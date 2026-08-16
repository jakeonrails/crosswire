import { Controller } from "@hotwired/stimulus"

// cw--confirm composes with cw--dialog by *name* the same way the presenter does — it
// is not an outlet, just a literal string used to write cw--dialog's own `open` value
// attribute directly (see `#requestDialogOpen` below).
const DIALOG_OPEN_ATTR = "data-cw--dialog-open-value"

/**
 * cw--confirm — a promise-returning confirmation dialog, replacing `window.confirm`.
 *
 * WAI-ARIA APG: https://www.w3.org/WAI/ARIA/apg/patterns/alertdialog/
 *
 * Targets  title, body, confirmButton, cancelButton
 * Values   title (String), body (String), confirmLabel (String, default "Confirm"),
 *          cancelLabel (String, default "Cancel"), destructive (Boolean, default false)
 * Classes  destructive (optional, applied to the dialog element)
 * Events   cw--confirm:opened, cw--confirm:resolved (detail: { confirmed: Boolean })
 *
 * Install as `Turbo.config.forms.confirm`, NEVER `Turbo.setConfirmMethod()` — that API
 * is deprecated. See the presenter docstring for the full wiring example, and for the
 * `data-turbo-confirm`-is-ignored-on-plain-links gotcha.
 *
 * COMPOSES WITH cw--dialog — stacked on the same element
 * (`data-controller="cw--dialog cw--confirm"`, see the presenter), rather than
 * reimplementing `<dialog>` plumbing. cw--dialog owns showModal()/close(), scroll
 * lock, focus save-and-restore, light dismiss (disabled here via `dismissable: false`
 * — a confirmation should never close on an accidental backdrop click) and the
 * `turbo:before-morph-element` guard against Idiomorph stripping `open` mid-modal.
 * This controller owns only the promise, the buttons and the alertdialog semantics on
 * top of that. Two things flow between the controllers, both via the public surface
 * named in cw--dialog's own docstring — its identifier, its `open` value, and its
 * events — never a Stimulus outlet (R5):
 *
 *   1. OUTBOUND (asking cw--dialog to open) — `open()` is called programmatically, so
 *      there is no click event on this element for a `data-action` binding to hook.
 *      It writes `data-cw--dialog-open-value="true"` directly on `this.element`
 *      (the same element cw--dialog is stacked on). This is the ordinary external
 *      write path R4 already guarantees works — the same mechanism a Turbo morph or
 *      server-rendered value uses — not a special case invented for this composition.
 *   2. OUTBOUND (asking cw--dialog to close) — the Confirm/Cancel buttons instead ride
 *      a REAL click event: the presenter wires each button's `data-action` to both
 *      `cw--confirm#confirm`/`#cancel` (record the intended result) AND
 *      `cw--dialog#close` (the actual close, gated by cw--dialog's own cancelable
 *      `closing` pre-check) — two listeners on one click, ordinary Stimulus
 *      composition, no custom event needed.
 *   3. INBOUND — this controller never touches `showModal()`/`close()` or the native
 *      `cancel`/`close` events itself; it listens for `cw--dialog:opened` (to place
 *      initial focus) and `cw--dialog:closed` (to resolve the promise), both wired by
 *      the presenter's `action()` pass-through.
 *
 * Escape is handled entirely by cw--dialog (native `cancel` → `close`), which then
 * dispatches `cw--dialog:closed`. `#confirmed` defaults to `false` and is only ever
 * flipped by the `confirm()` action, so Escape — which never runs `confirm()` — always
 * resolves `false`, with no explicit Escape-handling code of our own required.
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
  static targets = ["title", "body", "confirmButton", "cancelButton"]
  static values = {
    title: String,
    body: String,
    confirmLabel: { type: String, default: "Confirm" },
    cancelLabel: { type: String, default: "Cancel" },
    destructive: Boolean
  }
  static classes = ["destructive"]

  #resolve = null
  #confirmed = false

  // R7 — if the dialog is torn down (Turbo cache restore, frame replacement) while a
  // confirmation is still pending, resolve it false rather than leaving an `await
  // confirm.open(...)` caller hanging forever. Focus/scroll-lock teardown is
  // cw--dialog's job (R8/R7 on its own disconnect()), not ours.
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

    this.#confirmed = false
    this.#requestDialogOpen()

    return new Promise((resolve) => {
      this.#resolve = resolve
    })
  }

  confirm(event) {
    event?.preventDefault()
    this.#confirmed = true
    // The actual close runs via the second `click->cw--dialog#close` action binding
    // the presenter wires onto this same button — see the class docstring.
  }

  cancel(event) {
    event?.preventDefault()
    this.#confirmed = false
    // Ditto — `click->cw--dialog#close` on this button does the actual closing.
  }

  // cw--dialog:opened -> opened — fires once cw--dialog has actually called
  // showModal() and finished its own opening work, so focus lands correctly instead
  // of racing native `<dialog>` autofocus.
  opened() {
    this.#focusInitialButton()
    this.dispatch("opened")
  }

  // cw--dialog:closed -> closed — fires for EVERY close, however it happened: our own
  // Confirm/Cancel buttons (via the `click->cw--dialog#close` binding), Escape (native
  // `cancel` then cw--dialog's own `close` handling), or external code flipping
  // cw--dialog's `open` value directly. That single path is what keeps resolution
  // correct no matter which of those triggered it — the same single-write-path shape
  // as every other crosswire controller (R4), just delegated to cw--dialog's event
  // instead of a value of our own (see the presenter docstring for why confirm has no
  // `open` value of its own).
  closed() {
    this.#settle(this.#confirmed)
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

  // See the class docstring's OUTBOUND #1 — writes cw--dialog's own `open` value
  // directly rather than calling any method on it, so this never needs a reference to
  // the other controller's instance (no outlet).
  #requestDialogOpen() {
    this.element.setAttribute(DIALOG_OPEN_ATTR, "true")
  }

  #settle(confirmed) {
    if (!this.#resolve) return

    const resolve = this.#resolve
    this.#resolve = null

    resolve(confirmed)
    this.dispatch("resolved", { detail: { confirmed } })
  }
}
