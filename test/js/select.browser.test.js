import { morphElements } from "@hotwired/turbo"
import { afterEach, describe, expect, test } from "vitest"

// Browser tier (docs/COMPONENT_CONTRACT.md: "Browser mode for anything touching
// focus, <dialog>, IntersectionObserver, or positioning — jsdom cannot test those
// honestly"). Required here for a different reason than usual: this is the ONE
// non-Safe UI-tier Morph verdict shipped so far (ui_contract_audit_test.rb check 10
// requires a browser test per non-Safe verdict — see docs/MORPH.md), and jsdom's own
// <select>/<option> implementation is exactly the kind of native-control-sync
// behaviour that has to be verified against a REAL browser engine to mean anything.
//
// Crosswire::UI::Select ships no controller (Rule 0 — see its own docstring), so
// this is a pure DOM/morphElements test: no Stimulus Application, no controller
// class, nothing to boot. It proves the ONE claim the Morph: Server-owned verdict
// makes — that a server-rendered `<option selected>` in the INCOMING html actually
// wins, visibly (`select.value`), over whatever the LIVE control currently shows —
// through a real `@hotwired/turbo` `morphElements` call in a real browser.
//
// Run with `npm run test:browser` after `npx playwright install chromium` — see
// vitest.browser.config.js.

afterEach(() => {
  document.body.innerHTML = ""
})

function select(selectedValue) {
  document.body.innerHTML = `
    <select id="country" class="cw-select cw-focusable" name="country">
      <option value="us"${selectedValue === "us" ? " selected" : ""}>United States</option>
      <option value="ca"${selectedValue === "ca" ? " selected" : ""}>Canada</option>
      <option value="mx"${selectedValue === "mx" ? " selected" : ""}>Mexico</option>
    </select>`
  return document.getElementById("country")
}

function incomingWithSelected(selectedValue) {
  const incoming = document.createElement("select")
  incoming.id = "country"
  incoming.className = "cw-select cw-focusable"
  incoming.setAttribute("name", "country");
  ["us", "ca", "mx"].forEach((value) => {
    const option = document.createElement("option")
    option.value = value
    option.textContent = { us: "United States", ca: "Canada", mx: "Mexico" }[value]
    if (value === selectedValue) option.setAttribute("selected", "")
    incoming.append(option)
  })
  return incoming
}

describe("Crosswire::UI::Select — Morph: Server-owned", () => {
  test("a morph applies the server-rendered selected option even though the control's value never changed client-side", async () => {
    const el = select("us")
    expect(el.value).toBe("us")

    // Exactly what a page-level morph after a form submission looks like: the
    // server now renders "ca" as selected. Nothing on the client touched this
    // control in between — this is the plainest case the Server-owned verdict
    // has to cover before any of the harder ones below.
    morphElements(el, incomingWithSelected("ca"))
    await Promise.resolve()

    expect(el.value).toBe("ca")
    expect(el.querySelector('option[value="ca"]').selected).toBe(true)
    expect(el.querySelector('option[value="us"]').selected).toBe(false)
  })

  test("a morph applies the server's new selection even after the user changed it client-side first", async () => {
    const el = select("us")

    // The user picks a different option themselves — the live control now
    // diverges from what was last server-rendered, same as a real interaction
    // would produce, before any morph happens at all.
    el.value = "mx"
    expect(el.value).toBe("mx")

    // The server was never told about that client-side pick (no round trip
    // happened) — its next render still reflects ITS OWN last-known state ("ca"),
    // which is what the Server-owned verdict says must win.
    morphElements(el, incomingWithSelected("ca"))
    await Promise.resolve()

    expect(el.value).toBe("ca")
    expect(el.querySelector('option[value="ca"]').selected).toBe(true)
    expect(el.querySelector('option[value="mx"]').selected).toBe(false)
  })

  test("every other attribute (class, aria-invalid) still morphs normally alongside the selection", async () => {
    const el = select("us")
    expect(el.classList.contains("cw-select")).toBe(true)

    const incoming = incomingWithSelected("ca")
    incoming.setAttribute("aria-invalid", "true")

    morphElements(el, incoming)
    await Promise.resolve()

    expect(el.value).toBe("ca")
    expect(el.getAttribute("aria-invalid")).toBe("true")
    expect(el.classList.contains("cw-select")).toBe(true)
  })
})
