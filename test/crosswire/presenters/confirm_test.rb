# frozen_string_literal: true

require "test_helper"

# Not required by lib/crosswire.rb yet — COMPONENTS registration is being wired up
# separately (see docs/COMPONENT_CONTRACT.md and the task instructions for this
# component pair). Required directly here so the presenter is unit-testable on its own.
require "crosswire/presenters/confirm"

module Crosswire
  module Presenters
    class ConfirmTest < Minitest::Test
      def presenter(**options)
        Confirm.new(**options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--confirm", Confirm.identifier
      end

      # --- the accessibility contract lives here, not in the markup ------------------

      def test_dialog_is_an_alertdialog
        assert_equal "alertdialog", presenter.dialog_attrs["role"]
      end

      def test_dialog_is_labelled_and_described_by_id
        p = presenter
        attrs = p.dialog_attrs
        assert_equal p.title_id, attrs["aria-labelledby"]
        assert_equal p.body_id, attrs["aria-describedby"]
      end

      def test_title_and_body_ids_match_what_the_dialog_points_to
        p = presenter
        assert_equal p.title_id, p.title_attrs["id"]
        assert_equal p.body_id, p.body_attrs["id"]
      end

      def test_buttons_are_real_buttons
        p = presenter
        assert_equal "button", p.confirm_attrs["type"]
        assert_equal "button", p.cancel_attrs["type"]
      end

      # --- default text and overrides -------------------------------------------------

      def test_defaults
        p = presenter
        assert_equal "Are you sure?", p.title
        assert_equal "", p.body
        assert_equal "Confirm", p.confirm_label
        assert_equal "Cancel", p.cancel_label
        refute p.destructive
      end

      def test_custom_text
        p = presenter(title: "Delete file?", body: "This cannot be undone.",
                       confirm_label: "Delete", cancel_label: "Keep it")
        assert_equal "Delete file?", p.title
        assert_equal "This cannot be undone.", p.body
        assert_equal "Delete", p.confirm_label
        assert_equal "Keep it", p.cancel_label
      end

      # --- Stimulus wiring -------------------------------------------------------------

      def test_dialog_declares_the_controller_and_state
        attrs = presenter(title: "Delete?", destructive: true).dialog_attrs
        assert_equal "cw--confirm", attrs["data-controller"]
        assert_equal "Delete?", attrs["data-cw--confirm-title-value"]
        assert_equal "true", attrs["data-cw--confirm-destructive-value"]
      end

      def test_targets_are_namespaced_to_the_identifier
        assert_equal "dialog", presenter.dialog_attrs["data-cw--confirm-target"]
        assert_equal "title", presenter.title_attrs["data-cw--confirm-target"]
        assert_equal "body", presenter.body_attrs["data-cw--confirm-target"]
        assert_equal "confirmButton", presenter.confirm_attrs["data-cw--confirm-target"]
        assert_equal "cancelButton", presenter.cancel_attrs["data-cw--confirm-target"]
      end

      def test_actions_expand_to_the_full_identifier
        assert_equal "click->cw--confirm#confirm", presenter.confirm_attrs["data-action"]
        assert_equal "click->cw--confirm#cancel", presenter.cancel_attrs["data-action"]
      end

      def test_dialog_wires_native_cancel_and_close_events
        actions = presenter.dialog_attrs["data-action"]
        assert_includes actions, "cancel->cw--confirm#cancel"
        assert_includes actions, "close->cw--confirm#closed"
      end

      # --- destructive: default false, opt-in class -----------------------------------

      def test_destructive_class_is_omitted_when_not_given
        # Stimulus THROWS on this.fooClass when absent, so the controller guards with
        # hasDestructiveClass — but we must also not emit an empty attribute.
        refute presenter.dialog_attrs.key?("data-cw--confirm-destructive-class")
      end

      def test_destructive_class_is_passed_through_when_given
        attrs = presenter(destructive_class: "is-destructive").dialog_attrs
        assert_equal "is-destructive", attrs["data-cw--confirm-destructive-class"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).dialog_attrs
        assert_equal "cw--confirm analytics", attrs["data-controller"]
      end

      def test_caller_action_is_added_not_replaced
        attrs = presenter.confirm_attrs(data: { action: "click->analytics#track" })
        assert_equal "click->cw--confirm#confirm click->analytics#track", attrs["data-action"]
      end

      def test_caller_can_force_replacement_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).dialog_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_classes_survive
        attrs = presenter(class: "rounded shadow").dialog_attrs
        assert_equal "rounded shadow", attrs["class"]
      end

      # --- context-freedom ---------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, Confirm.new.dialog_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
