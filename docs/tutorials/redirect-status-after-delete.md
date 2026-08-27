# The redirect status that silently breaks every DELETE link in Rails 7+

You click Delete on an invoice. It disappears — the record's gone, no error banner, nothing red on
screen. The Rails log backs you up: a clean `302 Found` to the invoices index, exactly like a `destroy`
action is supposed to produce. Then the very next line: `ActionController::RoutingError (No route
matches [DELETE] "/invoices")`. Your redirect worked, and then Turbo deleted your homepage.

The fix is one word:

```ruby
def destroy
  @invoice.destroy!
  redirect_to invoices_path, status: :see_other
end
```

That's the whole change. Every `redirect_to` reached from a `destroy` or `update` action needs
`status: :see_other` — not the Rails default, which is a bare 302.

Here's why a status code you've never thought about suddenly matters. Turbo submits forms through
`fetch`, and `fetch` follows redirects according to a fixed algorithm in the Fetch spec, not
browser common sense. That algorithm only rewrites the method to GET in two cases: the original method
was POST and the status is 301 or 302, or the status is 303, period, regardless of what you sent. DELETE
isn't POST, so a 302 doesn't touch it — the browser reissues the exact same DELETE against whatever URL
you redirected to. 303 See Other is the only status the spec defines as "always switch to GET." This is
standards-conformant behavior, not a Turbo bug (SO 70498371, Rails forum 79810, turbo-rails#259).

Nobody hit this under rails-ujs, because rails-ujs never sent a real DELETE. A `method: :delete` link
built a hidden form with a `_method=delete` field and called the browser's native `form.submit()` — an
honest POST on the wire, full-page navigation, with Rails' middleware faking the verb server-side. POST
is the one method a 302 does downgrade to GET, so the whole bug class was invisible for a decade — every
app was accidentally hitting the one case the spec rewrites. Turbo doesn't build a fake form; it fetches a
real DELETE. The spec's actual rules apply, possibly for the first time in your app's history.

This is also why `link_to "Delete", invoice, method: :delete` stopped working: `method:` was rails-ujs
syntax, and no Rails 8 app ships rails-ujs by default (turbo-rails#259). Reach for `button_to` instead — it
renders a real `<form method="post">` with a `_method` override, which both Rails and assistive
technology understand as a destructive action rather than a navigation:

```erb
<%= button_to "Delete", invoice, method: :delete, data: { turbo_confirm: "Delete this invoice?" } %>
```

If you genuinely need an `<a>` — inline in a menu, styled to match surrounding links — Turbo ships its
own replacement attribute:

```erb
<%= link_to "Delete", invoice, data: { turbo_method: :delete, turbo_confirm: "Delete this invoice?" } %>
```

Either way, the controller still needs `status: :see_other`. The link-versus-button choice only decides
how the request leaves the browser; the redirect bug lives entirely in the response.

Remembering the status on every destructive action doesn't scale past a handful of controllers, and it's
exactly the kind of gap that survives code review — the happy path looks fine in a manual click-test,
because the record really did get deleted. If you're migrating a legacy codebase with this pattern
scattered across dozens of actions, an app-wide concern beats auditing each one by hand:

```ruby
module Turbo::SafeRedirection
  extend ActiveSupport::Concern

  def redirect_to(url = {}, options = {})
    result = super
    if !request.get? && options[:turbo] != false && request.accepts.include?(Mime[:turbo_stream])
      self.status = 303
    end
    result
  end
end
```

Include it in `ApplicationController` and every non-GET redirect gets bumped to 303 unless you opt out
per-call with `turbo: false`.

Even that concern only catches redirects your own controllers issue. Gems that redirect on your behalf
are the gap it can't close by itself — Devise is the standing example. Sign-out is a DELETE
(`button_to "Log out", destroy_user_session_path, method: :delete`), and Devise's own responders
default to a plain 302 unless you tell them otherwise, which reproduces this exact routing error on
logout in an otherwise fixed app:

```ruby
# config/initializers/devise.rb
config.responder.redirect_status = :see_other
```

That's one of three lines Devise needs; the [Devise-with-Turbo tutorial](./devise-with-turbo.md) has the
other two and the sign-out fix.

This bug is one corner of a larger contract: which status Turbo expects for every branch a form response
can take. `docs/recipes/form-response-contract.md` covers the rest of it — the 200-vs-redirect branch,
the 422 on validation failure, and how morphing changes the answer.
