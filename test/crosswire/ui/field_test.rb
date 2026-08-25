# frozen_string_literal: true

require "test_helper"
require "crosswire/ui/field"

module Crosswire
  module UI
    # Presenter unit suite (ui-tier-spec.md §7.1) — one test per a11y wiring
    # guarantee, named for it, per spec §7.1's own rule for this exact shape of
    # class. This IS the point of `Crosswire::UI::Field` (see its docstring) — there
    # is no separate "class string" concern the way Button/Badge/Card/Input/Select
    # have one, because Field declares no `Variants` at all.
    class FieldTest < Minitest::Test
      # --- guarantee 1: label `for` matches the control's `id` ------------------------

      def test_label_for_matches_the_shared_id
        field = Field.new(id: "email")

        assert_equal "email", field.label_attrs["for"]
      end

      def test_control_attrs_carries_the_same_id
        assert_equal "email", Field.new(id: "email").control_attrs[:id]
      end

      # --- guarantee 2: a hint wires aria-describedby, not just visible text ----------

      def test_hint_wires_aria_describedby_on_the_control
        field = Field.new(id: "email", hint: "We'll never share this")

        assert_equal "email-hint", field.control_attrs[:"aria-describedby"]
        assert_equal "email-hint", field.hint_attrs["id"]
      end

      def test_no_hint_omits_aria_describedby_and_the_hint_text
        field = Field.new(id: "email")

        refute field.control_attrs.key?(:"aria-describedby")
        assert_nil field.hint
      end

      # --- guarantee 3: an error wires aria-errormessage + aria-invalid ----------------

      def test_error_wires_aria_errormessage_and_aria_invalid_on_the_control
        field = Field.new(id: "email", error: "is invalid")

        assert_equal "email-error", field.control_attrs[:"aria-errormessage"]
        assert_equal "true", field.control_attrs[:"aria-invalid"]
        assert_equal "email-error", field.error_attrs["id"]
      end

      def test_no_error_omits_aria_errormessage_and_aria_invalid
        field = Field.new(id: "email")

        refute field.control_attrs.key?(:"aria-errormessage")
        refute field.control_attrs.key?(:"aria-invalid")
      end

      def test_error_presence_alone_decides_invalidity_no_separate_flag
        # There is no `invalid:` kwarg on Field at all — the presence of `error:` IS
        # the invalid signal, so there is nothing for the two to drift out of sync
        # with each other.
        refute_respond_to Field.new(id: "x"), :invalid
      end

      # --- hint and error can compose together on one control -------------------------

      def test_hint_and_error_both_wire_onto_the_control_together
        field = Field.new(id: "email", hint: "We'll never share this", error: "is invalid")

        assert_equal "email-hint", field.control_attrs[:"aria-describedby"]
        assert_equal "email-error", field.control_attrs[:"aria-errormessage"]
        assert_equal "true", field.control_attrs[:"aria-invalid"]
      end

      # --- control_attrs stays Symbol-keyed (double-splat + cw_attrs safe) ------------

      def test_control_attrs_is_symbol_keyed
        keys = Field.new(id: "email", hint: "x", error: "y").control_attrs.keys

        assert(keys.all? { |k| k.is_a?(Symbol) }, "expected every control_attrs key to be a Symbol, got #{keys.inspect}")
      end

      # --- root/label/hint/error carry their own BEM class -----------------------------

      def test_root_and_element_attrs_carry_their_own_bem_class
        field = Field.new(id: "email", hint: "h", error: "e")

        assert_equal "cw-field", field.root_attrs["class"]
        assert_equal "cw-field__label", field.label_attrs["class"]
        assert_equal "cw-field__hint", field.hint_attrs["class"]
        assert_equal "cw-field__error", field.error_attrs["class"]
      end

      def test_caller_class_composes_after_ours_on_root
        assert_equal "cw-field extra", Field.new(id: "x", class: "extra").root_attrs["class"]
      end

      # `extend Variants` with zero declared `variant`/`boolean` entries — purely so
      # `.variants` exists for the gallery props table and `rake ui:registry`
      # (`bin/build_gallery.rb`/`Rakefile` call it unconditionally on every
      # registered component). Field genuinely has none to declare — see the class
      # docstring — so an empty Hash is the correct, honest answer, not a gap.
      def test_variants_introspection_is_empty
        assert_equal({}, Field.variants)
      end

      def test_overrides_do_not_clobber_computed_root_attributes
        attrs = Field.new(id: "x", data: { controller: "dirty-form" }).root_attrs

        assert_equal "cw-field", attrs["class"]
        assert_equal "dirty-form", attrs["data-controller"]
      end
    end
  end
end
