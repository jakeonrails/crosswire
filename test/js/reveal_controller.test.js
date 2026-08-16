import { describe, expect, test } from "vitest"
import RevealController from "../../app/assets/javascripts/crosswire/controllers/reveal_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--reveal": RevealController }

function markup({ revealed = false, revealedClass = null } = {}) {
  return `
    <div data-controller="cw--reveal"
         data-cw--reveal-revealed-value="${revealed}"
         ${revealedClass ? `data-cw--reveal-revealed-class="${revealedClass}"` : ""}>
      <input data-cw--reveal-target="input"
             type="${revealed ? "text" : "password"}" value="hunter2">
      <button data-cw--reveal-target="trigger"
              data-action="click->cw--reveal#toggle"
              type="button" aria-pressed="${revealed}">Show password</button>
    </div>`
}

describe("cw--reveal", () => {
  test("renders masked on connect by default", async () => {
    const el = await mount(markup(), CONTROLLERS)
    expect(el.querySelector("input").type).toBe("password")
    expect(el.querySelector("button").getAttribute("aria-pressed")).toBe("false")
  })

  test("toggle flips the input to text and aria-pressed to true", async () => {
    const el = await mount(markup(), CONTROLLERS)
    el.querySelector("button").click()
    await nextFrame()

    expect(el.querySelector("input").type).toBe("text")
    expect(el.querySelector("button").getAttribute("aria-pressed")).toBe("true")
  })

  test("toggle again restores password and aria-pressed to false", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const button = el.querySelector("button")
    button.click()
    await nextFrame()
    button.click()
    await nextFrame()

    expect(el.querySelector("input").type).toBe("password")
    expect(button.getAttribute("aria-pressed")).toBe("false")
  })

  test("server-rendered revealed state is honoured without a click", async () => {
    const el = await mount(markup({ revealed: true }), CONTROLLERS)
    expect(el.querySelector("input").type).toBe("text")
    expect(el.querySelector("button").getAttribute("aria-pressed")).toBe("true")
  })

  // Never clear or replace the input's value when flipping type.
  test("flipping type never touches the input's value", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const input = el.querySelector("input")
    expect(input.value).toBe("hunter2")

    el.querySelector("button").click()
    await nextFrame()

    expect(input.value).toBe("hunter2")
  })

  test("dispatches revealed and hidden", async () => {
    const revealed = captureEvents("cw--reveal:revealed")
    const hidden = captureEvents("cw--reveal:hidden")
    const el = await mount(markup(), CONTROLLERS)
    const button = el.querySelector("button")

    button.click()
    await nextFrame()
    expect(revealed).toHaveLength(1)
    expect(revealed[0].detail.revealed).toBe(true)

    button.click()
    await nextFrame()
    expect(hidden).toHaveLength(1)
  })

  test("does not announce on initial connect", async () => {
    const revealed = captureEvents("cw--reveal:revealed")
    await mount(markup({ revealed: true }), CONTROLLERS)
    expect(revealed).toHaveLength(0)
  })

  test("applies the revealed class when given", async () => {
    const el = await mount(markup({ revealedClass: "is-revealed" }), CONTROLLERS)
    el.querySelector("button").click()
    await nextFrame()
    expect(el.classList.contains("is-revealed")).toBe(true)
  })

  // R3 — Stimulus throws on this.fooClass when the attribute is absent.
  test("does not throw when no revealed class is given", async () => {
    const el = await mount(markup(), CONTROLLERS)
    expect(() => el.querySelector("button").click()).not.toThrow()
    await nextFrame()
    expect(el.querySelector("input").type).toBe("text")
  })

  // R4 — the value is the single write path.
  test("changing the value attribute externally updates the DOM", async () => {
    const el = await mount(markup(), CONTROLLERS)
    el.setAttribute("data-cw--reveal-revealed-value", "true")
    await nextFrame()
    expect(el.querySelector("input").type).toBe("text")
  })

  // R7 — the general-purpose teardown: whatever the reason the controller
  // disconnects, a revealed password field must not stay type="text", AND the
  // underlying value must be corrected too — not just the live DOM. See the
  // controller docstring: writing `input.type` alone and leaving a stale
  // data-cw--reveal-revealed-value="true" attribute is exactly the bug this guards
  // against, since that stale attribute is what a LATER Turbo cache restore reads
  // back on connect().
  test("disconnect() restores type=password and the underlying value, even if the field was revealed", async () => {
    const el = await mount(markup(), CONTROLLERS)
    el.querySelector("button").click()
    await nextFrame()
    const input = el.querySelector("input")
    expect(input.type).toBe("text")

    document.body.innerHTML = ""
    await nextFrame()

    expect(input.type).toBe("password")
    expect(el.getAttribute("data-cw--reveal-revealed-value")).toBe("false")
  })

  // The Turbo-specific half of the cache-leak fix: turbo:before-cache fires on the
  // LIVE document, before Turbo clones it into the snapshot cache — earlier than
  // disconnect() ever runs — which is exactly the case a "reveal, then click a
  // normal in-app link" sequence needs covered. It must ALSO correct the underlying
  // value (not just the DOM), and the controller must remain fully usable afterwards
  // if, for whatever reason, no navigation actually follows.
  test("turbo:before-cache restores type=password and the value, and the controller stays usable", async () => {
    const el = await mount(markup(), CONTROLLERS)
    el.querySelector("button").click()
    await nextFrame()
    const input = el.querySelector("input")
    expect(input.type).toBe("text")

    document.dispatchEvent(new Event("turbo:before-cache"))

    expect(input.type).toBe("password")
    expect(el.getAttribute("data-cw--reveal-revealed-value")).toBe("false")
    expect(input.isConnected).toBe(true) // still attached — this isn't a teardown

    // Toggling again afterwards must genuinely reveal it — proving the DOM and the
    // value are still in sync, not desynced by the reset.
    el.querySelector("button").click()
    await nextFrame()
    expect(input.type).toBe("text")
  })

  test("removes the turbo:before-cache listener on disconnect", async () => {
    const addSpy = []
    const originalAdd = document.addEventListener.bind(document)
    const originalRemove = document.removeEventListener.bind(document)
    document.addEventListener = (...args) => {
      if (args[0] === "turbo:before-cache") addSpy.push("add")
      return originalAdd(...args)
    }
    document.removeEventListener = (...args) => {
      if (args[0] === "turbo:before-cache") addSpy.push("remove")
      return originalRemove(...args)
    }

    await mount(markup(), CONTROLLERS)
    document.body.innerHTML = ""
    await nextFrame()

    document.addEventListener = originalAdd
    document.removeEventListener = originalRemove

    expect(addSpy).toEqual(["add", "remove"])
  })
})
