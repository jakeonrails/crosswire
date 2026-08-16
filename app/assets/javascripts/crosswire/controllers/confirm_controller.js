import { Controller } from "@hotwired/stimulus"

/**
 * cw--confirm — a promise-returning confirmation dialog, replacing `window.confirm`.
 *
 * WAI-ARIA APG: https://www.w3.org/WAI/ARIA/apg/patterns/alertdialog/
 *
 * Targets  dialog, title, body, confirmButton, cancelButton
 * Values   title (String), body (String), confirmLabel (String, default "Confirm"),
 *          cancelLabel (String, default "Cancel"), destructive (Boolean, default false)
 * Classes  destructive (optional, applied to the dialog element)
 * Events   cw--confirm:opened, cw--confirm:resolved (detail: { confirmed: Boolean })
 *
 * Install as `Turbo.config.forms.confirm`, NEVER `Turbo.setConfirmMethod()` — that API
 * is deprecated. See the presenter docstring for the full wiring example, and for the
 * `data-turbo-confirm`-is-ignored-on-plain-links gotcha.
 *
 * TODO(compose): delegate to cw--dialog once both have landed. This controller
 * implements its own minimal open/close plumbing rather than composing with
 * cw--dialog, which is being built in parallel and may not exist yet. Deliberately no
 * light dismiss (backdrop click) — a confirmation should never be dismissible by
 * accident.
 *
 * `open()` is the public API, usable two ways:
 *
 *   1. Programmatically, e.g. from `Turbo.config.forms.confirm` — call it directly
 *      with an options object and await the Promise<boolean> it returns.
 *   2. As a Stimulus action (`data-action="click->cw--confirm#open"`) — Stimulus then
 *      passes the click Event instead of an options object. Per-trigger overrides in
 *      that case come through Stimulus Action Params
 *      (`data-cw--confirm-title-param="Delete this file?"`), read from `event.params`.
 *
 * Not reentrant: calling `open()` again before a previous call has resolved abandons
 * that call's resolver, which then never settles. One confirm dialog handles one
 * confirmation at a time — mount a single instance and reuse it (see the presenter
 * docstring), rather than one per trigger.
 */
export default class ConfirmController extends Controller {
  static targets = ["dialog", "title", "body", "confirmButton", "cancelButton"]
  static values = {
    title: String,
    body: String,
    confirmLabel: { type: String, default: "Confirm" },
    cancelLabel: { type: String, default: "Cancel" },
    destructive: Boolean
  }
  static classes = ["destructive"]

  #resolve = null
  #savedFocus = null

  // R7 — if the dialog is torn down (Turbo cache restore, frame replacement) while a
  // confirmation is still pending, resolve it false rather than leaving an `await
  // confirm.open(...)` caller hanging forever.
  disconnect() {
    this.#settle(false)
  }

  open(paramsOrEvent = {}) {
    const options = paramsOrEvent instanceof Event ? paramsOrEvent.params ?? {} : paramsOrEvent

    if (options.title !== undefined) this.titleValue = options.title
    if (options.body !== undefined) this.bodyValue = options.body
    if (options.confirmLabel !== undefined) this.confirmLabelValue = options.confirmLabel
    if (options.cancelLabel !== undefined) this.cancelLabelValue = options.cancelLabel
    if (options.destructive !== undefined) this.destructiveValue = options.destructive

    this.#savedFocus = document.activeElement
    this.dialogTarget.returnValue = ""
    this.dialogTarget.showModal()
    this.#focusInitialButton()

    this.dispatch("opened")

    return new Promise((resolve) => {
      this.#resolve = resolve
    })
  }

  confirm(event) {
    event?.preventDefault()
    this.dialogTarget.close("confirm")
  }

  cancel(event) {
    event?.preventDefault()
    this.dialogTarget.close("cancel")
  }

  // Fires for EVERY close, however it happened: our own confirm()/cancel(), Escape
  // (whose native `cancel` event's default action closes the dialog), or external code
  // calling `dialogTarget.close()` directly. That single path is what keeps resolution
  // correct no matter which of those triggered it — the same single-write-path shape
  // as every other crosswire controller (R4), just keyed off `returnValue` instead of
  // a value, because open/closed isn't modeled as one here (see the presenter
  // docstring for why).
  closed() {
    this.#settle(this.dialogTarget.returnValue === "confirm")
  }

  titleValueChanged(value) {
    if (this.hasTitleTarget) this.titleTarget.textContent = value
  }

  bodyValueChanged(value) {
    if (this.hasBodyTarget) this.bodyTarget.textContent = value
  }

  confirmLabelValueChanged(value) {
    if (this.hasConfirmButtonTarget) this.confirmButtonTarget.textContent = value
  }

  cancelLabelValueChanged(value) {
    if (this.hasCancelButtonTarget) this.cancelButtonTarget.textContent = value
  }

  // R3 — guarded with hasDestructiveClass; Stimulus throws on this.destructiveClass
  // when no class value was configured.
  destructiveValueChanged(value) {
    if (this.hasDestructiveClass) this.element.classList.toggle(this.destructiveClass, value)
  }

  // The least destructive control gets focus by default, per APG guidance — Cancel
  // when the confirmed action is destructive, Confirm otherwise. Done explicitly
  // rather than via a static `autofocus` attribute because `destructive` can change
  // per call (`open({ destructive: true })`), after the HTML has already rendered.
  #focusInitialButton() {
    const target = this.destructiveValue ? this.cancelButtonTarget : this.confirmButtonTarget
    target?.focus()
  }

  #settle(confirmed) {
    if (!this.#resolve) return

    const resolve = this.#resolve
    this.#resolve = null

    this.#savedFocus?.focus?.({ preventScroll: true })
    this.#savedFocus = null

    resolve(confirmed)
    this.dispatch("resolved", { detail: { confirmed } })
  }
}
