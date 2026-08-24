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

def strip_module_syntax(source)
  source
    .gsub(/^import .*$/, "")                       # inlined, so nothing to import
    .gsub(/^export \{[^}]*\};?\s*$/m, "")          # Stimulus' trailing export block
    .gsub(/^export default class/, "class")        # our controllers
    .gsub(/^export /, "")
end

def class_name_for(name)
  "#{name.split('_').map(&:capitalize).join}Controller"
end

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

# BLOCK FORM IS MANDATORY HERE. `String#sub` with a *string* replacement interprets
# backreferences in that replacement — `\0`–`\9`, `\&`, `\``, `\'`, `\\` and `\+`.
#
# This bit hard. Stimulus's own action-descriptor regex contains `\+`:
#
#   /^(?:(?:([^.]+?)\+)?(.+?)…/
#
# Ruby read that `\+` as "the last matched group", our pattern was a plain string with
# no groups, so it expanded to EMPTY and silently deleted the `\+` from the shipped
# regex. The optional group then swallowed a character, and every `click->` in the page
# was parsed as event `lick`. Nothing threw. The attribute was right, the controller
# connected, the targets resolved — the whole page was simply inert.
#
# The block form returns its value verbatim, with no backreference expansion.
html = File.read(TEMPLATE)
           .sub("<!--INJECT:STIMULUS-->") { stimulus_js }
           .sub("<!--INJECT:CONTROLLERS-->") { controllers }
           .sub("<!--INJECT:REGISTER-->") { registrations }
           .sub("<!--INJECT:VOCAB-->") { vocabulary_rows }

%w[STIMULUS CONTROLLERS REGISTER VOCAB].each do |marker|
  abort "marker <!--INJECT:#{marker}--> was not replaced" if html.include?("<!--INJECT:#{marker}-->")
end

# Guard against the above ever returning, and against any other silent mangling: what
# we inlined must appear in the output byte for byte.
abort "FATAL: inlined Stimulus does not match its source — injection corrupted it" unless html.include?(stimulus_js)
abort "FATAL: inlined controllers do not match their source" unless html.include?(controllers)

# And pin the specific regex, because this is the one whose corruption is invisible:
# no error, no console message, just a page where nothing responds to a click.
descriptor = File.read(STIMULUS)[/const descriptorPattern = .*/]
abort "FATAL: Stimulus action-descriptor regex was altered during injection" unless html.include?(descriptor)

FileUtils.mkdir_p(File.dirname(OUTPUT))
File.write(OUTPUT, html)

total = VOCABULARY.values.flatten.size
puts "built #{OUTPUT}"
puts "  #{(File.size(OUTPUT) / 1024.0).round(1)} KB"
puts "  #{DEMOED.size} live controllers inlined: #{DEMOED.join(", ")}"
puts "  vocabulary: #{shipped.size} shipped of #{total} specified"
