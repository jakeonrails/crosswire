# frozen_string_literal: true

require "crosswire/ui/component"
require "crosswire/ui/variants"

module Crosswire
  module UI
    # RULE 0: a button that only submits a form or navigates to a URL needs no
    # JavaScript at all — `button_to`/`f.submit`/`link_to` plus this presenter's
    # `_attrs` method is the whole story (see `button_helper.rb`'s `button_attrs`).
    # Reach for `cw.button`/`cw.button_for` only for the markup and styling; nothing
    # here ships a controller, and nothing here should ever need one.
    #
    # The worked example for the whole UI tier (ui-tier-spec.md §3/§6.2): the
    # smallest presenter that still earns its keep, because a plain `<button>` or
    # `<a class="btn">` gets three real accessibility guarantees wrong by default,
    # and this class is the one place that fixes all three so every renderer
    # (partial, hand-written ERB via `button_attrs`, a future ViewComponent) gets
    # them for free:
    #
    #   1. **`type="button"` by default.** An unstyled `<button>` inside a `<form>`
    #      submits it — the single most common accidental-submit bug in server-
    #      rendered apps. `cw.button` never guesses "submit"; pass `type: "submit"`
    #      explicitly (via `**overrides`) when that is actually what you want.
    #   2. **A disabled anchor drops its `href` and gains `role="link"` +
    #      `aria-disabled="true"`.** `<a>` has no native `disabled` attribute — an
    #      anchor with `href` removed is simply not a link to assistive tech at all
    #      (no role, not focusable), so the ARIA equivalent has to be restored by
    #      hand. Never emitting `href` at all is what actually prevents navigation;
    #      `aria-disabled` alone on an anchor that still carries `href` is a common
    #      but non-functional half-measure.
    #   3. **`aria-busy` travels with a bare `data-loading`.** `data-loading`
    #      (unprefixed, not `data-cw-loading`) is the same attribute name
    #      `Crosswire::Presenters::Loading`'s controller sets at runtime (D7a,
    #      docs/DECISIONS.md) — so a button rendered `loading: true` server-side (a
    #      page reloaded mid-job) and a button the `cw--loading` behaviour marks
    #      client-side end up in the exact same state, styled by the exact same
    #      `button.css` `[data-loading]` rule, with zero configuration either way.
    #
    # Variants: `variant` (primary/secondary/ghost/danger/link, default secondary),
    # `size` (sm/md/lg/icon, default md), `block` (boolean). See `Crosswire::UI::Variants`.
    #
    #   Crosswire::UI::Button.new(variant: :primary, size: :lg).attrs
    #   # => {"class" => "cw-button cw-button--primary cw-button--lg", "type" => "button"}
    #
    # Morph: Safe
    #   A button carries no DOM-only state of its own (no open/expanded/selected —
    #   just the variant classes and a11y attributes, all of which are re-rendered
    #   identically by any morph because they are pure functions of the presenter's
    #   constructor arguments). Nothing for a Turbo 8 morph to clobber or need to
    #   preserve.
    class Button < Component
      extend Variants

      base "cw-button"
      variant :variant, {
        primary: "cw-button--primary",
        secondary: nil,
        ghost: "cw-button--ghost",
        danger: "cw-button--danger",
        link: "cw-button--link"
      }, default: :secondary
      variant :size, {
        sm: "cw-button--sm",
        md: nil,
        lg: "cw-button--lg",
        icon: "cw-button--icon"
      }, default: :md
      boolean :block, "cw-button--block"

      attr_reader :variant, :size, :block, :href, :disabled, :loading

      # @param variant [Symbol] see `variant` declaration above
      # @param size [Symbol] see `variant` declaration above
      # @param block [Boolean] full-width button
      # @param href [String, nil] presence alone decides the tag: given a `href`,
      #   renders `<a>`; omitted, renders `<button>`. There is no separate `as:`
      #   switch — the one thing that decides "is this a link or a button" already
      #   tells you which tag it has to be.
      # @param disabled [Boolean] see accessibility guarantee 2 above
      # @param loading [Boolean] see accessibility guarantee 3 above
      # @param overrides [Hash] merged into the root element, last
      def initialize(variant: :secondary, size: :md, block: false, href: nil,
                     disabled: false, loading: false, **overrides)
        @variant = variant
        @size = size
        @block = block
        @href = href
        @disabled = !!disabled
        @loading = !!loading
        super(**overrides)
      end

      # `<a>` given a `href` (even a disabled one — an `<a>` never grows a
      # `disabled` attribute; the disabled STATE is real either way, only how it is
      # expressed differs), `<button>` otherwise.
      def tag_name = href ? :a : :button

      # `cw-focusable` opts into base.css's ONE shared `:focus-visible` ring
      # (`.cw-focusable:focus-visible { box-shadow: var(--cw-shadow-focus); }`) rather
      # than button.css declaring its own — that rule already exists for every future
      # interactive UI component to share (see base.css's own docstring). Appended
      # after the Variants-declared class order (base, then each variant/boolean in
      # declaration order — Variants rule 1) and before `overrides`, so a caller's
      # own `class:` still unions in last, per `Crosswire::Attributes.merge`.
      def attrs
        merge(
          { "class" => "#{self.class.variant_class(variant: variant, size: size, block: block)} cw-focusable" },
          element_attrs,
          state_attrs,
          overrides
        )
      end

      private

      # Guarantee 1 (button) and guarantee 2 (anchor).
      def element_attrs
        if href
          disabled ? { "role" => "link", "href" => nil } : { "href" => href }
        else
          { "type" => "button" }
        end
      end

      # Guarantee 2's other half (aria-disabled) and guarantee 3 (aria-busy +
      # bare data-loading). `disabled` and `aria-disabled` deliberately never both
      # appear — a `<button>` uses the native attribute; an `<a>` has none to use.
      def state_attrs
        out = {}
        out["disabled"] = true if disabled && !href
        out["aria-disabled"] = "true" if disabled && href

        if loading
          out["aria-busy"] = "true"
          # Bare — matches `Crosswire::Presenters::Loading`'s own runtime attribute
          # (D7a, docs/DECISIONS.md) so both compose against the same `[data-loading]`
          # CSS selector. `tag.attributes` renders an empty-string value with no `=`
          # content, not a Rails "boolean attribute" (that list is fixed and does not
          # include arbitrary `data-*` names) — `data-loading=""` is what's on the wire,
          # and `[data-loading]` matches it exactly as it would a truly bare attribute.
          out["data-loading"] = ""
        end

        out
      end
    end
  end
end
