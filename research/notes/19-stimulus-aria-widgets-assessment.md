# 19 — Assessment: `seanpdoyle/stimulus_aria_widgets`

> **Question this document answers.** A fourth agent surfaced
> `seanpdoyle/stimulus_aria_widgets` as a possible counterexample to the sibling-agent
> finding "no accessible/headless Hotwire component library exists." This is a rigorous,
> source-level assessment of that gem — read in full, cloned and read line-by-line, checked
> against the real WAI-ARIA APG keyboard specs — plus a scan of Sean Doyle's other repos for
> anything similarly relevant.

---

## 1. The facts

| | |
|---|---|
| Repo | [`seanpdoyle/stimulus_aria_widgets`](https://github.com/seanpdoyle/stimulus_aria_widgets) |
| Author | Sean Doyle (Turbo/Rails contributor, prolific OSS author) |
| Created | 2021-07-31 |
| Last push | 2023-12-19 (**~2 years, 8 months stale** as of 2026-08-15) |
| Stars | 17 |
| License | MIT |
| RubyGems | **Not published.** `gem 'stimulus_aria_widgets', github: 'seanpdoyle/stimulus_aria_widgets', branch: 'main'` — git-dependency only, forever |
| npm | **Not published.** Installed by pointing Yarn/importmap at the GitHub repo directly |
| Version | `0.1.0` (`lib/stimulus_aria_widgets/version.rb`), never bumped |
| CHANGELOG | Never left `## [Unreleased]` — no tagged release ever cut |
| Open issues | 2: `#11` "Carousel component" (unaddressed feature request, ~2022–23), `#13` "Revert CI check" (open, unmerged) |
| Merged PRs | 10, all from Sean himself, last merged 2023-12-19 (a README update) |
| README | Real usage docs per pattern, but "## Contributing / Contribution directions go here" is literal unfinished boilerplate |
| Tests | 599 lines, 6 real **Capybara + Selenium system tests** (one per pattern) driving actual keyboard events (`send_keys :arrow_down`, `:home`, `:end`, `:escape`, `:tab`), plus 1 unit test and 1 integration test. Genuinely good rigor for the scale of the project. |
| CI | GitHub Actions matrix: Ruby 2.7/3.0/3.1 × Rails 6.1/7.0/main. **Predates Turbo 8** (released Feb 2024) and predates Rails 7.1+/8. |
| JS runtime dep | `"stimulus": "^3.0.0"` in `package.json` — the **old, pre-rename npm package name**, not `@hotwired/stimulus`. Confirms the project stopped evolving before the ecosystem's naming/tooling conventions solidified. |
| Patterns implemented | 6: Combobox, Disclosure, Dialog (modal), Feed, Tabs, Grid |
| Companion gem | [`seanpdoyle/attributes_and_token_lists`](https://github.com/seanpdoyle/attributes_and_token_lists) (28 stars, last push 2023-02-02) — also unreleased to RubyGems, git-dependency only. Superseded by a newer, still-unreleased repo, [`seanpdoyle/action_view-attributes`](https://github.com/seanpdoyle/action_view-attributes) (37 stars, last push 2024-10-24). |

**Bottom line on maturity:** every load-bearing piece of this stack — the widgets gem, its
attribute-merge dependency, and that dependency's successor — has been built as a **public
technology demonstration and never shipped as a real release**. No gem gets a `0.2.0`. None
is on RubyGems. All three have gone dark for at least 20 months. This is a hobbyist's
proof-of-concept trilogy, not a maintained library.

---

## 2. Per-pattern coverage vs. the real APG keyboard specs

Checked against https://www.w3.org/WAI/ARIA/apg/patterns/ for each pattern, source read at
`src/*_controller.ts` + the paired `lib/stimulus_aria_widgets/*_controller.rb` DSL.

### Disclosure — essentially complete
`src/disclosure_controller.ts`. Generically toggles `aria-expanded` on the trigger and,
via `controlsElement` (looked up from `aria-controls`), drives whichever of three states the
controlled element supports: a CSS class (`classes "expanded"`), native `<details>`/`<dialog>`
`.open`, or `[hidden]`. Two-way sync via `MutationObserver` (state pushed from the trigger,
pulled back if the controlled element changes out-of-band — e.g. `<details>` toggled by
mouse click on `<summary>` natively). Disclosure's own APG keyboard model is trivial (Enter/
Space on a native `<button>`, which the browser gives for free), so there's nothing more to
implement. **This is the strongest piece in the library** — small, generic, and correctly
handles a state-source ambiguity most implementations hardcode around.

### Dialog (Modal) — strong, but only because it stands on native `<dialog>`
`src/dialog_controller.ts`. Uses `HTMLDialogElement.showModal()` directly rather than
hand-rolling a focus trap. On open (line 34–46): records `previouslyActiveElement`, calls
`showModal()`, sets `inert` on every sibling of the dialog (line 64, belt-and-suspenders
alongside the browser's own top-layer semantics), focuses the first `[autofocus]` element or
else the first element with `tabIndex > -1` (line 119–128), and auto-derives `aria-label`/
`aria-labelledby` from the first heading if the caller didn't supply one (line 96–109). On
close: restores focus to `previouslyActiveElement` if still connected (line 72–73), releases
`inert`. `role="dialog"` and `aria-modal="true"` set at `connect()`.
**Gap:** it never explicitly binds Escape — it relies entirely on the native `<dialog>`
behavior for that, which is correct *only* as long as the consumer actually renders a real
`<dialog>` (the `tag_name "dialog"` default in the Ruby side, line-verified in
`lib/stimulus_aria_widgets/dialog_controller.rb`). No fallback path exists for a
non-`<dialog>`-based modal. Given native `<dialog>` focus-trap/Escape support is now
universal (it was not, reliably, in 2023 when this was written — hence the `wicg-inert` /
`dialog-polyfill` dependencies in the README), this design has actually aged *well*.

### Tabs — strong, close to complete
`src/tabs_controller.ts`. Respects `aria-orientation` to switch Left/Right vs. Up/Down (line
45–47), Home/End jump to first/last tab with wraparound (line 68–79), roving tabindex via
`#isolateTabindex` triggered on focus (line 30–32, 136–144), and a manual-activation mode
(`deferSelectionValue`, line 87–89) matching APG's "automatic vs. manual activation" variance
point. Also handles dynamic add/remove of tab/tabpanel pairs via
`tabTargetConnected`/`Disconnected` lifecycle callbacks (line 12–28) — more thorough than
most third-party implementations. No gaps against the spec worth flagging.

### Grid — genuinely non-trivial, mostly complete
`src/grid_controller.ts`. Implements roving tabindex seeded from `columnValue`/`rowValue`
Stimulus values (line 20–30), `captureFocus` re-derives those values and re-applies
`tabindex` on every focus event (line 32–51, correct pattern for grids whose cells can be
focused by mouse too), `moveColumn`/`moveRow` handle arrow keys via a data-driven `directions`
param (`{"ArrowRight":1,"ArrowLeft":-1}` etc., set in the Ruby DSL) plus `Home`/`End`
boundaries with `ctrlKey` distinguishing "start/end of row" from "start/end of grid" (line
53–84) — this is the Grid pattern's hardest interaction to get right and it's handled
correctly. **Gaps:** no `PageUp`/`PageDown` for column jumps (only implemented for rows), and
no type-ahead — both optional per spec but commonly expected in a full-featured grid.
Still, this is the most technically impressive controller in the set; most third-party
"Hotwire component" libraries skip grid navigation entirely.

### Combobox — real, but has one concrete correctness gap
`src/combobox_controller.ts`. `ArrowUp`/`ArrowDown` with wraparound, `Home`/`End`, `Enter`
(clicks the active option), `Escape` (collapses), `aria-activedescendant` maintained on the
combobox input as the active option changes (line 39–87), `aria-selected` toggled on options,
listbox visibility driven by a `MutationObserver` watching `aria-expanded` rather than direct
manipulation (line 16, 90–96 — a nice decoupling). Options get `tabindex="-1"` to stay out of
tab order (verified by its own system test, "omits options from tab order").
**Concrete gap, confirmed by reading the Ruby helper** (`lib/stimulus_aria_widgets/combobox_controller.rb`
line 8): the combobox target sets `autocomplete: "off"` — the **native HTML** autocomplete
attribute (suppresses browser autofill) — but never sets **`aria-autocomplete`**, which is
the APG-required attribute that tells assistive tech whether the combobox does list-filtering,
inline completion, or both. This is a real, spec-relevant omission, not a style nit. Also
missing: no type-ahead beyond the app-level input filtering the demo relies on, and no
`Alt+Down`-opens-without-selecting variant.

### Feed — a simplified approximation, not a strict implementation
`src/feed_controller.ts`. `PageUp`/`PageDown` move focus directly between `[role=article]`
elements (line 36–49), `Ctrl+Home`/`Ctrl+End` jump to first/last article, `aria-posinset`/
`aria-setsize` maintained as articles connect/disconnect (line 60–66). The strict APG Feed
spec requires a two-step `PageDown` (first press moves focus to the article container if
focus is inside article content, second press moves to the next article) and requires
`Ctrl+End`/`Ctrl+Home` to move focus to the first focusable element **outside** the feed, not
to the first/last article. This implementation does neither — it's a common, defensible
simplification, but it is not APG-complete as written, unlike Tabs/Disclosure/Dialog.

**Overall pattern-coverage verdict:** 3 of 6 (Disclosure, Dialog, Tabs) are essentially
complete against the spec. Grid is strong with minor gaps. Combobox has one real correctness
bug (`aria-autocomplete` never set) plus missing type-ahead. Feed is a working
simplification, not spec-faithful. No pattern implements type-ahead character search anywhere
in the library.

---

## 3. The helper-pairing design — compared to `Crosswire::Attributes.merge` (§6)

Read `lib/stimulus_aria_widgets/builder.rb`, `lib/stimulus/controller.rb`,
`lib/stimulus/target.rb`, `lib/stimulus/delegator_with_closure.rb`, and the actual merge
primitive in the companion gem, `attributes_and_token_lists/lib/action_view/attributes.rb`
and `.../lib/action_view/helpers/tag_helper/tag_builder.rb`.

### The architecture

A view helper (`aria`, configurable) returns a `Builder` (`Struct` with one method per
pattern: `.disclosure`, `.combobox`, …). Each pattern is declared with a small class-level
DSL:

```ruby
# lib/stimulus_aria_widgets/tabs_controller.rb
class TabsController < Stimulus::Controller
  values "defer_selection"

  target "tablist", role: "tablist", data: { action: "keydown->tabs#navigate" }
  target "tab", role: "tab", data: { action: "focus->tabs#isolateFocus click->tabs#select" }
  target "tabpanel", role: "tabpanel"
end
```

`Stimulus::Controller.target(name, **attrs, &block)` (`lib/stimulus/target.rb`)
metaprograms a `#{name}_target` method that returns a `Stimulus::Target` — a `Hash`-like
object exposing `.attributes`, `.tag(*args, &block)`, `.to_s`. This is genuinely the same
shape as crosswire's proposed Layer 0/1 split (§4.2–4.3 of `17-helper-layer-design.md`): a
declarative name→attributes mapping, splattable or renderable directly.

### The merge primitive itself — convergent with §6, but structurally different

Both crosswire's `Crosswire::Attributes.merge` and Sean Doyle's system solve the identical,
correctly-identified gap: **Rails has no merge-don't-clobber facility for `data:`/`aria:`/
`class:`, and arrays inside `data:` silently JSON-encode instead of space-joining.** Both
land on "a `Hash`-like object that knows which of its keys are token lists and unions those,
last-writer-wins on everything else, and knows how to serialize itself via `tag_options`."
That's strong independent validation of crosswire's §6 design.

But the *mechanism* differs in a way worth calling out explicitly:

| | crosswire `Crosswire::Attributes.merge` | Sean Doyle `ActionView::Attributes` |
|---|---|---|
| Installed as | An opt-in module (`cw_attrs(...)`) — plain Ruby, touches nothing else | **Monkeypatches `ActionView::Helpers::TagHelper::TagBuilder#attributes` itself** (`lib/action_view/helpers/tag_helper/tag_builder.rb:57`), so *every* `tag.attributes` call in the whole consuming app, crosswire-related or not, starts returning a mergeable object instead of a plain string |
| Which keys are token lists | Fixed, small, hardcoded set: `class`, `data-controller`, `data-action` (`TOKEN_ATTRS`/`TOKEN_DATA_ATTRS` in §6) | A single **global mutable registry**, `ActionView::Attributes.token_lists` (a `cattr_accessor`, defaulting empty), populated by config (`config.action_view.token_lists << "data-action"` / `<< /data-(.*)-target/`). Supports regex patterns, so e.g. every `data-*-target` attribute can be declared a token list in one line — more expressive than crosswire's fixed list |
| Escape hatch for "don't merge, just replace this once" | An explicit `nil` on a key **deletes** it; there's no way to say "merge everything except force-replace `class` this one call" | A per-call `key!` suffix (`class!:`) forces override instead of merge for exactly that key, and doesn't persist as a real attribute name — a genuinely useful piece of surface API crosswire's design doesn't have an equivalent for |
| Merge direction | Last-writer-wins for scalars (**consumer wins** over defaults) | Same — right-hand side wins in `merge!` (`values, &merge_conflicts`), consumer wins |
| Where it plugs into `tag` | Explicit: `tag.div(**cw_attrs(...))` | Implicit and ambient: `tag.attributes(...)` *is* the merge-aware object everywhere, so `tag.with_options(tag.attributes(a, b))` composes for free |

**Assessment: neither is strictly better; they trade different risks.** Sean Doyle's
monkeypatch approach is more elegant *inside a single application* — it makes the vanilla
Rails primitive itself merge-aware, so there's no new vocabulary to learn (`tag.attributes`
just works better) and the regex-configurable token-list registry is more flexible than
crosswire's hardcoded three keys. But it's a global, load-order-dependent core-class
patch — two unrelated gems that both call `config.action_view.token_lists <<` are now
coupled through Rails' own `ActionView::Helpers::TagHelper::TagBuilder`, and any code in a
consuming app that already relies on `tag.attributes` returning a *plain string* (per Rails'
actual, documented behavior — `tag_options(attributes.to_h).to_s.strip.html_safe`) will
observe a different return type after installing this gem. **For a library that wants to be
one dependency among many in someone else's app**, crosswire's opt-in, namespaced,
non-monkeypatching `cw_attrs` is the safer default — this is a legitimate point in
crosswire's favor, discovered by reading Sean Doyle's actual implementation rather than
assumed. The one thing worth stealing outright is the `key!` override-escape-hatch — it is a
real API gap in crosswire's current §6 design (nil-deletes covers "remove," nothing covers
"replace instead of merge, just this once, without deleting the default entirely").

### The controller/helper coupling risk (not solved by either project)

`Stimulus::Controller.target` declares targets, actions, and params in Ruby; the actual
Stimulus controller (`static targets = [...]`) is a hand-written, independent TypeScript
file. **Nothing enforces these stay in sync** — a target renamed in `tabs_controller.rb`
without the matching rename in `tabs_controller.ts` fails silently at runtime (Stimulus just
never finds the target). This is the same problem crosswire's own design will face at
~30-controller scale, and Sean Doyle's project doesn't solve it either — worth noting in
crosswire's own open questions rather than assuming it's solved territory.

---

## 4. Other repos scanned for relevant prior art

Ran `gh repo list seanpdoyle --limit 200` (160 repos, many are stale forks of Rails/Ruby core
libraries with 0 stars — excluded below) and checked every repo whose name/description
touched ARIA, Stimulus, Hotwire, accessibility, or "component":

| Repo | Stars | Last push | Assessment |
|---|---|---|---|
| `attributes_and_token_lists` | 28 | 2023-02 | The dependency `stimulus_aria_widgets` requires; see §3. Unreleased. |
| `action_view-attributes` | 37 | 2024-10 | **Successor** to `attributes_and_token_lists` — same monkeypatch idea, cleaner README, still unreleased to RubyGems, still git-only. Confirms this is an idea he kept returning to over ~3 years but never packaged. |
| `constraint_validations` | 37 | 2026-01 (recent) | Integrates `ActiveModel::Validations` with the browser's native HTML5 Constraint Validation API. Not a component library, but adjacent — worth a separate look if crosswire ever does form-validation UX, not relevant to the ARIA-widgets question. |
| `turbo_stream_button` | 51 (his highest-starred) | 2026-08 (active) | Declares click handlers as Turbo Stream mutations. Not accessibility-related. His most actively maintained repo currently — evidence he's still shipping, just not in this space. |
| `view_partial_form_builder` | 33 | 2024-10 | **The only one of these actually published on RubyGems** (20k+ downloads, v0.2.2). Form-builder-as-partials, not ARIA/component-widget related, but shows he *can* and does ship real gems when he chooses to — makes the non-release of `stimulus_aria_widgets` a deliberate/status-quo choice, not an oversight. |
| `styled_helpers` | 14 | 2024-10 | No description; unreleased. Given the name and era, likely another `tag.attributes`-adjacent styling helper experiment. Not independently verified in depth — lower priority than the above. |
| `capybara_accessible_selectors` (fork) | 0, fork | 2025-11 | **Not his own project** — a fork of `citizensadvice/capybara_accessible_selectors`, a real, actively maintained a11y-focused Capybara testing library from the UK charity Citizens Advice. It's what `stimulus_aria_widgets`' system tests use for `:combo_box`/`:list_box_option` selectors. Worth knowing about independently as **test tooling**, not as a component library — different category of prior art than what the siblings were checking for. |

No other repo in the list implements Stimulus controllers paired with ARIA-widget
server-side helpers. `stimulus_aria_widgets` is Sean Doyle's only project in this specific
category.

---

## Verdict

**Does this invalidate "no accessible Hotwire component library exists"? Partially, and the
distinction matters.**

- The narrow claim the siblings were actually testing — *"has anyone shipped a maintained,
  adoptable, accessible Hotwire component library"* — **still holds**. Nothing here is
  published, versioned, or maintained. `stimulus_aria_widgets` has been dark for 2 years 8
  months, its dependency chain (`attributes_and_token_lists` → `action_view-attributes`) has
  been dark for 20+ months, none of the three is on RubyGems, and the README's Contributing
  section is literally unwritten. An app could not sanely add this as a production
  dependency today.
- The broader claim the siblings' evidence was actually being used to support — *"nobody has
  demonstrated that the paired server-helper + client-controller convention can produce
  APG-faithful, keyboard-correct, well-tested accessible widgets in Hotwire"* — **is false**,
  and was false before crosswire's research began. Sean Doyle demonstrated exactly that,
  including real keyboard-driven system tests, for 6 patterns, with a genuinely convergent
  independent solution to the same attribute-merge problem crosswire's §6 solves. The
  sibling agents' grep-based evidence (`tailwindcss-stimulus-components` has no `focus`/
  `Escape`/`inert`; the 32 `stimulus-components` packages have only `aria-expanded`) was
  accurate about the libraries they checked — this project was simply not in that sweep,
  and it directly contradicts the implied "nobody has tried" framing.

**Maturity: abandoned proof-of-concept.** Technically competent, not production software. Real
tests, real (if occasionally simplified or gapped) ARIA-spec coverage, zero packaging or
maintenance discipline, zero community, two stale open issues, no release ever cut.

**Recommendation: (c) learn from it and build separately**, with a dose of (d) — treat it as
prior art with a materially different and narrower scope, not a competitor.

- **Do not adopt/depend on it (a).** An unreleased, 2.7-year-dormant, single-maintainer git
  dependency with a known correctness gap (`aria-autocomplete`) and a hard version-matrix
  ceiling (Ruby ≤3.1, Rails ≤7.0/main-as-of-2023, pre-Turbo-8) is not something to build a
  gem on top of. It would have to be forked and actively maintained by crosswire anyway, at
  which point it's not really "adopting" it.
- **Do not contribute to it instead of competing (b).** There is no evidence of an active
  maintainer relationship to join — no commits, no issue responses, no PR reviews in ~2.7
  years. It also isn't shaped like crosswire: it's 6 ARIA *interaction* controllers with zero
  view/CSS override story, zero theming, zero ejection path, zero component types outside
  strict APG widgets. Contributing "the rest of crosswire" into this repo would mean
  building crosswire inside somebody else's dormant side project.
- **Do (c): learn from it, build separately.** Three concrete things worth taking:
  1. The `Attributes`-as-mergeable-`Hash` design independently validates crosswire's §6
     `Crosswire::Attributes.merge`. Steal the `key!` override-escape-hatch specifically —
     it's a real gap in the current crosswire design (nil deletes; nothing lets a caller say
     "replace, don't union, just this once").
  2. The Dialog controller's native-`<dialog>` + `inert`-on-siblings + focus-restore
     implementation (`src/dialog_controller.ts`) is close to reference-quality and worth
     reading again when crosswire designs its own Dialog component.
  3. Its Grid controller (`src/grid_controller.ts`) is a rare example of someone actually
     implementing the hard roving-tabindex-plus-directional-navigation Grid interaction
     correctly in a Stimulus controller — worth studying even though crosswire will still
     need to write its own.
  Also worth *not* reproducing: the missing `aria-autocomplete` on Combobox, the simplified
  (non-spec-faithful) Feed keyboard model, and the total absence of type-ahead anywhere —
  name these explicitly as things crosswire's own pattern coverage should get right where
  this project didn't.

**What crosswire still uniquely offers, if this exists:**

- **Breadth.** 6 APG patterns here vs. crosswire's ~30-component ambition (only some of
  which are strict APG widgets — copy-to-clipboard, sortable lists, transitions, etc. have
  no APG pattern to implement in the first place).
- **The whole view/override/theming layer.** This project has no partial-override story, no
  CSS Classes API strategy, no "ejection" path, no `customize_*` surface, no Layer-2/Layer-3
  convenience helpers — it's entirely Layer 0/1 (attributes + controller pairing) by the
  taxonomy in `17-helper-layer-design.md` §4.1. Everything in that document's §7 (theming)
  and §8 (customization & ejection) is still crosswire's unique territory.
  - **A safer default merge mechanism for a dependency.** Crosswire's opt-in
  `cw_attrs`/`Crosswire::Attributes.merge`, which touches nothing outside itself, is a more
  conservative and arguably more appropriate design than monkeypatching
  `ActionView::Helpers::TagHelper::TagBuilder` app-wide — a real, substantiated point in
  crosswire's favor rather than an assumed one.
- **Being maintained at all.** Shipping something people can install, pin a version of, and
  trust to keep working past a Turbo/Rails major bump is not a solved problem here — it's an
  open opportunity crosswire can still claim outright.
