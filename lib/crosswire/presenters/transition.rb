# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Transition — run an enter/leave class sequence and resolve when it finishes.
    #
    # Rule 0, and read this before reaching for the controller: CSS `@starting-style` +
    # `transition-behavior: allow-discrete` (both Baseline 2024) already animate elements
    # appearing in the DOM — including content inserted by a Turbo Stream, since
    # `@starting-style` triggers on "first rendered," not on any particular insertion
    # method. For a plain enter transition you need **zero JavaScript**:
    #
    #   .panel {
    #     transition: opacity .2s, display .2s allow-discrete;
    #     @starting-style { opacity: 0; }
    #   }
    #
    # What CSS genuinely cannot do is exit-on-removal: `Node.remove()` is synchronous, so
    # the node is gone before any transition has a chance to run. That is a spec-level
    # limitation, not a support gap — no future browser version fixes it. So this
    # controller is a narrow hook, not a general transition system: its whole job is to
    # intercept a removal, add an exiting class, await `transitionend`, and only then let
    # the removal happen. Reach for it on exit; reach for CSS on enter.
    #
    # It composes with `cw--dismiss`, which already dispatches a cancelable
    # `cw--dismiss:dismissing` carrying a `complete()` callback in `detail` — exactly the
    # shape this controller needs to hold a removal open long enough to animate. Wire it
    # with a plain `data-action`, e.g. via #leave_on below; that pairing is the primary
    # use case.
    #
    # Classes are supplied as data attributes rather than hardcoded, following the
    # transition module in tailwindcss-stimulus-components: `enter`, `enterFrom`,
    # `enterTo`, `leave`, `leaveFrom`, `leaveTo` — all optional, all guarded in the
    # controller with `hasFooClass` per R3.
    class Transition < Presenter
      # @param enter [String, nil] class applied for the whole enter transition
      # @param enter_from [String, nil] class applied only at the start of enter
      # @param enter_to [String, nil] class applied for the "settled" enter state
      # @param leave [String, nil] class applied for the whole leave transition
      # @param leave_from [String, nil] class applied only at the start of leave
      # @param leave_to [String, nil] class applied for the "settled" leave state
      # @param overrides [Hash] merged into the decorated element, last
      def initialize(enter: nil, enter_from: nil, enter_to: nil,
                     leave: nil, leave_from: nil, leave_to: nil, **overrides)
        @enter = enter
        @enter_from = enter_from
        @enter_to = enter_to
        @leave = leave
        @leave_from = leave_from
        @leave_to = leave_to
        super(**overrides)
      end

      def root_attrs(**extra)
        merge(
          controller_attrs,
          classes(
            enter: @enter, enter_from: @enter_from, enter_to: @enter_to,
            leave: @leave, leave_from: @leave_from, leave_to: @leave_to
          ),
          overrides,
          extra
        )
      end

      # Composition helper for the primary use case: wire this controller's `leave`
      # action as the handler for another controller's cancelable removal event.
      # Defaults to `cw--dismiss:dismissing`.
      #
      #   merge(transition.root_attrs, transition.leave_on)
      #   # => { …, "data-action" => "cw--dismiss:dismissing->cw--transition#leave" }
      #
      # Merge the result into the SAME element `cw--dismiss` is controlling — the event
      # only reaches listeners on the node it is dispatched from (it bubbles, but the
      # dismiss target and the transition target are the same element in the common case).
      def leave_on(event_name = "cw--dismiss:dismissing")
        action("#{event_name}->leave")
      end
    end
  end
end
