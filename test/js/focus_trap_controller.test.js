import { describe, expect, test } from "vitest"
import FocusTrapController from "../../app/assets/javascripts/crosswire/controllers/focus_trap_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--focus-trap": FocusTrapController }

// jsdom does not implement layout at all, so `element.offsetParent` is
// unconditionally `null` for every element regardless of real visibility — verified
// directly against the jsdom version this project pins (see the controller's own
// docstring). #focusableChildren() filters on `offsetParent !== null`, so under jsdom
// it can never observe a focusable descendant, full stop: a real `<button>` child and
// a genuinely absent one look identical here.
//
// That is a real, accepted limit of this tier, not a bug to work around with a stub —
// per docs/COMPONENT_CONTRACT.md, "jsdom's focus model is unreliable; do not write
// jsdom tests that pretend to verify tab order." So this file sticks to what IS
// honestly testable without a real layout engine: wiring, values, events, teardown,
// the missing-class guard, the `initial` selector path (which bypasses the
// offsetParent filter entirely — it trusts the caller's selector outright), and the
// no-focusable-descendants fallback (which jsdom actually exercises correctly,
// precisely because it always sees zero focusable children). Real multi-element Tab
// order — wrapping between several focusable siblings, skipping ones that go
// `disabled` mid-trap, re-querying after a DOM mutation — can only be verified
// against a real layout engine and lives exclusively in
// focus_trap_controller.browser.test.js.

function trapMarkup({ active = true, initial = null, activeClass = null, inner = "" } = {}) {
  return `
    <div id="trap"
         data-controller="cw--focus-trap"
         data-cw--focus-trap-active-value="${active}"
         ${initial ? `data-cw--focus-trap-initial-value="${initial}"` : ""}
         ${activeClass ? `data-cw--focus-trap-active-class="${activeClass}"` : ""}
         data-action="keydown.tab->cw--focus-trap#cycle keydown.shift+tab->cw--focus-trap#cycle">
      ${inner}
    </div>`
}

function wrapperMarkup(trapOptions = {}, { opener = false, escapeTarget = false } = {}) {
  return `
    <div>
      ${opener ? `<button id="opener">Open</button>` : ""}
      ${trapMarkup(trapOptions)}
      ${escapeTarget ? `<button id="escape-target">Escape</button>` : ""}
    </div>`
}

function tab({ shiftKey = false } = {}) {
  return new KeyboardEvent("keydown", { key: "Tab", shiftKey, bubbles: true, cancelable: true })
}

describe("cw--focus-trap", () => {
  // --- activation on connect, and the no-focusable-descendants fallback ------------

  test("activates on connect by default, focusing the container when there are no focusable descendants", async () => {
    const el = await mount(trapMarkup(), CONTROLLERS)
    expect(document.activeElement).toBe(el)
    expect(el.getAttribute("tabindex")).toBe("-1")
  })

  test("does not activate on connect when active is false", async () => {
    const el = await mount(wrapperMarkup({ active: false }, { opener: true }))
    expect(document.activeElement).not.toBe(el.querySelector("#trap"))
  })

  test("focuses the initial selector when given, bypassing the empty-under-jsdom focusable list", async () => {
    const el = await mount(
      trapMarkup({ initial: "#target", inner: `<input id="target">` }),
      CONTROLLERS
    )
    expect(document.activeElement).toBe(el.querySelector("#target"))
  })

  test("falls back to the container when the initial selector matches nothing", async () => {
    const el = await mount(trapMarkup({ initial: "#nope" }), CONTROLLERS)
    expect(document.activeElement).toBe(el)
  })

  // --- R4 / R4a: single write path, no phantom event on hydration -------------------

  test("does not announce activated on initial connect", async () => {
    const activated = captureEvents("cw--focus-trap:activated")
    await mount(trapMarkup(), CONTROLLERS)
    expect(activated).toHaveLength(0)
  })

  test("dispatches activated and released when the value changes", async () => {
    const activated = captureEvents("cw--focus-trap:activated")
    const released = captureEvents("cw--focus-trap:released")
    const el = await mount(trapMarkup({ active: false }), CONTROLLERS)

    el.setAttribute("data-cw--focus-trap-active-value", "true")
    await nextFrame()
    expect(activated).toHaveLength(1)
    expect(activated[0].detail.active).toBe(true)

    el.setAttribute("data-cw--focus-trap-active-value", "false")
    await nextFrame()
    expect(released).toHaveLength(1)
    expect(released[0].detail.active).toBe(false)
  })

  // --- restoring focus (activation-time snapshot, not connect-time) -----------------

  test("restores focus to whatever was focused before activation, on release", async () => {
    const el = await mount(wrapperMarkup({ active: false }, { opener: true }), CONTROLLERS)
    const trap = el.querySelector("#trap")
    const opener = el.querySelector("#opener")

    opener.focus()
    expect(document.activeElement).toBe(opener)

    trap.setAttribute("data-cw--focus-trap-active-value", "true")
    await nextFrame()
    expect(document.activeElement).toBe(trap) // took focus itself (no focusable children under jsdom)

    trap.setAttribute("data-cw--focus-trap-active-value", "false")
    await nextFrame()
    expect(document.activeElement).toBe(opener)
  })

  test("restores focus to whatever was focused before activation, on disconnect", async () => {
    const el = await mount(wrapperMarkup({ active: false }, { opener: true }), CONTROLLERS)
    const trap = el.querySelector("#trap")
    const opener = el.querySelector("#opener")

    opener.focus()
    trap.setAttribute("data-cw--focus-trap-active-value", "true")
    await nextFrame()

    trap.remove()
    await nextFrame()

    expect(document.activeElement).toBe(opener)
  })

  // --- escaped focus gets pulled back, and R7: the listener is actually removed ----

  test("pulls focus back when it escapes the trap while active, and stops once released", async () => {
    const el = await mount(wrapperMarkup({ active: true }, { escapeTarget: true }), CONTROLLERS)
    const trap = el.querySelector("#trap")
    const escapeTarget = el.querySelector("#escape-target")

    expect(document.activeElement).toBe(trap)

    // The recapture happens synchronously inside the focusin handler, so by the time
    // .focus() returns, focus has already been pulled back — there is nothing to
    // observe in between.
    escapeTarget.focus()
    expect(document.activeElement).toBe(trap)

    trap.setAttribute("data-cw--focus-trap-active-value", "false")
    await nextFrame()

    // R7: the document-level focusin listener must actually be gone, not merely
    // no-op-ing — otherwise this is exactly the per-visit leak Turbo's snapshot cache
    // turns into a real bug.
    escapeTarget.focus()
    expect(document.activeElement).toBe(escapeTarget)
  })

  // --- Tab handling with no focusable descendants (honestly testable under jsdom) --

  test("cycle: does nothing when inactive", async () => {
    const el = await mount(trapMarkup({ active: false }), CONTROLLERS)
    const event = tab()
    el.dispatchEvent(event)
    expect(event.defaultPrevented).toBe(false)
  })

  test("cycle: with no focusable descendants, pins focus to the container and prevents default", async () => {
    const el = await mount(trapMarkup(), CONTROLLERS)
    const event = tab()
    el.dispatchEvent(event)
    expect(event.defaultPrevented).toBe(true)
    expect(document.activeElement).toBe(el)
    expect(el.getAttribute("tabindex")).toBe("-1")
  })

  test("cycle: shift+tab also pins focus to the container when there are no focusable descendants", async () => {
    const el = await mount(trapMarkup(), CONTROLLERS)
    const event = tab({ shiftKey: true })
    el.dispatchEvent(event)
    expect(event.defaultPrevented).toBe(true)
    expect(document.activeElement).toBe(el)
  })

  // --- R3: the missing-class guard --------------------------------------------------

  test("does not throw when no active class is given", async () => {
    const el = await mount(trapMarkup({ active: false }), CONTROLLERS)
    expect(() => {
      el.setAttribute("data-cw--focus-trap-active-value", "true")
    }).not.toThrow()
    await nextFrame()
    expect(document.activeElement).toBe(el)
    expect(el.className).toBe("")
  })

  test("toggles the active class when one is given", async () => {
    const el = await mount(trapMarkup({ activeClass: "is-trapped" }), CONTROLLERS)
    expect(el.classList.contains("is-trapped")).toBe(true)

    el.setAttribute("data-cw--focus-trap-active-value", "false")
    await nextFrame()
    expect(el.classList.contains("is-trapped")).toBe(false)
  })
})
