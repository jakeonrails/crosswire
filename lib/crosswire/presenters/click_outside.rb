# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # ClickOutside — dispatch when a pointer event lands outside the element.
    #
    # Rule 0: prefer the platform first. `popover="auto"` gets light-dismiss on any
    # outside interaction for free, and `<dialog>`'s `closedby="any"` does the same for
    # modals (Chrome 134+/Firefox 141+, Safari behind a flag as of 2026-08 — pair it
    # with this component as a fallback there). This primitive exists for everything
    # that is not a popover or a `<dialog>`: a custom-styled menu, a non-modal panel, an
    # inline editor that should commit when focus/pointer activity leaves it.
    #
    # A behaviour, not a widget — it decorates whatever element it is placed on and
    # ships no partial (docs/COMPONENT_CONTRACT.md).
    class ClickOutside < Presenter
      attr_reader :enabled

      # @param enabled [Boolean] whether the listener is currently armed. Left off
      #   (false) while the thing it would dismiss is closed, so the very click that
      #   opens it is never misread as an outside click on itself — flipped by whatever
      #   controller owns that state (R5a #2: writing the value attribute directly).
      # @param overrides [Hash] merged into the root element, last
      def initialize(enabled: true, **overrides)
        @enabled = !!enabled
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(enabled: enabled),
          overrides
        )
      end
    end
  end
end
