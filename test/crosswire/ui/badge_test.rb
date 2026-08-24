# frozen_string_literal: true

require "test_helper"
require "crosswire/ui/badge"

module Crosswire
  module UI
    # Presenter unit suite (ui-tier-spec.md §7.1). Badge is deliberately the smallest
    # UI-tier component — one six-value `variant` plus one `boolean`, nothing else —
    # specifically so it can shake out a Variants engine gap with the least other
    # machinery in the way (see the class docstring). None turned up: every
    # combination below composes exactly as `Crosswire::UI::Variants`' own docstring
    # promises, so this file doubles as that promise's proof rather than a regression
    # net for a bug that was found and fixed.
    class BadgeTest < Minitest::Test
      def test_default_class_string
        assert_equal "cw-badge", Badge.new.attrs["class"]
      end

      def test_every_variant_value
        {
          neutral: "cw-badge",
          accent: "cw-badge cw-badge--accent",
          danger: "cw-badge cw-badge--danger",
          success: "cw-badge cw-badge--success",
          warning: "cw-badge cw-badge--warning",
          info: "cw-badge cw-badge--info"
        }.each do |variant, expected|
          assert_equal expected, Badge.new(variant: variant).attrs["class"], "variant #{variant.inspect}"
        end
      end

      def test_dot_boolean
        assert_equal "cw-badge cw-badge--dot", Badge.new(dot: true).attrs["class"]
        assert_equal "cw-badge", Badge.new(dot: false).attrs["class"]
      end

      # --- class ORDER: base, then variant, then dot (declaration order) -------------

      def test_class_order_is_base_then_variant_then_dot
        assert_equal "cw-badge cw-badge--success cw-badge--dot",
                     Badge.new(variant: :success, dot: true).attrs["class"]
      end

      # A boolean declared BEFORE a value-variant still emits after it, and a
      # neutral (nil-mapped) variant combined with dot emits ONLY the dot class with
      # no stray leading/trailing space — this is exactly the kind of two-declaration
      # interaction button's single boolean (paired with variant AND size) doesn't
      # exercise on its own, since block always sits last.
      def test_neutral_variant_with_dot_has_no_stray_whitespace
        classes = Badge.new(variant: :neutral, dot: true).attrs["class"]

        assert_equal "cw-badge cw-badge--dot", classes
        refute_match(/\s{2,}/, classes)
        refute_match(/\A\s|\s\z/, classes)
      end

      def test_unknown_variant_raises_naming_valid_values
        error = assert_raises(ArgumentError) { Badge.new(variant: :nope).attrs }

        assert_match(/nope/, error.message)
        %w[neutral accent danger success warning info].each { |v| assert_match(/#{v}/, error.message) }
      end

      # `Badge#initialize` coerces `dot:` with `!!dot` before Variants ever sees it
      # (same as every boolean kwarg on every UI presenter — a truthy non-boolean is
      # accepted, not an error, exactly like Ruby's own `if`), so a truthy non-boolean
      # through the PRESENTER never reaches Variants' own unknown-value check at all.
      # Hitting `Variants#variant_class` directly (bypassing that coercion) is what
      # actually exercises the engine's boundary — and it raises correctly: no gap
      # found here, this pins the finding rather than assuming it.
      def test_variants_engine_raises_for_a_genuinely_unknown_boolean_value
        error = assert_raises(ArgumentError) { Badge.variant_class(dot: "yes") }

        assert_match(/dot/, error.message)
        assert_match(/"yes"/, error.message)
      end

      def test_caller_class_composes_after_ours
        assert_equal "cw-badge extra", Badge.new(class: "extra").attrs["class"]
      end

      def test_caller_class_bang_replaces_ours
        assert_equal "only-mine", Badge.new("class!" => "only-mine").attrs["class"]
      end

      def test_caller_nil_deletes_a_key
        badge = Badge.new(data: { testid: "status" }, "data-testid!" => nil)
        refute badge.attrs.key?("data-testid")
      end

      def test_variants_introspection
        assert_equal({
                       variant: { values: %i[neutral accent danger success warning info], default: :neutral },
                       dot: { values: [true, false], default: false }
                     }, Badge.variants)
      end

      def test_overrides_do_not_clobber_computed_attributes
        attrs = Badge.new(variant: :danger, data: { controller: "analytics" }).attrs

        assert_equal "cw-badge cw-badge--danger", attrs["class"]
        assert_equal "analytics", attrs["data-controller"]
      end
    end
  end
end
