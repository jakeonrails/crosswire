import { describe, expect, test } from "vitest"
import ActivateController from "../../app/assets/javascripts/crosswire/controllers/activate_controller.js"
import { mount } from "./setup.js"

const CONTROLLERS = { "cw--activate": ActivateController }

// Every test triggers `activate()` via a custom event, `cw-test:go`, rather than
// binding it to `click` itself — the realistic composition (an intersection sentinel,
// a timeout elapsing, a hotkey) always fires `activate()` from a DIFFERENT event type
// than the click it produces. Wiring `click->cw--activate#activate` on the very element
// `activate()` clicks (itself, by default, or — via bubbling — a descendant) would
// recurse forever: the synthetic click it dispatches would re-trigger the same
// click-bound action. That is a real footgun worth avoiding in the docs/examples, not
// something worth testing as if it were supported usage.
function trigger(el) {
  el.dispatchEvent(new CustomEvent("cw-test:go", { bubbles: true }))
}

function markup({ target = null, onConnect = null, extra = "" } = {}) {
  return `
    <div data-controller="cw--activate"
         ${target !== null ? `data-cw--activate-target-value="${target}"` : ""}
         ${onConnect !== null ? `data-cw--activate-on-connect-value="${onConnect}"` : ""}
         data-action="cw-test:go->cw--activate#activate">
      ${extra}
    </div>`
}

describe("cw--activate", () => {
  test("activate() clicks its own element by default", async () => {
    const el = await mount(markup(), CONTROLLERS)
    let clicked = null
    el.addEventListener("click", (event) => { clicked = event })

    trigger(el)

    expect(clicked).not.toBeNull()
  })

  test("activate() clicks a descendant named by target, not its own element", async () => {
    const el = await mount(
      markup({ target: "#real-link", extra: '<a id="real-link" href="/next">Load more</a>' }),
      CONTROLLERS
    )
    const link = el.querySelector("#real-link")
    let ownWasClickTarget = false
    let linkClicked = false
    el.addEventListener("click", (event) => { if (event.target === el) ownWasClickTarget = true })
    link.addEventListener("click", (event) => {
      linkClicked = true
      event.preventDefault() // don't actually navigate jsdom
    })

    trigger(el)

    expect(linkClicked).toBe(true)
    expect(ownWasClickTarget).toBe(false)
  })

  test("the synthetic click carries isTrusted: false and detail: 0", async () => {
    const el = await mount(
      markup({ target: "#real-link", extra: '<a id="real-link" href="/next">Load more</a>' }),
      CONTROLLERS
    )
    const link = el.querySelector("#real-link")
    let seen = null
    link.addEventListener("click", (event) => {
      event.preventDefault()
      seen = event
    })

    trigger(el)

    expect(seen.isTrusted).toBe(false)
    expect(seen.detail).toBe(0)
  })

  test("onConnect fires activate() once immediately on connect", async () => {
    const extra = '<a id="real-link" href="/next">Load more</a>'
    let clicked = false
    document.addEventListener("click", (event) => {
      if (event.target.id === "real-link") {
        event.preventDefault() // don't actually navigate jsdom
        clicked = true
      }
    })

    await mount(markup({ target: "#real-link", onConnect: true, extra }), CONTROLLERS)

    expect(clicked).toBe(true)
  })

  test("does not fire on connect by default", async () => {
    const extra = '<a id="real-link" href="/next">Load more</a>'
    let clicked = false
    document.addEventListener("click", (event) => {
      if (event.target.id === "real-link") {
        event.preventDefault() // don't actually navigate jsdom
        clicked = true
      }
    })

    await mount(markup({ target: "#real-link", extra }), CONTROLLERS)

    expect(clicked).toBe(false)
  })

  // --- guard against activating a disabled control -----------------------------------

  test("does not click a target with the disabled property set", async () => {
    const el = await mount(
      markup({ target: "#btn", extra: '<button id="btn" disabled>Go</button>' }),
      CONTROLLERS
    )
    const btn = el.querySelector("#btn")
    let clicked = false
    btn.addEventListener("click", () => { clicked = true })

    trigger(el)

    expect(clicked).toBe(false)
  })

  test('does not click a target with aria-disabled="true"', async () => {
    const el = await mount(
      markup({ target: "#link", extra: '<a id="link" href="/x" aria-disabled="true">Go</a>' }),
      CONTROLLERS
    )
    const link = el.querySelector("#link")
    let clicked = false
    link.addEventListener("click", (event) => {
      event.preventDefault()
      clicked = true
    })

    trigger(el)

    expect(clicked).toBe(false)
  })

  // --- target resolution: descendant first, then a document-wide query --------------

  test("falls back to document.querySelector when target is not a descendant", async () => {
    // mount() replaces document.body.innerHTML wholesale, so the sibling element must
    // be inserted AFTER mounting or it would be wiped out before the controller connects.
    const el = await mount(markup({ target: "#outside-link" }), CONTROLLERS)
    document.body.insertAdjacentHTML("beforeend", '<a id="outside-link" href="/y">Outside</a>')
    const outside = document.getElementById("outside-link")
    let clicked = false
    outside.addEventListener("click", (event) => {
      event.preventDefault()
      clicked = true
    })

    trigger(el)

    expect(clicked).toBe(true)
  })

  test("an invalid selector does not throw", async () => {
    const el = await mount(markup({ target: "###not-a-selector" }), CONTROLLERS)

    expect(() => trigger(el)).not.toThrow()
  })
})
