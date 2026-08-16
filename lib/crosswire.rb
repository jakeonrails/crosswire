# frozen_string_literal: true

require "json"

require "crosswire/version"
require "crosswire/attributes"
require "crosswire/presenter"

# Presenters are plain Ruby and required eagerly, so they can be used — and unit
# tested — without Rails. `ruby -Ilib -rcrosswire -e '...'` is a supported entry point,
# and the test suite relies on it. See docs/DECISIONS.md D5.
require "crosswire/presenters/disclosure"
require "crosswire/presenters/dismiss"

module Crosswire
  class Error < StandardError; end

  # Every component crosswire ships, in build order (most load-bearing first).
  # `nil` entries are declared but not yet implemented — the generator and docs read
  # this list, so it is the single source of truth for what exists.
  COMPONENTS = {
    disclosure: Crosswire::Presenters::Disclosure,
    dismiss: Crosswire::Presenters::Dismiss
  }.freeze

  def self.component_names = COMPONENTS.keys.map(&:to_s)
end

require "crosswire/shadow_check" if defined?(Rails)
require "crosswire/engine" if defined?(Rails::Engine)
