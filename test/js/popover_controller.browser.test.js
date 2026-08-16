import { describe, expect, test } from "vitest"
import PopoverController from "../../app/assets/javascripts/crosswire/controllers/popover_controller.js"
import { mount } from "./setup.js"

// Browser tier (docs/COMPONENT_CONTRACT.md: "Browser mode for anything touching …
// positioning — jsdom cannot test those honestly; jsdom has no layout;
// offsetParent is unconditionally null"). The same limit applies to
// getBoundingClientRect: jsdom returns an all-zero DOMRect for every element,
// real or not, because it implements no layout engine at all — so the JS
// fallback positioner's actual placement math (`popover_controller.js`'s
// `#position()`) is honestly untestable there. `popover_controller.test.js`
// covers everything that doesn't need real layout: event wiring, show/hide/toggle
// delegation, and listener add/remove on open/close.
//
// Run with `npm run test:browser` after `npx playwright install chromium` — wired up
// in vitest.browser.config.js.
//
// This file originally hand-rolled `Application.start()`/`register()` and dispatched
// the `toggle` event in the same synchronous tick, before Stimulus's MutationObserver
// had actually connected the controller — so `toggled()` was never bound and
// `#position()` never ran, leaving the panel at its default (0,0) top-layer position.
// That's the connect-tick gotcha documented in docs/COMPONENT_CONTRACT.md's
// "Test-environment gotchas" table. Fixed by using the shared `mount()` helper from
// setup.js, which awaits a tick after registering, and by relying on setup.js's own
// afterEach for teardown — same idiom as dialog_controller.browser.test.js and
// focus_trap_controller.browser.test.js.
//
// Which placement path is actually live matters here: `CSS.supports("anchor-name",
// "--cw-x")` is `true` in the Chromium this suite runs against (verified directly —
// anchor positioning shipped by default well before the pinned Playwright/Chromium
// version), so on this engine the controller's default `strategy: "anchor"` takes the
// native CSS-anchor-positioning path and `#position()` (the JS fallback math this file
// exists to test) never runs at all. Every markup below sets
// `data-cw--popover-strategy-value="js"` explicitly, which forces `#usesFallback()` to
// return `true` regardless of anchor support — so these tests do exercise the JS
// fallback's real geometry, on purpose, rather than accidentally asserting on a code
// path this browser would never actually take.

function toggleEvent(newState) {
  const event = new Event("toggle")
  event.newState = newState
  return event
}

function markup(placement) {
  return `
    <div style="position: absolute; top: 100px; left: 100px; width: 50px; height: 20px;">
      <button id="trigger" popovertarget="panel" style="width: 50px; height: 20px;">Open</button>
    </div>
    <div id="panel"
         popover="auto"
         style="width: 80px; height: 30px; margin: 0;"
         data-controller="cw--popover"
         data-cw--popover-anchor-value="trigger"
         data-cw--popover-strategy-value="js"
         data-cw--popover-offset-value="8"
         ${placement ? `data-cw--popover-placement-value="${placement}"` : ""}
         data-action="toggle->cw--popover#toggled">Panel content</div>`
}

describe("cw--popover (real browser layout)", () => {
  test("bottom-start places the panel below and left-aligned with the trigger, offset by the gap", async () => {
    await mount(markup("bottom-start"), { "cw--popover": PopoverController })
    const trigger = document.getElementById("trigger")
    const panel = document.getElementById("panel")

    // showPopover() is required for the panel to participate in real layout / the
    // top layer at all; the controller's own #position() runs off the `toggle`
    // event regardless of how the popover was opened.
    panel.showPopover?.()
    panel.dispatchEvent(toggleEvent("open"))

    const triggerRect = trigger.getBoundingClientRect()
    const panelRect = panel.getBoundingClientRect()

    expect(panelRect.top).toBeCloseTo(triggerRect.bottom + 8, 0)
    expect(panelRect.left).toBeCloseTo(triggerRect.left, 0)
  })

  test("top-end places the panel above and right-aligned with the trigger", async () => {
    await mount(markup("top-end"), { "cw--popover": PopoverController })
    const trigger = document.getElementById("trigger")
    const panel = document.getElementById("panel")

    panel.showPopover?.()
    panel.dispatchEvent(toggleEvent("open"))

    const triggerRect = trigger.getBoundingClientRect()
    const panelRect = panel.getBoundingClientRect()

    expect(panelRect.top).toBeCloseTo(triggerRect.top - panelRect.height - 8, 0)
    expect(panelRect.left).toBeCloseTo(triggerRect.right - panelRect.width, 0)
  })

  test("repositions on window resize while the JS fallback is active", async () => {
    await mount(markup("bottom-start"), { "cw--popover": PopoverController })
    const trigger = document.getElementById("trigger")
    const panel = document.getElementById("panel")

    panel.showPopover?.()
    panel.dispatchEvent(toggleEvent("open"))

    trigger.parentElement.style.top = "300px"
    window.dispatchEvent(new Event("resize"))

    const triggerRect = trigger.getBoundingClientRect()
    const panelRect = panel.getBoundingClientRect()
    expect(panelRect.top).toBeCloseTo(triggerRect.bottom + 8, 0)
  })
})
