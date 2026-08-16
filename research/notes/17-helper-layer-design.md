# 17 — The View/Helper Layer: Design

> **Thesis this document serves.** A Stimulus controller stays generic only if its class
> names, URLs, IDs, and event bindings are injected from outside. Doing that injection by
> hand in ERB is painful enough that people give up and write app-specific controllers.
> **The ERB helper layer is therefore what makes generic controllers viable at scale.**
> This document designs that layer.
>
> **Constraint already decided by a sibling:** crosswire ships as a Rails engine gem with
> unbundled per-controller ESM plus a bundled fallback, plain JS (not TypeScript, because
> TS breaks `pin_all_from`). Everything below is designed inside that decision.

**Status:** design proposal, evidence-backed. Every Rails semantic claimed here was
verified empirically against ActionView 8.1.3.1; the merge implementation in
[§6](#6-the-merge-problem-solved) has a passing test suite (14/14).

---

## Table of contents

1. [How production does it](#1-how-production-does-it)
2. [Rails primitives available](#2-rails-primitives-available)
3. [Component-shipping options compared](#3-component-shipping-options-compared)
4. [Recommended design for crosswire](#4-recommended-design-for-crosswire)
5. [Worked example: the same component, three ways](#5-worked-example-the-same-component-three-ways)
6. [The merge problem, solved](#6-the-merge-problem-solved)
7. [Theming & CSS strategy](#7-theming--css-strategy)
8. [Customization & ejection](#8-customization--ejection)
9. [Naming conventions](#9-naming-conventions)
10. [Engine mechanics checklist](#10-engine-mechanics-checklist)
11. [Open questions](#11-open-questions)

---

## 1. How production does it

Five codebases independently arrived at "Stimulus controller + Ruby helper". None of them
documents the pattern as a pattern. Here is each one's actual code.

### 1.1 37signals — one helper per controller

Writebook, Campfire and Fizzy each carry an `app/helpers/forms_helper.rb`. In Writebook and
Campfire the file is **byte-identical**:

```ruby
# writebook/app/helpers/forms_helper.rb
# once-campfire/app/helpers/forms_helper.rb   (identical)
module FormsHelper
  def auto_submit_form_with(**attributes, &)
    data = attributes.delete(:data) || {}
    data[:controller] = "auto-submit #{data[:controller]}".strip

    form_with **attributes, data: data, &
  end
end
```

The shape is the whole pattern in four lines: **pull `data:` out of the caller's options,
prepend our controller identifier, pass everything through to the Rails helper.** The
`.strip` exists because `data[:controller]` is usually `nil`, producing `"auto-submit "`.

Fizzy (2025, the newest of the three) shows the pattern under strain. The same file has
grown a second helper that has to merge **two** token attributes:

```ruby
# fizzy/app/helpers/forms_helper.rb
def bridged_form_with(**attributes, &)
  data = attributes.delete(:data) || {}
  controllers = [ data[:controller], "bridge--form" ].compact.join(" ").strip
  actions = [
    data[:action],
    "turbo:submit-start->bridge--form#submitStart",
    "turbo:submit-end->bridge--form#submitEnd"
  ].compact.join(" ").strip

  data[:controller] = controllers
  data[:action] = actions

  if block_given?
    form_with **attributes, data: data, &
  else
    form_with(**attributes, data: data) { }
  end
end
```

Note what changed between Campfire and Fizzy: string interpolation became
`[...].compact.join(" ").strip`, because interpolation does not survive a `nil` in the
middle of a list. **This is the merge problem being rediscovered and hand-patched, per
helper, per app.** Neither version dedupes; both would happily emit
`data-controller="auto-submit auto-submit"`.

Other 37signals helpers show the same idea applied to plain tags rather than forms:

```ruby
# once-campfire/app/helpers/clipboard_helper.rb
module ClipboardHelper
  def button_to_copy_to_clipboard(url, &)
    tag.button class: "btn", data: {
      controller: "copy-to-clipboard", action: "copy-to-clipboard#copy",
      copy_to_clipboard_success_class: "btn--success", copy_to_clipboard_content_value: url
    }, &
  end
end
```

That is a **fully generic** `copy-to-clipboard` controller — the success class and the
content are both injected — and the helper is the only reason the call site is one line.
Campfire's chat screen famously contains not one `data-controller` attribute; helpers like
this are where they went.

Also worth stealing, Campfire's "just a string" helper for an action list that gets reused
across several elements:

```ruby
# once-campfire/app/helpers/drop_target_helper.rb
module DropTargetHelper
  def drop_target_actions
    "dragenter->drop-target#dragenter dragover->drop-target#dragover drop->drop-target#drop"
  end
end
```

And Fizzy's `avatars_helper.rb` shows they *do* know about `class_names` for the `class`
attribute — but there is no equivalent reach for `data`:

```ruby
# fizzy/app/helpers/avatars_helper.rb
link_to user_path(user), class: class_names("avatar btn btn--circle", options.delete(:class)), ...
```

**Takeaway:** one helper per controller, named after the thing rather than the controller
(`auto_submit_form_with`, `button_to_copy_to_clipboard`). Merging is manual, ad hoc, and
subtly different in every helper.

### 1.2 Solidus — one generic module keyed on `stimulus_id`

The most elegant of the five, and the smallest:

```ruby
# solidus/admin/app/helpers/solidus_admin/stimulus_helper.rb
# Simple shorthands and helpers for stimulus data attributes to avoid writing clumsy
# interpolations with `stimulus_id`
#  Before: "data-#{stimulus_id}-target": "wrapper"
#  After: stimulus_target("wrapper")

module SolidusAdmin
  module StimulusHelper
    def stimulus_controller
      {"data-controller": stimulus_id}
    end

    def stimulus_action(action, on: nil)
      action_construct = []
      action_construct << "#{on}->" if on.present?
      action_construct << "#{stimulus_id}##{action}"

      {"data-action": action_construct.join}
    end

    def stimulus_target(target)
      {"data-#{stimulus_id}-target": target}
    end

    def stimulus_value(name:, value:)
      {"data-#{stimulus_id}-#{name}-value": value}
    end
  end
end
```

Two things make this work:

1. **Every method returns a Hash, not a string.** That makes them splat-composable into
   `tag`: `tag.div(**stimulus_controller, **stimulus_target("wrapper"))`.
2. **`stimulus_id` is ambient.** It is derived from the component's own path, so the
   helper never has to be told which controller it belongs to. From
   `solidus/admin/docs/stimulusjs.md`:

   > Any `component.js` file is automatically loaded as a StimulusJS controller. The
   > component path is used as the identifier, which is achieved by using `parameterize`
   > and replacing `/` with `--`. For example, `app/components/solidus_admin/foo/component.js`
   > is loaded as `solidus-admin--foo`.

The convention is enforced by the loader, so the Ruby side and the JS side cannot drift.
That is the single best idea in this survey and crosswire should copy it.

**Its limitation:** because each method returns a *separate* hash, splatting two hashes
that both contain `:"data-action"` silently drops one — Ruby's `**` is last-wins. It
composes right up until two things want the same attribute, which is exactly the merge
problem. It also can't express "the caller also passed a `data-action`".

### 1.3 hotwire_combobox — presenter object + `customize`

The closest analogue to crosswire: a gem shipping one Hotwire component that consumers
embed in **their own** views. Its architecture is three layers.

**Layer 1 — a thin helper** that constructs a presenter and renders it
(`hotwire_combobox/lib/hotwire_combobox/helper.rb`):

```ruby
def hw_combobox_tag(name, options_or_src = [], render_in: {}, include_blank: nil,
                    chip_attributes: {}, prefilled_chips: nil, **kwargs, &block)
  options, src = hw_extract_options_and_src options_or_src, render_in, include_blank, chip_attributes
  prefilled_chips = hw_resolve_prefilled_chips prefilled_chips, chip_attributes
  component = HotwireCombobox::Component.new self, name, options: options, async_src: src,
    request: request, chip_attributes: chip_attributes, prefilled_chips: prefilled_chips, **kwargs
  render component, &block
end
```

**Layer 2 — a presenter** (`app/presenters/hotwire_combobox/component.rb`) that exposes one
`*_attrs` method per element, composed from small `Markup::` modules:

```ruby
# app/presenters/hotwire_combobox/component/markup/listbox.rb
module HotwireCombobox::Component::Markup::Listbox
  def listbox_attrs
    customize :listbox, base: {
      id: listbox_id, role: :listbox, hidden: "",
      class: "hw-combobox__listbox",
      data: { hw_combobox_target: "listbox" },
      aria: { multiselectable: multiselect? } }
  end
end
```

**Layer 3 — a partial** that splats those hashes into tags
(`app/views/hotwire_combobox/_component.html.erb`):

```erb
<%= tag.fieldset **component.fieldset_attrs do %>
  <%= tag.label component.label, **component.label_attrs %>
  ...
  <%= tag.ul **component.listbox_attrs do |ul| %>
```

The important part is `Customizable`, which is the only real merge solution found in any
of the five:

```ruby
# app/presenters/hotwire_combobox/component/customizable.rb
module HotwireCombobox::Component::Customizable
  CUSTOMIZABLE_ELEMENTS = %i[
    dialog dialog_input dialog_label dialog_listbox dialog_wrapper
    fieldset handle hidden_field input label listbox main_wrapper
  ].freeze

  PROTECTED_ATTRS = %i[ for hidden id name open role value ].freeze

  CUSTOMIZABLE_ELEMENTS.each do |element|
    define_method "customize_#{element}" do |**attrs|
      store_customizations element, **attrs
    end
  end

  private
    def store_customizations(element, **attrs)
      element = element.to_sym.presence_in(CUSTOMIZABLE_ELEMENTS)
      sanitized_attrs = attrs.deep_symbolize_keys.except(*PROTECTED_ATTRS)
      custom_attrs.store element, sanitized_attrs
    end

    def customize(element, base: {})
      custom = custom_attrs[element]

      coalesce = ->(key, value) do
        if custom.has_key?(key) && (value.is_a?(String) || value.is_a?(Array))
          view.token_list(value, custom.delete(key))
        else
          value
        end
      end

      default = base.map { |k, v| [ k, coalesce.(k, v) ] }.to_h
      custom.deep_merge default
    end
end
```

Four ideas worth stealing wholesale:

- **A named customization surface.** `CUSTOMIZABLE_ELEMENTS` enumerates every element a
  consumer may touch, and generates `customize_input`, `customize_listbox`, … The consumer
  reaches inner elements without knowing the markup.
- **`PROTECTED_ATTRS`.** `id`, `role`, `for`, `name`, `value`, `open`, `hidden` are stripped
  from consumer input, because those are what make the component *work* (and, for `role`,
  what makes it accessible). Customization is deliberately not total.
- **`token_list` for string/array values**, so `class` merges instead of clobbering.
- **`deep_merge`** for the rest.

Its bug, worth not reproducing: `coalesce` only unions when the **base** value is a String
or Array, and it merges `custom.deep_merge default` — i.e. **base wins** over the consumer
for non-token keys. That is backwards from every other Ruby merge convention and surprises
people. Also `custom.delete(key)` mutates the memoized hash during iteration, so the second
render of the same component in one request loses the customization.

Where the combobox needs to merge caller-supplied actions with its own, it hand-rolls it
again — the same list-join idiom as Fizzy:

```ruby
# app/presenters/hotwire_combobox/component/markup/input.rb
def input_data
  data = combobox_attrs.fetch(:data, {}).dup
  action = %w[
    click->hw-combobox#toggle
    keydown->hw-combobox#prepareToFilter
    input->hw-combobox#filterAndSelect
    ...
  ].append(data.delete(:action)).compact.join(" ")

  data.merge action: action, hw_combobox_target: "combobox", async_id: canonical_id
end
```

and for the controller attribute it *does* reach for `token_list`:

```ruby
# app/presenters/hotwire_combobox/component/markup/fieldset.rb
controller: view.token_list("hw-combobox", data[:controller]),
```

Two different merge strategies for two token attributes in the same object. That is the
strongest possible evidence that this needs to be one reusable primitive.

**Also note the "convenience alias" trick**, which solves the gem-namespacing tension
elegantly — ship `hw_`-prefixed names always, and unprefixed aliases unless the app opts
out:

```ruby
def self.hw_alias(method_name)
  unless bypass_convenience_methods?
    alias_method method_name.to_s.sub(/^hw_/, ""), method_name
  end
end
```

### 1.4 Avo — a view-context concern

Avo builds the attribute hash in a concern mixed into resources rather than into the view:

```ruby
# avo/lib/avo/concerns/has_resource_stimulus_controllers.rb
included do
  class_attribute :stimulus_controllers, default: ""
end

def get_stimulus_controllers
  return "" if @view.nil?
  controllers = []
  case @view.to_sym
  when :show        then controllers << "resource-show"
  when :new, :edit  then controllers << "resource-edit"
  when :index       then controllers << "resource-index record-selector"
  end
  controllers << self.class.stimulus_controllers
  controllers.reject(&:blank?).join " "
end

def stimulus_data_attributes
  attributes = { controller: get_stimulus_controllers }
  get_stimulus_controllers.split(" ").each do |controller|
    attributes["#{controller}-view-value"] = @view
  end
  attributes
end

def add_stimulus_attributes_for(entity, attributes, target_name = nil)
  entity.get_stimulus_controllers.split(" ").each do |controller|
    attributes["#{controller}-target"] = target_name ||
      "#{@field.id.to_s.underscore}_#{@field.type.to_s.underscore}_wrapper".camelize(:lower)
  end
end
```

The genuinely novel idea: **fan one value out to every attached controller.** Because you
can't know which controller identifier the target attribute belongs to, Avo splits the
controller list and writes `data-<each>-target`. crosswire will need this whenever a
component composes with a consumer's controller. The `join(" ")` / `split(" ")`
string-round-tripping is a smell, but the intent is right.

### 1.5 Administrate — Field objects + partial prefixes

Administrate's field objects expose the controller identifier as an overridable method:

```ruby
# administrate/lib/administrate/field/base.rb
def self.html_class
  field_type.dasherize
end

def html_controller
  nil
end
```

```ruby
# administrate/lib/administrate/field/associative.rb
def html_controller
  "select"
end
```

which the partials consume directly:

```erb
<%# administrate/app/views/fields/has_many/_form.html.erb %>
<%= f.select(field.attribute_key, nil, {}, multiple: true, data: {controller: field.html_controller}) do %>
```

No merging at all — but note it degrades safely: `data: { controller: nil }` renders
nothing, because Rails drops nil data values (verified, [§2.3](#23-tag_options-the-data-trap)).

The more interesting mechanism is **`partial_prefixes` + "looks"**, a variant system built
entirely out of view lookup:

```ruby
def self.local_partial_prefixes(look: :default)
  fallback = ["fields/#{field_type}/looks/default", "fields/#{field_type}"]
  if look == :default
    fallback
  else
    ["fields/#{field_type}/looks/#{look}"] + fallback
  end
end
```

A consumer passes `look: :compact` and Administrate looks for
`fields/select/looks/compact/_form`, falling back to `fields/select/_form`. **Variants
become filesystem paths a consumer can add to without touching the gem.** This is a strong
model for crosswire's theming and is discussed in [§8.3](#83-variants-looks).

### 1.6 Summary of the five

| | Unit of abstraction | Returns | Merge strategy | Consumer override |
|---|---|---|---|---|
| 37signals | one helper per controller | markup | manual `join(" ").strip`, no dedupe | n/a (app code) |
| Solidus | one generic module + `stimulus_id` | attribute Hash | none (`**` splat, last-wins) | n/a (app code) |
| hotwire_combobox | presenter + partial + helper | markup | `token_list` + `deep_merge`, base-wins | `customize_*`, protected attrs |
| Avo | concern on resource | attribute Hash | `join`/`split` strings | subclass resource |
| Administrate | Field object + partial prefixes | field object | none (nil-safe) | copy partial via generator; `looks` |

**The distinction that decides crosswire's architecture:** Avo and Solidus Admin ship a
*whole admin application* — the consumer never writes the views, so component objects are
free. hotwire_combobox and Administrate ship components into the *consumer's own views*,
and both landed on **helper + partial**, with the partial being the override surface.
crosswire is the second kind. See [§3](#3-component-shipping-options-compared).

---

## 2. Rails primitives available

Everything in this section was verified by running it against ActionView 8.1.3.1, not read
off documentation. The probe script lives in the scratchpad; results are inline.

### 2.1 `token_list` / `class_names`

```ruby
# actionview/lib/action_view/helpers/tag_helper.rb:538
def token_list(*args)
  tokens = build_tag_values(*args).flat_map { |value| CGI.unescape_html(value.to_s).split(/\s+/) }.uniq
  safe_join(tokens, " ")
end
alias_method :class_names, :token_list
```

`build_tag_values` flattens nested arrays, keeps hash keys whose values are truthy, and
drops anything `blank?`.

Verified behaviour:

| Input | Output |
|---|---|
| `token_list("auto-submit", "foo auto-submit bar")` | `"auto-submit foo bar"` — **dedupes, first-occurrence order** |
| `token_list(nil, false, "a", {b: true, c: false}, ["d", nil])` | `"a b d"` |
| `token_list("click->foo#bar")` | `"click-&gt;foo#bar"` — **HTML-escaped** |
| `token_list(token_list("click->a#b"), "input->a#c")` | `"click-&gt;a#b input-&gt;a#c"` — **not double-escaped** |

Three properties matter enormously and none of them is obvious:

1. **It dedupes.** None of the five production merge implementations does. `token_list`
   gets it for free.
2. **It escapes `>` to `&gt;`.** This looks alarming for `data-action` values, which are
   full of `->`. It is fine: the browser decodes entities when parsing the attribute, so
   `getAttribute("data-action")` returns `click->a#b` and Stimulus parses it normally.
   Verified render: `<div data-action="click-&gt;a#b input-&gt;a#c">`.
3. **It is idempotent under re-merging**, *because* of the `CGI.unescape_html` call — an
   already-escaped token list can be fed back in and will not double-escape. This is the
   single property that makes `token_list` safe as a general-purpose accumulator, and it
   is why the design in §6 can call it repeatedly as attributes flow through nested
   helpers.

`class_names` is a pure alias. Prefer `token_list` in crosswire's own code so it reads
correctly when the target is `data-action`, not a class.

### 2.2 `tag.attributes`

```ruby
# tag_helper.rb:222
def attributes(attributes)
  tag_options(attributes.to_h).to_s.strip.html_safe
end
```

Renders an attribute hash to a bare, safe string for interpolation into hand-written HTML:

```erb
<input <%= tag.attributes(type: :text, aria: { label: "Search" }) %>>
```

Verified: `tag.attributes(data: { controller: "a", action: token_list("click->a#b") }, class: "x")`
→ `data-controller="a" data-action="click-&gt;a#b" class="x"`.

**This is the primitive that makes "bare ERB" a first-class usage mode for crosswire.**
A consumer who wants total control of the markup can still get correct attributes.

### 2.3 `tag_options`: the `data` trap

```ruby
# tag_helper.rb:235
def tag_options(options, escape = true)
  options.each_pair do |key, value|
    type = TAG_TYPES[key]
    if type == :data && value.is_a?(Hash)
      value.each_pair do |k, v|
        next if k.blank? || v.nil?          # <- nil data values are DROPPED
        output << prefix_tag_option(key, k, v, escape)
      end
    elsif type == :aria && value.is_a?(Hash)
      # ... Array/Hash values here go through build_tag_values -> space-joined
    elsif type == :boolean
      # ...
```

```ruby
# tag_helper.rb:312
def prefix_tag_option(prefix, key, value, escape)
  key = "#{prefix}-#{key.to_s.dasherize}"
  unless value.is_a?(String) || value.is_a?(Symbol) || value.is_a?(BigDecimal)
    value = value.to_json                   # <- Arrays become JSON, not tokens
  end
  tag_option(key, value, escape)
end
```

```ruby
# tag_helper.rb:295 — note `class` is special-cased, and ONLY `class`
def tag_option(key, value, escape)
  case value
  when Array, Hash
    value = TagHelper.build_tag_values(value) if key.to_s == "class"
    value = escape ? @view_context.safe_join(value, " ") : value.join(" ")
```

Verified consequences:

| Expression | Renders | Verdict |
|---|---|---|
| `tag.div(data: { controller: ["a","b"] })` | `data-controller="[&quot;a&quot;,&quot;b&quot;]"` | **BROKEN — the trap** |
| `tag.div(class: ["a","b",nil,{c: true}])` | `class="a b c"` | fine |
| `tag.div(aria: { labelledby: ["a","b"] })` | `aria-labelledby="a b"` | fine |
| `tag.div(data: {a: nil, b: false, c: 0, d: {x: 1}})` | `data-b="false" data-c="0" data-d="{&quot;x&quot;:1}"` | nil dropped; **false is NOT** |
| `tag.div(data: { bridge__buttons_target: "b" })` | `data-bridge--buttons-target="b"` | the namespacing trick |

Four rules fall out, and every one of them has bitten somebody in the five codebases:

1. **Arrays are safe in `class:` and `aria:`, and silently wrong in `data:`.** The
   asymmetry is undocumented. Any array destined for `data-controller` or `data-action`
   must be run through `token_list` first.
2. **`nil` in `data:` disappears; `false` renders `"false"`.** So conditional controllers
   must use `nil`, never `false` — `data: { controller: (cond ? "x" : false) }` emits
   `data-controller="false"`. Use `presence`/`nil`.
3. **`_` dasherizes, so `__` becomes `--`.** `data: { bridge__buttons_target: "button" }`
   → `data-bridge--buttons-target`. This is how you write a *namespaced* Stimulus
   controller's target in Ruby hash syntax, and it is the reason crosswire should namespace
   with `--` ([§9](#9-naming-conventions)).
4. **Hashes and Arrays as data *values* become JSON**, which is exactly what Stimulus
   Object/Array values want. `data: { cw__chart_series_value: [1,2,3] }` just works.

### 2.4 `form_with` does a shallow merge — and that is the whole problem

```ruby
# actionview/lib/action_view/helpers/form_helper.rb:1597
def html_options_for_form_with(url_for_options = nil, model = nil, html: {}, ...)
  html_options = options.slice(:id, :class, :multipart, :method, :data, :authenticity_token).merge!(html)
```

`:data` is sliced out and passed straight through to the tag builder. If the caller
supplies both `data:` and `html: { data: … }`, the second **replaces** the first wholesale.

**Searched actionview and railties: there is no merge-don't-clobber facility for
attributes anywhere in Rails.** `token_list` is the only token-aware primitive, and nothing
calls it for `data`. Every one of the five codebases had to write its own, and each wrote a
different one. That gap is precisely the thing crosswire's helper layer should fill.

### 2.5 `capture`, `dom_id`, `with_options`

- **`capture(&block)`** runs the block against a fresh output buffer and returns the
  string. `tag.div { }` already calls `@view_context.capture(self, &block)` internally
  (`tag_string`, tag_helper.rb:281), which is why `tag.div(**attrs) { … }` composes
  correctly inside helpers and why the `&` block-forwarding idiom in 37signals' helpers
  works. Helpers that take a block and pass it to `tag`/`form_with` need no `capture` of
  their own — `capture` is only needed when you must *inspect* or *reuse* the content.
- **`dom_id(record, prefix = nil)`** → `"post_45"`, `dom_id(Post)` → `"new_post"`,
  `dom_id(post, :edit)` → `"edit_post_45"`. Joined with `_`. This is the right default for
  any crosswire component that needs a stable ID (Turbo Frame targets, `aria-controls`,
  `aria-labelledby`), and it means the consumer rarely has to invent one.
- **`with_options`** merges **shallowly** — `with_options(data: { controller: "x" })` then
  a call passing `data: { action: … }` yields only the action. It is not usable for this
  problem.

---

## 3. Component-shipping options compared

The constraint set, in rough priority order for a gem shipping ~30 Hotwire components into
**the consumer's own views**:

1. Consumer can override **markup** without forking
2. Consumer can override **styling** without `!important` wars
3. Low **cost to a consumer who doesn't already use the technology**
4. Previews work (Lookbook)
5. Sane **asset/engine** story
6. a11y is easy to get right
7. Performance

### 3.1 The decisive finding: ViewComponent templates are not on the view lookup path

Rails engines put their views on the lookup path, and the application's own copy always
wins:

```ruby
# railties-8.1.3.1/lib/rails/engine.rb:613
initializer :add_view_paths do
  views = paths["app/views"].existent
  unless views.empty?
    ActiveSupport.on_load(:action_controller) { prepend_view_path(views) if respond_to?(:prepend_view_path) }
    ActiveSupport.on_load(:action_mailer) { prepend_view_path(views) }
  end
end
```

Each engine **prepends**; the application is itself an `Engine` and its initializers run
last, so `Rails.root/app/views` ends up at the front. **A consumer overrides an engine
partial by creating a file with the same path. No API, no configuration, no subclassing.**

ViewComponent does not participate in this at all. It finds templates by globbing the
filesystem next to the component's `.rb` file:

```ruby
# view_component/lib/view_component/base.rb:600
sidecar_files = Dir["#{directory}/#{component_name}.*{#{extensions}}"]
sidecar_directory_files = Dir["#{directory}/#{component_name}/#{filename}.*{#{extensions}}"]
```

where `directory` comes from `File.dirname(identifier)` and `identifier` is the component
class's real source path, captured at `inherited` time (base.rb:652). **A consumer cannot
shadow `Crosswire::ComboboxComponent`'s template by adding a file to `app/views/`.** Their
only route is to subclass the component and then change every call site to render the
subclass — which, for a component library invoked from consumer views, means the override
story is "edit all your views".

That single asymmetry decides this. Everything else is confirmation.

### 3.2 Dependency cost

| | Version | Major-version history | Cost to consumer |
|---|---|---|---|
| ERB partials + helpers | — | ships with Rails | **zero** |
| ViewComponent | **4.12.0** | v1→v2→v3→v4. v3.0.0 alone removed SlotsV1, `content_areas`, deprecated slot setters, `with_variant`, and reclassified ~20 exception types | a hard constraint in every consumer's Gemfile |
| Phlex | **2.4.1** | 1.x→2.x was a rewrite of the rendering API | same, plus a Ruby-markup DSL the consumer must learn to override anything |

A gem that depends on ViewComponent puts itself in the middle of every consumer's
ViewComponent upgrade, and constrains apps that pin an older major. For a library whose
entire pitch is "add rich UI to your Rails app without adopting a framework", requiring
adoption of a view framework is close to self-defeating.

### 3.3 The table

| | Override markup | Override CSS | Consumer cost | Lookbook | Engine assets | a11y | Perf |
|---|---|---|---|---|---|---|---|
| **Helpers (+ partials)** | ✅ free, via view path precedence | ✅ ships CSS separately | ✅ zero deps | ⚠️ preview class renders the helper | ✅ simplest | ✅ helper owns roles/aria | ✅ partial render cost only |
| **ERB partials alone** | ✅ same | ✅ | ✅ zero deps | ⚠️ same | ✅ | ⚠️ every call site retypes aria | ✅ |
| **ViewComponent** | ❌ **not on lookup path**; subclass + edit every call site | ✅ | ❌ v4, 4 majors | ✅ first-class | ⚠️ `Dir[]` glob; sidecar assets need wiring | ✅ | ✅ fastest at high volume |
| **Phlex** | ⚠️ subclass + method override; markup is Ruby | ✅ | ❌ v2, DSL to learn | ⚠️ via phlex-rails adapter | ⚠️ | ✅ | ✅ fast |

### 3.4 Verdict

> **Primary: plain ERB helpers, backed by overridable partials in the engine's
> `app/views/crosswire/`, with a small presenter object per non-trivial component.**
> That is hotwire_combobox's architecture, and it is the architecture every gem in this
> survey that ships components into consumer views converged on.
>
> **Not ViewComponent, not Phlex** — as a dependency. crosswire will *work fine inside*
> both (a helper returns a safe string; a Phlex component can call it via `helpers`; a
> ViewComponent template is ERB), it just won't *require* either.

**What we lose by not choosing ViewComponent, honestly stated:**

- **Unit-testable components.** `render_inline(Component.new(...))` plus Capybara matchers
  is genuinely better than testing a helper's string output. *Mitigation:* helpers are
  testable via `ActionView::TestCase`, which supports `render` and `assert_select`; and the
  real behaviour under test here is the Stimulus controller, which needs a browser anyway.
- **First-class Lookbook previews.** ViewComponent previews are Lookbook's happy path.
  *Mitigation:* Lookbook can preview anything renderable from a preview class, but this is
  the weakest part of the recommendation — see [§11](#11-open-questions).
- **Compile-time template validation and a faster render path at high call volume.**
  Irrelevant at the scale a component library is invoked.
- **Slots.** A real API loss; §4.4 proposes a smaller substitute.
- **A typed, greppable constructor.** A presenter object recovers most of this.

**What we gain:** a gem with zero runtime dependencies beyond Rails, and an override story
that is one file, no API.

---

## 4. Recommended design for crosswire

### 4.1 Four layers, each independently usable

The whole point is that a consumer can enter at whichever layer they want and step *down*
a layer whenever the abstraction stops fitting — without ejecting from the library.

```
Layer 3   crosswire_disclosure_tag(...)         one call, full markup
             │  renders
Layer 2   app/views/crosswire/_disclosure.html.erb    overridable partial
             │  splats
Layer 1   Crosswire::Disclosure.new(...).trigger_attrs      presenter: attribute hashes
             │  built from
Layer 0   cw_controller(:disclosure), cw_action(...), Crosswire::Attributes.merge
                                                     primitives, usable in bare ERB
```

- **Layer 0** is Solidus's `StimulusHelper`, generalised and merge-safe. Always available.
- **Layer 1** is hotwire_combobox's presenter: one `*_attrs` method per element. Public API.
- **Layer 2** is an ERB partial the consumer can shadow by creating the same path.
- **Layer 3** is 37signals' one-helper-per-component convenience.

Only components with real internal structure (combobox, tabs, sortable list) need Layers 1
and 2. A `copy-to-clipboard` button is Layer 0 + Layer 3 and nothing else. **Do not build a
presenter for every one of the ~30 components** — that is the main way this design could
rot into ceremony.

### 4.2 Layer 0 — the Stimulus primitives

Solidus's module, with three changes: it takes an explicit identifier (crosswire has ~30
controllers, not one per component directory), it returns hashes that *merge* rather than
clobber, and it covers targets, values, classes, params and outlets.

```ruby
# app/helpers/crosswire/stimulus_helper.rb
module Crosswire
  module StimulusHelper
    # Namespace every crosswire controller so it can never collide with the app's.
    #   cw_identifier(:disclosure)         # => "cw--disclosure"
    #   cw_identifier("disclosure/menu")   # => "cw--disclosure--menu"
    def cw_identifier(name)
      "cw--#{name.to_s.tr('_', '-').tr('/', '--')}"
    end

    # data-controller="cw--disclosure"
    def cw_controller(*names)
      { data: { controller: token_list(names.map { cw_identifier(it) }) } }
    end

    # cw_action(:disclosure, "click->toggle", "keydown.esc->close")
    #   => { data: { action: "click->cw--disclosure#toggle keydown.esc->cw--disclosure#close" } }
    def cw_action(name, *bindings)
      id = cw_identifier(name)
      { data: { action: token_list(bindings.map { |b|
        event, method = b.to_s.split("->", 2)
        method ? "#{event}->#{id}##{method}" : "#{id}##{event}"
      }) } }
    end

    # cw_target(:disclosure, :panel) => { data: { "cw--disclosure-target": "panel" } }
    def cw_target(name, target)
      { data: { :"#{cw_identifier(name)}-target" => target.to_s.camelize(:lower) } }
    end

    # cw_values(:disclosure, open: true, url: path) => data-cw--disclosure-open-value="true", ...
    def cw_values(name, **values)
      id = cw_identifier(name)
      { data: values.compact.transform_keys { |k| :"#{id}-#{k.to_s.dasherize}-value" } }
    end

    # cw_classes(:disclosure, open: "is-open") => data-cw--disclosure-open-class="is-open"
    def cw_classes(name, **classes)
      id = cw_identifier(name)
      { data: classes.compact.transform_keys { |k| :"#{id}-#{k.to_s.dasherize}-class" } }
    end

    def cw_params(name, **params)
      id = cw_identifier(name)
      { data: params.compact.transform_keys { |k| :"#{id}-#{k.to_s.dasherize}-param" } }
    end

    def cw_outlet(name, outlet, selector)
      { data: { :"#{cw_identifier(name)}-#{outlet.to_s.dasherize}-outlet" => selector } }
    end

    # The composer. Merges any number of the above (plus raw hashes) correctly.
    #   cw_attrs(cw_controller(:disclosure), cw_target(:disclosure, :panel), class: "panel")
    def cw_attrs(*hashes, **rest)
      Crosswire::Attributes.merge(*hashes, rest)
    end
  end
end
```

`cw_attrs` is the piece Solidus is missing: `**a, **b` silently drops a duplicate
`data-action`, whereas `cw_attrs(a, b)` unions it.

### 4.3 Layer 1 — the presenter (only where structure warrants)

```ruby
# app/presenters/crosswire/disclosure.rb
module Crosswire
  class Disclosure
    include Crosswire::Customizable

    NAME = :disclosure
    ELEMENTS = %i[ root trigger panel ].freeze
    PROTECTED = %i[ id role type aria-controls aria-expanded ].freeze

    def initialize(view, open: false, id: nil, **attrs)
      @view, @open, @id = view, open, id || "cw-disclosure-#{SecureRandom.hex(4)}"
      @attrs = attrs
    end

    def root_attrs
      customize :root, base: cw_attrs(
        view.cw_controller(NAME),
        view.cw_values(NAME, open: @open),
        class: "cw-disclosure",
        **@attrs
      )
    end

    def trigger_attrs
      customize :trigger, base: cw_attrs(
        view.cw_target(NAME, :trigger),
        view.cw_action(NAME, "click->toggle"),
        type: "button",
        class: "cw-disclosure__trigger",
        aria: { expanded: @open.to_s, controls: panel_id }
      )
    end

    def panel_attrs
      customize :panel, base: cw_attrs(
        view.cw_target(NAME, :panel),
        id: panel_id,
        class: "cw-disclosure__panel",
        hidden: !@open
      )
    end

    def panel_id = "#{@id}-panel"

    private
      attr_reader :view
  end
end
```

Note `aria-expanded` and `aria-controls` are computed in Ruby *and* declared `PROTECTED`.
That is the a11y argument for the helper layer: the correct ARIA wiring ships once, and a
consumer cannot accidentally remove it while restyling. (The Stimulus controller keeps
`aria-expanded` in sync at runtime; Ruby sets the initial, no-JS-yet value.)

### 4.4 Blocks instead of slots

ViewComponent slots are the feature we're giving up. The plain-helper substitute: **a
helper yields its presenter, and the consumer places the parts.** This covers the large
majority of what `renders_one` is used for, in one line of Ruby.

```ruby
def crosswire_disclosure(**options, &block)
  presenter = Crosswire::Disclosure.new(self, **options)
  tag.div(**presenter.root_attrs) { capture(presenter, &block) }
end
```

```erb
<%= crosswire_disclosure(open: false) do |d| %>
  <%= tag.button "Details", **d.trigger_attrs %>
  <%= tag.div **d.panel_attrs do %>
    …whatever the consumer wants…
  <% end %>
<% end %>
```

This is exactly the `form_with |f|` shape every Rails developer already knows, it needs no
framework, and the consumer's markup is genuinely their own. For components where the
consumer usually *doesn't* care (a spinner, a clipboard button), ship the Layer-3 one-liner
instead and let the block form be the escape hatch.

---

## 5. Worked example: the same component, three ways

The component: a **disclosure** (button toggles a panel). Generic controller, injected
classes, correct ARIA.

### The controller (shipped, generic, hardcodes nothing)

```js
// app/javascript/crosswire/controllers/disclosure_controller.js
import { Controller } from "@hotwired/stimulus"
import { transition } from "crosswire/transition"

export default class extends Controller {
  static targets = ["trigger", "panel"]
  static values  = { open: Boolean }
  static classes = ["open"]           // optional — see note below

  openValueChanged() { this.#render() }

  toggle() { this.openValue = !this.openValue }

  async #render() {
    this.triggerTarget?.setAttribute("aria-expanded", this.openValue)
    // `hasOpenClass` guard: `this.openClass` THROWS when the attribute is absent.
    if (this.hasOpenClass) this.element.classList.toggle(this.openClass, this.openValue)
    await transition(this.panelTarget, this.openValue)
  }
}
```

> The `hasOpenClass` guard is mandatory, not stylistic. Stimulus's `ClassPropertiesBlessing`
> raises `Missing attribute "data-…-open-class"` on a bare `this.openClass` read
> (`stimulus/src/core/class_properties.ts`). Every crosswire controller must guard, or use
> the always-safe plural `this.openClasses` (which returns `[]`). This is the #1 way a
> generic controller breaks for a consumer who didn't pass a class.

### Way 1 — bare ERB, no helper

Everything is visible; nothing is hidden. This is the documentation baseline and the
`crosswire eject --to-erb` output.

```erb
<div class="cw-disclosure"
     data-controller="cw--disclosure"
     data-cw--disclosure-open-value="false">
  <button type="button"
          class="cw-disclosure__trigger"
          aria-expanded="false"
          aria-controls="faq-1-panel"
          data-cw--disclosure-target="trigger"
          data-action="click->cw--disclosure#toggle">
    Details
  </button>
  <div id="faq-1-panel"
       class="cw-disclosure__panel"
       hidden
       data-cw--disclosure-target="panel">
    …
  </div>
</div>
```

**Cost:** 5 hand-typed identifiers that must agree; `aria-controls`/`id` must be unique per
page and kept in sync by hand; `aria-expanded` duplicated in two places. Multiply by 30
components and this is exactly the friction that makes teams give up and write an
app-specific controller with the strings baked in.

### Way 2 — with our helper

```erb
<%= crosswire_disclosure id: "faq-1" do |d| %>
  <%= tag.button "Details", **d.trigger_attrs %>
  <%= tag.div **d.panel_attrs do %>
    …
  <% end %>
<% end %>
```

or, for the common case, the fully-packaged Layer-3 form:

```erb
<%= crosswire_disclosure_tag "Details", id: "faq-1" do %>
  …
<% end %>
```

Identical HTML to Way 1. The IDs, the ARIA pair, the target names and the action string are
all derived. **And the caller can still add their own controller to the same element
without breaking ours:**

```erb
<%= crosswire_disclosure id: "faq-1",
      data: { controller: "analytics", action: "click->analytics#track" } do |d| %>
```

```html
<div class="cw-disclosure"
     data-controller="cw--disclosure analytics"
     data-action="click->analytics#track"
     data-cw--disclosure-open-value="false">
```

That merge is the thing no production codebase gets right today, and §6 is how.

### Way 3 — consumer's own markup

Three escape hatches, in increasing order of divergence.

**3a. Keep our helper, restyle and re-arrange via `customize_*`:**

```erb
<%= crosswire_disclosure id: "faq-1" do |d| %>
  <% d.customize_panel class: "rounded-lg border p-4", data: { testid: "faq-panel" } %>
  <%= tag.summary "Details", **d.trigger_attrs %>
  <%= tag.div **d.panel_attrs do %>…<% end %>
<% end %>
```

`class` unions (`cw-disclosure__panel rounded-lg border p-4`); `data-testid` is added;
`id`/`role`/`aria-controls` are refused because they're in `PROTECTED`.

**3b. Drop to Layer 0 and write the markup yourself, keeping correctness:**

```erb
<details <%= tag.attributes(**cw_attrs(cw_controller(:disclosure),
                                       cw_values(:disclosure, open: false),
                                       cw_classes(:disclosure, open: "is-open"))) %>>
  <summary <%= tag.attributes(**cw_attrs(cw_target(:disclosure, :trigger),
                                         cw_action(:disclosure, "click->toggle"))) %>>
    Details
  </summary>
  <div <%= tag.attributes(**cw_target(:disclosure, :panel)) %>>…</div>
</details>
```

Completely different element structure — `<details>` instead of `<div>` — and the
controller still works, because the controller only ever knew about targets and values.
**This is the payoff for keeping controllers generic.**

**3c. Shadow the partial.** Create `app/views/crosswire/_disclosure.html.erb` in the app;
Rails' view path precedence means it wins over the engine's copy, for every call site at
once, with no code change ([§8](#8-customization--ejection)).

---

## 6. The merge problem, solved

### 6.1 Statement

Every helper that injects Stimulus attributes must combine its own attributes with the
caller's. Three attributes are **space-separated token lists that must union**:

- `class`
- `data-controller`
- `data-action`

Everything else is last-writer-wins. Rails provides `token_list` for the first and nothing
for the other two, and `data:` **JSON-encodes arrays**, so the natural-looking
`data: { controller: [ours, theirs] }` is silently broken ([§2.3](#23-tag_options-the-data-trap)).

The five production implementations solve it five different ways — `"#{a} #{b}".strip`,
`[a,b].compact.join(" ")`, `token_list`, `deep_merge`, and not at all — and none of them
dedupes.

### 6.2 The solution

One module, ~45 lines, no dependencies beyond ActionView.

```ruby
# lib/crosswire/attributes.rb
module Crosswire
  # Type-aware merge for HTML attribute hashes.
  #
  # Rails has no merge-don't-clobber facility for attributes: `form_with` does a shallow
  # `merge!` (actionview/lib/action_view/helpers/form_helper.rb:1597), and `tag`
  # JSON-encodes Arrays inside `data:` (tag_helper.rb:315) rather than joining them, so
  # `data: { controller: ["a", "b"] }` silently renders `data-controller="[&quot;a&quot;…"`.
  #
  # Rules:
  #   * `class`, `data-controller`, `data-action` UNION (deduped, order-preserving)
  #   * `data:` and `aria:` merge recursively
  #   * everything else is last-writer-wins
  #   * an explicit `nil` DELETES the key (so callers can opt out of our defaults)
  #   * `"data-controller" => x` and `data: { controller: x }` are the same key
  module Attributes
    extend self

    TOKEN_ATTRS      = %i[ class ].freeze
    TOKEN_DATA_ATTRS = %i[ controller action ].freeze
    NESTED_ATTRS     = %i[ data aria ].freeze

    # `token_list` needs a view-ish receiver; it only depends on these two modules.
    Tokenizer = Class.new do
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::OutputSafetyHelper
    end.new
    private_constant :Tokenizer

    def merge(*hashes)
      hashes.compact.map { |h| symbolize(h) }.reduce({}) { |base, override| merge_two(base, override) }
    end

    def tokens(*values)
      Tokenizer.token_list(*values).presence
    end

    private
      def merge_two(base, override)
        merged = base.merge(override) do |key, old, new|
          if TOKEN_ATTRS.include?(key)     then tokens(old, new)
          elsif key == :data               then merge_data(old, new)
          elsif NESTED_ATTRS.include?(key) then merge_two(symbolize(old), symbolize(new))
          else new
          end
        end
        merged.reject { |k, _| override.key?(k) && override[k].nil? }
      end

      def merge_data(old, new)
        symbolize(old).merge(symbolize(new)) do |key, o, n|
          TOKEN_DATA_ATTRS.include?(key) ? tokens(o, n) : n
        end
      end

      # Symbolize + underscore keys, and hoist flat `data-*`/`aria-*` keys into their
      # nested hash so both spellings merge against each other.
      def symbolize(hash)
        (hash || {}).to_h.each_with_object({}) do |(key, value), out|
          key = key.to_s.tr("-", "_")
          if (m = key.match(/\A(data|aria)_(.+)\z/))
            prefix, rest = m[1].to_sym, m[2].to_sym
            out[prefix] = (out[prefix] || {}).merge(rest => value)
          elsif NESTED_ATTRS.include?(key.to_sym)
            out[key.to_sym] = (out[key.to_sym] || {}).merge(symbolize(value))
          else
            out[key.to_sym] = value
          end
        end
      end
  end
end
```

### 6.3 Why it is correct

It leans on the three verified properties of `token_list` from
[§2.1](#21-token_list--class_names):

- **dedupes** — `merge` is idempotent, so a helper calling a helper calling a helper cannot
  produce `data-controller="cw--disclosure cw--disclosure"`;
- **escape-stable** — `CGI.unescape_html` means an already-merged (`&gt;`-escaped)
  `data-action` can be merged again without double-escaping. This is what makes the
  primitive safe to apply at every layer instead of exactly once;
- **nil/false-tolerant** — no `.compact` or `.strip` dance needed at any call site.

### 6.4 Verified behaviour

All 14 assertions pass against ActionView 8.1.3.1:

```
PASS  class union                                  "btn" + "btn btn--primary" -> "btn btn--primary"
PASS  data-controller union                        "auto-submit" + "tooltip"  -> "auto-submit tooltip"
PASS  data-controller dedupes                      "auto-submit" + "auto-submit tooltip" -> "auto-submit tooltip"
PASS  data-action union (escaped, browser-decodes) -> "click-&gt;a#b input-&gt;a#c"
PASS  data-action idempotent under re-merge        -> "click-&gt;a#b input-&gt;a#c keydown-&gt;a#d"
PASS  non-token data key: last wins
PASS  other data keys preserved across merge
PASS  scalar last-wins
PASS  explicit nil deletes
PASS  absent key does not delete
PASS  dashed string keys normalize                 {"data-controller"=>"a"} + {data:{controller:"b"}} -> "a b"
PASS  aria merges recursively
PASS  nil hash tolerated
PASS  class accepts array + hash forms
```

End-to-end render:

```ruby
Crosswire::Attributes.merge(
  { class: "cw-disclosure", data: { controller: "cw--disclosure", action: "click->cw--disclosure#toggle" } },
  { class: "my-thing",      data: { controller: "analytics",      action: "click->analytics#track", turbo_frame: "_top" } }
)
```

```html
<div class="cw-disclosure my-thing"
     data-controller="cw--disclosure analytics"
     data-action="click-&gt;cw--disclosure#toggle click-&gt;analytics#track"
     data-turbo-frame="_top"></div>
```

### 6.5 Design notes

- **Last-writer-wins for scalars, i.e. the consumer wins.** Deliberately the opposite of
  hotwire_combobox's `custom.deep_merge default` (base-wins), which surprises people. What
  the consumer must *not* override is handled by `PROTECTED_ATTRS` on the presenter, which
  is explicit rather than emergent.
- **Explicit `nil` deletes.** `crosswire_disclosure(class: nil)` removes our default class
  entirely, which is the "I'm using my own design system" escape hatch. Note that an
  *absent* key does not delete — tested.
- **`false` is not `nil`.** `data: { x: false }` renders `data-x="false"` (correct for
  Stimulus Boolean values). Use `nil` to omit. Helpers should `.presence` any conditional
  string before putting it in `data`.
- **Ship it as public API** (`Crosswire::Attributes.merge`, and `cw_attrs` in views). It is
  useful to consumers writing their *own* controllers, and it is the single most
  reusable artifact in the whole library — arguably the best standalone advertisement for
  crosswire.

---

## 7. Theming & CSS strategy

### 7.1 Three consumers, one library

Crosswire must work for an app using Tailwind, an app using plain CSS with custom
properties (the 37signals house style), and an app with its own design system. The only way
to serve all three is that **the controller hardcodes zero class names** — which is
precisely why Stimulus has a CSS Classes API.

```ts
// stimulus/src/core/class_map.ts
getDataKey(name: string) { return `${name}-class` }     // -> data-<identifier>-<name>-class
```

```ts
// stimulus/src/core/class_properties.ts
[`${key}Class`]: { get() {
  if (classes.has(key)) return classes.get(key)
  throw new Error(`Missing attribute "${classes.getAttributeName(key)}"`)   // <- THROWS
}},
[`${key}Classes`]:      { get() { return this.classes.getAll(key) } },      // safe, [] when absent
[`has${capitalize(key)}Class`]: { get() { return this.classes.has(key) } },
```

**There is no default-value mechanism.** A generic controller that reads `this.openClass`
without checking `this.hasOpenClass` will throw for every consumer who didn't pass the
attribute. Two consequences for crosswire, both non-negotiable:

1. Every controller guards with `hasXClass` (or uses the plural `xClasses`).
2. Every helper **passes a sensible default class**, so the guard rarely fires and the
   component looks right out of the box:
   `cw_classes(:disclosure, open: options.fetch(:open_class, "cw-disclosure--open"))`.

That combination — controller tolerates absence, helper supplies a default, consumer can
override or `nil` it away — is the whole theming story in one line per class.

### 7.2 Transitions: the best runtime idea in the ecosystem

`tailwindcss-stimulus-components`' transition module is worth adopting nearly verbatim. Its
insight: **read the transition classes off `data-*` attributes**, so the library ships
sequencing logic and zero class names.

```js
// tailwindcss-stimulus-components/src/transition.js
function getTransitionOptions(type, element, transitionOptions) {
  return {
    transitionClasses: element.dataset[`transition${type}`]     || transitionOptions[type.toLowerCase()]     || type.toLowerCase(),
    fromClasses:       element.dataset[`transition${type}From`] || transitionOptions[`${type.toLowerCase()}From`] || `${type.toLowerCase()}-from`,
    toClasses:         element.dataset[`transition${type}To`]   || transitionOptions[`${type.toLowerCase()}To`]   || `${type.toLowerCase()}-to`,
    toggleClass:       element.dataset.toggleClass              || transitionOptions.toggleClass || transitionOptions.toggle || 'hidden'
  }
}
```

Note the **three-tier fallback**: element `data-*` → controller-supplied options → a plain
literal default (`"enter"`, `"enter-from"`, `"enter-to"`, `"leave"`, …, `"hidden"`). A
Tailwind app passes utility strings; a plain-CSS app defines `.enter { transition: … }` in
its own stylesheet and passes nothing. **Same library, both worlds, no configuration.**

The sequencing is a double `requestAnimationFrame` plus a computed-duration timeout:

```js
function performTransitions(element, transitionStages) {
  if (element._stimulus_transition) cancelTransition(element)
  let interrupted, firstStageComplete, secondStageComplete
  setupTransition(element)

  element._stimulus_transition.cleanup = () => {
    if (!firstStageComplete)  transitionStages.firstFrame()
    if (!secondStageComplete) transitionStages.secondFrame()
    transitionStages.ending()
    element._stimulus_transition = null
  }

  return new Promise((resolve) => {
    requestAnimationFrame(() => {
      transitionStages.firstFrame();  firstStageComplete = true
      requestAnimationFrame(() => {
        transitionStages.secondFrame(); secondStageComplete = true
        element._stimulus_transition.timeout = setTimeout(() => {
          element._stimulus_transition.cleanup(); resolve()
        }, getAnimationDuration(element))
      })
    })
  })
}

function getAnimationDuration(element) {
  let duration = Number(getComputedStyle(element).transitionDuration.replace(/,.*/, '').replace('s', '')) * 1000
  let delay    = Number(getComputedStyle(element).transitionDelay.replace(/,.*/, '').replace('s', '')) * 1000
  if (duration === 0) duration = Number(getComputedStyle(element).animationDuration.replace('s', '')) * 1000
  return duration + delay
}
```

Three things it gets right that are easy to get wrong: it **reads the real duration from
computed style** rather than requiring the caller to declare it; it is **interruptible**,
with `cleanup()` fast-forwarding any un-run stage so a double-toggle can't strand classes;
and it **returns a Promise**, so controllers can `await transition(...)` before removing an
element.

**Adopt it, with these changes:** ship as `crosswire/transition`, `await`-able (already
is); add `prefers-reduced-motion` short-circuit (**it has none — a real a11y gap**); and
expose the durations through the helper so Ruby can set them.

Helper side:

```ruby
def cw_transition(enter: nil, enter_from: nil, enter_to: nil,
                  leave: nil, leave_from: nil, leave_to: nil, toggle: nil)
  { data: {
      transition_enter: enter, transition_enter_from: enter_from, transition_enter_to: enter_to,
      transition_leave: leave, transition_leave_from: leave_from, transition_leave_to: leave_to,
      toggle_class: toggle
    }.compact }
end
```

### 7.3 Headless + optional stylesheet

Ship **two** stylesheets and make the split explicit:

| | Contents | Loaded by |
|---|---|---|
| `crosswire/structure.css` | only what makes components *function*: visually-hidden announcer, `[hidden]` handling, focus-trap sizing, scroll-lock | always (recommended in the install generator) |
| `crosswire/theme.css` | opinionated look: colours, spacing, radii — all via custom properties | opt-in |

hotwire_combobox draws exactly this line, and even inlines the load-bearing rules into the
markup so they cannot be lost (`app/views/hotwire_combobox/_component.html.erb`):

```erb
<%= tag.style nonce: content_security_policy_nonce do %>
  <%# Essential styles defined here, removing these would break the combobox %>
  .hw-combobox__announcer { position: absolute; width: 1px; height: 1px; … clip: rect(0,0,0,0); }
<% end %>
```

Inlining with a CSP nonce is a neat trick for the handful of rules that must never be
missing. Use it sparingly — the visually-hidden announcer is the canonical case.

Its theme layer is pure custom properties, which is the model to copy:

```css
:root {
  --hw-active-bg-color: #F3F4F6;
  --hw-border-color: #D1D5DB;
  --hw-focus-color: #2563EB;
  --hw-border-radius: 0.375rem;
  --hw-combobox-width: 10rem;
}
```

A consumer retunes the whole component by redefining `--cw-*` in their own CSS — no
specificity war, no `!important`, no build step. This is also how 37signals do it in Fizzy
(`app/assets/stylesheets/_global.css` defines `--inline-space`, `--text-small`, `--font-sans`
… and components consume them), which means **crosswire's theme layer can be made to
inherit an app's existing tokens** by defaulting to them:
`--cw-space: var(--inline-space, 1ch)`.

**Rule for crosswire: never ship a Tailwind utility class in default markup.** Ship
`cw-*` semantic classes plus `--cw-*` custom properties. Tailwind users pass utilities
through `class:`/`customize_*`/`cw_classes` and they union cleanly (§6). A gem that
hardcodes `flex items-center gap-2` is unusable without Tailwind and unstylable with it.

---

## 8. Customization & ejection

Five exits, in order of escalation. The design goal is that **the consumer never has to
fork**, and that each step costs more than the last but strictly less than the next.

### 8.1 Attribute pass-through (free)

Any unknown keyword goes onto the root element and merges: `class:`, `data:`, `aria:`,
`id:`, `style:`, `hidden:`. Union for token attrs, last-wins for scalars, `nil` deletes.

### 8.2 `customize_*` for inner elements

hotwire_combobox's `CUSTOMIZABLE_ELEMENTS` + `PROTECTED_ATTRS`, adopted with the base/custom
precedence corrected so the consumer wins. Reaches inner elements without exposing markup.

### 8.3 Variants ("looks")

Administrate's `partial_prefixes` mechanism, which turns variants into lookup paths:

```ruby
def self.local_partial_prefixes(look: :default)
  fallback = ["fields/#{field_type}/looks/default", "fields/#{field_type}"]
  look == :default ? fallback : ["fields/#{field_type}/looks/#{look}"] + fallback
end
```

For crosswire: `crosswire_disclosure(look: :compact)` renders
`crosswire/disclosure/looks/compact/_disclosure` if it exists, else the default. **The
consumer adds a look by creating a file** — no registration, no config. This is the
cheapest possible extension point and it costs us ~6 lines.

### 8.4 Shadow the partial (no code change)

Because engines `prepend_view_path` and the application prepends last
([§3.1](#31-the-decisive-finding-viewcomponent-templates-are-not-on-the-view-lookup-path)),
creating `app/views/crosswire/_disclosure.html.erb` overrides the engine's copy **for every
call site simultaneously**. The helper, the presenter, the controller and the CSS all keep
working; only the markup changes. This is the single biggest architectural advantage of
partials over ViewComponent for a library like this, and it should be documented as the
primary customization route, not as a hack.

Ship a generator to seed the file, exactly as Administrate does:

```ruby
# administrate/lib/administrate/view_generator.rb
def copy_resource_template(template_name)
  copy_file "#{template_name}.html.erb",
            "app/views/#{namespace}/#{resource_path}/#{template_name}.html.erb"
end
```

```
$ bin/rails g crosswire:views disclosure
      create  app/views/crosswire/_disclosure.html.erb
```

### 8.5 Full ejection

```
$ bin/rails g crosswire:eject disclosure
      create  app/views/crosswire/_disclosure.html.erb
      create  app/javascript/controllers/disclosure_controller.js
      create  app/helpers/disclosure_helper.rb
      create  app/assets/stylesheets/disclosure.css
```

Copies everything, rewrites the `cw--disclosure` identifier to plain `disclosure`, and
leaves no reference to crosswire. **The consumer keeps the code and drops the dependency.**

This should be a headline feature, not a grudging escape hatch. It is the strongest
possible answer to "what if this gem goes unmaintained", it makes crosswire safe to adopt
incrementally, and — given the project's stated purpose as a *collection of skills,
components and recipes* — being ejectable is arguably the point. `--to-erb` additionally
inlines the helper into literal ERB (Way 1 of §5) for people who want no abstraction at all.

---

## 9. Naming conventions

Thirty components stay coherent only if the name of any one thing is derivable from the
name of the component. One rule: **`snake_case` in Ruby, `kebab-case` in the DOM,
`camelCase` in JS, and the transformation is mechanical.**

### 9.1 The table

| Thing | Convention | Example |
|---|---|---|
| Component name | `snake_case` singular | `disclosure`, `combobox`, `sortable_list` |
| **Stimulus identifier** | `cw--<kebab>` | `cw--disclosure`, `cw--sortable-list` |
| Controller file | `app/javascript/crosswire/controllers/<name>_controller.js` | `disclosure_controller.js` |
| Importmap pin | `crosswire/controllers/<name>_controller` | — |
| **Helper (Layer 3)** | `crosswire_<name>` / `crosswire_<name>_tag` | `crosswire_disclosure_tag` |
| Helper module | `Crosswire::<Name>Helper` | `Crosswire::DisclosureHelper` |
| Presenter (Layer 1) | `Crosswire::<Name>` | `Crosswire::Disclosure` |
| Attr methods | `<element>_attrs` | `trigger_attrs`, `panel_attrs` |
| Partial | `app/views/crosswire/_<name>.html.erb` | `_disclosure.html.erb` |
| Variant partial | `app/views/crosswire/<name>/looks/<look>/_<name>.html.erb` | `…/looks/compact/_disclosure.html.erb` |
| **Target** | `camelCase`, noun | `data-cw--disclosure-target="panel"` |
| **Value** | `kebab-case`, noun/adjective | `data-cw--disclosure-open-value="true"` |
| **CSS Class binding** | `kebab-case`, state adjective | `data-cw--disclosure-open-class="is-open"` |
| **Action method** | `camelCase`, verb | `click->cw--disclosure#toggle` |
| **Dispatched event** | `cw--<name>:<past-tense-verb>` | `cw--disclosure:opened` |
| **CSS block** | `cw-<name>` | `.cw-disclosure` |
| **CSS element** | `cw-<name>__<part>` | `.cw-disclosure__panel` |
| **CSS modifier** | `cw-<name>--<state>` | `.cw-disclosure--open` |
| **Custom property** | `--cw-<name>-<prop>` | `--cw-disclosure-panel-bg` |
| Generator | `crosswire:<verb>` | `crosswire:eject`, `crosswire:views` |

### 9.2 Why `cw--` with a double dash

Not decoration. Rails dasherizes underscores in data keys, so `__` → `--`
([§2.3](#23-tag_options-the-data-trap), verified):

```ruby
data: { cw__disclosure_target: "panel" }   # => data-cw--disclosure-target="panel"
```

This means a namespaced identifier is writable in **idiomatic Ruby hash syntax** with no
string interpolation and no quoted symbols. It's the same trick 37signals use in Fizzy
(`data: { bridge__buttons_target: "button" }` → `data-bridge--buttons-target`) and the same
separator Solidus generates from component paths (`solidus-admin--foo`). It is also
importmap-friendly: `pin_all_from … under: "crosswire/controllers"` yields
`crosswire--<name>` identifiers under stimulus-loading's default convention, so **the
filesystem path and the DOM identifier stay mechanically linked** — Solidus's best idea.

Single-dash (`cw-disclosure`) would collide with an app's own `cw-disclosure` controller
and reads ambiguously against kebab-cased multiword names (`cw-sortable-list`: is the
namespace `cw` or `cw-sortable`?). `--` is unambiguous.

### 9.3 Event naming

Dispatch `cw--<name>:<past-tense>` — namespace prevents collision, past tense signals "this
already happened, you're being notified":

```js
this.dispatch("opened")   // Stimulus prefixes with the identifier -> "cw--disclosure:opened"
```

Consumers bind with the ordinary Stimulus syntax, and it merges cleanly with our own
actions via §6:

```erb
<%= crosswire_disclosure data: { action: "cw--disclosure:opened->analytics#track" } %>
```

Where a component wraps a native or Turbo event, keep the original name and don't re-emit.

### 9.4 Two rules that keep 30 components coherent

1. **The component name appears exactly once per artifact name**, in the same position.
   Given `disclosure`, every path and identifier above is derivable without lookup. A
   generator can scaffold all of it, and a test can assert the whole matrix.
2. **Targets are nouns, actions are verbs, values are nouns/adjectives, events are past
   participles.** `panelTarget`, `#toggle`, `openValue`, `:opened`. When these blur, the
   API stops being guessable — which is the only thing that makes 30 components learnable.

---

## 10. Engine mechanics checklist

Distilled from `hotwire_combobox`, `turbo-rails`, `lexxy`, `mission_control-jobs`, `avo`
and `administrate`.

### 10.1 Helpers — auto-include, with an opt-out

```ruby
initializer "crosswire.helpers" do
  ActiveSupport.on_load :action_view do
    require "crosswire/stimulus_helper"
    ActionView::Base.include Crosswire::StimulusHelper
    ActionView::Base.include Crosswire::ComponentHelpers
  end
end
```

This is hotwire_combobox's approach and it is right for a library used in the consumer's
views. (`turbo-rails` uses `helper Turbo::Engine.helpers` inside
`on_load(:action_controller_base)` instead — appropriate when helpers are namespaced under
an isolated engine, but it does not reach `ActionView::Base` for arbitrary render paths.)

Adopt hotwire_combobox's **alias opt-out** for the short names, so a name collision is never
fatal:

```ruby
# always available: crosswire_disclosure_tag
# also available unless Crosswire.bypass_convenience_methods?: disclosure_tag
def self.cw_alias(name)
  alias_method name.to_s.sub(/^crosswire_/, ""), name unless bypass_convenience_methods?
end
```

A consumer overrides any helper by defining the method in `ApplicationHelper` (later in the
ancestor chain wins) or by `prepend`ing a module.

### 10.2 Views — automatic

`app/views/` in the engine is added by railties' `add_view_paths` initializer. Nothing to
configure. Consumer overrides by creating the same path in their app
([§8.4](#84-shadow-the-partial-no-code-change)).

### 10.3 Importmap — merge into the app's map

```ruby
initializer "crosswire.importmap", before: "importmap" do |app|
  if app.config.respond_to?(:importmap)
    app.config.importmap.paths << Engine.root.join("config/importmap.rb")
  end
end
```

```ruby
# config/importmap.rb (in the engine)
pin_all_from Crosswire::Engine.root.join("app/javascript/crosswire/controllers"),
             under: "crosswire/controllers", to: "crosswire/controllers"
pin "crosswire/transition", to: "crosswire/transition.js"
```

This is `avo`'s and `hotwire_combobox`'s pattern, and it is the correct one for crosswire:
pins land in the **consumer's** importmap, so their `eagerLoadControllersFrom` /
`application.register` calls see our controllers.

> **Contrast — do not copy:** `mission_control-jobs` owns a *separate* `Importmap::Map`
> (`MissionControl::Jobs.importmap.draw(...)`) rendered in its own layout. Correct for a
> mounted admin UI with its own `<head>`; wrong for components embedded in consumer views,
> which must share the app's map.

`pin_all_from` is also why **plain JS, not TypeScript** — it pins `.js` files off the
filesystem with no build step. (Ship `.d.ts` alongside if type hints are wanted; they don't
affect the pin.)

### 10.4 Assets — propshaft and sprockets

```ruby
initializer "crosswire.assets" do |app|
  if app.config.respond_to?(:assets)
    app.config.assets.paths << Engine.root.join("app/javascript")
    app.config.assets.paths << Engine.root.join("app/assets/stylesheets")
    app.config.assets.precompile += %w[ crosswire_manifest.js ] if defined?(::Sprockets)
  end
end
```

Adding to `assets.paths` covers **both** propshaft and sprockets (`lexxy` and
`mission_control-jobs` do exactly this). The `precompile` line is sprockets-only —
propshaft resolves through the load path and needs nothing.

> **Heed Avo's scar tissue** (`avo/lib/avo/engine.rb:146-163`): under Sprockets, two files
> compiling to the same logical path (engine's vs app's build) resolve to "whichever was
> written last", silently. Keep crosswire's logical paths unambiguously namespaced
> (`crosswire/structure.css`, never `application.css`) and the problem cannot arise.

### 10.5 Bundler users (esbuild/rollup/webpack)

`pin_all_from` does nothing for them. Ship, and document:

- an npm package (or a `node_modules`-resolvable path) exporting each controller
  individually **and** a bundled `crosswire.js` with a `registerCrosswireControllers(application)`
  helper;
- a prebuilt `app/assets/javascripts/crosswire.esm.js` in the gem (hotwire_combobox ships
  exactly this, pinned via `pin "controllers/hw_combobox_controller", to: "hotwire_combobox.esm.js"`),
  so bundler users can point at a file path with no npm install.

This is the "unbundled per-controller ESM plus a bundled fallback" decision already made;
the engine work is just the two pins above.

### 10.6 Generators

```
lib/generators/crosswire/install/install_generator.rb   # stylesheet link, importmap check, initializer
lib/generators/crosswire/views/views_generator.rb       # copy one partial for overriding  (§8.4)
lib/generators/crosswire/eject/eject_generator.rb       # copy everything, de-namespace    (§8.5)
```

All three are `Rails::Generators::Base` + `copy_file`, following Administrate's
`ViewGenerator`. Keep `source_root` pointed at the engine's real `app/views` so the copied
file is byte-identical to what shipped — the generator is not a template, it's a copy.

### 10.7 Checklist

- [ ] `isolate_namespace Crosswire`
- [ ] Helpers via `ActiveSupport.on_load :action_view` (+ `bypass_convenience_methods?`)
- [ ] `app/views` — automatic; document the override path
- [ ] `config/importmap.rb` merged via `app.config.importmap.paths <<`, `before: "importmap"`
- [ ] `assets.paths` for both `app/javascript` and stylesheets; sprockets manifest guarded by `defined?(::Sprockets)`
- [ ] Prebuilt `crosswire.esm.js` for bundler users
- [ ] Three generators: `install`, `views`, `eject`
- [ ] Zero runtime gem dependencies beyond `rails`
- [ ] Every logical asset path namespaced under `crosswire/`
- [ ] Dummy app in `test/dummy` covering importmap **and** esbuild

---

## 11. Open questions

1. **Lookbook previews for helpers.** The weakest point of the partials-and-helpers verdict.
   ViewComponent previews are Lookbook's happy path; previewing a *helper* likely means a
   preview class that renders a partial that calls the helper. **Needs verification against
   Lookbook's source** — specifically whether `ViewComponent::Preview`-style discovery can
   be pointed at arbitrary templates, and whether previews can be shipped *from the engine*
   rather than the host app. If this turns out to be genuinely bad, the fallback is a small
   Rails app in the repo as the component gallery (which doubles as the docs site) rather
   than reversing the ViewComponent decision.

2. **Do we ship presenters for all ~30 components, or only structured ones?** §4.1 says only
   where structure warrants, but the boundary is fuzzy and inconsistency is its own cost.
   Proposal: presenter iff the component has ≥2 addressable elements. Needs a pass over the
   real component list.

3. **`cw_attrs` vs. per-component keyword args.** `cw_attrs` is flexible but stringly-typed;
   explicit keywords are discoverable and typo-proof but 30× more code. Current lean:
   explicit keywords for documented options, `**rest` merged onto the root for everything
   else.

4. **How much ARIA belongs in Ruby vs. JS?** §4.3 puts initial state in Ruby and live
   updates in the controller, which means the truth is in two places. Alternative: controller
   sets everything on `connect()`, Ruby sets nothing — simpler, but the pre-JS render is
   inaccessible and it flashes. Current lean: keep both, and add a system test per component
   asserting the server-rendered ARIA matches the post-`connect()` ARIA.

5. **`prefers-reduced-motion` in the transition module.** `tailwindcss-stimulus-components`
   has no handling at all. Skip transitions entirely, or honour a
   `data-cw-respect-reduced-motion` opt-out? Leaning: skip by default, because a component
   library that animates against a user's stated OS preference is an a11y bug we'd be
   shipping 30 times.

6. **Turbo morph compatibility.** hotwire_combobox binds
   `turbo:morph-element->hw-combobox#idempotentConnect`. How many crosswire controllers need
   an idempotent-reconnect path, and should that be a shared mixin rather than per-controller?

7. **Does `Crosswire::Attributes` deserve its own gem?** It is useful far beyond crosswire —
   it's the missing Rails primitive. Extracting it is good marketing and good citizenship,
   but adds a release to manage. Leaning: ship inside crosswire first, extract if people ask.

8. **`data-action` ordering under merge.** `token_list` preserves first-occurrence order, so
   crosswire's own actions always fire before a consumer's on the same event. That's a
   sensible default but it is currently accidental rather than chosen — should there be a
   documented way to run a consumer's handler *first*?
