import { Application } from "@hotwired/stimulus"
import { morphElements } from "@hotwired/turbo"
import { afterEach, describe, expect, test } from "vitest"
import PreserveController from "../../app/assets/javascripts/crosswire/controllers/preserve_controller.js"
import { nextFrame } from "./setup.js"

// Browser tier (docs/COMPONENT_CONTRACT.md). The jsdom suite (preserve_controller.test.js)
// covers the event contract with synthetic CustomEvents; this file drives the SAME
// scenarios through a real @hotwired/turbo morphElements() call, which is what the
// spec calls the authoritative tier for morph fidelity.

let application

afterEach(async () => {
  document.body.innerHTML = ""
  await new Promise((resolve) => setTimeout(resolve, 0))
  application?.stop()
  application = undefined
})

function boot(markup) {
  document.body.innerHTML = markup
  application = Application.start()
  application.register("cw--preserve", PreserveController)
  return document.body.firstElementChild
}

describe("cw--preserve — real morph, protecting an element you do not own the controller for", () => {
  test("protects a raw attribute a third-party (non-Stimulus) script wrote at runtime", async () => {
    const el = boot(
      `<div id="widget" data-controller="cw--preserve"
            data-cw--preserve-attributes-value="aria-expanded"
            aria-expanded="false"></div>`
    )
    await nextFrame()

    // Simulates the Evil Martians case this surface is modelled on: code crosswire
    // does not own writing its own attribute directly, no Stimulus value involved.
    el.setAttribute("aria-expanded", "true")

    const stale = document.createElement("div")
    stale.id = "widget"
    stale.setAttribute("data-controller", "cw--preserve")
    stale.setAttribute("data-cw--preserve-attributes-value", "aria-expanded")
    stale.setAttribute("aria-expanded", "false") // the server's stale truth

    morphElements(el, stale)

    expect(el.getAttribute("aria-expanded")).toBe("true")
  })

  test("an attribute nothing has touched since connect() is still the server's to update", async () => {
    const el = boot(
      `<div id="widget" data-controller="cw--preserve"
            data-cw--preserve-attributes-value="aria-expanded"
            aria-expanded="false"></div>`
    )
    await nextFrame()

    const fresh = document.createElement("div")
    fresh.id = "widget"
    fresh.setAttribute("data-controller", "cw--preserve")
    fresh.setAttribute("data-cw--preserve-attributes-value", "aria-expanded")
    fresh.setAttribute("aria-expanded", "true") // a legitimate server-driven change

    morphElements(el, fresh)

    expect(el.getAttribute("aria-expanded")).toBe("true")
  })

  test("elementValue: true keeps the whole subtree — including third-party-injected children — intact through a real morph", async () => {
    const el = boot(
      `<div id="widget" data-controller="cw--preserve" data-cw--preserve-element-value="true"></div>`
    )
    await nextFrame()

    // A third-party library mounting its own DOM, same shape as the injected-widget
    // scenario in morph.browser.test.js — but here nothing in crosswire owns the
    // controller that did the mounting; cw--preserve is stacked on afterwards purely
    // to protect it.
    el.innerHTML = "<span class='injected'>mounted by something else</span>"

    const incoming = document.createElement("div")
    incoming.id = "widget"
    incoming.setAttribute("data-controller", "cw--preserve")
    incoming.setAttribute("data-cw--preserve-element-value", "true")
    // Server HTML has no idea the widget exists — an ordinary morph would delete it.

    morphElements(el, incoming)

    expect(el.querySelector(".injected")).not.toBeNull()
  })

  test("without cw--preserve stacked, the same scenario really would be clobbered — proving the fixture is honest", async () => {
    document.body.innerHTML = `<div id="widget"></div>`
    const el = document.getElementById("widget")
    el.setAttribute("aria-expanded", "true")

    const stale = document.createElement("div")
    stale.id = "widget"
    stale.setAttribute("aria-expanded", "false")

    morphElements(el, stale)

    expect(el.getAttribute("aria-expanded")).toBe("false")
  })
})
