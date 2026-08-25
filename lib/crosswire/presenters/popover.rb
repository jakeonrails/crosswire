# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Popover — a non-modal floating layer anchored to a trigger.
    #
    # RULE 0, read this first: the native Popover API (`popovertarget` on the
    # trigger + `popover="auto"` on the panel) already gives you light-dismiss,
    # Escape-to-close, and top-layer stacking (so the panel is never clipped by an
    # `overflow: hidden` ancestor) with ZERO JavaScript — this presenter emits
    # those attributes unconditionally, and for a large share of popovers
    # (tooltips, simple dropdowns, "About this user" cards) that is the entire
    # component. CSS anchor positioning (`anchor-name` / `position-anchor`) handles
    # PLACEMENT with equally zero JavaScript on engines that support it — this
    # presenter also emits those unconditionally, linking trigger and panel purely
    # through CSS, no JavaScript involved.
    #
    # Reach for `cw--popover`, the controller this presenter wires up, only for the
    # two things the platform doesn't yet give you everywhere:
    #
    #   1. Placement FALLBACK on an engine without CSS anchor positioning. Per
    #      research/notes/18-platform-primitives.md (verified against MDN,
    #      2026-08): anchor positioning's commonly-used properties are "newly
    #      available since January 2026" — all four engines ship the core
    #      properties, but the module is not fully Baseline (`position-anchor`
    #      itself shows only Firefox 151 in BCD, with no confirmed Chrome/Safari
    #      version). `strategy: "js"` (or an engine failing
    #      `CSS.supports("anchor-name", "--x")`) makes the controller compute
    #      placement by hand instead — a small fallback table, not a
    #      general-purpose positioning engine. See the controller docstring for
    #      why that deliberately does not mean pulling in Floating UI.
    #   2. Programmatic control — `show()`/`hide()`/`toggle()` called from other
    #      Stimulus code, rather than only ever a `popovertarget` click.
    #
    # `popover` itself is also NOT a safe default to reach for blind: MDN (2026-08)
    # marks it "newly available since Jan 2025" — not yet "widely available" — and
    # flags a live, UNRESOLVED Safari iOS bug where a popover cannot be dismissed
    # by a touch outside it. If you support iOS Safari today, verify light-dismiss
    # there before shipping; a non-modal `cw--dialog` (`modal: false`) is a
    # reasonable fallback shape if that bug blocks you.
    #
    # No `root_attrs` wraps trigger+panel in a shared element — unlike `dialog` or
    # `tabs`, `popovertarget`/`popover` is an attribute-level relationship the
    # browser resolves by id, so the two elements need no common ancestor at all,
    # and the controller lives entirely on the panel (see `panel_attrs`), which is
    # the only element it needs: the native `toggle` event it listens for fires
    # directly on the popover element itself, not on the trigger.
    #
    # Morph: Preserved
    #   DOM-only state: whether the panel is currently open. Unlike `dialog`, this
    #     controller declares no `open` Stimulus value at all — the native popover
    #     API's own top-layer membership IS the single source of truth (`cw--popover`'s
    #     own docstring: "STATE LIVES IN THE BROWSER, NOT A STIMULUS VALUE"), queried
    #     only via `matches(":popover-open")` when needed, never written by this
    #     controller (`toggled()` only ever reacts to the browser's own `toggle`
    #     event).
    #   On morph: because open/closed is not expressed as any DOM attribute, there is
    #     nothing for Idiomorph to patch and therefore nothing for it to get wrong —
    #     an attribute-patching morph over the SAME panel element (Idiomorph matches
    #     nodes and patches in place; it does not replace the element outright) simply
    #     never touches the browser's native top-layer state, so an open popover stays
    #     open through it with no controller intervention required. This is "preserved"
    #     by construction rather than by an active `usePreserve` guard — there is
    #     nothing here for that mechanism to name. `placement`/`offset`/`strategy` ARE
    #     ordinary Stimulus values, but they are pure, deterministic functions of the
    #     presenter's own constructor arguments, so a morph re-rendering them is a
    #     no-op, not a hazard.
    #   The app must: nothing beyond the ordinary rule for a Stimulus value — if the
    #     SAME panel element is ever replaced outright (not patched) by a morph, its
    #     native popover state is lost along with the node, same as any other
    #     browser-owned element state (scroll position, `:hover`) would be.
    class Popover < Presenter
      attr_reader :id, :placement, :offset, :strategy

      # @param id [String] the panel's id; the trigger derives its own id from it
      #   and the two are linked by `popovertarget`
      # @param placement [String] preferred side/alignment: "bottom-start"
      #   (default), "bottom-end", "top-start", "top-end", "left-start",
      #   "right-start" — used by the JS fallback positioner's placement table.
      # @param offset [Numeric] gap in pixels between trigger and panel, used by
      #   the JS fallback positioner.
      # @param strategy [String] "anchor" (default) — prefer native CSS anchor
      #   positioning, falling back to the JS positioner automatically when
      #   unsupported. "js" — always use the JS positioner.
      # @param overrides [Hash] merged into the panel element, last
      def initialize(id:, placement: "bottom-start", offset: 8, strategy: "anchor", **overrides)
        @id = id
        @placement = placement
        @offset = offset
        @strategy = strategy
        super(**overrides)
      end

      def trigger_id = "#{id}-trigger"

      # `popovertarget` is the entire wiring the browser needs — no data-controller,
      # no data-action. Per the HTML spec, the UA reflects the popover's open state
      # onto this element as an implicit ARIA relationship, so nothing here sets
      # `aria-expanded` by hand: doing so would just be a second, JS-free-to-desync
      # copy of what the browser already guarantees.
      def trigger_attrs(**extra)
        merge(
          {
            "id" => trigger_id,
            "type" => "button",
            "popovertarget" => id,
            "style" => "anchor-name: #{anchor_name};"
          },
          extra
        )
      end

      def panel_attrs(**extra)
        merge(
          controller_attrs,
          values(placement: placement, offset: offset, strategy: strategy, anchor: trigger_id),
          # `toggle` is the popover's OWN native event (a ToggleEvent, fired by the
          # browser for every state change — a popovertarget click, Escape,
          # light-dismiss, or a programmatic showPopover()/hidePopover()/
          # togglePopover() call) so it is wired without `->cw--popover#…`
          # translation ambiguity, the same way cw--dialog wires the native
          # `close`/`cancel` events.
          action("toggle->toggled"),
          {
            "id" => id,
            "popover" => "auto",
            "style" => "position-anchor: #{anchor_name};"
          },
          overrides,
          extra
        )
      end

      private

      # A CSS custom ident derived from the id, shared by trigger (`anchor-name`)
      # and panel (`position-anchor`) so the two are linked purely through CSS —
      # no JavaScript reads or writes this. Assumes `id` is already a valid HTML
      # id (the caller's responsibility, same as every other presenter here); most
      # HTML ids are already valid CSS custom-ident characters.
      def anchor_name = "--cw-popover-#{id}"
    end
  end
end
