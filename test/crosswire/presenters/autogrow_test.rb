# frozen_string_literal: true

# Required directly rather than through test_helper: sibling agents are wiring up
# lib/crosswire.rb and app/assets/javascripts/crosswire/index.js in parallel, and this
# suite must not depend on that being finished. `crosswire/presenters/autogrow` pulls
# in its own dependency (`crosswire/presenter`, which pulls in `crosswire/attributes`),
# so this is a complete, self-contained load path — and, like test_helper.rb, it proves
# the presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/autogrow"
require "minitest/autorun"

module Crosswire
  module Presenters
    class AutogrowTest < Minitest::Test
      def presenter(**options)
        Autogrow.new(**options)
      end

      # --- identifier derivation -----------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--autogrow", Autogrow.identifier
      end

      # --- Stimulus wiring -------------------------------------------------------------

      def test_root_declares_the_controller
        assert_equal "cw--autogrow", presenter.root_attrs["data-controller"]
      end

      def test_max_rows_is_declared_when_given
        attrs = presenter(max_rows: 12).root_attrs
        assert_equal 12, attrs["data-cw--autogrow-max-rows-value"]
      end

      def test_max_rows_is_omitted_entirely_rather_than_emitted_empty_when_not_given
        refute presenter.root_attrs.key?("data-cw--autogrow-max-rows-value")
      end

      # --- caller overrides compose, never clobber -------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(data: { controller: "analytics" }).root_attrs
        assert_equal "cw--autogrow analytics", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_with_bang
        attrs = presenter(data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_classes_survive
        attrs = presenter(class: "autogrow").root_attrs
        assert_equal "autogrow", attrs["class"]
      end

      # --- context-freedom -----------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, Autogrow.new.root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
