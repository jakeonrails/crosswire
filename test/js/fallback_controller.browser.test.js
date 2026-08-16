import { Application } from "@hotwired/stimulus"
import "@hotwired/turbo"
import { afterEach, describe, expect, test } from "vitest"
import FallbackController from "../../app/assets/javascripts/crosswire/controllers/fallback_controller.js"
import { nextFrame } from "./setup.js"

// Browser tier (docs/COMPONENT_CONTRACT.md). The jsdom suite (fallback_controller.test.js)
// covers the event contract with synthetic CustomEvents; this file drives the SAME
// scenarios through REAL @hotwired/turbo — a real <turbo-frame> navigation against a
// real (mocked) 500, a real missing-frame response, and a real network failure — which
// is what pins the event contract against Turbo version drift.
//
// Importing "@hotwired/turbo" registers the real <turbo-frame> custom element and
// starts Drive's observers as a side effect of the import itself (see morph.browser.
// test.js). `window.fetch` is monkey-patched per test (Turbo's own fetchWithTurboHeaders
// calls window.fetch directly, verified by reading it) rather than hitting a real
// network.

let application
const realFetch = window.fetch

afterEach(async () => {
  window.fetch = realFetch
  document.body.innerHTML = ""
  await new Promise((resolve) => setTimeout(resolve, 0))
  application?.stop()
  application = undefined
})

function boot(markup) {
  document.body.innerHTML = markup
  application = Application.start()
  application.register("cw--fallback", FallbackController)
  return document.body.firstElementChild
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

const ACTIONS = [
  "turbo:before-fetch-request->cw--fallback#pending",
  "turbo:before-fetch-response->cw--fallback#check",
  "turbo:fetch-request-error->cw--fallback#fail",
  "turbo:frame-missing->cw--fallback#fail"
].join(" ")

function markup(state = "ok") {
  return `
    <div data-controller="cw--fallback" data-cw--fallback-state-value="${state}" data-action="${ACTIONS}">
      <p data-cw--fallback-target="loading">Loading…</p>
      <p data-cw--fallback-target="failed">Failed <button type="button" id="retry" data-action="click->cw--fallback#retry">Retry</button></p>
      <turbo-frame id="the-frame"></turbo-frame>
    </div>`
}

function response(body, { status = 200 } = {}) {
  return new Response(body, { status, headers: { "Content-Type": "text/html" } })
}

function matchingFrameHtml(id, body = "content") {
  return `<!doctype html><html><body><turbo-frame id="${id}">${body}</turbo-frame></body></html>`
}

// Deliberately NOT a matching <turbo-frame id="the-frame">, so Turbo cannot locate the
// frame in the response body and dispatches turbo:frame-missing.
const NO_MATCHING_FRAME_HTML = `<!doctype html><html><body><turbo-frame id="some-other-frame">nope</turbo-frame></body></html>`

describe("cw--fallback — real Turbo events", () => {
  test("a real 500 (with a matching frame body) moves to failed via turbo:before-fetch-response", async () => {
    window.fetch = () => Promise.resolve(response(matchingFrameHtml("the-frame"), { status: 500 }))

    const el = boot(markup("loading"))
    await nextFrame()

    el.querySelector("turbo-frame").src = "/survivability_demo/fail"
    await wait(150)

    expect(el.querySelector('[data-cw--fallback-target="failed"]').hidden).toBe(false)
    expect(el.querySelector('[data-cw--fallback-target="loading"]').hidden).toBe(true)
  })

  test("a real 200 whose body has no matching frame triggers turbo:frame-missing, and fail() suppresses Turbo's default full-page visit", async () => {
    window.fetch = () => Promise.resolve(response(NO_MATCHING_FRAME_HTML))

    let sawFrameMissing = false
    let visitedAway = false
    document.addEventListener("turbo:frame-missing", (event) => {
      sawFrameMissing = true
      // Turbo's default handling would call the visit() callback in the event detail
      // to navigate the whole page. Wrap it so a real (unwanted) navigation attempt
      // during the test would be caught rather than actually firing.
      const originalVisit = event.detail.visit
      event.detail.visit = (...args) => { visitedAway = true; return originalVisit(...args) }
    })

    const el = boot(markup("loading"))
    await nextFrame()

    el.querySelector("turbo-frame").src = "/survivability_demo/mismatched"
    await wait(150)

    expect(sawFrameMissing).toBe(true)
    expect(visitedAway).toBe(false) // fail()'s preventDefault() stopped Turbo's default visit
    expect(el.querySelector('[data-cw--fallback-target="failed"]').hidden).toBe(false)
  })

  test("a network failure (fetch rejects) moves to failed via turbo:fetch-request-error", async () => {
    // See loading_controller.browser.test.js for the source-verified reason a genuine
    // network failure always produces a benign unhandled rejection inside Turbo
    // itself (FetchRequest#perform() unconditionally re-throws, and its caller here
    // does not await/catch it) — scoped narrowly to this test's own injected message.
    const swallowExpectedRejection = (event) => {
      if (event.reason?.message === "simulated network failure") event.preventDefault()
    }
    window.addEventListener("unhandledrejection", swallowExpectedRejection)

    window.fetch = () => Promise.reject(new TypeError("simulated network failure"))

    const el = boot(markup("loading"))
    await nextFrame()

    el.querySelector("turbo-frame").src = "/survivability_demo/unreachable"
    await wait(150)

    expect(el.querySelector('[data-cw--fallback-target="failed"]').hidden).toBe(false)

    window.removeEventListener("unhandledrejection", swallowExpectedRejection)
  })

  test("retry() reloads a real <turbo-frame>, and a subsequent success recovers to ok (cw--fallback:recovered)", async () => {
    let succeed = false
    window.fetch = () => Promise.resolve(
      succeed ? response(matchingFrameHtml("the-frame", "recovered!")) : response(matchingFrameHtml("the-frame"), { status: 500 })
    )

    const recovered = []
    document.addEventListener("cw--fallback:recovered", (event) => recovered.push(event))

    const el = boot(markup("loading"))
    await nextFrame()

    el.querySelector("turbo-frame").src = "/survivability_demo/flaky"
    await wait(150)
    expect(el.querySelector('[data-cw--fallback-target="failed"]').hidden).toBe(false)

    succeed = true
    document.getElementById("retry").click()
    await wait(150)

    expect(el.querySelector('[data-cw--fallback-target="failed"]').hidden).toBe(true)
    expect(el.querySelector("turbo-frame").textContent).toContain("recovered!")
    expect(recovered).toHaveLength(1)
  })
})
