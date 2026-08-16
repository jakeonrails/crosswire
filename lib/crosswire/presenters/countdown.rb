# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Countdown — tick down to a deadline and dispatch at zero.
    #
    # No Rule 0: there is no platform primitive for "count down to an absolute
    # instant and tell me when it arrives." A countdown that must fire while the
    # app is backgrounded is a native local notification, not a web timer — out
    # of scope for this controller entirely.
    #
    # Send a DEADLINE, never a duration. `deadline: "2026-08-15T18:30:00Z"` is an
    # absolute fact both client and server agree on; a duration
    # (`seconds_remaining: 300`) silently drifts the moment the page is cached by
    # Turbo, restored from a snapshot, or simply read a few seconds after the
    # server computed it. Client clock skew shifts an absolute-instant countdown
    # identically for everyone rather than compounding, and a Turbo restore
    # recomputes the correct remaining time automatically because it recomputes
    # from `deadline`, never from a value frozen at render time.
    #
    # A behaviour, not a widget — it decorates a container you already have, so
    # it ships no partial. It does own a second element though: the `output`
    # target that receives the ticking text, which is why there is a `_for` form
    # in the helper as well as the bare `_attrs` builder.
    #
    # Composes with `timeout` when you only need "do something at zero" and have
    # no interest in a ticking display — `timeout`'s single `delay:` in
    # milliseconds is the right tool for that and needs no `deadline`-vs-duration
    # discipline of its own since it never re-arms. Composes with `transition`
    # for a flash effect in the final seconds.
    #
    # Accessibility (R2): `output_attrs` bakes in `role="timer"` and
    # `aria-live="off"` — a live region that re-announces every second (or even
    # every ten) is a screen-reader denial-of-service, not a countdown. See the
    # controller docstring for exactly when and how briefly this flips to an
    # assertive announcement instead of never announcing at all.
    class Countdown < Presenter
      attr_reader :deadline, :format

      # @param deadline [String] ISO 8601 absolute instant to count down to.
      #   Required — see the class docstring for why this is an instant, never a
      #   duration.
      # @param format [String, nil] "clock" (default) — `H:MM:SS`/`M:SS` — or
      #   "words" — coarse humanised phrasing ("2 minutes", "45 seconds").
      #   Passed straight through to the controller.
      # @param overrides [Hash] merged into the root element, last
      def initialize(deadline:, format: nil, **overrides)
        @deadline = deadline
        @format = format
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(deadline: deadline, format: format),
          overrides
        )
      end

      # The element that receives the ticking text. `role="timer"` identifies it
      # as a numerical counter to assistive tech; `aria-live="off"` is the
      # default state the controller only ever leaves TEMPORARILY, and only in
      # the final seconds — see the controller docstring for the exact window
      # and why. `datetime` carries the same absolute deadline as the root, so
      # hovering/inspecting the output itself also recovers the real instant.
      def output_attrs(**extra)
        merge(
          target(:output),
          { "role" => "timer", "aria-live" => "off", "datetime" => deadline },
          extra
        )
      end
    end
  end
end
