import { Controller } from "@hotwired/stimulus"

/**
 * cw--disclosure — show/hide a panel from a trigger.
 *
 * WAI-ARIA APG: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/
 *
 * Targets  trigger, panel
 * Values   open (Boolean)
 * Classes  open (optional, applied to this.element)
 * Events   cw--disclosure:opened, cw--disclosure:closed  (both cancelable)
 *
 * Notes for anyone extending this — these are the rules every crosswire controller
 * follows, and they are why these controllers stay generic:
 *
 *   1. Never read `this.fooClass` without `hasFooClass`. Stimulus THROWS when a class
 *      attribute is absent and offers no default. This is the single most likely way a
 *      component breaks for a consumer who did not pass a class.
 *   2. State lives in a Stimulus value, and the value is rendered by the server. That
 *      keeps the pre-JS state correct and is the only arrangement that survives a Turbo
 *      morph — morphing overwrites `data-*-value` and skips `connect()` (turbo#1210,
 *      won't-fix upstream), so anything else silently desynchronises.
 *   3. Apply DOM changes in `openValueChanged`, not in the action handler. The action
 *      only sets the value. That single write path means a server-driven change, a morph
 *      and a click all converge on the same code.
 *   4. Events are the composition primitive. Emit them; never declare outlets — an
 *      outlet hardcodes another controller's identifier, which a distributable component
 *      cannot know.
 */
export default class DisclosureController extends Controller {
  static targets = ["trigger", "panel"]
  static values = { open: Boolean }
  static classes = ["open"]

  connect() {
    // Re-assert from the DOM rather than trusting the value alone: after a Turbo morph
    // the value attribute may have been clobbered while the panel kept its real state.
    this.#render()
  }

  toggle(event) {
    event?.preventDefault()
    this.openValue = !this.openValue
  }

  show() {
    this.openValue = true
  }

  hide() {
    this.openValue = false
  }

  // Single write path — see note 3 above.
  openValueChanged(value, previous) {
    this.#render()

    // Don't announce the initial connect, only real transitions.
    if (previous === undefined) return

    this.dispatch(value ? "opened" : "closed", {
      detail: { open: value },
      cancelable: true
    })
  }

  #render() {
    const open = this.openValue

    if (this.hasPanelTarget) {
      this.panelTarget.hidden = !open
    }

    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", String(open))
    }

    if (this.hasOpenClass) {
      this.element.classList.toggle(this.openClass, open)
    }
  }
}
