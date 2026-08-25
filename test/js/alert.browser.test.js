import { Application } from "@hotwired/stimulus"
import { morphElements } from "@hotwired/turbo"
import { afterEach, describe, expect, test } from "vitest"
import DismissController from "../../app/assets/javascripts/crosswire/controllers/dismiss_controller.js"
import { nextFrame } from "./setup.js"

// Browser tier (docs/COMPONENT_CONTRACT.md: "Browser mode for anything touching
// focus... or positioning"), required here for the reason ui_contract_audit_test.rb
// check 10 requires it: `Crosswire::UI::Alert` ships a non-Safe Morph verdict
// (Server-owned) — see that presenter's own docstring, "the flash-message trap".
//
// This file does not prove a FIX — there isn't one at this layer, and the presenter's
// docstring says so plainly. It DEMONSTRATES the trap: a client-side dismiss (a real
// `cw--dismiss` controller, removing a real node) followed by a real
// `@hotwired/turbo` `morphElements()` call whose incoming HTML still contains the
// same alert (exactly what the server sends when nothing told it the alert was
// dismissed) brings the alert BACK. That resurrection is the entire point of the
// Server-owned verdict, and the entire reason its "the app must" clause exists.
//
// Run with `npm run test:browser` after `npx playwright install chromium` — see
// vitest.browser.config.js.

let application

afterEach(async () => {
  document.body.innerHTML = ""
  await new Promise((resolve) => setTimeout(resolve, 0))
  application?.stop()
  application = undefined
})

// Mirrors exactly what app/views/crosswire/ui/_alert.html.erb renders for
// `cw.alert "Only 2 left in stock.", severity: :warning, dismissible: true` — see
// that partial and Crosswire::UI::Alert#root_attrs/#dismiss_trigger_attrs.
function alertMarkup() {
  return `
    <div id="low-stock-alert" class="cw-alert cw-alert--warning" role="alert"
         data-controller="cw--dismiss" data-cw--dismiss-remove-value="true">
      <div class="cw-alert__body">Only 2 left in stock.</div>
      <button type="button" class="cw-alert__dismiss" aria-label="Dismiss"
              data-action="click->cw--dismiss#dismiss"><span aria-hidden="true">&times;</span></button>
    </div>`
}

function boot() {
  document.body.innerHTML = `<div id="flash-container">${alertMarkup()}</div>`
  application = Application.start()
  application.register("cw--dismiss", DismissController)
  return document.getElementById("flash-container")
}

// What the server's NEXT response renders for this same container — the incoming
// HTML for the morph. Byte-identical to the original, because nothing server-side
// was ever told the alert was dismissed; that is exactly the failure mode this file
// demonstrates, not a bug in the markup construction here.
function incomingContainer() {
  const incoming = document.createElement("div")
  incoming.id = "flash-container"
  incoming.innerHTML = alertMarkup()
  return incoming
}

describe("Crosswire::UI::Alert — Morph: Server-owned (the flash-message trap, demonstrated)", () => {
  test("dismiss genuinely removes the alert client-side, on its own", async () => {
    boot()
    await nextFrame()

    document.querySelector(".cw-alert__dismiss").click()

    expect(document.getElementById("low-stock-alert")).toBeNull()
  })

  test("a morph resurrects a client-dismissed alert when the server still renders it", async () => {
    const container = boot()
    await nextFrame()

    document.querySelector(".cw-alert__dismiss").click()
    expect(document.getElementById("low-stock-alert")).toBeNull() // genuinely gone

    // The trap: a background morph (a redirect-after-submit, a periodic page
    // refresh, `broadcasts_refreshes`) whose HTML still includes the alert, because
    // the server was never told the user dismissed it — there is no
    // `dismissed`/`open` Stimulus VALUE here for idiomorph to have preserved, the way
    // there would be for a Preserved-verdict component; dismissal was a bare DOM
    // removal with no server-visible trace at all.
    morphElements(container, incomingContainer())
    await Promise.resolve()

    const resurrected = document.getElementById("low-stock-alert")
    expect(resurrected).not.toBeNull()
    expect(resurrected.textContent).toContain("Only 2 left in stock.")
  })

  test("an alert the user never dismissed is unaffected by the same morph (control case)", async () => {
    const container = boot()
    await nextFrame()

    morphElements(container, incomingContainer())
    await Promise.resolve()

    expect(document.getElementById("low-stock-alert")).not.toBeNull()
  })

  test("the app-side fix: once the server stops rendering the alert, a morph does not bring it back", async () => {
    const container = boot()
    await nextFrame()

    document.querySelector(".cw-alert__dismiss").click()
    expect(document.getElementById("low-stock-alert")).toBeNull()

    // This is what the presenter's "the app must" clause asks for: the NEXT response
    // genuinely stops rendering the alert (a consumed flash, an acknowledged notice) —
    // the incoming HTML for this morph simply has nothing where the alert used to be.
    const incoming = document.createElement("div")
    incoming.id = "flash-container"

    morphElements(container, incoming)
    await Promise.resolve()

    expect(document.getElementById("low-stock-alert")).toBeNull()
  })
})
