import { describe, expect, test, vi } from "vitest"
import { Application } from "@hotwired/stimulus"
import MenuController from "../../app/assets/javascripts/crosswire/controllers/menu_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

// jsdom tier (docs/COMPONENT_CONTRACT.md R8). jsdom does not implement the Popover API
// at all — no showPopover/hidePopover/togglePopover, no real ToggleEvent — and its
// nwsapi selector engine throws a SyntaxError on the `:popover-open` pseudo-class
// rather than just not matching it, the identical shape to the `:modal` gotcha
// dialog_controller.test.js works around. So, exactly like popover_controller.test.js
// and dialog_controller.test.js: stand in for the browser's own `toggle` event with a
// plain `Event` carrying `newState` (`toggleEvent` below, lifted verbatim from
// popover_controller.test.js), stub showPopover/hidePopover as vi.fn()s that also
// track "is it open" so `matches(":popover-open")` — this controller's own #isOpen()
// check — has something honest to answer (the same shim shape as dialog's `:modal`
// polyfill). What this file does NOT and cannot honestly test: real top-layer
// visibility, real focus-fix-up ordering on native Tab, and real Space-key native
// defaults on a <button>/<a> — those all live in menu_controller.browser.test.js.
//
// Uses the shared `mount()` helper from setup.js — this controller declares no
// connect() at all, so (unlike dialog) there is no ordering hazard to work around by
// hand-rolling an Application; the showPopover/hidePopover/matches stub can be
// attached to the panel AFTER mount() resolves.

function toggleEvent(newState) {
  const event = new Event("toggle")
  event.newState = newState
  return event
}

function key(k, opts = {}) {
  return new KeyboardEvent("keydown", { key: k, bubbles: true, cancelable: true, ...opts })
}

// Tracks a local "is it open" boolean alongside the showPopover/hidePopover stubs so
// this controller's own `#isOpen()` (`matches(":popover-open")`) has an honest answer —
// dialog_controller.test.js's `:modal` shim, same idiom.
function stubPopover(panel) {
  let open = false
  panel.showPopover = vi.fn(() => {
    open = true
  })
  panel.hidePopover = vi.fn(() => {
    open = false
  })

  const nativeMatches = typeof panel.matches === "function" ? panel.matches.bind(panel) : null
  panel.matches = (selector) => {
    if (selector === ":popover-open") return open
    if (!nativeMatches) return false
    try {
      return nativeMatches(selector)
    } catch {
      return false
    }
  }

  return panel
}

function itemHtml({ tag = "button", role = "menuitem", value, checked, label }) {
  const checkedAttr = checked === undefined ? "" : `aria-checked="${checked}"`
  const valueAttr = value === undefined ? "" : `data-cw--menu-value-param="${value}"`
  const typeAttr = tag === "button" ? 'type="button"' : ""
  const hrefAttr = tag === "a" ? 'href="#"' : ""

  return `<${tag} ${typeAttr} ${hrefAttr} role="${role}" ${checkedAttr} ${valueAttr}
            data-cw--menu-target="item" tabindex="-1"
            data-action="click->cw--menu#select keydown.space->cw--menu#activate">${label}</${tag}>`
}

const DEFAULT_ITEMS = [
  { tag: "a", value: "alpha", label: "Alpha" },
  { tag: "button", value: "beta", label: "Beta" },
  { tag: "button", role: "menuitemcheckbox", checked: false, value: "gamma", label: "Gamma" }
]

function markup(items) {
  return `
    <div data-controller="cw--menu">
      <button id="menu-trigger" popovertarget="menu-panel"
              data-cw--menu-target="button"
              data-action="keydown.down->cw--menu#openFirst keydown.up->cw--menu#openLast">
        Actions
      </button>
      <div id="menu-panel" popover="auto" role="menu"
           data-cw--menu-target="menu"
           data-action="toggle->cw--menu#toggled keydown.tab->cw--menu#tabOut keydown.shift+tab->cw--menu#tabOut">
        ${items.map(itemHtml).join("\n")}
      </div>
    </div>`
}

async function boot(items = DEFAULT_ITEMS) {
  const el = await mount(markup(items), { "cw--menu": MenuController })
  const panel = document.getElementById("menu-panel")
  stubPopover(panel)

  return {
    el,
    panel,
    button: document.getElementById("menu-trigger"),
    items: () => Array.from(panel.querySelectorAll('[data-cw--menu-target="item"]'))
  }
}

describe("cw--menu", () => {
  // --- opening from the button ------------------------------------------------------

  test("ArrowDown on the closed button calls showPopover and preventDefaults the keydown", async () => {
    const { panel, button } = await boot()
    const event = key("ArrowDown")
    button.dispatchEvent(event)

    expect(panel.showPopover).toHaveBeenCalledTimes(1)
    expect(event.defaultPrevented).toBe(true)
  })

  test("ArrowUp on the closed button calls showPopover", async () => {
    const { panel, button } = await boot()
    button.dispatchEvent(key("ArrowUp"))

    expect(panel.showPopover).toHaveBeenCalledTimes(1)
  })

  test("toggled(open) focuses the FIRST item by default (a plain click/Enter open)", async () => {
    const { panel, items } = await boot()
    panel.dispatchEvent(toggleEvent("open"))
    await nextFrame()

    expect(document.activeElement).toBe(items()[0])
  })

  test("ArrowDown then toggled(open) focuses the FIRST item", async () => {
    const { panel, button, items } = await boot()
    button.dispatchEvent(key("ArrowDown"))
    panel.dispatchEvent(toggleEvent("open"))
    await nextFrame()

    expect(document.activeElement).toBe(items()[0])
  })

  test("ArrowUp then toggled(open) focuses the LAST item", async () => {
    const { panel, button, items } = await boot()
    button.dispatchEvent(key("ArrowUp"))
    panel.dispatchEvent(toggleEvent("open"))
    await nextFrame()

    const all = items()
    expect(document.activeElement).toBe(all[all.length - 1])
  })

  test("pendingFocus resets to first after being consumed, so the NEXT open (without an ArrowUp) is first again", async () => {
    const { panel, button, items } = await boot()
    button.dispatchEvent(key("ArrowUp"))
    panel.dispatchEvent(toggleEvent("open"))
    await nextFrame()
    panel.dispatchEvent(toggleEvent("closed"))
    await nextFrame()

    panel.dispatchEvent(toggleEvent("open"))
    await nextFrame()

    expect(document.activeElement).toBe(items()[0])
  })

  // --- opened/closed events -----------------------------------------------------------

  test("toggled(open) dispatches opened exactly once", async () => {
    const opened = captureEvents("cw--menu:opened")
    const { panel } = await boot()

    panel.dispatchEvent(toggleEvent("open"))
    await nextFrame()

    expect(opened).toHaveLength(1)
  })

  test("does not dispatch opened merely from connecting (R4a-shaped assertion, even though this controller has no value)", async () => {
    const opened = captureEvents("cw--menu:opened")
    await boot()
    await nextFrame()

    expect(opened).toHaveLength(0)
  })

  test("toggled(closed) dispatches closed exactly once", async () => {
    const closed = captureEvents("cw--menu:closed")
    const { panel } = await boot()

    panel.dispatchEvent(toggleEvent("closed"))
    await nextFrame()

    expect(closed).toHaveLength(1)
  })

  test("toggled(closed) focuses the button when activeElement fell through to body (defensive backstop)", async () => {
    const { panel, button } = await boot()
    expect(document.activeElement).toBe(document.body)

    panel.dispatchEvent(toggleEvent("closed"))
    await nextFrame()

    expect(document.activeElement).toBe(button)
  })

  test("toggled(closed) does not steal focus from an element that already has it", async () => {
    const { panel, button, items } = await boot()
    const [first] = items()
    first.focus()

    panel.dispatchEvent(toggleEvent("closed"))
    await nextFrame()

    expect(document.activeElement).toBe(first)
    expect(document.activeElement).not.toBe(button)
  })

  // --- select ---------------------------------------------------------------------

  test("select dispatches selected with item and value, then closes", async () => {
    const selected = captureEvents("cw--menu:selected")
    const { panel, items } = await boot()
    const [first] = items()

    first.click()
    await nextFrame()

    expect(selected).toHaveLength(1)
    expect(selected[0].detail.item).toBe(first)
    expect(selected[0].detail.value).toBe("alpha")
    expect(panel.hidePopover).toHaveBeenCalledTimes(1)
  })

  test("select never preventDefaults the native click — links must still navigate, forms must still submit", async () => {
    const { items } = await boot()
    const [first] = items()

    const event = new MouseEvent("click", { bubbles: true, cancelable: true })
    first.dispatchEvent(event)

    expect(event.defaultPrevented).toBe(false)
  })

  test("a canceled selected event aborts the close", async () => {
    const preventSelect = (event) => event.preventDefault()
    document.addEventListener("cw--menu:selected", preventSelect)

    try {
      const { panel, items } = await boot()
      items()[1].click()
      await nextFrame()

      expect(panel.hidePopover).not.toHaveBeenCalled()
    } finally {
      document.removeEventListener("cw--menu:selected", preventSelect)
    }
  })

  test("activating a menuitemcheckbox stays open", async () => {
    const { panel, items } = await boot()
    const checkbox = items()[2]

    checkbox.click()
    await nextFrame()

    expect(panel.hidePopover).not.toHaveBeenCalled()
  })

  test("activating a menuitemradio stays open", async () => {
    const { panel, items } = await boot([
      { tag: "button", role: "menuitemradio", checked: true, value: "one", label: "One" },
      { tag: "button", role: "menuitemradio", checked: false, value: "two", label: "Two" }
    ])

    items()[1].click()
    await nextFrame()

    expect(panel.hidePopover).not.toHaveBeenCalled()
  })

  test("activating a plain menuitem closes", async () => {
    const { panel, items } = await boot()
    items()[1].click()
    await nextFrame()

    expect(panel.hidePopover).toHaveBeenCalledTimes(1)
  })

  // --- activate (Space shim) -------------------------------------------------------

  test("activate is a no-op for a <button> item — native Space already activates it, and clicking again would double-fire", async () => {
    const { items } = await boot()
    const button = items()[1]
    const clickSpy = vi.spyOn(button, "click")

    button.dispatchEvent(key(" "))

    expect(clickSpy).not.toHaveBeenCalled()
    clickSpy.mockRestore()
  })

  test("activate clicks an <a role=menuitem> exactly once — native Space only scrolls a link", async () => {
    const { items } = await boot()
    const link = items()[0]
    const clickSpy = vi.spyOn(link, "click")

    const event = key(" ")
    link.dispatchEvent(event)

    expect(clickSpy).toHaveBeenCalledTimes(1)
    expect(event.defaultPrevented).toBe(true)
    clickSpy.mockRestore()
  })

  // --- tabOut -----------------------------------------------------------------------

  test("Tab closes the menu", async () => {
    const { panel } = await boot()
    panel.dispatchEvent(key("Tab"))

    expect(panel.hidePopover).toHaveBeenCalledTimes(1)
  })

  test("Shift+Tab also closes (R8a — a bare keydown.tab filter silently drops Shift+Tab)", async () => {
    const { panel } = await boot()
    panel.dispatchEvent(key("Tab", { shiftKey: true }))

    expect(panel.hidePopover).toHaveBeenCalledTimes(1)
  })

  test("tabOut never preventDefaults — load-bearing so the browser's native Tab default runs after the popover focus fix-up", async () => {
    const { panel } = await boot()
    const event = key("Tab")
    panel.dispatchEvent(event)

    expect(event.defaultPrevented).toBe(false)
  })

  // --- close() (public) --------------------------------------------------------------
  // The only test in this file needing direct access to the controller instance
  // (mirrors popover_controller.test.js's `mountWithApplication` — every other test
  // uses the shared `mount()` from setup.js).

  test("close() hides the popover", async () => {
    document.body.innerHTML = markup(DEFAULT_ITEMS)
    const application = Application.start()
    application.register("cw--menu", MenuController)
    await nextFrame()

    const panel = stubPopover(document.getElementById("menu-panel"))
    const el = document.body.firstElementChild
    const controller = application.getControllerForElementAndIdentifier(el, "cw--menu")

    controller.close()

    expect(panel.hidePopover).toHaveBeenCalledTimes(1)
    application.stop()
  })

  // --- itemTargetDisconnected (R8) --------------------------------------------------

  test("removing the focused item while open moves focus to a surviving item", async () => {
    const { panel, items } = await boot()
    panel.showPopover()
    const [first, second] = items()
    first.focus()

    first.remove()
    await nextFrame()

    expect(document.activeElement).toBe(second)
  })

  test("removing the only remaining item while open falls back to the button, never body", async () => {
    const { panel, button, items } = await boot([{ tag: "button", value: "only", label: "Only" }])
    panel.showPopover()
    const [only] = items()
    only.focus()

    only.remove()
    await nextFrame()

    expect(document.activeElement).toBe(button)
    expect(document.activeElement).not.toBe(document.body)
  })

  test("removing an item that does not hold focus leaves focus untouched", async () => {
    const { panel, items } = await boot()
    panel.showPopover()
    const [first, second] = items()
    second.focus()

    first.remove()
    await nextFrame()

    expect(document.activeElement).toBe(second)
  })

  test("itemTargetDisconnected does nothing while the menu is not open", async () => {
    const { items, button } = await boot()
    const [first, second] = items()
    first.focus()

    first.remove()
    await nextFrame()

    expect(document.activeElement).not.toBe(second)
    expect(document.activeElement).not.toBe(button)
  })

  // --- disconnect (R7/R8) -------------------------------------------------------------

  test("disconnect blurs an activeElement contained within this controller's element", async () => {
    const { el, items } = await boot()
    const [first] = items()
    first.focus()
    expect(document.activeElement).toBe(first)

    el.remove()
    await nextFrame()

    expect(document.activeElement).not.toBe(first)
  })

  test("disconnect hides the popover if it was left open", async () => {
    const { el, panel } = await boot()
    panel.showPopover()

    el.remove()
    await nextFrame()

    expect(panel.hidePopover).toHaveBeenCalledTimes(1)
  })

  test("disconnect does not throw, and does not call hidePopover, when the menu was never opened", async () => {
    const { el, panel } = await boot()

    expect(() => el.remove()).not.toThrow()
    await nextFrame()

    expect(panel.hidePopover).not.toHaveBeenCalled()
  })
})
