# frozen_string_literal: true

require "crosswire/ui/component"
require "crosswire/ui/variants"

module Crosswire
  module UI
    # RULE 0: a field is layout plus accessibility wiring, nothing else — it ships no
    # controller and reacts to nothing at runtime.
    #
    # The a11y wiring is the ENTIRE point of this component (ui-tier-spec.md §5) — a
    # label with no `for`, a hint no screen reader ever associates with its control, an
    # error announced to sighted users but invisible to assistive tech, are three of
    # the most common form-accessibility bugs in hand-rolled markup, and this class
    # fixes all three with three id relationships:
    #
    #   1. **`label`'s `for` matches the control's `id`.** Both come from the same
    #      `id:` this presenter was constructed with — there is no way for them to
    #      drift, because neither is typed twice.
    #   2. **A hint is `aria-describedby`, not just visible text near the control.**
    #      Without it, a sighted user reads "Must be 8+ characters" next to the field;
    #      a screen reader user tabbing to the control hears only its label.
    #   3. **An error is `aria-errormessage` (with `aria-invalid="true"` alongside it —
    #      `aria-errormessage` alone is not exposed by every AT without it) — not just
    #      red text.** `aria-errormessage` id-references the error text as belonging
    #      to THIS control specifically, the way `aria-describedby` does for the hint.
    #
    # `cw.field` composes `cw.input` by default (the common case: a text field needs
    # exactly this wiring and nothing more). Anything else — `cw.select`, a
    # `<textarea>`, a hand-rolled radio group — goes through `cw.field_for` instead,
    # which yields this presenter and renders no control of its own:
    #
    #   <%= cw.field "Email", id: "email", hint: "We'll never share this" %>
    #
    #   <%= cw.field_for id: "country", error: @user.errors[:country].first do |f| %>
    #     <%= cw.select(**f.control_attrs) do %>
    #       <option value="us">United States</option>
    #     <% end %>
    #   <% end %>
    #
    # Morph: Safe
    #   A field's own wrapper/label/hint/error markup is a pure function of the
    #   presenter's constructor arguments, so any morph re-renders it identically.
    #   The control it wraps carries its own Morph verdict independently (`cw.input`
    #   is Safe; a `cw.select` composed in via `field_for` is Server-owned on its own
    #   terms — this presenter neither changes nor needs to know that).
    class Field < Component
      # No `variant`/`boolean` declared — Field has none (see the docstring above) —
      # but `extend Variants` anyway, for `.variants` alone: the gallery's props
      # table (`bin/build_gallery.rb`) and `rake ui:registry` both call
      # `presenter_class.variants` unconditionally across every registered
      # component, and an empty declared table (`{}`) is exactly what tells a
      # reader "this component has no variants", the same true fact `Button.variants`
      # or `Card.variants` would report for any variant it hadn't declared.
      extend Variants
      base "cw-field"

      attr_reader :id, :hint, :error

      # @param id [String] shared by the label's `for` and the control's `id` — the
      #   one thing this whole class exists to keep from drifting
      # @param hint [String, nil] supporting text, wired via `aria-describedby`
      # @param error [String, nil] validation text, wired via `aria-errormessage` +
      #   `aria-invalid="true"`. Presence alone decides invalidity — there is no
      #   separate `invalid:` flag to keep in sync with it.
      # @param overrides [Hash] merged into the root wrapper element, last
      def initialize(id:, hint: nil, error: nil, **overrides)
        @id = id
        @hint = hint
        @error = error
        super(**overrides)
      end

      def hint_id  = "#{id}-hint"
      def error_id = "#{id}-error"

      def root_attrs
        merge({ "class" => self.class.variant_class({}) }, overrides)
      end

      def label_attrs
        { "class" => "cw-field__label", "for" => id }
      end

      def hint_attrs
        { "class" => "cw-field__hint", "id" => hint_id }
      end

      def error_attrs
        { "class" => "cw-field__error", "id" => error_id }
      end

      # The three a11y guarantees above, as a Hash a caller merges onto ANY control —
      # deliberately Symbol-keyed (`:"aria-describedby"`, not `"aria-describedby"`),
      # unlike every OTHER `_attrs` method in this codebase (`button_attrs`,
      # `card_attrs`, …), which return the fully-`Crosswire::Attributes`-merged
      # String-keyed shape ready for `cw_attrs`/`tag`. This one is an INPUT to a
      # presenter constructor, not a rendering target: `cw.select(**f.control_attrs)`
      # keyword-splats it straight into `Crosswire::UI::Select.new`, and Ruby's `**`
      # operator raises `TypeError: wrong argument type String (expected Symbol)` on
      # a String-keyed Hash (see `Crosswire::UI::ButtonHelper#button_for`'s docstring
      # for the same trap from the other direction). Symbol keys work for BOTH call
      # shapes — double-splatting into another presenter, or passing straight to
      # `cw_attrs`/`tag` for hand-rolled markup (`Crosswire::Attributes.merge`
      # stringifies any key via `#to_s` regardless of the source hash's key type) —
      # so this is the one shape that is never wrong.
      def control_attrs
        attrs = { id: id }
        attrs[:"aria-describedby"] = hint_id if hint
        attrs[:"aria-errormessage"] = error_id if error
        attrs[:"aria-invalid"] = "true" if error
        attrs
      end
    end
  end
end
