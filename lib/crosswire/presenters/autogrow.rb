# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Autogrow — size a `<textarea>` to its content.
    #
    # RULE 0 — SHIP THE CSS; THIS EXISTS ONLY FOR OLDER ENGINES. `field-sizing:
    # content` is Baseline CSS (Chrome/Edge 123+, Firefox 152+, Safari 26.2+ — all
    # three current-generation engines) and does this with ZERO JavaScript:
    #
    #   textarea {
    #     field-sizing: content;
    #     min-height: 3lh;   /* don't collapse to one line when empty */
    #     max-height: 20lh;  /* then it scrolls */
    #     resize: vertical;  /* still let the user override */
    #   }
    #
    # Reach for THIS component only when your support matrix genuinely still includes
    # engines predating those versions. It is SUNSETTING — research/notes/08 already
    # flags it that way — and should be deleted from any app once that support window
    # closes. The controller itself no-ops entirely (see its docstring) whenever
    # `CSS.supports("field-sizing", "content")` is true, so shipping both the CSS and
    # this component together is always safe: on a modern engine the CSS alone does
    # the work and the controller does nothing.
    #
    # A behaviour, not a widget — it decorates a `<textarea>` you already have and
    # ships no partial.
    class Autogrow < Presenter
      attr_reader :max_rows

      # @param max_rows [Integer, nil] caps growth at this many rows; the textarea
      #   scrolls past it instead of growing further. Optional — omit for unbounded
      #   growth.
      # @param overrides [Hash] merged into the element, last
      def initialize(max_rows: nil, **overrides)
        @max_rows = max_rows
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(max_rows: max_rows),
          overrides
        )
      end
    end
  end
end
