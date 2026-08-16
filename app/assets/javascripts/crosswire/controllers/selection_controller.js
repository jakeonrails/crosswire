import { Controller } from "@hotwired/stimulus"

/**
 * cw--selection — a checkbox group with select-all, indeterminate state, a live
 * count, and toolbar enable/disable.
 *
 * Targets  all (the select-all checkbox), item (one per row), count (an output,
 *          announced live), action (toolbar controls to enable/disable)
 * Values   none
 * Events   cw--selection:changed — detail: { selected, total }. Dispatched only for
 *          a genuine user-driven change (toggling `all` or an `item`), never for the
 *          silent resync that runs on connect or when a target merely
 *          connects/disconnects — see the `#sync` / `#announce` split below.
 *
 * THE DETAIL EVERYONE GETS WRONG: `indeterminate` is a DOM PROPERTY, not an HTML
 * attribute. `<input indeterminate>` does nothing, it is not reflected by
 * `getAttribute`, and — because it is never serialised into markup — it does NOT
 * survive a Turbo morph or a bfcache restore. There is no server-rendered fallback
 * to lean on the way `open` or `selected` values can elsewhere in this library.
 * `#sync` below re-derives it from the actual checked state of every `item`, and
 * runs on `connect()` and after every change — recomputing from scratch each time
 * rather than trying to track it incrementally, which is what makes it correct
 * regardless of how the DOM got into its current shape.
 *
 * TURBO STREAM ROWS: `itemTargetConnected`/`itemTargetDisconnected` (and the `all`
 * equivalents) call `#sync` so a stream appending or removing rows keeps the count,
 * the select-all checkbox and the toolbar correct with no re-init required — the
 * same idiom `cw--roving-focus` uses to keep its own tabindex bookkeeping correct
 * across content churn. This firing on mere connection (not just on `change`) is
 * deliberate: a newly-appended, unchecked row must immediately turn a fully-checked
 * "all selected" state into `indeterminate`, without waiting for the user to
 * interact with anything.
 */
export default class SelectionController extends Controller {
  static targets = ["all", "item", "count", "action"]

  connect() {
    this.#sync()
  }

  allTargetConnected() {
    this.#sync()
  }

  allTargetDisconnected() {
    this.#sync()
  }

  itemTargetConnected() {
    this.#sync()
  }

  itemTargetDisconnected() {
    this.#sync()
  }

  toggleAll(event) {
    const checked = event.target.checked
    this.itemTargets.forEach((item) => {
      item.checked = checked
    })
    this.#sync()
    this.#announce()
  }

  refresh() {
    this.#sync()
    this.#announce()
  }

  // --- state -------------------------------------------------------------------------
  // Split in two on purpose (R4a's spirit, applied to a target-driven controller
  // rather than a value-driven one): `#sync` alone runs for every DOM-shape change,
  // including ones nobody "did" (a stream appending a row, the initial connect), and
  // never dispatches. Only a genuine user action calls `#announce` afterwards. A
  // consumer wiring `cw--selection:changed` to, say, a network request would
  // otherwise fire on every page load and every streamed row for free.

  #sync() {
    const items = this.itemTargets
    const total = items.length
    const selected = items.filter((item) => item.checked).length

    if (this.hasAllTarget) {
      this.allTarget.checked = total > 0 && selected === total
      this.allTarget.indeterminate = selected > 0 && selected < total
    }

    if (this.hasCountTarget) {
      this.countTarget.textContent = selected === 0 ? "" : `${selected} selected`
    }

    this.actionTargets.forEach((action) => {
      action.disabled = selected === 0
      action.setAttribute("aria-disabled", selected === 0 ? "true" : "false")
    })
  }

  #announce() {
    const total = this.itemTargets.length
    const selected = this.itemTargets.filter((item) => item.checked).length

    this.dispatch("changed", { detail: { selected, total } })
  }
}
