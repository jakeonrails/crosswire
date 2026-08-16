import { describe, expect, test } from "vitest"
import DismissController from "../../app/assets/javascripts/crosswire/controllers/dismiss_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--dismiss": DismissController }

function markup({ remove = null, selector = null } = {}) {
  return `
    <div data-controller="cw--dismiss"
         ${remove !== null ? `data-cw--dismiss-remove-value="${remove}"` : ""}
         ${selector ? `data-cw--dismiss-selector-value="${selector}"` : ""}>
      <button data-action="click->cw--dismiss#dismiss">Dismiss</button>
    </div>`
}

describe("cw--dismiss", () => {
  test("removes the element by default", async () => {
    const el = await mount(markup(), CONTROLLERS)
    el.querySelector("button").click()
    await nextFrame()

    expect(el.isConnected).toBe(false)
  })

  // Hiding rather than removing is the right default inside a Turbo Frame that may
  // re-render out from under a removed node — a frame re-render can restore markup the
  // controller already deleted, but it can't resurrect a hidden element incorrectly
  // because the server-rendered state wins on the next render anyway.
  test("hides instead of removing when remove is false", async () => {
    const el = await mount(markup({ remove: false }), CONTROLLERS)
    el.querySelector("button").click()
    await nextFrame()

    expect(el.isConnected).toBe(true)
    expect(el.hidden).toBe(true)
  })

  test("selector targets an ancestor via closest", async () => {
    document.body.innerHTML = `
      <div class="alert">
        <div data-controller="cw--dismiss" data-cw--dismiss-selector-value=".alert">
          <button data-action="click->cw--dismiss#dismiss">Dismiss</button>
        </div>
      </div>`
    const { Application } = await import("@hotwired/stimulus")
    const application = Application.start()
    application.register("cw--dismiss", DismissController)
    await nextFrame()

    const alert = document.querySelector(".alert")
    document.querySelector("button").click()
    await nextFrame()

    expect(alert.isConnected).toBe(false)

    application.stop()
  })

  test("selector falls back to a document-wide query when no ancestor matches", async () => {
    document.body.innerHTML = `
      <div id="elsewhere" class="alert"></div>
      <div data-controller="cw--dismiss" data-cw--dismiss-selector-value=".alert">
        <button data-action="click->cw--dismiss#dismiss">Dismiss</button>
      </div>`
    const { Application } = await import("@hotwired/stimulus")
    const application = Application.start()
    application.register("cw--dismiss", DismissController)
    await nextFrame()

    const elsewhere = document.getElementById("elsewhere")
    const controllerRoot = document.querySelector("[data-controller='cw--dismiss']")
    document.querySelector("button").click()
    await nextFrame()

    expect(elsewhere.isConnected).toBe(false)
    // The controller's own element was not the dismiss target, so it survives.
    expect(controllerRoot.isConnected).toBe(true)

    application.stop()
  })

  // R6 — this is the seam cw--transition hooks to animate an exit. Node.remove() is
  // synchronous, so if this event weren't cancelable (or preventDefault() didn't hold
  // removal open) there would be nothing left to animate. This is the most important
  // test in the file.
  test("dispatches a cancelable dismissing event, and preventDefault() keeps the element in the DOM", async () => {
    const dismissing = captureEvents("cw--dismiss:dismissing")
    const el = await mount(markup(), CONTROLLERS)
    el.addEventListener("cw--dismiss:dismissing", (event) => event.preventDefault())

    el.querySelector("button").click()
    await nextFrame()

    expect(dismissing).toHaveLength(1)
    expect(dismissing[0].cancelable).toBe(true)
    expect(dismissing[0].defaultPrevented).toBe(true)
    expect(el.isConnected).toBe(true)
  })

  test("the complete() callback in event.detail completes the dismissal when invoked later", async () => {
    const dismissing = captureEvents("cw--dismiss:dismissing")
    const dismissed = captureEvents("cw--dismiss:dismissed")
    const el = await mount(markup(), CONTROLLERS)
    el.addEventListener("cw--dismiss:dismissing", (event) => event.preventDefault())

    el.querySelector("button").click()
    await nextFrame()

    expect(el.isConnected).toBe(true) // held open by preventDefault
    expect(dismissed).toHaveLength(0)

    dismissing[0].detail.complete()
    await nextFrame()

    expect(el.isConnected).toBe(false)
    expect(dismissed).toHaveLength(1)
  })

  test("dispatches dismissed with detail.removed true when removeValue is true", async () => {
    const dismissed = captureEvents("cw--dismiss:dismissed")
    const el = await mount(markup(), CONTROLLERS)

    el.querySelector("button").click()
    await nextFrame()

    expect(dismissed).toHaveLength(1)
    expect(dismissed[0].detail.removed).toBe(true)
  })

  test("dispatches dismissed with detail.removed false when remove is false", async () => {
    const dismissed = captureEvents("cw--dismiss:dismissed")
    const el = await mount(markup({ remove: false }), CONTROLLERS)

    el.querySelector("button").click()
    await nextFrame()

    expect(dismissed).toHaveLength(1)
    expect(dismissed[0].detail.removed).toBe(false)
  })

  // R8 — a screen reader's focus otherwise falls back to <body> and the user loses
  // their place. The controller looks for a focusable ancestor of the removed node's
  // parent before detaching it.
  test("R8: moves focus off a stranded node before removing it, rather than stranding it on body", async () => {
    document.body.innerHTML = `
      <div id="wrapper" tabindex="0">
        <div data-controller="cw--dismiss">
          <button data-action="click->cw--dismiss#dismiss">Dismiss</button>
          <input id="focus-me">
        </div>
      </div>`
    const { Application } = await import("@hotwired/stimulus")
    const application = Application.start()
    application.register("cw--dismiss", DismissController)
    await nextFrame()

    const wrapper = document.getElementById("wrapper")
    document.getElementById("focus-me").focus()
    expect(document.activeElement.id).toBe("focus-me")

    document.querySelector("button").click()
    await nextFrame()

    expect(document.activeElement).toBe(wrapper)
    expect(document.activeElement).not.toBe(document.body)

    application.stop()
  })

  test("R8: falls back to document.body when no focusable ancestor exists", async () => {
    const el = await mount(markup(), CONTROLLERS)
    el.querySelector("button").focus()
    expect(document.activeElement).toBe(el.querySelector("button"))

    el.querySelector("button").click()
    await nextFrame()

    expect(document.activeElement).toBe(document.body)
  })
})
