# 12 — Cross-framework cross-pollination & the honest case for Hotwire

> Compiled 2026-08-15. Sources fetched raw (`curl_chrome145 | html2text`) wherever code
> was the content, because summarizers strip code samples. Version claims were verified
> against package registries, published dists, and GitHub APIs — not recalled.

**Verified version facts used throughout this document:**

| Thing | Version | Evidence |
|---|---|---|
| `@hotwired/turbo` | **8.0.23** (2026-01-29) | actively released; v8.0.18→8.0.23 shipped 2025-09→2026-01 |
| `turbo-rails` | **2.0.23** | — |
| `@hotwired/stimulus` | **3.2.2** (2023-08-07) | **no release in 3 years** — see §Where Hotwire loses |
| Phoenix LiveView | **1.2.9** | hexdocs current |
| Laravel Livewire | **4.x** | livewire.laravel.com defaults to 4.x (not 3.x) |
| Alpine.js | **3.16.1** | npm |
| Unpoly | **3.14.3** | unpoly.com |
| htmx | **2.0.10** | htmx.org |

---

## Table of contents

1. [Ideas worth stealing (ranked)](#ideas-worth-stealing-ranked)
2. [Per-ecosystem notes](#per-ecosystem-notes)
   - [HTMX](#htmx)
   - [Unpoly](#unpoly)
   - [Phoenix LiveView](#phoenix-liveview)
   - [Laravel Livewire](#laravel-livewire)
   - [Alpine.js](#alpinejs)
   - [Datastar & newer hypermedia](#datastar--newer-hypermedia)
   - [Platform primitives that replace JS in 2026](#platform-primitives-that-replace-js-in-2026)
3. [Where Hotwire genuinely loses](#where-hotwire-genuinely-loses)
4. [The honest case for Hotwire](#the-honest-case-for-hotwire)
5. [Decision framework: Hotwire vs island vs SPA](#decision-framework-hotwire-vs-island-vs-spa)
6. [Escape hatches done cleanly](#escape-hatches-done-cleanly)
7. [Migration stories (both directions)](#migration-stories-both-directions)

---

## Accuracy guardrails (read before citing anything here)

The credibility of crosswire depends on never claiming a gap that doesn't exist. Three
claims that are commonly repeated and are **false**, verified against the Turbo 8.0.23
published dist:

1. **"Turbo has no link preloading / no hover prefetch."** False. Turbo 8 ships
   prefetch-on-hover **enabled by default**: `PREFETCH_DELAY = 100` (ms after
   `mouseenter`), `cacheTtl = 10 * 1000`, and `linkOptsOut()` only opts a link out when
   `data-turbo-prefetch="false"` — it is an *opt-out*, not an opt-in. It auto-skips
   non-safe links (`data-turbo-method` ≠ GET, `data-turbo-confirm`, `data-turbo-stream`,
   UJS attributes) and same-page links. `data-turbo-preload` additionally exists for
   eager cache warming. htmx's `preload` extension and Livewire's `wire:navigate.hover`
   are **parity, not gaps**.
2. **"Stimulus has no transitions / no debounce / no intersection observer."** False as
   stated. Stimulus *core* has none, but **stimulus-use** ships `useTransition`
   (returns `[enter, leave, toggleTransition]`), `useDebounce`, `useThrottle`,
   `useIntersection`, `useClickOutside`, `useHotkeys`, `useIdle`, `useVisibility`,
   `useResize`, and `usePreventMorph`. Always say "not in core; available via
   stimulus-use (third-party)" rather than "Hotwire has nothing".
3. **"Turbo can't protect third-party JS from morphing."** False. `turbo:before-morph-element`
   and `turbo:before-morph-attribute` are real, supported cancelation hooks.

**The complete Turbo 8.0.23 attribute surface** (extracted from the dist — use this to
check any "Hotwire has NONE" claim before making it):

```
data-turbo                data-turbo-action        data-turbo-confirm
data-turbo-eval           data-turbo-frame         data-turbo-method
data-turbo-permanent      data-turbo-prefetch      data-turbo-preload
data-turbo-preview        data-turbo-stream        data-turbo-submits-with
data-turbo-suppress-warning  data-turbo-temporary  data-turbo-track
data-turbo-visit-direction
```

**Complete `turbo:` event surface:** `before-cache`, `before-fetch-request`,
`before-fetch-response`, `before-frame-morph`, `before-frame-render`,
`before-morph-attribute`, `before-morph-element`, `before-prefetch`, `before-render`,
`before-stream-render`, `before-visit`, `click`, `fetch-request-error`, `frame-load`,
`frame-missing`, `frame-render`, `load`, `morph-element`, `morph`, `reload`, `render`,
`submit-end`, `submit-start`, `visit`.

Genuinely **absent from Turbo entirely**: per-element loading state, polling, dirty
tracking, offline awareness, server-driven field validation, fail-targets, transitions,
debounce/throttle, optimistic previews, request coordination/deduplication, relative
targeting (`closest`/`next`/`previous`).

---

## Ideas worth stealing (ranked)

Ranked by (value delivered) × (breadth of applicability) ÷ (cost to build). Each is a real
gap verified against the Turbo 8.0.23 attribute surface above — none of these is something
Turbo already does.

### 1. `data-loading` — automatic per-element loading state (from Livewire 4, refined past LiveView)

**The gap.** Turbo's only loading affordance is `data-turbo-submits-with` (form submit
buttons) plus `[busy]`/`[aria-busy]` on frames. Every "disable this button / fade this row /
show this spinner while the request is in flight" is hand-written. LiveView gives it as
automatic CSS classes; **Livewire 4 gives it as an automatic `data-loading` attribute**,
which is strictly better because it needs no framework CSS classes — plain CSS already
targets attributes.

**Port sketch.** One global listener, zero per-feature code:

```js
// app/javascript/loading_state.js
const mark = (el) => el?.setAttribute("data-loading", "")
const clear = (el) => el?.removeAttribute("data-loading")

// forms
addEventListener("turbo:submit-start", (e) => {
  mark(e.target)
  mark(e.detail.formSubmission?.submitter)
})
addEventListener("turbo:submit-end", (e) => {
  clear(e.target)
  clear(e.detail.formSubmission?.submitter)
})

// links + frames: turbo:click gives us the originating element
let pending = null
addEventListener("turbo:click", (e) => { pending = e.target; mark(pending) })
addEventListener("turbo:load",       () => { clear(pending); pending = null })
addEventListener("turbo:frame-load", () => { clear(pending); pending = null })

// lazy/eager frames mark themselves
addEventListener("turbo:before-fetch-request", (e) => {
  if (e.target.tagName === "TURBO-FRAME") mark(e.target)
})
addEventListener("turbo:frame-render", (e) => clear(e.target))
```

Then all of this works with no further JS, using Tailwind v4 variants exactly as Livewire does:

```erb
<%= button_to "Save", path, class: "data-loading:opacity-50" %>

<%= link_to "Report", path do %>
  <span class="in-data-loading:hidden">Report</span>
  <span class="not-in-data-loading:hidden">Loading…</span>
<% end %>

<tr class="has-data-loading:opacity-40"> … </tr>
```

**Why #1:** it is the single highest-frequency missing affordance, it applies to *every*
interactive element in *every* app, and the implementation is ~25 lines of global JS with no
per-component cost. Best value-to-effort ratio in this document by a wide margin.

### 2. `up-validate` — declarative server-driven field validation (from Unpoly)

**The gap.** Field-level validation against server rules (uniqueness, cross-field, business
logic) is universal in Rails apps and universally hand-rolled, usually without debounce,
without batching, and with races between validation and submit.

**The Unpoly contract worth copying wholesale:** `X-Up-Validate: email` header, server
validates *without persisting*, re-renders only the field's form group; one request in flight
per form; simultaneous changes batch into one request with multiple targets; ancestor targets
subsume descendants; **submitting aborts in-flight validation**.

**Port sketch** — Stimulus controller + a Rails concern:

```js
// app/javascript/controllers/validate_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 200 } }

  connect() { this.pending = new Set(); this.inFlight = false }

  queue({ target }) {
    if (!target.name) return
    this.pending.add(target.name)
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.flush(), this.delayValue)
  }

  async flush() {
    if (this.inFlight || this.pending.size === 0) return
    const fields = [...this.pending]; this.pending.clear()
    this.inFlight = true
    try {
      const res = await fetch(this.element.action, {
        method: "POST",
        body: new FormData(this.element),
        headers: { "X-Validate": fields.join(","), Accept: "text/vnd.turbo-stream.html" }
      })
      if (res.ok) Turbo.renderStreamMessage(await res.text())
    } finally {
      this.inFlight = false
      if (this.pending.size) this.flush()   // drain what arrived mid-flight
    }
  }

  // abort validation when the form actually submits
  submit() { clearTimeout(this.timer); this.pending.clear() }
}
```

```ruby
# app/controllers/concerns/validatable.rb
module Validatable
  extend ActiveSupport::Concern

  private

  def validating? = request.headers["X-Validate"].present?
  def validating_fields = request.headers["X-Validate"].to_s.split(",")

  def render_validation(record, prefix:)
    record.valid?
    render turbo_stream: validating_fields.map { |f|
      turbo_stream.replace("#{prefix}_#{f}_group",
        partial: "shared/field_group", locals: { record:, field: f, prefix: })
    }
  end
end
```

```erb
<%= form_with model: @user, data: {
      controller: "validate", action: "submit->validate#submit" } do |f| %>
  <div id="user_email_group">
    <%= f.email_field :email, data: { action: "blur->validate#queue" } %>
    <%= render "shared/errors", record: @user, field: :email %>
  </div>
<% end %>
```

**Note the deliberate deviation from Unpoly:** Unpoly targets `fieldset:has(#email)` via a
CSS selector; Turbo targets by DOM id, so the port uses a `_group` id convention instead.
That is the right Rails-native adaptation, not a shortcoming.

### 3. Optimistic previews with guaranteed revert (from Unpoly `up.preview`)

**The gap.** Turbo 8 morphing smooths *real* responses; there is no optimistic primitive.
Hand-rolled optimistic UI in Hotwire is fragile precisely on the paths people forget: request
aborted, server errored, server targeted something else.

**The idea to copy is the guarantee, not the API:** every mutation registers an undo, and the
undo runs **before** the real response renders — never after.

```js
// app/javascript/previews.js
const registry = new Map()
export const definePreview = (name, fn) => registry.set(name, fn)

class Preview {
  constructor(origin, params) { this.origin = origin; this.params = params; this.undos = [] }
  insert(ref, position, html) {
    const t = document.createElement("template"); t.innerHTML = html.trim()
    const node = t.content.firstElementChild
    ref.insertAdjacentElement(position, node)
    this.undos.push(() => node.remove()); return node
  }
  addClass(el, c) { el.classList.add(c); this.undos.push(() => el.classList.remove(c)) }
  hide(el) { const p = el.style.display; el.style.display = "none"
             this.undos.push(() => (el.style.display = p)) }
  undoAll() { this.undos.reverse().forEach(fn => fn()) }
}

export function runPreview(name, origin, params) {
  const fn = registry.get(name); if (!fn) return null
  const p = new Preview(origin, params); fn(p); return p
}
```

```js
// app/javascript/controllers/preview_controller.js
import { Controller } from "@hotwired/stimulus"
import { runPreview } from "previews"

export default class extends Controller {
  static values = { name: String }

  connect() {
    this.start   = () => { this.preview = runPreview(
      this.nameValue, this.element, new URLSearchParams(new FormData(this.element))) }
    // CRITICAL: revert before Turbo paints, not after — otherwise the optimistic
    // node and the real node both render for a frame.
    this.revert  = () => { this.preview?.undoAll(); this.preview = null }

    this.element.addEventListener("turbo:submit-start", this.start)
    document.addEventListener("turbo:before-render",    this.revert)
    document.addEventListener("turbo:before-stream-render", this.revert)
    this.element.addEventListener("turbo:submit-end",   this.revert) // error/abort fallback
  }

  disconnect() {
    document.removeEventListener("turbo:before-render", this.revert)
    document.removeEventListener("turbo:before-stream-render", this.revert)
  }
}
```

**Caveat to publish alongside it,** in Unpoly's own words: *"Optimistic rendering is a recent
feature in Unpoly, and is inherently difficult in a server-driven approach. Expect more
changes as we're looking for the best patterns."* Ship this as an advanced recipe with its
sharp edges labeled, not as a default.

### 4. Overlays that return a value (from Unpoly layers / `up-accept-location`)

**The gap.** Every Rails app has the "create a Company from inside the Contact form" flow, and
almost every one solves it badly — by redirecting to the parent page and re-rendering
everything, losing the user's in-progress form state.

The idea: a modal is a *sub-interaction* that **resolves with a value**, and the opener
decides what to do with it. Accept vs dismiss are distinct outcomes.

```js
// app/javascript/controllers/overlay_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { acceptLocation: String }
  static targets = ["frame", "dialog"]

  frameTargetConnected() { this.dialogTarget.showModal() }

  // when the frame navigates, check whether it landed on the "success" URL
  check() {
    const src = this.frameTarget.src
    if (!src || !this.hasAcceptLocationValue) return
    const re = new RegExp("^" +
      this.acceptLocationValue.replace("$id", "(?<id>[^/]+)") + "$")
    const m = new URL(src, location.origin).pathname.match(re)
    if (m) this.accept(m.groups)
  }

  accept(value) { this.dispatch("accepted", { detail: { value }, bubbles: true }); this.close() }
  dismiss(reason = ":button") {
    this.dispatch("dismissed", { detail: { reason }, bubbles: true }); this.close() }
  close() { this.dialogTarget.close(); this.element.remove() }
}
```

```erb
<div data-controller="overlay"
     data-overlay-accept-location-value="/companies/$id"
     data-action="turbo:frame-load->overlay#check
                  overlay:accepted->company-select#addOption">
  <dialog data-overlay-target="dialog">
    <turbo-frame id="modal" src="/companies/new" data-overlay-target="frame"></turbo-frame>
  </dialog>
</div>
```

Server side mirrors `up.layer.accept` with a plain redirect the frame can observe. Use the
now-Widely-available `<dialog>` element — the browser handles focus trap, Esc, and top layer.

### 5. `wire:dirty` — unsaved-changes tracking

**The gap.** Universal need (every edit form), universally hand-rolled, and the
`beforeunload` guard is nearly always forgotten or wrong.

```js
// app/javascript/controllers/dirty_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { warn: { type: Boolean, default: true } }

  connect() {
    this.initial = this.snapshot()
    this.onBeforeUnload = (e) => { if (this.dirty) { e.preventDefault(); e.returnValue = "" } }
    if (this.warnValue) addEventListener("beforeunload", this.onBeforeUnload)
    // also guard Turbo navigations, which beforeunload does NOT cover
    this.onVisit = (e) => {
      if (this.dirty && !confirm("You have unsaved changes. Leave anyway?")) e.preventDefault()
    }
    addEventListener("turbo:before-visit", this.onVisit)
  }

  disconnect() {
    removeEventListener("beforeunload", this.onBeforeUnload)
    removeEventListener("turbo:before-visit", this.onVisit)
  }

  snapshot() { return new URLSearchParams(new FormData(this.element)).toString() }
  get dirty() { return this.snapshot() !== this.initial }

  check() { this.element.toggleAttribute("data-dirty", this.dirty) }
  reset() { this.initial = this.snapshot(); this.check() }
}
```

```erb
<%= form_with model: @post, data: {
      controller: "dirty", action: "input->dirty#check turbo:submit-end->dirty#reset" } do |f| %>
  <span class="hidden [[data-dirty]_&]:inline">Unsaved changes…</span>
<% end %>
```

Note the Turbo-specific value-add: `beforeunload` does **not** fire on Turbo Drive visits, so
guarding `turbo:before-visit` is required — exactly the kind of Hotwire-specific detail a
recipe library should encode once.

### 6. `wire:offline` — connection-aware UI

**The gap.** Hotwire apps fail silently offline: the user clicks, nothing happens, no
feedback. Cheapest meaningful UX win in this list.

```js
// app/javascript/offline.js
const sync = () => document.documentElement.toggleAttribute("data-offline", !navigator.onLine)
addEventListener("online", sync); addEventListener("offline", sync); sync()
```

```erb
<div class="hidden [html[data-offline]_&]:block">You're offline — changes won't save.</div>
<%= f.submit "Save", class: "[html[data-offline]_&]:opacity-50", data: { disable_with: "…" } %>
```

Six lines. Consider pairing with `turbo:fetch-request-error` for the "online but the request
failed" case, which is distinct and equally silent today.

### 7. Declarative loading/failed/empty states for lazy frames (from LiveView `AsyncResult`)

**The gap — and it is a real one.** A lazy `<turbo-frame src>` gives you a loading state (put
placeholder content inside the frame) but has **no failure state**. If the request 500s, the
frame just sits there showing the placeholder forever. LiveView's `<.async_result>` makes
loading/failed/ok a declarative tri-state.

```js
// app/javascript/controllers/async_frame_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loading", "failed", "empty"]

  connect() {
    this.element.addEventListener("turbo:fetch-request-error", () => this.fail())
    this.element.addEventListener("turbo:frame-missing", (e) => { e.preventDefault(); this.fail() })
    this.element.addEventListener("turbo:before-fetch-response", (e) => {
      if (!e.detail.fetchResponse.succeeded) this.fail()
    })
  }

  fail() {
    this.loadingTarget?.setAttribute("hidden", "")
    this.failedTarget?.removeAttribute("hidden")
  }

  retry() { this.failedTarget.setAttribute("hidden", ""); this.element.reload() }
}
```

```erb
<turbo-frame id="revenue" src={revenue_path} loading="lazy"
             data-controller="async-frame">
  <div data-async-frame-target="loading" class="animate-pulse">…</div>
  <div data-async-frame-target="failed" hidden>
    Couldn't load revenue. <button data-action="async-frame#retry">Retry</button>
  </div>
</turbo-frame>
```

### 8. `up-poll` / `wire:poll` — a polling primitive with the right defaults

**The gap.** Turbo has no polling at all. Rails' idiomatic answer is ActionCable push, which
is better *when available* — but third-party data, rate-limited APIs, and apps without
ActionCable have no story.

The value is in the defaults nobody hand-codes: pause when the tab is hidden, pause when
covered by a modal, refresh immediately on becoming visible again, and skip error responses.

```js
// app/javascript/controllers/poll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { interval: { type: Number, default: 30000 } }

  connect() {
    this.tick = this.tick.bind(this)
    this.onVisible = () => { if (!document.hidden) this.reload() }
    document.addEventListener("visibilitychange", this.onVisible)
    this.schedule()
  }
  disconnect() {
    clearTimeout(this.timer)
    document.removeEventListener("visibilitychange", this.onVisible)
  }

  schedule() { this.timer = setTimeout(this.tick, this.intervalValue) }
  async tick() {
    if (document.hidden || this.element.closest("dialog[open]")) return this.schedule()
    try { await this.element.reload() } catch {}
    this.schedule()
  }
  reload() { clearTimeout(this.timer); this.tick() }
}
```

### 9. `hx-sync` — request coordination and de-duplication

**The gap.** Nothing in Turbo prevents a double-click firing two requests, or a debounced
search racing its own earlier response, or a validation request racing a submit.

Model it on htmx's vocabulary — `drop` (ignore while busy), `abort` (cancel the old), `queue`
(run after) — keyed by a shared group name so unrelated elements don't interfere:

```js
// app/javascript/controllers/sync_controller.js
import { Controller } from "@hotwired/stimulus"
const groups = new Map()   // group -> { controller, queued }

export default class extends Controller {
  static values = { group: String, strategy: { type: String, default: "drop" } }

  guard(event) {
    const active = groups.get(this.groupValue)
    if (!active) return
    if (this.strategyValue === "drop")  { event.preventDefault(); return }
    if (this.strategyValue === "abort") { active.controller.abort() }
  }
}
```

Wire via `turbo:before-fetch-request` (which is cancelable with `preventDefault()`) rather
than wrapping fetch. **Honest note:** a complete port is harder than it looks because Turbo
owns its own `AbortController`s and doesn't expose them as public API — treat full
`hx-sync` parity as aspirational and ship `drop` (double-submit protection) first, which
covers most real bugs. LiveView gets this free: *"LiveView ignores clicks on elements that are
currently awaiting an acknowledgement from the server."*

### 10. `up-hungry` — receiver-driven fragments (badge counters that never go stale)

**The gap.** Turbo Streams are sender-driven: every controller action that could change the
unread count must remember to append a stream for it. Miss one and the badge silently goes
stale. `up-hungry` inverts it — the element declares "update me whenever I appear."

**The honest port is server-side**, because Turbo Stream responses only contain what the
server chose to send, so there is nothing for a client-side scanner to find:

```ruby
# app/controllers/concerns/hungry_fragments.rb
module HungryFragments
  extend ActiveSupport::Concern

  class_methods do
    def hungry(dom_id, partial:, locals: -> { {} })
      (@hungry ||= []) << { dom_id:, partial:, locals: }
    end
    def hungry_fragments = @hungry || []
  end

  included { after_action :append_hungry_fragments }

  private

  def append_hungry_fragments
    return unless response.media_type == Mime[:turbo_stream].to_s
    extra = self.class.hungry_fragments.map do |h|
      view_context.turbo_stream.replace(h[:dom_id],
        partial: h[:partial], locals: instance_exec(&h[:locals]))
    end
    response.body += extra.join
  end
end
```

```ruby
class ApplicationController < ActionController::Base
  include HungryFragments
  hungry "unread-count", partial: "shared/unread_count",
         locals: -> { { count: current_user&.unread_count } }
end
```

**Limitations to state plainly:** this only covers Turbo Stream responses, not Turbo Drive
full-page visits (those re-render the layout anyway, so the counter is fresh regardless), and
it costs a render per request — so scope it to genuinely cheap partials.

### Explicitly NOT worth stealing

| Idea | Why not |
|---|---|
| htmx `preload` / `wire:navigate.hover` | **Turbo 8 already does hover prefetch by default.** |
| `hx-boost` | Turbo Drive's default-on interception is the same thing, inverted and better. |
| SSE/WS extensions | `turbo_stream_from` + `broadcasts_to` is more integrated than either. |
| htmx OOB swaps / `multi-swap` | Turbo Streams are natively multi-target. |
| `idiomorph` extension | Turbo 8 ships idiomorph with *more* integration points. |
| Alpine `x-transition` / `useTransition` | **CSS `@starting-style` + `transition-behavior: allow-discrete` (both Baseline 2024) do this with zero JS.** |
| Alpine Anchor plugin / Floating UI | CSS anchor positioning reached **Baseline 2026**. |
| `up.compiler` | Stimulus is arguably better structured (declarative, formal values/targets, named lifecycle). |
| Livewire `@island` | This is `turbo_frame_tag ..., loading: :lazy`. Turbo got there first. |
| Datastar signals wholesale | Interesting, but adopting it means replacing Turbo+Stimulus. Steal `data-indicator` (→ idea #1) and let CSS `:has()` handle the rest. |

---

## Per-ecosystem notes

### HTMX

htmx 2.0.10. Read: `htmx.org/docs/`, `/reference/`, ~27 attribute pages, the essays, the
*Hypermedia Systems* book, and the extension set.

**The architectural difference that generates most of the gaps:** htmx puts a verb on
*any element* (`<button hx-put="/messages">`) and lets that element name *where* the
response goes (`hx-target`) and *how* it lands (`hx-swap`). Turbo instead binds
navigation to links/forms and resolves destination by *frame id* or by the server
declaring targets in a Turbo Stream. Turbo's model is more Rails-idiomatic and needs less
markup for the common case; htmx's is more composable at the edges.

#### Where Turbo already wins (don't port these)

| htmx feature | Why Turbo is fine or better |
|---|---|
| `hx-boost` | Inverted default — Turbo Drive intercepts all same-origin links/forms with no attribute. Opt out with `data-turbo="false"`. |
| `hx-swap-oob` | Turbo Streams are *natively* multi-target: `render turbo_stream: [replace(...), update(...), remove(...)]`. htmx's OOB is a bolt-on to a single-target model. |
| SSE / WS extensions | Turbo ships ActionCable-backed streaming first-class (`turbo_stream_from`, `broadcasts_to`, `broadcasts_refreshes`) wired into ActiveRecord callbacks. No extension needed. |
| `idiomorph` extension | Turbo 8 *ships* idiomorph, with more integration points: page refresh, per-frame `refresh="morph"`, per-stream `method="morph"`, and broadcast-level morph. |
| `head-support` extension | Turbo Drive always merges `<head>` on visits; `data-turbo-track="reload"` forces reload on asset change. |
| `preload` extension | **Turbo 8 has hover prefetch on by default.** See guardrails above. |
| Progress bar | Turbo ships `.turbo-progress-bar` automatically for visits >500ms. htmx has no global equivalent. |
| `hx-select` (common case) | A `<turbo-frame>` already extracts the matching frame from a full-page response. |

#### Real gaps

| htmx primitive | Hotwire status |
|---|---|
| `hx-sync` (`drop`/`abort`/`replace`/`queue first\|last\|all`) | **NONE.** No declarative request coordination anywhere in Turbo. |
| `response-targets` ext (`hx-target-404`, `hx-target-5*`, `hx-target-error`, wildcard `404→40*→4*→*`) | **NONE.** Turbo re-renders a failed response into the *same* target. Can't route 404 and 500 to different regions. |
| `hx-target` relative selectors (`closest tr`, `next`, `previous`, `find`, `this`) | **NONE.** Turbo targets by frame id only. Sharp gap for row-scoped inline edit unless every row gets its own frame. |
| `hx-vals` / `hx-headers` / `hx-include` / `hx-params` | **NONE declarative.** Workaround: hidden fields, or mutate `event.detail.fetchOptions` in `turbo:before-fetch-request`. |
| `hx-prompt` (+ `HX-Prompt` header) | **NONE.** `data-turbo-confirm` exists; there is no `data-turbo-prompt`. |
| `HX-Trigger` / `-After-Settle` / `-After-Swap` response headers | **NONE as headers.** Closest: register a custom `StreamActions.dispatch` and emit a `<turbo-stream action="dispatch">`. |
| `HX-Retarget` / `HX-Reswap` / `HX-Reselect` | **NONE.** Server can't override target/strategy at response time for a frame navigation. |
| `loading-states` ext (`data-loading-class`, `-disable`, `-delay`, `-target`, `-path`) | **NONE.** Only `data-turbo-submits-with` (form submit button text) and frame `[busy]`/`[aria-busy]`. |
| `htmx-swapping` / `htmx-settling` lifecycle classes | **NONE.** Turbo has no settle phase; only events. |
| `hx-swap` modifiers `swap:<t>`, `settle:<t>`, `focus-scroll`, `show:#el:top` | **NONE.** |
| `textContent` swap | **NONE.** All stream actions parse as HTML. |
| `path-deps` ext | **NONE.** Nearest is a manual ActionCable broadcast. |
| `hx-history-elt` | **NONE.** Turbo always snapshots `<body>`. |
| Per-swap View Transitions (`transition:true`) | **Partial.** Turbo's is page/frame-wide via `<meta name="view-transition">`; no per-element opt-in. |
| `hx-disabled-elt` (arbitrary elements) | **Partial.** Turbo auto-disables the submitter only. |

#### Philosophy worth using (exact quotes)

**Locality of Behaviour** — <https://htmx.org/essays/locality-of-behaviour/>
> "The behaviour of a unit of code should be as obvious as possible by looking only at that unit of code."

Gross is honest that it *conflicts* with DRY and Separation of Concerns:
> "SoC is, however, in conflict with LoB. By tweaking a CSS file the look and, to an extent, behaviour of an element can change dramatically... there is still 'spooky action at a distance' going on."

This is the sharpest available argument *against* Stimulus's separate-controller-file
convention, and crosswire should engage with it rather than dodge it.

**HDA definition** — <https://htmx.org/essays/hypermedia-driven-applications/>
> "thesis: MPA... antithesis: SPA... synthesis: HDA - hypermedia-driven application"

Notably, **htmx's own author lists `hotwired.dev` as an HDA library** alongside htmx,
Unpoly, Twinspark and Hyperview. Useful citation: the htmx camp treats Hotwire as playing
the same game, not as a competitor genre.

**Why htmx has no build step** — <https://htmx.org/essays/no-build-step/> (Alexander Petros)
> "The best reason to write a library in plain JavaScript is that it lasts forever... JavaScript from 1999 that ran in Netscape Navigator will run unaltered, alongside modern code, in Google Chrome downloaded yesterday."

This is the ready-made argument that Stimulus's freeze is a *feature*. Crosswire should
use it — but should not pretend it settles the question (see §Where Hotwire loses).

**Complexity Budget** — <https://htmx.org/essays/complexity-budget/>
> "An explicit or implicit allocation of complexity across the entire application."

**Hypermedia-friendly scripting** — <https://htmx.org/essays/hypermedia-friendly-scripting/>
> "hypermedia-friendly scripting should avoid the use of `fetch()` and `XMLHttpRequest` unless the responses from the server use a hypermedia of some sort (e.g. HTML), rather than a data API format (e.g. plain JSON)."

And the islands principle, which is exactly crosswire's escape-hatch doctrine:
> "Deniz Akşimşek has made the observation that it is typically easier to embed non-hypermedia islands within a larger Hypermedia-Driven Application, rather than vice-versa."

**Gross on when NOT to use hypermedia** — <https://htmx.org/essays/when-to-use-hypermedia/>.
This is the single most valuable essay for crosswire's credibility, because the author of
the competing framework names the losing cases himself:
> "If your UI state is updated extremely frequently... A good example is an online game that needs to capture mouse movements. Putting a hypermedia network request in-between a mouse move and a UI update will not work well."

> "If your UI has many, dynamic interdependencies... A good example of this is something like a spreadsheet: a user can enter an arbitrary function into a cell and introduce all sorts of dependencies on the screen, on the fly."

> "If you require offline functionality... then the hypermedia approach is not going to be an acceptable one."

> "Two famous examples of web applications that would not be amenable to a hypermedia approach are Google Sheets and Google Maps."

And the sociological one, which crosswire should quote verbatim in its decision framework:
> "If your team is not on board... it is a real phenomenon and should be borne in mind with humility... It may be better to adopt hypermedia around the edges, perhaps for internal tools first."

**The JSON-API split** — *Hypermedia Systems*, <https://hypermedia.systems/json-data-apis/>.
The book explicitly rejects Rails-style `respond_to` content negotiation on shared routes:
> "trying to pound them into the same set of URLs ends up creating a lot of tension in the application code."

Its stance is two separate route namespaces (app API in HTML, data API in JSON), which is
a real, actionable disagreement with standard Rails teaching. Worth surfacing.

---

### Unpoly

Unpoly 3.14.3. This is the richest source of portable ideas in the entire survey,
especially for **forms** and **overlays**. Unpoly has solved, declaratively and with
documented race-condition semantics, several problems that every Hotwire app hand-rolls
badly.

#### 1. `up-validate` — server-driven field-level validation (the #1 idea in this document)

```html
<input type="text" id="email" name="email" up-validate>
<input type="password" id="password" name="password" up-validate>
```

Wire protocol — this is the part to copy verbatim:

```
POST /users HTTP/1.1
X-Up-Validate: email
X-Up-Target: fieldset:has(#email)
```

The server validates **without persisting** and re-renders just the field's form group.
Default target is the closest form group, not the whole form. Unpoly always treats a
validation response as successful **regardless of HTTP status**.

Rails side (`unpoly-rails`):

```ruby
def create
  @user = User.new(user_params)
  if up.validate?
    @user.valid?          # validate only, don't save
    render 'form'
  elsif @user.save
    sign_in @user
  else
    render 'form', status: :bad_request
  end
end
```

Documented guarantees Hotwire gives you none of:
- only one validation request in flight per form; changes queue
- multiple fields changing near-simultaneously **batch into a single request with multiple targets**
- if one target is an ancestor of another, only the ancestor is requested
- submitting the form **aborts** in-flight validation

Options: `up-watch-event="input"`, `up-watch-delay="100"`, `up-validate-url="/validate_email"`,
explicit multi-target `up-validate=".email-errors, .base-errors"`.

**Hotwire status: NONE.** No attribute, no header convention, no batching, no abort-on-submit.

#### 2. `up-hungry` — receiver-driven fragments (Turbo Streams, inverted)

```html
<div class="unread-messages" up-hungry>You have no unread messages</div>
```

Any response containing a matching element updates it, automatically, without any link or
form naming it as a target. Layer-scoped by default (`up-if-layer="subtree"|"any"`).
Conflict rules are documented: explicit target beats hungry; outermost hungry wins;
nearest layer wins.

**This is the exact inverse of Turbo Streams.** Turbo Streams are *sender-driven* — every
controller action must remember `turbo_stream.replace("unread-count", ...)`. `up-hungry` is
*receiver-driven* — the element declares "update me whenever I appear," once, forever.
That eliminates a whole bug class ("I forgot to update the badge in this one action").

**Hotwire status: NONE.** Honest caveat on porting: a faithful client-side port fights
Turbo (stream responses only contain what the server chose to send, so there's nothing to
scan). The realistic Rails port is a server-side registry that auto-appends OOB streams —
which centralizes the bookkeeping but isn't a pure client declaration.

#### 3. Layers / overlays with context, accept/dismiss, and close conditions

Unpoly's most sophisticated idea, with no Hotwire analogue at all.

```html
<a href="/companies/new"
   up-layer="new"
   up-accept-location="/companies/$id"
   up-on-accepted="up.reload('.company-list')">New company</a>
```

Modes: `modal`, `drawer`, `popup`, `cover`; plus `up-layer="swap"` and `"shatter"`.

Two distinct close *intents*, each carrying a value: `up-accept` (success, with a value)
and `up-dismiss` (cancel, with a reason — `":key"`, `":outside"`, `":button"`).

Close conditions decouple the overlay's content from knowing it's in an overlay:
`up-accept-location="/companies/$id"` (URL pattern capture), `up-accept-event="user:created"`,
`up-accept-fragment=".user-profile"`, plus `up-dismiss-*` mirrors.

The canonical **subinteraction** — open "new customer" from a form, have it close and
populate the parent select:

```html
<select name="company">...</select>
<a href="/companies/new" up-layer="new"
   up-accept-location="/companies/$id"
   up-on-accepted="up.validate('select', { params: { company: value.id } })">New company</a>
```

Server side:

```ruby
if up.layer.overlay?
  up.layer.accept(@note.id)   # sends X-Up-Accept-Layer
  head :no_content
else
  redirect_to @note
end
```

Plus **layer context** — a per-overlay JSON state bag readable and writable from *both*
client (`up.context.lives++`) and server (`up.context[:project]`), the only mechanism that
is layer-scoped rather than tab- or domain-scoped.

**Hotwire status: NONE.** Rails modal patterns give you "show a form in an overlay," full
stop — no accept/dismiss vocabulary, no result-value propagation, no per-layer context.
Every Rails app reinvents this, usually by redirecting to the parent page and reloading the
whole thing instead of staying in the interaction.

#### 4. Previews / optimistic rendering (`up.preview`, `up-placeholder`)

```js
up.preview('add-task', function(preview) {
  let form = preview.origin.closest('form')
  let text = preview.params.get('text')
  preview.insert(form, 'afterend', `<div class="task">${up.util.escapeHTML(text)}</div>`)
  form.reset()
})
```

```html
<form up-target="#tasks" up-preview="add-task">
```

The `up.Preview` object exposes `insert`, `addClass`, `removeClass`, `setAttrs`, `setStyle`,
`swapContent`, `hide`, `show`, `openLayer`, `showPlaceholder`, `undo(fn)`, and getters
`origin`, `target`, `fragment`, `layer`, `request`, **`params`** (the submitted form data),
`renderOptions`, `revalidating`, `ended`.

The critical guarantee: a preview ends and **all changes revert** when the server responds,
errors, the network fails, the request is aborted, *or the server targets a different
fragment than expected* — and the revert happens **before** the real response is processed,
so there's no flash of inconsistent state.

Simpler sibling for skeletons: `up-placeholder="<p>Loading…</p>"` or
`up-placeholder="#loading-template { size: 'xl' }"`. Previews are **not** shown for cache
hits (avoids flash-then-revert); `up-revalidate-preview` covers revalidation specifically.

**Hotwire status: NONE.** Turbo 8 morphing smooths *real* responses; there is no
optimistic primitive. Any optimistic UI in Hotwire today is hand-rolled and fragile around
abort/error paths.

**Honest caveat, from Unpoly's own docs:** "Optimistic rendering is a recent feature in
Unpoly, and is inherently difficult in a server-driven approach. Expect more changes as
we're looking for the best patterns." Treat this as a good direction, not a finished spec.

#### 5. `up-watch` / `up-autosubmit` / dependent fields

```html
<input name="query" up-watch="console.log('New value', value)">
<input type="search" name="query" up-autosubmit>
```

Shared watch options across watch/validate/autosubmit: `up-watch-event`, `up-watch-delay`,
`up-watch-disable`, `up-watch-preview`, `up-watch-placeholder`. Async callbacks are
serialized — a change mid-flight re-runs with latest values after the current settles.

Dependent fields come in two flavors — server-rendered (reuses `up-validate`):

```html
<select name="continent" up-validate="#country">...</select>
<select name="country"   up-validate="#price">...</select>
<output id="price">23 €</output>
```

…and pure client-side (`up-switch`, no round trip):

```html
<select name="level" up-switch=".level-dependent">...</select>
<div class="level-dependent" up-show-for="beginner">only for beginners</div>
<div class="level-dependent" up-hide-for="beginner">hidden for beginners</div>
```

with pseudo-values `:blank`, `:present`, `:checked`, `:unchecked` and
`up-enable-for`/`up-disable-for`. **Hotwire status: NONE declarative** (everyone hand-rolls
a toggle controller; the value here is the standardized vocabulary more than the difficulty).

#### 6. `up-poll`

```html
<div id="score" up-poll up-interval="10000" up-if-layer="front">Score: 1400</div>
```

`up-if-layer='front'` pauses polling while covered by an overlay. Also `up-method`,
`up-headers`, `up-params`, `up-fail` (skip error responses by default), `up-keep-data`.

**Hotwire status: NONE.** Turbo has zero polling primitive. Rails' idiomatic answer is
push (ActionCable + `broadcasts_to`), which is architecturally better *when you have a
websocket* — but for third-party or rate-limited data, or apps without ActionCable, you're
on your own.

#### 7. `up-fail-target` — different destinations for success vs failure

```html
<form up-target=".content" up-fail-target="form"
      up-scroll="auto" up-fail-scroll=".errors">
```

**Any** option is `fail`-prefixable: target, scroll, history, layer, context, plus
`onRendered`/`onFailRendered`. The 2xx=success convention matches Rails/Turbo, but Unpoly
makes it *configurable* (`up.network.config.fail`, `up-fail=false`).

**Hotwire status: NONE, and the port is genuinely awkward** — a frame-scoped form always
renders its response back into the frame it came from. Taking over via
`turbo:before-fetch-response` + `preventDefault()` means re-implementing Turbo's rendering.
This is the one item where Turbo's architecture actively fights the port.

#### 8. Others (lower value)

- **`up-nav` / `.up-current`** — automatic active-link marking, reactive to any navigation.
  Rails' `current_page?` covers ~80% server-side and is simpler; Unpoly wins only when the
  nav persists across frame updates.
- **`up-keep`** — like `data-turbo-permanent` but with `same-html` / `same-data` granularity
  and an `up-on-keep` veto callback. Turbo 8 morphing already closed most of this gap.
- **Caching + revalidation** — 15s freshness, 90min eviction, 70-response cache, automatic
  revalidate-on-expired for *any* fragment update, `Vary`-header cache partitioning, and
  server-driven `up.cache.expire('/notes/*')` / `evict`. Turbo Drive does the same trick for
  full-page visits only, with no TTL config, no partitioning, no server eviction API.
- **`up.compiler`** — Unpoly's Stimulus analogue. Has `{ batch: true }` (one call for all
  matches) and `{ priority: N }` ordering that Stimulus lacks. **But this is the one area
  where Hotwire is arguably better structured** (declarative `data-controller`, formal
  values/targets API, named lifecycle). No port needed — don't let "Unpoly has an X for
  everything" push you to replace something that works.

#### Where Unpoly is worse / where ideas don't port

- **Non-Rails-native protocol.** Everything rides on `X-Up-*` headers translated by a gem.
  Turbo's conventions (422, `turbo_stream.*`, frame ids) are already idiomatic Rails.
  Porting means inventing your own vocabulary — no gem does this for Turbo today.
- **Solo-maintainer-led** (Henning Koch), far smaller community than Hotwire's, no
  Basecamp-scale production forcing function.
- **All-or-nothing.** Unpoly's power comes from a large, deeply cross-referencing attribute
  vocabulary. Cherry-picking ideas (what this document proposes) is the realistic path for
  a Hotwire shop; adopting Unpoly is a framework swap.
- **No native-app story.** Hotwire Native has no Unpoly counterpart.

---

### Phoenix LiveView

LiveView 1.2.9. This is where Hotwire's real gaps are most visible, because LiveView gives
declaratively, in markup, what Hotwire makes you write a controller for. Reported straight.

#### 1. Loading states as automatic CSS classes — zero JS

Every element that pushes an event gets a `-loading` class automatically:
`phx-click-loading`, `phx-change-loading`, `phx-submit-loading`, `phx-focus-loading`,
`phx-blur-loading`, `phx-keydown-loading`, `phx-keyup-loading`.

> "The CSS loading classes are maintained until an acknowledgement is received on the client for the pushed event. If the element is triggered several times, the loading state is removed only when all events are resolved."

```css
.phx-click-loading.opaque-on-click { opacity: 50%; }
```

With Tailwind's `addVariant`: `<button phx-click="clicked" class="phx-click-loading:opacity-50">`.
Redirect the loading state to a *different* element: `JS.push("delete", loading: "#post-row-13")`.

**Hotwire: NONE.** `data-turbo-submits-with` covers form submit buttons only.

#### 2. JS commands — declarative client behavior, DOM-patch aware

`JS.push`, `dispatch`, `toggle`, `show`, `hide`, `add_class`, `remove_class`, `toggle_class`,
`transition`, `focus`, `focus_first`, `push_focus`, `pop_focus`, `navigate`, `patch`, `exec`,
`set_attribute`, `remove_attribute`, `toggle_attribute`, `ignore_attributes`, `concat`.

```elixir
<button phx-click={JS.push("modal-closed") |> JS.remove_class("show", to: "#modal", transition: "fade-out")}>
```

Scoped selectors `{:inner, ".menu"}` / `{:closest, "sel"}`, composable, extractable:

```elixir
def hide_modal(js \\ %JS{}) do
  js |> JS.hide(transition: "fade-out", to: "#modal")
     |> JS.hide(transition: "fade-out-scale", to: "#modal-content")
end
```

The key property:
> "JS commands are DOM-patch aware, so operations applied by the JS APIs will stick to elements across patches from the server."

Turbo morphing has no equivalent guarantee — client-applied classes can be reverted by a morph.

**Hotwire: NONE.** Every one of these is a Stimulus controller.

#### 3. `phx-debounce` / `phx-throttle` as attributes

`phx-debounce="2000"`, `phx-debounce="blur"`, `phx-throttle="1000"` (default 300ms). With
non-obvious correct semantics baked in: submit/change resets sibling timers; keydown is
throttled only for key *repeats*, so distinct keypresses aren't swallowed.

**Hotwire: not in core.** stimulus-use has `useDebounce`/`useThrottle`; the subtle
form-reset and key-repeat semantics are yours to rediscover.

#### 4. `phx-viewport-top` / `phx-viewport-bottom` — bidirectional virtualized infinite scroll

Combined with `stream(:posts, posts, at: at, limit: per_page * 3)`, ~15 lines of markup gives
a fully virtualized bidirectional infinite list that *trims the DOM*, plus an `_overran`
param for when the user grabs the scrollbar and jumps.

**Hotwire: partial.** Lazy frames + a pagination link, or an IntersectionObserver controller.
No virtualization, no DOM trimming, no bidirectional support, no overrun signal.

#### 5. Async assigns with a declarative tri-state

```elixir
|> assign_async(:org, fn -> {:ok, %{org: fetch_org!(slug)}} end)
```
```heex
<.async_result :let={org} assign={@org}>
  <:loading>Loading organization...</:loading>
  <:failed :let={_failure}>there was an error</:failed>
  {org.name}
</.async_result>
```

Plus `start_async/3` + `handle_async/3` + `AsyncResult` for lower-level control, with
process isolation and exit catching.

**Hotwire: partial, and the missing third of it matters.** A lazy Turbo Frame gives you
loading. There is **no declarative failed state** — a frame whose request 500s just sits
there. Every Hotwire app needs an error story for lazy frames and none is provided.

#### 6. Form recovery, focus preservation, double-submit protection

- `phx-auto-recover="recover_wizard"` (or `"ignore"`) — re-submits params on reconnect so
  stateful wizards rebuild.
- > "The JavaScript client is always the source of truth for current input values. For any given input with focus, LiveView will never overwrite the input's current value." Opt out per-element with `phx-patch-focused`.
- On submit: inputs → readonly, submit buttons disabled, form gets `phx-submit-loading`; on
  completion "the last input with focus is restored".
- > "LiveView ignores clicks on elements that are currently awaiting an acknowledgement from the server."
  Automatic double-submit protection for *all* actions, not just forms.

**Hotwire: partial.** Turbo 8 morphing preserves focused input values, but with less
explicit rules and no per-element opt-in/out. No general in-flight click suppression.

#### 7. Uploads

`allow_upload(:avatar, accept: ~w(.jpg), max_entries: 2, auto_upload: true)`,
`<.live_file_input>`, `<.live_img_preview entry={entry}>`, auto-updating `entry.progress`,
`phx-drop-target` with an automatic `phx-drop-target-active` class, `cancel_upload/3`,
`upload_errors/1,2`, and external/direct-to-S3 uploads.

**Hotwire: partial and much more work.** Active Storage direct upload emits
`direct-upload:progress` events; you build every pixel of UI, previews, drag-drop styling,
per-entry cancel, and validation yourself.

#### 8. Connection lifecycle

`phx-connected` / `phx-disconnected` with JS commands, plus `.phx-connected`/`.phx-loading`/
`.phx-error` container classes → "Attempting to reconnect…" banners for free. Page-level
`phx:page-loading-start`/`stop` with `info.detail.kind ∈ redirect|patch|initial|element|error`.

**Hotwire: partial.** `.turbo-progress-bar` + turbo events. **No offline/disconnected concept at all.**

#### Where LiveView loses (and Hotwire genuinely wins)

Be as honest in this direction:
- **A stateful server process per connected user.** Memory and hosting cost scale with
  concurrent users, not request rate.
- **Requires a persistent WebSocket** — hostile to CDN and page caching.
- **Reconnect means state loss** — the existence of `phx-auto-recover` is the tell.
- **Every interaction is a round trip** unless you reach for JS commands; latency-sensitive
  UI degrades badly on flaky mobile networks.
- Hotwire's stateless HTTP model needs no per-user server state, caches normally, survives
  deploys without dropping user state, and runs on cheaper infrastructure.

---

### Laravel Livewire

Livewire **4.x** (note: commonly mis-cited as 3.x).

#### 1. `data-loading` attributes + CSS variants — the most portable idea in this survey

Livewire v4 "automatically adds a `data-loading` attribute to any element that triggers a
network request." The docs explicitly recommend it *over* the older `wire:loading` directive.
It fires for actions, form submits, property updates, **and dispatched events — even when
handled by a different component**.

```html
<button wire:click="save" class="data-loading:opacity-50">Save</button>
<span class="not-data-loading:hidden">Saving...</span>

<button wire:click="save">
  <span class="in-data-loading:hidden">Save</span>
  <span class="not-in-data-loading:hidden">Saving...</span>
</button>

<div class="has-data-loading:opacity-50"><button wire:click="save">Save</button></div>

<button wire:click="save" class="peer">…</button>
<span class="peer-data-loading:opacity-50">Saving…</span>

<button class="[&[data-loading]_.icon]:animate-spin" wire:click="save">…</button>
```

This is **strictly better than LiveView's class-based approach** because it needs no
framework-specific CSS classes — it's a plain attribute that CSS already knows how to
target, composing with `data-*`, `not-*`, `in-*`, `has-*`, `peer-*` and arbitrary variants.

#### 2. `wire:dirty` — unsaved-changes state, first class

```html
<div wire:dirty>Unsaved changes...</div>
<div wire:dirty.remove>The data is in-sync...</div>
<div wire:dirty wire:target="title">Unsaved title...</div>
<input wire:model.live.blur="title" wire:dirty.class="border-yellow-500">
<div wire:show="$dirty">You have unsaved changes</div>
<div wire:show="$dirty('user.name')">Name has been modified</div>
```

**Hotwire: NONE.** Dirty tracking (and the `beforeunload` guard that goes with it) is
hand-rolled in every Rails app.

#### 3. `wire:offline`

```html
<div wire:offline>This device is currently offline.</div>
<div wire:offline.class="bg-red-300">
<button wire:offline.attr="disabled">Save</button>
```

**Hotwire: NONE.** Trivial to port, disproportionately valuable — Hotwire apps fail silently
when offline.

#### 4. `@island` — partial re-render regions

```blade
@island(lazy: true)
  @placeholder <div class="animate-pulse">…</div> @endplaceholder
  <div>Revenue: {{ $this->revenue }} <button wire:click="$refresh">Refresh</button></div>
@endisland

@island(defer: true)          {{-- load right after page load, not on visibility --}}
@island(name: 'revenue')      {{-- targetable via wire:island --}}
```

`lazy:` uses an IntersectionObserver; `defer:` loads immediately post-load.

**Hotwire: this is basically `turbo_frame_tag ..., loading: :lazy` — genuine parity, and a
Hotwire win worth noting.** Turbo Frames arrived at this first and more simply. The only
edge Livewire has is the `@placeholder` ergonomics and named-island refresh.

#### 5. Rest of the surface

`wire:navigate` (+ `.hover`) ≈ Turbo Drive + `data-turbo-prefetch` (**parity — not a gap**);
`@persist` ≈ `data-turbo-permanent`; `wire:poll` (+`.visible`, `.keep-alive`) — **Hotwire has
none**; `wire:confirm` ≈ `data-turbo-confirm`; `wire:stream` (streamed partial responses —
relevant for LLM token streaming); plus `wire:transition`, `wire:show`, `wire:text`,
`wire:sort`, `wire:intersect`, `wire:ref`, `wire:replace`, `wire:ignore`, `wire:cloak`.
PHP attributes: `#[Async]`, `#[Defer]`, `#[Isolate]`, `#[Lazy]`, `#[Renderless]`, `#[Computed]`.

---

### Alpine.js

Alpine **3.16.1**, actively released — a pointed contrast with Stimulus 3.2.2 (Aug 2023).

**Where Alpine genuinely wins:** ephemeral, local, presentational state. A dropdown is ~3
lines of HTML with no separate file; the Stimulus equivalent is a controller file plus
targets plus classes plus a `data-controller` attribute. Alpine also has `x-model` (two-way
binding — Stimulus has nothing), `x-teleport`, `$refs`, `$watch`, `$store`, `x-transition`,
and actively maintained plugins (Focus/focus-trap, Collapse, Anchor, Persist, Intersect,
Sort, Mask, Morph, Resize).

**Where Stimulus wins:** no inline JS (CSP-clean by default — Alpine's default build
evaluates expressions and needs the restricted CSP build to satisfy a strict policy, and
Rails ships a CSP initializer); explicit `connect`/`disconnect` lifecycle; the values API
with change callbacks; outlets for cross-controller composition; and one mental model shared
with Turbo.

**Alpine + Turbo — the honest verdict.** The friction is real but low-grade and stable, not
a fire:
- `SimoTod/alpine-turbo-drive-adapter` (241 stars, pushed 2026-02-14, **not archived**, 1
  open issue from 2021) exists precisely because of this. Its README states the problem
  verbatim: *"It handles events to properly clean up the DOM from Alpine generated code when
  navigating between pages."*
- The structural hazard: Alpine mutates the DOM (`x-show` → `style="display:none"`,
  `x-bind` → attributes) and Turbo Drive caches a serialized DOM snapshot for back-button
  previews — so restored snapshots can show stale Alpine state.
- Turbo 8 morphing adds a second hazard surface (idiomorph rewriting nodes Alpine believes
  it owns), though `turbo:before-morph-element` is the supported escape hatch.
- **Honest qualification:** searching `hotwired/turbo` and `alpinejs/alpine` for current
  cross-mentions yields very little. That is as consistent with "few people do this" as with
  "it works fine." Do not overstate this as a known-broken combination.

**Verified `stimulus-components` inventory** (~30 packages) — what exists, and what doesn't:

*Exists:* auto-submit, prefetch, sortable, clipboard, dialog (native `<dialog>`), popover
(native popover), dropdown, reveal, content-loader, checkbox-select-all, character-counter,
textarea-autogrow, rails-nested-form, timeago, carousel, lightbox, scroll-to, scroll-progress,
scroll-reveal, notification, password-visibility, color-picker, chartjs, places-autocomplete,
animated-number, read-more, sound, glow, remote-rails.

*Does **not** exist — confirming the gaps ranked below:* **no focus-trap controller**, no
loading-state controller, no dirty-form controller, no polling controller, no
server-validation controller, no optimistic-preview controller, no offline controller.

**Should crosswire have an opinion?** Yes, a conditional one: prefer Stimulus for anything
that touches server state or must survive Turbo navigation; Alpine is defensible for
self-contained presentational widgets, but adopting it means two lifecycle models, a
third-party shim, and a CSP decision. The stronger 2026 answer for most of what people
reach for Alpine to do is **CSS and platform primitives** (see below) — `popover`,
`<dialog>`, `@starting-style` + `transition-behavior: allow-discrete`, `:has()` — which
cost zero bytes and have no lifecycle at all.

---

### Datastar & newer hypermedia

#### Datastar — the one newcomer that matters

`starfederation/datastar`, **v1.0.0 released 2026-04-16**, currently **v1.0.2** (2026-06-02),
**4,938 stars**, pushed 2026-08-14. Its own pitch:

> "Datastar provides backend reactivity like [htmx](https://htmx.org/) and frontend
> reactivity like [Alpine.js](https://alpinejs.dev/) in a lightweight frontend framework
> that doesn't require any npm packages or other dependencies."

That is the interesting claim: **one library replacing htmx + Alpine** — i.e. Turbo +
Stimulus — in a single `data-*` vocabulary with reactive signals, no build step.

```html
<script type="module" src="/path/to/datastar.js"></script>

<button data-on:click="alert('I'm sorry, Dave.')">Open the pod bay doors, HAL.</button>

<button data-on:click="@get('/endpoint')">Open the pod bay doors, HAL.</button>
<div id="hal"></div>
```

Backend "actions" (`@get()`, `@post()`, …) send fetch requests; responses with
`content-type: text/html` are **morphed** into the DOM by element ID. Note the design
choice: *morphing is the default patch strategy*, and Datastar states it "ensures... only
data attributes that have changed are reapplied, **preserving state**" — the reactivity
model and the morph model were designed together, which is precisely the seam where
Alpine + Turbo 8 morphing rubs.

**There is an official Ruby SDK** — `starfederation/datastar-ruby` (gem `datastar`, 37
stars, pushed 2026-06-02), explicitly Rails-aware:

```ruby
# Rails controller
datastar = Datastar.new(request:, response:, view_context:)

# one-off
datastar.patch_elements(%(<h1 id="title">Hello, World!</h1>))

# streaming — response stays open
datastar.stream do |sse|
  100.times { |i| sleep 1; sse.patch_elements(%(<h1 id="title">Hello #{i}!</h1>)) }
end
```

Multiple `stream` blocks run concurrently in threads/fibers with linearized output.

**Honest verdict:** a genuinely interesting design, 1.0 and shipping, with a real Ruby SDK
— but 37 stars on that SDK means near-zero Rails production usage. It also has a paid
"Datastar Pro" tier, which is a governance consideration. **Do not adopt; do steal one
idea:** signals. Datastar's insight is that a lot of what people reach for Stimulus to do
is *derived client state* (`data-computed`, `data-show`, `data-class`, `data-indicator`),
and expressing that declaratively removes whole controllers. The Rails-flavored version of
this idea is not "add signals to Turbo" — it's to notice that `data-indicator` is the same
idea as Livewire's `data-loading` (ranked #1 below), and that most `data-show` cases are
now solvable with CSS `:has()` and `popover`.

#### Others, briefly

- **StimulusReflex / CableReady** — the reactivity-gem category Turbo 8 morphing killed.
  Evidence: `stimulus_reflex` v3.5.5 (2026-07-28) but its 2026 commits are dependabot bumps;
  `cable_ready` last released **v5.0.6 on 2024-12-15** — ~20 months stale. Treat as
  maintenance-mode; do not start new work on them.
- **inertia-rails** — `inertiajs/inertia-rails` **v3.22.0 (2026-07-17)**, pushed 2026-08-15,
  1,221 stars. Actively developed with real momentum. This is the honest middle path: keep
  Rails routing/controllers/auth, render React/Vue/Svelte pages with server-provided props,
  no separate API layer. See §Escape hatches.
- **thoughtbot/superglue** — alive (pushed 2026-08-10, 610 stars): Rails + React + Redux.
  Narrower audience than Inertia.
- **turbo-mount** — `skryukov/turbo-mount` v0.4.4 (2025-12-25), pushed 2026-07-25, 476 stars.
  "Use React, Vue, Svelte, and other components with Hotwire." The purpose-built island tool.
- **react-rails** — 6,775 stars, pushed 2026-07-31. The old guard; still alive.

---

### Platform primitives that replace JS in 2026

**This is the highest-leverage section in this document.** A large share of the Stimulus
controllers people write in 2026 are re-implementing things the browser now does natively.
Baseline statuses below were verified individually against MDN on 2026-08-15.

| Feature | Baseline status | What it obsoletes |
|---|---|---|
| `<dialog>` + `showModal()` + `::backdrop` | **Widely available** | Hand-built modal controllers, backdrop divs, scroll locking, Esc handling |
| `<details name>` (exclusive accordion) | **Widely available** | Accordion controllers |
| `popover` / `popovertarget` | **Baseline 2024** | Dropdown, menu, tooltip controllers; top-layer/z-index fights; light-dismiss logic |
| `@starting-style` | **Baseline 2024** ("Since August 2024...") | Enter transitions for elements appearing from `display:none` |
| `transition-behavior: allow-discrete` | **Baseline 2024** | Exit transitions for `display:none` — **together with `@starting-style` this is the CSS replacement for Alpine `x-transition` / stimulus-use `useTransition`** |
| View Transitions (`view-transition-name`) | **Baseline 2025** | Hand-animated page/list transitions (Turbo wires this up via `<meta name="view-transition">`) |
| Invoker Commands (`command` / `commandfor`, `CommandEvent`) | **Baseline 2025** | The wiring controller between a button and a dialog/popover — **zero JS** |
| CSS anchor positioning (`anchor-name`, `position-anchor`, `position-try`) | **Baseline 2026** | Floating UI / Alpine's Anchor plugin for tooltip & dropdown positioning |
| `field-sizing: content` | **Baseline 2026** | `stimulus-textarea-autogrow` — one CSS declaration |

The two that matter most:

**1. Modals and dropdowns are now declarative and JS-free.**

```html
<button type="button" commandfor="mydialog" command="show-modal">Open</button>
<dialog id="mydialog">
  <p>Hello</p>
  <button commandfor="mydialog" command="request-close">Close</button>
</dialog>
```

No controller, no event listeners, no focus management code (the browser handles focus trap
and Esc for `showModal()`), no z-index management (top layer).

**2. Enter/exit transitions are now pure CSS.**

```css
.panel {
  transition: opacity 200ms, display 200ms allow-discrete;
  opacity: 1;
}
.panel[hidden] { opacity: 0; display: none; }
@starting-style { .panel { opacity: 0; } }
```

This removes the single most-cited reason to add Alpine to a Hotwire app.

**Honesty caveat to carry into the docs:** "Newly available" means current browsers, not
old ones. The 2024-baseline items have ~2 years of soak by now and are safe defaults for
most apps. The **2026**-baseline items (anchor positioning, `field-sizing`) are brand new —
use them as progressive enhancement with a working fallback, not as load-bearing structure.

---

## Where Hotwire genuinely loses

Stated bluntly. If crosswire soft-pedals this section, nothing else in the repo is trustworthy.

### 1. Stimulus is frozen, and the evidence is worse than "stable"

`@hotwired/stimulus` last shipped **v3.2.2 on 2023-08-07** — three years ago. Auditing every
commit to `main` since that release (`gh api repos/hotwired/stimulus/commits?since=...`):
**75 commits**, of which essentially **two** are substantive code changes:

- 2026-06-10 — "Clear cached event listeners when a removed action element leaves the
  document" (#877): **a memory-leak fix**
- 2024-03-19 — "Fix Inconsistency with Callback Ordering" (#759)

Everything else is dependabot bumps, docs typos, a copyright-year update, CI config, and
removing a dead Glitch link. **And the memory-leak fix merged 2026-06-10 is still
unreleased as of 2026-08-15.** Users on the released version are running with a known leak.

Additional verified evidence:

- **37 open PRs**, the oldest from **2022-12-07** (#621) — along with #627, #647, #653, #661,
  #662, #684, #687, #690, #695, all from Dec 2022–Jun 2023, all untouched.
- DHH promised to remove TypeScript from Stimulus in issue
  [#733](https://github.com/hotwired/stimulus/issues/733) (2023-12-30): *"Yes, Stimulus will
  eventually get off TypeScript as well. But we are working on getting Turbo 8 out the door
  first."* Turbo shipped and is now 100% JS (0 bytes TS). **Stimulus is still 251,138 bytes of
  TypeScript, 2.5+ years later.**

**Present both sides.** The maintainers' stated position, DHH replying directly to "is this
abandoned?" ([#803](https://github.com/hotwired/stimulus/issues/803), 2025-02-02):

> "Absolutely not. But not every package of software needs a constant churn of releases to be alive. Stimulus is used by every new Rails app by default, and it powers Basecamp, HEY, and a bunch of other web apps."

And Marco Roth (hotwired org maintainer),
[#740](https://github.com/hotwired/stimulus/issues/740) (2023-11-13): *"This repo isn't dead...
Stimulus is on top of my list after RubyConf."* RubyConf 2023 came and went; no release followed
in the ~2.75 years since.

The contrast matters: **Turbo is actively released** (v8.0.18 → v8.0.23 between 2025-09 and
2026-01). So "Hotwire is dead" is false — but "Stimulus specifically is in maintenance-only
mode with a merged, unreleased bugfix" is true and defensible. The
["no build step"](https://htmx.org/essays/no-build-step/) argument that finished software is
a feature is a real rebuttal — but finished software still ships its bug fixes, and it doesn't
leave 37 PRs open for three years.

**crosswire's editorial line should be: show the reader the maintainer position AND the
contradicting data, and let them decide.** Don't pick a side; don't hide either half.

### 2. The genuinely-losing UI categories

Carson Gross names these himself in
[When Should You Use Hypermedia?](https://htmx.org/essays/when-to-use-hypermedia/), which
makes them impossible to dismiss as React partisanship:

- **High-frequency input**: drag, canvas, drawing, sliders, resize, games. "Putting a
  hypermedia network request in-between a mouse move and a UI update will not work well."
- **Dense interdependent client state**: spreadsheets, formula engines, design tools. "a user
  can enter an arbitrary function into a cell and introduce all sorts of dependencies on the
  screen, on the fly."
- **Offline**: "if your application requires full functionality in an offline environment,
  then the hypermedia approach is not going to be an acceptable one."
- His named examples: **Google Sheets and Google Maps**.

Add to that, from the Gumroad write-up and general practice: rich-text/code editors,
real-time collaborative editing (CRDT/OT), and latency-sensitive interactions on bad mobile
networks. Every server round trip is a hostage to the user's worst network moment.

### 3. Capability gaps vs. peer frameworks (all verified above)

Hotwire has **nothing built in** for: per-element loading state (LiveView and Livewire both
give it in one attribute), dirty-form tracking, offline awareness, server-driven field-level
validation, polling, request coordination/deduplication, optimistic UI with automatic
revert, error/failed states for lazy frames, relative targeting (`closest`/`next`), or
routing failures to a different region than successes.

Most of these are individually buildable — that is the point of this document — but "you can
build it" is a different product than "it ships in the box," and honest comparison should say
so.

### 4. Component & accessibility ecosystem

There is no Hotwire equivalent to **Radix / React Aria** — headless, rigorously
accessibility-tested primitives (focus management, roving tabindex, ARIA wiring, keyboard
interaction patterns). **This claim was tested, not assumed**: `gh search repos` for "rails
headless accessible components", "stimulus accessibility primitives", and "ruby aria
combobox/listbox/popover" returned **zero results**.

Star counts for scale (via `gh api`, 2026-08):

| React side | ★ | Rails side | ★ |
|---|---|---|---|
| shadcn/ui | 121,395 | ViewComponent | 3,569 |
| Mantine | 31,571 | Phlex | 1,523 |
| Radix primitives | 19,166 | stimulus-components | 1,466 |
| React Aria / react-spectrum | 15,798 | Lookbook | 1,091 |
| Ark UI | 5,344 | `hotwire_combobox` | 652 |

The closest Rails answer, `shadcn-rails` (892★, last pushed 2025-11-21), states in its own
README: *"This is NOT a component library... copy and paste the code."* It ports shadcn's
Tailwind **visual** layer — not Radix's underlying focus-trap / roving-tabindex / ARIA
state-machine engineering. 121,395 vs 892 stars is a 136× gap.

The verified `stimulus-components` catalog (~30 packages) covers dropdowns, dialogs, popovers,
carousels, clipboard — but ships **no focus-trap controller at all**. Teams shipping accessible
complex widgets in Hotwire are doing a11y engineering themselves that React teams get from a
library. The 2026 platform primitives (`<dialog>`, `popover`, `inert`) close a real part of this
— but not roving tabindex, comboboxes, or tree/grid patterns.

**Raw ecosystem scale**, for honest framing — npm weekly downloads (2026-08-03→09):
`react` **163,083,190/wk** vs `@hotwired/stimulus` **1,013,897/wk** vs `@hotwired/turbo`
**981,560/wk** — roughly **160×**. Stack Overflow 2025 Developer Survey: React 46.9% of
professional developers, Rails 6.2%.

### 5. Type safety and the server→client contract

No typed contract exists between a Rails view and a Stimulus controller. Target and value
names are strings; a typo fails silently at runtime with no error. There is nothing
resembling end-to-end types (tRPC-style) or compile-time template checking.

Stimulus does ship `.d.ts` types, but they only cover the controller's own internals — every
`*Target`/`*Value`/`*Outlet` must be hand-declared with no automatic derivation
([stimulus#723](https://github.com/hotwired/stimulus/issues/723)). Third-party workarounds
exist (`stimulus-decorators`, `ajaishankar/stimulus-typescript`); none are official, and none
address the core problem: **an ERB template has zero compile-time link to the Stimulus
controller it references.** A renamed target is a runtime failure, not a build failure.

### 5b. Testing tooling

Honest comparison, with the caveat that hard numbers are scarce:

- Rails system tests are full-stack and browser-driven. The long-standing complaint (HN,
  <https://news.ycombinator.com/item?id=7659649>): *"the capybara tests as the most cumbersome, unreliable and generally superfluous tests in our suites... at best slow and hard to maintain."* Dated, but still widely echoed.
- turbo-rails' own bug-report template now standardizes on **Capybara + Cuprite** rather than
  Selenium — a tacit admission that the default stack was worth replacing.
- **Stimulus has no unit-testing story.** Two independent practitioners say so directly:
  `ywain` — *"Stimulus doesn't really offer a way to write unit tests for your controllers"*;
  `catwind7` — *"Stimulus has not been the most testable tool — we lean mostly on integration tests."* Compare Vitest/RTL, where testing a component in isolation is the default.
- ⚠ **Could not find hard apples-to-apples speed/flakiness numbers** for Vitest/RTL/Playwright-CT
  vs Rails system tests. Anyone claiming a specific multiplier is guessing.

### 6. Debugging and observability

The characteristic Hotwire failure is **silence**: a frame whose id doesn't match, a stream
targeting a missing DOM id, a response missing the frame, a morph that reverted your
client-side change. Nothing throws; nothing appears. `turbo:frame-missing` exists but must be
wired up deliberately. Contrast React devtools, or LiveView's explicit crash-and-reconnect.

Documented in turbo-rails' own issue tracker:

- [turbo-rails#168](https://github.com/hotwired/turbo-rails/issues/168) — "what makes turbo-rails silently fail on forms." Maintainer `henrik`: *"the frustration is certainly real... My assumption was that the docs are misleading."*
- [turbo-rails#703](https://github.com/hotwired/turbo-rails/issues/703) — broadcast fires, logs confirm it, HTML is received, DOM silently doesn't update, no error.
- [turbo-rails#342](https://github.com/hotwired/turbo-rails/issues/342) — an unresolved stream target yields a raw `TypeError: null is not an object` rather than a Turbo-level diagnostic.

### 6b. Turbo 8 morphing — the specific open complaints

Morphing is Turbo 8's headline feature and genuinely killed the reactivity-gem category, but it
has real, tracked limitations:

| Issue | Status | Problem |
|---|---|---|
| [turbo#1210](https://github.com/hotwired/turbo/issues/1210) | **open** | **Stimulus `data-*-value` attributes wiped on morph.** Maintainer `seanpdoyle`: *"I hope that there will [be] bandwidth for a coordinated effort to expand built-in Morph integration for Stimulus and Trix... something that affords a configuration-less turn-key solution"* — acknowledged unsolved, no timeline. |
| [turbo#1272](https://github.com/hotwired/turbo/issues/1272) | **open** | No built-in scroll-position preservation on morphed frames. |
| [turbo-rails#533](https://github.com/hotwired/turbo-rails/issues/533) | **open since 2023-11-30** | Trix editor toolbar disappears/disables on morph update. |
| [turbo#1199](https://github.com/hotwired/turbo/issues/1199) | closed | Morph overwrites user input on active elements during autosubmit/search; workaround is manual `data-turbo-permanent` toggling. |
| [turbo#1083](https://github.com/hotwired/turbo/issues/1083) | closed | Third-party JS DOM mutations (e.g. TomSelect) reverted by morph — `connect()`/`disconnect()` don't refire. `turbo:morph` fires twice in some cases (confirmed by a maintainer as a preview-then-real-response artifact). |
| [turbo#1351](https://github.com/hotwired/turbo/issues/1351) | closed | Lifecycle callback ordering differs under morph vs. normal load. |

Note the pattern: **the sharpest open issue is Stimulus ↔ morph integration**, and it is
acknowledged-but-unowned. That compounds directly with §1 — the component of Hotwire that most
needs work is the one that isn't shipping releases.

Also worth flagging: two **unresolved memory-leak reports**,
[turbo#1338](https://github.com/hotwired/turbo/issues/1338) and
[turbo#1325](https://github.com/hotwired/turbo/issues/1325) — *"heap size increases
exponentially due to thousands of detached DOM nodes being retained, leading to eventual
browser crashes."* `data-turbo-permanent` and script-strategy workarounds did not resolve it;
both threads have thin engagement and no fix.

### 7. Hiring and career surface — the honest non-technical cost

From HN, 2026-06-11 (<https://news.ycombinator.com/item?id=48497924>) — notably from someone
who *likes* and *ships* Hotwire:

> "I build my apps the same way: mostly server-rendered HTML with a little JavaScript on top
> (Hotwire on Rails)... I avoid React when I can. **The frustrating part is there isn't much
> Hotwire or Rails work around these days. Most of the jobs want React.**"

And Gross's own sociological caveat:

> "If your team is not on board... it is a real phenomenon and should be borne in mind with
> humility... It may be better to adopt hypermedia around the edges, perhaps for internal
> tools first, to prove its value first."

### 8. Where practitioners actually hit the wall

<https://news.ycombinator.com/item?id=40572705> — 2024-06-04:

> "I love the idea of Hotwire and I'm already using it in one of my production project.
> Overall it saved me a lot of time and frustration having to deal with a separate frontend
> project... **However I faced some other new frustration, such as when trying to make a
> dynamic nested form... It is also hard to think of each hotwire controller as a component,
> you might face some problems when trying to do some nesting.** I think Hotwire will be a
> perfect fit if you want a traditional websites with a few dynamic, interactive features.
> **If your website is too much app-like, you should consider switching the frontend part to
> SPA entirely.**"

<https://news.ycombinator.com/item?id=32960209> — 2022-09-24, net-positive but pointed:

> "I really dig Stimulus and Turbo Frames... **I think the documentation is pretty bad
> compared to the rest of the Hotwire stack** — but—holy moly—once I had it working, it's
> really like a superpower."

The historical "you accidentally built a worse SPA" critique
(<https://news.ycombinator.com/item?id=30530626>, 2022-03-02):

> "you get to browser navigation and you're screwed... **once you're done, you've basically
> implemented a SPA, except it's broken into a mix of tightly-coupled Javascript, Ruby and
> ERB templates.**"

⚠ Fairness note: that last one predates Turbo 8. Morphing + `data-turbo-permanent` +
`turbo:before-morph-element` materially improved state preservation across navigation.
Present it as a partially-addressed historical critique, not current fact.

### 9. The team-scale finding — the most load-bearing negative in this research

This is the one claim that showed up **repeatedly, from unconnected practitioners, unprompted**,
which makes it the closest thing to a falsifiable pattern in the whole corpus:

> `0xblinq`, Oct 2025 (<https://news.ycombinator.com/item?id=45506620>): *"We replaced Hotwire frontend with Inertia and it's night and day. **Unless you work 100% alone (and for a smallish project) hotwire leads to a real mess nobody can work on** way before anything else I've ever seen in my life."*

> `catwind7` (<https://news.ycombinator.com/item?id=25310766>): *"We adopted stimulusjs... it was a decent tool, but **we quickly grew out of it once we started adding more complex (form based) front-end behavior involving lots of state changes**... it does not grow well with increasing client side complexity. You'll end up writing a lot of javascript boilerplate / DOM manipulation code / custom state management components."*

> `ywain`, Oct 2023 (<https://news.ycombinator.com/item?id=37787235>): *"we are now considering switching to React... **candidate pool for React is a few orders of magnitude bigger**... it's getting harder and harder to find vanilla JS packages that you can wrap in Stimulus controllers... **the recent Turbo TypeScript debacle did not instill confidence in the long term stewardship of the Hotwire ecosystem.**"*

> `padseeker`, Oct 2025 (<https://news.ycombinator.com/item?id=45506908>): *"It's best suited for STATELESS interactions... if you want to update one thing based on the most recently touched input it becomes more complicated."*

And a deep technical critique from someone who actually built a Turbo 8 morphing app —
`andersmurphy`, Apr 2025 (<https://news.ycombinator.com/item?id=43657577>): *"the docs are
incomplete... you quickly realise the limitation [of morph]... **I found I was still writing
quite a bit of JavaScript with turbo.**"*

**crosswire should treat "Hotwire scales down beautifully and scales up questionably" as the
honest headline**, not as an attack to rebut. It is consistent with 37signals' own usage
(one programmer and one designer doing most of Basecamp) and with the escalation rubric below.


---

## The honest case for Hotwire

### Start by conceding the thing everyone gets wrong

**Hotwire's runtime is not smaller than React's.** Measured directly by downloading the
published npm tarballs and running `gzip -c` on the production builds (2026-08-15):

| Bundle | gzipped |
|---|---|
| `@hotwired/turbo` 8.0.23 (`turbo.es2017-esm.js`) | 45,323 B |
| `@hotwired/stimulus` 3.2.2 (`stimulus.js`) | 15,392 B |
| **Turbo + Stimulus** | **60,715 B** |
| `react` 18.3.1 (`react.production.min.js`) | 2,735 B |
| `react-dom` 18.3.1 (`react-dom.production.min.js`) | 42,396 B |
| **React + ReactDOM (bare)** | **45,131 B** |

Bare Turbo + Stimulus is **~35% larger** than bare React + ReactDOM. Any crosswire page that
claims "Hotwire ships less JavaScript than React" as a framework-level fact is wrong and will
be caught by anyone who checks. The real payload argument is about the **application** bundle —
the router, state library, data-fetching layer, component library, and build tooling a React app
additionally needs (and which Hotwire mostly doesn't) — and it must be made with
application-level numbers (below), never framework-level ones. Contexte's 255→9 dependencies and
martinjarosinski's 2.3MB→47KB are the right kind of evidence; "Turbo is smaller than React" is not.

Leading with this concession is what buys the rest of the section credibility.

### The thesis writing

- **"The One Person Framework"** — DHH, Dec 2021, <https://world.hey.com/dhh/the-one-person-framework-711e6318> — the post that shipped Hotwire as the Rails 7 default, framed around "conceptual compression."
- **"The Majestic Monolith"** — DHH, Feb 2016, <https://signalvnoise.com/svn3/the-majestic-monolith/> — Basecamp 3 as 200 controllers / 900 methods / 190 models built by "just 12 programmers... just 7 designers" across six platforms.
- **"How to recover from microservices"** — DHH, May 2023, <https://world.hey.com/dhh/how-to-recover-from-microservices-ce3803cc>.

⚠ Honesty note: there is **no single canonical DHH essay** tying "majestic monolith" to
Hotwire. The connection is thematic across posts. Don't cite a unified doctrine that doesn't exist.

### Rails World keynotes

- **2023 (Amsterdam)** — effectively "the Hotwire edition," 6+ Hotwire talks. Announced Turbo 8 DOM morphing, broadcasted refreshes, Propshaft, Solid Cache/Queue, Kamal, Strada.
- **2024 (Toronto)** — <https://rubyonrails.org/2024/10/15/rails-world-2024-recap>. DHH: *"HEY went 100% #NOBUILD"* and *"JS minification killed the web as a learning platform... saving only 2-5% overhead."* Production numbers: Solid Cache = 10TB, 60-day retention, 96% hit rate at HEY; Solid Queue = 20M jobs/day.
- **2025 (Amsterdam)** — Rails 8.1 beta, **Turbo Offline**, Action Push (Native + Web Push), Local CI DSL, Campfire made free.

### 37signals as evidence — measured, not asserted

The ONCE Campfire source is public, so it can be checked rather than believed. Cloning
`basecamp/once-campfire` and counting:

- **`app/` = 9,592 LOC**; whole repo (app + lib + config) = **22,133 LOC**
- 45 controllers, 17 models, **37 Stimulus controllers**
- **Zero React/Vue/webpack** in the Gemfile or package.json — genuinely pure Hotwire, not a hybrid

Team size (2025): *"Basecamp... developed by just three programmers and three designers... The
vast majority of work... made by one programmer, one designer."* A 2025 job posting corroborates
*"Just ten Ruby programmers total"* across Basecamp, HEY, ONCE and new products.

⚠ Not found: any published Writebook LOC figure. The "95% human-written code" claim about
37signals' Fizzy is secondhand only — do not cite it as primary.

### Migration evidence — with its weakness stated

**The strongest Hotwire-specific case** (Martin Jarosiński, Jan 2025,
<https://www.martinjarosinski.com/posts/what-i-learned-replacing-a-react-spa-with-hotwire/>):
Next.js SPA with 900+ npm deps, GraphQL, 2.3MB JS, 14s load on 3G, built by 3 people over ~4
months → Hotwire rebuild by **1 developer in 6 weeks**. Load 14s → <2s; JS **2.3MB → 47KB**;
deps 900+ → ~30 gems; **code ~60% smaller**; deploy pipeline 2 apps/12min → 1 app/4min.
*The client is anonymized.*

**HalalBooking.com** (named company, Rails World 2025,
<https://www.rubyevents.org/talks/lessons-from-migrating-a-legacy-frontend-to-hotwire>) —
React-centered stack → Hotwire, reported "huge DX and performance boost," but **no LOC/team/
timeline numbers are available in the published abstract**.

**Linkana** (<https://dev.to/cirdes/from-react-to-hotwire-part-i-en-2o6g>) — narrative only, no
metrics, and they **kept React for some flows**. A hybrid outcome, not a clean replacement.

⚠ **The honest bottom line on migrations: there is no publicly documented, named, large-company
React→Hotwire migration with hard numbers.** The genre is dominated by solo consultants and
anonymized clients. crosswire should say this outright. Anyone who searches will find the same
thing, and pretending otherwise costs more credibility than the admission does.

**The best-quantified server-driven migrations are htmx/Django, not Hotwire** — label them as
analogous, never as Hotwire evidence:

- **Contexte** (<https://htmx.org/essays/a-real-world-react-to-htmx-port/>, DjangoCon EU 2022):
  ~2 months on a 21K LOC codebase. Code **21,500 → 7,200 LOC (−67%)**; Python +140% (500→1,200);
  **JS deps 255 → 9 (−96%)**; build **40s → 5s (−88%)**; TTI 2-6s → 1-2s (−50-60%); memory
  75MB → 45MB (−46%); larger data sets became possible. Team went from a hard back/front split
  to **entirely full-stack**.
  With Gross's own caveat, which crosswire should always quote alongside the numbers:
  > "These are eye-popping numbers, and they reflect the fact that the Contexte application is extremely amenable to hypermedia: it is a content-focused application that shows lots of text and images. **We would not expect every web application to see these sorts of numbers.**"
- **Misago** (<https://misago-project.org/t/removing-reactjs-from-the-codebase-and-adapting-htmx-for-ui-interactivity/1267/>) — partial migration, ~85KB uncompressed / ~25KB gzip removed.

### The economic argument

The durable claim is **team shape, not bundle size**: one codebase, one deploy, no JSON API
layer to maintain, no duplicated validation/routing/state, and developers who own features
end-to-end. Contexte's whole team becoming full-stack, and the martinjarosinski 3-people-4-months
→ 1-person-6-weeks delta, are the two best data points.

⚠ Not found despite targeted search: **any article quantifying "we cut N frontend engineers"**
with real headcount or cost figures. The economic case is asserted qualitatively everywhere and
quantified nowhere. Say so.

---

## Decision framework: Hotwire vs island vs SPA

### The default

**Start with Hotwire. Escalate per screen, never per app.** The most common failure in both
directions is choosing one architecture for an entire product when the product has ten screens
that want Hotwire and one that wants a component.

### The five escalation signals

Escalate a **single screen** from Hotwire to an island when it shows any of these. These are
drawn from Gross's own "when not to use hypermedia" essay, the failure corpus, and the islands
literature:

1. **Interaction frequency exceeds round-trip tolerance.** Drag, canvas, drawing, sliders,
   resize, live cursors. Gross: *"Putting a hypermedia network request in-between a mouse move and a UI update will not work well."*
2. **Dense interdependent client state.** A change to one field recomputes many others through
   relationships not known at render time. Gross's example is a spreadsheet: *"a user can enter an arbitrary function into a cell and introduce all sorts of dependencies on the screen, on the fly."*
3. **Offline or unreliable-network is a requirement, not a nicety.** Gross: *"if your application requires full functionality in an offline environment, then the hypermedia approach is not going to be an acceptable one."* (Watch Rails 8.1's **Turbo Offline** — this may soften.)
4. **The widget has a deep internal state machine you'd be reimplementing.** Rich text, code
   editors, undo/redo stacks, incremental parsers. Wrap, don't rebuild.
5. **Interactivity *is* the product on this screen.** Jason Miller's original islands framing
   (<https://jasonformat.com/islands-architecture/>): peripheral interactivity → Stimulus
   sprinkle; interactivity that is the core value → real component.

**Two or more signals → island. Zero or one → Hotwire, and the pain you're feeling is probably
a missing recipe, not a missing framework.**

### The counter-signals (do NOT escalate)

- "It felt awkward once." Most awkwardness is a missing pattern — several are in §Ideas worth stealing.
- "We might need it later." Islands are cheap to add later and expensive to remove.
- "The designer knows React." Real, but a hiring argument, not an architecture argument — decide it as one.

### The honest team-shape signal

This is the most repeated finding in the failure corpus, from multiple unconnected practitioners,
and crosswire should publish it rather than bury it:

> `0xblinq`, HN Oct 2025 (<https://news.ycombinator.com/item?id=45506620>): *"We replaced Hotwire frontend with Inertia and it's night and day. Unless you work 100% alone (and for a smallish project) hotwire leads to a real mess nobody can work on."*

Same person reached the same conclusion on a **second, independent project**
(<https://news.ycombinator.com/item?id=41471978>), and states the rule as: **Hotwire for
solo/small teams; Inertia+React for large teams or split frontend/backend teams.**

Evil Martians' analysis of 334 funded 2024 startups
(<https://evilmartians.com/chronicles/why-startups-choose-react-and-when-you-should-not>) reaches
a compatible conclusion: React's 88.6% adoption is substantially a **hiring-pool bet**, not a
technical-superiority bet. Their advice is the right frame for crosswire to adopt:

> "design your architecture so your business logic survives framework migrations... your rendering layer should be replaceable."

### Rubric summary

| Situation | Choose |
|---|---|
| CRUD, forms, dashboards, content, admin | **Hotwire** |
| One screen with 2+ escalation signals | **Island inside a Hotwire app** (`turbo_mount`) |
| Third-party widget with deep internal state | **Stimulus controller wrapping it** |
| Most screens need rich client state; team is large or split front/back | **Inertia** (whole view layer, keep Rails routing/controllers/auth) |
| Offline-first, real-time collaborative editing, canvas/spreadsheet as the product | **Full SPA** — and be honest that Rails is now just the API |

---

## Escape hatches done cleanly

The containment rule, which is what separates a healthy island from a creeping rewrite:
**props in via data attributes, events out via DOM CustomEvents, no shared router, no shared
store, teardown on `disconnect()`.** An island that reaches into app-wide state has stopped
being an island.

| Tool | Version (verified 2026-08-15) | Status | Containment |
|---|---|---|---|
| **`turbo-mount`** (skryukov) | 0.4.4 (2025-12-25), pushed 2026-07-25, 476★ | Active, low cadence. Evil Martians. | **Strongest.** Props as a JSON data-attribute, mount on `connect()`, unmount on `disconnect()`, events out via DOM. The canonical island tool. |
| **Stimulus wrapping a widget** | pattern, not a package | Officially documented — Stimulus Handbook ch. 6, "Working With External Resources" | **Good** for self-contained widgets. Pair with `stimulus-use` (1,679★, active) for auto-cleanup helpers. Breaks down once the widget needs shared app state. |
| **Web components / Lit** | native | — | **Most contained of all** — no framework runtime, native `disconnectedCallback`. Evil Martians' nanotags migration saved **100KB** (React+ReactDOM 62.8KB gz vs Lit 6.2KB vs nanotags <2.5KB). ⚠ **No published Rails-specific case study** — mechanism transfers, but nobody has documented it at scale in Rails. |
| **`inertia_rails`** | **3.22.0** (2026-07-17), pushed 2026-08-15, 1,221★, 8 open issues | Very active, ~monthly releases | **Not an island** — replaces the whole view layer per page. Answers "should this *screen* be a SPA," not "should this *widget* be JS." Keeps Rails routing/controllers/auth; no client router, no REST API. |
| **`react_on_rails`** (shakacode) | 17.0.1 (2026-07-29), 5,190★, pushed 2026-08-15 | Very active | **Weak containment** — closer to "bring your whole React app." Also the tool behind a documented Turbo Streams mounting bug (below). |
| **`react-rails`** | gem **3.3.1** (2026-05-16) | Alive but maintenance-mode. ⚠ Its GitHub *Releases* tab is misleadingly stale (last tag 2.6.2, 2022) while RubyGems kept shipping. | Moderate; predates Turbo, no native Turbo lifecycle awareness. |
| **`vite_rails`/ViteRuby** | 3.11.1, 1,590★, active | Active | Build tooling only — enforces no containment itself; discipline is on you. |
| **`superglue`** (thoughtbot) | 1.0.3 stable; 2.0.0-beta.11 on default branch; pushed 2026-08-10, 610★ | Genuinely active (contradicts "thoughtbot abandoned it"), but long stuck mid-rewrite | **Fails containment by design** — a deliberate SPA framework with a global Redux store. Opposite end of the spectrum from turbo_mount. |
| **`stimulus_reflex` / `cable_ready`** | SR v3.5.5 (2026-07-28, dependabot-only); **CR v5.0.6 (2024-12-15, ~20 months stale)** | **Maintenance mode / stalled** | Don't start new work here — Turbo 8 morphing absorbed the category. |

**The documented integration hazard to warn about:** bitcrowd
(<https://dev.to/bitcrowd/getting-react-on-rails-to-work-with-turbo-streams-2c46>) found React
components silently failing to mount when Turbo Streams injected new DOM — the mount hooks
never fired. The fix required monkey-patching `Turbo.StreamElement.prototype.render`. This is
the canonical reason to prefer `turbo-mount` (Turbo-lifecycle-aware by construction) over
generic React-mounting gems.

**On inertia_rails' "official" status — do not overstate it.** Evil Martians, a prominent Rails
consultancy, formally joined as co-maintainers (2025-12-31,
<https://evilmartians.com/chronicles/inertiajs-in-rails-a-new-era-of-effortless-integration>),
citing "proper React support" as the #1 startup request from their RailsConf keynote. That is
real momentum — and notably the top contributor, `skryukov`, is the same engineer behind
`turbo-mount`, so one consultancy is running both prongs. But **no DHH statement, Rails-core
endorsement, or Rails World talk endorsing inertia_rails was found.** It is well-maintained and
increasingly popular; it is not blessed.

---

## Migration stories (both directions)

| Who | Direction | Stated reason | Source |
|---|---|---|---|
| Anonymized client (M. Jarosiński) | React SPA → Hotwire | 900+ deps, 2.3MB bundle, 3 devs/4mo → 1 dev/6wk; −60% code | [link](https://www.martinjarosinski.com/posts/what-i-learned-replacing-a-react-spa-with-hotwire/) |
| **HalalBooking.com** | React-centered → Hotwire | "Huge DX and performance boost" — ⚠ no numbers published | [Rails World 2025](https://www.rubyevents.org/talks/lessons-from-migrating-a-legacy-frontend-to-hotwire) |
| Linkana | React → Rails SSR (**partial**, kept React for some flows) | Narrative only | [link](https://dev.to/cirdes/from-react-to-hotwire-part-i-en-2o6g) |
| *Contexte* (htmx — analogous) | React → htmx | −67% LOC, −96% deps, −88% build | [link](https://htmx.org/essays/a-real-world-react-to-htmx-port/) |
| *Misago* (htmx — analogous) | React → htmx (partial) | ~25KB gz removed | [link](https://misago-project.org/t/removing-reactjs-from-the-codebase-and-adapting-htmx-for-ui-interactivity/1267/) |
| **`0xblinq`'s teams (×2)** | **Hotwire → Inertia+React** | Team-scale maintainability: *"a real mess nobody can work on"* | [HN 45506620](https://news.ycombinator.com/item?id=45506620), [HN 41471978](https://news.ycombinator.com/item?id=41471978) |
| **Avo** (Rails admin-panel SaaS) | Vue SPA → **Hotwire** → Next.js/React | Outgrew Hotwire's dynamism ceiling; ecosystem | [HN 29084243](https://news.ycombinator.com/item?id=29084243) |
| `ywain`'s team | Stimulus → React (in progress) | Hiring pool, package ecosystem, testing, Turbo TS reversal | [HN 37787235](https://news.ycombinator.com/item?id=37787235) |
| `catwind7`'s team | Stimulus → React (in progress) | Complex form state, boilerplate, poor testability | [HN 25310766](https://news.ycombinator.com/item?id=25310766) |
| **Gumroad / Helper** | htmx → React/Next.js | Drag-drop, complex state, dynamic forms, real-time collab, ecosystem, AI tooling familiarity | [essay](https://htmx.org/essays/why-gumroad-didnt-choose-htmx/) |
| Gumroad (main app) | Rails/React hybrid → React/Next.js | ⚠ **Disputed** as a Hotwire failure — [`zhalz`](https://news.ycombinator.com/item?id=41687614) notes it was never fully Hotwire | [HN 41669615](https://news.ycombinator.com/item?id=41669615) |

### The single best failure story: Avo

The most instructive because it's a named product with a three-stack history and a founder who
liked Hotwire:

> `adrianthedev`, HN Nov 2021 (<https://news.ycombinator.com/item?id=29084243>): *"Avo was first a Rails-backed SPA... it didn't work out that well. In January, we re-wrote Avo with Hotwire... **it's a joy to write apps using Rails and Hotwire.** But the fact of the matter is that we need an app that's a bit more dynamic on the front-end than Hotwire can deliver... **The reason we chose to go with React is the ecosystem.**"*

### The Gumroad essay — and why crosswire should copy its *form*

Sahil Lavingia's "Why Gumroad Didn't Choose htmx" is published **on htmx.org**, by the
competing framework's author. That editorial choice is the model crosswire should follow.
Its five stated reasons: developer experience/intuition, UX limitations pushing toward
"boring and generic" CRUD, **AI/tooling support** (*"AI tools are intimately familiar with
Next.js and not so much with htmx, due to the lack of open-source training data. This is
similar to the issue Rails faces"* — an increasingly load-bearing 2026 argument), scalability
of complex interactions, and ecosystem maturity. The specific breaking points were drag-and-drop
workflow reordering, interdependent step configuration, dynamic form generation, and real-time
collaboration — which map almost exactly onto the escalation signals above.

### Honest critiques from people who stayed

- `hahahacorn`: *"There are many (but fewer than those who 'don't get' hotwire believe) cases where it's more of a headache to delegate state... My go-to is [turbo-mount] + react because it minimizes its footprint on the omakase-ness of your rails app."*
- `castaigne`: *"Stimulus is also great, but you can't go into it expecting React. State management can get very tedious... but I pull in Preact and HTM where I really need them."*
- `krschacht`: *"you can just drop a React/Swift/Kotlin view in for parts of the app where you need it."*

**The hybrid is the modal outcome.** Across the entire corpus, the most common end state is
neither pure Hotwire nor pure React — it is Hotwire with a small number of deliberate islands.
crosswire should present that as the expected destination, not as a failure to be pure.

### The HEY.com performance debate — report it as unresolved

Critics: *"if the experience of the Hey webapp is an example of the best of Hotwire, no fucking
thanks. On a slow connection, it's bad... Boxes open with no content."*
(<https://news.ycombinator.com/item?id=40558852>). Defenders argue the viral demo was
deliberately throttled and that the latency is server response time, not Turbo
(<https://news.ycombinator.com/item?id=43886195>). Present both; don't adjudicate.

---

## Coverage gaps in this research (stated so nobody over-reads it)

- **Reddit was inaccessible** this session (bot-walled on every attempt) — r/rails, r/ruby and
  r/experiencedevs are absent from the failure corpus. Not evidence of absence.
- `discuss.rubyonrails.org` was not reached.
- **No named large-company React→Hotwire case study with hard numbers appears to exist publicly.**
- **No published Writebook LOC figure.**
- **No article quantifies the "we cut N frontend engineers" economic claim.**
- No hard apples-to-apples flakiness/speed numbers for Rails system tests vs Vitest/RTL/Playwright-CT.
- No named-library "third-party JS + Turbo horror story" (Flatpickr/Chart.js class) was found —
  the general complaint is attested, specific cases weren't.
- The "Stimulus becomes spaghetti at scale" meme: the **substance** is attested by multiple
  practitioners in other words; **that exact framing was not found**. Report the substance.
