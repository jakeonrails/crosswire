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
require "nokogiri"

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

  # ===================================================================================
  # Crosswire::Streams::Versioned + the versioned_replace helpers — piece 4.
  #
  # `test/dummy` deliberately loads no Active Record (D5 — see the app/config.rb header
  # comment), so the "requires optimistic locking" concern cannot be exercised against a
  # real `ActiveRecord::Base` here. `Crosswire::Streams::Versioned` is written to need
  # nothing but `respond_to?(:lock_version)`, so a plain Ruby double proves the same
  # contract an ActiveRecord model with (or without) a `lock_version` column would:
  # ===================================================================================

  # A plain PORO standing in for a versioned ActiveRecord model — has `lock_version`,
  # the way any model with optimistic locking enabled does, and nothing else
  # `Crosswire::Streams::Versioned` needs.
  class VersionableWidget
    include Crosswire::Streams::Versioned

    attr_accessor :lock_version

    def initialize(lock_version:) = @lock_version = lock_version

    def to_param = "widget"
  end

  # Deliberately has NO `lock_version` — this IS the unversioned model under test, not
  # a fixture left unfinished (mirrors `NoOverrideChannel` above).
  class UnversionedWidget
    include Crosswire::Streams::Versioned
  end

  # ---------------------------------------------------------------------------------
  # crosswire_stream_version
  # ---------------------------------------------------------------------------------
  class VersionedConcernTest < ActiveSupport::TestCase
    def test_crosswire_stream_version_raises_without_lock_version
      error = assert_raises(Crosswire::Error) { UnversionedWidget.new.crosswire_stream_version }

      assert_match(/lock_version/, error.message)
      assert_match(/UnversionedWidget/, error.message)
    end

    def test_crosswire_stream_version_returns_lock_version_when_present
      widget = VersionableWidget.new(lock_version: 7)

      assert_equal 7, widget.crosswire_stream_version
    end
  end

  # ---------------------------------------------------------------------------------
  # broadcast_versioned_replace_to / broadcast_versioned_replace_later_to — thin
  # wrappers over Turbo::StreamsChannel.broadcast_action_[later_]to. The synchronous
  # method is exercised end to end, over the real Action Cable test adapter
  # (`ActionCable::TestHelper`, the same test-adapter architecture
  # `ActionCable::Channel::TestCase` above builds on); the `_later_to` variant is
  # exercised by stubbing `Turbo::StreamsChannel.broadcast_action_later_to` instead of
  # actually enqueuing an Active Job — `test/dummy` deliberately loads no Active Job
  # (see config/application.rb's header comment), so asserting on a *real* enqueue here
  # would test Active Job's own autoloading rather than this thin wrapper's forwarding.
  # ---------------------------------------------------------------------------------
  class BroadcastVersionedReplaceTest < ActiveSupport::TestCase
    include ActionCable::TestHelper

    # Builds the exact `<turbo-stream>` markup `Turbo::StreamsChannel.broadcast_action_to`
    # itself would produce for the given action/target/template — reusing turbo-rails'
    # own tag-building method (mixed onto `Turbo::StreamsChannel` the same way
    # `broadcast_action_to` reaches it) rather than hand-assembling an HTML string that
    # would silently drift from whatever turbo-rails actually renders.
    def expected_stream_html(action:, target:, template:)
      Turbo::StreamsChannel.turbo_stream_action_tag(action, target: target, template: template)
    end

    def test_broadcast_versioned_replace_to_emits_a_versioned_replace_stream_carrying_the_version
      widget = VersionableWidget.new(lock_version: 3)
      html = %(<div id="widget_1" data-cw-version="3">Widget</div>)
      expected = expected_stream_html(action: :versioned_replace, target: "widget_1", template: html)

      assert_broadcast_on("room", expected) do
        widget.broadcast_versioned_replace_to("room", target: "widget_1", html: html)
      end
    end

    def test_broadcast_versioned_replace_to_defaults_target_to_self_like_broadcast_replace_to
      widget = VersionableWidget.new(lock_version: 1)
      html = "<div>Widget</div>"
      # `target:` omitted — `broadcast_versioned_replace_to` must default it to `self`
      # (the widget), exactly as `Turbo::Broadcastable#broadcast_replace_to` defaults
      # its own target. Proven by reusing the exact same `widget` instance to build
      # `expected`: if the defaulting were dropped, `Turbo::StreamsChannel.broadcast_action_to`
      # would fall back to ITS OWN `target: nil` default instead, which renders no
      # `target` attribute at all — a structurally different, easily-distinguished tag,
      # not merely a differently-formatted one.
      expected = expected_stream_html(action: :versioned_replace, target: widget, template: html)

      assert_broadcast_on("room", expected) do
        widget.broadcast_versioned_replace_to("room", html: html)
      end
    end

    def test_broadcast_versioned_replace_later_to_forwards_the_versioned_replace_action
      widget = VersionableWidget.new(lock_version: 5)
      recorded = nil
      stub = ->(*streamables, **opts) { recorded = [streamables, opts] }

      Turbo::StreamsChannel.stub(:broadcast_action_later_to, stub) do
        widget.broadcast_versioned_replace_later_to("room", target: "widget_1", html: "<div>x</div>")
      end

      streamables, opts = recorded
      assert_equal ["room"], streamables
      assert_equal :versioned_replace, opts[:action]
      assert_equal "widget_1", opts[:target]
      assert_equal "<div>x</div>", opts[:html]
    end
  end

  # ---------------------------------------------------------------------------------
  # crosswire_version_attrs / crosswire_versioned_replace — the helper half, rendered
  # through real ERB/ActionView the same way `StreamsHelperTest` covers
  # `crosswire_stream_from` in `integration_test_runner.rb`.
  # ---------------------------------------------------------------------------------
  module Dom
    def dom(html) = Nokogiri::HTML5.fragment(html.to_s)

    def node(html, selector)
      found = dom(html).at_css(selector)
      found || flunk("no element matching #{selector.inspect} in:\n\n#{html}")
    end
  end

  class VersionAttrsHelperTest < ActionView::TestCase
    include Dom

    helper Crosswire::StreamsHelper

    def test_crosswire_version_attrs_accepts_a_versionable_object
      widget = VersionableWidget.new(lock_version: 9)

      assert_equal({"data-cw-version" => "9"}, view.crosswire_version_attrs(widget))
    end

    def test_crosswire_version_attrs_accepts_a_plain_integer
      assert_equal({"data-cw-version" => "12"}, view.crosswire_version_attrs(12))
    end

    def test_crosswire_versioned_replace_renders_a_versioned_replace_turbo_stream
      # `.html_safe` matters here the same way it would for any `turbo_stream.replace
      # "id", html: "..."` call site — `Turbo::Streams::TagBuilder#action` renders an
      # unsafe `html:` string through `ActionView::Base#render`, which HTML-escapes
      # plain strings by default (the ordinary Rails XSS guard); nothing
      # `crosswire_versioned_replace` does changes that, since it forwards `**rendering`
      # as-is rather than reimplementing rendering.
      html = view.crosswire_versioned_replace("widget_1", html: '<div id="widget_1" data-cw-version="3"></div>'.html_safe)
      el = node(html, "turbo-stream")

      assert_equal "versioned_replace", el["action"]
      assert_equal "widget_1", el["target"]
      assert_equal "3", node(html, "#widget_1")["data-cw-version"]
    end
  end
end
