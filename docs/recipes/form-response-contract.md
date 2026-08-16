<%# crosswire:contract v1 %>
# My form submits but nothing happens

You submit a form. The network tab shows a request. The server logs a response. And the page just... sits
there. No error banner, no validation messages, nothing. This is the single most commonly hit Turbo
failure mode, and it has one root cause with four branches. Learn the branches once and you'll never be
confused by this again.

---

## The contract, in full

This is the actual decision tree, derived from Turbo's own source
(`src/core/drive/form_submission.js#requestSucceededWithResponse` and `src/core/drive/navigator.js`):

```
response 4xx (clientError)  → renders the response IN PLACE, URL unchanged     (validation errors)
response 5xx (serverError)  → replaces <head> AND <body> with the error page
response 2xx AND redirected → follows the redirect to its target                (the happy path)
response 200, NOT redirected, method != GET
                            → Error: "Form responses must redirect to another location"
                              console error. NOTHING renders. This is the silent failure.
```

Four branches, one silent one. If your form "does nothing," you're almost always in the fourth branch —
which means the fix is almost never in your view or your JavaScript, it's in your controller's response.

---

## Why a bare `200 OK` on a non-GET is discarded

Turbo only re-renders a form response **in place** when the status is 4xx or 5xx. A `200 OK` that isn't a
redirect is treated as a programming error, and Turbo throws it away rather than guessing what you meant.
This is the pre-Turbo Rails idiom, and it is silently dead under Turbo:

```ruby
# ❌ Nothing visible happens under Turbo
def create
  @post = Post.new(post_params)
  if @post.save
    redirect_to @post
  else
    render :new                      # 200 OK, not a redirect → Turbo discards it
  end
end
```

```ruby
# ✅ Rails 8 scaffold idiom
def create
  @post = Post.new(post_params)
  if @post.save
    redirect_to @post, status: :see_other
  else
    render :new, status: :unprocessable_content    # 4xx — Turbo re-renders in place
  end
end
```

The status code is not decoration here — it's the entire signal Turbo uses to decide what to do with the
response body. A 200 says "this is a fresh page for a fresh visit"; a non-GET request that gets a 200 back
without a redirect doesn't fit any case Turbo knows how to handle, so — by design, not by bug — it does
nothing and logs `Form responses must redirect to another location` to the console. If you only check one
thing when a form "does nothing," check this: is your failure branch rendering with an explicit 4xx
status?

---

## Why only `303 See Other` works for a redirect after `POST`/`PATCH`/`PUT`/`DELETE`

Turbo submits with `fetch(..., { redirect: "follow" })` — the browser follows the redirect for you, and
which HTTP method it uses on the follow-up request depends on the status code, not on what you might
expect:

| Status | Browser behavior on redirect after `PUT`/`PATCH`/`DELETE` |
|---|---|
| `301` / `302` | Historically downgrades `POST`→`GET`, but per the Fetch spec **preserves the method** for `PUT`/`PATCH`/`DELETE` — you get a `DELETE` request against the redirect target. |
| `307` / `308` | Explicitly preserve the method, for every verb. |
| **`303 See Other`** | Explicitly means "GET this other resource," regardless of the original method. ✅ |

Rails' `redirect_to` defaults to **302**. That's harmless after a `POST` (browsers still downgrade `POST`
redirects to `GET`), but it is wrong after `PATCH`, `PUT`, or `DELETE` — a 302 there re-issues the
*original* method against the new URL. The classic symptom is `No route matches [DELETE] "/"` after a
`destroy` action redirects to the index: the browser followed the 302, kept the `DELETE` method per spec,
and your index route doesn't accept `DELETE`.

```ruby
def update
  if @post.update(post_params)
    redirect_to @post, status: :see_other
  else
    render :edit, status: :unprocessable_content
  end
end

def destroy
  @post.destroy!
  redirect_to posts_path, status: :see_other
end
```

**Rule of thumb: every `redirect_to` reached from a non-GET action should carry `status: :see_other`.**
It's harmless after `POST` and mandatory after `PATCH`/`PUT`/`DELETE` — so it costs nothing to make it a
habit rather than something you remember selectively per action.

---

## Why the 422 body has to be a complete document

The 4xx branch tells Turbo to re-render the response **in place**, replacing the current `<body>`. That
only works if the response actually *has* a full `<body>` to swap in. If your failure path renders a bare
partial, sets `layout false`, or otherwise returns a document fragment instead of a complete HTML page,
Turbo can't perform the replace and silently falls back to issuing a fresh `GET` of the original URL.

**The signature to watch for in your Rails log:** a `422` immediately followed by a `200 GET` of the same
page. That second request is Turbo's fallback, and it's why the page looks like it "did nothing" even
though your controller clearly rendered *something* — what it rendered just wasn't consumable as a body
replacement.

Fix: render from the real template (`new.html.erb`, not a partial, not a `.turbo_stream.erb` for the
non-stream format), through the normal layout, with an explicit 4xx status.

---

## `:unprocessable_content` vs. the deprecated `:unprocessable_entity`

Rack 3.1 renamed HTTP 422 from *Unprocessable Entity* to *Unprocessable Content*. `:unprocessable_entity`
still resolves to 422 — it's not broken — but it's now a **deprecated alias** and emits a Rack deprecation
warning on Rack ≥ 3.2. Rails 8.1 scaffolds generate the new name.

```ruby
render :new, status: :unprocessable_content   # prefer this on Rails 7.2+ / Rack 3.1+
```

Both symbols work today. Every pre-2026 tutorial, and most existing Rails apps, say
`:unprocessable_entity` — that's not wrong, just dated. Sources:
[rails/rails#53383](https://github.com/rails/rails/pull/53383),
[rails/rails#55603](https://github.com/rails/rails/issues/55603).

---

## Rendering form errors via Turbo Stream instead of a full re-render

The 4xx branch above is the default and requires nothing extra — Turbo re-renders whatever your `.erb`
returns in place. If you specifically want a *targeted* update instead (say, the form lives in a modal and
you only want to replace the form partial, not the whole page body), respond with a stream instead of
falling through to HTML:

```ruby
def create
  @post = Post.new(post_params)
  if @post.save
    redirect_to @post, status: :see_other
  else
    render turbo_stream: turbo_stream.replace("form", partial: "posts/form", locals: { post: @post }),
           status: :unprocessable_content
  end
end
```

Turbo's `Accept` header on unsafe (non-GET) submissions already includes
`text/vnd.turbo-stream.html`, so this works with no extra view configuration — `respond_to { |f|
f.turbo_stream; f.html }` isn't even required if you always answer with the stream format on failure.

---

## The interaction with morphing: 422 responses DO morph

If the page has morphing enabled — `turbo_refreshes_with method: :morph` at the page level, or a targeted
`turbo_stream.replace(target, method: :morph)` — your validation-failure path does not get a pass. Turbo's
own test suite has a test named `"renders unprocessable content responses with morphing"`, which exists
specifically to assert that a 422 goes through the morph path exactly like any other page refresh.

This makes it the single most commonly hit morphing bug, precisely because it sits on the most ordinary
flow in a Rails app: submit an invalid form, get validation errors back. If that form contains a
Stimulus-wrapped JS widget — a date picker, an enhanced `<select>`, a rich editor — the widget's injected
DOM isn't present in the server's freshly rendered HTML, so the morph deletes it. The underlying `<input>`
or `<select>` element itself survives the morph (that's the point of morphing), so `disconnect()`/
`connect()` never fire on your Stimulus controller — there's no lifecycle hook telling it to rebuild the
widget. The controller is still "connected," the widget it built is just gone.

This is intentional, permanent behavior, not a bug scheduled for a fix — `turbo#1210` has been open over
two years:

> We originally considered triggering a stimulus reconnect automatically for all the controllers, but
> that assumes too much. Often, you want controllers to keep the state they have when a page refresh
> happens.
>
> — jorgemanrubia

If you're on a page with morphing enabled, don't treat "did the happy path survive morphing" as your test
— test the *failure* path. Submit an invalid form and confirm every JS widget on it still works
afterward; that's the case that actually breaks. See `docs/recipes/diagnosis.md` → "my JS library breaks
after a form error" for the full fix menu (reinitialize on `turbo:morph-element`, or mark the widget
`data-turbo-permanent`), and `research/notes/14-morphing-dossier.md` for the complete decision space.

---

## `data-turbo-submits-with`

```erb
<%= form_with model: @post do |f| %>
  <%= f.submit "Save", data: { turbo_submits_with: "Saving…" } %>
<% end %>
```

On `turbo:submit-start`, Turbo swaps the submitter's label (`button.innerHTML` or `input.value`) to the
given text, and restores the original on `turbo:submit-end`. It goes on the **submitter element**, not on
the `<form>`.

Independently, `Turbo.config.forms.submitter` controls whether/how the submitter gets disabled during
submission — worth knowing because the default has an accessibility cost:

```js
Turbo.config.forms.submitter = "disabled"       // default: submitter.disabled = true
Turbo.config.forms.submitter = "aria-disabled"  // sets aria-disabled + swallows clicks, but keeps focus
                                                 // and keeps the button's name/value in the submission
```

With the default `"disabled"` strategy the button's `name`/`value` is still included in the request
(Turbo appends it to `FormData` before disabling the element), so `params[:commit]` still works — but the
button loses focus, which screen-reader users notice. `"aria-disabled"` is the more accessible choice if
you're customizing this.

---

## `form.requestSubmit()` — never `form.submit()`

If you're triggering a form submission from JavaScript (an autosubmit controller, a "save and continue"
button wired up manually), the method you call matters:

```js
this.element.submit()          // ❌ does NOT fire a `submit` event — Turbo never sees it
this.element.requestSubmit()   // ✅ fires the real `submit` event Turbo listens for
```

`HTMLFormElement.submit()` predates the `submit` event and bypasses it entirely by spec — calling it makes
the form navigate the old-fashioned way (or silently do nothing, inside a frame), completely outside
Turbo's control. `requestSubmit()` fires the actual `submit` event, respects `formnovalidate` and other
submitter attributes, and is what every autosubmit/autosave Stimulus controller should call. This is easy
to get wrong because both methods exist on every `<form>` element and look interchangeable — only one of
them is visible to Turbo.

*research/notes/02-turbo-deep-dive.md §2.10–2.13; research/notes/14-morphing-dossier.md Rule 3, "422 /
unprocessable content"; docs/recipes/diagnosis.md — "My form submits but nothing updates"*

## Where crosswire helps

None of this contract is crosswire-specific — it's Turbo's own request/response rules, and applies to any
Hotwire app. crosswire's `autosubmit` primitive already calls `requestSubmit()` internally, so you don't
need to remember that detail if you're using it.
