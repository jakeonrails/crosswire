# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Reveal — toggle an input between `password` and `text`, or unmask masked text.
    #
    # SECURITY, HONESTLY STATED: revealing a password field is a real trade-off, not a
    # free feature. It defeats the browser's own shoulder-surfing / screen-capture
    # protections for exactly as long as it stays revealed — whatever masking the
    # platform normally provides on `type="password"` is gone the moment `type` flips
    # to `text`. Some password managers also behave differently against a
    # `type="text"` field (1Password and iCloud Keychain, among others, inject their
    # own reveal toggle and can end up duplicated alongside this one). None of that is
    # a reason to avoid the component — "show password" is expected UX — but it is a
    # reason not to default `revealed: true` on anything you didn't mean to expose.
    #
    # `aria-pressed` on the trigger is the whole announcement mechanism: the APG
    # Button (toggle) pattern's own accessible-state signal, and screen readers
    # announce a change to it automatically. Firing a SEPARATE live-region
    # announcement on top of that would double-announce the same state change, so
    # this deliberately does not add one — see `char-count`'s docstring for a case
    # where a live region genuinely is the right tool, and contrast with why it isn't
    # here.
    class Reveal < Presenter
      attr_reader :revealed

      # @param revealed [Boolean] initial state, rendered server-side (R4) so the
      #   input's `type` and the trigger's `aria-pressed` are both correct before
      #   JavaScript loads and survive a Turbo morph. Defaults to false — the safe
      #   default is masked.
      # @param revealed_class [String, nil] class applied to the root while revealed
      # @param overrides [Hash] merged into the root element, last
      def initialize(revealed: false, revealed_class: nil, **overrides)
        @revealed = !!revealed
        @revealed_class = revealed_class
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(revealed: revealed),
          classes(revealed: @revealed_class),
          overrides
        )
      end

      # `type` is rendered server-side from the same `revealed` state the value
      # carries (R4) — never left for the controller to decide on first paint, so a
      # field that starts revealed (e.g. after a validation error you chose to
      # re-render with `revealed: true`) is correct before JavaScript runs at all.
      def input_attrs(**extra)
        merge(
          target(:input),
          { "type" => (revealed ? "text" : "password") },
          extra
        )
      end

      def trigger_attrs(**extra)
        merge(
          target(:trigger),
          action("click->toggle"),
          {
            "type" => "button",
            "aria-pressed" => revealed.to_s
          },
          extra
        )
      end
    end
  end
end
