# frozen_string_literal: true

require "crosswire/ui/component"
require "crosswire/ui/variants"

module Crosswire
  module UI
    # RULE 0: a badge is inert text with a background color — if it needs to react
    # to anything (dismiss, count up, poll a status), that behaviour is a SEPARATE
    # primitive composed onto it (`cw.dismiss_attrs`, `cw.timeout_attrs`, …), never a
    # reason to give the badge itself a controller. This presenter ships none.
    #
    # The smallest UI-tier component on purpose (ui-tier-spec.md §5's build order
    # puts it second, right after button, specifically to shake out gaps in
    # `Crosswire::UI::Variants` with the least other machinery in the way — one
    # `variant` declaration with SIX values and one `boolean`, nothing else). No
    # `tag_name` choice, no state attributes, no a11y guarantee beyond "it's text" —
    # if `Variants` has a rough edge, a component this minimal is where it surfaces
    # first, not where a real bug hides behind other complexity.
    #
    #   Crosswire::UI::Badge.new(variant: :success, dot: true).attrs
    #   # => {"class" => "cw-badge cw-badge--success cw-badge--dot"}
    #
    # Morph: Safe
    #   A badge carries no DOM-only state — its class list is a pure function of the
    #   presenter's constructor arguments, so any morph re-renders it identically.
    class Badge < Component
      extend Variants

      base "cw-badge"
      variant :variant, {
        neutral: nil,
        accent: "cw-badge--accent",
        danger: "cw-badge--danger",
        success: "cw-badge--success",
        warning: "cw-badge--warning",
        info: "cw-badge--info"
      }, default: :neutral
      # A leading status dot, drawn entirely in CSS (`.cw-badge--dot::before`) — no
      # extra markup or slot needed, matching "the smallest component" framing above.
      boolean :dot, "cw-badge--dot"

      attr_reader :variant, :dot

      # @param variant [Symbol] see `variant` declaration above
      # @param dot [Boolean] see `boolean` declaration above
      # @param overrides [Hash] merged into the root element, last
      def initialize(variant: :neutral, dot: false, **overrides)
        @variant = variant
        @dot = !!dot
        super(**overrides)
      end

      def attrs
        merge(
          { "class" => self.class.variant_class(variant: variant, dot: dot) },
          overrides
        )
      end
    end
  end
end
