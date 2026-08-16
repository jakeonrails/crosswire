import { Controller } from "@hotwired/stimulus"

/**
 * cw--dismiss — remove or hide a container.
 *
 * Values   remove (Boolean, default true), selector (String, optional)
 * Events   cw--dismiss:dismissing (cancelable — preventDefault to animate first),
 *          cw--dismiss:dismissed
 *
 * Composes rather than absorbs: pair with cw--transition for an exit animation and
 * cw--timeout for auto-dismiss. Keeping those separate is why this one controller
 * serves flash messages, modal close buttons and dismissible banners alike.
 */
export default class DismissController extends Controller {
  static values = {
    remove: { type: Boolean, default: true },
    selector: String
  }

  dismiss(event) {
    event?.preventDefault()

    const target = this.#target
    if (!target) return

    // Cancelable, so a transition controller can hold the node open long enough to
    // animate. This is the same manoeuvre Turbo Streams need for exit animations:
    // Node.remove() is synchronous, so once it runs there is nothing left to animate.
    const dismissing = this.dispatch("dismissing", {
      target,
      detail: { complete: () => this.#complete(target) },
      cancelable: true
    })

    if (dismissing.defaultPrevented) return

    this.#complete(target)
  }

  #complete(target) {
    // Never strand the focus ring on a node we are about to detach — screen reader
    // focus would fall back to <body> and the user would lose their place.
    if (target.contains(document.activeElement)) {
      const fallback = target.parentElement?.closest("[tabindex], a, button") || document.body
      fallback.focus?.({ preventScroll: true })
    }

    // Dispatched while target is still attached to the document, so it bubbles to
    // document-level listeners — the ordinary way to observe crosswire events by
    // delegation, and how nothing but a listener bound directly to this exact node
    // would ever hear it otherwise: once target.remove() runs there is no parent left
    // for a bubbling event to travel through.
    this.dispatch("dismissed", { target, detail: { removed: this.removeValue } })

    if (this.removeValue) {
      target.remove()
    } else {
      target.hidden = true
    }
  }

  get #target() {
    if (!this.hasSelectorValue || this.selectorValue === "") return this.element

    return this.element.closest(this.selectorValue) ||
      document.querySelector(this.selectorValue)
  }
}
