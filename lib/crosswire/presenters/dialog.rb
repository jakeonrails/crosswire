# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # WAI-ARIA APG: Dialog (Modal)
    # https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/
    #
    # Rule 0: this drives the native `<dialog>` element on purpose. `showModal()` makes
    # the rest of the document `inert` and handles Escape for free, so the controller
    # does NOT hand-roll a focus trap or a backdrop div inside a modal dialog — reach
    # for `cw--focus-trap` only for non-modal panels (drawers, toolbars) that cannot use
    # `<dialog>` at all. `<dialog>`'s implicit ARIA role ("dialog") is correct in both
    # modal and non-modal mode, so nothing here adds `role="dialog"` by hand.
    #
    # `<dialog>` does not do everything for free, though, and the controller exists to
    # cover exactly the gaps:
    #
    #   * scroll lock — NOT free. whatwg/html#7732 is open since 2022; the page behind
    #     an open modal still scrolls unless the controller locks it, compensating for
    #     scrollbar width via `scrollbar-gutter` so the page does not shift.
    #   * focus restore on close — NOT free. The controller saves `document.activeElement`
    #     before opening and restores it on close.
    #   * light dismiss — the `closedby` attribute is NOT Baseline (Safari has not
    #     shipped it), so click-outside-to-close is implemented by hand, gated by the
    #     `dismissable` value, rather than delegated to the platform.
    #   * Turbo morph — Turbo 8 morphing strips the `open` attribute from `<dialog>`, and
    #     per spec removing `open` this way does NOT call `close()`. That leaves the
    #     document permanently inert with `close()` reduced to a silent no-op. The
    #     controller defends against this; see its docstring.
    #
    # Composes with `cw--dismiss` for an alternate close trigger and `cw--focus-trap`
    # only if you eject the markup into something that is not a native `<dialog>`.
    class Dialog < Presenter
      attr_reader :id, :open, :modal, :dismissable

      # @param id [String] base id; the panel and title derive theirs from it
      # @param open [Boolean] initial state, rendered server-side so it is correct
      #   before JavaScript loads and survives a morph
      # @param modal [Boolean] use `showModal()` (true, default) vs `show()` (false).
      #   A non-modal dialog gets no inertness, no top-layer, no `::backdrop` — the
      #   controller still locks scroll and restores focus, but never light-dismisses.
      # @param dismissable [Boolean] allow light-dismiss (click on the backdrop closes)
      # @param title [String, nil] accessible name, rendered as a heading and wired to
      #   `aria-labelledby` automatically. Omit and pass `labelled_by:` if you supply
      #   your own heading markup.
      # @param labelled_by [String, nil] id of the element that labels the dialog;
      #   overrides the id `title` would have produced
      # @param described_by [String, nil] id of the element that describes the dialog
      # @param overrides [Hash] merged into the root element, last
      def initialize(id:, open: false, modal: true, dismissable: true, title: nil,
                      labelled_by: nil, described_by: nil, **overrides)
        @id = id
        @open = !!open
        @modal = !!modal
        @dismissable = !!dismissable
        @title = title
        @labelled_by = labelled_by || (title ? title_id : nil)
        @described_by = described_by
        super(**overrides)
      end

      def title_id = "#{id}-title"

      def root_attrs
        merge(
          controller_attrs,
          values(open: open, modal: modal, dismissable: dismissable),
          overrides
        )
      end

      def trigger_attrs(**extra)
        merge(
          target(:trigger),
          action("click->open"),
          { "type" => "button", "aria-haspopup" => "dialog", "aria-controls" => id },
          extra
        )
      end

      def panel_attrs(**extra)
        merge(
          target(:panel),
          action(*panel_actions),
          {
            "id" => id,
            "open" => open,
            "aria-labelledby" => @labelled_by,
            "aria-describedby" => @described_by
          },
          extra
        )
      end

      def close_attrs(**extra)
        merge(
          action("click->close"),
          { "type" => "button", "aria-label" => "Close" },
          extra
        )
      end

      def title_attrs(**extra)
        merge({ "id" => title_id }, extra)
      end

      private

      # `close` and `cancel` are the DIALOG'S OWN native events (Escape fires `cancel`
      # then `close`; so does `dialog.close()` and `<form method="dialog">`), so they
      # are wired without `->cw--dialog#…` translation ambiguity — `action()` expands
      # `event->method` the same way regardless of whether the event name happens to
      # collide with an ARIA/HTML term. Click-on-backdrop is only ever a click landing
      # on the `<dialog>` element itself, never a descendant, so one listener on the
      # panel is enough. The two Turbo hooks defend the morph and cache hazards
      # documented on the controller.
      def panel_actions
        %w[
          close->syncClosed
          cancel->cancel
          click->backdropClick
          turbo:before-morph-element->beforeMorph
          turbo:before-cache->reset
        ]
      end
    end
  end
end
