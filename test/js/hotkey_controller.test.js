import { describe, expect, test } from "vitest"
import HotkeyController from "../../app/assets/javascripts/crosswire/controllers/hotkey_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--hotkey": HotkeyController }

function markup({ key, scope = null, preventDefault = null, tag = "button", extra = "" } = {}) {
  return `
    <${tag} data-controller="cw--hotkey"
         data-cw--hotkey-key-value="${key}"
         ${scope !== null ? `data-cw--hotkey-scope-value="${scope}"` : ""}
         ${preventDefault !== null ? `data-cw--hotkey-prevent-default-value="${preventDefault}"` : ""}
         ${extra}>Search</${tag}>`
}

function keydown(overrides = {}) {
  return new KeyboardEvent("keydown", {
    bubbles: true,
    cancelable: true,
    key: "k",
    ...overrides
  })
}

describe("cw--hotkey", () => {
  // --- basic matching ---------------------------------------------------------------

  test("fires on a plain key with no modifiers", async () => {
    const fired = captureEvents("cw--hotkey:fired")
    await mount(markup({ key: "/" }), CONTROLLERS)

    document.dispatchEvent(keydown({ key: "/" }))

    expect(fired).toHaveLength(1)
    expect(fired[0].detail.key).toBe("/")
  })

  test("fires on a modifier chord", async () => {
    const fired = captureEvents("cw--hotkey:fired")
    await mount(markup({ key: "cmd+k" }), CONTROLLERS)

    document.dispatchEvent(keydown({ key: "k", metaKey: true }))

    expect(fired).toHaveLength(1)
  })

  test("does not fire when the key matches but a required modifier is missing", async () => {
    const fired = captureEvents("cw--hotkey:fired")
    await mount(markup({ key: "cmd+k" }), CONTROLLERS)

    document.dispatchEvent(keydown({ key: "k" })) // no metaKey

    expect(fired).toHaveLength(0)
  })

  // Exact-match, not "at least these modifiers" — the same guarantee R8a demands from
  // a single Stimulus key-filter descriptor, applied here across an arbitrary combo
  // parsed from one value instead of hand-declared per descriptor.
  test("does not fire when an EXTRA, unrequested modifier is held", async () => {
    const fired = captureEvents("cw--hotkey:fired")
    await mount(markup({ key: "cmd+k" }), CONTROLLERS)

    document.dispatchEvent(keydown({ key: "k", metaKey: true, shiftKey: true }))

    expect(fired).toHaveLength(0)
  })

  test("shift must be explicit: 'shift+?' matches Shift+/ producing '?'", async () => {
    const fired = captureEvents("cw--hotkey:fired")
    await mount(markup({ key: "shift+?" }), CONTROLLERS)

    document.dispatchEvent(keydown({ key: "?", shiftKey: true }))

    expect(fired).toHaveLength(1)
  })

  test("key matching is case-insensitive on the letter itself", async () => {
    const fired = captureEvents("cw--hotkey:fired")
    await mount(markup({ key: "cmd+K" }), CONTROLLERS)

    document.dispatchEvent(keydown({ key: "k", metaKey: true }))

    expect(fired).toHaveLength(1)
  })

  // --- typing-context suppression -----------------------------------------------------

  test("a modifier-less binding is suppressed while typing in an input", async () => {
    document.body.innerHTML = `
      <input id="search">
      ${markup({ key: "/", tag: "div" })}
    `
    const { Application } = await import("@hotwired/stimulus")
    const application = Application.start()
    application.register("cw--hotkey", HotkeyController)
    await nextFrame()

    const fired = captureEvents("cw--hotkey:fired")
    const input = document.getElementById("search")
    input.dispatchEvent(keydown({ key: "/", bubbles: true }))

    expect(fired).toHaveLength(0)

    // Clear the DOM and let Stimulus's own MutationObserver fire disconnect() for
    // real BEFORE stopping the application — Application#stop() alone does not call
    // disconnect() on still-connected controllers (see test/js/setup.js), and this
    // controller's window-level keydown listener would otherwise leak into every
    // later test in this file.
    document.body.innerHTML = ""
    await nextFrame()
    application.stop()
  })

  test("a chord WITH a modifier still fires while typing in an input", async () => {
    document.body.innerHTML = `
      <input id="search">
      ${markup({ key: "cmd+k", tag: "div" })}
    `
    const { Application } = await import("@hotwired/stimulus")
    const application = Application.start()
    application.register("cw--hotkey", HotkeyController)
    await nextFrame()

    const fired = captureEvents("cw--hotkey:fired")
    const input = document.getElementById("search")
    input.dispatchEvent(keydown({ key: "k", metaKey: true, bubbles: true }))

    expect(fired).toHaveLength(1)

    // See the teardown-order note in the previous test.
    document.body.innerHTML = ""
    await nextFrame()
    application.stop()
  })

  test("suppressed inside a contenteditable region", async () => {
    document.body.innerHTML = `
      <div id="editor" contenteditable="true"><span id="inner">text</span></div>
      ${markup({ key: "/", tag: "div" })}
    `
    const { Application } = await import("@hotwired/stimulus")
    const application = Application.start()
    application.register("cw--hotkey", HotkeyController)
    await nextFrame()

    const fired = captureEvents("cw--hotkey:fired")
    document.getElementById("inner").dispatchEvent(keydown({ key: "/", bubbles: true }))

    expect(fired).toHaveLength(0)

    // See the teardown-order note above.
    document.body.innerHTML = ""
    await nextFrame()
    application.stop()
  })

  // --- isComposing / repeat ---------------------------------------------------------

  test("ignores events fired mid IME composition", async () => {
    const fired = captureEvents("cw--hotkey:fired")
    await mount(markup({ key: "/" }), CONTROLLERS)

    document.dispatchEvent(keydown({ key: "/", isComposing: true }))

    expect(fired).toHaveLength(0)
  })

  test("ignores auto-repeat keydowns", async () => {
    const fired = captureEvents("cw--hotkey:fired")
    await mount(markup({ key: "/" }), CONTROLLERS)

    document.dispatchEvent(keydown({ key: "/", repeat: true }))

    expect(fired).toHaveLength(0)
  })

  // --- preventDefault -----------------------------------------------------------------

  test("calls preventDefault by default on a match", async () => {
    await mount(markup({ key: "/" }), CONTROLLERS)

    const event = keydown({ key: "/" })
    document.dispatchEvent(event)

    expect(event.defaultPrevented).toBe(true)
  })

  test("does not call preventDefault when preventDefault value is false", async () => {
    await mount(markup({ key: "/", preventDefault: false }), CONTROLLERS)

    const event = keydown({ key: "/" })
    document.dispatchEvent(event)

    expect(event.defaultPrevented).toBe(false)
  })

  // --- "just click me" ----------------------------------------------------------------

  test("performs a synthetic click on the element on a match", async () => {
    const el = await mount(markup({ key: "cmd+k" }), CONTROLLERS)
    let clicked = false
    el.addEventListener("click", () => { clicked = true })

    document.dispatchEvent(keydown({ key: "k", metaKey: true }))

    expect(clicked).toBe(true)
  })

  test("the synthetic click composes with the element's own click-bound action", async () => {
    document.body.innerHTML = `
      <button data-controller="cw--hotkey cw--dismiss"
              data-cw--hotkey-key-value="cmd+k"
              data-action="click->cw--dismiss#dismiss">Close</button>`
    const { Application } = await import("@hotwired/stimulus")
    const DismissController = (await import("../../app/assets/javascripts/crosswire/controllers/dismiss_controller.js")).default
    const application = Application.start()
    application.register("cw--hotkey", HotkeyController)
    application.register("cw--dismiss", DismissController)
    await nextFrame()

    const button = document.querySelector("button")
    document.dispatchEvent(keydown({ key: "k", metaKey: true }))
    await nextFrame()

    expect(button.isConnected).toBe(false)

    application.stop()
  })

  // --- scope ---------------------------------------------------------------------------

  test("scope 'window' fires regardless of where the event originates", async () => {
    const fired = captureEvents("cw--hotkey:fired")
    await mount(markup({ key: "cmd+k", scope: "window" }), CONTROLLERS)

    window.dispatchEvent(keydown({ key: "k", metaKey: true }))

    expect(fired).toHaveLength(1)
  })

  test("scope 'element' does not fire for an event dispatched only on window", async () => {
    const fired = captureEvents("cw--hotkey:fired")
    await mount(markup({ key: "cmd+k", scope: "element" }), CONTROLLERS)

    window.dispatchEvent(keydown({ key: "k", metaKey: true }))

    expect(fired).toHaveLength(0)
  })

  test("scope 'element' fires for an event dispatched on the element itself", async () => {
    const fired = captureEvents("cw--hotkey:fired")
    const el = await mount(markup({ key: "cmd+k", scope: "element" }), CONTROLLERS)

    el.dispatchEvent(keydown({ key: "k", metaKey: true }))

    expect(fired).toHaveLength(1)
  })

  // --- R7: exhaustive teardown ---------------------------------------------------------

  test("removes the window listener on disconnect", async () => {
    const fired = captureEvents("cw--hotkey:fired")
    await mount(markup({ key: "cmd+k" }), CONTROLLERS)

    document.body.innerHTML = ""
    await nextFrame()

    window.dispatchEvent(keydown({ key: "k", metaKey: true }))

    expect(fired).toHaveLength(0)
  })
})
