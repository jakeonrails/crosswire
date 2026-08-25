# frozen_string_literal: true

require "test_helper"
require "crosswire/ui/card"

module Crosswire
  module UI
    # Presenter unit suite (ui-tier-spec.md §7.1) — the class-string/attrs half of
    # the Slots proof. `Crosswire::UI::Slots` itself has no state of its own to unit
    # test without a view context to `capture` into (see its docstring) — that half
    # of the proof is `test/crosswire/ui/rendering_test.rb`'s "card's four slot
    # combinations", not this file's job.
    class CardTest < Minitest::Test
      def test_default_class_string
        assert_equal "cw-card", Card.new.root_attrs["class"]
      end

      def test_every_variant_value
        {
          plain: "cw-card",
          raised: "cw-card cw-card--raised",
          outlined: "cw-card cw-card--outlined"
        }.each do |variant, expected|
          assert_equal expected, Card.new(variant: variant).root_attrs["class"], "variant #{variant.inspect}"
        end
      end

      def test_interactive_boolean
        assert_equal "cw-card cw-card--interactive", Card.new(interactive: true).root_attrs["class"]
        assert_equal "cw-card", Card.new(interactive: false).root_attrs["class"]
      end

      # --- class ORDER: base, then variant, then interactive (declaration order) -----

      def test_class_order_is_base_then_variant_then_interactive
        assert_equal "cw-card cw-card--raised cw-card--interactive",
                     Card.new(variant: :raised, interactive: true).root_attrs["class"]
      end

      def test_unknown_variant_raises_naming_valid_values
        error = assert_raises(ArgumentError) { Card.new(variant: :nope).root_attrs }

        assert_match(/nope/, error.message)
        %w[plain raised outlined].each { |v| assert_match(/#{v}/, error.message) }
      end

      def test_caller_class_composes_after_ours
        assert_equal "cw-card extra", Card.new(class: "extra").root_attrs["class"]
      end

      def test_caller_class_bang_replaces_ours
        assert_equal "only-mine", Card.new("class!" => "only-mine").root_attrs["class"]
      end

      def test_caller_nil_deletes_a_key
        card = Card.new(data: { testid: "plan-card" }, "data-testid!" => nil)
        refute card.root_attrs.key?("data-testid")
      end

      # --- header/body/footer attrs ---------------------------------------------------

      def test_header_body_footer_attrs_carry_their_own_bem_class
        card = Card.new

        assert_equal "cw-card__header", card.header_attrs["class"]
        assert_equal "cw-card__body", card.body_attrs["class"]
        assert_equal "cw-card__footer", card.footer_attrs["class"]
      end

      def test_header_body_footer_attrs_accept_extra_overrides
        card = Card.new

        assert_equal "cw-card__header extra", card.header_attrs(class: "extra")["class"]
      end

      def test_variants_introspection
        assert_equal({
                       variant: { values: %i[plain raised outlined], default: :plain },
                       interactive: { values: [true, false], default: false }
                     }, Card.variants)
      end

      def test_overrides_do_not_clobber_computed_attributes
        attrs = Card.new(variant: :raised, data: { controller: "analytics" }).root_attrs

        assert_equal "cw-card cw-card--raised", attrs["class"]
        assert_equal "analytics", attrs["data-controller"]
      end
    end
  end
end
