import { describe, expect, test } from "vitest"
import { Application } from "@hotwired/stimulus"
import FocusTrapController from "../../app/assets/javascripts/crosswire/controllers/focus_trap_controller.js"

// Browser tier (docs/COMPONENT_CONTRACT.md: "Browser mode for anything touching
// focus, <dialog>, IntersectionObserver, or positioning — jsdom cannot test those
// honestly"). This applies to focus-trap almost in its entirety: jsdom implements no
// layout at all, so `element.offsetParent` — the visibility check the controller uses
// to decide what counts as "focusable" — is unconditionally `null` for every element
// there, real or not (verified directly; see focus_trap_controller.test.js). That
// means jsdom can never honestly observe more than zero focusable descendants, so it
// is structurally incapable of testing the thing this component mostly exists to do:
// cycle Tab between multiple real focusable children, in the order the browser
// actually computes, skipping ones that become disabled or hidden along the way.
// jsdom's tier sticks to wiring, values, events, teardown, the missing-class guard,
// the `initial`-selector path, and the no-focusable-descendants fallback — all of
// which are honestly testable there. Everything below is not: it needs a real
// rendering engine, so it lives here.
//
// Run with `npm run test:browser` after `npx playwright install chromium`. As of this
// writing vitest.config.js does not yet define the `browser` project the package.json
// script points at — wiring that up is tracked separately from this primitive's
// implementation, same as every other crosswire controller's browser tier (see
// intersection_controller.browser.test.js). The assertions below are written against
// real browser APIs (real layout, real focus/blur, a real offsetParent) so they are
// correct the day that project exists, not aspirational pseudocode.
//
// Every keydown here is dispatched synthetically (`element.dispatchEvent`) rather
// than via a simulated native key press. That is deliberate, not a shortcut: this
// controller never relies on the browser's own native Tab-traversal to move focus —
// it reads the key, decides the target itself, and calls `.focus()` explicitly. A
// dispatched KeyboardEvent exercises exactly the same code path a real key press
// would drive through Stimulus's action system, while keeping these tests runnable
// as ordinary scripted DOM assertions rather than OS-level input simulation.

function markup({ active = true, initial = null, inner = "" } = {}) {
  return `
    <div id="trap"
         tabindex="0"
         data-controller="cw--focus-trap"
         data-cw--focus-trap-active-value="${active}"
         ${initial ? `data-cw--focus-trap-initial-value="${initial}"` : ""}
         data-action="keydown.tab->cw--focus-trap#cycle keydown.shift+tab->cw--focus-trap#cycle">
      ${inner}
    </div>`
}

function tab({ shiftKey = false } = {}) {
  return new KeyboardEvent("keydown", { key: "Tab", shiftKey, bubbles: true, cancelable: true })
}

function start(html) {
  document.body.innerHTML = html
  const application = Application.start()
  application.register("cw--focus-trap", FocusTrapController)
  return application
}

function stop(application) {
  application.stop()
  document.body.innerHTML = ""
}

describe("cw--focus-trap (real browser layout and focus)", () => {
  test("focuses the first focusable child on activate when no initial is given", async () => {
    const application = start(
      markup({
        inner: `<button id="first">First</button><button id="second">Second</button>`
      })
    )

    expect(document.activeElement.id).toBe("first")

    stop(application)
  })

  test("Tab from the last focusable child wraps to the first", async () => {
    const application = start(
      markup({
        inner: `<button id="first">First</button><button id="second">Second</button><button id="third">Third</button>`
      })
    )

    document.getElementById("third").focus()
    const event = tab()
    document.getElementById("third").dispatchEvent(event)

    expect(event.defaultPrevented).toBe(true)
    expect(document.activeElement.id).toBe("first")

    stop(application)
  })

  test("Shift+Tab from the first focusable child wraps to the last", async () => {
    const application = start(
      markup({
        inner: `<button id="first">First</button><button id="second">Second</button><button id="third">Third</button>`
      })
    )

    document.getElementById("first").focus()
    const event = tab({ shiftKey: true })
    document.getElementById("first").dispatchEvent(event)

    expect(event.defaultPrevented).toBe(true)
    expect(document.activeElement.id).toBe("third")

    stop(application)
  })

  test("Tab in the interior is left to the browser's own order, not intercepted", async () => {
    const application = start(
      markup({
        inner: `<button id="first">First</button><button id="second">Second</button><button id="third">Third</button>`
      })
    )

    document.getElementById("second").focus()
    const event = tab()
    document.getElementById("second").dispatchEvent(event)

    // Not at a boundary — the controller must not preventDefault here, or it would
    // strand every browser at the second-to-last element forever.
    expect(event.defaultPrevented).toBe(false)

    stop(application)
  })

  test("re-queries focusable children on every Tab — an element inserted after activation is honoured immediately", async () => {
    const application = start(
      markup({ inner: `<button id="first">First</button><button id="second">Second</button>` })
    )

    // A frame render or stream append happening while the trap is active — the exact
    // scenario a cached focusable list would go stale against.
    const inserted = document.createElement("button")
    inserted.id = "inserted"
    inserted.textContent = "Inserted"
    document.getElementById("trap").appendChild(inserted)

    document.getElementById("second").focus()
    const event = tab()
    document.getElementById("second").dispatchEvent(event)

    expect(event.defaultPrevented).toBe(true)
    expect(document.activeElement.id).toBe("inserted")

    stop(application)
  })

  test("skips a descendant that became disabled while the trap is active", async () => {
    const application = start(
      markup({
        inner: `<button id="first">First</button><button id="second">Second</button><button id="third">Third</button>`
      })
    )

    document.getElementById("second").disabled = true

    document.getElementById("first").focus()
    const event = tab()
    document.getElementById("first").dispatchEvent(event)

    // Not a boundary case for the ORIGINAL list, so the controller leaves it to the
    // browser's default order — which, with "second" disabled and thus unfocusable,
    // lands natively on "third".
    expect(event.defaultPrevented).toBe(false)

    stop(application)
  })

  test("skips a descendant that became hidden (display: none) while the trap is active, wrapping past it", async () => {
    const application = start(
      markup({
        inner: `<button id="first">First</button><button id="second">Second</button>`
      })
    )

    document.getElementById("second").style.display = "none"

    document.getElementById("first").focus()
    const event = tab()
    document.getElementById("first").dispatchEvent(event)

    // "first" is now the ONLY focusable child, so it is simultaneously the first and
    // last — Tab from it must wrap right back to itself rather than escaping the trap.
    expect(event.defaultPrevented).toBe(true)
    expect(document.activeElement.id).toBe("first")

    stop(application)
  })

  test("focuses the initial selector on activate when given", async () => {
    const application = start(
      markup({
        initial: "#second",
        inner: `<button id="first">First</button><button id="second">Second</button>`
      })
    )

    expect(document.activeElement.id).toBe("second")

    stop(application)
  })
})
