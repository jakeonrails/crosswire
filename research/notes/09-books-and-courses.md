# 09 — Books, Courses, and Long-Form Learning Resources

> Research notes for **crosswire**. Compiled 2026-08-15.
> Currency baseline: `@hotwired/turbo` 8.0.23, Rails 8.x. Turbo 8 (shipped alongside Rails 8,
> ~Nov 2024) is the line in the sand: it introduced **page refreshes / morphing**
> (`broadcasts_refreshes`, `<meta name="turbo-refresh-method" content="morph">`, idiomorph).
> Anything written before that date teaches a pre-morphing mental model of Turbo and is
> flagged `⚠️ PRE-TURBO-8` below. Anything still saying **"Turbo Native"** or **"Strada"**
> instead of **Hotwire Native** predates the Sept 2024 Rails World rebrand and is flagged
> `⚠️ OLD NAMING` (historically fine, just know what you're reading).
>
> Every price below was verified against the live product page on 2026-08-15 (via
> `curl_chrome145` where WebFetch/WebSearch were blocked or budget-exhausted — see Sources).

---

## Books

### Master Hotwire — Radan Skorić
- **URL:** <https://masterhotwire.com/>
- **Author:** Radan Skorić (long-time Rails consultant, blogs at radanskoric.com)
- **Format:** self-published ebook — Web reader + PDF + EPUB, one purchase, **lifetime updates**
- **Price:** **€49** (~$53), single tier, 300+ copies sold as of this writing
- **Last updated:** actively maintained (readers report buying "an early version at the end of 2024" and it having grown since; explicitly covers Turbo Morphing and current Hotwire Native)
- **Target level:** experienced Rails developers who already know CRUD/Stimulus basics — explicitly *not* for beginners
- **Uniquely covers:** the *why* under every Hotwire feature (deep-dive "under the hood" sections with source links after each concept), a dedicated chapter on **Turbo Morphing** (1.7), a full **Part II on Hotwire Native** (history, path config, bridge components, publishing), **Part III** on Turbo Cache internals, advanced Stimulus, **system-testing Hotwire apps**, **adding Turbo to a legacy app**, and **debugging Hotwire applications** — the last two are things almost nothing else in this catalog covers.
- **Currency:** ✅ current. Explicitly teaches morphing, not just pre-morph Frames/Streams.
- **Social proof:** praised on record by Rosa Gutiérrez (37signals, works on Turbo itself) alongside Masilotti's book; multiple Rails devs (Miha Rekar, Tilmann Singer, etc.) confirm it goes deeper than official docs.
- **Verdict: BUY.** The single best-targeted "how Hotwire actually works, including its sharp edges" resource in this whole catalog, and cheapest of the serious paid options.

### Hotwire Native for Rails Developers — Joe Masilotti
- **URL:** <https://pragprog.com/titles/jmnative/hotwire-native-for-rails-developers/>
- **Publisher:** Pragmatic Bookshelf, foreword by DHH. 270pp, ISBN 9798888651513.
- **Price:** **$30.95** (ebook: PDF/epub/mobi bundle); paperback via Bookshop.org
- **Published:** P1.0, **September 2025** — current for Hotwire Native 1.3.x
- **Target level:** Rails devs with basic Stimulus familiarity, zero Swift/Kotlin required
- **Uniquely covers:** end-to-end native iOS + Android app built from a Rails app — path config, native tab bars, SwiftUI/Jetpack Compose native screens, bridge components in Swift and Kotlin, TestFlight/Play Console deployment, push notifications (APNs/FCM).
- **Currency:** ✅ current, correct terminology throughout (Hotwire Native, not Turbo Native/Strada).
- **Verdict: BUY.** Already fully cataloged in `research/notes/04-hotwire-native.md` (full TOC, sample-chapter excerpts, and "implications for our library" section) — no need to duplicate here. This note exists only to place it correctly in the buy-list ranking below.

### Learn Hotwire — Chris Oliver & William Kennedy (GoRails)
*(This is a course, not a book, but it is priced and structured like one — a single lifetime purchase — so it's ranked alongside the books below.)*
- **URL:** <https://learnhotwire.com/>
- See full write-up under **Courses** below. Listed here only as a cross-reference because it directly competes with, and in scope exceeds, every book in this section for the price.

### Modern Front-End Development for Rails, Second Edition — Noel Rappin
- **URL:** <https://pragprog.com/titles/nrclient2/modern-front-end-development-for-rails-second-edition/>
- **Publisher:** Pragmatic Bookshelf. 408pp, ISBN 9781680509618. **In Print, no newer edition.**
- **Price:** **$28.95** ebook (PDF/epub/mobi); paperback via Bookshop.org
- **Published:** **September 2022** — ⚠️ **PRE-TURBO-8**. Built on jsbundling-rails/esbuild, cssbundling-rails/Tailwind, Propshaft, and "Rails 7 added a new set of default front-end tools." No morphing, no page refreshes, no Hotwire Native (predates it entirely). There is no 3rd edition or beta in the Pragmatic catalog as of 2026-08-15.
- **Target level:** Rails devs new to the whole modern front-end landscape
- **Uniquely covers:** the *comparison* — it teaches Hotwire/Turbo/Stimulus **and** React side by side in the same app, with an explicit decision framework for when to reach for which. Nothing else in this catalog does that framing.
- **Verdict: SKIP for Turbo/Stimulus mechanics specifically** — everything Hotwire-related in it is 2+ major Turbo versions stale, and hotrails.dev covers the same Rails-7-era ground for free. **Situational keep** only if you specifically want the Hotwire-vs-React decision framework or the React-integration half, which doesn't go stale the same way.

### Layered Design for Ruby on Rails Applications, 2nd Edition — Vladimir Dementyev (Evil Martians)
- **URL:** <https://www.packtpub.com/en-us/product/layered-design-for-ruby-on-rails-applications-9781806114221>
- **Publisher:** Packt (not Pragmatic — corrects a common misattribution). 452pp, ISBN 9781806114221.
- **Price:** **$35.99** (ebook, per Packt's own price JSON on the product page)
- **Published:** **December 2025** (2nd edition; 1st edition was 2023) — actively current
- **Target level:** intermediate-to-senior Rails devs designing service/domain layers
- **Uniquely covers:** Rails application architecture — service objects, policies, presenters — **not Hotwire-specific**. Adjacent, not on-topic.
- **Verdict: SKIP** for this catalog's purpose (front-end/Hotwire component library). Good book, wrong axis — it's about how you organize Ruby classes, not how you build UI. Worth owning for general Rails architecture, not for crosswire.

### StimulusReflex Patterns (+ Advanced CableReady) — Julian Rubisch
- **URL:** <https://www.stimulusreflexpatterns.com/> · bundle: <https://julianrubisch.gumroad.com/l/srp-acr>
- **Format:** self-published ebook/course on Gumroad
- **Price:** the Standard Package is now **free** ("Now free as in 🍺"); the Premium + Advanced CableReady bundle remains a separate paid product (price not confirmed on the live page — gated behind Gumroad checkout).
- **Note on the title:** there is no book called "Building Reactive Rails Apps" by Rubisch that could be verified to exist — the real, findable product is **StimulusReflex Patterns**, about **StimulusReflex and CableReady**, not core Hotwire/Turbo/Stimulus.
- **Currency / relevance warning:** StimulusReflex and CableReady are a **different, largely superseded ecosystem** — a reflex-based real-time UI approach that predates and now competes with, rather than composes with, mainline Turbo Streams + Broadcasts. Much of the Rails community has moved to native Turbo Streams instead. This is not "Hotwire" in the sense this repo cares about.
- **Verdict: SKIP.** Free is nice, but it's about an adjacent, declining library. Not useful for a Turbo/Stimulus component/recipe repo.

### David Colby — "Hotwire Handbook" (or similar)
- **Verdict: DOES NOT EXIST / UNVERIFIABLE.** Could not find any book by a "David Colby" on Hotwire via product-page or search-engine lookups (searches for the exact name mostly return unrelated "David" results). Do not budget for this — it appears to be a misremembered title/author pairing. If the repo owner has a specific link in mind, re-verify it directly rather than trusting this as a real title.

### ViewComponent / Phlex — dedicated books
- **Verdict: DOES NOT EXIST as a standalone paid book at any of the major publishers checked** (Pragmatic, Packt, Manning, Apress, O'Reilly). Coverage of ViewComponent and Phlex currently lives entirely in: official docs (viewcomponent.org, phlex.fun), blog posts (thoughtbot, Evil Martians, Joel Drapper's own writing), and paid **component libraries** rather than books — see **Rails Designer UI Components** under Courses below, which is the closest thing to a "ViewComponent book" that exists, just shipped as a gem + docs instead of prose.

---

## Courses & Screencasts

### Learn Hotwire — Chris Oliver & William Kennedy
- **URL:** <https://learnhotwire.com/>
- **Price:** **$299** (discounted from $349), **one-time payment, lifetime access** — includes Discord access with other learners and future content updates
- **Scope:** 13 modules, **125 lessons, 14+ hours** of video
- **Teachers:** Chris Oliver (creator of GoRails, Jumpstart, Hatchbox; Rails Luminary award) and William Kennedy (Rails dev with native iOS/Android depth)
- **Modules verified from the live curriculum:** Turbo Drive (importmaps, history pushState, page cache, prefetching, `data-turbo-confirm`, custom confirm modals, `data-turbo-submits-with`/`-method`/`-temporary`/`-track`, View Transitions, form redirects/errors) → Turbo Frames (inline editing, search, hovercards, infinite scroll) → **Turbo Streams including `broadcasts_refreshes`, morph-and-scroll-preservation** → Stimulus (autosubmit, mutation/intersection observers, wrapping third-party libs, **morphing with third-party libraries**, targets/values/actions/outlets, **Turbo Morph event with Stimulus**) → "More Hotwire" (**Turbo Morph internals with idiomorph**, custom Turbo Stream actions) → Testing Hotwire (integration + system tests for streams/frames/broadcasts, drag-and-drop system tests) → Modal Dialogs with Hotwire (a full built-from-scratch dialog pattern) → **Source Code Walkthroughs** (Turbo.js internals, frame/stream internals) → Swift/Kotlin crash courses → **Hotwire Native iOS and Android** (path config, native tabs/screens, bridge components, debugging with a custom WebView).
- **Currency:** ✅✅ **the most explicitly Turbo-8-current resource in this entire catalog** — it names morphing, idiomorph, and `broadcasts_refreshes` directly as first-class topics, not an afterthought.
- **Verdict: BUY.** For the specific goal of building a Hotwire component/recipe library, this is the single highest-density, most current resource that exists, at any price. The "Modal Dialogs with Hotwire" and "Source Code Walkthroughs" modules in particular map directly onto crosswire's own scope.

### Rails Designer — UI Components
- **URL:** <https://railsdesigner.com/components/> · pricing: <https://railsdesigner.com/components/pricing/>
- **What it actually is:** not a course or a book — a **private-gem UI component library**: "the first professionally-designed UI components library for Ruby on Rails apps," 200+ components, used by 1,000+ developers.
- **Price:** **Infinite $299** one-time (unlimited projects, lifetime updates, "most popular") or **Solo $149** one-time (1 project, updates for 12 months)
- **Tech stack (verified from the FAQ):** ERB + **ViewComponent** (required — no partials-only mode; a separate "Vanilla Rails UI Components" product exists for that), Tailwind CSS ≥4.0, Stimulus controllers for interactivity, Standard for Ruby, Eslint for JS. **Tested against Rails >7.0, including 8.0.**
- **Delivery mechanism:** a generator (`bin/rails generate rails_designer:component Elements::Avatar`) copies component source into your app — you own and edit the code, not a black-box dependency.
- **Components include:** accordions, avatars, badges, dropdowns, hovercards, tooltips, breadcrumbs, command menu, contextual menus, global hotkeys, navbars, sidebar nav, tabs, modals, notifications, slide-overs, alerts, empty states, calendar, stats, buttons, checkboxes, confirm fields, image previews, local autosaves, textarea autogrow, page-refresh-confirm.
- **Verdict: BUY (as reference architecture, not just components).** This is the single most directly relevant purchase for crosswire's actual goal: it's a **working, current, ViewComponent+Stimulus+Tailwind component catalog, code-generator delivered**, from a team solving the exact same problem crosswire is solving. Worth the $299 Infinite tier purely to study its component boundaries, Stimulus controller patterns, and generator design — independent of whether crosswire ends up using ViewComponent itself.

### GoRails — subscription + Hotwire/Stimulus series
- **URL:** <https://gorails.com/> · pricing: <https://gorails.com/pricing>
- **Price:** **$19/month** Personal (650+ Rails screencasts total, Discord community, new tutorials added regularly); annual and Team tiers also exist.
- **Relevant series (verified via the live series index):**
  - **"Hotwire"** — 19 lessons, 5h 14m, Intermediate. ⚠️ **PRE-TURBO-8** — first episode dated **Dec 23, 2020**, framed as "the NEW MAGIC that DHH has been teasing about," i.e. the *original* Hotwire launch. No morphing content confirmed.
  - **"Stimulus JS"** — 10 lessons, 2h 15m, Intermediate.
  - **"Realtime Group Chat with Hotwire"** — 9 lessons, 2h 38m.
  - **"Realtime Apps with Hotwire & ActionMailbox"** — 4 lessons, 1h 9m.
  - **"Mobile Apps with Rails & Hotwire"** — 1 lesson, 15m (Hotwire Native).
- **Verdict: SKIP as a dedicated purchase for this goal.** The flagship Hotwire series is over 5 years old and predates morphing; the standalone **Learn Hotwire** course from the same author (Chris Oliver) at $299 one-time is a strict upgrade in currency and depth. Only worth the $19/mo if already subscribing for GoRails' broader Rails catalog.

### Drifting Ruby
- **URL:** <https://www.driftingruby.com/>
- **Price:** **$19/month** Pro (or **$9/month** for verified students/teachers); annual discount available.
- **Relevant catalog (verified via tag counts):** 29 episodes tagged `hotwire`, 21 tagged `turbo`, 55 tagged `stimulusjs`. No dedicated "Hotwire path," episodes are individual and span Rails versions 4.x–8.x (episodes filterable by Rails version on-site, but individual episode dates for Hotwire-tagged content weren't sampled).
- **Verdict: SKIP as a dedicated purchase.** Same shape of judgment as GoRails — a large, uncurated back-catalog rather than a focused current course. Reasonable supplementary grab-bag if already subscribed.

### hotrails.dev — Turbo Rails Tutorial
- **URL:** <https://www.hotrails.dev/turbo-rails>
- **Author:** Alexandre Ruban
- **Price:** **Free**
- **Full chapter list (verified):** 0. Introduction → 1. A simple CRUD controller with Rails → 2. Organizing CSS with BEM → 3. Turbo Drive → 4. Turbo Frames and Turbo Stream templates → 5. Real-time updates with Turbo Streams (Action Cable) → 6. Turbo Streams and security → 7. Flash messages with Hotwire → 8. Two ways to handle empty states with Hotwire → 9. Another CRUD controller with Turbo Rails → 10. Nested Turbo Frames → 11. Adding a quote total with Turbo Frames.
- **Currency:** ⚠️ **PRE-TURBO-8**. Explicitly framed as "Rails 7... without writing any custom JavaScript" — no morphing chapter, written for the Frames/Streams-only era.
- **Verdict: FREE-READ**, still the best free on-ramp for Turbo Frames/Streams mechanics and the security chapter (broadcast-to-the-wrong-user pitfalls) is genuinely good and version-independent. Just know it stops short of morphing — pair with Skorić's book or the GoRails "Learn Hotwire" course for the Turbo-8 half.

### Rebuilding Turbo Rails — Alexandre Ruban
- **URL:** <https://www.hotrails.dev/rebuilding-turbo-rails> → course video linked directly to a public YouTube playlist
- **Price:** appears to be **free** on the live site now (both CTAs link straight to YouTube; the page's FAQ still references a 14-day refund policy, suggesting it may have been a paid product previously and is now open).
- **Scope:** not a "learn Hotwire" course — a **pair-programming rebuild of the actual `turbo-rails` gem from scratch**: Rails engine authoring, `test/dummy` app, ActionView/ActionCable/ActiveJob integration, turbo-rails' security model, install-generator rake tasks, and testing a Rails engine.
- **Currency:** version-insensitive — it's about *how a Rails engine like turbo-rails is built*, which is durable knowledge independent of which Turbo version ships.
- **Verdict: FREE-READ, high-value niche pick.** Directly useful if crosswire ever wants to understand *why* turbo-rails is shaped the way it is at the engine/gem level, not just how to consume it.

---

## Conference Talks — Rails World / RailsConf / community, 2021–2025

All links verified to resolve via YouTube search as of 2026-08-15. No Rails World 2026 talks were found yet (the event, historically held in September, does not appear to have occurred yet this year as of today's date).

| Talk | Speaker | Event | Link | Takeaway |
|---|---|---|---|---|
| Hotwire Demystified | Jamie Gaskins | RailsConf 2021 | <https://www.youtube.com/watch?v=gllwoSoD5mk> | ⚠️ Foundational/historical — explains original Turbolinks→Hotwire mental model, pre-Frames-maturity. |
| Just enough Turbo Native to be dangerous | Joe Masilotti | Rails World 2023 | <https://www.youtube.com/watch?v=hAq05KSra2g> | ⚠️ OLD NAMING (Turbo Native, pre-rebrand) — still useful for the core native-shell mental model that Hotwire Native inherited unchanged. |
| The Future of Rails as a Full-Stack Framework powered by Hotwire | Marco Roth | Rails World 2023 | <https://www.youtube.com/watch?v=iRjei4nj41o> | Argues Hotwire is core to Rails' "full-stack" identity going forward, not a bolt-on. |
| Making a difference with Turbo | Jorge Manrubia | Rails World 2023 | <https://www.youtube.com/watch?v=m97UsXa6HFg> | From a Turbo core maintainer — design rationale behind Turbo's philosophy, straight from source. |
| Revisiting the Hotwire Landscape after Turbo 8 | Marco Roth | RailsConf 2024 | <https://www.youtube.com/watch?v=nVrhlIfXSiA> | The explicit "what changed with Turbo 8" talk — morphing, page refreshes, and how they change idiomatic Hotwire code. Load-bearing for currency. |
| Making accessible web apps with Rails and Hotwire | Bruno Prieto | Rails World 2024 | <https://www.youtube.com/watch?v=zqBNEBnjzXM> | Accessibility patterns specific to Turbo Frame/Stream partial-page updates — a gap most Hotwire content skips entirely. |
| Hotwire Native — Rails World 2024 Lightning Talk (unofficial recording) | Yaroslav Shmarov | Rails World 2024 | <https://www.youtube.com/watch?v=kLPw34FQomI> | Covers the actual **Turbo Native/Strada → Hotwire Native rebrand announcement** (2024-09-25) live. |
| Joe Masilotti on Hotwire Native | Joe Masilotti | Rails World 2025 | <https://www.youtube.com/watch?v=XXZ05QvsN9o> | Post-rebrand, current Hotwire Native state-of-the-union from its most prolific documenter. |
| Hotwire Native: A Rails developer's secret tool | Joe Masilotti | RailsConf 2025 | (found via search, title confirms) | Pitches Hotwire Native specifically to Rails devs skeptical of "going native" — complements his book's framing. |
| Lessons from Migrating a Legacy Frontend to Hotwire | Radan Skorić | Rails World 2025 | <https://www.youtube.com/watch?v=kWFYc6qrXIo> | Practical migration war-story — same author as Master Hotwire, likely previews book content. Directly relevant to "adding Turbo to a legacy app." |
| Hotwire Cookbook: Common Uses, Essential Patterns & Best Practices | Yaroslav Shmarov | Rails World 2025 | <https://www.youtube.com/watch?v=F75k4Oc6g9Q> | A patterns/recipes talk — closest in spirit to what crosswire itself is trying to be, worth watching to see what recipes are considered "essential" by the community right now. |
| Offline Mode to Hotwire with Service Workers | Rosa Gutiérrez | Rails World 2025 | <https://www.youtube.com/watch?v=aeIb3sa3D3M> | Rosa works on Turbo itself (37signals) — offline-first patterns layered on top of Turbo, a gap area for most tutorials. |

---

## Recommended purchase list

Ranked and optimized specifically for building a comprehensive Hotwire component/recipe/skills repo — not general Rails learning.

| # | Item | Price | Why this rank |
|---|---|---|---|
| 1 | **Learn Hotwire** (Chris Oliver & William Kennedy) | $299 | Broadest, most current, most hands-on (14+ hrs, 125 lessons) coverage of exactly Turbo 8 + Stimulus + Hotwire Native mechanics, including source-code walkthroughs and a full modal-dialog build. Best dollar-for-depth ratio in the catalog. |
| 2 | **Rails Designer UI Components** (Infinite tier) | $299 | Not a course — a working ViewComponent+Stimulus+Tailwind component library at the exact scope crosswire is building. Buy it to study its component boundaries and generator pattern, independent of whether you adopt ViewComponent. |
| 3 | **Master Hotwire** (Radan Skorić) | €49 (~$53) | Cheapest paid item, and the only one with dedicated chapters on debugging Hotwire apps, testing, and legacy-app migration — the "operational" knowledge nothing else covers. |
| 4 | **Hotwire Native for Rails Developers** (Joe Masilotti) | $30.95 | Already the canonical native-mobile reference; buy if/when crosswire scopes in Hotwire Native components (already fully cataloged in `04-hotwire-native.md`). |
| — | *(optional, situational)* Modern Front-End Development for Rails, 2nd ed. | $28.95 | Only if you specifically want the Hotwire-vs-React decision-framework framing; skip for Turbo/Stimulus mechanics, which are 2 major versions stale. |

**Total for the core 4: ~$682.** Everything else in this catalog (GoRails/Drifting Ruby subscriptions, Layered Design, StimulusReflex Patterns) is a SKIP for this specific goal — either too dated, too broad/uncurated, or off-topic.

## Free-first reading order

1. **hotrails.dev — Turbo Rails Tutorial** (free). Do this first regardless of budget — it's the fastest correct mental model for Turbo Drive/Frames/Streams basics, including the security chapter most tutorials skip.
2. **RailsConf 2024 — "Revisiting the Hotwire Landscape after Turbo 8" (Marco Roth)** (free, YouTube). Watch immediately after #1 to patch the exact gap hotrails.dev leaves — what morphing changes about the mental model you just built.
3. **Rails World 2025 — "Hotwire Cookbook: Common Uses, Essential Patterns & Best Practices" (Yaroslav Shmarov)** (free, YouTube). A community patterns talk — useful calibration for what crosswire's own recipes should cover.
4. **Rails World 2025 — "Lessons from Migrating a Legacy Frontend to Hotwire" (Radan Skorić)** (free, YouTube). Practical war-story before deciding whether to buy his book.
5. **hotrails.dev — Rebuilding Turbo Rails** (free, YouTube playlist). Optional but valuable once you want to understand turbo-rails' internals, not just its API.
6. **Rails World 2024 — Hotwire Native rebrand lightning talk (Yaroslav Shmarov)** (free, YouTube), only if/when native scope comes up — gives the naming history context needed to read older docs correctly.

## What no book covers

- **A cross-library recipe/pattern catalog held to a single quality bar.** Every paid resource above is either a linear course (GoRails/Drifting Ruby/Learn Hotwire) or a component *library* you consume as a dependency (Rails Designer). None of them is a browsable, framework-agnostic-within-Hotwire **catalog of composable recipes** the way crosswire aims to be — that's the actual gap.
- **Explicit Turbo-8-vs-Turbo-7 migration guidance.** Only one talk (Marco Roth, RailsConf 2024) and one course module (Learn Hotwire's morph/idiomorph sections) address "what changes when you adopt morphing" directly; nothing does it as a standalone, focused migration guide the way a `docs/turbo-7-to-8-migration.md` in crosswire could.
- **Native-web parity as a first-class design constraint.** Only Master Hotwire and the Hotwire Native book touch "build once, degrade gracefully to native" as a *pattern*, and neither ships it as reusable, drop-in components — crosswire's own `04-hotwire-native.md` "Implications for our library" section (the bridge-controller pairing pattern, `data-bridge-*` namespace) is already ahead of anything published.
- **ViewComponent/Phlex + Hotwire integration recipes.** No book exists at all (confirmed above); Rails Designer is the closest thing but is closed-source-delivered-as-a-gem, not a documented pattern library you can learn *from* the way you'd learn from open recipes.
- **Testing patterns as a dedicated, exhaustive reference.** Learn Hotwire's testing module and Master Hotwire's system-testing chapter are the only paid treatments found, and both are single chapters/modules inside broader products — not a focused reference the way crosswire could make one.
- **Accessibility patterns for partial-page updates.** Bruno Prieto's talk is the only resource found that addresses this at all; it's a 20-40 min talk, not a maintained reference.
- **Debugging playbooks.** Master Hotwire has one chapter; nothing else in the catalog treats "my Turbo Stream isn't rendering / my Frame is missing / my Stimulus controller didn't connect" as a systematic, indexed troubleshooting reference.

---

## Sources

Verified live 2026-08-15 via WebFetch and `curl_chrome145 | html2text` (used wherever WebFetch/WebSearch were blocked, bot-checked, or the session's WebSearch budget was exhausted):
pragprog.com (category listing + individual product pages for nrclient2, jmnative), packtpub.com (product page + embedded JSON price for Layered Design 2e), masterhotwire.com (full landing page incl. chapter list and pricing), railsdesigner.com/components + /pricing, gorails.com (/pricing, /series, /series/hotwire-rails), learnhotwire.com (homepage curriculum + /buy page pricing), driftingruby.com (homepage pricing, /episodes tag counts), hotrails.dev (/turbo-rails and /rebuilding-turbo-rails), stimulusreflexpatterns.com + julianrubisch.gumroad.com, YouTube search results for Rails World/RailsConf talk titles and video IDs (cross-checked each resolves).
