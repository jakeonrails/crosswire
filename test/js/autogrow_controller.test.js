import { afterEach, beforeEach, describe, expect, test, vi } from "vitest"
import AutogrowController from "../../app/assets/javascripts/crosswire/controllers/autogrow_controller.js"
import { mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--autogrow": AutogrowController }

// jsdom does no layout at all: `scrollHeight` is always 0 (docs/COMPONENT_CONTRACT.md's
// gotchas table documents the same absence for `offsetParent`), so this file CANNOT
// honestly test the thing the component claims to do (grow a textarea to fit its
// content). That claim is covered exclusively by autogrow_controller.browser.test.js,
// against a real layout engine.
//
// A second, unrelated environment gap surfaced while writing this: jsdom (as pinned in
// package.json, 25.0.1) implements no global `CSS` object at all — not merely a
// `CSS.supports` that answers "false", but `typeof CSS === "undefined"`, verified
// directly against the pinned jsdom package. The controller guards for that (see its
// connect() comment); this file has to stub `globalThis.CSS` itself to exercise the
// "modern engine, no-op" branch at all.
//
// What jsdom CAN honestly verify: Rule 0 itself — whether the controller checks
// CSS.supports and, based on it, either does nothing (modern engine) or wires up an
// input listener and writes SOME inline height (old engine). Both are true/false facts
// about which code path ran, not about whether a pixel height came out correct, so
// jsdom is an honest witness to them.

function markup({ maxRows = null } = {}) {
  return `<textarea data-controller="cw--autogrow"
                     ${maxRows !== null ? `data-cw--autogrow-max-rows-value="${maxRows}"` : ""}
                     >initial content</textarea>`
}

afterEach(() => {
  vi.unstubAllGlobals()
})

describe("cw--autogrow", () => {
  describe("Rule 0 — field-sizing: content supported", () => {
    beforeEach(() => {
      vi.stubGlobal("CSS", { supports: vi.fn(() => true) })
    })

    test("checks CSS.supports for field-sizing: content before doing anything else", async () => {
      await mount(markup(), CONTROLLERS)
      expect(CSS.supports).toHaveBeenCalledWith("field-sizing", "content")
    })

    test("does not touch the element's height style at all", async () => {
      const el = await mount(markup(), CONTROLLERS)
      expect(el.style.height).toBe("")
    })

    test("does not wire an input listener — typing never changes inline height", async () => {
      const el = await mount(markup(), CONTROLLERS)
      el.value = "a lot more content than before, several lines worth of it now"
      el.dispatchEvent(new Event("input"))
      await nextFrame()

      expect(el.style.height).toBe("")
    })

    test("disconnect does not throw when connect() no-opped", async () => {
      const el = await mount(markup(), CONTROLLERS)
      document.body.innerHTML = ""
      await expect(nextFrame()).resolves.not.toThrow()
      expect(el.isConnected).toBe(false)
    })
  })

  describe("fallback — no CSS.supports available (jsdom's actual environment, and a stand-in for a genuinely old engine)", () => {
    test("wires an input listener and sets an inline pixel height on connect", async () => {
      const el = await mount(markup(), CONTROLLERS)
      // Real sizing accuracy is a browser-tier claim (see autogrow_controller.browser
      // .test.js) — jsdom's scrollHeight is always 0, so all this file can honestly
      // assert is that SOME inline pixel height got written, i.e. the fallback path
      // actually ran rather than silently doing nothing.
      expect(el.style.height).toMatch(/px$/)
    })

    test("hides overflow while measuring", async () => {
      const el = await mount(markup(), CONTROLLERS)
      expect(el.style.overflowY).toBe("hidden")
    })

    test("re-measures on connect — covers a Turbo cache restore bringing back content with no live sizing", async () => {
      // A cache-restored textarea has content but no inline height — a cloned
      // snapshot is inert markup, with no layout baked in. connect() re-growing on
      // every mount (not only reacting to `input`) is what makes that case work,
      // since Stimulus reconnects the controller the same way on a restore as it
      // would on a fresh load.
      const el = await mount(markup(), CONTROLLERS)
      expect(el.style.height).toMatch(/px$/) // grew on the very first connect already
    })

    test("does not throw without a maxRows value", async () => {
      const el = await mount(markup(), CONTROLLERS)
      expect(() => {
        el.value = "more text"
        el.dispatchEvent(new Event("input"))
      }).not.toThrow()
    })

    test("does not throw with a maxRows value set", async () => {
      const el = await mount(markup({ maxRows: 5 }), CONTROLLERS)
      expect(() => {
        el.value = "more text\nand more\nand more still"
        el.dispatchEvent(new Event("input"))
      }).not.toThrow()
    })

    // R7 — the listener registered in connect() must be released in disconnect().
    test("removes the input listener on disconnect", async () => {
      const el = await mount(markup(), CONTROLLERS)
      const removeSpy = vi.spyOn(el, "removeEventListener")

      document.body.innerHTML = ""
      await nextFrame()

      expect(removeSpy).toHaveBeenCalledWith("input", expect.any(Function))
    })
  })

  test("disconnect is a no-op (does not throw) if connect() never wired a listener", async () => {
    vi.stubGlobal("CSS", { supports: vi.fn(() => true) }) // modern engine — no-op branch
    const el = await mount(markup(), CONTROLLERS)

    document.body.innerHTML = ""
    await expect(nextFrame()).resolves.not.toThrow()
    expect(el.isConnected).toBe(false)
  })
})
