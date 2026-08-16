# frozen_string_literal: true

require "test_helper"

# lib/crosswire.rb is being wired up by a sibling change; require the presenter
# directly so this suite does not depend on that ordering.
require "crosswire/presenters/sync"

module Crosswire
  module Presenters
    class SyncTest < Minitest::Test
      def presenter(**options)
        Sync.new(target: "#char-count", **options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--sync", Sync.identifier
      end

      # --- defaults --------------------------------------------------------------------

      def test_attribute_defaults_to_value
        assert_equal "value", presenter.attribute
      end

      def test_transform_defaults_to_none
        assert_equal "none", presenter.transform
      end

      # --- state rendered server-side --------------------------------------------------

      def test_values_are_rendered_server_side
        attrs = presenter(attribute: "textContent", transform: "length").root_attrs
        assert_equal "#char-count", attrs["data-cw--sync-target-value"]
        assert_equal "textContent", attrs["data-cw--sync-attribute-value"]
        assert_equal "length", attrs["data-cw--sync-transform-value"]
      end

      def test_target_is_required
        assert_raises(ArgumentError) { Sync.new }
      end

      # --- Stimulus wiring -----------------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--sync", presenter.root_attrs["data-controller"]
      end

      def test_wires_input_and_change_to_sync
        assert_equal "input->cw--sync#sync change->cw--sync#sync", presenter.root_attrs["data-action"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--sync analytics", attrs["data-controller"]
      end

      def test_caller_action_is_added_not_replaced
        attrs = presenter(data: { action: "click->analytics#track" }).root_attrs
        assert_equal "input->cw--sync#sync change->cw--sync#sync click->analytics#track", attrs["data-action"]
      end

      def test_caller_can_force_replacement_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_classes_survive
        attrs = presenter(class: "counter-input").root_attrs
        assert_equal "counter-input", attrs["class"]
      end

      # --- there is no partial: this is a root-only behaviour --------------------------

      def test_has_no_target_or_panel_methods
        refute presenter.respond_to?(:trigger_attrs)
        refute presenter.respond_to?(:panel_attrs)
      end

      # --- context-freedom -------------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, presenter.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
