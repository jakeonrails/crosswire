# frozen_string_literal: true

# Required directly rather than through test_helper: sibling agents are wiring up
# lib/crosswire.rb and app/assets/javascripts/crosswire/index.js in parallel, and this
# suite must not depend on that being finished. `crosswire/presenters/char_count` pulls
# in its own dependency (`crosswire/presenter`, which pulls in `crosswire/attributes`),
# so this is a complete, self-contained load path — and, like test_helper.rb, it proves
# the presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/char_count"
require "minitest/autorun"

module Crosswire
  module Presenters
    class CharCountTest < Minitest::Test
      def presenter(**options)
        CharCount.new(max: 280, **options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--char-count", CharCount.identifier
      end

      # --- Stimulus wiring on the root -------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--char-count", presenter.root_attrs["data-controller"]
      end

      def test_root_declares_max_and_warn_at_values
        attrs = presenter(max: 500, warn_at: 0.8).root_attrs
        assert_equal 500, attrs["data-cw--char-count-max-value"]
        assert_equal 0.8, attrs["data-cw--char-count-warn-at-value"]
      end

      def test_warn_at_has_a_sensible_default
        assert_equal 0.9, presenter.root_attrs["data-cw--char-count-warn-at-value"]
      end

      # --- classes: optional, guarded per R3 --------------------------------------------

      def test_over_and_warn_classes_are_omitted_when_not_given
        attrs = presenter.root_attrs
        refute attrs.key?("data-cw--char-count-over-class")
        refute attrs.key?("data-cw--char-count-warn-class")
      end

      def test_over_and_warn_classes_are_passed_through_when_given
        attrs = presenter(over_class: "is-over", warn_class: "is-warn").root_attrs
        assert_equal "is-over", attrs["data-cw--char-count-over-class"]
        assert_equal "is-warn", attrs["data-cw--char-count-warn-class"]
      end

      # --- input_attrs -----------------------------------------------------------------

      def test_input_target_and_action
        attrs = presenter.input_attrs
        assert_equal "input", attrs["data-cw--char-count-target"]
        assert_equal "input->cw--char-count#update", attrs["data-action"]
      end

      # --- output_attrs: the accessibility contract for the live region ----------------

      def test_output_target_and_live_region_attrs
        attrs = presenter.output_attrs
        assert_equal "output", attrs["data-cw--char-count-target"]
        assert_equal "polite", attrs["aria-live"]
        assert_equal "true", attrs["aria-atomic"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--char-count analytics", attrs["data-controller"]
      end

      def test_caller_action_on_input_is_added_not_replaced
        attrs = presenter.input_attrs(data: { action: "blur->analytics#track" })
        assert_equal "input->cw--char-count#update blur->analytics#track", attrs["data-action"]
      end

      def test_caller_can_force_replacement_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_classes_survive_on_root
        attrs = presenter(class: "field").root_attrs
        assert_equal "field", attrs["class"]
      end

      def test_caller_overrides_on_output_win_last
        attrs = presenter.output_attrs(id: "bio_count")
        assert_equal "bio_count", attrs["id"]
        assert_equal "polite", attrs["aria-live"]
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, CharCount.new(max: 280).root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
