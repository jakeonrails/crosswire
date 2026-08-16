# frozen_string_literal: true

# Required directly rather than through test_helper: sibling agents are wiring up
# lib/crosswire.rb and app/assets/javascripts/crosswire/index.js in parallel, and this
# suite must not depend on that being finished. `crosswire/presenters/preserve` pulls
# in its own dependency (`crosswire/presenter`, which pulls in `crosswire/attributes`),
# so this is a complete, self-contained load path — and, like test_helper.rb, it proves
# the presenter needs no Rails.
$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "crosswire/presenters/preserve"
require "minitest/autorun"

module Crosswire
  module Presenters
    class PreserveTest < Minitest::Test
      def presenter(**options)
        Preserve.new(**options)
      end

      # --- identifier derivation -------------------------------------------------------

      def test_identifier_derives_from_class_name
        assert_equal "cw--preserve", Preserve.identifier
      end

      # --- Stimulus wiring on the root ---------------------------------------------------

      def test_root_declares_the_controller
        attrs = presenter(attributes: "aria-expanded").root_attrs
        assert_equal "cw--preserve", attrs["data-controller"]
      end

      def test_attributes_string_is_passed_through_as_the_value
        attrs = presenter(attributes: "aria-expanded class").root_attrs
        assert_equal "aria-expanded class", attrs["data-cw--preserve-attributes-value"]
      end

      def test_attributes_array_is_joined_with_spaces
        attrs = presenter(attributes: %w[aria-expanded class]).root_attrs
        assert_equal "aria-expanded class", attrs["data-cw--preserve-attributes-value"]
      end

      def test_attributes_array_entries_that_are_themselves_space_separated_are_split_and_flattened
        attrs = presenter(attributes: ["aria-expanded class", :contenteditable]).root_attrs
        assert_equal "aria-expanded class contenteditable", attrs["data-cw--preserve-attributes-value"]
      end

      def test_element_defaults_to_false_and_is_omitted_entirely
        attrs = presenter(attributes: "aria-expanded").root_attrs
        refute attrs.key?("data-cw--preserve-element-value")
      end

      def test_element_true_is_rendered
        attrs = presenter(element: true).root_attrs
        assert_equal "true", attrs["data-cw--preserve-element-value"]
      end

      def test_attributes_omitted_entirely_when_element_true_and_no_attributes_given
        attrs = presenter(element: true).root_attrs
        refute attrs.key?("data-cw--preserve-attributes-value")
      end

      def test_both_attributes_and_element_may_be_given_together
        attrs = presenter(attributes: "aria-expanded", element: true).root_attrs
        assert_equal "aria-expanded", attrs["data-cw--preserve-attributes-value"]
        assert_equal "true", attrs["data-cw--preserve-element-value"]
      end

      # --- the ArgumentError: nothing to preserve is a build-time mistake, not a
      # runtime state --------------------------------------------------------------------

      def test_raises_when_attributes_is_nil_and_element_is_false
        assert_raises(ArgumentError) { presenter }
      end

      def test_raises_when_attributes_is_blank_and_element_is_false
        assert_raises(ArgumentError) { presenter(attributes: "   ") }
        assert_raises(ArgumentError) { presenter(attributes: []) }
      end

      def test_does_not_raise_when_element_true_even_with_no_attributes
        presenter(element: true) # must not raise
      end

      # --- caller overrides compose, never clobber ---------------------------------------

      def test_caller_controller_is_added_not_replaced
        attrs = presenter(attributes: "aria-expanded", data: { controller: "tom-select" }).root_attrs
        assert_equal "cw--preserve tom-select", attrs["data-controller"]
      end

      def test_caller_can_force_replacement_of_controller_with_bang
        attrs = presenter(attributes: "aria-expanded", data: { "controller!" => "mine-only" }).root_attrs
        assert_equal "mine-only", attrs["data-controller"]
      end

      def test_caller_class_survives
        attrs = presenter(attributes: "aria-expanded", class: "cw-widget").root_attrs
        assert_equal "cw-widget", attrs["class"]
      end

      # --- context-freedom ---------------------------------------------------------------

      def test_presenter_needs_no_view_context
        assert_kind_of Hash, presenter(attributes: "aria-expanded").root_attrs
        refute defined?(::Rails), "test suite must not boot Rails"
      end
    end
  end
end
