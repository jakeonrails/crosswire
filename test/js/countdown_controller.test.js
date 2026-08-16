import { afterEach, describe, expect, test, vi } from "vitest"
import CountdownController from "../../app/assets/javascripts/crosswire/controllers/countdown_controller.js"
import { captureEvents, mount } from "./setup.js"

const CONTROLLERS = { "cw--countdown": CountdownController }
const NOW = "2026-08-15T12:00:00.000Z"

// Fake timers + a fixed system clock throughout, for the same reason as
// relative_time_controller.test.js: the back-off cadence spans minutes and hours, which
// a real-wait suite could not exercise without being either slow or unable to reach the
// slower tiers at all.
//
// A local afterEach restores real timers before setup.js's own afterEach runs (Vitest
// runs afterEach hooks in reverse registration order, so a hook declared here — after
// setup.js's is already registered via setupFiles — runs first). Without this, setup.js's
// `await new Promise((resolve) => setTimeout(resolve, 0))` would hang against a faked
// clock nothing ever advances again.
afterEach(() => {
  vi.useRealTimers()
})

async function mountFake(html, controllers) {
  const pending = mount(html, controllers)
  await vi.advanceTimersByTimeAsync(0)
  return pending
}

function markup({ deadline, format = null } = {}) {
  return `
    <div data-controller="cw--countdown"
         data-cw--countdown-deadline-value="${deadline}"
         ${format !== null ? `data-cw--countdown-format-value="${format}"` : ""}>
      <time data-cw--countdown-target="output">fallback</time>
    </div>`
}

function isoPlus(seconds) {
  return new Date(Date.parse(NOW) + seconds * 1000).toISOString()
}

function isoMinus(seconds) {
  return new Date(Date.parse(NOW) - seconds * 1000).toISOString()
}

function output(root) {
  return root.querySelector("[data-cw--countdown-target='output']")
}

describe("cw--countdown", () => {
  test("renders clock format (M:SS) by default and ticks down", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const el = await mountFake(markup({ deadline: isoPlus(90) }), CONTROLLERS)

    expect(output(el).textContent).toBe("1:30")

    await vi.advanceTimersByTimeAsync(10_000)
    expect(output(el).textContent).toBe("1:20")
  })

  test("renders words format", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const el = await mountFake(markup({ deadline: isoPlus(125), format: "words" }), CONTROLLERS)

    expect(output(el).textContent).toBe("2 minutes")
  })

  test("clock format includes hours once past an hour remaining", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const el = await mountFake(markup({ deadline: isoPlus(2 * 3600 + 65) }), CONTROLLERS)

    expect(output(el).textContent).toBe("2:01:05")
  })

  // --- deadline already past on connect ----------------------------------------------

  test("a deadline already in the past fires elapsed immediately with no negative count", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const elapsed = captureEvents("cw--countdown:elapsed")
    const ticks = captureEvents("cw--countdown:tick")
    const el = await mountFake(markup({ deadline: isoMinus(5) }), CONTROLLERS)

    expect(output(el).textContent).toBe("0:00")
    expect(elapsed).toHaveLength(1)
    expect(elapsed[0].detail.deadline).toBe(isoMinus(5))
    expect(ticks).toHaveLength(0) // never started a tick loop

    // No pending timer either — advancing time must change nothing further.
    await vi.advanceTimersByTimeAsync(60_000)
    expect(elapsed).toHaveLength(1)
  })

  // --- ticking to zero: tick events, exactly one elapsed -----------------------------

  test("dispatches tick on every update with remaining seconds, then elapsed exactly once at zero", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const elapsed = captureEvents("cw--countdown:elapsed")
    const ticks = captureEvents("cw--countdown:tick")
    await mountFake(markup({ deadline: isoPlus(2) }), CONTROLLERS)

    expect(ticks).toHaveLength(1)
    expect(ticks[0].detail.remaining).toBe(2)

    await vi.advanceTimersByTimeAsync(1000)
    expect(ticks).toHaveLength(2)
    expect(ticks[1].detail.remaining).toBe(1)
    expect(elapsed).toHaveLength(0)

    await vi.advanceTimersByTimeAsync(1000)
    expect(elapsed).toHaveLength(1)
    expect(ticks).toHaveLength(2) // no further tick once elapsed

    // Stays elapsed — advancing further dispatches nothing more.
    await vi.advanceTimersByTimeAsync(10_000)
    expect(elapsed).toHaveLength(1)
  })

  // --- back-off cadence, mirrored from time elapsed to time remaining ----------------

  test("reschedules every minute once remaining is over an hour", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const el = await mountFake(markup({ deadline: isoPlus(2 * 3600) }), CONTROLLERS)
    expect(output(el).textContent).toBe("2:00:00")

    await vi.advanceTimersByTimeAsync(59_999)
    expect(output(el).textContent).toBe("2:00:00") // not yet rescheduled

    await vi.advanceTimersByTimeAsync(1)
    expect(output(el).textContent).toBe("1:59:00")
  })

  test("reschedules every hour once remaining is over a day", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const el = await mountFake(markup({ deadline: isoPlus(2 * 86_400) }), CONTROLLERS)
    expect(output(el).textContent).toBe("2:00:00:00")

    await vi.advanceTimersByTimeAsync(3_600_000)
    expect(output(el).textContent).toBe("1:23:00:00")
  })

  // --- accessibility: aria-live rests off, flips to assertive only in the last 30s --

  test("aria-live is off while more than 30 seconds remain", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const el = await mountFake(markup({ deadline: isoPlus(35) }), CONTROLLERS)

    expect(output(el).getAttribute("aria-live")).toBe("off")
  })

  test("aria-live flips to assertive once 30 seconds or fewer remain", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const el = await mountFake(markup({ deadline: isoPlus(35) }), CONTROLLERS)

    await vi.advanceTimersByTimeAsync(5000) // 35s -> 30s remaining
    expect(output(el).getAttribute("aria-live")).toBe("assertive")
  })

  // --- R7: exhaustive teardown -------------------------------------------------------

  test("disconnect clears the pending reschedule", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const ticks = captureEvents("cw--countdown:tick")
    const el = await mountFake(markup({ deadline: isoPlus(5) }), CONTROLLERS)
    expect(ticks).toHaveLength(1)

    document.body.innerHTML = ""
    await vi.advanceTimersByTimeAsync(0)

    await vi.advanceTimersByTimeAsync(10_000)
    expect(ticks).toHaveLength(1) // no further ticks after disconnect
    expect(output(el)).toBeTruthy() // sanity: the detached node is still the one we mounted
  })
})
