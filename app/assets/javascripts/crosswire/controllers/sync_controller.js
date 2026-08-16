import { Controller } from "@hotwired/stimulus"

const TRANSFORMS = {
  none: (value) => value,
  length: (value) => String(String(value).length),
  uppercase: (value) => String(value).toUpperCase(),
  lowercase: (value) => String(value).toLowerCase()
}

/**
 * cw--sync — mirror this element's value or state onto another element on every
 * change.
 *
 * Targets  none — the target is named by CSS selector, not a Stimulus target,
 *          because it is almost never a descendant of this controller's own
 *          element (a character counter's `<span>` sits next to the `<textarea>`,
 *          not inside it — a Stimulus target can only ever be a descendant).
 * Values   target (String, CSS selector, required), attribute (String, default
 *          "value" — the property/attribute WRITTEN on the target), transform
 *          (String: "none" default | "length" | "uppercase" | "lowercase")
 * Events   cw--sync:synced (detail: { value, target })
 *
 * Deliberately narrow — this is the generic primitive dependent selects,
 * character counters, range/slider readouts and dark-mode toggle mirrors all
 * compose from, not a feature controller for any one of them. Resist adding
 * feature-specific options; a use case that needs more should wrap this
 * controller rather than grow it.
 *
 * READING this element: checkbox/radio inputs read `.checked`; anything with a
 * `.value` property (input, select, textarea, output, meter, progress) reads
 * that; everything else reads `.textContent`. This is intentionally NOT
 * controlled by `attribute` — `attribute` names only the WRITE side, because the
 * two ends are frequently different kinds of element (an `<input>` source, a
 * `<span>` readout target), and forcing one shared property name would make the
 * single most common use case in the catalog — a character counter, source
 * `.value` written as target `.textContent` — impossible to express with one
 * name.
 *
 * WRITING the target: `attribute` is set as a DOM property when the target
 * already has a property by that name (`"value" in target`, `"textContent" in
 * target`, `"checked" in target`, …), and via `setAttribute` otherwise. Setting a
 * property this way does NOT dispatch the target's own `input`/`change` event —
 * usually what you want for a read-only mirror; if the target itself must react,
 * have its own controller listen for `cw--sync:synced` instead (composition via
 * events, per R5, not a second write path here).
 *
 * R7: this controller holds no listeners, timers, or observers beyond the
 * Stimulus action binding on its own element, which Stimulus itself tears down —
 * there is nothing for an explicit `disconnect()` to release.
 *
 * Unlike `disclosure`/`tabs`, `sync()` runs unconditionally on `connect()` and
 * always dispatches — there is no R4a-style `#ready` guard here, because
 * "synced" describes a mirroring operation that just happened, not a state
 * TRANSITION the way "opened"/"closed" do. Showing the correct initial state on
 * connect (e.g. a character counter reading "0/280" on first paint) is exactly
 * the intended behaviour, not a phantom event to suppress.
 */
export default class SyncController extends Controller {
  static values = {
    target: String,
    attribute: { type: String, default: "value" },
    transform: { type: String, default: "none" }
  }

  connect() {
    this.sync()
  }

  sync() {
    const target = this.#target()
    if (!target) return

    const raw = this.#read()
    const value = this.#transform(raw)

    this.#write(target, value)

    this.dispatch("synced", { detail: { value, target } })
  }

  #target() {
    if (!this.hasTargetValue || this.targetValue === "") return null

    try {
      return document.querySelector(this.targetValue)
    } catch {
      // An invalid selector should not crash the page over a mirroring behaviour.
      return null
    }
  }

  #read() {
    const el = this.element

    if (el.type === "checkbox" || el.type === "radio") return el.checked
    if ("value" in el) return el.value

    return el.textContent
  }

  #transform(value) {
    const fn = TRANSFORMS[this.transformValue] || TRANSFORMS.none
    return fn(value)
  }

  #write(target, value) {
    const attr = this.attributeValue || "value"

    if (attr in target) {
      target[attr] = value
    } else {
      target.setAttribute(attr, value)
    }
  }
}
