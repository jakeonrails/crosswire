# frozen_string_literal: true

pin "application"
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js"

# Dev/test only (see root Gemfile) — needed here only for the `preserve` Lookbook
# preview's "simulate morph" button, which drives a real morph via `morphElements`
# rather than faking one. Not a gem dependency; see Rule 0 in
# app/assets/javascripts/crosswire/morph.js for why crosswire itself never imports
# Turbo — it only ever listens for the events Turbo dispatches.
pin "@hotwired/turbo", to: "@hotwired--turbo.js"

# `crosswire/index.js` and every `crosswire/controllers/*_controller.js` come from the
# engine's own asset path — the controllers are pinned by the engine's importmap
# initializer (one module each, so they stay lazy-loadable; see D5 R2).
# `crosswire/morph` is pinned by that same initializer.
pin "crosswire", to: "crosswire/index.js"
