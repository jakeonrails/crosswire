# frozen_string_literal: true

require "test_helper"
require "crosswire/presenters/menu"

module Crosswire
  module Presenters
    class MenuTest < Minitest::Test
      def presenter(**options)
        Menu.new(id: "actions", **options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--menu", Menu.identifier
      end

      # --- id relationships wired both ways --------------------------------------------

      def test_button_id_is_derived_from_the_panel_id
        assert_equal "actions-trigger", presenter.button_id
      end

      def test_menu_id_is_the_given_id
        assert_equal "actions", presenter.menu_id
      end

      def test_button_popovertarget_matches_the_panel_id
        p = presenter
        assert_equal p.menu_id, p.button_attrs["popovertarget"]
        assert_equal p.menu_id, p.menu_attrs["id"]
      end

      def test_button_id_matches_the_rendered_button_attrs
        p = presenter
        assert_equal p.button_id, p.button_attrs["id"]
      end

      # --- composition: root carries cw--menu alone ------------------------------------

      def test_root_carries_only_cw_menu
        assert_equal "cw--menu", presenter.root_attrs["data-controller"]
      end

      def test_root_has_no_stimulus_values
        # 0.7/0.9 — cw--menu holds no Stimulus values at all; state lives in the browser.
        refute presenter.root_attrs.keys.any? { |k| k.end_with?("-value") }
      end

      # --- composition: panel stacks popover + roving-focus (R5a/R5b) -----------------

      def test_panel_stacks_popover_and_roving_focus_controllers
        assert_equal "cw--popover cw--roving-focus", presenter.menu_attrs["data-controller"]
      end

      def test_panel_never_carries_cw_menu_itself
        refute_includes presenter.menu_attrs["data-controller"].split, "cw--menu"
      end

      def test_panel_is_a_native_auto_popover
        assert_equal "auto", presenter.menu_attrs["popover"]
      end

      def test_roving_focus_values_are_vertical_wrapping_with_typeahead
        attrs = presenter.menu_attrs
        assert_equal "vertical", attrs["data-cw--roving-focus-orientation-value"]
        assert_equal "true", attrs["data-cw--roving-focus-wrap-value"]
        assert_equal "true", attrs["data-cw--roving-focus-typeahead-value"]
      end

      # --- accessibility contract -----------------------------------------------------

      def test_menu_has_the_menu_role
        assert_equal "menu", presenter.menu_attrs["role"]
      end

      def test_button_has_aria_haspopup_menu
        assert_equal "menu", presenter.button_attrs["aria-haspopup"]
      end

      def test_button_is_a_real_button
        assert_equal "button", presenter.button_attrs["type"]
      end

      def test_button_never_carries_aria_expanded
        # Deliberate: the UA reflects aria-expanded itself via the popovertarget
        # invoker mapping (see Crosswire::Presenters::Popover). A second, JS-driven
        # copy here could only desync from it.
        refute presenter.button_attrs.key?("aria-expanded")
      end

      def test_aria_labelledby_defaults_to_the_button_id
        p = presenter
        assert_equal p.button_id, p.menu_attrs["aria-labelledby"]
      end

      def test_explicit_labelled_by_overrides_the_button_default
        attrs = presenter(labelled_by: "my-own-label").menu_attrs
        assert_equal "my-own-label", attrs["aria-labelledby"]
      end

      def test_label_is_omitted_by_default
        refute presenter.menu_attrs.key?("aria-label")
      end

      def test_label_renders_aria_label_when_given
        assert_equal "Row actions", presenter(label: "Row actions").menu_attrs["aria-label"]
      end

      # --- keyboard wiring --------------------------------------------------------------

      def test_button_wires_arrow_down_to_open_first_and_arrow_up_to_open_last
        actions = presenter.button_attrs["data-action"].split
        assert_includes actions, "keydown.down->cw--menu#openFirst"
        assert_includes actions, "keydown.up->cw--menu#openLast"
      end

      def test_button_wires_no_enter_action
        # Native click via popovertarget already opens on Enter/Space; wiring Enter
        # here would double-open.
        refute_includes presenter.button_attrs["data-action"], "keydown.enter"
      end

      def test_panel_wires_both_tab_descriptors
        actions = presenter.menu_attrs["data-action"].split
        assert_includes actions, "keydown.tab->cw--menu#tabOut"
        assert_includes actions, "keydown.shift+tab->cw--menu#tabOut",
                        "a bare keydown.tab filter silently drops Shift+Tab (R8a)"
      end

      def test_panel_reacts_to_its_own_native_toggle_event_from_both_stacked_controllers
        actions = presenter.menu_attrs["data-action"].split
        assert_includes actions, "toggle->cw--popover#toggled"
        assert_includes actions, "toggle->cw--menu#toggled"
      end

      def test_item_wires_click_to_select_and_space_to_activate
        actions = presenter.item_attrs["data-action"].split
        assert_includes actions, "click->cw--menu#select"
        assert_includes actions, "keydown.space->cw--menu#activate"
      end

      # --- items ------------------------------------------------------------------------

      def test_item_defaults_to_the_menuitem_role
        assert_equal "menuitem", presenter.item_attrs["role"]
      end

      def test_item_is_both_a_roving_focus_item_and_a_menu_item
        attrs = presenter.item_attrs
        assert_equal "item", attrs["data-cw--roving-focus-target"]
        assert_equal "item", attrs["data-cw--menu-target"]
      end

      def test_item_current_renders_tabindex_zero_others_negative_one
        assert_equal "0", presenter.item_attrs(current: true)["tabindex"]
        assert_equal "-1", presenter.item_attrs(current: false)["tabindex"]
        assert_equal "-1", presenter.item_attrs["tabindex"]
      end

      def test_plain_menuitem_carries_no_aria_checked
        refute presenter.item_attrs["aria-checked"]
      end

      def test_menuitemcheckbox_checked_true_renders_aria_checked_true
        attrs = presenter.item_attrs(role: "menuitemcheckbox", checked: true)
        assert_equal "true", attrs["aria-checked"]
      end

      def test_menuitemcheckbox_checked_false_renders_aria_checked_false
        attrs = presenter.item_attrs(role: "menuitemcheckbox", checked: false)
        assert_equal "false", attrs["aria-checked"]
      end

      def test_menuitemradio_checked_true_renders_aria_checked_true
        attrs = presenter.item_attrs(role: "menuitemradio", checked: true)
        assert_equal "true", attrs["aria-checked"]
      end

      def test_menuitemcheckbox_without_checked_raises
        assert_raises(ArgumentError) { presenter.item_attrs(role: "menuitemcheckbox") }
      end

      def test_menuitemradio_without_checked_raises
        assert_raises(ArgumentError) { presenter.item_attrs(role: "menuitemradio") }
      end

      def test_plain_menuitem_without_checked_does_not_raise
        presenter.item_attrs(role: "menuitem")
      end

      def test_item_value_is_rendered_as_a_data_param
        attrs = presenter.item_attrs(value: "duplicate")
        assert_equal "duplicate", attrs["data-cw--menu-value-param"]
      end

      def test_item_value_omitted_when_not_given
        refute presenter.item_attrs.key?("data-cw--menu-value-param")
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_on_root_is_added_not_replaced
        attrs = presenter(data: {controller: "analytics"}).root_attrs
        assert_equal "cw--menu analytics", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_with_bang_on_root
        attrs = presenter(data: {"controller!" => "mine-only"}).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_button_extra_attrs_are_merged
        attrs = presenter.button_attrs(class: "btn")
        assert_equal "btn", attrs["class"]
      end

      def test_menu_extra_attrs_are_merged
        attrs = presenter.menu_attrs(class: "dropdown")
        assert_equal "dropdown", attrs["class"]
      end

      def test_item_extra_attrs_are_merged
        attrs = presenter.item_attrs(class: "item")
        assert_equal "item", attrs["class"]
      end

      # --- placement passthrough to the internal Popover -------------------------------

      def test_placement_offset_and_strategy_pass_through_to_the_popover
        attrs = presenter(placement: "top-end", offset: 12, strategy: "js").menu_attrs
        assert_equal "top-end", attrs["data-cw--popover-placement-value"]
        assert_equal 12, attrs["data-cw--popover-offset-value"]
        assert_equal "js", attrs["data-cw--popover-strategy-value"]
      end

      # --- context-freedom -------------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, presenter.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
