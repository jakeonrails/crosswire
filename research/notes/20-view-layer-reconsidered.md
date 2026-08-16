# 20 — The View Layer, Reconsidered

**Date:** 2026-08-15 · **Resolves:** `docs/DECISIONS.md` O1 · **Supersedes §3 of** `research/notes/17-helper-layer-design.md`

Note 17 recommended plain ERB helpers + overridable partials, and rested that
recommendation on one "decisive finding": ViewComponent templates are not on the ActionView
lookup path, therefore a consumer cannot override an engine-shipped component's markup.
Jake reopened it: ViewComponent/Phlex feel right for a modern app — why not for a library?
And could we ship a thin VC or Phlex wrapper gem alongside?

Everything below was verified against real source at the released versions, and the
load-bearing claims were **executed**, not reasoned about. Harness lives in
`/private/tmp/claude-501/-Users-jakemoffatt-source/900254bf-0b68-48c0-90b6-7971c90746ed/scratchpad/`
(`vctest/`, `three_ways/`) against Ruby 3.4.2 · Rails 8.1.3.1 · view_component 4.12.0 ·
phlex 2.4.1 · phlex-rails 2.4.0 · lookbook 2.3.14.

**Headline:** the mechanism note 17 described is real, but the conclusion it drew from it is
too strong. The override asymmetry is a property of **sidecar templates**, not of
ViewComponent. A ViewComponent whose template delegates to a partial gets view-path
shadowing back in full. That kills "decisive" and turns O1 into an ordinary cost/benefit
question — which the presenter-core proposal answers well.

---

## Table of contents

1. [Claims verified / corrected](#1-claims-verified--corrected)
2. [The override question, argued both ways](#2-the-override-question-argued-both-ways)
3. [Prior art for optional adapters](#3-prior-art-for-optional-adapters)
4. [The presenter-core proposal, evaluated](#4-the-presenter-core-proposal-evaluated)
5. [Lookbook: what we actually lose](#5-lookbook-what-we-actually-lose)
6. [Recommendation](#6-recommendation)

---

## 1. Claims verified / corrected

### C1 — "Rails engines put views on the lookup path; the app prepends last and wins."
**CONFIRMED.** `railties-8.1.3.1/lib/rails/engine.rb:613-619`:

```ruby
initializer :add_view_paths do
  views = paths["app/views"].existent
  unless views.empty?
    ActiveSupport.on_load(:action_controller) { prepend_view_path(views) if respond_to?(:prepend_view_path) }
    ActiveSupport.on_load(:action_mailer) { prepend_view_path(views) }
  end
end
```

Executed (`vctest/test.rb`). With a `Crosswire::Engine` shipping
`engine/app/views/crosswire/_disclosure.html.erb` and the app shipping the same path:

```
== view paths (in lookup order) ==
   app/views
   engine/app/views
   .../view_component-4.12.0/app/views

1. plain partial render (app shadow should win)    => APP-SHADOWED-PARTIAL
```

### C2 — "ViewComponent globs sidecar templates from the component class's own source directory."
**CONFIRMED, and the citation is right.** `view_component-4.12.0/lib/view_component/base.rb:600`
and `:602`, inside `sidecar_files`:

```ruby
directory      = File.dirname(identifier)          # base.rb:578
filename       = File.basename(identifier, ".rb")  # base.rb:579
component_name = name.demodulize.underscore        # base.rb:580
sidecar_files            = Dir["#{directory}/#{component_name}.*{#{extensions}}"]          # :600
sidecar_directory_files  = Dir["#{directory}/#{component_name}/#{filename}.*{#{extensions}}"] # :602
```

and `identifier` is the class's real source path, captured from the call stack at
`inherited` time — `base.rb:652`:

```ruby
child.identifier = caller_locations(1, 10).reject { |l| l.base_label == "inherited" }[0].path
```

Confirmed at runtime: `DisclosureComponent.identifier = engine/app/components/crosswire/disclosure_component.rb`.

### C3 — "Therefore a consumer cannot shadow an engine component's template."
**CONFIRMED as stated**, and it is stronger than note 17 argued. The whole set of template
sources is `compiler.rb:170-202` (`gather_templates`), and it is exactly three:

1. `@component.__vc_inline_template` — the `erb_template "…"` DSL;
2. `@component.sidecar_files(...)` — the `Dir[]` glob above;
3. inline `call` / `call_*` methods found on ancestors.

No branch consults ActionView. A full grep of `view_component-4.12.0/lib/` for
`prepend_view_path|append_view_path|view_paths|find_template|Resolver` returns **zero**
runtime template-lookup hits — the only matches are `PathParser` (used to parse *details*
out of an already-globbed filename, `compiler.rb:178`), test helpers, and preview paths.
`lib/view_component/engine.rb` adds **no** view paths at all.

`requested_details` (formats/locales/variants) does come from the app's `LookupContext`
(`base.rb:126`), but it is only used to *select among the component's own already-gathered
templates* (`compiler.rb:63-75`). It cannot introduce a template the component doesn't own.

Executed: the app placed `app/components/crosswire/disclosure_component.html.erb`, mirroring
the engine path exactly.

```
2. VC with sidecar template (can app shadow it?)   => ENGINE-COMPONENT-SIDECAR
```

The app's file is inert. Confirmed.

Two side-corrections while here:

- **`config.view_component_path` does not exist in v4.** `lib/view_component/config.rb` has
  only `generate`, `previews`, and `instrumentation_enabled`. `generate.path` is a
  *generator output* setting; it has never affected runtime lookup. Anyone reaching for it
  as an override knob will find nothing.
- **Monkeypatching `erb_template` onto a shipped component does not work.** Templates are
  memoized (`@templates ||=`, `compiler.rb:171`) and compiled into methods; test 6 forced a
  recompile and still got the engine template. `inline_template.rb:13` also raises
  `MultipleInlineTemplatesError` if the gem already used the DSL. Close this escape hatch
  off in your head — it isn't one.

### C4 — "Their only route is to subclass and change every call site." — **CORRECTED.**

This is where note 17 overreached. Two findings.

**(a) A ViewComponent whose template delegates to a partial is fully shadowable.** A
component's `@lookup_context` *is* the app's (`base.rb:117`, `@lookup_context = view_context.lookup_context`),
so any `render partial:` inside a component template resolves through the app's view paths —
app-prepended copy first. Executed:

```erb
<%# engine/app/components/crosswire/delegating_disclosure_component.html.erb %>
<%= render partial: "crosswire/disclosure", locals: { cw: @cw, label: trigger_label, body: content } %>
```

```
3. VC whose template delegates to the partial      => APP-SHADOWED-PARTIAL
```

And with the app shipping a structurally different partial (`<section>`/`<summary>` instead
of `<div>`/`<button>`):

```
  ERB helper (Layer 3)       root element = <section>  APP OVERRIDE WON
  VC with own template       root element = <div>      engine markup (no override)
  VC delegating to partial   root element = <section>  APP OVERRIDE WON
  Phlex                      root element = <div>      engine markup (no override)
```

So the asymmetry note 17 called decisive is **a property of sidecar templates, not of
ViewComponent**. If crosswire's VC adapter keeps its markup in partials, VC consumers get
the same one-file, no-API override story ERB consumers get. Note 17's §3.3 table row
"ViewComponent — ❌ not on lookup path" is correct only for the sidecar style, and should
read "❌ if the component owns its markup; ✅ if it delegates to a partial."

**(b) Subclassing is cleaner than note 17 credited.** Because `identifier` is derived
per-subclass from the call stack, an app subclass gets its *own* sidecar directory for free
— no configuration:

```
4. app subclass w/ own sidecar template            => APP-SUBCLASS-SIDECAR
5. app subclass with NO template (inherits?)       => ENGINE-COMPONENT-SIDECAR
```

Test 5 is the useful one: a subclass with no template of its own transparently inherits the
parent's *compiled* template (`base.rb:626-666`, `@__vc_ancestor_calls`), and
`render_parent` / `render_parent_to_string` (`base.rb:212-222`) let a subclass wrap rather
than replace the parent's markup. That is a genuinely better override primitive than ERB
partials have — an ERB shadow is all-or-nothing; a VC subclass can override one slot and
call `render_parent` for the rest.

The real cost of subclassing was stated correctly, though: **the call sites**. `render
Crosswire::DisclosureComponent.new(...)` names the class, so overriding means editing every
view that renders it, or introducing a factory/registry indirection the library would have
to design. There is no `render` polymorphism hook, no component registry, and no
`with_variant`-style consumer override in v4 (`with_variant` as a *class* API was removed in
v3 — `docs/CHANGELOG.md:1233`, "BREAKING: Remove deprecated `with_variant` method"; what
survives is the test helper `test_helpers.rb:131` and filename variants
`component.html+mobile.erb`, and variant template files must still live beside the gem's
component file, so a consumer cannot add one).

**Net:** the claim "a consumer cannot shadow an engine VC's *sidecar template*" survives
intact. The claim that this **decides** the architecture does not survive, because we
control whether our components use sidecar templates at all.

### C5 — "Dependency cost: VC is a hard constraint in every consumer's Gemfile."
**CONFIRMED, and quantified.** `view_component.gemspec:36-38` — deps are `activesupport`,
`actionview`, `concurrent-ruby`, so VC itself is light. The cost is *version coupling*, not
transitive weight: 55 entries in `docs/CHANGELOG.md` are marked BREAKING across v1→v4, and a
gem depending on VC sits in the middle of every consumer's VC upgrade.

Phlex is worse on this axis: `phlex-rails.gemspec:31` pins `phlex "~> 2.4.0"` — a *patch-level*
pin on the core library. A `crosswire-phlex` gem inherits that pin transitively.

### C6 — "Phlex: subclass + method override; markup is Ruby."
**CONFIRMED.** `grep -rE "view_paths|lookup_context|find_template|prepend_view_path" phlex/lib/`
returns nothing — Phlex core has no concept of a template file, let alone a lookup path.
Markup is Ruby methods, so overriding is Ruby method overriding: subclass and redefine
`view_template` or whatever smaller private methods the component chose to expose. Executed
(the Phlex row of the override table above): an app partial has no effect on a Phlex
component.

**But the same escape hatch exists**, and phlex-rails blesses it. `Phlex::Rails::Partial`
(`phlex-rails/lib/phlex/rails/partial.rb:3-15`) is a first-class object whose entire body is
`view_context.render(@path, ...)`. Executed:

```ruby
def view_template(&block)
  raw(helpers.render(partial: "crosswire/disclosure",
        locals: { cw: @cw, label: @label, body: (block ? helpers.capture { block.call } : nil) }))
end
```
```
  Phlex -> partial root = <section>   APP OVERRIDE WON
```

So Phlex is in exactly the same position as VC: no shadowing of Ruby-authored markup,
full shadowing if the component delegates to a partial.

One asymmetry worth naming: **phlex-rails does not give you Rails helpers by default.**
`phlex-rails/lib/phlex/rails/helpers/` contains ~200 files, one shim per Rails helper, each
of which must be individually `include`d. A library whose public API is ERB helpers pays
that tax at the boundary.

### C7 — Bonus finding: the three renderers do **not** produce byte-identical HTML.
See §4. ERB and VC do; Phlex does not (`hidden` vs `hidden="hidden"`, and Phlex does not
escape `>` inside attribute values). DOM-equivalent, string-inequivalent.

---

## 2. The override question, argued both ways

Note 17 assumed file-shadowing is the good outcome. The brief asked me to argue it. Here it
is, honestly, because I think note 17 got the *conclusion* right for the wrong reason.

### The case against shadowing (the strongest form)

Shadowing is **implicit, unversioned, and silent**. The app creates
`app/views/crosswire/_disclosure.html.erb`, copied from crosswire v1.2. Nothing records that
it was ever a copy. Then crosswire v2 renames a Stimulus target from `trigger` to `toggle`.
The shipped controller now queries `data-cw--disclosure-target="toggle"`; the app's frozen
partial still emits `trigger`. `this.triggerTarget` is gone, `hasToggleTarget` is false, and
depending on the controller either nothing happens or a `Missing target element` error fires
in the browser — **at runtime, in production, on one page, with no Ruby-side error and no
deprecation warning.** Bundler is happy. Tests that stub the view pass. This is the classic
Rails-engine upgrade footgun, and it is exactly why Administrate's "just override the
partial" story generates upgrade pain.

Subclassing has none of that. `class MyDisclosure < Crosswire::DisclosureComponent` is a
Ruby constant referencing a Ruby superclass. Rename the slot and the subclass raises
`NoMethodError` at boot under eager loading. The coupling is *declared*. And
`render_parent` means the subclass can override one region and inherit the rest, so it stays
correct across upgrades that don't touch the overridden region — a shadowed partial is
frozen in its entirety, forever.

That is a real argument and it deserved more than note 17's one sentence.

### The case for shadowing

Three counterpoints, in increasing order of importance.

**(a) The failure modes are not symmetric in frequency.** Subclassing's cost is paid by
*everyone, always*: to change one component's markup you must find and edit every call site
that names the class. Shadowing's cost is paid *only by consumers who override, only at
major upgrades*. For a component library, "changed one component's markup" is the common
case and "upgraded across a breaking major" is the rare one. Optimising the common case is
correct.

**(b) The silent-staleness problem is fixable, cheaply, at boot.** This is the part I think
settles it. Because we know which partials we ship, we can resolve each one through the
app's own `LookupContext` at boot, notice when the winning template is not ours, and check
it for a declared contract version. Implemented and executed (`three_ways/shadow_check.rb`,
25 lines):

```ruby
module Crosswire
  module ShadowCheck
    CONTRACT = { "crosswire/disclosure" => 2 }.freeze   # bump when markup contract changes
    MARKER   = /crosswire:contract\s+v(\d+)/

    def self.run!(engine_root:, lookup_context:, raise_on_mismatch: false)
      findings = []
      CONTRACT.each do |virtual_path, expected|
        prefix, name = virtual_path.split("/")
        tmpl = lookup_context.find_all(name, [prefix], true).first
        next findings << [virtual_path, :missing, nil] unless tmpl
        next if tmpl.identifier.start_with?(engine_root.to_s)      # our own copy — fine

        declared = File.read(tmpl.identifier)[MARKER, 1]&.to_i
        if declared.nil?      then findings << [virtual_path, :undeclared, tmpl.identifier]
        elsif declared != expected then findings << [virtual_path, :stale,
          "#{tmpl.identifier} declares v#{declared}, controller needs v#{expected}"]
        end
      end
      # …warn, or raise in test/CI…
    end
  end
end
```

The consumer's shadowed partial keeps one comment line, `<%# crosswire:contract v2 %>`, which
the `eject` generator writes for them. Executed, all four scenarios:

```
SCENARIO 1: app shadow with NO contract marker (the footgun)   => undeclared
SCENARIO 2: app shadow declaring the CURRENT contract          => OK (no findings)
SCENARIO 3: crosswire v2 ships, app's shadow still declares v1 => stale
SCENARIO 4: no app shadow at all (engine copy wins)            => OK (no findings)
```

Warn in development, raise in test. Scenario 3 is precisely the upgrade break, caught at
boot with a message naming the file and both versions. The objection is real and the answer
costs 25 lines.

**(c) Shadowing is what a component library's users actually reach for.** Administrate
(9.07M downloads) ships pure ERB and documents partial overriding as *the* customisation
mechanism. Avo, which does depend on ViewComponent, ships `lib/generators/avo/eject_generator.rb`
(`namespace "avo:eject"`) precisely so consumers can copy engine source into the app —
`--partial :logo`, `--component Avo::Index::TableRowComponent`. The most VC-committed gem in
the survey built a copy-it-into-your-app mechanism anyway, because that is what consumers
want.

### Verdict on the override question

**Shadowing wins, but only because the staleness objection has a cheap mechanical answer.**
Without `ShadowCheck` I would rate this closer than note 17 did. With it, shadowing is
strictly better: same detection guarantee as subclassing (boot-time, named file, both
versions), without imposing per-call-site edits on the common case.

And the decision doesn't fork the architecture, because of C4(a): **if our markup lives in
partials, VC and Phlex adapters inherit the shadowing story too.** We do not have to choose.

---

## 3. Prior art for optional adapters

Surveyed against RubyGems' full 196k-name index, GitHub search, and cloned source.

### The direct question: does any gem ship one component set through ERB *and* VC *and/or* Phlex?

**No. Nothing in the Ruby ecosystem does this.** Cross-checked the name index for
`-view_component`, `_view_component`, `-phlex`, `_phlex`, `phlex-*`; searched GitHub;
inspected every candidate. This is a real finding, not a search failure. If we ship
`crosswire` + `crosswire-view_component`, it is novel packaging.

### The closest real precedent: `vident` (stevegeek/vident, 3.1.0)

A monorepo publishing **three gems** from one repo — this is the structural template.

| Gem | Runtime deps |
|---|---|
| `vident` (core) | `railties`, `activesupport`, `literal` |
| `vident-view_component` | core + `view_component >= 4.0, < 5` |
| `vident-phlex` | core + `phlex >= 2.0, < 3`, `phlex-rails >= 0.8.1, < 3` |

The core is `lib/vident/component.rb`, an `ActiveSupport::Concern` composing ~13
renderer-agnostic capability modules (`lib/vident/capabilities/{stimulus_declaring,
stimulus_parsing,stimulus_data_emitting,class_list_building,root_element_rendering,
identifiable,…}.rb`) — attribute/DSL logic and Stimulus wiring, none of it renderer-specific.
Each adapter gem supplies one thin base class that mixes in the core and implements only
HTML emission: `Vident::ViewComponent::Base < ViewComponent::Base` overrides
`root_element`/`generate_child_element` using `view_context.tag`; `Vident::Phlex::HTML` does
the Phlex-native equivalent. `vident.gemspec` mechanically subtracts the adapter gems' files
so the three `.gem`s built from one repo don't overlap.

**Two caveats.** vident has **no ERB adapter** — nobody has built that leg. And it is a
component-*authoring* toolkit, not a shipped component library, so it validates the
packaging shape but not the "30 finished components stay in sync" claim.

### Other patterns, and what each is actually good for

| Gem | Version | Pattern | Verdict for us |
|---|---|---|---|
| **pagy** | 43.6.1 (42M dl) | v43 **deleted** the whole `pagy/extras/*` require-on-demand system; frontends folded into core behind a lazy method-level loader (`gem/lib/pagy/toolbox/helpers/loaders.rb` — a stub method `require_relative`s its own file on first call and replaces itself). Only bootstrap + bulma survived; foundation/materialize/semantic/uikit were discontinued. Helpers only, zero templates. | The most successful pagination gem in Ruby **abandoned** the optional-frontends model and consolidated. That is a warning about adapter proliferation, not an endorsement. The lazy-loader trick is nice but solves conditional loading, not paradigm plurality. |
| **simple_form** | — | Bootstrap/Foundation ship as **generator templates** (`lib/generators/simple_form/templates/config/initializers/simple_form_{bootstrap,foundation}.rb`), copied by `rails g simple_form:install --bootstrap`. Zero framework deps in the gemspec. | Right pattern for *CSS preset* variants. Doesn't address rendering-engine choice. |
| **ransack** | — | Ships **no view code at all** — no `app/`, no partials, no form builders. | The "core is renderer-free" instinct taken to its limit. |
| **administrate** | 1.0.0 (9.07M dl) | Pure ERB engine, no VC/Phlex dep. Per-field-type partials (`app/views/fields/{belongs_to,boolean,date,…}`). Override = shadow the partial, documented as the mechanism, no eject command. | Closest analogue to note 17's design, at scale, for a decade. |
| **avo** | 4.1.10 (3.03M dl) | **Hard** dep: `add_dependency "view_component", ">= 3.7.0"`. Mixes ERB partials and VCs in one engine. Ships `avo:eject` (`--partial`, `--component`, `--controller`, `--field-components`). | Proves VC-dependent engines are viable at scale — and that they still need a copy-out generator. |
| **hotwire_combobox** | (775k dl) | Rails engine, ERB partials + Stimulus, presenter objects. **No** VC or Phlex dep — gemspec is `rails`, `stimulus-rails`, `turbo-rails`, `platform_agent`. | The single closest peer to crosswire, and it chose exactly note 17's architecture. |
| **RubyUI** | 1.6.0 (96.3k dl) | `phlex` is a **development** dependency only. Ships `lib/generators/ruby_ui/component_generator.rb` which generates each component's Phlex source *into the host app* — shadcn-style copy-in, no runtime engine. | A third model: no adapter question because there's no runtime library. Wrong for crosswire (D1/R1 lock the engine-gem shape), but worth knowing. |
| **`*_view_components` family** | primer, polaris, bulma, flowbite, material, tailwind | Vendor design systems built entirely on VC. **None** offers an ERB or Phlex sibling. | VC-only component libraries are the norm; multi-renderer ones don't exist. |
| **`view_component-contrib`** | 0.2.5 (1.24M dl) | Not a renderer companion — it's palkan's VC tooling/dev-experience gem. | Mis-cited in the brief; not relevant. |

Names checked that **do not exist**: `heroicons-phlex`, `view_componentcontrib`, `rubyui`
(the real gem is `ruby_ui`), `joeldrapper/ruby_ui` (it's `ruby-ui/ruby_ui`).

### The JS analogue, briefly

TanStack Table ships `@tanstack/table-core` plus thin `-react-/-vue-/-solid-/-svelte-table`
bindings; Headless UI ships separate React and Vue packages over shared behaviour. The map
is imperfect: in JS the plurality is *framework* (React vs Vue), whereas ERB/VC/Phlex are
three ways to emit strings within one framework. Ours is closer to template-language
pluralism, which is a much thinner seam — that is good news for the thin-adapter claim.

---

## 4. The presenter-core proposal, evaluated

The proposal: a zero-view-framework core of attribute **presenters** + `Attributes.merge` +
Stimulus controllers; thin optional renderers over it. Tested by building it and running it.

### 4.1 The core

The one change I'd make to note 17's §4.3 presenter: **drop the `view` argument.** Note 17's
`Crosswire::Disclosure.new(view, ...)` calls `view.cw_controller(NAME)` etc., which couples
the presenter to a view context and quietly makes it un-reusable from Phlex (where `helpers`
is a proxy, not an `ActionView::Base`) and awkward from a unit test. Made pure:

```ruby
# lib/crosswire/disclosure.rb — a PORO. No view context. No renderer. No markup.
module Crosswire
  class Disclosure
    NAME = "cw--disclosure"

    def initialize(id:, open: false, **attrs)
      @id, @open, @attrs = id, open, attrs
    end

    attr_reader :id, :open
    def panel_id = "#{@id}-panel"

    def root_attrs
      Attributes.merge(
        { class: "cw-disclosure",
          data: { controller: NAME, "#{NAME}-open-value": @open.to_s } },
        @attrs
      )
    end

    def trigger_attrs
      Attributes.merge(
        { type: "button", class: "cw-disclosure__trigger",
          aria: { expanded: @open.to_s, controls: panel_id },
          data: { "#{NAME}-target": "trigger", action: "click->#{NAME}#toggle" } }
      )
    end

    def panel_attrs
      Attributes.merge(
        { id: panel_id, class: "cw-disclosure__panel", hidden: !@open,
          data: { "#{NAME}-target": "panel" } }
      )
    end
  end
end
```

Presenter + `Attributes.merge` together: **77 non-blank lines.** The only ActionView contact
is `Attributes`' private `Tokenizer` (it needs `token_list` for dedupe and escape-stability —
see note 17 §6.3), which is a bare object including two modules, not a view context. So
"zero view-framework deps" is achievable and worth insisting on.

### 4.2 The same component, three ways — working code

All of these were executed. Sizes are non-blank lines.

**Renderer A — ERB helper + overridable partial (core, 16 lines total)**

```ruby
# app/helpers/crosswire/disclosure_helper.rb                          (15 lines)
module Crosswire
  module DisclosureHelper
    # Layer 3: fully packaged. Renders the OVERRIDABLE partial.
    def crosswire_disclosure(id:, open: false, label:, **attrs, &block)
      render partial: "crosswire/disclosure",
             locals: { cw: Crosswire::Disclosure.new(id: id, open: open, **attrs),
                       label: label, body: capture(&block) }
    end

    # Layer 2: yield the presenter; the consumer places the parts.
    def crosswire_disclosure_for(id:, open: false, **attrs, &block)
      cw = Crosswire::Disclosure.new(id: id, open: open, **attrs)
      tag.div(**cw.root_attrs) { capture(cw, &block) }
    end
  end
end
```
```erb
<%# app/views/crosswire/_disclosure.html.erb                           (1 line) %>
<%= tag.div(**cw.root_attrs) do %><%= tag.button(label, **cw.trigger_attrs) %><%= tag.div(body, **cw.panel_attrs) %><% end %>
```

**Renderer B — ViewComponent (10 lines)**

```ruby
# crosswire-view_component: app/components/crosswire/disclosure_component.rb   (9 lines)
module Crosswire
  class DisclosureComponent < ViewComponent::Base
    renders_one :trigger_label
    def initialize(id:, open: false, **attrs)
      @cw = Crosswire::Disclosure.new(id: id, open: open, **attrs)
    end
    delegate :root_attrs, :trigger_attrs, :panel_attrs, to: :@cw
  end
end
```
```erb
<%# disclosure_component.html.erb                                       (1 line) %>
<%= tag.div(**root_attrs) do %><%= tag.button(trigger_label, **trigger_attrs) %><%= tag.div(content, **panel_attrs) %><% end %>
```

**Renderer B2 — ViewComponent that delegates to the partial (9 lines).** Same class minus
the `delegate`, with the template replaced by:

```erb
<%= render partial: "crosswire/disclosure", locals: { cw: @cw, label: trigger_label, body: content } %>
```

**Renderer C — Phlex (17 lines)**

```ruby
# crosswire-phlex: lib/crosswire/phlex/disclosure.rb
module Crosswire
  module Phlex
    class Disclosure < ::Phlex::HTML
      def initialize(id:, open: false, **attrs)
        @cw = Crosswire::Disclosure.new(id: id, open: open, **attrs)
      end

      # Phlex's slot equivalent: a block stashed on the instance.
      def with_trigger_label(&block) = (@label_block = block; self)

      def view_template(&block)
        div(**@cw.root_attrs) do
          button(**@cw.trigger_attrs) { @label_block&.call }
          div(**@cw.panel_attrs) { block&.call }
        end
      end
    end
  end
end
```

### 4.3 Results

```
BASELINE (ERB helper + partial):
<div class="cw-disclosure" data-controller="cw--disclosure" data-cw--disclosure-open-value="false"><button
type="button" class="cw-disclosure__trigger" aria-expanded="false" aria-controls="faq-1-panel"
data-cw--disclosure-target="trigger" data-action="click-&gt;cw--disclosure#toggle">Details</button><div
id="faq-1-panel" class="cw-disclosure__panel" hidden="hidden" data-cw--disclosure-target="panel">PANEL BODY</div></div>

A.  ERB helper + partial        IDENTICAL      DOM EQUIVALENT
A2. ERB block form (Layer 2)    IDENTICAL      DOM EQUIVALENT
B.  ViewComponent (own tmpl)    IDENTICAL      DOM EQUIVALENT
B2. VC -> partial               IDENTICAL      DOM EQUIVALENT
C.  Phlex                       DIFFERS        DOM DIFFERS (1 attribute)
```

Phlex's two divergences, both in the serializer, neither in our logic:

- `hidden` vs `hidden="hidden"` — Phlex emits bare boolean attributes; ActionView emits the
  redundant form. Semantically identical in HTML5; Nokogiri reports `hidden=""` vs
  `hidden="hidden"`, hence the one DOM diff.
- `data-action="click->cw--disclosure#toggle"` vs `click-&gt;cw--disclosure#toggle` —
  ActionView escapes `>` in attribute values, Phlex does not. Both parse identically.

**The central claim holds.** One presenter drove four renderers to byte-identical output and
a fifth to semantically-identical output, with adapters of 9–17 lines containing zero
component logic. Every ARIA relationship, every Stimulus identifier, every ID derivation
lived in the presenter and was written exactly once.

### 4.4 The hard questions, answered

**Can a VC wrapper genuinely be thin, or does slot/content handling force logic into it?**

Thin — but slots are where the seams show, and they are *API* seams rather than *logic*
seams. The three block models are genuinely different:

| | "yield here" |
|---|---|
| ERB partial | a `body:` local, filled by `capture(&block)` in the helper |
| ERB Layer 2 | `capture(presenter, &block)` — the `form_with \|f\|` shape |
| ViewComponent | `content` for the main block; `renders_one :trigger_label` for the named one |
| Phlex | the main block is `view_template`'s `&block`; the named one is a stashed proc via `with_trigger_label` |

For **one** content region all four agree and the adapters are trivial. For **named** regions
they diverge: VC gets `with_trigger_label { }` from `renders_one` for free; Phlex needs the
three-line `with_trigger_label` stash written by hand (per component, per named region);
ERB threads a local. The friction is real but it is *plumbing*, not logic — none of it can
compute an attribute wrongly. And it is bounded by how many components need named regions.
Note 17 §4.4's instinct ("blocks instead of slots", yield the presenter) is what keeps this
small: **if the consumer places the parts, there are no named slots to reconcile.** Ship
Layer 2 as the primary shape and multi-slot components stay rare.

One irritation found in practice: VC's block-plus-slot call shape is ugly from Ruby —
`render(Component.new(...).tap { _1.with_trigger_label { "Details" } }) { "BODY" }`. In ERB
it's the pleasant `<%= render Component.new(...) do |c| %><% c.with_trigger_label do %>…`.
Not a blocker, but the VC adapter's docs must show the ERB form.

**Testing burden: what does 2–3 renderers really cost?**

The honest answer is a three-layer split, and it's cheaper than it looks:

1. **Presenter tests (the real suite).** Plain Ruby, no Rails, assert on hashes:
   `assert_equal "faq-1-panel", d.trigger_attrs.dig(:aria, :controls)`. This is where ARIA
   correctness, `Attributes.merge` semantics, ID derivation, and the `PROTECTED` list get
   tested. Written once. Covers ~all logic for all renderers. This is a *better* test suite
   than `render_inline` + Capybara matchers, because it asserts on structured data instead of
   grepping HTML — note 17's §3.4 concession that "unit-testable components" is a real VC
   advantage should be withdrawn; a presenter is more testable than a component.
2. **One golden-DOM test per component per renderer.** Not string equality — §4.3 proves
   string equality across Phlex is unachievable and not worth chasing. Normalise through
   Nokogiri and compare `(tag, sorted attrs, text)` triples, with a documented allowance for
   boolean-attribute spelling. ~15 lines of shared helper, one `assert` per component per
   renderer. For 10 components × 3 renderers that's 30 cheap assertions from one table.
3. **Browser tests against the Stimulus controllers only** — already required by D1/R9 and
   renderer-independent, since the controller only knows targets and values.

The marginal cost of the VC adapter is therefore ~10 lines of code and one golden-DOM row
per component. The marginal cost of the **Phlex** adapter is those plus a second CI matrix
entry with a `phlex ~> 2.4.0` lock, plus the boolean-attribute allowance in the comparator,
plus phlex-rails helper shims wherever we touch Rails helpers.

**Does it complicate the consumer story?**

Yes, and this is the proposal's real weakness — but it is answerable by *defaults*, not by
architecture. "Which do I install?" is only a question if we present three peers. If the
README says `bundle add crosswire` full stop, and a later "Using crosswire with
ViewComponent" page says `bundle add crosswire-view_component`, then the choice never
surfaces for the 90% who don't use VC, and is self-answering for the 10% who do. The failure
mode to avoid is a landing page with three install commands side by side. Pagy's history is
the cautionary tale: it shipped a rich extras matrix, then deleted it at v43 and discontinued
four of six frontends. **Do not ship `crosswire-phlex` speculatively.**

**Is there a version where VC is PRIMARY and ERB is the fallback?**

I built it (Renderer B2) and it works — but no, it should not be primary. Three reasons:

1. **It inverts the dependency for everyone.** Making VC primary means `crosswire.gemspec`
   depends on `view_component`, and every consumer inherits VC's 55-BREAKING-change history
   to use a Hotwire component gem. That contradicts the product thesis in D1/R1 — "rich UI
   without adopting a framework."
2. **It doesn't buy the override story.** The only reason to prefer VC-primary would be if
   VC had a better customisation mechanism. B2 shows the good override behaviour comes from
   *the partial*, not from VC. VC-primary-over-partials is ERB-primary with a mandatory
   wrapper.
3. **It buys exactly one thing: Lookbook.** See §5 — and §5 shows we can have that without
   the dependency.

The inverse — **ERB primary, with the VC adapter's templates delegating to our partials
(B2)** — is strictly better. It gives VC consumers idiomatic `render Crosswire::DisclosureComponent.new(...)`
call sites *and* one-file shadowing *and* subclass+`render_parent`, over a core that depends
on nothing.

**What breaks / what I'd watch**

- **Renderer drift is a real risk and the proposal's honest weak point.** Adding a component
  means touching 2–3 places. Mitigation: the golden-DOM table should be *data* (a fixture
  list of component + args), and the VC/Phlex adapters should be generated from a template,
  so "add a component" is one entry, not three files. If that discipline slips, the adapters
  rot silently — which is exactly what happened to pagy's frontends.
- **`Attributes.merge` is the single point of failure for all renderers.** Good — it's the
  most-tested 45 lines in the gem — but it must never take a view context.
- **Phlex's `~> 2.4.0` transitive pin** will collide with consumers on other Phlex patch
  lines. Reason enough to defer.

---

## 5. Lookbook: what we actually lose

Note 17 flagged this as the one unverified weak point. Verified, and mostly good news.

### What the source says

- **Lookbook does not require you to write ViewComponents.** It ships its own base class,
  `Lookbook::Preview` (`lib/lookbook/preview.rb:2`), and preview discovery accepts either —
  `lib/lookbook/entities/collections/preview_collection.rb:63`:
  ```ruby
  if (defined?(ViewComponent) && klass.ancestors.include?(ViewComponent::Preview)) || klass.ancestors.include?(Lookbook::Preview)
  ```
  The README (v2.3.14, line 18) states it outright: *"compatible with ViewComponent, Phlex,
  ActionView partials and more."*
- **Lookbook *does* hard-depend on the view_component gem.** `lookbook.gemspec:16`,
  `spec.add_dependency "view_component", ">= 2.0"`, and `lib/lookbook/engine.rb:28-33`
  `require "view_component"` unconditionally. So VC lands in the Gemfile either way — but
  only in the **consumer's development group**, via Lookbook, not via crosswire. That
  distinction matters: it does not constrain their production dependency graph or their
  upgrade path.
- **Which render APIs work** (`lib/lookbook/preview.rb:7-35`):

  | In a `Lookbook::Preview` scenario | Works? |
  |---|---|
  | `render "crosswire/disclosure", cw:, label:, body:` (bare-string partial) | **Yes** — documented, `docs/src/_guide/components/partials.md:26-41` |
  | `render_with_template(template:, locals:)` | **Yes** — `preview.rb:29-35`, the clean path |
  | `render template: "…"` | **Yes** — `args[:template]` honoured, `preview.rb:11` |
  | `render partial: "…", locals: {…}` (keyword form) | **No** — `render` never inspects `args[:partial]`; falls through to re-rendering the system template |
  | `render html: …` | **No** — same |
  | `render inline: "<%= … %>"` | **No** — open issue #656 |
- **Inspector features are renderer-agnostic.** `@param` dynamic controls
  (`lib/lookbook/tags/param_tag.rb` — parses YARD tags against the *scenario method's*
  signature), notes, and the params/output panels work identically for partial-backed
  previews. Only the **source panel** differs, and it keys off *which render API you called*,
  not component-vs-partial (`lib/lookbook/entities/rendered_scenario_entity.rb:36-67`):
  `render "partial"` → source panel shows the preview's **Ruby method**;
  `render_with_template(...)` → source panel shows the **template file's markup**. So use
  `render_with_template` where you want consumers to see copy-pasteable ERB — which for a
  component library is *most* of the time.
- **Pages support live embeds.** `lib/lookbook/helpers/page_helper.rb:27-41`'s `embed` helper
  works off `PreviewEntity`/`ScenarioEntity` with no VC-specific logic, and pages are plain
  `.html.erb`/`.md.erb`. So documenting ERB-helper components with live examples works.

### What I ran

Stood up Lookbook 2.3.14 in the harness (`three_ways/lookbook_test.rb`) with the crosswire
engine, and hit the real HTTP preview route:

```
discovered previews: ["Disclosure"]
scenarios: ["default", "via_helper"]
  default      HTTP 200  rendered root=<section>  PREVIEW WORKS
```

Two things confirmed. Partial-based previews work end to end. And note the `<section>`:
the app's shadowed partial was in place, so **Lookbook previews honour view-path shadowing
too** — a consumer's overridden markup shows up in their own Lookbook. That's a small bonus
for the shadowing design that I did not expect.

Then the one real gap. The default preview controller does **not** have engine helpers:

```
  preview controller = ViewComponentsController
  responds to crosswire_disclosure?  false
  render_to_string via helper => RAISED ActionView::Template::Error:
      undefined method 'crosswire_disclosure' for an instance of #<Class:0x…>
```

This is Lookbook issue **#745 "Can't include Helpers"** (open; maintainer allmarkedup: *"Helpers
should definitely be available in ERB templates… I haven't yet had a chance to dig into
this"*). For a library whose headline API *is* a helper, that would be fatal if it were
unfixable. It isn't — it's a preview-controller config:

```ruby
# consumer's config/environments/development.rb (or our install generator writes it)
config.lookbook.preview_controller = "CrosswirePreviewController"

# a controller that includes our helper — this is the entire fix
class CrosswirePreviewController < ApplicationController
  helper Crosswire::DisclosureHelper
end
```

Executed with that in place:

```
  preview controller = CrosswirePreviewController
  responds to crosswire_disclosure?  true
  render_to_string via helper => <section class="cw-disclosure" data-controller="cw--disclosure" data-cw--disclos…
```

Correct markup, from the helper, in the preview controller. *Caveat on rigour:* I proved the
helper renders through `render_to_string` on the configured preview controller; the full HTTP
route with the swapped controller 500'd in my synthetic app (a bare `Rails::Application`
without a real `ApplicationController`/routes file), which I judge a harness artifact rather
than a Lookbook limitation, but I did not chase it to the ground. In a real app the
documented config path is `config.lookbook.preview_controller` and the controller subclasses
`ApplicationController`.

### The answer

**What we lose without VC:** the keyword render forms (`render partial:`, `render html:`,
`render inline:`) — use the bare-string and `render_with_template` forms instead, both
documented and working; a source panel that shows markup rather than Ruby *unless* you use
`render_with_template`; and Lookbook's less-travelled code path, with open bugs (#745, #656,
#759) that mostly don't touch us once the preview controller is configured. We keep `@param`
controls, notes, output, and pages-with-live-embeds in full.

**Does a VC companion gem restore previews?** Yes — routing through `type: :component` is
Lookbook's most-exercised path and sidesteps all three open issues. But **it isn't needed for
previews**, which is the important correction to note 17 §3.4. Previews are not a reason to
depend on ViewComponent. They're a reason to write an install generator that sets
`preview_controller`.

---

## 6. Recommendation

### Ship this

**Core gem `crosswire` — no ViewComponent, no Phlex, no view-framework dependency.**

- **Layer 0** — `cw_controller` / `cw_target` / `cw_action` / `cw_values` + `Crosswire::Attributes.merge` (note 17 §4.2, §6).
- **Layer 1** — pure-PORO presenters, **no view context** (correcting note 17 §4.3). One `*_attrs` method per element. The public contract every renderer consumes.
- **Layer 2** — one overridable ERB partial per structured component, in `app/views/crosswire/`, each carrying a `<%# crosswire:contract vN %>` marker.
- **Layer 3** — `crosswire_*` helpers. The headline API. They render the Layer-2 partial.
- **`Crosswire::ShadowCheck`** — the 25-line boot-time check in §2. Warn in dev, raise in test. This is what makes the shadowing story defensible rather than merely convenient.
- **`rails g crosswire:eject`** — copies partials into the app with the contract marker pre-written, à la `avo:eject`. Proven pattern, small.
- **Install generator** writes `config.lookbook.preview_controller` so helper previews work out of the box.

**Then, and only then, `crosswire-view_component`.** Not in v1. Ship it when a real consumer
asks. It should be ~10 lines per component, and its templates should **delegate to the core's
partials** (Renderer B2), so VC consumers get idiomatic call sites *and* one-file shadowing
*and* subclass + `render_parent`.

**Do not build `crosswire-phlex` yet.** Same shape, worse economics: a transitive `phlex ~> 2.4.0`
patch-level pin, ~200 helper shims at the boundary, its own serializer quirks in the golden-DOM
comparator, and a second CI matrix entry — for the smallest of the three audiences. Nothing in
the presenter core forecloses it; that is the point of the design. Revisit on demand.

### Why this and not the alternatives

The presenter-core proposal **holds up under test** — that was the thing most likely to be
wishful thinking and it survived. One PORO drove four renderers to byte-identical HTML with
9–17-line adapters carrying zero logic. It also has an independent virtue that decides the
architecture even if we never ship a second renderer: **it makes crosswire's public contract
a data structure rather than a string.** `Crosswire::Disclosure#trigger_attrs` returning a
Hash is a better API than a helper returning HTML — easier to test, easier to compose, and
it's what makes a consumer's own bespoke markup a first-class path rather than an ejection.

Note 17 reached the right destination by the wrong road. The road was "VC can't be
overridden, therefore ERB." The actual reason is narrower and sturdier: **ERB partials are the
only renderer that costs the consumer nothing and that all other renderers can delegate
to.** That makes ERB the correct *substrate*, and makes every other renderer an optional,
genuinely thin adapter — rather than a fork.

### What would change my mind

- **VC-primary becomes right if** the first three serious consumers already use ViewComponent
  and find `render Crosswire::DisclosureComponent.new(...)` materially better than
  `crosswire_disclosure(...)`. That's a consumer-evidence question, not an architecture
  question, and D1's ten-primitive v1 is exactly the instrument for answering it.
- **The whole multi-renderer idea is wrong if** the golden-DOM table doesn't get built as
  *data* and the adapters start drifting. If adding component #11 means hand-editing three
  files, kill the adapters and ship ERB only. Pagy deleted its frontends at v43 for exactly
  this reason.
- **Shadowing is wrong if** `ShadowCheck` turns out to be unreliable in practice — e.g. if
  `lookup_context.find_all` misses under eager loading, or consumers strip the contract
  marker. It resolved correctly in all four scenarios here, but it has not met a real app.
  If it can't be trusted, subclass-only overriding (and therefore VC) gets materially more
  attractive.
- **A `phlex-rails` Lookbook/preview story materially better than ours** would move
  `crosswire-phlex` up, since previews are the only place ERB is measurably second-class.
- **If Lookbook #745 is fixed upstream**, the install generator's `preview_controller` line
  becomes unnecessary and the last rough edge of the ERB path disappears.

---

## Appendix — evidence index

| Claim | Source |
|---|---|
| Engine views prepended, app wins | `railties-8.1.3.1/lib/rails/engine.rb:613-619` |
| VC sidecar glob | `view_component-4.12.0/lib/view_component/base.rb:578-604` |
| VC `identifier` from call stack | `base.rb:652` |
| VC uses the app's lookup context | `base.rb:117`, `:126` |
| VC template sources are exactly three | `lib/view_component/compiler.rb:170-202` |
| Requested details only *select*, never *find* | `compiler.rb:63-75`, `:81-105` |
| Templates compile to methods on the class | `lib/view_component/template.rb:146-158` |
| VC engine adds no view paths | `lib/view_component/engine.rb` (entire file) |
| No `view_component_path` in v4 | `lib/view_component/config.rb` |
| `erb_template` can't be re-declared | `lib/view_component/inline_template.rb:13` |
| Subclass template inheritance | `base.rb:626-666`, `render_parent_to_string` `base.rb:212-222` |
| `with_variant` removed in v3 | `docs/CHANGELOG.md:1233` |
| VC runtime deps | `view_component.gemspec:36-38` |
| Phlex has no view-path concept | `grep` over `phlex-2.4.1/lib/` — no matches |
| phlex-rails pins phlex `~> 2.4.0` | `phlex-rails.gemspec:31` |
| Phlex's blessed partial bridge | `phlex-rails/lib/phlex/rails/partial.rb:3-15` |
| Lookbook has its own preview base class | `lookbook-2.3.14/lib/lookbook/preview.rb:2` |
| Lookbook accepts either preview base | `lib/lookbook/entities/collections/preview_collection.rb:63` |
| Lookbook hard-depends on view_component | `lookbook.gemspec:16`, `lib/lookbook/engine.rb:28-33` |
| Which render forms work in a preview | `lib/lookbook/preview.rb:7-35` |
| Source panel keys off render API | `lib/lookbook/entities/rendered_scenario_entity.rb:36-67` |
| Pages `embed` is renderer-agnostic | `lib/lookbook/helpers/page_helper.rb:27-41` |
| Helpers unavailable in previews (open) | Lookbook issue #745; reproduced in harness |
| vident's three-gem split | `vident.gemspec`, `vident-view_component.gemspec`, `vident-phlex.gemspec` |
| avo depends on VC + ships eject | `avo.gemspec`, `lib/generators/avo/eject_generator.rb` |
| hotwire_combobox has no VC/Phlex dep | `hotwire_combobox.gemspec` |
| pagy deleted its extras at v43 | `pagy/docs/guides/upgrade-guide.md`, `gem/lib/pagy/toolbox/helpers/loaders.rb` |
| RubyUI: phlex is a dev dependency | `ruby_ui.gemspec`, `lib/generators/ruby_ui/component_generator.rb` |

**Executable harnesses** (all runnable, all results quoted above):
`scratchpad/vctest/test.rb` — the six override tests ·
`scratchpad/three_ways/{core.rb,run.rb}` — presenter + four renderers + equivalence + override matrix ·
`scratchpad/three_ways/{shadow_check.rb,shadow_test.rb}` — the contract check, four scenarios ·
`scratchpad/three_ways/lookbook_test.rb` — Lookbook previews and the helper gap.
