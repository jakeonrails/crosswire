import { Controller } from "@hotwired/stimulus"

/**
 * cw--tabs — wire tablist/tab/tabpanel roles with roving focus and optional URL
 * sync.
 *
 * WAI-ARIA APG: https://www.w3.org/WAI/ARIA/apg/patterns/tabs/
 *
 * Targets  tab, panel
 * Values   selected (String), activation (String: "automatic" default | "manual"),
 *          param (String, optional)
 * Events   cw--tabs:changed (detail.selected)
 *
 * COMPOSES WITH cw--roving-focus — stacked on a shared ROOT element that wraps
 * both the tablist and every panel (`data-controller="cw--roving-focus cw--tabs"`,
 * see `Crosswire::Presenters::Tabs#root_attrs` for why it has to be the root and
 * not just the tablist: Stimulus scopes `tabTargets`/`panelTargets` to
 * descendants of whichever element carries `data-controller="cw--tabs"`, and
 * panels are siblings of the tablist, not descendants of it) rather than
 * reimplementing arrow-key navigation (R5a). The `keydown` action that drives
 * roving-focus itself stays scoped to the tablist specifically (not the wider
 * root), so arrow keys pressed inside a panel's own form fields are never
 * mistaken for tab navigation. Every `tab` target is ALSO a roving-focus `item`
 * target, so
 * `cw--roving-focus` owns Left/Right/Home/End movement and the roving
 * `tabindex="0"`/`"-1"` bookkeeping across them completely — THIS controller never
 * writes `tabindex` on a tab, only `aria-selected`. Splitting the two attributes
 * this way is deliberate: in "manual" activation, focus (tabindex) and selection
 * (aria-selected) are allowed to diverge — the user can arrow to a tab without
 * selecting it — and having two controllers both try to own `tabindex` would fight
 * over exactly that case.
 *
 * The two controllers talk to each other exactly per R5a's three cases:
 *
 *   1. A real click or Enter/Space on a tab needs no cross-controller plumbing at
 *      all — `select` is bound directly to that DOM event by the presenter.
 *   2. Nothing here calls INTO roving-focus programmatically — there's nothing to
 *      ask it to do.
 *   3. REACTING to roving-focus's state: this controller listens for its
 *      `cw--roving-focus:moved` event (wired via the presenter's `action()`
 *      pass-through in `tablist_attrs`) to implement "automatic" activation. In
 *      "manual" mode `selectFromMove` is a no-op — roving-focus has already moved
 *      DOM focus and its own tabindex by the time this fires, and nothing further
 *      happens until an explicit `select`.
 *
 * `selectedValueChanged` is guarded with a `#ready` flag rather than
 * `previous === undefined`, per R4a: Stimulus runs value-changed callbacks before
 * `connect()`, and for a typed (String) value the initial `previous` is `""`, not
 * `undefined` — an `undefined` guard would silently never fire, and every connect
 * would announce a phantom `changed` event and rewrite the URL on first paint.
 */
export default class TabsController extends Controller {
  static targets = ["tab", "panel"]
  static values = {
    selected: String,
    activation: { type: String, default: "automatic" },
    param: String
  }

  #ready = false

  connect() {
    this.#render()
    this.#ready = true
  }

  disconnect() {
    this.#ready = false
  }

  // cw--roving-focus:moved -> selectFromMove. `detail.index` indexes roving-focus's
  // own item list, which on this element is exactly `tabTargets` in the same order
  // (every tab is the only kind of roving-focus item present here).
  selectFromMove(event) {
    if (this.activationValue !== "automatic") return

    const tab = this.tabTargets[event.detail.index]
    if (tab) this.#selectId(this.#idOf(tab))
  }

  select(event) {
    event?.preventDefault()
    const id = event?.params?.id ?? this.#idOf(event?.currentTarget)
    this.#selectId(id)
  }

  // Single write path (R4): the action handlers above only ever decide WHETHER to
  // write selectedValue; all DOM work happens here.
  selectedValueChanged(value) {
    this.#render()

    if (!this.#ready) return

    this.#syncUrl(value)
    this.dispatch("changed", { detail: { selected: value } })
  }

  #selectId(id) {
    if (id == null || id === this.selectedValue) return
    this.selectedValue = id
  }

  // Reads the presenter's `data-cw--tabs-id-param` attribute directly rather than
  // through `.dataset`, the same way `cw--confirm` reads cw--dialog's open-value
  // attribute directly: a double-dash identifier like `cw--tabs` camelCases into an
  // awkward `dataset["cw-TabsIdParam"]` key (a literal embedded hyphen), so plain
  // `getAttribute` is both simpler and more obviously correct than fighting that.
  #idOf(tab) {
    return tab?.getAttribute("data-cw--tabs-id-param") ?? tab?.id ?? null
  }

  #render() {
    const selected = this.selectedValue

    this.tabTargets.forEach((tab) => {
      tab.setAttribute("aria-selected", String(this.#idOf(tab) === selected))
    })

    this.panelTargets.forEach((panel) => {
      panel.hidden = !this.#panelMatchesSelection(panel, selected)
    })
  }

  // A panel's own id encodes its tab id (see the presenter), but reading it back
  // off `aria-labelledby` instead of parsing either id string keeps this working
  // regardless of the presenter's exact id scheme — the ARIA relationship IS the
  // source of truth for which tab owns which panel.
  #panelMatchesSelection(panel, selected) {
    const labelledBy = panel.getAttribute("aria-labelledby")
    if (!labelledBy) return false

    const tab = this.tabTargets.find((t) => t.id === labelledBy)
    return tab ? this.#idOf(tab) === selected : false
  }

  #syncUrl(selected) {
    if (!this.hasParamValue || this.paramValue === "") return
    if (typeof window === "undefined" || !window.history?.replaceState) return

    const url = new URL(window.location.href)
    url.searchParams.set(this.paramValue, selected)

    // Deliberately `history.replaceState`, NOT Turbo Frame history
    // (`data-turbo-action="advance"` on a `<turbo-frame>`). A Turbo maintainer has
    // said on the record he does not recommend that feature for exactly this kind
    // of URL-sync use and has no plans to fix its known bugs — frames losing track
    // of the URL on Back, nested frames not updating it at all
    // (research/notes/07-problem-mining.md Q27/turbo#600, P4/turbo#1241). A
    // client-only tabs widget has no frame to advance in the first place:
    // `replaceState` is the plain, boring, maintainer-endorsed tool for keeping the
    // address bar in sync with state that already lives entirely on the client.
    window.history.replaceState(window.history.state, "", url)
  }
}
