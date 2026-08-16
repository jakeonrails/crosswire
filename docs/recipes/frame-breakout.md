# Redirect the whole page from inside a frame

**"I have a form in a modal. It lives in a Turbo Frame. On success I want the whole page to navigate. On
failure I want the errors to stay in the modal. How do I tell Turbo, from the server, that *this* response
should break out?"**

This is the single longest-running unsolved request in Hotwire, and the answer most blog posts give you
does not exist.

*Primary sources: `research/notes/15-sean-doyle-corpus.md` (branch `hotwire-example-modal`),
`research/notes/07-problem-mining.md` Q4 and pain point P2.*

---

## First: the option you were told about isn't real

```ruby
redirect_to items_path, turbo_frame: "_top"   # ← this keyword does not exist
```

There is no `turbo_frame:` option on `redirect_to`. It is
[`turbo-rails#367`](https://github.com/hotwired/turbo-rails/pull/367), **opened 2022-07-31, still open and
unmerged.** Several blog posts and at least one accepted Stack Overflow answer present it as shipped. It
never has been.

If you copied that line and nothing happened, that's why. Rails silently accepts unknown keys here.

---

## Why the obvious approach is impossible

Not laziness, and not an oversight — a browser constraint. The person who established this is Sean Doyle,
the Turbo maintainer who has been trying to solve it since 2021
([turbo#257](https://github.com/hotwired/turbo/issues/257#issuecomment-920482318)):

> Unfortunately, sending a response with `Turbo-Frame: _top` is incompatible with the browser built-in
> `fetch` API.
>
> A fetch `Response` resulting in a redirect **deliberately prevents** access to the intermediate redirect
> response with a status in the `300...399` range.
>
> Unless I'm missing a crucial concept, I don't think there is a way for Turbo to excise the server's
> `Turbo-Frame: _top` header from the chain of responses. Without access to that value, the client-side is
> unable to react to the server's override.

He was still saying it in December 2024, on the PR itself:

> I have explored that possibility in the past, but could not find a way to make it work with `fetch`. If
> you explore it on your own and are able to make progress, please share!

**The shape of the problem:** a `redirect_to` produces **two** responses — the 302, and the followed GET.
Turbo submits with `fetch(..., { redirect: "follow" })`, so the browser follows the redirect internally and
hands your JavaScript only the *final* response. Any header you set on the 302 is unreachable by the time
anything can react to it.

That is the whole difficulty, and it's why every "just set a response header" attempt fails.

*The corpus does not preserve the Fetch spec's own wording here, only Doyle's paraphrase of it. If you want
spec-level `redirect: "manual"` / `Response.redirected` mechanics, source them yourself — they are not in
this research and shouldn't be invented.*

**Why it hasn't been fixed** is a design deadlock, not neglect. Doyle wants a Rails-level convention; dhh
and Kevin McConnell want it to be Streams' job:

> kevinmcconnell: *"Making Frames any more 'server-directed' would mean more overlap between Frames and
> Streams, and I think it will start to introduce complexity that we don't need."*

---

## The working solution: `Turbo::FrameRedirectable`

Doyle solved this for himself in 2022, in his `hotwire-example-modal` branch. It is 25 lines of Ruby and 5
lines of JavaScript, and it is the most directly actionable thing in the entire research corpus.

**The insight: if the header can't ride the 302, put it on the response `fetch` *can* see — the followed
GET.** Stash it in the flash on the way out, and promote it onto the next response's headers on the way
back in.

### 1. The concern

```ruby
# app/controllers/concerns/turbo/frame_redirectable.rb

module Turbo
  module FrameRedirectable
    extend ActiveSupport::Concern

    included do
      before_action :transform_turbo_frame_flash_into_header

      def redirect_to(options = {}, response_options = {})
        turbo_frame = response_options.delete(:turbo_frame) { request.headers["Turbo-Frame"] }

        super

        flash["Turbo-Frame"] = response.headers["Turbo-Frame"] = turbo_frame
      end

      private

      def transform_turbo_frame_flash_into_header
        response.headers["Turbo-Frame"] = flash["Turbo-Frame"]

        flash.delete "Turbo-Frame"
      end
    end
  end
end
```

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Turbo::FrameRedirectable
end
```

Read the `redirect_to` override closely:

- `response_options.delete(:turbo_frame) { request.headers["Turbo-Frame"] }` pulls your `turbo_frame:`
  keyword out before `super` sees it — which is what stops Rails choking on an unknown option — and
  **defaults to the frame that made the request**, so `redirect_to @post` inside a frame keeps behaving
  normally.
- `flash["Turbo-Frame"] = response.headers["Turbo-Frame"] = turbo_frame` sets it in both places. The header
  on the 302 is unreachable, as established — it's set for completeness. **The flash is the one that
  matters.**
- `transform_turbo_frame_flash_into_header` runs as a `before_action` on the *next* request — the followed
  GET — and copies the stashed value onto that response's headers, then deletes it so it can't leak into a
  third request.

**The flash hop is not a hack.** It is the only manoeuvre that gets the value onto a response the client
can actually read. Understanding that is the difference between copying this and knowing when it applies.

### 2. The controller

```ruby
class MessagesController < ApplicationController
  def create
    @message = Message.new message_params

    if @message.save
      redirect_to messages_url, turbo_frame: "_top"
    else
      render :new, status: :unprocessable_content
    end
  end
end
```

That's the whole payoff: `turbo_frame: "_top"` now works, because you made it work.

*Currency note: Doyle's original wrote `status: :unprocessable_entity` and a bare `redirect_to`. Prefer
`:unprocessable_content` (Rack 3.1 rename) and add `status: :see_other` on redirects from non-GET actions —
see [`form-response-contract.md`](./form-response-contract.md).*

### 3. The listener

```js
// app/javascript/application.js

addEventListener("turbo:submit-end", ({ target, detail: { fetchResponse } }) => {
  if (fetchResponse.redirected && fetchResponse.header("Turbo-Frame") == "_top") {
    Turbo.visit(fetchResponse.location)
  }
})
```

Five lines. On every form submission that ended in a redirect, check the *final* response for the header
the `before_action` just planted, and promote it to a full-page visit.

---

## The companion trick: one template, modal and full page

The modal branch pairs breakout with its inverse problem — the same template needs to render inside a frame
on desktop and as a full page on mobile. The answer is to let the **client name the frame it wants**, as an
ordinary form field.

```erb
<%# app/views/messages/index.html.erb %>

<%= link_to "New message", new_message_path, class: "sm:hidden" %>

<form action="<%= new_message_path %>" class="hidden sm:block" data-turbo-frame="dialog">
  <button name="turbo_frame" value="dialog" aria-expanded="false">New message</button>
</form>
```

```erb
<%# app/views/messages/new.html.erb %>

<turbo-frame id="<%= params[:turbo_frame] || dom_id(@message) %>" target="_top">
  <h1>New message</h1>

  <%= link_to "Back", messages_path, class: "group-open:hidden" %>

  <%= form_with model: @message, class: "grid" do |form| %>
    <%= hidden_field_tag "turbo_frame", params[:turbo_frame] %>
    <%# … fields … %>
    <button>Send</button>
  <% end %>
</turbo-frame>
```

The trigger is **not a link — it's a one-field form** whose only field is `name="turbo_frame"
value="dialog"`. Submitting it does two things at once: `data-turbo-frame` routes the response into the
page-global dialog frame, *and* `?turbo_frame=dialog` tells the server which `id` to give the frame it
renders. The hidden `turbo_frame` field inside the real form carries that choice through re-renders, so a
validation failure stays in the modal.

On small screens the plain `link_to` is shown instead, with no frame targeting, and the same action renders
as a full page. **One template, two presentations, chosen by a CSS breakpoint.**

*Doyle's original also put `role="section"` on the `<turbo-frame>`. That is not a valid ARIA role — drop
it.*

---

## When `target="_top"` on the frame is the right answer instead

Often, honestly. If the flow is **single-step and all-or-nothing**, put `target="_top"` on the frame and
skip the concern entirely:

```erb
<%= turbo_frame_tag "modal", target: "_top" do %>
  <%= form_with model: @item do |f| %>…<% end %>
<% end %>
```

Every navigation inside the frame now becomes a full-page visit. To keep validation errors *in* the modal,
answer the failure path with a stream instead of a document:

```ruby
def update
  if @item.update(item_params)
    redirect_to items_path, status: :see_other        # breaks out via _top
  else
    render :edit, status: :unprocessable_content      # renders edit.turbo_stream.erb
  end
end
```

```erb
<%# app/views/items/edit.turbo_stream.erb %>
<%= turbo_stream.replace("modal", partial: "form", locals: { item: @item }) %>
```

> inopinatus, on this pattern (43 reactions): *"I don't think this is a hack, frankly, I think this is
> system-working-as-designed."*

### When it breaks

`target="_top"` is a blunt, unconditional switch: **every** navigation in that frame breaks out, on success
and failure alike. Doyle's own statement of the limit
([turbo#257, 2021-11-13](https://github.com/hotwired/turbo/issues/257#issuecomment-968096384)):

> We want the successful submission to "break out" of the frame and fully navigate the page to
> `/articles/1`. However, since there is a `<turbo-frame id="dialog_frame"></turbo-frame>` in **both** the
> requesting page and response, **we can't rely on the presence or absence to make that decision.**
>
> Declaring each page's `<turbo-frame id="dialog_frame">` with the `[target="_top"]` attribute would handle
> the "create, then redirect the page" use case, but **would break the multi-step experience, and would
> also break intermediate-step validations.**

**So: multi-step wizards in a frame cannot use `target="_top"`.** Step 1 → step 2 is supposed to stay in the
frame; `target="_top"` blows the modal open on the first Next. That is exactly the case
`FrameRedirectable` exists for, because it lets the *server* decide per response.

---

## Choosing

| Your flow | Use |
|---|---|
| Single-step modal; success leaves, failure stays | **`target="_top"` on the frame + a `.turbo_stream.erb` failure path.** Simplest thing that works. |
| Multi-step wizard in a frame; only the last step breaks out | **`Turbo::FrameRedirectable`.** The server decides per response. |
| Success must update the list *and* close the modal, without leaving the page | **Neither — a Turbo Stream with two actions.** See [`frames-vs-streams.md`](./frames-vs-streams.md). |
| You only need "navigate away" and don't care about frames | **A custom stream action**, below. |

The custom stream action is what most production apps converge on, and it's worth knowing even if you adopt
the concern:

```js
Turbo.StreamActions.redirect = function () { Turbo.visit(this.getAttribute("target")) }
```

```ruby
format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, articles_url) }
```

A fourth option, from the same threads (TastyPi, 29 reactions): **don't use a frame at all.** Give the
`<form>` an id, redirect on success, and answer failure with
`turbo_stream.replace(form_id)`. If the only reason you reached for a frame was error handling, this is
less machinery.

---

## Status

**Open, five years.** [`turbo#257`](https://github.com/hotwired/turbo/issues/257) (2021, 116 reactions) ·
[`turbo-rails#367`](https://github.com/hotwired/turbo-rails/pull/367) (2022-07-31) ·
[`turbo#210`](https://github.com/hotwired/turbo/pull/210) · `turbo#694` (a `Turbo-Action:` header, also
open).

Doyle asked the maintainers directly in March 2024 — *"Is there an architectural change to be made to Turbo
to improve support for this style of scenario?"* — and was never answered. **The last maintainer comment on
that PR is from June 2023.**

> **A correction to how this is often framed.** It's tempting to say this solution "has been sitting unread
> in a branch since 2022." That's not quite right, and the distinction matters:
>
> - **PR #367** has been open since 2022-07-31 and is *not* unread — it has 49 comments and real maintainer
>   engagement. What it has is a **stalled design conversation**: dhh rejected the original approach in June
>   2023 (*"too many moving parts… let's see if we can't find a path that uses the new turbo-visit-control
>   setup"*), Doyle re-pitched with a different API in 2024, and nobody replied.
> - **The `hotwire-example-modal` branch**, where `FrameRedirectable` actually lives, is a complete, working
>   demo application. It isn't abandoned or unread — it's just undiscovered. Calling it "unread" would
>   misdescribe a functioning artifact.
>
> The accurate version: **the fix has existed and worked since 2022; the upstream conversation about
> blessing it stalled in June 2023.**

---

## Caveats worth knowing before you ship the concern

- **It monkeypatches `redirect_to` at the controller level.** That's application code, not a Rails or
  turbo-rails API. It's 25 readable lines, but it is yours to maintain, and a future Rails change to
  `redirect_to`'s signature would land on you.
- **It uses the flash.** If your app doesn't have flash/session middleware on a given path — an API
  namespace, say — the hop has nowhere to land.
- **The corpus never names it outside notes/15.** `research/notes/07-problem-mining.md` documents the
  problem (Q4, P2) and the *community* workarounds, but never mentions `Turbo::FrameRedirectable`. Don't
  expect to find corroboration by searching; this is one maintainer's example branch, verified by reading
  it.
- **Nobody re-ran this branch against Turbo 8.** The mechanism depends only on stable pieces —
  `before_action`, the flash, response headers, and `turbo:submit-end`'s `fetchResponse` — so it should
  hold. That's an assessment, not a test result.

---

Related: [`form-response-contract.md`](./form-response-contract.md) for the 303/422 rules both paths depend
on · [`frames-vs-streams.md`](./frames-vs-streams.md) for whether this should be a frame at all ·
[`diagnosis.md`](./diagnosis.md) → "Content is missing inside a frame" ·
[`corrections.md`](./corrections.md) for the `turbo_frame: "_top"` claim in its short form.
