# frozen_string_literal: true

require "rails/generators"
require "rails/engine"
require "crosswire"
require "crosswire/engine" unless defined?(Crosswire::Engine)

module Crosswire
  module Generators
    # `rails g crosswire:install` — set up the STYLED component tier's CSS in a host
    # app. Unlike the primitive tier (JS behaviours, wired automatically through the
    # engine's importmap initializer — see lib/crosswire/engine.rb), the UI tier's
    # tokens/base/component CSS is opt-in: an app that never calls a `cw.button` (or
    # any other UI helper) should not pay for a stylesheet it never uses, so nothing
    # in engine.rb auto-injects a `<link>`. This generator writes the ONE file that
    # decides that — an `@import` manifest the app owns from here on (spec §4).
    #
    #   rails g crosswire:install             # writes app/assets/stylesheets/crosswire.css
    #   rails g crosswire:install --tokens     # + copies tokens.css in for direct editing
    #   rails g crosswire:install --tailwind   # + a placeholder for the (v1.1) @theme mapping
    class InstallGenerator < Rails::Generators::Base
      # Same reasoning as EjectGenerator/SkillsGenerator: a script running this
      # non-interactively should see a non-zero exit on a real error.
      def self.exit_on_failure? = true

      desc <<~DESC
        Set up crosswire's styled component tier: writes
        app/assets/stylesheets/crosswire.css, an @import manifest YOU own from here on
        (crosswire writes it once and never edits it again). Add the printed
        stylesheet_link_tag to your layout to actually load it.
      DESC

      class_option :tokens, type: :boolean, default: false,
                             desc: "Copy tokens.css into the app for direct editing, " \
                                   "in addition to the gem's own (same cascade layer, " \
                                   "loaded after — your copy wins property by property)"
      class_option :tailwind, type: :boolean, default: false,
                               desc: "Append a placeholder for the Tailwind @theme " \
                                     "mapping — the mapping file itself ships in v1.1"

      MANIFEST_PATH = "app/assets/stylesheets/crosswire.css"
      LOCAL_TOKENS_PATH = "app/assets/stylesheets/crosswire/ui/tokens.css"

      def install
        copy_local_tokens if options[:tokens]
        write_manifest
        say_next_steps
      end

      private

      # The app's own copy lands in the SAME `crosswire.tokens` cascade layer as the
      # gem's (tokens.css wraps itself in `@layer crosswire.tokens { ... }`), and is
      # `@import`ed AFTER the gem's bundle in the manifest below — within one named
      # layer, the later declaration wins property by property, so this file need not
      # duplicate base.css or omit the gem's bundle to take effect. It DOES mean this
      # copy stops receiving upstream token changes; diff against the gem's own
      # tokens.css by hand to pull in updates.
      def copy_local_tokens
        source = Crosswire::Engine.root.join("app/assets/stylesheets/crosswire/ui/tokens.css")
        create_file LOCAL_TOKENS_PATH, File.binread(source)
      end

      def write_manifest
        create_file MANIFEST_PATH, <<~CSS
          /* This file is yours — crosswire wrote it once via `rails g crosswire:install`
             and will never edit it again. Reorder, remove, or add your own imports. */
          @import "crosswire/ui.css";
          #{options[:tokens] ? local_tokens_import : ""}#{tailwind_placeholder}
        CSS
      end

      def local_tokens_import
        <<~CSS
          @import "crosswire/ui/tokens.css"; /* --tokens: your copy, overrides the gem's above */
        CSS
      end

      def tailwind_placeholder
        return "" unless options[:tailwind]

        <<~CSS

          /* --tailwind was requested: the @theme mapping (spec's JAKE-2 default) is
             held to v1.1 and does not exist yet — nothing to import here today. */
        CSS
      end

      def say_next_steps
        say <<~MSG

          Wrote #{MANIFEST_PATH}.

          Add this to your layout's <head>:

              <%= stylesheet_link_tag "crosswire" %>

          #{options[:tokens] ? "#{LOCAL_TOKENS_PATH} is now yours too — edit token values directly.\n\n" : ""}That's the whole install: every crosswire UI component's CSS reaches the page
          through this one manifest.
        MSG
      end
    end
  end
end
