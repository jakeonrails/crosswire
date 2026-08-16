# Marco Roth — Complete Hotwire Ecosystem Accounting

> Research note for **crosswire**. Compiled 2026-08-15.
> Author-centric survey of everything Marco Roth has built, written, and spoken
> above and beyond core Hotwire — verified against GitHub (authed `gh`), npm,
> RubyGems, VS Code Marketplace, speakerdeck PDFs, and YouTube transcripts.

**Who he is:** Marco Roth (`@marcoroth`, marcoroth.dev, Basel, Switzerland).
1,105 GitHub followers, 295 public repos. Member of the **`hotwired`** GitHub org
(plus `stimulusreflex`, `cableready`, `stimulus-use`, `rubyevents`).
Stimulus core contributor — **he authored the Stimulus Outlets API**. Former
StimulusReflex/CableReady core team. Creator of Herb, ReActionView, TurboPower,
stimulus-lsp, and hotwire.io. Rails Luminary 2025.

---

## Table of contents

- [Summary table](#summary-table)
- [Two myths corrected up front](#two-myths-corrected-up-front)
- [Per-project sections](#per-project-sections)
  - [Herb](#herb--the-html-aware-erb-toolchain)
  - [ReActionView](#reactionview)
  - [stimulus-lsp](#stimulus-lsp)
  - [stimulus-parser](#stimulus-parser)
  - [turbo-lsp](#turbo-lsp)
  - [TurboPower / turbo_power-rails](#turbopower--turbo_power-rails)
  - [turbo-morph](#turbo-morph)
  - [hotwire.io](#hotwireio)
  - [Hotwire Weekly](#hotwire-weekly)
  - [current.js](#currentjs)
  - [formulus](#formulus)
  - [Minor / historical](#minor--historical-hotwire-projects)
  - [CableReady & StimulusReflex](#cableready--stimulusreflex-the-dormant-history)
- [Upstream Hotwire contributions](#upstream-hotwire-contributions)
- [Writing & talks](#writing--talks)
- [Tooling we should adopt immediately](#tooling-we-should-adopt-immediately)
- [Anything he's said about the morph/Stimulus-values conflict](#anything-hes-said-about-the-morphstimulus-values-conflict)
- [Open questions](#open-questions)

---

## Summary table

| Project | What it is | ★ | Last push | Maturity | Relevance to crosswire |
|---|---|---:|---|---|---|
| **[herb](https://github.com/marcoroth/herb)** | HTML-aware ERB parser (C) + linter, formatter, LSP, engine, dev server | 1284 | 2026-08-15 | **Production**, v0.10.3, 720k npm dl/mo, 1.45M gem dl | **Highest.** Lint/format our ERB; 148 rules incl. 5 Turbo-aware |
| **[turbo_power](https://github.com/marcoroth/turbo_power)** | ~45 extra Turbo Stream actions (JS) | 519 | 2026-08-11 | Mature, **maintenance mode** (v0.8.0 = deps only), 444k dl/mo | High — action inventory is a recipe source |
| **[reactionview](https://github.com/marcoroth/reactionview)** | ActionView-compatible ERB engine on `Herb::Engine` | 484 | 2026-08-08 | **Early** v0.3.0, 199k gem dl | Medium — watch, don't adopt |
| **[turbo_power-rails](https://github.com/marcoroth/turbo_power-rails)** | Rails helpers for the above (`turbo_stream.*`) | 351 | 2026-07-22 | Mature, 2.66M gem dl total | High — the Ruby-side API we'd document |
| **[stimulus-lsp](https://github.com/marcoroth/stimulus-lsp)** | Language server: completion + diagnostics for `data-controller`/action/target/value | 303 | 2026-08-10 | **Production**, 11.2k VS Code installs, 5.0★ | **Highest DX leverage.** Ship a config |
| **[current.js](https://github.com/marcoroth/current.js)** | 410-byte lib reading `<meta name="current-*">` | 223 | 2025-11-10 | Stable, 3.9k dl/mo | Medium — clean recipe for server→client state |
| **[hotwire.io](https://github.com/marcoroth/hotwire.io)** | Community Hotwire docs + ecosystem hub (Rails app, git-backed MD) | 175 | 2026-01-20 | Live, **stale ~7mo** | Medium — a contribution target |
| **[formulus](https://github.com/marcoroth/formulus)** | Client-side validation on the HTML Form Validation API | 114 | 2026-04-20 | Early v0.1.0 | Medium — forms recipe |
| **[turbo-morph](https://github.com/marcoroth/turbo-morph)** | morphdom `morph` Stream action (pre-Turbo-8) | 103 | 2023-02-25 | **Obsolete** — superseded by Turbo 8 | Low — historical only |
| **[turbo-lsp](https://github.com/marcoroth/turbo-lsp)** | LSP for `<turbo-frame>`/`<turbo-stream>` elements + attrs | 53 | 2026-08-11 | **Preliminary**, not on npm | Low-medium — watch |
| **[stimulus-parser](https://github.com/marcoroth/stimulus-parser)** | Static analyser producing controller definitions | 45 | 2026-08-13 | Solid v0.3.2, 2.4k dl/mo | **High** — engine for custom checks |
| **[cable-streams](https://github.com/marcoroth/cable-streams)** | CableReady operations as Turbo Stream actions | 26 | 2022-12-18 | Dead | None |
| **[stimulus-render](https://github.com/marcoroth/stimulus-render)** | PoC: HTML rendering inside Stimulus controllers | 21 | 2022-09-04 | Dead PoC | None |

**Not his** (sibling-agent errors): `morphkit/morphkit`, `debounced`. See below.

---

## Two myths corrected up front

### 1. "Morphkit" — there is no Marco Roth Morphkit

The brief flagged a `Morphkit` repo as suspiciously empty and hypothesised it was
an unstarted answer to Turbo 8 morphing problems. **It isn't his, and it isn't
about morphing.**

- `morphkit` is a **GitHub org** created 2025-12-28, containing exactly one repo,
  `morphkit/morphkit` — *"LLM Optimized UI component library."*
- Every commit is authored by **Jaksa Malisic**. It's a React Native / Expo
  component library (Stack, Drawer, Tabs, Slider, theme utils) with a CLI and an
  npm registry. Marco Roth appears nowhere in it.
- A GitHub-wide search for `morphkit` returns 11 repos — ball-python genetics,
  a SwiftUI converter, an http proxy, a WebGL point cloud. None are his.
- `gh search repos --owner marcoroth morph` returns exactly **one** repo:
  `marcoroth/turbo-morph` (103★, last pushed 2023-02-25).

**Verdict: dead end.** The morphing-adjacent repo of his that actually exists is
`turbo-morph`, and it *predates* Turbo 8 rather than answering it. Do not spend
more time here.

### 2. "Debounced" is not his

`debounced` on npm (30,879 dl/mo, v2.0.1, 2025-09-23) is authored and maintained
by **Nate Hopkins (`hopsoft`)** — `github.com/hopsoft/debounced`. The confusion is
understandable: Hopkins and Roth were both on the StimulusReflex/CableReady core
team, and it's a common Hotwire-adjacent dependency. But it is not a Marco Roth
project and shouldn't be attributed to him in the repo.

---

## Per-project sections

### Herb — the HTML-aware ERB toolchain

**The strategically most significant thing he has built.** Site:
[herb-tools.dev](https://herb-tools.dev) · playground:
[herb-tools.dev/playground](https://herb-tools.dev/playground)

**Architecture.** At the core is a hand-written **HTML-aware ERB parser in C**
that treats HTML *and* ERB as first-class citizens in one syntax tree — rather
than the usual approach of regex-stripping ERB and handing the residue to an HTML
parser (`erb_lint`, `better-html`) or vice versa. It compiles against Prism's C
source (Prism parses the Ruby inside the ERB tags). Bindings ship for **Ruby,
Node.js, Rust, Java, and the browser via WebAssembly** — hence the playground.

Everything else is a consumer of that tree:

| Tool | Package | Status |
|---|---|---|
| Parser | `herb` gem / `@herb-tools/core` | Production |
| Linter | `@herb-tools/linter` | Production — **148 rules** |
| Formatter | `@herb-tools/formatter` | Experimental |
| Language Service | `@herb-tools/language-service` | Production, ActionView tag-helper aware |
| Language Server | `@herb-tools/language-server` | Production — VS Code, Zed, Neovim |
| `Herb::Engine` | in `herb` gem | Erubi-API-compatible renderer |
| Dev Server | `@herb-tools/dev-server` | Experimental — live DOM patching |
| Dev Tools | shipped with ReActionView | In-browser template inspector |

**Adoption (real, not vanity):**

| Package | Downloads | Latest |
|---|---|---|
| `@herb-tools/core` | **720,107/mo** | 0.10.3 (2026-08-01) |
| `@herb-tools/linter` | **694,561/mo** | 0.10.3 |
| `@herb-tools/formatter` | 549,629/mo | 0.10.3 |
| `@herb-tools/language-server` | 48,442/mo | 0.10.3 |
| `herb` gem | **1,448,172 total** | 0.10.3 |
| Herb LSP (VS Code) | **17,646 installs**, 5.0★ | published 2025-06-19 |

The VS Code extension is *newer* than stimulus-lsp (2025-06 vs 2023-10) and has
already overtaken it on installs (17.6k vs 11.2k), with ~5.5x the monthly
trending score. Herb is where his energy and the community's adoption both are.

**What the linter actually catches** (148 rules, sampled from
`javascript/packages/linter/src/rules/`):

- `html-*` (45 rules) — structural and a11y: `html-no-duplicate-ids`,
  `html-no-nested-forms`, `html-no-nested-links`, `html-img-require-alt`,
  `html-no-self-closing`, `html-require-closing-tags`,
  `html-no-event-handler-attributes`, `html-attribute-double-quotes`.
- `a11y-*` (10 rules) — `a11y-nested-interactive-elements`,
  `a11y-no-aria-label-misuse`, `a11y-avoid-generic-link-text`.
- `erb-*` (~45 rules) — `erb-no-unsafe-raw`, `erb-no-output-in-attribute-name`,
  `erb-no-raw-output-in-attribute-value`, `erb-no-unsafe-js-attribute`,
  `erb-no-instance-variables-in-partials`, `erb-strict-locals-required`,
  `erb-no-unused-local-variable`.
- `actionview-*` (21 rules) — `actionview-no-dynamic-partial-path`,
  `actionview-prefer-collection-render`, `actionview-no-unused-strict-locals`,
  `actionview-no-unnecessary-html-safe`.
- **Hotwire-aware (5 rules)** — this is the part that matters to us:
  - `turbo-permanent-require-id` — `data-turbo-permanent` without an `id` is a
    silent no-op. This is a *real* morph/cache footgun and Herb catches it.
  - `turbo-permanent-no-misleading-value`
  - `ujs-prefer-turbo-confirm`, `ujs-prefer-turbo-method`,
    `ujs-prefer-turbo-submits-with` — migrate off Rails-UJS attributes.

**Critical gap:** there are **zero Stimulus rules** in Herb. Nothing validates
`data-controller` / `data-action` / `data-*-target` against the controllers that
actually exist. That job currently belongs to stimulus-lsp — which is an *editor*
tool, not a *CI* tool. See "Tooling we should adopt".

**Install:**

```sh
gem install herb          # or: bundle add herb
herb analyze .            # parse-coverage report over all .html.erb
npx @herb-tools/linter    # lint
npx @herb-tools/formatter # format (experimental)
```

**Verdict: adopt.** The parser is genuinely novel, the linter is production-grade
with near-700k monthly downloads, and 5 of its rules are Turbo-specific. The
formatter is still experimental — lint now, format later.

---

### ReActionView

**What it is:** a Rails-integrated ERB *rendering engine* built on `Herb::Engine`,
API-compatible with Erubi but HTML-structure-aware. 484★, v0.3.0, 199k gem
downloads. Site: [reactionview.dev](https://reactionview.dev).

Two modes: native `.html.herb` templates, or intercept all `.html.erb`.

```sh
bundle add reactionview
rails generate reactionview:install
```

```ruby
# config/initializers/reactionview.rb
ReActionView.configure do |config|
  # config.intercept_erb = true            # process ALL .html.erb with Herb
  config.debug_mode = Rails.env.development?
  # config.validation_mode = :overlay      # :raise | :overlay | :none
  # config.external_template_mode = :skip  # gem templates: :fallback | :skip | :compile
end
```

What it buys today: HTML validation at render time, far better error messages
with precise source locations, "open in editor" links, and an in-browser debug
overlay.

**Verdict: watch, don't adopt.** v0.3.0 and only ~11 months old. Intercepting
every ERB template in an app is a large blast radius for a pre-1.0 gem. But see
the morphing section — its 2026 roadmap is the most interesting thing in this
whole document.

---

### stimulus-lsp

**Probably the highest-leverage pure-DX tool in the Hotwire ecosystem, and the
brief was right to single it out.** 303★, 11,211 VS Code installs, 5.0★ from 7
ratings, last updated 2026-08-01.

It solves a specific, recurring, *silent* class of bug: Stimulus fails soft. A
typo in `data-controller="user_profile"` (should be `user-profile`) produces no
error — the controller simply never connects, and you debug it by eye. Roth uses
exactly this example in his RailsConf 2024 deck under the heading *"These
mistakes happen so easily / Can we do better?"*

**Completions:** controller identifiers, actions, targets, values, classes, and
the data attributes themselves.

**Diagnostics — HTML files:**

| Code | Catches |
|---|---|
| `stimulus.controller.invalid` | `data-controller` naming a controller that doesn't exist |
| `stimulus.action.invalid` | missing action method / malformed action descriptor |
| `stimulus.controller.target.missing` | `data-x-target` for an undeclared target |
| `stimulus.controller.value.missing` | `data-x-value` for an undeclared value |
| `stimulus.attribute.mismatch` | data-attribute format errors |
| `stimulus.controller.value.type_mismatch` | value type doesn't match declaration |

**Diagnostics — JS/controller files:**
`stimulus.controller.value_definition.default_value.type_mismatch`,
`stimulus.controller.value_definition.unknown_type`,
`stimulus.controller.parse_error`, `stimulus.package.deprecated.import`.

**Quick-fixes:** create a controller with the given identifier; "did you mean"
identifier and action-name corrections; register a controller from your project
or an npm package; implement a missing action method on the controller; create
`.stimulus-lsp/config.json`; add an attribute or identifier to the ignore lists.

**Editor support:**
- VS Code — [marketplace: `marcoroth.stimulus-lsp`](https://marketplace.visualstudio.com/items?itemName=marcoroth.stimulus-lsp)
- Neovim — `stimulus_ls` in `nvim-lspconfig`
- Zed — [`vitallium/zed-stimulus`](https://github.com/vitallium/zed-stimulus)

Config lives at `.stimulus-lsp/config.json`, supporting `ignoredAttributes` and
`ignoredControllerIdentifiers` — important for projects using Alpine or other
`data-*` conventions that would otherwise trip diagnostics.

**Honest assessment.** The value is real and high — it converts a whole category
of silent runtime failures into red squiggles, and the "register controller from
npm package" fix genuinely helps when consuming `stimulus-components`. Two honest
caveats:

1. **It is editor-only.** There is no CLI, so it cannot gate CI. The `stimulus-lsp`
   npm package (14 dl/mo) is the server plumbing, not a runnable linter. If we
   want CI enforcement we must drive `stimulus-parser` ourselves.
2. **HTML-only parsing.** The README states it "currently only works for HTML,
   though its utility extends to ERB, PHP, or Blade." In practice ERB
   interpolation inside attributes (`data-controller="<%= ... %>"`) is where its
   understanding stops. This is precisely the gap Herb's parser could close, and
   the two projects are not yet integrated.

**Verdict: adopt, and document the config.**

---

### stimulus-parser

The static-analysis engine underneath stimulus-lsp, usable standalone. 45★,
v0.3.2, 2,452 npm dl/mo. Playground: **stimulus-parser.hotwire.io**.

```bash
yarn add stimulus-parser
```

```js
import { Project } from "stimulus-parser"

const project = new Project("/Users/user/path/to/project")
await project.initialize()

const controllers = project.controllerDefinitions
const controller = controllers[0]

console.log(controller.actionNames)  // => ["connect", "click", "disconnect"]
console.log(controller.targetNames)  // => ["name", "output"]
console.log(controller.classNames)   // => ["loading"]
console.log(controller.values)       // => [{ url: { type: "String", default: "" } }]
```

Per his RailsConf 2024 deck it "parses JavaScript classes and traces imports and
exports" and "registers and tracks identifiers" — including resolving
`application.register("clipboard", ClipboardController)` calls in
`controllers/index.js`, so it understands eager-loaded and manually-registered
controllers, not just filename conventions.

**Verdict: this is our programmable hook.** It's the supported way to build a CI
check that every `data-controller` in our ERB names a controller that exists.

---

### turbo-lsp

53★, last push 2026-08-11, but explicitly flagged in its own README:

> **IMPORTANT** — This Language Server Protocol (LSP) implementation is currently
> in a preliminary stage of development and does not yet include support for
> Ruby-related functionalities.

Provides completions for Turbo custom elements (`<turbo-frame>`, `<turbo-stream>`)
and their attributes. **Not published to npm** — no installable release.

**Verdict: not adoptable yet.** Watch it.

---

### TurboPower / turbo_power-rails

The extra-Turbo-Stream-actions power-pack, explicitly modelled on CableReady's
operations. Requires Turbo 7.2+.

- npm `turbo_power`: **444,132 dl/mo**, v0.8.0 (2026-07-13)
- gem `turbo_power`: **2,656,191 total downloads**, v0.8.0

```bash
yarn add turbo_power
```

```js
// application.js
import * as Turbo from '@hotwired/turbo'
import TurboPower from 'turbo_power'
TurboPower.initialize(Turbo.StreamActions)
```

TypeScript users also need `yarn add --dev @types/hotwired__turbo` (Turbo 8 moved
its types to the community-maintained DefinitelyTyped package).

**Full action inventory** (Rails-helper form):

*DOM* — `graft`, `morph`, `inner_html`, `insert_adjacent_html`,
`insert_adjacent_text`, `outer_html`, `text_content`, `set_meta`

*Attributes* — `add_css_class`, `remove_attribute`, `remove_css_class`,
`set_attribute`, `set_dataset_attribute`, `set_property`, `set_style`,
`set_styles`, `set_value`, `toggle_attribute`, `toggle_css_class`,
`replace_css_class`

*Events* — `dispatch_event`

*Forms* — `reset_form`

*Storage* — `clear_storage`, `clear_local_storage`, `clear_session_storage`,
`remove_storage_item`, `remove_local_storage_item`, `remove_session_storage_item`,
`set_storage_item`, `set_local_storage_item`, `set_session_storage_item`

*Browser* — `reload`, `scroll_into_view`, `set_focus`, `set_title`

*Document* — `set_cookie`, `set_cookie_item`

*History* — `history_back`, `history_forward`, `history_go`, `push_state`,
`replace_state`

*Debug* — `console_log`, `console_table`

*Notification* — `notification`

*Turbo* — `redirect_to`, `turbo_clear_cache`

*Progress bar* — `turbo_progress_bar_show`, `turbo_progress_bar_hide`,
`turbo_progress_bar_set_value`

*Turbo Frames* — `turbo_frame_reload`, `turbo_frame_set_src`

*Deprecated* — `invoke` was **removed**; it now logs a warning pointing at
`hopsoft/turbo_boost-streams`.

**Post-Turbo-8 relevance — honest read.** Two things changed:

1. **`morph` was absorbed upstream.** In turbo#1240 (opened by seanpdoyle,
   merged 2024-07-12) Turbo restructured morph support so it is expressed as
   `<turbo-stream action="replace" method="morph">` rather than a distinct
   `morph` action. Roth participated and floated keeping `morph` as a deprecation
   shim, then withdrew the suggestion. So TurboPower's `morph` is now redundant
   with core.
2. **The project is in maintenance mode.** v0.8.0 (2026-07-13) is the first
   release in 19 months, and its changelog is a Turbo-8 types upgrade, one bug
   fix (`history_forward` registration), and ~40 dependabot bumps. Both
   substantive PRs were by an outside contributor (`myabc`), not Roth.

But the remaining ~44 actions have **no core equivalent**. Turbo still ships only
the 7 default actions, and there is no built-in way to say "set this attribute",
"dispatch this event", "focus this element", or "write to localStorage" from a
Stream response. At 444k npm downloads/month it is not going anywhere.

**Verdict: still worth documenting, with a caveat.** Use it for the attribute /
event / focus / storage actions. Do **not** use its `morph` — use core Turbo 8's
`replace` + `method="morph"`.

---

### turbo-morph

103★, last push **2023-02-25**. A morphdom integration adding a `morph` Turbo
Stream action, written a year before Turbo 8 shipped morphing.

```html
<turbo-stream action="morph" targets="body">
  <template>
    <body data-updated="true"><h1>This is the new body</h1></body>
  </template>
</turbo-stream>
```

Supports morphdom's `childrenOnly` via a `[children-only]` attribute on the
`<turbo-stream>` element.

**Verdict: obsolete.** Turbo 8 uses **Idiomorph**, not morphdom, and handles this
natively. Historical interest only — but it is the strongest evidence that Roth
was thinking hard about morphing *granularity* two years before the ecosystem was.
683 npm dl/mo is residual.

---

### hotwire.io

175★, community documentation and ecosystem hub. Last push **2026-01-20** — about
seven months stale.

**How it's built:** a Rails app (Tailwind, esbuild) whose content is **Markdown
files in the same git repo**. The app clones its own repository at runtime
(`app/models/git_repo.rb` shells out to `git clone` using a PAT, checks out the
`new` branch) and renders the markdown via `app/models/markdown_renderer.rb`.
`db/seeds.rb` is the untouched Rails default, so there is **no database-driven
content and no automated scraping** — the ecosystem list is **entirely
hand-curated in git**.

That makes contributing straightforward and the README documents the flow
explicitly: fork → `bin/setup` → branch → PR. It also hosts
`stimulus-parser.hotwire.io`.

From the RailsConf 2024 deck, the site's stated purpose is "helping you navigate
and discover the ecosystem", with cross-framework coverage (turbo-laravel,
Symfony UX, rails-inspire-django, Micronaut, Bridgetown) and this open invitation:

> If you write a post, we want to feature it next to the relevant documentation
> section so it can also be discovered by the community. We would love to see
> your contribution.

**Verdict: yes, we could contribute, and we'd likely be welcomed.** But note the
seven-month gap — PRs may sit. Treat it as a distribution channel for crosswire
recipes, not a dependency.

---

### Hotwire Weekly

**Status: alive, archives fully recoverable — the sibling's 410 finding was a
domain artifact, not a dead newsletter.**

- `hotwireweekly.com` → connection failure; `www.hotwireweekly.com` → **410 Gone**.
  The custom domain has been retired.
- **`https://buttondown.com/hotwireweekly` → 200**, and the full archive is
  browsable at **`https://buttondown.com/hotwireweekly/archive/`**. No
  web.archive.org excavation needed.
- Also linked from `hotwire.io/newsletter`.
- Socials: [@Hotwire_Weekly](https://x.com/Hotwire_Weekly),
  [@hotwireweekly.com on Bluesky](https://bsky.app/profile/hotwireweekly.com),
  [@Hotwire_Weekly@ruby.social](https://ruby.social/@Hotwire_Weekly), LinkedIn.

Running since **October 2023**; per his RailsConf 2024 deck it had **1,200+
subscribers** by May 2024.

**Caveat:** the most recent issue is **"Week 12/13 — Hotwire Native Calendar
Bridge, TutorialKit.rb, and more!", 30 March 2026**. As of 2026-08-15 that is
**4.5 months of silence**, and the cadence had already slipped to fortnightly and
tri-weekly bundles ("Week 09/10/11") before stopping. It looks paused rather than
formally ended — consistent with his attention having shifted wholesale to Herb.

Recent issues are a good barometer of live community topics: importmap-rails,
Herb v0.9, dynamic partial rendering, "Turbo + ActionCable Trap", optimistic UIs,
Hotwire Native bridge components.

---

### current.js

223★, 410 bytes, 3,927 npm dl/mo. Reads `<meta name="current-*">` tags into a
global `Current` object.

```html
<head>
  <meta name="current-environment" content="production">
  <meta name="current-user-id" content="123">
  <meta name="current-user-time-zone-name" content="Central Time (US & Canada)">
</head>
```

```js
import "current.js"          // global Current
// or: import { Current } from "current.js"

Current.environment
// => "production"

Current.user
// => { id: "123", timeZoneName: "Central Time (US & Canada)" }
```

Single meta → string; multiple sharing a prefix → object with camelised keys.

**Verdict: a genuinely clean pattern worth a crosswire recipe.** It's the
idiomatic Hotwire answer to "how do I get `Current.user` to the client without a
JSON blob or a global `window.APP` object". And — relevant to the morphing
question — `<meta>` tags in `<head>` are outside the morphed `<body>`, so this is
a *morph-safe* place to keep client-visible state.

---

### formulus

114★, v0.1.0 (2025-05-19), 1,003 dl/mo. Client-side form validation built on the
browser's native HTML Form Validation API rather than a bespoke validation
engine. Early but conceptually aligned with "The Rails Way without React".

**Verdict: worth a look for a forms chapter; too early to depend on.**

---

### Minor / historical Hotwire projects

| Repo | ★ | Last push | Note |
|---|---:|---|---|
| `cable-streams` / `-rails` | 26 / 6 | 2022-12-18 | CableReady operations as Turbo Stream actions. Dead — TurboPower is the successor. |
| `stimulus-render` | 21 | 2022-09-04 | PoC for rendering HTML from within Stimulus controllers. Abandoned, but interesting prior art for client-side rendering. |
| `turbo-ruby` | 45 | 2023-01-10 | Turbo helpers without Rails. 2,236 gem dl. |
| `phlexing` | 103 | 2026-01-20 | ERB → Phlex converter, 15.7k gem dl. Adjacent to the view-layer thesis. |
| `boxdrop` | 85 | 2026-07-24 | Dropbox clone demo built with StimulusReflex. |
| `stimulus-blurhash` | 2 | 2021-03-17 | A single Stimulus controller. |
| `rubocop-stimulus_reflex`, `rubocop-cable_ready` | 9 / 4 | 2025/2023 | Style cops for the dormant stack. |

Note his output is much broader than Hotwire — a large Charm/TUI-for-Ruby suite
(`bubbletea-ruby` 145★, `lipgloss-ruby`, `glamour-ruby`, `gum-ruby`, `huh-ruby`),
`minitest-difftastic` (132★), `gem.sh` (136★), `insta-ruby` (57★), and
RubyEvents.org. Out of scope here but useful context for how much of his
attention Hotwire actually gets: **in 2026, almost none of it goes to Turbo or
Stimulus directly — it goes to Herb.**

---

### CableReady & StimulusReflex (the dormant history)

Roth was core team on both. This history explains the 2021–2023 blog/talk corpus
and, more usefully, explains *why* several Hotwire features exist.

Current state: `cable_ready` 2,589,561 total gem downloads (v5.0.6);
`stimulus_reflex` 1,490,989 (v3.5.5). Both effectively frozen.

His RailsConf 2024 deck announced the wind-down in his own words:

> The StimulusReflex Core team has decided that v3.5 is the last feature-release
> for now. Instead, we want to focus and help on improving the greater Hotwire
> ecosystem. Going forward we would love to help make Hotwire the best set of
> frameworks in this space.

And, asked whether to start new apps with StimulusReflex: **"Probably not."**

The deck's most valuable artifact is a feature-lag table showing StimulusReflex /
CableReady shipping ideas years before Turbo:

| Feature | SR/CR shipped | Turbo shipped | Lag |
|---|---|---|---|
| DOM updates | CableReady Operations, Dec 2020 | Turbo Streams | 3 yr 7 mo |
| **Morphing as an individual concept** | CR Morph Action + SR Morphs, Aug 2019 | **— (none)** | **4 yr 9 mo+** |
| Scoped navigation | `data-reflex-root`, Dec 2020 | Turbo Frames | 1 yr 2 mo |
| Custom actions | Custom CR Operations, Sep 2022 | Custom Turbo Stream Actions | 2 yr 4 mo |
| Reactive page refreshes | SR Page Morph, Feb 2024 | Turbo Page Refreshes | 3 yr 9 mo |
| **Partial page refreshes** | SR Selector Morph, May 2020 | **— (none)** | **4 yr+** |
| Model subscriptions | `CableReady::Updatable`, Feb 2024 | Turbo Model Broadcasts | 2 yr 6 mo |

The two "—" rows are the load-bearing ones and are analysed in the morphing
section below.

---

## Upstream Hotwire contributions

Verified via `gh search prs --author marcoroth --owner hotwired`. He has **48+
PRs** across `hotwired/*`. The significant ones:

### Stimulus — he authored the Outlets API

| PR | Date | What |
|---|---|---|
| **[stimulus#576](https://github.com/hotwired/stimulus/pull/576)** | 2022-08-28 | **Outlets API** — merged, shipped in Stimulus 3.2.0 |
| [stimulus#604](https://github.com/hotwired/stimulus/pull/604) | 2022-11-18 | Outlets API documentation |
| [stimulus#648](https://github.com/hotwired/stimulus/pull/648) | 2023-01-28 | Ensure `Scope` is connected before accessing outlets |
| [stimulus#350](https://github.com/hotwired/stimulus/pull/350) | 2020-12-12 | Custom default values for the Values API |
| [stimulus#407](https://github.com/hotwired/stimulus/pull/407) | 2021-06-13 | **`oldValue` argument to `{name}ValueChanged` callback** |
| [stimulus#413](https://github.com/hotwired/stimulus/pull/413) | 2021-06-20 | **Warnings for undefined controllers, actions and targets** — the conceptual seed of stimulus-lsp |
| [stimulus#571](https://github.com/hotwired/stimulus/pull/571) | 2022-08-09 | Action Parameters attributes case-insensitive |
| [stimulus#650](https://github.com/hotwired/stimulus/pull/650) | 2023-02-02 | `ValueTypeObject` accepted as a `Partial` |
| [stimulus#643](https://github.com/hotwired/stimulus/pull/643) | 2023-01-24 | Explicitly type `Controller.dispatch()` options |
| [stimulus#686](https://github.com/hotwired/stimulus/pull/686) | 2023-06-15 | Exposes internals used by custom Blessings (see blog post) |

Still open: [stimulus#687](https://github.com/hotwired/stimulus/pull/687)
(`application.lazyLoadingControllers`), [stimulus#647](https://github.com/hotwired/stimulus/pull/647)
(optional Outlets selector).

**`oldValue` (#407) is directly relevant to us** — it's the API that makes
`fooValueChanged(value, oldValue)` usable as a change-detection hook, which is one
of the few workable ways to react to morph-driven attribute changes.

### Turbo

| PR | Date | What |
|---|---|---|
| [turbo#632](https://github.com/hotwired/turbo/pull/632) | 2022-07-16 | **Client-side Turbo Cache Control API** (`Turbo.cache`) |
| [turbo#634](https://github.com/hotwired/turbo/pull/634) | 2022-07-18 | Deprecate `Turbo.clearCache()` |
| [turbo#708](https://github.com/hotwired/turbo/pull/708) | 2022-09-06 | Export Custom Elements and Stream Action types |
| [turbo#656](https://github.com/hotwired/turbo/pull/656) | 2022-07-29 | `elementIsNavigatable()` rename |
| [turbo#875](https://github.com/hotwired/turbo/pull/875) | 2023-02-16 | Untangle circular dep in `StreamSourceElement` |
| [turbo-site#173](https://github.com/hotwired/turbo-site/pull/173) | 2024-02-22 | **Update `morphdom` example with `idiomorph` in the Handbook** |
| [turbo-rails#375](https://github.com/hotwired/turbo-rails/pull/375) | 2022-08-22 | Make `target`/`targets` optional for Stream actions |
| [turbo-rails#373](https://github.com/hotwired/turbo-rails/pull/373) | 2022-08-20 | Additional attributes on `turbo_stream_action_tag` |

Still open: [turbo#692](https://github.com/hotwired/turbo/pull/692) (track Frame
visits in URL hash), [turbo#874](https://github.com/hotwired/turbo/pull/874)
(`data-turbo-confirm` on `<a>` without `data-turbo-method`).

---

## Writing & talks

His blog has **13 posts total** ([marcoroth.dev/blog](https://marcoroth.dev/blog),
Bridgetown, Atom feed at `/feed.xml` — note the feed only carries the latest 10).
He is a far more prolific speaker than writer: **40+ talk appearances** since 2023.

### Blog posts (complete list)

| Date | Title | Topic |
|---|---|---|
| 2026-07-15 | [Introducing Insta: Snapshot Testing for Ruby](https://marcoroth.dev/posts/introducing-insta-snapshot-testing-for-ruby) | Testing |
| 2025-12-25 | [Glamorous Christmas: Bringing Charm to Ruby](https://marcoroth.dev/posts/glamorous-christmas) | TUI |
| 2025-12-18 | [Giving Back to the Rails Community](https://marcoroth.dev/posts/rails-luminary-2025) | Rails Luminary award |
| 2025-09-11 | [Introducing ReActionView](https://marcoroth.dev/posts/rails-world-2025-recap) | **View layer** |
| 2025-07-17 | [Introducing the Herb Linter, Formatter, and a Vision for the Future of Rails Views](https://marcoroth.dev/posts/railsconf-2025-recap) | **Herb** |
| 2025-06-20 | [Herb Language Server and VS Code Extension](https://marcoroth.dev/posts/herb-language-server) | **Herb LSP** |
| 2025-04-16 | [Introducing Herb](https://marcoroth.dev/posts/introducing-herb) | **Herb parser** |
| 2025-04-03 | [Introducing RubyEvents.org](https://marcoroth.dev/posts/introducing-rubyevents-org) | Community |
| 2025-04-03 | [Introducing the RubyEvents.org iOS App](https://marcoroth.dev/posts/introducing-rubyevents-ios) | Community |
| 2025-01-23 | [2024 Year-in-Review](https://marcoroth.dev/posts/2024-year-in-review) | Retrospective |
| 2023-07-27 | **[Supercharge your Stimulus controllers with Custom APIs](https://marcoroth.dev/posts/supercharge-your-stimulus-controllers-with-custom-apis)** | **Stimulus internals** |
| — | [A Guide to Custom Turbo Stream Actions](https://marcoroth.dev/posts/guide-to-custom-turbo-stream-actions) | **Turbo Streams** |
| — | [Introduction to LHC and LHS](https://marcoroth.dev/posts/introduction-to-lhc-and-lhs) | HTTP clients (not Hotwire) |

---

### ⭐ "Supercharge your Stimulus controllers with Custom APIs" (2023-07-27)

**The single best piece of writing he has produced for our purposes.** It
documents Stimulus's undocumented extension mechanism — **Blessings** — and walks
through building a brand-new Stimulus API end to end.

**The thesis.** Each Stimulus API is a separate `Blessing` that decorates the
`Controller` class:

- Stimulus 1.0.0 → **Targets API**
- Stimulus 2.0.0 → **Values API** and **CSS Classes API**
- Stimulus 3.2.0 → **Outlets API** *(his own contribution)*

```js
// @hotwired/stimulus - src/core/controller.ts
export class Controller {
  static blessings = [
    ClassPropertiesBlessing,
    TargetPropertiesBlessing,
    ValuePropertiesBlessing,
    OutletPropertiesBlessing,
  ]
  // ...
}
```

**The problem he solves.** The recurring boilerplate of hand-rolled `querySelector`
getters for elements you can't make targets or outlets:

```js
import { Controller } from "@hotwired/stimulus"
import tippy from "tippy.js"

export default class extends Controller {
  connect() {
    this.backdropElement.classList.remove("hidden")
    this.itemElements.forEach(element => ...)
    this.tippyElements.forEach(element => tippy(element))
  }

  get backdropElement() { return document.querySelector("#backdrop") }
  get itemElements()   { return document.querySelectorAll(".item") }
  get tippyElements()  { return document.querySelectorAll("[data-tippy]") }
}
```

**The proposed "Elements API"** collapses that to a declaration:

```js
export default class extends Controller {
  static elements = {
    backdrop: "#backdrop",
    item: ".item",
    tippy: "[data-tippy]"
  }

  connect() {
    this.backdropElement.classList.remove("hidden")
    this.itemElements.forEach(element => ...)
    this.tippyElements.forEach(element => tippy(element))
  }
}
```

`[name]Element` → `querySelector`; `[name]Elements` → `querySelectorAll`.

**Full implementation — worth stealing verbatim:**

```js
// app/javascript/element_properties.js
import { readInheritableStaticObjectPairs } from "@hotwired/stimulus/dist/core/inheritable_statics"
import { namespaceCamelize } from "@hotwired/stimulus/dist/core/string_helpers"

export function ElementPropertiesBlessing(constructor) {
  const properties = {}
  const definitions = readInheritableStaticObjectPairs(constructor, "elements")

  definitions.forEach(definition => {
    Object.assign(properties, propertiesForElementDefinition(definition))
  })

  return properties
}

function propertiesForElementDefinition(definition) {
  const [name, selector] = definition
  const camelizedName = namespaceCamelize(name)

  return {
    [`${camelizedName}Element`]: {
      get() {
        return document.querySelector(selector)
      }
    },
    [`${camelizedName}Elements`]: {
      get() {
        return document.querySelectorAll(selector)
      }
    }
  }
}
```

Registration:

```js
// app/javascript/controllers/application.js
import { Application } from "@hotwired/stimulus"
import { Controller } from "@hotwired/stimulus"
import { ElementPropertiesBlessing } from "../element_properties"

Controller.blessings.push(ElementPropertiesBlessing)

const application = Application.start()

application.warnings = true
application.debug = false
window.Stimulus = application

export { application }
```

**Key mechanics to note:**
- `readInheritableStaticObjectPairs(constructor, "elements")` — for object-shaped
  definitions (like Values). Use `readInheritableStaticArrayValues()` for
  array-shaped ones (like Targets). Both respect inheritance up the class chain.
- These imports were private until **his own [stimulus#686](https://github.com/hotwired/stimulus/pull/686)**
  made them reachable; the post notes they landed in Stimulus 3.3.
- Extension ideas he leaves open: a `has[Name]Element` predicate, and letting the
  markup override selectors via `data-[identifier]-[element]-element`:

```html
<div
  data-controller="test"
  data-test-backdrop-element=".backdrop"
  data-test-item-element=".item:not([data-disabled])"
  data-test-tippy-element="span.tippy"
></div>
```

**His closing argument, which is a good design principle for crosswire:**

> Part of the reason for this post was to demonstrate that not every new API needs
> to ship with Stimulus itself to be useful in applications. Shipping custom APIs
> as application-specific code allows us to build APIs to our specific needs
> without polluting the upstream framework.

**Takeaway for us:** Blessings are a first-class, stable, inheritance-aware
extension point that almost nobody uses. This deserves its own crosswire chapter.

---

### Talks — the four-era arc

His speaking splits cleanly into four phases. Full index:
[marcoroth.dev/talks](https://marcoroth.dev/talks) ·
[rubyevents.org/speakers/marco-roth](https://www.rubyevents.org/speakers/marco-roth) ·
[speakerdeck.com/marcoroth](https://speakerdeck.com/marcoroth) (34 decks)

#### Era 1 — Rails World 2023: "The Future of Rails as a Full-stack Framework Powered by Hotwire"
2023-10-07, Amsterdam · [YouTube](https://www.youtube.com/watch?v=iRjei4nj41o) · transcript retrieved (5,034 words)

His origin story and a survey of the ecosystem. On morphing, in his own words
from the transcript:

> "I want to highlight some of the features and recent additions to Turbo — the
> View Transitions API and the morphing additions which are being added to Turbo
> right now. I think they are great examples of adopting and building new features
> on modern JavaScript APIs… those libraries shipped some of the features we saw
> today even a few years ago, and especially around the morphing stuff CableReady
> and StimulusReflex provided a lot of those features a few years back."

And on TurboPower's own future, strikingly candid:

> "…you might be asking, those tools exist, they are super similar, why do they
> even exist and why do we want to keep using them — and the answer is, we
> probably won't use them anymore because we have more advanced use cases [in
> Turbo]."

On motivation: after "getting frustrated by a lot of over-engineered React
applications", he wanted "to help improve the state of reactive applications in
Rails" — which is why he started contributing to open source at all.

#### Era 2 — "Revisiting the Hotwire Landscape after Turbo 8" (2024, ×4)

Geneva.rb (2024-04-16), **RailsConf 2024 (2024-05-09, Detroit)**, Helvetic Ruby
(2024-05-17), Brighton Ruby (2024-06-28).
[YouTube](https://www.youtube.com/watch?v=eh2joX5n58o) (31:59) ·
[slides PDF](https://speakerdeck.com/marcoroth/revisiting-the-hotwire-landscape-after-turbo-8)

⚠️ **The YouTube auto-captions for this talk are corrupted** — the ASR produced
~120 usable words for a 32-minute talk ("start the morning start Marco Marco open
morning I know I have like but also…"). RubyEvents.org serves the same broken
transcript. **I reconstructed the content from the 1,934-word slide PDF instead**,
which turned out to be richer than a transcript would have been.

**Content, reconstructed from slides:**

1. **Timeline** — Turbolinks 5 (2018) → Stimulus + CableReady (2020) → Phoenix
   LiveView + StimulusReflex (2020) → Hotwire/Turbo (2021) → Hotwire default in
   Rails → **Turbo 8 with Morphing (Feb 2024)**. "The paths are converging. They
   have the same goal."
2. **The StimulusReflex wind-down** (quoted in full above) — 3.5 and CableReady
   5.0 are the last feature releases. "Should you start new apps with
   StimulusReflex? **Probably not.**"
3. **The feature-lag table** (reproduced above) — Turbo took 1–4+ years to reach
   parity with SR/CR ideas, and **two rows have no Turbo equivalent at all**.
4. **"None of this is to blame. What can we learn from it?"** — the diagnosis is
   organisational: *"There is no Hotwire Core Team."* Missing tooling, education,
   marketing, documentation, issue triage, community building, framework
   integrations, migration support. "There are a lot of open issues and
   unaddressed pull requests."
5. **The Stimulus DX problem** — the identifier-mismatch demo:
   ```
   app/javascript/controllers/user_profile_controller.js
   <div data-controller="user_profile"></div>   ← silently never connects
   <div data-controller="user-profile"></div>   ← correct
   ```
   *"These mistakes happen so easily. Can we do better?"* → **Stimulus LSP,
   available now**, backed by stimulus-parser which "parses JavaScript classes and
   traces imports and exports" and "registers and tracks identifiers".
6. **hotwire.io + Hotwire Weekly** launch/status (1,200+ subscribers).
7. **The wishlist** — verbatim from the closing slides:
   > Optimistic UI · Optimistic client-side rendering · "Frameless" Turbo Frames ·
   > **Partial Page Morph Updates** · **Independent Morphing** · Plugins/Extensibility ·
   > Web Components · PWA · Better React-compatibility

   > "Turbo 8 has been awesome and is going in the right direction. But we need
   > more of it. And [we need] a more formal and 'official' way of pushing things
   > forward."

#### Era 3 — "Leveling Up Developer Tooling For The Modern Rails & Hotwire Era" (2024, ×7)

Red Dot Ruby (07-25), Madison+ Ruby (08-02), RoR Switzerland (08-22), EuRuKo
Sarajevo (09-12), Rocky Mountain Ruby (10-07), Geneva.rb (10-16), Ruby Türkiye
(11-20). [YouTube — EuRuKo/RDRC](https://www.youtube.com/watch?v=hKaIN-n1B-A) ·
transcript retrieved (5,411 words)

The LSP/parser tour: stimulus-parser, stimulus-lsp, turbo-lsp. **Notably, the
transcript contains zero occurrences of "morph"** — by this point his attention
had moved entirely from runtime behaviour to static analysis. This is the hinge
between the Hotwire-ecosystem era and the Herb era.

#### Era 4 — Herb & ReActionView (2025–2026, ~20 appearances)

- **RubyKaigi 2025** (2025-04-16, Matsuyama) — *Empowering Developers with
  HTML-Aware ERB Tooling*. Herb parser launch.
- **RailsConf 2025** (2025-07-10, Philadelphia) — *The Modern View Layer Rails
  Deserves: A Vision for 2025 and Beyond*. Linter + formatter + LSP.
- **Rails World 2025** (Amsterdam), **EuRuKo 2025**, **Kaigi on Rails 2025**
  (Tokyo) — *Introducing ReActionView*.
- **SF Ruby Conference 2025** (2025-11-19) — **keynote**, *Herb to ReActionView:
  A New Foundation for the View Layer*.
- **2026:** *Your Views Deserve a Grammar* (keynote, Tropical on Rails),
  **Herb in Rails 8.2: Your ERB Views, Now HTML-Aware** (Rocky Mountain Ruby
  2026), *The Anatomy of an ERB Rendering Engine*, and the flagship
  **HTML-Aware ERB: The Path to Reactive Rendering** (RubyKaigi 2026 Hakodate,
  RubyCon 2026 Rimini, Balkan Ruby 2026 Sofia).

**"Herb in Rails 8.2" implies Herb is being upstreamed into Rails itself** —
worth confirming (see Open questions).

#### ⭐ "HTML-Aware ERB: The Path to Reactive Rendering" (RubyKaigi 2026)

[slides PDF](https://speakerdeck.com/marcoroth/html-aware-erb-the-path-to-reactive-rendering-at-rubykaigi-2026-hakodate-japan) · 3,217 words extracted

**This is the most important talk for us, and it reframes the entire morphing
problem.** Read the morphing section below for why. Content summary:

**A syntax-tree diffing engine.** [herb#1518](https://github.com/marcoroth/herb/pull/1518)
adds `Herb.diff(old_source, new_source)` — a *template-level* diff, not a DOM diff:

```
<div>Hello World</div>  →  <div>Hello Ruby</div>
<h1><%= title %></h1>   →  <h1 class="title"><%= title %></h1>
```

> "This allows us to compute the minimal changes needed to reflect a state change
> in the UI."

**A dependency graph.** What Herb statically knows about a template:

> ✓ ~250 ActionView helpers (via registry)
> ✓ Strict locals declarations
> ✓ Locals passed through render calls
> ✓ Instance variables (`@post`, `@user`)
> ✓ Constants (`Current.user`, `Post.count`)
>
> ✓ Understand the render graph
> ✓ Trace state dependencies
> ✓ Resolving ActionView Tag Helpers
> ✓ **Track which variables affect which DOM nodes**

with an example mapping a variable to the nodes that depend on it:

```
@user => [
  "<% if @user.admin? %>",
  "<p><%= @user.id %></p>"
]
```

**Shipping today:** `herb dev` — a hot-reloading dev server that edits a template
and patches the DOM incrementally via the diff engine, "no full page refresh".

**Compile-time optimisation** (a side-effect of the reactivity work) — ActionView
tag helpers are resolved to literal HTML at compile time:

```erb
<%= turbo_frame_tag dom_id(@post) do %>
  <%= tag.div data: { controller: "hello" } do %>
    <%= link_to @post.title, post_path(@post) %>
  <% end %>
<% end %>
```
↓
```erb
<turbo-frame id="<%= dom_id(@post) %>">
  <div data-controller="hello">
    <a href="<%= post_path(@post) %>"><%= @post.title %></a>
  </div>
</turbo-frame>
```

**His thesis, verbatim:**

> "We aren't quite there yet for production reactivity. But this gives us all the
> primitives and foundation to build out this vision — where we can have Phoenix
> LiveView-like server-side reactivity in Ruby."
>
> "With the Herb Toolchain as the foundation, reactivity now feels doable.
> **I think reactivity is the missing piece to complete the Hotwire story.**"
>
> "The Ruby Prism Parser had a big effect on Ruby internals and the tooling
> landscape. Herb can have a similar effect for HTML Templating and Tooling."

---

## Tooling we should adopt immediately

### 1. Herb linter in CI — **do this first**

Highest value-to-effort ratio available. Zero Ruby-side risk (it's a static
analyser, not a runtime engine), and it immediately enforces correctness on every
ERB file we ship as a recipe.

```sh
npx @herb-tools/linter app/views
```

Concretely for crosswire:
- **`turbo-permanent-require-id`** is worth the install on its own. Every
  `data-turbo-permanent` we publish in a recipe *must* have an `id` or it silently
  does nothing — exactly the class of bug our readers will hit.
- `html-no-duplicate-ids` matters a lot for Turbo Frames and morphing, where
  Idiomorph matches on `id`. Duplicate IDs produce genuinely baffling morph
  behaviour.
- `erb-no-unsafe-raw`, `erb-no-raw-output-in-attribute-value` and
  `erb-no-unsafe-js-attribute` guard the exact spot where our recipes interpolate
  Ruby into `data-*-value` attributes.
- `ujs-prefer-turbo-*` catches Rails-UJS leftovers in any example we adapt from
  older sources.

Add a `.herb.yml`/lint step to the crosswire repo and run it over `research/` and
any example app. Adopt the **linter** now; hold on the **formatter** (still
flagged experimental) and on **ReActionView** (v0.3.0).

### 2. Ship a `stimulus-lsp` config with crosswire — **and build the CI check Marco hasn't**

Two parts.

**(a) Document the editor setup.** Add a `.stimulus-lsp/config.json` to the repo
and a short setup page covering VS Code (`marcoroth.stimulus-lsp`), Neovim
(`stimulus_ls`), and Zed (`vitallium/zed-stimulus`). It turns the single most
common Hotwire failure mode — a `data-controller` typo that fails silently — into
an editor squiggle. For a repo whose entire premise is "rich UI without React",
making Stimulus fail *loudly* is on-mission.

**(b) Fill the gap Marco has left open.** stimulus-lsp is editor-only; there is
**no CLI, so it cannot gate CI**, and Herb has **zero Stimulus rules**. We can
close that with ~40 lines using `stimulus-parser`:

```js
import { Project } from "stimulus-parser"

const project = new Project(process.cwd())
await project.initialize()

const known = new Set(project.controllerDefinitions.map(c => c.identifier))
// then walk .html.erb (via @herb-tools/core) and assert every
// data-controller / data-*-target / data-*-value resolves against `known`
```

Herb parses the ERB into a real tree; stimulus-parser resolves the controllers.
Nobody has wired these two together yet, and **both are by the same author, so
the pieces are designed to fit.** This would be a genuinely novel contribution
crosswire could publish — and a strong candidate to upstream to Herb as the
missing `stimulus-*` rule family.

### 3. Steal the Blessings pattern for a crosswire chapter

The [Elements API post](https://marcoroth.dev/posts/supercharge-your-stimulus-controllers-with-custom-apis)
documents a stable, inheritance-aware Stimulus extension point that is almost
entirely unknown and almost entirely undocumented upstream. Full working code is
transcribed above. This is exactly the "rich UI the Rails way" material crosswire
exists to collect — and it's the sanctioned way to add app-specific APIs without
forking Stimulus.

**Runner-up:** `current.js` (410 bytes) as the recipe for exposing server state to
the client — with the added benefit that `<meta>` tags in `<head>` sit outside the
morphed `<body>`, making it a **morph-safe** state channel.

---

## Anything he's said about the morph/Stimulus-values conflict

**Short answer: he has never addressed it, and I can now say that with high
confidence. But what he *has* said reframes the problem in a way that matters more
than a workaround would.**

### The confident negative

I checked every channel systematically:

| Channel | Result |
|---|---|
| [turbo#1210](https://github.com/hotwired/turbo/issues/1210) "Turbo morph not preserving stimulus values" | Opened 2024-03-01 by `rbclark`. **1 comment, by `seanpdoyle`.** Still open, untouched since 2024-03-01. **Roth never commented.** |
| [stimulus#801](https://github.com/hotwired/stimulus/issues/801) "Helper functions for morph inhibition in stimulus" | Opened 2024-11-04 by `brendon`. **Closed 2025-03-23 with zero comments.** **Roth never commented.** |
| His comments across `hotwired/*` mentioning "morph" | Exactly 4 issues: turbo#1240, turbo#1163, turbo#431, turbo#684. None concern Stimulus values or `connect()`. |
| RailsConf 2024 slide deck (1,934 words) | `connect()` appears 8× — **all** in the identifier-typo/stimulus-lsp demo, none about morphing. |
| Rails World 2023 transcript (5,034 words) | "morph" ×3, all about Turbo adopting CableReady/SR ideas. No values/lifecycle discussion. |
| "Leveling Up Developer Tooling" transcript (5,411 words) | **Zero** "morph" occurrences. |
| RubyKaigi 2026 deck (3,217 words) | **Zero** "morph"/"idiomorph"/"Stimulus" occurrences. |
| His 13 blog posts | No morphing post exists. |
| `marcoroth/*` repos | Only `turbo-morph`, which predates Turbo 8 by a year. |

**There is no Marco Roth statement, issue, PR, post, or slide addressing the fact
that Turbo 8 morphing overwrites `data-*-value` attributes and skips `connect()`.**

### What he did say — and why it's worse than silence

In **[turbo#1163](https://github.com/hotwired/turbo/issues/1163)** (2024-02-07),
arguing for an independent `morph` Stream action, he wrote:

> "There are definitely reasons why you'd want to have an independent morph
> action. **Morphing has the benefit of not loosing client-side state.** In any
> case where you are currently using `turbo_stream.replace` or
> `turbo_stream.update` you could consider upgrading that call to a
> `turbo_stream.morph`. I've personally done this quite often."

This is dated **three weeks before turbo#1210 was filed** — and it asserts the
exact opposite of what #1210 reports. He is recommending morphing *because* it
preserves client-side state, at the moment when the ecosystem was about to
discover that it specifically does *not* preserve Stimulus values. He is, as far
as I can tell, simply unaware of the conflict, and no one has raised it with him.

**Implication for crosswire: we cannot cite Marco Roth as having sanctioned any
workaround, and we should be careful not to propagate the "morphing preserves
client-side state" framing without qualification. It preserves *DOM* state
(focus, scroll, form input, CSS classes applied at runtime); it clobbers
*declarative attribute* state, which is exactly where Stimulus values live.**

### His actual morphing critique: granularity, not lifecycle

Where he *has* pushed on morphing, it's about **scope**. The RailsConf 2024
feature-lag table has two rows where Turbo's column is literally `?`:

| Feature | StimulusReflex/CableReady | Turbo | Lag |
|---|---|---|---|
| **Morphing as an individual concept** | CR Morph Action + SR Morphs, **Aug 2019** | **— none —** | **4 yr 9 mo+** |
| **Partial page refreshes** | SR Selector Morph, **May 2020** | **— none —** | **4 yr+** |

And his closing wishlist names the gap twice: **"Partial Page Morph Updates"** and
**"Independent Morphing"**, alongside *"Morphing beyond Page Refreshes"* in the
list of what Hotwire should inherit from StimulusReflex.

His position: Turbo 8 bolted morphing to the *page refresh* mechanism, so you get
it all-or-nothing at page scope. StimulusReflex had **selector-scoped** morphs
five years earlier. This is a real and separate criticism from #1210 — and note
that it *interacts* with #1210, because narrower morph scope means fewer
controllers needlessly morphed and fewer values clobbered. He never connects the
two, but the connection is ours to make.

Related upstream: in **[turbo#1240](https://github.com/hotwired/turbo/issues/1240)**
(seanpdoyle, closed 2024-07-12) morph support was restructured into
`<turbo-stream action="replace" method="morph">`. Roth suggested keeping `morph`
as a deprecation shim, then withdrew it ("Oh right, nevermind then. I guess I
confused it with the `refresh` action"). **So `replace` + `method="morph"` is the
current sanctioned narrow-scope morph** — the closest thing to "independent
morphing" that shipped, and the thing crosswire should document instead of
TurboPower's `morph`.

### The genuinely high-value finding: he is routing around the problem entirely

**This is the answer to bring back.** His 2026 work implies a position on the
morphing problem even though he never states one.

Turbo 8 morphing is **blind**: Idiomorph receives two DOM trees and diffs them
structurally, with no knowledge of which parts came from which template
expression or which attributes are semantically load-bearing. `data-foo-value` is
just an attribute; Idiomorph overwrites it because it has no reason not to. Every
mitigation in the ecosystem is therefore an *opt-out* bolted on afterwards —
`data-turbo-permanent`, `turbo:before-morph-attribute` + `preventDefault()` (see
the code in stimulus#801), `data-turbo-morph="false"`.

`Herb.diff(old_source, new_source)` is a bet on the opposite architecture: diff
the **templates**, server-side, with full knowledge of the render graph, strict
locals, instance variables, ~250 ActionView helpers, and — critically —
**"track which variables affect which DOM nodes."** A diff engine with that
information can emit "change the text of *this* node" rather than "here is a new
page, reconcile it", and the values-clobbering problem never arises because
untouched attributes are never in the patch set.

> "I think reactivity is the missing piece to complete the Hotwire story."

**So: he has no workaround for turbo#1210 because he doesn't think the DOM-morphing
architecture is the endgame.** The RailsConf 2024 wishlist ("Partial Page Morph
Updates", "Independent Morphing") and the 2026 diff engine are the same argument
at two levels of ambition: *morphing is too coarse and too blind*.

**Practical guidance for crosswire, which we now have to write ourselves:**

1. The "keep state in Stimulus values" ⟷ "enable morphing" conflict is **real,
   open, and unaddressed by the ecosystem's most prolific tooling author.** Treat
   it as a genuine architectural constraint, not a bug awaiting a fix.
2. Prefer **narrow-scope morphs** — `<turbo-stream action="replace" method="morph">`
   over full-page refresh morphing. This is Roth's "independent morphing" position
   and it shrinks the blast radius.
3. Keep morph-sensitive client state **out of `data-*-value`**: use `<meta
   name="current-*">` + `current.js` (outside the morphed `<body>`), or a
   controller instance property set in `connect()`, or `data-turbo-permanent`
   (with an `id` — Herb's `turbo-permanent-require-id` enforces this).
4. Where values must survive, use `fooValueChanged(value, oldValue)` — the
   `oldValue` argument exists because of **Roth's own
   [stimulus#407](https://github.com/hotwired/stimulus/pull/407)** — to detect and
   correct morph-driven attribute changes.
5. Watch `Herb.diff` ([herb#1518](https://github.com/marcoroth/herb/pull/1518)).
   If server-side template diffing lands in ReActionView, it dissolves this
   problem rather than patching it.

---

## Open questions

1. **Is Herb actually shipping in Rails 8.2?** His 2026 talk title *"Herb in Rails
   8.2: Your ERB views, now HTML-aware"* (Rocky Mountain Ruby 2026) strongly
   implies upstreaming. If Herb becomes a Rails default, our "adopt the linter"
   recommendation becomes "document the built-in". **Verify against rails/rails
   before publishing.** Highest-priority follow-up.
2. **Has anyone told him about turbo#1210?** Given he publicly recommends morphing
   *because* it "preserves client-side state", a well-constructed issue or a note
   in Hotwire Weekly could plausibly move this. Possible crosswire contribution.
3. **Is Hotwire Weekly paused or ended?** Last issue 2026-03-30, silent 4.5
   months, cadence already degrading beforehand. No announcement found. Affects
   whether we treat it as a live distribution channel.
4. **Will `Herb.diff` reach production?** He is explicit: *"We aren't quite there
   yet for production reactivity."* Timeline unknown.
5. **Will Stimulus rules land in Herb?** Currently zero. If they do, our proposed
   CI check becomes redundant — worth asking him directly before we build it.
6. **RailsConf 2024 talk content is reconstructed from slides, not the talk.** The
   YouTube auto-captions are corrupted (~120 usable words / 32 min) and
   RubyEvents.org mirrors the same broken data. Everything attributed to that talk
   here comes from the slide PDF. If the verbal argument matters, someone should
   watch the 32 minutes.
7. **turbo_power's long-term maintenance.** v0.8.0's only substantive PRs were by
   an outside contributor. At 444k dl/mo it's load-bearing for a lot of apps; if
   Roth has stepped back, that's a risk worth flagging in any recipe that depends
   on it.
8. **hotwire.io responsiveness.** Seven months without a push. Worth a probe PR
   before investing in a larger contribution.

---

### Sources

GitHub via authed `gh` (repos, PRs, issues, comments, file trees, releases);
npm registry + `api.npmjs.org` download endpoints; RubyGems API; VS Code
Marketplace `extensionquery` API; `curl-impersonate` + `html2text` for
marcoroth.dev, herb-tools.dev, buttondown.com, rubyevents.org, speakerdeck.com;
`yt-dlp --write-auto-sub --skip-download` + custom VTT cleaner for YouTube
transcripts; `pdftotext` on speakerdeck PDFs.
