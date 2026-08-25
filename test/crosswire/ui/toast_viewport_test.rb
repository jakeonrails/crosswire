# frozen_string_literal: true

require "test_helper"
require "crosswire/ui/toast_viewport"

module Crosswire
  module UI
    # Not a registered `Crosswire::UI::COMPONENTS` entry (see the class's own
    # docstring) — still a plain presenter with its own attribute computation, so it
    # gets the same no-Rails unit coverage every other presenter in this tier does.
    class ToastViewportTest < Minitest::Test
      def test_default_attrs
        attrs = ToastViewport.new.root_attrs

        assert_equal "cw-toast-viewport", attrs["id"]
        assert_equal "cw-toast-viewport", attrs["class"]
        assert_equal "status", attrs["role"]
        assert_equal "polite", attrs["aria-live"]
        assert_equal "false", attrs["aria-atomic"]
        assert_equal "", attrs["data-turbo-permanent"]
      end

      def test_assertive_sets_role_alert_and_aria_live_assertive
        attrs = ToastViewport.new(assertive: true).root_attrs

        assert_equal "alert", attrs["role"]
        assert_equal "assertive", attrs["aria-live"]
      end

      def test_custom_id_passes_through_and_stays_stable
        attrs = ToastViewport.new(id: "cw-toast-viewport-assertive").root_attrs

        assert_equal "cw-toast-viewport-assertive", attrs["id"]
      end

      def test_default_id_matches_the_documented_constant
        assert_equal "cw-toast-viewport", ToastViewport::DEFAULT_ID
        assert_equal ToastViewport::DEFAULT_ID, ToastViewport.new.id
      end

      def test_always_carries_data_turbo_permanent_regardless_of_politeness
        assert_equal "", ToastViewport.new.root_attrs["data-turbo-permanent"]
        assert_equal "", ToastViewport.new(assertive: true).root_attrs["data-turbo-permanent"]
      end

      def test_caller_class_composes_after_ours
        assert_equal "cw-toast-viewport extra", ToastViewport.new(class: "extra").root_attrs["class"]
      end

      def test_overrides_do_not_clobber_computed_attributes
        attrs = ToastViewport.new(data: { testid: "toasts" }).root_attrs

        assert_equal "cw-toast-viewport", attrs["class"]
        assert_equal "toasts", attrs["data-testid"]
      end
    end
  end
end
