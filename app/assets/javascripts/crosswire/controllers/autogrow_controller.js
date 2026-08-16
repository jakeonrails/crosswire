import { Controller } from "@hotwired/stimulus"

/**
 * cw--autogrow — size a <textarea> to its content.
 *
 * RULE 0 — READ THIS FIRST, THEN PROBABLY DELETE THIS FILE. `field-sizing: content`
 * is Baseline CSS as of 2026 (Chrome/Edge 123+, Firefox 152+, Safari 26.2+ — every
 * current-generation engine) and does exactly this with zero JavaScript:
 *
 *   textarea { field-sizing: content; min-height: 3lh; max-height: 20lh; resize: vertical; }
 *
 * SHIP THE CSS. This controller exists ONLY to cover engines that don't support
 * `field-sizing` yet, and is a SUNSETTING component — plan to delete it, and the
 * `data-controller="cw--autogrow"` attributes that reference it, once your support
 * matrix no longer needs it. On any engine that DOES support the property, connect()
 * checks `CSS.supports("field-sizing", "content")` FIRST, before touching the DOM at
 * all, and returns immediately if it's true — so this file does nothing on a modern
 * browser regardless of whether it's wired up. It is always safe to ship both this
 * and the CSS above together.
 *
 * Values   maxRows (Number, optional — caps growth; the box scrolls past it)
 *
 * When it DOES run (an old engine, no `field-sizing` support): grows on `input`,
 * measuring ONCE per call — reset height, read scrollHeight, write height; a single
 * forced reflow, not a read/write/read/write chain that would thrash layout. Also
 * measures on connect(), which covers the Turbo cache-restore case: a textarea
 * brought back from Turbo's snapshot cache has its CONTENT restored but no live
 * sizing baked in (the snapshot is inert markup, not a laid-out page), and Stimulus
 * reconnects this controller the same way it does on any other page load — so the
 * connect()-time grow() call re-sizes a restored textarea exactly as it would a
 * freshly loaded one.
 */
export default class AutogrowController extends Controller {
  static values = { maxRows: Number }

  #bound = null
  #maxHeight = null

  connect() {
    // Rule 0 — let the CSS do it. Guarded against `CSS` not existing at all, not
    // just against `.supports` returning false: `CSS.supports` itself is old enough
    // to be safe on any real engine that would ever reach this fallback, but jsdom
    // (as pinned in package.json) implements no global `CSS` object whatsoever —
    // `typeof CSS` is "undefined", not an object with a `supports` method that
    // returns false. An unguarded `CSS.supports(...)` throws a ReferenceError in
    // that environment. Treating "no CSS.supports at all" the same as "not
    // supported" is also the technically correct behaviour for a genuinely ancient
    // engine, which is exactly who this fallback exists for.
    if (typeof CSS !== "undefined" && CSS.supports?.("field-sizing", "content")) return

    this.#bound = this.#grow.bind(this)
    this.element.addEventListener("input", this.#bound)
    this.element.style.overflowY = "hidden"
    this.#grow() // also covers the Turbo cache-restore case — see the docstring above
  }

  // R7 — only registers a listener when it actually took over from the CSS, so only
  // tear it down in that case; nothing else to release.
  disconnect() {
    if (!this.#bound) return

    this.element.removeEventListener("input", this.#bound)
    this.#bound = null
    this.#maxHeight = null
  }

  #grow() {
    const el = this.element

    el.style.height = "auto" // MUST reset before measuring, or scrollHeight only grows
    const height = el.scrollHeight
    const capped = this.#cap(height)

    el.style.height = `${capped ?? height}px`
    el.style.overflowY = capped !== null ? "auto" : "hidden"
  }

  // maxRows is expressed in rows, not pixels, so converting it needs the element's
  // own line-height/padding/border — read via getComputedStyle ONCE and cached,
  // rather than on every keystroke, since getComputedStyle can itself force a
  // synchronous layout if styles are pending.
  #cap(height) {
    if (!this.hasMaxRowsValue || this.maxRowsValue <= 0) return null

    if (this.#maxHeight === null) {
      const style = getComputedStyle(this.element)
      const lineHeight = Number.parseFloat(style.lineHeight) || 20
      const vertical = (Number.parseFloat(style.paddingTop) || 0) +
        (Number.parseFloat(style.paddingBottom) || 0) +
        (Number.parseFloat(style.borderTopWidth) || 0) +
        (Number.parseFloat(style.borderBottomWidth) || 0)

      this.#maxHeight = lineHeight * this.maxRowsValue + vertical
    }

    return height > this.#maxHeight ? this.#maxHeight : null
  }
}
