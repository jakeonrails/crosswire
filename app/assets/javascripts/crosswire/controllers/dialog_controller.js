import { Controller } from "@hotwired/stimulus"

/**
 * cw--dialog — drive a native <dialog>.
 *
 * WAI-ARIA APG: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/
 *
 * Targets  trigger (optional), panel (the <dialog> element)
 * Values   open (Boolean), modal (Boolean, default true), dismissable (Boolean, default true)
 * Events   cw--dialog:opening (cancelable), :opened, :closing (cancelable), :closed
 *
 * RULE 0: inside `showModal()`, the document is already inert and Escape is already
 * handled. This controller does NOT hand-roll a focus trap or a backdrop div — that
 * would be redundant with (and could conflict with) what the platform already does.
 * Reach for `cw--focus-trap` instead when you eject to something that is not a native
 * `<dialog>`.
 *
 * What is genuinely NOT free, and why this controller exists:
 *
 *   * scroll lock (whatwg/html#7732, open since 2022) — the page behind an open modal
 *     still scrolls unless locked here. Locking compensates for scrollbar width via
 *     `scrollbar-gutter: stable` so the page does not shift when the bar disappears.
 *   * focus restore on close — `document.activeElement` is saved before opening and
 *     restored after closing.
 *   * light dismiss — the `closedby` attribute is not Baseline (Safari has not shipped
 *     it), so a click landing on the `<dialog>` element itself (i.e. the backdrop, since
 *     a click on rendered content lands on a descendant) closes it by hand when
 *     `dismissableValue` is true.
 *
 * MORPH HAZARD — read this before touching the Turbo wiring. Turbo 8's Idiomorph gives
 * the `open` attribute no special handling, and removing `open` per the HTML spec does
 * NOT call `close()`. If a background morph strips `open` from an open `<dialog>` the
 * result is: the document stays inert (because `showModal()`'s inertness is not tied to
 * the attribute) but the dialog is no longer visible or reachable, and `close()` is now
 * a silent no-op because the dialog element no longer thinks it is open — the page is
 * dead. Reference: this is a corollary of the `<dialog>` `open`-attribute-removal steps
 * in the HTML spec combined with Idiomorph treating `<dialog>` as an ordinary element.
 * Defence, in two layers: `turbo:before-morph-element` on the panel is cancelled
 * outright while the dialog is open (see `beforeMorph` below), so Idiomorph never
 * touches it mid-modal at all; once closed, morphing is allowed again so
 * server-rendered content changes still land normally. `turbo:before-cache` closes the
 * dialog before Turbo snapshots the page, so a cached page never depicts a live modal
 * as dead markup.
 *
 * A second, narrower guard is installed straight in `connect()`/torn down in
 * `disconnect()` (R7) rather than wired through `data-action`: seanpdoyle's fix from
 * turbo#1239 (open since 2024-04, reconfirmed 2026-06 — every app using `<dialog>` +
 * morph needs it), scoped to this instance's own panel instead of installed globally.
 * It cancels only the REMOVAL of the `open` attribute and calls `.close()` itself,
 * rather than the element-wide cancel above. In today's wiring the element-wide guard
 * always wins first — Idiomorph never even visits a node's attributes once
 * `beforeNodeMorphed` returns false for it — so this second guard is currently
 * redundant defence-in-depth, not the primary fix; it exists so this controller
 * matches the exact upstream-reportable patch verbatim (see `crosswire/morph`'s
 * `installDialogMorphGuard`, the same fix exposed for any `<dialog>` this controller
 * does not drive) and so it keeps working correctly if the coarser element-wide guard
 * is ever loosened to allow in-place content updates while open.
 */
export default class DialogController extends Controller {
  static targets = ["trigger", "panel"]
  static values = {
    open: Boolean,
    modal: { type: Boolean, default: true },
    dismissable: { type: Boolean, default: true }
  }

  // Shared across every cw--dialog instance so nested/sibling dialogs don't unlock the
  // page just because one of them closed while another is still open.
  static #scrollLocks = 0
  static #savedOverflow = null
  static #savedGutter = null

  // See R4a in docs/COMPONENT_CONTRACT.md: Stimulus runs value callbacks BEFORE
  // connect(), and for a typed value the initial `previous` argument is the type's
  // default, not `undefined` — so a `previous === undefined` guard silently never
  // fires. `#ready` gates *event dispatch* only; the actual DOM work in `#render`
  // always runs, because a server-rendered `open` dialog still needs `showModal()`
  // called from JS to become genuinely modal (see `#render`).
  #ready = false
  #savedFocus = null
  #locked = false
  // Set while #render calls panel.close() itself (the SSR-upgrade reopen below), so
  // the native "close" event that call produces doesn't loop back through syncClosed
  // and desync openValue out from under the showModal() call that follows it. Without
  // this, a server-rendered `open` dialog would silently close itself right after
  // being upgraded to a real modal — see syncClosed() and the SSR-upgrade test.
  #syncSuppressed = false

  // Bound once per instance so disconnect() removes exactly what connect() added —
  // R7. Scoped to `event.target === this.panelTarget` rather than `instanceof
  // HTMLDialogElement` alone (unlike `installDialogMorphGuard`'s document-wide form),
  // since this listener is only ever attached to this one panel.
  #openRemovalGuard = (event) => {
    const { target, detail } = event
    if (target !== this.panelTarget) return
    if (detail.attributeName !== "open" || detail.mutationType !== "remove") return

    event.preventDefault()
    target.close()
  }

  connect() {
    this.#render(this.openValue)
    this.#ready = true

    if (this.hasPanelTarget) {
      this.panelTarget.addEventListener("turbo:before-morph-attribute", this.#openRemovalGuard)
    }
  }

  disconnect() {
    // R8 — never strand focus on a node about to be detached.
    if (this.element.contains(document.activeElement)) {
      document.activeElement.blur?.()
    }

    if (this.hasPanelTarget) {
      this.panelTarget.removeEventListener("turbo:before-morph-attribute", this.#openRemovalGuard)
    }

    // R7 — exhaustive teardown. If this instance is disconnected mid-open (e.g. its
    // Turbo Frame is replaced outright, bypassing turbo:before-cache), release the
    // scroll lock and restore focus rather than leaving the page permanently locked.
    if (this.#locked) this.#unlockScroll()
    this.#savedFocus = null
    this.#ready = false
  }

  // --- actions, called by user interaction -----------------------------------------
  // Each only decides WHETHER to write the value (after a cancelable pre-check); the
  // DOM work always happens in openValueChanged. See R4 and R6.

  open(event) {
    event?.preventDefault()
    if (this.openValue) return

    const opening = this.dispatch("opening", { cancelable: true })
    if (opening.defaultPrevented) return

    this.openValue = true
  }

  close(event) {
    event?.preventDefault()
    if (!this.openValue) return

    const closing = this.dispatch("closing", { cancelable: true })
    if (closing.defaultPrevented) return

    this.openValue = false
  }

  backdropClick(event) {
    if (!this.hasPanelTarget || event.target !== this.panelTarget) return
    if (!this.dismissableValue) return

    this.close(event)
  }

  // Native `cancel` fires on Escape, before `close`, and is itself cancelable — give it
  // the same veto power a programmatic close gets.
  cancel(event) {
    if (!this.openValue) return

    const closing = this.dispatch("closing", { cancelable: true })
    if (closing.defaultPrevented) {
      event.preventDefault()
      return
    }
    // Otherwise let the native cancel proceed to `close`; `syncClosed` below is the
    // single place that writes the value back to false, whether Escape, a
    // `<form method="dialog">` submission, or our own #render() triggered it.
  }

  // Native `close` — fires however the dialog actually closed. This keeps the value
  // truthful even for paths this controller did not initiate itself.
  syncClosed() {
    if (this.#syncSuppressed) return
    if (this.openValue) this.openValue = false
  }

  // Cancel the morph outright while open; see the MORPH HAZARD note above.
  beforeMorph(event) {
    if (this.hasPanelTarget && this.panelTarget.open) event.preventDefault()
  }

  // turbo:before-cache — close before Turbo snapshots the page for the cache. Only
  // writes the value; #render (via openValueChanged) does the actual work.
  reset() {
    if (this.openValue) this.openValue = false
  }

  // --- single write path: openValueChanged does ALL DOM work -----------------------

  openValueChanged(value) {
    this.#render(value)

    if (!this.#ready) return

    this.dispatch(value ? "opened" : "closed")
  }

  #render(open) {
    if (!this.hasPanelTarget) return

    const panel = this.panelTarget

    if (open) {
      if (panel.open && this.modalValue && typeof panel.showModal === "function" && !this.#isModal(panel)) {
        // Server-rendered `open` attribute made the dialog visible but not modal
        // (showModal() throws InvalidStateError on an already-open dialog) — reopen
        // it properly so it gets the top layer, inertness and ::backdrop. Suppress
        // syncClosed for this call: it's an internal implementation detail, not a
        // real close, and openValue must stay true straight through to showModal().
        this.#syncSuppressed = true
        panel.close()
        this.#syncSuppressed = false
      }

      if (!panel.open) {
        this.#savedFocus = document.activeElement
        this.#lockScroll()

        if (this.modalValue && typeof panel.showModal === "function") {
          panel.showModal()
        } else if (typeof panel.show === "function") {
          panel.show()
        } else {
          // No <dialog> method support at all (e.g. a test environment, or a very old
          // browser with no polyfill): fall back to the plain HTML attribute so the
          // content is at least visible, even without modality.
          panel.setAttribute("open", "")
        }
      }
    } else {
      if (panel.open) {
        if (typeof panel.close === "function") {
          panel.close()
        } else {
          panel.removeAttribute("open")
        }
      }

      this.#unlockScroll()
      this.#restoreFocus()
    }
  }

  // `:modal` is Baseline-widely-available but not universal, and some environments
  // (jsdom's `nwsapi` selector engine, notably) throw a SyntaxError on an unrecognised
  // pseudo-class rather than just not matching. Treat that as "not currently modal" —
  // the caller's response (close then reopen properly) is the safe direction to fail in.
  #isModal(panel) {
    try {
      return typeof panel.matches === "function" && panel.matches(":modal")
    } catch {
      return false
    }
  }

  #lockScroll() {
    if (this.#locked) return
    this.#locked = true

    if (DialogController.#scrollLocks++ > 0) return

    const root = document.documentElement
    DialogController.#savedOverflow = root.style.overflow
    DialogController.#savedGutter = root.style.scrollbarGutter
    root.style.overflow = "hidden"
    root.style.scrollbarGutter = "stable"
  }

  #unlockScroll() {
    if (!this.#locked) return
    this.#locked = false

    if (--DialogController.#scrollLocks > 0) return

    const root = document.documentElement
    root.style.overflow = DialogController.#savedOverflow || ""
    root.style.scrollbarGutter = DialogController.#savedGutter || ""
    DialogController.#savedOverflow = null
    DialogController.#savedGutter = null
  }

  #restoreFocus() {
    const target = this.#savedFocus
    this.#savedFocus = null

    if (target && document.contains(target) && typeof target.focus === "function") {
      target.focus({ preventScroll: true })
    }
  }
}
