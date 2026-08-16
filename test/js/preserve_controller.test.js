import { describe, expect, test } from "vitest"
import PreserveController from "../../app/assets/javascripts/crosswire/controllers/preserve_controller.js"
import { mount } from "./setup.js"

// jsdom tier — event-contract tests, same rationale as morph.test.js: the events
// dispatched here match the exact shape @hotwired/turbo's own `dispatch()` produces
// (bubbles: true, composed: true, cancelable as applicable, detail). What this file
// does NOT claim to test is a real Idiomorph pass; that lives in
// preserve_controller.browser.test.js.

const CONTROLLERS = { "cw--preserve": PreserveController }

function markup({ attributes = null, element = null } = {}) {
  return `
    <div data-controller="cw--preserve"
         ${attributes !== null ? `data-cw--preserve-attributes-value="${attributes}"` : ""}
         ${element !== null ? `data-cw--preserve-element-value="${element}"` : ""}
         aria-expanded="true" class="is-open">
    </div>`
}

function morphAttribute(target, { attributeName, mutationType = "update" }) {
  const event = new CustomEvent("turbo:before-morph-attribute", {
    bubbles: true,
    composed: true,
    cancelable: true,
    detail: { attributeName, mutationType }
  })
  target.dispatchEvent(event)
  return event
}

function morphElementEvent(target, { newElement = document.createElement("div") } = {}) {
  const event = new CustomEvent("turbo:before-morph-element", {
    bubbles: true,
    composed: true,
    cancelable: true,
    detail: { currentElement: target, newElement }
  })
  target.dispatchEvent(event)
  return event
}

function morphedEvent(target) {
  target.dispatchEvent(new CustomEvent("turbo:morph-element", {
    bubbles: true,
    composed: true,
    detail: { currentElement: target, newElement: document.createElement("div") }
  }))
}

function flushMicrotasks() {
  return new Promise((resolve) => queueMicrotask(resolve))
}

describe("cw--preserve", () => {
  test("cancels a morph of a watched attribute once its live value has diverged", async () => {
    const el = await mount(markup({ attributes: "aria-expanded class" }), CONTROLLERS)

    el.setAttribute("aria-expanded", "false") // "the third-party controller wrote this"
    const event = morphAttribute(el, { attributeName: "aria-expanded", mutationType: "update" })

    expect(event.defaultPrevented).toBe(true)
  })

  test("lets a watched attribute through when it has not diverged since connect()", async () => {
    const el = await mount(markup({ attributes: "aria-expanded class" }), CONTROLLERS)

    const event = morphAttribute(el, { attributeName: "aria-expanded", mutationType: "update" })

    expect(event.defaultPrevented).toBe(false)
  })

  test("ignores attributes not named in attributesValue", async () => {
    const el = await mount(markup({ attributes: "aria-expanded" }), CONTROLLERS)

    el.setAttribute("class", "is-closed")
    const event = morphAttribute(el, { attributeName: "class", mutationType: "update" })

    expect(event.defaultPrevented).toBe(false)
  })

  test("protects nothing when no attributesValue is given and elementValue is false", async () => {
    const el = await mount(markup(), CONTROLLERS)

    el.setAttribute("aria-expanded", "false")
    const event = morphAttribute(el, { attributeName: "aria-expanded", mutationType: "update" })

    expect(event.defaultPrevented).toBe(false)
  })

  test("elementValue true (B6) cancels morphing of the whole element", async () => {
    const el = await mount(markup({ element: true }), CONTROLLERS)

    const event = morphElementEvent(el)

    expect(event.defaultPrevented).toBe(true)
  })

  test("elementValue false (default) does not cancel element-level morphing", async () => {
    const el = await mount(markup({ attributes: "aria-expanded" }), CONTROLLERS)

    const event = morphElementEvent(el)

    expect(event.defaultPrevented).toBe(false)
  })

  test("attributesValue changes at runtime take effect from the next morph pass, not just connect()", async () => {
    const el = await mount(markup({ attributes: "aria-expanded" }), CONTROLLERS)

    // Add "class" to the protected list at runtime, same as a server re-render (or a
    // sibling controller) would. A newly-watched name has no recorded baseline yet, so
    // — per the divergence check's safe default — it is not retroactively protected
    // against changes that already happened; a full morph pass (here, a harmless one
    // that touches nothing the guard cares about) is what syncs its baseline.
    el.setAttribute("data-cw--preserve-attributes-value", "aria-expanded class")
    morphedEvent(el)
    await flushMicrotasks()

    // NOW the guard has a baseline for "class". A subsequent divergence is protected —
    // proof that attributesValue was read fresh rather than cached from connect(),
    // when "class" was not yet in the list at all.
    el.setAttribute("class", "is-closed")
    const event = morphAttribute(el, { attributeName: "class", mutationType: "update" })
    expect(event.defaultPrevented).toBe(true)
  })

  // R7 / teardown — setup.js's afterEach clears the DOM and awaits a tick BEFORE
  // stopping the Application, so Stimulus's own MutationObserver runs disconnect()
  // for real here; this test forces that to happen mid-test to assert the listener is
  // actually gone rather than merely trusting afterEach ran.
  test("disconnect() tears down the guard — a previously-cancelled morph is let through", async () => {
    const el = await mount(markup({ attributes: "aria-expanded" }), CONTROLLERS)

    document.body.innerHTML = ""
    await new Promise((resolve) => setTimeout(resolve, 0)) // let Stimulus's observer fire disconnect()

    el.setAttribute("aria-expanded", "false")
    const event = morphAttribute(el, { attributeName: "aria-expanded", mutationType: "update" })

    expect(event.defaultPrevented).toBe(false)
  })
})
