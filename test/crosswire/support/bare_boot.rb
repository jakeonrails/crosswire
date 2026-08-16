# frozen_string_literal: true

# Boots a bare Rails application with the crosswire engine loaded but with **no
# importmap-rails and no asset pipeline at all** — a jsbundling/esbuild app, say, or an
# API-ish app that only renders a few HTML pages.
#
# Both of the engine's asset-facing initializers are conditional, and both conditions
# have to be right or the engine takes the host app's boot down with it. `test/dummy`
# cannot cover this: it deliberately has both.
#
# Prints BARE_BOOT_OK, or the exception, and reports what the guards saw.

require "tmpdir"

$LOAD_PATH.unshift File.expand_path("../../../lib", __dir__)

require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "crosswire"

module BareHost
  class Application < Rails::Application
    config.root = Dir.mktmpdir("crosswire-bare")
    config.eager_load = false
    config.secret_key_base = "crosswire-bare-boot-not-a-real-secret-key-base-0123"
    config.crosswire_shadow_check = false
  end
end

begin
  BareHost::Application.initialize!
  puts "BARE_BOOT_OK"
rescue Exception => e # rubocop:disable Lint/RescueException -- reporting, not handling
  puts "BARE_BOOT_RAISED #{e.class}: #{e.message}"
  exit 1
end

puts "importmap=#{Rails.application.respond_to?(:importmap)}"
puts "assets=#{Rails.application.config.respond_to?(:assets)}"
puts "attributes_helper=#{ActionView::Base.ancestors.include?(Crosswire::AttributesHelper)}"
