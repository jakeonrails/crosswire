# frozen_string_literal: true

# Required directly rather than through test_helper: sibling agents are wiring up
# lib/crosswire.rb and app/assets/javascripts/crosswire/index.js in parallel, and this
# suite must not depend on that being finished. `crosswire/presenters/countdown` pulls
# in its own dependency (`crosswire/presenter`, which pulls in `crosswire/attributes`),
# so this is a complete, self-contained load path — and, like test_helper.rb, it proves
# the presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/countdown"
require "minitest/autorun"

module Crosswire
  module Presenters
    class CountdownTest < Minitest::Test
      DEADLINE = "2026-08-15T18:30:00Z"

      def presenter(**options)
        Countdown.new(deadline: DEADLINE, **options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--countdown", Countdown.identifier
      end

      # --- Stimulus wiring on the root -------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--countdown", presenter.root_attrs["data-controller"]
      end

      def test_deadline_is_required
        assert_raises(ArgumentError) { Countdown.new }
      end

      def test_deadline_is_rendered_as_a_value
        attrs = presenter.root_attrs
        assert_equal DEADLINE, attrs["data-cw--countdown-deadline-value"]
      end

      def test_format_is_absent_by_default
        refute presenter.root_attrs.key?("data-cw--countdown-format-value")
      end

      def test_format_is_configurable
        attrs = presenter(format: "words").root_attrs
        assert_equal "words", attrs["data-cw--countdown-format-value"]
      end

      # --- output target + accessibility ------------------------------------------------

      def test_output_attrs_declares_the_target
        attrs = presenter.output_attrs
        assert_equal "output", attrs["data-cw--countdown-target"]
      end

      def test_output_attrs_has_timer_role
        assert_equal "timer", presenter.output_attrs["role"]
      end

      def test_output_attrs_defaults_aria_live_off
        assert_equal "off", presenter.output_attrs["aria-live"]
      end

      def test_output_attrs_carries_the_absolute_deadline
        assert_equal DEADLINE, presenter.output_attrs["datetime"]
      end

      def test_output_attrs_composes_caller_extras
        attrs = presenter.output_attrs(class: "cw-countdown__output")
        assert_equal "cw-countdown__output", attrs["class"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "cw--transition" }).root_attrs
        assert_equal "cw--countdown cw--transition", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_of_controller_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_class_survives
        attrs = presenter(class: "cw-countdown").root_attrs
        assert_equal "cw-countdown", attrs["class"]
      end

      def test_caller_action_composes_alongside_ours
        attrs = presenter(data: { action: "cw--countdown:elapsed->form#disable" }).root_attrs
        assert_equal "cw--countdown:elapsed->form#disable", attrs["data-action"]
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, presenter.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
