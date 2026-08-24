# frozen_string_literal: true

require "test_helper"
require "crosswire/ui/button"

module Crosswire
  module UI
    # Presenter unit suite (ui-tier-spec.md §7.1) — no Rails, no rendering, just the
    # attribute hashes `Crosswire::UI::Button` computes. This is the worked example's
    # test file: every rule the class docstring promises gets one assertion named
    # for it, plus the class-ORDER assertion Variants itself demands (spec §3 rule 1).
    class ButtonTest < Minitest::Test
      # --- default variant, exact class string ----------------------------------------

      def test_default_class_string
        assert_equal "cw-button cw-focusable", Button.new.attrs["class"]
      end

      # --- every variant value -----------------------------------------------------

      def test_every_variant_value
        {
          primary: "cw-button cw-button--primary cw-focusable",
          secondary: "cw-button cw-focusable",
          ghost: "cw-button cw-button--ghost cw-focusable",
          danger: "cw-button cw-button--danger cw-focusable",
          link: "cw-button cw-button--link cw-focusable"
        }.each do |variant, expected|
          assert_equal expected, Button.new(variant: variant).attrs["class"],
                       "variant #{variant.inspect}"
        end
      end

      def test_every_size_value
        {
          sm: "cw-button cw-button--sm cw-focusable",
          md: "cw-button cw-focusable",
          lg: "cw-button cw-button--lg cw-focusable",
          icon: "cw-button cw-button--icon cw-focusable"
        }.each do |size, expected|
          assert_equal expected, Button.new(size: size).attrs["class"],
                       "size #{size.inspect}"
        end
      end

      def test_block_boolean
        assert_equal "cw-button cw-button--block cw-focusable", Button.new(block: true).attrs["class"]
        assert_equal "cw-button cw-focusable", Button.new(block: false).attrs["class"]
      end

      # --- class ORDER: base, then each declared variant in declaration order --------

      def test_class_order_is_base_then_variant_then_size_then_block
        classes = Button.new(variant: :primary, size: :lg, block: true).attrs["class"]

        assert_equal "cw-button cw-button--primary cw-button--lg cw-button--block cw-focusable", classes
      end

      # --- unknown value raises, naming valid values ----------------------------------

      def test_unknown_variant_raises_naming_valid_values
        error = assert_raises(ArgumentError) { Button.new(variant: :nope).attrs }

        assert_match(/nope/, error.message)
        %w[primary secondary ghost danger link].each { |v| assert_match(/#{v}/, error.message) }
      end

      def test_unknown_size_raises_naming_valid_values
        error = assert_raises(ArgumentError) { Button.new(size: :huge).attrs }

        assert_match(/huge/, error.message)
        %w[sm md lg icon].each { |v| assert_match(/#{v}/, error.message) }
      end

      # --- class:, class!, nil (Crosswire::Attributes.merge contract) ----------------

      def test_caller_class_composes_after_ours
        assert_equal "cw-button cw-focusable extra", Button.new(class: "extra").attrs["class"]
      end

      def test_caller_class_bang_replaces_ours
        assert_equal "only-mine", Button.new("class!" => "only-mine").attrs["class"]
      end

      def test_caller_nil_deletes_a_key
        refute Button.new(href: "/x", "href!" => nil).attrs.key?("href")
      end

      # --- a11y guarantee 1: type=button by default -----------------------------------

      def test_type_button_is_the_default
        assert_equal "button", Button.new.attrs["type"]
      end

      def test_type_is_overridable_for_a_real_submit_button
        assert_equal "submit", Button.new(type: "submit").attrs["type"]
      end

      def test_button_never_carries_an_href
        refute Button.new.attrs.key?("href")
      end

      # --- a11y guarantee 2: disabled anchors drop href, gain role+aria-disabled -----

      def test_disabled_anchor_drops_its_href
        refute Button.new(href: "/danger", disabled: true).attrs.key?("href")
      end

      def test_disabled_anchor_gains_role_link_and_aria_disabled
        attrs = Button.new(href: "/danger", disabled: true).attrs

        assert_equal "link", attrs["role"]
        assert_equal "true", attrs["aria-disabled"]
      end

      def test_enabled_anchor_keeps_its_href_and_carries_no_role_or_aria_disabled
        attrs = Button.new(href: "/ok").attrs

        assert_equal "/ok", attrs["href"]
        refute attrs.key?("role")
        refute attrs.key?("aria-disabled")
      end

      def test_disabled_button_gets_the_native_disabled_attribute_not_aria_disabled
        attrs = Button.new(disabled: true).attrs

        assert_equal true, attrs["disabled"]
        refute attrs.key?("aria-disabled")
      end

      def test_tag_name_follows_href_presence_regardless_of_disabled
        assert_equal :button, Button.new.tag_name
        assert_equal :a, Button.new(href: "/x").tag_name
        assert_equal :a, Button.new(href: "/x", disabled: true).tag_name
      end

      # --- a11y guarantee 3: aria-busy travels with bare data-loading -----------------

      def test_loading_sets_aria_busy_and_bare_data_loading
        attrs = Button.new(loading: true).attrs

        assert_equal "true", attrs["aria-busy"]
        assert_equal "", attrs["data-loading"]
      end

      def test_loading_applies_to_an_anchor_too
        attrs = Button.new(href: "/x", loading: true).attrs

        assert_equal "true", attrs["aria-busy"]
        assert_equal "", attrs["data-loading"]
      end

      def test_not_loading_carries_neither_attribute
        attrs = Button.new.attrs

        refute attrs.key?("aria-busy")
        refute attrs.key?("data-loading")
      end

      # --- .variants introspection (feeds the gallery props table + registry.json) ---

      def test_variants_introspection
        assert_equal({
                       variant: { values: %i[primary secondary ghost danger link], default: :secondary },
                       size: { values: %i[sm md lg icon], default: :md },
                       block: { values: [true, false], default: false }
                     }, Button.variants)
      end

      # --- overrides merge last, so a caller can add anything without losing ours ----

      def test_overrides_do_not_clobber_computed_attributes
        attrs = Button.new(variant: :primary, data: { controller: "analytics" }).attrs

        assert_equal "cw-button cw-button--primary cw-focusable", attrs["class"]
        assert_equal "analytics", attrs["data-controller"]
      end
    end
  end
end
