# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Rule 0: before reaching for this, prefer Radan Skorić's "family 3" — persist the
    # state server-side (a preferences model, the session, the URL) so you morph
    # *toward* the state you want and the conflict evaporates, ideally somewhere it
    # also buys you a UX win (the state survives a reload, the URL becomes shareable).
    # Next, prefer *limiting the update's scope* instead of fighting it element-by-
    # element: a targeted `turbo_stream.replace(target, method: :morph)` — "the most
    # under-used tool in Hotwire" — only touches the subtree you actually changed, so
    # nothing outside it needs protecting in the first place. Reach for `preserve` only
    # for state the server genuinely does not know (is a menu open? which tab is
    # selected right now?) or for attributes a third-party controller writes at
    # runtime that you do not own the source of.
    #
    # `cw--preserve` — the markup-driven surface for a controller you do NOT own (a
    # third-party Stimulus controller, a web component, a JS library writing its own
    # attributes at runtime). If you own the controller, `usePreserve` from
    # `crosswire/morph` is the better fit (`static preservedValues` /
    # `static preservedAttributes` on the controller class itself, no markup wiring
    # required) — see that module's docstring.
    #
    # Modelled on, and fixing a gap in, Evil Martians' `data-turbo-morph-permanent-
    # attrs` (2025-06-24): that primitive protects unconditionally, so once applied the
    # server can never update the named attribute again for the life of the page. This
    # one only cancels a morph once the live DOM value has actually diverged from what
    # was last recorded — an attribute the decorated code never touched is still the
    # server's to update.
    class Preserve < Presenter
      attr_reader :attributes, :element

      # @param attributes [String, Array<String, Symbol>, nil] attribute name(s) to
      #   protect from morphing, e.g. `"aria-expanded"` or `%w[aria-expanded class]`.
      #   A String is split on whitespace; an Array is flattened and split the same
      #   way, so either form composes.
      # @param element [Boolean] true exempts the whole subtree — attributes AND
      #   children — from morphing, equivalent to `data-turbo-permanent` but scoped to
      #   morph passes only. Default false.
      # @param overrides [Hash] merged into the root element, last
      # @raise [ArgumentError] if there is nothing to preserve — `attributes` is empty
      #   and `element` is false
      def initialize(attributes: nil, element: false, **overrides)
        @attributes = normalize_attributes(attributes)
        @element = !!element

        if @attributes.empty? && !@element
          raise ArgumentError, "Crosswire::Presenters::Preserve has nothing to preserve: " \
                                "pass attributes: (a space-separated list, or an Array) or element: true"
        end

        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(attributes: attribute_list, element: (element || nil)),
          overrides
        )
      end

      private

      def attribute_list
        return nil if @attributes.empty?

        @attributes.join(" ")
      end

      def normalize_attributes(value)
        Array(value).flat_map { |entry| entry.to_s.split(/\s+/) }.reject(&:empty?)
      end
    end
  end
end
