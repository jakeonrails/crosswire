# The Hotwire Ecosystem: A Survey

**Compiled 2026-08-15.** Every version number, release date, star count, download figure, and licence below was verified live against the GitHub API, the RubyGems API, the npm registry, and the projects' own sources on that date — nothing here is from training data. Source code claims are cited to specific commits where it matters.

**Purpose:** to know exactly what already exists before crosswire builds anything, and to be honest about what's alive, what's dying, and what nobody has built.

---

## Table of contents

1. [hotwire.io/ecosystem — the community index](#1-hotwireioecosystem--the-community-index)
2. [The core: Hotwire itself](#2-the-core-hotwire-itself)
3. [Stimulus Components (the closest prior art)](#3-stimulus-components-the-closest-prior-art)
   - [stimulus-components (monorepo) — full 32-component catalogue](#stimulus-components-monorepo)
   - [tailwindcss-stimulus-components (the ancestor)](#tailwindcss-stimulus-components-the-ancestor)
4. [Rendering approaches & component libraries](#4-rendering-approaches--component-libraries)
   - [ViewComponent vs Phlex](#41-the-two-rendering-approaches)
   - [Free / open component libraries](#42-free--open-component-libraries)
   - [Commercial component products](#43-commercial-component-products)
   - [Composition & form helpers](#44-composition--form-helpers)
5. [Turbo & reactivity extensions](#5-turbo--reactivity-extensions)
6. [Form, input & data gems that pair with Hotwire](#6-form-input--data-gems-that-pair-with-hotwire)
   - [Forms & rich text](#61-forms--rich-text) · [File uploads](#62-file-uploads) · [Pagination, search & tables](#63-pagination-search--tables) · [Admin frameworks — what to steal](#64-admin-frameworks--what-to-steal)
7. [JavaScript libraries commonly wired to Stimulus](#7-javascript-libraries-commonly-wired-to-stimulus)
   - [Health & wrapper matrix](#71-health--wrapper-matrix) · [GitHub web components](#72-github-web-components-github) · [Hand-rolled wrapper recipes](#73-hand-rolled-wrapper-recipes-for-the-libraries-with-no-wrapper) · [Date pickers](#74-the-date-picker-situation-there-is-no-good-answer) · [View Transitions](#75-turbo--the-view-transitions-api) · [`@starting-style`](#76-transitions-without-javascript-starting-style)
8. [**What good looks like**](#8-what-good-looks-like)
9. [**Gaps in the ecosystem**](#9-gaps-in-the-ecosystem)
10. [Caveats & things we could not verify](#10-caveats--things-we-could-not-verify)

---

## The five things worth knowing before reading further

1. **Stimulus has not shipped a release since v3.2.2 in August 2023 — three years.** The substrate is frozen. Build on it accordingly; don't wait for a v4 to fix anything.
2. **Turbo 8 killed the reactivity-gem category.** Morphing + `broadcasts_refreshes_to` did what CableReady, StimulusReflex, TurboBoost, turbo-morph, and turbo_ready existed to do. All five are now dormant or dead. `turbo_power` is the only survivor, because it's additive rather than an alternative architecture.
3. **The whole "reusable component" story is two projects.** hotwire.io's own Components category has exactly two entries: `stimulus-components` and `tailwindcss-stimulus-components`. Between them: 41 controllers, none styled, no tabs+combobox+table+datepicker+toast-stack, and accessibility retrofitted as recently as this month.
4. **Every styled component library is either commercial or Phlex-only.** Rails UI ($299/yr), Rails Designer ($149–299 one-time), Zestui (unset licence) vs RubyUI/PhlexyUI (Phlex). **There is no free, ERB-first, styled + behavioural Hotwire component library.**
5. **`hotwire_combobox` shows what "good" looks like** — it ships a Stimulus controller *and* a Rails helper that generates the markup, so nobody hand-writes `data-` attributes, and it implements the W3C APG pattern deliberately. Nothing else in the ecosystem does both.

---

## Summary: verdicts at a glance

Legend — **Adopt**: use it. **Study**: read it, don't necessarily depend on it. **Avoid**: dormant, dead, or superseded.

| Project | Category | Latest release | Stars | Health | Verdict |
|---|---|---|---|---|---|
| **@hotwired/turbo / turbo-rails** | core | 8.0.23 · 2026-01-29 | 7.4k / 2.4k | active, 342 open issues | **Adopt** |
| **@hotwired/stimulus** | core | 3.2.2 · **2023-08-07** | 13.1k | ⚠️ frozen 3 yrs | **Adopt** (no alternative) |
| **stimulus-use** | core | 0.53.0 · 2026-06-30 | 1.7k | active, 747k/mo | **Adopt** |
| **@rails/request.js** | core | 0.0.13 · 2025-12-11 | 439 | active, 1.2M/mo | **Adopt** |
| **stimulus-components** | components | monorepo, 19 unreleased changesets | 1.5k | very active | **Study — the one to beat** |
| **tailwindcss-stimulus-components** | components | 6.1.4 · 2026-06-03 | 1.5k | active, slow | **Study / partial adopt** |
| **hotwire_combobox** | component | 0.4.1 · 2026-02-13 | 652 | active | **Adopt — the model** |
| **lexxy** | rich text | 0.9.29 · 2026-08-07 | 1.2k | very active | **Adopt (Rails 8.x)** |
| **turbo_power** | turbo ext | 0.8.0 · 2026-07-13 | 519 | active | **Adopt** |
| **turbo-mount** | escape hatch | 0.4.4 · 2025-12-25 | 476 | active | **Study** |
| **stimulus-lsp / stimulus-parser** | tooling | 1.1.2 · 2026-08-01 | 303 / 45 | very active | **Adopt** |
| **hotwire-livereload** | tooling | 2.1.1 · 2025-10-14 | 554 | active | **Adopt** |
| **hotwire-spark** | tooling | 0.1.13 · 2025-01-25 | 462 | ⚠️ quiet 16 mo | **Study** |
| **ViewComponent** | rendering | 4.12.0 · 2026-06-04 | 3.6k | very active | **Adopt** |
| **Phlex / phlex-rails** | rendering | 2.4.1 · 2026-02-06 | 1.5k / 364 | active ⚠️ CVE <2.4.1 | **Adopt (pin ≥2.4.1)** |
| **Lookbook** | rendering | 2.3.14 · 2025-12-17 | 1.1k | active | **Adopt** |
| **Primer ViewComponents** | components | 0.53.2 · 2026-08-05 | 580 | very active | **Study — reference impl** |
| **RubyUI** | components | 1.6.0 · 2026-08-05 | 1.0k | very active | **Study** |
| **Rails Blocks** | components | unversioned | 9 (repo) | live, ⚠️ Pro price unverified | **Study** |
| **Rails UI** | commercial | 3.4.2 · 2026-02-13 | 615 | active · **$299–799/yr** | **Study** |
| **Rails Designer** | commercial | n/a | — | active · **$149–299 one-time** | **Study** |
| **Zestui** | commercial | 0.4.0 | — | small · ⚠️ **licence unset** | **Study w/ caution** |
| **PhlexyUI** | components | — | 105 | ⚠️ quiet 9 mo | **Study** |
| **view_component-form** | forms | 0.3.1 · 2026-08-07 | 262 | very active | **Adopt** |
| **simple_form** | forms | 5.4.1 · 2026-01-05 | 8.2k | healthy, 97M dl | **Adopt** |
| **superform** | forms | 0.7.0 · 2026-03-02 | 392 | active, small | **Study** |
| **formtastic** | forms | 6.0.0 · 2026-02-20 | 5.2k | maintenance only | **Avoid (new work)** |
| **pagy** | pagination | **43.6.1** · 2026-07-21 | 5.0k | very active ⚠️ rewrite | **Adopt** |
| **ransack** | search | 4.4.1 · 2025-09-29 | 5.9k | active ⚠️ allowlist req'd | **Adopt** |
| **kaminari** | pagination | 1.2.2 · **2021-12-25** | 8.7k | frozen | **Superseded-by pagy** |
| **will_paginate** | pagination | 4.0.1 · 2024-06-10 | 5.7k | quiet | **Superseded-by pagy** |
| **shrine** | uploads | 3.9.0 · 2026-07-13 | 3.3k | healthy | **Study** |
| **avo** | admin | 4.1.10 · 2026-08-14 | 1.8k | very active · LGPL+comm. | **Study** |
| **administrate** | admin | 1.0.0 · 2025-10-31 | 6.0k | active | **Study** |
| **madmin** | admin | 2.5.1 · 2026-08-12 | 760 | active | **Study** |
| **activeadmin** | admin | 3.5.2 · 2026-07-13 | 9.7k | active but jQuery+Arbre | **Study interaction only** |
| **motor-admin** | admin | 0.5.0 · 2026-02-01 | 2.2k | ⚠️ repo dormant 2 yrs · AGPL | **Avoid** |
| **nice_partials** | composition | 0.10.1 · **2024-08-03** | 386 | dormant 2 yrs | **Study (vendor it)** |
| **view_component-contrib** | composition | 0.2.5 · 2025-08-11 | 425 | active, untagged | **Study (pin SHA)** |
| **cable_ready** | reactivity | 5.0.6 · **2024-12-15** | 771 | dormant | **Superseded-by Turbo 8** |
| **stimulus_reflex** | reactivity | 3.5.5 · **2025-05-25** | 2.3k | dependabot only | **Avoid (new work)** |
| **turbo_boost-commands** | reactivity | 0.3.2 · **2024-06-14** | 325 | **abandoned** | **Avoid** |
| **turbo_boost-streams** | reactivity | 0.1.11 · **2024-02-29** | 270 | **abandoned** | **Avoid** |
| **turbo_ready** | reactivity | 0.1.4 · **2022-12-12** | — | **dead** (repo renamed) | **Avoid** |
| **turbo-morph** | reactivity | — · **2023-02-25** | 103 | **abandoned** | **Superseded-by Turbo 8** |
| **mrujs** | legacy | 1.0.2 · **2024-08-16** | 172 | dormant, 6k/mo | **Avoid** |
| **trailblazer/cells** | rendering | — · 2024-12 | 3.1k | stale | **Superseded-by ViewComponent** |
| **unabridged/motion** | reactivity | — · **2023-03-17** | 694 | **abandoned** | **Avoid** |

**Dead or dying, called plainly:** turbo_boost-commands, turbo_boost-streams, turbo_ready, turbo-morph, unabridged/motion, cable_ready, stimulus_reflex, mrujs, motor-admin, kaminari, nice_partials (dormant), Tippy.js (archived), Litepicker (archived), Shoelace (archived), `@github/details-dialog-element` (archived), flatpickr (npm-stale since 2022), el-transition (2020), `stimulus-flatpickr` / `stimulus-tom-select` / `stimulus-hotkeys` (all stale wrappers), and hotwire.io's own Toasta / Morphkit / Radiolabel / rails-aria-components entries (dead links or empty stubs).

---
## 1. hotwire.io/ecosystem — the community index

**What it is:** https://hotwire.io is a **community-run** resource hub by Marco Roth (repo: `marcoroth/hotwire.io`, 175 ★, MIT, last pushed 2026-01-20, 31 open issues). Every page carries the disclaimer: *"Hotwire.io is a community-driven effort and is not affiliated with the official Hotwire project."* The official site remains `hotwired.dev`. Nav: Ecosystem, Documentation, Use-Cases, Frameworks, Community, Newsletter — there is no `/discuss` or `/handbooks` section.

**Freshness:** per-page "last modified" stamps range from ~3 years to ~10 months old. Periodic batch maintenance, not weekly-active. Several entries are dead links or empty stubs (see below).

**Verdict: study, don't trust.** It is the best existing link directory for this ecosystem and worth mining, but it is not curated for quality or liveness — abandoned and healthy projects sit side by side with no signal distinguishing them. **That absence of an honest maintenance signal is itself the argument for this survey.**

### Complete enumeration — 79 items across 13 populated categories

No entry on hotwire.io carries its own description; each card links out to the real project.

**Core Libraries (3):** Hotwire Native · Stimulus · Turbo

**Extending Core Functionality (6):** Stimulus Use · Turbo Morph *(abandoned 2023 — superseded by native Turbo 8 morphing)* · Turbo Power · stimulus-conductor *(parent/child controller management)* · stimulus-decorators *(TypeScript decorators for Stimulus)* · stimulus-zod-form *(Zod-validated forms)*

**New Concepts (2):** Formulus *(client-side HTML5 form validation, marcoroth)* · Turbo Boost *(hopsoft — abandoned, see §5)*

**Helper Libraries (4):** Current.js *(410-byte `<meta>` reader, marcoroth)* · Debounced *(framework-agnostic debounced DOM events)* · Morphkit *(⚠️ empty stub, no link)* · Request.js

**UI Frameworks with Hotwire in Mind (16):** CSS Zero · darksea/ui *(⚠️ site returns Cloudflare 525)* · Essence · Instrumental · michelson/rails-ui · Nitro Kit · PhlexyUI · Rails Blocks · Rails Designer · Rails UI · RailsbootUI · Ralix · Ruby UI · shadcn/ui on Rails *(aviflombaum/shadcn-rails)* · Zest UI · rails-aria-components *(⚠️ announcement only, no repo)* — covered in §4

**Ruby Gems Supporting the Hotwire Approach (5):** Kredis · Phlex · Turbo Ruby *(stale since 2023)* · Universal ID · ViewComponent

**Tooling (12):** Hotwire Dev Tools · Hotwire Livereload · Hotwire Native Dev Tools · Hotwire Spark · Radiolabel *(no description)* · Stimulizer · stimulus-lint · Stimulus LSP · Stimulus Parser · Toasta *(⚠️ dead link — repo 404s)* · Turbo Boost Dev Tools · Turbo LSP *(stub, no link)*

**Components (2):** Stimulus Components · Tailwindcss Stimulus Components — **the entire "Components" category is two entries.** That is the whole reusable-component story of the Hotwire ecosystem as its own community index tells it, and it's the clearest possible statement of the opportunity.

**NPM Packages Supporting the Hotwire Approach (8):** Chart.js · Chartkick · Grid.js · JS Cookie · Local Time *(basecamp/local_time)* · Relative Time Element · Tippy.js *(⚠️ archived 2024)* · Tom Select

**Hotwire Native (8):** Bridge Components · Hotwire Native Android · Hotwire Native Directory *(turbonative.directory)* · Hotwire Native iOS · Strada Rails · Turbo Native Example · Turbo Native Initializer · Turbo Navigator

**Websockets (7):** Action Cable CLI · ActionCable · AnyCable · Cable Shared Worker · Mercure · Turbo Train *(SSE broadcasting)* · WebSocket Director

**Deployment (4):** Enhanced PostgreSQL Adapter for ActionCable · Fly.io · Kamal · Scaling Websockets with AnyCable

**State Management (2):** Solder · Stimulus Store

**Optimistic UI (0):** *the category exists as a heading with **zero entries**.* See §9, gap #11.

### Also from Marco Roth (beyond the ecosystem page)

The ecosystem's most prolific tool-builder has largely moved on from Hotwire extensions to ERB tooling — worth knowing where the energy actually is:

- **herb** — https://github.com/marcoroth/herb — HTML-aware ERB toolchain. **1,284 ★, pushed 2026-08-15 (today).** His most active project by a wide margin.
- **reactionview** — https://github.com/marcoroth/reactionview — 484 ★, pushed 2026-08-08. ActionView-compatible ERB engine built on herb.
- **stimulus-lsp** (303 ★, v1.1.2 on 2026-08-01) and **stimulus-parser** (45 ★, pushed 2026-08-13) — both active; see §5.
- **turbo-lsp** — 53 ★, last tagged v0.0.2 (2024-05-24) despite pushes through 2026-08-11. Experimental.
- **turbo-morph** — 103 ★, **abandoned since 2023-02-25**; it was the ancestor of Turbo 8's native morphing and has no reason to exist now.
- **boxdrop** — 85 ★, pushed 2026-07-24 — a StimulusReflex Dropbox-clone demo; useful as a reference app, not a library.

## 2. The core: Hotwire itself

The most important finding in this whole survey, stated plainly:

> **Stimulus has not had a release since v3.2.2 on 2023-08-07 — three years ago.** The repo is not dead (13,080 stars, commits through 2026-07), but recent commits are Dependabot bumps and doc fixes. There are `mixins`, `esm`, and `compiler` branches on `hotwired/stimulus` that have never shipped. Turbo is healthier but also slowing: v8.0.23 landed 2026-01-29, seven months before this survey, with 342 open issues.

This is not a reason to avoid Hotwire — it's a reason to build *on top of* it carefully, and it strengthens the case for crosswire: the framework is stable-to-frozen, so a component layer built on it has an unusually long shelf life. It also means **don't wait for Stimulus 4 to solve anything.**

### @hotwired/stimulus
- **Repo/site:** https://github.com/hotwired/stimulus · https://stimulus.hotwired.dev
- **What:** The modest JavaScript framework — connects `data-controller` elements to controller classes with targets, values, classes, actions, and outlets.
- **Install:** `bin/importmap pin @hotwired/stimulus` / `yarn add @hotwired/stimulus`
- **Example:**
  ```js
  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static targets = ["output"]
    static values = { greeting: { type: String, default: "Hello" } }

    greet() { this.outputTarget.textContent = `${this.greetingValue}!` }
  }
  ```
- **Maintenance:** **v3.2.2, 2023-08-07 — no release in 3 years.** Repo pushed 2026-08-12, 67 open issues. Effectively feature-frozen.
- **Popularity:** 13,080 ★ · 4.28M npm downloads/month.
- **License:** MIT.
- **Verdict: adopt** (there is no alternative and the API is stable) — but treat it as a finished, frozen substrate.

### @hotwired/turbo & turbo-rails
- **Repo/site:** https://github.com/hotwired/turbo · https://github.com/hotwired/turbo-rails
- **What:** Drive/Frames/Streams — full-page navigation over the wire, plus Turbo 8's morphing page refreshes and broadcast refreshes.
- **Install:** `gem "turbo-rails"`
- **Example:**
  ```ruby
  # model
  class Message < ApplicationRecord
    broadcasts_refreshes_to :room   # Turbo 8: morph-based, replaces per-partial broadcasts
  end
  ```
  ```erb
  <%# view %>
  <meta name="turbo-refresh-method" content="morph">
  <meta name="turbo-refresh-scroll" content="preserve">
  <%= turbo_stream_from @room %>
  ```
- **Maintenance:** turbo v8.0.23 (2026-01-29), turbo-rails v2.0.23 (2026-01-29). Repo pushed 2026-08-11. **342 open issues on `hotwired/turbo`** — the highest of any repo in this survey. Active but with a large backlog and a slowing release cadence.
- **Popularity:** turbo 7,377 ★ / 4.15M npm/mo · turbo-rails 2,389 ★ / 81.8M gem downloads.
- **License:** MIT.
- **Verdict: adopt.** Turbo 8's morphing + broadcast refreshes are the change that made most of §5's reactivity gems unnecessary — see that section.

### stimulus-rails / importmap-rails
- `stimulus-rails` v1.3.4 (2024-08-16), 725 ★, 68.5M downloads — provides `stimulus-loading.js` (the eager/lazy autoload shim for importmap apps) and the `stimulus:manifest:update` task. Quiet, stable, effectively done.
- `importmap-rails` v2.2.3 (2026-01-07), 57.2M downloads — active.
- **Verdict: adopt** both; but note the documented constraint that **importmaps don't handle transitive npm dependencies well and don't handle CSS at all.** Any component with third-party deps or styles is bundler-only in practice.

### stimulus-use
- **Repo/site:** https://github.com/stimulus-use/stimulus-use · https://stimulus-use.github.io
- **What:** A set of composable behaviours (mixins) you apply inside a Stimulus controller's `connect()` — the closest thing Stimulus has to hooks.
- **Install:** `yarn add stimulus-use`
- **Example:**
  ```js
  import { Controller } from "@hotwired/stimulus"
  import { useClickOutside, useTransition } from "stimulus-use"

  export default class extends Controller {
    static targets = ["menu"]
    static classes = ["enterActive", "enterFrom", "enterTo"]

    connect() {
      useClickOutside(this, { element: this.menuTarget })
      useTransition(this, { element: this.menuTarget })
    }

    clickOutside() { this.leave() }   // provided by useClickOutside
  }
  ```
- **The complete mixin list** (verified from `src/index.ts` at v0.53.0 — 19 exports):
  `useApplication`, `useClickOutside`, `useDebounce`, `useDispatch`, `useHover`, `useIdle`, `useIntersection`, `useLazyLoad`, `useMatchMedia`, `useMemo`, `useMeta`, `useMutation`, `useResize`, `useTargetMutation`, `useThrottle`, `useTransition`, `useVisibility`, `useWindowFocus`, `useWindowResize`.
  `useHotkeys` **moved out of the main entry point** — it now lives at `stimulus-use/hotkeys` and requires `hotkeys-js` as a peer dep; importing it from `stimulus-use` throws an explanatory error.
- **Maintenance:** v0.53.0, 2026-06-30. Repo pushed 2026-08-12, 14 open issues. **Actively maintained.** Still pre-1.0 after six years.
- **Popularity:** 1,679 ★ · **747k npm downloads/month** — by a wide margin the most-used third-party Stimulus package in existence.
- **License:** MIT.
- **Verdict: adopt.** The single most valuable dependency in the ecosystem. `useClickOutside`, `useIntersection`, `useDebounce`, and `useTransition` remove most of the boilerplate from a component library. Its one weakness for our purposes: `useTransition` is **class**-based, not data-attribute-based — see the comparison in §3.

### @rails/request.js
- **Repo/site:** https://github.com/rails/request.js
- **What:** A thin `fetch` wrapper that automatically sends the CSRF token, sets `Accept` headers for `turbo-stream`/`json`/`html`, and processes Turbo Stream responses.
- **Install:** `bin/importmap pin @rails/request.js`
- **Example:**
  ```js
  import { patch } from "@rails/request.js"

  await patch(this.element.dataset.updateUrl, {
    body: JSON.stringify({ todo: { position: newIndex } }),
    responseKind: "turbo-stream"
  })
  ```
- **Maintenance:** v0.0.13 (2025-12-11), repo pushed 2026-03-04, 439 ★. Perpetually 0.0.x but stable and Rails-org-owned.
- **Popularity:** **1.16M npm downloads/month.**
- **License:** MIT.
- **Verdict: adopt.** If a controller talks to the server, use this rather than raw `fetch` — CSRF handling alone justifies it, and `responseKind: "turbo-stream"` lets a Stimulus controller drive Turbo Streams without writing any response-parsing code. `@stimulus-components/sortable` takes it as a peer dependency for exactly this reason.

## 3. Stimulus Components (the closest prior art)

### stimulus-components (monorepo)

- **Repo/site:** https://github.com/stimulus-components/stimulus-components · https://www.stimulus-components.com/
- **What:** A pnpm-workspace monorepo of 32 small, independently-published Stimulus controllers, each shipped as its own npm package `@stimulus-components/<name>`.
- **Author:** Guillaume Briday (French, ex-`stimulus-components` individual repos).
- **Install:** one package per controller.
  ```bash
  yarn add @stimulus-components/character-counter
  # or, Rails importmaps:
  bin/importmap pin @stimulus-components/character-counter
  ```
  ```js
  import { Application } from "@hotwired/stimulus"
  import CharacterCounter from "@stimulus-components/character-counter"

  const application = Application.start()
  application.register("character-counter", CharacterCounter)
  ```
- **Maintenance:** **Actively maintained and currently in a burst of activity.** Last commit 2026-08-15 (the day of this survey). 44 open issues. Note the release lag: the repo has **19 pending changesets** unreleased, and several npm packages (e.g. `@stimulus-components/dropdown` 3.0.0) were last *published* in 2024 — the monorepo is being hardened faster than it's being released.
- **History:** Until Oct 2024 each controller was its own GitHub repo (`stimulus-components/stimulus-sortable`, etc.). All 30 of those repos are now **archived** and consolidated into this monorepo; npm packages were renamed from `stimulus-<name>` to `@stimulus-components/<name>`. Two stragglers keep the old unscoped npm names: `stimulus-glow` and `stimulus-textarea-autogrow`, and `stimulus-rails-nested-form` is the one old repo left unarchived.
- **Popularity:** 1,466 stars, 68 forks. npm last-month downloads for the bigger packages: clipboard 169k, sortable 154k, rails-nested-form 142k, dropdown 80k, dialog 42k.
- **License:** MIT (per-package `LICENSE` file plus repo root).
- **Verdict: STUDY (deeply) — and treat as the direct competitor.** This is the best-engineered reusable-Stimulus-controller project that exists. Its repo/build/docs/test conventions are the template to beat (see [§8 What good looks like](#8-what-good-looks-like)). But its catalog is a grab-bag of "little behaviours," not a UI system: no tabs, no tooltip, no combobox, no toast stack, no table, no form-field primitives, and almost nothing is styled. That is exactly the gap crosswire can occupy.

#### Complete catalogue (32 components)

Every controller declares its API with `static targets` / `static values` / `static classes`. Full API below, verified against `components/*/src/index.ts` at commit `45fd9ec` (2026-08-15).

| # | Package | Version | Does | Targets | Values | Classes | Extra deps |
|---|---|---|---|---|---|---|---|
| 1 | `@stimulus-components/animated-number` | 5.0.0 | Counts up/down to a number | — | `start`, `end`, `duration`, `lazy`, `lazyThreshold`, `lazyRootMargin` | — | — |
| 2 | `@stimulus-components/auto-submit` | 6.0.0 | Debounced auto-submit of a form | — | `delay` (150) | — | — |
| 3 | `@stimulus-components/carousel` | 6.0.0 | Carousel | — | `options` (Object) | — | `swiper@^14` |
| 4 | `@stimulus-components/character-counter` | 5.1.0 | Character count / countdown | `input`, `counter` | `countdown`, `countUnit` (`code-units`) | — | — |
| 5 | `@stimulus-components/chartjs` | 6.0.1 | Chart.js chart | `canvas` | `type` (`line`), `data`, `options` | — | `chart.js@^4` |
| 6 | `@stimulus-components/checkbox-select-all` | 6.1.0 | Select-all + indeterminate checkbox list | `checkboxAll`, `checkbox` | `disableIndeterminate`, `ignoreDisabled` | — | — |
| 7 | `@stimulus-components/clipboard` | 5.0.0 | Copy to clipboard w/ success state | `button`, `source` | `successContent`, `successDuration` (2000) | — | — |
| 8 | `@stimulus-components/color-picker` | 2.0.0 | Color picker | `button`, `input` | `theme` (`classic`) | — | `@simonwep/pickr` |
| 9 | `@stimulus-components/confirmation` | 1.0.1 | "Type DELETE to confirm" gating | `input`, `item` | — | — | — |
| 10 | `@stimulus-components/content-loader` | 5.0.0 | Lazy/polled HTML fetch into element | — | `url`, `lazyLoading`, `lazyLoadingThreshold`, `lazyLoadingRootMargin`, `refreshInterval`, `loadScripts` | — | — |
| 11 | `@stimulus-components/dialog` | 1.0.1 | Native `<dialog>` modal | `dialog` | `open` | — | — |
| 12 | `@stimulus-components/dropdown` | 3.0.0 | Dropdown w/ transitions + a11y | `menu`, `button` | — | — | `stimulus-use` |
| 13 | `stimulus-glow` | 0.3.0 | Mouse-tracking glow effect | `child`, `overlay` | — | — | — |
| 14 | `@stimulus-components/hotkey` | 1.0.0 | Click/focus element on keypress | — | — | — | — |
| 15 | `@stimulus-components/lightbox` | 4.0.0 | Image lightbox | — | `options` | — | `lightgallery` (**GPLv3**) |
| 16 | `@stimulus-components/notification` | 3.0.0 | Auto-dismiss toast | — | `delay` (3000), `hidden` | — | `stimulus-use` |
| 17 | `@stimulus-components/password-visibility` | 3.0.0 | Show/hide password | `input`, `icon` | — | `hidden` | — |
| 18 | `stimulus-places-autocomplete` | 0.5.0 | Google Places address autofill | `address`, `city`, `streetNumber`, `route`, `postalCode`, `country`, `county`, `state`, `longitude`, `latitude` | `country` (Array) | — | Google Maps JS API |
| 19 | `@stimulus-components/popover` | 7.0.0 | Hover popover, optionally AJAX-loaded | `card`, `content` | `url` | — | — |
| 20 | `@stimulus-components/prefetch` | 4.0.0 | Prefetch in-viewport links | — | — | — | — |
| 21 | `@stimulus-components/rails-nested-form` | 5.0.0 | `fields_for` add/remove rows | `target`, `template` | `wrapperSelector` (`.nested-form-wrapper`) | — | — |
| 22 | `@stimulus-components/read-more` | 5.0.0 | Show more / show less | — | `moreText`, `lessText` | — | — |
| 23 | `@stimulus-components/remote-rails` | 5.0.0 | Handle legacy Rails UJS `ajax:*` events | — | — | — | — |
| 24 | `@stimulus-components/reveal` | 5.0.0 | Toggle a class on one/many items | `item` | — | `hidden` | — |
| 25 | `@stimulus-components/scroll-progress` | 5.0.0 | Reading-progress bar | — | `throttleDelay` (15) | — | — |
| 26 | `@stimulus-components/scroll-reveal` | 4.0.0 | Animate on scroll into view | `item` | `class`, `threshold`, `rootMargin` | — | — |
| 27 | `@stimulus-components/scroll-to` | 5.0.1 | Smooth scroll to anchor | — | `offset`, `behavior` | — | — |
| 28 | `@stimulus-components/sortable` | 5.0.2 | Drag-to-reorder + auto PATCH | — | `resourceName`, `paramName` (`position`), `responseKind` (`html`), `animation`, `handle`, `method` (`patch`) | — | `sortablejs`, `@rails/request.js` |
| 29 | `@stimulus-components/sound` | 2.0.1 | Play/pause/volume/loop audio | — | `url` | — | — |
| 30 | `@stimulus-components/speech-recognition` | 1.0.0 | Web Speech API → input | `startButton`, `stopButton`, `indicator`, `input` | — | `hidden` | — |
| 31 | `stimulus-textarea-autogrow` | 4.1.0 | Auto-growing textarea | — | `resizeDebounceDelay` (100) | — | — |
| 32 | `@stimulus-components/timeago` | 5.0.2 | "3 hours ago", self-refreshing | — | `datetime`, `refreshInterval`, `includeSeconds`, `addSuffix` | — | `date-fns@^3\|^4` |

#### Representative usage

```erb
<%# rails-nested-form — the single most Rails-useful controller in the set %>
<%= form_with model: @user, data: { controller: "nested-form",
      nested_form_wrapper_selector_value: ".nested-form-wrapper" } do |f| %>
  <template data-nested-form-target="template">
    <%= f.fields_for :todos, Todo.new, child_index: "NEW_RECORD" do |todo_fields| %>
      <%= render "todo_form", f: todo_fields %>
    <% end %>
  </template>

  <%= f.fields_for :todos do |todo_fields| %>
    <%= render "todo_form", f: todo_fields %>
  <% end %>

  <div data-nested-form-target="target"></div>
  <button type="button" data-action="nested-form#add">Add todo</button>
<% end %>
```

```erb
<%# sortable — drag to reorder, auto-PATCHes position %>
<ul data-controller="sortable" data-sortable-resource-name-value="todo">
  <% @todos.each do |todo| %>
    <li data-sortable-update-url="<%= todo_path(todo) %>"><%= todo.description %></li>
  <% end %>
</ul>
```

```html
<!-- dialog — native <dialog>, zero CSS opinion -->
<div data-controller="dialog" data-action="click->dialog#backdropClose">
  <dialog data-dialog-target="dialog">
    <p>The modal's content here</p>
    <button type="button" data-action="dialog#close" autofocus>Cancel</button>
  </dialog>
  <button type="button" data-action="dialog#open">Open modal</button>
</div>
```

#### The extension pattern (worth stealing)

Every documented controller ends with an "Extending Controller" section. The controllers are designed to be **subclassed**, with `defaultOptions` getters as the customization seam:

```js
import Sortable from "@stimulus-components/sortable"

export default class extends Sortable {
  connect() {
    super.connect()
    this.sortable   // the SortableJS instance
    this.options    // merged options
  }

  onUpdate(event) { super.onUpdate(event) }

  get defaultOptions() {
    return { animation: 500 }
  }
}
```

This is a genuinely good API decision: it means a wrapper never has to expose every underlying library option as a Stimulus value, and app-level defaults live in one place.

#### Honest criticisms

- **Coverage is behaviours, not a UI system.** 32 controllers and still no tabs, tooltip, combobox/autocomplete, toast *stack*, accordion, table sort/filter, date picker, file upload, command palette, or form-field primitives.
- **Nothing is styled.** By design — but it means "install a component" never gets you a working-looking UI, just wiring. Every consumer re-solves the CSS.
- **A11y is retrofitted, not designed in.** The most recent commits are literally `Add aria-expanded and aria-controls to dropdown (#183)` and `reveal-aria-expanded` — i.e. accessibility was missing from shipped components until August 2026.
- **Turbo is barely acknowledged.** These are pure Stimulus packages; almost none of the docs mention Turbo Frames, Turbo Streams, morphing, or the Turbo page cache — the three things that actually bite you when you write Stimulus in a Rails app. (Several of the pending changesets are teardown/leak fixes: `prefetch-observer-leak`, `animated-number-observer-leak`, `textarea-autogrow-listener-leak`, `pending-timeouts-on-disconnect` — exactly the class of bug Turbo's cache exposes.)
- **`lightbox` pulls in GPLv3 `lightgallery`.** Licence-incompatible for many commercial apps and not flagged prominently.
- **Release discipline lags engineering.** 19 unreleased changesets at time of writing.

---

### tailwindcss-stimulus-components (the ancestor)

- **Repo/site:** https://github.com/excid3/tailwindcss-stimulus-components · demo: https://excid3.github.io/tailwindcss-stimulus-components/
- **What:** Chris Oliver's (GoRails / Jumpstart Pro) original set of 9 Tailwind-oriented Stimulus controllers — the project that established the whole "reusable Stimulus controller package" genre.
- **Install:**
  ```bash
  yarn add tailwindcss-stimulus-components
  # or
  bin/importmap pin tailwindcss-stimulus-components
  ```
  ```js
  import { Application } from "@hotwired/stimulus"
  import { Alert, Autosave, ColorPreview, Dropdown, Modal, Popover, Slideover, Tabs, Toggle }
    from "tailwindcss-stimulus-components"

  const application = Application.start()
  application.register("dropdown", Dropdown)
  application.register("modal", Modal)
  // ...
  ```
- **Maintenance:** **Actively maintained but slow-moving.** v6.1.4 released 2026-06-03; last commit 2026-08-04; only **2 open issues** (unusually clean). Single-maintainer (Chris Oliver), effectively feature-complete.
- **Popularity:** 1,515 stars, 146 forks, **192k npm downloads/month** — more downloads than any single `@stimulus-components/*` package.
- **License:** MIT.
- **Verdict: STUDY / partially ADOPT.** Smaller and older than stimulus-components, but it ships the four things people actually reach for (modal, dropdown, tabs, slideover) as *one* package with *one* import, and its transition system is better thought-out. Its weakness is the flip side: 9 controllers, no docs site (just `/docs/*.md`), no TypeScript, and it's one person's side project attached to a commercial product (Jumpstart Pro).

#### Complete catalogue (9 controllers + 1 utility)

| Controller | Targets | Values | Classes | Notes |
|---|---|---|---|---|
| `alert` | — | `dismissAfter`, `showDelay` (0) | — | Auto-dismissing flash |
| `autosave` | `form`, `status` | `submitDuration` (1000), `statusDuration` (2000), `submittingText` ("Saving…"), `successText` ("Saved!"), `errorText` | — | Debounced form autosave with a status message |
| `color-preview` | `preview`, `color` | `style` (`backgroundColor`) | — | Live swatch from a color input |
| `dropdown` | `menu`, `button`, `menuItem` | `open`, `closeOnEscape` (true), `closeOnClickOutside` (true) | `enter`, `enterFrom`, `enterTo`, `leave`, `leaveFrom`, `leaveTo`, `toggle` | The richest of the set; keyboard nav via `menuItem` |
| `modal` | `dialog` | `open` | — | Native `<dialog>` since v5.1 |
| `popover` | `content` | `dismissAfter`, `open` | — | Hover/click popover |
| `slideover` | `dialog` | `open` | — | Native `<dialog>` since v5.1 (breaking change) |
| `tabs` | `tab`, `panel`, `select` | `index`, `updateAnchor`, `scrollToAnchor`, `scrollActiveTabIntoView` | `activeTab`, `inactiveTab` | **Includes a `<select>` target for mobile** — nice touch nobody else does |
| `toggle` | `toggleable` | `open` | — | Generic show/hide |
| `transition` (util) | — | — | — | Exported function, see below |

```html
<div data-controller="dropdown" data-dropdown-close-on-escape-value="true">
  <button data-dropdown-target="button" data-action="dropdown#toggle">Options</button>

  <div data-dropdown-target="menu"
       class="hidden absolute"
       data-transition-enter="transition ease-out duration-100"
       data-transition-enter-from="opacity-0 scale-95"
       data-transition-enter-to="opacity-100 scale-100"
       data-transition-leave="transition ease-in duration-75"
       data-transition-leave-from="opacity-100 scale-100"
       data-transition-leave-to="opacity-0 scale-95">
    <a data-dropdown-target="menuItem" href="/edit">Edit</a>
  </div>
</div>
```

#### How it differs from stimulus-components

| | tailwindcss-stimulus-components | stimulus-components |
|---|---|---|
| Packaging | **One** npm package, named exports | **32** npm packages, one default export each |
| Language | Plain JS, no types | TypeScript, emits `.d.ts` |
| Build | esbuild, CJS + ESM | Vite lib mode, UMD + `.mjs` + types, per-package |
| Tests | `@web/test-runner` + `@open-wc/testing` — **real browser** | Vitest + jsdom |
| Docs | Markdown files in `/docs` + a GitHub Pages demo | Full Nuxt Content site with Algolia DocSearch, live demos, dark mode |
| Releases | Manual, hand-written `CHANGELOG.md` | changesets → automated npm publish with provenance |
| Styling stance | Tailwind-flavoured; ships transition class conventions | Framework-agnostic, ships no class conventions |
| Scope | UI chrome (modal/dropdown/tabs/slideover) | Behaviours (scroll, clipboard, counters, sortable) |
| Turbo awareness | Modal/slideover handle `turbo:before-cache` | Mostly none |

The two are **complementary, not competing** — the classic Rails app installs both. Neither one covers combobox, table, or form-field patterns.

#### The transition system (its best idea, worth stealing)

`transition.js` (145 lines, exported as `transition`/`enter`/`leave`/`cancelTransition`) is a from-scratch reimplementation of Alpine/Vue enter-leave transitions driven by **data attributes**, not by Stimulus classes:

```js
import { enter, leave } from "tailwindcss-stimulus-components"
await enter(this.menuTarget)   // reads data-transition-enter*, awaits completion
await leave(this.menuTarget)   // reads data-transition-leave*, then adds `hidden`
```

Design details worth copying:

- **Six data attributes + a toggle class.** `data-transition-enter`, `-enter-from`, `-enter-to`, `data-transition-leave`, `-leave-from`, `-leave-to`, and `data-toggle-class` (default `hidden`). Each falls back to an options object, then to a sane default (`enter`, `enter-from`, …) — so it works with **plain CSS classes**, not just Tailwind, despite the package name.
- **Two `requestAnimationFrame` stages.** Frame 1 applies the transition + from-classes; frame 2 swaps from→to. This is the correct way to make a class change actually animate.
- **Duration read from computed style.** `getAnimationDuration()` parses `transitionDuration` + `transitionDelay`, falling back to `animationDuration` — no magic-number timeouts, no `transitionend` listener that never fires.
- **Interruptible.** Each element gets an `element._stimulus_transition` record with an `interrupt()` that cancels the pending timeout and runs cleanup, so rapid open/close/open doesn't strand an element mid-transition. `cancelTransition(element)` is exported.
- **Returns a Promise**, so controllers `await` it before removing an element from the DOM.

The alternative most people use — `stimulus-use`'s `useTransition` — is *class*-based (`static classes = ["enterActive", ...]`) rather than *data-attribute*-based. Data attributes win for a component library: the markup carries the animation, so the same controller can be reused with different transitions on the same page without subclassing.

Its one weak spot: since v5.1 the modal and slideover moved to `<dialog>`, and because `display: none` → `display: block` isn't transitionable, those two now use **CSS animations** in the examples rather than this system. That tension (`<dialog>` + transitions) is unresolved and is a real gap.

## 4. Rendering approaches & component libraries

### 4.1 The two rendering approaches

#### ViewComponent
- **Repo/site:** https://viewcomponent.org · https://github.com/ViewComponent/view_component
- **What:** Reusable, testable, encapsulated Ruby view objects that render an ERB (or Haml/Slim) sidecar template.
- **Install:** `gem "view_component"`
- **Example:**
  ```ruby
  class Card::Component < ViewComponent::Base
    renders_one :header
    renders_many :actions

    def initialize(title:) = @title = title
  end
  ```
  ```erb
  <%= render Card::Component.new(title: "Hi") do |c| %>
    <% c.with_header { "Header" } %>
    <% c.with_action { link_to "Edit", edit_path } %>
  <% end %>
  ```
- **Maintenance:** v4.12.0 (2026-06-04) — a security release fixing stale render-context/XSS issues. Last commit 2026-08-12. **Actively maintained**, GitHub-backed (Joel Hawksley).
- **Popularity:** 3,569 ★ · 61.4M gem downloads.
- **License:** MIT.
- **Verdict: ADOPT.** The default choice for an ERB-based Rails component system, with the largest install base and the only battle-tested slot API.

#### Phlex
- **Repo/site:** https://phlex.fun · https://github.com/yippee-fun/phlex *(org renamed from `phlex-ruby` to `yippee-fun`, Joel Drapper's company — old URLs redirect)*
- **What:** HTML-in-Ruby views — no template files; components are Ruby objects that emit markup by calling tag methods.
- **Install:** `gem "phlex-rails"` then `bin/rails generate phlex:install`
- **Example:**
  ```ruby
  class Card < Phlex::HTML
    def initialize(title:) = @title = title

    def view_template(&block)
      div(class: "card") do
        h2 { @title }
        yield if block
      end
    end
  end
  ```
- **Maintenance:** v2.4.1 (2026-02-06), last commit 2026-07-28. Actively maintained. **⚠️ v2.4.1 was a security release** fixing a high-severity XSS protection bypass via attribute splatting / dynamic tags / `href` values (**GHSA-w67g-2h6v-vjgq**). **Pin ≥ 2.4.1.** Phlex 2.0 was a from-scratch rewrite that renamed `template` → `view_template`.
- **Popularity:** 1,523 ★ (core) / 364 ★ (`phlex-rails`) · 5.0M + 3.1M gem downloads.
- **License:** MIT (no licensing controversy — verified; the 2.0 event was an API rewrite, not a licence change).
- **Verdict: ADOPT with eyes open.** Excellent for *authoring a distributable component library*; a still-settling API and a recent high-severity CVE are the costs.

#### ViewComponent vs Phlex — for shipping a component library in 2026

| | ViewComponent | Phlex |
|---|---|---|
| Slots | `renders_one` / `renders_many` — declarative, documented, shared idiom | No slot primitive; compose with plain Ruby blocks. More flexible, but every library invents its own convention |
| Previews | First-class `ViewComponent::Preview` + Lookbook | Works via Lookbook, more manual wiring |
| Testing | `ViewComponent::TestHelpers`, `render_inline`, Capybara matchers | POROs responding to `#call` — unit-testable with no Rails at all |
| Packaging in a gem | Class + sidecar template; view-path resolution leaks to consumers | One `.rb` file per component; trivially packaged and `require`d |
| Markup | ERB — designers can read it, grep works across `.erb` | Tag-method DSL — full autocomplete/refactoring, noisy when deeply nested |
| Momentum | Larger, higher commit cadence, GitHub's own Primer runs on it | Winning the *"ship a reusable UI kit as a gem"* niche outright |

**The pattern in the data is unambiguous:** ViewComponent wins for app-internal component systems; **Phlex has won the component-library-authoring niche.** RubyUI, Zestui, PhlexyUI, superform, and all three shadcn-for-Rails ports chose Phlex — because it maps directly onto the shadcn "copy a self-contained file into your app" distribution model.

Performance claims (Phlex's "~1.4 Gbps/core") are vendor claims; no independent 2026 head-to-head benchmark was found. Don't decide on this.

**Implication for crosswire:** the gap is on the *other* axis. Everything Phlex-based is HTML-in-Ruby; everything ERB-first is either behaviour-only (stimulus-components) or commercial (Rails UI, Rails Designer). **A free, ERB-first, styled + behavioural library is unoccupied ground.**

#### Lookbook
- **Repo/site:** https://github.com/lookbook-hq/lookbook (independent — not under the ViewComponent or Phlex orgs)
- **What:** "Storybook for Rails" — a mountable engine that browses and renders component previews with live reload, params controls, and embedded docs.
- **Install:** `gem "lookbook", group: :development`
- **Example:**
  ```ruby
  class CardPreview < ViewComponent::Preview
    def default = render(Card::Component.new(title: "Example"))
  end
  ```
- **Maintenance:** v2.3.14 (2025-12-17), last commit 2026-05-13 — quieter than the two frameworks but not stale.
- **Popularity:** 1,091 ★ · 10.2M gem downloads.
- **License:** MIT.
- **Verdict: ADOPT.** The standard preview tool for either approach, with no real competitor. **Crosswire should ship Lookbook previews for every component.**

### 4.2 Free / open component libraries

#### RubyUI
- **Repo/site:** https://rubyui.com · https://github.com/ruby-ui/ruby_ui
- **What:** The most mature "shadcn/ui for Rails" — Phlex-based, generator-driven, copy-the-code-into-your-app ownership model. 50+ components (Accordion → Typography).
- **Install:**
  ```bash
  bundle add ruby_ui
  bin/rails generate ruby_ui:install
  bin/rails generate ruby_ui:component button
  ```
- **Example:**
  ```ruby
  class Example < Phlex::HTML
    include RubyUI
    def view_template = Button(variant: :outline) { "Click me" }
  end
  ```
- **Maintenance:** v1.6.0 (2026-08-05), last commit 2026-08-09. **Very active.**
- **Popularity:** 1,032 ★ · 96k gem downloads.
- **License:** MIT.
- **Verdict: STUDY (closely) / adopt if you're Phlex-based.** The strongest free prior art for component *design* in Rails, and the best proof that the shadcn ownership model works here. Its limit is that it's Phlex-only and light on Stimulus behaviour.

#### Rails Blocks
- **Repo/site:** https://railsblocks.com · https://github.com/Rails-Blocks/components (9 ★, MIT, pushed 2026-08-06)
- **What:** Copy-paste ERB + Tailwind + Stimulus component snippets, free tier plus a paid Pro tier. By Sandu / Alexandre Glazunov.
- **Install:** none — you copy the ERB partial and the Stimulus controller from the docs site into `app/views` and `app/javascript/controllers`.
- **Maintenance:** it's a docs site, not a versioned artifact. The companion repo is thin but recently touched.
- **Popularity:** ~60 documented component types (marketing claims "300+", counting variants). Cited in `awesome-rails`.
- **License:** free tier + paid Pro. **⚠️ Pro pricing could not be verified — the pricing page 404s to both WebFetch and impersonated curl.**
- **Verdict: STUDY.** Closest thing to what crosswire wants to be — ERB + Stimulus, copy-paste, no lock-in. Worth raiding for patterns. Its weaknesses are exactly what we'd fix: no versioning, no tests, no accessibility story, no Turbo notes, and a paywalled tier with unverifiable terms.

#### PhlexyUI
- **Repo/site:** https://github.com/PhlexyUI/phlexy_ui — DaisyUI components for Phlex. 105 ★, MIT, last pushed 2025-11-13 (**~9 months quiet**).
- **Verdict: STUDY.** The most complete DaisyUI-for-Ruby implementation, but cooling.

#### Primer ViewComponents
- **Repo/site:** https://github.com/primer/view_components — GitHub's own production design system, built on ViewComponent. **This renders github.com.**
- **Maintenance:** v0.53.2 (2026-08-05), last commit 2026-08-13. Extremely active, corporate-backed.
- **Popularity:** 580 ★. License: MIT.
- **Verdict: ADOPT AS REFERENCE.** The best available proof that ViewComponent scales to a real high-traffic design system. Required reading for API design, accessibility conventions, and testing at scale — even though the gem itself is too GitHub-flavoured to depend on.

#### shadcn-for-Rails ports (fragmented — none canonical)
- `sean-yeoh/shadcn_phlexcomponents` — v1.0.0 (2025-08-04), last push 2025-11-29, 30 ★, 6.9k downloads. **Cooling.**
- `cole-robertson/shadcn-phlex` — v0.1.0, 273 downloads, released ~2026-03. **Too early.**
- `aviflombaum/shadcn-rails` — listed on hotwire.io.
- A third, `weird-phlex/weird_phlex-shadcn`, exists.
- **Verdict: WATCH, don't adopt.** Three-plus small non-cooperating projects in one niche. Name the fragmentation; don't pick a winner.

#### Tailwind & CSS plumbing
- **`rails/tailwindcss-rails`** — v4.6.0 (2026-06-17), last commit **2026-08-14**, 1,590 ★, MIT. Official, extremely active. **Verdict: adopt** — it's the substrate under every Tailwind kit in this survey.
- **Flowbite for Rails** — no canonical port. The `flowbite` gem (iwdt, v3.1.2, 34k downloads, 21 ★) only vendors assets; actual Ruby components come from `substancelab/flowbite-components` (v0.3.0, 2.9k downloads, 9 ★, early). **Verdict: study, don't adopt** — treat Flowbite as an asset source to wrap yourself.
- **DaisyUI for Rails** — DaisyUI is framework-agnostic CSS and needs no gem under Tailwind v4's `@plugin` syntax. Ruby ports: PhlexyUI (best), `mhenrixon/daisyui`, `daisyui_on_phlex` (both tiny). **Verdict: study PhlexyUI.**
- **CSS Zero** (`lazaronixon/css-zero`, 855 ★) — a no-build, Tailwind-less CSS starter kit. Not a component library, but listed on hotwire.io and philosophically adjacent to crosswire's "Rails Way" thesis. **Verdict: study.**

### 4.3 Commercial component products

#### Rails UI
- **Repo/site:** https://railsui.com · https://github.com/getrailsui/railsui (615 ★, public shell; source gated)
- **What:** Commercial "app kits" — pages, themes, and components (buttons, forms, tables, modals, dashboards, auth flows, mailers) for Rails with Hotwire/Stimulus. Claims 150–200+ components.
- **Pricing:** **Solo $299/year, Team $799/year — subscription.**
- **Maintenance:** v3.4.2 (2026-02-13), repo pushed 2026-06-08. Active.
- **License:** commercial (`NOASSERTION` on GitHub).
- **Verdict: STUDY.** Best available prior art for ERB+Stimulus breadth and for app-kit-level (not just component-level) delivery. Subscription pricing is the main friction.

#### Rails Designer
- **Repo/site:** https://railsdesigner.com — by Eelco.
- **What:** Commercial Rails UI component library, plus a free MIT SaaS-starter engine `kern` (github.com/Rails-Designer/kern, v0.8.0, 8 ★) and a consultancy offering from €12k.
- **Pricing:** **$149 one-time (Solo, 1 project, 12 months updates) / $299 one-time (Infinite, unlimited projects, lifetime updates).**
- **Components:** Elements, Navigation, Overlay, Feedback, Headings, Data Display, Form Elements, Lists — accordions, command menu, modals, calendar, bulk actions, feeds. **Several categories are marked "planned"/unshipped.**
- **Verdict: STUDY.** One-time pricing is a genuine differentiator vs Rails UI's subscription; breadth is padded with unshipped items. **⚠️ Delivery format (copy-paste vs gem) could not be verified without purchasing.**

#### Zestui
- **Repo/site:** https://zestui.com (gem `zestui`)
- **What:** Phlex + Tailwind + Stimulus UI kit — ~18 components, 25+ colour themes, and a custom form-builder DSL (`zui_form_with`).
- **Maintenance:** v0.4.0, ~4,300 total downloads. Site is live and functional; no prominent public repo, and gem metadata has no `source_code_uri`.
- **License:** **⚠️ UNSET — the gem declares an empty `licenses: []` field on RubyGems.** Do not copy code from it without asking the maintainer (Manu Janardhanan).
- **Verdict: STUDY WITH CAUTION.** Real and active, but tiny adoption and an unset licence is a red flag.

### 4.4 Composition & form helpers

#### ViewComponent::Form
- **Repo/site:** https://github.com/pantographe/view_component-form
- **What:** A Rails `FormBuilder` that renders ViewComponents instead of raw HTML for each field — lets you theme every form in an app by swapping components.
- **Install:** `gem "view_component-form"`
- **Example:**
  ```erb
  <%= form_with model: @user, builder: ViewComponent::Form::Builder do |f| %>
    <%= f.text_field :name %>
  <% end %>
  ```
- **Maintenance:** v0.3.1 (**2026-08-07** — 8 days before this survey). Active.
- **Popularity:** 262 ★ · 875k gem downloads. License: MIT.
- **Verdict: ADOPT / STUDY.** Fills ViewComponent's biggest hole (it has no opinion on form builders) and is exactly the "component + Rails helper" bridge pattern crosswire should copy.

#### superform
- **Repo/site:** https://github.com/rubymonolith/superform — Phlex-based form objects with strong-parameter derivation.
- **Maintenance:** v0.7.0 (2026-03-02), 392 ★, 37k downloads, MIT. Active but small.
- **Verdict: STUDY.** The most interesting *idea* in Rails forms right now (the form declares its own permitted params), but pre-1.0 and Phlex-only.

#### nice_partials
- **Repo/site:** https://github.com/bullet-train-co/nice_partials — slot-like named content blocks for **plain ERB partials**, no component framework required.
- **Example:**
  ```erb
  <%= render "card" do |c| %>
    <% c.header { "Title" } %>
    Body text
  <% end %>
  ```
- **Maintenance:** **v0.10.1, 2024-08-03 — last commit the same day. Two years dormant.** Not archived; may simply be finished.
- **Popularity:** 386 ★ · 561k downloads. License: MIT.
- **Verdict: STUDY, flag as dormant.** Conceptually the closest thing to "components without a component framework" — very relevant to an ERB-first library — but vendor the pattern rather than depending on it.

#### view_component-contrib
- **Repo/site:** https://github.com/palkan/view_component-contrib — palkan's ViewComponent extensions: sidecar-template helpers, test matchers, a "compile mode" perf boost.
- **Maintenance:** **latest tagged release v0.2.5 dates to 2025-08-11 but the last tag before that was 2023; repo pushed 2026-07-25.** Maintained, but not release-disciplined — pin a SHA if you need recent fixes.
- **Popularity:** 425 ★ · 1.24M downloads. License: MIT.
- **Verdict: STUDY.**

### 4.5 Superseded / dead prior art

- **trailblazer/cells** — 3,073 ★, last push 2024-12-02. Pre-ViewComponent view objects. **Verdict: superseded-by-ViewComponent.**
- **unabridged/motion** — 694 ★, last push **2023-03-17**. Reactive server-rendered components in pure Ruby. **Verdict: abandoned.**
- **rubymonolith/superview** — 100 ★. Build whole Rails apps from Phlex/ViewComponent objects. **Verdict: study, niche.**
- **zoolutions/phlex-reactive** — 62 ★. Livewire-style reactive Phlex components. **Verdict: study, early.**
- **Ralix** — 104 ★, a small front-end JS microframework, listed under hotwire.io's UI frameworks but not a component library.

## 5. Turbo & reactivity extensions

**The headline: Turbo 8 killed most of this category.** Morphing page refreshes (`<meta name="turbo-refresh-method" content="morph">`) plus `broadcasts_refreshes_to` solved the "keep the page in sync with the server" problem that CableReady and StimulusReflex existed to solve, using Idiomorph instead of a custom operation DSL. The download and commit numbers below tell the story plainly.

### turbo_power
- **Repo/site:** https://github.com/marcoroth/turbo_power (JS) · https://github.com/marcoroth/turbo_power-rails (gem)
- **What:** ~50 extra custom Turbo Stream actions beyond `append/prepend/replace/update/remove/before/after` — grouped as DOM, Attribute, Event, Form, Storage, Browser, Document, History, Debug, Notification, Turbo, Turbo Progress Bar, and Turbo Frame actions.
- **Install:**
  ```ruby
  gem "turbo_power"
  ```
  ```js
  // app/javascript/application.js
  import TurboPower from "turbo_power"
  TurboPower.initialize(Turbo.StreamActions)
  ```
- **Example:**
  ```ruby
  # in a controller or a .turbo_stream.erb
  turbo_stream.add_css_class "#row_1", "bg-yellow-100"
  turbo_stream.reset_form "#new_comment"
  turbo_stream.scroll_into_view "#comment_42"
  turbo_stream.notification "Saved", body: "Your changes were saved"
  turbo_stream.redirect_to root_path
  ```
- **Maintenance:** gem v0.8.0 (2026-07-13), repo pushed 2026-08-11. **Actively maintained.**
- **Popularity:** 519 ★ (JS) + 351 ★ (gem) · **2.66M gem downloads**, 444k npm/month.
- **License:** MIT.
- **Verdict: ADOPT.** The one gem in this section that Turbo 8 did *not* obsolete — it's additive rather than an alternative architecture, it's the highest-leverage way to drive UI state from the server, and it's the only project here with a healthy 2026 release cadence. Marco Roth is also a Turbo/Stimulus core contributor, so it tracks upstream.

### cable_ready
- **Repo/site:** https://github.com/stimulusreflex/cable_ready · https://cableready.stimulusreflex.com
- **What:** Broadcast ~30 DOM operations (morph, innerHTML, setAttribute, dispatchEvent, …) from Ruby over ActionCable — the pre-Turbo-Streams way to push DOM changes.
- **Install:** `gem "cable_ready"`
- **Example:**
  ```ruby
  cable_ready[UserChannel].morph(selector: "#counter", html: "<span>#{@count}</span>").broadcast
  ```
- **Maintenance:** **v5.0.6, 2024-12-15 — 20 months with no release.** Last substantive commit 2025-06-25. Not archived, but effectively dormant.
- **Popularity:** 771 ★ · 2.59M gem downloads (mostly historical, pulled in as a StimulusReflex dependency).
- **License:** MIT.
- **Verdict: SUPERSEDED-BY turbo-rails 8 + turbo_power.** `cable_ready.morph` is `broadcasts_refreshes_to` with more ceremony; the operation list is `turbo_power` with a websocket attached. Do not start new work here.

### stimulus_reflex
- **Repo/site:** https://github.com/stimulusreflex/stimulus_reflex · https://docs.stimulusreflex.com
- **What:** Phoenix-LiveView-style server-rendered reactivity for Rails — a DOM event triggers a server-side "reflex" that re-renders and morphs the page over a websocket, with no controller/route round-trip.
- **Install:** `gem "stimulus_reflex"` + `rails stimulus_reflex:install`
- **Example:**
  ```erb
  <a href="#" data-reflex="click->Counter#increment" data-step="1">Increment</a>
  ```
  ```ruby
  class CounterReflex < ApplicationReflex
    def increment
      session[:count] = session[:count].to_i + element.dataset[:step].to_i
    end
  end
  ```
- **Maintenance:** **gem v3.5.5 published to RubyGems 2025-05-25** (a GitHub release tag for v3.5.5 was created 2026-07-28, but no new gem shipped). Repo "pushed 2026-08-11" is misleading — the last three commits are all Dependabot bumps. The long-promised v4 has not shipped. **Effectively in maintenance mode.**
- **Popularity:** 2,333 ★ · 1.49M gem downloads.
- **License:** MIT.
- **Verdict: AVOID for new work / study for ideas.** It was a genuinely great idea and its `morph` semantics directly influenced Turbo 8. But it's a parallel architecture to Turbo (websocket-first, session-state-heavy, hard to debug, awkward with Turbo Frames), the community has moved, and betting a new codebase on a dormant v3 is not defensible in 2026.

### turbo_boost-commands / turbo_boost-streams
- **Repo/site:** https://github.com/hopsoft/turbo_boost-commands · https://github.com/hopsoft/turbo_boost-streams
- **What:** Nate Hopkins' successor to StimulusReflex — invoke server-side "commands" from `data-turbo-command` attributes, plus an extended stream-action set.
- **Install:** `gem "turbo_boost-commands"`
- **Example:**
  ```erb
  <button data-turbo-command="DemoCommand#say_hello">Say hello</button>
  ```
- **Maintenance:** **commands v0.3.2 (2024-06-14), streams v0.1.11 (2024-02-29); repos last pushed 2024-07 and 2024-03.** Over two years dormant. **Treat as abandoned.**
- **Popularity:** 325 ★ / 270 ★ · **33.5k and 102k gem downloads total** — negligible.
- **License:** MIT.
- **Verdict: AVOID (abandoned).**

### turbo_ready
- **Repo/site:** `hopsoft/turbo_ready` — **the repo now redirects to https://github.com/hopsoft/turbo_boost-streams** (it was renamed). Author is Nate Hopkins (hopsoft), *not* julianrubisch.
- **What:** Bridged CableReady-style operations into Turbo Streams; the earlier name for what became `turbo_boost-streams`.
- **Maintenance:** **gem v0.1.4, 2022-12-12 — nearly four years stale. 39k downloads. Dead name.**
- **Verdict: AVOID (dead) / superseded-by turbo_boost-streams (itself dormant) → in practice, `turbo_power`.** Don't reference this name in new docs.

### mrujs
- **Repo/site:** https://github.com/KonnorRogers/mrujs (the old `ParamagicDev/mrujs` URL redirects here) · https://mrujs.netlify.app
- **What:** A modern TypeScript replacement for `rails-ujs` (MutationObserver + fetch instead of jQuery-era code), for apps that still need `data-remote`, `data-method`, and `data-confirm` without adopting Turbo.
- **Install:** `bin/importmap pin mrujs`
- **Maintenance:** **v1.0.2, 2024-08-16. 6.1k npm downloads/month.** Repo pushed 2026-01-20 but no release in two years. Dormant.
- **Popularity:** 172 ★.
- **License:** MIT.
- **Verdict: AVOID unless you are specifically migrating a Rails 6 UJS app.** `rails-ujs` itself was removed from Rails 8 defaults, and if you're modernizing you should be going to Turbo, not to a better UJS. `@stimulus-components/remote-rails` exists for the same legacy audience.

### turbo-mount
- **Repo/site:** https://github.com/skryukov/turbo-mount
- **What:** Mount React/Vue/Svelte components inside Rails views from a Stimulus controller — the sanctioned escape hatch when a genuinely-JS widget is unavoidable.
- **Install:**
  ```bash
  bundle add turbo-mount
  bin/rails generate turbo_mount:install
  ```
- **Example:**
  ```erb
  <%= turbo_mount("Clock", props: { time: Time.current }) %>
  ```
- **Maintenance:** v0.4.4 (2025-12-25), repo pushed 2026-07-25. Actively maintained.
- **Popularity:** 476 ★ · 231k gem downloads.
- **License:** MIT.
- **Verdict: STUDY / adopt as an escape hatch.** For a repo whose thesis is "rich UI without React," this is the honest answer to "but what about the 2% that really does need React" — and it's worth documenting *precisely where that line is*.

### Dev-loop tools

**hotwire-spark** (37signals — repo is `hotwired/spark`; `basecamp/hotwire-spark` redirects there) — live reload for Rails: reloads HTML via morphing, CSS without a page reload, and Stimulus controllers in place. v0.1.13 (2025-01-25), repo pushed 2025-04-29, 462 ★, 592k downloads, MIT. **Verdict: adopt** — it's 37signals' own tool and the morph-based reload is noticeably better than a full refresh, but note it has been quiet for ~16 months.

**hotwire-livereload** (kirillplatonov) — the community predecessor; watches `app/views`, `app/assets`, `app/helpers` and pushes a reload over ActionCable. v2.1.1 (2025-10-14), 554 ★, 1.9M downloads, MIT. **Verdict: adopt** — more recently released than hotwire-spark and slightly more configurable; pick one, not both.

**stimulus-parser / stimulus-lsp** (marcoroth) — a static analyser for Stimulus controllers and the LSP built on it (autocomplete and diagnostics for `data-controller`, targets, values, and actions in ERB). stimulus-lsp: 303 ★, pushed 2026-08-10; stimulus-parser: 45 ★, pushed 2026-08-13. Both MIT and **actively maintained**. **Verdict: adopt** — and note for crosswire: if our controllers are parseable by stimulus-parser, editors get autocomplete for our data attributes for free. That's a real, cheap differentiator.

## 6. Form, input & data gems that pair with Hotwire

### 6.1 Forms & rich text

#### simple_form
- **Repo/site:** https://github.com/heartcombo/simple_form
- **What:** The de facto Rails form builder — infers input type from the column/association and wraps it in configurable markup.
- **Install:** `gem "simple_form"` + `rails generate simple_form:install`
- **Example:**
  ```erb
  <%= simple_form_for @user do |f| %>
    <%= f.input :username %>
    <%= f.input :description, as: :text %>
    <%= f.association :roles, as: :check_boxes %>
    <%= f.button :submit %>
  <% end %>
  ```
- **Maintenance:** v5.4.1 (2026-01-05), repo pushed 2026-04-01. Boring and healthy.
- **Popularity:** 8,227 ★ · **97.0M gem downloads.** License: MIT.
- **Verdict: ADOPT.** Still the safe default in 2026. Its wrapper DSL is a mini-language you learn once; beyond basic Bootstrap/Tailwind it gets fiddly. **Crosswire should ship simple_form wrappers for its form components** — that's how you meet the majority of Rails apps where they are.

#### formtastic
- **Repo/site:** https://github.com/formtastic/formtastic
- **What:** The older, more opinionated semantic-markup form builder that predated simple_form.
- **Maintenance:** **v6.0.0 released 2026-02-20** (Rails 7.2+/Ruby 3.1+) — a genuine major bump, so not dead, but only 3 open issues and CI-modernization commits.
- **Popularity:** 5,215 ★ · 62.9M downloads. License: MIT.
- **Verdict: AVOID for new work.** A "your team already has it" gem, never a "let's add this" gem. simple_form has the mindshare, the integrations, and the docs.

#### superform
- **Repo/site:** https://github.com/rubymonolith/superform
- **What:** Phlex-component forms where **the form declares its own permitted strong parameters** — the most interesting idea in Rails forms right now.
- **Example:**
  ```ruby
  class Views::Posts::Form < Components::Form
    def view_template
      Field(:title).text
      Field(:body).textarea(rows: 10)
      Field(:featured).checkbox
      submit
    end
  end
  ```
  ```ruby
  class PostsController < ApplicationController
    include Superform::Rails::StrongParameters

    def create
      @post = Post.new
      save(Views::Posts::Form.new(@post)) ? redirect_to(@post) : render(:new, status: :unprocessable_entity)
    end
  end
  ```
- **Maintenance:** v0.7.0 (2026-03-02), 245 commits, active (a `datalist` component landed March 2026).
- **Popularity:** 392 ★ · 37k downloads. License: MIT.
- **Verdict: STUDY.** Pre-1.0 and requires full Phlex buy-in, but the auto-permitting trick is worth knowing regardless of whether you adopt it.

#### hotwire_combobox
- **Repo/site:** https://github.com/josefarias/hotwire_combobox · https://hotwirecombobox.com
- **What:** **The single best-designed component in the entire Hotwire ecosystem** — an accessible, Turbo-native combobox/autocomplete with server-side filtering.
- **Install:**
  ```ruby
  gem "hotwire_combobox"
  ```
- **Example:**
  ```erb
  <%# static collection %>
  <%= combobox_tag "state", State.all, id: "state-box" %>

  <%# async: pass a path; the controller receives params[:q] %>
  <%= combobox_tag "author", authors_path, name_when_new: "author[name]" %>
  ```
  ```ruby
  # authors_controller.rb
  def index
    @authors = Author.where("name ILIKE ?", "%#{params[:q]}%")
    render json: {}, layout: false  # or:
    respond_to { |f| f.html { render partial: "hotwire_combobox/option", ... } }
  end
  ```
- **API surface:** collections accept an `ActiveRecord::Relation` (uses `#to_combobox_display`/`#id`), a URL/path (enables async server-driven filtering with `params[:q]` and `:next_page` pagination), a Hash, `[display, value]` pairs, or hashes with explicit `display:`/`value:`. Options include `mobile_at:` (breakpoint below which it switches to a native `<dialog>` mobile UI), `name_when_new:` (free-text / "select existing or create new"), `value:`, `render_in:` (custom option partial), `autocomplete: :list|:inline|:both`, `dialog_label:`, `input: {}`, `open:`, `association_name:`. Multiselect is supported.
- **Accessibility:** explicitly implements the **W3C APG combobox pattern**, with three documented, deliberate deviations (wrap-around arrow navigation; label association left to the developer; a live-region announcement mechanism for multiselect, since W3C has no finalized multiselect combobox pattern). This is the only project in this survey with a stated accessibility posture.
- **Maintenance:** gem v0.4.1 (2026-02-13), last commit 2026-08-10. **Actively maintained**, single maintainer, still pre-1.0.
- **Popularity:** 652 ★ · 776k gem downloads. License: MIT.
- **Verdict: ADOPT — and study it as the model for what a Hotwire component should be.** It ships a Stimulus controller *and* a Rails helper that generates the markup, so consumers never hand-write `data-` attributes. That "component + helper" pairing is the thing nothing else in this survey does, and it's exactly why it's the nicest thing here to actually use.

#### lexxy
- **Repo/site:** https://github.com/basecamp/lexxy · https://lexxy.dev/docs/
- **What:** 37signals' Lexical-based (Meta's editor framework) rich text editor for Rails — **the successor to Trix**.
- **Install:**
  ```ruby
  gem "lexxy"
  ```
  ```bash
  bin/importmap pin @37signals/lexxy   # or: yarn add @37signals/lexxy
  ```
- **Example:** none needed — **once installed, Lexxy takes over ActionText automatically.** Existing `form.rich_text_area` calls render a Lexxy editor instead of Trix, with no code change. On Rails 8.2+ it registers as the default ActionText editor adapter; on 8.0–8.1 it overrides ActionText's form helpers directly (overridable for incremental migration).
- **Why it exists:** real `<p>` tags instead of Trix's div soup, markdown shortcuts and paste auto-formatting, live code syntax highlighting, link-on-paste, configurable prompts (mentions), and in-editor previews for PDF/video attachments — while emitting **the same canonical HTML ActionText expects**, so existing rich text data stays compatible.
- **Maintenance:** v0.9.29 (2026-08-07), commits on 2026-08-11 including a DOMPurify security fix. **Very active** — 2,129 commits, 61 open PRs.
- **Popularity:** 1,210 ★ · 521k gem downloads. License: MIT.
- **Verdict: ADOPT on Rails 8.x.** This is the most significant new thing in the Rails UI world in the last year. **Caveat:** still 0.9.x, and there is **no formal Rails-core deprecation of Trix** — Trix is still what `rails new` gives you. Read Lexxy as the vendor-endorsed successor that hasn't been promoted into core defaults yet, and validate the ActionText HTML compatibility claim against your existing content before flipping an app over wholesale.

#### ActionText / Trix
- **Repo/site:** https://github.com/basecamp/trix
- **Maintenance:** trix v2.1.19 (2026-05-09), 20.0k ★, healthy. `actiontext` ships with Rails (8.1.3.1, 2026-07-29, 433M downloads).
- **Verdict: ADOPT (it's the default) / plan to migrate.** Trix is maintained but its long-standing complaints — div-based paragraphs that break copy-paste semantics, no markdown shortcuts, no syntax highlighting — are exactly what Lexxy was built to fix, by the same team.

### 6.2 File uploads

#### ActiveStorage direct upload
- **What:** Rails' built-in browser→storage direct upload. Ships **no UI** — just events.
- **Example:**
  ```erb
  <%= form.file_field :avatar, direct_upload: true,
        data: { controller: "upload-progress", upload_progress_target: "input" } %>
  ```
  ```js
  // upload_progress_controller.js
  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static targets = ["bar"]

    connect() {
      this.element.addEventListener("direct-upload:initialize", this.init)
      this.element.addEventListener("direct-upload:progress", this.progress)
      this.element.addEventListener("direct-upload:error", this.error)
    }

    disconnect() {   // ← required: Turbo caches and restores this page
      this.element.removeEventListener("direct-upload:initialize", this.init)
      this.element.removeEventListener("direct-upload:progress", this.progress)
      this.element.removeEventListener("direct-upload:error", this.error)
    }

    init     = () => { this.barTarget.style.width = "0%" }
    progress = (e) => { this.barTarget.style.width = `${e.detail.progress}%` }
    error    = (e) => { e.preventDefault(); console.error(e.detail.error) }
  }
  ```
- **The full event table** (a frequent source of bugs — most events fire on the **`<input>`**, not the form):

  | Event | Fires on | `event.detail` |
  |---|---|---|
  | `direct-uploads:start` | `<form>` | — |
  | `direct-upload:initialize` | `<input>` | `{id, file}` |
  | `direct-upload:start` | `<input>` | `{id, file}` |
  | `direct-upload:before-blob-request` | `<input>` | `{id, file, xhr}` |
  | `direct-upload:before-storage-request` | `<input>` | `{id, file, xhr}` |
  | `direct-upload:progress` | `<input>` | `{id, file, progress}` |
  | `direct-upload:error` | `<input>` | `{id, file, error}` — cancel the event to suppress the default `alert()` |
  | `direct-upload:end` | `<input>` | `{id, file}` |
  | `direct-uploads:end` | `<form>` | — |

- **Verdict: ADOPT** for the common case, and **this is a Tier-1 gap** (§9 #5): Rails gives you the events and nothing else, so every app hand-rolls the same progress bar, drag-drop zone, and image preview.

#### shrine
- **Repo/site:** https://github.com/shrinerb/shrine
- **What:** The powerful ActiveStorage alternative — plugin-based, with first-class presigned direct uploads.
- **Example:**
  ```ruby
  Shrine.plugin :presign_endpoint
  # routes.rb
  mount Shrine.presign_endpoint(:cache) => "/s3/params"
  ```
  Uppy's AwsS3 plugin then fetches params from `/s3/params` before each upload.
- **Maintenance:** v3.9.0 (2026-07-13), repo pushed 2026-07-13. Healthy.
- **Popularity:** 3,286 ★ · 17.6M downloads. License: MIT.
- **Verdict: STUDY / adopt when you outgrow ActiveStorage.** Shrine treats Uppy as a first-class partner (official walkthrough) in a way ActiveStorage doesn't. If you need resumable uploads, a drag-drop dashboard, or multi-source input (webcam, Drive), shrine + Uppy is the more capable combo.

**ActiveStorage vs Uppy — what Rails devs actually do:** ActiveStorage direct upload is the default for straightforward attach-to-a-record flows (zero extra JS deps). Uppy gets reached for specifically when you need resumable/chunked uploads for large files, a polished dashboard UI, multi-source input, or you're already on Shrine. No hard usage-share data exists — this is a qualitative read.

### 6.3 Pagination, search & tables

#### pagy
- **Repo/site:** https://github.com/ddnexus/pagy · https://ddnexus.github.io/pagy
- **What:** The fast, low-memory pagination gem — **now at v43.x, which is a ground-up rewrite, not an increment.**
- **⚠️ Everything you remember about pagy 6/9 is wrong.** ddnexus describes v43 as *"a complete redesign of the legacy code at all levels, usage and API included."* The config surface was cut drastically, methods autoload, and it now supports multiple pagination strategies (`:offset`, `:keyset`, `:countish`, `:keynav_js`) rather than offset alone.
- **Install:** `gem "pagy"`
- **Current API:**
  ```ruby
  class ProductsController < ApplicationController
    include Pagy::Method

    def index
      @pagy, @products = pagy(:offset, Product.all)
    end
  end
  ```
  ```erb
  <%== @pagy.series_nav %>       <%# server-rendered nav %>
  <%== @pagy.series_nav_js %>    <%# client-rendered, fills container width %>
  <%== @pagy.input_nav_js %>     <%# compact nav + info %>
  ```
- **Hotwire integration:** pagy's nav helpers emit ordinary links/forms, so wrapping them in a `turbo_frame_tag` is the whole integration — the frame intercepts the link and swaps itself. The `_js` variants ship a small vanilla JS that re-renders on resize; they compose fine inside frames. **⚠️ `ddnexus.github.io/pagy/docs/extras/` 404s** — there is no discrete named "Turbo extra" we could confirm; the frame-wrapping pattern is the integration.
- **Maintenance:** v43.6.1 (2026-07-21), repo pushed 2026-08-14. **Extremely active.**
- **Popularity:** 4,986 ★ · 42.1M downloads. License: MIT.
- **Verdict: ADOPT.** The right pagination choice in 2026 by a wide margin — but **budget real time for the upgrade guide** if you're coming from pre-v43.

#### kaminari
- **Repo/site:** https://github.com/kaminari/kaminari
- **Maintenance:** **last gem release v1.2.2, 2021-12-25 — four and a half years.** The repo isn't dead (commits through Feb 2026, "CI against Ruby 4.0"), but it's pure compatibility maintenance: 50 open issues, 24 open PRs mostly unmerged.
- **Popularity:** 8,673 ★ · **268M downloads** (the install base is enormous and historical). License: MIT.
- **Verdict: SUPERSEDED-BY pagy.** Functionally frozen. Don't rip it out of a working app; never choose it for a new one.

#### will_paginate
- v4.0.1 (2024-06-10), 5,688 ★, 107M downloads, MIT, repo pushed 2025-11-24. **Verdict: superseded-by-pagy.** Noted for completeness only.

#### ransack
- **Repo/site:** https://github.com/activerecord-hackery/ransack
- **What:** Object-based search/filter/sort for ActiveRecord, driven by query params (`name_cont`, `price_gteq`, …).
- **Install:** `gem "ransack"`
- **Example — the canonical Turbo Frame filtering pattern:**
  ```ruby
  # app/models/product.rb — MANDATORY since Ransack 4.0
  def self.ransackable_attributes(_auth_object = nil) = %w[name price category]
  ```
  ```erb
  <%= search_form_for @q, url: products_path, html: { data: { turbo_frame: "results" } } do |f| %>
    <%= f.search_field :name_cont, data: { controller: "auto-submit",
                                           action: "input->auto-submit#submit" } %>
  <% end %>

  <%= turbo_frame_tag "results" do %>
    <%= render @products %>
  <% end %>
  ```
  Ransack 4.x also ships `turbo_search_form_for` for submitting via Turbo Streams with `turbo_frame:` targeting and a configurable Turbo action.
- **Maintenance:** v4.4.1 (2025-09-29), repo pushed 2026-05-31, Rails 8.1 support. Active.
- **Popularity:** 5,863 ★ · 116M downloads. License: MIT.
- **Verdict: ADOPT.** ⚠️ **Since 4.0 the `ransackable_attributes` / `ransackable_associations` allowlist is mandatory** (a real security fix). Any pre-4.0 blog-post example that skips it will error or silently return nothing.

#### Hotwire-native tables — **nothing exists**
Searched thoroughly. There is no actively-maintained, adopted gem packaging "sortable + filterable + paginated Turbo Frame table" as a reusable component. What exists:
- **hot-glue** (jasonfb) — a Turbo/Hotwire *scaffold generator* (v0.7.7, June 2026), not a drop-in table component.
- Everything else is blog-post patterns: hand-rolled `<table>` + Turbo Frame + Ransack/Pagy + a ~10-line Stimulus auto-submit controller, reassembled per app.

**This is the single biggest packaged-solution gap in the ecosystem** — see §9 #1.

### 6.4 Admin frameworks — what to steal

Admin frameworks have all solved the hard UI problems internally; none of it is extractable. Here's what each one teaches.

#### avo
- **Repo/site:** https://avohq.io · https://github.com/avo-hq/avo
- **Built with:** **pure Hotwire.** Verified from `package.json`: `@hotwired/stimulus`, `@hotwired/turbo-rails`, `@rails/request.js`, `@github/hotkey`, plus TipTap for rich text. **No React or Vue in avo core.**
- **Maintenance:** v4.1.10 (2026-08-14), repo pushed 2026-08-15. Extremely active.
- **Popularity:** 1,797 ★ · 3.0M downloads. **License: LGPL-3.0 + Commercial** (open core; Pro/Advanced tiers are paid).
- **Hotwire lesson:** avo depends on **`@github/hotkey`** for its admin-wide keyboard shortcuts rather than hand-rolling keybinding logic — a concrete, production-validated example of composing a `@github/*` web component with Stimulus. Its resource/field abstraction is also the best worked example of "one Ruby declaration drives both the form and the table cell."
- **Verdict: STUDY.** The most Hotwire-native admin framework in existence and the best single codebase to read for Turbo-driven admin UI.

#### administrate
- **Repo/site:** https://github.com/thoughtbot/administrate
- **Built with:** deliberately plain server-rendered ERB, **no client JS layer at all**. Uses kaminari.
- **Maintenance:** v1.0.0 (2025-10-31), repo pushed 2026-08-12. Active. 6,031 ★ · 9.1M downloads. MIT.
- **Hotwire lesson:** its "no DSL — override with plain Rails controllers and views" philosophy. Every field renderer is a normal partial you can override. **This is the right template for a component library's escape-hatch story:** a plain view override is always available and you never need a proprietary config language to go off the rails.
- **Verdict: STUDY.**

#### activeadmin
- **Built with:** **still jQuery + Arbre** (its Ruby view DSL) even in the 4.0 betas — `jquery-rails` and `arbre` remain dependencies. Stimulus integration exists only as community add-on patterns.
- **Maintenance:** v3.5.2 (2026-07-13), repo pushed 2026-08-11. Active but architecturally legacy. 9,705 ★ · 50.2M downloads. MIT.
- **Hotwire lesson:** its **batch actions** UI — checkbox row selection that persists across a paginated table, plus a floating bulk-action bar. The implementation is legacy jQuery but **the interaction design is exactly what a Stimulus component library should ship out of the box** and nobody has.
- **Verdict: STUDY the interaction, avoid the implementation.**

#### madmin
- **Repo/site:** https://github.com/excid3/madmin — Chris Oliver's minimal admin.
- **Built with:** explicitly "Stimulus/Hotwire ready," Rails-scaffold-like resource classes with a minimal DSL.
- **Maintenance:** v2.5.1 (2026-08-12), repo pushed 2026-08-14. Active. 760 ★ · 485k downloads. MIT.
- **Hotwire lesson:** its resource-class-generates-scaffold approach mirrors `rails g scaffold` conventions, so the admin feels like *more Rails* rather than a separate framework bolted on. A design-taste lesson: **match the framework's existing conventions instead of inventing parallel ones.**
- **Verdict: STUDY.**

#### motor-admin
- **Repo/site:** https://github.com/motor-admin/motor-admin
- **Built with:** **a Vue 3 SPA** mounted by a Rails engine, talking to a Rails API. **This is not Hotwire.**
- **Maintenance:** gem v0.5.0 (2026-02-01) but **repo last pushed 2024-05-30 — over two years.** Dormant. 2,163 ★ · 691k downloads. **License: AGPL-3.0** (viral — a real consideration).
- **Hotwire lesson:** its **fully UI-driven, no-DSL configuration** — you build reports, dashboards, and custom actions by clicking through settings, persisted to a version-controllable YAML file. That "config as data, not code" pattern is orthogonal to the SPA choice and could be replicated with Turbo Frames + server-persisted config.
- **Verdict: AVOID (dormant + AGPL) / study the config-as-data idea.**

## 7. JavaScript libraries commonly wired to Stimulus

All figures verified 2026-08-15 from the npm registry, `api.npmjs.org/downloads`, and the GitHub API.

### 7.1 Health & wrapper matrix

| Library | npm | Latest | Published | ★ | npm/mo | License | Health | Maintained Stimulus wrapper? |
|---|---|---|---|---|---|---|---|---|
| SortableJS | `sortablejs` | 1.15.7 | 2026-02-11 | 31.2k | 17.1M | MIT | healthy | ✅ `@stimulus-components/sortable` |
| Swiper | `swiper` | 14.1.0 | 2026-08-06 | 41.9k | 17.3M | MIT | healthy | ✅ `@stimulus-components/carousel` |
| Chart.js | `chart.js` | 4.5.1 | 2025-10-13 | 67.6k | 53.7M | MIT | healthy | ⚠️ `@stimulus-components/chartjs` (60-line pass-through) |
| Trix | `trix` | 2.1.19 | 2026-05-09 | 20.0k | 2.3M | MIT | healthy | n/a — ships with ActionText |
| Pickr | `@simonwep/pickr` | 1.9.1 | — | 4.5k | — | MIT | healthy | ✅ `@stimulus-components/color-picker` |
| lightGallery | `lightgallery` | 2.9.0 | 2025-10-01 | 7.0k | 396k | **GPLv3** | healthy | ✅ `@stimulus-components/lightbox` ⚠️ licence |
| date-fns | `date-fns` | 4.4.0 | 2026-05-29 | — | 390M | MIT | healthy | ✅ via `@stimulus-components/timeago` |
| **Floating UI** | `@floating-ui/dom` | 1.8.0 | 2026-07-11 | 32.7k | **372M** | MIT | healthy | ❌ **none** |
| Popper v2 | `@popperjs/core` | 2.11.8 | **2023-05-26** | — | 96M | MIT | **frozen** | ❌ — superseded by Floating UI |
| Tippy.js | `tippy.js` | 6.3.7 | **2021-11-10** | 12.3k | 25.4M | MIT | **ARCHIVED 2024-05** | ❌ — superseded by Floating UI |
| Tom Select | `tom-select` | 2.6.2 | 2026-07-07 | 2.2k | 1.3M | Apache-2.0 | healthy | ⚠️ 21★, dead since 2023-02 |
| Slim Select | `slim-select` | 4.0.7 | 2026-07-22 | 1.3k | 316k | MIT | healthy | ❌ **none** |
| Choices.js | `choices.js` | 11.2.3 | 2026-04-30 | 6.8k | 2.3M | MIT | healthy (revived) | ❌ **none** |
| Flatpickr | `flatpickr` | 4.6.13 | **2022-04-14** | 16.5k | 7.1M | MIT | **stale** (repo 2024-08) | ⚠️ 422★, dead since 2023-10 |
| Litepicker | `litepicker` | 2.0.12 | **2021-10-26** | 907 | 147k | MIT | **ARCHIVED 2023** | ❌ |
| Cropper.js | `cropperjs` | 2.1.1 | 2026-04-06 | 13.9k | 6.6M | MIT | healthy (v2 rewrite) | ❌ **none** |
| Uppy | `@uppy/core` | 5.2.0 | 2025-12-02 | 30.9k | 4.5M | MIT | healthy | ❌ **none** |
| Fuse.js | `fuse.js` | 7.5.0 | 2026-07-13 | 20.4k | 49.7M | Apache-2.0 | healthy | ❌ **none** |
| hotkeys-js | `hotkeys-js` | 4.0.5 | 2026-08-14 | 7.1k | 5.6M | MIT | healthy | ⚠️ only `stimulus-use/hotkeys` |
| Idiomorph | `idiomorph` | 0.7.4 | 2025-09-29 | 1.1k | 260k | 0BSD | healthy | n/a — vendored inside Turbo 8 |
| El Transition | `el-transition` | 0.0.7 | **2020-09-10** | 215 | 114k | MIT | **dead** | n/a |
| `@rails/request.js` | — | 0.0.13 | 2025-12-11 | 439 | 1.16M | MIT | healthy | n/a |
| Motion | `motion` | 13.1.0 | 2026-08-10 | 33.3k | 69M | MIT | healthy | ❌ **none** |
| Lit | `lit` | 3.3.3 | 2026-05-14 | 21.8k | 27.9M | BSD-3 | healthy | n/a (alternative approach) |
| Shoelace | `@shoelace-style/shoelace` | 2.20.1 | 2025-03-11 | 13.9k | 572k | MIT | **ARCHIVED** → Web Awesome | n/a |

### 7.2 GitHub web components (`@github/*`)

A genuinely underrated complement to Stimulus: small, accessible, framework-free custom elements that GitHub runs in production. They compose with Stimulus rather than competing with it — the custom element handles the a11y/keyboard mechanics, the Stimulus controller handles the Rails wiring.

| Package | Latest | Published | ★ | npm/mo | Status |
|---|---|---|---|---|---|
| `@github/relative-time-element` | 5.3.1 | 2026-08-03 | 4.0k | 430k | ✅ healthy — a better `timeago` than any Stimulus wrapper |
| `@github/combobox-nav` | 3.0.2 | 2026-06-30 | — | 316k | ✅ healthy — the keyboard-nav half of a combobox |
| `@github/hotkey` | 3.1.4 | 2026-03-16 | 3.3k | 118k | ✅ healthy |
| `@github/auto-complete-element` | 3.8.0 | 2025-03-11 | 405 | 206k | ⚠️ quiet (17 months) |
| `@github/details-dialog-element` | 3.1.4 | **2022-08-15** | 763 | 6.5k | ❌ **ARCHIVED** — use `<dialog>` |

**Verdict: study / selectively adopt.** `relative-time-element` in particular is a drop-in that beats `@stimulus-components/timeago` (no `date-fns` dependency, better i18n, `<time>` semantics, no JS needed to hydrate). `combobox-nav` is the right foundation for a Tier-1 combobox. Do **not** build on `details-dialog-element` (archived) or Shoelace (archived → the commercial Web Awesome).

### 7.3 Hand-rolled wrapper recipes (for the libraries with no wrapper)

Every one of these follows the same shape, and **`disconnect()` is the load-bearing part** — Turbo caches and restores pages, so a controller that instantiates a third-party widget in `connect()` and doesn't destroy it in `disconnect()` leaks on every navigation and often double-initialises on restore.

```js
// floating_controller.js — tooltips/popovers/menus. Replaces Tippy (archived) and Popper (frozen).
import { Controller } from "@hotwired/stimulus"
import { computePosition, autoUpdate, offset, flip, shift } from "@floating-ui/dom"

export default class extends Controller {
  static targets = ["reference", "floating"]
  static values = { placement: { type: String, default: "top" } }

  connect() {
    // autoUpdate returns its own cleanup function — this is the whole trick
    this.cleanup = autoUpdate(this.referenceTarget, this.floatingTarget, () => {
      computePosition(this.referenceTarget, this.floatingTarget, {
        placement: this.placementValue,
        middleware: [offset(6), flip(), shift({ padding: 8 })]
      }).then(({ x, y }) => {
        Object.assign(this.floatingTarget.style, { left: `${x}px`, top: `${y}px` })
      })
    })
  }

  disconnect() { this.cleanup?.() }   // skipping this leaks scroll+resize listeners
}
```

```js
// slim_select_controller.js  (identical shape for choices.js: new Choices(...) / .destroy())
import { Controller } from "@hotwired/stimulus"
import SlimSelect from "slim-select"

export default class extends Controller {
  connect() {
    this.slim = new SlimSelect({ select: this.element, settings: { showSearch: true } })
  }

  disconnect() {
    this.slim.destroy()
    this.slim = null
  }
}
```

```js
// uppy_controller.js
import { Controller } from "@hotwired/stimulus"
import Uppy from "@uppy/core"
import Dashboard from "@uppy/dashboard"
import XHRUpload from "@uppy/xhr-upload"

export default class extends Controller {
  connect() {
    this.uppy = new Uppy()
      .use(Dashboard, { inline: true, target: this.element })
      .use(XHRUpload, { endpoint: "/uploads" })
  }

  disconnect() { this.uppy.destroy() }   // `destroy()`, not the pre-4.0 `close()`
}
```

```js
// fuzzy_search_controller.js — client-side filtering with Fuse.js
import { Controller } from "@hotwired/stimulus"
import Fuse from "fuse.js"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = { data: Array }

  connect() { this.fuse = new Fuse(this.dataValue, { keys: ["name"], threshold: 0.3 }) }
  disconnect() { this.fuse = null }

  search() {
    const hits = this.fuse.search(this.inputTarget.value)
    this.resultsTarget.innerHTML = hits.map((h) => `<li>${h.item.name}</li>`).join("")
  }
}
```

**⚠️ Cropper.js v2 changed shape entirely.** v2 is a rewrite to **Web Components** (`<cropper-canvas>`, `<cropper-image>`, `<cropper-selection>`) — there is no `new Cropper(img, opts)` any more. The Stimulus controller now just listens to the custom element's own events:

```js
import { Controller } from "@hotwired/stimulus"
import "cropperjs"   // registers the custom elements

export default class extends Controller {
  static targets = ["selection"]

  connect()    { this.selectionTarget.addEventListener("change", this.onCrop) }
  disconnect() { this.selectionTarget.removeEventListener("change", this.onCrop) }

  onCrop = (event) => this.dispatch("cropped", { detail: event.detail })
}
```

### 7.4 The date-picker situation (there is no good answer)

- **flatpickr** — no npm release since **2022-04-14**, yet still by far the most-downloaded vanilla date picker (~7.1M/month). Pure inertia.
- **Litepicker** — archived.
- **easepick** — real, actively-referenced, Shadow-DOM-based, dependency-free; niche adoption.
- **vanillajs-datepicker / air-datepicker / Duet Date Picker** — legitimate alternatives, none has displaced flatpickr's mindshare.
- **Native `<input type="date">`** — increasingly the pragmatic 2026 recommendation for single dates: mature browser support, zero payload.

**Honest guidance:** use `<input type="date">` unless you specifically need range selection or heavy styling; if you do, flatpickr (stale but stable) or easepick. **Nobody has packaged the "native where possible, enhanced where necessary" pattern** — see §9 #3.

### 7.5 Turbo + the View Transitions API

Turbo 8 **does** support cross-document view transitions. Verified from source:

```js
// src/core/drive/page_view.js
shouldTransitionTo(newSnapshot) {
  return this.snapshot.prefersViewTransitions && newSnapshot.prefersViewTransitions
}

// src/core/drive/page_snapshot.js
get prefersViewTransitions() {
  const enabled = this.getSetting("view-transition") === "true" ||
                  this.headSnapshot.getMetaValue("view-transition") === "same-origin"
  return enabled && !window.matchMedia("(prefers-reduced-motion: reduce)").matches
}
```

Opt in with:

```html
<meta name="view-transition" content="same-origin">
<!-- or -->
<meta name="turbo-view-transition" content="true">
```

**Caveats, and they matter:**

- **The meta tag must be on BOTH pages** — `shouldTransitionTo` requires `prefersViewTransitions` on the current *and* the incoming snapshot. A transition that "sometimes works" is almost always this.
- It **automatically respects `prefers-reduced-motion: reduce`** — you get accessibility for free, and a confusing "it doesn't work on my machine" if you have that set.
- Turbo suppresses its own snapshot caching on pages carrying the tag (cached snapshots fight the animation), and adds `data-turbo-visit-direction` to `<html>` so you can write directional CSS for forward vs back.
- Only **one transition runs at a time** — a new one interrupts and snap-finishes the previous.
- `data-turbo-permanent` elements can visually disappear or misbehave under view transitions (open upstream issue).
- Safari 18 supports it but you can't disable its native swipe-back animation, producing a doubled animation on gesture navigation.
- **It is designed around full-page Drive visits.** Mixing it with Turbo Frame updates is a well-known source of bugs. For Frame and Stream updates, use CSS or `motion`.

### 7.6 Transitions without JavaScript: `@starting-style`

`el-transition` (last release 2020) should not be used. The modern native replacement for the whole "double-`requestAnimationFrame` to fake a starting state" trick is **CSS `@starting-style` + `transition-behavior: allow-discrete`**, at roughly 86% browser support as of late 2025:

```css
dialog[open] {
  opacity: 1;
  transition: opacity 0.3s, display 0.3s allow-discrete;
}
@starting-style {
  dialog[open] { opacity: 0; }
}
```

This is a genuinely important development for a Hotwire component library: **it removes the need for a JS transition layer entirely in modern browsers**, and it solves the `<dialog>` + transition problem that forced tailwindcss-stimulus-components to fall back to CSS animations (§3). Where you still need JS sequencing or older-browser support, the maintained options are the `transition` module in `tailwindcss-stimulus-components` or `stimulus-use`'s `useTransition`.
## 8. What good looks like

Distilled from reading the source of the best-run projects in this survey — primarily **stimulus-components** (best repo engineering), with **tailwindcss-stimulus-components** (best runtime design), **RubyUI** (best distribution model), and **Primer ViewComponents** (best proof of scale) as counterpoints.

### 8.1 Repository shape

stimulus-components' layout, verified at `45fd9ec`:

```
stimulus-components/
├── components/           # one publishable package per directory
│   └── <name>/
│       ├── src/index.ts      # the controller — one default export
│       ├── spec/index.test.ts # Vitest + jsdom
│       ├── index.html         # standalone dev harness (vite dev server)
│       ├── vite.config.mts    # lib-mode build
│       ├── tsconfig.json      # { "extends": "../../tsconfig.json" }
│       ├── package.json
│       ├── README.md          # short; links to the docs site
│       ├── CHANGELOG.md       # Keep a Changelog format, generated by changesets
│       └── LICENSE
├── docs/                 # Nuxt 3 + Nuxt Content documentation site
├── utils/index.ts        # shared debounce / throttle / sleep
├── .changeset/           # one markdown file per pending release bump
├── .github/workflows/    # ci.yml + release.yml
├── .cursor/skills/create-new-component/SKILL.md   # agent playbook
├── CLAUDE.md             # contributor/agent guide
├── pnpm-workspace.yaml   # packages: docs, components/**
├── tsconfig.json  eslint.config.mjs  .prettierrc  vitest.config.mts
```

**Takeaways:**

1. **One directory = one publishable unit = one docs page = one demo.** The 1:1:1:1 mapping is the whole trick. Adding a component touches a predictable set of files and nothing else.
2. **Per-component `index.html` dev harness.** `pnpm -C components/<name> dev` boots a Vite page with just that controller. This is the fastest possible inner loop and almost nobody does it.
3. **Shared code is deliberately tiny.** `utils/` holds three functions. Everything else is duplicated rather than abstracted, so packages stay independently installable with zero shared runtime dependency.
4. **`CLAUDE.md` + a `SKILL.md` playbook are checked in.** The repo documents *how to add a component* as an executable recipe with a checklist — naming table (folder / package name / controller id / class name / Vite lib name / file name), the file-by-file template, and the docs-registration steps. **We should do this from commit one.**

### 8.2 Packaging & distribution

Per-component `package.json` (dialog, verbatim structure):

```jsonc
{
  "name": "@stimulus-components/dialog",
  "main":   "dist/stimulus-dialog.umd.js",
  "module": "dist/stimulus-dialog.mjs",
  "types":  "dist/types/index.d.ts",
  "exports": {
    ".": { "types": "./dist/types/index.d.ts",
           "import": "./dist/stimulus-dialog.mjs",
           "require": "./dist/stimulus-dialog.umd.js" },
    "./src": "./src/index.ts",          // ← docs site imports TS source directly
    "./package.json": "./package.json"
  },
  "peerDependencies": { "@hotwired/stimulus": "^3" },
  "files": ["dist"],
  "sideEffects": false,
  "scripts": { "build": "vite build && pnpm run types", "prepack": "pnpm run build" }
}
```

Rules worth adopting verbatim:

- **Stimulus is a `peerDependency`, never a dependency.** Two copies of Stimulus in one bundle is a silent, miserable bug.
- **Ship UMD *and* ESM *and* types.** The UMD build exists purely so Sprockets and CDN users work: `window.StimulusCharacterCounter`. Rails apps are on four different asset pipelines (importmap, esbuild, Vite, Sprockets) and a component library that only ships ESM will lock out a third of them.
- **Keep the legacy `main`/`module`/`types` fields alongside `exports`** for older bundlers.
- **Expose `./src`** so the docs site consumes TypeScript sources directly — no build step between editing a controller and seeing it in the docs.
- **`"files": ["dist"]` + `prepack`** — the published tarball is build output only, and the build can't be forgotten.
- **`sideEffects: false`** for tree-shaking.
- **Vite lib mode with `external: ["@hotwired/stimulus"]`** and a `globals` map for the UMD build.
- **Importmap caveat, stated plainly in their docs:** *"importmaps don't work well with external dependencies. And it does not work with CSS at all."* Any component with a third-party dep or any CSS is effectively bundler-only. A library that wants importmap users needs zero-dependency components — a real design constraint.

### 8.3 Release engineering

- **changesets, not manual publishing.** `pnpm changeset` writes a markdown file describing the bump; the Release workflow opens a "Version Packages" PR; merging it publishes changed packages, generates per-package `CHANGELOG.md`, and tags. Config uses `@changesets/changelog-github` so changelogs link PRs and authors.
- **npm provenance** (`NPM_CONFIG_PROVENANCE: "true"`, `id-token: write`) — supply-chain attestation, near-free to enable.
- **Only changed packages get released.** With 32 packages this is the difference between a maintainable monorepo and a version-lockstep nightmare.
- **Changeset filenames are descriptive** (`prefetch-observer-leak.md`, `dropdown-aria-disclosure.md`) — the pending-release folder doubles as a to-do list.

### 8.4 CI

```yaml
# ci.yml — two jobs, on PR and on push to master
lint-and-test:  pnpm run lint   # tsc --noEmit + eslint
                pnpm run test   # vitest --run
build:          pnpm run build:components
                pnpm run -C docs generate   # prerender every docs route
```

- **Cancel superseded PR runs but never cancel a master run** (`cancel-in-progress: ${{ github.event_name == 'pull_request' }}`) so no commit on the default branch goes unverified. Small, correct detail.
- **Prerendering the docs site in CI is the integration test.** A missing demo component or a broken content reference fails the build rather than the deploy. For a component library whose docs *are* the product, this is the single highest-value CI job.
- **Lint = type-check + ESLint.** They learned the hard way that `tsc --noEmit` at the root and per-package declaration emit don't type-check identically (Node's `setTimeout` returns `NodeJS.Timeout`, the DOM's returns `number`), and documented it: *"Always run the component build before assuming type changes are clean."*

### 8.5 Testing conventions

The stimulus-components pattern — **drive a real Stimulus Application against a real DOM**, never unit-test the class in isolation:

```ts
/**
 * @vitest-environment jsdom
 */
import { Application } from "@hotwired/stimulus"
import CharacterCounter from "../src/index"

let application: Application

const startStimulus = (): void => {
  application = Application.start()
  application.register("character-counter", CharacterCounter)
}

afterEach((): void => { application.stop() })

describe("#update", () => {
  beforeEach(() => {
    startStimulus()
    document.body.innerHTML = `
      <div data-controller="character-counter">
        <textarea data-character-counter-target="input">${"a".repeat(1250)}</textarea>
        <strong data-character-counter-target="counter"></strong>
      </div>`
  })

  it("returns count", () => {
    expect(document.querySelector('[data-character-counter-target="counter"]').innerHTML)
      .toBe("1,250")
  })
})
```

Notes:

- **Test through the data attributes, not the class API.** The `data-*` contract *is* the public API of a Stimulus controller; testing `new Controller().update()` tests the wrong thing.
- **`application.stop()` in `afterEach`** — otherwise controllers leak across tests.
- Coverage today: **24 of 32 components have specs** (75%). The 8 without are exactly the thin third-party wrappers (carousel, chartjs, color-picker, lightbox, places-autocomplete, popover, sortable, sound, remote-rails) — i.e. the ones hardest to test in jsdom. That's an honest, defensible line, but note **`sortable` — the most-downloaded component — is untested.**
- **tailwindcss-stimulus-components tests in a real browser** (`@web/test-runner` + `@open-wc/testing`) instead of jsdom, and has specs for 7 of 9 controllers plus the transition utility. For anything touching layout, focus, `<dialog>`, or CSS transitions, **the real-browser approach is correct and jsdom will lie to you.** A serious library should probably do both: jsdom for logic, Playwright/web-test-runner for the visual/focus/transition surface.

### 8.6 Documentation site

stimulus-components' docs (Nuxt 3 + Nuxt Content + Tailwind 4 + Algolia DocSearch + Plausible, deployed on Netlify) are the best in the ecosystem. The structural rules:

- **One markdown file per component**, frontmatter carrying `title`, `description`, `package`, `packagePath`. The sidebar is generated by sorting that directory — **zero navigation config to maintain.**
- **Every page has the identical section order**: Installation → (optional alert about the underlying lib) → **live Example** → Usage → Configuration table → Extending Controller. Predictability beats prose.
- **A live, interactive demo on every page**, as a Vue component in `docs/components/content/Demo/<Name>.vue` referenced from markdown as `:component-name`. The demo imports the controller's **TypeScript source** via the `./src` export, so docs can never drift from code.
- **`::code-block{tabName="app/views/index.html.erb"}`** — every snippet is labelled with the file it belongs in. This one detail does more for comprehension than any amount of prose.
- **The Configuration table is the API reference**: `Attribute | Default | Description | Optional`, listing full data-attribute names (`data-sortable-animation-value`), not camelCase value names. Readers copy attributes, not JS identifiers.
- **A single global Installation page** covering all four Rails asset strategies (bundler, importmap, Sprockets, CDN) so per-component pages stay short.

**Where even the best docs fall short, and where crosswire can beat them:** no "when *not* to use this", no accessibility notes per component, no Turbo Frame/Stream/morph interaction notes, no "common mistakes", and no copy-paste-ready styled markup. Every one of those is a differentiator.

### 8.7 Runtime design rules (synthesized)

1. **Data attributes over classes for anything the markup should vary** — see the transition system in §3. Classes (`static classes`) are for *state* hooks; data attributes are for *configuration*.
2. **Subclassing is the extension seam.** Export the class as default, put defaults behind a `get defaultOptions()`, and call `super` in lifecycle methods. Don't try to expose every underlying-library option as a Stimulus value.
3. **`disconnect()` is not optional.** Turbo caches and restores pages; a controller that adds a document listener, an `IntersectionObserver`, a `setInterval`, or a third-party instance in `connect()` and doesn't tear it down in `disconnect()` will leak on every navigation. This is stimulus-components' single biggest current bug class — five of their nineteen pending changesets are teardown/leak fixes.
4. **Return Promises from animations** so callers can await before removing DOM.
5. **Make interruption a first-class case.** Rapid toggle is the normal case, not the edge case.
6. **Kebab-case everywhere, consistently.** Folder = package suffix = controller identifier = `data-controller` value; PascalCase class; `stimulus-<name>` build filename. One name, four renderings, zero decisions.

## 9. Gaps in the ecosystem

UI patterns that, as of 2026-08-15, have **no good maintained reusable answer** in the Hotwire world. Each is an opportunity for crosswire. Ordered roughly by (demand × emptiness).

### Tier 1 — big, common, genuinely unsolved

**1. Data tables.** Sortable columns, column filters, per-column search, sticky headers, row selection with a bulk-action bar, saved views, CSV export. Every Rails app builds one; nobody has shipped a reusable one. `pagy` + `ransack` give you the query half and nothing at all of the interaction half. The only things GitHub surfaces for "stimulus table sort" are two demo apps and a 0-star personal repo. Admin frameworks (Avo, Administrate, ActiveAdmin) have all solved this internally and none of it is extractable. **This is the single biggest hole in the ecosystem.**

**2. Select / combobox / multi-select.** `hotwire_combobox` is excellent and genuinely best-in-class, but it is (a) a Rails gem, not a controller, so it's unusable outside ERB; (b) single-maintainer; (c) still pre-1.0 (0.4.1). Meanwhile the JS libraries people fall back to have **no maintained Stimulus wrappers at all**: Tom Select's only wrapper is a 21-star repo last touched 2023-02; Slim Select and Choices.js have none. Multi-select with tokens/chips, async remote options, option groups, and "create new" is a daily Rails need with no clean answer.

**3. Date & time pickers.** The worst-maintained corner of the whole survey. `flatpickr` — the de facto standard — last published to npm **2022-04-14**; its best Stimulus wrapper (`adrienpoly/stimulus-flatpickr`, 422 stars) was last touched **2023-10**. `Litepicker` is **archived**. `stimulus-datepicker` (airblade, 98 stars) hasn't moved since 2024-04. There is no maintained date-range picker, no date+time picker, and no Rails-aware one that understands `Time.zone`. Native `<input type="date">` is the honest 2026 answer for simple cases, and nobody has packaged the "native where possible, enhanced where necessary" pattern.

**4. Tooltips & positioned overlays.** Tippy.js is **archived** (2024-05); Popper v2 is **frozen** (last release 2023-05). Floating UI is the maintained successor with 32.7k stars and 372M downloads/month — and there is **no Stimulus wrapper for it whatsoever**. Every popover/dropdown/tooltip/menu in the ecosystem is either hand-positioned with `absolute` + Tailwind (breaks near viewport edges) or depends on a dead library. A single well-built `floating` controller providing anchored positioning, flip/shift middleware, arrows, and hover/focus/click triggers would be the most immediately useful thing crosswire could ship.

**5. File upload.** ActiveStorage's direct upload emits `direct-upload:initialize/start/progress/error/end` events and ships **no UI**. Every Rails app hand-rolls the same progress bar. There is no maintained drag-and-drop dropzone controller, no image-preview-before-upload controller, no multi-file queue with per-file progress and cancel, and no maintained Cropper.js wrapper (Cropper is healthy at 13.8k stars / 6.6M downloads and has zero Stimulus packages). Uppy is excellent but heavyweight and Rails devs mostly don't use it.

### Tier 2 — increasingly expected, nothing reusable

**6. Command palette (⌘K).** Now a baseline expectation in SaaS UIs. Nothing exists for Hotwire. The pieces are all there (`@github/combobox-nav` for keyboard nav, `fuse.js` for fuzzy matching, Turbo Frames for async results) and nobody has assembled them.

**7. Toast / notification *stacks*.** `@stimulus-components/notification` dismisses a *single* element. The real problem — a stack that appends, positions, de-duplicates, respects `prefers-reduced-motion`, survives Turbo navigation, and is drivable from a Turbo Stream `append` — is unsolved.

**8. Form-field primitives.** No reusable answer for: inline validation display driven by Rails validation errors, character/word limits with live feedback (the counter exists; the *field* doesn't), dependent/cascading selects, dirty-form "unsaved changes" guards that understand `turbo:before-visit`, or autosave with conflict handling. `tailwindcss-stimulus-components`' `autosave` is the only prior art and it's 52 lines.

**9. Accessible tabs, accordion, disclosure, menu.** `tailwindcss-stimulus-components` has `tabs`; nobody has a properly-implemented accordion or an ARIA menu with roving tabindex. Note that stimulus-components only added `aria-expanded`/`aria-controls` to its dropdown **in August 2026** — a11y is an afterthought across the board, and doing it properly is a real differentiator.

**10. Charts.** `@stimulus-components/chartjs` is a 60-line pass-through. Nothing handles the actual hard parts: re-rendering on Turbo Frame replacement, destroying the chart instance on `disconnect()` (a classic Turbo-cache leak), theme/dark-mode awareness, or responsive resize.

### Tier 3 — Hotwire-specific patterns with no canonical recipe

**11. Optimistic UI.** Turbo 8 morphing made this *possible* and nobody has written down the pattern. Apply the change locally, submit, reconcile or roll back on failure.

**12. Turbo-aware Stimulus lifecycle.** The single most common category of Hotwire bug — controllers that leak across `turbo:before-cache`, third-party instances that survive a page restore, `setInterval` that keeps firing on a cached page — has no library-level answer and barely any documentation. Even stimulus-components is actively fixing this class of bug in itself right now.

**13. Infinite scroll / "load more".** Every implementation is a blog post. `pagy` gives you the URLs; the intersection-observer + Turbo Frame + "no more results" + back-button-restores-scroll-position wiring is re-derived from scratch every time.

**14. Drag & drop beyond lists.** `sortable` handles a single list. Kanban (multi-list with cross-list moves), drag-to-a-drop-target, and reorderable trees are all unaddressed.

**15. Presence / typing indicators / live cursors.** Turbo Streams + ActionCable can do it; nobody has packaged it.

### Tier 4 — structural gaps

**16. No styled component layer that isn't commercial.** The free options give you behaviour with no CSS (stimulus-components) or CSS with no behaviour (Tailwind/DaisyUI). The projects that give you *both* are paid (Rails UI $299/yr, Rails Designer $149–299 one-time) or Phlex-only (RubyUI, PhlexyUI). **There is no free, ERB-first, styled + behavioural component library for Hotwire.**

**17. Nothing bridges ERB and the controller.** Every reusable Stimulus controller in this survey documents its API as raw HTML with hand-written `data-` attributes. Nobody ships the Rails-side helper (`<%= combobox_tag ... %>`-style) that generates the right markup. `hotwire_combobox` is the lone exception and it's precisely why it's the nicest thing to use in the whole ecosystem. **A component library that ships a controller *and* an ERB helper for each component would be meaningfully novel.**

**18. Documentation of interaction, not just installation.** Nobody documents how components behave under Turbo Frame navigation, morphing page refreshes, or the back-button cache. That is where the bugs are.

### JS libraries with NO maintained Stimulus wrapper (opportunity list)

| Library | Health | Wrapper status |
|---|---|---|
| **Floating UI** (`@floating-ui/dom`) | ★32.7k, 372M/mo, active | **None** |
| **Tom Select** | ★2.2k, 1.3M/mo, active | 21★, dead since 2023-02 |
| **Slim Select** | ★1.3k, 316k/mo, active | **None** |
| **Choices.js** | ★6.8k, 2.3M/mo, active | **None** |
| **Cropper.js v2** | ★13.9k, 6.6M/mo, active | **None** |
| **Uppy** | ★30.9k, 4.5M/mo, active | **None** |
| **Fuse.js** | ★20.4k, 49.7M/mo, active | **None** |
| **hotkeys-js** | ★7.1k, 5.6M/mo, active | only via `stimulus-use/hotkeys` |
| **Idiomorph** | ★1.1k, active (powers Turbo 8) | **None** (Turbo-internal only) |
| **motion** | ★33.3k, 69M/mo, active | **None** |
| Flatpickr | ★16.5k but **npm-stale since 2022** | 422★, stale since 2023 |
| Tippy.js | **archived 2024** | n/a — migrate to Floating UI |
| Litepicker | **archived 2023** | n/a |
| el-transition | last release **2020** | n/a — use the tailwindcss-stimulus-components transition module |

## 10. Caveats & things we could not verify

Stated explicitly so nothing here is mistaken for a verified fact.

**Could not reach / verify:**

- **Rails Blocks Pro pricing** — the pricing page 404s to both WebFetch and impersonated curl (likely client-side rendered). Free tier and component list confirmed; the Pro price is not.
- **Rails Designer delivery format** — the one-time price tiers ($149 / $299) are confirmed from the public pricing page, but whether the paid library ships as copy-paste snippets, a gem, or a generator could only be determined by purchasing.
- **Zestui licence** — the `zestui` gem declares an empty `licenses: []` array on RubyGems and the gem metadata has no `source_code_uri`. This is an unset field upstream, not a research gap. Ask the maintainer before copying any of its code.
- **`ddnexus.github.io/pagy/docs/extras/`** returns 404. Pagy's Hotwire story described in §6.3 is inferred from the documented `_js` nav variants and the general frame-wrapping pattern, not from a page enumerating a named "Turbo extra."
- **hotwirecombobox.com's deeper documentation pages** did not fully resolve. The `combobox_tag` option surface in §6.1 comes from the GitHub README, which is thorough; treat it as a solid floor rather than a guaranteed-exhaustive list. The raw `data-*` attribute names for hand-wiring outside the helpers were not extracted — read `app/javascript` in the gem if you need them.
- **hotwire.io entries** darksea/ui (Cloudflare 525), Morphkit (empty stub), Radiolabel (no description), Toasta (repo 404s), Turbo LSP (stub, no link), and rails-aria-components (announcement only, no repo) could not be verified. Several other hotwire.io UI-framework entries (Nitro Kit, Essence, Instrumental, michelson/rails-ui, RailsbootUI) were not independently confirmed for current stars/maintenance and should be treated as unverified leads.
- **Avo's paid Pro/Advanced tiers** — only the open-source core's `package.json` was inspected.

**Judgement calls, not facts:**

- The **StimulusReflex "superseded" verdict** is inferred from commit and release patterns (Dependabot-only commits for months, no v4) — there is no public maintainer statement declaring the project's direction. Worth checking their Discord/Discussions before treating it as settled.
- **Uppy vs ActiveStorage usage share** — no survey data exists. §6.2's read is qualitative.
- **Phlex's performance claims** (~1.4 Gbps/core) are vendor claims. No independent 2026 head-to-head benchmark against ViewComponent was found. Do not choose on this.

**Corrections to common assumptions, verified here:**

- `turbo_ready` is by **hopsoft (Nate Hopkins)**, not julianrubisch; its repo now redirects to `hopsoft/turbo_boost-streams`.
- `mrujs` moved from `ParamagicDev/mrujs` to **`KonnorRogers/mrujs`**.
- `hotwire-spark`'s repo is **`hotwired/spark`**; `basecamp/hotwire-spark` redirects there.
- Phlex moved from the `phlex-ruby` org to **`yippee-fun`** (Joel Drapper's company). There was **no licensing controversy** — Phlex has been MIT throughout; the 2.0 event was an API rewrite (`template` → `view_template`). There *was* a real security event: **GHSA-w67g-2h6v-vjgq**, a high-severity XSS protection bypass fixed in 2.4.1 (2026-02-06).
- `stimulus_reflex` v3.5.5 was **published to RubyGems on 2025-05-25**; a GitHub release tag for the same version was created 2026-07-28 but no new gem shipped. Use the RubyGems date.
- **`turbo_stream_actions` is not a package.** Registering custom stream actions (`Turbo.StreamActions.foo = function() {...}`) has been a native Turbo capability since 7.2. `turbo_power` is the pre-built pack.
- `@stimulus-components/hotkey` is **not** a `hotkeys-js` wrapper — it's a standalone controller using native Stimulus keyboard actions (`keydown.enter@document->hotkey#click`) that skips triggering while focus is inside `input`/`textarea`/`lexxy-editor`.

**Freshness:** every figure reflects live state on **2026-08-15**. The fast-movers (stimulus-components, stimulus-lsp, turbo_power, lexxy, avo, pagy) will have moved by the time you read this. The dead ones will not have.
