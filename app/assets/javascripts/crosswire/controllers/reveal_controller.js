import { Controller } from "@hotwired/stimulus"

/**
 * cw--reveal — toggle an input between `password` and `text`, or unmask masked text.
 *
 * Targets  input, trigger
 * Values   revealed (Boolean, default false)
 * Classes  revealed (optional, applied to this.element, guarded per R3)
 * Events   cw--reveal:revealed, cw--reveal:hidden (both cancelable, matching
 *          cw--disclosure's opened/closed)
 *
 * SECURITY — see the presenter docstring for the full statement. Revealing a
 * password field genuinely defeats the browser's shoulder-surfing / screen-capture
 * protections while revealed; this controller does not pretend that's free, and
 * never applies `type="text"` unless `revealed` is actually true.
 *
 * R4 — state lives in the `revealed` value; every mutation goes through `#apply`,
 * which sets the value AND renders in the SAME synchronous call (see the note on
 * `#apply` below for why rendering can't wait for Stimulus's own value-changed
 * callback). `revealedValueChanged` still exists and still renders — that's what
 * picks up a change made from OUTSIDE this controller: a server-rendered morph, or a
 * sibling controller writing the attribute directly per R5a #2 — which is the actual
 * case R4 is about.
 *
 * R7 / CACHE LEAK — a password left revealed (`type="text"`) inside Turbo's snapshot
 * cache is a real information leak the next time that page is restored. TWO things
 * guard against it, because they cover different moments and neither alone is
 * enough:
 *
 *   1. disconnect() forces `revealed` back to false — the ordinary R4a/R7 teardown
 *      discipline, covering the controller being torn down for ANY reason (a frame
 *      replacement, a morph, navigating away).
 *   2. `turbo:before-cache` (dispatched on `document`, BEFORE Turbo clones the
 *      current page into its snapshot cache) forces it too. This is the actually
 *      timing-correct fix for the caching case specifically: Turbo takes that
 *      snapshot from the LIVE DOM, and disconnect() does not run until later — after
 *      the new page has loaded and the old elements are actually removed. By then
 *      the snapshot already exists. disconnect() alone is not early enough to catch
 *      "reveal, then click a normal in-app link."
 *
 * Both go through `#apply(false)` — the same path as toggle()/show()/hide() — so
 * `data-cw--reveal-revealed-value` gets corrected, not just the live `type`. That
 * matters for the cached snapshot specifically: writing `input.type` alone and
 * leaving the stale `data-cw--reveal-revealed-value="true"` attribute in the cached
 * markup means the NEXT time that snapshot is restored, connect() reads "true" and
 * silently re-reveals the password. `#apply` fixes both at once.
 *
 * Never clears or replaces the input's `.value` when flipping `type` — that would
 * lose what the user typed, break password managers watching the field, and drop
 * focus. `type` is flipped in place and the caret/selection range is restored,
 * exactly as the reference implementation this is modelled on (@stimulus-components
 * /reveal) does.
 */
export default class RevealController extends Controller {
  static targets = ["input", "trigger"]
  static values = { revealed: { type: Boolean, default: false } }
  static classes = ["revealed"]

  // See R4a in docs/COMPONENT_CONTRACT.md: Stimulus runs value callbacks BEFORE
  // connect(), and the initial `previous` argument for a typed Boolean value is
  // `false` — not `undefined` — so a `previous === undefined` guard would silently
  // never fire and every connect would announce a phantom event.
  #ready = false

  #onBeforeCache = () => this.#apply(false)

  connect() {
    this.#render()
    this.#ready = true
    document.addEventListener("turbo:before-cache", this.#onBeforeCache)
  }

  disconnect() {
    this.#ready = false
    document.removeEventListener("turbo:before-cache", this.#onBeforeCache)
    this.#apply(false)
  }

  toggle(event) {
    event?.preventDefault()
    this.#apply(!this.revealedValue)
  }

  show() {
    this.#apply(true)
  }

  hide() {
    this.#apply(false)
  }

  // The ONE place any INTERNAL mutation happens: sets the value (so it stays the
  // single source of truth an outside morph can also drive) AND renders in the same
  // synchronous call, rather than waiting on revealedValueChanged.
  //
  // That render can't wait: Stimulus's value-changed callback is driven by a batched
  // MutationObserver, which is a microtask/macrotask round-trip away, not
  // synchronous, EVEN for a change made through the value setter itself. Two writes
  // to the same value within one synchronous tick — exactly what happens if
  // turbo:before-cache resets it and something calls toggle() again before the
  // observer's batch flushes — can net out to "no attribute change" from the
  // observer's point of view and get silently swallowed, leaving the DOM stuck out
  // of sync with the value it was supposed to reflect. Rendering synchronously here
  // makes the DOM correct immediately regardless of that batching.
  #apply(value) {
    this.revealedValue = value
    this.#render()
  }

  // Reached for BOTH the internal writes above (a redundant, harmless re-render) and
  // for genuinely external changes — the actual case R4 exists for.
  revealedValueChanged(value) {
    this.#render()

    if (!this.#ready) return

    this.dispatch(value ? "revealed" : "hidden", { detail: { revealed: value }, cancelable: true })
  }

  #render() {
    if (this.hasInputTarget) {
      const input = this.inputTarget
      const nextType = this.revealedValue ? "text" : "password"

      if (input.type !== nextType) {
        let selection = null
        try {
          selection = [input.selectionStart, input.selectionEnd]
        } catch {
          // Some input types never support selection; nothing to restore either way.
        }

        input.type = nextType // value is untouched

        if (selection) {
          try {
            input.setSelectionRange(selection[0], selection[1])
          } catch {
            // Restoring the caret is a nicety, not a correctness requirement.
          }
        }
      }
    }

    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-pressed", String(this.revealedValue))
    }

    if (this.hasRevealedClass) {
      this.element.classList.toggle(this.revealedClass, this.revealedValue)
    }
  }
}
