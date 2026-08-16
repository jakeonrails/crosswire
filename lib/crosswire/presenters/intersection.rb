# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Intersection — dispatch an event when the element enters or leaves the viewport.
    #
    # Rule 0: if all you need is "load this content once it scrolls into view," reach
    # for a `<turbo-frame loading="lazy">` instead — it fires on first intersection via
    # Turbo's own `AppearanceObserver` (itself an `IntersectionObserver`) and needs no
    # JavaScript of ours at all. This controller is for *reacting* to visibility —
    # dispatching an event another controller, or your own code, listens for — not for
    # loading content. If you only need "don't pay the render cost for a long
    # off-screen list," `content-visibility: auto` handles that natively and is not
    # an accessibility hazard the way DOM-removing virtualization is (skipped content
    # stays in the accessibility tree). If you only need "fade/slide in as it scrolls
    # into view," a scroll-driven CSS animation (`animation-timeline: view()`) covers
    # it with zero JS where supported — but it is not yet Baseline (Firefox is the sole
    # holdout as of 2026-08), so gate it behind `@supports` with this controller as the
    # fallback rather than the other way round.
    #
    # This is one of the most load-bearing primitives in the catalogue precisely
    # because so much decomposes to it: infinite scroll is this controller plus a
    # `<turbo-frame>`, where the observed sentinel is the frame that replaces itself
    # with the next page (its own sentinel included) — not a bespoke infinite-scroll
    # controller. Sticky-header elevation, reveal-on-scroll without CSS support, and
    # "poll only while visible" all decompose the same way: this controller supplies
    # the entered/left event, and a small amount of consumer code (or another
    # controller listening via `data-action`) does the feature-specific part.
    #
    # No targets, no markup of its own — it decorates whatever element it is placed
    # on. See docs/COMPONENT_CONTRACT.md: this is a "behaviour," so it ships no
    # partial.
    class Intersection < Presenter
      attr_reader :threshold, :once, :root_margin, :root

      # @param threshold [Numeric] fraction of the target visible before it counts as
      #   intersecting, passed straight through to `IntersectionObserverInit.threshold`
      # @param once [Boolean] unobserve after the first `entered` — for reveal-once and
      #   "load more" sentinels. Reconfiguring this is read live by the controller; it
      #   does not require re-creating the observer.
      # @param root_margin [String] passed straight through to
      #   `IntersectionObserverInit.rootMargin`, e.g. `"200px"` to fire early
      # @param root [String, nil] CSS selector for the scrolling ancestor to use as the
      #   viewport, resolved by the controller with `document.querySelector`. `nil`
      #   (the default) uses the browser viewport, matching `IntersectionObserverInit`'s
      #   own `root: null` default.
      # @param overrides [Hash] merged into the root element, last
      def initialize(threshold: 0, once: false, root_margin: "0px", root: nil, **overrides)
        @threshold = threshold
        @once = !!once
        @root_margin = root_margin
        @root = root
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(threshold: threshold, once: once, root_margin: root_margin, root: root),
          overrides
        )
      end
    end
  end
end
