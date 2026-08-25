# frozen_string_literal: true

require "test_helper"
require "crosswire/ui/input"

module Crosswire
  module UI
    # Presenter unit suite (ui-tier-spec.md §7.1).
    class InputTest < Minitest::Test
      def test_default_class_string
        assert_equal "cw-input cw-focusable", Input.new.attrs["class"]
      end

      def test_every_size_value
        {
          sm: "cw-input cw-input--sm cw-focusable",
          md: "cw-input cw-focusable",
          lg: "cw-input cw-input--lg cw-focusable"
        }.each do |size, expected|
          assert_equal expected, Input.new(size: size).attrs["class"], "size #{size.inspect}"
        end
      end

      def test_unknown_size_raises_naming_valid_values
        error = assert_raises(ArgumentError) { Input.new(size: :huge).attrs }

        assert_match(/huge/, error.message)
        %w[sm md lg].each { |v| assert_match(/#{v}/, error.message) }
      end

      # --- tag_name follows multiline -------------------------------------------------

      def test_tag_name_is_input_by_default
        assert_equal :input, Input.new.tag_name
      end

      def test_tag_name_is_textarea_when_multiline
        assert_equal :textarea, Input.new(multiline: true).tag_name
      end

      # --- type=text by default, overridable -------------------------------------------

      def test_type_text_is_the_default
        assert_equal "text", Input.new.attrs["type"]
      end

      def test_type_is_overridable
        assert_equal "email", Input.new(type: "email").attrs["type"]
      end

      def test_multiline_carries_no_type_attribute
        refute Input.new(multiline: true).attrs.key?("type")
      end

      # --- value: attribute for <input>, content for <textarea> -----------------------

      def test_value_becomes_the_value_attribute_for_a_plain_input
        assert_equal "hello", Input.new(value: "hello").attrs["value"]
      end

      def test_no_value_carries_no_value_attribute
        refute Input.new.attrs.key?("value")
      end

      def test_multiline_carries_no_value_attribute_either
        refute Input.new(multiline: true, value: "hello").attrs.key?("value")
      end

      def test_multiline_value_is_readable_from_the_presenter_for_the_partials_content
        assert_equal "hello", Input.new(multiline: true, value: "hello").value
      end

      # --- aria-invalid: an attribute, not a Variants class ----------------------------

      def test_invalid_sets_aria_invalid_true
        assert_equal "true", Input.new(invalid: true).attrs["aria-invalid"]
      end

      def test_not_invalid_carries_no_aria_invalid
        refute Input.new.attrs.key?("aria-invalid")
      end

      def test_invalid_never_appears_in_the_class_string
        refute_match(/invalid/, Input.new(invalid: true).attrs["class"])
      end

      # --- data-loading, same convention as Button -------------------------------------

      def test_loading_sets_bare_data_loading
        assert_equal "", Input.new(loading: true).attrs["data-loading"]
      end

      def test_not_loading_carries_no_data_loading
        refute Input.new.attrs.key?("data-loading")
      end

      # --- overrides / Attributes.merge contract ---------------------------------------

      def test_caller_class_composes_after_ours
        assert_equal "cw-input cw-focusable extra", Input.new(class: "extra").attrs["class"]
      end

      def test_caller_class_bang_replaces_ours
        assert_equal "only-mine", Input.new("class!" => "only-mine").attrs["class"]
      end

      def test_caller_nil_deletes_a_key
        refute Input.new(value: "x", "value!" => nil).attrs.key?("value")
      end

      def test_variants_introspection
        assert_equal({ size: { values: %i[sm md lg], default: :md } }, Input.variants)
      end

      def test_overrides_do_not_clobber_computed_attributes
        attrs = Input.new(size: :lg, data: { controller: "autogrow" }).attrs

        assert_equal "cw-input cw-input--lg cw-focusable", attrs["class"]
        assert_equal "autogrow", attrs["data-controller"]
      end
    end
  end
end
