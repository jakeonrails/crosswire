import { Controller } from "@hotwired/stimulus"

/**
 * cw--timeout — dispatch an action once, N ms after connect or after a trigger.
 *
 * Values   delay (Number ms, required), startOnConnect (Boolean, default true)
 * Actions  start, cancel, restart
 * Events   cw--timeout:elapsed, cw--timeout:cancelled
 *
 * Sits beside `interval`, not on top of it: `interval` re-arms itself and keeps
 * ticking until stopped; this fires once and never re-arms on its own. A toast's
 * auto-dismiss and a "resend code in 30s" cooldown want `timeout`; a polling
 * `<turbo-frame>` wants `interval`. `restart` gives you "push the deadline back"
 * (a hover-to-pause toast) without needing `interval`'s repetition at all.
 *
 * No Rule 0: there is no platform primitive for "run this once, later" beyond a bare
 * `setTimeout`, which is exactly what this wraps — plus Turbo-aware teardown and
 * pausing while the tab is hidden, neither of which a bare `setTimeout` gives you.
 *
 * PAUSES WHILE THE DOCUMENT IS HIDDEN, resuming with the genuinely-remaining delay
 * once it's visible again. Browsers throttle (but do not necessarily fully suspend)
 * timers in a background tab, so without this a handful of timeouts armed around the
 * same time — several toasts, say — can all become eligible to fire within the same
 * instant the tab regains focus, dumping a pile of `elapsed` events (and whatever
 * dismissals/side-effects they drive) on the user all at once instead of the
 * spaced-out sequence they were actually scheduled for. Pausing means the remaining
 * time is exact and resumes from where it left off, not from whatever the background
 * throttle happened to allow through.
 *
 * Single write path: the three action methods only ever call `#arm`/`#clear`/
 * `#pause`/`#resume` — none of them dispatch directly. `#fire` (the setTimeout
 * callback) and `cancel()` are the only two places an event is dispatched, so there is
 * exactly one path to each event, matching R4's "one write path" even though there is
 * no Stimulus value driving the DOM here (this controller has no DOM to render; the
 * "value" it manages is a timer, not markup).
 *
 * disconnect() clears any pending timer unconditionally (R7) and does NOT dispatch
 * `cancelled` — an element being removed by Turbo (a frame re-render, a cache
 * eviction) is routine lifecycle, not a meaningful cancellation a consumer asked for,
 * and dispatching on every single disconnect would be exactly the kind of phantom
 * event R4a exists to avoid, just arrived at from the teardown side instead of the
 * connect side.
 */
export default class TimeoutController extends Controller {
  static values = {
    delay: Number,
    startOnConnect: { type: Boolean, default: true }
  }

  #timerId = null
  #running = false
  #deadline = null // Date.now() timestamp the timer will fire at, while running
  #remaining = null // ms left, while paused (hidden document) — null means "not paused"

  connect() {
    document.addEventListener("visibilitychange", this.#onVisibilityChange)
    if (this.startOnConnectValue) this.start()
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.#onVisibilityChange)
    this.#clear()
  }

  start() {
    if (this.#running || this.#remaining !== null) return
    this.#arm(this.delayValue)
  }

  cancel() {
    if (!this.#running && this.#remaining === null) return

    this.#clear()
    this.dispatch("cancelled")
  }

  restart() {
    this.#clear()
    this.#arm(this.delayValue)
  }

  #arm(ms) {
    this.#running = true
    this.#deadline = Date.now() + ms
    this.#remaining = null
    this.#timerId = setTimeout(this.#fire, ms)

    // Started (or restarted) while the tab is already backgrounded: pause it
    // immediately rather than letting a real timer accumulate out of sight. The next
    // `visibilitychange` to "visible" resumes it with the exact remaining time.
    if (document.visibilityState === "hidden") this.#pause()
  }

  #fire = () => {
    this.#timerId = null
    this.#running = false
    this.#remaining = null
    this.#deadline = null

    this.dispatch("elapsed", { detail: { delay: this.delayValue } })
  }

  #clear() {
    if (this.#timerId !== null) clearTimeout(this.#timerId)

    this.#timerId = null
    this.#running = false
    this.#remaining = null
    this.#deadline = null
  }

  #onVisibilityChange = () => {
    if (document.visibilityState === "hidden") {
      this.#pause()
    } else {
      this.#resume()
    }
  }

  #pause() {
    if (!this.#running) return

    clearTimeout(this.#timerId)
    this.#timerId = null
    this.#running = false
    this.#remaining = Math.max(0, this.#deadline - Date.now())
    this.#deadline = null
  }

  #resume() {
    if (this.#running || this.#remaining === null) return

    const ms = this.#remaining
    this.#remaining = null
    this.#running = true
    this.#deadline = Date.now() + ms
    this.#timerId = setTimeout(this.#fire, ms)
  }
}
