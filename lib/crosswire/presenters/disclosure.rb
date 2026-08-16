# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # WAI-ARIA APG: Disclosure (Show/Hide)
    # https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/
    #
    # A trigger that shows and hides a panel. The simplest useful component, and a good
    # place to read the whole crosswire pattern:
    #
    #   * the presenter owns the accessibility contract, not the markup, so an ejected
    #     or restyled partial keeps correct ARIA (docs/DECISIONS.md D6)
    #   * the controller carries no design-system opinion — colours and animation come
    #     in through the CSS Classes API
    #   * composition happens through events, never outlets: a distributable component
    #     cannot know another controller's identifier (research/notes/03)
    #
    # Before reaching for this, apply Rule 0: if you do not need to react to the state
    # change, `<details>`/`<summary>` is a better answer and needs no JavaScript at all.
    # Use this when you need `aria-expanded` on a real button, animation, persistence,
    # or an event other controllers can listen to.
    class Disclosure < Presenter
      attr_reader :id, :open

      # @param id [String] base id; the trigger and panel derive theirs from it
      # @param open [Boolean] initial state, rendered server-side so it is correct
      #   before JavaScript loads and survives a morph
      # @param open_class [String, nil] class applied to the root while open
      # @param region [Boolean] label the panel as a landmark region. APG advises this
      #   only for panels substantial enough to be worth navigating to directly.
      # @param overrides [Hash] merged into the root element, last
      def initialize(id:, open: false, open_class: nil, region: false, **overrides)
        @id = id
        @open = !!open
        @open_class = open_class
        @region = region
        super(**overrides)
      end

      def trigger_id = "#{id}-trigger"
      def panel_id   = "#{id}-panel"

      def root_attrs
        merge(
          controller_attrs,
          values(open: open),
          classes(open: @open_class),
          { "id" => id },
          overrides
        )
      end

      def trigger_attrs(**extra)
        merge(
          target(:trigger),
          action("click->toggle"),
          {
            "id" => trigger_id,
            "type" => "button",
            "aria-expanded" => open.to_s,
            "aria-controls" => panel_id
          },
          extra
        )
      end

      def panel_attrs(**extra)
        merge(
          target(:panel),
          {
            "id" => panel_id,
            "hidden" => !open
          },
          region_attrs,
          extra
        )
      end

      private

      # `role="region"` without an accessible name is useless to a screen reader, so the
      # two always travel together.
      def region_attrs
        return {} unless @region

        { "role" => "region", "aria-labelledby" => trigger_id }
      end
    end
  end
end
