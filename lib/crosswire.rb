# frozen_string_literal: true

require "json"

require "crosswire/version"
require "crosswire/attributes"
require "crosswire/presenter"

# Presenters are plain Ruby and required eagerly, so they can be used — and unit
# tested — without Rails. `ruby -Ilib -rcrosswire -e '...'` is a supported entry point,
# and the test suite relies on it. See docs/DECISIONS.md D5.
require "crosswire/presenters/autosubmit"
require "crosswire/presenters/clipboard"
require "crosswire/presenters/confirm"
require "crosswire/presenters/dialog"
require "crosswire/presenters/disclosure"
require "crosswire/presenters/dismiss"
require "crosswire/presenters/focus_trap"
require "crosswire/presenters/intersection"
require "crosswire/presenters/persist"
require "crosswire/presenters/transition"

module Crosswire
  class Error < StandardError; end

  # Every component crosswire ships. The generator and docs read this list, so it is
  # the single source of truth for what exists.
  #
  # Ordered as the vocabulary is grouped in research/notes/08, not alphabetically:
  # behaviours first (the ones everything else composes from), then widgets, then
  # utilities. `dismiss` and `transition` sit next to each other deliberately — the
  # cancelable-dismissal seam between them is the reference example of R6.
  COMPONENTS = {
    # Behaviours — decorate an existing element, ship no markup
    dismiss: Crosswire::Presenters::Dismiss,
    transition: Crosswire::Presenters::Transition,
    persist: Crosswire::Presenters::Persist,
    intersection: Crosswire::Presenters::Intersection,
    focus_trap: Crosswire::Presenters::FocusTrap,
    clipboard: Crosswire::Presenters::Clipboard,
    autosubmit: Crosswire::Presenters::Autosubmit,

    # Widgets — own markup, ship an ejectable partial
    disclosure: Crosswire::Presenters::Disclosure,
    dialog: Crosswire::Presenters::Dialog,
    confirm: Crosswire::Presenters::Confirm
  }.freeze

  def self.component_names = COMPONENTS.keys.map(&:to_s)

  # The Stimulus identifier for a component, derived from its presenter so Ruby and JS
  # cannot drift: `:focus_trap` => `"cw--focus-trap"`.
  def self.identifier_for(name)
    COMPONENTS.fetch(name.to_sym).identifier
  end
end

require "crosswire/shadow_check" if defined?(Rails)
require "crosswire/engine" if defined?(Rails::Engine)
