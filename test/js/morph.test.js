import { describe, expect, test } from "vitest"
import { createMorphGuard, installDialogMorphGuard, usePreserve } from "../../app/assets/javascripts/crosswire/morph.js"

// jsdom tier (docs/COMPONENT_CONTRACT.md "Test strategy"). idiomorph itself is plain
// DOM manipulation and jsdom CAN run it mechanically, but this file does not drive a
// real morph at all — it dispatches the synthetic CustomEvents Turbo would dispatch
// DURING one, matching the exact shape `dispatch()` produces in
// @hotwired/turbo/dist/turbo.es2017-esm.js (`bubbles: true, composed: true,
// cancelable` as passed, `detail`). That is honest here specifically because the
// events themselves — their names and detail shapes — ARE crosswire's public
// contract with Turbo; nothing here needs real layout, a real top layer, or a real
// morph pass to verify that contract. The REQUIRED, authoritative morph tests — real
// @hotwired/turbo driving a real morph end to end — live in morph.browser.test.js.

function morphAttribute(target, { attributeName, mutationType = "update" }) {
  const event = new CustomEvent("turbo:before-morph-attribute", {
    bubbles: true,
    composed: true,
    cancelable: true,
    detail: { attributeName, mutationType }
  })
  target.dispatchEvent(event)
  return event
}

function morphElementEvent(target, options = {}) {
  // NOT a default parameter (`{ newElement = ... } = {}`) — a default parameter fires
  // whenever the destructured value is `undefined`, which is exactly the sentinel B4
  // needs to express ("this element is about to be removed"). `"newElement" in options`
  // is the only way to tell "the caller explicitly passed undefined" apart from "the
  // caller didn't pass this key at all".
  const newElement = "newElement" in options ? options.newElement : document.createElement("div")
  const event = new CustomEvent("turbo:before-morph-element", {
    bubbles: true,
    composed: true,
    cancelable: true,
    detail: { currentElement: target, newElement }
  })
  target.dispatchEvent(event)
  return event
}

function morphedEvent(target, { newElement = document.createElement("div") } = {}) {
  const event = new CustomEvent("turbo:morph-element", {
    bubbles: true,
    composed: true,
    detail: { currentElement: target, newElement }
  })
  target.dispatchEvent(event)
  return event
}

function flushMicrotasks() {
  return new Promise((resolve) => queueMicrotask(resolve))
}

describe("createMorphGuard — B2 divergence check", () => {
  test("cancels an attribute morph once the live value has diverged from the recorded baseline", () => {
    const el = document.createElement("div")
    el.setAttribute("data-cw--x-open-value", "true")
    document.body.append(el)

    const guard = createMorphGuard(el, { attributeNames: () => ["data-cw--x-open-value"] })

    // The controller writes a new value itself, AFTER the guard's baseline was
    // recorded at creation — this is what "the controller actually changed it" means.
    el.setAttribute("data-cw--x-open-value", "false")

    const event = morphAttribute(el, { attributeName: "data-cw--x-open-value", mutationType: "update" })
    expect(event.defaultPrevented).toBe(true)

    guard.teardown()
    el.remove()
  })

  test("lets an attribute morph through when the controller never touched it since the last sync", () => {
    const el = document.createElement("div")
    el.setAttribute("data-cw--x-open-value", "true")
    document.body.append(el)

    const guard = createMorphGuard(el, { attributeNames: () => ["data-cw--x-open-value"] })

    // Nothing wrote a new value after the guard synced — the server should win.
    const event = morphAttribute(el, { attributeName: "data-cw--x-open-value", mutationType: "update" })
    expect(event.defaultPrevented).toBe(false)

    guard.teardown()
    el.remove()
  })

  test("does not act on attribute names outside the watched list", () => {
    const el = document.createElement("div")
    el.setAttribute("class", "is-open")
    document.body.append(el)

    const guard = createMorphGuard(el, { attributeNames: () => ["data-cw--x-open-value"] })
    el.setAttribute("class", "is-closed")

    const event = morphAttribute(el, { attributeName: "class", mutationType: "update" })
    expect(event.defaultPrevented).toBe(false)

    guard.teardown()
    el.remove()
  })

  test("baselines refresh after a morph pass, so a later divergence check compares against the post-morph value", async () => {
    const el = document.createElement("div")
    el.setAttribute("data-cw--x-open-value", "true")
    document.body.append(el)

    const guard = createMorphGuard(el, { attributeNames: () => ["data-cw--x-open-value"] })

    // First pass: nothing diverged, the server's morph is allowed through and the DOM
    // now reads "false" (simulating what idiomorph itself would have done).
    morphAttribute(el, { attributeName: "data-cw--x-open-value", mutationType: "update" })
    el.setAttribute("data-cw--x-open-value", "false")
    morphedEvent(el)
    await flushMicrotasks()

    // Second pass: the controller writes true again — this now diverges from the
    // freshly-synced baseline ("false"), so it must be protected.
    el.setAttribute("data-cw--x-open-value", "true")
    const event = morphAttribute(el, { attributeName: "data-cw--x-open-value", mutationType: "update" })
    expect(event.defaultPrevented).toBe(true)

    guard.teardown()
    el.remove()
  })
})

describe("createMorphGuard — event.target scoping (B1)", () => {
  test("ignores a turbo:before-morph-attribute that bubbled up from a descendant", () => {
    const el = document.createElement("div")
    el.setAttribute("data-cw--x-open-value", "true")
    const child = document.createElement("span")
    el.append(child)
    document.body.append(el)

    const guard = createMorphGuard(el, { attributeNames: () => ["data-cw--x-open-value"] })
    el.setAttribute("data-cw--x-open-value", "false") // would diverge if checked

    const event = morphAttribute(child, { attributeName: "data-cw--x-open-value", mutationType: "update" })
    expect(event.defaultPrevented).toBe(false)

    guard.teardown()
    el.remove()
  })

  test("ignores a turbo:before-morph-element that bubbled up from a descendant", () => {
    const el = document.createElement("div")
    const child = document.createElement("span")
    el.append(child)
    document.body.append(el)

    const guard = createMorphGuard(el, { preserveElement: () => true })

    const event = morphElementEvent(child)
    expect(event.defaultPrevented).toBe(false)

    guard.teardown()
    el.remove()
  })
})

describe("createMorphGuard — B6 preserveElement", () => {
  test("cancels turbo:before-morph-element for the element itself when preserveElement() is true", () => {
    const el = document.createElement("div")
    document.body.append(el)

    const guard = createMorphGuard(el, { preserveElement: () => true })
    const event = morphElementEvent(el)

    expect(event.defaultPrevented).toBe(true)

    guard.teardown()
    el.remove()
  })

  test("does not cancel turbo:before-morph-element when preserveElement() is false", () => {
    const el = document.createElement("div")
    document.body.append(el)

    const guard = createMorphGuard(el, { preserveElement: () => false })
    const event = morphElementEvent(el)

    expect(event.defaultPrevented).toBe(false)

    guard.teardown()
    el.remove()
  })
})

describe("createMorphGuard — B4 removal", () => {
  test("calls onRemoved when detail.newElement is undefined for this exact element", () => {
    const el = document.createElement("div")
    document.body.append(el)

    const removed = []
    const guard = createMorphGuard(el, { onRemoved: (detail) => removed.push(detail) })

    morphElementEvent(el, { newElement: undefined })

    expect(removed).toHaveLength(1)
    expect(removed[0].newElement).toBeUndefined()

    guard.teardown()
    el.remove()
  })

  test("does not call onRemoved for an ordinary morph (newElement present)", () => {
    const el = document.createElement("div")
    document.body.append(el)

    const removed = []
    const guard = createMorphGuard(el, { onRemoved: (detail) => removed.push(detail) })

    morphElementEvent(el, { newElement: document.createElement("div") })

    expect(removed).toHaveLength(0)

    guard.teardown()
    el.remove()
  })
})

describe("createMorphGuard — B3 coalescing", () => {
  test("collapses several turbo:morph-element events from one synchronous pass into a single onMorphed call", async () => {
    const el = document.createElement("div")
    document.body.append(el)

    const calls = []
    const guard = createMorphGuard(el, { onMorphed: (detail) => calls.push(detail) })

    // Simulates idiomorph's own walk: several descendants morph synchronously within
    // the same pass, each bubbling turbo:morph-element up to this element.
    const a = document.createElement("span")
    const b = document.createElement("span")
    el.append(a, b)
    morphedEvent(a)
    morphedEvent(b)
    morphedEvent(el)

    expect(calls).toHaveLength(0) // not yet — coalescing waits for a microtask

    await flushMicrotasks()

    expect(calls).toHaveLength(1)

    guard.teardown()
    el.remove()
  })

  test("a second, later morph pass produces its own separate onMorphed call", async () => {
    const el = document.createElement("div")
    document.body.append(el)

    const calls = []
    const guard = createMorphGuard(el, { onMorphed: (detail) => calls.push(detail) })

    morphedEvent(el)
    await flushMicrotasks()
    morphedEvent(el)
    await flushMicrotasks()

    expect(calls).toHaveLength(2)

    guard.teardown()
    el.remove()
  })
})

describe("createMorphGuard — teardown and zero-cost idle behaviour", () => {
  test("teardown removes every listener — no divergence cancel, no onMorphed, no onRemoved after it", async () => {
    const el = document.createElement("div")
    el.setAttribute("data-cw--x-open-value", "true")
    document.body.append(el)

    let morphedCalls = 0
    let removedCalls = 0
    const guard = createMorphGuard(el, {
      attributeNames: () => ["data-cw--x-open-value"],
      onMorphed: () => morphedCalls++,
      onRemoved: () => removedCalls++
    })

    guard.teardown()

    el.setAttribute("data-cw--x-open-value", "false") // would have diverged
    const attrEvent = morphAttribute(el, { attributeName: "data-cw--x-open-value", mutationType: "update" })
    expect(attrEvent.defaultPrevented).toBe(false)

    morphElementEvent(el, { newElement: undefined })
    morphedEvent(el)
    await flushMicrotasks()

    expect(morphedCalls).toBe(0)
    expect(removedCalls).toBe(0)

    el.remove()
  })

  test("does nothing and throws nothing when no morph event ever fires", () => {
    const el = document.createElement("div")
    document.body.append(el)

    expect(() => {
      const guard = createMorphGuard(el, { attributeNames: () => ["data-cw--x-open-value"] })
      guard.teardown()
    }).not.toThrow()

    el.remove()
  })
})

describe("usePreserve", () => {
  class FakeController {
    static preservedValues = ["open"]
    static preservedAttributes = ["aria-expanded"]
    static reconnectOnMorph = true
    static preserveElement = false

    constructor(element, identifier = "cw--fake") {
      this.element = element
      this.identifier = identifier
      this.disconnectCalls = 0
      this.morphedCalls = []
      this.removedCalls = []
    }

    disconnect() {
      this.disconnectCalls++
    }

    morphed(detail) {
      this.morphedCalls.push(detail)
    }

    removedByMorph(detail) {
      this.removedCalls.push(detail)
    }
  }

  test("derives the preserved-value attribute name from the LIVE controller identifier, not a compile-time constant", () => {
    const el = document.createElement("div")
    el.setAttribute("data-cw--renamed-open-value", "true")
    document.body.append(el)

    const controller = new FakeController(el, "cw--renamed")
    usePreserve(controller)

    el.setAttribute("data-cw--renamed-open-value", "false") // controller "wrote" this
    const event = morphAttribute(el, { attributeName: "data-cw--renamed-open-value", mutationType: "update" })
    expect(event.defaultPrevented).toBe(true)

    controller.disconnect()
    el.remove()
  })

  test("also protects static preservedAttributes, the raw-attribute surface", () => {
    const el = document.createElement("div")
    el.setAttribute("aria-expanded", "true")
    document.body.append(el)

    const controller = new FakeController(el)
    usePreserve(controller)

    el.setAttribute("aria-expanded", "false")
    const event = morphAttribute(el, { attributeName: "aria-expanded", mutationType: "update" })
    expect(event.defaultPrevented).toBe(true)

    controller.disconnect()
    el.remove()
  })

  test("is idempotent — calling it twice without an intervening disconnect() returns the same handle", () => {
    const el = document.createElement("div")
    document.body.append(el)
    const controller = new FakeController(el)

    const first = usePreserve(controller)
    const second = usePreserve(controller)

    expect(second).toBe(first)

    controller.disconnect()
    el.remove()
  })

  test("wraps disconnect() stimulus-use style: the original disconnect still runs, plus teardown", () => {
    const el = document.createElement("div")
    el.setAttribute("data-cw--fake-open-value", "true")
    document.body.append(el)
    const controller = new FakeController(el)

    usePreserve(controller)
    controller.disconnect()

    expect(controller.disconnectCalls).toBe(1)

    // Guard should be torn down — a divergence that would have been cancelled before
    // is now let through.
    el.setAttribute("data-cw--fake-open-value", "false")
    const event = morphAttribute(el, { attributeName: "data-cw--fake-open-value", mutationType: "update" })
    expect(event.defaultPrevented).toBe(false)

    el.remove()
  })

  test("B3: calls morphed() at most once per morph pass, only when reconnectOnMorph is true", async () => {
    const el = document.createElement("div")
    document.body.append(el)
    const controller = new FakeController(el)
    usePreserve(controller)

    morphedEvent(el)
    morphedEvent(el)
    morphedEvent(el)
    await flushMicrotasks()

    expect(controller.morphedCalls).toHaveLength(1)

    controller.disconnect()
    el.remove()
  })

  test("does not call morphed() when reconnectOnMorph is not true", async () => {
    class NoReconnect extends FakeController {
      static reconnectOnMorph = false
    }
    const el = document.createElement("div")
    document.body.append(el)
    const controller = new NoReconnect(el)
    usePreserve(controller)

    morphedEvent(el)
    await flushMicrotasks()

    expect(controller.morphedCalls).toHaveLength(0)

    controller.disconnect()
    el.remove()
  })

  test("B4: calls removedByMorph() when this element's own removal is signalled", () => {
    const el = document.createElement("div")
    document.body.append(el)
    const controller = new FakeController(el)
    usePreserve(controller)

    morphElementEvent(el, { newElement: undefined })

    expect(controller.removedCalls).toHaveLength(1)

    controller.disconnect()
    el.remove()
  })

  test("B6: static preserveElement = true cancels the whole subtree", () => {
    class Permanent extends FakeController {
      static preserveElement = true
    }
    const el = document.createElement("div")
    document.body.append(el)
    const controller = new Permanent(el)
    usePreserve(controller)

    const event = morphElementEvent(el)
    expect(event.defaultPrevented).toBe(true)

    controller.disconnect()
    el.remove()
  })

  test("is zero-cost on a controller with none of the optional statics declared", () => {
    class Bare {
      constructor(element) {
        this.element = element
        this.identifier = "cw--bare"
      }
    }
    const el = document.createElement("div")
    document.body.append(el)
    const controller = new Bare(el)

    expect(() => usePreserve(controller)).not.toThrow()
    expect(() => morphAttribute(el, { attributeName: "class", mutationType: "update" })).not.toThrow()
    expect(() => morphElementEvent(el)).not.toThrow()

    controller.disconnect()
    el.remove()
  })
})

describe("installDialogMorphGuard", () => {
  function polyfillClose(dialog) {
    dialog.close = function close() {
      this.removeAttribute("open")
      this.dispatchEvent(new Event("close"))
    }
    return dialog
  }

  test("cancels removal of <dialog>'s open attribute and calls .close() itself (turbo#1239)", () => {
    const dialog = polyfillClose(document.createElement("dialog"))
    dialog.setAttribute("open", "")
    document.body.append(dialog)

    const uninstall = installDialogMorphGuard(document)
    const event = morphAttribute(dialog, { attributeName: "open", mutationType: "remove" })

    expect(event.defaultPrevented).toBe(true)
    expect(dialog.hasAttribute("open")).toBe(false) // .close() ran

    uninstall()
    dialog.remove()
  })

  test("ignores non-dialog elements", () => {
    const el = document.createElement("div")
    el.setAttribute("open", "")
    document.body.append(el)

    const uninstall = installDialogMorphGuard(document)
    const event = morphAttribute(el, { attributeName: "open", mutationType: "remove" })

    expect(event.defaultPrevented).toBe(false)

    uninstall()
    el.remove()
  })

  test("ignores attribute changes that are not removing `open`", () => {
    const dialog = polyfillClose(document.createElement("dialog"))
    dialog.setAttribute("open", "")
    document.body.append(dialog)

    const uninstall = installDialogMorphGuard(document)

    const updateEvent = morphAttribute(dialog, { attributeName: "open", mutationType: "update" })
    expect(updateEvent.defaultPrevented).toBe(false)

    const otherAttrEvent = morphAttribute(dialog, { attributeName: "class", mutationType: "remove" })
    expect(otherAttrEvent.defaultPrevented).toBe(false)

    uninstall()
    dialog.remove()
  })

  test("is idempotent: installing twice on the same root returns the same uninstall function", () => {
    const first = installDialogMorphGuard(document)
    const second = installDialogMorphGuard(document)

    expect(second).toBe(first)

    first()
  })

  test("uninstall removes the listener", () => {
    const dialog = polyfillClose(document.createElement("dialog"))
    dialog.setAttribute("open", "")
    document.body.append(dialog)

    const uninstall = installDialogMorphGuard(document)
    uninstall()

    const event = morphAttribute(dialog, { attributeName: "open", mutationType: "remove" })
    expect(event.defaultPrevented).toBe(false)

    dialog.remove()
  })
})
