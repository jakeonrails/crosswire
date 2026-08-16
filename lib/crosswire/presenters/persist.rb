# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Persist — mirror one piece of element state to `localStorage`/`sessionStorage`
    # and reapply it on connect.
    #
    # No APG pattern governs this; it is plumbing, not a widget. Typical uses: accordion
    # state, a wizard's current step, table filters, a dark-mode toggle, sidebar collapse
    # — anything where "remember what the user last chose" is the whole feature.
    #
    # Turbo 8 morphing overwrites `data-*-value` attributes and skips `connect()`
    # (turbo#1210, closed won't-fix), so the controller also listens for
    # `turbo:morph-element` **scoped to its own element**, never `turbo:morph@window` —
    # that fires page-wide and has hung browsers with many controllers mounted
    # (research/README.md #14).
    #
    # Storage can throw: Safari private browsing, a full quota, disabled cookies. Every
    # read and write is wrapped in the controller and degrades silently to an in-memory
    # fallback rather than breaking the page.
    #
    # Refuses to run against `type="password"` fields — storing credentials in Web
    # Storage is a security bug, not a feature, so the controller detects this at
    # runtime and warns once instead of persisting anything.
    class Persist < Presenter
      VALID_STORAGE = %w[local session].freeze

      # @param key [String] storage key; required — this is the identity of the
      #   persisted value, so there is no sane default
      # @param attribute [String] what to persist: "value", "checked", "open", or any
      #   other attribute name
      # @param storage [String] "local" (default) or "session"
      # @param debounce [Integer] milliseconds to wait after the last change before
      #   writing to storage; 0 (default) writes immediately
      # @param overrides [Hash] merged into the decorated element, last
      def initialize(key:, attribute: "value", storage: "local", debounce: 0, **overrides)
        raise ArgumentError, "key is required" if key.nil? || key.to_s.empty?
        unless VALID_STORAGE.include?(storage.to_s)
          raise ArgumentError, "storage must be one of #{VALID_STORAGE.join(", ")}, got #{storage.inspect}"
        end

        @key = key.to_s
        @attribute = attribute.to_s
        @storage = storage.to_s
        @debounce = debounce
        super(**overrides)
      end

      def root_attrs(**extra)
        merge(
          controller_attrs,
          values(key: @key, attribute: @attribute, storage: @storage, debounce: @debounce),
          overrides,
          extra
        )
      end
    end
  end
end
