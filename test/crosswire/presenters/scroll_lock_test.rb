# frozen_string_literal: true

# Required directly rather than through test_helper: sibling agents are wiring up
# lib/crosswire.rb and app/assets/javascripts/crosswire/index.js in parallel, and this
# suite must not depend on that being finished. `crosswire/presenters/scroll_lock`
# pulls in its own dependency (`crosswire/presenter`, which pulls in
# `crosswire/attributes`), so this is a complete, self-contained load path — and, like
# test_helper.rb, it proves the presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/scroll_lock"
require "minitest/autorun"

module Crosswire
  module Presenters
    class ScrollLockTest < Minitest::Test
      def presenter(**options)
        ScrollLock.new(**options)
      end

      # --- identifier derivation: scroll_lock.rb -> cw--scroll-lock -------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--scroll-lock", ScrollLock.identifier
      end

      # --- Stimulus wiring on the root -------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--scroll-lock", presenter.root_attrs["data-controller"]
      end

      def test_active_defaults_to_false
        assert_equal "false", presenter.root_attrs["data-cw--scroll-lock-active-value"]
      end

      def test_active_is_configurable
        attrs = presenter(active: true).root_attrs
        assert_equal "true", attrs["data-cw--scroll-lock-active-value"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "cw--dialog" }).root_attrs
        assert_equal "cw--scroll-lock cw--dialog", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_of_controller_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_class_survives
        attrs = presenter(class: "cw-dialog").root_attrs
        assert_equal "cw-dialog", attrs["class"]
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, presenter.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
