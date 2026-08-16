import { describe, expect, test } from "vitest"
import LoadingController from "../../app/assets/javascripts/crosswire/controllers/loading_controller.js"
import { mount, nextFrame } from "./setup.js"

// jsdom tier — event-contract tests, same rationale as preserve_controller.test.js:
// the synthetic events below match the exact shape @hotwired/turbo's own dispatch()
// produces (bubbles: true, cancelable as applicable, detail). What this file does NOT
// claim to test is that REAL Turbo actually fires these events with these names for a
// real form submission or frame load — that is loading_controller.browser.test.js's
// job, and it is also where the "turbo:before-fetch-request re-fires on a <form>"
// finding documented in the controller itself was verified against Turbo's own source.

const CONTROLLERS = { "cw--loading": LoadingController }

const ACTIONS = [
  "turbo:submit-start->cw--loading#start",
  "turbo:before-fetch-request->cw--loading#start",
  "turbo:submit-end->cw--loading#stop",
  "turbo:frame-render->cw--loading#stop",
  "turbo:fetch-request-error->cw--loading#stop"
].join(" ")

function markup({ delay = 30, loadingClass = null } = {}) {
  return `
    <div data-controller="cw--loading"
         data-cw--loading-delay-value="${delay}"
         ${loadingClass !== null ? `data-cw--loading-loading-class="${loadingClass}"` : ""}
         data-action="${ACTIONS}">
      <form id="the-form"><button id="the-button" type="submit">Go</button></form>
      <turbo-frame id="the-frame"></turbo-frame>
    </div>`
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

function submitStart(form, submitter = null) {
  const event = new CustomEvent("turbo:submit-start", {
    bubbles: true,
    cancelable: true,
    detail: { formSubmission: submitter ? { submitter } : {} }
  })
  form.dispatchEvent(event)
  return event
}

function submitEnd(form, submitter = null) {
  const event = new CustomEvent("turbo:submit-end", {
    bubbles: true,
    detail: { formSubmission: submitter ? { submitter } : {} }
  })
  form.dispatchEvent(event)
  return event
}

function beforeFetchRequest(target) {
  const event = new CustomEvent("turbo:before-fetch-request", {
    bubbles: true,
    cancelable: true,
    detail: { fetchOptions: {}, url: "http://example.com/" }
  })
  target.dispatchEvent(event)
  return event
}

function frameRender(frame) {
  const event = new CustomEvent("turbo:frame-render", { bubbles: true, cancelable: true, detail: {} })
  frame.dispatchEvent(event)
  return event
}

function fetchRequestError(target) {
  const event = new CustomEvent("turbo:fetch-request-error", { bubbles: true, cancelable: true, detail: {} })
  target.dispatchEvent(event)
  return event
}

describe("cw--loading", () => {
  // --- the anti-flicker delay -----------------------------------------------------------

  test("marks the originating element with a bare data-loading after the delay elapses", async () => {
    const el = await mount(markup({ delay: 20 }), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchRequest(frame)
    await wait(5)
    expect(frame.hasAttribute("data-loading")).toBe(false)

    await wait(30)
    expect(frame.getAttribute("data-loading")).toBe("")
  })

  test("clears data-loading on turbo:frame-render", async () => {
    const el = await mount(markup({ delay: 10 }), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchRequest(frame)
    await wait(20)
    expect(frame.hasAttribute("data-loading")).toBe(true)

    frameRender(frame)
    expect(frame.hasAttribute("data-loading")).toBe(false)
  })

  test("clears data-loading on turbo:fetch-request-error", async () => {
    const el = await mount(markup({ delay: 10 }), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchRequest(frame)
    await wait(20)
    expect(frame.hasAttribute("data-loading")).toBe(true)

    fetchRequestError(frame)
    expect(frame.hasAttribute("data-loading")).toBe(false)
  })

  test("a request that resolves before the delay elapses never flashes data-loading", async () => {
    const el = await mount(markup({ delay: 30 }), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchRequest(frame)
    await wait(5)
    frameRender(frame) // resolves well under the 30ms threshold

    await wait(40) // past the original deadline — must not have fired late
    expect(frame.hasAttribute("data-loading")).toBe(false)
  })

  // --- the Turbo-source-verified form/frame double-fire fix -----------------------------

  test("turbo:before-fetch-request on a <form> is ignored — turbo:submit-start already covers it", async () => {
    const el = await mount(markup({ delay: 10 }), CONTROLLERS)
    const form = el.querySelector("#the-form")

    beforeFetchRequest(form)
    await wait(20)
    expect(form.hasAttribute("data-loading")).toBe(false)
  })

  test("a real form submission (submit-start immediately followed by before-fetch-request, Turbo's own order) still clears cleanly on submit-end", async () => {
    const el = await mount(markup({ delay: 10 }), CONTROLLERS)
    const form = el.querySelector("#the-form")

    // Turbo's own FetchRequest#perform() dispatches turbo:before-fetch-request BEFORE
    // turbo:submit-start for a form submission (see the controller's docstring) — both
    // targeted at the SAME form element.
    beforeFetchRequest(form)
    submitStart(form)
    await wait(20)
    expect(form.hasAttribute("data-loading")).toBe(true)

    submitEnd(form)
    expect(form.hasAttribute("data-loading")).toBe(false)
  })

  // --- submitter marking ------------------------------------------------------------------

  test("marks the submitter separately from the form, and clears it independently", async () => {
    const el = await mount(markup({ delay: 10 }), CONTROLLERS)
    const form = el.querySelector("#the-form")
    const button = el.querySelector("#the-button")

    submitStart(form, button)
    await wait(20)
    expect(form.hasAttribute("data-loading")).toBe(true)
    expect(button.hasAttribute("data-loading")).toBe(true)

    submitEnd(form, button)
    expect(form.hasAttribute("data-loading")).toBe(false)
    expect(button.hasAttribute("data-loading")).toBe(false)
  })

  // --- ref-counting overlapping requests on one element -----------------------------------

  test("ref-counts overlapping requests on the same element — only the LAST stop clears it", async () => {
    const el = await mount(markup({ delay: 10 }), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchRequest(frame)
    beforeFetchRequest(frame) // a second, overlapping request on the same frame
    await wait(20)
    expect(frame.hasAttribute("data-loading")).toBe(true)

    frameRender(frame) // first one finishes
    expect(frame.hasAttribute("data-loading")).toBe(true) // still one in flight

    frameRender(frame) // second one finishes
    expect(frame.hasAttribute("data-loading")).toBe(false)
  })

  // --- the optional convenience class, guarded per R3 --------------------------------------

  test("applies the loading class alongside the attribute when configured", async () => {
    const el = await mount(markup({ delay: 10, loadingClass: "is-loading" }), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchRequest(frame)
    await wait(20)
    expect(frame.classList.contains("is-loading")).toBe(true)

    frameRender(frame)
    expect(frame.classList.contains("is-loading")).toBe(false)
  })

  test("does not throw when no loading class is configured (R3 — hasLoadingClass guard)", async () => {
    const el = await mount(markup({ delay: 10 }), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchRequest(frame)
    await expect(wait(20)).resolves.toBeUndefined()
    expect(frame.getAttribute("data-loading")).toBe("")
  })

  // --- R7: exhaustive teardown --------------------------------------------------------------

  test("disconnect() clears a pending (not-yet-fired) timer", async () => {
    const el = await mount(markup({ delay: 30 }), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchRequest(frame)

    document.body.innerHTML = ""
    await nextFrame()

    await wait(40)
    expect(frame.hasAttribute("data-loading")).toBe(false)
  })

  test("disconnect() removes data-loading from every element it had already marked", async () => {
    const el = await mount(markup({ delay: 10 }), CONTROLLERS)
    const frame = el.querySelector("#the-frame")

    beforeFetchRequest(frame)
    await wait(20)
    expect(frame.hasAttribute("data-loading")).toBe(true)

    document.body.innerHTML = ""
    await nextFrame()

    expect(frame.hasAttribute("data-loading")).toBe(false)
  })
})
