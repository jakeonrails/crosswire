# frozen_string_literal: true

# Required directly rather than through test_helper: sibling agents are wiring up
# lib/crosswire.rb and app/assets/javascripts/crosswire/index.js in parallel, and this
# suite must not depend on that being finished. `crosswire/presenters/sortable` pulls
# in its own dependency (`crosswire/presenter`, which pulls in `crosswire/attributes`),
# so this is a complete, self-contained load path — and, like test_helper.rb, it proves
# the presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/sortable"
require "minitest/autorun"

module Crosswire
  module Presenters
    class SortableTest < Minitest::Test
      def presenter(url: "/items/reorder", **options)
        Sortable.new(url: url, **options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--sortable", Sortable.identifier
      end

      # --- url is required, and rendered — R4: state accepted must be state emitted --

      def test_url_is_required
        assert_raises(ArgumentError) { Sortable.new }
      end

      def test_root_declares_the_controller
        assert_equal "cw--sortable", presenter.root_attrs["data-controller"]
      end

      def test_url_is_rendered_as_a_value
        attrs = presenter(url: "/lists/1/items/reorder").root_attrs
        assert_equal "/lists/1/items/reorder", attrs["data-cw--sortable-url-value"]
      end

      # --- optional values, nil-omitted when absent -------------------------------------

      def test_group_and_handle_are_omitted_by_default
        attrs = presenter.root_attrs
        refute attrs.key?("data-cw--sortable-group-value")
        refute attrs.key?("data-cw--sortable-handle-value")
      end

      def test_group_and_handle_are_rendered_when_given
        attrs = presenter(group: "cards", handle: ".drag-handle").root_attrs
        assert_equal "cards", attrs["data-cw--sortable-group-value"]
        assert_equal ".drag-handle", attrs["data-cw--sortable-handle-value"]
      end

      def test_param_name_defaults_to_position
        assert_equal "position", presenter.root_attrs["data-cw--sortable-param-name-value"]
      end

      def test_param_name_is_configurable
        attrs = presenter(param_name: "ids").root_attrs
        assert_equal "ids", attrs["data-cw--sortable-param-name-value"]
      end

      # --- item_attrs: the id IS the wiring, not a custom data attribute ---------------

      def test_item_target_is_namespaced_to_the_identifier
        assert_equal "item", presenter.item_attrs(id: "item_1")["data-cw--sortable-target"]
      end

      def test_item_id_is_rendered_as_the_plain_html_id
        assert_equal "item_42", presenter.item_attrs(id: "item_42")["id"]
      end

      def test_item_id_is_required
        assert_raises(ArgumentError) { presenter.item_attrs }
      end

      # --- move_up_attrs / move_down_attrs: the accessible path -------------------------

      def test_move_up_is_a_real_button_wired_to_move_up
        attrs = presenter.move_up_attrs
        assert_equal "button", attrs["type"]
        assert_equal "click->cw--sortable#moveUp", attrs["data-action"]
      end

      def test_move_down_is_a_real_button_wired_to_move_down
        attrs = presenter.move_down_attrs
        assert_equal "button", attrs["type"]
        assert_equal "click->cw--sortable#moveDown", attrs["data-action"]
      end

      def test_move_up_default_label
        assert_equal "Move up", presenter.move_up_attrs["aria-label"]
      end

      def test_move_down_default_label
        assert_equal "Move down", presenter.move_down_attrs["aria-label"]
      end

      def test_move_labels_are_configurable
        assert_equal "Move Foo up", presenter.move_up_attrs(label: "Move Foo up")["aria-label"]
        assert_equal "Move Foo down", presenter.move_down_attrs(label: "Move Foo down")["aria-label"]
      end

      def test_move_buttons_default_to_enabled
        assert_equal false, presenter.move_up_attrs["disabled"]
        assert_equal false, presenter.move_down_attrs["disabled"]
      end

      def test_move_buttons_honour_disabled
        assert_equal true, presenter.move_up_attrs(disabled: true)["disabled"]
        assert_equal true, presenter.move_down_attrs(disabled: true)["disabled"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--sortable analytics", attrs["data-controller"]
      end

      def test_caller_class_survives
        attrs = presenter(class: "cw-sortable").root_attrs
        assert_equal "cw-sortable", attrs["class"]
      end

      def test_caller_can_force_replacement_of_controller_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_move_up_extra_attrs_are_merged
        attrs = presenter.move_up_attrs(class: "btn")
        assert_equal "btn", attrs["class"]
        assert_equal "click->cw--sortable#moveUp", attrs["data-action"]
      end

      # --- there is no partial: this is a behaviour with no owned markup ---------------

      def test_has_no_trigger_or_panel_methods
        refute presenter.respond_to?(:trigger_attrs)
        refute presenter.respond_to?(:panel_attrs)
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, Sortable.new(url: "/x").root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
