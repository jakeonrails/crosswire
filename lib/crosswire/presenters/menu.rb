# frozen_string_literal: true

require "crosswire/presenter"
require "crosswire/presenters/popover"
require "crosswire/presenters/roving_focus"

module Crosswire
  module Presenters
    # WAI-ARIA APG: Menu Button (actions menu)
    # https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/
    #
    # RULE 0, read this first: a list of navigation links is not a menu. If the items
    # are links to other pages, build the dropdown from `cw.popover` with plain `<a>`
    # elements and **no** `role="menu"` — the native Popover API supplies open/close,
    # `aria-expanded`, Escape, light dismiss, focus return and top-layer stacking with
    # zero JavaScript, and APG's own Disclosure Navigation example says the `menu` role
    # is wrong for a link list because it does not provide the complex functionality
    # assistive technology expects from that role. Adopting `role="menu"` obligates you
    # to remove every item from the Tab sequence, implement Up/Down/Home/End/typeahead,
    # move focus into the menu on open, close on activation, and return focus — no ARIA
    # is better than bad ARIA. Reach for this presenter only for a list of **commands**
    # (Duplicate, Archive, Delete), where all of that ships for you. If you cannot take
    # the Popover API dependency, `<details>`/`<summary>` is still a reasonable
    # link-list dropdown — you lose top layer, light dismiss, Escape and focus return.
    #
    # WHAT THE SHIPPED STACK ALREADY GIVES (verified against source, not assumed):
    # open/close, top-layer, light-dismiss, Escape-to-close and focus-return-to-invoker
    # all come from native `popover="auto"` + `popovertarget`
    # (`Crosswire::Presenters::Popover#trigger_attrs`/`#panel_attrs`); `aria-expanded`
    # on the button is reflected by the UA itself via the `popovertarget` invoker
    # mapping — an explicit decided position in that presenter's own docstring, so THIS
    # presenter deliberately never emits `aria-expanded` either; placement, with a JS
    # fallback where CSS anchor positioning is absent, comes from `cw--popover`;
    # Up/Down/Home/End, wrap, and single/multi-character typeahead with 500ms buffering
    # all come from `cw--roving-focus`. What no part of that stack can express — the
    # entire reason this thin controller exists, at under 90 lines — is: moving focus
    # INTO the menu on open (`popovertarget` leaves focus on the button; APG requires a
    # menu item get it); first-vs-last depending on which key opened it; closing on
    # activation for the right item roles only; Tab/Shift+Tab closing the menu rather
    # than tabbing between items; the `role="menu"`/`"menuitem"`/`aria-haspopup="menu"`
    # semantics (nothing in the composed stack emits these); and R8 focus rescue when
    # the focused item is removed while open. `dismiss` and `click-outside` are
    # deliberately DROPPED from this composition, unlike the catalog's original sketch —
    # `popover="auto"` already supplies Escape and light-dismiss natively
    # (`cw--click-outside`'s own docstring says so verbatim), so reaching for either
    # here would just be a second, JS-driven copy of what the platform already does.
    #
    # COMPOSES WITH cw--popover and cw--roving-focus by STACKING all three controllers
    # across two elements, split by R5b (docs/COMPONENT_CONTRACT.md): `cw--menu` sits
    # on the WRAPPER (`root_attrs`) because its `button` target is a sibling of the
    # popover panel, not a descendant of it — `popovertarget`/`popover` links trigger
    # and panel purely by id, with no shared-ancestor requirement, so nothing about this
    # composition forces one onto the other. `cw--popover` and `cw--roving-focus` both
    # sit on the PANEL (`menu_attrs`, resulting in
    # `data-controller="cw--popover cw--roving-focus"` there) because that is where
    # both controllers' own targets/state actually live: roving-focus's `item` targets
    # are descendants of the panel, and popover's native `toggle` event fires on the
    # popover element itself. `cw--menu` is conspicuously ABSENT from that
    # `data-controller` list — it needs no state of its own on the panel, only actions
    # wired there (see `menu_attrs`'s `action()` calls) plus a `button` target that
    # lives outside the panel entirely.
    #
    # MENU COMMANDS ROVING-FOCUS BY MOVING DOM FOCUS ITSELF — mechanism (B) of two
    # considered — never by calling a method on the roving-focus controller instance or
    # inventing a command-shaped event for it. R5a bans cross-controller method calls
    # outright, which rules out
    # `application.getControllerForElementAndIdentifier(...).moveTo(...)`. The other
    # candidate, (A) — a command event (`cw--menu:focus-first`) that `cw--roving-focus`
    # would have to listen for — was considered and rejected: `cw--roving-focus` reads
    # "current position" from `document.activeElement` FIRST, falling back to whichever
    # item currently holds `tabindex="0"` only when focus is elsewhere entirely (see
    # that controller's own docstring on `#currentIndex`) — so a controller that simply
    # calls `.focus()` on one of ITS OWN `item` targets (the same elements roving-focus
    # targets, the "double-target" trick `cw--tabs` already uses for `tab`/`item`) is
    # picked up automatically on the very next arrow key, with zero new API surface and
    # no event whose name would violate the `cw--<name>:<past-participle>` convention (a
    # command is not a past participle). (A) would also need a brand-new event contract
    # nothing else in this package has, for a single call site — not a good trade
    # against (B)'s "reuse the contract that already works." The one documented cost:
    # after opening via ArrowUp (which asks `cw--menu` to focus the LAST item directly),
    # `tabindex="0"` can briefly sit on a DIFFERENT item than the one actually
    # focused — the roving stop `cw--roving-focus` assigned at connect time (ordinarily
    # the first item) — until the next arrow key recalculates it. This is unobservable
    # in practice: Tab immediately closes the menu (see the controller's `tabOut`)
    # rather than ever reaching that stale stop, screen readers do not announce
    # `tabindex` at all, and the very next move renormalizes it. Browser test 15 pins
    # this contract so it stays a documented, deliberate residue rather than silently
    # regressing. `cw--menu` NEVER writes a `tabindex` attribute anywhere, on any item,
    # ever — moving DOM focus with `.focus()` is not the same act as writing
    # `tabindex`, and the split stays exactly as clean as `cw--tabs`'s own split with
    # `cw--roving-focus`.
    #
    # MORPH SAFETY, DAY ONE: this presenter renders NO Stimulus values at all — neither
    # `root_attrs` nor `menu_attrs` calls `values(...)` anywhere — so there is nothing
    # here for Turbo 8 morphing to clobber and nothing to register with `usePreserve`.
    # That is a finding, not an omission: whether the menu is open lives entirely in the
    # browser's own top-layer "popover visibility state," exposed only through the
    # `:popover-open` pseudo-class, never through an attribute morph could see or
    # touch — the same reasoning `cw--popover` itself documents. The one residual hazard
    # morph introduces is a background stream replacing `item` elements while the menu
    # is open; that is handled by the controller's `itemTargetDisconnected` (R8) plus
    # `cw--roving-focus`'s own stop-handoff on the same event, not by a preserve
    # mechanism. Browser test 18 pins "an open menu survives `Turbo.morphElements()`
    # over its wrapper, still open, with focus unmoved."
    class Menu < Presenter
      attr_reader :id, :label, :labelled_by, :placement, :offset, :strategy

      # @param id [String] the panel's id; the trigger button derives
      #   `"#{id}-trigger"` from it — delegated entirely to the internal `Popover`
      #   instance's own `trigger_id`, so there is exactly one id scheme, never a
      #   second one invented here.
      # @param label [String, nil] `aria-label` for the menu. Omit to let the menu be
      #   labelled by its own trigger button instead (the default — see `labelled_by`).
      # @param labelled_by [String, nil] id of the element that labels the menu;
      #   overrides the trigger-button default. Labelling is not optional — every menu
      #   gets an accessible name one way or the other.
      # @param placement [String] passed straight through to the internal `Popover`.
      # @param offset [Numeric] passed straight through to the internal `Popover`.
      # @param strategy [String] passed straight through to the internal `Popover`.
      # @param overrides [Hash] merged into the root element, last
      def initialize(id:, label: nil, labelled_by: nil, placement: "bottom-start",
                      offset: 8, strategy: "anchor", **overrides)
        @id = id
        @label = label
        @labelled_by = labelled_by
        @placement = placement
        @offset = offset
        @strategy = strategy
        super(**overrides)
      end

      def menu_id = id
      def button_id = popover.trigger_id

      # The wrapper — carries `cw--menu` alone. See the class docstring's composition
      # map for why `cw--popover`/`cw--roving-focus` do NOT also live here, and for why
      # nothing here calls `values(...)` (0.7: menu holds no Stimulus values at all).
      def root_attrs(**extra)
        merge(
          controller_attrs,
          overrides,
          extra
        )
      end

      def button_attrs(**extra)
        merge(
          popover.trigger_attrs,
          target(:button),
          action("keydown.down->openFirst", "keydown.up->openLast"),
          { "aria-haspopup" => "menu" },
          extra
        )
      end

      # `aria-expanded` is deliberately NOT emitted anywhere in this method — see the
      # class docstring: the UA reflects it onto the trigger via the `popovertarget`
      # invoker mapping, and a second, JS-maintained copy here could only desync from
      # it.
      def menu_attrs(**extra)
        merge(
          popover.panel_attrs,
          roving_focus.state_attrs,
          roving_focus.action_attrs,
          target(:menu),
          # BOTH tab descriptors — R8a: a bare `keydown.tab` filter is exact-match on
          # modifiers and silently drops Shift+Tab.
          action("toggle->toggled", "keydown.tab->tabOut", "keydown.shift+tab->tabOut"),
          {
            "role" => "menu",
            "aria-label" => label,
            "aria-labelledby" => labelled_by || button_id
          },
          extra
        )
      end

      # @param current [Boolean] whether this item is the roving-focus stop rendered
      #   server-side. Unlike `cw--tabs`' selected tab, the menu has no concept of a
      #   "current" item of its own — `cw--roving-focus` assigns the first item the
      #   stop itself at connect time (see the class docstring's mechanism-(B) note) —
      #   so the shipped partial never passes this; it exists so a caller composing by
      #   hand can still mark one item current if their own use case calls for it.
      # @param role [String] "menuitem" (default), "menuitemcheckbox", or
      #   "menuitemradio" — see docs/DECISIONS.md-equivalent 0.9: close-on-activation
      #   is derived from this role by the controller, with no extra API.
      # @param checked [Boolean, nil] required (raises otherwise) when `role` is
      #   "menuitemcheckbox"/"menuitemradio"; ignored for a plain "menuitem"
      # @param value [String, nil] read back by the controller's `select` action and
      #   included in the `cw--menu:selected` event detail
      # @param extra [Hash] merged into this item's attributes, last
      # @raise [ArgumentError] if role is a checkbox/radio role and `checked:` is nil
      #   (house precedent: `Crosswire::Presenters::Preserve`, `cw.stream_from`)
      def item_attrs(current: false, role: "menuitem", checked: nil, value: nil, **extra)
        if %w[menuitemcheckbox menuitemradio].include?(role) && checked.nil?
          raise ArgumentError,
                "Crosswire::Presenters::Menu#item_attrs requires checked: true or " \
                "false when role: #{role.inspect} — a plain \"menuitem\" needs neither"
        end

        merge(
          roving_focus.item_attrs(current: current),
          target(:item),
          action("click->select", "keydown.space->activate"),
          {
            "role" => role,
            "aria-checked" => checked&.to_s,
            "data-cw--menu-value-param" => value
          },
          extra
        )
      end

      private

      # A fresh, stateless `Popover` per call — cheap, and keeps this presenter from
      # duplicating popover's own attribute logic. Mirrors `Crosswire::Presenters::Tabs`'
      # identical `roving_focus` private helper below.
      def popover
        Presenters::Popover.new(id: id, placement: placement, offset: offset, strategy: strategy)
      end

      # Vertical, wrapping, with typeahead — the composite-widget defaults APG expects
      # of a menu (as opposed to `cw--tabs`' fixed horizontal, no-typeahead defaults).
      def roving_focus
        Presenters::RovingFocus.new(orientation: "vertical", wrap: true, typeahead: true)
      end
    end
  end
end
