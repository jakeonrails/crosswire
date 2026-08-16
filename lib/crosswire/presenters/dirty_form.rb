# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # DirtyForm — track field changes and guard against losing them.
    #
    # THE WHOLE REASON THIS EXISTS: `beforeunload` does NOT fire on a Turbo Drive
    # visit — the document never actually unloads, Turbo just replaces the DOM in
    # place. A form guarded with only `beforeunload` (every "warn on unsaved changes"
    # tutorial ever written) is silently unprotected against the single most common
    # way a user leaves a Rails app: clicking an ordinary in-app link. See the
    # controller docstring for the three guards this installs — one for a real
    # unload, one for a Turbo Drive visit, one for a Turbo Frame render — and why
    # each is needed; `beforeunload` alone covers exactly one of the three.
    #
    # Place the controller on the `<form>` element itself: `data-dirty` is set there,
    # and — with no `field` targets given — dirtiness is tracked across every control
    # inside it via `FormData`.
    class DirtyForm < Presenter
      attr_reader :guard

      # @param guard [Boolean] block navigation (a real unload, a Turbo Drive visit,
      #   a Turbo Frame render) while dirty. Defaults to true. Set false to still
      #   TRACK dirtiness — `data-dirty`, the `changed`/`reset` events — without ever
      #   prompting, e.g. to drive a "Save" button's disabled state with no
      #   navigation guard at all.
      # @param dirty_class [String, nil] class applied to the form while dirty,
      #   optional and guarded per R3.
      # @param overrides [Hash] merged into the root element, last
      def initialize(guard: true, dirty_class: nil, **overrides)
        @guard = !!guard
        @dirty_class = dirty_class
        super(**overrides)
      end

      # `input`/`change` are wired here, on the root, rather than requiring the
      # caller to add them to every field: both events bubble, so ONE delegated
      # listener on the form (which is what the root IS for this component) catches
      # every descendant control automatically — including any explicit `field`
      # targets — with no per-field wiring needed.
      def root_attrs
        merge(
          controller_attrs,
          values(guard: guard),
          classes(dirty: @dirty_class),
          action("input->check", "change->check"),
          overrides
        )
      end

      # Optional — scope tracking to specific fields instead of every control inside
      # the form (e.g. ignore a search box that happens to live inside the same
      # `<form>`). With no `field` targets at all, the controller tracks everything.
      def field_attrs(**extra)
        merge(target(:field), extra)
      end
    end
  end
end
