# frozen_string_literal: true

require "test_helper"
require "crosswire/ui"
require "crosswire/ui/bundle"
require "crosswire/vocabulary"

module Crosswire
  module UI
    # Machine-checks the UI-tier rules from the UI-tier spec (§7.5) that CAN be
    # checked statically — the styled-component-tier sibling of
    # `test/crosswire/contract_audit_test.rb`, whose style and structure this clones
    # directly (local `camelize`, plain-Ruby no-Rails, filter_map + assert_empty).
    #
    # `Crosswire::UI::COMPONENTS` is empty through Phase 0 (gate: "audits green, no
    # components" — spec §10), so most checks below are VACUOUSLY true today: they
    # iterate `Crosswire::UI.component_names`, which iterates zero times. That is
    # deliberate, not a placeholder — every check is real, exercised logic that starts
    # actually checking something the moment Phase 1 registers `button`, rather than a
    # promise written down for later. A few checks (7, 8, 9) have something to check
    # today regardless, because tokens.css/base.css/themes/patchbay.css/ui.css already
    # exist.
    class UIContractAuditTest < Minitest::Test
      ROOT = File.expand_path("../..", __dir__)
      UI_LIB_DIR = File.join(ROOT, "lib/crosswire/ui")
      UI_VIEW_DIR = File.join(ROOT, "app/views/crosswire/ui")
      UI_CSS_DIR = File.join(ROOT, "app/assets/stylesheets/crosswire/ui")
      SITE_EXAMPLES_DIR = File.join(ROOT, "site/examples")
      TOKENS_CSS = File.join(UI_CSS_DIR, "tokens.css")
      PATCHBAY_CSS = File.join(UI_CSS_DIR, "themes", "patchbay.css")

      RESERVED_TOKEN_CATEGORIES = %w[color space radius text weight leading font shadow
                                     border duration ease z].freeze
      MORPH_VERDICTS = %w[Safe Preserved Server-owned Excluded].freeze

      def camelize(name)
        name.to_s.split("_").map { |part| part[0].upcase + part[1..] }.join
      end

      # --- 1: UI partials carry the current UI-tier contract marker -----------------
      #
      # The UI tier's own marker check, scoped to app/views/crosswire/ui/ only —
      # independent of (but consistent with) contract_audit_test.rb's widened, tier-
      # aware version of the same check over the WHOLE app/views/crosswire tree.
      def test_every_ui_partial_carries_the_current_ui_contract_marker
        partials = Dir[File.join(UI_VIEW_DIR, "**", "_*.html.erb")].sort

        violations = partials.filter_map do |path|
          marker = File.read(path)[/crosswire:contract\s+v(\d+)/, 1]
          name = File.basename(path)

          if marker.nil?
            "#{name}: no `<%# crosswire:contract vN %>` marker"
          elsif marker.to_i != Crosswire::UI::CONTRACT_VERSION
            "#{name}: declares v#{marker}, UI tier ships v#{Crosswire::UI::CONTRACT_VERSION}"
          end
        end

        assert_empty violations, "UI partial contract marker violation:\n#{violations.map { |v| "  #{v}" }.join("\n")}"
      end

      # --- 2: every registered component ships its full file set --------------------
      #
      # Two shapes now (spec §2's two anatomy rules), branched by `kind_of`:
      #
      #   kind: :new (a, the default) — this tier's OWN presenter, helper, partial and
      #     CSS, plus a gallery example. Every check below is unchanged from before
      #     `kind:` existed.
      #   kind: :css (b) — CSS only, over an EXISTING, identically-named primitive.
      #     There is no `lib/crosswire/ui/<name>.rb`/`_helper.rb` to demand — those
      #     files were never going to exist by design (see `Crosswire::UI.css_only?`'s
      #     docstring) — so this branch checks the files that DO have to exist
      #     instead: the primitive's own presenter and partial (proof the name really
      #     does name a real, shipped widget, not a typo or a stale registry entry),
      #     this tier's CSS, and a gallery example.
      def test_every_registered_component_ships_its_full_file_set
        violations = Crosswire::UI.component_names.flat_map do |name|
          missing = if Crosswire::UI.css_only?(name)
                      css_only_missing_files(name)
                    else
                      new_markup_missing_files(name)
                    end
          missing << "site/examples/#{name}/*.html.erb (at least one gallery example)" if Dir[File.join(SITE_EXAMPLES_DIR, name, "*.html.erb")].empty?

          missing.map { |m| "#{name}: missing #{m}" }
        end

        assert_empty violations, "incomplete UI component file set:\n#{violations.map { |v| "  #{v}" }.join("\n")}"
      end

      # --- 3: every UI helper is included into Crosswire::Builder --------------------
      #
      # `kind: :css` names have no `Crosswire::UI::<Name>Helper` at all — the same
      # camelized name instead resolves to the PRIMITIVE tier's `Crosswire::<Name>Helper`
      # (app/helpers/crosswire/<name>_helper.rb), which `Crosswire::Builder`'s OTHER
      # include loop (`Crosswire.component_names`, lib/crosswire/builder.rb) already
      # wires in and `test/crosswire/contract_audit_test.rb` already checks — asserting
      # it again here would just be a second, redundant copy of that check under a
      # different name. Skipped, not silently vacuous: the primitive-tier suite is
      # exactly where this belongs.
      def test_every_ui_helper_is_included_into_the_builder
        load_builder_with_every_helper!

        missing = Crosswire::UI.component_names.reject { |name| Crosswire::UI.css_only?(name) }.filter_map do |name|
          mod = Object.const_get("Crosswire::UI::#{camelize(name)}Helper")
          "Crosswire::Builder does not include #{mod}" unless Crosswire::Builder.ancestors.include?(mod)
        end

        assert_empty missing, "UI helper not wired into the builder:\n#{missing.map { |v| "  #{v}" }.join("\n")}"
      end

      # --- 4: the helper triple (<name>, <name>_for, <name>_attrs) is present -------
      #
      # Same `kind: :css` exemption as check 3 — the triple these four names actually
      # expose (`cw.dialog`/`cw.dialog_for`/`cw.dialog_attrs`, etc.) is the PRIMITIVE
      # tier's, already pinned by `test/crosswire/contract_audit_test.rb`.
      def test_every_ui_component_defines_the_helper_triple
        violations = Crosswire::UI.component_names.reject { |name| Crosswire::UI.css_only?(name) }.flat_map do |name|
          path = File.join(UI_LIB_DIR, "#{name}_helper.rb")
          next ["#{name}: #{name}_helper.rb does not exist"] unless File.exist?(path)

          load path
          mod = Object.const_get("Crosswire::UI::#{camelize(name)}Helper")
          defined = mod.instance_methods(false).map(&:to_s)

          %W[#{name} #{name}_for #{name}_attrs].filter_map { |m| "#{mod}##{m} is missing" unless defined.include?(m) }
        end

        assert_empty violations, "helper triple violation:\n#{violations.map { |v| "  #{v}" }.join("\n")}"
      end

      # --- 5: no name collisions ------------------------------------------------------
      #
      # `kind: :new` names must be genuinely new — the checks below are exactly as
      # they were before `kind:` existed. `kind: :css` names are the deliberate
      # OPPOSITE: they exist ONLY to style an already-shipped, identically-named
      # primitive (spec §2b), so a "collides with primitive" flag on one of them would
      # be flagging the entire point of the entry. The real bug this shape could still
      # hide — a `kind: :css` entry whose name does NOT actually correspond to any
      # shipped primitive (a typo, a stale rename) — gets its own, inverted assertion
      # instead of being silently unchecked.
      def test_ui_component_names_do_not_collide
        primitive_names = Crosswire.component_names
        vocabulary_names = Crosswire::VOCABULARY.values.flatten.map { |n| n.tr("-", "_") }

        new_markup_violations = Crosswire::UI.component_names.reject { |name| Crosswire::UI.css_only?(name) }.flat_map do |name|
          reasons = []
          reasons << "collides with primitive Crosswire::COMPONENTS[:#{name}]" if primitive_names.include?(name)
          reasons << "collides with a Crosswire::VOCABULARY entry" if vocabulary_names.include?(name)
          reasons << "collides with a reserved token category" if RESERVED_TOKEN_CATEGORIES.include?(name)
          reasons.map { |r| "#{name}: #{r}" }
        end

        css_only_violations = Crosswire::UI.component_names.select { |name| Crosswire::UI.css_only?(name) }.filter_map do |name|
          "#{name}: kind: :css but no primitive Crosswire::COMPONENTS[:#{name}] exists to style" unless primitive_names.include?(name)
        end

        violations = new_markup_violations + css_only_violations
        assert_empty violations, "UI component name collision:\n#{violations.map { |v| "  #{v}" }.join("\n")}"
      end

      # --- 6: no Tailwind utility lookalikes in shipped CSS ---------------------------
      #
      # Crude on purpose (spec §7.5: "skip if ambiguous" beats a flaky lint) — a class
      # selector shaped like a common Tailwind utility. crosswire ships semantic BEM-ish
      # classes (.cw-button--primary), never utilities, so this should never fire on
      # our own CSS; it exists to catch someone reaching for a Tailwind class out of
      # habit while writing a new component's CSS.
      TAILWIND_LOOKALIKE = /(\.(?:flex|grid|hidden|block|inline(?:-\w+)?|
                              (?:p|m|px|py|pt|pb|pl|pr|mx|my|mt|mb|ml|mr)-\d+|
                              w-\d+|h-\d+|text-(?:xs|sm|base|lg|xl|\d+)|
                              bg-\w+-\d{2,3}|rounded(?:-\w+)?|shadow-(?:sm|md|lg|xl|\d+)|
                              border-\d+)\b)/x

      def test_shipped_css_defines_no_tailwind_utility_lookalikes
        violations = ui_css_files.flat_map do |path|
          File.read(path).scan(TAILWIND_LOOKALIKE).flatten.uniq
              .map { |m| "#{relative(path)}: `#{m}` looks like a Tailwind utility class" }
        end

        assert_empty violations, "possible Tailwind utility in shipped CSS:\n#{violations.map { |v| "  #{v}" }.join("\n")}"
      end

      # --- 7: token discipline ---------------------------------------------------------
      #
      # Two independent rules, both bite TODAY against tokens.css/themes/patchbay.css
      # (rule a) and base.css (rule b), even with zero components registered:
      #
      #   a) every custom property a UI CSS file DECLARES matches either the global
      #      shape `--cw-<reserved-category>-*` (tokens.css, themes/*.css — the token
      #      DEFINITIONS) or, for a per-component file, `--cw-<component>-*` (a knob).
      #   b) every color/length a UI CSS file CONSUMES in a regular (non custom-
      #      property) declaration is `var(--cw-*)` or on the small structural
      #      allowlist — tokens.css and themes/*.css are exempt from rule (b): they ARE
      #      the definition source, so their raw values are correct by construction.
      VALUE_ALLOWLIST = %w[0 1px -1px 100% 9999px transparent currentColor].freeze
      RAW_VALUE_SOURCE_FILES = [TOKENS_CSS, PATCHBAY_CSS].freeze

      def test_token_discipline
        violations = ui_css_files.flat_map do |path|
          content = strip_css_comments(File.read(path))
          component = component_css_name(path)

          name_violations = declared_custom_properties(content).reject { |prop| valid_custom_prop_name?(prop, component) }
                                                                .map { |prop| "#{relative(path)}: #{prop} matches neither --cw-<category>-* nor --cw-<component>-*" }

          value_violations = if RAW_VALUE_SOURCE_FILES.include?(path)
                                []
                              else
                                regular_declarations(content).flat_map do |prop, value|
                                  raw = disallowed_raw_tokens(value)
                                  next [] if raw.empty?

                                  ["#{relative(path)}: `#{prop}: #{value.strip};` — #{raw.join(", ")} must be var(--cw-*) or allowlisted"]
                                end
                              end

          name_violations + value_violations
        end

        assert_empty violations, "token discipline violation:\n#{violations.map { |v| "  #{v}" }.join("\n")}"
      end

      # --- 8: the two dark blocks are byte-identical -----------------------------------
      def test_dark_blocks_are_byte_identical
        [TOKENS_CSS, PATCHBAY_CSS].each do |path|
          css = File.read(path)
          media_block = css[/@media \(prefers-color-scheme: dark\).*?:root:not\([^)]*\):not\([^)]*\)\s*\{(.*?)\n\s*\}/m, 1]
          static_block = css[/:root\[data-cw-theme="dark"\].*?\{(.*?)\n\s*\}/m, 1]

          refute_nil media_block, "#{relative(path)}: no @media dark block found"
          refute_nil static_block, "#{relative(path)}: no static [data-cw-theme=dark] block found"

          # Normalized to per-line content (stripped, blanks dropped) rather than raw
          # bytes: the two blocks necessarily sit at different indentation depths (one
          # is nested inside `@media`, the other is not), so literal byte-identity of
          # the FILE TEXT is neither achievable nor the point — what must never drift
          # is which custom properties are declared and what they're set to.
          normalized = ->(block) { block.lines.map(&:strip).reject(&:empty?) }

          assert_equal normalized.call(media_block), normalized.call(static_block),
                       "#{relative(path)}: the @media dark block and the static " \
                       "[data-cw-theme=dark] block have drifted from each other"
        end
      end

      # --- 9: ui.css is exactly the bundle's generated source --------------------------
      def test_ui_css_bundle_matches_its_generated_source_byte_for_byte
        assert_equal Crosswire::UI::Bundle.source, File.read(Crosswire::UI::Bundle.bundle_path),
                     "app/assets/stylesheets/crosswire/ui.css is stale — run `rake ui:bundle`"
      end

      # --- 10: every UI presenter docstring carries a Morph: clause --------------------
      #
      # `kind: :css` names carry no `lib/crosswire/ui/<name>.rb` — their Morph: clause
      # lives on the PRIMITIVE presenter they style instead (see
      # lib/crosswire/presenters/dialog.rb/popover.rb/menu.rb/combobox.rb), and `rake
      # morph:doc` reads from that same file for them.
      def test_every_ui_presenter_docstring_carries_a_morph_clause
        violations = Crosswire::UI.component_names.filter_map do |name|
          path = if Crosswire::UI.css_only?(name)
                   File.join(ROOT, "lib/crosswire/presenters/#{name}.rb")
                 else
                   File.join(UI_LIB_DIR, "#{name}.rb")
                 end
          next "#{name}: #{relative(path)} does not exist" unless File.exist?(path)

          verdict = File.read(path)[/^\s*#\s*Morph:\s*(\S+)/, 1]

          if verdict.nil?
            "#{name}: no `# Morph:` docstring clause"
          elsif !MORPH_VERDICTS.include?(verdict)
            "#{name}: `# Morph: #{verdict}` is not one of #{MORPH_VERDICTS.join("/")}"
          end
        end

        assert_empty violations, "Morph contract violation:\n#{violations.map { |v| "  #{v}" }.join("\n")}"
      end

      private

      # kind: :new (check 2, the default branch) — unchanged from before `kind:`
      # existed: this tier's own presenter, helper and partial.
      def new_markup_missing_files(name)
        missing = []
        missing << "lib/crosswire/ui/#{name}.rb (presenter)" unless File.exist?(File.join(UI_LIB_DIR, "#{name}.rb"))
        missing << "lib/crosswire/ui/#{name}_helper.rb" unless File.exist?(File.join(UI_LIB_DIR, "#{name}_helper.rb"))
        missing << "app/views/crosswire/ui/_#{name}.html.erb" unless File.exist?(File.join(UI_VIEW_DIR, "_#{name}.html.erb"))
        missing << "app/assets/stylesheets/crosswire/ui/#{name}.css" unless File.exist?(File.join(UI_CSS_DIR, "#{name}.css"))
        missing
      end

      # kind: :css (check 2) — no new presenter/helper/partial of its own; instead
      # checks the PRIMITIVE tier's already-shipped presenter and partial actually
      # exist (proof this name really does style a real, shipped widget) plus this
      # tier's own CSS.
      def css_only_missing_files(name)
        missing = []
        missing << "lib/crosswire/presenters/#{name}.rb (the primitive presenter this styles)" unless File.exist?(File.join(ROOT, "lib/crosswire/presenters/#{name}.rb"))
        missing << "app/views/crosswire/_#{name}.html.erb (the primitive partial this styles)" unless File.exist?(File.join(ROOT, "app/views/crosswire/_#{name}.html.erb"))
        missing << "app/assets/stylesheets/crosswire/ui/#{name}.css" unless File.exist?(File.join(UI_CSS_DIR, "#{name}.css"))
        missing
      end

      def relative(path) = path.delete_prefix("#{ROOT}/")

      def ui_css_files
        Dir[File.join(UI_CSS_DIR, "**", "*.css")].sort
      end

      # A per-component knob file is `app/assets/stylesheets/crosswire/ui/<name>.css`
      # directly inside UI_CSS_DIR (not themes/) whose basename is a registered
      # component — nil for tokens.css, base.css and every themes/*.css file.
      def component_css_name(path)
        return nil unless File.dirname(path) == UI_CSS_DIR

        name = File.basename(path, ".css")
        name if Crosswire::UI.component_names.include?(name)
      end

      def declared_custom_properties(content)
        content.scan(/(--cw-[\w-]+)\s*:/).flatten.uniq
      end

      def valid_custom_prop_name?(prop, component)
        categories = RESERVED_TOKEN_CATEGORIES.join("|")
        return true if prop.match?(/\A--cw-(?:#{categories})(?:-[\w-]+)?\z/)
        return true if component && prop.match?(/\A--cw-#{Regexp.escape(component)}(?:-[\w-]+)?\z/)

        false
      end

      # Every regular (non custom-property) declaration in the file, as [prop, value].
      def regular_declarations(content)
        content.scan(/([a-zA-Z-]+)\s*:\s*([^;]+);/).reject { |prop, _| prop.start_with?("--") }
      end

      # Strip CSS comments before any of the checks above ever scan the content — a
      # docstring paragraph explaining `--cw-button-*` knobs, or mentioning "100%" in
      # prose, is not a declaration, and must not be treated like one. `/\*.*?\*/`
      # matched non-greedily across the whole file (`m` flag lets `.` cross
      # newlines) is sufficient for CSS's actual comment syntax (no nesting, no
      # escaping) — this codebase's stylesheets carry no `/*`/`*/` sequence inside a
      # string or url() that would make a smarter tokenizer worth the complexity.
      def strip_css_comments(content) = content.gsub(%r{/\*.*?\*/}m, "")

      # Strip legitimate `var(--cw-*)` references first, then look for whatever's
      # left that smells like a hardcoded color or length. Deliberately loose — false
      # negatives (missing a real violation) are the acceptable failure mode for a
      # lint this size, not false positives that make people distrust it.
      #
      # The trailing boundary is a lookahead, `(?![\w%])`, NOT `\b` — a real bug this
      # test itself shipped with once, recorded here so it cannot silently come back.
      # `\b` treats `%` as a non-word character exactly like whitespace or `;`, so for
      # an allowlisted value like `100%` the engine matches the OPTIONAL `%` suffix
      # greedily first, finds no `\b` between `%` and the following `;` (neither side
      # is a word character, so there is no word/non-word transition to assert), and
      # backtracks to a match of bare `100` instead — which passes its OWN trailing
      # `\b` (between the word character `0` and the non-word `%`) and is then
      # checked against `VALUE_ALLOWLIST` as `"100"`, not `"100%"`, and reported as a
      # violation. `(?![\w%])` treats `%` as part of "the token", not as a boundary,
      # so the greedy match of `100%` is what actually gets checked — and it is
      # exactly what `VALUE_ALLOWLIST` allowlists.
      RAW_TOKEN = /#[0-9a-fA-F]{3,8}(?![\w])|\b(?:rgb|rgba|hsl|hsla)\([^)]*\)|-?\d+(?:\.\d+)?(?:px|rem|em|%|ms|s|vh|vw|deg)?(?![\w%])/

      def disallowed_raw_tokens(value)
        scrubbed = value.gsub(/var\([^)]*\)/, "")
        scrubbed.scan(RAW_TOKEN).reject { |token| VALUE_ALLOWLIST.include?(token) }
      end

      # Loads every primitive-tier AND UI-tier helper module by hand, then (re)loads
      # Crosswire::Builder — the exact sequence
      # contract_audit_test.rb#test_every_component_helper_is_included_into_the_builder
      # uses, replicated here (rather than relied upon by load order) so this test
      # passes regardless of which order Minitest happens to run the two files' tests
      # in within the same process.
      def load_builder_with_every_helper!
        Dir[File.join(ROOT, "app/helpers/crosswire/*_helper.rb")].each do |path|
          load path unless File.basename(path) == "facade_helper.rb"
        end
        Crosswire::UI.component_names.each do |name|
          path = File.join(UI_LIB_DIR, "#{name}_helper.rb")
          load path if File.exist?(path)
        end
        load File.join(ROOT, "lib/crosswire/builder.rb")
      end
    end
  end
end
