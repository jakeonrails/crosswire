import { afterEach, describe, expect, test, vi } from "vitest"
import DirtyFormController from "../../app/assets/javascripts/crosswire/controllers/dirty_form_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

// Several tests below spy on window.confirm without restoring it individually. Left
// unrestored, vi.spyOn's replacement of window.confirm (and its accumulated call
// history) survives into later tests in this file — the exact same class of leak R7
// exists to prevent, just for a spy instead of a controller-owned listener. Restoring
// here once, for all of them, is more robust than chasing down every call site.
afterEach(() => {
  vi.restoreAllMocks()
})

const CONTROLLERS = { "cw--dirty-form": DirtyFormController }

function markup({ guard = null, dirtyClass = null, withFieldTargets = false } = {}) {
  const fieldAttr = withFieldTargets ? 'data-cw--dirty-form-target="field"' : ""
  return `
    <form data-controller="cw--dirty-form"
          ${guard !== null ? `data-cw--dirty-form-guard-value="${guard}"` : ""}
          ${dirtyClass ? `data-cw--dirty-form-dirty-class="${dirtyClass}"` : ""}
          data-action="input->cw--dirty-form#check change->cw--dirty-form#check">
      <input type="text" name="title" value="Hello" ${fieldAttr}>
      <input type="text" name="ignored" value="untracked">
      <input type="checkbox" name="published" ${withFieldTargets ? "" : ""}>
      <button type="submit">Save</button>
    </form>`
}

function setValue(input, value) {
  input.value = value
  input.dispatchEvent(new Event("input", { bubbles: true }))
}

function dispatchCancelable(target, type, detail) {
  const event = new CustomEvent(type, { bubbles: true, cancelable: true, detail })
  target.dispatchEvent(event)
  return event
}

describe("cw--dirty-form", () => {
  test("starts clean: data-dirty is false on connect", async () => {
    const el = await mount(markup(), CONTROLLERS)
    expect(el.dataset.dirty).toBe("false")
  })

  test("editing a field sets data-dirty to true", async () => {
    const el = await mount(markup(), CONTROLLERS)
    setValue(el.querySelector('[name="title"]'), "Hello world")
    expect(el.dataset.dirty).toBe("true")
  })

  // The whole point of comparing against a snapshot rather than "any input event
  // fired": typing and then undoing it must not leave the form dirty.
  test("typing a character and then deleting it leaves the form clean", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const title = el.querySelector('[name="title"]')

    setValue(title, "Hello!")
    expect(el.dataset.dirty).toBe("true")

    setValue(title, "Hello")
    expect(el.dataset.dirty).toBe("false")
  })

  test("dispatches changed and reset only on real transitions", async () => {
    const changed = captureEvents("cw--dirty-form:changed")
    const reset = captureEvents("cw--dirty-form:reset")
    const el = await mount(markup(), CONTROLLERS)
    const title = el.querySelector('[name="title"]')

    setValue(title, "Hello!")
    setValue(title, "Hello!!")
    expect(changed).toHaveLength(1) // second edit was already dirty — no re-dispatch

    setValue(title, "Hello")
    expect(reset).toHaveLength(1)
  })

  test("reset() re-baselines against current values", async () => {
    // Invoked through a real data-action-bound button, the same way any consumer
    // would call it (e.g. after an in-place Turbo Frame save) — not by reaching into
    // Stimulus internals for the controller instance.
    const el = await mount(markup(), CONTROLLERS)
    const resetButton = document.createElement("button")
    resetButton.type = "button"
    resetButton.setAttribute("data-action", "click->cw--dirty-form#reset")
    el.appendChild(resetButton)
    // Stimulus discovers the new data-action binding via its own MutationObserver,
    // asynchronously — clicking synchronously right after appendChild would hit the
    // button before the action is wired up.
    await nextFrame()

    const title = el.querySelector('[name="title"]')

    setValue(title, "Hello!")
    expect(el.dataset.dirty).toBe("true")

    resetButton.click()

    expect(el.dataset.dirty).toBe("false")

    // Editing further from the NEW baseline is dirty again...
    setValue(title, "Hello! more")
    expect(el.dataset.dirty).toBe("true")
    // ...but going back to the re-baselined value is clean.
    setValue(title, "Hello!")
    expect(el.dataset.dirty).toBe("false")
  })

  test("applies the optional dirty class", async () => {
    const el = await mount(markup({ dirtyClass: "is-dirty" }), CONTROLLERS)
    setValue(el.querySelector('[name="title"]'), "Hello!")
    expect(el.classList.contains("is-dirty")).toBe(true)
  })

  // R3 — Stimulus throws on this.fooClass when the attribute is absent.
  test("does not throw when no dirty class is given", async () => {
    const el = await mount(markup(), CONTROLLERS)
    expect(() => setValue(el.querySelector('[name="title"]'), "Hello!")).not.toThrow()
  })

  test("clears dirty on turbo:submit-end when the submission succeeded", async () => {
    const el = await mount(markup(), CONTROLLERS)
    setValue(el.querySelector('[name="title"]'), "Hello!")
    expect(el.dataset.dirty).toBe("true")

    el.dispatchEvent(new CustomEvent("turbo:submit-end", { detail: { success: true } }))
    expect(el.dataset.dirty).toBe("false")
  })

  test("does NOT clear dirty on turbo:submit-end when the submission failed", async () => {
    const el = await mount(markup(), CONTROLLERS)
    setValue(el.querySelector('[name="title"]'), "Hello!")

    el.dispatchEvent(new CustomEvent("turbo:submit-end", { detail: { success: false } }))
    expect(el.dataset.dirty).toBe("true")
  })

  // --- guard: false — tracked but never blocks navigation --------------------------

  test("guard: false still tracks dirty but never blocks beforeunload", async () => {
    const el = await mount(markup({ guard: false }), CONTROLLERS)
    setValue(el.querySelector('[name="title"]'), "Hello!")
    expect(el.dataset.dirty).toBe("true")

    const event = new Event("beforeunload", { cancelable: true })
    Object.defineProperty(event, "returnValue", { value: "", writable: true })
    dispatchEvent(event)

    expect(event.defaultPrevented).toBe(false)
  })

  // --- the three guards, and only these three ---------------------------------------

  test("beforeunload is prevented while dirty and guard is true", async () => {
    await mount(markup(), CONTROLLERS)
    document.querySelector('[name="title"]').dispatchEvent(new Event("input", { bubbles: true }))
    setValue(document.querySelector('[name="title"]'), "Hello!")

    const event = new Event("beforeunload", { cancelable: true })
    dispatchEvent(event)

    expect(event.defaultPrevented).toBe(true)
  })

  test("beforeunload is NOT prevented while clean", async () => {
    await mount(markup(), CONTROLLERS)

    const event = new Event("beforeunload", { cancelable: true })
    dispatchEvent(event)

    expect(event.defaultPrevented).toBe(false)
  })

  test("turbo:before-visit is cancelled while dirty if the user declines the confirm", async () => {
    vi.spyOn(window, "confirm").mockReturnValue(false)
    const el = await mount(markup(), CONTROLLERS)
    setValue(el.querySelector('[name="title"]'), "Hello!")

    const event = dispatchCancelable(document, "turbo:before-visit")
    expect(event.defaultPrevented).toBe(true)
    expect(window.confirm).toHaveBeenCalled()
  })

  test("turbo:before-visit proceeds while dirty if the user accepts the confirm", async () => {
    vi.spyOn(window, "confirm").mockReturnValue(true)
    const el = await mount(markup(), CONTROLLERS)
    setValue(el.querySelector('[name="title"]'), "Hello!")

    const event = dispatchCancelable(document, "turbo:before-visit")
    expect(event.defaultPrevented).toBe(false)
  })

  test("turbo:before-visit is untouched while clean — no confirm shown at all", async () => {
    vi.spyOn(window, "confirm")
    await mount(markup(), CONTROLLERS)

    const event = dispatchCancelable(document, "turbo:before-visit")
    expect(event.defaultPrevented).toBe(false)
    expect(window.confirm).not.toHaveBeenCalled()
  })

  test("turbo:before-frame-render on the owning frame is guarded while dirty", async () => {
    vi.spyOn(window, "confirm").mockReturnValue(false)
    document.body.innerHTML = `
      <turbo-frame id="f">
        <form data-controller="cw--dirty-form"
              data-action="input->cw--dirty-form#check change->cw--dirty-form#check">
          <input type="text" name="title" value="Hello">
        </form>
      </turbo-frame>`
    const { Application } = await import("@hotwired/stimulus")
    const application = Application.start()
    application.register("cw--dirty-form", DirtyFormController)
    await nextFrame()

    setValue(document.querySelector('[name="title"]'), "Hello!")

    const frame = document.getElementById("f")
    const event = dispatchCancelable(frame, "turbo:before-frame-render")
    expect(event.defaultPrevented).toBe(true)

    // Clear the DOM and let Stimulus's own MutationObserver fire disconnect() for
    // real BEFORE stopping the application — Application#stop() alone does not call
    // disconnect() on still-connected controllers, and this controller's
    // document-level turbo:before-visit/turbo:before-frame-render listeners would
    // otherwise leak into every later test in this file (see test/js/setup.js and
    // docs/BUILD-LOG.md #6).
    document.body.innerHTML = ""
    await nextFrame()
    application.stop()
  })

  test("turbo:before-frame-render on an UNRELATED frame does not trigger the guard", async () => {
    vi.spyOn(window, "confirm")
    const el = await mount(markup(), CONTROLLERS)
    setValue(el.querySelector('[name="title"]'), "Hello!")

    const unrelated = document.createElement("turbo-frame")
    document.body.appendChild(unrelated)
    const event = dispatchCancelable(unrelated, "turbo:before-frame-render")

    expect(event.defaultPrevented).toBe(false)
    expect(window.confirm).not.toHaveBeenCalled()
  })

  // --- field targets: optional scoping -----------------------------------------------

  test("with field targets given, only those fields are tracked", async () => {
    const el = await mount(markup({ withFieldTargets: true }), CONTROLLERS)
    const ignored = el.querySelector('[name="ignored"]')

    setValue(ignored, "changed but untracked")
    expect(el.dataset.dirty).toBe("false")

    setValue(el.querySelector('[name="title"]'), "Hello!")
    expect(el.dataset.dirty).toBe("true")
  })

  test("with no field targets, every control in the form is tracked", async () => {
    const el = await mount(markup(), CONTROLLERS)
    setValue(el.querySelector('[name="ignored"]'), "now tracked")
    expect(el.dataset.dirty).toBe("true")
  })

  // --- R7: exhaustive teardown ---------------------------------------------------

  test("disconnect removes all four listeners — beforeunload no longer blocked after teardown", async () => {
    const el = await mount(markup(), CONTROLLERS)
    setValue(el.querySelector('[name="title"]'), "Hello!")
    expect(el.dataset.dirty).toBe("true")

    document.body.innerHTML = ""
    await nextFrame()

    const event = new Event("beforeunload", { cancelable: true })
    dispatchEvent(event)
    expect(event.defaultPrevented).toBe(false)
  })

  test("disconnect stops reacting to turbo:before-visit", async () => {
    vi.spyOn(window, "confirm").mockReturnValue(false)
    await mount(markup(), CONTROLLERS)
    setValue(document.querySelector('[name="title"]'), "Hello!")

    document.body.innerHTML = ""
    await nextFrame()

    const event = dispatchCancelable(document, "turbo:before-visit")
    expect(event.defaultPrevented).toBe(false)
    expect(window.confirm).not.toHaveBeenCalled()
  })
})
