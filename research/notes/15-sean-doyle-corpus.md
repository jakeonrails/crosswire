# Sean Doyle's Hotwire corpus

> Research note 15 for **crosswire**. Compiled 2026-08-15.
> Primary source: `thoughtbot/hotwire-example-template` (26 branches, cloned and read
> branch-by-branch, README + full commit series). Secondary: his upstream PRs/issues on
> `hotwired/*` and `rails/rails`, his thoughtbot blog posts, and his other repos.

Sean Doyle is a Turbo maintainer and the author of Rails' `field_id` / `field_name` form-builder
helpers. His example repo is a single Rails app with ~25 branches, each a self-contained tutorial
readable commit-by-commit. Several branches are deliberate **A/B pairs**: the same feature built
two ways, with the tradeoffs stated in prose.

**The single most important thing in the corpus** is his method, which he states explicitly and
then demonstrates 25 times:

> When brainstorming a new feature, start by asking: "How far can we get with full-page
> transitions, server-rendered HTML, and form submissions?", then make incremental improvements
> from there.
> — *hotwire-example-turbo-dynamic-forms*, "Wrapping up"

> It can be more fruitful to pose questions from an opposing perspective: "How long could we wait
> before we introduce our first Stimulus Controller? What would it take to build this without a
> Turbo Stream? Could we defer to the server for this? Would a full-page navigation work? Could
> these fetch requests be replaced with form submissions? What would it take to get started on this
> feature without Stimulus, Turbo, or any JavaScript at all?"
> — *hotwire-example-dynamic-form-fields*

> Each line of application code is as much of a liability as it is an asset. Teams have a finite
> "innovation token" budget to spend on a project. They should reserve the majority of that budget
> for differentiating their product from the competition, and minimize the cost of inventing (or
> re-inventing) Web technologies.
> — *hotwire-example-dynamic-form-fields*, "Why?"

---

## Table of contents

- [Branch index](#branch-index)
- [Baseline: what the repo runs on](#baseline-what-the-repo-runs-on)
- [The A/B pairs — tradeoffs made explicit](#the-ab-pairs--tradeoffs-made-explicit)
- [Frame breakout from the server — he solved it, in 2022, in ~25 lines](#frame-breakout-from-the-server--he-solved-it-in-2022-in-25-lines)
- [Per-branch: search & preview family](#per-branch-search--preview-family)
- [Per-branch: overlays & inline editing](#per-branch-overlays--inline-editing)
- [Per-branch: state, lists & focus](#per-branch-state-lists--focus)
- [Per-branch: uploads & rich text](#per-branch-uploads--rich-text)
- [Per-branch: grids & realtime](#per-branch-grids--realtime)
- [Upstream design rationale](#upstream-design-rationale)
- [Blog posts, other repos, Rails core](#blog-posts-other-repos-rails-core)
- [Accessibility guidance](#accessibility-guidance)
- [The abstraction unit he actually uses](#the-abstraction-unit-he-actually-uses-answering-the-37signals-question)
- [Techniques to adopt in crosswire (ranked)](#techniques-to-adopt-in-crosswire-ranked)
- [Anything now outdated](#anything-now-outdated)
- [Negative findings](#negative-findings)

---

## Branch index

Every commit authored by **Sean Doyle** in this repo lands between **2021-04-03 and 2022-08-15**.
That is the whole corpus: it is entirely **pre-Turbo-8** (Turbo 8 shipped Feb 2024 with morphing).
Two later branches — `drawer` and `hotwire-example-process-network-request` — are authored by
**Steve Polito**, not Doyle; they are included for completeness and flagged.

| Branch | Technique | Needs JS? | Dates | Currency verdict |
|---|---|---|---|---|
| `hotwire-example-turbo-frame-powered-nested-attributes` | Add/remove `accepts_nested_attributes_for` fields via `<turbo-frame>` + `formaction`/`formmethod="get"` round-trip | **No** — zero custom Stimulus controllers | 2021-09-12 … 2022-02-06 | **Current.** Nothing deprecated. The `cocoon` replacement. Frame semantics unchanged in Turbo 8. |
| `hotwire-example-template-powered-nested-attributes` | Same feature, no HTTP: inert `<template><turbo-stream>` cloned client-side | Yes — 3 tiny controllers (`clone`, `template-parts`, `element`) | 2021-09-12 … 2022-02-05 | **Mostly current**, but imports `@github/template-parts` from `cdn.skypack.dev` — **Skypack is dead**; re-pin via importmap/jsDelivr. |
| `hotwire-example-turbo-dynamic-forms` | Country→State `<select>` sync via `<turbo-frame>` navigation + inline `<turbo-stream>` | Yes — 2 controllers totalling ~14 lines (`element`, `search-params`); JS-free fallback ships in `<noscript>` | 2022-01-08 … 2022-01-09 | **Current.** The inline-`<turbo-stream>`-inside-a-frame trick still works and is still undocumented elsewhere. |
| `hotwire-example-stimulus-dynamic-forms` | Conditional fieldsets toggled purely client-side via `fieldset[disabled]` + `aria-controls` | Yes — one `fields` controller (~25 lines) | 2022-01-08 … 2022-01-09 | **Current.** `field_id`/`field_name` are shipped Rails API. |
| `hotwire-example-dynamic-form-fields` | The superset article: the same problem solved 5 ways (no-JS → JS → Frame → Stream) | Both variants shown | 2022-01-08 … 2022-01-09 | **Current.** Best single document in the repo for teaching the ladder. |
| `hotwire-example-live-preview` | Live preview of a form as you type | see section | 2021-04-05 | Pre-Turbo-8 |
| `hotwire-example-typeahead-search` | Typeahead/combobox search | see section | 2021-04-05 | Pre-Turbo-8 |
| `hotwire-example-tooltip-fetch` | Async-loaded tooltip | **No** — `<turbo-frame loading="lazy">` + CSS `peer-hover:`/`focus-within:` | 2021-08-21 | **Current**; zero-JS |
| `hotwire-example-multi-form-search` | Several search forms on a page, submit-as-you-type, preserve focus | Yes | 2021-11-04 | Pre-Turbo-8; focus work now partly superseded by morphing |
| `hotwire-example-inline-edit` | Click-to-edit a field in place | see section | 2022-05-20 … 2022-01-30 | Pre-Turbo-8 |
| `hotwire-example-modal` | Native `<dialog>` + `showModal()` driven by a Turbo Frame | Yes — one `dialog` controller | 2022-02-08 … 2021-08-21 | **Technique current, code broken**: `dialog-polyfill` came from `cdn.skypack.dev` (dead) — and is no longer needed. |
| `hotwire-example-button-alert-template` | Server pre-renders a whole alert (incl. its own dismissal `<turbo-stream action="remove">`) into an inert `<template>`; an 11-line generic `clone` controller appends it | Yes — one generic controller | 2022-05-20 … 2022-02-07 | **Current.** Excellent pattern. |
| `hotwire-example-pagination` | Pagination + infinite scroll | see section | 2022-08-15 … 2021-10-24 | Pre-Turbo-8 |
| `hotwire-example-restore-page-state` | Preserve scroll/disclosure/field state across visits | Yes — 4 controllers | 2021-12-10 … 2021-12-11 | **Largely superseded** by Turbo 8 morphing + `turbo-refresh-scroll` |
| `hotwire-example-kanban` | Drag-and-drop kanban board | Yes — 4 controllers | 2022-05-20 … 2022-05-21 | Pre-Turbo-8 |
| `hotwire-example-kanban-preserve-focus` | Same board + explicit focus preservation across stream renders | Yes — adds `focus` controller | 2021-10-07 … 2021-10-10 | **Partly superseded** by morphing |
| `hotwire-example-action-text-mentions` | @-mentions inside Trix: an accessible combobox over a rich-text editor | Yes — `mentions` controller + 2 ERB helpers | 2021-08-27 … 2021-04-11 | Pre-Turbo-8; the ARIA content is the durable part |
| `hotwire-example-attachment-album` | Preserve `<input type="file">` selections across a failed submission | Yes — `clone`, `disabled`, `file_reader` | 2021-10-22 | **Current**; still an unsolved-feeling problem elsewhere |
| `hotwire-example-upload-processing` | Broadcast upload/processing progress | Yes (minimal) | 2021-05-04 … 2021-05-05 | Pre-Turbo-8 |
| `hotwire-example-chat` | Realtime chat; last commit "Not knowing the browsing context" | Yes — `autoscroll`, `current`, `hotkey` | 2022-05-20 … 2021-11-09 | Pre-Turbo-8 |
| `hotwire-example-map` | Leaflet map bridged into Stimulus | Yes — `leaflet` controller | 2021-04-03 … 2021-04-10 | Pre-Turbo-8; third-party-lib bridging pattern still current |
| `hotwire-example-grid` | Keyboard-navigable `role="grid"` data grid, roving tabindex | Yes — `grid` controller | 2022-05-20 … 2022-04-08 | Pre-Turbo-8; the ARIA/keyboard code is durable |
| `hotwire-example-ag-grid` | AG Grid (third-party) bridged into Stimulus | Yes | 2022-05-24 | Pre-Turbo-8 |
| `drawer` | Slide-out drawer via View Transitions + Turbo Frame | Yes | 2024-11-26 … 2025-01-02 | **Not Doyle** (Steve Polito). Post-Turbo-8 but does *not* use morphing; uses `<div role="dialog">` not `<dialog>`. |
| `hotwire-example-process-network-request` | Background job → `Turbo::Broadcastable` progress | Minimal | 2024-11-10 | **Not Doyle** (Steve Polito). Post-Turbo-8. |
| `main` | `rails new` baseline + importmap + Tailwind | — | 2022-08-15 | — |

## Baseline: what the repo runs on

```
ruby       3.1.0
rails      7.0.2.2
turbo-rails    1.0.1
stimulus-rails 1.0.2
importmap-rails (no bundler, no webpacker)
Tailwind CSS
```

```ruby
# config/importmap.rb (main)

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.js"
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "trix"
pin "@rails/actiontext", to: "actiontext.js"
pin "tailwind.config"
```

Practical consequence for crosswire: **every branch is importmap-native**. No build step, no
`node_modules`. Where a branch pulls a third-party ES module it does so from a CDN URL inside the
controller file — and in two branches that CDN (`cdn.skypack.dev`) is now dead. See
[Anything now outdated](#anything-now-outdated).

---
## The A/B pairs — tradeoffs made explicit

Doyle builds two deliberate A/B pairs. In both cases the two branches cross-link each other in
their opening paragraphs, which is how you know the pairing is intentional.

### Pair 1 — Nested attributes: Turbo Frame vs `<template>`

This is **the `cocoon` replacement**, and it is the highest-value thing in the corpus.

He states the axis of the tradeoff in the first paragraph of each branch:

> This branch will demonstrate the process of **progressively enhancing** a foundation built on
> form submissions, URL parameters, and HTTP requests. If you're interested in exploring
> alternatives that **don't rely on HTTP**, read the
> `hotwire-example-template-powered-nested-attributes` branch.
> — *turbo-frame-powered-nested-attributes*

> This branch will **skip** the process of progressively enhancing a foundation built on form
> submissions, URL parameters, and HTTP requests. If you're interested in learning more about that
> process, read the `hotwire-example-turbo-frame-powered-nested-attributes` branch.
> — *template-powered-nested-attributes*

So the axis is: **network round-trip (server is the only renderer) vs. no network (server
pre-renders an inert template the client clones).**

| | `turbo-frame-powered` | `template-powered` |
|---|---|---|
| Custom Stimulus controllers | **0** | 3 (`clone`, `template-parts`, `element`) |
| Works with JS disabled | **Yes** (frame is the enhancement; buttons still work) | No |
| Network request per "Add" | Yes — one `GET` per add/remove | **No** |
| Server-side validation state preserved on add | **Yes**, automatically (server re-renders the whole fieldset from params) | No — new rows are static clones |
| Index bookkeeping | Server does it (`index: form.object.references.size`) | Client does it (`template-parts` + `{{id}}` placeholder) |
| Third-party dependency | none | `@github/template-parts` |
| Risk | URL length (all form fields encoded into the `GET`); implicit-submission hazard | dead CDN; client/server duplication of index logic |

**Both** branches share the same model/controller foundation:

```ruby
# app/models/applicant.rb

class Applicant < ApplicationRecord
  has_many :references

  accepts_nested_attributes_for :references, allow_destroy: true

  validates_associated :references

  with_options presence: true do
    validates :name
    validates :references
  end
end

# app/models/reference.rb

class Reference < ApplicationRecord
  belongs_to :applicant

  with_options presence: true do
    validates :name
    validates :email_address
  end
end
```

#### A — `hotwire-example-turbo-frame-powered-nested-attributes` (zero JS)

**The key move**: an "Add personal reference" button is a `<button>` inside the *same* form,
rendered with `formmethod="get"` and `formaction="/applicants/new"` (or `/applicants/:id/edit`).
Clicking it re-submits the entire form **as a GET to the form's own render action**. The controller
rehydrates the model from `params` — including the extra empty `references_attributes` index the
button contributes — and re-renders. Adding a row is just *re-rendering the page with one more
row in the params*.

The controller change is three lines:

```ruby
# app/controllers/applicants_controller.rb

class ApplicantsController < ApplicationController
  def new
    @applicant = Applicant.new applicant_params      # <- was Applicant.new
  end

  def create
    @applicant = Applicant.new applicant_params

    if @applicant.save
      redirect_to applicant_url(@applicant)
    else
      render :new, status: :unprocessable_entity
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
      redirect_to applicant_url(@applicant)
    else
      render :edit, status: :unprocessable_entity
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

> Since the `ApplicantsController#new` action might handle requests that don't encode any URL
> parameters, we also need to change the `#applicant_params` method to return an empty hash in the
> absence of a `params[:applicant]` value.

The final form partial — **this is the whole feature**:

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

Three things to notice, each of which is a reusable idea on its own:

1. **`reference_form.button :_destroy, value: true/false`** — the add/remove buttons *are* form
   fields. "Add" is a `_destroy=false` button at index `references.size`; "Destroy" is a
   `_destroy=true` button at the row's own index. Because a clicked submit button contributes its
   own name/value to the submission, clicking it is the *only* thing that adds the extra index to
   the params. No JS, no client-side index counter.
2. **`data: { turbo_frame: ... }`** on the buttons targets the `<turbo-frame>` that wraps the list,
   so the GET round-trip only replaces the references fieldset — scroll and focus outside it
   survive. Remove that attribute and the feature still works via full-page navigation. **The frame
   is purely the enhancement layer.**
3. **`form.field_id(:references_attributes)`** generates the frame `id` and the `data-turbo-frame`
   value from the same helper, so they cannot drift.

##### The implicit-submission hazard (his most under-appreciated a11y catch)

Because the add/destroy buttons carry `[formaction]`/`[formmethod]` and appear *before* the real
submit button in tree order, they become the form's **default button** — so pressing <kbd>Enter</kbd>
in a text field would fire "Destroy" instead of "Create Applicant". He quotes the spec:

> User agents may establish a button in each form as being the form's **default button**. This
> should be the **first submit button in tree order whose form owner is that form element** […] If
> the platform supports letting the user submit a form implicitly (for example, on some platforms
> hitting the <kbd>enter</kbd> key while a text field is focused implicitly submits the form), then
> doing so must cause the form's default button's activation behavior, if any, to be run.
> — [4.10.22.2 Implicit submission]

> Any time we render a `<button>` element with a `[formaction]` or `[formmethod]` attribute, we run
> the risk of changing the `<form>` element's implicit submission mechanism. […] We can exert
> control over which button is the **default button**, and which mechanism handles implicit
> submissions. We'll declare a `<button>` element as the form's first element. The element won't be
> visible to end-users or assistive technology, and won't be able to receive focus.

```erb
<button class="hidden" tabindex="-1" aria-hidden="true"></button>
```

That one line is the whole fix. **This applies to any Hotwire form that uses `formaction` buttons**
— which, in his idiom, is most of them. It belongs in a crosswire helper.

And he tests it, with a keyboard-only system test:

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

And a test that proves validation errors survive add/remove — the thing hand-rolled JS nested forms
always get wrong:

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

Note the Capybara idiom throughout: `within :fieldset, "Personal references"` — he leans on
`<fieldset>`/`<legend>` as the accessible grouping *and* as the test selector. Semantic HTML pays
for itself twice.

#### B — `hotwire-example-template-powered-nested-attributes` (no network)

Same feature, no HTTP. The server renders the new-row markup **once**, inertly, inside nested
`<template>` elements — an outer `<template>` holding a `<turbo-stream action="append">` whose own
`<template>` holds the fields. `<template>` content is inert, so none of it is live in the document
and none of the field names collide.

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
import { TemplateInstance } from "https://cdn.skypack.dev/@github/template-parts"

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
`data-action="input->element#hide"` — check it and the row hides client-side; the `_destroy=1` value
still submits with the form. `autocomplete: "off"` stops the browser restoring the checkbox state on
back-navigation without firing an `input` event.

The genuinely clever bit is the **index placeholder**. The server renders `index: "{{id}}"`, so
field names come out as `applicant[references_attributes][{{id}}][name]`; `template-parts`
interpolates a real integer at clone time and increments its own `indexValue`. That is how you get
`cocoon`'s `child_index: "new_record"` trick without string-replacing HTML.

**Caveat to record:** `https://cdn.skypack.dev/@github/template-parts` is a dead host as of 2024.
Re-pin through importmap (`bin/importmap pin @github/template-parts`) or drop the dependency and do
a `replaceAll("{{id}}", n)` on `template.innerHTML` before cloning.

#### Which one should crosswire ship?

**A (frame-powered) as the default recipe, B (template-powered) as the escape hatch.** A needs zero
JavaScript, survives validation errors for free, and cannot desync client and server index
counters. Its costs — one GET per row, and all form values in the query string — are real but
bounded, and he says exactly how to bound them (see the "Refining the request" technique in
*turbo-dynamic-forms*, which encodes only the *changed* field into an `<a href>`). Reach for B when
the form contains a file input or long rich text that cannot survive a `GET` round-trip — which are
precisely the two caveats he names.

---

### Pair 2 — Dynamic form fields: Stimulus vs Turbo

Same problem shape ("the form's shape depends on a field's value"), split by **where the new HTML
comes from**:

- `hotwire-example-stimulus-dynamic-forms` — the data is **already on the client**. Toggle it with
  a Stimulus controller and CSS. No request.
- `hotwire-example-turbo-dynamic-forms` — the data is **only knowable by the server** (3,391
  country/state pairings; a server-computed "estimated arrival"). Fetch a fragment.
- `hotwire-example-dynamic-form-fields` — the superset article that walks **both**, in five
  escalating steps, on one `Building` model.

He draws the line explicitly:

> While it might be tempting to **render all possible country and states pairings directly into the
> document**, that would require rendering about 3,400 elements in every form. […] Rendering that
> many elements would be inefficient. Instead, we'll render a single country-state pairing, then
> retrieve a new pairing whenever the selected country changes.

That is the whole decision rule: **if the full option space is small enough to ship, ship it and
toggle with CSS; if it isn't, fetch a fragment with a Frame.**

He also frames the problem against React up front, which is the framing crosswire wants:

> If we built this page with a client-side rendering framework, our form could store the selected
> level of access in-memory as a JavaScript object. […] Unfortunately, server-side rendering
> frameworks don't have that luxury. The server renders the page once, and only once when
> responding to an HTTP request. If we built a version of this feature with a server-side rendering
> framework, what would it take to achieve a similar level of interactivity and network efficiency?

#### The rung-by-rung ladder (both branches follow it)

**Rung 0 — no JavaScript at all.** A second `<button formmethod="get" formaction="<current page>">`
inside the same form. Clicking it re-submits every field as query params to the page's own render
action, which re-renders the form with the new shape.

```erb
<button formmethod="get" formaction="<%= new_document_path %>">Select access</button>
```

```ruby
def new
  @document = Document.new document_params
end

def document_params
  params.fetch(:document, {}).permit(:access, :passcode, :content)
end
```

He names the two costs of GET-encoding a whole form, and this is the passage to reuse verbatim:

> Submitting the form's values as query parameters comes with two caveats:
> 1. Any selected `<input type="file">` values will be discarded
> 2. According to the HTTP specification, there are no limits on the length of a URI […]
>    Unfortunately, in practice, conventional wisdom suggests that URLs over 2,000 characters are
>    risky.
>
> Collecting file uploads, rich text content, or long-form prose would put us at risk. […] When
> deploying this pattern in your own applications, it's worthwhile to assess this risk on a case by
> case basis.

**Rung 1 — keep the no-JS path alive.** Move the visible button into `<noscript>`, and add a
`hidden` twin that JS clicks.

```erb
<noscript>
  <button formmethod="get" formaction="<%= new_address_path %>">Select country</button>
</noscript>
<button formmethod="get" formaction="<%= new_address_path %>" hidden
        data-element-target="click"></button>
```

**Rung 2 — the entire Stimulus controller.** This is his most-reused controller in the whole repo
and it is six lines:

```javascript
// app/javascript/controllers/element_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "click" ]

  click() {
    this.clickTargets.forEach(target => target.click())
  }
}
```

```erb
<%= form.select :country, @address.countries.invert, {}, autocomplete: "off",
                data: { action: "change->element#click" } %>
```

Note the recurring `autocomplete: "off"`:

> Without explicitly opting out of autocompletion, browsers might automatically restore state from a
> previous visit to the page. Those state restorations don't dispatch events throughout the document
> in the same way as user-initiated selections would.

**Rung 3 — scope it to a Frame.** Wrap the dependent fields, point the hidden button at the frame.

```erb
<turbo-frame id="<%= form.field_id(:state, :turbo_frame) %>" class="contents">
  <% if @address.states.any? %>
    <%= form.label :state %>
    <%= form.select :state, @address.states.invert %>
  <% end %>
</turbo-frame>
```

```erb
<button formmethod="get" formaction="<%= new_address_path %>" hidden
        data-element-target="click" data-turbo-frame="<%= form.field_id(:state, :turbo_frame) %>"></button>
```

> Throughout the frame's navigation, the browser retains any client-side context outside of the
> `<turbo-frame>` element, like element focus or scroll depth.

**Rung 4 — shrink the request.** Swap the hidden `<button>` for a hidden `<a>` and encode only the
changed field:

```erb
<a href="<%= new_address_path %>" hidden
   data-search-params-target="anchor"
   data-element-target="click" data-turbo-frame="<%= form.field_id(:state, :turbo_frame) %>"></a>
```

```erb
<%= form.select :country, @address.countries.invert, {}, autocomplete: "off",
                data: { action: "change->search-params#encode change->element#click" } %>
```

```javascript
// app/javascript/controllers/search_params_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "anchor" ]

  encode({ target: { name, value } }) {
    for (const anchor of this.anchorTargets) {
      anchor.search = new URLSearchParams({ [name]: value })
    }
  }
}
```

> The order of the tokens in the `[data-action="change->search-params#encode change->element#click"]`
> descriptor **is significant**. […] "When an element has more than one action for the same event,
> Stimulus invokes the actions from left to right in the order that their descriptors appear."
> In this case, we need `search-params#encode` to precede `element#click` so that the name-value
> pair is encoded into the `[href]` attribute *before* we drive the `<turbo-frame>` element.

**Rung 5 — patch content *outside* the frame, from inside the frame.** This is the most valuable
single trick in the corpus and almost nobody knows it. A Frame only replaces itself, so anything
else on the page that depended on the changed value goes stale. His fix: **render a `<turbo-stream>`
element literally inside the frame's response.**

```erb
<turbo-frame id="<%= form.field_id(:state, :turbo_frame) %>" class="contents">
  <% if @address.states.any? %>
    <%= form.label :state %>
    <%= form.select :state, @address.states.invert %>
  <% end %>
  <%= turbo_stream.replace @address %>
</turbo-frame>
```

> Like `<turbo-frame>` custom elements, `<turbo-stream>` elements are valid HTML, and can be
> rendered *directly* into documents. […] On their own, `<template>` elements are completely inert.
> They're ignored by the document regardless of whether or not JavaScript is enabled.

> It's important to acknowledge the difference between the `<turbo-stream>` element and the
> `text/vnd.turbo-stream.html` MIME type. […] Coincidentally, responses with the
> `Content-Type: text/vnd.turbo-stream.html` header are also very likely to contain
> `<turbo-stream>` elements in their body.

He then names the cost, unprompted:

> Keep in mind, using this strategy means that the *server* renders the partial twice (once outside
> the `<form>` element, and once nested within a `<turbo-stream>`) *and* the *browser* parses the
> content twice. For text, content that isn't interactive, and content that doesn't load external
> resources, any negative end-user impact caused by double-parsing will be negligible.
> Double-loading an uncached external resource like an image or video might cause perceptible
> flickering during the second render.

**And the summary of what he did *not* build**, which is the crosswire thesis in one list:

> Let's also reflect on some things that *aren't* part of our implementation. The application code
> doesn't include:
> * additional routes or controllers dedicated to maintaining the "Country"-"States" pairing
> * Turbo-aware code outside of the `app/views` directory
> * any calls to XMLHttpRequest or fetch
> * any `async` functions or Promises
> * client-side templating of any kind

#### The pure-Stimulus side (no request at all)

When the options *are* already on the client, he never touches the network. The mechanism is
`<fieldset disabled>` + the `:disabled` CSS pseudo-class + `aria-controls`:

```erb
<%= field_set_tag "Passcode protect", disabled: !@document.passcode_protect?, class: "disabled:hidden",
                                      id: form.field_id(:access, :passcode_protected, :fieldset),
                                      name: form.field_name(:access) do %>
  <%= form.label :passcode %>
  <%= form.text_field :passcode %>
<% end %>
```

```erb
<%= form.collection_radio_buttons :access, Document.accesses.keys, :to_s, :humanize do |builder| %>
  <span>
    <%= builder.radio_button autocomplete: "off",
                             aria: { controls: form.field_id(:access, builder.value, :fieldset) },
                             data: { action: "input->fields#enable" } %>
    <%= builder.label %>
  </span>
<% end %>
```

```javascript
// app/javascript/controllers/fields_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  enable({ target }) {
    const elements = Array.from(this.element.elements)
    const selectedElements = "selectedOptions" in target ?
      target.selectedOptions :
      [ target ]

    for (const element of elements.filter(element => element.name == target.name)) {
      if (element instanceof HTMLFieldSetElement) element.disabled = true
    }

    for (const element of controlledElements(...selectedElements)) {
      if (element instanceof HTMLFieldSetElement) element.disabled = false
    }
  }
}

function controlledElements(...selectedElements) {
  return selectedElements.flatMap(selectedElement =>
    getElementsByTokens(selectedElement.getAttribute("aria-controls"))
  )
}

function getElementsByTokens(tokens) {
  const ids = (tokens ?? "").split(/\s+/)

  return ids.map(id => document.getElementById(id))
}
```

Four things make this better than the usual `classList.toggle("hidden")` version:

1. **`[disabled]` on a `<fieldset>` is the load-bearing state, not a CSS class.** Disabled fields are
   *not encoded into the submission*, so a hidden "passcode" can't accidentally be submitted — the
   validation `validates :passcode, if: :passcode_protected?` and the UI can never disagree.
2. **Visibility is derived from state**, via `disabled:hidden` (Tailwind's `:disabled` variant), not
   set independently.
3. **The wiring is `aria-controls`.** The controller reads the ARIA attribute to find what to toggle
   — the accessibility annotation *is* the application wiring, so it can't rot.
4. **`field_id` / `field_name` generate both ends**, so the `[id]`, `[name]`, and `[aria-controls]`
   values are generated from one source and cannot drift. (He wrote these Rails helpers.)

The `<select>` variant, for larger option sets, moves `aria-controls` onto each `<option>`:

```erb
<%= field_set_tag do %>
  <%= form.label :access %>
  <%= form.select :access, [], {}, autocomplete: "off",
                  data: { action: "change->fields#enable" } do %>
    <% Document.accesses.keys.each do |value| %>
      <%= tag.option value.humanize, value: value,
                                     aria: { controls: form.field_id(:access, value, :fieldset) } %>
    <% end %>
  <% end %>
<% end %>
```

His closing framing for this branch:

> We established a foundational version guided by the **Rule of Least Power**. We started with a
> sturdy and robust foundation built atop HTML. We relied on HTTP requests to ensure our page was
> functional in the absence of JavaScript. From there, we leveraged Stimulus's ability to route
> browser-based events and **infer application state from the document**.

"Infer application state from the document" is the sentence that separates his Stimulus from
everyone else's. No controller in this corpus holds state.

---
## Frame breakout from the server — he solved it, in 2022, in ~25 lines

Sibling research flagged this as the corpus's biggest open wound: `turbo-rails#367` has been open
since 2022, and **`redirect_to ..., turbo_frame: "_top"` does not exist in turbo-rails**.

It does exist in Doyle's `hotwire-example-modal` branch. He wrote it himself, as an application
concern, and it is the single most directly actionable thing in this entire note.

### The three pieces

**1. A `redirect_to` override that stamps a `Turbo-Frame` response header, and survives the redirect
via the flash.**

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

The subtlety worth internalising: a `redirect_to` produces **two** responses — the 302 and the
followed GET. A header set on the 302 is gone by the time the browser renders the target. So he
stashes it in the **flash**, and a `before_action` on the *next* request promotes the flash value
back onto the response headers. That is why this works where naive header-setting fails.

**2. The controller reads exactly like the API everyone wishes existed.**

```ruby
# app/controllers/messages_controller.rb

class MessagesController < ApplicationController
  def index
    @messages = Message.all
  end

  def new
    @message = Message.new
  end

  def create
    @message = Message.new message_params

    if @message.save
      redirect_to messages_url, turbo_frame: "_top"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :recipient, :sender)
  end
end
```

**3. A five-line global listener turns the header into a top-level visit.**

```javascript
// app/javascript/application.js

import "tailwind.config"
import { Turbo } from "@hotwired/turbo-rails"
import "controllers"
import "trix"
import "@rails/actiontext"

addEventListener("turbo:submit-end", ({ target, detail: { fetchResponse } }) => {
  if (fetchResponse.redirected && fetchResponse.header("Turbo-Frame") == "_top") {
    Turbo.visit(fetchResponse.location)
  }
})
```

That is the whole mechanism. **Server decides; client obeys.** No `data-turbo-frame="_top"` sprayed
on every form, no guessing in the view whether this render happens to be inside a frame.

### The companion trick: parameterising the frame id

The modal branch pairs frame-breakout with its inverse problem — *the same template must render
inside a frame on desktop and as a full page on mobile*. His answer is to let the **client name the
frame it wants**, as an ordinary form field:

```erb
<%# app/views/messages/index.html.erb %>

<%= link_to "New message", new_message_path, class: "sm:hidden" %>

<form action="<%= new_message_path %>" class="hidden sm:block" data-turbo-frame="dialog">
  <button name="turbo_frame" value="dialog" aria-expanded="false">New message</button>
</form>
```

```erb
<%# app/views/messages/new.html.erb %>

<turbo-frame id="<%= params[:turbo_frame] || dom_id(@message) %>" role="section" target="_top">
  <h1>New message</h1>

  <%= link_to "Back", messages_path, class: "group-open:hidden" %>

  <form method="dialog" class="hidden group-open:block">
    <button aria-expanded="true">
      Back
    </button>
  </form>

  <%= form_with model: @message, class: "grid" do |form| %>
    <%= hidden_field_tag "turbo_frame", params[:turbo_frame] %>

    <% if form.object.errors.any? %>
      <output role="alert">
        <h2><%= pluralize(form.object.errors.count, "error") %> prohibited this record from being saved:</h2>

        <ul>
          <% form.object.errors.each do |error| %>
            <li><%= error.full_message %></li>
          <% end %>
        </ul>
      </output>
    <% end %>

    <%= form.label :recipient %>
    <%= form.text_field :recipient %>

    <%= form.label :sender %>
    <%= form.text_field :sender %>

    <%= form.label :content %>
    <%= form.rich_text_area :content %>

    <button>Send</button>
  <% end %>
</turbo-frame>
```

Read the trigger carefully: it is not a link, it is a **one-field form** whose only field is
`name="turbo_frame" value="dialog"`. Submitting it does two things at once — `data-turbo-frame`
routes the response into the page-global dialog frame, *and* `?turbo_frame=dialog` tells the server
which `id` to give the frame it renders. The hidden `turbo_frame` field inside the real form carries
that choice through re-renders on validation failure, so an invalid submission stays in the modal.

On small screens the plain `link_to` (no frame targeting) is shown instead and the same action
renders as a full page — one template, two presentations, chosen by CSS breakpoint.

The frame also carries **`target="_top"`**, so any *link* inside it escapes the modal even though
form submissions are handled by the header mechanism above. Both escape hatches are covered.

### The modal shell — all native, almost no JS

```erb
<%# app/views/layouts/application.html.erb (body) %>

<body>
  <%= yield %>

  <dialog class="group" role="dialog" aria-modal="true"
          data-controller="dialog" data-action="turbo:frame-load->dialog#showModal">
    <turbo-frame id="dialog"></turbo-frame>
  </dialog>
</body>
```

```javascript
// app/javascript/controllers/dialog_controller.js

import { Controller } from "@hotwired/stimulus"
import dialogPolyfill from "https://cdn.skypack.dev/dialog-polyfill"

export default class extends Controller {
  initialize() {
    dialogPolyfill.registerDialog(this.element)
  }

  showModal() {
    if (this.element.open) return
    else this.element.showModal()
  }
}
```

```css
/* app/assets/stylesheets/application.css */
dialog        { display: none; }
dialog[open]  { display: initial; }
```

Points worth stealing:

- **An empty page-global `<turbo-frame id="dialog">` inside a `<dialog>`.** Anything on any page
  that targets `dialog` becomes a modal, with no per-feature modal plumbing.
- **`data-action="turbo:frame-load->dialog#showModal"`** — the frame finishing its load *is* the
  open event. The controller has one method and holds no state.
- **Closing is `<form method="dialog">`**, a native HTML mechanism, not a JS `close()` action.
- **`<dialog>` + `showModal()` gives focus trapping, Escape-to-close, focus restoration, and
  top-layer stacking for free.** Confirmed by inspection: there is **no focus-management JavaScript
  anywhere on this branch**. That is the correct answer, and it is why the `drawer` branch (a
  `<div role="dialog">`, not by Doyle) is the weaker pattern.
- The tests locate things by ARIA role, not by CSS class: `within :modal { … }`,
  `assert_selector :alert, "To can't be blank"`, `toggle_disclosure "New message", expand: true`.

### Currency

- The technique is **current**. `Turbo-Frame` request/response headers, `target="_top"`,
  `turbo:submit-end`, and `fetchResponse.header(...)` all still exist.
- The `dialog-polyfill` import and the `dialog-polyfill.css` `<link>` both point at
  **`cdn.skypack.dev`, which is dead**, and the polyfill is **no longer needed** — `<dialog>` has
  been baseline in all evergreen browsers since Firefox 98 (March 2022). Delete the `initialize()`
  hook, the import, and the stylesheet link. The controller reduces to `showModal()`.
- `redirect_to ..., turbo_frame:` still does not exist upstream in 2026. Ship the concern.

### Why the concern is shaped so oddly — the upstream constraint

The flash round-trip in `FrameRedirectable` looks like a hack until you read his upstream work, at
which point it is revealed as **the only thing that can work**. He is the person who established
*why* the obvious approach is impossible, and he has been repeating it for five years
([turbo#257, 2021-09-16](https://github.com/hotwired/turbo/issues/257#issuecomment-920482318)):

> Unfortunately, sending a response with `Turbo-Frame: _top` is incompatible with the browser
> built-in `fetch` API.
>
> A fetch `Response` resulting in a redirect **deliberately prevents** access to the intermediate
> redirect response with a status in the `300...399` range.

> Unless I'm missing a crucial concept, I don't think there is a way for Turbo to excise the
> server's `Turbo-Frame: _top` header from the chain of responses. Without access to that value, the
> client-side is unable to react to the server's override.

He was still saying it in [December 2024](https://github.com/hotwired/turbo-rails/pull/367#issuecomment-2541689558):

> I have explored that possibility in the past, but could not find a way to make it work with
> `fetch`. If you explore it on your own and are able to make progress, please share!

**So**: the header cannot ride the 302. His concern's flash hop is precisely the manoeuvre that gets
the value onto a response `fetch` *can* see — the followed `GET`. That is why it works and why every
naive "just set a response header" attempt fails. Say this in the recipe; it is the difference
between a copied snippet and an understood one.

His ranked alternatives, "from least to most regrettable", are the design space for anyone who wants
to do better:

> 1. Decide on a special case, reserved query parameter (for the sake of argument:
>    `?turbo_frame_override=_top`). […]
> 2. Replace Fetch with XMLHttpRequest, and use that to access the intermediate response and its
>    headers. […]
> 3. Add a unique identifier to the headers of each Turbo Frame-initiated Fetch Request. Since the
>    value is shared between the client and server, we could send frame target overrides via cookies
> 4. Change the Turbo Frame semantics for HTTP Response codes. […] We could use `201` to signify
>    that a frame response should navigate to the URL in the header, and treat `303 See Other`
>    responses as `_top` level redirects.

The design he'd actually prefer, spelled out in [March 2024](https://github.com/hotwired/turbo-rails/pull/367#issuecomment-2000266457):

```ruby
def create
  @todo = Todo.new(todo_params)

  if @todo.save
    if turbo_frame_request?
      head :created, location: @todo
    else
      redirect_to @todo
    end
  else
    render :new, status: :unprocessable_entity
  end
end
```

> Then the Turbo Frame Controller could special case responses with `201 Created`, then call
> `Turbo.visit(response.headers["Location"])`.

**And the hard case he insists nobody has solved** — worth quoting in crosswire so readers stop
looking for a general answer that doesn't exist
([turbo#257, 2021-11-13](https://github.com/hotwired/turbo/issues/257#issuecomment-968096384)):

> We want the successful submission to "break out" of the frame and fully navigate the page to
> `/articles/1`. However, since there is a `<turbo-frame id="dialog_frame"></turbo-frame>` in
> **both** the requesting page and response, **we can't rely on the presence or absence to make that
> decision.**
>
> Declaring each page's `<turbo-frame id="dialog_frame">` with the `[target="_top"]` attribute would
> handle the "create, then redirect the page" use case, but **would break the multi-step
> experience, and would also break intermediate-step validations**.

Note this directly qualifies the modal branch's own `target="_top"`: it is correct *there* because
that dialog is single-step. Multi-step wizards in a frame cannot use it.

Most striking, he sides with the maintainers **against his own four-year-old PR**
([2024-03-15](https://github.com/hotwired/turbo-rails/pull/367#issuecomment-2000226306)):

> While it's a suitable workaround given the constraints, and behaves the way it needs to, I dislike
> that it mixes HTML and Turbo Stream content types. Through that lens, I'm similarly dissatisfied
> with the original approach proposed by this PR's changeset.
>
> What I've come to appreciate about the `redirect_to`-powered Page Refresh is that the
> client-server communication revolves entirely around HTTP and `text/html`. […] adding abstractions
> to `turbo-rails` to improve the ergonomics around this type of interaction would need to be
> replicated in other server contexts.

He asked the maintainers directly, in March 2024, *"Is there an architectural change to be made to
Turbo to improve support for this style of scenario?"* — and was never answered. The last maintainer
comment on the thread is from June 2023. **`turbo-rails#367` is now four years old.**

### The honest recommendation for crosswire

Ship the `FrameRedirectable` concern as a working recipe, and ship the context with it: this is a
**known, acknowledged, unresolved gap in Turbo**, the maintainer who found it does not love any
available workaround, and there is no upstream fix in sight. A reader who knows that will make
better decisions than one handed a snippet. Two honourable alternatives to present alongside it:

- **The `turbo-visit-control` / query-param workaround** the maintainers prefer — which he
  criticises for leaking `?turbo_visit_controler=reload` into the final URL.
- **The `[disabled]` frame trick** ([turbo#445](https://github.com/hotwired/turbo/pull/445#issuecomment-995285530)),
  his other server-side breakout mechanism: render the frame with `[disabled]` when the request came
  from a frame, forcing `turbo:frame-missing` on the client; render it enabled for a full-page
  request.

> The pattern there is that the frame is rendered (with server-generated attributes and contents) and
> sent to the client. If the request is made from a frame, you could toggle the `[disabled]`
> attribute and force a `turbo:frame-missing` […] on the client side. If it *isn't* a frame request,
> the `<turbo-frame>` element […] is sent to the client's full-page request.

And his rule for *not* over-reacting to a missing frame, which crosswire should adopt as guidance:

> Transforming a failed Frame request for a portion of the page into page-wide error undercuts the
> value proposition of Frames […] For example, 500'ing the entire page because a lazily loaded
> menu's contents failed to load feels like an overreaction.

---

## Per-branch: search & preview family

### hotwire-example-live-preview

- **Technique**: Server-rendered live preview of a Markdown/plain-text `<textarea>`, submitted on every keystroke via a hidden `<button formaction>` and rendered back into the page with a `<turbo-stream action="replace">` response.
- **Problem it solves**: Letting a user see a WYSIWYG-ish rendering of their draft (`Article#content` run through `simple_format`) as they type, without hand-rolling a client-side Markdown/text renderer, and without losing the feature when JS is off.
- **Commit dates**: 2021-04-05 .. 2021-04-05 (single day, 4 commits: "Drafting Articles", "Previewing our changes", "Progressively Enhancing the experience with Hotwire", "Live previews as you type").
- **Needs JS?**: Yes, but minimal — one Stimulus controller (`form_controller.js`) that grows from 0 lines to ~13 lines over the tutorial (final version below). Without JS, the feature still works end-to-end via a normal `<button formaction>` submit-and-redirect round trip; JS only removes the need to click "Preview Article" and hides that button.
- **Key code**:

```ruby
# app/controllers/previews_controller.rb
class PreviewsController < ApplicationController
  def create
    @preview = Article.new(article_params)

    respond_to do |format|
      format.html { redirect_to new_article_url(article: @preview.attributes) }
      format.turbo_stream
    end
  end

  private

  def article_params
    params.require(:article).permit(:content)
  end
end
```

```ruby
# app/controllers/articles_controller.rb (relevant excerpt)
class ArticlesController < ApplicationController
  before_action :set_article, only: %i[ show edit update destroy ]

  def new
    @article = Article.new(article_params)
  end

  private
    def article_params
      params.fetch(:article, {}).permit(:content)
    end
end
```

```erb
<%# app/views/articles/_form.html.erb %>
<%= form_with(model: article, data: { controller: "form", action: "input->form#preview" }) do |form| %>
  <% if article.errors.any? %>
    <div id="error_explanation">
      <h2><%= pluralize(article.errors.count, "error") %> prohibited this article from being saved:</h2>

      <ul>
        <% article.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="field">
    <%= form.label :content %>
    <%= form.text_area :content %>
  </div>

  <div class="field">
    <strong>Preview:</strong>
    <div id="article_preview">
      <%= render partial: "articles/article", object: article %>
    </div>
  </div>

  <div class="actions">
    <%= form.submit %>
    <%= form.button "Preview Article", formaction: previews_path(render_into: "article_preview"),
          name: "_method", value: "post",
          data: { form_target: "preview" } %>
  </div>
<% end %>
```

```erb
<%# app/views/articles/_article.html.erb %>
<div id="<%= dom_id article %>" class="scaffold_record">
  <p>
    <strong>Content:</strong>
    <%= render partial: "articles/content", object: article.content %>
  </p>

  <p>
    <%= link_to "Show this article", article %>
  </p>
</div>
```

```erb
<%# app/views/articles/_content.html.erb %>
<%= simple_format content %>
```

```erb
<%# app/views/previews/create.turbo_stream.erb %>
<%= turbo_stream.update params[:render_into] do %>
  <%= render partial: "articles/article", object: @preview, as: :article %>
<% end %>
```

```javascript
// app/javascript/controllers/form_controller.js (final state, with README's "Improving even further" debounce step applied)
import { Controller } from "@hotwired/stimulus"
import debounce from "https://cdn.skypack.dev/lodash.debounce"

export default class extends Controller {
  static get targets() { return [ "preview" ] }

  initialize() {
    this.preview = debounce(this.preview.bind(this), 300)
  }

  connect() {
    this.previewTarget.hidden = true
  }

  preview() {
    this.previewTarget.click()
  }
}
```

```ruby
# config/routes.rb (diff)
Rails.application.routes.draw do
  resources :articles
  resources :previews, only: :create
end
```

- **Doyle's stated tradeoffs**:
  > "In this first version, the application doesn't make use of **any** Hotwire concepts." (establishes the plain-HTTP/form baseline first, then layers Turbo on top)

  > "In the spirit of progressive enhancement, we'll want to ensure that the feature gracefully degrades when JavaScript is unavailable. To do so, we'll make sure that the `Preview Post` is *always* rendered to the page. Then whenever JavaScript is available, we'll hide it."

  > "In the absence of JavaScript, Turbo won't have an opportunity to inject the `Accept: text/vnd.turbo-stream.html` into the `Accept` header, so requests made by submitting the `<form>` will have the `Accept: text/html` header. When those requests are handled by our server, the response will redirect like it did before we introduced any `turbo_stream`-specific code."

  > "Our implementation is light on JavaScript code, never encodes our `Article` records into JSON representations, and doesn't include a single line of application-specific code calling to XMLHttpRequest or fetch, in spite of sourcing all of its HTML's structure and data from the server."

  > "These omissions are at the core of Hotwire's value proposition. Turbo, specifically, demonstrates that applications can treat `<form>` elements as declarative HTML alternatives to imperative Asynchronous JavaScript and XML (AJAX) invocations. They sit within a page's document, inert and ready to be executed at a moment's notice by end-users."

- **Accessibility notes**: None explicit — no `aria-*`/role/focus-management discussion anywhere in this README. The preview area is a plain `<div id="article_preview">` with no `aria-live` region, so screen-reader users typing into the textarea would get no automatic announcement of the updated preview content (a gap Doyle doesn't address on this branch).
- **Currency check**: Repo pinned to Rails 7.0.2.2 / turbo-rails 1.0.1 / stimulus-rails 1.0.2 (Gemfile.lock), commits from 2021-04-05 — well before Turbo 8 (Feb 2024). Uses `javascript_importmap_tags` / `pin` (importmap-rails), not webpacker/sprockets for JS, so that part is still current-idiom. No morphing, no `turbo:load`/`turbo:render` distinction discussed, no `Turbo::StreamsChannel`. `form.button ... formaction:` + `turbo_stream` response pattern is unaffected by Turbo 8 changes and remains valid. Stimulus controller syntax (`static get targets()`) is Stimulus 2/3-compatible, nothing deprecated. Debounce dependency loaded from `cdn.skypack.dev` (Skypack has since had reliability/shutdown concerns) rather than being vendored via importmap `pin` — a rough edge if reproducing today.
- **Does he pair a Stimulus controller with an ERB helper/partial wrapper?** No dedicated helper — the `form` Stimulus controller is attached directly via `data: { controller: "form", action: "input->form#preview" }` on `form_with`, and the `preview` Stimulus target is set inline on the `form.button` call (`data: { form_target: "preview" }`). No wrapping partial/helper abstracts the `data-controller`/`data-action` attributes.

---

### hotwire-example-typeahead-search

- **Technique**: A global header search box that submits into a `<turbo-frame>` on every keystroke (debounced), suppresses the browser's native validation-message UI via HTML5 Constraint Validation + a Stimulus capture-phase listener, and layers GitHub's `@github/combobox-nav` package on top for `role="combobox"`/`role="listbox"` keyboard navigation.
- **Problem it solves**: A collapsible search-as-you-type box that (1) expands to show results inline while searching, (2) supports keyboard up/down + enter selection like a native autocomplete, (3) never fires a request for an empty/whitespace-only query, and (4) still works as a plain GET-and-reload search form with JS off.
- **Commit dates**: 2021-04-05 .. 2021-09-14 (bulk of the work 2021-04-05: scaffold, "Our haystack", "Enhancing our search", "Hiding the results when inactive", "Searching while typing"; keyboard navigation ["Navigating the results"] added later, 2021-09-14).
- **Needs JS?**: Yes for the live/no-reload/keyboard-nav behavior, but the base search-and-highlight feature is a plain `<form method=get>` + Turbo Frame that works with zero custom JS. Custom JS is two small Stimulus controllers: `form_controller.js` (~19 lines: swallow the native `invalid` validation bubble, auto-submit-on-input with debounce, hide the submit button) and `combobox_controller.js` (~19 lines, a thin wrapper instantiating the third-party `@github/combobox-nav` library for arrow-key navigation/selection).
- **Key code**:

```erb
<%# app/views/layouts/application.html.erb (final) %>
<!DOCTYPE html>
<html>
  <head>
    <title>HotwireExampleTemplate</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <script src="https://cdn.tailwindcss.com"></script>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body>
    <header data-controller="combobox">
      <form action="<%= searches_path(turbo_frame: "search_results") %>" data-turbo-frame="search_results" class="peer"
        data-controller="form" data-action="invalid->form#hideValidationMessage:capture input->form#submit">
        <label for="search_query">Query</label>
        <input id="search_query" name="query" type="search" pattern=".*\w+.*" required autocomplete="off"
          data-combobox-target="input" data-action="focus->combobox#start focusout->combobox#stop">

        <button data-form-target="submit">
          Search
        </button>
      </form>

      <turbo-frame id="search_results" target="_top" class="empty:hidden peer-invalid:hidden"></turbo-frame>
    </header>

    <main><%= yield %></main>
  </body>
</html>
```

```erb
<%# app/views/searches/index.html.erb %>
<turbo-frame id="<%= params.fetch(:turbo_frame, "search_results") %>">
  <h1>Results</h1>

  <ul role="listbox" data-combobox-target="list">
    <% @messages.each do |message| %>
      <li>
        <%= link_to highlight(message.body, params[:query]), message_path(message),
              id: dom_id(message, :search_result), role: "option", class: "aria-selected:outline-black" %>
      </li>
    <% end %>
  </ul>
</turbo-frame>
```

```ruby
# app/controllers/searches_controller.rb
class SearchesController < ApplicationController
  def index
    @messages = Message.containing(params[:query])
  end
end
```

```ruby
# app/models/message.rb
class Message < ApplicationRecord
  scope :containing, ->(query) { where <<~SQL, "%" + query + "%" }
    body ILIKE ?
  SQL
end
```

```javascript
// app/javascript/controllers/form_controller.js (final)
import debounce from "https://cdn.skypack.dev/lodash.debounce"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() { return [ "submit" ] }

  initialize() {
    this.submit = debounce(this.submit.bind(this), 200)
  }

  connect() {
    this.submitTarget.hidden = true
  }

  submit() {
    this.submitTarget.click()
  }

  hideValidationMessage(event) {
    event.stopPropagation()
    event.preventDefault()
  }
}
```

```javascript
// app/javascript/controllers/combobox_controller.js (final)
import { Controller } from "@hotwired/stimulus"
import Combobox from "https://cdn.skypack.dev/@github/combobox-nav"

export default class extends Controller {
  static get targets() { return [ "input", "list" ] }

  disconnect() {
    this.combobox?.destroy()
  }

  listTargetConnected() {
    this.start()
  }

  start() {
    this.combobox?.destroy()

    this.combobox = new Combobox(this.inputTarget, this.listTarget)
    this.combobox.start()
  }

  stop() {
    this.combobox?.stop()
  }
}
```

```css
/* app/assets/stylesheets/application.css (final additions) */
.empty\:hidden:empty                                { display: none; }
.peer:invalid ~ .peer-invalid\:hidden               { display: none; }
.aria-selected\:outline-black[aria-selected="true"] { outline: 2px dotted black; }
```

```ruby
# config/routes.rb (diff)
Rails.application.routes.draw do
  resources :messages
  resources :searches, only: :index
  root to: redirect("/messages")
end
```

- **Doyle's stated tradeoffs**:
  > "We'll start with an out-of-the-box Rails installation that utilizes Turbo Drive, Turbo Frames, and Stimulus to then progressively enhance concepts and tools that are built directly into browsers. Plus, it'll degrade gracefully when JavaScript is unavailable!"

  > "For simplicity's sake, our application will rely on SQL's ILIKE-powered pattern matching. Once implemented, the experience could be improved by more powerful search tools (e.g. PostgresSQL's full-text searching capabilities)."

  > "By default, browsers will communicate a field's invalidity by rendering a field-local tooltip message. While it's important to minimize the number of invalid HTTP requests sent to our server, a type-ahead search box works best when users can incrementally make changes to the query string. In our case, a validation message could [be] disruptive or distract a user mid-search."

  > "One quirk of invalid events is that they *do not* bubble up through the DOM. To account for that, our `form` controller will need to act on them during the capture phase. Stimulus supports the `:capture` suffix as a directive..."

  > "Since we'll be automatically submitting the form on each keystroke, we have an opportunity to hide the submit button. We'll use JavaScript to set the `[hidden]` attribute on the element. By deferring the `[hidden]` attribute to JavaScript, we can ensure that the element is visible whenever end-users are browsing without JavaScript enabled."

  > "We never encode our search request or response into JSON, and our client communicates with our server without any calls to XMLHttpRequest or fetch from within our application code. On top of all that, we've implemented the experience with semantically meaningful elements like `<form>`, `<input type="search">`, and `<mark>`!"

- **Accessibility notes**: This is the most accessibility-explicit branch of the four.
  - Uses the WAI-ARIA Authoring Practices `role="combobox"` pattern by name: `"The Web Accessibility Initiative - Accessible Rich Internet Applications (WAI-ARIA) Authoring Practices outline a pattern for this type of behavior: role="combobox"."`
  - Delegates the actual keyboard-navigation/ARIA-state management to `@github/combobox-nav` rather than hand-rolling it: quotes its docs directly — `"Each option needs to have role="option" and a unique id"` / `"The list should have role="listbox""`.
  - `<input type="search">` gets `autocomplete="off"` specifically because the app is substituting its own combobox UI for the browser's native autocomplete affordance.
  - `<ul role="listbox" data-combobox-target="list">` and each `<a role="option" id="...">` are wired up per spec.
  - Selection state is visually indicated via `[aria-selected="true"]` (set by the combobox-nav library) styled with a CSS attribute-selector class (`aria-selected:outline-black`), i.e. ARIA state driving CSS rather than a separate "selected" class — keeps assistive tech and visual state in sync from one source of truth.
  - No `aria-live` region is used for announcing result-count changes to screen readers as the list updates via Turbo Frame — not discussed.
- **Currency check**: Same Gemfile.lock pin as the rest of the repo — Rails 7.0.2.2, turbo-rails 1.0.1, stimulus-rails 1.0.2 — commits 2021-04 to 2021-09, well pre-Turbo-8 (Feb 2024). No morph/`turbo-refresh-method` usage (doesn't exist yet at this Turbo version). `data-turbo-frame="search_results"` on the `<form>` (not misused — this is still the correct, current API for out-of-frame targeting). Tailwind is loaded via the **Play CDN** `<script src="https://cdn.tailwindcss.com">` — Tailwind's own docs now explicitly warn this is dev-only, "not intended for production," which is a real staleness/production-readiness flag if someone lifts this layout verbatim. Both Stimulus controllers use Stimulus 2/3-compatible `static get targets()` syntax, no deprecated `data-action` forms. Debounce and combobox-nav both loaded ad hoc from `cdn.skypack.dev` rather than pinned via `bin/importmap pin` into `vendor/javascript` — Skypack is a weaker dependency-management story by 2026 standards than an importmap pin would be.
- **Does he pair a Stimulus controller with an ERB helper/partial wrapper?** No. Both `combobox` and `form` controllers are attached with raw `data-controller`/`data-action`/`data-*-target` attributes directly in `application.html.erb` and `searches/index.html.erb` — no helper method or partial wraps/generates those data attributes.

---

### hotwire-example-tooltip-fetch

- **Technique**: Per-user hover tooltips implemented as lazily-loaded `<turbo-frame src="...">` elements (`loading="lazy"`), revealed purely with CSS (`peer-hover:block`/`peer-focus:block`/`hover:block`/`focus-within:block`) — zero custom JavaScript.
- **Problem it solves**: Showing a small avatar+name tooltip on hover/focus over a "Show this user" link, without eagerly firing one network request per user row on page load, and without writing any JS to detect hover or to fetch/inject the tooltip HTML.
- **Commit dates**: 2021-08-21 .. 2021-12-20 ("[GENERATED]: Scaffold out Users" and "Loading the Tooltip" / "Loading the Tooltip Asynchronously" on 2021-08-21; a "[SKIP]: User fixture data" touch-up commit on 2021-12-20).
- **Needs JS?**: No — zero application JavaScript. The entire feature is `<turbo-frame loading="lazy">` (Turbo's built-in Intersection-Observer-backed lazy load) plus Tailwind's `peer-hover:`/`peer-focus:` variants (general sibling combinator + `:hover`/`:focus` pseudo-classes under the hood).
- **Key code**:

```ruby
# config/routes.rb (diff)
Rails.application.routes.draw do
  resources :users do
    resource :tooltip, only: :show
  end
  root to: redirect("/users")
end
```

```ruby
# app/controllers/tooltips_controller.rb
class TooltipsController < ApplicationController
  def show
    @user = User.find params[:user_id]
  end
end
```

```erb
<%# app/views/tooltips/show.html.erb %>
<turbo-frame id="<%= params.fetch :turbo_frame, dom_id(@user) %>" target="_top">
  <div class="relative">
    <div class="flex gap-2 items-center p-1 bg-black rounded-md text-white">
      <%= render partial: "users/user", object: @user, formats: :svg %>
      <strong>Name:</strong>
      <%= link_to @user.name, @user, class: "text-white" %>
    </div>
    <div class="h-2 w-2 bg-black rotate-45 -top-1 -left-2 ml-[50%] relative"></div>
  </div>
</turbo-frame>
```

```erb
<%# app/views/users/_user.html.erb (final, with loading="lazy") %>
<div id="<%= dom_id user %>" class="scaffold_record">
  <p>
    <strong>Name:</strong>
    <%= user.name %>
  </p>

  <p class="relative">
    <%= link_to "Show this user", user, class: "peer", aria: { describedby: dom_id(user, :tooltip) } %>
    <turbo-frame id="<%= dom_id user, :tooltip %>" target="_top" role="tooltip"
                 src="<%= user_tooltip_path(user, turbo_frame: dom_id(user, :tooltip)) %>"
                 class="hidden absolute translate-y-[-150%] z-10
                        peer-hover:block peer-focus:block hover:block focus-within:block"
                 loading="lazy"
    ></turbo-frame>
  </p>
</div>
```

```erb
<%# app/views/users/_user.svg.erb %>
<svg class="h-4 w-4 bg-white text-black rounded-full">
  <text text-anchor="middle" x="50%" y="50%" dy="0.35em" fill="currentColor" font-family="Arial" font-size=".75rem">
    <%= user.name.split.map(&:first).join %>
  </text>
</svg>
```

- **Doyle's stated tradeoffs**:
  > "We're deliberately prefixing the ID with `tooltip_user_` because we will be adding other elements that have an ID generated with the `dom_id` method. Adding the prefix helps keep the ID unique."

  > "We pass `"_top"` to the `target` attribute to ensure any links clicked within the tooltip will replace the whole page, and not just the content within this `<turbo-frame>`."

  > "If you navigate to http://localhost:3000/users you may not notice anything special since the tooltips show up when you hover over each link. However a separate network request is made to the tooltip endpoint for each user regardless of whether or not you hover over their link." (motivates the lazy-load step)

  > "Fortunately, optimizing these requests is really easy. All we need to do is add a `loading` attribute and have it set to `"lazy"`... This means the request to the tooltip endpoint will be made only when the `<turbo-frame>` becomes visible in the viewport. This is because `loading="lazy"` is using the Intersection Observer API under the hood."

  > "Even though a `<turbo-frame>` may be in the viewport, the fact that it's not visible prevents the network request from being made. It's only when the `<turbo-frame>` is revealed via CSS that the request is made."

  > Takeaways section, verbatim: "There's a cost to each network request, and not all user's will be viewing your application on the latest hardware or on a stable internet connection. Consider lazy-loading content that's not critical to the initial page load, especially if that content is not in the viewport." and "This is an incredibly powerful yet under utilized feature of CSS, and is often unnecessarily replicated with JavaScript."

- **Accessibility notes**:
  - `aria-describedby` links the trigger link to the tooltip: `link_to "Show this user", user, class: "peer", aria: { describedby: dom_id(user, :tooltip) }`.
  - The tooltip frame itself is given `role="tooltip"`.
  - Doyle explicitly flags the spec status: `"we give... role of "tooltip" to comply with the ARIA WAI specification for tooltips, which is currently a work in progress."`
  - Reveal triggers cover both mouse and keyboard: `peer-hover:block peer-focus:block hover:block focus-within:block` — i.e., hovering OR focusing the link, OR hovering/focusing within the tooltip itself, keeps it visible (important so keyboard users tabbing to the link, and mouse users trying to move into the tooltip to click a link inside it, both work).
  - No explicit focus-trapping or `Escape`-to-dismiss discussion; dismissal is implicit (blur/mouseout).
- **Currency check**: Commits 2021-08-21 (main work) and 2021-12-20 (fixture tweak), same Rails 7.0.2.2 / turbo-rails 1.0.1 stack, so also pre-Turbo-8. `loading="lazy"` on `<turbo-frame>` is a stable, still-current Turbo Frames API, unaffected by the Turbo 8 morphing changes. `target="_top"` usage is correct/current, not a deprecated pattern. No Stimulus at all, so no Stimulus-version concerns. Only mild dating: relies on Tailwind's Play CDN (same `<script src="https://cdn.tailwindcss.com">` pattern as the typeahead branch) — fine for a demo, explicitly discouraged by Tailwind for production as of current docs.
- **Does he pair a Stimulus controller with an ERB helper/partial wrapper?** No — there is no Stimulus controller on this branch at all; the whole interaction is server-rendered ERB partials (`users/_user`, `users/_user.svg`, `tooltips/show`) plus CSS. This is the clearest example in the set of the "no JS, `<turbo-frame>` + CSS only" approach.

---

### hotwire-example-multi-form-search

- **Technique**: Two independent `<form>` elements (a `<nav>` text-search box and an `<aside>` filter panel with a checkbox + two date fields) that each auto-submit on `input`, and that *merge* their query params together via a Stimulus `formdata` event handler so that submitting either form preserves the other form's current filter state in the resulting URL — combined with a second Stimulus controller that restores keyboard focus to whichever field triggered the last submit, since a full-page GET reload would otherwise blur/reset focus every keystroke.
- **Problem it solves**: Rails' htmlification of "search + facet filters" UIs where you have >1 physically separate `<form>` on the page that should behave like one combined query, submitted live-as-you-type, without losing the user's cursor/focus position on every debounced reload, and without JavaScript building the query string by hand (it lets native `FormData`/`URLSearchParams` do that).
- **Commit dates**: 2021-11-04 .. 2021-11-04 (all 7 commits land same day: "Generate `Customer` model", "Render Customers table", "Search by name or email_address", "Filter by Deactivation", "Filter by first purchase date range", "Combine search across forms", "Submit-as-you-input, preserve focus").
- **Needs JS?**: Yes — this is the most JS-dependent branch of the four (no `noscript`-only "click to submit" button; instead `<noscript><button>Submit</button></noscript>` is used as the fallback, meaning JS users get zero visible submit buttons and everything is auto-submit-on-input). Two small Stimulus controllers: `form_controller.js` (19 lines: `requestSubmit()` on `input`, plus a `formdata` handler that merges the *other* form's current URL params into the submitting form's `FormData` so neither form's filters get dropped) and `focus_controller.js` (19 lines: remembers which element had focus at `submit` time via a `data-controller="focus"` on `<html>`, then re-focuses the element with the matching `id` once Turbo re-renders the page and a matching `[data-focus-target="element"]` reconnects).
  - Note: `form_controller.js` imports a *polyfill*: `import "https://cdn.skypack.dev/form-request-submit-polyfill"` for `HTMLFormElement.prototype.requestSubmit`, since that method wasn't universally supported at the time.
- **Key code**:

```ruby
# config/routes.rb (diff)
Rails.application.routes.draw do
  resources :customers, only: :index
end
```

```ruby
# app/controllers/customers_controller.rb
class CustomersController < ApplicationController
  def index
    @search = Search.new search_params
    @customers = @search.query(Customer.all)
  end

  private

  def search_params
    params.permit(:q, :deactivated, :first_purchase_on_minimum, :first_purchase_on_maximum)
  end
end
```

```ruby
# app/models/search.rb
class Search
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :q, :string
  attribute :deactivated, :boolean
  attribute :first_purchase_on_minimum, :date
  attribute :first_purchase_on_maximum, :date

  def query(scope)
    to_h.values.reduce(scope) { |query, conditions| query.where(*conditions) }
  end

  def to_h
    {
      deactivated_on: ([ deactivated_on: (..Date.current) ] if deactivated),
      first_purchase_on: ([ first_purchase_on: first_purchase_on ] if first_purchase_on.present?),
      q: ([ "name ILIKE :query OR email_address ILIKE :query", query: q + "%" ] if q.present?),
    }.compact_blank
  end

  private

  def first_purchase_on
    if first_purchase_on_minimum || first_purchase_on_maximum
      Range.new(first_purchase_on_minimum, first_purchase_on_maximum)
    end
  end
end
```

```ruby
# app/models/customer.rb
class Customer < ApplicationRecord
end
```

```erb
<%# app/views/customers/index.html.erb %>
<nav>
  <form data-controller="form" data-action="input->form#requestSubmit formdata->form#mergeWithSearchParams">
    <%= fields "", model: @search do |form| %>
      <%= form.label :q, "Search" %>
      <%= form.search_field :q, data: { focus_target: "element", turbo_permanent: true } %>

      <noscript>
        <button>Submit</button>
      </noscript>
    <% end %>
  </form>
</nav>

<main>
  <aside>
    <form data-controller="form" data-action="input->form#requestSubmit formdata->form#mergeWithSearchParams">
      <%= fields "", model: @search do |form| %>
        <%= form.label :deactivated %>
        <%= form.check_box :deactivated, data: { focus_target: "element" } %>

        <%= form.label :first_purchase_on_minimum, "First purchase after" %>
        <%= form.date_field :first_purchase_on_minimum, data: { focus_target: "element" } %>

        <%= form.label :first_purchase_on_maximum, "First purchase before" %>
        <%= form.date_field :first_purchase_on_maximum, data: { focus_target: "element" } %>

        <noscript>
          <button>Submit</button>
        </noscript>
      <% end %>
    </form>
  </aside>

  <table>
    <caption>Customers</caption>

    <thead>
      <tr>
        <th>Name</th>
        <th>Email address</th>
        <th>First purchase</th>
        <th>Last purchase</th>
        <th>Status</th>
      </tr>
    </thead>

    <tbody>
      <% @customers.each do |customer| %>
        <tr>
          <td><%= customer.name %></td>
          <td><%= customer.email_address %></td>
          <td><%= customer.first_purchase_on %></td>
          <td><%= customer.last_purchase_on %></td>
          <td>
            <% if customer.deactivated_on&.past? %>
              Deactivated
            <% else %>
              Active
            <% end %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</main>
```

```erb
<%# app/views/layouts/application.html.erb (diff — <html> tag only) %>
<html data-controller="focus" data-action="submit->focus#push">
```

```javascript
// app/javascript/controllers/form_controller.js
import { Controller } from "@hotwired/stimulus"
import "https://cdn.skypack.dev/form-request-submit-polyfill"

export default class extends Controller {
  requestSubmit() {
    this.element.requestSubmit()
  }

  mergeWithSearchParams({ formData, target }) {
    const keys = Array.from(formData.keys())
    const action = new URL(target.action, document.baseURI)

    for (const [ key, value ] of action.searchParams) {
      if (keys.includes(key)) continue

      formData.append(key, value)
    }
  }
}
```

```javascript
// app/javascript/controllers/focus_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() { return [ "element" ] }

  push() {
    const { activeElement } = document

    if (activeElement) {
      this.activeElementId = activeElement.id
    }
  }

  elementTargetConnected(target) {
    if (this.activeElementId && target.id == this.activeElementId) {
      target.focus()
    }
  }
}
```

- **Doyle's stated tradeoffs**: **This branch has no bespoke tutorial README** — `README.md` on `hotwire-example-multi-form-search` is byte-for-byte the repo's generic top-level README (the "How to read this repository" / "How to fork this repository" index page), not a per-branch write-up like the other three branches. So there is no prose from Doyle on this branch weighing progressive enhancement, accessibility, or JS-off behavior; the commit messages ("Submit-as-you-input, preserve focus", "Combine search across forms") are the only first-person narrative available. Given that, no direct quotes are available for this section — inferring intent from code only: the `mergeWithSearchParams` action is doing by hand (via the native `formdata` event + `URLSearchParams`) what the live-preview and typeahead branches do server-side/declaratively, suggesting Doyle reaches for a `formdata` event handler specifically when two sibling `<form>` elements need to cooperate without a shared parent form.
- **Accessibility notes**: `<noscript><button>Submit</button></noscript>` is the only progressive-enhancement/no-JS affordance — with JS enabled there is no visible submit button on either form at all (unlike the live-preview and typeahead branches, which render a real, JS-hidden `<button>` so a screen-reader or JS-broken user still has a discoverable, tabbable control). The `focus_controller.js` exists specifically to counteract full-page-reload focus loss — a real accessibility concern for a live-search UI where every keystroke reloads the page — but it works by exact DOM `id` match, which is brittle (relies on the field's `id` staying stable across the Turbo render) and is not disclosed/explained anywhere in prose since there's no README for this branch. `turbo_permanent: true` is set on the search `<input>` (`form.search_field :q, data: { focus_target: "element", turbo_permanent: true }`) — using [Turbo permanent elements] to keep that specific DOM node (and its focus/composition state) untouched across page loads, which is the more standard/idiomatic Turbo answer to the same focus-loss problem the custom `focus_controller.js` is solving for the *other* fields that aren't marked permanent. No `aria-live`, no `role`, no `aria-*` attributes used anywhere in this branch's view code.
- **Currency check**: All commits 2021-11-04, same Rails 7.0.2.2 / turbo-rails 1.0.1 / stimulus-rails 1.0.2 stack — pre-Turbo-8. `data-turbo-permanent` usage is correct and still current Turbo API. The `form-request-submit-polyfill` import (`https://cdn.skypack.dev/form-request-submit-polyfill`) is very likely dead weight today — `HTMLFormElement.prototype.requestSubmit` has been supported in all major evergreen browsers since ~2020/2021, and the repo's own migrations target Rails 7 (image supports modern browsers), so this dependency is a good candidate for a "this is now unnecessary" flag when reviewing for reuse. As with the other branches, ad hoc `cdn.skypack.dev` imports rather than importmap-pinned vendored JS is the main dating tell. No `Turbo.setProgressBarDelay`, no legacy `data-action` syntax, no `Turbo::StreamsChannel` usage on this branch (it doesn't use Turbo Streams at all — pure Frame-less full-document GET navigations driven by Turbo Drive).
- **Does he pair a Stimulus controller with an ERB helper/partial wrapper?** No dedicated helper method wraps the `data-controller`/`data-action` attributes — they're written directly on `<html>`, on both `<form>` tags, and on individual fields (`data: { focus_target: "element", turbo_permanent: true }`) inline in the ERB. There is, however, a reusable *pattern*: the same `data-controller="form" data-action="input->form#requestSubmit formdata->form#mergeWithSearchParams"` attribute string is duplicated verbatim on both the `<nav>` search form and the `<aside>` filter form rather than being factored into a shared partial/helper — worth flagging as something later branches (e.g. `hotwire-example-stimulus-dynamic-forms`, not in scope here) may address.

---

## Per-branch: overlays & inline editing

### hotwire-example-inline-edit

- **Technique**: Per-attribute inline editing of a Rails record using paired `<turbo-frame>` elements (one in `show`, one in `edit`) that share a `dom_id`-derived frame id, so clicking "Edit" swaps just that field's frame in place; a Tailwind custom variant (`group-inline-edit:`) hides/shows the Save/Cancel controls depending on which page rendered the frame.

- **Problem it solves**: Lets a visitor edit a single field of a record (name, byline, published date, categories, rich-text content) without navigating to a full edit page or reloading the whole show page — only the one field's DOM fragment is replaced. It also solves the secondary problem of the "show" page's frame not being inside a `<form>` (needed to submit changes) by pairing the frame with a `form_with ... data: { turbo_frame: frame_id }` wrapper that targets the frame from outside it.

- **Commit dates**: 2022-01-27..2022-01-31 (technique commits: "Our Starting Point" 2022-01-27 through "Wrapping up" 2022-01-30, plus "Hiding inline actions" 2022-01-31). One unrelated later commit, "[SKIP]: Configure for `replit.com` support", is dated 2022-05-20 and is infra-only (adds `.replit`, `replit.nix`, etc.) — not part of the technique.

- **Needs JS?**: no — pure Turbo Frames/Streams (actually just Turbo Frames; no Turbo Streams used either). No Stimulus controller is introduced anywhere in this branch's diff. The only JS-adjacent change is a Tailwind config addition (a custom CSS variant via the Tailwind plugin API), which is build-time CSS tooling, not runtime JS.

- **Key code**:

  ```ruby
  # app/models/article.rb
  class Article < ApplicationRecord
    has_many :categorizations
    has_many :categories, through: :categorizations

    has_rich_text :content

    with_options presence: true do
      validates :byline
      validates :content
      validates :name
    end
  end

  # app/models/category.rb
  class Category < ApplicationRecord
    has_many :categorizations
    has_many :articles, through: :categorizations
  end

  # app/models/categorization.rb
  class Categorization < ApplicationRecord
    belongs_to :article
    belongs_to :category
  end
  ```

  ```ruby
  # app/controllers/articles_controller.rb
  class ArticlesController < ApplicationController
    def index
      @articles = Article.all
    end

    def show
      @article = Article.find params[:id]
    end

    def edit
      @article = Article.find params[:id]
    end

    def update
      @article = Article.find params[:id]

      if @article.update article_params
        redirect_to article_path(@article)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def article_params
      params.require(:article).permit(
        :byline,
        :content,
        :name,
        :published_on,
        category_ids: []
      )
    end
  end
  ```

  ```ruby
  # config/routes.rb
  Rails.application.routes.draw do
    # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
    resources :articles, only: [:index, :show, :edit, :update]

    # Defines the root path route ("/")
    # root "articles#index"
    root to: redirect("/articles")
  end
  ```

  ```erb
  <%# app/views/articles/show.html.erb %>
  <section class="grid gap-2 max-w-prose m-auto">
    <%= link_to "Edit Article", edit_article_path(@article) %>

    <%= render "inline_edit", model: @article, method: :name do %>
      <h1><%= @article.name %></h1>
    <% end %>

    <%= render "inline_edit", model: @article, method: :byline do %>
      <span>By: <%= @article.byline %></span>
    <% end %>

    <%= render "inline_edit", model: @article, method: :published_on do %>
      <% if @article.published_on.nil? %>
        <span>(Unpublished)</span>
      <% else %>
        <%= localize @article.published_on, format: :long %>
      <% end %>
    <% end %>

    <%= render "inline_edit", model: @article, method: :category_ids do %>
      <strong>Categories</strong>

      <span>
        <% @article.categories.each do |category| %>
          <span><%= category.name %></span>
        <% end %>
      </span>
    <% end %>

    <%= render "inline_edit", model: @article, method: :content do %>
      <%= @article.content %>
    <% end %>
  </section>
  ```

  ```erb
  <%# app/views/articles/edit.html.erb %>
  <%= form_with model: @article, class: "grid gap-2 max-w-prose m-auto" do |form| %>
    <%= link_to "Back", article_path(@article) %>

    <%= render "inline_fields", form: form, method: :name do %>
      <%= form.label :name %>
      <%= form.text_field :name %>
    <% end %>

    <%= render "inline_fields", form: form, method: :byline do %>
      <%= form.label :byline %>
      <%= form.text_field :byline %>
    <% end %>

    <%= render "inline_fields", form: form, method: :published_on do %>
      <%= form.label :published_on %>
      <%= form.date_field :published_on %>
    <% end %>

    <%= render "inline_fields", form: form, method: :category_ids do %>
      <fieldset>
        <legend>
          <%= @article.class.human_attribute_name(:category_ids) %>
        </legend>

        <%= form.collection_check_boxes :category_ids, Category.all, :id, :name do |builder| %>
          <%= builder.check_box %>
          <%= builder.label %>
        <% end %>
      </fieldset>
    <% end %>

    <%= render "inline_fields", form: form, method: :content do %>
      <%= form.label :content %>
      <%= form.rich_text_area :content %>
    <% end %>

    <%= form.button %>
  <% end %>
  ```

  ```erb
  <%# app/views/application/_inline_edit.html.erb %>
  <% frame_id = dom_id(model, "#{method}_turbo_frame") %>

  <%= form_with model: model, class: "contents", data: { turbo_frame: frame_id } do %>
    <turbo-frame id="<%= frame_id %>" class="contents group inline-edit">
      <%= yield %>

      <%= link_to edit_polymorphic_path(model) do %>
        Edit <%= model.class.human_attribute_name(method) %>
      <% end %>
    </turbo-frame>
  <% end %>
  ```

  ```erb
  <%# app/views/application/_inline_fields.html.erb %>
  <% frame_id = dom_id(form.object, "#{method}_turbo_frame") %>

  <turbo-frame id="<%= frame_id %>" class="contents">
    <%= yield %>

    <%= form.button class: "hidden group-inline-edit:inline" do %>
      Save <%= form.object.class.human_attribute_name(method) %>
    <% end %>
    <%= link_to "Cancel", polymorphic_path(form.object), class: "hidden group-inline-edit:inline" %>
  </turbo-frame>
  ```

  ```js
  // app/javascript/tailwind.config.js
  tailwind.config = {
    corePlugins: {
      preflight: false,
    },
    plugins: [
      tailwind.plugin(function({ addVariant }) {
        addVariant("group-inline-edit", ".group.inline-edit &")
      })
    ]
  }
  ```

  ```erb
  <%# app/views/articles/index.html.erb %>
  <% @articles.each do |article| %>
    <%= link_to article.name, article %>
  <% end %>
  ```

  Note: the README's early walkthrough (before extraction into partials) shows the `_inline_edit`/`_inline_fields` partials in an `Article`-specific, non-polymorphic form (using `edit_article_path` / `article_path`), then explicitly generalizes them to `app/views/application/_inline_edit.html.erb` and `_inline_fields.html.erb` using `edit_polymorphic_path` / `polymorphic_path` in the final "Wrapping up" section — the code blocks above reflect that final, generalized state (confirmed against the actual final file contents on the branch).

- **Doyle's stated tradeoffs**:

  > Prior to its introduction, the contents of the `<turbo-frame>` element were participating in a [grid][] layout. Introducing a single element where there were once two sibling elements changes how the `<label>` and `<input>` elements occupy available space. We'll apply the [display: contents][contents-rule] to the `<turbo-frame>` (through Tailwind's [`.contents`][tw-contents] utility class) so that its descendants continue to participate in the grid layout

  > Unfortunately, this form submission mechanism is one-sided. While the `app/views/articles/edit.html.erb` template renders the `<button>` element nested within a `<form>` element, the matching `<turbo-frame>` element that loads the fields from the `app/views/articles/show.html.erb` template _is not_ nested within a `<form>`.
  >
  > We'll render an `app/views/articles/show.html.erb`-side `<form>` element as an ancestor to the `<turbo-frame>`, then target it by declaring a `[data-turbo-frame]` attribute to match the `<turbo-frame>` element's `[id]` attribute

  > While it's crucial to present the "Save" and "Cancel" actions when they're loaded into the `app/views/articles/show.html.erb` page's `<turbo-frame>` element, it's as important to hide them when they're rendered as part of the `app/views/articles/edit.html.erb` template.
  >
  > If our application were styled in more traditional CSS manner, we'd control their visibility with cascading CSS rules. [...] Since our sample code styles its elements with Tailwind's [utility-first][tw] classes, there's an opportunity to introduce a [custom variant][] in the style of Tailwind's [`group:` variant][group] to achieve the same result

  > The partials are nested within the `app/views/articles` directory, and make use of `Article`-specific routing helpers. If we wanted to generalize this pattern to work with other models, we could declare them within `app/views/application`, and use the [polymorphic][polymorphic-helpers] variations of the `article_path` and `edit_article_path` route helpers

- **Accessibility notes**: None found. The README and diffs contain no mention of `<dialog>`, `role="dialog"`, `aria-modal`, focus trapping, `aria-live`, `inert`, `autofocus`, or the `alert` role. There is no explicit accessibility discussion anywhere in this branch — the write-up is entirely focused on Turbo Frame wiring and Tailwind CSS layout/visibility concerns (grid `display: contents`, the `group-inline-edit:` variant). No focus management is added when a frame swaps content (e.g. no autofocus on the revealed input), and no live-region is used to announce the swap to assistive tech.

- **Currency check**: This branch predates Turbo 8 (released Feb 2024) by roughly two years — its commits are dated January 2022 (with one unrelated infra commit in May 2022), and `Gemfile.lock` pins `turbo-rails (1.0.1)` against `rails (7.0.2.2)`. No page-morphing features, no `data-turbo-action`/morph-related config, and no reference to Turbo 8-era APIs appear anywhere. No deprecated/UJS-era patterns were found — the code uses `form_with` (not `form_tag`/`form_for` with `remote: true`), and Turbo Frame conventions (`<turbo-frame>`, `data-turbo-frame`) are used correctly per the version in the lockfile; nothing here is deprecated relative to Turbo 1.x, but the technique should be re-verified against Turbo 8's morphing behavior since frame-targeted form submissions and `display: contents` frame wrapping could interact differently with morph-based navigation.

- **Does he pair a Stimulus controller with an ERB helper / partial wrapper?**: no — there is no Stimulus controller in this branch at all. Instead of a Stimulus controller, Doyle pairs an ERB *partial* wrapper (`_inline_edit.html.erb` / `_inline_fields.html.erb`, rendered via `render "inline_edit", model: ..., method: ...` and `render "inline_fields", form: ..., method: ...`) with a Tailwind CSS custom variant (`addVariant("group-inline-edit", ".group.inline-edit &")` in `app/javascript/tailwind.config.js`) to toggle the Save/Cancel controls' visibility — a CSS-plugin/partial pairing, not a JS/partial pairing.

### hotwire-example-modal

- **Technique**: Present a `new`/`create` form modally by loading it into a shared, page-level `<turbo-frame id="dialog">` nested inside a native `<dialog>` element, and let a tiny Stimulus controller call `dialog.showModal()` once the frame finishes loading.

- **Problem it solves**: The starting point is a plain Rails CRUD flow (`MessagesController#new`/`#create`) rendered as full-page navigations. Doyle wants the "New message" form to appear as a modal dialog on larger viewports (while still degrading to a full-page navigation on small viewports, via `sm:hidden`/`sm:block` Tailwind classes) without hand-rolling modal show/hide, focus, or backdrop logic — by delegating all of that to the browser's native `<dialog>` element and Turbo Frames for the content swap.

- **Commit dates**: 2021-08-21..2022-02-08

- **Needs JS?**: yes — but minimally. A single ~13-line Stimulus controller (`app/javascript/controllers/dialog_controller.js`) is the only custom JS. It does two things: (1) in `initialize()`, registers the `<dialog>` element with the `dialog-polyfill` package (imported from a CDN) so browsers without native `<dialog>` support (Firefox, at the time) still work; (2) exposes a `showModal()` action, wired to fire on the `turbo:frame-load` event of the inner `<turbo-frame id="dialog">`, which calls the native `HTMLDialogElement.showModal()` (guarded so it's a no-op if already open). A second, unrelated piece of JS in `app/javascript/application.js` listens for `turbo:submit-end` and manually calls `Turbo.visit()` when a response redirected with a `Turbo-Frame: _top` response header — this is a workaround for redirecting "out of" the dialog's turbo-frame context after a successful create, not part of the modal/a11y mechanism itself. All modal open/close/focus/escape/backdrop behavior beyond `showModal()` is native browser `<dialog>` behavior — no hand-rolled focus trap JS exists.

- **Key code**:

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html>
  <head>
    <title>HotwireExampleTemplate</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdn.skypack.dev/dialog-polyfill/dist/dialog-polyfill.css">
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body>
    <%= yield %>

    <dialog class="group" role="dialog" aria-modal="true"
            data-controller="dialog" data-action="turbo:frame-load->dialog#showModal">
      <turbo-frame id="dialog"></turbo-frame>
    </dialog>
  </body>
</html>
```

```erb
<%# app/views/messages/index.html.erb %>
<section>
  <h1>Messages</h1>

  <%= link_to "New message", new_message_path, class: "sm:hidden" %>

  <form action="<%= new_message_path %>" class="hidden sm:block" data-turbo-frame="dialog">
    <button name="turbo_frame" value="dialog" aria-expanded="false">New message</button>
  </form>

  <% @messages.each do |message| %>
    <article>
      <header>
        <p>From: <%= message.sender %></p>
        <p>To: <%= message.recipient %></p>
      </header>

      <%= message.content %>
    </article>
  <% end %>
</section>
```

```erb
<%# app/views/messages/new.html.erb %>
<turbo-frame id="<%= params[:turbo_frame] || dom_id(@message) %>" role="section" target="_top">
  <h1>New message</h1>

  <%= link_to "Back", messages_path, class: "group-open:hidden" %>

  <form method="dialog" class="hidden group-open:block">
    <button aria-expanded="true">
      Back
    </button>
  </form>

  <%= form_with model: @message, class: "grid" do |form| %>
    <%= hidden_field_tag "turbo_frame", params[:turbo_frame] %>

    <% if form.object.errors.any? %>
      <output role="alert">
        <h2><%= pluralize(form.object.errors.count, "error") %> prohibited this record from being saved:</h2>

        <ul>
          <% form.object.errors.each do |error| %>
            <li><%= error.full_message %></li>
          <% end %>
        </ul>
      </output>
    <% end %>

    <%= form.label :recipient %>
    <%= form.text_field :recipient %>

    <%= form.label :sender %>
    <%= form.text_field :sender %>

    <%= form.label :content %>
    <%= form.rich_text_area :content %>

    <button>Send</button>
  <% end %>
</turbo-frame>
```

```javascript
// app/javascript/controllers/dialog_controller.js
import { Controller } from "@hotwired/stimulus"
import dialogPolyfill from "https://cdn.skypack.dev/dialog-polyfill"

export default class extends Controller {
  initialize() {
    dialogPolyfill.registerDialog(this.element)
  }

  showModal() {
    if (this.element.open) return
    else this.element.showModal()
  }
}
```

```javascript
// app/javascript/application.js
// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "tailwind.config"
import { Turbo } from "@hotwired/turbo-rails"
import "controllers"
import "trix"
import "@rails/actiontext"

addEventListener("turbo:submit-end", ({ target, detail: { fetchResponse } }) => {
  if (fetchResponse.redirected && fetchResponse.header("Turbo-Frame") == "_top") {
    Turbo.visit(fetchResponse.location)
  }
})
```

```ruby
# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  def index
    @messages = Message.all
  end

  def new
    @message = Message.new
  end

  def create
    @message = Message.new message_params

    if @message.save
      redirect_to messages_url, turbo_frame: "_top"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :recipient, :sender)
  end
end
```

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Turbo::FrameRedirectable
end
```

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
# app/models/message.rb
class Message < ApplicationRecord
  has_rich_text :content

  with_options presence: true do
    validates :content
    validates :recipient
    validates :sender
  end
end
```

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :messages, only: [:index, :new, :create]

  # Defines the root path route ("/")
  # root "articles#index"
  root to: redirect("/messages")
end
```

```css
/* app/assets/stylesheets/application.css */
dialog        { display: none; }
dialog[open]  { display: initial; }
```

```yaml
# config/locales/en.yml (relevant excerpt)
en:
  activerecord:
    attributes:
      message:
        recipient: To
        sender: From
```

```ruby
# test/system/messages_test.rb
require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
  test "create a new Message" do
    visit messages_path
    within(:section, "Messages") { toggle_disclosure "New message", expand: true }
    within :modal do
      fill_in "From", with: "Alice"
      fill_in "To", with: "Bob"
      fill_in_rich_text_area "Content", with: "Hello, world"
      click_on "Send"
    end

    assert_no_selector :section, "New message"
    assert_text "Hello, world"
    assert_text "From: Alice"
    assert_text "To: Bob"
  end

  test "rejects invalid submissions" do
    visit messages_path
    within(:section, "Messages") { toggle_disclosure "New message", expand: true }
    within :modal do
      fill_in "From", with: "Alice"
      click_on "Send"
    end

    within :modal do
      assert_selector :alert, "To can't be blank"
    end
  end
end
```

(For reference, the "starting point" pre-modal files quoted at the top of the README — `app/models/message.rb`, `app/controllers/messages_controller.rb`, `app/views/messages/index.html.erb`, `app/views/messages/new.html.erb` — are superseded by the final versions above; the README presents them as a diff baseline, not as separate final artifacts.)

- **Doyle's stated tradeoffs**:

  On why `<dialog>` plus a `<turbo-frame>` inside it, rather than a full custom modal:

  > `<dialog class="group" role="dialog" aria-modal="true" data-controller="dialog" data-action="turbo:frame-load->dialog#showModal"> <turbo-frame id="dialog"></turbo-frame> </dialog>`

  (i.e., the layout wraps a single, page-global `<turbo-frame id="dialog">` in a `<dialog>` so any link/form targeting that frame gets modal presentation for free.)

  On triggering the modal only on larger viewports while preserving a full-page fallback on small screens:

  > `<%= link_to "New message", new_message_path, class: "sm:hidden" %>`
  >
  > `<form action="<%= new_message_path %>" class="hidden sm:block" data-turbo-frame="dialog"> <button name="turbo_frame" value="dialog" aria-expanded="false">New message</button> </form>`

  This is Doyle's pattern for progressive enhancement: the plain `link_to` (full navigation, no frame targeting) is shown on small screens (`sm:hidden` hides it above the breakpoint), while the `data-turbo-frame="dialog"` form/button pair (which drives the response into the shared dialog frame) is shown only `sm:block` and up.

  On polyfilling `<dialog>` for browsers lacking native support at the time:

  > While [support has landed in WebKit][dialog-webkit], [Firefox support][] is still in the works. In the meantime, behavior can be polyfilled with the [dialog-polyfill][] package.

  On closing the dialog with a native `method="dialog"` form rather than JS:

  > ```diff
  > +  <form method="dialog" class="hidden group-open:block">
  > +    <button>Back</button>
  > +  </form>
  > ```

  (A `<form method="dialog">` submit closes the enclosing `<dialog>` natively, with zero JS — Doyle relies on this rather than writing a `close()` action on the Stimulus controller.)

  On the `redirect_to ..., turbo_frame: "_top"` / `Turbo::FrameRedirectable` mechanism (from the commit messages, since the README doesn't narrate this part in prose): the two trailing commits, "Persist `Turbo-Frame:` response header through redirects" and its revision, exist because after a successful `create` inside the frame, the controller needs the *redirect response* (not just the original response) to still carry a `Turbo-Frame: _top` header so the client-side `turbo:submit-end` listener in `application.js` knows to break out of the frame/dialog and do a full Turbo visit — Rails' `flash` is used to smuggle that header value across the redirect.

- **Accessibility notes** (primary focus of this branch):

  - **`<dialog>` element**: yes — the modal is the native HTML `<dialog>` element (`app/views/layouts/application.html.erb`), not a hand-rolled `<div>`. It wraps a single shared `<turbo-frame id="dialog">` that all modal-triggering forms/links target.
  - **`role="dialog"`**: explicitly set (`role="dialog"`) on the `<dialog>` element, even though `<dialog>` has an implicit ARIA role — likely added defensively for the polyfilled/pre-standardization period this branch was written in.
  - **`aria-modal="true"`**: explicitly set alongside `role="dialog"` on the same element.
  - **Focus trapping**: no hand-rolled focus-trap code exists anywhere in the diff (confirmed via `git grep -i focus` across every changed file — zero matches). Focus containment is delegated entirely to the browser's native `HTMLDialogElement.showModal()` behavior, which automatically traps focus within the dialog while open. No Stimulus `keydown`/`Tab` cycling logic is present.
  - **Focus restoration on close**: not implemented in custom code; this is native `<dialog>` behavior — `showModal()` remembers and restores focus to the previously-focused element when the dialog closes (via `close()`, the `method="dialog"` form submit, or Escape).
  - **`inert`**: not used anywhere in the diff. Not needed — `showModal()` natively makes the rest of the document inert to interaction/pointer events while the dialog is open (top-layer rendering + implicit inert-like modal state), so Doyle doesn't need to set the attribute by hand.
  - **Autofocus**: no `autofocus` attribute is set on any form field. Native `showModal()` autofocus behavior (which focuses the first focusable element, or the dialog itself if none, per the HTML spec) is relied upon implicitly; no explicit override.
  - **Close-on-Escape**: not implemented in custom JS — this is native `<dialog>` behavior when opened via `showModal()` (pressing Escape fires a `cancel` event and closes the dialog). No `keydown` listener overrides or blocks it in this branch.
  - **Close-on-backdrop-click**: NOT implemented. There is no click listener on the dialog's `::backdrop` or on the dialog element checking `event.target === dialog` to close on outside-click. The only explicit close mechanism in the diff is the `<form method="dialog">`/`<button>Back</button>` disclosure pair inside `new.html.erb`, which submits a native `dialog`-method form to close it. So backdrop-click-to-close is a documented gap in this implementation.
  - **`aria-live` / live regions**: no explicit `aria-live` attribute is used anywhere. Validation errors are rendered inside an `<output role="alert">` element (`app/views/messages/new.html.erb`), which gets an implicit `assertive` live-region behavior from `role="alert"` — this is how form validation errors are announced to screen readers, not via a manually authored `aria-live` region.
  - **`aria-expanded`**: used on the two disclosure-style trigger buttons: `<button name="turbo_frame" value="dialog" aria-expanded="false">New message</button>` in `index.html.erb`, and `<button aria-expanded="true">Back</button>` inside the dialog's own "Back" form in `new.html.erb`. These are static (not toggled by JS at runtime in this branch) but signal the open/closed disclosure relationship between the trigger and the dialog to assistive tech.
  - **CSS-only open/close via Tailwind `group`**: the `<dialog>` carries `class="group"`, and content inside the frame uses Tailwind's `group-open:` variant (e.g. `class="hidden group-open:block"` on the "Back" form, `class="group-open:hidden"` on the "Back" link) — this ties visibility of the two states purely to the native `[open]` attribute of the `<dialog>`, reinforcing that state is driven by the browser's own dialog semantics rather than a Stimulus-toggled class.
  - **System test verification of a11y semantics**: `test/system/messages_test.rb` explicitly asserts against the `:modal` Capybara selector (`within :modal do ... end`) and against `:alert` (`assert_selector :alert, "To can't be blank"`), confirming the intended modal/alert semantics are testable/exercised via accessible selectors, not just visual position.

- **Currency check**: This branch's commits span 2021-08-21 to 2022-02-08, roughly **two years before Turbo 8** (released February 2024, which added page morphing / `Turbo.session.drive` refresh methods). The branch therefore predates Turbo 8 entirely and uses none of its morphing APIs — it's built on plain Turbo Frames/Drive semantics (`data-turbo-frame`, `turbo:frame-load`, `turbo:submit-end`, response `Turbo-Frame` header). It DOES use the native `<dialog>` element (a post-2022 browser-baseline feature), which is notable because at the time this branch was written (Aug 2021–Feb 2022), `<dialog>` had only just landed in WebKit and was still unsupported in Firefox — hence the explicit `dialog-polyfill` dependency loaded from `cdn.skypack.dev`. Two concrete currency/deprecation flags: (1) **Skypack (`cdn.skypack.dev`) shut down in 2024** — both the polyfill script (`https://cdn.skypack.dev/dialog-polyfill`) and its stylesheet (`https://cdn.skypack.dev/dialog-polyfill/dist/dialog-polyfill.css`) are dead links today, so this exact code would 404 if run unmodified; (2) the **`dialog-polyfill` dependency itself is now obsolete** — native `<dialog>` (including `showModal()`, the `::backdrop` pseudo-element, and Escape-to-close) has been supported in all major evergreen browsers (Chrome, Firefox, Safari, Edge) since roughly 2022, so a modern rebuild of this technique would drop the polyfill and its `<link>`/`import` entirely. (3) The layout also loads Tailwind via the `cdn.tailwindcss.com` play-CDN script, which the Tailwind docs themselves warn is not intended for production use — not a deprecation, but a "don't ship this as-is" flag worth noting alongside the others.

- **Does he pair a Stimulus controller with an ERB helper / partial wrapper?**: No dedicated Ruby helper method is defined for the dialog (no `def dialog_for(...)` or similar in `app/helpers`). The pairing that does exist is simpler: a single shared, static ERB partial-like wrapper baked directly into `app/views/layouts/application.html.erb` (the `<dialog data-controller="dialog" ...><turbo-frame id="dialog"></turbo-frame></dialog>` block, always rendered on every page) plus the `dialog_controller.js` Stimulus controller wired to it via `data-controller="dialog"` and `data-action="turbo:frame-load->dialog#showModal"`. Individual views "invoke" this shared dialog not through a Ruby helper call but by targeting the frame declaratively — e.g. `data-turbo-frame="dialog"` on the trigering `<form>` in `index.html.erb`, and `id="<%= params[:turbo_frame] || dom_id(@message) %>"` on the `<turbo-frame>` in `new.html.erb`, which lets the same `new.html.erb` template render either inside the dialog frame (`turbo_frame` param present, `id="dialog"`) or as a normal full-page frame (`turbo_frame` param absent, falls back to `dom_id(@message)`).

### drawer

- **Technique**: A right-side sliding "drawer" panel (Tailwind slide-over UI) rendered into a persistent `turbo_frame_tag :drawer`, driven by Rails request variants (`?variant=drawer`) so the same `new`/`edit` actions can render either a full page or a `+drawer` partial-in-frame, with CSS View Transitions and a small Stimulus controller (using the `el-transition` library) providing the slide/fade animation on open and — critically — on close, since Turbo Frames don't animate content removal on their own.

- **Problem it solves**: Turbo Frames can morph/replace content when navigating *into* a frame, but there's no native way to play an exit animation when a frame's content is cleared (e.g. closing a drawer/modal panel) — the DOM node is just removed. This branch layers Turbo 8's response-targeting/variants and turbo-stream `refresh` actions on top of a hand-built frame + Stimulus + `el-transition` combo to get a real open/close slide animation for a "new/edit product in a side panel" flow, without adopting a JS modal library.

- **Commit dates**: 2024-11-26..2025-01-02 (drawer-specific work: 2024-11-26..2024-12-09; the 2025-01-02 commit is an unrelated Tailwind-CDN-to-gem swap)

- **Needs JS?**: yes. Two pieces:
  1. An imported third-party micro-library `el-transition` (pinned via importmap from a CDN: `pin "el-transition", to: "https://ga.jspm.io/npm:el-transition@0.0.7/index.js"`) which provides `enter(el)`/`leave(el)` helpers that toggle Tailwind transition utility classes (`data-transition-enter*` / `data-transition-leave*` attributes) to animate elements in/out.
  2. A small custom Stimulus controller (`drawer_controller.js`, ~40 lines) that hooks Turbo's `turbo:before-frame-render` event on the `#drawer` frame, detects whether the frame is about to go from having content to being empty (i.e. the drawer is closing), and if so calls `event.preventDefault()`, plays the `leave()` animation on the backdrop/panel elements, removes them manually, then calls `event.detail.resume()` to let Turbo continue the (now-empty) frame render.

- **Key code**:

  ```ruby
  # app/controllers/products_controller.rb
  class ProductsController < ApplicationController
    before_action :set_product, only: %i[ show edit update destroy ]
    before_action :set_variant, only: %i[ new edit update create ]

    def index
      @products = Product.all
    end

    def show
    end

    def new
      request.variant = @variant
      @product = Product.new
    end

    def edit
      request.variant = @variant
    end

    def create
      @product = Product.new(product_params)

      if @product.save
        respond_to do |format|
          format.turbo_stream if turbo_frame_request?
          format.html { redirect_to products_path, notice: "Product was successfully created." }
        end
      else
        render :new, variants: @variant, status: :unprocessable_entity
      end
    end

    def update
      if @product.update(product_params)
        respond_to do |format|
          format.turbo_stream if turbo_frame_request?
          format.html { redirect_to products_path, notice: "Product was successfully updated." }
        end
      else
        render :edit, variants: @variant, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy!

      redirect_to products_path, status: :see_other, notice: "Product was successfully destroyed."
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :description)
    end

    def set_variant
      @variant ||= :drawer if params[:variant] == "drawer"
    end
  end
  ```

  ```erb
  <%# app/views/application/_drawer.html.erb %>
  <%# locals: (title: )%>

  <%= turbo_frame_tag :drawer do %>
    <div class="relative z-10" aria-labelledby="slide-over-title" role="dialog" aria-modal="true">
      <div id="backdrop"
           class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
           data-drawer-target="backdrop"
           data-transition-enter="ease-in-out duration-500"
           data-transition-enter-start="opacity-0"
           data-transition-enter-end="opacity-100"
           data-transition-leave="ease-in-out duration-500"
           data-transition-leave-start="opacity-100"
           data-transition-leave-end="opacity-0"
           aria-hidden="true"></div>

      <div class="fixed inset-0 overflow-hidden">
        <div class="absolute inset-0 overflow-hidden">
          <div class="pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10">
            <div id="panel"
                 class="pointer-events-auto relative w-screen max-w-md"
                 data-transition-enter="transform transition ease-in-out duration-500 sm:duration-700"
                 data-transition-enter-start="translate-x-full"
                 data-transition-enter-end="translate-x-0"
                 data-transition-leave="transform transition ease-in-out duration-500 sm:duration-700"
                 data-transition-leave-start="translate-x-0"
                 data-transition-leave-end="translate-x-full"
                 data-drawer-target="panel">
              <div class="absolute left-0 top-0 -ml-8 flex pr-2 pt-4 sm:-ml-10 sm:pr-4">
                <%= link_to :back, class: "relative rounded-md text-gray-300 hover:text-white focus:outline-none focus:ring-2 focus:ring-white" do %>
                  <span class="absolute -inset-2.5"></span>
                  <span class="sr-only">Close panel</span>
                  <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true" data-slot="icon">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
                  </svg>
                <% end %>
              </div>

              <div class="flex h-full flex-col overflow-y-scroll bg-white py-6 shadow-xl">
                <div class="px-4 sm:px-6">
                  <h2 class="text-base font-semibold text-gray-900" id="slide-over-title"><%= title %></h2>
                </div>
                <div class="relative mt-6 flex-1 px-4 sm:px-6">
                  <%= yield %>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  <% end %>
  ```

  ```erb
  <%# app/views/products/new.html+drawer.erb %>
  <%= render "drawer", title: "New product" do %>
    <%= render "form", product: @product %>
  <% end %>
  ```

  ```erb
  <%# app/views/products/edit.html+drawer.erb %>
  <%= render "drawer", title: "Edit product" do %>
    <%= render "form", product: @product %>
  <% end %>
  ```

  ```erb
  <%# app/views/products/index.html.erb %>
  <div class="w-full">
    <% if notice.present? %>
      <p class="py-2 px-3 bg-green-50 mb-5 text-green-500 font-medium rounded-lg inline-block" id="notice"><%= notice %></p>
    <% end %>

    <% content_for :title, "Products" %>

    <div class="flex justify-between items-center">
      <h1 class="font-bold text-4xl">Products</h1>
      <%= link_to "New product",
        new_product_path(variant: :drawer),
        class: "rounded-lg py-3 px-5 bg-blue-600 text-white block font-medium",
        data: { turbo_frame: :drawer } %>
    </div>

    <div id="products" class="min-w-full">
      <% @products.each do |product| %>
        <%= render product %>
      <% end %>
    </div>
  </div>

  <%= turbo_frame_tag :drawer, data: {controller: "drawer", action: "turbo:before-frame-render->drawer#animate"} %>
  ```

  ```erb
  <%# app/views/products/_product.html.erb %>
  <div id="<%= dom_id product %>">
    <p class="my-5">
      <strong class="block font-medium mb-1">Name:</strong>
      <%= product.name %>
    </p>

    <p class="my-5">
      <strong class="block font-medium mb-1">Description:</strong>
      <%= product.description %>
    </p>

    <p>
      <%= link_to "Edit this product",
        edit_product_path(product, variant: :drawer),
        class: "ml-2 rounded-lg py-3 px-5 bg-gray-100 inline-block font-medium",
        data: {turbo_frame: :drawer} %>
    </p>

  </div>
  ```

  ```erb
  <%# app/views/products/_form.html.erb %>
  <%= form_with(model: product, class: "contents") do |form| %>
    <% if product.errors.any? %>
      <div id="error_explanation" class="bg-red-50 text-red-500 px-3 py-2 font-medium rounded-lg mt-3">
        <h2><%= pluralize(product.errors.count, "error") %> prohibited this product from being saved:</h2>

        <ul>
          <% product.errors.each do |error| %>
            <li><%= error.full_message %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <div class="my-5">
      <%= form.label :name %>
      <%= form.text_field :name, class: "block shadow rounded-md border border-gray-400 outline-none px-3 py-2 mt-2 w-full" %>
    </div>

    <div class="my-5">
      <%= form.label :description %>
      <%= form.text_area :description, rows: 4, class: "block shadow rounded-md border border-gray-400 outline-none px-3 py-2 mt-2 w-full" %>
    </div>

    <%= hidden_field_tag :variant, @variant %>

    <div class="inline">
      <%= form.submit class: "rounded-lg py-3 px-5 bg-blue-600 text-white inline-block font-medium cursor-pointer" %>
    </div>
  <% end %>
  ```

  ```erb
  <%# app/views/products/create.turbo_stream.erb %>
   <turbo-stream action="refresh"></turbo-stream>
  ```

  ```erb
  <%# app/views/products/update.turbo_stream.erb %>
   <turbo-stream action="refresh"></turbo-stream>
  ```

  ```erb
  <%# app/views/layouts/application.html.erb %>
  <!DOCTYPE html>
  <html>
    <head>
      <title>HotwireExampleTemplate</title>
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <meta name="view-transition" content="same-origin" />
      <%= csrf_meta_tags %>
      <%= csp_meta_tag %>
      <%= stylesheet_link_tag "tailwind", "inter-font", "data-turbo-track": "reload" %>

      <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
      <%= javascript_importmap_tags %>
    </head>

    <body>
      <main class="container mx-auto mt-28 px-5 flex">
        <%= yield %>
      </main>
    </body>
  </html>
  ```

  ```css
  /* app/assets/stylesheets/application.css */
  @keyframes fade-out {
    from {
      opacity: 100%;
    }

    to {
      opacity: 0%;
    }
  }

  @keyframes fade-in {
    from {
      opacity: 0%;
    }

    to {
      opacity: 100%;
    }
  }

  @keyframes slide-out {
    from {
      transform: translateX(0%);
    }

    to {
      transform: translateX(100%);
    }
  }

  @keyframes slide-in {
    from {
      transform: translateX(100%);
    }

    to {
      transform: translateX(0%);
    }
  }

  ::view-transition-old(backdrop) {
    animation: 0.4s ease-in both fade-out;
  }

  ::view-transition-new(backdrop) {
    animation: 0.4s ease-in both fade-in;
  }

  ::view-transition-old(panel) {
    animation: 0.4s ease-in both slide-out;
  }

  ::view-transition-new(panel) {
    animation: 0.4s ease-in both slide-in;
  }

  #panel {
    view-transition-name: panel;
  }

  #backdrop {
    view-transition-name: backdrop;
  }
  ```

  ```js
  // app/javascript/controllers/drawer_controller.js
  import { Controller } from "@hotwired/stimulus";
  import { enter, leave } from "el-transition";

  // Connects to data-controller="drawer"
  export default class extends Controller {
    static targets = ["backdrop", "panel"];

    #isEntering;
    #isLeaving;

    backdropTargetConnected(target) {
      if (this.#isEntering) enter(target);
    }

    panelTargetConnected(target) {
      if (this.#isEntering) enter(target);
    }

    async animate(event) {
      const {
        detail: { newFrame },
      } = event;

      const currentChildCount = this.element.children.length;
      const newChildCount = newFrame.children.length;

      this.#isEntering = currentChildCount == 0 && newChildCount > 0;
      this.#isLeaving = currentChildCount > 0 && newChildCount == 0;

      if (this.#isLeaving) {
        event.preventDefault();

        await Promise.all([
          leave(this.backdropTarget).then(() => this.backdropTarget.remove()),
          leave(this.panelTarget).then(() => this.panelTarget.remove()),
        ]);

        event.detail.resume();
      }
    }
  }
  ```

  ```ruby
  # config/importmap.rb
  # Pin npm packages by running ./bin/importmap

  pin "application", preload: true
  pin "@hotwired/turbo-rails", to: "turbo.min.js"
  pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
  pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
  pin_all_from "app/javascript/controllers", under: "controllers"
  pin "trix"
  pin "@rails/actiontext", to: "actiontext.js"
  pin "tailwind.config"
  pin "el-transition", to: "https://ga.jspm.io/npm:el-transition@0.0.7/index.js"
  ```

- **Doyle's stated tradeoffs**: No branch-specific README; reconstructed from commit series. Commit messages used as the primary narrative source (these are Steve Polito's messages, not Sean Doyle's — see note below):

  > "Create faux drawer" — commit title for the initial slide-over UI built from request variants (`app/views/products/new.html+drawer.erb`, `edit.html+drawer.erb`) rendered inside a Tailwind "slide-over" panel partial, before any frame/animation wiring existed.

  > "Enable view transitions" — sole body content is the diff adding `<meta name="view-transition" content="same-origin" />` to the layout, turning on the browser's View Transitions API for same-origin Turbo navigations.

  > "Create custom view transitions" — adds named `::view-transition-old/new(panel|backdrop)` CSS animations and `view-transition-name: panel` / `view-transition-name: backdrop` so the drawer's own backdrop/panel elements get bespoke slide/fade transitions instead of the browser's default cross-fade.

  > "Render drawer in a frame" — commit title for wrapping the drawer partial in `turbo_frame_tag :drawer`, adding `turbo_stream` responses to `create`/`update` (`format.turbo_stream if turbo_frame_request?`) that just `<turbo-stream action="refresh">`, and pointing the edit/new links at `data: {turbo_frame: :drawer}`.

  > "Animate frame" — commit title for adding the `drawer_controller.js` Stimulus controller and pinning the `el-transition` library, explicitly to solve frame-content removal not animating: the controller intercepts `turbo:before-frame-render`, detects an entering-vs-leaving transition by comparing child counts of the current frame vs. the incoming frame, and manually runs the `leave()` animation before letting Turbo actually empty the frame (`event.preventDefault()` ... `event.detail.resume()`).

  Note: this repository is a fork/derivative of `thoughtbot/hotwire-example-template` (originally by Sean Doyle); all commits on this `drawer` branch are authored by Steve Polito, not Sean Doyle. There is no prose tradeoff discussion anywhere in the series beyond the commit titles/bodies quoted above.

- **Accessibility notes**: The drawer partial has `role="dialog"` and `aria-modal="true"` on its outer wrapping `<div>`, plus `aria-labelledby="slide-over-title"` pointing at the `<h2 id="slide-over-title">` title element. The backdrop `<div id="backdrop">` has `aria-hidden="true"`. The close ("back") link has visually-hidden text via `<span class="sr-only">Close panel</span>` and an `<span class="absolute -inset-2.5"></span>` to enlarge its hit target. No use of native `<dialog>`, no explicit focus trapping code, no `inert`, no `autofocus`, no `aria-live`, no `alert` role, no explicit focus-restoration logic, and no keyboard escape-to-close handler — closing is done only via the "Close panel" link (`link_to :back`) which does a Turbo visit back to the previous frame state, not a JS-driven dialog close. Because it's a plain `<div role="dialog">` (not native `<dialog>`), the browser provides none of the built-in modal semantics (focus trap, Esc-to-close, top-layer stacking) — these would have to be added manually and are not present in this branch.

- **Currency check**:
  - **Turbo 8 morphing**: NOT used. `git grep` for `turbo-refresh-method`, `data-turbo-morph`, and `Turbo.session.drive` across `origin/drawer` returns zero hits. The `create.turbo_stream.erb` / `update.turbo_stream.erb` responses use `<turbo-stream action="refresh"></turbo-stream>` (Turbo 8's page-refresh stream action, which broadcasts a full-page morph refresh to *other* tabs/requests), but this is the turbo-stream `refresh` action, not the `<meta name="turbo-refresh-method" content="morph">` opt-in for regular navigations — that meta tag is absent from `app/views/layouts/application.html.erb`. The drawer's own open/close animation is handled entirely by the custom Stimulus controller + `el-transition`, not by morph.
  - **Native `<dialog>` element**: NOT used. `git grep -n "<dialog"` across `origin/drawer` returns zero hits. The drawer is a plain `<div role="dialog" aria-modal="true">` inside a `turbo_frame_tag`, not the HTML `<dialog>` element.
  - **View Transitions API**: USED. `app/views/layouts/application.html.erb` line 6: `<meta name="view-transition" content="same-origin" />` (enables Turbo's use of the browser View Transitions API for same-origin navigations). `app/assets/stylesheets/application.css` defines `::view-transition-old(backdrop)`, `::view-transition-new(backdrop)`, `::view-transition-old(panel)`, `::view-transition-new(panel)` with custom `fade-in`/`fade-out`/`slide-in`/`slide-out` keyframe animations, paired with `#panel { view-transition-name: panel; }` and `#backdrop { view-transition-name: backdrop; }` to scope named transitions to just those two elements. However, note this CSS transition machinery appears to be superseded/left-in-place after the later "Animate frame" commit switched the actual drawer close animation to the JS-driven `el-transition` (`enter`/`leave`) + Stimulus approach — both mechanisms exist in the final tree simultaneously.
  - **`data-turbo-permanent`**: NOT used. Zero hits for `turbo-permanent` in `origin/drawer`.

- **Does he pair a Stimulus controller with an ERB helper / partial wrapper?**: Yes — a Stimulus controller paired with a partial (not a Ruby helper method). There's no Ruby helper method (e.g. no `content_tag` or `content_for`-based helper in `app/helpers/`); the pairing is a shared partial (`app/views/application/_drawer.html.erb`) invoked from the two variant-specific views, with the Stimulus controller wired onto the *outer* `turbo_frame_tag` in the index view, not on the partial itself.

  The drawer frame declares the controller and its Turbo event binding directly on the `turbo_frame_tag` helper call in `app/views/products/index.html.erb`:

  ```erb
  <%= turbo_frame_tag :drawer, data: {controller: "drawer", action: "turbo:before-frame-render->drawer#animate"} %>
  ```

  The `_drawer.html.erb` partial (invoked as `<%= render "drawer", title: "New product" do %> ... <% end %>` from `new.html+drawer.erb` / `edit.html+drawer.erb`) renders its own inner `turbo_frame_tag :drawer do ... end` wrapping the backdrop/panel markup — the outer empty frame (with the Stimulus controller) in `index.html.erb` and the inner content-bearing frame emitted by the partial share the same `:drawer` frame ID, so Turbo replaces the empty outer frame's contents with the partial's rendered frame content on navigation. The `backdropTarget`/`panelTarget` elements the controller manipulates (`data-drawer-target="backdrop"` / `data-drawer-target="panel"`) are defined inside that partial, and the controller's `backdropTargetConnected`/`panelTargetConnected` lifecycle callbacks fire `enter()` from `el-transition` when new targets connect during an entering transition.

### hotwire-example-button-alert-template

- **Technique**: A `<button>` carries an inert `<template>` containing a `<turbo-stream action="append">` (itself wrapping another `<template>` with the alert markup); a generic `clone` Stimulus controller clones the template's `content` on click and appends it anywhere in the connected DOM, at which point the browser upgrades the now-connected `<turbo-stream>` custom element, which executes its own `action`/`target` (append the alert into `#alerts`, or later remove itself by `id`) and then disconnects itself.

- **Problem it solves**: Rails' `ActionDispatch::Flash` gives you server-rendered `notice`/`alert` messaging for full-page requests, but there's no equivalent for purely client-side interactions (e.g. "copied to clipboard") that never hit the server. This technique lets the server pre-render the entire alert (structure, content, styles, and even its own dismissal behavior) at initial page-load time, embedded inertly inside a `<template>`, so a client-side-only event (a clipboard copy) can trigger server-authored HTML being spliced into the document without any `fetch`/`XMLHttpRequest` round-trip or duplicate client-side templating logic.

- **Commit dates**: 2022-02-06..2022-03-04 (first..last substantive commits: "Our starting point" 2022-02-06, "Removing alerts" 2022-02-07, "Appending alerts" 2022-03-04; a later `[SKIP]` Replit-config commit dated 2022-05-20 is infrastructure-only and not part of the technique).

- **Needs JS?**: yes — two small Stimulus controllers, no other JS:
  - `clipboard_controller.js` (`copy` action): calls `navigator.clipboard.writeText(value)` on the button's `value`.
  - `clone_controller.js` (`append` action): the reusable generic controller that does `content.cloneNode(true)` on each `source` `<template>` target and appends the clone to `event.target` (the element the click happened on — its exact DOM position doesn't matter, since the cloned `<turbo-stream>` element relocates its own content once connected). No Turbo Stream network responses, no `fetch`/XHR — everything is pre-rendered server-side HTML sitting inert in the initial page load.

- **Key code**:

  ```ruby
  # app/controllers/invitation_codes_controller.rb
  class InvitationCodesController < ApplicationController
    def show
      @invitation_code = params[:id]
    end
  end
  ```

  ```ruby
  # config/routes.rb
  Rails.application.routes.draw do
    # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
    resources :invitation_codes, only: :show

    # Defines the root path route ("/")
    # root "articles#index"
    root to: redirect("/invitation_codes/abc123")
  end
  ```

  ```erb
  <%# app/views/invitation_codes/show.html.erb %>
  <fieldset>
    <legend>Copy</legend>

    <label>
      Invitation code

      <input value="<%= @invitation_code %>" readonly>
    </label>

    <button type="button" value="<%= @invitation_code %>"
            data-controller="clipboard clone"
            data-action="click->clipboard#copy click->clone#append">
      Copy to clipboard

      <template data-clone-target="source">
        <turbo-stream action="append" target="alerts">
          <template>
            <div id="copied_to_clipboard_alert" role="alert" class="border border-solid rounded-md m-4 p-4">
              Copied to clipboard

              <button type="button"
                      data-controller="clone"
                      data-action="click->clone#append">
                Dismiss

                <template data-clone-target="source">
                  <turbo-stream action="remove" target="copied_to_clipboard_alert"></turbo-stream>
                </template>
              </button>
            </div>
          </template>
        </turbo-stream>
      </template>
    </button>
  </fieldset>

  <fieldset>
    <legend>Paste</legend>

    <label>
      Invitation code
      <input>
    </label>
  </fieldset>

  <div id="alerts" class="absolute bottom-0 right-0 w-96"></div>
  ```

  ```javascript
  // app/javascript/controllers/clipboard_controller.js
  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    copy({ target: { value } }) {
      navigator.clipboard.writeText(value)
    }
  }
  ```

  ```javascript
  // app/javascript/controllers/clone_controller.js
  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static targets = [ "source" ]

    append(event) {
      const destination = event.target

      for (const { content } of this.sourceTargets) {
        destination.append(content.cloneNode(true))
      }
    }
  }
  ```

  ```erb
  <%# app/views/layouts/application.html.erb %>
  <!DOCTYPE html>
  <html>
    <head>
      <title>HotwireExampleTemplate</title>
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <%= csrf_meta_tags %>
      <%= csp_meta_tag %>

      <script src="https://cdn.tailwindcss.com"></script>
      <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
      <%= javascript_importmap_tags %>
    </head>

    <body class="flex flex-col justify-center h-screen max-w-prose m-auto">
      <%= yield %>
    </body>
  </html>
  ```

  ```ruby
  # test/system/invitation_codes_test.rb
  require "application_system_test_case"

  class InvitationCodesTest < ApplicationSystemTestCase
    test "copy code to clipboard" do
      code = "secret"

      visit invitation_code_path(id: code)
      click_on "Copy to clipboard"
      send_keys(:tab).then { assert_field "Invitation code", focused: true }
      send_keys :meta, "v"

      assert_field "Invitation code", focused: true, with: code
      within(:alert, "Copied to clipboard") { click_on "Dismiss" }

      assert_no_selector :alert, "Copied to clipboard"
    end
  end
  ```

  Confirmed via `config/importmap.rb`: `pin "@hotwired/turbo-rails", to: "turbo.js"` and `pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true` — both Turbo and Stimulus are loaded, and the `<turbo-stream>` elements rely on Turbo's custom-element upgrade/connectedCallback behavior to actually perform their `append`/`remove` actions once cloned into the connected DOM.

- **Doyle's stated tradeoffs**: This branch has a real branch-specific README (19,453 bytes) — quoted directly:
  > "**Value proposition**: You have abstractions and extractions on the server-side, re-use them to share concepts with the client-side without re-inventing parallel versions of them."

  > "The server encodes design decisions into the HTML in a way that's durable across transmission and reconstruction. It controls the structure, content, and presentation of the message, and the client controls the timing and conditions of the message's presentation."

  > "Since this interaction is _only_ client-side in the browser, there's an opportunity to do as much work as possible on the server, to the point where the client's responsibilities are constrained, and only include appending to and removing from the document"
  >
  > "* co-locates decisions about structure, content, styles, and element references in the same server-generated template
  > * declarative, pre-populated state"

  > "It's not important which element we append the contents of the `<template data-clone-target="source">` element. The `clone#append` action appends the element to the `Event.target` (in our case, the `<button>` element)." — i.e. the `clone` controller doesn't need to know the real destination; the embedded `<turbo-stream target="alerts">` handles the actual routing once connected.

  Explicit "Included"/"Excluded" summary from the README's "Wrapping up" section:
  > "Included:
  > * an entirely client-side interaction augmented by server-generated HTML
  > * declaratively encoded DOM operations through `<template>` and `<turbo-stream>` elements
  > * three general purpose controllers with potential for re-use across the codebase
  >
  > Excluded:
  > * parallel alert implementations split across the client-server boundary
  > * transforming JSON into HTML
  > * `XMLHttpRequest`, `fetch`"

  On the generic `clone` controller's use of the plural `sourceTargets` vs. singular `sourceTarget`:
  > "The `clone#append` references the collection of `<template>` elements through its the **plural** `this.sourceTargets` property. In our example's case, there's a single element marked with `[data-clone-target="source"]`, so direct access through the **singular** `this.sourceTarget` could suffice. ... Looping over the collection of targets supports **both** scenarios **without** any conditionals, and bakes-in future-proofed support for acting upon multiple embedded `<template>` targets."

- **Accessibility notes**: The alert `<div>` is explicitly marked `role="alert"` (`<div id="copied_to_clipboard_alert" role="alert" class="border border-solid rounded-md m-4 p-4">`) — no `aria-live` attribute is used (the `role="alert"` implicitly conveys `aria-live="assertive"` semantics per ARIA spec). No `<dialog>`, no `aria-modal`, no explicit focus trapping, no `inert`, no `autofocus` anywhere in the branch. The system test confirms the a11y hook is load-bearing for testing, not just semantic sugar: `within(:alert, "Copied to clipboard") { click_on "Dismiss" }` and `assert_no_selector :alert, "Copied to clipboard"` use Capybara's ARIA-role-based `:alert` selector, meaning the `role="alert"` attribute is what the test suite locates the alert by.

- **Currency check**: Commits are dated 2022-02-06 through 2022-03-04 (with an unrelated Replit-config commit on 2022-05-20), which is roughly two years before Turbo 8's morphing release (February 2024). This branch **predates Turbo 8** and does not use or reference Turbo Drive page morphing or `<turbo-frame>` morphing at all — it's built on Turbo Streams' `<turbo-stream>` custom element mechanism (append/remove actions), which is unaffected by/orthogonal to the Turbo 8 morphing changes and remains current API today. No deprecated APIs were found — `data-controller`, `data-action`, Stimulus `static targets`, `<turbo-stream action="append"|"remove" target="...">`, and `content.cloneNode(true)` on a native `<template>` element's `.content` are all still-current, unchanged APIs as of Turbo 8/Stimulus 3.x.

- **Does he pair a Stimulus controller with an ERB helper / partial wrapper?**: no — there is no Ruby helper method or extracted ERB partial anywhere in this branch. The `clone` and `clipboard` controllers are paired directly with inline markup written straight into `app/views/invitation_codes/show.html.erb` (no `render partial:` calls, no `app/helpers` additions beyond the default generated `ApplicationHelper`/`InvitationCodesHelper`, which are untouched by this diff). All templating co-location happens through nested `<template>`/`<turbo-stream>` elements directly in the single view file, not through server-side Ruby helper abstraction.

---

## Per-branch: state, lists & focus

### hotwire-example-pagination

- **Technique**: Turbo-Frame-per-page pagination links that morph into infinite scroll via `loading="lazy"` frames, `data-turbo-action="replace"`, and a tiny Stimulus controller that unwraps the frame once it renders.

- **Problem it solves**: A classic paginated index (using `pagy`) forces a full-page navigation for every "Next page"/"Previous page" click, and offers no path to infinite scroll without a page rewrite. Doyle incrementally layers Turbo Frames onto the exact same server-rendered `pagy` view so that (a) only the frame content is replaced on navigation, (b) the pagination `<a>` links themselves can be visually hidden once no longer relevant, (c) frame navigations get pushed onto the browser history/URL bar like a full visit (`data-turbo-action="replace"`), and (d) the trailing frame lazy-loads its own next page automatically when scrolled into view, producing infinite scroll — all with zero custom JavaScript beyond a 4-line Stimulus controller and zero custom pagination backend logic.

- **Commit dates**: 2021-10-24 (`Our starting point` / `Loading with Turbo Frames` / `Hiding pagination links` / `Promoting navigations` / `Scrolling infinitely`) .. 2022-02-05 (`Replacing Frames with their content`), plus an unrelated 2022-08-15 `[SKIP]` Gitpod config commit.

- **Needs JS?** — Yes, minimally: a single 4-line Stimulus controller (`element_controller.js`) with one action, used only to unwrap (`replaceWith(...target.children)`) the `<turbo-frame>` wrapper once Turbo has rendered its content, so the pagination link doesn't stay nested inside a frame element in the final DOM. Everything else (frame navigation, lazy-loading, history push) is native Turbo Frame/driver behavior requiring no hand-written JS.

- **Key code**

```ruby
# app/models/message.rb
class Message < ApplicationRecord
  has_rich_text :content

  scope :most_recent_first, -> { order created_at: :desc }
end
```

```ruby
# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  def index
    @page, @messages = pagy Message.where(query_params).most_recent_first
  end

  private

  def query_params
    params.permit(:author)
  end
end
```

```ruby
# config/initializers/pagy.rb
ActiveSupport.on_load :action_controller_base do
  include Pagy::Backend
end

ActiveSupport.on_load :action_view do
  include Pagy::UrlHelpers
end
```

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  resources :messages, only: :index

  root to: redirect("/messages")
end
```

```ruby
# db/migrate/20211024151445_create_messages.rb
class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.string :author

      t.timestamps
    end
  end
end
```

```erb
<%# app/views/messages/index.html.erb — FINAL state, after all incremental commits %>
<h1>Messages</h1>

<turbo-frame id="messages_page_<%= @page.page %>" class="grid gap-2" target="_top">
  <% if @page.prev %>
    <turbo-frame id="messages_page_<%= @page.prev %>" class="group" data-turbo-action="replace"
                 data-controller="element" data-action="turbo:frame-render->element#replaceWithChildren">
      <%= link_to pagy_url_for(@page, @page.prev), rel: "prev", class: "hidden group-first-of-type:block" do %>
        Previous page
      <% end %>
    </turbo-frame>
  <% end %>

  <% @messages.each do |message| %>
    <article class="border border-solid">
      <%= message.content %>

      <p>
        Posted by: <%= link_to message.author, messages_path(author: message.author) %>
      </p>
    </article>
  <% end %>

  <% if @page.next %>
    <turbo-frame id="messages_page_<%= @page.next %>" class="group" data-turbo-action="replace"
                 src="<%= pagy_url_for(@page, @page.next) %>" loading="lazy"
                 data-controller="element" data-action="turbo:frame-render->element#replaceWithChildren">
      <%= link_to pagy_url_for(@page, @page.next), rel: "next", class: "hidden group-last-of-type:block" do %>
        Next page
      <% end %>
    </turbo-frame>
  <% end %>
</turbo-frame>
```

```javascript
// app/javascript/controllers/element_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  replaceWithChildren({ target }) {
    this.element.replaceWith(...target.children)
  }
}
```

```erb
<%# app/views/layouts/application.html.erb — only diff vs. main %>
-  <body>
+  <body class="max-w-prose m-auto">
```

```ruby
# test/system/messages_test.rb — FULL FILE
require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
  test "renders a page-worth of Message records sorted from most recent to least recent" do
    using_page_size 20 do |page_size|
      messages = Message.most_recent_first

      visit messages_path

      assert_no_link "Previous page"
      assert_messages messages.limit(page_size)
      assert_link "Next page", count: 1
    end
  end

  test "renders a page-worth of Message records with an offset" do
    using_page_size 20 do |page_size|
      messages = Message.most_recent_first

      visit messages_path(page: 2)

      assert_link "Previous page", count: 1
      assert_messages messages.offset(page_size).limit(page_size)
      assert_link "Next page", count: 1
    end
  end

  test "appends the next page-worth of Message records" do
    using_page_size 20 do |page_size|
      messages = Message.most_recent_first

      visit messages_path
      click_on("Next page") { _1["rel"] == "next" }

      assert_link "Previous page", count: 1
      assert_messages messages.limit(page_size * 2)
      assert_link "Next page", count: 1
    end
  end

  test "prepends the previous page-worth of Message records" do
    using_page_size 20 do |page_size|
      messages = Message.most_recent_first

      visit messages_path(page: 2)
      click_on("Previous page") { _1["rel"] == "prev" }

      assert_link "Previous page", count: 1
      assert_messages messages.limit(page_size * 2)
      assert_link "Next page", count: 1
    end
  end

  test "navigates page from links in Article content" do
    using_page_size 20 do |page_size|
      messages = Message.most_recent_first
      author = messages.pick(:author)

      visit messages_path(page: 2)
      click_on author, match: :first

      assert_no_link "Previous page"
      assert_messages messages.limit(page_size)
    end
  end

  test "does not infinite-scroll to the previous page-worth of Message records" do
    using_page_size 20 do |page_size|
      messages = Message.most_recent_first

      visit messages_path(page: 2)
      scroll_to find_link "Next page"

      assert_link "Previous page", count: 1
      assert_messages messages.offset(page_size).limit(page_size)
      assert_link "Next page", count: 1
    end
  end

  test "infinite-scrolls to the next page-worth of Message records" do
    using_page_size 20 do |page_size|
      messages = Message.most_recent_first

      visit messages_path
      scroll_to find("article:last-of-type")

      assert_no_link "Previous page"
      assert_messages messages.limit(page_size * 2)
      assert_link "Next page", count: 1
    end
  end

  test "navigates in both directions" do
    using_page_size 20 do |page_size|
      messages = Message.most_recent_first

      visit messages_path(page: 3)
      click_link "Previous page", href: messages_path(page: 2)
      click_link "Previous page", href: messages_path(page: 1)
      scroll_to find_link "Next page"

      assert_link "Previous page", count: 0
      assert_messages messages.limit(page_size * 4)
      assert_link "Next page", count: 1
    end
  end

  def assert_messages(messages)
    assert_css "article", count: messages.size
    messages.each_with_index do |message, index|
      assert_message message, index: index
    end
  end

  def assert_message(message, index:)
    assert_text message.content.to_plain_text, count: 1

    within "article:nth-of-type(#{index + 1})" do
      assert_text message.content.to_plain_text
    end
  end

  def using_page_size(size = Pagy::DEFAULT[:items], &block)
    original_size, Pagy::DEFAULT[:items] = Pagy::DEFAULT[:items], size

    block.call(size)
  ensure
    Pagy::DEFAULT[:items] = original_size
  end
end
```

No custom CSS files are added on this branch — visual behavior (hiding stale nav links) is done entirely with Tailwind utility classes (`hidden group-first-of-type:block`, `hidden group-last-of-type:block`) applied directly in the ERB.

- **Doyle's stated tradeoffs**

> There is ongoing exploration work ([hotwired/turbo#146][]) to declaratively add this behavior directly to `<turbo-frame>` elements through the `[rendering="replace"]` attribute.

This is his one explicit forward-looking caveat: the `element_controller.js` "unwrap the frame" trick is a workaround for something he expects (or hopes) Turbo will eventually support natively via a `rendering="replace"` attribute, so the Stimulus controller is presented as a stopgap, not a permanent idiom. Beyond that one note, the README is written as a series of incremental diffs with no other explicit "pros vs. cons" prose — the tradeoffs are implicit in the fact that each section is a minimal, additive diff on top of the last (frame wrapping → content replacement → hiding stale links → history-promoting navigation → lazy infinite scroll), i.e. Doyle's structuring itself argues that each capability is a separable, optional layer you can adopt or skip independently.

- **Accessibility notes**: None found. This branch has no `aria-*` attributes, no `data-turbo-permanent`, no explicit focus management, no `autofocus`, and no `turbo:before-render`/`turbo:render` hooks. The only "focus"-adjacent concern addressed is purely visual: hiding now-redundant Previous/Next links via `hidden group-first-of-type:block` / `hidden group-last-of-type:block` Tailwind classes rather than removing them from the DOM or managing keyboard focus — this is not accessibility-motivated in any stated way, just a CSS-based visibility toggle to avoid duplicate "Next page" links piling up as infinite scroll appends frames. There is no test coverage for screen-reader behavior, focus retention across frame replacement, or keyboard-only navigation of the infinite-scroll list.

- **Currency check**: All substantive commits are from 2021-10-24, with one refinement on 2022-02-05 (`Replacing Frames with their content`) — both well before Turbo 8 (Feb 2024) introduced page morphing. Turbo 8 morphing is a *full-page-visit* replacement strategy (`<meta name="turbo-refresh-method" content="morph">`) that reconciles the whole `<body>` via idiomorph when Turbo Drive performs a page visit; it does not apply to Turbo Frame navigations or `<turbo-stream>` actions, which are what this entire branch is built on. Pagination-as-turbo-frames, `loading="lazy"` frame-based infinite scroll, and `data-turbo-action="replace"` frame promotion are frame-level and stream-level mechanisms orthogonal to morphing — morphing only changes *how* a full-document Turbo Drive visit reconciles DOM nodes (preserving scroll position and untouched elements), it doesn't give you incremental "append the next page of records" behavior for free. So Doyle's approach is still fully necessary on Turbo 8+: morphing would not replace it. The one piece of his implementation that predates a since-solved problem is the `element_controller.js` "unwrap frame" trick, which reflects an open Turbo RFC from 2021/2022 (`hotwired/turbo#146`); it's worth verifying against current Turbo (`rendering="replace"` or similar) whether that specific workaround has since been obsoleted by a native attribute, but that's independent of morphing.

- **Does he pair a Stimulus controller with an ERB helper / partial wrapper?** No. `element_controller.js` is wired directly onto the `<turbo-frame>` tags inline in `index.html.erb` via `data-controller="element" data-action="turbo:frame-render->element#replaceWithChildren"` — there is no Ruby helper method or partial that generates/wraps this markup. The `data-controller`/`data-action` attributes are hand-written literally in the view template, duplicated once for the "prev" frame and once for the "next" frame, rather than factored into a shared helper.


### hotwire-example-restore-page-state

- **Technique**: A guided tour through progressively-enhanced strategies for preserving end-user page state (scroll depth, `<details>` disclosure open/closed state, unsaved `<form>` field values) across full-page Turbo Drive navigations, using long-lived Stimulus controllers on `<html>` plus `[data-turbo-permanent]` and the `@github/session-resume` package — contrasted against the alternative of just using Turbo Stream responses.

- **Problem it solves**: When a `<form>` submission causes a full-page HTTP redirect, the browser discards all client-side state: scroll position, expanded `<details>` disclosures, and any unsaved input in other forms on the page. Doyle demonstrates several complementary/competing strategies to recover that state without abandoning conventional Rails redirects.

- **Commit dates**: 2021-12-10 → 2021-12-19 (`[GENERATED]: Generate Task model` on 2021-12-10 through `Preserve fields across visits with targets and callbacks` on 2021-12-11, with two follow-up commits on 2021-12-17 and 2021-12-19 titled "Preserving unsaved form field state (part 2)" and "(part 1)" — note the log's chronological listing is non-linear/rebased, but the outer span is 2021-12-10..2021-12-19).

- **Needs JS?** Yes, substantially — this is the most JS-heavy of the four branches. Four Stimulus controllers (`scroll`, `disclosure`, `permanence`, `session-resume`) are wired onto the root `<html>` element and stay alive for the life of the Turbo Drive process, reacting to `turbo:before-visit`, `turbo:visit`, `turbo:load`, `turbo:submit-start`, `turbo:before-render`, `turbo:render`, and `turbo:frame-render` events. It also pulls in a third-party JS package (`@github/session-resume`) via CDN import (`https://cdn.skypack.dev/@github/session-resume`).

- **Key code**

```ruby
# app/controllers/tasks_controller.rb
class TasksController < ApplicationController
  def new
    @task = Task.new
  end

  def create
    @task = Task.create! task_params

    redirect_to tasks_url
  end

  def index
    @tasks = Task.all
  end

  def edit
    @task = Task.find params[:id]
  end

  def update
    @task = Task.find params[:id]

    @task.update! task_params

    redirect_to tasks_url
  end

  private

  def task_params
    params.require(:task).permit(:details, :done)
  end
end
```

```ruby
# app/models/task.rb
class Task < ApplicationRecord
  validates :details, presence: true

  attribute :done, :boolean

  scope :to_do, -> { order(created_at: :asc).where done_at: nil }
  scope :done, -> { order(done_at: :asc).where.not done_at: nil }

  def done
    done_at.present? && done_at.past?
  end

  def done=(*)
    super

    self.done_at = read_attribute(:done) ? Time.current : nil
  end
end
```

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :tasks, only: [:index, :new, :create, :update, :edit]

  # Defines the root path route ("/")
  # root "articles#index"
  root to: redirect("/tasks")
end
```

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html data-controller="scroll disclosure session-resume"
      data-action="turbo:before-visit->scroll#cache
                   turbo:before-visit->scroll#invalidate
                   turbo:before-visit->disclosure#invalidate
                   turbo:visit->scroll#preventVisitScroll
                   turbo:load->scroll#read
                   turbo:submit-start->session-resume#setForm
                   turbo:before-render->session-resume#cache">
  <head>
    <title>HotwireExampleTemplate</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <script src="https://cdn.tailwindcss.com"></script>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="grid grid-cols-2">
    <%= yield %>
  </body>
</html>
```

Note: the README's later commits also route `turbo:render->session-resume#read` and `turbo:frame-render->session-resume#read`, but the final branch tip replaces those two with Stimulus 3 target callbacks (`fieldTargetConnected`) instead — see `session_resume_controller.js` below, and note the final `application.html.erb` action list above no longer includes those two entries because the target-callback refactor made them unnecessary.

```erb
<%# app/views/tasks/index.html.erb %>
<section>
  <h1>To-do (<%= @tasks.to_do.size %>)</h1>

  <ol>
    <%= render collection: @tasks.to_do, partial: "tasks/task" %>
  </ol>

  <details id="new_task_disclosure" data-disclosure-target="details">
    <summary>Add task</summary>
    <turbo-frame id="new_task" src="<%= new_task_path %>" loading="lazy"></turbo-frame>
  </details>
</section>

<section>
  <h1>Done (<%= @tasks.done.size %>)</h1>

  <ol>
    <%= render collection: @tasks.done, partial: "tasks/task" %>
  </ol>
</section>
```

```erb
<%# app/views/tasks/_task.html.erb %>
<li>
  <turbo-frame id="<%= dom_id task %>" data-turbo-permanent
               data-controller="permanence"
               data-action="turbo:submit-start->permanence#invalidate
                            turbo:frame-render->permanence#cache">
    <%= form_with model: task, namespace: task.id, data: { turbo_frame: "_top" } do |form| %>
      <%= form.button :done, value: !task.done do %>
        <% if task.done %>
          To do
        <% else %>
          Done
        <% end %>
      <% end %>
      <%= form.label :done, task.details %>

      <%= link_to "Edit", edit_task_path(task) %>
    <% end %>
  </turbo-frame>
</li>
```

```erb
<%# app/views/tasks/_form.html.erb %>
<%= form.label :details, class: "sr-only" %>
<%= form.text_field :details, required: true, pattern: /.*\w+.*/,
      data: { session_resume_target: "field" } %>
<%= form.button %>
```

```erb
<%# app/views/tasks/new.html.erb %>
<turbo-frame id="new_task">
  <%= form_with model: @task, data: { turbo_frame: "_top" } do |form| %>
    <%= render partial: "tasks/form", object: form %>
  <% end %>
</turbo-frame>
```

```erb
<%# app/views/tasks/edit.html.erb %>
<turbo-frame id="<%= dom_id @task %>">
  <%= form_with model: @task, namespace: @task.id do |form| %>
    <%= render partial: "tasks/form", object: form %>

    <%= link_to "Cancel", tasks_path %>
  <% end %>
</turbo-frame>
```

```javascript
// app/javascript/controllers/scroll_controller.js
import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = { top: Number }

  cache() {
    this.topValue = this.element.scrollTop
  }

  read() {
    this.element.scrollTop = this.topValue
  }

  invalidate({ detail: { url } }) {
    const { pathname } = new URL(url)

    if (window.location.pathname != pathname) this.topValue = 0
  }

  preventVisitScroll() {
    const { currentVisit } = Turbo.session.navigator

    if (currentVisit) currentVisit.scrolled = true
  }
}
```

```javascript
// app/javascript/controllers/disclosure_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "details" ]
  static values = { state: Object }

  detailsTargetConnected(target) {
    const { id } = target

    if (id in this.stateValue) target.open = this.stateValue[id]
  }

  detailsTargetDisconnected({ id, open }) {
    if (id) this.stateValue = { ...this.stateValue, [id]: open }
  }

  invalidate({ detail: { url } }) {
    const { pathname } = new URL(url)

    if (window.location.pathname != pathname) this.stateValue = {}
  }
}
```

```javascript
// app/javascript/controllers/permanence_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  cache() {
    this.element.setAttribute("data-turbo-permanent", "")
  }

  invalidate() {
    this.element.removeAttribute("data-turbo-permanent")
  }
}
```

```javascript
// app/javascript/controllers/session_resume_controller.js
import { Controller } from "@hotwired/stimulus"
import { setForm, persistResumableFields, restoreResumableFields } from "https://cdn.skypack.dev/@github/session-resume"

export default class extends Controller {
  static targets = [ "field" ]

  setForm(event) {
    setForm(event)
  }

  cache() {
    const selector = `[data-${this.identifier}-target="field"]`

    persistResumableFields(getPageID(), { selector })
  }

  fieldTargetConnected() {
    restoreResumableFields(getPageID())
  }
}

function getPageID() {
  return window.location.pathname
}
```

```javascript
// app/javascript/controllers/index.js
// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application"

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("controllers", application)
```

```ruby
# test/application_system_test_case.rb
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
end

Capybara.configure do |config|
  config.default_normalize_ws = true
end
```

```ruby
# test/system/tasks_test.rb
require "application_system_test_case"

class TasksTest < ApplicationSystemTestCase
  test "create a Task" do
    details = "Get started!"

    visit tasks_path
    within_section("To-do (0)") { toggle_disclosure "Add task" }
    within_disclosure "Add task", expanded: true do
      fill_in "Details", with: details
      click_on "Create Task"
    end

    within_section("To-do (1)") { assert_button details }
    within_disclosure("Add task") { assert_field "Details", with: "" }
  end

  test "mark a Task as Done" do
    task = Task.create! details: "Write a test!"

    visit tasks_path
    within_section("To-do (1)") { click_on task.details }

    assert_selector :section, "To-do (0)"
    within_section("Done (1)") { assert_button task.details }
  end

  test "mark a Task as To-do" do
    task = Task.create! details: "Write a test!", done_at: 1.week.ago

    visit tasks_path
    within_section("Done (1)") { click_on task.details }

    assert_selector :section, "Done (0)"
    within_section("To-do (1)") { assert_button task.details }
  end

  test "edit a Task" do
    Task.create! details: "Get started!"

    visit tasks_path
    within_section("To-do (1)") { click_on "Edit" }
    fill_in("Details", with: "Finish up!").then { click_on "Update Task" }

    within_section("To-do (1)") { assert_button "Finish up!" }
  end

  test "preserves fields while marking a Task as done" do
    task = Task.create! details: "Write a test!", done_at: 1.week.ago
    preserved = "Not started yet!"

    visit tasks_path
    within_section("To-do (0)") { toggle_disclosure "Add task" }
    within_disclosure("Add task") { fill_in "Details", with: preserved }
    within_section("Done (1)") { click_on task.details }

    assert_selector :section, "Done (0)"
    within_section "To-do (1)" do
      assert_field "Details", with: preserved
      assert_button task.details
    end
  end

  test "preserves scroll depth while marking a Task as done" do
    *, task = Task.create! 1.upto(100).map { { details: "Task ##{_1}" } }

    visit tasks_path
    scroll_to find_button task.details

    assert_no_changes -> { scroll_top } do
      click_on task.details
    end
  end

  test "preserves fields while editing a Task" do
    *, done = Task.create! [
      { details: "Fail a test" },
      { details: "Another task", done_at: 1.week.ago },
    ]

    visit tasks_path
    within_section "To-do (1)" do
      within_row(0) { click_on "Edit" }
      fill_in "Details", with: "Execute a test"
    end
    within_section("Done (1)") { click_on done.details }
    within_section("To-do (2)") { click_on "Update Task" }
    within_section "To-do (2)" do
      within_row(0) { click_on("Edit") }
      fill_in "Details", with: "Pass a test"
    end
    within_section("To-do (2)") { click_on done.details }

    within_section("To-do (1)") { assert_field "Details", with: "Pass a test" }
  end

  test "resets fields after submitting a new Task" do
    visit tasks_path
    within_section("To-do (0)") { toggle_disclosure "Add task" }
    within_disclosure "Add task" do
      fill_in("Details", with: "A new task").then { click_on "Create Task" }
    end

    within_disclosure("Add task") { assert_field "Details", with: "" }
  end

  def within_row(index = nil, &block)
    within "li:nth-of-type(#{index.to_i + 1})", &block
  end

  def scroll_top
    evaluate_script <<~JS, page
      arguments[0].scrollTop
    JS
  end
end
```

Note on test helpers: `within_section`, `within_disclosure`, `toggle_disclosure`, and the accessible-name-aware `assert_button`/`assert_field` are not defined anywhere in this repo — they come from the `capybara_accessible_selectors` gem (`gem "capybara_accessible_selectors", github: "citizensadvice/capybara_accessible_selectors"` in the `Gemfile`), which provides Capybara matchers that navigate the DOM via ARIA landmark/disclosure semantics rather than CSS selectors. This is itself an accessibility-relevant detail: Doyle's tests assert behavior the same way a screen-reader user would locate content (by section heading, by disclosure summary text), not by CSS class/id.

No CSS beyond the Rails-generated boilerplate `app/assets/stylesheets/application.css` manifest (all visual layout is Tailwind CDN utility classes in the ERB, e.g. `class="grid grid-cols-2"` on `<body>`); no branch-specific stylesheet was added.

- **Doyle's stated tradeoffs** (all direct quotes from the branch README, `git show origin/hotwire-example-restore-page-state:README.md`):

> Assessing our approach from that vantage point, let's consider some of the drawbacks, namely the user experience challenges:
> 1. Each submission (either creating or updating a `Task`) initiates a full-page navigation, which discards the entire document
> 2. If a user scrolls down the page to act upon a `Task`, the subsequent submission scrolls their browser back to the top of the page
> 3. If a user expands the "Add task" disclosure then marks a `Task` as "done", the page load will cause the disclosure to re-collapse
> 4. If a user starts to fill out the details of a new `Task`, then marks a `Task` as "done", the unsaved `Task` is lost

On adopting Turbo Streams:

> Turbo Streams are an _immensely_ powerful and precise way to change to the current document, and enable techniques that are otherwise costly, awkward, or outright impossible. It's good to know that we have Turbo Streams in our back pocket, for situations that demand their power and precision.
>
> In spite of that power, there are trade-offs to be made.
>
> When refreshing the contents of a single element on the page, a single `<turbo-stream>` operation is an extremely cost-effective solution. When the number of elements that require change grows, so do the costs.
>
> ... Reaching for tools like Turbo Streams means we're foregoing standardized HTTP mechanisms like `Content-Type: text/html` or Redirection response.
>
> Our application is now burdened with the responsibility reproducing common HTTP request-response mechanisms (for example, changing the browser's URL, resetting `<form>` element fields, or refreshing content across the page).
>
> When we deviate from HTTP Standards, we're on our [own].

On reverting to full-page redirects + scroll caching:

> Since we're returned to "full-page" redirection, we no longer have to micro-manage the _contents_ of our document. We don't need to create and manage a dedicated `.turbo_stream.erb` template, and can rely on built-in browser behavior and compliance with HTTP Standards.
>
> While we don't have to manage the changing _contents_ of the page transition, we're responsible for maintaining _context_ across changes. Our scope changes from thinking in terms of elements to thinking in terms of URLs and documents. This means that our application is responsible for managing and invalidating cached scroll values.
>
> While we've restored the scroll depth preserving behavior enabled by Turbo Streams at the cost of regressions in the preservation of other state like the expansion of disclosures and unsaved values in form fields

On the permanence/disclosure approach:

> We're preserving our disclosure elements toggle state, but we're still losing the state of its contents, as well as our inline editing form field state
>
> Once again, we've doubled-down on exchanging the precision of Turbo Stream operations for the breadth of a full-page navigation. Unfortunately, by including disclosure toggle state in our page-wide state cache, we've also doubled-down on the cost.

On per-element `[data-turbo-permanent]` + `permanence` controller:

> By selectively controlling an element's permanence, we can choose to preserve state when it suits us, and choose the parameters for refreshing the element's state from our server.
>
> Like other strategies, we're responsible for invalidating yet another cache. Unfortunately in this case, it's element-by-element. This can be an extremely powerful technique for situations that call for it, but can quickly become tedious and difficult to maintain.

On the global `@github/session-resume` approach:

> In practice, managing the permanence of individual elements can be tedious. If the state maintenance grows to be too much of a burden, there are other complementary strategies that operate at a document-wide scope.
>
> Our application's server doesn't include any Turbo-specific code. Our controllers and routes are completely unaware of the techniques the browser is using to progressively enhance the end-user's experience. We've replaced our custom MIME type response with a Standards-based HTTP redirect.
>
> While our client still requires bespoke JavaScript to achieve our outcomes, that JavaScript is generic and flexible enough to apply universally, and isn't tailored to any one particular resource or controller action.
>
> At what cost? We forfeit the state preservation gains won from introducing Turbo Streams. We're now responsible for managing yet another cache through Turbo lifecycle events.

Final wrap-up:

> In the end, we're left with a client-side and a server-side controller layer that operates without any knowledge of the fact that the client-side [is] Turbo-powered.
>
> While the strategies demonstrated throughout this example each have their own sets of trade-offs, they each have the potential to outperform their lines-of-code-to-utility ratios.

A version-caveat quote worth flagging for the currency check below:

> **Caveat:** Current versions of Turbo (those `<= 7.1.0`) require a scrolling work-around that prevents a Visit from scrolling so that applications can manage scrolling on its behalf.

- **Accessibility notes**: This branch does not frame its work explicitly in terms of WCAG/ARIA compliance language, but its entire premise is end-user-experience preservation across navigation, and its mechanism choices have direct accessibility implications:
  - **Disclosure state** uses the native `<details>`/`<summary>` element (already an accessible disclosure widget per the [ARIA Authoring Practices disclosure pattern](https://w3c.github.io/aria-practices/#disclosure), linked directly in the README: `[disclosure]: https://w3c.github.io/aria-practices/#disclosure`). Doyle explicitly calls out that losing disclosure open/closed state after a full-page reload is a UX regression: "If a user expands the 'Add task' disclosure then marks a `Task` as 'done', the page load will cause the disclosure to re-collapse" — for a screen-reader or keyboard user who just navigated into that disclosure, an unexpected collapse means lost place/context, not just a visual annoyance.
  - **Focus is named explicitly as state to preserve**, in the same enumerated list as scroll and form values: "Navigating with a full-page HTTP redirect after a Form Submission means that any end-user browser state will be lost. That state might include: how far they've scrolled within the page; any text they've typed into a form; which elements they've collapsed or expanded; **which element has focus**." Losing focus placement on every submission is precisely the failure mode that keyboard/assistive-tech users experience most acutely (focus silently resets to `<body>`), and Doyle lists it as a first-class problem even though — notably — none of the four controllers (`scroll`, `disclosure`, `permanence`, `session-resume`) explicitly restores keyboard focus position after a Turbo Stream or Turbo Drive update. The Turbo Stream section states as a benefit that "We retain the rest of our page's state (like scroll depth, partially filled-out fields, expanded disclosures, element focus, etc.)" — i.e., under the Turbo Stream strategy, focus preservation is a side effect of only patching the DOM nodes that changed (the browser never moves focus because the focused element, if untouched, is never removed/replaced). Under the full-page-redirect strategies (scroll/disclosure/permanence/session-resume), focus is NOT explicitly restored by any of the four controllers — this is a gap relative to the Turbo Stream approach, and the README doesn't call this gap out directly, though it is implied by the general "we forfeit the state preservation gains won from introducing Turbo Streams" line.
  - **`[data-turbo-permanent]`** is used to keep the actual DOM node (not just a re-created lookalike) present across navigations, which is the most robust way to preserve focus, since the browser never loses the underlying `Element` — a permanent node's cursor position, `document.activeElement` status, and any pending IME state remain intact by construction. This is arguably the most accessibility-effective mechanism in the whole branch, and it's used both statically (`_task.html.erb`'s `<turbo-frame data-turbo-permanent>`, `index.html.erb`'s `<turbo-frame id="new_task" ... data-turbo-permanent>`) and dynamically toggled by the `permanence` controller.
  - **`id` stability** is required and used throughout for Turbo Stream targeting (`dom_id(@task, :li)`, `id="to_do_tasks"`, `id="done_tasks"`, `id="to_do_size"`, `id="done_size"`) and for `[data-turbo-permanent]` matching (Turbo matches permanent elements between old/new document by `[id]`), and for the `disclosure` controller's per-element open-state cache (`id="new_task_disclosure"` keyed in a `Stimulus Value` object).
  - **`autofocus`**: the README shows one intermediate diff snippet applying `autofocus: true` to the new-task text field (`form.text_field :details, required: true, pattern: /.*\w+.*/, autofocus: true`) in the "target callbacks" alternative section, but this attribute is NOT present in the actual final-state `_form.html.erb` on this branch tip (final state only has `data: { session_resume_target: "field" }`, no `autofocus:`) — so `autofocus` appears only in a proposed/alternate code path the README walks through, not in the shipped branch.
  - **`turbo:before-render`/`turbo:render` hooks**: used by `session-resume` (`turbo:before-render->session-resume#cache` to snapshot fields right before the outgoing document is torn down, then originally `turbo:render->session-resume#read` to restore them — the README shows this action wired in an intermediate diff, but the FINAL `application.html.erb` action list only retains `turbo:before-render->session-resume#cache`, because the branch tip replaces the `read()`-on-`turbo:render` approach with a Stimulus 3 `fieldTargetConnected()` target callback instead, which fires per-field as soon as a matching `[data-session-resume-target="field"]` element connects to the DOM — a finer-grained mechanism than a single document-wide `turbo:render` listener).
  - **`turbo:frame-render`**: used by `permanence#cache` to re-arm `[data-turbo-permanent]` once a `<turbo-frame>` finishes a navigation (so the frame becomes "sticky" again only after its content is fresh), and was also shown (in an intermediate/superseded diff) wired to `session-resume#read` to handle the New Task turbo-frame's lazy-loaded content — again superseded by the final target-callback approach.
  - **`turbo:before-visit`/`turbo:visit`**: used for cache-write (`scroll#cache`, `scroll#invalidate`, `disclosure#invalidate`) before a Drive visit begins, and `turbo:visit->scroll#preventVisitScroll` is a workaround (Turbo `<= 7.1.0`) to stop Turbo's own scroll-restoration from fighting with the custom cached-scroll restoration — `preventVisitScroll()` reaches into `Turbo.session.navigator.currentVisit` and marks it `scrolled = true` to suppress Turbo's default behavior.

- **Currency check**: All commits are dated 2021-12-10 through 2021-12-19 — **more than two years before Turbo 8 shipped (February 2024) with page morphing**. This branch predates morphing entirely, and it shows: the whole scroll/disclosure/permanence/session-resume apparatus exists because, pre-Turbo-8, a full-page Turbo Drive visit does a hard `<body>` swap that has no concept of preserving anything except elements explicitly marked `[data-turbo-permanent]`. Turbo 8's morphing (`<meta name="turbo-refresh-method" content="morph">`, paired with `<meta name="turbo-refresh-scroll" content="preserve">`) is designed to replace almost this entire branch's custom machinery for free on refresh-style navigations:
  - **Scroll preservation** (`scroll_controller.js`): morphing + `turbo-refresh-scroll: preserve` handles this natively for standard page refreshes/redirects back to the same or a "morphable" page — Doyle's manual `turbo:before-visit`→cache→`turbo:load`→restore dance, plus the `preventVisitScroll` 7.1.0-era workaround, is very likely unnecessary today for this exact "redirect back to `tasks_path`" scenario. **Would not be needed today.**
  - **Disclosure open/closed state** (`disclosure_controller.js`) and **unsaved form field values**: this is where the story is more nuanced. Turbo 8 morphing diffs the incoming DOM against the current DOM and (via `idiomorph`) tries to preserve nodes it can match by identity/`id`, including their focus and, in many cases, their current attribute state (e.g., an already-`open` `<details>` element generally survives a morph because morph mutates attributes in place rather than replacing the node) — so much of what `disclosure_controller.js` does by hand (cache `[open]` per `id`, restore it on reconnect) is now something morphing does implicitly, PROVIDED the server-rendered response still marks up the `<details>` the same way (same `id`) and Turbo is configured to morph rather than replace. **Likely no longer needed**, or needed only if the app can't/won't adopt morphing everywhere.
  - **Unsaved form field values** (`permanence_controller.js`'s per-element `[data-turbo-permanent]` toggling, and `session_resume_controller.js`'s document-wide `@github/session-resume` integration): this is the most interesting case. Morphing is good at preserving values of form fields that are untouched by the diff (an `<input>` with unchanged attributes generally keeps its live user-typed value across a morph, because morph patches in place rather than replacing nodes) — so for the "Task A's checkbox toggled while Task B's edit form has unsaved text" scenario in this README, morphing would likely preserve Task B's unsaved text automatically, without needing `[data-turbo-permanent]` or `session-resume` at all, **as long as Task B's form markup renders with a stable `id`/shape server-side.** That said, `[data-turbo-permanent]` still has a distinct purpose morphing doesn't replace: forcibly opting an element OUT of diffing altogether (useful when you explicitly do NOT want the server's version to ever overwrite live client state, e.g. a widget with client-only state), so `permanence_controller.js`'s pattern of dynamically re-enabling/disabling permanence around a submission lifecycle could still be a legitimate technique layered on top of morphing, just for a narrower purpose than it served in 2021 (back then it was the ONLY way to protect sibling elements from being nuked by a full-body swap; today morphing already protects most siblings, and permanence is reserved for elements you want protected even FROM a morph diff).
  - **`session-resume` (third-party package)**: with morphing handling in-place field preservation for the common case, reaching for an external `@github/session-resume` package (which round-trips form values through `sessionStorage`, keyed by `pathname`) is very likely overkill today — it solves a form-field-loss problem that Turbo 8 morphing addresses natively for same-page/refresh-style redirects. It could still matter for the edge case morphing doesn't cover: navigating AWAY to a different URL and back (`session-resume` is deliberately keyed by page pathname and is built to survive actual navigation away and back, e.g. via browser back button, a case where the destination DOM has genuinely gone away, not just been diffed) — morphing only helps while morphing the SAME logical page; it can't help you resume a draft you started, then navigated fully away from and later returned to. So `session-resume` still has a niche, but it is a much smaller niche than "any full-page reload" as this README frames it.
  - **`turbo:frame-render`-scoped concerns** (the lazily-loaded `new_task` `<turbo-frame>`): Turbo Frames navigations are a separate code path from Drive page visits and are NOT covered by page-morphing (morphing is a Drive-visit / page-refresh feature). So anything in this branch that specifically reacts to `<turbo-frame>` navigations (e.g. `turbo:frame-render->permanence#cache`) is still just as relevant post-Turbo-8 as it was in 2021 — Turbo 8 doesn't change Frame behavior in this respect.
  - **Overall verdict**: for the specific redirect-based scenarios this README walks through (mark-as-done, mark-as-to-do, edit — all same-page redirects back to `tasks_path`), Turbo 8 morphing would likely eliminate the need for the `scroll` and `disclosure` controllers outright, would probably make `session-resume` and much of `permanence_controller.js`'s dynamic toggling unnecessary too, and would leave a much smaller residual need for `[data-turbo-permanent]` (only for elements that must survive even a morph diff) and for anything Turbo-Frame-scoped (unaffected by morphing). This branch reads today primarily as **valuable historical documentation of the problem morphing was built to solve**, not as a currently-recommended implementation pattern — though Doyle's own newer `kanban-preserve-focus` branch (with an explicit `focus_controller.js`) suggests that even in a post-morph world, focus preservation across dynamic Turbo Stream broadcast updates (a code path morphing does NOT cover — morphing is a Drive-visit feature, and full-page Drive visits are exactly what this branch abandons in favor of Turbo Streams at various points) remains a real, unsolved-by-morphing problem.

- **Does he pair a Stimulus controller with an ERB helper / partial wrapper?** No dedicated Ruby helper method is introduced on this branch (no `app/helpers/*` additions beyond the untouched default `application_helper.rb`). Instead, the pairing pattern is: a long-lived controller (`scroll`, `disclosure`, `session-resume`) is declared once on the root `<html>` element in `application.html.erb` via `data-controller="scroll disclosure session-resume"` plus one big multi-line `data-action` attribute listing every Turbo lifecycle event it cares about, and then individual view partials opt IN to being tracked by that document-wide controller purely through plain HTML attributes — e.g. `<details id="new_task_disclosure" data-disclosure-target="details">` in `index.html.erb` opts a specific `<details>` element into the `disclosure` controller's `details` Stimulus target array, and `<input data-session-resume-target="field">` in `_form.html.erb` opts a specific field into `session-resume`'s tracked-fields target array — with no Ruby helper mediating the attribute generation; it's written by hand in each ERB template. The `permanence` controller is the one exception that IS scoped to a single element rather than `<html>`, declared directly on the `<turbo-frame>` in `_task.html.erb` alongside `[data-turbo-permanent]`, again with hand-written `data-controller`/`data-action` attributes rather than a helper.


### hotwire-example-kanban

- **Technique**: A Trello-style kanban board where Cards are reordered/moved between Stages via native HTML5 drag-and-drop (plus button-based fallbacks), persisted with a Rails PATCH, and broadcast live to other sessions via Turbo Streams.

- **Problem it solves**: Give users a drag-and-drop kanban board (reorder within a column, move across columns) that (a) works without a client-side sortable JS library, (b) persists order via a plain Rails form submission triggered programmatically after the drop, (c) keeps other open sessions in sync via ActionCable/Turbo Stream broadcasts, and (d) doesn't lose a Stage's scroll position when that Stage's whole `<section>` gets replaced by an incoming broadcast.

- **Commit dates**: 2021-10-07 (`[GENERATED]: Generate Board model`) .. 2022-05-21 (`[SKIP]: Route root to first Board`). All the substantive drag/broadcast/scroll work landed 2021-10-07 through 2021-10-10; the May 2022 commits are unrelated `.replit`/root-route housekeeping.

- **Needs JS?** Yes — Stimulus controllers are load-bearing for the drag-and-drop interaction itself (native `dragstart`/`dragover`/`dragleave`/`drop` DOM events have no server-side equivalent) and for auto-submitting the resulting form. Everything else (button-based "move up"/"move down"/"move to stage", the actual persistence, and the live broadcast) is plain Rails form submissions and Turbo Stream over ActionCable — no custom JS needed for those paths.

- **Key code**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :boards, only: :show do
    resources :cards, only: :update
  end

  # Defines the root path route ("/")
  root to: redirect("/boards")
end
```

Note: the `index` action below was added in the final commit but `resources :boards` only declares `:show` — there is no routed `boards#index`, so `root to: redirect("/boards")` points at a URL with no matching route in this branch as committed. Transcribed as-is; not fixed here.

```ruby
# app/controllers/boards_controller.rb
class BoardsController < ApplicationController
  def show
    @board = Board.find params[:id]
  end

  def index
    @boards = Board.all

    redirect_to board_url(@boards.first)
  end
end
```

```ruby
# app/controllers/cards_controller.rb
class CardsController < ApplicationController
  def update
    @board = Board.find params[:board_id]
    @card = @board.cards.find params[:id]

    @card.update! card_params
    @card.broadcast_changes_to_stages

    redirect_to board_url(@board)
  end

  private

  def card_params
    params.require(:card).permit(:row_order_position, :stage_id)
  end
end
```

```ruby
# app/models/board.rb
class Board < ApplicationRecord
  has_many :stages
  has_many :cards, through: :stages
end
```

```ruby
# app/models/stage.rb
class Stage < ApplicationRecord
  include RankedModel

  belongs_to :board

  has_many :cards
  has_many :other_stages, ->(record) { without record },
    through: :board,
    source: :stages

  ranks :column_order, with_same: :board_id
end
```

```ruby
# app/models/card.rb
class Card < ApplicationRecord
  include RankedModel

  belongs_to :stage

  has_rich_text :content

  ranks :row_order, with_same: :stage_id

  delegate :other_stages, to: :stage

  def name
    content.to_plain_text
  end

  def broadcast_changes_to_stages
    changed_stages.each { |stage| stage.broadcast_replace_later_to stage.board }
  end

  private

  def changed_stages
    stage.board.stages.find changed_stage_ids
  end

  def changed_stage_ids
    saved_change_to_stage_id.presence || [ stage_id ]
  end
end
```

Uses the [`ranked-model`](https://github.com/brendon/ranked-model/tree/v0.4.7#simple-use) gem (added in commit `92472cb`, `[SKIP]: Depend on ranked-model gem`, explicitly "To set the foundation for several tables that will require arbitrary sort ordering") for both `Card#row_order` (scoped `with_same: :stage_id`) and `Stage#column_order` (scoped `with_same: :board_id`). `Card#broadcast_changes_to_stages` figures out which Stage(s) changed (the old one and the new one, via `saved_change_to_stage_id`) and re-broadcasts each affected Stage's partial to the Board's Turbo Stream channel — this is how a drag on one client updates every other open session.

```erb
{# app/views/boards/show.html.erb #}
<%= turbo_stream_from @board %>

<main class="grid grid-cols-3 gap-1 h-screen">
  <h1 class="col-span-3 h-12">Board</h1>

  <%= render partial: "stages/stage", collection: @board.stages.rank(:column_order) %>
</main>
```

```erb
{# app/views/layouts/application.html.erb #}
<!DOCTYPE html>
<html data-controller="scroll">
  <head>
    <title>HotwireExampleTemplate</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <script src="https://cdn.tailwindcss.com"></script>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body>
    <%= yield %>
  </body>
</html>
```

No standalone CSS file was added or modified on this branch — all styling is Tailwind utility classes inline in the ERB (loaded via the Tailwind CDN `<script>` tag above, itself unmodified from `main`).

```erb
{# app/views/stages/_stage.html.erb — final state #}
<section id="<%= dom_id stage %>" class="row-end-auto flex flex-col overflow-y-scroll"
    data-controller="drag"
    data-scroll-target="container"
    data-drag-accepting-class="opacity-25"
    data-action="dragstart->drag#start scroll->scroll#track:passive">
  <h2><%= stage.name %></h2>

  <%= tag.ol class: "peer" do -%>
    <% stage.cards.rank(:row_order).each do |card| %>
      <li class="group" draggable="true" aria-dropeffect="move" data-action="dragover->drag#accept dragleave->drag#reject drop->drag#insert">
        <template data-drag-target="template">
          <input type="submit" formaction="<%= url_for [ stage.board, card ] %>" data-controller="autoclick autoremove" hidden>
        </template>

        <%= card.content %>

        <%= form_with model: [ stage.board, card ] do |form| %>
          <%= form.hidden_field :row_order_position, value: "up" %>

          <button class="group-first-of-type:hidden">
            Move <%= card.name %> up
          </button>
        <% end %>

        <%= form_with model: [ stage.board, card ] do |form| %>
          <%= form.hidden_field :row_order_position, value: "down" %>

          <button class="group-last-of-type:hidden">
            Move <%= card.name %> down
          </button>
        <% end %>

        <%= form_with model: [ stage.board, card ] do |form| %>
          <%= form.hidden_field :row_order_position, value: 0 %>

          <%= form.label :stage_id do %>
            Stages
          <% end %>
          <%= form.select :stage_id, stage.other_stages.pluck(:name, :id) %>
          <button>
            Move to Stage
          </button>
        <% end %>

        <%= form_with model: [ stage.board, card ], data: { drag_target: "drop" } do |form| %>
          <%= form.hidden_field :row_order_position, value: card.row_order_rank %>
          <%= form.hidden_field :stage_id %>
        <% end %>
      </li>
    <% end %>
  <% end %>

  <form method="post" class="hidden h-12 peer-empty:block" aria-dropeffect="move" data-drag-target="drop"
      data-action="dragover->drag#accept dragleave->drag#reject drop->drag#insert">
    <input type="hidden" name="_method" value="patch">

    Move to <%= stage.name %>

    <%= fields :card do |form| %>
      <%= form.hidden_field :row_order_position, value: 0 %>
      <%= form.hidden_field :stage_id, value: stage.id %>
    <% end %>
  </form>
</section>
```

```javascript
// app/javascript/controllers/drag_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get classes() { return [ "accepting" ] }
  static get targets() { return [ "drop", "template" ] }

  start({ dataTransfer, target }) {
    const template = this.templateTargets.find(template => target.contains(template))
    const image = target.cloneNode(true)

    dataTransfer.setData("text/html", template?.innerHTML)
  }

  accept(event) {
    const { currentTarget, dataTransfer } = event

    event.preventDefault()

    dataTransfer.dropEffect = currentTarget.getAttribute("aria-dropeffect")
    currentTarget.classList.add(...this.acceptingClasses)
  }

  reject({ currentTarget }) {
    currentTarget.classList.remove(...this.acceptingClasses)
  }

  insert(event) {
    const { currentTarget, dataTransfer } = event

    event.preventDefault()

    const dropTarget = this.dropTargets.find(dropTarget => currentTarget.contains(dropTarget))

    dropTarget?.insertAdjacentHTML("beforeend", dataTransfer.getData("text/html"))
  }
}
```

```javascript
// app/javascript/controllers/autoclick_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.click()
  }
}
```

```javascript
// app/javascript/controllers/autoremove_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.remove()
  }
}
```

```javascript
// app/javascript/controllers/scroll_controller.js
import { Controller } from "@hotwired/stimulus"

const idsToScrollTops = {}

export default class extends Controller {
  static get targets() { return [ "container" ] }

  containerTargetConnected(target) {
    const scrollTop = idsToScrollTops[target.id]

    if (scrollTop) target.scroll(0, scrollTop)
  }

  track({ target }) {
    if (target.id) idsToScrollTops[target.id] = target.scrollTop
  }
}
```

```ruby
# test/system/boards_test.rb — final state, all 9 tests
require "application_system_test_case"

class BoardsTest < ApplicationSystemTestCase
  test "renders each Stage as a Section" do
    board = boards :tasks
    todo, doing, done = stages :todo, :doing, :done
    edit, write, setup = cards :edit, :write, :setup

    visit board_path(board)

    within_section(todo.name) { assert_text edit.name }
    within_section(doing.name) { assert_text write.name }
    within_section(done.name) { assert_text setup.name }
  end

  test "move a Card down a Stage" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)
    within_section todo.name do
      click_on "Move #{middle.name} down"

      assert_css "li:nth-of-type(1)", text: first.name
      assert_css "li:nth-of-type(2)", text: last.name
      assert_css "li:nth-of-type(3)", text: middle.name
    end
  end

  test "move a Card up a Stage" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)
    within_section todo.name do
      click_on "Move #{middle.name} up"

      assert_css "li:nth-of-type(1)", text: middle.name
      assert_css "li:nth-of-type(2)", text: first.name
      assert_css "li:nth-of-type(3)", text: last.name
    end
  end

  test "omits redundant buttons for the first and last Cards in a Stage" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)

    within_section todo.name do
      assert_no_button "Move #{first.name} up"
      assert_button "Move #{middle.name} up"
      assert_button "Move #{middle.name} down"
      assert_no_button "Move #{last.name} down"
    end
  end

  test "move a Card to another Stage" do
    todo, doing = stages :todo, :doing
    edit, top_of_doing = cards :edit, :write

    visit board_path(todo.board)
    within_section todo.name do
      within "li", text: edit.name do
        select doing.name, from: "Stages"
        click_on "Move to Stage"
      end

      assert_no_text edit.name
    end
    within_section doing.name do
      assert_css "li:nth-of-type(1)", text: edit.name
      assert_css "li:nth-of-type(2)", text: top_of_doing.name
    end
  end

  test "drag a Card to sort within a Stage" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)
    within_section todo.name do
      drag_card last.name, onto: first.name

      assert_css "li:nth-of-type(1)", text: last.name
      assert_css "li:nth-of-type(2)", text: first.name
      assert_css "li:nth-of-type(3)", text: middle.name
    end
  end

  test "drag a Card to another Stage" do
    todo, doing = stages :todo, :doing
    edit, top_of_doing = cards :edit, :write

    visit board_path(todo.board)
    drag_card edit.name, onto: top_of_doing.name

    within_section(todo.name) { assert_no_text edit.name }
    within_section doing.name do
      assert_css "li:nth-of-type(1)", text: top_of_doing.name
      assert_css "li:nth-of-type(2)", text: edit.name
    end
  end

  test "drag a Card to an empty Stage" do
    todo, doing = stages :todo, :doing
    edit, write = cards :edit, :write
    doing.cards.without(write).destroy_all

    visit board_path(todo.board)
    drag_card write.name, onto: edit.name
    drag_card write.name, onto: "Move to #{doing.name}"

    within_section(todo.name) { assert_no_text write.name }
    within_section(doing.name) { assert_css "li:only-of-type", text: write.name }
  end

  test "receives changes within a Stage broadcast from other sessions" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)
    within_window open_new_window do
      visit board_path(todo.board)
      within_section(todo.name) { click_on "Move #{middle.name} up" }
    end

    within_section todo.name do
      assert_css "li:nth-of-type(1)", text: middle.name
      assert_css "li:nth-of-type(2)", text: first.name
      assert_css "li:nth-of-type(3)", text: last.name
    end
  end

  test "receives changes across a Stage broadcast from other sessions" do
    todo, doing = stages :todo, :doing
    edit, top_of_doing = cards :edit, :write

    visit board_path(todo.board)
    within_window open_new_window do
      visit board_path(todo.board)
      drag_card edit.name, onto: top_of_doing.name
    end

    within_section(todo.name) { assert_no_text edit.name }
    within_section doing.name do
      assert_css "li:nth-of-type(1)", text: top_of_doing.name
      assert_css "li:nth-of-type(2)", text: edit.name
    end
  end

  def drag_card(name, onto:)
    drag_target = find %([draggable="true"]), text: name
    drop_target = find %([aria-dropeffect="move"]), text: onto

    drag_target.drag_to drop_target
  end
end
```

(`within_section` is a shared helper predating this branch — not redefined here, so it isn't reproduced as this branch's own code.)

- **Doyle's stated tradeoffs** — no branch README exists, so these are pulled entirely from commit messages/bodies:

  > "To set the foundation for several tables that will require arbitrary sort ordering, depend on the [ranked-model][] gem." (commit `92472cb`)

  > "Using CSS and the `:first-of-type` and `:last-of-type` pseudo selectors, hide the buttons to move the top Card 'up' and the bottom Card 'down'." (commit `13f4681`) — a deliberate choice to solve a UI-affordance problem with pure CSS rather than server-side conditionals or JS.

  > "When visiting the application root route (i.e. `/`), redirect to the `boards#index` action then, within the `boards#index` action, redirect to the first `Board` record." (commit `0bf4821`) — note this describes a two-hop redirect chain that, as committed, is unreachable because `resources :boards, only: :show` never routes `index` (see Key code note above).

  The "Scroll preservation" commit (`9a56fc3`) message is mostly a `git diff HEAD~10` recap/squash-summary rather than a design rationale — no additional prose tradeoff there beyond the diff itself.

- **Accessibility notes**: Every drop target and draggable `<li>` carries `aria-dropeffect="move"` (`_stage.html.erb`), which is how the `drag_controller`'s `accept`/`insert` handlers locate valid drop targets via `find %([aria-dropeffect="move"])` in the system tests — it's dual-purposed as both an accessibility attribute and a JS/test hook. Beyond that, there is no `data-turbo-permanent`, no `autofocus`, and no `turbo:before-render`/`turbo:render` hook usage anywhere on this branch — those all appear on later, more accessibility-focused branches (`restore-page-state`, `kanban-preserve-focus`). There is also no keyboard-operable alternative to drag-and-drop beyond the pre-existing "Move up"/"Move down"/"Move to Stage" buttons and `<select>` — those happen to double as an accessible fallback for reordering/moving cards without a mouse, but nothing in the commits suggests that was the stated motivation; they were built first (Oct 8) and drag-and-drop was layered on top a day later (Oct 9) as a progressive enhancement, with the buttons never removed.

- **Currency check**: All work here predates Turbo 8 (Feb 2024) by roughly 2.5 years (Oct 2021 commits) to over 2 years (May 2022 commits). Two distinct concerns are worth separating:
  - **Scroll preservation (`scroll_controller.js`)**: this exists specifically because `stage.broadcast_replace_later_to stage.board` does a full outerHTML replace of the `<section id="...">` for a Stage via Turbo Streams, which — pre-morph — always resets `scrollTop` on that element. If this project were upgraded to Turbo 8 and the broadcast used a morphing replace (Turbo 8 added `method: :morph` support to `turbo_stream.replace`/broadcast helpers, in addition to the Drive-level `<meta name="turbo-refresh-method" content="morph">`), morphing would diff the DOM in place rather than swap it, and `scrollTop` would very likely survive without any custom controller — this is close to the canonical use case morphing was built for. So `scroll_controller.js` is a strong candidate for outright deletion post-Turbo-8, provided the broadcast helpers are updated to request morph.
  - **Drag-and-drop (`drag_controller.js`, `autoclick_controller.js`, `autoremove_controller.js`)**: morphing is irrelevant here. These controllers implement the actual drag interaction using the native HTML5 Drag and Drop API (`dragstart`/`dragover`/`dragleave`/`drop`) — morphing only changes how the DOM is *patched after* a server response arrives, it does nothing for capturing a drag gesture or reordering the DOM client-side before that PATCH is even sent. This part of Doyle's approach is fully load-bearing today and would be unaffected by upgrading to Turbo 8.

- **Does he pair a Stimulus controller with an ERB helper / partial wrapper?** No dedicated Ruby helper method wraps the controller attributes (unlike e.g. a `content_tag`-generating helper). Instead, the pairing is done directly in `app/views/stages/_stage.html.erb`, which is itself the reusable "wrapper" unit (rendered once per Stage via `render partial: "stages/stage", collection: @board.stages.rank(:column_order)` in `boards/show.html.erb`). Notable pairing pattern: a `<template data-drag-target="template">` inside each `<li>` holds a hidden `<input type="submit" formaction="..." data-controller="autoclick autoremove" hidden>`. `drag_controller#insert` clones that template's `innerHTML` (captured as `text/html` on `dataTransfer` during `start`) into the drop target via `insertAdjacentHTML`. Once inserted into the live DOM, Stimulus auto-connects `autoclick` (which immediately calls `.click()`, submitting the form to persist the new position/stage) and `autoremove` (which immediately calls `.remove()`, deleting the now-redundant trigger element) — a "fire a real submit button then vanish" pattern for turning a client-side drag gesture into a genuine Rails form POST/PATCH without hand-rolled `fetch`/`FormData` JS.

### hotwire-example-kanban-preserve-focus

- **Technique**: A dedicated `focus` Stimulus controller that remembers which element (by `id`) had focus before a Turbo Stream DOM replacement, and refocuses the element with the same `id` after it reconnects — paired with a `scroll` controller doing the analogous thing for scroll position of overflow containers.

- **Problem it solves**: This branch builds a drag-and-drop Kanban board (Boards → Stages → Cards) where card moves are persisted via a form `PATCH` and then broadcast to all viewers as a Turbo Stream `replace` of the whole `<section id="stage_...">`. Because Turbo Streams replace the entire `<section>` subtree wholesale (this predates Turbo 8 morphing), every button/select inside gets destroyed and recreated — including the one the keyboard user just activated. Without intervention, focus silently falls back to `<body>` after every move, up-arrow, down-arrow, or cross-Stage transfer, forcing a keyboard user to re-locate their place in the list from scratch after every single action. Same problem for scroll position in a `overflow-y-scroll` Stage column: replacing the section resets `scrollTop` to 0, so a user scrolled deep into a long column gets kicked back to the top after every card move.

- **Commit dates**: 2021-10-07 → 2021-10-10 (repo-wide first commit on the branch's shared lineage) — the two commits that are the actual subject of this section, **Focus preservation** and **Scroll preservation**, both landed 2021-10-10 (afternoon and evening respectively). Note: this branch and `hotwire-example-kanban` share a common ancestor but have since diverged via independent rebases (per this repo's stated practice of periodically rewriting branch histories) — `hotwire-example-kanban`'s tip is dated 2022-05-21 and is *not* a strict superset of this branch, so diffs were taken from the shared merge-base (`937b6c7`) rather than branch-to-branch.

- **Needs JS?** Yes — this is 100% Stimulus/vanilla JS. Two small controllers (`focus_controller.js`, `scroll_controller.js`) totaling ~70 lines, plus a tiny global `turbo:submit-start`/`turbo:submit-end` listener in `application.js` that disables the submit button mid-request (prevents double-submits while a card move is in flight, which matters because the whole interaction model is native `<form>` submits, not fetch/XHR).

- **Key code**

```js
// app/javascript/controllers/focus_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() { return [ "item" ] }

  initialize() {
    this.lastActiveElement = null
    this.lastClickedElement = null
  }

  itemTargetConnected(target) {
    const { id, href } = this.lastActiveElement || {}

    if (hasMatchingId(id, target) && canFocus(target)) {
      if (href == window.location.href) {
        target.focus()
      } else {
        this.lastActiveElement = null
        this.lastClickedElement = null
      }
    }
  }

  itemTargetDisconnected(target) {
    if (target == document.activeElement) {
      this.lastActiveElement = { id: target.id, href: window.location.href }
    } else if (document.body == document.activeElement && hasMatchingId(target.id, this.lastClickedElement)) {
      this.lastActiveElement = this.lastClickedElement
      this.lastClickedElement = null
    }
  }

  push({ target }) {
    if (document.activeElement == document.body) return

    const item = this.itemTargets.find(item => item.contains(target))

    this.lastClickedElement = item ?
      { id: item.id, href: window.location.href } :
      null
  }
}

function hasMatchingId(id, element) {
  return id && id == element?.id
}

function canFocus(element) {
  if (element.hidden || getComputedStyle(element) == "none") {
    return false
  } else {
    return true
  }
}
```

```js
// app/javascript/controllers/scroll_controller.js
import { Controller } from "@hotwired/stimulus"

const idsToScrollTops = {}

export default class extends Controller {
  static get targets() { return [ "container" ] }

  containerTargetConnected(target) {
    const scrollTop = idsToScrollTops[target.id]

    if (scrollTop) target.scroll(0, scrollTop)
  }

  track({ target }) {
    if (target.id) idsToScrollTops[target.id] = target.scrollTop
  }
}
```

```js
// app/javascript/controllers/drag_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get classes() { return [ "accepting" ] }
  static get targets() { return [ "drop", "template" ] }

  start({ dataTransfer, target }) {
    const template = this.templateTargets.find(template => target.contains(template))
    const image = target.cloneNode(true)

    dataTransfer.setData("text/html", template?.innerHTML)
  }

  accept(event) {
    const { currentTarget, dataTransfer } = event

    event.preventDefault()

    dataTransfer.dropEffect = currentTarget.getAttribute("aria-dropeffect")
    currentTarget.classList.add(...this.acceptingClasses)
  }

  reject({ currentTarget }) {
    currentTarget.classList.remove(...this.acceptingClasses)
  }

  insert(event) {
    const { currentTarget, dataTransfer } = event

    event.preventDefault()

    const dropTarget = this.dropTargets.find(dropTarget => currentTarget.contains(dropTarget))

    dropTarget?.insertAdjacentHTML("beforeend", dataTransfer.getData("text/html"))
  }
}
```

```js
// app/javascript/controllers/autoclick_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.click()
  }
}
```

```js
// app/javascript/controllers/autoremove_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.remove()
  }
}
```

```js
// app/javascript/application.js
// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "tailwind.config"
import "@hotwired/turbo-rails"
import "controllers"
import "trix"
import "@rails/actiontext"

addEventListener("turbo:submit-start", (submitStart) => {
  const { formElement, submitter } = submitStart.detail.formSubmission

  if (submitter) submitter.disabled = true

  formElement.addEventListener("turbo:submit-end", (submitEnd) => {
    const { formElement, submitter } = submitEnd.detail.formSubmission

    if (submitter) submitter.disabled = false
  }, { once: true })
})
```

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html data-controller="scroll focus">
  <head>
    <title>HotwireExampleTemplate</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <script src="https://cdn.tailwindcss.com"></script>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body data-action="click->focus#push">
    <%= yield %>
  </body>
</html>
```

```erb
<%# app/views/boards/show.html.erb %>
<%= turbo_stream_from @board %>

<main class="grid grid-cols-3 gap-1 h-screen">
  <h1 class="col-span-3 h-12">Board</h1>

  <%= render partial: "stages/stage", collection: @board.stages.rank(:column_order) %>
</main>
```

```erb
<%# app/views/stages/_stage.html.erb %>
<section id="<%= dom_id stage %>" class="row-end-auto flex flex-col overflow-y-scroll"
    data-controller="drag"
    data-scroll-target="container"
    data-drag-accepting-class="opacity-25"
    data-action="dragstart->drag#start scroll->scroll#track:passive">
  <h2><%= stage.name %></h2>

  <%= tag.ol class: "peer" do -%>
    <% stage.cards.rank(:row_order).each do |card| %>
      <li class="group" draggable="true" aria-dropeffect="move" data-action="dragover->drag#accept dragleave->drag#reject drop->drag#insert">
        <template data-drag-target="template">
          <input type="submit" formaction="<%= url_for [ stage.board, card ] %>" data-controller="autoclick autoremove" hidden>
        </template>

        <%= card.content %>

        <%= form_with model: [ stage.board, card ] do |form| %>
          <%= form.hidden_field :row_order_position, value: "up" %>

          <button id="<%= dom_id card, :up %>" class="group-first-of-type:hidden" data-focus-target="item">
            Move <%= card.name %> up
          </button>
        <% end %>

        <%= form_with model: [ stage.board, card ] do |form| %>
          <%= form.hidden_field :row_order_position, value: "down" %>

          <button id="<%= dom_id card, :down %>" class="group-last-of-type:hidden" data-focus-target="item">
            Move <%= card.name %> down
          </button>
        <% end %>

        <%= form_with model: [ stage.board, card ] do |form| %>
          <%= form.hidden_field :row_order_position, value: 0 %>

          <%= form.label :stage_id do %>
            Stages
          <% end %>
          <%= form.select :stage_id, stage.other_stages.pluck(:name, :id), data: { focus_target: "item" } %>
          <button id="<%= dom_id card, :move %>" data-focus-target="item">
            Move to Stage
          </button>
        <% end %>

        <%= form_with model: [ stage.board, card ], data: { drag_target: "drop" } do |form| %>
          <%= form.hidden_field :row_order_position, value: card.row_order_rank %>
          <%= form.hidden_field :stage_id %>
        <% end %>
      </li>
    <% end %>
  <% end %>

  <form method="post" class="hidden h-12 peer-empty:block" aria-dropeffect="move" data-drag-target="drop"
      data-action="dragover->drag#accept dragleave->drag#reject drop->drag#insert">
    <input type="hidden" name="_method" value="patch">

    Move to <%= stage.name %>

    <%= fields :card do |form| %>
      <%= form.hidden_field :row_order_position, value: 0 %>
      <%= form.hidden_field :stage_id, value: stage.id %>
    <% end %>
  </form>
</section>
```

```ruby
# app/controllers/boards_controller.rb
class BoardsController < ApplicationController
  def show
    @board = Board.find params[:id]
  end
end
```

```ruby
# app/controllers/cards_controller.rb
class CardsController < ApplicationController
  def update
    @board = Board.find params[:board_id]
    @card = @board.cards.find params[:id]

    @card.update! card_params
    @card.broadcast_changes_to_stages

    redirect_to board_url(@board)
  end

  private

  def card_params
    params.require(:card).permit(:row_order_position, :stage_id)
  end
end
```

```ruby
# app/models/board.rb
class Board < ApplicationRecord
  has_many :stages
  has_many :cards, through: :stages
end
```

```ruby
# app/models/card.rb
class Card < ApplicationRecord
  include RankedModel

  belongs_to :stage

  has_rich_text :content

  ranks :row_order, with_same: :stage_id

  delegate :other_stages, to: :stage

  def name
    content.to_plain_text
  end

  def broadcast_changes_to_stages
    changed_stages.each { |stage| stage.broadcast_replace_later_to stage.board }
  end

  private

  def changed_stages
    stage.board.stages.find changed_stage_ids
  end

  def changed_stage_ids
    saved_change_to_stage_id.presence || [ stage_id ]
  end
end
```

```ruby
# app/models/stage.rb
class Stage < ApplicationRecord
  include RankedModel

  belongs_to :board

  has_many :cards
  has_many :other_stages, ->(record) { without record },
    through: :board,
    source: :stages

  ranks :column_order, with_same: :board_id
end
```

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  resources :boards, only: :show do
    resources :cards, only: :update
  end
end
```

```ruby
# test/system/boards_test.rb (full file, final state)
require "application_system_test_case"

class BoardsTest < ApplicationSystemTestCase
  test "renders each Stage as a Section" do
    board = boards :tasks
    todo, doing, done = stages :todo, :doing, :done
    edit, write, setup = cards :edit, :write, :setup

    visit board_path(board)

    within_section(todo.name) { assert_text edit.name }
    within_section(doing.name) { assert_text write.name }
    within_section(done.name) { assert_text setup.name }
  end

  test "move a Card down a Stage" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)
    within_section todo.name do
      click_on "Move #{middle.name} down"

      assert_css "li:nth-of-type(1)", text: first.name
      assert_css "li:nth-of-type(2)", text: last.name
      assert_css "li:nth-of-type(3)", text: middle.name
    end
  end

  test "move a Card up a Stage" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)
    within_section todo.name do
      click_on "Move #{middle.name} up"

      assert_css "li:nth-of-type(1)", text: middle.name
      assert_css "li:nth-of-type(2)", text: first.name
      assert_css "li:nth-of-type(3)", text: last.name
    end
  end

  test "omits redundant buttons for the first and last Cards in a Stage" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)

    within_section todo.name do
      assert_no_button "Move #{first.name} up"
      assert_button "Move #{middle.name} up"
      assert_button "Move #{middle.name} down"
      assert_no_button "Move #{last.name} down"
    end
  end

  test "move a Card to another Stage" do
    todo, doing = stages :todo, :doing
    edit, top_of_doing = cards :edit, :write

    visit board_path(todo.board)
    within_section todo.name do
      within "li", text: edit.name do
        select doing.name, from: "Stages"
        click_on "Move to Stage"
      end

      assert_no_text edit.name
    end
    within_section doing.name do
      assert_css "li:nth-of-type(1)", text: edit.name
      assert_css "li:nth-of-type(2)", text: top_of_doing.name
    end
  end

  test "drag a Card to sort within a Stage" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)
    within_section todo.name do
      drag_card last.name, onto: first.name

      assert_css "li:nth-of-type(1)", text: last.name
      assert_css "li:nth-of-type(2)", text: first.name
      assert_css "li:nth-of-type(3)", text: middle.name
    end
  end

  test "drag a Card to another Stage" do
    todo, doing = stages :todo, :doing
    edit, top_of_doing = cards :edit, :write

    visit board_path(todo.board)
    drag_card edit.name, onto: top_of_doing.name

    within_section(todo.name) { assert_no_text edit.name }
    within_section doing.name do
      assert_css "li:nth-of-type(1)", text: top_of_doing.name
      assert_css "li:nth-of-type(2)", text: edit.name
    end
  end

  test "drag a Card to an empty Stage" do
    todo, doing = stages :todo, :doing
    edit, write = cards :edit, :write
    doing.cards.without(write).destroy_all

    visit board_path(todo.board)
    drag_card write.name, onto: edit.name
    drag_card write.name, onto: "Move to #{doing.name}"

    within_section(todo.name) { assert_no_text write.name }
    within_section(doing.name) { assert_css "li:only-of-type", text: write.name }
  end

  test "receives changes within a Stage broadcast from other sessions" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)
    within_window open_new_window do
      visit board_path(todo.board)
      within_section(todo.name) { click_on "Move #{middle.name} up" }
    end

    within_section todo.name do
      assert_css "li:nth-of-type(1)", text: middle.name
      assert_css "li:nth-of-type(2)", text: first.name
      assert_css "li:nth-of-type(3)", text: last.name
    end
  end

  test "receives changes across a Stage broadcast from other sessions" do
    todo, doing = stages :todo, :doing
    edit, top_of_doing = cards :edit, :write

    visit board_path(todo.board)
    within_window open_new_window do
      visit board_path(todo.board)
      drag_card edit.name, onto: top_of_doing.name
    end

    within_section(todo.name) { assert_no_text edit.name }
    within_section doing.name do
      assert_css "li:nth-of-type(1)", text: top_of_doing.name
      assert_css "li:nth-of-type(2)", text: edit.name
    end
  end

  test "preserves button focus when moving a Card down within a Stage" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)
    within_section todo.name do
      move_focus_to "Move #{first.name} down"
      send_keys :enter

      assert_button "Move #{first.name} down", focused: true
      send_keys :enter

      assert_css "li:nth-of-type(1)", text: middle.name
      assert_css "li:nth-of-type(2)", text: last.name
      assert_css "li:nth-of-type(3)", text: first.name
    end
  end

  test "releases button focus when the button is hidden" do
    todo = stages :todo
    middle = cards :pull_request

    visit board_path(todo.board)
    within_section todo.name do
      move_focus_to "Move #{middle.name} down"
      send_keys :enter

      assert_css "li:nth-of-type(3)", text: middle.name
      assert_no_button focused: true, visible: :all
    end
  end

  test "preserves focus when receiving changes from another session" do
    todo = stages :todo
    first, middle = cards :edit, :pull_request

    visit board_path(todo.board)
    move_focus_to "Move #{first.name} down"
    within_window open_new_window do
      visit board_path(todo.board)
      within_section(todo.name) { click_on "Move #{middle.name} up" }
    end

    within_section todo.name do
      assert_button "Move #{first.name} down", focused: true
      assert_css "li:nth-of-type(1)", text: middle.name
      assert_css "li:nth-of-type(2)", text: first.name
    end
  end

  def move_focus_to(selector = :link_or_button, locator, **options)
    send_keys :tab until page.has_selector?(selector, locator, focused: true, **options)
  end

  def drag_card(name, onto:)
    drag_target = find %([draggable="true"]), text: name
    drop_target = find %([aria-dropeffect="move"]), text: onto

    drag_target.drag_to drop_target
  end
end
```

```ruby
# test/application_system_test_case.rb
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
end

Capybara.configure do |config|
  config.default_normalize_ws = true
end
```

Note: `within_section`, `assert_button ... focused: true`, `assert_no_button focused: true`, and `:link_or_button` are not defined anywhere in this repo's test helpers — they come from the `capybara_accessible_selectors` gem (`gem "capybara_accessible_selectors", github: "citizensadvice/capybara_accessible_selectors"`, added to the `Gemfile` in this same set of commits). This is itself a notable choice: Doyle tests accessibility semantics (landmark sections, focus state) using an accessible-selectors library rather than raw CSS/XPath, so the tests assert on the same structure a screen-reader/keyboard user would perceive, not incidental markup.

- **Doyle's stated tradeoffs**

No branch-specific README exists for this branch (it inherits the generic root `README.md`), so there is no prose write-up. The only first-person explanation is embedded in the "Scroll preservation" commit message itself, which recaps the branch's history as a diff-in-a-commit-message rather than prose:

> ```sh
> git diff HEAD~10 :^test
> ```
>
> Wrapping up:

That is the entirety of his direct commentary — terse, diff-oriented, no explicit tradeoff discussion. There are no code comments in `focus_controller.js` or `scroll_controller.js` either; the implementation is left to speak for itself. No explicit tradeoffs are stated anywhere in this branch's commits — this is stated explicitly rather than inferred.

- **Accessibility notes**

Focus preservation is the entire subject of this branch's namesake commit ("Focus preservation"), and the mechanism is worth spelling out precisely since there's no prose from Doyle explaining it:

  - **The problem, inferred from the code**: every card move (`up`/`down`/`move to stage`/drag) submits a form that mutates a `Card`, and `Card#broadcast_changes_to_stages` (`app/models/card.rb`) calls `stage.broadcast_replace_later_to stage.board` on every affected `Stage`, which Turbo Streams into a `<turbo-stream action="replace" target="stage_...">` that swaps out the *entire* `<section>` for that Stage — including whichever `<button>` or `<select>` the user just used. Because it's a full element replacement (not morphing — this is 2021, three years before Turbo 8), the DOM nodes are destroyed and re-created with fresh identity, so the browser's focus silently reverts to `<body>`.
  - **The fix**: `focus_controller.js` is attached at `data-controller="focus"` on `<html>` (`app/views/layouts/application.html.erb`), i.e. document-wide, with a single delegated click listener: `data-action="click->focus#push"` on `<body>`. Every focusable control that participates (the up/down/move buttons and the stage `<select>`) gets `data-focus-target="item"` plus a **stable, semantically-derived `id`** via Rails' `dom_id` helper — `id="<%= dom_id card, :up %>"`, `id="<%= dom_id card, :down %>"`, `id="<%= dom_id card, :move %>"`. Because `dom_id card, :up` always resolves to the same string for the same `Card` record (e.g. `card_42_up`), the *replacement* button after a Turbo Stream swap has the *same id* as the one that was just destroyed, even though it's a different DOM node.
  - **The state machine**:
    1. `push({ target })` — fired on every click anywhere in `<body>`. If focus isn't currently on `<body>` (i.e. the browser already knows what's focused), it walks up from the click target to find the enclosing `item` target and records `{ id, href: window.location.href }` as `lastClickedElement`. This captures "the user's intent" before the form submit blows the DOM away.
    2. `itemTargetDisconnected(target)` — Stimulus lifecycle callback fired when an `item`-tagged element is removed from the DOM (i.e. right as the Turbo Stream replace tears out the old `<section>`). If the *disconnecting* element was `document.activeElement`, it promotes that `{id, href}` to `lastActiveElement` directly. Otherwise — the more subtle branch — if focus has already fallen back to `<body>` (which happens synchronously in some browsers right when the old node is removed, before the new one arrives) and the disconnecting element's id matches the previously-clicked element's id, it promotes `lastClickedElement` to `lastActiveElement`. This handles the race where focus is lost *before* the disconnect fires.
    3. `itemTargetConnected(target)` — fired when the *replacement* `item`-tagged element (same id, new node) connects. If its `id` matches `lastActiveElement.id`, and it `canFocus()` (not `hidden` and not `display: none`), and the stored `href` still equals the current page's URL (guards against stale focus state bleeding across a full navigation), it calls `target.focus()`, restoring focus onto the *new* node with the *old* semantic identity.
    4. `canFocus()` explicitly checks visibility — because the up/down buttons are conditionally hidden via `group-first-of-type:hidden` / `group-last-of-type:hidden` Tailwind classes (a card moved to the top of the list loses its "up" button). If the just-focused button becomes hidden as a *result* of the move, focus is deliberately **not** force-attached to an invisible/unfocusable element — this is exactly what the test `"releases button focus when the button is hidden"` asserts (`assert_no_button focused: true, visible: :all`), i.e. correct behavior is for focus to fall back to nothing rather than get trapped on a hidden control.
  - **Cross-session case**: the test `"preserves focus when receiving changes from another session"` demonstrates the mechanism also works for Turbo Stream broadcasts arriving from *another browser tab/session* (not just your own form submit) — since the disconnect/connect target callbacks fire identically regardless of what triggered the stream, focus-restoration is broadcast-agnostic by construction.
  - `data-focus-target="item"` is applied to: the "up" button, "down" button, "move to Stage" `<select>` (`app/views/stages/_stage.html.erb`, `data: { focus_target: "item" }`), and "Move to Stage" submit button — i.e. every keyboard-operable control that could plausibly hold focus when a re-render happens.
  - No `aria-*` attributes are added by this branch specifically for focus management (the `aria-dropeffect="move"` attributes are from the earlier drag-and-drop commits, not this one). No `data-turbo-permanent` is used anywhere in this branch — permanence is not the mechanism; identity-matching via `id` + Stimulus connect/disconnect lifecycle is. No `autofocus` attribute is used. No `turbo:before-render`/`turbo:render` event hooks are used — the mechanism relies entirely on Stimulus's own `<target>Connected`/`<target>Disconnected` lifecycle callbacks, which fire off MutationObserver internally, rather than hooking into Turbo's rendering pipeline directly.
  - The `push` action's guard `if (document.activeElement == document.body) return` also prevents the controller from recording "focus intent" from clicks that don't actually move focus (e.g. clicking something non-focusable), avoiding false-positive refocus targets.

- **Currency check**

  This branch's commits are dated 2021-10-10, roughly **28 months before Turbo 8** (Feb 2024) introduced page morphing. Turbo 8 morphing (`<meta name="turbo-refresh-method" content="morph">`, with `data-turbo-permanent` and idempotent-connect-based scroll/focus preservation) is specifically designed to solve *this exact class of problem* — but only for one specific code path: **full-page Turbo Drive visits/refreshes**, where Turbo re-requests the whole page and morphs the new HTML onto the existing DOM node-by-node via `idiomorph`, preserving focus/scroll/form state on elements whose position in the tree is unchanged.

  This branch's update path is **not** a Turbo Drive page visit — it's a `<turbo-stream action="replace">` pushed over an Action Cable WebSocket via `broadcast_replace_later_to`. As of Turbo 8 (through 8.x as of this writing), **Turbo Streams do not use the morphing algorithm** — a `replace` stream action still does a literal DOM node replacement (`Element.replaceWith` style), not a morph. Morphing is opt-in per-visit via the `turbo-refresh-method` meta tag and applies to Drive-initiated navigations/refreshes, not to Stream actions delivered over a channel. (There is a `refresh` stream action introduced alongside morphing that *triggers* a morphing page refresh, but that's a different, coarser primitive than the targeted `replace` this branch relies on for a live multiplayer Kanban board — switching to it would mean re-fetching and morphing the whole page on every remote change instead of patching just the affected Stage.)

  **Conclusion: Doyle's `focus_controller.js`/`scroll_controller.js` approach is still needed today** for this exact architecture (targeted Turbo Stream `replace` broadcasts). Turbo 8 morphing would only make this redundant if the app were restructured to drop granular Stream broadcasts in favor of `turbo-refresh-method: morph` full-page refreshes on every card move — a meaningfully different (coarser, more bandwidth-heavy for multi-user real-time boards) architecture. For apps that *do* rely on Drive-based full-page reloads to reflect state, morphing would indeed replace the need for hand-rolled focus/scroll preservation — but not for this branch's live-broadcast, partial-replace design.

- **Does he pair a Stimulus controller with an ERB helper / partial wrapper?**

  Not via a Ruby helper method — there's no `focus_target_tag` or similar view helper. Instead the pairing is done directly in the `_stage.html.erb` partial by hand: every participating control gets `id="<%= dom_id card, :up|:down|:move %>"` (using Rails' built-in `dom_id` view helper, not a custom one) plus a literal `data-focus-target="item"` (or `data: { focus_target: "item" }` for the `form.select`). The controller itself is activated once, globally, at the `<html data-controller="scroll focus">` root in the layout — so there's no per-partial `data-controller="focus"` scoping; only the `data-focus-target="item"` markers and stable `dom_id`-derived ids are threaded through the `_stage.html.erb` partial. The pattern is "one global controller instance + `dom_id` for stable identity across replace", not "helper method that wraps markup."
---

## Per-branch: uploads & rich text


Source: `/private/tmp/claude-501/-Users-jakemoffatt-source/900254bf-0b68-48c0-90b6-7971c90746ed/scratchpad/hotwire-example-template`

---

### hotwire-example-action-text-mentions

- **Technique**: Progressive build-up of "@"-mention autocomplete inside a Trix/Action Text editor — from server-side regex `highlight` at render-time, to a `before_save` regex-attach at write-time, to Action Text's native attachable API, to a fully accessible combobox-driven draft-time mention picker wired to `@github/combobox-nav`.
- **Problem it solves**: How to let users "@"-mention a `User` record inline in rich text (Trix) content, have it persist as a real, renderable, linkable `ActionText::Attachment` (not just a string), and have the picker behave like a real accessible combobox/autocomplete (keyboard nav, escape-to-collapse, blur-to-collapse, cursor-position-aware popup).
- **Commit dates**: 2021-04-06 (first, "Render-time mentions") .. 2021-04-25 (last substantive, "Lazily-loaded mentions" / "Draft-time mentions"); "Write-time mentions (revisited)" also 2021-04-11. Fixture/scaffold `[SKIP]` commits trail to 2021-08-29.
- **Needs JS?**: Yes, substantially, for the final ("draft-time") iteration. Early iterations (render-time regex `highlight`, write-time `before_save` gsub) are pure server-side Ruby/ERB, zero JS. Once mentions become interactive/keyboard-navigable, a single Stimulus controller (`mentions_controller.js`, ~110 lines) plus one third-party library (`@github/combobox-nav`, imported via Skypack CDN, no npm/bundler) does all the work: reading Trix editor cursor position/selection, building/tearing down a `Combobox` instance, inserting `Trix.Attachment`s, and managing ARIA state indirectly through that library.

- **Key code**:

```js
// app/javascript/controllers/mentions_controller.js (final state)
import { Controller } from "@hotwired/stimulus"
import Combobox from "https://cdn.skypack.dev/@github/combobox-nav"

export default class extends Controller {
  static get targets() { return [ "editor", "listbox", "submit" ] }
  static get values() { return { wordPattern: String, breakPattern: String } }

  disconnect() {
    this.toggle(false)
  }

  // Actions

  insert({ target: { value, innerHTML } }) {
    const { editor } = this.editorTarget
    const selectedRange = findWordBoundsFromCursor(editor, this.breakPatternValue)

    editor.setSelectedRange(selectedRange)
    editor.deleteInDirection("backward")
    editor.insertAttachment(new Trix.Attachment({ sgid: value, content: innerHTML }))
  }

  expand({ target: { editor } }) {
    const mention = findMentionFromCursor(editor, this.wordPatternValue, this.breakPatternValue)

    if (mention) {
      const { bottom, left } = editor.getClientRectAtPosition(editor.getPosition())
      this.listboxTarget.style.top = bottom + "px"
      this.listboxTarget.style.left = left + "px"

      this.toggle(true)
      this.submitTarget.value = mention
      this.submitTarget.click()
    } else {
      this.toggle(false)
    }
  }

  collapseOnEscape({ key }) {
    if (key == "Escape") this.collapse()
  }

  collapseOnCursorExit({ target: { editor } }) {
    const mention = findMentionFromCursor(editor, this.wordPatternValue, this.breakPatternValue)

    if (mention) return
    else this.toggle(false)
  }

  collapse() {
    if (this.editorTarget.hasAttribute("aria-activedescendant")) return
    else this.toggle(false)
  }

  // Private

  toggle(expanded) {
    if (expanded) {
      this.listboxTarget.hidden = false
      this.listboxTarget.setAttribute("role", "listbox")
      this.editorTarget.setAttribute("role", "combobox")
      this.editorTarget.setAttribute("autocomplete", "username")
      this.editorTarget.setAttribute("autocorrect", "off")

      this.combobox?.destroy()
      this.combobox = new Combobox(this.editorTarget, this.listboxTarget)
      this.combobox.start()
    } else {
      this.listboxTarget.hidden = true
      this.listboxTarget.removeAttribute("role")
      this.editorTarget.setAttribute("role", "textbox")
      this.editorTarget.removeAttribute("autocomplete")
      this.editorTarget.removeAttribute("autocorrect")

      this.combobox?.destroy()
    }
  }
}

function findMentionFromCursor(editor, wordPattern, breakPattern) {
  const [ start, end ] = findWordBoundsFromCursor(editor, breakPattern)
  const word = editor.getDocument().toString().slice(start, end)
  const [ mention ] = word.match(new RegExp(wordPattern)) || []

  return mention
}

function findWordBoundsFromCursor(editor, breakPattern) {
  const content = editor.getDocument().toString()
  const position = editor.getPosition()
  breakPattern = new RegExp(breakPattern)

  return findWordBoundsFromStringAtPosition(content, position, (char) => breakPattern.test(char))
}

function findWordBoundsFromStringAtPosition(string, position, characterMatchesWordBoundary) {
  let start = position
  let index = position
  while(--index >= 0) {
    const char = string.charAt(index)
    if (characterMatchesWordBoundary(char)) break
    start = index
  }

  let end = position
    index = position
  while(index < string.length) {
    const char = string.charAt(index)
    if (characterMatchesWordBoundary(char)) break
    end = ++index
  }

  if (start != end) {
    return [ start, end ]
  } else {
    return [ -1, -1 ]
  }
}
```

```erb
<%# app/views/messages/_form.html.erb (final state) %>
<%= form_with(model: message, data: { controller: "mentions", action: "trix-change->mentions#expand",
                                      mentions_word_pattern_value: /^@(.*?)$/.source, mentions_break_pattern_value: /\s/.source }) do |form| %>
  <% if message.errors.any? %>
    <div id="error_explanation">
      <h2><%= pluralize(message.errors.count, "error") %> prohibited this message from being saved:</h2>

      <ul>
        <% message.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="field">
    <%= form.label :content %>
    <%= form.rich_text_area :content, data: { mentions_target: "editor",
                                              action: "
                                                keydown->mentions#collapseOnEscape
                                                keydown->mentions#collapseOnCursorExit
                                                trix-blur->mentions#collapse
                                               " } %>

    <button form="new_mention" name="username" data-mentions-target="submit" hidden>Search</button>
  </div>

  <div class="actions">
    <%= form.submit %>
  </div>

  <fieldset class="border-0 p-0">
    <legend class="sr-only">Mentions</legend>

    <turbo-frame id="mentions" class="absolute bg-white flex flex-col p-1" hidden
                 data-mentions-target="listbox"></turbo-frame>
  </fieldset>
<% end %>

<form id="new_mention" action="<%= mentions_path %>" data-turbo-frame="mentions"></form>
```

```erb
<%# app/views/mentions/index.html.erb (final state — rendered inside the turbo-frame) %>
<turbo-frame id="mentions">
  <% @users.each do |user| %>
    <button type="button" name="sgid" value="<%= user.attachable_sgid %>" id="<%= dom_id user, :mention %>" role="option"
            data-action="click->mentions#insert">
      <%= render partial: user.to_trix_content_attachment_partial_path, locals: { user: user } %>
    </button>
  <% end %>
</turbo-frame>
```

```erb
<%# app/views/mentions/_mention.html.erb — the Trix content-attachment partial (re-used both inside
     the picker buttons AND as the attachable's rendered HTML) %>
<%= user.name %>
```

```erb
<%# app/views/users/_attachable.html.erb — how User renders once attached to Action Text content %>
<%= link_to user_path(user) do %>
  <%= render partial: user.to_trix_content_attachment_partial_path, locals: { user: user } %>
<% end %>
```

```ruby
# app/models/user.rb (final state)
class User < ApplicationRecord
  include ActionText::Attachable

  scope :username_matching_handle, ->(handle) { where <<~SQL, handle.delete_prefix("@") + "%" }
    username LIKE ?
  SQL

  def to_trix_content_attachment_partial_path
    "mentions/mention"
  end

  def to_attachable_partial_path
    "users/attachable"
  end
end
```

```ruby
# app/models/message.rb (final state)
class Message < ApplicationRecord
  has_rich_text :content

  def mentioned_users
    content.body.attachables.select { |attachable| attachable.is_a? User }
  end
end
```

```ruby
# app/controllers/mentions_controller.rb (final state)
class MentionsController < ApplicationController
  def index
    @users = User.order(username: :asc).username_matching_handle params[:username]
  end
end
```

```ruby
# app/controllers/messages_controller.rb — relevant excerpt (final state)
def create
  @message = Message.new(message_params)

  respond_to do |format|
    if @message.save
      format.html { redirect_to @message, notice: "Message was successfully created. Mentioned #{@message.mentioned_users.pluck(:name).to_sentence}" }
      format.json { render :show, status: :created, location: @message }
    else
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: @message.errors, status: :unprocessable_entity }
    end
  end
end
```

```ruby
# app/controllers/users_controller.rb — relevant excerpt (final state)
private
  def set_user
    users_with_id = User.where id: params[:id]
    users_with_username_matching_handle = User.username_matching_handle params[:id]

    @user = users_with_id.or(users_with_username_matching_handle).first!
  end
```

```ruby
# app/helpers/messages_helper.rb (final state — VERBATIM, entire file)
module MessagesHelper
end
```

```ruby
# app/helpers/users_helper.rb (final state — VERBATIM, entire file)
module UsersHelper
end
```

```diff
--- a/app/assets/stylesheets/application.css
+++ b/app/assets/stylesheets/application.css
  *= require_tree .
  *= require_self
  */
+
+[aria-selected="true"]  { outline: 2px dotted black; }
```

```ruby
# config/routes.rb (final state)
Rails.application.routes.draw do
  resources :mentions, only: :index
  resources :messages
  resources :users

  root to: redirect("/messages/new")
end
```

```ruby
# test/system/messages_test.rb — mention-specific tests (final state)
test "transforms a mention as a link to the User" do
  alice = users(:alice)

  visit new_message_path
  find(:rich_text_area, "Content").click
  send_keys("Hello, @a").then { click_button alice.name }
  click_on("Create Message").then { assert_text "Message was successfully created." }

  assert_text "Mentioned #{alice.name}"

  click_link alice.name

  assert_text alice.username
  assert_text alice.name
end

test "provides choices for a mention" do
  erin, eve = users(:erin, :eve)

  visit new_message_path
  find(:rich_text_area, "Content").click
  send_keys "Hello, @e"
  2.times { send_keys :arrow_down }.then { send_keys :enter }
  click_on "Create Message"

  assert_text "Message was successfully created."
  assert_text "Hello, #{eve.name}"
  assert_no_text erin.name
end

test "can collapse the mention choices with escape" do
  visit new_message_path
  find(:rich_text_area, "Content").click.then { send_keys("Hello, @") }

  within_fieldset("Mentions") { assert_button }
  send_keys(:arrow_down).then { assert_list_box_option selected: true }
  send_keys(:escape).then     { assert_no_list_box_option selected: true }
  within_fieldset("Mentions") { assert_button }
  send_keys(:escape).then     { within_fieldset("Mentions") { assert_no_button } }
end

test "can collapse the mention choices by moving focus" do
  visit new_message_path
  find(:rich_text_area, "Content").click.then { send_keys("Hello, @") }

  within_fieldset("Mentions") { assert_button }
  send_keys(:tab).then        { assert_no_list_box_option selected: true }
  within_fieldset("Mentions") { assert_no_button }
end

test "renders the mentioned User's name while editing a Message" do
  alice_to_bob = messages(:alice_to_bob)
  bob = users(:bob)

  visit edit_message_path(alice_to_bob)

  within :rich_text_area, "Content" do
    assert_text alice_to_bob.content.to_plain_text
    assert_text bob.name
    assert_no_text bob.username
  end
end

test "renders a mention as a link to that User" do
  alice_to_bob = messages(:alice_to_bob)
  bob = users(:bob)

  visit message_path(alice_to_bob)
  click_link(bob.name).then { assert_text bob.name }

  assert_text bob.username
end

test "does not render a mention as a link when the User doesn't exist" do
  visit new_message_path
  fill_in_rich_text_area("Content", with: "Hello @xavier")
  click_on("Create Message").then { assert_text "Message was successfully created." }

  assert_no_link href: user_path("@xavier")
end

def assert_list_box_option(locator, selected: nil, **options)
  assert_selector :list_box_option, locator, **options do |element|
    selected.nil? || element["aria-selected"] == selected.to_s
  end
end

def assert_no_list_box_option(locator, selected: nil, **options)
  assert_no_selector :list_box_option, locator, **options do |element|
    selected.nil? || element["aria-selected"] == selected.to_s
  end
end
```

- **Doyle's stated tradeoffs**:

> "Since the mentions are entirely String-based, they won't include any information related to a `User` record's identifier. We'll need to add support for resolving records based on the `params[:id]` path parameter."

> "So far, our implementation handles '@'-mentioning `User` records based on their `username` values. However, by deferring our transformations until render-time, we miss out on any database-level constraints or guarantees that could prevent linking an '@'-mention to a `User` that doesn't exist. We can do better. Let's move `User`-mentions one phase earlier in the messaging process: at write-time."

> "Attaching `User` records to a message draft requires direct access to an Action Text-powered `<trix-editor>` element. Our current combination of Rails and Turbo doesn't afford our client-side with the tools to achieve that level of control, so let's add Stimulus to the mix!"

> "While the `sgid` value is _always_ significant, the `content` is only used for attachment-time rendering, and will be replaced with whatever HTML the server resolves the resulting `<action-text-attachment>` element to on subsequent viewings."

> "As the `users` table grows, the cost of retrieving and rendering _every_ `User` record as a `<button>` that creates a mention will grow with it. We can defer that cost until _after_ the initial request by delaying the retrieval of those records." (motivation for the Turbo Frame lazy-load step)

> "For simplicity's sake, we'll change our `User.mentioned` scope to rely on SQL's LIKE-powered pattern matching. Once implemented, the experience could be improved by more powerful search tools (e.g. PostgreSQL's full-text searching capabilities)." — explicit acknowledgment `LIKE` is a placeholder, not production-grade search.

> "Now that we're relying on Action Text and Trix to manage attachments on our behalf, it's no longer necessary to extract attachments during the creation of the `Message` records themselves, so let's remove the `before_save` block." — i.e., the write-time `before_save` gsub approach is explicitly superseded/deleted once the draft-time picker exists; it is presented as a stepping stone, not a technique to keep alongside the final version.

- **Accessibility notes** (crown jewel — verbatim):
  - Editor toggles role between inactive/active states:
    ```
    this.editorTarget.setAttribute("role", "combobox")   // when expanded
    this.editorTarget.setAttribute("role", "textbox")    // when collapsed
    ```
  - Listbox role is added/removed alongside `hidden`:
    ```
    this.listboxTarget.hidden = false
    this.listboxTarget.setAttribute("role", "listbox")
    ...
    this.listboxTarget.hidden = true
    this.listboxTarget.removeAttribute("role")
    ```
  - Editor also gets `autocomplete="username"` / `autocorrect="off"` toggled on/off in lockstep with the combobox role (mirrors the earlier static `<input type="search" autocomplete="username" autocorrect="off">` used in the pre-Stimulus filtered-search step).
  - Each option button in the listbox: `id="<%= dom_id user, :mention %>" role="option"` — unique IDs are required for `aria-activedescendant` to reference them.
  - **`aria-expanded`, `aria-controls`, `aria-autocomplete`, `aria-activedescendant` are never set directly by Doyle's own code.** They are delegated entirely to the imported `@github/combobox-nav` library (`import Combobox from "https://cdn.skypack.dev/@github/combobox-nav"`), instantiated as `new Combobox(this.editorTarget, this.listboxTarget)` and torn down via `.destroy()`. The app code only *reads* `aria-activedescendant` (via `hasAttribute`) to decide whether to suppress a blur-triggered collapse:
    ```js
    collapse() {
      if (this.editorTarget.hasAttribute("aria-activedescendant")) return
      else this.toggle(false)
    }
    ```
    This is a deliberate "don't hand-roll ARIA state machines" choice — pairing role/hidden management (owned by the Stimulus controller) with keyboard/ARIA-state management (owned by a dedicated, tested combobox library) is the actual pattern, not a from-scratch ARIA combobox implementation.
  - Keyboard interactions verbatim from code/tests: <kbd>@</kbd>-typing triggers `trix-change->mentions#expand`; `keydown->mentions#collapseOnEscape` collapses on <kbd>Escape</kbd>; `keydown->mentions#collapseOnCursorExit` collapses when the cursor moves outside the "word" being matched; `trix-blur->mentions#collapse` collapses on blur/`Tab`-away unless `aria-activedescendant` is present (i.e., an option is actively highlighted via arrow keys, so the library is mid-interaction); Down-arrow moves `aria-selected` through options (verified in tests via `send_keys :arrow_down` + `assert_list_box_option selected: true`); <kbd>Enter</kbd> selects the highlighted option.
  - CSS-level a11y affordance: `[aria-selected="true"] { outline: 2px dotted black; }` — a visible focus/selection indicator keyed directly off the ARIA state the combobox library manages.
  - `README.md` cites the W3C ARIA Authoring Practices directly (not just linked, referenced by section): role="combobox" (WAI-ARIA 1.1 §combobox), role="listbox" (§listbox), "Combobox interactions", "Combobox attributes" ("WAI-ARIA Roles, States, and Properties"), and "Combobox keyboard interactions" — all from `wai-aria-practices-1.1`.
  - Server-rendered popup uses `<fieldset><legend class="sr-only">Mentions</legend>...` — the legend is visually hidden but remains in the accessibility tree, and the fieldset itself is asserted against in tests (`within_fieldset("Mentions")`).

- **Currency check**: Committed 2021-04/2021-08, well before Turbo 8 (Feb 2024). Uses Stimulus 2-era `static get targets()` / `static get values()` getter syntax throughout (not the Stimulus 3 `static targets = [...]` class-field syntax) — this is a **deprecated-but-still-supported** syntax pattern worth flagging as dated. No importmap/esbuild bundling for the third-party library — it's pulled live from `https://cdn.skypack.dev/@github/combobox-nav`, a pattern that predates modern importmap-pinned vendoring conventions. No Turbo Streams/broadcasts used in this branch at all (everything is Turbo Frame + full-page navigation), so no morphing/`Turbo::Broadcastable`/`Turbo::StreamsChannel` currency concerns apply here.

- **Stimulus controller + ERB helper pairing?** **No.** `app/helpers/messages_helper.rb` and `app/helpers/users_helper.rb` are both empty, unused scaffold-generated modules (see verbatim contents above). The "pairing" that actually happens in this branch is Stimulus controller + **ERB partial** (not helper): the `mentions` controller is paired with the `mentions/_mention.html.erb` partial (referenced twice — once for picker buttons, once as the Action Text attachable renderer, via `user.to_trix_content_attachment_partial_path` / `user.to_attachable_partial_path` model methods) and with the `mentions/index.html.erb` + `<turbo-frame>` structure. There is no case of a Ruby helper *method* generating data-attributes or markup for a Stimulus controller to consume — all wiring is done directly in ERB view templates and small `to_*_partial_path` methods on the model.

---

### hotwire-example-attachment-album

- **Technique**: Multi-file photo upload with drag-in preview, per-file removal before submit, and preservation of already-attached photos and staged-but-not-yet-submitted files across a failed (invalid) form submission — built on `has_many_attached`, `<input type="file" multiple direct_upload>`, and three small single-purpose Stimulus controllers cloning a `<template>` per selected file.
- **Problem it solves**: Rails' native `<input type="file" multiple>` re-selection UX is bad (selecting a new file resets/replaces the whole FileList, so you can't add-then-remove individual files, and a failed form submit normally loses all staged file selections because file inputs can't be repopulated from the server). Doyle clones a `<template>` per file (each with its own single-file `<input type="file">`) so files can be added/removed independently, previewed via `FileReader`, and — critically — the already-persisted attachments survive as checkboxes (`form.check_box :photos, ..., photo.signed_id, []`) so users can deselect existing photos, while newly staged (not-yet-submitted) files are marked `data-turbo-permanent` so they survive Turbo's page morph/replace on a failed submission's re-render.
- **Commit dates**: 2021-10-22 (single day; all 5 commits from "[GENERATED]: Scaffold `Album`" through "Preserve `<input type="file">` elements across submission" land the same day).
- **Needs JS?**: Yes, moderately — three small Stimulus controllers (~25, ~11, ~19 lines) rather than one large one: `clone_controller.js` (clones a `<template>` per selected file using `@github/template-parts`'s `TemplateInstance`, via Skypack CDN, no bundler), `file_reader_controller.js` (renders an image preview via `FileReader.readAsDataURL`), and `disabled_controller.js` (toggles a hidden checkbox + disables the associated file input, used to let users "uncheck" a staged-but-unsubmitted file so it isn't submitted).
- **Key code**:

```js
// app/javascript/controllers/clone_controller.js (final state)
import { Controller } from "@hotwired/stimulus"
import { TemplateInstance } from "https://cdn.skypack.dev/@github/template-parts"

export default class extends Controller {
  static get targets() { return [ "output", "template" ] }
  static get values() { return { placeholder: String, selector: String } }

  append({ target }) {
    for (const file of target.files) {
      const id = (new Date()).getTime()
      const clonedTemplate = new TemplateInstance(this.templateTarget, { [this.placeholderValue]: id })

      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(file)

      const input = clonedTemplate.querySelector(this.selectorValue)
      input.files = dataTransfer.files

      this.outputTarget.append(clonedTemplate)
    }

    target.value = null
  }
}
```

```js
// app/javascript/controllers/disabled_controller.js (final state, full file)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() { return [ "input" ] }

  toggle({ target: { checked } }) {
    for (const input of this.inputTargets) {
      input.disabled = !checked
    }
  }
}
```

```js
// app/javascript/controllers/file_reader_controller.js (final state, full file)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() { return [ "input", "label", "image" ] }

  inputTargetConnected({ files: [ file ] }) {
    const fileReader = new FileReader()

    if (file) {
      for (const label of this.labelTargets) {
        label.innerHTML = file.name
      }
      this.imageTarget.alt = file.name

      fileReader.addEventListener("load", ({ target }) => this.imageTarget.src = target.result)
      fileReader.readAsDataURL(file)
    }
  }
}
```

```erb
<%# app/views/albums/_form.html.erb (final state) %>
<%= form_with(model: album) do |form| %>
  <% if album.errors.any? %>
    <div id="error_explanation">
      <h2><%= pluralize(album.errors.count, "error") %> prohibited this album from being saved:</h2>

      <ul>
        <% album.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="field">
    <%= form.label :name %>
    <%= form.text_field :name %>
  </div>

  <fieldset data-controller="clone" data-clone-placeholder-value="id" data-clone-selector-value="input[type=file]">
    <template data-clone-target="template">
      <%= render "albums/photos/form", form: form, photo: ActiveStorage::Attachment.new, id: form.field_id(:photos, "{{ id }}") %>
    </template>

    <ul id="<%= form.field_id :photos_attachments %>" data-clone-target="output" data-turbo-permanent>
      <% form.object.photos.each do |photo| %>
        <%= render "albums/photos/form", form: form, photo: photo, id: form.field_id(:photos, photo.id) %>
      <% end %>
    </ul>

    <%= form.label :photos %>
    <%= form.file_field :photos, multiple: true, direct_upload: true,
          data: { action: "input->clone#append" } %>
    <%= form.hidden_field :photos, multiple: true, id: nil, value: nil %>
  </fieldset>

  <div class="actions">
    <%= form.submit %>
  </div>
<% end %>
```

```erb
<%# app/views/albums/photos/_form.html.erb (final state — the per-file/per-attachment template, full file) %>
<li data-controller="file-reader disabled">
  <% if photo.persisted? %>
    <%= form.check_box :photos,
      { id: id, checked: true, multiple: true },
      photo.signed_id, [] %>
  <% else %>
    <%= form.check_box :photos,
          id: id, checked: true, name: nil,
          data: { action: "input->disabled#toggle" } %>
    <%= form.file_field :photos,
          id: nil, multiple: true, direct_upload: true, hidden: true,
          data: { disabled_target: "input", file_reader_target: "input" } %>
  <% end %>

  <%= form.label :photos, photo.persisted? ? photo.filename : "", for: id, data: { file_reader_target: "label" } %>

  <%= render "active_storage/attachments/attachment", attachment: photo, data: { file_reader_target: "image" } %>
</li>
```

```erb
<%# app/views/active_storage/attachments/_attachment.html.erb — app-level override of Rails' built-in
     partial, full file %>
<%= image_tag attachment.persisted? ? attachment : "", alt: attachment.persisted? ? attachment.filename : "", height: 240, **local_assigns.without(:attachment) %>
```

```erb
<%# app/views/albums/_album.html.erb (final state, full file) %>
<div id="<%= dom_id album %>" class="scaffold_record">
  <p>
    <strong>Name:</strong>
    <%= album.name %>
  </p>

  <ul>
    <% album.photos.each do |photo| %>
      <li>
        <%= link_to photo do %>
          <%= render "active_storage/attachments/attachment", attachment: photo %>
        <% end %>
      </li>
    <% end %>
  </ul>

  <p>
    <%= link_to "Show this album", album %>
  </p>
</div>
```

```ruby
# app/models/album.rb (final state, full file)
class Album < ApplicationRecord
  has_many_attached :photos

  with_options presence: true do
    validates :name
  end
end
```

```ruby
# app/controllers/albums_controller.rb — relevant excerpt (final state)
private
  def set_album
    @album = Album.find(params[:id])
  end

  def album_params
    params.require(:album).permit(:name, photos: [])
  end
```

```ruby
# config/routes.rb (final state)
Rails.application.routes.draw do
  resources :albums

  # root "articles#index"
end
```

```
# scaffold generator command from commit "[GENERATED]: Scaffold `Album`" — note the explicit --no-helper flag
bin/rails generate scaffold album name:string \
        --no-helper \
        --no-api \
        --no-jbuilder
```

```ruby
# test/system/albums_test.rb — the two preservation-focused tests (final state)
test "should preserve file attachments through an invalid submission" do
  visit new_album_url
  fill_in "Name", with: ""
  attach_file "Photos", file_fixture("photo.png")
  click_on "Create Album"

  assert_text "1 error prohibited this album from being saved"

  fill_in "Name", with: @album.name
  click_on "Create Album"

  assert_text "Album was successfully created"
  assert_text @album.name
  assert_link alt: "photo.png", count: 1
end

test "can update Album by uploading and discarding" do
  @album.photos.attach io: file_fixture("photo.png").open, filename: "photo.png"

  visit edit_album_url(@album)
  uncheck "photo.png"
  attach_file "Photos", 2.times.map { file_fixture("photo.png") }
  click_on "Update Album"

  assert_text "Album was successfully updated"
  assert_link alt: "photo.png", count: 2
end
```

- **Doyle's stated tradeoffs**: No branch-specific README/prose exists for this branch (only the generic repo-wide README is present at this commit — this branch is unfinished/undocumented, consistent with the "disabled" framing in the task). The only prose available is the commit message body for "Preview before uploading":

> "* `clone` controller from cloning a new `<input type="file">` for each item in the `FileList`
> * `file-reader` controller for transforming a `File` into a Data URI, and setting the `<img>` element's `[alt]` and `[src]`
> * `disabled` controller for toggling the staged upload inputs to be `[disabled]` and omitted, or enabled and included"

No other tradeoff commentary was committed to this branch.

- **Accessibility notes**: None specific to this branch — no ARIA roles/states are set anywhere in the diff. The only a11y-adjacent detail is that `image_tag` is always given a computed `alt` (`attachment.filename`, or empty string for a non-persisted/placeholder attachment), and `file_reader_controller.js` keeps that `alt` in sync with the live-previewed file's name (`this.imageTarget.alt = file.name`). Checkboxes for existing photos rely on their auto-generated `<label>` (via `form.label :photos, photo.filename, for: id`) for a name, which is how the system tests interact with them (`uncheck "photo.png"`).

- **Currency check**: All commits dated 2021-10-22, pre-Turbo 8. Stimulus 2-era `static get targets()`/`static get values()` syntax throughout (same dated pattern as the mentions branch). Third-party dependency (`@github/template-parts`) pulled live from Skypack CDN rather than vendored/pinned via importmap — same CDN-import pattern as the mentions branch's `combobox-nav`, suggesting this was Doyle's standard practice at the time rather than a one-off. No Turbo Streams/broadcasts/morphing anywhere in this branch.

- **Stimulus controller + ERB helper pairing?** **No.** The scaffold generator was explicitly run with `--no-helper`, so `app/helpers/albums_helper.rb` doesn't even exist in this branch. All Stimulus wiring (`data-controller`, `data-*-target`, `data-*-value`, `data-action`) is inlined directly into ERB view templates (`_form.html.erb`, `photos/_form.html.erb`) — there is no intermediate Ruby helper method generating those data-attributes.

---

### hotwire-example-upload-processing

- **Technique**: Background/async Active Storage analysis (image metadata extraction) with the analysis result streamed back into the page over Action Cable once complete, using Turbo Streams broadcasts triggered by an `after_touch` callback plus a Rails-internal "touch the attachment's record when its blob finishes updating" backport.
- **Problem it solves**: Active Storage's default image analysis (dimensions/metadata) can be slow (simulated here via `sleep 5` in a custom analyzer) and normally runs synchronously/blocks upload feedback. This branch shows the record ("Upload") getting `touch`ed automatically once its blob's analysis metadata is written (via a backported Rails patch, since as of the gem versions in this branch's Gemfile.lock this "touch the record when its attachment's blob updates" behavior wasn't yet built into Active Storage), and that `touch` triggering a Turbo Stream broadcast that replaces the page's rendered `<section>` with fresh markup showing "Processing..." vs. "Processing complete" and up-to-date metadata — with **zero client-side JavaScript**.
- **Commit dates**: 2021-05-04 ("Introduce Upload model") .. 2021-05-05 ("broadcast updates when touched") — all 5 commits land within two days.
- **Needs JS?**: No. This is the pure server-rendered-broadcast pattern — no Stimulus controllers exist anywhere in this branch's diff. The entire "live update" experience comes from `<%= turbo_stream_from @upload %>` (Action Cable subscription) plus server-side `broadcast_replace` calls; Turbo's own built-in `<turbo-cable-stream-source>` element handles applying the incoming `<turbo-stream>` DOM patches.

- **Key code**:

```ruby
# app/models/upload.rb (final state, full file)
class Upload < ApplicationRecord
  has_one_attached :file

  after_touch -> { broadcast_replace }
end
```

```ruby
# app/models/slow_image_analyzer.rb (final state, full file)
class SlowImageAnalyzer < ActiveStorage::Analyzer::ImageAnalyzer::Vips
  def metadata
    sleep 5

    super
  end
end
```

```ruby
# app/controllers/uploads_controller.rb (final state, full file)
class UploadsController < ApplicationController
  def new
    @upload = Upload.new
  end

  def create
    @upload = Upload.create! upload_params

    redirect_to @upload
  end

  def show
    @upload = Upload.find params[:id]
  end

  private

  def upload_params
    params.require(:upload).permit(:file)
  end
end
```

```erb
<%# app/views/uploads/show.html.erb (final state, full file) %>
<%= turbo_stream_from @upload %>

<%= render partial: "uploads/upload", object: @upload %>
```

```erb
<%# app/views/uploads/_upload.html.erb (final state, full file) %>
<section id="<%= dom_id upload %>">
  <h1>Uploaded at <time><%= upload.created_at %></time></h1>

  <%= image_tag upload.file %>

  <table>
    <tr>
      <% upload.file.metadata.each do |key, value| %>
        <th><%= key %></th>
        <td><%= value %></td>
      <% end %>
    </tr>

    <% if upload.file.analyzed? %>
      <caption>Processing complete</caption>
    <% else %>
      <caption>Processing...</caption>
    <% end %>
  </table>
</section>
```

```erb
<%# app/views/uploads/new.html.erb (final state, full file) %>
<%= form_with model: @upload do |form| %>
  <%= form.label :file %>
  <%= form.file_field :file, direct_upload: true %>

  <button>Upload</button>
<% end %>
```

```ruby
# config/application.rb — relevant excerpt (final state)
config.after_initialize do
  config.active_storage.analyzers.prepend SlowImageAnalyzer
end
```

```ruby
# config/initializers/active_storage.rb (final state, full file)
# Backport https://github.com/rails/rails/commit/294c2710620871a691e4ca5fefb5e5ace279195d

ActiveSupport.on_load :active_storage_blob do
  after_update :touch_attachment_records

  def touch_attachment_records
    attachments.includes(:record).each do |attachment|
      attachment.touch
    end
  end
end
```

```ruby
# config/routes.rb (final state, full file)
Rails.application.routes.draw do
  resources :uploads, only: [:new, :create, :show]

  root to: redirect("/uploads/new")
end
```

- **Doyle's stated tradeoffs**: This branch has no branch-specific narrative README — the only prose is the terse commit messages themselves ("Introduce Upload model", "Upload show page", "Upload analysis", "Custom Analyzer that takes time", "broadcast updates when touched") and one commit body:

> "Skipping image analysis because the mini_magick gem isn't installed" (commit body on "Upload analysis" — a note-to-self about a local environment gotcha encountered while building the branch, not a design tradeoff).

The `config/initializers/active_storage.rb` file's own comment is the closest thing to a stated rationale in this branch:

> "Backport https://github.com/rails/rails/commit/294c2710620871a691e4ca5fefb5e5ace279195d"

i.e., Doyle is explicitly patching in upstream Rails behavior (blob-update-touches-attached-record) that didn't yet exist in the Active Storage version this branch's Gemfile.lock pins, purely so `after_touch` on `Upload` would fire once the async-analyzed blob's metadata finished writing.

- **Accessibility notes**: None — no ARIA attributes, no interactive JS, no client-side focus management anywhere in this branch. All feedback ("Processing..." / "Processing complete") is plain server-rendered text inside a `<table><caption>`.

- **Currency check**: Commits dated 2021-05, but the checked-out tree's `Gemfile.lock` pins `rails (7.0.2.2)` / `turbo-rails (1.0.1)` and `db/schema.rb` carries schema version `2022_02_13_162643` and `config/application.rb` declares `config.load_defaults 7.0` — i.e., **this branch was rebased/updated forward onto Rails 7.0 well after its original 2021-05 authorship date** (consistent with the repo's own README warning that "histories are rebased and rewritten on a regular basis"). Even so, `turbo-rails 1.0.1` predates Turbo 8 (turbo-rails 2.x, Feb 2024) — this branch uses the **classic** `Turbo::Broadcastable#broadcast_replace` / `turbo_stream_from` pairing, not morphing (`refresh`/`broadcasts_refreshes`) or the newer `Turbo::StreamsChannel` singleton-stream helpers introduced with Turbo 8. Flag as **pre-Turbo-8 broadcast idiom** — a currency gap if used as a model for new code today. No Stimulus at all, so no Stimulus-syntax-version concerns.

- **Stimulus controller + ERB helper pairing?** N/A — no Stimulus controllers exist in this branch at all, and `app/helpers/` was not touched by the diff (no Upload-specific helper was generated or used).

---

### hotwire-example-process-network-request

- **Technique**: Background a slow "network request" (simulated) inside an `ActiveJob`, replacing the request-response-cycle-blocking synchronous version, and stream the result back with `Turbo::Broadcastable` — including a custom `ActiveJob::Serializers::ObjectSerializer` so a plain (non-ActiveRecord) `ActiveModel::Model` instance can be safely round-tripped through the job's serialized arguments.
- **Problem it solves**: A form (`OrderSearch`, a POJO-ish `ActiveModel::Model`, not backed by the database) needs to call out to a slow "network request" (`sleep 1` standing in for a real HTTP call) to resolve an `Order`. Doing this synchronously in the controller blocks the whole request-response cycle. This branch moves the slow work into `GetOrderJob`, immediately renders a "Searching..." placeholder, and pushes the final result over a Turbo Stream broadcast once the job completes — while dealing with the wrinkle that ActiveJob can't natively serialize an arbitrary `ActiveModel::Model` instance as a job argument, requiring a custom serializer.
- **Commit dates**: 2024-11-10 only — all 3 commits ("Base", "Background request and broadcast response", "Leverage `Turbo::Broadcastable`") land the same day (per Steve Polito, not Sean Doyle — this is one of the newer, non-Doyle-authored branches).
- **Needs JS?**: No. Zero Stimulus controllers, zero custom JS anywhere in the diff. The entire "live update while backgrounded" behavior is `<%= turbo_stream_from order_search %>` (Action Cable subscription, rendered conditionally only while `processing?`) plus a server-side `order_search.broadcast_replace` call from inside the job.

- **Key code** (this branch's whole diff is small enough to include essentially in full):

```ruby
# app/models/order.rb (final state, full file) — plain ActiveModel result object
class Order
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :big_integer
  attribute :product, :string
  attribute :quantity, :integer

  def to_partial_path
    "orders/order"
  end
end
```

```ruby
# app/models/order_search.rb (final state, full file)
class OrderSearch
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Turbo::Broadcastable

  attribute :order_id, :big_integer
  attribute :result

  alias_method :processed?, :result

  def processing?
    order_id && result.nil?
  end

  def process
    return unless processing?

    GetOrderJob.perform_later(self)
  end
end
```

```ruby
# app/jobs/get_order_job.rb (final state, full file)
class GetOrderJob < ActiveJob::Base
  def perform(order_search)
    # Simulate network request
    sleep 1

    # Simulate building result from response
    order_search.result = Order.new(id: order_search.order_id, product: "Some Widget", quantity: 1)

    order_search.broadcast_replace
  end
end
```

```ruby
# app/serializers/order_search_serializer.rb (final state, full file)
class OrderSearchSerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize(order_search)
    super(
      "order_id" => order_search.order_id,
      "result" => order_search.result
    )
  end

  def deserialize(hash)
    OrderSearch.new(order_id: hash["order_id"], result: hash["result"])
  end

  private

  def klass
    OrderSearch
  end
end
```

```ruby
# config/initializers/custom_serializers.rb (final state, full file)
Rails.application.config.active_job.custom_serializers << OrderSearchSerializer
```

```ruby
# config/application.rb — relevant excerpt (final state)
config.autoload_once_paths << "#{root}/app/serializers"
```

```ruby
# app/controllers/orders_controller.rb (final state, full file)
class OrdersController < ApplicationController
  def index
    @order_search = OrderSearch.new(params.permit!.slice(:order_id))
    @order_search.process
  end
end
```

```erb
<%# app/views/order_searches/_order_search.html.erb (final state, full file) %>
<div id="<%= dom_id(order_search) %>">
  <% if order_search.processing? %>
    <%= turbo_stream_from order_search %>
    <p>Searching...</p>
  <% elsif order_search.processed? %>
    <%= render order_search.result %>
  <% end %>
</div>
```

```erb
<%# app/views/orders/index.html.erb (final state, full file) %>
<%= form_with model: @order_search, scope: "", method: :get do |form| %>
  <%= form.label :order_id, "Order ID" %>
  <%= form.number_field :order_id, required: true %>

  <%= form.submit "Find order" %>
<% end %>

<%= render @order_search %>
```

```erb
<%# app/views/orders/_order.html.erb (final state, full file) %>
<p>Product: <%= order.product %></p>
<p>Quantity: <%= order.quantity %></p>
```

```ruby
# config/routes.rb (final state, full file)
Rails.application.routes.draw do
  resources :orders, only: %i[index]

  resolve("OrderSearch") { route_for :orders }

  root "orders#index"
end
```

```ruby
# test/system/order_stories_test.rb (final state, full file)
require "application_system_test_case"

class OrderStoriesTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test "searching an order" do
    visit orders_path

    assert_no_text "Searching..."

    fill_in "Order ID", with: 1
    click_button "Find order"

    assert_text "Searching..."

    perform_enqueued_jobs only: GetOrderJob

    assert_no_text "Searching..."
    assert_text "Product: Some Widget"
    assert_text "Quantity: 1"
  end
end
```

- **Doyle's stated tradeoffs** (authored by Steve Polito, not Doyle, but captured verbatim per instructions since it's in-repo on this branch):

> "Base — This is our starting point. Simulate processing a network request in the request-response cycle in a way that blocks the page from being rendered immediately. Note that we're only working with `ActiveModel` instances. There is nothing stored in the database. Our objective is to background this, and return the response with Turbo."

> "Background request and broadcast response — Notable changes include adding a [custom serializer], and wrapping our partial with an element identified by [`dom_id`] so that we can broadcast to it. This implementation satisfies our requirements, but its ergonomics could be improved. Additionally, the scope for our channel is really broad, since we're identifying our element with `#new_order_search`. Ideally, this should be scoped to the user issuing the request, or to the model instance."

> "Leverage `Turbo::Broadcastable` — Improves the ergonomics without changing behavior." (i.e., replaces the manual `Turbo::StreamsChannel.broadcast_replace_to(order_search, target: ..., content: ApplicationController.render(partial: ..., locals: ...))` call with the one-liner `order_search.broadcast_replace` once `OrderSearch` includes `Turbo::Broadcastable`.)

- **Accessibility notes**: None — no ARIA attributes anywhere in the diff. "Searching..." / result content is plain text swapped in-place by a Turbo Stream `replace` action; there's no explicit `aria-live` region, so a screen reader's behavior on this update depends entirely on Turbo's/the browser's default handling of DOM replacement (worth flagging as a **gap**, not a strength, if this pattern is used as a template — no `aria-live="polite"` wrapper is present around the "Searching..." → result transition).

- **Currency check**: All commits dated **2024-11-10 — after Turbo 8's Feb 2024 release** — so this is the one branch that could plausibly be expected to use modern Turbo 8 idioms. It does use `Turbo::Broadcastable` (module-based, not the raw `Turbo::StreamsChannel.broadcast_replace_to` class call it replaced), which is the more modern/ergonomic API. However: `Gemfile.lock` still pins `rails (7.0.2.2)` and `turbo-rails (1.0.1)` — **turbo-rails 1.0.1 predates Turbo 8 (turbo-rails 2.x)**, so despite the Nov-2024 commit date, this branch is **not actually running on Turbo 8**. No morphing (`Turbo::Broadcastable#broadcast_refresh`/`broadcasts_refreshes` were added with Turbo 8's `refresh` action) is used or available at this gem version; the branch uses only the pre-8 `broadcast_replace`/`turbo_stream_from` primitives. Flag this as the clearest instance in the whole repo of **stale gem pins outliving the branch's authorship date** — useful evidence that commit dates in this repo cannot be trusted as a proxy for "what Turbo version was actually used," per the repo's own README warning about aggressive rebasing/rewriting.

- **Stimulus controller + ERB helper pairing?** N/A — no Stimulus controllers and no custom helpers exist in this branch (no `app/helpers/order_searches_helper.rb` or similar was added). All wiring is Ruby model methods (`processing?`, `processed?`) called directly from ERB conditionals, plus the `Turbo::Broadcastable` module mixed into the ActiveModel class itself.

---

## Per-branch: grids & realtime


### hotwire-example-chat

### hotwire-example-chat

**Technique**: Turbo Streams broadcasting (`broadcast_append_to`) for a real-time 1:1 chat, backed by a handful of small, single-purpose Stimulus controllers (`autoscroll`, `current`, `hotkey`) that patch over things the server can't know about at render/broadcast time.

**Problem it solves**: Build a real-time direct-message chat (per pair of `User`s) where new `Message` records broadcast into every open conversation window via `<turbo-stream>`, while still handling client-side concerns a server-rendered broadcast can't (whose message is "mine", what timezone/relative time to show, scrolling to the newest message, submitting with a keyboard shortcut).

**Commit dates**: 2021-11-06 .. 2021-11-09 (four working days; a `[SKIP]` Replit-support commit lands later on 2022-05-20 and is not functionally relevant).

**Needs JS?** Yes, but minimally — three tiny Stimulus controllers (7, 15, and 20 lines) plus two bare CDN-imported (Skypack) libraries (`@github/time-elements`, `form-request-submit-polyfill`) wired in via plain `import` statements in `app/javascript/application.js`. No build-step bundling of third-party code; imports point straight at `cdn.skypack.dev`.

**Key code**

```ruby
# app/models/message.rb
class Message < ApplicationRecord
  has_rich_text :content

  with_options class_name: "User" do
    belongs_to :sender
    belongs_to :recipient
  end

  scope :latest_first, -> { order created_at: :desc }
  scope :involving, ->(users) { where sender: users, recipient: users }

  def broadcast_append_to_participants
    streamables = values_at(:sender, :recipient).sort

    broadcast_append_to streamables
  end
end
```

```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_one_attached :avatar

  with_options class_name: "Message" do
    has_many :sent_messages, foreign_key: :sender_id
  end
end
```

```ruby
# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  def index
    @user = find_user
    @streamables = [ Current.user, @user ].sort
    @messages = Message.latest_first.involving @streamables
  end

  def create
    @user = find_user
    @message = Current.user.sent_messages.new message_params.merge(recipient: @user)

    @message.save!
    @message.broadcast_append_to_participants

    redirect_to user_messages_path(@user)
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def find_user(id = params[:user_id])
    User.find id
  end
end
```

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate!

  private def authenticate!
    if (id = session[:user_id])
      Current.user = User.find id
    else
      redirect_to new_session_path
    end
  end
end
```

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  skip_before_action :authenticate!

  def new
    @users = User.all
  end

  def create
    session[:user_id] = session_params.fetch(:id)

    redirect_to users_path
  end

  private

  def session_params
    params.require(:session).permit(:id)
  end
end
```

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def index
    @users = User.without Current.user
  end
end
```

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :sessions, only: [:new, :create]
  resources :users, only: :index do
    resources :messages, only: [:index, :create]
  end

  # Defines the root path route ("/")
  root to: redirect("/sessions/new")
end
```

```erb
<%# app/views/messages/index.html.erb %>
<%= turbo_stream_from @streamables %>

<main class="flex flex-col h-screen">
  <meta name="current" content="<%= Current.user.signed_id purpose: "current" %>">

  <section class="flex-1 flex flex-col overflow-y-scroll space-y-2" id="messages">
    <%= render partial: "messages/message", collection: @messages.reverse %>

    <p class="hidden text-lg mx-auto only:block">Start the conversation!</p>
  </section>

  <aside>
    <%= form_with model: [ @user, @messages.new ], data: { controller: "hotkey" } do |form| %>
      <%= form.label :content %>
      <%= form.rich_text_area :content, class: "h-24 overflow-y-scroll", autofocus: true,
            data: { hotkey_modified_param: true, hotkey_key_param: "Enter",
                    action: "keydown->hotkey#requestSubmit" } %>

      <button>Send</button>
    <% end %>
  </aside>
</main>
```

```erb
<%# app/views/messages/_message.html.erb %>
<article id="<%= dom_id message %>" class="flex items-start group current:flex-row-reverse"
         data-controller="autoscroll current"
         data-current-user-class="current"
         data-current-token-value="<%= message.sender.signed_id purpose: "current" %>">
  <%= image_tag message.sender.avatar, class: "rounded-full mx-4",
        width: 32, height: 32, alt: message.sender.name %>

  <div class="flex flex-col items-start space-y-1 group-current:items-end">
    <div class="rounded-xl bg-gray-100 p-2 group-current:bg-blue-500 group-current:text-white">
      <%= message.content %>
    </div>

    <relative-time datetime="<%= message.created_at.iso8601 %>">
      <time datetime="<%= message.created_at.iso8601 %>">
        <%= localize message.created_at, format: :long %>
      </time>
    </relative-time>
  </div>
</article>
```

```js
// app/javascript/application.js
// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "tailwind.config"
import "@hotwired/turbo-rails"
import "controllers"
import "trix"
import "@rails/actiontext"
import "https://cdn.skypack.dev/@github/time-elements"
```

```js
// app/javascript/controllers/current_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get classes() { return [ "user" ] }
  static get values() { return { token: String } }

  tokenValueChanged(value) {
    const isCurrent = value && value == this.tokenFromMeta

    for (const className of this.userClasses) {
      this.element.classList.toggle(className, isCurrent)
    }
  }

  get tokenFromMeta() {
    const [ meta ] = document.getElementsByName(this.identifier)

    return meta?.content
  }
}
```

```js
// app/javascript/controllers/autoscroll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.scrollIntoView()
  }
}
```

```js
// app/javascript/controllers/hotkey_controller.js
import { Controller } from "@hotwired/stimulus"
import "https://cdn.skypack.dev/form-request-submit-polyfill"

export default class extends Controller {
  requestSubmit(event) {
    const { target, key, ctrlKey, metaKey, params } = event
    const modified = ctrlKey || metaKey

    if (params.key == key && params.modified == modified) {
      event.preventDefault()

      this.element.requestSubmit()
    }
  }
}
```

**Doyle's stated tradeoffs**

The branch's last three commits are explicitly framed as a trilogy of "what the server-rendered/broadcast HTML *doesn't* know" problems. Note: the task brief guessed that "Not knowing the browsing context" would be about breaking a Turbo Frame out to top-level navigation — **it is not**. That commit is actually about timezone/locale context lost when a background job (not a request) renders and broadcasts HTML. Transcribing his real reasoning below, verbatim:

> **Not knowing the current user** — Custom `current:` variant and controller
>
> Mark the elements with their creator's [signed_id][] to prevent tampering and exposing a record's ID value. They're signed with a matching `purpose:` argument.
>
> Also render a `<meta>` element with a matching `[content]` value.
>
> [signed_id]: https://edgeapi.rubyonrails.org/classes/ActiveRecord/SignedId.html#method-i-signed_id

> **Not knowing the state of the DOM** — Conditional visibility with CSS
>
> When broadcasting changes outside of the request-response cycle, we won't have access to what constitutes the rest of the list. We're better off rendering more and using in-place, contextual information to hide or show.

> **Not knowing the browsing context** — Context-less dates and times
>
> Progressively enhance the built-in [`<time>`][] element with `<relative-time>` from [github/time-elements][]. We can "localize" the time based on our server's time zone or other request-based contextual information.
>
> Once we start broadcasting data from a background job to _all_ subscribers, we need to ship an element that can re-construct the correct context _in the browser_.
>
> [github/time-elements]: https://github.com/github/time-elements/tree/main#relative-time
> [`<time>`]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/time

The unifying theme across all three: **a Turbo Stream broadcast fired from a background job (`ActiveJob`/`ActionCable`) has no per-viewer request context** — no "who is viewing this", no "what else is already in the DOM for this viewer", no "what timezone/locale does this viewer want". Doyle's answer each time is to push the missing context into the client: sign+compare a per-user token (`current_controller.js`), use CSS `:only-child`/`only:` structural selectors instead of server-computed "is this the first message" logic, and ship a custom element (`<relative-time>`) that computes localized/relative time in the browser instead of trusting server-side `localize`.

Also relevant, from the "Broadcasting `<turbo-stream>` elements" commit:

> It's also worth mentioning the fact that Active Job doesn't have a `default_url_options` configuration out of the box, so is poorly equipped to resolve fully-qualified URL values while rendering Action View templates and Active Storage uploads.

— which is why `config/application.rb` sets `config.action_controller.default_url_options = config.action_mailer.default_url_options = default_url_options` and `config/environments/development.rb` sets `default_url_options.merge! host: "localhost", port: "3000"`. This is the actual "browsing-context-free rendering" plumbing fix (background-job-rendered partials need explicit host/port since there's no incoming request to infer them from) — closely related in spirit to, but distinct from, the commit titled "Not knowing the browsing context."

**Accessibility notes**: Not the focus of this branch. `image_tag` avatars carry `alt: message.sender.name`. No `aria-live` region is added around the `#messages` list even though it receives streamed appends — worth flagging as a gap if using this as a real-time-region reference (a Turbo Stream `append` into a plain `<section id="messages">` without `aria-live="polite"` won't be announced by screen readers).

**Currency check**: All 2021 commits, pre-dating Turbo 8 (Feb 2024) by over two years. Nothing here uses deprecated Turbo Frame/Stream APIs — `broadcast_append_to`, `turbo_stream_from`, and Stimulus `static values`/`static classes` are all still current. The CDN-imported `@github/time-elements` and `form-request-submit-polyfill` via `cdn.skypack.dev` are dated in *approach* (Skypack CDN imports rather than importmap pins via `bin/importmap pin`) but not broken — worth noting Skypack's long-term status/availability is a risk for anyone reusing this verbatim today.

**Third-party JS integration pattern**: Both `@github/time-elements` and `form-request-submit-polyfill` are pulled in as bare side-effect imports directly from Skypack's CDN inside `app/javascript/application.js` (for time-elements) and inside `hotkey_controller.js` itself (for the polyfill) — no importmap pin entries shown in this diff, no npm/yarn dependency. This is the lightest possible integration: the custom element (`<relative-time>`) self-registers and is used directly in ERB with zero Stimulus glue; the polyfill patches `HTMLFormElement.prototype.requestSubmit` globally and the `hotkey_controller.js` Stimulus controller calls `this.element.requestSubmit()` normally. No `disconnect()`/teardown code anywhere in this branch — none of the controllers need it (no external widget instance to tear down).

**Does he pair a Stimulus controller with an ERB helper/partial wrapper?** No dedicated helper method or wrapper partial — controllers are wired directly via `data-controller`/`data-action`/`data-*-value` attributes inline in `_message.html.erb` and `index.html.erb`. `current_controller.js` is bound directly on the `<article>` element that also carries the `dom_id` id; no separate partial exists to encapsulate the current-user-marking pattern.

---

### hotwire-example-map

### hotwire-example-map

**Technique**: A single `leaflet` Stimulus controller wraps the third-party Leaflet.js map library end-to-end — tile layer, GeoJSON marker layer, bounding-box search form, and cross-navigation persistence via `data-turbo-permanent` — driven entirely by Stimulus Values decoded from server-rendered JSON (config YAML on one side, ActiveRecord via jbuilder GeoJSON on the other).

**Problem it solves**: Render a geographic map of `Location` records (Leaflet + OpenStreetMap/MapBox tiles), let users pan/zoom to filter the list by a bounding box (progressively-enhanced GET form), render custom SVG markers instead of Leaflet defaults, deep-link from a marker to a `location#show` page, and — the branch's centerpiece — keep the *same* live Leaflet map instance alive and animating smoothly across full Turbo Drive page navigations (list → show → list) instead of tearing it down and rebuilding it on every page load.

**Commit dates**: 2021-04-03 .. 2021-04-10 (about a week; excludes the 2021-04-03 `[GENERATED]`/`[SKIP]` scaffold/fixture commits).

**Needs JS?** Yes — this is the most JS-heavy of the four branches by necessity (wrapping a real mapping library), but it is still exactly one Stimulus controller file (`leaflet_controller.js`, ~65 lines final). Leaflet itself is loaded as a bare CDN import (`import L from "https://cdn.skypack.dev/leaflet@1.6.0"`), with its CSS pulled in via a `<link>` tag in the layout (not bundled).

**Key code**

```javascript
// app/javascript/controllers/leaflet_controller.js
import L from "https://cdn.skypack.dev/leaflet@1.6.0"
import { Controller } from "@hotwired/stimulus"

const targetsToMaps = new WeakMap
const mapsToTileLayers = new WeakMap
const mapsToGeoJsonLayers = new WeakMap

export default class extends Controller {
  static get targets() { return [ "bbox", "map", "template" ] }
  static get values() { return { tileLayer: Object, geoJsonLayer: Object } }

  initialize() {
    this.leaflet = targetsToMaps.get(this.mapTarget) || L.map(this.mapTarget)

    targetsToMaps.set(this.mapTarget, this.leaflet)
  }

  connect() {
    this.leaflet.on("moveend", this.prepareSearch)
  }

  disconnect() {
    this.leaflet.off("moveend", this.prepareSearch)
  }

  tileLayerValueChanged({ templateUrl, ...options }) {
    const layer = L.tileLayer(templateUrl, options)
    const existingLayer = mapsToTileLayers.get(this.leaflet)

    layer.addTo(this.leaflet).bringToBack()
    mapsToTileLayers.set(this.leaflet, layer)

    if (existingLayer) {
      existingLayer.removeFrom(this.leaflet)
    }
  }

  geoJsonLayerValueChanged({ bbox: [ west, south, east, north ], ...featureCollection }) {
    const { pointToLayer } = this
    const bounds = L.latLngBounds([ south, west ], [ north, east ])
    const layer = L.geoJSON(featureCollection, { pointToLayer })
    const existingLayer = mapsToGeoJsonLayers.get(this.leaflet)

    layer.addTo(this.leaflet).bringToFront()
    mapsToGeoJsonLayers.set(this.leaflet, layer)

    if (existingLayer) {
      this.leaflet.once("zoomend", () => existingLayer.removeFrom(this.leaflet))
      this.leaflet.flyToBounds(bounds)
    } else {
      this.leaflet.fitBounds(bounds)
    }
  }

  prepareSearch = ({ target }) => {
    const bbox = target.getBounds().toBBoxString()
    this.bboxTarget.value = bbox
  }

  pointToLayer = ({ properties: { icon: { id, ...options } } }, latLng) => {
    const html = this.templateTarget.content.getElementById(id).cloneNode(true)

    return L.marker(latLng, { icon: L.divIcon({ html, ...options }) })
  }
}
```

```erb
<%# app/views/locations/_leaflet.html.erb %>
<%= tag.section data: {
  controller: "leaflet",
  leaflet_geo_json_layer_value: geo_json_layer,
  leaflet_tile_layer_value: tile_layer,
} do %>
  <h1>Map</h1>

  <template data-leaflet-target="template">
    <% locations.each do |location| %>
      <%= link_to location_path(location), id: dom_id(location, :marker) do %>
        <span class="sr-only"><%= location.name %></span>
        <%= inline_svg_tag "marker", class: "h-8 w-8" %>
      <% end %>
    <% end %>
  </template>

  <article class="w-full h-96" data-leaflet-target="map"
    id="leaflet-map" data-turbo-permanent></article>

  <form>
    <button name="bbox" data-leaflet-target="bbox">
      Search this area
    </button>
  </form>
<% end %>
```

```ruby
# app/models/bounding_box.rb
class BoundingBox
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :west, :decimal
  attribute :south, :decimal
  attribute :east, :decimal
  attribute :north, :decimal

  validates :west, :east, inclusion: { in: -180..180 }
  validates :south, :north, inclusion: { in: -90..90 }

  def self.parse(bbox)
    coordinates bbox.to_s.split(",")
  end

  def self.coordinates(coordinates)
    west, south, east, north = coordinates

    new west: west, south: south, east: east, north: north
  end

  def self.containing(locations)
    west, east = locations.pluck(:longitude).minmax
    south, north = locations.pluck(:latitude).minmax

    coordinates [ west, south, east, north ]
  end

  def to_h
    { longitude: west..east, latitude: south..north }
  end

  def to_a
    [ west, south, east, north ]
  end

  def to_s
    to_a.join(",")
  end
end
```

```ruby
# app/models/location.rb
class Location < ApplicationRecord
  scope :within, ->(bounding_box) { where bounding_box.to_h }
end
```

```ruby
# app/controllers/locations_controller.rb
class LocationsController < ApplicationController
  before_action :set_location, only: %i[ show edit update destroy ]

  # GET /locations or /locations.json
  def index
    bounding_box = BoundingBox.parse(params[:bbox])

    if bounding_box.valid?
      @locations = Location.within(bounding_box)
      @bounding_box = bounding_box
    else
      @locations = Location.all
      @bounding_box = BoundingBox.containing(@locations)
    end
  end

  # GET /locations/1 or /locations/1.json
  def show
    @bounding_box = BoundingBox.containing([ @location ])
  end

  # GET /locations/new
  def new
    @location = Location.new
  end

  # GET /locations/1/edit
  def edit
  end

  # POST /locations or /locations.json
  def create
    @location = Location.new(location_params)

    respond_to do |format|
      if @location.save
        format.html { redirect_to @location, notice: "Location was successfully created." }
        format.json { render :show, status: :created, location: @location }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /locations/1 or /locations/1.json
  def update
    respond_to do |format|
      if @location.update(location_params)
        format.html { redirect_to @location, notice: "Location was successfully updated." }
        format.json { render :show, status: :ok, location: @location }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /locations/1 or /locations/1.json
  def destroy
    @location.destroy
    respond_to do |format|
      format.html { redirect_to locations_url, notice: "Location was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_location
      @location = Location.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def location_params
      params.require(:location).permit(:name, :latitude, :longitude)
    end
end
```

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def inline_svg_tag(name, **options)
    svg_path(name).read.strip.then do |svg|
      raw options.any? ? svg.sub(/\A<svg(.*?)>/, "<svg\\1 #{tag.attributes(options)}>") : svg
    end
  end

  def svg_path(name)
    Rails.root.join("app/assets/images/#{name}.svg")
  end
end
```

```html
<!-- app/assets/images/marker.svg -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 29 34" fill="none" role="presentation">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M23.9016 24.5C26.6454 21.9144 28.3582 18.2468 28.3582 14.1791C28.3582 6.3482 22.01 0 14.1791 0C6.3482 0 0 6.3482 0 14.1791C0 18.5588 1.98575 22.4748 5.10603 25.0757L14.5 34L24 24.5H23.9016Z" fill="currentColor"/>
</svg>
```

```yaml
# config/leaflet.yml
shared:
  accessToken: pk.REDACTED-mapbox-token
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
  id: mapbox/streets-v11
  maxZoom: 18
  templateUrl: https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}
  tileSize: 512
  zoomOffset: -1
```
(Note: this is Doyle's own public-tutorial MapBox token committed in the example repo — not a secret worth treating as sensitive, but flagging since it is a literal credential-shaped string in the diff.)

```ruby
# app/views/locations/index.json.jbuilder
json.type "FeatureCollection"
json.features @locations, partial: "locations/location", as: :location
json.bbox @bounding_box.to_a
```

```ruby
# app/views/locations/show.json.jbuilder
json.type "FeatureCollection"
json.features [ @location ], partial: "locations/location", as: :location
json.bbox @bounding_box.to_a
```

```ruby
# app/views/locations/_location.json.jbuilder
json.type "Feature"
json.geometry do
  json.type "Point"
  json.coordinates location.values_at(:longitude, :latitude)
end
json.properties do
  json.icon do
    json.id dom_id(location, :marker)
  end
end
```

```erb
<%# app/views/locations/index.html.erb %>
<p id="notice"><%= notice %></p>

<%= render partial: "locations/leaflet", locals: {
  locations: @locations,
  geo_json_layer: render(template: "locations/index", formats: :json),
  tile_layer: Rails.configuration.x.leaflet,
} %>

<section id="locations">
  <h1>Locations</h1>

  <%= render @locations %>
</section>

<%= link_to "New location", new_location_path %>
```

```erb
<%# app/views/locations/show.html.erb %>
<p id="notice"><%= notice %></p>

<%= render partial: "locations/leaflet", locals: {
  locations: [ @location ],
  geo_json_layer: render(template: "locations/show", formats: :json),
  tile_layer: Rails.configuration.x.leaflet,
} %>

<section>
  <h1><%= @location.name %></h1>

  <%= render @location %>
</section>

<div>
  <%= link_to "Edit this location", edit_location_path(@location) %> |
  <%= link_to "Back to locations", locations_path %>

  <%= button_to "Destroy this location", location_path(@location), method: :delete %>
</div>
```

```erb
<%# app/views/layouts/application.html.erb (relevant excerpt) %>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.6.0/dist/leaflet.css"
  integrity="sha512-xwE/Az9zrjBIphAcBb3F6JVqxf46+CDLwfLMHloNu6KEQCAWi6HcDUbeOfBIptF7tcCzusKFjFw2yuvEpDL9wQ=="
  crossorigin="">
```

```ruby
# config/application.rb (relevant line)
config.x.leaflet = config_for(:leaflet)
```

```ruby
# test/system/locations_test.rb
require "application_system_test_case"

class LocationsTest < ApplicationSystemTestCase
  setup do
    @location = locations(:union_square)
  end

  test "visiting the index" do
    visit locations_url
    assert_selector "h1", text: "Location"
  end

  test "should create Location" do
    visit locations_url
    click_on "New location"

    fill_in "Latitude", with: @location.latitude
    fill_in "Longitude", with: @location.longitude
    fill_in "Name", with: @location.name
    click_on "Create Location"

    assert_text "Location was successfully created"
    click_on "Back"
  end

  test "should update Location" do
    visit locations_url
    click_on "Show this location", match: :first
    click_on "Edit this location"

    fill_in "Latitude", with: @location.latitude
    fill_in "Longitude", with: @location.longitude
    fill_in "Name", with: @location.name
    click_on "Update Location"

    assert_text "Location was successfully updated"
    click_on "Back"
  end

  test "should destroy Location" do
    visit locations_url
    click_on "Show this location", match: :first
    click_on "Destroy this location"

    assert_text "Location was successfully destroyed"
  end

  test "list includes locations" do
    parks_on_broadway = locations(:union_square, :madison_square, :herald_square, :time_square, :columbus_circle)

    visit locations_path

    within_section "Locations" do
      parks_on_broadway.all? { assert_text _1.name }
    end
    within_section "Map" do
      parks_on_broadway.all? { assert_link href: location_path(_1) }
    end
  end

  test "limits results geographically by bounding box" do
    parks_within_bounds = locations(:madison_square, :herald_square)
    parks_outside_bounds = locations(:union_square, :time_square, :columbus_circle)

    visit locations_path
    zoom_in(2.times).then { click_on "Search this area" }

    within_section "Locations" do
      parks_within_bounds.all? { assert_text _1.name }
      parks_outside_bounds.none? { assert_no_text _1.name }
    end
    within_section "Map" do
      parks_within_bounds.all? { assert_link href: location_path(_1) }
      parks_outside_bounds.none? { assert_no_link href: location_path(_1) }
    end
  end

  test "renders the location on the map alongside the rest of its information" do
    union_square, columbus_circle = locations(:union_square, :columbus_circle)

    visit locations_path
    within_section("Map") { click_on union_square.name }

    within_section union_square.name do
      assert_link href: location_path(union_square)
      assert_no_text href: location_path(columbus_circle)
    end
    within_section "Map" do
      assert_link href: location_path(union_square)
      assert_no_link href: location_path(columbus_circle)
    end
  end

  def zoom_in(times = 1.times)
    times.each { click_on "Zoom in" }
    wait_for_animation
  end

  def wait_for_animation
    assert_no_css ".leaflet-zoom-anim"
  end
end
```

**Doyle's stated tradeoffs**

> **A note about operational security** — It's worth highlighting the fact that by embedding our configuration values _directly_ into our HTML and JavaScript code, we're transmitting them to each client in plain text. That is acceptable in this case, since the Leaflet configuration doesn't contain any credentials or secrets.
>
> The `L.TileLayer` initialization process requires a [MapBox token] as an argument, which would be transmitted in plain text even if we declared it elsewhere in our client-side code. Keep this in mind when considering encoding configuration values with `Rails.application.config_for`.

> **Making our map's navigation a seamless experience** — While navigating from the list of Locations to a single Location is functional, it's a jarring experience. There is a noticeable flicker in the map, and the immediate change in the map's bounds is disorienting. If this were implemented as a single-page application (SPA), the application would preserve the map's state across navigations, which could eliminate the flickering and would provide an opportunity to animate from bounding box to bounding box.
>
> Luckily, Turbo supports preserving elements across page loads through the `data-turbo-permanent` attribute:
> > Designate permanent elements by giving them an HTML `id` and annotating them with `data-turbo-permanent`.
>
> ... While it might seem as simple as annotating an element with an `[id]` and `[data-turbo-permanent]`, we're now responsible for maintaining the element's long-lived state. Taking on that responsibility comes with several considerations.
>
> First of all, we don't want to re-initialize the map if we already have access to one. As a memoization strategy, we'll store the instance of our `L.Map` in a `WeakMap` value, keyed by the long-lived `HTMLElement` referenced by the `this.mapTarget` property. Since the element's instance state will span page navigations, it will ferry our map forward and backward through the browser's history.
>
> By marking the element with `[data-turbo-permanent]` and handling those circumstances, we're able to seamlessly animate the map between navigations, achieving an SPA-like experience with server-rendered HTML.

**Accessibility notes**: Markers use visually-hidden text for screen readers: `<span class="sr-only"><%= location.name %></span>` inside each marker `<%= link_to %>`, alongside the SVG icon (`role="presentation"` on the `<svg>`, correctly hiding the decorative graphic from AT while the sr-only text carries the label). No `aria-live` on the location list; no explicit ARIA roles on the map container itself (Leaflet's own container ships some, but that's outside Doyle's code). Not a keyboard-navigation deep dive like the grid branch — this branch's accessibility contribution is narrowly the marker-labeling pattern.

**Currency check**: 2021-04 commits, ~3 years before Turbo 8 (Feb 2024). `data-turbo-permanent` is a long-standing Turbo Drive feature, still current in Turbo 8. No deprecated APIs spotted; the Skypack CDN dependency (`cdn.skypack.dev`) is the main "this predates modern importmap-pin conventions" flag, same as the chat branch.

**Third-party JS integration pattern** (priority — this is the clearest example in the four branches):
1. **Load**: `import L from "https://cdn.skypack.dev/leaflet@1.6.0"` at the top of the controller module (not importmap-pinned in this diff, just a bare CDN URL); Leaflet's CSS loaded via a `<link>` tag in the layout, separate from JS.
2. **Lifecycle — init**: `initialize()` (not `connect()`) creates the `L.Map` via `L.map(this.mapTarget)`, deliberately using the earlier-firing `initialize()` lifecycle callback rather than `connect()`.
3. **Server data in via Values**: two Stimulus Values (`tileLayer: Object`, `geoJsonLayer: Object`) carry server-rendered JSON — config YAML (`Rails.configuration.x.leaflet`, itself sourced from `config/leaflet.yml` via `config_for`) and ActiveRecord-derived GeoJSON (via jbuilder templates) — straight into the controller. Their `*ValueChanged` callbacks (`tileLayerValueChanged`, `geoJsonLayerValueChanged`) are where the actual `L.tileLayer(...)`/`L.geoJSON(...)` construction happens, decoupling "data arrived" from "DOM connected."
4. **Bridging server-rendered HTML into the library**: rather than let Leaflet synthesize marker HTML, Doyle renders marker HTML server-side into a hidden `<template data-leaflet-target="template">`, tags each marker with a `dom_id`-derived `id`, ships that `id` through the GeoJSON `properties.icon.id` field, then in the `pointToLayer` callback does `this.templateTarget.content.getElementById(id).cloneNode(true)` and hands the cloned HTML to `L.divIcon({ html, ...options })`. This is his answer to "how do I make a third-party map library render *my* HTML/SVG markers instead of its own."
5. **`data-turbo-permanent` + manual instance caching** for teardown/reuse across Turbo Drive navigations: because `data-turbo-permanent` prevents Turbo from destroying/rebuilding the element (and thus the Stimulus controller re-runs `initialize()` on every page swap), Doyle keys `WeakMap`s by the *DOM element itself* (`targetsToMaps`, `mapsToTileLayers`, `mapsToGeoJsonLayers`) so a persisted map element's Leaflet instance and its current layers survive navigation, and old layers are explicitly `.removeFrom(this.leaflet)`'d when replaced (with a `once("zoomend", ...)` deferred removal on GeoJSON layers so the fly-to-bounds animation doesn't jump).
6. **True `disconnect()` teardown** is present but narrow: only the `moveend` event listener is unbound (`this.leaflet.off("moveend", this.prepareSearch)`), not the whole map — because the map element persists across navigations by design, full map teardown never happens in this branch's flow.

**Does he pair a Stimulus controller with an ERB helper/partial wrapper?** Yes, explicitly — the `locations/_leaflet` partial *is* the wrapper: every page that wants a map (`index`, `show`) renders `partial: "locations/leaflet"` passing `locations:`, `geo_json_layer:`, and `tile_layer:` as locals, and the partial itself emits the single `<section data-controller="leaflet" data-leaflet-*-value="...">` root plus the `<template>`, map `<article>`, and search `<form>` the controller expects. Callers never touch `data-controller`/`data-*-value` attributes directly — they only supply Ruby data (an ActiveRecord relation/array and rendered JSON) and the partial handles all Stimulus wiring. This is the single clearest "partial as controller wrapper" pattern across all four branches examined.

---

### hotwire-example-grid

### hotwire-example-grid

**Technique**: A fully W3C ARIA Authoring Practices-compliant, keyboard-navigable data grid (`role="grid"`, roving `tabindex`, full arrow-key/Home/End/Ctrl+Home/Ctrl+End/PageUp/PageDown support) built from a single `grid_controller.js` Stimulus controller driving plain `<table>` markup, paired with a small "cell renderer" partial-dispatch convention (`_boolean`, `_integer`, `_string` application partials, selected by ActiveRecord column type).

**Problem it solves**: Make a large, paginated (`pagy`) HTML `<table>` of baseball player stats behave like a native spreadsheet/data-grid for keyboard users — one tab stop to enter the grid, arrow keys to move cell-to-cell, Home/End for row boundaries, Ctrl+Home/Ctrl+End for grid boundaries, PageUp/PageDown for author-determined row jumps — without JavaScript-rendering the grid (it's plain server-rendered `<table>`/`<tr>`/`<td>`).

**Commit dates**: 2022-02-14 .. 2022-04-08 (excludes the 2022-05-20 `[SKIP]` Replit commit). The dataset/scaffold commits (`[SKIP]: Establish the dataset`, `Our starting point`) land 2022-02-14; the keyboard-interaction work is almost entirely 2022-02-25 – 2022-02-28, with one bugfix on 2022-04-08.

**Needs JS?** Yes, exactly one Stimulus controller (`grid_controller.js`, 85 lines final) — no third-party grid library, no virtualization, no client-side rendering of rows/cells (all HTML is server-rendered by Rails/ERB; JS only manages `tabindex`/focus/`role` attributes and keyboard event handling).

**Key code**

```javascript
// app/javascript/controllers/grid_controller.js (final state)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "column", "row" ]
  static values = { column: Number, row: Number }

  connect() {
    this.element.setAttribute("role", "grid")
  }

  columnTargetConnected(target) {
    if (target.hasAttribute("tabindex")) return

    const row = this.rowTargets.findIndex(row => row.contains(target))
    const column = this.columnTargets.indexOf(target)
    const tabindex = row == this.rowValue && column == this.columnValue ?
       0 :
      -1

    target.setAttribute("tabindex", tabindex)
  }

  captureFocus({ target }) {
    const row = this.rowTargets.find(row => row.contains(target))
    const columnsInRow = this.columnTargets.filter(column => row.contains(column))

    this.rowValue = this.rowTargets.indexOf(row)
    this.columnValue = columnsInRow.indexOf(target)

    for (const column of this.columnTargets) {
      const tabindex = column == target ?
         0 :
        -1

      column.setAttribute("tabindex", tabindex)
    }
  }

  moveColumn({ key, ctrlKey, params: { directions, boundaries } }) {
    if (key in directions) {
      const row = this.rowTargets[this.rowValue]
      const columnsInRow = this.columnTargets.filter(column => row.contains(column))

      this.columnValue += directions[key]
      this.columnValue = Math.min(this.columnValue, columnsInRow.length - 1)
      this.columnValue = Math.max(0, this.columnValue)

      const nextColumn = columnsInRow[this.columnValue]

      if (nextColumn) nextColumn.focus()
    } else if (key in boundaries) {
      if (boundaries[key] < 1) {
        const row = ctrlKey ?
          this.rowTargets[0] :
          this.rowTargets[this.rowValue]
        const columnsInRow = this.columnTargets.filter(column => row.contains(column))
        const [ nextColumn ] = columnsInRow

        if (nextColumn) nextColumn.focus()
      } else {
        const row = ctrlKey ?
          this.rowTargets[this.rowTargets.length - 1] :
          this.rowTargets[this.rowValue]
        const columnsInRow = this.columnTargets.filter(column => row.contains(column))
        const nextColumn = columnsInRow[columnsInRow.length - 1]

        if (nextColumn) nextColumn.focus()
      }
    }
  }

  moveRow({ key, params: { directions } }) {
    if (key in directions) {
      this.rowValue += directions[key]
      this.rowValue = Math.min(this.rowValue, this.rowTargets.length - 1)
      this.rowValue = Math.max(0, this.rowValue)

      const row = this.rowTargets[this.rowValue]
      const columnsInRow = this.columnTargets.filter(column => row.contains(column))
      const nextColumn = columnsInRow[this.columnValue]

      if (nextColumn) nextColumn.focus()
    }
  }
}
```

```erb
<%# app/views/players/index.html.erb — final state %>
<section class="grid gap-4">
  <h1>Players</h1>

  <%= render partial: "page", object: @page %>

  <table data-controller="grid">
    <thead>
      <tr>
        <% Player.headings.each do |heading| %>
          <th>
            <%= Player.human_attribute_name heading.name %>
          </th>
        <% end %>
      </tr>
    </thead>

    <tbody>
      <% @players.each do |player| %>
        <tr data-grid-target="row" data-action="keydown->grid#moveRow"
            data-grid-directions-param="<%= html_escape({ ArrowDown: +1, ArrowUp: -1, PageDown: +10, PageUp: -10 }.to_json) %>">
          <% Player.headings.each do |heading| %>
            <td data-grid-target="column" data-action="focus->grid#captureFocus keydown->grid#moveColumn"
                data-grid-boundaries-param="<%= html_escape({ Home: 0, End: 1 }.to_json) %>"
                data-grid-directions-param="<%= html_escape({ ArrowRight: +1, ArrowLeft: -1 }.to_json) %>">
              <%= render partial: heading.type.to_s, object: player[heading.name] %>
            </td>
          <% end %>
        </tr>
      <% end %>
    </tbody>
  </table>

  <%= render partial: "page", object: @page %>
</section>
```

```erb
<%# app/views/application/_boolean.html.erb %>
<%= boolean ? "Yes" : "No" %>
```

```erb
<%# app/views/application/_integer.html.erb %>
<%= integer %>
```

```erb
<%# app/views/application/_string.html.erb %>
<%= string %>
```

```erb
<%# app/views/application/_page.html.erb %>
<nav class="flex justify-between">
  <% if page.prev %>
    <%= link_to pagy_url_for(page, page.prev), rel: "prev" do %>
      Previous page
    <% end %>
  <% end %>

  <% if page.next %>
    <%= link_to pagy_url_for(page, page.next), rel: "next" do %>
      Next page
    <% end %>
  <% end %>
</nav>
```

```ruby
# app/models/player.rb
class Player < ApplicationRecord
  def self.headings
    columns.reject { _1.name.in? %w[ id player_id created_at updated_at ] }
  end
end
```

```ruby
# app/controllers/players_controller.rb
class PlayersController < ApplicationController
  def index
    @page, @players = pagy Player.all
  end
end
```

```ruby
# config/initializers/pagy.rb
ActiveSupport.on_load :action_controller_base do
  include Pagy::Backend
end

ActiveSupport.on_load :action_view do
  include Pagy::UrlHelpers
end
```

```ruby
# app/models/team.rb
class Team < ApplicationRecord
  has_many :draftings
  has_many :players, through: :draftings

  accepts_nested_attributes_for :draftings
end
```

```ruby
# app/models/drafting.rb
class Drafting < ApplicationRecord
  belongs_to :player
  belongs_to :team
end
```

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :players, only: :index

  # Defines the root path route ("/")
  # root "articles#index"
  root to: redirect("/players")
end
```

```yaml
# config/locales/en.yml (relevant excerpt)
en:
  activerecord:
    attributes:
      player:
        player_id: Seamheads.com ID
        common_name: Name
        hof: Hall of Fame
        position: Batter or Pitcher
        position_cat: Position played
        player_label: Category
```

```ruby
# test/application_system_test_case.rb
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
end

Capybara.configure do |config|
  config.default_normalize_ws = true
end

Capybara.add_selector :cell do
  xpath do |locator|
    td = XPath.descendant(:td)

    locator.nil? ? td : td[XPath.n.string.is(locator)]
  end

  node_filter :column do |td, column|
    table = td.find :xpath, "./ancestor::table"
    row = td.find :xpath, "./ancestor::tr"
    index = row.all("td").map(&:path).index(td.path)

    table.has_selector?("th:nth-child(#{index + 1})", text: column) ||
      row.has_selector?("th[scope=row]", text: column)
  end
end
```

```ruby
# test/system/players_test.rb (full)
require "application_system_test_case"

class PlayersTest < ApplicationSystemTestCase
  test "only one of the focusable elements contained by the grid is included in the page tab sequence" do
    first_player = players.first

    visit players_path
    send_keys(:tab).then { assert_link "Next page", focused: true }
    send_keys(:tab).then { assert_cell first_player.common_name, focused: true, column: "Name" }
    send_keys(:tab).then { assert_link "Next page", focused: true }
    2.times { send_keys :shift, :tab }.then { assert_link "Next page", focused: true }
  end

  test "Right Arrow: Moves focus one cell to the right." do
    first_player = players.first

    visit players_path
    send_keys(:tab)
    send_keys(:tab).then { assert_cell first_player.common_name, focused: true, column: "Name" }
    send_keys(:right).then { assert_cell first_player.league, focused: true, column: "League" }
  end

  test "Right Arrow: If focus is in the last column of the grid, focus does not move." do
    first_player = players.first

    visit players_path
    2.times { send_keys :tab }.then { assert_cell focused: true, column: "Name" }
    send_keys([:control, :end]).then { assert_cell focused: true, column: "Batter or Pitcher" }
    5.times { send_keys :right }. then { assert_cell first_player.position, focused: true, column: "Batter or Pitcher"  }
    send_keys(:left). then { assert_cell first_player.position_cat, focused: true, column: "Position played"  }
  end

  test "Left Arrow: Moves focus one cell to the left." do
    first_player = players.first

    visit players_path
    send_keys(:tab)
    send_keys(:tab).then { assert_cell first_player.common_name, focused: true, column: "Name" }
    send_keys(:right)
    send_keys(:left).then { assert_cell first_player.common_name, focused: true, column: "Name" }
  end

  test "Left Arrow: If focus is in the first column of the grid, focus does not move." do
    first_player = players.first

    visit players_path
    2.times { send_keys :tab }.then { assert_cell focused: true, column: "Name" }
    5.times { send_keys :left }. then { assert_cell first_player.common_name, focused: true, column: "Name"  }
    send_keys(:right). then { assert_cell first_player.league, focused: true, column: "League"  }
  end

  test "Down Arrow: Moves focus one cell down." do
    first_player, second_player, * = players

    visit players_path
    2.times { send_keys :tab }.then { assert_cell first_player.common_name, focused: true, column: "Name" }
    send_keys(:down).then { assert_cell second_player.common_name, focused: true, column: "Name" }
  end

  test "Up Arrow: Moves focus one cell down." do
    first_player = players.first

    visit players_path
    2.times { send_keys :tab }.then { assert_cell first_player.common_name, focused: true, column: "Name" }
    send_keys(:down)
    send_keys(:up).then { assert_cell first_player.common_name, focused: true, column: "Name" }
  end

  test "Home: moves focus to the first cell in the row that contains focus." do
    first_player = players.first

    visit players_path
    send_keys(:tab)
    send_keys(:tab).then { assert_cell focused: true, column: "Name" }
    send_keys(:right).then { assert_cell focused: true, column: "League" }
    send_keys(:right).then { assert_cell focused: true, column: "Hall of Fame" }
    send_keys(:home).then { assert_cell first_player.common_name, focused: true, column: "Name" }
  end

  test "End: moves focus to the last cell in the row that contains focus." do
    first_player = players.first

    visit players_path
    send_keys(:tab)
    send_keys(:tab).then { assert_cell first_player.common_name, focused: true, column: "Name" }
    send_keys(:end).then { assert_cell first_player.position, focused: true, column: "Batter or Pitcher" }
  end

  test "Control + Home: moves focus to the first cell in the first row." do
    first_player, second_player, third_player = players.take(3)

    visit players_path
    2.times { send_keys :tab }.then { assert_cell focused: true, column: "Name" }
    send_keys(:down).then { assert_cell second_player.common_name, focused: true, column: "Name" }
    send_keys(:down).then { assert_cell third_player.common_name, focused: true, column: "Name" }
    send_keys(:end).then { assert_cell third_player.position, focused: true, column: "Batter or Pitcher" }
    send_keys([:control, :home]).then { assert_cell first_player.common_name, focused: true, column: "Name" }
  end

  test "Control + End: moves focus to the last cell in the last row." do
    last_player_on_page = players.take(Pagy::DEFAULT[:items]).last

    visit players_path
    2.times { send_keys :tab }.then { assert_cell focused: true, column: "Name" }
    send_keys([:control, :end]).then { assert_cell focused: true, column: "Batter or Pitcher" }
    send_keys(:home).then { assert_cell last_player_on_page.common_name, focused: true, column: "Name" }
  end

  test "Page Down: Moves focus down an author-determined number of rows" do
    eleventh_player = players.take(11).last

    visit players_path
    2.times { send_keys :tab }.then { assert_cell focused: true, column: "Name" }
    send_keys(:page_down).then { assert_cell eleventh_player.common_name, focused: true, column: "Name" }
  end

  test "Page Down: If focus is in the last row of the grid, focus does not move." do
    penultimate_player, ultimate_player = players.take(Pagy::DEFAULT[:items]).last(2)

    visit players_path
    2.times { send_keys :tab }.then { assert_cell focused: true, column: "Name" }
    5.times { send_keys :page_down }. then { assert_cell ultimate_player.common_name, focused: true, column: "Name"  }
    send_keys(:up). then { assert_cell penultimate_player.common_name, focused: true, column: "Name"  }
  end

  test "Page Up: Moves focus up an author-determined number of rows" do
    tenth_player = players.take(10).last
    ultimate_player = players.take(Pagy::DEFAULT[:items]).last

    visit players_path
    2.times { send_keys :tab }.then { assert_cell focused: true, column: "Name" }
    send_keys([:control, :end]).then { assert_cell ultimate_player.position, focused: true, column: "Batter or Pitcher" }
    send_keys(:home).then { assert_cell ultimate_player.common_name, focused: true, column: "Name" }
    send_keys(:page_up).then { assert_cell tenth_player.common_name, focused: true, column: "Name"  }
  end

  test "Page Up: If focus is in the first row of the grid, focus does not move." do
    first_player, second_player = players.take(2)

    visit players_path
    2.times { send_keys :tab }.then { assert_cell first_player.common_name, focused: true, column: "Name" }
    send_keys(:down).then { assert_cell second_player.common_name, focused: true, column: "Name" }
    5.times { send_keys :page_up }.then { assert_cell first_player.common_name, focused: true, column: "Name"  }
    send_keys(:down).then { assert_cell second_player.common_name, focused: true, column: "Name"  }
  end

  def assert_cell(...)
    assert_selector(:cell, ...)
  end
end
```

**Evolution worth noting**: the grid controller didn't start life as `grid_controller.js`. The first commit ("Add grid to page tab sequence") introduced a separate, generic `roving_tabstop_controller.js` (13 lines, just first-focusable-gets-`tabindex=0`) wired via `data-controller="roving-tabstop"` / `data-roving-tabstop-target="focusable"`. The very next commit ("Right Arrow...") deleted `roving_tabstop_controller.js` outright and replaced it with the more specific `grid_controller.js`, folding roving-tabindex logic directly into the grid controller. Doyle iterated the direction/boundary logic through several intermediate shapes (`directionsValue` as a Stimulus *Value* on the `<table>`, then moved to `directions`/`boundaries` as Stimulus *action params* on individual `<td>`/`<tr>` elements) before landing on the final `params: { directions, boundaries }` design shown above — each key press handler receives its allowed direction/boundary keymap as JSON declared inline in the HTML (`data-grid-directions-param`, `data-grid-boundaries-param`), rather than hardcoded in JS. This lets row-level (`ArrowDown`/`ArrowUp`/`PageDown`/`PageUp`) and column-level (`ArrowRight`/`ArrowLeft`, `Home`/`End`) keymaps differ per-axis while sharing one controller and one set of methods (`moveRow`, `moveColumn`).

**Doyle's stated tradeoffs**

> **Add grid to page tab sequence** — `[grid]` — https://www.w3.org/TR/wai-aria-practices/#grid

(Terse commit message, but it's the single explicit citation of the ARIA Authoring Practices Guide "Grid" pattern that the whole branch implements — every subsequent commit title is lifted almost verbatim from that spec's grid keyboard-interaction requirements: "Right Arrow: Moves focus one cell to the right", "Home: moves focus to the first cell in the row that contains focus", "Control + End: moves focus to the last cell in the last row", "Page Down: Moves focus down an author-determined number of rows", etc. — i.e., Doyle worked through the APG grid pattern's keyboard-interaction checklist commit-by-commit, each with its own dedicated system test.)

> **Fix: Left & Right surpassing first/last columns when pressed many times** — (commit body empty; the fix itself documents the bug: without clamping, holding/repeating Left or Right could push `this.columnValue` out of bounds — e.g. to `-3` — so a later Home/End or row-change computed from that stale, out-of-range value would misbehave. The fix clamps `columnValue` to `[0, columnsInRow.length - 1]` on every `moveColumn` call before deriving `nextColumn`.)

No broader "here's the tradeoff of this whole approach" essay exists (this branch has no branch-specific README, unlike `map`) — the tradeoffs are implicit in the commit sequence: build it incrementally, one keyboard interaction at a time, each backed by its own system test, rather than shipping the whole APG grid pattern in one commit.

**Accessibility notes (crown jewel — transcribed in full above)**:
- **`role="grid"`** is set imperatively in `connect()`: `this.element.setAttribute("role", "grid")` — applied to the `<table data-controller="grid">` element itself, not baked into the ERB markup, so the ARIA role is asserted at the moment Stimulus actually takes over interaction (progressive enhancement: a JS-disabled `<table>` renders as a plain data table, not a broken grid).
- **Roving tabindex** implemented via two Stimulus target-lifecycle callbacks: `columnTargetConnected(target)` sets the initial `tabindex` (0 for the cell matching `rowValue`/`columnValue`, else -1) as each `<td data-grid-target="column">` connects; `captureFocus({ target })` re-derives `rowValue`/`columnValue` whenever any cell receives native `focus`, then re-sweeps every column target's `tabindex` so exactly one cell in the whole grid is tab-reachable at a time (see the dedicated system test: `"only one of the focusable elements contained by the grid is included in the page tab sequence"`).
- **Arrow keys**: `moveColumn` handles `ArrowLeft`/`ArrowRight` (clamped to the current row's column bounds) and `moveRow` handles `ArrowUp`/`ArrowDown` (clamped to `[0, rowTargets.length - 1]`), both keyed off per-element `data-grid-directions-param` JSON maps rather than hardcoded key names.
- **Home/End**: handled inside `moveColumn`'s `boundaries` branch — `data-grid-boundaries-param="<%= html_escape({ Home: 0, End: 1 }.to_json) %>"` — jumps to the first/last column in the *current* row.
- **Ctrl+Home/Ctrl+End**: same `boundaries` branch, but checks `ctrlKey` to decide whether to jump within the current row or to the grid's first/last row (`this.rowTargets[0]` vs `this.rowTargets[this.rowTargets.length - 1]`) before picking first/last column of that row.
- **PageUp/PageDown**: handled in `moveRow` via `data-grid-directions-param="<%= html_escape({ ArrowDown: +1, ArrowUp: -1, PageDown: +10, PageUp: -10 }.to_json) %>"` on the `<tr>` — an "author-determined number of rows" (10, per the ARIA APG spec's own wording, echoed in the commit titles) rather than a full page/viewport calculation.
- **Testing approach**: a custom Capybara selector (`Capybara.add_selector :cell`) resolves `<td>` elements by their column header text via `th:nth-child(n)` lookup, used throughout `players_test.rb` as `assert_cell text, focused: true, column: "Name"` — a reusable, semantic way to assert grid focus state instead of brittle CSS selectors.

**`_boolean` / `_integer` / `_string` / `_page` application partials — cell-rendering abstraction**: `Player.headings` (`app/models/player.rb`) returns the ActiveRecord `column` objects for the model (excluding `id`/`player_id`/`created_at`/`updated_at`). In the view, each `<td>` renders `render partial: heading.type.to_s, object: player[heading.name]` — i.e., **the ActiveRecord column's SQL type name (`"boolean"`, `"integer"`, `"string"`) is used directly as the partial name**, and Rails' partial-rendering convention (`render partial: "boolean", object: value` looks for a local variable named `boolean`) means each partial's sole line just formats that one local: `_boolean.html.erb` renders `Yes`/`No`, `_integer.html.erb` and `_string.html.erb` just echo the value. This is a minimal but real "cell renderer registry" — extending the grid with a new formatted column type (e.g. dates, currency) is just adding a same-named partial in `app/views/application/`, no changes to the grid view or controller. `_page.html.erb` is unrelated to cell rendering — it's the `pagy`-powered prev/next pagination nav, reused above and below the table via `render partial: "page", object: @page`.

**Currency check**: Commits span 2022-02-14 to 2022-04-08, roughly two years before Turbo 8 (Feb 2024). This branch doesn't use Turbo Frames/Streams at all — it's pure Stimulus + server-rendered HTML + `pagy` pagination — so there's nothing Turbo-8-deprecated to flag. Stimulus API usage (`static targets`, `static values`, target-connected lifecycle callbacks, action params via `data-*-param`) is all still current in modern Stimulus. No third-party CDN dependencies in this branch at all (unlike chat/map/ag-grid) — everything is Rails + vanilla Stimulus, which also means nothing here is at risk of going stale from an external CDN.

**Third-party JS integration pattern**: N/A — this branch deliberately does not wrap a third-party grid library; it builds an ARIA grid pattern from scratch with plain `<table>` markup and Stimulus. Contrast directly with `hotwire-example-ag-grid`, which wraps the real AG Grid library — this branch is effectively "the hand-rolled alternative" to that approach, and comparing them side-by-side is likely valuable for the eventual report.

**Does he pair a Stimulus controller with an ERB helper/partial wrapper?** No dedicated wrapper partial for the grid itself (unlike `map`'s `_leaflet.html.erb`) — `data-controller="grid"` and all the `data-grid-*-param` attributes are written directly inline in `players/index.html.erb`. However, the *cell-content* rendering is delegated to the small `_boolean`/`_integer`/`_string` partial-per-type convention described above, which is its own (different kind of) view-layer abstraction paired with the grid.

---

### hotwire-example-ag-grid

### hotwire-example-ag-grid

**Technique**: A single Stimulus controller wraps the real [AG Grid](https://www.ag-grid.com/) Enterprise JS library, feeding it row data through a `<meta>` element whose `[content]` attribute holds JSON, and integrating AG Grid's server-side row model with Rails by routing AG Grid's internal pagination callback through a `<turbo-frame>` fetch — i.e., using `<turbo-frame>` as the "declarative fetch" layer instead of `window.fetch` inside the controller.

**Problem it solves**: Drive a full-featured third-party data-grid widget (AG Grid, with built-in virtualization/sorting/pagination) from server-rendered Rails data, for both a client-side-paginated dataset (everything loaded up front) and a server-side-paginated dataset (AG Grid requests more rows on demand), while keeping URL construction, HTTP fetching, and "is this response ready" state in Turbo/HTML rather than hand-rolled `fetch()` calls inside the Stimulus controller.

**Commit dates**: 2022-05-24 — single squashed/rebased commit ("Hotwire Example AG Grid"). Per the task brief's general note, branches like this are built via interactive rebase and don't preserve a real day-by-day history; the whole example lands as one commit.

**Needs JS?** Yes, and unlike `grid`, this branch necessarily depends on a full third-party library: AG Grid Enterprise, loaded via a plain `<script>` tag (`https://unpkg.com/ag-grid-enterprise@27.3.0/dist/ag-grid-enterprise.min.js`) in the layout — not an ES module import, not importmap-pinned; it registers a global `agGrid` that the controller reads directly (`new agGrid.Grid(...)`). The controller itself is compact (41 lines).

**Key code**

```javascript
// app/javascript/controllers/grid_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "datasource", "table" ]
  static values = { options: Object }

  connect() {
    this.grid = new agGrid.Grid(this.tableTarget, this.optionsValue)
    this.grid.gridOptions.api.setServerSideDatasource({
      getRows: params => {
        const event = new CustomEvent("grid:pagination", { detail: { params }, bubbles: true })

        this.datasourceTarget.dispatchEvent(event)
      }
    })
  }

  disconnect() {
    this.grid.destroy()
  }

  async loadRows({ currentTarget, detail: { params } }) {
    if (currentTarget.src) {
      const { startRow, endRow } = params.request
      const url = new URL(currentTarget.src, currentTarget.baseURI)
      url.searchParams.set("startRow", startRow)
      url.searchParams.set("endRow", endRow)

      currentTarget.src = url
    }

    try {
      await currentTarget.loaded

      const rows = JSON.parse(this.datasourceTarget.content)
      params.success(rows)
    } catch {
      params.fail()
    }
  }
}
```

```erb
<%# app/views/grids/show.html.erb — full file %>
<h1 class="text-lg">Server-side pagination</h1>

<%
    if params[:load].nil?
      # the grid is initially rendered empty, but ready to fetch data
      src = grid_path(load: true)
      rows = []
    else
      # the grid renders the data set that as part of a remote fetch
      min, max = params.values_at :startRow, :endRow
      min = min || 0
      max = max || 100
      min, max = [min, max].map(&:to_i).minmax

      src = nil
      rows = min...max
    end
%>

<%= tag.div class: "h-[40vh]", data: {
      controller: "grid",
      grid_options_value: {
        columnDefs: [
          { field: "a" },
          { field: "b" },
          { field: "c" },
        ],
        pagination: true,
        rowModelType: "serverSide",
        serverSideStoreType: "partial",
      },
    } do %>
  <%= turbo_frame_tag "grid-datasource", src: src,
                      data: { action: "grid:pagination->grid#loadRows" } do %>
    <%= tag.meta data: { grid_target: "datasource" },
                 content: {
                   rowData: rows.map { |index| { a: index, b: index, c: index } },
                   rowCount: 1_000,
                 }.to_json %>
  <% end %>

  <div class="h-full ag-theme-alpine"
       data-grid-target="table"></div>
<% end %>

<h1 class="text-lg">Client-side pagination</h1>

<%
    # the grid is pre-rendered with data
    rows = 0...1_000
%>

<%= tag.div class: "h-[40vh]", data: {
      controller: "grid",
      grid_options_value: {
        columnDefs: [
          { field: "d" },
          { field: "e" },
          { field: "f" },
        ],
        pagination: true,
        rowModelType: "serverSide",
      },
    } do %>
  <%= turbo_frame_tag "grid-datasource",
                      data: { action: "grid:pagination->grid#loadRows" } do %>
    <%= tag.meta data: { grid_target: "datasource" },
                 content: {
                   rowData: rows.map { |index| { d: index, e: index, f: index } },
                   rowCount: 1_000,
                 }.to_json %>
  <% end %>

  <div class="h-full ag-theme-alpine"
       data-grid-target="table"></div>
<% end %>
```

```ruby
# app/controllers/grids_controller.rb
class GridsController < ApplicationController
end
```

```ruby
# config/routes.rb (relevant lines)
resource :grid, only: :show

root to: redirect("/grid")
```

```erb
<%# app/views/layouts/application.html.erb (relevant line) %>
<script src="https://unpkg.com/ag-grid-enterprise@27.3.0/dist/ag-grid-enterprise.min.js"></script>
```

Also deleted in this commit: `app/javascript/controllers/hello_controller.js` (the default `rails new`/importmap-generated scaffold Stimulus controller), replaced entirely by `grid_controller.js`.

**Doyle's stated tradeoffs**

The commit message is effectively a full README essay (it becomes the branch's README). Key excerpts, verbatim:

> This repository is an experiment to investigate what it'd be like to drive an [AG Grid][] instance with a Stimulus controller and a `<turbo-frame>`.
>
> There are several facets of the experiment of note:
>
> * The row data is serialized to a [`<meta>` element][meta] that encodes the payload into its `[content]` attribute as JSON
> * Both client-side and server-side datasets are loaded with the same `<turbo-frame>` and `<meta>` pair mechanism
> * The `grid` Stimulus controller integrates with the server-side datasource pagination interface by dispatching a custom `grid:pagination` event, which the view-layer routes to the `grid#loadRows` Stimulus action by declaring a `[data-action]` attribute on the `<turbo-frame>`
> * The pagination event listener only encodes a limited set of data retrieval query parameters (the `startRow` and `endRow` values), but could be extended to incorporate more contextual values (like sort order or filter model)

> Navigation and links from elsewhere in the application would drive traffic to the page _without_ the `load` parameter. Once the page is loaded, the `<turbo-frame>` will lazily-load the data by visiting _the same route_ with the `?load=true` query parameter.

> **Why explore alternatives to our current implementation?**
>
> Stimulus Action routing idioms tend to push event listener attachment logic out of controller code and into the HTML layer. Similarly, `<turbo-frame>` elements are a declarative alternative to imperative `fetch` code.
>
> In that same vein, any behavior that constructs URLs in JavaScript code has a potential to be better served by Rails code and its access to routing helpers.
>
> By pushing client-side event routing, configuration, data, and HTTP interoperability into server-generated HTML, we limit our controller's burden of responsibility.

> **What might this unlock?**
>
> Some potential follow-up changes might include:
>
> * Refreshing the dataset with an `<a>` click or `<form>` submission that targets the `<turbo-frame>` through a `[data-turbo-frame="grid-datasource"]`
> * Deferring data retrieval for grids that are below the fold with [`<turbo-frame loading="lazy">`][loading-lazy]
> * Declaring event listeners for `turbo:frame-load` elsewhere in the document
> * Deep linking to pages and filtered datasets by encoding `?startRow=200&endRow=300` into the URL as query parameters

This is explicitly framed by Doyle as "an experiment" — the README title of this whole branch, and the "Why explore alternatives" section, signal he considers this a design-space exploration rather than a settled recommendation. The core tradeoff he's naming: pushing URL-construction and fetch-triggering logic *out* of the Stimulus controller (where `loadRows` would otherwise need to build a URL and call `fetch` imperatively) and *into* declarative HTML (`turbo_frame_tag src:`, `data-action="grid:pagination->grid#loadRows"`) — the controller's `loadRows` method still mutates `currentTarget.src` to trigger the frame's own fetch, and `await`s `currentTarget.loaded` (a Turbo Frame element property) rather than awaiting a raw `fetch()` promise.

**Accessibility notes**: None specific to this branch — AG Grid Enterprise's own internal accessibility behavior (or lack thereof) is opaque/out-of-scope since it's a third-party library instance; Doyle's code contributes no ARIA attributes, labels, or keyboard-interaction logic here. Directly contrast with the `grid` branch, which hand-builds full ARIA APG grid semantics.

**Currency check**: 2022-05-24, about 21 months before Turbo 8 (Feb 2024). `<turbo-frame>` `src`/`loaded`/lazy-loading APIs used here are still current in Turbo 8. `ag-grid-enterprise@27.3.0` is a pinned CDN version from 2022 — AG Grid has moved through major versions since (v27 → v3x as of 2026), so the specific `rowModelType`/`serverSideStoreType` config shape used here (`serverSideStoreType: "partial"`) may not match current AG Grid Enterprise APIs; worth flagging as likely stale if someone wants to actually run this against a current AG Grid release. The unpkg `<script src>` (non-module, global `agGrid`) approach is also dated relative to modern AG Grid's own recommended ESM/npm installation.

**Third-party JS integration pattern** (priority — second clear example alongside `map`):
1. **Load**: plain `<script src="https://unpkg.com/ag-grid-enterprise@27.3.0/dist/ag-grid-enterprise.min.js">` in the layout — a classic global-script tag, not an importmap pin and not an ES module; the controller consumes the resulting global `agGrid` object directly (no `import` statement for AG Grid at all in `grid_controller.js`).
2. **Lifecycle — init**: `connect() { this.grid = new agGrid.Grid(this.tableTarget, this.optionsValue) }` — instantiates AG Grid against a plain empty `<div data-grid-target="table">`, using Stimulus's `connect()` (not `initialize()`, unlike the `map` branch) since there's no cross-navigation persistence concern here.
3. **Lifecycle — teardown**: explicit `disconnect() { this.grid.destroy() }` — a full, simple teardown (contrast with `map`'s partial teardown, which only unbound one event listener because the map element was intentionally kept alive via `data-turbo-permanent`). Here the grid element is not `data-turbo-permanent`, so it's fully destroyed and recreated on every Turbo Drive navigation.
4. **Passing server data in via `values`+DOM, not Stimulus Values for the row data itself**: configuration (`columnDefs`, `pagination`, `rowModelType`, etc.) comes in through a genuine Stimulus Value (`static values = { options: Object }`, populated by `grid_options_value: {...}.to_json`-via-ERB-hash on the `<div data-controller="grid">`). But the *row data* itself is deliberately routed through a sibling `<meta data-grid-target="datasource" content="...">` element instead of a Stimulus Value — because it needs to be independently swappable by a `<turbo-frame>` re-fetch without re-triggering the whole controller's `connect()`/Value-changed lifecycle. This is a meaningful and non-obvious pattern: **Stimulus Values for config that doesn't change without a full reconnect; a plain DOM `<meta>` element (a `turbo-frame`-managed target) for data that needs to be replaced independently.**
5. **Bridging the library's own async pagination callback into a Turbo Frame fetch**: AG Grid's server-side row model expects a synchronous-looking `getRows({ request, success, fail })` datasource callback. Doyle's `connect()` wires that callback to dispatch a bubbling `CustomEvent("grid:pagination", { detail: { params }, bubbles: true })` on the `datasourceTarget` (the `<meta>` element, which lives *inside* the `<turbo-frame>`), and the frame's own `data-action="grid:pagination->grid#loadRows"` attribute routes that custom event to the `loadRows` Stimulus action — which then mutates `currentTarget.src` (the frame's `src`, with `startRow`/`endRow` query params merged in) to trigger the frame's native fetch, `await`s the frame's `.loaded` promise, then reads the *replaced* `<meta>` element's new `content` JSON and calls AG Grid's own `params.success(rows)`/`params.fail()` to close the loop back into the library's expected async contract.
6. No `data-turbo-permanent` used here (unlike `map`) — this is the "just destroy and rebuild on every navigation" strategy, appropriate since there's no expensive animated state (like map center/zoom) worth preserving.

**Does he pair a Stimulus controller with an ERB helper/partial wrapper?** No — everything (both the server-side-paginated grid and the client-side-paginated grid) is written directly inline in `grids/show.html.erb` as two near-duplicate blocks of `tag.div`/`turbo_frame_tag`/`tag.meta` ERB, with no extraction into a shared partial or helper despite the obvious duplication between the "Server-side pagination" and "Client-side pagination" sections. This is the one branch of the four where Doyle does *not* reach for a wrapper partial, even though the `map` branch's `_leaflet.html.erb` shows he's clearly comfortable with that pattern elsewhere — likely because this branch is explicitly framed as a rough "experiment," not a polished technique to imitate structurally.


---

## Upstream design rationale

Sourced from his GitHub activity. Inventory: **233** items on `hotwired/turbo` (228 PRs, 5 issues),
**58** on `hotwired/turbo-rails`, **12** on `hotwired/stimulus`, **8** on `hotwired/stimulus-rails`,
and **243** on `rails/rails` (149 merged; ~128 in Action View / Action Text / forms / tag-builder).
Nothing on `turbo-ios` / `turbo-android`.


Research compiled 2026-08-15 from the GitHub REST API (`gh api search/issues`, `gh api repos/.../issues/N/comments`, `.../pulls/N/comments`). All quotes are verbatim transcriptions of his own words.

### Inventory

Counts of authored PRs + issues (GitHub search, all states):

| Repo | PRs | Issues | Total |
|------|-----|--------|-------|
| hotwired/turbo | 228 | 5 | 233 |
| hotwired/turbo-rails | 58 | 0 | 58 |
| hotwired/stimulus | 12 | 0 | 12 |
| hotwired/stimulus-rails | 8 | 0 | 8 |
| hotwired/turbo-ios | 0 | 0 | 0 |
| hotwired/turbo-android | 0 | 0 | 0 |
| rails/rails | 237 | 6 | 243 (≈128 in Action View / Action Text / forms / tag-builder territory) |

He has authored **nothing** in `hotwired/turbo-ios` or `hotwired/turbo-android`. His Hotwire footprint is essentially `hotwired/turbo` (by a wide margin), then `turbo-rails`, with a small but pointed set of Stimulus proposals. In `rails/rails` his surface is Action View form/tag helpers, Action Text/Trix, and the ARIA-aware tag builder work — which is the same design thread as his Turbo accessibility work.

### hotwired/turbo (233)

| # | Kind | Title | State | Date | URL |
|---|------|-------|-------|------|-----|
| 1495 | PR | Same-page anchor: Account for `<a>` nested in `<svg>` | open | 2026-02-02 | https://github.com/hotwired/turbo/pull/1495 |
| 1474 | PR | Tests: Flaky `[autofocus]` assertions | closed | 2025-11-21 | https://github.com/hotwired/turbo/pull/1474 |
| 1473 | PR | Remove `chai`: Replace all calls with Playwright's `expect` | closed | 2025-11-20 | https://github.com/hotwired/turbo/pull/1473 |
| 1471 | PR | Remove deprecated `Turbo.clearCache()` function | closed | 2025-11-18 | https://github.com/hotwired/turbo/pull/1471 |
| 1470 | PR | Remove deprecated support for `[data-turbo-cache="false"]` | closed | 2025-11-18 | https://github.com/hotwired/turbo/pull/1470 |
| 1469 | PR | `PrefetchCache`: extract and re-use `LRUCache` from `SnapshotCache` | closed | 2025-11-17 | https://github.com/hotwired/turbo/pull/1469 |
| 1467 | PR | Playwright Root: use `expect` instead of `assert` | closed | 2025-11-14 | https://github.com/hotwired/turbo/pull/1467 |
| 1466 | PR | Loading Functional Tests: Replace `assert` with `expect` | closed | 2025-11-11 | https://github.com/hotwired/turbo/pull/1466 |
| 1465 | PR | Playwright: replace `assert` with `expect` | closed | 2025-11-11 | https://github.com/hotwired/turbo/pull/1465 |
| 1463 | PR | Visit Functional Tests: Replace chai with Playwright | closed | 2025-11-09 | https://github.com/hotwired/turbo/pull/1463 |
| 1461 | PR | Frame Functional Tests: Replace chai with Playwright | closed | 2025-11-07 | https://github.com/hotwired/turbo/pull/1461 |
| 1459 | PR | Rendering Functional Tests: Replace chai with Playwright | closed | 2025-11-06 | https://github.com/hotwired/turbo/pull/1459 |
| 1458 | PR | Functional Tests: Rendering - Replace `chai` with Playwright | closed | 2025-11-06 | https://github.com/hotwired/turbo/pull/1458 |
| 1454 | PR | Functional Tests: Replace chai with Playwright Assertions | closed | 2025-11-02 | https://github.com/hotwired/turbo/pull/1454 |
| 1453 | PR | Build: Remove circular dependency | closed | 2025-11-02 | https://github.com/hotwired/turbo/pull/1453 |
| 1438 | PR | Consolidate morphing functions into `core/morphing` | open | 2025-09-21 | https://github.com/hotwired/turbo/pull/1438 |
| 1319 | PR | Expose morphing functions for consumer use | closed | 2024-09-24 | https://github.com/hotwired/turbo/pull/1319 |
| 1306 | PR | Delegate `Turbo.session` properties to `Turbo.config` | closed | 2024-08-28 | https://github.com/hotwired/turbo/pull/1306 |
| 1287 | PR | Re-connect Stream Source when attribute change | open | 2024-07-24 | https://github.com/hotwired/turbo/pull/1287 |
| 1240 | PR | Re-structure `turbo-stream[action=morph]` support | closed | 2024-04-04 | https://github.com/hotwired/turbo/pull/1240 |
| 1235 | PR | Ignore links and forms that target `"_blank"` | closed | 2024-03-31 | https://github.com/hotwired/turbo/pull/1235 |
| 1234 | PR | Extract and re-use element morphing logic | closed | 2024-03-30 | https://github.com/hotwired/turbo/pull/1234 |
| 1231 | PR | Resolve Turbo Frame navigation bug | closed | 2024-03-27 | https://github.com/hotwired/turbo/pull/1231 |
| 1219 | PR | Use Playwright assertions for autofocus | closed | 2024-03-03 | https://github.com/hotwired/turbo/pull/1219 |
| 1217 | PR | Introduce `Turbo.config` object | closed | 2024-03-03 | https://github.com/hotwired/turbo/pull/1217 |
| 1216 | PR | Configure Submitter disabling | closed | 2024-03-02 | https://github.com/hotwired/turbo/pull/1216 |
| 1213 | PR | Prevent Refresh from interrupting ongoing Visit | closed | 2024-03-01 | https://github.com/hotwired/turbo/pull/1213 |
| 1208 | PR | Add `[method]` and `[scroll]` attributes for Refresh Stream | closed | 2024-02-28 | https://github.com/hotwired/turbo/pull/1208 |
| 1206 | PR | Implement `Preloader` with Mutation Observer | open | 2024-02-24 | https://github.com/hotwired/turbo/pull/1206 |
| 1205 | PR | Add `turbo:before-prefetch` test coverage | closed | 2024-02-24 | https://github.com/hotwired/turbo/pull/1205 |
| 1198 | PR | Fix Turbo Frame prefetching bug | open | 2024-02-21 | https://github.com/hotwired/turbo/pull/1198 |
| 1195 | PR | Omit `ignoreActiveValue: true` Morph option | closed | 2024-02-21 | https://github.com/hotwired/turbo/pull/1195 |
| 1193 | PR | Update JSDoc for `StreamElement` | closed | 2024-02-20 | https://github.com/hotwired/turbo/pull/1193 |
| 1148 | PR | `LinkPrefetchObserver`: replace `dataset` with `getAttribute` | closed | 2024-01-31 | https://github.com/hotwired/turbo/pull/1148 |
| 1147 | PR | `LinkPrefetchObserver`: listen for complementary events | closed | 2024-01-31 | https://github.com/hotwired/turbo/pull/1147 |
| 1141 | PR | Morph with `ignoreActiveValue: true` | closed | 2024-01-25 | https://github.com/hotwired/turbo/pull/1141 |
| 1136 | PR | Introduce `FrameElement.getElementById(id: string)` | open | 2024-01-22 | https://github.com/hotwired/turbo/pull/1136 |
| 1135 | PR | Drive `turbo-frame` with `Turbo.visit(url, { frame:, action: })` | closed | 2024-01-22 | https://github.com/hotwired/turbo/pull/1135 |
| 1129 | PR | Render `<turbo-stream-source>` as `display: none` | open | 2024-01-13 | https://github.com/hotwired/turbo/pull/1129 |
| 1097 | PR | Introduce `turbo:{before-,}morph-{element,attribute}` events | closed | 2023-12-03 | https://github.com/hotwired/turbo/pull/1097 |
| 1094 | PR | Import `session` instead of reading `window.Turbo.session` | closed | 2023-12-01 | https://github.com/hotwired/turbo/pull/1094 |
| 1078 | PR | Restructure to avoid internal `window.Turbo` access | closed | 2023-11-27 | https://github.com/hotwired/turbo/pull/1078 |
| 1077 | PR | Avoid infinite recursion from `window.fetch` name collision | closed | 2023-11-27 | https://github.com/hotwired/turbo/pull/1077 |
| 1064 | PR | Add coverage for focus and value preservation during morph | closed | 2023-11-14 | https://github.com/hotwired/turbo/pull/1064 |
| 1052 | PR | Tests: remove `"test"` docstring prefix | closed | 2023-10-29 | https://github.com/hotwired/turbo/pull/1052 |
| 1049 | PR | Remove Circular Build Dependency | closed | 2023-10-27 | https://github.com/hotwired/turbo/pull/1049 |
| 1040 | PR | Add control to preserve scroll during Drive visits | open | 2023-10-17 | https://github.com/hotwired/turbo/pull/1040 |
| 1039 | PR | `await` for `FetchRequest` delegate to handle response | open | 2023-10-13 | https://github.com/hotwired/turbo/pull/1039 |
| 1038 | PR | Add test coverage for submitting `form[data-turbo-frame="_top"]` | closed | 2023-10-12 | https://github.com/hotwired/turbo/pull/1038 |
| 1037 | PR | Handle `<turbo-stream>` name collisions with `<form>` controls | open | 2023-10-12 | https://github.com/hotwired/turbo/pull/1037 |
| 1036 | PR | Hide Progress bar on `turbo:load` | closed | 2023-10-12 | https://github.com/hotwired/turbo/pull/1036 |
| 1035 | PR | Set `html[lang]` during navigation | closed | 2023-10-12 | https://github.com/hotwired/turbo/pull/1035 |
| 1034 | PR | Dispatch `turbo:before-fetch-{request,response}` during preloading | closed | 2023-10-12 | https://github.com/hotwired/turbo/pull/1034 |
| 1033 | PR | Guard `[data-turbo-preload]` with conditionals | closed | 2023-10-12 | https://github.com/hotwired/turbo/pull/1033 |
| 1031 | PR | Integrate `[data-turbo-temporary]` with `pagehide` event | open | 2023-10-11 | https://github.com/hotwired/turbo/pull/1031 |
| 1029 | PR | Extract `Morph` class, then use it in `FrameRenderer` | closed | 2023-10-09 | https://github.com/hotwired/turbo/pull/1029 |
| 1028 | PR | Infer `renderElement` during `Renderer` construction | closed | 2023-10-09 | https://github.com/hotwired/turbo/pull/1028 |
| 1027 | PR | Make `Renderer` instance available to `View` delegates | open | 2023-10-09 | https://github.com/hotwired/turbo/pull/1027 |
| 1026 | PR | Delegate `StreamActions.refresh` to `Session` | closed | 2023-10-08 | https://github.com/hotwired/turbo/pull/1026 |
| 1025 | PR | Replace global fetch patch with Turbo-specific behavior  | closed | 2023-10-08 | https://github.com/hotwired/turbo/pull/1025 |
| 1024 | PR | Move `Cache` instantiation to `Session` | closed | 2023-10-08 | https://github.com/hotwired/turbo/pull/1024 |
| 1023 | PR | Add test coverage for `StreamActions` export | closed | 2023-10-08 | https://github.com/hotwired/turbo/pull/1023 |
| 1004 | PR | Support `FrameElement.reload()` without an initial `[src]` attribute | open | 2023-09-14 | https://github.com/hotwired/turbo/pull/1004 |
| 1000 | PR | [Deprecation]: Remove internal objects from public API | open | 2023-09-12 | https://github.com/hotwired/turbo/pull/1000 |
| 997 | Issue | Generate `hotwired/turbo-site` content from `hotwired/turbo` source | open | 2023-09-10 | https://github.com/hotwired/turbo/issues/997 |
| 970 | PR | Close `StreamSource` when `<turbo-stream-source>` disconnects | closed | 2023-09-05 | https://github.com/hotwired/turbo/pull/970 |
| 955 | PR | Add test coverage toggling `[aria-busy]` for `GET` Form Submissions | closed | 2023-07-29 | https://github.com/hotwired/turbo/pull/955 |
| 909 | PR | Remove `SubmitEvent` polyfill | closed | 2023-04-18 | https://github.com/hotwired/turbo/pull/909 |
| 908 | PR | Remove `requestSubmit` polyfill | closed | 2023-04-18 | https://github.com/hotwired/turbo/pull/908 |
| 887 | PR | Create Frame Snapshot from Fetch Response HTML | closed | 2023-03-02 | https://github.com/hotwired/turbo/pull/887 |
| 885 | PR | Extract `HTMLFormSubmission` tuple | open | 2023-03-02 | https://github.com/hotwired/turbo/pull/885 |
| 838 | PR | Fix failing Firefox test | closed | 2022-12-31 | https://github.com/hotwired/turbo/pull/838 |
| 835 | PR | Close Issue #834 | closed | 2022-12-30 | https://github.com/hotwired/turbo/pull/835 |
| 833 | PR | Tests: Resolve flaky rendering test | closed | 2022-12-29 | https://github.com/hotwired/turbo/pull/833 |
| 822 | PR | Update `@playwright/test` dependency | closed | 2022-12-15 | https://github.com/hotwired/turbo/pull/822 |
| 821 | PR | `[data-turbo-method="get"]` links: search params | closed | 2022-12-15 | https://github.com/hotwired/turbo/pull/821 |
| 814 | PR | Correct `Render<E>` method signature argument order | closed | 2022-12-08 | https://github.com/hotwired/turbo/pull/814 |
| 805 | PR | Wrap `noNext`-prefixed test helpers in assertions | closed | 2022-11-25 | https://github.com/hotwired/turbo/pull/805 |
| 804 | PR | Skip Snapshot Caching for redirect visits | closed | 2022-11-25 | https://github.com/hotwired/turbo/pull/804 |
| 799 | PR | Re-use getVisitAction utility function | closed | 2022-11-20 | https://github.com/hotwired/turbo/pull/799 |
| 798 | PR | Simplify `FetchRequestDelegate.prepareHeadersForRequest` | closed | 2022-11-20 | https://github.com/hotwired/turbo/pull/798 |
| 790 | PR | Fix: Promoting lazy-loaded Frames | closed | 2022-11-06 | https://github.com/hotwired/turbo/pull/790 |
| 765 | PR | Redirect to Location with a URL hash | open | 2022-10-13 | https://github.com/hotwired/turbo/pull/765 |
| 763 | PR | Update history during same-page Visits | closed | 2022-10-13 | https://github.com/hotwired/turbo/pull/763 |
| 749 | PR | Resolve Issue #747 | closed | 2022-09-30 | https://github.com/hotwired/turbo/pull/749 |
| 744 | PR | Ignore UJS `<a>` clicks and `<form>` submissions | closed | 2022-09-28 | https://github.com/hotwired/turbo/pull/744 |
| 741 | PR | Scope `willRender` to `PageRenderer` only | open | 2022-09-27 | https://github.com/hotwired/turbo/pull/741 |
| 740 | PR | Fix double `before-fetch-request` dispatch during reload | closed | 2022-09-27 | https://github.com/hotwired/turbo/pull/740 |
| 730 | PR | Configure Playwright to retry failed tests | closed | 2022-09-21 | https://github.com/hotwired/turbo/pull/730 |
| 729 | PR | Fix: Dispatch `turbo:click` when driving a Frame | closed | 2022-09-21 | https://github.com/hotwired/turbo/pull/729 |
| 728 | PR | Don't toggle `turbo-frame[busy]` when navigating `_top` | closed | 2022-09-20 | https://github.com/hotwired/turbo/pull/728 |
| 725 | PR | CI: Restore passing tests | closed | 2022-09-19 | https://github.com/hotwired/turbo/pull/725 |
| 717 | PR | Address CI Test Flakiness | closed | 2022-09-14 | https://github.com/hotwired/turbo/pull/717 |
| 715 | PR | Revert "allow customizing the element that Drive replaces (#627)" | closed | 2022-09-14 | https://github.com/hotwired/turbo/pull/715 |
| 711 | PR | Re-introduce #627 | open | 2022-09-13 | https://github.com/hotwired/turbo/pull/711 |
| 702 | PR | Dispatch `turbo:frame-render` when Frame connects | open | 2022-08-30 | https://github.com/hotwired/turbo/pull/702 |
| 694 | PR | Encode Visit Action into `Turbo-Action:` header | open | 2022-08-19 | https://github.com/hotwired/turbo/pull/694 |
| 693 | PR | `turbo:frame-missing`: Dispatch for 4xx and 5xx | closed | 2022-08-19 | https://github.com/hotwired/turbo/pull/693 |
| 691 | PR | Override `FetchOptions` from event listeners | closed | 2022-08-17 | https://github.com/hotwired/turbo/pull/691 |
| 690 | PR | Opt-into Turbo Stream `GET` from Form submitter | closed | 2022-08-17 | https://github.com/hotwired/turbo/pull/690 |
| 688 | PR | Turbo Streams: Preserve permanent elements | closed | 2022-08-17 | https://github.com/hotwired/turbo/pull/688 |
| 686 | PR | Turbo Streams: Manage element focus | closed | 2022-08-16 | https://github.com/hotwired/turbo/pull/686 |
| 685 | PR | Dispatch `turbo:fetch-request-error` during Visits | closed | 2022-08-16 | https://github.com/hotwired/turbo/pull/685 |
| 684 | PR | Add `render` to `turbo:before-stream-render` event | closed | 2022-08-13 | https://github.com/hotwired/turbo/pull/684 |
| 678 | PR | Form Link Submissions: Don't remove `<form>` until submission is complete | closed | 2022-08-10 | https://github.com/hotwired/turbo/pull/678 |
| 677 | PR | `turbo:frame-missing`: Do not `Turbo.visit` by default | closed | 2022-08-10 | https://github.com/hotwired/turbo/pull/677 |
| 676 | PR | Add `submitter` to `Turbo.setConfirmMethod` callback | closed | 2022-08-10 | https://github.com/hotwired/turbo/pull/676 |
| 674 | PR | Bugfix: Redirects and `[data-turbo-cache=false]` | closed | 2022-08-09 | https://github.com/hotwired/turbo/pull/674 |
| 672 | PR | `turbo:frame-missing`: Re-use `FetchResponse` HTML | closed | 2022-08-08 | https://github.com/hotwired/turbo/pull/672 |
| 669 | PR | PageSnapshot: reduce cloning loop iterations | closed | 2022-08-05 | https://github.com/hotwired/turbo/pull/669 |
| 667 | PR | Fix Markdown Syntax typo in CONTRIBUTING.md | closed | 2022-08-04 | https://github.com/hotwired/turbo/pull/667 |
| 666 | PR | Preserve input values in cache | closed | 2022-08-04 | https://github.com/hotwired/turbo/pull/666 |
| 665 | PR | Make `StreamElement.templateElement` more flexible | closed | 2022-08-04 | https://github.com/hotwired/turbo/pull/665 |
| 662 | PR | Dispatch `turbo:before-stream-render` with reference to `<turbo-stream>` | closed | 2022-08-01 | https://github.com/hotwired/turbo/pull/662 |
| 661 | PR | Return `Promise<void>` from `FrameElement.reload` | closed | 2022-08-01 | https://github.com/hotwired/turbo/pull/661 |
| 660 | PR | Activate `<script>` in Turbo Streams | closed | 2022-07-31 | https://github.com/hotwired/turbo/pull/660 |
| 658 | PR | Expand `Turbo.setFormMode` guards | closed | 2022-07-30 | https://github.com/hotwired/turbo/pull/658 |
| 657 | PR | Extract `DriveDelegate` interface | open | 2022-07-30 | https://github.com/hotwired/turbo/pull/657 |
| 655 | PR | Bugfix: Form Mode opt-in should consider outside submitters | closed | 2022-07-29 | https://github.com/hotwired/turbo/pull/655 |
| 654 | PR | Do not autofocus inert or hidden elements | closed | 2022-07-29 | https://github.com/hotwired/turbo/pull/654 |
| 653 | PR | Encode Form Submitter `[name]` into submission | closed | 2022-07-28 | https://github.com/hotwired/turbo/pull/653 |
| 650 | PR | Return `Promise<void>` from `Turbo.visit` | closed | 2022-07-27 | https://github.com/hotwired/turbo/pull/650 |
| 649 | PR | `Turbo.visit(..., { frame: "frame" })` | closed | 2022-07-27 | https://github.com/hotwired/turbo/pull/649 |
| 645 | PR | Prevent form links from submitting multiple requests | closed | 2022-07-21 | https://github.com/hotwired/turbo/pull/645 |
| 644 | PR | Resolve Frame Visit caching issue | closed | 2022-07-20 | https://github.com/hotwired/turbo/pull/644 |
| 635 | PR | Add tests for pausable Frame Rendering | closed | 2022-07-18 | https://github.com/hotwired/turbo/pull/635 |
| 633 | PR | [Flaky Tests]: Link Form Submission | closed | 2022-07-18 | https://github.com/hotwired/turbo/pull/633 |
| 631 | PR | Introduce `FormLinkInterceptor` | closed | 2022-07-16 | https://github.com/hotwired/turbo/pull/631 |
| 630 | PR | Treat `[data-turbo-stream]` as boolean attribute | closed | 2022-07-16 | https://github.com/hotwired/turbo/pull/630 |
| 626 | PR | Lazy load Frame styled with `display: contents` | open | 2022-07-13 | https://github.com/hotwired/turbo/pull/626 |
| 625 | Issue | Frame with `[loading="lazy"]` cannot load when styled with `display: contents` | open | 2022-07-13 | https://github.com/hotwired/turbo/issues/625 |
| 623 | Issue | Turbo Stream operations ignore `[data-turbo-permanent]` | closed | 2022-07-06 | https://github.com/hotwired/turbo/issues/623 |
| 622 | PR | Introduce `turbo:before-permanent-element-render` | open | 2022-07-06 | https://github.com/hotwired/turbo/pull/622 |
| 609 | PR | Drive Browser tests with `playwright` | closed | 2022-06-23 | https://github.com/hotwired/turbo/pull/609 |
| 606 | PR | Support development ChromeDriver version overrides | closed | 2022-06-20 | https://github.com/hotwired/turbo/pull/606 |
| 576 | PR | CI: Synchronize `VisitTests` test case | closed | 2022-05-03 | https://github.com/hotwired/turbo/pull/576 |
| 575 | PR | Generated: execute `yarn lint --fix` | closed | 2022-05-02 | https://github.com/hotwired/turbo/pull/575 |
| 535 | PR | Resolve progress bar test suite failure | closed | 2022-02-13 | https://github.com/hotwired/turbo/pull/535 |
| 534 | PR | Use `replaceChildren` in StreamActions.update | closed | 2022-02-13 | https://github.com/hotwired/turbo/pull/534 |
| 529 | PR | Treat blank `[formaction]` like a blank `[action]` | closed | 2022-02-08 | https://github.com/hotwired/turbo/pull/529 |
| 488 | PR | Frame Visits: Cache Snapshot later in process | closed | 2021-12-01 | https://github.com/hotwired/turbo/pull/488 |
| 487 | PR | Expose Frame load state via `[complete]` attribute | closed | 2021-12-01 | https://github.com/hotwired/turbo/pull/487 |
| 479 | PR | Custom Actions: Export `StreamActions` module | closed | 2021-11-26 | https://github.com/hotwired/turbo/pull/479 |
| 476 | PR | Perform scrolling prior to Visit completion | closed | 2021-11-25 | https://github.com/hotwired/turbo/pull/476 |
| 466 | PR | Restore searchParams to Visit and Frame Navigation | closed | 2021-11-23 | https://github.com/hotwired/turbo/pull/466 |
| 464 | PR | `GET` Submissions: Do not merge into `[action]` | closed | 2021-11-22 | https://github.com/hotwired/turbo/pull/464 |
| 461 | PR | `GET` Submissions: don't merge into `searchParams` | closed | 2021-11-22 | https://github.com/hotwired/turbo/pull/461 |
| 459 | PR | Frames: Ignore already cancelled `submit` events | closed | 2021-11-20 | https://github.com/hotwired/turbo/pull/459 |
| 455 | PR | Add test coverage for event listener leaking | closed | 2021-11-18 | https://github.com/hotwired/turbo/pull/455 |
| 454 | PR | Disconnect loaded Frame Element while rendering | closed | 2021-11-18 | https://github.com/hotwired/turbo/pull/454 |
| 452 | PR | Export Type declarations for `turbo:` events | closed | 2021-11-18 | https://github.com/hotwired/turbo/pull/452 |
| 449 | PR | Frames: handle `GET` form submissions | closed | 2021-11-16 | https://github.com/hotwired/turbo/pull/449 |
| 448 | PR | Preserve page state while promoting Frame-to-Visit | closed | 2021-11-16 | https://github.com/hotwired/turbo/pull/448 |
| 445 | PR | Introduce `turbo:frame-missing` event | closed | 2021-11-14 | https://github.com/hotwired/turbo/pull/445 |
| 444 | PR | Resolve Frame-to-Page Visit event ordering | closed | 2021-11-13 | https://github.com/hotwired/turbo/pull/444 |
| 443 | PR | Pass CI on `main` branch | closed | 2021-11-12 | https://github.com/hotwired/turbo/pull/443 |
| 442 | PR | Contain `[aria-busy]` toggling within Frames | closed | 2021-11-12 | https://github.com/hotwired/turbo/pull/442 |
| 441 | PR | Integrate Frame-to-Page Visits with Snapshot Cache | closed | 2021-11-12 | https://github.com/hotwired/turbo/pull/441 |
| 437 | PR | Ignore external `<form>` submissions | closed | 2021-11-06 | https://github.com/hotwired/turbo/pull/437 |
| 436 | PR | Restore focus when transposing Permanent Elements | closed | 2021-11-06 | https://github.com/hotwired/turbo/pull/436 |
| 431 | PR | Support custom rendering in `turbo:before{-frame,}-render` events | closed | 2021-10-31 | https://github.com/hotwired/turbo/pull/431 |
| 430 | PR | Extract `FrameVisit` to drive `FrameController` | open | 2021-10-27 | https://github.com/hotwired/turbo/pull/430 |
| 425 | PR | Fire `turbo:frame-load` event during form submission | closed | 2021-10-18 | https://github.com/hotwired/turbo/pull/425 |
| 424 | PR | `GET` Forms: fire `submit-start` and `submit-end` | closed | 2021-10-14 | https://github.com/hotwired/turbo/pull/424 |
| 421 | PR | Fire `turbo:click` event when submitting `<form method="get">` | closed | 2021-10-12 | https://github.com/hotwired/turbo/pull/421 |
| 418 | PR | Frames: Abort prior requests during navigation | closed | 2021-10-04 | https://github.com/hotwired/turbo/pull/418 |
| 415 | PR | Turbo stream source | closed | 2021-10-03 | https://github.com/hotwired/turbo/pull/415 |
| 412 | PR | Replace LinkInterceptor with LinkClickObserver | closed | 2021-09-30 | https://github.com/hotwired/turbo/pull/412 |
| 409 | PR | Read `[data-turbo-action]` during Form Submissions | closed | 2021-09-27 | https://github.com/hotwired/turbo/pull/409 |
| 402 | PR | Expand the FrameElementDelegate interface | closed | 2021-09-21 | https://github.com/hotwired/turbo/pull/402 |
| 398 | PR | Push history state from frame navigations | closed | 2021-09-17 | https://github.com/hotwired/turbo/pull/398 |
| 397 | PR | Override Frame response target from server | closed | 2021-09-17 | https://github.com/hotwired/turbo/pull/397 |
| 389 | PR | Ensure Turbo does not interfere with IFrames | closed | 2021-09-10 | https://github.com/hotwired/turbo/pull/389 |
| 388 | PR | Skip form{,method}="dialog" when targetting frame | closed | 2021-09-10 | https://github.com/hotwired/turbo/pull/388 |
| 386 | PR | Toggle [disabled] on form submitter | closed | 2021-09-10 | https://github.com/hotwired/turbo/pull/386 |
| 383 | PR | Support navigating a Frame to its current `src` | closed | 2021-09-07 | https://github.com/hotwired/turbo/pull/383 |
| 382 | PR | Replace FormInterceptor with FormSubmitObserver | closed | 2021-09-07 | https://github.com/hotwired/turbo/pull/382 |
| 381 | PR | Read `data-turbo-frame` target from Submitter | closed | 2021-09-07 | https://github.com/hotwired/turbo/pull/381 |
| 255 | PR | Support Custom `<turbo-stream action="...">` value | closed | 2021-04-22 | https://github.com/hotwired/turbo/pull/255 |
| 248 | PR | Support navigating a Frame to its current `src` | closed | 2021-04-15 | https://github.com/hotwired/turbo/pull/248 |
| 236 | PR | Revert "Revert "Add test coverage for toggling data-turbo-preview"" | closed | 2021-04-10 | https://github.com/hotwired/turbo/pull/236 |
| 235 | PR | Navigation: Scroll to select assertion | closed | 2021-04-09 | https://github.com/hotwired/turbo/pull/235 |
| 232 | PR | Replace FormInterceptor with FormSubmitObserver | closed | 2021-04-07 | https://github.com/hotwired/turbo/pull/232 |
| 231 | PR | Support `data-turbo-action="..."` on Form Submits | closed | 2021-04-05 | https://github.com/hotwired/turbo/pull/231 |
| 228 | PR | Skip form[data-turbo="false"] submissions in frame | closed | 2021-04-02 | https://github.com/hotwired/turbo/pull/228 |
| 224 | PR | Frames: Set `src` when a `<form>` redirects frame | closed | 2021-03-29 | https://github.com/hotwired/turbo/pull/224 |
| 222 | PR | Preserve playback state in permanent HTMLMediaElements | closed | 2021-03-28 | https://github.com/hotwired/turbo/pull/222 |
| 220 | PR | Forms: Log Submission failures to the console | closed | 2021-03-27 | https://github.com/hotwired/turbo/pull/220 |
| 212 | PR | Navigate a lazy-loaded turbo-frame | closed | 2021-03-16 | https://github.com/hotwired/turbo/pull/212 |
| 210 | PR | Render 4xx responses within frame | open | 2021-03-14 | https://github.com/hotwired/turbo/pull/210 |
| 199 | PR | Toggle `[aria-busy="true"]` during requests | closed | 2021-03-06 | https://github.com/hotwired/turbo/pull/199 |
| 191 | PR | Prevent Streams from {pre,app}ending duplicates | closed | 2021-02-28 | https://github.com/hotwired/turbo/pull/191 |
| 184 | PR | Don't duplicate Form Submitter [name] param | closed | 2021-02-21 | https://github.com/hotwired/turbo/pull/184 |
| 181 | PR | Observe changes to turbo-frame[disabled] | closed | 2021-02-16 | https://github.com/hotwired/turbo/pull/181 |
| 169 | PR | Focus [autofocus] on navigation and frame load  | closed | 2021-02-08 | https://github.com/hotwired/turbo/pull/169 |
| 168 | PR | Stream Response Codes | closed | 2021-02-08 | https://github.com/hotwired/turbo/pull/168 |
| 166 | PR | Prepare Frame Form Submission fetch headers | closed | 2021-02-07 | https://github.com/hotwired/turbo/pull/166 |
| 165 | PR | Prevent infinite looping when loading frames | closed | 2021-02-07 | https://github.com/hotwired/turbo/pull/165 |
| 164 | PR | Render progress bar during form submissions | closed | 2021-02-07 | https://github.com/hotwired/turbo/pull/164 |
| 162 | PR | Add test coverage for toggling data-turbo-preview | closed | 2021-02-06 | https://github.com/hotwired/turbo/pull/162 |
| 161 | PR | Toggle [disabled] on form submitter | closed | 2021-02-06 | https://github.com/hotwired/turbo/pull/161 |
| 158 | PR | Support verb overrides through _method | closed | 2021-02-04 | https://github.com/hotwired/turbo/pull/158 |
| 157 | PR | Toggle [aria-busy] instead of [busy] | closed | 2021-02-04 | https://github.com/hotwired/turbo/pull/157 |
| 156 | PR | turbo-frame[busy] attribute | closed | 2021-02-04 | https://github.com/hotwired/turbo/pull/156 |
| 146 | PR | Expand rendering capabilities of `<turbo-frame>` | closed | 2021-01-31 | https://github.com/hotwired/turbo/pull/146 |
| 142 | PR | Restore correct Accept header for form submissions | closed | 2021-01-29 | https://github.com/hotwired/turbo/pull/142 |
| 128 | PR | Form Encoding | closed | 2021-01-22 | https://github.com/hotwired/turbo/pull/128 |
| 127 | PR | Transform GET submissions into Visits | closed | 2021-01-22 | https://github.com/hotwired/turbo/pull/127 |
| 116 | PR | Read frame target from turbo-frame[target] | closed | 2021-01-17 | https://github.com/hotwired/turbo/pull/116 |
| 108 | PR | GET form submissions to the current path | closed | 2021-01-15 | https://github.com/hotwired/turbo/pull/108 |
| 90 | PR | Replace `Location` class with browser-provided URL | closed | 2021-01-08 | https://github.com/hotwired/turbo/pull/90 |
| 87 | PR | Move `[data-turbo="false"]` guard up to observers | closed | 2021-01-07 | https://github.com/hotwired/turbo/pull/87 |
| 79 | PR | Scroll to top after rejected form submission | closed | 2021-01-05 | https://github.com/hotwired/turbo/pull/79 |
| 75 | PR | Read form method as attribute instead of property | closed | 2021-01-04 | https://github.com/hotwired/turbo/pull/75 |
| 71 | PR | Persist data-turbo-permanent element within frames | closed | 2021-01-04 | https://github.com/hotwired/turbo/pull/71 |
| 68 | Issue | Document and add test coverage for turbo-frame[recurse] | closed | 2021-01-03 | https://github.com/hotwired/turbo/issues/68 |
| 67 | PR | Add test coverage for turbo-frame[disabled] | closed | 2021-01-03 | https://github.com/hotwired/turbo/pull/67 |
| 66 | PR | Ensure Turbo does not interfere with IFrames | closed | 2021-01-03 | https://github.com/hotwired/turbo/pull/66 |
| 59 | PR | Dispatch `turbo:frame-load` on turbo-frame | closed | 2020-12-30 | https://github.com/hotwired/turbo/pull/59 |
| 57 | PR | Skip links: focus and scroll restoration | closed | 2020-12-29 | https://github.com/hotwired/turbo/pull/57 |
| 54 | Issue | Could turbo-frame elements dispatch turbo events during their navigation lifecycle? | closed | 2020-12-29 | https://github.com/hotwired/turbo/issues/54 |
| 53 | PR | Support Lazy-loading `<turbo-frame>` contents | closed | 2020-12-29 | https://github.com/hotwired/turbo/pull/53 |
| 52 | PR | Restrict Accept: turbo-stream to Form Submissions | closed | 2020-12-29 | https://github.com/hotwired/turbo/pull/52 |
| 49 | PR | Modify SubmitEvent polyfill to read `type` property | closed | 2020-12-28 | https://github.com/hotwired/turbo/pull/49 |
| 40 | PR | Unobtrusive JavaScript polyfill | closed | 2020-12-26 | https://github.com/hotwired/turbo/pull/40 |
| 39 | PR | Render 400-500 status response HTML | closed | 2020-12-26 | https://github.com/hotwired/turbo/pull/39 |
| 16 | PR | Add Functional tests for Submitter attributes | closed | 2020-12-21 | https://github.com/hotwired/turbo/pull/16 |
| 6 | PR | Proposal: <turbo-frame> elements progressively enhance target attribute | closed | 2020-12-14 | https://github.com/hotwired/turbo/pull/6 |
| 5 | PR | Read turbo-frame target from Submitter | closed | 2020-12-14 | https://github.com/hotwired/turbo/pull/5 |
| 4 | PR | turbo-frame: Navigate frame when intercepting GET | closed | 2020-12-14 | https://github.com/hotwired/turbo/pull/4 |
| 3 | PR | Enable opting-out of form submissions | closed | 2020-12-14 | https://github.com/hotwired/turbo/pull/3 |
| 2 | PR | Change [data-turbo] guard to [data-turbo-drive] | closed | 2020-12-14 | https://github.com/hotwired/turbo/pull/2 |
| 1 | PR | Read FormSubmission.{method,location} from submitter | closed | 2020-12-14 | https://github.com/hotwired/turbo/pull/1 |

### hotwired/turbo-rails (58)

| # | Kind | Title | State | Date | URL |
|---|------|-------|-------|------|-----|
| 774 | PR | Restrict tests to `minitest < 6` | closed | 2025-12-24 | https://github.com/hotwired/turbo-rails/pull/774 |
| 764 | PR | Fix CI for `ruby@3.2.x`-`rails@7.2.x` | closed | 2025-11-21 | https://github.com/hotwired/turbo-rails/pull/764 |
| 758 | PR | Add `rails@8.1` to the CI matrix | closed | 2025-11-02 | https://github.com/hotwired/turbo-rails/pull/758 |
| 701 | PR | `turbo_stream` tag builder: support `:partial` with block | closed | 2024-12-05 | https://github.com/hotwired/turbo-rails/pull/701 |
| 698 | PR | Drop Support for `ruby@2.x.x` | closed | 2024-10-30 | https://github.com/hotwired/turbo-rails/pull/698 |
| 697 | PR | Include CSRF `<meta>` elements in frame layout | closed | 2024-10-29 | https://github.com/hotwired/turbo-rails/pull/697 |
| 690 | PR | Add `capture_turbo_stream_broadcast` test helper | closed | 2024-10-03 | https://github.com/hotwired/turbo-rails/pull/690 |
| 688 | PR | Add hooks to integrate with Action Text | closed | 2024-09-30 | https://github.com/hotwired/turbo-rails/pull/688 |
| 682 | PR | Commit to `ruby@2.6` support | closed | 2024-09-18 | https://github.com/hotwired/turbo-rails/pull/682 |
| 680 | PR | Ensure `turbo-stream[action="remove"]` does not render a view partial by default | closed | 2024-09-18 | https://github.com/hotwired/turbo-rails/pull/680 |
| 650 | PR | Alter Action Cable Element to be morph-compatible | closed | 2024-07-23 | https://github.com/hotwired/turbo-rails/pull/650 |
| 616 | PR | Improve rendering outside request | closed | 2024-04-15 | https://github.com/hotwired/turbo-rails/pull/616 |
| 615 | PR | Flatten and compact `*streamables` arguments | closed | 2024-04-12 | https://github.com/hotwired/turbo-rails/pull/615 |
| 603 | PR | Only pass `:request_id` option to Refresh Stream | closed | 2024-03-14 | https://github.com/hotwired/turbo-rails/pull/603 |
| 595 | PR | Add `turbo_stream.refresh` builder method | closed | 2024-03-03 | https://github.com/hotwired/turbo-rails/pull/595 |
| 593 | PR | Create executable bug report Rails application | closed | 2024-02-23 | https://github.com/hotwired/turbo-rails/pull/593 |
| 577 | PR | Introduce `Turbo::SystemTestHelper` | closed | 2024-02-11 | https://github.com/hotwired/turbo-rails/pull/577 |
| 574 | PR | Only include `Turbo::Broadcastable::TestHelper`  with Action Cable | closed | 2024-02-09 | https://github.com/hotwired/turbo-rails/pull/574 |
| 569 | PR | Stream Tag Builder: Support `:renderable` arguments | closed | 2024-02-08 | https://github.com/hotwired/turbo-rails/pull/569 |
| 557 | PR | Render `<turbo-cable-stream-source>` as `display: none` | open | 2024-01-13 | https://github.com/hotwired/turbo-rails/pull/557 |
| 555 | PR | Document how to extend `turbo_stream` for custom actions | closed | 2024-01-11 | https://github.com/hotwired/turbo-rails/pull/555 |
| 550 | PR | Update Turbo Drive `<meta>` across navigations | open | 2024-01-03 | https://github.com/hotwired/turbo-rails/pull/550 |
| 538 | PR | Fix System Tests in CI environment | closed | 2023-12-07 | https://github.com/hotwired/turbo-rails/pull/538 |
| 534 | PR | Render full documents for requests with `Turbo-Frame:` header | open | 2023-12-01 | https://github.com/hotwired/turbo-rails/pull/534 |
| 514 | PR | Tests: rely on load hooks instead of class constants | closed | 2023-11-11 | https://github.com/hotwired/turbo-rails/pull/514 |
| 505 | PR | Restore `turbo_frame_tag` support for Array arguments | closed | 2023-10-16 | https://github.com/hotwired/turbo-rails/pull/505 |
| 490 | PR | Mention RubyDoc page in README | closed | 2023-08-18 | https://github.com/hotwired/turbo-rails/pull/490 |
| 466 | PR | Introduce `Turbo::Broadcastable::TestHelper` | closed | 2023-05-13 | https://github.com/hotwired/turbo-rails/pull/466 |
| 462 | PR | Document the `assert_turbo_stream` helpers | closed | 2023-05-06 | https://github.com/hotwired/turbo-rails/pull/462 |
| 448 | PR | Support `target:` as Array argument | closed | 2023-03-28 | https://github.com/hotwired/turbo-rails/pull/448 |
| 422 | PR | Install `cuprite` | closed | 2023-01-29 | https://github.com/hotwired/turbo-rails/pull/422 |
| 421 | PR | Force CI execution to be sequential | closed | 2023-01-29 | https://github.com/hotwired/turbo-rails/pull/421 |
| 419 | PR | Expose `Turbo::Native::Navigation#turbo_native_app?` helper method | closed | 2023-01-26 | https://github.com/hotwired/turbo-rails/pull/419 |
| 413 | PR | Parallelize test suite | closed | 2022-12-24 | https://github.com/hotwired/turbo-rails/pull/413 |
| 403 | PR | Add Type Safety Guards to `turbo/fetch_requests` | closed | 2022-11-18 | https://github.com/hotwired/turbo-rails/pull/403 |
| 370 | PR | Encode HTTP method into Request body as `_method` | closed | 2022-08-11 | https://github.com/hotwired/turbo-rails/pull/370 |
| 367 | PR | "Break out" of a frame from the server | open | 2022-07-31 | https://github.com/hotwired/turbo-rails/pull/367 |
| 337 | PR | Replace `?` operator with conditional check | closed | 2022-05-23 | https://github.com/hotwired/turbo-rails/pull/337 |
| 328 | PR | Make `turbo_test.rb` consistent with Rails' generated `test_helper.rb` | closed | 2022-05-03 | https://github.com/hotwired/turbo-rails/pull/328 |
| 327 | PR | Improve upon test suite flakiness | closed | 2022-05-03 | https://github.com/hotwired/turbo-rails/pull/327 |
| 279 | PR | Update generated `turbo.min.js.map` | closed | 2021-12-05 | https://github.com/hotwired/turbo-rails/pull/279 |
| 257 | PR | Build-in integration with rails/ujs | closed | 2021-10-12 | https://github.com/hotwired/turbo-rails/pull/257 |
| 255 | PR | Execute CI against `rails/rails` main | closed | 2021-10-09 | https://github.com/hotwired/turbo-rails/pull/255 |
| 250 | PR | Extend ActionDispatch::Request | closed | 2021-09-25 | https://github.com/hotwired/turbo-rails/pull/250 |
| 248 | PR | Promote Dummy app's `Message` to Active Record | closed | 2021-09-23 | https://github.com/hotwired/turbo-rails/pull/248 |
| 247 | PR | Add guard to fail CI on uncommitted changes | closed | 2021-09-23 | https://github.com/hotwired/turbo-rails/pull/247 |
| 239 | PR | Support `[formmethod]` overrides to `_method` | closed | 2021-09-17 | https://github.com/hotwired/turbo-rails/pull/239 |
| 238 | PR | Make `bin/rails` executable | closed | 2021-09-17 | https://github.com/hotwired/turbo-rails/pull/238 |
| 237 | PR | Update generated build assets | closed | 2021-09-17 | https://github.com/hotwired/turbo-rails/pull/237 |
| 232 | PR | Include layout for `Turbo-Frame:` requests | closed | 2021-09-10 | https://github.com/hotwired/turbo-rails/pull/232 |
| 231 | PR | Dummy app: Depend on `turbo-rails` through importmap | closed | 2021-09-10 | https://github.com/hotwired/turbo-rails/pull/231 |
| 230 | PR | Include `#` prefix in `[targets]` | closed | 2021-09-10 | https://github.com/hotwired/turbo-rails/pull/230 |
| 116 | PR | Extend Assertions to handle Status Codes | closed | 2021-02-08 | https://github.com/hotwired/turbo-rails/pull/116 |
| 108 | PR | Add System Test coverage for broadcasting | closed | 2021-02-01 | https://github.com/hotwired/turbo-rails/pull/108 |
| 93 | PR | Support for Unobtrusive JavaScript | closed | 2021-01-25 | https://github.com/hotwired/turbo-rails/pull/93 |
| 53 | PR | Mixin ActionView::RecordIdentifier#dom_id | closed | 2020-12-29 | https://github.com/hotwired/turbo-rails/pull/53 |
| 45 | PR | Document `turbo_stream.erb` templates | closed | 2020-12-27 | https://github.com/hotwired/turbo-rails/pull/45 |
| 35 | PR | Make turbo_frame_tag accept model argument | closed | 2020-12-25 | https://github.com/hotwired/turbo-rails/pull/35 |

### hotwired/stimulus (12)

| # | Kind | Title | State | Date | URL |
|---|------|-------|-------|------|-----|
| 627 | PR | Aria Elements: Support for `aria-` prefixed Element reference attributes | open | 2022-12-17 | https://github.com/hotwired/stimulus/pull/627 |
| 624 | PR | Outlets: Add observers for controller element attributes | closed | 2022-12-11 | https://github.com/hotwired/stimulus/pull/624 |
| 621 | PR | Action Descriptor Syntax: Support Outlet listeners | open | 2022-12-07 | https://github.com/hotwired/stimulus/pull/621 |
| 567 | PR | Support custom Action Options | closed | 2022-07-28 | https://github.com/hotwired/stimulus/pull/567 |
| 499 | PR | Fire Value Change Callbacks consistently | closed | 2021-12-17 | https://github.com/hotwired/stimulus/pull/499 |
| 473 | PR | Docs: Fix Lifecycle Callback order | closed | 2021-10-11 | https://github.com/hotwired/stimulus/pull/473 |
| 460 | PR | Add element and target attribute change callbacks | closed | 2021-09-29 | https://github.com/hotwired/stimulus/pull/460 |
| 459 | PR | Prevent infinite looping in target callbacks | closed | 2021-09-28 | https://github.com/hotwired/stimulus/pull/459 |
| 397 | PR | Proposal: Mutation Observation Syntax | closed | 2021-04-27 | https://github.com/hotwired/stimulus/pull/397 |
| 367 | PR | Fire callbacks when targets are added or removed | closed | 2021-01-20 | https://github.com/hotwired/stimulus/pull/367 |
| 340 | PR | Account for HTML escaped ActionDescriptor Syntax | closed | 2020-11-25 | https://github.com/hotwired/stimulus/pull/340 |
| 237 | PR | @stimulus/polyfills: Polyfill `Reflect.construct` | closed | 2019-04-01 | https://github.com/hotwired/stimulus/pull/237 |

### hotwired/stimulus-rails (8)

| # | Kind | Title | State | Date | URL |
|---|------|-------|-------|------|-----|
| 58 | PR | Update mimemagic | closed | 2021-04-09 | https://github.com/hotwired/stimulus-rails/pull/58 |
| 57 | PR | Make autoloading changes visible to the DOM | closed | 2021-04-09 | https://github.com/hotwired/stimulus-rails/pull/57 |
| 49 | PR | Standard Library of ARIA controllers | closed | 2021-02-19 | https://github.com/hotwired/stimulus-rails/pull/49 |
| 30 | PR | Attach MutationObserver to `document` | closed | 2021-01-20 | https://github.com/hotwired/stimulus-rails/pull/30 |
| 28 | PR | Improve Autoloader | closed | 2021-01-20 | https://github.com/hotwired/stimulus-rails/pull/28 |
| 25 | PR | Run full suite in CI | closed | 2021-01-19 | https://github.com/hotwired/stimulus-rails/pull/25 |
| 11 | PR | Make Autoloading more robust | closed | 2020-12-28 | https://github.com/hotwired/stimulus-rails/pull/11 |
| 10 | PR | Update README example to use Stimulus 2 attributes | closed | 2020-12-27 | https://github.com/hotwired/stimulus-rails/pull/10 |

### rails/rails — Action View / Action Text / forms / tag-builder subset (filtered from 243 total)

| # | Kind | Title | State | Date | URL |
|---|------|-------|-------|------|-----|
| 58118 | PR | Action Controller: Fix bug to support `render(renderable: …) { … }` | open | 2026-07-14 | https://github.com/rails/rails/pull/58118 |
| 57374 | PR | Revert "Add default `#render_in` implementation to `ActiveModel::Conversion`" | closed | 2026-05-15 | https://github.com/rails/rails/pull/57374 |
| 57349 | PR | Add default `#render_in` implementation to `ActiveModel::Conversion` | closed | 2026-05-12 | https://github.com/rails/rails/pull/57349 |
| 55885 | PR | De-couple `@rails/actiontext/attachment_upload.js` from `Trix.Attachment` | closed | 2025-10-10 | https://github.com/rails/rails/pull/55885 |
| 55827 | PR | Action Text: change tag helpers to accept optional blocks | closed | 2025-10-03 | https://github.com/rails/rails/pull/55827 |
| 55666 | PR | Generalize `:rich_text_area` Capybara selector | closed | 2025-09-12 | https://github.com/rails/rails/pull/55666 |
| 55410 | PR | Introduce `ActionView::Helper::NavigationHelper` | closed | 2025-07-26 | https://github.com/rails/rails/pull/55410 |
| 55404 | PR | FormTagHelper: replace `#safe_concat` with `#content_tag` | closed | 2025-07-25 | https://github.com/rails/rails/pull/55404 |
| 54289 | PR | Doc: Format CSRF argument lists [ci skip] | closed | 2025-01-18 | https://github.com/rails/rails/pull/54289 |
| 53847 | PR | Change `ActionText::RichText#embeds` assignment to `before_validation` | closed | 2024-12-05 | https://github.com/rails/rails/pull/53847 |
| 53831 | PR | Document Action Text File Upload purging [ci skip] | closed | 2024-12-04 | https://github.com/rails/rails/pull/53831 |
| 53812 | PR | Action Text: Dispatch Active Storage events with `id` and `file` | closed | 2024-12-03 | https://github.com/rails/rails/pull/53812 |
| 53686 | PR | Forward `fill_in_rich_text_area` options to Capybara | closed | 2024-11-20 | https://github.com/rails/rails/pull/53686 |
| 53131 | PR | Make `ActionController::AllowBrowser::BrowserBlocker` private | closed | 2024-10-01 | https://github.com/rails/rails/pull/53131 |
| 53098 | PR | Rename authentication generator template files | closed | 2024-09-29 | https://github.com/rails/rails/pull/53098 |
| 53071 | PR | Refactor `ActionCable::TestHelper` block-wise assertions | open | 2024-09-27 | https://github.com/rails/rails/pull/53071 |
| 52494 | PR | Add `ActiveModel::Serializers::JSON.key_format` | open | 2024-08-02 | https://github.com/rails/rails/pull/52494 |
| 52467 | PR | Rename `text_area` to `textarea` and `rich_text_area` to `rich_textarea` | closed | 2024-07-31 | https://github.com/rails/rails/pull/52467 |
| 51598 | PR | Action View Caching code sample syntax [ci skip] | closed | 2024-04-18 | https://github.com/rails/rails/pull/51598 |
| 51296 | PR | `ActiveRecord::Migration.verbose` documentation [ci skip] | closed | 2024-03-11 | https://github.com/rails/rails/pull/51296 |
| 51282 | PR | Transform attributes during `ActiveModel::Serialization::JSON#from_json` | open | 2024-03-08 | https://github.com/rails/rails/pull/51282 |
| 51258 | PR | Emphasize mention of `Migration.verbose` [ci skip] | closed | 2024-03-05 | https://github.com/rails/rails/pull/51258 |
| 51238 | PR | Extract `ActionText::Editor` base class and `ActionText::TrixEditor` adapter | closed | 2024-03-02 | https://github.com/rails/rails/pull/51238 |
| 51093 | PR | Action View Test Case `rendered` memoization | closed | 2024-02-15 | https://github.com/rails/rails/pull/51093 |
| 50913 | PR | Add `activesupport` bug report template | closed | 2024-01-29 | https://github.com/rails/rails/pull/50913 |
| 50865 | PR | Scaffold view templates using Strict Locals | closed | 2024-01-24 | https://github.com/rails/rails/pull/50865 |
| 50852 | PR | Action View: Fallback to existing partial when possible | open | 2024-01-23 | https://github.com/rails/rails/pull/50852 |
| 50844 | Issue | `ActionView::Template::Error`: Missing Active Model partial when rendered from Controller declared in module | open | 2024-01-22 | https://github.com/rails/rails/issues/50844 |
| 50727 | PR | Action View Tests: Use `#with_routing` helper | closed | 2024-01-12 | https://github.com/rails/rails/pull/50727 |
| 50665 | PR | Raise `ArgumentError` if `:renderable` object does not respond to `#render_in` | closed | 2024-01-09 | https://github.com/rails/rails/pull/50665 |
| 50623 | PR | Pass render options and block to calls to `#render_in` | closed | 2024-01-06 | https://github.com/rails/rails/pull/50623 |
| 50622 | PR | Document rendering `:renderable` and `#render_in` | closed | 2024-01-06 | https://github.com/rails/rails/pull/50622 |
| 50584 | PR | Parse `ActionView::TestCase#rendered` as DocumentFragment | closed | 2024-01-04 | https://github.com/rails/rails/pull/50584 |
| 50556 | PR | Incorporate I18n.locale into Action Text Rich Text | closed | 2024-01-03 | https://github.com/rails/rails/pull/50556 |
| 50473 | PR | Delegate `ActionText::Content#deconstruct` to Nokogiri | closed | 2023-12-28 | https://github.com/rails/rails/pull/50473 |
| 50472 | PR | Read `ActionText::Attachment.tag_name` in Action Text Fixtures | closed | 2023-12-28 | https://github.com/rails/rails/pull/50472 |
| 50414 | PR | Improve Action Text System Test coverage | closed | 2023-12-21 | https://github.com/rails/rails/pull/50414 |
| 50390 | PR | Treat `as: :html` tests request params as `:url_encoded_form` | closed | 2023-12-18 | https://github.com/rails/rails/pull/50390 |
| 50320 | PR | Tag Builders: render keywords as dasherized HTML attributes | closed | 2023-12-10 | https://github.com/rails/rails/pull/50320 |
| 50312 | PR | Implement `button_to` in terms of `form_tag` | open | 2023-12-09 | https://github.com/rails/rails/pull/50312 |
| 50304 | PR | Document how to transform keys with `ActiveRecord::Store` | open | 2023-12-08 | https://github.com/rails/rails/pull/50304 |
| 50289 | PR | Elaborate on support for hash helpers in Integration Tests [ci skip] | open | 2023-12-06 | https://github.com/rails/rails/pull/50289 |
| 50273 | PR | Add `request.variant` API and guides documentation | closed | 2023-12-05 | https://github.com/rails/rails/pull/50273 |
| 50257 | PR | Sanitize and treat `ActionText::Content#to_{trix_html,html}` as safe | closed | 2023-12-03 | https://github.com/rails/rails/pull/50257 |
| 50255 | PR | Add test coverage for `rich_text_area` helper | closed | 2023-12-03 | https://github.com/rails/rails/pull/50255 |
| 50254 | PR | Action Text Source-to-Compiled code drift | closed | 2023-12-03 | https://github.com/rails/rails/pull/50254 |
| 50252 | PR | Action Text `rich_text_area` code samples [ci skip] | closed | 2023-12-03 | https://github.com/rails/rails/pull/50252 |
| 50245 | PR | Action View Docs: `field_id` and `field_name` examples [ci skip] | closed | 2023-12-02 | https://github.com/rails/rails/pull/50245 |
| 50241 | PR | Alias `field_set_tag` helper to `fieldset_tag` | closed | 2023-12-02 | https://github.com/rails/rails/pull/50241 |
| 50239 | PR | Batch define `FormBuilder` methods with `CodeGenerator` | closed | 2023-12-02 | https://github.com/rails/rails/pull/50239 |
| 50124 | PR | Introduce `field_label` form helper | open | 2023-11-21 | https://github.com/rails/rails/pull/50124 |
| 50010 | PR | Add `actiontext` bug report template | open | 2023-11-10 | https://github.com/rails/rails/pull/50010 |
| 50004 | PR | Add `actionmailer` bug report template | closed | 2023-11-10 | https://github.com/rails/rails/pull/50004 |
| 49986 | PR | Add `actionview` bug report template | closed | 2023-11-09 | https://github.com/rails/rails/pull/49986 |
| 49856 | PR | Rename `ActionView::TestCase::Behavior::{Content,RenderedViewContent}` | closed | 2023-10-30 | https://github.com/rails/rails/pull/49856 |
| 49696 | PR | Document Action Text Sanitization | closed | 2023-10-19 | https://github.com/rails/rails/pull/49696 |
| 49665 | PR | Define `aria:` and `data:` Capybara expression filters | closed | 2023-10-17 | https://github.com/rails/rails/pull/49665 |
| 49474 | PR | Document how to upgrade to `ActionView::TestCase#rendered` [ci skip] | closed | 2023-10-03 | https://github.com/rails/rails/pull/49474 |
| 49390 | PR | Define `TagBuilder` methods for known HTML Elements | closed | 2023-09-26 | https://github.com/rails/rails/pull/49390 |
| 49377 | PR | Action View: Remove internal calls to `tag` with positional arguments | open | 2023-09-25 | https://github.com/rails/rails/pull/49377 |
| 49371 | PR | Deprecate `tag` with positional arguments | closed | 2023-09-25 | https://github.com/rails/rails/pull/49371 |
| 49369 | PR | Action View: Reduce public API of `tag` helper | closed | 2023-09-24 | https://github.com/rails/rails/pull/49369 |
| 49368 | PR | Action View: Document `TagBuilder` as part of the public interface | closed | 2023-09-24 | https://github.com/rails/rails/pull/49368 |
| 49319 | PR | Use `assert_dom_equal` more in Action View Tests | closed | 2023-09-19 | https://github.com/rails/rails/pull/49319 |
| 49288 | PR | Action View: docs use `application/` instead of `shared/` | closed | 2023-09-15 | https://github.com/rails/rails/pull/49288 |
| 49194 | PR | Introduce `ActionView::TestCase.register_parser` | closed | 2023-09-08 | https://github.com/rails/rails/pull/49194 |
| 48912 | PR | Change `has_secure_token` default to `on: :initialize` | closed | 2023-08-09 | https://github.com/rails/rails/pull/48912 |
| 48847 | PR | Omit `webdrivers` gem from `Gemfile` template | closed | 2023-07-29 | https://github.com/rails/rails/pull/48847 |
| 47436 | PR | Don't double-encode nested `field_id` and `field_name` index | closed | 2023-02-20 | https://github.com/rails/rails/pull/47436 |
| 47420 | PR | Specify when to generate `has_secure_token` | closed | 2023-02-16 | https://github.com/rails/rails/pull/47420 |
| 47318 | PR | `token_list`: Guard Stimulus' `data-action` from multiple escapes | closed | 2023-02-08 | https://github.com/rails/rails/pull/47318 |
| 47163 | PR | Make `tag.attributes` token-list aware | open | 2023-01-27 | https://github.com/rails/rails/pull/47163 |
| 47159 | PR | `tag.attributes` accept variable number of `Hash` | open | 2023-01-27 | https://github.com/rails/rails/pull/47159 |
| 46808 | PR | Revert "Focus editor after calling `fill_in_rich_text_area`" | closed | 2022-12-23 | https://github.com/rails/rails/pull/46808 |
| 46807 | PR | Invoke `.focus()` on `<trix-editor>` after calling `fill_in_rich_text_area` | open | 2022-12-23 | https://github.com/rails/rails/pull/46807 |
| 46447 | PR | Update Action Text's Trix dependency | closed | 2022-11-08 | https://github.com/rails/rails/pull/46447 |
| 46271 | PR | Support `has_rich_text` with `strict_loading:` | closed | 2022-10-18 | https://github.com/rails/rails/pull/46271 |
| 46249 | PR | Focus editor after calling `fill_in_rich_text_area` | closed | 2022-10-14 | https://github.com/rails/rails/pull/46249 |
| 45549 | PR | Include `:rich_text_area` Capybara selector in `:_field` filter set | closed | 2022-07-08 | https://github.com/rails/rails/pull/45549 |
| 45366 | PR | Support calls to `#field_name` with nil `object_name` | closed | 2022-06-15 | https://github.com/rails/rails/pull/45366 |
| 44468 | PR | Move `convert_to_model` call from `form_for` into `form_with` | closed | 2022-02-17 | https://github.com/rails/rails/pull/44468 |
| 44328 | PR | `form_for`: Attempt to call `to_model` on first argument | closed | 2022-02-03 | https://github.com/rails/rails/pull/44328 |
| 44278 | PR | Support reading `FormBuilder#id` from `id:` option | closed | 2022-01-27 | https://github.com/rails/rails/pull/44278 |
| 44275 | PR | `form_with`: close tag when block omitted | open | 2022-01-27 | https://github.com/rails/rails/pull/44275 |
| 44081 | PR | Extend `dom_id` and `dom_class` to accept var-args | closed | 2022-01-05 | https://github.com/rails/rails/pull/44081 |
| 43886 | PR | Generate `[id]` for `FormBuilder#button` called with method name | closed | 2021-12-15 | https://github.com/rails/rails/pull/43886 |
| 43614 | PR | Document `tag.attributes` helper [ci-skip] | closed | 2021-11-08 | https://github.com/rails/rails/pull/43614 |
| 43511 | PR | ActiveStorage: support empty attachments submits | closed | 2021-10-22 | https://github.com/rails/rails/pull/43511 |
| 43425 | PR | DOCS: Improve ActionText FixtureSet Ruby docs | closed | 2021-10-10 | https://github.com/rails/rails/pull/43425 |
| 43421 | PR | Implement `form_for` by delegating to `form_with` | closed | 2021-10-10 | https://github.com/rails/rails/pull/43421 |
| 43418 | PR | Forms: Deprecate `local:` and `remote:` options | open | 2021-10-09 | https://github.com/rails/rails/pull/43418 |
| 43417 | PR | button_to: Support `authenticity_token:` option | closed | 2021-10-09 | https://github.com/rails/rails/pull/43417 |
| 43416 | PR | Action View: Support `fields model: [...]` | closed | 2021-10-09 | https://github.com/rails/rails/pull/43416 |
| 43413 | PR | Make `button_to` more model-aware | closed | 2021-10-08 | https://github.com/rails/rails/pull/43413 |
| 43411 | PR | Support name Symbol to `FormBuilder#button` | closed | 2021-10-08 | https://github.com/rails/rails/pull/43411 |
| 43409 | PR | Introduce `field_name` view helper | closed | 2021-10-08 | https://github.com/rails/rails/pull/43409 |
| 43408 | PR | Implement `field_id` in terms of the FormBuilder's `namespace:` option | closed | 2021-10-08 | https://github.com/rails/rails/pull/43408 |
| 43129 | PR | Synchronize System Test and Template text | closed | 2021-08-29 | https://github.com/rails/rails/pull/43129 |
| 42755 | PR | Execute `field_error_proc` within view | closed | 2021-07-11 | https://github.com/rails/rails/pull/42755 |
| 42739 | PR | Resolve bug in nested FormBuilder#field_id | closed | 2021-07-08 | https://github.com/rails/rails/pull/42739 |
| 42069 | PR | Action Text: forward form: option to hidden input | closed | 2021-04-25 | https://github.com/rails/rails/pull/42069 |
| 42051 | PR | Support `<form>` elements without `[action]` | closed | 2021-04-22 | https://github.com/rails/rails/pull/42051 |
| 41656 | PR | ActionView: Implement Tag Helpers with Nokogiri | closed | 2021-03-11 | https://github.com/rails/rails/pull/41656 |
| 41638 | PR | TokenList and Attributes Objects | closed | 2021-03-08 | https://github.com/rails/rails/pull/41638 |
| 41291 | PR | Drive ActionDispatch::IntegrationTest via Capybara | closed | 2021-02-01 | https://github.com/rails/rails/pull/41291 |
| 41062 | PR | Improve ActionText::FixtureSet documentation | closed | 2021-01-09 | https://github.com/rails/rails/pull/41062 |
| 41045 | PR | Emulate non-{GET,POST} submissions via button[formmethod] | closed | 2021-01-07 | https://github.com/rails/rails/pull/41045 |
| 40747 | PR | Consistently render `button_to` as `<button>` | closed | 2020-12-04 | https://github.com/rails/rails/pull/40747 |
| 40700 | PR | ActionView: Serialize Regexp into HTML attribute | closed | 2020-11-26 | https://github.com/rails/rails/pull/40700 |
| 40664 | PR | Build token list with RecordIdentifier#dom_ids | closed | 2020-11-21 | https://github.com/rails/rails/pull/40664 |
| 40657 | PR | Transform Hash into HTML atrributes for ERB interpolation | closed | 2020-11-20 | https://github.com/rails/rails/pull/40657 |
| 40600 | PR | ActionView: FormBuilder default aria-invalid value | closed | 2020-11-11 | https://github.com/rails/rails/pull/40600 |
| 40499 | PR | ARIA attributes: serialize empty Hash and Array as nil | closed | 2020-10-31 | https://github.com/rails/rails/pull/40499 |
| 40479 | PR | Serialize aria- namespaced list attributes | closed | 2020-10-29 | https://github.com/rails/rails/pull/40479 |
| 40341 | PR | Ensure `tag.with_options({}).p` builds a `<p>` | closed | 2020-10-05 | https://github.com/rails/rails/pull/40341 |
| 40308 | PR | Improve ActionText extensiblibility | closed | 2020-09-30 | https://github.com/rails/rails/pull/40308 |
| 40289 | PR | Add `action_text_attachment` helper to `FixtureSet` | closed | 2020-09-25 | https://github.com/rails/rails/pull/40289 |
| 40146 | PR | Alias TagHelper#class_names to #token_list | closed | 2020-08-31 | https://github.com/rails/rails/pull/40146 |
| 40127 | PR | Declare ActionView::Helpers::FormBuilder#id and #field_id | closed | 2020-08-28 | https://github.com/rails/rails/pull/40127 |
| 40121 | PR | Serialize aria- namespaced list attributes | closed | 2020-08-27 | https://github.com/rails/rails/pull/40121 |
| 38667 | PR | Extend `ActionView::Helpers#translate` to yield | closed | 2020-03-06 | https://github.com/rails/rails/pull/38667 |
| 38552 | PR | Locate `fill_in_rich_text_area` by `<label>` text | closed | 2020-02-22 | https://github.com/rails/rails/pull/38552 |
| 38551 | PR | Generate `aria-label` in calls to `rich_text_area` | closed | 2020-02-22 | https://github.com/rails/rails/pull/38551 |
| 38550 | PR | Yield translation to `FormBuilder#button` block | closed | 2020-02-22 | https://github.com/rails/rails/pull/38550 |
| 38549 | PR | Yield `Tags::Label::LabelBuilder#translations` | closed | 2020-02-22 | https://github.com/rails/rails/pull/38549 |
| 14649 | PR | Make `NilClass` quack like `to_s` formattable objects | closed | 2014-04-08 | https://github.com/rails/rails/pull/14649 |
---

### Frame breakout from the server

The single longest-running thread in his upstream work. Chronology: `hotwired/turbo#257` (issue, 2021-04, still open) → `hotwired/turbo#397` (PR, closed by him) → `hotwired/turbo#445` / `#677` (`turbo:frame-missing`) → `hotwired/turbo-rails#367` (PR, opened 2022-07-31, **still open after 4 years**) → `hotwired/turbo#694` (`Turbo-Action:` header, still open).

### 1. The `fetch` constraint — why a `Turbo-Frame: _top` response header cannot work

This is the load-bearing technical finding, and he has repeated it for five years. From [hotwired/turbo#257, 2021-09-16](https://github.com/hotwired/turbo/issues/257#issuecomment-920482318):

> Unfortunately, sending a response with `Turbo-Frame: _top` is incompatible with the browser built-in `fetch` API.
>
> A fetch `Response` resulting in a redirect _deliberately prevents_ access to the intermediate redirect response with a status in the `300...399` range.

He quotes the Fetch spec, then:

> Unless I'm missing a crucial concept, I don't think there is a way for Turbo to excise the server's `Turbo-Frame: _top` header from the chain of responses. Without access to that value, the client-side is unable to react to the server's override.

And the ranked alternatives, same comment — note the explicit ordering by regret:

> 1. Decide on a special case, reserved query parameter (for the sake of argument: `?turbo_frame_override=_top`). During the form submission response code, we can tease out that value (and maybe even delete it from the URL) and push a new Visit onto the history. Responses to URLs _without_ that query parameter would preserve the current behavior and continue to drive the frame element to the new URL.
> 2. Replace Fetch with [XMLHttpRequest](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest), and use that to access the intermediate response and its headers. This assumes that's even possible (I haven't experimented)
> 3. Add a unique identifier to the headers of each Turbo Frame-initiated Fetch Request. Since the value is shared between the client and server, we could send frame target overrides via cookies
> 4. Change the Turbo Frame semantics for HTTP Response codes. For example, [201 Created](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/201) responses are sent back with a `Location:` header. We could use `201` to signify that a frame response should navigate to the URL in the header, and treat [303 See Other](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/303) responses as `_top` level redirects.
>
> I've ranked them from least to most regrettable. I'm hoping I'm missing something obvious here!

He was still saying this in [Dec 2024](https://github.com/hotwired/turbo-rails/pull/367#issuecomment-2541689558), when a commenter endorsed Kevin McConnell's "just add a frame header to the redirect response" idea:

> [I have explored that possibility in the past](https://github.com/hotwired/turbo-rails/pull/367#issuecomment-2000033446), but could not find a way to make it work with `fetch`. If you explore it on your own and are able to make progress, please share!

And in [March 2024](https://github.com/hotwired/turbo-rails/pull/367#issuecomment-2000033446), replying directly to McConnell's proposal:

> I've explored this, and haven't found a way to make a server-set HTTP header available to Turbo when the resulting redirect occurs. I believe Turbo's use of `fetch` makes the intermediate HTTP response inaccessible. Have you had success in achieving that behavior?

### 2. The scenario he insists is unsolved — "matching frame in BOTH request and response"

His clearest framing of the problem, [hotwired/turbo#257, 2021-11-13](https://github.com/hotwired/turbo/issues/257#issuecomment-968096384). He splits the problem in two. Case one (response *without* a matching frame):

> Since that response doesn't contain a matching `<turbo-frame id="dialog_frame">`, replacing the entire page's contents with the response feels appropriate.
>
> ...
>
> This behavior would require some changes to the Turbo's internals, but are reasonable. **If we wanted this behavior, the path forward is fairly clear.**

Case two (response *with* a matching frame) — the hard one, walked through as a multi-step form in a `<dialog>`:

> This is where things become unclear. We want the successful submission to "break out" of the frame and fully navigate the page to `/articles/1`. However, since there is a `<turbo-frame id="dialog_frame"></turbo-frame>` in **both** the requesting page and response, we can't rely on the presence or absence to make that decision.
>
> Declaring each page's `<turbo-frame id="dialog_frame">` with the `[target="_top"]` attribute would handle the "create, then redirect the page" use case, but would break the multi-step experience, and would also break intermediate-step validations. Support for both `[target="_top"]` and `422` status responses is what [210][] aims to implement.
>
> Conversely, omitting the `[target]` attribute and controlling whether or not to stay "contained" within the frame is what [397][] (paired with a server-side component like what's mentioned in [comment]) aims to support.
>
> I would love to cover all of these behaviors without requiring that the server track frame state in its session, or respond with a `Turbo-Frame` header.
>
> Are there other solutions that I'm not considering that support the experience described above?

Earlier the same thread, on why `[target="_top"]` on the frame is not the answer ([2021-11-11](https://github.com/hotwired/turbo/issues/257#issuecomment-966549883)):

> For example, when there _is_ a matching `<turbo-frame>` element in both the source and response document. In that circumstance, I think applications might want a mechanism to ignore the presence of the matching frames and "break out" of the frame to navigate the entire page.

### 3. turbo-rails#367 — the PR itself

Current PR body (re-pitched 2024-11-23), [hotwired/turbo-rails#367](https://github.com/hotwired/turbo-rails/pull/367):

> Introduces the `Turbo::Stream::Redirect` concern to introduce the `#break_out_of_turbo_frame_and_redirect_to` and `#turbo_stream_redirect_to` methods. The `#break_out_of_turbo_frame_and_redirect_to` draws inspiration from the methods provided by the [Turbo::Native::Navigation][] concern.
>
> When handling requests made from outside a `<turbo-frame>` elements (without the `Turbo-Frame` HTTP header), respond with a typical HTML redirect response.
>
> When handling request made from inside a `<turbo-frame>` element (with the `Turbo-Frame` HTTP header), render a `<turbo-stream action="visit">` element with the redirect's pathname or URL encoded into the `[location]` attribute.

On the request-count argument (the objection that this adds round-trips):

> Typically, an HTTP that would result in a redirect nets two requests: the first submission, then the subsequent GET request to follow the redirect.
>
> In the case of a "break out", the same number of requests are made: the first submission, then the subsequent GET made by the `Turbo.visit` call.

Note the API shift: the original 2022 version was `redirect_to url, turbo_frame: "_top"`. DHH rejected the machinery in [June 2023](https://github.com/hotwired/turbo-rails/pull/367#issuecomment-1598888480) ("too many moving parts… let's see if we can't find a path that uses the new turbo-visit-control setup"), and the 2024 re-pitch traded the elegant keyword for the explicit `break_out_of_turbo_frame_and_redirect_to` — which the community then objected to as a regression.

### 4. Why he dislikes his own workaround

This is his most revealing comment, [2024-03-15](https://github.com/hotwired/turbo-rails/pull/367#issuecomment-2000226306). After demonstrating the `turbo_stream.action(:visit, root_url)` custom-stream-action workaround:

> While it's a suitable workaround given the constraints, and behaves the way it needs to, I dislike that it mixes HTML and Turbo Stream content types. Through that lens, I'm similarly dissatisfied with the original approach proposed by this PR's changeset.
>
> What I've come to appreciate about the `redirect_to`-powered Page Refresh is that the client-server communication revolves entirely around HTTP and `text/html`. Like @kevinmcconnell mentioned in [#367 (comment)](https://github.com/hotwired/turbo-rails/pull/367#issuecomment-1600748567), adding abstractions to `turbo-rails` to improve the ergonomics around this type of interaction would need to be replicated in other server contexts.

That is: **he agrees with the maintainers' objection to his own PR.** His stated ideal is HTTP + `text/html` only, no Rails-specific abstraction, because any such abstraction has to be re-implemented in turbo-laravel, turbo-php, etc.

On the `turbo-visit-control` workaround the maintainers pushed instead ([2024-03-15](https://github.com/hotwired/turbo-rails/pull/367#issuecomment-2000033446)):

> It "works", in that it meets the acceptance criteria outlined above without introducing new abstractions or Turbo mechanisms. However, the resulting `Turbo.visit`-driven navigation retains the `?turbo_visit_controler=reload` query parameter as part of the final URL. I dislike the fact that this work-around leaks that sort of implementation detail.

And his direct challenge back to the maintainers, same comment, quoting McConnell's "lean on Turbo Streams" position:

> Is there an architectural change to be made to Turbo to improve support for this style of scenario? If there isn't a way to support this directly, are there any examples of concrete changes to the example application below that you'd make to flesh out Turbo Stream-powered solutions?

(Never answered. The thread's last maintainer comment is McConnell's, June 2023.)

### 5. HTTP status codes as the escape hatch he'd prefer

[2024-03-15](https://github.com/hotwired/turbo-rails/pull/367#issuecomment-2000266457) — the most concrete alternative design he has put forward:

> There are two semantically meaningful HTTP status codes that might be worth considering as special-case escape hatches to "break out" of Turbo Frame requests from the server.
>
> There is [201 Created](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/201): […]
>
> This means that a server like Rails could control a frame with a status code through something like [head](https://edgeapi.rubyonrails.org/classes/ActionController/Head.html#method-i-head):
>
> ```ruby
> def create
>   @todo = Todo.new(todo_params)
>
>   if @todo.save
>     if turbo_frame_request?
>       head :created, location: @todo
>     else
>       redirect_to @todo
>     end
>   else
>     render :new, status: :unprocessable_entity
>   end
> end
> ```
>
> Then the Turbo Frame Controller could special case responses with `201 Created`, then call `Turbo.visit(response.headers["Location"])`.
>
> There is also [205 Reset Content](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/205): […] The downside here is that it doesn't have the `Location:` header, so the response couldn't semantically encode any information to indicate where to navigate to, other than `window.location.href`.

### 6. The `[disabled]` frame trick — his other server-side breakout mechanism

From [hotwired/turbo#445, 2021-12-15](https://github.com/hotwired/turbo/pull/445#issuecomment-995285530):

> The desire to render the `[disabled]` attribute server side comes from [#257 (comment)](https://github.com/hotwired/turbo/issues/257#issuecomment-968451458). It's a mechanism to "break out" from the server while still server-generating the HTML.
>
> The pattern there is that the frame is rendered (with server-generated attributes and contents) and sent to the client. If the request is made from a frame, you could toggle the `[disabled]` attribute and force a `turbo:frame-missing` (or `turbo:frame-not-found`) on the client side. If it _isn't_ a frame request, the `<turbo-frame>` element (along with the server-generated attributes and contents) is sent to the client's full-page request. Then the client has an opportunity to "enable" the frame by removing the `[disabled]` attribute through JS.

### 7. Why a missing frame must NOT become a page-wide error

[hotwired/turbo#445, 2021-12-16](https://github.com/hotwired/turbo/pull/445#issuecomment-996121516) — a clean statement of the Frames value proposition:

> Behavior like that isn't baked into `turbo` itself because transforming a failed Frame request for a portion of the page into page-wide error undercuts the value proposition of Frames that enables decomposing a page into chunks of asynchronously fetchable fragments.
>
> For example, 500'ing the entire page because a lazily loaded menu's contents failed to load feels like an overreaction.

And his own open design questions when introducing `turbo:frame-missing` ([2021-12-15](https://github.com/hotwired/turbo/pull/445#issuecomment-995164715)):

> * Is `turbo:frame-missing` a good name? Should it be named `turbo:frame-not-found`, `:frame-error`, or something else?
> * Does dispatching a reference to the `FetchResponse` make sense? It'd effectively make the shape of `FetchResponse` objects public API, and would represent a commitment to support that API in future releases
> * Does treating `turbo-frame[id][disabled]` in the body as a "missing" frame deserve its own conversation or PR?

He then walked the default back himself in [#677](https://github.com/hotwired/turbo/pull/677) — `turbo:frame-missing`: Do not `Turbo.visit` by default:

> Restore the existing default behavior when a matching frame is missing from a response: log an error and blank the frame.
>
> Alongside that original behavior, yield the [Response][] instance and a `Turbo.visit`-like callback that can transform the `Response` instance into a `Visit`.

### 8. His stance on minimizing machinery (predates all of the above)

[hotwired/turbo#257, 2022-06-01](https://github.com/hotwired/turbo/issues/257#issuecomment-1143999625), rejecting a proposed new `<turbo-stream>` action in favour of composing existing primitives:

> Plus, since they're `<a>` elements, you can decide between `"advance"` or `"replace"` semantics with `[data-turbo-action]`, like you typically would with any other `<a>` element, instead of passing it through a bespoke `[data-turbo-navigation-action-value]` attribute. The same is true for `[href]` instead of `[data-turbo-navigation-url-value]`, and `[data-turbo-frame]` instead of `[data-turbo-navigation-target-value]`.
>
> The idea is the same, but by relying on built-in platform features and their Tubro-powered extensions, we can cut down on the amount of machinery involved.

### Summary of the counterparty positions (for contrast)

- **DHH**, [2023-06-20](https://github.com/hotwired/turbo-rails/pull/367#issuecomment-1598888480): "I think there are too many moving parts in this setup at the moment. I think the underlying desire to be able to break out from the server side is right, but let's see if we can't find a path that uses the new turbo-visit-control setup for frames"; then [2023-06-21](https://github.com/hotwired/turbo-rails/pull/367#issuecomment-1600273947): "What I'm saying is that the implementation required in this PR is too heavy and cumbersome… We'll eventually crack this with a simple solution!"
- **Kevin McConnell**, [2023-06-21](https://github.com/hotwired/turbo-rails/pull/367#issuecomment-1600748567): "Making Frames any more 'server-directed' would mean more overlap between Frames and Streams, and I think it will start to introduce complexity that we don't need." Also proposed the redirect-response frame header — the exact thing Sean says `fetch` forbids.

---

### Frames, history and URLs

He is the author of frame→history promotion (`data-turbo-action` on frames). It is *his* feature, added in `hotwired/turbo#398` (2021-09-17, merged by DHH), and he has spent years patching its fallout.

### He built it

[hotwired/turbo#398](https://github.com/hotwired/turbo/pull/398), PR body:

> Extend of built-in support for `<a>` elements with [data-turbo-action][] (with `"replace"` or `"advance"`) to also encompass `<turbo-frame>` navigations.
>
> Account for the combination of of `[data-turbo-frame]` and `[data-turbo-action]` to navigate the target `<turbo-frame>` _and_ navigate the page's history push state, supporting:
>
> * `turbo-frame[data-turbo-action="..."]`
> * `turbo-frame a[data-turbo-action="..."]`
> * `a[data-turbo-frame="..."][data-turbo-action="..."]`
> * `form[data-turbo-frame="..."][data-turbo-action="..."]`
> * `form[data-turbo-frame="..."] button[data-turbo-action="..."]`
> * `form button[data-turbo-frame="..."][data-turbo-action="..."]`
>
> Whenever a Turbo Frame response is loaded that was initiated from one of those submitters, forms, anchors, or turbo-frames annotated with a `[data-turbo-action]`, the subsequent firing `turbo:frame-render` event will create a `Visit` instance that will skip rendering, won't result in a network request, and will instead only update the snapshot cache and history.

### The fallout he then fixed

`#448` "Preserve page state while promoting Frame-to-Visit" ([2021-11-16](https://github.com/hotwired/turbo/pull/448)) is the clearest statement of the design's fragility:

> The way that the `willRender:` guard clause was removed caused new issues in how Frame-to-Visit navigations were treated. Removing the outer conditional without replacing it with matching checks elsewhere has caused Frame-to-Visit navigations to re-render the entire page, and losing the current contextual state like scroll, focus or anything else that exists outside the `<turbo-frame>` element.
>
> Similarly, the nature of the `FrameController.proposeVisitIfNavigatedWithAction()` helper resulted in an out-of-order dispatching of `turbo:` and `turbo:frame-` events, and resulted in `turbo:before-visit` and `turbo:visit` events firing before `turbo:frame-render` and `turbo:frame-load` events.

And his own admission that the plumbing is bad:

> The `fetchResponseLoaded(FetchResponse)` callback is an improvement, but is still an awkward way to coordinate between the `formSubmissionIntercepted()` and `linkClickIntercepted()` delegate methods, the `FrameController` instance, and the `Session` instance. It's functional for now, and we'll likely have a change to improve it with work like what's proposed in [430][] (which we can take on while developing `7.2.0`).

(`#430`, "Extract `FrameVisit` to drive `FrameController`", is still open, 5 years later.)

Also `#790` "Fix: Promoting lazy-loaded Frames" ([2022-11-06](https://github.com/hotwired/turbo/pull/790)) — lazy frames silently ignored `data-turbo-action` for a year after `#398` shipped:

> Prior to this commit, `<turbo-frame>` elements navigated via the `AppearanceObserver` (powered by the [loading=lazy][] attribute) were not accounting for their [data-turbo-action][] attributes.

### The `tracked_element_mismatch` reload bug — his diagnosis and his fix proposal

`hotwired/turbo#1047` (Promoted Frame Visits cause `tracked_element_mismatch` reloads). His diagnosis, [2023-12-01](https://github.com/hotwired/turbo/issues/1047#issuecomment-1835170106):

> I wonder if it's related to a mostly (or completely) empty `<head>` element coming from `turbo-rails`

Then, [2024-01-24](https://github.com/hotwired/turbo/issues/1047#issuecomment-1908655512):

> @afcapel @jorgemanrubia I've encountered this today, and like @domchristie mentioned in [#1047 (comment)](https://github.com/hotwired/turbo/issues/1047#issuecomment-1825113897), it's a major impediment to upgrading.
>
> I'm not sure about how to resolve it. […] I've opened [hotwired/turbo-rails#534](https://github.com/hotwired/turbo-rails/pull/534). I've also opened [hotwired/turbo#694](https://github.com/hotwired/turbo/pull/694) to send the `Turbo-Action:` header when it's present in the requesting context. Turbo Rails could render the full document when both `Turbo-Frame:` and `Turbo-Action:` are present. Another alternative is to special-case responses with a completely empty `<head>`, then intervene to populate them with `document.head.innerHTML`.
>
> I think [#694](https://github.com/hotwired/turbo/pull/694) (even without the `Turbo-Action:` header) fits into the Morph-centric mental model: the server renders full HTML documents, then the client decides how to negotiate that new content into the document.

### His actual position: frames should stop being a server-side special case

This is the deepest thing he has written about frames, [hotwired/turbo-rails#534, 2024-02-24](https://github.com/hotwired/turbo-rails/pull/534#issuecomment-1962421283). He wants to **delete** the minimal-frame-layout optimization:

> I'm suggesting that the Turbo Frame server-side mental model change to be **more** like Morphing.
>
> **Morphing** — When submitting a form that redirects back or navigating a link that replaces the page, the server sends a fully formed document. As I understand, the value proposition of a Morphing page refresh is that the server does not care about the diff between what its rendering and what's on the client -- the client will handle negotiating the new content into the existing content. Even if the entirety of the new content is a new flash message, the full `<html>` document is sent down in the request and it's Turbo responsibility to render it.
>
> Furthermore, the client doesn't communicate anything special to the server. Other than being `fetch`-initiated requests, the server doesn't require any special headers or information in order to integrate with Morphing.
>
> **Frames** — From the client's perspective, frames behave in a similar way. […] From the server's perspective, the similarities break down. The `Turbo-Frame` header is a client-side implementation detail that servers expect. Instead of rendering a full document without any additional information from the client, servers use the `Turbo-Frame` header to determine the response HTML. In the case of `turbo-rails`, that response HTML can vary wildly based on the presence or absence of that header.
>
> The concept of Frames pre-dates Morphing. In a world where applications are encouraged to enable Morphing for the majority of their pages (instead of other approaches like Frame or Stream form submission responses), any gains won by `turbo-rails`'s server-side decision to skip rendering the page layout are likely to be offset by full document responses elsewhere. This is even more likely with the introduction of `<turbo-stream action="refresh">` elements broadcast over Web Sockets.
>
> **So what?** — Over time, the `turbo-rails`-driven server-side optimization to return different responses for frames and full pages has led to unintended side-effects and several Issues and codebase workarounds in `@hotwired/turbo`.
>
> The proposal is that by reversing the optimization and re-establishing the traditional Turbolinks expectations (that the servers responds with full HTML documents and the client expects full HTML documents), we have an opportunity to posit a singular simplified mental model and simplify some of `@hotwired/turbo`'s codepaths and patterns.

Earlier, [2023-12-01](https://github.com/hotwired/turbo-rails/pull/534#issuecomment-1835358249) and [2024-02-21](https://github.com/hotwired/turbo-rails/pull/534#issuecomment-1955489880):

> Rendering a minimal layout forces `turbo:reload` events because of the severe difference in the contents of the minimal layout's `<head>` and the requesting document's fully populated `<head>`.

> To paraphrase the Morphing mental model: "render full HTML documents on the server, then let the client decide how to insert that new content into the document".
>
> Rendering full and valid documents for Turbo Frames is likely to result in similar levels of queries, template renders, and over-the-wire traffic as a full page refresh with Morphing. That also means they stand to benefit from the same kinds of rendering mechanisms that Morphing might influence you to adopt (fragment caching, HTTP caching, etc).

**Status: unresolved.** turbo-rails#534 is still open (opened 2023-12-01), turbo#694 is still open (opened 2022-08-19). Neither has a maintainer response in the thread.

### On tracking frame state in the URL hash

Reviewing marcoroth's `hotwired/turbo#692`, [2022-08-17](https://github.com/hotwired/turbo/pull/692#issuecomment-1218482178):

> For me, this is the biggest blocker and unanswered question. Breaking that behavior [existing anchor scroll-to behaviour] by default is a non-starter. I wonder what the best way to strike that balance would be.

---

### Morphing (Turbo 8) and Stimulus

### `hotwired/turbo#1210` — "Turbo morph not preserving stimulus values" (still open)

There is exactly **one** comment from him on this thread, [2024-03-01](https://github.com/hotwired/turbo/issues/1210#issuecomment-1972409546), transcribed in full:

> Thank you for opening this issue and for sharing a reproduction repository.
>
> This feels related to several existing issues:
>
> * https://github.com/hotwired/turbo/issues/1083
> * https://github.com/hotwired/turbo/issues/1087
>
> The events that you mention were introduced by https://github.com/hotwired/turbo/pull/1097 (as a successor to a commit (https://github.com/hotwired/turbo/pull/1019/commits/9944490a3c8aec0c5060401125cc8932e93a32df) that was ultimately reverted).
>
> > although I'm not sure if it will have any other unforseen implications
>
> The unforeseen circumstances are certainly a risk. Over-committing to ignore *all* server-sent Stimulus Values feels safer than under-committing. I'm sure with time there will be some edge cases that will emerge.
>
> > it would be great if this behavior just worked out of the box.
>
> Integration with Stimulus was [the main driver behind that contribution](https://github.com/hotwired/turbo/pull/1097#issuecomment-1910973403). As the dust of the Turbo 8 release settles, I hope that there will bandwidth for a coordinated effort to expand built-in Morph integration for Stimulus and Trix (and therefore Action Text). Something that affords a configuration-less turn-key solution for most circumstances with some focused escape hatches when necessary.

That last sentence is his design goal in one line: **configuration-less turn-key morph/Stimulus integration, with focused escape hatches**. The issue is still open (opened 2024-03-01), and the "coordinated effort" never materialised.

The user's workaround he blesses is a global `turbo:before-morph-attribute` listener that `preventDefault()`s any `data-*-value` attribute — i.e. ignore *all* server-sent Stimulus Values. He says over-committing to that is "safer than under-committing".

### `hotwired/turbo#1097` — the events he built for exactly this

[PR body](https://github.com/hotwired/turbo/pull/1097):

> **The problem** — Some client-side plugins are losing their state when elements are morphed. Without resorting to `MutationObserver` instances to determine when a node is morphed, uses of those plugins don't have the ability to prevent (without `[data-turbo-permanent]`) or respond to the morphing.
>
> **The proposal** — This commit introduces a `turbo:before-morph-element` event […] If that event is cancelled via `event.preventDefault()`, it'll skip the morph as if the element were marked with `[data-turbo-permanent]`.
>
> Along with `turbo:before-morph-element`, this commit also introduces a `turbo:before-morph-attribute` to correspond to the `beforeAttributeUpdated` callback that Idiomorph provides. When listeners (like an `HTMLDetailsElement`, an `HTMLDialogElement`, or a Stimulus controller) want to preserve the state of an attribute, they can cancel the `turbo:before-morph-attribute` event that corresponds with the attribute name (through `event.detail.attributeName`).

And on where that integration *should* live:

> This commit re-introduced test coverage for a Stimulus controller to demonstrate how an interested party might respond. **It isn't immediately clear with that code should live**, but once we iron out the details, it could be part of a `@hotwired/turbo/stimulus` package, or a `@hotwired/stimulus/turbo` package that users (or `@hotwired/turbo-rails`) could opt-into.

[2024-01-25](https://github.com/hotwired/turbo/pull/1097#issuecomment-1910973403) — the "main driver" comment he cites in #1210:

> @jorgemanrubia @afcapel I've expanded this change to include a `turbo:before-morph-attribute` event to afford stateful elements (like `HTMLDetailsElement`, `HTMLDialogElement`, `TrixEditorElement`, or a Stimulus controller with `[data-*-value]` attributes) an opportunity to partially opt out of the morph changes.

He then asked the Basecamp maintainers what *they* were doing ([2024-01-27](https://github.com/hotwired/turbo/pull/1097#issuecomment-1913345376)):

> @jorgemanrubia prior to the introduction of these events, what strategies have you been using to support Trix and Stimulus controllers in a morph-compatible way?

Jorge Manrubia's answer — which is the crux of why upstream never invested more here:

> We haven't found issues with Trix, I think because we aren't using a Trix instance in scenarios where a page refresh happens 🤔. In the calendar, there is a single case where we used a stimulus value-change callback to prevent an unintended change in an attribute. It hasn't been a common/recurring issue for us.

### The `ignoreActiveValue` round-trip — shipped then rolled back in four weeks

`#1141` (2024-01-25, merged), morph with `ignoreActiveValue: true`:

> Morph with the [ignoreActiveValue: true][] option to morph the currently focused element's attributes, but preserve its value. This behavior can be extremely helpful when paired with an auto-submitting `<form>` element, like a typeahead `[role="combobox"]`, or an auto-submitting [`<input type="search">`][search].

`#1195` (2024-02-21, merged), rolling it back:

> Don't pass the `ignoreActiveValue: true` option when Morphing. To restore that behavior, applications can set `[data-turbo-permanent]` when form control receives focus (through a `focusin` event listener), then remove it if necessary when the form control loses focus (through a `focusout` event listener).

### Custom elements must survive morphing — the `attributeChangedCallback` doctrine

Repeated verbatim in `hotwired/turbo#1287` and `hotwired/turbo-rails#650`:

> Recent changes to integrate with morphing have altered the mental model for some Turbo custom elements […] Custom Elements' `connectedCallback()` and `disconnectedCallback()` (along with Stimulus' `connect()` and `disconnect()`) improved upon invoking code immediately, or listening for `DOMContentLoaded` events.
>
> There are similar improvements to be made to integrate with morphing. First, [observe attribute changes][] by declaring their own `static observedAttributes` properties along with `attributeChangedCallback(name, oldValue, newValue)` callbacks. Those callbacks execute the same initialization code as their current `connectedCallback()` and `disconnectedCallback()` methods.
>
> That'll help resolve this issue. In addition to those changes, **it's important to emphasize this pattern for consumer applications moving forward. JavaScript code (whether Stimulus controller or otherwise) should be implemented in a way that' resilient to both asynchronous connection and disconnection *as well as* asynchronous modification of attributes.**

(`turbo-rails#650` merged; `turbo#1287` still open since 2024-07-24.)

### Naming: fold morphing into existing Stream actions rather than adding one

`hotwired/turbo#1240` (merged) removed `<turbo-stream action="morph">` in favour of `action="replace|update" method="morph"`:

> By consolidating concepts, the "scope" of the modifications is more clearly communicated to callers that are familiar with the underlying DOM interfaces (`Element.replaceWith` and `Element.innerHTML`) that are invoked by the conventionally established Replace and Update actions.
>
> This proposal also aims to reinforce the "method" terminology introduced by the Page Refresh `<meta name="turbo-refresh-method" content="morph">` element.

And [2024-04-04](https://github.com/hotwired/turbo/pull/1240#issuecomment-2038122931) — explicitly rejecting inheriting Morphdom's vocabulary:

> Since Turbo 8's morphing is powered by Idiomorph, drawing inspiration from the Morphdom API isn't as compelling as it is for the `turbo-morph` package.
>
> Instead, utilizing existing Turbo terminology (instead of something like `[morph-style]` to mirror Idiomorph's `morphStyle: "innerHTML" | "outerHTML"` option) encapsulates that implementation detail in a way that makes it possible to change the underlying morphing library in the future without affecting downstream applications.

### Morphing outside page refreshes — `#1319`, and his answer to Manrubia's objections

[hotwired/turbo#1319, 2024-09-24](https://github.com/hotwired/turbo/pull/1319#issuecomment-2371348099). He quotes Manrubia's four objections and answers each:

> The main use case I've encountered that would benefit from morphing involves a List-Details view. The idea is that driving the page toward the Details of a selected item from the List would preserve the state of the List while replacing the contents of the Details with Morphing. In that scenario, navigating the browser backwards and forwards for that entry in the history should utilize Morphing, but navigating _past_ the page with the List-Details view should utilize full-page Replace rendering.

On snapshots-before-morph:

> I think that might be necessary to support the browser history manipulation described above.

On the API-surface objection — this is the key admission:

> Agreed. Exposing the functions directly (like what is proposed in this diff) promotes exploration in this space, but ultimately it would be nice for Turbo to provide first-party support for this. The most obvious change would involve a `[data-turbo-render-method]` attribute (proposed in https://github.com/hotwired/turbo/pull/1145), but **I'm also wary of expanding that area of the interface. There are too many edge cases and combinatory explosion of `[data-turbo-*]` attributes to account for.**
>
> Having said that, I'm not sure of an alternative that is more subtle while being declarative, relies on progressive enhancement and graceful degradation, etc.
>
> […] I wonder if the pattern of URLs is knowable ahead of time. If it is, would a Turbo Native-like Path Configurations JSON file make sense? A callback that provides the source and destination URLs for comparison? A new `detail` property on a `turbo:`-prefixed `CustomEvent`?

`#1319` merged Sept 2025 (a year later). Naming discussion in the follow-up `#1438`, [2025-11-14](https://github.com/hotwired/turbo/pull/1438):

> Would `morphPage` be an improvement? I think `morph` is maybe too vague, and that `morphPage` reinforces the existing concept of "Page Refreshes". The `morphElements` function *could* be abbreviated to `morph(currentElement, newElement)`, since that is much more general purpose, but I prefer being explicit when there are other `morph`-prefixed methods with different suffixes.

### Action Text / Trix under morphing — the other half of the Stimulus problem

`hotwired/turbo-rails#688` (merged 2024-09-30):

> One major challenge that applications face when integrating with morphing-powered Page Refreshes involves `<trix-editor>` elements rendered by Action Text.
>
> The emergent guidance instructs applications to skip morphing by marking the `<trix-editor>` as permanent. This guidance, while correct, does not encapsulate the entire story. In the case of Action Text-rendered `<trix-editor>` elements, applications might invoke `form.rich_text_area` with `data: {turbo_permanent: true}`, expecting for the presence of `trix-editor[data-turbo-permanent]` to be sufficient.
>
> However, to achieve the intended behavior, applications must *nest* their `<trix-editor>` elements *within* an element with `[data-turbo-permanent]` […]
>
> Since Page Refreshes, Morphing, and permanence are all Turbo concepts, and Action Text is a Rails framework, `turbo-rails` feels like the most appropriate codebase (out of `rails`, `trix`, `turbo`, and `turbo-rails`) to house the integration.

### Stimulus-side: what he tried and abandoned

- `hotwired/stimulus#397` "Proposal: Mutation Observation Syntax" (2021-04, closed) — `data-mutation` attribute routing, styled on `data-action`.
- `hotwired/stimulus#460` "Add element and target attribute change callbacks" (2021-09, closed). His own caveat in the body:

  > I still believe that [declaring mutation callbacks](https://github.com/hotwired/stimulus/pull/397) in the same style as event Action Routing is more aligned with Stimulus idioms and has the same self-documenting aspirations. With that being said, I think investigating more generic Controller callbacks could serve as an interesting exercise.

  Closed [2022-08-27](https://github.com/hotwired/stimulus/pull/460#issuecomment-1229221860):

  > I'm closing this in favor of exploring this behavior in an external package first: https://github.com/seanpdoyle/stimulus-mutation.

  > Starting with an external package enables consumers to pick and choose the way they interact with the observers: either callbacks or Actions with [data-mutation] routing declarations. Ideally, one or the other would win out, and the maintenance burden would be halved.

  In review of his own PR he draws the Values/attributes line explicitly:

  > It's also worth noting that Values are better suited for observing `data-` prefixed changes, and that `attributeChanged` is better for global attributes like `[disabled]`, `[hidden]`, or `aria-*` prefixed attributes.

  Note: brunoprietog explicitly asked to revive #460 *because of* morphing ([2023-12-28 on #1097](https://github.com/hotwired/turbo/pull/1097#issuecomment-1871108286)): "it is quite common to create observers in Stimulus controllers and that need will only increase with Turbo morphing." That did not happen.

---

### Accessibility

Accessibility is arguably his most distinctive contribution to Turbo. `aria-busy`, autofocus semantics, focus preservation across renders and streams, `html[lang]`, skip links — all his.

### `[aria-busy]` over a bespoke `[data-turbo-busy]`

`hotwired/turbo#157` (2021-02-04):

> Since `<turbo-frame>` elements are custom elements, the framework has total control over the names of the attributes.
>
> There are existing semantics for what we've introduced as `[busy]`: the ARIA guidelines suggest toggling [aria-busy="true"][aria-busy] when an element is loading more content, and `aria-busy="false"` when the content is loaded.
>
> This provides an "interface" for loading styles through CSS attribute selectors, and hints to assistive technologies the state of the frame.

`#199` (2021-03-06), the unification argument:

> By unifying a single, consistent attribute, consumer applications can use a single attribute CSS selector at different depths within their page to hide or show loading indicators.

And where he wins the argument against `[data-turbo-busy]`, [2021-11-11](https://github.com/hotwired/turbo/pull/199#issuecomment-966289678):

> I'm still not sure toggling `[data-turbo-busy]` is better than toggling [`[aria-busy]`](https://www.w3.org/TR/wai-aria-1.1/#aria-busy) like what was proposed in https://github.com/hotwired/turbo/pull/157

then [2021-11-11](https://github.com/hotwired/turbo/pull/199#issuecomment-966291572):

> Applications could declare their own MutationObservers that observe changes to `[data-turbo-busy]`, and toggle `[aria-busy]` themselves, but there's an opportunity for the framework to manage that state itself.
>
> The opportunity for styling via CSS is still there […] The more I think about it, the more I think it should toggle `[aria-busy]`. I'm going to push up some changes to toggle that instead, and attempt to get CI passing.

### Scoping busy-ness to the frame (`#442`, 2021-11-12)

> Setting `[aria-busy="true"]` on the `<html>` element during a `<turbo-frame>` navigation might be too aggressive given the frame's value proposition of a compartmentalized request-response cycle. If applications style the page based on `html[aria-busy="true"]`, having that toggled during (eager or lazy) Frame loading could lead to a disorienting experience.

[2021-11-12](https://github.com/hotwired/turbo/pull/442#issuecomment-967222689):

> I think Turbo's usage of `[aria-busy]` on the `<html>` element for page-wide navigations and the `<turbo-frame>` (and submitted `<form>`) is appropriate. The issue this change is addressing would be the same with `[data-turbo-busy]`.
>
> Imagine an application that renders a page-wide spinner instead of a progress bar. If a `<turbo-frame>` navigation toggled `html[data-turbo-busy]` (or `html[aria-busy="true"]`, **the attribute itself is unimportant**), and CSS was hooked off `[data-turbo-busy]`, the spinner would be rendered whenever a lazy- or eagerly- loaded frame was navigated.
>
> This change aims to contain `<turbo-frame>`-initiated toggling to the frame itself and the `<form>` that initiated the navigation. Does that break the uniformity of our usage?

### Autofocus — spec conformance, not heuristics

`hotwired/turbo#169` (2021-02-08) introduced `[autofocus]` handling on navigation and frame load. `#654` (2022-07-29) made it spec-correct:

> According to the specification, there is an [algorithm][] for determining the [focusable area][], that is, the elements with the `[autofocus]` attribute that can receive focus:
>
> > * the element's [tabindex][] value is non-null, or the element is determined by the user agent to be focusable;
> > * the element is either not a shadow host, or has a shadow root whose delegates focus is false;
> > * the element is not actually [disabled][];
> > * the element is not [inert][];
> > * the element is either being rendered or being used as relevant canvas fallback content.
>
> This commit extends the `Snapshot.firstAutofocusableElement` to programmatically determine the focusable area based on the available attributes, including checks for `<details>` and `<dialog>` ancestors that do not declare `[open]`.

He also interrogated the maintainers on autofocus-during-preview ([review, 2021-02-08](https://github.com/hotwired/turbo/pull/169)):

> @javan @sstephenson what are your thoughts on this change? What's the incentive for not autofocusing elements when navigating to a page that is not a preview?

### Focus management across Turbo Stream renders (`#686`, merged after 16 months)

> When a `<turbo-stream>` modifies the document, it has the potential to affect which element has focus. […] Prior to this commit, rendering that `<turbo-stream>` would remove the element with focus, and never restore it.
>
> After this commit, the `Session` will capture the `[id]` value of the element with focus (if there is any), then "restore" focus to an element in the document with a matching `[id]` attribute _after_ the render.

Plus autofocus-in-streams, with explicit guard conditions:

> Several scenarios will prevent that, including: there aren't any `[autofocus]` elements in the collection of `<turbo-stream>` elements; the `[autofocus]` element does not exist in the document after the rendering is complete; the document already has an element with focus

Honest about the limit, [2022-12-23](https://github.com/hotwired/turbo/pull/686#issuecomment-1364410107):

> Re-reading the code, those time stamps only mark autofocus elements. Without some kind of css path matching, tracking focus across anonymous elements isn't supported.

Note the review latency he had to push through: "@kevinmcconnell if you're available, this is ready for review." (2022-12-03) → "@manuelpuyol @marcoroth if you're available and interested in this feature, I'd really appreciate some review!" (2022-12-12) → "@afcapel @kevinmcconnell I've rebased this changeset to account for the migration from TypeScript. It's ready for re-review." (2023-09-11).

### Focus across permanent elements (`#436`, 2021-11-06)

> When an interactive element like an `<input>`, `<select>`, `<textarea>`, or `<button>` has an `[id]` attribute and is marked as `[data-turbo-permanent]`, the element and its internal state is preserved _except_ for its focus state. […] When typing a query into the box and submitting the `<form>` by <kbd>enter</kbd>, the request is submitted, the page transitions, the element retains its `[value]` attribute, but focus is lost.

Then the alternative he preferred but that never merged ([2021-11-19](https://github.com/hotwired/turbo/pull/436#issuecomment-974164571), later `#622`):

> As an alternative to handling this internally, Turbo could dispatch a new `turbo:before-permanent-element-render` event with `target` referencing the current element in the DOM, `event.detail.newElement` referencing the element in the response, and a `render(currentPermanentElement, newPermanentElement)` function that substitutes the two.
>
> That way, if they want to do any attribute merging, they have an opportunity to do so based off `target` and `event.detail.newElement` alone:
>
> ```javascript
> addEventListener("turbo:before-permanent-element-render", ({ target, detail: { newElement } }) => {
>   const validationMessageId = newElement.getAttribute("aria-describedby")
>   if (validationMessageId) target.setAttribute("aria-describedby", validationMessageId)
> })
> ```

The motivating a11y case in `#622`'s body is a file-upload validation error, where permanence loses the `aria-describedby` linkage to the error message:

> Prior to this change, the fact that the `<input>` is marked with `[data-turbo-permanent]` would ignore the `[class]` and `[aria-describedby]` attributes from the response, and the `<input>` would remain unchanged (with the attached file still in-memory).

**`#622` is still open since 2022-07-06.**

### Other a11y items

- **`html[lang]` across navigations** — `#1035` (merged 2023-10). "Change the `<html>` element's `[lang]` attribute during navigation. Currently, this isn't possible from applications (without a lot of trouble), since the [turbo:before-render][] event is scoped to the `newBody`." Follow-up ask: "@afcapel thank you for merging this! I wonder if it's worth merging other (or all?) attributes as well."
- **Progress bar timing** — `#1036` (merged): hide the bar on visit completion (near `turbo:load`) rather than between `turbo:before-fetch-response` and `turbo:render`.
- **Skip links** — `#57` (2020-12-29, one of his earliest): "Navigate with a skip link within our Functional test suite, assert that the correct element is scrolled to, the page's Location path and hash are correct, and that the initial tab stop occurs after the skipped-to content."
- **`<dialog>`** — `#388` "Skip `form{,method}="dialog"` when targetting frame": dialog-method forms must not be hijacked by Turbo even when they carry `data-turbo-frame`. `<dialog>` also shows up as a first-class citizen in his `#654` focusable-area work, his `#1097` morph-attribute rationale, and his `#257` multi-step-modal scenario.
- **`aria-live`/`role="status"`**: no PR of his in Turbo touches these — his a11y model is `aria-busy` + focus management, not live regions.
- **Stimulus ARIA** — `hotwired/stimulus#627` "Aria Elements" (open since 2022-12-17), proposing first-class `aria-controls`/`aria-labelledby`/etc. ID-ref traversal in Stimulus:

  > Providing built-in support from Stimulus for elements that a controller establishes an [`[id]`-based relationship][id-relationship] with through ARIA attributes could cultivate a virtuous cycle between assistive technologies (reliant on semantics and document-hierarchy driven relationships) and client-side feature development (reliant on low-friction DOM traversal and state change callbacks).

  Companion: `hotwired/stimulus-rails#49` "Standard Library of ARIA controllers" (2021-02, closed). And in Rails: `#40600` FormBuilder default `aria-invalid`, `#38551` `aria-label` in `rich_text_area`, `#40479`/`#40121` `aria-` namespaced list attributes, `#49665` `aria:` Capybara expression filters.

---

### Other substantive design rationale

**1. Shrink Turbo's public JS API to browser built-ins.** [`hotwired/turbo#1000`](https://github.com/hotwired/turbo/pull/1000), 2023-09-12 (still open):

> This pull request aims to reduce the surface area of those public interfaces, with the purposes of: coordinating with consumer applications through built-in classes that the browser provides; limiting the backwards compatibility burden; freeing up Turbo's internal objects to change over time.

And the sharper point in review:

> The built-in [Request](https://developer.mozilla.org/en-US/docs/Web/API/Request#instance_properties) class is much more immutable than our internal `FetchRequest`. All of its properties are read-only, so consumer's wouldn't be able to re-write data like the method, URL, or body. Mostly, consumers can re-write Headers.

Plus his flag that dropping TypeScript cost them the deprecation runway:

> I realize now that the removal of TypeScript in anticipation of an 8.0 release means that a deprecation cycle as part of a minor release is no longer possible.

**2. `Turbo.config` as the one supported configuration surface.** [`hotwired/turbo#1217`](https://github.com/hotwired/turbo/pull/1217), 2024-03-03 (merged):

> The initial implementation aims to replace the ad hoc configurations spread across `window.Turbo` and `Turbo.session`. Those objects shouldn't be considered part of the public interface, especially for extension.

And on the burden this places on third-party packages, [2024-10-02](https://github.com/hotwired/turbo/pull/1217#issuecomment-2389300946):

> if you are committed to maintaining support for all historical Turbo version, that decision involves supporting Turbo's full range of interfaces as they evolve. Turbo does not programmatically expose version information to the JavaScript runtime, so packages are left with graceful degradation-style conditionals to serve as safety nets.
>
> […] I do believe that as the package and its interfaces evolve, there will be an evolving minimal threshold version that will serve as a baseline of backwards compatibility.

**3. `[data-turbo-permanent]` should mean permanent everywhere — including Streams.** [`hotwired/turbo#623`](https://github.com/hotwired/turbo/issues/623), 2022-07-06:

> Is this intended behavior? [Permanent elements are a Turbolinks concept](https://github.com/turbolinks/turbolinks/tree/v5.2.0#persisting-elements-across-page-loads), and pre-date Frames and Streams.
>
> Personally, I'm not sure what I'd expect to be "correct" behavior.
>
> On one side of the argument, "permanence" is meaningful during navigation, but might not fit the idea of a Stream operation. On the opposing side, "permanence" could implies that it should be sturdy enough to be immutable in the face of page updates.

He resolved it in favour of the second reading with `#688` (Streams now run through `Bardo.preservingPermanentElements`).

**4. Submitter attributes must be uniformly overridable.** [`hotwired/turbo#690`](https://github.com/hotwired/turbo/pull/690#issuecomment-1243768787), 2022-09-12:

> Every other attribute that modifies a `<form>` submission (`formmethod`, `formaction`, `data-turbo-frame`, `data-turbo-method`, `data-turbo-confirm`) supports overrides from the submitter.
>
> The motivation behind this change is to maintain consistency.

This is a recurring pattern across a dozen of his PRs (`#1`, `#5`, `#16`, `#161`, `#184`, `#381`, `#386`, `#653`, `#676`): the submitter is the authority, not the `<form>`.

**5. Visit beats Refresh when they race.** [`hotwired/turbo#1213`](https://github.com/hotwired/turbo/pull/1213), review reply 2024-03-03:

> Now that you mention it, a `Visit` initiated by a link click is guaranteed to either do nothing (when canceled) or navigated. A form, on the other hand, has the potential to complete and succeed without navigating when handling stream responses. The same is true for a link click with `[data-turbo-stream]`.
>
> Acknowledging that, what *is* the desired order of operations for a Page Refresh that's competing with a Stream form submission?
>
> It feels like the Visit should always win out, since that's requesting the most (and most up-to-date) content. Is that correct?

**6. Drop inlined polyfills; let userland depend on real polyfill packages.** [`hotwired/turbo#908`](https://github.com/hotwired/turbo/pull/908#issuecomment-1513824625), 2023-04-18 (`requestSubmit`; `#909` did `SubmitEvent`):

> Would it be an appropriate stance to consider inlined, built-in polyfills outside the bounds of `turbo@7.4.x`, while encouraging those that need them to depend on third-party packages like [event-submitter-polyfill](https://github.com/idea2app/event-submitter-polyfill) and [form-request-submit-polyfill](https://github.com/javan/form-request-submit-polyfill)?

He reopened the question himself in [Dec 2024](https://github.com/hotwired/turbo/pull/908#issuecomment-2520519335): "@jorgemanrubia @brunoprietog is the removal of this polyfill worth re-considering?"

**7. Reproduce it as a single-file Rails app, or it isn't a bug report.** His signature method. Used on [turbo-rails#367](https://github.com/hotwired/turbo-rails/pull/367#issuecomment-2000033446) to make the frame-breakout acceptance criteria executable (6 numbered criteria + 3 Capybara system tests in ~180 lines), and on [turbo#1135](https://github.com/hotwired/turbo/pull/1135#issuecomment-2064007298) to close out unreproducible reports:

> I tried to reproduce the issues with a single-file Rails application. I'll share the source below. Could you save it locally as `bug.rb`, then execute it with `ruby bug.rb`? Once you have it executing and passing, could you modify it to more closely reflect your scenarios?

He also upstreamed the practice: `turbo-rails#593` "Create executable bug report Rails application", and `rails/rails` `#49986` (actionview), `#50004` (actionmailer), `#50010` (actiontext, still open), `#50913` (activesupport) bug-report templates.

**8. Progressive enhancement / platform-first as the tiebreaker.** Seen repeatedly:
- [`turbo#257`](https://github.com/hotwired/turbo/issues/257#issuecomment-1143999625): compose `<a href data-turbo-action data-turbo-frame>` rather than invent `data-turbo-navigation-*-value` attributes — "by relying on built-in platform features and their Tubro-powered extensions, we can cut down on the amount of machinery involved."
- [`turbo#1319`](https://github.com/hotwired/turbo/pull/1319#issuecomment-2371348099): wary of "combinatory explosion of `[data-turbo-*]` attributes", but wants something "declarative, relies on progressive enhancement and graceful degradation".
- [`turbo#654`](https://github.com/hotwired/turbo/pull/654), `#1035`, `#199`: quote the WHATWG/W3C spec text and implement it rather than invent Turbo-specific semantics.
- [`rails/rails#41656`](https://github.com/rails/rails/pull/41656) "Implement Tag Helpers with Nokogiri", `#49390` "Define `TagBuilder` methods for known HTML Elements", `#49369` "Reduce public API of `tag` helper" — the same instinct applied to Action View.

**9. `turbo:frame-missing` should give you the response, not re-fetch it.** [`turbo#445`, 2021-11-18](https://github.com/hotwired/turbo/pull/445#issuecomment-973011662):

> I've extended the `turbo:frame-missing` to yield a callable `visit()` function that knows how to transform the `FetchResponse` into a visit. Callers can pass additional `VisitOptions` like `action:` to the function.

But he flagged the design tension it exposes ([review on `#445`, 2022-08-01](https://github.com/hotwired/turbo/pull/445)):

> Since servers (like Rails) can [respond to Frame requests with incomplete HTML documents](https://github.com/hotwired/turbo-rails/pull/232), I'm unsure about how to best handle a response without a matching frame.
>
> I'm not sure whether or not Drive should re-use the response HTML or issue a new request to fetch a _full_ page of content. My gut tells me to always make a full request, but I'm curious if there's a quick win I'm not considering.

That tension is *exactly* what turbo-rails#534 (render full documents for frame requests) proposes to eliminate — the two threads are the same argument, two years apart.

**10. Ship it as an external package first, then upstream if it wins.** [`stimulus#460`, 2022-08-27](https://github.com/hotwired/stimulus/pull/460#issuecomment-1229221860) / [#1229223068](https://github.com/hotwired/stimulus/pull/460#issuecomment-1229223068):

> I'm closing this in favor of exploring this behavior in an external package first: https://github.com/seanpdoyle/stimulus-mutation.
>
> Starting with an external package enables consumers to pick and choose the way they interact with the observers: either callbacks or Actions with [data-mutation] routing declarations. Ideally, one or the other would win out, and the maintenance burden would be halved. Having said that, I'd be open to supporting both styles.

Also, before proposing any Stimulus API he asks users to justify the shape ([2022-08-28](https://github.com/hotwired/stimulus/pull/460#issuecomment-1229445505)):

> Could you both share an example of a use case you imagine would be simplified by this feature? How are you achieving that outcome now? Which style do you prefer: the callbacks or the data-action mutation descriptor routing?

---

### Structural note on his upstream position

A pattern worth recording: on the three biggest questions he has raised — server-driven frame breakout (`turbo-rails#367`, `turbo#694`), full-document frame responses (`turbo-rails#534`), and turn-key morph/Stimulus integration (`turbo#1210`, `turbo#1097` follow-through) — **his proposals are open and unanswered, in some cases for four years.** Several of his most-referenced PRs sit open indefinitely (`#622` permanent-element render event, `#430` FrameVisit extraction, `#1000` public-API reduction, `#1287` stream-source reconnection, `#210` 4xx-in-frame). His comments repeatedly show him pinging maintainers for review ("@afcapel @jorgemanrubia are either of you available to review this change?" appears verbatim across at least five threads). He is simultaneously the most prolific contributor to Turbo and the one whose architectural proposals most consistently stall.

---

## Blog posts, other repos, Rails core


Sources: thoughtbot author page (`https://thoughtbot.com/blog/authors/sean-doyle`, 2 pages,
15 posts total — RSS feeds returned HTTP 406 to curl-impersonate and were abandoned in favor
of the paginated author page + tag pages), `gh` (authenticated), and raw.githubusercontent.com
READMEs. WebSearch was not used (broken per instructions).

---

### Blog posts

All 15 posts thoughtbot's author-listing attributes to Sean Doyle (page 1 + page 2, confirmed
no page 3). Sorted newest first.

| # | Title | Date | URL |
|---|---|---|---|
| 1 | Dynamic forms with Turbo | 2022-02-02 | https://thoughtbot.com/blog/dynamic-forms-with-turbo |
| 2 | Dynamic forms with Stimulus | 2022-02-01 | https://thoughtbot.com/blog/dynamic-forms-with-stimulus |
| 3 | Integration Testing with Capybara | 2021-11-03 | https://thoughtbot.com/blog/integration-testing-with-capybara |
| 4 | Hotwire: Typeahead searching | 2021-09-17 | https://thoughtbot.com/blog/hotwire-typeahead-searching |
| 5 | Hotwire: Server-rendered live previews | 2021-09-14 | https://thoughtbot.com/blog/hotwire-server-rendered-live-previews |
| 6 | Full-text search with PostgreSQL and Action Text | 2021-05-17 (updated 2025-01-10) | https://thoughtbot.com/blog/full-text-search-with-postgres-and-action-text |
| 7 | Teaming up with Codecademy to bring you Test-Driven Development (co-author: George Brocklehurst) | 2018-01-19 | https://thoughtbot.com/blog/teaming-up-with-codecademy-to-bring-you-test-driven-development |
| 8 | Don't Worry, There's a Method to the Meeting (co-author: Keiran King) | 2020-04-17 | https://thoughtbot.com/blog/method-to-my-meeting |
| 9 | Hound Checks JavaScript Code Style | 2015-12-02 (updated 2023-08-18) | https://thoughtbot.com/blog/hound-checks-javascript-code-style |
| 10 | Destructuring Parameters in Ember.Helpers | 2015-07-20 (updated 2025-02-06) | https://thoughtbot.com/blog/destructuring-parameters-in-ember-helpers |
| 11 | Migrating FormKeep to ember-cli-rails | 2015-06-18 (updated 2019-03-23) | https://thoughtbot.com/blog/migrating-formkeep-to-ember-cli-rails |
| 12 | Embracing Ember: Routes | 2015-03-05 (updated 2025-02-06) | https://thoughtbot.com/blog/embracing-ember-routes |
| 13 | Validating the FormKeep API | 2015-10-12 (updated 2019-03-23) | https://thoughtbot.com/blog/validating-the-formkeep-api |
| 14 | Contributing to Big Bad Open Source | 2015-01-05 (updated 2019-03-25) | https://thoughtbot.com/blog/contributing-to-big-bad-open-source |
| 15 | Use Git Hooks to Automate Necessary but Annoying Tasks | 2014-09-17 (updated 2019-03-06) | https://thoughtbot.com/blog/use-git-hooks-to-automate-annoying-tasks |

### IMPORTANT correction re: task's title list

Several titles named in the task brief do **not** exist as Sean Doyle thoughtbot posts. I
cross-checked the `hotwire`, `stimulus`, and `turbo` tag archive pages (all posts, any author)
to be sure these weren't simply missing from author pagination:

- **"Hotwire: Asynchronously loading tooltips"** exists (`/blog/hotwire-asynchronously-loaded-tooltips`)
  but is authored by **Steve Polito**, not Sean Doyle (confirmed via the post's byline link
  `/blog/authors/steve-polito`). Not included above.
- "Hotwire: Modals", "Hotwire: Inline editing", "Hotwire: Pagination", "Hotwire: Multi-step
  forms", and "Hotwire: HTML over the wire" do not exist as thoughtbot post slugs/titles by
  anyone, Sean Doyle or otherwise, as far as the tag archives show. They may be titles you're
  thinking of from other thoughtbot Hotwire series posts (there are non-Sean-Doyle authors
  writing prolifically in the tag) or external talks — I did not find them on thoughtbot.com.
- "Hotwire: Dynamic form fields" and "Hotwire: Live previews as you type" are close
  paraphrases of the real titles **"Dynamic forms with Stimulus"/"Dynamic forms with Turbo"**
  and **"Hotwire: Server-rendered live previews"** (which has an H2 section literally titled
  "Live previews as you type") respectively — these are the same posts, not separate ones.
- The `field_id`/`field_name` topic is not a dedicated blog post; it's covered as a
  supporting technique inside "Dynamic forms with Stimulus" and "Dynamic forms with Turbo"
  (see below), and is primarily a **Rails core contribution** (see Task C).
- The ARIA/accessible-combobox topic is likewise not a dedicated thoughtbot post; it's a
  section of "Hotwire: Typeahead searching" (WAI-ARIA `role="combobox"` pattern via
  `@github/combobox-nav`), and much more fully realized in his own repo
  `stimulus_aria_widgets` (Task B).

### Deep dives — posts that do NOT duplicate a hotwire-example-template branch

**"Full-text search with PostgreSQL and Action Text"** (2021-05-17, updated 2025-01-10)
Not part of the branch list; ships its own standalone repo (`seanpdoyle/action-text-postgres-full-text-search`).
Summary: builds progressively from `ILIKE` string matching → stripping HTML via a
`plain_text_body` mirror column populated in a `before_save` callback calling
`ActionText::RichText#to_plain_text` → true Postgres full-text search with
`to_tsvector`/`websearch_to_tsquery` and a GIN index → generalizes the whole pattern via
`ActiveSupport.on_load(:action_text_rich_text)` so any model with `has_rich_text` gets it.
Key snippets transcribed:
```ruby
class Article < ApplicationRecord
  has_rich_text :content
  before_save { content.plain_text_body = content.body.to_plain_text }
  scope :with_content_containing, ->(query) { joins(:rich_text_content).merge(ActionText::RichText.where <<~SQL, query) }
    to_tsvector('english', plain_text_body) @@ websearch_to_tsquery(?)
  SQL
end
```
```ruby
# config/initializers/action_text_rich_text.rb
ActiveSupport.on_load :action_text_rich_text do
  before_save { self.plain_text_body = body.to_plain_text }
  scope :with_body_containing, ->(query) { where <<~SQL, query }
    to_tsvector('english', plain_text_body) @@ websearch_to_tsquery(?)
  SQL
end
```
GIN index migration:
```ruby
add_index :action_text_rich_texts, "to_tsvector('english', plain_text_body)", using: :gin, name: "tsvector_body_idx"
```

**"Integration Testing with Capybara"** (2021-11-03) — Not part of the branch list.
Directly relevant to accessibility testing philosophy: argues for Capybara-style semantic
finders (`assert_field "Email address"`, `assert_button "Sign in"`) over brittle CSS-ID-based
`assert_select`, explicitly citing WCAG label requirements ("that field is labeled with the
text 'Email address'" links to WCAG "Text labels and names" guidance). Shows how to graft
`Capybara::Session`/`Capybara::Minitest::Assertions` onto `ActionDispatch::IntegrationTest` via
an `ActiveSupport.on_load(:action_dispatch_integration_test)` hook so integration tests get
Capybara's label-aware finders without the overhead of a full System Test/real browser:
```ruby
require "capybara/minitest"
ActiveSupport.on_load :action_dispatch_integration_test do
  include(Module.new do
    extend ActiveSupport::Concern
    included do
      include Capybara::Minitest::Assertions
      delegate :within, to: :page
      setup do
        integration_session.extend(Module.new do
          def page
            @page ||= ::Capybara::Session.new(:rack_test, @app)
          end
          def _mock_session
            @_mock_session ||= page.driver.browser.rack_mock_session
          end
        end)
      end
    end
  end)
end
```
This pattern (`with_form`/label-driven Capybara helpers, testing by what a screen reader would
perceive rather than DOM structure) reappears years later as his standalone `with_form` gem
(Task B).

### Posts that duplicate a hotwire-example-template branch (still summarized, not deep-dived further than shown)

**"Dynamic forms with Stimulus"** (2022-02-01) — duplicates the `stimulus-dynamic-forms`
branch (article explicitly links `hotwire-example-template/tree/hotwire-example-stimulus-dynamic-forms`).
Builds a Document form (publish/draft/passcode-protected access levels) where a "passcode"
`<fieldset>` is conditionally shown/enabled. Progression: (1) no-JS baseline using
`<fieldset disabled>` + `:disabled` CSS pseudo-class, (2) no-JS dynamic re-render via a hidden
`<button formmethod="get" formaction="...">` that resubmits as a `GET` to re-render with the
selected state, (3) JS via a `fields` Stimulus controller that toggles `[disabled]` fieldsets
based on `aria-controls`/`field_id`-generated ids and `field_name`-generated matching `[name]`
attributes. Notably uses `aria-controls` explicitly as the synchronization mechanism between
the selected radio and its dependent fieldset — an accessibility-aware technique, not just a
JS hook:
```erb
<%= builder.radio_button autocomplete: "off",
                         aria: { controls: form.field_id(:access, builder.value, :fieldset) },
                         data: { action: "input->fields#enable" } %>
```
```js
// app/javascript/controllers/fields_controller.js
export default class extends Controller {
  enable({ target }) {
    const elements = Array.from(this.element.elements)
    for (const element of elements.filter(element => element.name == target.name)) {
      if (element instanceof HTMLFieldSetElement) element.disabled = true
    }
    for (const element of controlledElements(target)) {
      if (element instanceof HTMLFieldSetElement) element.disabled = false
    }
  }
}
function controlledElements(...selectedElements) {
  return selectedElements.flatMap(el => getElementsByTokens(el.getAttribute("aria-controls")))
}
```

**"Dynamic forms with Turbo"** (2022-02-02) — duplicates the `turbo-dynamic-forms` branch
(`hotwire-example-turbo-dynamic-forms`). Builds a country→state cascading `<select>` pair.
Progression: no-JS GET-resubmit via a `<noscript>`-wrapped button → JS clicks a hidden button
programmatically on `change` → swaps to `<turbo-frame>` scoped to just the state field
(`field_id(:state, :turbo_frame)`) so page focus/scroll survive → adds a `<turbo-stream
action="replace">` inside the frame to also refresh an out-of-frame "estimated arrival"
fragment in the same round trip. Key `field_id` usage:
```erb
<turbo-frame id="<%= form.field_id(:state, :turbo_frame) %>" class="contents">
```
```erb
<%= turbo_stream.replace dom_id(@address), partial: "addresses/address", object: @address %>
```

**"Hotwire: Server-rendered live previews"** (2021-09-14) — duplicates the `live-preview`
branch (`hotwire-example-live-preview`). Article draft page that live-previews rendered
content. Progression: `<button formaction="/previews">` posts a preview request and
redirects back with content in query params → adds Turbo Stream response
(`turbo_stream.update params[:render_into]`) so the preview updates in place → adds a `form`
Stimulus controller listening for `input` events that programmatically clicks a hidden
"Preview" button (debounced with lodash), with `connect() { this.previewTarget.hidden = true }`
for progressive-enhancement (button visible without JS, hidden and auto-triggered with JS).
The section literally titled "Live previews as you type" is this progressive-enhancement step.

**"Hotwire: Typeahead searching"** (2021-09-17) — duplicates the `typeahead-search` branch
(`hotwire-example-typeahead-search`). Builds a collapsible search-as-you-type box.
Progression: plain `<form method=get>` full-page search → `<turbo-frame id="search_results">`
scoped navigation via `data-turbo-frame` → hides results when input invalid using
`required pattern=".*\w+.*"` Constraint Validation + `:invalid`/`:empty` CSS pseudo-classes,
suppressing the browser's native validation bubble by intercepting the non-bubbling `invalid`
event with `data-action="invalid->form#hideValidationMessage:capture"` → **keyboard
navigation/selection built explicitly on the WAI-ARIA `role="combobox"` Authoring Practices
pattern**, delegating the actual keyboard logic to GitHub's `@github/combobox-nav` package via
a `combobox` Stimulus controller, with `autocomplete="off"` on the input to suppress native
browser autocomplete UI from conflicting with the custom listbox. This is his most directly
accessibility-relevant blog post besides the form-fieldset one.

### Other posts (brief, non-Hotwire, no duplication concern)

- **"Hound Checks JavaScript Code Style"** (2015-12-02) — thoughtbot's Hound linter adds JSCS
  support to replace deprecated JSHint style rules.
- **"Destructuring Parameters in Ember.Helpers"** (2015-07-20) — Ember 1.13's `Ember.Helper`
  API and how its `compute(params, hash)` signature enables destructuring-style helper code.
- **"Migrating FormKeep to ember-cli-rails"** (2015-06-18) — migrating FormKeep's Ember admin
  dashboard from `ember-rails` to `ember-cli-rails` for a cleaner client/server split while
  keeping end-to-end JS Capybara integration tests working.
- **"Embracing Ember: Routes"** (2015-03-05) — refactoring a Stripe-payment modal dialog in
  FormKeep from ad hoc component state into Ember's routing layer for maintainability.
- **"Validating the FormKeep API"** (2015-10-12) — using thoughtbot's `json_matchers` gem in
  RSpec request specs to contract-test FormKeep's JSON API consumed by its Ember admin app.
- **"Contributing to Big Bad Open Source"** (2015-01-05) — a narrative/how-to about making his
  first contributions to Ember.js, encouraging others past the fear of contributing upstream.
- **"Use Git Hooks to Automate Necessary but Annoying Tasks"** (2014-09-17) — thoughtbot's
  dotfiles-provided git hooks (post-checkout/post-merge) to auto-run bundle install, migrations,
  ctags reindexing, etc.
- **"Don't Worry, There's a Method to the Meeting"** (2020-04-17, co-author Keiran King) —
  non-technical: thoughtbot's IPM/retrospective meeting cadence and Shape Up-style planning.
- **"Teaming up with Codecademy to bring you Test-Driven Development"** (2018-01-19, co-author
  George Brocklehurst) — non-technical announcement of a TDD course partnership.

---

### Other repos

`gh repo list seanpdoyle --limit 200 --json name,description,updatedAt,stargazerCount,isFork --source`
returned 50 non-fork source repos. `gh search repos --owner seanpdoyle` confirms the same
account, no additional orgs of note (only org membership found: `castequality`, unrelated).
No dedicated "combobox" or "autocomplete" repo exists under his account by name — his
accessible-combobox work lives inside **stimulus_aria_widgets** instead (see below). Also
checked gists and orgs for any hidden a11y work; nothing further surfaced.

Top repos by stars (all confirmed Rails/Hotwire/a11y relevant, excludes forks):

| Stars | Repo | Description |
|---|---|---|
| 51 | turbo_stream_button | Harness Turbo Streams to declare click handlers as HTML mutations |
| 37 | constraint_validations | Integrates ActiveModel::Validations + ActionView + browser Constraint Validation API |
| 37 | action_view-attributes | (undescribed; ActionView attribute-building utility) |
| 33 | view_partial_form_builder | Construct `<form>`s/fields by combining FormBuilder with View Partials |
| 28 | attributes_and_token_lists | (undescribed; Hash/Set-like Attributes & TokenList primitives) |
| 19 | select-your-own-seat | (demo app) |
| 17 | stimulus_aria_widgets | Stimulus controllers + ARIA-widget server helpers (combobox, disclosure, dialog, feed, tabs, grid) |
| 14 | styled_helpers | (undescribed) |
| 12 | stimulus-mutation | Route DOM mutations to attributes/child lists like Events |
| 5 | with_form | "Your System Test's counterpart to `form_with`" — label-driven Capybara form helpers |
| 0 | a11y-todos | (small a11y-named demo, 0 stars) |
| 0 | rails-ujs-validation-example | Combine client/server validation via browser Constraint Validation API |

### Top 5 deep dives (READMEs fetched from `raw.githubusercontent.com/.../main/README.md`)

**1. `stimulus_aria_widgets`** — https://github.com/seanpdoyle/stimulus_aria_widgets
This is his most direct, explicit accessibility deliverable. README states its purpose plainly:
"The [Accessible Rich Internet Applications Authoring Practices 1.1] provide guidance for
implementing commonly occurring web widgets in accessible ways. This engine aims to provide
server-side helpers that generate HTML with the appropriate attributes to correspond with a
suite of client-side Controllers." It ships server-side helper builders (an `aria` helper
returning `Attributes`/`TokenList` instances from the sibling `attributes_and_token_lists` gem)
paired with Stimulus controllers for six WAI-ARIA APG patterns:
- **Combobox** (`ComboboxController`) — `role="combobox"`/`listbox`/`option`, `autocomplete="off"`,
  actions `expand`/`collapse`/`navigate`. Example:
  ```erb
  <%= aria.combobox.tag.form data: { turbo_frame: "names" } do |builder| %>
    <label for="query">Names</label>
    <input id="query" <%= builder.combobox_target.merge aria: { expanded: params[:query].present? } %> type="search" name="query">
    <turbo-frame <%= builder.listbox_target %> id="names">
      <%= builder.option_target.tag.button name, type: "button", id: "name_#{id}", aria: { selected: id.zero? } %>
    </turbo-frame>
  <% end %>
  ```
- **Disclosure** — toggles `<details>`, `[hidden]`, or a CSS class; renders `<button>` by default.
- **Dialog** — `role="dialog"`, wraps native `<dialog>` + `wicg-inert`/`dialog-polyfill` for
  browsers lacking `<dialog>`/`[inert]` support; `showModal`/`close` actions.
- **Feed** — `role="feed"` + arrow-key `navigate` action across `article` targets.
- **Tabs** — `role="tablist"/"tab"/"tabpanel"`, keyboard `navigate` + click `select`.
- **Grid** — `role="grid"/"row"/"gridcell"`, full 2D arrow-key/Home/End navigation with
  per-direction JSON param maps (`data-grid-directions-param`).
Ships as a Rails engine, installable via importmap-rails or npm/yarn, configurable helper
method name (`config.stimulus_aria_widgets.helper_method`).

**2. `turbo_stream_button`** — https://github.com/seanpdoyle/turbo_stream_button (51 stars, most
starred repo). Lets a plain `<button>` declare its own Turbo Stream mutations inline in a
nested `<template>`, evaluated client-side on click via a Stimulus controller — no server
round-trip needed for pure client-side DOM changes expressed as Turbo Stream actions. Ships
`turbo_stream_button_tag` and a lower-level `turbo_stream_button` attributes-builder helper;
demonstrates nesting (a flash message with an embedded "Dismiss" button that removes itself)
and composing with other Stimulus controllers (e.g., clipboard-copy).

**3. `constraint_validations`** — https://github.com/seanpdoyle/constraint_validations (37
stars). README opens with an explicit accessibility framing: "The current Action View default
configurations for `<form>` element construction don't create accessible forms and fields...
This work explores some possible extensions to Action View that could improve Rails' baked-in
accessibility." Provides a `ConstraintValidations::FormBuilder` with
`validation_message_template`/`validation_message`/`validation_message_id` helpers that render
error `<span>`s wired to fields via `aria-describedby`, plus a client-side JS layer
(`ConstraintValidations`) that integrates server-rendered ActiveModel error messages with the
browser's native Constraint Validation API / `ValidityState`, including an experimental
technique for validating grouped `<input type="checkbox">` sets by swapping `[required]` for
`[aria-required="true"]` since native `required` semantics don't support "at least one of N"
checkbox groups.

**4. `view_partial_form_builder`** — https://github.com/seanpdoyle/view_partial_form_builder
(33 stars). A `FormBuilder` subclass that resolves each field-helper call (e.g. `text_field`,
`button`) to a corresponding Rails View Partial (`app/views/application/form_builder/_text_field.html.erb`)
if one exists, falling back to default FormBuilder behavior otherwise, with partial resolution
scoped/overridable per-model (`app/views/posts/form_builder/_text_field.html.erb` beats the
application-wide default). Enables design-system-style centralized field styling without
overriding FormBuilder methods in Ruby.

**5. `with_form`** — https://github.com/seanpdoyle/with_form (5 stars, but directly continues
the accessibility-testing philosophy of the "Integration Testing with Capybara" blog post).
"Your System Test's counterpart to `form_with`." Provides a `with_form(scope:)`/`with_form(model:)`
block-scoped Capybara helper that fills/checks/submits forms purely by their **translated
`<label>` text** (Rails i18n `helpers.label.*`/`helpers.submit.*` keys) rather than field ids
or CSS — the same label-first, screen-reader-parity philosophy as his Capybara integration-test
post. Also adds a `fill_in_rich_text_area` helper for Action Text's `<trix-editor>`, explicitly
noting the a11y gap: `<trix-editor>` isn't a native form field, so `<label for="...">`
association doesn't focus it — his workaround requires the `<trix-editor aria-label="...">`
attribute to mirror the label text so Capybara/screen readers can still resolve it:
```erb
<%= form.label :my_rich_text_field %>
<%= form.rich_text_area :my_rich_text_field, "aria-label": translate(:my_rich_text_field, scope: "helpers.label.post") %>
```

---

### Rails core contributions

`gh search prs --author seanpdoyle --repo rails/rails` (paginated both `--sort created --order
asc` and `desc`, 100 each, deduplicated) plus `gh api search/issues` count checks:
- **237** total PRs authored (open + closed + merged)
- **149** merged PRs (confirmed via `gh api search/issues -f q="repo:rails/rails is:pr
  author:seanpdoyle is:merged" --jq .total_count` = 149, matching the deduplicated list exactly)
- Active from **2020-02-22** (#38549) through **2026-06-24** (#57843, most recent merge at time
  of research) — a 6+ year, still-ongoing contribution history.

He is the clear author of Rails' `field_id`/`field_name` form-builder helpers, plus a long
thread of ARIA-attribute-serialization, `button_to`, `form_for`/`form_with` unification, and
Action View `TagBuilder`/FormBuilder internals work. The 12 most substantive merged PRs (fetched
full bodies via `gh pr view --json title,body,mergedAt,url`):

1. **#40127 — Declare `ActionView::Helpers::FormBuilder#id` and `#field_id`** (merged
   2020-12-01) — https://github.com/rails/rails/pull/40127. The founding PR for this whole
   family. Quote: "Generate an HTML `id` attribute value... Return the value generated by the
   `FormBuilder` for the given attribute name," with the now-canonical accessibility example:
   ```erb
   <%= f.text_field :title, aria: { describedby: f.field_id(:title, :error) } %>
   <span id="<%= f.field_id(:title, :error) %>">is blank</span>
   ```

2. **#43409 — Introduce `field_name` view helper** (merged 2021-11-15) —
   https://github.com/rails/rails/pull/43409. `field_name`'s companion to `field_id`. Quote:
   "provide[s] an Action View-compliant way of overriding a form field element's `[name]`
   attribute (similar to `field_id`...)."
   ```ruby
   text_field_tag :post, :tag, name: field_name(:post, :tag, multiple: true)
   # => <input type="text" name="post[tag][]">
   ```

3. **#43408 — Implement `field_id` in terms of the FormBuilder's `namespace:` option** (merged
   2021-12-14) — https://github.com/rails/rails/pull/43408. Fixes `field_id` ignoring
   `namespace:` by prepending it to `@object_name`.

4. **#45366 — Support calls to `#field_name` with nil `object_name`** (merged 2022-06-15) —
   https://github.com/rails/rails/pull/45366. Fixes a crash (`undefined method 'empty?' for
   nil:NilClass`) when `field_name` is called from bare `fields`/`fields_for` blocks; swaps
   `String#empty?` for `Object#blank?`.

5. **#47436 — Don't double-encode nested `field_id` and `field_name` index** (merged
   2023-07-02) — https://github.com/rails/rails/pull/47436. Fixes nested-attributes index
   duplication bug (`parent[children_attributes][0][0][grandchildren_attributes][]`), closing
   issue #45483; reads `index:` from `@options` instead of the stale `@index` ivar.

6. **#40479 — Serialize aria- namespaced list attributes** (merged 2020-10-30) —
   https://github.com/rails/rails/pull/40479. Makes `aria: { labelledby: [...] }` serialize as
   a proper space-delimited token list instead of JSON, and serializes `true`/`false` as the
   strings `"true"`/`"false"` since "there are no boolean `aria-` attributes."

7. **#40499 — ARIA attributes: serialize empty Hash and Array as nil** (merged 2020-11-01) —
   https://github.com/rails/rails/pull/40499. Follow-up so a conditional
   `aria: { describedby: { error_id: has_error? } }` correctly omits the attribute entirely
   when false/empty, directly enabling clean conditional `aria-describedby` patterns for error
   messaging.

8. **#40747 — Consistently render `button_to` as `<button>`** (merged 2020-12-29) —
   https://github.com/rails/rails/pull/40747. Unifies `button_to`'s previously-inconsistent
   `<input type="submit">` vs `<button>` output (String arg vs block arg) so it always renders
   `<button>`, enabling richer `[value]`-encoded submitter data; adds
   `config.action_view.button_to_generates_button_tag` escape hatch for the old behavior.

9. **#43413 — Make `button_to` more model-aware** (merged 2021-11-15) —
   https://github.com/rails/rails/pull/43413. Infers HTTP verb from a model's `persisted?`
   state when `button_to` is given a model + block:
   ```ruby
   button_to(Workshop.find(1)) { "Update" }
   # => <form method="post" ...><input type="hidden" name="_method" value="patch" ...>
   ```

10. **#43421 — Implement `form_for` by delegating to `form_with`** (merged 2021-11-19) —
    https://github.com/rails/rails/pull/43421. Consolidates the two form-building code paths
    (and `fields_for`/`fields`) to reduce divergence/duplication between the legacy and modern
    form helper APIs.

11. **#50239 — Batch define `FormBuilder` methods with `CodeGenerator`** (merged 2023-12-02) —
    https://github.com/rails/rails/pull/50239. Internal perf/correctness cleanup so
    `ActiveSupport::CodeGenerator.batch` avoids invoking class-extension hooks more than once
    per FormBuilder method definition.

12. **#52467 — Rename `text_area` to `textarea` and `rich_text_area` to `rich_textarea`**
    (merged 2024-07-31) — https://github.com/rails/rails/pull/52467. Aligns Rails' helper
    naming with the actual HTML element name (`<textarea>`), with back-compat aliases
    preserved.

Other notable merged work visible in the full 149-PR list worth flagging even without full
bodies pulled: `#49369`/`#49390`/`#50320` (TagBuilder public API reduction + dasherized keyword
attribute rendering), `#48857` (`fixture_file_upload` → `file_fixture_upload` rename),
`#53686`/`#55666` (`fill_in_rich_text_area` Capybara-selector work — same territory as the
`with_form` gem), `#47318` (guards Stimulus `data-action` from double-escaping via `token_list`),
and a long, ongoing 2023–2026 stream of Action Text / ActiveModel / TagBuilder maintenance work.

---

### Accessibility guidance (Hotwire + a11y specifically)

Everything found on: ARIA-live-region announcements for Turbo Stream updates, focus management
after Turbo navigations, accessible comboboxes, `role=`/`aria-*` in server-rendered HTML,
accessible modals/dialogs, screen-reader announcement of async updates, keyboard interaction.

- **ARIA in server-rendered HTML is core to how he writes Rails helpers**, not an afterthought:
  the `field_id`/`field_name` Rails PRs exist specifically to make `aria-describedby`/
  `aria-controls` referencing reliable and DRY (#40127's own example is an `aria-describedby`
  error pattern), and #40479/#40499 fix ARIA-specific serialization bugs (list-valued and
  boolean/empty `aria-*` attributes) that are meaningless outside an accessibility context.
- **Accessible comboboxes are his most concentrated, explicit deliverable**: "Hotwire:
  Typeahead searching" builds one on the WAI-ARIA APG `role="combobox"` pattern using GitHub's
  `@github/combobox-nav`, and `stimulus_aria_widgets` productizes a full combobox (plus
  disclosure, dialog, feed, tabs, and grid) widget suite as paired server helpers + Stimulus
  controllers, explicitly scoped to the WAI-ARIA Authoring Practices 1.1 patterns.
- **Modals/dialogs**: `stimulus_aria_widgets`'s `DialogController` wraps the native `<dialog>`
  element (`role="dialog"`, `aria-modal="true"`) and explicitly documents polyfilling for
  browsers lacking `<dialog>`/`[inert]` support (`wicg-inert`, `dialog-polyfill`), combined with
  the Disclosure pattern for the opening trigger.
- **Keyboard interaction patterns**: implemented per-widget in `stimulus_aria_widgets` — arrow
  keys for Tabs, 2D grid navigation (arrows/Home/End) for Grid, arrow-key article navigation
  for Feed, and combobox open/close/navigate — all driven by declarative `data-action`
  descriptors rather than bespoke event-listener code in application JS.
- **Focus management**: less of a dedicated writeup, but present as a working concern — e.g.
  in "Dynamic forms with Turbo," swapping fields into a `<turbo-frame>` (vs. full-page reload)
  is explicitly framed as preserving focus/scroll state through the interaction; a merged (then
  reverted) Rails PR (#46249/#46808) attempted to auto-focus the Trix editor after
  `fill_in_rich_text_area` in tests.
- **Native browser mechanisms over custom JS/ARIA-only patches**: a consistent thread across
  the blog series is prefer HTML form semantics (`<fieldset disabled>`, Constraint Validation
  API, `formmethod`/`formaction`) and only add `aria-*`/`role` attributes where the native
  semantics run out — visible in `constraint_validations`' explicit statement that default
  Action View form output "doesn't create accessible forms and fields" and its use of
  `aria-required="true"` as a workaround only where native `[required]` semantics for checkbox
  groups are insufficient.
- **Testing accessibility, not just implementing it**: both "Integration Testing with Capybara"
  and the `with_form` gem treat label-text-based Capybara finders (not DOM ids/CSS) as the
  correct way to exercise forms, on the reasoning that this is closer to how a screen-reader
  user or WCAG auditor would identify a field — and he explicitly documents the current gap in
  `<trix-editor>` accessibility (no native label association) with a workaround via
  `aria-label`.
- No dedicated writing found on ARIA **live regions for Turbo Stream announcements** or on
  Turbo-navigation focus-management as a standalone topic/post — these appear only as embedded
  concerns inside the form/combobox work above, not as their own artifacts.
## Accessibility guidance

Doyle's reputation for accessibility is deserved, but it is worth being precise about *what kind* of
accessibility work this corpus contains, because it is not what you would guess. He almost never
writes ARIA. He writes **semantic HTML that already has the semantics**, and where a genuine ARIA
widget is unavoidable he **delegates the state machine to a tested library**. That's the bar
crosswire should set.

### Rule 1 — Prefer the element that already has the behaviour

| Need | His answer | What he did *not* do |
|---|---|---|
| Modal | `<dialog>` + `showModal()` | Hand-rolled focus trap. **There is zero focus-management JS on the modal branch.** |
| Close a modal | `<form method="dialog">` | A `close()` Stimulus action |
| Disclosure | `<details>` / `<summary>` (links the ARIA APG disclosure pattern by URL) | `aria-expanded` + click handlers |
| Group of related fields | `<fieldset>` + `<legend>` | `<div role="group" aria-labelledby>` |
| Conditionally-inactive fields | `<fieldset disabled>` + `:disabled` CSS | `.hidden` class toggling |
| Validation errors | `<output role="alert">` | A manually-authored `aria-live` region |
| Dismissible alert | `<div role="alert">` | `aria-live="assertive"` |
| Tooltip | `<turbo-frame role="tooltip">` + `aria-describedby` on the trigger, shown by CSS `peer-hover:`/`peer-focus:`/`focus-within:` | A JS tooltip library |

The `<fieldset disabled>` choice deserves special emphasis because it is the one that most changes
how you'd write a Rails form. `[disabled]` is not decoration — **disabled fields are excluded from
the form submission**. So the visual state, the ARIA state, and the wire format all derive from one
attribute and cannot disagree. Compare with the industry-standard `classList.toggle("hidden")`,
where a hidden field still submits its value and your validations have to defend against it.

### Rule 2 — Let the ARIA attribute *be* the application wiring

The `fields` controller in `stimulus-dynamic-forms` finds what to toggle by reading
`aria-controls` off the changed input:

```javascript
function controlledElements(...selectedElements) {
  return selectedElements.flatMap(selectedElement =>
    getElementsByTokens(selectedElement.getAttribute("aria-controls"))
  )
}
```

If someone deletes the `aria-controls`, the *feature* breaks, not just the screen-reader experience.
That is the strongest available guarantee that an ARIA annotation stays correct. Same idea in the
kanban branch, where drop targets are located by `[aria-dropeffect="move"]`, and in the tests, which
locate elements by ARIA role rather than CSS class:

```ruby
within :modal do ... end
assert_selector :alert, "To can't be blank"
toggle_disclosure "New message", expand: true
within(:alert, "Copied to clipboard") { click_on "Dismiss" }
assert_no_selector :alert, "Copied to clipboard"
within :fieldset, "Personal references" do ... end
assert_no_button(focused: true)
```

**Adopt this convention wholesale in crosswire.** Capybara's ARIA-role selectors mean a broken role
attribute fails the test suite. It is accessibility enforcement that costs nothing extra.

### Rule 3 — Don't hand-roll a combobox

Two branches build combobox/autocomplete UI (`typeahead-search`, `action-text-mentions`). In both,
his own code sets only the *structural* roles and delegates every piece of dynamic ARIA state to
[`@github/combobox-nav`](https://github.com/github/combobox-nav):

```erb
<ul role="listbox" data-combobox-target="list">
  <%= link_to message, id: dom_id(message, :search_result), role: "option",
              class: "aria-selected:outline-black" %>
</ul>
```

```javascript
this.editorTarget.setAttribute("role", "combobox")   // when expanded
this.editorTarget.setAttribute("role", "textbox")    // when collapsed
```

He quotes the library's contract in prose:

> The Web Accessibility Initiative — Accessible Rich Internet Applications (WAI-ARIA) Authoring
> Practices outline a pattern for this type of behavior: `role="combobox"`.

> Each option needs to have `role="option"` and a unique id. […] The list should have
> `role="listbox"`.

`aria-expanded`, `aria-controls`, `aria-autocomplete` and `aria-activedescendant` **never appear in
his application code at all** — the library owns them. The one place his code *reads*
`aria-activedescendant` is to decide whether a `blur` should be allowed to collapse the popup
mid-keyboard-navigation. That division of labour is the lesson: thin Stimulus controller for
app-specific concerns (Trix cursor math, `hidden` toggling), library for the WAI-ARIA state machine.

Another detail worth stealing: **ARIA state drives the CSS**, via an attribute selector rather than
a parallel class.

```css
.aria-selected\:outline-black[aria-selected="true"] { outline: 2px dotted black; }
```

One source of truth for "which option is active", consumed by both the screen reader and the eye.

### Rule 4 — The implicit-submission hazard

Covered in full under [Pair 1](#pair-1--nested-attributes-turbo-frame-vs-template), but restated
here because it is the a11y bug most Hotwire apps have and nobody talks about: any `<button>` with
`[formaction]` or `[formmethod]` that precedes the real submit button becomes the form's **default
button**, so <kbd>Enter</kbd> in a text field fires the wrong action. Fix:

```erb
<button class="hidden" tabindex="-1" aria-hidden="true"></button>
```

as the form's first child. He has a dedicated keyboard-only system test for it.

### Rule 5 — Focus after async updates is *your* problem (pre-morph)

He names focus loss explicitly as page state to be preserved:

> Navigating with a full-page HTTP redirect after a Form Submission means that any end-user browser
> state will be lost. That state might include: how far they've scrolled within the page; any text
> they've typed into a form; which elements they've collapsed or expanded; **which element has
> focus**.

Three mechanisms appear across the corpus, in increasing order of how much you should like them:

1. **`data-turbo-permanent`** — best. The DOM node is never destroyed, so `document.activeElement`,
   cursor position, and pending IME composition survive by construction. Requires a stable `[id]`.
2. **Turbo Streams that patch only what changed** — focus survives as a side effect, because the
   focused element is never in the replaced subtree. He states this as a benefit:
   *"We retain the rest of our page's state (like scroll depth, partially filled-out fields,
   expanded disclosures, element focus, etc.)."*
3. **A `focus` controller that re-focuses by `id` after a render** — the fallback when a broadcast
   replaces a whole `<section>`. In `kanban-preserve-focus` he attaches `data-controller="focus"` to
   `<html>` with a delegated `click->focus#push` on `<body>`, and gives every participating control
   a `dom_id`-derived stable id (`dom_id card, :up` → `card_42_up`), so the *replacement* button has
   the same id as the destroyed one and can be re-focused. It works, but it is brittle and depends
   on nothing else changing ids.

**Currency note:** Turbo 8 morphing (Feb 2024) largely retires (3) for Turbo *Drive* visits — but
**not** for Turbo Stream broadcasts, which is exactly what the kanban branches use. Morphing is a
Drive-visit reconciliation strategy; a `broadcast_replace_later_to` still does an outerHTML swap
unless you opt the stream into morphing. So this machinery is not simply obsolete — see
[Anything now outdated](#anything-now-outdated).

### Where the corpus falls short (record these as crosswire's gaps to fill)

Be honest about this; several branches have no a11y story at all:

- **No `aria-live` region for Turbo Stream updates, anywhere in the corpus.** `live-preview`,
  `typeahead-search` (result-count changes), `upload-processing`, and `process-network-request` all
  swap content asynchronously with no announcement. A screen-reader user gets silence. `role="alert"`
  on validation output is the only live-region behaviour in the whole repo, and it's implicit.
- **`inline-edit` has no focus management** — a frame swaps a value for an input and focus is not
  moved into it.
- **`drawer` uses `<div role="dialog">` with no focus trap, no Escape handler, no `inert`** — and
  it's the newest branch. (It is also not Doyle's; it is Steve Polito's.)
- **`pagination`/infinite scroll** has no focus or announcement handling for appended content.
- **`kanban` drag-and-drop** has no keyboard-operable equivalent by design; the pre-existing
  "Move up"/"Move down"/"Move to Stage" buttons happen to serve as one because he built them first
  and never removed them. That's the right outcome by accident — but "build the button version
  first, then layer the gesture on top, and never delete the buttons" is a genuinely good rule to
  state deliberately.

---
## The abstraction unit he actually uses (answering the 37signals question)

Sibling research found that five production 37signals codebases independently pair **each Stimulus
controller with an ERB helper**, and nobody documents it. **Doyle does not do this.** Checked
directly: every `app/helpers/*.rb` in the corpus is an empty scaffold stub —

```ruby
module MessagesHelper
end
```

— and several branches were generated with `--no-helper` so the file doesn't exist at all. Every
`data-controller` / `data-action` / `data-*-target` attribute is written **inline in the ERB
template**, always.

His reuse unit is different and, for crosswire's purposes, better: **a yielding partial in
`app/views/application/`**. It is the same idea (one named thing owns the markup contract) but it
composes with `yield`, so the caller supplies content rather than arguments.

The best example is `inline-edit`, which is a complete click-to-edit-any-field feature with **zero
JavaScript**:

```erb
<%# app/views/application/_inline_edit.html.erb %>

<% frame_id = dom_id(model, "#{method}_turbo_frame") %>

<%= form_with model: model, class: "contents", data: { turbo_frame: frame_id } do %>
  <turbo-frame id="<%= frame_id %>" class="contents group inline-edit">
    <%= yield %>

    <%= link_to edit_polymorphic_path(model) do %>
      Edit <%= model.class.human_attribute_name(method) %>
    <% end %>
  </turbo-frame>
<% end %>
```

```erb
<%# app/views/application/_inline_fields.html.erb %>

<% frame_id = dom_id(form.object, "#{method}_turbo_frame") %>

<turbo-frame id="<%= frame_id %>" class="contents">
  <%= yield %>

  <%= form.button class: "hidden group-inline-edit:inline" do %>
    Save <%= form.object.class.human_attribute_name(method) %>
  <% end %>
  <%= link_to "Cancel", polymorphic_path(form.object), class: "hidden group-inline-edit:inline" %>
</turbo-frame>
```

Used from an ordinary `show` and an ordinary `edit`:

```erb
<%# app/views/articles/show.html.erb %>

<section class="grid gap-2 max-w-prose m-auto">
  <%= link_to "Edit Article", edit_article_path(@article) %>

  <%= render "inline_edit", model: @article, method: :name do %>
    <h1><%= @article.name %></h1>
  <% end %>

  <%= render "inline_edit", model: @article, method: :byline do %>
    <span>By: <%= @article.byline %></span>
  <% end %>

  <%= render "inline_edit", model: @article, method: :published_on do %>
    <% if @article.published_on.nil? %>
      <span>(Unpublished)</span>
    <% else %>
      <%= localize @article.published_on, format: :long %>
    <% end %>
  <% end %>

  <%= render "inline_edit", model: @article, method: :content do %>
    <%= @article.content %>
  <% end %>
</section>
```

```erb
<%# app/views/articles/edit.html.erb %>

<%= form_with model: @article, class: "grid gap-2 max-w-prose m-auto" do |form| %>
  <%= link_to "Back", article_path(@article) %>

  <%= render "inline_fields", form: form, method: :name do %>
    <%= form.label :name %>
    <%= form.text_field :name %>
  <% end %>

  <%= render "inline_fields", form: form, method: :byline do %>
    <%= form.label :byline %>
    <%= form.text_field :byline %>
  <% end %>

  <%= render "inline_fields", form: form, method: :published_on do %>
    <%= form.label :published_on %>
    <%= form.date_field :published_on %>
  <% end %>

  <%= render "inline_fields", form: form, method: :content do %>
    <%= form.label :content %>
    <%= form.rich_text_area :content %>
  <% end %>

  <%= form.button %>
<% end %>
```

```javascript
// app/javascript/tailwind.config.js

tailwind.config = {
  corePlugins: { preflight: false },
  plugins: [
    tailwind.plugin(function({ addVariant }) {
      addVariant("group-inline-edit", ".group.inline-edit &")
    })
  ]
}
```

The mechanism is a **shared frame id derived from `(model, attribute)`** on both sides:
`dom_id(model, "#{method}_turbo_frame")`. `show` renders read-only content in frame
`article_1_name_turbo_frame`; `edit` renders that attribute's form fields in a frame with the *same*
id. Clicking "Edit Name" navigates only that frame, so only that field flips to an input — the whole
`edit` page is fetched, and Turbo throws away everything except the matching frame. Save/Cancel
appear because the frame on the `show` side carries `.group.inline-edit` and the buttons are
`group-inline-edit:inline`. Submitting posts back into the same frame via `data-turbo-frame` on the
wrapping `form_with`.

**No controller changes, no new routes, no JSON, no JavaScript.** `edit.html.erb` remains a normal,
fully-working, non-JS edit page. This is the pattern crosswire should hold up as the canonical
"progressive enhancement via matching frame ids" example.

### The other reuse unit: `to_*_partial_path` on the model

Where a partial must be chosen polymorphically he puts the method **on the model**, not in a helper:

```ruby
def to_trix_content_attachment_partial_path
def to_attachable_partial_path
```

and in `grid`, cell renderers are chosen by ActiveRecord column type via
`app/views/application/_string.html.erb`, `_integer.html.erb`, `_boolean.html.erb`.

### …but in his *libraries* he does pair helpers with controllers — extensively

The example repo is deliberately helper-free because it is teaching material: every attribute is
visible in the template so a reader can see the wiring. In his **gems**, he does exactly what the
37signals codebases do, and more rigorously.

**`seanpdoyle/stimulus_aria_widgets`** is a Rails engine whose entire premise is
server-side-helper-paired-with-Stimulus-controller, for six WAI-ARIA APG patterns (combobox,
disclosure, dialog, feed, tabs, grid). Its README states the thesis:

> The Accessible Rich Internet Applications Authoring Practices 1.1 provide guidance for
> implementing commonly occurring web widgets in accessible ways. This engine aims to provide
> **server-side helpers that generate HTML with the appropriate attributes to correspond with a
> suite of client-side Controllers**.

```erb
<%= aria.combobox.tag.form data: { turbo_frame: "names" } do |builder| %>
  <label for="query">Names</label>
  <input id="query" <%= builder.combobox_target.merge aria: { expanded: params[:query].present? } %>
         type="search" name="query">
  <turbo-frame <%= builder.listbox_target %> id="names">
    <%= builder.option_target.tag.button name, type: "button", id: "name_#{id}",
                                         aria: { selected: id.zero? } %>
  </turbo-frame>
<% end %>
```

Note the shape: the helper returns **target builders** (`builder.combobox_target`,
`builder.listbox_target`, `builder.option_target`) that splat the correct
`data-controller` / `data-*-target` / `role` / `aria-*` attributes into the tag. The helper owns the
contract; the controller owns the behaviour; the template stays readable. It even ships
`config.stimulus_aria_widgets.helper_method` so an app can rename the entry point.

**This is the strongest evidence yet for the 37signals convention** — an independent sixth
codebase, from a Turbo maintainer, arriving at the same answer, *and* documenting it. It also
supplies the missing rationale: the helper exists so that the ARIA attributes a controller depends
on cannot be forgotten at a call site.

**Recommendation for crosswire:** document the helper-per-controller convention as the production
pattern, with `stimulus_aria_widgets` as the worked reference implementation (it is the only public
one that explains itself), and document the yielding-`application/`-partial convention as the
lighter-weight alternative when the abstraction is mostly *markup* rather than *attributes*. Doyle
uses the partial form when there is a block of content to wrap (`_inline_edit`), and the helper form
when there is a set of attributes to guarantee (`stimulus_aria_widgets`). That distinction is the
rule worth writing down, and nobody has written it down.

### His other gems worth mining

| Gem | What it is | Why crosswire cares |
|---|---|---|
| [`turbo_stream_button`](https://github.com/seanpdoyle/turbo_stream_button) (51★) | A `<button>` declares its own Turbo Stream mutations inline in a nested `<template>`, evaluated client-side on click | The `button-alert-template` branch, productised. Client-side DOM changes expressed as Turbo Stream actions with **no server round-trip**. |
| [`constraint_validations`](https://github.com/seanpdoyle/constraint_validations) (37★) | Bridges `ActiveModel::Validations` ↔ the browser Constraint Validation API; renders error `<span>`s wired via `aria-describedby` | Opens with *"The current Action View default configurations for `<form>` element construction **don't create accessible forms and fields**."* Includes the grouped-checkbox `required` → `aria-required="true"` workaround. |
| [`view_partial_form_builder`](https://github.com/seanpdoyle/view_partial_form_builder) (33★) | Resolves each FormBuilder call to a view partial (`app/views/application/form_builder/_text_field.html.erb`), per-model overridable | Design-system field styling without subclassing FormBuilder in Ruby. |
| [`with_form`](https://github.com/seanpdoyle/with_form) | *"Your System Test's counterpart to `form_with`"* — Capybara helpers that fill forms by **translated `<label>` text** | The testing half of his a11y philosophy. Also documents the Trix gap: `<trix-editor>` isn't a native form field so `<label for>` doesn't focus it — mirror the label into `aria-label`. |
| [`stimulus-mutation`](https://github.com/seanpdoyle/stimulus-mutation) | Routes DOM mutations to controllers like events | Where his withdrawn Stimulus core PRs (#397, #460) ended up — relevant to the morphing-vs-Stimulus problem. |
| [`attributes_and_token_lists`](https://github.com/seanpdoyle/attributes_and_token_lists) | Hash/Set-like `Attributes` and `TokenList` primitives | The substrate `stimulus_aria_widgets` builds its helpers on. |

---

## Techniques to adopt in crosswire (ranked)

Ranked by (value to a reader) × (how unlikely they are to find it elsewhere).

**1. Nested / dynamic forms with zero JavaScript — the `cocoon` replacement.**
`turbo-frame-powered-nested-attributes`. Add/remove `accepts_nested_attributes_for` rows using
`form.fields(index: …)` plus `<button name="…[_destroy]" value="true/false" formmethod="get"
formaction="<this page>">`, wrapped in a `<turbo-frame>` for the enhancement. Validation state
survives for free; no client-side index counter can desync. Highest-demand recipe in the whole
corpus, and it needs no JS at all. Ship it as recipe #1 with the `<template>`-powered variant as the
documented escape hatch for forms containing file inputs or long rich text.

**2. Server-driven frame breakout: the `Turbo::FrameRedirectable` concern.**
`hotwire-example-modal`. Gives you `redirect_to url, turbo_frame: "_top"` — an API that still does
not exist upstream in 2026 (`turbo-rails#367`, open since 2022). ~25 lines of controller concern
plus a 5-line `turbo:submit-end` listener. Pair it with the parameterised-frame-id trick
(`<button name="turbo_frame" value="dialog">` + `<turbo-frame id="<%= params[:turbo_frame] || dom_id(@message) %>">`)
so one template serves both a modal and a full page. This is the single most-asked, least-answered
question in Hotwire, and crosswire would be the place that answers it.

**3. Inline editing via matching frame ids, with zero JavaScript.**
`hotwire-example-inline-edit`. Two yielding partials in `app/views/application/`, a frame id derived
from `dom_id(model, "#{attribute}_turbo_frame")`, and a Tailwind `group-*` variant for the
Save/Cancel affordances. The `edit` page stays a working non-JS page. Also the best demonstration of
his abstraction unit.

**4. `<fieldset disabled>` + `aria-controls` as the conditional-fields mechanism.**
`stimulus-dynamic-forms`. The disabled attribute controls visibility (`disabled:hidden`), keyboard
reachability, *and* whether the values are submitted — one source of truth instead of three. The
Stimulus controller finds its targets by reading `aria-controls`, so the accessibility annotation is
load-bearing and cannot rot. `field_id` / `field_name` generate both ends. Roughly 25 lines of JS
for an entire category of feature.

**5. `<turbo-stream>` rendered inline, inside a `<turbo-frame>`, to patch the rest of the page.**
`turbo-dynamic-forms`. A frame only replaces itself; anything else that depended on the changed
value goes stale. Rendering `<%= turbo_stream.replace @record %>` *inside* the frame's response
patches elsewhere in the document during a frame navigation — no WebSocket, no second request, no
`fetch`. Almost nobody knows `<turbo-stream>` works as plain inline HTML. He also names the cost
(double render server-side, double parse client-side; watch out for uncached images).

**Runners-up worth a recipe each:**

6. **The implicit-submission guard** — `<button class="hidden" tabindex="-1" aria-hidden="true">` as
   a form's first child, whenever the form contains `formaction`/`formmethod` buttons. One line;
   fixes a real keyboard bug; almost universally missing.
7. **Zero-JS async tooltips** — `<turbo-frame loading="lazy" role="tooltip">` + `aria-describedby` +
   CSS `peer-hover:` / `peer-focus:` / `focus-within:`. His own note: *"This is an incredibly
   powerful yet under-utilized feature of CSS, and is often unnecessarily replicated with
   JavaScript."*
8. **Server-pre-rendered `<template>` + an 11-line generic `clone` controller** —
   `button-alert-template`. The server renders an entire alert *including its own dismissal
   `<turbo-stream action="remove">`* into an inert `<template>`; cloning it into the live DOM lets
   Turbo's custom-element upgrade do the rest. Generalises to any "insert a server-authored fragment
   with no round-trip".
9. **"Fire a real submit button, then vanish"** — `kanban`. A drag gesture clones a hidden
   `<input type="submit" formaction="…" data-controller="autoclick autoremove">` into the drop
   target; `autoclick` clicks it (a genuine Rails PATCH), `autoremove` deletes it. Turns any
   client-side gesture into a conventional form submission with no `fetch`/`FormData` code.
10. **Test by ARIA role, not CSS class** — `within :modal`, `assert_selector :alert, "…"`,
    `within :fieldset, "Personal references"`, `assert_no_button(focused: true)`,
    `toggle_disclosure "New message", expand: true`. Makes accessibility a test-suite constraint at
    zero extra cost. Adopt as crosswire's house style for every recipe's example test.
11. **Third-party JS bridging** — `map` (Leaflet). A `WeakMap`-keyed instance cache plus
    `data-turbo-permanent` keeps one live map instance alive across Turbo Drive visits. And his
    data-plumbing rule of thumb: **stable config → Stimulus Values (JSON in `data-*-value`);
    volatile data that must be replaceable independently → a sibling `<meta>` element** the frame
    can swap.
12. **Hand-rolled accessible data grid** — `grid`. Full ARIA APG grid pattern (`role="grid"`, roving
    tabindex, arrows, Home/End, Ctrl+Home/End, PageUp/PageDown) over a plain `<table>`, with a
    custom Capybara `:cell` selector and a 150-line system-test suite. Directly contrast it with the
    `ag-grid` branch, which defers all accessibility to the library's opaque internals. Same problem,
    opposite architecture — an ideal A/B for the "should I reach for a JS grid?" question.

---

## Anything now outdated

**The corpus is entirely pre-Turbo-8.** Every Doyle commit is 2021-04-03 … 2022-08-15, and the
checked-out trees pin `rails 7.0.2.2`, `turbo-rails 1.0.1`, `stimulus-rails 1.0.2`. Even the two
2024 branches (`drawer`, `process-network-request` — both by **Steve Polito**, not Doyle) still have
`turbo-rails (1.0.1)` in `Gemfile.lock`, so **nothing in this repository has ever run on Turbo 8**.
Note also that the repo's own README warns histories are "rebased and rewritten on a regular basis":
`upload-processing` carries 2021-05 commit dates but a 2022-02 schema. **Do not trust commit dates
as a proxy for dependency currency.**

### Actually broken

- **`cdn.skypack.dev` is dead.** Three branches import third-party ES modules straight from it:
  `template-parts_controller.js` (`@github/template-parts`), `dialog_controller.js`
  (`dialog-polyfill`, plus a `<link>` to its CSS), and the combobox branches
  (`@github/combobox-nav`). Every one of these 404s today. Re-pin through importmap
  (`bin/importmap pin @github/combobox-nav`) or jsDelivr. **Rewrite these before publishing any
  recipe derived from them.**
- **`dialog-polyfill` is not merely broken, it is unnecessary.** `<dialog>` has been baseline since
  Firefox 98 (March 2022). Delete the import and the `initialize()` hook; `dialog_controller.js`
  collapses to a single `showModal()` method.
- **`ag-grid-enterprise@27.3.0`** (2022) is many majors behind; the branch's API usage will not
  transfer.

### Superseded, in whole or in part, by Turbo 8 morphing

Be careful here — morphing is narrower than people assume. It is a **Turbo Drive full-page-visit**
reconciliation strategy (`<meta name="turbo-refresh-method" content="morph">`, plus
`turbo-refresh-scroll` for scroll). It does **not** automatically apply to Turbo Frame navigations
or to `broadcast_replace_later_to` streams.

| Branch | Verdict |
|---|---|
| `restore-page-state` | **Largely superseded.** The `scroll` and much of the `session_resume` machinery exists to survive full-page redirects — exactly morphing's use case. Keep the `<details>`/`<summary>` disclosure modelling and `data-turbo-permanent` guidance; drop the hand-rolled caching. |
| `kanban-preserve-focus` | **Partly superseded.** The focus loss comes from `broadcast_replace_later_to` doing an outerHTML swap of a whole `<section>` — a *stream*, not a Drive visit. On Turbo 8 you'd opt the broadcast into morphing rather than delete `focus_controller.js` outright. His `dom_id`-derived stable ids are still the prerequisite either way. |
| `kanban` (`scroll_controller.js`) | **Strong deletion candidate** if broadcasts are updated to request morph. The drag controllers are unaffected — morphing patches the DOM *after* a response; it does nothing for capturing a gesture. |
| `multi-form-search` | Its bespoke "snapshot `document.activeElement.id`, refocus by exact id" controller is brittle and sits *next to* `data-turbo-permanent` on another field in the same file. Prefer `data-turbo-permanent`, or morphing. Flag the inconsistency explicitly. |
| `pagination` | **Not superseded.** Frame-based infinite scroll and `loading="lazy"` are orthogonal to morphing. Its `element_controller` "unwrap the frame after render" trick predates a long-open Turbo RFC (`hotwired/turbo#146`) — re-verify against current Turbo before republishing. |
| `chat`, `upload-processing`, `process-network-request` | Use the classic `broadcast_replace` / `turbo_stream_from` idiom. Still valid, but a modern write-up should at least mention `broadcasts_refreshes` / the `refresh` stream action as the Turbo 8 alternative. |

### Morphing vs Stimulus values (`hotwired/turbo#1210`) — still open, and he's the one who'd fix it

He has exactly one comment on the issue (2024-03-01), but he authored the mechanism it depends on
([turbo#1097](https://github.com/hotwired/turbo/pull/1097): `turbo:before-morph-element` /
`turbo:before-morph-attribute`), explicitly so that *"a Stimulus controller with `[data-*-value]`
attributes"* can opt out of a morph.

On the community's global "ignore every server-sent `data-*-value` during morph" workaround:

> Over-committing to ignore *all* server-sent Stimulus Values feels safer than under-committing.

On what should happen instead:

> a coordinated effort to expand built-in Morph integration for Stimulus and Trix (and therefore
> Action Text). Something that affords a configuration-less turn-key solution for most circumstances
> with some focused escape hatches when necessary.

That effort **never happened**. Basecamp's stated reason: *"It hasn't been a common/recurring issue
for us."* He even shipped a fix (`ignoreActiveValue: true`, turbo#1141) and **rolled it back four
weeks later** (turbo#1195), pushing the burden onto `focusin`/`focusout` + `data-turbo-permanent`.
He also withdrew his own Stimulus-side mutation-callback PRs (#397, #460) into an external package,
`stimulus-mutation` — so the Stimulus half of the integration was never built at all.

His durable doctrine, and the practical advice to give crosswire readers: **a controller or custom
element that expects to survive morphing must implement `static observedAttributes` +
`attributeChangedCallback`**, and be

> resilient to both asynchronous connection and disconnection *as well as* asynchronous modification
> of attributes.

And his self-imposed limit on how far morphing should reach:

> I'm also wary of expanding that area of the interface. There are too many edge cases and
> combinatory explosion of `[data-turbo-*]` attributes to account for.

**Verdict for crosswire:** treat "Stimulus values + morphing" as a documented sharp edge with three
mitigations (attribute-change callbacks; `data-turbo-permanent`; `turbo:before-morph-attribute` to
veto specific attributes), not as a solved problem. Cite #1210 as open.

### Stale idioms to normalise when transcribing recipes

- **Stimulus 2 syntax** in the older branches: `static get targets() { return [...] }` and
  `static get values() {...}`. Modern form is `static targets = [ … ]` / `static values = { … }`.
  He uses the modern form in the later (2022) branches, so the repo is internally inconsistent.
- **Tailwind via `<script src="https://cdn.tailwindcss.com">`** (the Play CDN) in several layouts —
  never for production.
- **`role="section"`** appears on a `<turbo-frame>` in the modal branch. That is not a valid ARIA
  role; drop it.
- **`aria-dropeffect`** (kanban) is **deprecated in ARIA 1.1+** and is not implemented by assistive
  technology. It works fine as his JS/test hook, but do not present it as an accessibility feature.
- **`role="dialog"` + `aria-modal="true"` explicitly set on a native `<dialog>`** was defensive
  belt-and-braces for the polyfill era. Harmless, now redundant.

### Not outdated, and worth saying so

`<turbo-frame>` targeting semantics, `data-turbo-frame`, `target="_top"`, `loading="lazy"`,
`<turbo-stream>`-as-inline-HTML, `Turbo-Frame` request/response headers, `turbo:submit-end` and
`fetchResponse.header(...)`, `field_id` / `field_name`, `form.fields(index:)`, `<fieldset disabled>`,
`<form method="dialog">`, and `data-turbo-permanent` are all unchanged. The overwhelming majority of
the *techniques* survive; it is the *dependencies* that have rotted.

---

## Negative findings

Recording these so nobody re-runs the search:

- **Stack Overflow: nothing.** Checked via the Stack Exchange API. The only "Sean Doyle" account
  with meaningful reputation (user 318458, 358 rep) has top answer tags of *iphone, android, dicom,
  cordova, xcode* — a different person. He does not appear in the top-answerer lists for the
  `hotwire`, `turbo`, `hotwire-rails`, or `turbo-frames` tags. **He does not answer on Stack
  Overflow.** His public Q&A surface is GitHub issues, not SO.
- **The "Stimulus controller paired with an ERB helper" convention does not appear in the *example
  repo*** — every `app/helpers/*.rb` there is an empty module or absent. It very much *does* appear
  in his gems, above all `stimulus_aria_widgets`. Don't conclude from the tutorial repo that he
  rejects the pattern; the tutorial repo omits it on purpose so the wiring stays visible. See
  [the abstraction unit he actually uses](#the-abstraction-unit-he-actually-uses-answering-the-37signals-question).
- **"Not knowing the browsing context"** (`hotwire-example-chat`'s final commit) is **not** about
  frame breakout, as we'd hypothesised. It is about a background job broadcasting HTML with no
  per-viewer request context — no timezone, no current user — solved with signed global ids for the
  current user, CSS `:only-child` for DOM state, and a `<relative-time>` custom element for
  timezone-correct timestamps. A different and arguably more broadly useful problem.
- **Frames + history/URL:** he never demonstrates promoting a frame navigation to a history entry
  except via `data-turbo-action="replace"` in the pagination branch. Consistent with maintainers
  disowning the pattern; he simply doesn't teach it.

---
