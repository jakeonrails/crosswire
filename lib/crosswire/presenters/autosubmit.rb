# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Autosubmit — submit the owning form automatically on input or change.
    #
    # This is the single highest-traffic question in the entire Hotwire corpus
    # ("submit a form automatically on change"), so read the whole docstring; the
    # requirements below correct the most common hand-rolled mistakes.
    #
    # Rule 0: for the simplest case — no debounce, no guard against redundant
    # submissions — a plain `onchange="this.form.requestSubmit()"` on the field does
    # the whole job with zero JavaScript of ours. Reach for this controller once you
    # need debouncing, the double-submit guard, or the `submitting`/`submitted` events.
    #
    # ALWAYS `form.requestSubmit()`, NEVER `form.submit()`. `submit()` bypasses HTML5
    # validation and — critically — bypasses Turbo entirely, causing a full page load
    # instead of a Turbo visit. This is the most common bug in hand-rolled versions of
    # this exact controller, and the controller enforces it; there is no value or
    # option that reaches `form.submit()`.
    #
    # Preserving focus and caret position across the round-trip is what makes
    # filter/search-as-you-type usable, and it is the part everyone gets wrong. This
    # controller does not implement it in JS because the robust answer lives in markup,
    # not behaviour: give the input a STABLE `id` and add `data-turbo-permanent` so
    # Turbo Frame navigation preserves the live element (including focus and caret)
    # across the round-trip instead of replacing it. Under Turbo 8 morphing, focus
    # survives a re-render only if the element has an `id` at all — morphing matches
    # elements by id, and an element with no id is always replaced rather than patched.
    #
    # Composition: per-field server-side validation is this same controller, scoped by
    # `formaction`/`formmethod` to a validation URL — it does not need a separate
    # `remote-validate` controller. Point `scope` at a small dedicated `<form>` (or a
    # `<button formaction="/validate/email" formnovalidate>` inside the field's own
    # form, passed to `form.requestSubmit(submitter)`) and this controller drives it
    # exactly the same way it drives a normal submit.
    class Autosubmit < Presenter
      attr_reader :delay, :event, :scope

      # @param delay [Integer] debounce delay in milliseconds before submitting after
      #   the triggering event. 0 (default) submits immediately, still on the trailing
      #   edge of the current event loop turn.
      # @param event [String] DOM event that triggers a submission attempt. "input"
      #   (default) fires on every keystroke; "change" waits for blur/commit. Any DOM
      #   event name the field actually dispatches is accepted.
      # @param scope [String, nil] CSS selector for the form to submit. Defaults to
      #   the field's own `form` property, falling back to the closest `<form>`
      #   ancestor. Use this to point a field at a form other than its own — e.g. a
      #   small dedicated validation form (see the composition note above).
      # @param overrides [Hash] merged into the field element, last
      def initialize(delay: 0, event: "input", scope: nil, **overrides)
        @delay = delay
        @event = event
        @scope = scope
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(delay: delay, event: event, scope: scope),
          overrides
        )
      end
    end
  end
end
