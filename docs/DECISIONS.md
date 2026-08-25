# Crosswire — locked decisions

Source of truth for settled questions. Check here before re-opening anything.
Proposals and reasoning live in `docs/SYNTHESIS.md`; evidence lives in `research/`.

Format: **D#** · decision · date locked · rationale · what would reopen it.

---

## D1 — Sequencing: thin gem + docs together
**Locked 2026-08-15 (Jake).**

Ship ~10 load-bearing primitives with helpers and full APG accessibility, alongside the
corrections log and diagnosis recipes. Defer the other 28 primitives, native, server-side
components, and any signals layer.

Initial ten (most load-bearing first, per `research/notes/08` build order):
`dismiss` · `persist` · `intersection` · `transition` · `focus-trap` · `dialog` ·
`autosubmit` · `disclosure` · `clipboard` · `confirm`

**Why:** the docs are ~free — the corrections log and diagnosis pages are already ~90%
written inside the research corpus — and ten primitives prove the thesis without committing
to 39 public APIs before a single consumer exists. Reddit says documentation is the #1
complaint about Hotwire by a wide margin (`07b`), so docs are not a consolation prize; they
are the highest-leverage deliverable.

**Reopen if:** a real consumer needs a primitive outside the ten badly enough to fork.

---

## D2 — Component scope: client-side v1, server side as an opt-in add-on later
**Locked 2026-08-15 (Jake).**

v1 components are markup + Stimulus controller + ERB helper. The consumer writes their own
routes and controller actions. A `crosswire-server` companion — engine routes, controller
concerns, `turbo_stream` templates — is deferred until the client API has stabilised against
a real consumer.

**Why:** keeps the differentiating move available without betting the core API on it. The
"components aren't self-contained" complaint (`07b`, recurring 2022→2026) is legitimate and
is the axis Inertia wins on, but answering it costs API surface and invites the "too much
magic" failure mode Rails libraries die of.

**Reopen if:** v1 lands and the top consumer complaint is "I still have to write the endpoint."

---

## D3 — Hotwire Native: design for it, don't test it yet
**Locked 2026-08-15 (Jake).**

Use `static get shouldLoad()` gating so every controller degrades cleanly, document the
stacked-controller pattern (`data-controller="menu bridge--menu"`), and ship path-config
recipes in the docs. Do **not** ship bridge components or stand up Xcode/Android CI.

**Why:** costs ~zero on the web — `shouldLoad` gates on a substring in the native user agent,
so the native half is never even registered in a browser (`04`). Full native support needs
toolchains and devices we don't have a reason to maintain yet.

**Reopen if:** a native app materialises, or the path-configuration DSL gap (nothing in the
ecosystem generates both platforms' JSON — `04`) becomes worth claiming.

---

## D4 — Books: none for now
**Locked 2026-08-15 (Jake).**

**Why:** the free corpus is already deep — hotrails.dev's 12 chapters, ~35 conference talks,
Sean Doyle's 25 branches, and 62k lines of research notes. Revisit only against a specific gap.

**Reopen if:** a build-phase gap maps onto a specific title. Most likely candidates, in order:
Master Hotwire (€49; debugging/testing/legacy-migration chapters) and Masilotti's *Hotwire
Native for Rails Developers* (~$31) if D3 flips.

---

## Settled by research (not requiring a call)

These follow from evidence in `research/`. Listed so they aren't relitigated by default;
each cites the file that establishes it.

| # | Decision | Src |
|---|---|---|
| R1 | Ship as a **Rails engine gem** — `bundle add crosswire` is the product | 10, 17 |
| R2 | **Unbundled per-controller ESM** + bundled fallback (a single bundle cannot be lazy-loaded by `stimulus-loading`) | 10 |
| R3 | **Plain JS, not TypeScript** (TS needs a compile step, which breaks `pin_all_from`) | 10 |
| R4 | **Opt-in `cw_attrs`** merging, never an app-wide `TagBuilder` monkeypatch | 17, 19 |
| R5 | Teach **three tiers** — Stimulus (wiring) / ES classes (logic) / custom elements (components) | 16 |
| R6 | **Rule 0 first**: can the server do it? Kills more component candidates than all other rules combined | 16, 08 |
| R7 | Default to **`turbo_stream.replace(target, method: :morph)`**, not page-level morphing | 11, 13, 14 |
| R8 | **Vitest two-tier** (jsdom + browser mode) + Minitest/Cuprite | 10 |
| R9 | **APG-complete in the controller**, never opt-in consumer wiring — this is the moat | 10, 12, 19 |
| R10 | Naming: `cw--` identifiers, `cw--name:verb` events. Helper naming superseded by `D8` — was flat `crosswire_*` methods, now per-component methods on the `cw`/`crosswire` builder | 17 |
| R11 | **39-primitive vocabulary**, converged with zero drift across ~95 patterns. No `modal` controller | 08 |

---

## D5 — View layer: context-free presenter core, ERB partials in v1, VC companion deferred, no Phlex
**Resolved 2026-08-15 by evidence (`research/notes/20-view-layer-reconsidered.md`). Jake may overrule.**

Reopened by Jake, who challenged `17`'s "not ViewComponent, not Phlex" verdict. The
investigation **corrected `17`'s reasoning but largely upheld its conclusion**, and changed
the core design.

**The correction that matters.** The override asymmetry belongs to **sidecar templates**, not
to ViewComponent. A VC's `@lookup_context` *is* the app's (`base.rb:117`), so a component
whose template simply delegates — `<%= render partial: "crosswire/disclosure", … %>` — picks
up an app's shadowed partial normally. Verified by building all five variants:

| Renderer | App override wins? |
|---|---|
| ERB helper | **yes** |
| VC with its own sidecar template | no |
| VC delegating to a core partial | **yes** |
| Phlex with Ruby markup | no |
| Phlex delegating to a core partial | **yes** |

So we control whether shadowing works. `17`'s "one asymmetry decides this" was wrong.
(Confirmed separately: VC 4.12.0 has exactly three template sources and **zero** runtime
references to view paths; `config.view_component_path` does not exist in v4; monkeypatching
`erb_template` onto a shipped component fails because templates are memoized and compiled.)

**The decisions:**

1. **Presenters are the core, and take NO view context.** Pure POROs returning attribute
   hashes — `Crosswire::Disclosure#trigger_attrs` / `#panel_attrs`. This **corrects `17`'s
   design**, which passed a view context into the presenter; that blocks Phlex reuse and
   makes unit testing awkward. Empirically validated: one presenter drove **four renderers to
   byte-identical HTML**, with adapters of 9–17 lines and zero logic.
2. **ERB helpers + partials ship in v1**, as the only renderer.
3. **`crosswire-view_component` is deferred to post-v1**, built when a consumer asks. Its
   templates will *delegate to the core partials*, so VC users get idiomatic call sites **and**
   shadowing **and** subclass + `render_parent`.
4. **No `crosswire-phlex`.** A transitive *patch-level* pin (`phlex ~> 2.4.0`), ~200 helper
   shims, its own serializer quirks and a second CI matrix — for the smallest audience.
5. **VC-primary is rejected**: the good override behaviour comes from the partial, not from
   VC, so "VC primary over partials" is just ERB-primary plus a mandatory dependency.

**The strongest counter-argument, now answered.** Shadowed partials going silently stale on
upgrade was the real objection (and `17` waved it away in a sentence). Resolved with a ~25-line
boot-time `ShadowCheck`: resolve each shipped partial through the app's `LookupContext` and
verify a `<%# crosswire:contract vN %>` marker. All four scenarios pass, including "crosswire
v2 ships, the app's shadow still declares v1" → caught at boot, naming the file and both
versions. That is what makes shadowing defensible rather than merely convenient.

**Novelty:** no Ruby gem ships one component set through ERB + VC/Phlex. Closest is `vident`
(core + `-view_component` + `-phlex`), which validates the shape but has no ERB leg. Cautionary
data point: **pagy deleted its entire extras/frontends system at v43** and discontinued four of
six frontends — multi-frontend maintenance has a real failure record.

**Reopen if:** a consumer needs VC before v1 ships (then pull the companion forward — it does
not change the core), or if presenter-driven adapters start accumulating logic, which is the
signal that the zero-logic premise has broken.

---

## D6 — Distribution: gem first, with tiered ejection and a copy-paste catalog
**Locked 2026-08-15 (Jake).**

Jake asked whether the shadcn copy/paste model beats shipping partials. Answer: do both,
because our architecture supports copy/paste *better* than shadcn's does.

**Ship the gem.** Then `rails g crosswire:eject <component>` with three tiers:

| Tier | Copies | Consumer keeps receiving |
|---|---|---|
| `--markup` *(default)* | the partial | a11y wiring, controller fixes, presenter changes |
| `--controller` | partial + Stimulus controller, re-registered under the app's own identifier | nothing — full ownership |
| `--all` | every component's markup | as per `--markup` |

**Why this beats plain shadcn**, and it is structural, not marketing:

1. **Accessibility lives in the presenter (Ruby), not in the markup.** An ejected partial
   that still calls `d.trigger_attrs` keeps correct `aria-expanded` / `aria-controls` / id
   wiring even after a total restyle. In shadcn the a11y is *in* the copied code, so an
   edit can silently break it and never be fixed upstream.
2. **`ShadowCheck` gives ejected markup a version contract.** The `<%# crosswire:contract vN %>`
   marker means a v2 upgrade fails at boot naming the file and both versions. Copy/paste
   normally has no staleness signal at all; this is the mechanism that gives it one.

**Corollary that constrains everything else:** keep partials deliberately dumb and push all
logic and a11y into presenters. The more that lives in the presenter, the more an ejected
component keeps working correctly. This reinforces D5 rather than complicating it.

**Also:** the docs site doubles as a **copy-paste catalog**, rendering each component's full
source from the same files the gem ships, so someone can lift a component with no dependency
at all.

**Market context** (`07b`, `05`, `09`): Reddit's single repeated reason for choosing Inertia
is *"you get shadcn and a ready-made component ecosystem."* `shadcn-rails` (892★) explicitly
says it is not a component library. **Rails Designer, the closest commercial competitor,
already ships generator-delivered rather than as a runtime dependency.** Copy-in is the
prevailing expectation in this space; the gem is what lets us also offer maintenance.

**Reopen if:** ejection turns out to be the dominant install path, which would mean the gem
is scaffolding rather than a dependency and the maintenance story needs rethinking.

---

## D7 — Survivability tier: preserve, loading/fallback, Streams — in-core, outside the 39
**Locked 2026-08-16 (Jake).**

Four pieces — `preserve` (morph-state survival), `loading` + `fallback` (declarative
in-flight/failure state), and `Crosswire::Streams` (`AuthorizedStreamChannel` +
`versioned_replace`) — ship in the **core gem**, not in the deferred `crosswire-server`
companion (`D2`). They sit **outside** the locked 39-primitive vocabulary (`R11`) as a
distinct **survivability** group, not primitives #40–43: they answer a different
question — "does the app survive Turbo 8 morphing and multi-worker broadcasts" — from
the one the 39-primitive catalog answers ("what UI patterns need JS"), and folding them
into that count would make "N of 39" mean two different kinds of thing.

**Why in-core, not `crosswire-server`:** `D2` deferred the server companion because it
costs API surface for a complaint ("I still have to write the endpoint") that a real
consumer hadn't raised yet. This tier answers a different complaint — Turbo 8 morphing
and `broadcast_replace_to` are silently unsafe by default, for every consumer, whether
or not they've asked for server-side routes. That is a correctness gap in the client
API's contract with Turbo, not a convenience layer on top of it.

**Four API decisions, each locked separately:**

a. **`data-loading` is bare, not `data-cw-loading`.** Livewire already owns this exact
   attribute name; matching it means Tailwind v4's `data-loading:` variants work
   verbatim, with zero config and zero CSS shipped.
b. **The stream action is `versioned_replace`, not `cw_versioned_replace`.** It
   productizes an existing community pattern (Radan Skorić's), and an unprefixed verb
   reads naturally inside `turbo_stream.versioned_replace` / `<turbo-stream
   action="versioned_replace">` in ERB the way every other stream action does.
c. **The dialog morph-deadlock guard is always-on inside `cw--dialog`, not
   configurable.** A deadlocking `<dialog>` is a bug, not a policy choice — there is no
   scenario where a consumer would want it off, so there is nothing to make optional.
d. **Version floors: `@hotwired/turbo` ^8.0.14, `turbo-rails` 2.0.23.** 8.0.14 is the
   first Turbo release exporting `morphElements` (`preserve` and `installDialogMorphGuard`
   call it directly); 2.0.23 is the version this tier was built and verified against.
   Below either floor, the primitives this tier depends on are not exported/available.

**Evidence base:** `research/notes/14-morphing-dossier.md` (the design brief, B1–B7,
that `preserve` implements verbatim, and the turbo#1239 dialog fix) and
`research/notes/02-turbo-deep-dive.md` §4.5 (`turbo_stream_from`'s name-only
authentication, which `AuthorizedStreamChannel` closes).

**Reopen if:** a consumer needs the survivability names folded into the primitive count
for tooling/marketing reasons, or `crosswire-server` lands and it turns out these pieces
belong there instead.

---

## D8 — The `crosswire`/`cw` builder facade
**Locked 2026-08-16 (Jake).**

Replace the ~90 flat `crosswire_<name>[_for|_attrs]` view helpers with a single entry
point, `crosswire` (canonical) / `cw` (shipped alias), returning a
`Crosswire::Builder` — modeled directly on Turbo's own `turbo_stream.`/`tag.`
TagBuilder idiom, not invented here:

```erb
<%= cw.disclosure "Shipping details", id: "shipping" do %>...<% end %>
<%= cw.disclosure_for id: "faq-1" do |d| %>...<% end %>
<%= tag.div **cw.disclosure_attrs(id: "x") %>
<%= cw.stream_from @board, channel: BoardChannel %>
```

Methods stay FLAT per component (`<name>`, `<name>_for`, `<name>_attrs`), not nested
under a further namespace — `cw.disclosure_for`, never `cw.disclosure.for`. Streams
gets the same treatment: `stream_from`, `version_attrs`, `versioned_replace`.

**Full cutover, no deprecation shim.** Pre-release, zero external users (`D1`'s
sequencing is exactly what makes this cheap now and expensive later): the old
`crosswire_*`-prefixed methods disappear from the view namespace entirely, rather than
aliasing forward. The 153-tutorial series this positions crosswire for (`D1`) gets
written once, against the final API, instead of once now and once after a v2 rename.

**Why now, why this shape:**
- **Namespace hygiene.** 31 components × up to 3 variants ≈ 90+ methods landing in
  *every* view, whether or not that view uses them, versus one name (plus its alias) that
  autocompletes into the whole vocabulary.
- **Rails-native precedent, not a new idiom.** `turbo_stream.replace`/`.append`/etc. and
  `tag.div`/`tag.button` already teach every Rails developer this exact shape:
  `Turbo::Streams::TagBuilder.new(view_context)`, unknown methods delegated to the view
  context. `Crosswire::Builder` copies that architecture line for line — construction,
  memoization, delegation.
- **`cw`/`crosswire` mirrors `t`/`translate` and `turbo_stream`.** A short alias for a
  hot path, with the unabbreviated name always available — not a new naming convention.
- **Discoverability doubles as documentation.** `cw.` + autocomplete lists the whole
  vocabulary from inside the editor, and a `NoMethodError` can teach instead of just
  failing — `cw.modal` explains that a modal is `dialog` + `focus-trap` + `scroll-lock`
  + `dismiss` + `transition`, composed, rather than a name crosswire will never define
  (`docs/COMPONENT_CONTRACT.md`'s "Banned as primitive names").
- **The future styled-component tier lands in the same namespace for free** —
  `cw.button` and friends, whenever that tier ships, need no new entry point.

**Architecture:** `lib/crosswire/builder.rb` is a plain Ruby class (no Rails requires of
its own — it stays loadable by `test/crosswire/contract_audit_test.rb`'s Rails-free
suite, `D5`). Every per-component helper module keeps its file
(`app/helpers/crosswire/<name>_helper.rb`) and logic, with its methods renamed to drop
the `crosswire_` prefix (`crosswire_disclosure_attrs` → `disclosure_attrs`), and is
`include`d into `Crosswire::Builder` — NOT into views. The module bodies are otherwise
unmodified: they still call `render`, `capture`, `tag`, `turbo_stream` as though `self`
were the view context, which keeps working because `Builder#method_missing` forwards
anything it doesn't itself define to the real view context it was constructed with.
`Crosswire::StreamsHelper` gets the identical treatment, which is a genuine
simplification over the pre-D8 world: it no longer needs registering by hand in
`test/dummy/app/controllers/crosswire_preview_controller.rb` and `HelperCase` (both used
to `helper Crosswire::StreamsHelper` explicitly, since it names no component for a
`Crosswire.component_names` loop to find) — as of D8 it rides along with every other
helper module simply by being `include`d into `Builder` once, in one place.

**`CW` (capitalized) was rejected** — it reads as a Ruby constant and fights linters
expecting a bare local/method call.

**`cw_attrs` (and `cw_presenter`) stay view-level helpers, unchanged.** They are
attribute-merge/presenter-construction *utilities*, not component primitives — folding
them into the builder would mean `cw.cw_attrs(...)`, which buys nothing and reads worse
than `cw_attrs(...)` already does.

**Collision note:** `cw`/`crosswire` occupy 2 names in the view helper namespace instead
of ~90. If a host app already defines `cw`, `crosswire` (the canonical, unabbreviated
name) is still available — no config toggle for choosing a different name ships in v1
(YAGNI; see Reopen-if).

**Reopen if:** a host app has a real, unavoidable collision on both `cw` AND
`crosswire` (unlikely enough not to design for up front), or a future styled-component
tier turns out to want its own separate entry point after all.

---

## Open

*(none currently blocking)*

### O2 — Upstream contributions
Two are cheap and high-visibility: the 8-line `<dialog>`/morph deadlock fix a maintainer
already wrote and never merged (`14`), and a stimulus-lsp CI linter (~40 lines; `stimulus-parser`
and `@herb-tools/core` both exist, nobody has wired them together) (`13`). Not scheduled.
**Update (`D7`, 2026-08-16):** the turbo#1239 half now ships in crosswire itself, as
`installDialogMorphGuard` (exported from `crosswire/morph`, and wired always-on inside
`cw--dialog`) — a working, in-production patch rather than a proposal, which strengthens
the case for eventually contributing it upstream to Turbo. Still not scheduled.

### O3 — Declarative signals layer
Stimulus has no reactive-state primitive; every derived-UI case is hand-rolled. Datastar shows
the shape and has **no Rails SDK** (`18`). Genuinely novel, genuinely scope creep. Deferred by D1.

---

## D9 — The styled component tier ("hotwire-shadcn")
**Locked 2026-08-16 (Jake).**

A second tier, `Crosswire::UI`, ships **in the core gem**, not a second gem —
purely-presentational components (`button`, `badge`, `card`, `input`, `field`,
`select`, `alert`, `toast`) plus CSS-only styling over four already-shipped
primitive-tier widgets (`dialog`, `popover`, `menu`, `combobox`). Same `D7`
precedent (pagy's extras, the survivability tier): a second gem costs a second
version number, a second install step and a second place accessibility fixes can
drift from, for a tier that shares every mechanism — presenter, `cw.`/`cw_attrs`,
`crosswire:eject` — with the primitive tier it sits beside. Independent
`Crosswire::UI::CONTRACT_VERSION` (not `Crosswire::CONTRACT_VERSION`) is the
reopen-if valve `D7` already established: this tier's markup contract can churn on
its own schedule without forcing a primitive-tier version bump, or vice versa.

**`lib/`, not `app/helpers/`, and NOT autoloaded — two independent, either-alone-
sufficient reasons (`lib/crosswire/engine.rb`'s own docstring carries the full
account):** (1) `contract_audit_test.rb`'s `test_every_presenter_has_a_matching_
controller` globs `lib/crosswire/presenters/` and demands every entry own a
Stimulus controller — UI presenters have none by design (Rule 0), so autoloading
them from that directory would either fail the check or force it to special-case a
subdirectory it has no business knowing about. (2) `UI` is a two-letter acronym;
Zeitwerk's default inflector would expect `lib/crosswire/ui.rb` to define
`Crosswire::Ui`, fixable only with a *global* `Zeitwerk::Inflector` override shared
across the whole host app's autoloader — not a cost a gem should impose on its
host. `lib/crosswire.rb`/`lib/crosswire/builder.rb` requiring `crosswire/ui`
explicitly sidesteps both: a `require`d constant is never a Zeitwerk concern, and
`Crosswire::UI::Component` (the tier's base class) deliberately does NOT subclass
`Crosswire::Presenter` — it owns no Stimulus identifier, so inheriting Presenter's
`controller_attrs`/`target`/`action`/`values` machinery would either go unused on
every UI presenter or force each one to override it away.

**CSS substrate: plain CSS custom properties, not Tailwind, with the Tailwind
mapping explicitly deferred to v1.1.** ~67 tokens (`--cw-<category>-<step>`
globals, `--cw-<component>-<prop>` knobs that default to them), two override
depths, `@layer crosswire.tokens, crosswire.base, crosswire.components` so
unlayered host CSS always wins with zero specificity war. This is the substrate
every consumer gets whether or not they run Tailwind — a components library that
required a specific utility framework to render correctly would be a much bigger
commitment than shipping some CSS variables. `ui/tailwind.css`'s `@theme inline`
mapping (`--color-cw-accent: var(--cw-color-accent)`, etc.) is real, scoped, and
genuinely useful for a Tailwind v4 host wanting `bg-cw-accent` — it is deferred, not
rejected, because it is pure upside layered on top of the token substrate rather
than a decision the substrate itself depends on, and nothing in v1's audits,
registry or gallery needs it to exist yet.

**Both-themes hedge, not a single opinionated palette: neutral `tokens.css` default
plus a swappable `themes/patchbay.css`.** A components library's default palette is
a taste claim as much as an engineering one — shipping a bland, uncontroversial set
of light/dark values as the actual DEFAULT (rather than shipping the site's own
distinctive palette as the only option) keeps the tier usable as a genuine starting
point for someone else's brand, while `themes/patchbay.css` demonstrates the
override mechanism is real by being a real, adversarial (non-default-looking)
worked example rather than a toy. `data-cw-theme` is canonical; `data-theme` is
honoured as a bridge (crosswire wins if both are set) so a host already using that
convention elsewhere doesn't have to invent a second one.

**No screenshot/visual-regression testing, ever — `test/**` §7.4 says so in
writing.** A screenshot assertion trains `--update-snapshots` the moment it starts
failing for the RIGHT reason (an intentional restyle) as readily as the wrong one,
which teaches whoever's running the suite to stop reading failures. Screenshots stay
available as **failure attachments only** (browser-tier tests already capture them
on assertion failure) — useful for a human debugging a real assertion, never
themselves the assertion. The testing pyramid this tier actually runs is presenter
unit (bulk, no Rails) → render integration (child process, real `ActionView`) →
browser-tier SEMANTICS only where one already doesn't exist for the underlying
primitive (`toast` + `field` in v1; dialog/menu/popover/combobox's own browser
suites are not duplicated — styling changed no semantics) → the CSS-specific audits
(`ui_contract_audit_test.rb`'s token-discipline/dark-block/bundle-byte-equality
checks, `token_contrast_test.rb`'s WCAG contrast math) that never need a browser at
all.

**Registry shipped, not marketed as a standard.** `rake ui:registry` emits
`site/registry.json` (shadcn-shaped: `name`/`type`/`description`/`files`/`cssVars`)
from `Crosswire::UI::COMPONENTS`, purely because the shape is a real, useful escape
hatch for tooling (an agent or script that wants machine-readable "what files make
up `button`") and costs nothing extra to generate from data this tier already
tracks by hand for the audit. v1 ships **no remote-fetch command, no stability
promise, no `npx shadcn add crosswire/button`-shaped CLI** — none of that exists
yet, and nothing here claims otherwise. It is infrastructure for a later CLI, not
the CLI.

**The `kind:` marker (spec-driven, Phase 4):** every entry in
`Crosswire::UI::COMPONENTS` defaults to `kind: :new` — this tier's own presenter,
helper, partial and CSS. `dialog`/`popover`/`menu`/`combobox` are `kind: :css`
instead: CSS only, over an ALREADY-SHIPPED, identically-named primitive-tier widget
— no new presenter, no new helper, no new partial, and (deliberately, the whole
point of the entry) a name that DOES collide with `Crosswire::COMPONENTS`, which
`ui_contract_audit_test.rb` check 5 asserts rather than flags. Every one of the ten
audit checks, `rake ui:registry` and `rake morph:doc` branch on `kind_of`/
`css_only?` so both shapes stay meaningfully checked rather than the second shape
silently skipping checks that don't apply to it verbatim.

**Evidence base:** `ui-tier-spec.md` (the executor-ready spec this tier was built
against, phase by phase) and `D6`/`D7`, whose "in-core, not a second gem" and
"independent CONTRACT_VERSION, reopen-if design churn forces annoying minor bumps"
reasoning this decision reuses rather than re-derives.

**Reopen if:** a real Tailwind-only consumer asks for the `@theme` mapping before
v1.1 lands anyway (cheap to pull forward — the file is already speced, just not
written); the neutral default palette turns out to read as nobody's actual brand
and a different default is warranted; or a real "publish this as a public
registry" use case shows up, at which point the remote-fetch/stability-promise
questions v1 explicitly ducked need real answers.
