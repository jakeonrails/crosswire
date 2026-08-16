# Build log — what building it taught us

`research/` records what we learned *reading*. This records what we learned *building*, and
they fail differently: a research error is a wrong claim, a build error is code that never
ran. Almost everything below was invisible to review and to hundreds of passing unit tests.

The rules these produced live in `docs/COMPONENT_CONTRACT.md`; this is the evidence behind
them, kept because the reasoning is more portable than the rules.

---

## The pattern, stated plainly

**Every bug of consequence was found by executing something for the first time.** Not one
was found by reading code — including code I had written, reviewed, and shipped as the
reference implementation other components were built against.

| What executed for the first time | What it found |
|---|---|
| A Rails app booting the engine | The gem could not boot **at all** under importmap-rails |
| A page rendering a partial | A helper that did not exist; two helpers that raised without a block; `cw_attrs` raising on an empty merge |
| A browser loading the built site | Every `click->` action in the library silently parsed as `lick` |
| A real browser running the tests | Two scroll-lock tests that could not have failed |
| Someone writing tests for `dismiss` | A completion event that no listener could ever receive |
| Lookbook rendering `tabs` | A component that hid all its own content the moment JS booted |

The corollary shaped the project: **a test suite that only exercises pure functions will be
green and worthless.** 177 Ruby tests passed while the engine could not boot.

---

## The bugs

### 1. The engine could not boot under importmap-rails — fatal, shipped, invisible
`initializer "crosswire.importmap", before: "importmap"` → `NoMethodError: undefined method
'draw' for nil`, on first boot in any app using importmap-rails. `app.importmap` is
*assigned by* the `"importmap"` initializer, so running `before:` it guarantees nil.

The guard made it worse. `app.respond_to?(:importmap)` looks defensive but is useless:
importmap-rails installs the accessor with `Rails::Application.send(:attr_accessor,
:importmap)` at **require** time, so it answers `true` long before the map exists.

**Lesson:** `respond_to?` tests for a *method*, not for *initialised state*. When guarding
against boot ordering, test the value.

### 2. `String#sub` deleted a backslash from Stimulus and the entire site went inert
The published page had no working interactions. No exception, no console message. The DOM
attributes were correct, the application started, all six controllers registered under the
right identifiers, the controller connected, both targets resolved, and calling the action
method directly worked.

Ruby's `String#sub` **interprets backreferences in a String replacement** — `\0`–`\9`,
`\&`, `` \` ``, `\'`, `\\`, and `\+`. Stimulus's action-descriptor regex contains `\+`:

```
/^(?:(?:([^.]+?)\+)?(.+?)…
```

`\+` means "the last matched group". Our pattern was a plain string with no groups, so it
expanded to **empty** and deleted the `\+`. The now-optional group swallowed one character
and every `click->` was parsed as event `lick`.

Fix: block form, `.sub(marker) { content }`, which never expands backreferences.

**Lesson:** when a whole system is inert with no error, suspect the layer *below* the one
you are debugging. Also: string interpolation and string replacement are not the same
operation, and Ruby's `sub` is the second one.

### 3. `tabs` hid all its own content the instant JavaScript booted
`Tabs` accepted `selected:`, used it to render `aria-selected` on each tab, and never
emitted `data-cw--tabs-selected-value`. Server-rendered markup was correct. Then the
controller connected, read the `String` type default (`""`), matched no panel, and
`#render()` hid every panel and deselected every tab.

Every unit test passed, because every unit test asserted on the attributes it *did* emit.

**Lesson (now R4, and an audit check):** state that the controller reads must be *rendered*,
not merely *used* during rendering. A presenter that accepts state and doesn't emit it has
broken the single-write-path contract silently.

### 4. A completion event nobody could receive
`dismiss` dispatched `cw--dismiss:dismissed` **after** `target.remove()`. A detached node
has no parent chain, so a `bubbles: true` event never reaches a document-level listener —
and document delegation is the normal way to observe these events. The event was
undeliverable in the default mode, visible only to a listener bound to that exact node.

**Lesson (now R6a):** worse than no event, because it looks like it works.

### 5. Two scroll-lock tests that could not have failed
Both asserted the lock by calling `window.scrollTo()`. Per the CSS Overflow spec,
`overflow: hidden` blocks **user-driven** scrolling and explicitly permits programmatic
`scrollTo`. The assertions would have passed with no lock at all.

Migrating them to real `userEvent.wheel()` gestures also surfaced a leak the false pass was
masking: the file called `application.stop()` before clearing the DOM, so `disconnect()`
never ran and the module-level `lockCount` never released.

**Lesson:** a false-passing test doesn't just fail to catch bugs, it *hides* them.

### 6. `Application#stop()` does not disconnect controllers
It only stops observing future mutations. Our shared `afterEach` stopped the application
before clearing the DOM, so **every R7 teardown assertion in the suite passed vacuously**
for any test that left its element in place.

Fixed by clearing the DOM and awaiting a tick first — the path a real Turbo navigation
takes. Verified with a throwaway probe asserting `disconnect()` actually fires, because
"the tests still pass" is not evidence when the tests were the problem.

Three separate agents hit this independently, two in hand-rolled `Application` instances
inside test bodies — so it is not a property of the shared harness.

### 7. Every `_for` helper double-rendered its block — the documented form was broken
All 28 `_for` helpers did a bare `yield presenter`. The form the README recommends,

```erb
<%= crosswire_disclosure_for id: "faq-1" do |d| %>…<% end %>
```

renders the block **twice**: once as the block writes into ERB's shared output buffer, and
again when `<%=` prints the block's return value — HTML-escaped, as literal visible text on
the page. The fix is Rails' own idiom, `capture(presenter, &block)`.

Found by an agent writing Lookbook previews, which is the only reason it surfaced: no test
had ever rendered a `_for` helper with a block through real ERB. It shipped in the README as
the recommended Layer-2 usage.

**And the first guard I wrote for it was worthless.** It called the helper directly from
Ruby, where a bare `yield` returns the block's value and looks perfectly correct — the
double-render only exists through `<%=` interacting with the buffer. The test passed with
the bug deliberately reintroduced. Rewritten to `render(inline:)` real ERB, then verified
the only way that counts: reintroduce the bug, watch it fail, restore.

**Lesson:** a guard written in a different execution mode than the bug does not guard
anything. Test through the path the user actually takes.

---

## Things the environment lies about

Each of these made a test suite assert something it was not testing.

| Environment | The lie | Consequence |
|---|---|---|
| jsdom | `offsetParent` is **always** `null` (no layout engine) | Visibility filtering and tab order are not merely unreliable, they are **absent**. All real focus-order testing must be browser-tier. |
| jsdom | has **no global `CSS` object at all** — not a `CSS.supports` returning false | An unguarded `CSS.supports(...)` throws. Guard with `typeof CSS !== "undefined" && CSS.supports?.(…)`. |
| jsdom | throws `SyntaxError` on `:modal` (nwsapi) | A controller's own `matches(":modal")` idempotency check always reads false and loops. |
| jsdom + Node 25 | Node's built-in Web Storage global shadows jsdom's, and without `--localstorage-file` has **no methods at all** | Storage tests fail with errors that look like controller bugs. |
| Any browser | Synthetic events have `isTrusted: false` | Native defaults — Escape closing a `<dialog>`, Tab traversal, scrolling — **never fire**. Tests asserting them can never pass. |
| Chromium 151 | *does* support CSS anchor positioning | Tests exercising a JS positioning fallback assert against dead code unless the fallback is forced explicitly. |

---

## Stimulus behaviours that are not in its docs

- **Value callbacks run before `connect()`**, and the initial `previous` argument is the
  type's default (`false`, `0`, `""`) — not `undefined`. The obvious "skip the first call"
  guard silently never fires. (R4a)
- **Key filters are exact-match on modifiers.** `keydown.tab` requires `shiftKey === false`,
  so it silently drops Shift+Tab. Anything needing a modifier combination needs two action
  descriptors. Traced into `Action.keyFilterDissatisfied`. (R8a)
- **The Classes API resolves against the controller's own element**, never a target. A
  `data-*-class` on a target throws at runtime. (R3a)
- **`this.fooClass` throws** when the attribute is absent, with no default mechanism. (R3)
- **Targets are scoped to descendants of the controller element**, so stacked controllers
  with differently-shaped target sets cannot always share one element. The failure is a
  silently empty target set — no error, just a component that does nothing. (R5b)

---

## Things predicted to be bugs that were not

Recorded because negative results stop the next person re-investigating.

- **`config.assets.precompile << …` under Propshaft.** Expected `nil <<`. Propshaft ships a
  compatibility shim (`railtie.rb:78`), so it is a harmless no-op.
- **Presenter namespace pollution.** Adding `lib/crosswire/presenters` to `autoload_paths`
  makes it a Zeitwerk *root*, which by the normal rules would require `disclosure.rb` to
  define a top-level `Disclosure` — colliding with a consumer's own `Dialog` or `Persist`.
  It doesn't, because `lib/crosswire.rb` requires every presenter eagerly, so Zeitwerk sees
  them as shadowed and registers no autoload. **The hazard returns if those eager requires
  are ever dropped**, so it is pinned by a test.
- **Lookbook and helper availability.** `config.lookbook.preview_controller` fixes helper
  inclusion as documented (issue #745) — but there is a second half nobody documents:
  `Lookbook::PreviewController` descends from `Rails::ApplicationController`, whose view
  paths exclude the engine's, so previews raise `MissingTemplate` even with the helper
  included. It needs `append_view_path` too — *append*, not prepend, so a consumer's
  shadowed copy still wins in their own Lookbook.

---

## Process findings

- **Parallel agents drift on shared conventions.** Four agents building components in
  parallel produced three incompatible helper naming schemes. Nothing was wrong
  individually; the *set* was unusable. Conventions need to be machine-checked, not
  documented — `test/crosswire/contract_audit_test.rb` exists because of this.
- **A lint that flags correct usage gets disabled, and then catches nothing.** The first
  version of the contract-marker check flagged the docs that legitimately *describe* the
  marker. Narrowed to a bare marker on its own line.
- **Comments defeat naive static checks.** An early audit flagged `dismiss` for dispatching
  after `remove()` because a *comment* explaining that very hazard mentioned
  `target.remove()`. Strip comments before matching.
- **Verify a guard by breaking the thing it guards.** Every audit check added here was
  confirmed by reverting the fix, watching it fail, and restoring. A check that has never
  failed is not known to work.
- **Agents correct their principals, if asked to.** Two claims stated to the repo owner were
  wrong and caught by an agent that had been told to push back: "210 controllers across 11
  codebases" (it was 10) and Doyle's frame-breakout concern "sitting unread since 2022"
  (`turbo-rails#367` has 49 comments and maintainer engagement — the *design conversation*
  stalled, not readership). Both are corrected in `research/README.md`.
