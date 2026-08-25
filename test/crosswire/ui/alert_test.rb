# frozen_string_literal: true

require "test_helper"
require "crosswire/ui/alert"

module Crosswire
  module UI
    # Presenter unit suite (ui-tier-spec.md §7.1) — plus the role-vs-aria-live a11y
    # guarantee and the composition showcase's own shape (dismiss stacks onto the
    # root only when `dismissible: true`, and never otherwise).
    class AlertTest < Minitest::Test
      def test_default_class_string
        assert_equal "cw-alert", Alert.new.root_attrs["class"]
      end

      def test_every_severity_value
        {
          neutral: "cw-alert",
          info: "cw-alert cw-alert--info",
          success: "cw-alert cw-alert--success",
          warning: "cw-alert cw-alert--warning",
          danger: "cw-alert cw-alert--danger"
        }.each do |severity, expected|
          assert_equal expected, Alert.new(severity: severity).root_attrs["class"], "severity #{severity.inspect}"
        end
      end

      def test_subtle_boolean
        assert_equal "cw-alert cw-alert--subtle", Alert.new(subtle: true).root_attrs["class"]
        assert_equal "cw-alert", Alert.new(subtle: false).root_attrs["class"]
      end

      def test_class_order_is_base_then_severity_then_subtle
        assert_equal "cw-alert cw-alert--danger cw-alert--subtle",
                     Alert.new(severity: :danger, subtle: true).root_attrs["class"]
      end

      def test_unknown_severity_raises_naming_valid_values
        error = assert_raises(ArgumentError) { Alert.new(severity: :nope).root_attrs }

        assert_match(/nope/, error.message)
        %w[neutral info success warning danger].each { |v| assert_match(/#{v}/, error.message) }
      end

      # --- guarantee: role picked from severity, never role + aria-live together -----

      def test_polite_severities_get_role_status
        %i[neutral info success].each do |severity|
          assert_equal "status", Alert.new(severity: severity).role, "severity #{severity.inspect}"
          assert_equal "status", Alert.new(severity: severity).root_attrs["role"]
        end
      end

      def test_assertive_severities_get_role_alert
        %i[danger warning].each do |severity|
          assert_equal "alert", Alert.new(severity: severity).role, "severity #{severity.inspect}"
          assert_equal "alert", Alert.new(severity: severity).root_attrs["role"]
        end
      end

      def test_root_attrs_never_carries_an_explicit_aria_live
        %i[neutral info success warning danger].each do |severity|
          refute Alert.new(severity: severity).root_attrs.key?("aria-live"),
                 "severity #{severity.inspect} should not carry an explicit aria-live alongside its role"
        end
      end

      # --- composition showcase: dismiss stacks onto root only when asked ------------

      def test_not_dismissible_by_default_carries_no_dismiss_controller
        attrs = Alert.new.root_attrs

        refute attrs.key?("data-controller")
      end

      def test_dismissible_composes_cw_dismiss_onto_the_root
        attrs = Alert.new(dismissible: true).root_attrs

        assert_equal "cw--dismiss", attrs["data-controller"]
      end

      def test_dismiss_trigger_attrs_raises_when_not_dismissible
        error = assert_raises(ArgumentError) { Alert.new.dismiss_trigger_attrs }

        assert_match(/dismissible: false/, error.message)
      end

      def test_dismiss_trigger_attrs_when_dismissible
        attrs = Alert.new(dismissible: true).dismiss_trigger_attrs

        assert_equal "button", attrs["type"]
        assert_equal "Dismiss", attrs["aria-label"]
        assert_equal "click->cw--dismiss#dismiss", attrs["data-action"]
      end

      def test_dismissible_attr_reader
        assert Alert.new(dismissible: true).dismissible
        refute Alert.new(dismissible: false).dismissible
        refute Alert.new.dismissible
      end

      # --- ordinary composition/introspection -----------------------------------------

      def test_caller_class_composes_after_ours
        assert_equal "cw-alert extra", Alert.new(class: "extra").root_attrs["class"]
      end

      def test_caller_class_bang_replaces_ours
        assert_equal "only-mine", Alert.new("class!" => "only-mine").root_attrs["class"]
      end

      def test_variants_introspection
        assert_equal({
                       severity: { values: %i[neutral info success warning danger], default: :neutral },
                       subtle: { values: [true, false], default: false }
                     }, Alert.variants)
      end

      def test_overrides_do_not_clobber_computed_attributes
        attrs = Alert.new(severity: :warning, data: { testid: "low-stock" }).root_attrs

        assert_equal "cw-alert cw-alert--warning", attrs["class"]
        assert_equal "low-stock", attrs["data-testid"]
      end

      # A caller's own `data-controller` still UNIONS with the composed `cw--dismiss`
      # one — the same union-not-clobber guarantee every stacked primitive relies on.
      def test_callers_own_controller_unions_with_the_composed_dismiss_controller
        attrs = Alert.new(dismissible: true, data: { controller: "analytics" }).root_attrs

        assert_equal "cw--dismiss analytics", attrs["data-controller"]
      end
    end
  end
end
