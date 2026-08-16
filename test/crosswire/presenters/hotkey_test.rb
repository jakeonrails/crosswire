# frozen_string_literal: true

# Required directly rather than through test_helper: sibling agents are wiring up
# lib/crosswire.rb and app/assets/javascripts/crosswire/index.js in parallel, and this
# suite must not depend on that being finished. `crosswire/presenters/hotkey` pulls in
# its own dependency (`crosswire/presenter`, which pulls in `crosswire/attributes`), so
# this is a complete, self-contained load path — and, like test_helper.rb, it proves
# the presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/hotkey"
require "minitest/autorun"

module Crosswire
  module Presenters
    class HotkeyTest < Minitest::Test
      def presenter(**options)
        Hotkey.new(key: "cmd+k", **options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--hotkey", Hotkey.identifier
      end

      # --- Stimulus wiring on the root -------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--hotkey", presenter.root_attrs["data-controller"]
      end

      def test_key_is_required
        assert_raises(ArgumentError) { Hotkey.new }
      end

      def test_key_is_rendered
        attrs = presenter(key: "shift+?").root_attrs
        assert_equal "shift+?", attrs["data-cw--hotkey-key-value"]
      end

      def test_scope_defaults_to_window
        assert_equal "window", presenter.root_attrs["data-cw--hotkey-scope-value"]
      end

      def test_scope_is_configurable
        attrs = presenter(scope: "element").root_attrs
        assert_equal "element", attrs["data-cw--hotkey-scope-value"]
      end

      def test_prevent_default_defaults_to_true
        assert_equal "true", presenter.root_attrs["data-cw--hotkey-prevent-default-value"]
      end

      def test_prevent_default_is_configurable
        attrs = presenter(prevent_default: false).root_attrs
        assert_equal "false", attrs["data-cw--hotkey-prevent-default-value"]
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--hotkey analytics", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_of_controller_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_class_survives
        attrs = presenter(class: "cw-search-trigger").root_attrs
        assert_equal "cw-search-trigger", attrs["class"]
      end

      def test_caller_action_composes_alongside_ours
        attrs = presenter(data: { action: "cw--hotkey:fired->analytics#track" }).root_attrs
        assert_equal "cw--hotkey:fired->analytics#track", attrs["data-action"]
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, presenter.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
