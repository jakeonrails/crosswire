# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Activate — treat an arbitrary event as a click on some element.
    #
    # Its entire purpose is keeping OBSERVERS pure. `intersection` reports
    # visibility and knows nothing about navigation; `hotkey` reports a keypress
    # and knows nothing about what it should do; neither should grow an opinion
    # about "and then click this link" just to serve the one feature that needs
    # it. `activate` is that opinion, factored out into one small, generic
    # controller any observer can compose with over `data-action` — never an
    # outlet (R5).
    #
    # Composition, worked through: infinite scroll is `intersection` (dispatches
    # `entered` when a sentinel scrolls into view) + `activate` (turns that into
    # a real click on the real "load more" link) + a lazy `<turbo-frame>` (does
    # the actual loading, because that part needs no JavaScript of ours at all).
    # NOT a bespoke infinite-scroll controller — see `intersection`'s own
    # docstring for the same composition from the sentinel's side.
    #
    #   <div data-controller="cw--intersection cw--activate"
    #        data-cw--activate-target-value="#load_more"
    #        data-action="cw--intersection:entered->cw--activate#activate">
    #     <%= link_to "Load more", next_page_path, id: "load_more", data: { turbo_stream: true } %>
    #   </div>
    #
    # A behaviour, not a widget — it decorates whatever element(s) it is placed
    # near and ships no partial.
    class Activate < Presenter
      attr_reader :target, :on_connect

      # @param target [String, nil] CSS selector for the element to click.
      #   `nil` (the default) clicks the controller's own element — the
      #   common case when `activate` is stacked directly onto the element
      #   that should be treated as clicked. A plain value rather than a
      #   Stimulus target: like `sync`'s `target:`, the referenced element is
      #   not always reachable the way a genuine Stimulus target is — here
      #   it is typically a DESCENDANT (a sentinel div wrapping the real
      #   "load more" link, per the composition below), the opposite
      #   relationship from `dismiss`'s ancestor-seeking `selector:`. See the
      #   controller docstring for the exact lookup order.
      # @param on_connect [Boolean] also activate once, immediately on
      #   connect — for "load the first page automatically" style triggers.
      #   Default false.
      # @param overrides [Hash] merged into the root element, last
      def initialize(target: nil, on_connect: false, **overrides)
        @target = target
        @on_connect = !!on_connect
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(target: target, on_connect: on_connect),
          overrides
        )
      end
    end
  end
end
