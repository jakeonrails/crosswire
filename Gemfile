# frozen_string_literal: true

source "https://rubygems.org"
gemspec

gem "rails", "~> 8.1"
gem "minitest", "~> 5.25"
gem "rake", "~> 13.2"

# Everything below exists only for `test/dummy` — the engine's host app, used by the
# integration suite and by the Lookbook preview server. NONE of it is a dependency of
# the gem itself; `crosswire.gemspec` stays at railties + actionview (D5).
#
# Lookbook pulls in `view_component` transitively. That is acceptable HERE and only
# here: D5 forbids ViewComponent as a *gem* dependency, not as a dev tool of the
# demo host. Crosswire ships zero ViewComponent components — the previews render
# our ERB partials and helpers directly.
group :development, :test do
  gem "propshaft"
  gem "importmap-rails"
  gem "puma"
  gem "lookbook"

  # Pulls in `actioncable`. Needed only for `Crosswire::Streams` (the
  # `AuthorizedStreamChannel` piece of the survivability tier) and its dummy-app
  # cable wiring — `crosswire.gemspec` stays at railties + actionview (D5); neither
  # `turbo-rails` nor `actioncable` is ever a load-time requirement of the plain-Ruby
  # core (see lib/crosswire/streams.rb).
  gem "turbo-rails"
end
