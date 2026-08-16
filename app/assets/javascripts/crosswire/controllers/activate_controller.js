import { Controller } from "@hotwired/stimulus"

/**
 * cw--activate — treat an arbitrary event as a click on some element.
 *
 * Values   target (String, CSS selector, optional — defaults to this element),
 *          onConnect (Boolean, default false)
 * Actions  activate — wire it to whatever event should trigger the click:
 *          `data-action="cw--intersection:entered->cw--activate#activate"`
 *
 * Its entire job is keeping observers pure: `intersection` dispatches
 * `entered`/`left` and knows nothing about navigation; this controller is what
 * turns "something happened" into "click that", so `intersection` (and
 * `hotkey`, and anything else that reports an event) never has to grow a
 * navigation opinion of its own. Infinite scroll is `intersection` + `activate`
 * + a lazy `<turbo-frame>` doing the actual loading — not a bespoke
 * infinite-scroll controller. See `intersection_controller.js` for the same
 * composition from the sentinel's side.
 *
 * DISPATCHES A REAL `el.click()` — deliberately, so it composes with whatever
 * click-bound `data-action` already exists on the target rather than needing
 * its own parallel invocation path. The synthetic click this produces carries
 * `isTrusted: false` and `detail: 0` (a real mouse click's `detail` is the
 * click count — 1, 2 for a dblclick, etc. — which a synthetic `.click()` call
 * never sets), so a listener that must tell real user interaction apart from
 * this controller's synthetic one can check `event.isTrusted` or
 * `event.detail === 0`. This also means anything that depends on genuine
 * browser trust — a `<a download>` in some browsers, a file picker — will not
 * work when triggered this way; that is a platform restriction on synthetic
 * clicks generally, not something this controller can route around.
 *
 * Guards against firing on a disabled control (`disabled` property or
 * `aria-disabled="true"`) — clicking something a screen reader and every other
 * input modality currently treats as inert would be a real accessibility bug,
 * not a convenience.
 *
 * `onConnect: true` fires once immediately on connect, in addition to
 * whatever `data-action` wiring exists — for "load the first page
 * automatically" style triggers.
 *
 * No R7 teardown: this controller holds no listeners, timers or observers
 * beyond the ordinary Stimulus action binding, which Stimulus itself releases.
 */
export default class ActivateController extends Controller {
  static values = {
    target: String,
    onConnect: { type: Boolean, default: false }
  }

  connect() {
    if (this.onConnectValue) this.activate()
  }

  activate() {
    const target = this.#target()
    if (!target) return
    if (target.disabled || target.getAttribute("aria-disabled") === "true") return

    target.click()
  }

  #target() {
    if (!this.hasTargetValue || this.targetValue === "") return this.element

    try {
      // Descendant first, not `closest()`: the realistic shape (see the class
      // docstring's infinite-scroll composition) has the real clickable element
      // NESTED inside whatever this controller is stacked onto — a sentinel div
      // wrapping the actual "load more" link — the opposite relationship from
      // `dismiss`'s `selector:`, which walks UP to find an ancestor container.
      // Falls back to a document-wide query for a target that lives elsewhere
      // entirely (a sibling, or another region of the page).
      return this.element.querySelector(this.targetValue) || document.querySelector(this.targetValue)
    } catch {
      // An invalid selector should not crash the page over an activation behaviour.
      return null
    }
  }
}
