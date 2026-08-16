# frozen_string_literal: true

require "test_helper"
require "crosswire/presenters/dialog"

module Crosswire
  module Presenters
    class DialogTest < Minitest::Test
      def presenter(**options)
        Dialog.new(id: "confirm", **options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--dialog", Dialog.identifier
      end

      # --- the accessibility contract lives here, not in the markup ------------------

      def test_trigger_is_a_real_button_that_announces_a_dialog
        attrs = presenter.trigger_attrs
        assert_equal "button", attrs["type"]
        assert_equal "dialog", attrs["aria-haspopup"]
      end

      def test_trigger_controls_the_panel_by_id
        p = presenter
        assert_equal p.id, p.trigger_attrs["aria-controls"]
        assert_equal p.id, p.panel_attrs["id"]
      end

      def test_close_button_is_a_real_button_with_an_accessible_name
        attrs = presenter.close_attrs
        assert_equal "button", attrs["type"]
        assert_equal "Close", attrs["aria-label"]
      end

      def test_title_labels_the_panel_automatically
        p = presenter(title: "Delete this project?")
        assert_equal p.title_id, p.panel_attrs["aria-labelledby"]
        assert_equal p.title_id, p.title_attrs["id"]
      end

      def test_no_title_means_no_aria_labelledby
        refute presenter.panel_attrs.key?("aria-labelledby")
      end

      def test_explicit_labelled_by_overrides_the_title_derived_id
        p = presenter(title: "Ignored", labelled_by: "my-own-heading")
        assert_equal "my-own-heading", p.panel_attrs["aria-labelledby"]
      end

      def test_described_by_is_opt_in
        refute presenter.panel_attrs.key?("aria-describedby")
        assert_equal "extra-copy", presenter(described_by: "extra-copy").panel_attrs["aria-describedby"]
      end

      # --- state rendered server-side --------------------------------------------------

      def test_open_state_is_rendered_server_side
        assert_equal false, presenter.panel_attrs["open"]
        assert_equal true, presenter(open: true).panel_attrs["open"]
      end

      def test_root_declares_the_controller_and_state
        attrs = presenter(open: true).root_attrs
        assert_equal "cw--dialog", attrs["data-controller"]
        assert_equal "true", attrs["data-cw--dialog-open-value"]
      end

      def test_modal_defaults_to_true
        assert_equal "true", presenter.root_attrs["data-cw--dialog-modal-value"]
      end

      def test_modal_is_configurable
        assert_equal "false", presenter(modal: false).root_attrs["data-cw--dialog-modal-value"]
      end

      def test_dismissable_defaults_to_true
        assert_equal "true", presenter.root_attrs["data-cw--dialog-dismissable-value"]
      end

      def test_dismissable_is_configurable
        assert_equal "false", presenter(dismissable: false).root_attrs["data-cw--dialog-dismissable-value"]
      end

      # --- Stimulus wiring -----------------------------------------------------------

      def test_targets_are_namespaced_to_the_identifier
        assert_equal "trigger", presenter.trigger_attrs["data-cw--dialog-target"]
        assert_equal "panel", presenter.panel_attrs["data-cw--dialog-target"]
      end

      def test_trigger_action_expands_to_the_full_identifier
        assert_equal "click->cw--dialog#open", presenter.trigger_attrs["data-action"]
      end

      def test_close_action_expands_to_the_full_identifier
        assert_equal "click->cw--dialog#close", presenter.close_attrs["data-action"]
      end

      def test_panel_wires_native_events_and_turbo_hooks
        actions = presenter.panel_attrs["data-action"]
        assert_includes actions, "close->cw--dialog#syncClosed"
        assert_includes actions, "cancel->cw--dialog#cancel"
        assert_includes actions, "click->cw--dialog#backdropClick"
        assert_includes actions, "turbo:before-morph-element->cw--dialog#beforeMorph"
        assert_includes actions, "turbo:before-cache->cw--dialog#reset"
      end

      # --- caller overrides compose, never clobber -----------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--dialog analytics", attrs["data-controller"]
      end

      def test_caller_action_is_added_not_replaced
        attrs = presenter.trigger_attrs(data: { action: "click->analytics#track" })
        assert_equal "click->cw--dialog#open click->analytics#track", attrs["data-action"]
      end

      def test_caller_can_force_replacement_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_classes_survive
        attrs = presenter(class: "rounded shadow").root_attrs
        assert_equal "rounded shadow", attrs["class"]
      end

      def test_panel_overrides_compose
        attrs = presenter.panel_attrs(class: "max-w-lg")
        assert_equal "max-w-lg", attrs["class"]
        assert_equal "panel", attrs["data-cw--dialog-target"]
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, Dialog.new(id: "x").root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
