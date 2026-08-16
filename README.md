# crosswire

Composable, accessible Hotwire primitives for Rails.

Small, generic Stimulus controllers paired with ERB helpers, so rich UI stays *The Rails
Way* without reaching for React.

> **Status: alpha.** Eighteen primitives of a planned 39. The API will change. It is being built
> in the open from a 50,000-line research corpus (`research/`) rather than from vibes —
> if a design decision here looks arbitrary, `docs/DECISIONS.md` says why, and cites the
> evidence.

---

## Why this exists

The Hotwire ecosystem does not lack knowledge. It lacks packaging.

- **Six** production codebases independently invented the "Stimulus controller + ERB
  helper" pairing — 37signals, Solidus, Avo, Administrate, `hotwire_combobox`,
  `stimulus_aria_widgets`. **None** documented it.
- 37signals copy-paste **14 primitives** between Campfire, Writebook and Fizzy — three of
  them byte-for-byte identical — because there is no way to ship them.
- A Turbo maintainer built APG-accessible widgets and **never published them**.
- `gh search repos hotwire aria` returns **nothing**. There is no maintained accessible
  Hotwire component library.

crosswire's claim is not novelty. It is: *we ship it, document it, and keep it working.*

## The thesis

**Stimulus is the wiring tier, not the component tier.**

A controller only stays generic if its classes, URLs, ids and bindings are injected from
outside — and doing that by hand in ERB is painful enough that people give up and write
one-off controllers instead. **The helper layer is what makes generic controllers
survive contact with a real app.**

So there is no `modal` controller here. A modal is `dialog` + `focus-trap` + `scroll-lock`
+ `dismiss` + `transition`, and each of those is independently useful elsewhere.

And before any of it: **can the server do it?** Of 119 UI patterns we catalogued, **41 need
no JavaScript at all** and 38 need "tiny". `<details>`, `<dialog>`, `popover`,
`field-sizing: content` and Turbo Frames have quietly eaten most of what component
libraries still ship JS for. Every presenter's docstring says when *not* to use it.

## Install

```ruby
# Gemfile
gem "crosswire"
```

```js
// app/javascript/application.js
import { Application } from "@hotwired/stimulus"
import { registerCrosswireControllers } from "crosswire"

const application = Application.start()
registerCrosswireControllers(application)
```

Register a subset if you prefer — `registerCrosswireControllers(application, ["cw--disclosure"])`.
Each controller also ships as its own ES module so it can be lazy-loaded; a single bundle
cannot be, because `stimulus-loading` registers via a dynamic per-controller import.

## Use it at whatever level suits

**Batteries included** — renders the shipped partial:

```erb
<%= crosswire_disclosure "Shipping details", id: "shipping" do %>
  <p>Arrives in 3–5 days.</p>
<% end %>
```

**Compose it yourself** — yields the presenter, renders none of our markup:

```erb
<%= crosswire_disclosure_for id: "faq-1" do |d| %>
  <div <%= cw_attrs(d.root_attrs) %>>
    <%= tag.button "Details", **d.trigger_attrs %>
    <%= tag.div(**d.panel_attrs) { "…" } %>
  </div>
<% end %>
```

**Your markup entirely** — a completely different element structure, and the controller
still works, because it only ever knew targets and values:

```erb
<% d = cw_presenter(:disclosure, id: "faq-1") %>
<details <%= cw_attrs(d.root_attrs) %>>
  <summary <%= cw_attrs(d.trigger_attrs) %>>Details</summary>
  <div <%= cw_attrs(d.panel_attrs) %>>…</div>
</details>
```

Your own attributes **compose** rather than clobber — pass `data: { controller: "analytics" }`
and you get `data-controller="cw--disclosure analytics"`. Pass `data: { "controller!" => "mine" }`
and the `!` forces replacement. That merge is 45 lines of pure Ruby with no ActionView
dependency, and it is idempotent, so it is safe to apply at every layer.

## What ships today

**Behaviours** (decorate an existing element, no markup)
`dismiss` · `transition` · `persist` · `intersection` · `focus-trap` · `roving-focus` ·
`hotkey` · `click-outside` · `scroll-lock` · `timeout` · `sync` · `clipboard` · `autosubmit`

**Widgets** (own markup, ship an ejectable partial)
`disclosure` · `dialog` · `confirm` · `tabs` · `popover`

Every component exposes `crosswire_<name>_for` (yields the presenter) and
`crosswire_<name>_attrs` (returns the merged attribute hash); widgets additionally get the
bare `crosswire_<name>` render form.

21 more are specified in `research/notes/08-ui-pattern-catalog.md` — the vocabulary was
reconciled across ~95 UI patterns with zero drift, so the names are stable even where the
code isn't written.

## Accessibility is in the presenter, not the markup

Every `role`, `aria-*`, id relationship and `tabindex` is emitted by a Ruby presenter. The
partial only places them. That is deliberate, and it is what makes the next section safe.

## Own the code when you want to

```bash
bin/rails g crosswire:eject disclosure               # the markup; keep receiving a11y + logic fixes
bin/rails g crosswire:eject disclosure --controller  # markup + JS, fully yours, no more updates
bin/rails g crosswire:eject --all
```

Ejected markup keeps working correctly after a total restyle, because the accessibility
travels with the presenter. And every ejected partial carries a
`<%# crosswire:contract v1 %>` marker that a boot-time check verifies — so when crosswire
changes what its controllers expect, **your stale copy fails at boot naming the file and
both versions**, instead of silently misbehaving. Copy/paste component libraries normally
have no answer to that.

You can also just override a partial by creating `app/views/crosswire/_disclosure.html.erb`.
Same check applies.

## What this does not do

Hotwire genuinely loses at: virtualized long lists, spreadsheet-style grid editing,
optimistic UI with rollback, character-level collaborative editing, typing indicators, and
infinite-scroll back-button state. `research/notes/12-cross-framework-and-the-case.md` names
each one and the honest escape hatch. We would rather tell you that than sell you something.

Also worth knowing: Turbo + Stimulus is **~35% larger** than React + ReactDOM at framework
level. The "ships less JS" argument is only true at the application-bundle level.

## Documentation

| | |
|---|---|
| `docs/recipes/corrections.md` | 34 pieces of widely-repeated Hotwire advice that are now **wrong**, with the reality and the fix |
| `docs/recipes/diagnosis.md` | 12 symptoms → confirm → root cause → fix |
| `docs/COMPONENT_CONTRACT.md` | the rules every primitive follows, each traced to the bug that motivates it |
| `docs/DECISIONS.md` | locked decisions and why; check before re-opening one |
| `research/README.md` | index to the corpus, the 10 load-bearing findings, the corrections log |

The corrections and diagnosis pages are useful even if you never install this gem.

## Development

```bash
bundle install && npm install

bundle exec rake test    # Ruby: presenters + Attributes, deliberately without booting Rails
npx playwright install chromium   # once, before the browser tier below

npm test                 # JS: jsdom tier (test/js/**/*.test.js)
npm run test:browser     # JS: browser tier, headless Chromium (test/js/**/*.browser.test.js)
npm run test:all         # both
```

The two tiers are two separate Vitest config files — `vitest.config.js` (jsdom, the
default `vitest run` picks up automatically) and `vitest.browser.config.js` (real
Chromium via `@vitest/browser` + Playwright) — rather than one config with two
`test.projects` entries, because Vitest runs every declared project by default unless
`--project <name>` is passed. Splitting the tiers into separate files keeps plain
`npx vitest run` / `npm test` scoped to jsdom only.

The Ruby suite **must not boot Rails** — a test asserts it. That is the guarantee presenters
stay usable, and unit-testable, without it. The generator suite needs Rails, so it runs in a
child process.

Two tiers for JS because jsdom cannot honestly test focus, `<dialog>` modality,
IntersectionObserver or positioning — and a library that only tests what jsdom supports ends
up with the accessibility record of one that shipped `aria-expanded` as its only ARIA
attribute across 32 packages.

## License

MIT.
