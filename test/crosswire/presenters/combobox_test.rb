# frozen_string_literal: true

require "test_helper"
require "crosswire/presenters/combobox"

module Crosswire
  module Presenters
    class ComboboxTest < Minitest::Test
      def presenter(**options)
        Combobox.new(id: "state", name: "record[state]", **options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--combobox", Combobox.identifier
      end

      # --- id relationships wired both ways --------------------------------------------

      def test_input_id_is_derived_from_the_base_id
        assert_equal "state-input", presenter.input_attrs["id"]
      end

      def test_listbox_id_is_derived_from_the_base_id
        assert_equal "state-listbox", presenter.listbox_attrs["id"]
      end

      def test_input_aria_controls_matches_the_listbox_id
        p = presenter
        assert_equal p.listbox_attrs["id"], p.input_attrs["aria-controls"]
      end

      def test_label_id_matches_input_aria_labelledby_on_the_listbox
        p = presenter
        assert_equal p.label_attrs["id"], p.listbox_attrs["aria-labelledby"]
      end

      def test_label_for_matches_the_input_id
        p = presenter
        assert_equal p.input_attrs["id"], p.label_attrs["for"]
      end

      def test_option_id_is_derived_from_the_base_id_and_value
        assert_equal "state-option-CA", presenter.option_id("CA")
      end

      # --- role=combobox contract -------------------------------------------------------

      def test_input_has_the_combobox_role
        assert_equal "combobox", presenter.input_attrs["role"]
      end

      def test_input_carries_aria_expanded
        assert_equal "false", presenter.input_attrs["aria-expanded"]
        assert_equal "true", presenter(expanded: true).input_attrs["aria-expanded"]
      end

      def test_input_carries_aria_haspopup_listbox
        assert_equal "listbox", presenter.input_attrs["aria-haspopup"]
      end

      # --- aria-autocomplete: unconditional (notes/19 gap) -----------------------------

      def test_aria_autocomplete_none
        assert_equal "none", presenter(autocomplete: "none").input_attrs["aria-autocomplete"]
      end

      def test_aria_autocomplete_list
        assert_equal "list", presenter(autocomplete: "list").input_attrs["aria-autocomplete"]
      end

      def test_aria_autocomplete_both
        assert_equal "both", presenter(autocomplete: "both").input_attrs["aria-autocomplete"]
      end

      def test_aria_autocomplete_defaults_to_list
        assert_equal "list", presenter.input_attrs["aria-autocomplete"]
      end

      # --- native autocomplete is switched off, deliberately ----------------------------

      def test_native_autocomplete_is_off
        assert_equal "off", presenter.input_attrs["autocomplete"]
      end

      # --- form integration (0.6) --------------------------------------------------------

      def test_input_carries_no_name
        refute presenter.input_attrs.key?("name")
      end

      def test_hidden_field_carries_the_name
        assert_equal "record[state]", presenter.field_attrs["name"]
      end

      def test_hidden_field_is_type_hidden
        assert_equal "hidden", presenter.field_attrs["type"]
      end

      def test_hidden_field_carries_the_server_value
        assert_equal "CA", presenter(value: "CA").field_attrs["value"]
      end

      # --- R4: preselected value rendered THREE ways -------------------------------------

      def test_preselected_value_renders_on_root_hidden_field_and_input
        p = presenter(value: "CA", display: "California")
        assert_equal "CA", p.root_attrs["data-cw--combobox-value-value"]
        assert_equal "CA", p.field_attrs["value"]
        assert_equal "California", p.input_attrs["value"]
      end

      def test_matching_option_is_marked_selected
        attrs = presenter(value: "CA").option_attrs(value: "CA", selected: true)
        assert_equal "true", attrs["aria-selected"]
      end

      # --- options ------------------------------------------------------------------------

      def test_option_has_the_option_role
        assert_equal "option", presenter.option_attrs(value: "CA")["role"]
      end

      def test_option_id_is_unique_per_value
        refute_equal presenter.option_attrs(value: "CA")["id"], presenter.option_attrs(value: "NY")["id"]
      end

      def test_option_carries_no_tabindex
        # 0.3 — DOM focus never leaves the input; no option ever carries a tabindex.
        refute presenter.option_attrs(value: "CA").key?("tabindex")
      end

      def test_option_aria_selected_defaults_false
        assert_equal "false", presenter.option_attrs(value: "CA")["aria-selected"]
      end

      def test_option_value_and_display_are_rendered_as_data_params
        attrs = presenter.option_attrs(value: "CA", display: "California")
        assert_equal "CA", attrs["data-cw--combobox-value-param"]
        assert_equal "California", attrs["data-cw--combobox-display-param"]
      end

      def test_option_wires_click_to_select_and_mousedown_to_prevent_blur
        actions = presenter.option_attrs(value: "CA")["data-action"].split
        assert_includes actions, "click->cw--combobox#select"
        assert_includes actions, "mousedown->cw--combobox#preventBlur"
      end

      def test_listbox_hidden_unless_expanded
        assert_equal true, presenter.listbox_attrs["hidden"]
        assert_equal false, presenter(expanded: true).listbox_attrs["hidden"]
      end

      # --- aria-activedescendant is NEVER rendered server-side (0.3) --------------------

      def test_input_never_carries_aria_activedescendant
        refute presenter.input_attrs.key?("aria-activedescendant")
      end

      def test_input_aria_activedescendant_absent_even_with_a_preselected_value
        refute presenter(value: "CA", display: "California").input_attrs.key?("aria-activedescendant")
      end

      # --- aria-controls yes, aria-owns no ------------------------------------------------

      def test_input_never_carries_aria_owns
        refute presenter.input_attrs.key?("aria-owns")
      end

      # --- R3a: active_class lands on the ROOT, never on option_attrs -------------------

      def test_active_class_is_emitted_on_root
        attrs = presenter(active_class: "is-active").root_attrs
        assert_equal "is-active", attrs["data-cw--combobox-active-class"]
      end

      def test_active_class_never_appears_on_option_attrs
        attrs = presenter(active_class: "is-active").option_attrs(value: "CA")
        refute attrs.key?("data-cw--combobox-active-class")
      end

      def test_expanded_class_is_emitted_on_root
        attrs = presenter(expanded_class: "is-open").root_attrs
        assert_equal "is-open", attrs["data-cw--combobox-expanded-class"]
      end

      # --- click-outside composition (R5a mechanism 2) ------------------------------------

      def test_root_stacks_click_outside
        assert_includes presenter.root_attrs["data-controller"].split, "cw--click-outside"
      end

      def test_click_outside_enabled_mirrors_expanded_false
        assert_equal "false", presenter(expanded: false).root_attrs["data-cw--click-outside-enabled-value"]
      end

      def test_click_outside_enabled_mirrors_expanded_true
        assert_equal "true", presenter(expanded: true).root_attrs["data-cw--click-outside-enabled-value"]
      end

      def test_root_reacts_to_click_outside_clicked
        actions = presenter.root_attrs["data-action"].split
        assert_includes actions, "cw--click-outside:clicked->cw--combobox#close"
      end

      # --- keyboard wiring: R8a four-descriptor Alt+Arrow --------------------------------

      def test_input_wires_all_four_arrow_descriptors
        actions = presenter.input_attrs["data-action"].split
        assert_includes actions, "keydown.down->cw--combobox#down"
        assert_includes actions, "keydown.alt+down->cw--combobox#down"
        assert_includes actions, "keydown.up->cw--combobox#up"
        assert_includes actions, "keydown.alt+up->cw--combobox#up"
      end

      def test_input_wires_both_tab_descriptors
        actions = presenter.input_attrs["data-action"].split
        assert_includes actions, "keydown.tab->cw--combobox#tabOut"
        assert_includes actions, "keydown.shift+tab->cw--combobox#tabOut"
      end

      # --- Home/End deliberately NOT wired (2.1 — APG assigns them to the caret) --------

      def test_input_never_wires_home_or_end
        actions = presenter.input_attrs["data-action"].split
        refute actions.any? { |a| a.include?("keydown.home") }
        refute actions.any? { |a| a.include?("keydown.end") }
      end

      def test_input_wires_escape_and_enter
        actions = presenter.input_attrs["data-action"].split
        assert_includes actions, "keydown.esc->cw--combobox#escape"
        assert_includes actions, "keydown.enter->cw--combobox#enter"
      end

      def test_input_wires_input_to_filter
        actions = presenter.input_attrs["data-action"].split
        assert_includes actions, "input->cw--combobox#filter"
      end

      def test_open_on_focus_adds_the_focus_action
        actions = presenter(open_on_focus: true).input_attrs["data-action"].split
        assert_includes actions, "focus->cw--combobox#open"
      end

      def test_open_on_focus_omits_the_focus_action_by_default
        actions = presenter.input_attrs["data-action"].split
        refute(actions.any? { |a| a.start_with?("focus->") })
      end

      # --- constructor validation ---------------------------------------------------------

      def test_remote_without_src_raises
        assert_raises(ArgumentError) { presenter(filter: "remote") }
      end

      def test_remote_with_src_does_not_raise
        presenter(filter: "remote", src: "/options")
      end

      def test_remote_with_autocomplete_both_raises
        assert_raises(ArgumentError) { presenter(filter: "remote", src: "/options", autocomplete: "both") }
      end

      def test_remote_with_autocomplete_list_does_not_raise
        presenter(filter: "remote", src: "/options", autocomplete: "list")
      end

      def test_unknown_filter_raises
        assert_raises(ArgumentError) { presenter(filter: "fuzzy") }
      end

      def test_unknown_autocomplete_raises
        assert_raises(ArgumentError) { presenter(autocomplete: "everything") }
      end

      # --- disabled disables both inputs --------------------------------------------------

      def test_disabled_disables_the_input
        assert presenter(disabled: true).input_attrs["disabled"]
      end

      def test_disabled_disables_the_hidden_field
        assert presenter(disabled: true).field_attrs["disabled"]
      end

      def test_not_disabled_by_default
        refute presenter.input_attrs["disabled"]
        refute presenter.field_attrs["disabled"]
      end

      # --- invalid / required / described_by -----------------------------------------------

      def test_invalid_renders_aria_invalid
        assert_equal "true", presenter(invalid: true).input_attrs["aria-invalid"]
        refute presenter.input_attrs.key?("aria-invalid")
      end

      def test_required_renders_aria_required
        assert_equal "true", presenter(required: true).input_attrs["aria-required"]
        refute presenter.input_attrs.key?("aria-required")
      end

      def test_described_by_renders_aria_describedby
        assert_equal "state-hint", presenter(described_by: "state-hint").input_attrs["aria-describedby"]
      end

      # --- frame_attrs (remote mode) ---------------------------------------------------

      def test_frame_id_is_derived_from_the_base_id
        assert_equal "state-options", presenter.frame_attrs["id"]
      end

      def test_frame_attrs_carries_no_src
        refute presenter.frame_attrs.key?("src")
      end

      # --- status / empty ----------------------------------------------------------------

      def test_status_is_a_polite_live_region
        attrs = presenter.status_attrs
        assert_equal "status", attrs["role"]
        assert_equal "polite", attrs["aria-live"]
        assert_equal "true", attrs["aria-atomic"]
      end

      def test_empty_is_hidden_by_default
        assert_equal true, presenter.empty_attrs["hidden"]
      end

      # --- clear_attrs ---------------------------------------------------------------------

      def test_clear_attrs_wires_click_to_clear
        actions = presenter.clear_attrs["data-action"].split
        assert_includes actions, "click->cw--combobox#clear"
      end

      def test_clear_attrs_has_an_accessible_label
        assert_equal "Clear", presenter.clear_attrs["aria-label"]
      end

      # --- caller attrs compose, never clobber --------------------------------------------

      def test_caller_controller_on_root_is_added_not_replaced
        attrs = presenter(data: {controller: "analytics"}).root_attrs
        assert_equal "cw--combobox cw--click-outside analytics", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_with_bang_on_root
        attrs = presenter(data: {"controller!" => "mine-only"}).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_input_extra_attrs_are_merged
        assert_equal "wide", presenter.input_attrs(class: "wide")["class"]
      end

      def test_option_extra_attrs_are_merged
        assert_equal "opt", presenter.option_attrs(value: "CA", class: "opt")["class"]
      end

      # --- context-freedom -------------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, presenter.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
