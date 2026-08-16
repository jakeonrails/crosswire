# Changelog

## Unreleased

- Initial primitives, presenters, helpers, and the eject generator.
- Add `dirty-form`, `char-count`, and `reveal` — the first three form-tier
  primitives from the planned vocabulary (18 → 21 shipped).
- Add `preserve` — keep controller-owned values/attributes alive across Turbo 8
  morphing, plus an always-on `<dialog>` morph-deadlock guard in `cw--dialog`
  (also exported standalone as `installDialogMorphGuard`).
- Add `loading` and `fallback` — declarative in-flight (`data-loading`) and
  tri-state ok/loading/failed indicators for lazy frames, form submissions, and
  stream connections.
- Add `Crosswire::Streams::AuthorizedStreamChannel` and `crosswire_stream_from` —
  authorize the *subscriber* to a Turbo Stream, not just the signed stream name.
- Add `versioned_replace` — a Turbo Stream action that applies a broadcast only
  when its version beats the page's, so out-of-order deliveries can't go backwards.
