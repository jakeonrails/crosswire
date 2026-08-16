import { Controller } from "@hotwired/stimulus"

/**
 * cw--roving-focus — move focus across `item` targets with arrow keys using roving
 * tabindex.
 *
 * WAI-ARIA APG Keyboard Interface Practices:
 * https://www.w3.org/WAI/ARIA/apg/practices/keyboard-interface/
 *
 * Targets  item (any number, in DOM order)
 * Values   orientation (String: "vertical" default | "horizontal" | "both"),
 *          wrap (Boolean, default true), typeahead (Boolean, default false)
 * Events   cw--roving-focus:moved (detail.index — index into the current item list)
 *
 * `tabs` stacks on top of this controller (`data-controller="cw--roving-focus
 * cw--tabs"`) rather than reimplementing any of it — see
 * Crosswire::Presenters::Tabs#tablist_attrs and the tabs controller docstring.
 *
 * THE MOST IMPORTANT CORRECTNESS DETAIL, same as `focus-trap`: `item` targets are
 * re-queried on every keypress via `this.itemTargets` (which Stimulus computes live
 * from the DOM, never cached) rather than snapshotted once at connect. Content
 * changes constantly under Turbo — frames render, streams append/remove items — and
 * a cached list goes stale. `itemTargetConnected`/`itemTargetDisconnected` below
 * additionally keep the roving stop itself (which single item has `tabindex="0"`)
 * correct across those changes: an item disconnecting while it holds the stop hands
 * it to a neighbour, and an item connecting into a group with no stop at all
 * (empty on first render, or every item was removed) claims it, so the group is
 * never left with zero focusable stops.
 *
 * R8a (docs/COMPONENT_CONTRACT.md): Stimulus key filters are exact-match on
 * modifiers, and this controller needs six named keys (four arrows, Home, End) plus
 * arbitrary printable characters for typeahead, which no filter can express at all.
 * So there is exactly one `keydown->navigate` action (no filter), and `navigate`
 * below does its own `switch` on `event.key`.
 *
 * "current position" is read from `document.activeElement` when it is one of the
 * items (the ordinary case, mid-navigation), falling back to whichever item
 * currently carries `tabindex="0"` (e.g. a fresh connect, or focus is currently
 * elsewhere entirely) so movement always has a sane starting point.
 *
 * Tabindex bookkeeping reads/writes the literal `tabindex` ATTRIBUTE
 * (`getAttribute`/`setAttribute`), never the `.tabIndex` DOM PROPERTY — the
 * property defaults to `0` for any natively-focusable element (a `<button>`, for
 * instance) even with no `tabindex` attribute present at all, which would make
 * "does this item currently hold tabindex 0" unreliable for exactly the elements
 * this controller is most commonly used with.
 */
export default class RovingFocusController extends Controller {
  static targets = ["item"]
  static values = {
    orientation: { type: String, default: "vertical" },
    wrap: { type: Boolean, default: true },
    typeahead: { type: Boolean, default: false }
  }

  #typeaheadBuffer = ""
  #typeaheadTimer = null

  connect() {
    this.#ensureRovingStop()
  }

  // R7 — the only resource this controller ever holds outside Stimulus's own
  // teardown is the typeahead buffer timer.
  disconnect() {
    this.#clearTypeahead()
  }

  // A fresh item connecting mid-session (Turbo frame render, stream append). If the
  // group currently has no roving stop at all (this is the very first item, or
  // every previous item was just removed), this one claims it so the group is never
  // left with zero tab stops. Otherwise it starts at -1 like any non-current item —
  // an incoming item must never steal the stop out from under whatever the user
  // currently has focused.
  itemTargetConnected(item) {
    if (!item.hasAttribute("tabindex")) {
      item.setAttribute("tabindex", this.#hasRovingStop() ? "-1" : "0")
    }
  }

  // If the departing item held the roving stop, hand it to a neighbour so the group
  // keeps exactly one tabindex="0", never zero.
  itemTargetDisconnected(item) {
    if (item.getAttribute("tabindex") !== "0") return

    const remaining = this.itemTargets.filter((el) => el !== item)
    if (remaining.length > 0) remaining[0].setAttribute("tabindex", "0")
  }

  navigate(event) {
    const key = event.key

    const delta = this.#moveDelta(key)
    if (delta !== 0) {
      event.preventDefault()
      this.#clearTypeahead()
      this.#moveBy(delta)
      return
    }

    if (key === "Home") {
      event.preventDefault()
      this.#clearTypeahead()
      this.#moveTo(0)
      return
    }

    if (key === "End") {
      event.preventDefault()
      this.#clearTypeahead()
      this.#moveTo(this.itemTargets.length - 1)
      return
    }

    if (this.typeaheadValue && this.#isPrintable(event)) {
      this.#typeaheadMove(event.key)
    }
  }

  // --- movement ----------------------------------------------------------------------

  #moveBy(delta) {
    const items = this.itemTargets
    if (items.length === 0) return

    const from = this.#currentIndex(items)
    let to = from + delta

    if (this.wrapValue) {
      to = ((to % items.length) + items.length) % items.length
    } else {
      to = Math.max(0, Math.min(items.length - 1, to))
    }

    this.#moveTo(to)
  }

  #moveTo(index) {
    const items = this.itemTargets
    if (items.length === 0) return

    const clamped = Math.max(0, Math.min(items.length - 1, index))
    const target = items[clamped]

    items.forEach((el) => el.setAttribute("tabindex", el === target ? "0" : "-1"))
    target.focus()

    this.dispatch("moved", { detail: { index: clamped } })
  }

  #currentIndex(items) {
    const active = document.activeElement
    const at = items.indexOf(active)
    if (at !== -1) return at

    const marked = items.findIndex((el) => el.getAttribute("tabindex") === "0")
    return marked === -1 ? 0 : marked
  }

  #moveDelta(key) {
    const orientation = this.orientationValue

    const vertical = orientation === "vertical" || orientation === "both"
    const horizontal = orientation === "horizontal" || orientation === "both"

    if (vertical && key === "ArrowUp") return -1
    if (vertical && key === "ArrowDown") return 1
    if (horizontal && key === "ArrowLeft") return -1
    if (horizontal && key === "ArrowRight") return 1

    return 0
  }

  // --- typeahead -----------------------------------------------------------------------
  // APG requires composite widgets like menus and listboxes to support single- and
  // multi-character typeahead: matching the item whose accessible text STARTS WITH
  // what has been typed so far (case-insensitively), cycling forward from the item
  // after the current one so repeated presses of the same letter cycle through every
  // match — the same behaviour every native <select> implements — and resetting the
  // buffer after a short pause (~500ms) so an unrelated keypress later doesn't
  // combine with stale input. This is the actual reason this primitive exists: per
  // research/notes/03, no Stimulus library in the ecosystem (stimulus-components,
  // tailwindcss-stimulus-components, stimulus-use) implements it.

  #isPrintable(event) {
    return event.key.length === 1 && !event.ctrlKey && !event.metaKey && !event.altKey
  }

  #typeaheadMove(char) {
    this.#typeaheadBuffer += char.toLowerCase()
    this.#armTypeaheadTimer()

    const items = this.itemTargets
    if (items.length === 0) return

    const from = this.#currentIndex(items)
    const order = items.map((_, i) => (from + 1 + i) % items.length)

    const match = order.find((i) => this.#itemText(items[i]).startsWith(this.#typeaheadBuffer))
    if (match !== undefined) {
      this.#moveTo(match)
      return
    }

    // No item matches the accumulated buffer. APG permits falling back to the
    // single newest character, so typing "s" then quickly "a" (no "sa..." item)
    // still finds "Settings" via "s" rather than getting stuck on a dead buffer.
    if (this.#typeaheadBuffer.length > 1) {
      const single = order.find((i) => this.#itemText(items[i]).startsWith(char.toLowerCase()))
      if (single !== undefined) {
        this.#typeaheadBuffer = char.toLowerCase()
        this.#moveTo(single)
      }
    }
  }

  #itemText(el) {
    return (el.textContent || "").trim().toLowerCase()
  }

  #armTypeaheadTimer() {
    this.#clearTypeaheadTimerOnly()
    this.#typeaheadTimer = setTimeout(() => {
      this.#typeaheadBuffer = ""
      this.#typeaheadTimer = null
    }, 500)
  }

  #clearTypeaheadTimerOnly() {
    if (this.#typeaheadTimer) {
      clearTimeout(this.#typeaheadTimer)
      this.#typeaheadTimer = null
    }
  }

  #clearTypeahead() {
    this.#typeaheadBuffer = ""
    this.#clearTypeaheadTimerOnly()
  }

  // --- setup -----------------------------------------------------------------------

  #hasRovingStop() {
    return this.itemTargets.some((el) => el.getAttribute("tabindex") === "0")
  }

  #ensureRovingStop() {
    const items = this.itemTargets
    if (items.length === 0) return
    if (this.#hasRovingStop()) return

    items[0].setAttribute("tabindex", "0")
    items.slice(1).forEach((el) => {
      if (!el.hasAttribute("tabindex")) el.setAttribute("tabindex", "-1")
    })
  }
}
