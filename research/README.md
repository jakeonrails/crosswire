# Crosswire research corpus

Research conducted 2026-08-15 for **crosswire** — a library, recipe collection, and skills
repo for building rich UI "The Rails Way" with Hotwire, without React.

**63,410 lines across 21 files.** Every file was produced by a dedicated agent
reading primary sources: cloned repo source over documentation, live APIs over recalled
facts, maintainer comments over blog posts.

---

## Inventory

| # | File | Lines | What it is |
|---|---|--:|---|
| 01 | `01-30-days-of-hotwire.md` | 5,513 | @itsameandrea's 30 tips, code transcribed from his companion repo's per-day commits (better than the tweet screenshots) |
| 02 | `02-turbo-deep-dive.md` | 2,069 | Turbo reference built from cloned `hotwired/turbo` + `turbo-rails` source. 26-event table, 6 ordering cheat sheets, 40 gotchas |
| 03 | `03-stimulus-deep-dive.md` | 4,392 | Stimulus reference + **22-pattern composition catalog** + 42 candidate controllers |
| 04 | `04-hotwire-native.md` | 2,530 | Hotwire Native, path config, bridge components, 13 gotchas |
| 05 | `05-ecosystem-survey.md` | 1,556 | 47 packages verified live via GitHub/RubyGems/npm APIs, each with adopt/study/avoid verdict |
| 06 | `06-blog-corpus.md` | 9,656 | 196 annotated articles, 300 URLs, grouped by theme |
| 07 | `07-problem-mining.md` | 1,951 | **60 ranked questions, 18 pain points, 195 recipe candidates.** SO API (238 answers), Discourse (90 threads), GitHub (115 threads), HN |
| 07b | `07b-reddit-mining.md` | 450 | Reddit via the Arctic Shift archive (reddit.com blocks everything else). 94 threads, ~1,090 comments, plus the sentiment read |
| 08 | `08-ui-pattern-catalog.md` | 11,528 | **119 UI patterns**, each decomposed into primitives. 41 need no JS at all. The reconciled 39-primitive vocabulary lives here |
| 09 | `09-books-and-courses.md` | 193 | Books/courses with real prices and buy/skip verdicts |
| 10 | `10-testing-a11y-perf-tooling.md` | 2,713 | Testing stack, a11y audit of existing libs, perf, debugging |
| 11 | `11-production-codebases.md` | 1,427 | **210 controllers censused** across 10 real codebases, classified generic vs one-off |
| 12 | `12-cross-framework-and-the-case.md` | 1,872 | HTMX/Unpoly/LiveView/Livewire ideas to steal + the honest anti-Hotwire case |
| 13 | `13-marcoroth-ecosystem.md` | 1,252 | Marco Roth's complete works, verified |
| 14 | `14-morphing-dossier.md` | 1,262 | Morphing consolidated: mechanism, the values conflict, 8 breakages, decision rubric |
| 15 | `15-sean-doyle-corpus.md` | 9,639 | All 25 branches of `thoughtbot/hotwire-example-template` with verbatim code |
| 16 | `16-three-tier-architecture.md` | 2,119 | Stimulus / ES classes / custom elements — the undocumented tiering, with a decision rule |
| 17 | `17-helper-layer-design.md` | 1,715 | **The architecture decision**: helpers + partials, tested merge implementation, naming |
| 18 | `18-platform-primitives.md` | 382 | CSS/HTML features that obsolete Stimulus controllers — every claim verified |
| 19 | `19-stimulus-aria-widgets-assessment.md` | 306 | Assessment of the one real prior-art counterexample |
| 20 | `20-view-layer-reconsidered.md` | 876 | Re-litigation of the ViewComponent/Phlex call, with all five renderers built and measured |

**See also `docs/BUILD-LOG.md`** — the findings that came out of *building* the library
rather than researching it. Different failure mode, different lessons: research errors are
wrong claims, build errors are code that never ran.

---

## The load-bearing findings

Ordered by how much they shape what crosswire should be.

1. **Generic controllers are not achievable at scale without a helper layer.** (11, 17)
   A controller stays generic only if class names, URLs, IDs and bindings are injected from
   outside. Doing that by hand in ERB is painful enough that people give up and write
   app-specific controllers. **Six independent codebases** pair controllers with ERB helpers
   — 37signals, Solidus, Avo, Administrate, `hotwire_combobox`, `stimulus_aria_widgets` —
   and **not one documents the convention.**

2. **The composable-primitive thesis holds, measured.** (11)
   62% of 210 production controllers are generic; 73% across 37signals' own apps.
   Refinement: **"small" and "generic" are different axes, and only generic matters** —
   Writebook's `arrangement_controller` is 403 lines and completely domain-free.

3. **Ship as a Rails engine gem, unbundled per-controller ESM, plain JS.** (10, 17)
   `stimulus-loading.js` lazy-registers via `import("${under}/${name}_controller")`, so a
   single bundle **cannot** be lazy-loaded. TypeScript breaks `pin_all_from`. And engine
   views are on the lookup path so a consumer overrides a partial by creating a file —
   **ViewComponent does not participate in that mechanism at all** (it globs from the
   component's own source directory), so its override story is "edit all your call sites."

4. **Three tiers, not two.** (16)
   Stimulus = wiring; plain ES classes = logic; custom elements = components. Lexxy is
   12,316 lines with **zero Stimulus** and 71% plain classes; Campfire is 59%. Decision rule
   in file 16. *"Stimulus is the wiring tier, not the component tier."*

5. **Rule 0 beats every other rule: can the server do it?** (16, 18)
   Turbo Frame/Stream, `<dialog>`, `popover`, `<details>`, CSS. This kills more component
   candidates than all other rules combined.

6. **The morph/Stimulus-values conflict is officially won't-fix.** (03, 14)
   turbo#1210 open 2y5m, one maintainer comment. stimulus#801 closed, **converted to a
   discussion and locked**. brunoprietog: *"This is by design."* Combined with Stimulus's
   3-year release freeze, this is permanently ours to solve. Two teams independently
   reinvented the same fix and no maintained package fills the niche.

7. **`turbo_stream.replace(target, method: :morph)` is the right default**, not page-level
   morphing. (13, 11, 14) — three independent lines of evidence converge:
   Marco Roth's granularity critique, Fizzy's actual production usage (targeted only,
   never page-level), and the morphing dossier's rubric.

8. **Nobody maintains accessible Hotwire components.** (10, 12, 19)
   `stimulus-components`' 32 packages contain `aria-expanded` as their *only* ARIA
   attribute. `tailwindcss-stimulus-components/src/modal.js` is 56 lines with zero
   `focus`/`Escape`/`inert`. The one real counterexample (`stimulus_aria_widgets`, by a
   Turbo maintainer) is APG-faithful but **never published, abandoned Dec 2023**.
   → The gap is not knowledge. It is **packaging and maintenance.**

9. **Stimulus is functionally frozen.** (05, 12)
   No release since v3.2.2 (Aug 2023). ~75 commits in 3 years, mostly dependabot. A
   memory-leak fix merged 2026-06-10 is still unreleased. Assume **no upstream help.**

10. **Turbo 8 killed a whole ecosystem category.** (05)
    cable_ready, stimulus_reflex, turbo_boost, turbo_ready, turbo-morph, mrujs — dormant or
    abandoned. A large fraction of the 2021–2023 blog corpus teaches a stack that no longer
    exists. Treat pre-2024 material as suspect by default.

---

## Corrections log

Things widely repeated online that are **false**, verified against source. These are recipe
material — each one is someone's lost afternoon.

| Claim | Reality | Src |
|---|---|---|
| `redirect_to path, turbo_frame: "_top"` | **Does not exist.** `turbo-rails#367` open since 2022 (49 comments; dhh rejected the original approach in 2023 — the *design conversation* stalled, not readership). Sean Doyle's `Turbo::FrameRedirectable` (~25 lines, flash-hop) is the working answer, unpublished outside a demo branch | 07, 15 |
| `Turbo.clearCache()` | Removed → `Turbo.cache.clear()` | 07, 10 |
| `data-turbo-cache="false"` | **Does not exist** in Turbo 8 → `turbo-cache-control` meta / `data-turbo-temporary` | 07, 10 |
| `reconnect() { this.disconnect(); this.connect() }` | Causes **exponential listener growth** | 07, 14 |
| `turbo:morph@window` listener | Fires page-wide — 188 Trix editors hung a browser. Use element-scoped `turbo:morph-element` | 14 |
| Dummy query param forces a replace | Dead since PR #1079 — the predicate compares `pathname` only | 14 |
| "Morphing preserves client-side state" (Marco Roth, 2024) | Preserves **DOM** state; **clobbers declarative attribute state**, which is where Stimulus values live | 13 |
| `data-turbo-permanent` always needs an `id` | Only on the Drive/Bardo path. **Under morph, no `id` required** | 14 |
| Hotwire ships less JS than React | **Turbo+Stimulus 60,715 B gzip vs React+ReactDOM 45,131 B** — ~35% larger. True only at app-bundle level | 12 |
| Need a preload/prefetch controller | Turbo 8 ships hover prefetch **on by default** (100 ms delay, LRU 1, 10 s TTL) | 12, 02 |
| Alpine's `x-transition` needs porting | CSS `@starting-style` + `allow-discrete` covers enter + stream-inserted content. **Not** exit-on-remove — that's a spec-level limit needing one small hook | 18 |
| `:hotwire_native` request variant | Does not exist. Nor `_status` nav helpers, nor `<meta name="bridge-components">` | 04 |
| Morph fires on any same-page update | Requires pathname match + `action === "replace"`. **Query string ignored** — filtered/paginated pages silently don't morph | 02, 14 |
| `morphkit` is Marco Roth's | It is Jaksa Malisic's React Native library. `debounced` is Nate Hopkins' | 13 |
| ONCE code is source-available-not-open | Campfire + Writebook are **MIT**. But `basecamp/fizzy` is "O'Saasy" (non-compete) — learn, don't vendor | 11 |
| Evil Martians Inertia post (2025-04-14) | **Fabricated citation.** Five real posts exist with other dates | 18 |

---

## Undocumented techniques worth publishing

Found in source or dead branches, absent from the published corpus:

- **`Turbo::FrameRedirectable`** — server-driven frame breakout via a flash hop (15)
- **Zero-JS nested forms** — add/remove buttons *are* form fields; `formmethod="get"` round-trip. No controllers at all. Includes the implicit-submission hazard fix (15)
- **The `connected` boolean attribute** — Trix/Lexxy's morph-survival trick for custom elements. Server never renders it, so a morph stripping it *is* the signal (16)
- **`ignoringBriefDisconnects`** — one rAF of patience before unsubscribing a cable channel (11)
- **Inline `<turbo-stream>` inside a `<turbo-frame>`** — patch the rest of the page during a frame navigation, no WebSocket, no second request (15)
- **`<fieldset disabled>` + `aria-controls`** — one source of truth for visibility, keyboard reachability, and whether values submit; the a11y annotation is load-bearing (15)
- **Solidus's `stimulus_id`** — identifier derived from the component's own path, so Ruby and JS cannot drift (17)
- **`token_list` is idempotent under re-merge** — undocumented; what makes layered attribute merging safe (17)
- **The `<dialog>` + morph top-layer deadlock** — an 8-line maintainer-written fix exists, never merged. ~1 hour to contribute upstream (14)
- **`data-controller` as a stored-XSS surface** — Lexxy forbids it in its sanitizer; user rich text can wire controllers into a *viewer's* session (16)

---

## Open decisions for synthesis

1. Which ~30 controllers form v1's vocabulary? (42 candidates in 03, decomposition in 08)
2. Do we build the `preserve` primitive for turbo#1210? (validated demand, no maintained package)
3. Lookbook previews without ViewComponent — the one unverified weak point in the file-17 design
4. Gem name/scope, and how "skills" + the GitHub Pages site relate to the gem
5. Do we adopt a declarative signals layer (Datastar-inspired)? No Rails SDK exists
6. Upstream contributions: the `<dialog>`/morph fix, and a stimulus-lsp CI linter (~40 lines, both halves exist)

---

## Coverage gaps — do not over-read this corpus

- **No named large-company React→Hotwire migration with hard numbers exists publicly.** Best-quantified cases are htmx/Django and are labelled analogous throughout (12)
- Reddit was unreachable for file 07; file 07b backfills via the PullPush archive (dates limited by archive coverage)
- Stack Overflow **HTML** blocks curl-impersonate; the **API** works. Sean Doyle has no SO presence — verified, not assumed (15)
- Conference talk transcripts largely not pulled; RailsConf 2024 auto-captions are corrupted (13)
- GoRails episode bodies are paywalled — titles/dates/techniques only (06)
- File 16's three-tier rule is **a synthesis from code, not a community consensus.** Ship it with its evidence attached (16)
