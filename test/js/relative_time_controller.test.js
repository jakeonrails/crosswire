import { afterEach, describe, expect, test, vi } from "vitest"
import RelativeTimeController from "../../app/assets/javascripts/crosswire/controllers/relative_time_controller.js"
import { mount } from "./setup.js"

const CONTROLLERS = { "cw--relative-time": RelativeTimeController }
const NOW = "2026-08-15T12:00:00.000Z"

// Fake timers + a fixed system clock throughout: the cadence back-off spans minutes,
// hours and days, which would make a real-wait suite either impossibly slow or unable
// to exercise the longer tiers at all. `vi.setSystemTime` combined with fake timers
// means Date.now() advances in lockstep with `vi.advanceTimersByTimeAsync`, so the
// controller's own re-renders see a consistent, controlled clock throughout.
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

function markup({ datetime, format = null, threshold = null } = {}) {
  return `
    <time data-controller="cw--relative-time"
          data-cw--relative-time-datetime-value="${datetime}"
          ${format !== null ? `data-cw--relative-time-format-value="${format}"` : ""}
          ${threshold !== null ? `data-cw--relative-time-threshold-value="${threshold}"` : ""}>fallback</time>`
}

function isoMinus(seconds) {
  return new Date(Date.parse(NOW) - seconds * 1000).toISOString()
}

function isoPlus(seconds) {
  return new Date(Date.parse(NOW) + seconds * 1000).toISOString()
}

describe("cw--relative-time", () => {
  test("renders coarse relative text in seconds under a minute", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const el = await mountFake(markup({ datetime: isoMinus(30) }), CONTROLLERS)

    expect(el.textContent).toBe("30 seconds ago")
  })

  test("renders in minutes once past a minute", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const el = await mountFake(markup({ datetime: isoMinus(120) }), CONTROLLERS)

    expect(el.textContent).toBe("2 minutes ago")
  })

  test("renders in hours once past an hour", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const el = await mountFake(markup({ datetime: isoMinus(3 * 3600) }), CONTROLLERS)

    expect(el.textContent).toBe("3 hours ago")
  })

  test("supports future timestamps", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const el = await mountFake(markup({ datetime: isoPlus(300) }), CONTROLLERS)

    expect(el.textContent).toBe("in 5 minutes")
  })

  // --- back-off: reschedules at the tier-appropriate cadence, not a fixed rate ------

  test("reschedules every 10s while under a minute old, then updates the text", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const el = await mountFake(markup({ datetime: isoMinus(30) }), CONTROLLERS)
    expect(el.textContent).toBe("30 seconds ago")

    await vi.advanceTimersByTimeAsync(9999)
    expect(el.textContent).toBe("30 seconds ago") // not yet rescheduled

    await vi.advanceTimersByTimeAsync(1)
    expect(el.textContent).toBe("40 seconds ago") // 30s + 10s elapsed
  })

  test("reschedules every 60s once in the minutes tier", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const el = await mountFake(markup({ datetime: isoMinus(100) }), CONTROLLERS)
    expect(el.textContent).toBe("2 minutes ago") // 100s rounds to 2 minutes

    await vi.advanceTimersByTimeAsync(60_000)
    expect(el.textContent).toBe("3 minutes ago") // 160s elapsed rounds to 3 minutes
  })

  test("reschedules every hour once in the hours tier", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const el = await mountFake(markup({ datetime: isoMinus(2 * 3600) }), CONTROLLERS)
    expect(el.textContent).toBe("2 hours ago")

    await vi.advanceTimersByTimeAsync(3_600_000)
    expect(el.textContent).toBe("3 hours ago")
  })

  // --- threshold: stops updating and switches to an absolute date -------------------

  test("switches to an absolute date once age crosses threshold, and stops rescheduling", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const datetime = isoMinus(50)
    const el = await mountFake(markup({ datetime, threshold: 60 }), CONTROLLERS)
    expect(el.textContent).toBe("50 seconds ago")

    // Crosses the 60s threshold partway through the 10s-cadence tier — the reschedule
    // must be capped to land exactly at the threshold, not overshoot by a full 10s tick.
    await vi.advanceTimersByTimeAsync(10_000)

    const expected = new Intl.DateTimeFormat("en", { dateStyle: "medium", timeStyle: "short" })
      .format(new Date(datetime))
    expect(el.textContent).toBe(expected)

    // Terminal state: advancing further must not change anything or throw.
    await vi.advanceTimersByTimeAsync(3_600_000)
    expect(el.textContent).toBe(expected)
  })

  test("format: datetime renders an absolute date once and never reschedules", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const datetime = isoMinus(30)
    const el = await mountFake(markup({ datetime, format: "datetime" }), CONTROLLERS)

    const expected = new Intl.DateTimeFormat("en", { dateStyle: "medium", timeStyle: "short" })
      .format(new Date(datetime))
    expect(el.textContent).toBe(expected)

    await vi.advanceTimersByTimeAsync(24 * 3_600_000)
    expect(el.textContent).toBe(expected) // unchanged — there was never a timer to fire
  })

  // --- R7: exhaustive teardown -------------------------------------------------------

  test("disconnect clears the pending reschedule", async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(NOW))
    const el = await mountFake(markup({ datetime: isoMinus(30) }), CONTROLLERS)
    expect(el.textContent).toBe("30 seconds ago")

    document.body.innerHTML = ""
    await vi.advanceTimersByTimeAsync(0)

    // If disconnect() had NOT cleared the timer, this advance would fire the pending
    // 10s reschedule and mutate the (now detached) element's text.
    await vi.advanceTimersByTimeAsync(60_000)
    expect(el.textContent).toBe("30 seconds ago")
  })
})
