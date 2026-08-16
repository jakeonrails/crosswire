import ActivateController from "crosswire/controllers/activate_controller"
import AutogrowController from "crosswire/controllers/autogrow_controller"
import AutosubmitController from "crosswire/controllers/autosubmit_controller"
import CharCountController from "crosswire/controllers/char_count_controller"
import ClickOutsideController from "crosswire/controllers/click_outside_controller"
import ClipboardController from "crosswire/controllers/clipboard_controller"
import ConfirmController from "crosswire/controllers/confirm_controller"
import CountdownController from "crosswire/controllers/countdown_controller"
import DialogController from "crosswire/controllers/dialog_controller"
import DirtyFormController from "crosswire/controllers/dirty_form_controller"
import DisclosureController from "crosswire/controllers/disclosure_controller"
import DismissController from "crosswire/controllers/dismiss_controller"
import FocusTrapController from "crosswire/controllers/focus_trap_controller"
import HotkeyController from "crosswire/controllers/hotkey_controller"
import IntersectionController from "crosswire/controllers/intersection_controller"
import IntervalController from "crosswire/controllers/interval_controller"
import PersistController from "crosswire/controllers/persist_controller"
import PopoverController from "crosswire/controllers/popover_controller"
import PreserveController from "crosswire/controllers/preserve_controller"
import RelativeTimeController from "crosswire/controllers/relative_time_controller"
import RevealController from "crosswire/controllers/reveal_controller"
import RovingFocusController from "crosswire/controllers/roving_focus_controller"
import ScrollLockController from "crosswire/controllers/scroll_lock_controller"
import SelectionController from "crosswire/controllers/selection_controller"
import SortableController from "crosswire/controllers/sortable_controller"
import SyncController from "crosswire/controllers/sync_controller"
import TabsController from "crosswire/controllers/tabs_controller"
import TimeoutController from "crosswire/controllers/timeout_controller"
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
 * derives identifiers from the consumer's own controllers directory, which would strip
 * our `cw--` namespace and collide with their controllers.
 *
 * To lazy-load instead, import individual controllers — each ships as its own module
 * precisely so it can be code-split. A single bundle cannot be, because stimulus-loading
 * registers via a dynamic `import("${under}/${name}_controller")`.
 *
 * Registering a subset is supported:
 *
 *   registerCrosswireControllers(application, ["cw--disclosure", "cw--dismiss"])
 */
export const CROSSWIRE_CONTROLLERS = {
  // Behaviours
  "cw--dismiss": DismissController,
  "cw--transition": TransitionController,
  "cw--persist": PersistController,
  "cw--intersection": IntersectionController,
  "cw--focus-trap": FocusTrapController,
  "cw--roving-focus": RovingFocusController,
  "cw--hotkey": HotkeyController,
  "cw--click-outside": ClickOutsideController,
  "cw--scroll-lock": ScrollLockController,
  "cw--timeout": TimeoutController,
  "cw--interval": IntervalController,
  "cw--sync": SyncController,
  "cw--activate": ActivateController,
  "cw--clipboard": ClipboardController,
  "cw--autosubmit": AutosubmitController,
  "cw--dirty-form": DirtyFormController,
  "cw--char-count": CharCountController,
  "cw--reveal": RevealController,
  "cw--autogrow": AutogrowController,
  "cw--selection": SelectionController,
  "cw--sortable": SortableController,
  "cw--relative-time": RelativeTimeController,
  "cw--countdown": CountdownController,
  "cw--preserve": PreserveController,

  // Widgets
  "cw--disclosure": DisclosureController,
  "cw--dialog": DialogController,
  "cw--confirm": ConfirmController,
  "cw--tabs": TabsController,
  "cw--popover": PopoverController
}

/**
 * Controllers that are inert without a stacked partner (see R5a — crosswire composes
 * by stacking controllers on one element and wiring them with events, never outlets).
 */
const REQUIRES = {
  "cw--confirm": ["cw--dialog"],
  "cw--tabs": ["cw--roving-focus"]
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

    // Warn rather than throw: the app still works, this one component will not. A hard
    // boot failure over an unused component would be worse than the bug it prevents.
    console.warn(
      `[crosswire] ${identifier} composes with ${missing.join(", ")}, which ${missing.length === 1 ? "is" : "are"} not registered. ` +
        `${identifier} will not function. See R5a in docs/COMPONENT_CONTRACT.md.`
    )
  }
}

export {
  ActivateController,
  AutogrowController,
  AutosubmitController,
  CharCountController,
  ClickOutsideController,
  ClipboardController,
  ConfirmController,
  CountdownController,
  DialogController,
  DirtyFormController,
  DisclosureController,
  DismissController,
  FocusTrapController,
  HotkeyController,
  IntersectionController,
  IntervalController,
  PersistController,
  PopoverController,
  PreserveController,
  RelativeTimeController,
  RevealController,
  RovingFocusController,
  ScrollLockController,
  SelectionController,
  SortableController,
  SyncController,
  TabsController,
  TimeoutController,
  TransitionController
}
