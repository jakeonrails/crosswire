# frozen_string_literal: true

require "test_helper"

# lib/crosswire.rb is being wired up by a sibling change; require the presenter
# directly so this suite does not depend on that ordering.
require "crosswire/presenters/tabs"

module Crosswire
  module Presenters
    class TabsTest < Minitest::Test
      def presenter(**options)
        Tabs.new(id: "settings", selected: "profile", **options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--tabs", Tabs.identifier
      end

      # --- id relationships wired both ways --------------------------------------------

      def test_tab_and_panel_ids_are_namespaced_to_the_base_id
        assert_equal "settings-tab-profile", presenter.tab_id("profile")
        assert_equal "settings-panel-profile", presenter.panel_id("profile")
      end

      def test_tab_controls_the_panel_by_id
        p = presenter
        assert_equal p.panel_id("profile"), p.tab_attrs(tab_id: "profile")["aria-controls"]
        assert_equal p.panel_id("profile"), p.panel_attrs(tab_id: "profile")["id"]
      end

      def test_panel_is_labelled_by_its_tab
        p = presenter
        assert_equal p.tab_id("profile"), p.tab_attrs(tab_id: "profile")["id"]
        assert_equal p.tab_id("profile"), p.panel_attrs(tab_id: "profile")["aria-labelledby"]
      end

      # --- accessibility contract -----------------------------------------------------

      def test_tablist_has_the_tablist_role
        assert_equal "tablist", presenter.tablist_attrs["role"]
      end

      def test_tab_has_the_tab_role
        assert_equal "tab", presenter.tab_attrs(tab_id: "profile")["role"]
      end

      def test_panel_has_the_tabpanel_role
        assert_equal "tabpanel", presenter.panel_attrs(tab_id: "profile")["role"]
      end

      def test_panel_always_has_tabindex_zero
        assert_equal "0", presenter.panel_attrs(tab_id: "profile")["tabindex"]
        assert_equal "0", presenter.panel_attrs(tab_id: "billing")["tabindex"]
      end

      def test_selected_tab_has_aria_selected_true
        attrs = presenter(selected: "profile").tab_attrs(tab_id: "profile")
        assert_equal "true", attrs["aria-selected"]
      end

      def test_unselected_tab_has_aria_selected_false_not_missing
        # APG requires aria-selected present on EVERY tab, never simply absent for
        # the inactive ones.
        attrs = presenter(selected: "profile").tab_attrs(tab_id: "billing")
        assert_equal "false", attrs["aria-selected"]
        assert attrs.key?("aria-selected")
      end

      def test_selected_panel_is_not_hidden
        attrs = presenter(selected: "profile").panel_attrs(tab_id: "profile")
        assert_equal false, attrs["hidden"]
      end

      def test_unselected_panel_is_hidden
        attrs = presenter(selected: "profile").panel_attrs(tab_id: "billing")
        assert_equal true, attrs["hidden"]
      end

      def test_selected_accepts_symbol_or_integer_and_compares_via_to_s
        attrs = Tabs.new(id: "settings", selected: :profile).tab_attrs(tab_id: "profile")
        assert_equal "true", attrs["aria-selected"]

        attrs = Tabs.new(id: "settings", selected: 2).tab_attrs(tab_id: 2)
        assert_equal "true", attrs["aria-selected"]
      end

      # --- state rendered server-side --------------------------------------------------

      def test_activation_defaults_to_automatic_and_is_rendered_server_side
        assert_equal "automatic", presenter.tablist_attrs["data-cw--tabs-activation-value"]
      end

      def test_activation_manual_is_rendered_server_side
        attrs = presenter(activation: "manual").tablist_attrs
        assert_equal "manual", attrs["data-cw--tabs-activation-value"]
      end

      def test_param_is_omitted_when_not_given
        refute presenter.tablist_attrs.key?("data-cw--tabs-param-value")
      end

      def test_param_is_passed_through_when_given
        attrs = presenter(param: "tab").tablist_attrs
        assert_equal "tab", attrs["data-cw--tabs-param-value"]
      end

      # --- stacked-controller composition with roving-focus (R5a) ---------------------

      def test_tablist_stacks_roving_focus_and_tabs_controllers
        assert_equal "cw--roving-focus cw--tabs", presenter.tablist_attrs["data-controller"]
      end

      def test_tablist_is_horizontal_roving_focus
        assert_equal "horizontal", presenter.tablist_attrs["data-cw--roving-focus-orientation-value"]
      end

      def test_tablist_wires_roving_focus_navigate_and_the_moved_reaction
        attrs = presenter.tablist_attrs
        assert_equal(
          "keydown->cw--roving-focus#navigate cw--roving-focus:moved->cw--tabs#selectFromMove",
          attrs["data-action"]
        )
      end

      def test_every_tab_is_also_a_roving_focus_item
        attrs = presenter.tab_attrs(tab_id: "profile")
        assert_equal "item", attrs["data-cw--roving-focus-target"]
        assert_equal "tab", attrs["data-cw--tabs-target"]
      end

      def test_selected_tab_is_the_roving_focus_stop
        selected = presenter(selected: "profile").tab_attrs(tab_id: "profile")
        unselected = presenter(selected: "profile").tab_attrs(tab_id: "billing")
        assert_equal "0", selected["tabindex"]
        assert_equal "-1", unselected["tabindex"]
      end

      def test_tab_wires_click_and_enter_and_space
        attrs = presenter.tab_attrs(tab_id: "profile")
        assert_equal(
          "click->cw--tabs#select keydown.enter->cw--tabs#select keydown.space->cw--tabs#select",
          attrs["data-action"]
        )
      end

      def test_tab_carries_its_id_as_an_action_param
        attrs = presenter.tab_attrs(tab_id: "billing")
        assert_equal "billing", attrs["data-cw--tabs-id-param"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_on_tablist_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).tablist_attrs
        assert_equal "cw--roving-focus cw--tabs analytics", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).tablist_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_tab_extra_attrs_are_merged
        attrs = presenter.tab_attrs(tab_id: "profile", class: "tab")
        assert_equal "tab", attrs["class"]
      end

      def test_panel_extra_attrs_are_merged
        attrs = presenter.panel_attrs(tab_id: "profile", class: "panel")
        assert_equal "panel", attrs["class"]
      end

      # --- context-freedom -------------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, presenter.tablist_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
