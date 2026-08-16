# frozen_string_literal: true

require_relative "boot"

require "rails"

# Deliberately NOT `rails/all`. crosswire is a view-layer gem; the dummy host proves it
# needs nothing beyond Action Pack and Action View — no Active Record, no Active Job.
# If the engine ever grows an accidental dependency on a framework it does not declare,
# this app stops booting, which is the point.
require "action_controller/railtie"
require "action_view/railtie"

require "propshaft"
require "importmap-rails"
require "lookbook"

require "crosswire"

module Dummy
  class Application < Rails::Application
    config.load_defaults 8.1

    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.secret_key_base = "crosswire-dummy-app-not-a-real-secret-key-base-0123456789"
    config.consider_all_requests_local = true
    config.hosts.clear

    # --- test seams ---------------------------------------------------------------
    #
    # `Crosswire::ShadowCheck` runs at boot and resolves partials through this app's
    # own view paths, so the only honest way to test it is to boot with a shadowing
    # partial actually in place. This lets the integration suite hand a throwaway
    # directory to a child process rather than writing into the checked-in app.
    if ENV["CROSSWIRE_EXTRA_VIEW_PATH"].to_s != ""
      config.paths["app/views"].unshift(ENV["CROSSWIRE_EXTRA_VIEW_PATH"])
    end

    # `nil` (the default) means "let the engine decide from Rails.env".
    unless ENV["CROSSWIRE_SHADOW_CHECK"].nil?
      config.crosswire_shadow_check = ENV["CROSSWIRE_SHADOW_CHECK"] == "true"
    end

    # ShadowCheck's "no contract marker" path only WARNS, through `Rails.logger`. To
    # assert on that honestly it has to be captured from the real boot, not re-run
    # afterwards with a stub.
    config.logger = ActiveSupport::Logger.new(ENV["CROSSWIRE_LOG_TO"]) if ENV["CROSSWIRE_LOG_TO"]

    # --- Lookbook -----------------------------------------------------------------
    #
    # Lookbook's default preview controller is a bare `Rails::ApplicationController`,
    # so engine helpers are not available in previews (lookbook#745) and the engine's
    # view path is absent. Both are fixed by pointing it at our own controller.
    config.lookbook.project_name = "crosswire"
    config.lookbook.preview_paths = [File.expand_path("../lookbook/previews", __dir__)]
    config.lookbook.preview_controller = "CrosswirePreviewController"
    # Previews are live, not screenshots: this layout loads the same importmap the host
    # app does, so every component in Lookbook is a connected Stimulus controller.
    config.lookbook.preview_layout = "crosswire_preview"
    config.lookbook.preview_display_options = {}
    config.lookbook.ui_theme = "indigo"
  end
end
