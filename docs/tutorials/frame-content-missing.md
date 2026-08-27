# You click a link inside a turbo-frame and the frame goes blank

The Network tab shows a clean 200. Your server logs show the action ran, rendered something, and returned. But the frame on screen doesn't update — it now holds one bold line, **Content missing**, or if you weren't watching closely it just looks like the click did nothing. The console has the actual explanation:

```
The response (200) did not contain the expected <turbo-frame id="invoice_42">
and will be ignored. To perform a full page visit instead, set
turbo-visit-control to reload.
```

Nothing crashed. Nothing failed the HTTP request. Turbo got a perfectly good response and threw it away, because the one thing it was looking for wasn't in it.

Here's the shortest honest fix, for the most common cause: the target action rendered a page that never wraps its content in a frame with the id Turbo asked for.

```erb
<%# app/views/invoices/index.html.erb %>
<% @invoices.each do |invoice| %>
  <%= turbo_frame_tag invoice do %>
    <%= invoice.number %> — <%= invoice.status %>
    <%= link_to "Edit", edit_invoice_path(invoice) %>
  <% end %>
<% end %>
```

```erb
<%# app/views/invoices/edit.html.erb — the missing half %>
<%= turbo_frame_tag @invoice do %>
  <%= render "form", invoice: @invoice %>
<% end %>
```

`turbo_frame_tag invoice` on the index and `turbo_frame_tag @invoice` on the edit page both resolve through `dom_id` to `"invoice_42"` for the same record. That match is the whole fix — not a coincidence you're relying on, a contract you're fulfilling.

**Why this works.** Turbo swaps a frame's contents only when the response body contains a `<turbo-frame>` element whose `id` matches the *requesting* frame's id, exactly. Everything else in the response — the rest of the HTML, the status code, whether the server considers the request a success — is irrelevant to this one check. A 200 doesn't mean "good response" to Turbo; it means "a response arrived," and then Turbo goes looking for one specific tag. If it isn't there, Turbo marks the frame complete, writes the `Content missing` placeholder into it, and throws a `TurboFrameMissingError` — this is Turbo 7.3+'s deliberate behavior, not a bug. (Older answers claiming Turbo silently falls back to a full-page visit describe the pre-7.3 behavior; that automatic fallback was removed, which is why upgrading from turbo-rails 1.3 to 1.4 broke a lot of frames that "used to just work.")

The id goes missing for one of three reasons, in order of how often you'll hit them. First, the one above — the action renders a template that was never wrapped in a matching frame at all, or only wraps the success path and forgets the re-render on validation failure. Second, a redirect: the frame's fetch request gets redirected to a page that doesn't have that frame. A session timeout bouncing an edit request to the sign-in page is the classic case. Because `fetch` follows redirects transparently, Turbo only ever sees the final response, never the redirect itself. Third, the id itself drifts: `turbo_frame_tag @invoice` and `turbo_frame_tag Invoice` resolve to different ids (`invoice_42` versus `new_invoice`), or a controller's custom `layout` method returns a static layout name and skips Turbo's `turbo_rails/frame` layout for frame requests. That last one usually produces two frames with the same id in one response — the layout's and the template's — and Turbo takes the first match in document order, which may not be the one holding your content.

Once the frame is rendering correctly, you'll sometimes want the opposite — a link inside a frame that should escape it and do a real navigation. Set that on the frame itself if it's the default for everything inside:

```erb
<%= turbo_frame_tag "invoice_42", target: "_top" do %>
  <%= render "invoice", invoice: @invoice %>
<% end %>
```

or on one link, to retarget just that link without changing the frame's default:

```erb
<%= link_to "Full invoice page", invoice_path(invoice), data: { turbo_frame: "_top" } %>
```

The redirect case needs its own fix, because the server can't fix a page that legitimately has no frame on it. Mark pages that should never render inside a frame — sign-in, most of all:

```erb
<%# app/views/sessions/new.html.erb %>
<% turbo_page_requires_reload %>
```

That helper writes `<meta name="turbo-visit-control" content="reload">` through `provide :head`, so your layout needs `<%= yield :head %>` inside `<head>` or the meta never lands and nothing changes. With it present, Turbo checks the response before it goes looking for the frame, sees the destination isn't a valid frame target, and does a full page visit instead of quietly discarding the response. For anything you can't tag ahead of time, handle the event directly — `turbo:frame-missing` is cancelable and fires before Turbo writes its own placeholder:

```js
// app/javascript/frame_missing.js
document.addEventListener("turbo:frame-missing", (event) => {
  const { detail: { response, visit } } = event
  event.preventDefault()
  visit(response) // escalate the response we already fetched into a full page visit
})
```

`preventDefault()` stops both the `Content missing` text and the thrown error; `detail.visit` lets you turn the response you already have into a normal navigation instead of asking the browser to fetch it again.

The fastest way to confirm any of this without opening dev tools: Turbo sends the frame's id as a `Turbo-Frame` request header, so curl can ask for exactly what your frame asked for.

```bash
curl -s -H "Turbo-Frame: invoice_42" http://localhost:3000/invoices/42/edit \
  | grep -o '<turbo-frame[^>]*>'
```

No `<turbo-frame id="invoice_42">` in the output is the bug, confirmed in one command. If you suspect the redirect case, check headers instead of body:

```bash
curl -sI -H "Turbo-Frame: invoice_42" http://localhost:3000/invoices/42/edit \
  | grep -i location
```

A `Location:` line means the response never got a chance to have a frame — you're following it somewhere else first.

One more honest note: this same event fires when the target action 500s, and by default that's exactly as unhelpful as a mismatched id — the same two words, no indication of what broke, easy to miss on a lazily loaded frame that just sits there. Crosswire ships that as an actual failure state instead of a placeholder: `cw.fallback_attrs` wires `turbo:frame-missing` (along with fetch errors) into a tri-state indicator, so a broken frame shows a real "couldn't load this" message with a retry action rather than two words nobody reads.

None of this gives the server a way to decide, per response, that *this* redirect should break the frame open — `target="_top"` and `data-turbo-frame` are both decided ahead of time, on the frame or the link, because a fetch response mid-redirect is one browsers deliberately won't let Turbo inspect. That's a five-year-old open design gap (`turbo#257`, `turbo-rails#367`), not something you're missing. What production apps actually ship instead is a custom stream action — `Turbo.StreamActions.redirect = function () { Turbo.visit(this.getAttribute("target")) }`, rendered on the success branch only; `docs/recipes/frame-breakout.md` has the full version.
