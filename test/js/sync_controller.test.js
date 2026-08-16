import { describe, expect, test } from "vitest"
import SyncController from "../../app/assets/javascripts/crosswire/controllers/sync_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--sync": SyncController }

function markup({ tag = "input", target = "#target", attribute = null, transform = null, value = "" } = {}) {
  const valueAttr = tag === "textarea" ? "" : `value="${value}"`
  const inner = tag === "textarea" ? value : ""

  return `
    <${tag} data-controller="cw--sync"
            data-cw--sync-target-value="${target}"
            ${attribute ? `data-cw--sync-attribute-value="${attribute}"` : ""}
            ${transform ? `data-cw--sync-transform-value="${transform}"` : ""}
            data-action="input->cw--sync#sync change->cw--sync#sync"
            ${valueAttr}>${inner}</${tag}>
    <input id="target">`
}

describe("cw--sync", () => {
  test("mirrors the initial value onto the target on connect", async () => {
    await mount(markup({ value: "hello" }), CONTROLLERS)
    expect(document.getElementById("target").value).toBe("hello")
  })

  test("mirrors on input", async () => {
    const el = await mount(markup(), CONTROLLERS)
    el.value = "typed"
    el.dispatchEvent(new Event("input", { bubbles: true }))
    await nextFrame()

    expect(document.getElementById("target").value).toBe("typed")
  })

  test("mirrors on change", async () => {
    const el = await mount(markup(), CONTROLLERS)
    el.value = "changed"
    el.dispatchEvent(new Event("change", { bubbles: true }))
    await nextFrame()

    expect(document.getElementById("target").value).toBe("changed")
  })

  test("dispatches synced with the written value and target", async () => {
    const synced = captureEvents("cw--sync:synced")
    await mount(markup({ value: "abc" }), CONTROLLERS)

    expect(synced).toHaveLength(1)
    expect(synced[0].detail.value).toBe("abc")
    expect(synced[0].detail.target).toBe(document.getElementById("target"))
  })

  // --- reading: checkbox/radio read .checked, not .value ----------------------------

  test("reads .checked for a checkbox source", async () => {
    await mount(
      `<input type="checkbox" checked
              data-controller="cw--sync"
              data-cw--sync-target-value="#target"
              data-cw--sync-attribute-value="checked"
              data-action="input->cw--sync#sync change->cw--sync#sync">
       <input type="checkbox" id="target">`,
      CONTROLLERS
    )

    expect(document.getElementById("target").checked).toBe(true)
  })

  // --- writing: property when present, setAttribute otherwise -----------------------

  test("writes textContent for a character-counter-style target", async () => {
    await mount(markup({ tag: "textarea", value: "hi", attribute: "textContent", transform: "length" }), CONTROLLERS)
    expect(document.getElementById("target").textContent).toBe("2")
  })

  test("falls back to setAttribute when the target has no matching property", async () => {
    await mount(
      `<input data-controller="cw--sync"
              data-cw--sync-target-value="#target"
              data-cw--sync-attribute-value="data-mirrored"
              data-action="input->cw--sync#sync change->cw--sync#sync"
              value="abc">
       <div id="target"></div>`,
      CONTROLLERS
    )

    expect(document.getElementById("target").getAttribute("data-mirrored")).toBe("abc")
  })

  // --- transforms ---------------------------------------------------------------------

  test("transform: length", async () => {
    await mount(markup({ value: "hello", transform: "length" }), CONTROLLERS)
    expect(document.getElementById("target").value).toBe("5")
  })

  test("transform: uppercase", async () => {
    await mount(markup({ value: "shout", transform: "uppercase" }), CONTROLLERS)
    expect(document.getElementById("target").value).toBe("SHOUT")
  })

  test("transform: lowercase", async () => {
    await mount(markup({ value: "QUIET", transform: "lowercase" }), CONTROLLERS)
    expect(document.getElementById("target").value).toBe("quiet")
  })

  test("transform: none passes the value through unchanged", async () => {
    await mount(markup({ value: "Plain", transform: "none" }), CONTROLLERS)
    expect(document.getElementById("target").value).toBe("Plain")
  })

  // --- resilience: never throws even when misconfigured ------------------------------

  test("does nothing and does not throw when the target selector matches nothing", async () => {
    const el = await mount(markup({ target: "#does-not-exist" }), CONTROLLERS)
    expect(() => {
      el.value = "x"
      el.dispatchEvent(new Event("input", { bubbles: true }))
    }).not.toThrow()
  })

  test("does not throw on an invalid CSS selector", async () => {
    await expect(mount(markup({ target: "###not-valid" }), CONTROLLERS)).resolves.toBeTruthy()
  })

  test("does not throw when no target value is configured at all", async () => {
    await expect(
      mount(`<input data-controller="cw--sync" data-action="input->cw--sync#sync">`, CONTROLLERS)
    ).resolves.toBeTruthy()
  })
})
