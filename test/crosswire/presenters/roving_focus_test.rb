# frozen_string_literal: true

require "test_helper"

# lib/crosswire.rb is being wired up by a sibling change; require the presenter
# directly so this suite does not depend on that ordering.
require "crosswire/presenters/roving_focus"

module Crosswire
  module Presenters
    class RovingFocusTest < Minitest::Test
      def presenter(**options)
        RovingFocus.new(**options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--roving-focus", RovingFocus.identifier
      end

      # --- defaults --------------------------------------------------------------------

      def test_orientation_defaults_to_vertical
        assert_equal "vertical", presenter.orientation
      end

      def test_wrap_defaults_to_true
        assert_equal true, presenter.wrap
      end

      def test_typeahead_defaults_to_false
        assert_equal false, presenter.typeahead
      end

      # --- state rendered server-side --------------------------------------------------

      def test_values_are_rendered_server_side
        attrs = presenter(orientation: "horizontal", wrap: false, typeahead: true).root_attrs
        assert_equal "horizontal", attrs["data-cw--roving-focus-orientation-value"]
        assert_equal "false", attrs["data-cw--roving-focus-wrap-value"]
        assert_equal "true", attrs["data-cw--roving-focus-typeahead-value"]
      end

      # --- Stimulus wiring -----------------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--roving-focus", presenter.root_attrs["data-controller"]
      end

      # R8a — six named keys plus arbitrary typeahead characters cannot be expressed
      # as `data-action` filters at all, so there is exactly one generic action and
      # the controller does its own `switch` on event.key.
      def test_navigate_is_wired_as_a_single_unfiltered_action
        assert_equal "keydown->cw--roving-focus#navigate", presenter.root_attrs["data-action"]
      end

      # --- items: target + roving tabindex, rendered server-side ---------------------

      def test_item_target_is_namespaced_to_the_identifier
        assert_equal "item", presenter.item_attrs["data-cw--roving-focus-target"]
      end

      def test_current_item_renders_tabindex_zero
        assert_equal "0", presenter.item_attrs(current: true)["tabindex"]
      end

      def test_non_current_item_renders_tabindex_negative_one
        assert_equal "-1", presenter.item_attrs(current: false)["tabindex"]
      end

      def test_current_defaults_to_false
        assert_equal "-1", presenter.item_attrs["tabindex"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--roving-focus analytics", attrs["data-controller"]
      end

      def test_caller_action_is_added_not_replaced
        attrs = presenter(data: { action: "click->analytics#track" }).root_attrs
        assert_equal "keydown->cw--roving-focus#navigate click->analytics#track", attrs["data-action"]
      end

      def test_caller_can_force_replacement_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_classes_survive
        attrs = presenter(class: "toolbar").root_attrs
        assert_equal "toolbar", attrs["class"]
      end

      def test_item_extra_attrs_are_merged
        attrs = presenter.item_attrs(current: true, class: "item")
        assert_equal "item", attrs["class"]
        assert_equal "0", attrs["tabindex"]
      end

      # --- there is no partial: this is a root+item-only behaviour --------------------

      def test_has_no_panel_or_trigger_methods
        refute presenter.respond_to?(:trigger_attrs)
        refute presenter.respond_to?(:panel_attrs)
      end

      # --- context-freedom -------------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, RovingFocus.new.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
