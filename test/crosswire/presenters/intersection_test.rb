# frozen_string_literal: true

require "test_helper"

# lib/crosswire.rb is being wired up by a sibling change; require the presenter
# directly so this suite does not depend on that ordering.
require "crosswire/presenters/intersection"

module Crosswire
  module Presenters
    class IntersectionTest < Minitest::Test
      def presenter(**options)
        Intersection.new(**options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--intersection", Intersection.identifier
      end

      # --- defaults --------------------------------------------------------------------

      def test_defaults_are_rendered_server_side
        attrs = presenter.root_attrs
        # Numbers pass through as-is (Crosswire::Presenter#serialize_value only
        # stringifies booleans/hashes/arrays) — the renderer stringifies at render
        # time, same as any other numeric HTML attribute.
        assert_equal 0, attrs["data-cw--intersection-threshold-value"]
        assert_equal "false", attrs["data-cw--intersection-once-value"]
        assert_equal "0px", attrs["data-cw--intersection-root-margin-value"]
      end

      def test_root_is_omitted_when_not_given
        refute presenter.root_attrs.key?("data-cw--intersection-root-value")
      end

      def test_root_is_passed_through_when_given
        attrs = presenter(root: "#scroller").root_attrs
        assert_equal "#scroller", attrs["data-cw--intersection-root-value"]
      end

      # --- values reflect constructor args --------------------------------------------

      def test_threshold_is_rendered
        assert_equal 0.5, presenter(threshold: 0.5).root_attrs["data-cw--intersection-threshold-value"]
      end

      def test_once_is_rendered
        assert_equal "true", presenter(once: true).root_attrs["data-cw--intersection-once-value"]
      end

      def test_root_margin_is_rendered
        attrs = presenter(root_margin: "200px").root_attrs
        assert_equal "200px", attrs["data-cw--intersection-root-margin-value"]
      end

      # --- Stimulus wiring ---------------------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--intersection", presenter.root_attrs["data-controller"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--intersection analytics", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_classes_survive
        attrs = presenter(class: "sentinel").root_attrs
        assert_equal "sentinel", attrs["class"]
      end

      def test_caller_action_composes_alongside_ours
        attrs = presenter(data: { action: "cw--intersection:entered->gallery#loadMore" }).root_attrs
        assert_equal "cw--intersection:entered->gallery#loadMore", attrs["data-action"]
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, Intersection.new.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
