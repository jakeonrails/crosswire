# frozen_string_literal: true

# Required directly rather than through test_helper: sibling agents are wiring up
# lib/crosswire.rb and app/assets/javascripts/crosswire/index.js in parallel, and this
# suite must not depend on that being finished. `crosswire/presenters/selection` pulls
# in its own dependency (`crosswire/presenter`, which pulls in `crosswire/attributes`),
# so this is a complete, self-contained load path — and, like test_helper.rb, it proves
# the presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/selection"
require "minitest/autorun"

module Crosswire
  module Presenters
    class SelectionTest < Minitest::Test
      def presenter(**options)
        Selection.new(**options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--selection", Selection.identifier
      end

      # --- Stimulus wiring on the root -------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--selection", presenter.root_attrs["data-controller"]
      end

      def test_root_declares_no_values
        attrs = presenter.root_attrs
        refute attrs.keys.any? { |k| k.end_with?("-value") }
      end

      # --- all_attrs -------------------------------------------------------------------

      def test_all_target_is_namespaced_to_the_identifier
        assert_equal "all", presenter.all_attrs["data-cw--selection-target"]
      end

      def test_all_action_expands_to_toggle_all
        assert_equal "change->cw--selection#toggleAll", presenter.all_attrs["data-action"]
      end

      # --- item_attrs --------------------------------------------------------------------

      def test_item_target_is_namespaced_to_the_identifier
        assert_equal "item", presenter.item_attrs["data-cw--selection-target"]
      end

      def test_item_action_expands_to_refresh
        assert_equal "change->cw--selection#refresh", presenter.item_attrs["data-action"]
      end

      # --- count_attrs: the live-region contract ----------------------------------------

      def test_count_target_is_namespaced_to_the_identifier
        assert_equal "count", presenter.count_attrs["data-cw--selection-target"]
      end

      def test_count_is_a_polite_atomic_live_region
        attrs = presenter.count_attrs
        assert_equal "polite", attrs["aria-live"]
        assert_equal "true", attrs["aria-atomic"]
      end

      # --- action_attrs: disabled by default, both mechanisms ---------------------------

      def test_action_target_is_namespaced_to_the_identifier
        assert_equal "action", presenter.action_attrs["data-cw--selection-target"]
      end

      def test_action_is_disabled_by_default
        attrs = presenter.action_attrs
        assert_equal true, attrs["disabled"]
        assert_equal "true", attrs["aria-disabled"]
      end

      def test_action_disabled_false_is_honoured
        attrs = presenter.action_attrs(disabled: false)
        assert_equal false, attrs["disabled"]
        assert_equal "false", attrs["aria-disabled"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--selection analytics", attrs["data-controller"]
      end

      def test_caller_class_survives
        attrs = presenter(class: "cw-selection").root_attrs
        assert_equal "cw-selection", attrs["class"]
      end

      def test_caller_can_force_replacement_of_controller_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_item_extra_attrs_are_merged
        attrs = presenter.item_attrs(aria: { label: "Select row" })
        assert_equal "Select row", attrs["aria-label"]
        assert_equal "item", attrs["data-cw--selection-target"]
      end

      def test_action_extra_attrs_compose_with_disabled
        attrs = presenter.action_attrs(class: "btn")
        assert_equal "btn", attrs["class"]
        assert_equal true, attrs["disabled"]
      end

      # --- there is no partial: this is a behaviour with no owned markup ---------------

      def test_has_no_trigger_or_panel_methods
        refute presenter.respond_to?(:trigger_attrs)
        refute presenter.respond_to?(:panel_attrs)
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, Selection.new.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
