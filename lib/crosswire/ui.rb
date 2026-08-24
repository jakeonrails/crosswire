# frozen_string_literal: true

require "crosswire/ui/variants"
require "crosswire/ui/component"
require "crosswire/ui/slots"

# Phase 1+ adds one pair of requires per shipped component here, eagerly —
#   require "crosswire/ui/button"
#   require "crosswire/ui/button_helper"
# — for the SAME reason lib/crosswire.rb requires every primitive-tier presenter
# eagerly rather than letting Zeitwerk autoload them (see that file's docstring in
# full): `lib/crosswire/ui` is never added to the engine's `autoload_paths` at all
# (see lib/crosswire/engine.rb for why), so nothing under it is discoverable unless
# something requires it by hand. `lib/crosswire.rb`'s eager requires exist to dodge a
# Zeitwerk top-level-constant collision that does not arise here — this file's
# requires exist for the more basic reason that without them `Crosswire::UI::COMPONENTS`
# below would have nothing to reference: it is populated by hand from these requires,
# not discovered from the filesystem.
module Crosswire
  module UI
    # Every styled component crosswire ships in this tier — empty through Phase 0
    # (see the UI-tier spec §10: "gate: audits green, no components"). The generator,
    # the registry (`rake ui:registry`), the docs and `ui_contract_audit_test.rb` all
    # read this, so it stays the single source of truth exactly the way
    # `Crosswire::COMPONENTS` (lib/crosswire.rb) is for the primitive tier — deliberately
    # NOT the same hash, because this tier's contract (markup + CSS presenters, no
    # Stimulus identifier) is a genuinely different shape (spec §2).
    COMPONENTS = {}.freeze

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
