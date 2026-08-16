# 14 — Dossier: Turbo 8 Morphing ("page refreshes with morphing")

**Status:** consolidated reference. Supersedes the scattered morph material in `02-turbo-deep-dive.md` §5/§6.4, `03-stimulus-deep-dive.md` §14.3, `07-problem-mining.md` P5–P10, `10-testing-a11y-perf-tooling.md`.

**Versions this document describes (verified 2026-08-15):**

| Package | Version | Date | Evidence |
|---|---|---|---|
| `@hotwired/turbo` | **8.0.23** | 2026-01-29 | `gh release list --repo hotwired/turbo` |
| `turbo-rails` | **2.0.23** | — | `lib/turbo/version.rb`; vendors turbo 8.0.23 in `app/assets/javascripts/turbo.min.js` |
| `idiomorph` (pinned by turbo) | **`~0.7.4`** | 0.7.4 released 2025-09-29 | `turbo/package.json:46` |

**Morph-relevant release history** (from `gh release view`), useful when triaging "is my Turbo new enough?":

| Turbo | Change |
|---|---|
| 8.0.13 (2025-03) | **Idiomorph 0.7.1→0.7.2** — the big correctness leap (`botandrose`), fixes `data-turbo-permanent` being ignored during reorders (PR #1321); adds `restoreFocus`; fixes stale refresh URL from debouncing (#1250) |
| 8.0.18 (2025-09) | recursive reloads of nested `refresh="morph"` frames (#1311); **`morphElements`/`morphChildren` exported for consumer use** (#1319) |
| 8.0.20 (2025-10) | frames with `refresh="morph"` are preserved when missing from the new content (#1452) |
| 8.0.21 (2026-01) | `[method]`/`[scroll]` attributes on the Refresh stream (#1208) |
| 8.0.23 (2026-01) | latest; no morph-specific changes |

Everything in the "How it works" and "Exact rules" sections was read out of the Turbo and Idiomorph sources at those versions, not from documentation. Where a claim comes from an issue thread or a blog post it is attributed inline. Where I could not verify something it is marked **[unverified]**.

---

## Table of contents

1. [How morphing actually works](#how-morphing-actually-works)
2. [The exact rules](#the-exact-rules)
3. [The Stimulus values conflict — complete picture](#the-stimulus-values-conflict--complete-picture)
4. [What breaks under morph — the full inventory](#what-breaks-under-morph--the-full-inventory)
5. [Decision rubric: morph vs streams vs frames](#decision-rubric-morph-vs-streams-vs-frames)
6. [Pre-flight checklist before enabling morphing](#pre-flight-checklist-before-enabling-morphing)
7. [Interactions](#interactions)
8. [Design brief: what a `preserve` primitive would need to do](#design-brief-what-a-preserve-primitive-would-need-to-do)
9. [Alternatives and adjacent work](#alternatives-and-adjacent-work)
10. [Corrections to the public literature](#corrections-to-the-public-literature)
11. [Corrections to earlier crosswire notes](#corrections-to-earlier-crosswire-notes)
12. [Open questions](#open-questions)

---

## How morphing actually works

### The one-paragraph version

When Turbo decides a navigation is a *page refresh* (same pathname, `replace` action) **and** the page opts in with `<meta name="turbo-refresh-method" content="morph">`, Turbo swaps its `PageRenderer` for a `MorphingPageRenderer`. Instead of `document.body.replaceWith(newBody)`, it hands the current `<body>` and the new `<body>` to **Idiomorph**, which walks both trees and mutates the existing DOM in place — patching attributes and text, moving matched subtrees, inserting only genuinely new nodes and deleting only genuinely gone ones. Nodes that survive are *the same DOM nodes*, so scroll position, focus, text selection, `<video>` playback, CSS transition state and custom-element instances survive with them. The `<head>` is **not** morphed; Turbo merges it with its own pre-existing `mergeHead()` machinery.

### The call chain (source-verified)

```
Visit#render
  └─ PageView#renderPage(snapshot, isPreview, willRender, visit)      src/core/drive/page_view.js:18
       shouldMorphPage = isPageRefresh(visit)
                         && (visit?.refresh?.method || this.snapshot.refreshMethod) === "morph"
       rendererClass = shouldMorphPage ? MorphingPageRenderer : PageRenderer
  └─ Renderer#prepareToRender  →  PageRenderer#mergeHead()             (head handled by Turbo, NOT idiomorph)
  └─ PageRenderer#render → replaceBody → assignNewBody
       └─ MorphingPageRenderer.renderElement(document.body, newBody)   src/core/drive/morphing_page_renderer.js
            └─ morphElements(current, new, { callbacks })              src/core/morphing.js:14
                 └─ Idiomorph.morph(current, new, { callbacks: DefaultIdiomorphCallbacks })
            └─ dispatch("turbo:morph", { detail: { currentElement, newElement } })
```

Two facts worth internalising:

* **`MorphingPageRenderer` overrides `preservingPermanentElements` to a passthrough.** Bardo (Turbo's transplant-the-live-node machinery for `data-turbo-permanent`) is **not used** during a morph. Permanence is enforced entirely inside Idiomorph callbacks. This is why permanent elements behave subtly differently under morph than under replace.
* **`MorphingPageRenderer.shouldAutofocus === false`.** Morphs never re-run autofocus. Anything that depends on `[autofocus]` firing on every render is broken by morphing. (Landed via PR #1267, "Don't lose focus due to autofocus when morphing pages".)

### What Turbo passes to Idiomorph

`src/core/morphing.js` calls `Idiomorph.morph(currentElement, newElement, { callbacks: new DefaultIdiomorphCallbacks(callbacks) })`. Note what is **not** passed:

| Idiomorph option | Turbo's value | Consequence |
|---|---|---|
| `morphStyle` | *unset* → default `"outerHTML"` for page morphs; `"innerHTML"` for `morphChildren()` (frames) | page morph patches the `<body>` element itself; frame morph patches only the frame's children |
| `ignoreActive` | *unset* (false) | the focused element **is** morphed |
| `ignoreActiveValue` | *unset* (false) | the focused element's `value` **is** overwritten by the server's. Was `true` in 8.0.0 (PR #1141) and reverted the same week (PR #1195) |
| `restoreFocus` | *unset* → default `true` since idiomorph 0.7.1 | after the morph, if the previously-focused input/textarea had an `id` and lost focus, idiomorph re-focuses it and restores `selectionStart`/`selectionEnd`. Fires extra `focus`/`select` events |
| `head` | *unset* | **dead config in Turbo** — Turbo never hands `<head>` to idiomorph, so `head.style`, `head.block`, `im-preserve`, `im-re-append`, `afterHeadMorphed` are all inert. Head merging is Turbo's own `HeadSnapshot` logic |

### The Idiomorph algorithm, precisely (v0.7.4, `src/idiomorph.js`)

**Step 1 — build the id maps** (`createIdMaps`, line 1142).

```
persistentIds = { id : id appears in BOTH old and new content
                       AND the two elements have the SAME tagName
                       AND the id is not duplicated on either side }
idMap: Map<Node, Set<persistentId>>   // for each node, every persistent id in its subtree, inclusive
```

Built bottom-up: for every `[id]` element whose id is persistent, walk `parentElement` up to the root adding that id to each ancestor's set (`populateIdMapWithTree`, line 1107). Two consequences that matter in practice:

* **Duplicate ids poison the well.** `createPersistentIds` (line 1166) collects any id seen twice — on either the old or the new side — into `duplicateIds` and then *deletes them from `persistentIds` entirely*. A duplicated id doesn't just fail to match; it removes that id from the matching algorithm altogether, degrading everything above it in the tree to structural guesswork. 37signals hit this in production ("The radiating programmer", dev.37signals.com).
* **Changing an element's tag breaks its identity.** `<div id="x">` → `<section id="x">` is not persistent. Idiomorph will delete and recreate, losing all state.

**Step 2 — match children** (`morphChildren`, line 276). For each child of the new parent, scanning forward from an insertion point in the old parent:

1. `findBestMatch` (line 401) scans old siblings forward. `isSoftMatch` is a **prerequisite**: same `nodeType`, same `tagName`, and *either the old element has no id, or the ids are equal*. Among soft matches, the first one that is also an `isIdSetMatch` (non-empty intersection of the two nodes' id sets) wins immediately.
2. If no id-set match, fall back to the first soft match — but with two dampers: a soft-match candidate is skipped if `ctx.idMap.has(cursor)` (it will hard-match something later, don't burn it), and soft matching is abandoned entirely if two *future* new siblings also soft-match the cursor (`siblingSoftMatchCount >= 2`), which is the anti-churn heuristic for prepends.
3. The scan **stops early** at the node containing `document.activeElement` (line 444) — deliberately refusing to look for a better match past the focused element, because moving it would reparent and blur it.
4. Old nodes skipped over are removed (`removeNodesBetween`), and the matched node is morphed in place.
5. If there is no local match but the new child has a **persistent id**, `moveBeforeById` (line 556) hunts the whole old tree *and the pantry* for that id and relocates it here.
6. Otherwise `createNode` (line 367): if the new node's subtree contains persistent ids, insert an **empty element of the same tag** and recursively morph into it (so nested stateful descendants can be pulled in from elsewhere); otherwise `document.importNode(newChild, true)` and insert the clone.

**Step 3 — the pantry.** `removeNode` (line 514): if a doomed old node appears in `idMap` (i.e. it or a descendant holds a persistent id that the new content still wants), it is **moved into a hidden `<div>` appended after `</body>`**, not deleted. It can be pulled back later in step 2.5. Critically, **pantried nodes skip the removal callbacks** — so `beforeNodeRemoved`/`afterNodeRemoved` (and therefore Turbo's events) do not fire for them. This is the mechanism that lets idiomorph reorder a list without destroying state, and it is also the reason "an element vanished and I got no event" happens.

**Step 4 — moves.** `moveBefore` (line 604) uses the Chromium `Element.moveBefore()` API when available, falling back to `insertBefore()`. This matters enormously: `moveBefore()` relocates a node **without disconnecting it**, so iframes don't reload, `<video>` doesn't pause, CSS transitions don't restart and custom elements don't re-run `connectedCallback`. `insertBefore()` does all of those things. So **the same morph behaves differently in Chrome than in Safari/Firefox** until `moveBefore` ships everywhere. (brunoprietog cites this as the eventual fix for Stimulus lifecycle ordering: hotwired/stimulus#808.)

**Step 5 — attributes** (`morphAttributes`, line 673):

```js
for (const newAttribute of newAttributes) {
  if (oldElt.getAttribute(newAttribute.name) === newAttribute.value) continue
  if (ignoreAttribute(newAttribute.name, oldElt, "update", ctx)) continue
  oldElt.setAttribute(newAttribute.name, newAttribute.value)
}
for (let i = oldAttributes.length - 1; 0 <= i; i--) {          // backwards: live NamedNodeMap
  const oldAttribute = oldAttributes[i]
  if (!oldAttribute) continue
  if (!newElt.hasAttribute(oldAttribute.name)) {
    if (ignoreAttribute(oldAttribute.name, oldElt, "remove", ctx)) continue
    oldElt.removeAttribute(oldAttribute.name)
  }
}
```

**Every attribute on the live element that is absent from the server's HTML is removed.** That single loop is the entire Stimulus-values conflict, the `<details open>` conflict, the `<dialog open>` deadlock, the `contenteditable` loss on Trix, and the web-component "lost my `hydrated` class" problem. There is no allowlist and no heuristic — the server's HTML is total truth for attributes.

**Step 6 — form-control properties** (`syncInputValue`, line 732). Attributes are not enough for form controls, because the *property* diverges from the *attribute* as soon as the user types. Idiomorph therefore additionally:

* `<input>` (except `type="file"`): syncs `checked` and `disabled` as boolean attributes-plus-properties; if the new element **has no `value` attribute at all**, it does `oldElement.value = ""` and removes the attribute; otherwise if values differ it sets both attribute and property.
* `<option>`: syncs `selected`.
* `<textarea>`: syncs `.value` **and** `firstChild.nodeValue`.

So: *server HTML that omits `value=` clears the field.* That is the intended semantic (it is how "submit the form, get an empty form back" works), and it is also why a typeahead that auto-submits while you keep typing eats your keystrokes (turbo#1199).

**Step 7 — focus restoration** (`saveAndRestoreFocus`, line 208). Only if `document.activeElement` is an `<input>` or `<textarea>`. Records `id`, `selectionStart`, `selectionEnd`; after the morph, if focus moved away and the id still resolves, re-focus and `setSelectionRange`. Guarded by try/catch since Turbo 8.0.21-ish because `setSelectionRange` throws on `type=number|email|date` (turbo#1538, fixed upstream in idiomorph).

### The events Turbo dispatches

All from `src/core/morphing.js` class `DefaultIdiomorphCallbacks`, plus `MorphingPageRenderer` / `MorphingFrameRenderer`.

| Event | Idiomorph hook | `target` | `detail` | Cancelable | `preventDefault()` does |
|---|---|---|---|---|---|
| `turbo:before-morph-element` | `beforeNodeMorphed` | the **current** (surviving) element | `{ currentElement, newElement }` | **yes** | skips the entire node — attributes *and* children. Identical to marking it `data-turbo-permanent` for this morph only |
| `turbo:before-morph-attribute` | `beforeAttributeUpdated` | the element being mutated | `{ attributeName, mutationType: "update" \| "remove" }` | **yes** | that one attribute is left alone |
| `turbo:morph-element` | `afterNodeMorphed` | the morphed element | `{ currentElement, newElement }` | no | — |
| `turbo:morph` | end of `MorphingPageRenderer.renderElement` | `document` | `{ currentElement, newElement }` | no | — |
| `turbo:before-frame-morph` | start of `MorphingFrameRenderer.renderElement` | the `<turbo-frame>` | `{ currentElement, newElement }` | no | — |

Three gotchas the official docs do not state:

1. **The official events reference lists only `newElement` in `detail`** for `turbo:before-morph-element` / `turbo:morph-element`. The source dispatches `{ currentElement, newElement }`. Both are present; `event.target` and `event.detail.currentElement` are the same node.
2. **`beforeNodeRemoved` is wired to `beforeNodeMorphed(node)` with one argument**:
   ```js
   beforeNodeRemoved = (node) => { return this.beforeNodeMorphed(node) }
   ```
   So a `turbo:before-morph-element` event **also fires for elements that are about to be deleted**, with `event.detail.newElement === undefined`. Cancelling it prevents the removal. This is undocumented and is exactly what confused the reporters of turbo#1279 and turbo#1415. It is also the only removal hook you get.
3. **Pantried nodes fire nothing.** If a node is being relocated via the pantry, `removeNode` short-circuits before the callbacks. So "element disappeared and reappeared elsewhere" produces no before/after-remove signal at all.

Add/remove-specific events (`turbo:before-morph-element-added` / `-removed`) are **proposed but not shipped** — issue #1477 (open, Dec 2025), PR #1482 (open, Jan 2026, unreviewed).

### Rails-side plumbing

```erb
<%= turbo_refreshes_with method: :morph, scroll: :preserve %>
<%# => <meta name="turbo-refresh-method" content="morph">
       <meta name="turbo-refresh-scroll"  content="preserve"> %>
```

`Turbo::DriveHelper#turbo_refreshes_with` (turbo-rails `app/helpers/turbo/drive_helper.rb`) validates `method ∈ {replace, morph}` and `scroll ∈ {reset, preserve}`, raising `ArgumentError` otherwise, and `provide :head` — so it needs `yield :head` in the layout, or use the `_tag` variants.

Broadcast side (`app/models/concerns/turbo/broadcastable.rb`):

```ruby
def broadcasts_refreshes(stream = model_name.plural)
  after_create_commit  -> { broadcast_refresh_later_to(stream) }   # to the collection stream
  after_update_commit  -> { broadcast_refresh_later }              # to the record's own stream
  after_destroy_commit -> { broadcast_refresh }                    # synchronous, record's stream
end

def broadcasts_refreshes_to(stream)
  after_commit -> { broadcast_refresh_later_to(stream.try(:call, self) || send(stream)) }
end
```

Note the asymmetry (create → collection stream, update/destroy → record stream). This surprises people constantly; brunoprietog's rationale in turbo-rails#545: "That's because you don't have a record before creation." The practical implication is that a parentless collection index page must `turbo_stream_from` *each* record as well as the collection, or use `broadcasts_refreshes_to ->(s) { s.class.broadcast_target_default }`.

**The dedup mechanism** (this is the part people get wrong):

1. Every Turbo fetch appends `X-Turbo-Request-Id: <uuid>` and remembers the uuid in a client-side `LimitedSet(20)` (`src/http/fetch.js:4-10`).
2. `Turbo::RequestIdTracking` puts it in `Turbo.current_request_id` for the duration of the Rails request.
3. `broadcast_refresh_later_to` stamps it into `<turbo-stream action="refresh" request-id="…">`.
4. Client-side `StreamActions.refresh` calls `session.refresh(this.baseURI, { method, requestId, scroll })`.
5. `Session#refresh` (`src/core/session.js:107`):
   ```js
   const isRecentRequest = requestId && this.recentRequests.has(requestId)
   const isCurrentUrl = url === document.baseURI
   if (!isRecentRequest && !this.navigator.currentVisit && isCurrentUrl) {
     this.visit(url, { action: "replace", shouldCacheSnapshot: false, refresh: { method, scroll } })
   }
   ```

So the tab that *caused* the change ignores its own broadcast; everyone else refreshes. Escape hatch: `turbo_stream.refresh(request_id: nil)`.

**Two independent debouncers:**

| Layer | Default | Configurable |
|---|---|---|
| Client `Session#pageRefreshDebouncePeriod` | 150 ms | `Turbo.session.pageRefreshDebouncePeriod = 250` |
| Server `Turbo::Debouncer::DEFAULT_DELAY` (used by `broadcast_refresh_later_to`) | 0.5 s | not exposed via `config`; tests swap in `Turbo::ImmediateDebouncer` |

Only *refreshes* are debounced. Targeted `append`/`replace`/`prepend` broadcasts are not.

---

## The exact rules

### Rule 1 — the morph predicate

```js
// src/core/drive/page_view.js:18-20
const shouldMorphPage = this.isPageRefresh(visit)
  && (visit?.refresh?.method || this.snapshot.refreshMethod) === "morph"

// :58-60
isPageRefresh(visit) {
  return !visit || (this.lastRenderedLocation.pathname === visit.location.pathname
                    && visit.action === "replace")
}
```

Both conditions must hold. Broken down:

| Condition | Detail |
|---|---|
| **Same pathname** | `lastRenderedLocation.pathname === visit.location.pathname`. **Query string is ignored** (PR #1079). Hash is ignored. |
| **`action === "replace"`** | Link clicks default to `advance` → **never morph**. Form submissions that redirect to the current location were changed to default to `replace` in PR #1072, which is why "submit form, redirect back, morph" is the happy path. |
| **`method === "morph"`** | From `<turbo-stream action="refresh" method="morph">` if present, else the `turbo-refresh-method` meta of `this.snapshot` — i.e. **the currently-rendered page's** meta tag, not the incoming response's. PR #1123 briefly changed this to the incoming snapshot; PR #1208 changed it back while adding stream attributes. So: *the page you are leaving decides whether the morph happens.* |

### Rule 2 — the query-string trap, in both directions

The pathname-only comparison is a deliberate design choice (brunoprietog, PR #1079: *"search params don't determine whether it is a refresh or not… a `show` action could have different search params, but in essence, it remains the same action and the same page"*). It produces two opposite surprises.

**Trap A — morphing when you didn't want it.** `/posts?filter=open` → `/posts?filter=archived` with `data-turbo-action="replace"` is a page refresh, so Turbo morphs a completely different list into the old one. Turbo's own test suite asserts this behaviour: *"renders a page refresh with morphing when the paths are the same but search params are different"* (`page_refresh_tests.js:139`). If the two states share ids, you get correct-but-animated results; if they share ids that mean different things, you get id-set matches across semantically unrelated rows.

**Trap B — silently not morphing.** `lastRenderedLocation` is Turbo's record of the last *page* it rendered. A `<turbo-frame data-turbo-action="advance">` updates the browser URL **without** updating `lastRenderedLocation`. Submit a form afterwards, redirect to the (visible) current URL, and `isPageRefresh` compares the new pathname against the *stale* one, returns false, and you get a full body replace that destroys your modal. This is turbo#1214 (open since 2024-03-01, confirmed still live by `phiele` in March 2026), and the same root cause reported against `turbo_stream.refresh` from inside frame modals.

**Corollary trap C — different paths never morph, and there is no override.** PR #1145 (`data-turbo-replace-method="morph"`) was rejected. jorgemanrubia's stated rationale (turbo#1085): snapshot caching assumes distinct `body` elements, and "does browser history make sense with morphing?" brunoprietog agreed the restriction pushes people toward fat controllers with mode params "just to be able to take advantage of morphing" — and it still does. Issues #1085, #1177, #1339, #1316 are all this, all still open.

### Rule 3 — what else changes under a morph visit

| Behaviour | Under morph |
|---|---|
| `<head>` | merged by Turbo's `mergeHead()`, exactly as under replace. Stylesheet/script tracking, `data-turbo-track="reload"` full-reload on asset change (PR #1146), all unchanged |
| `<body>` scripts | **not re-executed.** The existing `<script>` node is patched, never re-inserted, so it never re-runs. Anything that injected DOM from a body script is lost and not re-injected (donnysim, turbo#1083) |
| Snapshot caching | skipped — `shouldCacheSnapshot: false` for refresh visits (PR #1196); no cached preview is rendered (PR #1098) |
| Autofocus | disabled (`shouldAutofocus === false`) |
| 422 / unprocessable content | **does morph.** Turbo's test `"renders unprocessable content responses with morphing"` asserts it. This is why "submit invalid form → validation errors render → my date picker is dead" is the single most-reported morph bug |
| Scroll | `Visit#performScroll` is skipped entirely when `shouldPreserveScrollPosition(visit)` — see [Interactions](#morph--scroll-restoration) |
| Progress bar | still shown; opt-out proposed in PR #1270, still open (issue #1211) |
| `turbo-visit-control: reload` | honoured (was broken in beta, fixed via #1116 by making `MorphingPageRenderer` inherit `PageRenderer`) |

### Rule 4 — `<turbo-stream action="refresh">` gating

A refresh stream is a *request* for a page refresh, not a render. It is dropped silently if **any** of:

* `requestId` is in the client's last-20 request ids (you caused it);
* a Visit is already in flight (`navigator.currentVisit`);
* the stream's `baseURI` ≠ `document.baseURI`.

and it is debounced 150 ms client-side. If it survives all that, it becomes `visit(url, { action: "replace", … })` — which then still has to pass Rule 1.

---

## The Stimulus values conflict — complete picture

### The bug

Reported as **[hotwired/turbo#1210, "Turbo morph not preserving stimulus values"](https://github.com/hotwired/turbo/issues/1210)** by `rbclark` on 2024-03-01, with a reproduction repo (`rbclark/turbo-8-stimulus-bug-demo`) and a video.

> "I am using Turbo 8 morphing and I am noticing that all my controller values are reset when my page morphs. This behavior is a bit confusing since the `connect` callback is also skipped in these situations."

Two distinct failures compounding:

1. **Values are clobbered.** A `data-foo-value` attribute the controller wrote at runtime is not in the server's HTML, so `morphAttributes` removes it. A `data-foo-value` the controller *changed* is overwritten with the server's value.
2. **`connect()` does not re-run.** The element was never disconnected — it is literally the same node — so Stimulus has nothing to react to. `initialize()`, `connect()` and `disconnect()` are all silent. Only `[name]ValueChanged` and `[name]TargetConnected/Disconnected` fire, and only when the corresponding attribute or target actually changed.

The compound case is the nasty one, and it is the *default* shape of a Stimulus controller that wraps a JS library: `connect()` builds a widget → widget mutates the DOM → morph reverts the mutation → element was never removed → `connect()` never re-runs → widget is now a corpse with no hook to resurrect it.

### Current status (2026-08-15)

| Issue | State | Notes |
|---|---|---|
| **turbo#1210** — morph not preserving Stimulus values | **OPEN**, 2 years 5 months, **no labels, no assignee, no linked PR** | one maintainer comment total (seanpdoyle, day one) |
| turbo#1083 — JS-lib DOM mutations lost on morph | **CLOSED** 2025-03-04 by jorgemanrubia, wontfix-in-Turbo | the definitive maintainer statement |
| turbo#1087 — stale `<template>` contents under morph | **CLOSED** 2025-03-03 | genuinely fixed, upstream in idiomorph PR #49 → 0.4.0, shipped to Turbo 8.0.13 |
| turbo#1224 — inconsistent disconnect/reconnect | **CLOSED** same day, by reporter | "morphing intentionally does not disconnect & reconnect stimulus when it's bound to an element which doesn't change" |
| stimulus#775 — no connect after redirect to same URL | **CLOSED** 2025-03-04 | includes the 422-validation-error case |
| stimulus#808 — wrong lifecycle order (connect-connect-disconnect) | **CLOSED** 2025-03-23 by brunoprietog | "This is part of the flow of Idiomorph and Stimulus is not responsible… Possibly, it's something that will be solved with… `moveBefore`" |
| stimulus#829 — connect not triggered on validation re-render | **CLOSED** 2025-03-23 by brunoprietog | "**This is by design.**" |
| **stimulus#801** — *helper functions for morph inhibition in Stimulus* | **CLOSED** 2025-03-23, **converted to [discussion #830](https://github.com/hotwired/stimulus/discussions/830) and locked** by brunoprietog | the only reply is one sentence pointing at `data-action` modifiers |
| turbo#1477 / PR #1482 — add/remove morph events | **OPEN**, unreviewed | community PR, Jan 2026 |
| turbo PR #1319 — export `morphElements`/`morphChildren` | **MERGED** 2025-09-21 | the escape hatch maintainers *did* ship |

**Verdict on status: the conflict is open, unowned, and the maintainers have said in three separate threads that they will not fix it by default.** There is no work in progress on either side. The only movement in two years has been (a) the events from PR #1097 (Dec 2023), (b) exporting the morph functions (PR #1319, Sep 2025), and (c) upstream idiomorph correctness work by `botandrose`.

### The maintainer position, verbatim

**jorgemanrubia**, closing turbo#1083 (2025-03-04) — the load-bearing quote:

> "Indeed, when using morphing, the components you use should be prepared to handle DOM modifications to reset (or adapt) their state accordingly. There is not much that Turbo can do in general here, since each component is different. **We originally considered triggering a stimulus reconnect automatically for all the controllers, but that assumes too much. Often, you want controllers to keep the state they have when a page refresh happens.**
> You can rely on morphing/attribute events to let the component reset… You can also rely on value change callbacks to trigger logic when changes happen.
> I'd be happy to ease things here, but not sure what to do. **Maybe stimulus should expose a boolean option *reconnect when morphed*** so that it's easier to trigger this behavior?
> I'm closing this since there is not much Turbo can do here."

**brunoprietog**, closing stimulus#829 (2025-03-23):

> "This is by design. If you use morphing and the element doesn't change, the connect and disconnect flow won't work, because the element hasn't been disconnected! The element is the same. You can use `turbo:morph@document->controller#action`. You can also use a value that reflects the initialization state, which would trigger the `changedValueCallback`, and from there you can reset what you need."

**brunoprietog**, the entire response to stimulus#801's request for morph-inhibition helpers (discussion #830, 2025-03-23):

> "The essence of Stimulus is that you use the `data-action` attributes, instead of adding event listeners using `this.element`. Along with that, you can use modifiers like `:prevent`, `:stop`, etc."

**seanpdoyle**, turbo#1210 (2024-03-01) — the only maintainer voice sympathetic to a built-in fix:

> "**Over-committing to ignore *all* server-sent Stimulus Values feels safer than under-committing.** I'm sure with time there will be some edge cases that will emerge. […] Integration with Stimulus was the main driver behind that contribution. As the dust of the Turbo 8 release settles, I hope that there will [be] bandwidth for a coordinated effort to expand built-in Morph integration for Stimulus and Trix (and therefore Action Text). **Something that affords a configuration-less turn-key solution for most circumstances with some focused escape hatches when necessary.**"

That coordinated effort did not happen. seanpdoyle's `@hotwired/turbo/stimulus` package idea (PR #1097 description) was never built.

Note the *tension* between the two positions, because a `preserve` primitive has to pick a side: seanpdoyle thinks the safe default is to ignore server-sent values wholesale; jorgemanrubia thinks any automatic behaviour "assumes too much". Both are defensible. The repo owner's primitive should be **opt-in per controller**, which satisfies both.

### Every workaround, with a verdict

---

#### W1 — Global: block all `data-*-value` attribute morphs

The original reporter's own workaround, turbo#1210:

```js
document.addEventListener("turbo:before-morph-attribute", (event) => {
  const { detail: { attributeName } } = event
  if (attributeName.startsWith("data-") && attributeName.endsWith("-value")) {
    event.preventDefault()
  }
})
```

**Verdict: works, and is the bluntest possible instrument.** It fixes clobbering globally with three lines. But it makes the server permanently unable to change *any* Stimulus value on *any* controller — so server-driven state (`data-poll-interval-value`, `data-chart-data-value`, a wizard's `data-step-value` that the server advances) silently stops updating, and you will debug that for an hour six months later. It also cannot distinguish "value the controller owns" from "value the server owns". seanpdoyle explicitly endorsed the *philosophy* ("over-committing feels safer") but the ergonomics are bad. **Use only as a temporary bridge, never as the end state.**

---

#### W2 — Per-controller: cancel `turbo:before-morph-attribute` for this element's values

The pattern crosswire's own `03-stimulus-deep-dive.md` proposes, and what Evil Martians shipped in production:

```js
// preserve_values_controller.js
export default class extends Controller {
  preserveValues(event) {
    const { attributeName } = event.detail
    if (attributeName.startsWith("data-") && attributeName.endsWith("-value")) {
      event.preventDefault()
    }
  }
}
```
```html
<div data-controller="wizard preserve-values"
     data-action="turbo:before-morph-attribute->preserve-values#preserveValues">
```

**Verdict: works, correct scope, poor ergonomics.** Requires a second controller on every element that needs it and a `data-action` the consumer must remember. Because `turbo:before-morph-attribute` **bubbles**, a listener on the controller element also fires for descendants — so you must check `event.target === this.element` if you only mean the root, which the naive version above does not. Evil Martians generalised this into a bespoke `data-turbo-morph-permanent-attrs` attribute for a fintech wizard ([Evil Martians, 2025-06-24](https://evilmartians.com/chronicles/hotwire-rails-summit-interactive-multi-step-forms-peak-ux)) — i.e. two independent teams reinvented the same primitive, which is the strongest argument that it should exist.

---

#### W3 — Per-controller: cancel `turbo:before-morph-element` (full opt-out)

From stimulus#801's original post (the request that got closed):

```js
// in initialize()
this.element.addEventListener("turbo:before-morph-element", (event) => {
  if (event.target === this.element) event.preventDefault()
})
```

**Verdict: works, and is the sledgehammer.** It makes the subtree immune — attributes *and* children. Equivalent to `data-turbo-permanent` scoped to one morph. Correct for a modal, a rich text editor, a mounted map. Wrong for anything whose *content* the server still owns, because now the server can never update it. Note the `event.target === this.element` guard is mandatory (the event bubbles from descendants).

The declarative form brunoprietog implicitly endorses is:

```html
<div data-controller="modal" data-action="turbo:before-morph-element->modal#preventMorph">
```
with `preventMorph(e) { if (e.target === this.element) e.preventDefault() }`. Stimulus's `:prevent` action modifier (`turbo:before-morph-element:prevent->modal#noop`) works too but still needs a method to point at, which is why the "helper functions" request existed in the first place.

---

#### W4 — `data-turbo-permanent`

```html
<div data-turbo-permanent>…</div>
```

**Verdict: works under morph, and is the officially documented answer.** Handled in `DefaultIdiomorphCallbacks.beforeNodeMorphed`, so the node and its whole subtree are skipped, and `beforeNodeRemoved` also refuses to delete it.

**Correction to earlier crosswire notes: under morphing, `data-turbo-permanent` does NOT require an `id`.** Source:
```js
beforeNodeMorphed = (currentElement, newElement) => {
  if (currentElement instanceof Element) {
    if (!currentElement.hasAttribute("data-turbo-permanent") && …) { … }
    else { return false }
  }
}
```
No id is consulted. The `id` is only used by `beforeNodeAdded`, to avoid inserting a *second* copy when the incoming HTML also contains it. Under **Drive replace** (Bardo), the `id` *is* mandatory — Bardo matches old and new permanent elements by id. So the rule is: **id required under replace, optional under morph** — and since almost every app uses both rendering paths, "always give it an id" is still the right advice, just for a different reason than the notes stated.

The real cost of `data-turbo-permanent` is that it is not morph-scoped: it also survives ordinary Drive navigations to *different* pages, which is usually not what you want. `danielfriis` in turbo#1083: *"I did use `data-turbo-permanent` to begin with, but I realised it also preserves the element on page navigation, making it unusable when navigating between records."* The Campfire trick is to add/remove it dynamically (`delete this.element.dataset.turboPermanent`).

---

#### W5 — Re-initialise on `turbo:morph`

The most widely copied workaround. Final, correct form after two rounds of bug-fixing in turbo#1083:

```js
export default class extends Controller {
  connect() {
    this.reconnect = this.reconnect.bind(this)   // stable reference — REQUIRED
    window.addEventListener("turbo:morph", this.reconnect)
    this.create()
  }
  disconnect() {
    window.removeEventListener("turbo:morph", this.reconnect)
    this.destroy()
  }
  reconnect() { this.destroy(); this.create() }
}
```

**Verdict: works, but it is a minefield and the community got it wrong twice in public.**

* **Do not** write `reconnect() { this.disconnect(); this.connect() }` — Michoels did, and reported *"an exponentially increasing population of event listeners and Popper objects. Browser was not happy, and performance slowed to a crawl after 10-15 refreshes."* Because `connect()` re-adds the listener, each morph doubles them.
* **Do not** pass a fresh function to `addEventListener`/`removeEventListener` — `danieldiekmeier` caught Michoels leaking listeners because `this.reconnect(this) !== this.reconnect(this)`.
* `turbo:morph` fires **once on first refresh, then twice per refresh thereafter** if previews are in play (weaverryan observed it; brunoprietog explained it as cached-preview-then-response). Under current Turbo, previews are disabled for morphs (PR #1098), so this should be single-fire now — but **teardown must be idempotent regardless.**
* It fires on `window` for *every* page morph, so every controller on the page re-initialises whether or not anything under it changed. On a page with 188 Trix editors this hung the browser for seconds (`doits`, turbo-rails#533).

---

#### W6 — Re-initialise on `turbo:morph-element` scoped to the element

```html
<div data-controller="tom-select"
     data-action="turbo:morph-element->tom-select#reconnect">
```

**Verdict: strictly better than W5 and under-used.** `turbo:morph-element` fires *on the morphed element* (and bubbles), so you only re-initialise when something in your own subtree actually changed. This is what `hotwire_combobox` does ([josefarias/hotwire_combobox#132](https://github.com/josefarias/hotwire_combobox/pull/132)). Caveat: because it bubbles, a listener on the root fires once per morphed descendant — you must debounce or check `event.target`. m3thom's Select2 solution in turbo#1083 shows the shape.

---

#### W7 — Server-renders-the-truth + `[name]ValueChanged`

jorgemanrubia's and brunoprietog's actual recommendation: never let the controller own the value. Have the server render the current value into the attribute, and put reinitialisation logic in the value-changed callback.

```js
static values = { renderedAt: String }
renderedAtValueChanged() { this.destroy(); this.create() }
```
```erb
<div data-controller="widget" data-widget-rendered-at-value="<%= @record.updated_at.to_i %>">
```

**Verdict: this is the architecturally correct answer and it genuinely works — when you control the HTML.** It reframes "reinitialise on morph" as "reinitialise when the server says the data changed", which is more precise *and* cheaper than W5. Two real limitations:

* `m3thom` in turbo#1083 documented a case where a value *derived from a combination* of conditions did not fire its change callback after morph (repro: `m3thom/morph-and-value-change-callbacks-repro`) — because the attribute did not itself change. If the value isn't in the HTML, the callback can't fire. His fix was to move the derivation server-side and render it.
* It does nothing for state the server genuinely does not know about (is the dropdown open? which tab is selected? has the user dismissed the banner?). For those you are back to W2/W3.

---

#### W8 — `replaceWith(event.detail.newElement)` to force a real reconnect

`mnrlx`, turbo#1097:

```js
connect() { this.element.addEventListener("turbo:before-morph-element", this.reconnect.bind(this)) }
reconnect(event) { this.element.replaceWith(event.detail.newElement) }
```

**Verdict: works and is clever, but it throws away everything morphing bought you.** It converts a morph into a replace for that subtree: the element is genuinely removed and re-added, so `disconnect()`/`connect()` fire properly *and* the server's new attributes and children win. You lose focus, scroll-within, media playback and CSS transition state inside that subtree — but if the subtree is a self-contained widget you didn't want morphed anyway, that's fine. It's essentially a manual "atomic replace" and is the closest thing anyone has shipped to `chloerei`'s proposed `data-turbo-atomic` (turbo#1083). **Note:** cancelling the event is not needed — `replaceWith` during `beforeNodeMorphed` mutates the DOM mid-morph, which idiomorph's maintainer says is unsupported (idiomorph#140: *"mutating the DOM mid-morph is not supported"* — botandrose). It works today; it is not guaranteed to keep working. **[risk flagged]**

---

#### W9 — `MutationObserver` inside the controller

brunoprietog's first suggestion in turbo#1083, before the events existed:

```js
initialize() { this.mutationObserver = new MutationObserver(this.handleMutation.bind(this)) }
connect()    { this.mutationObserver.observe(this.element, { childList: true, subtree: true }) }
disconnect() { this.mutationObserver.disconnect() }
```

**Verdict: superseded. Do not use.** This is what Symfony LiveComponents had to do before morph events existed (weaverryan's "complex MutationObserver system"). It fires for the widget's *own* mutations too, so you need re-entrancy guards, and it's strictly more expensive than `turbo:morph-element`. Kept here only because it appears in old blog posts.

---

#### W10 — Add a dummy query param to defeat the morph

`elsurudo`, stimulus#775: *"I was able to get around the issue by adding a 'dummy' param (for example `success=true`) to the path I redirect to to force the disconnect/reconnect."*

**Verdict: does not work, and did not work when it was posted.** `isPageRefresh` compares `pathname` only (PR #1079, merged 2023-12-07, ~6 months before that comment). Adding a query param does not defeat morph detection. To actually force a replace you must change the **path**, or set `<meta name="turbo-refresh-method" content="replace">` on the page you're leaving. This workaround circulates; it is wrong. **[corrected]**

---

#### W11 — `stimulus-durable-values` (npm)

The only shipped library that attacks this directly: [`asgerb/stimulus-durable-values`](https://github.com/asgerb/stimulus-durable-values) (0 stars, last push 2024-09-19).

```js
import { DurableValuePropertiesBlessing } from "stimulus-durable-values"
Controller.blessings.push(DurableValuePropertiesBlessing)
```
```js
export default class extends Controller {
  static values = { open: Boolean }
  static durableValues = ["open"]
}
```

Mechanism: it wraps Stimulus's `ValuePropertiesBlessing`. The setter records the value in `this.durableValues[key]` as well as writing the attribute; the generated `[name]ValueChanged` callback checks whether the DOM value diverged from the recorded one and, if so, **writes the recorded value back**.

**Verdict: the right *idea*, the wrong *layer*, and unmaintained.** It works because morph → attribute change → `valueChanged` fires → controller re-asserts its own value. That is elegant: it needs no morph events, no `data-action`, and works with any morph implementation (htmx, Datastar, whatever). Problems: (a) it reaches into `@hotwired/stimulus/dist/core/*` internals that are not public API and will break; (b) it makes the value *permanently* controller-owned — the server can never change it again, same failure mode as W1 but scoped; (c) it fights the morph after the fact rather than preventing it, so you get a brief inconsistent frame and a spurious `valueChanged` invocation; (d) zero adoption, zero maintenance. **Excellent prior art for the design brief. Do not depend on it.**

---

#### Workaround summary table

| # | Approach | Prevents clobber | Restores `connect()` | Server can still update | Scope | Verdict |
|---|---|---|---|---|---|---|
| W1 | global block `data-*-value` | ✅ | ❌ | ❌ **never** | global | temporary bridge only |
| W2 | per-controller `before-morph-attribute` | ✅ | ❌ | ❌ for values | element | works; ergonomics poor |
| W3 | per-controller `before-morph-element` | ✅ | ❌ | ❌ at all | subtree | correct for opaque widgets |
| W4 | `data-turbo-permanent` | ✅ | ❌ | ❌ at all | subtree | official; leaks into Drive nav |
| W5 | re-init on `turbo:morph` | ❌ | ✅ (manual) | ✅ | page-wide | works; leak/perf minefield |
| W6 | re-init on `turbo:morph-element` | ❌ | ✅ (manual) | ✅ | element | **best general reinit** |
| W7 | server-rendered value + `ValueChanged` | n/a | ✅ (manual) | ✅ | element | **architecturally correct** |
| W8 | `replaceWith(newElement)` | ❌ | ✅ (real) | ✅ | subtree | works; unsupported mid-morph mutation |
| W9 | `MutationObserver` | ❌ | ✅ (manual) | ✅ | element | superseded |
| W10 | dummy query param | ❌ | ❌ | — | — | **does not work** |
| W11 | `stimulus-durable-values` | ✅ (after the fact) | ❌ | ❌ | value | prior art; unmaintained |

**The honest summary for a crosswire user today:** use **W7** where the server knows the state, **W6** where it doesn't and the widget must reinitialise, **W3/W4** where the widget must never be touched, and **W2** for the specific case of a controller-owned value the server must not stomp. There is no single answer, which is precisely the gap a `preserve` primitive would fill.

---

## What breaks under morph — the full inventory

Symptom → cause → fix. Every row is traceable to an issue thread or to the source.

| # | Symptom | Cause | Fix | Evidence |
|---|---|---|---|---|
| **1** | **Stimulus controller wrapping a JS library dies after any form submit / validation error.** TomSelect, Select2, Flatpickr, Chart.js, Leaflet, Popper, Shoelace | Library's injected DOM is not in the server HTML → morph removes it. Element itself survives → `connect()` never re-runs → no hook to rebuild | W6 (`turbo:morph-element->x#reconnect`) or W3/W4 if the widget owns the region | turbo#1083; turbo-rails#533, #552; stimulus#808, #829 |
| **2** | **Stimulus `data-*-value` written at runtime vanishes; server value overwrites controller value** | `morphAttributes` removes every attribute absent from the server HTML and overwrites every one that differs | W7 preferred; W2 if the value is genuinely controller-owned | turbo#1210 (**open**) |
| **3** | **`<dialog>` opened with `showModal()` leaves the page permanently un-clickable** | Morph *removes the `open` attribute*, which per HTML spec does **not** call `close()`, does not fire `close`, and **leaves the document blocked by the top layer** | Global listener: cancel the `open`-attribute removal and call `.close()` yourself (below) | turbo#1239 (**open since 2024-04**, reconfirmed 2026-06) |
| **4** | **`<details open>` snaps shut on every refresh** | same attribute-removal mechanism | cancel `turbo:before-morph-attribute` for `open`, or render the real state server-side | idiomorph#58; turbo#1415 |
| **5** | **Trix / Action Text editor goes read-only and loses its toolbar** | Action Text renders `<trix-editor>` with no `innerHTML` and **no `contenteditable`** (Trix adds it at runtime) → morph removes `contenteditable` and empties the editor; `<trix-toolbar>` is emptied too | wrap **both** editor and toolbar in a `data-turbo-permanent` container (afcapel's official answer) | turbo#1142, turbo-rails#533 |
| **6** | **User's keystrokes are eaten by an auto-submitting search box** | User types while the request is in flight; response contains `value="<what was submitted>"`; `syncInputValue` overwrites the newer text. `ignoreActiveValue` was added for exactly this and then reverted | Toggle `data-turbo-permanent` on `focusin`, remove on `focusout` — the officially blessed answer | turbo#1194, #1199; PRs #1141, #1195 |
| **7** | **Form doesn't clear after successful submit** (the mirror image of #6) | was caused by `ignoreActiveValue: true`; now caused by server HTML omitting `value=` while the field is `data-turbo-permanent` | ensure the server renders `value=""`; or `turbo:submit-end → form.reset()` | turbo#1194 |
| **8** | **`<select>` shows the wrong option after options change** | idiomorph bug matching `<option>` sets | fixed in idiomorph, shipped via turbo PR #1122 | turbo#1119 (closed) |
| **9** | **Web components lose their styling / default attributes** | morphing never re-runs a custom element's `constructor()`; anything the constructor reflected onto the host is gone. Shoelace's rendered buttons go unstyled | Render all default attributes server-side (Shoelace maintainer KonnorRogers' answer), or move state into shadow DOM, or `data-turbo-permanent` | turbo-rails#552; idiomorph#57 |
| **10** | **`<turbo-cable-stream-source>` stops receiving broadcasts after a morph** | idiomorph *merges attributes* on the element rather than replacing it, so `connectedCallback()` never re-runs and the new `signed-stream-name` is never subscribed | Fixed upstream via `observedAttributes` + `attributeChangedCallback` (turbo-rails PR #650). If on an older version: `turbo:morph-element` → `target.outerHTML = newElement.outerHTML` | turbo-rails#638 |
| **11** | **`<template>` contents are stale** | idiomorph did not descend into `DocumentFragment` | Fixed: idiomorph PR #49 → 0.4.0, in Turbo since 8.0.13. Older versions: copy `innerHTML` on `turbo:morph-element` | turbo#1087; idiomorph#15 |
| **12** | **Body `<script>` never re-runs; anything it injected is gone forever** | the `<script>` node is patched, not re-inserted, so the browser doesn't re-execute it | move initialisation into a Stimulus controller or a custom element; do not rely on inline body scripts | donnysim, turbo#1083 |
| **13** | **An element appended to `<body>` by JS (global tooltip, portal, dropdown layer) is deleted on every morph** | the morph reaches the appended node *after* the controller re-created it and finds no counterpart in the server HTML | render the portal container server-side and mark it `data-turbo-permanent`; or append inside a permanent wrapper | donnysim, turbo#1097 |
| **14** | **Permanent elements get shuffled onto the wrong parents; a form updates the wrong record** | a `replace` stream action followed by a `refresh` morph desynchronises `#el-N`/`#perma-N` pairings | none known; avoid mixing targeted replace and refresh on the same subtree | turbo#1262 (**open**) |
| **15** | **Duplicate `id`s cause elements to disappear or morph into the wrong place** | duplicated ids are *stripped from `persistentIds` entirely*, degrading matching for their whole ancestor chain | audit: `const ids=[...document.querySelectorAll('[id]')].map(e=>e.id); ids.filter((v,i)=>ids.indexOf(v)!==i)` | idiomorph source line 1166; 37signals' "The radiating programmer" |
| **16** | **Morphing doesn't happen at all after navigating via a frame with `data-turbo-action="advance"`** | `lastRenderedLocation` is stale; `isPageRefresh` compares against the wrong pathname | move the action to the page level, or override `StreamActions.refresh` (phiele's patch in the thread) | turbo#1214 (**open**) |
| **17** | **Scroll jumps to top even with `scroll: preserve`** | `preserve` only applies to *page refreshes*; ordinary `advance` navigations always reset. Nested scroll containers are only preserved if their elements survive the morph | see [Interactions](#morph--scroll-restoration) | turbo#37 (open since 2020); turbo#1272 |
| **18** | **Frame content scroll resets when the frame morphs** | frame morphing has no scroll preservation | Intrepidd's `turbo:before-frame-render` wrapper (in the thread) | turbo#1272 (**open**) |
| **19** | **Lazy frame + page refresh race: elements inside the lazy frame are removed mid-flight** | the page morph runs while the frame is still loading; the frame's contents aren't in the page response, so idiomorph deletes them | no fix; issue asks Turbo to exclude in-flight frames | turbo#1415 (**open**) |
| **20** | **A "refresh storm": several refreshes per second, browser cancels requests, Heroku logs fill with H27/499** | mass updates each triggering `broadcast_refresh_later` | client debounce (`Turbo.session.pageRefreshDebouncePeriod`) landed via PR #1099; also `suppressing_turbo_broadcasts`, and drop `touch: true` chains | turbo-rails#544 |
| **21** | **`TypeError: activeElement.setSelectionRange is not a function`** | `restoreFocus` calls `setSelectionRange` on inputs that don't support it (`number`, `email`, `date`) | fixed upstream in idiomorph (try/catch); ensure Turbo ≥ the release carrying it | turbo#1538; idiomorph#151 |
| **22** | **`removeElementFromAncestorsIdMaps` throws `Cannot read properties of null (reading 'id')`** | idiomorph ≤0.7.2 bug | fixed in idiomorph 0.7.3/0.7.4 → Turbo 8.0.18+ | turbo#1393 |
| **23** | **DaisyUI drawer flashes open on back-navigation** | checkbox `checked` state restored from a cached snapshot then morphed away | `<meta name="turbo-cache-control" content="no-cache">` | turbo#1370 (**open**) |
| **24** | **Alpine.js `@change` / `:class` shorthand attributes throw during morph** | `setAttribute` rejects those names in some paths | open upstream | idiomorph#147 (**open**) |
| **25** | **Custom element that removes itself in `connectedCallback` duplicates whole page sections** | mutating the DOM during a morph is unsupported | move the behaviour into shadow DOM; never mutate during morph | idiomorph#140, botandrose |
| **26** | **Infinite scroll: one refresh re-fetches every accumulated page.** User is 10 pages deep, clicks "like", and the morph reloads all 10 | the page response only contains page 1; a `refresh="morph"` frame reloads from `src`, so accumulated pages are refetched | none clean. Reported against **HEY Calendar itself** in the thread. Mitigate by making the accumulated region a `refresh="morph"` frame whose `src` encodes the accumulated range | turbo#1276 (**open**) |
| **27** | **Horizontally/vertically scrolled inner panes reset or shuffle when content is prepended** | new content inserted at the top changes sibling ordering; panes whose elements are recreated lose `scrollLeft`/`scrollTop` | give each pane a stable `id`; see #17/#18 | turbo#1130 (**open**) |
| **28** | **A frame link with `data-turbo-action="advance"` permanently deletes every `[data-turbo-temporary]` element on the page** | the promoted visit has `willRender: false` but still fires `turbo:before-cache`, so `CacheObserver` strips temporaries and nothing ever restores them. Kills global modal hosts | avoid `data-turbo-temporary` on elements outside the navigated frame | turbo#1553 (**open**, Jul 2026) |
| **29** | **A `<details>` reopens for *every viewer* whenever *anyone* edits something** | `broadcasts_refreshes` + morph: the server's HTML has no `open` attribute, so every subscriber's disclosure state is reset by someone else's action | cancel `turbo:before-morph-attribute` for `open`; better, persist the state (Radan's family 3) | thoughtbot, "Turbo morphing woes" |
| **30** | **Form doesn't clear after a successful morphed POST** | the redirect renders a fresh form, but the morph reconciles it against the filled-in one; if fields are `data-turbo-permanent` (added to fix #6) they are never cleared | `data-action="turbo:submit-end->form#reset"` on the form, with a one-line Stimulus controller calling `this.element.reset()` | thoughtbot, "Turbo morphing woes"; turbo#1194 |
| **31** | **A model change never broadcasts a refresh at all** | `increment!` / `decrement!` / `update_column` / `touch`-less writes skip AR commit callbacks, so `after_update_commit` never fires | use `update!`; audit every write path on models with `broadcasts_refreshes` | thoughtbot, "Hotwire and That Syncing Feeling" |
| **32** | **Chartkick / Chart.js chart shows "Loading" forever after a morph** | Chartkick renders an inline `<script>` calling `createChart()`. Morph patches the `<script>` node instead of re-inserting it, so **it never re-executes** | `window.addEventListener('turbo:render', e => { if (e.detail.renderMethod === 'morph') Chartkick.eachChart(c => c.redraw()) })` | [chartkick#625](https://github.com/ankane/chartkick/issues/625) |
| **33** | **`<iframe>` reloads — and `data-turbo-permanent` makes it *worse*** | Bardo detaches and re-attaches the node, and browsers reconnect iframes on reattach. afcapel: *"If you mark the element with `data-turbo-permanent` **that will always happen**"* | do **not** mark iframes permanent. A plain morph is your best chance — untouched nodes are never detached — but it is not guaranteed | [turbo#1067](https://github.com/hotwired/turbo/issues/1067) |
| **34** | **A hand-rolled View Transitions wrapper breaks `data-turbo-permanent`** | a custom `turbo:before-render` → `document.startViewTransition(...)` wrapper leaves the `<meta name="turbo-permanent-placeholder">` unresolved; the permanent element is never swapped back in and vanishes | use the `view-transition` meta tag rather than wrapping the render yourself | [discuss.hotwired.dev/t/5400](https://discuss.hotwired.dev/t/5400) |
| **35** | **A user's typed-but-unsubmitted input is wiped by *someone else's* broadcast** | idiomorph compares the `value` **attribute**, not the `.value` **property**, so dirty text is invisible to the diff | `data-turbo-permanent` on focus + explicit reset stream. Structurally unsolved — see the design brief | [basecamp/turbo-8-morphing-demo#9](https://github.com/basecamp/turbo-8-morphing-demo/issues/9) (**open, on Basecamp's own demo**) |
| **36** | **Focus jumps to the first input on the page after a stream replace** | `PageRenderer#focusFirstAutofocusableElement()`. Two reporters traced it to **non-unique input `id`s** | `dom_id`-derived unique ids on every form field | [turbo#1248](https://github.com/hotwired/turbo/issues/1248) |
| **37** | **A GET filter/search form doesn't morph** | Turbo only morphs on certain response statuses; the default 200 from a GET re-render isn't one of them in that flow | return `status: :see_other` (303) for the turbo_stream format; and set `data-turbo-action="replace"` | [discuss.hotwired.dev/t/6018](https://discuss.hotwired.dev/t/6018); turbo#1339 |
| **38** | **`turbo-refresh-scroll` ignored on 422 validation re-renders** | error responses go through `renderError()`, which bypasses the scroll-handling in `renderPageSnapshot()` | none; PR #1462 open | [turbo#1449](https://github.com/hotwired/turbo/issues/1449) |
| **39** | **Users sit on stale JS after a deploy** | early Turbo 8 `MorphRenderer` didn't inherit `PageRenderer`, so the `data-turbo-track="reload"` asset-digest check was skipped | fixed in PR #1146; ensure Turbo ≥ 8.0.4 | [turbo#1105](https://github.com/hotwired/turbo/issues/1105) |
| **40** | **Mutating the DOM from inside a morph callback duplicates content and skips siblings** | two independent corruptions: (a) `insertionPoint = bestMatch.nextSibling` is `null` after you detach `bestMatch`, so every remaining new child appends at the end *and* the trailing removal loop never runs; (b) `for (const newChild of newParent.childNodes)` iterates a **live** `NodeList` by index, so moving a node out shifts the rest down and one sibling is never visited | collect replacements during the walk, apply them **after** `Idiomorph.morph()` returns, and queue `cloneNode(true)` so the new tree is never mutated | [opf/openproject#24603](https://github.com/opf/openproject/pull/24603) — the most precise public diagnosis of this class |
| **41** | **Large-DOM morphs are slow** | `findBestMatch` does a linear sibling scan per new node → approaches O(n²) on long id-less sibling lists. Idiomorph's README: *"approximately 10% slower than morphdom for large DOM morphs"* | give every repeated element a stable `id` (`dom_id(record)`) so id-set matching short-circuits the scan | idiomorph#143, #144 (both open) |

### The top 8, ranked by how often they will bite a real Rails team

1. **Stimulus-wrapped JS libraries die on validation-error re-render** (#1) — hits every app with a date picker or enhanced select, on the most ordinary flow there is.
2. **Stimulus values clobbered / `connect()` skipped** (#2) — the same root cause, one abstraction layer up; turbo#1210 open 2.5 years.
3. **`<dialog>` top-layer deadlock** (#3) — the page becomes *completely unusable*, and both `<dialog>` and morphing are on Rails' recommended path.
4. **Focused input's value overwritten mid-typing** (#6) — auto-submitting search is a canonical Hotwire demo.
5. **Trix / Action Text breaks** (#5) — ships in the Rails box; needs a `data-turbo-permanent` wrapper nobody would guess.
6. **`<details>` / disclosure state resets** (#4) — silent, ubiquitous, trivially reproducible.
7. **Duplicate `id`s degrade matching in confusing ways** (#15) — Rails partials rendered in two places make this easy, and the failure looks like "morphing is buggy".
8. **Morph silently doesn't happen** (#16, and Trap A/B generally) — you enable morphing, it works on page A, doesn't on page B, and nothing tells you why.

**The `<dialog>` fix, verbatim** (seanpdoyle, turbo#1239) — every app using `<dialog>` + morph needs this today:

```js
addEventListener("turbo:before-morph-attribute", (event) => {
  const { target, detail: { attributeName, mutationType } } = event
  if (target instanceof HTMLDialogElement && attributeName === "open" && mutationType === "remove") {
    event.preventDefault()
    target.close()
  }
})
```
brunoprietog agreed it should be built into Turbo ("Turbo is already aware of some of these peculiarities in other places"). Two years later it is not.

### Performance: the only real numbers that exist

Almost all published morph performance data comes from **Micah Geisel (`botandrose`)**, Idiomorph's lead maintainer, profiling his own production Rails app (bardtracker.com).

* **Focus preservation was the dominant cost.** idiomorph#134: *"While profiling BARD Tracker on a particularly large DOM morph, I discovered that **~90% of the morph time was being spent in `findBestMatch`**, specifically: `if (cursor.contains(document.activeElement)) break;`"*. That is the early-stop guard described in Step 2 above. **This is fixed in 0.7.4** — the CHANGELOG entry is *"Optimize focus preservation checking for big perf win (@botandrose) #137"*, and the current source uses a precomputed `ctx.activeElementAndParents.includes(cursor)` instead of a `contains()` call per cursor. If you are below Turbo 8.0.18, you are running the slow version.
* **The unshipped headroom is 10×–100×.** idiomorph#144 proposes skipping subtrees whose old and new nodes are equal: *"I'm seeing **10x in 'normal' morphs, and even upwards of 100x(!) in pathological cases**"*. The Datastar maintainer, who shipped it in their fork, measured *"around 30% less time morphing"*. Micro-benchmark from the same thread: **`isEqualNode()` is ~6× faster than comparing `outerHTML`**. It is blocked on a breaking change (morphing `<input>` → `<input>` would stop clearing `.value`).
* **Known-pathological shapes**, from idiomorph#143 on a `<ul>` with 100 unkeyed `<li>`: prepend-at-beginning and remove-first are the bad ones; append-at-end and remove-last are fine. Joel Drapper claims Morphlex handles these better via longest-increasing-subsequence matching.
* **The other half of "performance" is server load**, and only Jon Sully quantifies it: a broadcast refresh costs a full page request per viewer, so it arrives *later* than a stream broadcast by *"one hundred to a few hundred milliseconds"* (his estimate, explicitly not a measurement) and *"that's more traffic on our web servers."*
* One positive production datapoint, HN: *"I recently turned on View Morphing via upgrading Turbo 7→8 in production and man it really does feel faster. Like a free performance upgrade."*

**Practical levers, in order:** stable `id`s on repeated rows; avoid prepend/remove-first on long unkeyed lists; be on Turbo ≥ 8.0.18; be aware that a focused element deep in a large tree used to make every morph dramatically more expensive.

### Field evidence: what happened to teams who turned it on

* **thoughtbot's verdict** (Matheus Richard, Dec 2024) is the most-quoted assessment in the ecosystem, and it is negative on the default: *"morphing isn't as simple as it might seem, so **enabling it by default can be dangerous** […] **Turbo morphs are sharp knives that should be wielded with care in specific scenarios, but not something ready yet to be enabled globally.**"*
* **Rails Designer** (May 2025) could not get it working at all on a small demo app: *"my experience with it is limited **because I cannot get morphing to work easily or without experiencing unexpected side-effects. Even with this small example app, it is not working when following the docs.** […] currently it feels like a bit too much 'magic'."* Morphing does not appear in his summary recommendation list.
* **Carwow** shipped it and hit the frames wall. Their mobile filter panel lost its scroll state on every update because *"you can't morph a Turbo Frame."* They tried and abandoned manual scroll save/restore — *"we were unable to make it work without some degree of noticeable flicker/movement"* — and ended up **replacing Turbo's frame renderer with morphdom**:
  ```js
  import morphdom from "morphdom"
  addEventListener("turbo:before-frame-render", (event) => {
    event.detail.render = (currentElement, newElement) => {
      morphdom(currentElement, newElement, { childrenOnly: true })
    }
  })
  ```
* **Four documented retreats**, which is the strongest available signal: two developers downgraded to Turbo 7 outright (*"I did go back to Turbo 7 in the meantime"*, discuss#5491; *"I switched back to turbo 7.1.1 and everything works like I would expect"*, turbo#1248); one abandoned the `<dialog>` element entirely for hand-built Stimulus modals (turbo#1239); and **37signals could not upgrade HEY** for a period because of `ignoreActiveValue` (jorgemanrubia, turbo#1194).
* **Jon Sully** is the most positive documented adopter, and his retrospective is honest about scope: enabling the two meta tags fixed his blog's comment-form scroll jump *"without any changes to the back-end / controller code."* His scoping heuristic is the best one-liner in the corpus: **"If a user would reasonably expect their scroll to be reset in a navigation, it's likely that they've just navigated to a content page"** — and content pages are where refreshes belong. His commenter Keith Schacht supplies the canonical trap: *"I refactored the routes to make them a bit cleaner and **Page Refreshing stopped working. I couldn't figure out why!**"*
* **The bluntest practitioner take** (donnysim, turbo#1083): *"the moment a third party library, like a custom select, wysiwyg etc. is involved, it just messes things up […] so I'd say the real world use case is very slim."*

---

## Decision rubric: morph vs streams vs frames

### The first question is not "which tool" — it's "who owns this region's state?"

| Owner of truth | Mechanism |
|---|---|
| The server owns the whole page, and the whole page can change | **Morph** (page refresh) |
| The server owns *one region*, and that region has its own URL | **Frame** |
| The server owns *specific known elements* and knows exactly which ones changed | **Streams** |
| The server owns *one known region*, and that region has state worth preserving | **Stream + `method: :morph`** — the underrated fourth option |
| The client owns it (open/closed, selected, scroll, draft text) | none of the above — keep it out of the render path (`data-turbo-permanent`, or client-only DOM) |

That fourth row deserves emphasis because almost nobody uses it. `turbo_stream.replace(dom_id(@board), method: :morph, partial: "boards/board")` gives you **targeted** update with **morph** semantics: one partial rendered on the server, sent to one target, reconciled in place with full `data-turbo-permanent` support and all the `turbo:*morph*` events. It sidesteps the page-refresh trigger rules entirely (no same-pathname requirement, no `replace` action requirement), costs one partial render instead of N page renders, and still preserves scroll/focus/media inside the target. When someone says "I want morphing but only for this region", this is the answer — not `refresh="morph"` frames, and not a page refresh.

### The rubric

**Use morphing when all of these hold:**

- The flow is *submit → redirect back to the same path*, or *broadcast → everyone re-renders the same page*.
- The page has meaningful client state worth keeping: scroll position, focus, an open panel, in-flight CSS transitions. **This is the entire benefit.** jorgemanrubia is explicit ("A happier happy path in Turbo with morphing"): the win *"came from keeping client-side state: scroll, focus, selected text, CSS transition states"* — **not** from speed. 37signals separately prototyped server-side diffing to make it faster and found the gains "marginal… not noticeable" and abandoned it ("Exploring server-side diffing in Turbo").
- The number of distinct things that can change is large or unbounded, so enumerating stream targets would be a combinatorial mess.
- Your rendering is idempotent: rendering the page twice produces identical HTML given identical state (no `SecureRandom` in ids, no `Time.now` in classes).

**Use targeted Turbo Streams when:**

- You know precisely which DOM nodes changed and the set is small and stable.
- The update must be *surgical* — you must not touch neighbouring state (a chat message appended to a list while someone is typing in the composer above it).
- The response must be cheap: a stream renders one partial; a refresh re-renders the entire page for every subscriber. **On a page with 500 subscribers, `broadcasts_refreshes` is 500 full page renders.**
- You need append/prepend semantics that morphing cannot express without re-rendering the whole collection.

**Use Turbo Frames when:**

- The region has, or should have, its own URL — pagination, tabs, a details pane, a lazily-loaded panel.
- You want navigation *within* the region without touching the rest of the page, and you want browser history to advance. Morphing cannot do this at all (`action` must be `replace`); frames can (`data-turbo-action="advance"`). keithschacht's answer to the image-browser use case (turbo#1177) is exactly this, and it's right.
- You want lazy loading (`loading="lazy"`) or a cheap independent refresh (`frame.reload()`).

**Combine:** frames marked `refresh="morph"` are the intended bridge — see [Interactions](#morph--frames).

### The broadcast case: `broadcasts_refreshes` vs `broadcast_replace_to`

| | `broadcasts_refreshes` | `broadcast_replace_to` |
|---|---|---|
| What crosses the wire | `<turbo-stream action="refresh">` — a few bytes, **no rendered HTML** | the rendered partial |
| Who renders | every subscribed **client**, each fetching the page as *themselves* | the **server**, once, for everyone |
| Per-viewer authorisation | ✅ correct by construction — each client's fetch runs through your normal controller/policy code | ⚠️ dangerous — one render is broadcast to everyone; you must render the least-privileged view or shard streams per audience |
| Server cost | N page renders (one HTTP request per viewer) | 1 partial render |
| Coupling | zero — model doesn't know what views exist | model must know a partial and a target id |
| Debounced | ✅ 0.5 s server-side + 150 ms client-side | ❌ not debounced |
| Preserves client state | ✅ (that's the point) | only outside the replaced fragment |
| **Ordering / staleness** | ✅ **impossible to render stale state** — the last refresh just fetches current truth | ⚠️ **out-of-order delivery is possible.** With multiple workers, a client can receive v2 then v1 and be left stale |
| Self-echo to the originator | suppressed via `X-Turbo-Request-Id` | **not suppressed** — the originator gets their own payload back |
| Latency to other viewers | 0.5 s server debounce + 150 ms client debounce + a full round trip | debounce only, and bypassable |
| Fails when | many concurrent viewers; expensive pages; N+1 render storms | per-user content; you don't know every target id; ordering matters |

**The ordering race is the hidden cost of switching to `broadcast_replace_to`**, and Radan Skorić's ["When broadcasting a Turbo refresh is not enough"](https://radan.dev/articles/turbo-versioned-updates) is the only good treatment of it. His fix is a versioned custom stream action:

```js
Turbo.StreamActions.versioned_replace = function () {
  let payloadVersion = parseInt(this.templateContent.children[0].dataset.version)
  let pageVersion    = parseInt(this.targetElements[0].dataset.version)
  if (payloadVersion > pageVersion) {
    Turbo.StreamActions.replace.bind(this)()
  }
}
```

Version source: a domain counter, or `ActiveRecord::Locking::Optimistic`'s `lock_version` propagated upward with `belongs_to …, touch: true`. His note — *"Even if you don't actually need optimistic locking, it's perfectly OK to introduce it just to get a robust version number"* — is good advice. He also documents how to bypass Turbo's built-in debounce when you need minimum latency (live dashboards, collaborative editors, multiplayer):

```ruby
action = turbo_stream.replace game, partial: "games/game", locals: { game: game }
Turbo::Streams::BroadcastStreamJob.perform_later game, content: action
```

**My recommendation:** default to `broadcasts_refreshes`. It is the "no view coupling, correct authorisation, one line in the model" option, and it is what the happy-path argument is *for*. Switch to `broadcast_replace_to` (or `broadcast_action_to … attributes: { method: :morph }` for a morphing replace) when you measure a problem: many concurrent viewers on an expensive page, or a high-frequency stream where N-renders-per-event is real load. The failure mode of `broadcasts_refreshes` is a load problem you can see in APM; the failure mode of `broadcast_replace_to` is a data-leak you find in a pen test.

### What practitioners actually recommend

Worth having side by side, because they do not agree.

**Rails Designer**'s ladder — note that **morphing is absent from it entirely**:
> "default to **Turbo Drive**, with any of its extra options; changes **within the same element**: Turbo Frames; changes needed **elsewhere on the page** (one or many elements): Turbo Streams; changes needed **outside of the current request cycle**: Turbo Stream Broadcasts"

**Jorge Manrubia (37signals)** — the pro-morphing case in one sentence:
> "Of course, we could have achieved the same with stream actions, but **that's indeed the whole point here: not having to write those.**"

**Jon Sully** — the trade stated honestly:
> "the Page Refresh paradigm is **less *efficient*** than going with a fully-manual Turbo Streams setup. **But it's *significantly* less complex.**" — and on when streams still win: *"if you're an instant-messaging / chat application where keeping the users 'in sync' as fast as possible, it might matter."*

**Radan Skorić** — on frames, and the point everyone misses:
> "Turbo frames scope the updates to a part of the page. However, there is a bit of a problem if we're talking about morphing: **it doesn't support it.** […] Still, frames might provide smooth enough updates without morphing. **Focus on the user experience rather than specific technical approaches.**" And: *"**Full page updates are simpler to maintain, if they work.**"*

**chloerei** — the sharpest per-tool triage:
> "`data-turbo-permanent` is good for elements that don't need morph […] `turbo:morph-element->controller#reconnect` is good if you want the element to update and reconnect. […] **Morph is still a bleeding edge feature, so if it's a barrier to learning Rails, you might want to turn it off first. It's an opt-in feature.**"

**Sean Doyle** — the architectural entry price:
> "**Integrating with morphing alters the mental model.** […] JavaScript code (whether Stimulus controller or otherwise) should be implemented in a way that's resilient to both asynchronous connection and disconnection *as well as* asynchronous modification of attributes."

Radan's **migration** advice is the one to follow if you're retrofitting: *"This approach particularly helps when adding morphing to legacy applications. **Start with smaller page sections and expand the morphing scope as the codebase adapts**"* — i.e. begin with `turbo_stream.replace(…, method: :morph)`, not with the page-level meta tag.

### My opinion, stated plainly

1. **Morphing is not a performance feature and shouldn't be sold as one.** It is a *state-preservation* feature. If your page has no client state worth keeping, morphing buys you nothing and costs you the entire inventory in the previous section. Do not enable it "because Turbo 8".
2. **Morphing's real sweet spot is narrow and valuable:** long-lived, information-dense pages that update frequently — dashboards, kanban boards, calendars, inboxes, live tables. That is exactly what 37signals built it for (HEY Calendar, Basecamp card table). It is a poor fit for CRUD forms, marketing pages and wizards.
3. **Enable it per-page, not per-app.** `turbo_refreshes_with` is a `provide :head` — you can set it in a specific view or a controller-scoped layout. Global opt-in is how teams end up debugging Trix. (Caveat: turbo-rails#549 reports that overriding it per-page via `content_for` doesn't reliably work; seanpdoyle could not reproduce. Test it in your app. **[partially unverified]**)
4. **The moment you find yourself writing your third `turbo:before-morph-*` listener, you have chosen the wrong tool for that page.** Streams and frames exist. Use them.
5. **`turbo_stream.replace(target, method: :morph)` is the most under-used tool in Hotwire** and should probably be crosswire's *default* recommendation for "this region needs to update without losing state". It is strictly cheaper than a page refresh, strictly more state-preserving than a plain replace, has none of the trigger-rule traps, and is one keyword argument. Most of the pain in this document comes from people reaching for whole-page morphing when they wanted a morphing stream.
6. **Do not chase the "morph between different URLs" dream.** It has been requested since 2023 (#1085, #1177, #1339), was rejected once (#1145), and the maintainers have coherent reasons. Use a frame.

---

## Pre-flight checklist before enabling morphing

Work through this *before* adding the meta tag. Each item is a real failure from the inventory above.

### A. HTML hygiene

- [ ] **No duplicate `id`s anywhere on the page.** Run in console on every important page:
      ```js
      const ids = [...document.querySelectorAll("[id]")].map(e => e.id)
      console.log(ids.filter((v, i) => ids.indexOf(v) !== i))
      ```
      Add a system-test assertion for the pages that matter. Duplicate ids don't degrade gracefully — they remove that id from matching entirely.
- [ ] **Every repeated element has a stable `id`** — `dom_id(record)`, not an index. This is what makes reorders cheap and correct, and it is the main performance lever (turns a linear sibling scan into a hash lookup).
- [ ] **Ids are stable across renders.** No `SecureRandom`, no object_id, no timestamps in ids or in `data-` attributes that idiomorph will diff.
- [ ] **No element changes its tag name between renders.** `<div id="x">` → `<section id="x">` destroys persistence.
- [ ] **Rendering is idempotent.** Render the page twice with unchanged data and diff the HTML; it must be byte-identical. Anything that isn't (relative timestamps, CSRF-adjacent nonces, randomised class suffixes) will thrash on every morph.

### B. Inventory client-owned state

Walk the page and list everything whose current state is *not* in the server's HTML. For each, decide: render it server-side, or protect it.

- [ ] Focused element and caret position (partially handled by `restoreFocus`; not for `<select>`, contenteditable, or `type=number|date`)
- [ ] Text selection
- [ ] `<details open>` / disclosure widgets
- [ ] `<dialog>` open state — **and add the `close()` listener regardless**
- [ ] Popover API state
- [ ] Scroll position of **nested** scroll containers (the page-level one is handled; inner ones only survive if the element survives)
- [ ] `<video>` / `<audio>` playback position and play state
- [ ] `<iframe>` contents (third-party embeds, YouTube, Stripe Elements, maps)
- [ ] In-flight CSS transitions and animations
- [ ] Uncontrolled form values, checkbox/radio state, file inputs (`type=file` is skipped by idiomorph — verify your behaviour anyway), autofill
- [ ] Anything a browser extension injected (see idiomorph#60 — LastPass)

### C. Audit every JavaScript integration

For each Stimulus controller and each third-party library:

- [ ] **Does it mutate the DOM outside its own element?** (portals, tooltips appended to `<body>`, TomSelect's sibling `<div>`) → these are deleted on every morph.
- [ ] **Does it set attributes at runtime?** (`contenteditable`, `aria-expanded`, `class`, `hydrated`) → these are removed on every morph unless the server renders them.
- [ ] **Does `connect()` do setup that must re-run when content changes?** → it won't. Move to `[name]ValueChanged`, `[name]TargetConnected`, or W6.
- [ ] **Is `disconnect()` a complete teardown, and is it idempotent?** Any W5/W6 reinit pattern will call it repeatedly.
- [ ] **Are listeners added in `connect()` removed in `disconnect()` with the *same function reference*?** This is the #1 source of exponential listener growth under morph.
- [ ] **Custom elements: is state set in `constructor()` reflected onto the host?** → it's gone. Add `static observedAttributes` + `attributeChangedCallback`, or move state to shadow DOM.
- [ ] Specifically check: Trix/Action Text, any WYSIWYG, charts, maps, date pickers, enhanced selects, sortable/drag-drop, tooltip libraries, Alpine, Shoelace/Web Awesome, analytics and session-replay snippets.

### D. Verify the trigger will actually fire

- [ ] For each flow you expect to morph, confirm **same pathname + `replace` action**. Instrument it:
      ```js
      addEventListener("turbo:render", e => console.log("renderMethod:", e.detail.renderMethod))
      ```
      Expect `"morph"`. If you see `"replace"`, you have a Rule-1 mismatch.
- [ ] Check for frames with `data-turbo-action="advance"` upstream of the flow (turbo#1214).
- [ ] Confirm the **current** page carries `turbo-refresh-method`, since that's the snapshot that decides.
- [ ] Check the query-string trap in the *other* direction: are there filter/sort/pagination links on the same path with `data-turbo-action="replace"` that will now morph across semantically different content?

### E. Broadcasts

- [ ] Model the fan-out: viewers × refresh rate = full page renders per second. Load-test it.
- [ ] Confirm the actor's own tab is deduped (request-id) and that the flow still looks right for them — usually you want `redirect_back_or_to` for the actor, broadcast for everyone else.
- [ ] Check `touch: true` chains — one update can cascade into several broadcasts on different streams, each debounced independently.
- [ ] Decide `Turbo.session.pageRefreshDebouncePeriod` (150 ms default) and whether it's enough.
- [ ] Verify per-viewer authorisation: with `broadcasts_refreshes` each viewer re-renders as themselves, so this is correct by default — do not "optimise" it into `broadcast_replace_to` without re-checking.
- [ ] **Audit every write path for callback-skipping methods.** `increment!`, `decrement!`, `update_column(s)`, `update_all`, `insert_all`, `upsert` all bypass `after_*_commit`, so they silently never broadcast. Grep for them on any model carrying `broadcasts_refreshes`.
- [ ] **Ask "whose state does this reset?" for every broadcast-triggered morph.** A `<details>` closed by *your* edit reopens for *everyone*. Broadcast morphing amplifies every client-state bug across the whole audience — the failure mode is qualitatively worse than a self-initiated refresh.
- [ ] Confirm forms actually clear after a successful morphed POST (`turbo:submit-end->form#reset`), especially any field you made `data-turbo-permanent` to preserve focus.
- [ ] Tests must wait for the async broadcast: `perform_enqueued_jobs { record.update!(...) }`, or the inline queue adapter. A system test that asserts immediately after `update!` will pass locally and flake in CI.

### F. Tests

- [ ] Integration test asserting the meta tags are actually emitted:
      ```ruby
      assert_select "meta[name=turbo-refresh-method][content=morph]", count: 1
      assert_select "meta[name=turbo-refresh-scroll][content=preserve]", count: 1
      ```
- [ ] System tests for the *consequence*, not the mechanism: focus an input, type, trigger the refresh, assert `document.activeElement` and the value are unchanged. Assert an open `<details>` stays open. Assert the chart is still on screen.
- [ ] A test that submits an invalid form (the 422 morph path) and asserts every JS widget on the form still works. **This is the highest-value single test.**
- [ ] A listener-leak check across several refreshes: `getEventListeners(window)` in a devtools-driven test, or count instances of your library's objects.
- [ ] Cross-browser: run at least the focus/media/iframe assertions in **both** a Chromium and a non-Chromium browser, because `moveBefore()` changes behaviour.

### G. Rollout

- [ ] Enable on **one** page first, ideally the dashboard-like page that motivated it.
- [ ] Install [Hotwire DevTools](https://github.com/leonvogt/hotwire-dev-tools) — it warns on `TURBO_PERMANENT_ELEMENT_MISSING_ID` and `TURBO_PERMANENT_ELEMENT_DUPLICATE_ID`.
- [ ] Add the `<dialog>` global listener before you ship.
- [ ] Have a documented kill switch: `turbo_refreshes_with method: :replace` restores old behaviour immediately.

---

## Interactions

### Morph + `data-turbo-permanent`

Two completely different mechanisms wear the same attribute name.

| | Drive **replace** | **Morph** |
|---|---|---|
| Mechanism | `Bardo`: swap the new page's copy for a placeholder `<meta>`, replace `<body>`, transplant the live node back | Idiomorph `beforeNodeMorphed` / `beforeNodeRemoved` return `false` |
| Requires `id` | **yes** — Bardo matches by id | **no** — only the attribute is checked |
| Node is detached/reattached | **yes** — so iframes reload, media restarts, `connectedCallback` re-runs, `<turbo-cable-stream-source>` resubscribes | **no** — the node is genuinely never touched |
| If missing from the new page | element is **lost** | element is **kept** |
| Turbo Streams | honoured via `Bardo` in `StreamMessageRenderer`, but only for permanent elements that carry an `id` **and** appear inside the stream's template | n/a |

brunoprietog's much-quoted "permanent elements in Turbo are not truly permanent, as they are detached and attached to the dom anyway" is about the **Bardo/replace** path. Under morph they really are untouched. Since apps use both paths, **always give permanent elements an id** — but understand that under morph the id is doing a different job (preventing duplicate insertion via `beforeNodeAdded`).

One more asymmetry from the source: because Turbo's `beforeNodeAdded` returns `false` when the incoming node has a permanent id already present in the document, **the server's version of a permanent element is discarded, not merged.** Whatever the server renders inside a permanent element is thrown away on every morph.

### Morph + frames

`<turbo-frame refresh="morph">` is the designed bridge between "the page morphs" and "this region has content the page response doesn't contain" (pagination, infinite scroll, lazily loaded panels).

During a page morph, `MorphingPageRenderer`'s `beforeNodeMorphed` intercepts:

```js
beforeNodeMorphed: (node, newNode) => {
  if (shouldRefreshFrameWithMorphing(node, newNode) && !closestFrameReloadableWithMorphing(node)) {
    node.reload()
    return false          // idiomorph does NOT touch this frame's subtree
  }
  return true
}
```

`shouldRefreshFrameWithMorphing` requires: it is a `FrameElement`; `src` present **and** `refresh === "morph"`; the incoming frame (if any) is a `TURBO-FRAME` with the same `id` and either no `src` or the same `src`; and it is **not** inside `[data-turbo-permanent]`. If it qualifies, Turbo refetches from `src` and renders with `MorphingFrameRenderer` (which morphs the frame's *children*, `morphStyle: "innerHTML"`, after dispatching `turbo:before-frame-morph`).

Verified behaviours (from Turbo's own test suite, `page_refresh_tests.js`):

* `"frames marked with refresh='morph' are excluded from full page morphing"` — client-side attributes on the frame survive the page morph.
* `"frames with refresh='morph' are preserved when missing from new content"` — a frame absent from the page response is kept, not deleted (PR #1452, Oct 2025).
* `"navigated frames without refresh attribute are reset after morphing"` — a plain frame you navigated is **reset to the server's version** and *not* reloaded. This is a real trap: navigate a frame, then trigger a page refresh, and the frame snaps back.
* `"don't refresh frames contained in [data-turbo-permanent] elements"`.
* Nested `refresh="morph"` frames reload recursively (PR #1311).

**Correction to `07-problem-mining.md`:** the note says `frame.reload()` ignores `refresh="morph"` (citing turbo#1161). That is **no longer true** as of 8.0.23. `FrameElement#reload()` → `FrameController#sourceURLReloaded()` sets `#shouldMorphFrame = src && refresh === "morph"`, and `#shouldMorphFrame` selects `MorphingFrameRenderer`. Fixed by PR #1192 ("Lift the frame morphing logic up to `FrameController.reload`", Feb 2024).

**You cannot morph a frame you navigate.** This is the single biggest structural gap, and Carwow hit it hard enough to replace Turbo's frame renderer with morphdom (see [Field evidence](#field-evidence-what-happened-to-teams-who-turned-it-on)). Radan Skorić states the correction plainly: *"You may now be thinking: 'Wait a minute! there's a `refresh="morph"` attribute!' … But notice the wording: 'Frame that will get reloaded with morphing **during page refreshes**'."* If you need morph semantics for a region you navigate, use `turbo_stream.replace(target, method: :morph)` instead — or, as Carwow did, override `event.detail.render` on `turbo:before-frame-render`.

**Frames never morph on ordinary navigation.** A frame navigated by a link always does a full `FrameRenderer` replace. PR #1316 ("Enable frame morphing for `data-turbo-frame` links and forms if the URL doesn't change") has been open since Sep 2024. Issue #1357 asks the same. Also unsolved: scroll preservation inside a morphing frame (#1272).

### Morph + Turbo Streams in the same response

* **There is no `<turbo-stream action="morph">`.** It briefly existed (PR #1185) and was restructured away (PR #1240, and issue #1229 "Morph action for streams not part of 8.0.4 but in docs"). What exists today is a **`method="morph"` modifier on `replace` and `update`**:
  ```js
  // src/core/streams/stream_actions.js
  replace() { … method === "morph" ? morphElements(targetElement, this.templateContent)
                                   : targetElement.replaceWith(this.templateContent) }
  update()  { … method === "morph" ? morphChildren(targetElement, this.templateContent)
                                   : (targetElement.innerHTML = "", targetElement.append(this.templateContent)) }
  ```
  From Rails: `turbo_stream.replace(target, method: :morph, partial: …)` / `turbo_stream.update(target, method: :morph, …)` — the `method:` keyword is threaded through `TagBuilder#action`. These use the same `morphElements`/`morphChildren` functions as page morphs, so **every `turbo:*morph*` event fires for them too**, including `data-turbo-permanent` honouring. This is the surgical middle ground people usually want and rarely know exists: *targeted* update, *morph* semantics.
* Ordering hazard: a `replace` stream followed by a `refresh` morph can desynchronise permanent-element pairings — turbo#1262, **open**, and the reported consequence is a form submitting against the wrong record. Treat "targeted stream + refresh on the same subtree" as unsupported.
* `<turbo-stream action="refresh">` is gated (Rule 4). The single most common confusion is "my `turbo_stream.refresh` does nothing" — it's request-id dedup; the actor is meant to be served by their own redirect. Escape hatch `turbo_stream.refresh(request_id: nil)`, but the canonical answer is `redirect_back_or_to`.
* A refresh stream is dropped entirely while another Visit is in flight (`!this.navigator.currentVisit`). Under load this silently loses updates.

### Morph + Hotwire Native

**Morphing is supported and is the recommended fix for native flicker.** A developer porting a PWA reported *"bottom navbar which is flickering (actually whole page is flickering when using `data-action="replace"`)"* and offered to contribute morph support; maintainer **jayohms** closed it as already working — *"This is already supported… Include this in your `<head>`: `<meta name="turbo-refresh-method" content="morph">`"* — pointing at the official demo app's layout ([hotwire-native-android#60](https://github.com/hotwired/hotwire-native-android/issues/60)). There are **no** morph bug reports in `hotwired/hotwire-native-ios`. So the baseline story is positive.

That said, nothing in the morph path is native-aware, and there are real divergences.

1. **The native wrapper's screenshot overlay flashes even when the web layer morphs perfectly.** hotwire-native-ios#53: an app with `data-turbo-action="replace"` tab links and `turbo-refresh-method: morph` still flashed on every tab switch. karlentwistle traced it to `VisitableView.showScreenshot()` — stubbing it out removed the flash. The morph was fine; the native chrome was drawing a stale bitmap over it.
2. **Native and web disagree about what "the same page" means.** joemasilotti closed #53 with: *"Visiting a URL with different query items is a **different URL** and should behave that way. Different query items could mean different native screens depending on the path configuration!"* But Turbo web's `isPageRefresh` compares **pathname only** and treats different query strings as the same page. So `/forums?sort=trending` → `/forums?sort=unanswered` is *one page refreshing* to Turbo and *two screens* to Hotwire Native. The recommended workaround on both sides is to wrap the region in a Turbo Frame and move `data-turbo-action="replace"` onto the frame — which then brings its own tax (every link inside needs `data-turbo-frame="_top"`; scroll preservation stops behaving).
3. hotwire-native-ios#147 reported `renderMethod === "replace"` on native back navigation (`recede_or_redirect_to`) despite the morph meta tags. Closed for lack of a reproduction, not fixed. **[unverified — worth re-testing]**
4. **Modals are a separate WKWebView.** A sibling crosswire note established that Hotwire Native modals run in their own web view / JS realm. Morphing is per-document, so a page refresh in the main web view cannot morph anything inside a modal web view, and a `<turbo-stream action="refresh">` delivered to one realm does not reach the other. Each realm has its own `recentRequests` set and its own `document.baseURI`, so the dedup and `isCurrentUrl` guards evaluate independently. **[inferred from the mechanism + the sibling note; not directly verified against native source]**

### Morph + View Transitions

Independent features that can be combined. `Visit` owns a `ViewTransitioner`; `PageView#shouldTransitionTo` requires `<meta name="view-transition" content="same-origin">` on **both** the current and new snapshots; if so the whole `render` callback (including the morph) runs inside `document.startViewTransition(render)`.

Consequences worth knowing:

* Morph + view transitions is *the* combination that makes reorders look good — coorasse's 2D game grid in turbo#1085 is exactly this, and it's why they wanted morph-on-advance.
* View transitions snapshot the page before and after the callback. Because a morph mutates in place, elements that keep the same `view-transition-name` animate; elements idiomorph deletes and recreates do not. **Stable ids are a prerequisite for good transitions under morph**, same as everything else.
* `data-turbo-permanent` is reported broken under view transitions (turbo#1048) — but that report is about the Bardo/replace path, so it may not apply to morph. **[unverified for the morph path]**
* Turbo's `ViewTransitioner` guards against re-entrancy (`#viewTransitionStarted`); rapid broadcast refreshes plus transitions is a combination worth load-testing.

### Morph + scroll restoration

```js
// page_view.js:62
shouldPreserveScrollPosition(visit) {
  return this.isPageRefresh(visit) && (visit?.refresh?.scroll || this.snapshot.refreshScroll) === "preserve"
}
// visit.js:334
performScroll() {
  if (!this.scrolled && !this.view.forceReloaded && !this.view.shouldPreserveScrollPosition(this)) { … }
}
```

This is subtractive, not additive: `preserve` does not save and restore a scroll position — it simply **suppresses Turbo's scroll reset**. The scroll survives because the `<body>` was never replaced. Implications:

* It applies **only** to page refreshes (Rule 1). Ordinary `advance` navigations always reset scroll — Turbo's own test asserts *"it does not preserve the scroll position on regular 'advance' navigations, despite of using a 'preserve' option"*. The general "preserve scroll across navigation" request is turbo#37, open since December 2020.
* `<turbo-stream action="refresh" scroll="reset">` overrides the meta tag per-broadcast; so does `scroll="preserve"` against a `reset` default.
* **Nested scroll containers are not handled.** A scrollable `<div>` keeps its `scrollTop` only if that exact element survives the morph — which needs a stable `id`. Frames get nothing (turbo#1272).
* `morph` + `scroll: reset` is a legitimate combination (jon-sully in turbo-rails#536 attributes it to the HEY Calendar team): preserve DOM state, but move the viewport because the content the user needs is now elsewhere.
* Error responses ignore the scroll setting — [turbo#1449](https://github.com/hotwired/turbo/issues/1449): 422s go through `renderError()`, which never reaches the scroll logic in `renderPageSnapshot()`. PR #1462, open.
* **`preserve` is all-or-nothing per page.** There is no `data-turbo-refresh-scroll` per link. The canonical case — a filter form that should preserve scroll next to pagination links that should reset it — is [turbo#1350](https://github.com/hotwired/turbo/issues/1350) (open) and [turbo#1089](https://github.com/hotwired/turbo/issues/1089). jorgemanrubia: *"This is not supported right now."* brunoprietog: *"You can change the value of the meta tag dynamically when you want the scroll to be preserved… We don't plan to increase the scope of the API yet, but I understand the use case."* The working community fix is exactly that — mutate the meta tag from a controller:
  ```js
  this.element.addEventListener('turbo:before-fetch-request', (event) => {
    if (this.resetScrollTargets.includes(event.target)) resetScroll = true
  })
  document.addEventListener('turbo:morph', () => {
    if (resetScroll) {
      document.querySelector('meta[name="turbo-refresh-scroll"]').content = 'reset'
      resetScroll = false
    }
  })
  ```
* **The most common support question in the whole corpus is "`scroll: :preserve` does nothing"** ([turbo-rails#575](https://github.com/hotwired/turbo-rails/issues/575), 14 comments, plus forum duplicates). seanpdoyle's diagnosis is the thing to memorise: *"For scroll preservation to behave like you're describing, the navigation needs to: **1. have a Turbo Action of `replace`. 2. navigate to the current URL.**"* It is Rule 1 wearing a different hat. Add `data: { turbo_action: "replace" }` to the link — and note that for a *form*, what matters is where the response **redirects to**, not the attribute on the form.

---

## Design brief: what a `preserve` primitive would need to do

This is a spec for the thing crosswire could ship. It is informed by every failure mode above, by the two independent reinventions (Evil Martians' `data-turbo-morph-permanent-attrs`, `stimulus-durable-values`), by the request Stimulus closed (#801), and by htmx's `hx-preserve`.

### The problem statement, precisely

Turbo gives you two levers — `turbo:before-morph-element` (all-or-nothing for a subtree) and `turbo:before-morph-attribute` (one attribute at a time) — and a hammer, `data-turbo-permanent`. What is missing is the middle: **"the server owns my content; I own these specific attributes and this specific state."** Every app rediscovers this and reimplements it badly.

### Prior art #1: Evil Martians' `data-turbo-morph-permanent-attrs`

Shipped in a production fintech wizard ([Evil Martians, 2025-06-24](https://evilmartians.com/chronicles/hotwire-rails-summit-interactive-multi-step-forms-peak-ux)). This is the closest thing to the primitive that exists:

```js
// Protect specific attributes (not whole elements) from being overwritten during morph
addEventListener("turbo:before-morph-attribute", (event) => {
  if (!event.target.dataset.turboMorphPermanentAttrs) return;

  const { attributeName } = event.detail;

  const regex = event.target._permanentAttrsRegex ||=
    new RegExp(`\\b(${event.target.dataset.turboMorphPermanentAttrs.split(/\s+/).join('|')})\\b`);
  if (regex.test(attributeName)) {
    event.preventDefault();
  }
});
```
```html
<div data-controller="wizard-step" data-turbo-morph-permanent-attrs="aria-expanded class">
```

What it gets right: one global listener (no per-controller wiring), declarative in the markup, attribute-level rather than element-level, and it caches the compiled regex on the element. What it gets wrong for our purposes: it is markup-driven rather than controller-driven (the view author has to know), it is unconditional (the server can *never* update those attributes — no divergence check), and their motivating problem was specifically *"third-party Stimulus controllers that mutate their own attributes"* — i.e. controllers whose source you can't edit. That last case is real and a controller-side API cannot solve it, so **the primitive should support both surfaces**: a `static preservedAttributes` for controllers you own, and the `data-` attribute escape hatch for ones you don't.

Note also what else that project used: `turbo_stream.replace(:reporting_custom_wizard, method: "morph")` — targeted morphing streams, not page refreshes. They reached for the fourth option in the rubric.

### Prior art #2: the three families of fix

Radan Skorić's taxonomy ("How to avoid problems with Turbo morphing") is the right frame for scoping the primitive, because it makes clear that **two of the three families are not the primitive's job**:

1. **Tell Turbo to leave it alone** — `data-turbo-permanent`, `preventDefault()` in morph callbacks. ← *this is where a `preserve` primitive lives*
2. **Limit the update scope** — `replace`/`update` streams with `method="morph"`, or Frames.
3. **Make server state match browser state** — persist the UI state (a user-preferences model, the session) or encode it in the URL, so you morph *toward* the desired state and the problem evaporates.

Family 3 is the one people miss, and Radan's tell for when it's right is worth quoting in the crosswire docs: *"The best usage of this approach is when it also has a UX benefit beyond fixing morphing"* — the state now survives a reload, or the URL becomes shareable with the UI state intact. A `preserve` primitive should therefore ship with documentation that tries to talk you out of using it first.

### Design principles

1. **Opt-in per controller, never global.** This is what reconciles seanpdoyle's "over-commit to ignoring server values" with jorgemanrubia's "automatic assumes too much": the *default* is Turbo's, the *opt-in* is total.
2. **Declarative in the controller class, not in the markup.** `static preservedValues = [...]` reads like `static values` and requires nothing of the view author. A `data-action` the consumer must remember is the reason W2 is unpleasant.
3. **Preserve is about *attributes and state*, not about blocking content updates.** If you want to block the subtree, `data-turbo-permanent` already exists and is fine.
4. **Idempotent, leak-free, and safe to call repeatedly.** Every hand-rolled version has leaked listeners.
5. **Zero cost when morphing is off.** The same controller must work on a `replace`-rendered page.

### Proposed surface

```js
import { Controller } from "@hotwired/stimulus"
import { usePreserve } from "crosswire/morph"

export default class extends Controller {
  static values  = { open: Boolean, endpoint: String }
  static targets = ["panel"]

  // (a) values this controller owns; the server must not stomp them
  static preservedValues = ["open"]

  // (b) arbitrary attributes this controller writes at runtime
  static preservedAttributes = ["aria-expanded", "contenteditable"]

  // (c) opt into a re-initialisation callback
  static reconnectOnMorph = true

  connect() { usePreserve(this); this.mount() }
  disconnect() { this.unmount() }

  // called only when this controller's own subtree was morphed
  morphed({ newElement }) { this.unmount(); this.mount() }
}
```

### Required behaviours

**B1 — Attribute preservation, correctly scoped.**
Listen for `turbo:before-morph-attribute` on `this.element`. Because the event bubbles, the handler must check `event.target === this.element` for root-level preservation, and support an explicit descendant form for targets. Cancel when `event.detail.attributeName` is in the preserved set. For `preservedValues: ["open"]` the derived attribute name is `data-${identifier}-open-value` — and it must be derived from the *live* `identifier`, not a compile-time constant, because a controller can be registered under a different name.

**B2 — Only preserve what the controller actually changed.**
This is the crucial refinement over W1/W2 and over `stimulus-durable-values`. Blanket preservation permanently disables server-driven updates, which is a slow-burn bug. Instead: record the value at `connect()` time; on `turbo:before-morph-attribute`, cancel **only if the current DOM value differs from the recorded one** (i.e. the controller has diverged from the server). If the controller never touched it, let the server win. Update the recorded value whenever the controller sets it and whenever a morph is allowed through. This gives the semantics people actually want: *last writer wins, and the client is the last writer only when it actually wrote.*

**B3 — A `morphed()` lifecycle callback, scoped to the element.**
Listen for `turbo:morph-element` on `this.element`. Because it bubbles once per morphed descendant, **coalesce**: collect within a microtask/`requestAnimationFrame` and invoke `morphed()` at most once per morph pass. This is the fix for the "188 Trix editors hung the browser" failure. Provide `event.detail.newElement` through. This is exactly the `morphed()` method weaverryan asked for in turbo#1097 and the "`reconnect when morphed` boolean option" jorgemanrubia said Stimulus should perhaps expose.

**B4 — A real removal hook.**
Turbo dispatches `turbo:before-morph-element` with `detail.newElement === undefined` for elements about to be removed, and dispatches **nothing at all** for pantried (relocated) elements. A primitive must (a) surface removal as a distinct, documented thing rather than a quirk of an undefined field, and (b) document loudly that relocation is silent. If PR #1482 lands, switch to the real events and keep the API stable.

**B5 — Correct teardown.**
All listeners registered with a stable bound reference and removed in `disconnect()`. `usePreserve(this)` must wrap `disconnect` (the standard Stimulus "use" mixin pattern) so the consumer cannot forget. It must be safe if `connect()` runs twice without an intervening `disconnect()` (Stimulus explicitly reuses controller instances on reconnection).

**B6 — Full-subtree opt-out, declaratively.**
`static preserveElement = true` → cancel `turbo:before-morph-element` when `event.target === this.element`. Equivalent to `data-turbo-permanent` but morph-scoped, so it does *not* leak into ordinary Drive navigations. This is precisely what stimulus#801 asked for and got closed.

**B7 — Nothing may mutate the DOM during a morph. This is non-negotiable, and the failure is worse than you'd guess.**

W8's `replaceWith()` trick works today but is explicitly unsupported (idiomorph#140, botandrose: *"mutating the DOM mid-morph is not supported"*). [OpenProject PR #24603](https://github.com/opf/openproject/pull/24603) is the definitive public diagnosis of what actually goes wrong when a `beforeNodeMorphed` callback calls `oldNode.replaceWith(newNode)`:

> "That mutates both trees idiomorph is walking, and breaks the walk in two independent ways:
> **1. Stale insertion point.** `morphChildren` tracks its position via `insertionPoint = bestMatch.nextSibling` … `bestMatch` is the now-detached `oldNode`, so `nextSibling` is `null`. Every remaining new child then falls through to `createNode(oldParent, newChild, null, ctx)` — i.e. `insertBefore(node, null)`, an append at the end of the parent. The trailing 'remove any remaining old nodes' loop is guarded on the same `insertionPoint`, so stale old siblings are never removed either. **The result is duplication, not just staleness.**
> **2. Skipped new sibling.** `morphChildren` iterates `for (const newChild of newParent.childNodes)`. **`childNodes` is a *live* `NodeList` and the iterator is index-based**, so moving `newNode` out of `newParent` shifts every later entry down one index. The new sibling immediately following the … node is never visited at all."

Both claims check out against the 0.7.4 source I read (`morphChildren`, lines 296–354). Their conclusion is also the design constraint: **"idiomorph has no 'replace instead of morph' signal — returning `false` only skips."**

So if the primitive offers an "atomic replace this subtree" mode it must **queue** the replacement during the walk and apply it after `Idiomorph.morph()` returns (from `turbo:morph`, or a microtask), and it must queue a `cloneNode(true)` so the incoming tree is never mutated either. This is also a reason to prefer building the primitive on Turbo's events rather than on raw idiomorph callbacks: the events fire at the same points, but a `turbo:morph`-scoped flush queue is a natural place to do the deferral.

### Failure modes the primitive must handle

| Failure | Requirement |
|---|---|
| Event bubbling causes N invocations for N descendants | coalesce per morph pass (B3); guard on `event.target` (B1) |
| Listener leaks / exponential growth | stable bound references; mixin-owned teardown (B5) |
| Server can never update a preserved value again | divergence check (B2) |
| `turbo:morph` firing twice | idempotent teardown; prefer element-scoped events over `turbo:morph` |
| Controller identifier ≠ file name | derive attribute names from `this.identifier` at runtime |
| Preserved element removed by the morph | B4; decide explicitly whether preservation implies "don't delete me" |
| Element relocated via the pantry with no events | document; consider a `MutationObserver` fallback **only** if measurably needed |
| Runs on a page where morphing is off | all listeners are no-ops; zero cost |
| Frame morph (`morphStyle: "innerHTML"`) vs page morph | must work identically; `turbo:before-frame-morph` fires first, use it as a coalescing boundary |
| Duplicate ids upstream break matching entirely | out of scope to fix, but the primitive should be able to **warn** in development |

### What it must *not* do

* It must not try to make `connect()` re-fire. jorgemanrubia rejected that for good reasons ("that assumes too much"), and it would break every controller that correctly relies on surviving. Give people `morphed()` instead.
* It must not patch Stimulus internals the way `stimulus-durable-values` does (`@hotwired/stimulus/dist/core/*`). Build on public API: `this.identifier`, `this.element`, `[name]ValueChanged`, and DOM events.
* It must not become a general "morph config" DSL. Four statics and one callback. If a page needs more than that, it needs streams or frames.

### Sequencing note

If turbo PR #1482 (add/remove morph events) lands, B4 gets much cleaner. Design the API so that the *implementation* can switch to the new events without a breaking change — i.e. expose `morphed()` / `removedByMorph()` semantics, not raw event names.

---

## Alternatives and adjacent work

### `marcoroth/Morphkit` — **does not exist**

Verified: `gh api repos/marcoroth/Morphkit` → **404**, as do `morphkit` and `morph_kit` under that owner. A global GitHub search for `morphkit` returns only unrelated projects (a ball-python genetics calculator, a TypeScript→SwiftUI converter, a Greek morphology toolkit, an audio plugin). **The sibling agent's flag was right to be suspicious, and the answer is stronger than "empty": there is no such repository.**

What *does* exist under that owner is **[`marcoroth/turbo-morph`](https://github.com/marcoroth/turbo-morph)** — 103 stars, "Morph action for Turbo Streams", **last pushed 2023-02-25**. That predates Turbo 8 by a year; it added a `morph` stream action before Turbo had one. It is superseded by Turbo's built-in `<turbo-stream action="morph">` (PRs #1185/#1240) and should be treated as archived. If a crosswire note cites "Morphkit", it should cite `turbo-morph` and mark it obsolete.

### morphdom vs idiomorph

| | **morphdom** (`patrick-steele-idem`) | **idiomorph** (`bigskysoftware`) |
|---|---|---|
| Matching | single-key: `getNodeKey(node)`, defaults to `node.id`. Two nodes are "the same" iff their keys match | **id *sets***: each node carries the set of persistent ids in its subtree; two nodes match if those sets intersect. Children contribute to a parent's identity without a depth-first probe |
| Effect | ids must be dense to get good matching; sparse ids degrade to positional guessing | works well with the sparse ids real HTML actually has — which is the whole thesis in `CONCEPT.md` |
| Reordering | moves keyed nodes | plus a **pantry**: a node whose id the new content still wants is parked in a hidden div and retrieved later, instead of being destroyed |
| Moves | `insertBefore` (disconnects) | `moveBefore()` when available (does **not** disconnect), else `insertBefore` |
| Hooks | `getNodeKey`, `addChild`, `onBeforeNodeAdded`, `onNodeAdded`, `onBeforeElUpdated`, `onElUpdated`, `onBeforeNodeDiscarded`, `onNodeDiscarded`, `onBeforeElChildrenUpdated`, `skipFromChildren`, `childrenOnly` | `beforeNodeAdded`, `afterNodeAdded`, `beforeNodeMorphed`, `afterNodeMorphed`, `beforeNodeRemoved`, `afterNodeRemoved`, `beforeAttributeUpdated`; plus `morphStyle`, `ignoreActive`, `ignoreActiveValue`, `restoreFocus`, and a whole `head` sub-config |
| Notable extra | `onBeforeElUpdated` may **return a replacement element** to continue morphing into — strictly more expressive than idiomorph's boolean | `head` handling (`merge`/`append`/`morph`/`none`, `im-preserve`, `im-re-append`, head-blocking on stylesheet load) |
| Speed | faster | idiomorph's own README: *"approximately 10% slower than morphdom for large DOM morphs"* |
| Rails-land users | CableReady's `morph` operation; StimulusReflex | Turbo 8; htmx's morph extension; Datastar (forked) |

Idiomorph's trade is explicit and, for server-rendered HTML, correct: **accept ~10% slower in exchange for far better matching on sparse ids and fewer node disconnects**, because a disconnect costs you focus, playback and custom-element state — which is the entire point of morphing. Its README states the priority order outright: *"Idiomorph is not designed to be as fast as either morphdom or nanomorph."* `ROADMAP.md` ranks the goals as **correctness → state preservation → performance**, in that order.

37signals' own account (quoted in idiomorph's README) is worth having verbatim, because it contradicts the "we picked the slower one" reading:

> "We are indeed using idiomorph and we'll include it officially as part of Turbo 8. We started with morphdom, but eventually switched to idiomorph as we found it way more suitable. It just worked great with all the tests we threw at it, **while morphdom was incredibly picky about 'ids' to match nodes. Also, we noticed it's at least as fast.**"
> — Jorge Manrubia, 37signals

**Idiomorph's roadmap (`ROADMAP.md`, as of 0.7.4)** — relevant to anything crosswire builds on top:

* **0.8.0**: warn when duplicate ids are detected in new content (would surface failure #15 automatically); plugin system (idiomorph#109); "restore or preserve scroll state" (#26); **"natively preserve focus, selection, scroll state by morphing *around* the currently focused element"** (PR #85); improve anonymous-node matching, possibly via Merkle trees or fuzzy synthetic ids; "can we improve the iframe morphing situation without `moveBefore`?"
* **1.0.0**: performance work.
* **2.0.0**, gated on `Element#moveBefore` being widely available: **remove all pre-`moveBefore` workarounds.**

That last line is the clearest statement anywhere that a large fraction of today's morph pain is a browser-API gap with a known expiry date.

Two concrete callbacks morphdom has that Turbo users would benefit from:
* `onBeforeElUpdated` returning a replacement element (a supported "swap this subtree for that one" — exactly what W8 hacks around).
* `skipFromChildren` — "don't index this subtree at all", which is a cheaper `data-turbo-permanent`.

### What htmx has learned that Turbo hasn't

Idiomorph is by htmx's author (Carson Gross, `1cg`), now maintained by `botandrose`. htmx's own experience is instructive:

1. **`hx-preserve` is a *first-class attribute*, not an event listener.** It preserves an element by `id` across a swap, explicitly and declaratively, and — importantly — htmx **documents its limits honestly**: *"Some elements cannot unfortunately be preserved properly, such as `<input type="text">` (focus and caret position are lost), iframes or certain types of videos."* Turbo's `data-turbo-permanent` documentation makes no such disclosure.
2. **`hx-preserve` participates in history restoration.** "When using History Support for actions like the back button, `hx-preserve` elements will also have their state preserved." Turbo's permanent elements do not have an equivalent story under morph + history.
3. **htmx 4 split the swap strategies explicitly** — `outerMorph` vs `outerSync` — acknowledging that "reconcile faithfully" and "match the server exactly" are different jobs with different trade-offs. Turbo has one morph mode and a boolean opt-out.
4. **htmx hit — and is still hitting — the same web-component and focus problems.** htmx#3567 (Lit light-DOM components removed after `morph:outerHTML`), #3602 (morphing auto-focuses web components), #3659 (focus restoration for preserved elements), #3869 (`outerSync` reparents preserved children and resets CSS transitions "without `moveBefore()`"). That last one is the clearest confirmation that `moveBefore()` is the real fix and everything before it is mitigation.
5. **htmx exposes the whole Idiomorph config surface inline.** The extension supports `hx-swap="morph"`, `morph:outerHTML`, `morph:innerHTML`, and `hx-swap="morph:<expr>"` where `<expr>` is a JS expression evaluated and passed straight to `Idiomorph.morph()` — so an htmx user can write `hx-swap='morph:{ignoreActiveValue:true}'` on one element and be done. Turbo deliberately treats Idiomorph as a private implementation detail (seanpdoyle: *"I have a sense that the fact that Idiomorph handles morphing is to be treated like a private implementation detail"*). That is a defensible API decision, but it means every option Turbo hasn't surfaced — `ignoreActiveValue`, `restoreFocus`, `ignoreActive`, `morphStyle` — is simply unreachable, and the only escape hatch is `Turbo.morphElements()` called by hand from a `turbo:before-*-render` listener.
6. **The Alpine story is a cautionary tale.** htmx maintains `hx-alpine-compat` and there is a live discussion (#3791) about propagating Alpine reactivity through morph swaps. If crosswire ever recommends Alpine alongside Turbo morphing, that integration burden is real and unowned on the Turbo side.

### Has anyone shipped a better Stimulus-aware morph strategy?

Searched GitHub repos, and the honest answer is **no**.

* `asgerb/stimulus-durable-values` — 0 stars, last touched 2024-09-19, patches Stimulus internals. Analysed in W11. The best prior art, and not production-grade.
* Evil Martians' `data-turbo-morph-permanent-attrs` — described in a blog post, not released as a package.
* `josefarias/hotwire_combobox` PR #132 — a single component solving it for itself with `turbo:morph-element`.
* No gem, no npm package, no Turbo plugin implements the middle ground.

**This is a genuinely open niche.** Two teams built the same thing privately; the maintainers of both Turbo and Stimulus have said they won't build it; the canonical issue has been open unowned for two and a half years.

### Other morphing implementations worth knowing

* **[Morphlex](https://github.com/yippee-fun/morphlex)** (joeldrapper, 214 stars, active 2026-05) — ~3 KB TypeScript, from the Phlex world. Explicitly borrows idiomorph's id sets, adds: longest-increasing-subsequence for partial sorts (fewer moves on reorder), `moveBefore()`, `isEqualNode()` fast-path made *value-sensitive* by temporarily tagging inputs whose `value` differs from `defaultValue`, and a **`preserveChanges: true` option that preserves modified form inputs**. That option is the correct answer to the turbo#1194/#1199 stalemate and Turbo does not have it. Also has richer hooks (`beforeNodeVisited`, `beforeChildrenVisited`, `afterAttributeUpdated`).
* **Datastar** maintains an idiomorph fork with the subtree-skip optimisation and value-preservation changes; its maintainer reports ~30% less morph time from the `isEqualNode` fast path (idiomorph#144).
* **CableReady** (`stimulusreflex/cable_ready`) uses morphdom for its `morph` operation — the pre-Turbo-8 Rails answer, and the reason `hopsoft`'s 2018 Stimulus issue (#209) reads identically to today's. The advice javan gave then — *"move initialisation out of `connect()` and into `data-action`"* — is still the best structural advice.

---

## Corrections to the public literature

The best public writing on morphing — Radan Skorić's three-part deep dive, thoughtbot's "Turbo morphing woes", the Fly.io gotchas list, David Colby's Turbo 8 trilogy — is catalogued with code in [`06-blog-corpus.md`](./06-blog-corpus.md) §"Morphing & page refreshes". Read it for the tutorials. Four widely-repeated claims in that corpus are **now out of date against Turbo 8.0.23 / Idiomorph 0.7.4**, and correcting them is the main original contribution of this dossier.

### C1 — The "+0.5 / +1" matching score no longer exists

Radan Skorić's idiomorph deep dive (and its interactive playground) teaches node matching as a **score**: *"+0.5 for a matching node type, +1 for each shared id"*, with the highest-scoring candidate winning. That was accurate for idiomorph ≤ 0.6.x, which had a `twoPass` mode and a scoring function.

**Idiomorph 0.7.1 (Feb 2025) deleted it.** CHANGELOG, verbatim:

> "Remove `twoPass` option. **There is only one single morphing algorithm now**, which is more correct than both previous versions."

Current 0.7.4 matching is boolean and order-sensitive, not scored (see [The Idiomorph algorithm, precisely](#the-idiomorph-algorithm-precisely-v074-srcidiomorphjs)): a `isSoftMatch` gate (same nodeType + tagName + compatible id), then the **first** candidate that shares *any* persistent id wins immediately, with a soft-match fallback plus two anti-churn heuristics and an early stop at the focused element. There is no "best" match, only the first acceptable one scanning forward. Turbo has shipped the post-rewrite algorithm since **8.0.13** (March 2025, PR #1321).

Practical difference: under the old scoring, a candidate sharing two ids beat one sharing one id even if the latter came first. Under the new algorithm the *first* id-set match wins regardless of how many ids it shares. **If you are reasoning about a morph using the scoring model, you will predict the wrong outcome.**

### C2 — Turbo does not hand `<head>` to Idiomorph

The same article states that `<head>` "uses idiomorph's **merge** algorithm (Turbo's default)", is compared by full `outerHTML`, and blocks the body morph until new assets' `load` events fire.

**Turbo never passes `<head>` to Idiomorph at all.** `MorphingPageRenderer.renderElement` receives `document.body` and the new `<body>`; `<head>` is handled *before* that by `PageRenderer#prepareToRender → mergeHead()`, which is Turbo's own pre-morphing machinery (`mergeProvisionalElements`, `copyNewHeadStylesheetElements`, `copyNewHeadScriptElements`, `removeUnusedDynamicStylesheetElements`). The *observable behaviour* is similar — provisional head elements absent from the new head are removed, new ones appended, and `copyNewHeadStylesheetElements` does `await Promise.all(loadingElements)` before the body renders — so the practical advice ("front-load assets; don't introduce huge new stylesheets in morphed content") survives.

What does **not** survive: **Idiomorph's `head` config is inert under Turbo.** `head: { style: "append" }`, `im-preserve="true"`, `im-re-append="true"`, `afterHeadMorphed` — none of these do anything in a Turbo app. If you find advice telling you to use them, it is for htmx or a direct `Idiomorph.morph()` call.

### C3 — `data-turbo-permanent` under morph is a different mechanism than described

Radan's description — Turbo saves permanent elements **by id**, substitutes placeholders in the incoming content, renders, then swaps the saved nodes back — is an accurate description of **Bardo**, which runs on the Drive *replace* path and on Turbo Stream rendering. It is **not** what happens during a morph. `MorphingPageRenderer` overrides `preservingPermanentElements` to a no-op passthrough; permanence is enforced by Idiomorph callbacks that simply refuse to touch or remove the node. Consequences already covered in [Interactions](#morph--data-turbo-permanent): **no `id` required under morph**, the node is never detached (so listeners/iframes/media genuinely survive, rather than surviving a detach-reattach), and a permanent element missing from the new page is *kept* rather than lost.

### C4 — `frame.reload()` and `refresh="morph"`

Radan's correction — *"Turbo Frames do not support morphing for their own updates; `refresh="morph"` means the frame is reloaded with morphing during page refreshes"* — is **correct**, and so is his noted exception: a frame with `refresh="morph"` *does* morph when reloaded from JS via `.reload()`. Source-confirmed: `FrameElement#reload()` → `FrameController#sourceURLReloaded()` → `#shouldMorphFrame = src && refresh === "morph"` → `MorphingFrameRenderer`. This resolves the contradiction between `02-` and `07-` in the crosswire notes: **frame link navigation never morphs; `frame.reload()` does; page refresh does.** Three paths, two of which morph.

### Field reports worth keeping (all already in `06-blog-corpus.md`)

* **thoughtbot, "Turbo morphing woes"** (Matheus Richard, Dec 2024) — the canonical three-failure writeup: Trix dies (fix: `data-turbo-permanent` on the *wrapping div*, because `<trix-toolbar>` needs preserving too); forms don't clear after a morphed POST (fix: `turbo:submit-end->form#reset`); `broadcasts_refreshes` reopens a `<details>` for **every viewer** whenever anyone edits (fix: cancel `turbo:before-morph-attribute` for `open`). That third one is the best illustration in the literature of why broadcast morphing amplifies state bugs across users.
* **thoughtbot, "Hotwire and That Syncing Feeling"** (Louis Antonopoulos, Mar 2025) — ~30 concurrent clients synced with `broadcasts_refreshes` alone, no custom channel. Two production gotchas: **`increment!`/`decrement!` skip AR callbacks so they never broadcast** (use `update!`), and system tests need `perform_enqueued_jobs` or the inline adapter to see the async broadcast. This is the best evidence that the `broadcasts_refreshes` fan-out model works at modest scale.
* **David Colby's Turbo 8 trilogy** (Mar 2024) — sortable tables and search/filter built purely on page refreshes with `data-turbo-action: 'replace'` on the links and form. Note this is **Trap A used deliberately**: same path, different query params, morph. His own stated cost: `replace` doesn't advance history, so users can't step back through sort changes. His verdict on retrofits is the honest one: *"morphing refreshes suit new features more than retrofits."*
* **Evil Martians, "Turbo Morph Drive"** (Dementyev/Turner, Oct 2023) — pre-Turbo-8 prototype that independently invented `data-morph-permanent` + `beforeNodeMorphed`, frame morphing via `turbo:before-frame-render`, and a custom `refresh` stream action. It predicted Turbo 8's design almost exactly, and its conclusion — make Stimulus controllers *"reactive to attribute changes instead of expecting reconnect"* — is the same advice the maintainers landed on two years later.
* **Fly.io, "8 Turbo 8 Gotchas"** (Brad Gessler) — Radan points newcomers here rather than at his own deep dives. Worth reading before enabling morphing.

---

## Corrections to earlier crosswire notes

Resolved against Turbo 8.0.23 / turbo-rails 2.0.23 / idiomorph 0.7.4 source.

1. **`data-turbo-permanent` and `id` (02 §gotcha 7, 10 ×3 vs 07:949).** `07` is correct: **under morphing no `id` is required**; `beforeNodeMorphed` checks the attribute only. Under Drive **replace**, `id` is mandatory (Bardo matches by id). `10`'s "a permanent element without an id silently does nothing" is true for replace and false for morph. Recommended guidance stands ("always add an id") but the *reason* must be restated.
2. **Permanent elements and Turbo Streams (02:402 vs 07:1576 / turbo#623).** `02` is correct for current Turbo: `StreamMessageRenderer.render` wraps the append in `Bardo.preservingPermanentElements(...)`. The caveat is narrower than "ignored": permanence is honoured only for elements that have an `id` **and** appear inside the stream's `<template>` (`getPermanentElementById`).
3. **`frame.reload()` ignores `refresh="morph"` (07:541, citing turbo#1161).** **No longer true.** `reload()` → `sourceURLReloaded()` → `#shouldMorphFrame = src && refresh === "morph"` → `MorphingFrameRenderer`. Fixed by PR #1192 (Feb 2024).
4. **The "query string trap" framing (02 vs 07).** Both are describing the same code. `07`'s "query params no longer defeat it (PR #1079)" is historically accurate; `02`'s "morph detection ignores the query string" is mechanically accurate. The trap is real in *both* directions and should be documented as such — see [Rule 2](#rule-2--the-query-string-trap-in-both-directions).
5. **Which meta tag decides.** `02` correctly quotes `(visit?.refresh?.method || this.snapshot.refreshMethod)`. Worth stating explicitly that `this.snapshot` is the **outgoing** page, so the page you are leaving decides. PR #1123 briefly made it the incoming snapshot; PR #1208 reverted that.
6. **The dummy-query-param workaround** (stimulus#775, repeated in the wild) does not work and hasn't since PR #1079. Do not reproduce it.
7. **`turbo:morph` firing twice.** True in early Turbo 8 (cached preview + response). Previews are disabled for morphs since PR #1098, so it should be single-fire now. Keep the "make teardown idempotent" advice; drop "it always fires twice" as a stated fact. **[worth an empirical check]**

---

## Open questions

1. **Does the repo owner's `preserve` primitive belong in Stimulus-land or Turbo-land?** The B2 divergence check is Stimulus-shaped (it needs `values`); the B3/B4 lifecycle is Turbo-shaped (it needs morph events). A crosswire package can do both, which is arguably the reason for it to exist.
2. **Is the divergence check (B2) actually right?** "Preserve only if the controller diverged" is my proposal, not anyone's shipped behaviour. It needs a prototype and a matrix of cases: server changes + client unchanged; client changes + server unchanged; both change; server *removes* the attribute.
3. **What is the real performance cliff?** No one has published numbers. The tooling note asserts near-O(n²) on long id-less sibling lists from reading the source, and idiomorph#143/#144 are open about it. **Worth measuring:** morph time vs node count, with and without stable ids, on a realistic 5,000-node page.
4. **How much does `moveBefore()` actually change outcomes?** It is the difference between "iframe survives" and "iframe reloads". A Chromium-vs-Firefox matrix over the inventory table would be genuinely novel and would tell teams which of these bugs are already expiring.
5. **Does per-page opt-out via `content_for` work?** turbo-rails#549 says no ("the meta tags are cached between page navigation"); seanpdoyle could not reproduce and his PR #550 needed no implementation change. The Turbo-side mechanism looks sound: `PageRenderer#mergeProvisionalElements` explicitly removes current head elements (including `<meta>`) absent from the new head and appends the new ones, so the tag really is swapped per page. The remaining risk is Rails-side `provide`/`content_for` ordering, not Turbo. Still worth a test app before crosswire recommends per-page opt-in as the default posture. **[partially resolved]**
6. **Hotwire Native modals + morph.** Asserted from mechanism, not verified against native source. Worth a direct experiment: does a broadcast refresh reach a modal web view at all?
7. **`data-turbo-permanent` + view transitions under *morph*.** turbo#1048 is about the replace path. Unknown for morph.
8. **Should crosswire ship the `<dialog>` listener as a default?** Turbo maintainers agreed it belongs in Turbo (brunoprietog, Aug 2024) and it still isn't there. Shipping it in a crosswire "morph safety" bundle is low-risk and high-value — but it silently changes `<dialog>` semantics, which needs documenting.
9. **Is the pantry observable?** Elements relocated through the pantry fire no events. Is there any reliable way to detect "my element was relocated, not morphed"? (`turbo:morph-element` fires afterwards, but nothing distinguishes the two paths.)
10. **Would a Turbo PR be better spent on `preserveChanges` (Morphlex's option) than on a Stimulus mixin?** Failure modes #6, #7 and #35 are all "the server and the user disagree about a form value". Morphlex solved it at the morph layer with `preserveChanges: true`. Turbo reverted its attempt (`ignoreActiveValue`) because it was too coarse — jorgemanrubia's specific complaint was that *"some parent container in the page grabbed the focus, and this resulted in morphing not working as expected because the whole tree was skipped"*, which is a bug in `ignoreActive`'s **scope**, not in the idea. A dirty-value check (compare `.value` against `defaultValue`, not against the incoming attribute) is precisely scoped and would fix it for everyone rather than per-controller. **Joel Drapper has already floated the delivery mechanism** on Basecamp's own demo repo (turbo-8-morphing-demo#9): *"I'm considering making an extension to Turbo that switches the morphing library from Idiomorph to Morphlex, which would allow you to configure `preserveChanges`."* If crosswire wants one high-leverage upstream contribution, this is a stronger candidate than a Stimulus mixin.
11. **The lazily-explored corners.** A thorough field sweep (~45 sources: the Hotwire forum, HN, GitHub across six repos, the blog corpus) found **no reports at all** on: Alpine.js state under morph; SortableJS under morph (surprising, since morph reorders and reparents); Flatpickr, TinyMCE, CodeMirror, Mapbox, Choices.js, Slim Select; `<input type="file">` and `FileList` retention; browser/password-manager **autofill** values; a POST **in flight** when a broadcast refresh lands; `<video>` restarting *specifically* due to morph (only audio is documented); the **Popover API**; and **analytics / session-replay / A-B-test scripts**. That last one is the biggest gap: the mechanism suggests two hazards — `turbo:load` fires on every broadcast refresh (so pageview-on-`turbo:load` instrumentation double-counts, now triggered by *other users'* actions), and inline `<script>` snippets are never re-executed — but **neither is corroborated by any field report.** Treat all of these as untested, not as safe.
12. **Is there really no Rails World 2024/2025 morphing talk?** The 2023 announcement talk exists (Manrubia). The only migration-focused talk found is a Rocky Mountain Ruby 2024 lightning talk ([Ron Shinall, "Turbo Morphing — Making the Jump"](https://www.rubyevents.org/talks/lightning-talk-turbo-morphing-making-the-jump)), which I could not transcribe. The absence of follow-up conference content two years after launch is itself a signal worth interpreting.
