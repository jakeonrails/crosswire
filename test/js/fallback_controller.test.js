import { describe, expect, test } from "vitest"
import FallbackController from "../../app/assets/javascripts/crosswire/controllers/fallback_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

// jsdom tier — event-contract tests, same rationale as loading_controller.test.js: the
// synthetic events below match the shape @hotwired/turbo's own dispatch() produces.
// The stream-connection watching (MutationObserver on a plain `connected` attribute) is
// honestly testable here too — it is plain DOM, no ActionCable/turbo-rails involved.
// What this file does NOT claim: that real Turbo actually fires these events with these
// names against a real <turbo-frame>/fetch — that is fallback_controller.browser.test.js.

const CONTROLLERS = { "cw--fallback": FallbackController }

const ACTIONS = [
  "turbo:before-fetch-request->cw--fallback#pending",
  "turbo:before-fetch-response->cw--fallback#check",
  "turbo:fetch-request-error->cw--fallback#fail",
  "turbo:frame-missing->cw--fallback#fail"
].join(" ")

function markup({ state = null, failedClass = null, withSource = false } = {}) {
  return `
    <div data-controller="cw--fallback"
         ${state !== null ? `data-cw--fallback-state-value="${state}"` : ""}
         ${failedClass !== null ? `data-cw--fallback-failed-class="${failedClass}"` : ""}
         data-action="${ACTIONS}">
      <p data-cw--fallback-target="loading">Loading…</p>
      <p data-cw--fallback-target="failed">Failed. <button type="button" data-action="click->cw--fallback#retry">Retry</button></p>
      <turbo-frame id="the-frame"></turbo-frame>
      ${withSource ? '<div data-cw--fallback-target="source"></div>' : ""}
    </div>`
}

function beforeFetchRequest(target) {
  target.dispatchEvent(new CustomEvent("turbo:before-fetch-request", {
    bubbles: true, cancelable: true, detail: { fetchOptions: {}, url: "http://example.com/" }
  }))
}

function beforeFetchResponse(target, succeeded) {
  target.dispatchEvent(new CustomEvent("turbo:before-fetch-response", {
    bubbles: true, cancelable: true, detail: { fetchResponse: { succeeded } }
  }))
}

function fetchRequestError(target) {
  const event = new CustomEvent("turbo:fetch-request-error", { bubbles: true, cancelable: true, detail: {} })
  target.dispatchEvent(event)
  return event
}

function frameMissing(target) {
  const event = new CustomEvent("turbo:frame-missing", {
    bubbles: true, cancelable: true, detail: { response: {}, visit: () => {} }
  })
  target.dispatchEvent(event)
  return event
}

describe("cw--fallback", () => {
  // --- rendering the current state -----------------------------------------------------

  test("defaults to \"ok\" — both loading and failed targets hidden", async () => {
    const el = await mount(markup(), CONTROLLERS)

    expect(el.querySelector('[data-cw--fallback-target="loading"]').hidden).toBe(true)
    expect(el.querySelector('[data-cw--fallback-target="failed"]').hidden).toBe(true)
  })

  test("server-rendered state: \"loading\" shows the loading target before any event fires (R4)", async () => {
    const el = await mount(markup({ state: "loading" }), CONTROLLERS)

    expect(el.querySelector('[data-cw--fallback-target="loading"]').hidden).toBe(false)
    expect(el.querySelector('[data-cw--fallback-target="failed"]').hidden).toBe(true)
  })

  // --- pending / check / fail transitions -------------------------------------------------

  test("pending (turbo:before-fetch-request) moves to loading", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchRequest(frame)
    await nextFrame()

    expect(el.querySelector('[data-cw--fallback-target="loading"]').hidden).toBe(false)
  })

  test("check (turbo:before-fetch-response) moves to failed unless the response succeeded", async () => {
    const el = await mount(markup({ state: "loading" }), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchResponse(frame, false)
    await nextFrame()

    expect(el.querySelector('[data-cw--fallback-target="failed"]').hidden).toBe(false)
  })

  test("check (turbo:before-fetch-response) moves to ok when the response succeeded", async () => {
    const el = await mount(markup({ state: "loading" }), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchResponse(frame, true)
    await nextFrame()

    expect(el.querySelector('[data-cw--fallback-target="loading"]').hidden).toBe(true)
    expect(el.querySelector('[data-cw--fallback-target="failed"]').hidden).toBe(true)
  })

  test("fail (turbo:fetch-request-error) moves to failed and cancels the event", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    const event = fetchRequestError(frame)
    await nextFrame()

    expect(event.defaultPrevented).toBe(true)
    expect(el.querySelector('[data-cw--fallback-target="failed"]').hidden).toBe(false)
  })

  test("fail (turbo:frame-missing) moves to failed and cancels Turbo's default full-page visit", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    const event = frameMissing(frame)
    await nextFrame()

    expect(event.defaultPrevented).toBe(true)
    expect(el.querySelector('[data-cw--fallback-target="failed"]').hidden).toBe(false)
  })

  // --- retry ---------------------------------------------------------------------------------

  test("retry() hides the failed UI and calls reload() on a contained <turbo-frame>", async () => {
    const el = await mount(markup({ state: "failed" }), CONTROLLERS)
    const frame = el.querySelector("#the-frame")
    let reloaded = false
    frame.reload = () => { reloaded = true }

    el.querySelector('[data-cw--fallback-target="failed"] button').click()
    await nextFrame()

    expect(el.querySelector('[data-cw--fallback-target="failed"]').hidden).toBe(true)
    expect(el.querySelector('[data-cw--fallback-target="loading"]').hidden).toBe(false)
    expect(reloaded).toBe(true)
  })

  // --- events, guarded by #ready (R4a) --------------------------------------------------------

  test("dispatches cw--fallback:failed entering the failed state, not on initial connect", async () => {
    const failed = captureEvents("cw--fallback:failed")
    const el = await mount(markup({ state: "failed" }), CONTROLLERS) // server-rendered failed
    expect(failed).toHaveLength(0) // R4a — no phantom event on connect

    const frame = el.querySelector("#the-frame")
    beforeFetchRequest(frame) // failed -> loading
    await nextFrame()
    beforeFetchResponse(frame, false) // loading -> failed, a REAL transition
    await nextFrame()

    expect(failed).toHaveLength(1)
    expect(failed[0].detail.state).toBe("failed")
  })

  test("dispatches cw--fallback:recovered specifically on the failed -> ok transition", async () => {
    const recovered = captureEvents("cw--fallback:recovered")
    const el = await mount(markup({ state: "failed" }), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchRequest(frame) // failed -> loading: not a recovery yet
    await nextFrame()
    expect(recovered).toHaveLength(0)

    beforeFetchResponse(frame, true) // loading -> ok
    await nextFrame()
    expect(recovered).toHaveLength(1)
    expect(recovered[0].detail.state).toBe("ok")
  })

  test("does not dispatch recovered for an ordinary ok -> loading -> ok cycle (never failed)", async () => {
    const recovered = captureEvents("cw--fallback:recovered")
    const el = await mount(markup(), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchRequest(frame)
    await nextFrame()
    beforeFetchResponse(frame, true)
    await nextFrame()

    expect(recovered).toHaveLength(0)
  })

  // --- the optional failed class, guarded per R3 ------------------------------------------------

  test("applies the failed class to the root element while failed", async () => {
    const el = await mount(markup({ failedClass: "is-failed" }), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchRequest(frame)
    await nextFrame()
    beforeFetchResponse(frame, false)
    await nextFrame()
    expect(el.classList.contains("is-failed")).toBe(true)

    beforeFetchResponse(frame, true)
    await nextFrame()
    expect(el.classList.contains("is-failed")).toBe(false)
  })

  test("does not throw when no failed class is configured (R3 — hasFailedClass guard)", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchRequest(frame)
    beforeFetchResponse(frame, false)
    await expect(nextFrame()).resolves.toBeUndefined()
  })

  // --- stream-connection watching ------------------------------------------------------------

  test("losing the connected attribute on the source target fails with reason: stream-disconnected", async () => {
    const failed = captureEvents("cw--fallback:failed")
    const el = await mount(markup({ withSource: true }), CONTROLLERS)
    const source = el.querySelector('[data-cw--fallback-target="source"]')

    source.setAttribute("connected", "")
    await nextFrame()
    source.removeAttribute("connected")
    await nextFrame()

    expect(el.querySelector('[data-cw--fallback-target="failed"]').hidden).toBe(false)
    expect(failed).toHaveLength(1)
    expect(failed[0].detail.reason).toBe("stream-disconnected")
  })

  test("regaining the connected attribute recovers to ok", async () => {
    const recovered = captureEvents("cw--fallback:recovered")
    const el = await mount(markup({ withSource: true }), CONTROLLERS)
    const source = el.querySelector('[data-cw--fallback-target="source"]')

    source.setAttribute("connected", "")
    await nextFrame()
    source.removeAttribute("connected")
    await nextFrame()
    source.setAttribute("connected", "")
    await nextFrame()

    expect(el.querySelector('[data-cw--fallback-target="failed"]').hidden).toBe(true)
    expect(recovered).toHaveLength(1)
  })

  // --- R7: exhaustive teardown -----------------------------------------------------------------

  test("disconnect() tears down the stream MutationObserver — a later attribute change has no effect", async () => {
    const failed = captureEvents("cw--fallback:failed")
    const el = await mount(markup({ withSource: true }), CONTROLLERS)
    const source = el.querySelector('[data-cw--fallback-target="source"]')
    source.setAttribute("connected", "")
    await nextFrame()

    document.body.innerHTML = ""
    await nextFrame()

    source.removeAttribute("connected")
    await nextFrame()

    expect(failed).toHaveLength(0)
  })
})
