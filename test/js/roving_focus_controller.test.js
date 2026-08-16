import { describe, expect, test, vi } from "vitest"
import RovingFocusController from "../../app/assets/javascripts/crosswire/controllers/roving_focus_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--roving-focus": RovingFocusController }

function markup({ orientation = null, wrap = null, typeahead = null, items = ["One", "Two", "Three"], current = 0 } = {}) {
  const itemsHtml = items
    .map(
      (label, i) =>
        `<button data-cw--roving-focus-target="item" tabindex="${i === current ? "0" : "-1"}">${label}</button>`
    )
    .join("")

  return `
    <div data-controller="cw--roving-focus"
         ${orientation ? `data-cw--roving-focus-orientation-value="${orientation}"` : ""}
         ${wrap !== null ? `data-cw--roving-focus-wrap-value="${wrap}"` : ""}
         ${typeahead !== null ? `data-cw--roving-focus-typeahead-value="${typeahead}"` : ""}
         data-action="keydown->cw--roving-focus#navigate">
      ${itemsHtml}
    </div>`
}

function key(k, opts = {}) {
  return new KeyboardEvent("keydown", { key: k, bubbles: true, cancelable: true, ...opts })
}

function items(el) {
  return Array.from(el.querySelectorAll("[data-cw--roving-focus-target='item']"))
}

describe("cw--roving-focus", () => {
  test("connect claims the roving stop when nothing is marked", async () => {
    const el = await mount(
      `<div data-controller="cw--roving-focus" data-action="keydown->cw--roving-focus#navigate">
        <button data-cw--roving-focus-target="item">One</button>
        <button data-cw--roving-focus-target="item">Two</button>
      </div>`,
      CONTROLLERS
    )

    const [first, second] = items(el)
    expect(first.getAttribute("tabindex")).toBe("0")
    expect(second.getAttribute("tabindex")).toBe("-1")
  })

  test("ArrowDown moves focus and the roving stop, vertical by default", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const [first, second] = items(el)
    first.focus()

    first.dispatchEvent(key("ArrowDown"))
    await nextFrame()

    expect(document.activeElement).toBe(second)
    expect(first.getAttribute("tabindex")).toBe("-1")
    expect(second.getAttribute("tabindex")).toBe("0")
  })

  test("ArrowUp/ArrowDown are ignored entirely in horizontal orientation", async () => {
    const el = await mount(markup({ orientation: "horizontal" }), CONTROLLERS)
    const [first] = items(el)
    first.focus()

    const event = key("ArrowDown")
    first.dispatchEvent(event)
    await nextFrame()

    expect(document.activeElement).toBe(first)
    expect(event.defaultPrevented).toBe(false)
  })

  test("ArrowLeft/ArrowRight move focus in horizontal orientation", async () => {
    const el = await mount(markup({ orientation: "horizontal" }), CONTROLLERS)
    const [first, second] = items(el)
    first.focus()

    first.dispatchEvent(key("ArrowRight"))
    await nextFrame()

    expect(document.activeElement).toBe(second)
  })

  test("all four arrows move focus when orientation is both", async () => {
    const el = await mount(markup({ orientation: "both" }), CONTROLLERS)
    const [first, second, third] = items(el)
    first.focus()

    first.dispatchEvent(key("ArrowRight"))
    await nextFrame()
    expect(document.activeElement).toBe(second)

    second.dispatchEvent(key("ArrowDown"))
    await nextFrame()
    expect(document.activeElement).toBe(third)
  })

  test("wraps from the last item to the first by default", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const [first, , third] = items(el)
    third.focus()

    third.dispatchEvent(key("ArrowDown"))
    await nextFrame()

    expect(document.activeElement).toBe(first)
  })

  test("wraps from the first item back to the last", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const [first, , third] = items(el)
    first.focus()

    first.dispatchEvent(key("ArrowUp"))
    await nextFrame()

    expect(document.activeElement).toBe(third)
  })

  test("does not wrap when wrap is false", async () => {
    const el = await mount(markup({ wrap: false }), CONTROLLERS)
    const [, , third] = items(el)
    third.focus()

    third.dispatchEvent(key("ArrowDown"))
    await nextFrame()

    expect(document.activeElement).toBe(third)
  })

  test("Home jumps to the first item, End jumps to the last", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const [first, , third] = items(el)
    const [, second] = items(el)
    second.focus()

    second.dispatchEvent(key("End"))
    await nextFrame()
    expect(document.activeElement).toBe(third)

    third.dispatchEvent(key("Home"))
    await nextFrame()
    expect(document.activeElement).toBe(first)
  })

  test("dispatches moved with the new index", async () => {
    const moved = captureEvents("cw--roving-focus:moved")
    const el = await mount(markup(), CONTROLLERS)
    const [first] = items(el)
    first.focus()

    first.dispatchEvent(key("ArrowDown"))
    await nextFrame()

    expect(moved).toHaveLength(1)
    expect(moved[0].detail.index).toBe(1)
  })

  test("preventDefault is called for a recognised navigation key", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const [first] = items(el)
    first.focus()

    const event = key("ArrowDown")
    first.dispatchEvent(event)
    await nextFrame()

    expect(event.defaultPrevented).toBe(true)
  })

  test("an unrelated key is left alone", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const [first] = items(el)
    first.focus()

    const event = key("Escape")
    first.dispatchEvent(event)
    await nextFrame()

    expect(event.defaultPrevented).toBe(false)
    expect(document.activeElement).toBe(first)
  })

  // --- typeahead -------------------------------------------------------------------

  test("typeahead jumps to the item whose text starts with the typed character", async () => {
    const el = await mount(markup({ typeahead: true, items: ["Apple", "Banana", "Cherry"] }), CONTROLLERS)
    const [first, , third] = items(el)
    first.focus()

    first.dispatchEvent(key("c"))
    await nextFrame()

    expect(document.activeElement).toBe(third)
  })

  test("typeahead is off by default, so a printable key does nothing", async () => {
    const el = await mount(markup({ items: ["Apple", "Banana", "Cherry"] }), CONTROLLERS)
    const [first] = items(el)
    first.focus()

    first.dispatchEvent(key("c"))
    await nextFrame()

    expect(document.activeElement).toBe(first)
  })

  test("typeahead is case-insensitive and accumulates a multi-character buffer", async () => {
    const el = await mount(markup({ typeahead: true, items: ["Apple", "Banana", "Blueberry"] }), CONTROLLERS)
    const [, second, third] = items(el)
    second.focus()

    // "B" (uppercase) cycling forward from Banana matches Blueberry next.
    second.dispatchEvent(key("B"))
    await nextFrame()
    expect(document.activeElement).toBe(third)

    // Buffer is now "b"; typing "l" narrows to "bl", which only Blueberry matches
    // — confirms characters accumulate rather than each keystroke restarting fresh.
    third.dispatchEvent(key("l"))
    await nextFrame()
    expect(document.activeElement).toBe(third)
  })

  test("typeahead buffer resets after ~500ms of inactivity", async () => {
    // mount() awaits a real setTimeout internally (see setup.js#nextFrame), so fake
    // timers are switched on only after connect has already happened — otherwise
    // that internal wait would hang forever waiting on a timer nothing advances.
    const el = await mount(markup({ typeahead: true, items: ["Apple", "Banana", "Aardvark"] }), CONTROLLERS)
    const [first, , third] = items(el)
    first.focus()

    vi.useFakeTimers()
    try {
      // "a" matches "Aardvark" (cycling forward from Apple). Stimulus action
      // handlers run synchronously on dispatchEvent, so no await is needed here.
      first.dispatchEvent(key("a"))
      expect(document.activeElement).toBe(third)

      vi.advanceTimersByTime(600)

      // Buffer reset — a fresh "a" should behave like a brand-new single-character
      // search again (cycles forward from Aardvark, wrapping to Apple).
      third.dispatchEvent(key("a"))
      expect(document.activeElement).toBe(first)
    } finally {
      vi.useRealTimers()
    }
  })

  test("typeahead ignores modified keys so it never steals browser shortcuts", async () => {
    const el = await mount(markup({ typeahead: true, items: ["Apple", "Banana", "Cherry"] }), CONTROLLERS)
    const [first] = items(el)
    first.focus()

    first.dispatchEvent(key("c", { metaKey: true }))
    await nextFrame()

    expect(document.activeElement).toBe(first)
  })

  // --- Turbo content churn: connected/disconnected keep exactly one stop ------------

  test("a newly connected item claims the stop if the group was empty", async () => {
    const el = await mount(
      `<div data-controller="cw--roving-focus" data-action="keydown->cw--roving-focus#navigate"></div>`,
      CONTROLLERS
    )

    const item = document.createElement("button")
    item.setAttribute("data-cw--roving-focus-target", "item")
    item.textContent = "New"
    el.appendChild(item)
    await nextFrame()

    expect(item.getAttribute("tabindex")).toBe("0")
  })

  test("a newly connected item does not steal the stop from an existing item", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const [first] = items(el)

    const item = document.createElement("button")
    item.setAttribute("data-cw--roving-focus-target", "item")
    item.textContent = "New"
    el.appendChild(item)
    await nextFrame()

    expect(first.getAttribute("tabindex")).toBe("0")
    expect(item.getAttribute("tabindex")).toBe("-1")
  })

  test("removing the item holding the stop hands it to a neighbour", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const [first, second] = items(el)

    first.remove()
    await nextFrame()

    expect(second.getAttribute("tabindex")).toBe("0")
  })

  test("re-queries items on every keypress rather than caching at connect", async () => {
    const el = await mount(markup({ items: ["One", "Two"] }), CONTROLLERS)
    const [first] = items(el)
    first.focus()

    const inserted = document.createElement("button")
    inserted.setAttribute("data-cw--roving-focus-target", "item")
    inserted.setAttribute("tabindex", "-1")
    inserted.textContent = "Inserted"
    el.insertBefore(inserted, items(el)[1])
    await nextFrame()

    first.dispatchEvent(key("ArrowDown"))
    await nextFrame()

    expect(document.activeElement).toBe(inserted)
  })

  // R7 — the typeahead buffer-reset timer is the only resource this controller
  // holds outside Stimulus's own action/target bookkeeping, so disconnect() must
  // release it. Spying on the real clearTimeout (rather than faking timers, which
  // would fight setup.js's own real-timer afterEach) proves it's actually called.
  test("disconnect clears the typeahead timer (R7)", async () => {
    const el = await mount(markup({ typeahead: true, items: ["Apple", "Banana"] }), CONTROLLERS)
    const [first] = items(el)
    first.focus()
    first.dispatchEvent(key("a")) // arms the 500ms buffer-reset timer

    const clearSpy = vi.spyOn(window, "clearTimeout")

    document.body.innerHTML = ""
    await nextFrame() // let Stimulus's MutationObserver fire disconnect() for real

    expect(clearSpy).toHaveBeenCalled()
    clearSpy.mockRestore()
  })
})
