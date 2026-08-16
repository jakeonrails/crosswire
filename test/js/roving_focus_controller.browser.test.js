import { describe, expect, test } from "vitest"
import RovingFocusController from "../../app/assets/javascripts/crosswire/controllers/roving_focus_controller.js"
import { mount } from "./setup.js"

// Browser tier (docs/COMPONENT_CONTRACT.md: "Browser mode for anything touching
// focus … jsdom cannot test those honestly"). Being honest about the split, unlike
// `focus-trap`: most of `roving-focus`'s own logic — tabindex bookkeeping, arrow-key
// dispatch, typeahead matching, moved events — never touches layout at all (it moves
// focus among explicit `item` targets rather than *discovering* focusable descendants
// via `offsetParent`, which is the specific thing jsdom cannot do), and
// `roving_focus_controller.test.js` verifies all of that honestly under jsdom already.
//
// What genuinely differs here, and is worth a real engine for: (1) confirming actual
// focus/blur life-cycle and `document.activeElement` transitions hold up against a
// real accessibility/focus implementation rather than jsdom's approximation of one —
// jsdom's focus handling is reasonable but not a spec implementation, and this
// primitive's entire job is focus movement; (2) a real Turbo-shaped churn scenario
// (an item's ancestor re-rendering) combined with real layout, so a "removed and
// re-added" item is a genuinely different node, not a coincidentally-matching one.
//
// Run with `npm run test:browser` after `npx playwright install chromium` — wired up
// in vitest.browser.config.js.
//
// This file originally hand-rolled `Application.start()`/`register()` and interacted
// with the DOM in the same synchronous tick, before Stimulus's MutationObserver had
// actually connected the controller — so the very first ArrowDown/sequence tests
// dispatched their keydowns into a DOM with no `navigate` action bound yet, and
// nothing happened. That's the connect-tick gotcha documented in
// docs/COMPONENT_CONTRACT.md's "Test-environment gotchas" table. Fixed by using the
// shared `mount()` helper from setup.js, which awaits a tick after registering — same
// idiom as dialog_controller.browser.test.js and focus_trap_controller.browser.test.js
// — and by relying on setup.js's own afterEach for teardown rather than a hand-rolled
// stop()/innerHTML reset (whose ordering would silently skip disconnect() — see the
// gotchas table).
//
// The keydowns themselves are still dispatched synthetically (`element.dispatchEvent`)
// rather than through `userEvent.keyboard`, and that is deliberate, not a shortcut:
// this controller's `navigate` action has no key filter at all (R8a) — it is a plain
// `keydown->navigate` listener that reads `event.key` itself and moves focus via an
// explicit `.focus()` call. It never relies on the browser's own native arrow-key
// default action (there isn't one to intercept here, unlike native Tab order or
// Escape-closes-<dialog>), so a dispatched, untrusted KeyboardEvent exercises exactly
// the same code path a real key press would drive through Stimulus's action system.

function markup(items = ["One", "Two", "Three"]) {
  const itemsHtml = items
    .map((label, i) => `<button id="item-${i}" data-cw--roving-focus-target="item">${label}</button>`)
    .join("")

  return `
    <div data-controller="cw--roving-focus" data-action="keydown->cw--roving-focus#navigate">
      ${itemsHtml}
    </div>`
}

function key(k) {
  return new KeyboardEvent("keydown", { key: k, bubbles: true, cancelable: true })
}

describe("cw--roving-focus (real browser focus)", () => {
  test("ArrowDown moves real document.activeElement between real buttons", async () => {
    await mount(markup(), { "cw--roving-focus": RovingFocusController })
    const first = document.getElementById("item-0")
    const second = document.getElementById("item-1")

    first.focus()
    expect(document.activeElement).toBe(first)

    first.dispatchEvent(key("ArrowDown"))

    expect(document.activeElement).toBe(second)
    expect(first.getAttribute("tabindex")).toBe("-1")
    expect(second.getAttribute("tabindex")).toBe("0")
  })

  test("only one item is ever reachable via tabindex=0 after a sequence of real moves", async () => {
    await mount(markup(["One", "Two", "Three", "Four"]), { "cw--roving-focus": RovingFocusController })
    const items = () => Array.from(document.querySelectorAll("[data-cw--roving-focus-target='item']"))

    items()[0].focus()
    for (const k of ["ArrowDown", "ArrowDown", "ArrowUp", "ArrowDown", "ArrowDown"]) {
      document.activeElement.dispatchEvent(key(k))
    }

    const zeroTabindex = items().filter((el) => el.getAttribute("tabindex") === "0")
    expect(zeroTabindex).toHaveLength(1)
    expect(zeroTabindex[0]).toBe(document.activeElement)
  })

  test("a real node swap (remove + re-add, as a re-render would produce) keeps exactly one roving stop", async () => {
    await mount(markup(["One", "Two"]), { "cw--roving-focus": RovingFocusController })
    const container = document.querySelector("[data-controller='cw--roving-focus']")
    const first = document.getElementById("item-0")

    first.remove()
    // Real MutationObserver disconnect/connect callbacks are microtasks; yield one.
    await Promise.resolve()

    const second = document.getElementById("item-1")
    expect(second.getAttribute("tabindex")).toBe("0")

    const replacement = document.createElement("button")
    replacement.id = "item-2"
    replacement.setAttribute("data-cw--roving-focus-target", "item")
    replacement.textContent = "Re-added"
    container.appendChild(replacement)
    await Promise.resolve()

    expect(replacement.getAttribute("tabindex")).toBe("-1")
  })
})
