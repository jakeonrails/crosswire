import { Controller } from "@hotwired/stimulus"

/**
 * cw--char-count — mirror an input's length into an `output` target.
 *
 * Targets  input, output
 * Values   max (Number, required), warnAt (Number, default 0.9 — ratio of max)
 * Classes  over, warn (both optional, guarded per R3)
 *
 * A11Y DECISION — read before changing this file. Writing the live count into an
 * `aria-live="polite"` region on every `input` event announces every keystroke: a
 * screen reader reads "279... 278... 277..." for as long as the user types, which is
 * worse than no live region at all. Rather than add a second, visually-hidden
 * announcer element (which would need its own target, plus its own "must already be
 * in the DOM before it changes" caveat), this controller DEBOUNCES its writes to the
 * single `output` target instead: the DOM — and therefore the live region — only
 * updates `DEBOUNCE_MS` after the user stops typing, not on every keystroke. A screen
 * reader only announces a live region when its content actually changes, so
 * throttling the writes throttles the announcements for free. 300ms reads as "live"
 * to a sighted user (well under the ~500-1000ms most UI treats as instantaneous)
 * while collapsing a fast typist's whole burst into one announcement at the pause.
 * The trade-off accepted: crossing into the over-limit state waits out the same
 * debounce window as any other update rather than announcing instantly — acceptable
 * for a warning that doesn't block anything by itself, not for an interruption.
 *
 * The FIRST render, in connect(), is immediate and NOT debounced, so a pre-filled or
 * Turbo-cache-restored value renders correctly before the user has typed anything.
 *
 * Over-limit sets `aria-invalid="true"` on the input — not just a colour or class —
 * because that is the one signal a screen reader user gets automatically, even
 * without visiting the live region. The announced text always includes the word
 * "over" so colour is never the only carrier either.
 */
export default class CharCountController extends Controller {
  static targets = ["input", "output"]
  static values = {
    max: Number,
    warnAt: { type: Number, default: 0.9 }
  }
  static classes = ["over", "warn"]

  static DEBOUNCE_MS = 300

  #timer = null

  connect() {
    this.#render()
  }

  // R7 — the only side effect this controller owns is the debounce timer.
  disconnect() {
    this.#clearTimer()
  }

  update() {
    this.#clearTimer()
    this.#timer = setTimeout(() => this.#render(), CharCountController.DEBOUNCE_MS)
  }

  #render() {
    this.#timer = null
    if (!this.hasInputTarget) return

    const max = this.maxValue
    const used = this.#length(this.inputTarget.value)
    const remaining = max - used
    const over = remaining < 0
    // Compared as `used >= max * warnAt` rather than the algebraically equivalent
    // `remaining <= max * (1 - warnAt)` — the subtraction on the right-hand side of
    // the second form is a real source of floating-point error (e.g. `1 - 0.8` is
    // 0.19999999999999996 in IEEE 754 double precision, not 0.2), which silently
    // missed the warn state exactly at the boundary a caller is most likely to test.
    const warn = !over && used >= max * this.warnAtValue

    if (this.hasOutputTarget) {
      this.outputTarget.textContent = over
        ? `${Math.abs(remaining)} characters over limit`
        : `${remaining} characters remaining`
    }

    if (over) {
      this.inputTarget.setAttribute("aria-invalid", "true")
    } else {
      this.inputTarget.removeAttribute("aria-invalid")
    }

    if (this.hasOverClass) this.element.classList.toggle(this.overClass, over)
    if (this.hasWarnClass) this.element.classList.toggle(this.warnClass, warn)
  }

  // Counts grapheme clusters, not UTF-16 code units, so a family emoji ("\u{1F468}...")
  // counts as one character to a human rather than several. Intl.Segmenter is broadly
  // supported but feature-detected anyway rather than assumed.
  #length(value) {
    if (typeof Intl !== "undefined" && Intl.Segmenter) {
      return [...new Intl.Segmenter(undefined, { granularity: "grapheme" }).segment(value)].length
    }

    return value.length
  }

  #clearTimer() {
    if (this.#timer === null) return

    clearTimeout(this.#timer)
    this.#timer = null
  }
}
