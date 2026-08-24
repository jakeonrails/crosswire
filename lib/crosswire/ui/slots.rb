# frozen_string_literal: true

module Crosswire
  module UI
    # A tiny slot-capturing builder yielded to a container component's block —
    # card's header/body/footer, and any future multi-region component that needs the
    # same shape (spec §2, worked through for card in spec §6.3).
    #
    #   slots = Crosswire::UI::Slots.new(view_context: self)
    #   whole_output = view_context.capture { block.call(slots) }
    #   body = slots[:body] || (slots.any? ? nil : whole_output)
    #
    # That is the ENTIRE contract, and it is deliberately the only code path — never
    # branch on `block.arity` to decide "did the caller name slots or not". Proc#arity
    # lies the moment a block takes zero, optional, or splat arguments in ways that
    # collapse to the same ambiguous negative number; it cannot answer "did `s.header`
    # get called inside this block" at all. The one thing that CAN answer that
    # question is capturing the block's own output and recording slot calls in the
    # same pass, then asking afterwards which slots got recorded. If none did, the
    # captured output IS the body — that's the "arity-0 shorthand" from spec §2, and
    # it falls out of this ordering rather than being special-cased on the signature.
    class Slots
      NAMES = %i[header body footer].freeze

      def initialize(view_context:)
        @view_context = view_context
        @captured = {}
      end

      NAMES.each do |name|
        # `s.header { "Title" }` — records under `name`, returns nil deliberately, so
        # a caller can never accidentally interpolate a slot's own return value into
        # the surrounding body.
        define_method(name) do |&block|
          @captured[name] = @view_context.capture(&block)
          nil
        end
      end

      def [](name) = @captured[name]

      def any? = @captured.any?
    end
  end
end
