# frozen_string_literal: true

require "test_helper"

# lib/crosswire.rb is being wired up by a sibling change; require the presenter
# directly so this suite does not depend on that ordering.
require "crosswire/presenters/focus_trap"

module Crosswire
  module Presenters
    class FocusTrapTest < Minitest::Test
      def presenter(**options)
        FocusTrap.new(**options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--focus-trap", FocusTrap.identifier
      end

      # --- state rendered server-side --------------------------------------------------

      def test_active_defaults_to_true_and_is_rendered_server_side
        assert_equal "true", presenter.root_attrs["data-cw--focus-trap-active-value"]
      end

      def test_active_false_is_rendered_server_side
        attrs = presenter(active: false).root_attrs
        assert_equal "false", attrs["data-cw--focus-trap-active-value"]
      end

      def test_initial_is_omitted_when_not_given
        refute presenter.root_attrs.key?("data-cw--focus-trap-initial-value")
      end

      def test_initial_is_passed_through_when_given
        attrs = presenter(initial: "#heading").root_attrs
        assert_equal "#heading", attrs["data-cw--focus-trap-initial-value"]
      end

      # --- Stimulus wiring -----------------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--focus-trap", presenter.root_attrs["data-controller"]
      end

      def test_tab_is_wired_to_cycle
        assert_equal "keydown.tab->cw--focus-trap#cycle keydown.shift+tab->cw--focus-trap#cycle",
                     presenter.root_attrs["data-action"]
      end

      # --- R3 / R3a: the class attribute, when present, lives on the root -------------

      def test_active_class_is_omitted_when_not_given
        # Stimulus THROWS on `this.fooClass` when absent, so the controller guards with
        # hasActiveClass — but we must also not emit an empty attribute.
        refute presenter.root_attrs.key?("data-cw--focus-trap-active-class")
      end

      def test_active_class_is_passed_through_when_given
        attrs = presenter(active_class: "is-trapped").root_attrs
        assert_equal "is-trapped", attrs["data-cw--focus-trap-active-class"]
      end

      # --- there are no targets: this is a root-only behaviour ------------------------

      def test_has_no_target_methods
        # focus-trap decorates whatever element it is placed on; it owns no markup
        # and defines no targets, unlike a widget such as disclosure.
        refute presenter.respond_to?(:trigger_attrs)
        refute presenter.respond_to?(:panel_attrs)
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--focus-trap analytics", attrs["data-controller"]
      end

      def test_caller_action_is_added_not_replaced
        attrs = presenter(data: { action: "click->analytics#track" }).root_attrs
        assert_equal "keydown.tab->cw--focus-trap#cycle keydown.shift+tab->cw--focus-trap#cycle " \
                     "click->analytics#track",
                     attrs["data-action"]
      end

      def test_caller_can_force_replacement_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_classes_survive
        attrs = presenter(class: "drawer").root_attrs
        assert_equal "drawer", attrs["class"]
      end

      # --- context-freedom -------------------------------------------------------------

      def test_presenter_needs_no_view_context
        # The whole suite proves this by not booting Rails, but assert it explicitly
        # so the constraint is visible as a requirement rather than an accident.
        assert_kind_of Hash, FocusTrap.new.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
