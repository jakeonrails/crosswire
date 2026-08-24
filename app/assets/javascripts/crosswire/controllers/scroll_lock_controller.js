import { Controller } from "@hotwired/stimulus"

// Reference-counted at MODULE scope rather than per instance. Two stacked lockers (a
// dialog opened from inside an already-locked drawer) must not have the inner one's
// release re-enable page scroll while the outer is still active — a purely
// per-instance lock has no way to know a sibling instance still needs it, and R5 bans
// reaching for a sibling controller directly to ask. This module-level counter is the
// coordination mechanism, and it is the whole reason `scroll-lock` is a shared
// primitive instead of ~20 lines duplicated inline into `dialog` and every other
// overlay that needs a locked background.
let lockCount = 0
let savedScrollY = 0
let savedHtmlOverflow = null
let savedHtmlScrollbarGutter = null
let savedHtmlPaddingRight = null
let addedPadding = false
let savedBodyStyleCssText = null

function supportsScrollbarGutter() {
  try {
    return typeof CSS !== "undefined" && typeof CSS.supports === "function" &&
      CSS.supports("scrollbar-gutter", "stable")
  } catch {
    return false
  }
}

// iOS Safari ignores `overflow: hidden` on both <html> and <body> — this is not a
// theoretical edge case, it's the documented reason whatwg/html#7732 is still open.
// `position: fixed` on <body> is the only lock that actually holds there, and it has a
// real, unavoidable cost: it resets scroll to 0 the instant it's applied. The tradeoff
// is accepted rather than worked around — the position is saved before locking and
// restored on release, which is the one thing that makes it safe to use at all.
function isIOS() {
  return /iP(ad|hone|od)/.test(navigator.platform) ||
    (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
}

function acquire() {
  if (lockCount === 0) applyLock()
  lockCount++
}

function release() {
  if (lockCount === 0) return
  lockCount--
  if (lockCount === 0) removeLock()
}

function applyLock() {
  const doc = document.documentElement
  const body = document.body

  savedScrollY = window.scrollY

  savedHtmlOverflow = doc.style.overflow

  // Measure whether a scrollbar is actually taking space BEFORE touching `overflow`.
  // `scrollbar-gutter: stable` reserves gutter space unconditionally the instant
  // `overflow` isn't `visible` — per the CSS Overflow spec, it reserves the gutter
  // "even if the box doesn't currently overflow in the relevant axis." Applying it
  // regardless of whether a scrollbar existed before locking doesn't compensate for
  // anything on a page that wasn't already scrolling — it *introduces* a shift where
  // none existed, on any platform with a space-taking (non-overlay) scrollbar. Gating
  // both branches on a measured `gap` keeps this to what it claims to be: compensation,
  // not a blind reservation.
  const gap = window.innerWidth - doc.clientWidth

  doc.style.overflow = "hidden"

  if (gap > 0) {
    if (supportsScrollbarGutter()) {
      savedHtmlScrollbarGutter = doc.style.scrollbarGutter
      doc.style.scrollbarGutter = "stable"
    } else {
      savedHtmlPaddingRight = doc.style.paddingRight
      const current = Number.parseFloat(getComputedStyle(doc).paddingRight) || 0
      doc.style.paddingRight = `${current + gap}px`
      addedPadding = true
    }
  }

  if (isIOS()) {
    savedBodyStyleCssText = body.style.cssText
    body.style.position = "fixed"
    body.style.top = `${-savedScrollY}px`
    body.style.left = "0"
    body.style.right = "0"
    body.style.width = "100%"
  }
}

function removeLock() {
  const doc = document.documentElement
  const body = document.body

  doc.style.overflow = savedHtmlOverflow || ""
  savedHtmlOverflow = null

  if (savedHtmlScrollbarGutter !== null) {
    doc.style.scrollbarGutter = savedHtmlScrollbarGutter || ""
    savedHtmlScrollbarGutter = null
  }

  if (addedPadding) {
    doc.style.paddingRight = savedHtmlPaddingRight || ""
    savedHtmlPaddingRight = null
    addedPadding = false
  }

  if (isIOS()) {
    body.style.cssText = savedBodyStyleCssText || ""
    savedBodyStyleCssText = null
    // position:fixed reset scroll to 0 the moment it was applied. This restores it —
    // the one part of the iOS approach that is NOT free: skip this line and the page
    // silently loses the user's scroll position on every single lock/unlock.
    window.scrollTo(0, savedScrollY)
  }
}

/**
 * cw--scroll-lock — lock document scroll while active.
 *
 * Values   active (Boolean, default false)
 * Events   cw--scroll-lock:locked, cw--scroll-lock:unlocked — reflect THIS instance's
 *          own engagement, not whether the page is currently scrollable overall: the
 *          underlying lock is reference-counted at module scope (see above), so the
 *          page can remain locked by a sibling instance after this one releases.
 *
 * No Rule 0: `<dialog>.showModal()` does not lock document scroll (whatwg/html#7732,
 * open since 2022) — there is no platform feature to defer to here.
 *
 * Applies to `document.documentElement`/`document.body`, never to `this.element` —
 * there is nothing element-scoped about "the page can't scroll." Typically stacked on
 * the same element as `cw--dialog` or a drawer's own controller
 * (`data-controller="cw--dialog cw--scroll-lock"`), with `active` driven by whichever
 * of them owns the open/closed state.
 *
 * State lives in the `active` value; the action handler (if any consumer wires one)
 * never touches document/body directly — `activeValueChanged` does the work, per R4.
 * Guarded with a `#ready` flag rather than `previous === undefined`. because Stimulus
 * runs value-changed callbacks before `connect()` with the value's type default as
 * `previous`, not `undefined`, so that guard would silently never fire (R4a).
 *
 * Exhaustive teardown (R7): `disconnect()` always releases this instance's hold on the
 * lock, even if `active` was never explicitly set back to false. Turbo can remove the
 * locked element (a frame re-render, a cache restore that drops it, a stream removal)
 * without ever running an `activeValueChanged(false)` — and a page stuck permanently
 * unscrollable because a dialog vanished mid-open is a worse bug than the one this
 * controller exists to prevent.
 */
export default class ScrollLockController extends Controller {
  static values = { active: { type: Boolean, default: false } }

  #ready = false
  #locked = false

  connect() {
    this.#render()
    this.#ready = true
  }

  disconnect() {
    this.#release()
    this.#ready = false
  }

  activeValueChanged(value) {
    this.#render()

    if (!this.#ready) return

    this.dispatch(value ? "locked" : "unlocked", { detail: { active: value } })
  }

  #render() {
    if (this.activeValue) {
      this.#acquire()
    } else {
      this.#release()
    }
  }

  #acquire() {
    if (this.#locked) return
    this.#locked = true
    acquire()
  }

  #release() {
    if (!this.#locked) return
    this.#locked = false
    release()
  }
}
