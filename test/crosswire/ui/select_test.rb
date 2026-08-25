# frozen_string_literal: true

require "test_helper"
require "crosswire/ui/select"

# `Crosswire::Builder`'s class body (`lib/crosswire/builder.rb`) includes every
# per-component helper module BY CONSTANT NAME — `Crosswire.const_get(:"#{...}Helper")`
# — which normally resolves through Zeitwerk autoloading inside a booted Rails app.
# This suite is deliberately Rails-free (see the class docstring below on why that
# matters), so those constants have to be `require`d by hand before `crosswire/builder`
# itself, exactly the sequence `ui_contract_audit_test.rb#load_builder_with_every_helper!`
# uses (that file re-derives it at test-run time via `load`, not file-load time via
# `require`, because it also needs to prove the UI-tier `include` loop specifically —
# this file only needs `Crosswire::Builder` to exist at all, so plain, idempotent
# `require` is enough and does not fight that file's own `load` calls). Excludes
# `facade_helper.rb`, which itself `require`s `crosswire/builder` — the one file this
# bootstrap exists to load in the first place.
Dir[File.expand_path("../../../app/helpers/crosswire/*_helper.rb", __dir__)].sort.each do |path|
  require path unless File.basename(path) == "facade_helper.rb"
end
require "crosswire/builder"

module Crosswire
  module UI
    # Presenter unit suite (ui-tier-spec.md §7.1), plus the one structural pin the
    # spec calls out by name for this component specifically: `cw.select` shadows
    # `ActionView::Helpers::FormOptionsHelper#select` inside `Crosswire::Builder` —
    # see `Crosswire::UI::Select`'s own docstring for the full explanation. This
    # suite needs no Rails at all: `Crosswire::Builder` never calls into ActionView
    # itself at load time — only `method_missing` reaches for the view context,
    # lazily, at render time — so the manual `require` bootstrap above is sufficient.
    class SelectTest < Minitest::Test
      def test_default_class_string
        assert_equal "cw-select cw-focusable", Select.new.attrs["class"]
      end

      def test_every_size_value
        {
          sm: "cw-select cw-select--sm cw-focusable",
          md: "cw-select cw-focusable",
          lg: "cw-select cw-select--lg cw-focusable"
        }.each do |size, expected|
          assert_equal expected, Select.new(size: size).attrs["class"], "size #{size.inspect}"
        end
      end

      def test_unknown_size_raises_naming_valid_values
        error = assert_raises(ArgumentError) { Select.new(size: :huge).attrs }

        assert_match(/huge/, error.message)
        %w[sm md lg].each { |v| assert_match(/#{v}/, error.message) }
      end

      def test_invalid_sets_aria_invalid_true
        assert_equal "true", Select.new(invalid: true).attrs["aria-invalid"]
      end

      def test_not_invalid_carries_no_aria_invalid
        refute Select.new.attrs.key?("aria-invalid")
      end

      def test_loading_sets_bare_data_loading
        assert_equal "", Select.new(loading: true).attrs["data-loading"]
      end

      def test_not_loading_carries_no_data_loading
        refute Select.new.attrs.key?("data-loading")
      end

      # Rule 0: crosswire never sets `multiple`/`name`/`required`/etc. itself — a
      # caller passes whatever native `<select>` attribute they want straight
      # through `overrides`, unmodified.
      def test_native_select_attributes_pass_through_overrides_untouched
        attrs = Select.new(multiple: true, name: "country", required: true).attrs

        assert_equal true, attrs["multiple"]
        assert_equal "country", attrs["name"]
        assert_equal true, attrs["required"]
      end

      def test_caller_class_composes_after_ours
        assert_equal "cw-select cw-focusable extra", Select.new(class: "extra").attrs["class"]
      end

      def test_caller_class_bang_replaces_ours
        assert_equal "only-mine", Select.new("class!" => "only-mine").attrs["class"]
      end

      def test_variants_introspection
        assert_equal({ size: { values: %i[sm md lg], default: :md } }, Select.variants)
      end

      def test_overrides_do_not_clobber_computed_attributes
        attrs = Select.new(size: :lg, data: { controller: "dirty-form" }).attrs

        assert_equal "cw-select cw-select--lg cw-focusable", attrs["class"]
        assert_equal "dirty-form", attrs["data-controller"]
      end

      # --- the shadow pin ---------------------------------------------------------------
      #
      # `Crosswire::UI.component_names.each { include ... }` in builder.rb runs AFTER
      # the primitive-tier loop, so `Crosswire::UI::SelectHelper` sits closer to
      # `Crosswire::Builder` in the ancestor chain than anything included before it —
      # Ruby's normal method lookup finds `SelectHelper#select` directly and never
      # falls through to `method_missing`'s `view_context.select` forwarding at all.
      # If a future refactor ever reordered those two `include` loops, or renamed
      # `SelectHelper#select` to something that stopped colliding with ActionView's
      # own `select`, this is the test that would catch it.
      def test_cw_select_shadows_action_views_select_inside_the_builder
        assert_equal Crosswire::UI::SelectHelper,
                     Crosswire::Builder.instance_method(:select).owner,
                     "Crosswire::Builder#select should resolve to Crosswire::UI::SelectHelper, " \
                     "not to whatever ActionView's own #select would have been forwarded to"
      end
    end
  end
end
