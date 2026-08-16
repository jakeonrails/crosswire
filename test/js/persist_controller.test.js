import { afterEach, beforeEach, describe, expect, test, vi } from "vitest"
import PersistController from "../../app/assets/javascripts/crosswire/controllers/persist_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--persist": PersistController }

function markup({ tag = "input", key = "search-filter", attribute = null, storage = null,
  debounce = null, type = null, checked = null, open = null, extraAttrs = "" } = {}) {
  const attrs = [
    `data-cw--persist-key-value="${key}"`,
    attribute ? `data-cw--persist-attribute-value="${attribute}"` : "",
    storage ? `data-cw--persist-storage-value="${storage}"` : "",
    debounce !== null ? `data-cw--persist-debounce-value="${debounce}"` : "",
    type ? `type="${type}"` : "",
    checked !== null ? "checked" : "",
    open !== null ? "open" : "",
    extraAttrs
  ].filter(Boolean).join(" ")

  return `<${tag} data-controller="cw--persist" ${attrs}></${tag}>`
}

async function waitFor(predicate, { timeout = 2000, interval = 5 } = {}) {
  const start = Date.now()
  while (!predicate()) {
    if (Date.now() - start > timeout) throw new Error("waitFor: condition never became true")
    await new Promise((resolve) => setTimeout(resolve, interval))
  }
}

describe("cw--persist", () => {
  beforeEach(() => {
    window.localStorage.clear()
    window.sessionStorage.clear()
  })

  test("restores a previously saved value on connect", async () => {
    window.localStorage.setItem('cw--persist:search-filter', JSON.stringify("hello"))

    const el = await mount(markup(), CONTROLLERS)

    expect(el.value).toBe("hello")
  })

  test("does nothing on connect when nothing was stored yet", async () => {
    const el = await mount(markup(), CONTROLLERS)
    expect(el.value).toBe("")
  })

  test("saves the value to localStorage on input", async () => {
    const el = await mount(markup(), CONTROLLERS)

    el.value = "widgets"
    el.dispatchEvent(new Event("input", { bubbles: true }))

    await waitFor(() => window.localStorage.getItem("cw--persist:search-filter") !== null)
    expect(JSON.parse(window.localStorage.getItem("cw--persist:search-filter"))).toBe("widgets")
  })

  test("dispatches restored on connect and saved on write", async () => {
    const restored = captureEvents("cw--persist:restored")
    const saved = captureEvents("cw--persist:saved")

    const el = await mount(markup(), CONTROLLERS)
    expect(restored).toHaveLength(1)
    expect(restored[0].detail.found).toBe(false)

    el.value = "x"
    el.dispatchEvent(new Event("input", { bubbles: true }))
    await waitFor(() => saved.length === 1)
    expect(saved[0].detail.value).toBe("x")
  })

  test("persists checked state for a checkbox", async () => {
    window.localStorage.setItem('cw--persist:remember-me', JSON.stringify(true))

    const el = await mount(markup({ key: "remember-me", attribute: "checked", type: "checkbox" }), CONTROLLERS)
    expect(el.checked).toBe(true)

    el.checked = false
    el.dispatchEvent(new Event("change", { bubbles: true }))
    await waitFor(() => JSON.parse(window.localStorage.getItem("cw--persist:remember-me")) === false)
  })

  test("persists the open state of a details element via the toggle event", async () => {
    const el = await mount(markup({ tag: "details", key: "faq-1", attribute: "open" }), CONTROLLERS)
    expect(el.open).toBe(false)

    el.open = true
    el.dispatchEvent(new Event("toggle", { bubbles: true }))

    await waitFor(() => JSON.parse(window.localStorage.getItem("cw--persist:faq-1")) === true)
  })

  test("persists an arbitrary attribute via a MutationObserver, not input/change", async () => {
    const el = await mount(markup({ tag: "div", key: "sidebar", attribute: "data-state" }), CONTROLLERS)

    el.setAttribute("data-state", "collapsed")
    await waitFor(() => window.localStorage.getItem("cw--persist:sidebar") !== null)
    expect(JSON.parse(window.localStorage.getItem("cw--persist:sidebar"))).toBe("collapsed")
  })

  test("reapplies state and does not restore twice with debounce collapsing rapid writes", async () => {
    const el = await mount(markup({ debounce: 50 }), CONTROLLERS)
    const saved = captureEvents("cw--persist:saved")

    for (const value of ["a", "ab", "abc"]) {
      el.value = value
      el.dispatchEvent(new Event("input", { bubbles: true }))
    }

    // Immediately after firing three rapid inputs, nothing should have saved yet.
    expect(saved).toHaveLength(0)

    await waitFor(() => saved.length === 1, { timeout: 500 })
    expect(saved[0].detail.value).toBe("abc")
  })

  test("reapplies on turbo:morph-element, scoped to this element (not a page-wide morph)", async () => {
    window.localStorage.setItem('cw--persist:search-filter', JSON.stringify("restored-value"))
    const el = await mount(markup(), CONTROLLERS)

    // Simulate what Turbo 8 morphing does: it can leave the DOM property stale while
    // skipping connect() entirely (turbo#1210).
    el.value = ""

    el.dispatchEvent(new CustomEvent("turbo:morph-element", { bubbles: true }))
    await waitFor(() => el.value === "restored-value")
  })

  test("ignores a bubbled turbo:morph-element that targets a descendant, not itself", async () => {
    const el = await mount(markup({ tag: "div", key: "wrapper", attribute: "data-state" }), CONTROLLERS)
    el.setAttribute("data-state", "open")
    await waitFor(() => window.localStorage.getItem("cw--persist:wrapper") !== null)

    const restored = captureEvents("cw--persist:restored")
    const child = document.createElement("span")
    el.appendChild(child)
    child.dispatchEvent(new CustomEvent("turbo:morph-element", { bubbles: true }))

    await nextFrame()
    expect(restored).toHaveLength(0)
  })

  test("refuses to persist a password field and warns once", async () => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {})

    const el = await mount(markup({ type: "password", key: "secret" }), CONTROLLERS)
    el.value = "hunter2"
    el.dispatchEvent(new Event("input", { bubbles: true }))
    await nextFrame()

    expect(window.localStorage.getItem("cw--persist:secret")).toBeNull()
    expect(warn).toHaveBeenCalledTimes(1)

    warn.mockRestore()
  })

  test("refuses to persist when no key is given, and warns once", async () => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {})

    const el = await mount('<input data-controller="cw--persist">', CONTROLLERS)

    el.value = "x"
    el.dispatchEvent(new Event("input", { bubbles: true }))
    await nextFrame()

    expect(window.localStorage.getItem("cw--persist:")).toBeNull()
    expect(warn).toHaveBeenCalledTimes(1)

    warn.mockRestore()
  })

  test("degrades silently to an in-memory fallback when storage throws", async () => {
    const original = window.localStorage.setItem
    window.localStorage.setItem = () => { throw new Error("QuotaExceededError") }

    try {
      const el = await mount(markup({ key: "quota-test" }), CONTROLLERS)
      el.value = "still works"
      el.dispatchEvent(new Event("input", { bubbles: true }))

      const saved = captureEvents("cw--persist:saved")
      el.value = "again"
      el.dispatchEvent(new Event("input", { bubbles: true }))
      await waitFor(() => saved.length === 1)
      expect(saved[0].detail.value).toBe("again")
    } finally {
      window.localStorage.setItem = original
    }
  })

  test("uses sessionStorage when storage is session", async () => {
    const el = await mount(markup({ key: "wizard-step", storage: "session" }), CONTROLLERS)
    el.value = "3"
    el.dispatchEvent(new Event("input", { bubbles: true }))

    await waitFor(() => window.sessionStorage.getItem("cw--persist:wizard-step") !== null)
    expect(window.localStorage.getItem("cw--persist:wizard-step")).toBeNull()
  })

  test("teardown removes listeners so a later input on a disconnected element does not save", async () => {
    const el = await mount(markup({ key: "teardown-test" }), CONTROLLERS)
    el.remove()
    await nextFrame()

    el.value = "should not persist"
    el.dispatchEvent(new Event("input", { bubbles: true }))
    await nextFrame()

    expect(window.localStorage.getItem("cw--persist:teardown-test")).toBeNull()
  })
})
