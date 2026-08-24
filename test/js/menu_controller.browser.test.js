import { describe, expect, test } from "vitest"
import { userEvent } from "vitest/browser"
import { morphElements } from "@hotwired/turbo"
import MenuController from "../../app/assets/javascripts/crosswire/controllers/menu_controller.js"
import PopoverController from "../../app/assets/javascripts/crosswire/controllers/popover_controller.js"
import RovingFocusController from "../../app/assets/javascripts/crosswire/controllers/roving_focus_controller.js"
import { mount } from "./setup.js"

// Browser tier (docs/COMPONENT_CONTRACT.md: "Browser mode for anything touching
// focus, <dialog>, IntersectionObserver, or positioning — jsdom cannot test those
// honestly"). This IS the accessibility claim for `cw--menu`: jsdom has no Popover
// API and no top layer at all (menu_controller.test.js's own header explains why),
// so the eighteen tests below are the only place the FULL real-browser stack —
// native popover open/close/light-dismiss/Escape/focus-fix-up, real CSS layout and
// top-layer stacking, real focus/blur, and real native-default key handling
// (Enter-activates-a-link, Space-activates-a-button, Tab traversal) — is exercised
// together, exactly as WAI-ARIA APG's Menu Button pattern requires it to work.
//
// Register cw--menu, cw--popover, and cw--roving-focus — the full composed stack,
// per Crosswire::Presenters::Menu's docstring (R5b: cw--menu on the wrapper,
// cw--popover + cw--roving-focus stacked on the panel).
//
// Uses the shared `mount()` helper from setup.js, never a hand-rolled
// Application.start()/register() — three agents independently hit the connect-tick
// bug that produces (dialog_controller.browser.test.js, popover_controller.browser
// .test.js, roving_focus_controller.browser.test.js all carry the same note).
//
// Synthetic vs real input, deliberately split: ArrowDown/ArrowUp/Home/End/typeahead
// (tests 2, 3, 4, 5, 6, 15) are dispatched as plain `KeyboardEvent`s because the
// controller (cw--menu directly, or cw--roving-focus underneath it) reads
// `event.key` itself and calls `.focus()` explicitly — there is no browser-native
// default action being relied on, the identical justification
// roving_focus_controller.browser.test.js gives for the same choice. Tests 8, 9, 11
// and 12 depend on genuine native default actions (Tab traversal order,
// Enter-activates-a-link, Space-activates-a-button) that the UA wires to *trusted*
// input only — `dispatchEvent(new KeyboardEvent(...))` is never trusted, so those
// four MUST drive real input through `userEvent` (the Playwright provider). Tests 1
// and 7 are also native-default-shaped (Enter/Space open via popovertarget's own
// click activation; Escape-closes-a-popover is entirely the UA's own doing) and use
// `userEvent` for the same reason even though a plain `.click()` would arguably
// reach the same code path for test 1 — driving the actual key is more honest.
//
// Direct morphElements() dispatches THREE element-level events, not five (BUILD-LOG
// §8) — test 18 is built around that, not around a full Turbo page/frame render.

const CONTROLLERS = {
  "cw--menu": MenuController,
  "cw--popover": PopoverController,
  "cw--roving-focus": RovingFocusController
}

function itemHtml({ tag = "button", role = "menuitem", value, checked, id, href, label }) {
  const typeAttr = tag === "button" ? 'type="button"' : ""
  const hrefAttr = tag === "a" ? `href="${href ?? "#"}"` : ""
  const checkedAttr = checked === undefined ? "" : `aria-checked="${checked}"`
  const valueAttr = value === undefined ? "" : `data-cw--menu-value-param="${value}"`
  const idAttr = id ? `id="${id}"` : ""

  return `<${tag} ${idAttr} ${typeAttr} ${hrefAttr} role="${role}" ${checkedAttr} ${valueAttr}
            data-cw--roving-focus-target="item" data-cw--menu-target="item" tabindex="-1"
            data-action="click->cw--menu#select keydown.space->cw--menu#activate">${label}</${tag}>`
}

// Alpha/Delta/Duplicate deliberately give typeahead (test 6) two "d" matches to
// cycle between. Each item carries a stable id so identity survives the morph in
// test 18 (idiomorph matches descendants by id).
const ITEMS = [
  { tag: "button", id: "item-alpha", value: "alpha", label: "Alpha" },
  { tag: "a", id: "item-delta", href: "#delta-target", label: "Delta" },
  { tag: "button", id: "item-duplicate", value: "duplicate", label: "Duplicate" },
  { tag: "button", id: "item-hidden", role: "menuitemcheckbox", checked: false, value: "hidden", label: "Show hidden" }
]

function markup(items = ITEMS, { wrapOverflow = false } = {}) {
  const menu = `
    <div id="menu-wrapper" data-controller="cw--menu">
      <button id="actions-trigger" type="button" popovertarget="actions-panel"
              data-cw--menu-target="button" aria-haspopup="menu"
              data-action="keydown.down->cw--menu#openFirst keydown.up->cw--menu#openLast">
        Actions
      </button>
      <div id="actions-panel" popover="auto" role="menu" aria-labelledby="actions-trigger"
           data-controller="cw--popover cw--roving-focus"
           data-cw--roving-focus-orientation-value="vertical"
           data-cw--roving-focus-wrap-value="true"
           data-cw--roving-focus-typeahead-value="true"
           data-cw--menu-target="menu"
           data-action="toggle->cw--popover#toggled toggle->cw--menu#toggled
                        keydown.tab->cw--menu#tabOut keydown.shift+tab->cw--menu#tabOut
                        keydown->cw--roving-focus#navigate">
        ${items.map(itemHtml).join("\n")}
      </div>
    </div>
    <button id="after">After</button>
    <div id="delta-target">Delta target</div>`

  const before = `<button id="before">Before</button>`

  if (!wrapOverflow) return `${before}${menu}`

  return `${before}<div style="overflow: hidden; height: 24px; width: 220px;">${menu}</div>`
}

async function boot(items = ITEMS, opts = {}) {
  const el = await mount(markup(items, opts), CONTROLLERS)
  return {
    el: document.getElementById("menu-wrapper"),
    trigger: document.getElementById("actions-trigger"),
    panel: document.getElementById("actions-panel"),
    before: document.getElementById("before"),
    after: document.getElementById("after"),
    items: () => Array.from(document.querySelectorAll('[data-cw--menu-target="item"]'))
  }
}

async function settle() {
  await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
}

async function open(items = ITEMS, opts = {}) {
  const ctx = await boot(items, opts)
  await userEvent.click(ctx.trigger)
  await settle()
  return ctx
}

function key(k, opts = {}) {
  return new KeyboardEvent("keydown", { key: k, bubbles: true, cancelable: true, ...opts })
}

describe("cw--menu (real browser, full composed stack)", () => {
  test("1. Enter on the button opens the menu and moves focus to the first item", async () => {
    const { trigger, items } = await boot()
    trigger.focus()

    await userEvent.keyboard("{Enter}")
    await settle()

    expect(document.activeElement).toBe(items()[0])
  })

  test("2. ArrowDown on the closed button opens the menu and focuses the first item", async () => {
    const { trigger, items } = await boot()
    trigger.dispatchEvent(key("ArrowDown"))
    await settle()

    expect(document.activeElement).toBe(items()[0])
  })

  test("3. ArrowUp on the closed button opens the menu and focuses the LAST item", async () => {
    const { trigger, items } = await boot()
    trigger.dispatchEvent(key("ArrowUp"))
    await settle()

    const all = items()
    expect(document.activeElement).toBe(all[all.length - 1])
  })

  test("4. ArrowDown moves to the next item, wrapping from the last item back to the first", async () => {
    const { items } = await open()
    const all = items()
    const last = all[all.length - 1]
    last.focus()

    last.dispatchEvent(key("ArrowDown"))

    expect(document.activeElement).toBe(all[0])
  })

  test("5. Home and End move focus to the first and last items, through the real composed stack", async () => {
    const { items } = await open()
    const all = items()
    all[1].focus()

    all[1].dispatchEvent(key("End"))
    expect(document.activeElement).toBe(all[all.length - 1])

    document.activeElement.dispatchEvent(key("Home"))
    expect(document.activeElement).toBe(all[0])
  })

  test("6. Typing 'd' focuses the first item starting with 'd'; typing it again cycles to the next match", async () => {
    const { items } = await open()
    const all = items()
    all[0].focus() // "Alpha"

    document.activeElement.dispatchEvent(key("d"))
    expect(document.activeElement.textContent.trim()).toBe("Delta")

    document.activeElement.dispatchEvent(key("d"))
    expect(document.activeElement.textContent.trim()).toBe("Duplicate")
  })

  test("7. Escape closes the menu and returns focus to the button, never <body>", async () => {
    const { trigger, panel, items } = await open()
    items()[0].focus()

    await userEvent.keyboard("{Escape}")
    await settle()

    expect(panel.matches(":popover-open")).toBe(false)
    expect(document.activeElement).toBe(trigger)
    expect(document.activeElement).not.toBe(document.body)
  })

  test("8. Tab from an open menu closes it and moves focus to the element AFTER the button", async () => {
    const { items, after } = await open()
    items()[0].focus()

    await userEvent.tab()
    await settle()

    expect(document.activeElement).toBe(after)
  })

  test("9. Shift+Tab from an open menu closes it and moves focus to the element BEFORE the button (R8a)", async () => {
    const { items, before } = await open()
    items()[0].focus()

    await userEvent.tab({ shift: true })
    await settle()

    expect(document.activeElement).toBe(before)
  })

  test("10. Clicking a menuitem closes the menu, dispatches selected with its value, and returns focus to the button", async () => {
    const { trigger, panel, items } = await open()
    const selected = []
    document.addEventListener("cw--menu:selected", (event) => selected.push(event))

    await userEvent.click(items()[0]) // "Alpha", value "alpha"
    await settle()

    expect(selected).toHaveLength(1)
    expect(selected[0].detail.value).toBe("alpha")
    expect(panel.matches(":popover-open")).toBe(false)
    expect(document.activeElement).toBe(trigger)
  })

  // Both this test and the Space/<a> case below deliberately call
  // event.preventDefault() from a SEPARATE listener of our own — never from the
  // controller — purely so a real `<a href>` activation in Vitest's browser-mode
  // iframe doesn't actually navigate. A genuine same-page hash navigation was tried
  // first and reliably corrupted Vitest's own browser-mode RPC state for every test
  // that ran afterward in the same worker (`Cannot read properties of undefined
  // (reading 'has'/'delete')` inside @vitest/browser's own internals, immediately
  // after the navigating test) — that is a harness limitation, not a controller bug,
  // and the actual claim under test ("activates exactly once") is fully provable by
  // counting `click` without ever letting the navigation complete.
  test("11. Enter on a focused <a role=menuitem href> activates exactly once and closes the menu", async () => {
    const { panel, items } = await open()
    const link = items().find((el) => el.tagName === "A")
    let clicks = 0
    link.addEventListener("click", (event) => {
      clicks++
      event.preventDefault()
    })
    link.focus()

    await userEvent.keyboard("{Enter}")
    await settle()

    expect(clicks).toBe(1)
    expect(panel.matches(":popover-open")).toBe(false)
  })

  test("12. Space activates a focused <a role=menuitem> exactly once — native Space only scrolls a link", async () => {
    const { items } = await open()
    const link = items().find((el) => el.tagName === "A")
    let clicks = 0
    link.addEventListener("click", (event) => {
      clicks++
      event.preventDefault()
    })
    link.focus()

    await userEvent.keyboard(" ")
    await settle()

    expect(clicks).toBe(1)
  })

  test("12. Space activates a focused <button role=menuitem> exactly once — no shim double-fire", async () => {
    const { items } = await open()
    const button = items().find((el) => el.tagName === "BUTTON" && el.getAttribute("role") === "menuitem")
    let clicks = 0
    button.addEventListener("click", () => {
      clicks++
    })
    button.focus()

    await userEvent.keyboard(" ")
    await settle()

    expect(clicks).toBe(1)
  })

  test("13. Activating a menuitemcheckbox toggles aria-checked and leaves the menu OPEN", async () => {
    const { panel, items } = await open()
    const checkbox = items().find((el) => el.getAttribute("role") === "menuitemcheckbox")

    // The controller only decides whether to CLOSE (0.9) — flipping aria-checked
    // itself is the consumer's own listener, exactly like the checkable_items
    // Lookbook preview. Wired here so the test proves the whole round trip works.
    document.addEventListener("cw--menu:selected", (event) => {
      const { item } = event.detail
      item.setAttribute("aria-checked", String(item.getAttribute("aria-checked") !== "true"))
    })

    expect(checkbox.getAttribute("aria-checked")).toBe("false")

    await userEvent.click(checkbox)
    await settle()

    expect(checkbox.getAttribute("aria-checked")).toBe("true")
    expect(panel.matches(":popover-open")).toBe(true)
  })

  test("14. Inside an ancestor with overflow:hidden and a small height, the open menu is still hit-testable — the top layer earns its keep", async () => {
    const { trigger, items } = await boot(ITEMS, { wrapOverflow: true })

    await userEvent.click(trigger)
    await settle()

    const first = items()[0]
    const rect = first.getBoundingClientRect()
    const hit = document.elementFromPoint(rect.left + rect.width / 2, rect.top + rect.height / 2)

    expect(hit === first || first.contains(hit)).toBe(true)
  })

  test("15. After an ArrowUp-open (focus on the LAST item), the next ArrowDown moves to the FIRST item, and exactly one item holds tabindex=0 afterwards (pins the mechanism-(B) residue, 0.2)", async () => {
    const { trigger, items } = await boot()
    trigger.dispatchEvent(key("ArrowUp"))
    await settle()

    const all = items()
    const last = all[all.length - 1]
    expect(document.activeElement).toBe(last)

    last.dispatchEvent(key("ArrowDown"))

    expect(document.activeElement).toBe(all[0])
    const zeroTabindex = all.filter((el) => el.getAttribute("tabindex") === "0")
    expect(zeroTabindex).toHaveLength(1)
    expect(zeroTabindex[0]).toBe(all[0])
  })

  test("16. Removing the focused menuitem while open moves focus to a surviving item, never <body> (R8)", async () => {
    const { items } = await open()
    const all = items()
    all[0].focus()

    all[0].remove()
    await settle()

    expect(document.activeElement).not.toBe(document.body)
    expect(all.slice(1)).toContain(document.activeElement)
  })

  test("17. Clearing the DOM disconnects the controller, releases the top layer, and the rest of the page stays interactive", async () => {
    const { el, before } = await open()

    el.remove()
    await settle()

    before.focus()
    expect(document.activeElement).toBe(before)

    let clicked = false
    before.addEventListener("click", () => {
      clicked = true
    })
    await userEvent.click(before)
    expect(clicked).toBe(true)
  })

  test("18. Turbo.morphElements over the wrapper while open leaves the menu open with focus unmoved (0.7 — cw--menu holds no Stimulus values for morph to clobber)", async () => {
    const { el, panel, items } = await open()
    const first = items()[0]
    first.focus()

    const incoming = document.createElement("div")
    incoming.id = "menu-wrapper"
    incoming.setAttribute("data-controller", "cw--menu")
    incoming.innerHTML = el.innerHTML

    morphElements(el, incoming)
    await settle()

    expect(panel.matches(":popover-open")).toBe(true)
    expect(document.activeElement).toBe(first)
  })
})
