/**
 * crosswire/morph — survive Turbo 8 morphing without a config DSL.
 *
 * A sibling of `crosswire/index.js`, not a controller: nothing here is registered
 * with Stimulus. It is plain DOM-event plumbing that a controller opts into.
 *
 * Turbo 8's morph replaces `document.body.replaceWith(newBody)` with Idiomorph
 * patching the live tree in place. That is what makes scroll position, focus, media
 * playback and custom-element state survive a refresh — but it also means every
 * attribute on the live element that is absent from (or different from) the server's
 * HTML is silently overwritten, `connect()` never re-runs for a surviving element, and
 * `<dialog>`'s `open` attribute can be stripped without ever calling `close()`. See
 * research/notes/14-morphing-dossier.md for the full source-verified account — this
 * module implements its "Design brief: what a `preserve` primitive would need to do"
 * (B1–B7).
 *
 * Two documented entry points:
 *
 *   - `usePreserve(controller)` — mix into a controller you own (see
 *     `crosswire/controllers/preserve_controller.js` for the markup-driven form aimed
 *     at controllers you do NOT own).
 *   - `installDialogMorphGuard(root)` — a standalone fix for turbo#1239, usable on any
 *     `<dialog>` whether or not it is driven by `cw--dialog`.
 *
 * Design constraints these two functions share, all load-bearing (see the dossier's
 * design brief for the evidence behind each):
 *
 *   - Opt-in only. Nothing here attaches a listener until a caller asks for it, so a
 *     page that never morphs pays nothing (design principle 5).
 *   - Every attribute name is derived from live values (`controller.identifier`), never
 *     a compile-time constant, because a controller can be registered under a
 *     different identifier than its class name suggests.
 *   - Nothing here mutates the DOM from inside a morph callback (B7) — idiomorph's own
 *     maintainer documents that as unsupported and corruption-prone (idiomorph#140,
 *     OpenProject#24603). Everything below only calls `preventDefault()` or reads
 *     attributes; the one exception, `.close()` inside `installDialogMorphGuard`, is
 *     the exact fix seanpdoyle posted against turbo#1239 and runs in response to a
 *     *cancelled* attribute mutation, not a structural one.
 */

// Module-private symbols so `usePreserve` can stash bookkeeping directly on the
// controller instance without risking a collision with Stimulus's own properties or a
// consumer's. Two symbols, not one: INSTALLED is cleared by teardown so a later
// `connect()` re-installs cleanly (B5 — "safe if connect() runs twice without an
// intervening disconnect()"); ORIGINAL_DISCONNECT is captured exactly once so repeated
// connect()/disconnect() cycles over the controller's lifetime wrap the SAME original
// method instead of nesting a new wrapper around the previous wrapper every time.
const INSTALLED = Symbol("crosswire:preserve:installed")
const ORIGINAL_DISCONNECT = Symbol("crosswire:preserve:original-disconnect")

// Stimulus's own dasherize (dist/core/string_helpers.js) — reproduced rather than
// imported so this module has zero runtime dependency on @hotwired/stimulus (it works
// identically for the markup-driven cw--preserve controller and for plain DOM code
// that never touches Stimulus at all). Named distinctly from a plain `dasherize`
// deliberately: bin/build_site.rb inlines this module into a single flat script scope
// alongside Stimulus's own (identically-named) internal helper, and two top-level
// `function dasherize` declarations in one scope is a page-breaking collision, not a
// harmless shadow.
function dasherizeValueName(value) {
  return String(value).replace(/([A-Z])/g, (_, char) => `-${char.toLowerCase()}`)
}

/**
 * The shared engine behind both `usePreserve` and `cw--preserve`. Not part of the
 * documented public API (see the two exports above) — exported anyway because both
 * consumers live in this package and a single implementation is the only way the
 * divergence check (B2) stays consistent between "a controller I own" and "an element I
 * don't own the controller for".
 *
 * Watches `element` for three Turbo morph events and does nothing else:
 *
 *   - `turbo:before-morph-attribute` — cancels the update/removal of a watched
 *     attribute, but ONLY if the attribute's current DOM value has diverged from the
 *     value recorded the last time this guard synced (B2). An attribute the caller
 *     never touched is left alone, so the server can keep updating it.
 *   - `turbo:before-morph-element` — B6 full-subtree opt-out when `preserveElement()`
 *     is true; otherwise B4, reporting `newElement === undefined` (an imminent removal)
 *     through `onRemoved`.
 *   - `turbo:morph-element` — coalesced per morph pass (B3): multiple bubbled events
 *     collapse into one microtask flush, which both re-syncs the divergence baseline
 *     and (if provided) invokes `onMorphed` exactly once.
 *
 * @param {Element} element - the element whose attributes/subtree this guards.
 * @param {object} [options]
 * @param {() => string[]} [options.attributeNames] - attribute names to protect,
 *   evaluated fresh on every check (never cached), so a value that changes at runtime
 *   (cw--preserve's `attributesValue`) is honoured immediately.
 * @param {() => boolean} [options.preserveElement] - B6: when true, the whole subtree
 *   is exempted from morphing, the same as `data-turbo-permanent` but scoped to morph
 *   passes only.
 * @param {(detail: {currentElement: Element, newElement: Element}) => void} [options.onMorphed]
 *   - called at most once per morph pass that touched this element's subtree.
 * @param {(detail: {currentElement: Element, newElement: undefined}) => void} [options.onRemoved]
 *   - B4: called when this exact element is about to be removed by the morph. Never
 *     called for an element relocated through idiomorph's pantry — Turbo dispatches
 *     nothing at all for those (see the dossier's Step 3); there is no honest way to
 *     detect that case without a MutationObserver, which is explicitly out of scope
 *     unless it becomes measurably necessary.
 * @returns {{ teardown: () => void }}
 */
export function createMorphGuard(element, options = {}) {
  const attributeNames = options.attributeNames || (() => [])
  const preserveElement = options.preserveElement || (() => false)
  const { onMorphed, onRemoved } = options

  // The B2 baseline: attribute name -> value recorded at the last sync point (guard
  // creation, i.e. connect(), or the flush after the most recent morph pass). `null`
  // is a legitimate recorded value (the attribute did not exist yet).
  const baseline = new Map()

  function syncBaseline() {
    baseline.clear()
    for (const name of attributeNames()) {
      baseline.set(name, element.getAttribute(name))
    }
  }

  function onBeforeMorphAttribute(event) {
    // The event bubbles (afcapel's callbacks dispatch it on the mutated element, and
    // that element can be a descendant), so a listener on `element` also hears its
    // children's attribute mutations. Only the root-level case is this guard's job —
    // per-element scoping. That is B1's mandatory guard.
    if (event.target !== element) return

    const { attributeName } = event.detail
    if (!attributeNames().includes(attributeName)) return

    // Never captured (the name was added to `attributeNames()` after the last sync,
    // e.g. cw--preserve's attributesValue changed at runtime): treat "now" as the
    // baseline, which trivially lets this first morph through — the safe default,
    // since we have no evidence the caller ever touched it.
    const known = baseline.has(attributeName) ? baseline.get(attributeName) : element.getAttribute(attributeName)
    const current = element.getAttribute(attributeName)

    // B2 — the core differentiator over a blanket block (W1/W2) and over
    // stimulus-durable-values (W11): cancel only when the live DOM has diverged from
    // the last known-good value, i.e. only when THIS element actually wrote it. If
    // nothing touched it since the last sync, the server wins.
    if (current !== known) event.preventDefault()
  }

  function onBeforeMorphElement(event) {
    if (event.target !== element) return

    if (preserveElement()) {
      // B6 — equivalent to data-turbo-permanent, but scoped to this morph pass only
      // (it does not leak into an ordinary Drive navigation the way the attribute
      // does).
      event.preventDefault()
      return
    }

    // B4 — `beforeNodeRemoved` is wired to `beforeNodeMorphed(node)` with a single
    // argument, so an imminent removal surfaces here as `newElement === undefined`,
    // not as a separate event. Surface it as its own named thing rather than leaving
    // callers to discover the undefined check by reading Turbo's source.
    if (event.detail.newElement === undefined && onRemoved) {
      onRemoved(event.detail)
    }
  }

  // B3 coalescing state. `turbo:morph-element` fires once per morphed descendant and
  // bubbles, so N events for one morph pass must collapse into exactly one flush.
  // Idiomorph's walk is fully synchronous, so a microtask boundary is sufficient — by
  // the time it runs, every morph-element event for this pass has already fired.
  let pendingDetail = null
  let flushScheduled = false

  function flush() {
    flushScheduled = false
    // Baselines refresh here, after the morph, rather than by patching Stimulus's
    // value setters (the stimulus-durable-values mistake, W11) — this only ever reads
    // the DOM, which is always the truth after a completed morph pass regardless of
    // whether individual attributes were cancelled above or allowed through.
    syncBaseline()

    const detail = pendingDetail
    pendingDetail = null
    if (onMorphed) onMorphed(detail)
  }

  function onMorphElement(event) {
    pendingDetail = event.detail
    if (flushScheduled) return
    flushScheduled = true
    queueMicrotask(flush)
  }

  element.addEventListener("turbo:before-morph-attribute", onBeforeMorphAttribute)
  element.addEventListener("turbo:before-morph-element", onBeforeMorphElement)
  element.addEventListener("turbo:morph-element", onMorphElement)

  syncBaseline()

  return {
    teardown() {
      element.removeEventListener("turbo:before-morph-attribute", onBeforeMorphAttribute)
      element.removeEventListener("turbo:before-morph-element", onBeforeMorphElement)
      element.removeEventListener("turbo:morph-element", onMorphElement)
    }
  }
}

/**
 * Mix morph survival into a Stimulus controller you own.
 *
 *   import { Controller } from "@hotwired/stimulus"
 *   import { usePreserve } from "crosswire/morph"
 *
 *   export default class extends Controller {
 *     static values = { open: Boolean }
 *
 *     // Values this controller owns; the server must not stomp them once this
 *     // controller has written them (B2 — only once it has actually written them).
 *     static preservedValues = ["open"]
 *
 *     // Arbitrary attributes this controller writes at runtime, e.g. via the Classes
 *     // API or by hand.
 *     static preservedAttributes = ["aria-expanded"]
 *
 *     // Opt into morphed() below. Off by default — most controllers correctly rely
 *     // on surviving untouched and need no reinitialisation hook at all.
 *     static reconnectOnMorph = true
 *
 *     // B6: true makes the WHOLE subtree immune to morphing, attributes and children
 *     // alike — the equivalent of data-turbo-permanent, scoped to morph passes only.
 *     static preserveElement = false
 *
 *     connect() { usePreserve(this) }
 *
 *     // Called at most once per morph pass that touched this controller's element or
 *     // a descendant of it (B3 coalescing) — never once per individual attribute or
 *     // child that changed.
 *     morphed({ newElement }) { }
 *
 *     // B4: this controller's own element is about to be removed by the morph.
 *     // Not called for an element relocated through idiomorph's pantry — see
 *     // `createMorphGuard`'s docstring for why that case is silent by design.
 *     removedByMorph({ currentElement }) { }
 *   }
 *
 * `preservedValues` entries are Stimulus value names (e.g. `"open"`), not attribute
 * names — the actual DOM attribute is derived at call time as
 * `data-${controller.identifier}-${dasherized name}-value`, using the LIVE identifier
 * rather than a name baked in at authoring time, because a controller can be
 * registered under a different identifier than the one it ships with.
 *
 * `usePreserve` wraps `disconnect()` the way stimulus-use libraries do (B5), so
 * teardown cannot be forgotten, and is idempotent: calling it twice on the same
 * instance without an intervening `disconnect()` — which Stimulus explicitly allows,
 * reusing controller instances on reconnection — is a no-op the second time.
 *
 * Zero-cost when morphing never happens on the page: this only ever attaches DOM
 * listeners for events Turbo dispatches during a morph, never a poll or an observer.
 *
 * @param {import("@hotwired/stimulus").Controller} controller
 * @returns {{ teardown: () => void }}
 */
export function usePreserve(controller) {
  if (controller[INSTALLED]) return controller[INSTALLED]

  const preservedValues = () => controller.constructor.preservedValues || []
  const preservedAttributes = () => controller.constructor.preservedAttributes || []

  const attributeNames = () => [
    ...preservedValues().map((name) => `data-${controller.identifier}-${dasherizeValueName(name)}-value`),
    ...preservedAttributes()
  ]

  const preserveElement = () => controller.constructor.preserveElement === true

  const wantsMorphed = () =>
    controller.constructor.reconnectOnMorph === true && typeof controller.morphed === "function"

  const guard = createMorphGuard(controller.element, {
    attributeNames,
    preserveElement,
    onMorphed: (detail) => {
      if (wantsMorphed()) controller.morphed(detail)
    },
    onRemoved: (detail) => {
      if (typeof controller.removedByMorph === "function") controller.removedByMorph(detail)
    }
  })

  if (!controller[ORIGINAL_DISCONNECT]) {
    const original = typeof controller.disconnect === "function" ? controller.disconnect.bind(controller) : () => {}
    controller[ORIGINAL_DISCONNECT] = original
  }

  controller.disconnect = () => {
    guard.teardown()
    controller[INSTALLED] = null
    controller[ORIGINAL_DISCONNECT]()
  }

  const api = { teardown: () => { guard.teardown(); controller[INSTALLED] = null } }
  controller[INSTALLED] = api
  return api
}

// One shared registry so calling `installDialogMorphGuard(root)` twice on the same
// root is a no-op rather than a second listener stacking a second `.close()` call —
// idempotent per the documented contract.
const installedRoots = new WeakMap()

/**
 * Standalone fix for turbo#1239 (open since 2024-04, reconfirmed 2026-06): morphing
 * removes `<dialog>`'s `open` attribute the same as any other attribute, and per the
 * HTML spec removing it that way does NOT call `close()`, does not fire `close`, and
 * does NOT release the top layer — so the rest of the document is left permanently
 * un-clickable while looking like the dialog is simply gone.
 *
 * This is seanpdoyle's fix from that issue thread, scoped to `root` instead of
 * installed globally: cancel the removal and call `.close()` explicitly, so the
 * dialog exits the top layer through the real API instead of losing its attribute out
 * from under it.
 *
 * NOT auto-installed by `registerCrosswireControllers` — a distributable component
 * library does not get to attach a document-wide listener a consumer never asked for.
 * `cw--dialog` installs the equivalent of this, scoped to its own element, on its own
 * (see that controller's docstring); reach for this function directly for any other
 * `<dialog>` on the page, including ones with no Stimulus controller at all:
 *
 *   import { installDialogMorphGuard } from "crosswire/morph"
 *   installDialogMorphGuard()   // whole document, once, e.g. from your entrypoint
 *
 * @param {Document | Element} [root] - defaults to `document`, i.e. every `<dialog>`
 *   on the page. Pass a narrower root to scope it.
 * @returns {() => void} an uninstall function.
 */
export function installDialogMorphGuard(root = document) {
  if (installedRoots.has(root)) return installedRoots.get(root)

  function onBeforeMorphAttribute(event) {
    const { target, detail } = event
    if (target instanceof HTMLDialogElement && detail.attributeName === "open" && detail.mutationType === "remove") {
      event.preventDefault()
      target.close()
    }
  }

  root.addEventListener("turbo:before-morph-attribute", onBeforeMorphAttribute)

  function uninstall() {
    root.removeEventListener("turbo:before-morph-attribute", onBeforeMorphAttribute)
    installedRoots.delete(root)
  }

  installedRoots.set(root, uninstall)
  return uninstall
}
