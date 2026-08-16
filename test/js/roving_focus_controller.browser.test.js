import { describe, expect, test } from "vitest"
import { Application } from "@hotwired/stimulus"
import RovingFocusController from "../../app/assets/javascripts/crosswire/controllers/roving_focus_controller.js"

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
// Run with `npm run test:browser` after `npx playwright install chromium`. As of this
// writing vitest.config.js does not yet define the `browser` project the package.json
// script points at — wiring that up is tracked separately, same as every other
// crosswire controller's browser tier (see intersection_controller.browser.test.js).
// The assertions below are written against real browser APIs so they are correct the
// day that project exists, not aspirational pseudocode.

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

function start(html) {
  document.body.innerHTML = html
  const application = Application.start()
  application.register("cw--roving-focus", RovingFocusController)
  return application
}

function stop(application) {
  application.stop()
  document.body.innerHTML = ""
}

describe("cw--roving-focus (real browser focus)", () => {
  test("ArrowDown moves real document.activeElement between real buttons", () => {
    const application = start(markup())
    const first = document.getElementById("item-0")
    const second = document.getElementById("item-1")

    first.focus()
    expect(document.activeElement).toBe(first)

    first.dispatchEvent(key("ArrowDown"))

    expect(document.activeElement).toBe(second)
    expect(first.getAttribute("tabindex")).toBe("-1")
    expect(second.getAttribute("tabindex")).toBe("0")

    stop(application)
  })

  test("only one item is ever reachable via tabindex=0 after a sequence of real moves", () => {
    const application = start(markup(["One", "Two", "Three", "Four"]))
    const items = () => Array.from(document.querySelectorAll("[data-cw--roving-focus-target='item']"))

    items()[0].focus()
    for (const k of ["ArrowDown", "ArrowDown", "ArrowUp", "ArrowDown", "ArrowDown"]) {
      document.activeElement.dispatchEvent(key(k))
    }

    const zeroTabindex = items().filter((el) => el.getAttribute("tabindex") === "0")
    expect(zeroTabindex).toHaveLength(1)
    expect(zeroTabindex[0]).toBe(document.activeElement)

    stop(application)
  })

  test("a real node swap (remove + re-add, as a re-render would produce) keeps exactly one roving stop", async () => {
    const application = start(markup(["One", "Two"]))
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

    stop(application)
  })
})
