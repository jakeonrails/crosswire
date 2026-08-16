# frozen_string_literal: true

module Crosswire
  # `crosswire_stream_from` — a `turbo_stream_from` wrapper that requires an explicit,
  # already-authorizing channel.
  #
  # This is the one Ruby-only helper crosswire ships with no matching controller or
  # presenter: `Crosswire::AuthorizedStreamChannel` is Action Cable subscription logic,
  # not a Stimulus behaviour, so there is no `streams_controller.js` and no
  # `lib/crosswire/presenters/streams.rb` for it to pair with. That also means it is
  # invisible to `contract_audit_test.rb`'s naming checks, which walk controller ->
  # presenter -> helper in that direction and would never go looking for a helper that
  # names no controller. It is registered by hand instead, in two places: explicitly
  # added to `HelperCase` in `test/crosswire/integration_test_runner.rb` (component-
  # name-derived inclusion would never find it), and explicitly `helper`-included in
  # `test/dummy/app/controllers/crosswire_preview_controller.rb`.
  #
  # Guarded at CALL time, not load time — this file is only ever loaded once
  # `Crosswire::Streams` itself has been (see `lib/crosswire/streams.rb`), so `Turbo`
  # and `Crosswire::AuthorizedStreamChannel` are already defined by the time any app
  # code can reach `crosswire_stream_from`. The `defined?` check exists only so a
  # caller who somehow bypasses that load path gets a crosswire-flavoured error instead
  # of a bare `NameError` three frames deep.
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
    #   <%= crosswire_stream_from(@board, channel: BoardChannel) %>
    #   <%= crosswire_stream_from(Current.account, :entries, channel: AccountChannel) %>
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
    def crosswire_stream_from(*streamables, channel:, **attributes)
      unless defined?(Turbo::StreamsChannel)
        raise Crosswire::Error, "crosswire_stream_from needs turbo-rails (Turbo::StreamsChannel " \
                                 "is not defined). Add `gem \"turbo-rails\"` to your Gemfile."
      end

      unless channel.is_a?(Class) && channel <= Crosswire::AuthorizedStreamChannel
        raise ArgumentError, "crosswire_stream_from requires channel: to be a " \
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
  end
end
