# frozen_string_literal: true

# Required directly rather than through test_helper, matching preserve_test.rb: this
# suite must not depend on lib/crosswire.rb or index.js being finished, and — like
# test_helper.rb — this proves the presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/fallback"
require "minitest/autorun"

module Crosswire
  module Presenters
    class FallbackTest < Minitest::Test
      def presenter(**options)
        Fallback.new(**options)
      end

      # --- identifier derivation ---------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--fallback", Fallback.identifier
      end

      # --- Stimulus wiring on the root ----------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--fallback", presenter.root_attrs["data-controller"]
      end

      def test_state_defaults_to_ok
        assert_equal "ok", presenter.root_attrs["data-cw--fallback-state-value"]
      end

      def test_state_is_configurable_and_accepts_a_symbol
        assert_equal "loading", presenter(state: "loading").root_attrs["data-cw--fallback-state-value"]
        assert_equal "failed", presenter(state: :failed).root_attrs["data-cw--fallback-state-value"]
      end

      def test_failed_class_is_omitted_by_default
        refute presenter.root_attrs.key?("data-cw--fallback-failed-class"),
               "an absent class attribute is what the controller's hasFailedClass guard expects (R3)"
      end

      def test_failed_class_is_rendered_when_given
        attrs = presenter(failed_class: "is-failed").root_attrs
        assert_equal "is-failed", attrs["data-cw--fallback-failed-class"]
      end

      def test_root_wires_every_pending_check_and_fail_event
        actions = presenter.root_attrs["data-action"].split(/\s+/)

        assert_includes actions, "turbo:before-fetch-request->cw--fallback#pending"
        assert_includes actions, "turbo:before-fetch-response->cw--fallback#check"
        assert_includes actions, "turbo:fetch-request-error->cw--fallback#fail"
        assert_includes actions, "turbo:frame-missing->cw--fallback#fail"
      end

      # --- loading_attrs -------------------------------------------------------------

      def test_loading_attrs_is_a_polite_live_region
        attrs = presenter.loading_attrs
        assert_equal "loading", attrs["data-cw--fallback-target"]
        assert_equal "status", attrs["role"]
        assert_equal "polite", attrs["aria-live"]
        assert_equal "true", attrs["aria-atomic"]
      end

      def test_loading_attrs_is_hidden_unless_state_is_loading
        assert_equal true, presenter(state: "ok").loading_attrs["hidden"]
        assert_equal true, presenter(state: "failed").loading_attrs["hidden"]
        assert_equal false, presenter(state: "loading").loading_attrs["hidden"]
      end

      # --- failed_attrs ----------------------------------------------------------------

      def test_failed_attrs_is_an_assertive_live_region
        attrs = presenter.failed_attrs
        assert_equal "failed", attrs["data-cw--fallback-target"]
        assert_equal "alert", attrs["role"]
        assert_equal "true", attrs["aria-atomic"]
      end

      def test_failed_attrs_is_hidden_unless_state_is_failed
        assert_equal true, presenter(state: "ok").failed_attrs["hidden"]
        assert_equal true, presenter(state: "loading").failed_attrs["hidden"]
        assert_equal false, presenter(state: "failed").failed_attrs["hidden"]
      end

      # --- source_attrs ------------------------------------------------------------------

      def test_source_attrs_carries_only_the_target
        attrs = presenter.source_attrs
        assert_equal "source", attrs["data-cw--fallback-target"]
      end

      # --- extra kwargs on element-level methods compose ---------------------------------

      def test_element_methods_accept_extra_attrs
        assert_equal "1", presenter.loading_attrs("data-x" => "1")["data-x"]
        assert_equal "1", presenter.failed_attrs("data-x" => "1")["data-x"]
        assert_equal "1", presenter.source_attrs("data-x" => "1")["data-x"]
      end

      # --- caller overrides compose, never clobber -----------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--fallback analytics", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_of_controller_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      # --- context-freedom -------------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, presenter.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
