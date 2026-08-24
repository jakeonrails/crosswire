import { Controller } from "@hotwired/stimulus"
import { usePreserve } from "crosswire/morph"

/**
 * cw--combobox — a text input with an attached, filterable listbox and a hidden
 * field carrying the submitted value.
 *
 * WAI-ARIA APG Combobox (editable, list autocomplete):
 * https://www.w3.org/WAI/ARIA/apg/patterns/combobox/
 *
 * Targets  input, field, listbox, option, status, empty, frame
 * Values   value (String), expanded (Boolean), active (String, default ""),
 *          filter (String, "client"), autocomplete (String, "list"), src (String),
 *          param (String, "q"), delay (Number, 200), minLength (Number, 0),
 *          wrap (Boolean, true), clearOnEscape (Boolean, true),
 *          resultsMessage (String), emptyMessage (String)
 * Classes  active (optional, applied to the active OPTION — see R3a below),
 *          expanded (optional, on this.element)
 * Events   cw--combobox:opened, :closed, :selected (detail { value, display, option }),
 *          :filtered (detail { query, count }), :cleared
 * Preserve static preservedValues = ["value", "expanded"] — see the morph paragraph.
 *
 * ANTI-COMPOSITION: this controller does NOT compose `cw--roving-focus`, even
 * though "combobox = roving-focus + listbox" is the obvious wrong guess — see
 * `Crosswire::Presenters::Combobox`'s class docstring. DOM focus never leaves the
 * `input` target, for the entire lifetime of this controller; no `option` ever
 * receives a `tabindex`. The currently "active" option is tracked purely through
 * the `active` value, rendered onto `input` as `aria-activedescendant` and onto the
 * matching option as `aria-selected`/the `active` class — never as real DOM focus.
 *
 * R4 — SINGLE WRITE PATH PER VALUE, exactly one DOM-writing private method per
 * value, called from BOTH that value's own `*ValueChanged` callback and from
 * `connect()`'s defensive re-render (the same "re-assert from the DOM, morph may
 * have clobbered it" idiom `cw--disclosure` uses) — an action handler only ever
 * DECIDES what the new value should be, never touches the DOM itself:
 *
 *   - `value` → `#applyValue` writes `field.value` and each option's
 *     `aria-selected` (the PERSISTED selection baseline — see the note on `active`
 *     below for why this can be temporarily overridden), fires a bubbling `change`
 *     on the hidden field (hidden inputs fire no events of their own — this is the
 *     composition seam with `cw--autosubmit`/`cw--dirty-form`), and — gated by
 *     `#ready` (R4a) — dispatches `selected`.
 *   - `expanded` → `#applyExpanded` toggles the listbox's `hidden`, the input's
 *     `aria-expanded`, the optional `expanded` class, and — R5a mechanism 2 — writes
 *     `cw--click-outside`'s OWN `enabled` value attribute directly onto this same
 *     element (COMPOSED, not reimplemented; that controller's own docstring names
 *     this exact use case). Closing also clears `active` (nothing is "active" in a
 *     hidden listbox). Gated by `#ready`, dispatches `opened`/`closed`.
 *   - `active` → `#applyActive` sets or REMOVES `aria-activedescendant` on the
 *     input and calls `scrollIntoView({ block: "nearest" })` on the newly active
 *     option. Per APG's own combobox-list example, `aria-selected` tracks whichever
 *     option is CURRENTLY ACTIVE while arrowing through the list, not a separate
 *     persisted concept — so while there IS an active option, this method also
 *     overrides `aria-selected` to track it (clearing every other option), exactly
 *     the same way `#applyValue` does for the baseline. When `active` goes back to
 *     "" (closing, or nothing active yet), this method deliberately does NOT touch
 *     `aria-selected` at all — it leaves whatever `#applyValue` last asserted alone,
 *     which is what stops closing the listbox right after a selection from wiping
 *     the very `aria-selected="true"` that selection just set. No named event is
 *     dispatched for `active` at all — it is UI-only, with no server-rendered
 *     counterpart (see the morph paragraph).
 *
 * FORM INTEGRATION: `input` (the visible text field) carries no `name` — it is
 * display-only. `field` (a sibling `<input type="hidden">`) is the ONLY thing this
 * component ever submits, and `#applyValue` above is the ONLY code that ever writes
 * `field.value`. `#disabled` (every action below checks it first) reads
 * `field.matches(":disabled")` — deliberately NOT the `.disabled` IDL property,
 * which reflects only the element's OWN `disabled` attribute and, per spec, does
 * NOT account for an ancestor `<fieldset disabled>` cascading onto it (verified
 * directly, not assumed — an easy mistake, since it reads as though it should be
 * the computed state). The `:disabled` CSS pseudo-class is the actual "is this
 * control disabled" concept the HTML spec defines for form participation, and DOES
 * fold the fieldset cascade in, with no extra wiring needed for it. A `reset`
 * listener on the closest `<form>` (added in `connect()`,
 * removed in `disconnect()`, R7 stable bound reference) restores both the visible
 * text and the submitted value on a real `reset`. The visible `input` is an
 * ordinary `type="text"` control, so its own `.defaultValue` genuinely stays pinned
 * to the server-rendered `value=` attribute no matter what this controller writes
 * to `.value` later, and restoring it is a one-line read-back. `field` is NOT:
 * `<input type="hidden">` sits in HTML's "value mode: default" bucket (alongside
 * checkbox/radio/submit/button), where the `value` IDL property IS the content
 * attribute — `field.defaultValue` silently tracks whatever `#applyValue` last
 * wrote the moment it writes it even once, so it cannot be trusted to recover the
 * ORIGINAL server-rendered value after any interaction at all (verified directly
 * against jsdom's implementation of the spec, not assumed). `connect()` therefore
 * snapshots `this.valueValue` into a private field before anything can touch it,
 * and `reset` restores from that snapshot instead — `valueValue` itself has no such
 * quirk, since a Stimulus value is just a plain `data-*-value` attribute with none
 * of native form controls' reflection semantics.
 *
 * FILTER MODES — `filterValue` picks one of three completely different `filter()`
 * bodies. `"none"`: no filtering at all, just `open()` (a select-shaped combobox
 * over a short static list). `"client"`: options are already all present in the
 * DOM; `#filterClient` only ever toggles their `hidden` attribute (case-insensitive
 * substring match against each option's own rendered display text) and updates the
 * live region ONLY when the visible count actually changes, never on every
 * keystroke. `"remote"`: THERE IS NO FETCH PATH HERE. `#filterRemote` debounces
 * (`delayValue`, `#timeout` — the exact `cw--autosubmit` idiom: a single field,
 * `clearTimeout` in `disconnect()`, R7) and then does exactly one thing:
 * `frameTarget.src = ...`. Turbo owns everything past that point — cancelling the
 * previous in-flight frame request the instant a new `src` lands is Turbo's job,
 * not this controller's, and a frame request's `Accept` header is HTML, so the
 * classic Rails 406-on-JSON pitfall that a hand-rolled `fetch()` would have to dodge
 * never comes up. `min_length` below `minLengthValue` sends nothing at all.
 *
 * R8a — FOUR ARROW DESCRIPTORS, ONE PAIR OF METHODS: the presenter wires
 * `keydown.down`/`keydown.alt+down` (both to `down`) and
 * `keydown.up`/`keydown.alt+up` (both to `up`) because Stimulus key filters are
 * EXACT-MATCH on modifier state (docs/COMPONENT_CONTRACT.md R8a) — a bare
 * `keydown.down` filter would silently swallow every Alt+ArrowDown. `down`/`up`
 * read `event.altKey` themselves to tell "open with no active option" (Alt) apart
 * from "open, active = first/last" (plain), and — only while already expanded —
 * "Alt+ArrowUp closes without changing the value" apart from ordinary movement.
 * `event.preventDefault()` runs unconditionally in both (before the disabled
 * check's early return even matters in practice, since a disabled input cannot
 * receive keyboard events at all) — the text cursor must never move as a side
 * effect of a key this controller intercepts.
 *
 * HOME/END ARE DELIBERATELY NOT WIRED HERE AT ALL — no presenter action, no method
 * in this file. That is APG's own position for an EDITABLE combobox: Home/End
 * belong to the text cursor, exactly as in any other text input, not to jumping the
 * active option — a documented departure from this repo's own UI pattern catalog
 * (research/notes/08, line 3526), resolved in APG's favour. See
 * `docs/recipes/corrections.md`.
 *
 * MORPH SAFETY — `usePreserve(this)` in `connect()` (disclosure's own ordering:
 * re-render from values, THEN `#ready = true`, THEN `usePreserve`), guarding
 * `static preservedValues = ["value", "expanded"]`. `value` so a background stream
 * landing elsewhere on the page cannot silently revert a choice this controller
 * already wrote (B2's divergence check: the SERVER still wins if this controller
 * never actually wrote a value different from what it last synced). `expanded` so
 * an unrelated render cannot collapse the listbox out from under someone mid-typing.
 * `active` is NEVER preserved — it is transient navigation state with no
 * server-rendered counterpart, and morph legitimately invalidates it. KNOWN
 * RESIDUAL, observed and recorded rather than papered over (see
 * `combobox_controller.browser.test.js` tests 20/21): the characters the user has
 * typed live in `input`'s `value` PROPERTY, and `input` is a DESCENDANT of the root
 * this controller's `usePreserve` guards — `createMorphGuard`'s B1 per-element
 * scoping (`event.target !== element`, `crosswire/morph.js`) means a guard on the
 * root cannot reach a descendant's property, by construction, no matter what is
 * listed in `preservedValues`. The actual fix, per `crosswire/morph`'s own Rule 0,
 * is to narrow the SERVER-SIDE update's scope with
 * `turbo_stream.replace(target, method: :morph)` so this subtree is never the thing
 * being morphed into in the first place.
 */
export default class ComboboxController extends Controller {
  static targets = ["input", "field", "listbox", "option", "status", "empty", "frame"]
  static classes = ["active", "expanded"]
  static values = {
    value: String,
    expanded: Boolean,
    active: { type: String, default: "" },
    filter: { type: String, default: "client" },
    autocomplete: { type: String, default: "list" },
    src: String,
    param: { type: String, default: "q" },
    delay: { type: Number, default: 200 },
    minLength: { type: Number, default: 0 },
    wrap: { type: Boolean, default: true },
    clearOnEscape: { type: Boolean, default: true },
    resultsMessage: String,
    emptyMessage: String
  }

  static preservedValues = ["value", "expanded"]

  // R4a — see docs/COMPONENT_CONTRACT.md: Stimulus fires every *ValueChanged
  // callback BEFORE connect(), with the type default as `previous`, so a
  // `previous === undefined` guard would silently never fire and every connect
  // would announce phantom events.
  #ready = false
  #timeout = null
  #lastAnnouncedCount = null
  #form = null
  #initialValue = ""

  connect() {
    // Re-assert from the DOM first — the same defensive re-render `cw--disclosure`
    // does in its own connect() — idempotent DOM writes only, no events dispatched
    // from these three calls (that only ever happens from the *ValueChanged
    // callbacks themselves, which Stimulus already ran once, automatically, before
    // this method started).
    this.#applyValue(this.valueValue)
    this.#applyExpanded(this.expandedValue)
    this.#applyActive(this.activeValue)

    // Captured here, NOT read back off `fieldTarget.defaultValue` on reset: a
    // hidden input is HTML's "value mode: default" category (same bucket as
    // checkbox/radio/submit), where the `value` IDL attribute IS the content
    // attribute — there is no separate dirty-value-flag divergence the way a text
    // input has, so `field.defaultValue` silently tracks whatever this controller
    // last wrote, not the server-rendered original, the moment `#applyValue` runs
    // even once. `valueValue` itself has no such quirk (a plain Stimulus value,
    // backed by a `data-*-value` attribute with no native reflection semantics), so
    // capturing it here, before any user interaction is even possible, is the only
    // reliable "what did the server render" snapshot.
    this.#initialValue = this.valueValue

    this.#form = this.element.closest("form")
    this.#form?.addEventListener("reset", this.#onReset)

    this.#ready = true
    usePreserve(this)
  }

  disconnect() {
    this.#ready = false
    this.#clearTimeout()
    this.#form?.removeEventListener("reset", this.#onReset)
    this.#form = null
  }

  // --- value/expanded/active: the three single write paths (R4) ----------------------

  valueValueChanged(value) {
    this.#applyValue(value)

    // Hidden inputs fire no events of their own — this is the composition seam
    // with cw--autosubmit / cw--dirty-form, deliberately unconditional (unlike the
    // dispatch below): a form-level listener needs to see this transition exactly
    // once per actual write, connect-time hydration included.
    if (this.hasFieldTarget) {
      this.fieldTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }

    if (!this.#ready) return
    this.dispatch("selected", {
      detail: { value, display: this.hasInputTarget ? this.inputTarget.value : "", option: this.#optionByValue(value) }
    })
  }

  expandedValueChanged(value) {
    this.#applyExpanded(value)

    if (!this.#ready) return
    this.dispatch(value ? "opened" : "closed")
  }

  // No event dispatch here, ever — see the class docstring's note on why `active`
  // is UI-only.
  activeValueChanged(id) {
    this.#applyActive(id)
  }

  // --- actions -------------------------------------------------------------------------
  // Every action below early-returns on `#disabled` — docs/COMPONENT_CONTRACT.md's
  // "every action early-returns when fieldTarget.disabled" guard, which covers an
  // ancestor `<fieldset disabled>` for free because `#disabled` reads the computed
  // `:disabled` pseudo-class, not the `.disabled` IDL property (see that getter's
  // own docstring below for why the distinction matters).

  filter(event) {
    if (this.#disabled) return

    this.open()

    if (this.filterValue === "client") {
      this.#filterClient()
    } else if (this.filterValue === "remote") {
      this.#filterRemote()
    }

    if (this.autocompleteValue === "both" && this.filterValue !== "remote") {
      this.#autocomplete(event)
    }
  }

  down(event) {
    if (this.#disabled) return
    event.preventDefault()
    this.#move(1, event.altKey)
  }

  up(event) {
    if (this.#disabled) return
    event.preventDefault()
    this.#move(-1, event.altKey)
  }

  enter(event) {
    if (this.#disabled) return
    if (this.activeValue === "") return // NOT intercepted — the form submits normally

    event.preventDefault()
    const option = this.#optionById(this.activeValue)
    if (option) this.#selectOption(option)
  }

  // Two-stage, per APG: expanded closes first; only a SECOND Escape (already
  // collapsed) clears the text and the value.
  escape() {
    if (this.#disabled) return

    if (this.expandedValue) {
      this.close()
      return
    }

    if (this.clearOnEscapeValue) {
      this.#clearAll()
    }
  }

  tabOut() {
    if (this.#disabled) return
    this.close()
  }

  open() {
    if (this.#disabled) return
    this.expandedValue = true
  }

  close() {
    if (this.#disabled) return
    this.expandedValue = false
  }

  select(event) {
    if (this.#disabled) return
    this.#selectOption(event.currentTarget, event.params)
  }

  // mousedown->preventBlur, wired on every option (catalog-named pitfall: without
  // this, the input blurs — and the listbox closes as a result — BEFORE the
  // option's click ever fires, so the click lands on nothing).
  preventBlur(event) {
    event.preventDefault()
  }

  clear(event) {
    if (this.#disabled) return
    event?.preventDefault()
    this.#clearAll()
    this.inputTarget?.focus()
  }

  // Remote frame renders arrive with no connect() of their own for the options
  // inside — the same idiom cw--selection and cw--roving-focus use to stay correct
  // across content churn.
  optionTargetConnected() {
    this.#recomputeOptions()
  }

  optionTargetDisconnected() {
    this.#recomputeOptions()
  }

  // --- single write paths (private) -----------------------------------------------------

  #applyValue(value) {
    if (this.hasFieldTarget) this.fieldTarget.value = value ?? ""

    this.optionTargets.forEach((option) => {
      const optionValue = option.getAttribute(`data-${this.identifier}-value-param`)
      option.setAttribute("aria-selected", String(value !== "" && optionValue === value))
    })
  }

  #applyExpanded(value) {
    if (this.hasListboxTarget) this.listboxTarget.hidden = !value
    if (this.hasInputTarget) this.inputTarget.setAttribute("aria-expanded", String(value))
    if (this.hasExpandedClass) this.element.classList.toggle(this.expandedClass, value)

    // R5a mechanism 2 — cw--click-outside's OWN documented external-write path,
    // never a cross-controller method call. Armed only while expanded, so the very
    // pointerdown that OPENS this combobox (landing on the input itself) is never
    // misread as an outside click on itself.
    this.element.setAttribute("data-cw--click-outside-enabled-value", String(value))

    if (!value) this.activeValue = ""
  }

  #applyActive(id) {
    if (this.hasInputTarget) {
      if (id) {
        this.inputTarget.setAttribute("aria-activedescendant", id)
      } else {
        this.inputTarget.removeAttribute("aria-activedescendant")
      }
    }

    if (id === "") {
      // Nothing is active (closed, or navigation hasn't started yet) — leave
      // aria-selected exactly as #applyValue last asserted it; only the ACTIVE
      // class is cleared. Touching aria-selected here would wipe out the
      // just-set selection the moment a select() closes the listbox (select()
      // writes valueValue, THEN close() clears active).
      if (this.hasActiveClass) {
        this.optionTargets.forEach((option) => option.classList.remove(this.activeClass))
      }
      return
    }

    this.optionTargets.forEach((option) => {
      const isActive = option.id === id
      option.setAttribute("aria-selected", String(isActive))
      if (this.hasActiveClass) option.classList.toggle(this.activeClass, isActive)
      // jsdom implements no layout at all and has no scrollIntoView — same shape as
      // the offsetParent gotcha docs/COMPONENT_CONTRACT.md's test-environment-gotchas
      // table names. Real scroll behaviour is only ever asserted in the browser tier.
      if (isActive) option.scrollIntoView?.({ block: "nearest" })
    })
  }

  // --- movement --------------------------------------------------------------------------

  #move(delta, altKey) {
    if (!this.expandedValue) {
      this.open()
      if (altKey) return // Alt+ArrowDown/Up opens with NO active option

      const options = this.#navigableOptions()
      if (options.length === 0) return

      const target = delta > 0 ? options[0] : options[options.length - 1]
      this.activeValue = target.id
      return
    }

    // Already expanded — Alt+ArrowUp closes without changing anything.
    if (altKey && delta < 0) {
      this.close()
      return
    }

    const options = this.#navigableOptions()
    if (options.length === 0) return

    const currentIndex = options.findIndex((option) => option.id === this.activeValue)
    let nextIndex

    if (currentIndex === -1) {
      nextIndex = delta > 0 ? 0 : options.length - 1
    } else if (this.wrapValue) {
      nextIndex = ((currentIndex + delta) % options.length + options.length) % options.length
    } else {
      nextIndex = Math.max(0, Math.min(options.length - 1, currentIndex + delta))
    }

    this.activeValue = options[nextIndex].id
  }

  #navigableOptions() {
    return this.optionTargets.filter((option) => !option.hidden && option.getAttribute("aria-disabled") !== "true")
  }

  // --- filtering ---------------------------------------------------------------------------

  #filterClient() {
    const query = this.inputTarget.value.trim().toLowerCase()
    let count = 0

    this.optionTargets.forEach((option) => {
      const matches = query === "" || this.#optionDisplay(option).toLowerCase().includes(query)
      option.hidden = !matches
      if (matches) count++
    })

    if (this.activeValue !== "") {
      const active = this.#optionById(this.activeValue)
      if (!active || active.hidden) this.activeValue = ""
    }

    this.#updateEmpty(count)
    this.#announceCount(count)

    this.dispatch("filtered", { detail: { query, count } })
  }

  #filterRemote() {
    this.#clearTimeout()
    const query = this.inputTarget.value

    if (query.length < this.minLengthValue) return

    this.#timeout = setTimeout(() => {
      this.#timeout = null
      this.#writeFrameSrc(query)
    }, this.delayValue)
  }

  #writeFrameSrc(query) {
    if (!this.hasFrameTarget || !this.hasSrcValue) return

    const url = new URL(this.srcValue, window.location.origin)
    url.searchParams.set(this.paramValue, query)
    this.frameTarget.src = url.toString()
  }

  #clearTimeout() {
    if (this.#timeout === null) return
    clearTimeout(this.#timeout)
    this.#timeout = null
  }

  // Only client/none filtering, never remote (completing against options that
  // have not arrived yet is meaningless — the presenter also raises at
  // construction time for remote + autocomplete: "both").
  #autocomplete(event) {
    if (event && (event.inputType === "deleteContentBackward" || event.inputType === "deleteContentForward")) return

    const typed = this.inputTarget.value
    if (typed === "") return

    const match = this.optionTargets.find(
      (option) =>
        !option.hidden &&
        option.getAttribute("aria-disabled") !== "true" &&
        this.#optionDisplay(option).toLowerCase().startsWith(typed.toLowerCase())
    )
    if (!match) return

    const full = this.#optionDisplay(match)
    this.inputTarget.value = full
    this.inputTarget.setSelectionRange(typed.length, full.length)
  }

  #updateEmpty(count) {
    if (this.hasEmptyTarget) this.emptyTarget.hidden = count !== 0
  }

  // Live region updated ONLY when the count actually changed — never on every
  // keystroke, which would otherwise spam a screen reader mid-typing.
  #announceCount(count) {
    if (count === this.#lastAnnouncedCount) return
    this.#lastAnnouncedCount = count

    if (!this.hasStatusTarget) return

    this.statusTarget.textContent =
      count === 0 ? this.emptyMessageValue : this.resultsMessageValue.replace("%{count}", String(count))
  }

  #recomputeOptions() {
    this.#applyValue(this.valueValue)
    this.#applyActive(this.activeValue)
    this.#updateEmpty(this.optionTargets.filter((option) => !option.hidden).length)
  }

  // --- selection -----------------------------------------------------------------------

  #selectOption(option, params) {
    const value = params?.value ?? option.getAttribute(`data-${this.identifier}-value-param`) ?? ""
    const display = params?.display ?? option.getAttribute(`data-${this.identifier}-display-param`) ?? ""

    if (this.hasInputTarget) this.inputTarget.value = display
    this.valueValue = value
    this.close()
    this.inputTarget?.focus()
  }

  #clearAll() {
    if (this.hasInputTarget) this.inputTarget.value = ""
    this.valueValue = ""
    this.activeValue = ""
    this.dispatch("cleared")
  }

  #optionById(id) {
    return this.optionTargets.find((option) => option.id === id)
  }

  #optionByValue(value) {
    return this.optionTargets.find((option) => option.getAttribute(`data-${this.identifier}-value-param`) === value)
  }

  #optionDisplay(option) {
    return option.getAttribute(`data-${this.identifier}-display-param`) ?? (option.textContent || "").trim()
  }

  // --- form reset (R7 stable bound reference) -------------------------------------------

  #onReset = () => {
    if (this.hasInputTarget) this.inputTarget.value = this.inputTarget.defaultValue
    this.valueValue = this.#initialValue
  }

  // `.disabled` (the IDL property) reflects ONLY the element's own `disabled`
  // CONTENT ATTRIBUTE, per spec — it does NOT account for an ancestor
  // `<fieldset disabled>` cascading onto it (verified directly against both jsdom
  // and a real Chromium via Playwright, not assumed; a genuinely easy mistake,
  // since MDN's own prose reads as if `.disabled` were the computed state).
  // `:disabled` (the CSS pseudo-class) DOES fold the cascade in — it is the actual
  // "is this control disabled" concept the HTML spec defines for form
  // participation and constraint validation, so that is what this guard reads.
  get #disabled() {
    return this.hasFieldTarget && this.fieldTarget.matches(":disabled")
  }
}
