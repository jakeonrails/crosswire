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
to 38 public APIs before a single consumer exists. Reddit says documentation is the #1
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
| R10 | Naming: `cw--` identifiers, `crosswire_*` helpers, `cw--name:verb` events | 17 |
| R11 | **38-primitive vocabulary**, converged with zero drift across ~95 patterns. No `modal` controller | 08 |

---

## Open

### O1 — View layer: ERB helpers + partials, or ViewComponent / Phlex?
**Status: REOPENED 2026-08-15 by Jake. Under investigation.**

`research/notes/17` recommended plain ERB helpers + overridable partials, on the grounds that
engine views sit on the ActionView lookup path (so a consumer overrides by creating a file)
while ViewComponent globs sidecar templates from its own source directory and therefore
cannot be shadowed.

Jake's challenge: VC/Phlex feel right for a *modern app* — why not for a library? And could
we ship a thin VC or Phlex wrapper gem?

Under evaluation (`research/notes/20-view-layer-reconsidered.md`, in progress):
- Does the VC override claim survive contact with current VC source?
- Is partial-shadowing actually *good*, or is it an unversioned footgun that breaks silently
  on upgrade while subclassing is at least explicit about coupling?
- **The candidate synthesis:** make zero-dependency attribute **presenters** the core
  (`Crosswire::Disclosure#trigger_attrs` / `#panel_attrs`), with thin, logic-free renderers
  — ERB in core, `crosswire-view_component` and `crosswire-phlex` as companions. If the
  renderers contain no logic, the cost of three is small.
- Lookbook: what previews actually cost us without VC.

### O2 — Upstream contributions
Two are cheap and high-visibility: the 8-line `<dialog>`/morph deadlock fix a maintainer
already wrote and never merged (`14`), and a stimulus-lsp CI linter (~40 lines; `stimulus-parser`
and `@herb-tools/core` both exist, nobody has wired them together) (`13`). Not scheduled.

### O3 — Declarative signals layer
Stimulus has no reactive-state primitive; every derived-UI case is hand-rolled. Datastar shows
the shape and has **no Rails SDK** (`18`). Genuinely novel, genuinely scope creep. Deferred by D1.
