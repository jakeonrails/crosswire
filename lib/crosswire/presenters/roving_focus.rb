# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # WAI-ARIA APG: Keyboard Interface Practices — roving tabindex
    # https://www.w3.org/WAI/ARIA/apg/practices/keyboard-interface/
    #
    # Move focus across a set of `item` targets with arrow keys using the roving
    # tabindex model: exactly one item has `tabindex="0"` at any time, every other
    # item has `tabindex="-1"`, so Tab moves in and out of the whole group in a
    # single stop instead of visiting every item, and arrow keys move both DOM focus
    # and which item holds the `0`.
    #
    # A behaviour, not a widget — it decorates whatever `item` targets you place
    # inside it and ships no partial and no markup opinions of its own
    # (docs/COMPONENT_CONTRACT.md). `tabs` composes on top of this by STACKING
    # controllers on the tablist element (R5a) rather than reimplementing arrow-key
    # navigation — see `Crosswire::Presenters::Tabs#tablist_attrs` for the stacking
    # recipe, and its controller docstring for the "automatic" activation half of
    # that composition.
    #
    # Rule 0: none applies. There is no native element that gives you arrow-key
    # navigation across a set of custom widgets (tabs, menu items, grid cells,
    # toolbar buttons) for free — this primitive exists because that gap is real.
    #
    # Home/End jump to the first/last item. Typeahead, when enabled, jumps to the
    # next item whose text starts with the typed character(s), buffered for ~500ms
    # per APG's own suggested composite-widget timing — a genuine APG requirement
    # for menus and listboxes that (per research/notes/03) no Stimulus library in
    # the ecosystem implements. See the controller for the exact matching algorithm.
    class RovingFocus < Presenter
      attr_reader :orientation, :wrap, :typeahead

      # @param orientation [String] "vertical" (default) listens to Up/Down,
      #   "horizontal" to Left/Right, "both" to all four arrow keys.
      # @param wrap [Boolean] wrap from the last item back to the first (and the
      #   first back to the last) rather than stopping at the boundary. Default
      #   true, per APG's general recommendation for composite widgets.
      # @param typeahead [Boolean] enable single/multi-character typeahead. Default
      #   false — most roving-focus consumers (tabs, toolbars) don't want it; menus
      #   and listboxes do.
      # @param overrides [Hash] merged into the root element, last
      def initialize(orientation: "vertical", wrap: true, typeahead: false, **overrides)
        @orientation = orientation
        @wrap = !!wrap
        @typeahead = !!typeahead
        super(**overrides)
      end

      def root_attrs
        merge(state_attrs, action_attrs, overrides)
      end

      # The controller declaration + values, without the `keydown` action — split
      # out for `tabs` (and any other composer): when this behaviour is STACKED
      # onto another controller's element (R5a), the `data-controller`/values need
      # to live on the shared root that contains every `item`, but the `keydown`
      # action is best scoped to a narrower descendant (see
      # `Crosswire::Presenters::Tabs#tablist_attrs`) so it does not also catch
      # keydowns from unrelated content sharing that root. `root_attrs` above is
      # just `merge(state_attrs, action_attrs)` — the composition seam this
      # primitive is built to support, not a special case bolted on afterwards.
      def state_attrs
        merge(
          controller_attrs,
          values(orientation: orientation, wrap: wrap, typeahead: typeahead)
        )
      end

      # R8a: a key filter with a modifier needs its own action descriptor, and this
      # widget potentially needs six named keys (four arrows, Home, End) plus
      # arbitrary printable characters for typeahead — enumerating that as
      # `data-action` filters would be unreadable and could not express typeahead at
      # all (Stimulus key filters only name specific keys, not "any printable
      # character"). One generic `keydown->navigate` action and a single `switch` on
      # `event.key` in the controller is both simpler and the only way to cover
      # typeahead at all.
      def action_attrs
        action("keydown->navigate")
      end

      # One `item_attrs` call per item in the group. `current: true` on exactly one
      # of them renders that item's `tabindex="0"` server-side (R4: state rendered
      # server-side) so the correct roving stop is in the tab order before
      # JavaScript loads; every other item renders `tabindex="-1"`.
      def item_attrs(current: false, **extra)
        merge(
          target(:item),
          { "tabindex" => current ? "0" : "-1" },
          extra
        )
      end
    end
  end
end
