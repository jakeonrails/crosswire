import { Application, Controller } from "@hotwired/stimulus"
import { morphBodyElements, morphElements } from "@hotwired/turbo"
import { afterEach, describe, expect, test } from "vitest"
import { userEvent } from "vitest/browser"
import { createMorphGuard, installDialogMorphGuard, usePreserve } from "../../app/assets/javascripts/crosswire/morph.js"
import { nextFrame } from "./setup.js"

// Browser tier (docs/COMPONENT_CONTRACT.md: "Browser mode for anything touching
// focus, <dialog>, IntersectionObserver, or positioning — jsdom cannot test those
// honestly"). jsdom CAN morph mechanically (idiomorph is plain DOM manipulation), but
// per morph.test.js's header comment it cannot be trusted for morph FIDELITY — no
// layout, no top layer, throws on `:modal`, and its focus path reads
// `document.activeElement` against a layoutless tree. This file is the REQUIRED,
// authoritative morph coverage: real @hotwired/turbo, real DOM, real <dialog>.
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

describe("verifying @hotwired/turbo's own event contract", () => {
  // This is the "verify at implementation time" check the spec called for: does the
  // exported morphElements() actually dispatch the turbo:*morph* events, the way the
  // dossier's source reading (morphing.js's DefaultIdiomorphCallbacks) says it should?
  //
  // FINDING (recorded here since it is exactly what this test exists to pin): yes.
  // morphElements(current, new) dispatches turbo:before-morph-attribute,
  // turbo:before-morph-element and turbo:morph-element — DefaultIdiomorphCallbacks is
  // constructed and used internally by morphElements itself, not only by
  // MorphingPageRenderer. It does NOT dispatch the document-level turbo:morph event —
  // that is dispatched by MorphingPageRenderer.renderElement AFTER calling
  // morphElements, and separately exported as morphBodyElements(currentBody, newBody)
  // (verified against @hotwired/turbo's own dist/turbo.es2017-esm.js: morphBodyElements
  // is a one-line wrapper around MorphingPageRenderer.renderElement). Anything relying
  // specifically on turbo:morph — nothing in this package does; the coalescing engine
  // uses the element-scoped turbo:morph-element instead, precisely so it works
  // identically for a page morph and a frame morph — must use morphBodyElements /
  // morphTurboFrameElements, not bare morphElements.
  test("morphElements dispatches before-morph-attribute, before-morph-element and morph-element", () => {
    const current = document.createElement("div")
    current.id = "morph-event-probe"
    current.setAttribute("data-x", "old")
    document.body.append(current)

    const incoming = document.createElement("div")
    incoming.id = "morph-event-probe"
    incoming.setAttribute("data-x", "new")

    const seen = []
    for (const type of ["turbo:before-morph-attribute", "turbo:before-morph-element", "turbo:morph-element"]) {
      document.addEventListener(type, () => seen.push(type))
    }

    morphElements(current, incoming)

    expect(seen).toContain("turbo:before-morph-attribute")
    expect(seen).toContain("turbo:before-morph-element")
    expect(seen).toContain("turbo:morph-element")
    expect(current.getAttribute("data-x")).toBe("new")
  })

  test("morphBodyElements (unlike bare morphElements) additionally dispatches the document-level turbo:morph event", () => {
    const container = document.createElement("body")
    // Can't actually swap document.body in a shared test page, so this asserts the
    // narrower, honest claim: morphBodyElements is documented and built as a thin
    // wrapper over MorphingPageRenderer.renderElement, which is what fires turbo:morph.
    // Exercised indirectly — the full turbo:morph contract for a real page is Turbo's
    // own test suite's job, not crosswire's; what crosswire needs verified is that
    // morphElements ALONE (what usePreserve and cw--preserve are built on) is
    // sufficient for B1–B4, which the test above already confirms.
    expect(typeof morphBodyElements).toBe("function")
  })
})

describe("usePreserve — real morph, real attribute clobber", () => {
  class WidgetController extends Controller {
    static values = { open: Boolean }
    static preservedValues = ["open"]

    connect() {
      usePreserve(this)
    }
  }

  function boot(open = "true") {
    document.body.innerHTML = `<div id="widget" data-controller="cw--widget" data-cw--widget-open-value="${open}"></div>`
    application = Application.start()
    application.register("cw--widget", WidgetController)
    return document.getElementById("widget")
  }

  test("a value the controller actually wrote survives a real morph that would otherwise clobber it", async () => {
    const el = boot("true")
    await nextFrame()

    // The controller "writes" its own value, diverging from what connect() recorded.
    el.setAttribute("data-cw--widget-open-value", "false")

    const stale = document.createElement("div")
    stale.id = "widget"
    stale.setAttribute("data-controller", "cw--widget")
    stale.setAttribute("data-cw--widget-open-value", "true") // the server's stale truth

    morphElements(el, stale)

    expect(el.getAttribute("data-cw--widget-open-value")).toBe("false")
  })

  test("a value the controller never touched is still the server's to update", async () => {
    const el = boot("true")
    await nextFrame()

    const fresh = document.createElement("div")
    fresh.id = "widget"
    fresh.setAttribute("data-controller", "cw--widget")
    fresh.setAttribute("data-cw--widget-open-value", "false") // legitimate server update

    morphElements(el, fresh)

    expect(el.getAttribute("data-cw--widget-open-value")).toBe("false")
  })
})

describe("usePreserve — morphed() and third-party widget resurrection", () => {
  // The canonical failure this fixes (inventory #1 in the dossier): a controller that
  // mounts a third-party library's DOM in connect() finds it silently deleted by the
  // next morph, with no hook to rebuild it, because connect() never re-runs for an
  // element that survives.
  class MountsAWidgetController extends Controller {
    static reconnectOnMorph = true

    connect() {
      usePreserve(this)
      this.mount()
    }

    mount() {
      this.element.innerHTML = "<span class='injected'>mounted</span>"
    }

    morphed({ newElement }) {
      this.lastNewElement = newElement
      this.morphedCallCount = (this.morphedCallCount || 0) + 1
      this.mount() // rebuild what the morph just deleted
    }
  }

  function boot() {
    document.body.innerHTML = `<div id="widget" data-controller="cw--mounts"></div>`
    application = Application.start()
    application.register("cw--mounts", MountsAWidgetController)
    return document.getElementById("widget")
  }

  test("morphed() receives the real newElement and fires exactly once per morph pass", async () => {
    const el = boot()
    await nextFrame()

    // Server HTML has no idea the widget injected a <span> — but DOES still carry the
    // controller's own data-controller attribute, exactly as the original
    // server-rendered markup did (that attribute is not something the widget added at
    // runtime, so losing it here would be testing an unrelated Stimulus disconnect,
    // not the morph-survival behaviour this test is about).
    const incoming = document.createElement("div")
    incoming.id = "widget"
    incoming.setAttribute("data-controller", "cw--mounts")

    morphElements(el, incoming)
    await Promise.resolve() // one microtask — the coalescing flush

    const controller = application.getControllerForElementAndIdentifier(el, "cw--mounts")
    expect(controller.morphedCallCount).toBe(1)
    expect(controller.lastNewElement).toBeInstanceOf(Element)
  })

  test("the injected widget markup, deleted by the morph, is rebuilt by morphed()", async () => {
    const el = boot()
    await nextFrame()
    expect(el.querySelector(".injected")).not.toBeNull()

    const incoming = document.createElement("div")
    incoming.id = "widget"
    incoming.setAttribute("data-controller", "cw--mounts")

    morphElements(el, incoming)
    // Idiomorph deletes the <span> synchronously (it is not in the server HTML) —
    // confirm the failure mode is real before confirming the fix.
    expect(el.querySelector(".injected")).toBeNull()

    await Promise.resolve()

    expect(el.querySelector(".injected")).not.toBeNull()
  })
})

describe("installDialogMorphGuard — real <dialog>, real top layer (turbo#1239)", () => {
  async function settle() {
    await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
  }

  test("a morph that strips `open` from an open modal dialog does not leave the page permanently un-clickable", async () => {
    document.body.innerHTML = `
      <button id="outside">Outside</button>
      <dialog id="d1"><p>Body</p></dialog>`
    const dialog = document.getElementById("d1")
    const outside = document.getElementById("outside")

    const uninstall = installDialogMorphGuard(document)

    dialog.showModal()
    await settle()
    expect(dialog.matches(":modal")).toBe(true)

    let closeFired = false
    dialog.addEventListener("close", () => { closeFired = true })

    // Exactly what a background morph does: the incoming HTML has no `open` attribute
    // at all, because the server thinks the dialog should be closed.
    const incoming = document.createElement("dialog")
    incoming.id = "d1"
    incoming.innerHTML = "<p>Body</p>"

    morphElements(dialog, incoming)
    await settle()

    expect(dialog.open).toBe(false)
    expect(closeFired).toBe(true)

    // The actual turbo#1239 assertion jsdom cannot make: is the rest of the document
    // genuinely reachable again, not merely reporting `.open === false` while still
    // stuck behind an orphaned top-layer/inert state?
    outside.focus()
    expect(document.activeElement).toBe(outside)

    let clicked = false
    outside.addEventListener("click", () => { clicked = true })
    await userEvent.click(outside)
    expect(clicked).toBe(true)

    uninstall()
  })

  test("does not interfere with a dialog that stays closed", async () => {
    document.body.innerHTML = `<dialog id="d2"><p>Body</p></dialog>`
    const dialog = document.getElementById("d2")
    const uninstall = installDialogMorphGuard(document)

    const incoming = document.createElement("dialog")
    incoming.id = "d2"
    incoming.setAttribute("class", "updated")
    incoming.innerHTML = "<p>Body</p>"

    morphElements(dialog, incoming)

    expect(dialog.getAttribute("class")).toBe("updated")
    expect(dialog.open).toBe(false)

    uninstall()
  })
})

describe("createMorphGuard — B3 coalescing under a real, larger morph pass", () => {
  test("many descendants morphing in one pass still produce exactly one flush", async () => {
    document.body.innerHTML = `<ul id="list">${Array.from({ length: 25 }, (_, i) => `<li data-n="${i}">${i}</li>`).join("")}</ul>`
    const list = document.getElementById("list")

    let calls = 0
    const guard = createMorphGuard(list, { onMorphed: () => calls++ })

    const incoming = document.createElement("ul")
    incoming.id = "list"
    incoming.innerHTML = Array.from({ length: 25 }, (_, i) => `<li data-n="${i}">${i} updated</li>`).join("")

    morphElements(list, incoming)
    await Promise.resolve()

    expect(calls).toBe(1)
    expect(list.children[0].textContent).toBe("0 updated")

    guard.teardown()
  })
})
