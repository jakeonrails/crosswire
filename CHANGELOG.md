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
