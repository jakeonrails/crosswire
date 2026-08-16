# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Timeout — dispatch an action once, N ms after connect or after a trigger.
    #
    # Sits beside `interval`, not on top of it: `interval` re-arms itself and keeps
    # ticking until stopped, `timeout` fires once and never re-arms on its own — a
    # toast's auto-dismiss and a "resend code in 30s" cooldown want `timeout`; a
    # polling `<turbo-frame>` or a live countdown tick wants `interval`. Reach for
    # `restart` (below) when you want "fire once, but the clock can be pushed back,"
    # which is the toast-on-hover-pause shape without needing `interval`'s repetition.
    #
    # No Rule 0 here: there is no platform primitive for "run this once, later," short
    # of a bare `setTimeout` — which is exactly what this wraps, plus Turbo-aware
    # teardown and pausing while the tab is hidden.
    #
    # A behaviour, not a widget — it decorates whatever element it is placed on and
    # ships no partial (docs/COMPONENT_CONTRACT.md). It has no trigger markup of its
    # own; wire `start`/`cancel`/`restart` onto whatever elements or events should
    # control it, e.g. `data-action="mouseenter->cw--timeout#cancel"`.
    class Timeout < Presenter
      attr_reader :delay, :start_on_connect

      # @param delay [Numeric] milliseconds to wait before dispatching `elapsed`.
      #   Required — there is no sensible default duration for "wait, then do
      #   something."
      # @param start_on_connect [Boolean] arm the timer as soon as the controller
      #   connects. Set false when the timer should only ever be started by an
      #   explicit `start` action (e.g. an inline editor that starts its own
      #   auto-save timeout only once the user has actually typed something).
      # @param overrides [Hash] merged into the root element, last
      def initialize(delay:, start_on_connect: true, **overrides)
        @delay = delay
        @start_on_connect = !!start_on_connect
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(delay: delay, start_on_connect: start_on_connect),
          overrides
        )
      end
    end
  end
end
