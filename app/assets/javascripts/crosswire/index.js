import AutosubmitController from "crosswire/controllers/autosubmit_controller"
import ClipboardController from "crosswire/controllers/clipboard_controller"
import ConfirmController from "crosswire/controllers/confirm_controller"
import DialogController from "crosswire/controllers/dialog_controller"
import DisclosureController from "crosswire/controllers/disclosure_controller"
import DismissController from "crosswire/controllers/dismiss_controller"
import FocusTrapController from "crosswire/controllers/focus_trap_controller"
import IntersectionController from "crosswire/controllers/intersection_controller"
import PersistController from "crosswire/controllers/persist_controller"
import TransitionController from "crosswire/controllers/transition_controller"

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
 * precisely so it can be code-split. A single bundle cannot be lazy-loaded, because
 * stimulus-loading registers via a dynamic `import("${under}/${name}_controller")`.
 *
 * Registering a subset is supported, and worth doing if you only use a few:
 *
 *   registerCrosswireControllers(application, ["cw--disclosure", "cw--dismiss"])
 *
 * Note `cw--confirm` composes with `cw--dialog` by stacking on the same element
 * (see R5a in docs/COMPONENT_CONTRACT.md), so registering confirm without dialog
 * leaves it inert. `assertRegistrationComplete` below catches that.
 */
export const CROSSWIRE_CONTROLLERS = {
  // Behaviours
  "cw--dismiss": DismissController,
  "cw--transition": TransitionController,
  "cw--persist": PersistController,
  "cw--intersection": IntersectionController,
  "cw--focus-trap": FocusTrapController,
  "cw--clipboard": ClipboardController,
  "cw--autosubmit": AutosubmitController,

  // Widgets
  "cw--disclosure": DisclosureController,
  "cw--dialog": DialogController,
  "cw--confirm": ConfirmController
}

/** Controllers that are inert without a stacked partner. */
const REQUIRES = {
  "cw--confirm": ["cw--dialog"]
}

export function registerCrosswireControllers(application, only = null) {
  const identifiers = only ?? Object.keys(CROSSWIRE_CONTROLLERS)

  for (const identifier of identifiers) {
    const controller = CROSSWIRE_CONTROLLERS[identifier]
    if (!controller) {
      throw new Error(
        `[crosswire] unknown controller ${identifier}. Known: ${Object.keys(CROSSWIRE_CONTROLLERS).join(", ")}`
      )
    }
    application.register(identifier, controller)
  }

  assertRegistrationComplete(identifiers)
}

function assertRegistrationComplete(identifiers) {
  for (const [identifier, needed] of Object.entries(REQUIRES)) {
    if (!identifiers.includes(identifier)) continue

    const missing = needed.filter((dependency) => !identifiers.includes(dependency))
    if (missing.length === 0) continue

    // Warn rather than throw: the app still works, this component just won't. A hard
    // failure at boot over an unused component would be worse than the bug it prevents.
    console.warn(
      `[crosswire] ${identifier} composes with ${missing.join(", ")}, which ${missing.length === 1 ? "is" : "are"} not registered. ` +
        `${identifier} will not function. See R5a in docs/COMPONENT_CONTRACT.md.`
    )
  }
}

export {
  AutosubmitController,
  ClipboardController,
  ConfirmController,
  DialogController,
  DisclosureController,
  DismissController,
  FocusTrapController,
  IntersectionController,
  PersistController,
  TransitionController
}
