import { describe, expect, test } from "vitest"
import TimeoutController from "../../app/assets/javascripts/crosswire/controllers/timeout_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--timeout": TimeoutController }

// Real (short) delays rather than vi.useFakeTimers(): the shared mount()/nextFrame()
// helpers in setup.js rely on a real setTimeout(0) to let Stimulus's MutationObserver
// flush, and faking global timers would fake that too. Every delay below is short
// (tens of ms) with a generous wait margin, the same tradeoff persist_controller.test.js
// already makes for its own debounce tests.

function markup({ delay = 30, startOnConnect = null, action = null } = {}) {
  return `
    <div data-controller="cw--timeout"
         data-cw--timeout-delay-value="${delay}"
         ${startOnConnect !== null ? `data-cw--timeout-start-on-connect-value="${startOnConnect}"` : ""}
         ${action ? `data-action="${action}"` : ""}></div>`
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

function setHidden(hidden) {
  Object.defineProperty(document, "visibilityState", { value: hidden ? "hidden" : "visible", configurable: true })
  document.dispatchEvent(new Event("visibilitychange"))
}

describe("cw--timeout", () => {
  // --- start on connect ---------------------------------------------------------------

  test("dispatches elapsed after the configured delay by default", async () => {
    const elapsed = captureEvents("cw--timeout:elapsed")
    await mount(markup({ delay: 20 }), CONTROLLERS)

    await wait(10)
    expect(elapsed).toHaveLength(0)

    await wait(40)
    expect(elapsed).toHaveLength(1)
    expect(elapsed[0].detail.delay).toBe(20)
  })

  test("does not start automatically when startOnConnect is false", async () => {
    const elapsed = captureEvents("cw--timeout:elapsed")
    await mount(markup({ delay: 20, startOnConnect: false }), CONTROLLERS)

    await wait(60)
    expect(elapsed).toHaveLength(0)
  })

  // --- start / cancel / restart actions -------------------------------------------------

  test("start() arms the timer when startOnConnect is false", async () => {
    const elapsed = captureEvents("cw--timeout:elapsed")
    const el = await mount(
      markup({ delay: 20, startOnConnect: false, action: "click->cw--timeout#start" }),
      CONTROLLERS
    )

    el.click()
    await wait(10)
    expect(elapsed).toHaveLength(0)

    await wait(40)
    expect(elapsed).toHaveLength(1)
  })

  test("calling start() twice does not re-arm an already-running timer", async () => {
    const elapsed = captureEvents("cw--timeout:elapsed")
    const el = await mount(
      markup({ delay: 30, startOnConnect: false, action: "click->cw--timeout#start" }),
      CONTROLLERS
    )

    el.click() // arms it, deadline ~30ms out
    await wait(20)
    el.click() // must be a no-op — a second full 30ms window would push elapsed later

    await wait(40) // 60ms total since the first click — comfortably past the original 30ms deadline
    expect(elapsed).toHaveLength(1)
  })

  test("cancel() stops a pending timer and dispatches cancelled, not elapsed", async () => {
    const elapsed = captureEvents("cw--timeout:elapsed")
    const cancelled = captureEvents("cw--timeout:cancelled")
    const el = await mount(markup({ delay: 20, action: "click->cw--timeout#cancel" }), CONTROLLERS)

    el.click()
    await wait(60)

    expect(cancelled).toHaveLength(1)
    expect(elapsed).toHaveLength(0)
  })

  test("cancel() on an already-elapsed or never-started timer is a no-op — no event", async () => {
    const cancelled = captureEvents("cw--timeout:cancelled")
    const el = await mount(
      markup({ delay: 20, startOnConnect: false, action: "click->cw--timeout#cancel" }),
      CONTROLLERS
    )

    el.click()
    await wait(10)

    expect(cancelled).toHaveLength(0)
  })

  test("restart() pushes the deadline back rather than firing immediately", async () => {
    const elapsed = captureEvents("cw--timeout:elapsed")
    const el = await mount(markup({ delay: 30, action: "mouseenter->cw--timeout#restart" }), CONTROLLERS)

    await wait(20)
    el.dispatchEvent(new MouseEvent("mouseenter", { bubbles: true }))

    // Original deadline (30ms from connect) has now passed, but restart() pushed it
    // out another 30ms from the mouseenter.
    await wait(20)
    expect(elapsed).toHaveLength(0)

    await wait(30)
    expect(elapsed).toHaveLength(1)
  })

  // --- pauses while the document is hidden ----------------------------------------------

  test("pauses the countdown while the document is hidden and resumes on visible", async () => {
    const elapsed = captureEvents("cw--timeout:elapsed")
    await mount(markup({ delay: 50 }), CONTROLLERS)

    await wait(10) // well under the 50ms deadline — comfortably more than ~40ms left
    setHidden(true)

    // Hidden for far longer than the remaining ~40ms would have needed — if the timer
    // weren't paused, this would already have fired.
    await wait(100)
    expect(elapsed).toHaveLength(0)

    setHidden(false)

    // Resumes with the genuinely-remaining ~40ms, not a fresh full 50ms delay.
    await wait(20)
    expect(elapsed).toHaveLength(0)
    await wait(50)
    expect(elapsed).toHaveLength(1)
  })

  test("starting while already hidden does not fire until the document becomes visible", async () => {
    setHidden(true)
    const elapsed = captureEvents("cw--timeout:elapsed")
    await mount(markup({ delay: 10 }), CONTROLLERS)

    await wait(60)
    expect(elapsed).toHaveLength(0)

    setHidden(false)
    await wait(40)
    expect(elapsed).toHaveLength(1)

    setHidden(false) // leave a clean, defined visibilityState for subsequent tests
  })

  // --- R7: exhaustive teardown -----------------------------------------------------------

  test("disconnect clears the pending timer without dispatching cancelled", async () => {
    const elapsed = captureEvents("cw--timeout:elapsed")
    const cancelled = captureEvents("cw--timeout:cancelled")
    await mount(markup({ delay: 20 }), CONTROLLERS)

    document.body.innerHTML = ""
    await nextFrame()

    await wait(40)
    expect(elapsed).toHaveLength(0)
    expect(cancelled).toHaveLength(0)
  })

  test("disconnect removes the visibilitychange listener", async () => {
    const elapsed = captureEvents("cw--timeout:elapsed")
    await mount(markup({ delay: 20 }), CONTROLLERS)

    document.body.innerHTML = ""
    await nextFrame()

    // Should not throw, and should have no further effect on a disconnected controller.
    setHidden(true)
    setHidden(false)
    await wait(30)

    expect(elapsed).toHaveLength(0)
  })
})
