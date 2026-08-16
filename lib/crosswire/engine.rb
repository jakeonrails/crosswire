# frozen_string_literal: true

require "rails/engine"

module Crosswire
  class Engine < ::Rails::Engine
    isolate_namespace Crosswire

    # Presenters are pure POROs in lib/, not app/, precisely so they can be required
    # and unit-tested without Rails. Autoload them anyway for convenience in apps.
    config.autoload_paths << root.join("lib/crosswire/presenters")
    config.eager_load_paths << root.join("lib/crosswire/presenters")

    # Serve our controllers through the asset pipeline (Propshaft or Sprockets).
    initializer "crosswire.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app/assets/javascripts")
      end
    end

    # Make every controller individually importable so consumers can lazy-load them.
    #
    # A single bundle CANNOT be lazy-loaded: stimulus-loading registers via a dynamic
    # `import("${under}/${name}_controller")`, which needs one module per controller.
    # See docs/DECISIONS.md R2.
    #
    # Runs AFTER importmap-rails' own "importmap" initializer, not before it, because
    # that is the initializer that assigns `app.importmap` in the first place:
    #
    #   initializer "importmap" do |app|
    #     app.importmap = Importmap::Map.new
    #     …
    #   end
    #
    # `app.respond_to?(:importmap)` is not a usable guard for this — importmap-rails
    # installs the accessor with `Rails::Application.send(:attr_accessor, :importmap)`
    # at require time, so it answers true long before the map exists. Running `before:`
    # therefore always hit `nil.draw`. Drawing afterwards is safe: `Importmap::Map#draw`
    # accumulates, and the reloader only re-draws the app's own config paths, so our
    # directory pin survives a reload.
    initializer "crosswire.importmap", after: "importmap" do |app|
      next unless app.respond_to?(:importmap) && app.importmap

      app.importmap.draw do
        pin_all_from Crosswire::Engine.root.join("app/assets/javascripts/crosswire/controllers"),
                     under: "crosswire/controllers"

        # A non-controller module, pinned individually rather than swept up by
        # `pin_all_from` above (which only walks the controllers/ directory) — see the
        # header comment on morph.js for why it lives outside controllers/ in the
        # first place. Consumers import it directly: `import { usePreserve } from
        # "crosswire/morph"`.
        pin "crosswire/morph", to: "crosswire/morph.js"

        # Same reasoning as `crosswire/morph` above — registers into
        # `Turbo.StreamActions`, not into Stimulus, so it is not a controller either.
        # `import { registerCrosswireStreamActions } from "crosswire/stream_actions"`.
        pin "crosswire/stream_actions", to: "crosswire/stream_actions.js"
      end

      # Sprockets needs this; Propshaft serves everything on `config.assets.paths` and
      # keeps `precompile` only as a compatibility shim, so appending is a harmless
      # no-op there.
      if app.config.respond_to?(:assets)
        app.config.assets.precompile << "crosswire/index.js"
        app.config.assets.precompile << "crosswire/morph.js"
        app.config.assets.precompile << "crosswire/stream_actions.js"
      end
    end

    # Helpers are opt-in per component rather than blanket-included, so crosswire adds
    # nothing to a consumer's helper surface until they ask for it.
    initializer "crosswire.helpers" do
      ActiveSupport.on_load(:action_view) do
        include Crosswire::AttributesHelper
      end
    end

    # `Crosswire::Streams` (the `AuthorizedStreamChannel` piece of the survivability
    # tier) needs actioncable + turbo-rails — neither is a gem dependency (D5) — so it
    # is deliberately absent from the `autoload_paths`/`eager_load_paths` above and
    # never required by `lib/crosswire.rb`. This initializer is its only load path.
    #
    # `defined?(Turbo::Engine)` is a truthful gate specifically HERE: `Bundler.require`
    # has already loaded every gem in the Gemfile before any initializer body runs, so
    # by the time this block executes, `Turbo::Engine` is defined if and only if
    # turbo-rails is actually in the bundle. `to_prepare` (rather than a bare
    # initializer, or `after_initialize`) matters too: it runs after Zeitwerk's
    # autoloaders are ready, which is what makes `Turbo::StreamsChannel` — itself set
    # up by turbo-rails' own initializers, which have already run by then — resolvable
    # when `crosswire/streams` requires `crosswire/streams/authorized_stream_channel`.
    # `require` is idempotent, so `to_prepare` re-running this on every class-cache
    # reload in development is harmless.
    initializer "crosswire.streams" do |app|
      app.config.to_prepare do
        require "crosswire/streams" if defined?(Turbo::Engine)
      end
    end

    # Verify any partial the app has shadowed still matches the contract we ship
    # against. This is what makes ejection (D6) and view-path override (D5) safe:
    # copy/paste normally has no staleness signal, and this gives it one.
    #
    # Development and test only — a boot-time filesystem walk has no business running
    # in production, and a stale shadow will have been caught long before deploy.
    config.after_initialize do |app|
      enabled = if app.config.respond_to?(:crosswire_shadow_check)
                  app.config.crosswire_shadow_check
                end
      enabled = Rails.env.local? if enabled.nil?
      next unless enabled

      Crosswire::ShadowCheck.new(app).run
    end
  end
end
