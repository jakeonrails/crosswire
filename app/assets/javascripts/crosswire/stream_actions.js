/**
 * crosswire/stream_actions — `versioned_replace`, a Turbo Stream action that orders
 * broadcasts by a monotonic version instead of by arrival order.
 *
 * A sibling of `crosswire/index.js` and `crosswire/morph.js`, not a controller: this
 * registers into `Turbo.StreamActions`, Turbo's OWN extension point for stream
 * actions (the same table `replace`/`update`/`remove`/etc. live in), not into
 * Stimulus. Nothing here is a `data-controller`.
 *
 * The problem (Radan Skorić's pattern; research/notes/14-morphing-dossier.md ~line
 * 717): `broadcast_replace_to` delivers over Action Cable, which promises nothing
 * about ORDER. Two workers processing a queue can broadcast v2 then v1 for the same
 * record — a slow request finishing after a fast one that started later — and the
 * client, having no way to tell, applies whichever arrives last: the page is stuck
 * showing stale content until the next broadcast happens to be newer than whatever
 * it clobbered. `versioned_replace` fixes this the same way TCP fixes out-of-order
 * packets: every payload carries a version number, and a client that already has a
 * newer (or equal — redelivery is not the same bug as reordering) version silently
 * discards the stale one instead of applying it.
 *
 * RULE 0 — read before reaching for this. `broadcasts_refreshes` (Turbo 8) makes a
 * stale render structurally impossible: instead of pushing HTML, it pushes a signal
 * to re-fetch over the viewer's own connection, so there is nothing to reorder in
 * the first place. Reach for `broadcast_replace_to` (and, if reordering turns out to
 * be a real problem for it, `versioned_replace`) only after choosing it over
 * `broadcasts_refreshes` for a MEASURED load or latency reason — one broadcast
 * carrying the HTML directly is cheaper than one signal plus a round-trip fetch, but
 * only cash that in once profiling says the fetch is the actual cost, not by default.
 *
 * SELF-ECHO CAVEAT: `broadcast_replace_to` is not suppressed for the browser tab that
 * caused the change — the originating tab receives its own broadcast back over the
 * wire, same as every other subscriber. Ordinarily this can flicker a tab backward
 * (its own optimistic UI, or a page rendered a moment ago, replaced by a broadcast
 * describing the state it already has). Versioning neutralizes exactly this case:
 * once the originating page has rendered version N, its own echo of version N — or
 * anything older — is simply skipped, not reapplied.
 *
 * Usage — the version rides the PARTIAL's root element, the same partial renders both
 * the page and the broadcast, so there is exactly one place that ever writes it:
 *
 *   # app/views/widgets/_widget.html.erb
 *   <div id="<%= dom_id(widget) %>" <%= cw_attrs(crosswire_version_attrs(widget)) %>>
 *     ...
 *   </div>
 *
 *   # a model, alongside Turbo::Broadcastable
 *   include Crosswire::Streams::Versioned
 *   broadcasts_to :board # ordinary turbo-rails creates/destroys
 *   after_update_commit { broadcast_versioned_replace_to board, target: dom_id(self), partial: "widgets/widget", locals: { widget: self } }
 *
 *   // entrypoint, once, after Turbo is loaded
 *   import * as Turbo from "@hotwired/turbo"
 *   import { registerCrosswireStreamActions } from "crosswire/stream_actions"
 *   registerCrosswireStreamActions(Turbo)
 *
 * Attribute is namespaced `data-cw-version` — Radan's own write-up uses the bare
 * `data-version`, which a distributable gem cannot claim (any consumer, or another
 * library, may already have their own meaning for it).
 */

// Logged at most once per page load — many stream messages missing a version would
// otherwise spam the console with the same actionable warning on every delivery.
let warnedAboutMissingPayloadVersion = false

function readVersion(source) {
  const raw = source?.dataset?.cwVersion
  return parseInt(raw, 10)
}

// A stand-in `<turbo-stream>`-shaped object whose `targetElements` is narrowed to
// only the targets that passed the version check, while `templateContent` and
// `getAttribute` (which `Turbo.StreamActions.replace` reads `method` off of, to honor
// `method="morph"`) still delegate to the real element. `templateContent` is
// forwarded as a GETTER, not read once and cached, because `replace()` itself reads
// `this.templateContent` once per target when there is more than one — each read
// clones a fresh `DocumentFragment` from the `<template>` (see `StreamElement` in
// @hotwired/turbo), and a cached single fragment would be consumed (moved into the
// DOM) by the first target and be empty for the rest.
function scopedToTargets(stream, targetElements) {
  return {
    getAttribute: (name) => stream.getAttribute(name),
    get templateContent() {
      return stream.templateContent
    },
    targetElements
  }
}

/**
 * The `versioned_replace` Turbo Stream action. Registered as
 * `Turbo.StreamActions.versioned_replace` by `registerCrosswireStreamActions` below —
 * Turbo invokes every stream action as a method call on the `<turbo-stream>` element
 * itself (`newElement.performAction()`), so `this` here is that element, exactly as
 * for Turbo's own built-in `replace`/`update`/etc.
 *
 * Per target in `this.targetElements`:
 *
 *   - `payloadVersion` — `data-cw-version` on the broadcast payload's root element
 *     (read once; the payload is the same for every target in this message).
 *   - `pageVersion` — `data-cw-version` already on that target in the live DOM.
 *   - Applies (delegates to Turbo's own `replace`, so `method="morph"` still honors
 *     morphing — a versioned replace is not exempt from a targeted
 *     `turbo_stream.replace(target, method: :morph)`) when `payloadVersion >
 *     pageVersion`, STRICTLY — equal means this is a redelivery of a message this
 *     page already applied (Action Cable promises no dedup), not a genuine update,
 *     and is skipped the same as a stale one.
 *   - `pageVersion` `NaN` or absent applies unconditionally (fail OPEN toward
 *     freshness) — a target with no version yet has nothing to protect; refusing to
 *     ever apply to it would make the very first versioned replace a no-op.
 *   - `payloadVersion` `NaN` (the payload's root carries no, or a non-numeric,
 *     `data-cw-version` — almost always a partial that forgot
 *     `crosswire_version_attrs`) still applies, degrading to a plain replace, and
 *     warns once — silently dropping a real update because of a missing attribute
 *     would be a worse failure than an unordered one.
 *   - On skip, dispatches a bubbling `cw--stream:skipped` on the target, detail
 *     `{ action, payloadVersion, pageVersion }`, so a page that wants to know can
 *     listen for it (e.g. to flash "newer data available, ignoring an older update").
 *
 * @this {InstanceType<import("@hotwired/turbo").StreamElement>}
 */
export function versionedReplace() {
  const payloadRoot = this.templateContent?.firstElementChild
  const payloadVersion = readVersion(payloadRoot)

  if (Number.isNaN(payloadVersion) && !warnedAboutMissingPayloadVersion) {
    warnedAboutMissingPayloadVersion = true
    console.warn(
      "[crosswire] versioned_replace: the broadcast payload's root element has no (or a " +
        "non-numeric) data-cw-version — applying anyway, degraded to a plain replace. Render " +
        "crosswire_version_attrs(...) on the partial's root element so later deliveries can be " +
        "ordered against this one. (This warning is logged once per page load.)"
    )
  }

  const applying = []

  for (const target of this.targetElements) {
    const pageVersion = readVersion(target)
    const applies = Number.isNaN(payloadVersion) || Number.isNaN(pageVersion) || payloadVersion > pageVersion

    if (applies) {
      applying.push(target)
    } else {
      target.dispatchEvent(
        new CustomEvent("cw--stream:skipped", {
          bubbles: true,
          detail: { action: "versioned_replace", payloadVersion, pageVersion }
        })
      )
    }
  }

  if (applying.length === 0) return

  const streamActions = (typeof window !== "undefined" && window.Turbo && window.Turbo.StreamActions) || null
  if (!streamActions || typeof streamActions.replace !== "function") {
    throw new Error(
      "[crosswire] versioned_replace: Turbo.StreamActions.replace is not available on " +
        "window.Turbo — is @hotwired/turbo loaded before this action runs?"
    )
  }

  // Delegate to Turbo's OWN replace, scoped to only the targets that passed the
  // version check, so `method="morph"` keeps working exactly as it does for a plain
  // <turbo-stream action="replace"> — a versioned replace is free to morph too.
  streamActions.replace.call(scopedToTargets(this, applying))
}

/**
 * Register `versioned_replace` into `Turbo.StreamActions`. Not auto-installed by
 * `registerCrosswireControllers` (that registers Stimulus controllers; this is a
 * Turbo Stream action, an entirely different registry) — call it once, yourself,
 * after Turbo has loaded:
 *
 *   import * as Turbo from "@hotwired/turbo"
 *   import { registerCrosswireStreamActions } from "crosswire/stream_actions"
 *   registerCrosswireStreamActions(Turbo)
 *
 * Defaults to `window.Turbo` — the global Turbo itself sets as an import side effect
 * — so a page that already has Turbo loaded globally (the common case: an importmap
 * pinning `@hotwired/turbo` for Turbo Drive) can call this with no argument.
 *
 * @param {{ StreamActions: Record<string, Function> }} [Turbo] - defaults to
 *   `window.Turbo`.
 */
export function registerCrosswireStreamActions(Turbo = typeof window !== "undefined" ? window.Turbo : undefined) {
  if (!Turbo || !Turbo.StreamActions) {
    throw new Error(
      "[crosswire] registerCrosswireStreamActions() needs a Turbo object with StreamActions " +
        '— pass the @hotwired/turbo module (`import * as Turbo from "@hotwired/turbo"`) or call ' +
        "this after Turbo has set window.Turbo."
    )
  }

  Turbo.StreamActions.versioned_replace = versionedReplace
}
