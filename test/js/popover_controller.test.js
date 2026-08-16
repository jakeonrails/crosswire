import { describe, expect, test, vi } from "vitest"
import { Application } from "@hotwired/stimulus"
import PopoverController from "../../app/assets/javascripts/crosswire/controllers/popover_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--popover": PopoverController }

// jsdom does not implement the Popover API at all (no showPopover/hidePopover/
// togglePopover methods, no real ToggleEvent) — it is very new (MDN: "newly
// available since Jan 2025") and not something jsdom 25 models. So this tier
// stands in for the browser's own `toggle` event with a plain `Event` carrying a
// `newState` property, which is enough to exercise every line of this controller's
// OWN logic (it only ever READS event.newState, and only ever CALLS
// showPopover/hidePopover/togglePopover through `?.()`, never assuming they exist)
// without pretending jsdom actually implements the platform feature. Real
// getBoundingClientRect-based placement math is jsdom-dishonest for the same reason
// focus-trap's offsetParent is — see popover_controller.browser.test.js.
function toggleEvent(newState) {
  const event = new Event("toggle")
  event.newState = newState
  return event
}

function markup({ placement = null, offset = null, strategy = null, anchor = "trigger" } = {}) {
  return `
    <button id="trigger" popovertarget="panel">Open</button>
    <div id="panel"
         popover="auto"
         data-controller="cw--popover"
         data-cw--popover-anchor-value="${anchor}"
         ${placement ? `data-cw--popover-placement-value="${placement}"` : ""}
         ${offset !== null ? `data-cw--popover-offset-value="${offset}"` : ""}
         ${strategy ? `data-cw--popover-strategy-value="${strategy}"` : ""}
         data-action="toggle->cw--popover#toggled">Panel content</div>`
}

// Only the two tests that need to call show()/hide()/toggle() directly on a
// controller instance need the Application object itself; every other test uses
// setup.js's shared `mount`, consistent with the rest of the suite.
function mountWithApplication(html) {
  document.body.innerHTML = html
  const application = Application.start()
  application.register("cw--popover", PopoverController)
  return application
}

describe("cw--popover", () => {
  test("connects without throwing even though the panel has no showPopover in jsdom", async () => {
    await expect(mount(markup(), CONTROLLERS)).resolves.toBeTruthy()
  })

  test("dispatches shown on a toggle event reporting open", async () => {
    const shown = captureEvents("cw--popover:shown")
    await mount(markup(), CONTROLLERS)
    const panel = document.getElementById("panel")

    panel.dispatchEvent(toggleEvent("open"))
    await nextFrame()

    expect(shown).toHaveLength(1)
  })

  test("dispatches hidden on a toggle event reporting closed", async () => {
    const hidden = captureEvents("cw--popover:hidden")
    await mount(markup(), CONTROLLERS)
    const panel = document.getElementById("panel")

    panel.dispatchEvent(toggleEvent("closed"))
    await nextFrame()

    expect(hidden).toHaveLength(1)
  })

  test("show/hide/toggle delegate to native methods when present, and never throw when absent", async () => {
    const application = mountWithApplication(markup())
    await nextFrame()
    const panel = document.getElementById("panel")
    const controller = application.getControllerForElementAndIdentifier(panel, "cw--popover")

    // jsdom has none of these methods — calling the public API must not throw.
    expect(() => controller.show()).not.toThrow()
    expect(() => controller.hide()).not.toThrow()
    expect(() => controller.toggle()).not.toThrow()

    application.stop()
  })

  test("show/hide/toggle call the native method when the platform provides one", async () => {
    const application = mountWithApplication(markup())
    await nextFrame()
    const panel = document.getElementById("panel")
    panel.showPopover = vi.fn()
    panel.hidePopover = vi.fn()
    panel.togglePopover = vi.fn()

    const controller = application.getControllerForElementAndIdentifier(panel, "cw--popover")
    controller.show()
    controller.hide()
    controller.toggle()

    expect(panel.showPopover).toHaveBeenCalledOnce()
    expect(panel.hidePopover).toHaveBeenCalledOnce()
    expect(panel.togglePopover).toHaveBeenCalledOnce()

    application.stop()
  })

  test("missing anchor value never throws when positioning on open", async () => {
    await mount(
      `<div id="panel" popover="auto" data-controller="cw--popover"
            data-action="toggle->cw--popover#toggled">Panel</div>`,
      CONTROLLERS
    )
    const panel = document.getElementById("panel")

    expect(() => panel.dispatchEvent(toggleEvent("open"))).not.toThrow()
  })

  test("falls back to JS positioning and sets fixed styling on open (jsdom has no anchor positioning)", async () => {
    await mount(markup({ strategy: "js" }), CONTROLLERS)
    const panel = document.getElementById("panel")

    panel.dispatchEvent(toggleEvent("open"))
    await nextFrame()

    expect(panel.style.position).toBe("fixed")
  })

  test("adds resize/scroll listeners only while using the JS fallback and open", async () => {
    const addSpy = vi.spyOn(window, "addEventListener")
    await mount(markup({ strategy: "js" }), CONTROLLERS)
    const panel = document.getElementById("panel")

    panel.dispatchEvent(toggleEvent("open"))
    await nextFrame()

    expect(addSpy.mock.calls.some(([type]) => type === "resize")).toBe(true)
    expect(addSpy.mock.calls.some(([type]) => type === "scroll")).toBe(true)

    addSpy.mockRestore()
  })

  test("removes resize/scroll listeners on close", async () => {
    await mount(markup({ strategy: "js" }), CONTROLLERS)
    const panel = document.getElementById("panel")

    panel.dispatchEvent(toggleEvent("open"))
    await nextFrame()

    const removeSpy = vi.spyOn(window, "removeEventListener")
    panel.dispatchEvent(toggleEvent("closed"))
    await nextFrame()

    expect(removeSpy.mock.calls.some(([type]) => type === "resize")).toBe(true)
    expect(removeSpy.mock.calls.some(([type]) => type === "scroll")).toBe(true)

    removeSpy.mockRestore()
  })

  // R7 — disconnect always releases the window listeners, whether or not they were
  // ever added; removeEventListener with a handler that was never registered is a
  // documented no-op, so this must never throw.
  test("disconnect releases window listeners without throwing (R7)", async () => {
    await mount(markup({ strategy: "js" }), CONTROLLERS)
    const panel = document.getElementById("panel")
    panel.dispatchEvent(toggleEvent("open"))
    await nextFrame()

    expect(() => {
      document.body.innerHTML = ""
    }).not.toThrow()
    await nextFrame()
  })
})
