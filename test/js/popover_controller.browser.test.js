import { describe, expect, test } from "vitest"
import { Application } from "@hotwired/stimulus"
import PopoverController from "../../app/assets/javascripts/crosswire/controllers/popover_controller.js"

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
// Run with `npm run test:browser` after `npx playwright install chromium`. As of
// this writing vitest.config.js does not yet define the `browser` project the
// package.json script points at — wiring that up is tracked separately, same as
// every other crosswire controller's browser tier (see
// intersection_controller.browser.test.js and dialog_controller.browser.test.js).
// The assertions below are written against real browser APIs (real layout, a
// real getBoundingClientRect) so they are correct the day that project exists.

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

function start(html) {
  document.body.innerHTML = html
  const application = Application.start()
  application.register("cw--popover", PopoverController)
  return application
}

function stop(application) {
  application.stop()
  document.body.innerHTML = ""
}

describe("cw--popover (real browser layout)", () => {
  test("bottom-start places the panel below and left-aligned with the trigger, offset by the gap", () => {
    const application = start(markup("bottom-start"))
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

    stop(application)
  })

  test("top-end places the panel above and right-aligned with the trigger", () => {
    const application = start(markup("top-end"))
    const trigger = document.getElementById("trigger")
    const panel = document.getElementById("panel")

    panel.showPopover?.()
    panel.dispatchEvent(toggleEvent("open"))

    const triggerRect = trigger.getBoundingClientRect()
    const panelRect = panel.getBoundingClientRect()

    expect(panelRect.top).toBeCloseTo(triggerRect.top - panelRect.height - 8, 0)
    expect(panelRect.left).toBeCloseTo(triggerRect.right - panelRect.width, 0)

    stop(application)
  })

  test("repositions on window resize while the JS fallback is active", () => {
    const application = start(markup("bottom-start"))
    const trigger = document.getElementById("trigger")
    const panel = document.getElementById("panel")

    panel.showPopover?.()
    panel.dispatchEvent(toggleEvent("open"))

    trigger.parentElement.style.top = "300px"
    window.dispatchEvent(new Event("resize"))

    const triggerRect = trigger.getBoundingClientRect()
    const panelRect = panel.getBoundingClientRect()
    expect(panelRect.top).toBeCloseTo(triggerRect.bottom + 8, 0)

    stop(application)
  })
})
