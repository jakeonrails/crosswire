# frozen_string_literal: true

# Required directly rather than through test_helper: sibling agents are wiring up
# lib/crosswire.rb and app/assets/javascripts/crosswire/index.js in parallel, and this
# suite must not depend on that being finished. `crosswire/presenters/dismiss` pulls in
# its own dependency (`crosswire/presenter`, which pulls in `crosswire/attributes`), so
# this is a complete, self-contained load path — and, like test_helper.rb, it proves the
# presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/dismiss"
require "minitest/autorun"

module Crosswire
  module Presenters
    class DismissTest < Minitest::Test
      def presenter(**options)
        Dismiss.new(**options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--dismiss", Dismiss.identifier
      end

      # --- Stimulus wiring on the root -------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--dismiss", presenter.root_attrs["data-controller"]
      end

      def test_root_declares_remove_and_selector_values
        attrs = presenter(remove: false, selector: ".flash").root_attrs
        assert_equal "false", attrs["data-cw--dismiss-remove-value"]
        assert_equal ".flash", attrs["data-cw--dismiss-selector-value"]
      end

      def test_remove_defaults_to_true
        assert_equal "true", presenter.root_attrs["data-cw--dismiss-remove-value"]
      end

      def test_selector_nil_is_omitted_entirely_rather_than_emitted_empty
        attrs = presenter(selector: nil).root_attrs
        refute attrs.key?("data-cw--dismiss-selector-value")
      end

      # --- escape: the pairing is the point -------------------------------------------
      # Escape must reach the container even when focus is inside it, so the keydown
      # action and the tabindex that makes the container focusable are one guarantee,
      # tested together rather than separately.

      def test_escape_adds_the_keydown_action_and_makes_the_root_focusable
        attrs = presenter(escape: true).root_attrs
        assert_equal "keydown.esc->cw--dismiss#dismiss", attrs["data-action"]
        assert_equal "-1", attrs["tabindex"]
      end

      def test_escape_false_by_default_adds_neither
        attrs = presenter.root_attrs
        refute attrs.key?("data-action")
        refute attrs.key?("tabindex")
      end

      # --- trigger_attrs: the a11y contract for the button ------------------------------

      def test_trigger_is_a_real_button
        assert_equal "button", presenter.trigger_attrs["type"]
      end

      def test_trigger_action_expands_to_the_full_identifier
        assert_equal "click->cw--dismiss#dismiss", presenter.trigger_attrs["data-action"]
      end

      def test_trigger_aria_label_comes_from_the_label_option
        attrs = presenter(label: "Close alert").trigger_attrs
        assert_equal "Close alert", attrs["aria-label"]
      end

      def test_trigger_aria_label_has_a_sensible_default
        assert_equal "Dismiss", presenter.trigger_attrs["aria-label"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--dismiss analytics", attrs["data-controller"]
      end

      def test_caller_action_is_added_not_replaced_alongside_escape
        attrs = presenter(escape: true, data: { action: "click->analytics#track" }).root_attrs
        assert_equal "keydown.esc->cw--dismiss#dismiss click->analytics#track", attrs["data-action"]
      end

      def test_caller_class_survives
        attrs = presenter(class: "cw-alert").root_attrs
        assert_equal "cw-alert", attrs["class"]
      end

      def test_caller_can_force_replacement_of_controller_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_of_action_with_bang
        attrs = presenter(escape: true, data: { "action!" => "click->mine#only" }).root_attrs
        assert_equal "click->mine#only", attrs["data-action"]
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, Dismiss.new.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
