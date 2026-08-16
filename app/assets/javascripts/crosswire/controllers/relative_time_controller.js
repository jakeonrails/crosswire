import { Controller } from "@hotwired/stimulus"

const SECONDS_PER = { minute: 60, hour: 3600, day: 86_400 }

/**
 * cw--relative-time — render and self-update a relative timestamp ("3 minutes
 * ago").
 *
 * Values   datetime (String, ISO 8601, required), format (String: "relative"
 *          default | "datetime"), threshold (Number, seconds — default 86400,
 *          one day)
 *
 * RULE 0 — READ THIS FIRST. Prefer `<relative-time>` from
 * `@github/relative-time-element` over this controller. It is a mature,
 * actively maintained custom element that does the same job properly:
 * `Intl.RelativeTimeFormat` localisation, a `title` with the absolute time,
 * per-instance self-adjusting scheduling, and — because a custom element's
 * lifecycle is owned by the browser, not Stimulus — zero connect/disconnect
 * discipline needed after a Turbo Stream append, frame swap, morph, or cache
 * restore. This controller exists only for the case where you do not want
 * another JS dependency and need nothing beyond coarse-grained English
 * relative phrasing. It still uses `Intl.RelativeTimeFormat` itself rather
 * than hand-rolling "3 minutes ago" — the formatting is correct and localised,
 * only the feature surface (precision, duration/micro formats, full locale
 * passthrough) is smaller than the web component's.
 *
 * WHY THIS OWNS ITS OWN TIMER RATHER THAN COMPOSING WITH `cw--interval`:
 * `interval` promises one FIXED cadence for as long as it runs. This
 * controller's whole point is a cadence that changes as the timestamp ages —
 * 10s, then 60s, then 3600s, then a day, then stop entirely — which `interval`
 * cannot express on its own. Composing would mean stacking `cw--interval` on
 * this element and, on every `cw--interval:tick`, reaching back into
 * `interval`'s OWN value attribute (`setAttribute("data-cw--interval-ms-value",
 * ...)`, the R5a #2 mechanism for driving a sibling controller with no backing
 * DOM event) to reprogram its cadence for the next tier. That is strictly more
 * machinery than a single self-adjusting `setTimeout` chain that recomputes its
 * own next delay on every render — and it still needs that same
 * next-delay-computation logic either way, so composing buys nothing here. Two
 * controllers is the right shape when the work is genuinely separable
 * (`dismiss` + `timeout`); here the "next delay" computation and the "what to
 * render" computation are the same piece of domain knowledge (how old is this
 * timestamp), so one controller owning both is the honest shape.
 *
 * UPDATE CADENCE (back-off), per render, based on the timestamp's age:
 *   age < 60s        → render in seconds,  reschedule in 10s
 *   age < 1 hour      → render in minutes,  reschedule in 60s
 *   age < 1 day       → render in hours,    reschedule in 3600s (1 hour)
 *   age >= 1 day       → render in days,     reschedule in 1 day
 * Never reschedules past `threshold`: the next delay is capped so the element
 * always transitions to the absolute date exactly when its age crosses
 * `threshold`, never later. With the default `threshold` (one day), the "age
 * >= 1 day" tier above never actually gets a chance to re-render — the switch
 * to absolute happens first — which is the intended reading of "every hour
 * under a day, then stop." A larger `threshold` (e.g. a week) is what makes the
 * day-granularity tier meaningful; a smaller one (e.g. an hour, for a chat
 * where "yesterday" is more useful than a stale "18 hours ago") makes the
 * switch to absolute happen sooner still. This is why `threshold` is not
 * merely a display cutoff: it also bounds the timer this controller keeps
 * running.
 *
 * `format: "datetime"` skips relative rendering and scheduling entirely —
 * it renders the absolute date once via `Intl.DateTimeFormat` and never
 * reschedules, the same terminal state a relative timestamp reaches once past
 * `threshold`.
 *
 * NOT PAUSED ON `visibilitychange`, unlike `interval` and `timeout`. Both of
 * those need it because a fast, indefinitely-repeating timer left running in a
 * background tab either burns cycles or produces a stale-tick pile-up on
 * refocus. Neither risk applies here: every scheduled step is a single
 * one-shot `setTimeout`, never a burst, and even the fastest cadence (10s) is
 * well within what browsers already throttle a background tab's timers to
 * without any help from us — there is nothing to "catch up."
 *
 * ACCESSIBILITY (R2, mostly in the presenter): `root_attrs` always emits a
 * literal `datetime` and a `title` carrying the absolute instant, so hovering
 * or a screen reader's "read title" gesture recovers the exact time regardless
 * of how coarse the visible text is. Deliberately no `aria-live` — a
 * self-updating timestamp that announces itself on every change is a
 * screen-reader denial-of-service; `title`/`datetime` is the accessible
 * escape hatch here, not a live region.
 *
 * R7: `disconnect()` clears the single pending `setTimeout`, if any. There are
 * no listeners or observers to remove.
 */
export default class RelativeTimeController extends Controller {
  static values = {
    datetime: String,
    format: { type: String, default: "relative" },
    threshold: { type: Number, default: 86_400 }
  }

  #timerId = null
  #rtf = null
  #dtf = null

  connect() {
    this.#rtf = new Intl.RelativeTimeFormat(document.documentElement.lang || "en", { numeric: "auto" })
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

    const instant = Date.parse(this.datetimeValue)
    const ageSeconds = (Date.now() - instant) / 1000 // positive = past, negative = future
    const absAge = Math.abs(ageSeconds)

    if (this.formatValue === "datetime" || absAge >= this.thresholdValue) {
      this.element.textContent = this.#formatAbsolute(instant)
      return // Terminal state: nothing left to reschedule.
    }

    const { text, nextDelayMs } = this.#formatRelative(ageSeconds, absAge)
    this.element.textContent = text

    const msUntilThreshold = (this.thresholdValue - absAge) * 1000
    const delay = Math.max(0, Math.min(nextDelayMs, msUntilThreshold))
    this.#timerId = setTimeout(() => this.#render(), delay)
  }

  #formatAbsolute(instant) {
    this.#dtf ??= new Intl.DateTimeFormat(document.documentElement.lang || "en", {
      dateStyle: "medium",
      timeStyle: "short"
    })
    return this.#dtf.format(instant)
  }

  #formatRelative(ageSeconds, absAge) {
    if (absAge < 60) {
      return { text: this.#rtf.format(Math.round(-ageSeconds), "second"), nextDelayMs: 10_000 }
    }
    if (absAge < SECONDS_PER.hour) {
      return { text: this.#rtf.format(Math.round(-ageSeconds / SECONDS_PER.minute), "minute"), nextDelayMs: 60_000 }
    }
    if (absAge < SECONDS_PER.day) {
      return { text: this.#rtf.format(Math.round(-ageSeconds / SECONDS_PER.hour), "hour"), nextDelayMs: 3_600_000 }
    }
    return { text: this.#rtf.format(Math.round(-ageSeconds / SECONDS_PER.day), "day"), nextDelayMs: 86_400_000 }
  }
}
