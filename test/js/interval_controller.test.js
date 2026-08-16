import { afterEach, describe, expect, test, vi } from "vitest"
import IntervalController from "../../app/assets/javascripts/crosswire/controllers/interval_controller.js"
import { captureEvents, mount } from "./setup.js"

const CONTROLLERS = { "cw--interval": IntervalController }

// Fake timers throughout: an interval's back-off/pause behaviour is inherently about
// elapsed wall-clock time, and this suite exercises multi-second and visibility-gated
// spans that would make a real-wait suite slow and flaky. `mount()` awaits a real
// setTimeout(0) internally (see setup.js) to let Stimulus's MutationObserver flush, so
// timers must be faked BEFORE mounting and advanced with the async variant, which
// yields to the microtask queue the same way a real timer would.
//
// A local afterEach restores real timers before setup.js's own afterEach runs (Vitest
// runs afterEach hooks in reverse registration order, so a hook declared here — after
// setup.js's is already registered via setupFiles — runs first). Without this, setup.js's
// `await new Promise((resolve) => setTimeout(resolve, 0))` would hang forever against a
// faked clock nothing ever advances again.
afterEach(() => {
  vi.useRealTimers()
})

async function mountFake(html, controllers) {
  const pending = mount(html, controllers)
  await vi.advanceTimersByTimeAsync(0)
  return pending
}

function markup({ ms = 1000, immediate = null } = {}) {
  return `
    <div data-controller="cw--interval"
         data-cw--interval-ms-value="${ms}"
         ${immediate !== null ? `data-cw--interval-immediate-value="${immediate}"` : ""}></div>`
}

function setHidden(hidden) {
  Object.defineProperty(document, "visibilityState", { value: hidden ? "hidden" : "visible", configurable: true })
  document.dispatchEvent(new Event("visibilitychange"))
}

describe("cw--interval", () => {
  test("dispatches tick every ms while visible, with an incrementing count", async () => {
    vi.useFakeTimers()
    const ticks = captureEvents("cw--interval:tick")
    await mountFake(markup({ ms: 1000 }), CONTROLLERS)

    await vi.advanceTimersByTimeAsync(999)
    expect(ticks).toHaveLength(0)

    await vi.advanceTimersByTimeAsync(1)
    expect(ticks).toHaveLength(1)
    expect(ticks[0].detail.count).toBe(1)

    await vi.advanceTimersByTimeAsync(3000)
    expect(ticks).toHaveLength(4)
    expect(ticks[3].detail.count).toBe(4)
  })

  test("does not dispatch an immediate tick by default", async () => {
    vi.useFakeTimers()
    const ticks = captureEvents("cw--interval:tick")
    await mountFake(markup({ ms: 1000 }), CONTROLLERS)

    expect(ticks).toHaveLength(0)
  })

  test("immediate dispatches one extra tick on connect, before the first cadence tick", async () => {
    vi.useFakeTimers()
    const ticks = captureEvents("cw--interval:tick")
    await mountFake(markup({ ms: 1000, immediate: true }), CONTROLLERS)

    expect(ticks).toHaveLength(1)
    expect(ticks[0].detail.count).toBe(1)

    await vi.advanceTimersByTimeAsync(1000)
    expect(ticks).toHaveLength(2)
    expect(ticks[1].detail.count).toBe(2)
  })

  // --- pause on hidden / resume on visible ------------------------------------------

  test("stops ticking while the document is hidden", async () => {
    vi.useFakeTimers()
    const ticks = captureEvents("cw--interval:tick")
    await mountFake(markup({ ms: 1000 }), CONTROLLERS)

    setHidden(true)

    // Comfortably long enough that an unpaused interval would have ticked many times.
    await vi.advanceTimersByTimeAsync(10_000)
    expect(ticks).toHaveLength(0)
  })

  test("resumes with a fresh interval on visible, not a burst of catch-up ticks", async () => {
    vi.useFakeTimers()
    const ticks = captureEvents("cw--interval:tick")
    await mountFake(markup({ ms: 1000 }), CONTROLLERS)

    setHidden(true)
    await vi.advanceTimersByTimeAsync(10_000) // time a naive impl would try to "catch up"
    setHidden(false)

    // Exactly one tick per full ms window from the resume point — never a pile of
    // stale ticks delivered all at once.
    await vi.advanceTimersByTimeAsync(999)
    expect(ticks).toHaveLength(0)

    await vi.advanceTimersByTimeAsync(1)
    expect(ticks).toHaveLength(1)

    await vi.advanceTimersByTimeAsync(2000)
    expect(ticks).toHaveLength(3)
  })

  test("starting already hidden does not tick until the document becomes visible", async () => {
    setHidden(true)
    vi.useFakeTimers()
    const ticks = captureEvents("cw--interval:tick")
    await mountFake(markup({ ms: 500 }), CONTROLLERS)

    await vi.advanceTimersByTimeAsync(5000)
    expect(ticks).toHaveLength(0)

    setHidden(false)
    await vi.advanceTimersByTimeAsync(500)
    expect(ticks).toHaveLength(1)

    setHidden(false) // leave a clean, defined visibilityState for subsequent tests
  })

  test("redundant visibilitychange events while already visible do not start a second interval", async () => {
    vi.useFakeTimers()
    const ticks = captureEvents("cw--interval:tick")
    await mountFake(markup({ ms: 1000 }), CONTROLLERS)

    setHidden(false) // already visible — must be a no-op, not a second interval

    await vi.advanceTimersByTimeAsync(1000)
    expect(ticks).toHaveLength(1) // would be 2 if a duplicate interval had started
  })

  // --- R7: exhaustive teardown -------------------------------------------------------

  test("disconnect clears the pending interval", async () => {
    vi.useFakeTimers()
    const ticks = captureEvents("cw--interval:tick")
    await mountFake(markup({ ms: 500 }), CONTROLLERS)

    document.body.innerHTML = ""
    await vi.advanceTimersByTimeAsync(0)

    await vi.advanceTimersByTimeAsync(5000)
    expect(ticks).toHaveLength(0)
  })

  test("disconnect removes the visibilitychange listener", async () => {
    vi.useFakeTimers()
    const ticks = captureEvents("cw--interval:tick")
    await mountFake(markup({ ms: 500 }), CONTROLLERS)

    document.body.innerHTML = ""
    await vi.advanceTimersByTimeAsync(0)

    // Should not throw, and should have no further effect on a disconnected controller.
    setHidden(true)
    setHidden(false)
    await vi.advanceTimersByTimeAsync(2000)

    expect(ticks).toHaveLength(0)
  })
})
