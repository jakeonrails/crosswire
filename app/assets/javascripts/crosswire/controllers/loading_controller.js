import { Controller } from "@hotwired/stimulus"

/**
 * cw--loading — mark an in-flight Turbo request with a bare `data-loading` attribute.
 *
 * Values   delay (Number ms, default 100 — anti-flicker threshold)
 * Classes  loading (optional convenience class, applied alongside the attribute)
 * Actions  start (turbo:submit-start, turbo:before-fetch-request),
 *          stop (turbo:submit-end, turbo:frame-render, turbo:fetch-request-error)
 *
 * RULE 0: Turbo already sets `aria-busy="true"` on the form/frame it is
 * submitting/loading, and `data-turbo-submits-with="Saving…"` swaps a submit
 * button's own label for the duration, for free. Reach for either first — see
 * `Crosswire::Presenters::Loading`'s docstring for the full case. This earns its
 * keep for marking the SUBMITTER separately from the form/frame, an anti-flicker
 * delay threshold, and a `data-loading` attribute Tailwind v4's `data-loading:` /
 * `in-data-loading:` / `has-data-loading:` variants already understand with zero CSS
 * shipped — the Livewire-compatible name is deliberate.
 *
 * `data-loading` is intentionally BARE, not namespaced `data-cw-loading` — matching
 * Livewire's own attribute is the entire point; a gem-prefixed name would not compose
 * with a consumer's existing `data-loading:` Tailwind classes or third-party CSS
 * written against the Livewire convention.
 *
 * PLACEMENT is entirely the caller's call — every Turbo fetch/submit event bubbles,
 * so this controller works identically stacked on a `<form>`, a single
 * `<turbo-frame>`, a `<table>` row wrapping several, or `<body>` for a page-wide
 * indicator. Scope it as narrowly as the UI needs; nothing here assumes a shape.
 *
 * REF-COUNTED per element: two overlapping requests that both touch the same element
 * (nested frames, a form that triggers a background frame reload, a doubled-clicked
 * frame reload) do not clear `data-loading` until the LAST one finishes, and the
 * anti-flicker timer is armed once per element, not once per request.
 *
 * VERIFIED AGAINST @hotwired/turbo's OWN SOURCE — the one wrinkle this wiring exists
 * to route around. `FormSubmission` builds its `FetchRequest` with `target:
 * formElement` (turbo.es2017-esm.js's `FormSubmission` constructor), and
 * `FetchRequest#perform()` dispatches `turbo:before-fetch-request` on that SAME
 * target BEFORE it dispatches `turbo:submit-start` (also targeted at `formElement`).
 * So for every ordinary form submission, both events fire on the identical element —
 * counting both as a "start" would leave `data-loading` stuck forever after any
 * submission whose response is not itself a `<turbo-frame>` render (a Turbo Stream
 * response, for instance, has no `turbo:frame-render` to close the second count).
 * `start()` below skips `turbo:before-fetch-request` whenever its target is a
 * `<form>`, precisely because `turbo:submit-start`/`turbo:submit-end` already cover
 * that element completely; `turbo:before-fetch-request` only ever does real marking
 * work here for a `<turbo-frame>` loading its own `src` — the case with no
 * `turbo:submit-start` equivalent at all.
 *
 * `disconnect()` clears every pending timer AND removes `data-loading` from every
 * element this instance ever marked (R7) — a controller torn down mid-request (its
 * scope replaced outright by a frame navigation) must not leave a spinner stuck on.
 */
export default class LoadingController extends Controller {
  static values = {
    delay: { type: Number, default: 100 }
  }

  static classes = ["loading"]

  // element -> { count, timerId }. A plain Map, not a WeakMap: disconnect() must be
  // able to ITERATE it to release every timer and attribute still outstanding.
  // Entries are deleted the instant their count reaches zero, so this never holds
  // more than the requests genuinely in flight.
  #entries = new Map()

  disconnect() {
    for (const [el, entry] of this.#entries) {
      if (entry.timerId !== null) clearTimeout(entry.timerId)
      this.#clear(el)
    }
    this.#entries.clear()
  }

  start(event) {
    // See the class docstring's "VERIFIED AGAINST" note: turbo:before-fetch-request
    // re-fires on the exact element turbo:submit-start already marks for any form
    // submission, and nothing in the stop list below would ever close that second
    // count for a non-frame response.
    if (event.type === "turbo:before-fetch-request" && event.target instanceof HTMLFormElement) return

    this.#mark(event.target)
    this.#mark(event.detail?.formSubmission?.submitter)
  }

  stop(event) {
    this.#unmark(event.target)
    this.#unmark(event.detail?.formSubmission?.submitter)
  }

  #mark(el) {
    if (!(el instanceof Element)) return

    const entry = this.#entries.get(el) || { count: 0, timerId: null }
    entry.count++

    // Only the FIRST concurrent request for this element arms the anti-flicker
    // timer — a second, overlapping one piggybacks on it rather than restarting the
    // clock.
    if (entry.count === 1) {
      entry.timerId = setTimeout(() => {
        entry.timerId = null
        this.#set(el)
      }, this.delayValue)
    }

    this.#entries.set(el, entry)
  }

  #unmark(el) {
    if (!(el instanceof Element)) return

    const entry = this.#entries.get(el)
    if (!entry) return

    entry.count = Math.max(0, entry.count - 1)
    if (entry.count > 0) return

    if (entry.timerId !== null) clearTimeout(entry.timerId)
    this.#entries.delete(el)
    this.#clear(el)
  }

  #set(el) {
    el.setAttribute("data-loading", "")
    if (this.hasLoadingClass) el.classList.add(...this.loadingClasses)
  }

  #clear(el) {
    el.removeAttribute("data-loading")
    if (this.hasLoadingClass) el.classList.remove(...this.loadingClasses)
  }
}
