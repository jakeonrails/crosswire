import { describe, expect, test } from "vitest"
import { userEvent } from "vitest/browser"
import DialogController from "../../app/assets/javascripts/crosswire/controllers/dialog_controller.js"
import { mount } from "./setup.js"

// Browser tier (docs/COMPONENT_CONTRACT.md: "Browser mode for anything touching focus,
// <dialog>, IntersectionObserver, or positioning — jsdom cannot test those honestly").
// jsdom (as pinned in package.json) does not implement HTMLDialogElement's
// showModal()/show()/close() at all — verified directly against the pinned version —
// so dialog_controller.test.js only proves the controller's *wiring* against hand-
// rolled polyfills of those methods: value sync, event sequencing, the SSR-upgrade
// path, the morph/cache defence. None of that is "does the rest of the page actually
// go inert", "does Escape actually close it", or "is the scrollbar-gutter compensation
// actually preventing layout shift" — those claims can only be honestly tested against
// a real browser's top layer and inertness implementation, which is what this file does.
//
// Run with `npm run test:browser` after `npx playwright install chromium` — wired up
// in vitest.browser.config.js. The assertions below are written against real browser
// APIs (a real <dialog>, a real top layer, real inertness, real focus).
//
// Uses the shared `mount()` helper from setup.js rather than a hand-rolled
// Application.start()/register() so this file gets the same connect-before-interact
// guarantee (mount awaits a tick after registering, letting Stimulus's MutationObserver
// actually connect the controller) and the same load-bearing afterEach teardown order
// (DOM cleared and a tick awaited BEFORE Application#stop(), so disconnect() actually
// runs — see setup.js and the gotchas table in docs/COMPONENT_CONTRACT.md). Without
// that, DialogController's shared static scroll-lock counter leaks across tests.

function markup({ open = false } = {}) {
  return `
    <button id="outside">Outside control</button>
    <div data-controller="cw--dialog" data-cw--dialog-open-value="${open}">
      <button data-cw--dialog-target="trigger"
              data-action="click->cw--dialog#open"
              aria-haspopup="dialog" aria-controls="d1">Open</button>
      <dialog id="d1"
              data-cw--dialog-target="panel"
              data-action="close->cw--dialog#syncClosed cancel->cw--dialog#cancel click->cw--dialog#backdropClick turbo:before-morph-element->cw--dialog#beforeMorph turbo:before-cache->cw--dialog#reset"
              style="width: 20rem;">
        <h2 id="d1-title">Title</h2>
        <p>Body content.</p>
        <button data-action="click->cw--dialog#close" aria-label="Close">&times;</button>
      </dialog>
    </div>`
}

async function boot(opts) {
  await mount(markup(opts), { "cw--dialog": DialogController })
  return {
    el: document.body.querySelector("[data-controller='cw--dialog']"),
    panel: document.getElementById("d1"),
    trigger: document.body.querySelector("[data-cw--dialog-target='trigger']"),
    outside: document.getElementById("outside")
  }
}

async function settle() {
  await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
}

describe("cw--dialog (real browser <dialog>)", () => {
  test("showModal() actually opens it on the top layer and it is the top-layer element", async () => {
    const { panel, trigger } = await boot()
    trigger.click()
    await settle()

    expect(panel.open).toBe(true)
    expect(panel.matches(":modal")).toBe(true)
  })

  test("the rest of the document is genuinely inert while modal — outside controls cannot be focused", async () => {
    const { trigger, outside } = await boot()
    trigger.click()
    await settle()

    outside.focus()
    expect(document.activeElement).not.toBe(outside)
  })

  // Escape-closes-<dialog> is a native default action the UA wires to a *trusted*
  // keydown — dispatching a synthetic KeyboardEvent (`element.dispatchEvent(new
  // KeyboardEvent(...))`) never triggers it, isTrusted is false either way. That was
  // a genuine bug in this test as first written: it dispatched a synthetic Escape and
  // asserted the dialog had closed, which could never pass in a real browser. Fixed by
  // driving Escape through `userEvent.keyboard`, which goes through the Playwright
  // provider's real input automation (a genuinely trusted key press).
  test("Escape closes the dialog natively and the controller syncs its value", async () => {
    const { el, panel, trigger } = await boot()
    trigger.click()
    await settle()
    expect(panel.open).toBe(true)

    await userEvent.keyboard("{Escape}")
    await settle()

    expect(panel.open).toBe(false)
    expect(el.getAttribute("data-cw--dialog-open-value")).toBe("false")
  })

  test("focus returns to the trigger after Escape, not to <body>", async () => {
    const { panel, trigger } = await boot()
    trigger.focus()
    trigger.click()
    await settle()

    await userEvent.keyboard("{Escape}")
    await settle()

    expect(document.activeElement).toBe(trigger)
  })

  test("a real click on the dialog's own padding box (the backdrop area) closes it", async () => {
    const { panel, trigger } = await boot()
    trigger.click()
    await settle()

    const rect = panel.getBoundingClientRect()
    // Click just inside the dialog's own box but outside any content — since the
    // dialog element covers the whole padding box, a coordinate at its very edge
    // hits the <dialog> itself, not a descendant.
    panel.dispatchEvent(new MouseEvent("click", {
      bubbles: true,
      clientX: rect.left + 1,
      clientY: rect.top + 1
    }))
    await settle()

    expect(panel.open).toBe(false)
  })

  // `window.scrollTo()` is a genuine bug in this test as first written: CSS
  // `overflow: hidden` on the root element only removes the scrollBAR and blocks
  // USER-driven scrolling (wheel, touch, keyboard, dragging the scrollbar) — it does
  // NOT block programmatic `scrollTo`/`scrollBy`/`scrollTop =`, which is explicitly
  // still permitted by the CSS Overflow spec. So `window.scrollTo(0, 500)` was always
  // going to "succeed" regardless of whether the lock worked, and the assertion would
  // have passed for the wrong reason even if the lock were entirely absent — it never
  // exercised the thing it claims to. Fixed by driving a real trusted wheel gesture via
  // `userEvent.wheel`, which is exactly the kind of input `overflow: hidden` is
  // documented to block.
  test("scroll lock actually prevents the page behind the modal from scrolling", async () => {
    document.body.style.height = "5000px"
    const { panel, trigger } = await boot()

    window.scrollTo(0, 0)
    trigger.click()
    await settle()

    await userEvent.wheel(panel, { delta: { y: 500 } })
    await settle()

    expect(window.scrollY).toBe(0)

    document.body.style.height = ""
  })

  test("scrollbar-gutter compensation keeps the page's content box width stable while locked", async () => {
    const { trigger } = await boot()
    const before = document.documentElement.getBoundingClientRect().width

    trigger.click()
    await settle()
    const during = document.documentElement.getBoundingClientRect().width

    expect(during).toBe(before)
  })

  test("Turbo morph hazard: a dialog left open across a morph is not silently struck inert-forever", async () => {
    // Regression guard for the documented hazard: Idiomorph gives `open` no special
    // handling, and removing it per the HTML spec does NOT call close() — so a naive
    // morph would leave the document inert with close() reduced to a no-op. The
    // controller cancels turbo:before-morph-element on the panel while open; assert
    // that a dialog opened, "morphed" (attribute stripped exactly as Idiomorph would),
    // and then asked to close via the controller's own path still actually closes,
    // rather than leaving the page dead.
    const { el, panel, trigger } = await boot()
    trigger.click()
    await settle()
    expect(panel.open).toBe(true)

    const morphEvent = new Event("turbo:before-morph-element", { bubbles: true, cancelable: true })
    panel.dispatchEvent(morphEvent)
    expect(morphEvent.defaultPrevented).toBe(true) // morph was refused; open state preserved

    // Now drive a normal close through the controller, proving the dialog is still a
    // live, controllable modal rather than dead inert markup.
    el.querySelector("[aria-label='Close']").click()
    await settle()

    expect(panel.open).toBe(false)
    expect(document.body.matches(":not([inert])") || !document.body.inert).toBe(true)
  })

  // The second, narrower guard added alongside `preserve` (see the MORPH HAZARD note
  // in dialog_controller.js): seanpdoyle's exact turbo#1239 fix, installed straight in
  // connect()/disconnect() rather than through data-action, scoped to this instance's
  // own panel. In today's wiring the element-wide guard above always wins first — this
  // dispatches the narrower turbo:before-morph-attribute event directly, bypassing the
  // element-wide guard (a different event entirely), to exercise this second guard on
  // its own rather than only ever seeing it shadowed.
  test("the scoped open-removal guard cancels the raw attribute removal and calls close() itself, verbatim per turbo#1239", async () => {
    const { panel, trigger } = await boot()
    trigger.click()
    await settle()
    expect(panel.open).toBe(true)

    let closeFired = false
    panel.addEventListener("close", () => { closeFired = true })

    const event = new CustomEvent("turbo:before-morph-attribute", {
      bubbles: true,
      cancelable: true,
      detail: { attributeName: "open", mutationType: "remove" }
    })
    panel.dispatchEvent(event)
    await settle()

    expect(event.defaultPrevented).toBe(true) // the raw removal itself was refused...
    expect(panel.open).toBe(false) // ...but close() ran for real, so it is genuinely closed
    expect(closeFired).toBe(true)
    expect(document.body.matches(":not([inert])") || !document.body.inert).toBe(true)
  })

  test("the scoped open-removal guard ignores updates to other attributes and other mutation types", async () => {
    const { panel, trigger } = await boot()
    trigger.click()
    await settle()

    const updateEvent = new CustomEvent("turbo:before-morph-attribute", {
      bubbles: true,
      cancelable: true,
      detail: { attributeName: "open", mutationType: "update" }
    })
    panel.dispatchEvent(updateEvent)
    expect(updateEvent.defaultPrevented).toBe(false)

    const otherAttrEvent = new CustomEvent("turbo:before-morph-attribute", {
      bubbles: true,
      cancelable: true,
      detail: { attributeName: "class", mutationType: "remove" }
    })
    panel.dispatchEvent(otherAttrEvent)
    expect(otherAttrEvent.defaultPrevented).toBe(false)

    expect(panel.open).toBe(true)
  })

  test("the scoped open-removal guard is torn down on disconnect — R7", async () => {
    const { el, panel, trigger } = await boot()
    trigger.click()
    await settle()

    el.remove()
    await settle()

    const event = new CustomEvent("turbo:before-morph-attribute", {
      bubbles: true,
      cancelable: true,
      detail: { attributeName: "open", mutationType: "remove" }
    })
    panel.dispatchEvent(event)

    expect(event.defaultPrevented).toBe(false)
  })
})
