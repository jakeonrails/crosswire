# frozen_string_literal: true

require "crosswire/ui/component"
require "crosswire/ui/variants"
require "crosswire/presenters/dismiss"

module Crosswire
  module UI
    # RULE 0: an alert is a severity-coded message, not a widget — it reacts to
    # nothing on its own. The one thing it DOES react to (an optional dismiss) is not
    # hand-rolled here: it is `Crosswire::Presenters::Dismiss`, the existing
    # `cw--dismiss` primitive, composed onto this component's own root element the
    # exact way `skills/crosswire-composing/RECIPES.md`'s "Toast / flash message"
    # recipe already documents by hand — this class is that recipe, shipped.
    #
    # THE COMPOSITION SHOWCASE (ui-tier-spec.md §5 item 7): every other component in
    # this tier ships zero controllers. Alert is the first to show what "styled tier"
    # and "composed primitive" look like stacked on ONE element — `root_attrs` below
    # is nothing but `merge(own class/role, @dismiss&.root_attrs, overrides)`, the same
    # `cw_attrs(...)` stacking a consumer would write by hand, just done once here so
    # nobody has to re-derive it. `dismiss_trigger_attrs` hands back
    # `Crosswire::Presenters::Dismiss#trigger_attrs` unchanged — this presenter adds no
    # opinion of its own about HOW an element dismisses, only about WHETHER one exists:
    #
    #   def root_attrs
    #     merge(
    #       { "class" => self.class.variant_class(severity: severity, subtle: subtle), "role" => role },
    #       dismissible? ? @dismiss.root_attrs : {},
    #       overrides
    #     )
    #   end
    #
    # --- role vs aria-live -------------------------------------------------------------
    #
    # The severity variant alone decides the ARIA role, and the role alone carries the
    # live-region semantics — `role="status"` is implicitly `aria-live="polite"`;
    # `role="alert"` is implicitly `aria-live="assertive"` (both per the ARIA role
    # mapping, not a guess). This presenter NEVER emits an explicit `aria-live`
    # alongside either role: a role and a redundant `aria-live` that happens to
    # disagree with it is a real, recorded a11y bug class, and there is no case where
    # this component needs to say anything an explicit `aria-live` would say better
    # than the role already does. (Contrast `Crosswire::UI::ToastViewport`, a
    # freestanding live-region CONTAINER with no implicit role/liveness pairing of its
    # own to lean on — that one sets both deliberately; see its own docstring.)
    # `danger`/`warning` are assertive (`role="alert"` — interrupts); `neutral`/`info`/
    # `success` are polite (`role="status"`).
    #
    #   <%= cw.alert "Payment failed — please try another card.", severity: :danger %>
    #   <%= cw.alert "Draft saved.", severity: :success, dismissible: true %>
    #
    # Morph: Server-owned
    #   DOM-only state: whether the alert has been dismissed. Dismissal here is a DOM
    #     REMOVAL driven by a Stimulus action (`cw--dismiss`), not a Stimulus VALUE —
    #     there is no server-rendered `dismissed="true"` attribute a morph could ever
    #     see and decide to honour, the way `Crosswire::UI::Select`'s Server-owned
    #     verdict has a `selected` attribute to patch. That absence IS the hazard.
    #   On morph: this is the flash-message trap. If the SAME alert keeps being
    #     server-rendered on the next response that could be followed by a morph (the
    #     session still holds the flash, a background `broadcasts_refreshes`, a page
    #     that simply re-renders the same instance variable), idiomorph has no way to
    #     know the node the user just dismissed ever existed — the incoming HTML
    #     carries an element idiomorph has never been told to treat as gone, so it adds
    #     it right back, identical to the one the user removed. A morph does not
    #     "clobber" a dismissed alert; it resurrects it, because dismissal was never
    #     expressed anywhere the server could see. Proven, not merely asserted, against
    #     real `@hotwired/turbo` in `test/js/alert.browser.test.js` — that file
    #     DEMONSTRATES the trap (a morph brings the alert back), it does not claim to
    #     fix it, because nothing at this layer can: the fix is server-side.
    #   The app must: stop rendering a dismissed alert on the very next response that
    #     could be followed by a morph — consume the flash after it is read once,
    #     track acknowledgement server-side and stop emitting the alert once
    #     acknowledged, or equivalent. Client-side dismissal alone never survives a
    #     morph if the server does not also agree, server-side, that the alert is gone.
    class Alert < Component
      extend Variants

      base "cw-alert"
      variant :severity, {
        neutral: nil,
        info: "cw-alert--info",
        success: "cw-alert--success",
        warning: "cw-alert--warning",
        danger: "cw-alert--danger"
      }, default: :neutral
      boolean :subtle, "cw-alert--subtle"

      # Severities that interrupt (`role="alert"`) rather than merely inform
      # (`role="status"`) — see the role-vs-aria-live doctrine above.
      ASSERTIVE_SEVERITIES = %i[danger warning].freeze

      attr_reader :severity, :subtle, :dismissible

      # @param severity [Symbol] see `variant` declaration above — also decides `role`
      # @param subtle [Boolean] a lower-emphasis treatment (alert.css), same
      #   variant-boolean shape as every other component in this tier
      # @param dismissible [Boolean] compose `cw--dismiss` onto the root element and
      #   make `dismiss_trigger_attrs` available — see the composition showcase above
      # @param overrides [Hash] merged into the root element, last
      def initialize(severity: :neutral, subtle: false, dismissible: false, **overrides)
        @severity = severity
        @subtle = !!subtle
        @dismissible = !!dismissible
        @dismiss = Crosswire::Presenters::Dismiss.new(label: "Dismiss") if @dismissible
        super(**overrides)
      end

      # `role="alert"` (assertive) for danger/warning, `role="status"` (polite)
      # otherwise — see the role-vs-aria-live doctrine above. Never both a role and an
      # explicit `aria-live`.
      def role = ASSERTIVE_SEVERITIES.include?(severity) ? "alert" : "status"

      def root_attrs
        merge(
          { "class" => self.class.variant_class(severity: severity, subtle: subtle), "role" => role },
          @dismiss ? @dismiss.root_attrs : {},
          overrides
        )
      end

      # The composed `cw--dismiss` trigger's attributes — only meaningful when
      # `dismissible: true`. Raises rather than silently rendering a dead button when
      # it is not: a close button wired to a controller that was never composed onto
      # the root is a worse failure mode than an explicit error at construction time.
      def dismiss_trigger_attrs(**extra)
        raise ArgumentError, "#{self.class}: dismiss_trigger_attrs called but dismissible: false" unless @dismiss

        @dismiss.trigger_attrs(**extra)
      end
    end
  end
end
