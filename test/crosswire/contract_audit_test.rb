# frozen_string_literal: true

require "test_helper"

module Crosswire
  # Machine-checks the rules in docs/COMPONENT_CONTRACT.md that CAN be checked
  # statically, so the contract is enforced rather than merely written down.
  #
  # Every rule here exists because breaking it produced a real bug — see the contract
  # for the story behind each. A prose contract rots the moment someone is in a hurry;
  # this makes the important half of it fail the build instead.
  #
  # Deliberately plain Ruby with no Rails and no JS parser: it reads the controller
  # sources as text. That is crude, but it runs in milliseconds as part of the normal
  # suite, and the alternative (a real JS toolchain in the Ruby tests) would not be worth
  # it. Where the text approach cannot be precise, the check is skipped rather than made
  # unreliable — a flaky lint is worse than none.
  class ContractAuditTest < Minitest::Test
    ROOT = File.expand_path("../..", __dir__)
    CONTROLLER_DIR = File.join(ROOT, "app/assets/javascripts/crosswire/controllers")
    PRESENTER_DIR = File.join(ROOT, "lib/crosswire/presenters")
    VIEW_DIR = File.join(ROOT, "app/views/crosswire")

    def controllers
      @controllers ||= Dir[File.join(CONTROLLER_DIR, "*_controller.js")].sort
    end

    # Strip comments so documentation *about* a rule never trips the check for it.
    # (An early version of this audit flagged `dismiss` for dispatching after remove()
    # because a comment explaining that very hazard mentioned `target.remove()`.)
    def code_of(path)
      File.read(path)
          .gsub(%r{/\*.*?\*/}m, "")
          .gsub(%r{^\s*//.*$}, "")
          .gsub(%r{\s//.*$}, "")
    end

    def test_there_is_at_least_one_controller_to_audit
      refute_empty controllers, "no controllers found — audit would pass vacuously"
    end

    # R3 / R3a — Stimulus THROWS on `this.fooClass` when the attribute is absent and
    # offers no default mechanism. Every read must be guarded.
    def test_every_css_class_read_is_guarded
      violations = controllers.flat_map do |path|
        code = code_of(path)
        code.scan(/this\.([a-z][a-zA-Z]*)Class\b/).flatten.uniq
            .reject { |name| name.start_with?("has") }
            .reject { |name| code.include?("this.has#{name[0].upcase}#{name[1..]}Class") }
            .map { |name| "#{File.basename(path)}: this.#{name}Class without has#{name[0].upcase}#{name[1..]}Class" }
      end

      assert_empty violations, <<~MSG
        R3 violation — an unguarded Stimulus class read will throw at runtime for any
        consumer who did not pass that class:

        #{violations.map { |v| "  #{v}" }.join("\n")}
      MSG
    end

    # R7 — Turbo's snapshot cache turns every missed teardown into a per-visit leak.
    def test_controllers_with_side_effects_tear_them_down
      side_effecting = controllers.select do |path|
        code_of(path).match?(/addEventListener|new (?:Intersection|Mutation|Resize)Observer|setTimeout|setInterval/)
      end

      violations = side_effecting.reject { |path| code_of(path).match?(/^\s*disconnect\s*\(/) }
                                 .map { |path| File.basename(path) }

      assert_empty violations, <<~MSG
        R7 violation — these register listeners, observers or timers but define no
        disconnect(), so each Turbo visit leaks:

        #{violations.map { |v| "  #{v}" }.join("\n")}
      MSG
    end

    # R10 — the contract marker is what makes ejection and view-path shadowing safe.
    # ShadowCheck reads it at boot; a partial without one silently defeats that.
    def test_every_shipped_partial_carries_a_current_contract_marker
      partials = Dir[File.join(VIEW_DIR, "_*.html.erb")].sort
      refute_empty partials, "expected at least one shipped partial"

      violations = partials.filter_map do |path|
        marker = File.read(path)[/crosswire:contract\s+v(\d+)/, 1]
        name = File.basename(path)

        if marker.nil?
          "#{name}: no `<%# crosswire:contract vN %>` marker"
        elsif marker.to_i != Crosswire::CONTRACT_VERSION
          "#{name}: declares v#{marker}, gem ships v#{Crosswire::CONTRACT_VERSION}"
        end
      end

      assert_empty violations, <<~MSG
        R10 violation — ShadowCheck cannot verify an ejected copy of these:

        #{violations.map { |v| "  #{v}" }.join("\n")}
      MSG
    end

    # R10, inverted. The contract marker is an ERB comment that ShadowCheck reads out
    # of *partials*. Anywhere else it is meaningless — and in a Markdown file it is
    # worse than meaningless, because it renders as literal text at the top of the page.
    # An agent applied it to all seven recipe pages by over-generalising R10.
    def test_contract_markers_appear_only_in_partials
      # Only a BARE marker on its own line is the bug. Prose that documents the marker —
      # as README and this contract both legitimately do — mentions it inline, and must
      # not trip the check. Getting this wrong in the first draft is itself the lesson:
      # a lint that flags correct usage gets disabled, and then catches nothing.
      docs = Dir[File.join(ROOT, "docs/**/*.md")] + Dir[File.join(ROOT, "*.md")]
      violations = docs.select { |path| File.read(path).match?(/^\s*<%#\s*crosswire:contract\s+v\d+\s*%>\s*$/) }
                       .map { |path| path.delete_prefix("#{ROOT}/") }

      assert_empty violations, <<~MSG
        The `<%# crosswire:contract vN %>` marker belongs only in shipped ERB partials,
        where ShadowCheck reads it. In Markdown it renders as literal text:

        #{violations.map { |v| "  #{v}" }.join("\n")}
      MSG
    end

    # Naming — the component name appears exactly once per artifact, in the same
    # position, so everything is derivable. Drift here breaks the generator, which
    # discovers components from the filesystem.
    def test_every_controller_has_a_matching_presenter
      violations = controllers.filter_map do |path|
        name = File.basename(path).sub(/_controller\.js\z/, "")
        expected = File.join(PRESENTER_DIR, "#{name}.rb")
        "#{File.basename(path)} has no #{name}.rb presenter" unless File.exist?(expected)
      end

      assert_empty violations, "naming violation:\n#{violations.map { |v| "  #{v}" }.join("\n")}"
    end

    def test_every_presenter_has_a_matching_controller
      violations = Dir[File.join(PRESENTER_DIR, "*.rb")].sort.filter_map do |path|
        name = File.basename(path, ".rb")
        expected = File.join(CONTROLLER_DIR, "#{name}_controller.js")
        "#{name}.rb has no #{name}_controller.js" unless File.exist?(expected)
      end

      assert_empty violations, "naming violation:\n#{violations.map { |v| "  #{v}" }.join("\n")}"
    end

    # The identifier is derived from the presenter class name so Ruby and JS cannot
    # drift. Assert the derivation actually holds for every registered component.
    def test_identifiers_derive_from_presenter_class_names
      Crosswire::COMPONENTS.each do |name, presenter|
        expected = "cw--#{name.to_s.tr("_", "-")}"
        assert_equal expected, presenter.identifier,
                     "#{presenter} should derive identifier #{expected}"
      end
    end

    # Every controller file must be registered, or it ships dead: `pin_all_from` makes
    # it importable but nothing registers it, so `data-controller="cw--x"` silently does
    # nothing. This is exactly the drift that manual wiring invites.
    def test_every_controller_is_registered_in_the_index
      index = File.read(File.join(ROOT, "app/assets/javascripts/crosswire/index.js"))

      violations = controllers.filter_map do |path|
        name = File.basename(path).sub(/_controller\.js\z/, "")
        identifier = "cw--#{name.tr("_", "-")}"
        "#{identifier} (#{File.basename(path)})" unless index.include?(%("#{identifier}"))
      end

      assert_empty violations, <<~MSG
        These controllers exist but are not registered in index.js, so they ship dead —
        importable, but `data-controller` will silently do nothing:

        #{violations.map { |v| "  #{v}" }.join("\n")}
      MSG
    end

    def test_every_controller_is_registered_in_the_components_registry
      registered = Crosswire::COMPONENTS.keys.map(&:to_s).sort
      on_disk = controllers.map { |p| File.basename(p).sub(/_controller\.js\z/, "") }.sort

      assert_equal on_disk, registered, <<~MSG
        Crosswire::COMPONENTS has drifted from the controllers on disk. The generator and
        docs read this registry, so anything missing here is invisible to both.
      MSG
    end
  end
end
