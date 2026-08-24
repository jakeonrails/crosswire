# frozen_string_literal: true

require "rails/generators"
require "rails/engine"
require "crosswire"
require "crosswire/engine" unless defined?(Crosswire::Engine)

module Crosswire
  module Generators
    # `rails g crosswire:skills` — copy the agent skills the gem ships (skills/* at the
    # gem root) into the host app's .claude/skills/, so coding agents working in the
    # app load them. Three skills today — crosswire-ui (use the primitives),
    # crosswire-composing (build composite widgets by stacking primitives), and
    # crosswire-authoring (write a new controller that survives the component
    # contract) — but the set is discovered from the gem's own skills/ directory at
    # run time, never hardcoded, exactly the way the eject generator discovers
    # components from the filesystem: the filesystem is the only source that cannot
    # drift from what is actually shipped.
    #
    #   rails g crosswire:skills           # copy (or refresh) every shipped skill
    #   rails g crosswire:skills --force   # overwrite locally edited copies
    #
    # Idempotent: files are written through Thor's create_file, so an unchanged file
    # is a silent no-op ("identical"), a locally edited one prompts (or is preserved
    # under --skip / overwritten under --force), and the summary names what landed.
    class SkillsGenerator < Rails::Generators::Base
      # Same reasoning as EjectGenerator: a script running this non-interactively
      # should see a non-zero exit on a real error rather than Thor's default
      # swallow-and-continue.
      def self.exit_on_failure?
        true
      end

      desc <<~DESC
        Copy crosswire's agent skills into this app's .claude/skills/, so coding
        agents (Claude Code and compatible) pick them up when working in this app.

        The skills teach an agent to use the primitives (Rule 0 first), compose them
        into composite widgets, and author new controllers against the component
        contract. Re-run after upgrading the gem to refresh them; local edits are
        never overwritten without --force.
      DESC

      def copy_skills
        if skill_names.empty?
          say_status :info, "This crosswire build ships no skills — nothing to copy.", :yellow
          return
        end

        skill_names.each do |skill|
          skill_files(skill).each do |source|
            relative = source.relative_path_from(skills_dir)
            create_file ".claude/skills/#{relative}", File.binread(source)
          end
        end

        say <<~MSG

          Copied #{skill_names.size} crosswire skill#{"s" unless skill_names.size == 1} \
          into .claude/skills/: #{skill_names.join(", ")}.

          Agents working in this app now load them automatically. Re-run this
          generator after upgrading crosswire to refresh them (--force overwrites
          local edits).
        MSG
      end

      private

      def skills_dir
        Crosswire::Engine.root.join("skills")
      end

      def skill_names
        return [] unless skills_dir.directory?

        skills_dir.children.select(&:directory?).map { |dir| dir.basename.to_s }.sort
      end

      def skill_files(skill)
        Pathname.glob(skills_dir.join(skill, "**", "*")).select(&:file?).sort
      end
    end
  end
end
