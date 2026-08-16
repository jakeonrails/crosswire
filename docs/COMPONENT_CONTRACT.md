# Component contract

Every crosswire primitive follows this shape. It is not style guidance — most of these
rules exist because breaking them produces a specific, documented bug. The research file
each rule comes from is cited so you can read the evidence.

Reference implementations: **`disclosure`** (widget with markup) and **`dismiss`**
(behaviour, no markup). Read both before writing a new one.

---

## Files per component

| File | Required? | Purpose |
|---|---|---|
| `lib/crosswire/presenters/<name>.rb` | **always** | attribute contract + a11y. Pure PORO. |
| `app/assets/javascripts/crosswire/controllers/<name>_controller.js` | **always** | behaviour |
| `app/helpers/crosswire/<name>_helper.rb` | **always** | `crosswire_<name>` + `crosswire_<name>_for` |
| `app/views/crosswire/_<name>.html.erb` | only if it owns markup | ejectable default markup |
| `test/crosswire/presenters/<name>_test.rb` | **always** | plain Minitest, no Rails |
| `test/js/<name>_controller.test.js` | **always** | Vitest |

Behaviours that decorate existing elements (`persist`, `intersection`, `transition`,
`focus-trap`, `clipboard`, `autosubmit`) ship **no partial** — they have no markup of
their own. Widgets that own markup (`dialog`, `confirm`) ship one.

---

## The rules

### R1 — Presenters take no view context
Pure POROs returning plain hashes. No `view`, no `tag`, no `link_to`. The test suite must
not boot Rails; `test/test_helper.rb` enforces this and one test asserts it explicitly.
*Why: it makes every renderer a thin wrapper, keeps the library unit-testable, and is what
lets a consumer drop to raw markup. (D5, notes/17)*

### R2 — Accessibility lives in the presenter, never in the partial
Every `role`, `aria-*`, `id` relationship, `tabindex` and `type="button"` is emitted by a
presenter method. The partial only places them.
*Why: an ejected or restyled partial must stay accessible. This is what makes crosswire's
copy/paste story better than shadcn's. (D6)*

### R3 — Never read `this.fooClass` without `hasFooClass`
Stimulus **throws** when a class attribute is absent and has no default mechanism.
*Why: the single most likely way a component breaks for a consumer who did not pass a
class. (notes/17)*

### R3a — `data-*-class` attributes belong on the controller element, never on a target
Stimulus's Classes API resolves `data-<identifier>-<name>-class` against the **controller's
own element**, never against a target. So even when the controller applies the class to a
target visually, the attribute must be emitted by the presenter's `root_attrs`.

*Why: put it on the target and `this.fooClass` throws `Missing attribute` at runtime — the
R3 failure, arrived at from the other direction. Caught during the `clipboard` build by
modelling it on `disclosure`'s `open_class` (which applies to the root, so the distinction
never came up) and writing a test to pin it down.*

### R4 — State lives in a value, the server renders it, and there is one write path
The action handler sets the value; `<name>ValueChanged` does the DOM work. Never both.
*Why: a server-driven change, a Turbo morph and a click then converge on one code path.
Turbo 8 morphing overwrites `data-*-value` and skips `connect()` — turbo#1210, closed
won't-fix — so any other arrangement silently desynchronises. (notes/03, notes/14)*

### R4a — Guard event dispatch with a `#ready` flag, not `previous === undefined`
Stimulus runs value callbacks **before** `connect()`, and for a typed value the initial
`previous` argument is the type's default (`false`, `0`, `""`) — **not** `undefined`. So the
obvious guard silently never fires and every connect announces a phantom event.

```js
#ready = false
connect()    { this.#render(); this.#ready = true }
disconnect() { this.#ready = false }
openValueChanged(value) { this.#render(); if (!this.#ready) return; this.dispatch(…) }
```

*Why: Turbo reconnects controllers on every frame render, stream render and cache restore,
so one bogus event per connect becomes a steady drip of phantom state changes for anything
listening. Found by a failing test in `disclosure`, not by reading the docs.*

### R5 — Compose with events, never outlets
Emit namespaced events (`cw--<name>:<past-tense-verb>`). Never declare a Stimulus outlet.
*Why: an outlet hardcodes another controller's identifier, which a distributable component
cannot know. Verified: across stimulus-components (32), tailwindcss-stimulus-components (10)
and stimulus-use (19), **not one** uses outlets. (notes/03)*

### R5a — Stacking controllers on one element: values to drive, events to react, never a cross-controller method call
When one primitive composes with another (`data-controller="cw--dialog cw--confirm"`),
three different situations come up, and each has exactly one right mechanism:

1. **A real DOM event already backs the moment** (a button click, say). Bind both
   controllers' actions to that one event: `data-action="click->cw--confirm#confirm
   click->cw--dialog#close"`. Ordinary Stimulus, no plumbing — Stimulus runs both
   listeners, in the order they appear in the attribute.
2. **No DOM event backs the moment** (a public method called programmatically, e.g.
   `confirm.open(...)` from `Turbo.config.forms.confirm`). Write the other
   controller's own value attribute directly —
   `this.element.setAttribute("data-cw--dialog-open-value", "true")`. This is not a
   workaround; it is the exact external-write path R4 already guarantees works (a
   Turbo morph or a server-rendered value takes the identical path) — invoked by a
   sibling controller instead of by Turbo.
3. **Reacting to the other controller's state changes.** Listen for its
   already-namespaced events with the presenter's `action()` pass-through — a spec
   containing `#` is not auto-prefixed, so `action("cw--dialog:closed->closed")`
   expands to `cw--dialog:closed->cw--confirm#closed` and wires straight to your own
   method.

**Never** reach for `application.getControllerForElementAndIdentifier` to call a
method on a sibling *stacked* controller — that reintroduces the exact coupling R5
bans an outlet for, just spelled with a different API. (That call is still the right
tool for external app-integration code reaching INTO a crosswire controller — see the
`Turbo.config.forms.confirm` wiring in the `confirm` presenter's docstring — the
constraint is only on crosswire's own controllers composing with each other.)

*Why: worked out building `confirm` on top of `dialog`. `confirm` has no DOM event to
hang an "open the dialog" action off (it's invoked programmatically or from a trigger
element that isn't even in `dialog`'s scope), so #2 was necessary; the Confirm/Cancel
buttons DO have one, so #1 was both available and simpler than inventing a synthetic
event for something a plain multi-action `data-action` already does.*

### R6 — Make destructive events cancelable
Anything that removes, closes, or replaces DOM dispatches a cancelable event first and
passes a `complete()` callback in `detail`.
*Why: `Node.remove()` is synchronous — once it runs there is nothing left to animate. This
is a spec-level limit that `@starting-style` cannot fix. (notes/18)*

### R6a — Dispatch completion events while the node is still attached
Emit `:dismissed` / `:removed` / `:closed` **before** `target.remove()`, not after.

*Why: once a node is detached there is no parent chain, so a `bubbles: true` event
dispatched on it never reaches a `document`-level listener. Document delegation is the
ordinary way to observe crosswire events — it is how the test harness's own
`captureEvents` works — so a completion event dispatched after removal is effectively
undeliverable, visible only to a listener bound to that exact node reference. Worse than
having no event, because it looks like it works. Shipped in `dismiss` as an exemplar and
survived review; only caught when someone wrote tests for it.*

### R7 — Exhaustive teardown in `disconnect()`
Unbind listeners, call the library's `destroy()`, null references, release object URLs,
timers and observers. Keep stable handler references so they can be removed.
*Why: Turbo's snapshot cache turns every missed teardown into a per-visit leak. This is the
number-one bug in Stimulus library wrappers. (notes/08)*

### R8 — Guard focus before detaching a node
If the element about to be removed contains `document.activeElement`, move focus somewhere
sensible first.
*Why: screen-reader focus otherwise falls back to `<body>` and the user loses their place.
Turbo announces nothing on navigation and moves focus only for `[autofocus]` — turbo#774,
open for years, with defaults explicitly rejected. (notes/10)*

### R8a — A key filter with a modifier needs its own action descriptor
Stimulus key filters are **exact-match on modifier state**. `keydown.tab->x#cycle`
requires `shiftKey === false`, so it **silently drops Shift+Tab**. Wire both and read
`event.shiftKey` to pick direction:

```ruby
action("keydown.tab->cycle", "keydown.shift+tab->cycle")
```

*Why: traced into `Action.keyFilterDissatisfied` in Stimulus's own dist while building
`focus-trap`, where it meant backwards tabbing simply did not work, with no error. Single
filters with no modifier variant (`keydown.esc` in `dismiss`) are unaffected; anything
needing Shift/Ctrl/Alt/Meta needs the two-descriptor treatment.*

### R9 — Rule 0 goes in the docstring
If a platform feature does most of the job, say so at the top of the presenter and say when
to use the controller instead. `<details>` over `disclosure`, `<dialog>` over a hand-rolled
modal, `popover` over JS positioning, `field-sizing: content` over autogrow.
*Why: 41 of 119 catalogued patterns need no JavaScript. A component library that does not
say so is selling you something. (notes/08, notes/16)*

### R10 — Every shipped partial carries a contract marker
First line: `<%# crosswire:contract v1 %>`. `ShadowCheck` reads it at boot.
*Why: it is the upgrade signal that plain copy/paste has no answer to. (D6)*

---

## Naming

| Thing | Convention | Example |
|---|---|---|
| Stimulus identifier | `cw--<kebab>` | `cw--focus-trap` |
| Presenter | `Crosswire::Presenters::<CamelCase>` | `Crosswire::Presenters::FocusTrap` |
| Helper | `crosswire_<name>` / `crosswire_<name>_for` | `crosswire_dialog` |
| Partial | `app/views/crosswire/_<name>.html.erb` | overridable by path |
| Target | `camelCase` **noun** | `data-cw--dialog-target="panel"` |
| Action method | `camelCase` **verb** | `#toggle`, `#dismiss` |
| Value | `kebab-case`, **adjective or noun** | `data-cw--disclosure-open-value` |
| Class | `kebab-case` | `data-cw--disclosure-open-class` |
| Event | `cw--<name>:<past participle>` | `cw--dismiss:dismissed` |
| CSS | `cw-<name>__<part>--<state>` | `.cw-disclosure__panel` |
| Custom property | `--cw-<name>-<prop>` | `--cw-dialog-backdrop` |

The component name appears **exactly once per artifact name, in the same position**, so
everything is derivable. Identifiers derive from the presenter class name — Ruby and JS
cannot drift.

**Banned as primitive names** (too vague, or they describe a feature rather than a
behaviour): `toggle`, `modal`, `dropdown`, `autocomplete`, `lazy-load`, `local-storage`.

---

## Presenter API available to subclasses

```ruby
controller_attrs(*extra)   # => { "data-controller" => "cw--x …" }
target(:panel)             # => { "data-cw--x-target" => "panel" }
action("click->toggle")    # => { "data-action" => "click->cw--x#toggle" }
values(open: false)        # => { "data-cw--x-open-value" => "false" }   (nil omitted)
classes(open: "is-open")   # => { "data-cw--x-open-class" => "is-open" } (nil omitted)
event_name(:opened)        # => "cw--x:opened"
merge(*hashes)             # => Crosswire::Attributes.merge
overrides                  # caller-supplied attrs; merge LAST on the root element
```

Public methods are `<element>_attrs`, each accepting `**extra` merged last.

---

## Test expectations

**Presenter (Minitest, no Rails).** Cover: identifier derivation; every a11y guarantee as
its own test; id relationships wired both ways; state rendered server-side; optional
features off by default; caller `data-controller`/`data-action`/`class` composing rather
than clobbering; the `!` force-replace; nil-omission for optional classes.

**Controller (Vitest).** jsdom for state/values/events. **Browser mode** for anything
touching focus, `<dialog>`, IntersectionObserver, or positioning — jsdom cannot test those
honestly, and a library that only tests what jsdom supports ends up with
stimulus-components' accessibility record (`aria-expanded` as its only ARIA attribute
across 32 packages). Cover: connect/disconnect teardown, every action, every event
including cancelation, and the missing-class guard from R3.

### Test-environment gotchas

Each of these made a suite lie about what it was verifying. All were found by building, not
by reading documentation.

| Gotcha | Consequence | Handling |
|---|---|---|
| **`Application#stop()` does not call `disconnect()`** on still-connected controllers — it only stops observing future mutations | Every R7 teardown assertion passes **vacuously** for any test that leaves its element in the DOM. Worse, real listeners leak between tests and make *unrelated* tests flaky. | Clear the DOM and await a tick *first*, letting Stimulus's MutationObserver fire `disconnect()` as a real Turbo navigation would, and only then stop the application. The shared `afterEach` in `test/js/setup.js` does this — **do not reorder it** — but the rule is not a property of the harness: it applies equally to any hand-rolled `Application` you start inside a test body. Prefer `mount()` from `setup.js` over rolling your own; three separate agents hit this independently, two of them in hand-rolled instances. |
| **Node 25's built-in Web Storage global shadows jsdom's** — `globalThis === window` in vitest's jsdom env, and without `--localstorage-file` the built-in has *no methods at all*, not even `getItem` | Any storage test fails with confusing errors that look like controller bugs | Assign a Map-backed stub per test (see `persist_controller.test.js`). Define methods as **own-properties**, not on a prototype, so a single one can be swapped for a throwing stand-in to test graceful degradation. |
| **jsdom's `offsetParent` is unconditionally `null`** — it does no layout, so even a plainly visible `<button>` reports `null` | Visibility filtering and real tab order are not merely unreliable in jsdom, they are **categorically absent** | All real tab-order assertions go to the browser tier. Say so in a comment at the top of both files. |
| **jsdom cannot evaluate `:modal`** — `nwsapi` throws `SyntaxError` on the pseudo-class | A controller's own `matches(":modal")` idempotency check always reads false and loops | Extend the `showModal`/`show`/`close` polyfill to track modal state and answer `matches(":modal")` honestly (see `dialog_controller.test.js`). This is stubbing what jsdom omits, not faking browser-only behaviour. |

**The rule behind all four:** when a test cannot honestly verify what its name claims, move
it to the browser tier and comment which tier covers what. Never soften the assertion.
