# Which tool for this update?

**"I need to update part of the page after a click. Do I use a Turbo Frame, a Turbo Stream, morphing, or
just write some JavaScript? Every tutorial shows me one of them and none of them tell me when to pick
which."**

This is the root cause of the most-repeated complaint about Hotwire — that it's convoluted. It isn't
convoluted. It has four server-driven update mechanisms plus an escape hatch, they compose in a specific
order, and **nobody has written the decision procedure down.** The research corpus flags this as the
single highest-priority missing document out of 195 recipe candidates.

Here it is.

---

## The 15-second table

**Ask one question: who owns this region's state?** Not "which tool do I like," not "which is more
modern." Ownership decides, and everything else follows.

| Who owns the state | Reach for | Why |
|---|---|---|
| The server owns the whole page, and the whole page can change | **Plain link / redirect** (Turbo Drive) | You already have it. Don't build anything. |
| The server owns **one region**, and that region has its own URL | **Turbo Frame** | Scoped request *and* response. Free lazy-loading and history. |
| The server owns **specific known elements** and knows exactly which changed | **Turbo Stream** | Multiple targets in one response, not scoped to where the request came from. |
| The server owns **one known region**, and that region has state worth preserving | **`turbo_stream.replace(target, method: :morph)`** | Targeted render *with* morph semantics. The option almost nobody uses. |
| The **client** owns it — open/closed, selected, scroll, draft text, a character count | **Stimulus** (or plain CSS/HTML) | No server truth to reconcile. A round-trip would be actively wrong. |

*research/notes/14-morphing-dossier.md — "Decision rubric: morph vs streams vs frames"*

---

## The escalation ladder

Climb from the top. Stop at the first rung that works. Every rung down costs you complexity, and most
teams start three rungs too low.

### Rung 0 — can the server just do it?

A plain link and a redirect. Turbo Drive already makes this fast and doesn't flash the page. If the whole
page is changing anyway, **you are done** — no frame, no stream, no controller.

This kills more component candidates than every other rule combined. It's `docs/DECISIONS.md` R6 in this
repo, and it's the rung people skip fastest.

### Rung 1 — Turbo Frame

**When:** one region changes, and that region has (or should have) its own URL.

Frames are scoped on **both** ends of the lifecycle — the request comes from a frame, and the response
must contain a matching frame. seanpdoyle, stating the contract:

> …turbo-frames are explicitly scoped to a part of the page during both the request and response part of
> their lifecycles. A turbo-frame response **must** contain a `<turbo-frame>` element with an `[id]` that
> matches the requesting frame, **should** be a fully valid HTML page of its own, and **could** be accessed
> via its own resource via an HTTP GET request.

You get, for free: lazy loading (`loading="lazy"`), independent refresh (`frame.reload()`), and browser
history if you want it (`data-turbo-action="advance"` — but read the warning in
`docs/recipes/corrections.md` first; a maintainer explicitly does not recommend it).

### Rung 2 — Turbo Stream

**When one response must change more than one region.** That's the whole trigger. The corpus states the
escalation rule as: *start with a Frame. The moment one response must change more than one region, you
need Streams. **Frames get you there; streams finish the job.***

Streams are the mirror image of frames — deliberately *not* scoped:

> `turbo-stream` elements… are useful for globally changing parts of the requesting page's DOM, and are
> **not scoped** by where on the page the request was initiated from… do not need to be served in a valid
> HTML document response, and **can not** be accessed as their own resource.

dhh, on when to make the jump:

> If you want to replace multiple frames, you can also just target `_top` and replace the whole thing via
> drive. But otherwise there won't be a path to custom replace two frames. When you need that, you gotta go
> to turbo streams.

And, killing a widely-repeated misquote:

> By all means include multiple commands in your turbo stream response! It was designed for this.

### Rung 3 — `turbo_stream.replace(target, method: :morph)`

**The fourth option most people miss.** One region, updated surgically, *and* its client-side DOM state
survives.

```ruby
turbo_stream.replace(dom_id(@board), method: :morph, partial: "boards/board")
```

This is a **modifier on `replace`/`update`**, not a separate action. There is no
`<turbo-stream action="morph">` — that briefly existed in a pre-release PR and was restructured away before
shipping.

What it buys you over a plain `replace`: `data-turbo-permanent` is honoured, the `turbo:*morph*` events
fire, and scroll/focus/media/CSS-transition state inside the target survives. What it buys you over a
page-level morph refresh: it sidesteps the page-refresh trigger rules entirely — **no same-pathname
requirement, no `replace`-action requirement** — and costs one partial render instead of a full page render
per subscriber.

The next section is the argument for making this your default. It's the most important claim on this page,
so it gets its evidence shown honestly.

### Rung 4 — page-level morph refresh

**When:** the flow is *submit → redirect back to the same path*, or *broadcast → everyone re-renders the
same page*, **and** the set of things that can change is large or unbounded enough that enumerating stream
targets would be a combinatorial mess.

All of these must hold:

- The page has meaningful client state worth keeping — scroll, focus, an open panel, in-flight CSS
  transitions. **This is the entire benefit.** jorgemanrubia is explicit that the win *"came from keeping
  client-side state: scroll, focus, selected text, CSS transition states"* — **not** from speed. 37signals
  separately prototyped server-side diffing to make morphing faster and found the gains *"marginal… not
  noticeable"*, and abandoned it.
- Your rendering is **idempotent**: rendering twice from identical state produces identical HTML. No
  `SecureRandom` in ids, no `Time.now` in class names.

⚠️ **Two traps before you commit to this rung.** Turbo decides "is this a page refresh?" by comparing
**pathname only** — the query string is ignored in both directions. So `/posts?filter=open` →
`/posts?filter=archived` *will* morph across unrelated content, and a different path *never* morphs no
matter what you set. And **422 validation responses do morph**, which is what kills Stimulus-wrapped JS
libraries on the most ordinary flow in Rails. See `docs/recipes/form-response-contract.md`.

### Rung 5 — drop to Stimulus

**When the client owns the state.** Not "when Hotwire got hard" — when there is genuinely no server truth
to reconcile.

The test: *would a server round-trip be wrong, not just slow?* A character counter is the clean case —
the count is derived entirely from what the user is typing right now, has no server representation, and
debouncing keystrokes to the server just to echo a number back would be absurd. Same for open/closed
disclosure state, drag-reorder-in-progress, and client-side-only filtering of an already-loaded list.

If you're at this rung because the server tools *felt* awkward rather than because the state is genuinely
client-owned, go back to rung 0 and re-read the ownership question.

*research/notes/07-problem-mining.md Q41, Q28, Q4, recipe candidate #1;
research/notes/14-morphing-dossier.md — decision rubric*

---

## The case for targeted morph as your default

`docs/DECISIONS.md` R7 in this repo says: default to `turbo_stream.replace(target, method: :morph)`, not
page-level morphing. **Here's the evidence, graded honestly** — this is usually pitched as three
converging lines, and it isn't quite; it's two strong ones plus a supportive quote.

### Strong: 37signals don't use page-level morph in production

This is the best-evidenced part, from a direct census of four shipped codebases:

| App | turbo-rails | Morphing? |
|---|---|---|
| Writebook | 2.0.11 | **None.** Zero `turbo_refreshes_with` |
| Campfire | 2.0.16 | **None.** Zero `turbo_refreshes_with` |
| Fizzy | current | **Yes — but never page-level refresh** |

> Nobody in these codebases uses `turbo_refreshes_with method: :morph` for whole-page broadcast refreshes.
> The blogosphere's "just broadcast a refresh and let morphing sort it out" is not what 37signals ships.
> They target precisely and use morph only to make *that* replacement non-destructive to focus/scroll/
> selection.

What Fizzy actually ships is targeted morph, everywhere:

```erb
<%= turbo_stream.replace(dom_id(@column), partial: "boards/show/column", method: :morph, locals: { column: @column }) %>
```

```ruby
render turbo_stream: turbo_stream.replace([ @card, :card_container ],
  partial: "cards/container", method: :morph, locals: { card: @card.reload })
```

*(Fizzy is source-available under the O'Saasy licence, not open source — study it, don't vendor from it.
See `docs/recipes/corrections.md`.)*

**Scope this claim correctly:** Fizzy is the *only* one of the four apps that uses morphing at all. So the
honest version is "one 37signals app uses morphing, and even there only in targeted form; the other three
use none" — not "37signals uniformly prefer targeted morph."

Worth knowing: even used narrowly, morphing cost Fizzy three Stimulus controllers to contain its bugs —
including a `morph_guard` that marks the enclosing frame `data-turbo-permanent` while an edit is in
progress so a broadcast can't morph away in-flight state.

*research/notes/11-production-codebases.md — "Morph vs targeted streams: a clear generational split"*

### Strong: the mechanics genuinely favour it

Not opinion — this follows from Turbo's own trigger rules. Targeted morph has no same-pathname
requirement, no `replace`-action requirement, renders one partial instead of a whole page, honours
`data-turbo-permanent`, and fires the full `turbo:*morph*` event set. Page-level morph has all of the
trigger traps and, on a page with 500 subscribers, `broadcasts_refreshes` is **500 full page renders**.

### Weaker than usually claimed: Marco Roth's critique

Marco Roth did say this, in turbo#1163 (2024-02-07), and it's directly on point:

> There are definitely reasons why you'd want to have an independent morph action. **Morphing has the
> benefit of not loosing client-side state.** In any case where you are currently using
> `turbo_stream.replace` or `turbo_stream.update` you could consider upgrading that call to a
> `turbo_stream.morph`. I've personally done this quite often.

His broader, repeated critique is about **granularity** — his RailsConf 2024 talk lists "Morphing as an
individual concept" and "Partial Page Refreshes" as things Turbo lagged on, and his wishlist names "Partial
Page Morph Updates" and "Independent Morphing". StimulusReflex had selector-scoped morphs five years
earlier.

**But be honest about what that is.** Roth never connects his granularity critique to "therefore targeted
morph should be your default" — the research corpus is explicit that *"the connection is ours to make."*
And the quote above predates by three weeks the filing of turbo#1210, the Stimulus-values-clobbering bug,
which he appears simply unaware of. **Do not cite him as having sanctioned any morph workaround**, and
don't propagate his "morphing preserves client-side state" phrasing unqualified — it preserves *DOM* state
and clobbers *declarative attribute* state, which is exactly where Stimulus values live.

*research/notes/13-marcoroth-ecosystem.md — "His actual morphing critique: granularity, not lifecycle"*

### The counterweight, which keeps this scoped

thoughtbot's Matheus Richard, the most-quoted assessment in the ecosystem:

> morphing isn't as simple as it might seem, so enabling it by default can be dangerous… Turbo morphs are
> sharp knives that should be wielded with care in specific scenarios, but not something ready yet to be
> enabled globally.

That's about *global* morphing, and it's compatible with preferring *targeted* morph. It's the reason this
page says "default to targeted morph" and never "default to morph."

### ⚠️ A genuine disagreement in the source material

The UI pattern catalogue recommends page-level `broadcasts_refreshes` + morph as the **default** answer for
live-updating lists. The production census shows 37signals using it **nowhere**. These aren't strictly
incompatible — the first optimises for "no view coupling, correct authorization," the second reflects what
people actually ship — but they *are* opposing advice and you should know that before choosing.

**My read:** use `broadcasts_refreshes` when the alternative is enumerating an unbounded set of stream
targets and you'd get the authorization wrong. Use targeted morph everywhere else. Measure the render cost
before you put page-level broadcast morph on anything with many concurrent viewers.

---

## When one frame is enough — and when it genuinely isn't

### Enough: tabs

Each tab is a real link to a real URL targeting a shared frame. The server renders `aria-selected`. There
is no client state at all.

```erb
<div role="tablist">
  <%= link_to "Members", team_path(@team, tab: "members"),
        role: "tab", "aria-selected": @tab == "members",
        data: { turbo_frame: "tabpanel", turbo_action: "advance" } %>
  <%= link_to "Settings", team_path(@team, tab: "settings"),
        role: "tab", "aria-selected": @tab == "settings",
        data: { turbo_frame: "tabpanel", turbo_action: "advance" } %>
</div>

<%= turbo_frame_tag "tabpanel" do %>
  <%= render "teams/tabs/#{@tab}", team: @team %>
<% end %>
```

**The requirement that trips people up: the tab URL must be independently renderable.** If
`?tab=members` only works as a frame response, Back and reload break.

### Enough: inline editing

One frame per editable cell, id'd `dom_id(record, :field)`. The show partial and the edit-form partial
declare the **same frame id**, so the swap is automatic — `#update` needs no stream and no `respond_to`.
No JavaScript for the core loop.

### Not enough: the modal that must update a row

The canonical case, and *"the single clearest 'Hotwire is convoluted' complaint on the Rails core forum"*
— ~40k views across Stack Overflow variants, 99 comments on turbo#138.

Edit a record in a modal. On failure, show errors **inside the modal**. On success, close the modal **and**
update the row in the list behind it.

**A frame cannot express the success path**, because one response must touch two regions — and a frame
response resolves exactly one matching id. Extra frames in the response are ignored.

```ruby
def update
  if @item.update(item_params)
    redirect_to items_path, status: :see_other        # success: escapes the frame
  else
    render :edit, status: :unprocessable_content      # failure: renders edit.turbo_stream.erb
  end
end
```

```erb
<%# app/views/items/edit.turbo_stream.erb — failure stays in the modal %>
<%= turbo_stream.replace("modal", partial: "form", locals: { item: @item }) %>
```

For the success half — getting out of the frame — see `docs/recipes/frame-breakout.md`. **Do not** reach
for `redirect_to path, turbo_frame: "_top"`; it does not exist.

### Not enough: anything inside a table

`<turbo-frame>` inside `<table>`/`<tbody>`/`<tr>` **does not work** — HTML's table content model hoists
unknown elements out of table internals. `<tbody is="turbo-frame">` doesn't work either; seanpdoyle tested
it, and Safari never implemented customizable built-ins.

Target the row with a stream instead. Streams work on any element with a matching id:

```erb
<tbody id="companies">
  <tr id="<%= dom_id(company) %>"> … </tr>
</tbody>
```

```ruby
render turbo_stream: turbo_stream.replace(dom_id(@company), partial: "company", locals: { company: @company })
```

### Not enough: one response must touch something outside the form

The cleanest one-line test for escalating from frame to stream: **do you need to update a header count, a
flash region, a sidebar badge — anything outside the region the request came from?** If yes, it's a
stream.

```ruby
render turbo_stream: [
  turbo_stream.replace(@post, partial: "posts/form", locals: { post: @post }),
  turbo_stream.update("flash", partial: "shared/flash",
                      locals: { alert: "Couldn't save that post." })
], status: :unprocessable_content
```

*research/notes/08-ui-pattern-catalog.md — Tabs, Inline editing, Form errors via Turbo Streams;
research/notes/07-problem-mining.md Q4, Q28, P13*

> **Worth knowing:** the 422 above is **not** required for Turbo to apply a stream. Verified in Turbo
> 8.0.23 — `StreamObserver#inspectFetchResponse` tests only the content type; the status is never
> consulted. Keep the 422 anyway for non-Turbo clients, tests, and error monitoring.

---

## Rung 5 in practice: when Stimulus is the right answer

A character counter. No frame, no stream, no morph — the state is derived from an input the user is
actively typing into.

```js
// app/javascript/controllers/char_count_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]
  static values = { max: Number }

  connect() { this.count() }

  count() {
    const used = [...new Intl.Segmenter().segment(this.inputTarget.value)].length
    this.outputTarget.textContent = `${this.maxValue - used} left`
  }
}
```

Note `Intl.Segmenter` rather than `.length` — "👨‍👩‍👧" is one character to a human and eight to `.length`.

**An accessibility detail worth carrying:** an `<output>` has an implicit `role="status"`. Wiring it to
fire on every keystroke makes a screen reader announce continuously. Split it — an `aria-hidden` visual
counter, plus a separately-debounced threshold announcer.

*research/notes/08-ui-pattern-catalog.md — Character counters*

---

## Before you ship a morph, read this list

The eight breakages, ranked by how often they bite a real team. Full detail in
`research/notes/14-morphing-dossier.md`; the fixes for the common ones are in `docs/recipes/diagnosis.md`.

1. **Stimulus-wrapped JS libraries die on validation-error re-render.** TomSelect, Select2, Flatpickr,
   Chart.js, Leaflet, Popper, Shoelace. The library's injected DOM isn't in the server HTML, so morph
   removes it; the element survives, so `connect()` never re-runs. **The most common one, on the most
   ordinary flow there is.**
2. **Stimulus `data-*-value` clobbered, `connect()` skipped.** `morphAttributes` overwrites every attribute
   differing from the server's HTML. turbo#1210, open 2.5 years, won't-fix.
3. **`<dialog>` top-layer deadlock.** Morph removes `open` without calling `close()`; the page becomes
   completely unclickable.
4. **A focused input's value overwritten mid-typing.** Auto-submitting search boxes.
5. **Trix / Action Text breaks** — editor goes read-only, toolbar empties. Needs `data-turbo-permanent`
   around **both** editor and toolbar.
6. **`<details open>` snaps shut on every refresh** — and under `broadcasts_refreshes`, for *every viewer*,
   not just the person who edited.
7. **Duplicate `id`s degrade matching** — ids get stripped from `persistentIds` entirely, degrading the
   whole ancestor chain.
8. **The morph silently doesn't happen at all** — no error, no warning, nothing telling you why. Usually
   the pathname-only trigger rule.

**Do not** try to defeat morph detection by adding a dummy query param. That does not work — `isPageRefresh`
compares `pathname` only. The workaround still circulates; it's wrong.

---

## Honest gaps

Flagging these rather than smoothing them over:

- **Morph behaviour is untested against a long list of common libraries.** The corpus found *no* field
  reports for morph interaction with Alpine.js state, SortableJS, TinyMCE, CodeMirror, Mapbox, Choices.js,
  Slim Select, `<input type="file">`/`FileList` retention, browser autofill, an in-flight POST when a
  broadcast refresh lands, or the Popover API. Treat these as untested, not as safe.
- **Analytics and session-replay scripts under broadcast morph** is the biggest unexamined gap — the
  mechanism suggests double-counted `turbo:load` pageviews and inline `<script>` never re-executing, but
  neither is corroborated by any field report.
- **Per-page override of `turbo_refreshes_with` via `content_for`** is reported broken (turbo-rails#549)
  but seanpdoyle could not reproduce it. Partially unverified.
- **`data-turbo-permanent` + view transitions** is well documented for the replace/Bardo path and
  unverified for the morph path specifically.
- `frame.reload()` with `refresh="morph"` **does** work as of Turbo 8.0.23 (fixed by turbo#1192) — an
  earlier research file left this open; the morphing dossier resolves it.

---

## Where crosswire helps

Nowhere in the decision itself — this page is about Turbo, and every rung works the same with or without
this gem. Where crosswire shows up is rung 5: primitives like `disclosure` and `dialog` are built so their
state survives a morph (state in a value, server renders it, one write path), which is the part people get
wrong by hand.

---

*Sources: research/notes/14-morphing-dossier.md (decision rubric, the 41-row breakage inventory and its
top-8 ranking); research/notes/11-production-codebases.md (census of 210 controllers across 10 codebases;
the 37signals morph split); research/notes/13-marcoroth-ecosystem.md (Marco Roth's granularity critique,
verified across every channel); research/notes/07-problem-mining.md Q4, Q28, Q41, P2, P13, recipe candidate
#1; research/notes/08-ui-pattern-catalog.md (Tabs, Inline editing, Form errors via Turbo Streams,
Live-updating lists, Character counters).*
