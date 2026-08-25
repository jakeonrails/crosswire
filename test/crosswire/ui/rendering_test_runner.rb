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
    #
    # `kind: :css` names (dialog/popover/menu/combobox — spec §2b) are deliberately
    # EXCLUDED from every loop below: they ship no NEW presenter for `Crosswire::UI`
    # to render generically, most have required constructor keywords no "defaults"
    # call could satisfy (`Menu#id`/`#items`, `Combobox#id`/`#name`, `Popover#id`,
    # `Dialog#id`), and `cw.popover`'s own bare render form has no single wrapping
    # root at all by design (trigger and panel are documented siblings — see
    # `Crosswire::Presenters::Popover`'s own docstring) — so "the root element carries
    # `cw-<name>`" is not even a claim that applies to it. These four widgets already
    # have their own real-DOM render coverage in the PRIMITIVE tier's own suites; spec
    # §7.3 is explicit that dialog/menu/popover browser tests exist and this tier must
    # not duplicate them — styling changed no semantics.
    UI_ONLY_NAMES = Crosswire::UI.component_names.reject { |name| Crosswire::UI.css_only?(name) }.freeze

    BASE_CLASS = UI_ONLY_NAMES.index_with { |name| "cw-#{name}" }.freeze

    def test_every_ui_component_renders_with_defaults
      UI_ONLY_NAMES.each do |name|
        args = REQUIRED_DEFAULTS.fetch(name, {})

        html = view.cw.public_send(name, **args)

        refute_empty html.to_s.strip, "#{name}: rendered empty output"
      end
    end

    def test_the_root_element_carries_the_components_base_class
      UI_ONLY_NAMES.each do |name|
        args = REQUIRED_DEFAULTS.fetch(name, {})
        html = view.cw.public_send(name, **args)

        assert_includes tokens(root_of(html), "class"), BASE_CLASS.fetch(name),
                        "#{name}: root element missing base class #{BASE_CLASS.fetch(name).inspect}"
      end
    end

    def test_a_callers_own_class_survives_onto_the_root_element
      UI_ONLY_NAMES.each do |name|
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

  # ---------------------------------------------------------------------------------
  # Alert's composition showcase, in real rendered DOM (ui-tier-spec.md §5 item 7):
  # the dismiss button renders only when asked for, and — the one thing a presenter
  # unit test cannot see without a real ActionView `id`/`for` cycle — its `aria-label`
  # actually resolves on a real element in the tree.
  # ---------------------------------------------------------------------------------
  class AlertRenderTest < HelperCase
    def test_not_dismissible_renders_no_dismiss_button
      html = view.cw.alert("Draft saved.")
      root = dom(html).at_css(".cw-alert")

      assert_nil root.at_css(".cw-alert__dismiss")
      assert_equal "Draft saved.", root.at_css(".cw-alert__body").text.strip
    end

    def test_dismissible_renders_a_labelled_dismiss_button
      html = view.cw.alert("Only 2 left.", severity: :warning, dismissible: true)
      root = dom(html).at_css(".cw-alert")
      button = root.at_css(".cw-alert__dismiss")

      refute_nil button
      assert_equal "button", button["type"]
      assert_equal "Dismiss", button["aria-label"]
      assert_equal "click->cw--dismiss#dismiss", button["data-action"]
    end

    def test_role_reflects_severity_in_real_dom
      assert_equal "status", dom(view.cw.alert("x", severity: :success)).at_css(".cw-alert")["role"]
      assert_equal "alert", dom(view.cw.alert("x", severity: :danger)).at_css(".cw-alert")["role"]
    end
  end

  # ---------------------------------------------------------------------------------
  # Toast's two-part composite, in real rendered DOM: the container's live-region
  # attributes land on a real element, and a toast rendered inside its block actually
  # ends up nested inside that container carrying all three composed controllers.
  # ---------------------------------------------------------------------------------
  class ToastRenderTest < HelperCase
    def test_viewport_renders_the_live_region_container_attrs
      html = view.cw.toast_viewport
      root = dom(html).at_css(".cw-toast-viewport")

      assert_equal "cw-toast-viewport", root["id"]
      assert_equal "status", root["role"]
      assert_equal "polite", root["aria-live"]
      assert_equal "", root["data-turbo-permanent"]
    end

    def test_a_toast_rendered_inside_the_viewport_block_lands_inside_the_container
      html = view.cw.toast_viewport { view.cw.toast("Saved!", severity: :success) }
      container = dom(html).at_css(".cw-toast-viewport")
      toast = container.at_css(".cw-toast")

      refute_nil toast
      assert_includes tokens(toast, "class"), "cw-toast--success"
      assert_equal "Saved!", toast.at_css(".cw-toast__body").text.strip
      tokens(toast, "data-controller").tap do |controllers|
        assert_equal %w[cw--dismiss cw--timeout cw--transition], controllers
      end
    end

    def test_toast_carries_no_role_or_aria_live_of_its_own
      html = view.cw.toast("Saved!")
      root = dom(html).at_css(".cw-toast")

      assert_nil root["role"]
      assert_nil root["aria-live"]
    end
  end
end
