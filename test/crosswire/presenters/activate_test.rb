# frozen_string_literal: true

# Required directly rather than through test_helper: sibling agents are wiring up
# lib/crosswire.rb and app/assets/javascripts/crosswire/index.js in parallel, and this
# suite must not depend on that being finished. `crosswire/presenters/activate` pulls in
# its own dependency (`crosswire/presenter`, which pulls in `crosswire/attributes`), so
# this is a complete, self-contained load path — and, like test_helper.rb, it proves
# the presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/activate"
require "minitest/autorun"

module Crosswire
  module Presenters
    class ActivateTest < Minitest::Test
      def presenter(**options)
        Activate.new(**options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--activate", Activate.identifier
      end

      # --- Stimulus wiring on the root -------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--activate", presenter.root_attrs["data-controller"]
      end

      def test_target_is_optional_and_absent_by_default
        refute presenter.root_attrs.key?("data-cw--activate-target-value")
      end

      def test_target_is_rendered_when_given
        attrs = presenter(target: "#load_more").root_attrs
        assert_equal "#load_more", attrs["data-cw--activate-target-value"]
      end

      def test_on_connect_defaults_to_false
        assert_equal "false", presenter.root_attrs["data-cw--activate-on-connect-value"]
      end

      def test_on_connect_is_configurable
        attrs = presenter(on_connect: true).root_attrs
        assert_equal "true", attrs["data-cw--activate-on-connect-value"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "cw--intersection" }).root_attrs
        assert_equal "cw--activate cw--intersection", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_of_controller_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_class_survives
        attrs = presenter(class: "cw-sentinel").root_attrs
        assert_equal "cw-sentinel", attrs["class"]
      end

      def test_caller_action_composes_alongside_ours
        attrs = presenter(data: { action: "cw--intersection:entered->cw--activate#activate" }).root_attrs
        assert_equal "cw--intersection:entered->cw--activate#activate", attrs["data-action"]
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, presenter.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
