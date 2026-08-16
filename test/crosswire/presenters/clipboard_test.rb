# frozen_string_literal: true

require "test_helper"

# lib/crosswire.rb is being wired up by a sibling change; require the presenter
# directly so this suite does not depend on that ordering.
require "crosswire/presenters/clipboard"

module Crosswire
  module Presenters
    class ClipboardTest < Minitest::Test
      def presenter(**options)
        Clipboard.new(**options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--clipboard", Clipboard.identifier
      end

      # --- defaults --------------------------------------------------------------------

      def test_success_duration_defaults_to_2000
        # Numbers pass through as-is (Crosswire::Presenter#serialize_value only
        # stringifies booleans/hashes/arrays) — the renderer stringifies at render
        # time, same as any other numeric HTML attribute.
        assert_equal 2000, presenter.root_attrs["data-cw--clipboard-success-duration-value"]
      end

      def test_text_is_omitted_when_not_given
        refute presenter.root_attrs.key?("data-cw--clipboard-text-value")
      end

      def test_text_is_passed_through_when_given
        attrs = presenter(text: "https://example.com").root_attrs
        assert_equal "https://example.com", attrs["data-cw--clipboard-text-value"]
      end

      def test_success_duration_is_configurable
        attrs = presenter(success_duration: 1500).root_attrs
        assert_equal 1500, attrs["data-cw--clipboard-success-duration-value"]
      end

      # --- the accessibility contract lives here, not in the markup ------------------

      def test_status_target_is_a_polite_live_region
        attrs = presenter.status_attrs
        assert_equal "status", attrs["role"]
        assert_equal "polite", attrs["aria-live"]
        assert_equal "true", attrs["aria-atomic"]
      end

      def test_button_is_a_real_button
        assert_equal "button", presenter.button_attrs["type"]
      end

      # --- success class lives on the root, never the button -------------------------
      # Stimulus's Classes API resolves data-*-class attributes against the
      # controller's own element, never against a target's, so it MUST be emitted in
      # root_attrs even though the controller may apply it to the button target.

      def test_success_class_is_omitted_when_not_given
        refute presenter.root_attrs.key?("data-cw--clipboard-success-class")
      end

      def test_success_class_lives_on_root_not_button
        attrs = presenter(success_class: "is-copied").root_attrs
        assert_equal "is-copied", attrs["data-cw--clipboard-success-class"]
        refute presenter(success_class: "is-copied").button_attrs.key?("data-cw--clipboard-success-class")
      end

      # --- Stimulus wiring -----------------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--clipboard", presenter.root_attrs["data-controller"]
      end

      def test_targets_are_namespaced_to_the_identifier
        assert_equal "source", presenter.source_attrs["data-cw--clipboard-target"]
        assert_equal "button", presenter.button_attrs["data-cw--clipboard-target"]
        assert_equal "status", presenter.status_attrs["data-cw--clipboard-target"]
      end

      def test_button_action_expands_to_the_full_identifier
        assert_equal "click->cw--clipboard#copy", presenter.button_attrs["data-action"]
      end

      # --- caller overrides compose, never clobber -----------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--clipboard analytics", attrs["data-controller"]
      end

      def test_caller_action_is_added_not_replaced
        attrs = presenter.button_attrs(data: { action: "click->analytics#track" })
        assert_equal "click->cw--clipboard#copy click->analytics#track", attrs["data-action"]
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
        assert_kind_of Hash, Clipboard.new.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
