# Resume brief — paused 2026-08-15 23:40 PDT

Work was paused mid-build to avoid a Claude usage rate limit. Three build agents were
stopped cleanly; their presenters had all landed and passed, and each was partway through
its JavaScript controller tests.

**Read `docs/DECISIONS.md` (D1–D6) and `docs/COMPONENT_CONTRACT.md` before touching code.**

---

## State at pause

```
Ruby:  139 runs, 223 assertions, 0 failures     ✅ all presenters green
JS:    5 test files pass, 2 fail (56 passing, 22 failing)
```

Verify with:
```bash
cd ~/source/crosswire
ruby -Ilib -Itest -e 'Dir["test/**/*_test.rb"].each { |f| require File.expand_path(f) }'
npx vitest run
```

### Components: 9 of 10 built

| Component | Presenter | Controller | Helper | Partial | Ruby test | JS test |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| disclosure | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| dismiss | ✅ | ✅ | — | — | ❌ **missing** | ❌ **missing** |
| dialog | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ **7 failing** |
| focus-trap | ❌ | ❌ | ❌ | n/a | ❌ | ❌ **not started** |
| transition | ✅ | ✅ | ✅ | n/a | ✅ | ✅ |
| persist | ✅ | ✅ | ✅ | n/a | ✅ | ⚠️ **15 failing** |
| autosubmit | ✅ | ✅ | ✅ | n/a | ✅ | ✅ |
| confirm | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ **missing** |
| intersection | ✅ | ✅ | ✅ | n/a | ✅ | ✅ (+browser) |
| clipboard | ✅ | ✅ | ✅ | n/a | ✅ | ✅ |

`dismiss` has no helper by design — it is exercised through other components — but it does
need tests.

---

## Next actions, in order

### 1. Fix `test/js/persist_controller.test.js` (15 failing)
The agent had diagnosed this and was applying the fix when stopped. Its last words:
*"The polyfill approach works. Let me rewrite the persist test file using this pattern."*
jsdom's `localStorage` does not behave as the tests assume. Install an explicit storage
polyfill/stub in the test file rather than relying on jsdom's. **The controller is likely
correct; the test file is what needs rewriting.** Confirm that before editing the controller.

### 2. Fix `test/js/dialog_controller.test.js` (7 failing)
Also mid-fix. Its last words: *"All 24 dialog presenter tests pass. Now let's write the
dialog jsdom controller test, being careful about jsdom's lack of `showModal`/`show`/`close`."*
jsdom implements `<dialog>` only partially — no `showModal`, no top layer, no inertness.
Stub those methods explicitly in the jsdom tier and move the honest assertions (real modality,
inertness, focus containment) into `test/js/dialog_controller.browser.test.js`, which already
exists and is excluded from the default run.

### 3. Build `focus-trap` — the only component not started
Behaviour, no partial. Full brief:
- Rule 0 in the docstring: **inside a modal `<dialog>` you do not need this** — `showModal()`
  already inerts the rest of the document. This exists for drawers, non-modal panels and
  toolbars.
- Values: `active` (Boolean, default true), `initial` (String, optional selector to focus on
  activate). Events: `cw--focus-trap:activated`, `:released`.
- Handle Tab/Shift+Tab wrapping; no-focusable-children (focus the container with
  `tabindex="-1"`); **re-query focusable children on each Tab rather than caching a stale
  list**; restore focus to the previously focused element on release/disconnect.
- Exhaustive teardown (R7). Browser-tier tests for focus order — jsdom cannot test it honestly.

### 4. Write the missing tests
`test/crosswire/presenters/dismiss_test.rb`, `test/js/dismiss_controller.test.js`,
`test/js/confirm_controller.test.js`.

### 5. Reconcile `confirm` and `dialog`
They were built in parallel by different agents and both handle native `<dialog>`.
`confirm_controller.js` carries a `TODO(compose): delegate to cw--dialog once both have
landed`. Make `confirm` compose with `cw--dialog` rather than duplicating it — that
composition is the library's whole thesis, so duplication here would be embarrassing.

### 6. Wire up registration — I deliberately held these back
Four agents were told **not** to touch these two files, to avoid a four-way race. They are
still stale and list only `disclosure` and `dismiss`:
- `lib/crosswire.rb` — add every presenter to `require` and to the `COMPONENTS` hash
- `app/assets/javascripts/crosswire/index.js` — add every controller to
  `CROSSWIRE_CONTROLLERS` and the named exports

### 7. Then: the eject generator (D6)
`lib/generators/crosswire/eject/eject_generator.rb` — not started. Tiers `--markup`
(default), `--controller`, `--all`. Must write the `<%# crosswire:contract v1 %>` marker
into every ejected partial, which is what `ShadowCheck` reads at boot.

---

## Contract rules discovered during the build

Added to `docs/COMPONENT_CONTRACT.md` while building; both came from failing tests, not docs:

- **R4a** — guard event dispatch with a `#ready` flag, not `previous === undefined`.
  Stimulus runs value callbacks *before* `connect()`, and the initial `previous` is the
  type's default (`false`), not `undefined`. Under Turbo, controllers reconnect constantly,
  so the broken guard produces a steady drip of phantom events.
- **R3a** — `data-*-class` attributes must be emitted on the **controller element**, never
  on a target. Stimulus resolves the Classes API against the controller's own element only;
  putting it on a target throws at runtime.

---

## Do not

- Do not re-open D1–D6 without a new fact; see `docs/DECISIONS.md`.
- Do not add ViewComponent or Phlex as a dependency (D5).
- Do not put accessibility attributes in a partial — they belong in the presenter (R2/D6),
  because that is what keeps an ejected copy correct.
- Do not boot Rails in the Ruby test suite; `test/test_helper.rb` asserts it stays out, and
  that assertion is the guarantee presenters remain context-free (D5).
