import { Controller } from "@hotwired/stimulus"

/**
 * cw--sortable — drag-and-drop reordering that PATCHes the new order to the server,
 * wrapping SortableJS (https://github.com/SortableJS/Sortable).
 *
 * Targets  item (one per draggable row; must carry a real `id` attribute — see
 *          `Crosswire::Presenters::Sortable#item_attrs`)
 * Values   url (String, required — PATCH destination),
 *          group (String, optional — shared name enables cross-container drags),
 *          handle (String, optional — CSS selector restricting the drag grip),
 *          paramName (String, default "position" — see the presenter docstring for
 *          exactly what this names)
 * Events   cw--sortable:reordered — detail: { item, oldIndex, newIndex }, dispatched
 *          the instant the DOM order changes, before the PATCH is even sent
 *          cw--sortable:persisted — detail: { ids } — the PATCH succeeded
 *          cw--sortable:failed — detail: { error } — the PATCH failed; the DOM has
 *          already been reverted to its pre-reorder order by the time this fires
 *
 * SORTABLEJS IS AN OPTIONAL PEER, NOT A DEPENDENCY (see the presenter docstring for
 * why). Resolution order:
 *
 *   1. `window.Sortable` — what an importmap-rails pin of "sortablejs" (or a plain
 *      `<script src=".../Sortable.min.js">`) exposes as a UMD global. Works with
 *      zero configuration for the importmap/Sprockets/CDN majority of Rails apps.
 *   2. `SortableController.sortableLoader` — a static hook, overridable by a
 *      bundler consumer (esbuild/webpack/Vite) who npm-installed sortablejs
 *      themselves:
 *
 *        import SortableController from "crosswire/controllers/sortable_controller"
 *        import Sortable from "sortablejs"
 *        SortableController.sortableLoader = () => Sortable
 *
 *      This file deliberately never writes `import("sortablejs")` itself — a bare
 *      dynamic import of a module the CONSUMER didn't install is exactly the kind
 *      of hard dependency this component refuses to be, and worse, most bundlers
 *      try to resolve a bare specifier at BUILD time even when the import is
 *      dynamic, which would break the build for every consumer who never uses this
 *      component at all. Handing the loader to the consumer means their import (if
 *      any) lives in code their own bundler already knows how to resolve.
 *
 *   Install line: `npm install sortablejs`, or pin "sortablejs" via importmap-rails
 *   (`bin/importmap pin sortablejs`). If neither resolves, `connect()` logs one
 *   console warning naming this and no-ops the drag wiring — the keyboard
 *   move-up/move-down controls (see below) keep working regardless, because they
 *   depend on nothing but `fetch`.
 *
 * TEARDOWN (R7, docs/COMPONENT_CONTRACT.md) IS MANDATORY HERE. `disconnect()` calls
 * SortableJS's own `destroy()` and nulls the reference — Turbo's snapshot cache
 * turns a missed teardown into a per-visit leak, and this is the single most common
 * bug in Stimulus wrappers around a stateful third-party library. Because resolving
 * the loader is async, `connect()` also guards against disconnecting mid-resolve: if
 * `disconnect()` runs before the loader promise settles, the controller must not go
 * on to create (and thereby leak) a Sortable instance nobody will ever destroy.
 *
 * ACCESSIBILITY, STATED HONESTLY: native HTML5 drag-and-drop is not keyboard- or
 * screen-reader-operable, and SortableJS does not change that — there is no ARIA
 * that fixes it. `moveUp`/`moveDown` below are the REQUIRED fallback, paired with
 * `Crosswire::Presenters::Sortable#move_up_attrs`/`#move_down_attrs`. They reorder
 * the DOM exactly the way a drag would and then run through the IDENTICAL
 * persistence path (`#complete` → `#persist`) — a keyboard reorder is not a
 * second-class version of the feature, it is the same feature through a different
 * input. They work with no SortableJS present at all.
 */
export default class SortableController extends Controller {
  static targets = ["item"]
  static values = {
    url: String,
    group: String,
    handle: String,
    paramName: { type: String, default: "position" }
  }

  static sortableLoader = () => globalThis.Sortable

  #sortable = null
  #connected = false

  async connect() {
    this.#connected = true

    const Sortable = await this.constructor.sortableLoader()

    // Disconnected while the loader was resolving (a fast Turbo navigation, a
    // cache restore that immediately tears down again) — creating a Sortable
    // instance now would create it with nobody left to call destroy() on it.
    if (!this.#connected) return

    if (!Sortable) {
      console.warn(
        "cw--sortable: SortableJS was not found on window.Sortable and no " +
        "SortableController.sortableLoader was configured. Install it with " +
        "`npm install sortablejs` (and set SortableController.sortableLoader " +
        "= () => Sortable) or pin \"sortablejs\" via importmap-rails. " +
        "Drag-and-drop reordering is disabled; the keyboard move up/down " +
        "controls still work."
      )
      return
    }

    this.#sortable = Sortable.create(this.element, {
      handle: this.hasHandleValue ? this.handleValue : undefined,
      group: this.hasGroupValue ? this.groupValue : undefined,
      onStart: this.#onStart,
      onEnd: this.#onEnd
    })
  }

  disconnect() {
    this.#connected = false
    this.#sortable?.destroy()
    this.#sortable = null
  }

  moveUp(event) {
    this.#move(event, -1)
  }

  moveDown(event) {
    this.#move(event, 1)
  }

  // --- drag path -----------------------------------------------------------------------

  #previousOrder = null

  #onStart = () => {
    // Captured before SortableJS mutates the DOM, so a failed PATCH has something
    // honest to revert to.
    this.#previousOrder = this.itemTargets.map((item) => item.id)
  }

  #onEnd = (event) => {
    const { oldIndex, newIndex, item } = event
    if (oldIndex === newIndex) return // dropped back where it started

    const previousOrder = this.#previousOrder
    this.#previousOrder = null
    this.#complete(item, oldIndex, newIndex, previousOrder)
  }

  // --- keyboard path -------------------------------------------------------------------

  #move(event, delta) {
    event?.preventDefault()

    const items = this.itemTargets
    const item = items.find((candidate) => candidate.contains(event.target))
    if (!item) return

    const oldIndex = items.indexOf(item)
    const newIndex = oldIndex + delta
    if (newIndex < 0 || newIndex >= items.length) return

    const previousOrder = items.map((candidate) => candidate.id)
    const neighbor = items[newIndex]

    if (delta < 0) {
      item.parentElement.insertBefore(item, neighbor)
    } else {
      item.parentElement.insertBefore(neighbor, item)
    }

    // Moving a node in the DOM does not itself move browser focus, so without this
    // the button visually jumps away from the control the user just activated —
    // the same "don't strand the user" concern R8 names for removal, applied here
    // to repositioning instead.
    event.target.focus?.({ preventScroll: true })

    this.#complete(item, oldIndex, newIndex, previousOrder)
  }

  // --- shared: dispatch, persist, revert on failure -------------------------------------

  #complete(item, oldIndex, newIndex, previousOrder) {
    this.dispatch("reordered", { detail: { item, oldIndex, newIndex } })
    this.#persist(previousOrder)
  }

  async #persist(previousOrder) {
    const ids = this.itemTargets.map((item) => item.id)

    try {
      const body = new FormData()
      ids.forEach((id) => body.append(`${this.paramNameValue}[]`, id))

      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": this.#csrfToken,
          Accept: "text/vnd.turbo-stream.html, text/html"
        },
        body
      })

      if (!response.ok) throw new Error(`cw--sortable: PATCH ${this.urlValue} responded ${response.status}`)

      const contentType = response.headers.get("Content-Type") || ""
      if (globalThis.Turbo && contentType.includes("turbo-stream")) {
        globalThis.Turbo.renderStreamMessage(await response.text())
      }

      this.dispatch("persisted", { detail: { ids } })
    } catch (error) {
      // A reorder that silently fails to persist is worse than one that visibly
      // fails: put the DOM back the way it was so the screen matches the server.
      this.#revert(previousOrder)
      this.dispatch("failed", { detail: { error } })
    }
  }

  #revert(previousOrder) {
    if (!previousOrder) return

    const byId = new Map(this.itemTargets.map((item) => [item.id, item]))
    previousOrder.forEach((id) => {
      const item = byId.get(id)
      if (item) this.element.appendChild(item)
    })
  }

  get #csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
