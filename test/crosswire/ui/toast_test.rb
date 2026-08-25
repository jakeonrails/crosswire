# frozen_string_literal: true

require "test_helper"
require "crosswire/ui/toast"

module Crosswire
  module UI
    # Presenter unit suite (ui-tier-spec.md §7.1) — the composition showcase's other
    # half: by default a toast composes all three of cw--dismiss/cw--timeout/
    # cw--transition, wired together (R5a mechanism 3); each piece is independently
    # optional, and the wiring between two pieces only appears when BOTH are present.
    class ToastTest < Minitest::Test
      def test_default_class_string
        assert_equal "cw-toast", Toast.new.root_attrs["class"]
      end

      def test_every_severity_value
        {
          neutral: "cw-toast",
          info: "cw-toast cw-toast--info",
          success: "cw-toast cw-toast--success",
          warning: "cw-toast cw-toast--warning",
          danger: "cw-toast cw-toast--danger"
        }.each do |severity, expected|
          assert_equal expected, Toast.new(severity: severity).root_attrs["class"], "severity #{severity.inspect}"
        end
      end

      def test_unknown_severity_raises_naming_valid_values
        error = assert_raises(ArgumentError) { Toast.new(severity: :nope).root_attrs }

        assert_match(/nope/, error.message)
        %w[neutral info success warning danger].each { |v| assert_match(/#{v}/, error.message) }
      end

      # --- default composition: all three primitives, fully wired --------------------

      def test_default_composes_all_three_controllers
        tokens = Toast.new.root_attrs["data-controller"].split
        assert_equal %w[cw--dismiss cw--timeout cw--transition], tokens
      end

      def test_default_timeout_delay_is_5000
        assert_equal 5000, Toast.new.root_attrs["data-cw--timeout-delay-value"]
      end

      def test_custom_timeout_delay
        assert_equal 8000, Toast.new(timeout: 8000).root_attrs["data-cw--timeout-delay-value"]
      end

      def test_transition_leave_classes_are_the_presenters_own
        attrs = Toast.new.root_attrs

        assert_equal "cw-toast--leaving", attrs["data-cw--transition-leave-class"]
        assert_equal "cw-toast--leave-from", attrs["data-cw--transition-leave-from-class"]
        assert_equal "cw-toast--leave-to", attrs["data-cw--transition-leave-to-class"]
      end

      def test_default_action_wires_hover_pause_and_elapsed_dismiss
        specs = Toast.new.root_attrs["data-action"].split
        assert_includes specs, "mouseenter->cw--timeout#cancel"
        assert_includes specs, "mouseleave->cw--timeout#restart"
        assert_includes specs, "cw--timeout:elapsed->cw--dismiss#dismiss"
        assert_includes specs, "cw--dismiss:dismissing->cw--transition#leave"
      end

      # --- opting out of one composed piece at a time ---------------------------------

      def test_dismissible_false_drops_dismiss_and_transition_but_keeps_timeout
        attrs = Toast.new(dismissible: false).root_attrs
        tokens = attrs["data-controller"].split

        assert_equal %w[cw--timeout], tokens
        specs = attrs["data-action"].split
        assert_includes specs, "mouseenter->cw--timeout#cancel"
        assert_includes specs, "mouseleave->cw--timeout#restart"
        refute_includes specs, "cw--timeout:elapsed->cw--dismiss#dismiss"
      end

      def test_timeout_nil_drops_timeout_and_its_wiring_but_keeps_dismiss_and_transition
        attrs = Toast.new(timeout: nil).root_attrs
        tokens = attrs["data-controller"].split

        assert_equal %w[cw--dismiss cw--transition], tokens
        refute attrs["data-action"].include?("cw--timeout")
        # `leave_on` (cw--dismiss:dismissing->cw--transition#leave) still wires —
        # cw--transition's `leave_on` default listens for cw--dismiss's own event and
        # has nothing to do with whether a timer exists at all.
        assert_includes attrs["data-action"].split, "cw--dismiss:dismissing->cw--transition#leave"
      end

      def test_dismissible_false_and_timeout_nil_composes_nothing
        attrs = Toast.new(dismissible: false, timeout: nil).root_attrs

        refute attrs.key?("data-controller")
        refute attrs.key?("data-action")
      end

      # --- dismiss trigger ---------------------------------------------------------------

      def test_dismiss_trigger_attrs_raises_when_not_dismissible
        error = assert_raises(ArgumentError) { Toast.new(dismissible: false).dismiss_trigger_attrs }

        assert_match(/dismissible: false/, error.message)
      end

      def test_dismiss_trigger_attrs_when_dismissible
        attrs = Toast.new.dismiss_trigger_attrs

        assert_equal "button", attrs["type"]
        assert_equal "Dismiss", attrs["aria-label"]
      end

      def test_dismissible_and_timeout_attr_readers
        toast = Toast.new(dismissible: false, timeout: nil)
        refute toast.dismissible
        assert_nil toast.timeout
      end

      # --- never carries role/aria-live — see the class docstring --------------------

      def test_root_attrs_never_carries_a_role_or_aria_live
        attrs = Toast.new.root_attrs

        refute attrs.key?("role")
        refute attrs.key?("aria-live")
      end

      # --- ordinary composition/introspection -----------------------------------------

      def test_caller_class_composes_after_ours
        assert_equal "cw-toast extra", Toast.new(class: "extra").root_attrs["class"]
      end

      def test_caller_class_bang_replaces_ours
        assert_equal "only-mine", Toast.new("class!" => "only-mine").root_attrs["class"]
      end

      def test_variants_introspection
        assert_equal({ severity: { values: %i[neutral info success warning danger], default: :neutral } },
                     Toast.variants)
      end

      def test_callers_own_controller_unions_with_the_composed_controllers
        attrs = Toast.new(data: { controller: "analytics" }).root_attrs

        assert_equal "cw--dismiss cw--timeout cw--transition analytics", attrs["data-controller"]
      end
    end
  end
end
