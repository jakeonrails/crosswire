# frozen_string_literal: true

require "crosswire/ui/component"
require "crosswire/ui/variants"

module Crosswire
  module UI
    # RULE 0: a card is a grouping container, not a widget — if the whole card is a
    # single navigation target, Rule 0 still applies to WHAT makes it clickable (see
    # the interactive-card a11y doctrine below); nothing here ever ships a controller.
    #
    # The Slots proof for the whole UI tier (ui-tier-spec.md §2/§6.3): the first
    # component whose block can name MULTIPLE regions instead of being either "plain
    # text" or "one captured blob" — see `Crosswire::UI::Slots` for the mechanism
    # itself (arity-0 shorthand, one code path, never branch on `block.arity`).
    #
    #   <%= cw.card variant: :raised do |c| %>
    #     <% c.header { "Plan" } %>
    #     <% c.body { "Everything in Free, plus…" } %>
    #     <% c.footer { cw.button "Upgrade", variant: :primary } %>
    #   <% end %>
    #
    #   <%= cw.card { "No header or footer needed — the whole block is the body." } %>
    #
    # Variants: `variant` (plain/raised/outlined, default plain), `interactive`
    # (boolean). See `Crosswire::UI::Variants`.
    #
    # --- Interactive-card accessibility doctrine -------------------------------------
    #
    # `interactive: true` adds ONLY a hover-elevation and a `:focus-within` ring to the
    # card's own CSS (card.css) — it never adds `role`, `tabindex`, or a click handler
    # to the card's root element. A `<div>` (or any wrapper) with `role="button"` or
    # `tabindex="0"` slapped on it to make "the whole card clickable" is a well-known
    # a11y trap: it needs hand-rolled Enter/Space key handling to behave like a real
    # link or button (nothing here ships that JS — Rule 0), and if the card ALSO
    # contains a real `<a>` or `<button>` inside it (a "Read more" link, a menu
    # trigger), the wrapper becomes a second, redundant, worse-behaved interactive
    # element nested around a better one — the "nested interactive control" trap.
    #
    # The correct pattern (and the ONLY one crosswire ships or documents): put ONE
    # real `<a>` where the heading naturally lives — inside the header slot — and give
    # it `class="cw-card__link"`. `.cw-card__link::after { position: absolute; inset:
    # 0; }` (card.css) stretches that single anchor's hit area to cover the entire
    # `.cw-card--interactive` (which is `position: relative` for exactly this reason),
    # so clicking anywhere on the card activates that one real link — real link
    # semantics, native keyboard behaviour, one focusable stop, for free. Any OTHER
    # interactive element inside the card (e.g. a secondary button in the footer)
    # keeps working normally: give it `position: relative` of its own so it paints
    # above the stretched overlay. See `site/examples/card/interactive.html.erb` for
    # the worked-through markup.
    #
    # Morph: Safe
    #   A card carries no DOM-only state of its own (no open/expanded/selected) — its
    #   class list and slot contents are a pure function of the presenter's
    #   constructor arguments and the caller's block, so any morph re-renders it
    #   identically. (The real `<a>` inside an interactive card is an ordinary link;
    #   it has nothing for a morph to clobber either.)
    class Card < Component
      extend Variants

      base "cw-card"
      variant :variant, {
        plain: nil,
        raised: "cw-card--raised",
        outlined: "cw-card--outlined"
      }, default: :plain
      boolean :interactive, "cw-card--interactive"

      attr_reader :variant, :interactive

      # @param variant [Symbol] see `variant` declaration above
      # @param interactive [Boolean] see the a11y doctrine above — adds styling only,
      #   never role/tabindex/a click handler
      # @param overrides [Hash] merged into the root element, last
      def initialize(variant: :plain, interactive: false, **overrides)
        @variant = variant
        @interactive = !!interactive
        super(**overrides)
      end

      def root_attrs
        merge(
          { "class" => self.class.variant_class(variant: variant, interactive: interactive) },
          overrides
        )
      end

      def header_attrs(**extra) = merge({ "class" => "cw-card__header" }, extra)
      def body_attrs(**extra)   = merge({ "class" => "cw-card__body" }, extra)
      def footer_attrs(**extra) = merge({ "class" => "cw-card__footer" }, extra)
    end
  end
end
