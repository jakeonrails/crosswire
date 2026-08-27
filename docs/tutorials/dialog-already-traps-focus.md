# Focus leaks out of your modal, or your focus-trap breaks Escape

You open a modal, tab through the form inside it, and focus walks straight out the back — into a nav link behind the overlay, into a button you can't see. Or the opposite bug: you installed `focus-trap` (or hand-rolled a `keydown` listener that cycles `Tab` between the first and last focusable child) and now Escape does nothing, or a screen reader user tabs into the page behind the overlay and starts reading stale content the sighted user can't see. You didn't do anything wrong, exactly — this is the standard advice from every 2021 modal tutorial. It's also unnecessary work solving a problem the platform already solved.

Use `<dialog>`, opened with `showModal()`. No focus-trap library, no keydown listener.

```html
<dialog id="invite-dialog">
  <h2 id="invite-dialog-title">Invite a member</h2>
  <form method="post" action="/invitations">
    <label for="invite-email">Email</label>
    <input id="invite-email" name="email" type="email" autofocus required>
    <button type="submit">Send invite</button>
    <button formmethod="dialog">Cancel</button>
  </form>
</dialog>

<button id="invite-trigger" type="button">Invite a member…</button>

<script>
  const dialog = document.getElementById("invite-dialog")
  document.getElementById("invite-trigger").addEventListener("click", () => dialog.showModal())
</script>
```

`formmethod="dialog"` (or a plain `<form method="dialog">`) closes the dialog client-side with no JavaScript at all. Leave that Cancel button as a submit button — `formmethod` is only read on submit buttons, so adding `type="button"` to it silently turns the close into a no-op. `dialog.close()` does the same thing from a script. Either way, closing removes the dialog from the top layer and returns focus to whatever had it before `showModal()` ran — you don't write that part.

`showModal()` puts the `<dialog>` in the browser's *top layer* — the same rendering layer as fullscreen video and native `<select>` popups — which is why it paints above everything else with no `z-index` war, and why it gets a `::backdrop` pseudo-element for free (`dialog:modal { position: fixed; … }` is in the UA stylesheet, per the WHATWG rendering spec). More importantly, opening it blocks the rest of the document: everything outside the dialog becomes `inert` per spec — not just visually dimmed, but genuinely unfocusable, unclickable, and hidden from assistive tech. A `<button>` outside an open modal cannot take focus even if you call `.focus()` on it programmatically. That's the whole bug class a focus-trap library exists to prevent, closed at the browser level. Escape closes the topmost dialog for free too.

Tab cycles only among the dialog's own focusable descendants, and it's allowed to leave into browser chrome — the URL bar, the tab strip — and back again. That's correct: it's the same thing that happens with a native `<select>` or the browser's own find-in-page bar. A JS focus trap that blocks it is behavior the platform deliberately doesn't have, not a bug you're fixing.

One thing `showModal()` does *not* decide for you: which element gets focus first. Without an `autofocus` attribute, the browser focuses the first focusable descendant, which is often a close "×" button — usually not what you want. Put `autofocus` on the field the user should type into, as in the email input above.

`showModal()`'s inertness is a modal `<dialog>` feature specifically — it doesn't apply to a `<div class="drawer">`, a Popover-API panel opened with `show()` instead of `showModal()`, or any other non-modal overlay. Those still need a real focus trap, because nothing makes the rest of the page inert for them. If you're building a drawer or toolbar out of crosswire, that's `cw.focus_trap_for` — see its helper at `app/helpers/crosswire/focus_trap_helper.rb`.

If your app has crosswire, you don't write even the `showModal()` call:

```erb
<%= cw.dialog "Invite a member", id: "invite-dialog", trigger_label: "Invite a member…" do %>
  <%= form_with model: Invitation.new do |f| %>
    <%= f.label :email %>
    <%= f.email_field :email, autofocus: true, required: true %>
    <%= f.submit "Send invite" %>
  <% end %>
<% end %>
```

`cw.dialog` renders a real `<dialog>` — same element, same inertness, no focus-trap primitive stacked on it, exactly per its presenter's Rule 0. It adds three things the bare element doesn't give you. Scroll lock: the platform still doesn't do this, `whatwg/html#7732` has been open since 2022, and the page behind your `<dialog>` keeps scrolling on wheel or touch without it. Focus restore to the invoker on close. And a guard against a real Turbo 8 hazard — Idiomorph's attribute sync has no special case for `open`, and removing `open` doesn't implicitly call `close()`, so a background morph on an open dialog leaves the top layer blocking the whole page while `close()` is reduced to a silent no-op (`turbo#1239`, open since 2024). The controller cancels that attribute removal and closes the dialog itself on `turbo:before-cache`, so a cached page snapshot never depicts a live modal as dead markup.
