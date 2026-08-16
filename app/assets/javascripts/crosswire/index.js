import DisclosureController from "crosswire/controllers/disclosure_controller"
import DismissController from "crosswire/controllers/dismiss_controller"

/**
 * Register every crosswire controller under its `cw--` identifier.
 *
 *   import { Application } from "@hotwired/stimulus"
 *   import { registerCrosswireControllers } from "crosswire"
 *
 *   const application = Application.start()
 *   registerCrosswireControllers(application)
 *
 * Registration is explicit rather than convention-scanned because stimulus-loading
 * derives identifiers from the consumer's own controllers directory, which would give
 * our controllers un-namespaced names and collide with theirs.
 *
 * To lazy-load instead, import individual controllers — each ships as its own module
 * precisely so it can be code-split. A single bundle cannot be lazy-loaded.
 */
export const CROSSWIRE_CONTROLLERS = {
  "cw--disclosure": DisclosureController,
  "cw--dismiss": DismissController
}

export function registerCrosswireControllers(application, only = null) {
  for (const [identifier, controller] of Object.entries(CROSSWIRE_CONTROLLERS)) {
    if (only && !only.includes(identifier)) continue
    application.register(identifier, controller)
  }
}

export { DisclosureController, DismissController }
