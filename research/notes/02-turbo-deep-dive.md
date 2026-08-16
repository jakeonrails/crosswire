# Turbo Deep Dive

> Research notes for **crosswire**. Written 2026-08-15.
>
> **Versions this document describes:**
> - `@hotwired/turbo` **8.0.23** (latest release, 2026-01-29). There is **no Turbo 9** as of this writing — the `9` in "Turbo 8/9-era" does not exist yet; 8.0.x is the current line and has been since Feb 2024.
> - `turbo-rails` gem **2.0.23** / npm `@hotwired/turbo-rails` **8.0.23**
> - `idiomorph` **~0.7.4** (bundled inside Turbo)
> - Rails **8.x** conventions assumed.
>
> Everything below was verified against the actual source of `hotwired/turbo` (`src/`) and
> `hotwired/turbo-rails` (`app/`, `lib/`), not just the docs. Where the published docs and the
> source disagree, **the source wins** and it is called out.

---

## Table of Contents

1. [Mental model & where each tool fits](#1-mental-model--where-each-tool-fits)
2. [Turbo Drive](#2-turbo-drive)
   - [2.1 What Drive intercepts (and what it refuses to)](#21-what-drive-intercepts-and-what-it-refuses-to)
   - [2.2 The visit lifecycle, step by step](#22-the-visit-lifecycle-step-by-step)
   - [2.3 Complete event reference](#23-complete-event-reference)
   - [2.4 Event ordering cheat sheets](#24-event-ordering-cheat-sheets)
   - [2.5 Visit actions: advance / replace / restore](#25-visit-actions-advance--replace--restore)
   - [2.6 Caching, preview snapshots, and the flash-of-old-content](#26-caching-preview-snapshots-and-the-flash-of-old-content)
   - [2.7 `data-turbo-permanent`](#27-data-turbo-permanent)
   - [2.8 `<head>` merging and `data-turbo-track`](#28-head-merging-and-data-turbo-track)
   - [2.9 Opting out: `data-turbo="false"`, form modes, root, extensions](#29-opting-out-data-turbofalse-form-modes-root-extensions)
   - [2.10 Form submissions: the 303 / 422 rules and WHY](#210-form-submissions-the-303--422-rules-and-why)
   - [2.11 `data-turbo-method`, `data-turbo-confirm`, `data-turbo-submits-with`](#211-data-turbo-method-data-turbo-confirm-data-turbo-submits-with)
   - [2.12 Prefetch on hover, preload, and the progress bar](#212-prefetch-on-hover-preload-and-the-progress-bar)
   - [2.13 Redirects and `turbo_stream` vs `html` negotiation](#213-redirects-and-turbo_stream-vs-html-negotiation)
   - [2.14 `Turbo.config` — the full surface](#214-turboconfig--the-full-surface)
3. [Turbo Frames](#3-turbo-frames)
4. [Turbo Streams](#4-turbo-streams)
5. [Turbo 8 morphing & page refreshes](#5-turbo-8-morphing--page-refreshes)
6. [View Transitions](#6-view-transitions)
7. [Turbo + Native (brief)](#7-turbo--native-brief)
8. [Testing Turbo in Rails](#8-testing-turbo-in-rails)
9. [Common failure modes & how to diagnose them](#9-common-failure-modes--how-to-diagnose-them)
10. [Gotchas & Sharp Edges](#gotchas--sharp-edges)
11. [Open Questions](#open-questions)

Primary sources used throughout:
- Handbook: <https://turbo.hotwired.dev/handbook/introduction>, `/drive`, `/page_refreshes`, `/frames`, `/streams`, `/native`, `/building`, `/installing`
- Reference: <https://turbo.hotwired.dev/reference/drive>, `/frames`, `/streams`, `/events`, `/attributes`
- Source: <https://github.com/hotwired/turbo> (`src/`), <https://github.com/hotwired/turbo-rails>
- 37signals: <https://dev.37signals.com/a-happier-happy-path-in-turbo-with-morphing/>, <https://dev.37signals.com/turbo-8-released/>
- Radan Skorić, "Turbo 8 morphing deep dive": <https://radan.dev/articles/turbo-morphing-deep-dive>

---

## 1. Mental model & where each tool fits

Turbo is three cooperating layers plus a rendering strategy:

| Layer | Unit of update | Triggered by | Server sends |
|---|---|---|---|
| **Drive** | whole `<body>` (+ merged `<head>`) | link clicks, form submits | a full HTML page |
| **Frames** | one `<turbo-frame id>` subtree | links/forms *inside* (or targeting) a frame | a full HTML page containing a matching frame |
| **Streams** | N arbitrary targets | form responses, WebSocket/SSE broadcasts | `<turbo-stream>` elements (`text/vnd.turbo-stream.html`) |
| **Morphing** | whole `<body>`, diffed | a *page refresh* (see §5) or `method="morph"` streams | a full HTML page |

Decision order I'd recommend for crosswire recipes:

1. **Plain Drive** — default. No attributes, no JS.
2. **Morphing page refreshes** (Turbo 8) — when the interaction re-renders "the current page" and you want to keep scroll/focus/CSS state. One meta tag, no per-element plumbing.
3. **Frames** — when a *region of the page has its own navigation* (inline edit, tabs, modal, pagination-in-place, independently cached fragment).
4. **Streams** — when one action must update *several disjoint* regions, or when updates arrive from *another user's* action over a socket.

> Handbook warning worth repeating: *"Turbo Frames do not contribute support to the usage of Turbo Stream. If your application utilizes `turbo-frame` elements for the sake of a `turbo-stream` element, change the `turbo-frame` into another built-in element."* — <https://turbo.hotwired.dev/handbook/frames>. Wrapping things in frames purely so you have a stream target is an anti-pattern; a `<div id="...">` is the correct target.

---

## 2. Turbo Drive

### 2.1 What Drive intercepts (and what it refuses to)

Drive installs a **capture-phase** `click` listener on `window` and a capture-phase `submit` listener on `document` (`src/observers/link_click_observer.js`, `src/observers/form_submit_observer.js`).

A click is "significant" only if **all** of these hold (`LinkClickObserver#clickEventIsSignificant`):

```js
!(event.target?.isContentEditable ||
  event.defaultPrevented ||
  event.which > 1 ||          // not a middle/right click
  event.altKey || event.ctrlKey || event.metaKey || event.shiftKey)
```

Then `findLinkFromClickTarget` (`src/util.js`) walks up (through shadow roots via `findClosestRecursively`) for `a[href], a[xlink\\:href]` and **returns null** if:

- the `href` starts with `#` (pure fragment links are *not* Turbo visits — they're native browser anchors),
- the link has `[download]`,
- the link has a `target` attribute that isn't `_self`.

Then `Session#willFollowLinkToLocation` requires:

- `elementIsNavigatable(link)` — see §2.9,
- `locationIsVisitable(location, rootLocation)` — same-origin, prefixed by `<meta name="turbo-root">`, and the extension is **not** in `Turbo.config.drive.unvisitableExtensions`,
- and the app didn't cancel `turbo:click`.

`unvisitableExtensions` (from `src/core/config/drive.js`) includes, notably: `.js .json .xml .csv .txt .css .svg .pdf .zip .png .jpg .gif .webp .mp4 .doc(x) .xls(x) .ppt(x)` and ~40 more. **A link to `/reports.csv` or `/api/thing.json` is deliberately handed to the browser, not Turbo.**

Form submits require `Session#submissionIsNavigatable` (respects `Turbo.config.forms.mode`) and are skipped when:

- `method="dialog"` (or `formmethod="dialog"`) — dialog dismissal,
- `target`/`formtarget` names an `<iframe>` on the page, or is `_blank`.

### 2.2 The visit lifecycle, step by step

Source: `src/core/session.js`, `src/core/drive/navigator.js`, `src/core/drive/visit.js`, `src/core/native/browser_adapter.js`.

```
click on <a href>
 └─ LinkClickObserver: significant? → findLinkFromClickTarget
     └─ Session#willFollowLinkToLocation
         ├─ dispatch  turbo:click              (cancelable — preventDefault ⇒ browser handles it)
         └─ Session#followedLinkToLocation → Turbo.visit(url, {action, acceptsStreamResponse})
             └─ Navigator#proposeVisit
                 ├─ dispatch  turbo:before-visit  (cancelable — preventDefault ⇒ no visit at all)
                 └─ BrowserAdapter#visitProposedToLocation → Navigator#startVisit → new Visit(...).start()
                     ├─ BrowserAdapter#visitStarted
                     │    ├─ visit.loadCachedSnapshot()   ← may render a PREVIEW
                     │    │    ├─ view.cacheSnapshot() ⇒ dispatch turbo:before-cache
                     │    │    └─ renderPage(snapshot, isPreview=true)
                     │    │         ├─ dispatch turbo:before-render (cancelable/pausable)
                     │    │         └─ dispatch turbo:render
                     │    └─ visit.issueRequest()
                     │         └─ FetchRequest#perform
                     │              ├─ dispatch turbo:before-fetch-request (cancelable/pausable)
                     │              ├─ window.fetch(...)  [+ header X-Turbo-Request-Id]
                     │              └─ dispatch turbo:before-fetch-response
                     └─ Session#visitStarted ⇒ dispatch turbo:visit
                        (also sets aria-busy="true" and data-turbo-visit-direction on <html>)
   ... response arrives ...
 └─ visit.loadResponse()
     ├─ 2xx + HTML → renderPage(snapshot, isPreview=false)
     │    ├─ prepareToRender: set <html lang/dir>, mergeHead()
     │    │    └─ tracked-element mismatch? ⇒ NO render; dispatch turbo:reload; window.location.href = url
     │    ├─ dispatch turbo:before-render  (cancelable/pausable; you may swap detail.render)
     │    ├─ replaceBody() inside Bardo (permanent-element transplant)
     │    ├─ dispatch turbo:render
     │    └─ performScroll()
     ├─ 4xx/5xx → ErrorRenderer replaces <head> AND <body>; visit.fail()
     └─ visit.complete() ⇒ Session#visitCompleted ⇒ dispatch turbo:load
        (clears aria-busy, removes data-turbo-visit-direction)
```

Key structural facts:

- **`<html>` and `window`/`document` persist** across visits. Only `<body>` is replaced and `<head>` is merged. This is why `DOMContentLoaded` fires once and `turbo:load` fires every time.
- Rendering is scheduled on `requestAnimationFrame` (or a `setTimeout(0)` if `document.visibilityState === "hidden"`), so `turbo:visit` fires *before* any preview paints.
- `turbo:load` also fires on the **initial** page load, from `PageObserver#pageBecameInteractive` (readyState `interactive`). So `turbo:load` = "a page is now live", initial or not.

### 2.3 Complete event reference

All Turbo events are dispatched via `src/util.js#dispatch` as `CustomEvent` with **`bubbles: true, composed: true`**. If the intended `target` is not connected to the document, the event is dispatched on `document.documentElement` instead. So `document.addEventListener("turbo:...")` always works.

#### Navigation / page lifecycle

| Event | Target | Cancelable | `event.detail` | Fires when / what you can do |
|---|---|---|---|---|
| `turbo:click` | the `<a>` | ✅ | `{ url, originalEvent }` | A Turbo-eligible link was clicked, before any visit is proposed. `preventDefault()` ⇒ let the browser navigate normally. Only place you still have the raw `MouseEvent`. |
| `turbo:before-visit` | `<html>` | ✅ | `{ url }` | Before an *application* visit starts. `preventDefault()` ⇒ cancel entirely. **Does not fire for restoration (back/forward) visits.** Good place for "unsaved changes?" guards. |
| `turbo:visit` | `<html>` | ❌ | `{ url, action }` | Visit has started (after adapter kickoff). `action` is `"advance" \| "replace" \| "restore"`. Good for showing your own loading chrome. |
| `turbo:before-cache` | `<html>` | ❌ | — | Immediately before the **current** page is cloned into the snapshot cache. **This is where you clean up transient DOM** so the cached preview isn't wrong (see §2.6). |
| `turbo:before-render` | `<html>` | ✅ | `{ newBody, resume, render, renderMethod }` | Before the new `<body>` replaces/morphs the old. `renderMethod` is `"replace"` or `"morph"`. Mutate `event.detail.newBody` freely. `preventDefault()` **pauses** rendering until you call `event.detail.resume()`. You can override the swap by assigning `event.detail.render = (current, next) => {…}`. |
| `turbo:render` | `<html>` | ❌ | `{ renderMethod }` | After the new body is in the DOM. **Fires twice per visit when a preview is shown** (once for preview, once for real). |
| `turbo:load` | `<html>` | ❌ | `{ url, timing }` | Visit fully completed (and on initial page load). `timing` has `visitStart / requestStart / requestEnd / visitEnd` (epoch ms); it's `{}` on the initial load. **Never fires for previews or for frame navigations.** |
| `turbo:reload` | `<html>` | ❌ | `{ reason, context? }` | Turbo gave up and is about to do `window.location.href = …`. `reason` ∈ `tracked_element_mismatch`, `turbo_visit_control_is_reload`, `request_failed`, `turbo_disabled`. **Best single hook for "why did my app hard-reload?"** |

#### HTTP layer

| Event | Target | Cancelable | `event.detail` | Notes |
|---|---|---|---|---|
| `turbo:before-fetch-request` | the `<turbo-frame>`, `<form>`, `<a>`, or `<html>` | ✅ | `{ fetchOptions, url, resume }` | Fires for **every** Turbo-issued request: visits, frame loads, form submits, prefetches, preloads. Mutate `fetchOptions.headers`, `fetchOptions.body`, or reassign `event.detail.url` (Turbo reads it back). `preventDefault()` pauses until `resume()`. This is how `turbo-rails` injects `_method` for `DELETE`/`PATCH`. |
| `turbo:before-fetch-response` | same | ✅ | `{ fetchResponse }` | After headers+body arrive, before Turbo interprets them. `preventDefault()` ⇒ Turbo stops handling the response (delegate gets `requestPreventedHandlingResponse`). **`StreamObserver` uses exactly this hook** to hijack any response whose `Content-Type` starts with `text/vnd.turbo-stream.html`. |
| `turbo:fetch-request-error` | same | ✅ | `{ request, error }` | Network-level failure (not HTTP error statuses). `preventDefault()` suppresses Turbo's own error handling. |
| `turbo:before-prefetch` | the `<a>` | ✅ | — | Before a hover-prefetch request is queued. `preventDefault()` ⇒ don't prefetch this link. |

#### Forms

| Event | Target | Cancelable | `event.detail` |
|---|---|---|---|
| `turbo:submit-start` | the `<form>` | ❌ | `{ formSubmission }` |
| `turbo:submit-end` | the `<form>` | ❌ | `{ formSubmission, success, fetchResponse }` or `{ formSubmission, success: false, error }` |

`formSubmission` exposes `formElement`, `submitter`, `method`, `action`, `body`, `enctype`, `isSafe`, `fetchRequest`, `location`.

`turbo:submit-start` fires *after* `turbo:before-fetch-request` (the request has already been prepared). `turbo:submit-end` fires in the `finally` of `FetchRequest#perform`, so it fires on success **and** failure. It is the correct place to re-enable custom UI.

#### Frames

| Event | Target | Cancelable | `event.detail` | Notes |
|---|---|---|---|---|
| `turbo:before-frame-render` | the `<turbo-frame>` | ✅ | `{ newFrame, resume, render, renderMethod }` | Same pause/override semantics as `turbo:before-render`. |
| `turbo:frame-render` | the `<turbo-frame>` | ✅ (per source) | `{ fetchResponse }` | Fires *before* `turbo:frame-load`. |
| `turbo:frame-load` | the `<turbo-frame>` | ❌ | — | Frame finished navigating. **This — not `turbo:load` — is your hook for frame content.** |
| `turbo:frame-missing` | the `<turbo-frame>` | ✅ | `{ response, visit }` | Response had no matching frame. `preventDefault()` ⇒ you handle it. `detail.visit(urlOrResponse, options)` lets you escalate to a full page visit. See §3.6. |

#### Streams

| Event | Target | Cancelable | `event.detail` |
|---|---|---|---|
| `turbo:before-stream-render` | the `<turbo-stream>` | ✅ **(source says `cancelable: true`; the published reference table says it isn't — trust the source)** | `{ newStream, render }` |

Override the action wholesale:

```js
document.addEventListener("turbo:before-stream-render", (event) => {
  const fallback = event.detail.render
  event.detail.render = async (streamElement) => {
    if (streamElement.action === "flash") { showToast(streamElement.getAttribute("message")); return }
    await fallback(streamElement)
  }
})
```

#### Morphing (Turbo 8)

| Event | Target | Cancelable | `event.detail` | Notes |
|---|---|---|---|---|
| `turbo:before-frame-morph` | the `<turbo-frame>` | ❌ | `{ currentElement, newElement }` | Only for frames morphed via `refresh="morph"` / `method="morph"`. |
| `turbo:before-morph-element` | the element being morphed | ✅ | `{ currentElement, newElement }` | `preventDefault()` ⇒ **skip this element and its subtree entirely.** The single most useful morph escape hatch. |
| `turbo:before-morph-attribute` | the element | ✅ | `{ attributeName, mutationType }` | `mutationType` is `"update"` or `"remove"`. `preventDefault()` ⇒ keep the current attribute value. |
| `turbo:morph-element` | the morphed element | ❌ | `{ currentElement, newElement }` | Per-element "done" hook. |
| `turbo:morph` | `<html>` | ❌ | `{ currentElement, newElement }` | Whole-page morph finished. |

### 2.4 Event ordering cheat sheets

**Plain link click, cache miss:**
```
turbo:click → turbo:before-visit → turbo:visit → turbo:before-cache
→ turbo:before-fetch-request → turbo:before-fetch-response
→ turbo:before-render → turbo:render → turbo:load
```

**Link click, cache HIT (preview shown):**
```
turbo:click → turbo:before-visit → turbo:visit → turbo:before-cache
→ turbo:before-fetch-request
→ turbo:before-render(preview) → turbo:render(preview)     ← old content painted!
→ turbo:before-fetch-response
→ turbo:before-render → turbo:render → turbo:load
```
Note: **two** `before-render`/`render` pairs. Guard with `document.documentElement.hasAttribute("data-turbo-preview")` if you must distinguish.

**Back button (restoration visit, cached):**
```
turbo:visit → turbo:before-cache → turbo:before-render → turbo:render → turbo:load
```
No `turbo:click`, **no `turbo:before-visit`**, and normally no fetch at all.

**Form submit → 422 re-render (validation error):**
```
turbo:before-fetch-request → turbo:submit-start → turbo:before-fetch-response
→ turbo:before-render → turbo:render → turbo:submit-end
```
The URL does **not** change and `turbo:load` does **not** fire (the failed-submission path calls `view.renderPage` directly, bypassing the Visit).

**Form submit → 303 redirect (success):**
```
turbo:before-fetch-request → turbo:submit-start → turbo:before-fetch-response
→ turbo:submit-end → turbo:before-visit → turbo:visit → turbo:before-cache
→ turbo:before-render → turbo:render → turbo:load
```

**Form submit → turbo_stream response:**
```
turbo:before-fetch-request → turbo:submit-start
→ turbo:before-fetch-response  (StreamObserver calls preventDefault())
→ turbo:before-stream-render × N
→ turbo:submit-end
```
No `turbo:load`, no `turbo:render`, no URL change. **This is the #1 source of "my JS doesn't run after a stream update."**

**Frame navigation:**
```
turbo:click → turbo:before-fetch-request → turbo:before-fetch-response
→ turbo:before-frame-render → turbo:frame-render → turbo:frame-load
```
No `turbo:visit`, no `turbo:load` — *unless* `data-turbo-action` promotes it, in which case a Visit is also proposed afterward.

### 2.5 Visit actions: advance / replace / restore

| Action | History | Issues request? | Set by |
|---|---|---|---|
| `advance` | `history.pushState` | yes | default for link clicks and successful form redirects |
| `replace` | `history.replaceState` | yes | `data-turbo-action="replace"`, or a redirect back to the *same* URL |
| `restore` | none (browser already moved) | **only if no cached snapshot** | `popstate` (Back/Forward) |

```erb
<%# Don't add a history entry for this filter link %>
<%= link_to "Only open", tickets_path(status: :open), data: { turbo_action: "replace" } %>
```

```js
Turbo.visit("/inbox")                       // advance
Turbo.visit("/inbox", { action: "replace" })
Turbo.visit("/messages/1", { frame: "message_1" })  // drives a frame instead of the page
```

Restoration visits also restore scroll position from `History#restorationData` (`{ scrollPosition: {x, y} }`, updated on every `scroll` event). Turbo sets `history.scrollRestoration = "manual"` once the page is `complete` and hands it back on `pagehide`.

`data-turbo-visit-direction` is set on `<html>` for the duration of a visit: `"forward"` (advance), `"back"` (restore), `"none"` (replace). Useful for CSS-driven directional transitions.

Two more redirect-related niceties from `Navigator#getDefaultAction`: if a form's response redirects to *the URL you're already on*, the action becomes `replace` rather than `advance` — so a failed-then-retried form doesn't stack history entries.

### 2.6 Caching, preview snapshots, and the flash-of-old-content

**How it works** (`src/core/drive/page_view.js`, `snapshot_cache.js`, `visit.js`):

- Turbo keeps an **LRU cache of 10 page snapshots**, keyed by URL *with the fragment stripped* (`toCacheKey`).
- On starting a visit, Turbo caches the page you are *leaving* (dispatching `turbo:before-cache` first), then — if the *destination* is in the cache — **immediately renders that stale snapshot as a "preview"** while the network request is still in flight.
- During a preview, `<html>` carries `data-turbo-preview`.
- The preview render is a real render: `turbo:before-render` + `turbo:render` fire, body scripts execute, Stimulus controllers connect.

**Snapshot cloning is lossy on purpose** (`PageSnapshot#clone`):
- `<select>` selections are copied over explicitly,
- `input[type=password]` values are **cleared**,
- stylesheets inside `<noscript>` are stripped.

Everything else — text input values, open `<details>`, third-party widget DOM, class toggles — is cached **as-is**. That is the flash-of-old-content problem: you navigate away with a modal open, come back, and the modal is briefly open again.

**Fixes, in order of preference:**

1. **Mark transient nodes `data-turbo-temporary`.** `CacheObserver` removes every `[data-turbo-temporary]` element on `turbo:before-cache`. Perfect for flash messages.

   ```erb
   <% flash.each do |type, message| %>
     <div class="flash flash--<%= type %>" data-turbo-temporary><%= message %></div>
   <% end %>
   ```

2. **Clean up in `turbo:before-cache`.** Idempotent teardown of anything stateful:

   ```js
   document.addEventListener("turbo:before-cache", () => {
     // close dialogs
     document.querySelectorAll("dialog[open]").forEach((d) => d.close())
     // collapse disclosure widgets
     document.querySelectorAll("details[open]").forEach((d) => d.removeAttribute("open"))
     // reset any submit buttons stuck in their "submitting" text
     document.querySelectorAll("[aria-busy=true]").forEach((el) => el.removeAttribute("aria-busy"))
     // tear down third-party widgets that don't survive cloning
     document.querySelectorAll("[data-chart-initialized]").forEach((el) => {
       el.removeAttribute("data-chart-initialized")
       el.replaceChildren()
     })
   })
   ```

   Stimulus equivalent — do it in `disconnect()`, which fires when the body is swapped anyway.

3. **Opt the page out of previews** (still cached, so Back is instant, but never shown stale):

   ```erb
   <% turbo_exempts_page_from_preview %>   <%# <meta name="turbo-cache-control" content="no-preview"> %>
   ```

4. **Opt the page out of caching entirely** (nothing to flash, but Back re-fetches):

   ```erb
   <% turbo_exempts_page_from_cache %>     <%# <meta name="turbo-cache-control" content="no-cache"> %>
   ```

   Both helpers live in `Turbo::DriveHelper` and use `provide :head`, so your layout needs `<%= yield :head %>` inside `<head>`. `_tag` variants (`turbo_exempts_page_from_cache_tag`) return the bare `<meta>` if you'd rather place it yourself. **They are mutually exclusive** — the underlying meta tag holds one value.

JS equivalents:

```js
Turbo.cache.clear()                  // nuke the snapshot cache
Turbo.cache.exemptPageFromCache()    // sets <meta name="turbo-cache-control" content="no-cache">
Turbo.cache.exemptPageFromPreview()  // ... content="no-preview"
Turbo.cache.resetCacheControl()      // ... content=""
```

> **Outdated advice flag:** `Turbo.clearCache()` (top-level) is deprecated in Turbo 8 and logs a warning; use `Turbo.cache.clear()`. Likewise `Turbo.setProgressBarDelay()`, `Turbo.setConfirmMethod()`, `Turbo.setFormMode()` are all deprecated in favour of `Turbo.config.*`.

**Cache invalidation you get for free:** any non-idempotent form submission clears the entire snapshot cache (`Navigator#formSubmissionSucceededWithResponse` → `view.clearSnapshotCache()` when `!isSafe`). Frame form submissions do the same via `session.clearCache()`.

### 2.7 `data-turbo-permanent`

An element with **both an `id` and `data-turbo-permanent`** is transplanted, DOM node and all, from the old page into the new one — preserving event listeners, media playback, scroll position, and focus.

```erb
<div id="audio-player" data-turbo-permanent>
  <audio src="<%= @track.url %>" controls></audio>
</div>
```

Mechanics (`src/core/bardo.js`, `src/core/renderer.js`):
1. Before the swap, for each `[id][data-turbo-permanent]` in the **current** page that also exists **by the same id** in the **new** page, Turbo replaces the new page's copy with a `<meta name="turbo-permanent-placeholder" content="<id>">`.
2. It swaps the body.
3. It puts the *original live node* back where the placeholder was.
4. Focus inside the permanent element is restored afterwards.

Consequences:
- **The element must exist in both documents, with the same `id`.** If the new page omits it, it is simply gone.
- **The server-rendered contents of the new page's copy are discarded.** A permanent element never updates from a Drive navigation. If you need it to change, update it with a Turbo Stream or `Turbo.morphElements`.
- Turbo Streams honour permanence too: `StreamMessageRenderer` runs the same Bardo dance over stream fragments.
- **Morphing does NOT use Bardo** — `MorphingPageRenderer#preservingPermanentElements` is a no-op. Permanence during a morph is enforced by idiomorph callbacks instead: `beforeNodeMorphed` returns `false` for `[data-turbo-permanent]`, and `beforeNodeAdded` refuses to add a node that has an id + `data-turbo-permanent` and already exists. Net effect is the same ("don't touch it"), but the *mechanism* differs — which is why some third-party widgets behave differently under morph vs replace.

### 2.8 `<head>` merging and `data-turbo-track`

`PageRenderer#mergeHead` is precise, and worth knowing:

- **Tracked elements** (`data-turbo-track="reload"`): Turbo builds a signature by concatenating the `outerHTML` of every tracked head element. If old ≠ new, **Turbo refuses to render**, dispatches `turbo:reload` with `reason: "tracked_element_mismatch"`, and does `window.location.href = url` — a real browser reload. This is the standard "we deployed new assets, force everyone onto them" mechanism:

  ```erb
  <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
  <%= javascript_importmap_tags %>  <%# importmap-rails already adds data-turbo-track="reload" %>
  ```

  The signature is computed from full `outerHTML`, so **digest-stamped asset URLs are what make this work.** In development with unfingerprinted assets, nothing changes and nothing reloads.

- **`data-turbo-track="dynamic"`** (underdocumented): head *stylesheets* carrying this attribute that are **absent from the new page's head are removed**. Use it for page-specific stylesheets that shouldn't accumulate. It does *not* trigger reloads.

- **New stylesheets** in the incoming head are appended and **awaited** (up to a 2000 ms timeout per element) before the body swaps, so you don't get a flash of unstyled content.

- **New head scripts** are appended and executed **once**; they are never removed on subsequent navigations. Head scripts that already exist (identical `outerHTML`, `nonce` normalised away) are not re-executed.

- **"Provisional" head elements** — anything that isn't a script or stylesheet and isn't tracked (`<title>`, `<meta>`, `<link rel=canonical>`, …) — are removed from the current head if absent in the new head, and the new ones are appended. `<title>` is compared by `innerHTML`.

- **Body scripts re-execute on every render** (`activateNewBodyScriptElements` clones each `<script>` into a fresh element). This is why Turbo warns you at load time if `turbo.js` itself is in `<body>` (`src/script_warning.js`). Suppress with `data-turbo-suppress-warning`, opt an individual script out of re-evaluation with `data-turbo-eval="false"`.

  ```html
  <head>
    <script src="/assets/application-cbd3cd4.js" data-turbo-track="reload" defer></script>
  </head>
  ```

### 2.9 Opting out: `data-turbo="false"`, form modes, root, extensions

```html
<a href="/legacy" data-turbo="false">Escape hatch</a>
<div data-turbo="false"> …everything in here bypasses Turbo… </div>
```

`Session#elementIsNavigatable` semantics (this is subtler than the docs suggest):

```js
const container  = findClosestRecursively(element, "[data-turbo]")   // pierces shadow DOM
const withinFrame = findClosestRecursively(element, "turbo-frame")

if (config.drive.enabled || withinFrame) {
  return container ? container.getAttribute("data-turbo") != "false" : true
} else {
  return container ? container.getAttribute("data-turbo") == "true" : false
}
```

Two things fall out of this:

1. **`data-turbo="false"` does NOT disable Turbo inside a `<turbo-frame>`.** The `|| withinFrame` clause means frames stay live even with Drive globally off; and the *nearest* `[data-turbo]` ancestor wins, so an inner `data-turbo="true"` re-enables inside a `data-turbo="false"` region.
2. Global opt-out inverts the default:

   ```js
   import "@hotwired/turbo-rails"
   Turbo.session.drive = false          // === Turbo.config.drive.enabled = false
   ```
   Then only `[data-turbo="true"]` subtrees are driven.

**Form-specific mode** — `Turbo.config.forms.mode`:

| Value | Behaviour |
|---|---|
| `"on"` (default) | all eligible forms are Turbo-submitted |
| `"off"` | Turbo never intercepts form submits |
| `"optin"` | only forms inside `[data-turbo="true"]` are intercepted |

**Root location** — restrict Turbo to a path prefix (handy when Rails is mounted under `/app` next to a legacy app):

```erb
<meta name="turbo-root" content="/app">
```

Anything not prefixed by the root is handed to the browser.

**Force a full reload for a whole page**, e.g. a sign-in page reached via an expired session:

```erb
<% turbo_page_requires_reload %>   <%# <meta name="turbo-visit-control" content="reload"> %>
```

Turbo will refuse to render this document and hard-navigate instead (`turbo:reload`, `reason: "turbo_visit_control_is_reload"`). It also makes a Turbo **Frame** that receives such a page escalate to a full page visit (with a `console.warn`) instead of showing "Content missing" — see §3.6.

### 2.10 Form submissions: the 303 / 422 rules and WHY

This is the part people get wrong most often, so here's the actual decision tree from `src/core/drive/form_submission.js#requestSucceededWithResponse` + `src/core/drive/navigator.js`:

```
response 4xx (clientError)  → formSubmissionFailedWithResponse
                              → view.renderPage(snapshot)  ← renders IN PLACE, URL unchanged
response 5xx (serverError)  → formSubmissionFailedWithResponse
                              → view.renderError(snapshot) ← replaces <head> AND <body>
response 2xx AND redirected → propose a Visit to fetchResponse.location  ✅ the happy path
response 200 AND NOT redirected AND method != GET
                            → Error("Form responses must redirect to another location")
                              ← console error, NOTHING renders. The classic silent failure.
```

#### Why `status: :unprocessable_entity` (422) is required for validation errors

Turbo only re-renders a form response **in place** when the status is 4xx or 5xx. A `200 OK` that isn't a redirect is treated as a programming error, so this — the pre-Turbo Rails idiom — **does nothing visible**:

```ruby
# ❌ BROKEN under Turbo
def create
  @post = Post.new(post_params)
  if @post.save
    redirect_to @post
  else
    render :new                      # 200 OK, not a redirect → Turbo throws it away
  end
end
```

```ruby
# ✅ Rails 8 scaffold idiom
def create
  @post = Post.new(post_params)
  if @post.save
    redirect_to @post, notice: "Post created", status: :see_other
  else
    render :new, status: :unprocessable_content   # 422
  end
end
```

> **Currency note (Rails 8 / Rack 3.1+):** Rack 3.1 renamed 422 from *Unprocessable Entity* to *Unprocessable Content*. `:unprocessable_entity` still resolves to 422 but is a **deprecated alias** and emits a Rack deprecation warning on Rack ≥ 3.2. On Rails 7.2/8+, prefer **`:unprocessable_content`**. Older tutorials and most existing Rails apps say `:unprocessable_entity`; both work today. (Sources: <https://github.com/rails/rails/pull/53383>, <https://github.com/rails/rails/issues/55603>.)

#### Why `status: :see_other` (303) is required for non-GET redirects

Turbo submits with `fetch(..., { redirect: "follow" })`. The browser follows the redirect *for you*, and the method it uses depends on the status code:

| Status | Browser behaviour on redirect after a `DELETE`/`PATCH`/`PUT` |
|---|---|
| `301` / `302` | Historically converts POST→GET, but for `PUT`/`PATCH`/`DELETE` the spec says **preserve the method** — so you get `DELETE /posts` on the index. 💥 |
| `307` / `308` | Explicitly preserves the method. 💥 |
| **`303 See Other`** | Explicitly means "GET this other resource". ✅ |

Rails' `redirect_to` defaults to **302**, which is fine after a `POST` (browsers downgrade to GET) but wrong after `PATCH`/`PUT`/`DELETE`. Hence the Rails 7+ scaffold convention:

```ruby
def update
  if @post.update(post_params)
    redirect_to @post, notice: "Updated", status: :see_other
  else
    render :edit, status: :unprocessable_content
  end
end

def destroy
  @post.destroy!
  redirect_to posts_path, notice: "Deleted", status: :see_other
end
```

**Rule of thumb: every `redirect_to` reached from a non-GET action should carry `status: :see_other`.** It is harmless after POST and mandatory after PATCH/PUT/DELETE.

#### Form submission requirements checklist

- CSRF: Turbo reads `<meta name="csrf-param">`/`<meta name="csrf-token">` and sets `X-CSRF-Token` on unsafe requests. `<%= csrf_meta_tags %>` must be in your layout. (Note that `turbo_rails/frame.html.erb`, the frame-request layout, includes `csrf_meta_tags` for exactly this reason.)
- `Accept` header on unsafe submissions is `text/vnd.turbo-stream.html, text/html, application/xhtml+xml` — so `respond_to { |f| f.turbo_stream ... f.html ... }` works out of the box.
- Safe (GET) submissions do **not** ask for turbo streams unless the form or submitter has `data-turbo-stream`.
- GET form submissions have their query string rebuilt from the form data (`getAction` clears `action.search` for safe methods).
- File inputs: multipart bodies are passed through untouched; for GET, `File` entries are silently dropped from the query string.
- The submitter's `name`/`value` is appended to the FormData manually (Turbo builds `new FormData(form)` itself), and `formaction` / `formmethod` / `formenctype` on the submitter are honoured.

### 2.11 `data-turbo-method`, `data-turbo-confirm`, `data-turbo-submits-with`

#### `data-turbo-method`

```erb
<%= link_to "Delete", post_path(@post),
      data: { turbo_method: :delete, turbo_confirm: "Are you sure?" } %>
```

How it actually works (`src/observers/form_link_click_observer.js`): Turbo intercepts the click, **builds a hidden `<form>`** in `document.body` with the link's URL as `action`, copies over `data-turbo-frame` / `data-turbo-action` / `data-turbo-confirm` / `data-turbo-stream`, converts query params into hidden inputs, calls `form.requestSubmit()`, and removes the form on `turbo:submit-end`.

Then `turbo-rails`' `encodeMethodIntoRequestBody` (registered on `turbo:before-fetch-request`) rewrites anything that isn't GET/POST into `POST` + `_method=<verb>` in the body, which is what Rails' `Rack::MethodOverride` expects.

**Accessibility caveat:** this makes an `<a>` behave like a form. It is not announced as a button, it isn't keyboard-activatable in the same way, and it breaks without JS. Prefer `button_to`:

```erb
<%= button_to "Delete", post_path(@post), method: :delete,
      form: { data: { turbo_confirm: "Are you sure?" } } %>
```

`button_to` emits a real `<form method="post">` with `_method=delete` — works with JS off, works with Turbo, correct semantics.

#### `data-turbo-confirm`

```erb
<%= button_to "Delete account", account_path, method: :delete,
      form: { data: { turbo_confirm: "This cannot be undone. Type-check yourself." } } %>
```

Read via `getAttribute("data-turbo-confirm", submitter, formElement)` — **submitter wins over form**, so different buttons in one form can have different confirmations.

Replace the browser `confirm()` with your own dialog:

```js
// app/javascript/confirm.js
Turbo.config.forms.confirm = async (message, formElement, submitter) => {
  const dialog = document.getElementById("confirm-dialog")
  dialog.querySelector("[data-message]").textContent = message
  dialog.showModal()
  return new Promise((resolve) => {
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "confirm"), { once: true })
  })
}
```

The signature is `(message, formElement, submitter) => Promise<boolean> | boolean`. (Deprecated: `Turbo.setConfirmMethod(fn)`.)

#### `data-turbo-submits-with`

```erb
<%= form_with model: @post do |f| %>
  <%= f.submit "Save", data: { turbo_submits_with: "Saving…" } %>
<% end %>
```

On `turbo:submit-start`, Turbo swaps `button.innerHTML` (or `input.value`) to the given text and restores the original on `turbo:submit-end`. It goes on the **submitter**, not the form.

Independently, `Turbo.config.forms.submitter` controls how the submitter is disabled during submission:

```js
Turbo.config.forms.submitter = "disabled"      // default: submitter.disabled = true
Turbo.config.forms.submitter = "aria-disabled" // sets aria-disabled + swallows clicks; keeps focus & keeps
                                               // the button in the form data. Better for a11y.
// or fully custom:
Turbo.config.forms.submitter = {
  beforeSubmit: (el) => el.classList.add("is-busy"),
  afterSubmit:  (el) => el.classList.remove("is-busy")
}
```

> ⚠️ With the default `"disabled"` strategy, the submitter's `name`/`value` **is still included** (Turbo appends it to FormData before disabling), so `params[:commit]` still works. But the button loses focus, which screen-reader users notice. `"aria-disabled"` is the a11y-friendlier choice.

Also set automatically during submission: `aria-busy="true"` on the `<form>` (and on the enclosing frame), plus `busy` on `<turbo-frame>`.

```css
form[aria-busy="true"] { opacity: .6; pointer-events: none; }
turbo-frame[busy] .spinner { display: block; }
```

### 2.12 Prefetch on hover, preload, and the progress bar

#### Prefetch on hover (a.k.a. "instant click") — on by default since Turbo 8

`src/observers/link_prefetch_observer.js` + `src/core/drive/prefetch_cache.js`:

- Listens for `mouseenter` (capture, passive) on `a[href]:not([target^=_]):not([download])`.
- Waits **100 ms** (`PREFETCH_DELAY`), then issues a `GET` with `priority: "low"` and header **`X-Sec-Purpose: prefetch`**.
- Caches the in-flight `FetchRequest` for **10 s** (`cacheTtl`) — and the cache holds **exactly one entry** (`new PrefetchCache()` → LRU size 1).
- On `mouseleave` before the request fires, it's cancelled.
- On the real `turbo:before-fetch-request` for that URL, the cached request's response is reused.
- If the link targets a frame, a `Turbo-Frame` header is added to the prefetch so the server can render the frame layout.

**Not prefetched:** cross-origin, non-http(s), links with `target`, links to the current page, `#`-only hrefs, `data-turbo-method` ≠ GET, `data-turbo-confirm`, `data-turbo-stream`, and legacy UJS attributes (`data-remote`, `data-method`, `data-confirm`, `data-behavior`).

**Disabling:**

```erb
<%# globally %>
<meta name="turbo-prefetch" content="false">

<%# per link (or any ancestor) %>
<%= link_to "Expensive report", report_path, data: { turbo_prefetch: false } %>
<div data-turbo-prefetch="false"> … </div>
```

```js
// programmatically
document.addEventListener("turbo:before-prefetch", (event) => {
  if (event.target.dataset.destructive) event.preventDefault()
})
```

Tune the TTL:

```erb
<meta name="turbo-prefetch-cache-time" content="5000">  <%# ms; default 10000 %>
```

> ⚠️ **Prefetch fires real GETs against your server.** Any GET endpoint with side effects (counters, "mark as read", one-time tokens, expensive report generation) will be hit on hover. Guard with `data-turbo-prefetch="false"`, or check `request.headers["X-Sec-Purpose"] == "prefetch"` server-side:
>
> ```ruby
> def prefetch_request? = request.headers["X-Sec-Purpose"] == "prefetch"
> ```
>
> Note there is **no `Turbo.config.drive.prefetch` flag in 8.0.23** — configuration is meta-tag / attribute only.

#### `data-turbo-preload`

```erb
<%= link_to "Dashboard", dashboard_path, data: { turbo_preload: true } %>
```

`src/core/drive/preloader.js` fetches these on page load (and after every render) and stashes a full `PageSnapshot` in the snapshot cache — so clicking is an instant cache hit with no network. Skipped for links with `data-turbo-method`, `data-turbo-stream`, or links that target a frame.

Use sparingly: every preloaded link is an unconditional request on every page render.

#### Progress bar

- Element: `<div class="turbo-progress-bar">` inserted before `<body>`; the injected stylesheet element has id-less `<style>` but the CSS class is `.turbo-progress-bar`.
- Shown **after a delay** (default 500 ms) so fast navigations don't flicker. Restoration visits with no cached snapshot show it immediately.
- Shown for form submissions too.
- Default look: 3px, `#0076ff`, `position: fixed; top: 0`, `z-index: 2147483647`, width animates `10% → 100%` with random "trickle".

```js
Turbo.config.drive.progressBarDelay = 200   // ms  (deprecated: Turbo.setProgressBarDelay)
```

```css
/* Override — your rule must beat the injected <style> which is inserted FIRST in <head>,
   so any stylesheet you load later wins on equal specificity. */
.turbo-progress-bar {
  height: 4px;
  background: linear-gradient(to right, #7c3aed, #ec4899);
}
```

To suppress it for one navigation, listen for `turbo:before-fetch-request` and… actually there's no supported per-visit toggle; set `progressBarDelay` to a very large number around the operation, or hide via CSS scoped to a body class you toggle.

### 2.13 Redirects and `turbo_stream` vs `html` format negotiation

**How Turbo asks:**

| Request | `Accept` header |
|---|---|
| Drive visit (GET) | `text/html, application/xhtml+xml` |
| Link with `data-turbo-stream` | `text/vnd.turbo-stream.html, text/html, application/xhtml+xml` |
| Form POST/PATCH/PUT/DELETE | `text/vnd.turbo-stream.html, text/html, application/xhtml+xml` |
| Frame navigation | as above **plus** `Turbo-Frame: <frame-id>` |
| Prefetch / preload | as above plus `X-Sec-Purpose: prefetch` |

**How Turbo decides what it got:** `StreamObserver` listens on `turbo:before-fetch-response` and, if `Content-Type` starts with `text/vnd.turbo-stream.html`, calls `preventDefault()` and renders the streams. Otherwise the normal Drive/Frame path runs.

**Rails side:**

```ruby
class PostsController < ApplicationController
  def create
    @post = Post.new(post_params)

    if @post.save
      respond_to do |format|
        format.turbo_stream          # renders create.turbo_stream.erb
        format.html { redirect_to @post, status: :see_other }
      end
    else
      render :new, status: :unprocessable_content
    end
  end
end
```

`format.turbo_stream` works because the engine registers the MIME type and a renderer:

```ruby
# turbo-rails/lib/turbo/engine.rb
Mime::Type.register "text/vnd.turbo-stream.html", :turbo_stream
ActionController::Renderers.add :turbo_stream do |turbo_streams_html, options|
  self.content_type = Mime[:turbo_stream] if media_type.nil?
  turbo_streams_html
end
```

**Progressive-enhancement rule:** always supply the `format.html` branch. It's what non-JS clients, Turbo Native, and (importantly) *your integration tests* hit.

**Making a link ask for streams:**

```erb
<%= link_to "Mark all read", mark_all_read_path,
      data: { turbo_method: :post, turbo_stream: true } %>
```

### 2.14 `Turbo.config` — the full surface

Introduced in Turbo 8.0.6; the flat setters are deprecated.

```js
Turbo.config.drive.enabled              // boolean, default true
Turbo.config.drive.progressBarDelay     // ms, default 500
Turbo.config.drive.unvisitableExtensions // Set<string>, ~50 entries

Turbo.config.forms.mode                 // "on" | "off" | "optin"
Turbo.config.forms.submitter            // "disabled" | "aria-disabled" | { beforeSubmit, afterSubmit }
Turbo.config.forms.confirm              // (message, form, submitter) => boolean | Promise<boolean>
```

Other top-level API (`src/core/index.js`, `src/index.js`):

```js
Turbo.start()
Turbo.visit(location, options)
Turbo.session                    // the Session instance
Turbo.navigator                  // session.navigator (renamed on export to avoid shadowing window.navigator)
Turbo.cache                      // { clear, resetCacheControl, exemptPageFromCache, exemptPageFromPreview }
Turbo.registerAdapter(adapter)
Turbo.connectStreamSource(source)
Turbo.disconnectStreamSource(source)
Turbo.renderStreamMessage(html)
Turbo.StreamActions              // register custom stream actions here
Turbo.morphElements(current, next)
Turbo.morphChildren(current, next)
Turbo.morphBodyElements(currentBody, newBody)
Turbo.morphTurboFrameElements(currentFrame, newFrame)
Turbo.session.pageRefreshDebouncePeriod = 150   // ms
```

---

## 3. Turbo Frames

### 3.1 The contract

A `<turbo-frame id="X">` says: *any link click or form submit inside me produces a response; find `<turbo-frame id="X">` in that response and swap my children for its children. Don't touch the rest of the page. Don't change the URL.*

```erb
<%# app/views/posts/show.html.erb %>
<%= turbo_frame_tag @post do %>
  <h2><%= @post.title %></h2>
  <%= link_to "Edit", edit_post_path(@post) %>
<% end %>

<%# app/views/posts/edit.html.erb %>
<%= turbo_frame_tag @post do %>
  <%= render "form", post: @post %>
  <%= link_to "Cancel", post_path(@post) %>
<% end %>
```

`turbo_frame_tag` (`Turbo::FramesHelper`) resolves ids via `ActionView::RecordIdentifier.dom_id`:

```erb
<%= turbo_frame_tag "tray" %>                          <%# id="tray" %>
<%= turbo_frame_tag @post %>                           <%# id="post_1" %>
<%= turbo_frame_tag Post %>                            <%# id="new_post" %>
<%= turbo_frame_tag @post, "comments" %>               <%# id="comments_post_1" %>
<%= turbo_frame_tag [current_user.id, "tray"] %>       <%# id="1_tray" %>
<%= turbo_frame_tag "tray", src: tray_path %>          <%# src is run through url_for %>
<%= turbo_frame_tag "tray", src: tray_path, loading: :lazy, target: "_top" %>
```

**The id must be identical on both sides.** `dom_id` on the same record guarantees this, which is why the helper takes records — that convention *is* the frame contract.

### 3.2 Eager vs lazy loading

```erb
<%# eager: fetched as soon as the element connects %>
<%= turbo_frame_tag "sidebar", src: sidebar_path do %>
  <div class="skeleton">Loading…</div>
<% end %>

<%# lazy: fetched when it scrolls into view (IntersectionObserver) %>
<%= turbo_frame_tag "comments", src: post_comments_path(@post), loading: :lazy do %>
  <div class="skeleton">Loading comments…</div>
<% end %>
```

- Contents you put inside a `src` frame are the **placeholder**; they are replaced on load.
- `loading="lazy"` is powered by `AppearanceObserver` (IntersectionObserver). It fires on *first* intersection, including a frame inside a `display:none` container that later becomes visible — the canonical "load the modal body only when the modal opens" trick.
- Setting `loading="eager"` on an already-lazy frame triggers an immediate load (`loadingStyleChanged`).
- A frame is "done" when it has the `complete` attribute; `frame.loaded` is a Promise; `frame.complete` is a boolean getter.

**Caching win:** a lazy/eager frame carves the personalised bit out of an otherwise publicly cacheable page:

```erb
<%# cache the whole page for everyone… %>
<% cache @article do %>
  <%= render @article %>
<% end %>
<%# …except this, which is per-user %>
<%= turbo_frame_tag "user_toolbar", src: toolbar_path %>
```

### 3.3 Targeting: `data-turbo-frame`, `target`, `_top`, `_parent`

Resolution order in `FrameController#findFrameElement`:

```js
const id = getAttribute("data-turbo-frame", submitter, element) || this.element.getAttribute("target")
```

1. `data-turbo-frame` on the **submitter** (button) — highest precedence,
2. `data-turbo-frame` on the **link/form**,
3. `target` on the enclosing `<turbo-frame>` — the frame's default,
4. otherwise the enclosing frame itself.

| Value | Meaning |
|---|---|
| `some_id` | drive the frame with that id (anywhere in the document) |
| `_top` | **break out**: do a full-page Turbo Drive visit |
| `_parent` | drive the *enclosing* frame of this frame (`element.parentElement.closest("turbo-frame")`) — **real, works, barely documented** |

```erb
<%# every link in this frame drives the page, not the frame %>
<%= turbo_frame_tag "results", target: "_top" do %> … <% end %>

<%# one link escapes an otherwise self-contained frame %>
<%= link_to "Open full page", post_path(@post), data: { turbo_frame: "_top" } %>

<%# a link inside a frame that drives a DIFFERENT frame %>
<%= link_to "Preview", preview_path(@post), data: { turbo_frame: "preview_pane" } %>

<%# a nested frame that drives its parent when the inner action completes %>
<%= link_to "Done", post_path(@post), data: { turbo_frame: "_parent" } %>
```

**Links *outside* any frame can still drive a frame** — that's `FrameRedirector` (`src/core/frames/frame_redirector.js`), which watches the whole document for `[data-turbo-frame]` on links/forms and routes them into the named frame. This is the modal-trigger pattern.

### 3.4 Promoting a frame navigation to a page visit (`data-turbo-action`)

By default frame navigation doesn't touch the URL or history. Add `data-turbo-action` to change that:

```erb
<%# every navigation inside this frame also pushes a history entry %>
<%= turbo_frame_tag "results", data: { turbo_action: "advance" } do %>
  <%= render @results %>
  <%= paginate @results %>
<% end %>

<%# or per-link %>
<%= link_to "Next", posts_path(page: 2), data: { turbo_frame: "results", turbo_action: "advance" } %>
```

Mechanically (`FrameController#proposeVisitIfNavigatedWithAction`): Turbo snapshots the current page, lets the frame render, then proposes a Visit to `frame.src` with `willRender: false, updateHistory: false` and a `visitCachedSnapshot` callback that stitches the *new* frame contents into the *cached* page snapshot. Net result: URL updates, Back works, and Back restores the page with the correct frame contents.

**Requirement:** the frame's `src` URL must be a real, standalone page URL that renders the same frame. If `/posts?page=2` renders nothing sensible on a full page load, Back/refresh will be broken.

### 3.5 Nested frames and `recurse`

Nesting works: the innermost frame wins for links inside it (`LinkInterceptor#clickEventIsSignificant` checks `element.closest("turbo-frame, html") == this.element`), and `FormSubmitObserver` requires `element.closest("turbo-frame") == this.element`.

`recurse` is an escape hatch for the case where the frame you want is *inside another lazy frame* in the response:

```html
<turbo-frame id="outer" src="/outer" recurse="inner">
  <turbo-frame id="inner">…</turbo-frame>
</turbo-frame>
```

`FrameController#extractForeignFrameElement` first looks for `turbo-frame#inner`; failing that, it looks for `turbo-frame[src][recurse~=inner]`, **awaits that frame's own load**, and searches again inside it. Rarely needed; useful for deeply-nested lazily-loaded shells.

`recurse` also has a second effect: on `disconnect()`, a frame with `[recurse]` does **not** cancel its in-flight request.

### 3.6 "Content missing" — what it means and how to debug it

When a frame's response contains no `<turbo-frame>` with a matching id:

1. Turbo sets `complete` on the frame.
2. Dispatches **`turbo:frame-missing`** (cancelable) with `{ response, visit }`.
3. If not prevented: writes `<strong class="turbo-frame-error">Content missing</strong>` into the frame and **throws `TurboFrameMissingError`** with:
   > `The response (<status>) did not contain the expected <turbo-frame id="X"> and will be ignored. To perform a full page visit instead, set turbo-visit-control to reload.`

**Debug checklist, in order:**

| Cause | Check | Fix |
|---|---|---|
| id mismatch | View source of the response; compare `<turbo-frame id>` exactly | use `turbo_frame_tag @record` on both sides |
| redirect to a page without the frame (login, root) | Network tab: was the response a redirect? | put `<% turbo_page_requires_reload %>` on the sign-in page |
| Rails swapped the layout and your frame lived in the layout | frame requests use layout `turbo_rails/frame` | move the frame into the view, or handle `turbo_frame_request?` in your custom layout method |
| custom layout method returns a static layout | `layout "application"` ignores Turbo's frame layout | convert to `layout :custom_layout` returning `"turbo_rails/frame" if turbo_frame_request?` |
| 4xx/5xx error page rendered | status code in Network tab | frames render error responses too — the error page just has no frame |
| you're targeting a frame that doesn't exist on the page | `document.getElementById("X")` in console | typo, or the frame is inside a not-yet-loaded lazy frame (see `recurse`) |

**Handle it gracefully:**

```js
// app/javascript/frame_missing.js
document.addEventListener("turbo:frame-missing", (event) => {
  const { detail: { response, visit } } = event
  event.preventDefault()
  visit(response)          // escalate to a full-page visit using the response we already have
})
```

Or the declarative version — put this on any page that should never be shown inside a frame (sign-in, error pages):

```erb
<% turbo_page_requires_reload %>
```

With that meta tag present, `FrameController#loadResponse` detects `pageSnapshot.isVisitable === false` and does a full page visit instead of erroring (with a `console.warn` explaining why).

Rails-side custom layout, for the record:

```ruby
class ApplicationController < ActionController::Base
  layout :resolve_layout

  private
    def resolve_layout
      return "turbo_rails/frame" if turbo_frame_request?
      admin? ? "admin" : "application"
    end
end
```

`turbo_frame_request?` and `turbo_frame_request_id` are helper methods too, so views can branch on them.

### 3.7 Frames + pagination

```erb
<%# app/views/posts/index.html.erb %>
<%= turbo_frame_tag "posts", data: { turbo_action: "advance" } do %>
  <div id="posts_list">
    <%= render @posts %>
  </div>
  <%= link_to "Next page", posts_path(page: @posts.next_page) if @posts.next_page %>
<% end %>
```

Because the frame contains the pagination links, clicking Next re-renders the frame from `/posts?page=2`, and `data-turbo-action="advance"` keeps the URL honest.

**Infinite scroll** — a lazy frame that loads the *next* page and contains the next lazy frame:

```erb
<%# app/views/posts/index.html.erb %>
<div id="posts">
  <%= render @posts %>
</div>
<%= render "next_page_frame", posts: @posts %>

<%# app/views/posts/_next_page_frame.html.erb %>
<% if posts.next_page %>
  <%= turbo_frame_tag "posts_page_#{posts.next_page}",
        src: posts_path(page: posts.next_page), loading: :lazy do %>
    <div class="skeleton">Loading…</div>
  <% end %>
<% end %>
```

and in the page-2 response, the frame's content is `append`-able markup plus the *next* frame. (Alternative: respond with a Turbo Stream that appends to `#posts` and replaces the sentinel frame — cleaner for true infinite scroll.)

### 3.8 Frames + modals

```erb
<%# layout: one always-present, empty frame for modal content %>
<%= turbo_frame_tag "modal" %>

<%# trigger anywhere on the page %>
<%= link_to "New post", new_post_path, data: { turbo_frame: "modal" } %>

<%# app/views/posts/new.html.erb %>
<%= turbo_frame_tag "modal" do %>
  <dialog open data-controller="modal">
    <%= form_with model: @post do |f| %> … <% end %>
    <%= link_to "Cancel", posts_path, data: { turbo_frame: "modal" } %>
  </dialog>
<% end %>
```

Closing = navigating the `modal` frame to something that renders an **empty** `<turbo-frame id="modal">`. On successful create, respond with a stream that both closes the modal and inserts the record:

```erb
<%# app/views/posts/create.turbo_stream.erb %>
<%= turbo_stream.update "modal", "" %>
<%= turbo_stream.prepend "posts", @post %>
```

### 3.9 Frame JS API

```js
const frame = document.getElementById("messages")

frame.src = "/messages?page=2"   // triggers a navigation
frame.reload()                   // refetch current src (morphs children if refresh="morph")
frame.loading = "eager"
frame.disabled = true            // cancels in-flight request; stops intercepting
frame.autoscroll = true
await frame.loaded               // Promise
frame.complete                   // boolean (read-only)
frame.isActive                   // in the live document and not a cached preview
frame.isPreview                  // <html data-turbo-preview>
```

Attributes set by Turbo during a frame request: `busy` and `aria-busy="true"`.

Autoscroll options:

```erb
<%= turbo_frame_tag "chat", src: chat_path, autoscroll: true,
      data: { autoscroll_block: "end", autoscroll_behavior: "smooth" } %>
```
(`block` ∈ `start|center|end|nearest`, default `end`; `behavior` ∈ `auto|smooth`, default `auto`.)

---

## 4. Turbo Streams

### 4.1 The eight actions

`src/core/streams/stream_actions.js` defines exactly eight:

| Action | Effect | `method="morph"`? |
|---|---|---|
| `append` | `target.append(content)` | — |
| `prepend` | `target.prepend(content)` | — |
| `before` | insert before `target` | — |
| `after` | insert after `target` | — |
| `replace` | `target.replaceWith(content)` | ✅ → `morphElements` |
| `update` | clear `target`, then append content (inner HTML) | ✅ → `morphChildren` |
| `remove` | `target.remove()` | — |
| `refresh` | `Turbo.session.refresh(baseURI, { method, requestId, scroll })` | reads `method`/`scroll` attrs |

Wire format:

```html
<turbo-stream action="append" target="messages">
  <template>
    <div id="message_1">Hello</div>
  </template>
</turbo-stream>
```

**Deduplication (nice, and surprising):**
- `append`/`prepend` first remove any existing **direct children of the target** whose `id` matches an `id` in the incoming template. So re-appending the same record replaces rather than duplicates it — idempotent broadcasts for free.
- `before`/`after` do the same for **siblings** of the target.

**Missing targets are silent no-ops.** `targetElementsById` returns `[]` if `getElementById` misses; `targetElementsByQuery` returns `[]` if the selector matches nothing. Nothing is logged. (Missing *`action`* or *`target`/`targets`* attributes, however, throw.)

**Other stream-render behaviours worth knowing** (`stream_message_renderer.js`, `stream_message.js`):
- `<script>` tags inside stream templates **are** activated and executed.
- Permanent elements (`[id][data-turbo-permanent]`) are preserved through stream renders via Bardo.
- Focus is preserved: the focused element (by id) is refocused after render; and if the incoming stream contains an `[autofocus]` element and nothing else has focus, it is focused.
- The `<turbo-stream>` element removes itself from the DOM after rendering.
- Rendering happens after `nextRepaint()`, so it's async relative to `turbo:submit-end`.

### 4.2 `target` vs `targets`

```html
<turbo-stream action="remove" target="post_1"></turbo-stream>
<turbo-stream action="add_css_class" targets=".post.selected"><template></template></turbo-stream>
```

- `target` = a **single DOM id** (no `#`), resolved with `getElementById`.
- `targets` = a **CSS selector**, resolved with `querySelectorAll`, applied to every match.

Rails helpers: every action has an `_all` twin.

```erb
<%= turbo_stream.remove @post %>                          <%# target="post_1"        %>
<%= turbo_stream.remove_all ".post.archived" %>           <%# targets=".post.archived" %>
<%= turbo_stream.update_all ".counter", @count %>
```

`Turbo::Streams::ActionHelper#convert_to_turbo_stream_dom_id` means you can pass records to `targets` too, and it prefixes `#`:

```erb
<%= turbo_stream.replace_all @post %>   <%# targets="#post_1" %>
```

### 4.3 Streams from controllers

**Three ways, all valid:**

**(a) A `.turbo_stream.erb` template** — best when there are several updates:

```erb
<%# app/views/posts/create.turbo_stream.erb %>
<%= turbo_stream.prepend "posts", @post %>
<%= turbo_stream.update "posts_count", @posts_count %>
<%= turbo_stream.replace "new_post_form" do %>
  <%= render "form", post: Post.new %>
<% end %>
<%= turbo_stream.append "flashes" do %>
  <div class="flash" data-turbo-temporary>Post created.</div>
<% end %>
```

```ruby
def create
  @post = current_user.posts.new(post_params)
  if @post.save
    @posts_count = current_user.posts.count
    respond_to do |format|
      format.turbo_stream                                    # → create.turbo_stream.erb
      format.html { redirect_to @post, status: :see_other }
    end
  else
    render :new, status: :unprocessable_content
  end
end
```

**(b) Inline `render turbo_stream:`** — best for one or two updates:

```ruby
def destroy
  @post.destroy!
  respond_to do |format|
    format.turbo_stream { render turbo_stream: turbo_stream.remove(@post) }
    format.html { redirect_to posts_path, status: :see_other }
  end
end
```

Multiple streams inline — pass an array:

```ruby
render turbo_stream: [
  turbo_stream.remove(@post),
  turbo_stream.update("posts_count", @posts.count),
  turbo_stream.append("flashes", partial: "shared/flash", locals: { message: "Deleted" })
]
```

**(c) Render a stream from *any* format branch** (e.g. respond to an HTML request with a stream — legal but usually a smell).

**The TagBuilder's rendering rules** (`Turbo::Streams::TagBuilder#render_template`), in priority order:

```ruby
turbo_stream.replace "x", "<div id='x'>raw</div>"                 # explicit content string
turbo_stream.replace @post                                        # renders _post partial via to_partial_path
turbo_stream.replace "x", partial: "posts/post", locals: { post: @post }
turbo_stream.replace "x", MyComponent.new(post: @post)            # anything with #render_in
turbo_stream.replace("x") { link_to "hi", root_path }             # block → capture
turbo_stream.replace("x", partial: "posts/wrapper") { … }         # block + partial → block rendered inside partial as layout
turbo_stream.remove @post                                         # never renders content
```

> ⚠️ **`turbo_stream.update "count", 5`** will try `render_record(5)` first, find no `to_partial_path`, and fall back to the literal — fine. But `turbo_stream.update "x", some_active_record` **renders the record's partial**, which is usually what you want but occasionally a surprise. Pass a string if you mean a string.
>
> ⚠️ Content is **not** HTML-escaped by the tag builder (`template.to_s.html_safe`). Escape user input yourself.

`TagBuilder#initialize` does `@view_context.formats |= [:html]`, and partials are rendered with `formats: [:html]` — that's why `_post.html.erb` (not `_post.turbo_stream.erb`) is picked inside a `.turbo_stream.erb` template.

### 4.4 Streams over WebSockets

**View side:**

```erb
<%# subscribe to a stream %>
<%= turbo_stream_from @board %>
<%= turbo_stream_from Current.account, :notifications %>
<%= turbo_stream_from "room", channel: RoomChannel, data: { room_name: "General" } %>

<div id="messages"><%= render @board.messages %></div>
```

renders

```html
<turbo-cable-stream-source channel="Turbo::StreamsChannel"
                           signed-stream-name="eyJfcmFpbHMiOns...">
</turbo-cable-stream-source>
```

The custom element (`turbo-rails/app/javascript/turbo/cable_stream_source_element.js`) subscribes via Action Cable, re-dispatches each payload as a `MessageEvent`, and gains a `connected` attribute when the subscription is live. Extra `data-*` attributes are snake-cased and passed as channel params.

**Model side:**

```ruby
class Message < ApplicationRecord
  belongs_to :board

  # generated: after_create_commit append_later, after_update_commit replace_later, after_destroy_commit remove
  broadcasts_to :board
end
```

Expanded forms:

```ruby
broadcasts_to :board                                       # stream = message.board
broadcasts_to ->(m) { [m.board, :messages] },              # stream = "board:1:messages"
              inserts_by: :prepend,
              target: "board_messages",
              partial: "messages/custom_message"

broadcasts                                                  # stream = "messages" for create; self for update/destroy
broadcasts_refreshes                                        # page-refresh broadcasts (see §5)
broadcasts_refreshes_to :board
```

Manual, per-callback:

```ruby
class Message < ApplicationRecord
  after_create_commit  -> { broadcast_prepend_later_to board, :messages, target: "messages" }
  after_update_commit  -> { broadcast_replace_later_to board, :messages }
  after_destroy_commit -> { broadcast_remove_to board, :messages }
end
```

**Full broadcast API** (`Turbo::Broadcastable`):

| Sync | Async (`_later`) | Notes |
|---|---|---|
| `broadcast_append_to(*s, target:)` | `broadcast_append_later_to` | |
| `broadcast_prepend_to` | `broadcast_prepend_later_to` | |
| `broadcast_replace_to` | `broadcast_replace_later_to` | target defaults to `self` |
| `broadcast_update_to` | `broadcast_update_later_to` | target defaults to `self` |
| `broadcast_before_to(*s, target:)` | `broadcast_before_later_to`* | requires `target:` or `targets:` |
| `broadcast_after_to(*s, target:)` | `broadcast_after_later_to`* | requires `target:` or `targets:` |
| `broadcast_remove_to` | — (never needed) | renders nothing |
| `broadcast_refresh_to` | `broadcast_refresh_later_to` | see §5 |
| `broadcast_action_to(*s, action:)` | `broadcast_action_later_to` | dynamic/custom actions |
| `broadcast_render_to(*s, **rendering)` | `broadcast_render_later_to` | renders a whole `.turbo_stream.erb` |

\* `broadcast_before_later_to` / `broadcast_after_later_to` exist on `Turbo::Streams::Broadcasts` (the channel) but **not** as `Turbo::Broadcastable` instance methods. Call `Turbo::StreamsChannel.broadcast_before_later_to(...)` directly.

Each also has a `broadcast_X` (no `_to`) variant that streams to `self`.

**Why `_later`:** the sync versions render ERB *inline, inside your model callback, inside the DB transaction*. That's slow and can deadlock. `_later` enqueues `Turbo::Streams::ActionBroadcastJob` (or `BroadcastJob` for `broadcast_render_later_to`, `BroadcastStreamJob` for refreshes) so rendering happens in a worker. All three jobs `discard_on ActiveJob::DeserializationError` — a record destroyed before the job runs is silently dropped.

**Rendering options for broadcasts:**

```ruby
broadcast_replace_to board, partial: "messages/message", locals: { message: self, highlight: true }
broadcast_update_to  user, :counter, target: "count", html: "<span>#{count}</span>"
broadcast_replace_to user, target: "message", template: "messages/show", locals: { message: self }
broadcast_replace_to user, target: "message", renderable: MessageComponent.new(message: self)
broadcast_replace_to board, attributes: { method: :morph }        # ← morph instead of hard replace
```

Defaults from `broadcast_rendering_with_defaults`: `partial:` ⇒ `to_partial_path`, and `locals` always gets `model_name.element => self` (i.e. `message: self`).

**Suppressing broadcasts** (data imports, backfills, tests):

```ruby
Message.suppressing_turbo_broadcasts do
  Message.insert_all(rows)   # nothing broadcast
end
```

**Rendering happens outside a request.** Broadcast jobs render via `ApplicationController.render`, so:
- there is no `current_user`, no `request`, no `session`;
- `*_url` helpers need `Rails.application.routes.default_url_options[:host]` set per environment;
- any view code that touches `Current.user` or `request` will blow up in the job.

Design broadcast partials to be *audience-agnostic*, or broadcast per-user streams.

### 4.5 The security model of `turbo_stream_from`

```ruby
# turbo-rails/app/helpers/turbo/streams_helper.rb
attributes[:"signed-stream-name"] = Turbo::StreamsChannel.signed_stream_name(streamables)

# turbo-rails/lib/turbo-rails.rb
ActiveSupport::MessageVerifier.new(signed_stream_verifier_key, digest: "SHA256", serializer: JSON)
# key = config.turbo.signed_stream_verifier_key ||
#       Rails.application.key_generator.generate_key("turbo/signed_stream_verifier_key")
```

`Turbo::StreamsChannel#subscribed` verifies the signature and rejects if it fails.

**What this protects against:** a client cannot *invent* a stream name. They cannot type `Board:99` into devtools and start listening to another board.

**What it does NOT protect against:**

1. **It is authentication of the *name*, not authorization of the *subscriber*.** If a signed stream name leaks (shared screenshot, a cached HTML page, a shared account, a page you render for the wrong user), **anyone with that string can subscribe from any browser session** and will receive every broadcast forever. The signature never expires.
2. **Broadcast payloads are not per-user.** Everyone on the stream gets identical HTML. If a partial renders anything audience-specific, it leaks.
3. **Model-level broadcasts fire regardless of who is allowed to see the record.**

**Mitigation — a custom channel that also authorizes:**

```ruby
# app/channels/board_channel.rb
class BoardChannel < ActionCable::Channel::Base
  extend  Turbo::Streams::Broadcasts, Turbo::Streams::StreamName
  include Turbo::Streams::StreamName::ClassMethods

  def subscribed
    stream_name = verified_stream_name_from_params
    if stream_name.present? && authorized?(stream_name)
      stream_from stream_name
    else
      reject
    end
  end

  private
    def authorized?(stream_name)
      board_gid = stream_name.split(":").first
      board = GlobalID::Locator.locate(board_gid)
      board && current_user.can_read?(board)
    end
end
```

```erb
<%= turbo_stream_from @board, channel: BoardChannel %>
```

(`current_user` comes from your `ApplicationCable::Connection#identified_by`.)

**Stream names** are built by `stream_name_from`: each streamable becomes `to_gid_param` (Active Records) or `to_param`, joined with `:`. So `turbo_stream_from Current.account, :entries` → `"gid://app/Account/5:entries"`.

`turbo_stream_from` raises `ArgumentError` if all streamables are blank — a small but real footgun with `turbo_stream_from @maybe_nil`.

### 4.6 Custom stream actions

**Client:**

```js
// app/javascript/stream_actions.js
Turbo.StreamActions.toast = function () {
  const message = this.getAttribute("message")
  const level   = this.getAttribute("level") || "info"
  showToast(message, level)
}

Turbo.StreamActions.scroll_to = function () {
  this.targetElements.forEach((el) => el.scrollIntoView({ behavior: "smooth", block: "center" }))
}

Turbo.StreamActions.redirect = function () {
  Turbo.visit(this.getAttribute("url"), { action: this.getAttribute("turbo-action") || "advance" })
}
```

Inside an action, `this` is the `StreamElement`, so you get `this.targetElements`, `this.templateContent`, `this.target`, `this.targets`, `this.requestId`, and `this.getAttribute(...)`.

**Server (Rails), the idiomatic way** — extend the TagBuilder via the load hook (this is documented right in `tag_builder.rb`):

```ruby
# config/initializers/turbo_streams.rb
ActiveSupport.on_load :turbo_streams_tag_builder do
  def toast(message, level: :info)
    turbo_stream_action_tag :toast, message: message, level: level
  end

  def scroll_to(target)
    action :scroll_to, target, allow_inferred_rendering: false
  end

  def scroll_to_all(targets)
    action_all :scroll_to, targets, allow_inferred_rendering: false
  end

  def redirect(url, turbo_action: "advance")
    turbo_stream_action_tag :redirect, url: url, "turbo-action": turbo_action
  end
end
```

```erb
<%= turbo_stream.toast "Saved!", level: :success %>
<%= turbo_stream.scroll_to @post %>
```

Broadcast a custom action:

```ruby
message.broadcast_action_later_to board, action: :toast, target: "toasts",
                                  attributes: { message: "New message" }, render: false
```

> ⚠️ `turbo_stream_action_tag` only emits an empty `<template>` for `remove` and `refresh`. Any other action gets a `<template>` — which is why `allow_inferred_rendering: false` matters for content-less custom actions (otherwise it will try to render the target as a record).

**The other extension point** — intercept `turbo:before-stream-render` (§2.3). Use this when you want to *wrap* existing actions (animation, logging) rather than add new ones.

### 4.7 `turbo_power` — the batteries-included action pack

<https://github.com/marcoroth/turbo_power> ships ~50 extra actions.

```ruby
# Gemfile
gem "turbo_power"
```

```js
// app/javascript/application.js
import * as Turbo from "@hotwired/turbo-rails"
import TurboPower from "turbo_power"
TurboPower.initialize(Turbo.StreamActions)
```

Categories and representative actions:

| Category | Actions |
|---|---|
| DOM | `graft`, `morph`, `inner_html`, `outer_html`, `text_content`, `insert_adjacent_html`, `insert_adjacent_text`, `set_meta` |
| Attributes/classes | `add_css_class`, `remove_css_class`, `replace_css_class`, `toggle_css_class`, `set_attribute`, `remove_attribute`, `toggle_attribute`, `set_dataset_attribute`, `set_property`, `set_style`, `set_styles`, `set_value` |
| Events | `dispatch_event` |
| Forms | `reset_form` |
| Storage | `set_local_storage_item`, `remove_local_storage_item`, `clear_local_storage` (+ session variants) |
| Browser | `reload`, `scroll_into_view`, `set_focus`, `set_title`, `notification` |
| Cookies | `set_cookie`, `set_cookie_item` |
| History | `push_state`, `replace_state`, `history_back`, `history_forward`, `history_go` |
| Turbo | `redirect_to`, `turbo_clear_cache`, `turbo_frame_reload`, `turbo_frame_set_src`, `turbo_progress_bar_show/hide/set_value` |
| Debug | `console_log`, `console_table` |

```erb
<%= turbo_stream.add_css_class "post_#{@post.id}", "highlight" %>
<%= turbo_stream.dispatch_event "#chart", "data:updated", detail: { count: @count } %>
<%= turbo_stream.reset_form "#new_comment" %>
<%= turbo_stream.redirect_to posts_path %>
```

**My take for crosswire:** `turbo_power` is genuinely useful, but most of its actions are "do a DOM manipulation from the server," which is exactly the thing Turbo's philosophy discourages. Recommend it for the handful of cases with no HTML-shaped answer (`dispatch_event`, `reset_form`, `redirect_to`, `set_focus`) and warn against building an app on `set_style`/`add_css_class`.

---

## 5. Turbo 8 morphing & page refreshes

### 5.1 What counts as a "page refresh"

This is the single most important and least-documented definition. From `src/core/drive/page_view.js`:

```js
isPageRefresh(visit) {
  return !visit || (this.lastRenderedLocation.pathname === visit.location.pathname &&
                    visit.action === "replace")
}
```

A visit is a page refresh **iff**:
1. its `action` is `"replace"`, **and**
2. the destination **pathname** matches the current pathname.

Notes:
- **Query strings are ignored.** `/posts?page=1` → `/posts?page=2` with `action: "replace"` counts as a refresh, and will morph.
- `action: "advance"` never morphs — even to the same URL.
- Turbo's own `Navigator#getDefaultAction` turns a form redirect *back to the same URL* into `action: "replace"` — which is exactly the "submit the form, get redirected back to this page" flow that morphing is designed for.
- `Turbo.visit(url, { action: "replace" })` to the current page morphs.
- The `refresh` stream action calls `session.refresh` which does `visit(url, { action: "replace", shouldCacheSnapshot: false, refresh: {method, scroll} })`.

Then:

```js
const shouldMorphPage = this.isPageRefresh(visit) &&
  (visit?.refresh?.method || this.snapshot.refreshMethod) === "morph"
```

So: **page refresh + (`turbo-refresh-method` meta = `morph`, or the stream action said `method="morph"`) ⇒ morph.** Otherwise, plain `<body>` replacement.

### 5.2 Turning it on

```erb
<%# app/views/layouts/application.html.erb %>
<head>
  <%= yield :head %>
  <meta name="turbo-refresh-method" content="morph">
  <meta name="turbo-refresh-scroll" content="preserve">
</head>
```

or, via the Rails helper (requires `<%= yield :head %>` in the layout):

```erb
<% turbo_refreshes_with method: :morph, scroll: :preserve %>
```

`Turbo::DriveHelper#turbo_refreshes_with` validates the arguments (`method ∈ {replace, morph}`, `scroll ∈ {reset, preserve}`) and raises `ArgumentError` otherwise. Individual tags: `turbo_refresh_method_tag(:morph)`, `turbo_refresh_scroll_tag(:preserve)`.

`turbo-refresh-scroll: preserve` is honoured in `Visit#performScroll` via `view.shouldPreserveScrollPosition(visit)` — which is also gated on `isPageRefresh`. So scroll preservation only applies to refreshes, not to ordinary navigation.

### 5.3 What morphing actually does

`MorphingPageRenderer.renderElement` calls `Turbo.morphElements(currentBody, newBody)` → `Idiomorph.morph(...)` (idiomorph ~0.7.4) with Turbo's callback set:

| idiomorph callback | Turbo behaviour |
|---|---|
| `beforeNodeAdded` | refuse to add a node that has an `id` + `data-turbo-permanent` and already exists in the document |
| `beforeNodeMorphed` | refuse if `[data-turbo-permanent]`; otherwise dispatch cancelable `turbo:before-morph-element` |
| `beforeAttributeUpdated` | dispatch cancelable `turbo:before-morph-attribute` (`{ attributeName, mutationType }`) |
| `beforeNodeRemoved` | same rule as `beforeNodeMorphed` |
| `afterNodeMorphed` | dispatch `turbo:morph-element` |

Then dispatch `turbo:morph` on the document.

Also, `MorphingPageRenderer`:
- overrides `preservingPermanentElements` to a **no-op** (Bardo is bypassed),
- sets `shouldAutofocus = false` (no autofocus stealing on refresh),
- reports `renderMethod === "morph"` in `turbo:before-render` / `turbo:render`.

**Idiomorph matches nodes by `id` first**, then falls back to structural heuristics. Which means: **stable `id`s on repeated elements are what make morphing behave.** `dom_id(record)` everywhere is not decoration; it's the algorithm's input.

### 5.4 `refresh="morph"` frames

```erb
<%= turbo_frame_tag "comments", src: post_comments_path(@post), refresh: "morph" do %>
  <%= render @comments %>
<% end %>
```

During a page morph, when idiomorph reaches this frame, Turbo's `beforeNodeMorphed` sees `shouldRefreshFrameWithMorphing(node, newNode)` and instead:
1. calls `frame.reload()` (refetch from `src`, then `morphChildren`),
2. returns `false` so idiomorph **doesn't touch the frame's subtree**.

Compatibility requirements (`areFramesCompatibleForRefreshing`):
- the frame has a `src` and `refresh === "morph"`,
- the new document's frame has the same `id`,
- the new frame either has no `src` or the same `src`,
- the frame is **not** inside `[data-turbo-permanent]`.

This is *the* solution for "the page has 3 pages of comments loaded via pagination; a morph would throw pages 2–3 away." The frame refetches itself with its own current `src`.

Frames morphing also dispatch `turbo:before-frame-morph` on the frame.

### 5.5 The `refresh` stream action + request-id debouncing

```erb
<%= turbo_stream.refresh %>
<%# => <turbo-stream action="refresh" request-id="ef083d55-..."></turbo-stream> %>

<%= turbo_stream.refresh request_id: nil %>   <%# no dedupe: everyone refreshes, incl. the actor %>
```

Raw form with options:

```html
<turbo-stream action="refresh" method="morph" scroll="preserve" request-id="abc"></turbo-stream>
```

**The request-id mechanism, end to end:**

1. Every Turbo `fetch` adds a header: `X-Turbo-Request-Id: <uuid>` and remembers the uuid in a `LimitedSet(20)` (`src/http/fetch.js`).
2. Rails captures it: `Turbo::RequestIdTracking` (`around_action`) sets `Turbo.current_request_id` for the duration of the request.
3. `broadcast_refresh_later_to` stamps that id into the broadcast: `<turbo-stream action="refresh" request-id="...">`.
4. On the client, `StreamActions.refresh` calls `session.refresh(baseURI, { requestId })`, which **skips** if `recentRequests.has(requestId)`.

Net effect: **the browser tab that caused the change does not double-render.** It already got the HTTP response; the socket broadcast that comes back with its own request-id is ignored. Every *other* tab/user does refresh.

`Session#refresh` also skips when:
- a visit is already in flight (`this.navigator.currentVisit`), or
- `url !== document.baseURI` (the broadcast is for a page you're not on).

**Two layers of debouncing:**

| Layer | Where | Default | Configurable |
|---|---|---|---|
| Client | `Session#pageRefreshDebouncePeriod` — the `refresh()` method itself is `debounce()`d | **150 ms** | `Turbo.session.pageRefreshDebouncePeriod = 250` |
| Server | `Turbo::ThreadDebouncer` / `Turbo::Debouncer` (Concurrent::ScheduledTask), keyed by `stream_name + request_id` | **0.5 s** | not exposed via config; `Turbo::Debouncer::DEFAULT_DELAY` |

So a loop that touches 200 records in one request produces **one** broadcast, not 200.

> ⚠️ The server-side debouncer uses a **background thread** (`Concurrent::ScheduledTask`). In tests, `turbo-rails` swaps in `Turbo::ImmediateDebouncer` (which doesn't debounce at all) to avoid flakiness. Anything that depends on debouncing behaviour therefore behaves differently in tests than in production.

### 5.6 `broadcasts_refreshes`

```ruby
class Board < ApplicationRecord
  has_many :columns
  broadcasts_refreshes
end

class Column < ApplicationRecord
  belongs_to :board, touch: true     # touching the board triggers ITS refresh broadcast
  broadcasts_refreshes_to :board
end
```

```erb
<%# app/views/boards/show.html.erb %>
<%= turbo_stream_from @board %>
<% turbo_refreshes_with method: :morph, scroll: :preserve %>

<%# ... the entire board, rendered normally ... %>
```

That's the whole feature. No per-element targets, no `_later` bookkeeping, no partial-per-DOM-node discipline. 37signals reported replacing "over 100 lines" of targeted broadcast code with `broadcasts_refreshes` (<https://dev.37signals.com/a-happier-happy-path-in-turbo-with-morphing/>).

Generated callbacks:

```ruby
def broadcasts_refreshes(stream = model_name.plural)
  after_create_commit  -> { broadcast_refresh_later_to(stream) }   # stream = "boards"
  after_update_commit  -> { broadcast_refresh_later }              # stream = self
  after_destroy_commit -> { broadcast_refresh }                    # sync, stream = self
end

def broadcasts_refreshes_to(stream)
  after_commit -> { broadcast_refresh_later_to(stream.try(:call, self) || send(stream)) }
end
```

Note the asymmetry: create broadcasts to the **collection** stream, update/destroy to the **record's own** stream. And destroy is **synchronous** (there's no record left to deserialize in a job).

### 5.7 When morphing beats targeted streams — and when it doesn't

**Morph wins when:**
- the update is "this page, but with new data" (a Kanban board, a dashboard, a list with a filter),
- multiple regions change together and you'd otherwise write 5 stream actions,
- you want scroll/focus/text-selection/CSS-transition state preserved for free,
- correctness matters more than bytes: the server always re-renders the whole truth, so drift between client DOM and server state is structurally impossible,
- the change came from *someone else* and you don't know what changed.

**Morph loses when:**
- the page is expensive to render (morphing sends the *entire* page over the wire and re-renders it server-side, per subscriber, per change),
- the page is huge (idiomorph walks the whole tree),
- you need to update something the current page doesn't contain (a toast, a modal),
- the update needs to be visibly different per user,
- the DOM contains third-party-managed subtrees (maps, editors, charts) — see gotchas,
- you need append-only semantics with a growing list (chat) — `append` streams are cheaper and don't re-render history.

**Rule of thumb:** morphing is the default; reach for targeted streams as an optimization or when the update has no page-shaped answer.

### 5.8 Morphing gotchas (the real list)

1. **Lost DOM state that isn't in the HTML.** Morphing preserves nodes, so scroll/focus survive. But anything the *server* re-renders differently gets overwritten: an `<input>` the user is typing into **will be reset** if the server sends a different `value` attribute. Idiomorph updates attributes, and for inputs it also syncs the `value` property. Guard the field:

   ```html
   <input name="draft" value="…" data-turbo-permanent id="draft_field">
   ```

   or

   ```js
   document.addEventListener("turbo:before-morph-element", (event) => {
     const el = event.detail.currentElement
     if (el === document.activeElement && el.matches("input, textarea")) event.preventDefault()
   })
   ```

2. **Third-party widgets.** Anything that manipulates the DOM outside your templates (Google Maps, TinyMCE/Trix, Chart.js canvases, Select2, Leaflet) will be seen by idiomorph as "unexpected children" and pruned. Fix with `data-turbo-permanent` on the container, or skip via `turbo:before-morph-element`:

   ```js
   document.addEventListener("turbo:before-morph-element", (event) => {
     if (event.detail.currentElement.hasAttribute("data-widget")) event.preventDefault()
   })
   ```

3. **Stimulus controllers.** When a node is *morphed in place*, it is **not** disconnected/reconnected — good for state, but it means `connect()` doesn't re-run and your controller must handle attribute/`value` changes reactively (`xChanged(value)` callbacks). When a node is *added or removed*, Stimulus connect/disconnect fires normally. So a controller written with all its logic in `connect()` will silently stop updating under morphing.

   Also: `data-controller` **attribute changes** during a morph *do* re-trigger Stimulus, and `turbo:before-morph-attribute` can be used to protect an attribute your controller writes at runtime:

   ```js
   document.addEventListener("turbo:before-morph-attribute", (event) => {
     if (event.detail.attributeName.startsWith("data-tooltip-")) event.preventDefault()
   })
   ```

4. **Duplicate `id`s destroy idiomorph's heuristics.** 37signals hit exactly this (<https://dev.37signals.com/the-radiating-programmer/>). Audit with `document.querySelectorAll("[id]")` and check for dupes.

5. **Moving elements out of their server-rendered position** (a common pagination trick: hoisting a frame out of a container) confuses idiomorph's id-map. Prefer `refresh="morph"` frames.

6. **`<body>`-level scripts still re-execute?** No — under morph, scripts that are "the same" are left alone, so `turbo:load`-style initialization that assumed a fresh body may not re-run. Use `turbo:morph` / `turbo:morph-element` as complementary hooks.

7. **`data-turbo-permanent` behaves differently under morph vs replace.** Under replace, the *live node is transplanted* (Bardo). Under morph, the node is simply *not touched*. In both cases contents don't update from the server — but a permanent element that is missing from the new page is **deleted** under replace and **kept** under morph.

8. **Broadcasts don't aggregate across models.** `Board` and `Column` each broadcasting refreshes to the same stream produce two broadcasts (they debounce independently by stream+request-id, and requests slower than 0.5 s can emit more than one). Pick one model as the broadcaster where possible.

9. **The broadcast recipient re-fetches the page as themselves.** Make sure the HTTP response the *actor* got and the page the *observers* fetch are consistent, or people will see divergent state.

---

## 6. View Transitions

Turbo has first-class support (`src/core/drive/view_transitioner.js`).

**Opt in** — either meta tag works (`PageSnapshot#prefersViewTransitions`):

```html
<meta name="view-transition" content="same-origin">
<!-- or -->
<meta name="turbo-view-transition" content="true">
```

Rules:
- **Both** the outgoing and incoming snapshots must opt in (`PageView#shouldTransitionTo`), so put the tag in your layout.
- Honours `prefers-reduced-motion: reduce` — transitions are skipped for users who ask.
- Uses `document.startViewTransition(render)` and awaits `.finished`; falls back silently when the API is unavailable.
- Transitions are serialized through a promise chain, and only one can be in flight (`#viewTransitionStarted`).

Combine with `data-turbo-visit-direction` for directional animations:

```css
@view-transition { navigation: auto; }

::view-transition-old(root),
::view-transition-new(root) { animation-duration: 200ms; }

html[data-turbo-visit-direction="back"] ::view-transition-old(root) {
  animation-name: slide-out-right;
}
```

Named transitions across pages work the usual way:

```erb
<%= link_to post_path(@post) do %>
  <img src="<%= post.cover_url %>" style="view-transition-name: cover-<%= post.id %>">
<% end %>
```

> Morphing and view transitions are **independent**. A morph render can also be wrapped in a view transition (`renderPageSnapshot` calls `viewTransitioner.renderChange(...)` regardless of renderer). In practice, morphing already preserves so much state that a view transition on top is often unnecessary and sometimes visually odd.

---

## 7. Turbo + Native (brief)

*(Another agent covers Hotwire Native in depth; this is just the Turbo-side seam.)*

Turbo's `Session` delegates all navigation UI to an **adapter**. The web default is `BrowserAdapter` (progress bar + `window.location` fallbacks). Native shells call:

```js
Turbo.registerAdapter(myAdapter)
```

Adapter interface (from `src/core/native/browser_adapter.js`, all called by `Visit`/`Navigator`):

```
visitProposedToLocation(location, options)
visitStarted(visit)
visitRequestStarted(visit)
visitRequestCompleted(visit)
visitRequestFailedWithStatusCode(visit, statusCode)
visitRequestFinished(visit)
visitRendered(visit)
visitCompleted(visit)
visitFailed(visit)
pageInvalidated(reason)
formSubmissionStarted(formSubmission)      // optional
formSubmissionFinished(formSubmission)     // optional
linkPrefetchingIsEnabledForLocation(loc)   // optional; native shells return false
```

`Visit#identifier` exists specifically "Required by turbo-ios". `SystemStatusCode` (`networkFailure: 0`, `timeoutFailure: -1`, `contentTypeMismatch: -2`) is the vocabulary adapters use for non-HTTP failures.

Rails side (`Turbo::Native::Navigation`, auto-included in `ActionController::Base`):

```ruby
hotwire_native_app?          # user agent matches /(Turbo|Hotwire) Native/
turbo_native_app?            # alias

recede_or_redirect_to(url, **options)
resume_or_redirect_to(url, **options)
refresh_or_redirect_to(url, **options)
recede_or_redirect_back_or_to(url, **options)
resume_or_redirect_back_or_to(url, **options)
refresh_or_redirect_back_or_to(url, **options)
```

These redirect to engine-provided sentinel routes (`turbo_recede_historical_location_url` etc., see `turbo-rails/config/routes.rb`) that native shells intercept to pop/dismiss/refresh. On the web they fall through to a normal redirect.

```ruby
def create
  @post = Post.create!(post_params)
  recede_or_redirect_to posts_path, status: :see_other
end
```

Disable the routes with `config.turbo.draw_routes = false`.

---

## 8. Testing Turbo in Rails

Auto-included by the engine — no setup required.

**Stream assertions** (`Turbo::TestAssertions`, in `ActiveSupport::TestCase`):

```ruby
assert_turbo_stream action: "append", target: "messages"
assert_turbo_stream action: "replace", target: message do
  assert_select "template .message__body", text: "Hi"
end
assert_turbo_stream action: "remove", target: "post_1", count: 1
assert_no_turbo_stream action: "remove", target: "post_1"
```

**Frame assertions:**

```ruby
assert_turbo_frame id: "messages", src: messages_path, loading: "lazy"
assert_turbo_frame @post do
  assert_select "h2", text: @post.title
end
assert_no_turbo_frame "modal"
```

**Integration tests** (`Turbo::TestAssertions::IntegrationTestAssertions`) add `status:` and assert the media type:

```ruby
post messages_path, params: { message: { body: "Hi" } }, as: :turbo_stream
assert_turbo_stream action: "append", target: "messages", status: :created
```

`as: :turbo_stream` works because the engine registers a `TurboStreamEncoder` sending `Accept: text/vnd.turbo-stream.html,text/html`.

**Broadcast assertions** (`Turbo::Broadcastable::TestHelper`):

```ruby
assert_turbo_stream_broadcasts @board, count: 1 do
  message.broadcast_append_to @board
end
```

**System tests:** `<turbo-cable-stream-source>` takes a moment to connect. `turbo-rails` patches Capybara's `visit` to wait (`connect_turbo_cable_stream_sources`). Extend or disable:

```ruby
# config/environments/test.rb
config.turbo.test_connect_after_actions << :click_link
config.turbo.test_connect_after_actions = []   # disable
```

```ruby
test "renders broadcast messages" do
  visit "/"
  click_link "All Messages"
  connect_turbo_cable_stream_sources   # explicit wait
  Message.create!(content: "Hello")
  assert_text "Hello"
end
```

**Rendering outside a request** (what broadcast jobs do — useful in tests and scripts):

```ruby
ApplicationController.render(template: "posts/show", assigns: { post: Post.first })
PostsController.renderer.render(:show, assigns: { post: Post.first })
```

---

## 9. Common failure modes & how to diagnose them

| Symptom | Likely cause | Diagnosis | Fix |
|---|---|---|---|
| Form submits, nothing happens, console says **"Form responses must redirect to another location"** | non-GET returned `200 OK` without a redirect | Network tab: status 200, `redirected: false` | `redirect_to …, status: :see_other`, or return a 422, or return a `turbo_stream` |
| Validation errors never show | `render :new` returned 200 | Network tab shows 200 | `render :new, status: :unprocessable_content` (422) |
| `DELETE` redirect hits the wrong route / re-issues DELETE | `redirect_to` returned 302 after a non-GET | Network tab shows two requests, second is DELETE | `status: :see_other` |
| Frame shows **"Content missing"** | response has no `<turbo-frame id="…">` | View source of the frame response | §3.6 checklist |
| Every navigation does a **full browser reload** | `data-turbo-track="reload"` signature mismatch | listen for `turbo:reload` and log `event.detail.reason` | make asset digests stable; check for per-request nonces/timestamps in tracked head elements |
| **JS breaks after a stream update** | `turbo:load` doesn't fire for streams | check event log | use Stimulus (`connect()`), or listen for `turbo:before-stream-render` / `turbo:frame-load` |
| **JS runs twice / handlers accumulate** | listeners added in `turbo:load` without teardown; body scripts re-execute every render | count listeners in devtools | move to Stimulus, or remove in `turbo:before-cache` |
| **Old content flashes on Back** | cached preview snapshot | `<html data-turbo-preview>` visible in devtools during the flash | `data-turbo-temporary`, `turbo:before-cache` cleanup, or `turbo_exempts_page_from_preview` |
| Turbo Stream response **renders as a full page / downloads a file** | server returned `text/html` (or the browser got a stream response for a plain GET) | check `Content-Type` | ensure a `.turbo_stream.erb` template exists and `format.turbo_stream` is declared |
| Broadcast never arrives | (a) cable not connected (b) wrong stream name (c) `_later` job not running (d) dev `async` adapter across processes | `<turbo-cable-stream-source connected>` attribute; `rails console` in a *different* process won't reach the browser | check Action Cable adapter (`redis` in prod), check the job queue, use web-console for manual triggers |
| Broadcast raises in the job: `undefined method 'url_for'` / missing host | rendering outside a request | job backtrace | set `Rails.application.routes.default_url_options[:host]` |
| Broadcast partial raises on `current_user` | no request context in the job | job backtrace | make broadcast partials audience-agnostic, or broadcast per-user streams |
| Morphing wipes what the user typed | server re-rendered the input's `value` | type, trigger a refresh, watch the field | `data-turbo-permanent` on the field, or cancel `turbo:before-morph-element` for the focused element |
| Third-party widget dies on refresh | idiomorph pruned its DOM | log `turbo:before-morph-element` for the container | `data-turbo-permanent` or cancel the event |
| Stimulus controller stops updating after morph | node morphed in place ⇒ `connect()` doesn't re-run | log `connect`/`disconnect` | move logic into value/attribute change callbacks |
| Server gets unexpected GETs on hover | prefetch-on-hover | look for `X-Sec-Purpose: prefetch` in logs | `data-turbo-prefetch="false"` or `<meta name="turbo-prefetch" content="false">` |
| Link to `/export.csv` gets Turbo-intercepted or fails to download | it *doesn't* — the extension is in `unvisitableExtensions` | `Turbo.config.drive.unvisitableExtensions.has(".csv")` | nothing; if you *want* it intercepted, delete the extension from the set |
| `<turbo-stream>` silently does nothing | target id/selector doesn't match anything (silent no-op) | `document.getElementById("…")` in console | fix the id; consider a dev-only listener that warns on empty `targetElements` |
| `data-turbo="false"` doesn't disable Turbo inside a frame | by design (`|| withinFrame`) | read `Session#elementIsNavigatable` | add `disabled` to the frame, or `data-turbo-frame="_top"` on the link |
| Console warns about loading Turbo from `<body>` | script placement | the warning names the offending element | move the bundle to `<head>` with `defer`, or `data-turbo-suppress-warning` |
| Broadcasts fire during a data import | model callbacks | — | `Model.suppressing_turbo_broadcasts { … }` |

**Universal debugging snippet** — paste in the console, get a full trace:

```js
;[
  "turbo:click","turbo:before-visit","turbo:visit","turbo:before-cache",
  "turbo:before-render","turbo:render","turbo:load","turbo:reload",
  "turbo:before-fetch-request","turbo:before-fetch-response","turbo:fetch-request-error",
  "turbo:submit-start","turbo:submit-end",
  "turbo:before-frame-render","turbo:frame-render","turbo:frame-load","turbo:frame-missing",
  "turbo:before-stream-render",
  "turbo:morph","turbo:before-morph-element","turbo:morph-element","turbo:before-frame-morph",
  "turbo:before-prefetch"
].forEach((name) =>
  document.addEventListener(name, (e) =>
    console.log("%c" + name, "color:#0076ff", e.target, e.detail ?? "")
  )
)
```

---

## Gotchas & Sharp Edges

1. **`turbo:load` does not fire for Turbo Stream renders or Turbo Frame navigations.** This is the single biggest source of "my JavaScript stopped working." Use Stimulus, whose `connect()` runs whenever a matching element enters the DOM by any mechanism.

2. **`turbo:before-render` / `turbo:render` fire twice when a cached preview is shown.** Guard with `document.documentElement.hasAttribute("data-turbo-preview")` if the work is expensive or side-effecting.

3. **A 200 OK non-redirect response to a non-GET form submission renders nothing** and logs `Form responses must redirect to another location`. Always redirect (303) or return 4xx/5xx or a turbo_stream.

4. **`:unprocessable_entity` is deprecated on Rack 3.1+.** Prefer `:unprocessable_content`. Both are 422. Existing tutorials universally say `:unprocessable_entity` — flag this as outdated in crosswire recipes.

5. **`redirect_to` after PATCH/PUT/DELETE must be `status: :see_other`.** 302 makes the browser follow with the *original* method for those verbs.

6. **`data-turbo="false"` does not disable Turbo inside a `<turbo-frame>`.** `elementIsNavigatable` short-circuits with `|| withinFrame`. Use `disabled` on the frame instead.

7. **`data-turbo-permanent` requires an `id`** and requires the element to exist **in both** documents. Otherwise it's silently dropped.

8. **Permanent elements never update from the server** on a Drive navigation. Update them via a Turbo Stream or `Turbo.morphElements`.

9. **Permanence works differently under morph.** Bardo (node transplant) is bypassed; idiomorph just skips the subtree. Behaviour diverges when the element is missing from the new page (deleted under replace, kept under morph).

10. **Morph detection ignores the query string.** `isPageRefresh` compares only `pathname` + `action === "replace"`. `/posts?page=1` → `/posts?page=2` with a replace action *will* morph.

11. **Prefetch-on-hover is on by default** and issues real GETs after 100 ms of hover. Any GET with side effects will be triggered. There is no `Turbo.config` flag — only the meta tag / attributes. Check `X-Sec-Purpose: prefetch` server-side if you need to distinguish.

12. **The prefetch cache holds exactly one entry** (LRU size 1) with a 10 s TTL. Hovering a second link discards the first prefetch.

13. **`data-turbo-preload` links are re-fetched after every render.** Cheap-looking, expensive at scale.

14. **`<turbo-stream>` with a non-matching target is a silent no-op.** No warning, no error. Budget debugging time.

15. **`append`/`prepend` dedupe children by `id`; `before`/`after` dedupe siblings by `id`.** Usually helpful, occasionally surprising (an appended element with an id already present elsewhere in the target gets removed first).

16. **The Rails `TagBuilder` does not escape content.** `template.to_s.html_safe`. Escape user input.

17. **`turbo_stream.update "x", @record` renders the record's partial**, not the record's `to_s`. Pass a string if you mean a string.

18. **`turbo_stream_from` raises `ArgumentError` if all streamables are blank.** `turbo_stream_from @maybe_nil` will 500 your page.

19. **Signed stream names are authentication, not authorization, and never expire.** Anyone holding the signed string can subscribe forever. Use a custom channel with an authorization check for anything sensitive.

20. **Broadcast payloads are identical for every subscriber.** Never render audience-specific content in a broadcast partial.

21. **Broadcast rendering happens outside a request** — no `current_user`, no `request`, and `*_url` needs `default_url_options[:host]`.

22. **`broadcast_*_later` jobs `discard_on ActiveJob::DeserializationError`.** A record destroyed before its job runs disappears silently.

23. **`broadcast_before_later_to` / `broadcast_after_later_to` don't exist on models** — only on `Turbo::StreamsChannel`.

24. **In development, the Action Cable `async` adapter is per-process.** Broadcasts from `bin/rails console` will never reach a browser attached to `bin/rails server`. Use web-console.

25. **`<meta name="turbo-cache-control">` holds one value.** `no-cache` and `no-preview` are mutually exclusive; the two Rails helpers overwrite each other.

26. **Head `<script>` elements are executed once and never removed.** Body `<script>` elements re-execute on every render. Put your bundle in `<head>`.

27. **`data-turbo-track="reload"` only works if the tracked element's `outerHTML` actually changes.** Unfingerprinted assets in development never trigger it.

28. **`data-turbo-track="dynamic"` exists** (removes head stylesheets absent from the new page) and is essentially undocumented.

29. **`data-turbo-frame="_parent"` exists** (drives the enclosing frame) and is essentially undocumented.

30. **`turbo:before-stream-render` IS cancelable in the source** (`cancelable: true` in `stream_element.js`) even though the published events reference lists it as not cancelable.

31. **Anchor-only links (`href="#foo"`) are not Turbo visits.** `findLinkFromClickTarget` returns null. Same for `[download]` and `target` ≠ `_self`.

32. **~50 file extensions bypass Turbo entirely** (`Turbo.config.drive.unvisitableExtensions`), including `.json`, `.pdf`, `.csv`, `.svg`, `.txt`. A Rails route ending in one of those will be a full browser navigation.

33. **`data-turbo-method` on an `<a>` synthesizes a hidden form.** It's not keyboard/AT-equivalent to a button and breaks without JS. Prefer `button_to`.

34. **The default submitter-disable strategy blurs the button.** `Turbo.config.forms.submitter = "aria-disabled"` is the accessible alternative.

35. **Frame requests get a different layout and a different ETag.** If you use a static `layout "foo"`, frames will render your full layout inside the frame. Convert to a layout *method*.

36. **A frame whose `src` equals its own response URL throws** "Matching `<turbo-frame>` element has a source URL which references itself".

37. **Duplicate DOM `id`s break idiomorph badly.** Also break `getElementById`-based stream targeting.

38. **Server-side refresh debouncing uses a background thread** and is replaced by a no-op debouncer in the test environment. Timing behaviour differs between test and production.

39. **`Turbo.clearCache()`, `Turbo.setProgressBarDelay()`, `Turbo.setConfirmMethod()`, `Turbo.setFormMode()`, `session.setProgressBarDelay()` are all deprecated** in Turbo 8 and log warnings. Use `Turbo.cache.clear()` and `Turbo.config.*`. Any tutorial using the old forms predates 8.0.6.

40. **Turbo 8 removed the SubmitEvent/`requestSubmit` polyfills in 8.0.21.** Very old browsers that previously worked no longer do.

---

## Open Questions

1. **Turbo 9.** There is no 9.x branch or release as of 2026-08-15; 8.0.23 (2026-01-29) is current. Worth re-checking before publishing crosswire — if a 9 lands, the `Turbo.config` surface and the deprecated top-level setters are the most likely breaking changes.

2. **Server-side diffing.** 37signals explored it (<https://dev.37signals.com/exploring-server-side-diffing-in-turbo/>) before shipping idiomorph-based client morphing. Is that line of work dead, or is it a candidate for a future release? Not answered by any source I found.

3. **Prefetch configuration.** There's a meta tag and attributes but no `Turbo.config.drive.prefetch`. Is that an intentional omission or a gap? Worth checking open issues before writing a "how to disable prefetch" recipe that recommends the meta tag as the only option.

4. **`turbo:before-stream-render` cancelability.** The source sets `cancelable: true`; the published reference says otherwise. I have not tested what `preventDefault()` actually does end-to-end (it should skip the render, since `render()` guards on `this.dispatchEvent(event)`), but I'd verify before documenting it as an API.

5. **`recurse` semantics.** The attribute is real (`turbo-frame[src][recurse~=<id>]`) and has a second effect (suppressing request cancellation on disconnect), but I found no handbook coverage and no real-world examples. Is this internal machinery or a supported API?

6. **`_parent` frame target.** Present in `FrameController#getFrameElementById` and exercised by `#shouldInterceptNavigation`, but not in the attributes reference. Supported, or an implementation detail?

7. **Morphing + Stimulus outlets/values best practices.** The "morph doesn't re-run `connect()`" issue has real ergonomic consequences for how crosswire should teach Stimulus controllers. Worth a dedicated experiment: which controller shapes survive morphing cleanly?

8. **Interaction of view transitions and morphing.** Both can apply to the same render. Is the combination recommended, discouraged, or just untested? No source addresses it.

9. **`data-turbo-track="dynamic"` and `data-turbo-eval`** — both real, both essentially undocumented. Need practical examples before recommending them.

10. **Performance envelope of `broadcasts_refreshes`.** How large can a page get before whole-page re-render per subscriber per change becomes the bottleneck? Needs a benchmark, not a doc.

11. **Turbo + CSP.** Turbo reads `<meta name="csp-nonce">` (`getCspNonce`) and applies it to activated scripts and the progress-bar stylesheet, and strips `nonce` when comparing head elements. Whether that's sufficient for a strict `script-src 'nonce-…'` policy with morphing in play is untested here.
