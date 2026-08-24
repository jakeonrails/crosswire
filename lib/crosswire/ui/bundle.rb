# frozen_string_literal: true

require "crosswire/ui"

module Crosswire
  module UI
    # Builds the concatenated ui.css bundle: the layer-order declaration, then
    # tokens.css, then base.css, then every registered component's own CSS in
    # `Crosswire::UI::COMPONENTS` order (spec §6/§9: "layer decl + concatenation in
    # registry order"). This is the ONE place that algorithm lives — `rake ui:bundle`
    # (Rakefile) writes `app/assets/stylesheets/crosswire/ui.css` from it, and
    # `ui_contract_audit_test.rb`'s byte-equality guard (spec §7.5 check 9) reads
    # from it to verify the checked-in bundle hasn't drifted. Sharing it is exactly
    # the lesson `lib/crosswire/vocabulary.rb` already draws from `bin/build_site.rb`:
    # a Rake task and a test each hand-rolling "read these files in this order and
    # join them" is how the two quietly disagree.
    module Bundle
      # Declared once here; every individual file (tokens.css, base.css, each
      # component's css) wraps its OWN rules in the matching `@layer` block, so
      # each stays correctly ordered even when an app loads it standalone instead
      # of through this bundle (tokens.css's own header comment explains why).
      LAYER_DECLARATION = "@layer crosswire.tokens, crosswire.base, crosswire.components;\n\n"

      def self.ui_dir
        File.expand_path("../../../app/assets/stylesheets/crosswire/ui", __dir__)
      end

      def self.bundle_path
        File.expand_path("../../../app/assets/stylesheets/crosswire/ui.css", __dir__)
      end

      def self.source
        files = [File.join(ui_dir, "tokens.css"), File.join(ui_dir, "base.css")]
        files.concat(Crosswire::UI.component_names.map { |name| File.join(ui_dir, "#{name}.css") })

        LAYER_DECLARATION + files.map { |path| File.read(path) }.join("\n")
      end
    end
  end
end
