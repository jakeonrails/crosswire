# Why isn't this working?

This is a triage guide, organized by symptom — because a symptom is what you actually have. Each entry
follows the same shape: **symptom → how to confirm it's this → root cause → fix**, leading with the
cheapest check you can run. Where a console or network signature exists, it's given verbatim so you can
pattern-match against your own devtools.

The single biggest finding behind this whole document: the overwhelming majority of Hotwire questions
online are not "how do I build X," they are "I built X and nothing happened." If that's you, start with
the first section.

---

## "I clicked / submitted and nothing happened"

This is the single largest category of Hotwire problem report anywhere it's been measured. Before
chasing anything specific, run these five checks **in this order** — they're ordered by how often each
one turns out to be the actual cause.

**1. Is there an unrelated JS error earlier on the page?** Open the console first, always. One error
anywhere on the page can silently stop every Stimulus controller from connecting and can abort in-flight
Turbo work. This is the real cause behind a large share of "nothing happened" reports that people spend
hours debugging elsewhere.

**2. Is the response format what Turbo expects?** A GET request does not get a Turbo Stream response
unless the link/form/frame carries `data-turbo-stream`. Check the `Accept` header your request actually
sent, and the `Content-Type` the server actually returned. See "my form submits but nothing updates"
below for the full contract.

**3. Is the HTTP status code right?** A `200 OK` on a non-GET form response is silently discarded by
Turbo — see the same section below.

**4. Is a Stimulus value or target scoped correctly?** Values and targets must live on/inside the
controller element itself, never outside it. See "my Stimulus controller doesn't connect" below.

**5. Does the response actually contain what you're targeting?** A frame response missing the matching
`id`, or a stream targeting an id that isn't in the DOM right now, both fail **silently** — no error,
no console warning. See "Content is missing inside a frame" below.

If none of those five turn anything up, paste this in the console and reproduce the click — it logs
every Turbo event and its target/detail as it fires, which turns "nothing happened" into "here's exactly
where it stopped":

```js
;[
  "turbo:click","turbo:before-visit","turbo:visit","turbo:before-cache",
  "turbo:before-render","turbo:render","turbo:load","turbo:reload",
  "turbo:before-fetch-request","turbo:before-fetch-response","turbo:fetch-request-error",
  "turbo:submit-start","turbo:submit-end",
  "turbo:before-frame-render","turbo:frame-render","turbo:frame-load","turbo:frame-missing",
  "turbo:before-stream-render",
  "turbo:morph","turbo:before-morph-element","turbo:morph-element","turbo:before-frame-morph",
].forEach((name) =>
  document.addEventListener(name, (e) =>
    console.log("%c" + name, "color:#0076ff", e.target, e.detail ?? "")))
```

Also set `application.debug = true` in your Stimulus `application.js` to log every controller
connect/disconnect/action.

---

## Content is missing inside a frame

**Symptom.** The frame renders `Content missing`, or the console shows:
> `The response (200) did not contain the expected <turbo-frame id="…"> and will be ignored.`

**Confirm it's this.** View source on the frame's actual response (open `frame.src` directly, or check
the Network tab response body) and search for `id="…"` matching the frame you navigated.

**Root cause — checklist, in order of likelihood:**

| Cause | How to tell | Fix |
|---|---|---|
| The response redirected somewhere that doesn't have the frame (login, root) | Network tab: was there a redirect before the final response? | `<% turbo_page_requires_reload %>` on pages that should always break out of a frame |
| A `layout "application"` override renders the frame in the layout *and* the view — two frames, same id, only the first (often empty) wins | Frame requests use the minimal `turbo_rails/frame` layout by default; check if you forced a static layout | Convert to a layout method: `layout -> { turbo_frame_request? ? "turbo_rails/frame" : "application" }` |
| A 4xx/5xx error page rendered instead | Status code in the Network tab | Error pages have no frame by definition — either render the frame on error paths too, or handle `turbo:frame-missing` |
| Duplicate frame `id`s on the page | `document.querySelectorAll('turbo-frame#x').length` | Turbo matches the *first* one, which may not be yours — rename |
| The frame is inside a `<table>`/`<tbody>`/`<tr>` | Inspect where it actually rendered in the DOM | HTML's table content model hoists it out. Target the row with a Turbo Stream instead — see `corrections.md` |
| You're targeting a frame id that doesn't exist yet (e.g. inside another lazy frame) | `document.getElementById("x")` in the console | Fix the id, or check load ordering |

**The generic safety net**, worth adding globally rather than per-page:

```js
document.addEventListener("turbo:frame-missing", (event) => {
  const { detail: { response, visit } } = event
  event.preventDefault()
  visit(response, { action: "replace" })   // escalate to a full-page visit
})
```

**Do not** reach for `redirect_to path, turbo_frame: "_top"` as the fix — it doesn't exist. See
`corrections.md`.

---

## My Stimulus controller doesn't connect

**The cheapest check first:** open the console. Any unrelated JS error earlier on the page silently
stops every controller on that page from connecting — this is the actual cause behind a large share of
"my controller won't connect" reports, and it's the first thing to rule out.

Then, in order:

**1. Is the file/attribute name actually a match?** `foo_bar_controller.js` ↔
`data-controller="foo-bar"`. Subfolders use `--`: `controllers/admin/foo_controller.js` →
`admin--foo`.

**2. Are you importing from the right package?** `import { Controller } from "@hotwired/stimulus"` — the
bare `"stimulus"` specifier hasn't existed since Stimulus 3.0.

**3. Is the manifest/import map actually current?** esbuild/webpack apps need
`bin/rails stimulus:manifest:update` re-run. Importmap apps autoload via `eagerLoadControllersFrom` —
confirm the directory is covered by `pin_all_from`. Sprockets apps need
`//= link_tree ../../javascript .js` in `manifest.js` (Propshaft/Rails 8 apps have no `manifest.js` —
skip this check entirely there).

**4. Is there a JS error during import specifically?** `lazyLoadControllersFrom` logs
`Failed to autoload controller: <name>` to the console when a controller module itself throws on import.

**5. Did the element arrive after Stimulus's `Application` was scoped to something that doesn't contain
it?** Rare, but worth ruling out if everything else checks out.

**6. Turn on the logger and confirm from Stimulus's own point of view:**

```js
// app/javascript/controllers/application.js
application.debug = true   // logs every connect/disconnect/action
```

Or run this in the console to directly diff what's in the DOM against what's registered:

```js
const inDom = new Set([...document.querySelectorAll("[data-controller]")]
  .flatMap(el => el.dataset.controller.split(/\s+/)))
const registered = new Set(Stimulus.router.modules.map(m => m.identifier))
console.log("in DOM but NOT registered:", [...inDom].filter(id => !registered.has(id)))
```

**If it's registered but still isn't connecting on a specific element**, the element most likely arrived
via a Turbo Stream into a subtree Stimulus's `MutationObserver` isn't watching (rare), or — much more
commonly — you're looking at a controller declared **on** a `<turbo-frame>` element itself: a frame's
content is replaced without replacing the frame element, so Stimulus never disconnects/reconnects a
controller declared on the frame tag. Put the controller on an element *inside* the frame's content
instead, so it ships fresh with every response.

**A related but distinct failure — the action isn't firing even though the controller connected:**

- Check the descriptor syntax exactly: `data-action="click->dropdown#toggle"`. A stray space around `->`,
  a typo'd identifier, or a method name that doesn't exist on the controller all silently no-op (Stimulus
  does warn on the last one — check the console).
- Check you're not relying on Stimulus's inferred default event for the wrong element. Stimulus infers
  `click` for most elements, `submit` for `<form>`, `input` for `<input>`/`<textarea>`/`<select>`,
  `change` for `<select>`. A `<div>` expecting `submit` needs the event named explicitly.
- Non-bubbling events (`focus`, `blur`, `mouseenter`, `mouseleave`) don't delegate through Stimulus's
  event binding. Use `@window`/`@document`, or their bubbling counterparts (`focusin`, `focusout`).

---

## My form submits but nothing updates

**The cheapest check:** open the Network tab and look at the response status code for the submission.
This single number resolves most of this category.

**The contract, in full** (from Turbo's `form_submission.js`):

```
response 4xx           → re-renders the response IN PLACE, URL unchanged     (validation errors)
response 5xx            → replaces <head> AND <body> with the error page
response 2xx + redirect → follows to the redirect target                     (the happy path)
response 200, no redirect, method != GET
                        → Error: "Form responses must redirect to another location"
                          Console error. NOTHING renders. This is the classic silent failure.
```

**If you see the console error above:** your controller returned a bare `200` (usually `render :new` or
`render :edit` with no explicit status) instead of a redirect or a 4xx. Fix:

```ruby
def create
  @post = Post.new(post_params)
  if @post.save
    redirect_to @post, status: :see_other
  else
    render :new, status: :unprocessable_content   # not optional
  end
end
```

**If the redirect target 404s, or a DELETE seems to re-fire against the wrong route:** you used the
Rails default 302, which preserves the HTTP method for non-GET requests per the Fetch spec. Use
`status: :see_other` (303) on every redirect reached from a non-GET action.

**If the 422 response renders but the page still looks unchanged or partially broken:** the 422 body must
be a **complete document** rendered from the matching template (`new.html.erb`, not `.slim`/`.haml`
missing the `.html` segment, and not a bare partial or a `layout false` controller) — otherwise Turbo
can't replace `<body>` and silently falls back to a GET of the original URL. **Signature:** you'll see a
`422` in the log immediately followed by a `200 GET` of the same page.

**If nothing shows in the Network tab at all:** rails-ujs may still be loaded with
`form_with_generates_remote_forms = true`; the form gets `[data-remote="true"]` and UJS intercepts before
Turbo ever sees it.

---

## The page fully reloads when it shouldn't

**The cheapest check:** open the Network tab, submit or navigate, and count the requests for the same
action. If you see it processed **twice** — once as `TURBO_STREAM`, once as `HTML` — you have the
signature below.

**The `data-turbo-track="reload"` timestamped-asset bug — the best root-cause find in the whole
corpus, and it takes people days to find on their own.** Signature in the Rails log:

```
Processing by JobsController#show as TURBO_STREAM
Processing by JobsController#show as HTML
```

The second, full-page GET wipes your flash message too, which is usually what gets reported ("my flash
disappears after redirect"). The actual cause is almost always a `<script>` tag pasted into `<head>` from
a CDN snippet, carrying `data-turbo-track="reload"` with a **cache-busting timestamp baked into the
URL**. Turbo compares tracked-asset URLs between the old and new page; a timestamp means they never
match, so Turbo concludes the assets changed and forces a full reload on **every single navigation**.

Every plausible-sounding fix gets tried first and is wrong: `target: "_top"`, `status: :see_other`,
hooking `turbo:submit-end` and calling `Turbo.visit()`, changing Devise's `navigational_formats`. None of
them touch it. Find the offending `<script>` (usually a chat widget, analytics snippet, or A/B testing
tool pasted into the layout) and either drop the tracking attribute or make the URL stable.

**Other causes of a full reload you didn't ask for**, roughly in order of likelihood:

- `data-turbo="false"` on the element or **any ancestor**.
- The URL ends in one of the ~50 extensions Turbo won't drive (`.pdf`, `.csv`, `.json`, `.zip`, …) — check
  with `Turbo.config.drive.unvisitableExtensions.has(".csv")`.
- `target="_blank"`, or any `target` other than `_top`/none.
- Cross-origin `href` — Turbo only drives same-origin URLs.
- `<meta name="turbo-visit-control" content="reload">` on the *destination* page — this is often
  intentional (e.g. a sign-in page) but surprising if you didn't add it.
- Genuine tracked-asset changes: your CSS/JS digest really did change (e.g. mid-deploy) — this one is
  correct behavior, not a bug.

---

## My JS library breaks after a form error

**Symptom.** A date picker, rich select, or chart works fine on first load, but goes dead — visually
gone, or frozen and unresponsive — the moment a form fails validation and re-renders.

**Confirm it's this.** This happens specifically on pages with morphing enabled
(`turbo_refreshes_with method: :morph`, or a `turbo_stream.replace(..., method: :morph)`). **422
responses do morph** — Turbo's own test suite explicitly asserts this — which is exactly the response
your validation-failure path returns. This makes it the single most commonly hit morphing bug, because
it's on the most ordinary flow there is.

**Root cause.** Idiomorph patches the existing DOM node in place rather than removing and re-adding it.
Your library's injected DOM (a calendar popup, an enhanced `<select>` wrapper) isn't in the server's
freshly-rendered HTML, so the morph deletes it. The original element itself survives, so
`disconnect()`/`connect()` never fire — there's no lifecycle hook telling your controller to rebuild.
This is intentional and permanent: turbo#1210 has been open 2.5 years with no plan to fix it by default.
> jorgemanrubia: *"We originally considered triggering a stimulus reconnect automatically for all the
> controllers, but that assumes too much. Often, you want controllers to keep the state they have when a
> page refresh happens."*

**Fix, in order of preference:**

1. **Let the server own the state, and reinitialize on a value change** (the architecturally correct
   answer, when you control the HTML):
   ```js
   static values = { renderedAt: String }
   renderedAtValueChanged() { this.teardown(); this.build() }
   ```
2. **Reinitialize on the element-scoped morph event** (the best general-purpose fix):
   ```html
   <div data-controller="tom-select" data-action="turbo:morph-element->tom-select#reconnect">
   ```
   Do not scope this to `turbo:morph@window` — it fires page-wide for every morph, including ones that
   didn't touch your element. See `corrections.md`.
3. **Exclude the widget from morphing entirely**, if the server never needs to update it:
   ```html
   <div data-turbo-permanent>…</div>
   ```

For the full decision matrix (values-clobbering vs widget-DOM-loss, controller-owned vs server-owned
state) see `research/notes/14-morphing-dossier.md` — this page gives you the fast diagnosis, that file
gives you the complete design space.

---

## My dialog froze the page

**Symptom.** You open a `<dialog>` with `showModal()`. A morph refresh arrives — a broadcast, a redirect
back to the same page — and the dialog visually disappears, but **nothing on the page is clickable
afterward.**

**Confirm it's this.** Check `document.querySelector('dialog[open]')` — if it returns nothing but the
page is still inert, and the page has morphing enabled, this is it.

**Root cause.** `showModal()` promotes the `<dialog>` into the browser's top layer. When the morph runs,
the server's HTML (rendered after the dialog closed, or simply not including the `open` attribute)
causes idiomorph to remove the `open` attribute from the live element — but per the HTML spec, removing
`[open]` via `removeAttribute` does **not** implicitly call `.close()`. The dialog's node is gone from
view, but the browser's top layer still thinks a modal is open, and blocks all interaction with the rest
of the document. This has been open since 2024 ([`turbo#1239`](https://github.com/hotwired/turbo/issues/1239))
and both `<dialog>` and morphing are on Rails' own recommended path, so this collision sits squarely on
the happy path, not an edge case.

**Fix — the maintainer's own snippet, needed on every app combining `<dialog>` with morphing today:**

```js
addEventListener("turbo:before-morph-attribute", (event) => {
  const { target, detail: { attributeName, mutationType } } = event
  if (target instanceof HTMLDialogElement && attributeName === "open" && mutationType === "remove") {
    event.preventDefault()
    target.close()
  }
})
```

A maintainer agreed on the record that this belongs in Turbo itself. It still doesn't ship there.
crosswire's `dialog` primitive installs this fix by default, so you don't need to remember it — but if
you're hand-rolling a modal outside crosswire, you need this snippet.

---

## State resets for everyone when someone else edits

**Symptom.** An `<details>` disclosure, an accordion, or any client-only open/closed state snaps shut for
every viewer on a page whenever *anyone* edits something — not just the person who made the change.

**Confirm it's this.** The page uses `broadcasts_refreshes` (or `broadcasts_refreshes_to`) paired with
morphing, and the state that reset is something the server doesn't know about (it's not in a column, not
in a session — it only ever lived in the DOM as an attribute).

**Root cause.** `broadcasts_refreshes` sends every subscribed client a page-refresh instruction; each
client fetches the page fresh and morphs it in. The server's HTML has no `open` attribute (or whatever
client-only state you're tracking), so `morphAttributes` strips it from **every** subscriber's DOM — not
just the editor's. This is the sharp edge of broadcast morphing: it amplifies every client-state bug
across the whole audience simultaneously, rather than confining it to the person who triggered it.
> thoughtbot's field report on exactly this: *"a `<details>` reopens for every viewer whenever anyone
> edits something."*

**Fix, two options, in order of durability:**

1. **Persist the state server-side** if it deserves to survive a reload anyway (Radan Skorić's family-3
   fix): a user-preferences row, or encode it in the URL. This is the one to prefer — it usually comes
   with a UX win too (the state now survives a real reload, and becomes shareable).
2. **Cancel the attribute removal**, if the state is genuinely ephemeral:
   ```js
   addEventListener("turbo:before-morph-attribute", (event) => {
     if (event.detail.attributeName === "open") event.preventDefault()
   })
   ```

Before shipping `broadcasts_refreshes` + morphing on any page, walk it and list every piece of state that
isn't in the server's HTML — open panels, selected tabs, dismissed banners, scroll inside nested
containers. Each one is a candidate for this exact bug. crosswire's `disclosure` primitive persists open
state through `[name]ValueChanged` rather than a bare DOM attribute, which sidesteps this specific case.

---

## Bonus: double submits, or listeners that seem to accumulate

**Symptom.** Two records get created from one click. An event handler appears to fire twice. A listener
count that climbs every time you navigate.

**Root cause, in order of likelihood:**

- **Listeners added to `window`/`document` in `connect()` without matching removal in `disconnect()`.**
  Turbo Drive restores cached pages and re-renders them, so `connect()` runs more than once per visit —
  and under morphing this is worse, because `connect()`/`disconnect()` no longer bracket every server
  render at all (a surviving element keeps its controller instance alive across many morphs).
- **The same controller module registered twice** — usually `pin "application"` *and*
  `pin_all_from "app/javascript/controllers"` while `application.js` also imports the controller
  directly. Confirm with `console.log` placed *outside* the controller class body; if it logs twice per
  page load, the module itself is being evaluated twice, not just double-bound.
- **The submit button re-enabling before the redirect completes**, leaving a window where a second click
  submits again. This one is a known, unfixed upstream gap (`turbo#766`), not something you're doing
  wrong — mitigate with a `disabled`/`aria-disabled` state tied to `turbo:submit-start`/`turbo:submit-end`
  rather than assuming the redirect always wins the race.

**Fix.** Prefer `data-action` over manual `addEventListener` wherever possible — Stimulus handles
teardown for you. Where you must add listeners manually, keep a stable bound reference and remove it in
`disconnect()`. Verify with `getEventListeners(window)` in Chrome DevTools before and after a few Turbo
visits.

---

## Bonus: Turbo isn't intercepting a link or form at all

**Symptom.** A full page reload happens where you expected a Drive visit, frame swap, or stream — the
browser's native loading spinner/blank-flash appears instead of Turbo's progress bar.

**Root cause checklist:**

- `data-turbo="false"` on the element or any ancestor.
- `target="_blank"` or any `target` other than `_top`.
- Cross-origin `href`.
- The URL ends in one of Turbo's unvisitable extensions (see "the page fully reloads" above).
- `Turbo.config.drive.enabled === false`, or `Turbo.config.forms.mode` is `"off"`/`"optin"`.
- `<meta name="turbo-visit-control" content="reload">` on the destination page.
- For a frame specifically: `data-turbo-frame` points at an id that doesn't exist anywhere on the current
  page.
