# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # RULE 0: Turbo already gives you two loading signals for free, and both beat
    # this for the common case. `aria-busy="true"` is set automatically on the
    # `<form>` (or `<turbo-frame>`) Turbo is currently submitting/loading, and
    # `data-turbo-submits-with="Saving…"` swaps a submit button's own label for the
    # duration with zero JavaScript — see notes/08's CSS-only loading vocabulary
    # (`[aria-busy="true"] { ... }` needs no controller at all). Reach for either
    # first.
    #
    # `cw--loading` earns its keep for three things neither of those gives you:
    #
    #   * marking the SUBMITTER separately from the form/frame it belongs to (so a
    #     "Save" button can show a spinner while an unrelated status text elsewhere
    #     on the same form does not);
    #   * an anti-flicker DELAY threshold — a request that resolves in 40ms should
    #     never visibly flash a spinner, the same problem `wire:loading.delay`
    #     solves in Livewire;
    #   * a bare, unprefixed `data-loading` attribute — deliberately matching
    #     Livewire 4's own attribute name (12-cross-framework-and-the-case.md calls
    #     it "the most portable idea in this survey") rather than a gem-namespaced
    #     one, so it composes with Tailwind v4's `data-loading:` / `in-data-loading:`
    #     / `has-data-loading:` variants and any CSS already written against that
    #     name, out of the box, with zero CSS shipped by this gem.
    #
    # A behaviour, not a widget — it decorates a scope you already have (a form, a
    # `<turbo-frame>`, a table row wrapping several, or `<body>` for a page-wide
    # indicator), so it ships no partial. See the controller docstring for exactly
    # which Turbo events drive it and the one Turbo source-verified wrinkle
    # (`turbo:before-fetch-request` re-firing on a `<form>` that `turbo:submit-start`
    # already covers) this presenter's action wiring exists to route around.
    class Loading < Presenter
      attr_reader :delay

      # @param delay [Integer] anti-flicker threshold in milliseconds. `data-loading`
      #   (and the optional `loading_class`) are only applied once a request has been
      #   in flight this long — a request that resolves faster never visibly flashes
      #   anything. Default 100, Livewire's own default.
      # @param loading_class [String, nil] class applied (Classes API) alongside
      #   `data-loading` to whichever element the controller marks — the form/frame
      #   the event originated on, and the submitter if there is one. `nil` (default)
      #   ships no class; style off `[data-loading]` instead unless a design system
      #   specifically needs a class hook.
      # @param overrides [Hash] merged into the root element, last
      def initialize(delay: 100, loading_class: nil, **overrides)
        @delay = delay
        @loading_class = loading_class
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(delay: delay),
          classes(loading: @loading_class),
          action(
            "turbo:submit-start->start",
            "turbo:before-fetch-request->start",
            "turbo:submit-end->stop",
            "turbo:frame-render->stop",
            "turbo:fetch-request-error->stop"
          ),
          overrides
        )
      end
    end
  end
end
