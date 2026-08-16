# Platform primitives & hypermedia alternatives

> Verified 2026-08-15. This document replaces `18-platform-primitives-UNVERIFIED.md`
> (deleted). Every claim below was checked against a live primary source — MDN Baseline
> badges, the `web-features` dataset MDN's badges are generated from, `gh`/npm/RubyGems
> APIs, or the cited article itself — this run. See "Verification log" at the bottom for
> methodology and what could not be checked.

---

## 1. Platform primitives that may replace Stimulus controllers

The strategic claim: several CSS/HTML features now do natively what Hotwire component
libraries currently ship JavaScript for. If true, crosswire should NOT build controllers
for these — it should document the native primitive and ship at most a thin helper.

| Feature | Verified status (2026-08-15) | Verdict | Source |
|---|---|---|---|
| `popover` + `popovertarget` | **Newly available since Jan 2025.** Not yet widely available — an unresolved Safari iOS bug (popovers can't be dismissed by touch) blocks promotion. All engines ship it (Chrome 116, Edge 116, Firefox 125, Safari 17). | CORRECTED — original said "widely available ~2024" | [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Popover_API) |
| `<dialog>` (`showModal()`, `::backdrop`) | **Widely available since March 2022** (reached "widely" Sept 2024). | CORRECTED — original said "Apr 2023"; base element is a full year older and already widely available | [MDN](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/dialog) |
| `<dialog closedby>` | **NOT Baseline.** Chrome/Edge 134+, Firefox 141+ — **Safari has not shipped it at all.** | CORRECTED — original flagged "unconfirmed"; now resolved as genuinely not-yet-safe | [MDN](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/dialog#closedby) |
| CSS anchor positioning | **Newly available since Jan 2026** for the commonly-used properties (`anchor-name`, `anchor()`, `position-area`, `position-try-fallbacks`). The *full* module isn't Baseline yet — `position-anchor` itself currently shows only Firefox 151 in BCD, with no confirmed Chrome/Safari version recorded. | CONFIRMED, with a real caveat the original missed (partial-module gap, and unusually Firefox-first on one property) | [MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/anchor-name) |
| View Transitions (same-document) | **Newly available since Oct 2025.** Chrome 111, Edge 111, Firefox 144, Safari 18 all support it. | CONFIRMED | [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Document/startViewTransition) |
| View Transitions (**cross-document**) | **NOT Baseline — limited.** But NOT Chromium-only: Safari has supported it since 18.2 (Dec 2024). **Firefox is the actual holdout**, with no shipped support at all. | CORRECTED — original said "Chromium-only"; wrong engine named | [MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/@view-transition) |
| Invoker Commands (`command`/`commandfor`) | **Newly available since Dec 2025** (~8 months old as of today). Chrome 135, Edge 135, Firefox 144, Safari 26.2. | CONFIRMED | [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Invoker_Commands_API) |
| `:has()` | **Widely available since Dec 2023** (crossed the widely-available threshold 2026-06-19 — very recently). | CONFIRMED | [MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Selectors/:has) |
| Scroll-driven animations | **NOT Baseline — limited.** Safari now supports it (v26+) — **Firefox is the sole holdout**, not "Chromium-only" as claimed. | CORRECTED — right conclusion (not safe yet), wrong engine blamed | [MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/animation-timeline) |
| `content-visibility: auto` | **Newly available since Sept 2024.** Chrome 108, Edge 108, Firefox 130, Safari 18/26. | CONFIRMED | [MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/content-visibility) |
| `field-sizing: content` | **Newly available since June 2026** — genuinely the youngest confirmed-Baseline item here (younger than anchor positioning's Jan 2026 and Invoker Commands' Dec 2025). Firefox was last to ship (152). | CONFIRMED | [MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/field-sizing) |
| `text-wrap: balance` | **Newly available since May 2024.** Chrome 114, Firefox 121, Safari 17.5. | CONFIRMED (close to original's "2024") | [MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/text-wrap) |
| `text-wrap: pretty` | **NOT Baseline at all.** Chrome 117/Edge 117/Safari 26 only — **Firefox has not implemented it.** | CORRECTED — original lumped this with `balance` under "Baseline 2024"; it is a materially different, non-safe feature | [MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/text-wrap) |
| Customizable `<select>` / `appearance: base-select` | **NOT Baseline — limited, Chromium-only** (Chrome/Edge 135+). No Firefox, no Safari support at all. | CONFIRMED | [MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/appearance) |
| Speculation Rules API | **NOT Baseline — experimental, Chromium-only** (Chrome/Edge 109+). Firefox and Safari both explicitly unsupported. | CONFIRMED | [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Speculation_Rules_API) |
| `<details>` base element | **Widely available since Jan 2020.** | CONFIRMED | [MDN](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/details) |
| `<details name>` (exclusive accordions) | **Newly available since Sept 2024** — Chrome 120, Firefox 130, Safari 17.2, all engines. | CORRECTED — original flagged this "unconfirmed"; now resolved and safe-ish | [MDN](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/details#name) |
| `inert` | **Widely available since Apr 2023** (crossed "widely" 2025-10-11). | CONFIRMED | [MDN](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/inert) |
| `@starting-style` | **Newly available since Aug 2024.** All four engines (Chrome 117, Edge 117, Firefox 129, Safari 17.5) support it; not yet "widely" (needs ~30 months, only ~24 have passed). | CONFIRMED, with a nuance the original's flat "Baseline 2024" glossed over (still "newly," not "widely," as of today) | [MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@starting-style) |
| `transition-behavior: allow-discrete` | **Newly available since Aug 2024.** Same four-engine pattern as `@starting-style`. | CONFIRMED, same nuance | [MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/transition-behavior) |
| "Interest invokers" / `interestfor` | **NOT Baseline — experimental, Chromium-only** (Chrome/Edge 142+). Firefox and Safari both unsupported. MDN does now have a stable page for it. | CONFIRMED — original correctly flagged this as unconfirmed/unsafe; now resolved with a concrete status | [MDN](https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/interest_event) |

**Corrected grouping**

- *Safe today (Baseline, all major engines shipping)*: `<dialog>` core, `:has()`,
  `content-visibility`, `inert`, `text-wrap: balance`, `@starting-style`, `allow-discrete`,
  same-doc View Transitions, Invoker Commands, `<details name>`, popover (modulo the Safari
  iOS touch-dismiss bug), anchor positioning core properties, `field-sizing`.
- *Still genuinely risky, NOT Baseline*: cross-document View Transitions (Firefox missing,
  not Chromium-exclusive — Safari has it), Speculation Rules (Chromium-only), scroll-driven
  animations (Firefox missing), customizable `<select>` (Chromium-only), `text-wrap: pretty`
  (Firefox missing), `<dialog closedby>` (Safari missing), interest invokers (Chromium-only).
- One correction worth flagging on its own: the original doc's habit of saying "Chromium-only"
  for anything not-yet-Baseline was wrong in two of the four cases where it said it
  (cross-document View Transitions and scroll-driven animations both actually have Safari
  support now — Firefox is the one lagging). Don't let "Chromium-only" become a reflexive
  label; check per-feature.

---

## 1a. The design-relevant question: does `@starting-style` + `allow-discrete` replace a transition controller?

**Verified facts.** Both features are Baseline "Newly available since Aug 2024," confirmed
supported in Chrome, Edge, Firefox, and Safari via MDN's own compat widgets (fetched
directly). A third property that shows up in MDN's *own* popover-transition example,
`overlay` (governs when a top-layer element like a `popover` or `<dialog>` is actually
removed from the top layer) is **NOT Baseline — Chrome/Edge only, Firefox and Safari
explicitly unsupported.** That matters because it means popover/dialog exit transitions that
rely on animating `overlay` are Chromium-only right now; transitions on ordinary elements
(divs, not top-layer content) don't touch `overlay` at all and are unaffected.
(Source: [MDN `overlay`](https://developer.mozilla.org/en-US/docs/Web/CSS/overlay))

**A working, zero-JavaScript, cross-browser example** (deliberately avoids `popover`/`overlay`
so it doesn't inherit that caveat — a plain checkbox toggle drives it instead):

```html
<input type="checkbox" id="toast-toggle" class="sr-toggle">
<label for="toast-toggle" class="toast-trigger">Show toast</label>

<div class="toast">
  Entered and will exit with pure CSS — zero JavaScript.
</div>

<style>
  .sr-toggle { position: absolute; opacity: 0; pointer-events: none; }

  .toast {
    display: none;
    opacity: 0;
    transform: translateY(0.5rem);
    transition: opacity .25s ease, transform .25s ease, display .25s allow-discrete;
  }

  #toast-toggle:checked ~ .toast {
    display: block;
    opacity: 1;
    transform: translateY(0);
  }

  @starting-style {
    #toast-toggle:checked ~ .toast {
      opacity: 0;
      transform: translateY(0.5rem);
    }
  }
</style>
```

`display: none → block` is a discrete property; `allow-discrete` makes it flip at 0%/100%
of the transition instead of the browser's default 50% snap, so the element stays laid out
and visible for the whole animation in both directions. `@starting-style` supplies the
"before" values for the very first style change after the shown-state selector starts
matching — exactly the entry-animation problem that used to need a JS double-`requestAnimationFrame`
hack (add the element, force a reflow, then add the final-state class on the next frame).

**Verdict: yes for most of it, no for one case that matters a lot to us.**

*Replaces JS entirely:*
1. Any enter/exit driven by a **local** class or attribute toggle — dropdown open/close,
   toast dismiss-by-click, accordion expand/collapse, disclosure widgets. This is the bulk
   of what `tailwindcss-stimulus-components`' transition module exists for.
2. **Enter transitions for elements a Turbo Stream inserts** (`append`/`prepend`/`before`/
   `after`/`replace`). Reasoning from the spec/MDN: `@starting-style`'s trigger condition —
   demonstrated in MDN's own dynamic-insertion example using `document.createElement()` +
   `.append()` — is "first rendered in the DOM," not "created via a specific API." Turbo
   inserts real DOM nodes by cloning `<template>` content, and those nodes already carry
   their final ("shown") CSS classes straight from the server-rendered fragment — no JS
   class-toggle step is needed. A Turbo-Stream-appended `.item` with
   `@starting-style { .item { opacity: 0 } }` in the stylesheet animates in with zero JS.

*Does NOT replace JS for:*
1. **Exit transitions triggered by a Turbo Stream `remove` action** (or by idiomorph/morph
   diffing deciding to delete a node). Turbo's remove action calls the DOM's `Node.remove()`
   synchronously — the node is gone before any CSS transition has anything left to animate.
   `allow-discrete` only changes *when* a discrete property flips relative to a transition
   already running; it cannot intercept or defer an outright node deletion, because deletion
   isn't a style change, it's removal from the render tree. There is no CSS-only way to say
   "wait 250ms before actually deleting this node." **This is a genuine spec-level limitation,
   not a browser-support gap that will close with time.** Crosswire still needs a small,
   narrowly-scoped piece of JS for this one case — intercept the stream-render/morph event,
   add an "exiting" class, wait for the transition to finish
   (`transitionend`/`Element.getAnimations()`), then actually remove the node. That's a
   single-purpose ~20-line hook, not a general transition controller.
2. Popover/dialog exit transitions that need to look right in the top layer additionally
   depend on `overlay`, which is Chrome/Edge-only today. Non-popover elements are unaffected.

**Bottom line for crosswire:** the transition *primitive* is now mostly free, including —
encouragingly — entry animation for server-pushed Turbo Stream content. What survives as a
real, scoped JS need is a single small "defer DOM removal until the exit transition finishes"
hook for Turbo Stream `remove`/morph deletions. Recommend: document the CSS pattern as the
default; ship at most one tiny helper for the remove-action case, not a
`tailwindcss-stimulus-components`-style transition controller module.

---

## 2. Datastar

**Repo identity, CORRECTED (original didn't confirm it):** [`starfederation/datastar`](https://github.com/starfederation/datastar)
— 4,938 stars, latest release v1.0.2 (2026-06-02), pushed 2026-08-14, not archived.

**Origin story, CONFIRMED.** htmx's own ["Alternatives to htmx"](https://htmx.org/essays/alternatives/)
essay (by Carson Gross, published 2025-01-12 — both author and date confirmed by fetching
the live page) says verbatim: *"Datastar started life as a proposed rewrite of htmx in
typescript and with modern tooling. It eventually became its own project and takes an
SSE-oriented approach to hypermedia. Datastar combines functionality found in both htmx and
Alpine.js into a single, tidy package that is smaller than htmx."* Datastar's creator is
Delaney Gillilan (GitHub handle `delaneyj`, confirmed as the repo's top contributor) —
this was a separate, correct attribution in the original and is unrelated to who wrote the
htmx essay describing it.

**Architecture, CONFIRMED.** Fetched the repo's README and SDK config directly:
- Bundle size: **10.76 KiB gzipped** (within the claimed "~10–15KB" range).
- Canonical SSE event type names (from `sdk/datastar-sdk-config-v1.json`): **`datastar-patch-elements`**
  and **`datastar-patch-signals`** — confirms these replaced the older `…-merge-fragments`
  / `…-merge-signals` names the original doc flagged as "possibly renamed."
- Core attributes (`data-signals`, `data-bind`, `data-text`, `data-show`, `data-on`, etc.)
  match what's documented in the repo.

**Ruby/Rails SDK — CORRECTED framing.** Datastar does ship an official Ruby SDK, but it is
a **Rack-level SDK, not a Rails-specific one.** It lives in its own repo,
[`starfederation/datastar-ruby`](https://github.com/starfederation/datastar-ruby) (37 stars,
pushed 2026-06-02) — the monorepo's `sdk/ruby/` directory is now just a pointer to it. It
publishes the RubyGems gem named **`datastar`** (not `datastar-rails`), currently v1.0.5, by
Ismael Celis, described as *"Ruby SDK for Datastar. Rack-compatible,"* depending on `rack >=
3.2`. A RubyGems lookup for `datastar-rails` returns not-found — **no official or community
Rails-branded gem exists.** Full official SDK language list (from the monorepo's `sdk/`
directory): Clojure, .NET, Go, Haskell, Java, PHP, Python, Ruby, Rust, TypeScript, Zig.

**Judgment (unchanged, still worth keeping on its merits):** don't copy Datastar's transport
— Rails already has ActionCable/Redis and Turbo Streams ride on it. What's worth stealing is
narrower: **Stimulus has no declarative reactive-state layer.** A small declarative signals
graph (`data-signals`/`data-computed`/`data-bind` style) layered *on top of* Turbo Streams
rather than replacing them would close a genuine gap. This is a crosswire design idea worth
evaluating on its merits, independent of the numbers above.

---

## 3. inertia-rails — the legitimate middle path

**Numbers, CORRECTED (date field was mislabeled, not wrong).** `gh repo view` output:

| Repo | Stars | Latest version | Release date | Actual last push |
|---|---|---|---|---|
| `inertiajs/inertia` | 8,097 | v3.6.1 | 2026-07-07 | **2026-08-11** |
| `inertiajs/inertia-rails` | 1,221 | v3.22.0 | 2026-07-17 | **2026-08-15 (today)** |

Star counts and version numbers were exactly right. The original doc's "pushed" dates were
actually the *release* dates — the real last-commit-pushed dates are a month or so later in
both cases, i.e. both projects are more actively maintained than the original numbers implied.
RubyGems name is `inertia_rails` (underscore), 1,868,625 downloads.

```ruby
class UsersController < ApplicationController
  def index
    render inertia: { users: User.active.map { |u| u.as_json(only: [:id, :name, :email]) } }
  end
end
```

**Adoption evidence, spot-checked:**
- HN launch thread (142pts/44 comments, 2024-09-06) — not independently re-verified this
  pass (out of scope of the four priorities); treat as UNVERIFIED.
- Evil Martians has published **at least five** posts on Inertia-rails, not two as
  originally claimed. Confirmed via the full site sitemap/atom feed:
  - ["Redprints CFP: an open source CFP management app built with Rails + Inertia.js"](https://evilmartians.com/chronicles/redprints-cfp-open-source-cfp-management-app-build-with-rails-and-inertia-js) — 2025-08-06 (this one exactly matches the original doc's second citation)
  - "Simplicity vanished: solving the mystery with Inertia.js and Rails" — 2025-07-29
  - "Inertia.js in Rails: a new era of effortless integration" — 2025-12-31
  - "Optimistic UI in Rails with Optimism and Inertia" — 2026-01-27
  - "The joy of Inertia Rails: painting your own with ~50 happy little lines" — 2026-07-14
  - **The original's other cited date, 2025-04-14, does not correspond to any real Evil
    Martians post** — exhaustively checked against the full chronicles sitemap and atom
    feed. REFUTED / likely fabricated; use one of the five real posts above instead.
- Hardcover.app case study: real title is **"Part 1: How We Fell Out of Love with Next.js
  and Back in Love with Ruby on Rails & Inertia.js"** (the original's paraphrase, "We Fell
  Out of Love with Next.js and in Love with Rails and Inertia.js," drops the "Part 1:" and
  changes "Back in Love" to "in Love"). Date confirmed exact: 2025-05-02. URL:
  https://hardcover.app/blog/part-1-how-we-fell-out-of-love-with-next-js-and-back-in-love-with-ruby-on-rails-inertia-js.
  Content confirmed: migration *from* a Next.js SPA *to* Rails+Inertia, as claimed.

**Assessment (unchanged, this is a judgment call not a checkable fact):** you lose Turbo
Drive/Frames/Streams on Inertia-rendered routes; you gain real React/Vue ergonomics with
Rails-typed props and session auth that works. Risk is organizational more than technical.
Framed as the honest answer to "what if Hotwire genuinely isn't right for this screen?"

---

## 4. StimulusReflex + CableReady — shrinking niche, not dead

`gh repo view` output:

| Repo | Stars | Archived | Latest version | Last push | Open issues |
|---|---|---|---|---|---|
| `stimulusreflex/stimulus_reflex` | 2,333 | no | v3.5.5 (2026-07-28) | 2026-08-11 | **12** |
| `stimulusreflex/cable_ready` | 771 | no | v5.0.6 (2024-12-15) | 2025-06-25 | — |

CONFIRMED across the board except open-issue count: the original claimed 17 open issues;
the real number is **12** (CORRECTED). Everything else — stars, archived status, versions,
push dates, and the observation that `cable_ready` has stalled relative to its dependent —
checks out exactly.

**Verdict (unchanged, judgment):** not dead, but Turbo 8's built-in idiomorph morphing
subsumes the headline value proposition. Nothing here to steal that Turbo Streams +
ActionCable don't already cover. (Consistent with `05-ecosystem-survey.md`.)

---

## 5. htmx 2.x, fixi.js, µJS, Twinspark, Triptych

- **htmx**: 48,968★ CONFIRMED. Stable release **v2.0.9 (2026-04-20)** on GitHub, but npm's
  `dist-tags.latest` is **2.0.10** (published 2026-04-21) — one point release ahead of the
  GitHub release the original cited. CORRECTED nuance. **v4.0.0-beta6 (2026-07-23) CONFIRMED**
  — and it lives as a prerelease tag inside the *same* `bigskysoftware/htmx` repo; there is
  no separate `bigskysoftware/htmx4` repo (404 on lookup). npm's `next` dist-tag confirms
  `4.0.0-beta6`. Fetched Carson Gross's ["The fetch()ening"](https://htmx.org/essays/the-fetchening/)
  directly (real date: **Nov 1, 2025**, matching the original's "Nov 2025") and confirmed,
  with direct quotes, every specific claim: explicit-by-default attribute inheritance
  ("*In htmx 4.0, attribute inheritance will be explicit by default rather than implicit*"),
  no locally-cached history ("*No Locally Cached History... htmx 2.0 stores history in local
  cache... snapshotting the DOM is often brittle*"), and SSE/streaming + idiomorph morphing
  folded into core ("*Streaming Responses & SSE in Core*" / "*Morphing Swap in Core*"). The
  ["Future of htmx"](https://htmx.org/essays/future/) essay also CONFIRMED — real URL is
  `/essays/future/` (not `/essays/future-of-htmx/`), dated Jan 1, 2025, and **co-authored by
  Carson Gross and Alex Petros** (the original didn't name an author, so no correction, just
  added detail); content confirms the "stability as a feature" stance and the Triptych
  reference verbatim.
- **fixi.js**: `bigskysoftware/fixi`, **1,316★ CONFIRMED**, unversioned (no tags). Raw size
  of `fixi.js` = **3,473 bytes exactly**, gzipped = **1,473 bytes exactly** — CONFIRMED via
  direct source download. **6 attributes CONFIRMED** by grepping the source itself:
  `fx-action`, `fx-ignore`, `fx-method`, `fx-swap`, `fx-target`, `fx-trigger`.
- **µJS** (mujs.org): repo is `Digicreon/mujs`, **222★**, pushed 2026-05-04 (original gave no
  star count, so this is new information, not a correction). Show HN thread CONFIRMED to
  exist — "Show HN: µJS, a 5KB alternative to Htmx and Turbo with zero dependencies" — with
  **161 points matching exactly**, but **92 comments, not 24 as claimed** (CORRECTED). Also
  CONFIRMED mentioned on htmx's own alternatives page (grepped the live page HTML). The
  mujs.org-vs-mujs.com disambiguation itself was not independently re-verified this pass —
  UNVERIFIED, but low-risk/plausible.
- **Twinspark**: **CORRECTED — repo ownership has moved.** `piranha/twinspark-js` now
  resolves to `sansolovyov/twinspark-js` (stars and push date otherwise match exactly: 468★,
  pushed 2026-07-13). "8KB" CONFIRMED verbatim from the README ("*only 2000 lines of code and
  only 8KB .min.gz*"). The "explicitly rejects htmx's implicit attribute inheritance" framing
  is CONFIRMED indirectly — the README's own design-philosophy line reads *"no surprising
  behavior (whatever is declared on top of your DOM tree will not affect your code)"* — the
  literal word "inherit" doesn't appear, but the positioning is accurate.
- **Triptych**: `alexpetros/triptych`, **260★ CONFIRMED**, pushed 2026-08-01. The dual
  reference to "alexpetros.com/triptych" is explained by a domain migration —
  alexpetros.com now redirects to alexanderpetros.com — not a doc error.
- Also (lower priority, spot-checked): **Alpine AJAX** (`imacrayon/alpine-ajax`) **1,139★
  CONFIRMED exactly**. **Nomini: UNVERIFIABLE** — could not locate the correct repo slug in a
  reasonable number of guesses without web search (tried `nichtsam/nomini`,
  `epicweb-dev/nomini`, `kentcdodds/nomini`, `nomini/nomini`, `nomini-js/nomini`, all 404).
  Don't cite the 189★ figure until the real repo is found.
- **Turbo outside Rails**: `hotwired-laravel/turbo-laravel`, **840★, v2.6.0 (2026-02-28),
  CONFIRMED exactly**, actual last push 2026-05-25.

**Critique articles, both CONFIRMED to exist and support the claims:**
- ["MESH: I tried HTMX, then ditched it"](https://ajmoon.com/posts/mesh-i-tried-htmx-then-ditched-it)
  (ajmoon.com) — date CONFIRMED exact (2025-09-18). Quote: *"HTMX leaves it up to the
  developer to impose discipline on their code, however they see fit."* HN skepticism
  CONFIRMED via the actual thread (story id 45345950, 183 comments) — e.g. commenter
  nicr_22: *"My worry with MESH is that many endpoints might become a (sorry) mess."*
- ["Less htmx is More"](https://unplannedobsolescence.com/blog/less-htmx-is-more)
  (unplannedobsolescence.com) — date CONFIRMED exact (2024-10-02). Quote: *"While htmx is
  amazing for targeted page updates, I highly discourage using it to take over all page
  navigation."* The "Turbo's opposite default praised as more consistent" HN characterization
  was not independently re-checked this pass — UNVERIFIED (lower priority, not one of the
  four flagged priorities).

Claim: nothing genuinely new and significant emerged in 2025–2026 beyond Datastar, htmx 4,
and Inertia maturing. — Not independently falsifiable without broad web search; left as an
editorial judgment, not a checked fact.

---

## Verification log

**What was checked, and how (2026-08-15):**

1. **§1 platform primitives (17 features + interest invokers)** — fetched each MDN page's
   live Baseline badge via `curl_chrome145` (not just `WebFetch`'s summarizer, which was
   observed dropping badge text on several pages), then cross-checked exact per-engine
   version numbers against the `web-features` dataset (the literal upstream source MDN's own
   badges and caniuse are both generated from). Where a canonical URL had moved (MDN did a
   large `/Reference/` restructure at some point before 2026-08-15), followed the 301 to the
   real page rather than trusting the guessed URL.
2. **§1a `@starting-style` + `allow-discrete`** — fetched both MDN pages directly, plus the
   `overlay` property page (revealed a real, previously-unflagged caveat: Chromium-only,
   blocks fully-cross-browser popover/dialog exit transitions specifically). Read the spec
   behavior for dynamically-inserted elements from MDN's own documented example
   (`document.createElement` + `.append()` triggering `@starting-style`) and reasoned from
   that — plus how Turbo Streams and Turbo's morph both perform DOM mutation — to the
   Turbo-Stream-insertion and Turbo-Stream-removal verdicts. The code example was built from
   MDN's own documented pattern, adapted to avoid the `overlay` dependency so it's honestly
   cross-browser today.
3. **§2–§4 numbers** — `gh repo view <owner>/<repo> --json stargazerCount,pushedAt,
   latestRelease,isArchived` for every repo; `gh api repos/.../contents/...` to walk the
   Datastar monorepo's `sdk/` directory and confirm the Ruby SDK's real location and gem
   name; `curl` against `rubygems.org/api/v1/gems/*.json` and `registry.npmjs.org/*` for gem
   and npm package data.
4. **§4–§5 sourced essays/posts** — fetched each article directly (`curl_chrome145` /
   `WebFetch`), pulling verbatim quotes rather than trusting titles/dates from memory. Where
   a claimed post could not be found (Evil Martians' 2025-04-14 date), checked the site's
   full sitemap and Atom feed before concluding it doesn't exist, rather than guessing.
5. **Not independently re-verified this pass** (out of scope of the four stated priorities,
   flagged inline where they occur rather than silently dropped): the HN launch-thread
   figures for inertia-rails (142pts/44 comments); the "Turbo's opposite default praised" HN
   characterization for the "Less htmx is More" thread; the closing claim that nothing
   significant beyond Datastar/htmx4/Inertia emerged in 2025–2026 (an editorial judgment, not
   a checkable fact); the mujs.org-vs-mujs.com disambiguation.

**Corrections found that materially change the doc's conclusions:**
- Two "Chromium-only" claims were wrong in the specific engine named (cross-document View
  Transitions and scroll-driven animations both have Safari support; Firefox is the actual
  holdout in both cases) — this matters because it changes which engine crosswire should
  watch for these features to become safe.
- `text-wrap: pretty` was wrongly lumped in with `text-wrap: balance` under one "Baseline
  2024" status — they are not the same feature and `pretty` is not Baseline at all (no
  Firefox support).
- `popover`/`popovertarget` was claimed "widely available ~2024" but is actually only
  "newly available" since Jan 2025, blocked from "widely" by a live Safari iOS bug — a
  materially different risk profile than "widely available" implies.
- One Evil Martians citation date (2025-04-14) does not correspond to any real post and
  should not be cited; five real Inertia-rails posts exist and are listed above instead.
- Datastar's Ruby SDK is Rack-level, not Rails-branded — the gem is `datastar`, not
  `datastar-rails`, and no Rails-specific gem exists at all.
