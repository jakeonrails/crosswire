# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # RULE 0: for the "is this request taking a while" case, prefer `cw--loading` (or
    # Turbo's own `aria-busy` / `data-turbo-submits-with`) — see that presenter's
    # docstring. `cw--fallback` exists for the state Turbo has no answer to at all: a
    # request that FAILS. A lazy `<turbo-frame loading="lazy" src="…">` whose endpoint
    # 500s just sits there showing its placeholder forever (LiveView's tri-state async
    # assigns are the prior art this is modelled on — a plain two-state loading/loaded
    # toggle has no failure branch to transition into); a `<turbo-cable-stream-source>`
    # whose WebSocket drops mid-session gives no visual signal that broadcasts have
    # stopped arriving.
    #
    # A behaviour, not a widget — it decorates a scope you already have (typically
    # wrapping a `<turbo-frame>`), so it ships no partial. Tri-state: `"ok"` (default),
    # `"loading"`, `"failed"`. State is rendered server-side (R4) — a lazy frame's
    # wrapper renders `state: "loading"` up front, so the loading target is visible
    # before JavaScript boots, not just after the first fetch event.
    #
    # See the controller docstring for exactly which Turbo events drive each
    # transition and how stream-connection status folds into the same tri-state
    # rather than needing its own controller (a standalone "connection" primitive was
    # considered and rejected in the research catalog for exactly that reason).
    class Fallback < Presenter
      attr_reader :state

      # @param state [String, Symbol] initial state: `"ok"`, `"loading"`, or
      #   `"failed"`. Rendered server-side so a lazy frame can start in `"loading"`
      #   and a page reload after a known failure can start in `"failed"`, both
      #   correct before JavaScript ever runs.
      # @param failed_class [String, nil] class applied (Classes API) to the root
      #   element while `state == "failed"`. `nil` (default) ships no class; style off
      #   the `failed` target's visibility (or `[data-cw--fallback-state-value=
      #   "failed"]`) instead unless a design system specifically needs a class hook.
      # @param overrides [Hash] merged into the root element, last
      def initialize(state: "ok", failed_class: nil, **overrides)
        @state = state.to_s
        @failed_class = failed_class
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(state: state),
          classes(failed: @failed_class),
          action(
            "turbo:before-fetch-request->pending",
            "turbo:before-fetch-response->check",
            "turbo:fetch-request-error->fail",
            "turbo:frame-missing->fail"
          ),
          overrides
        )
      end

      # The region shown only while `state == "loading"`. A live region: this is
      # exactly the "genuinely absent" case Rule 0 above waves through — Turbo's own
      # `aria-busy` announces busy-ness on the form/frame itself, but nothing
      # announces the presence of a *dedicated* loading message to a screen reader
      # unless it is one itself.
      def loading_attrs(**extra)
        merge(
          target(:loading),
          {
            "role" => "status",
            "aria-live" => "polite",
            "aria-atomic" => "true",
            "hidden" => state != "loading"
          },
          extra
        )
      end

      # The region shown only while `state == "failed"`. `role="alert"` (implicit
      # `aria-live="assertive"`) rather than `loading_attrs`' `"polite"` — a failure is
      # exactly the kind of thing screen-reader guidance says should interrupt.
      def failed_attrs(**extra)
        merge(
          target(:failed),
          {
            "role" => "alert",
            "aria-atomic" => "true",
            "hidden" => state != "failed"
          },
          extra
        )
      end

      # Marks the (optional) `<turbo-cable-stream-source>` the controller should watch
      # for connection loss. No accessibility contract of its own — the element is
      # normally visually empty; losing/regaining its `connected` attribute surfaces
      # through `loading_attrs`/`failed_attrs` above, not through this element
      # directly.
      def source_attrs(**extra)
        merge(target(:source), extra)
      end
    end
  end
end
