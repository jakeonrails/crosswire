# frozen_string_literal: true

require "crosswire/ui/component"
require "crosswire/ui/variants"

module Crosswire
  module UI
    # RULE 0: a styled text input needs no JavaScript at all — this presenter emits
    # markup and CSS hooks only. Reach for `cw.autogrow`/`cw.dirty-form`/`cw.reveal`
    # (all separate, composable primitives) when you actually need runtime behaviour;
    # none of it belongs on this class.
    #
    # The shell button/badge/card don't need: a single `<input>` OR `<textarea>`,
    # chosen by `multiline:` rather than a separate component, because the two share
    # every other concern here (size, invalid styling, loading) and Rails' own
    # `text_field`/`text_area` split the same way for the same reason.
    #
    #   Crosswire::UI::Input.new(size: :sm, invalid: true).attrs
    #   # => {"class" => "cw-input cw-input--sm cw-focusable", "type" => "text",
    #   #     "aria-invalid" => "true"}
    #
    # `invalid` is deliberately NOT a `Variants` boolean — it never emits a class of
    # its own. It only sets `aria-invalid="true"`, which `input.css` styles directly
    # with a `[aria-invalid="true"]` attribute selector (ui-tier-spec.md §5's "aria-
    # invalid styling hook"). That keeps the invalid treatment attached to the same
    # attribute a real form library (or `Crosswire::UI::Field`, below) sets for
    # accessibility reasons anyway — one signal drives both the screen-reader
    # semantics and the visual state, so they cannot drift apart the way a separate
    # `invalid: true` boolean class could (visually invalid but not actually marked
    # `aria-invalid`, or vice versa).
    #
    # Morph: Safe
    #   An input's OWN classes/attributes are a pure function of the presenter's
    #   constructor arguments, so any morph re-renders those identically. The thing a
    #   morph could clobber — text the user is actively typing — is native browser
    #   state Turbo 8 already protects on its own: idiomorph does not overwrite the
    #   `value` of a focused form field during a page-level morph. Nothing here needs
    #   to add anything on top of that (contrast `Crosswire::UI::Select`, whose
    #   Server-owned verdict is about a DIFFERENT DOM/attribute-sync gap idiomorph
    #   does NOT cover for `<option selected>`).
    class Input < Component
      extend Variants

      base "cw-input"
      variant :size, {
        sm: "cw-input--sm",
        md: nil,
        lg: "cw-input--lg"
      }, default: :md

      attr_reader :size, :multiline, :invalid, :loading, :value

      # @param size [Symbol] see `variant` declaration above
      # @param multiline [Boolean] renders `<textarea>` instead of `<input>`
      # @param invalid [Boolean] sets `aria-invalid="true"` — see the docstring above
      #   for why this is an attribute, not a `Variants` class
      # @param loading [Boolean] sets bare `data-loading` (same convention as
      #   `Crosswire::UI::Button` — see that class's docstring guarantee 3)
      # @param value [String, nil] for `<input>`, rendered as the `value` attribute;
      #   for `<textarea>`, rendered as element content (a `<textarea>` has no
      #   `value` attribute at all — its content IS the value)
      # @param overrides [Hash] merged into the root element, last — pass
      #   `type: "email"` etc. here; it wins over the `type: "text"` default
      def initialize(size: :md, multiline: false, invalid: false, loading: false,
                     value: nil, **overrides)
        @size = size
        @multiline = !!multiline
        @invalid = !!invalid
        @loading = !!loading
        @value = value
        super(**overrides)
      end

      def tag_name = multiline ? :textarea : :input

      def attrs
        merge(
          { "class" => "#{self.class.variant_class(size: size)} cw-focusable" },
          element_attrs,
          state_attrs,
          overrides
        )
      end

      private

      # A `<textarea>` gets no `type`/`value` attributes at all — its content is its
      # value, rendered by the partial, not by this hash.
      def element_attrs
        return {} if multiline

        out = { "type" => "text" }
        out["value"] = value if value
        out
      end

      def state_attrs
        out = {}
        out["aria-invalid"] = "true" if invalid
        out["data-loading"] = "" if loading
        out
      end
    end
  end
end
