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

ROOT = File.expand_path("..", __dir__)
TEMPLATE = File.join(ROOT, "site/template.html")
OUTPUT = File.join(ROOT, "site/index.html")
STIMULUS = File.join(ROOT, "node_modules/@hotwired/stimulus/dist/stimulus.js")
CONTROLLERS = File.join(ROOT, "app/assets/javascripts/crosswire/controllers")

# Only the controllers the page actually demonstrates. Inlining all of them would
# bloat the page with code no demo exercises.
DEMOED = %w[disclosure dismiss clipboard dialog].freeze

# The reconciled 38-primitive vocabulary, grouped as in research/notes/08. Shipped
# status is derived from the filesystem, never hand-maintained, so the table cannot
# drift from reality.
VOCABULARY = {
  "Behaviour" => %w[dismiss persist intersection transition focus-trap roving-focus hotkey sync
                    timeout scroll-lock interval click-outside anchor activate autoscroll cable-channel],
  "Widget" => %w[dialog combobox popover disclosure tabs menu],
  "Form" => %w[autosubmit dirty-form direct-upload char-count nested-form drop-zone reveal
               file-preview input-mask autogrow],
  "Collection" => %w[sortable selection chart],
  "Utility" => %w[relative-time confirm clipboard countdown]
}.freeze

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

controllers = DEMOED.map do |name|
  path = File.join(CONTROLLERS, "#{name}_controller.js")
  abort "demo references #{name} but #{path} does not exist" unless File.exist?(path)

  "// ---- #{name}_controller.js " + ("-" * 40) + "\n" + strip_module_syntax(File.read(path))
end.join("\n\n")

registrations = DEMOED.map do |name|
  %(application.register("cw--#{name.tr("_", "-")}", #{class_name_for(name)}))
end.join("\n")

html = File.read(TEMPLATE)
           .sub("<!--INJECT:STIMULUS-->", strip_module_syntax(File.read(STIMULUS)))
           .sub("<!--INJECT:CONTROLLERS-->", controllers)
           .sub("<!--INJECT:REGISTER-->", registrations)
           .sub("<!--INJECT:VOCAB-->", vocabulary_rows)

%w[STIMULUS CONTROLLERS REGISTER VOCAB].each do |marker|
  abort "marker <!--INJECT:#{marker}--> was not replaced" if html.include?("<!--INJECT:#{marker}-->")
end

FileUtils.mkdir_p(File.dirname(OUTPUT))
File.write(OUTPUT, html)

total = VOCABULARY.values.flatten.size
puts "built #{OUTPUT}"
puts "  #{(File.size(OUTPUT) / 1024.0).round(1)} KB"
puts "  #{DEMOED.size} live controllers inlined: #{DEMOED.join(", ")}"
puts "  vocabulary: #{shipped.size} shipped of #{total} specified"
