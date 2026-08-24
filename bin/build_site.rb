#!/usr/bin/env ruby
# frozen_string_literal: true

# Assembles site/index.html from site/template.html plus the gem's REAL source.
#
# The demos on the site run the actual shipped controllers, inlined at build time —
# not reimplementations. That is the point: a component library whose marketing page
# is a mock has already told you something about the library.
#
# Run: bin/build_site.rb  (or `rake site`)

require "fileutils"
require_relative "../lib/crosswire/vocabulary"
require_relative "lib/site_bundle"

ROOT = File.expand_path("..", __dir__)
TEMPLATE = File.join(ROOT, "site/template.html")
OUTPUT = File.join(ROOT, "site/index.html")
STIMULUS = File.join(ROOT, "node_modules/@hotwired/stimulus/dist/stimulus.js")
CONTROLLERS = File.join(ROOT, "app/assets/javascripts/crosswire/controllers")
MORPH = File.join(ROOT, "app/assets/javascripts/crosswire/morph.js")

# Only the controllers the page actually demonstrates. Inlining all of them would
# bloat the page with code no demo exercises.
DEMOED = %w[disclosure dismiss clipboard dialog hotkey persist].freeze

# The reconciled 39-primitive vocabulary now lives in lib/crosswire/vocabulary.rb —
# the UI-tier name-collision lint needs the same table, so it is required above
# rather than defined twice. See that file's docstring.
VOCABULARY = Crosswire::VOCABULARY

def shipped
  @shipped ||= Dir[File.join(CONTROLLERS, "*_controller.js")]
               .map { |p| File.basename(p).sub(/_controller\.js\z/, "").tr("_", "-") }
               .to_set
end

require "set"

# `strip_module_syntax`/`class_name_for` now live in bin/lib/site_bundle.rb — shared
# with bin/build_gallery.rb (ui-tier-spec.md §9), moved rather than re-derived.
def strip_module_syntax(source) = SiteBundle.strip_module_syntax(source)
def class_name_for(name) = SiteBundle.class_name_for(name)

def vocabulary_rows
  VOCABULARY.map do |group, names|
    chips = names.sort.map do |name|
      klass = shipped.include?(name) ? "chip chip-ship" : "chip chip-plan"
      title = shipped.include?(name) ? "shipped" : "specified, not yet built"
      %(<span class="#{klass}" title="#{title}">#{name}</span>)
    end.join(" ")

    count = names.count { |n| shipped.include?(n) }
    <<~ROW
      <tr>
        <td><strong>#{group}</strong><br><span style="color:var(--ink-faint);font-size:.8125rem">#{count}/#{names.size} shipped</span></td>
        <td style="line-height:2">#{chips}</td>
      </tr>
    ROW
  end.join("\n")
end

abort "missing #{TEMPLATE}" unless File.exist?(TEMPLATE)
abort "run `npm install` first — #{STIMULUS} not found" unless File.exist?(STIMULUS)

controller_sources = DEMOED.map do |name|
  path = File.join(CONTROLLERS, "#{name}_controller.js")
  abort "demo references #{name} but #{path} does not exist" unless File.exist?(path)

  [name, File.read(path)]
end

# `crosswire/morph.js` is a sibling MODULE, not a controller — nothing in
# app/assets/javascripts/crosswire/controllers/ pulls it in automatically the way
# `stimulus.js` above is always inlined. A demoed controller that imports it (currently
# only `disclosure`, via `usePreserve`) would otherwise reference an undefined function
# once `strip_module_syntax` deletes the `import` line: the single-file site has no
# module resolution, so every export has to land in the same flat script scope. Detect
# the need from the real source rather than hardcoding "disclosure", so the next
# controller built the same way is covered for free.
needs_morph = controller_sources.any? { |_, source| source.match?(%r{from\s+["']crosswire/morph["']}) }
morph_js = needs_morph ? "// ---- morph.js " + ("-" * 46) + "\n" + strip_module_syntax(File.read(MORPH)) : nil

controllers = [
  morph_js,
  *controller_sources.map do |name, source|
    "// ---- #{name}_controller.js " + ("-" * 40) + "\n" + strip_module_syntax(source)
  end
].compact.join("\n\n")

registrations = DEMOED.map do |name|
  %(application.register("cw--#{name.tr("_", "-")}", #{class_name_for(name)}))
end.join("\n")

stimulus_js = strip_module_syntax(File.read(STIMULUS))

# The block-form-`sub`-with-backreference-hazard story (see bin/lib/site_bundle.rb's
# `SiteBundle.inject` docstring for the full account) and the byte-guards below both
# now live there too — shared with bin/build_gallery.rb, moved rather than re-derived.
# Wrapped in a top-level `abort`, same CLI behaviour as before the move: a clean
# one-line stderr message and a non-zero exit, no Ruby backtrace.
begin
  html = File.read(TEMPLATE)
  html = SiteBundle.inject(html, "<!--INJECT:STIMULUS-->", stimulus_js)
  html = SiteBundle.inject(html, "<!--INJECT:CONTROLLERS-->", controllers)
  html = SiteBundle.inject(html, "<!--INJECT:REGISTER-->", registrations)
  html = SiteBundle.inject(html, "<!--INJECT:VOCAB-->", vocabulary_rows)

  SiteBundle.assert_present!(html, stimulus_js, "inlined Stimulus")
  SiteBundle.assert_present!(html, controllers, "inlined controllers")

  # And pin the specific regex, because this is the one whose corruption is invisible:
  # no error, no console message, just a page where nothing responds to a click.
  descriptor = File.read(STIMULUS)[/const descriptorPattern = .*/]
  SiteBundle.assert_present!(html, descriptor, "Stimulus action-descriptor regex")
rescue RuntimeError => e
  abort e.message
end

FileUtils.mkdir_p(File.dirname(OUTPUT))
File.write(OUTPUT, html)

total = VOCABULARY.values.flatten.size
puts "built #{OUTPUT}"
puts "  #{(File.size(OUTPUT) / 1024.0).round(1)} KB"
puts "  #{DEMOED.size} live controllers inlined: #{DEMOED.join(", ")}"
puts "  vocabulary: #{shipped.size} shipped of #{total} specified"
