import { Controller } from "@hotwired/stimulus"

const UNSAVED_MESSAGE = "You have unsaved changes. Leave this page?"

/**
 * cw--dirty-form — track field changes and guard against losing them.
 *
 * Targets  field (optional — defaults to every form control inside this.element)
 * Values   guard (Boolean, default true — block navigation while dirty; false just
 *          tracks and exposes data-dirty/events with no prompting)
 * Classes  dirty (optional, guarded per R3)
 * Events   cw--dirty-form:changed, cw--dirty-form:reset
 *
 * THE WHOLE REASON THIS EXISTS: `beforeunload` DOES NOT FIRE on a Turbo Drive visit —
 * the document never unloads, Turbo just replaces the DOM in place. Every "warn on
 * unsaved changes" tutorial that wires only `beforeunload` is silently broken in any
 * Hotwire app the moment a user clicks an ordinary in-app link. This controller
 * installs THREE guards, because each covers a moment the others cannot see:
 *
 *   1. beforeunload (window)         — real unloads: closing the tab, a hard
 *      reload, data-turbo=false links, cross-origin navigation. The ONLY case
 *      this classic handler actually covers.
 *   2. turbo:before-visit (document) — Turbo Drive visits: in-app link clicks,
 *      Turbo.visit(), and the redirect visit that follows a form submission.
 *      Cancelable, dispatched BEFORE the network request.
 *   3. turbo:before-frame-render (the owning turbo-frame, if any) — a frame
 *      navigation never proposes a Drive Visit at all, so #2 never fires for it.
 *      Also cancelable, but dispatched AFTER the response has already arrived —
 *      cancelling here wastes a request, an acceptable cost for a confirm prompt.
 *
 * window.confirm is used for #2/#3 because both handlers must decide SYNCHRONOUSLY —
 * turbo:before-visit cannot be held open with an await, so a custom dialog-based
 * confirm needs the "cancel unconditionally, then re-issue Turbo.visit() if the user
 * accepts" dance documented in research/notes/08. This controller keeps the simpler
 * synchronous form.
 *
 * Dirty is computed by comparing a serialized snapshot of the tracked fields against
 * the snapshot taken at connect() (or the last reset()) — NOT by "has any input
 * event fired." Typing a character and then deleting it must not leave the form
 * dirty, and this comparison-based approach gets that for free.
 *
 * Cleared automatically on turbo:submit-end when the submission succeeded, which
 * Turbo fires BEFORE the post-submit redirect's turbo:before-visit (verified against
 * Turbo's own functional tests) — so a successful save never triggers its own guard
 * on the way to the next page. Forgetting this step is the second-most common bug in
 * hand-rolled versions of this pattern.
 */
export default class DirtyFormController extends Controller {
  static targets = ["field"]
  static values = { guard: { type: Boolean, default: true } }
  static classes = ["dirty"]

  #snapshot = ""

  #onBeforeUnload = (event) => {
    if (!this.guardValue || !this.#isDirty()) return

    event.preventDefault()
    event.returnValue = "please-confirm"
  }

  #onBeforeVisit = (event) => {
    if (!this.guardValue || !this.#isDirty()) return
    if (!window.confirm(UNSAVED_MESSAGE)) event.preventDefault()
  }

  #onBeforeFrameRender = (event) => {
    if (!this.guardValue || !this.#isDirty()) return
    if (event.target !== this.#frame) return
    if (!window.confirm(UNSAVED_MESSAGE)) event.preventDefault()
  }

  #onSubmitEnd = (event) => {
    if (event.detail && event.detail.success) this.reset()
  }

  connect() {
    this.#snapshot = this.#serialize()
    this.element.dataset.dirty = "false"

    addEventListener("beforeunload", this.#onBeforeUnload)
    document.addEventListener("turbo:before-visit", this.#onBeforeVisit)
    document.addEventListener("turbo:before-frame-render", this.#onBeforeFrameRender)
    this.element.addEventListener("turbo:submit-end", this.#onSubmitEnd)
  }

  disconnect() {
    removeEventListener("beforeunload", this.#onBeforeUnload)
    document.removeEventListener("turbo:before-visit", this.#onBeforeVisit)
    document.removeEventListener("turbo:before-frame-render", this.#onBeforeFrameRender)
    this.element.removeEventListener("turbo:submit-end", this.#onSubmitEnd)
  }

  check() {
    const dirty = this.#isDirty()
    const wasDirty = this.element.dataset.dirty === "true"
    this.element.dataset.dirty = String(dirty)

    if (this.hasDirtyClass) this.element.classList.toggle(this.dirtyClass, dirty)

    if (dirty === wasDirty) return

    this.dispatch(dirty ? "changed" : "reset")
  }

  reset() {
    this.#snapshot = this.#serialize()
    this.check()
  }

  #isDirty() {
    return this.#serialize() !== this.#snapshot
  }

  #serialize() {
    if (this.hasFieldTarget) {
      return JSON.stringify(this.fieldTargets.map((field) => this.#fieldToken(field)))
    }

    return new URLSearchParams(new FormData(this.element)).toString()
  }

  #fieldToken(field) {
    if (field.type === "checkbox" || field.type === "radio") return field.name + "=" + field.checked

    return field.name + "=" + field.value
  }

  get #frame() {
    return this.element.closest("turbo-frame")
  }
}
