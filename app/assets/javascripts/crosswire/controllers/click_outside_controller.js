import { Controller } from "@hotwired/stimulus"

/**
 * cw--click-outside — dispatch when a pointer event lands outside the element.
 *
 * Values   enabled (Boolean, default true)
 * Events   cw--click-outside:clicked — detail carries `{ originalEvent }`
 *
 * Rule 0: the native Popover API (`popover="auto"`) and `<dialog>`'s `closedby="any"`
 * already give light-dismiss for their own cases, for free, with no JavaScript of
 * ours. Reach for this controller for everything else — a custom-styled menu, a
 * non-modal panel, an inline editor that should commit on outside activity.
 *
 * LISTENS ON `pointerdown`, NOT `click`. A `click` event fires only after `mouseup`
 * targeting the same element `mousedown` targeted, so a text selection or drag that
 * starts inside the element and is released outside it never fires a `click` at
 * all — which reads, wrongly, as "the user didn't click outside." `pointerdown` fires
 * at the moment the pointer goes down, which is the actual moment intent to interact
 * with something outside the element is expressed, drag or not.
 *
 * COMPOSED-PATH AWARE (R-worthy on its own): `event.composedPath()` is used instead of
 * `element.contains(event.target)`. `contains()` silently gives the wrong answer for
 * anything crossing a shadow boundary — a click inside an open shadow root retargets
 * `event.target` to the shadow host from the perspective of a listener outside that
 * root, so `contains()` can read a same-element click as "outside." It is also wrong
 * for portaled content (a menu rendered into `document.body` via a teleporting
 * component, or into the top layer) where the clicked node is a DOM descendant of
 * something else entirely, not of this controller's element. `composedPath()` returns
 * the full path an event actually traveled, shadow boundaries included, so checking it
 * for `this.element` is correct in both cases where `contains()` is not.
 *
 * Ignores right-clicks (`event.button > 0` — covers the auxiliary/middle button too)
 * and, where feasible, clicks that land on the scrollbar rather than the page: a
 * scrollbar click at the very edge of the viewport is not "outside" the panel in any
 * meaningful sense, it's the user operating browser chrome. That check needs a real
 * layout to be meaningful (see the jsdom test file for why it's inert, not merely
 * untested, under jsdom) and is a best-effort heuristic even in a real browser —
 * overlay scrollbars (macOS) don't reserve layout space at all, so there is no
 * universal way to detect "that pixel was scrollbar, not page."
 *
 * Exhaustive teardown (R7): the `pointerdown` listener is added on `document` with a
 * stable bound reference and removed on `disconnect()`.
 */
export default class ClickOutsideController extends Controller {
  static values = { enabled: { type: Boolean, default: true } }

  connect() {
    // Capture phase, so an inner handler calling `stopPropagation()` on the way up
    // cannot silently hide the interaction from this listener — the same robustness
    // choice every serious click-outside implementation makes.
    document.addEventListener("pointerdown", this.#onPointerDown, true)
  }

  disconnect() {
    document.removeEventListener("pointerdown", this.#onPointerDown, true)
  }

  #onPointerDown = (event) => {
    if (!this.enabledValue) return
    if (event.button > 0) return
    if (this.#isScrollbarClick(event)) return
    if (event.composedPath().includes(this.element)) return

    this.dispatch("clicked", { detail: { originalEvent: event } })
  }

  // Best-effort only: jsdom performs no layout at all, so `clientWidth`/`clientHeight`
  // are always 0 there — the guard below returns false in that case rather than
  // misreading every click as "on the scrollbar." A real browser reports real
  // dimensions, but even there this is a heuristic (overlay scrollbars occupy no
  // reserved layout space and can't be detected this way at all) — see the class
  // docstring.
  #isScrollbarClick(event) {
    const doc = document.documentElement
    if (doc.clientWidth === 0 || doc.clientHeight === 0) return false

    return event.clientX > doc.clientWidth || event.clientY > doc.clientHeight
  }
}
