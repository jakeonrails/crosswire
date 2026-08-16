# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Sync — mirror this element's value or state onto another element on every
    # change.
    #
    # A behaviour, not a widget — it decorates whatever element you already have
    # and ships no partial (docs/COMPONENT_CONTRACT.md). The generic primitive
    # dependent selects, character counters, range/slider readouts and dark-mode
    # toggle mirrors all compose from — see the controller docstring for exactly
    # what "target"/"attribute" mean and why the read side and write side are not
    # forced to share one property name.
    #
    # Rule 0: none applies generally — mirroring one element's state onto an
    # unrelated one is not something any single native element/attribute does.
    # (A `<output for>` covers exactly one narrow case — a calculation tied to
    # specific `<input>` ids — and does nothing for the character-counter,
    # cascading-select or toggle-mirror cases this primitive also serves.)
    #
    # Deliberately narrow: resist adding feature-specific options here. A use case
    # that needs more (formatting a currency value, debouncing, syncing multiple
    # targets) should compose around this controller rather than grow it — see the
    # `sync` entry in docs/COMPONENT_CONTRACT.md and research/notes/08's primitive
    # vocabulary table.
    class Sync < Presenter
      attr_reader :target, :attribute, :transform

      TRANSFORMS = %w[none length uppercase lowercase].freeze

      # @param target [String] CSS selector for the element to mirror onto. A
      #   plain value rather than a Stimulus target, because the target is almost
      #   never a descendant of this element (a character counter's `<span>` sits
      #   next to the `<textarea>`, not inside it) — see the controller docstring.
      # @param attribute [String] property/attribute name written on the target
      #   element (default "value"). Set as a DOM property when the target has one
      #   by that name, via `setAttribute` otherwise.
      # @param transform [String] "none" (default), "length", "uppercase", or
      #   "lowercase" — applied to the value read from this element before it is
      #   written to the target.
      # @param overrides [Hash] merged into the root element, last
      def initialize(target:, attribute: "value", transform: "none", **overrides)
        @target = target
        @attribute = attribute
        @transform = transform
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(target: target, attribute: attribute, transform: transform),
          # `input` covers live typing; `change` covers discrete controls
          # (checkboxes, selects, range inputs whose `input` events some older
          # embedded/native contexts drop) — both call the same #sync.
          action("input->sync", "change->sync"),
          overrides
        )
      end
    end
  end
end
