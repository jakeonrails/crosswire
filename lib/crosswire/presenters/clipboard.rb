# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Clipboard — copy text and give feedback.
    #
    # Rule 0: there is no HTML element for "copy," so unlike most of the catalogue this
    # one earns its JavaScript outright. If you would rather not own the code,
    # `<clipboard-copy>` (a GitHub-maintained web component) is a drop-in that survives
    # morphs for free; reach for this controller when you want the CSS Classes API,
    # the `cw--clipboard:copied`/`:failed` events for composition, or an accessible
    # `aria-live` announcement wired in for you.
    #
    # A purely visual "Copied!" state is invisible to a screen reader. The controller
    # writes the success state into a `status` target with `role="status"` /
    # `aria-live="polite"` — but **that region must already exist in the DOM before
    # the copy happens**. Injecting an element that already has `aria-live` set
    # announces nothing; the region has to be observed by the browser's accessibility
    # machinery first, then mutated (research/notes/10, the same rule that governs a
    # site-wide route announcer). Because `status_attrs` is rendered server-side as
    # part of the page's initial markup, this is satisfied automatically as long as you
    # don't build the status element with client-side JS after the fact.
    #
    # `navigator.clipboard.writeText` requires a secure context (HTTPS, or the
    # controller has no browser API to call at all on plain `http://`) and can reject
    # even when present — permissions, an iframe missing the `clipboard-write` allow
    # attribute. The controller never lets that throw unhandled: it falls back to a
    # hidden-textarea + `execCommand("copy")` selection copy, and only if that also
    # fails does it dispatch `cw--clipboard:failed`.
    class Clipboard < Presenter
      attr_reader :text, :success_duration

      # @param text [String, nil] literal text to copy. Takes precedence over the
      #   `source` target's value/textContent, which in turn takes precedence over
      #   `this.element.textContent` — see the controller docstring for the exact
      #   precedence order.
      # @param success_duration [Numeric] milliseconds the success state (class +
      #   live-region announcement) is held before the controller clears it
      # @param success_class [String, nil] class applied on copy — to the `button`
      #   target if given, else to the root element itself. Guarded with
      #   `hasSuccessClass` per R3: Stimulus throws on `this.fooClass` when the
      #   attribute is absent.
      # @param overrides [Hash] merged into the root element, last
      def initialize(text: nil, success_duration: 2000, success_class: nil, **overrides)
        @text = text
        @success_duration = success_duration
        @success_class = success_class
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(text: text, success_duration: success_duration),
          # The success class MUST live on the root (controller) element even when the
          # controller applies it to the `button` target — Stimulus's Classes API
          # resolves `data-*-class` attributes against the controller's own element,
          # never against a target's.
          classes(success: @success_class),
          overrides
        )
      end

      # The element whose value/textContent is copied when no explicit `text` is
      # given. Optional — omit it entirely when `text:` is set.
      def source_attrs(**extra)
        merge(target(:source), extra)
      end

      # The element that triggers the copy and (if no `text:` was given) receives the
      # success class. Optional — the controller's own root element can carry the
      # click action itself instead for a single-element copy button.
      def button_attrs(**extra)
        merge(
          target(:button),
          action("click->copy"),
          { "type" => "button" },
          extra
        )
      end

      # The `aria-live` region the controller announces the success state into. See
      # the class docstring: this element must be rendered as part of the initial
      # markup, never injected at copy time.
      def status_attrs(**extra)
        merge(
          target(:status),
          { "role" => "status", "aria-live" => "polite", "aria-atomic" => "true" },
          extra
        )
      end
    end
  end
end
