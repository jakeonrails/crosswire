import { Controller } from "@hotwired/stimulus"

const SECONDS_PER = { minute: 60, hour: 3600, day: 86_400 }
const ANNOUNCE_WINDOW_SECONDS = 30 // see "ACCESSIBILITY" below

/**
 * cw--countdown — tick down to a deadline and dispatch at zero.
 *
 * Targets  output — receives the ticking text
 * Values   deadline (String, ISO 8601, required), format (String: "clock"
 *          default — H:MM:SS / M:SS — or "words" — coarse humanised phrasing)
 * Events   cw--countdown:tick (detail: { remaining } — whole seconds remaining,
 *          never negative), cw--countdown:elapsed (detail: { deadline },
 *          dispatched exactly once, when remaining first reaches zero)
 *
 * No Rule 0: there is no platform primitive for "count down to an instant and
 * tell me when it arrives." A countdown that must fire while the app is
 * backgrounded is a native local notification, not a web timer — out of scope.
 *
 * DEADLINE ALREADY PAST ON CONNECT: renders the zero state and dispatches
 * `elapsed` immediately, with no negative countdown and no tick loop ever
 * started. This is the same "send an instant, not a duration" discipline as
 * `deadlineValue` itself — a page that sat in the Turbo cache past its own
 * deadline must resolve to "already over," not a confusing negative count or a
 * count that silently never fires.
 *
 * UPDATE CADENCE (back-off), based on time REMAINING — the mirror image of
 * `relative-time`'s back-off by time elapsed, and for the same reason: a
 * `setInterval(1000)` on a countdown that is hours or days out is wasted work
 * for a display nobody is watching closely yet.
 *   remaining > 1 day    → reschedule every hour
 *   remaining > 1 hour    → reschedule every minute
 *   remaining > 1 minute  → reschedule every 10s
 *   remaining <= 1 minute  → reschedule every 1s
 * The final tier ticks every second for the whole last minute — a countdown's
 * final minute is exactly the part where second-level visual precision is the
 * point, unlike `relative-time` where "37 seconds ago" vs "41 seconds ago" is
 * not meaningfully different information. Each reschedule is capped so it never
 * overshoots the deadline itself.
 *
 * ACCESSIBILITY (R2, mostly in the presenter): `output_attrs` bakes in
 * `role="timer"` and a resting `aria-live="off"` — announcing a change every
 * second (or even every ten) is a screen-reader denial-of-service, not a
 * countdown. This controller flips `aria-live` to `"assertive"` for the FINAL
 * 30 SECONDS ONLY, then it reverts to `"off"` once disconnected/elapsed — so a
 * screen-reader user gets exactly the part of the countdown where a per-second
 * announcement is actually meaningful ("5… 4… 3…"), and silence for the long
 * stretch beforehand where it would just be noise. This is a coarser
 * granularity than milestone-only announcements ("1 minute remaining") would
 * give, chosen deliberately for simplicity: a single documented threshold is
 * easier to reason about and test than a list of milestone instants, and 30
 * seconds of assertive ticking is short enough not to be hostile.
 *
 * The visual tick rate (every 1s for the whole last minute) and the
 * announcement window (assertive for only the last 30s) are deliberately
 * different spans — the DOM can update quietly far more often than a screen
 * reader should be interrupted.
 *
 * `datetime` values that end up in the past mid-countdown are all `remaining <=
 * 0`: only one `elapsed` event ever fires, guarded by the same terminal state
 * that stops rescheduling.
 *
 * R7: `disconnect()` clears the single pending `setTimeout`, if any.
 */
export default class CountdownController extends Controller {
  static targets = ["output"]
  static values = {
    deadline: String,
    format: { type: String, default: "clock" }
  }

  #timerId = null
  #elapsedDispatched = false

  connect() {
    this.#render()
  }

  disconnect() {
    this.#clear()
  }

  #clear() {
    if (this.#timerId !== null) clearTimeout(this.#timerId)
    this.#timerId = null
  }

  #render() {
    this.#clear()

    const remainingMs = Math.max(0, Date.parse(this.deadlineValue) - Date.now())
    const remainingSeconds = Math.ceil(remainingMs / 1000)

    if (this.hasOutputTarget) {
      this.outputTarget.textContent = this.#format(remainingSeconds)
      this.outputTarget.setAttribute("aria-live", remainingSeconds <= ANNOUNCE_WINDOW_SECONDS ? "assertive" : "off")
    }

    if (remainingMs <= 0) {
      if (!this.#elapsedDispatched) {
        this.#elapsedDispatched = true
        this.dispatch("elapsed", { detail: { deadline: this.deadlineValue } })
      }
      return // Terminal state: nothing left to reschedule.
    }

    this.dispatch("tick", { detail: { remaining: remainingSeconds } })

    const delay = Math.min(this.#nextDelayMs(remainingSeconds), remainingMs)
    this.#timerId = setTimeout(() => this.#render(), delay)
  }

  #nextDelayMs(remainingSeconds) {
    if (remainingSeconds > SECONDS_PER.day) return 3_600_000
    if (remainingSeconds > SECONDS_PER.hour) return 60_000
    if (remainingSeconds > SECONDS_PER.minute) return 10_000
    return 1000
  }

  #format(remainingSeconds) {
    return this.formatValue === "words" ? this.#formatWords(remainingSeconds) : this.#formatClock(remainingSeconds)
  }

  #formatClock(remainingSeconds) {
    const days = Math.floor(remainingSeconds / SECONDS_PER.day)
    const hours = Math.floor((remainingSeconds % SECONDS_PER.day) / SECONDS_PER.hour)
    const minutes = Math.floor((remainingSeconds % SECONDS_PER.hour) / SECONDS_PER.minute)
    const seconds = remainingSeconds % SECONDS_PER.minute
    const pad = (n) => String(n).padStart(2, "0")

    if (days > 0) return `${days}:${pad(hours)}:${pad(minutes)}:${pad(seconds)}`
    if (hours > 0) return `${hours}:${pad(minutes)}:${pad(seconds)}`
    return `${minutes}:${pad(seconds)}`
  }

  #formatWords(remainingSeconds) {
    const tiers = [
      [SECONDS_PER.day, "day"],
      [SECONDS_PER.hour, "hour"],
      [SECONDS_PER.minute, "minute"],
      [1, "second"]
    ]
    const [unitSeconds, unit] = tiers.find(([s]) => remainingSeconds >= s) || tiers[tiers.length - 1]
    const value = Math.floor(remainingSeconds / unitSeconds) || 0

    return `${value} ${unit}${value === 1 ? "" : "s"}`
  }
}
