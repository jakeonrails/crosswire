# frozen_string_literal: true

require "test_helper"

# lib/crosswire.rb is being wired up by a sibling change; require the presenter
# directly so this suite does not depend on that ordering.
require "crosswire/presenters/popover"

module Crosswire
  module Presenters
    class PopoverTest < Minitest::Test
      def presenter(**options)
        Popover.new(id: "user-card-42", **options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--popover", Popover.identifier
      end

      # --- Rule 0: native popovertarget/popover is the entire wiring for the trigger --

      def test_trigger_is_a_real_button_wired_via_popovertarget
        attrs = presenter.trigger_attrs
        assert_equal "button", attrs["type"]
        assert_equal "user-card-42", attrs["popovertarget"]
      end

      def test_trigger_carries_no_stimulus_wiring_at_all
        # Native popovertarget needs no data-controller, no data-action, no
        # data-cw--popover-target — that is the entire point of Rule 0.
        attrs = presenter.trigger_attrs
        refute attrs.key?("data-controller")
        refute attrs.key?("data-action")
      end

      def test_panel_has_the_native_popover_attribute
        assert_equal "auto", presenter.panel_attrs["popover"]
      end

      def test_panel_id_matches_trigger_popovertarget
        p = presenter
        assert_equal p.id, p.panel_attrs["id"]
        assert_equal p.id, p.trigger_attrs["popovertarget"]
      end

      def test_no_aria_expanded_is_set_by_hand
        # The UA reflects this implicitly for popovertarget invokers; setting it
        # here would just be a second, JS-free-to-desync copy.
        refute presenter.trigger_attrs.key?("aria-expanded")
      end

      # --- CSS anchor positioning wiring, zero JS ---------------------------------------

      def test_trigger_and_panel_share_an_anchor_name
        trigger_style = presenter.trigger_attrs["style"]
        panel_style = presenter.panel_attrs["style"]

        assert_includes trigger_style, "anchor-name: --cw-popover-user-card-42"
        assert_includes panel_style, "position-anchor: --cw-popover-user-card-42"
      end

      # --- defaults --------------------------------------------------------------------

      def test_placement_defaults_to_bottom_start
        assert_equal "bottom-start", presenter.placement
      end

      def test_offset_defaults_to_8
        assert_equal 8, presenter.offset
      end

      def test_strategy_defaults_to_anchor
        assert_equal "anchor", presenter.strategy
      end

      # --- state rendered server-side --------------------------------------------------

      def test_values_are_rendered_server_side
        attrs = presenter(placement: "top-end", offset: 12, strategy: "js").panel_attrs
        assert_equal "top-end", attrs["data-cw--popover-placement-value"]
        # Numeric values pass through Presenter#serialize_value unchanged (only
        # Hash/Array/Boolean get special-cased there) — the final string coercion
        # is the renderer's job, same as every other numeric Stimulus value in
        # this codebase.
        assert_equal 12, attrs["data-cw--popover-offset-value"]
        assert_equal "js", attrs["data-cw--popover-strategy-value"]
      end

      def test_panel_carries_the_trigger_id_as_the_anchor_value
        assert_equal "user-card-42-trigger", presenter.panel_attrs["data-cw--popover-anchor-value"]
      end

      # --- Stimulus wiring lives on the panel only --------------------------------------

      def test_panel_declares_the_controller
        assert_equal "cw--popover", presenter.panel_attrs["data-controller"]
      end

      def test_panel_wires_the_native_toggle_event
        assert_equal "toggle->cw--popover#toggled", presenter.panel_attrs["data-action"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_on_panel_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).panel_attrs
        assert_equal "cw--popover analytics", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).panel_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_classes_survive_on_panel
        attrs = presenter(class: "shadow").panel_attrs
        assert_equal "shadow", attrs["class"]
      end

      def test_trigger_extra_attrs_are_merged
        attrs = presenter.trigger_attrs(class: "btn")
        assert_equal "btn", attrs["class"]
      end

      # --- context-freedom -------------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, presenter.panel_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
