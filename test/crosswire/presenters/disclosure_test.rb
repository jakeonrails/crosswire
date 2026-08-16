# frozen_string_literal: true

require "test_helper"

module Crosswire
  module Presenters
    class DisclosureTest < Minitest::Test
      def presenter(**options)
        Disclosure.new(id: "faq-1", **options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--disclosure", Disclosure.identifier
      end

      # --- the accessibility contract lives here, not in the markup ------------------
      # These are the tests that make ejection safe: a consumer can restyle or replace
      # the partial entirely and these guarantees still hold.

      def test_trigger_is_a_real_button_with_expanded_state
        attrs = presenter.trigger_attrs
        assert_equal "button", attrs["type"]
        assert_equal "false", attrs["aria-expanded"]
      end

      def test_trigger_controls_the_panel_by_id
        p = presenter
        assert_equal p.panel_id, p.trigger_attrs["aria-controls"]
        assert_equal p.panel_id, p.panel_attrs["id"]
      end

      def test_open_state_is_rendered_server_side
        attrs = presenter(open: true).trigger_attrs
        assert_equal "true", attrs["aria-expanded"]
        assert_equal false, presenter(open: true).panel_attrs["hidden"]
      end

      def test_panel_is_hidden_when_closed
        assert_equal true, presenter.panel_attrs["hidden"]
      end

      def test_region_role_always_travels_with_an_accessible_name
        attrs = presenter(region: true).panel_attrs
        assert_equal "region", attrs["role"]
        assert_equal presenter.trigger_id, attrs["aria-labelledby"]
      end

      def test_region_is_opt_in
        refute presenter.panel_attrs.key?("role")
        refute presenter.panel_attrs.key?("aria-labelledby")
      end

      # --- Stimulus wiring -----------------------------------------------------------

      def test_root_declares_the_controller_and_state
        attrs = presenter(open: true).root_attrs
        assert_equal "cw--disclosure", attrs["data-controller"]
        assert_equal "true", attrs["data-cw--disclosure-open-value"]
      end

      def test_targets_are_namespaced_to_the_identifier
        assert_equal "trigger", presenter.trigger_attrs["data-cw--disclosure-target"]
        assert_equal "panel", presenter.panel_attrs["data-cw--disclosure-target"]
      end

      def test_actions_expand_to_the_full_identifier
        assert_equal "click->cw--disclosure#toggle", presenter.trigger_attrs["data-action"]
      end

      def test_open_class_is_omitted_when_not_given
        # Stimulus THROWS on `this.fooClass` when absent, so the controller guards with
        # hasOpenClass — but we must also not emit an empty attribute.
        refute presenter.root_attrs.key?("data-cw--disclosure-open-class")
      end

      def test_open_class_is_passed_through_when_given
        attrs = presenter(open_class: "is-open").root_attrs
        assert_equal "is-open", attrs["data-cw--disclosure-open-class"]
      end

      # --- caller overrides compose, never clobber -----------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--disclosure analytics", attrs["data-controller"]
      end

      def test_caller_action_is_added_not_replaced
        attrs = presenter.trigger_attrs(data: { action: "click->analytics#track" })
        assert_equal "click->cw--disclosure#toggle click->analytics#track", attrs["data-action"]
      end

      def test_caller_can_force_replacement_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_classes_survive
        attrs = presenter(class: "rounded shadow").root_attrs
        assert_equal "rounded shadow", attrs["class"]
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        # The whole suite proves this by not booting Rails, but assert it explicitly
        # so the constraint is visible as a requirement rather than an accident.
        assert_kind_of Hash, Disclosure.new(id: "x").root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
