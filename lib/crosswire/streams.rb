# frozen_string_literal: true

require "crosswire"

# `Crosswire::Streams` — the Ruby-side half of the survivability tier's stream pieces:
# authorization (`Crosswire::AuthorizedStreamChannel` + `cw.stream_from`) and
# monotonic-version ordering (`Crosswire::Streams::Versioned` +
# `cw.version_attrs` / `cw.versioned_replace`, in `streams_helper.rb`).
#
# NOT required by lib/crosswire.rb, NOT in the engine's autoload/eager-load paths.
# `Crosswire::AuthorizedStreamChannel < Turbo::StreamsChannel` needs turbo-rails (and,
# transitively, actioncable) — neither is a gem dependency (D5: the gemspec stays at
# railties + actionview) and neither may be a load-time requirement of the plain-Ruby
# core, which `ruby -Ilib -rcrosswire -e '...'` must keep working with zero Rails or
# Turbo installed at all.
#
# The one load path that IS safe: `lib/crosswire/engine.rb`'s "crosswire.streams"
# initializer requires this file from a `to_prepare` hook, gated on
# `defined?(Turbo::Engine)`. That gate is truthful only there — `Bundler.require` has
# already loaded every gem in the Gemfile before any initializer runs, so by the time
# any initializer body executes, `Turbo::Engine` is defined if and only if turbo-rails
# is actually in the bundle. `to_prepare` specifically (over `after_initialize` or a
# bare `initializer` block) because it runs AFTER Zeitwerk's autoloaders are ready,
# which is what makes `Turbo::StreamsChannel` resolvable below when this file requires
# `crosswire/streams/authorized_stream_channel`. The require is idempotent, so
# `to_prepare` re-running on every class-cache reload in development is harmless.
#
# Requiring this file directly, without turbo-rails loaded, raises a clear
# `Crosswire::Error` instead of a bare `NameError: uninitialized constant
# Turbo::StreamsChannel` three lines into a file the caller didn't write:
#
#   require "crosswire/streams"
#   # Crosswire::Error: Crosswire::Streams needs turbo-rails (Turbo::StreamsChannel is
#   # not defined). Add `gem "turbo-rails"` to your Gemfile.
unless defined?(Turbo::StreamsChannel)
  raise Crosswire::Error, "Crosswire::Streams needs turbo-rails (Turbo::StreamsChannel is not " \
                           "defined). Add `gem \"turbo-rails\"` to your Gemfile."
end

require "crosswire/streams/authorized_stream_channel"
require "crosswire/streams/versioned"

module Crosswire
  # `Crosswire::AuthorizedStreamChannel` — the public name. The class itself lives in
  # the `Crosswire::Streams` namespace (see authorized_stream_channel.rb) so that this
  # file, and everything else `lib/crosswire/streams/` grows (`Crosswire::Streams::Versioned`,
  # in versioned.rb), has one namespace to hang off; this constant is the short,
  # memorable alias a consumer actually subclasses.
  AuthorizedStreamChannel = Crosswire::Streams::AuthorizedStreamChannel
end
