import { Controller } from "@hotwired/stimulus"

/**
 * cw--clipboard — copy text and give feedback.
 *
 * Targets  source (element whose value/textContent is copied), button (optional,
 *          receives the success class and carries the click action if separate from
 *          the root), status (optional but strongly recommended — an `aria-live`
 *          region the success state is announced into)
 * Values   text (String, optional — literal text to copy),
 *          successDuration (Number ms, default 2000)
 * Classes  success (optional, guarded with `hasSuccessClass` per R3)
 * Events   cw--clipboard:copied (detail: { text }), cw--clipboard:failed
 *          (detail: { error })
 *
 * Copy precedence: an explicit `text` value wins; otherwise the `source` target's
 * `.value` (inputs/textareas) or `.textContent`; otherwise `this.element.textContent`.
 *
 * Accessibility matters more than it looks here. A purely visual "Copied!" state is
 * invisible to a screen reader, so the success state is also written into the
 * `status` target's text content, and `status_attrs` (see the presenter) puts
 * `role="status"`/`aria-live="polite"` on it. That region MUST already exist in the
 * DOM before the copy happens — an element that gains `aria-live` at the same moment
 * it gains its content is not announced, because the accessibility tree has to observe
 * the region before it can report a mutation on it. Render it server-side as part of
 * the page's normal markup (which `status_attrs` does when used through the helper);
 * never construct it with JS at copy time.
 *
 * `navigator.clipboard.writeText` requires a secure context — on plain `http://` it
 * is simply absent — and can reject even when present (permission prompts denied, an
 * iframe missing the `clipboard-write` allow attribute). Both cases fall back to a
 * hidden-textarea `execCommand("copy")` selection copy. Only if that also fails is
 * `cw--clipboard:failed` dispatched — this never throws unhandled, which matters
 * because a copy button that explodes the console on http://localhost is a bad first
 * impression.
 */
export default class ClipboardController extends Controller {
  static targets = ["source", "button", "status"]
  static values = {
    text: String,
    successDuration: { type: Number, default: 2000 }
  }
  static classes = ["success"]

  #timer = null

  disconnect() {
    // R7 — cancel the pending timer and clear whatever success state it would have
    // reset, rather than leaving a stray classList/live-region change behind on a
    // node Turbo may be about to cache.
    this.#clearTimer()
    this.#clearSuccessState()
  }

  async copy(event) {
    event?.preventDefault()

    const text = this.#text

    try {
      await this.#write(text)
      this.#succeed(text)
    } catch (error) {
      this.#fail(error)
    }
  }

  get #text() {
    if (this.hasTextValue && this.textValue !== "") return this.textValue

    if (this.hasSourceTarget) {
      const source = this.sourceTarget
      return "value" in source ? source.value : source.textContent
    }

    return this.element.textContent
  }

  async #write(text) {
    if (navigator.clipboard?.writeText) {
      try {
        await navigator.clipboard.writeText(text)
        return
      } catch {
        // Rejected — permissions, a secure-context edge case, an iframe without the
        // clipboard-write allow attribute. Fall through to the selection-based
        // fallback rather than giving up immediately; only its own failure below is
        // what copy() ultimately reports as cw--clipboard:failed.
      }
    }

    if (!this.#fallbackCopy(text)) {
      throw new Error("clipboard write unsupported")
    }
  }

  // Selection-based fallback for insecure contexts / browsers without the async
  // Clipboard API. `execCommand` is deprecated but still universally implemented for
  // exactly this case.
  #fallbackCopy(text) {
    const scratch = document.createElement("textarea")
    scratch.value = text
    scratch.setAttribute("readonly", "")
    // Off-screen, not display:none — a hidden element cannot be selected.
    scratch.style.position = "fixed"
    scratch.style.top = "0"
    scratch.style.left = "-9999px"
    document.body.appendChild(scratch)

    let copied = false
    try {
      scratch.select()
      scratch.setSelectionRange(0, text.length)
      copied = document.execCommand("copy")
    } catch {
      copied = false
    } finally {
      scratch.remove()
    }

    return copied
  }

  #succeed(text) {
    this.#clearTimer()

    if (this.hasSuccessClass) this.#successTarget.classList.add(this.successClass)
    if (this.hasStatusTarget) this.statusTarget.textContent = "Copied"

    this.dispatch("copied", { detail: { text } })

    this.#timer = setTimeout(() => this.#clearSuccessState(), this.successDurationValue)
  }

  #fail(error) {
    this.dispatch("failed", { detail: { error: error?.message ?? String(error) } })
  }

  #clearSuccessState() {
    if (this.hasSuccessClass) this.#successTarget.classList.remove(this.successClass)
    if (this.hasStatusTarget) this.statusTarget.textContent = ""
  }

  #clearTimer() {
    if (this.#timer === null) return

    clearTimeout(this.#timer)
    this.#timer = null
  }

  get #successTarget() {
    return this.hasButtonTarget ? this.buttonTarget : this.element
  }
}
