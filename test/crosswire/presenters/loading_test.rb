# frozen_string_literal: true

# Required directly rather than through test_helper, matching preserve_test.rb: this
# suite must not depend on lib/crosswire.rb or index.js being finished, and — like
# test_helper.rb — this proves the presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/loading"
require "minitest/autorun"

module Crosswire
  module Presenters
    class LoadingTest < Minitest::Test
      def presenter(**options)
        Loading.new(**options)
      end

      # --- identifier derivation ---------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--loading", Loading.identifier
      end

      # --- Stimulus wiring on the root ----------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--loading", presenter.root_attrs["data-controller"]
      end

      def test_delay_defaults_to_100
        assert_equal 100, presenter.root_attrs["data-cw--loading-delay-value"]
      end

      def test_delay_is_configurable
        assert_equal 300, presenter(delay: 300).root_attrs["data-cw--loading-delay-value"]
      end

      def test_loading_class_is_omitted_by_default
        refute presenter.root_attrs.key?("data-cw--loading-loading-class"),
               "an absent class attribute is what the controller's hasLoadingClass guard expects (R3)"
      end

      def test_loading_class_is_rendered_when_given
        assert_equal "is-loading", presenter(loading_class: "is-loading").root_attrs["data-cw--loading-loading-class"]
      end

      # --- action wiring: every Turbo event this behaviour reacts to ----------------

      def test_root_wires_every_start_and_stop_event
        actions = presenter.root_attrs["data-action"].split(/\s+/)

        assert_includes actions, "turbo:submit-start->cw--loading#start"
        assert_includes actions, "turbo:before-fetch-request->cw--loading#start"
        assert_includes actions, "turbo:submit-end->cw--loading#stop"
        assert_includes actions, "turbo:frame-render->cw--loading#stop"
        assert_includes actions, "turbo:fetch-request-error->cw--loading#stop"
      end

      # --- caller overrides compose, never clobber -----------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--loading analytics", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_of_controller_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_class_survives
        attrs = presenter(class: "cw-widget").root_attrs
        assert_equal "cw-widget", attrs["class"]
      end

      def test_caller_action_is_unioned_with_ours_rather_than_replacing_it
        attrs = presenter(data: { action: "click->analytics#track" }).root_attrs
        tokens = attrs["data-action"].split(/\s+/)

        assert_includes tokens, "click->analytics#track"
        assert_includes tokens, "turbo:submit-start->cw--loading#start"
      end

      # --- context-freedom -------------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, presenter.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
