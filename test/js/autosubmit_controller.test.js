import { describe, expect, test, vi } from "vitest"
import AutosubmitController from "../../app/assets/javascripts/crosswire/controllers/autosubmit_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--autosubmit": AutosubmitController }

function markup({ delay = null, event = null, scope = null } = {}) {
  return `
    <form id="f">
      <input data-controller="cw--autosubmit"
             ${delay !== null ? `data-cw--autosubmit-delay-value="${delay}"` : ""}
             ${event !== null ? `data-cw--autosubmit-event-value="${event}"` : ""}
             ${scope !== null ? `data-cw--autosubmit-scope-value="${scope}"` : ""}
             name="q" value="">
    </form>`
}

// jsdom does not implement real navigation, and requestSubmit() would otherwise log a
// "not implemented" error trying to perform one — every test needs a submit listener
// that prevents the default, exactly as a real Turbo-enhanced form's own listener would.
function preventRealSubmission(el) {
  const form = el.closest("form") || el
  form.addEventListener("submit", (event) => event.preventDefault())
  return form
}

function setValue(el, value) {
  el.value = value
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

describe("cw--autosubmit", () => {
  test("submits the owning form immediately when delay is 0 (default)", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const input = el.querySelector("input")
    const form = preventRealSubmission(input)
    const requestSubmit = vi.spyOn(form, "requestSubmit")

    setValue(input, "hello")
    input.dispatchEvent(new Event("input"))

    expect(requestSubmit).toHaveBeenCalledTimes(1)
  })

  // The most common bug in hand-rolled versions of this controller.
  test("never calls form.submit()", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const input = el.querySelector("input")
    const form = preventRealSubmission(input)
    const submit = vi.spyOn(form, "submit")

    setValue(input, "hello")
    input.dispatchEvent(new Event("input"))

    expect(submit).not.toHaveBeenCalled()
  })

  test("debounces on the trailing edge", async () => {
    const el = await mount(markup({ delay: 30 }), CONTROLLERS)
    const input = el.querySelector("input")
    const form = preventRealSubmission(input)
    const requestSubmit = vi.spyOn(form, "requestSubmit")

    setValue(input, "h")
    input.dispatchEvent(new Event("input"))
    await wait(10)

    setValue(input, "he")
    input.dispatchEvent(new Event("input"))
    await wait(10)

    setValue(input, "hel")
    input.dispatchEvent(new Event("input"))

    expect(requestSubmit).not.toHaveBeenCalled()

    await wait(40)
    expect(requestSubmit).toHaveBeenCalledTimes(1)
  })

  test("respects the configured event (change instead of input)", async () => {
    const el = await mount(markup({ event: "change" }), CONTROLLERS)
    const input = el.querySelector("input")
    const form = preventRealSubmission(input)
    const requestSubmit = vi.spyOn(form, "requestSubmit")

    setValue(input, "hello")
    input.dispatchEvent(new Event("input"))
    expect(requestSubmit).not.toHaveBeenCalled()

    input.dispatchEvent(new Event("change"))
    expect(requestSubmit).toHaveBeenCalledTimes(1)
  })

  test("does not submit when the value has not actually changed", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const input = el.querySelector("input")
    const form = preventRealSubmission(input)
    const requestSubmit = vi.spyOn(form, "requestSubmit")

    // Simulates an arrow-key or modifier-key event that fires the configured DOM
    // event without the value having moved from what was last submitted.
    input.dispatchEvent(new Event("input"))

    expect(requestSubmit).not.toHaveBeenCalled()
  })

  test("a real submit cancels a pending debounced submit", async () => {
    const el = await mount(markup({ delay: 30 }), CONTROLLERS)
    const input = el.querySelector("input")
    const form = preventRealSubmission(input)
    const requestSubmit = vi.spyOn(form, "requestSubmit")

    setValue(input, "hello")
    input.dispatchEvent(new Event("input"))
    expect(requestSubmit).not.toHaveBeenCalled()

    // A real submit happens (Enter, a submit button, another controller) before the
    // debounce timer elapses.
    form.dispatchEvent(new Event("submit", { cancelable: true }))

    await wait(60)
    // Only the real submit happened; the debounced one never fired behind it.
    expect(requestSubmit).not.toHaveBeenCalled()
  })

  test("dispatches submitting and submitted", async () => {
    const submitting = captureEvents("cw--autosubmit:submitting")
    const submitted = captureEvents("cw--autosubmit:submitted")
    const el = await mount(markup(), CONTROLLERS)
    const input = el.querySelector("input")
    preventRealSubmission(input)

    setValue(input, "hello")
    input.dispatchEvent(new Event("input"))

    expect(submitting).toHaveLength(1)
    expect(submitted).toHaveLength(1)
  })

  test("submitting is cancelable and prevents the submit", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const input = el.querySelector("input")
    const form = preventRealSubmission(input)
    const requestSubmit = vi.spyOn(form, "requestSubmit")

    document.addEventListener(
      "cw--autosubmit:submitting",
      (event) => event.preventDefault(),
      { once: true }
    )

    setValue(input, "hello")
    input.dispatchEvent(new Event("input"))

    expect(requestSubmit).not.toHaveBeenCalled()
  })

  test("uses the scope selector instead of the owning form when given", async () => {
    document.body.innerHTML = `
      <form id="other-form"></form>
      <form id="f">
        <input data-controller="cw--autosubmit"
               data-cw--autosubmit-scope-value="#other-form"
               name="q" value="">
      </form>`
    const { Application } = await import("@hotwired/stimulus")
    const application = Application.start()
    application.register("cw--autosubmit", AutosubmitController)
    await nextFrame()

    const otherForm = document.getElementById("other-form")
    const ownForm = document.getElementById("f")
    otherForm.addEventListener("submit", (event) => event.preventDefault())
    ownForm.addEventListener("submit", (event) => event.preventDefault())

    const otherRequestSubmit = vi.spyOn(otherForm, "requestSubmit")
    const ownRequestSubmit = vi.spyOn(ownForm, "requestSubmit")

    const input = document.querySelector("input")
    setValue(input, "hello")
    input.dispatchEvent(new Event("input"))

    expect(otherRequestSubmit).toHaveBeenCalledTimes(1)
    expect(ownRequestSubmit).not.toHaveBeenCalled()

    application.stop()
  })

  test("cancels a pending debounce on disconnect", async () => {
    const el = await mount(markup({ delay: 30 }), CONTROLLERS)
    const input = el.querySelector("input")
    const form = preventRealSubmission(input)
    const requestSubmit = vi.spyOn(form, "requestSubmit")

    setValue(input, "hello")
    input.dispatchEvent(new Event("input"))

    document.body.innerHTML = ""
    await nextFrame()

    await wait(60)
    expect(requestSubmit).not.toHaveBeenCalled()
  })
})
