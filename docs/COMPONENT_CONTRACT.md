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

### R6 — Make destructive events cancelable
Anything that removes, closes, or replaces DOM dispatches a cancelable event first and
passes a `complete()` callback in `detail`.
*Why: `Node.remove()` is synchronous — once it runs there is nothing left to animate. This
is a spec-level limit that `@starting-style` cannot fix. (notes/18)*

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
