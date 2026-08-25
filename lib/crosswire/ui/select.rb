# frozen_string_literal: true

require "crosswire/ui/component"
require "crosswire/ui/variants"

module Crosswire
  module UI
    # RULE 0, the exemplar the whole UI tier points back to (ui-tier-spec.md §5): a
    # native `<select>` already gives you keyboard handling (type-ahead, arrow keys),
    # a platform-native picker UI on mobile (a real wheel/sheet, not a div trying to
    # imitate one), built-in form participation (`required`, `:invalid`,
    # `FormData`), and screen-reader support no amount of `role="listbox"` +
    # `aria-activedescendant` markup fully reproduces. Rebuilding it — the instinct
    # every custom-dropdown component library eventually gives in to — trades all of
    # that for a component that now has to reimplement it badly. `cw.select` styles
    # the platform's own control and adds NO markup, NO controller, and NO option-
    # generation logic of its own: the `<option>` elements are whatever the caller
    # writes (plain ERB, `options_for_select`, a loop over an AR relation — crosswire
    # has no opinion), exactly the way `cw.button` renders a `<button>`/`<a>` instead
    # of inventing a third element that pretends to be one.
    #
    #   <%= cw.select name: "country" do %>
    #     <option value="us">United States</option>
    #     <option value="ca" selected>Canada</option>
    #   <% end %>
    #
    # Deliberately does NOT set `appearance: none` (select.css) — redrawing the
    # dropdown arrow is exactly the "rebuild the platform control" instinct this
    # class's whole docstring argues against; the native arrow already says
    # "this is a select" unambiguously, in every browser and OS, for free.
    #
    # `color-scheme: light dark` (tokens.css's `:root`, set in every light/dark
    # branch — see that file's own docstring) is load-bearing here specifically:
    # it is what makes the browser draw the native OPTION POPUP in a dark palette
    # when crosswire is in dark mode, instead of a jarring white dropdown floating
    # over a dark page. Nothing in select.rb or select.css sets it again — the
    # global already covers every `<select>` on the page, styled or not.
    #
    # `cw.select` shadows `ActionView::Helpers::FormOptionsHelper#select` INSIDE
    # `Crosswire::Builder` only — `cw.select(...)` always resolves to THIS helper,
    # never Rails' own `select(object, method, choices, ...)`. That is intentional
    # (`cw.<name>` is this tier's whole naming surface) and scoped: it has no effect
    # on a bare `select(...)` call from a view or a `FormBuilder` — those still reach
    # Rails' own method exactly as before, because Builder's `method_missing` is
    # never consulted for a name Builder itself defines. Any OTHER `Crosswire::UI`
    # helper module that genuinely needs Rails' `select` internally (none does today)
    # must call `view_context.select(...)` explicitly rather than a bare `select(...)`
    # — a bare call from inside a module mixed into `Builder` now resolves here
    # first. `test/crosswire/ui/select_test.rb` pins
    # `Crosswire::Builder.instance_method(:select).owner ==
    # Crosswire::UI::SelectHelper` so a future refactor cannot silently flip which
    # one wins.
    #
    # Morph: Server-owned
    #   DOM-only state: which `<option>` the browser currently shows as selected.
    #     Once a user (or script) has changed a `<select>`'s value, the browser does
    #     not keep re-deriving `.selectedIndex`/`.value` from each `<option>`'s
    #     `selected` HTML ATTRIBUTE — the attribute and the live IDL property can
    #     legitimately disagree from that point on. A DOM diff that patches the
    #     `selected` ATTRIBUTE onto the right `<option>` element is therefore not
    #     guaranteed to make the SELECT actually show that option as chosen.
    #   On morph: the server-rendered `<option selected>` in the new HTML is what
    #     must win. Turbo/idiomorph's own morph (`morphElements`) patches attributes
    #     correctly; the risk this verdict names is specifically whether the LIVE
    #     `.value` visibly follows that patched attribute for a `<select>` whose
    #     value has already diverged client-side — the same class of gap
    #     `Crosswire::UI::Select`'s sibling primitive `cw--preserve` exists to close
    #     for CONTROLLER-owned values, except here there is no controller to run
    #     `usePreserve` at all (select ships none — Rule 0). See
    #     `test/js/select.browser.test.js` for the proof against real
    #     `@hotwired/turbo`, not jsdom.
    #   The app must: always render the CURRENTLY correct `selected` option
    #     server-side on every response that could be followed by a morph (a
    #     redirect-after-submit, a Turbo Stream update) — never rely on the client
    #     to remember a selection across one. The value named here is exactly one
    #     thing: which `<option>` carries the `selected` attribute in the HTML the
    #     server sends.
    class Select < Component
      extend Variants

      base "cw-select"
      variant :size, {
        sm: "cw-select--sm",
        md: nil,
        lg: "cw-select--lg"
      }, default: :md

      attr_reader :size, :invalid, :loading

      # @param size [Symbol] see `variant` declaration above
      # @param invalid [Boolean] sets `aria-invalid="true"` — same attribute-not-
      #   class reasoning as `Crosswire::UI::Input#invalid`
      # @param loading [Boolean] sets bare `data-loading` (same convention as
      #   `Crosswire::UI::Button`/`Crosswire::UI::Input`)
      # @param overrides [Hash] merged into the root element, last — pass
      #   `multiple: true`, `name:`, `required:`, etc. here; crosswire adds no
      #   opinion of its own about any native `<select>` attribute
      def initialize(size: :md, invalid: false, loading: false, **overrides)
        @size = size
        @invalid = !!invalid
        @loading = !!loading
        super(**overrides)
      end

      def attrs
        merge(
          { "class" => "#{self.class.variant_class(size: size)} cw-focusable" },
          state_attrs,
          overrides
        )
      end

      private

      def state_attrs
        out = {}
        out["aria-invalid"] = "true" if invalid
        out["data-loading"] = "" if loading
        out
      end
    end
  end
end
