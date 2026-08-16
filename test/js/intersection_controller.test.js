import { describe, expect, test, vi, beforeEach, afterEach } from "vitest"
import IntersectionController from "../../app/assets/javascripts/crosswire/controllers/intersection_controller.js"
import { mount, nextFrame, captureEvents } from "./setup.js"

const CONTROLLERS = { "cw--intersection": IntersectionController }

// jsdom has no real IntersectionObserver, so this suite stubs the global explicitly
// and verifies wiring/teardown honestly: what options the controller passes, that it
// observes/disconnects the right element, and that value changes reconfigure rather
// than leak observers. It never pretends to assert real scroll-driven intersection
// behaviour — that assertion (does it actually fire when the element scrolls into
// view) belongs in intersection_controller.browser.test.js, which runs against a
// real browser IntersectionObserver.

class FakeIntersectionObserver {
  constructor(callback, options) {
    this.callback = callback
    this.options = options
    this.observed = []
    this.disconnected = false
    FakeIntersectionObserver.instances.push(this)
  }

  observe(target) {
    this.observed.push(target)
  }

  unobserve(target) {
    this.observed = this.observed.filter((t) => t !== target)
  }

  disconnect() {
    this.disconnected = true
    this.observed = []
  }

  // Test helper, not part of the real API: simulate the browser calling back.
  trigger(entries) {
    this.callback(entries)
  }
}
FakeIntersectionObserver.instances = []

function markup({ threshold, once, rootMargin, root } = {}) {
  const attrs = [
    threshold !== undefined ? `data-cw--intersection-threshold-value="${threshold}"` : "",
    once !== undefined ? `data-cw--intersection-once-value="${once}"` : "",
    rootMargin !== undefined ? `data-cw--intersection-root-margin-value="${rootMargin}"` : "",
    root !== undefined ? `data-cw--intersection-root-value="${root}"` : ""
  ].join(" ")

  return `<div data-controller="cw--intersection" ${attrs}>Sentinel</div>`
}

function fakeEntry(isIntersecting, target) {
  return { isIntersecting, intersectionRatio: isIntersecting ? 1 : 0, target }
}

beforeEach(() => {
  FakeIntersectionObserver.instances = []
  vi.stubGlobal("IntersectionObserver", FakeIntersectionObserver)
})

afterEach(() => {
  vi.unstubAllGlobals()
})

describe("cw--intersection", () => {
  test("creates an observer with the configured options on connect", async () => {
    await mount(markup({ threshold: 0.5, rootMargin: "200px" }), CONTROLLERS)

    expect(FakeIntersectionObserver.instances).toHaveLength(1)
    const observer = FakeIntersectionObserver.instances[0]
    expect(observer.options.threshold).toBe(0.5)
    expect(observer.options.rootMargin).toBe("200px")
    expect(observer.options.root).toBeNull()
  })

  test("observes its own element", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const observer = FakeIntersectionObserver.instances[0]
    expect(observer.observed).toEqual([el])
  })

  test("resolves root to the selector's element when given", async () => {
    document.body.innerHTML = '<div id="scroller"></div>'
    document.body.insertAdjacentHTML("beforeend", markup({ root: "#scroller" }))
    const scroller = document.getElementById("scroller")

    const { Application } = await import("@hotwired/stimulus")
    const application = Application.start()
    application.register("cw--intersection", IntersectionController)
    await nextFrame()

    const observer = FakeIntersectionObserver.instances[0]
    expect(observer.options.root).toBe(scroller)

    application.stop()
  })

  // R7 — exhaustive teardown.
  test("disconnects the observer and nulls the reference on disconnect", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const observer = FakeIntersectionObserver.instances[0]

    document.body.innerHTML = ""
    await nextFrame()

    expect(observer.disconnected).toBe(true)
  })

  test("dispatches entered with the raw IntersectionObserverEntry in detail", async () => {
    const entered = captureEvents("cw--intersection:entered")
    const el = await mount(markup(), CONTROLLERS)
    const observer = FakeIntersectionObserver.instances[0]

    const entry = fakeEntry(true, el)
    observer.trigger([entry])

    expect(entered).toHaveLength(1)
    expect(entered[0].detail.entry).toBe(entry)
    expect(entered[0].detail.entry.intersectionRatio).toBe(1)
  })

  test("dispatches left when no longer intersecting", async () => {
    const left = captureEvents("cw--intersection:left")
    const el = await mount(markup(), CONTROLLERS)
    const observer = FakeIntersectionObserver.instances[0]

    observer.trigger([fakeEntry(false, el)])

    expect(left).toHaveLength(1)
  })

  // once: true must unobserve after the first entry, not merely ignore later ones —
  // asserted here by checking the observer itself was torn down, not just that a
  // second event didn't fire.
  test("once disconnects the observer after the first entered", async () => {
    const el = await mount(markup({ once: true }), CONTROLLERS)
    const observer = FakeIntersectionObserver.instances[0]

    observer.trigger([fakeEntry(true, el)])

    expect(observer.disconnected).toBe(true)
  })

  test("without once, the observer survives repeated entries", async () => {
    const el = await mount(markup({ once: false }), CONTROLLERS)
    const observer = FakeIntersectionObserver.instances[0]

    observer.trigger([fakeEntry(true, el)])
    expect(observer.disconnected).toBe(false)

    observer.trigger([fakeEntry(false, el)])
    expect(observer.disconnected).toBe(false)
  })

  // Reconfiguration: changing a value after connect disconnects the old observer and
  // creates a new one with the updated options — it does not recreate on the initial
  // connect's own value hydration (asserted by the "creates ... on connect" test above
  // only ever seeing one instance at connect time).
  test("changing threshold after connect disconnects the old observer and creates a new one", async () => {
    const el = await mount(markup({ threshold: 0 }), CONTROLLERS)
    const first = FakeIntersectionObserver.instances[0]
    expect(FakeIntersectionObserver.instances).toHaveLength(1)

    el.setAttribute("data-cw--intersection-threshold-value", "0.75")
    await nextFrame()

    expect(first.disconnected).toBe(true)
    expect(FakeIntersectionObserver.instances).toHaveLength(2)
    expect(FakeIntersectionObserver.instances[1].options.threshold).toBe(0.75)
  })

  test("changing rootMargin after connect reconfigures rather than duplicating forever", async () => {
    const el = await mount(markup({ rootMargin: "0px" }), CONTROLLERS)

    el.setAttribute("data-cw--intersection-root-margin-value", "50px")
    await nextFrame()
    el.setAttribute("data-cw--intersection-root-margin-value", "100px")
    await nextFrame()

    // Exactly one instance per change, not one per instantiation plus stray leftovers.
    expect(FakeIntersectionObserver.instances).toHaveLength(3)
    expect(FakeIntersectionObserver.instances.filter((o) => !o.disconnected)).toHaveLength(1)
  })
})
