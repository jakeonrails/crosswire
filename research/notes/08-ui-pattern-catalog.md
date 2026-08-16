# 08 — The Canonical UI Pattern Catalog

**What this is.** For every common interactive UI pattern a modern web app needs, the best-known
Hotwire implementation — the one a thoughtful Rails developer would ship in 2026. Each record names
the tool that does the work, gives adaptable code, and decomposes the pattern into small **generic**
Stimulus primitives rather than one-off controllers.

**Version snapshot (2026-08-15).** `@hotwired/turbo` 8.0.23 · `turbo-rails` 2.0.23 · Stimulus 3.2.x ·
Rails 8. **There is no Turbo 9.** Rack 3.1 renamed 422 to *Unprocessable Content*, so every code
sample here uses `status: :unprocessable_content`.

**Staleness markers.** Any tutorial using `Turbo.clearCache()`, `Turbo.setProgressBarDelay()`,
`Turbo.setConfirmMethod()`, or `Turbo.setFormMode()` predates Turbo 8 — the modern equivalents are
`Turbo.cache.clear()` and `Turbo.config.*`. Records below flag where morphing has obsoleted a
pre-2024 recipe.

**Companion documents.** Mechanics live in
[`02-turbo-deep-dive.md`](./02-turbo-deep-dive.md); native concerns in
[`04-hotwire-native.md`](./04-hotwire-native.md). This document is the *catalog*, and cross-references
those rather than repeating them.

**The house style.** Three rules govern every record:

1. **Ask "does this need JavaScript at all?" first.** In 2026 the answer is "no" far more often than
   the Rails-Twitter consensus assumes — `<dialog>`, the Popover API, CSS anchor positioning,
   `<details name>`, `field-sizing`, `light-dark()`, `content-visibility`, and scroll-driven
   animations have eaten whole categories of Stimulus controller.
2. **Prefer a URL to a state variable.** Anything a user can navigate to should be reachable by
   link, restorable by reload, and correct under the back button. Turbo Frames plus
   `data-turbo-action="advance"` is how you get there.
3. **Compose primitives.** A "modal controller" is a smell. A modal is `dialog` + `focus-trap` +
   `dismiss` + `transition`. The vocabulary at the end of this document is the contract.

---

## Table of contents

- [Errata: where the received wisdom is now wrong](#errata-where-the-received-wisdom-is-now-wrong)
  - [Turbo attributes that no longer exist](#turbo-attributes-that-no-longer-exist)
  - [Turbo behaviors that surprise people](#turbo-behaviors-that-surprise-people)
  - [<dialog> facts that change the recommended decomposition](#dialog-facts-that-change-the-recommended-decomposition)
  - [Platform support, corrected against MDN BCD (2026-08)](#platform-support-corrected-against-mdn-bcd-2026-08)
  - [Ecosystem corrections](#ecosystem-corrections)
- [The zero-JS ledger (2026)](#the-zero-js-ledger-2026)
- [Overlays & disclosure](#overlays-disclosure)
  - [Modal dialog](#modal-dialog)
  - [Drawer / slideover](#drawer-slideover)
  - [Popover / tooltip](#popover-tooltip)
  - [Dropdown menu](#dropdown-menu)
  - [Context menu](#context-menu)
  - [Accordion / disclosure](#accordion-disclosure)
  - [Tabs (with URL state)](#tabs-with-url-state)
  - [Command palette (⌘K)](#command-palette-k)
  - [Deep-linking modal state / modal + back button](#deep-linking-modal-state-modal-back-button)
  - [Focus trap + modal a11y](#focus-trap-modal-a11y)
  - [Click-outside](#click-outside)
  - [Scroll lock](#scroll-lock)
- [Forms — flow, validation & submission](#forms-flow-validation-submission)
  - [Client-side validation vs. server round-trip](#client-side-validation-vs-server-round-trip)
  - [Inline field validation on blur](#inline-field-validation-on-blur)
  - [Form errors via Turbo Streams](#form-errors-via-turbo-streams)
  - [Dependent / cascading selects](#dependent-cascading-selects)
  - [Nested forms — dynamic add/remove fields (the cocoon replacement problem)](#nested-forms-dynamic-addremove-fields-the-cocoon-replacement-problem)
  - [Multi-step wizards](#multi-step-wizards)
  - [Autosave / debounced submit](#autosave-debounced-submit)
  - [Submit-on-change](#submit-on-change)
  - [Search-as-you-type with debouncing](#search-as-you-type-with-debouncing)
  - [Character counters](#character-counters)
  - [Dirty-form warnings](#dirty-form-warnings)
  - [Disable-while-submitting](#disable-while-submitting)
  - ["Add another" repeated sections](#add-another-repeated-sections)
  - [Form state across Turbo cache preview (the flash-of-old-form problem)](#form-state-across-turbo-cache-preview-the-flash-of-old-form-problem)
- [Forms — rich inputs & uploads](#forms-rich-inputs-uploads)
  - [Combobox / autocomplete / typeahead (server-backed)](#combobox-autocomplete-typeahead-server-backed)
  - [Tag / token input](#tag-token-input)
  - [File upload with progress (Active Storage direct upload)](#file-upload-with-progress-active-storage-direct-upload)
  - [Drag-and-drop upload](#drag-and-drop-upload)
  - [Image cropping](#image-cropping)
  - [Rich text (Trix / Action Text)](#rich-text-trix-action-text)
  - [Date & time pickers](#date-time-pickers)
  - [Range / slider](#range-slider)
  - [Masked inputs](#masked-inputs)
  - [Password strength](#password-strength)
  - [Star ratings](#star-ratings)
  - [Signature pads](#signature-pads)
  - [Color pickers](#color-pickers)
  - [Textarea autogrow](#textarea-autogrow)
  - [The wrapped-library teardown contract](#the-wrapped-library-teardown-contract)
- [Data display & collections](#data-display-collections)
  - [Streams vs. morphing: the decision rule for every list mutation](#streams-vs-morphing-the-decision-rule-for-every-list-mutation)
  - [Pagination with Turbo Frames](#pagination-with-turbo-frames)
  - ["Load more" button](#load-more-button)
  - [Infinite scroll](#infinite-scroll)
  - [Sortable table columns](#sortable-table-columns)
  - [Filterable / faceted tables](#filterable-faceted-tables)
  - [Inline editing of a cell / row](#inline-editing-of-a-cell-row)
  - [Bulk selection + bulk actions toolbar](#bulk-selection-bulk-actions-toolbar)
  - [Drag-and-drop reordering (SortableJS + position persistence)](#drag-and-drop-reordering-sortablejs-position-persistence)
  - [Kanban board](#kanban-board)
  - [Tree / nested list](#tree-nested-list)
  - [Virtualized long lists](#virtualized-long-lists)
  - [Charts (Chart.js via Stimulus)](#charts-chartjs-via-stimulus)
  - [Export triggers (CSV / PDF / XLSX)](#export-triggers-csv-pdf-xlsx)
  - [Data grid / spreadsheet editing](#data-grid-spreadsheet-editing)
  - [Empty states](#empty-states)
- [Feedback, state & real-time](#feedback-state-real-time)
  - [Toast / flash notifications](#toast-flash-notifications)
  - [Loading states & skeletons](#loading-states-skeletons)
  - [Busy indicators for frames (the complete selector & event map)](#busy-indicators-for-frames-the-complete-selector-event-map)
  - [Optimistic UI](#optimistic-ui)
  - [Progress bars for background jobs (determinate)](#progress-bars-for-background-jobs-determinate)
  - [Empty states](#empty-states-1)
  - [Custom confirmation dialogs (replacing data-turbo-confirm)](#custom-confirmation-dialogs-replacing-data-turbo-confirm)
  - [Undo (Gmail-style)](#undo-gmail-style)
  - [Choosing a cable backend (Solid Cable vs Redis vs AnyCable)](#choosing-a-cable-backend-solid-cable-vs-redis-vs-anycable)
  - [Live-updating lists](#live-updating-lists)
  - [Secure per-user broadcasting](#secure-per-user-broadcasting)
  - [Notification bell with unread count](#notification-bell-with-unread-count)
  - [Live chat](#live-chat)
  - [Typing indicators](#typing-indicators)
  - [Presence (who's online)](#presence-whos-online)
  - [Collaborative editing](#collaborative-editing)
  - [Live dashboards](#live-dashboards)
  - [Polling as the boring alternative](#polling-as-the-boring-alternative)
- [Navigation, layout & miscellany](#navigation-layout-miscellany)
  - [Scroll-position restoration](#scroll-position-restoration)
  - [Back-button correctness](#back-button-correctness)
  - [View Transitions API + Turbo](#view-transitions-api-turbo)
  - [Sidebar state persistence (data-turbo-permanent)](#sidebar-state-persistence-data-turbo-permanent)
  - [Sticky headers](#sticky-headers)
  - [Breadcrumbs](#breadcrumbs)
  - [Mobile nav (off-canvas drawer)](#mobile-nav-off-canvas-drawer)
  - [Layout shift & <turbo-frame> sizing](#layout-shift-turbo-frame-sizing)
  - [Clipboard copy](#clipboard-copy)
  - [Hotkeys](#hotkeys)
  - [Dark-mode toggle with persistence](#dark-mode-toggle-with-persistence)
  - [Click-outside](#click-outside-1)
  - [i18n in Stimulus](#i18n-in-stimulus)
  - [Lazy images](#lazy-images)
  - [Video players](#video-players)
  - [Maps](#maps)
  - [Print views](#print-views)
  - [Countdown timers](#countdown-timers)
  - [Self-updating relative timestamps](#self-updating-relative-timestamps)
  - [Click-to-reveal](#click-to-reveal)
  - [Filter chips](#filter-chips)
  - [Scroll-driven animations / reveal-on-scroll](#scroll-driven-animations-reveal-on-scroll)
  - [Idle / session timeout warning](#idle-session-timeout-warning)
  - [Offline / connection-lost banner](#offline-connection-lost-banner)
- [Prior-art inventory](#prior-art-inventory)
  - [Stimulus controller libraries](#stimulus-controller-libraries)
  - [Hotwire-specific gems](#hotwire-specific-gems)
  - [Commercial / curated component libraries](#commercial-curated-component-libraries)
  - [Web components worth preferring over Stimulus](#web-components-worth-preferring-over-stimulus)
  - [Supporting JS libraries commonly wrapped by Stimulus controllers](#supporting-js-libraries-commonly-wrapped-by-stimulus-controllers)
  - [Rails-side gems for the patterns](#rails-side-gems-for-the-patterns)
- [Primitive vocabulary used in this document](#primitive-vocabulary-used-in-this-document)
  - [Behavior primitives](#behavior-primitives)
  - [Widget primitives](#widget-primitives)
  - [Form primitives](#form-primitives)
  - [Collection primitives](#collection-primitives)
  - [Utility primitives](#utility-primitives)
  - [Conventions, not primitives](#conventions-not-primitives)
  - [Rejected / merged proposals](#rejected-merged-proposals)
  - [Drift to fix](#drift-to-fix)

---

## Summary table

`Needs JS?` is the column to read first. **No** = zero JavaScript. **Tiny** = one small generic
primitive from the shared vocabulary. **Yes** = meaningful bespoke Stimulus work. **Wrapped lib** =
a third-party library wrapped with the teardown contract. Roughly 40% of this catalog is `No`.

| Pattern | Primary tool | Needs JS? | Prior art | Difficulty |
|---|---|---|---|---|
| **Overlays & disclosure** | | | | |
| Modal dialog | Native `<dialog>` + Turbo Frame | Tiny | tailwindcss-stimulus-components, stimulus-components | Moderate |
| Drawer / slideover | Native `<dialog>` + Turbo Frame | Tiny | tailwindcss-stimulus-components | Easy |
| Popover / tooltip | Popover API + CSS anchor positioning | Tiny | floating-ui | Easy |
| Dropdown menu | Popover API + Stimulus | Tiny | @github/details-menu-element, stimulus-components | Moderate |
| Context menu | Popover API + Stimulus | Yes | roll your own | Moderate |
| Accordion / disclosure | Plain HTML/CSS | No | roll your own | Trivial |
| Tabs (with URL state) | Turbo Frame | Tiny | @github/tab-container-element, tailwindcss-stimulus-components | Easy |
| Command palette (⌘K) | Turbo Frame + Stimulus | Yes | @github/hotkey, hotwire_combobox | Moderate |
| Deep-linking modal state / modal + back button | Turbo Frame + Native `<dialog>` | Tiny | turbo-rails | Easy |
| Focus trap + modal a11y | Native `<dialog>` | No | focus-trap | Trivial |
| Click-outside | Popover API + Stimulus | Tiny | stimulus-use | Easy |
| Scroll lock | Stimulus | Tiny | body-scroll-lock | Moderate |
| **Forms — flow, validation & submission** | | | | |
| Client-side validation vs. server round-trip | Plain HTML/CSS | No | roll your own | Trivial |
| Inline field validation on blur | Turbo Stream + Stimulus | Tiny | roll your own | Easy |
| Form errors via Turbo Streams | Rails helper | No | turbo-rails | Easy |
| Dependent / cascading selects | Turbo Frame + Stimulus | Tiny | hotwire_combobox | Easy |
| Nested forms — dynamic add/remove fields | Stimulus | Yes | stimulus-components | Hard |
| Multi-step wizards | Turbo Frame + Rails helper | No | roll your own, AASM | Moderate |
| Autosave / debounced submit | Stimulus | Tiny | stimulus-components, stimulus-use | Moderate |
| Submit-on-change | Turbo Frame + Stimulus | Tiny | stimulus-components | Easy |
| Search-as-you-type with debouncing | Turbo Frame + Stimulus | Tiny | stimulus-components, stimulus-use | Easy |
| Character counters | Stimulus | Tiny | stimulus-components | Trivial |
| Dirty-form warnings | Stimulus | Yes | roll your own | Moderate |
| Disable-while-submitting | Rails helper | No | turbo-rails | Trivial |
| "Add another" repeated sections | Turbo Stream | No | stimulus-components | Easy |
| Form state across Turbo cache preview | Turbo Drive | No | turbo-rails | Easy |
| **Forms — rich inputs & uploads** | | | | |
| Combobox / autocomplete / typeahead (server-backed) | Gem | Wrapped lib | hotwire_combobox, Tom Select, Choices.js | Moderate |
| Tag / token input | Gem | No | ActsAsTaggableOn, hotwire_combobox | Easy |
| File upload with progress (Active Storage direct upload) | Rails helper + Stimulus | Tiny | Active Storage, Uppy | Moderate |
| Drag-and-drop upload | Stimulus | Yes | roll your own, Uppy | Moderate |
| Image cropping | Stimulus + lib | Wrapped lib | Cropper.js, image_processing | Moderate |
| Rich text (Trix / Action Text) | Rails helper | No | Action Text, Lexxy | Moderate |
| Date & time pickers | Plain HTML/CSS | No | Cally | Easy |
| Range / slider | Plain HTML/CSS | No | noUiSlider | Trivial |
| Masked inputs | Plain HTML/CSS | No | IMask, maska | Easy |
| Password strength | Stimulus + lib | Wrapped lib | zxcvbn-ts, devise-pwned_password | Moderate |
| Star ratings | Plain HTML/CSS | No | roll your own | Trivial |
| Signature pads | Stimulus + lib | Wrapped lib | signature_pad | Moderate |
| Color pickers | Plain HTML/CSS | No | roll your own | Trivial |
| Textarea autogrow | Plain HTML/CSS | No | roll your own | Trivial |
| **Data display & collections** | | | | |
| Streams vs. morphing: the decision rule | Turbo Stream + Morphing | No | turbo-rails | Easy |
| Pagination with Turbo Frames | Turbo Frame | No | pagy, kaminari | Trivial |
| "Load more" button | Turbo Stream | No | pagy | Easy |
| Infinite scroll | Turbo Frame + Stimulus | Tiny | pagy, stimulus-use | Hard |
| Sortable table columns | Turbo Frame + Rails helper | No | ransack | Easy |
| Filterable / faceted tables | Turbo Frame + Stimulus | Tiny | ransack, has_scope | Moderate |
| Inline editing of a cell / row | Turbo Frame | No | roll your own | Moderate |
| Bulk selection + bulk actions toolbar | Stimulus | Yes | stimulus-components | Moderate |
| Drag-and-drop reordering | Stimulus + lib | Wrapped lib | SortableJS, positioning | Hard |
| Kanban board | Stimulus + lib + Broadcast | Wrapped lib | SortableJS, positioning, turbo-rails | Hard |
| Tree / nested list | Plain HTML/CSS | No | ancestry, closure_tree | Easy |
| Virtualized long lists | Plain HTML/CSS | No | clusterize.js, pagy | Very hard |
| Charts (Chart.js via Stimulus) | Stimulus + lib | Wrapped lib | Chart.js, chartkick | Moderate |
| Export triggers (CSV / PDF / XLSX) | Rails helper | No | caxlsx_rails, grover | Moderate |
| Data grid / spreadsheet editing | Turbo Frame | No | AG Grid, Handsontable | Very hard |
| Empty states | Rails helper + Morphing | No | roll your own | Easy |
| **Feedback, state & real-time** | | | | |
| Toast / flash notifications | Turbo Stream + Stimulus | Tiny | roll your own | Moderate |
| Loading states & skeletons | Plain HTML/CSS | No | turbo-rails | Trivial |
| Busy indicators for frames | Plain HTML/CSS + Stimulus | Tiny | roll your own | Easy |
| Optimistic UI | Stimulus | Yes | roll your own | Hard |
| Progress bars for background jobs | Broadcast | No | noticed, turbo_power | Easy |
| Custom confirmation dialogs | Native `<dialog>` + Stimulus | Yes | roll your own | Moderate |
| Undo (Gmail-style) | Gem + Turbo Stream | Tiny | discard, paper_trail | Easy |
| Choosing a cable backend | ActionCable | No | Solid Cable, AnyCable | Easy |
| Live-updating lists | Broadcast + Morphing | No | turbo-rails | Easy |
| Secure per-user broadcasting | Broadcast + Rails helper | No | turbo-rails, AnyCable | Moderate |
| Notification bell with unread count | Broadcast + Gem | Tiny | noticed | Moderate |
| Live chat | Broadcast + Stimulus | Yes | roll your own | Hard |
| Typing indicators | ActionCable | Yes | roll your own | Hard |
| Presence (who's online) | ActionCable | Yes | AnyCable, Kredis | Hard |
| Collaborative editing | Rails helper | No | yrb-actioncable | Hard |
| Live dashboards | Broadcast + Morphing | No | chartkick, Groupdate | Moderate |
| Polling as the boring alternative | Turbo Frame + Stimulus | Tiny | roll your own | Easy |
| **Navigation, layout & miscellany** | | | | |
| Scroll-position restoration | Turbo Drive | No | turbo-rails | Moderate |
| Back-button correctness | Turbo Drive | No | turbo-rails | Moderate |
| View Transitions API + Turbo | Turbo Drive | No | turbo-rails | Easy |
| Sidebar state persistence (`data-turbo-permanent`) | Rails helper + Stimulus | Tiny | roll your own | Moderate |
| Sticky headers | Plain HTML/CSS | No | roll your own | Trivial |
| Breadcrumbs | Rails helper | No | gretel | Trivial |
| Mobile nav (off-canvas drawer) | Native `<dialog>` + Stimulus | Tiny | tailwindcss-stimulus-components | Moderate |
| Layout shift & `<turbo-frame>` sizing | Plain HTML/CSS | No | roll your own | Trivial |
| Clipboard copy | Stimulus | Tiny | @github/clipboard-copy-element, stimulus-components | Easy |
| Hotkeys | Stimulus + lib | Wrapped lib | @github/hotkey, stimulus-use | Easy |
| Dark-mode toggle with persistence | Rails helper + Stimulus | Tiny | roll your own | Moderate |
| Click-outside (cross-ref) | Popover API + Stimulus | Tiny | stimulus-use | Easy |
| i18n in Stimulus | Rails helper | No | i18n-js | Easy |
| Lazy images | Plain HTML/CSS | No | roll your own | Trivial |
| Video players | Plain HTML/CSS | No | hls.js, video.js | Moderate |
| Maps | Stimulus + lib | Wrapped lib | MapLibre GL JS, Leaflet, mapkick-rb | Moderate |
| Print views | Plain HTML/CSS | Tiny | grover, ferrum | Trivial |
| Countdown timers | Stimulus | Tiny | roll your own | Easy |
| Self-updating relative timestamps | Web component | Tiny | @github/relative-time-element | Trivial |
| Click-to-reveal | Stimulus | Tiny | stimulus-components | Trivial |
| Filter chips | Rails helper | No | roll your own | Trivial |
| Scroll-driven animations / reveal-on-scroll | Plain HTML/CSS + Stimulus | Tiny | stimulus-use | Easy |
| Idle / session timeout warning | Stimulus + lib | Wrapped lib | stimulus-use | Moderate |
| Offline / connection-lost banner | Stimulus | Yes | roll your own | Moderate |

### Patterns where Hotwire has no good answer

Seven honest gaps. Everything else in this catalog has a recommendation worth defending.

- **Virtualized long lists** — True windowed virtualization (recycled DOM nodes for a slice of the
  list) fights Turbo's "server owns the DOM" model head-on: Streams and morphing target elements a
  virtualizer may not have rendered. Ship pagination or "load more"; use `content-visibility: auto`
  for the 500-5,000 row middle case; fence a third-party grid off from Turbo only if the list truly
  must be virtualized.
- **Data grid / spreadsheet editing** — A real spreadsheet needs arrow-key cell navigation,
  undo/redo, fill-down, formulas, and sub-100ms optimistic feedback: a rich client-side model the
  server confirms asynchronously, the exact inverse of Turbo's philosophy. Ship a sortable/filterable
  table with per-cell frame editing, or embed AG Grid / Handsontable as an island outside Turbo's
  control.
- **Optimistic UI** — Hotwire gives exactly one reconciliation guarantee (dedupe-by-`id` on
  `append`/`prepend`) and no rollback or in-flight-mutation registry. Binary toggles are fine by
  hand; anything the server computes (a position, a total, a derived status) means writing your own
  revert logic. Spend the effort on a fast round-trip and a pending style instead.
- **Collaborative editing (character-level)** — Needs a CRDT and a persistent binary transport that
  a `<turbo-stream>` DOM patch cannot express. Optimistic locking (`lock_version`) plus a conflict
  banner covers "two people editing different fields" well; real co-editing means bolting Yjs onto
  Rails via `yrb-actioncable` and accepting that the screen is a separate client app.
- **Typing indicators** — Ephemeral, high-frequency, per-user state must never touch the database or
  become a rendered-HTML broadcast. The honest answer is to drop below Turbo Streams to a raw
  ActionCable channel (or AnyCable whispers) with client-side TTL expiry.
- **Infinite scroll (back-button state)** — Loading more works fine; restoring the loaded-page state
  after Back does not. Turbo's snapshot cache is a 10-entry LRU that **any** successful non-GET form
  submission clears entirely. Encode the cursor in the URL, or default to "load more", which
  sidesteps the problem.
- **Kanban concurrent drags** — Hotwire yields a board that is eventually consistent and never
  corrupt, but ships no conflict resolution for two users dragging at once. Sending relative intent
  (`position: { after: card_id }`) plus optimistic locking covers a normal working day; CRDT-grade
  concurrent-drag resolution is out of scope.

---
## Errata: where the received wisdom is now wrong

Every claim below was verified against source (Turbo 8.0.23 dist, `hotwired/turbo` `main`, Rails
`main`, MDN browser-compat-data, or the package's own source) during the research for this document,
because each contradicts advice that is still widely repeated in Rails tutorials and LLM output.
Where a record in this catalog depends on one of these, it says so locally too.

### Turbo attributes that no longer exist

| Thing people write | Reality |
|---|---|
| `data-turbo-cache="false"` on an element | **Removed.** Deprecated in Turbo 7.3.0 ([#871](https://github.com/hotwired/turbo/pull/871)), removed in 8.0.21 ([#1470](https://github.com/hotwired/turbo/pull/1470), Nov 2025). `CacheObserver` in 8.0.23 knows only `[data-turbo-temporary]`. Page-level `<meta name="turbo-cache-control">` is unaffected. |
| `data-turbo-morph="false"` | **Never existed.** The only morph opt-outs are `data-turbo-permanent` and `preventDefault()` on `turbo:before-morph-element` / `turbo:before-morph-attribute`. |
| `Turbo.clearCache()`, `Turbo.setProgressBarDelay()`, `Turbo.setConfirmMethod()`, `Turbo.setFormMode()` | Pre-Turbo-8. Use `Turbo.cache.clear()` and `Turbo.config.*`. Their presence dates a tutorial to before 2024. |
| `data-direct-upload-token`, `data-direct-upload-attachment-name` | **Do not exist.** `direct_upload: true` emits only `data-direct-upload-url` (plus `data-checksum-algorithm` on Rails 8.2/main). |

### Turbo behaviors that surprise people

- **Morphing overwrites what the user is currently typing.** Turbo passes only `callbacks` to
  `Idiomorph.morph`, so `ignoreActiveValue` stays `false` and the focused input's `value` is reset
  from the response. Focus and selection range *are* restored (`restoreFocus: true`) — **but only if
  the element has an `id`.** The same `id` requirement governs focus preservation across ordinary
  Turbo Stream renders. "Give every filter and search control a stable `id`" is a hard requirement,
  not hygiene.
- **Preserved scroll and per-filter history entries are mutually exclusive in Turbo 8.** The same
  gate in `page_view.js` controls both morphing and scroll preservation: `isPageRefresh` requires
  `visit.action === "replace"`. So a filter form can have `data-turbo-action="replace"` + preserved
  scroll, or `advance` + back-button history, not both.
- **Frame navigation with `data-turbo-action="advance"` does not scroll the page.** The visit is
  built with `willRender: false` and `Visit` sets `scrolled = !willRender`, making `performScroll()`
  a no-op. Opt in with the frame's `autoscroll` attribute plus `data-autoscroll-block` /
  `data-autoscroll-behavior`.
- **Any successful non-GET form submission clears the entire Turbo snapshot cache**
  (`session.clearCache()`). This is the real reason "back after submitting loses my infinite-scroll
  pages" — the cache is also only a 10-entry LRU.
- **`@view-transition { navigation: auto; }` does nothing under Turbo.** That at-rule opts into
  *cross-document* transitions; Turbo intercepts navigation and uses same-document
  `document.startViewTransition`. Only `<meta name="view-transition" content="same-origin">` matters.
- **A 422 `turbo_stream` response applies normally** — `fetchResponseIsStream` checks content type
  only, never status.
- **`turbo:submit-end` fires before `turbo:before-visit`** on a post-save redirect. That ordering is
  what makes a dirty-form guard workable.
- **`data-turbo-confirm` is silently ignored on a plain `<a href>`.** `FormLinkClickObserver`
  synthesizes a form only when the link also carries `data-turbo-method` or `data-turbo-stream`, and
  the confirm is read inside `FormSubmission#start`. A confirm on a bare link does nothing at all —
  no error, no dialog. Verified signature:
  `(message, formElement, submitter) => Promise<boolean> | boolean`, submitter attribute beating form.
- **The exact busy contract** (`src/util.js`): `markAsBusy` sets the `busy` attribute **only** on
  `<turbo-frame>`, and `aria-busy="true"` on everything. `<html>` gets it on Drive visits *except*
  `data-turbo-stream` visits; `<form>` gets it during submit; on a form submit **both the ancestor
  and the target frame** are marked. `<turbo-frame complete>` is set after a successful render, so
  `turbo-frame[src]:not([complete])` is a valid "never loaded yet" CSS hook.

### `<dialog>` facts that change the recommended decomposition

- **`showModal()` makes the rest of the document inert.** A button outside an open modal cannot take
  focus even programmatically. A `focus-trap` primitive is therefore **dead weight for `<dialog>`
  modals** — it is only needed for non-`<dialog>` overlays.
- **Scroll lock is genuinely not free.** With a modal `<dialog>` open the page behind still scrolls
  on wheel; the WHATWG UA stylesheet has no scroll-blocking rule and
  [whatwg/html#7732](https://github.com/whatwg/html/issues/7732) has been open since 2022.
- **Stripping the `open` attribute from a modal `<dialog>` inert-locks the whole page.** The element
  goes `display:none` but stays `:modal`, and `close()` becomes a silent no-op; recovery needs
  `setAttribute("open",""); close()`. Idiomorph gives `open` no special treatment (only
  `value`/`checked`/`disabled`/`selected` get live-property handling), so a morph can trigger this.
  *Removing* the element releases the top layer cleanly — which is why `turbo_stream.update "modal", ""`
  is the safe close idiom. The same gap means **morphing closes user-opened `<details>` accordions.**

### Platform support, corrected against MDN BCD (2026-08)

| Feature | Status | Consequence |
|---|---|---|
| CSS anchor positioning | Baseline Jan 2026 (Chrome, FF 147, Safari 26) | Anchored popovers/tooltips are genuinely zero-JS now. |
| `command` / `commandfor` | Chrome 135, FF 144, Safari 26.2 | Declarative, zero-JS dialog opening is real. |
| `closedby="any"` | Chrome 134, FF 141, **Safari TP only** | Light-dismiss still needs the backdrop-click fallback. |
| `interpolate-size: allow-keywords`, `calc-size()` | **Chrome only** | "Animate an accordion to `height:auto` with no JS" is Chrome-only progressive enhancement. |
| `overlay` (top-layer transitions) | **Chrome only** | Top-layer exit animations degrade elsewhere. |
| `field-sizing: content` | Chrome 123, FF 152, Safari 26.2 | Textarea autogrow is now a no-JS pattern. |
| `:user-invalid` / `:user-valid` | Baseline since Nov 2023 | Safe unguarded; this is the 2026 answer to "only go red after they've touched it". |
| Scroll-driven animations (`animation-timeline`) | Baseline **Limited** — Chrome 115+, Safari 26+, **no Firefox** | Keep `@supports`-gated with `intersection` as the real fallback. |
| `content-visibility: auto` | Chrome 85, FF 125, Safari 18 | Safe — but a **no-op on `<tr>`/`<tbody>`**, since containment doesn't apply to internal table elements. |
| `<input type=color>` `alpha` / `colorspace` | **Safari 18.4 only** | Don't rely on it. |

### Ecosystem corrections

- **Pagy 43.6.1 is a total API redesign.** `include Pagy::Method`;
  `@pagy, @records = pagy(:offset, scope, limit: 25)`; helpers are instance methods on `@pagy`
  (`series_nav`, `info_tag`, `page_url(:next)`) rendered with `<%== %>`. `Pagy::Backend`,
  `Pagy::Frontend`, `pagy_nav`, and the whole extras system are **gone** — so every pagy tutorial
  ever written is stale. Kaminari 1.2.2 is the conservative pick.
- **`rich_text_area` was renamed `rich_textarea` in Rails 8.0** (old name kept as an alias; the test
  helper is `fill_in_rich_textarea`).
- **The 2026 rich-text story is Lexxy, not Trix.** Basecamp's Lexical-based editor takes over Action
  Text automatically. Rails 8.2 adds a pluggable `ActionText::Editor` adapter API.
- **The Trix-under-morphing bug is fixed upstream** ([basecamp/trix#1227](https://github.com/basecamp/trix/pull/1227),
  shipped in Trix 2.1.13). The `turbo:before-morph-attribute` workarounds circulating from
  turbo-rails#533 are now stale advice.
- **`@stimulus-components/sortable` uses per-item `data-sortable-update-url`**, not a
  `data-sortable-url-value` on the container, and hooks `onUpdate` — which never fires for cross-list
  moves, so it cannot drive a Kanban board unaided.
- **`stimulus_reflex` / `cable_ready` are in maintenance mode** — only dependency bumps since Jan
  2026. Their `morphdom`-based morphing is architecturally separate from Turbo 8's `idiomorph`.
- **`wkhtmltopdf` is archived**, so `wicked_pdf` wraps a dead binary with no README warning. Use
  Grover/Puppeteer or Prawn.
- **Dead or archived, don't reach for these:** cocoon (last release 2020), `nested_form_fields`
  (2020), Duet and Easepick date pickers (archived), Dropzone.js (stuck at a 2021 beta),
  flatpickr (2022, 855 open issues), `@github/details-dialog-element` (deprecated by GitHub, citing
  the scroll-lock gap), PhlexUI (domain now squatted), best_in_place, wice_grid, select2-rails.
- **There is no maintained "flash over Turbo Streams" gem.** `joshmn/turbo_flash` has been stale
  since 2023 and the alternatives are toys. Write the ~40-line concern; the Toast record has it.
- **Solid Cable has a hard latency floor.** It polls (`polling_interval: 0.1s`,
  `SELECT id > last_id` + `sleep`) with **no LISTEN/NOTIFY**. Its own benchmarks: p95 234ms at 250
  VUs vs Redis 135ms; SQLite peaks at 5.19s at 750 VUs. Fine for dashboards and notifications, wrong
  for chat and typing indicators. AnyCable's presence support is **OSS, not Pro-gated**
  (`--presence_ttl`, 15s default), and its whispers solve typing indicators without touching the DB.
- **The optimistic-UI trick nobody documents:** Turbo's `append`/`prepend` call
  `removeDuplicateTargetChildren()`, matching on the `id` of direct children. ONCE Campfire exploits
  this by overriding `to_key` so `dom_id` is *client*-generated — the server's broadcast then
  collapses the optimistic node instead of duplicating it. That is the entire reconciliation story.
- **APG is explicit that `role="menu"` is not for navigation link lists** — its Disclosure Navigation
  example says so directly. Most Rails dropdown tutorials get this backwards.

## The zero-JS ledger (2026)

Which of these overlays need no JavaScript at all, verified against MDN browser-compat-data and (where noted) tested in Chrome 151 on 2026-08-15.

| Pattern | JS needed in 2026? | What supplies the behaviour |
|---|---|---|
| **Accordion / disclosure** | **None.** | `<details>`/`<summary>` + `name=` (Chrome 120 / FF 130 / Safari 17.2) + `::details-content` (Chrome 131 / FF 143 / Safari 18.4). Height animation (`interpolate-size`) is **Chrome-only** — degrades to a snap. |
| **Popover** | **None** for open/close/dismiss/position. | `popover="auto"` + `popovertarget` (Chrome 114 / FF 125 / Safari 17); anchor positioning (Chrome 125 / Safari 26 / **FF 147**, Baseline Jan 2026). |
| **Dropdown (navigation links)** | **None.** | Same as popover. Arrow keys are not required for a link list. |
| **Drawer/modal open trigger** | **None**, if the content is already in the page. | `<button command="show-modal" commandfor="…">` (Chrome 135 / FF 144 / Safari 26.2). Cannot also navigate a Turbo Frame — that still needs a link. |
| **Modal light dismiss** | **None** on Chrome/Firefox; a 4-line fallback on Safari. | `closedby="any"` (Chrome 134 / FF 141 / **Safari: Technology Preview only**). |
| **Modal focus trap** | **None, ever.** | `showModal()` makes the rest of the document inert (spec + verified). Delete your `focus-trap`. |
| **Enter/exit animation for any top-layer element** | **None.** | `@starting-style` (Chrome 117 / FF 129 / Safari 17.5) + `transition-behavior: allow-discrete` (Chrome 117 / FF 129 / Safari 17.4). The `overlay` property is Chrome-only; exit transitions are slightly degraded elsewhere. |
| **Tabs with URL state** | **None** beyond optional arrow keys. | Turbo Frame + `data-turbo-action="advance"`; the server renders `aria-selected`. |
| **Modal open/close lifecycle with a Turbo Frame** | ~25 lines (`dialog`). | `showModal()` on connect + `turbo:before-cache` cleanup. Irreducible. |
| **Scroll lock** | ~20 lines (`scroll-lock`). | **Not free.** whatwg/html#7732 open since 2022; verified: the page scrolls behind an open modal. |
| **Dropdown (command menu, `role=menu`)** | `roving-focus`. | The Popover API supplies everything except arrow keys/typeahead. |
| **Tooltip** | small controller, or skip on touch. | `interestfor` would make this zero-JS but is **Chrome 142 only**. `popover="hint"` is Chrome/Firefox only. |
| **Command palette** | `hotkey` + `autosubmit` + `roving-focus`. | The dialog and the ⌘K binding can be declarative; debounced server search cannot. |

Two claims worth repeating because they invert common advice: **stop shipping focus traps for modals** (the platform does it, correctly, and your version is worse), and **keep shipping scroll locks** (the platform still doesn't, despite four years of the issue being open).



## Overlays & disclosure

### Modal dialog

**Hotwire answer.** A **persistent, empty `<turbo-frame id="modal">` in the layout**, lazily filled by any link carrying `data-turbo-frame="modal"`, whose response renders a **native `<dialog>`** that a generic `dialog` controller `showModal()`s on connect. Closing is a *server* concern: `turbo_stream.update "modal", ""` (stay on the page) or a redirect with the form targeting `_top` (leave the page). The only JavaScript you own is a ~25-line generic `dialog` primitive; everything else — top layer, backdrop, Esc, focus containment, focus restore — is the browser. Do **not** hand-roll a `div.modal` + `focus-trap` + `click-outside` stack in 2026.

**Code.**

```erb
<%# app/views/layouts/application.html.erb — ONE always-present, empty frame %>
<%= turbo_frame_tag "modal" %>
```

```erb
<%# anywhere on the page %>
<%= link_to "New post", new_post_path, data: { turbo_frame: "modal" } %>
```

```erb
<%# app/views/posts/new.html.erb — a real, standalone route that ALSO renders as a modal %>
<%= turbo_frame_tag "modal" do %>
  <dialog data-controller="dialog"
          data-action="click->dialog#backdropClose close->dialog#onClose"
          closedby="any"
          aria-labelledby="modal_title">
    <div class="dialog__body">          <%# padding lives HERE, not on <dialog> — see Pitfalls %>
      <h2 id="modal_title">New post</h2>
      <%= form_with model: @post, data: { turbo_frame: "modal" } do |f| %>
        <%= f.text_field :title %>
        <%= f.submit "Create" %>
      <% end %>
      <%= link_to "Cancel", posts_path, data: { turbo_frame: "modal" } %>
    </div>
  </dialog>
<% end %>
```

```js
// app/javascript/controllers/dialog_controller.js — the `dialog` primitive
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { modal: { type: Boolean, default: true } }

  connect() {
    this.modalValue ? this.element.showModal() : this.element.show()
    this.beforeCache = () => this.forceClose()
    document.addEventListener("turbo:before-cache", this.beforeCache)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.beforeCache)
  }

  close() { this.element.close() }

  // Fallback light-dismiss for browsers without closedby="any" (Safari, as of 2026-08).
  backdropClose(event) {
    if (event.target !== this.element) return              // clicks inside bubble up from children
    if (getSelection().toString().length > 0) return       // don't close on drag-select
    this.element.close()
  }

  onClose() { this.dispatch("closed") }

  // A modal whose `open` attribute was stripped is invisible but STILL blocks the page,
  // and close() is a no-op in that state. Re-add `open`, then close properly.
  forceClose() {
    if (!this.element.open) this.element.setAttribute("open", "")
    this.element.close()
  }
}
```

```ruby
# app/controllers/posts_controller.rb
def create
  @post = Post.new(post_params)
  if @post.save
    respond_to do |format|
      format.turbo_stream          # create.turbo_stream.erb — closes the modal, updates the page
      format.html { redirect_to posts_path, status: :see_other }
    end
  else
    # MUST re-render the same frame id, MUST be 422, or Turbo discards the response.
    render :new, status: :unprocessable_content
  end
end
```

```erb
<%# app/views/posts/create.turbo_stream.erb %>
<%= turbo_stream.update "modal", "" %>   <%# removes the <dialog> from the DOM => releases top layer %>
<%= turbo_stream.prepend "posts", @post %>
```

**Why native `<dialog>` wins, precisely.** `showModal()` gives you, for free and correctly:

| Behaviour | Free with `showModal()`? | Evidence |
|---|---|---|
| Top layer (renders above everything, no `z-index` war) | yes | [WHATWG rendering UA sheet](https://html.spec.whatwg.org/multipage/rendering.html) — `dialog:modal { position: fixed; … }` |
| `::backdrop` pseudo-element | yes | same UA sheet |
| Esc closes; only the topmost dialog closes | yes | [MDN `<dialog>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/dialog) |
| Everything outside the dialog is **inert** (not focusable, not clickable, hidden from AT) | **yes** | spec: the document is [*blocked by a modal dialog*](https://html.spec.whatwg.org/multipage/interaction.html#modal-dialogs-and-inert-subtrees). Verified in Chrome 151: a `<button>` outside an open modal cannot take focus. |
| Initial focus on first focusable child / `[autofocus]` | yes | MDN |
| Focus **restored to the invoker** on close | yes | part of the dialog close algorithm |
| Light dismiss (click outside) | `closedby="any"` only | Chrome 134+, Firefox 141+; **Safari: Technology Preview only** as of 2026-08 ([MDN BCD `html.elements.dialog.closedby`](https://github.com/mdn/browser-compat-data/blob/main/html/elements/dialog.json)) |
| **Scroll lock** | **NO** | Verified in Chrome 151: the page behind an open modal still scrolls on wheel; `documentElement` `overflow` stays `visible`. Still an open spec issue: [whatwg/html#7732](https://github.com/whatwg/html/issues/7732), open since 2022. Also called out in the deprecation notice for [@github/details-dialog-element](https://github.com/github/details-dialog-element). |

So: **`focus-trap` is dead weight for a modal `<dialog>`** — do not ship one. **`scroll-lock` is still yours to write.** (Tab does escape into browser chrome — URL bar, tabs — and then returns into the dialog. That is correct behaviour, not a bug; a JS focus trap that prevents it is *worse* than the native one.)

**How to close it — pick by intent.**

| Intent | Idiom |
|---|---|
| Create/update succeeded, user stays where they were | `turbo_stream.update "modal", ""` + the streams that reflect the change. The `<dialog>` element is *removed from the DOM*, which releases the top layer cleanly (verified in Chrome 151). |
| Create succeeded, user should go to the new record | `form_with … data: { turbo_frame: "_top" }` + `redirect_to @post, status: :see_other`. The whole page navigates; the modal ceases to exist. |
| Turbo 8 morphing is on and the change is "this page, but with new data" | `turbo_stream.update "modal", ""` + `turbo_stream.refresh`. Do **not** hand-write five stream actions for the list behind the modal — see [02-turbo-deep-dive §5.7](../notes/02-turbo-deep-dive.md). |
| User cancelled | A `link_to` back to the index targeting the `modal` frame (its response contains an empty `<turbo-frame id="modal">`), or `<form method="dialog"><button>Cancel</button></form>` for a pure-client close. |

**Validation errors — the part everyone gets wrong.** Two conditions, both mandatory:

1. **`status: :unprocessable_content`** (422). Turbo only renders a form-submission response body on a 4xx/5xx; a 200 is treated as "success, nothing to render". (Never write `:unprocessable_entity` in new code — Rack 3.1 deprecated alias.)
2. **The re-rendered `new.html.erb` must still be wrapped in `<turbo-frame id="modal">`.** If your error render escapes the frame, you get `Content missing` and a thrown `TurboFrameMissingError` — see [02-turbo-deep-dive §3.6](../notes/02-turbo-deep-dive.md). If the form targets `_top`, errors re-render the *whole page*, not the modal — which is why the form above carries `data: { turbo_frame: "modal" }` explicitly even though it is already inside the frame (the explicit attribute survives the form being extracted into a partial shared with the standalone page).

**Deep-linking.** Put `data: { turbo_action: "advance" }` on the frame or the link so `/posts/new` lands in the address bar and Back closes the modal. Requires `/posts/new` to render sensibly as a full page — it does here, because `new.html.erb` is a real route. See pattern *Deep-linking modal state* below and [02-turbo-deep-dive §3.4](../notes/02-turbo-deep-dive.md).

**Variant worth knowing (animation-first).** Invert it: put a *persistent* `<dialog>` in the layout with the frame **inside** it, per [Rails Designer, "Use native dialog with Turbo (and no extra JavaScript)", Jan 2026](https://railsdesigner.com/dialog-turboframe/):

```erb
<dialog id="overlay" closedby="any" class="… starting:opacity-0 starting:scale-95 transition-all duration-300 backdrop:bg-black/50">
  <%= tag.turbo_frame id: :modal %>
</dialog>
```

Because the `<dialog>` node is never destroyed, `@starting-style` enter **and exit** animations work with zero JS timing hacks, and one dialog serves modal + drawer by swapping a `type` attribute. Cost: opening requires an action on the link (`data-action="dialog#showModal"`), the URL is no longer the modal's identity, and the modal route is no longer standalone-renderable. Use it when animation polish matters more than deep-linking. In 2026 the open trigger can even be declarative — `<button command="show-modal" commandfor="overlay">` (Chrome 135+, Firefox 144+, Safari 26.2+) — but a `<button command>` cannot also navigate a Turbo Frame, so you still need the link.

**Decomposition.** `dialog` + `transition` + `scroll-lock`. **Not** `focus-trap` (free via `showModal()`), **not** `click-outside`/`dismiss` where `closedby="any"` is available.

**A11y.** [APG Dialog (Modal)](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/). `<dialog>` maps to `role="dialog"` + `aria-modal="true"` automatically — **do not add either by hand**. Required of you: `aria-labelledby` pointing at the dialog's heading (or `aria-label`), and a visible, keyboard-reachable close control. Keyboard: Esc closes (free), Tab/Shift+Tab cycle within (free), focus returns to the invoker (free). Set `autofocus` on the field you want focused first — otherwise the browser picks the first focusable child, which is often a close "×".

**Native.** Modals belong in path configuration, not in your ERB: `{"patterns": ["/new$", "/edit$"], "properties": {"context": "modal"}}` presents the screen as a native sheet, and the web `<dialog>` chrome must then be suppressed (Hotwire Native adds a `turbo-native` class / `Turbo::Native::Navigation#turbo_native_app?` is available server-side). Closing the modal *and* refreshing the screen underneath cannot be done with a Turbo Stream — the modal is a **separate web view**. Use `refresh_or_redirect_to items_path`. See [04-hotwire-native §2, §6.4, §G6](../notes/04-hotwire-native.md).

**Pitfalls.**
- **The morph/stream trap.** Anything that strips the `open` attribute from a modal `<dialog>` — an idiomorph attribute sync, a careless `turbo_stream.replace` of an ancestor — leaves the dialog `display: none` **but still in the top layer**, so the entire page becomes inert and unclickable, and `close()` silently no-ops. Verified in Chrome 151. Recovery is `el.setAttribute("open",""); el.close()`. Idiomorph has no special-casing for `open` ([`morphAttributes` in idiomorph.js](https://github.com/bigskysoftware/idiomorph/blob/main/src/idiomorph.js) syncs every attribute; only `value`/`checked`/`disabled`/`selected` get live-property treatment). *Removing* the whole element is safe — the top layer is released. Prefer `turbo_stream.update "modal", ""` over anything that edits the dialog in place.
- **Turbo Drive snapshot caching re-opens your modal.** Navigate away with the dialog open, come back, and the cached preview flashes it open. Fix in the controller's `turbo:before-cache` handler (shown above) — see [02-turbo-deep-dive §2.6](../notes/02-turbo-deep-dive.md). Both [tailwindcss-stimulus-components](https://github.com/excid3/tailwindcss-stimulus-components/blob/master/src/modal.js) and [stimulus-components/dialog](https://github.com/stimulus-components/stimulus-components/blob/main/components/dialog/src/index.ts) do exactly this (the latter on `turbo:before-render`).
- **Backdrop-click detection breaks the moment `<dialog>` has padding.** `event.target === dialog` is true when you click the dialog's own padding box — so a click *inside* the visible card closes it. Fix: `padding: 0` on `<dialog>`, put padding on an inner wrapper (as in the code above); or just use `closedby="any"`.
- **Drag-selecting text out of the dialog fires a backdrop click.** Guard with `getSelection().toString().length` (both libraries above do).
- **Redirects inside a frame produce `Content missing`.** A form inside `<turbo-frame id="modal">` that redirects to `posts_path` will look for `<turbo-frame id="modal">` in the *index* page. It's there (empty, from the layout), so this actually works — but only because the layout has the frame. Remove the layout frame and this breaks. Prefer the explicit stream or `_top`.
- **Nested modal-in-modal.** Works (top layer stacks, Esc pops one at a time) but you need a second frame id; one shared `modal` frame cannot hold two.
- **`<dialog>` doesn't lock scroll** — the page behind scrolls under your fingers on mobile. See the *Scroll lock* record.
- **Don't put `data-turbo-permanent` on the modal frame.** It would make the frame's contents un-updatable from the server, which is the one thing the pattern depends on. See [02-turbo-deep-dive §2.7](../notes/02-turbo-deep-dive.md).

**Prior art.**
- [tailwindcss-stimulus-components `modal.js`](https://github.com/excid3/tailwindcss-stimulus-components/blob/master/src/modal.js) — native `<dialog>`, `turbo:before-cache` close, `getAnimations()`-based exit animation. Closest to what you want.
- [stimulus-components `dialog`](https://github.com/stimulus-components/stimulus-components/tree/main/components/dialog) / [docs](https://www.stimulus-components.com/docs/stimulus-dialog/) — same shape, closes on `turbo:before-render`.
- [Rails Designer — "Use native dialog with Turbo (and no extra JavaScript)" (2026-01-08)](https://railsdesigner.com/dialog-turboframe/) — the `closedby="any"` + `@starting-style` + persistent-dialog variant. Current.
- [Rails Designer — "How to create Modals with Rails and Hotwire" (2024)](https://railsdesigner.com/modal-with-rails-hotwire/) — **STALE**: `div[role=dialog]` + a hand-rolled backdrop `button_to` + a `modal` controller that resets `frame.src` in `disconnect()`. Everything it hand-rolls is now native. Its one still-useful idea is the `Frameable` concern (`redirect_to root_path unless turbo_frame_request?`) to force a view to be modal-only.
- [Rails Designer components — modals](https://railsdesigner.com/components/modals/), [railsblocks.com](https://railsblocks.com/) — paid component libraries.
- [WICG/inert](https://github.com/WICG/inert), [focus-trap](https://github.com/focus-trap/focus-trap) — **superseded for this use case.** Only relevant for non-`<dialog>` overlays.

---

### Drawer / slideover

**Hotwire answer.** The exact same machinery as the modal — a `<dialog>` in a Turbo Frame driven by the `dialog` primitive — with different CSS. A drawer is not a different component; it is a `<dialog>` pinned to one edge. All the enter/exit animation is **pure CSS in 2026** (`@starting-style` + `transition-behavior: allow-discrete`), no JS timing hacks, no `setTimeout`, no `transitionend` listeners.

**Code.**

```css
/* app/assets/stylesheets/drawer.css — a <dialog> as a right-hand drawer */
dialog.drawer {
  /* override the UA `dialog:modal` box */
  margin: 0 0 0 auto;                 /* pin right; use `margin-right: auto` for left */
  inset-block: 0;
  height: 100dvh;
  max-height: none;
  width: min(28rem, 100vw);
  max-width: none;
  padding: 0;                          /* padding on an inner wrapper — see modal pitfalls */
  border: 0;

  translate: 0 0;
  opacity: 1;
  transition:
    translate 250ms ease,
    opacity 250ms ease,
    overlay 250ms allow-discrete,      /* Chrome-only; harmless elsewhere */
    display 250ms allow-discrete;      /* keeps it rendered through the exit transition */
}

/* enter: the state the element transitions FROM on first render / display:none -> block */
@starting-style {
  dialog.drawer[open] { translate: 100% 0; opacity: 0; }
}

/* exit: the state it transitions TO, matched because [open] is gone but display is still animating */
dialog.drawer:not([open]) { translate: 100% 0; opacity: 0; }

dialog.drawer::backdrop {
  background: rgb(0 0 0 / 0.4);
  opacity: 1;
  transition: opacity 250ms ease, display 250ms allow-discrete, overlay 250ms allow-discrete;
}
@starting-style { dialog.drawer[open]::backdrop { opacity: 0; } }
dialog.drawer:not([open])::backdrop { opacity: 0; }

/* mobile: same dialog, bottom sheet */
@media (max-width: 640px) {
  dialog.drawer { margin: auto 0 0 0; width: 100vw; height: min(85dvh, 100dvh); }
  @starting-style { dialog.drawer[open] { translate: 0 100%; } }
  dialog.drawer:not([open]) { translate: 0 100%; }
}
```

```erb
<%= turbo_frame_tag "drawer" do %>
  <dialog class="drawer" data-controller="dialog"
          data-action="click->dialog#backdropClose" closedby="any"
          aria-labelledby="drawer_title">
    <div class="drawer__body">
      <h2 id="drawer_title"><%= @filter_set.name %></h2>
      <%= render "filters/form", filter_set: @filter_set %>
    </div>
  </dialog>
<% end %>
```

**Browser support, verified.** `@starting-style` — Chrome 117, Firefox 129, Safari 17.5. `transition-behavior: allow-discrete` — Chrome 117, Firefox 129, Safari 17.4. Both **Baseline widely available**; ship them unguarded. The `overlay` property is **Chrome-only** (Firefox/Safari: not implemented) — without it, a closing top-layer element leaves the top layer immediately, so in Firefox/Safari the exit transition can render *behind* other content. In practice the 250ms exit is barely visible; if it matters, animate the exit by keeping `[open]` and removing it after `getAnimations()` resolves, exactly as [tailwindcss-stimulus-components `slideover.js`](https://github.com/excid3/tailwindcss-stimulus-components/blob/master/src/slideover.js) does. (Source: MDN BCD [`css.at-rules.starting-style`](https://developer.mozilla.org/en-US/docs/Web/CSS/@starting-style), [`css.properties.transition-behavior`](https://developer.mozilla.org/en-US/docs/Web/CSS/transition-behavior), [`css.properties.overlay`](https://developer.mozilla.org/en-US/docs/Web/CSS/overlay).)

**When a drawer should NOT be a dialog.** Mobile navigation that is *always in the DOM* and merely expands — a hamburger nav — is a **`disclosure`**, not a modal drawer: a `<button aria-expanded>` toggling `hidden` on a `<nav>`. Making it a modal `<dialog>` costs you the ability to have it open on wide viewports simultaneously with page content, and traps focus where no trap is wanted. Rule: **if the page behind must stay usable, it's a `disclosure`; if it must not, it's a `dialog`.**

**Decomposition.** `dialog` + `transition` + `scroll-lock`. (Identical to modal; the `transition` primitive is only needed if you want JS-coordinated exit animations rather than pure CSS.)

**A11y.** Same as [APG Dialog (Modal)](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) — a drawer is a modal dialog with different geometry. `aria-labelledby` on the `<dialog>`; Esc closes; focus returns to the invoker. Respect `prefers-reduced-motion: reduce` by zeroing the `transition-duration`.

**Native.** A drawer is almost always the wrong metaphor on native. Map it to `context: modal` in path configuration (iOS sheet / Android bottom sheet) rather than shipping a web slide-in — see [04-hotwire-native §2](../notes/04-hotwire-native.md). Filter/sort drawers are strong bridge-component candidates so the native app can present a real picker.

**Pitfalls.**
- The UA stylesheet sets `dialog:modal { max-width: calc(100% - 6px - 2em); max-height: … }`. A full-height drawer **must** reset `max-width`/`max-height`/`margin`, or it will inexplicably be inset by a few pixels.
- `height: 100vh` is wrong on mobile Safari (URL bar). Use `100dvh`.
- Scrolling inside the drawer scroll-chains to the document behind it. `overscroll-behavior: contain` on the scrollable child, and still see *Scroll lock*.
- Swipe-to-dismiss is not free and is not worth hand-rolling. Ship the close button.

**Prior art.** [tailwindcss-stimulus-components `slideover.js`](https://github.com/excid3/tailwindcss-stimulus-components/blob/master/src/slideover.js) (native `<dialog>` + `getAnimations()` exit); [Rails Designer `dialog-turboframe` article](https://railsdesigner.com/dialog-turboframe/) — one `<dialog>` serving both modal and slider via a `type` attribute and `[&[type=slider]]` styling.

---

### Popover / tooltip

**Hotwire answer.** **No JS needed** for the popover itself: the native Popover API (`popovertarget` + `popover`) plus CSS anchor positioning gives you a top-layer, light-dismissible, correctly-anchored floating layer with **zero JavaScript**, and Turbo/Stimulus never enter the picture. Anchor positioning went Baseline in **January 2026** (Chrome 125, Safari 26, Firefox 147), so this is finally shippable. A `popover` primitive controller exists only to wrap the invoke API for browsers below that line and to lazily fill the panel from a Turbo Frame.

**Code — the whole thing, no JS:**

```erb
<button popovertarget="user_card_<%= user.id %>" aria-label="About <%= user.name %>">
  <%= image_tag user.avatar_url, alt: "" %>
</button>

<div id="user_card_<%= user.id %>" popover>
  <turbo-frame id="user_card_frame_<%= user.id %>" src="<%= user_card_path(user) %>" loading="lazy">
    <span aria-busy="true">Loading…</span>
  </turbo-frame>
</div>
```

```css
[popovertarget] { anchor-name: --trigger; }        /* or rely on the implicit anchor, below */

#user_card {
  position: absolute;
  position-anchor: --trigger;
  position-area: block-end span-inline-end;         /* below, aligned to the start edge */
  margin-block-start: 0.5rem;
  position-try-fallbacks: block-start span-inline-end, inline-end span-block-end, flip-block flip-inline;
  max-width: 20rem;
  opacity: 1;
  transition: opacity 150ms, display 150ms allow-discrete, overlay 150ms allow-discrete;
}
@starting-style { #user_card:popover-open { opacity: 0; } }
#user_card:not(:popover-open) { opacity: 0; }
```

`popovertarget` establishes an **implicit anchor reference**, so on Chrome 133+/Firefox 147+/Safari 26+ you can drop `anchor-name` entirely and just write `position-area: block-end`.

**What is genuinely free in 2026.**

| Capability | Free? | Support (verified, MDN BCD) |
|---|---|---|
| Top layer, no `z-index` | yes | `popover`: Chrome 114, Firefox 125, Safari 17 |
| Toggle by button, no JS | yes | `popovertarget` / `popovertargetaction`: Chrome 114, Firefox 125, Safari 17 |
| Light dismiss (click outside) + Esc, for `popover="auto"` | yes | [MDN Using the Popover API](https://developer.mozilla.org/en-US/docs/Web/API/Popover_API/Using) |
| `aria-expanded` on the invoker, focus order stitched to the popover, focus returned on Esc | **yes, automatic** | MDN: "When a relationship is established between a popover and its control via `popovertarget`, the API automatically … updates the keyboard focus navigation order … focus is shifted back to the invoker" |
| One-at-a-time stacking, nested popovers allowed | yes | `popover="auto"` semantics |
| Anchored positioning + collision fallback | yes | `anchor-name` Chrome 125 / Safari 26 / **Firefox 147**; `position-area` Chrome 129 / Safari 26 / Firefox 147; `position-try-fallbacks` Chrome 128 / Safari 26 / Firefox 147. **Baseline "newly available", Jan 2026.** |
| Enter/exit animation | yes | `@starting-style` + `allow-discrete`, Baseline widely available |
| `popover="hint"` (a second, tooltip-tier stack that doesn't dismiss the auto stack) | **no** | Chrome 151, Firefox 153, **Safari: not implemented** |
| `interestfor` (declarative hover/focus-triggered popover = zero-JS tooltip) | **no** | Chrome 142 only. Watch it; don't ship it. |

**Fallback story.** Everything except anchor positioning has been broadly available since 2023-2024. Anchor positioning is the only genuinely new dependency, and it degrades gracefully: without it, `position: absolute` inside a `position: relative` wrapper puts the panel in roughly the right place — it just won't flip on collision. Only reach for [floating-ui](https://floating-ui.com/) (as the `anchor` primitive's fallback implementation) if you need collision-aware placement on Safari ≤ 18 / Firefox ≤ 146, or arrow-element positioning. `@supports (anchor-name: --x) { … }` is the right guard.

**Tooltip ≠ popover. Do not conflate them.**

| | Tooltip | Popover |
|---|---|---|
| Trigger | hover **and** focus | click |
| Focusable itself | **never** | yes, contains focusable content |
| Wiring | `role="tooltip"` + `aria-describedby` on the trigger | `popovertarget`, `aria-expanded` (automatic) |
| Content | short text only, **no links, no buttons** | anything |
| Dismiss | Esc, blur, mouse-out (must stay open while the pointer is over the tooltip itself) | light dismiss, Esc |
| Native API | none yet (`interestfor` is Chrome-only) | `popover="auto"` |

A tooltip today still needs a small controller (hover/focus in, delay, Esc, `aria-describedby` wiring) — or [@github/tooltip-element](https://github.com/github/tooltip-element). Build it as `popover="manual"` + `anchor`, never `popover="auto"` (auto's light-dismiss and one-at-a-time stack are wrong for tooltips).

**Decomposition.** `popover` + `anchor`. Tooltip additionally: `timeout` (hover delay). Server-backed content: a lazy `<turbo-frame>` inside the panel — **not** a `content-loader` controller.

**A11y.** No APG "popover" pattern exists; the closest are [APG Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/) (for a click-toggled panel) and [APG Tooltip](https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/) — note APG's tooltip pattern carries the banner *"this design pattern is work in progress; it does not yet have task force consensus"* and ships **no example**, so nobody should be citing it as gospel. What it does say, and what matters: *"Tooltip widgets do not receive focus"*, *"A hover that contains focusable elements can be made using a non-modal dialog"*, and Esc must dismiss. Never put a tooltip on a non-focusable element — keyboard users can't reach it. Never put essential information only in a tooltip.

**Native.** **Tooltips on touch are a trap** — there is no hover, so a tooltip becomes either unreachable or a long-press easter egg. In Hotwire Native, drop tooltips entirely (inline the text, or use a `?` button opening a real popover). Popovers should generally become native sheets/action-sheets via a bridge component; a top-layer web popover inside a native web view can be clipped by native chrome.

**Pitfalls.**
- `popover="auto"` is dismissed by a subsequent `showModal()` on another element. If a popover launches a modal, the popover vanishing is *correct* but surprising.
- The UA stylesheet gives `[popover]` `position: fixed; inset: 0; margin: auto` — you **must** set `position: absolute` (or explicit insets) before anchor positioning does anything, or your popover renders centered on screen.
- `anchor-name` is not inherited and does not cross a `position: fixed` containing-block boundary the way people expect; if the anchor scrolls out of view, add `position-visibility: anchors-visible`.
- `beforetoggle`/`toggle` handlers may not call `showPopover`/`hidePopover` on another popover — throws `InvalidStateError`.
- Turbo Drive caches the popover open. Close on `turbo:before-cache` (same as dialogs).
- Don't use `stimulus-components` `popover` for this — despite the name it is a *hover card that `fetch()`es HTML and appends it*, with no top layer, no anchor, no a11y ([source](https://github.com/stimulus-components/stimulus-components/blob/main/components/popover/src/index.ts)).

**Prior art.** [MDN Popover API](https://developer.mozilla.org/en-US/docs/Web/API/Popover_API/Using); [floating-ui](https://floating-ui.com/) (the `anchor` fallback); [@github/tooltip-element](https://github.com/github/tooltip-element); [stimulus-components `popover`](https://www.stimulus-components.com/docs/stimulus-popover/) (**mis-named**, see above); [Rails Designer tooltips](https://railsdesigner.com/components/tooltips/). Tippy.js / Popper v2 are **superseded** by native popover + anchor positioning.

---

### Dropdown menu

**Hotwire answer.** Two different components share this name and you must decide which you have. **A list of navigation links is not a menu** — build it as `popover` + `disclosure` semantics, with plain `<a>` elements, and it needs **no JS at all** in 2026. **A list of commands** (Duplicate, Archive, Delete) is `menu` = `popover` + `roving-focus` + `dismiss`, with `role="menu"`/`role="menuitem"`. Most Rails tutorials slap `role="menu"` on a nav list; that is a downgrade, not an upgrade.

**Code — navigation dropdown, zero JS:**

```erb
<button popovertarget="account_menu">Account</button>
<div id="account_menu" popover>
  <ul>
    <li><%= link_to "Profile", profile_path %></li>
    <li><%= link_to "Billing", billing_path %></li>
    <li><%= button_to "Sign out", session_path, method: :delete %></li>
  </ul>
</div>
```

```css
[popovertarget="account_menu"] { anchor-name: --account; }
#account_menu { position: absolute; position-anchor: --account;
                position-area: block-end span-inline-start;
                position-try-fallbacks: flip-block; margin-block-start: .25rem; }
```

`aria-expanded` on the button, Esc, light dismiss, focus return, and top-layer stacking are all supplied by the Popover API. Arrow keys are *not* — and for a list of links, [APG says that is correct](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/): Tab is the expected key for navigating links.

**Code — command menu (`role="menu"` earned):**

```erb
<div data-controller="menu roving-focus" data-action="keydown->roving-focus#navigate">
  <button popovertarget="post_actions_<%= post.id %>"
          aria-haspopup="menu" data-menu-target="button">Actions</button>

  <div id="post_actions_<%= post.id %>" popover role="menu"
       aria-label="Post actions"
       data-action="toggle->menu#onToggle"
       data-roving-focus-target="container">
    <%= link_to "Edit", edit_post_path(post), role: "menuitem", tabindex: "-1",
          data: { roving_focus_target: "item", turbo_frame: "modal" } %>
    <%= button_to "Duplicate", duplicate_post_path(post),
          form: { data: { turbo_frame: "_top" } },
          role: "menuitem", tabindex: "-1", data: { roving_focus_target: "item" } %>
    <%= button_to "Delete", post_path(post), method: :delete,
          role: "menuitem", tabindex: "-1",
          data: { roving_focus_target: "item", turbo_confirm: "Delete this post?" } %>
  </div>
</div>
```

```js
// app/javascript/controllers/menu_controller.js — thin: popover does the heavy lifting
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static outlets = ["roving-focus"]

  onToggle({ newState }) {
    // aria-expanded is set by the browser for popovertarget invokers, but role=menu
    // additionally wants focus moved INTO the menu on open (APG Menu Button).
    if (newState === "open") this.rovingFocusOutlet.focusFirst()
    else this.buttonTarget.focus()
  }
}
```

**The `role="menu"` question, settled.** [APG Menu and Menubar](https://www.w3.org/WAI/ARIA/apg/patterns/menu/): *"A menu is a widget that offers a list of choices to the user, such as a set of actions or functions. Menu widgets behave like native operating system menus."* And, decisively, from the [APG Disclosure Navigation Menu example](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/):

> "Although this example uses the word 'menu' in the colloquial sense to refer to a set of navigation links, it does not use the WAI-ARIA `menu` role. This implementation of site navigation does not use the `menu` role because it does not provide the complex functionality that assistive technologies expect in a widget that has the `menu` role."

Concretely, adopting `role="menu"` obligates you to: remove menu items from the Tab sequence (`tabindex="-1"`), implement Up/Down/Home/End/typeahead, move focus into the menu on open, close on activation, and return focus. If you are not shipping all of that, `role="menu"` makes the component *worse* than plain links. "No ARIA is better than bad ARIA."

**`<details>`-based dropdowns.** Fine, and still the lowest-effort option:

```erb
<details class="dropdown">
  <summary>Account</summary>
  <ul><li><%= link_to "Profile", profile_path %></li></ul>
</details>
```

You get toggle, `aria-expanded` (browsers expose `<summary>` expanded state natively), and keyboard activation for free. You do **not** get: top layer (so `z-index` and `overflow: hidden` ancestors will bite), click-outside dismiss, Esc, or focus return. [@github/details-menu-element](https://github.com/github/details-menu-element) (actively maintained, last push 2026-08) adds exactly those plus `role="menu"` wiring and label-syncing. Prefer native popover for new work; `<details>` is the right call when you can't take the anchor-positioning dependency.

**The Turbo gotcha:** a `<details open>` **stays open across a Turbo Frame update or a Drive navigation from a cached snapshot** — click a menu item that targets a frame, the page updates, and the dropdown is still hanging open. Two distinct causes: (a) frame updates never touch the `<details>` because it is outside the frame; (b) `PageSnapshot#clone` caches `details[open]` verbatim ([02-turbo-deep-dive §2.6](../notes/02-turbo-deep-dive.md)). Under **morphing** the opposite bites: idiomorph syncs the `open` attribute from the server render, so a menu the user opened snaps shut on every page refresh. Fixes: close on `turbo:submit-end`/`turbo:before-cache`, and mark the `<details>` `data-turbo-permanent` (with an `id`) if you need it to survive a morph. `popover` has neither problem for cause (a) — `popover="auto"` light-dismisses on the click.

**Decomposition.** Navigation dropdown: `popover` + `anchor` (+ nothing else). Command menu: `menu` = `popover` + `roving-focus` + `dismiss` (+ `anchor`).

**A11y.** [APG Menu Button](https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/) + [APG Menu](https://www.w3.org/WAI/ARIA/apg/patterns/menu/) for command menus; [APG Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/) for navigation. Menu button: `aria-haspopup="menu"`, `aria-expanded`, Enter/Space/Down open and focus the first item, Up opens and focuses the last. In the menu: Up/Down move, Home/End jump, printable characters typeahead, Esc closes and returns focus, Tab does **not** move between items.

**Native.** A row-level "Actions" dropdown should be a **bridge component** presenting a native action sheet (iOS `UIAlertController` / Android bottom sheet) — this is the single most common bridge component in real apps. See the bridge catalog in [04-hotwire-native §Bridge Component Catalog](../notes/04-hotwire-native.md). Overflow menus in the nav bar should be native toolbar items driven by path configuration, not web chrome.

**Pitfalls.**
- A dropdown inside a table cell or a `overflow: hidden` card is clipped — the classic reason to move to `popover` (top layer is immune).
- `button_to` generates a `<form>`; `role="menuitem"` must go on the `<button>`, not the form, and the form must not break the roving-focus item query.
- Don't nest a Turbo Frame link inside `role="menuitem"` without closing the menu on activation — APG requires the menu close on selection.
- `stimulus-components` `dropdown` uses `useTransition` + a document click handler, sets `aria-expanded`, and does **not** do roving focus, Esc, or top layer ([source](https://github.com/stimulus-components/stimulus-components/blob/main/components/dropdown/src/index.ts)). Fine for nav lists, insufficient for `role="menu"`.

**Prior art.** [@github/details-menu-element](https://github.com/github/details-menu-element) (maintained); [stimulus-components `dropdown`](https://www.stimulus-components.com/docs/stimulus-dropdown/); [tailwindcss-stimulus-components `dropdown.js`](https://github.com/excid3/tailwindcss-stimulus-components/blob/master/src/dropdown.js); [Rails Designer dropdowns](https://railsdesigner.com/components/dropdowns/). **Superseded:** Bootstrap's JS dropdown, select2-style menus, [@github/details-dialog-element](https://github.com/github/details-dialog-element) (archived, deprecated by GitHub for a11y reasons).

---

### Context menu

**Hotwire answer.** Rare in Rails apps and rarely worth it — but if you need one, it is `contextmenu` event + native `popover` + a CSS anchor pinned to the pointer. No library. Always duplicate every context-menu command in a visible, keyboard-reachable menu button; a right-click-only affordance fails WCAG on its own.

**Code.**

```erb
<tbody data-controller="context-menu" data-action="contextmenu->context-menu#open">
  <%= render @rows %>
</tbody>
<div id="row_menu" popover role="menu" aria-label="Row actions" data-context-menu-target="menu"></div>
```

```js
// app/javascript/controllers/context_menu_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["menu"]
  open(event) {
    const row = event.target.closest("[data-menu-src]")
    if (!row) return                        // let the browser's own menu happen
    event.preventDefault()
    this.menuTarget.style.setProperty("--x", `${event.clientX}px`)
    this.menuTarget.style.setProperty("--y", `${event.clientY}px`)
    this.menuTarget.replaceChildren(
      Object.assign(document.createElement("turbo-frame"),
                    { id: "row_menu_frame", src: row.dataset.menuSrc }))
    this.menuTarget.showPopover()
  }
}
```

```css
#row_menu { position: fixed; inset: auto auto auto auto; top: var(--y); left: var(--x); margin: 0; }
```

**Decomposition.** `popover` + `anchor` + `roving-focus` + `dismiss`.

**A11y.** [APG Menu](https://www.w3.org/WAI/ARIA/apg/patterns/menu/). Shift+F10 must open the same menu from the keyboard; the menu must be reachable without a right-click. Focus moves to the first item on open; Esc closes and returns focus to the row.

**Native.** Long-press context menus are a platform idiom with real native affordances (`UIContextMenuInteraction`, Android `ContextMenu`). Ship a bridge component; a web `contextmenu` handler does not fire reliably in a native web view.

**Pitfalls.** Never swallow the browser's own context menu on text or links (users need Copy / Open in new tab). Anchoring to the pointer needs `position-visibility` / manual flip near the viewport edge. Touch has no right-click — you need a long-press or an overflow button anyway, at which point the plain dropdown is usually the better product decision.

**Prior art.** No good Rails-ecosystem gem. [MDN `contextmenu` event](https://developer.mozilla.org/en-US/docs/Web/API/Element/contextmenu_event). The old HTML `<menu type="context">` was removed from all browsers — do not use it.

---

### Accordion / disclosure

**Hotwire answer.** **No JS needed.** `<details>`/`<summary>` is the whole component; `name="group"` makes it an exclusive accordion; `::details-content` + `interpolate-size: allow-keywords` animates it. Reach for a `disclosure` controller only when the markup can't be `<details>` (e.g. the trigger and the panel are not siblings, or you need `aria-controls` across a layout boundary).

**Code — the complete accordion, zero JavaScript:**

```erb
<div class="accordion">
  <% @faqs.each do |faq| %>
    <details name="faq" id="faq_<%= faq.id %>" <%= "open" if faq == @faqs.first %>>
      <summary><%= faq.question %></summary>
      <div class="accordion__panel"><%= faq.answer %></div>
    </details>
  <% end %>
</div>
```

```css
.accordion details { border-block-end: 1px solid var(--rule); }

.accordion summary {
  cursor: pointer; list-style: none;      /* Firefox */
  display: flex; justify-content: space-between; padding: .75rem 0;
}
.accordion summary::-webkit-details-marker { display: none; }   /* Safari/Chrome */
.accordion summary::after { content: "▾"; transition: rotate 200ms; }
.accordion details[open] > summary::after { rotate: 180deg; }

/* Animate open/close with no JS. Requires ::details-content. */
.accordion details::details-content {
  block-size: 0;
  overflow: hidden;
  opacity: 0;
  transition: block-size 250ms ease, content-visibility 250ms allow-discrete, opacity 200ms ease;
}
.accordion details[open]::details-content {
  block-size: auto;                        /* needs interpolate-size, below */
  opacity: 1;
}
/* Opt into animating to/from intrinsic sizes. Chrome-only today — the accordion
   still works everywhere, it just snaps instead of sliding. */
:root { interpolate-size: allow-keywords; }

@media (prefers-reduced-motion: reduce) {
  .accordion details::details-content { transition: none; }
}
```

**Browser support, verified (MDN BCD).**
- `<details name>` exclusive accordion: **Chrome 120, Firefox 130, Safari 17.2** — widely available, ship it.
- `::details-content`: **Chrome 131, Firefox 143, Safari 18.4** — Baseline newly available since Sept 2025. Safe with graceful degradation.
- `interpolate-size: allow-keywords` and `calc-size()`: **Chrome 129 only. Firefox: no. Safari: no.** This is the one piece that is *not* cross-browser. Everywhere else the panel snaps open instantly — which is a perfectly acceptable degradation. **Do not build a JS height-animation fallback**; it is not worth the code.

**Turbo interactions.**
- **Morphing closes your accordion.** Idiomorph syncs every attribute including `open`, with no special-casing ([idiomorph `morphAttributes`](https://github.com/bigskysoftware/idiomorph/blob/main/src/idiomorph.js)). If the server renders `<details>` closed and a page refresh morphs, the user's open panel snaps shut. Fixes, in order: (1) render the open state from the server (`?open=faq_3`, or a `session`/cookie), which is the Rails-y answer and survives reloads too; (2) `data-turbo-permanent` + `id` on the `<details>` so idiomorph skips it — note this also freezes its *contents* ([02-turbo-deep-dive §2.7](../notes/02-turbo-deep-dive.md)); (3) cancel `turbo:before-morph-element` for `details[open]`.
- **Drive snapshot caching keeps it open**, which is usually what you want — but combined with `name=` grouping you can briefly see two panels open. `PageSnapshot#clone` caches `details[open]` as-is ([§2.6](../notes/02-turbo-deep-dive.md)).
- `<details>` panels are **found by in-page search (Ctrl+F) and auto-open** in Chrome 97+ / Firefox 148+ / Safari 26.2 (partial) — a real accessibility win no JS accordion gives you.

**When to reach for `disclosure` instead.** When the button and the panel cannot be `<summary>` and its siblings: a sidebar section whose toggle lives in a sticky header, a "show more" that reveals content in a different column, or a panel whose expanded state must be sent to the server. Then: `<button aria-expanded aria-controls="panel_id">` + `[hidden]` on the panel, and a 15-line `disclosure` controller. Everything else should be `<details>`.

**Decomposition.** Nothing — plain HTML/CSS. Optional `persist` (mirror `open` to `localStorage` on the `toggle` event) when the state should survive navigation and you don't want a server round-trip.

**A11y.** [APG Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/). `<summary>` is exposed as a button with the expanded state automatically — **do not add `role="button"` or `aria-expanded` yourself**, it regresses AT support. Enter/Space toggle, free. Do **not** put a heading *around* `<details>` and a second heading inside `<summary>`; wrap the `<summary>` text in the heading (`<summary><h3>…</h3></summary>`) if you need document structure. Note that `name=`-grouped `<details>` is *not* an ARIA accordion — screen readers announce N independent disclosures, which is fine and is what APG's accordion pattern effectively degrades to.

**Native.** n/a. `<details>` works identically in a native web view. If the accordion is the primary navigation of a screen, consider a native list/section instead.

**Pitfalls.**
- Hiding the marker takes **two** rules: `list-style: none` (Firefox) and `::-webkit-details-marker { display: none }` (WebKit/Blink).
- `<details name="x">` inside a Turbo Frame: if two frames each render a `name="x"` group, they compete — names are document-global.
- The `toggle` event fires on both open *and* close; check `element.open`.
- Content inside a closed `<details>` still exists in the DOM — don't use it to "hide" sensitive data.
- Lazy-loading panel content: put a `<turbo-frame loading="lazy">` inside. It fires on becoming visible, which is exactly on open.

**Prior art.** [Rails Designer — "Accordion without JavaScript" (2024-12)](https://railsdesigner.com/accordion-without-javascript/) (good; its `localStorage` controller is the `persist` primitive); [Rails Designer accordions component](https://railsdesigner.com/components/accordions/); [MDN `::details-content`](https://developer.mozilla.org/en-US/docs/Web/CSS/::details-content). **Superseded:** every jQuery/Bootstrap accordion plugin, and any Stimulus `accordion` controller that toggles a `hidden` class.

---

### Tabs (with URL state)

**Hotwire answer.** Three tiers; **default to tier (b)**. (a) If the panels are cheap and all render anyway, they're just anchors + `:target`/checkbox CSS — no JS, but poor a11y. (b) **Turbo Frame tabs**: each tab is a real `<a>` to a real URL (`?tab=members`) targeting a shared frame, with `data-turbo-action="advance"` so the URL updates, Back works, reload works, and the link is shareable. The server renders `aria-selected` — no client state at all, and no JS beyond the optional `roving-focus` primitive for arrow keys. (c) A client-only `tabs` controller (all panels pre-rendered, toggle `hidden`) is correct **only** when the panels are small and switching must be instant with no network. Never ship tabs whose state lives only in a JS variable.

**Code — tier (b), the default:**

```ruby
# app/controllers/projects_controller.rb
TABS = %w[overview members activity].freeze

def show
  @project = Project.find(params[:id])
  @tab = TABS.include?(params[:tab]) ? params[:tab] : "overview"
end
```

```erb
<%# app/views/projects/show.html.erb %>
<div role="tablist" aria-label="Project sections"
     data-controller="roving-focus" data-roving-focus-orientation-value="horizontal"
     data-action="keydown->roving-focus#navigate">
  <% ProjectsController::TABS.each do |tab| %>
    <%= link_to tab.titleize, project_path(@project, tab: tab),
          id: "tab_#{tab}",
          role: "tab",
          "aria-selected": (tab == @tab).to_s,
          "aria-controls": "tabpanel",
          tabindex: (tab == @tab ? "0" : "-1"),
          class: class_names("tab", active: tab == @tab),
          data: { turbo_frame: "tabpanel", turbo_action: "advance",
                  roving_focus_target: "item" } %>
  <% end %>
</div>

<%= turbo_frame_tag "tabpanel",
      role: "tabpanel",
      tabindex: "0",
      "aria-labelledby": "tab_#{@tab}" do %>
  <%= render "projects/tabs/#{@tab}", project: @project %>
<% end %>
```

That is the entire feature. Because `project_path(@project, tab: "members")` is a real URL that renders the same `<turbo-frame id="tabpanel">` on a cold load, `data-turbo-action="advance"` gives correct history: the URL changes, Back restores the previous tab with the right panel contents stitched into the cached snapshot ([02-turbo-deep-dive §3.4](../notes/02-turbo-deep-dive.md)). **The requirement that trips people up: the tab URL must be independently renderable.** If `?tab=members` only works as a frame response, Back and reload break.

Two refinements:
- Put the `role="tablist"` **inside** the frame too if you want the selected state to update without a second render path — otherwise the frame response must also contain the tablist, or you re-render the whole page. Simplest correct shape: wrap tablist *and* panel in the frame.
- Use `data-turbo-action="replace"` instead of `"advance"` if tab switching shouldn't pile up history entries. `"replace"` to the same pathname also makes the visit a *page refresh*, so with morphing enabled the swap preserves scroll and focus ([§5.1](../notes/02-turbo-deep-dive.md)).

**Manual vs automatic activation.** [APG Tabs](https://www.w3.org/WAI/ARIA/apg/patterns/tabs/): *"It is recommended that tabs activate automatically when they receive focus **as long as their associated tab panels are displayed without noticeable latency. This typically requires tab panel content to be preloaded.**"* Turbo Frame tabs involve a network round-trip, so **use manual activation**: arrow keys move focus only; Enter/Space activates. This is why `roving-focus` must not fire the link on move. Tier (c) with pre-rendered panels should use automatic activation.

**Decomposition.** Tier (b): `roving-focus` only (the frame does everything else). Tier (c): `tabs` (= `roving-focus` + panel visibility + `aria-selected`) + optional `persist` for hash/localStorage sync.

**A11y.** [APG Tabs](https://www.w3.org/WAI/ARIA/apg/patterns/tabs/). `role="tablist"` (+ `aria-label`), `role="tab"` with `aria-controls` and `aria-selected`, `role="tabpanel"` with `aria-labelledby` and `tabindex="0"` when it holds no focusable content. Roving tabindex: exactly one tab has `tabindex="0"`. Left/Right (or Up/Down if `aria-orientation="vertical"`) wrap around; Home/End optional. Tab from the tablist goes to the panel, not to the next tab.

**Native.** Top-level app sections should be **native tabs**, configured in path configuration, not web tabs — see [04-hotwire-native §7](../notes/04-hotwire-native.md). Sub-navigation within a screen can stay web, but `data-turbo-action="advance"` on a tab link pushes a native screen on the stack, which is wrong: you get a back-button per tab click. Use `data-turbo-action="replace"` for tabs in native contexts (this maps to `presentation: replace`; [§6.3](../notes/04-hotwire-native.md)) or exclude the pattern via path config.

**Pitfalls.**
- Tabs whose state is only in `location.hash` break server-side rendering and share links that need auth-scoped content. Prefer a query param.
- Putting `role="tab"` on an `<a href>` is fine and preferred (activation and middle-click still work), but you must then handle Space yourself — links respond to Enter only.
- Don't render `aria-selected="false"` as a missing attribute; APG requires it present on every tab. (Note `tailwindcss-stimulus-components` `tabs.js` sets `tab.ariaSelected = null` for inactive tabs, which removes it — a small a11y bug in that library.)
- A frame-based tab that returns a response without the matching frame gives `Content missing` — check your layout isn't stripped on the tab route.
- Scroll position jumps when a tall panel is replaced by a short one. `data-turbo-action="replace"` + morphing avoids this.

**Prior art.** [@github/tab-container-element](https://github.com/github/tab-container-element) — framework-free, APG-correct, actively maintained; the best client-only option. [tailwindcss-stimulus-components `tabs.js`](https://github.com/excid3/tailwindcss-stimulus-components/blob/master/src/tabs.js) — index-based, syncs the URL hash via `Turbo.navigator.history.replace`, has `scrollActiveTabIntoView`; no roving tabindex. [Rails Designer tabs](https://railsdesigner.com/components/tabs/).

---

### Command palette (⌘K)

**Hotwire answer.** Compose four primitives you already have: `hotkey` binds ⌘K, `dialog` opens a native `<dialog>`, `autosubmit` debounce-submits the search form on input, and a `<turbo-frame>` renders server-side results. The results are **real `<a>` links**, so Enter, ⌘-click, and middle-click all just work with no key handling. There is no palette library to install; the only third-party dependency worth taking is [@github/hotkey](https://github.com/github/hotkey).

**Code.**

```erb
<%# app/views/layouts/_command_palette.html.erb — rendered once in the layout %>

<%# The visible search affordance IS the hotkey target. @github/hotkey clicks it. %>
<button type="button" class="search-trigger"
        data-hotkey="Mod+k"
        command="show-modal" commandfor="command_palette">
  Search <kbd>⌘K</kbd>
</button>

<dialog id="command_palette" class="palette" closedby="any"
        data-controller="dialog" data-dialog-modal-value="true"
        data-action="click->dialog#backdropClose close->dialog#reset"
        aria-label="Command palette">

  <%= form_with url: commands_path, method: :get,
        data: { turbo_frame: "command_results",
                controller: "autosubmit", autosubmit_delay_value: 200 } do |f| %>
    <%= f.search_field :q,
          autofocus: true, autocomplete: "off", spellcheck: "false",
          placeholder: "Search or jump to…",
          role: "combobox",
          "aria-expanded": "true",
          "aria-controls": "command_results",
          "aria-autocomplete": "list",
          "aria-describedby": "command_status",
          data: { action: "input->autosubmit#submit " \
                          "keydown.down->roving-focus#next " \
                          "keydown.up->roving-focus#previous" } %>
  <% end %>

  <turbo-frame id="command_results" target="_top"
               data-controller="roving-focus"
               data-roving-focus-orientation-value="vertical">
    <%= render "commands/results", results: [], query: nil %>
  </turbo-frame>
</dialog>
```

```erb
<%# app/views/commands/_results.html.erb %>
<ul class="palette__results">
  <% results.each do |result| %>
    <li>
      <%= link_to result.path,
            class: "palette__result",
            data: { roving_focus_target: "item" } do %>
        <span class="palette__kind"><%= result.model_name.human %></span>
        <%= result.to_s %>
      <% end %>
    </li>
  <% end %>
</ul>
<p id="command_status" class="sr-only" role="status">
  <%= results.any? ? "#{results.size} results for #{query}" : "No results" %>
</p>
```

```ruby
# app/controllers/commands_controller.rb
class CommandsController < ApplicationController
  def index
    @query   = params[:q].to_s.strip
    @results = @query.present? ? Command::Search.new(@query, user: Current.user).results.first(10) : []
    # renders index.html.erb — the response MUST contain the matching frame
  end
end
```

```erb
<%# app/views/commands/index.html.erb — the frame response, not a bare partial %>
<%= turbo_frame_tag "command_results", target: "_top",
      data: { controller: "roving-focus", roving_focus_orientation_value: "vertical" } do %>
  <%= render "commands/results", results: @results, query: @query %>
<% end %>
```

`target="_top"` on the frame is what makes clicking a result navigate the whole page instead of trying to load the destination into the results frame.

```js
// app/javascript/controllers/autosubmit_controller.js — the `autosubmit` primitive
import { Controller } from "@hotwired/stimulus"
import { useDebounce } from "stimulus-use"

export default class extends Controller {
  static debounces = [{ name: "submit", wait: 200 }]
  static values = { delay: { type: Number, default: 200 } }

  connect() { useDebounce(this, { wait: this.delayValue }) }

  submit() { this.element.requestSubmit() }
}
```

```js
// app/javascript/hotkey.js — the `hotkey` primitive, 5 lines
import { install, uninstall } from "@github/hotkey"

document.addEventListener("turbo:load", () => {
  for (const el of document.querySelectorAll("[data-hotkey]")) install(el)
})
document.addEventListener("turbo:before-cache", () => {
  for (const el of document.querySelectorAll("[data-hotkey]")) uninstall(el)
})
```

**How much of this is free.** The ⌘K → open path is fully declarative: `data-hotkey="Mod+k"` clicks the button, `command="show-modal" commandfor="command_palette"` opens the dialog with **zero JavaScript of your own** (`command`/`commandfor`: Chrome 135, Firefox 144, Safari 26.2 — cross-browser as of 2026). `Mod` resolves to ⌘ on macOS and Ctrl elsewhere, which is the detail hand-rolled implementations always get wrong. Esc, backdrop dismiss, focus into the input (`autofocus`), and focus restored to the trigger on close are all native `<dialog>`.

**Debounced search-as-you-type** is `autosubmit` + `useDebounce` from stimulus-use — per the shared vocabulary, this is *not* a `debounce` controller. Each keystroke's request supersedes the last; Turbo cancels the in-flight frame request when a new one starts, so out-of-order responses are not a concern.

**A11y — the honest version.** A strict [APG Combobox](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/) requires `role="listbox"`/`role="option"` on the results and `aria-activedescendant` moved by JS while DOM focus stays in the input. That is real work, and it conflicts with the "results are links" trick, because `<a role="option">` loses link semantics. Two defensible positions:

1. **Links + `roving-focus` (recommended default).** Input is `role="combobox"` with `aria-controls`/`aria-expanded`; results are a `<ul>` of `<a>`; Down/Up move *real DOM focus* into the list; Enter is the browser's own link activation. Announce result counts through a `role="status"` live region. Screen-reader users get a perfectly usable "search field, then a list of links" experience. Not APG-literal, but robust and impossible to get subtly wrong.
2. **Full ARIA 1.2 combobox.** Don't write it — use [hotwire_combobox](https://github.com/josefarias/hotwire_combobox), which already implements `role="combobox"` + `aria-controls`/`aria-owns`/`aria-haspopup="listbox"`/`aria-autocomplete`/`aria-activedescendant`, plus live-region announcements, async `src` loading, and a small-viewport `<dialog>` mode ([`markup/input.rb`](https://github.com/josefarias/hotwire_combobox/blob/main/app/presenters/hotwire_combobox/component/markup/input.rb), [`combobox/dialog.js`](https://github.com/josefarias/hotwire_combobox/blob/main/app/assets/javascripts/hw_combobox/models/combobox/dialog.js)).

**Decomposition.** `hotkey` + `dialog` + `combobox` + `autosubmit` + `roving-focus` (+ a `<turbo-frame src>` for results). Debounced via stimulus-use `useDebounce`.

**Native.** Ship the palette as a **bridge component** backed by native search, or hide it entirely (`data-bridge-hide-on-native`) — ⌘K has no meaning without a keyboard, and a web `<dialog>` inside a native web view fights the native search bar. If you keep it, the `commands#index` route should be `context: modal` with `pull_to_refresh_enabled: false`. See [04-hotwire-native §2, §3](../notes/04-hotwire-native.md).

**Pitfalls.**
- `data-hotkey` must be **re-installed after every Turbo navigation** and uninstalled on cache, or you leak listeners and the hotkey silently dies. This is the #1 ⌘K bug in Turbo apps.
- Don't intercept ⌘K when focus is in a text field unless you mean to — `@github/hotkey` handles this via `data-hotkey-scope`; a hand-rolled `keydown` listener will steal the browser's own shortcuts.
- `autofocus` inside a `<dialog>` works on `showModal()`, but if the dialog is opened by a `command` button *before* the frame has content, ensure the input (not the frame) is the first focusable child.
- Debounce below ~150ms and you DoS your own search endpoint; above ~400ms it feels broken. 200ms is right.
- Search endpoints must be scoped to `Current.user` — a palette that indexes everything is a data leak waiting to happen.
- The Turbo Frame must carry `target="_top"`, otherwise clicking a result tries to render the destination page inside the results frame.
- Turbo caches the dialog open (see modal pitfalls); the `dialog` controller's `turbo:before-cache` handler covers it.

**Prior art.** [hotwire_combobox](https://github.com/josefarias/hotwire_combobox) (Jose Farias) — the most complete ARIA combobox in the Rails ecosystem; read it before writing your own. [@github/hotkey](https://github.com/github/hotkey) — the `data-hotkey` behaviour GitHub itself ships on every page. [@github/auto-complete-element](https://github.com/github/auto-complete-element) — framework-free server-backed autocomplete. [ninja-keys](https://github.com/ssleptsov/ninja-keys) — a web component ⌘K palette; workable but client-data-only, so it fights the "results come from the server" model. [Rails Designer command menu](https://railsdesigner.com/components/command-menu/) ([announcement](https://railsdesigner.com/introducing-command-menu/)). [stimulus-use `useHotkeys`](https://stimulus-use.github.io/stimulus-use/) as an alternative `hotkey` implementation.

---

### Deep-linking modal state / modal + back button

**Hotwire answer.** Make the modal a **real route** and let Turbo do history. `data-turbo-action="advance"` on the modal frame (or on the link) promotes the frame navigation to a Visit, so `/posts/1/edit` appears in the address bar, Back closes the modal, reload re-opens it, and the URL is shareable. No `history.pushState`, no `popstate` listener, no `?modal=` state machine. (General back-button correctness is the Navigation researcher's territory; this record is only the modal-specific part.)

**Code.**

```erb
<%# layout %>
<%= turbo_frame_tag "modal", data: { turbo_action: "advance" } %>

<%# link %>
<%= link_to "Edit", edit_post_path(post), data: { turbo_frame: "modal" } %>
```

On Back, Turbo restores the cached snapshot — which was captured *before* the modal opened — so the modal frame is empty again and the dialog is gone. On forward, or on a cold load of `/posts/1/edit`, the route renders standalone; whether that is "the edit page" or "the index with a modal over it" is your choice:

```erb
<%# app/views/posts/edit.html.erb — render inside the index when loaded directly %>
<% if turbo_frame_request_id == "modal" %>
  <%= turbo_frame_tag "modal" do %><%= render "modal_shell" %><% end %>
<% else %>
  <%= render "posts/index_behind_modal", post: @post %>   <%# full page + modal open %>
<% end %>
```

`turbo_frame_request?` / `turbo_frame_request_id` are turbo-rails controller helpers; the Rails Designer `Frameable` concern uses the same hook to *forbid* direct access (`redirect_to root_path unless turbo_frame_request?`) when a standalone render isn't worth building.

**The "morph closes my dialog" trap.** If `turbo-refresh-method=morph` is on and a page refresh happens while a modal is open, idiomorph syncs attributes against the server's markup. If the server's copy of the dialog lacks `open`, the attribute is stripped — leaving an invisible dialog that **still blocks the entire page** (verified in Chrome 151; `close()` is a no-op in that state). Two defences: keep the modal inside a frame that is not part of the morph target, or add `data-turbo-permanent` + `id` to the `<dialog>`. See the *Modal dialog* pitfalls.

**Decomposition.** `dialog` (nothing else — history is Turbo's job).

**A11y.** Focus on Back-restore is the weak point: Turbo restores the snapshot but focus lands on `<body>`. If the modal was opened from a row action, restore focus to that row's trigger in the dialog's `close` handler (`this.dispatch("closed")` → a small listener), otherwise keyboard users are dumped at the top of the page.

**Native.** `data-turbo-action="advance"` pushes a native screen. Combined with `context: modal` in path configuration you get a native sheet with correct dismissal — but note that dismissing the native modal does **not** fire the web `close` event on the screen behind it, because they are separate web views ([04-hotwire-native §1.2, §6.4](../notes/04-hotwire-native.md)). Use `refresh_or_redirect_to` server-side rather than trying to coordinate from JS.

**Pitfalls.**
- `data-turbo-action="advance"` on a frame whose `src` is not a standalone-renderable URL breaks Back and reload — the single hard requirement ([02-turbo-deep-dive §3.4](../notes/02-turbo-deep-dive.md)).
- The Drive snapshot cache will flash the modal open on Back if you don't close dialogs in `turbo:before-cache` ([§2.6](../notes/02-turbo-deep-dive.md)).
- Don't use `advance` for modals users open dozens of times (a row-level preview) — you fill history with junk. Use the default (no history) there.
- `?modal=edit&id=1` query-param state machines are strictly worse than a real route: not RESTful, not cacheable, and they force you to hand-roll the render branch anyway.

**Prior art.** turbo-rails `turbo_frame_request?` / `turbo_frame_request_id` controller helpers ([turbo-rails](https://github.com/hotwired/turbo-rails)); the `Frameable` concern from [Rails Designer](https://railsdesigner.com/modal-with-rails-hotwire/). Any tutorial that reaches for `history.pushState` or a `?modal=` param to do this predates `data-turbo-action` on frames — skip it.

---

### Focus trap + modal a11y

**Hotwire answer.** For a modal `<dialog>` opened with `showModal()`, **you do not need a focus trap** — the browser marks the entire rest of the document inert and the spec calls this being *"blocked by a modal dialog"*. Verified in Chrome 151: a `<button>` outside an open modal cannot receive focus, programmatically or by Tab. The `focus-trap` primitive exists only for overlays that are *not* a `<dialog>`: a non-modal `dialog.show()`, a full-screen `popover`, or legacy `div` overlays you haven't migrated.

**What is free vs. what is yours.**

| Concern | `showModal()` | You |
|---|---|---|
| Outside content inert (focus, click, AT) | free | — |
| Tab / Shift+Tab cycle within the dialog | free | — |
| Esc closes topmost dialog only | free | — |
| Focus returned to the invoker on close | free | — |
| **Which** element gets initial focus | first focusable child | set `autofocus` deliberately — otherwise focus lands on a "×" close button, which is a bad first announcement |
| Accessible name | — | `aria-labelledby` (or `aria-label`) on the `<dialog>` |
| Accessible description | — | `aria-describedby` for confirmation copy |
| A visible, reachable close control | — | yours; Esc alone is not enough |
| Scroll lock | **not free** | yours — see *Scroll lock* |
| Focus after Back/restore navigation | — | yours |

**Code — the `focus-trap` primitive, for the non-`<dialog>` case only:**

```js
// app/javascript/controllers/focus_trap_controller.js
import { Controller } from "@hotwired/stimulus"

const FOCUSABLE = 'a[href],button:not([disabled]),input:not([disabled]),select:not([disabled]),' +
                  'textarea:not([disabled]),[tabindex]:not([tabindex="-1"]),details,summary'

export default class extends Controller {
  connect() {
    this.previouslyFocused = document.activeElement
    this.siblings = [...document.body.children].filter((el) => !el.contains(this.element))
    this.siblings.forEach((el) => el.setAttribute("inert", ""))     // the real mechanism
    ;(this.element.querySelector("[autofocus]") || this.focusable[0] || this.element).focus()
    this.onKeydown = (e) => { if (e.key === "Tab") this.wrap(e) }
    this.element.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.onKeydown)
    this.siblings.forEach((el) => el.removeAttribute("inert"))
    this.previouslyFocused?.focus()
  }

  get focusable() { return [...this.element.querySelectorAll(FOCUSABLE)].filter((el) => el.offsetParent) }

  wrap(event) {
    const items = this.focusable
    if (items.length === 0) return event.preventDefault()
    const first = items[0], last = items[items.length - 1]
    if (event.shiftKey && document.activeElement === first) { last.focus(); event.preventDefault() }
    else if (!event.shiftKey && document.activeElement === last) { first.focus(); event.preventDefault() }
  }
}
```

Note the important half: **`inert` on the siblings is what actually makes the trap correct** (it hides them from screen-reader virtual cursors, not just from Tab). `inert` is Chrome 102 / Firefox 112 / Safari 15.5 — safe. A Tab-only trap without `inert` is a fake trap: VoiceOver and NVDA users can still swipe/arrow into the background content.

**Decomposition.** `focus-trap`. Composes with `dialog` only when `dialog.show()` (non-modal) is used.

**A11y.** [APG Dialog (Modal)](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/). Required: `role="dialog"` + `aria-modal="true"` (both automatic on `<dialog>` + `showModal()`), accessible name, Esc, focus management. Do **not** add `aria-modal="true"` to a non-modal `dialog.show()` — it lies to AT.

**Native.** n/a — native presentation handles this. A JS focus trap inside a native web view can fight the native keyboard/accessibility focus; another reason to prefer `<dialog>`.

**Pitfalls.**
- Tab escaping into browser chrome (URL bar) is **correct** and required by WCAG's "no keyboard trap". Don't "fix" it.
- Querying focusable elements once on connect misses content added later (a Turbo Frame loading into the dialog). Query lazily, as above.
- `offsetParent` as a visibility check fails for `position: fixed` children. Use `checkVisibility()` if you have fixed content inside the trap.
- Restoring focus to an element that has since been removed from the DOM silently does nothing; fall back to a stable ancestor.

**Prior art.** [focus-trap](https://github.com/focus-trap/focus-trap) (+ `focus-trap-js`) — the reference implementation, ~10KB; only worth it for non-`<dialog>` overlays. [WICG/inert](https://github.com/WICG/inert) — the polyfill; **no longer needed**, `inert` is native everywhere. [MDN `inert`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/inert).

---

### Click-outside

**Hotwire answer.** Three mechanisms, in strict preference order: (1) **native popover light-dismiss** — `popover="auto"` closes on any outside click, zero JS, plus Esc; (2) **`closedby="any"` on `<dialog>`** — same, for modals (Chrome 134+/Firefox 141+; Safari still Technology Preview as of 2026-08, so pair it with (3)); (3) the `click-outside` primitive (stimulus-use `useClickOutside`) for everything else. Writing your own `document.addEventListener("click", …)` is the wrong answer in all three cases.

**Code — the backdrop-click fallback, done correctly:**

```js
// inside the `dialog` controller
backdropClose(event) {
  if (event.target !== this.element) return          // any click inside bubbles from a child
  if (getSelection().toString().length > 0) return   // a drag-select that ended on the backdrop
  this.element.close()
}
```

```css
/* Required, or the trick misfires: a click on the dialog's own padding has
   event.target === dialog, so the modal closes when you click INSIDE the card. */
dialog { padding: 0; border: 0; }
dialog > .dialog__body { padding: 1.5rem; }
```

A more robust variant that survives padding (use if you can't restructure the markup):

```js
backdropClose(event) {
  const r = this.element.getBoundingClientRect()
  const inside = r.top <= event.clientY && event.clientY <= r.bottom &&
                 r.left <= event.clientX && event.clientX <= r.right
  if (!inside) this.element.close()
}
```

**Decomposition.** `click-outside` (or nothing, when `popover="auto"` / `closedby="any"` covers it).

**A11y.** Click-outside is a **pointer-only** affordance; Esc must always do the same job, and there must be a visible close control. Never make dismissal *only* available by clicking outside.

**Native.** Outside-tap on a native sheet is handled by the platform. n/a.

**Pitfalls.**
- Listening on `click` at `document` and checking `contains()` fires for the *opening* click too if you bind synchronously — bind on the next tick, or use `useClickOutside`, which handles it.
- `mousedown`-based detection closes the panel when a drag-select starts inside and ends outside. Use `click`, plus the `getSelection()` guard.
- Elements in the **top layer** are not `contains()`-descendants of your controller element — a `contains()` check will treat your own popover as "outside". This is the main reason to let the platform do it.
- `event.target === dialog` is defeated by `<dialog>` padding. This is the single most common modal bug in Rails codebases.

**Prior art.** [stimulus-use `useClickOutside`](https://stimulus-use.github.io/stimulus-use/#/use-click-outside); [MDN Popover API light dismiss](https://developer.mozilla.org/en-US/docs/Web/API/Popover_API/Using); [tailwindcss-stimulus-components `modal.js`](https://github.com/excid3/tailwindcss-stimulus-components/blob/master/src/modal.js) (the `nodeName !== "DIALOG"` + selection guard, verbatim).

---

### Scroll lock

**Hotwire answer.** You have to write it — `<dialog>.showModal()` does **not** lock document scroll, verified in Chrome 151 and still an open spec issue ([whatwg/html#7732](https://github.com/whatwg/html/issues/7732), open since 2022). The `scroll-lock` primitive is ~20 lines and must do two things `overflow: hidden` alone doesn't: compensate for the vanishing scrollbar, and hold position on iOS Safari.

**Code.**

```css
/* Reserve the scrollbar gutter permanently. This alone removes the layout shift
   on Chrome 94+, Firefox 97+, Safari 18.2+ (verified, MDN BCD). */
html { scrollbar-gutter: stable; }
```

```js
// app/javascript/controllers/scroll_lock_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const doc = document.documentElement
    this.y = window.scrollY
    // Fallback for browsers without scrollbar-gutter: pad by the scrollbar width.
    if (!CSS.supports("scrollbar-gutter", "stable")) {
      const gap = window.innerWidth - doc.clientWidth
      if (gap > 0) doc.style.setProperty("--scrollbar-gap", `${gap}px`)
    }
    doc.classList.add("is-scroll-locked")
    // iOS Safari ignores overflow:hidden on <html>/<body>. Only position:fixed works,
    // and it destroys scroll position, so we save and restore it.
    if (this.isIOS) {
      document.body.style.cssText += `position:fixed;top:${-this.y}px;left:0;right:0;width:100%;`
    }
  }

  disconnect() {
    document.documentElement.classList.remove("is-scroll-locked")
    document.documentElement.style.removeProperty("--scrollbar-gap")
    if (this.isIOS) {
      document.body.style.position = ""
      document.body.style.top = ""
      window.scrollTo(0, this.y)
    }
  }

  get isIOS() {
    return /iP(ad|hone|od)/.test(navigator.platform) ||
           (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
  }
}
```

```css
html.is-scroll-locked { overflow: hidden; padding-right: var(--scrollbar-gap, 0); }
/* Stop the modal's own scroll from chaining to the page behind it. */
dialog .dialog__body { overscroll-behavior: contain; }
```

Attach it to the dialog: `data-controller="dialog scroll-lock"` — connect/disconnect line up with the frame being filled and emptied.

**Decomposition.** `scroll-lock`.

**A11y.** Locking scroll is *required* for a modal: without it the invoking element scrolls out of the viewport and focus-return lands off-screen (the original motivation in whatwg/html#7732). But if the dialog itself is taller than the viewport, the **dialog** must scroll — `dialog:modal` already has `overflow: auto` in the UA stylesheet; don't override it to `visible`.

**Native.** n/a — native modal presentation handles it. Skip the controller entirely under `turbo_native_app?` if the screen is presented as a native sheet.

**Pitfalls.**
- `overflow: hidden` on `<body>` alone is a no-op in several situations because the scrolling element is `<html>`. Set it on `document.documentElement`.
- **iOS Safari ignores `overflow: hidden` on both `<html>` and `<body>`.** `position: fixed` is the only reliable lock, and it resets scroll to 0 — hence the save/restore. This is why [hotwire_combobox vendors a `bodyScrollLock`](https://github.com/josefarias/hotwire_combobox/blob/main/app/assets/javascripts/hw_combobox/vendor/bodyScrollLock.js) rather than using `overflow: hidden`.
- Without `scrollbar-gutter: stable` (or the padding fallback) the entire page shifts a few pixels when the scrollbar disappears — a visible, cheap-looking jump. macOS overlay scrollbars hide it during development, so it ships broken.
- Nested overlays: lock/unlock must be reference-counted, or closing an inner popover unlocks the page while the outer modal is still open. Track a counter on `document.documentElement.dataset`.
- Don't lock scroll for non-modal popovers or tooltips.

**Prior art.** [`bodyScrollLock`](https://github.com/willmcpo/body-scroll-lock) (vendored inside hotwire_combobox); [MDN `scrollbar-gutter`](https://developer.mozilla.org/en-US/docs/Web/CSS/scrollbar-gutter); [MDN `overscroll-behavior`](https://developer.mozilla.org/en-US/docs/Web/CSS/overscroll-behavior); [whatwg/html#7732](https://github.com/whatwg/html/issues/7732).

---



## Forms — flow, validation & submission

### Client-side validation vs. server round-trip

**Hotwire answer.** **No JS needed** for the 90% case: native HTML constraint validation (`required`, `type="email"`, `pattern`, `min`/`max`/`step`, `maxlength`) for *shape*, styled with `:user-invalid` / `:user-valid` so a field only turns red after the user has actually touched it. The **server is the only source of truth** — every rule that matters is an ActiveRecord/ActiveModel validation, and the client-side layer is a pure UX affordance that saves a round-trip. Never implement a business rule twice.

**The decision rule.**

| Rule | Where it lives |
|---|---|
| Presence, length, format, numeric range, email/url shape | Native HTML attributes **and** the model. Duplication here is fine — the HTML attribute is generated *from* the same intent, and both are cheap. |
| Uniqueness, cross-record, cross-field, "does this coupon exist", authorization, anything needing the DB | **Server only.** Do not attempt it in JS. |
| "Passwords must match", "end date after start date" | Server. If you want instant feedback, `setCustomValidity` is acceptable, but the model validation is what enforces it. |
| Anything a malicious client could skip | Server, always. Client validation is not a security boundary. |

**Code.**

```erb
<%# app/views/users/_form.html.erb %>
<%= form_with model: @user do |f| %>
  <div class="field">
    <%= f.label :email %>
    <%= f.email_field :email, required: true,
          autocomplete: "email",
          aria: { describedby: "email_hint email_error" } %>
    <p id="email_hint" class="hint">We'll only use this to sign you in.</p>
    <%# server-rendered errors always win %>
    <p id="email_error" class="error"><%= @user.errors.full_messages_for(:email).first %></p>
  </div>

  <%= f.submit "Create account", data: { turbo_submits_with: "Creating…" } %>
<% end %>
```

```css
/* Only style AFTER interaction. :invalid alone paints every empty required
   field red on first paint — that is the bug :user-invalid exists to fix. */
.field:has(:user-invalid) .error::before { content: "⚠ "; }
input:user-invalid  { border-color: var(--danger); }
input:user-valid    { border-color: var(--success); }

/* Native bubbles are unstyleable; if you hide them you MUST render your own. */
```

`:user-invalid` / `:user-valid` are **Baseline "widely available" since November 2023** ([MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/:user-invalid)) — Chrome 119, Safari 16.5, Firefox 88. In 2026 you can use them unguarded. `:has()` is likewise Baseline, so `.field:has(:user-invalid)` for styling the wrapper is safe.

**`setCustomValidity` + the `invalid` event.** Use these when the browser has no built-in constraint for your rule:

```js
// app/javascript/controllers/confirmation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "confirmation"]

  check() {
    const mismatch = this.sourceTarget.value !== this.confirmationTarget.value
    // "" clears the error; any non-empty string marks the field invalid.
    this.confirmationTarget.setCustomValidity(mismatch ? "Passwords don't match." : "")
  }
}
```

```js
// The `invalid` event does NOT bubble. A listener on the <form> only fires with
// capture. This is the single most common reason "my invalid handler never runs".
form.addEventListener("invalid", (event) => {
  event.preventDefault()             // suppress the native bubble
  showOwnMessage(event.target)
}, true)                              // ← capture: true is mandatory
```

**`novalidate` and Turbo.** Turbo submits via `form.requestSubmit()` (from `data-turbo-method` links) and intercepts the `submit` event, so **native validation still runs** — Turbo does not bypass it. You want `novalidate` in exactly three situations:

1. **A `required` field inside a hidden container.** This is the killer, and it happens constantly with nested forms: when you soft-remove a nested row by hiding the wrapper (see *Nested forms*), a `required` input inside it is still in the form. The browser refuses to submit and logs `An invalid form control with name='…' is not focusable` — with no visible message, because it can't scroll to an invisible field. The form just dies silently.
2. **Multi-step wizards** where step 3's fields exist in the DOM but aren't filled yet.
3. **You've committed to fully custom error UI** and don't want the native bubble racing your own.

```erb
<%= form_with model: @survey, html: { novalidate: true } do |f| %>
```

Adding `novalidate` costs you **zero correctness** — the server validates identically. It costs you one round-trip of latency on a bad submit. That is a fine trade, and it's why many mature Hotwire apps set `novalidate` globally and lean entirely on `:user-invalid` + server errors.

**Decomposition.**
- Nothing. This is HTML + CSS.
- `char-count` for `maxlength` feedback (see below).
- Optional tiny Stimulus for `setCustomValidity` cross-field rules; do not build a general "validation" controller.

**A11y.**
- Associate the error text with the input via `aria-describedby`, and add `aria-invalid="true"` on server re-render. Do **not** set `aria-invalid` pre-emptively.
- `:user-invalid` is purely visual — screen readers get nothing from it. The accessible signal is the server-rendered `<p id="…_error">` plus `aria-describedby`.
- Never rely on colour alone; the `⚠` glyph / icon carries the meaning for colour-blind users.
- On server re-render, move focus to the first invalid field or to the error summary (`tabindex="-1"` + `.focus()`), and give the summary `role="alert"`.

**Native.** n/a — native constraint validation works identically inside a Hotwire Native web view. Do not attempt to mirror validation into the native shell.

**Pitfalls.**
- `:invalid` (without `user-`) matches empty required fields **on first paint**. Every "why is my whole form red before I typed anything" bug is this.
- The `invalid` event does not bubble (capture only) and does not fire at all for `form.submit()` (see *Autosave*).
- Native validation bubbles are unstyleable and untranslatable beyond the browser locale.
- `pattern` is anchored implicitly (`^(?:…)$`) and uses the `v`/`u` regex flag — JS regexes with `\d` etc. are fine, but Ruby-flavoured regexes with `\A`/`\z` are not.
- A `required` `<input type="hidden">` is never validated; a `required` input in a `display:none` wrapper *is*, and blocks submission. See above.
- Turbo's default cache preview can restore a field that was `:user-invalid`; the pseudo-class state does not survive the snapshot. Server-rendered errors do.

**Prior art.**
- [MDN: Client-side form validation](https://developer.mozilla.org/en-US/docs/Learn_web_development/Extensions/Forms/Form_validation)
- [MDN: `:user-invalid`](https://developer.mozilla.org/en-US/docs/Web/CSS/:user-invalid) — Baseline widely available since Nov 2023
- [MDN: Constraint Validation API](https://developer.mozilla.org/en-US/docs/Web/API/Constraint_validation)
- [Rails Guides: Active Record Validations](https://guides.rubyonrails.org/active_record_validations.html)
- [Rails Designer: Better Inline Validation for Rails Forms](https://railsdesigner.com/inline-form-validations/) (2024-08-22) — `errors.full_messages_for(field)` in a `FormLabelComponent`

---

### Inline field validation on blur

**Hotwire answer.** A `blur` action submits **that one field** to a dedicated validation endpoint, which instantiates the model, calls `valid?`, and returns a Turbo Stream that replaces **only that field's wrapper**. Use a `<turbo-frame>` per field if you want zero JS, or a 15-line `remote-validate` controller if you want it on `blur` specifically. **Be honest: this is only worth building for constraints the client genuinely cannot check — uniqueness (email/username/slug taken), remote lookups (coupon code, VAT number), and expensive cross-record rules.** For presence/format/length, `:user-invalid` gives you the same UX with no server, no endpoint, and no code.

**Code.**

```ruby
# config/routes.rb
resources :users do
  collection do
    post :validate            # POST so the value never lands in a URL/log
  end
end
```

```ruby
# app/controllers/users_controller.rb
def validate
  attribute = params.require(:attribute).to_sym
  raise ActionController::BadRequest unless User::VALIDATABLE.include?(attribute)

  # Build a throwaway record carrying ONLY the field under test, plus the id so
  # uniqueness validations correctly exclude the record being edited.
  @user = User.find_by(id: params[:id]) || User.new
  @user.assign_attributes(user_params.slice(attribute))
  @user.valid?                                    # populates errors for every attribute…

  render turbo_stream: turbo_stream.replace(
    "user_#{attribute}_field",
    partial: "users/field",
    locals: { user: @user, attribute: attribute }
  )
end
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  VALIDATABLE = %i[email username].freeze
  validates :email,    presence: true, uniqueness: { case_sensitive: false }
  validates :username, presence: true, length: { in: 3..30 },
                       uniqueness: true, format: { with: /\A[a-z0-9_]+\z/i }
end
```

```erb
<%# app/views/users/_field.html.erb — locals: (user:, attribute:) %>
<%# Rendering ONLY this attribute's errors is the whole trick: user.errors is
    full of complaints about fields the user hasn't reached yet. %>
<% errors = user.errors.full_messages_for(attribute) %>
<div id="user_<%= attribute %>_field" class="field">
  <%= label_tag "user_#{attribute}", attribute.to_s.humanize %>
  <%= text_field :user, attribute,
        value: user.public_send(attribute),
        required: true,
        aria: { invalid: errors.any?, describedby: "user_#{attribute}_error" },
        data: { action: "blur->remote-validate#run",
                remote_validate_attribute_param: attribute } %>
  <p id="user_<%= attribute %>_error" class="error"><%= errors.first %></p>
</div>
```

```js
// app/javascript/controllers/remote_validate_controller.js
// Put this on the <form>. It POSTs one field and renders the Turbo Stream reply.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  async run({ params: { attribute }, target }) {
    if (target.value === target.dataset.lastValidated) return   // don't re-check unchanged
    target.dataset.lastValidated = target.value

    const body = new FormData()
    body.append("attribute", attribute)
    body.append(`user[${attribute}]`, target.value)
    const id = this.element.querySelector("input[name='user[id]']")?.value
    if (id) body.append("id", id)

    const response = await fetch(this.urlValue, {
      method: "POST",
      body,
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content
      }
    })
    if (response.ok) Turbo.renderStreamMessage(await response.text())
  }
}
```

```erb
<%= form_with model: @user,
      data: { controller: "remote-validate",
              remote_validate_url_value: validate_users_path } do |f| %>
  <%= render "users/field", user: @user, attribute: :email %>
  <%= render "users/field", user: @user, attribute: :username %>
  <%= f.submit "Save", data: { turbo_submits_with: "Saving…" } %>
<% end %>
```

**The zero-JS variant.** Wrap each field in a `<turbo-frame id="user_email_field">` and give the field a sibling submit button (`formaction: validate_users_path, formmethod: :get`) that the user never sees but that `autosubmit` triggers on `change`. It works, but you pay a full GET per field and you can't distinguish `blur` from `change`. The Stimulus version above is 15 lines and better; use it.

**The cheaper alternative — and usually the right one.** Just let the form round-trip on submit. `render :new, status: :unprocessable_content` re-renders every field with its errors in ~40ms on a warm app. For a 6-field signup form, per-field blur validation buys you almost nothing and costs you: an extra route, an authorization surface (`VALIDATABLE` allow-list — without it you have a model-introspection oracle), N extra requests per form fill, and a partial that must stay in sync with the main form. **Build it for username/email availability. Don't build it for "name can't be blank".**

**Decomposition.**
- `remote-validate` (NEW — see end of file) — on blur, POST one field's name/value to a URL and render the returned Turbo Stream.
- Optionally debounced via stimulus-use `useDebounce` if you also want it on `input`.

**A11y.**
- `aria-invalid="true"` on the input when errors are present; `aria-describedby` pointing at the error `<p>`.
- The error `<p>` should be `aria-live="polite"` **or** `role="status"` so the replacement is announced. Do not use `role="alert"` per-field — with several fields it becomes a machine-gun.
- Replacing the wrapper is a DOM swap: Turbo's stream renderer restores focus **only if the focused element has an `id`** (`withPreservedFocus` in `src/core/streams/stream_message_renderer.js`). Since this fires on `blur` the input isn't focused anyway, but keep the `id` stable regardless.
- Never move focus back to the field on error — the user is on their way to the next field.

**Native.** n/a. Works unchanged in a Hotwire Native web view. Avoid the `blur`-triggered request on mobile: soft-keyboard dismissal fires `blur` at awkward times and you'll double-request.

**Pitfalls.**
- **`Model.new(param).tap(&:valid?)` populates errors for *every* attribute.** If you render `user.errors.full_messages` you'll show "Password can't be blank" the moment they blur the email field. Always scope with `errors.full_messages_for(attribute)` / `errors.where(attribute)`.
- Uniqueness validation on a **persisted** record needs the record's `id`, or `User.new(email: …).valid?` reports "has already been taken" against itself.
- Uniqueness validation here is a UX hint, not a guarantee. You still need the DB unique index and `rescue ActiveRecord::RecordNotUnique`.
- Do not accept an arbitrary `attribute` param. Allow-list it, or you've built an endpoint that reports on any column.
- Rate-limit the endpoint (`rate_limit to: 20, within: 1.minute` in Rails 8) — an unthrottled "is this email taken" endpoint is a user-enumeration oracle.
- The field partial must render identically to the one in the main form, or the layout jumps on first validation. Extract it once and render it from both places (as above).

**Prior art.**
- [Rails Designer: Better Inline Validation for Rails Forms](https://railsdesigner.com/inline-form-validations/) (2024) — the `full_messages_for` label-swap approach
- [Rails: `ActiveModel::Errors#full_messages_for`](https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-full_messages_for)
- [Rails 8 `rate_limit`](https://api.rubyonrails.org/classes/ActionController/RateLimiting/ClassMethods.html)
- No maintained gem does this well; `client_side_validations` (https://github.com/DavyJonesLocker/client_side_validations) mirrors model validations into JS and is a maintenance trap — **do not use it**, it duplicates business rules by design.

---

### Form errors via Turbo Streams

**Hotwire answer.** **The Rails 8 scaffold idiom is correct and you should use it:** `render :new, status: :unprocessable_content`. Turbo re-renders the response body in place, URL unchanged, no JS. Reach for a targeted Turbo Stream **only** when the form lives inside a frame whose id doesn't match the response, or when you need to update something outside the form (a header error count, a flash region). Morphing is the third option and is the right answer when the form is on a page you're refreshing anyway.

**Code — (a) the canonical scaffold idiom. Default to this.**

```ruby
# app/controllers/posts_controller.rb
def create
  @post = Post.new(post_params)
  if @post.save
    redirect_to @post, notice: "Post created", status: :see_other
  else
    render :new, status: :unprocessable_content   # 422 — REQUIRED
  end
end

def update
  if @post.update(post_params)
    redirect_to @post, notice: "Updated", status: :see_other
  else
    render :edit, status: :unprocessable_content
  end
end
```

Turbo's rule (see [02-turbo-deep-dive §2.10](../notes/02-turbo-deep-dive.md)): 4xx/5xx → render in place; 2xx + redirect → visit; **2xx without redirect → console error and nothing renders**. That last line is why plain `render :new` silently does nothing.

**(b) Targeted stream replacement of an errors partial.** Use when the form is inside a `<turbo-frame>` that the `new`/`edit` template doesn't reproduce, or when you must touch two regions.

```ruby
def create
  @post = Post.new(post_params)
  if @post.save
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.prepend("posts", @post) }
      format.html { redirect_to posts_path, status: :see_other }
    end
  else
    render turbo_stream: [
      turbo_stream.replace(@post, partial: "posts/form", locals: { post: @post }),
      turbo_stream.update("flash", partial: "shared/flash",
                          locals: { alert: "Couldn't save that post." })
    ], status: :unprocessable_content
  end
end
```

> `status: :unprocessable_content` on a `turbo_stream` response is **not** required for the stream to apply. Verified in Turbo 8.0.23: `StreamObserver#inspectFetchResponse` calls `fetchResponseIsStream`, which tests **only** `response.contentType.startsWith("text/vnd.turbo-stream.html")` — the status code is never consulted. Keep the 422 anyway: it keeps the semantics honest for non-Turbo clients, request specs, and error monitoring.

**(c) Morphing.** If the page already declares `<meta name="turbo-refresh-method" content="morph">`, a failed submit that redirects back to the same URL will morph errors into place while preserving scroll, focus, and untouched sibling DOM.

```ruby
def create
  @post = Post.new(post_params)
  if @post.save
    redirect_to @post, status: :see_other
  else
    render :new, status: :unprocessable_content
  end
end
```

```erb
<%# app/views/layouts/application.html.erb %>
<meta name="turbo-refresh-method" content="morph">
<meta name="turbo-refresh-scroll" content="preserve">
```

Morphing **is not** a replacement for the 422 — it's a rendering strategy for the response you already returned. But it does obsolete hand-rolled "replace the errors div" streams on morph-enabled pages: just re-render the page and let idiomorph diff it. See [02-turbo-deep-dive §5.7](../notes/02-turbo-deep-dive.md).

**When each.**

| Situation | Use |
|---|---|
| Ordinary full-page form | (a) `render :new, status: :unprocessable_content` |
| Form in a modal/slide-over frame | (a) **plus** a matching `<turbo-frame>` in `new.html.erb`, or (b) |
| Need to update the form *and* a counter/flash elsewhere | (b) |
| Page already morph-refreshing; form is one region among many | (c) |
| Form submitted into a frame targeting `_top` | (a) |

**The classic "my form doesn't re-render errors" failure — in diagnosis order.**

1. **Missing the 422.** You wrote `render :new` (200). Turbo logs `Form responses must redirect to another location` and discards it. **Fix:** add `status: :unprocessable_content`.
2. **You redirected on failure.** `redirect_to new_post_path` throws away `@post.errors`. Never redirect on validation failure. (If you must, `flash[:post_errors]` is a smell — re-render instead.)
3. **The form is inside a `<turbo-frame id="modal">` and `new.html.erb` doesn't contain a frame with that id.** Turbo finds no matching frame and blanks it: *"Response has no matching `<turbo-frame id="modal">` element"*. **Fix:** wrap `new.html.erb`'s body in the same frame, or `render turbo_stream: turbo_stream.replace("modal", …)`. See [02-turbo-deep-dive §3.6](../notes/02-turbo-deep-dive.md).
4. **`format.turbo_stream` block missing.** Turbo sends `Accept: text/vnd.turbo-stream.html, text/html, …` on unsafe submits. If your `respond_to` has a `turbo_stream` branch that renders nothing on the failure path, you get an empty 422. Make the failure path explicit in **both** formats.
5. **The submit button is outside the form and has no `form=` attribute** — nothing submits at all.
6. **`data-turbo="false"` somewhere up the tree** — the form does a native submit and you get a full page load with a raw 422 body.

**Decomposition.**
- Nothing. This is Rails.
- `dirty-form` if you want to clear the unsaved-changes guard on `turbo:submit-end`.

**A11y.**
- Give the error summary `role="alert"` (or `tabindex="-1"` + focus it on render). A 422 in-place render is invisible to a screen-reader user otherwise — the URL didn't change and there was no page-load announcement.
- `aria-invalid="true"` + `aria-describedby` on each errored input.
- Follow the [WAI-ARIA APG alert pattern](https://www.w3.org/WAI/ARIA/apg/patterns/alert/) for the summary region.

```erb
<% if @post.errors.any? %>
  <div id="error_explanation" role="alert" tabindex="-1"
       data-controller="focus-trap" data-focus-trap-auto-value="false">
    <h2><%= pluralize(@post.errors.count, "error") %> prevented saving:</h2>
    <ul><% @post.errors.each do |e| %><li><%= e.full_message %></li><% end %></ul>
  </div>
<% end %>
```

**Native.** Hotwire Native follows the same rules — a 422 renders in place inside the web view. If the form is presented as a native modal screen, make sure the failure path re-renders the *modal* layout, not the full app chrome, or the user sees your navbar inside a sheet. Path configuration should mark the form URL as `modal` and the success redirect should use `recede_or_redirect_to` (turbo-rails 2.x native helpers) so the sheet dismisses. See `04-hotwire-native.md`.

**Pitfalls.**
- `:unprocessable_entity` still resolves to 422 but is a deprecated Rack alias. Write `:unprocessable_content`. Every tutorial dated before ~2025 says `:unprocessable_entity` — including [Rails Designer's Turbo Frame validations post](https://railsdesigner.com/turbo-frame-form-validations/) (2024-04-04) and every hotrails.dev chapter. Flagged.
- A 500 renders through `renderError`, which replaces `<head>` **and** `<body>` — your JS reboots. Don't rely on 500s for anything.
- `render :new` re-runs `new.html.erb`, which often calls `Model.new` or `.build` for nested fields — that can double up blank nested rows on re-render. Guard those.
- Turbo Streams on failure bypass the browser's back-forward cache semantics: the URL is unchanged, so a back-navigation loses the errors. That's correct behaviour, but users complain.

**Prior art.**
- [Turbo Handbook: Redirecting After a Form Submission](https://turbo.hotwired.dev/handbook/drive#redirecting-after-a-form-submission)
- [Rails Designer: Easy Peasy Form Validation Errors with Rails Turbo Frames](https://railsdesigner.com/turbo-frame-form-validations/) (2024-04-04, uses `:unprocessable_entity` — update it)
- [hotrails.dev: Turbo Frames and Turbo Stream templates](https://www.hotrails.dev/turbo-rails/turbo-frames-and-turbo-streams) (pre-Turbo-8; `:unprocessable_entity`)
- [rails/rails#53383 — `:unprocessable_content`](https://github.com/rails/rails/pull/53383)

---

### Dependent / cascading selects

**Hotwire answer.** Wrap the dependent select in a `<turbo-frame>`, and put `autosubmit` on the parent select so a `change` fires a **GET** that re-renders just that frame with the filtered options. **No JSON, no client-side data duplication, no fetch.** The frame wins over the Stimulus-fetch-JSON approach because the option list is rendered by the same ERB partial as the initial page load — one source of truth, works with `collection_select`, respects authorization scoping, and is inspectable in the network tab as HTML.

**Code — frame around the dependent select (the default).**

```ruby
# config/routes.rb
resources :addresses do
  collection { get :states }
end
```

```erb
<%# app/views/addresses/_form.html.erb %>
<%= form_with model: @address do |f| %>
  <div class="field">
    <%= f.label :country_id %>
    <%= f.collection_select :country_id, Country.order(:name), :id, :name,
          { include_blank: "Choose a country" },
          { form: "state_lookup",              # ← the select belongs to BOTH forms
            data: { action: "change->autosubmit#submit" } } %>
  </div>

  <turbo-frame id="state_select">
    <%= render "addresses/state_select", f: f, country: @address.country %>
  </turbo-frame>

  <%= f.submit "Save address", data: { turbo_submits_with: "Saving…" } %>
<% end %>

<%# A second, hidden GET form whose only job is to reload the frame.
    `form=` lets the country select participate in it without nesting forms. %>
<%= form_with url: states_addresses_path, method: :get, id: "state_lookup",
      data: { controller: "autosubmit", turbo_frame: "state_select" } do %>
<% end %>
```

```erb
<%# app/views/addresses/_state_select.html.erb — locals: (f:, country:) %>
<div class="field">
  <%= f.label :state_id %>
  <% states = country ? country.states.order(:name) : State.none %>
  <%= f.collection_select :state_id, states, :id, :name,
        { include_blank: country ? "Choose a state" : "Choose a country first" },
        { disabled: country.nil?, aria: { live: "polite" } } %>
</div>
```

```ruby
# app/controllers/addresses_controller.rb
def states
  @address = Address.new(country_id: params.dig(:address, :country_id))
  render :states
end
```

```erb
<%# app/views/addresses/states.html.erb — the frame response %>
<%# Re-enter fields_for rather than trying to pass a form builder across the
    request boundary. Rails emits identical name="address[state_id]" attributes
    either way, so the field submits with the outer form correctly. %>
<turbo-frame id="state_select">
  <%= fields_for :address, @address do |f| %>
    <%= render "addresses/state_select", f: f, country: @address.country %>
  <% end %>
</turbo-frame>
```

**Variant — the whole form is the frame.** Simpler, and what most apps should do when the form is small:

```erb
<turbo-frame id="address_form">
  <%= form_with model: @address, url: (@address.new_record? ? addresses_path : address_path(@address)) do |f| %>
    <%= f.collection_select :country_id, Country.order(:name), :id, :name,
          { include_blank: true },
          { data: { action: "change->autosubmit#submitFor" },
            formaction: refresh_addresses_path, formmethod: :get } %>

    <%= f.collection_select :state_id, @address.country&.states || State.none, :id, :name %>
    <%= f.submit %>
  <% end %>
</turbo-frame>
```

```ruby
def refresh
  @address = Address.new(address_params)   # keeps everything the user already typed
  render :refresh                          # a template containing <turbo-frame id="address_form">
end
```

Cost: the whole form re-renders, so any *uncommitted* state outside the model (file inputs, an open date picker, caret position elsewhere) is lost. Benefit: one code path, and the round-trip preserves every other typed value because you rebuilt the model from params. **Use the whole-form frame when the form has ≤ ~10 fields; use the field-scoped frame otherwise.**

**Why the frame beats Stimulus + fetch JSON.**

| | Turbo Frame | Stimulus + `fetch` JSON |
|---|---|---|
| Option rendering | One ERB partial, shared with initial load | Duplicated in JS (`new Option(...)`) |
| Authorization / scoping | Free — it's a normal controller action | You must remember to scope the JSON |
| Blank state, disabled state, hints | ERB | More JS |
| i18n | `t()` | You ship translations to JS |
| Works with `hotwire_combobox`, `simple_form`, custom builders | Yes | You reimplement each |
| Extra code | ~0 lines JS | ~40 lines and growing |

The JSON approach is only better when you have a genuinely huge option set that you want to search client-side — and at that point you want a combobox, not a select.

**Searchable case.** For a country/state pair with hundreds of options, use [`hotwire_combobox`](https://github.com/josefarias/hotwire_combobox) (v0.4.1, 2026-02-13; actively developed — last push 2026-08-10). Its `combobox_tag` helper takes either an options array or an **`src:`** for async/paginated options, so the dependent case becomes "point the child combobox's `src` at a URL carrying the parent's value":

```erb
<%= f.combobox :country_id, Country.order(:name), include_blank: "Any country",
      data: { action: "change->autosubmit#submit" } %>

<turbo-frame id="state_combobox">
  <%= f.combobox :state_id, src: states_addresses_path(country_id: @address.country_id) %>
</turbo-frame>
```

Note the gem's own README still says *"HotwireCombobox is at an early stage of development"* — it's pre-1.0 and the API may move. It is nonetheless the best-maintained accessible autocomplete in the Rails ecosystem and follows the [APG combobox pattern](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/) deliberately.

**Decomposition.**
- `autosubmit` (with `change`, no debounce — selects don't need one).
- Optionally `combobox` for the searchable variant.
- `sync` if you also need to mirror the parent value into a display element.

**A11y.**
- The dependent `<select>` must be `disabled` (not just empty) until a parent is chosen, and its `include_blank` label should say *why* ("Choose a country first").
- Put `aria-live="polite"` on the wrapper inside the frame so the option-count change is announced. Do **not** put it on the `<select>` itself — announcing 50 options is hostile.
- Frame navigation sets `aria-busy="true"` on the `<turbo-frame>` automatically (Turbo `markAsBusy`); style a spinner off `turbo-frame[aria-busy] { … }`.
- Preserve the user's previous state selection if it's still valid after the country change; silently clearing it is a common complaint.
- Combobox case: follow [APG combobox](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/); `hotwire_combobox` already does.

**Native.** Consider a **bridge component**: on iOS/Android a long `<select>` renders as a native picker anyway, so plain HTML is usually right. If the option list is large, path-configure the child selection as a native list screen that posts back and lets the frame reload. `data-turbo-action` is irrelevant here — frame loads shouldn't push history for a select change.

**Pitfalls.**
- **`form=` is the key trick** for having a control in one form drive a different form. Nested `<form>` elements are invalid HTML and browsers silently drop the inner one.
- Rebuild the model from params in the refresh action (`Address.new(address_params)`) or every other field resets to blank.
- A GET form's query string is **rebuilt from the form data** by Turbo (`getAction` clears `action.search` for safe methods) — you cannot smuggle extra params in the `action` URL; use hidden inputs.
- If the child `<select>` has `required` and is disabled, it's exempt from validation (disabled controls are barred from constraint validation) — good. If it's `required` and merely empty, the browser blocks submit with an unfocusable-control error if it's inside a hidden frame.
- Three-level cascades (country → state → city) need each level in its own frame, each triggered by the level above; the grandchild must reload when the child changes, not when the grandparent does.
- Don't put `data-turbo-action="advance"` on this frame. A cascading select is not a navigation; you'll litter history with one entry per keystroke of the parent select.

**Prior art.**
- [hotwire_combobox](https://github.com/josefarias/hotwire_combobox) — v0.4.1 (2026-02-13), `combobox_tag` / `f.combobox`, `src:` for async, `paginated_combobox_options`
- [Turbo Handbook: Frames](https://turbo.hotwired.dev/handbook/frames)
- [stimulus-components auto-submit](https://www.stimulus-components.com/docs/stimulus-auto-submit)
- Superseded: `select2` + `grouped_options_for_select` + jQuery `.change()` handlers; `chosen-rails`.

---

### Nested forms — dynamic add/remove fields (the `cocoon` replacement problem)

**Hotwire answer.** `accepts_nested_attributes_for` + `fields_for` + a `<template>` holding one blank record whose child index is the literal `NEW_RECORD`, cloned by a ~25-line `nested-form` Stimulus controller that swaps `NEW_RECORD` for `Date.now()`. **This is the cocoon replacement and it is not a gem** — either vendor the controller or install `@stimulus-components/rails-nested-form`. There is also a **pure-Turbo-Stream** variant with zero custom JS that is genuinely excellent; pick based on whether the new row needs anything from the server.

**cocoon is dead.** [nathanvda/cocoon](https://github.com/nathanvda/cocoon): last gem release **1.2.15 on 2020-09-08**, last repo activity 2023-08-08, README caps at "rails 3, 4 and 5" plus a Rails 6/Webpacker note, and it hard-depends on jQuery. It was superseded by Rails 7 (Dec 2021) dropping jQuery from the default stack in favour of Hotwire; by 2022 the Stimulus `<template>` pattern was the community answer. [ncri/nested_form_fields](https://github.com/ncri/nested_form_fields) is worse off — last release 0.8.4, 2020-07-17, also jQuery. **Do not install either in 2026.**

**Code — the model and controller.**

```ruby
# app/models/survey.rb
class Survey < ApplicationRecord
  has_many :questions, dependent: :destroy
  accepts_nested_attributes_for :questions,
    allow_destroy: true,          # required for _destroy to do anything
    reject_if: :all_blank         # drops the row if every attribute is blank
end
```

```ruby
# app/controllers/surveys_controller.rb
def new
  @survey = Survey.new
  @survey.questions.build          # seed ONE row so the form isn't empty
end

def create
  @survey = Survey.new(survey_params)
  if @survey.save
    redirect_to @survey, status: :see_other
  else
    render :new, status: :unprocessable_content
  end
end

private

def survey_params
  params.require(:survey).permit(
    :name,
    questions_attributes: [:id, :_destroy, :content, :position]
  )
end
```

> `:id` and `:_destroy` in the permit list are **not optional**. Without `:id`, every submit creates duplicate children instead of updating them. Without `:_destroy`, removal silently no-ops. This is the #1 nested-forms bug.

**The view.**

```erb
<%# app/views/surveys/_form.html.erb %>
<%= form_with model: survey, html: { novalidate: true },
      data: { controller: "nested-form" } do |f| %>
  <%= render "shared/error_summary", record: survey %>

  <div class="field">
    <%= f.label :name %><%= f.text_field :name, required: true %>
  </div>

  <%= f.fields_for :questions do |question_f| %>
    <%= render "surveys/question_fields", f: question_f %>
  <% end %>

  <%# insertion anchor: new rows go BEFORE this element %>
  <div data-nested-form-target="target"></div>

  <template data-nested-form-target="template">
    <%= f.fields_for :questions, Question.new, child_index: "NEW_RECORD" do |question_f| %>
      <%= render "surveys/question_fields", f: question_f %>
    <% end %>
  </template>

  <button type="button" data-action="nested-form#add">Add question</button>
  <%= f.submit "Save survey", data: { turbo_submits_with: "Saving…" } %>
<% end %>
```

```erb
<%# app/views/surveys/_question_fields.html.erb — locals: (f:) %>
<div class="nested-form-wrapper"
     data-new-record="<%= f.object.new_record? %>"
     id="<%= "question_fields_#{f.object.id || f.index}" %>">
  <%= f.hidden_field :id unless f.object.new_record? %>
  <%= f.hidden_field :_destroy %>

  <%= f.label :content, "Question" %>
  <%= f.text_area :content, rows: 2 %>

  <button type="button" data-action="nested-form#remove"
          aria-label="Remove question">Remove</button>
</div>
```

Note `f.fields_for :questions, Question.new, child_index: "NEW_RECORD"` — **`Question.new`, not `f.object.questions.build`**. Calling `.build` from a view mutates the parent's in-memory association as a side effect of rendering, so a re-render after a validation failure accumulates extra blank rows. Seed rows in the **controller** (`@survey.questions.build`), never in the template.

**The controller (this is `@stimulus-components/rails-nested-form` v5.0.0, verbatim from [`src/index.ts`](https://github.com/stimulus-components/stimulus-components/blob/master/components/rails-nested-form/src/index.ts), translated to plain JS).**

```js
// app/javascript/controllers/nested_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["target", "template"]
  static values = { wrapperSelector: { type: String, default: ".nested-form-wrapper" } }

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime().toString())
    this.targetTarget.insertAdjacentHTML("beforebegin", content)
    this.element.dispatchEvent(new CustomEvent("nested-form:add", { bubbles: true }))
  }

  remove(event) {
    event.preventDefault()
    const wrapper = event.target.closest(this.wrapperSelectorValue)
    if (!wrapper) return

    if (wrapper.dataset.newRecord === "true") {
      wrapper.remove()                                  // unpersisted → real DOM removal
    } else {
      wrapper.style.display = "none"                    // persisted → HIDE, never remove
      const input = wrapper.querySelector("input[name*='_destroy']")
      if (input) input.value = "1"
    }
    this.element.dispatchEvent(new CustomEvent("nested-form:remove", { bubbles: true }))
  }
}
```

**Get this right — remove semantics.**

| Row state | Correct action | Why |
|---|---|---|
| **Unpersisted** (`data-new-record="true"`, no `id` hidden field) | `wrapper.remove()` — real DOM removal | There is nothing on the server to destroy. Leaving it hidden means `reject_if: :all_blank` has to save you, and if the user typed something before removing, you'd create the record anyway. |
| **Persisted** (has `id`) | `wrapper.style.display = "none"` **and** set the `_destroy` input to `"1"` | The `id` and `_destroy` inputs must reach the server for `allow_destroy: true` to fire. Remove the wrapper from the DOM and the record silently survives. |

`display: none` (and the `hidden` attribute) still submits the contained inputs — that is exactly why it works. `disabled` does **not** submit; never use `disabled` here.

Rails Designer's [2026 follow-up](https://railsdesigner.com/extending-nested-forms-stimulus/) uses a different, arguably cleaner discriminator — the *presence* of the `_destroy` input, since a brand-new row's template never renders one:

```js
remove(event) {
  const field = event.target.closest("[data-nested-form-wrapper]")
  const destroyInput = field.querySelector('input[name*="_destroy"]')
  if (destroyInput) { destroyInput.value = "1"; field.hidden = true } else { field.remove() }
}
```

Either discriminator is fine. Pick one and be consistent.

**A `link_to_add_fields` helper, if you miss cocoon's ergonomics.**

```ruby
# app/helpers/nested_form_helper.rb
module NestedFormHelper
  # <%= add_fields_button(f, :questions, "Add question") %>
  def add_fields_button(form, association, label, partial: nil)
    klass   = form.object.class.reflect_on_association(association).klass
    partial ||= "#{association.to_s.singularize.pluralize}/fields"

    template = capture do
      form.fields_for association, klass.new, child_index: "NEW_RECORD" do |nested|
        render(partial, f: nested)
      end
    end

    safe_join([
      tag.template(template, data: { nested_form_target: "template" }),
      tag.button(label, type: "button", data: { action: "nested-form#add" })
    ])
  end
end
```

**The pure-Turbo-Stream alternative — zero custom JS.** The server renders and appends the fields. From [Rails Designer, *Nested Forms With Turbo (without dependencies)*](https://railsdesigner.com/rails-nested-forms-with-turbo/) (2024-08-15):

```erb
<%# inside the survey form — a button that GETs a turbo_stream %>
<div id="questions">
  <%= f.fields_for :questions do |qf| %><%= render "surveys/question_fields", f: qf %><% end %>
</div>

<%= button_tag "Add Question", type: :submit,
      formaction: new_question_path, formmethod: :get,
      data: { turbo_stream: true } %>
```

```erb
<%# app/views/questions/new.turbo_stream.erb %>
<%= turbo_stream.append "questions" do %>
  <%= fields_for "survey[questions_attributes][]", Question.new, index: Time.current.to_i do |f| %>
    <%= render "surveys/question_fields", f: f %>
  <% end %>
<% end %>
```

`index: Time.current.to_i` plays exactly the role `NEW_RECORD` → `Date.now()` plays client-side — without it every appended row shares an index and only the last one saves. `data-turbo-stream` on the submitter is what makes Turbo request `text/vnd.turbo-stream.html` on a **GET** ([02-turbo-deep-dive §2.10](../notes/02-turbo-deep-dive.md): safe submissions don't ask for streams unless the form or submitter has `data-turbo-stream`).

**When the stream variant is better:**
- The new row needs server data — a default value, a computed price, a scoped `collection_select`, an i18n'd label set, an Active Storage direct-upload token.
- You want the row markup to exist in exactly one place with zero placeholder-substitution magic.
- You already have a persisted parent (an editing flow), or you're working against a **draft record** created up front (`Survey.create!(status: :draft)` on `#new`), which also unlocks per-row autosave and file uploads.

**When the Stimulus variant is better:**
- Adding a row is pure static HTML (the common case). A network round-trip to insert two `<input>`s is silly on a flaky connection.
- The user may add ten rows quickly.

Note the article's claim that this "requires" nothing special: it works fine with an **unpersisted** parent because the appended fields are named `survey[questions_attributes][<index>][…]` regardless of whether `@survey` has an id. A persisted parent is only required if you want the row to *be* a record immediately.

**The morphing interaction — this bites.** A Turbo 8 page refresh with `<meta name="turbo-refresh-method" content="morph">` reconciles the DOM against the server's HTML via idiomorph. A client-added, unsaved nested row **does not exist in the server's response**, so idiomorph removes it. Confirmed in Turbo 8.0.23's `src/core/morphing.js`: `DefaultIdiomorphCallbacks#beforeNodeRemoved` delegates to `beforeNodeMorphed`, which returns `false` (i.e. "don't touch") **only** for elements carrying `data-turbo-permanent`. So:

```erb
<%# protect unsaved rows from morph — needs a UNIQUE, STABLE id %>
<div class="nested-form-wrapper" data-turbo-permanent
     id="question_fields_<%= f.object.id || f.index %>">
```

Caveats: `data-turbo-permanent` requires a unique `id` and makes the element opt out of *all* server-driven updates while it's permanent — including legitimate ones. `shouldRefreshFrameWithMorphing` also refuses to morph-refresh any frame inside `[data-turbo-permanent]`. Related: [hotwired/turbo#1142](https://github.com/hotwired/turbo/issues/1142) (client-injected DOM destroyed by morph; wrapping in `data-turbo-permanent` was the fix), and the still-open [hotwired/turbo#1477](https://github.com/hotwired/turbo/issues/1477) asking for per-node morph-add/remove hooks. **Simplest correct answer: don't enable morph refreshes on pages with a live nested form, or mark the whole nested region permanent while it's dirty.** See [02-turbo-deep-dive §5.8](../notes/02-turbo-deep-dive.md).

**Decomposition.**
- `nested-form` — clone a `<template>` into a container, mark `_destroy`, unique child index.
- `sortable` if rows are reorderable (SortableJS wrapper PATCHing positions).
- `dirty-form` to guard navigation away from unsaved rows.
- `confirm` before removing a persisted row with content.

**A11y.**
- The remove button needs an accessible name that identifies *which* row: `aria-label="Remove question 3"` or `aria-label="Remove question: <%= truncate(f.object.content, length: 30) %>"`. Ten buttons all labelled "Remove" is unusable by screen reader.
- After **add**, move focus to the new row's first input. After **remove**, move focus to the next row's remove button, or to the "Add" button if it was the last row. Otherwise focus lands on `<body>` and the user is lost.
- Announce the change in a polite live region: `<p aria-live="polite" class="sr-only">Question 4 added.</p>`.
- Wrap rows in a `<fieldset>` with a `<legend>` when the group is semantically a set; give each row's container `role="group"` + `aria-label`.
- A hidden (`display:none`) removed row is correctly removed from the a11y tree — good. A row hidden only with `opacity: 0` or `visibility: hidden` + `position: absolute` is **not**; use `display:none` or the `hidden` attribute.

```js
// add focus management on top of the base controller
add(event) {
  // …insertAdjacentHTML…
  const row = this.targetTarget.previousElementSibling
  row.querySelector("input, textarea, select")?.focus()
  this.#announce(`Row added.`)
}
```

**Native.** n/a for the mechanism, but a long nested form is a poor native experience. Prefer path-configuring the child editor as its own native screen (list → detail → save → `recede_or_redirect_to` back to the list) over a 30-row scroll. If you keep the web form, the pure-Turbo-Stream variant behaves better because there's no `<template>` cloning to break under a morph-based native refresh.

**Pitfalls.**
- Forgetting `:id` in `permit` → duplicates on every update. Forgetting `:_destroy` → removal no-ops. Forgetting `allow_destroy: true` → `_destroy` is ignored entirely.
- `reject_if: :all_blank` silently drops rows where every attribute is blank — including a row the user meant to add. It also fires *before* `_destroy` is considered for new records.
- A `required` input inside a hidden removed wrapper blocks submission (`An invalid form control … is not focusable`). Either `novalidate` the form, or clear `required` when hiding.
- `new Date().getTime()` collides if the user clicks "Add" twice within the same millisecond. Rare but real; use a monotonic counter (`this.index = (this.index ?? Date.now()) + 1`) if the add button can be held down or scripted.
- Nested-nested (`fields_for` inside `fields_for`) needs a *different* placeholder token per level or the inner replace clobbers the outer index.
- Validation errors on nested records surface as `questions.content` on the parent's errors — `@survey.errors.full_messages` reads "Questions content can't be blank" with no indication of *which* question. Render per-row errors from `f.object.errors` inside the row partial.
- Turbo Drive's cached preview restores the DOM *as it was*, including your dynamically added rows, but not their `value`s if the browser didn't persist them. See *Form state across Turbo cache preview*.

**Prior art.**
- [@stimulus-components/rails-nested-form](https://github.com/stimulus-components/stimulus-components/tree/master/components/rails-nested-form) — v5.0.0 (2024-03-23); [docs](https://www.stimulus-components.com/docs/stimulus-rails-nested-form). Targets `target`/`template`, value `wrapperSelector` (default `.nested-form-wrapper`), token `NEW_RECORD`, discriminator `data-new-record`. **The recommended off-the-shelf option.**
- [Rails Designer: Building Nested Forms in Rails with Stimulus](https://railsdesigner.com/rails-nested-form-with-stimulus/) (2024-09-05) — hand-rolled, `__INDEX__` token
- [Rails Designer: Adding edit, delete and reposition for nested forms](https://railsdesigner.com/extending-nested-forms-stimulus/) (2026-05-07) — the `_destroy`-presence discriminator, plus a SortableJS reposition controller
- [Rails Designer: Nested Forms With Turbo (without dependencies)](https://railsdesigner.com/rails-nested-forms-with-turbo/) (2024-08-15) — the pure-stream variant
- [Rails Designer: Nested forms without `accepts_nested_attributes_for`](https://railsdesigner.com/nested-forms-without-accepts-nested-attributes/) (2026-01-15) — give every child its own autosaving form; a real third option
- [GoRails: Dynamic Nested Forms with Stimulus JS](https://gorails.com/episodes/nested-forms-with-stimulusjs) — **2019-02-07, predates Turbo entirely.** Historically important, do not copy verbatim.
- hotrails.dev has **no** nested-forms chapter. [Nested Turbo Frames](https://www.hotrails.dev/turbo-rails/nested-turbo-frames) is a different pattern (one persisted resource per frame) and still uses `:unprocessable_entity`.
- **Superseded:** [cocoon](https://github.com/nathanvda/cocoon) (dead since 2020/2022, jQuery), [nested_form_fields](https://github.com/ncri/nested_form_fields) (dead since 2020, jQuery), `nested_form` (Ryan Bates, dead since 2013).

---

### Multi-step wizards

**Hotwire answer.** **One model, one record, a `step` column, one route per step, conditional validations.** Everything else — session accumulation, state-machine gems, JS-only step switching — is worse. Put each step's body in a `<turbo-frame id="wizard" data-turbo-action="advance">` so advancing feels instant *and* pushes a history entry, which is what makes the browser back button work without extra code.

**Code — (a) one record + `step` column. The default.**

```ruby
# db/migrate/…_create_signups.rb  →  t.string :current_step, null: false, default: "account"
# app/models/signup.rb
class Signup < ApplicationRecord
  STEPS = %w[account profile plan review].freeze

  validates :current_step, inclusion: { in: STEPS }

  with_options if: -> { reached?("account") } do
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, length: { minimum: 12 }, if: -> { password.present? }
  end
  validates :full_name, :company, presence: true, if: -> { reached?("profile") }
  validates :plan_id,              presence: true, if: -> { reached?("plan") }
  validates :terms_accepted,       acceptance: true, if: -> { reached?("review") }

  def reached?(step)  = STEPS.index(current_step.to_s).to_i >= STEPS.index(step)
  def next_step       = STEPS[STEPS.index(current_step) + 1]
  def previous_step   = STEPS.index(current_step).positive? ? STEPS[STEPS.index(current_step) - 1] : nil
  def last_step?      = current_step == STEPS.last
  def progress        = "#{STEPS.index(current_step) + 1} of #{STEPS.size}"
end
```

```ruby
# config/routes.rb
resource :signup, only: %i[show create] do
  resource :step, only: %i[show update], path: "steps/:step", as: :step
end
# → GET  /signup/steps/profile   signups/steps#show
# → PATCH/signup/steps/profile   signups/steps#update
```

```ruby
# app/controllers/signups/steps_controller.rb
class Signups::StepsController < ApplicationController
  before_action :set_signup
  before_action :ensure_step_reachable

  def show
    render step_template
  end

  def update
    @signup.current_step = step                       # validate only up to here
    if @signup.update(signup_params)
      if @signup.last_step?
        @signup.complete!
        redirect_to dashboard_path, status: :see_other
      else
        @signup.update_column(:current_step, @signup.next_step)
        redirect_to signup_step_path(step: @signup.next_step), status: :see_other
      end
    else
      render step_template, status: :unprocessable_content
    end
  end

  private

  def step = params[:step].presence_in(Signup::STEPS) || Signup::STEPS.first
  def step_template = "signups/steps/#{step}"
  def set_signup = @signup = current_user.signup || current_user.create_signup!

  # Don't let someone deep-link to /steps/review with an empty record.
  def ensure_step_reachable
    return if Signup::STEPS.index(step) <= Signup::STEPS.index(@signup.current_step)
    redirect_to signup_step_path(step: @signup.current_step), status: :see_other
  end

  def signup_params
    params.require(:signup).permit(*permitted_for(step))
  end

  def permitted_for(step)
    { "account" => %i[email password],
      "profile" => %i[full_name company],
      "plan"    => %i[plan_id],
      "review"  => %i[terms_accepted] }.fetch(step, [])
  end
end
```

```erb
<%# app/views/signups/steps/_layout.html.erb — every step renders through this %>
<turbo-frame id="wizard" data-turbo-action="advance">
  <nav aria-label="Progress">
    <ol>
      <% Signup::STEPS.each_with_index do |s, i| %>
        <li aria-current="<%= "step" if s == @signup.current_step %>">
          <% if Signup::STEPS.index(s) < Signup::STEPS.index(@signup.current_step) %>
            <%= link_to s.humanize, signup_step_path(step: s) %>
          <% else %>
            <span><%= s.humanize %></span>
          <% end %>
        </li>
      <% end %>
    </ol>
  </nav>

  <h1><%= yield :step_title %></h1>
  <p class="sr-only" aria-live="polite">Step <%= @signup.progress %></p>
  <%= yield %>
</turbo-frame>
```

```erb
<%# app/views/signups/steps/profile.html.erb %>
<% content_for :step_title, "Tell us about you" %>
<%= render layout: "signups/steps/layout" do %>
  <%= form_with model: @signup, url: signup_step_path(step: "profile"), method: :patch do |f| %>
    <%= render "shared/error_summary", record: @signup %>
    <%= f.label :full_name %><%= f.text_field :full_name, required: true %>
    <%= f.label :company %><%= f.text_field :company %>

    <% if @signup.previous_step %>
      <%= link_to "Back", signup_step_path(step: @signup.previous_step),
            data: { turbo_frame: "wizard", turbo_action: "advance" } %>
    <% end %>
    <%= f.submit "Continue", data: { turbo_submits_with: "…" } %>
  <% end %>
<% end %>
```

**Browser back must go to the previous step — take this seriously.** Users *will* hit back, and a wizard that dumps them out of the flow is a conversion bug.

- `data-turbo-action="advance"` on the `<turbo-frame>` promotes each frame navigation to a full Visit: Turbo pushes the frame's URL into history and caches a page snapshot. Back then triggers a **restoration visit** to `/signup/steps/account`, which renders the cached snapshot and, because the URL is real and server-routable, survives a hard reload too.
- **This only works because every step has its own URL.** A wizard that swaps steps with `hidden` classes and no URL change cannot support back, full stop. That is the single reason to reject the "one page, N hidden divs" design (Rails Designer's onboarding article uses that shape — it's fine for a 4-screen delight-driven onboarding, wrong for a form users will abandon and resume).
- Restoration visits render from the **snapshot cache**, so the "Back" step shows the values as they were *at the time you left it*, not as the server would render them now. If a step's content depends on later answers, add `<meta name="turbo-cache-control" content="no-preview">` to that step (or call `Turbo.cache.exemptPageFromPreview()`), so Turbo refetches rather than showing a stale preview.
- Guard forward-skipping server-side (`ensure_step_reachable` above). Never trust the URL.
- Do **not** try to make back "undo" a step's data. Back navigates; it doesn't roll back. If a step has side effects (charging a card), do them on the final step only.

**(b) Session-accumulated params.** Legitimate when you refuse to write a partial record — e.g. an anonymous checkout, or a form whose model has NOT NULL columns you can't satisfy until the end.

```ruby
class Onboarding::BaseController < ApplicationController
  private

  def wizard_state          = session[:onboarding] ||= {}
  def merge_state!(attrs)   = session[:onboarding] = wizard_state.merge(attrs.to_h)
  def clear_state!          = session.delete(:onboarding)
  def form_object           = Onboarding.new(wizard_state)   # ActiveModel form object
end
```

```ruby
# app/models/onboarding.rb — a PORO, no table
class Onboarding
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :workspace_name, :string
  attribute :use_case,       :string
  attribute :theme,          :string
  attribute :step,           :string, default: "workspace"

  validates :workspace_name, presence: true, if: -> { reached?("workspace") }
  # …

  def save
    return false if invalid?
    ActiveRecord::Base.transaction { create_workspace!.tap { |w| apply_theme_to(w) } }
  end
end
```

**Cost:** the Rails cookie session is capped at **4 KB**. Any file upload, any long text, any array of ids and you'll blow it — silently, because `ActionDispatch::Cookies::CookieOverflow` only raises in some configurations. Session-backed wizards also lose all state on logout/session rotation and are invisible to your support team. **Use a `draft`/`pending` record with a `status` enum instead, and sweep abandoned drafts with a job.** Reserve the session for genuinely small, genuinely anonymous flows.

**(c) A state machine.** `wicked` turns a controller into a wizard with `steps :one, :two` and `render_wizard`. It works with Turbo (it's just controllers and redirects), but: **last release 2.0.0 on 2022-09-14, last repo activity 2024-08-30.** It is dormant, not dead. What it gives you over (a) is a `step`/`next_step` DSL and `jump_to` — about 30 lines you can write yourself, as the [Rails Designer multistep article](https://railsdesigner.com/multistep-forms/) argues explicitly: *"this kind of feature is not something I would outsource to a gem."* Agreed. If you want a real state machine because steps branch (`plan == "enterprise"` → an extra step), use `AASM` or a plain `case` in `next_step` — not a wizard gem.

**`ActiveRecord::Store` for wizard payloads.** When steps collect loosely-structured data you don't want columns for:

```ruby
class Signup < ApplicationRecord
  store :answers, accessors: %i[use_case team_size referral_source], coder: JSON
  # or, on Postgres:  store_accessor :answers, :use_case, :team_size
end
```
`store_accessor` over a `jsonb` column gives you `signup.use_case` with form-builder support and no migration per question. Validate them exactly like columns.

**Decomposition.**
- No custom controller for the core flow — frames + `data-turbo-action` do it.
- `dirty-form` to warn on abandoning a partially-filled step.
- `persist` if you want to keep in-progress answers in `sessionStorage` across a crash.
- `disclosure` for optional "advanced" sub-sections within a step.

**A11y.**
- Progress indicator: `<nav aria-label="Progress"><ol>` with `aria-current="step"` on the active item. This is the [APG "breadcrumb"-adjacent](https://www.w3.org/WAI/ARIA/apg/patterns/breadcrumb/) convention; there is no dedicated APG wizard pattern.
- Frame navigation does not announce anything. Add a polite live region reporting "Step 2 of 4: Tell us about you" and update the `<title>` per step (Turbo merges `<head>` on advance visits, so a per-step `content_for :title` is announced by screen readers on the visit).
- Move focus to the step's `<h1>` (`tabindex="-1"`) after each advance. Without this, focus stays on the "Continue" button that no longer exists and drops to `<body>`.
- Never disable the "Back" affordance; a wizard the user can't reverse is hostile.
- Don't hide future steps behind `aria-hidden` — they aren't in the DOM at all in this design, which is correct.

**Native.** This is the pattern most worth making native. Path-configure each step URL to push a **native screen** so the platform back gesture / navigation bar drives the flow, and use `recede_or_redirect_to` / `refresh_or_redirect_to` (turbo-rails 2.x `Turbo::Native::Navigation`) on completion so the stack unwinds correctly. With native screens, drop `data-turbo-action="advance"` — the native navigator owns history. Hide the web progress bar and let the native nav bar show "Step 2 of 4" as the title. See `04-hotwire-native.md`.

**Pitfalls.**
- Conditional validations keyed on `current_step` must be evaluated with the step being *submitted*, not the step stored in the DB. Assign `@signup.current_step = step` **before** `update`, as above; otherwise step 2's validations never run.
- `update_column` to advance the step skips validations and callbacks deliberately — if you use `update!`, the just-passed step's validations run again against the next step's stricter set and you deadlock.
- A `<turbo-frame>` wizard with `data-turbo-action="advance"` requires the step response to contain a frame with the **same id**, or you get "content missing" ([02-turbo-deep-dive §3.6](../notes/02-turbo-deep-dive.md)).
- Redirect after a successful step **must** be `status: :see_other` — it follows a PATCH ([§2.10](../notes/02-turbo-deep-dive.md)).
- Users bookmark step URLs and come back days later. Handle "record already completed" explicitly.
- Analytics/abandonment tracking is the actual product requirement behind most wizards. A `current_step` column gives it to you for free; a session-based wizard gives you nothing.

**Prior art.**
- [wicked](https://github.com/zombocom/wicked) — v2.0.0 (2022-09-14), repo quiet since 2024-08-30. Works, dormant, not needed.
- [Rails Designer: Add a multi-step form/wizard to your Rails app](https://railsdesigner.com/multistep-forms/) — form object + steps-as-data; single-page/hidden-div shape, so no back-button support
- [Rails Designer: Form service objects](https://railsdesigner.com/form-service-objects/)
- [`ActiveRecord::Store`](https://api.rubyonrails.org/classes/ActiveRecord/Store.html) / `store_accessor`
- [AASM](https://github.com/aasm/aasm) for genuinely branching flows

---

### Autosave / debounced submit

**Hotwire answer.** `autosubmit` on the form with a debounce, firing `requestSubmit()` on `input`, PATCHing to an `update` action that returns `head :no_content` (or a tiny stream carrying a "Saved" timestamp). **`requestSubmit()` — never `submit()`.** `form.submit()` does not dispatch the `submit` event, so Turbo never sees it, you get a full page navigation, and constraint validation is skipped entirely ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/requestSubmit): *"`requestSubmit()`… acts as if a submit button were clicked. The form's content is validated, and the form is submitted only if validation succeeds. Once the form has been submitted, the `submit` event is sent back to the form object."*).

**Code — a Notion-style autosaving title field.**

```erb
<%# app/views/documents/_editor.html.erb %>
<%= form_with model: @document, method: :patch,
      data: { controller: "autosubmit save-indicator",
              autosubmit_delay_value: 600,
              action: "turbo:submit-start->save-indicator#saving " \
                      "turbo:submit-end->save-indicator#saved" } do |f| %>

  <%= f.hidden_field :lock_version %>          <%# optimistic locking, see below %>

  <%= f.text_field :title,
        id: "document_title",                  <%# stable id: focus restore needs it %>
        class: "title-input",
        placeholder: "Untitled",
        autocomplete: "off",
        aria: { label: "Document title", describedby: "save_status" },
        data: { action: "input->autosubmit#submit" } %>

  <%= f.rich_text_area :body,
        data: { action: "trix-change->autosubmit#submit" } %>

  <output id="save_status" data-save-indicator-target="status" aria-live="polite">
    <%= "Saved #{time_ago_in_words(@document.updated_at)} ago" if @document.persisted? %>
  </output>

  <noscript><%= f.submit "Save" %></noscript>
<% end %>
```

```js
// app/javascript/controllers/autosubmit_controller.js
// Generic primitive. Works for autosave, search, filters, dependent selects.
import { Controller } from "@hotwired/stimulus"
import { useDebounce } from "stimulus-use"

export default class extends Controller {
  static debounces = ["submit"]
  static values = { delay: { type: Number, default: 300 } }

  connect() {
    useDebounce(this, { wait: this.delayValue })
  }

  submit() {
    // requestSubmit(): fires `submit` (so Turbo intercepts) AND runs constraint
    // validation. form.submit() does NEITHER — it would cause a full page load.
    this.form.requestSubmit()
  }

  // For a control that must submit *its own* form via a specific submitter
  // (e.g. a `formaction`/`formmethod` button), pass the submitter through.
  submitFor({ target }) {
    this.form.requestSubmit(target.closest("[type=submit]") ?? undefined)
  }

  get form() {
    return this.element instanceof HTMLFormElement ? this.element : this.element.form
  }
}
```

```js
// app/javascript/controllers/save_indicator_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]

  saving()  { this.statusTarget.textContent = "Saving…" }

  saved({ detail: { success, fetchResponse } }) {
    if (success) {
      this.statusTarget.textContent = "Saved"
      this.element.dataset.dirty = "false"
    } else if (fetchResponse?.statusCode === 409) {
      this.statusTarget.textContent = "This document changed elsewhere — reload to continue."
    } else {
      this.statusTarget.textContent = "Couldn't save. Retrying…"
    }
  }
}
```

```ruby
# app/controllers/documents_controller.rb
def update
  @document = current_user.documents.find(params[:id])
  # Assigning lock_version from the form is all optimistic locking needs: Rails
  # puts it in the UPDATE's WHERE clause and raises if zero rows matched.
  if @document.update(document_params)   # permits :lock_version
    head :no_content                              # 204: cheapest possible save
  else
    render turbo_stream: turbo_stream.replace(
      "save_status", partial: "documents/save_status", locals: { document: @document }
    ), status: :unprocessable_content
  end
rescue ActiveRecord::StaleObjectError
  head :conflict                                  # 409 — see the race section
end
```

> **`head :no_content` and Turbo.** A 204 on a non-GET submission is Turbo's documented "do nothing" response — it neither renders nor errors. That's exactly what autosave wants. Do **not** return a bare `200 OK` with an empty body: that trips *"Form responses must redirect to another location"* ([02-turbo-deep-dive §2.10](../notes/02-turbo-deep-dive.md)).

**The out-of-order race — and the real fix.** The user types `Hell` (request A fires), then `Hello` (request B fires). B is served by a fast worker and lands first; A lands second and writes `Hell`. The document now says `Hell` and the UI says `Hello`. This is not hypothetical; it is the default behaviour of a naive autosave.

Three fixes, in order of preference:

1. **Optimistic locking (server-side, authoritative).** Add a `lock_version` integer column; Rails handles the rest. Request A carries `lock_version: 7`; B also carries 7. Whichever lands first wins and bumps to 8; the loser raises `ActiveRecord::StaleObjectError` → `head :conflict`. Your indicator then re-syncs (refetch or morph the field). **This is the only fix that is correct across tabs, devices, and collaborators.**

2. **Serialize on the client.** Turbo's `Navigator#submitForm` calls `this.stop()` first, which aborts any in-flight form submission *for Drive-level navigations* — but an autosave PATCH returning 204 doesn't navigate, and frame-scoped submissions have their own navigator. Don't rely on it. Instead, coalesce explicitly:

```js
// add to autosubmit_controller.js
submit() {
  if (this.element.getAttribute("aria-busy") === "true") { this.pending = true; return }
  this.form.requestSubmit()
}
// data-action: "turbo:submit-end->autosubmit#flush"
flush() { if (this.pending) { this.pending = false; this.submit() } }
```
   Turbo sets `aria-busy="true"` on the `<form>` for the duration of the submission (`markAsBusy` in `src/util.js`), so this needs no extra bookkeeping.

3. **Debounce longer.** 600–1000ms for a text field makes the race rare. It does not make it impossible. Ship 1 *and* 3.

**Turbo 8's request-id debouncing is a different thing** and does not help here: it deduplicates incoming `<turbo-stream action="refresh">` broadcasts caused by *your own* request, so an autosaving `broadcasts_refreshes` model doesn't refresh the page under the very user who typed. It's the reason autosave + `broadcasts_refreshes` doesn't produce a feedback loop. See [02-turbo-deep-dive §5.5](../notes/02-turbo-deep-dive.md).

**Decomposition.**
- `autosubmit` (debounced via stimulus-use `useDebounce`, or the `delay` value on stimulus-components' auto-submit).
- `dirty-form` — track changes, clear on `turbo:submit-end`.
- `relative-time` for the "Saved 2 minutes ago" stamp.
- `persist` as a belt-and-braces local backup of the in-progress value.

**A11y.**
- The status region is an `<output>` (implicit `role="status"`, i.e. a polite live region — [MDN](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/output)). Do **not** update it on every keystroke; only on `turbo:submit-start` / `turbo:submit-end`. Even then, "Saving…"/"Saved" every 600 ms is chatty — consider only announcing failures and announcing success at most once per idle period.
- Point the input's `aria-describedby` at the status element.
- Provide a real submit button in `<noscript>`, and keep a keyboard-reachable "Save" for users who want confirmation.
- Do not steal focus on save. Ever.

**Native.** Autosave over a mobile connection is expensive and drains battery. Raise the debounce (1200 ms+) in the native shell, and flush on `pagehide` / the bridge's "screen will disappear" hook, because a native pop does **not** fire `beforeunload`. A `save-form` bridge component that flushes before the native navigator pops is worth building.

**Pitfalls.**
- **`form.submit()` is the bug.** No `submit` event → no Turbo → full page reload, or (inside a frame) a navigation that nukes the frame. Also skips validation. `requestSubmit()` always.
- `requestSubmit()` **does** run constraint validation, so an autosaving form with `required` fields silently stops saving the moment a required field is emptied. Either `novalidate` the autosave form or don't mark fields `required` on it.
- Autosaving a form with `enctype="multipart/form-data"` re-uploads the file on every keystroke. Split file inputs into their own direct-upload flow.
- `input` fires on IME composition in CJK input; debounce alone doesn't fix it. Guard with `compositionstart`/`compositionend` if you support those locales.
- A 204 leaves the URL and history untouched — correct — but it also means nothing re-renders, so server-side normalisation (title truncation, slug generation) is invisible until reload. Return a small stream if the server mutates the value.
- Turbo Drive caches the page on navigation; an autosaving form's *last* debounced edit can be lost if the user navigates within the debounce window. Flush on `turbo:before-visit`.

**Prior art.**
- [MDN: `HTMLFormElement.requestSubmit()`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/requestSubmit)
- [@stimulus-components/auto-submit](https://github.com/stimulus-components/stimulus-components/tree/master/components/auto-submit) — `delayValue` default **150 ms**, debounced in `initialize()` (deliberately, so Stimulus reusing the instance can't compound the delay), calls `this.element.requestSubmit()`
- [stimulus-use `useDebounce`](https://stimulus-use.dev/use-debounce.html) — `static debounces = ['submit']`, `useDebounce(this, { wait: 200 })`, default **200 ms**, per-method `{ name, wait, leading, trailing }`
- [Rails Designer: Local autosaves component](https://railsdesigner.com/components/local-autosaves/)
- [Rails: Optimistic locking](https://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html)
- Superseded: `best_in_place` (jQuery inline editing, unmaintained since 2016).

---

### Submit-on-change

**Hotwire answer.** A **GET** form with `autosubmit` on `change` for selects/checkboxes and debounced `input` for text, targeting a `<turbo-frame>` that holds the results, with `data-turbo-action="advance"` on the frame so the filter state lands in the URL and the back button works. **No JS beyond the generic `autosubmit` primitive.** Frame-scoping is also the answer to the focus-loss problem: if the controls are *outside* the frame, they're never re-rendered, so focus can't be lost.

**Code.**

```erb
<%# app/views/orders/index.html.erb %>
<%= form_with url: orders_path, method: :get,
      data: { controller: "autosubmit", turbo_frame: "orders_list",
              autosubmit_delay_value: 300 } do |f| %>

  <%= label_tag :q, "Search orders" %>
  <%= text_field_tag :q, params[:q],
        id: "orders_q", type: "search", autocomplete: "off",
        data: { action: "input->autosubmit#submit" } %>

  <%= label_tag :status %>
  <%= select_tag :status,
        options_for_select(Order.statuses.keys.map { [_1.humanize, _1] }, params[:status]),
        include_blank: "Any status",
        data: { action: "change->autosubmit#submit" } %>

  <%= label_tag :sort %>
  <%= select_tag :sort,
        options_for_select([["Newest", "recent"], ["Highest value", "value"]], params[:sort]),
        data: { action: "change->autosubmit#submit" } %>

  <noscript><%= submit_tag "Apply" %></noscript>
<% end %>

<turbo-frame id="orders_list" data-turbo-action="advance" target="_top">
  <%= render "orders/list", orders: @orders %>
</turbo-frame>
```

```ruby
# app/controllers/orders_controller.rb
def index
  @orders = current_account.orders
              .then { |s| params[:q].present?      ? s.search(params[:q])      : s }
              .then { |s| params[:status].present? ? s.where(status: params[:status]) : s }
              .then { |s| params[:sort] == "value" ? s.order(total_cents: :desc) : s.order(created_at: :desc) }
              .page(params[:page])
end
```

**The URL / back-button combo.** `data-turbo-action="advance"` on the `<turbo-frame>` promotes each frame navigation to a Visit: Turbo pushes the frame's URL (which, because it's a GET form, already carries `?q=…&status=…`) into history. Result: shareable filtered URLs, working back button, working reload — with zero extra code. Put the attribute on the **frame**, not the form; on the form it applies to the form's own navigation, which for a frame-targeted GET is the same thing but reads worse.

> Set `data-turbo-action="replace"` instead if you want filter changes to *not* pile up in history — one entry per filter session rather than per keystroke. For a debounced text input, `advance` produces one history entry per debounce window, which is usually too many. **Recommendation: `advance` for selects, `replace` for the text input.** You can't have both on one frame, so if it matters, split into two frames or set the action per-submitter.

**The focus-loss problem — the crux.** If the form controls are inside whatever gets re-rendered, the browser destroys and recreates them, and focus (plus caret position, plus the IME buffer) is gone. Three working recipes, in preference order:

**1. Frame-scope it (best).** Keep the controls **outside** the `<turbo-frame>` and only the results inside. Nothing about the input is ever re-rendered, so there is nothing to preserve. This is why the code above puts the form above the frame. Ship this unless you can't.

**2. Morph the page refresh (when the whole page must re-render).**

```erb
<%# app/views/layouts/application.html.erb %>
<meta name="turbo-refresh-method" content="morph">
<meta name="turbo-refresh-scroll" content="preserve">
```

Turbo 8 morphing runs [idiomorph](https://github.com/bigskysoftware/idiomorph) **0.7.4**, whose `restoreFocus` option defaults to `true`: it records `document.activeElement`'s `id`, `selectionStart` and `selectionEnd` before the morph and restores focus and the selection range after (`saveAndRestoreFocus` in `src/idiomorph.js`). **The input must have an `id`** — that's how it's re-found. Give every filter control an explicit `id`.

**But there is a trap.** Idiomorph also has `ignoreActiveValue`, which defaults to **false**, and Turbo does *not* set it (`src/core/morphing.js` passes only `callbacks`). So `syncInputValue` will overwrite the focused input's `value` with whatever the server rendered. If the user typed two more characters while the request was in flight, morph silently reverts them. The fix uses Turbo's cancelable `turbo:before-morph-attribute` event, which idiomorph consults via `beforeAttributeUpdated`:

```js
// app/javascript/morph_guards.js — import once from application.js
document.addEventListener("turbo:before-morph-attribute", (event) => {
  const { attributeName } = event.detail
  if (attributeName === "value" && event.target === document.activeElement) {
    event.preventDefault()          // keep what the user is typing
  }
})
```

**3. `data-turbo-permanent` on the input (blunt).** Add it plus a unique `id` and morph will skip the element entirely (`DefaultIdiomorphCallbacks#beforeNodeMorphed` returns `false` for `[data-turbo-permanent]`). Cost: the server can never update that input again — including resetting it, or reflecting a filter cleared elsewhere. Use only for a search box that is genuinely client-owned.

For **Turbo Stream** responses (not morph), focus is preserved only when the focused element has an `id` — `withPreservedFocus` in `src/core/streams/stream_message_renderer.js` reads `activeElementBeforeRender.id` and refocuses by `getElementById`. Same rule: **always give filter controls stable ids.**

**Decomposition.**
- `autosubmit` (debounced via stimulus-use for text; undebounced `change` for selects).
- `persist` if filters should survive a full navigation away and back.
- `disclosure` for a collapsible "more filters" panel.
- `selection` when the filtered list also supports bulk actions.

**A11y.**
- Announce the result count in a polite live region **inside** the frame: `<p aria-live="polite" role="status">42 orders</p>`. Without it, a screen-reader user has no idea the list changed.
- Never auto-submit on `blur` of a select — it fires when the user is tabbing past and produces phantom navigations.
- `<noscript>` submit button, always. A filter form that requires JS is a filter form that fails.
- Keep visible `<label>`s. Placeholder-only filter controls fail [WCAG 3.3.2](https://www.w3.org/WAI/WCAG22/Understanding/labels-or-instructions.html).
- The frame gets `aria-busy="true"` while loading; use it for a non-intrusive loading state rather than a spinner that steals attention.

**Native.** Filters map well to a native screen (path-configure a `/orders/filters` modal that redirects back with query params). If you keep it web, drop `data-turbo-action="advance"` — the native navigator owns history and every filter change would push a screen. Consider a `filter` bridge component driving a native segmented control.

**Pitfalls.**
- `change` on a text input fires only on blur; you want `input`. `change` on a `<select>` is correct and needs **no** debounce.
- A GET form's action query string is discarded and rebuilt from the form fields by Turbo. Extra params must be hidden inputs, not baked into the URL.
- Blank params pile up: `?q=&status=&sort=` in the URL after clearing. Strip them with a `compact_blank`-style rewrite server-side, or accept the ugliness.
- Pagination + filters: the frame must re-render pagination links carrying the current filter params, or page 2 loses the filter. `pagy`'s frame support handles this if you pass the params through.
- With `advance`, each debounced keystroke is a history entry — hold the back button and you'll walk backwards one character at a time. Use `replace` for the text field.
- Checkbox filters: an unchecked checkbox submits nothing, so "uncheck to clear" needs a paired `hidden_field_tag :status, ""` before it (Rails' `check_box` helper already does this for model forms).

**Prior art.**
- [@stimulus-components/auto-submit](https://www.stimulus-components.com/docs/stimulus-auto-submit)
- [Turbo Handbook: Page Refreshes with morphing](https://turbo.hotwired.dev/handbook/page_refreshes)
- [idiomorph](https://github.com/bigskysoftware/idiomorph) — `restoreFocus`, `ignoreActiveValue`
- [pagy](https://ddnexus.github.io/pagy/) — documented Turbo Frame support
- Superseded: `wice_grid`, `ransack` + `remote: true` jQuery forms. (Ransack itself is fine as a query builder; its jQuery-era view helpers are not.)

---

### Search-as-you-type with debouncing

**Hotwire answer.** The most-copied Hotwire recipe, and it is genuinely three lines of JS: a **GET** form targeting a `<turbo-frame id="results">`, `autosubmit` debounced ~300 ms on `input`, `data-turbo-action="advance"` on the frame for URL state. The search input lives **outside** the frame, which is the entire reason the cursor stays put.

**Code.**

```ruby
# config/routes.rb
resources :articles do
  collection { get :search }
end
```

```erb
<%# app/views/articles/index.html.erb %>
<%= form_with url: search_articles_path, method: :get,
      data: { controller: "autosubmit",
              autosubmit_delay_value: 300,
              turbo_frame: "search_results" } do %>

  <%= label_tag :q, "Search articles", class: "sr-only" %>
  <%= search_field_tag :q, params[:q],
        id: "article_search",
        placeholder: "Search articles…",
        autocomplete: "off",
        autofocus: true,
        aria: { controls: "search_results", describedby: "search_status" },
        data: { action: "input->autosubmit#submit" } %>

  <noscript><%= submit_tag "Search" %></noscript>
<% end %>

<%# The frame sits OUTSIDE the form. Only this is replaced. %>
<turbo-frame id="search_results" data-turbo-action="advance" target="_top">
  <%= render "articles/results", articles: @articles, query: params[:q] %>
</turbo-frame>
```

```erb
<%# app/views/articles/search.html.erb — the frame response %>
<turbo-frame id="search_results">
  <%= render "articles/results", articles: @articles, query: params[:q] %>
</turbo-frame>
```

```erb
<%# app/views/articles/_results.html.erb — locals: (articles:, query:) %>
<p id="search_status" role="status" aria-live="polite" class="sr-only">
  <%= query.blank? ? "" : "#{pluralize(articles.size, "result")} for #{query}" %>
</p>

<% if query.blank? %>
  <div class="empty">
    <p>Start typing to search <%= Article.count %> articles.</p>
  </div>
<% elsif articles.empty? %>
  <div class="empty">
    <p>No articles match "<%= query %>".</p>
    <%= link_to "Clear search", articles_path, data: { turbo_frame: "_top" } %>
  </div>
<% else %>
  <ul>
    <% articles.each do |article| %>
      <li>
        <%= link_to highlight(article.title, query), article, data: { turbo_frame: "_top" } %>
        <p><%= highlight(truncate(article.summary, length: 160), query) %></p>
      </li>
    <% end %>
  </ul>
  <%== pagy_nav(@pagy) if @pagy.pages > 1 %>
<% end %>
```

```ruby
# app/models/article.rb
scope :search, ->(query) {
  return all if query.blank?
  where("title ILIKE :q OR summary ILIKE :q", q: "%#{sanitize_sql_like(query)}%")
}
# Postgres full text is better:
# scope :search, ->(q) { where("searchable @@ websearch_to_tsquery('english', ?)", q) }
```

```ruby
# app/controllers/articles_controller.rb
def search
  @pagy, @articles = pagy(Article.published.search(params[:q]).order(created_at: :desc))
  render :search
end
```

**Keeping the cursor in the input.** Because the input is outside `<turbo-frame id="search_results">`, Turbo replaces only the frame's children and never touches the input — focus, caret, selection, and IME state all survive untouched. **This is the whole design.** If you find yourself needing `data-turbo-permanent` on a search box, you've put the input inside the frame; move it out. See *Submit-on-change* above for what to do when you genuinely can't.

**The `turbo-frame src` alternative.** Instead of a form, drive the frame's `src` directly:

```js
// app/javascript/controllers/frame_search_controller.js
import { Controller } from "@hotwired/stimulus"
import { useDebounce } from "stimulus-use"

export default class extends Controller {
  static targets = ["frame", "input"]
  static values = { url: String }
  static debounces = ["reload"]

  connect() { useDebounce(this, { wait: 300 }) }

  reload() {
    const url = new URL(this.urlValue, window.location.origin)
    if (this.inputTarget.value) url.searchParams.set("q", this.inputTarget.value)
    this.frameTarget.src = url.toString()      // setting src triggers a frame visit
  }
}
```

Use this when there is no form to speak of — e.g. a search box in a header that filters a panel elsewhere on the page, or when the query is assembled from several non-form sources. It loses `data-turbo-action` history integration (you'd have to `Turbo.visit(url, { action: "advance", frame: "…" })` yourself), so **prefer the form.**

**Decomposition.**
- `autosubmit` — debounced via stimulus-use `useDebounce` (or stimulus-components auto-submit's `delayValue`).
- `combobox` if results should be a dropdown listbox rather than an inline list — different pattern, different ARIA.
- `intersection` for infinite-scrolling the results (pagy documents the Turbo Frame flavour).
- `clipboard` / `hotkey` (`data-hotkey="/"` to focus search) as garnish.

**A11y.**
- The input is `<input type="search">` with a real (possibly visually-hidden) `<label>`.
- `aria-controls="search_results"` on the input tells AT what it drives. Support is patchy but it costs nothing.
- A `role="status"` / `aria-live="polite"` result count **inside** the frame is what actually announces the change. Put it first in the frame so it's the first thing re-rendered.
- **This is not a combobox.** Don't add `role="combobox"`/`aria-expanded`/`aria-autocomplete` unless you're building a listbox popup — then follow [APG combobox](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/) fully (or just use `hotwire_combobox`).
- Don't `autofocus` on a page users navigate to for other reasons — it hijacks screen-reader reading position.
- Keep results keyboard-reachable in DOM order; don't reorder visually with CSS grid in a way that breaks tab order.

**Native.** Path-configure a dedicated `/search` screen and back it with the platform's native search bar via a `search` bridge component; forwarding keystrokes into the web input over the bridge is the standard shape. Drop `data-turbo-action="advance"` on native (the native navigator owns history). Raise the debounce to ~500 ms on cellular.

**Pitfalls.**
- **Debounce, don't throttle.** 250–350 ms is the sweet spot; below 150 ms you're DoS-ing your own database.
- Racing responses: a slow response for `ru` can land after a fast one for `ruby`. Turbo *does* cancel the previous frame request when a new one starts on the same frame, which handles this for the frame case — but not if you fan out to several frames. Don't hand-roll `fetch` here; let the frame do it.
- `sanitize_sql_like` or you have both an injection hole and a `%`-eats-the-query bug.
- Empty state matters more than results state. Handle "no query yet" and "no matches" separately — they're different messages.
- Result links must escape the frame: `data: { turbo_frame: "_top" }`, or clicking a result renders the article *inside* the results frame.
- With `data-turbo-action="advance"`, each debounce window pushes history. Consider `replace` (see *Submit-on-change*).
- `highlight()` returns HTML-safe output built from user input — Rails escapes the query before wrapping it, but double-check if you customise the `highlighter:` option.
- Don't cache the search page (`<meta name="turbo-cache-control" content="no-preview">` on it) if a stale preview of someone else's query would leak.

**Prior art.**
- [@stimulus-components/auto-submit](https://www.stimulus-components.com/docs/stimulus-auto-submit)
- [stimulus-use `useDebounce`](https://stimulus-use.dev/use-debounce.html)
- [Boring Rails: Thinking in Hotwire — progressive enhancement](https://boringrails.com/articles/thinking-in-hotwire-progressive-enhancement/) — the philosophical case for the GET-form-plus-frame shape
- [Boring Rails: Highlight search results in Rails](https://boringrails.com/tips/rails-highlight-search-results)
- [hotrails.dev: Turbo Frames and Turbo Stream templates](https://www.hotrails.dev/turbo-rails/turbo-frames-and-turbo-streams) — **pre-Turbo-8** (uses `:unprocessable_entity`); the frame mechanics are still correct
- [pagy Turbo Frame / infinite scroll](https://ddnexus.github.io/pagy/)
- [hotwire_combobox](https://github.com/josefarias/hotwire_combobox) for the dropdown-listbox flavour

---

### Character counters

**Hotwire answer.** A `char-count` Stimulus controller mirroring `input.value.length` into an `<output>`. **~15 lines; do not install a gem for this.** Prefer counting *down* against `maxlength` and only flipping to a warning state near the limit.

**Code.**

```erb
<div class="field" data-controller="char-count" data-char-count-max-value="280">
  <%= f.label :bio %>
  <%= f.text_area :bio, maxlength: 280,
        aria: { describedby: "bio_count" },
        data: { char_count_target: "input", action: "input->char-count#update" } %>

  <%# <output> has an implicit role="status" → already a polite live region. %>
  <output id="bio_count" for="post_bio" data-char-count-target="counter">280</output>
</div>
```

```js
// app/javascript/controllers/char_count_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter"]
  static values  = { max: Number, warnAt: { type: Number, default: 0.9 } }
  static classes = ["warn", "over"]

  connect() { this.update() }

  update() {
    const max  = this.maxValue || this.inputTarget.maxLength
    // Count grapheme clusters, not UTF-16 code units: "👨‍👩‍👧" is 1 character to
    // a human and 8 to `.length`.
    const used = [...new Intl.Segmenter(undefined, { granularity: "grapheme" })
                    .segment(this.inputTarget.value)].length
    const left = max - used

    this.counterTarget.textContent = left
    this.element.classList.toggle(this.warnClass, left <= max * (1 - this.warnAtValue) && left > 0)
    this.element.classList.toggle(this.overClass, left < 0)
  }
}
```

**Do not announce every keystroke.** `<output>`'s implicit `role="status"` makes it a polite live region, and updating it on every `input` means a screen reader reads "279… 278… 277…" forever. Two mitigations, use both:

```erb
<%# 1. Give AT a stable description; let the visual counter be aria-hidden. %>
<output id="bio_count" data-char-count-target="counter" aria-hidden="true">280</output>
<span id="bio_count_a11y" class="sr-only" role="status" aria-live="polite"
      data-char-count-target="announcer"></span>
```

```js
// 2. Only announce at thresholds, debounced.
#announce(left, max) {
  const milestone = left <= 0 ? "over" : left <= 20 ? "near" : "ok"
  if (milestone === this.lastMilestone) return
  this.lastMilestone = milestone
  this.announcerTarget.textContent =
    left < 0 ? `${-left} characters over the limit` :
    left <= 20 ? `${left} characters remaining` : ""
}
```

**Decomposition.**
- `char-count` — mirror input length into an output element with max/over states.
- `sync` if the count must also appear elsewhere (e.g. a submit button label).

**A11y.**
- `<output>` — implicit `role="status"`, polite live region ([MDN](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/output)); its `for` attribute references the contributing input's `id`. Note `<output>`'s value is **not** submitted.
- `aria-describedby` from the input to the counter so its content is read when the field receives focus.
- Throttle announcements to thresholds (above). This is the single most-missed detail.
- The "over limit" state must be conveyed by more than red text — add the word "over".
- `maxlength` hard-truncates paste, which is hostile for a 500-char field. Consider omitting `maxlength` and validating server-side, letting the counter go negative.

**Native.** n/a.

**Pitfalls.**
- `value.length` counts UTF-16 code units. Emoji, ZWJ sequences, and combining accents all over-count. `Intl.Segmenter` with `granularity: "grapheme"` is the correct measure and is Baseline; stimulus-components' controller exposes exactly this via `countUnit: "graphemes"`.
- `maxlength` counts code units too, so a `maxlength="280"` field cuts a 280-emoji tweet short. If your server-side limit is graphemes, drop `maxlength` and validate server-side.
- `maxlength` does not apply to `<textarea>` content set programmatically, nor to `contenteditable`/Trix.
- Counting on `keyup` misses paste, drag-drop, and autofill. Use `input`.

**Prior art.**
- [@stimulus-components/character-counter](https://github.com/stimulus-components/stimulus-components/tree/master/components/character-counter) — targets `input`/`counter`; values `countdown` (Boolean) and `countUnit` (`"code-units"` default, `"code-points"`, `"graphemes"`); reads `maxlength` off the input in countdown mode. [Docs](https://www.stimulus-components.com/docs/stimulus-character-counter).
- [MDN: `<output>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/output)
- [MDN: `Intl.Segmenter`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Segmenter)

---

### Dirty-form warnings

**Hotwire answer.** A `dirty-form` controller that tracks changes and installs **three** guards, not one: `beforeunload` for real unloads, **`turbo:before-visit` for Turbo Drive navigations, and `turbo:before-frame-render` for frame swaps.** `beforeunload` **does not fire on a Turbo Drive visit** — the document never unloads — so the naive one-liner every tutorial shows is silently broken in every Hotwire app. This is the genuine gotcha.

**Code.**

```js
// app/javascript/controllers/dirty_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    message: { type: String, default: "You have unsaved changes. Leave this page?" },
    guardFrames: { type: Boolean, default: true }
  }

  connect() {
    this.snapshot = this.#serialize()
    this.element.dataset.dirty = "false"

    // 1. Real unloads: closing the tab, a full reload, data-turbo="false" links,
    //    cross-origin navigation. Fires ONLY for these.
    this.onBeforeUnload = (event) => {
      if (!this.dirty) return
      event.preventDefault()
      event.returnValue = ""     // legacy browsers still require this
    }
    addEventListener("beforeunload", this.onBeforeUnload)

    // 2. Turbo Drive visits: link clicks, Turbo.visit(), and the redirect visit
    //    that follows a successful form submission. Cancelable.
    this.onBeforeVisit = (event) => {
      if (!this.dirty) return
      if (!window.confirm(this.messageValue)) event.preventDefault()
    }
    addEventListener("turbo:before-visit", this.onBeforeVisit)

    // 3. Frame navigations never propose a Visit, so before-visit never fires.
    //    Guard the frame render instead. Cancelable, dispatched on the frame.
    if (this.guardFramesValue) {
      this.onBeforeFrameRender = (event) => {
        if (!this.dirty) return
        if (!this.element.closest("turbo-frame")?.contains(event.target)
            && event.target !== this.element.closest("turbo-frame")) return
        if (!window.confirm(this.messageValue)) event.preventDefault()
      }
      addEventListener("turbo:before-frame-render", this.onBeforeFrameRender)
    }

    // 4. Clear on successful submit. turbo:submit-end fires BEFORE the redirect's
    //    turbo:before-visit, so this stops the guard prompting after a save.
    this.onSubmitEnd = ({ detail: { success } }) => { if (success) this.reset() }
    this.element.addEventListener("turbo:submit-end", this.onSubmitEnd)
  }

  disconnect() {
    removeEventListener("beforeunload", this.onBeforeUnload)
    removeEventListener("turbo:before-visit", this.onBeforeVisit)
    if (this.onBeforeFrameRender) removeEventListener("turbo:before-frame-render", this.onBeforeFrameRender)
    this.element.removeEventListener("turbo:submit-end", this.onSubmitEnd)
  }

  check() { this.element.dataset.dirty = String(this.dirty) }
  reset() { this.snapshot = this.#serialize(); this.element.dataset.dirty = "false" }

  get dirty() { return this.#serialize() !== this.snapshot }

  #serialize() {
    return new URLSearchParams(new FormData(this.element)).toString()
  }
}
```

```erb
<%= form_with model: @post,
      data: { controller: "dirty-form",
              action: "input->dirty-form#check change->dirty-form#check" } do |f| %>
  …
<% end %>
```

```css
/* free visual affordance */
form[data-dirty="true"] .save-button::after { content: " •"; }
```

**Ordering, verified against Turbo 8.0.23.** For a successful submit that redirects, Turbo's own functional test asserts this sequence: `turbo:before-fetch-response` → `turbo:submit-end` → `turbo:before-visit` → `turbo:visit` → `turbo:before-render` → `turbo:render` → `turbo:load` (`src/tests/functional/form_submission_tests.js`). Because `turbo:submit-end` precedes `turbo:before-visit`, clearing the dirty flag there reliably prevents the guard from prompting on the post-save redirect. **If you skip step 4, every successful save prompts "You have unsaved changes."** — the second-most-common bug in this pattern.

**Why `turbo:before-visit` and not `turbo:before-fetch-request`.** `turbo:before-visit` is dispatched from `Session#notifyApplicationBeforeVisitingLocation` with `cancelable: true` and fires before the network request, so cancelling it aborts cleanly with no wasted request. `turbo:before-frame-render` is likewise `cancelable: true`, dispatched on the frame element (`FrameController#allowsImmediateRender`) — but note it fires *after* the response has arrived, so cancelling wastes a request. That's acceptable for a confirm dialog.

**A promise-based confirm instead of `window.confirm`.** `turbo:before-visit` handlers must decide **synchronously**, so you cannot `await` a `<dialog>` there. The workable shape is: cancel unconditionally, show your dialog, and re-issue the visit if the user confirms:

```js
this.onBeforeVisit = (event) => {
  if (!this.dirty || this.confirmed) return
  event.preventDefault()
  const url = event.detail.url
  this.dialog.confirm(this.messageValue).then((ok) => {
    if (!ok) return
    this.confirmed = true
    this.reset()
    Turbo.visit(url)
  })
}
```

`beforeunload` cannot be made async at all — browsers show their own generic string and ignore yours. Accept that the real-unload case gets the browser's dialog.

**Decomposition.**
- `dirty-form` — track changes, set `data-dirty`, guard `beforeunload` + `turbo:before-visit` + `turbo:before-frame-render`, clear on `turbo:submit-end`.
- `confirm` — the promise-returning `<dialog>` used in the async variant.
- `persist` — optionally stash the in-progress values so "leave anyway" is recoverable.

**A11y.** The native `beforeunload` dialog is browser chrome and inherently accessible. A custom `<dialog>` confirm must be `dialog` + `focus-trap` + `dismiss`, follow the [APG alertdialog pattern](https://www.w3.org/WAI/ARIA/apg/patterns/alertdialog/), and default focus to the **safe** action ("Stay"), not the destructive one.

**Native.** `beforeunload` does not fire when the native navigator pops a screen, and neither does `turbo:before-visit` — the web view is simply removed. Guard the native back gesture through a bridge component (`Bridge.postMessage("dirty", { dirty: true })` and have the native side intercept the pop), or sidestep it entirely with autosave. **This is a real gap: a web-only dirty guard gives you no protection in Hotwire Native.** See `04-hotwire-native.md`.

**Pitfalls.**
- **`beforeunload` alone does nothing in a Hotwire app.** Every Turbo Drive link click bypasses it. This is the pattern.
- Forgetting to clear on `turbo:submit-end` → prompt on every successful save.
- `beforeunload` requires a prior user gesture in Chrome ("sticky activation"); a form the user never interacted with won't prompt — which is what you want, but it makes testing confusing.
- File inputs can't be serialized into `FormData`-based comparison meaningfully (`File` objects stringify to `[object File]`); track them separately or accept false negatives.
- Trix / rich text: the hidden input updates on `trix-change`, so include that in your `action` list or the editor's content is invisible to the dirty check.
- The `input` event doesn't fire for programmatic value changes. If a Stimulus controller sets a value, dispatch `new Event("input", { bubbles: true })`.
- Morphing page refreshes re-render the form without a navigation — your guard never runs, and idiomorph may reset the focused input's value (see *Submit-on-change*). Don't put a dirty-guarded form on a morph-refreshing page.
- Don't guard trivially-dirty forms (a single search box). The prompt is expensive attention.

**Prior art.**
- [Turbo events reference](https://turbo.hotwired.dev/reference/events) — `turbo:before-visit` and `turbo:before-frame-render` are both cancelable
- [MDN: `beforeunload`](https://developer.mozilla.org/en-US/docs/Web/API/Window/beforeunload_event) — note the sticky-activation requirement and that custom messages are ignored
- No maintained gem/package does this correctly for Turbo; `dirtyforms` (jQuery) and `stimulus-dirty-form` variants on npm all predate the frame case. Vendor the controller above.

---

### Disable-while-submitting

**Hotwire answer.** **No JS needed.** `data-turbo-submits-with="Saving…"` on the submit button (Turbo 7.2+) swaps its label for the duration of the submission, and Turbo already disables the submitter and sets `aria-busy="true"` on the `<html>` element, the `<form>`, and any enclosing `<turbo-frame>` — plus shows the `<turbo-progress-bar>` after 500 ms. Style off those attributes and write zero JavaScript. See [02-turbo-deep-dive §2.11](../notes/02-turbo-deep-dive.md).

**Code.**

```erb
<%= form_with model: @post do |f| %>
  <%= f.text_field :title %>
  <%= f.submit "Publish", data: { turbo_submits_with: "Publishing…" } %>
<% end %>
```

```css
/* Everything below is free — Turbo sets these attributes itself. */
form[aria-busy="true"]        { opacity: .6; pointer-events: none; }
turbo-frame[aria-busy="true"] { cursor: progress; }
turbo-frame[busy] .spinner    { display: block; }
html[aria-busy="true"] .global-spinner { display: block; }

.turbo-progress-bar { height: 3px; background: var(--accent); }
```

**What Turbo does automatically, verified in 8.0.23's source.**

| Behaviour | Source |
|---|---|
| Swaps `button.innerHTML` (or `input.value`) to `data-turbo-submits-with`, restores it on `turbo:submit-end` | `src/core/drive/form_submission.js` — `setSubmitsWith` / `resetSubmitterText`. Read from the **submitter only**, never the form. |
| Disables the submitter (`submitter.disabled = true`), re-enables after | `src/core/config/forms.js` — `config.forms.submitter` defaults to `"disabled"` |
| Sets `aria-busy="true"` on `<html>`, the `<form>`, and the enclosing/target `<turbo-frame>`; clears on completion | `src/util.js` `markAsBusy`/`clearBusyState` |
| Appends the submitter's `name`/`value` to the FormData **before** disabling, so `params[:commit]` still works | `src/core/drive/form_submission.js` — `buildFormData` |
| Shows the progress bar after `Turbo.config.drive.progressBarDelay` (**500 ms**) | `src/core/config/drive.js` |

**Only the clicked submitter is disabled**, not every button in the form. That's correct — but it means a form with three submit buttons leaves the other two live. If you need all of them locked, style off `form[aria-busy="true"] { pointer-events: none }` (as above) rather than scripting it.

**The a11y-friendlier disable strategy.** `disabled` removes the button from the accessibility tree and blows away focus mid-interaction, which screen-reader and keyboard users notice. Turbo ships an alternative:

```js
// app/javascript/application.js
import "@hotwired/turbo-rails"
Turbo.config.forms.submitter = "aria-disabled"
// sets aria-disabled="true" and swallows clicks, keeping focus and the a11y node
```
(Deprecated pre-Turbo-8 spelling: `Turbo.setFormMode()` / direct mutation of `Turbo.session`. If a tutorial uses those, it predates Turbo 8.)

A fully custom strategy is also supported:

```js
Turbo.config.forms.submitter = {
  beforeSubmit: (el) => el.classList.add("is-busy"),
  afterSubmit:  (el) => el.classList.remove("is-busy")
}
```

**Multiple submit buttons.** `data-turbo-submits-with` is read from the submitter, so each button gets its own label — and `formaction`/`formmethod`/`formenctype` on the submitter are honoured:

```erb
<%= form_with model: @post do |f| %>
  <%= f.submit "Save draft", name: "commit", value: "draft",
        data: { turbo_submits_with: "Saving draft…" } %>
  <%= f.submit "Publish", name: "commit", value: "publish",
        data: { turbo_submits_with: "Publishing…" } %>
  <%= button_tag "Delete", type: "submit",
        formaction: post_path(@post), formmethod: "post",
        name: "_method", value: "delete",
        data: { turbo_submits_with: "Deleting…",
                turbo_confirm: "Delete this post?" } %>
<% end %>
```

From JS, always pass the submitter explicitly so its label swap and `formaction` apply:

```js
form.requestSubmit(document.getElementById("publish_button"))
```

**Buttons outside the form via `form=`.** Standard HTML, and Turbo handles it: `FormSubmitObserver` listens for the `submit` event on the form, and the browser's own form-owner resolution means a `<button form="post_form" type="submit">` anywhere in the document is a legitimate submitter. `data-turbo-submits-with` works on it unchanged.

```erb
<%= form_with model: @post, id: "post_form" do |f| %>…<% end %>

<%# In a sticky footer, outside the <form> element entirely %>
<footer class="sticky-actions">
  <button type="submit" form="post_form" data-turbo-submits-with="Saving…">Save</button>
</footer>
```

Caveat: `form=` is not supported inside a `<dialog>` in older Safari for *implicit* submission, and the `form` attribute does **not** work on `<input type="submit">` in some legacy paths — use `<button type="submit" form="…">`. Also, a `form=` button that lives outside the frame containing the form will still submit into the frame correctly (Turbo resolves the frame from the form, not the submitter).

**Decomposition.**
- Nothing. This is the strongest "no JS needed" answer in the whole section.
- `transition` only if you want an animated spinner swap beyond a CSS class.

**A11y.**
- `aria-busy="true"` on `<form>` is set for you; that's the semantically correct signal.
- Prefer `Turbo.config.forms.submitter = "aria-disabled"` globally — it keeps focus on the button and keeps it in the a11y tree, so a screen reader user isn't dumped to `<body>` mid-submit.
- The label swap ("Save" → "Saving…") is announced only if the button is focused (it usually is, having just been activated). Don't rely on it as the sole signal for long operations; add a `role="status"` region.
- The `<turbo-progress-bar>` is decorative and not announced. For submissions over ~2 s, add your own polite status text.
- Never `pointer-events: none` without also handling keyboard: it doesn't block Enter on a focused button. `aria-disabled` + Turbo's click-swallowing does.

**Native.** Hotwire Native shows its own loading treatment for screen transitions but not for in-page form submissions. Hide the `turbo-progress-bar` in the native shell (`html[data-native] .turbo-progress-bar { display: none }`) and let `data-turbo-submits-with` carry the feedback. Long submits should surface a native activity indicator via a bridge component.

**Pitfalls.**
- `data-turbo-submits-with` on the `<form>` does nothing — it must be on the **submitter**.
- With the default `"disabled"` strategy the button loses focus. Users pressing Enter twice in quick succession end up focused on `<body>`.
- The label swap uses `innerHTML` for `<button>`: an icon inside the button is destroyed and restored, which is fine, but if a Stimulus controller was bound to a child element it gets disconnected and reconnected.
- If the response is a 204, `turbo:submit-end` still fires and the label restores — good. If the request errors at the network level, `turbo:submit-end` fires with `success: false` and the label still restores.
- A form with `data-turbo="false"` gets none of this; it's a native submission.
- The progress bar only appears for **Drive visits** taking >500 ms, not for frame or stream-only submissions. Frame loading state comes from `turbo-frame[aria-busy]`/`[busy]`.

**Prior art.**
- [Turbo attributes reference](https://turbo.hotwired.dev/reference/attributes) — *"`data-turbo-submits-with` specifies text to display when submitting a form… After the submission, the original text will be restored"*
- [Turbo `config.forms.submitter`](https://turbo.hotwired.dev/reference/drive) — `"disabled"` (default) / `"aria-disabled"` / custom
- [02-turbo-deep-dive §2.11](../notes/02-turbo-deep-dive.md)
- Superseded: `data-disable-with` (rails-ujs). It still works in apps that load rails-ujs, but do not use it in a Turbo app — the two mechanisms fight over the button.

---

### "Add another" repeated sections

**Hotwire answer.** Same machinery as *Nested forms* — `nested-form` cloning a `<template>` — with one simplification available when the parent is **already persisted**: skip the template entirely and let the server append the row via a Turbo Stream. That variant is strictly better whenever the new row needs anything from the server.

**Code (persisted-parent variant).**

```erb
<%# on the parent's edit page %>
<div id="<%= dom_id(@invoice, :line_items) %>">
  <%= render @invoice.line_items %>
</div>

<%= button_to "Add line item", invoice_line_items_path(@invoice),
      method: :post, form: { data: { turbo_frame: "_top" } },
      data: { turbo_submits_with: "Adding…" } %>
```

```ruby
# app/controllers/line_items_controller.rb
def create
  @line_item = @invoice.line_items.create!   # a blank draft row
  render turbo_stream: turbo_stream.append(
    dom_id(@invoice, :line_items), partial: "line_items/fields", locals: { line_item: @line_item }
  )
end
```

Each appended row then autosaves independently (see *Autosave*), which sidesteps `accepts_nested_attributes_for` entirely — the shape Rails Designer argues for in [*Nested forms without `accepts_nested_attributes_for`*](https://railsdesigner.com/nested-forms-without-accepts-nested-attributes/) (2026-01-15): *"Each form is independent… No complex params parsing."* It requires a persisted (or draft) parent and a `status` column so half-built records don't pollute reports.

**Decomposition.** `nested-form` (unpersisted parent) **or** nothing at all (persisted parent + stream append) + `autosubmit` per row.

**A11y.** As *Nested forms*: unique accessible name per remove button, focus into the new row's first input after append, polite live-region announcement. With the stream variant, Turbo restores focus after a stream render only if the focused element has an `id` — the "Add" button should have one so focus returns to it.

**Native.** Prefer a native "add" screen for anything with more than two fields per row.

**Pitfalls.**
- Creating a blank record on "Add" means your table now contains rows a user may abandon. Add `status: :draft` + a sweeper job, or you will ship a reporting bug.
- Don't mix the two approaches in one form; the params shapes differ (`line_items_attributes` vs. independent `line_item` posts).

**Prior art.** See *Nested forms* — same list. Plus [Rails Designer: "Save and add another"](https://railsdesigner.com/save-and-another/) and [inline "save and another"](https://railsdesigner.com/inline-save-and-another/) for the adjacent "submit and immediately start a fresh one" flow.

---

### Form state across Turbo cache preview (the flash-of-old-form problem)

**Hotwire answer.** Turbo Drive caches a snapshot of the page before leaving it and paints that snapshot instantly on return, before the network response arrives. Form `value`s live in the DOM's *property* state, not attributes, so what the preview shows is whatever Turbo captured — usually stale, sometimes a half-typed draft, occasionally another user's input on a shared machine. **Pick one of three: `data-turbo-permanent` to carry live state across, `<meta name="turbo-cache-control" content="no-preview">` to skip the preview for that page, or morphing to avoid the snapshot dance entirely.**

**Code.**

```erb
<%# 1. Carry a specific element's live state across visits. Needs a unique id. %>
<div id="composer" data-turbo-permanent>
  <%= text_area_tag :draft, nil, id: "draft_body" %>
</div>

<%# 2. Never show a stale preview of this page (still cached for restoration). %>
<meta name="turbo-cache-control" content="no-preview">

<%# 3. Never cache it at all — always refetch, even on back. %>
<meta name="turbo-cache-control" content="no-cache">

<%# 4. Strip transient chrome (flash messages, toasts) before caching. %>
<div class="flash" data-turbo-temporary>Saved.</div>
```

```js
// Programmatic equivalents (Turbo 8; NOT Turbo.clearCache()/setCacheControl()).
Turbo.cache.exemptPageFromPreview()   // == no-preview
Turbo.cache.exemptPageFromCache()     // == no-cache
Turbo.cache.resetCacheControl()
Turbo.cache.clear()                   // replaces the removed Turbo.clearCache()
```

```js
// 5. Explicitly scrub sensitive fields at cache time.
document.addEventListener("turbo:before-cache", () => {
  document.querySelectorAll("input[type=password], [data-scrub-on-cache]")
          .forEach((el) => { el.value = "" })
  document.querySelectorAll("dialog[open]").forEach((d) => d.close())
})
```

**`data-turbo-cache="false"` is gone.** In Turbo 8.0.23's source the cache observer's only selector is `[data-turbo-temporary]` (`src/observers/cache_observer.js`), and `data-turbo-cache` appears nowhere in `src/`. The [attributes reference](https://turbo.hotwired.dev/reference/attributes) lists `data-turbo-temporary` and not `data-turbo-cache`. **Any tutorial telling you to write `data-turbo-cache="false"` predates Turbo 7.2 — flag it.**

**Morphing sidesteps the problem.** A page refresh with `<meta name="turbo-refresh-method" content="morph">` doesn't render a cached preview at all — it diffs the live DOM against the new response, so there is no flash and no snapshot restoration (Turbo's own test asserts `turbo:before-cache` does **not** fire on a morph refresh). It introduces a *different* problem — idiomorph syncs the focused input's `value` from the response (see *Submit-on-change*) — but for the flash-of-old-form specifically, morph is the cleanest fix.

**Decomposition.**
- `persist` — mirror in-progress values to `sessionStorage` and reapply on `connect`. This is the only approach that survives a full reload, not just a Turbo visit.
- `dirty-form` — so you know whether the state is worth preserving.

**A11y.** The preview is marked `[data-turbo-preview]` on `<html>`; Turbo does not set `aria-busy` during it. If your preview shows interactive-looking-but-inert controls, gate them: `html[data-turbo-preview] form { pointer-events: none; }`.

**Native.** Hotwire Native keeps web views alive across screens, so the preview problem manifests differently — a popped-to screen shows its real live DOM rather than a snapshot. Don't assume the web behaviour carries over; test the native back path explicitly.

**Pitfalls.**
- **Passwords and other secrets can persist in a cached preview.** Always scrub on `turbo:before-cache` (snippet above). This is a real security finding on shared devices.
- `data-turbo-permanent` requires a unique, stable `id`; without one it's silently ignored. And a permanent element is also skipped by morph, so it stops receiving *any* server updates.
- `no-preview` still caches the page for restoration visits (back button); `no-cache` disables both.
- Dynamically added nested-form rows *are* in the snapshot and *do* come back on preview — including their values if the browser also restored them — but they will not survive a morph refresh. Two different mechanisms, opposite behaviours.
- `<dialog open>`, open `<details>`, and CSS transition states all get snapshotted mid-flight. Close them in `turbo:before-cache`.
- Deprecated: `Turbo.clearCache()` → `Turbo.cache.clear()`. Any source using the former predates Turbo 8.

**Prior art.**
- [Turbo Handbook: Understanding Caching](https://turbo.hotwired.dev/handbook/building#understanding-caching) — `turbo-cache-control`, `data-turbo-temporary`, `data-turbo-permanent`, `Turbo.cache.*`
- [02-turbo-deep-dive §2.6 and §2.7](../notes/02-turbo-deep-dive.md)
- [@stimulus-components](https://www.stimulus-components.com/) has no `persist` equivalent; vendor it.

---



## Forms — rich inputs & uploads

### Combobox / autocomplete / typeahead (server-backed)

**Hotwire answer.** Use [**hotwire_combobox**](https://github.com/josefarias/hotwire_combobox) (gem `0.4.1`, npm `@josefarias/hotwire_combobox` `0.4.1`, released 2026-02-13). It is the only Rails-native combobox that ships correct ARIA 1.2 semantics, async/paginated options over Turbo Streams, free-text "create new" values, and multiselect chips — and it is one helper call. Roll your own `combobox` primitive (input + `<turbo-frame>` listbox, driven by `autosubmit`) only when you need markup the gem can't express; reach for Tom Select when you need drag-reorderable, heavily-styled tokens on a client-side dataset.

**Code — the sanctioned answer.** Verified against the gem source at `lib/hotwire_combobox/helper.rb`, `app/presenters/hotwire_combobox/component.rb`, and `test/dummy/app/views/comboboxes/*`.

```erb
<%# Static options — collection responds to #to_combobox_display %>
<%= combobox_tag "state", State.all, id: "state-field", label: "State" %>

<%# Inside a form builder (name maps to the model attribute) %>
<%= form_with model: @post do |form| %>
  <%= form.combobox :author_id, User.all, label: "Author", open: true %>
<% end %>

<%# Async / server-filtered: pass a PATH instead of a collection %>
<%= combobox_tag "movie_id", movies_path, id: "movie-field", label: "Choose your movie!" %>

<%# Free text: allow a value that is not in the list, submitted under a second name %>
<%= form.combobox :favorite_state_id, State.all,
      id: "allow-new",
      name_when_new: "user[favorite_state_attributes][name]" %>
```

```ruby
# app/controllers/movies_controller.rb — the async endpoint
class MoviesController < ApplicationController
  def index
    movies = Movie.search(params[:q]).alphabetically
    set_page_and_extract_portion_from movies, per_page: 5   # geared_pagination
  end
end
```

```erb
<%# app/views/movies/index.turbo_stream.erb %>
<%= paginated_combobox_options @page.records,
      next_page: @page.last? ? nil : @page.next_param %>
```

The gem sends `GET <src>?q=<query>&for_id=<combobox id>&format=turbo_stream`, debounced (`debounce_interval:`, default 150 ms), and appends the next page when the sentinel frame scrolls into view. Full constructor options, read from `HotwireCombobox::Component#initialize`: `association_name:`, `autocomplete:` (`:both` default, `:list`, `:none`), `chip_attributes:`, `chip_template:`, `data:`, `debounce_interval:`, `dialog_label:`, `form:`, `free_text:`, `id:`, `input:`, `label:`, `mobile_at:` (default `"640px"` — below this it renders a full-screen `<dialog>`), `multiselect_chip_src:`, `name_when_new:`, `open:`, `preload:`, `prefilled_chips:`, `value:`.

**There is no `open_on_focus:` option.** The equivalent is `open: true`, which expands the listbox on connect; the listbox also opens on click/keydown via the controller's own actions (`click->hw-combobox#toggle`).

**Code — the roll-your-own `combobox` primitive.** Input + a `<turbo-frame>` that re-fetches a `role="listbox"`. Note the trap: you **cannot** nest a search `<form>` inside the record form, so drive the frame by setting `frame.src` rather than by `autosubmit`-ing a nested GET form.

```erb
<%# app/views/posts/_city_combobox.html.erb %>
<div data-controller="combobox"
     data-combobox-src-value="<%= cities_path %>"
     data-combobox-selected-class="is-active">
  <label for="city_input">City</label>

  <input id="city_input" type="text" autocomplete="off"
         role="combobox" aria-expanded="false" aria-controls="city_listbox"
         aria-autocomplete="list" aria-activedescendant=""
         data-combobox-target="input"
         data-action="input->combobox#filter keydown->combobox#navigate
                      focus->combobox#open click@window->combobox#closeOnOutside">

  <%= hidden_field_tag "post[city_id]", @post.city_id,
        data: { combobox_target: "hiddenField" } %>

  <%= turbo_frame_tag "city_options", data: { combobox_target: "frame" } do %>
    <ul id="city_listbox" role="listbox" aria-label="Cities" hidden></ul>
  <% end %>
</div>
```

```erb
<%# app/views/cities/index.html.erb — rendered inside the frame %>
<%= turbo_frame_tag "city_options" do %>
  <ul id="city_listbox" role="listbox" aria-label="Cities">
    <% @cities.each do |city| %>
      <li role="option" id="city_option_<%= city.id %>" aria-selected="false"
          data-combobox-target="option"
          data-value="<%= city.id %>" data-display="<%= city.name %>"
          data-action="click->combobox#choose mousedown->combobox#preventBlur">
        <%= city.name %>
      </li>
    <% end %>
  </ul>
<% end %>
```

```js
// app/javascript/controllers/combobox_controller.js
import { Controller } from "@hotwired/stimulus"
import { useDebounce } from "stimulus-use"

export default class extends Controller {
  static targets = ["input", "frame", "hiddenField", "option"]
  static values  = { src: String, minLength: { type: Number, default: 1 } }
  static classes = ["selected"]
  static debounces = [{ name: "filter", wait: 200 }]   // debounced via stimulus-use

  connect() { useDebounce(this); this.activeIndex = -1 }

  filter() {
    const q = this.inputTarget.value.trim()
    if (q.length < this.minLengthValue) return this.close()
    const url = new URL(this.srcValue, location.origin)
    url.searchParams.set("q", q)
    this.frameTarget.src = url.toString()   // Turbo fetches + swaps the listbox
    this.open()
  }

  open()  { this.#listbox()?.removeAttribute("hidden"); this.inputTarget.setAttribute("aria-expanded", "true") }
  close() { this.#listbox()?.setAttribute("hidden", ""); this.inputTarget.setAttribute("aria-expanded", "false")
            this.inputTarget.setAttribute("aria-activedescendant", ""); this.activeIndex = -1 }

  navigate(event) {
    const keys = {
      ArrowDown: () => this.#move(1), ArrowUp: () => this.#move(-1),
      Home: () => this.#moveTo(0),    End: () => this.#moveTo(this.optionTargets.length - 1),
      Enter: () => this.optionTargets[this.activeIndex]?.click(),
      Escape: () => this.close()
    }
    const handler = keys[event.key]
    if (!handler) return
    event.preventDefault()
    handler()
  }

  choose({ currentTarget }) {
    this.inputTarget.value = currentTarget.dataset.display
    this.hiddenFieldTarget.value = currentTarget.dataset.value
    this.hiddenFieldTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.close()
    this.inputTarget.focus()
  }

  preventBlur(event) { event.preventDefault() }          // keep focus in the input
  closeOnOutside(event) { if (!this.element.contains(event.target)) this.close() }

  #listbox() { return this.element.querySelector("[role=listbox]") }
  #moveTo(i) {
    this.optionTargets.forEach(o => { o.classList.remove(this.selectedClass); o.setAttribute("aria-selected", "false") })
    const option = this.optionTargets[i]
    if (!option) return
    this.activeIndex = i
    option.classList.add(this.selectedClass)
    option.setAttribute("aria-selected", "true")
    option.scrollIntoView({ block: "nearest" })
    this.inputTarget.setAttribute("aria-activedescendant", option.id)  // focus NEVER leaves the input
  }
  #move(delta) {
    const n = this.optionTargets.length
    if (n === 0) return
    this.#moveTo((this.activeIndex + delta + n) % n)
  }
}
```

**When to wrap a library instead.** [Tom Select](https://tom-select.js.org/) `2.6.2` (2026-07-07, actively maintained) — client-side datasets, tokens with drag-reorder, optgroups, `create:` for new values, and a real `destroy()` for teardown. [Choices.js](https://github.com/Choices-js/Choices) `11.2.3` (2026-04-30) — lighter, similar scope. [`@github/auto-complete-element`](https://github.com/github/auto-complete-element) `3.8.0` (2025-03-11) — a zero-Stimulus custom element that is essentially the roll-your-own pattern above, packaged: `<auto-complete src="/users/search" for="users-popup">` wrapping an `<input>` and a `<ul>`, with the server returning `<li role="option" data-autocomplete-value="…">` fragments and a `#users-popup-feedback` live region. **Choose `@github/auto-complete-element` over hand-rolling if you don't want the gem** — it's less code than the controller above and its a11y is already right. `select2` is SUPERSEDED (jQuery); do not use it in new Rails 8 code.

**Decomposition.**
- `combobox` (input + listbox + ARIA 1.2 semantics + `aria-activedescendant`)
- `autosubmit` — only if the search input lives in its own standalone GET form
- `click-outside` + `dismiss` — close on outside pointer/Esc
- `anchor` — position the listbox when it must escape an `overflow: hidden` ancestor
- `intersection` — the "load next page" sentinel in async/paginated mode

**A11y.** [APG combobox pattern](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/). Input carries `role="combobox"`, `aria-expanded`, `aria-controls="<listbox id>"`, `aria-autocomplete` (`none|list|both`), and an accessible name via `<label for>` / `aria-labelledby`. Popup is `role="listbox"` with `role="option"` children and `aria-selected="true"` on the active option. **DOM focus never leaves the input** — the active option is communicated with `aria-activedescendant`. This is emphatically *not* `roving-focus`; do not put `tabindex` on options. Keyboard: Down/Up move (and open), Alt+Down opens without moving, Alt+Up closes, Home/End jump, Enter accepts, Esc closes (and optionally clears). APG explicitly prefers `aria-controls` over the ARIA-1.0 `aria-owns` — note that hotwire_combobox emits *both* (`markup/input.rb` sets `controls:` and `owns:`), which is belt-and-braces, not a bug. hotwire_combobox documents three deliberate APG deviations in its README: wrap-around arrow selection, permitting an unlabeled combobox, and multiselect (for which [no APG guidance exists yet](https://github.com/w3c/aria-practices/issues/1512)) announced via a live region.

**Native.** In Hotwire Native, hotwire_combobox's `mobile_at:` breakpoint already swaps to a full-screen `<dialog>`, which reads acceptably in a web view. For anything that is a primary selection step (choosing a recipient, a project, a location), promote it to a **bridge component** backed by a native picker/search screen — see `04-hotwire-native.md` §3 and §3.6 for hiding the web control when the native one exists. Async comboboxes issue a request per keystroke; on cellular, raise `debounce_interval:` to ~300 ms for the native variant.

**Pitfalls.**
- **Nested forms.** A search `<form>` inside the record `<form>` is invalid HTML and silently breaks submission. Either set `frame.src` from JS (above), or move the search input outside and wire it with the `form` attribute.
- The listbox must keep a **stable `id`** across frame reloads or `aria-controls` dangles.
- `mousedown` on an option blurs the input before `click` fires; `preventDefault()` on `mousedown` or the listbox closes before selection lands.
- hotwire_combobox needs the **gem and the npm package pinned to the same version** (README warning) when using jsbundling; importmap users get it automatically via the engine's `hw_importmap.rb`.
- Options must respond to `to_combobox_display` (or you pass `display:`); the gem raises a loud, explicit `NoMethodError` telling you to add it.
- Under morphing, wrapped libraries (Tom Select/Choices) get their generated DOM pruned by idiomorph — see `02-turbo-deep-dive` §5.8 gotcha 2; mark the wrapper `data-turbo-permanent` or `preventDefault()` in `turbo:before-morph-element`. hotwire_combobox handles this itself with a `turbo:morph-element->hw-combobox#idempotentConnect` action.
- Async responses are `format: :turbo_stream`; a controller that only renders HTML will 406.

**Prior art.**
- https://github.com/josefarias/hotwire_combobox — the gem (docs: https://hotwirecombobox.com/)
- https://github.com/github/auto-complete-element
- https://tom-select.js.org/ · https://github.com/Choices-js/Choices
- https://www.w3.org/WAI/ARIA/apg/patterns/combobox/
- SUPERSEDED: select2, jQuery UI autocomplete

---

### Tag / token input

**Hotwire answer.** Two honest answers, and the boring one usually wins. (1) If tags are free text: **ActsAsTaggableOn + a single comma-separated string field** — literally `f.text_field :tag_list` — and stop there. No JS. (2) If tags are records the user picks from an existing set: **hotwire_combobox in multiselect mode**, which renders chips and submits one comma-joined hidden field. Reach for Tom Select only when you need drag-reorderable tokens.

**Code — the boring answer that wins.**

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  acts_as_taggable_on :tags
end
```

```erb
<%= form_with model: @post do |form| %>
  <%= form.label :tag_list, "Tags" %>
  <%= form.text_field :tag_list, value: @post.tag_list.to_s,
        list: "known_tags", autocomplete: "off",
        aria: { describedby: "tag_hint" } %>
  <p id="tag_hint">Separate tags with commas.</p>

  <datalist id="known_tags">
    <% ActsAsTaggableOn::Tag.order(taggings_count: :desc).limit(50).each do |tag| %>
      <option value="<%= tag.name %>">
    <% end %>
  </datalist>
<% end %>
```

```ruby
# params.require(:post).permit(:title, :tag_list)  — that is the whole integration
```

`tag_list=` parses on the configured delimiter (comma by default); `tag_list.add("a, b", parse: true)` is the string form ([README](https://github.com/mbleigh/acts-as-taggable-on#usage)). Gem `13.0.0`, 2025-11-05.

**Code — hotwire_combobox multiselect (record-backed).** Multiselect is switched on by passing `multiselect_chip_src:` (server-rendered chips) *or* `chip_template:` (client-rendered from a `<template>`); see `component/multiselect.rb#multiselect?`.

```erb
<%= combobox_tag "post[tag_ids]", Tag.all,
      id: "tags-field", label: "Tags",
      multiselect_chip_src: tag_chips_path,
      placeholder: "Select tags" %>
```

```ruby
# app/controllers/tag_chips_controller.rb
class TagChipsController < ApplicationController
  def create
    tags = Tag.where(id: params[:combobox_values].split(","))
    render turbo_stream: helpers.combobox_selection_chips_for(tags)
  end
end
```

```ruby
# The hidden field submits a COMMA-JOINED STRING, not an array:
#   params[:post][:tag_ids] # => "3,7,11"
@post.tag_ids = params[:post][:tag_ids].to_s.split(",")
```

Client-side chips instead, with a `{{placeholder}}` template:

```erb
<%= combobox_tag "post[tag_ids]", Tag.all,
      id: "tags-field",
      chip_template: { partial: "tags/chip" },
      chip_attributes: { display: :name, slug: ->(tag) { tag.name.parameterize } } %>
```

```erb
<%# app/views/tags/_chip.html.erb %>
<div class="chip chip--{{slug}}">
  <p>{{display}}</p>
  <%= tag.span **combobox_chip_remover_attrs(display: "{{display}}", value: "{{value}}") %>
</div>
```

`combobox_chip_remover_attrs` emits `tabindex="0"`, `aria-label="Remove …"`, and `data-action="click->hw-combobox#removeChip:stop keydown->hw-combobox#navigateChip"`; Backspace / Enter / Space on a focused chip removes it, Esc reopens the listbox (`multiselect.js#_chipKeyHandlers`).

**Code — the `<input type="hidden" name="post[tag_ids][]">` accumulation pattern** (when you want a real array and no gem):

```erb
<div data-controller="combobox" data-combobox-src-value="<%= tags_path %>">
  <ul data-combobox-target="chips" class="chips">
    <% @post.tags.each do |tag| %>
      <li class="chip">
        <input type="hidden" name="post[tag_ids][]" value="<%= tag.id %>">
        <%= tag.name %>
        <button type="button" aria-label="Remove <%= tag.name %>"
                data-action="click->combobox#removeChip">&times;</button>
      </li>
    <% end %>
  </ul>
  <input type="hidden" name="post[tag_ids][]" value="">  <%# ensures "cleared" submits %>
  <input type="text" role="combobox" aria-expanded="false" aria-controls="tag_listbox" …>
</div>
```

```js
  addChip({ value, display }) {
    if (this.chipsTarget.querySelector(`input[value="${CSS.escape(value)}"]`)) return
    const li = document.createElement("li")
    li.className = "chip"
    li.innerHTML = `<input type="hidden" name="post[tag_ids][]" value="${value}">
                    ${display}
                    <button type="button" aria-label="Remove ${display}"
                            data-action="click->combobox#removeChip">&times;</button>`
    this.chipsTarget.append(li)
    this.announce(`${display} added`)
  }

  removeChip({ currentTarget }) {
    const chip = currentTarget.closest(".chip")
    const label = chip.textContent.trim()
    const next = chip.nextElementSibling || chip.previousElementSibling
    chip.remove()
    ;(next?.querySelector("button") || this.inputTarget).focus()   // never strand focus
    this.announce(`${label} removed`)
  }
```

**Decomposition.** `combobox` (multiselect mode) + `dismiss` (chip removal) + `roving-focus` (moving between chips with Left/Right) + optional `announce`-style `aria-live` region.

**A11y.** Follow the [APG combobox pattern](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/) plus `aria-multiselectable="true"` on the listbox (hotwire_combobox sets this in `markup/listbox.rb`). Chips are focusable (`tabindex="0"`) with `aria-label="Remove <name>"`; Backspace/Delete on a focused chip removes it; **after removal, move focus to the adjacent chip or back to the input** — a removed chip that leaves focus on `<body>` is the classic bug. Announce add/remove into a visually-hidden `aria-live="polite"` region; there is no APG multiselect-combobox pattern, so this is the community convention.

**Native.** Chips in a web view are fiddly to hit with a thumb. For a first-class tagging screen, promote to a bridge component with a native token field / picker (`04-hotwire-native.md` §3.5). Otherwise ensure chip hit targets are ≥44×44 px.

**Pitfalls.**
- hotwire_combobox multiselect submits **one comma-joined string**, not `tag_ids[]`. Split it in the controller. `hidden_field_value` also joins arrays with `,` on render.
- Always render a trailing empty `name="post[tag_ids][]"` hidden input, or removing every chip submits nothing and Rails leaves the association untouched.
- With `free_text:` on a multiselect, `name_when_new:` **must equal** the regular hidden-field name — the gem validates this and raises otherwise (`component/freetext.rb`).
- ActsAsTaggableOn's default delimiter is `,`; tags containing commas need a delimiter change *and* a matching front-end change.
- Deduplicate on insert; `CSS.escape` the value in the existence check or an id like `12"` breaks the selector.

**Prior art.**
- https://github.com/josefarias/hotwire_combobox (multiselect + chips)
- https://github.com/mbleigh/acts-as-taggable-on (`13.0.0`)
- https://tom-select.js.org/examples/ (`2.6.2`) · https://github.com/Choices-js/Choices (`11.2.3`)
- SUPERSEDED: select2 tokenizer, jQuery tokeninput

---

### File upload with progress (Active Storage direct upload)

**Hotwire answer.** No third-party uploader. Set `direct_upload: true` on the file field, start the Active Storage JS, and write one `direct-upload` Stimulus controller that listens for the `direct-upload:*` events Rails already dispatches on the input. Use the `DirectUpload` class manually only when you need uploads to start on *file selection* rather than on *form submit* (drag-and-drop galleries, wizard steps).

**Code — the event-driven controller (uploads start on submit).** Events and semantics per the [Active Storage guide](https://guides.rubyonrails.org/active_storage_overview.html#direct-uploads) and `activestorage/app/javascript/activestorage/direct_upload_controller.js`.

```erb
<%= form_with model: @post, data: { controller: "direct-upload",
                                    action: "direct-uploads:start->direct-upload#lock
                                             direct-uploads:end->direct-upload#unlock" } do |form| %>
  <%= form.label :attachments, "Attachments" %>
  <%= form.file_field :attachments, multiple: true, direct_upload: true,
        data: { direct_upload_target: "input",
                action: "direct-upload:initialize->direct-upload#initialize
                         direct-upload:start->direct-upload#start
                         direct-upload:progress->direct-upload#progress
                         direct-upload:error->direct-upload#error
                         direct-upload:end->direct-upload#end" } %>

  <ul data-direct-upload-target="list" aria-live="polite"></ul>

  <%= form.submit "Save", data: { direct_upload_target: "submit" } %>
<% end %>
```

```js
// app/javascript/controllers/direct_upload_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "list", "submit"]

  initialize({ detail: { id, file } }) {
    this.listTarget.insertAdjacentHTML("beforeend", `
      <li id="upload-${id}" class="upload upload--pending">
        <span class="upload__name">${file.name}</span>
        <progress id="upload-progress-${id}" max="100" value="0"
                  aria-label="Uploading ${file.name}">0%</progress>
        <span class="upload__error" role="alert"></span>
      </li>`)
  }

  start({ detail: { id } })  { this.#el(id)?.classList.remove("upload--pending") }

  progress({ detail: { id, progress } }) {
    const bar = document.getElementById(`upload-progress-${id}`)
    if (bar) { bar.value = progress; bar.textContent = `${Math.round(progress)}%` }
  }

  error(event) {
    event.preventDefault()                       // suppress Rails' default alert()
    const { id, error } = event.detail
    const el = this.#el(id)
    el?.classList.add("upload--error")
    el?.querySelector(".upload__error")?.replaceChildren(String(error))
  }

  end({ detail: { id } }) { this.#el(id)?.classList.add("upload--complete") }

  lock()   { this.submitTarget.disabled = true;  this.submitTarget.value = "Uploading…" }
  unlock() { this.submitTarget.disabled = false; this.submitTarget.value = "Save" }

  #el(id) { return document.getElementById(`upload-${id}`) }
}
```

**Code — `DirectUpload` used manually (uploads start on selection).** This is the version you want with `drop-zone`, and it is what `@rails/actiontext` itself does.

```js
// app/javascript/controllers/direct_upload_controller.js  (manual mode)
import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  static targets = ["input", "list", "submit"]
  static values  = { url: String, name: String }   // name: "post[attachments][]"

  connect() { this.pending = 0 }

  disconnect() {                                   // Turbo cache / navigation teardown
    this.aborted = true
    this.pending = 0
  }

  upload() {
    Array.from(this.inputTarget.files).forEach(file => this.#uploadOne(file))
    this.inputTarget.value = null                  // free the picker for a re-pick
  }

  #uploadOne(file) {
    const row = this.#renderRow(file)
    this.pending++; this.#syncSubmit()

    const upload = new DirectUpload(file, this.urlValue, {
      directUploadWillStoreFileWithXHR: (xhr) => {
        xhr.upload.addEventListener("progress", e => {
          row.querySelector("progress").value = (e.loaded / e.total) * 100
        })
      }
    })

    upload.create((error, blob) => {
      this.pending--; this.#syncSubmit()
      if (this.aborted) return
      if (error) { row.classList.add("upload--error"); return }

      const hidden = document.createElement("input")
      hidden.type  = "hidden"
      hidden.name  = this.nameValue                // e.g. "post[attachments][]"
      hidden.value = blob.signed_id
      row.append(hidden)
      row.classList.add("upload--complete")
    })
  }

  #syncSubmit() { this.submitTarget.disabled = this.pending > 0 }
  #renderRow(file) { /* … build and append the <li> … */ }
}
```

```erb
<%= form_with model: @post, data: { controller: "direct-upload",
      direct_upload_url_value: rails_direct_uploads_url,
      direct_upload_name_value: "post[attachments][]" } do |form| %>
  <input type="file" multiple
         data-direct-upload-target="input"
         data-action="change->direct-upload#upload">
  <ul data-direct-upload-target="list" aria-live="polite"></ul>
  <%= form.submit data: { direct_upload_target: "submit" } %>
<% end %>
```

**Rails 8 specifics.**

```ruby
# config/environments/production.rb
config.active_storage.service = :amazon
# app/models/post.rb
class Post < ApplicationRecord
  has_many_attached :attachments
end
```

```js
// app/javascript/application.js  — required, or nothing uploads
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()
```

- `direct_upload: true` only ever adds `data-direct-upload-url` (and, on Rails 8.2+/main, `data-checksum-algorithm` from `data_checksum_algorithm:`). Verified in `actionview/lib/action_view/helpers/form_tag_helper.rb#convert_direct_upload_option_to_url` on both `v8.1.0` and `main`. **`data-direct-upload-token` and `data-direct-upload-attachment-name` do not exist in Rails 8** — if a tutorial shows them, it is describing a fork or a patched app, not Rails.
- CORS is mandatory on S3/GCS/Azure (not on `:disk`). S3 bucket policy, from the guide:

```json
[
  { "AllowedHeaders": ["Content-Type", "Content-MD5", "Content-Disposition"],
    "AllowedMethods": ["PUT"],
    "AllowedOrigins": ["https://www.example.com"],
    "MaxAgeSeconds": 3600 }
]
```

- Blobs created by a direct upload that never get attached leak. Prune them: `ActiveStorage::Blob.unattached.where(created_at: ..2.days.ago).find_each(&:purge_later)`.
- Authenticated upload endpoints: subclass `ActiveStorage::DirectUploadsController`, and pass custom headers as the 4th `DirectUpload` argument (`new DirectUpload(file, url, delegate, headers)`).

**The Turbo gotcha, precisely.** Active Storage's UJS registers `document.addEventListener("submit", didSubmitForm, true)` — **capture phase** (`activestorage/app/javascript/activestorage/ujs.js`). It `preventDefault()`s your submit before Turbo's bubble-phase listener ever sees it, uploads every file, then re-submits by *synthetically clicking a submit button*. Consequences:
- Any code that disables the submit button on `turbo:submit-start` never fires the first time, then blocks the synthetic click. Gate on `direct-uploads:start` / `direct-uploads:end` instead (as above).
- A form submitted with `form.submit()` (no `submit` event) bypasses Active Storage entirely — files are never uploaded. Always use `form.requestSubmit()`; this is also what the `autosubmit` primitive must call.
- The first submit produces **no** `turbo:submit-start`; the re-submit produces the real one. Don't count them.
- With multiple direct-upload forms on a page, the `processingAttribute` guard is per-form, so concurrent forms are fine.

**Decomposition.** `direct-upload` + optional `drop-zone` + optional `file-preview` + `dirty-form` (warn before leaving with in-flight uploads).

**A11y.** Keep a real, labelled `<input type="file">`. Use `<progress max="100" value="…" aria-label="Uploading foo.pdf">` per file — `<progress>` maps to `role="progressbar"` for free. Put the file list in an `aria-live="polite"` container so additions/completions are announced; put errors in `role="alert"`. Announce completion textually, not only by colour. No APG pattern exists for file upload; the closest guidance is the [meter/progressbar](https://www.w3.org/WAI/ARIA/apg/patterns/meter/) role docs.

**Native.** `<input type="file">` opens the system photo/file picker in both WKWebView and Android WebView, so the basic path works unchanged. Add `accept="image/*"` and `capture="environment"` to get the camera. For large uploads on mobile, a **bridge component** is worth it: hand the file to a native background URLSession/WorkManager upload so it survives backgrounding, then post the signed id back to the web form (`04-hotwire-native.md` §3.5). Hide the drop zone when `hotwire_native_app?` (§4.1) — there is nothing to drag.

**Pitfalls.**
- Forgetting `ActiveStorage.start()`. Silent: the field just posts the raw file through Rack.
- `direct_upload:` on a field inside a `<turbo-frame>` that is later replaced leaves orphaned progress DOM; render the list inside the same frame.
- Progress caps at 90 % from real bytes; Rails then *simulates* 90→99 % while waiting for the response (`direct_upload_controller.js#simulateResponseProgress`). Don't treat 99 % as a hang.
- `direct-upload:error` calls `alert()` unless you `preventDefault()`.
- Rails computes an **MD5 checksum in the browser** before uploading; on a 1 GB file this is a multi-second freeze on the main thread. For very large files, consider a chunked uploader (Uppy + a custom endpoint) instead.
- Validation failures re-render the form; the *signed ids* survive in hidden fields only if you re-render them. Otherwise the user re-uploads everything.

**Prior art.**
- https://guides.rubyonrails.org/active_storage_overview.html#direct-uploads
- https://github.com/rails/rails/tree/main/activestorage/app/javascript/activestorage
- https://uppy.io/ (`@uppy/core` `5.2.0`, 2025-12-02) — the escape hatch for chunked/resumable (tus) uploads
- https://shrinerb.com/ — Shrine + Uppy, if you have outgrown Active Storage

---

### Drag-and-drop upload

**Hotwire answer.** Write the `drop-zone` primitive yourself — roughly 60 lines of Stimulus. **There is no maintained Rails/Stimulus drop-zone package**: `stimulus-components` has no dropzone entry (verified against https://www.stimulus-components.com/ — 33 components, none of them a dropzone), Dropzone.js is stuck at `6.0.0-beta.2` from **2021-11-29**, and the Rails-specific wrappers on GitHub were last touched in 2023. The one non-negotiable technique: use a `DataTransfer` to write the dropped files **into the real `<input type="file">`**, so the form, validation, and Active Storage all keep working unchanged.

**Code.**

```erb
<div data-controller="drop-zone direct-upload"
     data-drop-zone-over-class="drop-zone--over"
     data-action="dragover->drop-zone#over
                  dragenter->drop-zone#over
                  dragleave->drop-zone#leave
                  drop->drop-zone#drop
                  paste@document->drop-zone#paste">

  <p id="dz_hint">Drag files here, paste, or</p>

  <%# The real input stays. It is the keyboard path AND the form's source of truth. %>
  <%= form.file_field :attachments, multiple: true, direct_upload: true,
        aria: { describedby: "dz_hint" },
        data: { drop_zone_target: "input", direct_upload_target: "input",
                action: "change->drop-zone#preview" } %>

  <ul data-drop-zone-target="previews" aria-live="polite"></ul>
  <p data-drop-zone-target="status" class="sr-only" role="status"></p>
</div>
```

```js
// app/javascript/controllers/drop_zone_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "previews", "status"]
  static classes = ["over"]
  static values  = { accept: String, max: { type: Number, default: 0 } }

  connect()    { this.objectUrls = new Set() }
  disconnect() { this.#revokeAll() }              // no leaked blob: URLs on Turbo cache

  over(event)  { event.preventDefault(); this.element.classList.add(this.overClass) }
  leave(event) { event.preventDefault(); this.element.classList.remove(this.overClass) }

  drop(event) {
    event.preventDefault()
    this.element.classList.remove(this.overClass)
    this.#accept(event.dataTransfer.files)
  }

  paste(event) {
    const files = Array.from(event.clipboardData?.files ?? [])
    if (files.length === 0) return
    event.preventDefault()
    this.#accept(files)
  }

  preview() { this.#renderPreviews() }

  // --- the only reliable way to keep the form working -----------------------
  #accept(fileList) {
    const dt = new DataTransfer()
    // keep whatever is already selected …
    Array.from(this.inputTarget.files).forEach(f => dt.items.add(f))
    // … and append the new files
    Array.from(fileList)
      .filter(f => this.#allowed(f))
      .forEach(f => dt.items.add(f))

    this.inputTarget.files = dt.files                       // <- assign a FileList
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.statusTarget.textContent = `${dt.files.length} file(s) selected`
  }

  #allowed(file) {
    if (this.maxValue && file.size > this.maxValue) return false
    if (!this.acceptValue) return true
    return this.acceptValue.split(",").some(p => {
      const pattern = p.trim()
      return pattern.endsWith("/*")
        ? file.type.startsWith(pattern.slice(0, -1))
        : file.type === pattern || file.name.toLowerCase().endsWith(pattern)
    })
  }

  #renderPreviews() {
    this.#revokeAll()
    this.previewsTarget.replaceChildren(...Array.from(this.inputTarget.files).map(file => {
      const li = document.createElement("li")
      if (file.type.startsWith("image/")) {
        const url = URL.createObjectURL(file)
        this.objectUrls.add(url)
        const img = document.createElement("img")
        img.src = url
        img.alt = ""                                        // decorative; name is adjacent
        img.onload = () => { URL.revokeObjectURL(url); this.objectUrls.delete(url) }
        li.append(img)
      }
      li.append(document.createTextNode(file.name))
      return li
    }))
  }

  #revokeAll() { this.objectUrls.forEach(URL.revokeObjectURL); this.objectUrls.clear() }
}
```

`input.files = dataTransfer.files` is the whole trick — a `FileList` is otherwise read-only and unconstructible. It is supported in every current browser (the `DataTransfer` constructor has been baseline since 2018). Combined with `direct-upload` in the same element, the synthetic `change` event drives uploads with zero extra wiring.

**Decomposition.** `drop-zone` + `direct-upload` + `file-preview` (previews via `URL.createObjectURL`) + `dismiss` (per-file remove, which rebuilds the `DataTransfer` minus that file).

**A11y.** Drag-and-drop is **not** an accessible interaction; it must be an enhancement, never the only path. Keep a real, labelled `<input type="file">` that is reachable by Tab and operable with Enter/Space — do not `display: none` it (use a visually-hidden class or style it, and keep the visible affordance as its `<label>`). Announce accepted/rejected files through `role="status"` (polite) and `role="alert"` for rejections. Previews get `alt=""` with the filename in adjacent text. Related APG reading: there is no drag-and-drop *pattern*, only [WCAG 2.2 SC 2.5.7 Dragging Movements](https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements.html), which **requires** a single-pointer alternative — the file input is it.

**Native.** `dragover`/`drop` are dead code on phones. Gate the whole zone on `hotwire_native_app?` and render just the file field plus a "Take photo" button (`accept="image/*" capture="environment"`). If you want the native share-sheet / document-picker experience, that is a bridge component (`04-hotwire-native.md` §3.6).

**Pitfalls.**
- **You must `preventDefault()` on `dragover`**, not only `drop`. Without it the browser navigates away to the dropped file. This is the #1 bug.
- `dragleave` fires when moving over child elements. Either use a counter, or `pointer-events: none` on children, or (simplest) only clear the class on `drop`/`dragleave` of the container with a `relatedTarget` check.
- Directory drops give you `DataTransferItem` entries with `webkitGetAsEntry()`, not plain files. Handle or reject them explicitly; `dataTransfer.files` silently drops folders in some browsers.
- `URL.createObjectURL` leaks until revoked — revoke on `img.onload` *and* in `disconnect()`, or Turbo's cache turns every navigation into a memory leak.
- A global `paste` listener on `document` will hijack pastes into the page's other inputs; scope it (`paste@document` plus a check that the drop zone or its input has focus) if the page has a text editor.
- Setting `input.files` does **not** fire `change` — dispatch it yourself, or Active Storage never sees the files.
- Don't rely on client-side MIME filtering for security. Validate content type and size server-side (`validates :attachments, content_type: [...]` via `active_storage_validations`).

**Prior art.**
- https://github.com/dropzone/dropzone — `6.0.0-beta.2`, **2021-11-29**. Effectively abandoned; do not start here in 2026.
- https://uppy.io/ — `@uppy/core` `5.2.0` (2025-12-02). The real library answer when you need resumable/chunked, remote sources (Drive/Dropbox), or an image editor.
- https://shrinerb.com/docs/getting-started — Shrine's documented Uppy integration.
- https://github.com/igorkasyanchuk/active_storage_validations — server-side content-type/size validation.
- https://www.stimulus-components.com/ — confirmed: **no** dropzone component.

---

### Image cropping

**Hotwire answer.** Wrap [Cropper.js](https://github.com/fengyuanchen/cropperjs) in a Stimulus `cropper` controller, and **store the crop coordinates in hidden fields; let the server crop with `image_processing`/libvips.** Do not upload a cropped blob from the browser. Server-side cropping keeps the original (so the crop is re-editable), avoids re-encoding artifacts and EXIF loss, and means the crop is reproducible for every variant.

**Code.**

```erb
<%= form_with model: @user do |form| %>
  <div data-controller="cropper" data-cropper-aspect-ratio-value="1">
    <img src="<%= url_for(@user.avatar) %>" data-cropper-target="image" alt="Avatar to crop">
    <% %i[x y width height].each do |k| %>
      <%= form.hidden_field :"crop_#{k}", data: { cropper_target: k.to_s } %>
    <% end %>
  </div>
  <%= form.submit "Save crop" %>
<% end %>
```

```js
// app/javascript/controllers/cropper_controller.js
import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"                 // v2.x — web components under the hood

export default class extends Controller {
  static targets = ["image", "x", "y", "width", "height"]
  static values  = { aspectRatio: Number }

  connect() {
    this.cropper = new Cropper(this.imageTarget)
    this.selection = this.cropper.getCropperSelection()
    if (this.aspectRatioValue) this.selection.aspectRatio = this.aspectRatioValue
    this.onChange = () => this.#sync()
    this.selection.addEventListener("change", this.onChange)
    this.#sync()
  }

  disconnect() {                                 // teardown — the #1 wrapped-lib bug
    this.selection?.removeEventListener("change", this.onChange)
    this.cropper?.destroy()
    this.cropper = this.selection = null
  }

  #sync() {
    const { x, y, width, height } = this.selection
    this.xTarget.value = Math.round(x)
    this.yTarget.value = Math.round(y)
    this.widthTarget.value = Math.round(width)
    this.heightTarget.value = Math.round(height)
  }
}
```

```ruby
# app/models/user.rb — crop server-side, at variant time
class User < ApplicationRecord
  has_one_attached :avatar

  def cropped_avatar
    return avatar.variant(resize_to_limit: [400, 400]) unless crop_width.to_i.positive?

    avatar.variant(
      crop: [crop_x, crop_y, crop_width, crop_height],   # left, top, width, height
      resize_to_fill: [400, 400]
    )
  end
end
```

`crop` maps straight onto `ImageProcessing::Vips#crop(left, top, width, height)` ([vips docs](https://github.com/janko/image_processing/blob/master/doc/vips.md#crop)) and is on Rails' `ActiveStorage.supported_image_processing_methods` allowlist. `image_processing` `2.0.3` (2026-08-06); Rails 8 defaults to `config.active_storage.variant_processor = :vips`.

**Cropper.js version note.** npm `cropperjs` latest is **`2.1.1` (2026-04-06)** — v2 is a **full rewrite into web components** (`<cropper-canvas>`, `<cropper-image>`, `<cropper-selection>`, `<cropper-shade>`, `<cropper-handle>`). The `Cropper` class survives as a convenience shell: `new Cropper(imgEl, options)` → `getCropperSelection()` / `getCropperImage()` / `destroy()`, and the selection element exposes plain `x/y/width/height/aspectRatio` properties plus `$toCanvas()`. The v1 API (`getCroppedCanvas()`, `getData()`, `viewMode:`) is **gone**; v1 lives on the `v1` branch. Use v2 for new code — and disregard any tutorial calling `getCroppedCanvas()`.

**When client-side cropping is right.** Only when you must not ship the original to the server (privacy) or you're cropping before the file exists server-side. Then: `selection.$toCanvas()` → `canvas.toBlob()` → `new DirectUpload(new File([blob], "avatar.jpg", { type: "image/jpeg" }), url)`.

**Decomposition.** `cropper` + `direct-upload` (client-side variant only) + `dialog` (cropping usually lives in a modal).

**A11y.** Cropper.js v2 handles are keyboard-operable (arrow keys move/resize the active `<cropper-selection>` via its document keydown handler), but **always provide numeric fallbacks**: expose the four hidden fields as visible, labelled number inputs behind a disclosure, so the crop is settable without a pointer. Give the image a real `alt`. Announce the current selection into an `aria-live="polite"` region if you want parity.

**Native.** Cropping in a web view is a poor experience. On Hotwire Native, prefer the platform crop UI (`UIImagePickerController` `allowsEditing` / Android's `Intent.ACTION_CROP` or a native library) behind a bridge component, and post back the crop rect or the cropped blob (`04-hotwire-native.md` §3.5).

**Pitfalls.**
- Crop coordinates are in **natural image pixels**, not displayed CSS pixels. Cropper v2's selection is already in image space; if you compute anything yourself, scale by `naturalWidth / clientWidth`.
- EXIF orientation: crop coordinates taken from a browser-rendered (auto-oriented) image will be wrong against a raw file. Normalize server-side with `auto_orient` first, or store the orientation.
- Not calling `destroy()` in `disconnect()` leaves document-level keydown listeners bound; after a few Turbo visits, arrow keys start moving invisible crop boxes.
- Under morphing, mark the cropper container `data-turbo-permanent` or idiomorph prunes the generated shadow DOM (`02-turbo-deep-dive` §5.8 gotcha 2).
- Persist `crop_x/y/width/height` on the record, not in the session — so a re-edit reopens where the user left off.

**Prior art.**
- https://github.com/fengyuanchen/cropperjs (`2.1.1`)
- https://github.com/janko/image_processing — `crop`, `resize_to_fill`, `resize_to_limit`
- https://guides.rubyonrails.org/active_storage_overview.html#transforming-images

---

### Rich text (Trix / Action Text)

**Hotwire answer.** Action Text is the built-in and it is genuinely good. In Rails 8, the helper is **`rich_textarea`** (`f.rich_textarea :content`); `rich_text_area` still works as an alias. In 2026 the interesting change is the editor underneath: **[Lexxy](https://github.com/basecamp/lexxy)** (37signals, Lexical-based, gem `0.9.29` / npm `@37signals/lexxy` `0.9.29`, 2026-08-07) drops into Action Text and takes over `rich_textarea` automatically. **Ship Lexxy for new apps; keep Trix for existing ones.** Only reach for TipTap/ProseMirror/Lexical directly when you need collaborative editing or a schema Action Text can't store.

**Code — Action Text, the Rails 8 way.**

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  has_rich_text :body
end
```

```erb
<%= form_with model: @post do |form| %>
  <%= form.label :body %>
  <%= form.rich_textarea :body, class: "trix-content",
        placeholder: "Write something…" %>
  <%= form.submit %>
<% end %>

<%# rendering %>
<div class="trix-content"><%= @post.body %></div>
```

```ruby
# controller
params.require(:post).permit(:title, :body)          # body is a plain string of HTML
```

`rich_textarea` renders a hidden input plus a `<trix-editor>` and injects `data-direct-upload-url` (`rails_direct_uploads_url`) and `data-blob-url-template` (`rails_service_blob_url(":signed_id", ":filename")`) — verified in `actiontext/app/helpers/action_text/tag_helper.rb`. Attachment upload is wired for free: `@rails/actiontext` listens for `trix-attachment-add`, runs a `DirectUpload`, feeds `direct-upload:progress` into `attachment.setUploadProgress()`, and finally `attachment.setAttributes({ sgid, url })` (`actiontext/app/javascript/actiontext/index.js`).

**Code — Lexxy.**

```ruby
# Gemfile
gem "lexxy"
```

```ruby
# config/importmap.rb
pin "lexxy", to: "lexxy.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
```

```js
// app/javascript/application.js
import * as Lexxy from "lexxy"
Lexxy.configure({                     // MUST be called synchronously after the import
  default: { headings: ["h2", "h3"], toolbar: { upload: "both" } },
  simple:  { richText: false, multiLine: false },
  global:  { attachmentTagName: "action-text-attachment" }
})
```

The same `form.rich_textarea :body` now renders `<lexxy-editor>`. On **Rails 8.2+** Lexxy registers as a first-class Action Text editor adapter (`config.action_text.editor = :lexxy`); on **Rails 8.0/8.1** the gem overrides the Action Text helpers, and `config.lexxy.override_action_text_defaults = false` plus `form.lexxy_rich_text_area` lets you mix Trix and Lexxy during a migration ([Lexxy install docs](https://lexxy.dev/docs/)). Rails 8.2 (currently `8.2.0.alpha` on `main`) introduces `ActionText::Editor` with `as_canonical`/`as_editable` fragment converters — that is the extension point for any third-party editor.

**Code — customizing the Trix toolbar from Stimulus.**

```js
// app/javascript/controllers/trix_toolbar_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // data-action="trix-initialize->trix-toolbar#addButton" on the <trix-editor>
  addButton({ target }) {
    const groups = target.toolbarElement.querySelector(".trix-button-group--block-tools")
    groups.insertAdjacentHTML("beforeend", `
      <button type="button" class="trix-button" data-trix-attribute="highlight"
              title="Highlight" tabindex="-1">HL</button>`)
  }
}
```

```js
// app/javascript/application.js — register the attribute BEFORE any editor connects
import Trix from "trix"
addEventListener("trix-before-initialize", () => {
  Trix.config.textAttributes.highlight = { tagName: "mark", inheritable: true }
})
```

`trix-before-initialize` is the only safe place to mutate `Trix.config`; `trix-initialize` is where `editor` and `toolbarElement` exist. You can also replace the whole toolbar by overriding `Trix.config.toolbar.getDefaultHTML()`, or render `<trix-toolbar id="my_toolbar">` yourself and point at it with `<trix-editor toolbar="my_toolbar">` ([Trix README](https://github.com/basecamp/trix#creating-a-toolbar)). Buttons wire up declaratively via `data-trix-attribute` / `data-trix-action` / `data-trix-key`.

**Attachment control.** `trix-file-accept` fires before `trix-attachment-add`; `preventDefault()` it to reject a drop/paste. Lexxy's equivalent is `lexxy:file-accept` (`event.detail.file`, `preventDefault()`), plus `lexxy:upload-start` / `lexxy:upload-progress` (`detail.progress`, 0–100) / `lexxy:upload-end` (`detail.error`), and the `permitted-attachment-types` attribute.

**Sanitization.** Action Text sanitizes on **render**, not on save; the raw HTML is stored. Tune it globally:

```ruby
# config/initializers/action_text.rb
ActionText::ContentHelper.allowed_tags =
  ActionText::ContentHelper.sanitizer.class.allowed_tags +
    ["action-text-attachment", "figure", "figcaption", "mark"]
ActionText::ContentHelper.allowed_attributes =
  ActionText::ContentHelper.sanitizer.class.allowed_attributes +
    ActionText::Attachment::ATTRIBUTES
```

Defaults live in `actiontext/app/helpers/action_text/content_helper.rb` (`sanitizer_allowed_tags` = the safe-list sanitizer's tags + `action-text-attachment`, `figure`, `figcaption`). `config.action_text.sanitizer_vendor` selects HTML4 vs HTML5 sanitization.

**Turbo interaction — get this right.**
- **Morphing.** Trix used to break badly under morph: the server renders `<trix-editor>` with no `innerHTML` and no `[contenteditable]`, so idiomorph wiped both ([turbo-rails#533](https://github.com/hotwired/turbo-rails/issues/533), Sean Doyle's analysis). **This is fixed upstream** — [basecamp/trix#1227 "Make Trix compatible with morphing"](https://github.com/basecamp/trix/pull/1227) merged 2025-03-10 and shipped in **Trix 2.1.13**; it flags the editor as initialized with an attribute and detects when that attribute is modified. On Trix ≥ 2.1.13 you should not need the old `turbo:before-morph-attribute` `preventDefault()` hacks. If you are pinned below that, the minimal workaround is still:

```js
addEventListener("turbo:before-morph-attribute", (event) => {
  const tag = event.target.tagName
  if (tag === "TRIX-EDITOR" || tag === "TRIX-TOOLBAR") event.preventDefault()
})
```

- **The cache double-initialize.** Trix's `connectedCallback` guards on `this.editorController` and a `[connected]` attribute (`src/trix/elements/trix_editor_element.js`), but a Turbo **snapshot restore** replays a *cloned* DOM that already contains Trix's auto-generated `<trix-toolbar>` and hidden input while `editorController` is undefined — so you get a duplicated toolbar and stale content. Fixes, in order of preference: (1) explicitly render your own `<trix-toolbar id="…">` and reference it with `toolbar=`, which removes the auto-generated element entirely; (2) `data-turbo-permanent` on a wrapping `[id]` element so the live node is transplanted (`02-turbo-deep-dive` §2.7); (3) as a blunt last resort, `<meta name="turbo-cache-control" content="no-cache">` on the page (**not** `data-turbo-cache="false"` — that element attribute was removed in Turbo 8.0.21; see the errata). Do **not** reach for `Turbo.clearCache()` — that API is gone; it is `Turbo.cache.clear()` now.
- `data-turbo-permanent` behaves differently under morph vs. replace — see `02-turbo-deep-dive` §5.8 gotcha 7.

**Trix vs. Lexxy vs. markdown vs. TipTap — the honest table.**

| | Use it when | Limits |
|---|---|---|
| **Trix** | Existing app, comments, simple articles | **No tables.** Block types limited to h1, blockquote, code, bullet/number lists, and nesting. No inline images side-by-side with text. No mentions without custom work. Attachment styling is fixed. |
| **Lexxy** | New Rails app, anything Basecamp-shaped | Pre-1.0 (`0.9.x`). Real `<p>` tags, markdown shortcuts + paste conversion, syntax-highlighted code, configurable prompts/mentions, PDF/video previews, and it writes the same canonical Action Text attachment HTML. |
| **Markdown** (`redcarpet`/`commonmarker` + a plain `<textarea>`) | Developer-facing content, docs, anything version-controlled or diffable | No WYSIWYG. Attachments need their own flow. But: trivially sanitizable, portable, and the textarea is the most accessible editor there is. |
| **TipTap / ProseMirror / Lexical direct** | Collaborative editing (Y.js), custom schema, tables + complex nodes | You now own the whole editor: toolbar, a11y, attachment upload, sanitization, and the HTML↔storage contract. On Rails 8.2 you can at least register it as an `ActionText::Editor` adapter. |

**Decomposition.** Almost none — the editor is a custom element, not a Stimulus widget. `direct-upload` (built into Action Text) + `dirty-form` (unsaved-changes guard) + a thin app-specific controller for toolbar extensions and `trix-*`/`lexxy:*` event handling.

**A11y.** `<trix-editor>` integrates with `<label for>` (and supports `aria-label`/`aria-labelledby`); it sets `role="textbox"` and `aria-multiline` itself. **Render the `<trix-toolbar>` outside the `<label>`** if you nest the editor in a label — the Trix README flags this explicitly. Toolbar buttons carry `tabindex="-1"` and are reached with the documented `data-trix-key` shortcuts (Cmd/Ctrl+B etc.); if you add buttons, keep that convention and give them `title` + accessible names. Contenteditable editors remain the weakest a11y surface on any web page — for developer-facing content, a plain `<textarea>` with markdown genuinely serves screen-reader users better.

**Native.** In a web view, the Trix/Lexxy toolbar sits above the software keyboard and fights the input accessory view. For a serious composer screen, make it a bridge component that renders a native toolbar tied to the keyboard, or go fully native for that one screen via path configuration (`04-hotwire-native.md` §2.7, §7). Attachment upload from the editor uses Active Storage direct upload, so the camera/photo picker works out of the box.

**Pitfalls.**
- `rich_text_area` is a deprecated *name*, not a deprecated feature — but write `rich_textarea` in new Rails 8 code (renamed in Rails 8.0, `actiontext/CHANGELOG.md`; system-test helper is `fill_in_rich_textarea`).
- `has_rich_text :body` creates an `ActionText::RichText` record, so `Post.body` is **not** a column. `includes(:rich_text_body)` or you N+1 every index page.
- Sanitization happens on render. If you dump `post.body.to_s` into a non-Action-Text context you are dumping raw stored HTML.
- Trix content is stored with `<figure data-trix-attachment=…>`; Action Text converts it to canonical `<action-text-attachment>` on save via `ActionText::Editor::TrixEditor#as_canonical`. Do not hand-edit stored HTML.
- Deleting a record does not purge its attachment blobs unless the association is set up to; `has_rich_text` handles `embeds`, but audit it.
- Lexxy is `0.9.x`. Pin an exact version and read its CHANGELOG before upgrading.
- Two editors sharing an `id` (a common `<turbo-frame>` mistake) break idiomorph — `02-turbo-deep-dive` §5.8 gotcha 4.

**Prior art.**
- https://guides.rubyonrails.org/action_text_overview.html
- https://github.com/basecamp/trix (`2.1.19`, 2026-05-09)
- https://github.com/basecamp/lexxy · https://lexxy.dev/docs/ (`0.9.29`)
- https://github.com/rails/rails/tree/main/actiontext/lib/action_text/editor — the 8.2 adapter API
- https://tiptap.dev/ · https://lexical.dev/

---

### Date & time pickers

**Hotwire answer.** **No JS needed** for the overwhelmingly common cases: `<input type="date">`, `<input type="time">`, and `<input type="datetime-local">` are genuinely good in 2026 and give you the native mobile wheel picker for free. Use `f.date_field` / `f.time_field` / `f.datetime_field` and move on. Add JS only for the three things natives cannot do: **date ranges**, **arbitrary disabled dates**, and **timezone-aware display**. For those, wrap **[Cally](https://wicky.nillia.ms/cally/)** (web components, <9 KB gzip, actively maintained) — *not* flatpickr.

**Code — the default: no JS.**

```erb
<%= form_with model: @event do |form| %>
  <%= form.label :starts_on %>
  <%= form.date_field :starts_on, min: Date.current, required: true %>

  <%= form.label :starts_at %>
  <%= form.datetime_field :starts_at, include_seconds: false,
        min: 1.hour.from_now, max: 1.year.from_now %>

  <%= form.label :doors_at %>
  <%= form.time_field :doors_at, include_seconds: false, step: 15.minutes %>
<% end %>
```

Rails formats these correctly out of the box: `DateField` → `%Y-%m-%d`, `TimeField` → `%H:%M` with `include_seconds: false`, `DatetimeLocalField` → `%Y-%m-%dT%H:%M` with `include_seconds: false` (default is `%Y-%m-%dT%T`) — see `actionview/lib/action_view/helpers/tags/{date,time,datetime_local}_field.rb`. `min:`/`max:` accept `Date`/`Time` objects and are formatted for you.

Two CSS/JS niceties that need no library:

```css
/* the only pseudo-element that is broadly settable on a date input */
input[type="date"]::-webkit-calendar-picker-indicator { cursor: pointer; opacity: 1; }
```

```js
// open the native picker from anywhere in the field — Chrome 99+, FF 101+, Safari 16+
this.inputTarget.showPicker()
```

**Where native genuinely fails (verified against MDN browser-compat-data, pulled 2026-08-15).**

| | Chrome | Firefox | Safari |
|---|---|---|---|
| `type="date"` | 20 | 57 | 14.1 |
| `type="time"` | 20 | 57 | 14.1 |
| `type="datetime-local"` | 20 | 93 | 14.1 |
| `type="month"` | 20 | **no** | **no** |
| `type="week"` | 20 | **no** | **no** |
| `HTMLInputElement.showPicker()` | 99 | 101 | 16 |

- **`month` and `week` are unusable.** Desktop Firefox and desktop Safari render a bare text box. Use two selects or a `date` field.
- **No date range.** One input = one date. Two coupled `date` inputs with `min`/`max` wired by a tiny `sync` controller covers 80 % of range needs; a real range calendar needs a component.
- **No timezone.** `datetime-local` has no zone concept at all — the browser reads and writes the *device's* wall clock with no offset in the string.
- **No arbitrary disabled dates.** Only contiguous `min`/`max`. There is no `disabled-dates` attribute.
- **Styling is still not customizable.** `::picker-icon` (Chrome 133+, Safari 27, **Firefox: not supported**) and `::picker()` (Chrome 135+) plus `appearance: base-select` (Chrome 135, Firefox 149 *behind prefs*, Safari 27) are the [customizable-`<select>`](https://open-ui.org/components/customizable-select.explainer/) work — they apply to `<select>`, **not** to date inputs. The [Open UI datepicker research page](https://open-ui.org/components/datepicker.research) has been parked in pre-proposal since March 2023. Do not wait for it.

**Code — date range with Cally, wrapped correctly.**

```erb
<div data-controller="date-picker">
  <label for="range_display">Stay</label>
  <input id="range_display" readonly data-date-picker-target="display"
         popovertarget="range_popover" aria-describedby="range_hint">
  <p id="range_hint">Select a check-in and check-out date.</p>

  <div id="range_popover" popover data-date-picker-target="popover">
    <calendar-range months="2" data-date-picker-target="calendar"
                    min="<%= Date.current.iso8601 %>"
                    value="<%= "#{@stay.starts_on&.iso8601}/#{@stay.ends_on&.iso8601}" %>">
      <svg slot="previous" aria-label="Previous month">…</svg>
      <svg slot="next" aria-label="Next month">…</svg>
      <calendar-month></calendar-month>
      <calendar-month offset="1"></calendar-month>
    </calendar-range>
  </div>

  <%= hidden_field_tag "stay[starts_on]", @stay.starts_on, data: { date_picker_target: "start" } %>
  <%= hidden_field_tag "stay[ends_on]",   @stay.ends_on,   data: { date_picker_target: "end" } %>
</div>
```

```js
// app/javascript/controllers/date_picker_controller.js
import { Controller } from "@hotwired/stimulus"
import "cally"

export default class extends Controller {
  static targets = ["calendar", "display", "start", "end", "popover"]

  connect() {
    this.onChange = (event) => this.#sync(event.target.value)
    this.calendarTarget.addEventListener("change", this.onChange)
    this.#sync(this.calendarTarget.value)
  }

  disconnect() {                                    // the leak that bites everyone
    this.calendarTarget?.removeEventListener("change", this.onChange)
    this.onChange = null
  }

  #sync(value) {
    const [start, end] = String(value || "").split("/")
    this.startTarget.value = start || ""
    this.endTarget.value   = end || ""
    this.displayTarget.value = start && end ? `${start} → ${end}` : ""
    this.popoverTarget.hidePopover?.()
  }
}
```

Cally: npm `cally` `0.9.2` (2026-02-05), repo pushed 2026-07-10, <9 KB min+gzip. Components: `<calendar-date>`, `<calendar-range>`, `<calendar-multi>`, `<calendar-month>`. Props include `value`, `min`, `max`, `months`, `locale`, `firstDayOfWeek`, `isDateDisallowed` (a function — this is your "disabled dates"), `showOutsideDays`, `showWeekNumbers`; it fires `change`. Same author as Duet Date Picker, which is now archived.

**Library maintenance reality check (checked 2026-08-15).**

| Library | Latest release | Verdict |
|---|---|---|
| `flatpickr` | `4.6.13`, **2022-04-14**; last commit 2022-09-27; 855 open issues | Coasting. Do not start here. |
| `stimulus-flatpickr` | `1.4.0`, **2020-11-24**; repo last pushed 2023-10-01 | **Unmaintained.** Do not use. |
| `@duetds/date-picker` | `1.4.0`, 2021-06-18 | **Repo archived.** |
| `@easepick/bundle` | `1.2.1`, 2023-02-22 | **Repo archived.** |
| `air-datepicker` | `3.6.0`, 2025-05-18 | Alive; solid classic option. |
| `vanilla-calendar-pro` | `3.2.0`, **2026-08-12** | Very actively maintained; heavier (~325 KB unpacked). |
| `cally` | `0.9.2`, 2026-02-05 | **Recommended.** |

**Rails-side `Time.zone` gotchas.**
- `datetime-local` submits a **naive** string (`"2026-08-15T14:30"`) with no offset. With `time_zone_aware_attributes` on (the default), Rails parses it in **`Time.zone`** — which is `config.time_zone` (default `"UTC"`), *not* the user's zone. Ship a user zone and wrap requests: `around_action { |_, action| Time.use_zone(Current.user&.time_zone || "UTC", &action) }`.
- Render values back through the same zone or the field shows a different time than the user entered: `form.datetime_field :starts_at, value: @event.starts_at&.in_time_zone(Current.user.time_zone)&.strftime("%Y-%m-%dT%H:%M")`.
- There is a real, still-cited Rails bug where a naive datetime string picked up the **server OS's** offset instead of `config.time_zone` ([discuss.rubyonrails.org/t/time-zone-bug-for-datetime-attributes/73864](https://discuss.rubyonrails.org/t/time-zone-bug-for-datetime-attributes/73864), traced to `ActiveModel::Type::Helpers::TimeValue` defaulting to `:local`). Set `config.time_zone` **and** `config.active_record.default_timezone = :utc`, and never rely on the box's `TZ`.
- Pure dates (`type="date"` → a `date` column) have no zone problem. Prefer them when you mean "a day".
- For *display*, don't fight this at all: render UTC `<time datetime="…Z">` and convert client-side — see the `relative-time` primitive and [basecamp/local_time](https://github.com/basecamp/local_time).

**Decomposition.** Usually nothing. For the enhanced case: `date-picker` (lib/web-component wrapper) + `popover` (prefer the native Popover API) + `sync` (mirror the widget value into hidden/native inputs) + `dismiss`.

**A11y.** Native inputs are the accessible answer — screen readers announce them as spin-button segments, and mobile gets the platform picker. The [APG "Date Picker Dialog" example](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/examples/datepicker-dialog/) is the reference for a custom picker: the text input keeps focus and ownership of the value, the calendar is a `role="dialog"` with `role="grid"` inside, arrow keys move the day cell, PageUp/PageDown change month, Shift+PageUp/PageDown change year, Esc closes and returns focus. Cally implements keyboard + screen-reader support already — which is the main reason to pick it over hand-rolling. Never build a "date picker" out of divs with click handlers and no input.

**Native.** This is the strongest "no JS needed" argument in the whole catalog: in WKWebView and Android WebView, `<input type="date">` and `type="datetime-local"` open the **platform** picker (iOS wheel/inline calendar, Android Material dialog). A JS calendar in a web view immediately reads as "this is a website". Keep native inputs in the Hotwire Native variant even if you use Cally on desktop — gate with `hotwire_native_app?` (`04-hotwire-native.md` §4.1).

**Pitfalls.**
- Don't set `value:` on a `datetime_field` from a `String` — `DatetimeField#datetime_value` passes strings through unformatted, so a bad format silently blanks the field.
- `step` on `time`/`datetime-local` is in **seconds** (`step: 900` = 15 min); Rails accepts `15.minutes` because that's `900`.
- Safari before 14.1 has no date picker; it's a text box. Still add `pattern`/`inputmode` if you support very old iOS.
- Wrapped pickers that append a calendar to `<body>` leak on Turbo navigation unless `disconnect()` destroys them, and get pruned by idiomorph unless the container is `data-turbo-permanent`.
- `required` + `type="date"` gives you free client-side validation; don't reimplement it.

**Prior art.**
- https://wicky.nillia.ms/cally/ · https://github.com/WickyNilliams/cally
- https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/datetime-local
- https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/examples/datepicker-dialog/
- https://github.com/t1m0n/air-datepicker · https://vanilla-calendar.pro/
- https://railsdesigner.com/ — ships a date picker component
- SUPERSEDED: `stimulus-flatpickr`, flatpickr, Duet Date Picker, Easepick, jQuery UI datepicker, `date_select` dropdowns

---

### Range / slider

**Hotwire answer.** **No JS needed.** `<input type="range">` + `<output>` wired with the `sync` primitive — and even `sync` is optional, because a two-line inline handler or a tiny controller is all it takes. Dual-thumb ranges have **no native answer**; wrap [noUiSlider](https://refreshless.com/nouislider/) and accept the cost.

**Code.**

```erb
<div data-controller="sync">
  <%= form.label :budget, "Budget: " %>
  <%= form.range_field :budget, in: 0..1000, step: 50,
        list: "budget_ticks",
        data: { sync_target: "source", action: "input->sync#update" } %>
  <output for="post_budget" data-sync-target="output"><%= @post.budget %></output>

  <datalist id="budget_ticks">
    <option value="0" label="$0"><option value="500"><option value="1000" label="$1k">
  </datalist>
</div>
```

```js
// app/javascript/controllers/sync_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["source", "output"]
  connect() { this.update() }
  update()  { this.outputTargets.forEach(o => o.textContent = this.sourceTarget.value) }
}
```

Thumb styling needs **both** vendor pseudo-elements — there is no standard one:

```css
input[type="range"]::-webkit-slider-thumb { -webkit-appearance: none; width: 1.5rem; height: 1.5rem; border-radius: 50%; background: canvastext; }
input[type="range"]::-moz-range-thumb     { width: 1.5rem; height: 1.5rem; border: 0; border-radius: 50%; background: canvastext; }
```

`::-webkit-slider-thumb`: Chrome 32+, Safari 18+, **Firefox no**. `::-moz-range-thumb`: Firefox 21+, others no. `<datalist>` tick marks on a range: Chrome ≤67, Firefox 109, Safari 12.1. Datalist **labels** on ticks: Chrome 38, Firefox 77, **Safari no**. Vertical orientation (`writing-mode`): Chrome 124, Firefox 120, Safari 16.5.

**Dual-thumb.** noUiSlider `15.8.1` (2024-06-21) is the pragmatic choice — but it renders divs, so you must add `role="slider"`, `aria-valuenow/min/max/text`, and keyboard handlers yourself (it ships `ariaFormat`/`keyboardSupport` options; turn them on). The standards answer is the Open UI [Enhanced Range Input explainer](https://open-ui.org/components/enhanced-range-input.explainer/) — an Active Proposal (created 2025-03-10, updated 2026-06-04) for a `<rangegroup>` wrapper element containing multiple `<input type="range">`. **Nothing has shipped in any browser.** Two coupled single ranges with `min`/`max` clamped against each other by a `sync` controller is the accessible, dependency-free fallback and is usually good enough.

**Decomposition.** `sync` (range → `<output>`), plus `autosubmit` if the slider filters a `<turbo-frame>` list.

**A11y.** `<input type="range">` is already `role="slider"` with full arrow/Home/End/PageUp/PageDown support — do not reimplement it. Give it a `<label>`; `<output for="…">` is `role="status"` so the value change is announced politely. Add `aria-valuetext` when the raw number isn't meaningful ("$500", "Medium"). APG: https://www.w3.org/WAI/ARIA/apg/patterns/slider/ and https://www.w3.org/WAI/ARIA/apg/patterns/slider-multithumb/.

**Native.** Native input renders the platform slider in a web view; leave it alone. If the slider drives an expensive query, debounce and only `autosubmit` on `change` (pointer release), not `input`.

**Pitfalls.**
- Listen to `input` for live display, `change` for submission — `input` fires on every pixel of drag.
- A range with no visible value output is unusable; always pair with `<output>`.
- `-webkit-appearance: none` on the thumb is required before any `::-webkit-slider-thumb` sizing takes effect.
- Range inputs always submit a value (the midpoint if untouched) — there is no "empty" state. Add an explicit "any" checkbox if that matters.

**Prior art.** https://refreshless.com/nouislider/ · https://open-ui.org/components/enhanced-range-input.explainer/ · https://www.w3.org/WAI/ARIA/apg/patterns/slider-multithumb/

---

### Masked inputs

**Hotwire answer.** Prefer **no mask at all**: `inputmode` + `pattern` + `autocomplete` for the browser, and normalization in an ActiveRecord `before_validation` on the server. When you do need one (phone numbers, currency in a finance UI), wrap [IMask](https://imask.js.org/) in the `input-mask` primitive and **submit the unmasked value from a hidden field**.

**Code — the preferred, no-JS version.**

```erb
<%= form.telephone_field :phone,
      inputmode: "tel", autocomplete: "tel",
      placeholder: "+1 555 123 4567" %>
<%= form.text_field :postal_code, inputmode: "numeric", pattern: "[0-9]{5}(-[0-9]{4})?",
      autocomplete: "postal-code" %>
```

```ruby
class Contact < ApplicationRecord
  before_validation { self.phone = phone.to_s.gsub(/\D/, "").presence }
  validates :phone, format: { with: /\A\d{10,15}\z/ }, allow_nil: true
end
```

**Code — `input-mask` when you really need it.**

```erb
<div data-controller="input-mask" data-input-mask-mask-value="+{1} (000) 000-0000">
  <%= form.label :phone %>
  <input type="tel" inputmode="tel" autocomplete="tel"
         value="<%= @contact.phone %>"
         data-input-mask-target="visible">
  <%# THE server-facing value — the masked input is display-only %>
  <%= form.hidden_field :phone, data: { input_mask_target: "value" } %>
</div>
```

```js
// app/javascript/controllers/input_mask_controller.js
import { Controller } from "@hotwired/stimulus"
import IMask from "imask"

export default class extends Controller {
  static targets = ["visible", "value"]
  static values  = { mask: String, lazy: { type: Boolean, default: true } }

  connect() {
    this.mask = IMask(this.visibleTarget, { mask: this.maskValue, lazy: this.lazyValue })
    this.onAccept = () => { this.valueTarget.value = this.mask.unmaskedValue }
    this.mask.on("accept", this.onAccept)
    this.onAccept()
  }

  disconnect() {
    this.mask?.off("accept", this.onAccept)
    this.mask?.destroy()          // unbinds view events and drops the element reference
    this.mask = null
  }
}
```

API verified against `imask@7.6.1/esm/controls/input.d.ts`: `IMask(el, opts)` → `InputMask` with `value` (masked), `unmaskedValue`, `typedValue`, `displayValue`, `on(ev, fn)` / `off(ev, fn)` (`"accept"`, `"complete"`), `updateOptions(opts)`, and `destroy()`. IMask `7.6.1`, published 2024-05-21 — stable but slow-moving.

**The "mask breaks the server value" problem.** If you mask the input the form actually submits, Rails receives `"+1 (555) 123-4567"`. You then either strip it server-side (fine — but now the mask was decoration) or you get dirty data. Two clean resolutions, in order:
1. **Don't mask the submitted field.** Mask a display-only input and mirror `mask.unmaskedValue` into a hidden field (above). The form's contract stays "digits".
2. **Mask the real field and normalize server-side anyway.** Simpler markup, but you must write the `before_validation` regardless — so you may as well skip the mask.

Either way, **always normalize on the server**. A mask is a UX affordance, never a validation.

**Library status.** `cleave.js` `1.6.0` (2020-05-19) — dead; the author's successor `cleave-zen` is at `0.0.17` (2023-12-16) and also stalled. `maska` `3.2.0` (2025-07-02) is the lighter, actively-maintained alternative if IMask is too big. **Do not use Cleave.js in new code.**

**Decomposition.** `input-mask` + `sync` (masked display → hidden canonical value).

**A11y.** Set `inputmode` so mobile gets the right keypad. Put the expected format in a `<p id="…">` referenced by `aria-describedby` — **not** only in `placeholder` (placeholders vanish on focus and are invisible to some AT). Masks that move the caret unpredictably are hostile to screen-reader users; prefer `lazy: true` (placeholder chars appear only as you type). Never mask a password or a one-time code — use `autocomplete="one-time-code"` and let the platform autofill.

**Native.** `inputmode` drives the software keyboard identically in a web view; that's most of the value. Nothing bridge-worthy here.

**Pitfalls.**
- Masking a field that autofill wants to populate breaks autofill: the browser writes the raw value, IMask reformats, and the change event ordering can lose data. Always set the correct `autocomplete` token and re-sync on `change`.
- Not calling `destroy()` in `disconnect()` leaves listeners bound to a detached element on every Turbo visit.
- Under morphing, the server re-renders the *unmasked* value into `value=""`, and idiomorph will overwrite what the user sees. Guard with `data-turbo-permanent` on the visible input (`02-turbo-deep-dive` §5.8 gotcha 1).
- Currency masks and `Float` are a trap. Store cents as an integer and mask the display.

**Prior art.** https://imask.js.org/ (`7.6.1`) · https://github.com/beholdr/maska (`3.2.0`) · SUPERSEDED: https://github.com/nosir/cleave.js (`1.6.0`, 2020), jquery.maskedinput

---

### Password strength

**Hotwire answer.** A thin Stimulus controller around **`@zxcvbn-ts/core`** (`4.2.0`, 2026-08-12) with lazily-imported language packs, writing into a `<meter>` plus an `aria-live="polite"` region. The meter is **advice, not a gate** — enforcement belongs on the server, via a breached-password check (`pwned` / `devise-pwned_password`) and a length minimum. The original `dropbox/zxcvbn` is at `4.4.2` from **2017-02-07**; use the TypeScript fork.

**Code.**

```erb
<div data-controller="password-strength">
  <%= f.label :password %>
  <%= f.password_field :password, autocomplete: "new-password", minlength: 12,
        aria: { describedby: "pw_feedback" },
        data: { password_strength_target: "input", action: "input->password-strength#score" } %>

  <meter min="0" max="4" low="2" high="3" optimum="4" value="0"
         data-password-strength-target="meter" aria-hidden="true"></meter>
  <p id="pw_feedback" role="status" aria-live="polite"
     data-password-strength-target="feedback"></p>
</div>
```

```js
// app/javascript/controllers/password_strength_controller.js
import { Controller } from "@hotwired/stimulus"
import { useDebounce } from "stimulus-use"

const LABELS = ["Very weak", "Weak", "Fair", "Strong", "Very strong"]

export default class extends Controller {
  static targets = ["input", "meter", "feedback"]
  static debounces = [{ name: "score", wait: 250 }]   // debounced via stimulus-use

  connect() { useDebounce(this) }

  async score() {
    const zxcvbn = await this.#estimator()
    const { score, feedback } = zxcvbn.check(this.inputTarget.value)
    this.meterTarget.value = score
    this.feedbackTarget.textContent =
      [LABELS[score], feedback.warning, ...feedback.suggestions].filter(Boolean).join(". ")
  }

  async #estimator() {                                 // ~800 KB of dictionaries: load once, lazily
    this.estimator ||= (async () => {
      const [{ ZxcvbnFactory }, common, en] = await Promise.all([
        import("@zxcvbn-ts/core"),
        import("@zxcvbn-ts/language-common"),
        import("@zxcvbn-ts/language-en")
      ])
      return new ZxcvbnFactory({
        dictionary: { ...common.dictionary, ...en.dictionary },
        graphs: common.adjacencyGraphs,
        translations: en.translations
      })
    })()
    return this.estimator
  }

  disconnect() { this.estimator = null }
}
```

The v4 API is `new ZxcvbnFactory(options).check(password)` ([zxcvbn-ts README](https://github.com/zxcvbn-ts/zxcvbn/tree/master/packages/libraries/main)); older tutorials showing a bare `zxcvbn(password)` function are pre-v3.

**Server side — the part that actually matters.**

```ruby
# Gemfile
gem "devise-pwned_password"   # 0.2.0, 2026-02-21 — wraps philnash/pwned (2.4.1)

# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :validatable, :pwned_password
  validates :password, length: { minimum: 12 }, allow_nil: true
end
```

`pwned` uses the Have I Been Pwned k-anonymity range API — only the first 5 hex chars of the SHA-1 leave your server. NIST SP 800-63B's guidance is the one to cite in a design doc: require a long minimum, **check against known-breached lists**, and **drop composition rules and forced rotation**. A zxcvbn meter is a nudge toward that; it is not the control.

**Decomposition.** `password-strength` + `reveal` (show/hide the password) + `char-count` (if you show a length requirement).

**A11y.** `<meter>` is announced inconsistently, so mark it `aria-hidden="true"` and carry the real message in a `role="status" aria-live="polite"` paragraph referenced by `aria-describedby`. Debounce so every keystroke doesn't queue an announcement. Never convey strength by colour alone. `reveal` must be a `<button>` with `aria-pressed` and a stable accessible name ("Show password"), not an icon-only div.

**Native.** None. Let the platform password manager work: `autocomplete="new-password"`, and don't block paste.

**Pitfalls.**
- Never send the password to the server for scoring. Score in the browser only.
- The dictionaries are large; a static `import` at the top of `application.js` adds ~800 KB to your entrypoint. Lazy-import inside the controller (above) or use importmap `preload: false`.
- Don't block submission on score. Users with passphrases from a manager routinely score oddly; enforce length + breach checks instead.
- Rate-limit the HIBP lookup path and fail open (`pwned` raises on network errors — rescue and allow) or an HIBP outage takes down signups.

**Prior art.** https://zxcvbn-ts.github.io/zxcvbn/ (`@zxcvbn-ts/core` `4.2.0`) · https://github.com/philnash/pwned (`2.4.1`) · https://github.com/michaelbanfield/devise-pwned_password (`0.2.0`) · https://pages.nist.gov/800-63-3/sp800-63b.html · SUPERSEDED: `dropbox/zxcvbn` (`4.4.2`, 2017)

---

### Star ratings

**Hotwire answer.** **No JS needed.** A `<fieldset>` of radio inputs in reverse DOM order, styled with `:checked ~` sibling selectors (or `:has()`), submitted by the normal form. Keyboard, form validation, and screen-reader semantics all come free from the radio group.

**Code.**

```erb
<%= form_with model: @review do |form| %>
  <fieldset class="rating">
    <legend>Rating</legend>
    <%# Reverse order: 5 first, so ~ can reach the stars BEFORE the checked one %>
    <% 5.downto(1) do |n| %>
      <%= form.radio_button :stars, n, id: "stars_#{n}", required: true %>
      <%= form.label :stars, "#{n} star#{'s' unless n == 1}", value: n, for: "stars_#{n}" %>
    <% end %>
  </fieldset>
  <%= form.submit %>
<% end %>
```

```css
.rating {
  border: 0;
  display: inline-flex;
  flex-direction: row-reverse;      /* visually re-reverses 5..1 back to 1..5 */
  justify-content: flex-end;
}
.rating legend { float: left; width: 100%; }

/* Hide the radio visually, keep it focusable and in the a11y tree */
.rating input[type="radio"] {
  position: absolute; width: 1px; height: 1px;
  margin: -1px; padding: 0; overflow: hidden;
  clip-path: inset(50%); white-space: nowrap;
}

.rating label {
  cursor: pointer;
  font-size: 2rem;
  line-height: 1;
  color: var(--star-empty, #ccc);
  transition: color 120ms;
}
.rating label::before { content: "★"; }

/* the checked star and every star AFTER it in DOM order (= lower numbers) */
.rating input:checked ~ label { color: var(--star-filled, #f5a623); }

/* hover/focus preview */
.rating:hover label { color: var(--star-empty, #ccc); }
.rating label:hover,
.rating label:hover ~ label,
.rating input:focus-visible + label { color: var(--star-hover, #ffc857); }

/* focus ring on the label, since the input is visually hidden */
.rating input:focus-visible + label { outline: 2px solid Highlight; outline-offset: 2px; }
```

Modern `:has()` variant — no `flex-direction: row-reverse` trick needed, natural 1..5 DOM order:

```css
.rating { border: 0; display: inline-flex; }
.rating label::before { content: "★"; color: var(--star-empty, #ccc); }
/* fill this star if it, or any LATER sibling, is checked */
.rating:has(input:checked) label:has(~ input:checked)::before,
.rating input:checked + label::before { color: var(--star-filled, #f5a623); }
```

Read-only display (no form) is just text plus `aria-label`:

```erb
<span aria-label="<%= "Rated #{@review.stars} out of 5" %>"><%= "★" * @review.stars %><%= "☆" * (5 - @review.stars) %></span>
```

**Decomposition.** None. If the rating should save immediately, add `autosubmit` (`data-action="change->autosubmit#submit"` on the fieldset) and render the result into a `<turbo-frame>`.

**A11y.** `<fieldset>` + `<legend>` gives the group its accessible name and maps to a radiogroup — do **not** hand-roll `role="radiogroup"` with divs. Each radio needs a real `<label>` with a meaningful name ("3 stars"), not just a star glyph. Visually hide the input with the clip-path pattern, **never** `display: none` or `visibility: hidden` (both remove it from the tab order and the a11y tree). Arrow keys move within the group and Space selects, for free. Add `:focus-visible` styling on the adjacent label since the input itself is invisible. APG for reference: https://www.w3.org/WAI/ARIA/apg/patterns/radio/

**Native.** Works unchanged. Ensure each label's hit target is ≥44×44 px on touch.

**Pitfalls.**
- The reverse-DOM trick is required for the `~` version because CSS has no "previous sibling" combinator; if you write 1..5 in DOM order with `~`, the *wrong* stars fill.
- `flex-direction: row-reverse` reverses visual order but **not** tab order — which is correct here (Tab still enters the group once; arrows move by DOM order) but confuses people. The `:has()` version avoids the whole question.
- `required: true` on radios: put it on every button of the group, or the browser won't enforce it consistently.
- "Half stars" break the radio model. Use ten radios or a `<input type="range" step="0.5">` with an `<output>`.

**Prior art.** Pure CSS; no library warranted. https://www.w3.org/WAI/ARIA/apg/patterns/radio/ · https://developer.mozilla.org/en-US/docs/Web/CSS/:has

---

### Signature pads

**Hotwire answer.** Wrap [signature_pad](https://github.com/szimek/signature_pad) (`5.1.4`, 2026-07-31) in a Stimulus `signature-pad` controller. Convert the canvas to a `Blob` and upload it as a real Active Storage attachment via `DirectUpload` — **not** a base64 data URL in a `text` column.

**Code.**

```erb
<div data-controller="signature-pad"
     data-signature-pad-url-value="<%= rails_direct_uploads_url %>"
     data-signature-pad-name-value="agreement[signature]">
  <canvas data-signature-pad-target="canvas" width="600" height="200"
          role="img" aria-label="Signature drawing area"></canvas>

  <button type="button" data-action="signature-pad#clear">Clear</button>
  <input type="hidden" name="agreement[signature]" data-signature-pad-target="value">

  <details>
    <summary>Can't draw? Type your name instead</summary>
    <%= form.text_field :typed_signature, autocomplete: "name" %>
  </details>
</div>
```

```js
// app/javascript/controllers/signature_pad_controller.js
import { Controller } from "@hotwired/stimulus"
import SignaturePad from "signature_pad"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  static targets = ["canvas", "value"]
  static values  = { url: String, name: String }

  connect() {
    this.pad = new SignaturePad(this.canvasTarget, { backgroundColor: "rgb(255,255,255)" })
    this.onResize = () => this.#resize()
    window.addEventListener("resize", this.onResize)
    this.onSubmit = (event) => this.#capture(event)
    this.element.closest("form")?.addEventListener("submit", this.onSubmit)
    this.#resize()
  }

  disconnect() {
    window.removeEventListener("resize", this.onResize)
    this.element.closest("form")?.removeEventListener("submit", this.onSubmit)
    this.pad?.off()                 // unbinds signature_pad's own pointer handlers
    this.pad = null
  }

  clear() { this.pad.clear(); this.valueTarget.value = "" }

  // README's HiDPI recipe — required or the strokes are blurry / offset
  #resize() {
    const ratio = Math.max(window.devicePixelRatio || 1, 1)
    this.canvasTarget.width  = this.canvasTarget.offsetWidth  * ratio
    this.canvasTarget.height = this.canvasTarget.offsetHeight * ratio
    this.canvasTarget.getContext("2d").scale(ratio, ratio)
    this.pad.clear()                // otherwise isEmpty() lies
  }

  async #capture(event) {
    if (this.pad.isEmpty() || this.valueTarget.value) return
    event.preventDefault()
    const blob = await new Promise(r => this.canvasTarget.toBlob(r, "image/png"))
    const file = new File([blob], "signature.png", { type: "image/png" })
    new DirectUpload(file, this.urlValue).create((error, uploaded) => {
      if (error) return
      this.valueTarget.value = uploaded.signed_id
      event.target.requestSubmit()   // re-submit now that the signed id is present
    })
  }
}
```

API verified against the [signature_pad README](https://github.com/szimek/signature_pad#api): `toDataURL(type, quality)`, `toSVG()`, `fromDataURL()`, `toData()`/`fromData()`, `redraw()`, `clear()`, `isEmpty()`, `off()` / `on()` (unbind/rebind handlers). The `off()` in `disconnect()` is the teardown that matters.

**Decomposition.** `signature-pad` + `direct-upload` + `dirty-form`.

**A11y.** A canvas is a black box: give it `role="img"` and a descriptive `aria-label`, and **always** ship an alternative — a typed-name field (as above) is the standard accommodation and is what most e-signature laws actually contemplate. Provide a visible, keyboard-reachable "Clear" `<button>`. Announce "signature captured" via `role="status"`. There is no APG pattern; treat it as a non-interactive image plus a real form control.

**Native.** Drawing in a web view is laggy and doesn't get Apple Pencil pressure. If signatures are core to your product, make this a bridge component backed by `PKCanvasView` (iOS) / a native `View` (Android) and post back the image (`04-hotwire-native.md` §3.5). Otherwise set `touch-action: none` on the canvas so the web view doesn't scroll while drawing.

**Pitfalls / legal.**
- Resizing a canvas **clears** it. Handle orientation change explicitly, or read the image out before resizing and write it back.
- Without the `devicePixelRatio` scale, strokes are blurry and the pointer offset is wrong on retina — the single most common complaint.
- `isEmpty()` returns garbage after `fromDataURL()` (documented) and after a resize without `clear()`.
- A drawn squiggle is **not** legally binding on its own. ESIGN/eIDAS want *intent*, *attribution*, and *record integrity*: store the signer identity, IP, user agent, timestamp, and a hash of the signed document alongside the image, and show explicit consent text. Do not let the pretty canvas substitute for the audit trail.
- Never store the data URL in a `text` column — it bloats the row, defeats variants, and is slow on mobile.

**Prior art.** https://github.com/szimek/signature_pad (`5.1.4`) · https://guides.rubyonrails.org/active_storage_overview.html

---

### Color pickers

**Hotwire answer.** **No JS needed.** `<input type="color">` is universally supported (Chrome 20+, Firefox 29+, Safari 12.1+) and opens the platform colour picker, including on mobile. Add a `<datalist>` of brand swatches. Only wrap a library when you need alpha, HSL/OKLCH input, or eyedropper UI *today* — because the standard attributes for those have not shipped in Chrome.

**Code.**

```erb
<div data-controller="sync">
  <%= form.label :brand_color %>
  <%= form.color_field :brand_color, list: "brand_swatches",
        data: { sync_target: "source", action: "input->sync#update" } %>
  <output data-sync-target="output"><%= @site.brand_color %></output>

  <datalist id="brand_swatches">
    <option value="#0f172a"><option value="#2563eb"><option value="#f5a623">
  </datalist>
</div>
```

**`alpha` and `colorspace`: do not rely on them yet.** MDN browser-compat-data (2026-08-15) for both attributes is identical: **Safari 18.4+ only; Chrome not supported ([crbug 368059226](https://crbug.com/368059226)); Firefox preview/flag only ([bug 1919718](https://bugzil.la/1919718))**. Same story for `input type=color` accepting arbitrary CSS colour values (`oklab(…)`, `rgb(… / .5)`): Firefox 143, Safari 18.4, Chrome no. So in 2026 the portable contract is still **`#rrggbb`, fully opaque**. Write it as progressive enhancement:

```erb
<%# harmless where unsupported; Safari users get an alpha channel %>
<input type="color" name="site[brand_color]" alpha value="#2563eb">
```

`<datalist>` swatches on a colour input have worked since Chrome 23 ([Chrome dev blog](https://developer.chrome.com/blog/datalist-for-range-color-inputs-offer-some-default-choices/)); Safari does not render them. Treat swatches as a Chrome/Edge nicety and always allow free entry. `showPicker()` works on colour inputs (Chrome 99+, FF 101+, Safari 16+) and is *not* blocked cross-origin for `color`/`file`.

**If you need alpha everywhere:** `@stimulus-components/color-picker` wraps [Pickr](https://github.com/simonwep/pickr) with a hidden field + a mount div — usable, but it is a full custom picker and you inherit its a11y. Prefer a `<input type="color">` plus a separate `<input type="range" min="0" max="1" step="0.01">` for alpha; that is two native, accessible controls instead of one div soup.

**Decomposition.** `sync` (mirror the hex into a text `<output>` or a preview swatch). Nothing else.

**A11y.** Native input is announced correctly and keyboard-operable. **Never convey meaning by the swatch alone** — always show the hex value as text next to it (that's what the `sync` output is for) so it's readable and copyable. If you show a palette of preset colours, they must be `<input type="radio">` in a labelled fieldset, not clickable divs. Contrast-check any user-chosen colour server-side before using it as a text/background pair.

**Native.** `<input type="color">` opens the iOS/Android system colour picker in a web view — a JS picker would be strictly worse. Leave it native.

**Pitfalls.**
- The value is always lowercase `#rrggbb` in the portable case; normalize/validate server-side (`format: { with: /\A#[0-9a-f]{6}\z/ }`) — users paste `rgb()` strings into the adjacent text field.
- `input` fires continuously while the picker is open on some platforms. Debounce before any `autosubmit`.
- There is no "no colour" state. Pair with a checkbox if null is meaningful.

**Prior art.** https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/color · https://www.stimulus-components.com/docs/stimulus-color-picker (wraps https://github.com/simonwep/pickr)

---

### Textarea autogrow

**Hotwire answer.** **No JS needed** in 2026: `field-sizing: content`. Per MDN browser-compat-data (2026-08-15) it is **Chrome/Edge 123+, Firefox 152+, Safari 26.2+** — i.e. all three current-generation engines, Baseline "newly available" since June 2026. Ship the CSS; keep the Stimulus controller only if you must support browsers older than ~2 years.

**Code.**

```css
textarea {
  field-sizing: content;
  min-height: 3lh;      /* don't collapse to one line when empty */
  max-height: 20lh;     /* then it scrolls */
  resize: vertical;     /* still let the user override */
}

/* input autogrow works too */
input[type="text"].autogrow {
  field-sizing: content;
  min-width: 6ch;
  max-width: 40ch;
}
```

```erb
<%= form.text_area :body, rows: 3, class: "autogrow",
      data: { controller: "char-count", char_count_max_value: 280 } %>
```

**Fallback controller** (only if your support matrix needs it — otherwise delete it):

```js
// app/javascript/controllers/autogrow_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { max: Number }

  connect() {
    if (CSS.supports("field-sizing", "content")) return   // let the CSS do it
    this.grow = this.grow.bind(this)
    this.element.addEventListener("input", this.grow)
    this.observer = new ResizeObserver(this.grow)
    this.observer.observe(this.element)
    this.element.style.overflowY = "hidden"
    this.grow()
  }

  disconnect() {
    this.element.removeEventListener("input", this.grow)
    this.observer?.disconnect()
    this.observer = null
  }

  grow() {
    this.element.style.height = "auto"                    // must reset before measuring
    const height = this.element.scrollHeight
    const capped = this.maxValue && height > this.maxValue
    this.element.style.height = `${capped ? this.maxValue : height}px`
    this.element.style.overflowY = capped ? "auto" : "hidden"
  }
}
```

**Decomposition.** Ideally none (CSS). Fallback: `autogrow`, often paired with `char-count`.

**A11y.** Nothing special — it's a `<textarea>` with a `<label>`. Do **not** remove `resize` entirely (`resize: none`) : users with low vision and motor impairments rely on manually enlarging the box. `field-sizing: content` plus `resize: vertical` gives both. Announce character limits via `char-count` writing into an `aria-live="polite"` output, not by silently truncating.

**Native.** Works identically in a web view; growing textareas interact badly with the keyboard accessory view on iOS — cap `max-height` so the field never pushes the send button off screen.

**Pitfalls.**
- Without `min-height`/`min-width`, a `field-sizing: content` field collapses to the width of the caret when empty. Always set both bounds.
- The JS fallback **must** reset `height = "auto"` before reading `scrollHeight`, or it only ever grows.
- `box-sizing: border-box` vs `content-box` changes whether `scrollHeight` matches; set it explicitly.
- Under morphing, a server-rendered `<textarea>` the user is typing into gets reset. Guard it (`02-turbo-deep-dive` §5.8 gotcha 1).
- Autogrow inside a `<turbo-frame>` that lazy-loads: measure on `turbo:frame-load`, not only on `connect()`, or the height is computed while the element is still `display: none` (`scrollHeight === 0`).

**Prior art.** https://developer.mozilla.org/en-US/docs/Web/CSS/field-sizing · https://www.stimulus-components.com/docs/stimulus-textarea-autogrow (npm `stimulus-textarea-autogrow` — note the **unscoped** package name; `@stimulus-components/textarea-autogrow` does not exist)

---

### The wrapped-library teardown contract

Every wrapped-lib controller in this section follows the same shape, because the leak on `disconnect()` is the number one bug in Stimulus lib wrappers. Turbo keeps a cached snapshot of the previous page and restores it on Back; a controller that never tears down accumulates a listener (and often a detached DOM subtree) per visit.

```js
export default class extends Controller {
  connect() {
    this.widget = new SomeLib(this.element, options)
    this.onChange = (event) => this.sync(event)          // keep a stable reference
    this.widget.on("change", this.onChange)              // or addEventListener
    window.addEventListener("resize", this.onResize)
  }

  disconnect() {
    this.widget?.off?.("change", this.onChange)          // 1. unbind YOUR listeners
    window.removeEventListener("resize", this.onResize)
    this.widget?.destroy?.()                             // 2. let the lib unbind ITS listeners
    this.widget = this.onChange = null                   // 3. drop references so GC can run
    this.objectUrls?.forEach(URL.revokeObjectURL)        // 4. release blob: URLs, timers, observers
  }
}
```

Rules that follow from it:
- Store bound handlers on `this` — `this.element.addEventListener("x", this.method.bind(this))` cannot be removed.
- `destroy()` is not optional. IMask, Tom Select, Cropper.js v2, and SortableJS all have one; signature_pad uses `off()`; Cally is a plain custom element (remove your listeners and let the DOM go).
- Under **morphing**, `disconnect()` may never fire, because the node is morphed in place rather than replaced. Anything that must react to a server value change belongs in a `xxxValueChanged()` callback, not in `connect()` — see `02-turbo-deep-dive` §5.8 gotcha 3.
- Libraries that generate DOM the server doesn't know about get pruned by idiomorph. Mark the container `data-turbo-permanent` (with a stable `id`) or `preventDefault()` in `turbo:before-morph-element` — §5.8 gotcha 2.
- On `turbo:before-cache`, tear down anything that would look wrong in a restored snapshot (open dropdowns, half-drawn canvases, duplicated toolbars).

---



## Data display & collections

### Streams vs. morphing: the decision rule for every list mutation

Every pattern below that mutates a collection has to answer one question: **targeted Turbo Stream, or Turbo 8 morphing page refresh?** Answer it once, here, and reference it.

**The rule.**

> **Default to a morphing page refresh.** Drop to targeted Turbo Streams when (a) the list is append-only and long, (b) the page is expensive to render, or (c) the update has no page-shaped answer (a toast, a flash, a modal, a partial the current page doesn't contain).

Concretely, for a Rails controller action that changed a row:

| Situation | Ship this |
|---|---|
| Row created/updated/destroyed, list is one page of ≤ a few hundred rows | `redirect_to posts_path` + `<meta name="turbo-refresh-method" content="morph">`. Zero stream templates. Filters, sort order, counts, empty state, pagination links and the "3 selected" toolbar **all** re-derive correctly for free. |
| Same, but the change came from another user | `broadcasts_refreshes` on the model. Request-id debouncing means the actor doesn't double-render (see [02-turbo-deep-dive §5.5](../notes/02-turbo-deep-dive.md)). |
| Infinite scroll / "load more" / chat — the client holds N pages the server URL does not describe | **Streams.** `turbo_stream.append` + replace the sentinel. A morph would re-render page 1 and throw pages 2–N away. |
| Drag-and-drop reorder | **Neither.** `head :no_content`. See the reorder pattern. |
| Bulk destroy of 300 rows | Streams (`turbo_stream.remove` per id) **only if** the page is expensive; otherwise morph — one round trip beats 300 `<turbo-stream>` elements. |
| A page with a chart, a map, or an editor in it | Streams, or morph with `data-turbo-permanent` on the widget container. Morph prunes third-party DOM. |

**The obsolescence claim, stated plainly:** every pre-2024 tutorial that writes `create.turbo_stream.erb`, `update.turbo_stream.erb` and `destroy.turbo_stream.erb` for a CRUD index — hotrails.dev's original Turbo Rails course, most GoRails episodes from 2021–2023, every "Turbo Streams CRUD" blog post — is now doing by hand what one `redirect_to` + morph does correctly. Those tutorials are not *wrong*, they are *more code with more failure modes*. The classic empty-state bug (below) exists only in the stream version.

**The escape hatch you will need:** a list that is paginated *inside a frame* is destroyed by a whole-page morph unless the frame carries `refresh="morph"` and a `src` — then Turbo refetches the frame from its own current `src` instead of letting idiomorph overwrite it ([02-turbo-deep-dive §5.4](../notes/02-turbo-deep-dive.md)). This is the single most important interaction between this section and morphing.

---

### Pagination with Turbo Frames

**Hotwire answer.** A Turbo Frame wrapping the list *and its pagination links*, with `data-turbo-action="advance"` so the address bar and Back button stay honest. **No Stimulus, no JS.** Turbo intercepts the link because it is inside the frame; the server does not need to know a frame is involved.

**Code.**

Pagy is at **43.6.1** (a full API redesign — `include Pagy::Method`, `pagy(:offset, scope)`, helpers hang off the `@pagy` instance). Every pagy tutorial written before 2026 uses `Pagy::Backend`/`Pagy::Frontend`, `pagy(Post.all, items: 20)` and `pagy_nav(@pagy)` — **that API is gone**; treat those posts as stale ([pagy README, "Version 43"](https://github.com/ddnexus/pagy#readme)).

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  include Pagy::Method   # usually in ApplicationController

  def index
    @pagy, @posts = pagy(:offset, Post.order(created_at: :desc), limit: 25)
  end
end
```

```erb
<%# app/views/posts/index.html.erb %>
<h1>Posts</h1>

<%= turbo_frame_tag "posts", data: { turbo_action: "advance" } do %>
  <p class="loading">Loading…</p>

  <table>
    <thead><tr><th>Title</th><th>Author</th><th>Published</th></tr></thead>
    <tbody><%= render @posts %></tbody>
  </table>

  <nav aria-label="Pagination">
    <%== @pagy.series_nav %>       <%# note <%== : pagy returns raw HTML %>
  </nav>
  <p aria-live="polite"><%== @pagy.info_tag %></p>
<% end %>
```

```css
/* Turbo sets a `busy` attribute (and aria-busy="true") on the frame while it fetches.
   Free loading indicator, no Stimulus. */
.loading { visibility: hidden; }
turbo-frame[busy] .loading { visibility: visible; }
```
(The `busy` attribute is set by Turbo itself; the CSS trick is from [Benito Serna's data-grid walkthrough](https://bhserna.com/building-data-grid-with-search-rails-hotwire-ransack.html) — note that article predates pagy 43 and Turbo 8.)

Kaminari (**1.2.2**) is the conservative alternative and the API has been stable for a decade:

```ruby
@posts = Post.order(created_at: :desc).page(params[:page]).per(25)
```
```erb
<%= turbo_frame_tag "posts", data: { turbo_action: "advance" } do %>
  <tbody><%= render @posts %></tbody>
  <%= paginate @posts %>
<% end %>
```

**Frame `src` vs. link targeting — pick shape (a).**

- **(a) Links inside the frame (ship this).** The frame has no `src`; page 1 renders inline with the first page load. Turbo's link interceptor sees the click inside the frame and navigates the frame. One route, one template, works with JS disabled, and the frame's URL is always a real page.
- **(b) Lazy frame + external links.** `<%= turbo_frame_tag "posts", src: posts_path, loading: :lazy %>` with pagination links elsewhere carrying `data-turbo-frame="posts"`. Use only when the list is genuinely secondary content you want deferred (below the fold, expensive query). Costs a second HTTP round trip on every page load and needs a layout-less response.

**Scrolling — the verified behaviour.** A frame navigation promoted with `data-turbo-action="advance"` **does not scroll the page at all.** Turbo constructs the visit with `willRender: false`, and `Visit` sets `this.scrolled = !willRender`, which makes `performScroll()` a no-op ([`src/core/drive/visit.js`](https://github.com/hotwired/turbo/blob/main/src/core/drive/visit.js)). So clicking "page 2" at the bottom of a tall table leaves you at the bottom, looking at rows 26–50's footer. Two fixes:

```erb
<%# Opt in to Turbo's own autoscroll. Note: it scrolls the frame's FIRST ELEMENT CHILD
    into view, block defaults to "end" — for pagination you want "start". %>
<%= turbo_frame_tag "posts", autoscroll: true,
      data: { turbo_action: "advance", autoscroll_block: "start", autoscroll_behavior: "smooth" } do %>
```
(`autoscroll` / `data-autoscroll-block` / `data-autoscroll-behavior` are read in [`frame_renderer.js`](https://github.com/hotwired/turbo/blob/main/src/core/frames/frame_renderer.js); `block ∈ start|center|end|nearest`, default `end`; `behavior ∈ auto|smooth`, default `auto`. See also [02-turbo-deep-dive §3.9](../notes/02-turbo-deep-dive.md).)

Or, if you want the scroll only when the frame is off-screen:

```js
// one listener, application-wide
document.addEventListener("turbo:frame-render", (event) => {
  const frame = event.target
  if (!frame.hasAttribute("data-scroll-into-view")) return
  const { top } = frame.getBoundingClientRect()
  if (top < 0) frame.scrollIntoView({ block: "start", behavior: "smooth" })
})
```

**Decomposition.**
- none — plain Turbo Frame. Optional `intersection` for a lazy frame you want loaded early.

**A11y.**
- Wrap the nav in `<nav aria-label="Pagination">`. Pagy's `series_nav` emits `aria-label` on the links and marks the current page; verify against [pagy's ARIA notes](https://ddnexus.github.io/pagy/resources/ARIA/).
- Frame navigation moves no focus and announces nothing. Put the result count in an `aria-live="polite"` region inside the frame (`@pagy.info_tag`) so screen-reader users hear "Displaying items 26-50 of 312".
- The frame gets `aria-busy="true"` from Turbo during the fetch — free.
- APG: [table pattern](https://www.w3.org/WAI/ARIA/apg/patterns/table/).

**Native.** Set `queryStringPresentation: "replace"` in the path configuration for the index route (iOS 1.2.1+), otherwise every page click **pushes a new screen** and Back walks you through twelve pages one at a time — Android already behaves this way. See [04-hotwire-native §2.3](../notes/04-hotwire-native.md). On native, prefer "load more" over numbered pagination: infinite lists are the platform idiom and a numbered pager inside a webview reads as a website.

**Pitfalls.**
- `data-turbo-action="advance"` rewrites the address bar to the **frame's src URL**. If that URL is a fragment-only route (`/posts/table?page=2` returning a bare `<tbody>`), you have just put a URL in the user's history that renders a broken page on reload/share. Rule: only promote frames whose src is a real, standalone, layout-rendering page.
- A whole-page morph will overwrite the frame with page 1. Add `refresh="morph"` **and** a `src` to the frame so Turbo refetches it from its own current src instead ([02-turbo-deep-dive §5.4](../notes/02-turbo-deep-dive.md)).
- Pagination links must be *inside* the frame, or they navigate the whole page.
- With a `<table>`, the frame cannot go around `<tbody>` — `<turbo-frame>` is not valid table content and the parser will hoist it out. Put the frame **around the whole `<table>`**, or use `display: contents` on a frame placed around a `<tbody>` only if you have verified your target browsers' parser behaviour. Wrapping the table is the safe answer.
- Turning on prefetch-on-hover for pagination links prefetches every page number the user grazes. `data-turbo-prefetch="false"` on the nav if your index query is expensive.

**Prior art.** [pagy](https://ddnexus.github.io/pagy/) (43.x) · [kaminari](https://github.com/kaminari/kaminari) (1.2.2) · [will_paginate](https://github.com/mislav/will_paginate) (maintained but has no reason to be chosen in 2026) · [Benito Serna, data grid with hotwire + ransack](https://bhserna.com/building-data-grid-with-search-rails-hotwire-ransack.html).

---

### "Load more" button

**Hotwire answer.** A link carrying `data-turbo-stream` that returns a Turbo Stream: `append` the new rows to the list, `replace` the button with the next one. **This is the default you should ship**, in preference to infinite scroll, for both a11y and control. Two lines of Stimulus? Zero. No Stimulus at all.

**Code.**

```erb
<%# app/views/posts/index.html.erb %>
<h1>Posts</h1>

<div id="posts">
  <%= render @posts %>
</div>

<div id="pagination">
  <%= render "pagination", pagy: @pagy %>
</div>

<p id="posts_status" class="sr-only" aria-live="polite" aria-atomic="true"></p>
```

```erb
<%# app/views/posts/_pagination.html.erb %>
<% if pagy.next %>
  <%= link_to "Load more",
        posts_path(request.query_parameters.merge(page: pagy.next)),
        id: "load_more",
        rel: "next",
        data: { turbo_stream: true } %>
<% else %>
  <p class="end-of-list">That’s everything.</p>
<% end %>
```

`data-turbo-stream` on an `<a>` is what makes Turbo send `Accept: text/vnd.turbo-stream.html` on a **link click** — Turbo only sends that header automatically for form submissions. Verified in [`src/core/session.js`](https://github.com/hotwired/turbo/blob/main/src/core/session.js): `followedLinkToLocation` reads `link.hasAttribute("data-turbo-stream")` and passes `acceptsStreamResponse` into the visit.

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  include Pagy::Method

  def index
    @pagy, @posts = pagy(:offset, filtered_posts, limit: 25)

    respond_to do |format|
      format.html
      format.turbo_stream   # renders index.turbo_stream.erb
    end
  end

  private

  def filtered_posts
    Post.order(created_at: :desc)
  end
end
```

```erb
<%# app/views/posts/index.turbo_stream.erb %>
<%= turbo_stream.append "posts" do %>
  <%= render @posts %>
<% end %>

<%= turbo_stream.replace "pagination" do %>
  <div id="pagination"><%= render "pagination", pagy: @pagy %></div>
<% end %>

<%= turbo_stream.update "posts_status" do %>
  Loaded <%= @posts.size %> more. <%== @pagy.info_tag %>
<% end %>
```

**Implementation (b): the frame-per-page nesting trick.** Each page's response renders the *next* page's frame, so no streams and no `respond_to` at all:

```erb
<%# app/views/posts/index.html.erb — page 1 %>
<div id="posts"><%= render @posts %></div>
<%= render "next_page", pagy: @pagy %>

<%# app/views/posts/_next_page.html.erb %>
<% if pagy.next %>
  <%= turbo_frame_tag "posts_page_#{pagy.next}",
        src: posts_path(page: pagy.next), loading: :lazy, target: "_top" do %>
    <span class="skeleton">Loading…</span>
  <% end %>
<% end %>

<%# app/views/posts/_page.html.erb — what page 2+ returns inside its frame %>
<%= turbo_frame_tag "posts_page_#{pagy.page}" do %>
  <%= render posts %>
  <%= render "next_page", pagy: pagy %>
<% end %>
```

Shape (b) is elegant and needs zero JS, but the rows end up **nested inside frames**, one level deeper per page. That breaks `<table>` markup entirely, breaks CSS selectors like `#posts > tr`, and makes `turbo_stream.remove dom_id(post)` on page 7 land inside a frame you'd rather not think about. **Ship (a).** Use (b) only for a flat card/feed list where nesting is harmless, or when you need the sentinel to be the loading mechanism (see infinite scroll).

**Decomposition.**
- (a) none — a plain link + Turbo Stream.
- (b) none — a lazy Turbo Frame; Turbo's own `AppearanceObserver` does the intersection work.

**A11y.**
- A real `<a>` (or `<button>` in a GET form) — keyboard, Enter/Space, and focus all work by construction. This is the whole reason to prefer it over infinite scroll.
- **Focus is destroyed** when the button is `replace`d: the element the user just activated is removed from the DOM and focus falls to `<body>`. Fix by keeping the focused element and updating its href instead — `turbo_stream.replace` the *wrapper* but immediately re-focus, or use `turbo_stream.update "pagination"` and a `turbo:before-stream-render` hook that restores focus. Simplest correct version: give the button a stable id and restore focus after the stream renders.
  ```js
  document.addEventListener("turbo:before-stream-render", (event) => {
    const hadFocus = document.activeElement?.id === "load_more"
    if (!hadFocus) return
    const render = event.detail.render
    event.detail.render = async (stream) => { await render(stream); document.getElementById("load_more")?.focus() }
  })
  ```
- Announce the result with `aria-live="polite"` (the `#posts_status` region above), or the load is silent for screen-reader users.
- `rel="next"` on the link is meaningful markup and costs nothing.

**Native.** Works as-is. Prefer this over numbered pagination in native apps. If you want a true native "pull to load more", that is a bridge component; but the web version is good enough that nobody builds it.

**Pitfalls.**
- **The link must not be inside a `<turbo-frame>`**, or the frame intercepts the click and swallows the stream. If it must live inside one, add `data-turbo-frame="_top"`.
- Turbo prefetches links on hover by default; the load-more link is one hover away from firing your page-2 query on every mouse pass. Add `data-turbo-prefetch="false"`.
- Preserve the current filter/sort params in the link (`request.query_parameters.merge(page:)`), or "load more" silently drops the user's filters and appends unrelated rows.
- Records inserted while the user pages produce **duplicate rows** at page boundaries. If that matters, use a keyset/cursor paginator (`pagy(:keyset, …)`) rather than OFFSET.
- Do **not** wire this to a morphing refresh. A refresh re-renders page 1 and discards everything appended. If the page also does CRUD, use targeted streams for that CRUD too, or accept losing the loaded pages.

**Prior art.** [pagy `:countless` paginator](https://ddnexus.github.io/pagy/toolbox/paginators/countless/) with `headless: true` for exactly this (no COUNT query; the collection ends when `@records.size < @pagy.limit`) · [pagy `next_tag` / `page_url(:next)` helpers](https://ddnexus.github.io/pagy/toolbox/helpers/anchor_tags/) · [stimulus-components content-loader](https://www.stimulus-components.com/docs/stimulus-content-loader) for the frame variant.

---

### Infinite scroll

**Hotwire answer.** A sentinel element at the bottom of the list that fires when it enters the viewport and clicks the (visually hidden) "load more" link. Built from the generic `intersection` primitive — or, with **zero JS**, a lazy `<turbo-frame>` sentinel, because Turbo's own `AppearanceObserver` already is an IntersectionObserver. **But: don't. Ship "load more" instead.** This is a genuinely weak spot; read the honesty section below before you build it.

**Code — the no-JS version (Turbo does the observing).**

Exactly implementation (b) from "Load more": the last thing on each page is `<turbo-frame loading="lazy" src="…?page=N">`. Turbo loads it when it scrolls into view (`elementAppearedInViewport` → `#loadSourceURL` in [`frame_controller.js`](https://github.com/hotwired/turbo/blob/main/src/core/frames/frame_controller.js)). No Stimulus, no IntersectionObserver of your own. Pays the nesting cost.

**Code — the `intersection` primitive version (ship this if you must ship infinite scroll).**

```js
// app/javascript/controllers/intersection_controller.js
import { Controller } from "@hotwired/stimulus"

// Generic: dispatches intersection:appear / intersection:disappear. No opinion about
// what happens next. Compose with `activate` to click something.
export default class extends Controller {
  static values = {
    rootMargin: { type: String,  default: "0px" },
    threshold:  { type: Number,  default: 0 },
    once:       { type: Boolean, default: false }
  }

  connect() {
    this.observer = new IntersectionObserver(this.#handle, {
      rootMargin: this.rootMarginValue,
      threshold: this.thresholdValue
    })
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer.disconnect()
    this.observer = null
  }

  #handle = (entries) => {
    for (const entry of entries) {
      if (entry.isIntersecting) {
        this.dispatch("appear", { detail: { entry } })
        if (this.onceValue) this.observer.unobserve(entry.target)
      } else {
        this.dispatch("disappear", { detail: { entry } })
      }
    }
  }
}
```

```js
// app/javascript/controllers/activate_controller.js
// Translates any event into a synthetic click on this element or an `item` target.
// Also fires on connect when data-activate-on-connect-value="true".
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]
  static values  = { onConnect: { type: Boolean, default: false } }

  connect() { if (this.onConnectValue) this.fire() }

  fire() {
    const el = this.hasItemTarget ? this.itemTarget : this.element
    if (el.getAttribute("aria-disabled") === "true" || el.disabled) return
    el.click()
  }
}
```

```erb
<%# app/views/posts/_pagination.html.erb — the sentinel wraps the real link %>
<% if pagy.next %>
  <div data-controller="intersection"
       data-intersection-root-margin-value="800px"
       data-intersection-once-value="true"
       data-action="intersection:appear->activate#fire">
    <%= link_to "Load more",
          posts_path(request.query_parameters.merge(page: pagy.next)),
          id: "load_more", rel: "next",
          class: "js-only-visually-hidden",
          data: { controller: "activate", turbo_stream: true, turbo_prefetch: false } %>
  </div>
<% end %>
```

Server side is **identical to "Load more"** — same `index.turbo_stream.erb`, same controller. That is the point: infinite scroll is the load-more pattern plus an observer. If you keep the link real and merely *also* auto-click it, you keep the keyboard path working, which is the only defensible way to ship infinite scroll.

`rootMargin: "800px"` fires the load before the user reaches the bottom, which is what makes it feel infinite rather than stuttery.

**Pagy's position.** Pagy 43 ships **no** infinite-scroll extra and no autoscroll JS. Earlier pagy versions had `pagy*_nav_js` client-rendered navs and community recipes for infinite scroll; v43 removed the extras system entirely. What v43 *does* give you is [`:countless`](https://ddnexus.github.io/pagy/toolbox/paginators/countless/) with `headless: true` — no COUNT query, `@records` behaves like a plain collection, and the list is over when `@records.size < @pagy.limit`. That is the correct paginator for an infinite feed. Any blog post telling you to `gem "pagy"` and `require "pagy/extras/..."` is pre-43 and stale.

**The a11y problem — stated plainly.** Infinite scroll is hostile to keyboard and screen-reader users, and the damage is structural, not a bug you can polish out:

1. **The footer becomes unreachable.** Every time the user gets near the bottom, more content is inserted above it. Site nav, legal links, help — gone. There is no fix other than moving that content elsewhere or not doing infinite scroll.
2. **Tab order grows without bound.** A keyboard user cannot get past the list.
3. **New content is announced badly or not at all.** You must add `aria-live="polite"` (see the status region in "Load more") or the page silently changes under a screen reader.
4. **"Where am I?" is unanswerable.** No page numbers, no position, no way to return to an item.
5. **Scroll hijacking with `rootMargin` breaks the user's mental model of document length** — the scrollbar keeps lying.

WAI-ARIA APG has a pattern for exactly this shape: **[feed](https://www.w3.org/WAI/ARIA/apg/patterns/feed/)** — `role="feed"` on the container, `role="article"` with `aria-posinset` / `aria-setsize` / `aria-labelledby` on each item, Page Down/Page Up moving between articles, Control+End to the footer. If you ship infinite scroll, ship the feed pattern; it is the only thing that makes it navigable. `aria-setsize="-1"` when the total is unknown.

**Recommendation: "load more" is the default.** Infinite scroll for consumer feeds where engagement is the product; a real button everywhere else. Nielsen Norman's finding — that infinite scroll destroys the ability to find something you saw earlier — has held up for a decade.

**The scroll-restoration-on-back problem — what actually happens.**

The common claim ("going back loses your loaded pages") is *usually false and sometimes true*, and it's worth knowing which:

- Turbo caches a **snapshot of the page taken at `turbo:before-cache` time**, i.e. as you navigate *away*. That snapshot contains all N pages you had appended. Going Back is a `restore` visit: Turbo serves the cached snapshot and `scrollToRestoredPosition()` puts you back at your scroll offset ([`visit.js`](https://github.com/hotwired/turbo/blob/main/src/core/drive/visit.js)). **In the happy path, Back works.**
- The cache is an **LRU capped at 10 snapshots** (`new SnapshotCache(10)` in [`page_view.js`](https://github.com/hotwired/turbo/blob/main/src/core/drive/page_view.js)). Wander eleven pages deep and your feed snapshot is evicted → Back refetches page 1 and you land at the top.
- **Any successful non-GET form submission clears the entire cache** (`session.clearCache()` in `formSubmissionSucceededWithResponse`). Like a post, submit a comment, follow someone — feed snapshot gone.
- `<meta name="turbo-cache-control" content="no-cache">` anywhere on that page disables it outright.
- A **hard reload** or arriving from an external link is not a restore visit; you get page 1.
- Turbo 8 morphing **does not help here** — a morph refresh re-renders the server's page 1.

Mitigations, in order of how much I'd recommend them:

1. **Encode loaded state in the URL.** On each append, `history.replaceState` the URL to `?page=N` and have the server render pages 1..N for that request (or accept landing on page N). Costs a heavier query; buys correct Back, correct reload, correct sharing. This is what "the URL is the state" actually means.
2. **Use "load more" instead**, and put the page in the URL via `data-turbo-action="advance"` on a frame. Problem disappears.
3. **`persist` the loaded page count in `sessionStorage`** keyed by URL, and re-fetch on connect. Fast to write, but it re-runs N queries and you still lose exact scroll offset.
4. Accept it. For an ephemeral consumer feed, nobody notices.

**Verdict: Hotwire's infinite scroll is fine mechanically and weak on state. The framework gives you the loading; it gives you nothing for restoration, and neither does React — this is a web problem, not a Hotwire problem. Prefer "load more".**

**Decomposition.**
- `intersection` (sentinel) + `activate` (click the real link) — or nothing at all, using a lazy `<turbo-frame>` as the sentinel.
- optional `persist` for the loaded-page-count mitigation.

**A11y.** APG [feed](https://www.w3.org/WAI/ARIA/apg/patterns/feed/) pattern: `role="feed"`, `role="article"` items with `aria-posinset`/`aria-setsize`/`aria-labelledby`, Page Down/Up navigation, Control+End to footer. Plus an `aria-live="polite"` status region. Keep a real, focusable "Load more" link — visually hidden until focused (`:focus-visible { position: static; }`) — so the keyboard path always exists.

**Native.** Infinite scroll inside a webview competes with the native scroll view and with pull-to-refresh (`pull_to_refresh_enabled` defaults to `true` on iOS). Either disable pull-to-refresh for the feed route in the path configuration, or use "load more". Momentum scrolling + `rootMargin` + a slow network is the combination that produces the "why did it jump" bug reports.

**Pitfalls.**
- `IntersectionObserver` fires immediately on connect if the sentinel is already visible (a short first page) → instant double-load. Set `once: true` and/or make page 1 taller than the viewport.
- The sentinel must be **replaced, not appended after**, or the observer stays attached to a stale node and never fires again. `turbo_stream.replace "pagination"` handles it: the new node connects a new controller.
- `disconnect()` must call `observer.disconnect()` or you leak an observer per Turbo navigation.
- Under morphing, a node morphed **in place** does not re-run `connect()` ([02-turbo-deep-dive §5.8](../notes/02-turbo-deep-dive.md)) — the sentinel keeps its old observer. Since the sentinel is stream-replaced, this is normally fine; if you mix morphing in, verify.
- Don't put the sentinel inside a `<turbo-frame>` unless you mean the frame to handle the click.
- Firing a request per pixel: throttle by removing the sentinel (`once: true`) and letting the server's response bring a new one.

**Prior art.** [pagy `:countless`](https://ddnexus.github.io/pagy/toolbox/paginators/countless/) · [stimulus-use `useIntersection`](https://stimulus-use.github.io/stimulus-use/#/use-intersection) (if you'd rather mix in than hand-roll) · [stimulus-components content-loader](https://www.stimulus-components.com/docs/stimulus-content-loader) · Turbo's own lazy frames.

---

### Sortable table columns

**Hotwire answer.** **No JS needed.** Column headers are plain links to `?sort=name&direction=asc`, targeting the table's Turbo Frame, with `data-turbo-action="advance"`. The entire feature is an ERB helper, a controller allowlist, and `order()`.

**Code.**

```ruby
# app/helpers/sorting_helper.rb
module SortingHelper
  # <th><%= sortable "name", "Name" %></th>
  def sortable(column, label = nil, **link_options)
    label     ||= column.to_s.humanize
    current     = params[:sort].to_s == column.to_s
    direction   = (current && params[:direction] == "asc") ? "desc" : "asc"
    indicator   = current ? (params[:direction] == "asc" ? " ▲" : " ▼") : ""

    link_to url_for(request.query_parameters.merge(
              sort: column, direction: direction, page: nil)),   # reset to page 1
            **link_options.reverse_merge(data: { turbo_action: "advance" }) do
      safe_join([label, tag.span(indicator, aria: { hidden: true })])
    end
  end

  # aria-sort belongs on the <th>, not the link.
  def sort_th(column, label = nil, **options)
    state = if params[:sort].to_s == column.to_s
              params[:direction] == "asc" ? "ascending" : "descending"
            else
              "none"
            end
    tag.th(sortable(column, label), scope: "col", aria: { sort: state }, **options)
  end
end
```

```erb
<%# app/views/posts/index.html.erb %>
<%= turbo_frame_tag "posts", data: { turbo_action: "advance" } do %>
  <table>
    <thead>
      <tr>
        <%= sort_th :title %>
        <%= sort_th :author_name, "Author" %>
        <%= sort_th :published_at, "Published" %>
        <th scope="col">Actions</th>
      </tr>
    </thead>
    <tbody><%= render @posts %></tbody>
  </table>
  <%== @pagy.series_nav %>
<% end %>
```

**The SQL injection guard — this is the part people get wrong.** `params[:sort]` and `params[:direction]` go straight into `ORDER BY`. `Post.order(params[:sort])` with `sort=(SELECT ...)` is a live vulnerability, and Rails' "dangerous query method" protection has been relaxed and re-tightened enough times that you must not rely on it. **Validate against a literal allowlist, always:**

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  include Pagy::Method

  SORTABLE_COLUMNS = %w[title published_at author_name created_at].freeze

  def index
    @pagy, @posts = pagy(:offset, Post.sorted_by(sort_column, sort_direction), limit: 25)
  end

  private

  # Never interpolate params into SQL. Never `send`. Never `Post.column_names.include?`
  # (that leaks every column including ones you don't want exposed). A literal array.
  def sort_column
    SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "created_at"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end
  helper_method :sort_column, :sort_direction
end
```

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :author

  # Hash form: the column is an identifier, quoted by the adapter. Direction is a symbol.
  # Association sorts need an explicit join and a qualified column.
  scope :sorted_by, ->(column, direction) {
    case column
    when "author_name" then joins(:author).order("authors.name" => direction)
    else order(column => direction)
    end
  }
end
```

Note the layering: even though `sort_column` is already validated, the model's `case` means a bug in the controller can't reach `order()` with an arbitrary string. Belt and braces on the one code path where a mistake is a data breach.

**Ransack alternative.** `sort_link(@q, :title)` does all of the above including the arrow. Ransack **4.x requires** you to define `ransackable_attributes` on every model or it raises — the allowlist is mandatory and that's the reason to consider it:

```ruby
class Post < ApplicationRecord
  def self.ransackable_attributes(auth_object = nil) = %w[title published_at created_at]
  def self.ransackable_associations(auth_object = nil) = %w[author]
  def self.ransortable_attributes(auth_object = nil) = ransackable_attributes(auth_object)
end
```
```erb
<th scope="col"><%= sort_link(@q, :title, "Title", data: { turbo_action: "advance" }) %></th>
```
([ransack sorting docs](https://github.com/activerecord-hackery/ransack/blob/main/docs/docs/getting-started/sorting.md), [authorization docs](https://github.com/activerecord-hackery/ransack/blob/main/docs/docs/going-further/other-notes.md); ransack is at 4.4.1.) Ransack's `sort_link` does **not** emit `aria-sort` — you still write the `<th>` wrapper yourself.

**Recommendation:** hand-rolled for ≤ 3 tables; ransack once you have an admin area with a dozen. The hand-rolled version is 20 lines you fully understand; ransack is a query DSL exposed to the internet, which is a different security posture.

**Decomposition.**
- none. Links inside a Turbo Frame. (If you add a "sort by" `<select>` instead of headers, that's `autosubmit`.)

**A11y.**
- `aria-sort` on the `<th>`, one column at a time, values `ascending` | `descending` | `none` | `other`. This is the *only* thing that tells a screen reader the table is sorted. [APG sortable table example](https://www.w3.org/WAI/ARIA/apg/patterns/table/examples/sortable-table/) and [grid & table properties](https://www.w3.org/WAI/ARIA/apg/practices/grid-and-table-properties/).
- `scope="col"` on every header.
- The arrow indicator must be `aria-hidden="true"` — `aria-sort` already conveys it, and "▲" reads as "up-pointing triangle".
- The header must be a real `<a>` (or `<button>`) inside the `<th>`, not a click handler on the `<th>`.
- After a frame swap, announce the new state: put `<span aria-live="polite">Sorted by Title, ascending</span>` inside the frame.

**Native.** Same `queryStringPresentation: "replace"` note as pagination — a sort click otherwise pushes a screen. Consider a native sort menu as a bridge component that just sets `location.search`; the web table underneath needs no changes.

**Pitfalls.**
- **Reset `page` to nil when sorting.** Sorting while on page 7 and staying on page 7 is nonsense.
- `request.query_parameters.merge(...)` preserves filters — do not rebuild the URL from scratch or you drop them.
- Sorting on a nullable column: `NULLS LAST` differs by adapter. Postgres: `order(Arel.sql("#{quoted} #{dir} NULLS LAST"))` — and note this is the one place you *do* need `Arel.sql`, so the allowlist matters even more.
- Sorting an association requires a `joins`, which can change the row count if the association is has_many. Use `distinct` or sort on a denormalized column.
- Clicking the same header twice must toggle, not re-apply — the `current && direction == "asc"` check above.
- Sorting by a *computed* attribute (a Ruby method, not a column) cannot be done in SQL. Either denormalize it into a column or accept in-memory sorting only within a page.

**Prior art.** [ransack](https://github.com/activerecord-hackery/ransack) 4.4.1 · [pagy](https://ddnexus.github.io/pagy/) for the pagination half · [Rails Action View helpers guide](https://guides.rubyonrails.org/action_view_helpers.html) · the `sortable` helper originates in Railscast #228 and is reproduced in every GoRails/Drifting Ruby table episode since · **superseded:** [wice_grid](https://github.com/leikind/wice_grid) (dead, jQuery-era), `datatables` wrappers.

---

### Filterable / faceted tables

**Hotwire answer.** A **GET** form with `autosubmit` (debounced), targeting the table's Turbo Frame, with `data-turbo-action="advance"` so every filter state is a real URL. Filter chips and "clear all" are plain links with params dropped. **One Stimulus primitive (`autosubmit`) and nothing else.**

**Code.**

```erb
<%# app/views/posts/index.html.erb %>
<%= form_with url: posts_path, method: :get,
      data: { controller: "autosubmit", autosubmit_delay_value: 300,
              turbo_frame: "posts", turbo_action: "advance" } do |f| %>

  <%= f.label :q, "Search" %>
  <%= f.search_field :q, value: params[:q],
        data: { action: "input->autosubmit#submit" }, autocomplete: "off" %>

  <%= f.label :status, "Status" %>
  <%= f.select :status, Post.statuses.keys, { include_blank: "Any" },
        data: { action: "change->autosubmit#submit" } %>

  <%= f.label :author_id, "Author" %>
  <%= f.collection_select :author_id, Author.order(:name), :id, :name,
        { include_blank: "Anyone" }, data: { action: "change->autosubmit#submit" } %>

  <%= f.label :published_after, "Published after" %>
  <%= f.date_field :published_after, value: params[:published_after],
        data: { action: "change->autosubmit#submit" } %>

  <%# carry sort state through the form so filtering doesn't reset it %>
  <%= f.hidden_field :sort, value: params[:sort] %>
  <%= f.hidden_field :direction, value: params[:direction] %>

  <noscript><%= f.submit "Filter" %></noscript>
<% end %>

<%= render "filter_chips" %>

<%= turbo_frame_tag "posts", data: { turbo_action: "advance" } do %>
  <p aria-live="polite"><%== @pagy.info_tag %></p>
  <table>…</table>
  <%== @pagy.series_nav %>
<% end %>
```

```js
// app/javascript/controllers/autosubmit_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 0 } }

  initialize() { this.submit = this.submit.bind(this) }

  connect() {
    if (this.delayValue > 0) this.submit = debounce(this.submit, this.delayValue)
  }

  submit() { this.element.requestSubmit() }
}

function debounce(fn, delay) {
  let timer
  return (...args) => { clearTimeout(timer); timer = setTimeout(() => fn.apply(this, args), delay) }
}
```
(This is [`@stimulus-components/auto-submit`](https://www.stimulus-components.com/docs/stimulus-auto-submit) verbatim — default delay 150 ms, `requestSubmit()` so `submit` handlers and validation run. Prefer installing it to copying it; it's ~15 lines either way. `debounce` is not a controller — see the vocabulary rules.)

**Filter chips + clear all.** Pure ERB, pure links:

```erb
<%# app/views/posts/_filter_chips.html.erb %>
<% chips = {
     q:               ("Search: “#{params[:q]}”"                 if params[:q].present?),
     status:          ("Status: #{params[:status].humanize}"      if params[:status].present?),
     author_id:       ("Author: #{Author.find(params[:author_id]).name}" if params[:author_id].present?),
     published_after: ("After #{params[:published_after]}"        if params[:published_after].present?)
   }.compact %>

<% if chips.any? %>
  <ul class="chips">
    <% chips.each do |key, text| %>
      <li>
        <span><%= text %></span>
        <%= link_to url_for(request.query_parameters.except(key.to_s).merge(page: nil)),
              class: "chip-remove",
              aria: { label: "Remove filter: #{text}" },
              data: { turbo_frame: "posts", turbo_action: "advance" } do %>
          <span aria-hidden="true">×</span>
        <% end %>
      </li>
    <% end %>
    <li>
      <%= link_to "Clear all", posts_path,
            data: { turbo_frame: "posts", turbo_action: "advance" } %>
    </li>
  </ul>
<% end %>
```

Note the chips live **outside** the frame, so they need explicit `data-turbo-frame="posts"` — and they will therefore *not* update when the frame reloads. Two ways out: (1) put the chips inside the frame (simplest, ship this — move the `<ul>` above the `<table>` inside `turbo_frame_tag`), or (2) return a Turbo Stream that also replaces `#filter_chips`. Same choice as always.

**Controller — hand-rolled scopes.**

```ruby
class PostsController < ApplicationController
  include Pagy::Method

  def index
    scope = Post.includes(:author)
                .search(params[:q])
                .with_status(params[:status])
                .by_author(params[:author_id])
                .published_after(params[:published_after])
                .sorted_by(sort_column, sort_direction)

    @count       = scope.count
    @pagy, @posts = pagy(:offset, scope, limit: 25)
  end
end
```

```ruby
# app/models/post.rb — each scope is a no-op when its param is blank. This is the
# whole trick: chainable, testable, and impossible to inject into.
scope :search,          ->(q)    { q.present?    ? where("title ILIKE ?", "%#{sanitize_sql_like(q)}%") : all }
scope :with_status,     ->(s)    { s.present?    ? where(status: s)          : all }
scope :by_author,       ->(id)   { id.present?   ? where(author_id: id)      : all }
scope :published_after, ->(date) { date.present? ? where(published_at: date..) : all }
```

**Preserving filter state in pagination links — the thing everyone forgets.** Pagy 43's `page_url` / `series_nav` build URLs from **the current request's params**, so filters survive automatically (`@pagy.page_url(:next) # => "/path?example=123&page=4"` — the `example=123` is the incoming query string, [page_url docs](https://ddnexus.github.io/pagy/toolbox/helpers/page_url/)). Kaminari's `paginate` does the same via `url_for`. If you hand-roll pagination links, you must `request.query_parameters.merge(page: n)`. And your sort links must merge, and your chips must `.except`. **One rule: never construct a URL for this page from scratch; always derive it from `request.query_parameters`.**

**Ransack vs. hand-rolled — pick hand-rolled.** Ransack gives you `f.search_field :title_cont` and arbitrary predicate combinations for free, and 4.x forces an allowlist. But: it turns your query string into a query language, `ransackable_associations` is an easy way to leak a `users.encrypted_password_cont` probe if you get it wrong, the generated SQL is hard to optimise, and `distinct: true` for association filters silently changes your counts. **Hand-rolled scopes for product surfaces; ransack for internal admin where the flexibility pays.** If you want ransack's ergonomics with a smaller surface, [`has_scope`](https://github.com/heartcombo/has_scope) maps params to scopes you wrote.

**The focus-loss problem.** With a 300 ms debounce and a slow query, a frame render can land *while the user is still typing*. The `<input>` is inside the form which is **outside** the frame in the markup above — so it is untouched and focus is preserved. **That is the fix: keep the form outside the frame; put only the results inside.** If your design forces the form inside the frame:

- `data-turbo-permanent` + a stable `id` on the input (works for both replace and morph; under morph the node is simply not touched — [`morphing.js`](https://github.com/hotwired/turbo/blob/main/src/core/morphing.js)), or
- use a page-level morph refresh and guard the active element:
  ```js
  document.addEventListener("turbo:before-morph-element", (event) => {
    const el = event.detail.currentElement
    if (el === document.activeElement && el.matches("input, textarea, select")) event.preventDefault()
  })
  ```
- Do **not** try to restore focus and caret position after the fact; you will get the caret wrong and eat keystrokes typed during the round trip.

**Decomposition.**
- `autosubmit` (debounced via the controller's `delay` value)
- optional `persist` — remember the last filter set in `sessionStorage` for when the user returns
- optional `combobox` for a typeahead facet with many values (see the forms section)
- optional `dialog` + `focus-trap` if facets live in a "Filters" sheet on mobile

**A11y.**
- Real `<label>` on every control. The form is a `<form role="search">` if it's primarily search.
- `aria-live="polite"` on the result count so a screen reader hears "312 results" after each auto-submit. Put it inside the frame so it updates.
- Chips: the remove control is a link with `aria-label="Remove filter: Status: Draft"`; the `×` is `aria-hidden`.
- Auto-submitting on `input` is itself an a11y hazard — content changes without user request. Debounce ≥ 300 ms, keep a visible `<noscript>`/fallback submit, and never move focus on submit.
- APG: [table](https://www.w3.org/WAI/ARIA/apg/patterns/table/); for the facet group, `<fieldset><legend>`.

**Native.** Filter/sort/page links are all query-string changes: set `queryStringPresentation: "replace"` on the route or the user accumulates a stack of near-identical screens ([04-hotwire-native §2.3](../notes/04-hotwire-native.md)). A native filter sheet is a reasonable bridge component — it collects values and does `form.requestSubmit()` on the web side.

**Pitfalls.**
- The form **must** be `method: :get`. A POST here breaks the URL, the Back button, bookmarking and sharing.
- Blank params pollute the URL (`?q=&status=&author_id=`). Strip them: either `form.querySelectorAll("[name]")` filtering in a submit handler, or accept it — but note blank params also break `request.query_parameters.except` chip logic if you test `key?` instead of `.present?`.
- A slow filter + a fast typist produces out-of-order responses. Turbo Frames cancel the in-flight request when a new one starts on the same frame, so this is handled — **but only if both requests target the same frame.** Mixed targets race.
- `distinct` and `count` on a joined scope: `scope.count` after `includes` + `references` can emit a very different query than you expect. Compute `@count` from the un-paginated scope explicitly.
- Resetting `page` on every filter change: the chips and the form must both drop `page`.
- Under a whole-page morph, the frame is overwritten with the server's default filter state unless the frame has `refresh="morph"` + `src`.

**Prior art.** [Benito Serna — dynamic data grid with rails, hotwire and ransack](https://bhserna.com/building-data-grid-with-search-rails-hotwire-ransack.html) + [demo app](https://github.com/bhserna/dynamic_data_grid_hotwire_ransack) (2022; pre-Turbo-8 and pre-pagy-43, but the frame+autosubmit structure is still correct) · [ransack](https://github.com/activerecord-hackery/ransack) · [has_scope](https://github.com/heartcombo/has_scope) · [stimulus-components auto-submit](https://www.stimulus-components.com/docs/stimulus-auto-submit) · **superseded:** [filterrific](https://github.com/jhund/filterrific) (jQuery-era).

---

### Inline editing of a cell / row

**Hotwire answer.** One Turbo Frame per editable cell, id'd `dom_id(record, :field)`. The show partial renders the value plus an edit link; `#edit` renders the *same frame id* containing a form; `#update` re-renders the show partial in that frame. **No JS for the core loop** — add `hotkey` for Escape-to-cancel and `autosubmit` for save-on-blur. This is the direct, better replacement for `best_in_place`, which is jQuery-based, last meaningfully released in 2020, and should not be used.

**Code.**

```erb
<%# app/views/posts/_post.html.erb %>
<%= tag.tr id: dom_id(post) do %>
  <td><%= render "posts/fields/title",  post: post %></td>
  <td><%= render "posts/fields/status", post: post %></td>
  <td><%= post.author.name %></td>
<% end %>
```

```erb
<%# app/views/posts/fields/_title.html.erb — the SHOW state %>
<%= turbo_frame_tag dom_id(post, :title) do %>
  <span class="value"><%= post.title %></span>
  <%= link_to "Edit",
        edit_field_post_path(post, field: :title),
        class: "edit-link",
        aria: { label: "Edit title of #{post.title}" } %>
<% end %>
```

```erb
<%# app/views/posts/fields/_title_form.html.erb — the EDIT state, SAME frame id %>
<%= turbo_frame_tag dom_id(post, :title) do %>
  <%= form_with model: post, url: post_path(post), method: :patch,
        data: { controller: "autosubmit" } do |f| %>
    <%= f.label :title, class: "sr-only" %>
    <%= f.text_field :title, autofocus: true,
          data: { action: "blur->autosubmit#submit" },
          aria: { describedby: (dom_id(post, :title_error) if post.errors[:title].any?) } %>

    <%= f.submit "Save" %>
    <%= link_to "Cancel", post_path(post, field: :title),
          data: { hotkey: "escape" } %>

    <% if post.errors[:title].any? %>
      <p id="<%= dom_id(post, :title_error) %>" role="alert"><%= post.errors[:title].to_sentence %></p>
    <% end %>
  <% end %>
<% end %>
```

```ruby
# config/routes.rb
resources :posts do
  member { get :edit_field }
end

# app/controllers/posts_controller.rb
FIELDS = %w[title status published_at].freeze   # allowlist: `field` names a partial

def edit_field
  @post  = Post.find(params[:id])
  field  = params[:field].to_s.presence_in(FIELDS) or return head :bad_request
  render partial: "posts/fields/#{field}_form", locals: { post: @post }
end

def show                      # doubles as "cancel": re-renders the show frame
  @post  = Post.find(params[:id])
  return super unless params[:field].in?(FIELDS)
  render partial: "posts/fields/#{params[:field]}", locals: { post: @post }
end

def update
  @post = Post.find(params[:id])
  field = params[:field].presence_in(FIELDS) || FIELDS.first

  if @post.update(post_params)
    render partial: "posts/fields/#{field}", locals: { post: @post }
  else
    render partial: "posts/fields/#{field}_form",
           locals: { post: @post }, status: :unprocessable_content
  end
end
```

`status: :unprocessable_content` is required for Turbo to render the form response instead of discarding it (Rack 3.1 renamed 422; `:unprocessable_entity` is a deprecated alias — never write it). See [02-turbo-deep-dive §2.10](../notes/02-turbo-deep-dive.md).

Note the frame id is `dom_id(post, :title)` → `title_post_1`. Because both the show partial and the form partial declare the same id, `#update` needs no stream and no `respond_to` — the frame swap is automatic.

**Making it feel instant.** The round trip to `#edit_field` is 50–200 ms of nothing happening after the click. Two ways to kill it:

1. **Eager-render the form, hidden.** Render both states in the cell and toggle with `disclosure`. Zero latency, but you pay N forms of HTML on the index page — fine for 25 rows and 2 editable fields, not fine for 500 × 10. This is the right default for small tables.
   ```erb
   <div data-controller="disclosure">
     <div data-disclosure-target="summary">
       <span><%= post.title %></span>
       <button data-action="disclosure#toggle" aria-expanded="false"
               aria-controls="<%= dom_id(post, :title_form) %>">Edit</button>
     </div>
     <div id="<%= dom_id(post, :title_form) %>" data-disclosure-target="content" hidden>
       <%= render "posts/fields/title_form", post: post %>
     </div>
   </div>
   ```
2. **Keep the frame but prefetch.** `data-turbo-prefetch` is on by default for links, so hovering the Edit link already warms `#edit_field`. Verify the action is cheap and idempotent.

**Escape to cancel.** The Cancel link is a real link back to the show state; `hotkey` just clicks it:

```js
// app/javascript/controllers/hotkey_controller.js (excerpt — see the forms/keyboard section)
// data-hotkey="escape" on a link/button → Escape clicks it while focus is inside the controller scope.
```
Prefer this to a `keydown->something#cancel` action, because it keeps the cancel path working for mouse users and for people who tab to it.

**Save on blur.** `data-action="blur->autosubmit#submit"` above. Two caveats: blurring toward the Cancel link submits before the cancel fires (use `mousedown` on Cancel, or `relatedTarget` checks), and blur-save with a validation error leaves the user with an error they didn't ask for. Blur-save is right for a spreadsheet-ish grid, wrong for anything with real validation. **Default to an explicit Save button.**

**Multiple rows editing at once.** Frames make this free — each cell is an independent frame with its own id and its own in-flight request. Nothing to do. Two constraints: (a) don't wrap the whole table in one frame *and* the cells in frames and expect the outer one not to interfere (nested frames navigate independently, but a reload of the outer one blows away every open editor — see [02-turbo-deep-dive §3.5](../notes/02-turbo-deep-dive.md)); (b) a page-level morph refresh triggered by *another user's* edit will close every open editor unless the editing cells are `data-turbo-permanent`.

**The morph-based alternative.** Turbo 8 lets you skip the second route entirely: put the edit state in the URL, and let a morphing refresh swap the cell.

```erb
<%# index.html.erb, with <meta name="turbo-refresh-method" content="morph"> in the layout %>
<td>
  <% if params[:editing] == dom_id(post, :title) %>
    <%= render "posts/fields/title_form", post: post %>
  <% else %>
    <%= link_to post.title, posts_path(request.query_parameters.merge(editing: dom_id(post, :title))),
          data: { turbo_action: "advance" } %>
  <% end %>
</td>
```
Editing state is a URL, so it's shareable and Back-able; morphing preserves scroll and the rest of the DOM; `#update` is a plain `redirect_to posts_path`. **Cost:** a full page render per open/close, and only one cell can be open at a time (unless you make `editing` an array). **Use it when** the table is small, the page is cheap, and you value having no extra routes. **Use frames when** multiple simultaneous editors matter or the index query is expensive.

**Decomposition.**
- Core: none (Turbo Frame).
- `hotkey` — Escape clicks Cancel.
- `autosubmit` — save on blur/change (optional, opinionated).
- `disclosure` — the eager-rendered instant variant.
- `dirty-form` — warn before navigating away with unsaved cell edits.

**A11y.**
- Focus must land in the input when the form renders: `autofocus: true` works on frame render because the element is newly inserted. (Turbo does not manage focus for frames; `autofocus` is the browser doing it.)
- On cancel/save, focus is lost to `<body>`. Return it to the Edit link: give the show-state link a stable id and focus it in a `turbo:frame-load` listener, or use `autofocus` on the Edit link in the show partial (crude but effective).
- Escape must cancel. Not optional — it is the expected key for "get me out of this editor".
- Validation errors: `role="alert"` on the message and `aria-describedby` from the input, as above.
- Give the Edit link an accessible name that includes the record (`"Edit title of Foo"`), or a screen-reader user hears "Edit, Edit, Edit, Edit" down the column.
- APG: this is not a grid unless you make it one. If you want arrow-key cell navigation, you have opted into the [grid pattern](https://www.w3.org/WAI/ARIA/apg/patterns/grid/) and all of its keyboard requirements — don't do that accidentally.

**Native.** Small inline text fields inside a webview are a poor native experience (the keyboard covers the row, there's no Done button). Route edits to a native modal screen via path configuration (`context: "modal"`, `modal_style: "medium"`), or accept the web form. `pull_to_refresh_enabled: false` on edit routes.

**Pitfalls.**
- **The frame id must match exactly** between show and edit partials. `dom_id(post, :title)` in both. A mismatch gives you "Content missing" ([02-turbo-deep-dive §3.6](../notes/02-turbo-deep-dive.md)).
- `<turbo-frame>` inside a `<td>` is fine; inside a `<tr>` between cells is not — the parser hoists it. Frame goes *inside* the `<td>`.
- The `field` param names a partial path. **Allowlist it** or you have a local file disclosure / template injection bug. The code above uses `FIELDS`.
- Validation failure must respond `:unprocessable_content`, or Turbo throws the response away and the user sees nothing happen.
- `form_with` defaults to remote and will submit inside the frame — that's what you want. But if the form is inside a frame *and* you want a full-page redirect on success, you need `data: { turbo_frame: "_top" }` on the form.
- Don't render the edit form for every cell of a 1000-row table "for speed". Measure the HTML size.

**Prior art.** **Superseded:** [best_in_place](https://github.com/bernat/best_in_place) (4.0.0, jQuery, effectively unmaintained) · [x-editable](https://vitalets.github.io/x-editable/) (dead). Current: plain Turbo Frames as documented in [Turbo handbook — Frames](https://turbo.hotwired.dev/handbook/frames), [hotrails.dev Turbo Rails course](https://www.hotrails.dev/turbo-rails) (structurally right; its stream-per-CRUD-action chapters are superseded by morphing), [Rails Designer components](https://railsdesigner.com/).

---

### Bulk selection + bulk actions toolbar

**Hotwire answer.** The `selection` primitive: one Stimulus controller managing a header checkbox with indeterminate state, per-row checkboxes, a live count, and a toolbar that enables/disables. The bulk action itself is a plain `<form>` POSTing `ids[]`. The response is a **morphing refresh** unless the page is expensive.

**Code.**

```js
// app/javascript/controllers/selection_controller.js
import { Controller } from "@hotwired/stimulus"

// Generic checkbox-group selection. Extends the stimulus-components checkbox-select-all
// contract with a count output and toolbar enabling — both of which it lacks.
export default class extends Controller {
  static targets = ["all", "item", "count", "toolbar", "scopeAll", "scopeBanner"]
  static values  = { total: Number }   // total matching the current filter, across all pages

  initialize() {
    this.toggleAll = this.toggleAll.bind(this)
    this.refresh   = this.refresh.bind(this)
  }

  allTargetConnected(el)  { el.addEventListener("change", this.toggleAll); this.refresh() }
  itemTargetConnected(el) { el.addEventListener("change", this.refresh);   this.refresh() }
  allTargetDisconnected(el)  { el.removeEventListener("change", this.toggleAll); this.refresh() }
  itemTargetDisconnected(el) { el.removeEventListener("change", this.refresh);   this.refresh() }

  toggleAll(event) {
    this.itemTargets.forEach((cb) => { cb.checked = event.target.checked })
    this.refresh()
  }

  clear() {
    this.itemTargets.forEach((cb) => { cb.checked = false })
    if (this.hasScopeAllTarget) this.scopeAllTarget.checked = false
    this.refresh()
  }

  refresh() {
    const total   = this.itemTargets.length
    const checked = this.selected.length

    if (this.hasAllTarget) {
      this.allTarget.checked       = checked > 0 && checked === total
      this.allTarget.indeterminate = checked > 0 && checked < total
    }

    if (this.hasCountTarget) {
      const n = this.scopeAllSelected ? this.totalValue : checked
      this.countTarget.textContent = n === 0 ? "" : `${n} selected`
    }

    if (this.hasToolbarTarget) {
      this.toolbarTarget.hidden = checked === 0
      this.toolbarTarget.querySelectorAll("button, input[type=submit]")
          .forEach((el) => { el.disabled = checked === 0 })
    }

    // "select all N matching this filter" banner appears only when the page is fully selected
    if (this.hasScopeBannerTarget) {
      this.scopeBannerTarget.hidden = !(checked > 0 && checked === total && total < this.totalValue)
    }
  }

  get selected()        { return this.itemTargets.filter((cb) => cb.checked) }
  get scopeAllSelected() { return this.hasScopeAllTarget && this.scopeAllTarget.checked }
}
```

```erb
<%# app/views/posts/index.html.erb %>
<div data-controller="selection" data-selection-total-value="<%= @count %>">

  <%= form_with url: bulk_posts_path, method: :post, id: "bulk_posts_form",
        data: { selection_target: "toolbar" },
        hidden: true, class: "bulk-toolbar", role: "toolbar",
        aria: { label: "Bulk actions" } do |f| %>

    <output data-selection-target="count" aria-live="polite" aria-atomic="true"></output>

    <%# carry the current filter so "select all matching" works server-side %>
    <% request.query_parameters.except("page").each do |k, v| %>
      <%= hidden_field_tag "filters[#{k}]", v, id: nil %>
    <% end %>

    <%= f.button "Archive", name: "commit_action", value: "archive" %>
    <%= f.button "Delete",  name: "commit_action", value: "destroy",
          data: { turbo_confirm: "Delete the selected posts? This cannot be undone." } %>
    <button type="button" data-action="selection#clear">Clear selection</button>

    <p data-selection-target="scopeBanner" hidden>
      All <%= @posts.size %> on this page are selected.
      <label>
        <input type="checkbox" name="select_all_matching" value="1"
               data-selection-target="scopeAll" data-action="selection#refresh">
        Select all <%= @count %> posts matching the current filter
      </label>
    </p>
  <% end %>

  <table>
    <thead>
      <tr>
        <th scope="col">
          <input type="checkbox" data-selection-target="all"
                 aria-label="Select all posts on this page">
        </th>
        <th scope="col">Title</th>
        <th scope="col">Status</th>
      </tr>
    </thead>
    <tbody id="posts">
      <% @posts.each do |post| %>
        <%= tag.tr id: dom_id(post) do %>
          <td>
            <%# the checkbox lives OUTSIDE the toolbar form; `form=` associates it %>
            <input type="checkbox" name="ids[]" value="<%= post.id %>"
                   form="<%= "bulk_posts_form" %>"
                   data-selection-target="item"
                   aria-label="Select <%= post.title %>">
          </td>
          <td><%= post.title %></td>
          <td><%= post.status.humanize %></td>
        <% end %>
      <% end %>
    </tbody>
  </table>
</div>
```

The `form="…"` attribute is what lets checkboxes scattered through `<tbody>` submit with a toolbar form that lives elsewhere in the DOM — you cannot nest a `<form>` across `<tr>`s. Give the `form_with` an explicit `id: "bulk_posts_form"`.

**"Select all matching the filter, not just this page" — send the filter, never 40,000 ids.**

```ruby
# app/controllers/posts_controller.rb
BULK_ACTIONS = %w[archive destroy publish].freeze

def bulk
  action = params[:commit_action].presence_in(BULK_ACTIONS) or
    return head :bad_request

  scope =
    if params[:select_all_matching] == "1"
      filtered_scope(params.fetch(:filters, {}))      # the same scope builder index uses
    else
      Post.where(id: Array(params[:ids]))
    end

  scope = scope.merge(Post.accessible_by(current_ability))   # authorize! do not skip this

  count = scope.count
  case action
  when "archive" then scope.update_all(archived_at: Time.current)
  when "publish" then scope.update_all(status: :published)
  when "destroy" then scope.destroy_all
  end

  redirect_to posts_path(request.query_parameters.slice(*ALLOWED_FILTER_KEYS)),
              notice: "#{action.humanize}d #{count} posts."
end
```

That `redirect_to` + `<meta name="turbo-refresh-method" content="morph">` is the whole response. Counts, the empty state, pagination, the "3 selected" toolbar (now empty because the checkboxes re-render unchecked) — all correct, because the server re-rendered the truth.

**The stream alternative, and when to use it.**

```erb
<%# app/views/posts/bulk.turbo_stream.erb %>
<% @destroyed_ids.each do |id| %>
  <%= turbo_stream.remove "post_#{id}" %>
<% end %>
<%= turbo_stream.update "results_count" do %><%== @pagy.info_tag %><% end %>
<%= turbo_stream.update "flash" do %><%= render "shared/flash" %><% end %>
```

**Decision:** use streams only when the index page is expensive to render *and* the number of removed rows is small. Deleting 300 rows means 300 `<turbo-stream>` elements — a morph is one render and one diff, and it fixes the row count, the pagination links, and the empty state, none of which the stream version does. See the decision rule at the top. (`turbo_stream.remove` also cannot backfill the page from page 2, so after a bulk delete the stream version leaves you looking at 7 rows on a 25-per-page table.)

**Decomposition.**
- `selection` (the controller above)
- `dialog` + `focus-trap` + `dismiss` if you replace `data-turbo-confirm` with a real confirm dialog — see the `confirm` primitive
- `confirm` — promise-returning `Turbo.config.forms.confirm` replacement (never `Turbo.setConfirmMethod()`, which is removed)

**A11y.**
- The count **must** be announced: `<output aria-live="polite" aria-atomic="true">3 selected</output>`. `<output>` already has an implicit live region in most AT, but be explicit.
- `indeterminate` is a **DOM property, not an attribute** — it does not survive a server render. Every checkbox-select-all implementation that sets it must re-apply it on connect (the controller above does, via `itemTargetConnected` → `refresh`). Screen readers announce it as "mixed"; `aria-checked="mixed"` is only for `role="checkbox"` elements, not native inputs — leave native inputs alone and just set `.indeterminate`.
- Every row checkbox needs an accessible name that identifies the row (`aria-label="Select <title>"`), not "Select".
- The toolbar is `role="toolbar"` with `aria-label` — and if it has 3+ controls, [APG toolbar](https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/) says arrow keys should move between them (`roving-focus`).
- `hidden` on the toolbar (not `display:none` via a class) keeps it out of the a11y tree and out of tab order.
- Shift-click range selection is a power-user expectation; it must not be the *only* way to select a range.
- APG: [checkbox](https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/) (tri-state section), [table](https://www.w3.org/WAI/ARIA/apg/patterns/table/).

**Native.** Multi-select in a webview table is poor on touch. This is a good candidate for a native selection mode (bridge component) that toggles a CSS class on the web view and collects ids, or for simply not offering bulk actions on mobile. `data-turbo-confirm` maps to a native alert if you've wired the confirm bridge component.

**Pitfalls.**
- **Selection does not survive pagination.** Checking 5 rows, going to page 2, checking 3 more — the first 5 are gone, because the DOM was replaced. Either accept it (and say so in the UI: "5 selected on this page"), or `persist` the id set in `sessionStorage` and re-apply on connect. Don't fake it with hidden fields you forget to clean up.
- **Never send 40,000 ids.** Rack's default form limits (`Rack::Utils.multipart_part_limit`, param depth, and most reverse proxies' request-size caps) will bite, and the URL/body is enormous. Send `select_all_matching=1` plus the filter.
- **Re-authorize on the server.** The ids came from the client. `scope.merge(accessible_by(current_ability))` or equivalent, every time.
- `update_all` / `destroy_all` skip callbacks / are slow respectively. `update_all` won't touch `updated_at` unless you include it; `destroy_all` instantiates every record. Pick deliberately.
- A bulk action is a non-GET form: it must redirect with **303 See Other** for Turbo (`redirect_to` in Rails already does this for Turbo-aware responses; verify — see [02-turbo-deep-dive §2.10](../notes/02-turbo-deep-dive.md)).
- After the redirect+morph, the header checkbox's `indeterminate` state is stale unless `refresh()` re-runs. Under morph, nodes morphed in place do **not** re-run `connect()` ([§5.8](../notes/02-turbo-deep-dive.md)) — but `itemTargetConnected` *does* fire for added/removed rows. If the row set is unchanged, add a `turbo:morph` listener that calls `refresh()`.

**Prior art.** [@stimulus-components/checkbox-select-all](https://www.stimulus-components.com/docs/stimulus-checkbox-select-all) — real source: targets `checkboxAll` / `checkbox`, a `disableIndeterminate` boolean value, and `refresh()` setting `.indeterminate`; it has **no** count output and **no** toolbar handling, which is why the primitive above extends it · [tailwindcss-stimulus-components](https://github.com/excid3/tailwindcss-stimulus-components) · [turbo_power](https://github.com/marcoroth/turbo_power) for extra stream actions if you go the stream route.

---

### Drag-and-drop reordering (SortableJS + position persistence)

**Hotwire answer.** The `sortable` primitive: a Stimulus controller wrapping [SortableJS](https://github.com/SortableJS/Sortable) (1.15.7) whose `onEnd` PATCHes the new order to a `positions` endpoint. Server side, the [`positioning`](https://github.com/brendon/positioning) gem (0.4.8). **The response is `head :no_content`.** A keyboard alternative is mandatory, not optional.

**Code.**

```js
// app/javascript/controllers/sortable_controller.js
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"
import { FetchRequest } from "@rails/request.js"

export default class extends Controller {
  static values = {
    url:       String,                                   // batch endpoint
    group:     String,                                   // set to share items across lists
    handle:    String,
    animation: { type: Number, default: 150 },
    param:     { type: String, default: "position" }
  }

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: this.animationValue,
      handle:    this.handleValue || undefined,
      group:     this.hasGroupValue ? { name: this.groupValue, pull: true, put: true } : undefined,
      ghostClass: "sortable-ghost",
      chosenClass: "sortable-chosen",
      onEnd: this.#persist
    })
  }

  disconnect() {
    this.sortable?.destroy()
    this.sortable = null
  }

  // Send the whole order, not one item. Idempotent, survives dropped requests,
  // and costs one query on the server instead of N.
  #persist = async ({ oldIndex, newIndex, from, to }) => {
    if (from === to && oldIndex === newIndex) return   // dropped where it started

    const ids = Array.from(this.element.children)
      .map((el) => el.dataset.sortableId)
      .filter(Boolean)

    const body = new FormData()
    ids.forEach((id) => body.append("ids[]", id))

    const response = await new FetchRequest("patch", this.urlValue, {
      body, responseKind: "html"    // NOT "turbo-stream" — see below
    }).perform()

    if (!response.ok) {
      // The server rejected it. Reload the list rather than leaving the DOM lying.
      const frame = this.element.closest("turbo-frame")
      frame ? frame.reload() : window.location.reload()
    }
  }
}
```

```erb
<%# app/views/lists/show.html.erb %>
<%= turbo_frame_tag dom_id(@list, :items), refresh: "morph", src: list_path(@list) do %>
  <ul data-controller="sortable"
      data-sortable-url-value="<%= reorder_list_items_path(@list) %>"
      data-sortable-handle-value=".drag-handle">
    <% @list.items.each do |item| %>
      <li id="<%= dom_id(item) %>" data-sortable-id="<%= item.id %>">
        <span class="drag-handle" aria-hidden="true" data-turbo-permanent>⠿</span>
        <%= item.name %>

        <%# THE KEYBOARD ALTERNATIVE — required %>
        <span class="reorder-buttons">
          <%= button_to "Move up", move_up_list_item_path(@list, item), method: :patch,
                disabled: item.position == 1,
                form: { data: { turbo_frame: dom_id(@list, :items) } },
                aria: { label: "Move #{item.name} up" } %>
          <%= button_to "Move down", move_down_list_item_path(@list, item), method: :patch,
                disabled: item == @list.items.last,
                form: { data: { turbo_frame: dom_id(@list, :items) } },
                aria: { label: "Move #{item.name} down" } %>
        </span>
      </li>
    <% end %>
  </ul>
<% end %>
```

```ruby
# app/models/item.rb
class Item < ApplicationRecord
  belongs_to :list
  positioned on: :list          # `positioning` gem; column `position`, NOT NULL,
                                # with a unique index on [list_id, position]
end
```

```ruby
# app/controllers/items_controller.rb
class ItemsController < ApplicationController
  before_action :set_list

  # PATCH /lists/:list_id/items/reorder
  def reorder
    ids = Array(params[:ids]).map(&:to_i)
    items = @list.items.where(id: ids).index_by(&:id)
    return head :unprocessable_content unless items.size == ids.size

    Item.transaction do
      ids.each_with_index { |id, index| items[id].update!(position: index + 1) }
    end

    head :no_content            # <<<<<< THE IMPORTANT LINE
  end

  # The keyboard path. Full HTML/frame response is correct here — nothing has
  # moved in the DOM yet, so re-rendering is not fighting anyone.
  def move_up
    item = @list.items.find(params[:id])
    item.update!(position: { before: item.prior_position })
    redirect_to @list
  end
end
```

**Why `head :no_content` and not a Turbo Stream.** SortableJS has *already moved the node*. If you respond with a stream (or a frame render) that re-renders the list, Turbo replaces the DOM Sortable just mutated. Best case you get a visible flash as the list re-paints; worst case you get a race — the response lands mid-animation, Sortable's internal references point at detached nodes, and the next drag throws. **Never re-render the list you just dragged.** The client and server agree already; the response's only job is to say so. `responseKind: "html"` on the FetchRequest (the default) means the body is ignored even if you accidentally send one — but send nothing.

If the reorder *changes something else* (a total, a "last updated" stamp), update that one thing with a targeted stream and leave the list alone:
```ruby
render turbo_stream: turbo_stream.update("list_meta", partial: "lists/meta", locals: { list: @list })
```
and set `responseKind: "turbo-stream"` on the FetchRequest.

**Batch endpoint vs. per-item PATCH.** [`@stimulus-components/sortable`](https://www.stimulus-components.com/docs/stimulus-sortable) uses a **per-item** convention: `data-sortable-update-url` on each `<li>`, `data-sortable-resource-name-value`, `data-sortable-param-name-value` (default `position`), and in `onUpdate` it PATCHes `{resource}[position]=newIndex+1` to that one item's URL ([dist source](https://unpkg.com/@stimulus-components/sortable/dist/stimulus-sortable.mjs)). That works with `acts_as_list`/`positioning`, needs no new route, and is the shortest path to shipping. But it is **not idempotent under packet loss** (one dropped request leaves the list permanently wrong with no way to detect it) and it only handles the moved item, so it cannot express a cross-list move. The batch `ids[]` endpoint above is what I'd ship. Note the different value name: `data-sortable-url-value` (batch, ours) vs. `data-sortable-update-url` (per-item, stimulus-components) — do not mix them up when copying code from the docs.

**positioning vs. acts_as_list.** [`positioning`](https://github.com/brendon/positioning) (0.4.8) is the modern one: sequential integers from 1, all moves in a transaction, a unique index is *supported and recommended*, handles scope changes ("if you move a record from one scope to another, the gap in the position column will be healed in the scope the record is leaving"), and takes `position: 3`, `position: :first`, `position: { before: other }`, `position: { after: 11 }`. [`acts_as_list`](https://github.com/brendon/acts_as_list) (1.2.6, same maintainer) is fine and battle-tested but has a larger, older API surface and looser guarantees about gaps. **Use `positioning` for new code.** Both are strictly better than a hand-rolled `position` integer, because both do the shuffling in a transaction.

**The morph interaction.** If another user's change broadcasts a refresh mid-drag, idiomorph will walk into the list you are currently dragging and rearrange it under the cursor. Mitigations, in order:
1. Put `data-turbo-permanent` on the sortable container while a drag is in progress (add it in `onStart`, remove in `onEnd`). Morph skips `[data-turbo-permanent]` entirely ([`morphing.js`](https://github.com/hotwired/turbo/blob/main/src/core/morphing.js)).
2. Use `refresh="morph"` + `src` on the enclosing frame so the list refetches itself rather than being overwritten by the page morph ([02-turbo-deep-dive §5.4](../notes/02-turbo-deep-dive.md)) — still needs (1) for the mid-drag case.
3. Accept it for single-user lists. Most reorderable lists are single-user.

Also: a node morphed **in place** does not re-run `connect()`, so the Sortable instance survives a morph — good. But if idiomorph decides to *replace* the container (duplicate ids, changed attributes), `disconnect()` → `destroy()` → `connect()` → new Sortable, and any in-flight drag dies. Keep ids stable and unique.

**Decomposition.**
- `sortable` (SortableJS wrapper, batch PATCH)
- optional `transition` for the drop animation if you want CSS classes rather than SortableJS's `animation`

**A11y — the keyboard alternative is REQUIRED.** Native HTML drag-and-drop and SortableJS's pointer events are **completely unusable** by keyboard-only and screen-reader users. There is no ARIA that fixes this. Shipping drag-only reordering is shipping a feature that a fraction of your users cannot use at all. The obligation:
- **Provide Move up / Move down buttons** on every item (as in the code above), or a "Move to position ⟨number⟩" input, or both. These are ordinary `button_to` forms — no JS, works everywhere, and doubles as the mobile-touch escape hatch.
- Announce the result: `aria-live="polite"` region saying "Moved Foo to position 3 of 8".
- The drag handle itself gets `aria-hidden="true"` if the buttons are the real control; do not make a `<div>` with a grab cursor the only affordance.
- Give the list `<ol>` semantics if the order is meaningful (it is — that's the whole feature).
- Do not use `tabindex` on the `<li>`s to fake keyboard dragging unless you implement the full "grab / arrow / drop / escape" model and announce every step. The buttons are less work and better.

**Native.** SortableJS's touch handling inside a webview conflicts with the native scroll view: a long-press-drag can be interpreted as a scroll, and the frame's own drag is janky at 60fps. Options: `forceFallback: true` + `delay: 200, delayOnTouchOnly: true` in SortableJS (helps a lot), or make reordering a native screen. The Move up/down buttons work perfectly in the webview and are often the right answer on mobile regardless.

**Pitfalls.**
- **Do not return a Turbo Stream that re-renders the list.** Stated three times because it is the #1 bug.
- `disconnect()` must call `sortable.destroy()`. Turbo navigations recreate the controller; without destroy you leak listeners and get double-firing `onEnd`.
- The `position` column must be `NOT NULL` with a unique index on `[scope_id, position]`. Without the index, concurrent reorders silently produce duplicates. `positioning` uses `0` and negative integers internally while shuffling, so **do not add a `CHECK (position > 0)` constraint**.
- Send `ids[]` in the new visual order and derive positions server-side. Sending client-computed positions means trusting the client with your ordering integrity.
- Validate that every submitted id belongs to the scope (`items.size == ids.size` above), or a user reorders someone else's list.
- SortableJS `onUpdate` fires only for **intra-list** moves; `onAdd` fires on the receiving list for cross-list moves. If you use `onUpdate` (as stimulus-components does), cross-list drags silently do nothing. Use `onEnd`.
- Filtered/paginated lists: dragging item 3 of page 2 to the top means position 26, not 1. Either disable dragging when a filter or sort is active, or compute the offset. The batch endpoint above assumes the DOM contains the whole list.
- `overflow: hidden` ancestors and CSS transforms break SortableJS's ghost positioning. `forceFallback: true` is the usual fix.

**Prior art.** [SortableJS](https://github.com/SortableJS/Sortable) 1.15.7 · [@stimulus-components/sortable](https://www.stimulus-components.com/docs/stimulus-sortable) · [positioning](https://github.com/brendon/positioning) 0.4.8 · [acts_as_list](https://github.com/brendon/acts_as_list) 1.2.6 · [ranked-model](https://github.com/brendon/ranked-model) · [@rails/request.js](https://github.com/rails/request.js) · **superseded:** `jquery-ui-sortable`, `acts_as_list` + `rails-ujs` `remote: true` recipes, [dragula](https://github.com/bevacqua/dragula) (unmaintained).

---

### Kanban board

**Hotwire answer.** The same `sortable` primitive with a shared `group` name across columns, PATCHing **both** the destination column id and the new position; broadcast a refresh to other users. Hotwire gets you a working single-user board in about 60 lines and a *nearly* working multi-user board. Conflict resolution is where it stops.

**Code.**

```erb
<%# app/views/boards/show.html.erb %>
<%= turbo_stream_from @board %>

<div class="board" id="<%= dom_id(@board) %>">
  <% @board.columns.each do |column| %>
    <section class="column" aria-labelledby="<%= dom_id(column, :heading) %>">
      <h2 id="<%= dom_id(column, :heading) %>"><%= column.name %>
        <span aria-live="polite"><%= column.cards.size %></span>
      </h2>

      <ul id="<%= dom_id(column, :cards) %>"
          data-controller="sortable"
          data-sortable-group-value="cards"
          data-sortable-url-value="<%= board_moves_path(@board) %>"
          data-column-id="<%= column.id %>">
        <%= render column.cards %>
      </ul>
    </section>
  <% end %>
</div>
```

```js
// app/javascript/controllers/kanban_sortable_controller.js
// Extends the generic `sortable` primitive: same wrapper, different payload.
import { FetchRequest } from "@rails/request.js"
import SortableController from "./sortable_controller"

export default class extends SortableController {
  async persist({ item, to }) {
    const body = new FormData()
    body.append("card_id",   item.dataset.sortableId)
    body.append("column_id", to.dataset.columnId)
    body.append("position",  Array.from(to.children).indexOf(item) + 1)

    const response = await new FetchRequest("patch", this.urlValue, { body, responseKind: "html" }).perform()
    if (!response.ok) window.location.reload()
  }
}
```
(In practice, make `sortable`'s payload builder overridable — a `#buildBody(event)` method the subclass replaces — rather than duplicating `#persist`.)

```ruby
# app/models/card.rb
class Card < ApplicationRecord
  belongs_to :column
  positioned on: :column                   # `positioning` heals both lists on a scope change
  broadcasts_refreshes_to ->(card) { card.column.board }
end

# app/controllers/moves_controller.rb
class MovesController < ApplicationController
  def create
    board  = Board.find(params[:board_id])
    card   = board.cards.find(params[:card_id])
    column = board.columns.find(params[:column_id])

    card.update!(column: column, position: params[:position].to_i)

    head :no_content     # again: do NOT re-render the columns you just dragged
  end
end
```

`positioning` does the hard part: "If you move a record from one scope to another, the gap in the position column will be healed in the scope the record is leaving, and by default the record will be added to the end of the list in the new scope" — and `card.update!(column: other, position: 3)` moves *and* inserts at 3 in one transaction ([README, Scopes](https://github.com/brendon/positioning#scopes)).

**Broadcasting to other users.** `broadcasts_refreshes_to` sends `<turbo-stream action="refresh" request-id="…">`. The **actor's own tab ignores it** because Turbo remembers the request ids it issued ([02-turbo-deep-dive §5.5](../notes/02-turbo-deep-dive.md)) — which is exactly what you want, since the actor's DOM is already correct and a re-render would fight SortableJS. Everyone else's board morphs to the new truth. This is the single best argument for morphing over hand-written streams on a Kanban board: the observer's page has *many* things that changed (two column card-counts, two lists, possibly a WIP-limit warning) and morph re-derives all of them from one render.

Add `<meta name="turbo-refresh-scroll" content="preserve">` so a board that scrolls horizontally doesn't snap back.

**The concurrent-drag conflict problem — an honest assessment.**

Two users drag the same card, or two different cards into the same slot, within a second of each other:

1. **Last write wins, silently.** Both PATCHes succeed. `positioning`'s transaction keeps positions internally consistent (no duplicates, no gaps), so you never get corrupt data — that's real and valuable. But user A sees their move undone by B's broadcast, with no explanation.
2. **The broadcast lands while A is mid-drag.** Idiomorph rearranges the column under A's cursor. Mitigation as in the reorder pattern: `data-turbo-permanent` on the column during a drag. Turbo's 150 ms client debounce + 0.5 s server debounce ([§5.5](../notes/02-turbo-deep-dive.md)) absorb bursts but not a drag that lasts three seconds.
3. **A stale board produces a nonsense move.** A drags a card that B already moved to another column. `card.update!(column:, position:)` succeeds anyway and the card lands somewhere neither user intended.

**How far Hotwire gets you:** to a board that is *eventually consistent and never corrupt*, with no client state machine and no reconciliation layer. That covers a team of five on a project board. It does not cover a high-contention board.

**What to add when you need more,** in increasing order of effort:
- **Optimistic locking.** `lock_version` on `Card`; the client sends the version it saw; a `StaleObjectError` → `head :conflict` → the client reloads the board and shows "Someone else moved this card." ~15 lines, kills failure mode 3.
- **Send the intent, not the index.** PATCH `{ after_card_id: "card_17" }` instead of `position: 3` (`positioning` accepts `position: { after: 17 }` natively). Relative intent survives a concurrent insert; an absolute index does not. **Do this — it is nearly free and it is the single highest-value change.**
- **Presence / "B is dragging this card"** — a `turbo_stream_from` channel plus a CSS class. Prevents most conflicts socially rather than technically.
- **Real CRDT/OT.** Out of scope for Hotwire and out of scope for most products. If you genuinely need it, you are building Figma, and this is the point where a client-side state library earns its cost.

**Verdict: Hotwire ships a good Kanban board. It does not ship real-time conflict resolution, and neither does any framework — but the "send relative intent + optimistic locking" combination gets you 95% of the way for a day's work.**

**Decomposition.**
- `sortable` (with `group`) per column
- `dialog` + `focus-trap` for the card detail modal (see the overlays section)
- optional `intersection` if columns paginate

**A11y.** Everything from the reorder pattern applies and is *more* important here, because there are two axes. Requirements: each column is a `<section aria-labelledby>` with an `<ol>`; each card exposes a **"Move to column…"** control (a `<select>` in a `button_to` form, or a `menu`) **and** up/down buttons — a card must be movable between columns without a pointer. Announce moves in an `aria-live="polite"` region ("Moved Design review to In progress, position 2 of 5"). Column card counts in a live region so a screen-reader user notices remote changes. APG: [grid](https://www.w3.org/WAI/ARIA/apg/patterns/grid/) if you implement 2-D arrow navigation (a genuinely good fit for a board, and a lot of work); [toolbar](https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/) for the per-card action cluster.

**Native.** A horizontally-scrolling board of vertically-scrolling columns with drag-and-drop inside a webview is the worst case for gesture conflict. Either build the board natively, or on mobile render a single-column "list per status with a status picker" — which is also the better mobile UX. Do not ship webview Kanban drag to phones.

**Pitfalls.**
- `group: { name: "cards", pull: true, put: true }` — a bare `group: "cards"` string works but you'll want the object as soon as you need a read-only column.
- Empty columns need a **minimum height** and must remain drop targets. A zero-height `<ul>` cannot receive a drop. `min-height: 4rem` on the list, not the section.
- `onEnd` fires on the **source** list's Sortable instance with `to`/`from`; `onUpdate` does not fire at all for cross-list moves. Use `onEnd`.
- WIP limits enforced server-side must return an error the client can act on — `head :unprocessable_content` and reload; the card is already visually in the wrong column.
- Two models broadcasting to the same stream (`Board` and `Card`) produce two broadcasts; they debounce independently ([§5.8 #8](../notes/02-turbo-deep-dive.md)). Pick one broadcaster.
- Card partials rendered by a broadcast are rendered **without a request context** — `current_user` is nil. Anything user-specific on a card breaks under `broadcasts_refreshes`; that's fine here because refresh makes each observer re-fetch the page *as themselves* ([§5.8 #9](../notes/02-turbo-deep-dive.md)) — but it is exactly why `broadcast_replace_to` with a per-user partial is the wrong tool.

**Prior art.** [SortableJS shared groups](https://github.com/SortableJS/Sortable#group-option) · [positioning](https://github.com/brendon/positioning) · [turbo-rails `broadcasts_refreshes`](https://github.com/hotwired/turbo-rails) · [Radan Skorić's writing on Hotwire architecture](https://radanskoric.com/) · [Marco Roth's blog](https://marcoroth.dev/) for stream internals.

---

### Tree / nested list

**Hotwire answer.** Recursive partials plus `<details>`/`<summary>` (or the `disclosure` primitive when you need controlled state and `persist`ed expansion). **No JS needed** for a read-only or link-navigated tree. Reordering a tree is SortableJS with nested shared groups and is meaningfully harder than a flat list.

**Code.**

```erb
<%# app/views/categories/_category.html.erb — recursive %>
<li>
  <% if category.has_children? %>
    <details data-controller="persist" data-persist-key-value="cat-<%= category.id %>">
      <summary><%= link_to category.name, category_path(category) %></summary>
      <ul role="group">
        <%= render partial: "categories/category", collection: category.children.ordered, as: :category %>
      </ul>
    </details>
  <% else %>
    <%= link_to category.name, category_path(category) %>
  <% end %>
</li>
```

```ruby
class Category < ApplicationRecord
  has_ancestry cache_depth: true       # `ancestry` 5.1.0
  scope :ordered, -> { order(:position) }
end

# Load the whole tree in one query and arrange in memory — the N+1 here is brutal otherwise.
@tree = Category.includes(:children).arrange(order: :position)
```

`ancestry` (5.1.0) stores a materialized path (`1/4/17`) — one query for a subtree, cheap reads, writes rewrite descendants. `closure_tree` (9.8.0) keeps a hierarchy join table — more storage, faster arbitrary ancestor queries, better for deep/wide trees you query sideways. **`ancestry` for menus, categories, comment threads; `closure_tree` for org charts and permission hierarchies.**

For **lazy** subtrees (a file browser with thousands of nodes), each `<summary>` toggles a lazy frame:
```erb
<details>
  <summary><%= node.name %></summary>
  <%= turbo_frame_tag dom_id(node, :children), src: node_path(node, only: :children), loading: :lazy %>
</details>
```
Turbo's lazy frames load on *appearance in viewport*, and a closed `<details>` subtree is not visible — so it loads exactly when opened. Nice property, no JS.

**Nested reordering** is SortableJS with the same `group` name on every `<ul>` at every level, plus `fallbackOnBody` and `swapThreshold: 0.65`. On drop, send `{ id, parent_id, position }`; server does `node.parent = new_parent; node.position = index + 1`. Expect to fight it: drop targets between levels are ambiguous, and empty-child-list drop zones need min-height at every level. If reordering is a core feature, evaluate [SortableJS's nested demo](https://sortablejs.github.io/Sortable/#nested) carefully before committing.

**Decomposition.** `disclosure` (or native `<details>`) · `persist` (remember expanded nodes) · `sortable` with `group` (reorderable trees) · `roving-focus` (if you implement the real treeview pattern).

**A11y.** Native `<details>`/`<summary>` gives correct expand/collapse semantics for free and is the right default. A **real** [APG treeview](https://www.w3.org/WAI/ARIA/apg/patterns/treeview/) is a different, heavier contract: `role="tree"` / `role="treeitem"` / `role="group"`, `aria-expanded`, `aria-level`, `aria-setsize`, `aria-posinset`, a single tab stop with roving tabindex, arrow keys (Right expands/descends, Left collapses/ascends), Home/End, and typeahead. **Only adopt `role="tree"` if you implement all of it** — a half-built tree is worse than a nested `<ul>` of links, which is already perfectly accessible. See also [disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/).

**Native.** Deeply nested webview trees scroll badly on phones. Prefer drill-down navigation (one level per screen, pushed via path configuration) — it is both the native idiom and simpler HTML.

**Pitfalls.**
- `arrange` without `includes` is an N+1 per node. Load once, arrange in memory.
- `ancestry` writes rewrite every descendant's path — moving a top-level node with 10,000 descendants is a big UPDATE. Do it in a background job.
- `<details>` open state is lost on every Turbo navigation. `persist` it, or use a morphing refresh (morph preserves the `open` attribute because it preserves the node).
- Recursive partials are easy to blow up: cap depth and render-cache aggressively (`cache category do`).
- Cycle prevention: validate that a node's new parent is not its own descendant, server-side.

**Prior art.** [ancestry](https://github.com/stefankroes/ancestry) 5.1.0 · [closure_tree](https://github.com/ClosureTree/closure_tree) 9.8.0 · [SortableJS nested lists](https://sortablejs.github.io/Sortable/#nested) · [@github/details-menu-element](https://github.com/github/details-menu-element) for `<details>`-based menus.

---

### Virtualized long lists

**Hotwire answer.** Server-driven pagination is the Hotwire answer, and for a genuinely long list it is the *correct* answer, not a consolation prize. For the middle case — 500–5,000 rows you legitimately want in one DOM — **CSS `content-visibility: auto` + `contain-intrinsic-size` gets you most of the win with zero JavaScript.** True windowed virtualization (render only the visible slice, recycle nodes) fights Turbo's DOM ownership and has no good Hotwire story.

**Code — the 90% solution, no JS.**

```css
.row {
  content-visibility: auto;
  contain-intrinsic-size: auto 48px;   /* "auto" = remember the real size once measured */
}
```

That's it. The browser skips layout, paint, and style for off-screen rows; `contain-intrinsic-size` supplies a placeholder size so the scrollbar doesn't lie, and the `auto` keyword makes the browser remember each element's last-rendered size instead of using the fallback forever.

**Support (verified against [MDN browser-compat-data](https://github.com/mdn/browser-compat-data/blob/main/css/properties/content-visibility.json)):** Chrome 85, Firefox 125, Safari 18. All shipped by September 2024, so it is safe in 2026 — and it degrades to "nothing happens", which is the ideal failure mode for a performance hint.

**The caveat that will bite you:** CSS containment **does not apply to internal table elements** (`display: table-row`, `table-row-group`, `table-cell`). `content-visibility: auto` on a `<tr>` is a **no-op**. If you want this on a table, you must either use a CSS-grid/flex "table" of `<div>`s (and then supply the table semantics with ARIA roles — `role="table"`/`row`/`cell`, which is a real accessibility cost), or apply it to chunk wrappers rather than rows. Chunking is the pragmatic move:

```erb
<%# div-based list: chunk wrappers ARE containable %>
<% @rows.each_slice(50) do |chunk| %>
  <div class="chunk" role="rowgroup"><%= render chunk %></div>
<% end %>
```
```css
.chunk { content-visibility: auto; contain-intrinsic-size: auto 2400px; }
```
Multiple `<tbody>` elements in one `<table>` is valid HTML, but a `<tbody>` is still an internal table element, so `content-visibility` is a no-op there too. **For a real `<table>`, the answer is pagination.** Verify in your target browsers before believing any blog post on this.

Other real caveats: in-page find (Ctrl+F) works in Chrome (hidden-but-searchable content is revealed), but `scrollIntoView` on a skipped element and anchor links into skipped content have been buggy across versions; and rows inside a skipped subtree are not accessible to `IntersectionObserver`, which breaks a sentinel placed there.

**Why true virtualization doesn't work here.**

1. **Turbo owns the DOM.** A virtualizer's whole design is that the DOM is a lie it maintains. Turbo Streams target elements by id — but the element with that id isn't rendered. `turbo_stream.remove "post_4823"` silently does nothing. Idiomorph walks a tree that doesn't match the server's HTML and prunes your window.
2. **`data-turbo-permanent` on the scroll container** stops morphing from destroying the virtualizer, but then the container never updates from the server at all, and you have re-invented a client-side data store — at which point you have a React app with extra steps.
3. **The libraries are framework-coupled.** [`virtua`](https://www.npmjs.com/package/virtua) (0.50.1) is excellent but ships React/Vue/Solid/Svelte/Angular adapters — there is no vanilla Stimulus entry point. [`clusterize.js`](https://clusterize.js.org/) (1.0.0) *is* vanilla and does exactly the "swap chunks of rows in and out" job, but its last release was years ago and it wants to own the `innerHTML` of your table body.
4. **You still have to get the rows to the client.** Virtualization saves DOM nodes, not bytes or query time. 50,000 rows of HTML is still 50,000 rows over the wire.

**Verdict: no good Hotwire answer for true windowed virtualization.** What people actually do, in order of how often it's right:
- **Paginate or "load more"** (correct ~90% of the time — if the user is scrolling past 2,000 rows, the UI is wrong, not slow).
- **`content-visibility: auto`** on a div-based list for the 500–5,000 row case.
- **Give the user a filter and a search box** instead of a longer list. This is usually the actual product answer.
- **`clusterize.js` in a Stimulus wrapper with `data-turbo-permanent`** on the container, updating it only through the controller's own API — accepting that this region is now outside Turbo's world. Roughly 100 lines and a permanent maintenance tax.
- **Drop to a real data grid** (see below) if this is a spreadsheet product.

**Decomposition.** None — CSS. If you wrap `clusterize.js`, that is a genuinely new primitive and you are outside the catalog.

**A11y.** Virtualization is an a11y hazard by construction: screen readers cannot reach content that isn't in the DOM, and `aria-setsize`/`aria-posinset` are the only way to communicate the real list length. `content-visibility: auto` is *not* affected — skipped content remains in the accessibility tree and searchable. That asymmetry is a strong argument for the CSS approach.

**Native.** A 5,000-row webview list scrolls badly on mid-range Android regardless of what you do. Paginate, or build the list natively — this is one of the genuine "make it a native screen" cases from [04-hotwire-native §4](../notes/04-hotwire-native.md).

**Pitfalls.** Containment does not apply to table internals (above). `contain-intrinsic-size` with a wrong fixed value makes the scrollbar jump — use the `auto` keyword. Sticky headers inside a contained subtree behave oddly. Don't combine with an infinite-scroll sentinel inside the contained region.

**Prior art.** [MDN `content-visibility`](https://developer.mozilla.org/en-US/docs/Web/CSS/content-visibility) · [web.dev content-visibility guide](https://web.dev/articles/content-visibility) · [clusterize.js](https://clusterize.js.org/) · [virtua](https://github.com/inokawa/virtua) (framework-coupled) · pagy/kaminari for the answer you should actually ship.

---

### Charts (Chart.js via Stimulus)

**Hotwire answer.** The `chart` primitive: a Stimulus controller that reads data from a `<script type="application/json">` block, builds the chart in `connect()`, and — **the part everyone forgets** — calls `chart.destroy()` in `disconnect()`. Use [chartkick](https://chartkick.com/) (5.2.1) when you want a chart in one line of ERB; drop to raw Chart.js (4.5.1) the moment you need custom scales, plugins, mixed types, or annotations.

**Code.**

```erb
<%# app/views/dashboards/show.html.erb %>
<div data-controller="chart"
     data-chart-type-value="line"
     data-turbo-permanent id="revenue_chart_container">
  <canvas data-chart-target="canvas" role="img"
          aria-label="Monthly revenue, January to December 2026. Peak in November at $412,000."></canvas>

  <%# Data as JSON, not as a Stimulus Value: values live in an HTML attribute and a
      year of daily points will blow past attribute-size sanity. %>
  <script type="application/json" data-chart-target="data">
    <%= raw({
          labels: @months,
          datasets: [{ label: "Revenue", data: @revenue, tension: 0.3 }]
        }.to_json) %>
  </script>

  <%# Always provide the numbers as a real table for screen readers. %>
  <details>
    <summary>View data as a table</summary>
    <table>
      <caption>Monthly revenue 2026</caption>
      <thead><tr><th scope="col">Month</th><th scope="col">Revenue</th></tr></thead>
      <tbody>
        <% @months.zip(@revenue).each do |month, value| %>
          <tr><th scope="row"><%= month %></th><td><%= number_to_currency(value) %></td></tr>
        <% end %>
      </tbody>
    </table>
  </details>
</div>
```

```js
// app/javascript/controllers/chart_controller.js
import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

export default class extends Controller {
  static targets = ["canvas", "data"]
  static values  = {
    type:    { type: String, default: "line" },
    options: { type: Object, default: {} }
  }

  connect() {
    this.chart = new Chart(this.canvasTarget, {
      type: this.typeValue,
      data: this.#data,
      options: { responsive: true, maintainAspectRatio: false, ...this.optionsValue }
    })
  }

  // THE LEAK: Chart.js registers a ResizeObserver, a DPR listener and a global
  // instance registry keyed by canvas. Without destroy(), every Turbo navigation
  // leaks a chart, and re-initialising over a live canvas throws
  // "Canvas is already in use. Chart with ID '0' must be destroyed".
  disconnect() {
    this.chart?.destroy()
    this.chart = null
  }

  // Re-read the JSON and update in place when the data block is stream-replaced.
  dataTargetConnected() {
    if (!this.chart) return
    this.chart.data = this.#data
    this.chart.update()
  }

  // Reactive under morphing: a morphed-in-place node does NOT re-run connect(),
  // so option changes must arrive through a value callback.
  optionsValueChanged() {
    if (!this.chart) return
    Object.assign(this.chart.options, this.optionsValue)
    this.chart.update()
  }

  get #data() { return JSON.parse(this.dataTarget.textContent) }
}
```

**Updating on a Turbo Stream replacement.** Two shapes:
- **Replace the whole container** (`turbo_stream.replace "revenue_chart_container"`): `disconnect()` → `destroy()` → `connect()` → new chart. Simple, correct, costs a full chart rebuild and loses any animation continuity. **Ship this unless the rebuild is visible.**
- **Replace only the `<script type="application/json">` data block**: `dataTargetConnected()` fires, the chart updates in place with Chart.js's own animation. Nicer, and the reason the data lives in a target rather than a value.

**The morph problem — verified.** Morphing a `<canvas>` is destructive: idiomorph sees a canvas with no children on both sides, "morphs" it, and the 2D context's contents are gone — while your `chart` controller, having been morphed *in place*, never re-runs `connect()` and therefore never redraws. You get a blank rectangle and no error.

**The fix is `data-turbo-permanent` on a wrapper with a stable `id`.** Turbo's morphing skips any element carrying that attribute (`beforeNodeMorphed` returns early for `[data-turbo-permanent]`, and `[id][data-turbo-permanent]` nodes are never removed — [`src/core/morphing.js`](https://github.com/hotwired/turbo/blob/main/src/core/morphing.js)). The alternative is the event hook:

```js
document.addEventListener("turbo:before-morph-element", (event) => {
  if (event.detail.currentElement.matches("[data-chart-target='canvas'], canvas")) {
    event.preventDefault()   // idiomorph leaves this subtree alone
  }
})
```

**`data-turbo-morph="false"` does not exist.** In Turbo 8.0.23's source the only morph opt-outs are `data-turbo-permanent`, `preventDefault()` on `turbo:before-morph-element`, and `preventDefault()` on `turbo:before-morph-attribute`. Any tutorial that tells you to write `data-turbo-morph="false"` is wrong. See [02-turbo-deep-dive §5.8](../notes/02-turbo-deep-dive.md), gotcha #2, which lists Chart.js canvases explicitly.

Note the trade-off you just accepted: a `data-turbo-permanent` chart **will not update from the server** at all. If the chart's data must change on refresh, don't make it permanent — use the `turbo:before-morph-element` hook on the `<canvas>` only, and let the JSON data block morph normally so `dataTargetConnected` fires. That combination is the one that actually works under morphing.

**Chartkick — the batteries-included answer.**

```erb
<%= line_chart Revenue.group_by_month(:created_at).sum(:amount),
      id: "revenue", height: "300px", library: { tension: 0.3 } %>
```
One line, `groupdate` integration, adapters for Chart.js / Highcharts / Google Charts, `refresh:` for polling a remote endpoint. **Use chartkick when** the chart is a straightforward series over a `group_by_*` aggregate. **Drop to raw Chart.js when** you need custom plugins, annotations, mixed chart types, per-point styling, or precise control over `disconnect()`.

Chartkick's Turbo hygiene is on you: it registers charts in a global `Chartkick.charts` keyed by element id, and inline `<script>` tags do the initialization. The recipe:

```js
// Chartkick's own API: Chartkick.charts[id], chart.updateData(data), chart.setOptions(opts),
// chart.refreshData(), chart.redraw(), chart.destroy(), Chartkick.destroyAll()
document.addEventListener("turbo:before-cache", () => Chartkick.destroyAll())
```
Without that, a cached snapshot contains a canvas whose chart object is gone, and the restore renders a dead chart. Under **morphing**, chartkick is worse off than raw Chart.js: the inline `<script>` won't re-execute, so `data-turbo-permanent` on the chart div is effectively mandatory. **If your app uses morphing refreshes on chart pages, prefer the raw Chart.js + Stimulus controller above** — it has a reactive update path; chartkick's script-tag model does not.

**Decomposition.**
- `chart` (the wrapper above)
- optional `intersection` to defer building off-screen charts (`connect()` on appear)
- optional `persist` for a user's chosen range/granularity

**A11y.** A `<canvas>` is an opaque image to assistive technology. Non-negotiable minimum:
- `role="img"` + a genuinely descriptive `aria-label` on the canvas — describe the *trend and the notable points*, not "a line chart".
- **A real `<table>` of the same numbers**, in a `<details>` next to the chart (as above). This is the only thing that makes the data available, and it costs nothing since you already have the data server-side.
- Never encode meaning in colour alone; Chart.js supports `pointStyle` and dash patterns per dataset.
- Check contrast of series colours in both themes; Chart.js defaults are not accessible on dark backgrounds.
- Tooltips are pointer-only. Anything the tooltip says that the user needs must also be in the table.
- There is no APG pattern for charts. The [WAI chart guidance](https://www.w3.org/WAI/tutorials/images/complex/) treats them as complex images: short label + long description.

**Native.** Charts render fine in a webview. Two things to handle: `maintainAspectRatio: false` plus an explicit container height (webview resizes on rotation and Chart.js's ResizeObserver can loop), and dark mode — read the native theme from the UA / a `prefers-color-scheme` media query and pick colours accordingly. A chart is a reasonable bridge-component candidate if you want native rendering, but rarely worth it.

**Pitfalls.**
- **The `destroy()` leak.** Missing `disconnect()` → "Canvas is already in use" on the second visit. This is the single most common Chart.js + Turbo bug.
- Data in a Stimulus **Value** means the JSON lives in an HTML attribute — fine for 12 points, terrible for 3,650. Use `<script type="application/json">`.
- Under morphing, `connect()` does not re-run for in-place morphs ([§5.8 #3](../notes/02-turbo-deep-dive.md)). All update logic must live in `*ValueChanged` / `*TargetConnected` callbacks, not in `connect()`.
- `data-turbo-permanent` under **replace** transplants the live node (Bardo); under **morph** it simply isn't touched. In both cases the contents stop updating from the server — that's the deal ([§5.8 #7](../notes/02-turbo-deep-dive.md)).
- A canvas inside a lazily-loaded `<turbo-frame>` with `display: none` measures 0×0 and renders nothing. Build the chart on `intersection:appear`, not on connect.
- CSP: chartkick emits inline `<script>`; it reads `content_security_policy_nonce` automatically, but verify in production.
- Chart.js 4 is tree-shakeable; `chart.js/auto` imports everything (~200 KB). Register only the controllers/scales you use if bundle size matters.

**Prior art.** [Chart.js](https://www.chartjs.org/) 4.5.1 · [chartkick](https://chartkick.com/) 5.2.1 + [groupdate](https://github.com/ankane/groupdate) · [ahoy](https://github.com/ankane/ahoy) + [blazer](https://github.com/ankane/blazer) for the dashboard end of this · [stimulus-components chartjs](https://www.stimulus-components.com/) · [ApexCharts](https://apexcharts.com/) if you want built-in annotations/toolbars · [Observable Plot](https://observablehq.com/plot/) for exploratory work.

---

### Export triggers (CSV / PDF / XLSX)

**Hotwire answer.** For a fast export: a plain link with **`data-turbo="false"`** (or `target="_blank"`) to an action that `send_data`s with `Content-Disposition: attachment`. For a slow one: a form that enqueues a job, an `aria-live` status region, and a broadcast that swaps in a real download link when the file is ready. **A Turbo Stream cannot trigger a download** — explanation below.

**Code — the fast path.**

```erb
<%# Preserve the current filters in the export URL — exporting "all records" when the
    user is looking at a filtered table is a bug report waiting to happen. %>
<%= link_to "Export CSV",
      posts_path(request.query_parameters.merge(format: :csv)),
      data: { turbo: false } %>

<%# Equivalent, and arguably better: opening in a new context bypasses Turbo entirely
    and leaves the current page untouched. %>
<%= link_to "Export CSV", posts_path(format: :csv), target: "_blank", rel: "noopener" %>
```

```ruby
# app/controllers/posts_controller.rb
def index
  @posts = filtered_scope          # NOT paginated for the CSV branch

  respond_to do |format|
    format.html { @pagy, @posts = pagy(:offset, @posts, limit: 25) }
    format.csv do
      send_data PostsCsv.new(@posts).to_csv,
                filename: "posts-#{Date.current.iso8601}.csv",
                type: "text/csv; charset=utf-8",
                disposition: "attachment"
    end
  end
end
```

For anything over a few thousand rows, stream it so you don't build the whole string in memory:

```ruby
format.csv do
  headers["Content-Type"]        = "text/csv; charset=utf-8"
  headers["Content-Disposition"] = ActionDispatch::Http::ContentDisposition.format(
    disposition: "attachment", filename: "posts-#{Date.current.iso8601}.csv")
  headers["X-Accel-Buffering"]   = "no"
  headers["Last-Modified"]       = Time.current.httpdate   # defeats Rack::ETag buffering

  self.response_body = Enumerator.new do |yielder|
    yielder << CSV.generate_line(%w[id title status published_at])
    @posts.find_each(batch_size: 1000) do |post|
      yielder << CSV.generate_line([post.id, post.title, post.status, post.published_at])
    end
  end
end
```

**What actually happens without `data-turbo="false"` — verified, and it's not what most posts claim.** Turbo intercepts the click and fetches the URL. The response's content type isn't HTML, so `FetchResponse#responseHTML` is `undefined`, and Turbo records `SystemStatusCode.contentTypeMismatch` (`-2`). `BrowserAdapter#visitRequestFailedWithStatusCode` then handles `contentTypeMismatch` by doing a **full page reload**: `window.location.href = url` ([`browser_adapter.js`](https://github.com/hotwired/turbo/blob/main/src/core/native/browser_adapter.js)). The browser then handles that navigation, sees `Content-Disposition: attachment`, and downloads.

So: **the download usually works anyway** — but you paid for the export **twice** (once into Turbo's fetch, discarded; once for real), the progress bar ran, and `turbo:reload` fired. For a 40 MB XLSX generated by a slow query, that is a real outage-shaped problem. `data-turbo="false"` skips the interception entirely: one request, no progress bar. **Always set it.**

**Why a Turbo Stream can't trigger a download.** A Turbo Stream is a DOM patch. `<turbo-stream>` actions do exactly one thing: mutate elements. Downloading a file is a **navigation** — the browser must commit to a URL and inspect the response's `Content-Disposition`. There is no navigation in a stream render, so there is no download. Corollaries:
- `render turbo_stream:` with `send_data` in the same action is nonsense; you get one response body, and it's one or the other.
- A form submitting to an action that `send_data`s will *appear* to do nothing under Turbo, for the same content-type-mismatch reason as above — except that for a **form** Turbo's failure path is not the same reload, and you get a silent no-op. Put `data-turbo="false"` on the form.
- The closest you can get is a stream that inserts an `<a download href="…">` and a controller that clicks it on connect — which is a *navigation initiated by JS*, not by the stream. See the background-job recipe.

**Code — the background job + broadcast recipe (the one to ship for big exports).**

```ruby
# app/models/export.rb
class Export < ApplicationRecord
  belongs_to :user
  has_one_attached :file
  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  broadcasts_refreshes_to ->(export) { [export.user, :exports] }
end
```

```ruby
# app/controllers/exports_controller.rb
class ExportsController < ApplicationController
  def create
    @export = current_user.exports.create!(
      kind: "posts",
      filters: params.fetch(:filters, {}).permit!.to_h,   # allowlist in real code
      status: :pending
    )
    ExportJob.perform_later(@export)

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("export_panel",
                 partial: "exports/panel", locals: { export: @export })
      }
      format.html { redirect_to posts_path, notice: "Preparing your export…" }
    end
  end

  # A separate, plain GET that streams the finished file.
  def download
    export = current_user.exports.completed.find(params[:id])
    redirect_to export.file.url, allow_other_host: true    # or send_data for local disk
  end
end
```

```ruby
# app/jobs/export_job.rb
class ExportJob < ApplicationJob
  def perform(export)
    export.processing!
    io = StringIO.new(PostsCsv.new(export.scope).to_csv)
    export.file.attach(io: io, filename: "posts-#{export.id}.csv", content_type: "text/csv")
    export.completed!
  rescue => e
    export.failed!
    raise
  end
  # broadcasts_refreshes_to fires on each save — the user's page morphs to the new state.
end
```

```erb
<%# app/views/exports/_panel.html.erb — rendered inside <%= turbo_stream_from current_user, :exports %> %>
<div id="export_panel" aria-live="polite" aria-atomic="true">
  <% case export.status %>
  <% when "pending", "processing" %>
    <p><span class="spinner" aria-hidden="true"></span> Preparing your export…</p>
  <% when "completed" %>
    <p>
      Your export is ready.
      <%= link_to "Download #{export.file.filename}",
            download_export_path(export),
            data: { turbo: false },
            download: export.file.filename.to_s %>
    </p>
  <% when "failed" %>
    <p role="alert">Export failed. <%= button_to "Try again", exports_path(kind: export.kind) %></p>
  <% end %>
</div>
```

Because `Export` uses `broadcasts_refreshes_to`, the page morphs when the job finishes — no stream templates for each state. **Show a link; do not auto-click it.** A programmatic `.click()` on a download link works in Chrome and Firefox but Safari and mobile browsers treat a download with no recent user gesture as suspicious, and blocking it is silent. Email the link too, for exports that take minutes.

**Decomposition.**
- none for the fast path — a link with `data-turbo="false"`.
- Background path: `dialog` (optional progress modal) · `clipboard` (copy the download URL) · `activate` only if you insist on auto-clicking, which you shouldn't.

**A11y.**
- Say what the link does in its text: "Export CSV (2,341 rows)" beats "Export". Add `type` and size if known: `<a … type="text/csv">`.
- `target="_blank"` needs a warning for screen-reader users ("opens in a new tab") — or use `data-turbo="false"` on a same-tab link and skip the problem.
- The status region is `aria-live="polite"`; the failure message is `role="alert"`.
- When the download link appears asynchronously, **move focus to it** or a keyboard user will never find it. `autofocus` on the link inside the swapped-in partial works.

**Native.** This is the sharpest edge in the section. A webview download does **not** just work: iOS `WKWebView` needs `WKDownloadDelegate` wiring and a share sheet; Android needs `DownloadListener` and a `FileProvider`. Options: (1) implement a download bridge component that hands the URL to the native layer and presents the system share sheet — the right answer; (2) open the URL in the system browser (`data-turbo="false"` + a path-config rule routing the download URL externally) — cheap and acceptable; (3) email the file and skip in-app download entirely — often the best product answer on mobile. See [04-hotwire-native](../notes/04-hotwire-native.md) for bridge-component mechanics.

**Pitfalls.**
- `send_data` with `disposition: "inline"` and a PDF renders in the browser's viewer instead of downloading — sometimes what you want, but then Turbo interception matters even more.
- Excel mangles UTF-8 CSV without a BOM. Prepend `"﻿"` if your users open exports in Excel.
- CSV injection: a cell starting with `=`, `+`, `-`, or `@` becomes a formula in Excel/Sheets. Prefix such values with `'`. This is a real vulnerability, not pedantry.
- Rack::ETag and Rack::Deflater buffer streamed responses. Set `Last-Modified` and `X-Accel-Buffering: no`, and verify streaming actually streams in production (it often doesn't behind a proxy).
- Long-running exports in a web request will hit your proxy's timeout at 30–60 s. Anything that might exceed ~10 s belongs in a job.
- `redirect_to export.file.url` exposes a signed, expiring URL — check the expiry (`ActiveStorage::Service.url_expires_in`) exceeds the time the link sits on screen.
- Authorization on the download action: `current_user.exports.completed.find` — never `Export.find`.

**Prior art.** [caxlsx_rails](https://github.com/caxlsx/caxlsx_rails) 0.7.2 (XLSX) · [prawn-rails](https://github.com/cortiz/prawn-rails) 1.6.0 and [wicked_pdf](https://github.com/mileszs/wicked_pdf) 2.8.2 / [grover](https://github.com/Studiosity/grover) 1.2.10 (PDF; grover = headless Chrome, the best output) · Ruby stdlib `CSV` · Active Storage for the artifact · [Active Job](https://guides.rubyonrails.org/active_job_basics.html) + `broadcasts_refreshes` for the async pattern.

---

### Data grid / spreadsheet editing

**Hotwire answer.** Cell-per-frame inline editing (above) scales to a *table you can edit*. It does not scale to a *spreadsheet*. **Verdict: no good Hotwire answer for true spreadsheet editing** — and this is the clearest boundary of the whole catalog.

**Where Hotwire runs out, concretely.** Each of these is table stakes for "spreadsheet" and each one is a server round trip or a client state machine that Hotwire deliberately does not provide:

| Expectation | Why Hotwire can't |
|---|---|
| Arrow-key cell navigation, Tab to next cell, Enter to commit and move down | Pure client state. Implementable with `roving-focus` over a `role="grid"` — the [APG grid pattern](https://www.w3.org/WAI/ARIA/apg/patterns/grid/) — but it's a few hundred lines and it's the easy part. |
| Type-to-replace, F2 to edit, Escape to revert | Client state machine per cell. |
| Copy/paste a range from Excel | Parse TSV from the clipboard, map onto a cell range, POST a bulk patch. No Hotwire involvement; you're writing an app. |
| Undo/redo | Requires a client-side command stack. Turbo has no model for this. |
| Fill-down / drag-fill handle | Same. |
| Formulas | A calculation engine. |
| 10,000 rows × 30 columns | Needs virtualization, which Turbo fights (see above). |
| Sub-100 ms edit feedback | A round trip per cell is 50–300 ms. Optimistic UI means client state, which means the DOM and the server disagree, which is precisely what Turbo is designed to prevent. |

The failure isn't a missing feature — it's that a spreadsheet's defining property is a **rich client-side model that the server confirms asynchronously**, and Turbo's defining property is that **the server owns the DOM**. These are opposed. Every partial attempt lands in the worst place: enough client state to have bugs, not enough to feel like a spreadsheet.

**What to do instead.**

1. **Ask whether you need a spreadsheet.** Most "we need a data grid" requirements are satisfied by a sortable, filterable table with per-cell inline editing and a good bulk-edit form. Ship that first — the patterns above cover it entirely, with no JS beyond `autosubmit` and `selection`.
2. **Bulk edit via a form, not a grid.** Select rows (`selection`), open a form, set one field on all of them. Faster for the user than editing 40 cells, and it's 30 lines.
3. **Import/export round-trip.** Export XLSX, let them edit in the tool they already know, re-import with a diff preview. Genuinely the best product answer for "bulk data entry" surprisingly often.
4. **Embed a real grid component as an island.** [Handsontable](https://handsontable.com/) (commercial for most uses), [AG Grid](https://www.ag-grid.com/) (community edition is MIT and has a vanilla-JS entry point), [Revo Grid](https://rv-grid.com/), [jSpreadsheet](https://bossanova.uk/jspreadsheet/). Wrap in one Stimulus controller, put `data-turbo-permanent` on the container, feed it JSON from an endpoint, and POST changes as a batch. **Accept that this region is outside Turbo's world**: no streams targeting inside it, no morphing through it, its own loading and error states. Draw the boundary explicitly and keep it small.
5. **If the grid *is* the product**, that screen is a client app. Mount it on one route. The rest of your Rails app stays Hotwire. This is a completely respectable outcome and far better than half-building a grid out of frames.

**Decomposition.** For the "editable table" tier: `selection` + `autosubmit` + `hotkey` + `roving-focus` (if you add arrow navigation) + inline-edit frames. For the island tier: one bespoke wrapper controller and `data-turbo-permanent` — not a reusable primitive.

**A11y.** If you implement arrow-key navigation you have adopted [APG grid](https://www.w3.org/WAI/ARIA/apg/patterns/grid/), which requires: one tab stop for the whole grid, arrow/Home/End/Ctrl+Home/Ctrl+End navigation, `aria-rowcount`/`aria-colcount`/`aria-rowindex`/`aria-colindex` when virtualized, `aria-selected`, and an editing model where entering a cell's editor changes the keyboard contract. Third-party grids vary from good (AG Grid) to unusable — **test with a screen reader before you buy**, because a grid you can't retrofit is a grid you're stuck with.

**Native.** A spreadsheet in a webview on a phone is not a product. Provide a mobile-appropriate list/detail form instead.

**Pitfalls.** Islands leak: someone will eventually target a `turbo_stream.replace` inside your permanent container and spend a day on it. Comment the boundary in the ERB. Grid libraries assume they own resize/scroll; Turbo restore-visits with a cached snapshot will hand them a detached DOM — destroy on `turbo:before-cache`. And check licensing before you demo it: AG Grid Enterprise and Handsontable are not free for commercial use.

**Prior art.** [AG Grid](https://www.ag-grid.com/) · [Handsontable](https://handsontable.com/) · [Revo Grid](https://rv-grid.com/) · [jSpreadsheet](https://bossanova.uk/jspreadsheet/) · [Avo](https://avohq.io/) / [ActiveAdmin](https://activeadmin.info/) / [Administrate](https://administrate-demo.herokuapp.com/) if the real requirement is an admin CRUD surface rather than a spreadsheet · **superseded:** [wice_grid](https://github.com/leikind/wice_grid).

---

### Empty states

**Hotwire answer.** A partial rendered when the collection is empty. Trivial — except for one classic bug: **removing the last row with `turbo_stream.remove` does not make the empty state appear.** Three fixes, in order of preference: morph, target a wrapper, or CSS `:has()`.

**Code.**

```erb
<%# app/views/posts/index.html.erb %>
<div id="posts_wrapper">
  <% if @posts.any? %>
    <table>
      <tbody id="posts"><%= render @posts %></tbody>
    </table>
  <% else %>
    <%= render "posts/empty" %>
  <% end %>
</div>
```

```erb
<%# app/views/posts/_empty.html.erb %>
<div class="empty-state">
  <h2>No posts yet</h2>
  <p>Posts you write will show up here.</p>
  <%= link_to "Write your first post", new_post_path, class: "button" %>
</div>
```

**The bug.** `render turbo_stream: turbo_stream.remove(@post)` removes `#post_17`. If that was the last row, `#posts` is now an empty `<tbody>` inside a `<table>` — a table with a header and no rows — and the empty state, which was never rendered, still isn't. Same bug in reverse: creating the first post with `turbo_stream.append "posts"` appends a `<tr>` into a container that isn't there because the empty state replaced it.

**Fix 1 (best): a morphing refresh.** `redirect_to posts_path` with `<meta name="turbo-refresh-method" content="morph">`. The server re-renders `index.html.erb`, the `if @posts.any?` branch flips, the empty state appears, the count updates, the pagination links update. The bug is structurally impossible because the server always renders the whole truth. **This is why the top-of-section decision rule defaults to morphing.**

**Fix 2: target the wrapper, not the rows.**

```ruby
def destroy
  @post.destroy!
  @posts = Post.order(created_at: :desc)   # or the filtered scope
  render turbo_stream: turbo_stream.replace("posts_wrapper",
           partial: "posts/list", locals: { posts: @posts })
end
```
Correct, costs a full list re-render, and now you've written most of what morph does for free.

**Fix 3: CSS `:has()` — no JS, no extra render.**

```erb
<div id="posts_wrapper">
  <table><tbody id="posts"><%= render @posts %></tbody></table>
  <%= render "posts/empty" %>   <%# always rendered, hidden by CSS when rows exist %>
</div>
```
```css
.empty-state { display: block; }
#posts_wrapper:has(#posts > tr) .empty-state { display: none; }
#posts_wrapper:not(:has(#posts > tr)) table { display: none; }
```
`:has()` is supported in Chrome 105, Safari 15.4, Firefox 121 (verified against [MDN BCD](https://github.com/mdn/browser-compat-data/blob/main/css/selectors/has.json)) — safe in 2026. Do **not** use `:empty` for this: an ERB-rendered `<tbody>` contains whitespace text nodes and `:empty`'s handling of them has varied across browsers and spec revisions.

**Decomposition.** None.

**A11y.**
- The empty state is content, not decoration: a real `<h2>`, real prose, and a real link to the primary action. Don't ship a shrug emoji.
- When the last row is removed by a user action, announce it: `<p aria-live="polite">All posts deleted.</p>`, or put the empty state itself in a live region.
- Distinguish "no records yet" from "no records match your filters" — the latter needs a "Clear filters" link, and confusing the two is the most common empty-state design bug.
- Focus after deleting the last row goes to `<body>`. Move it to the empty state's heading (`tabindex="-1"` + `.focus()`) or the primary action link.

**Native.** n/a — it's markup.

**Pitfalls.**
- The row-removal bug above. It's the one everybody ships.
- An empty *filtered* result rendering the "create your first post" empty state is actively misleading. Branch on `@posts.any?` vs. `filters_applied?`.
- Loading skeletons and empty states are different things: a lazy frame's placeholder must not say "No posts yet".
- Don't hide the empty state behind `display: none` and forget it exists in the a11y tree — `display: none` does remove it, but a `visibility: hidden` / `opacity: 0` version does not. Use `hidden` or `display: none`.

**Prior art.** Nothing to install. [Rails Designer](https://railsdesigner.com/) and [railsblocks](https://railsblocks.com/) both ship reasonable empty-state markup you can crib.

---



## Feedback, state & real-time

### Toast / flash notifications

**Hotwire answer.** Three tiers, and you want all three in the same app: (a) a `#flashes` live-region container rendered in the layout, filled from `flash` on full page loads; (b) `flash.now[...]` + `turbo_stream.append "flashes"` from a controller so a stream-only response can still flash; (c) `Turbo::StreamsChannel.broadcast_append_later_to current_user, :toasts, target: "flashes"` so a background job can toast one specific user. Auto-dismissal is `timeout` + `transition` + `dismiss` — three tiny generic controllers, no toast library. There is **no** well-maintained gem for this; write the ~40 lines.

**Code.**

Tier (a) — the container. Put it in the layout, outside anything a frame replaces:

```erb
<%# app/views/layouts/application.html.erb %>
<body>
  <%# Two containers, because role/aria-live politeness is per-container and must exist
      in the DOM BEFORE content is injected for reliable SR announcement. %>
  <div id="flashes"       class="toast-stack" role="status" aria-live="polite"    aria-atomic="false"></div>
  <div id="flash_alerts"  class="toast-stack" role="alert"  aria-live="assertive" aria-atomic="false"></div>

  <%= render "layouts/flashes" %>
  <%= yield %>
</body>
```

```erb
<%# app/views/layouts/_flashes.html.erb — appends into the live regions on a full load %>
<% flash.each do |type, message| %>
  <%= turbo_stream.append flash_container_for(type) do %>
    <%= render "layouts/flash", type: type, message: message %>
  <% end %>
<% end %>
```

A bare `<turbo-stream>` sitting in ordinary HTML executes on connect — that behaviour is documented and intentional ([turbo.hotwired.dev/reference/streams#stream-elements-inside-html](https://turbo.hotwired.dev/reference/streams#stream-elements-inside-html)). This is what lets one partial serve both the full-page and the stream path.

```ruby
# app/helpers/flash_helper.rb
module FlashHelper
  ALERT_TYPES = %w[alert error].freeze
  def flash_container_for(type) = type.to_s.in?(ALERT_TYPES) ? "flash_alerts" : "flashes"
end
```

```erb
<%# app/views/layouts/_flash.html.erb %>
<div class="toast toast--<%= type %>"
     data-controller="transition timeout dismiss"
     data-transition-enter-from-class="toast--from"
     data-transition-enter-to-class="toast--to"
     data-transition-leave-from-class="toast--to"
     data-transition-leave-to-class="toast--from"
     data-timeout-delay-value="<%= type.to_s.in?(FlashHelper::ALERT_TYPES) ? 8000 : 4000 %>"
     data-action="timeout:fire->dismiss#dismiss
                  mouseenter->timeout#pause
                  mouseleave->timeout#resume">
  <p class="toast__body"><%= message %></p>
  <button type="button" class="toast__close" aria-label="Dismiss notification"
          data-action="dismiss#dismiss">&times;</button>
</div>
```

`dismiss` runs `transition`'s leave sequence and then `element.remove()`. Stacking is CSS only:

```css
.toast-stack { position: fixed; inset-block-start: 1rem; inset-inline-end: 1rem;
               display: flex; flex-direction: column; gap: .5rem; z-index: 100;
               pointer-events: none; }
.toast { pointer-events: auto; transition: opacity .2s, transform .2s; }
.toast--from { opacity: 0; transform: translateX(1rem); }
.toast--to   { opacity: 1; transform: none; }
@media (prefers-reduced-motion: reduce) { .toast { transition: none } }
```

Tier (b) — flashing from a Turbo Stream response:

```ruby
# app/controllers/concerns/flashable.rb
module Flashable
  extend ActiveSupport::Concern

  private
    # Use with: render turbo_stream: [ turbo_stream.remove(@quote), *turbo_stream_flash ]
    def turbo_stream_flash(**messages)
      messages.each { |type, message| flash.now[type] = message }
      flash.map do |type, message|
        turbo_stream.append helpers.flash_container_for(type),
          partial: "layouts/flash", locals: { type: type, message: message }
      end
    end
end
```

```ruby
class QuotesController < ApplicationController
  include Flashable

  def destroy
    @quote.destroy!
    render turbo_stream: [
      turbo_stream.remove(@quote),
      *turbo_stream_flash(notice: "Quote deleted.")
    ]
  end
end
```

Prepend instead of append if your stack grows upward from the bottom: `turbo_stream.prepend`.

Tier (c) — broadcast a toast to one user from a job:

```erb
<%# in the layout, for signed-in users %>
<%= turbo_stream_from current_user, :toasts if current_user %>
```

```ruby
# app/models/toast.rb
class Toast
  def self.deliver_later(user, message, type: :notice)
    Turbo::StreamsChannel.broadcast_append_later_to \
      user, :toasts,
      target:  type.to_s.in?(FlashHelper::ALERT_TYPES) ? "flash_alerts" : "flashes",
      partial: "layouts/flash",
      locals:  { type: type, message: message }
  end
end

class ExportJob < ApplicationJob
  def perform(user, report)
    Export.new(report).run
    Toast.deliver_later(user, "Your export is ready.", type: :notice)
  end
end
```

`broadcast_append_later_to` → `broadcast_action_later_to(action: :append)` → `Turbo::Streams::ActionBroadcastJob`, which renders the partial **inside the job** (turbo-rails `app/channels/turbo/streams/broadcasts.rb`). That's why `_later` is right here: your web request doesn't pay for the render.

**Decomposition.** `timeout` + `transition` + `dismiss`. Optionally `hotkey` (Esc dismisses the top toast) and `persist` (remember "don't show this again" banners).

**A11y.**
- `role="status"` (implicit `aria-live="polite"`, `aria-atomic="true"` off by default in some AT — set it explicitly) for confirmations. Announced when the user is idle; never interrupts.
- `role="alert"` (implicit `aria-live="assertive"`) **only** for errors and destructive outcomes. It interrupts whatever the screen reader is saying. Using it for "Saved!" is abusive.
- The live region must exist in the DOM before content is injected. Injecting a whole `<div role="status">` works in most modern SR/browser pairs but is measurably less reliable than appending into a pre-existing region — hence the two empty containers in the layout.
- Auto-dismiss and screen readers conflict: a 4s toast is not enough time. Give errors 8s+, never auto-dismiss anything the user must act on, and keep a real `<button>` close control with an accessible name.
- No APG pattern for toasts; the relevant spec is [WAI-ARIA live regions](https://www.w3.org/WAI/ARIA/apg/practices/live-regions/). WCAG 2.2 SC 2.2.1 (Timing Adjustable) means auto-dismiss needs a pause — hence `mouseenter->timeout#pause`.
- `pointer-events: none` on the stack + `auto` on the toast prevents a stale toast eating clicks.

**Native.** Toasts should be a bridge component in Hotwire Native — the web toast renders behind the native nav bar and looks wrong. Post `{ message, type }` over the bridge and let iOS/Android show a native snackbar / `UNNotification`. Suppress the web stack with a `.turbo-native .toast-stack { display: none }` rule (Hotwire Native adds a `turbo-native` class to `<html>`). See `04-hotwire-native.md`.

**Pitfalls.**
- **The classic double-flash:** using `flash[:notice]` instead of `flash.now[:notice]` in a Turbo Stream (or any non-redirecting) response. The message renders in the stream *and* survives in the session, so it appears again on the next full page load. Rule: `flash` only immediately before a `redirect_to`; `flash.now` everywhere else.
- **Morphing wipes toasts.** Turbo 8 page refreshes morph `<body>`; a toast appended by a stream isn't in the server's HTML, so morph deletes it — and a toast that *is* in the server HTML gets re-added on every morph. Fix: mark the containers permanent.
  ```erb
  <div id="flashes" data-turbo-permanent role="status" aria-live="polite"></div>
  ```
  `data-turbo-permanent` requires an `id` and is honoured by **both** the page renderer and the stream renderer (`src/core/streams/stream_message_renderer.js` wraps rendering in `Bardo.preservingPermanentElements`). Consequence: once the container is permanent, the server can no longer seed it from the layout — everything must arrive by stream append (which is exactly what the tier-(a) `turbo_stream.append` partial above does). See `02-turbo-deep-dive.md` §2.7 and §5.8.
- **Turbo Drive caching shows ghost toasts.** The snapshot cached on navigation includes whatever toasts were visible. Going Back re-displays them. Add `data-turbo-temporary` to each toast (Turbo strips those from the cached snapshot) or clear the stack on `turbo:before-cache`.
- A redirect after a stream-flash re-renders the layout and the flash region; if you emitted both you get duplicates.
- Don't put the `#flashes` container inside a `<turbo-frame>` — frame responses can't target outside themselves, so every stream append silently no-ops.

**Prior art.**
- [stimulus-components `notification`](https://github.com/stimulus-components/stimulus-components/tree/main/components/notification) — `delayValue` (default 3000), `hiddenValue` (default false), `show()`/`hide()`, uses `stimulus-use`'s `useTransition`, removes itself from the DOM. Verified from `components/notification/src/index.ts`. Close to the `timeout`+`transition`+`dismiss` composition, but bundled into one controller.
- [tailwindcss-stimulus-components `alert`](https://github.com/excid3/tailwindcss-stimulus-components/blob/main/src/alert.js) — `dismissAfterValue` (Number, no default: auto-dismiss only when set), `showDelayValue` (default 0), public `close()`. Its own `enter`/`leave` from `src/transition.js`.
- [turbo_power](https://github.com/marcoroth/turbo_power) (519★, active as of 2026-08) — ships a `notification` stream action plus `add_css_class` / `remove_css_class` / `dispatch_event` / `set_style`. `turbo_stream.notification "Saved", body: "..."` uses the browser Notification API, which is **not** an in-page toast — don't confuse them.
- **Verdict on gems:** there is no maintained flash-over-Turbo-Stream gem worth adopting. [joshmn/turbo_flash](https://github.com/joshmn/turbo_flash) (63★, last push 2023-08) is the most-starred and is stale; `mixandgo/hotwire_flash` (2★, 2022) and `rnevius/rails_turbo_flash` (0★) are toys. Write the concern.
- [hotrails.dev — Flash messages with Hotwire](https://www.hotrails.dev/turbo-rails/flash-messages-hotwire) is the canonical tutorial; note it dismisses on `animationend` rather than with a `timeout` controller, which is fine but harder to pause.

---

### Loading states & skeletons

**Hotwire answer.** **No JS needed.** Turbo already puts `aria-busy="true"` on `<html>` during a Drive visit, on the `<form>` and enclosing `<turbo-frame>` during a submission, and both `busy` and `aria-busy="true"` on a `<turbo-frame>` while it fetches. Write CSS against those attributes. For lazy frames, the frame's own children are the placeholder — put a skeleton there and Turbo replaces it on load. Reach for the `content-loader` style Stimulus controller only if you need a skeleton for something that isn't a frame.

**Code.** The exact rules, from `src/util.js`:

```js
export function markAsBusy(...elements) {
  for (const element of elements) {
    if (element.localName == "turbo-frame") { element.setAttribute("busy", "") }
    element.setAttribute("aria-busy", "true")
  }
}
```

So `busy` is **frames only**; `aria-busy` goes on everything. Call sites (Turbo 8.0.23):

| Element | Attributes | Set when | Source |
|---|---|---|---|
| `<html>` | `aria-busy="true"` | Drive visit starts — **unless** `visit.acceptsStreamResponse` (i.e. a `data-turbo-stream` link/form) | `src/core/session.js:281` `visitStarted` |
| `<form>` | `aria-busy="true"` | `turbo:submit-start` → `turbo:submit-end` | `src/core/drive/form_submission.js:126,172` |
| `<turbo-frame>` | `busy` + `aria-busy="true"` | frame navigation (link click, `src` change, lazy load) | `frame_controller.js:214` `requestStarted` |
| `<turbo-frame>` (ancestor **and** target) | `busy` + `aria-busy="true"` | a form inside/targeting it submits | `frame_controller.js:243` `formSubmissionStarted` |
| `<turbo-frame>` | `complete` (no value) | after a **successful** frame render; removed when `src` changes or `.reload()` is called | `frame_controller.js:328`, `:95`, `:108` |

The whole loading vocabulary in CSS:

```css
/* 1. Whole-page: dim the content during a Drive visit.
      Note this does NOT fire for data-turbo-stream visits. */
html[aria-busy="true"] main { opacity: .55; transition: opacity .15s .1s; }

/* 2. Forms mid-submit */
form[aria-busy="true"] { opacity: .6; pointer-events: none; }
form[aria-busy="true"] .spinner { display: inline-block; }

/* 3. Frames mid-fetch. [busy] is the frame-specific one; prefer it over
      [aria-busy] so you don't accidentally match forms. */
turbo-frame[busy] .skeleton { display: block; }
turbo-frame[busy] .frame-body { display: none; }

/* 4. A lazy frame that has never loaded (no [complete] yet) */
turbo-frame[src]:not([complete]) { min-height: 8rem; }

/* 5. The skeleton itself — pure CSS, no library */
.skeleton {
  display: none;
  background: linear-gradient(90deg,
    var(--skeleton-base) 25%, var(--skeleton-shine) 37%, var(--skeleton-base) 63%);
  background-size: 400% 100%;
  animation: skeleton-shimmer 1.4s ease infinite;
  border-radius: .375rem;
}
.skeleton--line  { height: 1rem; margin-block-end: .5rem; }
.skeleton--line:nth-child(3) { inline-size: 60%; }
.skeleton--card  { block-size: 8rem; }
@keyframes skeleton-shimmer { 0% { background-position: 100% 50% } 100% { background-position: 0 50% } }
@media (prefers-reduced-motion: reduce) { .skeleton { animation: none } }
```

The lazy-frame placeholder. This is the single most elegant loading pattern Hotwire has:

```erb
<%= turbo_frame_tag "dashboard_stats", src: dashboard_stats_path, loading: :lazy do %>
  <div class="skeleton-group" aria-hidden="true">
    <div class="skeleton skeleton--card" style="display:block"></div>
    <div class="skeleton skeleton--line" style="display:block"></div>
    <div class="skeleton skeleton--line" style="display:block"></div>
  </div>
<% end %>
```

The block content renders server-side with the first byte, shows instantly, and is discarded the moment the frame's response arrives. `loading: :lazy` defers the fetch until the frame scrolls into view (`AppearanceObserver`), so a below-the-fold widget costs nothing.

Progress bar customisation (see `02-turbo-deep-dive.md` §2.12 for the full mechanics):

```js
// app/javascript/application.js
Turbo.config.drive.progressBarDelay = 250   // default 500ms
// NOT Turbo.setProgressBarDelay() — deprecated in Turbo 8, logs a console warning.
```

```css
/* Turbo injects its own <style> as the FIRST child of <head>, so any stylesheet
   you load later wins at equal specificity. Real default: 3px, #0076ff, z-index 2147483647. */
.turbo-progress-bar { height: 3px; background: var(--accent); }
```

**Decomposition.** None — this is CSS against attributes Turbo already sets. If you need a skeleton for a non-frame region, `intersection` (fire when visible) + a `<turbo-frame>` is still the better answer than a JS controller.

**A11y.** `aria-busy="true"` is exactly the right ARIA state and Turbo sets it for you; assistive tech suppresses reporting of the subtree while it's true. Skeleton elements must be `aria-hidden="true"` — a screen reader reading twelve empty grey boxes is worse than silence. Do not add `role="progressbar"` to the Turbo progress bar: it's indeterminate decoration and already invisible to AT. If a frame load can take more than ~5s, put a `role="status"` "Loading results…" node inside the placeholder so there is *something* announced.

**Native.** In Hotwire Native the web progress bar competes with the native one. Hide it: `.turbo-native .turbo-progress-bar { display: none }`. Lazy frames still work but fire on the web view's viewport, which can differ from what the user sees under a native bottom bar — test it.

**Pitfalls.**
- **`<html aria-busy>` does not fire for stream visits.** `visitStarted` guards on `!visit.acceptsStreamResponse`, so a `data-turbo-stream` link gets no page-level busy state. Deliberate (there's a functional test asserting it) but surprising.
- `turbo-frame[busy]` is set on **both** the ancestor frame and the target frame for a form submission, so a nested frame layout can show two spinners.
- The progress bar's 500ms delay means fast responses show nothing at all — users read that as "my click didn't register". `data-turbo-submits-with="Saving…"` on the submit button (see §2.11) is the cheap fix for forms; for links, a `:active` style.
- A frame with `loading="lazy"` inside a `display: none` container never becomes visible, so it never loads. `AppearanceObserver` is an IntersectionObserver.
- Skeleton dimensions that don't match the real content cause layout shift. Match the real element's height, or reserve space with `min-height` on the frame.
- Don't hand-roll a `turbo:before-fetch-request` → add-class → `turbo:frame-load` → remove-class controller. That's what `[busy]` is.

**Prior art.**
- [stimulus-components `content-loader`](https://github.com/stimulus-components/stimulus-components/tree/main/components/content-loader) — fetches a URL and injects HTML with a loading state. Largely **superseded** by lazy `<turbo-frame>`; use it only for non-frame fetches.
- [turbo_power](https://github.com/marcoroth/turbo_power) — `turbo_progress_bar_show` / `_hide` / `_set_value` stream actions if you want server-driven control of the bar.
- [tailwindcss-stimulus-components](https://github.com/excid3/tailwindcss-stimulus-components) — no loading controller; nothing needed.
- CSS-only skeleton recipes are everywhere; nothing to install.

---

### Busy indicators for frames (the complete selector & event map)

**Hotwire answer.** CSS attribute selectors first, events only when CSS can't express it. **No JS needed** for 90% of cases.

**Code.**

```css
turbo-frame[busy]                  { /* this frame is fetching (frames only) */ }
turbo-frame[aria-busy="true"]      { /* same moment; also matches forms/html, so prefer [busy] */ }
turbo-frame[src]:not([complete])   { /* has a src but has never successfully rendered */ }
form[aria-busy="true"]             { /* submitting */ }
html[aria-busy="true"]             { /* Drive visit in flight (not for data-turbo-stream visits) */ }
.turbo-progress-bar                { /* the injected indeterminate bar */ }
```

The events, with verified detail payloads (`src/http/fetch_request.js`, `src/core/drive/form_submission.js`):

| Event | `target` | `detail` | Cancelable |
|---|---|---|---|
| `turbo:before-fetch-request` | the frame / form / `document` | `{ fetchOptions, url, resume }` | yes — `preventDefault()` then call `detail.resume()` |
| `turbo:before-fetch-response` | same | `{ fetchResponse }` | yes |
| `turbo:fetch-request-error` | same | `{ request, error }` | yes (prevents Turbo's own handling) |
| `turbo:submit-start` | the `<form>` | `{ formSubmission }` | no |
| `turbo:submit-end` | the `<form>` | `{ formSubmission, success, fetchResponse }` or `{ formSubmission, success, error }` | no |
| `turbo:frame-load` | the `<turbo-frame>` | — | no |
| `turbo:frame-missing` | the `<turbo-frame>` | `{ response, visit }` | yes |

The only thing CSS can't do: showing an error state when the network dies (a failed frame fetch leaves the frame in whatever state it was, logs to console, and clears `[busy]`).

```js
// app/javascript/controllers/frame_error_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["error"]

  connect()  { this.element.addEventListener("turbo:fetch-request-error", this.#fail) }
  disconnect(){ this.element.removeEventListener("turbo:fetch-request-error", this.#fail) }

  retry() { this.errorTarget.hidden = true; this.element.reload() }

  #fail = (event) => {
    event.preventDefault()          // stop Turbo from just console.error-ing
    this.errorTarget.hidden = false
  }
}
```

```erb
<%= turbo_frame_tag "report", src: report_path, loading: :lazy,
      data: { controller: "frame-error", frame_error_target: "self" } do %>
  <div class="skeleton skeleton--card" aria-hidden="true" style="display:block"></div>
  <div data-frame-error-target="error" hidden role="alert">
    Couldn't load this report.
    <button type="button" data-action="frame-error#retry">Retry</button>
  </div>
<% end %>
```

**Decomposition.** None for the CSS path. The retry case is a one-off controller; there is no generic primitive that fits (it needs `frame.reload()`).

**A11y.** `aria-busy` is set by Turbo and is the correct state. Add `role="alert"` to the error node so the failure is announced. Give the retry control a real `<button>`.

**Native.** `turbo:fetch-request-error` fires on the web view when the device is offline; Hotwire Native shows its own offline screen for *page* visits but not for *frame* fetches, so the in-frame retry UI above is load-bearing on mobile.

**Pitfalls.**
- `[busy]` is set on ancestor **and** target frames during a form submission — scope your CSS or you'll flash two indicators.
- `aria-busy` on `<html>` is skipped for `data-turbo-stream` visits.
- `turbo:fetch-request-error` is `cancelable`; if you don't `preventDefault()`, Turbo still runs its default (console.error) — harmless, but if you *do* prevent it, the frame's visit promise still resolves and `[busy]` is still cleared in `requestFinished`.
- There is no `turbo:frame-error` event. `turbo:frame-missing` is for a 200 response that lacks the matching frame — a different failure.
- Cross-ref `02-turbo-deep-dive.md` §2.3 (full event reference) and §2.12 (progress bar internals).

**Prior art.** None needed. [htmx's `hx-indicator`](https://htmx.org/attributes/hx-indicator/) is the comparable feature in the neighbouring ecosystem; Turbo's attribute-based version needs no attribute at all.

---

### Optimistic UI

**Hotwire answer.** Hotwire has no optimistic-UI *system*. What it has is a **reconciliation guarantee** you can build on: `append`/`prepend`/`before`/`after` stream actions call `removeDuplicateTargetChildren()`, so if your optimistically-inserted node carries the same DOM `id` the server will produce, the server's version silently replaces it instead of duplicating. Combine that with a Stimulus controller that mutates the DOM on click and `turbo:submit-end` to detect failure. For toggles (like/star/vote), do it. For anything with a server-computed result, don't.

**Code.** The verified 37signals recipe (ONCE Campfire, `app/javascript/controllers/composer_controller.js` + `messages_controller.js` + `app/models/message.rb`). Three moving parts:

```ruby
# app/models/message.rb — the key trick: dom_id is derived from a CLIENT-generated id
class Message < ApplicationRecord
  before_create -> { self.client_message_id ||= Random.uuid }

  def to_key = [ client_message_id ]   # => dom_id(message) == "message_<uuid>"
end
```

```js
// app/javascript/controllers/composer_controller.js (condensed from Campfire)
export default class extends Controller {
  static targets = ["clientid", "text"]
  static outlets = ["messages"]

  async submit(event) {
    event.preventDefault()
    const clientMessageId = crypto.randomUUID()

    // 1. paint it immediately, with the id the server WILL use
    await this.messagesOutlet.insertPendingMessage(clientMessageId, this.textTarget)

    // 2. tell the server which id to persist
    this.clientidTarget.value = clientMessageId
    this.element.requestSubmit()
    this.#reset()
  }

  // 3. revert on failure
  submitEnd(event) {
    if (!event.detail.success) {
      this.messagesOutlet.failPendingMessage(this.clientidTarget.value)
    }
  }
}
```

```erb
<%= form_with model: [@room, Message.new], data: {
      controller: "composer", action: "submit->composer#submit turbo:submit-end->composer#submitEnd",
      composer_messages_outlet: "#messages" } do |form| %>
  <%= form.hidden_field :client_message_id, data: { composer_target: "clientid" } %>
  <%= form.rich_text_area :body, data: { composer_target: "text" } %>
<% end %>
```

The server then broadcasts normally — `broadcast_append_to room, :messages, target: [room, :messages]` — and because the broadcast partial renders `id="message_<same-uuid>"`, Turbo's `append` action removes the pending node and inserts the real one. **No duplicate, no manual reconciliation.** Verified in `src/elements/stream_element.js`:

```js
get duplicateChildren() {
  const existingChildren  = this.targetElements.flatMap((e) => [...e.children]).filter((c) => !!c.getAttribute("id"))
  const newChildrenIds    = [...(this.templateContent?.children || [])].filter((c) => !!c.getAttribute("id")).map((c) => c.getAttribute("id"))
  return existingChildren.filter((c) => newChildrenIds.includes(c.getAttribute("id")))
}
```

The simpler case — an optimistic like button. Here the failure path is a real revert:

```js
// app/javascript/controllers/optimistic_toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static classes = ["on"]
  static targets  = ["count"]

  toggle() {
    this.#previous = { on: this.element.classList.contains(this.onClass),
                       count: this.countTarget.textContent }
    this.element.classList.toggle(this.onClass)
    this.element.setAttribute("aria-pressed", String(!this.#previous.on))
    this.countTarget.textContent = Number(this.#previous.count) + (this.#previous.on ? -1 : 1)
    this.element.dataset.pending = ""          // style with [data-pending] { opacity: .7 }
  }

  settled(event) {
    delete this.element.dataset.pending
    if (!event.detail.success) this.#revert()
  }

  #revert() {
    this.element.classList.toggle(this.onClass, this.#previous.on)
    this.element.setAttribute("aria-pressed", String(this.#previous.on))
    this.countTarget.textContent = this.#previous.count
    // Tell the user. Silent reverts are worse than no optimism.
    this.dispatch("failed", { prefix: "toast", detail: { message: "Couldn't save that." } })
  }
}
```

```erb
<%= button_to like_path(@post), method: :post, form: { data: {
      action: "turbo:submit-end->optimistic-toggle#settled" } },
    data: { controller: "optimistic-toggle", action: "click->optimistic-toggle#toggle",
            optimistic_toggle_on_class: "like--on" },
    aria: { pressed: @post.liked_by?(current_user) } do %>
  <span data-optimistic-toggle-target="count"><%= @post.likes_count %></span>
<% end %>
```

Then the server's `broadcast_replace_to` (or a `refresh` broadcast + morph) reconciles the truth. Morphing is well-behaved here: idiomorph will restore the correct class because the server's HTML is authoritative.

**Decomposition.** `transition` (pending → settled styling). Nothing else generic exists — the mutation is inherently domain-specific. `sync` if the same state appears in two places.

**A11y.** A toggle is `<button aria-pressed>`; update it in the same tick you update the visual. On revert, announce the failure through the `role="alert"` toast region — a silently reverted button is invisible to a screen reader user. Never disable the button during the pending window; that steals focus (see `Turbo.config.forms.submitter = "aria-disabled"` in §2.11).

**Native.** Optimistic web UI inside a Hotwire Native web view is fine, but the native shell may also cache the screen; a reverted optimistic change plus a cached snapshot produces a lie. Prefer server truth on native screens.

**Pitfalls.**
- **You must implement revert yourself, and you will get it wrong.** React's optimistic story (`useOptimistic`, React Query rollback) exists because the revert is the hard 80%. Turbo gives you no rollback, no request-scoped state, no "in-flight mutation" registry.
- **Two optimistic mutations racing** on the same node: the second `toggle()` overwrites `#previous`, so a failure of the first reverts to the wrong state. Guard with a per-element in-flight counter or just don't allow it.
- **`turbo:submit-end` fires with `success: true` for any 2xx/3xx**, including a response that didn't do what you assumed. `detail.fetchResponse` is there if you need to check.
- **Morphing will fight you** if the server's HTML disagrees with your optimistic DOM at the moment the refresh lands, producing a visible flicker back and forth. Keep the optimistic window short.
- The `client_message_id` trick requires overriding `to_key`, which changes `dom_id` **everywhere** — routes using `to_param` are unaffected, but any `dom_id(record)` in existing views changes shape. Do it on new models.
- `crypto.randomUUID()` requires a secure context (HTTPS or localhost).

**Verdict: partial.** For binary toggles with a `data-pending` style and a real revert path, Hotwire's optimistic UI is genuinely fine and ~30 lines. For anything where the server computes the result (a new row's position, a total, a derived status), **don't**. The decision rule: *a p95 server round-trip under ~250ms plus a pending style beats real optimistic UI for almost every CRUD app.* Spend the effort on the query, not the rollback. Hotwire is honestly weaker than React here and the gap is not closable with a library.

**Prior art.**
- [ONCE Campfire source](https://github.com/basecamp/once-campfire) — `app/javascript/controllers/composer_controller.js`, `app/javascript/models/client_message.js`, `app/models/message.rb`. The only production-grade optimistic Hotwire code in the open.
- [turbo_boost-commands](https://github.com/hopsoft/turbo_boost-commands) (325★, **last push 2024-07** — effectively dormant, flag it) offered server-driven "commands" with optimistic hooks. Not recommended in 2026.
- No Stimulus package does optimistic UI. There is nothing to install.

---

### Progress bars for background jobs (determinate)

**Hotwire answer.** Broadcast, don't poll. Have the job call `Turbo::StreamsChannel.broadcast_replace_to` on a throttle (every N% or every N seconds, not every record) targeting a small partial containing a `<progress>`. **No JS needed.**

**Code.**

```erb
<%# app/views/imports/show.html.erb %>
<%= turbo_stream_from @import %>
<%= render "imports/progress", import: @import %>
```

```erb
<%# app/views/imports/_progress.html.erb %>
<div id="<%= dom_id(import, :progress) %>" class="import-progress">
  <label for="import_progress_bar">Importing <%= import.filename %></label>
  <progress id="import_progress_bar" max="100" value="<%= import.percent %>"
            aria-valuenow="<%= import.percent %>" aria-valuemin="0" aria-valuemax="100"
            aria-describedby="import_progress_text"></progress>
  <p id="import_progress_text" role="status">
    <%= import.finished? ? "Done — #{import.rows_total} rows imported." :
        "#{import.percent}% — #{import.rows_done} of #{import.rows_total}" %>
  </p>
</div>
```

```ruby
# app/jobs/import_job.rb
class ImportJob < ApplicationJob
  THROTTLE = 2.seconds

  def perform(import)
    last_push = Time.current
    import.each_row.with_index do |row, i|
      import.ingest(row)
      if Time.current - last_push > THROTTLE
        import.update_columns(rows_done: i + 1)
        push_progress(import)
        last_push = Time.current
      end
    end
    import.update!(rows_done: import.rows_total, finished_at: Time.current)
    push_progress(import)
  end

  private
    def push_progress(import)
      # Synchronous on purpose: we're already in a job, and _later would enqueue
      # thousands of tiny render jobs.
      Turbo::StreamsChannel.broadcast_replace_to import,
        target: ActionView::RecordIdentifier.dom_id(import, :progress),
        partial: "imports/progress", locals: { import: import }
    end
end
```

The polling alternative, when you have no cable backend at all:

```erb
<%= turbo_frame_tag dom_id(@import, :progress), src: progress_import_path(@import),
      data: { controller: "interval", interval_ms_value: 2000,
              action: "interval:tick->interval#reloadFrame" } do %>
  …
<% end %>
```

Broadcasting wins: one message per 2s per import vs. one HTTP request per 2s per *viewer*.

**Decomposition.** Broadcast version: none. Poll version: `interval` (see NEW PRIMITIVES).

**A11y.** `<progress>` has an implicit `role="progressbar"`; `aria-valuenow/min/max` are redundant on a native `<progress>` with `value`/`max` but harmless and help older AT. The **percentage text must be in a separate `role="status"` node** — screen readers do not announce `<progress>` value changes. Associate the label with `for`/`id`. Do not announce every 1% — the throttle serves accessibility too. Indeterminate: `<progress max="100">` with no `value`.

**Native.** A long job is a good candidate for a bridge component driving a native progress HUD; otherwise the web `<progress>` renders fine.

**Pitfalls.**
- Broadcasting per record melts your cable backend and your job queue. Throttle by time or by percentage delta, always.
- Use `broadcast_replace_to` (synchronous) inside a job, not `_later` — `_later` enqueues a second job just to render a 5-line partial.
- `update_columns` avoids callbacks; if the model has `broadcasts_refreshes`, a plain `update!` inside the loop would fire a refresh broadcast per row.
- Turbo's own `.turbo-progress-bar` is unrelated and indeterminate. Different thing, confusingly similar name.
- If the user isn't on the page when the job finishes, they see nothing. Pair with a toast (tier c) or a `noticed` notification.

**Prior art.** [noticed](https://github.com/excid3/noticed) (2701★) for the durable "your export is ready" record. [turbo_power](https://github.com/marcoroth/turbo_power) `set_property` can nudge `progress.value` without re-rendering the partial. No dedicated progress gem is worth it.

---

### Empty states

**Hotwire answer.** Server-rendered `<% if collection.any? %> … <% else %> …empty… <% end %>` inside the container the streams target. **No JS needed.** The only real decision is whether removing the last row can leave the container empty without a re-render — with Turbo 8 `refresh` broadcasts + morphing it can't, which is a good reason to prefer morphing for any list that can become empty.

**Code.**

```erb
<div id="quotes">
  <% if @quotes.any? %>
    <%= render @quotes %>
  <% else %>
    <%= render "quotes/empty" %>
  <% end %>
</div>
```

```erb
<%# app/views/quotes/_empty.html.erb %>
<div id="quotes_empty" class="empty-state">
  <h2>No quotes yet</h2>
  <p>Quotes you create will show up here.</p>
  <%= link_to "New quote", new_quote_path, class: "btn btn--primary" %>
</div>
```

With targeted streams you must maintain it by hand on both edges:

```ruby
def destroy
  @quote.destroy!
  render turbo_stream: [
    turbo_stream.remove(@quote),
    (turbo_stream.append("quotes", partial: "quotes/empty") if Current.account.quotes.none?)
  ].compact
end
```

**Decomposition.** None.

**A11y.** The empty state should be a real heading (`<h2>`) so it appears in the heading outline, with the primary action as a link/button. If it appears as a result of a user action (deleting the last row), the container should be a `role="status"` region or you should flash "Last quote deleted."

**Native.** n/a.

**Pitfalls.** The removing-the-last-row bug and the inverse (adding a row while the empty state is still in the DOM) are covered in detail by the Data-display section — see it for `turbo_stream.remove "quotes_empty"` bookkeeping. Short version: **if a list can become empty, use `broadcasts_refreshes` + morphing and stop hand-maintaining it.**

**Prior art.** None; this is a view convention. [Rails Designer](https://railsdesigner.com/) ships styled empty-state components.

---

### Custom confirmation dialogs (replacing `data-turbo-confirm`)

**Hotwire answer.** Assign a promise-returning function to `Turbo.config.forms.confirm`. One `<dialog>` in the layout, one `confirm` primitive controller, and every `data-turbo-confirm` in the app upgrades at once. **Any tutorial using `Turbo.setConfirmMethod` is pre-Turbo-8 and stale** — it still works but logs a deprecation warning and is slated for removal.

**Code.** The exact call site (`src/core/drive/form_submission.js`, Turbo 8.0.23):

```js
const confirmationMessage = getAttribute("data-turbo-confirm", this.submitter, this.formElement)
if (typeof confirmationMessage === "string") {
  const confirmMethod = typeof config.forms.confirm === "function" ? config.forms.confirm : FormSubmission.confirmMethod
  const answer = await confirmMethod(confirmationMessage, this.formElement, this.submitter)
  if (!answer) return
}
```

So the signature is **`(message: string, formElement: HTMLFormElement, submitter: HTMLElement|undefined) => Promise<boolean> | boolean`**, `await`ed, and the submitter's attribute wins over the form's. Default is `Promise.resolve(confirm(message))`.

```erb
<%# app/views/layouts/application.html.erb — one dialog for the whole app %>
<dialog id="confirm_dialog" class="confirm" aria-labelledby="confirm_title"
        data-controller="confirm focus-trap"
        data-confirm-target="dialog">
  <form method="dialog" class="confirm__form">
    <h2 id="confirm_title" data-confirm-target="title">Are you sure?</h2>
    <p data-confirm-target="message"></p>

    <div data-confirm-target="typeToConfirm" hidden>
      <label for="confirm_phrase">Type <b data-confirm-target="phrase"></b> to confirm</label>
      <input id="confirm_phrase" type="text" autocomplete="off" autocapitalize="off"
             data-confirm-target="input" data-action="input->confirm#validate">
    </div>

    <menu class="confirm__actions">
      <button value="cancel" data-confirm-target="cancel">Cancel</button>
      <button value="confirm" data-confirm-target="accept" class="btn--danger">Confirm</button>
    </menu>
  </form>
</dialog>
```

```js
// app/javascript/controllers/confirm_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "title", "message", "accept", "cancel",
                    "typeToConfirm", "phrase", "input"]

  connect() {
    // Register once. `element` is the form; `submitter` is the button that was clicked.
    Turbo.config.forms.confirm = (message, element, submitter) => this.ask(message, submitter ?? element)
  }

  ask(message, source) {
    const d = this.dialogTarget
    const data = source.dataset

    this.messageTarget.textContent = message
    this.titleTarget.textContent   = data.turboConfirmTitle  ?? "Are you sure?"
    this.acceptTarget.textContent  = data.turboConfirmAccept ?? "Confirm"
    this.acceptTarget.className    = `btn--${data.turboConfirmVariant ?? "danger"}`

    // "type the resource name" variant
    const phrase = data.turboConfirmPhrase
    this.typeToConfirmTarget.hidden = !phrase
    if (phrase) {
      this.phraseTarget.textContent = phrase
      this.inputTarget.value = ""
      this.#required = phrase
      this.acceptTarget.disabled = true
    } else {
      this.#required = null
      this.acceptTarget.disabled = false
    }

    d.showModal()
    this.cancelTarget.focus()   // safe default focus for a destructive action

    return new Promise((resolve) => {
      d.addEventListener("close", () => resolve(d.returnValue === "confirm"), { once: true })
    })
  }

  validate() { this.acceptTarget.disabled = this.inputTarget.value !== this.#required }

  // Resilience: if something (a morph, a stream replace) stripped [open] while the
  // dialog was modal, close() becomes a silent no-op and the page stays inert-locked.
  forceClose() {
    const d = this.dialogTarget
    if (!d.hasAttribute("open")) d.setAttribute("open", "")
    d.close("cancel")
    if (d.matches(":modal")) d.remove()   // last resort: remove beats an inert page
  }

  #required = null
}
```

```erb
<%= button_to "Delete account", account_path, method: :delete, data: {
      turbo_confirm: "This permanently deletes #{@account.name} and all its data.",
      turbo_confirm_title: "Delete account",
      turbo_confirm_accept: "Delete forever",
      turbo_confirm_phrase: @account.name } %>
```

**Decomposition.** `confirm` + `dialog` + `focus-trap`. Native `<dialog showModal()>` already traps focus and handles Esc, so `focus-trap` is belt-and-braces for older Safari. `dismiss` is unnecessary — `method="dialog"` buttons close natively and set `returnValue`.

**A11y.** Native `<dialog>.showModal()` gives you: focus trap, Esc-to-cancel (fires `cancel` then `close` with empty `returnValue` → resolves `false`, correct), `aria-modal`, and inerting the rest of the page. You add: `aria-labelledby` pointing at the title, initial focus on **Cancel** (never on a destructive Confirm), and a visible focus ring. See [WAI-ARIA APG — Dialog (Modal)](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/). The type-to-confirm input needs a real `<label>`; disabling the Confirm button is fine because the reason is on screen and adjacent.

**Native.** In Hotwire Native, override `Turbo.config.forms.confirm` again behind a `turbo-native` check and route to a bridge component that shows a `UIAlertController` / `AlertDialog`. The bridge callback resolves the same promise, so no server change. Type-to-confirm has no native analogue — fall back to a two-step native alert or keep the web dialog on native. See `04-hotwire-native.md`.

**Pitfalls.**
- **`data-turbo-confirm` is silently ignored on a plain `<a href>`.** `FormLinkClickObserver#willFollowLinkToLocation` only converts a link into a form when it has `data-turbo-method` **or** `data-turbo-stream`; the confirm is only read inside `FormSubmission#start`. So `link_to "Delete", path, data: { turbo_confirm: "Sure?" }` with no method just navigates. Use `button_to`, or add `data: { turbo_method: :delete }`.
- **Registering in `connect()` on a controller whose element is inside `<body>` means a morph can re-run it.** Harmless (idempotent assignment) but if you instead register in an initializer, make sure it runs before the first possible submit.
- **The inert-lock trap:** a modal `<dialog>` whose `open` attribute is removed by a morph or a `turbo_stream.replace` remains `:modal` — the page stays inert and `close()` is a **silent no-op**. Keep the dialog outside anything Turbo replaces, mark it `data-turbo-permanent`, and keep the `forceClose()` escape hatch above.
- The promise leaks if the dialog is removed from the DOM before `close` fires — nothing rejects it, and the form submission hangs forever. `forceClose()` on `disconnect()` guards this.
- `Turbo.setConfirmMethod(fn)` — **deprecated**, logs `"Please replace Turbo.setConfirmMethod(confirmMethod) with Turbo.config.forms.confirm = confirmMethod"`. Flag any tutorial using it as pre-2024.
- Returning a bare `false` (not a promise) works — Turbo `await`s the value either way.
- Cross-ref `02-turbo-deep-dive.md` §2.11.

**Prior art.**
- [turbo-confirm](https://github.com/ghiculescu/turbo-confirm) and similar micro-packages exist but are thinner than the 40 lines above.
- [tailwindcss-stimulus-components](https://github.com/excid3/tailwindcss-stimulus-components) ships a `modal` controller you can point at, though native `<dialog>` supersedes it.
- [Rails Designer](https://railsdesigner.com/) and [railsblocks](https://railsblocks.com/) both ship a styled confirm dialog.
- **Superseded:** `rails-ujs` `data-confirm` and the `data-confirm-modal` gem. Both predate Turbo.

---

### Undo (Gmail-style)

**Hotwire answer.** Soft-delete with [discard](https://github.com/jhawthorn/discard) (2424★, active), stream a toast containing an undo `button_to` scoped to the discarded record, and schedule a purge job. The undo action un-discards and streams the row back. This is one of the patterns Hotwire is genuinely *good* at, because "put the row back" is one stream action.

**Code.**

```ruby
# app/models/quote.rb
class Quote < ApplicationRecord
  include Discard::Model          # adds discarded_at, .kept, .discarded, #discard, #undiscard
  default_scope -> { kept }       # opinionated but correct for this pattern
end
```

```ruby
# config/routes.rb
resources :quotes do
  member { patch :undo }
end
```

```ruby
class QuotesController < ApplicationController
  include Flashable

  def destroy
    @quote = Current.account.quotes.find(params[:id])
    @quote.discard!
    PurgeDiscardedJob.set(wait: 30.seconds).perform_later(@quote)

    render turbo_stream: [
      turbo_stream.remove(@quote),
      turbo_stream.append("flashes", partial: "quotes/undo_toast", locals: { quote: @quote })
    ]
  end

  def undo
    # unscoped: the record is discarded, so the default scope hides it
    @quote = Current.account.quotes.with_discarded.find(params[:id])
    @quote.undiscard!

    render turbo_stream: [
      turbo_stream.remove("undo_#{dom_id(@quote)}"),          # kill the toast
      turbo_stream.append("quotes", partial: "quotes/quote", locals: { quote: @quote }),
      *turbo_stream_flash(notice: "Quote restored.")
    ]
  end
end
```

```erb
<%# app/views/quotes/_undo_toast.html.erb %>
<div id="undo_<%= dom_id(quote) %>" class="toast toast--undo" role="status"
     data-controller="timeout dismiss transition"
     data-timeout-delay-value="30000"
     data-action="timeout:fire->dismiss#dismiss
                  mouseenter->timeout#pause mouseleave->timeout#resume">
  <p><%= quote.name %> deleted.</p>
  <%= button_to "Undo", undo_quote_path(quote), method: :patch, class: "toast__undo" %>
  <button type="button" data-action="dismiss#dismiss" aria-label="Dismiss">&times;</button>
</div>
```

```ruby
# app/jobs/purge_discarded_job.rb — the "actually delete" half
class PurgeDiscardedJob < ApplicationJob
  discard_on ActiveJob::DeserializationError   # already gone: fine

  def perform(record)
    record = record.class.with_discarded.find_by(id: record.id)
    return if record.nil? || record.kept?      # user pressed Undo — do nothing
    record.destroy!
  end
end
```

Two details that make this correct rather than merely working:
1. The toast's undo window (`30000`ms) and the purge job's `wait: 30.seconds` are the same number. Keep them in one constant.
2. `PurgeDiscardedJob` re-checks `kept?` instead of trusting the schedule — the user may have undone it from a different tab.

If the row belongs to a live list, broadcast instead of rendering inline: `@quote.broadcast_remove_to(Current.account, :quotes)` on discard and `broadcast_append_to` on undiscard, and skip the `turbo_stream.*` calls above.

**Undoing an arbitrary edit** is a different, harder problem: you need the *previous* attribute set. Use [paper_trail](https://github.com/paper-trail-gem/paper_trail) (7029★) — it stores a `versions` row per change and gives you `record.paper_trail.previous_version` and `version.reify.save!`:

```ruby
class QuotesController < ApplicationController
  def update
    @quote.update!(quote_params)
    version = @quote.versions.last
    render turbo_stream: [
      turbo_stream.replace(@quote, partial: "quotes/quote", locals: { quote: @quote }),
      turbo_stream.append("flashes", partial: "quotes/undo_edit_toast",
                          locals: { quote: @quote, version: version })
    ]
  end

  def undo_edit
    version = @quote.versions.find(params[:version_id])
    version.reify.save!                       # restore the pre-change attributes
    redirect_to @quote, notice: "Change undone."
  end
end
```

[audited](https://github.com/collectiveidea/audited) (3494★, last push 2025-11) is the alternative; `paper_trail` is more actively maintained and its `reify` is the cleaner undo API.

**Decomposition.** `timeout` + `dismiss` + `transition` (the toast), plus `hotkey` if you want `Cmd+Z` bound to the toast's undo button (`data-hotkey="cmd+z"` on the `<button>` — the `hotkey` primitive dispatches a click).

**A11y.** `role="status"` on the toast so the deletion is announced. The undo control must be a real button/link and must be **reachable by keyboard before the toast auto-dismisses** — this is why the undo window is 30s, not 4s, and why `mouseenter->timeout#pause` should be joined by `focusin->timeout#pause`. WCAG 2.2 SC 2.2.1 requires that a time limit be adjustable or extendable; pausing on focus/hover satisfies the "extend" path. Consider not auto-dismissing undo toasts at all.

**Native.** A snackbar-with-action is the canonical native pattern (Android `Snackbar.setAction`, iOS a custom banner). Bridge component, definitely.

**Pitfalls.**
- **`default_scope -> { kept }` bites everywhere.** `find` in the undo action must use `with_discarded`; so must any admin view, any `has_many` count, and any `dependent: :destroy` reasoning. If that scares you, drop the default scope and add `.kept` to every query instead — more verbose, fewer surprises.
- **`dependent: :destroy` still hard-deletes children** when the parent is eventually purged, and `discard` does **not** cascade. Decide explicitly: cascade discard with a callback, or accept that children stay live until purge.
- Uniqueness validations still see discarded rows unless scoped (`validates :slug, uniqueness: { conditions: -> { kept } }`). Deleting and re-creating with the same slug will fail confusingly.
- **A cached Turbo snapshot can resurrect the undo toast** on Back. Add `data-turbo-temporary`.
- If the user navigates away before pressing Undo, the toast is gone (Drive replaces the body) but the record is still discarded and the purge job is still scheduled. That's correct behaviour, but it means undo is *page-scoped* — don't promise more.
- The purge job holds a serialized reference; if the record is hard-deleted by other means the job raises `ActiveJob::DeserializationError`. `discard_on` it.
- Full-text search indexes and counter caches need to be told about discards; `discard` doesn't touch them.

**Prior art.**
- [discard](https://github.com/jhawthorn/discard) — 2424★, last push 2026-06. The right choice; `acts_as_paranoid`/`paranoia` are the **superseded** ancestors (they override `destroy`, which breaks in surprising ways).
- [paper_trail](https://github.com/paper-trail-gem/paper_trail) — 7029★, `reify` for arbitrary-edit undo.
- [audited](https://github.com/collectiveidea/audited) — 3494★, alternative.
- No Hotwire-specific undo gem exists.

---
### Choosing a cable backend (Solid Cable vs Redis vs AnyCable)

**Hotwire answer.** Rails 8 defaults to **Solid Cable** (DB-backed, polling). That default is correct for most apps and materially wrong for a few, and it changes which real-time patterns below are advisable. Know the numbers before you design a chat app.

| | Solid Cable | Redis adapter | AnyCable |
|---|---|---|---|
| Mechanism | polls a `solid_cable_messages` table | Redis pub/sub | Go WebSocket server + RPC (or standalone signed streams) |
| Latency floor | **= `polling_interval`, default 0.1s** (~50ms mean, 100ms worst) | sub-ms | sub-ms |
| Measured RTT @250 VUs | `avg 146ms / p95 234ms` (SQLite) | `avg 69ms / p95 135ms` | — |
| Measured RTT @750 VUs | `avg 548ms / max 5.19s` (SQLite); `avg 822ms / p95 1.97s` (MySQL) | `avg 163ms / p95 438ms` | — |
| Connections/node | bounded by your Ruby app servers | same | **10,000+**, ~34 KB/conn OSS, ~18 KB/conn Pro |
| Ops cost | zero (it's your DB) | one Redis | one Go process |
| Presence | none | none | **built in, OSS** |
| Payload limit | none | none | none |

Benchmarks are Solid Cable's own README ([rails/solid_cable](https://github.com/rails/solid_cable), 343★, active). Defaults verified from `lib/solid_cable/configuration.rb`: `polling_interval: 0.1.seconds`, `message_retention: 1.day`, `autotrim: true`, `silence_polling: true`, `trim_batch_size: 100`. `use_skip_locked` affects **only the trim `DELETE`**, not the read loop — there is **no** `LISTEN/NOTIFY` or trigger-based push anywhere in the gem; it is `SELECT ... WHERE id > last_id`, `sleep 0.1`, repeat, on a thread named `solid_cable_listener`.

```yaml
# config/cable.yml — what Rails 8 generates
production:
  adapter: solid_cable
  connects_to: { database: { writing: cable } }
  polling_interval: 0.1.seconds
  message_retention: 1.day
```

**Decision rule.**
- Notifications, live lists, dashboards, activity feeds, progress bars → **Solid Cable**. A 100ms floor is invisible.
- Chat, typing indicators, presence, anything where humans perceive the delay → **Redis**, or Solid Cable at `polling_interval: 0.01.seconds` (README: "becomes comparable to Redis" — `avg 84ms / p95 150ms` @250 VUs — but that's 10× the `SELECT` load).
- \>5k concurrent sockets, or you want presence and whispers for free → **AnyCable** ([anycable/anycable-rails](https://github.com/anycable/anycable-rails), 535★). Presence is **open source**, not Pro-gated; Pro ($1490/yr) adds Redis-backed *cluster* presence and ~2× better memory per connection.
- Rails' dedicated PostgreSQL adapter (`adapter: postgresql`, `NOTIFY`-based) is faster than Solid Cable but has an **8 KB payload limit** — and a morph-triggering `refresh` broadcast is tiny while an `append` of a rendered partial is often not. That limit is exactly why Solid Cable exists.

**Pitfalls.**
- Solid Cable's autotrim does a `DELETE` on broadcast. High broadcast volume + autotrim = write contention on the same table the listener polls. `autotrim: false` + a cron `SolidCable::Message.trim` is measurably faster.
- Every app server runs its own listener thread polling every 100ms. 20 dynos = 200 `SELECT`s/sec at idle.
- Action Cable's `worker_pool_size` defaults to **4** (`actioncable/lib/action_cable/configuration.rb`) — that's four threads handling *all* channel callbacks per server. A slow `subscribed` blocks everyone.
- PaaS platforms that bill per connection or cap connection duration make WebSockets expensive; see "Polling as the boring alternative".

**Prior art.** [rails/solid_cable](https://github.com/rails/solid_cable) · [anycable.io](https://anycable.io/) · [docs.anycable.io/anycable-go/presence](https://docs.anycable.io/anycable-go/presence) · [actioncable-enhanced-postgresql-adapter](https://github.com/jhawthorn/actioncable-enhanced-postgresql-adapter) works around the 8 KB `NOTIFY` limit.

---

### Live-updating lists

**Hotwire answer.** Two legitimate answers and you must pick deliberately. **Default: `broadcasts_refreshes` + `<meta name="turbo-refresh-method" content="morph">`** — the server re-renders the page, idiomorph applies the diff, and correctness is structural. **Optimize to targeted `broadcast_append_to` / `broadcast_remove_to`** only when the page is expensive to render, huge, or append-only (chat). Every pre-2024 tutorial that hand-rolls a stream action per mutation is describing the *optimization*, not the default — Turbo 8 obsoleted that as the starting point. Always use the `_later` variants.

**Code.** The 2026 default:

```ruby
# app/models/board.rb
class Board < ApplicationRecord
  has_many :columns
  broadcasts_refreshes                # after_create → "boards" stream; after_update/destroy → self
end

# app/models/column.rb
class Column < ApplicationRecord
  belongs_to :board, touch: true      # touching the board fires ITS refresh broadcast
  broadcasts_refreshes_to :board      # after_commit on any change
end
```

```erb
<%# app/views/boards/show.html.erb %>
<% turbo_refreshes_with method: :morph, scroll: :preserve %>
<%= turbo_stream_from @board %>

<div id="columns">
  <%= render @board.columns %>
</div>
```

That's the whole feature. `broadcasts_refreshes` is literally three callbacks (turbo-rails `app/models/concerns/turbo/broadcastable.rb`):

```ruby
def broadcasts_refreshes(stream = model_name.plural)
  after_create_commit  -> { broadcast_refresh_later_to(stream) }
  after_update_commit  -> { broadcast_refresh_later }
  after_destroy_commit -> { broadcast_refresh }        # sync: no record left to deserialize
end
```

The targeted alternative, when you need it:

```ruby
class Message < ApplicationRecord
  belongs_to :room
  broadcasts_to :room, inserts_by: :append, target: "messages"
end
```

```ruby
# expands to
after_create_commit  -> { broadcast_action_later_to(room, action: :append, target: "messages") }
after_update_commit  -> { broadcast_replace_later_to(room) }
after_destroy_commit -> { broadcast_remove_to(room) }   # sync — remove needs no render
```

**Why `_later` almost always.** `broadcast_append_later_to` enqueues `Turbo::Streams::ActionBroadcastJob`, which renders the partial **in the job**. The synchronous version renders inside your request/`after_commit`, so a 30ms partial × 3 broadcasts is 90ms added to every write. The one exception is `remove`, which has nothing to render — turbo-rails itself uses the sync version there.

**Request-id debouncing** (so the actor doesn't get a double update) works only on the `refresh` path:

```ruby
def broadcast_refresh_later_to(*streamables, request_id: Turbo.current_request_id, **opts)
  refresh_debouncer_for(*streamables, request_id: request_id).debounce do
    Turbo::Streams::BroadcastStreamJob.perform_later stream_name,
      content: turbo_stream_refresh_tag(request_id: request_id, **opts).to_str
  end
end
```

End to end: Turbo's `fetch` stamps `X-Turbo-Request-Id: <uuid>` and remembers it in a `LimitedSet(20)`; `Turbo::RequestIdTracking` (an `around_action`) parks it in `Turbo.current_request_id`; the broadcast carries `request-id="<uuid>"`; `StreamActions.refresh` calls `session.refresh(baseURI, { requestId })` which **skips if `recentRequests.has(requestId)`**. Net: the tab that caused the change already has the HTTP response and ignores the socket echo; everyone else refreshes. Two debounce layers — client 150ms, server `Turbo::Debouncer::DEFAULT_DELAY = 0.5`s keyed by stream+request-id — so a loop touching 200 records emits **one** broadcast.

Targeted broadcasts get **none of this**. `broadcast_append_later_to` does not pass a request id, so the actor receives their own append over the socket in addition to their HTTP response. If your controller also renders the row, you get it twice. Fix by rendering nothing in the controller and letting the broadcast be the only source of truth, or by giving the row a stable `dom_id` so `append`'s `removeDuplicateTargetChildren()` collapses them (see Optimistic UI).

**Decomposition.** None on the happy path. `intersection` if you pair a live list with infinite scroll; `autoscroll` (see NEW PRIMITIVES) if the list is bottom-anchored.

**A11y.** A list that changes under the user without their action needs a live region — but **do not** put `aria-live="polite"` on a 200-row list: every morph re-announces everything. Instead keep a separate `role="status"` sentinel and update its text ("3 new messages"), or announce nothing and provide a "3 new" jump button. Morphing preserves focus and scroll, which is the accessibility win over `replace`. If rows are interactive, ensure a removed row's focus goes somewhere sensible — morph leaves focus on a detached node otherwise.

**Native.** A `refresh` broadcast in Hotwire Native triggers a full web-view page refresh, which on a native screen can look like a flash. Prefer targeted streams on screens that are native-shelled, or gate with `turbo-native`. See `04-hotwire-native.md`.

**Pitfalls.**
- **Morphing sends the whole page to every subscriber on every change.** 500 viewers × 1 change = 500 full page renders (server-side, on the refresh each client fetches). That is the actual cost, and it is why targeted streams still exist.
- `broadcasts_refreshes` on a hot model + `touch: true` up a hierarchy = a refresh storm. The 0.5s server debouncer helps within one request, not across requests.
- The destroy callback in both `broadcasts_refreshes` and `broadcasts_to` is **synchronous**, so a destroy in a tight loop broadcasts per record.
- `broadcasts_to` renders `to_partial_path` by default; if that partial needs `current_user` it will blow up in the job. Broadcast partials must be user-agnostic — see "Secure per-user broadcasting".
- `turbo_stream_from @maybe_nil` raises `ArgumentError, "streamables can't be blank"`.
- `turbo_refreshes_with` uses `provide :head`, so your layout **must** have `<%= yield :head %>` inside `<head>`. Without it the meta tags never render and you silently get `replace` instead of `morph` — a very common "why isn't morphing working" report.
- Cross-ref `02-turbo-deep-dive.md` §4.4 (streams over WebSockets), §5.5 (request-id mechanism in full), §5.6 (`broadcasts_refreshes`), §5.7 (when morph beats targeted streams).

**Prior art.** [turbo-rails](https://github.com/hotwired/turbo-rails) is the whole answer. [hotrails.dev Ch. 5–6](https://www.hotrails.dev/turbo-rails) for the tutorial. [37signals — A happier happy path in Turbo with morphing](https://dev.37signals.com/a-happier-happy-path-in-turbo-with-morphing/) is the case for the default. [turbo_power](https://github.com/marcoroth/turbo_power) if you need custom actions in the mix.

---

### Secure per-user broadcasting

**Hotwire answer.** `turbo_stream_from current_user` signs the stream name with an `ActiveSupport::MessageVerifier` so a client cannot forge one. That is the *only* thing it does. It is **not** authorization, it does **not** expire, and — the one that actually bites — **one broadcast renders one HTML payload for every subscriber**, so anything user-specific in the partial leaks. Turbo 8's real answer to that is: broadcast a `refresh` and let each client re-fetch the page as themselves.

**Code.** The mechanism, verified (`turbo-rails` `app/helpers/turbo/streams_helper.rb`, `app/channels/turbo/streams/stream_name.rb`, `lib/turbo-rails.rb`):

```ruby
def turbo_stream_from(*streamables, **attributes)
  raise ArgumentError, "streamables can't be blank" unless streamables.any?(&:present?)
  attributes[:channel] = attributes[:channel]&.to_s || "Turbo::StreamsChannel"
  attributes[:"signed-stream-name"] = Turbo::StreamsChannel.signed_stream_name(streamables)
  tag.turbo_cable_stream_source(**attributes)
end

def signed_stream_name(streamables) = Turbo.signed_stream_verifier.generate stream_name_from(streamables)
def verified_stream_name(signed)    = Turbo.signed_stream_verifier.verified signed

# HMAC-SHA256, JSON serializer, key derived from secret_key_base:
ActiveSupport::MessageVerifier.new(signed_stream_verifier_key, digest: "SHA256", serializer: JSON)
```

```ruby
# Turbo::StreamsChannel#subscribed
def subscribed
  if stream_name = verified_stream_name_from_params then stream_from stream_name else reject end
end
```

**The threat model, precisely.**

*Blocked:* a user opens devtools, edits `signed-stream-name` to point at `gid://app/Account/99:entries`, reconnects. `MessageVerifier#verified` returns `nil`, `subscribed` calls `reject`, no data flows. They cannot mint a signature without `secret_key_base`.

*Not blocked, and you must handle each:*
1. **Signing is not authorization.** If your view renders `turbo_stream_from @other_persons_project` because you forgot a policy check, the token is valid and the subscription succeeds. The gem trusts that whoever rendered the tag did the authorization.
2. **The token never expires** (`generate` is called with no `expires_in`). A signed stream name in a shared screenshot, a cached HTML page, a browser extension, or a support-session recording works forever from any browser, with no session at all.
3. **It's signed, not encrypted.** Base64-decode the token and you get the plaintext stream name, including record GlobalIDs.
4. **The payload is identical for every subscriber.** This is the big one.

Mitigation 1 — **authorize the subscription** with a custom channel:

```ruby
# app/channels/project_channel.rb
class ProjectChannel < ActionCable::Channel::Base
  extend  Turbo::Streams::Broadcasts, Turbo::Streams::StreamName
  include Turbo::Streams::StreamName::ClassMethods

  def subscribed
    stream_name = verified_stream_name_from_params
    if stream_name.present? && authorized?(stream_name)
      stream_from stream_name
    else
      reject
    end
  end

  private
    def authorized?(stream_name)
      gid = stream_name.split(":").first
      project = GlobalID::Locator.locate(gid)
      project && current_user.can_read?(project)
    rescue ActiveRecord::RecordNotFound
      false
    end
end
```

```erb
<%= turbo_stream_from @project, :items, channel: ProjectChannel %>
```

This closes leaks 1 and 2 — a stolen token still fails because `current_user` is checked at subscribe time and on every reconnect.

Mitigation 2 — **the per-user content leak.** Consider:

```erb
<%# app/views/comments/_comment.html.erb — broadcast to a whole project %>
<div id="<%= dom_id(comment) %>">
  <p><%= comment.body %></p>
  <time><%= l comment.created_at, format: :short %></time>          <%# whose timezone? %>
  <% if comment.user == current_user %><%= link_to "Edit", … %><% end %>  <%# BOOM %>
</div>
```

Rendered in `ActionBroadcastJob` there is no `current_user` — it either raises or, worse, resolves to something stale and every subscriber gets the *same* answer. Three fixes, in order of preference:

```ruby
# BEST — Turbo 8: broadcast a refresh, let each client re-render the page AS ITSELF.
class Comment < ApplicationRecord
  belongs_to :project
  broadcasts_refreshes_to :project
end
```
Each subscriber's browser issues its own authenticated GET. Permissions, timezones, "your" vs "their", feature flags — all correct, for free. This is the single strongest argument for morphing over targeted streams and it is a *security* argument, not an ergonomics one.

```ruby
# GOOD — broadcast the neutral payload, personalise on the client.
# Timestamps: the <relative-time> web component renders in the VIEWER's locale/timezone.
```
```erb
<%# @github/relative-time-element — no server-side timezone assumption at all %>
<relative-time datetime="<%= comment.created_at.iso8601 %>" format="datetime"
               tense="past"><%= comment.created_at.iso8601 %></relative-time>
<div id="<%= dom_id(comment) %>" data-author-id="<%= comment.user_id %>">…</div>
```
```css
/* body carries data-current-user-id; CSS does the "is this mine" branch */
[data-author-id]:not([data-author-id="0"]) .comment__edit { display: none }
```

```ruby
# ACCEPTABLE, EXPENSIVE — fan out per user.
project.members.find_each do |member|
  Turbo::StreamsChannel.broadcast_append_later_to(
    member, :comments, target: "comments",
    partial: "comments/comment", locals: { comment: comment, viewer: member })
end
```
N renders and N broadcasts per comment. Only for small N.

**Decomposition.** `relative-time` (client-side timestamp localisation is the most common per-user leak and the easiest to fix).

**A11y.** n/a beyond the live-list guidance.

**Native.** Signed stream names are embedded in HTML the native app caches. A cached screen from a previous session can hold a still-valid token — another reason to authorize in `subscribed` rather than trusting the token.

**Pitfalls.**
- **Never derive a stream name from user input.** `turbo_stream_from params[:room]` signs whatever they typed, and the signature makes it look safe. Always start from a record you fetched through an authorized scope: `turbo_stream_from Current.account.rooms.find(params[:id])`.
- `broadcast_*_to` on a model fires regardless of who may see the record. Authorization lives at subscribe time, not broadcast time.
- Rotating `secret_key_base` invalidates every rendered token; open tabs silently stop receiving updates until reload. Set `config.turbo.signed_stream_verifier_key` explicitly if you rotate.
- A partial that calls `current_user` (or any `Current.*` attribute) works in the request path and explodes or lies in `ActionBroadcastJob`. Test broadcasts with `perform_enqueued_jobs`.
- `stream_name_from` joins with `:`, so `turbo_stream_from user, :notifications` → `"gid://app/User/5:notifications"`. Two different streamable lists that stringify identically share a stream.
- Cross-ref `02-turbo-deep-dive.md` §4.5.

**Prior art.** [hotrails.dev — Turbo Streams and security](https://www.hotrails.dev/turbo-rails/turbo-streams-security) is the most rigorous public treatment. [AnyCable signed streams](https://docs.anycable.io/guides/hotwire) lets `anycable-go` verify tokens without an RPC round-trip: `config.turbo.signed_stream_verifier_key = AnyCable.config.secret` + `ANYCABLE_TURBO_STREAMS=true` — but note that mode does **not** run your `subscribed` authorization, so it re-opens leak 1.

---

### Notification bell with unread count

**Hotwire answer.** Store notifications as records ([noticed](https://github.com/excid3/noticed), 2701★). Subscribe the layout to `turbo_stream_from current_user, :notifications`. On create, `broadcast_replace_to` the **count badge** and `broadcast_prepend_to` the **dropdown list** — two small targets, one broadcast each, both `_later`. The dropdown itself is a lazy `<turbo-frame>` so the list is only rendered when opened.

**Code.**

```erb
<%# app/views/layouts/_notification_bell.html.erb — in the layout %>
<%= turbo_stream_from current_user, :notifications %>

<div class="bell" data-controller="popover dismiss click-outside"
     data-action="click-outside->dismiss#dismiss">
  <button type="button" popovertarget="notifications_panel"
          aria-haspopup="true" aria-expanded="false"
          aria-describedby="notification_count">
    <%= inline_svg "bell.svg" %>
    <%= render "layouts/notification_count", user: current_user %>
  </button>

  <div id="notifications_panel" popover class="bell__panel">
    <h2>Notifications</h2>
    <%= turbo_frame_tag "notifications_list", src: notifications_path, loading: :lazy do %>
      <div class="skeleton skeleton--line" aria-hidden="true" style="display:block"></div>
    <% end %>
  </div>
</div>
```

```erb
<%# app/views/layouts/_notification_count.html.erb — the ONLY thing that broadcasts %>
<span id="notification_count" class="bell__badge <%= "bell__badge--zero" if user.unread_notifications_count.zero? %>"
      role="status" aria-live="polite">
  <% if user.unread_notifications_count.positive? %>
    <span aria-hidden="true"><%= user.unread_notifications_count > 99 ? "99+" : user.unread_notifications_count %></span>
    <span class="sr-only"><%= pluralize user.unread_notifications_count, "unread notification" %></span>
  <% end %>
</span>
```

```ruby
# app/models/notification.rb
class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User", counter_cache: :unread_notifications_count

  after_create_commit  :broadcast_arrival
  after_update_commit  :broadcast_count, if: :saved_change_to_read_at?
  after_destroy_commit :broadcast_count

  private
    def broadcast_arrival
      broadcast_prepend_later_to recipient, :notifications,
        target: "notifications_list", partial: "notifications/notification"
      broadcast_count
    end

    def broadcast_count
      recipient.reload
      Turbo::StreamsChannel.broadcast_replace_later_to recipient, :notifications,
        target: "notification_count",
        partial: "layouts/notification_count", locals: { user: recipient }
    end
end
```

Mark-as-read, with the count following automatically:

```ruby
class NotificationsController < ApplicationController
  def index                      # the lazy frame's src
    @notifications = current_user.notifications.newest_first.limit(20)
  end

  def update                     # mark one read
    notification = current_user.notifications.find(params[:id])
    notification.update!(read_at: Time.current)   # triggers broadcast_count
    render turbo_stream: turbo_stream.replace(notification,
             partial: "notifications/notification", locals: { notification: notification })
  end

  def read_all
    current_user.notifications.unread.update_all(read_at: Time.current)
    current_user.update!(unread_notifications_count: 0)   # update_all skipped the counter cache
    render turbo_stream: [
      turbo_stream.replace("notification_count", partial: "layouts/notification_count",
                           locals: { user: current_user }),
      turbo_stream.replace("notifications_list", partial: "notifications/list",
                           locals: { notifications: current_user.notifications.newest_first.limit(20) })
    ]
  end
end
```

**Count drift** is the defining bug of this pattern. Sources, in order of likelihood:
1. `update_all` / `delete_all` bypass `counter_cache` — the badge and reality diverge permanently. Reset explicitly (above) or use `User.reset_counters(id, :notifications)`.
2. The badge rendered in a *cached* layout fragment while the count changed.
3. Two tabs: tab A marks read, tab B's badge only updates if B is also subscribed — it is, because the subscription is in the layout. If you put it in the panel instead, B never learns.
4. `recipient.reload` omitted, so the broadcast renders the pre-update count.

The cheap structural fix: make the badge derive from a query, not a counter, and broadcast `refresh` instead — then the count is whatever the server says on re-render, and drift is impossible. Costs a page render per notification.

**Decomposition.** `popover` (prefer the native Popover API: `popovertarget` gives you light-dismiss and top-layer for free) + `dismiss` + `click-outside` + `roving-focus` (arrow keys through the list) + `relative-time` (timestamps must be client-rendered — see the per-user leak above).

**A11y.** Follow [WAI-ARIA APG — Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/), not Menu: notification panels contain links and buttons, not menu items, so `role="menu"` is wrong and breaks screen-reader link navigation. Keyboard: Enter/Space toggles, Esc closes and returns focus to the bell, Tab moves through panel contents. The badge needs a text alternative — "3" alone is meaningless; render `<span class="sr-only">3 unread notifications</span>`. `aria-live="polite"` on the badge announces new arrivals; use `polite`, never `alert`. `aria-expanded` must be kept in sync by the `popover`/`disclosure` controller.

**Native.** This should be a native screen via path configuration, or better, a push notification. Rendering a web dropdown inside a native nav bar is the classic Hotwire Native tell. The badge itself maps to `UIApplication.applicationIconBadgeNumber` / `navigator.setAppBadge` — [ONCE Campfire's `badge_dot_controller.js`](https://github.com/basecamp/once-campfire) does exactly this from the web side. See `04-hotwire-native.md`.

**Pitfalls.**
- Broadcasting the whole panel instead of the count means every notification re-renders 20 rows for every subscriber. Broadcast the badge; let the frame lazy-load the list.
- A lazy frame inside a `popover` that starts `display: none` never intersects, so it never loads. Native `[popover]` uses `display: none` until shown — the frame loads on first open, which is what you want, but verify it in your browser matrix.
- If the panel is open when a `broadcast_prepend` lands, the new row appears above the scroll position and shifts content. Anchor with `overflow-anchor` or prepend below a sticky header.
- `counter_cache` on a hot column serialises writes to the `users` row. At volume, denormalise to a separate table or compute on read.
- Don't `turbo_stream_from` inside the panel — it's re-created on every page render and drops the subscription during morphs.

**Prior art.** [noticed](https://github.com/excid3/noticed) (2701★, active) — delivery methods including ActionCable and a `Noticed::Event` record model; the canonical choice. [GoRails — Notifications with Noticed and Hotwire](https://gorails.com/episodes/rails-notifications-with-noticed). [@github/relative-time-element](https://github.com/github/relative-time-element) for timestamps. [stimulus-components `dropdown`](https://www.stimulus-components.com/docs/stimulus-dropdown) if you don't want the native Popover API.

---

### Live chat

**Hotwire answer.** The canonical app. `broadcasts_to :room` with `inserts_by: :append`, `turbo_stream_from @room` in the view, and a Stimulus controller that intercepts `turbo:before-stream-render` to keep the container pinned to the bottom **only if the user was already near the bottom**. This is one of the few places you should *not* use morphing: an append-only log should not re-render its history on every message.

**Code.**

```ruby
# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :room, touch: true
  belongs_to :creator, class_name: "User"

  before_create -> { self.client_message_id ||= Random.uuid }
  def to_key = [ client_message_id ]        # dom_id == "message_<uuid>" — see Optimistic UI

  after_create_commit  -> { broadcast_append_later_to room, :messages, target: "messages" }
  after_update_commit  -> { broadcast_replace_later_to room, :messages }
  after_destroy_commit -> { broadcast_remove_to room, :messages }
end
```

```erb
<%# app/views/rooms/show.html.erb %>
<%= turbo_stream_from @room, :messages %>

<div class="chat" data-controller="autoscroll"
     data-action="turbo:before-stream-render@document->autoscroll#beforeStreamRender">
  <div id="messages" class="chat__messages" data-autoscroll-target="container"
       role="log" aria-live="polite" aria-relevant="additions" aria-label="Messages">
    <%= turbo_frame_tag "older_messages", src: room_messages_path(@room, before: @messages.first&.id),
          loading: :lazy %>
    <%= render @messages %>
  </div>

  <button type="button" class="chat__jump" hidden data-autoscroll-target="jump"
          data-action="autoscroll#toBottom">New messages ↓</button>
</div>
```

The fiddly bit — scroll management on `turbo:before-stream-render`. The event's `detail.render` is **reassignable**, which is the officially supported hook (`src/elements/stream_element.js`):

```js
get beforeRenderEvent() {
  return new CustomEvent("turbo:before-stream-render", {
    bubbles: true, cancelable: true,
    detail: { newStream: this, render: StreamElement.renderElement }
  })
}
```

```js
// app/javascript/controllers/autoscroll_controller.js
// Modelled on ONCE Campfire's ScrollManager + messages_controller.
import { Controller } from "@hotwired/stimulus"

const THRESHOLD = 100   // px from the bottom that still counts as "at the bottom"

export default class extends Controller {
  static targets = ["container", "jump"]

  connect() { this.toBottom() }

  beforeStreamRender(event) {
    const stream = event.detail.newStream
    if (stream.getAttribute("target") !== this.containerTarget.id) return

    const wasPinned = this.#nearBottom
    const render    = event.detail.render          // capture the original renderer

    event.detail.render = async (streamElement) => {
      await render(streamElement)                  // let Turbo do the DOM work first
      await new Promise(requestAnimationFrame)     // wait for layout
      if (wasPinned) {
        this.toBottom()
      } else {
        this.jumpTarget.hidden = false             // don't yank the user's scroll
      }
    }
  }

  toBottom() {
    this.containerTarget.scrollTop = this.containerTarget.scrollHeight
    this.jumpTarget.hidden = true
  }

  get #nearBottom() {
    const el = this.containerTarget
    return el.scrollHeight - el.scrollTop - el.clientHeight <= THRESHOLD
  }
}
```

Three rules this encodes, all learned the hard way:
1. **Measure before the render, scroll after it.** Reading `scrollHeight` after insertion gives you the new height and you can't tell whether the user was pinned.
2. **Never force-scroll a user who scrolled up.** Show a "New messages" affordance instead.
3. **Reassign `detail.render`, don't `preventDefault()`.** Preventing it drops the message entirely.

**"My own message appears twice."** Three causes, three fixes:
- *The controller renders the message AND the broadcast delivers it.* Fix: the controller returns `head :ok` (or nothing) and the broadcast is the only renderer.
- *Optimistic client render + broadcast.* Fix: the `client_message_id` / `to_key` trick above — Turbo's `append` calls `removeDuplicateTargetChildren()` and collapses the two because the ids match. Verified in `src/elements/stream_element.js`.
- *Two subscriptions.* `turbo_stream_from` rendered both in the layout and the view, or a `<turbo-frame>` reload duplicating the `turbo-cable-stream-source`. Check the DOM for two of them.

**Pagination of history.** Load newest-first, prepend older on scroll-up, and preserve scroll position:

```ruby
class MessagesController < ApplicationController
  def index
    @messages = @room.messages.before(params[:before]).newest_first.limit(30).reverse
    render partial: "messages/page", locals: { messages: @messages, room: @room }
  end
end
```

```erb
<%# app/views/messages/_page.html.erb %>
<%= turbo_frame_tag "older_messages", src: (messages.any? ? room_messages_path(room, before: messages.first.id) : nil),
      loading: :lazy %>
<%= render messages %>
```

The frame replaces itself with a new lazy frame plus the page of messages, so scrolling up loads the next page automatically — no JS. The scroll jump needs the mirror of `autoscroll`: capture `scrollHeight` before the frame renders and add the delta after (Campfire's `ScrollManager#keepScroll`).

**Decomposition.** `autoscroll` (NEW) + `intersection` (load-older trigger, if you don't use `loading: :lazy`) + `relative-time` + `dirty-form` (warn on navigating away mid-compose). Typing indicator and presence are separate patterns below.

**A11y.** `role="log"` with `aria-live="polite"` and `aria-relevant="additions"` on the message container — `log` is specified for exactly this (sequential, append-only, most recent at the end) and instructs AT to announce only the addition, not the whole list. `aria-atomic="false"`. Give it `aria-label`. The "New messages" button must be keyboard-reachable and should also be announced (`role="status"` wrapper). Do not put `aria-live` on the whole chat pane — the composer is in there and every keystroke would be announced. Each message needs its author in text, not only in an avatar image.

**Native.** Chat is the single strongest case for a **native screen** via path configuration. The scroll physics, keyboard avoidance, and message composer are all things web gets subtly wrong inside a web view. If you must keep it web, hide web chrome and bridge the composer. See `04-hotwire-native.md`.

**Pitfalls.**
- **Solid Cable's 100ms polling floor is perceptible in chat.** Its own benchmarks show `p95 234ms` at 250 concurrent users on SQLite and seconds at 750. Use Redis or drop `polling_interval` to `0.01.seconds`.
- Don't use `broadcasts_refreshes` for chat — every message re-renders and morphs the whole room, including all history.
- `belongs_to :room, touch: true` combined with `broadcasts_refreshes` on `Room` gives you both mechanisms firing. Pick one.
- Turbo's `append` action fires `removeDuplicateTargetChildren()` which compares **`id` on direct children of the target**. If your partial's root element has no `id`, dedupe silently does nothing.
- `scrollTop = scrollHeight` before images/embeds load lands short. Re-run on `load` of media, or reserve space with `width`/`height` attributes.
- Sticky-bottom via CSS (`flex-direction: column-reverse`) avoids most of this JS but inverts your DOM order and breaks `role="log"` semantics and text selection. Not worth it.

**Prior art.** [ONCE Campfire](https://github.com/basecamp/once-campfire) — the reference implementation; read `app/javascript/models/scroll_manager.js`, `controllers/messages_controller.js`, `app/models/message/broadcasts.rb`. [hotrails.dev](https://www.hotrails.dev/turbo-rails) chapters 5–7. [David Colby — live commenting system](https://www.colby.so/posts/using-hotwire-and-rails-to-build-a-commenting-system). [pagy](https://ddnexus.github.io/pagy/) has documented Turbo Frame + infinite-scroll support for the history pagination.

---

### Typing indicators

**Hotwire answer.** **Drop below Turbo Streams to a raw ActionCable channel.** Typing state is ephemeral, high-frequency, and per-user — it must never touch the database, must never be a broadcast of rendered HTML, and must expire on its own. This is the honest boundary of Turbo Streams: a `<turbo-stream>` is a DOM mutation, and "Alice is typing" is state with a TTL. Throttle outbound at ~3s, expire inbound at ~5s client-side.

**Code.** Verified against ONCE Campfire (`app/channels/typing_notifications_channel.rb`, `app/javascript/controllers/typing_notifications_controller.js`).

```ruby
# app/channels/typing_notifications_channel.rb
class TypingNotificationsChannel < ApplicationCable::Channel
  def subscribed
    @room = current_user.rooms.find(params[:room_id])   # authorize here
    stream_for @room
  rescue ActiveRecord::RecordNotFound
    reject
  end

  def start(_data) = broadcast_to(@room, action: "start", user: user_attributes)
  def stop(_data)  = broadcast_to(@room, action: "stop",  user: user_attributes)

  private
    def user_attributes = current_user.slice(:id, :name)
end
```

No database write, no `after_commit`, no rendered partial — a JSON message straight through the pubsub backend.

```js
// app/javascript/controllers/typing_indicator_controller.js
import { Controller } from "@hotwired/stimulus"
import { cable } from "@hotwired/turbo-rails"

const SEND_THROTTLE = 3000   // don't spam the socket while someone types a paragraph
const EXPIRE_AFTER  = 5000   // clear a name if we stop hearing from them

export default class extends Controller {
  static targets = ["output"]
  static values  = { roomId: Number, userId: Number }

  async connect() {
    this.typers  = new Map()   // name -> expiry timer
    this.channel = await cable.subscribeTo(
      { channel: "TypingNotificationsChannel", room_id: this.roomIdValue },
      { received: this.#received }
    )
  }

  disconnect() {
    this.channel?.unsubscribe()
    this.typers.forEach(clearTimeout)
  }

  // data-action="input->typing-indicator#typing blur->typing-indicator#stopped
  //              turbo:submit-end->typing-indicator#stopped"
  typing(event) {
    if (!event.target.value && !event.target.textContent.trim()) return this.stopped()
    const now = Date.now()
    if (now - (this.lastSent ?? 0) < SEND_THROTTLE) return
    this.lastSent = now
    this.channel.send({ action: "start" })
  }

  stopped() {
    this.lastSent = 0
    this.channel?.send({ action: "stop" })
  }

  #received = ({ action, user }) => {
    if (user.id === this.userIdValue) return          // ignore our own echo
    if (action === "start") this.#add(user.name) else this.#remove(user.name)
  }

  #add(name) {
    clearTimeout(this.typers.get(name))
    // Client-side TTL: the "stop" message may never arrive (tab closed, network drop).
    this.typers.set(name, setTimeout(() => this.#remove(name), EXPIRE_AFTER))
    this.#render()
  }

  #remove(name) {
    clearTimeout(this.typers.get(name))
    this.typers.delete(name)
    this.#render()
  }

  #render() {
    const names = [...this.typers.keys()]
    this.outputTarget.textContent =
      names.length === 0 ? "" :
      names.length === 1 ? `${names[0]} is typing…` :
      names.length === 2 ? `${names[0]} and ${names[1]} are typing…` :
                           `${names.length} people are typing…`
  }
}
```

```erb
<div data-controller="typing-indicator"
     data-typing-indicator-room-id-value="<%= @room.id %>"
     data-typing-indicator-user-id-value="<%= current_user.id %>">
  <p class="typing" aria-live="polite" aria-atomic="true"
     data-typing-indicator-target="output"></p>

  <%= form_with model: [@room, Message.new], data: {
        action: "input->typing-indicator#typing blur->typing-indicator#stopped
                 turbo:submit-end->typing-indicator#stopped" } do |f| %>
    <%= f.text_area :body %>
  <% end %>
</div>
```

**If you insist on staying in Turbo.** `Turbo::StreamsChannel.broadcast_action_to(room, action: :typing, target: "typing", ...)` with a custom stream action registered client-side works and is worse: you serialise HTML for a two-word status, you pay a render, and you still need the client-side TTL. Do it only if you want the indicator rendered server-side for i18n. Register the action with `StreamActions` (see `02-turbo-deep-dive.md` §4.6).

**On AnyCable**, this pattern becomes one line — **whispers** are client-to-client and never reach your backend:

```ruby
def subscribed = stream_for(@room, whisper: true)
```
```js
chatChannel.whisper({ event: "typing", name: user.name })
chatChannel.on("message", (msg) => { if (msg.event === "typing") show(msg.name) })
```
([docs.anycable.io/js/presence](https://docs.anycable.io/js/presence)). Note the Action Cable fallback path broadcasts whispers to **all** clients including the sender, so keep the self-echo guard.

**Decomposition.** `cable-channel` (NEW — subscribe and dispatch received payloads as DOM events) + `timeout` (per-typer TTL). Throttling is not a controller: it's a plain `Date.now()` guard, or `useThrottle`/`useDebounce` from [stimulus-use](https://stimulus-use.github.io/stimulus-use/).

**A11y.** `aria-live="polite"` with `aria-atomic="true"` on the output so the whole phrase is re-read rather than word diffs. Consider suppressing it for screen-reader users entirely — a constantly-changing live region during composition is genuinely hostile. Never `role="alert"`. The indicator must not shift layout (reserve its line height) or the message list jumps on every keystroke.

**Native.** Bridge component if you want the native "typing" bubble; otherwise leave it web and accept it looks web.

**Pitfalls.**
- **Never persist typing state.** A `typing_at` column plus `broadcasts_refreshes` means a full page re-render per keystroke for every participant. This is the single worst real-time mistake in the Rails ecosystem.
- The `stop` message is unreliable: closed tabs, killed networks, and backgrounded mobile browsers never send it. The client-side TTL is **required**, not defensive.
- Solid Cable will happily deliver these, but each one is an INSERT plus a poll pickup plus a trim DELETE. At 3s throttle × N typers × M rooms this is real DB write load. Redis or AnyCable for a busy app.
- `cable.subscribeTo` from `@hotwired/turbo-rails` returns a promise — `await` it or `this.channel` is undefined when `disconnect()` runs.
- Turbo Drive caches the page; on restore, `connect()` re-subscribes but stale typer names may still be in the DOM. Clear `outputTarget` in `connect()`.
- Guard against your own echo (`user.id === this.userIdValue`); ActionCable's `broadcast_to` has no "except sender".

**Prior art.** [ONCE Campfire](https://github.com/basecamp/once-campfire) `app/channels/typing_notifications_channel.rb` + `app/javascript/controllers/typing_notifications_controller.js` — verified source for the shape above. [AnyCable whispers](https://docs.anycable.io/js/presence). No gem exists and none should.

---

### Presence (who's online)

**Hotwire answer.** ActionCable `subscribed` / `unsubscribed` writing to a **TTL-backed store**, plus a client heartbeat. Turbo Streams is only involved at the last step (broadcasting the re-rendered avatar list). The critical design fact: **`unsubscribed` is not reliable** — a crashed tab, a killed process, or a dropped network means it may fire late or never — so presence must be a *lease you renew*, not a flag you set and clear. If you're already on AnyCable, use its built-in presence and delete all of this.

**Code.** The Campfire approach, verified (`app/channels/presence_channel.rb`, `app/models/membership/connectable.rb`, `app/javascript/controllers/presence_controller.js`) — a DB column with a TTL scope, refreshed on a 50s timer against a 60s TTL:

```ruby
# app/models/concerns/membership/connectable.rb
module Membership::Connectable
  extend ActiveSupport::Concern
  CONNECTION_TTL = 60.seconds

  included do
    scope :connected,    -> { where(connected_at: CONNECTION_TTL.ago..) }
    scope :disconnected, -> { where(connected_at: [nil, ...CONNECTION_TTL.ago]) }
  end

  def connected? = connected_at? && connected_at >= CONNECTION_TTL.ago

  # `connections` counts open tabs — a user with three tabs must close all three.
  def present            = self.class.where(id: id).update_all(connections: connected? ? connections + 1 : 1,
                                                               connected_at: Time.current)
  def disconnected       = connected? ? decrement!(:connections, touch: true) : update!(connections: 0)
  def refresh_connection = (increment_connections unless connected?) && touch(:connected_at)
end
```

```ruby
# app/channels/presence_channel.rb
class PresenceChannel < ApplicationCable::Channel
  def subscribed
    @room = current_user.rooms.find(params[:room_id])
    stream_for @room
    membership.present
    broadcast_roster
  rescue ActiveRecord::RecordNotFound
    reject
  end

  def unsubscribed
    return if subscription_rejected?
    membership.disconnected
    broadcast_roster
  end

  def refresh(_data) = membership.refresh_connection   # the heartbeat

  private
    def membership = @room.memberships.find_by(user: current_user)

    def broadcast_roster
      Turbo::StreamsChannel.broadcast_replace_later_to @room, :presence,
        target: "presence_#{@room.id}", partial: "rooms/presence", locals: { room: @room }
    end
end
```

```js
// app/javascript/controllers/presence_controller.js
import { Controller } from "@hotwired/stimulus"
import { cable } from "@hotwired/turbo-rails"

const REFRESH_INTERVAL        = 50 * 1000   // must be < CONNECTION_TTL (60s)
const VISIBILITY_CHANGE_DELAY = 5000        // ignore quick tab-switches

export default class extends Controller {
  static values = { roomId: Number }

  async connect() {
    this.wasVisible = true
    this.channel = await cable.subscribeTo(
      { channel: "PresenceChannel", room_id: this.roomIdValue },
      { connected: this.#start, disconnected: this.#stop }
    )
    document.addEventListener("visibilitychange", this.#visibilityChanged)
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.#visibilityChanged)
    clearInterval(this.timer)
    this.channel?.unsubscribe()
  }

  #start = () => { this.timer ??= setInterval(() => this.channel.send({ action: "refresh" }), REFRESH_INTERVAL) }
  #stop  = () => { clearInterval(this.timer); this.timer = null }

  #visibilityChanged = async () => {
    const visible = document.visibilityState === "visible"
    await new Promise((r) => setTimeout(r, VISIBILITY_CHANGE_DELAY))
    if (visible === this.wasVisible) return
    this.wasVisible = visible
    if (visible) { this.channel.send({ action: "present" }); this.#start() }
    else         { this.#stop(); this.channel.send({ action: "absent" }) }
  }
}
```

The Redis variant, when you don't want presence writes hitting Postgres:

```ruby
class PresenceChannel < ApplicationCable::Channel
  KEY = ->(room) { "presence:room:#{room.id}" }
  TTL = 60

  def subscribed
    @room = current_user.rooms.find(params[:room_id])
    stream_for @room
    touch_presence
    broadcast_roster
  end

  def refresh(_data) = touch_presence
  def unsubscribed   = (Kredis.set(KEY[@room]).remove(current_user.id) if @room) && broadcast_roster

  private
    def touch_presence
      Kredis.configured_for(:shared).multi do |r|   # any raw Redis handle works
        r.zadd(KEY[@room], Time.current.to_i, current_user.id)
        r.zremrangebyscore(KEY[@room], "-inf", TTL.seconds.ago.to_i)   # sweep the dead
        r.expire(KEY[@room], TTL * 2)
      end
    end
end
```

A sorted set scored by timestamp gives you self-healing presence: reading is `ZRANGEBYSCORE key <now-60> +inf`, and anyone who stopped heartbeating simply falls out. No cleanup job.

**Why `unsubscribed` is unreliable, with numbers.** Action Cable pings every **3 seconds** (`ActionCable::Server::Connections::BEAT_INTERVAL = 3`) and the JS client declares the connection stale after **6 seconds** (`ConnectionMonitor.staleThreshold = 6`, i.e. two missed beats). A `SIGKILL`ed browser, a laptop lid, or an LTE handoff means the server keeps believing the client is present for up to those few seconds before `handle_close` runs — and behind some proxies, considerably longer. The Rails guide's "User Appearances" example uses `subscribed`/`unsubscribed` with no caveat at all; the guide never mentions the failure mode. Treat `unsubscribed` as an *optimisation* that makes departures fast, and the TTL as the thing that makes them *correct*.

**AnyCable — the built-in.** Presence is **open source**, not Pro-gated (Pro only adds Redis-backed cluster presence). Server-side default `--presence_ttl` is **15 seconds**:

```ruby
class ChatChannel < ApplicationCable::Channel
  def subscribed
    room = current_user.rooms.find(params[:id])
    stream_for room
    join_presence(broadcasting_for(room), id: current_user.id, info: { name: current_user.name })
  end
end
```
```js
chatChannel.on("presence", ({ type, id, info }) => { /* type: "join" | "leave" */ })
const users = await chatChannel.presence.info()   // { "user-1": { name: "Alice" }, … }
```
([docs.anycable.io/anycable-go/presence](https://docs.anycable.io/anycable-go/presence)). If presence is a core feature of your product, this alone justifies AnyCable.

**Decomposition.** `cable-channel` (NEW) + `interval` (NEW — the heartbeat). Visibility handling is `document.visibilityState`, not a primitive.

**A11y.** The roster is decorative status, not an interruption: `role="status"` on the container at most, and **do not** `aria-live` it — "Alice joined, Bob left, Alice joined" narrated over a conversation is unusable. Avatars need `alt` with the person's name (or `alt=""` plus a visually-hidden name list). Online/offline must not be conveyed by a green dot alone — add a text or `title` affordance (WCAG 1.4.1).

**Native.** Native apps background aggressively; the web view's `visibilitychange` fires but the socket may be torn down by the OS. Presence from a native shell is unreliable by construction — either accept a generous TTL or drive presence from a native lifecycle bridge component.

**Pitfalls.**
- **A user with 3 tabs.** Without a connection *count*, closing one tab marks them offline. Campfire's `connections` integer is exactly this fix.
- **The heartbeat interval must be comfortably under the TTL.** 50s/60s gives one missed beat of slack. 55s/60s does not.
- **Broadcasting the roster on every join/leave is a storm** in a busy room. Debounce it (a `Turbo::ThreadDebouncer`-style guard) or broadcast a `refresh` and let morphing collapse it.
- Writing `connected_at` to a hot table on every heartbeat is a write per user per 50s. Redis or a separate `presences` table.
- `subscription_rejected?` guard in `unsubscribed` — otherwise a rejected subscription runs your departure logic.
- Presence is a privacy feature. "Last seen" and "online now" leak behaviour; make it opt-out.

**Prior art.** [ONCE Campfire](https://github.com/basecamp/once-campfire) `app/channels/presence_channel.rb` + `app/models/concerns/membership/connectable.rb` — the verified reference. [Rails guide — Action Cable, User Appearances](https://guides.rubyonrails.org/action_cable_overview.html) — the toy version; note it has no TTL and is wrong for production. [AnyCable presence](https://docs.anycable.io/anycable-go/presence) — the real built-in. [Kredis](https://github.com/rails/kredis) for the Redis sorted-set variant. No Rails presence gem worth naming exists.

---

### Collaborative editing

**Hotwire answer.** Split the problem. **Record-level conflict detection is a solved Hotwire pattern**: `ActiveRecord::Locking::Optimistic` (a `lock_version` column), rescue `ActiveRecord::StaleObjectError`, and stream a conflict banner. Do that. **Character-level concurrent editing (OT/CRDT) is not a Hotwire thing at all** — Turbo plays no part. You bolt Yjs onto Rails, and there is a real, maintained ActionCable provider for it.

**Code — the achievable half.**

```ruby
# db/migrate/…_add_lock_version_to_documents.rb
add_column :documents, :lock_version, :integer, null: false, default: 0
```

```erb
<%# app/views/documents/_form.html.erb %>
<%= form_with model: @document, id: dom_id(@document, :form) do |f| %>
  <%= f.hidden_field :lock_version %>            <%# the whole mechanism %>
  <%= f.text_area :body, data: { controller: "dirty-form" } %>
  <%= f.submit "Save" %>
<% end %>
```

```ruby
class DocumentsController < ApplicationController
  def update
    @document = Current.account.documents.find(params[:id])
    @document.update!(document_params)           # raises if lock_version is stale
    redirect_to @document, notice: "Saved."
  rescue ActiveRecord::StaleObjectError
    @fresh = Current.account.documents.find(params[:id])
    render turbo_stream: turbo_stream.replace(dom_id(@document, :form),
             partial: "documents/conflict",
             locals: { mine: @document, theirs: @fresh }),
           status: :conflict                     # 409
  end

  private
    def document_params = params.require(:document).permit(:body, :lock_version)
end
```

```erb
<%# app/views/documents/_conflict.html.erb %>
<div id="<%= dom_id(mine, :form) %>" class="conflict" role="alert">
  <h2>Someone else edited this while you were writing</h2>
  <p>Last saved by <%= theirs.updated_by.name %>, <%= time_ago_in_words theirs.updated_at %> ago.</p>

  <div class="conflict__panes">
    <section>
      <h3>Your version</h3>
      <pre class="conflict__pane"><%= mine.body %></pre>
    </section>
    <section>
      <h3>Their version (current)</h3>
      <pre class="conflict__pane"><%= theirs.body %></pre>
    </section>
  </div>

  <%= form_with model: theirs, id: "#{dom_id(mine, :form)}_resolve" do |f| %>
    <%= f.hidden_field :lock_version, value: theirs.lock_version %>
    <%= f.hidden_field :body, value: mine.body %>
    <%= f.submit "Keep mine (overwrite theirs)", class: "btn--danger" %>
  <% end %>
  <%= link_to "Discard mine and reload theirs", document_path(theirs), class: "btn" %>
</div>
```

Add **field-level locking** — a soft lease so two people rarely collide in the first place — with the presence machinery above: broadcast "Alice is editing the Summary field", render other users' fields `readonly` with an owner badge, expire the lease on a TTL. It's presence with a field id in the key. This is achievable and worth doing; it is *not* concurrency control (leases race), it's collision avoidance.

Note that `422` is now **Unprocessable Content**; for a lock conflict use `:conflict` (409) — semantically correct and it keeps Turbo from treating it as a validation re-render.

**Code — the CRDT half, honestly.** Turbo is not involved. You run Yjs in the browser bound to a rich-text editor, and you need a transport. On Rails the concrete option is [`y-crdt/yrb-actioncable`](https://github.com/y-crdt/yrb-actioncable) (68★, last push 2025-11) — an ActionCable companion for Y.js clients, backed by [`y-crdt/yrb`](https://github.com/y-crdt/yrb) (96★, active), the Ruby bindings to `yrs`:

```ruby
# app/channels/sync_channel.rb
class SyncChannel < ApplicationCable::Channel
  include Y::Actioncable::Sync

  def subscribed
    sync_for(session)                 # initial sync + subscribe to updates, optional persistence
  end

  def receive(message)
    sync_to(session, message)         # fan out to all clients across all servers
  end
end
```

```js
import * as Y from "yjs"
import { WebsocketProvider } from "@y-rb/actioncable"
import consumer from "channels/consumer"

const doc = new Y.Doc()
new WebsocketProvider(doc, consumer, "SyncChannel", { id: documentId })
// then bind doc.getXmlFragment("default") to Tiptap / ProseMirror / Monaco
```

The alternatives are [`yjs/y-websocket`](https://github.com/yjs/y-websocket) (712★) as a separate Node process, or a hosted service (Liveblocks, Tiptap Cloud, PartyKit). AnyCable is a live path here too — AnyCable + Yjs has been presented as a production pattern (SF Ruby 2025, JP Camara / Wealthbox).

**Decomposition.** Conflict path: `dirty-form` (know there are unsaved changes) + `confirm` (before overwriting someone). CRDT path: none — a `<div>` handed to a JS editor, plus `data-turbo-permanent` so Turbo never touches it.

**A11y.** The conflict banner is `role="alert"` — a lost edit is exactly the interrupt case. Move focus to the banner heading. Both versions must be readable, not just diffed with colour (WCAG 1.4.1). For live collaboration, remote cursors need names in text, not only colour, and remote edits landing in a textarea are hostile to screen-reader users — provide a "pause live updates" control.

**Native.** A CRDT editor is a native screen. Don't try.

**Pitfalls.**
- **Optimistic locking silently does nothing if you forget the hidden field.** No `lock_version` in params = no check. Test it.
- `update_columns`, `update_all`, and `touch` **bypass** optimistic locking entirely.
- `StaleObjectError` is raised on `save`/`update`, so it escapes your `rescue` if you save in a callback or a nested transaction. Rescue at the controller boundary.
- Field-level leases are advisory. Two users can acquire the same lease under a partition. They reduce collisions; they don't prevent lost updates. Keep `lock_version` underneath.
- **A CRDT editor and Turbo morphing are mortal enemies.** Morphing walks the editor's DOM and destroys its internal state. `data-turbo-permanent` on the editor container is mandatory. See `02-turbo-deep-dive.md` §5.8.
- Yjs documents are binary blobs. Your `documents.body` column is no longer the source of truth; you now have two persistence stories to reconcile (Y.Doc state vector + a rendered snapshot for search/SEO).

**Verdict: partial, with a hard boundary.** Optimistic locking + a conflict banner + field leases is a genuinely good Hotwire pattern, ships in a day, and covers the 95% case (two people editing different parts of a form). **Google-Docs-style character-level co-editing has no Hotwire answer and never will** — it needs a CRDT and a persistent bidirectional binary transport, which is a different architecture that merely happens to share your ActionCable connection. `yrb-actioncable` is the honest Rails path and it is a small, lightly-maintained project; budget accordingly. If character-level collaboration is a core product requirement, that is a legitimate reason to put a JS framework on that one screen.

**Prior art.** [ActiveRecord::Locking::Optimistic](https://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html) (built in). [y-crdt/yrb-actioncable](https://github.com/y-crdt/yrb-actioncable) + [y-crdt/yrb](https://github.com/y-crdt/yrb). [yjs/y-websocket](https://github.com/yjs/y-websocket). [paper_trail](https://github.com/paper-trail-gem/paper_trail) if you want to offer "restore their version" after an overwrite. No dedicated conflict-UI gem exists.

---

### Live dashboards

**Hotwire answer.** One **throttled `refresh` broadcast + morphing** for the whole dashboard, not one broadcast per widget. The N-users × M-widgets broadcast storm is the defining failure of this pattern, and Turbo 8 solved it: a `refresh` broadcast is a ~100-byte message that costs the server nothing until a client acts on it, and the client-side 150ms debounce plus the server-side 0.5s `ThreadDebouncer` collapse bursts automatically.

**Code.**

```erb
<%# app/views/dashboards/show.html.erb %>
<% turbo_refreshes_with method: :morph, scroll: :preserve %>
<%= turbo_stream_from Current.account, :dashboard %>

<div class="dashboard">
  <%= render "dashboards/revenue",   account: Current.account %>
  <%= render "dashboards/signups",   account: Current.account %>
  <%= render "dashboards/queue",     account: Current.account %>
</div>
```

```ruby
# app/models/concerns/dashboard_broadcastable.rb
module DashboardBroadcastable
  extend ActiveSupport::Concern
  included do
    after_commit -> { DashboardRefreshJob.perform_later(account) }, on: %i[create update destroy]
  end
end

# app/jobs/dashboard_refresh_job.rb — coalesce at the app level too
class DashboardRefreshJob < ApplicationJob
  THROTTLE = 5.seconds

  def perform(account)
    key = "dashboard_refresh:#{account.id}"
    return unless Rails.cache.write(key, true, expires_in: THROTTLE, unless_exist: true)
    Turbo::StreamsChannel.broadcast_refresh_to account, :dashboard
  end
end
```

Three layers of throttling, and you want all of them: the `unless_exist` cache lock (5s, app-wide across processes), `Turbo::ThreadDebouncer` (0.5s, per-request), and `Session#pageRefreshDebouncePeriod` (150ms, client). Without the first, 200 orders in a minute is 200 broadcasts.

The alternative, when a full dashboard render is genuinely expensive — targeted, and only for the widgets that actually change:

```ruby
Turbo::StreamsChannel.broadcast_replace_later_to Current.account, :dashboard,
  target: "dashboard_queue", partial: "dashboards/queue", locals: { account: account }
```

Or, when there's no cable backend at all, per-widget polling frames (see the next pattern) — which has the nice property that widgets refresh independently and a slow one doesn't block the others.

**The storm arithmetic.** 200 concurrent viewers, 6 widgets, an event every 2 seconds:
- naive per-widget targeted broadcasts: 6 renders × 1 broadcast, fanned to 200 sockets = 1,200 messages carrying rendered HTML every 2s.
- one throttled `refresh`: 1 tiny message × 200 sockets every 5s, then 200 page GETs — which hit your HTTP cache, your fragment caches, and your CDN, and which you can already reason about. Renders move from the job queue (unbounded, uncached) to the request path (cached, observable, rate-limitable).

That second property is the underrated one: **`refresh` broadcasts turn a push problem into a pull problem**, and Rails is much better at pull.

**Decomposition.** `chart` (see below) + `relative-time` + `countdown` (for "next update in…"). `interval` (NEW) for the polling variant.

**A11y.** A dashboard that mutates under the reader is hostile. Do **not** `aria-live` the whole thing. Give each stat a stable `<dfn>`/label so the number is never announced alone, and provide a "Pause live updates" toggle that unsubscribes — WCAG 2.2 SC 2.2.2 (Pause, Stop, Hide) applies to auto-updating content. A single `role="status"` node saying "Updated 12:04" is the right amount of announcement.

**Native.** Dashboards are a good native-screen candidate; a `refresh` broadcast causing a full web-view reload on a native screen is jarring. Gate with `turbo-native` and prefer targeted replaces there.

**Pitfalls.**
- **Charts are destroyed by morphing.** Chart.js/ApexCharts write to a `<canvas>` and keep state outside the DOM; idiomorph replaces attributes and the chart goes blank or leaks the old instance. `data-turbo-permanent` on the chart container plus a Stimulus `disconnect()` that calls `chart.destroy()`. **The Data-display section owns this problem in full — defer to it.**
- Without the app-level throttle, a bulk import fires one refresh per record. The 0.5s `ThreadDebouncer` is per-thread-per-request and won't save you across jobs.
- `broadcast_refresh_to` (sync) from inside a job is right; `broadcast_refresh_later_to` from a job enqueues another job.
- Every refreshing client re-runs your dashboard queries. Fragment-cache the widgets or you've moved the load, not removed it.
- Solid Cable's 100ms floor is irrelevant here — dashboards are the ideal Solid Cable workload.
- Morphing preserves scroll only with `<meta name="turbo-refresh-scroll" content="preserve">`; without it, a refreshing dashboard scrolls to top under the user.

**Prior art.** [Chartkick](https://chartkick.com/) + [Groupdate](https://github.com/ankane/groupdate) for the charts. [turbo_power](https://github.com/marcoroth/turbo_power) `set_property` / `set_text_content` to update a number without re-rendering a partial. [37signals on morphing](https://dev.37signals.com/a-happier-happy-path-in-turbo-with-morphing/). Cross-ref the Data-display section for chart lifecycle.

---

### Polling as the boring alternative

**Hotwire answer.** A `<turbo-frame>` that reloads itself on an interval. **No WebSocket, no Redis, no ActionCable, no Solid Cable table, no cable.yml.** Roughly ten lines of Stimulus and one controller action. For low-frequency updates with modest concurrency this is not a compromise — it is the correct engineering choice, and it is what you should reach for first.

**Code.**

```erb
<%= turbo_frame_tag "build_status", src: build_status_path(@build),
      data: { controller: "interval",
              interval_ms_value: 5000,
              action: "interval:tick->interval#reloadFrame" } do %>
  <span class="skeleton skeleton--line" aria-hidden="true" style="display:block"></span>
<% end %>
```

```js
// app/javascript/controllers/interval_controller.js — the whole thing
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { ms: { type: Number, default: 5000 }, stopped: Boolean }

  connect() {
    this.#start()
    document.addEventListener("visibilitychange", this.#visibility)
  }

  disconnect() {
    clearInterval(this.timer)
    document.removeEventListener("visibilitychange", this.#visibility)
  }

  reloadFrame() {
    const frame = this.element.closest("turbo-frame") ?? this.element
    if (frame.hasAttribute("busy")) return       // don't stack requests
    frame.reload()
  }

  #start = () => { this.timer ??= setInterval(() => this.dispatch("tick"), this.msValue) }
  #stop  = () => { clearInterval(this.timer); this.timer = null }
  // Never poll a background tab. This is most of the cost saving.
  #visibility = () => (document.visibilityState === "visible" ? this.#start() : this.#stop())
}
```

```ruby
class BuildStatusesController < ApplicationController
  def show
    @build = Current.account.builds.find(params[:build_id])
    fresh_when @build                     # 304s cost you almost nothing
  end
end
```

```erb
<%# app/views/build_statuses/show.html.erb %>
<%= turbo_frame_tag "build_status" do %>
  <p role="status"><%= @build.status.humanize %> — <%= @build.percent %>%</p>
  <% if @build.finished? %>
    <%# stop polling by rendering the frame WITHOUT the interval controller %>
  <% end %>
<% end %>
```

Self-terminating polling: the response controls whether the next frame carries the controller. When the build finishes, render a frame with no `data-controller` and the polling simply stops. No JS state machine.

**When polling beats WebSockets:**
- Update frequency ≥ 3s and staleness of a few seconds is acceptable (build status, job progress, "N people are viewing", queue depth, exchange rates).
- Few concurrent viewers of the same resource — a handful of admins, not 5,000 users.
- You don't already run Redis and don't want to (Solid Cable is free but it's still a polling loop plus a table plus a trim job — you've just moved the polling to the server).
- Your PaaS bills per connection, caps concurrent connections, or terminates idle sockets (many serverless/edge platforms, some load balancers with short idle timeouts).
- The data is already HTTP-cacheable. `fresh_when` + `Cache-Control` turns 90% of polls into 304s that never touch your DB. A WebSocket broadcast cannot use your HTTP cache at all.
- You need it working *today* with zero operational surface.

**When it doesn't:** anything a human perceives as instant (chat, typing, cursors), fan-out to many viewers of one resource, or update rates under ~2s.

**Decomposition.** `interval` (NEW) — that's it. `intersection` if you want to poll only while the frame is on screen (a strict improvement over `visibilitychange` for long pages).

**A11y.** Wrap the changing value in `role="status"` so updates are announced politely, and only if the change matters. WCAG 2.2 SC 2.2.2 (Pause, Stop, Hide) — offer a pause control if the region updates more than once per 5s. Never `aria-live` a whole polled frame.

**Native.** Polling in a backgrounded web view is wasteful on mobile battery and data; the `visibilitychange` guard above is doing real work there. Hotwire Native pauses timers when the screen is off-stack, but not always promptly.

**Pitfalls.**
- **Always guard against stacking requests.** If the response takes longer than the interval, `frame.reload()` fires again and you queue up. The `[busy]` check above is the fix.
- **Always stop polling in hidden tabs.** A user with 30 tabs open is otherwise 30 requests every 5s, forever.
- `frame.reload()` re-fetches the frame's `src`; if the frame has no `src` (it was populated by a stream) `reload()` is a no-op. Give polled frames an explicit `src`.
- A polled frame that reloads while the user has focus inside it steals focus on render. Morph the frame instead: `<turbo-frame refresh="morph">`.
- Every poll is a full Rails request — auth, session, middleware. `fresh_when` and a lightweight controller matter more than the interval.
- Don't poll and also broadcast to the same frame. Pick one.

**Prior art.** [stimulus-components `auto-reload`](https://www.stimulus-components.com/) covers a similar shape but the ten lines above are clearer. [Boring Rails — polling with Turbo Frames](https://boringrails.com/) argues this case well. [pagy](https://ddnexus.github.io/pagy/) for the paginated variant. **Superseded:** `<meta http-equiv="refresh">` and jQuery `setInterval($.get)`.

---



## Navigation, layout & miscellany

### Scroll-position restoration

**Hotwire answer.** Turbo Drive already does the right thing for ordinary navigation — **no JS needed**. The only knob you need is the pair of refresh meta tags, and the one thing you must get right is making your filter/search form a *page refresh* (`data-turbo-action="replace"`) rather than an advance visit, because scroll preservation is gated on that.

**What Turbo does by default** (verified against `hotwired/turbo` 8.0.23 source, `src/core/drive/visit.js#performScroll`):

```js
performScroll() {
  if (!this.scrolled && !this.view.forceReloaded && !this.view.shouldPreserveScrollPosition(this)) {
    if (this.action == "restore") {
      this.scrollToRestoredPosition() || this.scrollToAnchor() || this.view.scrollToTop()
    } else {
      this.scrollToAnchor() || this.view.scrollToTop()
    }
    this.scrolled = true
  }
}
```

- **restore** visits (Back/Forward) → restore the saved `{x, y}` from `History#restorationData`, else the `#anchor`, else top.
- **advance / replace** visits → the `#anchor` if the URL has one, else **top**.
- Turbo sets `history.scrollRestoration = "manual"` once the document is `complete` and hands it back to the browser on `pagehide`, so the browser's own restoration never fights Turbo's. See [02-turbo-deep-dive §2.5](#).

**The escape hatch, and its exact gate.** `src/core/drive/page_view.js`:

```js
isPageRefresh(visit) {
  return !visit || (this.lastRenderedLocation.pathname === visit.location.pathname && visit.action === "replace")
}

shouldPreserveScrollPosition(visit) {
  return this.isPageRefresh(visit) && (visit?.refresh?.scroll || this.snapshot.refreshScroll) === "preserve"
}
```

Read that twice. Scroll preservation applies **only** when (a) the destination **pathname** is identical to the current one (query string is *not* compared) and (b) the visit action is **`replace`**. The same `isPageRefresh` gate also decides whether you get morphing at all (`renderPage` picks `MorphingPageRenderer` on exactly the same condition). One gate, two behaviours.

**The exact meta tag names** (verified against `PageSnapshot#refreshMethod` / `#refreshScroll`, which read via `getSetting("refresh-method")` / `getSetting("refresh-scroll")` → `<meta name="turbo-refresh-*">`):

```html
<meta name="turbo-refresh-method" content="morph">   <!-- replace | morph -->
<meta name="turbo-refresh-scroll" content="preserve"> <!-- reset | preserve -->
```

Rails helper (`Turbo::DriveHelper`, validates and raises `ArgumentError` on bad values):

```erb
<% turbo_refreshes_with method: :morph, scroll: :preserve %>
<%# individual tags: turbo_refresh_method_tag(:morph), turbo_refresh_scroll_tag(:preserve) %>
```

Per-stream override: `<turbo-stream action="refresh" method="morph" scroll="preserve"></turbo-stream>`.

**Recipe: keep scroll position on a filter form submit.**

```erb
<%# app/views/layouts/application.html.erb — in <head> %>
<% turbo_refreshes_with method: :morph, scroll: :preserve %>
```

```erb
<%# app/views/tickets/index.html.erb %>
<%= form_with url: tickets_path, method: :get,
              data: {
                turbo_action: "replace",          # <- THE load-bearing attribute
                controller: "autosubmit",
                autosubmit_delay_value: 300
              } do |f| %>
  <%= f.search_field :q, value: params[:q],
        data: { action: "input->autosubmit#submit" } %>
  <%= f.select :status, Ticket.statuses.keys, { include_blank: "Any" },
        data: { action: "change->autosubmit#submit" } %>
<% end %>

<div id="results">
  <%= render @tickets %>
</div>
```

Why this works and the obvious alternatives don't:

- `data-turbo-action="replace"` makes the visit action `replace` (`Navigator#getActionForFormSubmission` → `getVisitAction(submitter, formElement)`), so `isPageRefresh` is true, so you get **morph + scroll preserve**.
- `data-turbo-action="advance"` on the same form gives you a history entry per keystroke *and* scroll-to-top, because `isPageRefresh` fails. This is the trade-off and there is no way around it: **preserved scroll and per-filter history entries are mutually exclusive in Turbo 8.** For a live filter, `replace` is correct anyway — you do not want 40 history entries from typing "authentication".
- Wrapping the results in a `<turbo-frame>` instead also preserves scroll (frames never scroll the document), but then the URL only updates if you add `data-turbo-action` to the frame — which puts you right back in the same trade-off, plus a frame-shaped controller. Prefer the morph refresh.

**Where it breaks.**

- **Turbo Streams don't scroll at all.** A stream render is not a Visit; `performScroll` never runs. If you *want* a scroll after a stream, use `turbo_stream.scroll_to` from [turbo_power](https://github.com/marcoroth/turbo_power) or a custom `Turbo.StreamActions`.
- **Frames.** A frame render calls `FrameRenderer#scrollFrameIntoView`, which does nothing unless the frame has the `autoscroll` attribute:

  ```erb
  <%= turbo_frame_tag "chat", src: chat_path, autoscroll: true,
        data: { autoscroll_block: "end", autoscroll_behavior: "smooth" } %>
  ```

  Defaults are `block: "end"`, `behavior: "auto"`, and it scrolls `frame.firstElementChild` — so an empty frame scrolls nothing.
- **Infinite scroll.** Appending to a list below the fold is fine; the problem is *Back*. If the user scrolls through 5 lazily-loaded pages, navigates into a record and comes back, the restore visit renders the cached snapshot — which *does* contain all 5 pages, because the snapshot was taken at `turbo:before-cache` — and restores the scroll position. This works. It stops working the moment you `Turbo.cache.clear()` or submit a non-idempotent form (which clears the whole snapshot cache). The honest fix is to put the page cursor in the URL (`?page=5`) with `data-turbo-action="advance"` on the pagination frame, so Back replays a real URL rather than depending on a cache.
- **`turbo:load` / `turbo:render` timing.** `performScroll()` runs inside the same `requestAnimationFrame` callback as the render, *before* `turbo:load`. So a `turbo:load` listener that scrolls will win, and a `turbo:load` listener that reads `window.scrollY` sees the post-restore value. Never scroll from `turbo:render` — the body may still be mid-swap.

**Decomposition.** None — this is Turbo Drive configuration. The filter form uses `autosubmit` (debounced via stimulus-use).

**A11y.** Scroll restoration is an a11y feature: skipping it strands screen-reader and magnifier users. Do not disable it globally. If you scroll programmatically, respect `prefers-reduced-motion` before passing `behavior: "smooth"`.

**Native.** Hotwire Native maintains its own scroll state per screen in the native navigation stack — each visit is a fresh web view or a fresh snapshot, and the native back gesture restores the native screen, not Turbo's restoration data. Don't rely on `turbo-refresh-scroll` to fix a native back-navigation problem; see [04-hotwire-native §6.1–6.2](#).

**Pitfalls.**
- Scroll preserve is **not** global — it only fires for same-pathname `replace` visits. Adding the meta tag and expecting it to preserve scroll across an ordinary link click is the #1 misunderstanding.
- The pathname comparison ignores the query string, which is what makes filter forms work — but it also means a `replace` visit from `/tickets/5` to `/tickets` will *not* count as a refresh.
- `visit.scrolled` is set once. If you call `Turbo.visit()` again mid-visit you can end up with no scroll at all.
- **`data-turbo-cache="false"` on an element is gone.** It was deprecated in Turbo 7.3.0 ([#871](https://github.com/hotwired/turbo/pull/871), Feb 2023) and **removed in Turbo 8.0.21** ([#1470](https://github.com/hotwired/turbo/pull/1470), Nov 2025). `CacheObserver` in 8.0.23 only knows `[data-turbo-temporary]`. Any tutorial still telling you to write `data-turbo-cache="false"` is stale and the attribute is now silently inert.
- The pre-Turbo-8 community shims — hand-rolled `data-turbo-preserve-scroll` controllers that stash `window.scrollY` on `turbo:before-render` and reapply on `turbo:render` — are **obsoleted by the refresh meta tags**. They also fight Turbo's own `performScroll` and produce a visible double-jump. Delete them.

**Prior art.**
- [Turbo Handbook — Page Refreshes](https://turbo.hotwired.dev/handbook/page_refreshes)
- [hotwired/turbo issue #37 — "Preserve scroll position"](https://github.com/hotwired/turbo/issues/37), the long-running thread that led to the 8.0 meta tags
- [turbo_power](https://github.com/marcoroth/turbo_power) — `scroll_into_view`, `reload`, `set_focus` stream actions

---

### Back-button correctness

**Hotwire answer.** There is no controller for this. Back-button correctness is a **design rule**: every UI state a user can reach must be a URL, and every navigation that changes what the user sees must push history. In Turbo that reduces to two attributes (`data-turbo-action`) and one hygiene practice (clean up transient DOM before it gets cached). **No JS needed.**

**The three visit actions** ([02-turbo-deep-dive §2.5](#)):

| Action | History | Issues a request? | Set by |
|---|---|---|---|
| `advance` | `pushState` | yes | default for link clicks and successful form redirects |
| `replace` | `replaceState` | yes | `data-turbo-action="replace"`, or a redirect back to the same URL |
| `restore` | none (browser already moved) | **only if there's no cached snapshot** | `popstate` (Back/Forward) |

Turbo also stamps `<html data-turbo-visit-direction="forward|back|none">` for the duration of the visit — use it for directional CSS.

**Promoting a frame navigation to a history entry.** By default a frame navigation touches neither URL nor history: click "page 2" inside a frame, hit Back, and you leave the page entirely. Fix it at the frame, not the link:

```erb
<%# every navigation inside this frame also pushes a history entry %>
<%= turbo_frame_tag "results", data: { turbo_action: "advance" } do %>
  <%= render @results %>
  <%= render "pagination", pagy: @pagy %>
<% end %>
```

**Hard requirement:** the frame's `src` must be a real, standalone page URL that renders the same frame on a cold full-page load. `FrameController#proposeVisitIfNavigatedWithAction` proposes a Visit with `willRender: false` and stitches the new frame contents into the cached snapshot — so Back works — but a *refresh* or a shared link goes through the server, and if `/posts?page=2` renders nothing sensible standalone you have shipped a broken URL. See [02-turbo-deep-dive §3.4](#).

**When a GET form should be `advance`.** Rule: **`advance` if the result is a destination, `replace` if it is a refinement.**

```erb
<%# Search page: the query IS the destination. Back should undo the search. %>
<%= form_with url: search_path, method: :get, data: { turbo_action: "advance" } do |f| %>
  <%= f.search_field :q %>
  <%= f.submit "Search" %>
<% end %>

<%# Live filter on an index: every keystroke would be a history entry. Refinement → replace. %>
<%= form_with url: tickets_path, method: :get,
      data: { turbo_action: "replace", controller: "autosubmit" } do |f| %>
```

Both write the params into the URL, which is the point. A discrete "Apply filters" button-press is a destination (`advance`); an auto-submitting input is a refinement (`replace`).

**The restoration cache and the flash of stale content.** Turbo keeps an LRU of **10 page snapshots** keyed by URL with the fragment stripped. On a visit it caches the page you are leaving (after dispatching `turbo:before-cache`), and if the *destination* is cached it renders that stale snapshot immediately as a **preview** while the request is in flight. During the preview `<html>` carries `data-turbo-preview`. The preview is a real render — `turbo:before-render`, `turbo:render`, script execution, Stimulus `connect()`. Snapshot cloning deliberately clears `input[type=password]` values and copies `<select>` selections, and preserves everything else as-is. That "everything else" is your flash of stale content: an open modal, a spinner stuck at 40%, a "Saving…" button. See [02-turbo-deep-dive §2.6](#).

Fixes in order of preference:

```erb
<%# 1. Mark transient nodes. CacheObserver removes [data-turbo-temporary] on turbo:before-cache. %>
<% flash.each do |type, message| %>
  <div class="flash flash--<%= type %>" data-turbo-temporary><%= message %></div>
<% end %>
```

```js
// 2. Idempotent teardown in turbo:before-cache (or, better, in a Stimulus disconnect()).
document.addEventListener("turbo:before-cache", () => {
  document.querySelectorAll("dialog[open]").forEach((d) => d.close())
  document.querySelectorAll("details[open]").forEach((d) => d.removeAttribute("open"))
  document.querySelectorAll("[aria-busy=true]").forEach((el) => el.removeAttribute("aria-busy"))
})
```

```erb
<%# 3. Cache the page but never show it stale (Back is still instant). %>
<% turbo_exempts_page_from_preview %>   <%# <meta name="turbo-cache-control" content="no-preview"> %>

<%# 4. Last resort: don't cache at all (Back re-fetches). %>
<% turbo_exempts_page_from_cache %>     <%# <meta name="turbo-cache-control" content="no-cache"> %>
```

Both helpers use `provide :head`, so your layout needs `<%= yield :head %>` inside `<head>`, and they are **mutually exclusive** — the underlying meta holds one value.

> **Correction to a widely-repeated instruction.** `data-turbo-cache="false"` **on an element** is removed as of Turbo 8.0.21 ([#1470](https://github.com/hotwired/turbo/pull/1470)). Use `data-turbo-temporary`. `<meta name="turbo-cache-control" content="no-cache">` (page level) is unaffected and still correct.

**Checklist — run through this before shipping any interactive screen.**

1. Can I reload the page right now and see the same thing? If not, the state isn't in the URL. Fix that first.
2. Can I copy the URL, paste it in a new tab, and get the same screen? (Catches frame `src` URLs that don't render standalone.)
3. Does every `<turbo-frame>` whose content the user perceives as "a page" carry `data-turbo-action="advance"`?
4. Does every GET form put its params in the URL, with `advance` for destinations and `replace` for refinements?
5. Hit Back from the deepest state. Does it undo exactly one perceptible step — not zero, not the whole flow?
6. Hit Back and watch for a flash: modal reopening, spinner, stale flash message, "Saving…" button. Everything that flashes needs `data-turbo-temporary` or a `turbo:before-cache` teardown.
7. Hit Forward. Same checks.
8. Is any sort/filter/tab/accordion state held only in JS or `localStorage`? Move it to the URL (or accept that Back won't restore it and say so out loud).
9. Does a POST → 303 redirect land on a URL you'd be happy to have in history? (Turbo downgrades a redirect-to-the-same-URL to `replace` automatically, so a failed-then-retried form doesn't stack entries.)
10. Sign-in / error pages: `<% turbo_page_requires_reload %>` so a frame that redirects there escalates to a full visit instead of "Content missing".

**Decomposition.** None. This is Turbo Drive configuration plus URL design. Related primitives: `tabs` (with URL sync), `dialog` (a modal reached by URL is a frame + a `dialog`).

**A11y.** Back-button correctness *is* an accessibility requirement — WCAG 3.2.3 (Consistent Navigation) and the general expectation that browser chrome works. When a frame navigation changes the main content without a page load, announce it: put `aria-live="polite"` on a small status region, or move focus to the frame's heading after `turbo:frame-load`. See [APG landmark guidance](https://www.w3.org/WAI/ARIA/apg/practices/landmark-regions/).

**Native.** In Hotwire Native, `data-turbo-action="advance"` on a frame does **not** push a native screen — the native stack is driven by full visits and path configuration, not frame promotions. `data-turbo-action="replace"` on a link maps to replacing the top of the native stack. See [04-hotwire-native §6.3 "`data-turbo-action` vs path configuration"](#) and §4.4.

**Pitfalls.**
- A frame with `data-turbo-action="advance"` whose `src` 404s or renders a different layout standalone: Back appears to work (it's stitching a cached snapshot) but refresh is broken. Always cold-load the frame URL yourself.
- `restore` visits do **not** issue a request when a snapshot exists. If your page has server-side state that changed, Back shows stale data. That is correct Turbo behaviour and the fix is `turbo_exempts_page_from_cache`, not a JS hack.
- Anything you stash in `sessionStorage` to "remember scroll/tab state" is invisible to Back/Forward. URLs or nothing.
- `Turbo.visit(url, { action: "replace" })` from a Stimulus controller is a legitimate tool, but it is a code smell if you're using it to sync URL state that a plain link could express.

**Prior art.**
- [Turbo Handbook — Drive](https://turbo.hotwired.dev/handbook/drive), [Reference — Attributes](https://turbo.hotwired.dev/reference/attributes)
- [02-turbo-deep-dive §2.5, §2.6, §3.4](#)

---

### View Transitions API + Turbo

**Hotwire answer.** One meta tag in your layout, then pure CSS. **No JS needed.** Turbo 8 wires `document.startViewTransition()` around every render itself (`src/core/drive/view_transitioner.js`); you never call the API.

**Turn it on.** `PageSnapshot#prefersViewTransitions` accepts either form:

```html
<meta name="view-transition" content="same-origin">
<!-- equivalent -->
<meta name="turbo-view-transition" content="true">
```

Verified source:

```js
get prefersViewTransitions() {
  const viewTransitionEnabled =
    this.getSetting("view-transition") === "true" ||
    this.headSnapshot.getMetaValue("view-transition") === "same-origin"
  return viewTransitionEnabled && !window.matchMedia("(prefers-reduced-motion: reduce)").matches
}
```

Three consequences worth internalising:

1. **Both snapshots must opt in** (`PageView#shouldTransitionTo` ANDs the outgoing and incoming pages). So it goes in the layout, not on one page. It also means you can *disable* transitions for one route by omitting the tag there.
2. **`prefers-reduced-motion: reduce` is honoured for free.** You do not need a media query guard for the transition itself.
3. Transitions are serialized through a promise chain and only one can be in flight, so rapid clicking degrades to plain renders rather than stacking.

**What Turbo does automatically in 8.x.** `Visit#render` wraps the render in `viewTransitioner.renderChange(view.shouldTransitionTo(snapshot), render)`, which is:

```js
if (useViewTransition && document.startViewTransition && !this.#viewTransitionStarted) {
  this.#lastOperation = this.#lastOperation.then(async () => {
    await document.startViewTransition(render).finished
  })
}
```

That's the whole integration. It applies to **all** page renders — replace *and* morph — because `renderPageSnapshot` calls it regardless of renderer.

> **`@view-transition { navigation: auto; }` does nothing for Turbo.** That at-rule opts a document into **cross-document** (MPA) view transitions, i.e. real browser navigations. Turbo Drive intercepts those navigations and does a **same-document** swap, so the at-rule is never consulted. It is harmless but inert, and it appears in a lot of blog posts (and in [02-turbo-deep-dive §6](#)'s CSS example) where it misleads. The meta tag is the only opt-in that matters. Keep the at-rule only if you also want transitions on the non-Turbo navigations in your app (`data-turbo="false"` links, cross-origin, full reloads) — and note browser support for cross-document is much narrower.

**Browser support, verified 2026-08-15** ([webstatus.dev](https://webstatus.dev/)):

| Feature | Baseline | Chrome | Safari | Firefox |
|---|---|---|---|---|
| Same-document (`document.startViewTransition`) — **what Turbo uses** | **Newly available**, 2025-10-14 | 111 | 18 | **144** |
| Cross-document (`@view-transition`) | **Limited** | 126 | 18.2 | *not shipped* |

So as of mid-2026 Turbo's view transitions work in **all three engines**. Firefox 144 (Oct 2025) was the last holdout. Safari has had it since 18 (Sept 2024). This is the first year it's reasonable to ship view transitions without a fallback story — and there's nothing to fall back to anyway, since `ViewTransitioner` silently degrades to a plain render.

**Baseline CSS.**

```css
/* Duration + easing for the default root cross-fade */
::view-transition-old(root),
::view-transition-new(root) {
  animation-duration: 200ms;
  animation-timing-function: cubic-bezier(0.2, 0, 0, 1);
}

/* Directional: Turbo stamps <html data-turbo-visit-direction="forward|back|none"> */
html[data-turbo-visit-direction="back"] ::view-transition-old(root) {
  animation-name: slide-out-right;
}
html[data-turbo-visit-direction="back"] ::view-transition-new(root) {
  animation-name: slide-in-left;
}

@keyframes slide-out-right { to { transform: translateX(30%); opacity: 0 } }
@keyframes slide-in-left  { from { transform: translateX(-30%); opacity: 0 } }
```

**Shared-element transition, list → detail.** The contract: the *same* `view-transition-name` must exist on exactly one element in the outgoing page and one in the incoming page. Duplicate names on one page abort the transition entirely.

```erb
<%# app/views/posts/_post.html.erb — the list item %>
<article class="post-card">
  <%= link_to post_path(post) do %>
    <%= image_tag post.cover.variant(:card),
          class: "post-card__cover",
          style: "view-transition-name: cover-#{post.id}",
          loading: "lazy", decoding: "async" %>
    <h2 style="view-transition-name: title-<%= post.id %>"><%= post.title %></h2>
  <% end %>
</article>
```

```erb
<%# app/views/posts/show.html.erb — the detail page %>
<article class="post">
  <%= image_tag @post.cover.variant(:hero),
        class: "post__cover",
        style: "view-transition-name: cover-#{@post.id}",
        fetchpriority: "high", decoding: "async" %>
  <h1 style="view-transition-name: title-<%= @post.id %>"><%= @post.title %></h1>
  <%= @post.body %>
</article>
```

```css
/* Tune the shared-element morph; the * selector catches every dynamically-named pair */
::view-transition-group(*) {
  animation-duration: 260ms;
  animation-timing-function: cubic-bezier(0.2, 0, 0, 1);
}
/* Cover images change aspect ratio between card and hero — cross-fade the frames
   rather than letting the default squash them. */
::view-transition-image-pair(*) { isolation: auto; }
::view-transition-old(*),
::view-transition-new(*)        { mix-blend-mode: normal; }
```

Inline `style=` is the right call here because the name is per-record; a CSS class can't carry a dynamic identifier. If you dislike inline styles, emit `--vt-name` as a custom property and use `view-transition-name: var(--vt-name)` in your stylesheet.

**Interaction with morphing.** Morphing and view transitions are **independent** and compose — a morph render is wrapped in a view transition just like a replace render. But in practice **don't**. Morphing already preserves scroll, focus, selection and in-flight CSS transitions; layering a full-page cross-fade on top makes a same-page refresh look like a navigation, which is exactly the illusion morphing exists to avoid. Ship view transitions for *page-to-page* motion and let morph refreshes be invisible. If you have both, scope the transition off for refreshes:

```css
/* refresh visits are action=replace on the same path → direction "none" */
html[data-turbo-visit-direction="none"]::view-transition-old(root),
html[data-turbo-visit-direction="none"]::view-transition-new(root) {
  animation: none;
}
```

**Decomposition.** None — configuration + CSS.

**A11y.** `prefers-reduced-motion: reduce` is handled by Turbo before the transition starts, so reduced-motion users get an instant swap with no work from you. Don't add motion that conveys meaning (a "back" slide is decoration, not information). Keep durations under ~300ms; view transitions freeze the page (pointer events are blocked on the pseudo-elements) for their duration, so long transitions are a real interaction cost.

**Native.** Turn view transitions **off** in Hotwire Native. The native navigation controller is already animating a push/pop; a web cross-fade underneath it reads as a double animation. Hide it with the standard native stylesheet:

```css
/* app/assets/stylesheets/native.css — loaded only for native clients */
@media (prefers-reduced-motion: no-preference) {
  body[data-hotwire-native] ::view-transition-group(*) { animation: none !important; }
}
```

Better still, omit the meta tag for the native variant. See [04-hotwire-native §4.2 (native request variant) and §4.3](#).

**Pitfalls.**
- Two elements with the same `view-transition-name` on one page → the transition is **skipped entirely**, silently. Common when a record appears both in a sidebar list and the main list.
- `view-transition-name` on an element inside a `position: fixed`/sticky container often produces a jump, because the pseudo-element is positioned against the snapshot viewport, not the container.
- Very large images make transitions janky — the browser snapshots them as textures. Use the variant, not the original.
- `@view-transition { navigation: auto; }` in your stylesheet buys you nothing under Turbo. See above.
- Turbo's opt-in requires the meta on **both** pages; if your error page or sign-in page lacks the layout, transitions to it silently stop working. That's usually desirable.

**Prior art.**
- [Turbo Handbook — Page Refreshes / View Transitions](https://turbo.hotwired.dev/handbook/page_refreshes)
- [MDN — View Transition API](https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API)
- [Chrome — Same-document view transitions](https://developer.chrome.com/docs/web-platform/view-transitions)
- [02-turbo-deep-dive §6](#)

---

### Sidebar state persistence (`data-turbo-permanent`)

**Hotwire answer.** For a *collapsible* sidebar, `data-turbo-permanent` is the wrong first reach. **Store the collapsed state in a cookie and render the class server-side** — that's the only thing that survives a full reload, a new tab, and a Hotwire Native cold start. Use `disclosure` + `persist` for instant client-side feedback, and reserve `data-turbo-permanent` for sidebars with genuinely un-reconstructible DOM state: a scrolled-far-down conversation list, an open `<details>` tree, a playing audio element.

**The `data-turbo-permanent` contract** ([02-turbo-deep-dive §2.7](#)). An element with **both an `id` and `data-turbo-permanent`** is transplanted, live DOM node and all, from the old page into the new one:

1. For each `[id][data-turbo-permanent]` in the **current** page that also exists **by the same id** in the **new** page, Turbo replaces the new page's copy with `<meta name="turbo-permanent-placeholder" content="<id>">`.
2. Swap the body.
3. Put the original live node back where the placeholder was.
4. Restore focus inside the permanent element.

Consequences, all of which bite:

- **It must exist in both documents with the same `id`.** If the new page omits it, it is simply **gone** (under replace). Under **morph** it is *kept* instead — the mechanisms differ (`Bardo` vs idiomorph callbacks) and so does this edge case.
- **The new page's server-rendered contents are discarded.** A permanent element never updates from a Drive visit. To change it, target it with a Turbo Stream or `Turbo.morphElements`.
- Turbo Streams honour permanence too (`StreamMessageRenderer` runs the same Bardo dance).
- Under morphing, `MorphingPageRenderer#preservingPermanentElements` is a **no-op**; permanence is enforced by `beforeNodeMorphed` returning `false` and `beforeNodeAdded` refusing duplicates.

**A real collapsible sidebar.**

```erb
<%# app/views/layouts/_sidebar.html.erb %>
<aside id="sidebar"
       data-turbo-permanent
       data-controller="disclosure persist"
       data-disclosure-open-value="<%= sidebar_open? %>"
       data-disclosure-expanded-class="sidebar--expanded"
       data-persist-key-value="sidebar:open"
       data-persist-attribute-value="data-disclosure-open-value"
       class="sidebar <%= "sidebar--expanded" if sidebar_open? %>">

  <button type="button"
          aria-expanded="<%= sidebar_open? %>"
          aria-controls="sidebar-nav"
          data-disclosure-target="trigger"
          data-action="disclosure#toggle persist#save">
    <span class="sr-only">Toggle navigation</span>
    <%= icon "panel-left" %>
  </button>

  <nav id="sidebar-nav" data-disclosure-target="content" aria-label="Main">
    <%= render "layouts/nav_links" %>
  </nav>
</aside>
```

```ruby
# app/helpers/layout_helper.rb
def sidebar_open?
  cookies[:sidebar_open] != "0"   # default: open
end
```

```js
// app/javascript/controllers/persist_controller.js
import { Controller } from "@hotwired/stimulus"

// Mirrors one attribute of this element to storage and reapplies it on connect.
// Also writes a cookie when `cookie` is set, so the server can render the same state.
export default class extends Controller {
  static values = {
    key: String,
    attribute: { type: String, default: "data-state" },
    storage: { type: String, default: "local" },   // "local" | "session"
    cookie: { type: Boolean, default: false }
  }

  connect() {
    const stored = this.#store.getItem(this.keyValue)
    if (stored !== null) this.element.setAttribute(this.attributeValue, stored)
  }

  save() {
    const value = this.element.getAttribute(this.attributeValue) ?? ""
    this.#store.setItem(this.keyValue, value)
    if (this.cookieValue) {
      document.cookie = `${this.keyValue}=${encodeURIComponent(value)}; path=/; max-age=31536000; samesite=lax`
    }
  }

  get #store() {
    return this.storageValue === "session" ? sessionStorage : localStorage
  }
}
```

For the cookie version, swap the two data attributes: `data-persist-key-value="sidebar_open"` + `data-persist-cookie-value="true"`, and have `sidebar_open?` read `cookies[:sidebar_open]`. Now the server renders `sidebar--expanded` on the very first byte and there is no flash on hard reload.

**The three approaches, ranked.**

| Approach | Survives Drive visit | Survives morph | Survives **hard reload** | Survives new tab | Cost |
|---|---|---|---|---|---|
| Cookie + server-rendered class | yes | yes | **yes** | yes | one cookie, one helper |
| `persist` → localStorage | yes | yes | yes, **after a flash** | yes | FOUC on cold load |
| `data-turbo-permanent` | yes | yes | **no** | no | zero, but see failure modes |
| Pure CSS `:has()` + checkbox | no (checkbox state is not cached reliably) | partially | no | no | zero JS |

The pure-CSS version, for completeness — genuinely fine for a mobile menu, wrong for a persisted preference:

```html
<input type="checkbox" id="sidebar-toggle" class="sr-only">
<label for="sidebar-toggle">Toggle navigation</label>
<aside class="sidebar">…</aside>
```
```css
body:has(#sidebar-toggle:checked) .sidebar { inline-size: 4rem }
```
`:has()` is [Baseline widely available since 2023-12](https://webstatus.dev/features/has). But a checkbox is not a button, `aria-expanded` has nowhere to live, and Turbo's snapshot clone does not reliably carry checkbox state — so it flashes on Back.

**Failure modes of `data-turbo-permanent`.**

- **Missing on the destination page.** Under a replace render the element is deleted. Classic symptom: sidebar disappears when you navigate to a page rendered with a different layout (admin, sign-in, error).
- **No `id`.** Silently ignored. There is no warning.
- **Stimulus controllers inside a permanent element do NOT reconnect.** The node is transplanted, never disconnected and never re-added in a way Stimulus observes as new — so `disconnect()`/`connect()` do not fire across the visit. This is usually what you want (that's the point) but it means: any controller that reads page-specific data on `connect()` will keep the *old* page's data forever. Never put a controller that depends on `document`-level page state inside a permanent element. Values still work — but only if something updates them, which a Drive visit will not.
- **Nested frames.** A `<turbo-frame>` inside `[data-turbo-permanent]` is exempted from morph-driven reloading (`shouldRefreshFrameWithMorphing` explicitly returns false for `currentFrame.closest("[data-turbo-permanent]")`). Your permanent sidebar's lazy frame will stop refreshing on page refreshes. Usually a surprise.
- **Active-link highlighting stops working.** The classic bite: your permanent sidebar's "current page" class is baked in from whenever the node was created, and Drive navigation won't update it. Fix by driving the highlight from CSS off a `<body data-current-section>` attribute, or by updating the sidebar with a Turbo Stream, or — simplest — by not making the sidebar permanent and using the cookie approach instead.

**Decomposition.** `disclosure` + `persist`. Add `focus-trap` + `scroll-lock` + `dismiss` only for the mobile off-canvas variant (see *Mobile nav*).

**A11y.** [APG Disclosure pattern](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/). Trigger is a `<button>` with `aria-expanded` and `aria-controls` pointing at the nav's id. Wrap the links in `<nav aria-label="Main">`. When collapsed to an icon rail, keep accessible names on the links (`aria-label` or a visually-hidden span) — icon-only nav with no name is the most common a11y failure in this component. Never `display: none` the nav on desktop collapse if links should remain reachable; use a width transition.

**Native.** Hide it. A web sidebar inside a Hotwire Native app competes with the native tab bar / navigation. Stamp the body and hide with CSS rather than branching in ERB (which doubles your cache footprint):

```erb
<body <%= "data-hotwire-native" if hotwire_native_app? %>>
```
```css
body[data-hotwire-native] .sidebar { display: none }
```
See [04-hotwire-native §4.3 "Hiding web chrome"](#) and §7.4 (native tabs).

**Prior art.**
- [Turbo Reference — Attributes (`data-turbo-permanent`)](https://turbo.hotwired.dev/reference/attributes)
- [02-turbo-deep-dive §2.7](#)
- [@stimulus-components/reveal](https://www.stimulus-components.com/docs/components/reveal) 5.0.0 — targets `item`, class `data-reveal-hidden-class` (default `"hidden"`), actions `reveal#toggle`/`#show`/`#hide`; syncs `aria-expanded` on the trigger if present. Closest off-the-shelf `disclosure`.
- [tailwindcss-stimulus-components](https://github.com/excid3/tailwindcss-stimulus-components) — `toggle` controller

---

### Sticky headers

**Hotwire answer.** `position: sticky`. **No JS needed.** For the "shrink/elevate on scroll" variant, use an `intersection` observer on a zero-height sentinel — **never** a `scroll` listener. In 2026 you can also do it with a scroll-driven animation, but check support first (below).

**Code.**

```css
.site-header {
  position: sticky;
  inset-block-start: 0;
  z-index: 10;
  transition: box-shadow 150ms, padding-block 150ms;
}
/* the sentinel sits immediately before the header, 0px tall */
.site-header--stuck { box-shadow: 0 1px 0 rgb(0 0 0 / .1); padding-block: .5rem }
```

```erb
<div data-controller="intersection"
     data-intersection-root-margin-value="0px"
     data-action="intersection:leave->header#stick intersection:enter->header#unstick"
     aria-hidden="true" style="height:1px"></div>
<header class="site-header" data-header-target="bar"> … </header>
```

The scroll-driven-animation version, which needs no controller at all:

```css
@supports (animation-timeline: scroll()) {
  .site-header {
    animation: shrink linear both;
    animation-timeline: scroll(root block);
    animation-range: 0 120px;
  }
  @keyframes shrink {
    to { padding-block: .5rem; box-shadow: 0 1px 0 rgb(0 0 0 / .1) }
  }
}
```

**Support check, 2026-08-15:** scroll-driven animations are **Baseline: Limited** — Chrome 115+, **Safari 26+**, **Firefox: not shipped** ([webstatus.dev](https://webstatus.dev/features/scroll-driven-animations)). So this is a progressive enhancement behind `@supports`, not a replacement for the sentinel. `position: sticky` itself is universal.

**Decomposition.** `intersection` (sentinel) — or nothing at all with CSS.

**A11y.** A sticky header eats vertical space; cap it at ~15% of viewport height and add `scroll-padding-block-start: <header height>` on `:root` so in-page anchors and `scrollIntoView` don't land under it. Respect `prefers-reduced-motion` for the shrink transition.

**Native.** Hide the whole web header under Hotwire Native — the native navigation bar is the header. `body[data-hotwire-native] .site-header { display: none }`. See [04-hotwire-native §4.3](#).

**Pitfalls.**
- `position: sticky` does nothing if **any** ancestor has `overflow: hidden|auto|scroll` — the single most common cause of "sticky doesn't work".
- It also needs the parent to be taller than the sticky element; a sticky child of a `height: fit-content` parent never sticks.
- A `scroll` listener for this is a performance bug: it runs on the main thread on every frame. Use `IntersectionObserver`.
- Turbo morph refreshes preserve scroll, so a stuck header stays stuck — good. Turbo *replace* renders reset scroll to top, and your `--stuck` class comes back from the cache still applied. Toggle it from the observer on `connect()`, not from a cached class.

**Prior art.** [stimulus-use `useIntersection`](https://stimulus-use.github.io/stimulus-use/#/use-intersection) · [MDN — `position: sticky`](https://developer.mozilla.org/en-US/docs/Web/CSS/position) · [Scroll-driven Animations demos](https://scroll-driven-animations.style/)

---

### Breadcrumbs

**Hotwire answer.** Server-rendered ERB. **No JS needed, no Stimulus, no Turbo.** A partial and a helper. Add `BreadcrumbList` JSON-LD in the same partial so the structured data can never drift from the visible trail.

**Code.**

```erb
<%# app/views/shared/_breadcrumbs.html.erb — crumbs: [[name, path], ...], last path may be nil %>
<nav aria-label="Breadcrumb" class="breadcrumbs">
  <ol>
    <% crumbs.each_with_index do |(name, path), i| %>
      <li>
        <% if path && i < crumbs.size - 1 %>
          <%= link_to name, path %>
        <% else %>
          <span aria-current="page"><%= name %></span>
        <% end %>
      </li>
    <% end %>
  </ol>
</nav>

<script type="application/ld+json">
<%= {
  "@context" => "https://schema.org",
  "@type" => "BreadcrumbList",
  "itemListElement" => crumbs.each_with_index.map { |(name, path), i|
    { "@type" => "ListItem", "position" => i + 1, "name" => name,
      "item" => (url_for(path) if path) }.compact
  }
}.to_json.html_safe %>
</script>
```

Separators go in CSS (`li + li::before { content: "/" }`), never in the markup — a screen reader shouldn't read "slash".

**Decomposition.** None.

**A11y.** [APG Breadcrumb pattern](https://www.w3.org/WAI/ARIA/apg/patterns/breadcrumb/). `<nav aria-label="Breadcrumb">` wrapping an `<ol>`; the current page is **not a link** and carries `aria-current="page"`. If you must link the current page, put `aria-current="page"` on the `<a>`.

**Native.** Hide. The native navigation bar's back button and title are the breadcrumb. `body[data-hotwire-native] .breadcrumbs { display: none }`.

**Pitfalls.**
- Breadcrumbs inside a `<turbo-frame>` that the frame doesn't re-render go stale. Keep them outside the frame, or render them in the frame's response.
- Don't derive crumbs from `request.path` segments — you'll get IDs in the trail.

**Prior art.**
- [gretel](https://github.com/kzkn/gretel) — **5.1.0 (2025-12-09)**. Note the maintained gem now ships from the `kzkn` fork; the original `lassebunk/gretel` is dormant. DSL in `config/breadcrumbs.rb`, semantic + JSON-LD output. **The 2026 pick if you want a gem.**
- [breadcrumbs_on_rails](https://github.com/weppos/breadcrumbs_on_rails) — 4.1.0 (gem 2021-04, repo touched 2024-12). Works, barely maintained.
- [loaf](https://github.com/piotrmurach/loaf) — 0.10.0 (2020-11), repo last pushed 2022. **Stale; don't start here.**
- Honestly: most 2026 Rails apps skip the gem and pass an array into a partial, exactly as above. A DSL buys little for ~15 lines of ERB.

---

### Mobile nav (off-canvas drawer)

**Hotwire answer.** A `<dialog>` with `showModal()`, driven by `dialog` + `dismiss` + `transition`, that **closes itself on `turbo:before-visit`**. Not `data-turbo-permanent` — a nav drawer should be destroyed on navigation, not preserved. (The Overlays researcher owns the drawer mechanics — `scroll-lock`, `focus-trap`, `@starting-style` slide-in, iOS `position: fixed` quirks. This record covers only the navigation-specific parts.)

**`<dialog>` vs `disclosure`.** Use `<dialog>` + `showModal()` for a **modal** off-canvas drawer (the common mobile pattern: overlay, background inert, Esc closes, focus trapped). Use `disclosure` for a nav that **pushes content** rather than covering it, or for a desktop collapse — a non-modal panel should not steal focus or make the page inert. `showModal()` gives you the top layer, `::backdrop`, Esc handling and `inert` background for free; hand-rolling that with a `<div>` is the mistake.

**The "menu stays open after you tap a link" bug.** Tap a nav link, Turbo swaps the body, and the drawer either (a) stays open over the new page, or (b) reopens later out of the restoration cache. Two distinct causes, two distinct fixes — you need **both**:

```js
// app/javascript/controllers/dialog_controller.js — the navigation-aware parts
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]
  static values = { closeOnNavigate: { type: Boolean, default: false } }

  connect() {
    if (this.closeOnNavigateValue) {
      this.#onBeforeVisit = () => this.close()
      addEventListener("turbo:before-visit", this.#onBeforeVisit)
    }
  }

  disconnect() {
    if (this.#onBeforeVisit) removeEventListener("turbo:before-visit", this.#onBeforeVisit)
  }

  open()  { this.dialogTarget.showModal() }
  close() { if (this.dialogTarget.open) this.dialogTarget.close() }

  #onBeforeVisit
}
```

```js
// app/javascript/turbo_hygiene.js — belt and braces: never cache an open dialog
document.addEventListener("turbo:before-cache", () => {
  document.querySelectorAll("dialog[open]").forEach((d) => d.close())
})
```

Which event, and why:

| Event | Fires on | Use it? |
|---|---|---|
| `turbo:click` | link click, before the visit is proposed | too early — a cancelled visit leaves the menu closed |
| **`turbo:before-visit`** | before any Drive visit, cancelable | **yes** — closes as the navigation starts, so the drawer animates out with the page |
| `turbo:visit` | visit started | works, but after the request is already in flight |
| `turbo:load` | after render | too late — you get a visible flash of the drawer over the new page |
| `turbo:before-cache` | before the snapshot is taken | **also yes**, but as hygiene, not as the primary fix (it doesn't fire on a cancelled/failed visit) |

Note `turbo:before-visit` does **not** fire for restoration (Back/Forward) visits — that's what the `turbo:before-cache` half covers.

**`data-turbo-permanent` vs re-rendering.** Do **not** make a mobile nav drawer permanent. If you do: the active-link highlight freezes at whatever page created it, the Stimulus controller inside never reconnects (see the sidebar record), and the drawer survives the navigation *by design* — which is the bug you're trying to fix. Re-render it every page; it's a `<nav>` full of links, it costs nothing. The one exception is a drawer containing a live search input the user is mid-typing in, and even then prefer `data-turbo-permanent` on just the `<input>`, not the drawer.

**Closing without navigating.** A link inside the drawer that targets a `<turbo-frame>` doesn't fire `turbo:before-visit` at all. Close on `turbo:frame-load` too, or put `data-action="click->dialog#close"` on the frame-targeting links.

**Decomposition.** `dialog` + `focus-trap` + `dismiss` + `scroll-lock` + `transition`. Plus `hotkey` if you want a keyboard shortcut. See the Overlays section for those primitives.

**A11y.** `<nav aria-label="Mobile">` inside the dialog. The trigger is a `<button aria-expanded aria-controls>` with a real accessible name ("Menu", not just a hamburger glyph). `showModal()` handles Esc, focus trapping and background `inert`. Move focus to the first link (or the close button) on open and **restore it to the trigger on close** — `<dialog>` does the restore for you only if the trigger was focused when `showModal()` was called. Mark the current page's link `aria-current="page"`.

**Native.** **Delete it entirely.** In a Hotwire Native app the native tab bar / navigation stack replaces the web mobile menu, and shipping both is the single most common "this feels like a website" tell. Hide with CSS off the stamped body attribute rather than branching in ERB:

```erb
<body <%= "data-hotwire-native" if hotwire_native_app? %>>
```
```css
body[data-hotwire-native] .mobile-nav,
body[data-hotwire-native] .mobile-nav-trigger { display: none !important }
```

If a specific native build ships an overflow-menu bridge component, hide the web control conditionally on the advertised components instead — `<html>` carries `data-bridge-components`, so `[data-bridge-components~="overflow-menu"] .mobile-nav-trigger { display: none }` is version-aware for free with no server change. See [04-hotwire-native §3.6, §4.3, §7.4](#).

**Pitfalls.**
- Removing the `turbo:before-visit` listener in `disconnect()` is mandatory — it's a `window` listener, and Turbo caching means `connect()` runs again on Back.
- `dialog.close()` on an already-closed dialog is a no-op but `showModal()` on an already-open one **throws**. Guard both.
- iOS Safari: `showModal()` + `overflow: hidden` on `<body>` still lets the page scroll behind on some versions; the `scroll-lock` primitive's `position: fixed; top: -scrollY` technique is what actually works. (Overlays section.)
- A drawer rendered inside a `<turbo-frame>` will be destroyed when the frame navigates. Render it in the layout.

**Prior art.**
- [@stimulus-components/dropdown](https://www.stimulus-components.com/docs/components/dropdown) 3.0.0 — targets `button`/`menu`, `data-transition-enter-from/to`, ARIA disclosure semantics
- [tailwindcss-stimulus-components](https://github.com/excid3/tailwindcss-stimulus-components) — `slideover`, `modal`
- [@github/details-menu-element](https://github.com/github/details-menu-element)

---

### Layout shift & `<turbo-frame>` sizing

**Hotwire answer.** Reserve the space in CSS before the frame loads. **No JS needed.** A `<turbo-frame loading="lazy">` with no content is a zero-height inline element; when its response lands, everything below jumps. That's Cumulative Layout Shift, and it's the single most common Turbo-specific CLS source.

**Code.**

```erb
<%= turbo_frame_tag "recommendations", src: recommendations_path, loading: :lazy,
      class: "frame-skeleton" do %>
  <%= render "shared/skeleton_rows", count: 3 %>
<% end %>
```

```css
turbo-frame { display: block }            /* it is inline by default — set this globally */

.frame-skeleton { min-block-size: 12rem } /* or aspect-ratio: 16 / 9 for media */
turbo-frame[busy] { opacity: .6; transition: opacity 120ms }
turbo-frame[complete] .frame-skeleton { min-block-size: 0 }
```

Three tools, in order: **(1)** put real skeleton markup *inside* the frame — it's the placeholder AND the perceived-performance win; **(2)** `min-block-size` matching the typical loaded height; **(3)** `aspect-ratio` when the content has a known ratio (charts, maps, video). `content-visibility: auto` + `contain-intrinsic-size` is a legitimate fourth option ([Baseline newly available 2025-09](https://webstatus.dev/features/content-visibility), Safari 26+) for long lists of frames.

**Decomposition.** None.

**A11y.** Turbo sets `busy` on a loading frame and `aria-busy="true"` on the element; add `aria-live="polite"` to the frame if the loaded content is the answer to a user action, so it's announced. Skeleton placeholders should be `aria-hidden="true"` with a visually-hidden "Loading…" for AT.

**Native.** Zero-height frames on a cold native web view are worse — the native screen renders empty and then jumps. Same fix.

**Pitfalls.**
- `<turbo-frame>` is `display: inline` until you say otherwise. Half of "my frame CSS does nothing" is this.
- A lazy frame inside `display: none` loads on *first intersection*, which includes the moment the container becomes visible — great for modals, surprising if you were counting bytes.
- Skeleton height that's wildly wrong causes CLS in the *other* direction. Measure the real thing.

**Prior art.** [Turbo Reference — Frames](https://turbo.hotwired.dev/reference/frames) · [@stimulus-components/content-loader](https://www.stimulus-components.com/docs/components/content-loader) (largely superseded by lazy frames) · [web.dev — Optimize CLS](https://web.dev/articles/optimize-cls)

---

### Clipboard copy

**Hotwire answer.** A `clipboard` Stimulus controller around `navigator.clipboard.writeText`. This is the canonical case where a controller is right: there is no HTML element for "copy". If you'd rather not own the code, `<clipboard-copy>` from GitHub is a drop-in web component that survives morphs for free.

**Code — the full `clipboard` primitive.**

```js
// app/javascript/controllers/clipboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button", "status"]
  static classes = ["success"]
  static values = {
    content: String,                                   // copy this literal instead of a target
    successContent: { type: String, default: "Copied!" },
    successDuration: { type: Number, default: 2000 }
  }

  connect() {
    // Hide the control entirely where the API can't work (non-secure context, old browser).
    if (!this.#supported) this.element.hidden = true
  }

  disconnect() {
    clearTimeout(this.#timer)
  }

  async copy(event) {
    event?.preventDefault()

    const text = this.hasContentValue
      ? this.contentValue
      : (this.sourceTarget.value ?? this.sourceTarget.textContent).trim()

    // Cancelable hook so a wrapper can transform or veto the payload.
    const before = this.dispatch("copy", { detail: { text }, cancelable: true })
    if (before.defaultPrevented) return

    try {
      await navigator.clipboard.writeText(before.detail.text)
    } catch {
      if (!this.#legacyCopy(before.detail.text)) return
    }

    this.copied()
    this.dispatch("copied", { detail: { text: before.detail.text } })
  }

  copied() {
    if (this.hasSuccessClass) this.element.classList.add(...this.successClasses)

    let restore = () => {}
    if (this.hasButtonTarget) {
      const original = this.buttonTarget.innerHTML
      this.buttonTarget.innerHTML = this.successContentValue
      restore = () => { this.buttonTarget.innerHTML = original }
    }
    // Announce to assistive tech. The region must already exist in the DOM.
    if (this.hasStatusTarget) this.statusTarget.textContent = "Copied to clipboard"

    clearTimeout(this.#timer)
    this.#timer = setTimeout(() => {
      if (this.hasSuccessClass) this.element.classList.remove(...this.successClasses)
      restore()
      if (this.hasStatusTarget) this.statusTarget.textContent = ""
    }, this.successDurationValue)
  }

  // Fallback for insecure contexts (http:// staging) and Safari's occasional
  // "not allowed without user gesture" rejection inside async chains.
  #legacyCopy(text) {
    const ta = document.createElement("textarea")
    ta.value = text
    ta.setAttribute("readonly", "")
    ta.style.cssText = "position:fixed;top:-9999px;opacity:0"
    document.body.appendChild(ta)
    ta.select()
    let ok = false
    try { ok = document.execCommand("copy") } catch { ok = false }
    ta.remove()
    return ok
  }

  get #supported() {
    return !!navigator.clipboard?.writeText || !!document.execCommand
  }

  #timer
}
```

```erb
<div data-controller="clipboard"
     data-clipboard-success-class="copied"
     data-clipboard-success-duration-value="1800">
  <input type="text" readonly value="<%= @invite.url %>"
         data-clipboard-target="source"
         aria-label="Invite link">
  <button type="button"
          data-clipboard-target="button"
          data-action="clipboard#copy">Copy link</button>
  <span class="sr-only" role="status" data-clipboard-target="status"></span>
</div>
```

Copying a value that isn't in the DOM (an API token you render once):

```erb
<button type="button"
        data-controller="clipboard"
        data-clipboard-content-value="<%= @token %>"
        data-action="clipboard#copy">Copy token</button>
```

Because it dispatches `clipboard:copied`, you can compose feedback without touching the controller — `data-action="clipboard:copied->transition#flash"`.

**The web-component alternative**, which is one line and immune to Turbo lifecycle entirely:

```erb
<clipboard-copy for="invite-url" class="btn">Copy link</clipboard-copy>
<input id="invite-url" readonly value="<%= @invite.url %>">
```
`<clipboard-copy for="…">` or `value="…"`; fires a bubbling `clipboard-copy` event on success. Ship this if you don't need the composable primitive.

**Decomposition.** `clipboard` (+ `transition` for the feedback animation, wired via `data-action="clipboard:copied->transition#flash"`).

**A11y.** The control is a `<button>`, not a `<div>` or an icon-only `<a>`. Announce success in a live region — a `role="status"` (implicit `aria-live="polite"`) element that **exists in the DOM before the text is inserted**, otherwise nothing is announced. Swapping the button label from "Copy" to "Copied!" also renames the button mid-interaction, which some screen readers re-announce and some don't; the separate status region is the reliable channel. Don't rely on a tooltip alone. Keep a visible label or `aria-label` on icon-only buttons.

**Native.** No bridge component needed — `navigator.clipboard` works in `WKWebView`/Android WebView. If you want the native toast instead of a web one, that's a `bridge--toast` component. Note the iOS system paste banner will appear over your feedback.

**Pitfalls.**
- `navigator.clipboard` requires a **secure context**. On plain-`http://` staging it is `undefined` — hence the `#supported` guard and the `execCommand` fallback (deprecated, still universally implemented).
- Safari rejects `writeText` if the promise chain loses the user-gesture context. Never `await` a fetch *before* `writeText`; if you must fetch the text, use `ClipboardItem` with a promise, or fetch first and copy on a second click.
- `sourceTarget.textContent` on a `<pre>` includes the leading newline your ERB indentation produced. `.trim()`, or render the code block without leading whitespace.
- Firefox historically gated `navigator.clipboard.readText` behind a permission — `writeText` is fine. Don't build a "paste" button.
- Under morphing, a controller whose success class is on the element will get that class morphed away if the server re-renders. Keep the transient class on a child, or mark it `data-turbo-permanent`.

**Prior art.**
- [Stimulus Handbook ch. 3](https://stimulus.hotwired.dev/handbook/managing-state) — the original clipboard example
- [@stimulus-components/clipboard](https://www.stimulus-components.com/docs/components/clipboard) **5.0.0** — targets `source`, `button`; values `successContent` (default `""`), `successDuration` (default `2000`); action `clipboard#copy`; overridable `copy()`/`copied()` hooks
- [@github/clipboard-copy-element](https://github.com/github/clipboard-copy-element) **1.3.2** (2026-06-16) — actively maintained, not deprecated

---

### Hotkeys

**Hotwire answer.** Ship [`@github/hotkey`](https://github.com/github/hotkey). It is declarative (`data-hotkey` on the element that should be activated), framework-free, ~2KB, and its model — "a hotkey clicks or focuses an element" — is exactly right for a server-rendered app. Wrap its `install`/`uninstall` in a three-line Stimulus controller so Turbo lifecycle is handled. Hand-roll only when you need a chord that doesn't map to an element.

**The three options, honestly compared.**

| | `@github/hotkey` 3.1.4 | stimulus-use `useHotkeys` | Stimulus built-in key filters |
|---|---|---|---|
| Declaration | `data-hotkey="Mod+k"` on the target element | JS map inside a controller | `data-action="keydown.esc->x#close"` |
| Fires | `.click()` (or `.focus()` for fields/contenteditable) | your callback | your action |
| Global scope | yes, document-wide | yes, via `hotkeys-js` scopes | only via `@window`/`@document` |
| Sequences (`g` then `c`) | **yes** | no | no |
| Suppressed in text fields | **yes, by default** | via `hotkeys.filter` (a global — last controller wins) | no, you must check yourself |
| Extra dependency | 2KB | `hotkeys-js` | none |

`@github/hotkey` wins because the shortcut lives on the thing it activates, so it can't drift, and it's visible when you read the template.

**Exact syntax** (verified against source, v3.1.4):

- Single key: `data-hotkey="j"`
- Alternatives: comma-separated — `data-hotkey="s,/"`
- **Sequences**: space-separated — `data-hotkey="g c"` (press `g` then `c`)
- **Modifiers**: plus-separated in the fixed order `Control+Alt+Meta+Shift+KEY` — e.g. `Control+Alt+h`
- **`Mod+s` is the cross-platform modifier**: resolves to `Meta` on macOS and `Control` on Windows/Linux. Use `Mod`, not `Meta` (which is Mac-only literal). This is the answer to the ⌘-vs-Ctrl problem — you do not detect the platform yourself.
- `Plus` and `Space` are the special names for the literal `+` and space keys.
- Shift must be explicit when held: `Shift+A`, not `A`.
- **Action**: `input`/`textarea`/`select`/`contenteditable` get `.focus()`; everything else gets `.click()`. Overridable via the cancelable `hotkey-fire` event.
- **Scoping**: hotkeys are suppressed while focus is in a text-editable field, unless scoped with `data-hotkey-scope="<id>"` matching the focused field's `id`.

**Code.**

```js
// app/javascript/controllers/hotkey_controller.js
import { Controller } from "@hotwired/stimulus"
import { install, uninstall } from "@github/hotkey"

// Put this on <body> once; it installs every [data-hotkey] in its subtree
// and re-installs after Turbo Stream/frame updates.
export default class extends Controller {
  connect() {
    this.#installAll()
    this.observer = new MutationObserver(() => this.#installAll())
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
    for (const el of this.#elements) uninstall(el)
  }

  #installAll() {
    for (const el of this.#elements) {
      if (el.dataset.hotkeyInstalled) continue
      install(el)
      el.dataset.hotkeyInstalled = "true"
    }
  }

  get #elements() {
    return this.element.querySelectorAll("[data-hotkey]")
  }
}
```

```erb
<%# app/views/layouts/application.html.erb %>
<body data-controller="hotkey">
  <button type="button" data-hotkey="Mod+k"
          aria-keyshortcuts="Meta+K Control+K"
          data-action="dialog#open">Search</button>

  <%= link_to "New ticket", new_ticket_path,
        data: { hotkey: "c" }, "aria-keyshortcuts": "C" %>

  <%= link_to "Keyboard shortcuts", "#shortcuts",
        data: { hotkey: "?", action: "dialog#open" } %>
</body>
```

**Discoverability — the `?` help dialog.** A shortcut nobody knows about is dead code. Ship a `?`-triggered dialog listing them, generated from the same source of truth:

```erb
<%# app/views/shared/_shortcuts.html.erb %>
<dialog id="shortcuts" data-controller="dialog focus-trap" aria-labelledby="shortcuts-title">
  <h2 id="shortcuts-title">Keyboard shortcuts</h2>
  <dl>
    <% SHORTCUTS.each do |keys, description| %>
      <div>
        <dt><% keys.split("+").each do |k| %><kbd><%= k %></kbd><% end %></dt>
        <dd><%= description %></dd>
      </div>
    <% end %>
  </dl>
  <button data-action="dialog#close" autofocus>Close</button>
</dialog>
```

`<kbd>` is the correct element and gives you free styling hooks. Render ⌘ vs Ctrl from CSS, not Ruby — the server doesn't know the client's platform:

```css
.kbd-mod::after { content: "Ctrl" }
@supports (-webkit-touch-callout: none) { .kbd-mod::after { content: "⌘" } }
```
(or a two-line `navigator.platform` check in the `hotkey` controller that stamps `<html data-platform="mac">`.)

**Decomposition.** `hotkey`. Composes with `dialog` (command palette), `combobox` (⌘K search), `dismiss` (Esc).

**A11y.** Set `aria-keyshortcuts` on the element the shortcut activates — it is the *only* programmatic channel that tells AT a shortcut exists. Its value uses the ARIA key names (`Meta+K`, `Control+K`, space-separated for alternatives), **not** the `data-hotkey` syntax, so the two attributes will not match and that's correct. Provide a visible way to reach every shortcut's action (a real button/link — which `@github/hotkey` requires anyway, since it clicks an element). Single-character shortcuts without a modifier are an [WCAG 2.1.4 Character Key Shortcuts](https://www.w3.org/WAI/WCAG22/Understanding/character-key-shortcuts.html) risk for speech-input users: you must offer a way to turn them off, remap them, or make them active only when a component has focus. `@github/hotkey`'s "suppressed inside text fields" default covers the most common failure but not speech input — ship an "enable keyboard shortcuts" preference.

**Native.** Largely n/a — no physical keyboard on phones. On iPad with a hardware keyboard it works, but the native app should register real `UIKeyCommand`s for anything important (they show in the ⌘-hold HUD). Hide the `?` shortcuts dialog: `body[data-hotwire-native] [data-shortcut-help] { display: none }`.

**Pitfalls.**
- `install()` is idempotent-unsafe — calling it twice on the same element binds twice. Hence the `dataset.hotkeyInstalled` guard.
- Turbo Streams replace DOM without firing `turbo:load`, so newly-streamed `[data-hotkey]` elements are never installed. The `MutationObserver` above is the fix; a `turbo:load` listener alone is not enough.
- `Meta+K` is Cmd+K on Mac and the Windows key on Windows. Always `Mod`.
- Browser-reserved chords (`Mod+n`, `Mod+t`, `Mod+w`) cannot be intercepted reliably. Pick from the safe set: `Mod+k`, `Mod+/`, `Mod+Enter`, and single letters.
- Stimulus's built-in key filters are **exhaustive matchers** — `keydown.k` will not fire if any modifier is held. That's a feature for `esc`, a trap for anything else. See [03-stimulus-deep-dive §on key filters](#).
- stimulus-use's `useHotkeys` lives at `stimulus-use/hotkeys`, **not** the main entry point (which exports a deliberately throwing stub so `hotkeys-js` stays out of your bundle). And `hotkeys.filter` is a global on the `hotkeys-js` singleton — the last controller to set it wins.

**Prior art.**
- [@github/hotkey](https://github.com/github/hotkey) **3.1.4** (2026-03-16) — active
- [stimulus-use `useHotkeys`](https://stimulus-use.github.io/stimulus-use/#/use-hotkeys) — `stimulus-use` **0.53.0** (2026-06-30), from [stimulus-use/stimulus-use](https://github.com/stimulus-use/stimulus-use)
- [@stimulus-components/hotkey](https://www.stimulus-components.com/) — thin, values `key:String`, clicks/focuses `this.element`, skips when focus is in an input
- [Stimulus Reference — Actions (key filters)](https://stimulus.hotwired.dev/reference/actions#keyboardevent-filter)

---

### Dark-mode toggle with persistence

**Hotwire answer.** **Cookie-rendered class on `<html>`, plus `color-scheme` and `light-dark()` in CSS.** The server writes the theme into the first byte of HTML, so there is no FOUC on cold load, no blocking inline script, and it works identically in Hotwire Native. Stimulus does exactly two things: flip the class for instant feedback and write the cookie. `persist` to `localStorage` is the fallback for a static/CDN-cached page where the server can't vary.

**Why the cookie and not the inline script.** The inline blocking `<script>` in `<head>` is the standard SPA answer and it does work — but in a Turbo app it's strictly worse: (a) it runs once per *document*, and Turbo replaces the `<body>` without re-running head scripts, so it can't participate in navigation at all; (b) it's a render-blocking script you now have to CSP-nonce; (c) it can't be server-side-rendered into a cached fragment, so any cached HTML has the wrong theme baked into its class names if you use `dark:` variants. The cookie is already on every request, Rails already varies on it if you tell it to, and Hotwire Native's web view sends it too. Use the cookie.

**Code.**

```ruby
# app/controllers/concerns/theme.rb
module Theme
  extend ActiveSupport::Concern

  THEMES = %w[system light dark].freeze

  included do
    helper_method :current_theme
  end

  def current_theme
    t = cookies[:theme]
    THEMES.include?(t) ? t : "system"
  end
end
```

```ruby
# app/controllers/themes_controller.rb
class ThemesController < ApplicationController
  def update
    theme = params[:theme].presence_in(Theme::THEMES) || "system"
    cookies[:theme] = { value: theme, expires: 1.year.from_now, same_site: :lax, path: "/" }
    redirect_back fallback_location: root_path, status: :see_other
  end
end
```

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html lang="en" data-theme="<%= current_theme %>">
  <head>
    <%# tells the UA which form controls / scrollbars / form autofill colors to use %>
    <meta name="color-scheme" content="light dark">
    <%= csrf_meta_tags %>
    <% turbo_refreshes_with method: :morph, scroll: :preserve %>
  </head>
  <body> … </body>
</html>
```

```css
/* app/assets/stylesheets/theme.css */
:root {
  color-scheme: light dark;                 /* honours the OS setting; "system" mode */
  --bg:      light-dark(#ffffff, #0b0d10);
  --fg:      light-dark(#16181d, #e7e9ee);
  --muted:   light-dark(#5c626e, #9aa1ae);
  --surface: light-dark(#f6f7f9, #14171c);
  --border:  light-dark(#e2e5ea, #262b33);
}
html[data-theme="light"] { color-scheme: light }
html[data-theme="dark"]  { color-scheme: dark }

body { background: var(--bg); color: var(--fg) }
```

That is the whole thing. **`light-dark()` reads the computed `color-scheme`**, so setting `color-scheme: dark` on `<html>` flips every token at once — you write each color pair exactly once and never repeat a `prefers-color-scheme` block. `color-scheme` also fixes the two things a class-based theme always gets wrong: native form controls and the scrollbar.

```js
// app/javascript/controllers/theme_controller.js
import { Controller } from "@hotwired/stimulus"

// Three-state: system / light / dark. Flips <html data-theme> immediately for
// instant feedback, then persists via cookie so the server renders it next time.
export default class extends Controller {
  static values = { theme: { type: String, default: "system" } }
  static targets = ["option"]

  connect() {
    // Turbo replaces <body> but never <html>, so the attribute survives Drive
    // visits and morphs — but this controller is a NEW instance on every visit
    // and must re-sync its own UI from the DOM, not from memory.
    this.themeValue = document.documentElement.dataset.theme || "system"
    this.#syncOptions()
  }

  select(event) {
    this.themeValue = event.params.theme ?? event.target.value
  }

  themeValueChanged(theme, previous) {
    document.documentElement.dataset.theme = theme
    this.#syncOptions()
    if (previous === undefined) return                 // initial set on connect: don't write
    document.cookie = `theme=${theme}; path=/; max-age=31536000; samesite=lax`
  }

  #syncOptions() {
    for (const el of this.optionTargets) {
      const active = el.dataset.themeThemeParam === this.themeValue
      el.setAttribute("aria-checked", active)
      el.tabIndex = active ? 0 : -1
    }
  }
}
```

```erb
<%# app/views/shared/_theme_switch.html.erb %>
<div data-controller="theme"
     role="radiogroup" aria-label="Color theme">
  <% %w[system light dark].each do |theme| %>
    <button type="button"
            role="radio"
            aria-checked="<%= current_theme == theme %>"
            tabindex="<%= current_theme == theme ? 0 : -1 %>"
            data-theme-target="option"
            data-theme-theme-param="<%= theme %>"
            data-action="theme#select">
      <%= icon(theme) %><span><%= theme.titleize %></span>
    </button>
  <% end %>
</div>
```

Add `roving-focus` to the radiogroup for arrow-key navigation, which the APG radio pattern requires.

**Cache correctness.** Because the theme is now in the HTML, any full-page HTTP cache must vary on it:

```ruby
# app/controllers/application_controller.rb
before_action { response.headers["Vary"] = [response.headers["Vary"], "Cookie"].compact.join(", ") }
```
Fragment caches need the theme in the cache key **only if** your CSS uses `dark:`-style utility variants that bake the theme into class names. With the `light-dark()` token approach above, the markup is theme-independent and your fragment caches need no extra dimension. That is a second, quieter reason to prefer tokens over `dark:` variants.

**The Turbo-specific issue.** `PageRenderer` only touches **`lang`** and **`dir`** on `<html>`:

```js
#setLanguage() {
  const { documentElement } = this.currentSnapshot
  const { dir, lang } = this.newSnapshot
  if (lang) documentElement.setAttribute("lang", lang) else documentElement.removeAttribute("lang")
  if (dir)  documentElement.setAttribute("dir", dir)   else documentElement.removeAttribute("dir")
}
```
`class` and `data-theme` on `<html>` are **never copied from the new snapshot**, and morphing morphs `<body>`, not `<html>`. So:

- A client-side theme flip **survives** every Drive visit and every morph. Good.
- But it also means the server's `data-theme` on the *incoming* page is ignored. If the user changes the theme in another tab and you navigate here, the DOM wins over the server. Harmless.
- And it means your **toggle's own UI must re-sync from the DOM on `connect()`** — a fresh controller instance per visit, reading `document.documentElement.dataset.theme`, exactly as above. The bug you get otherwise: the toggle shows "System" on every navigation while the page is visibly dark.

**Support, verified 2026-08-15** ([webstatus.dev](https://webstatus.dev/)): `color-scheme` is **Baseline widely available** (since 2022-02); `light-dark()` is **Baseline newly available since 2024-05-13** — Chrome 123, Firefox 120, Safari 17.5. Two years of support across all engines as of now. Ship it. If you must support older Safari, wrap in `@supports (color: light-dark(#000, #fff))` and keep a `prefers-color-scheme` block as fallback.

**Decomposition.** `persist` (localStorage fallback) + `sync` (mirror the choice into a `<select>` elsewhere) + `roving-focus` (radiogroup keyboard). The theme controller itself is thin enough to be a named app controller rather than a primitive.

**A11y.** [APG Radio Group pattern](https://www.w3.org/WAI/ARIA/apg/patterns/radio/) for the three-state switch: `role="radiogroup"` with an accessible name, `role="radio"` + `aria-checked` per option, roving tabindex, Arrow keys move and select, Space selects. A two-state toggle should instead be `<button aria-pressed>` or a checkbox — **not** a `role="switch"` with a hidden label. Never announce the theme change via a live region on every click; it's visible. Ensure both palettes independently meet 4.5:1 contrast — a dark palette derived by inverting a light one almost never does.

**Native.** Hotwire Native web views inherit the system appearance, and the native chrome (navigation bar, tab bar) follows `UIUserInterfaceStyle` / `AppCompatDelegate`, not your cookie. So a web-only theme toggle produces a light nav bar over a dark page. Two options: (1) hide the web toggle in native (`body[data-hotwire-native] .theme-switch { display: none }`) and let the OS drive both — the right default; or (2) build a `bridge--theme` component that pushes the choice to the native side. See [04-hotwire-native §3.6, §4.3](#).

**Pitfalls.**
- `<meta name="color-scheme">` and the CSS `color-scheme` property are different mechanisms; you want the CSS property for the toggle (it cascades and can be overridden per-element) and the meta tag only to color the browser UI before CSS loads.
- Setting `color-scheme: dark` on `<html>` changes the **default canvas color to black** before your `background` applies. That's a feature (no white flash) but surprises people debugging.
- Images and SVG logos need a companion: `<picture>` with `media="(prefers-color-scheme: dark)"` follows the *OS*, not your `data-theme` override. For a manual override you need two `<img>`s toggled by CSS, or a `currentColor` SVG.
- Don't put the theme class on `<body>` — Turbo replaces `<body>`, so it will be reset by the server's value on every visit. `<html>` is the correct home precisely because Turbo leaves it alone.
- Three-state means "system" is a real value, not the absence of a value. `cookies[:theme] == nil` and `"system"` must behave identically; don't let `nil` fall through to `"light"`.
- Emitting `dark:` Tailwind variants alongside a cookie-rendered class works, but doubles your fragment-cache key space. Tokens don't.

**Prior art.**
- [MDN — `light-dark()`](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/light-dark) · [MDN — `color-scheme`](https://developer.mozilla.org/en-US/docs/Web/CSS/color-scheme)
- [betterstimulus.com — Dark Mode recipe](https://www.betterstimulus.com/) — the `dark-mode` + `radio-dropdown` controller pair that communicate only through `data-action`, no imports. The best structural idea on that site; note the site's last substantive content commit was Feb 2025.
- [Rails Designer — components](https://railsdesigner.com/)

---

### Click-outside

**Cross-reference only.** The `click-outside` primitive is owned by the **Overlays** section — see the dismissal/popover records there. Everything in this section that needs it (mobile drawer, theme menu) composes it via `dismiss`.

---

### i18n in Stimulus

**Hotwire answer.** **Don't ship translations to JavaScript.** Render translated strings into `data-*` values from ERB and read them as Stimulus Values. Where the string genuinely depends on runtime numbers or times, use the `Intl.*` APIs, which are built in, correct, locale-aware, and free. Reach for the `i18n-js` dictionary only when you have a real client-side rendering surface — which in a Hotwire app you mostly don't.

**The pattern.**

```erb
<%# app/views/tickets/_form.html.erb %>
<form data-controller="dirty-form"
      data-dirty-form-warning-value="<%= t(".unsaved_warning") %>"
      data-dirty-form-saving-value="<%= t(".saving") %>">
  …
</form>
```

```js
export default class extends Controller {
  static values = { warning: String, saving: String }

  beforeUnload(event) {
    if (!this.dirty) return
    event.preventDefault()
    event.returnValue = this.warningValue   // already translated, by Rails, server-side
  }
}
```

Why this is right and not a compromise:
- Rails' I18n backend is the single source of truth. No export step, no drift, no second locale-fallback implementation.
- Zero bytes shipped for locales the user isn't using.
- `t(".key")` lazy lookup keeps translations next to the view that uses them.
- Works with fragment caching as long as the locale is in the cache key (`cache [I18n.locale, ticket]`).
- Under morphing, a re-rendered element brings its updated `data-*` values with it, so a locale switch propagates automatically.

For a set of strings, pass an Object value rather than a fistful of attributes:

```erb
<div data-controller="upload"
     data-upload-messages-value="<%= {
       queued: t(".queued"), uploading: t(".uploading"),
       failed: t(".failed"), done: t(".done")
     }.to_json %>">
```
```js
static values = { messages: Object }
// this.messagesValue.uploading
```

**The exceptions, and what to use instead of a dictionary.**

| Case | Answer |
|---|---|
| Relative timestamps ("3 minutes ago") | `Intl.RelativeTimeFormat` — or better, `<relative-time>` (next record), which uses it internally |
| A live counter with pluralization ("1 file" / "3 files") | `Intl.PluralRules` + a small per-category map rendered from ERB |
| Formatting a number the user just typed | `Intl.NumberFormat(locale, { style: "currency", currency })` |
| Formatting a date the client computed | `Intl.DateTimeFormat(locale, { dateStyle, timeStyle, timeZone })` |
| Full client-side view rendering | you don't have one; if you do, `i18n-js` |

Pluralization done correctly, with the plural *forms* still coming from Rails:

```erb
<output data-controller="char-count"
        data-char-count-locale-value="<%= I18n.locale %>"
        data-char-count-forms-value="<%= {
          zero:  t(".chars.zero",  default: ""),
          one:   t(".chars.one"),
          two:   t(".chars.two",   default: ""),
          few:   t(".chars.few",   default: ""),
          many:  t(".chars.many",  default: ""),
          other: t(".chars.other")
        }.compact_blank.to_json %>"></output>
```

```js
static values = { locale: String, forms: Object }

connect() {
  this.rules = new Intl.PluralRules(this.localeValue)
}

label(count) {
  const category = this.rules.select(count)          // "one" | "few" | "many" | "other" | …
  const template = this.formsValue[category] ?? this.formsValue.other
  return template.replace("%{count}", new Intl.NumberFormat(this.localeValue).format(count))
}
```

`Intl.PluralRules` knows that Russian has `one/few/many/other` and Arabic has six categories; your `count === 1 ? "file" : "files"` does not. This is the one place where the JS API is *more* correct than a naive Rails-side approach — but note the *strings* still come from `config/locales/*.yml`, which is the point.

Set the locale once, globally, rather than threading it through every controller:

```erb
<html lang="<%= I18n.locale %>">
```
```js
const locale = document.documentElement.lang || navigator.language
```

**When you actually need the dictionary client-side.** [`i18n-js`](https://github.com/fnando/i18n-js) — Ruby gem **4.2.4** (2025-10-31) exports Rails translations to JSON per `config/i18n.yml` via `bin/rails i18n export`; the npm runtime is a separate package, [`i18n-js`](https://github.com/fnando/i18n) **4.5.3** (2026-03-04), which does interpolation and pluralization against that JSON. It's the de facto pairing and still maintained; there is no clearly superior 2026 alternative. Use it if you have a genuinely client-rendered surface (a canvas app, a rich editor). Do not use it to translate three button labels.

**Decomposition.** None — this is a convention that every primitive follows. Every controller in this catalog that displays text takes it as a Value.

**A11y.** Set `lang` on `<html>` (and on any element whose content is in another language) — screen readers switch voice/pronunciation from it, and `Intl` locale detection reads it. For RTL locales set `dir="rtl"`; note Turbo *does* copy `dir` and `lang` from the incoming snapshot onto `<html>` (`PageRenderer#setLanguage`), so a locale switch that changes direction propagates across Drive visits correctly. Use CSS logical properties (`margin-inline-start`, `inset-block-start`) throughout so RTL needs no separate stylesheet.

**Native.** The web view inherits the app's locale via `Accept-Language`; Rails' `I18n.locale` set from that header covers both surfaces. Bridge components receive already-translated strings in their message payloads — never translate on the Swift/Kotlin side from a key, or you'll maintain two catalogs. See [04-hotwire-native §3.4](#).

**Pitfalls.**
- `t()` output in a `data-*` attribute is HTML-escaped by ERB, which is correct — but if your translation contains `&` or quotes, `JSON.parse` of an Object value handles it and manual string splitting does not. Use Object values for anything non-trivial.
- Don't put translations in `<script type="application/json">` "just for JS" — it's the same bytes with worse ergonomics than a data attribute.
- `Intl.RelativeTimeFormat` needs you to pick the unit yourself; it does not do "pick the largest sensible unit". That's why `<relative-time>` exists.
- Locale must be in every fragment cache key. `cache [I18n.locale, record]`, always.

**Prior art.**
- [Rails Guides — I18n](https://guides.rubyonrails.org/i18n.html)
- [i18n-js gem](https://github.com/fnando/i18n-js) 4.2.4 · [i18n-js npm runtime](https://github.com/fnando/i18n) 4.5.3
- [MDN — `Intl.PluralRules`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/PluralRules)

---

### Lazy images

**Hotwire answer.** Four HTML attributes. **No JS needed** — and specifically, no `lazysizes`, no `IntersectionObserver` controller, no `content-loader`.

**Code.**

```erb
<%# Below the fold: lazy + async decode + explicit dimensions (CLS) %>
<%= image_tag post.cover.variant(:card),
      alt: post.cover_alt,
      width: 640, height: 360,
      loading: "lazy", decoding: "async",
      srcset: {
        post.cover.variant(:card)   => "640w",
        post.cover.variant(:card2x) => "1280w"
      },
      sizes: "(min-width: 60rem) 40rem, 100vw" %>

<%# The LCP image: NEVER lazy. Eager + high priority. %>
<%= image_tag @post.cover.variant(:hero),
      alt: @post.cover_alt,
      width: 1200, height: 630,
      loading: "eager", decoding: "async", fetchpriority: "high" %>
```

```css
img { max-inline-size: 100%; block-size: auto }
/* When you can't emit width/height (user content), reserve the box: */
.media { aspect-ratio: 16 / 9; background: var(--surface) }
.media > img { inline-size: 100%; block-size: 100%; object-fit: cover }
```

Active Storage: define named variants on the model so the ERB stays clean and the variants are pre-processed.

```ruby
class Post < ApplicationRecord
  has_one_attached :cover do |a|
    a.variant :card,   resize_to_limit: [640, 360],   format: :webp, preprocessed: true
    a.variant :card2x, resize_to_limit: [1280, 720],  format: :webp, preprocessed: true
    a.variant :hero,   resize_to_limit: [1200, 630],  format: :webp, preprocessed: true
  end
end
```

`preprocessed: true` matters: without it the first request to a variant is a redirect to a URL that then generates the image, which is slow exactly when the LCP measurement is taken.

**Support, 2026:** `loading="lazy"` and `decoding="async"` are universal. `fetchpriority` is **Baseline newly available since 2024-10** — Chrome 103, Safari 17.2, Firefox 132 — and degrades to "ignored" everywhere else, so there is no reason not to use it. `aspect-ratio` is **Baseline widely available**.

**Decomposition.** None.

**A11y.** `alt` is not optional. Decorative images get `alt=""` (empty, present) so AT skips them; informative images get a description of what the image *conveys*, not a filename. Never `alt` on a `<img>` inside a link that already has text — that produces a double announcement; use `alt=""` there.

**Native.** Same. Note that a native web view may load images before the screen is visible; `loading="lazy"` still gates on intersection with the web view's viewport, which is correct.

**Pitfalls.**
- `loading="lazy"` on your LCP image is a **performance regression**, not an optimization. Never lazy-load anything in the initial viewport.
- Missing `width`/`height` (or `aspect-ratio`) means every lazy image shifts the layout as it arrives. This is the CLS in most Rails apps.
- `srcset` without `sizes` makes the browser assume `100vw` and download a needlessly large file.
- `image_tag` with an Active Storage variant emits a redirect URL by default; that's an extra round trip per image. Use `preprocessed: true` and consider a CDN in front of `/rails/active_storage`.
- Lazy images inside a `<turbo-frame loading="lazy">` are doubly deferred — fine, but don't be surprised when nothing loads until the frame is scrolled into view.

**Prior art.** [Rails Guides — Active Storage variants](https://guides.rubyonrails.org/active_storage_overview.html#transforming-images) · [web.dev — Browser-level lazy loading](https://web.dev/articles/browser-level-image-lazy-loading) · [MDN — `fetchPriority`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/fetchPriority)

---

### Video players

**Hotwire answer.** Native `<video controls>` first — it's accessible, it does picture-in-picture, AirPlay and captions for free, and it costs zero bytes. Reach for a library only when you need HLS on non-Safari (`hls.js`) or a custom skin. Wrap it in a Stimulus controller with a real `disconnect()` teardown, and mark the page `no-preview` so the Turbo cache never shows a frozen frame.

**Code.**

```erb
<div data-controller="video"
     data-video-src-value="<%= @clip.hls_url %>"
     data-video-poster-value="<%= url_for(@clip.poster) %>">
  <video data-video-target="player"
         controls playsinline preload="metadata"
         poster="<%= url_for(@clip.poster) %>"
         width="1280" height="720"
         style="aspect-ratio: 16 / 9; inline-size: 100%; block-size: auto">
    <track kind="captions" srclang="en" label="English"
           src="<%= @clip.captions_url %>" default>
    Your browser doesn't support video. <%= link_to "Download", @clip.file_url %>
  </video>
</div>
```

```js
// app/javascript/controllers/video_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["player"]
  static values = { src: String }

  async connect() {
    const video = this.playerTarget
    // Safari plays HLS natively; everyone else needs hls.js.
    if (video.canPlayType("application/vnd.apple.mpegurl")) {
      video.src = this.srcValue
      return
    }
    const { default: Hls } = await import("hls.js")
    if (!Hls.isSupported()) return
    this.hls = new Hls({ enableWorker: true })
    this.hls.loadSource(this.srcValue)
    this.hls.attachMedia(video)
  }

  disconnect() {
    this.playerTarget.pause()
    this.hls?.destroy()          // #1 leak if you skip this
    this.hls = null
  }
}
```

**The Turbo cache problem.** A page snapshot is a `cloneNode` of the DOM at `turbo:before-cache`. For video this produces two distinct bugs: (a) the cached preview shows the video **paused mid-playback with a stale frame** and no controls state; (b) with a library player, the clone contains the player's generated DOM *and* your `connect()` runs again on the restored preview, producing **two players** stacked. Fixes, in order:

```erb
<%# On any page with a real player: cache it but never show it stale. %>
<% turbo_exempts_page_from_preview %>
```
```js
// And tear down idempotently — disconnect() already does most of this.
document.addEventListener("turbo:before-cache", () => {
  document.querySelectorAll("video").forEach((v) => { v.pause(); v.removeAttribute("autoplay") })
})
```
For a player that must keep playing across navigation (a podcast bar), that's the `data-turbo-permanent` case — same `id`, present in every layout, and accept that its contents never update from the server.

> `data-turbo-cache="false"` is **removed** as of Turbo 8.0.21; if a video tutorial tells you to add it, the tutorial predates Nov 2025. Use `data-turbo-temporary` (removes the node) or `turbo_exempts_page_from_preview` (keeps the page cached but never previews it).

**Decomposition.** A `video` app controller (not a shared primitive — the lifecycle is too media-specific). Composes with `intersection` for pause-when-offscreen.

**A11y.** `controls` on the native element gives a fully keyboard-accessible, screen-reader-labelled player. Always ship a `<track kind="captions">`. If you replace the controls with a custom skin you inherit the entire [APG media player burden](https://www.w3.org/WAI/ARIA/apg/) — that alone is a reason to stay native. Never `autoplay` with sound; `autoplay muted playsinline` for background video only, and honour `prefers-reduced-motion` by not autoplaying at all.

**Native.** iOS requires `playsinline` or video goes fullscreen. Consider a native player screen via path configuration for anything long-form — see [04-hotwire-native §7.1–7.2](#).

**Library status, verified 2026-08-15:**
- [video.js](https://github.com/videojs/video.js) **8.24.0** (2026-08-03) — very active, big plugin ecosystem. **The 2026 pick** if you need a library.
- [hls.js](https://github.com/video-dev/hls.js) **1.7.0** (2026-08-12) — very active; the HLS engine everything else uses.
- [Plyr](https://github.com/sampotts/plyr) **3.8.4** (2026-01-03) — active but slow, ~940 open issues.
- [Vidstack](https://vidstack.io/) — **caveat**: the npm `latest` dist-tag is stuck at **0.6.15 (2024-04-19)** while the real line is **1.15.6 published only under `next`** (2026-06-10). Nicer API, confusing distribution. Check the docs for the exact install command; don't `npm install vidstack` and assume you got 1.x.

**Pitfalls.**
- Forgetting `hls.destroy()` in `disconnect()` leaks a MediaSource and a worker per navigation. It is the most common Stimulus memory leak in the wild.
- `preload="auto"` on a list of videos will happily download hundreds of MB. `metadata` or `none`.
- Morphing will prune a library player's generated DOM. `data-turbo-permanent` on the container, or cancel `turbo:before-morph-element` for it — see [02-turbo-deep-dive §5](#).
- No `width`/`height`/`aspect-ratio` on `<video>` → CLS, same as images.

**Prior art.** [MDN — `<video>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/video) · [hls.js](https://github.com/video-dev/hls.js) · [video.js](https://videojs.com/)

---

### Maps

**Hotwire answer.** [MapLibre GL JS](https://maplibre.org/) (vector, BSD-licensed) or [Leaflet](https://leafletjs.com/) (raster, tiny, boring in the good way) inside a Stimulus controller. The entire discipline is lifecycle: initialise in `connect()`, **`map.remove()` in `disconnect()`**, take markers from a Stimulus Value, and rebuild markers in the value-changed callback so Turbo Stream replacements just work.

**Code.**

```erb
<%# app/views/venues/index.html.erb %>
<div id="venues_map"
     data-controller="map"
     data-map-provider-value="maplibre"
     data-map-style-value="<%= Rails.configuration.x.map_style_url %>"
     data-map-center-value="<%= [ -0.1276, 51.5072 ].to_json %>"
     data-map-zoom-value="11"
     data-map-markers-value="<%= @venues.map { |v|
        { id: v.id, lng: v.longitude.to_f, lat: v.latitude.to_f,
          title: v.name, url: venue_path(v) }
     }.to_json %>"
     style="block-size: 60vh; inline-size: 100%"
     role="application"
     aria-label="Map of venues">
</div>

<%# The accessible equivalent — NOT optional. %>
<ul class="visually-hidden-on-desktop">
  <% @venues.each do |venue| %>
    <li><%= link_to venue.name, venue_path(venue) %> — <%= venue.address %></li>
  <% end %>
</ul>
```

```js
// app/javascript/controllers/map_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    style:   String,
    center:  Array,
    zoom:    { type: Number, default: 12 },
    markers: { type: Array, default: [] }
  }

  async connect() {
    const { Map, Marker, Popup, NavigationControl } = await import("maplibre-gl")
    this.lib = { Marker, Popup }

    this.map = new Map({
      container: this.element,
      style: this.styleValue,
      center: this.centerValue,
      zoom: this.zoomValue
    })
    this.map.addControl(new NavigationControl(), "top-right")

    this.markers = []
    this.map.on("load", () => this.#renderMarkers())
  }

  disconnect() {
    // THE #1 LEAK. Without this every Turbo visit leaks a WebGL context,
    // and browsers hard-cap those (~16) — the map silently stops rendering.
    this.markers?.forEach((m) => m.remove())
    this.markers = null
    this.map?.remove()
    this.map = null
  }

  // Fires when a Turbo Stream / morph rewrites data-map-markers-value.
  markersValueChanged() {
    if (this.map?.loaded()) this.#renderMarkers()
  }

  #renderMarkers() {
    const { Marker, Popup } = this.lib
    this.markers.forEach((m) => m.remove())
    this.markers = this.markersValue.map(({ lng, lat, title, url }) => {
      const popup = new Popup({ offset: 24 })
        .setHTML(`<a href="${url}">${escapeHtml(title)}</a>`)
      return new Marker().setLngLat([lng, lat]).setPopup(popup).addTo(this.map)
    })
  }
}

function escapeHtml(s) {
  return s.replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]))
}
```

The `markersValueChanged` callback is what makes this Turbo-native: a `turbo_stream.replace "venues_map", partial: …` rewrites the `data-map-markers-value` attribute, Stimulus fires the callback, markers rebuild. No custom event plumbing.

> **In-place mutation does not fire the callback.** `this.markersValue.push(x)` is a no-op as far as Stimulus is concerned — Values are compared by reassignment, not by deep watching. Always `this.markersValue = [...this.markersValue, x]`. (This exact bug is one of the published-but-broken examples on betterstimulus.com; see [03-stimulus-deep-dive](#).)

**Morphing.** Idiomorph sees the map library's generated `<canvas>` and control DOM as "unexpected children" and **prunes them**. Two fixes:

```erb
<div id="venues_map" data-turbo-permanent data-controller="map" …>
```
or cancel the morph for that subtree:
```js
document.addEventListener("turbo:before-morph-element", (e) => {
  if (e.target.matches("[data-controller~=map]")) e.preventDefault()
})
```
Prefer the second: `data-turbo-permanent` stops the *markers value* updating too, which defeats the point of `markersValueChanged`. See [02-turbo-deep-dive §5](#).

**A map that must survive navigation** (a persistent map with a changing sidebar) is the legitimate `data-turbo-permanent` case: same `id` in every layout that shows it, and drive its content exclusively with Turbo Streams — remembering that Streams *do* honour permanence, so target a child element, not the permanent container itself.

**Decomposition.** `map` is not on the shared primitive list and shouldn't be — it's a library wrapper with a specific lifecycle, like `chart`. It composes with `intersection` (defer `connect()` until visible) and `persist` (remember the last viewport).

**A11y.** An interactive map is not accessible, full stop. `role="application"` + `aria-label` is the minimum, but the real requirement is the **parallel text list of the same data**, linked and keyboard-reachable, as in the ERB above. Keep it in the DOM (visually hidden on desktop if you must), don't `display: none` it. MapLibre and Leaflet both give keyboard pan/zoom on the container; ensure it isn't in the tab order ahead of the page's real content, and never trap scroll — disable scroll-wheel zoom until the map is clicked (`scrollZoom: false` then enable on `click`), or a user scrolling the page gets hijacked.

**Native.** A full-screen map is the archetypal **native screen** — register a path-configuration rule and hand it to MapKit/Google Maps. See [04-hotwire-native §7.1–7.3](#) (progressive rollout: ship the web map, replace it natively later without changing the URL). If the map is a small inline widget, keep it web.

**Library status, 2026-08-15:**
- [MapLibre GL JS](https://github.com/maplibre/maplibre-gl-js) **6.3.0** (2026-08-10) — active, BSD-3-Clause, vector tiles. **Default pick.**
- [Leaflet](https://github.com/Leaflet/Leaflet) **1.9.4** (2023-05-18) — unchanged three years but not abandoned (repo pushed 2026-08-10); `2.0.0-alpha.1` in progress. Pick it for simple raster maps where 40KB matters.
- **Mapbox GL JS** **3.28.1** — **v2.0+ is proprietary under the Mapbox ToS**, not open source. v1.13 was the last BSD build, and MapLibre is its fork. Only use Mapbox if you're paying for their tiles anyway.
- Google Maps JS API — fine, but a `<script>` you can't bundle and a per-load bill.
- [mapkick-rb](https://github.com/ankane/mapkick) **0.3.0** (2026-04-15) — Ankane's chartkick-style Ruby helper over Leaflet/Mapbox/Google. Nice for a quick map, opaque when you need control.
- `leaflet-rails` **1.9.5** — just vendors the asset; redundant now that importmap/jsbundling pull `leaflet` from npm directly.

**Pitfalls.**
- **No `map.remove()` in `disconnect()`** → leaked WebGL contexts. Browsers cap them; after ~16 navigations the map goes blank with a console warning most people never see. This is the single most common bug in Stimulus map controllers.
- A map initialised inside a `display: none` container renders at 0×0. Call `map.resize()` (MapLibre) / `map.invalidateSize()` (Leaflet) when the container becomes visible — e.g. on `turbo:frame-load` or a `dialog` open event.
- Turbo's snapshot cache clones the map's canvas as a dead image; combine with `turbo_exempts_page_from_preview` or accept a frozen map on Back.
- Marker popups containing user content are an XSS vector — `setHTML` does no escaping. Escape, or use `setText`.
- `import("maplibre-gl")` dynamically so the ~800KB bundle isn't on every page.

**Prior art.** [MapLibre GL JS docs](https://maplibre.org/maplibre-gl-js/docs/) · [Leaflet](https://leafletjs.com/) · [mapkick-rb](https://github.com/ankane/mapkick)

---

### Print views

**Hotwire answer.** A `@media print` block in your stylesheet, plus a two-line controller for a "Print" button. **No JS beyond `window.print()`.** For a document that genuinely differs from the screen version — an invoice, a packing slip — render a server-side `?print=1` layout variant instead of fighting CSS. For a real downloadable PDF, generate it server-side.

**Code.**

```css
@media print {
  nav, aside, footer, .site-header, .no-print,
  [data-controller~="dialog"], turbo-frame[loading="lazy"] { display: none !important }

  :root { color-scheme: light }            /* never print a dark theme */
  body  { background: #fff; color: #000; font-size: 11pt }

  a[href^="http"]::after { content: " (" attr(href) ")"; font-size: 9pt; color: #555 }
  table { break-inside: auto }
  tr, img, figure { break-inside: avoid }
  thead { display: table-header-group }    /* repeat headers across pages */
  h2, h3 { break-after: avoid }
}
@page { margin: 18mm 14mm }
```

```js
// app/javascript/controllers/print_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  print() { window.print() }
}
```
```erb
<button type="button" data-controller="print" data-action="print#print" class="no-print">
  Print
</button>
```

The server-side variant, for anything with a genuinely different structure:

```ruby
# app/controllers/invoices_controller.rb
def show
  @invoice = Invoice.find(params[:id])
  render layout: params[:print] ? "print" : "application"
end
```
```erb
<%= link_to "Printable version", invoice_path(@invoice, print: 1),
      data: { turbo: false }, target: "_blank", rel: "noopener" %>
```
`data-turbo="false"` because you want a real document load, not a Drive visit into a different layout.

**Decomposition.** None worth naming; a one-method `print` controller is fine as an app controller.

**A11y.** Print styles are an accessibility feature for users who read on paper. Don't hide content that carries meaning; expand abbreviations and reveal link URLs (as above). Ensure the print stylesheet doesn't drop `alt` text substitutes for images that don't print.

**Native.** No print in a mobile web view worth shipping. Hide the button: `body[data-hotwire-native] .print-button { display: none }`. If a native "Share → Print" is required, that's a bridge component invoking the native share sheet — see [04-hotwire-native §Bridge Component Catalog](#).

**Real PDFs (2026 status, verified).**
- [grover](https://github.com/Studiosity/grover) **1.2.10** (2026-04-02) — headless Chrome via Puppeteer. **The default pick.**
- [ferrum](https://github.com/rubycdp/ferrum) **0.17.2** (2026-03-23) — pure-Ruby Chrome DevTools Protocol driver, **no Node dependency**. Pick this if adding Node to your deploy is unacceptable.
- [wicked_pdf](https://github.com/mileszs/wicked_pdf) **2.8.2** — the gem is maintained, but it wraps **wkhtmltopdf, which is archived** (GitHub archived, last push 2022-11-22, unpatched Qt/WebKit CVEs). **Do not start a new project on it.** The README carries no deprecation warning, which is how people keep choosing it.
- [prawn](https://github.com/prawnpdf/prawn) **2.5.0** — not HTML→PDF at all; a native Ruby drawing API. Right answer for pixel-exact invoices and statements, wrong answer for "print this page".

**Pitfalls.**
- `display: none` on a `<turbo-frame loading="lazy">` in print CSS doesn't stop it loading, it just hides it — the user prints a page with a hole. Load frames eagerly on printable pages.
- Chrome's print preview ignores `background-color` unless the user enables backgrounds; use borders and text weight, not fills, to convey structure.
- `break-inside: avoid` on a container taller than a page silently does nothing.
- Printing a page that's inside a modal prints the whole document behind it. Print from a dedicated URL instead.

**Prior art.** [MDN — `@media print`](https://developer.mozilla.org/en-US/docs/Web/CSS/@media) · [grover](https://github.com/Studiosity/grover) · [ferrum](https://ferrum.rubycdp.com/)

---

### Countdown timers

**Hotwire answer.** A `countdown` Stimulus controller reading an **ISO8601 timestamp** (never a duration) from a data attribute, ticking with `setInterval` at the display granularity, and clearing on `disconnect()`.

**Send a timestamp, not a duration.** `data-countdown-seconds-value="300"` is wrong: the page may have been server-rendered 40 seconds ago, cached by Turbo for a minute, or restored from a snapshot ten minutes later. `data-countdown-deadline-value="2026-08-15T18:30:00Z"` is an absolute fact both sides agree on. Client clock skew shifts everyone's countdown identically rather than compounding, and a Turbo restore recomputes the right number automatically.

**Code.**

```erb
<div data-controller="countdown"
     data-countdown-deadline-value="<%= @auction.ends_at.utc.iso8601 %>"
     data-countdown-expired-class="countdown--expired"
     data-action="countdown:expired->form#disable">
  <time datetime="<%= @auction.ends_at.utc.iso8601 %>"
        data-countdown-target="output"
        role="timer" aria-live="off">
    <%= distance_of_time_in_words_to_now(@auction.ends_at) %>
  </time>
</div>
```

```js
// app/javascript/controllers/countdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]
  static classes = ["expired"]
  static values = {
    deadline: String,                              // ISO8601, UTC
    interval: { type: Number, default: 1000 }
  }

  connect() {
    this.deadline = Date.parse(this.deadlineValue)
    this.#tick()
    this.timer = setInterval(() => this.#tick(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)                      // mandatory: Turbo caching re-connects
    this.timer = null
  }

  #tick() {
    const remaining = this.deadline - Date.now()
    if (remaining <= 0) {
      this.outputTarget.textContent = "Ended"
      this.element.classList.add(...this.expiredClasses)
      this.dispatch("expired")
      clearInterval(this.timer)
      return
    }
    this.outputTarget.textContent = format(remaining)
  }
}

function format(ms) {
  const total = Math.floor(ms / 1000)
  const h = Math.floor(total / 3600)
  const m = Math.floor((total % 3600) / 60)
  const s = total % 60
  const pad = (n) => String(n).padStart(2, "0")
  return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${m}:${pad(s)}`
}
```

**`setInterval` vs `requestAnimationFrame`.** Use `setInterval` at the granularity you display. `rAF` runs 60×/second to update a string that changes once a second — pure waste, and it stops in background tabs (which is fine here, since a countdown that pauses when hidden is wrong). `rAF` is only correct for a countdown with a **sub-second animated progress ring**; even then, drive the ring with a CSS animation and keep the text on `setInterval`. Note browsers throttle `setInterval` to ~1/s in background tabs — harmless, because `#tick` recomputes from the deadline rather than decrementing a counter. That's the second reason for absolute timestamps.

**Decomposition.** `countdown`. Composes with `transition` (flash at the last 10s) and `timeout` (fire an action at zero, if you don't need the ticking display).

**A11y.** `role="timer"` on the output. Set `aria-live="off"` — a live region that updates every second is a screen-reader denial-of-service. Announce only the *milestones*: switch to `aria-live="assertive"` in the last 30 seconds, or better, put milestone announcements in a separate `role="status"` region ("1 minute remaining"). The `<time datetime>` attribute gives AT the absolute deadline regardless of what the visible text says.

**Native.** n/a for the web countdown. A countdown that must fire while the app is backgrounded is a native local notification, not a web timer.

**Pitfalls.**
- Not clearing the interval in `disconnect()`: Turbo caches the page, `connect()` runs again on Back, and now two intervals fight over the same element.
- `new Date("2026-08-15 18:30:00")` (space, no `T`, no zone) parses inconsistently across engines. Always `iso8601` from Rails, always UTC, always with the `Z`.
- Server-render a sensible initial value (`distance_of_time_in_words_to_now`) so the element isn't blank before JS runs — and so it's still meaningful if JS never runs.
- Under morphing, if the server re-renders the `<time>` text your tick will be overwritten on the next refresh. Put the ticking text in a child the server renders as empty, or exclude it via `turbo:before-morph-element`.

**Prior art.** [@stimulus-components/timeago](https://www.stimulus-components.com/docs/components/timeago) (counts up, not down, but same shape) · [stimulus-use `useIntersection`](https://stimulus-use.github.io/stimulus-use/) to pause offscreen countdowns

---

### Self-updating relative timestamps

**Hotwire answer.** **Use a web component, not a Stimulus controller.** Ship [`@github/relative-time-element`](https://github.com/github/relative-time-element) — `<relative-time datetime="...">`. Because it's a custom element, its lifecycle is owned by the browser: it works after a Turbo Stream append, after a frame swap, after a morph, inside a cached snapshot, with **zero lifecycle code from you**. A Stimulus controller doing the same job needs `connect`/`disconnect` discipline and still can't beat "it just works".

This is the flagship record for the general rule: **when the behaviour belongs to a single element and needs no coordination, a custom element beats a controller.** Stimulus is for wiring elements together; `relative-time` wires nothing.

**Code — what to ship.**

```erb
<%# app/helpers/application_helper.rb %>
<%= relative_time(comment.created_at) %>
```
```ruby
def relative_time(time, **options)
  tag.relative_time(
    time.strftime("%B %-d, %Y at %-l:%M %p"),   # server-rendered fallback text
    datetime: time.utc.iso8601,                 # ALWAYS UTC ISO8601
    **options
  )
end
```
Renders:
```html
<relative-time datetime="2026-08-15T14:22:07Z">August 15, 2026 at 2:22 PM</relative-time>
```
```js
// app/javascript/application.js
import "@github/relative-time-element"
```

The element's inner text is the **server-rendered fallback**: it's what's shown before the script loads, what search engines index, and what a no-JS client sees. The element replaces it once upgraded. Never render an empty `<relative-time>`.

**The real attribute surface** (verified against `src/relative-time-element.ts`, v5.3.1, 2026-08-03):

| Attribute | Values | Default |
|---|---|---|
| `datetime` | ISO8601 (required) | — |
| `format` | `relative` \| `datetime` \| `duration` \| `micro` (deprecated aliases: `auto`→`relative`, `elapsed`→`duration`) | `auto` (= `relative`) |
| `tense` | `auto` \| `past` \| `future` | `auto` |
| `precision` | a unit name (`second`, `minute`, …) | `second` (`minute` when `format="micro"`) |
| `threshold` | ISO8601 duration — when to switch from relative to absolute | `P30D` |
| `prefix` | string (**`@deprecated` in source**, still functional) | `"on"` (`""` when `format="datetime"`) |
| `no-title` | boolean — suppress the title tooltip | absent |
| `lang`, `time-zone`, `time-zone-name`, `hour-cycle`, `format-style` | Intl passthrough | — |
| `second`/`minute`/`hour`/`weekday`/`day`/`month`/`year` | Intl passthrough | — |

It **self-updates**: each instance schedules its own `setTimeout`, recomputed and re-lengthened as the timestamp ages (seconds → minutes → hours), rather than a shared global ticker. After `threshold` it stops and shows the absolute date. This is strictly better than a 60-second global interval.

**The Stimulus alternative, for comparison — and why not to ship it.**

```erb
<time data-controller="relative-time"
      data-relative-time-datetime-value="<%= comment.created_at.utc.iso8601 %>"
      datetime="<%= comment.created_at.utc.iso8601 %>">
  <%= time_ago_in_words(comment.created_at) %> ago
</time>
```
```js
import { Controller } from "@hotwired/stimulus"

const UNITS = [["year",31536e3],["month",2592e3],["week",6048e2],["day",864e2],
               ["hour",36e2],["minute",60],["second",1]]

export default class extends Controller {
  static values = { datetime: String, refresh: { type: Number, default: 60000 } }

  connect() {
    this.rtf = new Intl.RelativeTimeFormat(document.documentElement.lang || "en",
                                           { numeric: "auto" })
    this.render()
    this.timer = setInterval(() => this.render(), this.refreshValue)
  }
  disconnect() { clearInterval(this.timer) }

  render() {
    const delta = (Date.parse(this.datetimeValue) - Date.now()) / 1000
    const [unit, secs] = UNITS.find(([, s]) => Math.abs(delta) >= s) || ["second", 1]
    this.element.textContent = this.rtf.format(Math.round(delta / secs), unit)
  }
}
```
It works. It is also ~25 lines you now maintain, it ticks every element on a fixed interval regardless of age, it needs the interval cleared on `disconnect()` (and Turbo will re-`connect()` it on every Back), and after a Turbo Stream append the controller connects fine but you've re-implemented what a custom element gives free. **Ship `<relative-time>`.**

`time_ago_in_words` alone (no JS) is the third option and it's underrated: on a page the user reads for 30 seconds, "2 minutes ago" not becoming "3 minutes ago" harms nobody. Ship plain `time_ago_in_words` for anything that isn't a live feed.

**The server-render + timezone problem.** There is exactly one correct division of labour:

- **Server renders the instant**, always as `datetime="<%= t.utc.iso8601 %>"` — UTC, unambiguous, cacheable across all users and all timezones.
- **Client formats it**, in the viewer's timezone and locale, via `Intl`.

Rendering a *localized* time server-side means either (a) you don't know the user's timezone so you show your server's, which is wrong, or (b) you store a per-user timezone and now every fragment cache key needs a timezone dimension. Rendering UTC ISO8601 into `datetime` and letting the element format it makes the HTML **timezone-independent and therefore cacheable**. That is the real argument, and it applies to `<relative-time>`, to `Intl.DateTimeFormat`, and to any absolute timestamp you display.

```erb
<%# Absolute timestamps get the same treatment %>
<relative-time datetime="<%= @order.placed_at.utc.iso8601 %>"
               format="datetime" month="long" day="numeric" year="numeric"
               hour="numeric" minute="numeric">
  <%= l @order.placed_at, format: :long %>
</relative-time>
```

**Decomposition.** `relative-time` — but implemented as a custom element, not a Stimulus controller. Keep the name in the vocabulary; note the implementation choice.

**A11y.** Always a `<time datetime>` or `<relative-time datetime>` — the machine-readable attribute is what AT and parsers use. Don't set `aria-live`; a feed full of live-updating timestamps is a screen-reader nightmare. `<relative-time>` sets a `title` with the absolute time by default (suppress with `no-title` if you're supplying your own tooltip); keep it, it's the accessible escape hatch for "when exactly?". "3 minutes ago" alone is insufficient for anything auditable — pair it with an absolute time on hover/focus.

**Native.** Works unchanged in the web view. If you have a native list screen showing the same records, it must format timestamps the same way — the native side should receive the ISO8601 instant, not a formatted string.

**Pitfalls.**
- An empty `<relative-time>` with no fallback text renders blank until the JS loads, and blank forever for crawlers. Always emit `time_ago_in_words` or a formatted date inside.
- `datetime` without a timezone designator (`2026-08-15T14:22:07`, no `Z`) is parsed as **local time** — every user in a different timezone sees a wrong offset. `.utc.iso8601` is not optional.
- Under morphing, idiomorph will morph the element's text content back to the server's fallback string on every refresh; the element re-renders on its next tick, so you may see a brief flicker. `data-turbo-permanent` is overkill; ignore it, or set a long `threshold` so most timestamps are static text anyway.
- `format="micro"` produces "3m", "2d" — great for dense lists, bad as the *only* representation. Keep the title.
- The npm package is ESM; with importmap, `./bin/importmap pin @github/relative-time-element`.

**Prior art.**
- [@github/relative-time-element](https://github.com/github/relative-time-element) **5.3.1** (2026-08-03) — active. **The answer.**
- [@stimulus-components/timeago](https://www.stimulus-components.com/docs/components/timeago) **5.0.2** — values `datetime` (required), `refreshInterval`, `includeSeconds` (default false), `addSuffix` (default false); built on `date-fns/formatDistanceToNow`, so it pulls in date-fns. Fine, but heavier and less capable than the web component.
- [Rails — `time_ago_in_words`](https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-time_ago_in_words)

---

### Click-to-reveal

**Hotwire answer.** A `reveal` primitive. For a password field it flips `type` between `password` and `text`; for a "show email" / spoiler it toggles a `hidden` class on `item` targets. Ten lines, no dependencies.

**Code.**

```js
// app/javascript/controllers/reveal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "input", "trigger"]
  static classes = ["hidden"]

  toggle(event) {
    const pressed = event.currentTarget.getAttribute("aria-pressed") === "true"
    this.#apply(!pressed)
  }

  #apply(revealed) {
    if (this.hasInputTarget) {
      const el = this.inputTarget
      const { selectionStart: s, selectionEnd: e } = el
      el.type = revealed ? "text" : "password"   // value is untouched
      el.setSelectionRange?.(s, e)               // keep the caret where it was
    }
    this.itemTargets.forEach((el) => el.classList.toggle(this.hiddenClass, !revealed))
    this.triggerTargets.forEach((el) => {
      el.setAttribute("aria-pressed", revealed)
      el.querySelector("[data-reveal-label]")?.replaceChildren(
        revealed ? "Hide password" : "Show password"
      )
    })
  }
}
```

```erb
<div data-controller="reveal" data-reveal-hidden-class="hidden">
  <%= f.password_field :password, data: { reveal_target: "input" },
        autocomplete: "new-password" %>
  <button type="button"
          data-reveal-target="trigger"
          data-action="reveal#toggle"
          aria-pressed="false"
          aria-controls="user_password">
    <span data-reveal-label>Show password</span>
  </button>
</div>
```

**Decomposition.** `reveal` (+ `transition` for a spoiler fade).

**A11y.** The trigger is a `<button type="button">` (inside a form, `type="button"` is mandatory or it submits) with `aria-pressed` reflecting state — this is the [APG Button (toggle) pattern](https://www.w3.org/WAI/ARIA/apg/patterns/button/). Changing `aria-pressed` is announced by screen readers automatically; **do not** also fire a live region, you'll get a double announcement. Changing the *visible* label ("Show" → "Hide") is good for sighted users and also renames the button — that is acceptable and expected here. `aria-controls` points at the input. **Never clear or re-set the input's `value`** when flipping `type` — some hand-rolled versions replace the input node entirely, which loses the value, breaks password managers, and drops focus. Flip `type` in place and restore the selection range, as above.

**Native.** n/a — works as-is. Note iOS's own "show password" affordance may also appear; that's fine.

**Pitfalls.**
- `type="text"` on a password field disables the browser/password-manager treatment while revealed. Expected, but it also means autofill may re-fire; keep `autocomplete` correct.
- 1Password/iCloud Keychain inject their own toggle; yours can end up duplicated. Test with an extension installed.
- Turbo's snapshot clone **clears `input[type=password]` values** by design — but if the field is currently `type="text"` when the snapshot is taken, the value **is** cached. Reset to `password` in `turbo:before-cache`.
- A spoiler that only hides with `visibility: hidden` still leaks the text to screen readers and to Ctrl+F. Use `hidden` / `display: none`, or `filter: blur()` plus `user-select: none` only if the leak is acceptable.

**Prior art.** [@stimulus-components/reveal](https://www.stimulus-components.com/docs/components/reveal) **5.0.0** — target `item`, class `hidden` (default `"hidden"`), actions `toggle`/`show`/`hide`, auto-syncs `aria-expanded` on the trigger if present (note: `aria-expanded` is the disclosure semantic; for a password toggle `aria-pressed` is more correct).

---

### Filter chips

**Hotwire answer.** Chips are **links**, not buttons and not JS. Each chip's × is an `<a>` to the current URL minus one param. **No JS needed**, no Stimulus controller, and Back works for free. (Faceted filtering itself — the form, the counts, the frame — belongs to the Data-display section; this record is only the chip UI.)

**Code.**

```erb
<%# app/helpers/filters_helper.rb %>
def without_param(key, value = nil)
  filters = params.permit(:q, status: [], tag: []).to_h
  if value && filters[key.to_s].is_a?(Array)
    filters[key.to_s] = filters[key.to_s] - [value]
    filters.delete(key.to_s) if filters[key.to_s].empty?
  else
    filters.delete(key.to_s)
  end
  url_for(filters.merge(only_path: true))
end
```

```erb
<ul class="chips">
  <% @active_filters.each do |key, label, value| %>
    <li class="chip">
      <span><%= label %></span>
      <%= link_to without_param(key, value),
            class: "chip__remove",
            aria: { label: t(".remove_filter", filter: label) },
            data: { turbo_action: "replace" } do %>
        <svg aria-hidden="true" focusable="false">…</svg>
      <% end %>
    </li>
  <% end %>
  <% if @active_filters.any? %>
    <li><%= link_to t(".clear_all"), url_for(only_path: true),
              data: { turbo_action: "replace" } %></li>
  <% end %>
</ul>
```

`data-turbo-action="replace"` for consistency with the filter form, so removing chips doesn't stack history entries and (with the refresh meta tags) scroll is preserved — see the *Scroll-position restoration* record.

**Decomposition.** None.

**A11y.** Each remove control is a link with `aria-label="Remove filter: Open"` — the icon must be `aria-hidden="true" focusable="false"`. Wrap the set in a `<ul>` so AT announces "list, 3 items". Do **not** use `role="button"` on a link that navigates. After removal the page re-renders and focus is lost to `<body>`; if the chip list is long, move focus to the chip list container (`tabindex="-1"` + focus on `turbo:load`) or announce the new result count via `role="status"`.

**Native.** Works as-is. A horizontally scrolling chip row should use `scroll-snap-type: inline mandatory` and `overscroll-behavior-inline: contain` so it doesn't fight the native swipe-back gesture.

**Pitfalls.**
- Building the "remove" URL by string-munging `request.query_string` breaks on array params (`tag[]=a&tag[]=b`). Rebuild from a permitted hash, as above.
- Chips implemented as `<button>` inside the filter form submit the form when clicked — and if you `preventDefault` you've just written JavaScript for something a link does.
- A chip whose × is smaller than 24×24 CSS px fails [WCAG 2.5.8 Target Size (Minimum)](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html). Pad it.

**Prior art.** [pagy](https://ddnexus.github.io/pagy/) **43.6.1** (2026-07-21) for the pagination that usually sits below — note pagy's v43 docs no longer ship a dedicated Turbo/infinite-scroll extra; its JS nav helpers render plain links that work inside a frame naturally. Verify against the current docs before citing pagy "Turbo support".

---

### Scroll-driven animations / reveal-on-scroll

**Hotwire answer.** `animation-timeline: view()` where supported, `intersection` where not. **Ship both**, gated on `@supports` — because as of 2026-08 scroll-driven animations are **Baseline: Limited** (Chrome 115+, Safari 26+, **Firefox has not shipped**, [webstatus.dev](https://webstatus.dev/features/scroll-driven-animations)). Anyone telling you this is "the 2026 zero-JS answer" is a year early on Firefox.

**Code.**

```css
.reveal { opacity: 0; translate: 0 1rem }
.reveal.is-visible { opacity: 1; translate: none; transition: opacity .4s, translate .4s }

@supports (animation-timeline: view()) {
  .reveal {
    opacity: 1; translate: none;                  /* JS path not needed; reset the base */
    animation: reveal linear both;
    animation-timeline: view();
    animation-range: entry 0% entry 60%;
  }
  @keyframes reveal { from { opacity: 0; translate: 0 1rem } }
}

@media (prefers-reduced-motion: reduce) {
  .reveal { opacity: 1 !important; translate: none !important; animation: none !important }
}
```

```erb
<article class="reveal"
         data-controller="intersection"
         data-intersection-once-value="true"
         data-intersection-threshold-value="0.2"
         data-action="intersection:enter->intersection#addVisibleClass">
```

Feature-detect in the controller so the fallback doesn't fight the CSS:

```js
connect() {
  if (CSS.supports("animation-timeline: view()")) return   // CSS owns it
  // …useIntersection setup
}
```

**Decomposition.** `intersection` (with a `once` value so the observer unobserves after the first entry).

**A11y.** `prefers-reduced-motion: reduce` must fully disable this — content that animates in is content that, for some users, never appears. The `!important` block above is deliberate: it has to beat both paths. Never make content *depend* on the animation to become visible; the base state should be visible for anyone without JS and without the CSS feature.

**Native.** Reveal-on-scroll in a native web view reads as jank on a slower device and fights the native scroll physics. Consider `body[data-hotwire-native] .reveal { animation: none; opacity: 1 }`.

**Pitfalls.**
- A `scroll` event listener for this is a main-thread performance bug. `IntersectionObserver` or CSS, never `scroll`.
- Elements that start at `opacity: 0` and never intersect (inside a collapsed container, below a lazy frame that never loads) stay invisible forever. Always unobserve *and* set the visible state on `disconnect()`.
- `animation-timeline: view()` requires the element to be in a scroll container with a definite scrollport; inside `overflow: visible` ancestors it silently uses the nearest scrollport, which is often not the one you meant.

**Prior art.** [scroll-driven-animations.style](https://scroll-driven-animations.style/) · [stimulus-use `useIntersection`](https://stimulus-use.github.io/stimulus-use/#/use-intersection) · [MDN — CSS scroll-driven animations](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_scroll-driven_animations)

---

### Idle / session timeout warning

**Hotwire answer.** `stimulus-use`'s `useIdle` + a `<dialog>` warning + a keepalive `fetch` on "Stay signed in". Server-side session expiry stays the source of truth; the dialog is a courtesy, never the enforcement.

**Code.**

```js
// app/javascript/controllers/session_timeout_controller.js
import { Controller } from "@hotwired/stimulus"
import { useIdle } from "stimulus-use"

export default class extends Controller {
  static targets = ["dialog", "countdown"]
  static values = {
    idleMs:   { type: Number, default: 25 * 60 * 1000 },  // warn 5 min before a 30-min session
    graceMs:  { type: Number, default: 5 * 60 * 1000 },
    keepalive: String                                     // POST here to extend
  }

  connect() {
    useIdle(this, { ms: this.idleMsValue })
  }

  away() {                     // stimulus-use calls this when idle
    this.deadline = Date.now() + this.graceMsValue
    this.dialogTarget.showModal()
    this.timer = setInterval(() => this.#tick(), 1000)
  }

  back() {                     // and this on any activity
    if (!this.dialogTarget.open) this.#extend()   // silent keepalive while active
  }

  async stay() {
    await this.#extend()
    this.#dismiss()
  }

  disconnect() { clearInterval(this.timer) }

  #tick() {
    const left = Math.max(0, this.deadline - Date.now())
    this.countdownTarget.textContent = `${Math.ceil(left / 1000)}s`
    if (left === 0) { this.#dismiss(); Turbo.visit("/session/timeout", { action: "replace" }) }
  }

  #dismiss() { clearInterval(this.timer); this.dialogTarget.close() }

  async #extend() {
    await fetch(this.keepaliveValue, {
      method: "POST",
      headers: { "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content },
      keepalive: true
    })
  }
}
```

```erb
<div data-controller="session-timeout"
     data-session-timeout-keepalive-value="<%= session_keepalive_path %>">
  <dialog data-session-timeout-target="dialog"
          aria-labelledby="timeout-title" aria-describedby="timeout-body">
    <h2 id="timeout-title">Still there?</h2>
    <p id="timeout-body" role="alert">
      You'll be signed out in <strong data-session-timeout-target="countdown">5:00</strong>.
    </p>
    <button data-action="session-timeout#stay" autofocus>Stay signed in</button>
    <%= button_to "Sign out now", session_path, method: :delete %>
  </dialog>
</div>
```

`useIdle` options, verified against stimulus-use **0.53.0** docs: `ms` (default `60000`), `initialState` (default `false`), `events` (default `['mousemove','mousedown','resize','keydown','touchstart','wheel']`), `dispatchEvent` (default `true`), `eventPrefix` (default `true`). It calls `away(event)` / `back(event)` on the controller, exposes `isIdle`, returns `[observe, unobserve]`, and patches `disconnect` for cleanup.

**Decomposition.** `dialog` + `focus-trap` + `countdown` + `timeout`. Idle detection itself is the `useIdle` **mixin**, not a controller.

**A11y.** `showModal()` traps focus and makes the background inert — required, because the dialog is time-critical. `autofocus` on the safe action ("Stay signed in"). `role="alert"` on the body so it's announced immediately. **The countdown text must not be in a live region** that re-announces every second; announce once, and if you must update, use `aria-live="off"` with a separate one-shot announcement at 60s and 10s. [WCAG 2.2.1 Timing Adjustable](https://www.w3.org/WAI/WCAG22/Understanding/timing-adjustable.html) requires the user be able to extend the limit — the "Stay signed in" button *is* that mechanism, so it must be reachable and must actually work.

**Native.** In Hotwire Native the web view may be backgrounded for hours; the idle timer is meaningless and the dialog will greet the user on resume. Suppress it: `body[data-hotwire-native] [data-controller~=session-timeout] { display: none }`, and handle expiry with the standard 401 → native login flow instead ([04-hotwire-native §5.2](#)).

**Pitfalls.**
- The warning is **not** the security boundary. The server must expire the session regardless; a user with JS disabled must still be logged out.
- Multiple tabs: each tab has its own idle timer, and one tab's keepalive silently extends the others. If that matters, coordinate over `BroadcastChannel` or a `localStorage` heartbeat.
- A keepalive endpoint that touches the session on every call defeats absolute-timeout policies. Make it explicit and rate-limited.
- `useIdle`'s default event list includes `mousemove`, so a page that's merely under the cursor never goes idle. Trim the list if you need real idleness.

**Prior art.** [stimulus-use `useIdle`](https://stimulus-use.github.io/stimulus-use/#/use-idle) — **0.53.0** (2026-06-30), [stimulus-use/stimulus-use](https://github.com/stimulus-use/stimulus-use)

---

### Offline / connection-lost banner

**Hotwire answer.** Two signals, one banner: `navigator.onLine` + the `online`/`offline` events for the OS-level state, and **`turbo:fetch-request-error`** for the case that actually matters — a Turbo visit or form submission that failed. The second is the one nobody documents, and it's the one that catches "your wifi says connected but the server is unreachable".

**Code.**

```js
// app/javascript/controllers/connection_controller.js
import { Controller } from "@hotwired/stimulus"

// Put this on the banner element in the layout, once.
export default class extends Controller {
  static classes = ["offline"]
  static targets = ["message"]
  static values = { retryUrl: String }

  connect() {
    this.onOnline  = () => this.#set(true)
    this.onOffline = () => this.#set(false)
    // Fired by Turbo whenever a fetch (visit, frame, form) throws — i.e. a network
    // failure, not an HTTP error status. Cancelable; detail is { request, error }.
    this.onFetchError = (event) => {
      this.#set(false, `Couldn't reach the server (${event.detail.error.message}).`)
    }

    addEventListener("online", this.onOnline)
    addEventListener("offline", this.onOffline)
    addEventListener("turbo:fetch-request-error", this.onFetchError)

    this.#set(navigator.onLine)
  }

  disconnect() {
    removeEventListener("online", this.onOnline)
    removeEventListener("offline", this.onOffline)
    removeEventListener("turbo:fetch-request-error", this.onFetchError)
  }

  // "Retry" button: a cheap HEAD to confirm we're really back before hiding.
  async retry() {
    try {
      await fetch(this.retryUrlValue, { method: "HEAD", cache: "no-store" })
      this.#set(true)
      Turbo.visit(window.location.href, { action: "replace" })
    } catch {
      this.#set(false, "Still offline.")
    }
  }

  #set(online, message) {
    this.element.classList.toggle(this.offlineClass, !online)
    this.element.hidden = online
    if (this.hasMessageTarget) {
      this.messageTarget.textContent =
        message ?? (online ? "Back online." : "You're offline. Changes won't be saved.")
    }
  }
}
```

```erb
<%# app/views/layouts/application.html.erb — outside every frame, above the fold %>
<div id="connection-banner"
     data-controller="connection"
     data-connection-offline-class="banner--offline"
     data-connection-retry-url-value="<%= up_path %>"
     role="status" aria-live="polite"
     hidden>
  <span data-connection-target="message"></span>
  <button type="button" data-action="connection#retry">Retry</button>
</div>
```

**`turbo:fetch-request-error`, verified against source** (`src/http/fetch_request.js`):

```js
#willDelegateErrorHandling(error) {
  const event = dispatch("turbo:fetch-request-error", {
    target: this.target,
    cancelable: true,
    detail: { request: this, error: error }
  })
  return !event.defaultPrevented
}
```

- Fires on a **thrown fetch** — DNS failure, connection reset, offline — **not** on a 4xx/5xx, which are ordinary responses Turbo renders.
- `detail.request` is the `FetchRequest` (with `.url`, `.method`); `detail.error` is the `TypeError` from `fetch`.
- `target` is the element that initiated it (the `<form>`, the `<turbo-frame>`, or `document` for a Drive visit), and it **bubbles** — so a single `@window` listener catches all of them.
- Calling `event.preventDefault()` **suppresses Turbo's own error handling**, which for a Drive visit means it won't fall back to `window.location`. Only do that if you're handling the failure yourself.

Frame-scoped variant — show the error inside the frame rather than a global banner:

```erb
<%= turbo_frame_tag "comments", src: comments_path, loading: :lazy,
      data: { action: "turbo:fetch-request-error->frame-error#show" } do %>
```

**Decomposition.** No shared primitive fits cleanly; `connection` is an app-level controller. It composes with `transition` (slide the banner in) and `timeout` (auto-hide the "Back online" message after 3s).

**A11y.** `role="status"` + `aria-live="polite"` — the region must exist in the DOM (`hidden` is fine; toggling `hidden` on an existing live region does announce) before you write into it. Don't use `assertive`; losing connection is not an emergency interrupt. The banner must not overlay or displace focused content — a `position: fixed` bar at the top that pushes the layout causes a focus jump mid-typing. Give the Retry button a real accessible name. Don't rely on color alone (red bar) — include text.

**Native.** Hotwire Native has **no built-in offline story** — no service worker, no cached shell ([04-hotwire-native §G4](#)). A failed visit surfaces through the native error handling (§6.5), and the web banner may never render because the web view has nothing to render. If offline matters in the native app, that's an argument for a **native screen backed by a local store**, not a web banner. Hide the web banner in native and let the native error screen do the job.

**Pitfalls.**
- **`navigator.onLine` is a liar.** `true` means "there's a network interface with a route", not "the internet works" — captive portals, VPN drops, and dead backends all report online. That's exactly why `turbo:fetch-request-error` is the more useful of the two signals. Never gate functionality on `navigator.onLine` alone.
- `false` is trustworthy in the other direction: if it's `false`, you are definitely offline.
- The banner must live **outside** every `<turbo-frame>`, or a frame swap destroys it mid-message.
- Mark the banner `data-turbo-temporary` so a stale "You're offline" doesn't come back from the snapshot cache on Back.
- Firing a `Turbo.visit` retry on every `online` event produces a reload storm on a flaky connection. Debounce it (stimulus-use `useDebounce`) or require the explicit Retry click.
- Registering the listeners on `window` from a controller means you **must** remove them in `disconnect()` — Turbo's cache will re-`connect()` the controller on Back and you'll double-register.

**Prior art.**
- [Turbo Reference — Events](https://turbo.hotwired.dev/reference/events) (`turbo:fetch-request-error`)
- [MDN — `navigator.onLine`](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/onLine) and the [Online/offline events guide](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/Online_and_offline_events)
- [@stimulus-components/notification](https://www.stimulus-components.com/docs/components/notification) **3.0.0** — values `delay` (default `3000`), `hidden` (default `false`); actions `show`/`hide`; built on stimulus-use's `useTransition`. Reasonable base for the banner's animation.

---



## Prior-art inventory


Compiled 2026-08-15. Context: Rails 8 era, Turbo 8.0.23, turbo-rails 2.0.23, Stimulus 3.2.x. No Turbo 9 exists.

---

### Stimulus controller libraries

#### stimulus-components (monorepo)

- Site: https://www.stimulus-components.com/
- Repo: https://github.com/stimulus-components/stimulus-components
- Last commit: **2026-08-15** (same day) — actively maintained, very high commit frequency.
- Monorepo tooling: pnpm workspaces + Changesets. Root deps pin `@hotwired/stimulus ^3.2.2`, `@hotwired/turbo ^8.0.13`.
- Packages live under `components/` (not `packages/`). Install line pattern: `npm install @stimulus-components/<name>` (a few packages kept their pre-monorepo standalone npm name — noted below).

Full package list (verbatim `name`/`version` from each `package.json`, fetched via GitHub API 2026-08-15):

| npm package | Version | What it does |
|---|---|---|
| `@stimulus-components/animated-number` | 5.0.0 | Animates a numerical value by counting to it |
| `@stimulus-components/auto-submit` | 6.0.0 | Auto-submits forms |
| `@stimulus-components/carousel` | 6.0.0 | Carousel behavior |
| `@stimulus-components/character-counter` | 5.1.0 | Counts characters in input fields |
| `@stimulus-components/chartjs` | 6.0.1 | Wraps Chart.js |
| `@stimulus-components/checkbox-select-all` | 6.1.0 | Manages checkbox lists (select-all/none) |
| `@stimulus-components/clipboard` | 5.0.0 | Copies text to clipboard |
| `@stimulus-components/color-picker` | 2.0.0 | Color picker |
| `@stimulus-components/confirmation` | 1.0.1 | Manual action confirmation |
| `@stimulus-components/content-loader` | 5.0.0 | Asynchronously loads HTML from a URL |
| `@stimulus-components/dialog` | 1.0.1 | Modals via native `<dialog>` element |
| `@stimulus-components/dropdown` | 3.0.0 | Dropdown |
| `stimulus-glow` | 0.3.0 | Mouse-tracing glow effect (kept standalone npm name) |
| `@stimulus-components/hotkey` | 1.0.0 | Triggers click/focus on keyboard shortcut |
| `@stimulus-components/lightbox` | 4.0.0 | Lightbox on images |
| `@stimulus-components/notification` | 3.0.0 | Shows notifications |
| `@stimulus-components/password-visibility` | 3.0.0 | Toggles password input visibility |
| `stimulus-places-autocomplete` | 0.5.0 | Google Places Autocomplete (kept standalone npm name) |
| `@stimulus-components/popover` | 7.0.0 | Wraps native HTML Popover API |
| `@stimulus-components/prefetch` | 4.0.0 | Prefetches in-viewport links |
| `@stimulus-components/rails-nested-form` | 5.0.0 | Adds/removes nested form fields for Rails `accepts_nested_attributes_for` |
| `@stimulus-components/read-more` | 5.0.0 | Show more/less text |
| `@stimulus-components/remote-rails` | 5.0.0 | Handles Rails UJS-style remote events |
| `@stimulus-components/reveal` | 5.0.0 | Toggles a class on elements to show/hide them |
| `@stimulus-components/scroll-progress` | 5.0.0 | Progress bar tied to scroll position |
| `@stimulus-components/scroll-reveal` | 4.0.0 | Animates elements into view on scroll |
| `@stimulus-components/scroll-to` | 5.0.1 | Scrolls to elements |
| `@stimulus-components/sortable` | 5.0.2 | Drag-and-drop reordering (wraps SortableJS) |
| `@stimulus-components/sound` | 2.0.1 | Plays/controls sound |
| `@stimulus-components/speech-recognition` | 1.0.0 | Web Speech API capture into an input/element |
| `stimulus-textarea-autogrow` | 4.1.0 | Auto-growing textarea (kept standalone npm name) |
| `@stimulus-components/timeago` | 5.0.2 | Relative "time ago" text |

Note: the historic standalone packages `stimulus-reveal-controller` (last npm publish 4.1.0, 2022-12-26) and `stimulus-rails-nested-form` (last npm publish 4.1.0, 2022-12-24) were superseded by `@stimulus-components/reveal` and `@stimulus-components/rails-nested-form` respectively inside this monorepo (now at major version 5.0.0) — the old standalone package names are effectively frozen/deprecated in favor of the scoped names.

#### tailwindcss-stimulus-components

| Package | Version (date) | Status | What it does |
|---|---|---|---|
| `tailwindcss-stimulus-components` | 6.1.4 (2026-06-03) | Actively maintained (last commit 2026-08-04) | Pre-built Stimulus controllers styled for Tailwind CSS |

- Repo: https://github.com/excid3/tailwindcss-stimulus-components
- Controllers shipped (from `src/`, verbatim filenames): `alert.js`, `autosave.js`, `color_preview.js`, `dropdown.js`, `modal.js`, `popover.js`, `slideover.js`, `tabs.js`, `toggle.js`, `transition.js` (plus `index.js` entrypoint).
- Install: `npm install tailwindcss-stimulus-components` (or `yarn add`).

#### stimulus-use

| Package | Version (date) | Status | What it does |
|---|---|---|---|
| `stimulus-use` | 0.53.0 (2026-06-30) | Actively maintained (last commit 2026-07-27) | Collection of reusable Stimulus behavior mixins/composition helpers |

- Repo: https://github.com/stimulus-use/stimulus-use
- Install: `npm install stimulus-use`
- Every mixin (from `src/` directory listing, verbatim): `useApplication`, `useClickOutside`, `useDebounce`, `useDispatch`, `useHotkeys` (also exposed as top-level `hotkeys.ts`), `useHover`, `useIdle`, `useIntersection`, `useLazyLoad`, `useMatchMedia`, `useMemo`, `useMeta`, `useMutation`, `useResize`, `useTargetMutation`, `useThrottle`, `useTransition`, `useVisibility`, `useWindowFocus`, `useWindowResize`.

#### Better Stimulus

- Site: https://www.betterstimulus.com/ (patterns/best-practices site, not a package)
- Section headings (from site nav, verbatim slugs):
  - **Architecture**: Application Controller, Configurable Controllers, Mixins, Namespaced Attributes, State Management, Targetless Controllers
  - **Lifecycle**: Connect
  - **Interaction**: Callbacks, Outlets
  - **Events**: Events
  - **Integrating Libraries**: Lifecycle
  - **Turbo**: Form Submits, Teardown
  - **SOLID**: Single Responsibility, Open/Closed, Dependency Inversion

#### Other maintained `stimulus-*` packages

| Package | Version (date) | Status | Install | Repo |
|---|---|---|---|---|
| `stimulus-flatpickr` | 1.4.0 (2020-11-24) | **Quiet/stale** — last commit 2023-10-01, last release 2021 (v3.0.0-0 tag exists but never published to npm past 1.4.0) | `npm install stimulus-flatpickr` | https://github.com/adrienpoly/stimulus-flatpickr |
| `stimulus-autocomplete` | 3.1.0 (2023-03-01) | Quiet — last commit 2024-08-14, no release since 2023 | `npm install stimulus-autocomplete` | https://github.com/afcapel/stimulus-autocomplete |

Both `stimulus-reveal-controller` and `stimulus-rails-nested-form` as standalone packages are effectively superseded/frozen — see stimulus-components monorepo above, which is where active development continues under scoped names.

---

### Hotwire-specific gems

| Package | Version (date) | Status | What it does |
|---|---|---|---|
| `hotwire_combobox` | 0.4.1 (2026-02-13) | Actively maintained (last commit 2026-08-10) | Accessible, richly-styled autocomplete/combobox for Hotwire Rails apps |
| `turbo_power` | 0.8.0 (2026-07-13) | Actively maintained (last commit 2026-08-02) | Adds a large set of custom Turbo Stream actions beyond the 7 built-in ones |
| `turbo_boost-commands` | 0.3.2 (2024-06-14) | **Quiet** — last commit 2024-07-25, not archived but no activity in 2 years | RPC-style "Commands" for calling Ruby methods from Stimulus without a full controller action |
| `turbo_ready` | 0.1.4 (rubygems) | **Quiet/stale** — repo last pushed 2024-03-01 | Turbo Stream helper gem ("take full control of the DOM with Turbo Streams") from the hopsoft/turbo_boost author |
| `turbo_stream_actions` | — | Not found as a distinct maintained rubygem (search returned no results) — write "unverified/does not appear to exist as such" | — |
| `hotwire-livereload` | 2.1.1 (2025-10-14, rubygems) | Actively maintained on rubygems but note the canonical repo appears to be `kirillplatonov/hotwire-livereload` (a community fork/successor of the original), last pushed 2025-10-14 | Auto-reloads browser on view/asset changes in development |
| `hotwire-spark` (gem name is `hotwire-spark`, not `hotwire_spark`) | 0.1.13 (2025-01-25) | **Quiet** since Jan 2025, but this is the official 37signals/Hotwired successor to hotwire-livereload — install via Rails 8 default Gemfile | Official Basecamp/37signals live-reload system ("updates just what's needed") |
| `turbo-mount` | 0.4.4 (rubygems, 2025-12-25); repo last pushed 2026-07-25 | Actively maintained | Mounts React/Vue/Svelte "islands" inside Turbo-driven Rails views |
| `stimulus_reflex` | 3.5.5 (2025-05-25) | **Maintenance-mode** — repo commits continue (last 2026-07-28) but every commit since Jan 2026 is a Dependabot dependency bump; the last *substantive* change was 2025-05-22 (relaxing `@rails/actioncable` to allow `>= 8.0` for Rails 8 compatibility). No new features since. | Server-rendered reactive updates over ActionCable ("Reflexes") |
| `cable_ready` | 5.0.6 (2024-12-15) | **Quiet** — last commit 2025-06-25, no release since Dec 2024 | Broadcasts fine-grained DOM operations over ActionCable from server-side Ruby |

Turbo Power — every custom stream action (verbatim exported function names from `src/actions/*.ts`, 45 real actions + `invoke` in a `deprecated.ts` file):
`add_css_class`, `clear_storage`, `console_log`, `console_table`, `dispatch_event`, `graft`, `history_back`, `history_forward`, `history_go`, `inner_html`, `insert_adjacent_html`, `insert_adjacent_text`, `notification`, `outer_html`, `push_state`, `redirect_to`, `reload`, `remove_attribute`, `remove_css_class`, `remove_storage_item`, `replace_css_class`, `replace_state`, `reset_form`, `scroll_into_view`, `set_attribute`, `set_cookie`, `set_cookie_item`, `set_dataset_attribute`, `set_focus`, `set_meta`, `set_property`, `set_storage_item`, `set_style`, `set_styles`, `set_title`, `set_value`, `text_content`, `toggle_attribute`, `toggle_css_class`, `turbo_clear_cache`, `turbo_frame_reload`, `turbo_frame_set_src`, `turbo_progress_bar_hide`, `turbo_progress_bar_set_value`, `turbo_progress_bar_show`, `invoke` (deprecated).

**StimulusReflex / CableReady vs. Turbo 8 morphing** — factual findings:
- StimulusReflex's own docs (`docs/guide/morph-modes.md`) describe three "Morph" modes (Page, Selector, Nothing) that are implemented on top of the `morphdom` library, entirely independent of Turbo. This is StimulusReflex's own DOM-diffing mechanism for applying server-rendered HTML after a Reflex round-trip over ActionCable — it predates and is architecturally separate from Turbo 8's native `idiomorph`-based morphing (used by `<turbo-frame refresh="morph">`, `Turbo.session.drive`, and morphing Turbo Stream broadcasts).
- The commit history shows the project has been in dependency-bump-only maintenance mode since roughly mid-2025 (see version/date table above); the last functional commit was a Rails 8 ActionCable compatibility fix.
- Net: StimulusReflex/CableReady are not archived/dead, but show no active feature development as of 2026-08-15, and their core "morph without a full request-response cycle" value proposition substantially overlaps with what Turbo 8's built-in morphing + Turbo Streams broadcasts now provide without a separate ActionCable-based Reflex layer.

---

### Commercial / curated component libraries

| Product | Version/last activity | Status | Pricing | What it does |
|---|---|---|---|---|
| **Rails Designer** — https://railsdesigner.com/ | Components page states "Over 200 components used by 1,000+ developers globally." Exact release cadence unverified (no public changelog feed checked beyond `/feed/changelog.xml` existing). | Appears actively maintained (has a changelog RSS feed, blog, notes feed) | **One-time price with lifetime updates** (per pricing page copy: "one-time price," "lifetime updates"); exact dollar figure not captured from static HTML (rendered client-side) — unverified. Separately advertises a bespoke "Rails UI consultancy"/SaaS-build service starting around €12k, unrelated to the component library price. | Built with **ViewComponent + Tailwind CSS + Hotwire** (per page meta description, verbatim: "Built with ViewComponent, Tailwind CSS and Hotwire") |
| **Railsblocks** — https://railsblocks.com/ | unverified (no changelog/version data pulled) | unverified | Freemium: free tier + "Rails Blocks Pro" (price unverified), student discount offered | "300+ UI components" — Accordion, Alert, Avatar, Badge, Banner, Breadcrumb, Buttons, Card, Carousel, Checkbox, Clipboard, Collapsible, Color picker, Combobox, Command Palette, Confirmation, Datatable, Date picker, Drawer, Dropdown, Emoji picker, Feedback, Forms, Infinite Scroll, Lightbox, Modal, Navbar, Pagination, Popover, Radio, Scroll Area, Select, Sidebar, Skeleton, Slideover, Stepper, Tabs, Table, Toast, Tooltip, and others. Uses **ViewComponent**, Tailwind CSS v4+, Stimulus, Hotwire (Turbo Drive/Frames/Streams); targets Rails 7+ |
| **RailsUI** — https://railsui.com/ | unverified version/release data | unverified maintenance cadence | Subscription: **$99 / $149 / $299** tiers seen on homepage ("One subscription. Every kit, every component, every update.") — tier names/inclusions not individually confirmed | Positions itself against AI-generated code: "AI writes your Rails code. Rails UI makes it a product." Ships kits/components for CRM, project management, hiring/ATS, personal finance, property management, agency/client portals, AI apps, PaaS/server management |
| **Shadcn on Rails** (aviflombaum/shadcn-rails) — https://github.com/aviflombaum/shadcn-rails, site https://shadcn.rails-components.com | Gem: `shadcn-ui`. Repo last pushed **2025-11-21** | **Quiet** — ~9 months no activity as of 2026-08-15, but not archived; 892 GitHub stars | Free, open source | Explicitly **not a distributed component library** — copy-paste components (like the original shadcn/ui philosophy), not installed as a dependency, not published to npm/rubygems as a runtime dep |
| **view_primitives** (alec-c4/view_primitives) | Gem `view_primitives`. Repo last pushed **2026-07-31** | Actively maintained | Free/open source | "shadcn/ui-inspired component library for Rails built on ViewComponent." Components copied into the app via a generator (`rails g view_primitives:install`), Tailwind classes live in-app. Requires ViewComponent >= 4.0, Rails >= 7.1 |
| **PhlexUI** (phlexui.com) | — | **Dead** — the domain `phlexui.com` and `www.phlexui.com` now 301-redirect to unrelated third-party sites (`thesmartoffice.io`, a hotel site), confirming the original project/domain has lapsed and been repurposed/squatted as of 2026-08-15 | n/a | Historically a Phlex + shadcn/ui-inspired component set; no longer reachable at its original URL |
| Newer Phlex/shadcn-style alternatives found on GitHub (2026 activity) | `sean-yeoh/shadcn_phlexcomponents` (last pushed 2025-11-29), `cole-robertson/shadcn-phlex` | Quiet-to-active, small projects (tens of stars or fewer) | Free/open source | Phlex + Tailwind component libraries explicitly inspired by shadcn/ui, filling the gap left by the dead phlexui.com |
| **ViewComponent** (official) — https://github.com/ViewComponent/view_component | 4.12.0 (2026-06-04); repo last pushed 2026-08-12 | Actively maintained | Free/open source (Rails-adjacent, GitHub-backed) | Framework for reusable, testable, encapsulated view components — the base layer many of the above libraries build on |
| **Primer ViewComponents** — https://github.com/primer/view_components | 0.53.2 (2026-08-05); repo last pushed 2026-08-11 | Actively maintained | Free/open source | GitHub's own design system implemented as Rails ViewComponents (what github.com itself uses) |
| **Polaris ViewComponents** (community port, baoagency/polaris_view_components) | 3.1.2 (2026-05-25); repo last pushed 2026-05-25 | Actively maintained | Free/open source | Community-built ViewComponents implementing Shopify's Polaris design system for Rails (not an official Shopify project) |
| **Bullet Train** field partials — https://github.com/bullet-train-co/bullet_train, fields gem: https://github.com/bullet-train-co/bullet_train-fields | `bullet_train-fields` gem version 1.45.1 (2026-05-06); umbrella repo last pushed 2026-08-14 | Actively maintained | Free/open source SaaS starter framework | Ships a "Super Scaffolding" system with reusable field partials (string, boolean, select, date, etc.) used across the whole Bullet Train framework for generating consistent CRUD forms |
| **Avo** — https://avohq.io/ | unverified specific version | Appears actively maintained (marketing site referenced Pro/Advanced tiers) | Tiered: **$0/mo** (Community/free), then paid tiers seen at **$15, $20, $30, $40/mo** and **$75, $145, $249, $299/mo per app** (multiple tiers on pricing page, exact tier-to-price mapping not individually confirmed) | Ruby framework for building admin panels/internal tools on top of any Rails app; code-driven (Ruby config, not visual builder); 30+ field types, dashboards, filters, authorization, multi-tenancy, audit logging |
| **Madmin** — https://github.com/excid3/madmin | Gem `madmin` 2.5.1 (2026-08-12); repo last pushed **2026-08-14** | Actively maintained (very recent activity) | Free/open source | "A robust Admin Interface for Ruby on Rails apps" by Chris Oliver (excid3) |
| **Motor Admin** — https://motoradmin.com/ (site unreachable from this research environment — DNS/connection refused via both curl-impersonate and WebFetch), GitHub org `motor-admin/motor-admin` | Repo last pushed **2024-05-30**, last release `0.4.21` (2023-09-09) | **Quiet/stale** — over 2 years with no commits as of 2026-08-15 | AGPL-3.0 licensed (open source core); commercial hosted/pricing tiers unverified (site unreachable) | "Deploy a no-code admin panel for any application in less than a minute" — search, CRUD, custom actions, reports; database-agnostic (not Rails-specific) |

---

### Web components worth preferring over Stimulus

All are maintained by GitHub (`github/*` orgs) as standards-based custom elements. Because custom elements are lifecycle-managed by the browser itself (`connectedCallback`/`disconnectedCallback` fire whenever the element enters/leaves the DOM), they re-initialize correctly across Turbo Drive navigations, Turbo Frame swaps, and Turbo 8 morphing without any manual Stimulus `connect()`/`disconnect()` wiring — a Stimulus controller instance is torn down and needs re-attaching by Stimulus's own mutation observer, whereas the custom element's behavior is baked into the element itself.

| npm package | Version (date) | Status | What it does |
|---|---|---|---|
| `@github/relative-time-element` | 5.3.1 (2026-08-03) | Actively maintained (repo pushed 2026-08-07) | Formats a timestamp as localized text or auto-updating relative text ("3 minutes ago") |
| `@github/auto-complete-element` | 3.8.0 (2025-03-11) | Quiet-but-current (repo pushed 2026-08-07, no new npm release since March 2025) | Auto-completes input values from server results |
| `@github/details-menu-element` | 1.0.13 (2022-10-26) | **Stale** — no npm release since Oct 2022, though repo shows activity pushes | A menu opened by a native `<details>`/`<summary>` disclosure |
| `@github/hotkey` | 3.1.4 (2026-03-16) | Actively maintained | Declarative `data-hotkey="Shift+?"` keyboard shortcuts |
| `@github/clipboard-copy-element` | 1.3.2 (2026-06-16) | Actively maintained | Copies element text/input values to the clipboard |
| `@github/markdown-toolbar-element` | 2.2.3 (2024-03-01) | Quiet (repo still pushed to 2026-08-11, but no npm release since March 2024) | Markdown formatting toolbar buttons for a text input |
| `@github/tab-container-element` | 4.9.0 (2026-08-03) | Actively maintained | Tab container/tab-panel switching element |
| `@github/filter-input-element` | npm shows 0.1.1 (2019-12-10) even though the GitHub repo has tagged releases up to v1.0.0 (2023-10-20) — npm publish appears stale/out of sync with GitHub tags | **Stale on npm** (verify before depending on the published package; GitHub source is newer than what's on npm) | Filters visible elements in a subtree against filter input text |
| `@github/time-elements` | Latest npm 4.0.0 (2022-11-29); repo `github/time-elements` now shares its most recent pushes/releases with `relative-time-element` (5.3.1, 2026-08-03) | `time-elements` is effectively **superseded/folded into** `relative-time-element` — treat `time-elements` as the legacy/deprecated package name | Original multi-element time-formatting package; `<relative-time>` is its modern single-element successor |

---

### Supporting JS libraries commonly wrapped by Stimulus controllers

| npm package | Current version | What it does | Still default in 2026? |
|---|---|---|---|
| `sortablejs` | 1.15.7 (2026-02-11) | Drag-and-drop reorderable lists | Yes — still the default drag-and-drop library wrapped by `@stimulus-components/sortable` |
| `chart.js` | 4.5.1 (2025-10-13) | Canvas-based charting | Yes — still the default, wrapped by `@stimulus-components/chartjs` and by `chartkick` |
| `chartkick` | 5.0.1 (2023-01-19) | One-line chart helper wrapping Chart.js/Highcharts/Google Charts | Quiet (no npm release since Jan 2023) but still widely used as a Rails-gem + JS pairing |
| `imask` | 7.6.1 (2024-05-21) | Vanilla JS input masking | Quiet (no release since May 2024) but still the standard input-mask choice |
| `cropperjs` | 2.1.1 (2026-04-06) | JS image cropper | Yes, actively developed (major v2 rewrite) |
| `signature_pad` | 5.1.4 (2026-07-31) | Draws smooth signatures on canvas | Yes, actively maintained and the default choice |
| `zxcvbn` | 4.4.2 (2017-02-07) | Original password-strength estimator | **Superseded** — original package unmaintained since 2017 |
| `@zxcvbn-ts/core` | 4.2.0 (2026-08-12) | TypeScript rewrite of zxcvbn | Yes — this is now the default choice, actively maintained |
| `flatpickr` | 4.6.13 (2022-04-14) | Lightweight JS datetime picker | Quiet (no release since April 2022) but still extremely widely used; no clear dominant successor has fully displaced it |
| `tom-select` | 2.6.2 (2026-07-07) | Versatile `<select>` UI control, forked from Selectize.js | Yes — actively maintained, generally considered the default modern successor to Select2/Selectize |
| `choices.js` | 11.2.3 (2026-04-30) | Vanilla JS select/text-input plugin | Yes — actively maintained, a common alternative/peer to Tom Select |
| `trix` | 2.1.19 (2026-05-09) | Rich text editor; ships with Rails ActionText | Yes — still the default for ActionText-based rich text in Rails |
| `@tiptap/core` | 3.30.1 (2026-08-13) | Headless, extensible rich text editor (ProseMirror-based) | Yes — the default choice when apps need a more extensible/customizable editor than Trix |
| `leaflet` | 1.9.4 (2023-05-18) | Mobile-friendly interactive maps | Quiet (no release since May 2023) but still the default lightweight/raster map library; MapLibre GL is the default choice specifically for vector-tile/WebGL maps |
| `maplibre-gl` | 6.3.0 (2026-08-10) | BSD-licensed community fork of Mapbox GL JS, WebGL vector maps | Yes — actively developed, the default choice for vector-tile WebGL maps post-Mapbox license change |
| `@floating-ui/dom` | 1.8.0 (2026-07-11) | Positioning engine for tooltips/popovers/dropdowns | Yes — still the default positioning library (successor to Popper.js) |
| `focus-trap` | 8.2.2 (2026-06-22) | Traps keyboard focus within a DOM node (modals/dialogs) | Yes — actively maintained, standard choice for accessible modal focus management |
| `dropzone` | 6.0.0-beta.2 (2021-11-29) | Drag-and-drop file uploads | **Superseded** — last publish is a 2021 beta; effectively unmaintained |
| `@uppy/core` | 5.2.0 (2025-12-02) | Modular, extensible file upload widget (drag-and-drop, resumable uploads) | Yes — Uppy is now the default modern choice over Dropzone |
| `hls.js` | 1.7.0 (2026-08-12) | JS HLS video streaming client | Yes — actively maintained, still the default for HLS playback in the browser |
| `nouislider` | 15.8.1 (2024-06-21) | Lightweight JS range slider | Quiet (no release since June 2024) but still a common default for range sliders |

---

### Rails-side gems for the patterns

| Gem | Version (date) | Status | What it does |
|---|---|---|---|
| `pagy` | 43.6.1 (2026-07-21) | Actively maintained | Fast, framework-agnostic pagination |
| `kaminari` | 1.2.2 (2021-12-25) | **Quiet/stale** — no release since Dec 2021 | Scope & engine-based pagination (older, still widely deployed but Pagy is the more current default) |
| `ransack` | 4.4.1 (2025-09-29) | Actively maintained | Object-based searching/filtering for ActiveRecord |
| `positioning` (brendon/positioning) | 0.4.8 (2026-03-28) | Actively maintained | Simple positioning/ordering for ActiveRecord models; newer, gap-based-positioning successor approach from the same author as acts_as_list |
| `acts_as_list` | 1.2.6 (2025-10-21) | Actively maintained | Classic sorting/reordering extension for ActiveRecord lists (same author, brendon, now also maintains `positioning` as a modern alternative approach) |
| `ancestry` | 5.1.0 (2026-03-08) | Actively maintained | Organizes ActiveRecord records into a tree using a materialized path column |
| `closure_tree` | 9.8.0 (2026-08-05) | Actively maintained | Hierarchies for ActiveRecord via a closure table |
| `discard` | 2.0.0 (2026-05-27) | Actively maintained | Soft-delete/discard pattern with scopes |
| `paper_trail` | 17.0.0 (2025-10-24) | Actively maintained | Tracks/versions changes to models |
| `audited` | 5.8.0 (2024-11-08) | Quiet (no release since Nov 2024) but not abandoned | Logs all changes to models |
| `friendly_id` | 5.7.0 (2026-05-08) | Actively maintained | Slugging/permalinks for ActiveRecord |
| `ActionText` | Bundled with Rails 8 (versioned with Rails core) | Actively maintained as part of Rails | Rich text content + attachments, built on Trix |
| `ActiveStorage` | Bundled with Rails 8 (versioned with Rails core) | Actively maintained as part of Rails | File attachment/upload framework |
| `wicked` | 2.0.0 (2022-09-14) | **Quiet** — no release since Sept 2022 | Rails engine for multi-step wizard controllers |
| `pwned` (the de-facto "have_i_been_pwned" gem; no gem is literally named `have_i_been_pwned`) | 2.4.1 (2022-08-29) | Quiet (no release since Aug 2022) but still the commonly used integration | Checks passwords against the HaveIBeenPwned breached-password API (commonly paired with Devise via `devise-pwned_password`) |
| `view_component` | 4.12.0 (2026-06-04) | Actively maintained | Framework for reusable, testable, encapsulated view components |
| `phlex` | 2.4.1 (2026-02-06) | Actively maintained | Builds HTML/SVG/CSV views with plain Ruby classes (alternative to ERB/ViewComponent) |

#### Superseded / dead gems (explicitly flagged)

| Gem | Last release (date) | Status | Superseded by |
|---|---|---|---|
| `cocoon` | 1.2.15 (2020-09-08) | **Dead** — jQuery-dependent, no release in 6 years | Native Turbo-driven nested forms / `@stimulus-components/rails-nested-form` |
| `best_in_place` | 4.0.0 (2024-08-15) | **Effectively dead in practice** — jQuery-script-based; Rails 8 no longer ships jQuery by default, so this pattern is off the beaten path even though a 2024 release exists | Custom Stimulus in-place-edit controllers, or Turbo Frame-based inline editing |
| `wice_grid` | 7.1.4 (2024-11-04) | **Quiet/effectively legacy** — points at a `rails3` branch in its own source_code_uri, signaling long-term stagnation despite a 2024 gem bump | Modern datatable components (e.g. Railsblocks' Datatable component, or custom Turbo Frame/Stream-paginated tables) |
| `jquery-rails` | 4.6.1 (2025-10-21) | Still receives occasional releases, but **Rails 8 dropped jQuery from the default new-app stack** — its relevance is now legacy-app-only | Stimulus + Turbo, or targeted vanilla-JS/web-component replacements |
| `select2-rails` | 4.0.13 (2020-07-10) | **Dead** — jQuery-based, no release in 6 years | Tom Select or Choices.js |

---

*Where a fact could not be independently verified from a primary source (README, releases page, rubygems/npm registry, or GitHub API) within this research pass, it is explicitly marked "unverified" rather than guessed.*

## Primitive vocabulary used in this document

Every pattern in this catalog is composed, not authored. There is no `modal` controller here — a modal is `dialog` + `focus-trap` + `scroll-lock` + `dismiss` + `transition`, and each of those five is independently useful somewhere else in this document. The table below is the complete set of controllers the ~95 patterns actually decompose into: 32 from the original shared vocabulary plus 6 admitted during reconciliation. **[ERRATUM, added post-review: this arithmetic is wrong. The tables below contain 39 primitives and mark 6 as `(new)`, so the originals numbered 33, not 32. The tables are authoritative; 39 is the count used everywhere else in this repo. The same off-by-one appears again in the "Drift to fix" section below.]** **Used by** cites real patterns from this document, and each group is ordered most load-bearing first — the primitives at the top of each table are the ones to build and test first, because everything else leans on them. Primitives marked **(new)** were proposed by a section author and accepted here; the proposals that did *not* survive are listed at the end with reasons, because knowing what is deliberately *not* vocabulary is as load-bearing as knowing what is.

### Behavior primitives

| Primitive | Contract | Used by |
|---|---|---|
| `dismiss` | Close or remove the nearest dismissible container on click, Esc, or a programmatic call; `data-dismiss-target-value` to name a non-ancestor container. | Modal dialog, Dropdown menu, Tag / token input, Toast / flash notifications, Mobile nav |
| `persist` | Mirror one piece of element state to localStorage/sessionStorage under `data-persist-key-value` and reapply it on connect. | Accordion / disclosure, Multi-step wizards, Filterable / faceted tables, Dark-mode toggle, Sidebar state persistence |
| `intersection` | Dispatch an action when the element enters or leaves the viewport; `data-intersection-threshold-value`, `data-intersection-once-value`, `data-intersection-root-margin-value`. | Infinite scroll, Pagination with Turbo Frames, Polling, Sticky headers, Reveal-on-scroll |
| `transition` | Run an enter/leave CSS class sequence (`data-transition-enter-*` / `data-transition-leave-*`) and resolve a promise when it finishes. | Modal dialog, Disable-while-submitting, Toast / flash notifications, Optimistic UI, Clipboard copy |
| `focus-trap` | Constrain Tab cycling inside the element, and save then restore the previously focused node on release. | Modal dialog, Bulk actions toolbar, Kanban board, Custom confirm dialogs, Idle / session timeout warning |
| `roving-focus` | Move focus over `item` targets with arrow keys using roving tabindex, plus Home/End and typeahead; `data-roving-focus-orientation-value`. | Dropdown menu, Tabs, Command palette, Tree / nested list, Data grid editing |
| `hotkey` | Bind a declarative keybinding (`data-hotkey="cmd+k"`) that dispatches a click or named action on the element. | Command palette, Search-as-you-type, Inline cell editing, Undo (Gmail-style), Hotkeys |
| `sync` | Mirror one element's value or state onto another named by `data-sync-target-value`, on every change. | Dependent / cascading selects, Character counters, Range / slider, Color pickers, Dark-mode toggle |
| `timeout` | Dispatch an action once, N ms after connect or after a trigger; `data-timeout-delay-value`, cancellable, cleared on disconnect. | Popover / tooltip, Toast / flash notifications, Undo (Gmail-style), Typing indicators, Countdown timers |
| `scroll-lock` | Lock document scroll while active, compensating for scrollbar width via `scrollbar-gutter` so the page does not shift. | Modal dialog, Drawer / slideover, Scroll lock, Mobile nav, Sidebar state persistence |
| `interval` **(new)** | Dispatch a `tick` action every `data-interval-ms-value` milliseconds while the document is visible; auto-stop on `disconnect` and on `visibilitychange`. | Polling, Progress bars for background jobs, Presence (who's online), Live dashboards |
| `click-outside` | Dispatch an action when a pointer event lands outside the element (composed-path aware, so it survives shadow DOM and portals). | Modal dialog, Click-outside, Combobox, Notification bell |
| `anchor` | Position a floating element against a reference using CSS anchor positioning, falling back to floating-ui; `data-anchor-placement-value`. | Popover / tooltip, Dropdown menu, Context menu, Combobox |
| `activate` **(new)** | Dispatch a synthetic `click()` on this element or its `item` target when an action fires; optionally once on connect via `data-activate-on-connect-value`. | Infinite scroll, Export triggers |
| `autoscroll` **(new)** | Keep a scroll container pinned to its end across Turbo Stream renders, but only when the user was already near the end; otherwise reveal a `jump` target. Hooks `turbo:before-stream-render` and wraps `event.detail.render`. | Live chat, Live-updating lists |
| `cable-channel` **(new)** | Subscribe to the ActionCable channel named by `data-cable-channel-name-value` with params, re-dispatch each received payload as a DOM CustomEvent on the element, expose a `send` action, unsubscribe on `disconnect`. | Typing indicators, Presence (who's online) |

### Widget primitives

| Primitive | Contract | Used by |
|---|---|---|
| `dialog` | Drive a native `<dialog>`: `show` / `showModal` / `close`, light-dismiss, and open/close events; never hand-roll the backdrop. | Modal dialog, Drawer / slideover, Command palette, Bulk actions toolbar, Custom confirm dialogs |
| `combobox` | Wire a text input to a listbox with ARIA 1.2 combobox semantics, options static or fetched from `data-combobox-url-value`. | Command palette, Search-as-you-type, Combobox / typeahead, Tag / token input, Filterable tables |
| `popover` | Open a non-modal floating layer, preferring the native Popover API (`popovertarget` / `popover="auto"`) over JS positioning. | Popover / tooltip, Dropdown menu, Context menu, Date & time pickers, Notification bell |
| `disclosure` | Toggle a `content` target's visibility, keeping `aria-expanded` on the trigger and `hidden` on the panel in sync. | Multi-step wizards, Inline cell editing, Tree / nested list, Sidebar state persistence |
| `tabs` | Wire tablist/tab/tabpanel roles with roving focus and optional URL sync via `data-tabs-param-value`. | Tabs (with URL state), Back-button correctness |
| `menu` | Compose a button with `role="menu"` from `popover` + `roving-focus` + `dismiss`; owns only the menu ARIA semantics. | Dropdown menu |

### Form primitives

| Primitive | Contract | Used by |
|---|---|---|
| `autosubmit` | Call `requestSubmit()` on the owning form on input or change, with optional debounce (`data-autosubmit-delay-value`) — never `submit()`. | Autosave, Submit-on-change, Search-as-you-type, Filterable tables, Inline cell editing |
| `dirty-form` | Track field changes, set `data-dirty`, optionally guard `beforeunload`, and clear on `turbo:submit-end`. | Dirty-form warnings, Multi-step wizards, Form state across Turbo cache preview, Rich text, Collaborative editing |
| `direct-upload` | Run Active Storage's `DirectUpload` for each selected file and emit progress events for a `progress` target. | File upload with progress, Drag-and-drop upload, Image cropping, Rich text, Signature pads |
| `char-count` | Mirror an input's length into an `output` target with max and over-limit states from `data-char-count-max-value`. | Character counters, Client-side validation, Password strength, Textarea autogrow |
| `nested-form` | Clone a `<template>` into a container with a unique child index, and mark removals `_destroy` instead of deleting the node. | Nested forms (the `cocoon` replacement), "Add another" repeated sections |
| `drop-zone` | Capture files from drag/drop and paste into a target `<input type="file">`, dispatching a synthetic `change`. | File upload with progress, Drag-and-drop upload |
| `reveal` | Toggle an input between `password` and `text`, or unmask masked text, keeping `aria-pressed` on the trigger. | Password strength, Click-to-reveal |
| `file-preview` **(new)** | Render previews (thumbnail, filename, size) for the files currently in an `<input type="file">`, revoking every object URL on `disconnect`. | File upload with progress, Drag-and-drop upload |
| `input-mask` | Wrap a masking library (IMask/Cleave) and keep the unmasked value in a hidden field for the server. | Masked inputs |
| `autogrow` **(new)** | Size a `<textarea>`/`<input>` to its content, no-oping entirely when `CSS.supports("field-sizing", "content")`. Sunsetting — see note below. | Textarea autogrow |

### Collection primitives

| Primitive | Contract | Used by |
|---|---|---|
| `sortable` | Wrap SortableJS and PATCH the new position to `data-sortable-url-value`; `data-sortable-group-value` for cross-container drags. | Drag-and-drop reordering, Kanban board, Tree / nested list, Nested forms |
| `selection` | Manage a checkbox group with select-all, indeterminate state, a count `output`, and toolbar enable/disable. | Bulk selection + bulk actions toolbar, Data grid editing, Submit-on-change |
| `chart` | Wrap a charting library, reading data from a value or a `<script type="application/json">` target, and destroying the instance on `disconnect`. | Charts (Chart.js), Live dashboards, Maps |

### Utility primitives

| Primitive | Contract | Used by |
|---|---|---|
| `relative-time` | Render and self-update a relative timestamp from a `datetime` attribute; prefer `<relative-time>` from `@github/relative-time-element`. | Self-updating relative timestamps, Live chat, Notification bell, Live dashboards, Autosave |
| `confirm` | Return a promise from a `dialog`-based confirmation, installed as `Turbo.config.forms.confirm` — never `Turbo.setConfirmMethod()`. | Custom confirm dialogs, Dirty-form warnings, Bulk actions toolbar, Nested forms, Collaborative editing |
| `clipboard` | Copy text from a `source` target or `data-clipboard-text-value` and show success feedback for a fixed interval. | Clipboard copy, Export triggers, Search-as-you-type |
| `countdown` | Tick down to the timestamp in `data-countdown-deadline-value` and dispatch an action at zero. | Countdown timers, Idle / session timeout warning, Live dashboards |

### Conventions, not primitives

These recur throughout the document but are patterns, mixins, or platform features — do **not** create a controller for any of them.

- **Debouncing and throttling.** The stimulus-use `useDebounce` / `useThrottle` mixins, or a debounced method behind an action option. There is no `debounce` controller, and a per-instance `Date.now()` guard is often enough.
- **The wrapped-library teardown contract.** Every controller that instantiates a third-party library follows one shape: keep stable handler references, then in `disconnect()` unbind your listeners, call the library's `destroy()`/`off()`, null out references, and release object URLs, timers, and observers. This is the number-one bug in Stimulus library wrappers, because Turbo's cached snapshots make every missed teardown a per-visit leak. It is a code shape every wrapper implements, not a primitive one composes with. See "The wrapped-library teardown contract" in the rich-inputs section.
- **Turbo-native attributes.** `data-turbo-permanent`, `data-turbo-action="advance"`, `data-turbo-frame`, and `loading="lazy"` on frames replace whole categories of controller. A lazy `<turbo-frame>` is the answer to deferred loading — never a `content-loader` or `lazy-load` controller.
- **Morphing.** `<meta name="turbo-refresh-method" content="morph">` plus `broadcasts_refreshes` obsoletes hand-rolled per-mutation streams. Reach for it before writing any list-sync JS.
- **ARIA live regions.** An `aria-live="polite"` element that the server or an existing primitive writes into. Announcement is a markup decision, not an `announce` controller.
- **Singleton app controllers.** Offline banners, print buttons, video players, and map wrappers are legitimate controllers — they are just app-specific, instantiated once, and compose *with* the vocabulary rather than joining it.

### Rejected / merged proposals

| Proposed | Verdict | Rationale |
|---|---|---|
| `date-picker` | Reject — convention | One library, one job, used by exactly one pattern; it is an instance of the wrapped-library teardown contract, not shared vocabulary. |
| `cropper` | Reject — convention | Same: a cropperjs wrapper writing a rect to hidden fields, used once. Ship it as an app controller following the teardown shape. |
| `signature-pad` | Reject — convention | Same: a signature_pad wrapper producing a Blob for `direct-upload`, used once. |
| `password-strength` | Reject — convention | A zxcvbn wrapper writing into a `<meter>`; the reusable halves are already `char-count` and an `aria-live` region. |
| `print` | Reject — too specific | One method call (`window.print()`); its own author wrote "none worth naming". An app controller at most. |
| `connection` | Reject — app singleton | Genuine behavior, but an app has exactly one offline banner. Instantiated once and composed with `transition` + `timeout` in one place, it is a component, not vocabulary. |
| `save-indicator` | Merge → `sync` | Never appeared in a single `Decomposition.` line, including its proposer's. Reflecting `turbo:submit-start`/`turbo:submit-end` into an `<output>` is `sync` plus two action attributes. |
| `remote-validate` | Merge → `autosubmit` | Closest call. Per-field validation is `autosubmit` scoped by `formaction`/`formmethod` to a validation URL, with an unchanged-value guard; the section's own zero-JS variant proves the composition works. |
| `activate` | **Accept** | Genuinely generic: "treat this event as a click on that element." Its real value is keeping `intersection` a pure observer instead of growing navigation opinions. |
| `interval` | **Accept** | Sits *beside* `timeout`, does not subsume it: `timeout` fires once and never re-arms. Polling, heartbeats, and dashboards all need a repeating, visibility-aware timer. Both stay. |
| `cable-channel` | **Accept** | The only sanctioned escape hatch below Turbo Streams; generic over channel name and params, and re-dispatching payloads as DOM events keeps consumers plain Stimulus. |
| `autoscroll` | **Accept** | Non-obvious correctness (near-end detection, wrapping `event.detail.render`) that is identical for chat, logs, and any bottom-anchored feed. |
| `file-preview` | **Accept** | Library-free, applies to any `<input type="file">`, and carries a real correctness contract — revoking object URLs on disconnect — that is otherwise reimplemented and forgotten. Does not overlap `sync`: it renders derived DOM from a `FileList`, it does not mirror a value. |
| `autogrow` | **Accept (sunsetting)** | Generic and library-free, but `field-sizing: content` is Baseline as of June 2026 and the controller no-ops on every current engine. Ship the CSS; keep this only for older-browser support and plan to delete it. |

**On library wrappers generally.** `chart`, `sortable`, and `input-mask` are library wrappers that *did* earn vocabulary entries, which looks inconsistent next to the four rejections above. The discriminator is cross-feature reuse, not purity: `chart` and `sortable` are each composed into unrelated features in three or four different sections, while `date-picker`, `cropper`, `signature-pad`, and `password-strength` were each used exactly once, in the single pattern that proposed them. `input-mask` is the honest marginal case — one use, kept because it was in the original vocabulary and masking recurs across any form-heavy app. If it is still at one use after the next batch of patterns, demote it.

### Drift to fix

None — the vocabulary held. All 32 original primitives were used at least once, no section invented a synonym for an existing name, and none of the explicitly banned names (`toggle`, `modal`, `dropdown`, `autocomplete`, `lazy-load`, `local-storage`) was used as a primitive. The near-misses below are correct usage, recorded so a later reader does not "fix" them:

- `` `toggle` `` in section A, line 540 and section A, line 549 — the DOM `toggle` event of `<details>`, not a controller. Correct.
- `` `toggle` `` in section F, lines 516 and 1959 — naming tailwindcss-stimulus-components' and stimulus-components' own controllers in **Prior art**. Correct.
- `` `content-loader` `` in section A, line 313 and section E, lines 169 and 270 — all three explicitly reference the stimulus-components package to say a lazy `<turbo-frame>` supersedes it. Correct, and worth keeping.
- `` `announce` `` in section C, line 307 — used adjectivally ("an `announce`-style `aria-live` region"), not proposed as a controller. Left as a convention above; if a later section starts composing with it as a primitive, revisit.
