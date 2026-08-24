---
name: crosswire-ui
description: "Crosswire UI work — use when building or changing views in a Rails app that has the crosswire gem: before writing any JavaScript for a UI behaviour (Rule 0), when wiring a cw.* primitive at one of its three levels, or when a page faces Turbo 8 morphing, in-flight/failing requests, or Action Cable broadcasts."
---

crosswire ships composable Hotwire primitives behind one builder — `cw` (canonical
`crosswire`) — reached from any view the way `tag.` and `turbo_stream` are. This skill
covers using what ships. For a composite widget (modal, dropdown, drawer, toast,
wizard…), use the `crosswire-composing` skill; for a genuinely new behaviour, use
`crosswire-authoring`.

## Rule 0 — before any JavaScript

Check, in order, before writing or wiring any JS for a UI behaviour:

1. **Platform**: `<details>`, `<dialog>` + `showModal()`, `popover`, CSS
   `field-sizing: content`, anchor positioning, the `title` attribute.
2. **Server**: a Turbo Frame (lazy `src`), a Turbo Stream, a redirect.
3. **An existing primitive**: the `cw.` vocabulary (discovery below).

41 of the 119 UI patterns crosswire catalogued need zero JavaScript; every presenter's
docstring opens with when *not* to use it. The step is done when you can name which of
the three answered — or state that all three failed, which is the trigger for
`crosswire-authoring`.

## Discover the vocabulary from the gem, not from memory

The primitive list grows release to release — look it up, never recite it:

```bash
gem_dir="$(bundle show crosswire)"
ls "$gem_dir"/app/helpers/crosswire/        # one helper per primitive
```

- Each helper's docstring carries the worked ERB for that primitive; each presenter
  (`"$gem_dir"/lib/crosswire/presenters/<name>.rb`) documents its options and its
  Rule 0.
- A guessed or misremembered `cw.` name is safe to try: the builder's `NoMethodError`
  lists every primitive, and `cw.modal` / `cw.dropdown` / `cw.tooltip` explain the
  composition or the platform feature to use instead.
- `"$gem_dir"/docs/` holds the contract, decisions, corrections and diagnosis recipes.

## Wiring a primitive — three levels

Every primitive exposes `cw.<name>_for` and `cw.<name>_attrs`; widgets that own markup
additionally get the bare `cw.<name>`. Pick the highest level that fits the markup you
need:

```erb
<%# 1 — batteries: renders the shipped, ejectable partial (widgets only) %>
<%= cw.disclosure "Shipping details", id: "shipping" do %>...<% end %>

<%# 2 — compose: yields the presenter; your structure, crosswire's attributes %>
<%= cw.disclosure_for id: "faq-1" do |d| %>
  <div <%= cw_attrs(d.root_attrs) %>>
    <%= tag.button "Details", **d.trigger_attrs %>
    <%= tag.div(**d.panel_attrs) { "…" } %>
  </div>
<% end %>

<%# 3 — your markup entirely: bare attribute hashes on any element structure %>
<% d = cw_presenter(:disclosure, id: "faq-1") %>
<details <%= cw_attrs(d.root_attrs) %>>...</details>
```

`cw_attrs` and `cw_presenter` are view-level utilities, called directly — not through
`cw.`. The merge **composes**: pass `data: { controller: "analytics" }` and you get
`data-controller="cw--disclosure analytics"`; a `!` suffix (`"controller!" => "mine"`)
forces replacement; the merge is idempotent, so it is safe at every layer.

Done when every `data-cw--*` attribute on the page came out of a presenter
(`cw.*` / `cw_presenter`) — the presenter owns ids, ARIA and state wiring, and
hand-typed copies drift the moment the gem updates.

## Making it survive production

Wire these at build time, not after the bug report — each covers a failure mode Turbo
does not answer on its own. When any row fires, read
[`SURVIVABILITY.md`](SURVIVABILITY.md) before wiring:

| The page has… | Reach for |
|---|---|
| Turbo 8 morphing over client-owned state (an open menu, a third-party widget's attributes) | `preserve` |
| A lazy frame, a form, or a stream connection that can be in flight or fail | `loading` + `fallback` |
| Any `broadcast_replace_to` | `cw.stream_from` + an authorized channel, and `versioned_replace` |
