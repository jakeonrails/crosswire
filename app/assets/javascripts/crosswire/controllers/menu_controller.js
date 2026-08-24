import { Controller } from "@hotwired/stimulus"

/**
 * cw--menu — move focus into a `cw--popover` panel and give it `role="menu"`
 * semantics. WAI-ARIA APG Menu Button:
 * https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/
 *
 * Targets  button, menu, item
 * Values   (none) — see "STATE LIVES IN THE BROWSER" below
 * Classes  (none)
 * Events   cw--menu:opened, cw--menu:closed,
 *          cw--menu:selected (cancelable; detail { item, value })
 *
 * See `Crosswire::Presenters::Menu` for Rule 0 (a list of navigation links is not a
 * menu) and the full "what the shipped stack already gives you" accounting. This
 * controller is deliberately small — under 90 lines — because `cw--popover` and
 * `cw--roving-focus` already supply everything else a menu needs: open/close,
 * top-layer, light-dismiss, Escape, focus-return-to-invoker and placement from the
 * former; Up/Down/Home/End, wrap and typeahead from the latter. What is left is
 * exactly six things: moving focus INTO the menu on open (`popovertarget` leaves
 * focus on the button); first-vs-last depending on which key opened it;
 * close-on-activation for the right item roles only; Tab/Shift+Tab closing the menu
 * instead of moving between items; a Space shim for `<a role=menuitem>` (Space
 * natively scrolls a link, never activates it); and R8 focus rescue when the focused
 * item is removed while open.
 *
 * STATE LIVES IN THE BROWSER, NOT A STIMULUS VALUE — the same position `cw--popover`
 * takes (see that controller's docstring), and the reason this class declares no
 * `static values` at all. The native popover's own open/closed state IS the single
 * source of truth, queried here only when needed via `matches(":popover-open")`
 * (`#isOpen` below). No `open` value means no R4a phantom-event risk, and nothing for
 * Turbo 8 morphing to clobber or to register with `usePreserve` —
 * `Crosswire::Presenters::Menu`'s class docstring has the full morph-safety
 * accounting, including why the residual "items replaced by a background render while
 * open" hazard is handled by `itemTargetDisconnected` below, not by a preserve
 * mechanism.
 *
 * VERIFIED JSDOM GAP: jsdom 25.0.1 (as pinned) implements NEITHER the Popover API at
 * all (no `showPopover`/`hidePopover`, hence every call to them below going through
 * `?.()`, exactly like `cw--popover`'s own `show()`/`hide()`/`toggle()`) NOR the
 * `:popover-open` pseudo-class — `nwsapi` throws a `SyntaxError` on it, the identical
 * shape to the `:modal` gotcha `cw--dialog` works around in its own `#isModal`.
 * `#isOpen()` below treats that throw as "not open," the same safe-failure direction
 * `#isModal` takes. jsdom-tier tests stub `matches` the same way
 * `dialog_controller.test.js` stubs `:modal`; real `:popover-open` behaviour is only
 * ever asserted in the browser tier.
 *
 * COMPOSITION: `cw--menu` moves DOM focus among `item` targets ITSELF — the exact same
 * elements `cw--roving-focus` also targets on the panel (the "double-target" trick
 * `cw--tabs` already uses for `tab`/`item`) — rather than calling a method on the
 * roving-focus controller instance (R5a bans that outright) or inventing a
 * command-shaped event for it. This is mechanism (B) of two considered; see
 * `Crosswire::Presenters::Menu`'s class docstring for why a command event (A) was
 * considered and rejected. It works because `cw--roving-focus` reads "current
 * position" from `document.activeElement` FIRST (see that controller's own
 * `#currentIndex`), falling back to whichever item currently holds `tabindex="0"`
 * only when focus is elsewhere entirely — so a plain `.focus()` call here is picked up
 * automatically on the very next arrow key, with zero new API surface. The documented
 * residue: after an ArrowUp-open (focus moved straight to the LAST item),
 * `tabindex="0"` can briefly sit on a different item than the one actually
 * focused — until the next arrow key recalculates it. Unobservable in practice (Tab
 * closes the menu immediately, per `tabOut` below; screen readers do not announce
 * `tabindex`) — browser test 15 pins it as a deliberate contract, not a bug.
 * `cw--menu` never writes a `tabindex` attribute anywhere, on any item, ever.
 */
export default class MenuController extends Controller {
  static targets = ["button", "menu", "item"]

  #pendingFocus = "first"

  // --- opening, from the button ------------------------------------------------------
  // Both intercept the opening keydown BEFORE the popover opens, so `toggled()` below
  // knows which end of the list to focus once it actually does. `openFirst`/`openLast`
  // are the only reason ArrowDown/ArrowUp on the closed button need Stimulus wiring at
  // all — a plain click or Enter/Space opens through nothing but native
  // `popovertarget`, landing in `toggled()` with `#pendingFocus` left at its "first"
  // default.

  openFirst(event) {
    event.preventDefault()
    this.#pendingFocus = "first"
    this.menuTarget.showPopover?.()
  }

  openLast(event) {
    event.preventDefault()
    this.#pendingFocus = "last"
    this.menuTarget.showPopover?.()
  }

  // Native `toggle` (ToggleEvent) — `cw--popover`'s own `panel_attrs` wires this same
  // event to ITS `toggled`; this is our own reaction to the identical, already-firing
  // native event (R5a case 1: a real DOM event already backs the moment, so both
  // controllers simply bind to it — no plumbing between them needed).
  toggled(event) {
    if (event.newState === "open") {
      this.#focusItem(this.#pendingFocus)
      this.#pendingFocus = "first"
      this.dispatch("opened")
      return
    }

    this.dispatch("closed")

    // Defensive backstop, not the primary mechanism: the browser's own popover focus
    // fix-up (the HTML spec's hide-popover-stack-item algorithm) is what actually
    // returns focus to the invoking button, in every engine this was verified
    // against — but the outcome (never <body>) is what matters, not which of the two
    // paths produced it, so this covers the case where it doesn't.
    if (document.activeElement === document.body) {
      this.buttonTarget.focus()
    }
  }

  // click->select, wired on every item.
  select(event) {
    const value = event.params?.value ?? event.currentTarget.getAttribute("data-cw--menu-value-param")
    const item = event.currentTarget
    const role = item.getAttribute("role")

    const selected = this.dispatch("selected", { cancelable: true, detail: { item, value } })
    if (selected.defaultPrevented) return

    // menuitemcheckbox/menuitemradio toggle their own aria-checked in place (a
    // consumer's own click handler owns that — this controller only decides whether to
    // close) and stay open; only a plain menuitem closes the menu on activation.
    if (role === "menuitemcheckbox" || role === "menuitemradio") return

    // NEVER preventDefault anywhere in this method — the native click this action is
    // bound to must proceed unhindered: a link navigates, a `button_to` form submits.
    // This only ever closes the popover alongside that activation, never instead of it.
    this.menuTarget.hidePopover?.()
  }

  // keydown.space->activate, wired on every item. Space naturally activates a
  // `<button>` on its own (native keyup->click default) but only SCROLLS an
  // `<a href>` — this exists purely to shim that one case, and must not double-fire
  // the button case by also clicking it.
  activate(event) {
    const target = event.currentTarget
    if (target.tagName === "BUTTON" || target.tagName === "INPUT") return

    event.preventDefault()
    target.click()
  }

  // keydown.tab / keydown.shift+tab (both wired — R8a: a bare `keydown.tab` filter is
  // exact-match on modifiers and silently drops Shift+Tab). Deliberately NOT calling
  // preventDefault(): closing the popover first, then letting the browser's own Tab
  // traversal run its native default from wherever focus now sits, is what lands Tab on
  // the element AFTER the button (Shift+Tab, before it) — exactly APG's required
  // outcome — because the popover's own focus fix-up returns focus to the button as
  // part of `hidePopover()`, and only THEN does the browser's native Tab default run
  // against that new focus position. Reordering this (preventDefault + hidePopover +
  // manually focusing "whatever is next") would mean reimplementing the browser's own
  // tab-order algorithm by hand. Load-bearing: do not add preventDefault() here.
  tabOut() {
    this.menuTarget.hidePopover?.()
  }

  // Public — for programmatic close from outside (mirrors `cw--popover`'s own
  // show/hide/toggle public API; R5a mechanism 2 if another controller ever needs it).
  close() {
    this.menuTarget.hidePopover?.()
  }

  // R8 — guard focus before a background render (a Turbo Frame or stream replacing
  // items while the menu is open) detaches the very item the user is on. Never lets
  // focus fall through to <body>.
  //
  // Stimulus's target-disconnected callbacks fire from a MutationObserver, strictly
  // AFTER the node is already out of the document — and per the HTML spec, removing
  // the currently-focused element moves focus to <body> synchronously, as part of the
  // removal itself, before this callback ever runs. So `item` can never still equal
  // (or contain) `document.activeElement` by the time we get here — there is no
  // "before disconnect" hook to compare against instead. The reliable signal is the
  // OUTCOME, not the departed node: while the menu is open, focus is always supposed
  // to be somewhere inside it (an item, from `toggled()`/roving-focus); if it is
  // <body> right now, the item that just disconnected is the only thing that could
  // have taken it there.
  itemTargetDisconnected(item) {
    if (!this.#isOpen()) return
    if (document.activeElement !== document.body) return

    const survivor = this.itemTargets.find((el) => el !== item)
    if (survivor) {
      survivor.focus()
    } else {
      this.buttonTarget.focus()
    }
  }

  // R7/R8 — this controller holds no timers, listeners or observers of its own beyond
  // Stimulus's own action bindings (which Stimulus tears down automatically), so the
  // only work here is not stranding focus on a node about to be detached, and making
  // sure a controller mid-teardown doesn't leave the top layer occupied by a panel
  // nothing is listening to `toggle` on any more.
  disconnect() {
    if (this.element.contains(document.activeElement)) {
      document.activeElement.blur?.()
    }

    if (this.#isOpen()) {
      this.menuTarget.hidePopover?.()
    }

    this.#pendingFocus = "first"
  }

  // --- private -------------------------------------------------------------------

  #focusItem(position) {
    const items = this.itemTargets
    if (items.length === 0) return

    const item = position === "last" ? items[items.length - 1] : items[0]
    item.focus()
  }

  // See the class docstring's "VERIFIED JSDOM GAP" paragraph: nwsapi throws on
  // `:popover-open`, the same shape as `cw--dialog`'s `:modal` gotcha, and the safe
  // failure direction is "not open."
  #isOpen() {
    try {
      return this.menuTarget.matches(":popover-open")
    } catch {
      return false
    }
  }
}
