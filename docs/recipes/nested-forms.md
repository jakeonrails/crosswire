<%# crosswire:contract v1 %>
# The cocoon replacement

You need add/remove rows on a nested form — line items, personal references, links — the thing `cocoon`
used to own. `cocoon` is unmaintained-adjacent at this point and its client-side index counter has always
been able to desync from the server. Sean Doyle's `hotwire-example-nested-attributes` corpus shows a
frame-powered version that ships **zero custom Stimulus controllers**, and a `<template>`-powered fallback
for the two cases the frame version genuinely can't handle. Both are below, verbatim from source.

---

## The frame-powered version (ship this by default)

The controller change is three lines — comments mark each one. (Two status codes are modernised from the
2022 original, which predates both the Rack 3.1 rename and Rails' `see_other` scaffolds — see the note
after this listing.)

```ruby
# app/controllers/applicants_controller.rb

class ApplicantsController < ApplicationController
  def new
    @applicant = Applicant.new applicant_params      # <- was Applicant.new
  end

  def create
    @applicant = Applicant.new applicant_params

    if @applicant.save
      redirect_to applicant_url(@applicant), status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @applicant = Applicant.find params[:id]
  end

  def edit
    @applicant = Applicant.find params[:id]
    @applicant.assign_attributes applicant_params    # <- added
  end

  def update
    @applicant = Applicant.find params[:id]

    if @applicant.update applicant_params
      redirect_to applicant_url(@applicant), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def applicant_params
    params.fetch(:applicant, {}).permit(             # <- was params.require(:applicant)
      :name,
      references_attributes: [ :name, :email_address, :id, :_destroy ],
    )
  end
end
```

`new` now pre-fills from `applicant_params` and `edit` re-assigns from it — because the add/remove buttons
below reach `new`/`edit` via a `GET`, and those actions need to render whatever the user had already typed
plus the one new row (or minus the one removed row). Since `new`/`edit` requests don't always carry
`params[:applicant]`, `applicant_params` switches from `params.require(:applicant)` to
`params.fetch(:applicant, {})` so it returns an empty hash rather than raising.

**Two currency corrections to the original.** Doyle's 2022 code renders `status: :unprocessable_entity` and
redirects with the Rails default 302. Both are now wrong, and the listing above is corrected:

- `:unprocessable_entity` became a deprecated Rack alias when Rack 3.1 renamed 422 to *Unprocessable
  Content*. Use `:unprocessable_content`.
- A 302 after `PATCH` re-issues the **`PATCH`** against the redirect target, per the Fetch spec, so
  `update` needs `status: :see_other`.

Neither affects the nested-attributes mechanism itself — they'd break any Rails controller written in
2022. See `docs/recipes/form-response-contract.md` for both in full.

The form partial — **this is the whole feature**:

```erb
<%# app/views/applicants/_form.html.erb %>

<button class="hidden" tabindex="-1" aria-hidden="true"></button>

<fieldset>
  <legend>Applicant</legend>

  <%= form.label :name %>
  <%= form.text_field :name %>
</fieldset>

<fieldset>
  <legend>Personal references</legend>

  <turbo-frame id="<%= form.field_id(:references_attributes) %>">
    <ol>
      <% form.object.references.each_with_index do |reference, index| %>
        <%= form.fields :references_attributes, model: reference, index: index do |reference_form| %>
          <li <%= "hidden" if reference_form.object.marked_for_destruction? %> class="mt-2">
            <div class="grid gap-2">
              <%= reference_form.hidden_field :id %>
              <%= reference_form.hidden_field :_destroy %>

              <%= reference_form.label :name %>
              <%= reference_form.text_field :name %>

              <%= reference_form.label :email_address %>
              <%= reference_form.email_field :email_address %>

              <%= reference_form.button :_destroy, value: true,
                                                   formaction: reference_form.object.applicant.persisted? ?
                                                     edit_applicant_path(reference_form.object.applicant) :
                                                     new_applicant_path,
                                                   formmethod: "get",
                                                   data: { turbo_frame: form.field_id(:references_attributes) } do %>
                Destroy
              <% end %>
            </div>
          </li>
        <% end %>
      <% end %>
    </ol>

    <%= form.fields :references_attributes, index: form.object.references.size do |reference_form| %>
      <%= reference_form.button :_destroy, value: false,
                                           formaction: form.object.new_record? ?
                                             new_applicant_path :
                                             edit_applicant_path(form.object),
                                           formmethod: "get",
                                           data: { turbo_frame: form.field_id(:references_attributes) } do %>
        Add personal reference
      <% end %>
    <% end %>
  </turbo-frame>
</fieldset>

<%= form.button %>
```

Three things here, each a reusable idea on its own:

1. **`reference_form.button :_destroy, value: true/false`** — the add/remove buttons *are* form fields.
   "Add" is a `_destroy=false` button at index `references.size`; "Destroy" is a `_destroy=true` button
   at the row's own index. Because a clicked submit button contributes its own name/value to the
   submission, clicking it is the *only* thing that adds the extra index to the params. No JS, no
   client-side index counter — nothing to desync.
2. **`data: { turbo_frame: ... }`** on the buttons targets the `<turbo-frame>` wrapping the list, so the
   `GET` round-trip only replaces the references fieldset — scroll and focus outside it survive. Remove
   that attribute and the feature still works, just via a full-page navigation. **The frame is purely the
   enhancement layer.**
3. **`form.field_id(:references_attributes)`** generates both the frame's `id` and the buttons'
   `data-turbo-frame` value from the same helper call, so they cannot drift apart.

### The implicit-submission hazard (the most under-appreciated catch here)

Because the add/destroy buttons carry `[formaction]`/`[formmethod]` and sit *before* the real submit
button in tree order, they become the form's **default button** — so pressing <kbd>Enter</kbd> in a text
field would fire "Destroy" instead of "Create Applicant." This is not Turbo-specific; it's plain HTML form
semantics that Turbo-style buttons happen to trigger far more often than traditional forms do. The spec:

> User agents may establish a button in each form as being the form's **default button**. This should be
> the **first submit button in tree order whose form owner is that form element** […] If the platform
> supports letting the user submit a form implicitly (for example, on some platforms hitting the
> <kbd>enter</kbd> key while a text field is focused implicitly submits the form), then doing so must
> cause the form's default button's activation behavior, if any, to be run.
>
> — HTML Standard, §4.10.22.2 Implicit submission

> Any time we render a `<button>` element with a `[formaction]` or `[formmethod]` attribute, we run the
> risk of changing the `<form>` element's implicit submission mechanism. […] We can exert control over
> which button is the **default button**, and which mechanism handles implicit submissions. We'll declare
> a `<button>` element as the form's first element. The element won't be visible to end-users or
> assistive technology, and won't be able to receive focus.

The one-line fix — a decoy default button, first in tree order, invisible and unfocusable:

```erb
<button class="hidden" tabindex="-1" aria-hidden="true"></button>
```

That's the whole fix, and it belongs on **any Hotwire form that uses `formaction` buttons** — which is
most nested-form and inline-action forms once you start using this pattern. It's cheap enough to make a
habit of adding to every form that has more than one submit-capable button.

He tests it with a keyboard-only system test — Tab through every field, Enter after each, and confirm no
button ever ends up focused (i.e. the browser never silently picked a default button mid-flow):

```ruby
# test/system/applicants_test.rb (excerpt)

test "form is keyboard navigable" do
  visit new_applicant_path
  send_keys(:tab).then { send_keys "Bob" }
  send_keys(:tab).then { send_keys :enter }
  assert_no_button(focused: true)
  send_keys(:tab).then { send_keys "Enemy" }
  send_keys(:tab).then { send_keys "enemy@example.com" }
  send_keys(:tab).then { send_keys :enter }
  assert_no_button(focused: true)
  send_keys(:tab).then { send_keys :enter }
  assert_no_button(focused: true)
  send_keys(:tab).then { send_keys "Friend" }
  send_keys(:tab).then { send_keys "friend@example.com" }
  send_keys(:enter)

  within :section, "Bob" do
    assert_no_text "Enemy"
    assert_no_text "enemy@example.com"
    assert_text "Friend", count: 1
    assert_text "friend@example.com", count: 1
  end
end
```

And a second test proving validation state survives add/remove — the thing hand-rolled JS nested forms
reliably get wrong, because it comes free from the server round-trip rather than needing to be
reconstructed client-side:

```ruby
test "rejects invalid nested attributes for Personal References when creating" do
  visit new_applicant_path
  within :fieldset, "Applicant" do
    fill_in "Name", with: "New Applicant"
  end
  within :fieldset, "Personal references" do
    click_on "Add personal reference"
    within "li:nth-of-type(1)" do
      fill_in "Name", with: ""
      fill_in "Email address", with: "friend@example.com"
    end
    click_on "Add personal reference"
    within "li:nth-of-type(2)" do
      fill_in "Name", with: "Enemy"
      fill_in "Email address", with: "enemy@example.com"
      click_on "Destroy"
    end
  end
  click_on "Create Applicant"

  assert_field "Email address", with: "friend@example.com"
  assert_button "Destroy", count: 1
  assert_no_field "Email address", with: "enemy@example.com"
end
```

Note the Capybara idiom: `within :fieldset, "Personal references"` leans on `<fieldset>`/`<legend>` as
both the accessible grouping *and* the test selector. Semantic HTML pays for itself twice.

---

## The `<template>`-powered alternative — for what the GET round-trip can't serve

The frame version submits the whole form's fields as query params on every add/remove click. That has two
real, named costs:

1. **File inputs are discarded.** A `GET` request has no body — anything in an `<input type="file">` is
   silently dropped when the form re-submits as query params.
2. **Long content doesn't fit.** There's no hard HTTP limit on URI length, but browsers and servers impose
   practical ones (commonly cited around 2,000 characters) — a `<textarea>` or rich-text field with real
   prose in it can blow past that on the second or third add/remove click.

For those two cases — a form with a file input, or with long rich text — reach for the `<template>`-based
version instead. Same feature, no network round-trip at all: the server renders the new-row markup once,
inertly, inside nested `<template>` elements, and cloning happens entirely client-side.

```erb
<%# app/views/applicants/_form.html.erb %>

<fieldset>
  <legend>Personal references</legend>

  <ol id="<%= form.field_id(:references_attributes) %>">
    <% form.object.references.each_with_index do |reference, index| %>
      <%= form.fields :references_attributes, model: reference,
                                              index: index do |reference_form| %>
        <%= render partial: "references/form", object: reference_form %>
      <% end %>
    <% end %>
  </ol>

  <button type="button" data-controller="clone template-parts" data-action="click->clone#append"
                        data-template-parts-key-value="id"
                        data-template-parts-index-value="<%= form.object.references.size %>">
    Add personal reference

    <template data-clone-target="template">
      <turbo-stream action="append" target="<%= form.field_id(:references_attributes) %>">
        <template data-template-parts-target="template">
          <%= form.fields :references_attributes, model: form.object.references.new,
                                                  index: "{{id}}" do |reference_form| %>
            <%= render partial: "references/form", object: reference_form %>
          <% end %>
        </template>
      </turbo-stream>
    </template>
  </button>
</fieldset>

<%= form.button %>
```

```erb
<%# app/views/references/_form.html.erb %>

<%= tag.li class: "mt-2", hidden: form.object.marked_for_destruction?,
           data: { controller: "element" } do %>
  <div class="grid gap-2">
    <%= form.hidden_field :id %>

    <%= form.label :name %>
    <%= form.text_field :name %>

    <%= form.label :email_address %>
    <%= form.email_field :email_address %>

    <div>
      <%= form.check_box :_destroy, data: { action: "input->element#hide" },
                                    autocomplete: "off" %>
      <%= form.label :_destroy %>
    </div>
  </div>
<% end %>
```

The three controllers, complete:

```javascript
// app/javascript/controllers/clone_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "template" ]

  append() {
    for (const { content } of this.templateTargets) {
      this.element.append(content.cloneNode(true))
    }
  }
}
```

```javascript
// app/javascript/controllers/template_parts_controller.js

import { Controller } from "@hotwired/stimulus"
import { TemplateInstance } from "@github/template-parts"

export default class extends Controller {
  static targets = [ "template" ]
  static values = { index: Number, key: String }

  templateTargetConnected(target) {
    const templateInstance = new TemplateInstance(target, {
      [this.keyValue]: this.indexValue
    })

    target.content.replaceChildren(templateInstance)

    this.indexValue++
  }
}
```

```javascript
// app/javascript/controllers/element_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  hide() {
    this.element.hidden = true
  }
}
```

Removal here is a **checkbox**, not a button: `form.check_box :_destroy` with
`data-action="input->element#hide"` — check it and the row hides client-side; the `_destroy=1` value still
submits with the rest of the form on the real save. `autocomplete: "off"` stops the browser silently
restoring the checkbox's checked state on back-navigation without firing an `input` event (which would
leave the row hidden but not actually marked for destruction, or vice versa).

The clever part is the index placeholder. The server renders `index: "{{id}}"`, so field names come out
as `applicant[references_attributes][{{id}}][name]`; `@github/template-parts`'s `TemplateInstance`
interpolates a real integer at clone time and the controller increments its own `indexValue` after each
clone. That's how you get `cocoon`'s `child_index: "new_record"` trick without ever string-replacing HTML
by hand.

**Currency caveat you need to act on:** the original example imports `TemplateInstance` from
`https://cdn.skypack.dev/@github/template-parts` — **`cdn.skypack.dev` is a dead host as of 2024.** Either
re-pin the dependency through importmap (`bin/importmap pin @github/template-parts`) or drop it entirely
and do a plain `replaceAll("{{id}}", n)` on `template.innerHTML` before cloning.

---

## Which one should you ship?

**The frame-powered version as the default, the `<template>` version as the escape hatch.** The frame
version needs zero JavaScript, survives validation errors for free (it's just a normal server re-render),
and structurally cannot let client and server disagree about the next index — there is no client-side
counter to desync. Its costs — one `GET` per add/remove click, and every field's current value riding
along in the query string — are real but bounded and visible; you'll notice them, rather than debugging a
silent desync later. Reach for the `<template>` version specifically when the form has a file input or
long rich text that genuinely can't survive a `GET` round-trip.

**Currency note:** this pattern is not explicitly marked as Turbo-8-verified in the source corpus the way
the frame-breakout material is — treat it as unverified against Turbo 8 specifically, though nothing in it
depends on morphing or any Turbo-7-specific behavior, and the mechanism (frame + `formaction`/`formmethod`
buttons) is unchanged between Turbo 7 and 8.

*research/notes/15-sean-doyle-corpus.md — "Pair 1 — Nested attributes: Turbo Frame vs `<template>`"*

## Where crosswire helps

The implicit-submission decoy button — `<button class="hidden" tabindex="-1" aria-hidden="true"></button>`
as a form's first child — applies to any Hotwire form using `formaction` buttons, not just nested forms.
It's a good candidate for a future crosswire form helper; crosswire doesn't ship one yet (see
`docs/recipes/README.md`), so add it by hand for now.
