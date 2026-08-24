---
name: crosswire-authoring
description: "New Stimulus controller work in an app using crosswire, or a contribution to crosswire itself — use before writing the controller: decides whether the behaviour belongs in a controller at all (three tiers), then gives the component shape, the R-rules it must satisfy, and the sharp edges that bite first-time controllers."
---

crosswire's thesis: **Stimulus is the wiring tier, not the component tier.** A new
controller is the last resort, and when it is the right call, it follows a machine-
checked shape. If what you actually need is a modal/dropdown/drawer-style widget,
that is a composition of existing primitives — use the `crosswire-composing` skill
instead.

## 1 — Does this belong in a controller at all?

Apply in order; the first rule that fires wins:

- **Rule 0 — can the platform or server do it?** `<details>`, `<dialog>`, `popover`,
  CSS, a Turbo Frame or Stream. This kills more candidates than every other rule
  combined; check it via the `crosswire-ui` skill before continuing here.
- **Form control** — the thing has a `name` and a value that must submit with
  `form_with` → a **form-associated custom element**. A Stimulus controller cannot
  participate in submission, validation, reset, or `<fieldset disabled>`; a
  hidden-input mirror desynchronises.
- **Widget** — a noun you'd name in a design review, that owns DOM it *created*, and
  that outside code must observe or command → a **custom element** with attributes,
  properties and namespaced events as its API.
- **Logic** — testable with `new Thing()` in a bare Node process (state machines,
  formatters, network, timers) → a **plain ES class**; the controller that constructs
  and tears it down stays a thin adapter.
- **Everything else** → a Stimulus controller: wiring, under ~60 lines, mostly
  `connect`, `disconnect`, and action methods.

Escalate mid-build the moment a controller grows private fields holding non-DOM
state, or private methods that never touch `this.element` — extract the ES class and
keep the controller as the adapter.

## 2 — The component shape

Every crosswire component ships the same five artifacts; the names are all derivable
from the component name, and `test/crosswire/contract_audit_test.rb` machine-checks
the set (conventions here are enforced, not suggested — four parallel builders once
produced three incompatible naming schemes, which is why):

| Artifact | Where |
|---|---|
| Presenter (pure PORO, attribute contract + all a11y) | `lib/crosswire/presenters/<name>.rb` |
| Controller | `app/assets/javascripts/crosswire/controllers/<name>_controller.js` |
| Helper (`<name>_for` + `<name>_attrs`; widgets also `<name>`), included into `Crosswire::Builder` | `app/helpers/crosswire/<name>_helper.rb` |
| Partial — only if it owns markup, first line `<%# crosswire:contract v1 %>` | `app/views/crosswire/_<name>.html.erb` |
| Tests: presenter (Minitest, **no Rails**) and controller (Vitest, jsdom + browser tiers) | `test/crosswire/presenters/`, `test/js/` |

The full contract — naming table, presenter base API, test expectations — is
`docs/COMPONENT_CONTRACT.md` (in a host app: `"$(bundle show crosswire)"/docs/`).
Read it in full before the first file; the reference implementations it names
(`disclosure` for widgets, `dismiss` for behaviours) are the models to copy from.

## 3 — The load-bearing rules

Each exists because breaking it produced a documented bug; the one-line why is here,
the evidence is in `COMPONENT_CONTRACT.md`/`BUILD-LOG.md`:

- **R1** Presenters take no view context — pure hashes keep them unit-testable and let consumers drop to raw markup.
- **R2** Accessibility lives in the presenter, never the partial — ejected or restyled markup stays accessible.
- **R3/R3a** Guard `this.fooClass` with `hasFooClass`, and emit `data-*-class` on the controller element, never a target — either way, an absent class throws at runtime.
- **R4** One write path: the server renders state into a value, actions set the value, `<name>ValueChanged` does the DOM work — a morph, a stream and a click then converge on one code path. Render every value the controller reads: a presenter that accepts state without emitting it leaves the controller reading the typed default (this is how `tabs` hid all its own panels).
- **R4a** Guard event dispatch with a `#ready` flag — value callbacks run *before* `connect()` and the initial `previous` is the type's default, not `undefined`, so the obvious guard never fires and every reconnect announces a phantom event.
- **R5/R5a/R5b** Compose with namespaced events (`cw--<name>:<past-tense-verb>`), never outlets; between stacked controllers use a shared DOM event, a sibling value write, or an event listener — never a cross-controller method call; and put each `data-controller` where its own targets live (targets scope to descendants — the failure is a silently empty target set).
- **R6/R6a** Destructive actions dispatch a cancelable event first, and completion events fire *before* `remove()` — a detached node's events reach no document-level listener.
- **R7** `disconnect()` reverses every `connect()` side effect — listeners, timers, observers, `destroy()`, nulled references — because Turbo's snapshot cache turns each miss into a per-visit leak.
- **R8/R8a** Move focus before detaching a node that contains it; a key filter with a modifier needs its own descriptor (`keydown.tab` silently drops Shift+Tab).
- **R9** Rule 0 goes at the top of the presenter's docstring — say when *not* to use the component.

## 4 — Sharp edges that bite new controllers

- **`Application#stop()` does not disconnect controllers** — a teardown test that
  stops before clearing the DOM passes vacuously. Clear the DOM, await a tick, then
  stop; use `mount()` from `test/js/setup.js` rather than a hand-rolled `Application`.
- **Direct `Turbo.morphElements()` dispatches three events, not five** — only the
  element-level `turbo:before-morph-attribute` / `turbo:before-morph-element` /
  `turbo:morph-element`; `turbo:morph` and `turbo:before-frame-morph` come from the
  page/frame renderers a layer above. Design around the layer you actually call.
- **`turbo:before-fetch-request` and `turbo:submit-start` both fire on the same
  `<form>`, in that order** — check `event.target`, not just the event name, before
  treating two listeners as additive (counting both double-increments and the state
  never clears).
- **`<turbo-cable-stream-source>`'s `connected` attribute is presence-only** — absent
  means "not yet confirmed" *and* "dropped"; only an observed removal
  (`MutationObserver`) means disconnect.
- **jsdom lies**: `offsetParent` is always `null`, there is no global `CSS` object,
  `:modal` throws, synthetic events are `isTrusted: false` so native defaults never
  run. Anything touching focus, `<dialog>`, IntersectionObserver or positioning
  asserts in the browser tier — move the test, never soften the assertion.

## Done when

A new controller is finished when it survives this checklist, each item verified by a
test:

- `disconnect()` reverses every side effect `connect()` created — and the teardown
  test clears the DOM before stopping the application, so the assertion is real.
- Every piece of state the controller reads is server-rendered into a value
  attribute, with the single action → value → `ValueChanged` write path.
- All cross-controller communication is namespaced events (or R5a's sibling value
  write for programmatic moments).
- Destructive paths dispatch cancelable events, while the node is attached, guarded
  by `#ready`.
- Both test tiers exist, and every focus/dialog/observer/positioning assertion lives
  in the browser tier.
- The presenter's docstring opens with its Rule 0.
