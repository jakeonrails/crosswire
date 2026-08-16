import { Application } from "@hotwired/stimulus"
import "@hotwired/turbo"
import { afterEach, describe, expect, test } from "vitest"
import LoadingController from "../../app/assets/javascripts/crosswire/controllers/loading_controller.js"
import { nextFrame } from "./setup.js"

// Browser tier (docs/COMPONENT_CONTRACT.md). The jsdom suite (loading_controller.test.js)
// covers the event contract with synthetic CustomEvents; this file drives the SAME
// scenarios through REAL @hotwired/turbo — a real <turbo-frame> navigation and a real
// <form> submission — which is what pins the event contract against Turbo version
// drift and is the only honest way to verify the form/frame double-fire finding
// documented in loading_controller.js's own docstring (a synthetic test can only
// assert what IT chooses to dispatch; this one proves Turbo's actual order).
//
// Importing "@hotwired/turbo" registers the real <turbo-frame> custom element and
// starts Drive's click/submit observers as a side effect of the import itself (see
// the finding recorded in morph.browser.test.js). `window.fetch` is monkey-patched
// per test (fetchWithTurboHeaders in Turbo's own source calls window.fetch directly,
// verified by reading it) rather than hitting a real network — deterministic, and
// fast enough to assert the anti-flicker delay precisely.

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
  application.register("cw--loading", LoadingController)
  return document.body.firstElementChild
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

function frameHtml(id, body = "loaded") {
  return `<!doctype html><html><body><turbo-frame id="${id}">${body}</turbo-frame></body></html>`
}

function delayedSuccess(id, ms) {
  return () => new Promise((resolve) => {
    setTimeout(
      () => resolve(new Response(frameHtml(id), { status: 200, headers: { "Content-Type": "text/html" } })),
      ms
    )
  })
}

const ACTIONS = [
  "turbo:submit-start->cw--loading#start",
  "turbo:before-fetch-request->cw--loading#start",
  "turbo:submit-end->cw--loading#stop",
  "turbo:frame-render->cw--loading#stop",
  "turbo:fetch-request-error->cw--loading#stop"
].join(" ")

describe("cw--loading — real Turbo events", () => {
  test("a real <turbo-frame> navigation marks data-loading after the delay, then clears it on turbo:frame-render", async () => {
    // Generous margins throughout this file rather than tight ones: this is a real
    // browser under real scheduling (JIT warm-up, CI load), not fake timers, so each
    // checkpoint sits well clear of its neighbouring threshold rather than close to it.
    window.fetch = delayedSuccess("loading-frame", 200)

    const el = boot(`
      <div data-controller="cw--loading" data-cw--loading-delay-value="30" data-action="${ACTIONS}">
        <turbo-frame id="loading-frame"></turbo-frame>
      </div>`)
    await nextFrame()

    const frame = el.querySelector("turbo-frame")
    frame.src = "/loading-demo"

    await wait(10)
    expect(frame.hasAttribute("data-loading")).toBe(false) // well under the 30ms threshold

    await wait(110) // t=120ms — past the 30ms threshold, well before the 200ms response
    expect(frame.hasAttribute("data-loading")).toBe(true)

    await wait(160) // t=280ms — well past the 200ms response
    expect(frame.hasAttribute("data-loading")).toBe(false) // turbo:frame-render cleared it
  })

  // The exact scenario loading_controller.js's docstring documents verifying against
  // Turbo's own source: turbo:before-fetch-request fires on the FORM (not merely
  // turbo:submit-start), and only turbo:submit-end closes it out for a non-frame-
  // render response shape. If the "skip before-fetch-request on a <form>" fix in
  // start() were removed, this test would fail with data-loading stuck at count 1.
  test("a real form submission marks the submitter separately from the form, and BOTH clear cleanly on submit-end", async () => {
    window.fetch = delayedSuccess("result-frame", 200)

    const el = boot(`
      <div data-controller="cw--loading" data-cw--loading-delay-value="30" data-action="${ACTIONS}">
        <form action="/survive" method="get" data-turbo-frame="result-frame">
          <button type="submit" id="go">Go</button>
        </form>
        <turbo-frame id="result-frame"></turbo-frame>
      </div>`)
    await nextFrame()

    const form = el.querySelector("form")
    const button = document.getElementById("go")

    button.click()

    await wait(120) // past the 30ms threshold, well before the 200ms response
    expect(form.hasAttribute("data-loading")).toBe(true)
    expect(button.hasAttribute("data-loading")).toBe(true)

    await wait(160) // well past the 200ms response
    expect(form.hasAttribute("data-loading")).toBe(false)
    expect(button.hasAttribute("data-loading")).toBe(false)
  })

  test("a network failure (fetch rejects) clears data-loading via turbo:fetch-request-error", async () => {
    // Verified against Turbo's own source: FetchRequest#perform() unconditionally
    // re-throws a genuine network error after dispatching turbo:fetch-request-error
    // (turbo.es2017-esm.js's `catch` block — `throw error` runs regardless of whether
    // anything called preventDefault()), and FrameController#visit()'s call site does
    // not await or catch that promise. So a REAL network failure always produces a
    // benign unhandled rejection inside Turbo itself, independent of anything this
    // controller does. Scoped narrowly to the exact message this test injects, so an
    // unrelated real bug elsewhere still fails the run.
    const swallowExpectedRejection = (event) => {
      if (event.reason?.message === "simulated network failure") event.preventDefault()
    }
    window.addEventListener("unhandledrejection", swallowExpectedRejection)

    window.fetch = () => Promise.reject(new TypeError("simulated network failure"))

    const el = boot(`
      <div data-controller="cw--loading" data-cw--loading-delay-value="10" data-action="${ACTIONS}">
        <turbo-frame id="err-frame"></turbo-frame>
      </div>`)
    await nextFrame()

    const frame = el.querySelector("turbo-frame")
    frame.src = "/will-fail"

    await wait(60)
    expect(frame.hasAttribute("data-loading")).toBe(false)

    window.removeEventListener("unhandledrejection", swallowExpectedRejection)
  })
})
