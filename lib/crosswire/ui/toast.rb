# frozen_string_literal: true

require "crosswire/ui/component"
require "crosswire/ui/variants"
require "crosswire/presenters/dismiss"
require "crosswire/presenters/timeout"
require "crosswire/presenters/transition"

module Crosswire
  module UI
    # RULE 0: read `Crosswire::UI::Alert`'s docstring first — this is the SAME
    # composition showcase, one tier heavier. `skills/crosswire-composing/RECIPES.md`'s
    # "Toast / flash message" recipe stacks `cw--dismiss` + `cw--transition` +
    # `cw--timeout` on one element by hand; this presenter is that recipe, shipped —
    # `root_attrs` is nothing but the same three presenters' own `root_attrs` merged
    # onto one root, plus the `data-action` lines that wire the moments BETWEEN them
    # (R5a mechanism 3: react to a stacked sibling's own namespaced event):
    #
    #   merge(
    #     { "class" => ... },
    #     @dismiss&.root_attrs,
    #     @timeout&.root_attrs,
    #     @transition.root_attrs,
    #     @transition.leave_on,                                 # cw--dismiss:dismissing->cw--transition#leave
    #     { "data-action" => "mouseenter->cw--timeout#cancel mouseleave->cw--timeout#restart " \
    #                        "cw--timeout:elapsed->cw--dismiss#dismiss" },
    #     overrides
    #   )
    #
    # What THIS class adds over hand-rolling the recipe: the pause-on-hover wiring
    # (`mouseenter`/`mouseleave`) travels with `timeout:`, not something a caller
    # re-derives per toast; a `dismissible: false` or `timeout: nil` toast composes
    # only the pieces it actually needs (see `initialize` below) rather than always
    # shipping all three regardless of what was asked for.
    #
    # Composes a `severity` variant purely for VISUAL styling (toast.css) — it decides
    # colour only, never `role`/`aria-live`. A toast item carries NEITHER: putting a
    # role or `aria-live` on the item itself would be a SECOND, competing live region
    # nested inside `Crosswire::UI::ToastViewport`'s one real live-region container,
    # and nested live regions are exactly the "which one do I announce from" trap the
    # container exists to avoid. The container announces every insertion into it by
    # DOM mutation alone — that is the entire mechanism, and it is why the container
    # must exist, with its `aria-live` already set, before any toast is ever inserted
    # (see `Crosswire::UI::ToastViewport`'s own docstring — "the aria-live rule from
    # the corpus").
    #
    # --- the two rendering paths --------------------------------------------------
    #
    # 1. Server-rendered flash toasts — render `cw.toast` INSIDE the block passed to
    #    `cw.toast_viewport`, on the same response that renders the container itself:
    #
    #      <%= cw.toast_viewport do %>
    #        <% flash.each do |type, message| %>
    #          <%= cw.toast message, severity: severity_for(type) %>
    #        <% end %>
    #      <% end %>
    #
    # 2. Turbo-Stream-appended toasts — the container already exists (rendered once in
    #    the layout, `data-turbo-permanent`; see `Crosswire::UI::ToastViewport`), so a
    #    LATER response only ever needs to append into it. The whole controller-side
    #    story is one line:
    #
    #      # app/controllers/orders_controller.rb
    #      def create
    #        @order.save!
    #        render turbo_stream: turbo_stream.append(
    #          Crosswire::UI::ToastViewport::DEFAULT_ID) { cw.toast("Order placed.", severity: :success) }
    #      end
    #
    # Morph: Excluded
    #   DOM-only state: which toasts currently exist in the viewport, and each one's
    #     live `cw--timeout` timer (paused/remaining, armed by hover) and any in-flight
    #     `cw--transition` leave animation. None of that has a server-side
    #     representation at all — a toast is never re-derived from a page's own
    #     instance variables the way, say, a flash `<div>` embedded in the page body
    #     is; it is either rendered once at the moment it was pushed (path 1 above) or
    #     appended once via a Turbo Stream (path 2) and never again.
    #   On morph: `Crosswire::UI::ToastViewport`'s shipped partial carries
    #     `data-turbo-permanent`, which — proven in `test/js/toast.browser.test.js`
    #     against real `@hotwired/turbo`, not merely asserted — a bare `morphElements()`
    #     call already honours on its own: `data-turbo-permanent` is checked inside
    #     `DefaultIdiomorphCallbacks`, the callback object `morphElements()` itself
    #     constructs internally, not something layered on only by Turbo's page-level
    #     renderer. A permanent node is skipped by the morph entirely — idiomorph never
    #     compares its children against the incoming HTML at all — so every toast
    #     inside it, and every live timer/transition driving one, survives a page-level
    #     morph completely untouched. See docs/BUILD-LOG.md for the full finding.
    #   The app must: give the viewport a STABLE id across responses (the whole reason
    #     `data-turbo-permanent` id-matches at all) and never rely on server-rendered
    #     HTML to describe which toasts are currently showing — the container's
    #     CONTENTS are the only source of truth once the page has loaded, exactly like
    #     `data-turbo-permanent`'s other shipped use (`cw--autosubmit`'s search box).
    class Toast < Component
      extend Variants

      base "cw-toast"
      variant :severity, {
        neutral: nil,
        info: "cw-toast--info",
        success: "cw-toast--success",
        warning: "cw-toast--warning",
        danger: "cw-toast--danger"
      }, default: :neutral

      attr_reader :severity, :dismissible, :timeout

      # @param severity [Symbol] see `variant` declaration above — styling only, see
      #   the docstring above for why this never touches role/aria-live
      # @param dismissible [Boolean] compose `cw--dismiss` (and, with it, the
      #   `cw--dismiss:dismissing->cw--transition#leave` wiring) onto the root element
      # @param timeout [Numeric, nil] milliseconds before auto-dismiss; `nil` composes
      #   no `cw--timeout` at all (a toast that only ever leaves via an explicit
      #   dismiss or a Turbo Stream `remove`)
      # @param overrides [Hash] merged into the root element, last
      def initialize(severity: :neutral, dismissible: true, timeout: 5000, **overrides)
        @severity = severity
        @dismissible = !!dismissible
        @timeout = timeout
        @dismiss = Crosswire::Presenters::Dismiss.new(label: "Dismiss") if @dismissible
        @timeout_presenter = Crosswire::Presenters::Timeout.new(delay: timeout) if timeout
        # The leave sequence only ever runs when something can dismiss the toast in
        # the first place — tied to @dismiss's presence, not declared unconditionally,
        # same reasoning `Crosswire::UI::Alert` does NOT apply here (an alert has no
        # timeout to race against; a toast without `cw--dismiss` has nothing that ever
        # dispatches the cancelable `dismissing` event `leave_on` listens for).
        @transition = if @dismiss
                        Crosswire::Presenters::Transition.new(
                          leave: "cw-toast--leaving",
                          leave_from: "cw-toast--leave-from",
                          leave_to: "cw-toast--leave-to"
                        )
                      end
        super(**overrides)
      end

      def root_attrs
        merge(
          { "class" => self.class.variant_class(severity: severity) },
          @dismiss ? @dismiss.root_attrs : {},
          @timeout_presenter ? @timeout_presenter.root_attrs : {},
          @transition ? @transition.root_attrs : {},
          @transition ? @transition.leave_on : {},
          composed_action_attrs,
          overrides
        )
      end

      # The composed `cw--dismiss` trigger's attributes — only meaningful when
      # `dismissible: true`. Same "raise rather than render a dead button" reasoning
      # as `Crosswire::UI::Alert#dismiss_trigger_attrs`.
      def dismiss_trigger_attrs(**extra)
        raise ArgumentError, "#{self.class}: dismiss_trigger_attrs called but dismissible: false" unless @dismiss

        @dismiss.trigger_attrs(**extra)
      end

      private

      # The moments BETWEEN the composed controllers (R5a mechanism 3) — none of this
      # belongs to any one presenter, because it is the SEAM between them, not either
      # side's own concern. `mouseenter`/`mouseleave` pause/resume the timer whenever
      # one is composed, independent of whether dismiss is; the timer's `elapsed` only
      # wires to `cw--dismiss#dismiss` when both are present, or the action would name
      # a controller that was never composed onto this element.
      def composed_action_attrs
        return {} unless @timeout_presenter

        specs = ["mouseenter->cw--timeout#cancel", "mouseleave->cw--timeout#restart"]
        specs << "cw--timeout:elapsed->cw--dismiss#dismiss" if @dismiss
        { "data-action" => specs.join(" ") }
      end
    end
  end
end
