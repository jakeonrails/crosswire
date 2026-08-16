import { afterEach, beforeEach, describe, expect, test, vi } from "vitest"
import AutogrowController from "../../app/assets/javascripts/crosswire/controllers/autogrow_controller.js"
import { mount } from "./setup.js"

// Browser tier (docs/COMPONENT_CONTRACT.md: "Browser mode for anything touching
// focus, <dialog>, IntersectionObserver, or positioning — jsdom cannot test those
// honestly"). jsdom does no layout at all — `scrollHeight` is unconditionally 0, the
// same absence documented for `offsetParent` in the contract's gotchas table — so
// autogrow_controller.test.js only proves the controller's WIRING (Rule 0's
// CSS.supports branch, that an input listener gets attached/removed, that it writes
// SOME inline height without throwing). None of that is "does the textarea actually
// grow to fit its content" or "does it actually stop growing at maxRows" — those
// claims can only be honestly tested against a real browser's layout engine, which is
// what this file does.
//
// This is the ONE component in this batch where a browser test is genuinely required
// rather than padding: per docs/COMPONENT_CONTRACT.md, "Do not write browser tests for
// things jsdom covers honestly." `char-count`, `reveal` and `dirty-form` are all
// state/event/DOM-attribute claims jsdom can verify for real; `autogrow`'s actual
// sizing claim is not.
//
// The Chromium this suite runs in DOES support `field-sizing: content`, which is
// exactly why Rule 0 says to ship the CSS and delete this controller once your
// support matrix allows it — but it also means the controller's own connect() would
// take the no-op branch on this very engine, unable to exercise the fallback code
// these tests exist to check. `CSS.supports` is stubbed to answer false for
// "field-sizing" specifically (and defer to the real implementation for everything
// else) to force the JS fallback path, the same technique the jsdom tier uses to
// force the OTHER branch.
//
// Run with `npm run test:browser` after `npx playwright install chromium` — wired up
// in vitest.browser.config.js.

function markup({ maxRows = null, value = "" } = {}) {
  return `
    <textarea data-controller="cw--autogrow"
              ${maxRows !== null ? `data-cw--autogrow-max-rows-value="${maxRows}"` : ""}
              style="font: 16px/1.5 monospace; padding: 4px; border: 1px solid; box-sizing: border-box; width: 20rem;"
              >${value}</textarea>`
}

async function settle() {
  await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
}

beforeEach(() => {
  const real = CSS.supports.bind(CSS)
  vi.spyOn(CSS, "supports").mockImplementation((prop, value) => (
    prop === "field-sizing" ? false : real(prop, value)
  ))
})

afterEach(() => {
  vi.restoreAllMocks()
})

describe("cw--autogrow (real browser layout)", () => {
  test("grows the textarea's own height as content is typed", async () => {
    const el = await mount(markup(), { "cw--autogrow": AutogrowController })
    const before = el.getBoundingClientRect().height

    el.value = "one\ntwo\nthree\nfour\nfive\nsix\nseven\neight"
    el.dispatchEvent(new Event("input"))
    await settle()

    const after = el.getBoundingClientRect().height
    expect(after).toBeGreaterThan(before)
  })

  test("shrinks back down when content is removed", async () => {
    const el = await mount(markup({ value: "one\ntwo\nthree\nfour\nfive\nsix" }), {
      "cw--autogrow": AutogrowController
    })
    await settle()
    const grown = el.getBoundingClientRect().height

    el.value = "one line"
    el.dispatchEvent(new Event("input"))
    await settle()

    const shrunk = el.getBoundingClientRect().height
    expect(shrunk).toBeLessThan(grown)
  })

  test("stops growing at maxRows and switches to a scrollbar instead", async () => {
    const el = await mount(markup({ maxRows: 3 }), { "cw--autogrow": AutogrowController })
    await settle()

    el.value = Array.from({ length: 20 }, (_, i) => `line ${i}`).join("\n")
    el.dispatchEvent(new Event("input"))
    await settle()

    const height = el.getBoundingClientRect().height

    // Adding even more content past the cap must not grow the box any further.
    el.value += "\nanother line past the cap"
    el.dispatchEvent(new Event("input"))
    await settle()
    expect(el.getBoundingClientRect().height).toBe(height)

    // ...but the content is still there and reachable by scrolling, not truncated.
    expect(el.scrollHeight).toBeGreaterThan(el.clientHeight)
  })

  test("a Turbo-cache-restored textarea (content present, no inline sizing) is sized correctly on (re)connect", async () => {
    // Simulate what a snapshot restore hands back: markup with real content but no
    // live `style.height` — connect() must size it immediately, not only in reaction
    // to a later `input` event.
    const el = await mount(markup({ value: "one\ntwo\nthree\nfour\nfive" }), {
      "cw--autogrow": AutogrowController
    })
    await settle()

    expect(el.style.height).toMatch(/px$/)
    expect(el.getBoundingClientRect().height).toBeGreaterThan(20) // sized to its 5 lines, not collapsed
  })
})
