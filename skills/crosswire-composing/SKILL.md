---
name: crosswire-composing
description: "Composite widgets in a Rails app that has the crosswire gem — use when asked for a modal, dropdown, drawer, toast, wizard, or any other multi-part widget: name it, decompose it into shipped cw.* primitives, and wire them by stacking attrs merges, shipping no new controller."
---

crosswire deliberately ships no `modal` controller. A modal is five primitives in a
trenchcoat — `dialog` + `focus-trap` + `scroll-lock` + `dismiss` + `transition` — and
each is independently useful elsewhere. Composites are built the same way every time:

1. **Name the composite, then decompose it.** Try the name on the builder —
   `cw.modal`, `cw.dropdown`, `cw.tooltip` raise a `NoMethodError` that states the
   decomposition (or the platform feature that makes the whole thing unnecessary).
   [`RECIPES.md`](RECIPES.md) holds worked decompositions; `confirm` in the gem itself
   is a shipped example (`cw--dialog` + `cw--confirm` stacked on one `<dialog>`).
2. **Stack the pieces with `cw_attrs`.** Pass each primitive's `*_attrs` hash into one
   `cw_attrs(...)` call on the shared element — the merge appends `data-controller`
   and `data-action` rather than clobbering, and is idempotent, so stacking is safe at
   any depth.
3. **Place each controller where its own targets live** (R5b in the gem's
   `docs/DECISIONS.md` / `docs/COMPONENT_CONTRACT.md`). Stimulus scopes targets to
   descendants of the `data-controller` element, so two primitives with
   differently-shaped target sets cannot always share one element: a wide-rooted
   primitive (`tabs` needs tab *and* panel targets) sits on a wrapper, a
   narrow-scoped one (`roving-focus`'s `keydown` must not hijack form fields inside
   panels) sits on the inner element — presenters expose split methods
   (`state_attrs` / `action_attrs`) for exactly this. The tell for wrong placement is
   a silently empty target set: no error, a widget that does nothing.
4. **Wire the moments between stacked controllers** with R5a's three mechanisms —
   a real DOM event backs the moment: bind both actions to it
   (`data-action="click->cw--confirm#confirm click->cw--dialog#close"`); no DOM event:
   write the sibling's value attribute (the same external write path a morph takes);
   reacting to the sibling's state: listen for its namespaced event
   (`action("cw--dialog:closed->closed")`). Method calls between stacked controllers
   are the coupling the events exist to avoid.

## Worked example — the modal

```erb
<%= cw.dialog_for id: "invite-member" do |d| %>
  <div <%= cw_attrs(d.root_attrs) %>>
    <button <%= cw_attrs(d.trigger_attrs, class: "btn") %>>Invite a member…</button>

    <dialog <%= cw_attrs(
              d.panel_attrs,
              cw.scroll_lock_attrs,
              cw.transition_attrs(enter: "fade-in", leave: "fade-out"),
              class: "modal") %>>
      <h2 <%= cw_attrs(d.title_attrs) %>>Invite a member</h2>
      <%= form_with model: Invitation.new do |f| %>...<% end %>
      <button <%= cw_attrs(d.close_attrs) %>>Cancel</button>
    </dialog>
  </div>
<% end %>
```

`dialog` owns open/close and `showModal()`; `scroll-lock` and `transition` stack on
the `<dialog>` element; dismissal on Escape and the close button is `dialog`'s own.
`focus-trap` completes the five — but its Rule 0 exempts a native `<dialog>` opened
with `showModal()`, which already traps focus, so it joins the stack only when the
surface is non-modal (see the drawer recipe). Before merging, read each piece's
helper docstring (`"$(bundle show crosswire)"/app/helpers/crosswire/`) for its
current options — presenter options are looked up, not recited.

## Done when

The composite ships with **zero new controllers** — every behaviour on the page is a
`cw--*` primitive or an existing app controller, and every stacked element's targets
resolve (exercise each moment: open, close, dismiss, keyboard). If some step
genuinely cannot be expressed as a stack of primitives, that step is a new
*primitive*, not a bigger composite: switch to the `crosswire-authoring` skill for
that one piece and keep the rest composed.
