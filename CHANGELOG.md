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
