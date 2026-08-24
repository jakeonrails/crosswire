# frozen_string_literal: true

require "crosswire/attributes"

module Crosswire
  module UI
    # Base class for styled UI component presenters (button, card, badge, …) —
    # deliberately NOT a subclass of Crosswire::Presenter.
    #
    # A primitive-tier presenter (lib/crosswire/presenters/*.rb) owns a Stimulus
    # identifier and exposes `controller_attrs`/`target`/`action`/`values`/`classes`/
    # `event_name` — the whole point of that class is wiring a `data-controller`
    # element. Nothing in the UI tier ships JS of its own (Rule 0: a purely
    # presentational component needs no controller at all — see
    # docs/COMPONENT_CONTRACT.md and the UI-tier spec §2/§3). Subclassing Presenter
    # here would either drag in Stimulus-shaped machinery no UI component ever calls,
    # or force every UI presenter to override it away. A separate, smaller base class
    # is the honest shape: attribute-hash computation and `Variants`, nothing else.
    #
    #   class Button < Crosswire::UI::Component
    #     extend Crosswire::UI::Variants
    #     base "cw-button"
    #     variant :variant, { primary: "cw-button--primary", secondary: nil }, default: :secondary
    #
    #     def initialize(variant: :secondary, **overrides)
    #       @variant = variant
    #       super(**overrides)
    #     end
    #
    #     def root_attrs = merge({ "class" => self.class.variant_class(variant: @variant) }, overrides)
    #   end
    class Component
      # Every UI presenter accepts arbitrary caller attributes and merges them last —
      # same contract as Crosswire::Presenter, so a consumer can always add their own
      # class or data attributes without losing ours.
      def initialize(**overrides)
        @overrides = overrides
      end

      private

      attr_reader :overrides

      def merge(*sources) = Crosswire::Attributes.merge(*sources)
    end
  end
end
