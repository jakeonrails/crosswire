# frozen_string_literal: true

require "crosswire/ui/variants"
require "crosswire/ui/component"
require "crosswire/ui/slots"

# One pair of requires per shipped component, eagerly — for the SAME reason
# lib/crosswire.rb requires every primitive-tier presenter eagerly rather than
# letting Zeitwerk autoload them (see that file's docstring in full): `lib/crosswire/ui`
# is never added to the engine's `autoload_paths` at all (see lib/crosswire/engine.rb
# for why), so nothing under it is discoverable unless something requires it by hand.
# `lib/crosswire.rb`'s eager requires exist to dodge a Zeitwerk top-level-constant
# collision that does not arise here — this file's requires exist for the more basic
# reason that without them `Crosswire::UI::COMPONENTS` below would have nothing to
# reference: it is populated by hand from these requires, not discovered from the
# filesystem.
require "crosswire/ui/button"
require "crosswire/ui/button_helper"
require "crosswire/ui/badge"
require "crosswire/ui/badge_helper"
require "crosswire/ui/card"
require "crosswire/ui/card_helper"
require "crosswire/ui/input"
require "crosswire/ui/input_helper"
require "crosswire/ui/field"
require "crosswire/ui/field_helper"
require "crosswire/ui/select"
require "crosswire/ui/select_helper"
require "crosswire/ui/alert"
require "crosswire/ui/alert_helper"
require "crosswire/ui/toast_viewport"
require "crosswire/ui/toast"
require "crosswire/ui/toast_helper"

module Crosswire
  module UI
    # Every styled component crosswire ships in this tier, keyed by the name the
    # generator, `rake ui:registry`, `docs/MORPH.md` and `ui_contract_audit_test.rb`
    # all key off — deliberately NOT the same hash shape as `Crosswire::COMPONENTS`
    # (lib/crosswire.rb, name => presenter CLASS): this tier's registry (spec §4) is
    # shadcn-shaped, one JSON entry per component drawn from real filesystem state
    # (files, declared `--cw-<name>-*` knobs) plus a short hand-written description —
    # so each value here carries only what the filesystem genuinely cannot derive.
    #
    #   COMPONENTS.fetch(:button).fetch(:description)
    #   Crosswire::UI.component_names # => ["button", "badge"]
    COMPONENTS = {
      button: {
        description: "A button or link with five variants, three sizes, and the " \
                      "three accessibility guarantees a plain <button>/<a> gets " \
                      "wrong by default (type=button, disabled-anchor semantics, " \
                      "aria-busy/data-loading)."
      }.freeze,
      badge: {
        description: "Inert status text with six variants and an optional leading " \
                      "dot — the smallest UI-tier component."
      }.freeze,
      card: {
        description: "A grouping container with header/body/footer slots (plain, " \
                      "raised, or outlined) — the tier's Slots proof, and the a11y " \
                      "doctrine for making a whole card clickable without a fake " \
                      "role or tabindex."
      }.freeze,
      input: {
        description: "A styled native <input>/<textarea> shell — size variant, an " \
                      "aria-invalid styling hook, and a data-loading state. No JS."
      }.freeze,
      field: {
        description: "A label + control + hint + error wrapper that wires for/id, " \
                      "aria-describedby, aria-errormessage and aria-invalid — " \
                      "composes cw.input by default, any control via field_for."
      }.freeze,
      select: {
        description: "A styled NATIVE <select> — the tier's Rule 0 exemplar: no " \
                      "reimplemented listbox, just the platform control, styled."
      }.freeze,
      alert: {
        description: "A severity-coded message (role status/alert picked from the " \
                      "severity, never both a role and a redundant aria-live) with " \
                      "an optional dismiss — the tier's composition showcase, " \
                      "stacking the existing cw--dismiss primitive onto one element."
      }.freeze,
      toast: {
        description: "A viewport-fixed live-region container plus individual " \
                      "toasts composing cw--dismiss + cw--timeout + cw--transition " \
                      "— server-rendered on first paint or Turbo-Stream-appended " \
                      "later; the container survives a page morph via " \
                      "data-turbo-permanent."
      }.freeze,

      # --- kind: :css — the OTHER anatomy rule (spec §2b): CSS ONLY over an EXISTING,
      # identically-named primitive-tier widget. No new presenter, no new helper, no
      # new partial — `Crosswire::Presenters::Dialog`/`Popover`/`Menu`/`Combobox` and
      # their shipped `app/views/crosswire/_<name>.html.erb` partials already exist
      # and are unchanged; this tier only adds `app/assets/stylesheets/crosswire/ui/
      # <name>.css` plus a gallery example that exercises the real `cw.<name>`. Every
      # entry above this comment defaults to `kind: :new` (the `.fetch(:kind, :new)`
      # below) — the four below are the only `kind: :css` entries, and their NAME
      # deliberately DOES collide with a primitive-tier `Crosswire::COMPONENTS` entry
      # (see `kind_of`/`css_only?` and `ui_contract_audit_test.rb` check 5, which
      # asserts that collision on purpose instead of flagging it as a bug).
      dialog: {
        description: "CSS over the shipped native <dialog> widget — ::backdrop, " \
                      "@starting-style enter/exit transitions, :modal sizing, and " \
                      "internal scroll containment. The modal-composition showcase: " \
                      "no new markup, no new presenter, styles cw.dialog as-is.",
        kind: :css
      }.freeze,
      popover: {
        description: "CSS over the shipped native popovertarget/popover widget — " \
                      "elevation, radius, padding rhythm. Positioning stays entirely " \
                      "in the primitive; this tier adds nothing but paint.",
        kind: :css
      }.freeze,
      menu: {
        description: "CSS over the shipped role=menu widget — item hover/focus/" \
                      "checked states, a documented [role=separator] treatment the " \
                      "partial itself never emits, a .cw-menu__item--danger " \
                      "modifier, and disabled styling.",
        kind: :css
      }.freeze,
      combobox: {
        description: "CSS over the shipped APG combobox widget — listbox " \
                      "elevation, [aria-selected] and the controller's opt-in " \
                      "active-option class, empty-state and status styling.",
        kind: :css
      }.freeze
    }.freeze

    def self.component_names = COMPONENTS.keys.map(&:to_s)

    # `kind: :new` (this tier's own presenter + partial + CSS — the default; every
    # entry above omits the key entirely) vs `kind: :css` (spec §2b — CSS only, over
    # an existing primitive; see dialog/popover/menu/combobox above). Every audit
    # check, `rake ui:registry` and `rake morph:doc` read this to know which file set
    # and which source file apply to a given name — each of their own branches
    # explains why. `.fetch(:kind, :new)` rather than requiring every one of the
    # first eight entries to spell out `kind: :new` by hand.
    def self.kind_of(name) = COMPONENTS.fetch(name.to_sym).fetch(:kind, :new)

    def self.css_only?(name) = kind_of(name) == :css

    # Independent of `Crosswire::CONTRACT_VERSION` (lib/crosswire/version.rb), which
    # governs the PRIMITIVE tier's shipped partials only. This tier gets its own
    # counter because its markup contract can and will churn on its own schedule —
    # in-core rather than a second gem (pagy extras precedent; docs/DECISIONS.md D7
    # precedent), reopen-if design churn forces annoying minor bumps (spec §2).
    # `Crosswire::ShadowCheck` compares a UI partial's `<%# crosswire:contract vN %>`
    # marker against THIS constant, not against `Crosswire::CONTRACT_VERSION`.
    CONTRACT_VERSION = 1
  end
end
