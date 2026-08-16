# frozen_string_literal: true

# Required directly rather than through test_helper: sibling agents are wiring up
# lib/crosswire.rb and app/assets/javascripts/crosswire/index.js in parallel, and this
# suite must not depend on that being finished. `crosswire/presenters/relative_time`
# pulls in its own dependency (`crosswire/presenter`, which pulls in
# `crosswire/attributes`), so this is a complete, self-contained load path — and, like
# test_helper.rb, it proves the presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/relative_time"
require "minitest/autorun"

module Crosswire
  module Presenters
    class RelativeTimeTest < Minitest::Test
      DATETIME = "2026-08-15T14:05:07Z"

      def presenter(**options)
        RelativeTime.new(datetime: DATETIME, **options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--relative-time", RelativeTime.identifier
      end

      # --- Stimulus wiring on the root -------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--relative-time", presenter.root_attrs["data-controller"]
      end

      def test_datetime_is_required
        assert_raises(ArgumentError) { RelativeTime.new }
      end

      def test_datetime_is_rendered_as_a_value
        attrs = presenter.root_attrs
        assert_equal DATETIME, attrs["data-cw--relative-time-datetime-value"]
      end

      def test_format_defaults_to_relative
        assert_equal "relative", presenter.root_attrs["data-cw--relative-time-format-value"]
      end

      def test_format_is_configurable
        attrs = presenter(format: "datetime").root_attrs
        assert_equal "datetime", attrs["data-cw--relative-time-format-value"]
      end

      def test_threshold_defaults_to_one_day_in_seconds
        assert_equal 86_400, presenter.root_attrs["data-cw--relative-time-threshold-value"]
      end

      def test_threshold_is_configurable
        attrs = presenter(threshold: 3600).root_attrs
        assert_equal 3600, attrs["data-cw--relative-time-threshold-value"]
      end

      # --- accessibility (R2): absolute instant always recoverable ---------------------

      def test_root_carries_a_literal_datetime_attribute_with_the_absolute_value
        attrs = presenter.root_attrs
        assert_equal DATETIME, attrs["datetime"]
      end

      def test_root_carries_a_human_readable_title_with_the_absolute_value
        attrs = presenter.root_attrs
        assert_equal "August 15, 2026, 2:05 PM UTC", attrs["title"]
      end

      def test_title_reflects_a_different_instant
        attrs = presenter(datetime: "2026-01-02T09:00:00Z").root_attrs
        assert_equal "January 2, 2026, 9:00 AM UTC", attrs["title"]
      end

      def test_no_aria_live_is_emitted
        attrs = presenter.root_attrs
        refute attrs.key?("aria-live"), "a self-updating timestamp must not be a live region"
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "cw--sync" }).root_attrs
        assert_equal "cw--relative-time cw--sync", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_of_controller_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_class_survives
        attrs = presenter(class: "cw-timestamp").root_attrs
        assert_equal "cw-timestamp", attrs["class"]
      end

      def test_caller_title_override_wins_over_ours
        attrs = presenter(title: "custom title").root_attrs
        assert_equal "custom title", attrs["title"]
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, presenter.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
