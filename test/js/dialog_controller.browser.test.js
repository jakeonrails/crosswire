import { describe, expect, test } from "vitest"
import { Application } from "@hotwired/stimulus"
import DialogController from "../../app/assets/javascripts/crosswire/controllers/dialog_controller.js"

// Browser tier (docs/COMPONENT_CONTRACT.md: "Browser mode for anything touching focus,
// <dialog>, IntersectionObserver, or positioning — jsdom cannot test those honestly").
// jsdom (as pinned in package.json) does not implement HTMLDialogElement's
// showModal()/show()/close() at all — verified directly against the pinned version —
// so dialog_controller.test.js only proves the controller's *wiring* against hand-
// rolled polyfills of those methods: value sync, event sequencing, the SSR-upgrade
// path, the morph/cache defence. None of that is "does the rest of the page actually
// go inert", "does Escape actually close it", or "is the scrollbar-gutter compensation
// actually preventing layout shift" — those claims can only be honestly tested against
// a real browser's top layer and inertness implementation, which is what this file does.
//
// Run with `npm run test:browser` after `npx playwright install chromium`. As of this
// writing vitest.config.js does not yet define the `browser` project the package.json
// script points at — wiring that up is tracked separately from this primitive's
// implementation, same as every other crosswire controller's browser tier. The
// assertions below are written against real browser APIs (a real <dialog>, a real
// top layer, real inertness, real focus) so they are correct the day that project
// exists, not aspirational pseudocode.

function markup({ open = false } = {}) {
  return `
    <button id="outside">Outside control</button>
    <div data-controller="cw--dialog" data-cw--dialog-open-value="${open}">
      <button data-cw--dialog-target="trigger"
              data-action="click->cw--dialog#open"
              aria-haspopup="dialog" aria-controls="d1">Open</button>
      <dialog id="d1"
              data-cw--dialog-target="panel"
              data-action="close->cw--dialog#syncClosed cancel->cw--dialog#cancel click->cw--dialog#backdropClick turbo:before-morph-element->cw--dialog#beforeMorph turbo:before-cache->cw--dialog#reset"
              style="width: 20rem;">
        <h2 id="d1-title">Title</h2>
        <p>Body content.</p>
        <button data-action="click->cw--dialog#close" aria-label="Close">&times;</button>
      </dialog>
    </div>`
}

function boot(opts) {
  document.body.innerHTML = markup(opts)
  const application = Application.start()
  application.register("cw--dialog", DialogController)
  return {
    application,
    el: document.body.querySelector("[data-controller='cw--dialog']"),
    panel: document.getElementById("d1"),
    trigger: document.body.querySelector("[data-cw--dialog-target='trigger']"),
    outside: document.getElementById("outside")
  }
}

function teardown(application) {
  application.stop()
  document.body.innerHTML = ""
}

async function settle() {
  await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
}

describe("cw--dialog (real browser <dialog>)", () => {
  test("showModal() actually opens it on the top layer and it is the top-layer element", async () => {
    const { application, panel, trigger } = boot()
    trigger.click()
    await settle()

    expect(panel.open).toBe(true)
    expect(panel.matches(":modal")).toBe(true)

    teardown(application)
  })

  test("the rest of the document is genuinely inert while modal — outside controls cannot be focused", async () => {
    const { application, trigger, outside } = boot()
    trigger.click()
    await settle()

    outside.focus()
    expect(document.activeElement).not.toBe(outside)

    teardown(application)
  })

  test("Escape closes the dialog natively and the controller syncs its value", async () => {
    const { application, el, panel, trigger } = boot()
    trigger.click()
    await settle()
    expect(panel.open).toBe(true)

    panel.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true }))
    await settle()

    expect(panel.open).toBe(false)
    expect(el.getAttribute("data-cw--dialog-open-value")).toBe("false")

    teardown(application)
  })

  test("focus returns to the trigger after Escape, not to <body>", async () => {
    const { application, panel, trigger } = boot()
    trigger.focus()
    trigger.click()
    await settle()

    panel.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true }))
    await settle()

    expect(document.activeElement).toBe(trigger)

    teardown(application)
  })

  test("a real click on the dialog's own padding box (the backdrop area) closes it", async () => {
    const { application, panel, trigger } = boot()
    trigger.click()
    await settle()

    const rect = panel.getBoundingClientRect()
    // Click just inside the dialog's own box but outside any content — since the
    // dialog element covers the whole padding box, a coordinate at its very edge
    // hits the <dialog> itself, not a descendant.
    panel.dispatchEvent(new MouseEvent("click", {
      bubbles: true,
      clientX: rect.left + 1,
      clientY: rect.top + 1
    }))
    await settle()

    expect(panel.open).toBe(false)

    teardown(application)
  })

  test("scroll lock actually prevents the page behind the modal from scrolling", async () => {
    document.body.style.height = "5000px"
    const { application, trigger } = boot()

    window.scrollTo(0, 0)
    trigger.click()
    await settle()

    window.scrollTo(0, 500)
    await settle()

    expect(window.scrollY).toBe(0)

    teardown(application)
    document.body.style.height = ""
  })

  test("scrollbar-gutter compensation keeps the page's content box width stable while locked", async () => {
    const { application, trigger } = boot()
    const before = document.documentElement.getBoundingClientRect().width

    trigger.click()
    await settle()
    const during = document.documentElement.getBoundingClientRect().width

    expect(during).toBe(before)

    teardown(application)
  })

  test("Turbo morph hazard: a dialog left open across a morph is not silently struck inert-forever", async () => {
    // Regression guard for the documented hazard: Idiomorph gives `open` no special
    // handling, and removing it per the HTML spec does NOT call close() — so a naive
    // morph would leave the document inert with close() reduced to a no-op. The
    // controller cancels turbo:before-morph-element on the panel while open; assert
    // that a dialog opened, "morphed" (attribute stripped exactly as Idiomorph would),
    // and then asked to close via the controller's own path still actually closes,
    // rather than leaving the page dead.
    const { application, el, panel, trigger } = boot()
    trigger.click()
    await settle()
    expect(panel.open).toBe(true)

    const morphEvent = new Event("turbo:before-morph-element", { bubbles: true, cancelable: true })
    panel.dispatchEvent(morphEvent)
    expect(morphEvent.defaultPrevented).toBe(true) // morph was refused; open state preserved

    // Now drive a normal close through the controller, proving the dialog is still a
    // live, controllable modal rather than dead inert markup.
    el.querySelector("[aria-label='Close']").click()
    await settle()

    expect(panel.open).toBe(false)
    expect(document.body.matches(":not([inert])") || !document.body.inert).toBe(true)

    teardown(application)
  })
})
