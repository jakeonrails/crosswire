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
      }.freeze
    }.freeze

    def self.component_names = COMPONENTS.keys.map(&:to_s)

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
