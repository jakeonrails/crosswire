# Crosswire — synthesis

Written 2026-08-15, from the 18-file / 50k-line research corpus in `research/`.
This is the "what should we build and why" document. It proposes; it does not lock.
Locked decisions go to `docs/DECISIONS.md` once Jake signs off.

---

## 1. The finding that should define the project

Across every independent line of evidence, the same conclusion:

> **The Hotwire ecosystem does not lack knowledge. It lacks packaging and maintenance.**

- **Six** production codebases independently invented the controller+ERB-helper pairing.
  **None** documented it. (`11`, `15`, `17`)
- 37signals copy-paste **14 primitives** between Campfire, Writebook and Fizzy — **three
  byte-for-byte identical** — plus an identical `FormsHelper`. They have a de facto standard
  library and no way to ship it. (`11`)
- A **Turbo maintainer** built APG-faithful accessible widgets (`stimulus_aria_widgets`) and
  **never published them**. His attribute-merge gem and *its* successor are likewise
  unreleased. A pattern of technology demos that never became products. (`19`)
- He also solved **server-driven frame breakout** in 2022 — a problem the community still
  calls open — in a branch nobody read. (`15`)
- Reddit's dominant complaint about Hotwire, by a wide margin, is **documentation** — and the
  loudest complainants are advocates, including a Hotwire course author. (`07b`)

So crosswire's claim is not "we invented this." It is: **we ship it, document it, and keep
it working.** That is both more honest and more defensible.

---

## 2. Positioning

**One line:** *Stimulus is the wiring tier, not the component tier.* (`16`)

**The pitch, evidence-backed:** of 119 catalogued UI patterns, **41 need no JavaScript at
all** and 38 need "tiny." (`08`) The argument is not "Hotwire can replace React" — it is
*two-thirds of what teams reach for React to build needs no JavaScript in 2026, and here is
the catalogue proving it.* That is falsifiable, checkable, and far more persuasive than a
framework comparison.

**What we must not claim** (`README.md` coverage gaps): that Hotwire ships less JS than React
(it is ~35% *larger* at framework level — `12`), or that any named large company has publicly
migrated React→Hotwire with hard numbers (none has).

---

## 3. Settled architecture

These are decided by evidence, not preference. Reopening any of them needs a new fact.

| Decision | Choice | Why | Src |
|---|---|---|---|
| Distribution | **Rails engine gem** | `bundle add crosswire` *is* the product for a "Rails Way" library; the only way to ship controllers + helpers + partials together. Neither big JS library ships a gem at all. | 10, 17 |
| JS packaging | **Unbundled per-controller ESM + bundled fallback** | `stimulus-loading` lazy-registers via `import("${under}/${name}_controller")` — a single bundle **cannot** be lazy-loaded. | 10 |
| Language | **Plain JS, not TypeScript** | TS requires a compile step, which breaks `pin_all_from`. This is exactly why stimulus-components is not importmap-consumable. | 10 |
| View layer | **Context-free presenter core**; ERB helpers + partials in v1; `crosswire-view_component` deferred; no Phlex | ⚠️ **`17`'s reasoning was corrected — see D5 in `DECISIONS.md`.** The override asymmetry belongs to *sidecar templates*, not to ViewComponent: a VC delegating to a core partial inherits app shadowing normally. Presenters must take **no view context** (`17` got this wrong). One presenter drove four renderers to byte-identical HTML. | 17, **20** |
| Attribute merging | **Opt-in `cw_attrs`**, never a `TagBuilder` monkeypatch | Doyle's gem patches ActionView app-wide. For one dependency among many, opt-in is the safer default. Implementation tested, 14 assertions. | 17, 19 |
| Architecture taught | **Three tiers** — Stimulus (wiring) / ES classes (logic) / custom elements (components) | Lexxy: 12,316 lines, **zero Stimulus**, 71% plain classes. Campfire 59%. Decision rule in `16`. | 16 |
| Morph default | **`turbo_stream.replace(target, method: :morph)`**, not page-level morphing | Three independent convergences: Marco Roth's granularity critique, Fizzy's actual usage, the morphing dossier's rubric. Most morph pain is people reaching for page morph when they wanted a morphing stream. | 11, 13, 14 |
| Testing | **Vitest two-tier** (jsdom + browser mode/Playwright) + Minitest/Cuprite | stimulus-components is jsdom-only *and* has the worst a11y in the ecosystem — `aria-expanded` is its only ARIA attribute. The tooling choice caused the failure. | 10 |
| A11y bar | **APG-complete in the controller**, never opt-in consumer wiring | No maintained accessible Hotwire library exists. This is the moat. | 10, 12, 19 |
| Naming | `cw--` identifiers, `crosswire_*` helpers, `cw--name:verb` events | The `__`→`--` dasherization makes namespaced identifiers writable in plain Ruby hash syntax. 37signals use this exact trick. | 17 |

**Rule 0, above all of it:** *can the server do it?* Turbo Frame/Stream, `<dialog>`,
`popover`, `<details>`, CSS. This kills more component candidates than every other rule
combined. (`16`, `08`)

---

## 4. The vocabulary — 39 primitives

Reconciled independently by two agents across ~95 patterns with **zero drift**: every one of
the original 32 was used, no synonyms were invented, no banned name (`toggle`, `modal`,
`dropdown`, `autocomplete`, `lazy-load`, `local-storage`) appeared. A vocabulary that
converges under that much pressure is real, not imposed. Full contracts in `08`.

**Behavior (16)** — `dismiss` · `persist` · `intersection` · `transition` · `focus-trap` ·
`roving-focus` · `hotkey` · `sync` · `timeout` · `scroll-lock` · `interval` · `click-outside` ·
`anchor` · `activate` · `autoscroll` · `cable-channel`

**Widget (6)** — `dialog` · `combobox` · `popover` · `disclosure` · `tabs` · `menu`

**Form (10)** — `autosubmit` · `dirty-form` · `direct-upload` · `char-count` · `nested-form` ·
`drop-zone` · `reveal` · `file-preview` · `input-mask` · `autogrow` *(sunsetting —
`field-sizing: content` is Baseline)*

**Collection (3)** — `sortable` · `selection` · `chart`

**Utility (4)** — `relative-time` · `confirm` · `clipboard` · `countdown`

There is **no `modal` controller.** A modal is `dialog` + `focus-trap` + `scroll-lock` +
`dismiss` + `transition`, each independently useful elsewhere. That is the whole thesis in
one example.

**Deliberately not vocabulary** (documented as conventions): debounce/throttle (mixins),
the wrapped-library teardown contract, Turbo-native attributes, morphing, ARIA live regions,
app singletons. Knowing what is *not* vocabulary is as load-bearing as knowing what is.

**Build order:** the tables in `08` are sorted most-load-bearing first. `dismiss`, `persist`,
`intersection`, `transition`, `focus-trap` and `dialog` carry the most weight.

---

## 5. Recipe taxonomy

Three converging sources: 195 candidates (`07`), 119 pattern records (`08`), ~11 more plus a
whole **Hotwire Native cluster** the others missed (`07b`).

Proposed shape — every recipe is one page, and every page answers the same questions:
**problem → the Hotwire answer → decomposition into primitives → working code → a11y →
native → pitfalls → prior art.**

1. **Foundations** — the frames-vs-streams escalation rule *(the single highest-value recipe;
   nobody has written it down, and it is the root of the "Hotwire is convoluted" complaint)*,
   the form-response contract (303/422), the Rails-6→Hotwire idiom translation table.
2. **Diagnosis** — "nothing happened" (five causes), "Content missing", "my controller
   doesn't connect" (six-point checklist), silent-failure triage. *Reddit says docs are the
   #1 complaint; diagnosis pages are the highest-leverage docs.*
3. **Patterns** — the 119, organised by the `08` sections.
4. **Morphing** — the dossier as a guide: pre-flight checklist, the eight breakages, the rubric.
5. **Sharp edges** — the corrections log as standalone pages. Each is somebody's lost afternoon.
6. **Native** — path config, bridge components, the degradation story.
7. **Escape hatches** — islands done cleanly, and the seven patterns Hotwire genuinely can't do.

---

## 6. Differentiators, ranked by defensibility

1. **Accessibility.** No maintained accessible Hotwire library exists — verified three ways,
   including `gh search repos hotwire aria` returning literally nothing. The one real
   counterexample is abandoned and unpublished. Hardest to copy, most valuable.
2. **The helper layer.** Six codebases do it, none document it, none ship it. Makes generic
   controllers *ergonomic*, which is what makes them survive contact with a real app.
3. **The recipe corpus + corrections log.** Directly attacks Reddit's #1 complaint. Cheapest
   to produce, fastest to deliver value, hardest to keep current.
4. **Morph survival.** turbo#1210 is won't-fix upstream and Stimulus is frozen, so this stays
   broken forever. Two teams independently reinvented the fix; no maintained package exists.
5. **Native degradation.** `shouldLoad` gating means bridge components cost *nothing* on the
   web. Write once, ship both. Reddit's most enthusiastic topic, and it rebuts React's best
   structural argument ("you'll need an API for mobile anyway").

---

## 7. The strategic tension worth naming

Reddit is unambiguous about **why Inertia.js is winning**, and it is not performance or
architecture. Repeated over and over: *you get shadcn and a ready-made component ecosystem.*
**Components.**

And the recurring structural critique of Hotwire, in near-identical words from 2022 to 2026:
*"a frame needs a controller action to support it, so components aren't self-contained."*

Those are the same complaint. A React component is one file you drop in. A Hotwire "component"
is markup + controller + helper + **a route and a controller action you must write yourself**.

**This suggests the boldest available move:** ship components that include their own server
side — an engine route, a controller concern, a `turbo_stream` template — so a consumer mounts
`crosswire` and a combobox *just works* against their model without hand-writing an endpoint.
Nothing in the ecosystem does this. It is also materially more work and more API surface, and
it risks the "too much magic" failure mode Rails libraries die of. See decision D2.

---

## 8. Sequencing options

- **A — Docs first.** Recipes + skills + site. Attacks the #1 complaint, ships fastest, near-zero
  maintenance, no API commitments. Weakest against Inertia.
- **B — Gem first.** Primitives + helpers + a11y. Strongest differentiation, highest maintenance,
  slowest to first value, and every API is a promise.
- **C — Thin gem + docs together.** Ship the ~10 load-bearing primitives with helpers and full
  a11y, and the corrections/diagnosis recipes alongside. Defer widgets, native, and server-side
  components until the shape is proven.

**Recommendation: C.** The corrections log and diagnosis pages are already 90% written *inside
the research corpus* — they are nearly free. And ten primitives with real a11y is enough to
prove the thesis without committing to 39 public APIs before we have a single consumer.

---

## 9. Open decisions (need Jake)

- **D1 — Sequencing.** A, B, or C.
- **D2 — Component ambition.** Client-side primitives only, or components that ship their own
  server endpoints (§7)? This changes the architecture, not just the roadmap.
- **D3 — Native in v1?** Cheap to *design for* (`shouldLoad` costs nothing on web), expensive to
  *test* (needs Xcode/Android toolchains).
- **D4 — Upstream contributions.** Two are cheap and high-visibility: the 8-line `<dialog>`/morph
  fix a maintainer already wrote and never merged (`14`), and a stimulus-lsp CI linter (~40 lines;
  both halves exist, neither is wired together) (`13`).
- **D5 — Signals layer.** Stimulus has no declarative reactive-state primitive; every derived-UI
  case is hand-rolled. Datastar shows the shape and has **no Rails SDK**. Genuinely novel, genuinely
  scope creep. (`12`, `18`)
- **D6 — Books.** Master Hotwire (€49) and Masilotti (~$31) are the text purchases worth making.

---

## 10. Risks

1. **Maintenance is the whole product.** Every predecessor failed here, not at design. If
   crosswire ships and stalls, it becomes the seventh undocumented demo.
2. **No upstream help.** Stimulus has not released in 3 years; a merged memory-leak fix is still
   unreleased. Everything we depend on staying broken, stays broken.
3. **The a11y bar is a promise.** Claiming APG-complete and shipping a combobox without type-ahead
   is worse than not claiming it. `19` shows exactly how a maintainer's own library fell short.
4. **The three-tier rule is our synthesis, not consensus** — one GitHub thread in Stimulus's
   entire history. Ship it with its evidence attached.
5. **Corpus decay.** Turbo moves; ~30 corrections were needed against *current* published advice.
   Our corrections log will itself need correcting.
