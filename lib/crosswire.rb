# frozen_string_literal: true

require "json"

require "crosswire/version"
require "crosswire/attributes"
require "crosswire/presenter"

# Presenters are plain Ruby and required eagerly, so they can be used — and unit
# tested — without Rails. `ruby -Ilib -rcrosswire -e '...'` is a supported entry point,
# and the test suite relies on it (docs/DECISIONS.md D5).
#
# These eager requires are also load-bearing for a reason that is easy to miss: the
# engine adds this directory to `autoload_paths`, which makes it a Zeitwerk *root*.
# By Zeitwerk's normal rules `disclosure.rb` would then have to define a TOP-LEVEL
# `Disclosure` — and would collide with a consumer's own `Dialog`, `Confirm` or
# `Persist`. It doesn't collide only because requiring the files here first makes
# Zeitwerk treat them as shadowed and register no autoload at all. Drop these requires
# and the namespace hazard comes back. Pinned by a test.
require "crosswire/presenters/autosubmit"
require "crosswire/presenters/click_outside"
require "crosswire/presenters/clipboard"
require "crosswire/presenters/confirm"
require "crosswire/presenters/dialog"
require "crosswire/presenters/disclosure"
require "crosswire/presenters/dismiss"
require "crosswire/presenters/focus_trap"
require "crosswire/presenters/hotkey"
require "crosswire/presenters/intersection"
require "crosswire/presenters/persist"
require "crosswire/presenters/popover"
require "crosswire/presenters/roving_focus"
require "crosswire/presenters/scroll_lock"
require "crosswire/presenters/sync"
require "crosswire/presenters/tabs"
require "crosswire/presenters/timeout"
require "crosswire/presenters/transition"

module Crosswire
  class Error < StandardError; end

  # Every component crosswire ships. The generator, the docs, the Lookbook preview
  # check and the contract audit all read this, so it is the single source of truth.
  #
  # Grouped as the vocabulary is in research/notes/08, not alphabetically: behaviours
  # first — they are what everything else composes from — then widgets. `dismiss` and
  # `transition` sit adjacent deliberately; the cancelable-dismissal seam between them
  # is the reference example of R6.
  COMPONENTS = {
    # Behaviours — decorate an existing element, ship no markup
    dismiss: Crosswire::Presenters::Dismiss,
    transition: Crosswire::Presenters::Transition,
    persist: Crosswire::Presenters::Persist,
    intersection: Crosswire::Presenters::Intersection,
    focus_trap: Crosswire::Presenters::FocusTrap,
    roving_focus: Crosswire::Presenters::RovingFocus,
    hotkey: Crosswire::Presenters::Hotkey,
    click_outside: Crosswire::Presenters::ClickOutside,
    scroll_lock: Crosswire::Presenters::ScrollLock,
    timeout: Crosswire::Presenters::Timeout,
    sync: Crosswire::Presenters::Sync,
    clipboard: Crosswire::Presenters::Clipboard,
    autosubmit: Crosswire::Presenters::Autosubmit,

    # Widgets — own markup, ship an ejectable partial
    disclosure: Crosswire::Presenters::Disclosure,
    dialog: Crosswire::Presenters::Dialog,
    confirm: Crosswire::Presenters::Confirm,
    tabs: Crosswire::Presenters::Tabs,
    popover: Crosswire::Presenters::Popover
  }.freeze

  def self.component_names = COMPONENTS.keys.map(&:to_s)

  # `:focus_trap` => `"cw--focus-trap"`. Derived from the presenter class so Ruby and
  # JS cannot drift.
  def self.identifier_for(name)
    COMPONENTS.fetch(name.to_sym).identifier
  end
end

require "crosswire/shadow_check" if defined?(Rails)
require "crosswire/engine" if defined?(Rails::Engine)
