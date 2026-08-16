import { describe, expect, test } from "vitest"
import CharCountController from "../../app/assets/javascripts/crosswire/controllers/char_count_controller.js"
import { mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--char-count": CharCountController }

function markup({ max = 20, warnAt = null, value = "", overClass = null, warnClass = null } = {}) {
  return `
    <div data-controller="cw--char-count"
         data-cw--char-count-max-value="${max}"
         ${warnAt !== null ? `data-cw--char-count-warn-at-value="${warnAt}"` : ""}
         ${overClass ? `data-cw--char-count-over-class="${overClass}"` : ""}
         ${warnClass ? `data-cw--char-count-warn-class="${warnClass}"` : ""}>
      <textarea data-cw--char-count-target="input"
                data-action="input->cw--char-count#update">${value}</textarea>
      <output data-cw--char-count-target="output" aria-live="polite"></output>
    </div>`
}

async function waitFor(predicate, { timeout = 2000, interval = 5 } = {}) {
  const start = Date.now()
  while (!predicate()) {
    if (Date.now() - start > timeout) throw new Error("waitFor: condition never became true")
    await new Promise((resolve) => setTimeout(resolve, interval))
  }
}

function input(el, value) {
  const field = el.querySelector("textarea")
  field.value = value
  field.dispatchEvent(new Event("input", { bubbles: true }))
}

describe("cw--char-count", () => {
  test("renders the initial count immediately on connect, without waiting for the debounce", async () => {
    const el = await mount(markup({ max: 20, value: "hello" }), CONTROLLERS)
    expect(el.querySelector("output").textContent).toBe("15 characters remaining")
  })

  test("updates the count after the debounce window, not on every keystroke", async () => {
    const el = await mount(markup({ max: 20 }), CONTROLLERS)
    const output = el.querySelector("output")

    input(el, "a")
    input(el, "ab")
    input(el, "abc")

    // Nothing should have rendered yet — the writes are debounced.
    expect(output.textContent).toBe("20 characters remaining")

    await waitFor(() => output.textContent === "17 characters remaining")
  })

  test("counts grapheme clusters, not UTF-16 code units", async () => {
    const el = await mount(markup({ max: 20 }), CONTROLLERS)
    input(el, "👨‍👩‍👧") // one grapheme cluster, eight UTF-16 code units
    await waitFor(() => el.querySelector("output").textContent === "19 characters remaining")
  })

  test("flips to the over-limit message and aria-invalid past max", async () => {
    const el = await mount(markup({ max: 5 }), CONTROLLERS)
    const field = el.querySelector("textarea")

    input(el, "far too long")
    await waitFor(() => el.querySelector("output").textContent.includes("over"))

    expect(el.querySelector("output").textContent).toBe("7 characters over limit")
    expect(field.getAttribute("aria-invalid")).toBe("true")
  })

  test("clears aria-invalid once back under the limit", async () => {
    const el = await mount(markup({ max: 5 }), CONTROLLERS)
    const field = el.querySelector("textarea")

    input(el, "too long")
    await waitFor(() => field.getAttribute("aria-invalid") === "true")

    input(el, "ok")
    await waitFor(() => field.getAttribute("aria-invalid") === null)
  })

  test("applies the warn class near the limit and the over class past it", async () => {
    const el = await mount(markup({ max: 10, warnAt: 0.8, overClass: "is-over", warnClass: "is-warn" }), CONTROLLERS)

    input(el, "12345678") // 8/10 used, 2 remaining <= 10 * (1 - 0.8) = 2 -> warn
    await waitFor(() => el.classList.contains("is-warn"))
    expect(el.classList.contains("is-over")).toBe(false)

    input(el, "123456789012") // over
    await waitFor(() => el.classList.contains("is-over"))
    expect(el.classList.contains("is-warn")).toBe(false)
  })

  // R3 — Stimulus throws on this.fooClass when the attribute is absent.
  test("does not throw when no warn/over classes are given", async () => {
    const el = await mount(markup({ max: 5 }), CONTROLLERS)
    expect(() => input(el, "way too long for the limit")).not.toThrow()
    await waitFor(() => el.querySelector("output").textContent.includes("over"))
  })

  test("does nothing when there is no input target", async () => {
    const el = await mount(`<div data-controller="cw--char-count" data-cw--char-count-max-value="10"></div>`, CONTROLLERS)
    await nextFrame()
    expect(el.querySelector("output")).toBeNull()
  })

  test("teardown cancels a pending debounce so a later keystroke on a detached node cannot render", async () => {
    const el = await mount(markup({ max: 20 }), CONTROLLERS)
    const output = el.querySelector("output")
    expect(output.textContent).toBe("20 characters remaining") // the immediate connect() render

    input(el, "abc")
    el.remove()
    await nextFrame()

    // Give the original debounce window plenty of time to have fired if it were not
    // cancelled — if disconnect() failed to clear the timer this would flip to "17
    // characters remaining" even though the controller (and element) are gone.
    await new Promise((resolve) => setTimeout(resolve, 400))
    expect(output.textContent).toBe("20 characters remaining")
  })
})
