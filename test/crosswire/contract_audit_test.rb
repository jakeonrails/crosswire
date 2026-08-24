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
    HELPER_DIR = File.join(ROOT, "app/helpers/crosswire")

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

    # The contract says a helper is required for EVERY component — the helper layer is
    # the whole thesis, since a controller only stays generic if its ids, classes and
    # bindings are injected from outside.
    #
    # `dismiss` shipped for a week without one, despite being a reference implementation
    # and despite `TransitionHelper`'s own docstring calling `crosswire_dismiss_attrs`.
    # Nothing caught it until an app actually rendered. Symmetry checks are cheap; the
    # bugs they catch are not.
    def test_every_controller_has_a_matching_helper
      helper_dir = File.join(ROOT, "app/helpers/crosswire")

      violations = controllers.filter_map do |path|
        name = File.basename(path).sub(/_controller\.js\z/, "")
        expected = File.join(helper_dir, "#{name}_helper.rb")
        "#{name}_controller.js has no #{name}_helper.rb" unless File.exist?(expected)
      end

      assert_empty violations, <<~MSG
        Every component ships a helper (see "Files per component" in the contract):

        #{violations.map { |v| "  #{v}" }.join("\n")}
      MSG
    end

    # Required constructor keywords that name a declared Stimulus value must actually be
    # EMITTED by `root_attrs`. R4 says state lives in a value and the server renders it —
    # a presenter that accepts `selected:` and then never writes
    # `data-cw--tabs-selected-value` has broken that contract even though every unit test
    # still passes, because the controller reads the type default (`""`) on connect.
    #
    # `tabs` shipped exactly that bug: server-rendered markup was correct, then Stimulus
    # booted and hid every panel. Only visible by loading a real page. This check makes
    # that class of bug fail the build instead.
    #
    # Scoped narrowly on purpose: only REQUIRED keywords, and only where the name also
    # appears as a declared value. Optional keywords (`param:`) may legitimately be
    # absent, and plenty of required ones (`id:`) are not values at all.
    REQUIRED_ARG_FIXTURES = {
      "disclosure" => { id: "probe" },
      "dialog" => { id: "probe" },
      "popover" => { id: "probe" },
      "tabs" => { id: "probe", selected: "one" },
      "menu" => { id: "probe" },
      "combobox" => { id: "probe", name: "probe" },
      "persist" => { key: "probe" },
      "hotkey" => { key: "probe" },
      "timeout" => { delay: 1000 },
      "interval" => { ms: 1000 },
      "sync" => { target: "#probe" },
      "char_count" => { max: 140 },
      "sortable" => { url: "/probe" },
      "relative_time" => { datetime: "2026-08-16T00:00:00Z" },
      "countdown" => { deadline: "2026-08-16T00:00:00Z" },
      # `preserve` has no REQUIRED keyword (both `attributes:` and `element:` have
      # defaults) — `required` below is legitimately empty for it, so this entry exists
      # only because `presenter.new(...)` on line ~201 is unconditional for every
      # registered component regardless of `required`, and the zero-arg default
      # combination (`attributes: nil, element: false`) deliberately raises
      # ArgumentError ("nothing to preserve") rather than silently constructing an
      # inert preserve.
      "preserve" => { attributes: "aria-expanded" }
    }.freeze

    def test_required_state_keywords_are_rendered_as_values
      violations = Crosswire::COMPONENTS.flat_map do |name, presenter|
        controller = File.join(CONTROLLER_DIR, "#{name}_controller.js")
        next [] unless File.exist?(controller)

        declared = code_of(controller)[/static\s+values\s*=\s*\{(.*?)\}\s*$/m, 1].to_s
                                      .scan(/^\s*(\w+)\s*:/).flatten

        required = presenter.instance_method(:initialize).parameters
                            .select { |kind, _| kind == :keyreq }.map { |_, arg| arg.to_s }

        instance = presenter.new(**REQUIRED_ARG_FIXTURES.fetch(name.to_s, {}))

        # Not every component calls its root `root_attrs`: `confirm`'s root IS the
        # <dialog> it stacks onto (`dialog_attrs`), and `popover`'s trigger and panel
        # share no common ancestor by design (`panel_attrs`). So gather every zero-arg
        # `*_attrs` method rather than assuming a name — the value only has to be
        # rendered *somewhere* on the controller element.
        attrs = instance.public_methods(false)
                        .grep(/_attrs\z/)
                        .select { |m| instance.method(m).arity <= 0 }
                        .reduce({}) { |acc, m| acc.merge(instance.public_send(m)) }

        (required & declared).filter_map do |arg|
          key = "data-#{presenter.identifier}-#{arg.tr("_", "-")}-value"
          "#{name}: requires #{arg}: and declares it as a Stimulus value, but no *_attrs method emits #{key}" unless attrs.key?(key)
        end
      end

      assert_empty violations, <<~MSG
        R4 violation — required state is accepted but never rendered, so the controller
        reads its type default on connect and clobbers correct server-rendered markup:

        #{violations.map { |v| "  #{v}" }.join("\n")}
      MSG
    end

    # Widgets are the components that own markup — derived from which components ship
    # a partial, never a hardcoded list, because components are still being added.
    def widget_names
      Dir[File.join(VIEW_DIR, "_*.html.erb")]
          .map { |path| File.basename(path).sub(/\A_/, "").sub(/\.html\.erb\z/, "") }
          .sort
    end

    def camelize(name)
      name.to_s.split("_").map { |part| part[0].upcase + part[1..] }.join
    end

    # The standard (docs/COMPONENT_CONTRACT.md "Files per component" / Naming table):
    # every component's helper module defines `<name>_for` and `<name>_attrs`; widgets
    # (components that own markup — i.e. ship a partial) additionally define the bare
    # `<name>` batteries-included render form. Since D8 (docs/DECISIONS.md), these are
    # the method names as they exist on the MODULE — reached by a consumer as
    # `cw.<name>_for` etc. once the module is included into `Crosswire::Builder` (see
    # `test_every_component_helper_is_included_into_the_builder` below), never with a
    # `crosswire_` prefix on the method itself. This is what a consumer relies on to
    # predict the API without reading the source — landed after four agents built the
    # helper layer in parallel and drifted into three different naming schemes across
    # components.
    def test_every_helper_follows_the_standard_naming
      widgets = widget_names

      violations = controllers.flat_map do |controller_path|
        name = File.basename(controller_path).sub(/_controller\.js\z/, "")
        helper_path = File.join(HELPER_DIR, "#{name}_helper.rb")

        next ["#{name}_helper.rb does not exist"] unless File.exist?(helper_path)

        load helper_path
        mod_name = "Crosswire::#{camelize(name)}Helper"
        mod = Object.const_get(mod_name)
        defined_methods = mod.instance_methods(false).map(&:to_s)

        expected = ["#{name}_for", "#{name}_attrs"]
        expected << name if widgets.include?(name)

        expected.filter_map { |m| "#{mod_name}##{m} is missing" unless defined_methods.include?(m) }
      end

      assert_empty violations, <<~MSG
        Helper API standard violation (docs/COMPONENT_CONTRACT.md "Files per
        component" / Naming): every component's helper module defines <name>_for and
        <name>_attrs; widgets additionally define the bare <name> batteries-included
        form — reached by a consumer as cw.<name>_for, cw.<name>_attrs, cw.<name>:

        #{violations.map { |v| "  #{v}" }.join("\n")}
      MSG
    end

    # D8 (docs/DECISIONS.md) moved every per-component helper module OFF views and INTO
    # `Crosswire::Builder` — a consumer no longer `helper Crosswire::DisclosureHelper`s
    # anything; they call `cw.disclosure_for`, reached through the `crosswire`/`cw`
    # facade. This is the naming check above's necessary companion: defining the right
    # method NAMES on a module nobody ever `include`s would be silently inert.
    #
    # `Crosswire::Builder` itself is deliberately dependency-free enough to load here
    # (see its own docstring on why it avoids `ActiveSupport#camelize`) — every helper
    # module is `load`ed by hand first, exactly as the naming check above does, so the
    # constants `Crosswire::Builder`'s own `include` loop looks up already exist.
    def test_every_component_helper_is_included_into_the_builder
      # `facade_helper.rb` itself `require`s `lib/crosswire/builder.rb` at its top (see
      # that file's docstring for why) — loading it here, before every OTHER helper
      # module is loaded, would trigger Builder's own `include` loop too early and blow
      # up with a NameError on whichever module sorts after "facade" alphabetically.
      # It plays no part in this check anyway (it defines `cw`/`crosswire`, not a
      # per-component helper), so skip it and load the builder file ourselves, after.
      Dir[File.join(HELPER_DIR, "*_helper.rb")].each do |path|
        load path unless File.basename(path) == "facade_helper.rb"
      end
      load File.join(ROOT, "lib/crosswire/builder.rb")

      missing = Crosswire.component_names.filter_map do |name|
        mod = Object.const_get("Crosswire::#{camelize(name)}Helper")
        "Crosswire::Builder does not include #{mod}" unless Crosswire::Builder.ancestors.include?(mod)
      end

      unless Crosswire::Builder.ancestors.include?(Crosswire::StreamsHelper)
        missing << "Crosswire::Builder does not include Crosswire::StreamsHelper"
      end

      assert_empty missing, <<~MSG
        Every per-component helper module (and Crosswire::StreamsHelper) must be
        `include`d into Crosswire::Builder (lib/crosswire/builder.rb) — that is what
        makes its methods reachable as cw.<name>/cw.<name>_for/cw.<name>_attrs:

        #{missing.map { |v| "  #{v}" }.join("\n")}
      MSG
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
