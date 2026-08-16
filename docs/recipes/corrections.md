<%# crosswire:contract v1 %>
# Advice that is now wrong

Hotwire's documentation problem isn't just gaps — it's that a lot of what's out there was true once
and no longer is, or was never true and got repeated anyway. Every entry below cost someone real time.
They're ordered by how likely you are to hit them, not by how interesting they are.

Format: **the claim**, as people actually write it → **the reality**, verified against source → **what
to do instead**. Each entry cites the research file it came from — `research/notes/NN-*.md` — so you can
read the primary sources (GitHub threads, maintainer quotes, source line numbers) if you want the full
trail.

If you only read one thing on this page, read the first five. They account for most of the "I built
this and nothing happened" reports in the wild.

---

### "`render :new` after a failed save will show my validation errors"

**Reality.** Turbo only re-renders a form response *in place* when the status is 4xx or 5xx. A `200 OK`
that isn't a redirect is treated as a programming error — Turbo throws it away and logs `Form responses
must redirect to another location`. Nothing appears on screen.

**Do this instead.**

```ruby
def create
  @post = Post.new(post_params)
  if @post.save
    redirect_to @post, status: :see_other
  else
    render :new, status: :unprocessable_content   # the 4xx is not optional
  end
end
```

*research/notes/02-turbo-deep-dive.md §2.10, research/notes/07-problem-mining.md P1*

---

### "`redirect_to` after a `destroy` or `update` is fine with the Rails default"

**Reality.** Turbo submits with `fetch(..., { redirect: "follow" })`. Per the Fetch spec, a `301`/`302`
preserves the HTTP method for `PUT`/`PATCH`/`DELETE` requests — so a plain `redirect_to` after a `destroy`
re-issues a **`DELETE`** against the redirect target, producing `No route matches [DELETE] "/"`. This is
standards-conformant, not a Turbo bug. Only **303 See Other** tells the browser to switch to `GET`.

**Do this instead.**

```ruby
redirect_to posts_path, status: :see_other
```

Rule of thumb: every `redirect_to` reached from a non-GET action should carry `status: :see_other`. It's
harmless after `POST` and mandatory after `PATCH`/`PUT`/`DELETE`.

*research/notes/02-turbo-deep-dive.md §2.10, research/notes/07-problem-mining.md Q7*

---

### "`status: :unprocessable_entity` is the right symbol for a 422"

**Reality.** Rack 3.1 renamed the 422 status from *Unprocessable Entity* to *Unprocessable Content*.
`:unprocessable_entity` still resolves to 422 but is a deprecated alias and logs a Rack deprecation
warning on Rack ≥ 3.2. Rails 8.1 scaffolds emit the new name.

**Do this instead.**

```ruby
render :new, status: :unprocessable_content
```

Both work today. Every pre-2026 tutorial says `:unprocessable_entity` — that's not wrong, just dated.

*research/notes/02-turbo-deep-dive.md §2.10, research/notes/07-problem-mining.md — version facts*

---

### "`redirect_to path, turbo_frame: "_top"` breaks a form out of a frame"

**Reality. This option does not exist.** It's [`turbo-rails#367`](https://github.com/hotwired/turbo-rails/pull/367),
open since 2022-07-31, still unmerged. A fetch `Response` resulting in a redirect deliberately prevents
script access to the intermediate redirect response — so a `Turbo-Frame: _top` header on a redirect is
unreachable by design, not an oversight. Several blog posts present this option as shipped. It never has
been.

**Do this instead.** The pattern every production app converges on: a custom Turbo Stream action for the
redirect, used on the success path from inside the frame.

```js
// app/javascript/application.js
Turbo.StreamActions.redirect = function () { Turbo.visit(this.getAttribute("target")) }
```

```ruby
format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, articles_url) }
```

Or give the frame `target: "_top"` and answer failures with a `.turbo_stream.erb` that stays inside the
frame — see `docs/recipes/diagnosis.md` → "my form submits but nothing updates."

*research/notes/07-problem-mining.md Q4, P2*

---

### "`data-turbo-confirm` puts a confirmation dialog on any link"

**Reality.** On a plain `<a href>` with no `data-turbo-method`, `data-turbo-confirm` is a **silent
no-op**. dhh, on the record: *"Don't think this makes sense on regular links, but on
`data-turbo-method` links yes."* It only fires on links/forms that actually submit through Turbo's form
machinery.

**Do this instead.**

```erb
<%= button_to "Delete", post, method: :delete, form: { data: { turbo_confirm: "Are you sure?" } } %>
```

If you truly need it on an `<a>`, pair it with `data-turbo-method`. crosswire's `confirm` primitive
wires an accessible custom dialog behind `Turbo.config.forms.confirm` so you never reach for
`window.confirm()` by hand.

*research/notes/07-problem-mining.md Q8*

---

### "`link_to ..., method: :delete` sends a DELETE"

**Reality.** `method:` on `link_to` was a rails-ujs feature. `@rails/ujs` is removed in Rails 8, so it
silently sends a plain `GET`.

**Do this instead.**

```erb
<%= button_to "Delete", post, method: :delete, data: { turbo_confirm: "Sure?" } %>
```

`button_to` emits a real `<form>`, works with JS off, and is the accessible choice. Only reach for
`link_to ..., data: { turbo_method: :delete }` when you genuinely need an `<a>`.

*research/notes/07-problem-mining.md Q6*

---

### "`element.submit()` will trigger my Stimulus-wired autosubmit"

**Reality.** `HTMLFormElement.submit()` does not fire a `submit` event, so Turbo never sees it and the
form just navigates the old-fashioned way (or does nothing, inside a frame).

**Do this instead.**

```js
this.element.requestSubmit()
```

`requestSubmit()` fires the real `submit` event, respects `formnovalidate`, and is what every
autosubmit/autosave controller should call. crosswire's `autosubmit` primitive does this for you.

*research/notes/07-problem-mining.md Q5*

---

### "Add `format: :turbo_stream` to the path helper to get a stream response"

**Reality.** Turbo refuses to handle a link whose URL carries a non-HTML extension in the path segment,
so this produces a full browser navigation to a raw `text/vnd.turbo-stream.html` document — you'll see
plain text (or garbage) render in the browser.

**Do this instead.**

```erb
<%# WRONG %> <%= button_to "Refresh", refresh_task_path(task, format: :turbo_stream) %>
<%# RIGHT %> <%= button_to "Refresh", refresh_task_path(task) %>
```

Non-GET requests get `text/vnd.turbo-stream.html` in `Accept` automatically. For a GET, opt in with
`data: { turbo_stream: true }` instead of touching the URL.

*research/notes/07-problem-mining.md Q10, Q11*

---

### "Devise needs `data-turbo: false` / a forked `TurboFailureApp` to work with Turbo"

**Reality.** Devise ≥ 4.9 (2023) is Turbo-native. Every `data-turbo: false` workaround, forked
`error-code-422` branch, and custom `TurboFailureApp`/`TurboController` from the Devise wiki is obsolete
— and the wiki page is still the accepted answer on a 14.8k-view forum thread.

**Do this instead.**

```ruby
# config/initializers/devise.rb
config.responder.error_status    = :unprocessable_content
config.responder.redirect_status = :see_other
config.navigational_formats      = ["*/*", :html, :turbo_stream]
```

*research/notes/07-problem-mining.md Q30*

---

### "Reconnect a widget on morph with `reconnect() { this.disconnect(); this.connect() }`"

**Reality.** `connect()` re-adds your `turbo:morph` listener every time it runs. Because `reconnect()`
never removes the *old* listener first, each successive morph doubles the listener count. One reporter
described *"an exponentially increasing population of event listeners and Popper objects. Browser was
not happy, and performance slowed to a crawl after 10-15 refreshes."*

**Do this instead.** Write explicit teardown/build methods and a stable bound reference:

```js
connect() {
  this.reconnect = this.reconnect.bind(this)   // stable reference — required
  window.addEventListener("turbo:morph", this.reconnect)
  this.build()
}
disconnect() {
  window.removeEventListener("turbo:morph", this.reconnect)
  this.teardown()
}
reconnect() { this.teardown(); this.build() }
```

Better still, scope to `turbo:morph-element` on the element itself instead of `window` — see the next
entry.

*research/notes/14-morphing-dossier.md W5*

---

### "Listen for `turbo:morph@window` to reinitialize a widget after a morph"

**Reality.** `turbo:morph` fires on `window` for *every* page morph, whether or not your subtree
changed. On a page with 188 Trix editors, this hung the browser for seconds.

**Do this instead.** Use the element-scoped event, which only fires when something inside *your own*
subtree actually changed:

```html
<div data-controller="tom-select" data-action="turbo:morph-element->tom-select#reconnect">
```

*research/notes/README.md corrections log, research/notes/14-morphing-dossier.md W6*

---

### "`data-turbo-permanent` always needs an `id`, or it silently does nothing"

**Reality.** This is true under Drive's *replace* path (Bardo matches permanent elements by `id`) but
**not under morphing** — `beforeNodeMorphed` checks only the attribute, no `id` is consulted. Since
almost every app hits both rendering paths, "always give it an `id`" is still the right habit — just for
a different reason than usually stated.

**What actually differs:** under replace, a permanent element missing an `id` is silently dropped. Under
morph, it is kept regardless — the `id` there is only used to avoid inserting a *second* copy when the
incoming HTML also contains one.

*research/notes/README.md corrections log, research/notes/14-morphing-dossier.md — "Morph + data-turbo-permanent"*

---

### "Morphing preserves client-side state"

**Reality.** Morphing preserves **DOM** state — scroll, focus, media playback, CSS transitions. It
**clobbers declarative attribute state**, which is exactly where Stimulus values live. `morphAttributes`
removes every attribute on the live element that's absent from the server's HTML and overwrites every
one that differs — including runtime `data-*-value` attributes your controller set. `connect()` also
never re-runs, because the element was never disconnected.

**Do this instead.** Have the server render the current value and drive re-initialization off
`[name]ValueChanged`, not `connect()`:

```js
static values = { renderedAt: String }
renderedAtValueChanged() { this.teardown(); this.build() }
```

See `docs/recipes/diagnosis.md` → "my JS library breaks after a form error" for the full decision guide.

*research/notes/README.md corrections log, research/notes/14-morphing-dossier.md — "The Stimulus values conflict", turbo#1210 (open 2.5 years)*

---

### "Morphing kicks in on any same-page update"

**Reality.** Turbo detects a "page refresh" by comparing **pathname only**, plus `action === "replace"`.
The **query string is ignored** in both directions: `/posts?filter=open` → `/posts?filter=archived` *will*
morph even though the content is unrelated (Turbo's own test suite asserts this), and a genuinely
different path *never* morphs no matter how you ask. There is no override — [`turbo#1145`](https://github.com/hotwired/turbo/pull/1145)
(`data-turbo-replace-method="morph"`) was proposed and rejected.

**Practical effect:** filtered and paginated pages on the same path silently morph across semantically
unrelated content, and a redirect to a *different* path silently never morphs no matter what meta tag you
set.

**Do this instead.** Structure success flows to redirect back to the same path
(`redirect_back_or_to`) when you want a morph, and reach for `turbo_stream.replace(target, method:
:morph)` — a targeted morph — when you want morph semantics on a region you navigate to.

*research/notes/README.md corrections log, research/notes/02-turbo-deep-dive.md gotcha #10, research/notes/14-morphing-dossier.md Rule 2*

---

### "Add a dummy query param to the redirect to force a fresh reconnect"

**Reality.** This does not work, and hasn't since `turbo#1079` (merged 2023-12-07). `isPageRefresh`
compares `pathname` only — a query param change is invisible to the morph predicate. This workaround
still circulates in issue threads written *after* the fix landed.

**Do this instead.** To force a `replace` instead of a `morph`, change the actual path, or set
`<meta name="turbo-refresh-method" content="replace">` on the page you're leaving.

*research/notes/14-morphing-dossier.md W10*

---

### "`data-turbo-cache="false"` opts an element out of the snapshot cache"

**Reality.** This attribute was **removed** in Turbo 8.0.21 ([`#1471`](https://github.com/hotwired/turbo/pull/1471))
— deprecated, not merely discouraged. It also never meant "re-render fresh"; per seanpdoyle it instructed
the cache to ignore the element entirely, which is exactly what its replacement does more clearly.

**Do this instead.**

```html
<div data-turbo-temporary>…</div>
```

*research/notes/README.md corrections log, research/notes/07-problem-mining.md — version facts*

---

### "`Turbo.clearCache()` clears the snapshot cache"

**Reality.** Removed on Turbo `main` ([`#1470`](https://github.com/hotwired/turbo/pull/1470), Nov 2025),
deprecated since 7.2.0. Every snippet online still uses it.

**Do this instead.**

```js
Turbo.cache.clear()
```

*research/notes/README.md corrections log*

---

### "`Turbo.setConfirmMethod(fn)` is how you customize the confirm dialog"

**Reality.** Deprecated in Turbo 8. It still logs a warning and works, which is why it keeps getting
copied.

**Do this instead.**

```js
Turbo.config.forms.confirm = async (message, formElement, submitter) => {
  // return a Promise<boolean> or a boolean
}
```

*research/notes/02-turbo-deep-dive.md §2.11*

---

### "Set `data-turbo-morph="false"` to opt an element out of morphing"

**Reality. This attribute never existed.** The real opt-outs are `data-turbo-permanent` (subtree,
survives Drive too) or canceling `turbo:before-morph-element` for just this morph pass.

**Do this instead.**

```js
addEventListener("turbo:before-morph-element", (e) => {
  if (e.target === this.element) e.preventDefault()
})
```

*Sharpened from research/notes/14-morphing-dossier.md W3, W4*

---

### "`<turbo-stream action="morph">` is how you get a morphing stream"

**Reality.** This action briefly existed in a pre-release PR and was restructured away before shipping —
the docs got ahead of the release at the time. It does not exist in Turbo 8.

**Do this instead.** `method="morph"` is a modifier on `replace`/`update`, not a separate action:

```ruby
turbo_stream.replace(dom_id(@board), method: :morph, partial: "boards/board")
```

*research/notes/07-problem-mining.md Q35 (outdated note), research/notes/14-morphing-dossier.md — "Morph + Turbo Streams"*

---

### "`<turbo-frame rendering="append">` lets a frame append instead of replace"

**Reality. Does not exist.** `hotwired/turbo` [`#146`](https://github.com/hotwired/turbo/pull/146) was
closed unmerged in 2021.

**Do this instead.** Respond with a Turbo Stream `append` action, or use the lazy-frame infinite-scroll
pattern (each page's response appends the list and renders the next lazy frame).

*research/notes/07-problem-mining.md Q33 (outdated note)*

---

### "Set `data-turbo-preserve-scroll` to keep scroll position across a visit"

**Reality. This attribute does not exist and never has.** [`turbo#37`](https://github.com/hotwired/turbo/issues/37)
has been open since the project's first week. Drive resets scroll on `advance` visits by design.

**Do this instead.** Turbo 8 covers only the same-URL page-refresh case:

```erb
<% turbo_refreshes_with method: :morph, scroll: :preserve %>
```

For everything else, hand-roll `turbo:before-cache` / `turbo:before-render` / `turbo:render` listeners —
see `docs/recipes/diagnosis.md` for the pattern, and don't reach for
`Turbo.navigator.currentVisit.scrolled = true`, which is a private internal.

*research/notes/07-problem-mining.md Q36*

---

### "That accepted Stack Overflow answer's `DOMNodeInserted` listener is the way to detect DOM changes"

**Reality.** `DOMNodeInserted` is a **removed DOM API**. It appears in at least two accepted Stack
Overflow answers for Hotwire questions. Copying it will simply not work in a current browser.

**Do this instead.** Use a `MutationObserver`, or — almost always better — put the behavior in a
Stimulus controller and let `connect()` do the work; it runs whenever the element enters the DOM by any
mechanism.

*research/notes/07-problem-mining.md Q9, Q36 (outdated notes)*

---

### "`stimulus-rails-nested-form` is the nested-forms package to install"

**Reality.** Moved to **`@stimulus-components/rails-nested-form`**. The old package name and its
`.mjs` named-import workaround both predate the move.

*research/notes/07-problem-mining.md Q16, version facts*

---

### "Reset a form after successful submission by handling the submit button's click"

**Reality.** Binding to the submit button's `click` event clears the fields **before** they're
serialized into the request — this creates empty records, not clean ones. One widely-accepted answer
does exactly this.

**Do this instead.**

```js
export default class extends Controller {
  reset(event) { if (event.detail.success) this.element.reset() }
}
```

```erb
<%= form_with model: @message, data: { controller: "reset-form",
      action: "turbo:submit-end->reset-form#reset" } do |f| %>
```

*research/notes/07-problem-mining.md Q38*

---

### "You need a custom Stimulus controller to preload/prefetch links"

**Reality.** Turbo 8 ships hover prefetch ("Instant Click") **on by default** — a 100ms hover delay, a
one-entry LRU cache, 10s TTL. It shipped enabled despite the original PR text describing it as opt-in,
and it issues real GETs, so any link with a side effect behind it will now fire that side effect on
hover.

**Do this instead.** Disable it where a GET isn't safe, and prefer making prefetched GETs idempotent
over disabling it globally:

```erb
<meta name="turbo-prefetch" content="false">
<%= link_to "Home", root_path, data: { turbo_prefetch: false } %>
```

*research/notes/README.md corrections log, research/notes/02-turbo-deep-dive.md §2.12, research/notes/07-problem-mining.md Q48*

---

### "`data-turbo-action="advance"` on a frame is a safe way to sync the URL with frame navigation"

**Reality.** It's real and it works for the simple case, but a Turbo maintainer explicitly does not
recommend it: *"There are a few known bugs with `data-turbo-action="advance"` in frames, I, personally,
don't recommend its use, and we have no plans to work on fixing them either, I say that with all
sincerity here."* Rails-side, frame responses render with an empty-`<head>` layout that breaks snapshot
restoration on refresh unless you override it.

**Do this instead.** If you need URL-syncing navigation, use a Drive visit at the page level. If you use
the frame pattern anyway, override `app/views/layouts/turbo_rails/frame.html.erb` to include tracked
asset tags, and carry the maintainer's warning into your own docs rather than hiding it.

*research/notes/07-problem-mining.md Q27, P4*

---

### "Wrap a `<tbody>` with `is="turbo-frame"` to get frames inside a table"

**Reality. Does not work.** seanpdoyle tested it directly: *"Safari support is incomplete, and declaring
`[is]` does not make an element evaluate `instanceof FrameElement` to `true`."* HTML's table content
model hoists unknown elements out of table internals regardless.

**Do this instead.** Target the row with a Turbo Stream, keyed on a plain `id`:

```erb
<tbody id="companies">
  <tr id="<%= dom_id(company) %>"> … </tr>
</tbody>
```

```ruby
render turbo_stream: turbo_stream.replace(dom_id(@company), partial: "company", locals: { company: @company })
```

*research/notes/07-problem-mining.md Q31, P13*

---

### "dhh said updating multiple stream targets in one response is discouraged"

**Reality. This is a widely repeated misquote.** dhh's actual comment on [`turbo-rails#77`](https://github.com/hotwired/turbo-rails/issues/77)
discourages writing stream actions **inline in the controller**, not answering a request with multiple
targets. His own words, elsewhere in the same thread: *"By all means include multiple commands in your
turbo stream response! It was designed for this."*

**Do this instead.** Render multiple actions from a `.turbo_stream.erb` template freely:

```erb
<%= turbo_stream.replace(:flash, partial: "layouts/flash", locals: { notice: "Posted!" }) %>
<%= turbo_stream.append(:messages, partial: "messages/message", locals: { message: @message }) %>
```

*research/notes/07-problem-mining.md Q28*

---

### "Turbo ships noticeably less JavaScript than a React app"

**Reality.** True only when compared framework-to-framework in isolation, not at the app-bundle level
that actually ships to a browser: measured, Turbo + Stimulus is **60,715 B gzip** against React +
ReactDOM's **45,131 B** — Hotwire is the larger of the two by about 35%.

*research/notes/README.md corrections log*

---

### "There's a `:hotwire_native` request variant / `_status` nav helpers / `<meta name="bridge-components">`"

**Reality.** None of these exist in turbo-rails or Hotwire Native. If you're writing a Hotwire Native
recipe and see one of these in a blog post, it's either aspirational or invented.

*research/notes/README.md corrections log*

---

### "Alpine's `x-transition` needs a full manual port to work with Turbo"

**Reality.** Partial. CSS `@starting-style` + `allow-discrete` covers enter transitions and
stream-inserted content natively, no JS needed. What it does **not** cover is exit-on-remove — that's a
real spec-level limit (`Node.remove()` is synchronous; once it runs there's nothing left to animate),
which is why crosswire's component contract (R6) requires destructive actions to dispatch a cancelable
event with a `complete()` callback first.

*research/notes/README.md corrections log*

---

### "`morphkit` is Marco Roth's morphing library"

**Reality.** No such repository exists — `gh api repos/marcoroth/Morphkit` returns 404, under any
capitalization. What does exist under that owner is
[`marcoroth/turbo-morph`](https://github.com/marcoroth/turbo-morph), a pre-Turbo-8 custom stream action
that predates and is superseded by Turbo's built-in `method: :morph`. Treat it as archived, and treat
"Morphkit" citations as referring to the unrelated Jaksa Malisic React Native library of that name if you
find one.

*research/notes/README.md corrections log, research/notes/14-morphing-dossier.md — "Alternatives and adjacent work"*

---

### "37signals' ONCE-licensed apps are open source, so you can vendor from them"

**Reality.** Mixed. **Campfire and Writebook are MIT** and safe to learn from and vendor patterns out of.
**`basecamp/fizzy` is "O'Saasy"** — source-available with a non-compete clause, not open source. Learn
from it; don't vendor code from it.

*research/notes/README.md corrections log*

---

## A note on what's missing here

One row from the research corpus's own corrections log — a citation to an Evil Martians post dated
2025-04-14 that turned out to be fabricated during research — is a research-integrity note, not developer
advice, so it isn't reproduced above. It's recorded in `research/README.md` if you're auditing the
corpus itself.
