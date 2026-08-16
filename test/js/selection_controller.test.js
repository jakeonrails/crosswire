import { describe, expect, test } from "vitest"
import SelectionController from "../../app/assets/javascripts/crosswire/controllers/selection_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--selection": SelectionController }

// jsdom does support `.checked` and the `.indeterminate` DOM property honestly (this
// is not layout/focus-order territory — see the gotchas table in
// docs/COMPONENT_CONTRACT.md, which is specifically about offsetParent/:modal/tab
// order, none of which this controller touches), so the whole indeterminate contract
// is fairly tested here in jsdom, not pushed to a browser tier.
function markup({ items = [false, false, false], toolbar = true } = {}) {
  const itemsHtml = items
    .map((checked, i) =>
      `<input type="checkbox" data-cw--selection-target="item"
              data-action="change->cw--selection#refresh"
              ${checked ? "checked" : ""} id="item-${i}">`)
    .join("")

  return `
    <div data-controller="cw--selection">
      <input type="checkbox" data-cw--selection-target="all"
             data-action="change->cw--selection#toggleAll">
      <output data-cw--selection-target="count"></output>
      ${itemsHtml}
      ${toolbar ? `<button type="button" data-cw--selection-target="action">Archive</button>` : ""}
    </div>`
}

function items(el) {
  return Array.from(el.querySelectorAll("[data-cw--selection-target='item']"))
}

describe("cw--selection", () => {
  // --- indeterminate: re-derived, never trusted from markup ------------------------

  test("connect re-derives indeterminate when some but not all items are pre-checked", async () => {
    const el = await mount(markup({ items: [true, false, false] }), CONTROLLERS)
    const all = el.querySelector("[data-cw--selection-target='all']")

    expect(all.checked).toBe(false)
    expect(all.indeterminate).toBe(true)
  })

  test("connect sets all checked and not indeterminate when every item is pre-checked", async () => {
    const el = await mount(markup({ items: [true, true, true] }), CONTROLLERS)
    const all = el.querySelector("[data-cw--selection-target='all']")

    expect(all.checked).toBe(true)
    expect(all.indeterminate).toBe(false)
  })

  test("connect leaves all unchecked and not indeterminate when nothing is checked", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const all = el.querySelector("[data-cw--selection-target='all']")

    expect(all.checked).toBe(false)
    expect(all.indeterminate).toBe(false)
  })

  // --- toggleAll ---------------------------------------------------------------------

  test("checking the all checkbox checks every item", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const all = el.querySelector("[data-cw--selection-target='all']")

    all.checked = true
    all.dispatchEvent(new Event("change", { bubbles: true }))
    await nextFrame()

    expect(items(el).every((item) => item.checked)).toBe(true)
  })

  test("unchecking the all checkbox unchecks every item", async () => {
    const el = await mount(markup({ items: [true, true, true] }), CONTROLLERS)
    const all = el.querySelector("[data-cw--selection-target='all']")

    all.checked = false
    all.dispatchEvent(new Event("change", { bubbles: true }))
    await nextFrame()

    expect(items(el).some((item) => item.checked)).toBe(false)
  })

  // --- item change recomputes count / all / indeterminate ---------------------------

  test("checking one of three items sets indeterminate and updates the count", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const [first] = items(el)
    const all = el.querySelector("[data-cw--selection-target='all']")
    const count = el.querySelector("[data-cw--selection-target='count']")

    first.checked = true
    first.dispatchEvent(new Event("change", { bubbles: true }))
    await nextFrame()

    expect(all.indeterminate).toBe(true)
    expect(count.textContent).toBe("1 selected")
  })

  test("checking every item checks all and clears indeterminate", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const all = el.querySelector("[data-cw--selection-target='all']")

    items(el).forEach((item) => {
      item.checked = true
      item.dispatchEvent(new Event("change", { bubbles: true }))
    })
    await nextFrame()

    expect(all.checked).toBe(true)
    expect(all.indeterminate).toBe(false)
  })

  test("count is empty text when nothing is selected", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const count = el.querySelector("[data-cw--selection-target='count']")

    expect(count.textContent).toBe("")
  })

  // --- toolbar enable/disable ---------------------------------------------------------

  test("action targets are disabled while nothing is selected", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const action = el.querySelector("[data-cw--selection-target='action']")

    expect(action.disabled).toBe(true)
    expect(action.getAttribute("aria-disabled")).toBe("true")
  })

  test("action targets enable once something is selected", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const [first] = items(el)
    const action = el.querySelector("[data-cw--selection-target='action']")

    first.checked = true
    first.dispatchEvent(new Event("change", { bubbles: true }))
    await nextFrame()

    expect(action.disabled).toBe(false)
    expect(action.getAttribute("aria-disabled")).toBe("false")
  })

  test("action targets re-disable once the last selection is cleared", async () => {
    const el = await mount(markup({ items: [true, false, false] }), CONTROLLERS)
    const [first] = items(el)
    const action = el.querySelector("[data-cw--selection-target='action']")

    expect(action.disabled).toBe(false)

    first.checked = false
    first.dispatchEvent(new Event("change", { bubbles: true }))
    await nextFrame()

    expect(action.disabled).toBe(true)
  })

  // --- itemTargetConnected/Disconnected: Turbo Stream rows keep state correct ------

  test("a Turbo-Stream-style appended item is counted without any re-init", async () => {
    const el = await mount(markup({ items: [true, true, true] }), CONTROLLERS)
    const all = el.querySelector("[data-cw--selection-target='all']")
    expect(all.checked).toBe(true)

    const appended = document.createElement("input")
    appended.type = "checkbox"
    appended.id = "item-new"
    appended.setAttribute("data-cw--selection-target", "item")
    el.appendChild(appended)
    await nextFrame()

    // A newly appended, unchecked row must immediately flip "all selected" to
    // indeterminate — without the user touching anything.
    expect(all.checked).toBe(false)
    expect(all.indeterminate).toBe(true)
  })

  test("removing a checked item recomputes the count", async () => {
    const el = await mount(markup({ items: [true, true, false] }), CONTROLLERS)
    const count = el.querySelector("[data-cw--selection-target='count']")
    expect(count.textContent).toBe("2 selected")

    items(el)[0].remove()
    await nextFrame()

    expect(count.textContent).toBe("1 selected")
  })

  // --- events: only for genuine user-driven changes ---------------------------------

  test("dispatches cw--selection:changed with selected and total on toggleAll", async () => {
    const changed = captureEvents("cw--selection:changed")
    const el = await mount(markup(), CONTROLLERS)
    const all = el.querySelector("[data-cw--selection-target='all']")

    all.checked = true
    all.dispatchEvent(new Event("change", { bubbles: true }))
    await nextFrame()

    expect(changed).toHaveLength(1)
    expect(changed[0].detail).toEqual({ selected: 3, total: 3 })
  })

  test("dispatches cw--selection:changed on an item toggle", async () => {
    const changed = captureEvents("cw--selection:changed")
    const el = await mount(markup(), CONTROLLERS)
    const [first] = items(el)

    first.checked = true
    first.dispatchEvent(new Event("change", { bubbles: true }))
    await nextFrame()

    expect(changed).toHaveLength(1)
    expect(changed[0].detail).toEqual({ selected: 1, total: 3 })
  })

  test("does NOT dispatch cw--selection:changed on connect", async () => {
    const changed = captureEvents("cw--selection:changed")
    await mount(markup({ items: [true, false, false] }), CONTROLLERS)
    await nextFrame()

    expect(changed).toHaveLength(0)
  })

  test("does NOT dispatch cw--selection:changed when a row is merely appended (no user action)", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const changed = captureEvents("cw--selection:changed")

    const appended = document.createElement("input")
    appended.type = "checkbox"
    appended.id = "item-new"
    appended.setAttribute("data-cw--selection-target", "item")
    el.appendChild(appended)
    await nextFrame()

    expect(changed).toHaveLength(0)
  })
})
