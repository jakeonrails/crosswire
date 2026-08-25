# frozen_string_literal: true

# The real render-integration suite for the UI tier (ui-tier-spec.md §7.2) — every
# registered `Crosswire::UI` component rendered through a REAL `ActionView` context,
# under a REAL Rails boot. The presenter unit suites (`test/crosswire/ui/*_test.rb`,
# no Rails) already pin every class string and attribute a presenter computes; what
# they cannot see is whether the PARTIAL actually renders that into HTML the way the
# presenter promises, and — the reason this file exists as its own suite rather than
# folding into `bin/build_gallery.rb`'s coverage — whether `Crosswire::UI::Slots`'
# capture-and-record mechanism actually produces the right DOM for each of card's
# four header/body/footer combinations. The gallery renders ONE example per
# combination for human eyes; it asserts nothing and is not a substitute for this.
#
# This file is NOT named `*_test.rb` on purpose and is never `require`d in-process —
# cloned from `test/crosswire/integration_test_runner.rb`, which explains the
# subprocess boundary itself (short version: `test/test_helper.rb` guarantees the
# presenter suite never sees Rails, and booting Rails anywhere in that shared process
# would break every sibling's `refute defined?(::Rails)`). `test/crosswire/ui/
# rendering_test.rb` runs this as its own child process and fails loudly if it fails.
#
# Run it directly and it behaves as an ordinary, self-contained Minitest suite:
#
#   bundle exec ruby test/crosswire/ui/rendering_test_runner.rb

ENV["RAILS_ENV"] = "test"

require File.expand_path("../../dummy/config/environment", __dir__)
require "rails/test_help"
require "minitest/autorun"
require "nokogiri"

module CrosswireUIRendering
  module Dom
    def dom(html)
      Nokogiri::HTML5.fragment(html.to_s)
    end

    def root_of(html)
      dom(html).at_css("*") || flunk("no element in:\n\n#{html}")
    end

    def tokens(node, attribute)
      node[attribute].to_s.split(/\s+/)
    end
  end

  # Mirrors what a consumer's ApplicationController gets automatically — the
  # engine's own `crosswire.helpers` initializer includes exactly these two modules
  # into `ActionView::Base` globally. Every per-component helper is reached THROUGH
  # the builder (`view.cw.card`, never `view.card`), so there is nothing else to mix
  # in here.
  class HelperCase < ActionView::TestCase
    include Dom

    helper Crosswire::AttributesHelper
    helper Crosswire::FacadeHelper
  end

  # ---------------------------------------------------------------------------------
  # Every registered component: renders with defaults, root carries the base class,
  # caller class survives.
  # ---------------------------------------------------------------------------------
  class DefaultsRenderTest < HelperCase
    # A handful of components have a required constructor argument (`Field#id`) —
    # everything else renders with zero arguments, exactly the "defaults" spec §7.2
    # asks for.
    REQUIRED_DEFAULTS = {
      "field" => { id: "email" }
    }.freeze

    # Every shipped component's root class follows the same `cw-<name>` convention.
    # Computed here rather than introspected from `Crosswire::UI.const_get(name).base`,
    # so this test pins the actual shipped convention, not whatever a presenter
    # happens to compute: a component that quietly renamed its own base class would
    # still make THIS test fail.
    BASE_CLASS = Crosswire::UI.component_names.index_with { |name| "cw-#{name}" }.freeze

    def test_every_ui_component_renders_with_defaults
      Crosswire::UI.component_names.each do |name|
        args = REQUIRED_DEFAULTS.fetch(name, {})

        html = view.cw.public_send(name, **args)

        refute_empty html.to_s.strip, "#{name}: rendered empty output"
      end
    end

    def test_the_root_element_carries_the_components_base_class
      Crosswire::UI.component_names.each do |name|
        args = REQUIRED_DEFAULTS.fetch(name, {})
        html = view.cw.public_send(name, **args)

        assert_includes tokens(root_of(html), "class"), BASE_CLASS.fetch(name),
                        "#{name}: root element missing base class #{BASE_CLASS.fetch(name).inspect}"
      end
    end

    def test_a_callers_own_class_survives_onto_the_root_element
      Crosswire::UI.component_names.each do |name|
        args = REQUIRED_DEFAULTS.fetch(name, {}).merge(class: "caller-class")
        html = view.cw.public_send(name, **args)

        assert_includes tokens(root_of(html), "class"), "caller-class",
                        "#{name}: root element lost the caller's own class"
      end
    end
  end

  # ---------------------------------------------------------------------------------
  # Card's four slot combinations (ui-tier-spec.md §7.2) — the actual proof that
  # `Crosswire::UI::Slots`' single code path (capture the whole block, ask
  # afterwards which slots got recorded) produces the right DOM, not just the right
  # Ruby-level `slots[:body]`/`slots.any?` values the presenter unit suite cannot
  # observe without a view context to `capture` into.
  # ---------------------------------------------------------------------------------
  class CardSlotsRenderTest < HelperCase
    def test_arity_zero_shorthand_the_whole_block_is_the_body_no_header_or_footer
      html = view.cw.card { "Just text.".html_safe }
      root = dom(html).at_css(".cw-card")

      assert_nil root.at_css(".cw-card__header")
      assert_nil root.at_css(".cw-card__footer")
      assert_equal "Just text.", root.at_css(".cw-card__body").text.strip
    end

    def test_header_and_body_named_no_footer
      html = view.cw.card do |c|
        c.header { "Plan".html_safe }
        c.body { "Everything in Free.".html_safe }
      end
      root = dom(html).at_css(".cw-card")

      assert_equal "Plan", root.at_css(".cw-card__header").text.strip
      assert_equal "Everything in Free.", root.at_css(".cw-card__body").text.strip
      assert_nil root.at_css(".cw-card__footer")
    end

    def test_body_and_footer_named_no_header
      html = view.cw.card do |c|
        c.body { "Everything in Free.".html_safe }
        c.footer { "Upgrade".html_safe }
      end
      root = dom(html).at_css(".cw-card")

      assert_nil root.at_css(".cw-card__header")
      assert_equal "Everything in Free.", root.at_css(".cw-card__body").text.strip
      assert_equal "Upgrade", root.at_css(".cw-card__footer").text.strip
    end

    def test_header_body_and_footer_all_three_named
      html = view.cw.card do |c|
        c.header { "Plan".html_safe }
        c.body { "Everything in Free.".html_safe }
        c.footer { "Upgrade".html_safe }
      end
      root = dom(html).at_css(".cw-card")

      assert_equal "Plan", root.at_css(".cw-card__header").text.strip
      assert_equal "Everything in Free.", root.at_css(".cw-card__body").text.strip
      assert_equal "Upgrade", root.at_css(".cw-card__footer").text.strip
    end
  end
end
