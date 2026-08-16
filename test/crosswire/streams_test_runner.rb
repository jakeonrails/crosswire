# frozen_string_literal: true

# The real `Crosswire::AuthorizedStreamChannel` specs, using
# `ActionCable::Channel::TestCase` against a real Rails boot of `test/dummy`. Cloned
# from `integration_test_runner.rb`'s pattern (see the comment on `StreamsTest` in
# `streams_test.rb` for why this is a separate file and a separate subprocess).
#
# This file is NOT named `*_test.rb` on purpose and is never `require`d in-process.
# `streams_test.rb` runs it as its own child process. Run it directly and it behaves as
# an ordinary, self-contained Minitest suite:
#
#   bundle exec ruby test/crosswire/streams_test_runner.rb

ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment", __dir__)
require "rails/test_help"
require "minitest/autorun"

# `GlobalID.app` is ordinarily set by Active Record's own railtie — `test/dummy`
# deliberately loads no Active Record (D5: the engine needs nothing beyond Action Pack
# and Action View), so nothing else here ever sets it. Only *minting* a GlobalID
# (`to_gid_param`, which these tests need in order to build a realistic signed stream
# name) requires it; `GlobalID::Locator.locate` — what
# `Crosswire::AuthorizedStreamChannel#streamables` actually calls — does not, since
# parsing an already-minted GID URI is app-agnostic. Set only if unset, so a real host
# app's own value (always present once it has Active Record, which any app broadcasting
# model changes over Turbo Streams will) is never clobbered.
GlobalID.app ||= Rails.application.railtie_name

module CrosswireStreams
  # Stands in for the `ActiveRecord::Base` a real app's streamable almost always is.
  # `GlobalID::Identification` only needs `#id` and a class-level `#find` — plain Ruby
  # is enough, no Active Record required.
  class Board
    include GlobalID::Identification

    attr_reader :id

    def initialize(id) = @id = id.to_s

    def self.find(id) = new(id)

    def ==(other) = other.is_a?(Board) && id == other.id
  end

  # Records exactly what `authorized?` was called with and what it should answer, so a
  # test can assert on the located `streamables` without the channel needing any other
  # test-only surface.
  class RecordingChannel < Crosswire::AuthorizedStreamChannel
    class << self
      attr_accessor :last_received, :verdict
    end

    private

    def authorized?(*streamables)
      self.class.last_received = streamables
      self.class.verdict
    end
  end

  class RejectingChannel < Crosswire::AuthorizedStreamChannel
    private

    def authorized?(*) = false
  end

  # Deliberately does NOT override `authorized?` — this IS the fail-closed default
  # under test, not a fixture left unfinished.
  class NoOverrideChannel < Crosswire::AuthorizedStreamChannel
  end

  # ---------------------------------------------------------------------------------
  # RecordingChannel — the confirm/stream path, connection identifiers, and streamable
  # relocation (GID segments located, raw strings passed through).
  # ---------------------------------------------------------------------------------
  class RecordingChannelTest < ActionCable::Channel::TestCase
    tests RecordingChannel

    def test_valid_signature_and_authorized_confirms_and_streams
      RecordingChannel.verdict = true
      stub_connection(current_user: "jake")

      subscribe signed_stream_name: Turbo::StreamsChannel.signed_stream_name(["room"])

      assert subscription.confirmed?
      assert_has_stream "room"
      assert_equal "jake", subscription.connection.current_user
    end

    def test_multi_streamable_locates_gids_and_passes_strings_through
      RecordingChannel.verdict = true
      board = Board.new(42)

      subscribe signed_stream_name: Turbo::StreamsChannel.signed_stream_name([board, :entries])

      assert subscription.confirmed?
      received = RecordingChannel.last_received

      assert_equal 2, received.size
      assert_instance_of Board, received.first
      assert_equal "42", received.first.id
      assert_equal "entries", received.last
      assert_instance_of String, received.last
    end

    def test_missing_signed_stream_name_rejects
      subscribe

      assert subscription.rejected?
      assert_no_streams
    end

    def test_tampered_signed_stream_name_rejects
      subscribe signed_stream_name: "not-a-real-signature"

      assert subscription.rejected?
      assert_no_streams
    end
  end

  # ---------------------------------------------------------------------------------
  # RejectingChannel — a valid signature does not, on its own, mean confirmed.
  # ---------------------------------------------------------------------------------
  class RejectingChannelTest < ActionCable::Channel::TestCase
    tests RejectingChannel

    def test_valid_signature_but_unauthorized_rejects
      subscribe signed_stream_name: Turbo::StreamsChannel.signed_stream_name(["room"])

      assert subscription.rejected?
      assert_no_streams
    end
  end

  # ---------------------------------------------------------------------------------
  # NoOverrideChannel — the fail-closed default itself, exercised end to end.
  # ---------------------------------------------------------------------------------
  class NoOverrideChannelTest < ActionCable::Channel::TestCase
    tests NoOverrideChannel

    def test_fails_closed_without_an_authorized_override
      subscribe signed_stream_name: Turbo::StreamsChannel.signed_stream_name(["room"])

      assert subscription.rejected?
      assert_no_streams
    end
  end
end
