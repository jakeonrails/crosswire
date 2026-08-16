# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Interval — dispatch a `tick` every N milliseconds while the document is
    # visible.
    #
    # Sits beside `timeout`, not on top of it: `timeout` fires ONCE and never
    # re-arms itself; this re-arms on every tick and keeps going until the
    # controller disconnects. A "resend code in 30s" cooldown or a toast's
    # auto-dismiss wants `timeout`; a polling `<turbo-frame>`, a progress bar for a
    # background job, or a live "who's online" dashboard wants `interval`. Neither
    # subsumes the other — see `timeout`'s docstring for the same note from the
    # other side.
    #
    # Rule 0: for polling a server, the composition is a lazy `<turbo-frame>` plus
    # this controller reloading it on every tick — NOT a bespoke "poll" controller.
    # `interval` supplies the visibility-aware clock; a `<turbo-frame>` supplies
    # the request/response/DOM-swap machinery Turbo already owns. Wiring it needs
    # no Ruby at all beyond the frame itself:
    #
    #   <turbo-frame id="job_status" src="...">
    #     <div data-controller="cw--interval" data-cw--interval-ms-value="2000"
    #          data-action="cw--interval:tick->job_status#reload"></div>
    #   </turbo-frame>
    #
    # No other Rule 0 applies beyond that: there is no platform primitive for "run
    # this repeatedly, later" short of `setInterval`, which is exactly what this
    # wraps, plus the visibility pause/resume below.
    #
    # PAUSES WHILE THE DOCUMENT IS HIDDEN, and resumes with a fresh interval once
    # visible again — see the controller docstring for why a backgrounded tab must
    # neither keep ticking (burns cycles for work nobody sees) nor catch up with a
    # burst of stale ticks the instant it regains focus.
    #
    # A behaviour, not a widget — it decorates whatever element it is placed on and
    # ships no partial (docs/COMPONENT_CONTRACT.md). It has no markup of its own;
    # wire `cw--interval:tick` onto whatever action should run on each tick.
    class Interval < Presenter
      attr_reader :ms, :immediate

      # @param ms [Numeric] milliseconds between ticks. Required — there is no
      #   sensible default polling cadence.
      # @param immediate [Boolean] dispatch one extra `tick` immediately on
      #   connect, before the first `ms`-spaced tick. Default false. This fires
      #   exactly once, at connect — it is not re-applied on every
      #   visibility-resume, which would defeat the pause/resume behaviour by
      #   dispatching a tick the instant a backgrounded tab regains focus.
      # @param overrides [Hash] merged into the root element, last
      def initialize(ms:, immediate: false, **overrides)
        @ms = ms
        @immediate = !!immediate
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(ms: ms, immediate: immediate),
          overrides
        )
      end
    end
  end
end
