# frozen_string_literal: true

# Required directly rather than through test_helper: sibling agents are wiring up
# lib/crosswire.rb and app/assets/javascripts/crosswire/index.js in parallel, and this
# suite must not depend on that being finished. `crosswire/presenters/interval` pulls in
# its own dependency (`crosswire/presenter`, which pulls in `crosswire/attributes`), so
# this is a complete, self-contained load path — and, like test_helper.rb, it proves
# the presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/interval"
require "minitest/autorun"

module Crosswire
  module Presenters
    class IntervalTest < Minitest::Test
      def presenter(**options)
        Interval.new(ms: 5000, **options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--interval", Interval.identifier
      end

      # --- Stimulus wiring on the root -------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--interval", presenter.root_attrs["data-controller"]
      end

      def test_ms_is_required
        assert_raises(ArgumentError) { Interval.new }
      end

      def test_ms_is_rendered
        attrs = presenter(ms: 2000).root_attrs
        assert_equal 2000, attrs["data-cw--interval-ms-value"]
      end

      def test_immediate_defaults_to_false
        assert_equal "false", presenter.root_attrs["data-cw--interval-immediate-value"]
      end

      def test_immediate_is_configurable
        attrs = presenter(immediate: true).root_attrs
        assert_equal "true", attrs["data-cw--interval-immediate-value"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "cw--activate" }).root_attrs
        assert_equal "cw--interval cw--activate", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_of_controller_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_class_survives
        attrs = presenter(class: "cw-poller").root_attrs
        assert_equal "cw-poller", attrs["class"]
      end

      def test_caller_action_composes_alongside_ours
        attrs = presenter(data: { action: "cw--interval:tick->job_status#reload" }).root_attrs
        assert_equal "cw--interval:tick->job_status#reload", attrs["data-action"]
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, presenter.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
