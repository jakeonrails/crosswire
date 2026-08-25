---
name: crosswire-styling
description: "Crosswire UI styling and theming — use when styling or theming crosswire's styled components (cw.button, cw.card, cw.alert, and the rest of the UI tier), building a screen out of them, or making a host app's own look override the shipped defaults."
---

crosswire's styled tier (`Crosswire::UI` — `button`, `badge`, `card`, `input`,
`field`, `select`, `alert`, `toast`, plus CSS over the shipped `dialog`/`popover`/
`menu`/`combobox` widgets) ships real CSS on ~67 design tokens, not utility classes.
This skill covers styling and theming what ships. For wiring the underlying
behaviour, use `crosswire-ui`; for stacking multiple primitives into a composite,
use `crosswire-composing`.

## Tokens before classes

Before writing a single CSS rule against `.cw-button`, ask whether a **token**
already says what you want to change — a token override touches every component
that reads it, needs no specificity fight, and survives an upgrade. The escalation
ladder, cheapest first:

1. **Redefine a `--cw-*` custom property**, anywhere in your own CSS, no
   `!important`, no layer declaration needed — unlayered app CSS always wins (see
   "The layer story" below).
2. **A plain rule against `.cw-button`** (or any shipped class) in your own,
   unlayered stylesheet — still wins over every layered rule the gem ships.
3. **`rails g crosswire:eject button --css`** — copy the component's stylesheet
   into your app and edit it directly. Last resort: you stop receiving upstream
   CSS fixes for that one file.

Reach for step 2 only when the change genuinely isn't expressible as a token (a
new pseudo-class rule, a layout change); reach for step 3 only when 1 and 2 both
fall short.

## The two-depth token system

Every token lives at one of two depths, and both are meant to be overridden —
picking the right depth is the whole skill:

- **Global** (`--cw-color-accent`, `--cw-radius`, `--cw-space-4`, …) — semantic,
  categorized (`color`/`space`/`radius`/`text`/`weight`/`leading`/`font`/`shadow`/
  `border`/`duration`/`ease`/`z`), shared by every component. Override one of these
  and every component that reads it changes at once — this is how you reskin the
  whole tier's accent color or corner radius in one line.
- **Component knob** (`--cw-button-bg`, `--cw-alert-border`, …), always declared
  `default: var(--cw-<global>)` in the component's own CSS
  (`.cw-button { background: var(--cw-button-bg, var(--cw-color-surface)); }`).
  Override the KNOB when you want to change one component and leave every sibling
  alone; override the GLOBAL when you want the change to propagate.

A third depth exists for a single element: `style="--cw-button-bg: hotpink"` on
one instance, no CSS file involved at all. `--cw-*` names never chain to a guessed
host token name (`--brand-primary` or similar) — the three depths above are the
whole override surface, deliberately, so there is one thing to learn instead of a
convention to reverse-engineer per app.

## Escalate only as far as you need

The helper triple (`<name>`, `<name>_for`, `<name>_attrs`) doubles as a styling
escalation ladder, cheapest first:

1. **Pass `class:`/`style:`/`data:` straight through the batteries-included call**
   — `cw.button "Save", variant: :primary, class: "w-full"` — or grab
   `cw.button_attrs(...)` directly when you need the merged attribute hash on an
   element you're building by hand. This covers the overwhelming majority of
   real styling asks and needs no new markup, no eject.
2. **`cw.<name>_for`** when the STRUCTURE itself needs to change — different
   child elements, extra wrapping — not just which classes land on the existing
   ones.
3. **`crosswire:eject <name> --css`** (styling changes only, upstream CSS fixes
   stop) or **`--presenter`** (markup AND CSS, full ownership) only once 1 and 2
   both fall short of what the redesign needs.

Jumping straight to eject for a change step 1 could have made is the single most
common way a styling task turns into more code to maintain than the feature
warranted.

## The layer story: unlayered app CSS always wins

Every rule this tier ships lives inside a named cascade layer —
`@layer crosswire.tokens, crosswire.base, crosswire.components;` — declared once by
the bundle, with each source file wrapping its own rules in the matching `@layer`
block so it stays correctly ordered even loaded standalone. Per the CSS cascade
spec, **any unlayered rule beats every layered rule, regardless of selector
specificity or source order.** Your app's own `app/assets/stylesheets/application.css`
is unlayered by default, so a plain `.cw-button { background: hotpink; }` in your
own stylesheet wins over the gem's `.cw-button` rule with zero `!important`, zero
specificity arithmetic, zero fighting the framework. This is *why* step 2 of the
escalation ladder above works without a linter-defeating hack.

## Theme switching: `data-cw-theme` + the patchbay swap

Light/dark is `prefers-color-scheme` by default; force one explicitly by setting
`data-cw-theme="dark"` (or `"light"`) on `<html>` — a small JS snippet writing that
attribute is the entire mechanism, no framework, no reload. `data-theme` is
honoured as a bridge for a host app already using that convention elsewhere, but
`data-cw-theme` wins if both are set. `color-scheme` is set in every branch
(`:root`, the media query, and the explicit attribute), which is load-bearing —
native scrollbars, `<select>`, and form controls follow it too.

A full re-theme — not just light/dark, a genuinely different palette — is one
stylesheet swap: `app/assets/stylesheets/crosswire/ui/themes/patchbay.css` ships as
a worked, real example (the site's own palette, not a toy), loaded instead of (or
layered after) `tokens.css`. Study it as the template for shipping your own
`themes/<name>.css` the same way: every token this tier declares, redeclared with
different values, in the same `crosswire.tokens` layer.

## Read the Morph: verdict before you touch anything with client state

Every non-trivial component's Morph verdict is machine-generated from its
presenter's docstring into `docs/MORPH.md` — read it before wiring `alert`,
`select`, `dialog`, `toast`, or any component whose Morph verdict is not `Safe`,
especially before adding Turbo Streams or `broadcasts_refreshes` to a page that
already renders one. `Safe` means restyle freely with no behavioural
consideration; anything else names exactly what the server must keep rendering
correctly across a morph, and styling changes never move a component from one
verdict to another on their own — verify the verdict didn't change only if you
also touched the presenter.

## Discover the tier from the gem, not from memory

```bash
gem_dir="$(bundle show crosswire)"
ls "$gem_dir"/app/assets/stylesheets/crosswire/ui/       # tokens.css, base.css, one file per component
cat "$gem_dir"/app/assets/stylesheets/crosswire/ui/tokens.css   # the full token catalog, with the override ladder in its own header
cat "$gem_dir"/site/registry.json                          # machine-readable: files + cssVars per component
```

Every component's live, restylable examples render at `site/components/<name>/`
(published at the `jakeonrails.github.io/crosswire/components/<name>/` pattern) —
each page ships the rendered markup, the exact CSS, the props table, and the eject
command, generated from the gem's real source, never a mock.

## Done when

The change is expressed at the CHEAPEST depth that actually captures it — a token
override before a class rule, a class rule before an eject — the host's stylesheet
stays unlayered so it keeps winning without `!important`, and if the component's
Morph verdict is not `Safe`, `docs/MORPH.md` still describes the truth after your
change.
