# Composite recipes

Each recipe names the primitives and where each sits. Options change release to
release — read each piece's helper docstring
(`"$(bundle show crosswire)"/app/helpers/crosswire/<name>_helper.rb`) before wiring.
The modal recipe is worked in full in [`SKILL.md`](SKILL.md).

## Drawer (slide-over panel)

`dialog` (non-modal) or your own panel + `focus-trap` + `scroll-lock` + `dismiss` +
`transition`. Unlike the modal, a drawer is usually *not* a native modal `<dialog>`,
so `focus-trap` earns its place here:

```erb
<%= cw.focus_trap_for active: @drawer_open, initial: "#drawer-heading" do |t| %>
  <div <%= cw_attrs(
            t.root_attrs,
            cw.scroll_lock_attrs(active: @drawer_open),
            cw.transition_attrs(enter: "slide-in", leave: "slide-out"),
            cw.dismiss_attrs(escape: true),
            class: "drawer") %>>
    <h2 id="drawer-heading" tabindex="-1">Filters</h2>
    ...
  </div>
<% end %>
```

All four stack on the one panel element — their target sets are all root-scoped, so
sharing is safe (R5b).

## Dropdown menu

`popover` + `roving-focus` + `dismiss` + `click-outside`. Placement matters here:
`popover`'s controller lives on the panel (trigger and panel are linked by id via
`popovertarget`, no shared ancestor needed), and `roving-focus` sits on the menu list
so its `keydown` handling stays scoped to the items:

```erb
<%= cw.popover_for id: "actions-menu" do |p| %>
  <button <%= cw_attrs(p.trigger_attrs) %>>Actions</button>
  <div <%= cw_attrs(p.panel_attrs, cw.click_outside_attrs, cw.dismiss_attrs(escape: true)) %>>
    <%= cw.roving_focus_for orientation: "vertical" do |r| %>
      <div <%= cw_attrs(r.root_attrs) %> role="menu">
        <% actions.each_with_index do |action, i| %>
          <button <%= cw_attrs(r.item_attrs(current: i.zero?)) %> role="menuitem">
            <%= action %>
          </button>
        <% end %>
      </div>
    <% end %>
  </div>
<% end %>
```

Rule 0 note: for a plain disclosure-style menu with no keyboard roving, the bare
`popover` attribute alone may be the whole widget.

## Toast / flash message

`dismiss` + `transition` + `timeout` on one element — the R6 reference seam:
`transition` intercepts `dismiss`'s cancelable event so the node can animate before
`remove()`:

```erb
<div <%= cw_attrs(
          cw.transition_attrs(leave: "fade", leave_from: "opacity-100", leave_to: "opacity-0"),
          cw.dismiss_attrs,
          cw.timeout_attrs(delay: 5000),
          data: { action: "cw--timeout:elapsed->cw--dismiss#dismiss
                           mouseenter->cw--timeout#cancel" },
          class: "toast", role: "status") %>>
  Saved.
</div>
```

`timeout` fires once and dispatches `cw--timeout:elapsed`; the `data-action` line is
R5a mechanism 3 — reacting to a stacked sibling's namespaced event — and the merge
appends it to the actions the presenters already emitted. Rendered from a layout
flash loop or pushed by a Turbo Stream append — either way it is markup, so a
broadcast toast costs nothing extra.

## Confirm flow (destructive action guard)

Ships composed: `confirm` already stacks `cw--dialog` + `cw--confirm` on one
`<dialog>` — use `cw.confirm` / `cw.confirm_for` directly rather than re-deriving it.
Its presenter docstring documents the `Turbo.config.forms.confirm` wiring for
intercepting `data-turbo-confirm` links and buttons app-wide. It is also the shipped
proof of the R5a mechanisms: Confirm/Cancel share DOM events with `cw--dialog`
(mechanism 1), and programmatic opening writes `data-cw--dialog-open-value` directly
(mechanism 2).

## Wizard (multi-step form)

Rule 0 first: steps are pages — a `<turbo-frame>` per step with server-rendered
progress needs zero JavaScript and survives reload/back natively. Compose primitives
only for the in-page polish: `dirty-form` (warn on abandon), `autosubmit` (persist a
step on change), `loading` on the frame, `reveal`/`transition` for step entrances. A
"wizard controller" holding step state client-side is the anti-pattern — the server
already knows the step.
