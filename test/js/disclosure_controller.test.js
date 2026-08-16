import { describe, expect, test } from "vitest"
import DisclosureController from "../../app/assets/javascripts/crosswire/controllers/disclosure_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--disclosure": DisclosureController }

function markup({ open = false, openClass = null } = {}) {
  return `
    <div data-controller="cw--disclosure"
         data-cw--disclosure-open-value="${open}"
         ${openClass ? `data-cw--disclosure-open-class="${openClass}"` : ""}>
      <button data-cw--disclosure-target="trigger"
              data-action="click->cw--disclosure#toggle"
              aria-expanded="${open}">Details</button>
      <div data-cw--disclosure-target="panel" ${open ? "" : "hidden"}>Panel</div>
    </div>`
}

describe("cw--disclosure", () => {
  test("renders closed state on connect", async () => {
    const el = await mount(markup(), CONTROLLERS)
    expect(el.querySelector("[data-cw--disclosure-target='panel']").hidden).toBe(true)
    expect(el.querySelector("button").getAttribute("aria-expanded")).toBe("false")
  })

  test("toggle opens and keeps aria-expanded in sync", async () => {
    const el = await mount(markup(), CONTROLLERS)
    el.querySelector("button").click()
    await nextFrame()

    expect(el.querySelector("[data-cw--disclosure-target='panel']").hidden).toBe(false)
    expect(el.querySelector("button").getAttribute("aria-expanded")).toBe("true")
  })

  test("server-rendered open state is honoured without a click", async () => {
    const el = await mount(markup({ open: true }), CONTROLLERS)
    expect(el.querySelector("[data-cw--disclosure-target='panel']").hidden).toBe(false)
  })

  test("dispatches opened and closed", async () => {
    const opened = captureEvents("cw--disclosure:opened")
    const closed = captureEvents("cw--disclosure:closed")
    const el = await mount(markup(), CONTROLLERS)

    el.querySelector("button").click()
    await nextFrame()
    expect(opened).toHaveLength(1)
    expect(opened[0].detail.open).toBe(true)

    el.querySelector("button").click()
    await nextFrame()
    expect(closed).toHaveLength(1)
  })

  test("does not announce on initial connect", async () => {
    const opened = captureEvents("cw--disclosure:opened")
    await mount(markup({ open: true }), CONTROLLERS)
    expect(opened).toHaveLength(0)
  })

  test("applies the open class when given", async () => {
    const el = await mount(markup({ openClass: "is-open" }), CONTROLLERS)
    el.querySelector("button").click()
    await nextFrame()
    expect(el.classList.contains("is-open")).toBe(true)
  })

  // R3 — Stimulus throws on this.fooClass when the attribute is absent.
  test("does not throw when no open class is given", async () => {
    const el = await mount(markup(), CONTROLLERS)
    expect(() => el.querySelector("button").click()).not.toThrow()
    await nextFrame()
    expect(el.querySelector("[data-cw--disclosure-target='panel']").hidden).toBe(false)
  })

  // R4 — the value is the single write path, so a server-driven change converges
  // on the same code as a click. This is what survives a Turbo morph.
  test("changing the value attribute externally updates the DOM", async () => {
    const el = await mount(markup(), CONTROLLERS)
    el.setAttribute("data-cw--disclosure-open-value", "true")
    await nextFrame()
    expect(el.querySelector("[data-cw--disclosure-target='panel']").hidden).toBe(false)
  })
})
