# frozen_string_literal: true

require_relative "lib/crosswire/version"

Gem::Specification.new do |spec|
  spec.name        = "crosswire"
  spec.version     = Crosswire::VERSION
  spec.authors     = ["Jake Moffatt"]
  spec.email       = ["jake.moffatt@gmail.com"]

  spec.summary     = "Composable, accessible Hotwire primitives for Rails."
  spec.description = <<~TEXT.tr("\n", " ").strip
    Small, generic, composable Stimulus controllers paired with ERB helpers, so rich UI
    stays "The Rails Way" without reaching for React. Every component is APG-accessible
    in the controller, not by consumer opt-in.
  TEXT
  spec.homepage = "https://github.com/jakeonrails/crosswire"
  spec.license  = "MIT"

  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "app/**/*", "lib/**/*", "docs/**/*.md", "skills/**/*",
    "MIT-LICENSE", "README.md", "CHANGELOG.md"
  ]

  # Deliberately thin. No ViewComponent, no Phlex — see docs/DECISIONS.md D5.
  spec.add_dependency "railties",   ">= 7.1", "< 9"
  spec.add_dependency "actionview", ">= 7.1", "< 9"
end
