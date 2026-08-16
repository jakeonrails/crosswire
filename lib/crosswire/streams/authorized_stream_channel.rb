# frozen_string_literal: true

require "global_id"

module Crosswire
  module Streams
    # A `Turbo::StreamsChannel` subclass that authorizes the SUBSCRIBER, not just the
    # stream name.
    #
    # Threat model (02-turbo-deep-dive.md §4.5) — read this before reaching for it:
    # `turbo_stream_from`'s signed stream name authenticates the NAME. A client cannot
    # invent `Board:99` in devtools and start listening to another board's stream — the
    # signature is a real cryptographic guarantee of that one fact. It is NOT, and was
    # never designed to be, authorization of the subscriber, and it protects nothing
    # beyond that one fact:
    #
    #   1. **A leaked name subscribes forever.** The signature never expires. A shared
    #      screenshot, a cached HTML page, a shared account, or a page rendered to the
    #      wrong user hands out a working subscription with no expiry — anyone holding
    #      that string can open a WebSocket to it from any browser, at any time, and
    #      the plain `Turbo::StreamsChannel` will happily confirm it.
    #   2. **Broadcast payloads are not per-user.** Every subscriber on a stream
    #      receives byte-identical HTML. A partial that renders anything
    #      audience-specific (another user's name, a price only some viewers should
    #      see, a delete button gated on a permission) leaks it to everyone else on
    #      that same stream, regardless of who is or isn't authorized to subscribe.
    #   3. **Model-level broadcasts fire regardless of who is allowed to see the
    #      record.** `Turbo::Broadcastable` callbacks broadcast on model changes; they
    #      have no concept of a viewer, so nothing about them consults an authorization
    #      rule at broadcast time.
    #
    # This class closes (1): every subscribe attempt re-derives the streamables from
    # the verified name and asks `authorized?` before ever calling `stream_from`, not
    # only whichever request originally rendered `crosswire_stream_from`. It does NOT,
    # and structurally CANNOT, close (2) or (3) — a channel is a subscription gate, not
    # a rendering pipeline, and it never sees the payload. **A stream whose payload
    # legitimately differs by viewer must not be authorized harder — it must be
    # sharded.** Give each audience its own stream (one per user, one per role, one per
    # tenant — whatever the actual boundary is) rather than one shared stream everyone
    # subscribes to, or reach for `broadcasts_refreshes` (piece 4's Rule 0), which
    # pushes only a signal to re-fetch over the viewer's own already-authorized
    # connection instead of pushing shared HTML at all — authorization-correct by
    # construction, because nothing sensitive ever rides the wire.
    #
    # Fails CLOSED: `authorized?` returns `false` unless a subclass overrides it — the
    # opposite default from `Turbo::StreamsChannel`, which authorizes anyone holding a
    # validly-signed name. A channel that forgets to override `authorized?` rejects
    # every subscriber instead of accepting every subscriber; `crosswire_stream_from`
    # (see `Crosswire::StreamsHelper`) additionally raises in development/test if it
    # detects that omission, so the mistake is loud long before it reaches production.
    #
    #   # app/channels/board_channel.rb
    #   class BoardChannel < Crosswire::AuthorizedStreamChannel
    #     private
    #
    #     def authorized?(board, *)
    #       board.is_a?(Board) && current_user&.can_read?(board)
    #     end
    #   end
    #
    #   <%# app/views/boards/show.html.erb %>
    #   <%= crosswire_stream_from(@board, channel: BoardChannel) %>
    #
    # (`current_user` comes from your `ApplicationCable::Connection#identified_by`, as
    # with any Action Cable channel.)
    class AuthorizedStreamChannel < Turbo::StreamsChannel
      def subscribed
        stream_name = verified_stream_name_from_params

        if stream_name.present? && authorized?(*streamables)
          stream_from stream_name
        else
          reject
        end
      end

      private

      # The verified stream name is a `:`-joined string of per-streamable segments —
      # see `Turbo::Streams::StreamName#stream_name_from`. Each segment is either a
      # GlobalID param (`streamable.to_gid_param`, when the streamable responds to it —
      # an Active Record instance, or anything else mixing in
      # `GlobalID::Identification`) or a bare `streamable.to_param` String otherwise
      # (e.g. the `:entries` in `turbo_stream_from Current.account, :entries`). Neither
      # form can itself contain a `:`, so splitting the joined name on it is safe.
      #
      # Re-locate every segment: a `GlobalID::Locator.locate` hit becomes the real
      # object, in the same position `authorized?` receives it; anything that isn't a
      # GlobalID at all (`Locator.locate` returns `nil` for those, rather than raising)
      # passes through untouched as the original String. A GlobalID-shaped segment
      # whose record no longer exists is deliberately NOT rescued into a pass-through
      # here — the caller signed a name for something that used to resolve, and a
      # locator raising on that is a real error, not an authorization decision for
      # `authorized?` to make.
      #
      # Memoized, so `authorized?` (and anything wrapping it) can call this more than
      # once per subscribe attempt without re-parsing or re-locating. `[]` when the
      # name itself failed verification — a tampered or garbage signature never
      # produces streamables to hand anyone.
      def streamables
        return @streamables if defined?(@streamables)

        stream_name = verified_stream_name_from_params
        segments = stream_name.present? ? stream_name.split(":") : []

        @streamables = segments.map { |segment| GlobalID::Locator.locate(segment) || segment }
      end

      # Subclass hook. Receives the located `streamables`, in the order they were
      # signed in. FAIL CLOSED: this default returns `false`, so a channel that never
      # overrides it rejects every subscriber, not the other way around.
      def authorized?(*streamables) = false
    end
  end
end
