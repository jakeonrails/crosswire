import { describe, expect, test, vi, beforeEach, afterEach } from "vitest"
import ClipboardController from "../../app/assets/javascripts/crosswire/controllers/clipboard_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--clipboard": ClipboardController }

// jsdom implements neither navigator.clipboard nor document.execCommand — both are
// undefined by default (verified directly against the jsdom used by this project).
// This suite stubs them explicitly per scenario rather than relying on jsdom's
// (nonexistent) implementation, so every assertion here is honest about what it is
// actually exercising: the controller's own precedence/fallback/event logic, not a
// browser's real clipboard.

function fullMarkup({ successClass = "" } = {}) {
  return `
    <div data-controller="cw--clipboard"
         ${successClass ? `data-cw--clipboard-success-class="${successClass}"` : ""}>
      <input data-cw--clipboard-target="source" value="from-source-input">
      <button data-cw--clipboard-target="button"
              data-action="click->cw--clipboard#copy" type="button">Copy</button>
      <span data-cw--clipboard-target="status" role="status" aria-live="polite"></span>
    </div>`
}

function textSourceMarkup() {
  return `
    <div data-controller="cw--clipboard">
      <div data-cw--clipboard-target="source">from-source-text</div>
      <button data-cw--clipboard-target="button"
              data-action="click->cw--clipboard#copy" type="button">Copy</button>
    </div>`
}

function standaloneButtonMarkup(text) {
  return `
    <button data-controller="cw--clipboard"
            data-cw--clipboard-text-value="${text}"
            data-action="click->cw--clipboard#copy" type="button">Copy token</button>`
}

function elementTextOnlyMarkup() {
  return `
    <button data-controller="cw--clipboard"
            data-action="click->cw--clipboard#copy" type="button">from-element-text</button>`
}

beforeEach(() => {
  delete navigator.clipboard
  delete document.execCommand
})

afterEach(() => {
  delete navigator.clipboard
  delete document.execCommand
  vi.restoreAllMocks()
})

describe("cw--clipboard: copy source precedence", () => {
  test("explicit text value wins over the source target", async () => {
    navigator.clipboard = { writeText: vi.fn().mockResolvedValue(undefined) }
    const el = document.createElement("div")
    document.body.appendChild(el)
    el.innerHTML = fullMarkup()
    el.querySelector("[data-controller]").setAttribute("data-cw--clipboard-text-value", "explicit")

    const { Application } = await import("@hotwired/stimulus")
    const application = Application.start()
    application.register("cw--clipboard", ClipboardController)
    await nextFrame()

    el.querySelector("button").click()
    await nextFrame()

    expect(navigator.clipboard.writeText).toHaveBeenCalledWith("explicit")
    application.stop()
  })

  test("falls back to the source target's .value for inputs", async () => {
    navigator.clipboard = { writeText: vi.fn().mockResolvedValue(undefined) }
    const el = await mount(fullMarkup(), CONTROLLERS)

    el.querySelector("button").click()
    await nextFrame()

    expect(navigator.clipboard.writeText).toHaveBeenCalledWith("from-source-input")
  })

  test("falls back to the source target's .textContent for non-form elements", async () => {
    navigator.clipboard = { writeText: vi.fn().mockResolvedValue(undefined) }
    const el = await mount(textSourceMarkup(), CONTROLLERS)

    el.querySelector("button").click()
    await nextFrame()

    expect(navigator.clipboard.writeText).toHaveBeenCalledWith("from-source-text")
  })

  test("falls back to this.element.textContent with no text value and no source", async () => {
    navigator.clipboard = { writeText: vi.fn().mockResolvedValue(undefined) }
    const el = await mount(elementTextOnlyMarkup(), CONTROLLERS)

    el.click()
    await nextFrame()

    expect(navigator.clipboard.writeText).toHaveBeenCalledWith("from-element-text")
  })
})

describe("cw--clipboard: writing", () => {
  test("uses navigator.clipboard.writeText when available and dispatches copied", async () => {
    navigator.clipboard = { writeText: vi.fn().mockResolvedValue(undefined) }
    const copied = captureEvents("cw--clipboard:copied")
    const el = await mount(standaloneButtonMarkup("hello"), CONTROLLERS)

    el.click()
    await nextFrame()

    expect(copied).toHaveLength(1)
    expect(copied[0].detail.text).toBe("hello")
  })

  test("never throws unhandled when navigator.clipboard is entirely absent", async () => {
    const el = await mount(standaloneButtonMarkup("hello"), CONTROLLERS)
    expect(() => el.click()).not.toThrow()
    await nextFrame()
  })

  test("falls back to selection copy when navigator.clipboard is absent", async () => {
    document.execCommand = vi.fn(() => true)
    const copied = captureEvents("cw--clipboard:copied")
    const el = await mount(standaloneButtonMarkup("hello"), CONTROLLERS)

    el.click()
    await nextFrame()

    expect(document.execCommand).toHaveBeenCalledWith("copy")
    expect(copied).toHaveLength(1)
  })

  test("falls back to selection copy when writeText rejects", async () => {
    navigator.clipboard = { writeText: vi.fn().mockRejectedValue(new Error("denied")) }
    document.execCommand = vi.fn(() => true)
    const copied = captureEvents("cw--clipboard:copied")
    const el = await mount(standaloneButtonMarkup("hello"), CONTROLLERS)

    el.click()
    await nextFrame()

    expect(document.execCommand).toHaveBeenCalledWith("copy")
    expect(copied).toHaveLength(1)
  })

  test("dispatches failed, never throws, when both the API and the fallback fail", async () => {
    navigator.clipboard = { writeText: vi.fn().mockRejectedValue(new Error("denied")) }
    // No document.execCommand stub — jsdom has none, so the fallback's internal
    // try/catch swallows the TypeError and reports failure honestly.
    const failed = captureEvents("cw--clipboard:failed")
    const el = await mount(standaloneButtonMarkup("hello"), CONTROLLERS)

    expect(() => el.click()).not.toThrow()
    await nextFrame()

    expect(failed).toHaveLength(1)
    expect(typeof failed[0].detail.error).toBe("string")
  })

  test("the fallback scratch element does not leak into the DOM", async () => {
    document.execCommand = vi.fn(() => true)
    const el = await mount(standaloneButtonMarkup("hello"), CONTROLLERS)

    el.click()
    await nextFrame()

    expect(document.querySelector("textarea")).toBeNull()
  })
})

describe("cw--clipboard: success feedback", () => {
  test("applies the success class to the button target when given", async () => {
    navigator.clipboard = { writeText: vi.fn().mockResolvedValue(undefined) }
    const el = await mount(fullMarkup({ successClass: "is-copied" }), CONTROLLERS)

    el.querySelector("button").click()
    await nextFrame()

    expect(el.querySelector("button").classList.contains("is-copied")).toBe(true)
  })

  test("applies the success class to the root element when there is no button target", async () => {
    navigator.clipboard = { writeText: vi.fn().mockResolvedValue(undefined) }
    const el = document.body
    el.innerHTML = ""
    const markup = `<button data-controller="cw--clipboard"
                            data-cw--clipboard-text-value="hi"
                            data-cw--clipboard-success-class="is-copied"
                            data-action="click->cw--clipboard#copy" type="button">Copy</button>`
    const root = await mount(markup, CONTROLLERS)

    root.click()
    await nextFrame()

    expect(root.classList.contains("is-copied")).toBe(true)
  })

  // R3 — Stimulus throws on this.fooClass when the attribute is absent.
  test("does not throw when no success class is given", async () => {
    navigator.clipboard = { writeText: vi.fn().mockResolvedValue(undefined) }
    const el = await mount(standaloneButtonMarkup("hello"), CONTROLLERS)

    expect(() => el.click()).not.toThrow()
    await nextFrame()
  })

  test("announces success into the status target's aria-live region", async () => {
    navigator.clipboard = { writeText: vi.fn().mockResolvedValue(undefined) }
    const el = await mount(fullMarkup(), CONTROLLERS)

    el.querySelector("button").click()
    await nextFrame()

    expect(el.querySelector("[data-cw--clipboard-target='status']").textContent).toBe("Copied")
  })

  test("does not throw when there is no status target", async () => {
    navigator.clipboard = { writeText: vi.fn().mockResolvedValue(undefined) }
    const el = await mount(standaloneButtonMarkup("hello"), CONTROLLERS)

    expect(() => el.click()).not.toThrow()
    await nextFrame()
  })
})

describe("cw--clipboard: teardown (R7)", () => {
  test("disconnect cancels the pending success timer", async () => {
    const clearSpy = vi.spyOn(globalThis, "clearTimeout")
    navigator.clipboard = { writeText: vi.fn().mockResolvedValue(undefined) }
    await mount(fullMarkup(), CONTROLLERS)

    document.querySelector("button").click()
    await nextFrame()

    document.body.innerHTML = ""
    await nextFrame()

    expect(clearSpy).toHaveBeenCalled()
  })

  test("disconnect clears the success class and status text", async () => {
    navigator.clipboard = { writeText: vi.fn().mockResolvedValue(undefined) }
    const el = await mount(fullMarkup({ successClass: "is-copied" }), CONTROLLERS)
    const button = el.querySelector("button")
    const status = el.querySelector("[data-cw--clipboard-target='status']")

    button.click()
    await nextFrame()
    expect(button.classList.contains("is-copied")).toBe(true)
    expect(status.textContent).toBe("Copied")

    document.body.innerHTML = ""
    await nextFrame()

    expect(button.classList.contains("is-copied")).toBe(false)
    expect(status.textContent).toBe("")
  })
})
