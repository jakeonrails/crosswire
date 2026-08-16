import { Application } from "@hotwired/stimulus"
import { registerCrosswireControllers } from "crosswire"

const application = Application.start()
application.debug = false

// One call registers all ten under their `cw--` identifiers. Pass an array as the
// second argument to register a subset.
registerCrosswireControllers(application)

window.Stimulus = application

// A tiny probe the demo pages use to prove, in a real browser, that the controllers
// registered and connected — not just that the attributes rendered.
document.addEventListener("DOMContentLoaded", () => {
  const badge = document.getElementById("stimulus-status")
  if (!badge) return
  const identifiers = application.router.modules.map((m) => m.identifier)
  badge.textContent = `Stimulus up · ${identifiers.filter((i) => i.startsWith("cw--")).length} crosswire controllers registered`
  badge.dataset.ready = "true"
})
