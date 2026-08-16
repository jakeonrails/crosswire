# frozen_string_literal: true

pin "application"
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js"

# `crosswire/index.js` and every `crosswire/controllers/*_controller.js` come from the
# engine's own asset path — the controllers are pinned by the engine's importmap
# initializer (one module each, so they stay lazy-loadable; see D5 R2).
pin "crosswire", to: "crosswire/index.js"
