# frozen_string_literal: true

require "test_helper"
require "crosswire/presenters/persist"

module Crosswire
  module Presenters
    class PersistTest < Minitest::Test
      def presenter(**options)
        Persist.new(key: "search-filter", **options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--persist", Persist.identifier
      end

      # --- required / validated arguments ----------------------------------------------

      def test_key_is_required
        assert_raises(ArgumentError) { Persist.new(key: nil) }
        assert_raises(ArgumentError) { Persist.new(key: "") }
      end

      def test_storage_must_be_local_or_session
        assert_raises(ArgumentError) { presenter(storage: "cookie") }
        presenter(storage: "local")
        presenter(storage: "session")
      end

      # --- Stimulus wiring -------------------------------------------------------------

      def test_root_declares_the_controller_and_key
        attrs = presenter.root_attrs
        assert_equal "cw--persist", attrs["data-controller"]
        assert_equal "search-filter", attrs["data-cw--persist-key-value"]
      end

      def test_defaults_are_rendered_server_side
        attrs = presenter.root_attrs
        assert_equal "value", attrs["data-cw--persist-attribute-value"]
        assert_equal "local", attrs["data-cw--persist-storage-value"]
        assert_equal 0, attrs["data-cw--persist-debounce-value"]
      end

      def test_options_are_passed_through
        attrs = presenter(attribute: "checked", storage: "session", debounce: 300).root_attrs
        assert_equal "checked", attrs["data-cw--persist-attribute-value"]
        assert_equal "session", attrs["data-cw--persist-storage-value"]
        assert_equal 300, attrs["data-cw--persist-debounce-value"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--persist analytics", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_classes_survive
        attrs = presenter(class: "rounded shadow").root_attrs
        assert_equal "rounded shadow", attrs["class"]
      end

      # --- context-freedom ---------------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, Persist.new(key: "x").root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
