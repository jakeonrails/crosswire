# frozen_string_literal: true

require "test_helper"

# Not required by lib/crosswire.rb yet — COMPONENTS registration is being wired up
# separately (see docs/COMPONENT_CONTRACT.md and the task instructions for this
# component pair). Required directly here so the presenter is unit-testable on its own.
require "crosswire/presenters/autosubmit"

module Crosswire
  module Presenters
    class AutosubmitTest < Minitest::Test
      def presenter(**options)
        Autosubmit.new(**options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--autosubmit", Autosubmit.identifier
      end

      # --- Stimulus wiring -------------------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--autosubmit", presenter.root_attrs["data-controller"]
      end

      def test_defaults_are_rendered_as_values
        attrs = presenter.root_attrs
        assert_equal 0, attrs["data-cw--autosubmit-delay-value"]
        assert_equal "input", attrs["data-cw--autosubmit-event-value"]
      end

      def test_scope_is_omitted_when_not_given
        refute presenter.root_attrs.key?("data-cw--autosubmit-scope-value")
      end

      def test_custom_values_are_rendered
        attrs = presenter(delay: 300, event: "change", scope: "#search-form").root_attrs
        assert_equal 300, attrs["data-cw--autosubmit-delay-value"]
        assert_equal "change", attrs["data-cw--autosubmit-event-value"]
        assert_equal "#search-form", attrs["data-cw--autosubmit-scope-value"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--autosubmit analytics", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_classes_survive
        attrs = presenter(class: "form-control").root_attrs
        assert_equal "form-control", attrs["class"]
      end

      def test_caller_data_attributes_survive
        attrs = presenter(data: { testid: "search-field" }).root_attrs
        assert_equal "search-field", attrs["data-testid"]
      end

      # --- context-freedom ---------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, Autosubmit.new.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
