import { Controller } from "@hotwired/stimulus"

/**
 * cw--intersection — dispatch an event when the element enters or leaves the viewport.
 *
 * Values   threshold (Number, default 0), once (Boolean, default false),
 *          rootMargin (String, default "0px"), root (String, optional CSS selector)
 * Events   cw--intersection:entered, cw--intersection:left — detail carries the
 *          `IntersectionObserverEntry` itself (`detail.entry`), so a consumer can read
 *          `intersectionRatio`, `boundingClientRect`, etc. straight off it.
 *
 * Rule 0 — read this before wiring the controller up:
 *
 *   * Deferred loading: a `<turbo-frame loading="lazy">` needs no JavaScript at all.
 *     Turbo's own `AppearanceObserver` is an `IntersectionObserver`; this controller
 *     is for *reacting* to visibility (dispatching an event), not for loading content.
 *   * Long-list render cost: `content-visibility: auto` handles it natively and,
 *     unlike DOM-removing virtualization, keeps skipped content in the accessibility
 *     tree.
 *   * Reveal-on-scroll: a scroll-driven CSS animation (`animation-timeline: view()`)
 *     covers some of this with zero JS, but it is not yet Baseline — Firefox is the
 *     sole holdout as of 2026-08 — so gate it behind `@supports` with this controller
 *     as the fallback, not the other way round.
 *
 * Composition: infinite scroll is this controller plus a `<turbo-frame>`, with the
 * observed sentinel being the frame that replaces itself with the next page (sentinel
 * included) — not a bespoke infinite-scroll controller. Sticky-header elevation and
 * "poll only while visible" decompose the same way: this controller supplies the
 * event, a small amount of consumer code does the feature-specific part.
 *
 * Exhaustive teardown (R7): `disconnect()` calls `observer.disconnect()` and nulls the
 * reference. Turbo's snapshot cache turns every missed teardown into a per-visit leak,
 * and an orphaned `IntersectionObserver` holding a detached node is the textbook case.
 *
 * The observer is NOT re-created on every value-changed callback — Stimulus fires
 * those once up front during connect, before an observer exists yet, and the guard
 * below is a no-op at that point. It is re-created only when `threshold`, `rootMargin`
 * or `root` genuinely change after connect, and the old observer is always disconnected
 * before the new one is created.
 *
 * `once: true` unobserves after the first `entered` — read live off the value, not
 * baked into the observer config, so toggling it does not require a reconnect.
 *
 * jsdom has no real `IntersectionObserver`. This controller's jsdom test stubs the
 * global explicitly and verifies the wiring/teardown logic honestly; the real
 * behavioural assertions (does it actually fire on scroll) live in
 * `intersection_controller.browser.test.js`.
 */
export default class IntersectionController extends Controller {
  static values = {
    threshold: { type: Number, default: 0 },
    once: { type: Boolean, default: false },
    rootMargin: { type: String, default: "0px" },
    root: String
  }

  #observer = null

  connect() {
    this.#observe()
  }

  disconnect() {
    this.#teardown()
  }

  thresholdValueChanged() {
    this.#reconfigure()
  }

  rootMarginValueChanged() {
    this.#reconfigure()
  }

  rootValueChanged() {
    this.#reconfigure()
  }

  // Only reconfigures once an observer already exists — i.e. never on the initial
  // connect's value hydration, only on a genuine post-connect change. See the class
  // docstring: "do not re-create the observer on every value change."
  #reconfigure() {
    if (this.#observer) this.#observe()
  }

  #observe() {
    this.#teardown()

    const root = this.hasRootValue && this.rootValue !== ""
      ? document.querySelector(this.rootValue)
      : null

    this.#observer = new IntersectionObserver(this.#handleIntersect, {
      threshold: this.thresholdValue,
      rootMargin: this.rootMarginValue,
      root
    })

    this.#observer.observe(this.element)
  }

  // Stable reference (class field, not a bound method created per-call) so it can be
  // meaningfully passed to `IntersectionObserver` and, if ever needed, removed.
  #handleIntersect = (entries) => {
    for (const entry of entries) {
      if (entry.isIntersecting) {
        this.dispatch("entered", { detail: { entry } })

        // Unobserve after the first entry, not merely ignore later ones — the
        // observer itself is torn down so nothing keeps the detached logic alive.
        if (this.onceValue) this.#teardown()
      } else {
        this.dispatch("left", { detail: { entry } })
      }
    }
  }

  #teardown() {
    this.#observer?.disconnect()
    this.#observer = null
  }
}
