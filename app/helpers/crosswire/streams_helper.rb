# frozen_string_literal: true

module Crosswire
  # `stream_from` (reached as `cw.stream_from` / `crosswire.stream_from`) — a
  # `turbo_stream_from` wrapper that requires an explicit, already-authorizing channel.
  #
  # This is the one Ruby-only helper crosswire ships with no matching controller or
  # presenter: `Crosswire::AuthorizedStreamChannel` is Action Cable subscription logic,
  # not a Stimulus behaviour, so there is no `streams_controller.js` and no
  # `lib/crosswire/presenters/streams.rb` for it to pair with. That also means it is
  # invisible to `contract_audit_test.rb`'s naming checks, which walk controller ->
  # presenter -> helper in that direction and would never go looking for a helper that
  # names no controller. It is registered by hand instead: included into
  # `Crosswire::Builder` (lib/crosswire/builder.rb) alongside every per-component helper
  # module, and explicitly added to `HelperCase` in
  # `test/crosswire/integration_test_runner.rb` for the same reason — component-name-
  # derived inclusion would never find it.
  #
  # Guarded at CALL time, not load time — this file is only ever loaded once
  # `Crosswire::Streams` itself has been (see `lib/crosswire/streams.rb`), so `Turbo`
  # and `Crosswire::AuthorizedStreamChannel` are already defined by the time any app
  # code can reach `stream_from`. The `defined?` check exists only so a caller who
  # somehow bypasses that load path gets a crosswire-flavoured error instead of a bare
  # `NameError` three frames deep.
  module StreamsHelper
    # Wrap `turbo_stream_from` with a REQUIRED explicit `channel:`. Plain
    # `turbo_stream_from` defaults to `Turbo::StreamsChannel`, which authorizes anyone
    # holding a validly-signed stream name and nothing more (02-turbo-deep-dive.md
    # §4.5) — this helper exists specifically so reaching for that default cannot
    # happen by omission. You must name a channel; naming one that still uses
    # `Crosswire::AuthorizedStreamChannel`'s fail-closed default `authorized?` raises
    # below, in development and test, so forgetting to actually write an authorization
    # rule is loud immediately rather than silently rejecting every subscriber in
    # production.
    #
    #   <%= cw.stream_from(@board, channel: BoardChannel) %>
    #   <%= cw.stream_from(Current.account, :entries, channel: AccountChannel) %>
    #
    # Any extra `attributes:` pass straight through to `turbo_stream_from` (`data:`
    # attributes are the documented way to hand a channel additional subscribe
    # params — see `Turbo::StreamsHelper#turbo_stream_from`).
    #
    # @param streamables [Array<Object>] passed straight through to `turbo_stream_from`
    # @param channel [Class] a `Crosswire::AuthorizedStreamChannel` subclass — REQUIRED,
    #   no default
    # @param attributes [Hash] merged into the rendered `<turbo-cable-stream-source>`
    # @raise [ArgumentError] if `channel` is not a `Crosswire::AuthorizedStreamChannel`
    #   subclass
    # @raise [Crosswire::Error] in development/test only, if `channel` still uses the
    #   fail-closed default `authorized?` — i.e. was never actually given a rule
    def stream_from(*streamables, channel:, **attributes)
      unless defined?(Turbo::StreamsChannel)
        raise Crosswire::Error, "cw.stream_from needs turbo-rails (Turbo::StreamsChannel " \
                                 "is not defined). Add `gem \"turbo-rails\"` to your Gemfile."
      end

      unless channel.is_a?(Class) && channel <= Crosswire::AuthorizedStreamChannel
        raise ArgumentError, "cw.stream_from requires channel: to be a " \
                              "Crosswire::AuthorizedStreamChannel subclass, got #{channel.inspect}"
      end

      if Rails.env.local? && channel.instance_method(:authorized?).owner == Crosswire::Streams::AuthorizedStreamChannel
        raise Crosswire::Error, "#{channel} has not overridden authorized? — as shipped, it " \
                                 "rejects every subscriber (Crosswire::AuthorizedStreamChannel " \
                                 "fails closed by design; see its docstring). Define a private " \
                                 "authorized?(*streamables) on #{channel} before using it here."
      end

      turbo_stream_from(*streamables, channel: channel, **attributes)
    end

    # A plain Hash of the one attribute `versioned_replace` (see
    # `crosswire/stream_actions.js`) reads on both sides: `{ "data-cw-version" => "42" }`.
    # Spread it onto whatever tag builder you already render the partial's root
    # element with — this is not a Stimulus component, so unlike every
    # `cw.<name>_attrs` elsewhere in this gem it is not meant for `cw_attrs`
    # specifically, just for the version to appear on the root element by whatever
    # means the partial already uses:
    #
    #   <div id="<%= dom_id(widget) %>" <%= cw_attrs(cw.version_attrs(widget)) %>>
    #   <%= tag.div id: dom_id(widget), **cw.version_attrs(widget) %>
    #
    # @param versionable [Integer, #crosswire_stream_version] an already-resolved
    #   version, or an object mixing in `Crosswire::Streams::Versioned` (or otherwise
    #   responding to `crosswire_stream_version`).
    # @return [Hash{String => String}]
    def version_attrs(versionable)
      version = versionable.is_a?(Integer) ? versionable : versionable.crosswire_stream_version
      { "data-cw-version" => version.to_s }
    end

    # Build a `<turbo-stream action="versioned_replace">` tag directly, for the rare
    # case you are composing a `.turbo_stream.erb` template by hand rather than
    # broadcasting from a model (`Crosswire::Streams::Versioned#broadcast_versioned_replace_to`
    # covers that far more common path). A thin wrapper over
    # `turbo_stream.action(:versioned_replace, target, **rendering, &block)` — the same
    # primitive `turbo_stream.replace`/`.update`/etc. are themselves built on
    # (`Turbo::Streams::TagBuilder#action`) — not a reimplementation of it.
    #
    #   <%= cw.versioned_replace dom_id(widget), partial: "widgets/widget", locals: { widget: widget } %>
    #
    # RULE 0 and the self-echo caveat are documented on
    # `crosswire/stream_actions.js` — read that first; this helper (and the model
    # concern) assume you have already decided `broadcast_replace_to` earns its keep
    # over `broadcasts_refreshes` for measured reasons.
    #
    # @param target [Object] forwarded to `Turbo::Streams::TagBuilder#action` — a dom id
    #   String, or an object `ActionView::RecordIdentifier.dom_id` accepts
    # @param rendering [Hash] `partial:`, `locals:`, `html:`, `method: :morph`, …
    # @return [ActiveSupport::SafeBuffer]
    def versioned_replace(target, **rendering, &block)
      turbo_stream.action(:versioned_replace, target, **rendering, &block)
    end
  end
end
