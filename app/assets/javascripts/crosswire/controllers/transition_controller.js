import { Controller } from "@hotwired/stimulus"

// A small margin added on top of the computed transition duration before the fallback
// timeout fires, so a transition that finishes right on the wire still gets a real
// `transitionend` rather than racing the timeout. See #timeoutFor below.
const TIMEOUT_MARGIN_MS = 50

/**
 * cw--transition — run an enter/leave CSS class sequence and resolve when it finishes.
 *
 * Classes  enter, enterFrom, enterTo, leave, leaveFrom, leaveTo (all optional)
 * Actions  enter, leave
 * Events   cw--transition:entering, :entered, :leaving, :left
 *
 * Rule 0 — read the presenter docstring first. CSS `@starting-style` +
 * `transition-behavior: allow-discrete` already handles enter transitions, including
 * Turbo-Stream-inserted content, with zero JavaScript. The one thing CSS cannot do is
 * exit-on-removal — `Node.remove()` is synchronous, so a node is gone before any
 * transition can run. That is this controller's entire reason to exist: it is a narrow
 * hook that intercepts a removal, animates it, and only then lets it complete. Reach for
 * `enter()` sparingly — it exists for the cases where content is toggled in place rather
 * than freshly inserted (so `@starting-style` never triggers), not as a general-purpose
 * replacement for CSS.
 *
 * Composition: pairs with `cw--dismiss`, which dispatches a cancelable
 * `cw--dismiss:dismissing` carrying `detail.complete()`. Wire it directly —
 *
 *   data-action="cw--dismiss:dismissing->cw--transition#leave"
 *
 * `leave()` calls `event.preventDefault()` to hold the removal open, runs the leave
 * class sequence, then calls `detail.complete()` so `cw--dismiss` finishes the job. Used
 * without such an event (e.g. `data-action="click->cw--transition#leave"`), it simply
 * runs the animation and dispatches `left` — the caller is responsible for any DOM
 * change that should follow, which keeps this controller a narrow hook rather than
 * absorbing removal/hiding itself (see R6 in the component contract).
 *
 * Must not hang: if `transitionend` never fires — no transition defined, `display:
 * none`, an interrupted animation — a fallback timeout derived from the computed
 * `transition-duration` (+ a small margin) completes anyway. A transition controller
 * that can deadlock a removal is worse than none.
 *
 * Honours `prefers-reduced-motion`: skips the class dance and resolves immediately.
 */
export default class TransitionController extends Controller {
  static classes = ["enter", "enterFrom", "enterTo", "leave", "leaveFrom", "leaveTo"]

  #cleanups = new Set()

  disconnect() {
    // Exhaustive teardown (R7): any transition in flight when this element is torn down
    // — e.g. removed from the Turbo cache mid-animation — must not leak its listener or
    // timer.
    for (const cleanup of this.#cleanups) cleanup()
    this.#cleanups.clear()
  }

  enter(event) {
    return this.#run("enter", event)
  }

  leave(event) {
    return this.#run("leave", event)
  }

  async #run(kind, event) {
    event?.preventDefault?.()

    const complete = event?.detail?.complete
    const verbing = kind === "enter" ? "entering" : "leaving"
    const verbed = kind === "enter" ? "entered" : "left"

    const starting = this.dispatch(verbing, { cancelable: true })

    if (starting.defaultPrevented || this.#prefersReducedMotion) {
      this.#finish(verbed, complete)
      return
    }

    const element = this.element
    const base = this.#classFor(kind)
    const from = this.#classFor(`${kind}From`)
    const to = this.#classFor(`${kind}To`)

    this.#addClasses(element, base, from)
    // Force a reflow so the browser commits the "from" state before we flip to "to" on
    // the next frame — otherwise the browser may coalesce both class changes into one
    // paint and no transition fires at all.
    void element.offsetHeight

    await this.#nextFrame()
    this.#removeClasses(element, from)
    this.#addClasses(element, to)

    await this.#waitForTransitionEnd(element)

    this.#removeClasses(element, base, to)
    this.#finish(verbed, complete)
  }

  #finish(eventName, complete) {
    this.dispatch(eventName)
    complete?.()
  }

  #classFor(name) {
    const capitalized = name[0].toUpperCase() + name.slice(1)
    const hasKey = `has${capitalized}Class`
    return this[hasKey] ? this[`${name}Class`] : null
  }

  #addClasses(element, ...classNames) {
    for (const className of classNames) {
      if (!className) continue
      element.classList.add(...className.split(/\s+/).filter(Boolean))
    }
  }

  #removeClasses(element, ...classNames) {
    for (const className of classNames) {
      if (!className) continue
      element.classList.remove(...className.split(/\s+/).filter(Boolean))
    }
  }

  #nextFrame() {
    return new Promise((resolve) => {
      if (typeof requestAnimationFrame === "function") {
        requestAnimationFrame(() => requestAnimationFrame(() => resolve()))
      } else {
        setTimeout(resolve, 0)
      }
    })
  }

  #waitForTransitionEnd(element) {
    return new Promise((resolve) => {
      let done
      const onEnd = (event) => {
        if (event.target !== element) return
        done()
      }

      done = () => {
        element.removeEventListener("transitionend", onEnd)
        clearTimeout(timer)
        this.#cleanups.delete(done)
        resolve()
      }

      const timer = setTimeout(done, this.#timeoutFor(element))
      element.addEventListener("transitionend", onEnd)
      this.#cleanups.add(done)
    })
  }

  // Derives a fallback timeout from the computed transition-duration (and any
  // transition-delay) so a missing or interrupted `transitionend` can never hang a
  // removal forever. A small margin absorbs timer jitter around the real end.
  #timeoutFor(element) {
    const style = getComputedStyle(element)
    const durations = this.#parseTimeList(style.transitionDuration)
    const delays = this.#parseTimeList(style.transitionDelay)
    const count = Math.max(durations.length, delays.length, 1)

    let longest = 0
    for (let i = 0; i < count; i++) {
      const duration = durations[i % durations.length] ?? 0
      const delay = delays[i % delays.length] ?? 0
      longest = Math.max(longest, duration + delay)
    }

    return longest * 1000 + TIMEOUT_MARGIN_MS
  }

  #parseTimeList(value) {
    if (!value) return [0]

    const times = value.split(",").map((part) => {
      const seconds = parseFloat(part)
      return Number.isNaN(seconds) ? 0 : seconds
    })

    return times.length ? times : [0]
  }

  get #prefersReducedMotion() {
    try {
      return globalThis.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches ?? false
    } catch {
      return false
    }
  }
}
