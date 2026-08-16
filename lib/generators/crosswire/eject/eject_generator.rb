# frozen_string_literal: true

require "rails/generators"
require "rails/engine"
require "crosswire"
require "crosswire/engine" unless defined?(Crosswire::Engine)

module Crosswire
  module Generators
    # `rails g crosswire:eject <component>` — tiered ejection out of the gem and into
    # the consumer's own app. See docs/DECISIONS.md D6 for the tier table and the case
    # for why this beats plain shadcn-style copy/paste: accessibility lives in the
    # presenter (Ruby), not the markup, so an ejected partial stays accessible even
    # after a total restyle, and `Crosswire::ShadowCheck` gives it a version contract
    # that copy/paste otherwise has no answer to.
    #
    #   rails g crosswire:eject disclosure               # markup only (default)
    #   rails g crosswire:eject disclosure --controller  # markup + JS, fully owned
    #   rails g crosswire:eject --all                     # every component's markup
    #   rails g crosswire:eject disclosure --force        # overwrite an existing copy
    #
    # Component names are never hardcoded here — not every component owns a partial,
    # and the set of components is still growing. Both the "does this component have
    # markup" question and the "is this a real component" question are answered by
    # listing the engine's own app/views and app/assets/javascripts directories at
    # generator run time, so this generator stays correct as components land.
    class EjectGenerator < Rails::Generators::Base
      # Rails::Generators::Base sets this to false so a bad generator invocation never
      # takes down an interactive `rails new` flow. We want the opposite: a script
      # running this non-interactively should see a non-zero exit on a real usage
      # error (unknown component name, or no component/--all given).
      def self.exit_on_failure?
        true
      end

      desc <<~DESC
        Eject a crosswire component out of the gem and into your own app, so you own
        and can freely edit the copy.

        Tiers (see docs/DECISIONS.md D6):

          --markup (default)   copies the partial only. You still receive a11y wiring,
                                controller fixes and presenter changes from the gem —
                                only the markup shape is now yours.
          --controller          copies the partial (if any) AND the Stimulus controller,
                                re-registered under your own identifier. Full ownership;
                                you stop receiving fixes for the controller.
          --all                 copies every component's markup (markup tier only).

        Not every component owns a partial — behaviours like `dismiss` or `persist`
        decorate existing elements and ship no markup of their own. Ejecting one of
        those without --controller prints an explanation instead of writing anything.
      DESC

      argument :name, type: :string, required: false, default: nil,
                      banner: "component",
                      desc: "Component to eject, e.g. disclosure (omit when using --all)"

      class_option :controller, type: :boolean, default: false,
                                 desc: "Also eject the Stimulus controller, re-registered " \
                                       "under your own identifier — full ownership, no more " \
                                       "upstream fixes"
      class_option :all, type: :boolean, default: false,
                          desc: "Eject every component's markup (markup tier only)"

      CONTRACT_MARKER = /crosswire:contract\s+v(\d+)/

      def eject
        if options[:all]
          eject_all
        else
          eject_named
        end
      end

      private

      # --- component discovery ---------------------------------------------------
      #
      # Deliberately NOT read from `Crosswire::COMPONENTS` (lib/crosswire.rb) — that
      # registry is a work in progress (it currently lists only two components) and
      # more are landing in parallel. The filesystem is the only source that cannot
      # drift from what is actually shipped.

      def engine_root
        Crosswire::Engine.root
      end

      def views_dir
        engine_root.join("app/views/crosswire")
      end

      def controllers_dir
        engine_root.join("app/assets/javascripts/crosswire/controllers")
      end

      # Components that ship a default, ejectable partial.
      def partial_components
        Dir[views_dir.join("_*.html.erb")].map do |path|
          File.basename(path).delete_prefix("_").delete_suffix(".html.erb")
        end.sort
      end

      # Every component that ships a Stimulus controller — i.e. every component,
      # widgets and behaviours alike (see docs/COMPONENT_CONTRACT.md: the controller
      # file is "always" required).
      def controller_components
        Dir[controllers_dir.join("*_controller.js")].map do |path|
          File.basename(path).delete_suffix("_controller.js")
        end.sort
      end

      def known_components
        (partial_components + controller_components).uniq.sort
      end

      # --- dispatch ----------------------------------------------------------------

      def eject_all
        if partial_components.empty?
          say_status :info, "No component ships a partial yet — nothing to eject.", :yellow
          return
        end

        partial_components.each { |component| eject_partial(component) }

        say <<~MSG

          Ejected #{partial_components.size} partial#{"s" unless partial_components.size == 1} \
          (#{partial_components.join(", ")}) into app/views/crosswire/.

          #{upgrade_note}
        MSG
      end

      def eject_named
        if name.blank?
          raise Thor::Error, "Specify a component to eject, e.g. " \
                              "`rails g crosswire:eject disclosure`, or pass --all.\n" \
                              "Known components: #{known_components.join(", ")}"
        end

        unless known_components.include?(name)
          raise Thor::Error, "Unknown crosswire component #{name.inspect}.\n" \
                              "Known components: #{known_components.join(", ")}"
        end

        has_partial = partial_components.include?(name)

        if options[:controller]
          eject_with_controller(name, has_partial)
        elsif has_partial
          eject_partial(name)
          say <<~MSG

            Ejected app/views/crosswire/_#{name}.html.erb.

            #{upgrade_note}
          MSG
        else
          explain_no_markup(name)
        end
      end

      def eject_with_controller(name, has_partial)
        eject_controller(name)
        eject_partial(name) if has_partial

        files = ["app/javascript/controllers/#{name}_controller.js"]
        files.unshift("app/views/crosswire/_#{name}.html.erb") if has_partial

        say <<~MSG

          "#{name}" is now fully yours:
          #{files.map { |f| "  #{f}" }.join("\n")}

          Next steps:
            * Register the controller under YOUR OWN Stimulus identifier — most Rails
              setups do this automatically from the file's location (e.g. "#{name}"),
              which is exactly what you want. Do NOT register it as "cw--#{name}"; that
              identifier belongs to crosswire's own registration of this component, and
              reusing it would collide if crosswire is still loaded elsewhere in the app.
            * You will not receive any more fixes, accessibility corrections, or
              upgrades for this controller from crosswire — it is a plain Stimulus
              controller now, yours to change freely.
          #{has_partial_note(name, has_partial)}
        MSG
      end

      def has_partial_note(name, has_partial)
        return "" unless has_partial

        "  * The ejected partial still calls Crosswire::Presenters::#{presenter_class_name(name)} " \
          "for its\n    attributes (id relationships, ARIA state, etc.) — that presenter is still " \
          "the\n    gem's, and still updates with it. If you rewrite the controller's behaviour, " \
          "keep\n    the presenter call in sync or replace it too.\n"
      end

      def explain_no_markup(name)
        say_status :skip, "#{name} has no markup — it's a behaviour, not a widget.", :yellow
        say <<~MSG

          "#{name}" ships no partial (see docs/COMPONENT_CONTRACT.md) — it decorates
          existing elements rather than owning markup of its own, so there is nothing
          to eject at the markup tier.

          To take ownership of its behaviour instead, eject the controller:
            rails g crosswire:eject #{name} --controller
        MSG
      end

      # --- copying -------------------------------------------------------------

      # `copy_file` resolves its source through Thor's source_paths/source_root
      # machinery, which this generator has no use for — the "templates" it copies
      # are real, already-rendered gem files living outside any template dir. Reading
      # the bytes ourselves and handing them to `create_file` still goes through the
      # exact same Thor::Actions conflict-detection (identical?/force/skip/prompt), so
      # this is not a shortcut around requirement 6 — just a shortcut around source
      # path resolution we don't need.
      def eject_partial(component)
        source = views_dir.join("_#{component}.html.erb")
        verify_contract_marker!(source)
        create_file "app/views/crosswire/_#{component}.html.erb", File.binread(source)
      end

      def eject_controller(component)
        source = controllers_dir.join("#{component}_controller.js")
        create_file "app/javascript/controllers/#{component}_controller.js", File.binread(source)
      end

      # Belt-and-braces: fail loudly, rather than ship a silently-wrong contract, if a
      # shipped partial's marker ever doesn't match Crosswire::CONTRACT_VERSION. This
      # reads the version from the real constant every time — never a literal "v1" —
      # so it can't drift the way a hardcoded marker could.
      def verify_contract_marker!(source)
        version = File.readlines(source).first.to_s[CONTRACT_MARKER, 1]&.to_i

        return if version == Crosswire::CONTRACT_VERSION

        raise Thor::Error, "#{source} is missing a `<%# crosswire:contract " \
                            "v#{Crosswire::CONTRACT_VERSION} %>` marker (found: " \
                            "#{version.inspect}). That is a crosswire gem bug, not a usage " \
                            "error — please report it."
      end

      def upgrade_note
        "You still receive a11y wiring, controller fixes and presenter changes from " \
          "the gem — only the markup shape is now yours. `Crosswire::ShadowCheck` warns " \
          "or raises at boot if this file's contract marker ever drifts from what the " \
          "gem ships; re-run with --force to take the new markup."
      end

      def presenter_class_name(name)
        name.to_s.split(/[-_]/).map(&:capitalize).join
      end
    end
  end
end
