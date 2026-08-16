import * as Turbo from "@hotwired/turbo"
import { afterEach, describe, expect, test } from "vitest"
import { registerCrosswireStreamActions } from "../../app/assets/javascripts/crosswire/stream_actions.js"
import { captureEvents } from "./setup.js"

// Browser tier (docs/COMPONENT_CONTRACT.md: real Turbo for anything the jsdom decision
// table in stream_actions.test.js cannot honestly cover) — REAL @hotwired/turbo, REAL
// Turbo.renderStreamMessage, a REAL <turbo-stream> custom element parsing and applying
// the action, and (the one thing genuinely impossible to fake convincingly) a REAL
// morph confirming method="morph" still passes through versioned_replace exactly as it
// does through Turbo's own built-in replace.
//
// registerCrosswireStreamActions() runs once for the whole file — `Turbo.StreamActions`
// is a plain object Turbo itself owns for the life of the module, so there is nothing
// to tear down between tests (unlike a Stimulus registration, which is scoped to an
// Application instance created fresh per test elsewhere in this suite).
registerCrosswireStreamActions(Turbo)

function stream({ action = "versioned_replace", target, method, template }) {
  const methodAttr = method ? ` method="${method}"` : ""
  return `<turbo-stream action="${action}" target="${target}"${methodAttr}><template>${template}</template></turbo-stream>`
}

// `<turbo-stream>` is a custom element whose connectedCallback -> render() ->
// performAction() chain is fully async (StreamElement awaits `nextRepaint()` before
// invoking the action) — `Turbo.renderStreamMessage` returns long before
// versionedReplace has actually run. Every test below awaits this after rendering a
// message and before asserting on its effect.
async function settle() {
  await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
}

afterEach(() => {
  document.body.innerHTML = ""
})

describe("versioned_replace — real Turbo.renderStreamMessage", () => {
  test("a fresher payload (data-cw-version greater than the page's) applies", async () => {
    document.body.innerHTML = `<div id="widget" data-cw-version="1">stale</div>`

    Turbo.renderStreamMessage(
      stream({ target: "widget", template: `<div id="widget" data-cw-version="2">fresh</div>` })
    )

    await settle()

    const widget = document.getElementById("widget")
    expect(widget.textContent).toBe("fresh")
    expect(widget.dataset.cwVersion).toBe("2")
  })

  test("a stale payload (data-cw-version less than or equal to the page's) is skipped", async () => {
    document.body.innerHTML = `<div id="widget" data-cw-version="5">current</div>`

    Turbo.renderStreamMessage(
      stream({ target: "widget", template: `<div id="widget" data-cw-version="5">redelivered</div>` })
    )

    await settle()

    // Equal version: a redelivery of a message this page already applied, not a
    // genuine update — content must NOT change.
    expect(document.getElementById("widget").textContent).toBe("current")

    Turbo.renderStreamMessage(
      stream({ target: "widget", template: `<div id="widget" data-cw-version="3">older</div>` })
    )

    await settle()

    // Strictly older: also skipped.
    expect(document.getElementById("widget").textContent).toBe("current")
  })

  test("a page target with no data-cw-version yet applies unconditionally (fail open toward freshness)", async () => {
    document.body.innerHTML = `<div id="widget">never versioned</div>`

    Turbo.renderStreamMessage(
      stream({ target: "widget", template: `<div id="widget" data-cw-version="1">first version</div>` })
    )

    await settle()

    const widget = document.getElementById("widget")
    expect(widget.textContent).toBe("first version")
    expect(widget.dataset.cwVersion).toBe("1")
  })

  test('method="morph" passes through: the live <input> node (and its focus) survives, proving a real morph ran rather than a plain replaceWith', async () => {
    document.body.innerHTML = `
      <div id="widget" data-cw-version="1">
        <input id="widget-input">
      </div>`
    const input = document.getElementById("widget-input")
    input.focus()
    expect(document.activeElement).toBe(input)

    // A plain replace (StreamActions.replace without method="morph") calls
    // targetElement.replaceWith(...), which destroys the whole subtree and builds a
    // BRAND NEW <input> node — focus is lost, because the node that was focused no
    // longer exists in the document. morphElements patches idiomorph-matched nodes in
    // place instead, so the SAME <input> node (and therefore its focus) survives.
    // This only tells us anything because it is real @hotwired/turbo actually
    // morphing — the jsdom tier only ever asserts on which `this` gets passed to a
    // SPIED replace, never on what morphElements itself really does to the DOM.
    Turbo.renderStreamMessage(
      stream({
        target: "widget",
        method: "morph",
        template: `<div id="widget" data-cw-version="2"><input id="widget-input"></div>`
      })
    )

    await settle()

    const widget = document.getElementById("widget")
    expect(widget.dataset.cwVersion).toBe("2")
    expect(document.getElementById("widget-input")).toBe(input)
    expect(document.activeElement).toBe(input)
  })

  test("a skip dispatches cw--stream:skipped at the document level, with the version detail", async () => {
    document.body.innerHTML = `<div id="widget" data-cw-version="5">current</div>`
    const seen = captureEvents("cw--stream:skipped")

    Turbo.renderStreamMessage(
      stream({ target: "widget", template: `<div id="widget" data-cw-version="2">stale</div>` })
    )

    await settle()

    expect(seen).toHaveLength(1)
    expect(seen[0].detail).toEqual({ action: "versioned_replace", payloadVersion: 2, pageVersion: 5 })
  })
})
