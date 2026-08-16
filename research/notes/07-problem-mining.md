# 07 — Problem Mining: What People Actually Struggle With in Hotwire

**Compiled 2026-08-15.** Versions treated as current throughout: **Turbo 8.0.23, turbo-rails 2.0.23, Stimulus 3.2.2, Rails 8.1.3.**

## Corpus

| Source | Volume mined | Method |
|---|---|---|
| Stack Overflow | 970 questions deduped across `hotwire-rails`, `turbo`, `turbo-frames`, `turbo-rails`, `stimulusjs`, `hotwire`, `stimulus-rails` (756 from 2021+); 238 read in full with top-3 answer bodies | Stack Exchange API |
| discuss.hotwired.dev | 650 topics ranked by views; 90 threads read in full (715+ posts) | Discourse JSON API |
| GitHub | 591 issues/PRs ranked by reactions + comments across `hotwired/turbo`, `hotwired/turbo-rails`, `hotwired/stimulus`; ~115 threads read in full with maintainer comments | `gh api` |
| Hacker News | 119 threads; 14 major threads read in full (~800 substantive comments) | Algolia API |
| discuss.rubyonrails.org | 5 searches, 4 high-value threads read | Discourse JSON API |
| Official docs / source | Turbo handbook + reference, turbo-rails helpers & `Broadcastable`, Rails 8.1 scaffold templates, Rack status symbols | raw.githubusercontent |

**Not reached: Reddit.** `old.reddit.com` and `www.reddit.com` are hard-blocked from this network for plain curl, browser-UA curl, `curl-impersonate` (`curl_chrome145`), and the WebFetch tool; five mirror/proxy services (r.jina.ai, safereddit, redlib.catsarch, redlib.r4fo, red.artemislena) also failed, and WebSearch returned no live reddit.com URLs across ~15 `site:reddit.com` queries. **Zero verified Reddit quotes are in this document.** Reddit sentiment would need a human with a logged-in browser. Also not reached: X/Twitter threads referenced secondhand on HN, and conference-talk transcripts.

---

## Reading the corpus: the single most important finding

The corpus is **not** mostly "how do I build X." It is overwhelmingly **"I built X and nothing happened."** 53 of 756 SO titles use literally that phrasing, and the vast majority of the rest reduce to it. Root causes collapse to five:

1. **ID / frame mismatch** — the response doesn't contain an element with the id being targeted.
2. **Wrong response format** — GET requests don't get Turbo Stream responses without `data-turbo-stream`.
3. **Missing HTTP status code** — a 200 on a non-GET form response is discarded by Turbo.
4. **Stimulus scoping** — values and targets that aren't inside/on the controller element.
5. **A silent JS error or a bad import path** killing every controller on the page at once.

**Design implication for this repo: every recipe should lead with a "how this fails and how to tell" block.** That alone beats 90% of what exists online. A second strongly-indicated artifact: a **Rails 6 → Hotwire idiom translation table** (`link_to method:`, `data-confirm`, `remote: true`, `.js.erb`, 302 redirects), because the Rails core forum's Hotwire traffic is almost entirely "why did my working Rails 6 idiom stop working."

### Frequency table (matching titles out of 756 SO questions; categories overlap)

| Theme | Titles | | Theme | Titles |
|---|---:|---|---|---:|
| Turbo Streams (any mention) | 125 | | Testing (RSpec/Minitest/Capybara) | 15 |
| Turbo Frames (any mention) | 102 | | Production-only breakage | 15 |
| "doesn't work / doesn't update / doesn't render" | 53 | | File upload / Active Storage | 14 |
| Stimulus controller won't connect (broad match) | 83 | | Scroll position | 14 |
| Third-party JS library in Stimulus | 50 | | Modals | 12 |
| Turbo events (which fires when?) | 45 | | Search / filter / autocomplete | 12 |
| Dropdowns / selects (incl. dependent) | 37 | | Tables / `<tr>` with frames | 12 |
| HTTP status / format negotiation | 31 | | "Content Missing" (exact error string) | 11 |
| Stimulus values | 29 | | Devise + Turbo | 9 |
| Stimulus targets | 28 | | Nested forms | 9 |
| Importmap / module resolution | 31 | | Confirm dialogs | 8 |
| Broadcasting | 21 | | Pagination / infinite scroll | 7 |
| GET vs turbo_stream negotiation | 19 | | Legacy `.js.erb` / UJS migration | 7 |
| `link_to`/`button_to` behavior changes | 18 | | `target: "_top"` / frame breakout | 7 |
| Back button / history / `advance` | 17 | | Flash messages | 5 |
| Caching / permanent / morph / refresh | 16 | | **Turborepo/Next.js tag collision (NOISE)** | ~18 |

### Version facts that invalidate large swathes of existing online answers

- **`status: :unprocessable_entity` → `status: :unprocessable_content`.** Rack 3.1 renamed the 422 symbol; Rails 8.1 scaffolds emit `:unprocessable_content` (verified in `railties/.../scaffold_controller/templates/controller.rb.tt`). The old symbol still resolves but is deprecated.
- **Rails 8.1 scaffolds emit `status: :see_other`** on redirects after `update` and `destroy`. Most tutorials predate this.
- **`Turbo.clearCache()` and `data-turbo-cache="false"` are deprecated and have been REMOVED on Turbo `main`** (PRs #1470/#1471, Nov 2025 — deprecated since v7.2.0/v7.3.0). Use `Turbo.cache.clear()` and `data-turbo-temporary`. Every snippet online still uses the removed forms.
- **Rails 8 ships Solid Cable** — "run `rails turbo:install:redis`" is no longer the universal broadcast fix.
- **Devise ≥ 4.9 (2023) is Turbo-native.** Every `TurboFailureApp` / forked-branch / `data-turbo: false` workaround online is obsolete.
- **`stimulus-rails-nested-form` → `@stimulus-components/rails-nested-form`.**
- **Turbo 8 ships Idiomorph internally** — hand-rolled `morphdom` custom stream actions are unnecessary, and "switch to React, Turbo has no virtual DOM" is now wrong.
- **`DOMNodeInserted`** appears in at least two *accepted* SO answers. It is a removed DOM API. Never reproduce it.

### Three claims widely repeated online that are FALSE

1. **`redirect_to path, turbo_frame: "_top"` does not exist.** It is `hotwired/turbo-rails` PR **#367, still OPEN since 2022-07-31** (last touched 2025-05-25, 49 comments, the single most-reacted open feature request). Verified against turbo-rails `main`: there is no `turbo_frame:` option on `redirect_to` anywhere in the gem. Several blog posts and forum answers present it as shipped. It is not.
2. **`<turbo-frame rendering="append">` does not exist.** `hotwired/turbo` PR #146 was closed unmerged in 2021.
3. **`data-turbo-preserve-scroll` does not exist** and never has.

---

## The 60 most-asked questions

Ranked by a blend of frequency (variant count across sources) and view count. Each answer is re-derived for 2026, not copied from the accepted answer.

---

### 1. "My Stimulus controllers don't connect at all — no errors, nothing in the console"
**Frequency: the largest single cluster in the corpus.** 83 matching SO titles, ~15 clearly distinct questions, ~35k views.

Run this checklist in order — it is ordered by how often each item is the actual cause:

1. **Any unrelated JS error earlier on the page stops every controller.** Check the console first. This was the real cause in a large share of these questions.
2. `import { Controller } from "@hotwired/stimulus"` — **not** `"stimulus"`. The bare `stimulus` specifier hasn't existed since Stimulus 3.0.
3. File `foo_bar_controller.js` ↔ attribute `data-controller="foo-bar"`. Subfolders use `--`: `controllers/admin/foo_controller.js` → `admin--foo`.
4. Sprockets apps need `//= link_tree ../../javascript .js` in `app/assets/config/manifest.js`. Propshaft/Rails 8 apps have no `manifest.js` — skip this.
5. esbuild/webpack: run `bin/rails stimulus:manifest:update`. Importmap apps autoload via `eagerLoadControllersFrom`.
6. Turn on the logger:
```js
// app/javascript/controllers/application.js
application.debug = true   // logs every connect/disconnect/action
```

**Sources:** [73902158](https://stackoverflow.com/questions/73902158) · [77158296](https://stackoverflow.com/questions/77158296) · [73861471](https://stackoverflow.com/questions/73861471)

`OUTDATED:` Answers recommending `config.assets.digest = false` in development are actively harmful — the real Sprockets 4.1.1 bug was the opposite (`stimulus-loading.js` was skipped because the hyphen looked like a digest; fixed by `digest = true`). `@hotwired/stimulus-webpack-helpers` and `require.context` answers apply only to retired Webpacker.

---

### 2. "I get `Content Missing` — 'The response (200) did not contain the expected `<turbo-frame id="…">`'"
**Frequency: the most-repeated single error string.** ~12 SO variants, ~28k views, plus dominating the forum's frame threads.

Turbo replaces a frame only if the response contains a frame with the **same id**. A redirect to a page without that frame produces this. Three fixes in order of preference:

```erb
<%# 1. Wrap the redirect target in the same frame, OR %>
<%# 2. Declare the breakout on the frame or the link %>
<%= turbo_frame_tag "task", target: "_top" do %>…<% end %>
<%= link_to "New", new_task_path, data: { turbo_frame: "_top" } %>
```
```js
// 3. Handle it globally (Turbo 7.3+)
addEventListener("turbo:frame-missing", (event) => {
  const { detail: { response, visit } } = event
  event.preventDefault()
  visit(response, { action: "replace" })   // "replace" drops the dead page from history
})
```
**Debug tip that resolves most reports:** the response is usually fine. Frame requests render with the `layouts/turbo_rails/frame` layout; a `layout "application"` override produces **two frames with the same id**, and only the first (often empty) one is used.

You can also *force* a miss from the server by rendering `<turbo-frame id="x" disabled>` — a `[disabled]` frame is treated as missing.

**Sources:** [SO 75738570](https://stackoverflow.com/questions/75738570) · [SO 78487652](https://stackoverflow.com/questions/78487652) · [turbo#445 (merged)](https://github.com/hotwired/turbo/pull/445)

`OUTDATED:` Answers from 2021–2022 describe the *old* behavior where a missing frame caused an automatic full-page visit. That was reverted in Turbo 7.3 / turbo-rails 1.4 — which is exactly why "Content Missing" reports exploded after upgrading from turbo-rails 1.3.x. Any answer saying "Turbo will just redirect for you" is wrong now.

> seanpdoyle on why it isn't automatic: *"transforming a failed Frame request for a portion of the page into a page-wide error undercuts the value proposition of Frames… 500'ing the entire page because a lazily loaded menu's contents failed to load feels like an overreaction."* — [turbo#445](https://github.com/hotwired/turbo/pull/445)

---

### 3. "My form submits, the server logs a 302/200, but the browser just sits there" / `Error: Form responses must redirect to another location`
**Frequency: ~6 SO variants (~15k views) + [turbo-rails#122](https://github.com/hotwired/turbo-rails/issues/122), 76 comments, still open — the canonical 'Turbo broke my forms' thread.**

Turbo requires a non-GET form response to be **either a redirect, or 4xx/5xx, or a Turbo Stream**. A `200 OK` HTML body is discarded.

```ruby
def create
  @post = Post.new(post_params)
  if @post.save
    redirect_to @post, notice: "Created", status: :see_other      # 303, NOT 302
  else
    render :new, status: :unprocessable_content                    # 422 — required
  end
end
```

Sub-cases that trip people:
- The 422 body must be a **complete document**. Rendering a bare partial or a `layout false` controller means Turbo can't replace `<body>` and falls back to a GET of the original URL — you'll see `422` immediately followed by `200 GET` in the log.
- The template must be `new.html.erb`, not `new.slim`/`new.haml` without the `.html` segment.
- If rails-ujs is still loaded and `form_with_generates_remote_forms = true`, the form gets `[data-remote="true"]` and **UJS intercepts before Turbo**.

**Sources:** [SO 68824400](https://stackoverflow.com/questions/68824400) · [SO 72648355](https://stackoverflow.com/questions/72648355) · [turbo-rails#12](https://github.com/hotwired/turbo-rails/issues/12) · [turbo-rails#122](https://github.com/hotwired/turbo-rails/issues/122)

> dhh: *"Yeah, Turbo currently requires a redirect. Not compatible with responding with HTML to a POST for error handling."* … later: *"Fixed in 0.5.3. Render your form error response with unprocessable entity (422) and Turbo will display it."*

`OUTDATED:` `local: true` on `form_with` (a top answer) disables the feature rather than fixing it — and `form_with` hasn't defaulted to `remote: true` since Rails 6.1.

---

### 4. "A form in a modal/frame should redirect the whole page on success, but show errors inside the frame on failure"
**Frequency: ~7 SO variants (~40k views), the largest forum thread family (13k + 14.8k + 12.6k views), [turbo#138](https://github.com/hotwired/turbo/issues/138) with 99 comments, and the single clearest "Hotwire is convoluted" complaint on the Rails core forum.**

**This is the canonical Hotwire struggle.** The asker on discuss.rubyonrails.org stated it perfectly: list of items → click edit → modal form opens → save → (a) invalid: errors render inside the modal, modal stays open; (b) valid: modal closes **and** the row in the list updates.

The frame-only mental model cannot express (b), because one response must touch two regions. **The rule nobody writes down: frames get you there, streams finish the job.**

```erb
<%# The frame declares the breakout; the failure path answers with a stream %>
<%= turbo_frame_tag "modal" do %>
  <%= form_with model: @item, data: { turbo_frame: "_top" } do |f| %>…<% end %>
<% end %>
```
```ruby
def update
  if @item.update(item_params)
    redirect_to items_path, status: :see_other        # escapes the frame via _top
  else
    render :edit, status: :unprocessable_content      # renders edit.turbo_stream.erb
  end
end
```
```erb
<%# app/views/items/edit.turbo_stream.erb — failure path, stays in the modal %>
<%= turbo_stream.replace("modal", partial: "form", locals: { item: @item }) %>
```
Success path when you want the row updated *and* the modal closed without leaving the page:
```ruby
render turbo_stream: [
  turbo_stream.replace(@item),                    # update the row
  turbo_stream.update("modal", "")                # empty the modal frame = closed
]
```

**Sources:** [turbo#138](https://github.com/hotwired/turbo/issues/138) · [SO 75701014](https://stackoverflow.com/questions/75701014) · [forum 1562](https://discuss.hotwired.dev/t/break-out-of-a-frame-during-form-redirect/1562) · [Rails forum 83042](https://discuss.rubyonrails.org/t/i-find-it-difficult-to-use-turbo-frames-building-a-simple-modal-to-edit-items/83042)

> inopinatus (43 reactions), on the `_top` + `.turbo_stream.erb` pattern: *"I don't think this is a hack, frankly, I think this is system-working-as-designed."*
> chris31: *"This is a big missing point in docs… I spent endless time trying to understand this."*

`OUTDATED / FALSE:` **`redirect_to path, turbo_frame: "_top"` does not exist.** [turbo-rails#367](https://github.com/hotwired/turbo-rails/pull/367) is still open. Sources presenting it as shipped are wrong — verified against turbo-rails 2.0.23 source. See pain point P2 for what to do instead.

---

### 5. "How do I submit a form automatically when an input/select changes?"
**Frequency: the highest-traffic single question in the corpus.** ~6 SO variants (~40k views) + the #1 most-viewed forum thread (42k views).

`HTMLFormElement.submit()` does **not** fire a `submit` event, so Turbo never sees it. Use `requestSubmit()`.

```js
// app/javascript/controllers/autosubmit_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }
  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }
  disconnect() { clearTimeout(this.timeout) }
}
```
```erb
<%= form_with url: search_path, method: :get,
      data: { controller: "autosubmit", action: "input->autosubmit#submit change->autosubmit#submit",
              turbo_frame: "results" } do |f| %>
  <%= f.search_field :q %>
<% end %>
<%= turbo_frame_tag "results" do %><%= render @results %><% end %>
```

**Sources:** [SO 68624668](https://stackoverflow.com/questions/68624668) · [forum 1622](https://discuss.hotwired.dev/t/triggering-turbo-frame-with-js/1622)

`OUTDATED:` The `this.form.requestSubmit ? … : this.form.submit()` feature check is dead weight in 2026. Answers reaching for `Rails.ajax`/`@rails/ujs` are dead (removed in Rails 8). Answers advising `format: :turbo_stream` in the URL are actively wrong for GET forms — see Q10.

---

### 6. "Why is `link_to ..., method: :delete` sending a GET in Rails 7+?"
**Frequency:** ~6 SO variants, ~18k views, plus the top Rails-forum Hotwire thread.

`method:` was a rails-ujs feature and is dead. Prefer `button_to` — it emits a real form and is the accessible choice.

```erb
<%= button_to "Delete", post, method: :delete, data: { turbo_confirm: "Sure?" } %>
<%# only if you truly need an <a>: %>
<%= link_to "Delete", post, data: { turbo_method: :delete, turbo_confirm: "Sure?" } %>
```
Server side, **always** `status: :see_other` (303) after DELETE/PATCH. See Q7 for why.

> Community rule of thumb from the issue tracker: *"avoid using `link_to` for anything other than GET requests; use `button_to` for post requests."*

**Sources:** [SO 70498371](https://stackoverflow.com/questions/70498371) · [turbo-rails#259](https://github.com/hotwired/turbo-rails/issues/259)

`OUTDATED:` "Pin `@rails/ujs` and call `Rails.start()`" is a legacy-app bridge only — `@rails/ujs` is removed in Rails 8.

---

### 7. "Why does Turbo break all my 302 redirects? I get `No route matches [DELETE] "/"`"
**Frequency:** high on the Rails core forum; the root cause behind a large share of Q3/Q6 reports.

Turbo submits via `fetch`, and **the Fetch spec preserves the request method across a 301/302/307 for non-GET requests**. So a 302 after a DELETE re-issues a DELETE against the redirect target. **303 See Other is the only status that tells fetch to switch to GET.** This is standards-conformant, not a Turbo bug.

```ruby
redirect_to root_path, status: :see_other
```
App-wide safety net if you're migrating a large legacy codebase:
```ruby
module Turbo::SafeRedirection
  extend ActiveSupport::Concern
  def redirect_to(url = {}, options = {})
    result = super
    if !request.get? && options[:turbo] != false && request.accepts.include?(Mime[:turbo_stream])
      self.status = 303
    end
    result
  end
end
```

**Sources:** [Rails forum 79810](https://discuss.rubyonrails.org/t/why-turbo-breaks-all-302-redirects/79810) · [turbo-rails#259](https://github.com/hotwired/turbo-rails/issues/259) · turbo-rails `UPGRADING.md`

---

### 8. "`data-confirm` stopped working — how do I get a confirm dialog?"
**Frequency:** ~7 SO variants + 2 forum threads, ~24k views.

The attribute is `data-turbo-confirm`, and on `button_to` it must go on the **form**, not the button.

```erb
<%= button_to "Delete", post, method: :delete, form: { data: { turbo_confirm: "Are you sure?" } } %>
<%= link_to "Delete", post, data: { turbo_method: :delete, turbo_confirm: "Are you sure?" } %>
```
For a real dialog instead of `window.confirm`, override once (Turbo 7.2+):
```js
Turbo.setConfirmMethod((message, element, submitter) => {
  const dialog = document.getElementById("turbo-confirm")
  dialog.querySelector("p").textContent = message
  dialog.showModal()
  return new Promise((resolve) =>
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "confirm"), { once: true }))
})
```
The `<dialog id="turbo-confirm">` must live in `application.html.erb` **outside any frame**, with a `<form method="dialog">` whose buttons carry `value="confirm"` / `value="cancel"`.

**Critical gotcha:** `data-turbo-confirm` on a plain `<a href>` with **no** `data-turbo-method` is a **no-op**.
> dhh: *"Don't think this makes sense on regular links, but on `data-turbo-method` links yes."* — [turbo#379](https://github.com/hotwired/turbo/pull/379)

**Sources:** [SO 70994322](https://stackoverflow.com/questions/70994322) · [turbo#525](https://github.com/hotwired/turbo/pull/525)

`OUTDATED:` The Stimulus `confirmation_controller.js` workaround (top-voted in 2022) is obsolete. Two-arg `setConfirmMethod` examples still work but lose the `submitter`.

---

### 9. "How do I run JavaScript when a turbo frame or stream finishes rendering? `turbo:load` never fires"
**Frequency: second-biggest cluster.** ~8 SO variants (~30k views) + a 16k-view/30-post forum thread.

`turbo:load` fires **only on full page visits** — not on frame navigations, not on stream renders. **Don't chase events.** Put the behavior in a Stimulus controller that lives inside the replaced HTML, so `connect()` runs every time the content arrives:

```js
export default class extends Controller {
  connect()    { this.chart = new Chart(this.element, this.dataValue) }
  disconnect() { this.chart?.destroy() }
}
```
If you genuinely need the event, the frame ones are `turbo:frame-load` / `turbo:before-frame-render` / `turbo:frame-render`, and they fire **on the frame element**:
```erb
<%= turbo_frame_tag "chart", data: { action: "turbo:frame-load->logger#log" } %>
```
For streams there is only `turbo:before-stream-render` — **there is deliberately no `turbo:after-stream-render` and there never will be.**

> sstephenson: *"There's no built-in event for notification after a Turbo Streams render… The specific reason is to encourage you to design your application not to care about where new HTML comes from or how it gets into the document."* — [forum 1554](https://discuss.hotwired.dev/t/event-to-know-a-turbo-stream-has-been-rendered/1554)

If you must, chain the render function:
```js
addEventListener("turbo:before-stream-render", (event) => {
  const original = event.detail.render
  event.detail.render = async (el) => { await original(el); afterRender(el) }
})
```

**Sources:** [SO 67315225](https://stackoverflow.com/questions/67315225) · [forum 1554](https://discuss.hotwired.dev/t/event-to-know-a-turbo-stream-has-been-rendered/1554) · [turbo#1289](https://github.com/hotwired/turbo/issues/1289)

`OUTDATED:` `turbo:before-fetch-response` + `frame.loaded.then(...)` predates `turbo:frame-load`. One accepted answer uses **`DOMNodeInserted`, a removed DOM API** — never reproduce it; use `MutationObserver` or Stimulus target callbacks.

---

### 10. "My GET link/form is processed as HTML, not TURBO_STREAM (`UnknownFormat` / 406)"
**Frequency:** ~9 SO variants, ~30k views.

Turbo adds `text/vnd.turbo-stream.html` to `Accept` **only for non-GET submissions**. For GET you must opt in:

```erb
<%= link_to "Edit", edit_translation_path(t), data: { turbo_stream: true } %>
<%= form_with url: search_path, method: :get, data: { turbo_stream: true } do |f| %>
<%= turbo_frame_tag "menu", src: menu_path, data: { turbo_stream: true } %>
```
Then `respond_to { |f| f.turbo_stream }`. Verify with `request.headers["Accept"]` in the action.

Note the URL is deliberately **not** advanced for a stream response.
> kevinmcconnell: *"a Turbo Stream response could be making any sort of change to the page, so we don't really know whether it represents a navigation or not."* — [turbo#612](https://github.com/hotwired/turbo/pull/612)

**Sources:** [SO 77429759](https://stackoverflow.com/questions/77429759) · [turbo#612 (merged, 7.2)](https://github.com/hotwired/turbo/pull/612)

`OUTDATED:` **`format: :turbo_stream` in the URL/path helper is wrong and actively harmful** — Turbo refuses to handle links with a non-html extension, so you get a raw text page (this is Q11). It was widely upvoted in 2021–2022. `defaults: { format: :turbo_stream }` in routes also breaks HTML fallback. Answers saying "GET streams aren't supported" are stale (shipped Turbo 7.2 / turbo-rails 1.3).

---

### 11. "My turbo_stream response renders as plain text in the browser"
**Frequency:** ~4 SO variants, ~13k views.

Same root cause as Q10 inverted: the URL carries `.turbo_stream`, so Turbo declines the click, the browser navigates directly, and `Content-Type: text/vnd.turbo-stream.html` renders as text.

```erb
<%# WRONG %> <%= button_to "Refresh", refresh_task_path(task, format: :turbo_stream) %>
<%# RIGHT %> <%= button_to "Refresh", refresh_task_path(task) %>
```
If it's a GET, add `data: { turbo_stream: true }` instead.

Related: if Turbo **appends the whole response to the bottom of the page**, you have a template named `show.erb` instead of `show.html.erb` — Rails serves it for the `turbo_stream` format and Turbo tries to parse a full HTML page as stream elements.

**Sources:** [SO 73067985](https://stackoverflow.com/questions/73067985) · [SO 74849934](https://stackoverflow.com/questions/74849934)

---

### 12. "My turbo_stream works the first time but not the second" / "`replace` deleted my turbo-frame"
**Frequency:** ~4 SO variants, ~15k views. **Highest-value "aha" in the corpus.**

`turbo_stream.replace` swaps the **entire target element**, including the `<turbo-frame>` wrapper. If the replacement content isn't itself wrapped in the same frame, the target id no longer exists and the second update silently does nothing. `update` replaces only inner HTML.

```erb
<%# keeps <turbo-frame id="default-format"> in the DOM %>
<%= turbo_stream.update "default-format" do %><%= render "form" %><% end %>

<%# replaces it — only correct if the partial re-renders the frame tag itself %>
<%= turbo_stream.replace "default-format", partial: "form" %>
```
**Rule of thumb:** target a plain `<div id="…">` with `update`, or make the partial always render its own `turbo_frame_tag` and use `replace`.

**Sources:** [SO 73294418](https://stackoverflow.com/questions/73294418) · [SO 73130098](https://stackoverflow.com/questions/73130098)

---

### 13. "After `create`, how do I append the new record to the list without leaving the page?"
**Frequency:** ~8 SO variants, ~35k views.

```erb
<%# index.html.erb %>
<div id="deals"><%= render @deals %></div>
<%= turbo_frame_tag "deal_form" do %><%= render "form", deal: Deal.new %><% end %>
```
```ruby
def create
  @deal = Deal.new(deal_params)
  if @deal.save
    render turbo_stream: [
      turbo_stream.prepend("deals", @deal),
      turbo_stream.replace("deal_form", partial: "deals/form", locals: { deal: Deal.new })
    ]
  else
    render turbo_stream: turbo_stream.replace("deal_form", partial: "deals/form",
             locals: { deal: @deal }), status: :unprocessable_content
  end
end
```
**The `_deal.html.erb` partial's root element must carry `id="<%= dom_id(deal) %>"`** — otherwise `prepend`/`replace` have nothing to key on, and `turbo_stream.remove(@deal)` later won't work.

**Sources:** [SO 75751032](https://stackoverflow.com/questions/75751032) · [SO 67347079](https://stackoverflow.com/questions/67347079)

---

### 14. "My `broadcast_*_to` runs (I see it in the log) but the page never updates"
**Frequency:** ~9 SO variants, ~15k views.

In order of likelihood:
1. The receiving page must subscribe: `<%= turbo_stream_from :posts %>`, and the stream key must match the broadcast **exactly**.
2. The **target id must exist** in the DOM (`<div id="posts">`).
3. Action Cable adapter: the `async` adapter only works within one process, so console/Sidekiq broadcasts never reach the browser. Rails 8: Solid Cable. Rails 7: `bin/rails turbo:install:redis` and set `adapter: redis` in development too.
4. Production: check `config.action_cable.allowed_request_origins`.
5. Use the `_later_to` variants so rendering happens in a job.

```erb
<%= turbo_stream_from :posts %>
<div id="posts"><%= render @posts %></div>
```
```ruby
class Post < ApplicationRecord
  after_create_commit -> { broadcast_prepend_later_to :posts, target: "posts" }
end
```

**Sources:** [SO 71141502](https://stackoverflow.com/questions/71141502) · [SO 78773397](https://stackoverflow.com/questions/78773397)

`OUTDATED:` "Run `rails turbo:install:redis`" is no longer universal (Rails 8 ships Solid Cable). The whole per-action `broadcast_append_to`/`broadcast_replace_to` callback trio is largely superseded by `broadcasts_refreshes` + morphing — see Q15/Q40.

---

### 15. "`current_user` blows up inside a broadcast partial (`Devise could not find the Warden::Proxy`)"
**Frequency:** ~5 SO variants + a 15k-view/31-post forum thread.

Broadcasts render outside a request — there is no session.

> dhh: *"Partials used for turbo streaming have to be free of global references, as they're rendered by the ApplicationRenderer, not within the context of a specific request."* — [forum 1752](https://discuss.hotwired.dev/t/authentication-and-devise-with-broadcasts/1752)

Three fixes, best first:
```ruby
# 1. Turbo 8: each client re-fetches the page in its own session, so current_user just works
class Message < ApplicationRecord
  broadcasts_refreshes_to ->(m) { m.room }
end
```
```ruby
# 2. Pass what you need as explicit locals
after_create_commit { broadcast_prepend_to :messages, locals: { current_user: user } }
```
3. Render the privileged UI for everyone and hide with CSS — **only** when the hidden content isn't sensitive.

Related trap: broadcasting a partial containing `form_with`/`button_to`/`rich_text_area` used to raise `Request forgery protection requires a working session store`. Fixed in Rails 7 (`token_tag` now checks `session.enabled?`); on older versions pass `authenticity_token: false`.

**Sources:** [SO 67574341](https://stackoverflow.com/questions/67574341) · [forum 1752](https://discuss.hotwired.dev/t/authentication-and-devise-with-broadcasts/1752) · [turbo-rails#243](https://github.com/hotwired/turbo-rails/issues/243)

---

### 16. "How do I build dynamic nested forms (add/remove `fields_for` rows)?"
**Frequency:** ~9 SO variants, ~25k views.

The Rails-native, zero-JS-templating way is a `<template>` plus a tiny controller:

```erb
<template data-nested-form-target="template">
  <%= form.fields_for :line_items, LineItem.new, child_index: "NEW_RECORD" do |ff| %>
    <%= render "line_item_fields", f: ff %>
  <% end %>
</template>
<div data-nested-form-target="target"></div>
<button type="button" data-action="nested-form#add">Add item</button>
```
```js
add() {
  const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now())
  this.targetTarget.insertAdjacentHTML("beforebegin", html)
}
remove(e) {                                   // soft-delete persisted records
  const row = e.target.closest("[data-nested-form-target='row']")
  row.querySelector("input[name*='_destroy']").value = "1"
  row.hidden = true
}
```
Requires `accepts_nested_attributes_for :line_items, allow_destroy: true` and `line_items_attributes: [:id, :name, :_destroy]` in strong params.

**Sources:** [SO 71713303](https://stackoverflow.com/questions/71713303) · [SO 76679177](https://stackoverflow.com/questions/76679177)

`OUTDATED:` The package moved: `stimulus-rails-nested-form` → **`@stimulus-components/rails-nested-form`**. The `.mjs` named-import workaround is no longer needed.

**Sharp edge:** re-rendering the form partial through `turbo_stream.replace` on validation failure can render nested `fields_for` **twice**. Fix: `render partial: "form", locals: {...}, formats: [:html]` — [turbo-rails#159, open](https://github.com/hotwired/turbo-rails/issues/159).

---

### 17. "How do I reload / re-fetch a specific turbo frame from JavaScript?"
**Frequency:** ~5 SO variants (~24k views) + a 13k-view forum thread.

`<turbo-frame>` exposes `reload()` (Turbo 7.2+). Don't null-and-reset `src`.

```js
export default class extends Controller {
  static targets = ["frame"]
  reload() { this.frameTarget.reload() }
  poll()   { this.timer = setInterval(() => this.frameTarget.reload(), 10_000) }
  disconnect() { clearInterval(this.timer) }
}
```
From the server, the Turbo 8 way is usually better:
```ruby
class Order < ApplicationRecord
  broadcasts_refreshes
end
```
```erb
<%= turbo_stream_from @order %>
<% turbo_refreshes_with method: :morph, scroll: :preserve %>   <%# needs `yield :head` in the layout %>
```

**Sources:** [SO 76096510](https://stackoverflow.com/questions/76096510) · [forum 1872](https://discuss.hotwired.dev/t/how-to-auto-reload-frame/1872)

`OUTDATED:` `removeAttribute("loaded")` and `this.src = null; this.src = src` predate `reload()`. Client polling is superseded by `broadcasts_refreshes` for anything backed by a model change. **Caveat:** `refresh="morph"` on a frame is ignored by `frame.reload()` — that morph path only exists in the page-refresh renderer ([turbo#1161](https://github.com/hotwired/turbo/issues/1161)).

---

### 18. "How do I wire up a third-party JS library (flatpickr / FullCalendar / Leaflet / Tom Select / Chart.js) in Stimulus?"
**Frequency: the largest topic area by title count — 50 SO titles**, ~25 distinct questions, 30k+ views.

One controller, `connect()` to init, `disconnect()` to tear down. **The teardown is what everyone forgets**, and it's why libraries break after Turbo navigations and cached restores.

```js
import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
export default class extends Controller {
  static values = { options: Object }
  connect()    { this.picker = flatpickr(this.element, this.optionsValue) }
  disconnect() { this.picker?.destroy() }
}
```
For libraries emitting non-DOM events (Select2, Tom Select, jQuery plugins), re-emit a native event so `data-action` can see it:
```js
$(this.element).on("select2:select", () =>
  this.element.dispatchEvent(new Event("change", { bubbles: true })))
```
With importmaps, **CSS is a separate concern** — `bin/importmap pin leaflet` does not bring CSS. Add it via the asset pipeline or a `<link>`, never by importing a `.css` from JS (that's the `Expected a JavaScript module but got MIME type "text/css"` error).

Under Turbo 8 morphing, `connect()`/`disconnect()` **do not re-run** — see pain point P5.

**Sources:** [SO 71478969](https://stackoverflow.com/questions/71478969) · [SO 70280216](https://stackoverflow.com/questions/70280216) · [forum 2380](https://discuss.hotwired.dev/t/manually-force-trigger-a-change-event-on-select-in-nested-form-using-stimulusjs/2380)

---

### 19. "My Stimulus `static values` are always empty"
**Frequency:** 29 SO titles, ~6 distinct questions, ~10k views.

Values are read from the **controller element itself**, never from children. The attribute is `data-[identifier]-[name]-value`, kebab-cased.

```erb
<div data-controller="selectable"
     data-selectable-icon-url-value="/x.png"
     data-selectable-count-value="3">
```
```js
static values = { iconUrl: String, count: Number, opts: { type: Object, default: {} } }
connect() { console.log(this.iconUrlValue, this.countValue) }   // "/x.png", 3 (a real Number)
```
`iconUrl` ↔ `icon-url`. Multi-word identifiers dasherize too: `my_thing_controller.js` → `data-my-thing-…-value`. For per-child data use targets + `dataset`, or **Action Params**. Non-round-trippable keys can be declared kebab-case: `static values = { "time-24hr": Boolean }` → `this.time24hrValue`.

**Sources:** [SO 73852562](https://stackoverflow.com/questions/73852562) · [stimulus#62](https://github.com/hotwired/stimulus/issues/62)

---

### 20. "`Missing target element "x" for "y" controller`"
**Frequency:** 28 SO titles, ~7 distinct questions, ~10k views.

Two causes, both structural:
1. The attribute must include the identifier: `data-[identifier]-target="name"`, **not** `data-target="y.name"` (that's Stimulus 1.x syntax).
2. Targets must be **inside the controller element's subtree**.

```erb
<div data-controller="countdown">
  <span data-countdown-target="countdown">8</span>
  <a data-countdown-target="link" href="…">Go</a>
</div>
```
Guard optional targets with `this.hasNameTarget`. For targets that arrive later via Turbo, use `nameTargetConnected(el)` / `nameTargetDisconnected(el)`.

**Sources:** [SO 76084205](https://stackoverflow.com/questions/76084205) · [SO 76279205](https://stackoverflow.com/questions/76279205)

---

### 21. "How do I call a method on / talk to another Stimulus controller?"
**Frequency:** ~6 SO variants (~28k views) + a 10.8k-view forum thread + [stimulus#35](https://github.com/hotwired/stimulus/issues/35) (52 reactions).

**(a) Events** — for loose coupling. `this.dispatch` prefixes with the identifier and bubbles by default:
```js
this.dispatch("append", { detail: { count: 3 } })   // → "infinite-scroll:append"
```
```erb
<div data-controller="gallery" data-action="infinite-scroll:append@window->gallery#relayout">
```
**The `@window` suffix is what most people are missing** when the two controllers aren't ancestor/descendant.

**(b) Outlets** (Stimulus 3.2+) — for direct method calls:
```js
static outlets = ["togglee"]
toggleeOutletConnected(outlet, el) { /* safe here — see below */ }
handleClick() { this.toggleeOutlets.forEach(o => o.toggle()) }
```
```erb
<button data-controller="toggler" data-toggler-togglee-outlet="#filter-form">…</button>
<div id="filter-form" data-controller="togglee">…</div>
```
**Two outlet footguns that cost people hours:**
- The outlet element **must itself carry `data-controller="togglee"`**.
- **Outlet names must exactly equal the controller identifier, kebab-case, with no camelCase conversion.** A `price-input` controller needs `static outlets = ["price-input"]`, not `["priceInput"]`. There is no aliasing. ([stimulus#669](https://github.com/hotwired/stimulus/issues/669), open; chrisdmacrae: *"I lost over 4 hours to this."*)
- **Don't access outlets in `connect()`** — DOM order matters and outlets after the host haven't connected yet. Use `xOutletConnected`.

**Sources:** [SO 71632091](https://stackoverflow.com/questions/71632091) · [forum 35](https://discuss.hotwired.dev/t/relationship-between-controllers/35) · [stimulus#618](https://github.com/hotwired/stimulus/issues/618)

`OUTDATED:` `this.application.getControllerForElementAndIdentifier(...)` and the `this.element[this.identifier] = this` hack are pre-Outlets patterns.
> javan on the latter: *"If you do this, and **I don't recommend that you do**, be very careful with your controller names. If they conflict with any of the element's own property names (there are hundreds!) things will go 💥."*
**`this.xOutlets` returning `undefined` rather than `[]` means Stimulus < 3.2.**

---

### 22. "I need to select one specific element out of `this.fooTargets`"
**Frequency:** ~6 SO variants (~20k views) + a 9.2k-view forum thread.

Usually the real answer is "your controller is scoped too widely" — instantiate one controller per item. When you genuinely need to pick, use **Action Params**, not dataset spelunking:

```erb
<div data-controller="tabs">
  <button data-action="tabs#show" data-tabs-key-param="a">A</button>
  <div data-tabs-target="panel" data-key="a">…</div>
</div>
```
```js
show({ params: { key } }) {
  this.panelTargets.forEach(p => p.hidden = p.dataset.key !== key)
}
```
Inside an action handler, `event.currentTarget` is the element the action is bound to — that's how you identify "the one that fired this," not a named target lookup (`this.xTarget` always returns the *first* match in scope).

**Sources:** [SO 72282150](https://stackoverflow.com/questions/72282150) · [forum 349](https://discuss.hotwired.dev/t/multiple-targets-with-the-same-name/349)

---

### 23. "`event.target` gives me the wrong element"
**Frequency:** 26,930 views on a 3-post forum thread — Stimulus's single most common newbie mistake.

`event.currentTarget` is always the element the listener is attached to. `event.target` is whatever nested element the click actually landed on (e.g. a `<span>` inside your `<a>`).

> sstephenson: *"You probably want to use `event.currentTarget` instead of `event.target`… `event.currentTarget` will be the `<a>` element, since that's where the event handler is installed."* — [forum 134](https://discuss.hotwired.dev/t/cannot-get-attribute-value-using-event-target/134)

---

### 24. "How do I autoload all Stimulus controllers? (importmap vs esbuild vs engines)"
**Frequency:** ~7 SO variants, ~30k views.

```ruby
# config/importmap.rb
pin_all_from "app/javascript/controllers", under: "controllers"
```
```js
// app/javascript/controllers/index.js
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
```
With **esbuild/bun/rollup** there is no autoloading — `@hotwired/stimulus-loading` is not on npm. Regenerate the manifest:
```
bin/rails stimulus:manifest:update
```
For **Rails engines**, pin with an absolute path:
```ruby
pin_all_from MyEngine::Engine.root.join("app/javascript/controllers"), under: "controllers"
```

**Sources:** [SO 71898315](https://stackoverflow.com/questions/71898315) · [SO 78889874](https://stackoverflow.com/questions/78889874)

---

### 25. "`Failed to resolve module specifier` / relative import works in dev, 404s in production"
**Frequency:** ~10 SO variants (~20k views) + a 16k-view forum thread.

Importmaps don't look in `node_modules`; every bare specifier must be pinned. And **never use relative imports across pinned modules** — `import "./helpers/foo"` resolves relative to the *digested* URL of the importing file, producing `/assets/helpers/foo`, which exists in dev (Sprockets serves undigested) but 404s in production.

```ruby
pin_all_from "app/javascript/helpers", under: "helpers"
```
```js
import { debounce } from "helpers/functions"   // NOT "../helpers/functions"
```
```
bin/importmap json    # inspect exactly what the browser will see
```
This is also the cause of `Failed to fetch dynamically imported module: …controllers/home_controller-<digest>.js` in production — and note that **one bad relative import silently breaks `stimulus-loading` for other, unrelated controllers**.

**Sources:** [SO 76116427](https://stackoverflow.com/questions/76116427) · [forum 5121](https://discuss.hotwired.dev/t/failed-to-fetch-dynamically-imported-module/5121)

---

### 26. "How do I get a modal working with turbo frames?"
**Frequency:** ~7 SO variants + multiple forum threads, ~15k views.

Persistent empty frame in the layout + `data-turbo-frame` on the trigger, using native `<dialog>` so you get focus trapping and Esc for free:

```erb
<%# application.html.erb %>
<%= turbo_frame_tag "modal" %>
```
```erb
<%= link_to "New task", new_task_path, data: { turbo_frame: "modal" } %>
```
```erb
<%# tasks/new.html.erb %>
<%= turbo_frame_tag "modal" do %>
  <div data-controller="modal" data-action="turbo:submit-end->modal#closeOnSuccess">
    <dialog data-modal-target="dialog"><%= render "form", task: @task %></dialog>
  </div>
<% end %>
```
```js
connect() { this.dialogTarget.showModal() }
closeOnSuccess(e) { if (e.detail.success) this.dialogTarget.close() }
```
Because the frame is empty in the layout, no modal shows on a direct visit — and closing from the server means `turbo_stream.update("modal", "")`.

**Under Turbo 8 morphing this deadlocks the page** unless you handle `[open]` — see pain point P6.

**Sources:** [SO 73543708](https://stackoverflow.com/questions/73543708) · [forum 2094](https://discuss.hotwired.dev/t/presenting-forms-in-modals-with-turbo/2094)

`OUTDATED:` Bootstrap-modal answers work but carry a JS dependency for something `<dialog>` does natively, and the memoization problem they solve disappears entirely with `<dialog>`.

---

### 27. "How do I make frame navigation update the browser URL / support Back?"
**Frequency:** ~7 SO variants, ~22k views, 17 SO titles.

```erb
<%= turbo_frame_tag "main", data: { turbo_action: "advance" } do %> … <% end %>
```
For `<a>`/`<form>` navigations inside an advancing frame, Turbo sets **both** the frame's `src` and the browser path, **including query params** (verified against the current Turbo handbook). The `turbo:frame-render` + `history.replaceState` shim that circulates online is only needed when **JS sets `frame.src` programmatically**.

**On refresh**, the browser requests the advanced URL as a full page — that action must render the whole layout with the frame in place, not just the frame.

**Read this before you ship it.** A maintainer recommends against the feature on the record:
> brunoprietog: *"Although you can use `data-turbo-action="advance"`, it's not the inherent purpose of a Turbo frame, and in fact, we have never used it internally either. There are a few known bugs with `data-turbo-action="advance"` in frames, I, personally, don't recommend its use, and we have no plans to work on fixing them either, I say that with all sincerity here. If I want to update the URL, I always do it with a Turbo drive visit, not with frames."* — [turbo#600](https://github.com/hotwired/turbo/issues/600)

**Sources:** [SO 77949184](https://stackoverflow.com/questions/77949184) · [turbo#398 (merged)](https://github.com/hotwired/turbo/pull/398) · [turbo#1241 (open regression)](https://github.com/hotwired/turbo/issues/1241)

---

### 28. "How do I update several parts of the page in one response?"
**Frequency:** ~6 SO variants + [turbo#475](https://github.com/hotwired/turbo/issues/475) + [turbo-rails#77](https://github.com/hotwired/turbo-rails/issues/77).

A frame response resolves exactly one matching id; extra frames in the response are ignored. Use Streams.

```erb
<%# app/views/messages/create.turbo_stream.erb — dhh's preferred form %>
<%= turbo_stream.replace(:flash, partial: "layouts/flash", locals: { notice: "Posted!" }) %>
<%= turbo_stream.append(:messages, partial: "messages/message", locals: { message: @message }) %>
<%= turbo_stream.update("item_count", @items.size) %>
```
`update_all` / `remove_all` / `replace_all` target by **CSS selector** rather than id (turbo-rails 1.4+, verified in `TagBuilder`).

> dhh: *"If you want to replace multiple frames, you can also just target `_top` and replace the whole thing via drive. But otherwise there won't be a path to custom replace two frames. When you need that, you gotta go to turbo streams."* — [turbo#56](https://github.com/hotwired/turbo/issues/56)

**Widely misquoted:** dhh's "this is discouraged" comment on [turbo-rails#77](https://github.com/hotwired/turbo-rails/issues/77) refers to writing streams **inline in the controller**, not to updating multiple sections.
> jeanmartin (15 reactions): *"There seems to be quite a bit of confusion across the web linking to his comment here, claiming dhh is discouraging updating multiple sections."*
> dhh himself: *"By all means include multiple commands in your turbo stream response! It was designed for this."*

---

### 29. "How do I run arbitrary JS / scroll / toggle a class from a Turbo Stream?"
**Frequency:** ~8 SO variants, ~16k views. **The single most under-documented, highest-leverage technique in the corpus.**

`Turbo.StreamActions` is exported and extendable. **`this` is the `<turbo-stream>` element, so you must use `function () {}`, not an arrow function.**

```js
// app/javascript/application.js
import { Turbo } from "@hotwired/turbo-rails"
Turbo.StreamActions.redirect = function () { Turbo.visit(this.getAttribute("target")) }
Turbo.StreamActions.scroll_to = function () {
  this.targetElements[0]?.scrollIntoView({ behavior: "smooth", block: "start" })
}
Turbo.StreamActions.toggle_class = function () {
  const name = this.getAttribute("class_name")
  this.targetElements.forEach(el => el.classList.toggle(name))
}
```
```ruby
# generic builder — turbo_stream.action builds any <turbo-stream action="…">
render turbo_stream: turbo_stream.action(:scroll_to, "list")

# or add sugar
module CustomTurboStreamActions
  def scroll_to(target) = action(:scroll_to, target)
  def toggle_class(target, class_name:) = action(:toggle_class, target, class_name:)
end
Turbo::Streams::TagBuilder.prepend(CustomTurboStreamActions)
```
> dhh: *"After letting this marinate for a while, I like the simplicity of exporting the stream actions, and allowing the app to extend as they see fit. We should document it as a sharp knife. But I like sharp knives."* — [turbo#479 (merged)](https://github.com/hotwired/turbo/pull/479)

The `turbo_power` gem ships ~50 of these pre-built (`set_focus`, `dispatch_event`, `redirect_to`, `reset_form`, `set_value`, `scroll_into_view`, `push_state`, `console_log`, …) — a good inventory of what people need but Turbo doesn't ship.

**Sources:** [SO 77928948](https://stackoverflow.com/questions/77928948) · [turbo#479](https://github.com/hotwired/turbo/pull/479)

`OUTDATED:` Monkey-patching `event.detail.render` in `turbo:before-stream-render` (2022-era) is superseded by `Turbo.StreamActions`.

---

### 30. "Devise + Turbo: sign-in hangs, sign-out does nothing, errors don't show"
**Frequency:** ~7 SO variants (~14k views) + a 14.8k-view/30-post forum thread.

Devise ≥ 4.9 supports Turbo natively — configure the responder statuses instead of disabling Turbo.

```ruby
# config/initializers/devise.rb
config.responder.error_status    = :unprocessable_content   # :unprocessable_entity pre-Rails 8
config.responder.redirect_status = :see_other
config.navigational_formats      = ["*/*", :html, :turbo_stream]
```
```erb
<%= button_to "Log out", destroy_user_session_path, method: :delete %>
```

**Sources:** [SO 74613172](https://stackoverflow.com/questions/74613172) · [forum 1606](https://discuss.hotwired.dev/t/forms-without-redirect/1606)

`OUTDATED:` **Everything** in the 2021–2022 answers is obsolete since Devise 4.9.0 (2023): `data-turbo: false` on Devise forms, the forked `error-code-422` branch, and the custom `TurboFailureApp`/`TurboController` from the Devise wiki (still the accepted answer on the 14.8k-view forum thread). Rails 8 also ships `bin/rails generate authentication`, which is Turbo-correct out of the box.

---

### 31. "Turbo frames don't work inside `<table>` / `<tr>`"
**Frequency:** 12 SO titles + a 14.8k-view/20-post forum thread + [turbo#48](https://github.com/hotwired/turbo/issues/48) (53 comments).

HTML's table content model hoists unknown elements out of table internals, so `<turbo-frame>` never ends up where you wrote it.

**Recommended:** target the row with a **stream**, not a frame — streams work on any element with a matching id.
```erb
<tbody id="companies">
  <tr id="<%= dom_id(company) %>"> … </tr>
</tbody>
```
```ruby
render turbo_stream: turbo_stream.replace(dom_id(@company), partial: "company", locals: { company: @company })
```
Other options: `display: contents` on the frame where you *can* legally place it; drop `<table>` for CSS grid. **`<tbody is="turbo-frame">` does not work** — seanpdoyle tested it: *"Safari support is incomplete, and declaring `[is]` does not make an element evaluate `instanceof FrameElement` to `true`."*

> dhh closed the issue with: *"Rails 7 no longer uses tables in the scaffold templates."* On the `is=` mixin PR: *"A bummer we need to address is that Safari does not support customizable built-in elements. And has said they don't want to do so either."* — [turbo#131, open since 2021](https://github.com/hotwired/turbo/pull/131)

---

### 32. "How do I build a debounced live search / filter?"
**Frequency:** ~8 SO variants + a 5.8k-view/16-post forum thread.

```erb
<%= form_with url: posts_path, method: :get, data: { controller: "autosubmit",
      action: "input->autosubmit#submit", turbo_frame: "results" } do |f| %>
  <%= f.search_field :q, value: params[:q], autocomplete: "off" %>
<% end %>
<%= turbo_frame_tag "results" do %><%= render @posts %><% end %>
```
Gotchas from the corpus: the results template must render the **same frame id** or you get "Content Missing"; debounce 300ms or you DoS your own search; the frame's URL must be a real page so a refresh works; and **keep the input OUTSIDE the frame that gets replaced**, or it loses focus on every keystroke.

Turbo 8 alternative that preserves focus and caret: drive it as a morphing page refresh instead of a frame swap.

**Sources:** [SO 76599134](https://stackoverflow.com/questions/76599134) · [forum 2232](https://discuss.hotwired.dev/t/search-as-you-type-with-turbo/2232)

`OUTDATED:` The `MutationObserver` + `history.replaceState` URL-sync hack in the forum thread predates `data-turbo-action="advance"` on frames. `data-turbo-permanent` on the input was tried and rejected — pre-Turbo-8 it clones and re-inserts, so focus is lost anyway.

---

### 33. "How do I do infinite scroll / pagination?"
**Frequency:** ~7 SO variants + several forum threads.

Lazy frame at the bottom of the list, each page rendering the next frame — no scroll listeners:

```erb
<div id="posts"><%= render @posts %></div>
<% if @pagy.next %>
  <%= turbo_frame_tag "page_#{@pagy.next}", loading: :lazy,
        src: posts_path(page: @pagy.next), target: "_top" do %>
    <p>Loading…</p>
  <% end %>
<% end %>
```
The next page's response renders `turbo_stream.append("posts", …)` plus a fresh lazy frame for page+1. With Pagy, use `pagy_countless` to avoid a `COUNT(*)`, and pass `request_path:` so links generated during a `destroy` don't inherit the record URL.

Keep pagination as **GET + frames**. Converting filter forms to POST+turbo_stream breaks the GET pagination links.

**Sources:** [SO 72645610](https://stackoverflow.com/questions/72645610) · [SO 73631863](https://stackoverflow.com/questions/73631863)

`OUTDATED:` Stimulus + `IntersectionObserver` + manual `fetch` (2021–2022) is more code than the lazy-frame chain and duplicates `loading: :lazy`. **`<turbo-frame rendering="append">` does not exist** — PR #146 was closed unmerged.

---

### 34. "How do I build dependent / cascading dropdowns?"
**Frequency:** 37 SO titles mention dropdowns/selects; ~6 distinct cascade questions.

Auto-submit on change into a frame that re-renders the dependent selects server-side — no JSON, no client templating:

```erb
<%= form_with url: new_job_path, method: :get, data: { controller: "autosubmit",
      action: "change->autosubmit#submit" } do |f| %>
  <%= f.select :category_id, Category.roots.pluck(:name, :id), { include_blank: true } %>
  <%= turbo_frame_tag "subcategory" do %>
    <%= f.select :subcategory_id, @category&.children&.pluck(:name, :id) || [],
                 { include_blank: true }, disabled: @category.nil? %>
  <% end %>
<% end %>
```
**The bug everyone hits:** re-render the *parent* select with its selected value too, or the selection visibly resets. Simplest fix is to keep both selects inside one frame and re-render both.

**Sources:** [SO 74360686](https://stackoverflow.com/questions/74360686) · [SO 77951635](https://stackoverflow.com/questions/77951635)

---

### 35. "Turbo Stream updates wipe out my checkbox selection / open dropdown / scroll position"
**Frequency:** ~5 SO variants. Small count, very high value.

This is exactly what Turbo 8 morphing exists for. In order:

```erb
<% turbo_refreshes_with method: :morph, scroll: :preserve %>
<div id="filters" data-turbo-permanent> … </div>
```
1. Page refresh with morph (`broadcasts_refreshes` + `<meta name="turbo-refresh-method" content="morph">`) — diffs the DOM and leaves untouched inputs alone.
2. `data-turbo-permanent` on the element that must survive. **Under morphing it does not need an `id`** (jorgemanrubia, [turbo#1019](https://github.com/hotwired/turbo/pull/1019)); under Drive it does.
3. `turbo_stream.replace(target, method: :morph)` for a morph-scoped single element.

Hook `turbo:before-morph-element` and `preventDefault()` to opt an element out entirely.

**Sources:** [SO 76105105](https://stackoverflow.com/questions/76105105)

`OUTDATED:` The accepted answer hand-rolls a `morphdom` custom stream action. Excellent 2023 work, completely unnecessary in 2026 — Turbo 8 ships Idiomorph. Any answer suggesting "switch to React/Vue because Turbo has no virtual DOM" is now wrong. Note **`<turbo-stream action="morph">` never existed** — the docs got ahead of the release; the shipped API is `method="morph"` on `replace`/`update` ([turbo#1229](https://github.com/hotwired/turbo/issues/1229)).

---

### 36. "How do I preserve scroll position across visits?"
**Frequency:** 14 SO titles + [turbo#37](https://github.com/hotwired/turbo/issues/37) — **open since week 1 of the project**, 61 reactions, 59 comments.

**There is no `data-turbo-preserve-scroll` attribute and never has been.** Drive resets scroll on `advance` visits by design.

Turbo 8 covers the *same-URL page refresh* case only:
```erb
<% turbo_refreshes_with method: :morph, scroll: :preserve %>
```
> seanpdoyle on why `scroll: :preserve` "doesn't work" for ordinary links: *"For scroll preservation to behave like you're describing, the navigation needs to: (1) have a Turbo Action of `replace`, (2) navigate to the current URL."*

For everything else, hand-roll it:
```js
const positions = {}
const save    = () => document.querySelectorAll("[data-preserve-scroll]").forEach(e => positions[e.id] = e.scrollTop)
const restore = (e) => {
  document.querySelectorAll("[data-preserve-scroll]").forEach(el => el.scrollTop = positions[el.id])
  e.detail?.newBody?.querySelectorAll("[data-preserve-scroll]").forEach(el => el.scrollTop = positions[el.id])
}
addEventListener("turbo:before-cache",  save)
addEventListener("turbo:before-render", restore)
addEventListener("turbo:render",        restore)
```
**Avoid** `Turbo.navigator.currentVisit.scrolled = true` — seanpdoyle: *"writing to `Turbo.navigator.currentVisit.scrolled = true` reaches far into internal, private interfaces."*

For scrolling *to* something after a frame loads, Turbo has it built in:
```erb
<%= turbo_frame_tag "chat", autoscroll: true, data: { autoscroll_block: "end", autoscroll_behavior: "smooth" } %>
```
(`autoscroll` is a real `<turbo-frame>` attribute — verified in `frame_element.js`.) With a sticky header, offset with `scroll-padding-block-start` in CSS rather than JS.

**Sources:** [turbo#37](https://github.com/hotwired/turbo/issues/37) · [turbo#1040 (open PR)](https://github.com/hotwired/turbo/pull/1040) · [SO 76484729](https://stackoverflow.com/questions/76484729)

`OUTDATED:` The accepted answer on SO 76484729 uses `DOMNodeInserted`, a removed DOM API.

---

### 37. "The back button shows stale content / a flash of the old page / my filled-in form reappears"
**Frequency:** 17 SO titles on history + several GitHub threads.

Turbo caches a snapshot of every page on the way out and shows it as a **preview** on restoration visits. Two specific bugs: submitting a form clears the cache and then caches the *current* page (with the form you don't want cached); and mutating state via a `GET` link never clears the cache at all.

```html
<meta name="turbo-cache-control" content="no-preview">   <!-- volatile pages -->
<meta name="turbo-cache-control" content="no-cache">     <!-- opt out entirely -->
```
```js
// scrub volatile DOM before it's snapshotted
addEventListener("turbo:before-cache", () => {
  document.querySelectorAll("form").forEach(f => f.reset())
})
```
**Structural fix:** make state-mutating actions non-GET (`button_to` + DELETE), which clears the cache for free.

Turbo caches `<input>`/`<textarea>`/`<select>` values in snapshots deliberately (bfcache mimicry) and excludes password inputs.

**Sources:** [turbo#193](https://github.com/hotwired/turbo/issues/193) · [turbo#894](https://github.com/hotwired/turbo/issues/894)

`OUTDATED — IMPORTANT:` Every snippet online uses **`Turbo.clearCache()`** and **`data-turbo-cache="false"`**. Both are deprecated and have been **removed on Turbo `main`** ([#1470](https://github.com/hotwired/turbo/pull/1470), [#1471](https://github.com/hotwired/turbo/pull/1471), Nov 2025). Use **`Turbo.cache.clear()`** and **`data-turbo-temporary`**. Also note `data-turbo-cache="false"` never meant "re-render fresh" — seanpdoyle: *"It's a directive that instructs the cache to ignore the element entirely, which is why it's removed from the cached contents."*

---

### 38. "How do I clear/reset a form after a successful submission?"
**Frequency:** ~4 SO variants, ~10k views.

```js
export default class extends Controller {
  reset(event) { if (event.detail.success) this.element.reset() }
}
```
```erb
<%= form_with model: @message, data: { controller: "reset-form",
      action: "turbo:submit-end->reset-form#reset" } do |f| %>
```
Server-side alternative that also resets state the client can't know about: `turbo_stream.replace("message_form", partial: "form", locals: { message: Message.new })`.

**Sources:** [SO 71462885](https://stackoverflow.com/questions/71462885)

`OUTDATED:` The accepted answer binds to the submit **button's click**, which clears the fields *before* they're serialized — it literally creates empty records. Never recommend it.

---

### 39. "`flash.now[:alert]` doesn't render after `render :edit`"
**Frequency:** ~4 SO variants + a 19k-view/18-post forum thread.

It's the missing status code, not flash. Turbo discards a 200 non-redirect form response.

```ruby
flash.now[:alert] = "Could not save"
render :edit, status: :unprocessable_content
```
For flashes delivered by streams, render the flash container as part of the stream. To avoid repeating it in every template, exploit ordinary Rails layout resolution — Turbo Streams are their own MIME type (seanpdoyle):
```erb
<%# app/views/layouts/application.turbo_stream.erb %>
<% if notice.present? %>
  <%= turbo_stream.append("flash_messages") { flash_tag notice, type: :notice } %>
<% end %>
<%= yield %>
```
No canonical flash solution ever landed in turbo-rails; it is still per-app as of 2026.

**Sources:** [SO 71981471](https://stackoverflow.com/questions/71981471) · [forum 2345](https://discuss.hotwired.dev/t/flash-messages-with-turbo/2345) · [turbo-rails#25](https://github.com/hotwired/turbo-rails/issues/25)

---

### 40. "How do I broadcast to a specific user / scope / multiple recipients?"
**Frequency:** ~6 SO variants, ~10k views.

```erb
<%= turbo_stream_from current_user, :notifications %>
```
```ruby
after_create_commit -> { broadcast_prepend_later_to(user, :notifications, target: "notifications") }
```
For many recipients, loop explicitly:
```ruby
after_create_commit -> { users.each { |u| broadcast_prepend_later_to(u, :calls, target: "calls") } }
```
Turbo 8 alternative that sidesteps per-recipient partial rendering entirely — and cleanly solves Q15:
```ruby
broadcasts_refreshes_to ->(call) { call.room }   # each client re-fetches & morphs its own page
```
`suppressing_turbo_broadcasts { … }` exists for bulk operations (verified in `Broadcastable`).

**Sources:** [SO 65736489](https://stackoverflow.com/questions/65736489) · [SO 71020508](https://stackoverflow.com/questions/71020508)

---

### 41. "Which do I use — a Frame or a Stream?"
**Frequency:** implicit in most of the corpus; the 5.9k-view forum thread "Finally Understanding `<turbo-stream>`" exists because nobody explains it.

The mechanism, stated plainly: `<turbo-stream>` is a plain custom element. Adding it to the DOM triggers its side effect against its `target`. Turbo's `StreamObserver` watches `fetch` responses for `Content-Type: text/vnd.turbo-stream.html` and injects any root-level `<turbo-stream>` tags found — **completely independent of WebSockets.** Action Cable is just one delivery mechanism; a plain HTTP response works identically.

The contract, from seanpdoyle ([turbo#146](https://github.com/hotwired/turbo/pull/146)):
> *"`turbo-stream` elements… are useful for globally changing parts of the requesting page's DOM, and are **not scoped** by where on the page the request was initiated from… do not need to be served in a valid HTML document response, and **can not** be accessed as their own resource. On the other hand, turbo-frames are explicitly scoped to a part of the page during both the request and response part of their lifecycles. A turbo-frame response **must** contain a `<turbo-frame>` element with an `[id]` that matches the requesting frame, **should** be a fully valid HTML page of its own, and **could** be accessed via its own resource via an HTTP GET request."

**The escalation rule (the thing nobody writes down):** start with a Frame. The moment one response must change **more than one region**, you need Streams. Frames get you there; streams finish the job.

---

### 42. "One delete link, two behaviors: remove the row on index, redirect on show"
**Frequency:** ~5 SO variants, ~13k views.

Turbo sends `Accept: text/vnd.turbo-stream.html, text/html`, so `format.turbo_stream` always wins when present. Disambiguate with a param:

```erb
<%# index — wants a stream %>
<%= button_to "Delete", post, method: :delete, data: { turbo_confirm: "Sure?" } %>
<%# show — wants a redirect %>
<%= button_to "Delete", post_path(post, redirect_to: posts_path), method: :delete %>
```
```ruby
def destroy
  @post.destroy!
  respond_to do |format|
    format.turbo_stream { render turbo_stream: turbo_stream.remove(@post) } unless params[:redirect_to]
    format.html { redirect_to(params[:redirect_to] || posts_path, status: :see_other) }
  end
end
```

**Sources:** [SO 75656122](https://stackoverflow.com/questions/75656122)

`OUTDATED:` `.html` URL-extension tricks and `data-turbo="false"` both work but throw away Turbo Drive on that click.

---

### 43. "How do I test turbo_stream responses, broadcasts, and frames without flaky tests?"
**Frequency:** 15 SO titles + an 11k-view forum thread + a Rails-forum thread.

```ruby
# request spec — assert the media type, not a redirect
get posts_path(format: :turbo_stream)
expect(response.media_type).to eq Mime[:turbo_stream]

# non-GET: format goes OUTSIDE params
post posts_path(format: :turbo_stream), params: { post: attrs }
assert_response :success        # NOT assert_redirected_to
```
```ruby
# broadcast expectation — Turbo signs stream names; match on the GlobalID param
expect { post messages_path, params: … }
  .to broadcast_to(room.to_gid_param).from_channel(Turbo::StreamsChannel)
```
**System tests:** never assert immediately after a click and never `sleep`. Capybara already polls up to `default_max_wait_time`. Assert on the resulting DOM state (`expect(page).to have_css("#results tr", count: 3)`), and gate on a per-response marker class if the content can look identical before and after. If you truly need a generic "Turbo finished" wait, wait on `.turbo-progress-bar` / `turbo-frame[busy]` disappearing.

For Stimulus unit tests there is still **no official harness** as of 3.2.2 — `@hotwired/stimulus` + jsdom under Vitest/Jest is the community standard.

**Sources:** [SO 75108451](https://stackoverflow.com/questions/75108451) · [forum 2269](https://discuss.hotwired.dev/t/capybara-wait-for-ajax-replacement-for-turbo-stream-responses/2269) · [forum 90](https://discuss.hotwired.dev/t/testing-stimulus/90)

---

### 44. "My controller responds `head :no_content` / 204 and nothing happens"
**Frequency:** ~4 SO variants, ~10k views.

`No template found for X#create, rendering head :no_content` means no `create.turbo_stream.erb` existed and no `render turbo_stream:` was called. Add the template or render inline.

Companion gotcha from the same cluster: if Turbo **appends the whole response to the bottom of the page**, you have a template named `show.erb` instead of `show.html.erb`.

**Sources:** [SO 67347079](https://stackoverflow.com/questions/67347079)

---

### 45. "A frame with `src:` is requested as HTML, not turbo_stream"
**Frequency:** ~6 SO variants, ~12k views.

Lazy frames issue a **normal HTML GET**. `turbo_frame_request?` is true but the format is `html` — that is correct and intended. Respond with HTML containing a matching frame.

```erb
<%= turbo_frame_tag "primary_menu", src: primary_menu_path, loading: :lazy %>
```
```erb
<%# app/views/menus/show.html.erb %>
<%= turbo_frame_tag "primary_menu" do %> … <% end %>
```
If it doesn't fire at all, check `javascript_importmap_tags` is present and `@hotwired/turbo-rails` is pinned. If you want a stream, add `data: { turbo_stream: true }`.

> dhh on branching responses by frame: *"I'm fine with having a way to detect turbo frame requests as a conditional, but I think that's as far as it should go. This should be the exception. If you're branching all your responses for frames vs not, something isn't right."* (frame *variants* were rejected)

**Sources:** [SO 67546910](https://stackoverflow.com/questions/67546910) · [turbo-rails#229](https://github.com/hotwired/turbo-rails/issues/229)

---

### 46. "A turbo frame in `application.html.erb` breaks everything"
**Frequency:** ~4 SO variants, ~5k views.

Frame navigations render with `layouts/turbo_rails/frame` (an intentionally minimal layout), so the frame in your application layout isn't in the response — and if you force `layout "application"` you get **two frames with the same id**, only the first (empty) of which is used. Don't wrap `yield` in a frame.

```erb
<div id="sidebar" data-turbo-permanent><%= render "shared/sidebar" %></div>
<main><%= yield %></main>
```
If you must override, keep the frame layout for frame requests:
```ruby
layout -> { turbo_frame_request? ? "turbo_rails/frame" : "admin" }
```
You can also override the gem's layout by creating `app/views/layouts/turbo_rails/frame.html.erb` — which you **need** to do if you use `data-turbo-action="advance"` on frames, because the empty `<head>` breaks snapshot restoration (see P4).

> kevinmcconnell: *"The fact that turbo rails renders with less/no layout is an optimisation… It's not a necessary part of frames working correctly."* — [turbo-rails#428](https://github.com/hotwired/turbo-rails/pull/428)

**Sources:** [SO 75912633](https://stackoverflow.com/questions/75912633)

---

### 47. "What replaced `data-disable-with` for double-submit protection?"
**Frequency:** 2 SO variants, ~10k views, plus a long turbo-rails thread.

Turbo disables the submitter automatically between `turbo:submit-start` and `turbo:submit-end`. To change the label:

```erb
<%= form.submit "Save", data: { turbo_submits_with: "Saving…" } %>
```
Or style the two states with pure CSS:
```css
button          .show-when-disabled { display: none }
button[disabled].show-when-disabled { display: initial }
button          .show-when-enabled  { display: initial }
button[disabled].show-when-enabled  { display: none }
```
Turn off the UJS leftover so the two don't fight:
```ruby
config.action_view.automatically_disable_submit_tag = false
```
**Two caveats:** a form submitted by pressing Enter in an `<input>` has `SubmitEvent.submitter == null`, so there is nothing to disable; and the button is re-enabled *before* the redirect completes, leaving a double-submit window ([turbo#766, open](https://github.com/hotwired/turbo/issues/766)).

**Sources:** [SO 66734020](https://stackoverflow.com/questions/66734020) · [turbo#386 (merged)](https://github.com/hotwired/turbo/pull/386)

---

### 48. "Turbo fires a GET every time I hover a link — how do I stop it?"
**Frequency:** 1 SO question, 53 upvotes — a Turbo 8 upgrade surprise with outsized impact.

Turbo 8 prefetches on hover (Instant Click), and it **shipped enabled by default despite the PR text saying opt-in.**

```erb
<meta name="turbo-prefetch" content="false">                  <%# in <head> %>
<%= link_to "Home", root_path, data: { turbo_prefetch: false } %>
<div data-turbo-prefetch="false"> … </div>
```
**Real fix in most cases:** make prefetched GETs idempotent and cheap. Never put side effects behind a GET link.

Also note prefetched requests aren't cancelled, so clicking several slow links in a row renders all of them out of order ([turbo#1244, open](https://github.com/hotwired/turbo/issues/1244)).

> afcapel on the one-link-deep cache: *"Instead of keeping a cache of all the links we've hovered in the last 10 seconds, we can just keep a reference to a single request… This is still very fast most of the time and avoids stale content problems."*

**Sources:** [SO 78042975](https://stackoverflow.com/questions/78042975) · [turbo#1101](https://github.com/hotwired/turbo/pull/1101)

`OUTDATED:` Any pre-2024 answer saying "Turbo never requests until you click" is wrong for Turbo 8+.

---

### 49. "How do I redirect to an external URL (Stripe Checkout, OAuth) from a Turbo form?"
**Frequency:** recurring; the classic `Access to fetch at 'https://…' has been blocked by CORS policy` report.

Turbo submits via `fetch` and *follows* the redirect; the browser then enforces CORS on the cross-origin target. This is by design and cannot be fixed in Turbo.

```erb
<%# A. simplest: opt the form out of Turbo %>
<%= form_with url: payments_path, method: :post, data: { turbo: false } do |f| %>
```
```js
// B. keep Turbo for the failure case, use a custom stream action for the redirect
Turbo.StreamActions.redirect_to = function () { Turbo.visit(this.getAttribute("url") || "/") }
```

> dhh: *"It's a basic CORS restriction, so I think treating validation errors with JS and then using vanilla forms for the redirect is a good path to suggest."*
> brunoprietog: *"Turbo must be disabled in those forms or links. Closing because there's nothing we can do to handle this."*

**Sources:** [turbo-rails#483](https://github.com/hotwired/turbo-rails/issues/483) · [turbo#401](https://github.com/hotwired/turbo/issues/401)

---

### 50. "`redirect_to path(anchor: 'x')` silently drops the `#anchor`"
**Frequency:** [turbo#211](https://github.com/hotwired/turbo/issues/211), open, 47 reactions.

Per the Fetch spec, intermediate redirect responses are opaque to script, so the fragment never reaches the `pushState` call. 301/302/303 all behave identically. **Never fixed and won't be.**

```ruby
# best: pass it as a query param instead of a fragment
redirect_to your_path(scroll_to: "your-id"), status: :see_other
```
```js
// then scroll on load
addEventListener("turbo:load", () => {
  const id = new URL(location).searchParams.get("scroll_to")
  if (id) document.getElementById(id)?.scrollIntoView()
})
```
> dhh: *"Could also just start by adding the caveat to the docs. Explain why it isn't possible to fix."*

---

### 51. "How do I show a loading indicator while a frame loads? The progress bar never appears"
**Frequency:** [turbo#540](https://github.com/hotwired/turbo/issues/540), open, 27 comments.

Deliberate — frames don't drive the progress bar. Use the frame's own `[busy]` / `[aria-busy]` attribute with **zero JS**:

```css
turbo-frame[busy] .spinner      { display: block }
turbo-frame:not([busy]) .spinner { display: none }
```
(`busy` and `aria-busy` are added automatically by Turbo to `<turbo-frame>` during a navigation or submission, and `aria-busy` to `<html>` and `<form>` during visits/submissions — verified in the attributes reference.)

> dhh: *"We looked at invoking the progress bar for everything, but that didn't seem right. You can have a lot of frames triggering for lazy loading. It would be a very busy progress bar."*

---

### 52. "I can only interact with a turbo-frame once"
**Frequency:** high-value, low-visibility; [turbo#249](https://github.com/hotwired/turbo/issues/249).

After navigating, the frame retains `src="…"`. A subsequent link/form pointing at the *same* URL is a no-op because `src` is unchanged, so no fetch fires.

```js
// turbo_frame_controller.js
resetSrc() { this.element.src = "" }
```
```html
<turbo-frame id="comments" data-controller="turbo-frame"
             data-action="turbo:frame-render->turbo-frame#resetSrc">
```
The same trick powers "refresh a frame without a dedicated route":
```js
element.src = window.location.href; await element.loaded; element.removeAttribute("src")
```

---

### 53. "My lazy frame stops working after the back button"
**Frequency:** [turbo#886](https://github.com/hotwired/turbo/issues/886), **open, confirmed by a maintainer, unfixed.**

`FrameController` guards on `hasBeenLoaded`, which is instance state lost when the frame is restored from the snapshot cache — so a lazy frame never re-enters `loadSourceURL()`.

```js
addEventListener("turbo:load", () => {
  document.querySelectorAll('turbo-frame[loading="lazy"][complete]')
    .forEach(frame => frame.removeAttribute("loading"))
})
```
> kevinmcconnell: *"yes, I can reproduce this. It does look like a bug to me."*

---

### 54. "How do I do Active Storage direct uploads inside a frame, and why is there no upload progress?"
**Frequency:** 14 SO titles on uploads.

**Direct upload inside a frame** was broken (the frame submitted before the upload finished) and is **fixed** — upgrade to Rails ≥ 7.0 and Turbo ≥ 7.1, and import as `import "@rails/activestorage"` (the `ActiveStorage.start()` form is gone).

**Upload progress is structurally impossible** with a plain Turbo form: Turbo submits with `fetch`, which has no upload progress event, and this will not change because Fetch is core to Drive's caching. Use direct uploads (which use XHR and emit `direct-upload:progress`) and submit only the signed ids:

```js
addEventListener("direct-upload:progress", (e) => {
  const { id, progress } = e.detail
  document.getElementById(`direct-upload-progress-${id}`).style.width = `${progress}%`
})
```

**Sources:** [turbo#243 (fixed)](https://github.com/hotwired/turbo/issues/243) · [turbo#652 (by design)](https://github.com/hotwired/turbo/issues/652)

---

### 55. "How do I detect a click outside an element (close a dropdown/modal)?"
**Frequency:** 21k + 20.4k views across two forum threads; also an SO question.

```js
toggle(event) {
  event.preventDefault()
  this.buttonTarget.getAttribute("aria-expanded") === "false" ? this.show() : this.hide(null)
}
hide(event) {
  if (event && (this.popupTarget.contains(event.target) || this.buttonTarget.contains(event.target))) return
  this.buttonTarget.setAttribute("aria-expanded", "false")
}
```
```html
<div data-action="click@window->dropdown#hide touchend@window->dropdown#hide">
```
`stimulus-use`'s `useClickOutside` packages this and dispatches a `click:outside` event. There is still **no native Stimulus `click:outside` action** as of 3.2.2.

**Prefer the HTML-native route where you can:** `<dialog>` + `::backdrop`, or the Popover API — both give you light-dismiss for free.

**Sources:** [forum 1266](https://discuss.hotwired.dev/t/best-practices-for-handling-clicks-outside-element/1266) · [forum 67](https://discuss.hotwired.dev/t/hide-a-popup-on-clicking-outside-the-popup-area/67)

---

### 56. "How do I warn about unsaved changes? `beforeunload` never fires"
**Frequency:** 18.8k views on the forum.

Turbo visits use `fetch`, so `beforeunload` only fires for real tab close / hard reload. For in-app navigation use `turbo:before-visit`:

```js
connect() { this.confirmLeave = this.confirmLeave.bind(this) }
confirmLeave(event) {
  if (this.formChanged && !confirm("Discard changes?")) event.preventDefault()
}
```
```html
<form data-action="turbo:before-visit@window->unsaved#confirmLeave">
```
Keep a real `beforeunload` listener too — it's the only thing that covers tab close.

**Sources:** [forum 3426](https://discuss.hotwired.dev/t/how-to-catch-beforeunload-and-stop-page-to-reload-without-alert/3426)

---

### 57. "`<script>` tags in my frame / stream response don't run"
**Frequency:** recurring; the cause behind many "Chartkick doesn't work in a frame" reports.

HTML5 forbids `<script>` inserted via `innerHTML` from executing. `PageRenderer` explicitly clones-and-reinserts script nodes; the frame and stream renderers originally did not. **Both are fixed now** (frames: [#192](https://github.com/hotwired/turbo/pull/192); streams: [#527](https://github.com/hotwired/turbo/pull/527)) — upgrade.

But prefer a Stimulus controller over inline `<script>` regardless:
```js
// chart_controller.js — the idiomatic replacement for chartkick's inline script
static values = { data: Object }
connect()    { this.chart = new Chart(this.element, this.dataValue) }
disconnect() { this.chart?.destroy() }
```
**Note: under morphing, `<script>` tags are still not re-evaluated** and there is no framework fix — the existing node is patched rather than inserted.

---

### 58. "Turbo won't navigate to URLs containing a dot"
**Frequency:** [turbo#608](https://github.com/hotwired/turbo/issues/608); bites anyone with slugs, version tags, or filenames in paths.

`src/core/url.ts` treats a dotted last path segment as a file extension so Turbo doesn't hijack `.jpg`/`.mp4` links. `/releases/tag/v7.1.0` triggers a full browser load.

**Fix:** add a trailing slash — `resources :users, trailing_slash: true`, or `/users/jason.json/`.

> dhh: *"We're doing this to prevent Turbo from trying to load .jpg and .mp4 etc."* An allow/deny list was floated but *"That is a breaking change, though."*

---

### 59. "Swiping back in iOS Safari kills all my buttons"
**Frequency:** [turbo#637](https://github.com/hotwired/turbo/issues/637), **open since 2022.**

On a stock Rails scaffold, after one iOS Safari swipe-back, any `data-turbo-method` link/button stops working until a hard refresh. It's a long-standing WebKit bfcache/`confirm()` bug. Not reproducible in Firefox iOS.

```js
;(function () {
  const ua = navigator.userAgent
  const isChrome = ua.includes("Chrome/") || ua.includes("CriOS/")
  const isIosSafari = /\((iPad|iPhone|iPod)/.test(ua) && !isChrome && ua.includes("Safari/")
  if (!isIosSafari) return
  let popped = false
  addEventListener("popstate", () => { popped = true })
  document.addEventListener("turbo:before-render", (event) => {
    if (popped && event.detail.newBody.querySelector("[data-turbo-confirm]")) location.reload()
  })
})()
```
> dhh: *"If this issue is still present 5 years later, perhaps we should assume there's no fix coming. Maybe we can bake something like this straight into Turbo? … Gotta deal with reality as it is."* — still not baked in.

---

### 60. "Do Turbo navigations announce themselves to screen readers?"
**Frequency:** [turbo#774](https://github.com/hotwired/turbo/issues/774), open, filed by GitHub's accessibility team.

**No.** No real page load occurs, so browsers never fire the accessibility page-load machinery. Frame navigation gives screen-reader users no feedback at all; Drive is inconsistent (VoiceOver/Safari usually announces, NVDA/Chrome usually doesn't). **Every Turbo app must ship its own `aria-live` polyfill.**

```erb
<body>
  <span class="sr-only" aria-live="assertive"><%= content_for(:page_title) %></span>
  …
</body>
```
Fire it **after** `turbo:before-render` (so a replaced body can't drop it) and clear the text after a few hundred ms so it isn't re-read when the user arrows through the page.

Worth knowing before you treat this as a five-alarm fire — brunoprietog, a blind maintainer:
> *"as a blind user, one of the things I like most about SPAs is that I don't have to hear notices that a page changed… I would not consider these types of errors to be serious accessibility issues."*

He also notes that **morph-based rendering substantially improves focus retention** over `replaceWith`: *"if I am in a navigation bar… when I press enter on one of the links… the focus is not lost and the screen reader immediately says 'current page'."*

---

## Top pain points & sharp edges

The 60 questions above are symptoms. These are the underlying edges, ordered by how much damage they do.

### P1. The form-response contract is invisible until you violate it
**Symptom:** Form submits, server logs success, browser does nothing. Or `Error: Form responses must redirect to another location`.
**Root cause:** Turbo requires non-GET form responses to be a redirect, a 4xx/5xx, or a Turbo Stream. A 200 HTML body is discarded. Compounding: `fetch` preserves the HTTP method across 302, so only **303** downgrades to GET; and the 422 body must be a **complete document**, not a bare partial.
**Fix:** `redirect_to …, status: :see_other` on success; `render …, status: :unprocessable_content` on failure. Rails 8.1 scaffolds do both.
**Status:** By design, permanent. [turbo-rails#122](https://github.com/hotwired/turbo-rails/issues/122) open with 76 comments; [turbo#1297](https://github.com/hotwired/turbo/issues/1297) (render after a *successful* POST) closed without the feature — so confirmation/preview screens that must not be GET-shareable have **no supported path**.

### P2. Breaking out of a frame from the server — the longest-standing unsolved request
**Symptom:** Modal in a frame; on save you want a full-page redirect, on failure the frame re-rendered. The server cannot say "this one goes to `_top`."
**Root cause:** Not laziness — a browser constraint. seanpdoyle: *"A fetch `Response` resulting in a redirect **deliberately prevents** access to the intermediate redirect response with a status in the `300...399` range."* So `Turbo-Frame: _top` on a redirect is unreachable by design.
**Fix (what actually ships):** every production app writes this:
```js
Turbo.StreamActions.redirect = function () { Turbo.visit(this.getAttribute("target")) }
```
```ruby
format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, articles_url) }
```
Or: `target="_top"` on the frame + a `.turbo_stream.erb` for the failure case (inopinatus, 43 reactions). Or: don't use a frame at all — give the `<form>` an id, redirect on success, reply with `turbo_stream.replace(form_id)` on failure (TastyPi, 29 reactions).
**Status: OPEN, 5 years.** [turbo-rails#367](https://github.com/hotwired/turbo-rails/pull/367) (since 2022), [turbo#257](https://github.com/hotwired/turbo/issues/257) (since 2021, 116 reactions), [turbo#210](https://github.com/hotwired/turbo/pull/210). Design deadlock between seanpdoyle (wants a Rails-level convention) and dhh + kevinmcconnell (want it to be Streams' job).
> kevinmcconnell: *"Making Frames any more 'server-directed' would mean more overlap between Frames and Streams, and I think it will start to introduce complexity that we don't need."*
> **Do not write a recipe that claims `redirect_to …, turbo_frame: "_top"` works. It does not exist.**

### P3. "Content missing" is one error with a dozen causes
**Symptom:** Frame goes blank; console logs `The response (200) did not contain the expected <turbo-frame id="…">`.
**Root cause:** Session timeout redirecting to login; CSRF failure; a redirect whose destination lacks the frame; `render :new` without the frame wrapper; a 404/422/500 (a Rails error page has no frame); a `layout "application"` override producing two frames with the same id; or a `<turbo-frame>` hoisted out of a table.
**Fix:** the `turbo:frame-missing` listener (Q2) as a global safety net, plus `<meta name="turbo-visit-control" content="reload">` (or `turbo_page_requires_reload`) on pages like login that should always break out.
**Status:** Working as intended; the automatic-promotion behavior was deliberately reverted in 7.3.

### P4. Frames + history/URL is shipped, broken, and officially unowned
**Symptom:** `data-turbo-action="advance"` changes the URL going forward, but Back changes the URL while the frame keeps the *latest* content. Nested frames don't update the URL at all. Behavior differs between vanilla Turbo and Rails.
**Root cause (Rails-specific):** turbo-rails renders frame responses with the minimal `turbo_rails/frame.html.erb` layout, which has an **empty `<head>`**. Turbo caches the frame's page snapshot from that response; lacking the `data-turbo-track` assets the live page has, the restoration visit mishandles it. Also: a frame whose content is **text-only** (no element nodes) isn't cached at all, because Turbo caches via `cloneNode`.
**Fix:** override `app/views/layouts/turbo_rails/frame.html.erb` to include the tracked asset tags.
**Status: OPEN and disowned.** [turbo#1241](https://github.com/hotwired/turbo/issues/1241) (7→8 regression, 31 comments), [#1300](https://github.com/hotwired/turbo/issues/1300), [#699](https://github.com/hotwired/turbo/issues/699), [#489](https://github.com/hotwired/turbo/issues/489) (closed then regressed). A maintainer says on the record he doesn't recommend the feature and has no plans to fix it (see Q27). **Any recipe using advance-in-a-frame must carry that warning.**

### P5. Morphing is a deliberate boundary, and third-party JS falls off it
**Symptom:** After a morph refresh, TomSelect/Select2/TinyMCE/Chart.js/flatpickr/Popper widgets are gone or reverted, with no lifecycle hook to recover. Anything a library injected as a *sibling* is deleted (it's not in the server HTML); anything it *added to* the element is reverted.
**Root cause:** Idiomorph patches existing nodes in place, so the controller element is never removed/re-added and Stimulus never fires `disconnect()`/`connect()`. **This is intentional and will never change by default.**
> jorgemanrubia: *"We originally considered triggering a stimulus reconnect automatically for all the controllers, but that assumes too much. Often, you want controllers to keep the state they have when a page refresh happens."* And: *"If we introduced some API here, it will be with the opposite semantics: flag controllers to reconnect during morphing."*

**Fix, three levels:**
```html
<!-- 1. re-init on the morph event -->
<select data-controller="tom-select" data-action="turbo:morph@window->tom-select#reconnect">
```
```js
// 2. cancel the morph for this subtree
addEventListener("turbo:before-morph-element", (e) => {
  if (e.target.matches("[data-controller~='tom-select']")) e.preventDefault()
})
```
```html
<!-- 3. blunt: exclude entirely (no [id] required under morph) -->
<div data-turbo-permanent>…</div>
```
**Two traps that bite everyone:**
- `turbo:morph` fires **twice** per refresh once a snapshot exists (cached preview, then server response). Your teardown must be idempotent.
- The widely-circulated `reconnect() { this.disconnect(); this.connect() }` causes **exponential event-listener growth**. Write an explicit `#teardown()`/`#build()` pair instead (see the Recipes list).

**Status:** [turbo#1083](https://github.com/hotwired/turbo/issues/1083) closed won't-fix-in-Turbo; [stimulus#460](https://github.com/hotwired/stimulus/pull/460) (element/target-change callbacks) never merged.

### P6. `<dialog>` + morph deadlocks the page
**Symptom:** A modal opened with `showModal()`; a morph refresh arrives; the dialog disappears but **nothing on the page is clickable.**
**Root cause:** `showModal()` promotes the dialog into the browser's top layer. Idiomorph removes the `open` attribute, but per the HTML spec removing `[open]` does **not** implicitly call `close()`, so the now-empty top layer stays and blocks everything.
**Fix (seanpdoyle's own snippet):**
```js
addEventListener("turbo:before-morph-attribute", (event) => {
  const { target, detail: { attributeName, mutationType } } = event
  if (target instanceof HTMLDialogElement && attributeName === "open" && mutationType === "remove") {
    event.preventDefault()
    target.close()
  }
})
```
**Status:** [turbo#1239, open](https://github.com/hotwired/turbo/issues/1239). Given Q26 recommends `<dialog>` for modals and Q35 recommends morphing, **this collision is on the default happy path** — it belongs in the modal recipe, not a footnote.

### P7. Morphing only fires on a same-URL page refresh
**Symptom:** `<meta name="turbo-refresh-method" content="morph">` set, but `event.detail.renderMethod` still reports `"replace"`. Or `POST /posts` → `redirect_to post_path(@post)` → full replace, scroll and state lost.
**Root cause:** Turbo detects a "page refresh" by comparing **pathname**. Query params no longer defeat it (PR #1079), but a different path does. There is intentionally no way to force a morph on an arbitrary navigation.
**Fix:** structure the flow so success redirects back to the same path (`redirect_back_or_to`).
**Status:** [turbo#1145](https://github.com/hotwired/turbo/pull/1145) (`data-turbo-replace-method="morph"`) **rejected**.
> jorgemanrubia: *"Every new option we add adds complexity… We intentionally left using morphing out of arbitrary navigations… to keep the programming model as simple as possible."*

### P8. `turbo_stream.refresh` is silently ignored by the client that caused it
**Symptom:** Server returns a toast stream *and* `<turbo-stream action="refresh">`; the toast renders, the page never refreshes.
**Root cause:** Refresh streams carry a `request-id`. Turbo dedupes — the client that *originated* the request ignores a refresh bearing its own id, so the submitter doesn't double-render. Form-submission streams inherit the submitting request's id.
**Fix (canonical):** don't use the stream. `redirect_back_or_to` **is** a page refresh; carry the toast in the flash. Escape hatch: `turbo_stream.refresh(request_id: nil)`.
**Status:** [turbo#1173](https://github.com/hotwired/turbo/issues/1173), closed by design.
> brunoprietog: *"If you want to respond with a page refresh, simply redirect to the same page… You don't need to respond with a Turbo stream."*
Unmet objection: a full redirect does not preserve scroll the way a refresh does.

### P9. Scroll position is unsolved for ordinary Drive visits
**Symptom:** Every link click jumps to the top. Kanban columns, chat panes, and sidebars lose their scroll.
**Root cause:** Drive resets scroll on `advance` visits by design. `turbo-refresh-scroll: preserve` only covers same-URL page refreshes.
**Fix:** hand-rolled `turbo:before-cache` / `turbo:before-render` / `turbo:render` listeners (Q36).
**Status: open since week 1 of the project (2020).** [turbo#37](https://github.com/hotwired/turbo/issues/37) (59 comments), [#1040](https://github.com/hotwired/turbo/pull/1040) (seanpdoyle's `turbo-visit-scroll` PR, still open), [#1272](https://github.com/hotwired/turbo/issues/1272) (frame-level).
> mweitzel: *"This issue has been open since the week 1 of the project being open sourced, will it ever be addressed?"*

### P10. `data-turbo-permanent` is not actually permanent
**Symptom:** `<turbo-cable-stream-source>` unsubscribes and resubscribes on every visit; iframes reload; media re-initializes; custom elements re-run `connectedCallback`; event listeners accumulate.
**Root cause:** brunoprietog: *"permanent elements in Turbo are not truly permanent, as they are detached and attached to the dom anyway."* `bardo.js` removes and re-inserts rather than *moving*.
**Also:** permanent elements are **ignored by Turbo Stream actions** entirely ([turbo#623](https://github.com/hotwired/turbo/issues/623)), and **break under CSS View Transitions** because the synchronous transposition is no longer paired with the deferred render ([turbo#1048](https://github.com/hotwired/turbo/issues/1048)).
**Fix:** always mirror `addEventListener` with `removeEventListener` in `disconnect()`, or use `data-action` so Stimulus manages it. For view transitions, use Turbo's built-in `<meta name="view-transition" content="same-origin">` rather than hand-rolling `startViewTransition()`.
**Status:** [turbo-rails#756, open](https://github.com/hotwired/turbo-rails/pull/756). seanpdoyle sees `Element.moveBefore()` + `connectedMoveCallback` as the real fix.

### P11. Stimulus `disconnect()` runs *after* `turbo:before-cache`
**Symptom:** You delete a D3 SVG / third-party widget in `disconnect()` so it isn't cached; the snapshot still contains it, and on Back you get two widgets.
**Root cause:** sstephenson's canonical explanation — Stimulus uses MutationObserver, which queues a microtask, so the actual disconnection happens *during* the `document.body` replacement, **after** Turbo has already cached the old body.
**Fix:** do cache-preparation in a `turbo:before-cache` action, not `disconnect()`. Keep `disconnect()` for real resource cleanup.
```js
connect()  { this.chart = renderChart(this.element) }
teardown() { this.element.replaceChildren() }   // data-action="turbo:before-cache@window->chart#teardown"
disconnect() { this.chart?.destroy() }
```
**Status:** [stimulus#104](https://github.com/hotwired/stimulus/issues/104), closed by design. **This is one of the two most under-documented mechanics in all of Hotwire.**

### P12. A Stimulus controller ON a `<turbo-frame>` never reconnects
**Symptom:** `<turbo-frame id="x" data-controller="thing">`; the frame loads new content; `connect()` never runs again.
**Root cause:** brunoprietog: *"the Turbo frame element is not replaced, only its content is replaced, so Stimulus will not disconnect or connect the controller again if you defined it in the Turbo frame element."*
**Fix:** put the controller on an element **inside** the frame's content, so it ships with each response.
**Status:** [stimulus#700](https://github.com/hotwired/stimulus/issues/700), closed. **The single most common "why doesn't my controller re-run inside a frame" cause** — and the other most under-documented mechanic.

### P13. Frames cannot live inside tables
**Symptom:** The frame renders visually *outside* the table; layout breaks.
**Root cause:** HTML's table content model. The parser hoists the unknown element out. Not fixable in Turbo.
**Fix:** target `<tr id>`/`<tbody id>` with a **stream** instead. `<tbody is="turbo-frame">` does not work (Safari has declined to implement customizable built-ins).
**Status:** [turbo#48](https://github.com/hotwired/turbo/issues/48) closed; [#131](https://github.com/hotwired/turbo/pull/131) open since 2021 with dhh actively wanting it. The blessed workaround **forces you to maintain two rendering paths for the same row.**

### P14. Third-party scripts that inject nodes before `</body>` break on every visit
**Symptom:** `Failed to execute 'postMessage' on 'DOMWindow'` on every navigation with Stripe.js. GA4 makes frame links navigate as full page loads.
**Root cause:** Drive replaces the entire `<body>`, destroying injected iframes. Stripe requires its script on every page for fraud detection, so "disable Turbo here" isn't viable.
**Fix:** carry the iframe forward manually:
```js
const q = 'iframe[src^="https://js.stripe.com"]'
addEventListener("turbo:before-render", (event) => {
  const current = document.querySelector(q)
  const incoming = event.detail.newBody.querySelector(q)
  if (current && !incoming) event.detail.newBody.appendChild(current)
})
```
Monkey-patching `PageRenderer.prototype.assignNewBody` works forward but **breaks the back button**.
**Status:** [turbo#270, open](https://github.com/hotwired/turbo/issues/270); [#627](https://github.com/hotwired/turbo/pull/627) (replace a sub-element instead of `<body>`) closed unmerged, though dhh wanted it.

### P15. Snapshot caching shows you the past
**Symptom:** Back shows pre-mutation content; a filled-in form with validation errors flashes before the fresh one loads; an autoplaying video keeps playing audibly after you navigate away.
**Root cause:** Turbo caches a snapshot on the way out and shows it as a preview on restoration visits. Mutating state via a GET link never clears the cache.
**Fix:** `<meta name="turbo-cache-control" content="no-preview">`; scrub volatile DOM in `turbo:before-cache`; make mutations non-GET so the cache clears for free; pause media in `turbo:before-cache`.
**Status:** Mostly by design. **The API changed:** `Turbo.clearCache()` → `Turbo.cache.clear()`, `data-turbo-cache="false"` → `data-turbo-temporary`; the old forms are removed on `main`.

### P16. Accessibility of navigation has no default
**Symptom:** No announcement, no focus management, no consensus.
**Fix:** ship your own `aria-live` region (Q60). Focus after streams is partly handled — Turbo records the focused element's `[id]` before a stream render and restores it after, and focuses the first `[autofocus]` in an incoming stream **unless** something is already focused. **This requires an `[id]`** — seanpdoyle: *"tracking focus for anonymous elements isn't currently supported."* Turbo now **never** autofocuses during a morphing page refresh, specifically so a broadcast doesn't steal focus from someone typing.
**Status:** [turbo#774, open](https://github.com/hotwired/turbo/issues/774) since 2022. Every Turbo app ships its own polyfill.

### P17. Real-time is not free at scale
**Symptom:** "We added Hotwire to our Rails app — and watched our server bill double."
**Root cause:** Turbo Stream updates accumulate DOM nodes on long-lived pages (dashboards reaching 10,000+ elements and multi-second click lag); and 10k concurrent users means 10k persistent WebSocket connections, with Redis/Action Cable spending ~30% CPU on connection overhead alone.
**Fix:** prefer `broadcasts_refreshes` + morphing over fine-grained per-action broadcasts (fewer, idempotent messages); cap list lengths server-side; don't broadcast to pages nobody is looking at.
**Source:** [dev.to writeup](https://dev.to/alex_aslam/hotwires-dark-side-when-real-time-isnt-worth-it-167a). Author's own conclusion: *"Use Hotwire for enhancements, not as a total SPA replacement."*
**Also underdiscussed:** when a Turbo Stream update fails (500), **the page just doesn't change** — there is no default error state. Silent failure is the default UX.

### P18. Miscellaneous sharp edges worth a paragraph each
- **Submit button re-enables before the redirect lands**, leaving a double-submit window ([turbo#766, open](https://github.com/hotwired/turbo/issues/766)).
- **`turbo:before-cache` fires on the *live* page** when a frame is promoted with `advance`/`replace`, breaking the documented teardown pattern ([turbo#1259, open](https://github.com/hotwired/turbo/issues/1259)).
- **Stimulus `connect()` can't see restored input values** after Back — the properties aren't restored yet ([stimulus#328, open 6 years](https://github.com/hotwired/stimulus/issues/328)).
- **Aborted form submissions throw uncatchable `AbortError`s** into your error reporter when debounced autosave overlaps ([turbo#170, open](https://github.com/hotwired/turbo/issues/170)).
- **`data-turbo-track="reload"` renders the destination twice and eats the flash** ([turbo#114, open](https://github.com/hotwired/turbo/issues/114)).
- **Frame requests hardcode `credentials: "same-origin"`** — cross-subdomain frames get no cookies. Patch via `turbo:before-fetch-request` ([turbo-rails#161, open](https://github.com/hotwired/turbo-rails/issues/161)).
- **The server cannot tell a Turbo Drive request from a normal one.** `Turbolinks-Referrer` was dropped and never replaced; only `Turbo-Frame` exists ([turbo#195, open](https://github.com/hotwired/turbo/issues/195)).
- **`flash` disappears when a frame request races the redirect.** The gem-level fix was merged then **reverted in v2.0.13** for breaking apps. Use `flash.keep` in a `before_action` guarded by `turbo_frame_request?` ([turbo-rails#699](https://github.com/hotwired/turbo-rails/pull/699)).
- **Stimulus controllers double-fire** when the same module is imported by both an eager manifest and an explicit `application.register` ([stimulus#777](https://github.com/hotwired/stimulus/issues/777)).
- **Morphing overwrites what the user is typing.** Idiomorph 0.7.1 (Turbo 8.0.13) added `restoreFocus`, which improves but does not eliminate this ([turbo#1199](https://github.com/hotwired/turbo/issues/1199)).
- **`connect()` runs out of order relative to targets under morphing** — Idiomorph's insertion order has no relationship to Turbo's render phases. Use `xTargetConnected` instead ([turbo#1351](https://github.com/hotwired/turbo/issues/1351)).
- **Lazy-loading Stimulus controllers is effectively deprecated.** dhh: *"I'm actually starting to think that maybe we shouldn't lazy load at all… too complicated… We already changed the default to eager loading."* Lazy-import the heavy *dependency* inside the controller instead.

---

## Recipe candidates

Deduplicated across all sources. **195 items**, of which **37 are marked ★** as the highest-frequency / highest-pain candidates — build those first. Ordered so the list can seed the repo's directory structure directly.

### Foundations & mental model
1. ★ The frames-vs-streams escalation rule: when one region is enough, and when it isn't
2. ★ The form-response contract: 303 on success, 422 on failure, and why 302 breaks DELETE
3. Read `request.headers["Accept"]` to understand which `respond_to` block will run
4. Log every Turbo event to understand the lifecycle end to end
5. Turn on Stimulus debug logging (`application.debug = true`)
6. ★ Diagnose "nothing happened" — the five root causes and how to tell them apart
7. ★ Rails 6 → Hotwire idiom translation table (`method:`, `data-confirm`, `remote: true`, `.js.erb`, 302)
8. ★ Turbo-ify the default scaffold: the diff from generated CRUD to frame-based inline CRUD
9. What `<turbo-stream>` actually is (a custom element), and why it doesn't need WebSockets
10. Choose importmaps vs jsbundling/esbuild for a Hotwire app

### Forms & submission
11. ★ Submit a form automatically on input/select change (debounced)
12. Submit a form from JS correctly (`requestSubmit()` vs `submit()` vs `Turbo.navigator.submitForm`)
13. ★ Show inline validation errors without leaving the page
14. Reset/clear a form after a successful Turbo submission (and why binding to click is wrong)
15. Show a "Saving…" label on the submit button (`data-turbo-submits-with`)
16. Prevent double form submission, including the re-enable-before-redirect window
17. Submit a form without changing the URL
18. Re-render a single form field server-side with `helpers.fields`
19. Submit a GET form and get a Turbo Stream response (`data-turbo-stream`)
20. Force a specific form to bypass Turbo entirely (`data-turbo="false"`)
21. Read the response body in `turbo:submit-end`
22. Handle CSRF correctly when submitting via `fetch` / `@rails/request.js`
23. ★ Dynamic nested forms: add/remove `fields_for` rows with `<template>`
24. Fix nested `fields_for` rendering twice when returned via a stream (`formats: [:html]`)
25. Warn about unsaved changes on navigation (`turbo:before-visit`, not `beforeunload`)
26. Debounced autosave without uncatchable `AbortError`s
27. Client-side computed totals/subtotals in a form (no round trip)
28. Cross-field / cascading dependent selects (country → state → city)
29. Client + server dual validation without duplicating business rules
30. Multi-step wizard with server-persisted draft state
31. A confirmation/preview step for a POST that must not be GET-shareable (and why Turbo fights you)

### Turbo Frames
32. Load a section lazily (`turbo_frame_tag src:` + `loading: :lazy`)
33. ★ Break out of a frame to the full page (`target: "_top"` vs `data-turbo-frame="_top"`)
34. ★ Conditionally break out only on success — the `Turbo.StreamActions.redirect` pattern
35. ★ Diagnose and fix "Content Missing" — the full cause checklist
36. Handle `turbo:frame-missing` globally with a custom fallback
37. Handle an expired session / 401 inside a frame request
38. Gracefully handle 404/422/500 inside a frame without silently emptying it
39. Reload a frame programmatically (`frame.reload()`)
40. Re-navigate a frame to the same URL twice (clearing `src`)
41. Poll a frame on an interval — and why `broadcasts_refreshes` is usually better
42. Advance the URL when navigating inside a frame — with the maintainer's warning attached
43. Make a frame-advanced URL survive a browser refresh
44. Override `layouts/turbo_rails/frame.html.erb` so frame snapshots restore correctly
45. Fix a lazy frame that stops working after the back button
46. ★ Use turbo frames inside a `<table>` — and why you should target `<tr id>` with a stream instead
47. Inline-edit a single attribute with a frame + validation feedback
48. Replace a "New" form with the created record's show partial
49. Build tabs with turbo frames
50. Add a spinner / busy state while a frame loads (`[busy]`, zero JS)
51. Autoscroll a frame into view after it loads (`autoscroll`, `autoscroll_block`)
52. Nest frames safely, and why nested frames with `src` misbehave
53. Restrict an action to frame requests (`turbo_frame_request?`) — and why not to branch much
54. Never put a frame around `yield` in the application layout
55. Update `<title>`/meta/OG tags when a frame navigates (community hack; officially won't-do)
56. Get cookies sent with cross-subdomain frame requests

### Turbo Streams
57. ★ Append/prepend a newly created record to a list
58. Remove a destroyed record's row (`turbo_stream.remove(@record)`)
59. ★ Choose between `update` and `replace` — and why `replace` eats your frame
60. Render multiple stream actions in one response (and dhh's template-not-controller preference)
61. Target elements by CSS selector (`update_all`, `remove_all`, `replace_all`)
62. Render a stream from a `.turbo_stream.erb` template vs inline from the controller
63. Render a template (not a partial) from a stream
64. Render a partial inside `<turbo-stream><template>` with `formats: [:html]`
65. ★ Write a custom Turbo Stream action + a `TagBuilder` helper (the `function(){}` trap)
66. Show a JS alert / toast from a Turbo Stream response
67. Scroll to an element after a stream renders
68. Toggle a CSS class on an element from a stream
69. Trigger a file download in response to a Turbo form submission
70. Use `turbo_stream.refresh` — and why it's ignored when it comes from your own request
71. Serve both `turbo_stream` and `html` from one action, and control which wins
72. One delete button, two behaviors: stream-remove on index, redirect on show
73. Avoid duplicate list items when a form response and a broadcast both append
74. Render flash messages in every stream response via a `.turbo_stream.erb` layout
75. Recover gracefully from a failed/500 stream update instead of a silent no-op
76. Make `<script>` tags in frame and stream responses actually run — and what to do instead

### Broadcasting / real-time
77. Subscribe a page to a stream (`turbo_stream_from`) and broadcast to it
78. Broadcast to a per-user or per-scope stream
79. Broadcast to multiple recipients from one model callback
80. Move broadcasting out of model callbacks into controllers/jobs
81. ★ Use `broadcasts_refreshes` + morphing instead of per-action broadcasts
82. Use `*_later_to` variants to render broadcasts in a background job
83. Suppress broadcasts inside a block (`suppressing_turbo_broadcasts`)
84. Configure Action Cable (Solid Cable vs Redis vs the `async` trap)
85. ★ Handle `current_user` / Pundit / CanCan inside broadcast partials
86. Broadcast a partial containing a form without blowing up on CSRF/session
87. Debug "the broadcast log line appears but the page doesn't change"
88. Broadcast a turbo_stream from a Sidekiq job (frames can't reach the client)
89. Detect when a Turbo Stream subscription connects
90. Keep Action Cable/Redis costs sane at high concurrency
91. Cap DOM growth on long-lived broadcast pages (dashboards, chat)
92. Real-time chat with Action Cable + Turbo Streams
93. "Who's viewing this" presence indicators
94. Stream LLM/AI responses token-by-token via Turbo Streams

### Turbo Drive / navigation / caching
95. Disable Turbo for a specific link, form, or page
96. Use `data-turbo-method` for non-GET links — or switch to `button_to`
97. ★ Disable link prefetch-on-hover (`turbo-prefetch`), and make prefetched GETs safe
98. Preserve an element across navigations with `data-turbo-permanent` — and its real limits
99. ★ Enable morphing page refreshes and preserve scroll (`turbo_refreshes_with`)
100. Opt individual elements out of morphing (`turbo:before-morph-element`)
101. Preserve a single attribute across a morph (`turbo:before-morph-attribute`)
102. Morph a single region with a stream (`action="replace" method="morph"`)
103. ★ Stop the back button showing a stale cached page (`no-preview` vs `no-cache`)
104. Stop a filled-in form with validation errors from being cached and flashed
105. Opt a page or element out of the snapshot cache (`data-turbo-temporary`, `Turbo.cache.clear()`)
106. ★ Preserve scroll position across Drive visits (window and named containers)
107. Update `<title>` and `<head>` correctly across visits
108. Fix a Turbo progress bar that never disappears / hide it during broadcast refreshes
109. Redirect to an external URL (Stripe Checkout, OAuth) without a CORS error
110. Redirect to an anchor after a form submission (and why the fragment is dropped)
111. Enable cross-document view transitions, with direction-aware CSS
112. Customize which element Turbo Drive replaces instead of `<body>`
113. Detect on the server whether a request came from Turbo Drive
114. Link to a URL containing a dot without Turbo bailing out
115. Fix "swipe back in iOS Safari breaks all my buttons"
116. Keep the flash alive across a frame request that races a redirect

### Stimulus
117. ★ Wire up your first controller and verify it connected
118. ★ Diagnose "my controller doesn't connect" — the six-point checklist
119. Autoload controllers with importmap vs esbuild vs a Rails engine
120. Name controllers in subfolders (`admin--users`) and multi-word names correctly
121. ★ Pass data with values, and why values must sit on the controller element
122. Use typed values with defaults and `xValueChanged` callbacks
123. ★ Scope targets correctly and guard optional targets with `hasXTarget`
124. React to elements arriving/leaving with `xTargetConnected` / `xTargetDisconnected`
125. Use Action Params to identify which element triggered an action
126. `event.currentTarget` vs `event.target` — the #1 newbie mistake
127. Bind multiple actions to one event; use `@window` / `@document` global events
128. Use keyboard action descriptors (`keydown.enter->`, `keydown.ctrl+k@document->`)
129. ★ Communicate between controllers with `this.dispatch` events
130. ★ Communicate between controllers with Outlets — including the exact-name and connect() traps
131. Toggle CSS classes with the Classes API instead of hardcoded strings
132. ★ Clean up timers, observers, and library instances in `disconnect()`
133. ★ Tear down for the snapshot cache in `turbo:before-cache`, NOT `disconnect()`
134. ★ Why a controller declared ON a `<turbo-frame>` never reconnects
135. Understand `initialize()` vs `connect()` in a Turbo app
136. Read restored input values after the back button (why `connect()` is too early)
137. Share helper functions between controllers without breaking production imports
138. Subclass / compose Stimulus controllers (target inheritance is additive)
139. Type a Stimulus controller in TypeScript (declaring targets/values)
140. Debounce and throttle inside a controller
141. Fix controllers that double-fire from being registered twice
142. Lazy-import a heavy dependency inside a controller instead of lazy-loading the controller
143. Handle clicks outside an element (and prefer `<dialog>`/Popover light-dismiss)

### Third-party integrations
144. ★ Wrap any third-party JS library in a controller (connect/disconnect)
145. ★ Keep a third-party widget alive across a morph — with an idempotent `#teardown`/`#build`
146. Avoid exponential listener growth from a naive `reconnect()`
147. Re-emit non-native library events (Select2/Tom Select/jQuery) as native `change`
148. Load a library's CSS when using importmaps
149. Install a stimulus-components package with importmaps
150. Vendor an ESM library into an importmap without a bundler
151. Charts that survive Turbo navigation, cached restores, and morphs
152. Maps (Leaflet/Mapbox) with correct CSS and marker asset paths
153. Date pickers inside modals and frames
154. Keep Stripe.js / GA4 / a chat widget alive across navigations
155. Keep audio/video playing across navigations — and stop it playing after you leave
156. Rich text (Trix/Action Text): custom toolbar buttons, allowed attributes, when to escape to TipTap
157. Fix jQuery plugins that die after the back button

### Uploads
158. Active Storage direct upload with a progress bar
159. Direct upload inside a Turbo Frame (and the historical race that broke it)
160. Preview selected images before upload (single and multiple)
161. Drag-and-drop file dropzone wired to Active Storage
162. Why there is no upload progress for a plain Turbo form submission

### Components & UI patterns
163. ★ Modal via a persistent empty frame + native `<dialog>`
164. Make a `<dialog>` survive a morph without deadlocking the page
165. Reuse a single modal shell for multiple record types
166. Modal stacking — and why you probably shouldn't
167. ★ Debounced live search into a frame (keeping input focus)
168. ★ Infinite scroll / "load more" pagination with lazy frames
169. Combine infinite scroll with filters (append vs replace)
170. Accessible autocomplete / combobox
171. Cmd+K command palette (hotkeys + debounced search frame)
172. Drag-and-drop sortable lists persisting order to the server
173. Trello-style kanban board
174. Nested sortable tree with reparenting
175. Bulk row selection + batch actions in a data table
176. Server-side sortable/filterable/paginated data table with zero custom JS
177. Toast/flash notifications with auto-dismiss
178. Optimistic UI: instant-feeling create/update before the server responds
179. Tabs, accordions, and disclosure widgets (and when HTML `<details>` is enough)
180. Embed a calendar/scheduling view as a scoped JS island

### Auth, testing, ops
181. Configure Devise for Turbo (`error_status`, `redirect_status`, `navigational_formats`)
182. Make sign-out work (`button_to` + DELETE + 303)
183. Render an inline sign-up form inside a frame
184. ★ Request-spec a turbo_stream response (`response.media_type`)
185. Assert a Turbo broadcast happened (`broadcast_to(record.to_gid_param)`)
186. ★ Write non-flaky Capybara assertions against frames and streams (never `sleep`)
187. Debug "works in development, broken in production" (asset digests, relative imports, cable adapter)

### Accessibility
188. Announce Turbo navigations to screen readers (`aria-live` polyfill)
189. Manage focus after a stream update or a morph (the `[id]` requirement)
190. Keep `[disabled]` submit buttons from stealing focus

### Migration
191. Convert a `.js.erb` response to a Turbo Stream response
192. Replace `Rails.ajax` with `fetch` or `@rails/request.js`
193. Retire `data-remote: true` / `method:` links from a Rails 6 app
194. Add Hotwire to an existing Sprockets app (`manifest.js`, `link_tree`)
195. Coexist with rails-ujs during a phased migration

---

## Where people give up and reach for React

Honest assessment. Verdicts: **YES** (solved, boring), **PARTIAL** (works with real caveats), **NO GOOD ANSWER** (don't pretend).

| # | Requirement | How often | Verdict |
|---|---|---|---|
| 1 | Multi-step wizard | very common | **YES** |
| 2 | Drag-drop kanban / sortable lists | very common | **YES** |
| 3 | Autocomplete / combobox | very common | **YES** |
| 4 | Date / date-range picker | very common | **YES** |
| 5 | Client-side computed totals in a form | very common | **YES** |
| 6 | Charts with hover/tooltips | very common | **YES** |
| 7 | Infinite scroll with filters | very common | **YES** |
| 8 | Toasts / notifications | common | **YES** |
| 9 | Command palette (Cmd+K) | growing | **YES** (composed) |
| 10 | Canvas / map interactions | common | **YES** (mostly) |
| 11 | Custom media players | occasional | **YES** (one sharp edge) |
| 12 | Single modal | common | **YES** |
| 13 | Optimistic UI | common ask | **YES**, but hand-written each time |
| 14 | Rich text editor | common | **PARTIAL** |
| 15 | Complex cross-field validation | common | **PARTIAL** |
| 16 | Nested sortable tree | less common | **PARTIAL** |
| 17 | Modal stacks | occasional | **PARTIAL** |
| 18 | Animated state transitions | common | **PARTIAL** |
| 19 | Mobile app parity | growing | **PARTIAL** |
| 20 | Real-time collaborative editing | occasional, high-visibility | **PARTIAL** (presence yes, co-editing no) |
| 21 | Virtualized grid, 10k+ rows, inline edit | common in internal tools | **NO GOOD ANSWER** |
| 22 | Calendar / scheduling with drag-to-reschedule | common | **NO GOOD ANSWER** |
| 23 | Offline support / PWA | occasional | **NO GOOD ANSWER** (explicit non-goal) |
| 24 | High-latency / global users | structural | **NO GOOD ANSWER** (architecture) |

### The four genuine dead ends

**Virtualized grids / spreadsheets (10k+ rows, inline editing).** Hotwire's only answer is server-side pagination. There is no equivalent to `react-window`/AG Grid/TanStack virtual scrolling with fast client-side sort/filter/inline-edit and no round trip per interaction. The community's own attempt (`hottable`, an "Airtable clone in Rails+Hotwire") is explicitly a proof of concept. This is **the requirement most concretely named as a dealbreaker** — a Rails dev building a point-of-sale app: *"waiting for a network request on every micro interaction is a no-go"* ([HN](https://news.ycombinator.com/item?id=25942864)). If you truly need this, mount AG Grid/TanStack via Turbo Mount, or go Inertia.

**Calendar / scheduling views.** The cleanest documented case of a team reaching for React *around* Hotwire rather than fighting it — and it's thoughtbot's own blog: *"Our application simply renders a list of events, and we've been tasked with rendering it as a calendar. We've decided to use React for this since it's a solved problem thanks to FullCalendar."* Notably that post argues for a **hybrid, per-screen** approach, not an all-or-nothing rewrite: *"I'm now realizing that the two can be integrated on a spectrum."* Generalizes to any UI where a best-in-class pre-built React component already exists (Gantt charts, WYSIWYG page builders, spreadsheet editors).

**Offline / PWA.** An explicit non-goal, and a real technical wall in Hotwire Native: WKWebView Service Worker support requires App-Bound Domains, which conflicts with Hotwire Native's user-script injection ([hotwire-native-ios#188](https://github.com/hotwired/hotwire-native-ios/issues/188)). There is no official offline queue/outbox. HN: *"it's clear that DHH is not interested in even something like basic PWA support."*

**High-latency / global users.** Every interaction beyond pure client-side JS is a round trip to the origin. Multi-region read replicas help GETs, but writes — and any UI feedback contingent on a write — hit one region. **This is the single most repeated criticism across the entire HN corpus.** A paying HEY customer: *"In the face of medium-high latency, stuff behaves in an unpredictable/buggy way. Boxes open with no content. Links don't work like you'd hope. It just feels off."* ([HN](https://news.ycombinator.com/item?id=40555116))

### Complaints that recur (and are fair)

- **Stimulus doesn't compose at scale.** *"After working with it in a larger application, it is quickly obvious that more complex tasks are made extra hard and that lack of opinion turns into a wild west of different implementation patterns. When you start trying to get multiple stimulus controllers talking together… Good luck."* — hfourm, [HN](https://news.ycombinator.com/item?id=23642484)
- **State management gets tedious.** *"Stimulus is also great, but you can't go into it expecting React. State management can get very tedious. I use Turbo and Stimulus for most interactions in my current project, but I pull in Preact and HTM where I really need them."* — castaigne
- **Component/nesting thinking is awkward.** *"It is also hard to think of each hotwire controller as a component, you might face some problems when trying to do some nesting."* — fs0c13ty00
- **The component ecosystem is thin.** *"I've been using Hotwire for a greenfield project for the last year… but I miss React and will probably choose it for my next project… The React/Vue ecosystems have a lot more useful open source components."* — BillFranklin
- **Mobile forces an API anyway.** *"More and more, you've got 2-3 frontends… you'll end up building REST APIs and mobile apps anyways, so the productivity gains end up way smaller, possibly even net negative."* — yashap
- **Error handling is undocumented.** *"From the turbo handbook: 'When the response arrives, Turbo Drive renders its HTML and completes the visit.' Using the phrase 'When the response arrives' begs the question of what happens if it doesn't arrive."* — SahAssar
- **Edge cases accumulate.** *"I remember dozens of edge cases that involved errors and back buttons and flash scope… You accumulate enough edge cases and UX tweaks, and you're half way down the SPA requirements anyway."* — ebiester
- **Focus loss on frame swaps.** *"If someone has their focus in an input within the frame that gets swapped out, they're going to lose their focus. This has implications for accessibility as well as just regular usability."* — jonstaab

### Counter-arguments that hold up

- **"Hotwire can't do live-updating pages" — obsolete as of Turbo 8.** ericb, in production: *"In 7 lines of code, with no javascript, I had my index and view pages live-updating whenever a model changed on the server! It is spooky good."* ([HN](https://news.ycombinator.com/item?id=40313111))
- **"The HEY-is-laggy video proves Hotwire is slow" — the demo was throttled on purpose.** The demo's own author, quoted on HN: *"This is slow on purpose as a demonstration… The original post was highly misleading. Basically just a lie."* The underlying latency tradeoff is real; this particular evidence isn't.
- **"Frame swaps inherently break focus" — usually a scoping mistake.** midrus: *"The focus thing is as easy to fix as just not swapping that component. Certainly you need a different mindset to use this technique. If you try to do it the same way you do SPAs you will find a lot of problems of course."* Keep the input outside the frame that re-renders.
- **"You need a virtual DOM for stateful updates" — Turbo 8 ships Idiomorph.** The hand-rolled `morphdom` stream actions of 2023 are dead weight now.
- **"Most apps need heavy client interactivity" — most don't.** Evil Martians' framing is the useful version: Hotwire fits *"simple CRUD pages, most admin panels, wizards, and any screens where there is little entanglement between the user's actions and the state of multiple elements on the page."* That is most of a typical Rails app. The honest corollary: **if your screen has heavy entanglement between one action and many elements, that's the real signal to escape** — not "is it an app or a website."
- **Traffic goes both directions.** Linkana documented migrating *from* React *to* Hotwire, citing React's lack of Rails-like convention (*"being a library and not a framework, React code tends to become messy"*), a component library that fought their CSS, and unresolved GraphQL/Apollo N+1 complexity ([dev.to](https://dev.to/cirdes/from-react-to-hotwire-part-i-en-2o6g)).
- **Be honest about the JS-churn talking point.** nosefurhairdo, in the same thread as several anti-JS-churn comments: *"there hasn't been a significant change to our build system for our React application in the last ~5 years. Same is true for state management (redux)… Really don't understand the argument that React apps must be rewritten all the time."*

### The decision rule worth putting in the repo

Escape to a JS island when **one user action must change many entangled elements faster than a round trip allows**, or when a **best-in-class component already exists** (calendar, virtualized grid, WYSIWYG). Do it **per screen**, not per app — the thoughtbot spectrum position, which is also what the honest Hotwire advocates on HN converge on. Everything else in this document is a recipe, not a reason to leave.

---

## Source-quality caveats

- Two claims in the community mining were flagged by their own author as **synthesized characterizations** rather than verbatim quotes (a dev.to remark on updating multiple frames, and one on ActionCable request context). They are directionally supported by the SO/GitHub corpus but should not be quoted as sourced.
- Several `UNVERIFIED:` items remain in the underlying working notes and were **excluded** from this document rather than asserted: whether stream actions now honor `[data-turbo-permanent]` in current 8.x; whether Turbo pauses media before caching by default; whether the `<dialog>`/morph handling has since been built in; whether `refresh="morph"` + `frame.reload()` was resolved by [turbo#1192](https://github.com/hotwired/turbo/pull/1192)/#1028.
- Everything stated as current API in this document was checked against turbo-rails `main` source, the Turbo handbook/reference, or Rails 8.1 generator templates on 2026-08-15.
