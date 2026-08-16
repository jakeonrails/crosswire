# frozen_string_literal: true

require "test_helper"
require "crosswire/presenters/transition"

module Crosswire
  module Presenters
    class TransitionTest < Minitest::Test
      def presenter(**options)
        Transition.new(**options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--transition", Transition.identifier
      end

      # --- Stimulus wiring -------------------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--transition", presenter.root_attrs["data-controller"]
      end

      # --- the CSS Classes API: every class is optional and nil-omitted --------------
      # R3 — Stimulus THROWS on `this.fooClass` when the attribute is absent, so the
      # controller must guard with `hasFooClass` — but we must also not emit an empty
      # attribute in the first place.

      def test_no_classes_are_emitted_by_default
        attrs = presenter.root_attrs
        %w[enter enter-from enter-to leave leave-from leave-to].each do |name|
          refute attrs.key?("data-cw--transition-#{name}-class"), "expected no #{name} class"
        end
      end

      def test_each_class_is_passed_through_independently
        attrs = presenter(
          enter: "transition-enter",
          enter_from: "opacity-0",
          enter_to: "opacity-100",
          leave: "transition-leave",
          leave_from: "opacity-100",
          leave_to: "opacity-0"
        ).root_attrs

        assert_equal "transition-enter", attrs["data-cw--transition-enter-class"]
        assert_equal "opacity-0", attrs["data-cw--transition-enter-from-class"]
        assert_equal "opacity-100", attrs["data-cw--transition-enter-to-class"]
        assert_equal "transition-leave", attrs["data-cw--transition-leave-class"]
        assert_equal "opacity-100", attrs["data-cw--transition-leave-from-class"]
        assert_equal "opacity-0", attrs["data-cw--transition-leave-to-class"]
      end

      def test_leave_only_classes_leave_enter_classes_omitted
        attrs = presenter(leave: "fade", leave_from: "opacity-100", leave_to: "opacity-0").root_attrs

        refute attrs.key?("data-cw--transition-enter-class")
        refute attrs.key?("data-cw--transition-enter-from-class")
        refute attrs.key?("data-cw--transition-enter-to-class")
        assert_equal "fade", attrs["data-cw--transition-leave-class"]
      end

      # --- composition with cw--dismiss -----------------------------------------------

      def test_leave_on_wires_the_dismissing_event_to_leave_by_default
        attrs = presenter.leave_on
        assert_equal "cw--dismiss:dismissing->cw--transition#leave", attrs["data-action"]
      end

      def test_leave_on_accepts_a_custom_event_name
        attrs = presenter.leave_on("cw--custom:removing")
        assert_equal "cw--custom:removing->cw--transition#leave", attrs["data-action"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--transition analytics", attrs["data-controller"]
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
        assert_kind_of Hash, Transition.new.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
