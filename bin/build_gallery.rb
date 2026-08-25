#!/usr/bin/env ruby
# frozen_string_literal: true

# Assembles site/components/<name>/index.html for every registered UI-tier component
# (ui-tier-spec.md §9), by rendering site/examples/<name>/*.html.erb through the REAL
# Rails view stack — the same "boot test/dummy, then render for real" approach
# test/crosswire/integration_test_runner.rb uses (see that file's own header): demo ==
# snippet, not a second hand-rolled preview pipeline that could drift from what
# `cw.*` actually renders.
#
# Run: bin/build_gallery.rb  (or `rake site`, after ui:bundle/ui:registry/build_site.rb)

require "cgi"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
require_relative "lib/site_bundle"

ENV["RAILS_ENV"] ||= "test"
require File.expand_path("test/dummy/config/environment", ROOT)

require_relative "../lib/crosswire/ui"

TEMPLATE = File.join(ROOT, "site/component_template.html")
EXAMPLES_DIR = File.join(ROOT, "site/examples")
UI_CSS_DIR = File.join(ROOT, "app/assets/stylesheets/crosswire/ui")
UI_LIB_DIR = File.join(ROOT, "lib/crosswire/ui")
OUT_DIR = File.join(ROOT, "site/components")
ASSETS_DIR = File.join(ROOT, "site/assets")
SITE_CSS_PATH = File.join(ASSETS_DIR, "crosswire-ui.css")

abort "missing #{TEMPLATE}" unless File.exist?(TEMPLATE)

# The site must stay self-contained (nothing a built page links to may live outside
# site/), but the ONE source of truth for the bundle's content stays
# `Crosswire::UI::Bundle.source` (also written to `app/assets/stylesheets/crosswire/
# ui.css` by `rake ui:bundle`, and pinned there byte-for-byte by
# `ui_contract_audit_test.rb` check 9). This is a COPY of that same generated source,
# not a second place that algorithm lives — regenerated here via the identical code
# path `rake ui:bundle` uses, so it can never drift even if `ui:bundle` was skipped
# before this script ran.
require_relative "../lib/crosswire/ui/bundle"
FileUtils.mkdir_p(ASSETS_DIR)
File.write(SITE_CSS_PATH, Crosswire::UI::Bundle.source)

MORPH_CLAUSE = /^\s*# Morph:.*(?:\n\s*#.*)*/

# `kind: :css` names (spec §2b — dialog/popover/menu/combobox) have no
# `Crosswire::UI::<Name>` presenter at all; the class that actually renders them is
# the PRIMITIVE tier's `Crosswire::Presenters::<Name>`, already loaded (this script
# boots a full Rails app, so the gem's own eager presenter requires have already run).
def presenter_class_for(name)
  Crosswire::UI.css_only?(name) ? Crosswire::Presenters.const_get(name.camelize) : Crosswire::UI.const_get(name.camelize)
end

# Renders one example's raw ERB SOURCE through the real view stack —
# `ApplicationController.renderer` is a full ActionView context (every helper the
# `crosswire.helpers` initializer mixes into ActionView::Base globally, `cw`/`cw_attrs`
# included), the exact context `cw.button` etc. render through in a real app. No
# second templating pipeline, no stub view context.
def render_example(source)
  ApplicationController.renderer.render(inline: source)
end

def props_table(presenter_class)
  # `kind: :css` names' presenter class is a plain `Crosswire::Presenter` (the
  # PRIMITIVE tier's base class), which never `extend`s `Crosswire::UI::Variants` —
  # there is no `.variants` to introspect at all, not merely an empty declaration.
  # Its real keyword arguments are documented on the presenter itself (linked from
  # the page via the eject command), not surfaced as a props table.
  return "<p><em>No declared variants — CSS-only styling of the existing " \
         "primitive; see its own keyword arguments.</em></p>" unless presenter_class.respond_to?(:variants)

  variants = presenter_class.variants
  return "<p><em>No declared variants.</em></p>" if variants.empty?

  rows = variants.map do |prop_name, spec|
    values = spec[:values].map(&:inspect).join(", ")
    <<~ROW
      <tr>
        <td><code>#{CGI.escapeHTML(prop_name.to_s)}</code></td>
        <td><code>#{CGI.escapeHTML(values)}</code></td>
        <td><code>#{CGI.escapeHTML(spec[:default].inspect)}</code></td>
      </tr>
    ROW
  end.join

  <<~HTML
    <table class="props">
      <thead><tr><th>Prop</th><th>Values</th><th>Default</th></tr></thead>
      <tbody>
        #{rows}
      </tbody>
    </table>
  HTML
end

PRIMITIVE_LIB_DIR = File.join(ROOT, "lib/crosswire/presenters")

def morph_clause_for(name)
  # `kind: :css` names carry their Morph: clause on the PRIMITIVE presenter they
  # style, not on a `lib/crosswire/ui/<name>.rb` that was never going to exist — the
  # same branch `ui_contract_audit_test.rb` check 10 and `rake morph:doc` take.
  path = if Crosswire::UI.css_only?(name)
           File.join(PRIMITIVE_LIB_DIR, "#{name}.rb")
         else
           File.join(UI_LIB_DIR, "#{name}.rb")
         end
  clause = File.read(path)[MORPH_CLAUSE]
  abort "#{path} carries no `# Morph:` docstring clause — ui_contract_audit_test.rb " \
        "check 10 should already have caught this" unless clause

  CGI.escapeHTML(clause.gsub(/^\s*#\s?/, ""))
end

def examples_for(name)
  Dir[File.join(EXAMPLES_DIR, name, "*.html.erb")].sort
end

def examples_html(name)
  examples_for(name).map do |path|
    source = File.read(path)
    rendered = render_example(source)
    example_name = File.basename(path, ".html.erb")

    <<~HTML
      <div class="example">
        <div class="stage">#{rendered}</div>
        <div class="source">
          <p class="name">site/examples/#{name}/#{example_name}.html.erb</p>
          <pre><code>#{CGI.escapeHTML(source.strip)}</code></pre>
        </div>
      </div>
    HTML
  end.join
end

def eject_command_for(name)
  "rails g crosswire:eject #{name}"
end

# The gallery index (site/components/index.html) — one card per registered UI
# component, grouped by kind (spec §2b: `kind: :new` ships its own presenter/helper/
# partial/CSS; `kind: :css` styles an EXISTING primitive-tier widget with no new
# markup of its own). Same shell styling approach as site/component_template.html —
# the --cw-* tokens from the bundled stylesheet, not a second hand-rolled palette —
# just laid out as a card grid instead of one component's own page.
def component_card(name)
  description = Crosswire::UI::COMPONENTS.fetch(name.to_sym).fetch(:description)
  <<~HTML
    <a class="card" href="#{CGI.escapeHTML(name)}/index.html">
      <h3>cw.<code>#{CGI.escapeHTML(name)}</code></h3>
      <p>#{CGI.escapeHTML(description)}</p>
    </a>
  HTML
end

def gallery_index_html(new_names, css_names)
  <<~HTML
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Component gallery — crosswire</title>
    <link rel="stylesheet" href="../assets/crosswire-ui.css">
    <style>
      :root { --shell-max: 64rem; }
      * { box-sizing: border-box; }
      body {
        margin: 0;
        background: var(--cw-color-bg);
        color: var(--cw-color-fg);
        font-family: var(--cw-font-sans);
        line-height: var(--cw-leading-normal);
      }
      header.page {
        border-bottom: var(--cw-border-width) solid var(--cw-color-border);
        padding: var(--cw-space-4) var(--cw-space-5);
      }
      header.page a.back { color: var(--cw-color-fg-muted); text-decoration: none; font-size: var(--cw-text-sm); }
      header.page a.back:hover { color: var(--cw-color-accent); }
      h1 { font-size: var(--cw-text-2xl); margin: var(--cw-space-2) 0 0; }
      p.description { color: var(--cw-color-fg-muted); max-width: var(--shell-max); margin: var(--cw-space-2) 0 0; }
      main { max-width: var(--shell-max); margin: 0 auto; padding: var(--cw-space-5); }
      h2 { font-size: var(--cw-text-lg); margin: var(--cw-space-6) 0 var(--cw-space-3); }
      .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(15rem, 1fr)); gap: var(--cw-space-4); }
      .card {
        display: block; border: var(--cw-border-width) solid var(--cw-color-border);
        border-radius: var(--cw-radius-lg); padding: var(--cw-space-4);
        background: var(--cw-color-surface-raised); color: inherit; text-decoration: none;
      }
      .card:hover { border-color: var(--cw-color-accent); }
      .card h3 { margin: 0 0 var(--cw-space-2); font-size: var(--cw-text-base); }
      .card h3 code { font-family: var(--cw-font-mono); }
      .card p { margin: 0; font-size: var(--cw-text-sm); color: var(--cw-color-fg-muted); }
      footer.page { padding: var(--cw-space-6) var(--cw-space-5); color: var(--cw-color-fg-subtle); font-size: var(--cw-text-xs); }
    </style>
    </head>
    <body>
      <header class="page">
        <a class="back" href="../index.html">← crosswire</a>
        <h1>Component gallery</h1>
        <p class="description">Every registered UI-tier component (ui-tier-spec.md §9), rendered from the gem's real source at build time.</p>
      </header>

      <main>
        <h2>New components</h2>
        <p class="description" style="margin-bottom:var(--cw-space-3)">Ship their own presenter, helper, partial and CSS.</p>
        <div class="grid">
          #{new_names.map { |name| component_card(name) }.join}
        </div>

        <h2>Styled widgets</h2>
        <p class="description" style="margin-bottom:var(--cw-space-3)">CSS only, over an existing shipped primitive — no new markup.</p>
        <div class="grid">
          #{css_names.map { |name| component_card(name) }.join}
        </div>
      </main>

      <footer class="page">
        Rendered from the gem's real source at build time — nothing on this page is a mock.
      </footer>
    </body>
    </html>
  HTML
end

FileUtils.rm_rf(OUT_DIR)
FileUtils.mkdir_p(OUT_DIR)

built = Crosswire::UI.component_names.map do |name|
  if examples_for(name).empty?
    abort "#{name} has no site/examples/#{name}/*.html.erb — ui_contract_audit_test.rb " \
          "check 2 should already have caught this"
  end

  presenter_class = presenter_class_for(name)
  css_path = File.join(UI_CSS_DIR, "#{name}.css")
  description = Crosswire::UI::COMPONENTS.fetch(name.to_sym).fetch(:description)

  html = begin
    html = File.read(TEMPLATE)
    html = SiteBundle.inject(html, "<!--INJECT:TITLE-->", CGI.escapeHTML("cw.#{name} — crosswire"))
    html = SiteBundle.inject(html, "<!--INJECT:NAME-->", CGI.escapeHTML(name))
    html = SiteBundle.inject(html, "<!--INJECT:DESCRIPTION-->", CGI.escapeHTML(description))
    html = SiteBundle.inject(html, "<!--INJECT:EXAMPLES-->", examples_html(name))
    html = SiteBundle.inject(html, "<!--INJECT:PROPS-->", props_table(presenter_class))
    html = SiteBundle.inject(html, "<!--INJECT:MORPH-->", morph_clause_for(name))
    html = SiteBundle.inject(html, "<!--INJECT:CSS-->", CGI.escapeHTML(File.read(css_path)))
    SiteBundle.inject(html, "<!--INJECT:EJECT-->", CGI.escapeHTML(eject_command_for(name)))
  rescue RuntimeError => e
    abort "#{name}: #{e.message}"
  end

  out_dir = File.join(OUT_DIR, name)
  FileUtils.mkdir_p(out_dir)
  out_path = File.join(out_dir, "index.html")
  File.write(out_path, html)

  [name, out_path]
end

new_names = Crosswire::UI.component_names.reject { |name| Crosswire::UI.css_only?(name) }
css_names = Crosswire::UI.component_names.select { |name| Crosswire::UI.css_only?(name) }

index_path = File.join(OUT_DIR, "index.html")
File.write(index_path, gallery_index_html(new_names, css_names))

puts "built #{built.size} component page#{"s" unless built.size == 1}:"
built.each { |name, path| puts "  #{name} -> #{path.delete_prefix("#{ROOT}/")}" }
puts "  index -> #{index_path.delete_prefix("#{ROOT}/")}"
puts "wrote #{SITE_CSS_PATH.delete_prefix("#{ROOT}/")}"
