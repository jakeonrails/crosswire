# frozen_string_literal: true

require "test_helper"

module Crosswire
  class AttributesTest < Minitest::Test
    Attrs = Crosswire::Attributes

    # --- the core promise: accumulate, don't clobber -------------------------------

    def test_unions_data_controller
      result = Attrs.merge(
        { data: { controller: "cw--disclosure" } },
        { data: { controller: "analytics" } }
      )
      assert_equal "cw--disclosure analytics", result["data-controller"]
    end

    def test_unions_data_action
      result = Attrs.merge(
        { data: { action: "click->cw--disclosure#toggle" } },
        { data: { action: "click->analytics#track" } }
      )
      assert_equal "click->cw--disclosure#toggle click->analytics#track", result["data-action"]
    end

    def test_unions_class
      result = Attrs.merge({ class: "cw-disclosure" }, { class: "mt-4 rounded" })
      assert_equal "cw-disclosure mt-4 rounded", result["class"]
    end

    def test_non_union_keys_are_last_wins
      result = Attrs.merge({ id: "a" }, { id: "b" })
      assert_equal "b", result["id"]
    end

    # --- idempotency: what makes it safe to apply at every layer --------------------

    def test_merging_a_result_into_itself_is_a_noop
      once = Attrs.merge({ data: { controller: "a b" }, class: "x y" })
      twice = Attrs.merge(once, once)
      assert_equal once, twice
    end

    def test_union_dedupes
      result = Attrs.merge(
        { data: { controller: "a" } },
        { data: { controller: "a b" } },
        { data: { controller: "b a" } }
      )
      assert_equal "a b", result["data-controller"]
    end

    # --- key normalization ---------------------------------------------------------

    def test_nested_and_flat_keys_normalize_to_the_same_thing
      nested = Attrs.merge(data: { controller: "a" })
      flat   = Attrs.merge("data-controller" => "a")
      assert_equal flat, nested
    end

    def test_underscores_dasherize_so_double_underscore_namespaces
      # This is what lets a namespaced Stimulus identifier be written in plain Ruby
      # hash syntax with no string interpolation.
      result = Attrs.merge(data: { cw__disclosure_target: "panel" })
      assert_equal "panel", result["data-cw--disclosure-target"]
    end

    def test_aria_nesting
      result = Attrs.merge(aria: { expanded: "true", controls: "x" })
      assert_equal "true", result["aria-expanded"]
      assert_equal "x", result["aria-controls"]
    end

    # --- deletion and the override escape hatch ------------------------------------

    def test_explicit_nil_deletes
      result = Attrs.merge({ id: "a", class: "x" }, { id: nil })
      refute result.key?("id")
      assert_equal "x", result["class"]
    end

    def test_bang_forces_replacement_over_union
      result = Attrs.merge(
        { data: { controller: "cw--disclosure" } },
        { data: { "controller!" => "only-mine" } }
      )
      assert_equal "only-mine", result["data-controller"]
    end

    def test_bang_key_does_not_leak_into_output
      result = Attrs.merge({ class: "a" }, { "class!" => "b" })
      assert_equal({ "class" => "b" }, result)
    end

    # --- the traps found in Rails' own behaviour (research/notes/17) ----------------

    def test_arrays_in_union_keys_space_join_rather_than_json_encode
      # Rails only special-cases `class` and `aria`, so `data: { controller: [...] }`
      # silently renders as JSON. We fix that for the keys where it matters.
      result = Attrs.merge(data: { controller: %w[a b] })
      assert_equal "a b", result["data-controller"]
    end

    def test_false_is_preserved_not_dropped
      # Rails drops nil from data but renders false as the string "false".
      # Only an explicit nil should delete.
      result = Attrs.merge(data: { open: false })
      assert_equal false, result["data-open"]
    end

    def test_nil_inside_data_deletes
      result = Attrs.merge({ data: { open: true } }, { data: { open: nil } })
      refute result.key?("data-open")
    end

    # --- ordering ------------------------------------------------------------------

    def test_first_seen_order_is_preserved_in_unions
      result = Attrs.merge({ class: "z" }, { class: "a" }, { class: "m" })
      assert_equal "z a m", result["class"]
    end

    def test_nil_sources_are_ignored
      assert_equal({ "id" => "a" }, Attrs.merge(nil, { id: "a" }, nil))
    end

    def test_empty_merge
      assert_equal({}, Attrs.merge)
    end

    def test_arrow_syntax_survives_untouched
      # Escaping is the renderer's job. If we escaped here, a second merge would
      # double-escape and Stimulus would stop recognising the action.
      result = Attrs.merge(data: { action: "click->cw--disclosure#toggle" })
      assert_equal "click->cw--disclosure#toggle", result["data-action"]
    end
  end
end
