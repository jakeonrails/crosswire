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

**Rule 0, read this first: a list of navigation links is not a menu.** `role="menu"`
obligates you to remove every item from the Tab sequence, implement Up/Down/Home/
End/typeahead, move focus into the panel on open, close on activation, and return
focus — APG's own Disclosure Navigation example says the menu role is wrong for a
link list, because it doesn't provide the complex functionality assistive technology
expects from that role. So "dropdown" is two different recipes depending on what's
inside, not one:

**Navigation links** — `popover`, plain `<a>` elements, **no** `role="menu"`, zero
JavaScript beyond what `cw.popover` already ships:

```erb
<%= cw.popover_for id: "profile-menu" do |p| %>
  <button <%= cw_attrs(p.trigger_attrs) %>>Account</button>
  <div <%= cw_attrs(p.panel_attrs) %>>
    <%= link_to "Settings", settings_path %>
    <%= link_to "Sign out", logout_path, data: { turbo_method: :delete } %>
  </div>
<% end %>
```

**Commands** (Duplicate, Archive, Delete) — `cw.menu`, which composes `popover` +
`roving-focus` + the `role="menu"` semantics for you; nothing here is hand-assembled:

```erb
<%= cw.menu "Actions", id: "row-42-menu", items: [
      { label: "Duplicate", value: "duplicate" },
      { label: "Archive", value: "archive" },
      { label: "Delete", value: "delete" }
    ] %>
```

For a `button_to`-shaped item (a DELETE with CSRF), use `cw.menu_for` instead — see
`Crosswire::Presenters::Menu`'s docstring for the compose-it-yourself form.

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
