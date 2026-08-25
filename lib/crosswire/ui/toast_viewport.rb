# frozen_string_literal: true

require "crosswire/ui/component"

module Crosswire
  module UI
    # The live-region CONTAINER `Crosswire::UI::Toast` items are rendered or appended
    # into — not itself a registered `Crosswire::UI::COMPONENTS` entry (it ships no
    # variants, no severity, nothing a caller configures beyond `id:`/`assertive:`),
    # but its own small presenter rather than inline attrs in the helper, for the same
    # reason every other element-with-attributes in this tier gets one: so its
    # attribute computation is unit-testable without a view context.
    #
    # "The aria-live rule from the corpus" (research/notes/08-ui-pattern-catalog.md,
    # "Toast / flash notifications"): a live region's `role`/`aria-live` must already
    # be present in the DOM BEFORE content is injected into it — most screen readers
    # never pick up an announcement from a role/aria-live pair added at the same
    # moment as the content, or later. That is why this container is rendered
    # server-side, in the layout, from first paint — `cw.toast_viewport` — and never
    # constructed lazily by client-side JS the way a toast library typically would.
    #
    # Unlike `Crosswire::UI::Alert`, which deliberately never pairs a role with an
    # explicit `aria-live` (the role alone already implies it — see that class's own
    # docstring), THIS element sets both, deliberately: it is a freestanding live
    # region with no message content of its own driving the role choice — the corpus
    # pattern this class ships sets `role` and `aria-live` together on a live-region
    # container specifically because implicit role-to-liveness support is not uniform
    # across every screen reader/browser pairing for a region whose content changes
    # entirely via later DOM mutation rather than being present at parse time. The two
    # presenters are answering different questions: Alert asks "what role does THIS
    # message need", Toast asks "what does an EMPTY container that will only ever
    # change through mutation need to reliably announce whatever lands inside it".
    #
    # Renders exactly one container per politeness level — `assertive: true` for a
    # second, urgent-only viewport (the corpus's two-container split: `#flashes`
    # polite, `#flash_alerts` assertive), given a DIFFERENT `id:` than the default so
    # the two never collide:
    #
    #   <%= cw.toast_viewport %>
    #   <%= cw.toast_viewport id: "cw-toast-viewport-assertive", assertive: true %>
    #
    # Morph: Excluded — see `Crosswire::UI::Toast`'s own docstring (the verdict for
    #   this composite lives there, on the registered component; this class only
    #   carries the `data-turbo-permanent` attribute the verdict depends on).
    class ToastViewport < Component
      # The id `Crosswire::UI::ToastHelper#toast_viewport` defaults to, and what a
      # Turbo Stream append targets when no other container was ever rendered — see
      # `Crosswire::UI::Toast`'s "Turbo-Stream-appended toasts" rendering path.
      DEFAULT_ID = "cw-toast-viewport"

      attr_reader :id, :assertive

      # @param id [String] must be STABLE across responses — `data-turbo-permanent`
      #   id-matches the current DOM against the incoming HTML by this value alone
      # @param assertive [Boolean] `role="alert"`/`aria-live="assertive"` instead of
      #   the default `role="status"`/`aria-live="polite"` — see the docstring above
      # @param overrides [Hash] merged into the root element, last
      def initialize(id: DEFAULT_ID, assertive: false, **overrides)
        @id = id
        @assertive = !!assertive
        super(**overrides)
      end

      def root_attrs
        merge(
          {
            "id" => id,
            "class" => "cw-toast-viewport",
            "role" => assertive ? "alert" : "status",
            "aria-live" => assertive ? "assertive" : "polite",
            "aria-atomic" => "false",
            "data-turbo-permanent" => ""
          },
          overrides
        )
      end
    end
  end
end
