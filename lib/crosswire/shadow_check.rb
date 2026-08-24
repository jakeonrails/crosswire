# frozen_string_literal: true

module Crosswire
  # Detect app-shadowed or ejected crosswire partials that have gone stale.
  #
  # Both of crosswire's customization paths work by putting a copy of our markup in the
  # consumer's app: view-path shadowing (D5) and `rails g crosswire:eject` (D6). Both
  # share one failure mode, and it is the strongest argument against the whole approach:
  #
  #   crosswire v2 changes the markup a controller expects. The app's copy still says v1.
  #   Nothing errors. The component silently misbehaves.
  #
  # Copy/paste component libraries generally have no answer to this — once you copy, you
  # are on your own with no signal that upstream moved. This is that signal.
  #
  # Every shipped partial carries a marker:
  #
  #   <%# crosswire:contract v1 %>
  #
  # At boot we resolve each shipped partial through the app's own LookupContext. If the
  # winner is not ours, we read its marker and compare. Mismatch raises with the file
  # path and both versions; a missing marker warns.
  class ShadowCheck
    MARKER = /crosswire:contract\s+v(\d+)/

    class StaleShadowError < StandardError; end

    def initialize(app, contract_version: Crosswire::CONTRACT_VERSION)
      @app = app
      @contract_version = contract_version
      @engine_views = Crosswire::Engine.root.join("app/views").to_s
    end

    def run
      stale = []
      unmarked = []

      shipped_partials.each do |name, expected_version|
        resolved = resolve(name)
        next if resolved.nil?                          # not overridden, or unresolvable
        next if resolved.start_with?(@engine_views)    # ours won; nothing to check

        version = contract_version_in(resolved)
        if version.nil?
          unmarked << [resolved, expected_version]
        elsif version != expected_version
          stale << [resolved, version, expected_version]
        end
      end

      warn_unmarked(unmarked) if unmarked.any?
      raise_stale(stale) if stale.any?

      true
    end

    private

    # Widened to `**/_*.html.erb` so it also walks app/views/crosswire/ui/ — empty
    # through Phase 0, but the UI tier's partials will land there (spec §2's file
    # list). Each partial is paired with the CONTRACT_VERSION that actually governs
    # it: a UI partial's `<%# crosswire:contract vN %>` marker means
    # `Crosswire::UI::CONTRACT_VERSION`, not the primitive tier's — the two counters
    # are independent (see lib/crosswire/ui.rb's own docstring on why) and a UI
    # partial checked against the wrong one would raise a false "stale shadow" the
    # moment the two version numbers ever drift.
    def shipped_partials
      Dir[Crosswire::Engine.root.join("app/views/crosswire/**/_*.html.erb")].map do |path|
        relative = path.delete_prefix("#{Crosswire::Engine.root.join("app/views/crosswire")}/")
        name = "crosswire/#{relative.sub(%r{(^|/)_}, '\1').sub(/\.html\.erb\z/, "")}"
        expected_version = relative.start_with?("ui/") ? ui_contract_version : @contract_version
        [name, expected_version]
      end
    end

    def ui_contract_version
      require "crosswire/ui"
      Crosswire::UI::CONTRACT_VERSION
    end

    # Ask the app which template actually wins, using the same lookup Rails will use
    # at render time — not a filesystem guess.
    #
    # Split on the LAST "/", not the first: `render partial:` resolves against a
    # PREFIX (everything but the final segment) and a partial name (the final
    # segment) — for "crosswire/dialog" that is prefix "crosswire", partial
    # "dialog", but for a nested UI partial "crosswire/ui/button" it is prefix
    # "crosswire/ui", partial "button", not prefix "crosswire" with partial
    # "ui/button" (which `ActionView::LookupContext#find_all` cannot resolve).
    def resolve(name)
      prefix, _, partial = name.rpartition("/")
      lookup = ActionView::LookupContext.new(@app.config.paths["app/views"].existent + view_paths)
      template = lookup.find_all(partial, [prefix], true).first
      template&.identifier
    rescue StandardError
      nil
    end

    def view_paths
      paths = []
      paths.concat(ActionController::Base.view_paths.map(&:to_s)) if defined?(ActionController::Base)
      paths << @engine_views
      paths.uniq
    end

    def contract_version_in(path)
      return nil unless File.readable?(path)

      File.read(path)[MARKER, 1]&.to_i
    end

    def warn_unmarked(entries)
      # Each line names the exact marker to add for THAT file — a UI partial and a
      # primitive partial can expect different version numbers (see
      # `shipped_partials` above), so one blanket "vN" cannot be correct for both.
      lines = entries.map { |path, expected| "  #{path}\n    add `<%# crosswire:contract v#{expected} %>`" }
      Rails.logger&.warn(<<~MSG)
        [crosswire] Overriding a crosswire partial without a contract marker:
        #{lines.join("\n")}
        so upgrades can warn you when the markup contract changes. `rails g
        crosswire:eject` adds it for you.
      MSG
    end

    def raise_stale(stale)
      details = stale.map { |path, version, expected| "  #{path}\n    declares v#{version}, crosswire ships v#{expected}" }
      raise StaleShadowError, <<~MSG
        [crosswire] Stale component markup.

        #{details.join("\n")}

        These files were copied from an older crosswire and its markup contract has since
        changed, so the shipped controllers may no longer find what they expect.

        Re-eject to take the new markup (your customizations will be overwritten):
          bin/rails g crosswire:eject <component> --force

        Or diff against the current source and bump the marker to the version shown
        above (per file) once reconciled.
        To silence this entirely: config.crosswire_shadow_check = false
      MSG
    end
  end
end
