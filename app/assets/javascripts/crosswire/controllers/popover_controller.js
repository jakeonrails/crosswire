import { Controller } from "@hotwired/stimulus"

// Small placement table for the JS fallback positioner. Deliberately not a
// general-purpose positioning engine — see the class docstring below for why this
// stays a short lookup rather than a Floating UI integration.
const PLACEMENTS = {
  "bottom-start": (t, p, offset) => ({ top: t.bottom + offset, left: t.left }),
  "bottom-end": (t, p, offset) => ({ top: t.bottom + offset, left: t.right - p.width }),
  "top-start": (t, p, offset) => ({ top: t.top - p.height - offset, left: t.left }),
  "top-end": (t, p, offset) => ({ top: t.top - p.height - offset, left: t.right - p.width }),
  "right-start": (t, p, offset) => ({ top: t.top, left: t.right + offset }),
  "left-start": (t, p, offset) => ({ top: t.top, left: t.left - p.width - offset })
}

/**
 * cw--popover — enhance a native `popovertarget`/`popover="auto"` pair with
 * placement-fallback positioning and programmatic control.
 *
 * See Crosswire::Presenters::Popover for Rule 0: native `popovertarget` + CSS
 * anchor positioning already covers light-dismiss, Escape, top-layer stacking and
 * placement with zero JavaScript on engines that support anchor positioning. This
 * controller ONLY adds what that combination doesn't cover everywhere yet.
 *
 * Targets  none — lives entirely on the popover panel element; the trigger needs
 *          no Stimulus wiring at all (native `popovertarget` handles it).
 * Values   placement (String, default "bottom-start"), offset (Number, default 8),
 *          strategy (String: "anchor" default | "js"), anchor (String — the
 *          trigger's id, written by the presenter; internal wiring, not
 *          something a caller typically sets directly)
 * Events   cw--popover:shown, cw--popover:hidden
 *
 * STATE LIVES IN THE BROWSER, NOT A STIMULUS VALUE. Unlike `disclosure`/`dialog`,
 * this controller tracks no `open` value of its own — the native popover's open/
 * closed state IS the single source of truth (R4's spirit applied to a
 * platform-owned value instead of a Stimulus one), and `toggled()` below only
 * ever reacts to the browser's own `toggle` event, never writes state itself. That
 * also means there is no R4a phantom-event risk here: a popover cannot start
 * "open" from server-rendered markup (there is no such attribute in the API), so
 * `toggled()` firing is always a real, user- or script-initiated transition, never
 * spurious hydration.
 *
 * NO FLOATING UI DEPENDENCY. Floating UI is excellent and, per
 * research/notes/18-platform-primitives.md, has roughly 372M downloads/month — but
 * it ships no Stimulus wrapper, and pulling in a general-purpose positioning
 * engine as this primitive's only JS fallback path would make the common case (a
 * browser that DOES support anchor positioning, where this controller does almost
 * nothing) pay for a dependency it never uses. A future `cw--anchor` primitive
 * wrapping Floating UI is a deliberate option for callers who need real collision
 * detection, flip/shift middleware, or virtual elements — a decision left for
 * when a real use case asks for it, not built speculatively into v1. What ships
 * here instead is a small, honestly-limited placement table (six named
 * placements, no collision detection, no auto-flip) — good enough for the
 * fallback case, not a promise to be Floating UI.
 */
export default class PopoverController extends Controller {
  static values = {
    placement: { type: String, default: "bottom-start" },
    offset: { type: Number, default: 8 },
    strategy: { type: String, default: "anchor" },
    anchor: String
  }

  #anchorSupported = false
  #reposition = () => this.#position()

  connect() {
    this.#anchorSupported =
      typeof CSS !== "undefined" && typeof CSS.supports === "function" && CSS.supports("anchor-name", "--cw-x")
  }

  // R7 — the only resources this controller ever acquires outside Stimulus's own
  // action binding are the window listeners added while positioning manually;
  // removeEventListener is a no-op if they were never added, so this is safe to
  // call unconditionally rather than tracking whether positioning is active.
  disconnect() {
    window.removeEventListener("resize", this.#reposition)
    window.removeEventListener("scroll", this.#reposition, true)
  }

  // Native `toggle` (ToggleEvent) — the single source of truth for open/closed
  // state, however it changed: a popovertarget click, Escape, light-dismiss, or a
  // programmatic call to show()/hide()/toggle() below.
  toggled(event) {
    const opened = event.newState === "open"

    if (opened) {
      this.#position()

      if (this.#usesFallback()) {
        window.addEventListener("resize", this.#reposition)
        window.addEventListener("scroll", this.#reposition, true)
      }
    } else {
      window.removeEventListener("resize", this.#reposition)
      window.removeEventListener("scroll", this.#reposition, true)
    }

    this.dispatch(opened ? "shown" : "hidden")
  }

  // Public API for programmatic control — the second half of Rule 0's "when you
  // need the controller" list. Each delegates straight to the native method; this
  // controller adds no state of its own that could desync from it. Optional
  // chaining guards environments (or very old browsers) with no Popover API at
  // all, rather than throwing.
  show() {
    this.element.showPopover?.()
  }

  hide() {
    this.element.hidePopover?.()
  }

  toggle() {
    this.element.togglePopover?.()
  }

  #usesFallback() {
    return !this.#anchorSupported || this.strategyValue === "js"
  }

  #position() {
    if (!this.#usesFallback()) return // CSS anchor positioning already placed it
    if (!this.hasAnchorValue) return

    const trigger = document.getElementById(this.anchorValue)
    if (!trigger) return

    const compute = PLACEMENTS[this.placementValue] || PLACEMENTS["bottom-start"]
    const { top, left } = compute(trigger.getBoundingClientRect(), this.element.getBoundingClientRect(), this.offsetValue)

    this.element.style.position = "fixed"
    this.element.style.top = `${Math.max(0, top)}px`
    this.element.style.left = `${Math.max(0, left)}px`
  }
}
