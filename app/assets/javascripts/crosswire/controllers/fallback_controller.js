import { Controller } from "@hotwired/stimulus"

/**
 * cw--fallback — a tri-state ("ok" | "loading" | "failed") indicator for the failure
 * Turbo has no answer to: a lazy `<turbo-frame loading="lazy" src="…">` whose
 * endpoint 500s just sits there showing its placeholder forever, and a
 * `<turbo-cable-stream-source>` whose WebSocket drops mid-session gives no visual
 * signal that broadcasts have stopped arriving.
 *
 * RULE 0: for "is this request taking a while," prefer `cw--loading` (or Turbo's own
 * `aria-busy` / `data-turbo-submits-with`) — see that controller's docstring. This
 * one exists specifically for the genuinely absent failure state.
 *
 * Targets  loading, failed, source (optional — a `<turbo-cable-stream-source>` to
 *          watch for connection loss; see `sourceTargetConnected` below)
 * Values   state (String: "ok" default | "loading" | "failed") — rendered
 *          server-side (R4): a lazy frame's wrapper starts in "loading" so the
 *          loading target is visible before JavaScript ever boots, not just after
 *          the first fetch event
 * Classes  failed (optional convenience class, applied to this.element)
 * Events   cw--fallback:failed (dispatched entering "failed"),
 *          cw--fallback:recovered (dispatched reaching "ok" after a failure — NOT
 *          merely when `previous === "failed"`: the realistic sequence is always
 *          failed -> loading -> ok, since `check()` cannot reach "ok" without
 *          `pending()` passing through "loading" first, so "loading" always sits
 *          between them. An ordinary first-time "loading" -> "ok" that was never
 *          failed does not count as a recovery.)
 *
 * `pending`/`check`/`fail` are wired to the Turbo events documented on the
 * presenter's `root_attrs` (`turbo:before-fetch-request`, `turbo:before-fetch-
 * response`, `turbo:fetch-request-error`, `turbo:frame-missing`) and bubble the same
 * way `cw--loading`'s do — this controller's placement (typically wrapping a single
 * `<turbo-frame>`) determines its scope, same as that one.
 *
 * `fail` calls `event.preventDefault()` on `turbo:frame-missing` deliberately:
 * Turbo's default behaviour for a missing frame is to visit the response as a full
 * page — this primitive exists so the FAILED STATE, not a surprise navigation, is
 * what the user sees. `turbo:fetch-request-error` is also cancelable; preventing it
 * suppresses Turbo's own console error in favour of the same owned failure UI.
 *
 * Single write path (R4): `pending`/`check`/`fail`/`retry` only ever decide WHETHER
 * to write `stateValue`; all DOM work and event dispatch happens in
 * `stateValueChanged`, guarded by a `#ready` flag rather than `previous ===
 * undefined` (R4a: Stimulus runs value callbacks before `connect()`, and the initial
 * `previous` for a typed String value is `""`, not `undefined`).
 */
export default class FallbackController extends Controller {
  static targets = ["loading", "failed", "source"]
  static values = {
    state: { type: String, default: "ok" }
  }
  static classes = ["failed"]

  #ready = false
  #streamObserver = null
  // Extra detail merged into the next `cw--fallback:failed` dispatch — set by
  // `#syncStreamConnection` immediately before writing `stateValue`, consumed (and
  // cleared) by `stateValueChanged` the moment it runs. Keeps DOM work AND dispatch
  // in the one place `stateValueChanged` owns (R4) while still letting a specific
  // failure path attach a reason a generic "state flipped to failed" cannot know.
  #nextFailedDetail = null
  // Tracks whether the CURRENT loading/retry cycle followed a failure, so "ok" can
  // tell a genuine recovery apart from an ordinary first-time success. The realistic
  // sequence is always failed -> loading -> ok (check() cannot reach "ok" without
  // pending() passing through "loading" first, since a response only arrives after a
  // request began) — comparing against the immediate `previous` value in
  // stateValueChanged would therefore never see "failed" by the time "ok" arrives,
  // since "loading" sits in between. Set true entering "failed" (including the
  // server-rendered initial state, tracked even before #ready — a page loaded already
  // showing a known failure still counts), cleared once "ok" is actually reached.
  #wasFailed = false

  connect() {
    this.#render()
    this.#ready = true
  }

  disconnect() {
    this.#ready = false
    this.#teardownStreamObserver()
  }

  // turbo:before-fetch-request -> the request is now in flight.
  pending() {
    this.stateValue = "loading"
  }

  // turbo:before-fetch-response -> did it succeed?
  check(event) {
    this.stateValue = event.detail?.fetchResponse?.succeeded ? "ok" : "failed"
  }

  // turbo:fetch-request-error, turbo:frame-missing -> this primitive owns the
  // failure UX instead of Turbo's own default handling.
  fail(event) {
    event?.preventDefault()
    this.stateValue = "failed"
  }

  // Hides the failed UI and re-triggers the work that failed. For a scope that is or
  // contains a <turbo-frame>, that frame's own reload() re-issues the request (which
  // will itself fire turbo:before-fetch-request -> pending() as it bubbles back up).
  // Outside a frame there is nothing generic to re-trigger — wire a second action on
  // the same retry control for that case (R5a case 1: an ordinary multi-action
  // data-action, no plumbing needed).
  retry() {
    this.stateValue = "loading"

    const frame = this.#frame()
    if (frame && typeof frame.reload === "function") frame.reload()
  }

  // Single write path (R4): all DOM work and dispatch happens here, once, regardless
  // of which action wrote the value.
  stateValueChanged(value) {
    this.#render()

    if (value === "failed") this.#wasFailed = true

    if (!this.#ready) return

    if (value === "failed") {
      const detail = { state: value, ...(this.#nextFailedDetail || {}) }
      this.#nextFailedDetail = null
      this.dispatch("failed", { detail })
    } else if (value === "ok" && this.#wasFailed) {
      this.#wasFailed = false
      this.#nextFailedDetail = null
      this.dispatch("recovered", { detail: { state: value } })
    } else {
      this.#nextFailedDetail = null
    }
  }

  // --- optional stream-connection watching ------------------------------------------
  //
  // Folds <turbo-cable-stream-source> connection status into the same tri-state
  // rather than needing a standalone "connection" primitive (rejected in the
  // research catalog for exactly that reason). turbo-rails toggles a `connected`
  // attribute on the element as its ActionCable subscription confirms/drops; a
  // MutationObserver is the only honest way to hear that, since neither event fires
  // through the Turbo event bus this controller otherwise listens to exclusively.

  sourceTargetConnected(el) {
    this.#teardownStreamObserver()

    this.#streamObserver = new MutationObserver((mutations) => {
      if (mutations.some((m) => m.attributeName === "connected")) this.#syncStreamConnection(el)
    })
    this.#streamObserver.observe(el, { attributes: true, attributeFilter: ["connected"] })

    // Already connected by the time Stimulus wired this target up (a subscription
    // that confirmed before this controller connected, or one that survived a Turbo
    // frame/stream re-render) is unambiguous good news — safe to reflect immediately.
    // The ABSENCE of the attribute at this same moment is deliberately NOT treated as
    // a failure here: a subscription that has simply not confirmed YET (the ordinary,
    // brief startup window) looks identical to one that dropped, and only an actually
    // OBSERVED transition (via the MutationObserver above) can tell those two apart.
    if (el.hasAttribute("connected")) this.#syncStreamConnection(el)
  }

  sourceTargetDisconnected() {
    this.#teardownStreamObserver()
  }

  #syncStreamConnection(el) {
    if (el.hasAttribute("connected")) {
      if (this.stateValue === "failed") this.stateValue = "ok"
      return
    }

    this.#nextFailedDetail = { reason: "stream-disconnected" }
    this.stateValue = "failed"
  }

  #teardownStreamObserver() {
    this.#streamObserver?.disconnect()
    this.#streamObserver = null
  }

  // --- rendering ----------------------------------------------------------------------

  #render() {
    const state = this.stateValue

    if (this.hasLoadingTarget) this.loadingTarget.hidden = state !== "loading"
    if (this.hasFailedTarget) this.failedTarget.hidden = state !== "failed"
    if (this.hasFailedClass) this.element.classList.toggle(this.failedClass, state === "failed")
  }

  #frame() {
    if (this.element instanceof HTMLElement && this.element.tagName === "TURBO-FRAME") return this.element

    return this.element.querySelector("turbo-frame")
  }
}
