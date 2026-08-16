import { afterEach, beforeEach, describe, expect, test, vi } from "vitest"
import TransitionController from "../../app/assets/javascripts/crosswire/controllers/transition_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--transition": TransitionController }

function markup({ leaveClass = null, leaveFromClass = null, leaveToClass = null,
  enterClass = null, enterFromClass = null, enterToClass = null } = {}) {
  const classAttrs = [
    leaveClass ? `data-cw--transition-leave-class="${leaveClass}"` : "",
    leaveFromClass ? `data-cw--transition-leave-from-class="${leaveFromClass}"` : "",
    leaveToClass ? `data-cw--transition-leave-to-class="${leaveToClass}"` : "",
    enterClass ? `data-cw--transition-enter-class="${enterClass}"` : "",
    enterFromClass ? `data-cw--transition-enter-from-class="${enterFromClass}"` : "",
    enterToClass ? `data-cw--transition-enter-to-class="${enterToClass}"` : ""
  ].filter(Boolean).join(" ")

  return `
    <div data-controller="cw--transition"
         data-action="dismissing->cw--transition#leave"
         ${classAttrs}>
      <button class="leave-btn" data-action="click->cw--transition#leave">Leave</button>
      <button class="enter-btn" data-action="click->cw--transition#enter">Enter</button>
    </div>`
}

// Polls a real clock rather than stepping fake timers — the controller's own timeouts
// (and Stimulus's action wiring) run on real timers, so this is the least brittle way
// to wait for an async transition to settle.
async function waitFor(predicate, { timeout = 2000, interval = 5 } = {}) {
  const start = Date.now()
  while (!predicate()) {
    if (Date.now() - start > timeout) throw new Error("waitFor: condition never became true")
    await new Promise((resolve) => setTimeout(resolve, interval))
  }
}

// jsdom never runs a real CSS transition engine, so `transitionend` never fires here —
// which is exactly the "must not hang" scenario this controller has to survive. Every
// test in this file exercises the fallback-timeout path; real-browser behaviour (an
// actual `transitionend` firing before the timeout) is architecturally the same code
// path, just resolved earlier.
describe("cw--transition", () => {
  beforeEach(() => {
    vi.stubGlobal("matchMedia", undefined)
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  test("leave adds then removes the leave classes and dispatches left", async () => {
    const el = await mount(markup({
      leaveClass: "transition", leaveFromClass: "opacity-100", leaveToClass: "opacity-0"
    }), CONTROLLERS)
    el.style.transitionDuration = "0.01s"

    const left = captureEvents("cw--transition:left")
    el.querySelector(".leave-btn").click()

    await waitFor(() => left.length === 1)
    expect(el.classList.contains("transition")).toBe(false)
    expect(el.classList.contains("opacity-100")).toBe(false)
    expect(el.classList.contains("opacity-0")).toBe(false)
  })

  test("settles into the leaveTo class before the transition completes", async () => {
    const el = await mount(markup({
      leaveClass: "transition", leaveFromClass: "opacity-100", leaveToClass: "opacity-0"
    }), CONTROLLERS)
    el.style.transitionDuration = "0.15s"

    const left = captureEvents("cw--transition:left")
    el.querySelector(".leave-btn").click()

    await waitFor(() => el.classList.contains("opacity-0"))
    expect(el.classList.contains("opacity-100")).toBe(false)
    expect(left).toHaveLength(0) // still mid-transition, not yet complete

    await waitFor(() => left.length === 1)
    expect(el.classList.contains("opacity-0")).toBe(false) // cleaned up on completion
  })

  test("dispatches leaving before the animation and left after", async () => {
    const el = await mount(markup({ leaveClass: "fade" }), CONTROLLERS)
    el.style.transitionDuration = "0.01s"

    const leaving = captureEvents("cw--transition:leaving")
    const left = captureEvents("cw--transition:left")

    el.querySelector(".leave-btn").click()
    expect(leaving).toHaveLength(1) // dispatched synchronously before the class dance

    await waitFor(() => left.length === 1)
  })

  test("calls detail.complete after the leave transition finishes, and prevents the default", async () => {
    const el = await mount(markup({ leaveClass: "fade" }), CONTROLLERS)
    el.style.transitionDuration = "0.01s"

    let completed = false
    const event = new CustomEvent("dismissing", {
      detail: { complete: () => { completed = true } },
      cancelable: true,
      bubbles: true
    })

    el.dispatchEvent(event)
    expect(event.defaultPrevented).toBe(true)

    await waitFor(() => completed)
  })

  test("falls back to a short timeout when no transition is defined, and does not hang", async () => {
    const el = await mount(markup({ leaveClass: "fade" }), CONTROLLERS)
    // No transition-duration set — computed duration is 0, so the fallback is just the
    // margin. This is the "no transition defined" case from the brief.
    const left = captureEvents("cw--transition:left")

    el.querySelector(".leave-btn").click()

    await waitFor(() => left.length === 1, { timeout: 500 })
  })

  // R3 — Stimulus throws on this.fooClass when the attribute is absent.
  test("does not throw and still completes when no classes are given at all", async () => {
    const el = await mount(markup(), CONTROLLERS)
    const left = captureEvents("cw--transition:left")

    expect(() => el.querySelector(".leave-btn").click()).not.toThrow()

    await waitFor(() => left.length === 1, { timeout: 500 })
  })

  test("enter runs the enter class sequence and dispatches entered", async () => {
    const el = await mount(markup({
      enterClass: "transition", enterFromClass: "opacity-0", enterToClass: "opacity-100"
    }), CONTROLLERS)
    el.style.transitionDuration = "0.01s"

    const entered = captureEvents("cw--transition:entered")
    el.querySelector(".enter-btn").click()

    await waitFor(() => entered.length === 1)
    expect(el.classList.contains("transition")).toBe(false)
    expect(el.classList.contains("opacity-100")).toBe(false)
  })

  test("honours prefers-reduced-motion by skipping the animation entirely", async () => {
    vi.stubGlobal("matchMedia", () => ({ matches: true }))

    const el = await mount(markup({
      leaveClass: "fade", leaveFromClass: "opacity-100", leaveToClass: "opacity-0"
    }), CONTROLLERS)
    el.style.transitionDuration = "10s" // would time out the test if the fallback ran

    const leaving = captureEvents("cw--transition:leaving")
    const left = captureEvents("cw--transition:left")

    el.querySelector(".leave-btn").click()

    await waitFor(() => left.length === 1, { timeout: 200 })
    expect(leaving).toHaveLength(1)
    expect(el.classList.contains("opacity-0")).toBe(false) // the class dance never ran
  })

  test("a preventDefault()'d leaving event also skips the animation", async () => {
    const el = await mount(markup({ leaveClass: "fade", leaveToClass: "opacity-0" }), CONTROLLERS)
    el.style.transitionDuration = "10s"
    el.addEventListener("cw--transition:leaving", (event) => event.preventDefault())

    const left = captureEvents("cw--transition:left")
    el.querySelector(".leave-btn").click()

    await waitFor(() => left.length === 1, { timeout: 200 })
    expect(el.classList.contains("opacity-0")).toBe(false)
  })

  test("composes with cw--dismiss's cancelable dismissing event via a plain data-action", async () => {
    // This is the primary use case documented on the presenter's #leave_on: the same
    // element carries both controllers, and cw--transition#leave is wired as the
    // handler for cw--dismiss:dismissing.
    const el = await mount(markup({ leaveClass: "fade", leaveToClass: "opacity-0" }), CONTROLLERS)
    el.style.transitionDuration = "0.01s"

    let removed = false
    const dismissing = new CustomEvent("dismissing", {
      detail: { complete: () => { removed = true } },
      cancelable: true,
      bubbles: true
    })
    el.dispatchEvent(dismissing)

    expect(dismissing.defaultPrevented).toBe(true) // leave() held the removal open
    expect(removed).toBe(false) // not yet — the transition hasn't finished

    await waitFor(() => removed)
  })

  test("disconnecting mid-transition does not throw or hang (R7 teardown)", async () => {
    const el = await mount(markup({ leaveClass: "fade", leaveToClass: "opacity-0" }), CONTROLLERS)
    el.style.transitionDuration = "0.2s"

    el.querySelector(".leave-btn").click()
    await nextFrame()
    el.remove()

    // No assertion beyond "this resolves cleanly" — that is what exhaustive teardown
    // guarantees: no dangling timer or listener from the in-flight transition.
    await new Promise((resolve) => setTimeout(resolve, 300))
  })
})
