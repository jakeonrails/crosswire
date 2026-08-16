import { Controller } from "@hotwired/stimulus"

/**
 * cw--interval — dispatch a `tick` every N milliseconds while the document is
 * visible.
 *
 * Values   ms (Number, required), immediate (Boolean, default false — dispatch
 *          one extra tick immediately on connect)
 * Events   cw--interval:tick — detail: { count }, a 1-based count of ticks
 *          dispatched by THIS controller instance since connect (the immediate
 *          connect tick, if any, counts as tick 1)
 *
 * Sits beside `timeout`, not on top of it: `timeout` fires once and never
 * re-arms; this re-arms on every tick and keeps going until disconnect. Reach
 * for `timeout` for "run this once, later" (an auto-dismiss, a cooldown); reach
 * for this for "keep running until told to stop" (polling, a heartbeat, a
 * progress bar). See `timeout_controller.js` for the same note from the other
 * side.
 *
 * Rule 0 — for polling a server, compose a lazy `<turbo-frame>` with this
 * controller reloading it on every tick. Do not build a bespoke "poll"
 * controller; this plus a frame IS the poll.
 *
 * PAUSE/RESUME ON VISIBILITYCHANGE — the reason this exists instead of a bare
 * `setInterval`. Without it, a backgrounded tab either:
 *   (a) keeps ticking on schedule, burning cycles (and, for a polling frame,
 *       network requests) for work nobody is looking at, or
 *   (b) if a naive implementation tries to "catch up" missed ticks, dumps a
 *       pile of stale `tick` events — and whatever side effects they drive — on
 *       the user the instant the tab regains focus.
 * This controller does neither: `#stop()` on hidden clears the running interval
 * outright (no ticks accumulate, nothing to catch up), and `#start()` on visible
 * begins a FRESH interval from that moment — not a resumed one carrying forward
 * elapsed background time. The tradeoff is that the tick cadence resets to
 * visibility-change moments rather than staying phase-locked to connect time;
 * that is the correct tradeoff for "poll only while looked at," which is the
 * only thing this primitive promises.
 *
 * Unlike `timeout`, there is no "remaining time" to preserve across a pause —
 * `interval` has no deadline, only a cadence, so "stop, then start clean" is the
 * whole mechanism. `timeout` needs the more elaborate remaining-time bookkeeping
 * precisely because it DOES have a single deadline worth preserving.
 *
 * R7: `disconnect()` clears the pending interval (if any) and removes the
 * `visibilitychange` listener unconditionally.
 */
export default class IntervalController extends Controller {
  static values = {
    ms: Number,
    immediate: { type: Boolean, default: false }
  }

  #timerId = null
  #count = 0

  connect() {
    document.addEventListener("visibilitychange", this.#onVisibilityChange)

    if (this.immediateValue) this.#tick()
    if (document.visibilityState !== "hidden") this.#start()
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.#onVisibilityChange)
    this.#stop()
  }

  #start() {
    if (this.#timerId !== null) return

    this.#timerId = setInterval(this.#tick, this.msValue)
  }

  #stop() {
    if (this.#timerId !== null) clearInterval(this.#timerId)

    this.#timerId = null
  }

  #tick = () => {
    this.#count += 1
    this.dispatch("tick", { detail: { count: this.#count } })
  }

  #onVisibilityChange = () => {
    if (document.visibilityState === "hidden") {
      this.#stop()
    } else {
      this.#start()
    }
  }
}
