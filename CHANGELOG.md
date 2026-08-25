# Changelog

## Unreleased

- **Breaking:** replace the ~90 flat `crosswire_<name>[_for|_attrs]` view helpers with
  a single `crosswire` / `cw` builder facade (`Crosswire::Builder`, modeled on Turbo's
  `turbo_stream.`/`tag.`) — `crosswire_disclosure_for` is now `cw.disclosure_for`,
  `crosswire_stream_from` is now `cw.stream_from`, and so on. No deprecation shim
  (pre-release, D8). `cw_attrs`/`cw_presenter` are unaffected — still called directly,
  not through `cw.`.
- Initial primitives, presenters, helpers, and the eject generator.
- Add `dirty-form`, `char-count`, and `reveal` — the first three form-tier
  primitives from the planned vocabulary (18 → 21 shipped).
- Add `preserve` — keep controller-owned values/attributes alive across Turbo 8
  morphing, plus an always-on `<dialog>` morph-deadlock guard in `cw--dialog`
  (also exported standalone as `installDialogMorphGuard`).
- Add `loading` and `fallback` — declarative in-flight (`data-loading`) and
  tri-state ok/loading/failed indicators for lazy frames, form submissions, and
  stream connections.
- Add `Crosswire::Streams::AuthorizedStreamChannel` and `cw.stream_from` —
  authorize the *subscriber* to a Turbo Stream, not just the signed stream name.
- Add `versioned_replace` — a Turbo Stream action that applies a broadcast only
  when its version beats the page's, so out-of-order deliveries can't go backwards.
- Add the agent-skills family — `skills/crosswire-ui`, `skills/crosswire-composing`,
  and `skills/crosswire-authoring`, shipped in the gem — plus
  `rails g crosswire:skills` to copy them into a host app's `.claude/skills/`.
- Add `menu` — WAI-ARIA APG Menu Button, composing `popover` + `roving-focus` under a
  thin (under 90 lines) controller that moves focus into the panel on open, closes on
  the right item roles, and rescues focus (R8) when the focused item is removed while
  open. `Crosswire::Builder::COMPOSITE_HINTS[:dropdown]` now distinguishes navigation
  links (`cw.popover`, plain `<a>`, no `role="menu"`) from commands (`cw.menu`).
- Add `combobox` — WAI-ARIA APG Combobox (editable, list autocomplete), maintaining
  the active option purely through `aria-activedescendant` — an ANTI-composition with
  `roving-focus`, not the obvious "combobox = roving-focus + listbox" guess (DOM focus
  never leaves the input; no option ever carries `tabindex`). Composes `click-outside`
  (R5a mechanism 2: the controller keeps its `enabled` value in lockstep with its own
  `expanded` state). A sibling hidden `<input>` carries the submitted value — the
  visible input carries none — written by exactly one path (`valueValueChanged`, R4).
  `filter:` supports `"client"` (hide non-matching, server-rendered options),
  `"remote"` (debounce, then write a Turbo Frame's `src` — no fetch path of its own),
  and `"none"`. `usePreserve` guards `value`/`expanded` across a Turbo 8 morph.
- Add the styled component tier's foundation — `Crosswire::UI` (an independent
  `CONTRACT_VERSION`, deliberately not autoloaded, see `lib/crosswire/engine.rb`),
  ~67 design tokens (`--cw-<category>-<step>` globals, `--cw-<component>-<prop>`
  knobs that default to them) in `app/assets/stylesheets/crosswire/ui/tokens.css`
  plus a swappable `themes/patchbay.css`, the `Crosswire::UI::Variants` declarative
  class-table DSL, and `ui_contract_audit_test.rb` / `token_contrast_test.rb`. It
  lands component by component, not all at once (spec: `research/notes` →
  `ui-tier-spec.md`) — see "Styled components" in the README.
- Add `button` — the UI tier's worked example: five variants, three sizes, `block`,
  and three presenter-held accessibility guarantees a plain `<button>`/`<a>` gets
  wrong by default (`type="button"` unless told otherwise; a disabled anchor drops
  its `href` and gains `role="link"` + `aria-disabled`; `aria-busy` travels with a
  bare `data-loading`, the same attribute name `cw--loading` sets at runtime).
  `cw.button_attrs` is the `button_to`/`f.submit`/`link_to` integration story — no
  `cw.button_to`. Morph: Safe.
- Add `badge` — the smallest UI-tier component (one six-value `variant`, one
  `boolean`), built specifically to exercise `Crosswire::UI::Variants` under a
  second component; no engine gap turned up. Morph: Safe.
- Add `card` — the Slots proof (ui-tier-spec.md §6.3): `plain`/`raised`/`outlined`
  variants, an `interactive` boolean, and `Crosswire::UI::Slots`-backed
  header/body/footer regions (arity-0 shorthand = the whole block is the body; a
  slot renders only when the caller named it). The interactive-card a11y doctrine —
  no `role`/`tabindex` on the wrapper; one real `<a class="cw-card__link">` in the
  header, stretched over the whole card with `::after { inset: 0 }` — lives in both
  the presenter's docstring and `site/examples/card/interactive.html.erb`. Morph:
  Safe.
- Add `input` — a styled native `<input>`/`<textarea>` shell (`multiline:` picks the
  tag): a `size` variant, an `aria-invalid` styling hook (an attribute, not a
  `Variants` class, so the screen-reader signal and the visual one can never drift
  apart), and the same bare `data-loading` convention as `button`. No JS. Morph:
  Safe.
- Add `field` — a label + control + hint + error wrapper whose whole job is
  accessibility wiring: the label's `for` and the control's `id` come from one
  shared value so they cannot drift; a hint wires `aria-describedby`; an error wires
  `aria-errormessage` + `aria-invalid` (presence alone decides invalidity — no
  separate flag to keep in sync). Composes `cw.input` by default; any other control
  (`cw.select`, a hand-rolled radio group) goes through `cw.field_for` and
  `f.control_attrs`, a Symbol-keyed hash deliberately safe to double-splat into any
  `cw.<control>` helper. Morph: Safe.
- Add `select` — a styled NATIVE `<select>`, this tier's Rule 0 exemplar: no
  reimplemented listbox, no controller, just the platform control with crosswire's
  classes on it — the `<option>`s are whatever the caller writes. The tier's first
  non-Safe Morph verdict (**Server-owned**): once a `<select>`'s live value has
  diverged from its `selected` HTML attribute, a DOM diff that patches the attribute
  is not guaranteed to make the control visibly follow it, so the server-rendered
  `selected` option is what a morph must land — proven against real
  `@hotwired/turbo` in `test/js/select.browser.test.js` (jsdom cannot be trusted for
  this; see that file's header). `cw.select` deliberately shadows
  `ActionView::Helpers::FormOptionsHelper#select` inside `Crosswire::Builder` only —
  pinned by `test/crosswire/ui/select_test.rb`'s
  `Crosswire::Builder.instance_method(:select).owner` assertion.
- Add `test/crosswire/ui/rendering_test.rb` (+ `rendering_test_runner.rb`, the
  child-process pattern `integration_test.rb`/`streams_test.rb` already use) — every
  registered UI component rendered through a real `ActionView` context under a real
  Rails boot: renders with defaults, the root carries its base class, a caller's own
  `class:` survives, and card's four header/body/footer slot combinations actually
  produce the right DOM (not just the right Ruby-level `Slots` bookkeeping the
  presenter unit suite can't observe on its own).
- Fix `ui_contract_audit_test.rb`'s token-discipline check (#7): the raw-token
  regex's trailing `\b` treated `%` as a non-word boundary, so an allowlisted value
  like `100%` was scanned as bare `100` (not on the allowlist) and reported as a
  false violation — replaced with a `(?![\w%])` lookahead that keeps `%` attached to
  its number. The scanner is now comment-aware too (CSS comments are stripped before
  either token-discipline rule runs), so explanatory prose mentioning a raw value or
  a `--cw-*` name can no longer be mistaken for a declaration. `button.css`'s
  `--cw-button-block-width` knob — a custom-property workaround for exactly this bug
  (a regular declaration's raw `100%` value has nowhere to hide from the lint except
  inside a custom property, which the lint never inspects) — is no longer needed and
  is gone; `.cw-button--block` sets `width: 100%` directly.
- Add `bin/build_gallery.rb` and `site/component_template.html` — renders every
  `site/examples/<component>/*.html.erb` through the real Rails view stack (demo ==
  copy-paste snippet, same "boot test/dummy for real" approach as the integration
  suite) into `site/components/<name>/index.html`, with a theme switcher, a live
  token panel, the props table generated from `Presenter.variants`, the Morph
  clause, and the eject command. `bin/lib/site_bundle.rb` extracts the machinery
  `bin/build_site.rb` and `bin/build_gallery.rb` now share (`strip_module_syntax`,
  `class_name_for`, and the `String#sub` block-form byte-guards) — `rake site` runs
  `ui:bundle` → `ui:registry` → `build_site.rb` → `ui:gallery` → `smoke_site.mjs`,
  which now also walks every component page and fails on a console error or a
  zero-height rendered root.
- Add `alert` — the styled tier's composition showcase (ui-tier-spec.md §5 item 7):
  `severity` (neutral/info/success/warning/danger) picks BOTH the visual variant and
  the ARIA role (`status` for polite severities, `alert` for danger/warning) — never
  a role alongside a redundant, possibly-disagreeing `aria-live`. An optional
  `dismissible: true` composes the existing `cw--dismiss` primitive onto the root
  element by stacking its `root_attrs`, exactly the way
  `skills/crosswire-composing/RECIPES.md`'s "Toast / flash message" recipe already
  documents by hand — `dismiss_trigger_attrs` hands back the composed trigger's
  attributes, raising if called on a non-dismissible alert. Morph: **Server-owned**
  — the tier's second non-Safe verdict, and a new shape of one: dismissal is a DOM
  removal with no server-visible trace at all (no `dismissed` value for a morph to
  patch), so a subsequent response that keeps rendering the same alert resurrects it
  — the flash-message trap. `test/js/alert.browser.test.js` DEMONSTRATES the trap
  against real `@hotwired/turbo` (a morph brings a dismissed alert back) rather than
  claiming to fix it; the fix is server-side, and the presenter's docstring says so.
- Add `toast` — new markup, the tier's other composition showcase: a viewport-fixed
  live-region container (`Crosswire::UI::ToastViewport`, `cw.toast_viewport`) that
  must render server-side before any toast exists ("the aria-live rule from the
  corpus" — a live region's `role`/`aria-live` has to already be in the DOM before
  content is injected for reliable screen-reader announcement), plus individual
  toasts (`cw.toast`) composing `cw--dismiss` + `cw--timeout` + `cw--transition` via
  stacked `root_attrs`, wired together (hover pauses/resumes the auto-dismiss timer;
  the timer's `elapsed` event dismisses; dismissal's cancelable `dismissing` event
  runs the leave transition before removal). Each composed piece is independently
  optional (`dismissible: false`, `timeout: nil`) — only the wiring between two
  present pieces is ever emitted. Two rendering paths, both in the docstring: toasts
  rendered inside `cw.toast_viewport`'s block on first paint, or Turbo-Stream-appended
  into the same (already-rendered) container later — a one-line controller response.
  Morph: **Excluded** — the container's shipped partial carries
  `data-turbo-permanent` — which toasts exist, and each one's live timer/transition
  state, is DOM-only, with no server-side representation at all.
  `test/js/toast.browser.test.js` proves it against real `@hotwired/turbo`: a
  page-level morph whose incoming HTML doesn't even render the container's toasts
  leaves the live toast stack — and the exact same running `cw--timeout` controller
  instances — untouched. That test also settled an open question the spec itself
  raised (§5 item 11: "bare morphElements may not honor turbo-permanent the way page
  renders do — investigate") — it does, unconditionally, because `data-turbo-permanent`
  is checked inside `DefaultIdiomorphCallbacks`, which the exported `morphElements()`
  constructs itself; there was never a distinct "page render" path for it to differ
  from. Full finding in `docs/BUILD-LOG.md`.
- Add `test/js/field.browser.test.js` — the tier's other required browser-tier
  component (ui-tier-spec.md §7.3 names toast and field; field shipped without one in
  Phase 2). `Crosswire::UI::Field` ships no controller (Morph: Safe), so this is a
  pure DOM proof that `aria-describedby`/`aria-errormessage` genuinely resolve to
  real elements in a real document — the same lookup a screen reader's accessibility
  tree builder performs — not just matching strings, which the presenter unit suite
  already pins with no DOM at all.
- Add `dialog.css`, `popover.css`, `menu.css`, `combobox.css` — the showcase tier
  (ui-tier-spec.md §5 items 8–10 + 12): CSS ONLY over four already-shipped
  primitive-tier widgets, no new presenter, no new helper, no API change.
  `dialog.css` is the modal-composition showcase — `::backdrop` via
  `--cw-color-overlay`, a `@starting-style` + `transition-behavior: allow-discrete`
  enter/exit animation (honoring `--cw-duration`/`--cw-ease`, disabled under
  `prefers-reduced-motion`), `:modal`-scoped sizing, and `scrollbar-gutter: stable`
  internal scroll containment on the body. `popover.css` stays deliberately lean
  (elevation/radius/padding only — placement remains entirely in the primitive).
  `menu.css` adds item hover/`:focus-visible`/`[aria-checked]` states, a documented
  `[role="separator"]` treatment the partial itself never emits, and a
  `.cw-menu__item--danger` modifier. `combobox.css` styles `[aria-selected]` and the
  documented `.cw-combobox__option--active` convention the controller's optional
  `active_class:` (Stimulus Classes API — opt-in, no default) targets at runtime.
  Every gallery example exercises the real widget through `cw.dialog`/`cw.popover`/
  `cw.menu`/`cw.combobox`; `site/examples/dialog/composed-with-card.html.erb`
  composes `cw.dialog_for` with a real `cw.button` trigger and a `cw.card` body —
  three styled-tier pieces on one dialog.
- Extend `Crosswire::UI::COMPONENTS`'s entry shape with a `kind:` marker (`:new`,
  the default, unchanged for the eight prior components; `:css` for the four
  above) — every one of `ui_contract_audit_test.rb`'s ten checks, `rake
  ui:registry`, `rake morph:doc` and `bin/build_gallery.rb` branch on
  `Crosswire::UI.kind_of`/`.css_only?` so both shapes stay meaningfully checked: a
  `kind: :css` name is asserted to genuinely collide with a real, shipped
  `Crosswire::COMPONENTS` primitive (check 5, inverted from the `kind: :new`
  no-collision rule) rather than requiring files that were never going to exist
  (a `lib/crosswire/ui/dialog.rb`, an unregistered `DialogHelper`). Their `#
  Morph:` docstring clauses live on the PRIMITIVE presenter they style
  (`lib/crosswire/presenters/dialog.rb`/`popover.rb`/`menu.rb`/`combobox.rb`) —
  dialog is **Server-owned** (the native `<dialog>` `open` attribute vs. actual
  modal state can diverge across a background morph; the controller's own
  `turbo:before-morph-element` cancellation is the defence, proven in
  `test/js/dialog_controller.browser.test.js`); popover and menu are
  **Preserved** by construction (open/closed lives entirely in the browser's
  native popover top-layer state, never a Stimulus value, so there is nothing
  for a morph to touch either way); combobox is **Preserved** via `usePreserve`'s
  existing `preservedValues = ["value", "expanded"]` guard (already shipped on
  the primitive; only now carries the formal clause).
- Add the fourth agent skill, `skills/crosswire-styling` (symlinked into
  `.claude/skills/`, discovered automatically by `rails g crosswire:skills`) —
  styling and theming the `cw.*` styled tier: tokens before classes (the
  redefine-token → plain-rule → eject escalation ladder), the two-depth token
  system (global vs. component knob vs. per-instance `style=""`), the helper
  triple read as a STYLING escalation (`_attrs`/bare call → `_for` → eject), the
  cascade-layer story (unlayered app CSS always beats `@layer crosswire.*`, no
  `!important` needed), `data-cw-theme` + the `themes/patchbay.css` full-repaint
  worked example, and a pointer to `docs/MORPH.md` before touching any non-`Safe`
  component.
- README: the "Styled components" section names all twelve components (eight
  new-markup plus four CSS-only), the `crosswire:install` one-liner, a
  three-line token-override worked example (global vs. component knob), the
  `site/components/<name>/` gallery link pattern, and a `docs/MORPH.md` pointer.
  `docs/DECISIONS.md` D9 records the tier's sequencing: in-core (not a second
  gem, `D7` precedent), `lib/`-not-`app/helpers/`-and-not-autoloaded placement
  (the contract-audit glob and the Zeitwerk two-letter-acronym collision, both
  independently sufficient reasons), plain CSS custom properties as the
  substrate with the Tailwind `@theme` mapping deliberately held to v1.1, the
  neutral-default-plus-swappable-`patchbay.css` both-themes hedge, the
  no-screenshot-testing doctrine, and the registry (`site/registry.json`)
  shipped as real infrastructure but explicitly not marketed as a standard.
