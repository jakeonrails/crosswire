# frozen_string_literal: true

# Required directly rather than through test_helper: sibling agents are wiring up
# lib/crosswire.rb and app/assets/javascripts/crosswire/index.js in parallel, and this
# suite must not depend on that being finished. `crosswire/presenters/reveal` pulls in
# its own dependency (`crosswire/presenter`, which pulls in `crosswire/attributes`), so
# this is a complete, self-contained load path — and, like test_helper.rb, it proves the
# presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/reveal"
require "minitest/autorun"

module Crosswire
  module Presenters
    class RevealTest < Minitest::Test
      def presenter(**options)
        Reveal.new(**options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--reveal", Reveal.identifier
      end

      # --- Stimulus wiring on the root -------------------------------------------------

      def test_root_declares_the_controller_and_state
        attrs = presenter(revealed: true).root_attrs
        assert_equal "cw--reveal", attrs["data-controller"]
        assert_equal "true", attrs["data-cw--reveal-revealed-value"]
      end

      def test_revealed_defaults_to_false
        assert_equal "false", presenter.root_attrs["data-cw--reveal-revealed-value"]
      end

      # --- the accessibility contract lives here, not in the markup ------------------

      def test_input_type_is_password_when_not_revealed
        assert_equal "password", presenter.input_attrs["type"]
      end

      def test_input_type_is_text_when_revealed_server_side
        assert_equal "text", presenter(revealed: true).input_attrs["type"]
      end

      def test_trigger_is_a_real_button_with_aria_pressed
        attrs = presenter.trigger_attrs
        assert_equal "button", attrs["type"]
        assert_equal "false", attrs["aria-pressed"]
      end

      def test_trigger_aria_pressed_reflects_initial_revealed_state
        assert_equal "true", presenter(revealed: true).trigger_attrs["aria-pressed"]
      end

      def test_targets_are_namespaced_to_the_identifier
        assert_equal "input", presenter.input_attrs["data-cw--reveal-target"]
        assert_equal "trigger", presenter.trigger_attrs["data-cw--reveal-target"]
      end

      def test_trigger_action_expands_to_the_full_identifier
        assert_equal "click->cw--reveal#toggle", presenter.trigger_attrs["data-action"]
      end

      # --- revealed_class: optional, guarded per R3 -------------------------------------

      def test_revealed_class_is_omitted_when_not_given
        refute presenter.root_attrs.key?("data-cw--reveal-revealed-class")
      end

      def test_revealed_class_is_passed_through_when_given
        attrs = presenter(revealed_class: "is-revealed").root_attrs
        assert_equal "is-revealed", attrs["data-cw--reveal-revealed-class"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--reveal analytics", attrs["data-controller"]
      end

      def test_caller_action_on_trigger_is_added_not_replaced
        attrs = presenter.trigger_attrs(data: { action: "click->analytics#track" })
        assert_equal "click->cw--reveal#toggle click->analytics#track", attrs["data-action"]
      end

      def test_caller_can_force_replacement_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_classes_survive_on_root
        attrs = presenter(class: "field").root_attrs
        assert_equal "field", attrs["class"]
      end

      def test_caller_overrides_on_input_win_last
        attrs = presenter.input_attrs(autocomplete: "new-password")
        assert_equal "new-password", attrs["autocomplete"]
        assert_equal "password", attrs["type"]
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, Reveal.new.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
