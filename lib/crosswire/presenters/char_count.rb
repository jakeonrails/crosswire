# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # CharCount — mirror an input's length into an `output` target, with max and
    # over-limit states.
    #
    # Accessibility is the entire point of this component, and the easy way to build
    # it is also the wrong way: writing the live count into an `aria-live="polite"`
    # region on every keystroke reads "two hundred seventy-nine... two hundred
    # seventy-eight..." to a screen reader user for as long as they keep typing — worse
    # than no live region at all. `output_attrs` puts `aria-live="polite"` on the
    # `output` target itself (an `<output>` element's implicit role is already
    # `status`, a polite live region, but this is set explicitly rather than relying on
    # a consumer rendering the exact right element). The CONTROLLER is what keeps that
    # region from being spammy, by debouncing its writes rather than writing on every
    # `input` event — see its docstring for the mechanism and the trade-off accepted.
    #
    # As with `clipboard`'s `status` target, the live region must already exist in the
    # DOM before the count changes — an element that gains `aria-live` at the same
    # moment it gains content is never announced, because the accessibility tree has
    # to observe the region before it can report a mutation on it. Because
    # `output_attrs` is rendered server-side as part of the page's initial markup,
    # this is satisfied automatically as long as a consumer doesn't build the output
    # element with client-side JS after the fact.
    #
    # Over-limit is conveyed three ways, deliberately: `aria-invalid="true"` on the
    # input itself (the one signal a screen reader user gets even without visiting the
    # live region), an optional CSS class, and the literal word "over" in the announced
    # text — colour alone is never an accessible signal.
    class CharCount < Presenter
      attr_reader :max, :warn_at

      # @param max [Integer] the character limit being counted down against. Required
      #   — there is no sensible default for "how many characters is too many," and a
      #   component that silently no-ops without one is worse than one that raises.
      # @param warn_at [Float] ratio of `max` (0..1) at which the warn state begins.
      #   The default 0.9 means "warn once 90% of the limit is used" (10% remaining).
      # @param over_class [String, nil] class applied to the root while over the limit
      # @param warn_class [String, nil] class applied to the root while in the warn
      #   band. Both optional and independently guarded per R3 — the controller uses
      #   `hasOverClass`/`hasWarnClass` before ever reading `overClass`/`warnClass`.
      # @param overrides [Hash] merged into the root element, last
      def initialize(max:, warn_at: 0.9, over_class: nil, warn_class: nil, **overrides)
        @max = max
        @warn_at = warn_at
        @over_class = over_class
        @warn_class = warn_class
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(max: max, warn_at: warn_at),
          classes(over: @over_class, warn: @warn_class),
          overrides
        )
      end

      def input_attrs(**extra)
        merge(target(:input), action("input->update"), extra)
      end

      # `aria-live="polite"` lives here rather than on a second, visually-hidden
      # announcer element — see the class docstring for why one region is enough as
      # long as the controller debounces its writes to it. `aria-atomic="true"` so the
      # whole message re-reads on change rather than a partial diff of it.
      def output_attrs(**extra)
        merge(
          target(:output),
          { "aria-live" => "polite", "aria-atomic" => "true" },
          extra
        )
      end
    end
  end
end
