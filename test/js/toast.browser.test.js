import { Application } from "@hotwired/stimulus"
import { morphElements } from "@hotwired/turbo"
import { afterEach, describe, expect, test } from "vitest"
import DismissController from "../../app/assets/javascripts/crosswire/controllers/dismiss_controller.js"
import TimeoutController from "../../app/assets/javascripts/crosswire/controllers/timeout_controller.js"
import TransitionController from "../../app/assets/javascripts/crosswire/controllers/transition_controller.js"
import { nextFrame } from "./setup.js"

// Browser tier (docs/COMPONENT_CONTRACT.md), required by ui_contract_audit_test.rb
// check 10 for `Crosswire::UI::Toast`'s non-Safe Morph verdict (Excluded).
//
// FINDING (recorded in full in docs/BUILD-LOG.md — this file is the proof of it):
// the ui-tier spec's own §5 item 11 flagged a real open question — "bare
// morphElements may not honor turbo-permanent the way page renders do... investigate
// what actually preserves it at this layer". It DOES honour it, unconditionally. Read
// against the vendored @hotwired/turbo source
// (test/dummy/vendor/javascript/@hotwired--turbo.js): `morphElements()` (the function
// this whole package's morph testing imports) constructs `DefaultIdiomorphCallbacks`
// itself, inline — `Idiomorph.morph(currentElement, newElement, { callbacks: new
// DefaultIdiomorphCallbacks(callbacks) })`. `DefaultIdiomorphCallbacks#beforeNodeMorphed`
// short-circuits on `currentElement.hasAttribute("data-turbo-permanent")` BEFORE
// dispatching any `turbo:before-morph-*` event at all, and `beforeNodeRemoved`
// delegates to that exact same check. Nothing about this lives in
// `MorphingPageRenderer` (the class a real Turbo page visit uses) — it is baked into
// the shared low-level callback object BOTH a real page morph and a bare
// `morphElements()` call route through, so there was never a distinct "page render"
// code path to differ from in the first place. The tests below exercise that
// unconditionally, the same way `test/js/select.browser.test.js` and
// `test/js/morph.browser.test.js` already do for their own claims.
//
// Run with `npm run test:browser` after `npx playwright install chromium` — see
// vitest.browser.config.js.

let application

afterEach(async () => {
  document.body.innerHTML = ""
  await new Promise((resolve) => setTimeout(resolve, 0))
  application?.stop()
  application = undefined
})

// Mirrors app/views/crosswire/ui/_toast.html.erb for a default
// `cw.toast(message, severity: ..., timeout: delay)` — see Crosswire::UI::Toast's
// own `root_attrs`/`dismiss_trigger_attrs` for the exact attribute set and order.
function toastMarkup({ id, delay = 30, severity = "success", message = "Saved!" } = {}) {
  return `
    <div id="${id}" class="cw-toast cw-toast--${severity}"
         data-controller="cw--dismiss cw--timeout cw--transition"
         data-cw--dismiss-remove-value="true"
         data-cw--timeout-delay-value="${delay}"
         data-cw--transition-leave-class="cw-toast--leaving"
         data-cw--transition-leave-from-class="cw-toast--leave-from"
         data-cw--transition-leave-to-class="cw-toast--leave-to"
         data-action="cw--dismiss:dismissing->cw--transition#leave
                      mouseenter->cw--timeout#cancel
                      mouseleave->cw--timeout#restart
                      cw--timeout:elapsed->cw--dismiss#dismiss">
      <div class="cw-toast__body">${message}</div>
      <button type="button" class="cw-toast__dismiss" aria-label="Dismiss"
              data-action="click->cw--dismiss#dismiss"><span aria-hidden="true">&times;</span></button>
    </div>`
}

// Mirrors app/views/crosswire/ui/_toast_viewport.html.erb — see
// Crosswire::UI::ToastViewport#root_attrs. `data-turbo-permanent` carries no value
// in the shipped partial (a bare boolean attribute — `cw_attrs` renders `""` as
// exactly that), matching real markup precisely.
function viewportMarkup(innerHTML = "") {
  return `<div id="cw-toast-viewport" class="cw-toast-viewport" role="status"
               aria-live="polite" aria-atomic="false"
               data-turbo-permanent>${innerHTML}</div>`
}

function boot(bodyHTML) {
  document.body.innerHTML = bodyHTML
  application = Application.start()
  application.register("cw--dismiss", DismissController)
  application.register("cw--timeout", TimeoutController)
  application.register("cw--transition", TransitionController)
  return application
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

describe("Crosswire::UI::Toast + ToastViewport — Morph: Excluded, proven against a real morph", () => {
  test("a page-level morph whose incoming HTML renders no toasts at all leaves the live toast stack untouched", async () => {
    document.body.innerHTML =
      `<main id="page"><h1>Dashboard</h1>${viewportMarkup(
        toastMarkup({ id: "t1", message: "Saved!" }) + toastMarkup({ id: "t2", message: "Synced." })
      )}</main>`
    boot(document.body.innerHTML)
    await nextFrame()

    const page = document.getElementById("page")
    expect(document.getElementById("t1")).not.toBeNull()
    expect(document.getElementById("t2")).not.toBeNull()

    // The next page's own HTML: the viewport is rendered EMPTY (toasts are never
    // re-derived from any server-side state — see Crosswire::UI::Toast's own
    // docstring), and the rest of the page genuinely changed, so this proves the
    // morph actually ran rather than merely doing nothing at all.
    const incoming = document.createElement("main")
    incoming.id = "page"
    incoming.innerHTML = `<h1>Dashboard (3 new)</h1>${viewportMarkup()}`

    morphElements(page, incoming)
    await Promise.resolve()

    expect(page.querySelector("h1").textContent).toBe("Dashboard (3 new)") // the morph ran
    expect(document.getElementById("t1")).not.toBeNull() // untouched
    expect(document.getElementById("t2")).not.toBeNull() // untouched
    expect(document.getElementById("t1").textContent).toContain("Saved!")
    expect(document.getElementById("t2").textContent).toContain("Synced.")
  })

  test("the running cw--timeout/cw--transition controller instances survive the morph unchanged — not disconnected and reconnected", async () => {
    document.body.innerHTML = `<main id="page">${viewportMarkup(toastMarkup({ id: "t1", delay: 10000 }))}</main>`
    boot(document.body.innerHTML)
    await nextFrame()

    const toast = document.getElementById("t1")
    const timeoutBefore = application.getControllerForElementAndIdentifier(toast, "cw--timeout")
    const transitionBefore = application.getControllerForElementAndIdentifier(toast, "cw--transition")
    expect(timeoutBefore).not.toBeNull()

    const page = document.getElementById("page")
    const incoming = document.createElement("main")
    incoming.id = "page"
    incoming.innerHTML = viewportMarkup()

    morphElements(page, incoming)
    await Promise.resolve()

    // Same live JS objects, not new ones stood up by a disconnect/reconnect pair —
    // exactly what "data-turbo-permanent skips this node entirely" (not "skips it,
    // then quietly resets it") has to mean for a running timer to genuinely survive.
    expect(application.getControllerForElementAndIdentifier(document.getElementById("t1"), "cw--timeout"))
      .toBe(timeoutBefore)
    expect(application.getControllerForElementAndIdentifier(document.getElementById("t1"), "cw--transition"))
      .toBe(transitionBefore)
  })

  test("a toast appended into the container AFTER boot (the Turbo-Stream-append path) is protected by the same morph just as much as one rendered on first paint", async () => {
    document.body.innerHTML = `<main id="page">${viewportMarkup()}</main>`
    boot(document.body.innerHTML)
    await nextFrame()

    // Simulates exactly what a `<turbo-stream action="append">` does to the DOM: the
    // container already exists (data-turbo-permanent, stable id — rendered once, in
    // the layout); this response only ever appends into it.
    document.getElementById("cw-toast-viewport").insertAdjacentHTML("beforeend", toastMarkup({ id: "t-appended", message: "Order placed." }))
    await nextFrame()
    expect(document.getElementById("t-appended")).not.toBeNull()

    const page = document.getElementById("page")
    const incoming = document.createElement("main")
    incoming.id = "page"
    incoming.innerHTML = viewportMarkup()

    morphElements(page, incoming)
    await Promise.resolve()

    expect(document.getElementById("t-appended")).not.toBeNull()
    expect(document.getElementById("t-appended").textContent).toContain("Order placed.")
  })
})

describe("Crosswire::UI::ToastViewport — announcement via the PRE-EXISTING live region", () => {
  test("role/aria-live are already on the container before any toast is inserted, and a toast lands inside that same already-tagged region", async () => {
    document.body.innerHTML = viewportMarkup()
    const viewport = document.getElementById("cw-toast-viewport")

    // The structural precondition "the aria-live rule from the corpus" depends on:
    // the live region's role/aria-live exist BEFORE content is injected, not added at
    // the same moment as (or after) the content itself.
    expect(viewport.getAttribute("role")).toBe("status")
    expect(viewport.getAttribute("aria-live")).toBe("polite")
    expect(viewport.children).toHaveLength(0)

    viewport.insertAdjacentHTML("beforeend", toastMarkup({ id: "t1", message: "Saved!" }))

    // Same node, same attributes, now with content — never a fresh container created
    // at append time (which is the pattern that reliably fails to announce).
    expect(document.getElementById("cw-toast-viewport")).toBe(viewport)
    expect(viewport.getAttribute("role")).toBe("status")
    expect(viewport.getAttribute("aria-live")).toBe("polite")
    expect(viewport.contains(document.getElementById("t1"))).toBe(true)
  })
})

describe("Crosswire::UI::Toast — timeout dismissal works through the composed primitives", () => {
  test("auto-dismisses via the real cw--timeout -> cw--dismiss wiring, with no manual interaction", async () => {
    document.body.innerHTML = viewportMarkup(toastMarkup({ id: "t1", delay: 30 }))
    boot(document.body.innerHTML)
    await nextFrame()

    expect(document.getElementById("t1")).not.toBeNull()

    await wait(150) // delay (30ms) + the transition controller's fallback margin + slack

    expect(document.getElementById("t1")).toBeNull()
  })

  test("hovering pauses the timer (mouseenter->cancel) and leaving restarts it (mouseleave->restart)", async () => {
    document.body.innerHTML = viewportMarkup(toastMarkup({ id: "t1", delay: 40 }))
    boot(document.body.innerHTML)
    await nextFrame()

    const toast = document.getElementById("t1")
    toast.dispatchEvent(new MouseEvent("mouseenter", { bubbles: true }))

    await wait(80) // well past the original 40ms delay — cancelled, so still present
    expect(document.getElementById("t1")).not.toBeNull()

    toast.dispatchEvent(new MouseEvent("mouseleave", { bubbles: true }))
    await wait(150) // restarted at the full 40ms delay again + margin

    expect(document.getElementById("t1")).toBeNull()
  })
})

describe("Crosswire::UI::Toast — focus is never stolen", () => {
  test("an unrelated, focused control on the page is completely undisturbed by an auto-dismissing toast", async () => {
    document.body.innerHTML =
      `<input id="search" type="text">${viewportMarkup(toastMarkup({ id: "t1", delay: 30 }))}`
    boot(document.body.innerHTML)
    await nextFrame()

    const search = document.getElementById("search")
    search.focus()
    expect(document.activeElement).toBe(search)

    await wait(150)

    expect(document.getElementById("t1")).toBeNull() // it did dismiss
    expect(document.activeElement).toBe(search) // focus never moved
  })

  test("dismissing via the toast's own button (focus was on it) does not leave focus stranded on a detached node", async () => {
    document.body.innerHTML = viewportMarkup(toastMarkup({ id: "t1", delay: 10000 }))
    boot(document.body.innerHTML)
    await nextFrame()

    const dismissButton = document.querySelector("#t1 .cw-toast__dismiss")
    dismissButton.focus()
    expect(document.activeElement).toBe(dismissButton)

    dismissButton.click()
    await wait(200) // the leave transition's fallback timeout, then removal

    expect(document.getElementById("t1")).toBeNull()
    // `DismissController#complete()` relocates focus whenever it was inside the node
    // being removed (it was, here): it looks for the closest FOCUSABLE ANCESTOR of
    // the toast's parent (`target.parentElement?.closest("[tabindex], a, button")`)
    // — meant for widgets nested inside their own trigger (a menu item returning
    // focus to the menu button that opened it). A toast in a flat viewport has no
    // such ancestor, so the controller's own documented last resort applies:
    // `document.body`. The claim this test verifies is narrower than "focus lands
    // somewhere clever" — it is "focus is never left referencing the now-detached
    // node", which would otherwise stray a real screen reader user's context
    // entirely with no recovery path at all.
    expect(document.activeElement).toBe(document.body)
    expect(document.body.contains(document.activeElement)).toBe(true)
  })
})
