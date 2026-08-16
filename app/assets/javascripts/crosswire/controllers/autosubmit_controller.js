import { Controller } from "@hotwired/stimulus"

/**
 * cw--autosubmit — submit the owning form automatically on input or change.
 *
 * Values   delay (Number, ms, default 0), event (String, default "input"),
 *          scope (String, optional CSS selector for the form)
 * Events   cw--autosubmit:submitting (cancelable), cw--autosubmit:submitted
 *
 * ALWAYS `form.requestSubmit()`, NEVER `form.submit()`. `submit()` skips HTML5
 * validation and skips Turbo entirely, forcing a full page load — the single most
 * common bug in hand-rolled versions of this controller. This file calls
 * `requestSubmit()` in exactly one place and nowhere calls `submit()`.
 *
 * Focus and caret survive the round-trip only through markup, not through anything
 * this controller does: give the field a STABLE `id` and add `data-turbo-permanent`.
 * Under Turbo 8 morphing, an element with no `id` is always replaced rather than
 * patched, so focus is lost regardless of what JavaScript runs.
 *
 * Debouncing is trailing-edge only: each qualifying event resets the timer, and only
 * the last one in a burst actually submits. A submission is skipped if the field's
 * value is unchanged since the LAST SUBMITTED value (not the last input event) — this
 * is what keeps arrow keys, modifier keys and other value-preserving events from
 * triggering a submit. A real submit (Enter, a submit button, another controller)
 * cancels any debounce still pending, so the same edit is never submitted twice.
 *
 * Composition: per-field server validation is this same controller, `scope`d by
 * formaction/formmethod to a validation URL — see the presenter docstring. It does
 * not need a separate `remote-validate` controller.
 */
export default class AutosubmitController extends Controller {
  static values = {
    delay: { type: Number, default: 0 },
    event: { type: String, default: "input" },
    scope: String
  }

  #timeout = null
  #lastSubmittedValue = null
  #boundHandleEvent = null
  #boundHandleSubmit = null

  connect() {
    this.#lastSubmittedValue = this.#currentValue

    this.#boundHandleEvent = this.#handleEvent.bind(this)
    this.#boundHandleSubmit = this.#handleFormSubmit.bind(this)

    this.element.addEventListener(this.eventValue, this.#boundHandleEvent)
    this.#form?.addEventListener("submit", this.#boundHandleSubmit)
  }

  // R7 — exhaustive teardown: unbind both listeners and cancel any pending timer so a
  // Turbo Frame or cache restore never leaves an orphaned setTimeout behind.
  disconnect() {
    this.element.removeEventListener(this.eventValue, this.#boundHandleEvent)
    this.#form?.removeEventListener("submit", this.#boundHandleSubmit)
    this.#cancelPending()
  }

  #handleEvent() {
    const value = this.#currentValue
    if (value === this.#lastSubmittedValue) return

    this.#cancelPending()

    if (this.delayValue > 0) {
      this.#timeout = setTimeout(() => this.#submit(value), this.delayValue)
    } else {
      this.#submit(value)
    }
  }

  // A real submit started (Enter, a submit button, another controller) — drop any
  // debounce still in flight so the same edit does not get submitted a second time.
  #handleFormSubmit() {
    this.#cancelPending()
  }

  #submit(value) {
    this.#timeout = null

    const form = this.#form
    if (!form) return

    const submitting = this.dispatch("submitting", { cancelable: true })
    if (submitting.defaultPrevented) return

    this.#lastSubmittedValue = value
    form.requestSubmit()

    this.dispatch("submitted")
  }

  #cancelPending() {
    if (this.#timeout === null) return

    clearTimeout(this.#timeout)
    this.#timeout = null
  }

  get #currentValue() {
    return this.element.value
  }

  get #form() {
    if (this.hasScopeValue && this.scopeValue !== "") {
      return document.querySelector(this.scopeValue)
    }

    return this.element.form || this.element.closest("form")
  }
}
