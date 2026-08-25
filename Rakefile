# frozen_string_literal: true

require "rake/testtask"
require "shellwords"

# Minitest auto-discovers plugins from every loaded gem. Because the Gemfile pins `rails`
# for the generator suite, that discovery finds railties' `minitest/rails_plugin.rb`, which
# **defines `Rails` before any test body runs** — breaking the `refute defined?(::Rails)`
# assertion that guarantees presenters stay usable without Rails (D5).
#
# The leak is environmental, not ours: it reproduces with zero crosswire files loaded.
# `MT_NO_PLUGINS` disables that discovery, so `rake test` behaves identically to the plain
# `ruby -Ilib -Itest ...` invocation. Without it, `bundle exec rake test` fails and the
# generator suite gets blamed for something railties did.
ENV["MT_NO_PLUGINS"] = "1"

Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.pattern = "test/**/*_test.rb"
  t.warning = false
end

desc "Run the JS controller tests"
task :js do
  sh "npm test"
end

DUMMY = File.expand_path("test/dummy", __dir__)

desc "Start the dummy host app + Lookbook on PORT (default 3000). Lookbook: /lookbook"
task :lookbook do
  port = ENV.fetch("PORT", "3000")
  puts "  demo     http://localhost:#{port}/"
  puts "  Lookbook http://localhost:#{port}/lookbook"
  sh "cd #{DUMMY.shellescape} && bin/rails server -p #{port}"
end

namespace :ui do
  desc "Regenerate app/assets/stylesheets/crosswire/ui.css (layer decl + tokens + " \
       "base + every registered component's CSS, in registry order)"
  task :bundle do
    require_relative "lib/crosswire/ui/bundle"

    File.write(Crosswire::UI::Bundle.bundle_path, Crosswire::UI::Bundle.source)
    puts "wrote #{Crosswire::UI::Bundle.bundle_path}"
  end

  desc "Regenerate site/registry.json from Crosswire::UI::COMPONENTS (shadcn-shaped " \
       "schema — see ui-tier-spec.md §4). Empty through Phase 0: valid empty JSON."
  task :registry do
    require "json"
    require_relative "lib/crosswire/ui"

    root = File.expand_path(__dir__)
    ui_css_dir = File.join(root, "app/assets/stylesheets/crosswire/ui")

    # Schema per component (spec §4): name/type/description/dependencies/
    # registryDependencies/files[{path,type}]/cssVars — everything but `description`
    # (a short hand-written line in `Crosswire::UI::COMPONENTS`, the one thing the
    # filesystem cannot derive) is read from real, on-disk state, the same "cannot
    # drift from what's actually shipped" reasoning `crosswire:eject`'s own component
    # discovery already uses (lib/generators/crosswire/eject/eject_generator.rb).
    entries = Crosswire::UI.component_names.map do |name|
      css_path = File.join(ui_css_dir, "#{name}.css")
      css_vars = File.read(css_path).scan(/(--cw-#{Regexp.escape(name)}(?:-[\w-]+)?)\s*:/).flatten.uniq.sort

      # `kind: :css` (spec §2b) ships no NEW presenter/helper/partial of its own — it
      # styles the identically-named PRIMITIVE tier's already-shipped files instead,
      # so the registry names those real, on-disk paths rather than fabricating
      # `lib/crosswire/ui/dialog.rb`, which does not exist. See
      # `Crosswire::UI.css_only?`'s own docstring for the full reasoning; this is the
      # same branch `ui_contract_audit_test.rb` check 2 and `rake morph:doc` take.
      files = if Crosswire::UI.css_only?(name)
                [
                  { "path" => "lib/crosswire/presenters/#{name}.rb", "type" => "presenter" },
                  { "path" => "app/views/crosswire/_#{name}.html.erb", "type" => "partial" },
                  { "path" => "app/assets/stylesheets/crosswire/ui/#{name}.css", "type" => "css" }
                ]
              else
                [
                  { "path" => "lib/crosswire/ui/#{name}.rb", "type" => "presenter" },
                  { "path" => "lib/crosswire/ui/#{name}_helper.rb", "type" => "helper" },
                  { "path" => "app/views/crosswire/ui/_#{name}.html.erb", "type" => "partial" },
                  { "path" => "app/assets/stylesheets/crosswire/ui/#{name}.css", "type" => "css" }
                ]
              end
      files += Dir[File.join(root, "site/examples/#{name}/*.html.erb")].sort.map do |example|
        { "path" => example.delete_prefix("#{root}/"), "type" => "example" }
      end

      {
        "name" => name,
        "type" => "registry:ui",
        "description" => Crosswire::UI::COMPONENTS.fetch(name.to_sym).fetch(:description),
        "dependencies" => [],
        "registryDependencies" => [],
        "files" => files,
        "cssVars" => css_vars
      }
    end

    path = File.expand_path("site/registry.json", __dir__)
    File.write(path, "#{JSON.pretty_generate(entries)}\n")
    puts "wrote #{path} (#{entries.size} component#{"s" unless entries.size == 1})"
  end

  desc "Rebuild site/components/<name>/index.html for every registered UI component " \
       "by rendering its site/examples/ through the real Rails view stack"
  task :gallery do
    sh "#{RbConfig.ruby.shellescape} bin/build_gallery.rb"
  end
end

namespace :morph do
  MORPH_CLAUSE = /^\s*# Morph:.*(?:\n\s*#.*)*/

  desc "Regenerate docs/MORPH.md from every UI presenter's `# Morph:` docstring " \
       "clause (spec §8). Empty scaffold through Phase 0 — no UI presenter exists yet."
  task :doc do
    require_relative "lib/crosswire/ui"

    rows = Crosswire::UI.component_names.filter_map do |name|
      # `kind: :css` (spec §2b) has no `lib/crosswire/ui/<name>.rb` at all — its Morph
      # clause lives on the PRIMITIVE presenter it styles instead (the same file
      # `ui_contract_audit_test.rb` check 10 reads for it).
      relative = Crosswire::UI.css_only?(name) ? "lib/crosswire/presenters/#{name}.rb" : "lib/crosswire/ui/#{name}.rb"
      path = File.expand_path(relative, __dir__)
      next unless File.exist?(path)

      clause = File.read(path)[MORPH_CLAUSE]
      next unless clause

      "## #{name}\n\n```\n#{clause.gsub(/^\s*#\s?/, "")}\n```\n"
    end

    body = if rows.empty?
      <<~MD
        # Morph contract

        Generated by `rake morph:doc` from every UI presenter's `# Morph:` docstring
        clause (see ui-tier-spec.md §8) — never hand-edited. No UI component has landed
        yet (Phase 0; gate: "audits green, no components"), so there is nothing to list.

        Format, once a component exists:

            # Morph: <Safe|Preserved|Server-owned|Excluded>
            #   DOM-only state: ...
            #   On morph:       ...
            #   The app must:   ...

        A browser test is required per non-Safe verdict.
      MD
    else
      rows.join("\n")
    end

    path = File.expand_path("docs/MORPH.md", __dir__)
    File.write(path, body)
    puts "wrote #{path} (#{rows.size} component#{"s" unless rows.size == 1})"
  end
end

desc "Rebuild site/index.html and every site/components/<name>/index.html from the " \
     "gem's real source, then smoke-test all of it in Chromium — " \
     "ui:bundle -> ui:registry -> build_site -> ui:gallery -> smoke (spec §9)"
task site: ["ui:bundle", "ui:registry", "morph:doc"] do
  sh "ruby bin/build_site.rb"
  Rake::Task["ui:gallery"].invoke
  sh "node bin/smoke_site.mjs"
end

desc "Run only the Rails integration suite (boots test/dummy), with full output"
task :integration do
  sh "#{RbConfig.ruby.shellescape} test/crosswire/integration_test_runner.rb"
end

desc "Run only the Action Cable streams suite (boots test/dummy), with full output"
task :streams do
  sh "#{RbConfig.ruby.shellescape} test/crosswire/streams_test_runner.rb"
end

task default: %i[test]
