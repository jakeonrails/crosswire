# Survivability — preserve, loading/fallback, authorized streams

The tier that makes Hotwire safe under Turbo 8 morphing and multi-worker broadcasts.
Each piece has its own Rule 0 — apply it before wiring the piece. Full evidence:
`docs/DECISIONS.md` D7 and `docs/BUILD-LOG.md` in the gem
(`"$(bundle show crosswire)"/docs/`).

## `preserve` — state that must outlive a morph

Turbo 8 morphing overwrites `data-*-value` attributes and skips `connect()`
(turbo#1210, closed won't-fix), so client-owned state is clobbered mid-morph by default.

**Rule 0, in order:** (1) persist the state server-side — session, URL, a preferences
model — so the morph converges *toward* the state you want and the conflict evaporates
(often a UX win: survives reload, shareable URL); (2) narrow the update instead —
`turbo_stream.replace(target, method: :morph)` touches only the changed subtree, so
nothing outside it needs protecting. Reach for `preserve` only for state the server
genuinely cannot know (is this menu open right now?) or attributes a third-party
library writes at runtime.

```erb
<%# protect named attributes on an element another controller owns %>
<div <%= cw_attrs({data: {controller: "tom-select"}},
          cw.preserve_attrs(attributes: "data-selected")) %>>

<%# or exempt the whole subtree from morph passes (data-turbo-permanent, morph-scoped) %>
<div <%= cw_attrs({data: {controller: "leaflet-map"}}, cw.preserve_attrs(element: true)) %>>
```

For a controller you own, prefer `usePreserve` from `"crosswire/morph"`
(`static preservedValues` / `static preservedAttributes` on the class — no markup
wiring); see that module's docstring. `preserve` only cancels a morph where the live
value actually diverged, so untouched attributes stay the server's to update.

## `loading` — a visual signal for every in-flight request

`cw.loading_attrs` on the scope that submits or fetches (a form, a `<turbo-frame>`, a
row, `<body>`). While a request is in flight the scope carries the bare `data-loading`
attribute — deliberately Livewire's attribute name, so Tailwind's `data-loading:`
variants work verbatim; crosswire ships no CSS, you style it:

```erb
<%= form_with model: @order, **cw_attrs(cw.loading_attrs) do |f| %>...<% end %>
<style>[data-loading] { opacity: 0.6; }</style>
```

## `fallback` — a declared failure state for anything that can fail

Tri-state ok/loading/failed for lazy frames, submissions and stream connections. Use
`cw.fallback_for` and build all regions from the ONE yielded presenter — its
`loading_attrs`/`failed_attrs`/`source_attrs` read the same `state`, which keeps them
in sync (see the helper docstring for the full lazy-frame example with a retry button
wired to `click->cw--fallback#retry`).

## Streams — authorize the subscriber, order the broadcasts

Plain `turbo_stream_from` signs the stream **name**: it stops a client inventing
`Board:99`, but says nothing about who may hold a legitimate name. Any
`broadcast_replace_to` also rides Action Cable, which promises nothing about delivery
order — two workers can deliver v2 then v1 and the page sticks on stale content.

**Subscription:** `cw.stream_from` requires an explicit channel and refuses the
unauthorized default:

```erb
<%= cw.stream_from @board, channel: BoardChannel %>
```

```ruby
class BoardChannel < Crosswire::AuthorizedStreamChannel
  private

  def authorized?(board, *) = board.is_a?(Board) && current_user&.can_read?(board)
end
```

`AuthorizedStreamChannel` **fails closed** — the shipped default rejects everyone, and
`cw.stream_from` raises in development/test if `authorized?` was never overridden, so
the mistake is loud at dev time. A channel gates subscription only; it never sees the
broadcast HTML. A payload that differs per viewer must be **sharded per audience** (one
stream per user/role/tenant) or replaced with `broadcasts_refreshes` — authorizing
harder on a shared payload is the wrong layer.

**Ordering:** `versioned_replace` carries a monotonic version on the partial's root
element; a client already holding a newer-or-equal version discards the stale
broadcast — which also neutralizes the self-echo flicker (a tab receiving its own
broadcast back).

**Rule 0 first:** `broadcasts_refreshes` makes a stale render structurally impossible
(it pushes a refetch signal, not HTML — nothing to reorder). Choose
`broadcast_replace_to` + `versioned_replace` only for a *measured* load or latency
reason.

```erb
<%# the partial that renders both page and broadcast — one write site for the version %>
<div id="<%= dom_id(widget) %>" <%= cw_attrs(cw.version_attrs(widget)) %>>
```

```ruby
# the model, alongside Turbo::Broadcastable
include Crosswire::Streams::Versioned
after_update_commit { broadcast_versioned_replace_to board, target: dom_id(self),
                      partial: "widgets/widget", locals: { widget: self } }
```

Version floors: `@hotwired/turbo` ^8.0.14, `turbo-rails` 2.0.23 — below either, the
functions this tier calls are not exported.
