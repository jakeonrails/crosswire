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

abort "missing #{TEMPLATE}" unless File.exist?(TEMPLATE)

MORPH_CLAUSE = /^\s*# Morph:.*(?:\n\s*#.*)*/

def presenter_class_for(name)
  Crosswire::UI.const_get(name.camelize)
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

def morph_clause_for(name)
  path = File.join(UI_LIB_DIR, "#{name}.rb")
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

puts "built #{built.size} component page#{"s" unless built.size == 1}:"
built.each { |name, path| puts "  #{name} -> #{path.delete_prefix("#{ROOT}/")}" }
