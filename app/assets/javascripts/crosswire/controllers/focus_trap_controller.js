import { Controller } from "@hotwired/stimulus"

// Selector for "things that can normally take focus." Matches the standard list used
// by every other focus-trap implementation in the wild (focus-trap, inert polyfills,
// etc.) — deliberately not exhaustive of every focusable edge case (contenteditable,
// audio/video controls, custom elements with `tabindex` set via property only), which
// is a known, accepted limit of this whole genre of component.
const FOCUSABLE_SELECTOR = "a[href], button, input, select, textarea, [tabindex]"

/**
 * cw--focus-trap — constrain Tab cycling within an element and restore focus on
 * release.
 *
 * Rule 0 (see the presenter docstring): inside a modal `<dialog>` you do not need
 * this — `showModal()` already makes the rest of the document inert. Reach for this
 * controller only for drawers, non-modal panels, and toolbars.
 *
 * Values   active (Boolean, default true), initial (String, optional CSS selector)
 * Classes  active (optional, applied to this.element — see R3/R3a)
 * Events   cw--focus-trap:activated, cw--focus-trap:released — both carry
 *          `detail.active`. Neither is cancelable: nothing here is destructive
 *          (R6 governs removal/replacement, not a focus move), so there is nothing
 *          meaningful to prevent.
 *
 * State lives in the `active` value; the action handler never touches the DOM
 * directly, `activeValueChanged` does (R4). Guarded with a `#ready` flag rather than
 * `previous === undefined`, because Stimulus runs value-changed callbacks before
 * `connect()` with the value's type default as `previous` — not `undefined` — so that
 * guard would silently never fire (R4a).
 *
 * THE MOST IMPORTANT CORRECTNESS DETAIL: focusable descendants are re-queried on
 * every Tab press, never cached at activation. Content under Turbo changes
 * constantly — frames render, streams append, buttons toggle `disabled` mid-session —
 * and a cached list goes stale and can wrap focus onto a node that has since been
 * detached or hidden.
 *
 * `offsetParent !== null` is used below as the "is this actually visible" check. It
 * is a reasonable, cheap proxy in a real browser (it is null for `display: none` and
 * detached nodes) but it is NOT a complete visibility test — it does not catch
 * `visibility: hidden`, clip-based hiding, or elements whose nearest positioned
 * ancestor is itself `position: fixed` (whose own offsetParent is also legitimately
 * null while still visible). jsdom does not implement layout at all, so
 * `offsetParent` is unconditionally `null` there regardless of real visibility —
 * meaning this filter can never observe a focusable descendant under jsdom. That is
 * a real, verified limit of the jsdom tier, not a bug: `focus_trap_controller.test.js`
 * documents it and restricts itself to what is honestly testable there (wiring,
 * events, teardown, the container/no-focusable-children fallback, and the `initial`
 * selector path, which bypasses this filter entirely). Real multi-element Tab order —
 * wrapping, skipping newly-disabled elements, re-querying after a mutation — is only
 * ever honestly verifiable against a real layout engine, so it lives exclusively in
 * `focus_trap_controller.browser.test.js`.
 *
 * Exhaustive teardown (R7): the only persistent resource this controller holds is a
 * `focusin` listener on `document`, added on activate and removed on release/
 * disconnect via a stable bound reference. A leaked one is exactly the per-visit leak
 * Turbo's snapshot cache turns into a real bug.
 */
export default class FocusTrapController extends Controller {
  static values = {
    active: { type: Boolean, default: true },
    initial: String
  }

  static classes = ["active"]

  #ready = false
  #engaged = false
  #previouslyFocused = null
  #addedContainerTabindex = false

  connect() {
    this.#render()
    this.#ready = true
  }

  disconnect() {
    // Direct teardown, not through activeValueChanged — disconnect is not a value
    // change, so it must not dispatch an event, only release what connect acquired.
    this.#deactivate()
    this.#ready = false
  }

  // There is deliberately no click-bound action here. This behaviour has no trigger
  // of its own — it is driven entirely by its `active` value, set by whatever owns
  // the state (a drawer controller, a server-rendered attribute, a parent's own
  // action). Single write path (R4): activeValueChanged does all the DOM/focus work
  // and every dispatch; nothing else touches either.
  activeValueChanged(value) {
    this.#render()

    // Announce real transitions only, never the initial hydration (R4a).
    if (!this.#ready) return

    this.dispatch(value ? "activated" : "released", { detail: { active: value } })
  }

  // Bound to both `keydown.tab` and `keydown.shift+tab` on the root element in the
  // presenter's root_attrs — Stimulus's key-filter modifiers are exact-match, so a
  // bare `.tab` filter requires shiftKey to be false and silently drops Shift+Tab
  // unless `.shift+tab` is wired separately. Both route here; `event.shiftKey` is
  // read below to pick a direction. Tab events bubble from whatever is focused up
  // through this element as long as focus is somewhere inside it — which is the
  // entire premise of the trap — so no document-level listener is needed for this
  // half of the job.
  cycle(event) {
    if (!this.activeValue) return

    const focusable = this.#focusableChildren()

    if (focusable.length === 0) {
      // Nothing to cycle between. Keep focus pinned to the container rather than
      // letting Tab carry it out of the trap entirely.
      event.preventDefault()
      this.#fallbackContainer().focus({ preventScroll: true })
      return
    }

    const first = focusable[0]
    const last = focusable[focusable.length - 1]
    const current = document.activeElement
    // `current` can be absent from `focusable` if it became disabled/hidden since it
    // was focused — treat that the same as "at the boundary" and snap back inside
    // rather than letting Tab escape to whatever is next in the document.
    const atBoundary = event.shiftKey ? current === first : current === last
    const stray = !focusable.includes(current)

    if (atBoundary || stray) {
      event.preventDefault()
      const target = event.shiftKey ? last : first
      target.focus({ preventScroll: true })
    }
  }

  #render() {
    if (this.hasActiveClass) {
      this.element.classList.toggle(this.activeClass, this.activeValue)
    }

    if (this.activeValue) {
      this.#activate()
    } else {
      this.#deactivate()
    }
  }

  #activate() {
    if (this.#engaged) return
    this.#engaged = true

    this.#previouslyFocused = document.activeElement
    document.addEventListener("focusin", this.#handleFocusin)
    this.#focusEntryPoint()
  }

  #deactivate() {
    if (!this.#engaged) return
    this.#engaged = false

    document.removeEventListener("focusin", this.#handleFocusin)
    this.#releaseContainerTabindex()
    this.#restoreFocus()
  }

  // Focus that somehow escapes the trap (a stray click, a programmatic .focus() call
  // elsewhere, a race during a Turbo render) gets pulled straight back.
  #handleFocusin = (event) => {
    if (!this.activeValue) return
    if (this.element.contains(event.target)) return

    this.#focusEntryPoint()
  }

  #focusEntryPoint() {
    const target = this.#initialTarget() || this.#focusableChildren()[0] || this.#fallbackContainer()
    target.focus({ preventScroll: true })
  }

  // Unlike #focusableChildren, this trusts the caller's selector outright — no
  // offsetParent filtering — because the caller named this element specifically as
  // where focus should land, and because it makes "focus initial" honestly testable
  // under jsdom despite the offsetParent limit documented above.
  #initialTarget() {
    if (!this.hasInitialValue || this.initialValue === "") return null

    return this.element.querySelector(this.initialValue)
  }

  #fallbackContainer() {
    if (!this.element.hasAttribute("tabindex")) {
      this.element.setAttribute("tabindex", "-1")
      this.#addedContainerTabindex = true
    }

    return this.element
  }

  #releaseContainerTabindex() {
    if (!this.#addedContainerTabindex) return

    this.element.removeAttribute("tabindex")
    this.#addedContainerTabindex = false
  }

  #restoreFocus() {
    const previous = this.#previouslyFocused
    this.#previouslyFocused = null

    if (previous?.isConnected && typeof previous.focus === "function") {
      previous.focus({ preventScroll: true })
    }
  }

  #focusableChildren() {
    return Array.from(this.element.querySelectorAll(FOCUSABLE_SELECTOR)).filter(
      (el) => !el.disabled && el.tabIndex !== -1 && el.offsetParent !== null
    )
  }
}
