# frozen_string_literal: true

# Required directly rather than through test_helper: sibling agents are wiring up
# lib/crosswire.rb and app/assets/javascripts/crosswire/index.js in parallel, and this
# suite must not depend on that being finished. `crosswire/presenters/timeout` pulls in
# its own dependency (`crosswire/presenter`, which pulls in `crosswire/attributes`), so
# this is a complete, self-contained load path — and, like test_helper.rb, it proves
# the presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/timeout"
require "minitest/autorun"

module Crosswire
  module Presenters
    class TimeoutTest < Minitest::Test
      def presenter(**options)
        Timeout.new(delay: 4000, **options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--timeout", Timeout.identifier
      end

      # --- Stimulus wiring on the root -------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--timeout", presenter.root_attrs["data-controller"]
      end

      def test_delay_is_required
        assert_raises(ArgumentError) { Timeout.new }
      end

      def test_delay_is_rendered
        attrs = presenter(delay: 8000).root_attrs
        assert_equal 8000, attrs["data-cw--timeout-delay-value"]
      end

      def test_start_on_connect_defaults_to_true
        assert_equal "true", presenter.root_attrs["data-cw--timeout-start-on-connect-value"]
      end

      def test_start_on_connect_is_configurable
        attrs = presenter(start_on_connect: false).root_attrs
        assert_equal "false", attrs["data-cw--timeout-start-on-connect-value"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "cw--dismiss" }).root_attrs
        assert_equal "cw--timeout cw--dismiss", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_of_controller_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_class_survives
        attrs = presenter(class: "cw-toast").root_attrs
        assert_equal "cw-toast", attrs["class"]
      end

      def test_caller_action_composes_alongside_ours
        attrs = presenter(data: { action: "cw--timeout:elapsed->cw--dismiss#dismiss" }).root_attrs
        assert_equal "cw--timeout:elapsed->cw--dismiss#dismiss", attrs["data-action"]
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, presenter.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
