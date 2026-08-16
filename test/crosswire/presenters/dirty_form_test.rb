# frozen_string_literal: true

# Required directly rather than through test_helper: sibling agents are wiring up
# lib/crosswire.rb and app/assets/javascripts/crosswire/index.js in parallel, and this
# suite must not depend on that being finished. `crosswire/presenters/dirty_form` pulls
# in its own dependency (`crosswire/presenter`, which pulls in `crosswire/attributes`),
# so this is a complete, self-contained load path — and, like test_helper.rb, it proves
# the presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/dirty_form"
require "minitest/autorun"

module Crosswire
  module Presenters
    class DirtyFormTest < Minitest::Test
      def presenter(**options)
        DirtyForm.new(**options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--dirty-form", DirtyForm.identifier
      end

      # --- Stimulus wiring on the root -------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--dirty-form", presenter.root_attrs["data-controller"]
      end

      def test_root_declares_the_guard_value
        assert_equal "false", presenter(guard: false).root_attrs["data-cw--dirty-form-guard-value"]
      end

      def test_guard_defaults_to_true
        assert_equal "true", presenter.root_attrs["data-cw--dirty-form-guard-value"]
      end

      def test_root_wires_input_and_change_to_check
        assert_equal "input->cw--dirty-form#check change->cw--dirty-form#check",
                     presenter.root_attrs["data-action"]
      end

      # --- dirty_class: optional, guarded per R3 ----------------------------------------

      def test_dirty_class_is_omitted_when_not_given
        refute presenter.root_attrs.key?("data-cw--dirty-form-dirty-class")
      end

      def test_dirty_class_is_passed_through_when_given
        attrs = presenter(dirty_class: "is-dirty").root_attrs
        assert_equal "is-dirty", attrs["data-cw--dirty-form-dirty-class"]
      end

      # --- field_attrs -------------------------------------------------------------------

      def test_field_target
        assert_equal "field", presenter.field_attrs["data-cw--dirty-form-target"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--dirty-form analytics", attrs["data-controller"]
      end

      def test_caller_action_is_added_not_replaced
        attrs = presenter(data: { action: "turbo:submit-start->analytics#track" }).root_attrs
        assert_equal "input->cw--dirty-form#check change->cw--dirty-form#check turbo:submit-start->analytics#track",
                     attrs["data-action"]
      end

      def test_caller_can_force_replacement_of_controller_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_of_action_with_bang
        attrs = presenter(data: { "action!" => "submit->mine#only" }).root_attrs
        assert_equal "submit->mine#only", attrs["data-action"]
      end

      def test_caller_classes_survive
        attrs = presenter(class: "post-form").root_attrs
        assert_equal "post-form", attrs["class"]
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, DirtyForm.new.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
