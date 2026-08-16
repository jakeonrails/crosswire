# 11 — Production Codebases: How Experts Actually Build With Hotwire

*Research date: 2026-08-15. Source-reading task — every claim below is from code read in the repo, not from docs or blog posts.*

Environment facts assumed: `@hotwired/turbo` 8.0.23, `turbo-rails` 2.0.23, hotwire-native 1.3.1, Stimulus frozen at 3.2.2 (Aug 2023). Rails 8 era.

---

## Table of contents

- [Executive summary](#executive-summary)
- [Licensing: read this first](#licensing-read-this-first)
- [Per-codebase notes](#per-codebase-notes)
  - [1. basecamp/fizzy — the single most valuable repo found](#1-basecampfizzy)
  - [2. basecamp/once-campfire](#2-basecamponce-campfire)
  - [3. basecamp/writebook](#3-basecampwritebook)
  - [4. basecamp/lexxy](#4-basecamplexxy)
  - [5. Tier-2 ecosystem survey](#5-tier-2-ecosystem-survey)
- [Controller census](#controller-census)
- [Generic controllers found in the wild](#generic-controllers-found-in-the-wild)
- [Composition techniques observed](#composition-techniques-observed)
- [The helper↔controller pairing (our differentiator)](#the-helpercontroller-pairing-our-differentiator)
- [Turbo usage patterns](#turbo-usage-patterns)
- [Idioms the tutorials miss](#idioms-the-tutorials-miss)
- [What production code avoids](#what-production-code-avoids)
- [Verdict: does the composable-primitive philosophy hold up?](#verdict-does-the-composable-primitive-philosophy-hold-up)

---

## Executive summary

Five findings that should change how the crosswire repo is built:

1. **The composable-primitive philosophy is not just validated — it is how 37signals actually writes Stimulus.** Across three of their production apps, 92 of 126 controllers (73%) are domain-free reusable primitives. In their newest app (Fizzy) it is 53 of 69 (77%). Across all 210 controllers in 10 Hotwire codebases: 62%, or **74% once Avo — which ships one controller per field type — is excluded as a structural outlier.**

2. **The helper↔controller pairing that we thought was unique to `hotwire_combobox` is 37signals' house style, and four other projects reinvented it independently.** It is not informal or occasional — it is systematic. In Campfire and Fizzy, essentially *no* Stimulus wiring appears in a `.erb` template; it all lives in `app/helpers/*.rb` methods that emit `data-controller` / `data-action` / `data-*-value` / `data-*-class`. Solidus, Avo, and Administrate each built their own version. **Five independent implementations, zero documentation.** This is the single strongest finding of the research and it validates crosswire's core bet.

3. **Stimulus controllers are adapters, not implementations.** In Campfire, 59% of the app's JavaScript lives *outside* `controllers/` — in plain ES classes under `models/` and `lib/`. The controller's job is DOM wiring and lifecycle; the logic is a plain object.

4. **For a genuinely complex component, 37signals leaves Stimulus entirely.** Lexxy's 12,316-line editor is Web Components + plain OO classes, with **zero Stimulus**. Stimulus is explicitly the glue tier, not the component tier.

5. **Licensing is the inverse of what we assumed.** Campfire and Writebook are now plain **MIT** — freely copyable with attribution. Fizzy is **not** — it carries a bespoke non-compete "O'Saasy License". See below.

---

## Licensing: read this first

| Repo | License | Can we copy code? |
|---|---|---|
| `basecamp/once-campfire` | **MIT** (`MIT-LICENSE`, © 37signals LLC) | **Yes**, with copyright notice retained |
| `basecamp/writebook` | **MIT** (`MIT-LICENSE`, © 37signals LLC) | **Yes**, with copyright notice retained |
| `basecamp/lexxy` | **MIT** | **Yes**, with notice |
| `rails/mission_control-jobs` | MIT | Yes |
| `hotwired/turbo-rails` | MIT | Yes |
| **`basecamp/fizzy`** | **"O'Saasy License"** — MIT text **plus a non-compete clause** | **Learn from, do NOT vendor** |
| `maybe-finance/maybe` | **AGPL-3.0** | **Do NOT copy** — copyleft would infect crosswire |
| `decidim/decidim` | AGPL-3.0 | Do NOT copy |
| `AlchemyCMS/alchemy_cms` | BSD-3-Clause | Yes, with notice |

### The two landmines

**Fizzy — `LICENSE.md`, clause 2:**

> 2. No licensee or downstream recipient may use the Software (including any modified or derivative versions) to directly compete with the original Licensor by offering it to third parties as a hosted, managed, or Software-as-a-Service (SaaS) product or cloud service where the primary value of the service is the functionality of the Software itself.

This is *not* OSI-approved open source. Crosswire is a documentation/recipe repo, so the non-compete clause is unlikely to bite in practice — but **every Fizzy snippet in this document is quoted for study and is marked `[FIZZY — O'Saasy License]`.** Do not paste Fizzy code into crosswire's shipped component library. Where a Fizzy pattern is worth having, **re-implement it from the idea**, or take the MIT-licensed Campfire/Writebook equivalent where one exists (several of the best primitives exist in both).

**maybe-finance/maybe — AGPL-3.0.** Copying any of its 39 controllers into an MIT/permissive crosswire would be a license violation. Read-only.

**The good news:** the original premise — that Campfire and Writebook are "source-available, not open source" — is **out of date**. Both now ship a standard MIT license file, and `gh api repos/basecamp/once-campfire/license` confirms SPDX `MIT`. The ONCE *distribution* was commercial; the *source* is MIT. We may copy from them freely with attribution.

---

## Per-codebase notes

### 1. basecamp/fizzy

*"Kanban as it should be. Not as it has been."* — 37signals' newest public Rails app, pushed to within hours of this research. **69 Stimulus controllers, 3,455 lines.** This repo was not on the original target list and turned out to be the highest-signal source found. It is the most current expression of 37signals' Hotwire style — it uses Lexxy, Hotwire Native bridge components, and Turbo morphing, none of which Campfire/Writebook do.

**Shape:** plain ERB (no ViewComponent, no Phlex), importmap (no bundler), 38 `.turbo_stream.erb` templates, 69 controllers averaging 50 lines.

**What makes it exceptional:** the ratio of generic to one-off controllers (53:16), and the completeness of the helper layer. Twelve helper files emit Stimulus attributes.

The clearest single example of house style — `app/helpers/columns_helper.rb`:

```ruby
# [FIZZY — O'Saasy License. Study only; do not vendor.]
def column_frame_tag(id, src: nil, data: {}, **options, &block)
  data = data.with_defaults \
    drag_and_drop_refresh: true,
    controller: "frame",
    action: "turbo:before-frame-render->frame#morphRender turbo:before-morph-element->frame#morphReload"
  options[:refresh] = :morph if src.present?
  turbo_frame_tag(id, src: src, data: data, **options, &block)
end
```

Note three things at once: (a) the helper wraps a Turbo primitive (`turbo_frame_tag`), not just a `tag.div`; (b) `data.with_defaults` lets callers override any piece of the wiring; (c) the Stimulus controller name (`frame`) and its event bindings never appear in a template.

And the composition of *action strings* — same file:

```ruby
# [FIZZY — O'Saasy License]
data[:action] = token_list(
  "turbo:before-morph-attribute->collapsible-columns#preventToggle",
  "focus->navigable-list#select",
  data.delete(:action)
)
```

`token_list` (a Rails built-in) is used as an action-string combinator: default bindings plus whatever the caller passed, deduplicated and space-joined. This is the mechanism that makes stacked controllers composable from Ruby.

**Hotwire Native integration is a namespaced controller directory**, `app/javascript/controllers/bridge/` — 8 controllers (`form`, `buttons`, `title`, `stamp`, `overflow_menu`, `insets`, `text_size`, `share`) referenced from ERB as `bridge--form`, `bridge--share`. Paired with `app/helpers/bridge_helper.rb` (`bridged_form_with`, `bridged_share_url_button`). This is a clean answer to "how do I keep native-only behavior out of my web controllers": a namespace plus a helper prefix, not conditionals.

---

### 2. basecamp/once-campfire

The canonical real-time Turbo Streams + ActionCable app. **35 controllers, 1,572 lines.** turbo-rails 2.0.16 (tracked from git), stimulus-rails 1.3.4, importmap, plain ERB, 78 view files.

**The defining statistic:** Campfire has 1,572 lines in `controllers/` and **2,247 lines outside it** — in `app/javascript/models/` (`ScrollManager`, `MessageFormatter`, `MessagePaginator`, `ClientMessage`, `TypingTracker`, `FileUploader`), `app/javascript/lib/autocomplete/` (a 900-line autocomplete engine), and `app/javascript/helpers/`. **59% of Campfire's JavaScript is not in a Stimulus controller.**

The controllers are thin adapters over those objects. `typing_notifications_controller.js` is the archetype: 59 lines that subscribe a cable channel, delegate all state to `new TypingTracker(...)`, and write the result to two targets. `messages_controller.js` (190 lines, the largest) does no real work either — it constructs `MessageFormatter`, `MessagePaginator`, and `ScrollManager` in `connect()` and spends the rest of its body coordinating them.

**The view layer is the surprise.** `app/views/rooms/show.html.erb`, the main screen of a real-time chat app, is 20 lines and contains **not one `data-controller` attribute**:

```erb
<%= message_area_tag(@room) do %>
  <%= render "messages/template" %>

  <%= messages_tag(@room) do %>
    <%= render "rooms/show/invitation", room: @room %>
    <%= render partial: "messages/message", collection: @messages, cached: true %>
  <% end %>

  <%= turbo_stream_from @room, :messages, channel: "RoomMessagesChannel" %>
  <%= button_to_jump_to_newest_message %>
<% end %>
```

All wiring is in `app/helpers/messages_helper.rb` and `app/helpers/rooms_helper.rb`. See [the pairing section](#the-helpercontroller-pairing-our-differentiator).

---

### 3. basecamp/writebook

**22 controllers, 960 lines.** turbo-rails 2.0.11. Plain ERB, importmap.

Writebook's value is twofold. First, **it proves 37signals maintains an informal shared primitive library across apps.** Three controllers are byte-for-byte identical to Campfire's:

```
IDENTICAL: auto_submit_controller.js
IDENTICAL: copy_to_clipboard_controller.js
IDENTICAL: form_controller.js
differs (2 lines):  web_share_controller.js   # only the filename prefix string
differs (8 lines):  lightbox_controller.js
differs (8 lines):  upload_preview_controller.js
```

Plus `app/helpers/forms_helper.rb` is identical in Campfire, Writebook, *and* Fizzy. `helpers/timing_helpers.js` is shared too. There is no gem, no npm package — they copy files between apps. **This is exactly the gap crosswire fills.**

Second, **Writebook is the only app of the four with custom Turbo Stream actions, and it pairs them with a Ruby DSL method.** This is a first-class idiom worth stealing wholesale:

`app/javascript/actions/scroll_into_view.js`:
```js
// [WRITEBOOK — MIT, © 37signals LLC]
import { Turbo } from "@hotwired/turbo-rails"

Turbo.StreamActions.scroll_into_view = function() {
  const animation = this.getAttribute("animation")
  const element = this.targetElements[0]

  element.scrollIntoView({ behavior: "smooth", block: "center" })

  if (animation) {
    element.addEventListener("animationend", () => {
      element.classList.remove(animation)
    }, { once: true })

    element.classList.add(animation)
  }
}
```

`app/helpers/turbo_stream_actions_helper.rb` — the whole file:
```ruby
# [WRITEBOOK — MIT, © 37signals LLC]
module TurboStreamActionsHelper
  def scroll_into_view(id, animation: nil)
    turbo_stream_action_tag :scroll_into_view, target: id, animation: animation
  end
end

Turbo::Streams::TagBuilder.prepend TurboStreamActionsHelper
```

Call site, `app/views/leafables/create.turbo_stream.erb`:
```erb
<%= turbo_stream.scroll_into_view @leaf, animation: :wiggle %>
```

`Turbo::Streams::TagBuilder.prepend` at the bottom of the helper file is the trick. Three files, ~25 lines, and you have a new first-class stream verb with a Ruby signature. Note also that they registered it under `app/javascript/actions/` with its own `pin_all_from` — a directory convention parallel to `controllers/`.

**The one big controller.** `arrangement_controller.js` is 403 lines — 42% of Writebook's controller code in one file. It is a drag-and-drop + keyboard-navigable list reordering primitive. Critically, it is **still domain-free**: grepping it for `book|leaf|page|section|chapter` returns only two constants (`"x-writebook/create"`, `"x-writebook/move"`, drag-and-drop MIME types). Its API is `arrangement_target: "item"` + `arrangement_url_value`. So the counter-example to "controllers should be small" is *not* a counter-example to "controllers should be generic" — it is a large, generic, reusable component. That distinction matters for our thesis.

Its keyboard bindings are generated from a Ruby hash in `app/helpers/arrangement_helper.rb`:

```ruby
# [WRITEBOOK — MIT, © 37signals LLC]
def arrangement_actions
  actions = {
    "click": "click", "dragstart": "dragStart", "dragover": "dragOver:prevent",
    "dragend": "dragEnd", "drop": "drop",
    "keydown.up": "moveBefore", "keydown.right": "moveAfter",
    "keydown.down": "moveAfter", "keydown.left": "moveBefore",
    "keydown.shift+up": "moveBefore", "keydown.shift+right": "moveAfter",
    "keydown.shift+down": "moveAfter", "keydown.shift+left": "moveBefore",
    "keydown.space": "toggleMoveMode", "keydown.enter": "applyMoveMode",
    "keydown.esc": "cancelMoveMode"
  }

  actions.map { |action, target| "#{action}->arrangement##{target}" }.join(" ")
end
```

Sixteen keyboard bindings that would be an unreadable 400-character `data-action` string, expressed as a legible Ruby hash. A tutorial would never show you this.

---

### 4. basecamp/lexxy

37signals' new Lexical-based Action Text editor. **This is the most important negative result in the research.**

- `src/` is **12,316 lines of JavaScript across ~60 files**.
- Stimulus appears **zero times** in `src/`. (The only match for "stimulus" anywhere is an unrelated string in `src/config/dom_purify.js`.)
- The 8 Stimulus controllers in the repo are all in `test/dummy/` — demo glue for the example app, not the library.

Lexxy is built as **custom elements** (`lexxy-editor`, `lexxy-toolbar`, `lexxy-prompt`, `lexxy-code-language-picker`, `lexxy-table-tools`, …) registered in `src/elements/index.js`, driving a set of plain OO classes (`Contents`, `Selection`, `Clipboard`, `CommandDispatcher`).

Their own `STYLE.md:149` states the architecture explicitly:

> Lexxy's JavaScript is a set of plain ES modules. The editor is a custom element (`<lexxy-editor>`) that builds a handful of object-oriented controllers (`Contents`, `Selection`, `Clipboard`) around a Lexical editor, plus a set of extensions for optional behavior. Lexical is *a component we drive*, not the pattern we organize around.

**The Ruby side is a pure pairing layer** — 281 lines total, and its entire job is to render one custom element tag with the right data attributes:

```ruby
# [LEXXY — MIT, © 37signals LLC]  lib/lexxy/rich_text_area_tag.rb (abridged)
def lexxy_rich_textarea_tag(name, value = nil, options = {}, &block)
  options[:name]  ||= name
  options[:value] ||= value
  options[:class] ||= "lexxy-content"
  options[:data]  ||= {}
  options[:data][:direct_upload_url]  ||= main_app.rails_direct_uploads_url
  options[:data][:blob_url_template]  ||= main_app.rails_service_blob_url(":signed_id", ":filename")

  content_tag("lexxy-editor", "", options, &block)
end
```

…plus `lib/lexxy/form_helper.rb` and `lib/lexxy/form_builder.rb`, which are 9 lines each and exist only to expose `f.lexxy_rich_textarea` on the form builder.

**The API surface is 18 custom DOM events**, namespaced `lexxy:*` (`lexxy:change`, `lexxy:initialize`, `lexxy:upload-start/progress/end`, `lexxy:file-accept`, `lexxy:focus`, `lexxy:blur`, `lexxy:insert-link`, `lexxy:insert-markdown`, …). Consumers wire to them from a Stimulus `data-action` — which is exactly how Writebook's autosave listens to its markdown editor: `house-md:change->autosave#change`.

**The lesson for crosswire:** there is a size/complexity threshold above which 37signals stops using Stimulus. Below it: Stimulus controller + ERB helper. Above it: custom element + namespaced custom events + a thin ERB tag helper. The *pairing* survives the transition; the *Stimulus* does not. Our repo should say so.

`STYLE.md` is also worth reading in full as a source of house-style rules (expanded conditionals over guard clauses, no ternaries, private fields declared at class top with `#`, methods ordered by invocation order, fail-fast over defensive `?.`).

---

### 5. Tier-2 ecosystem survey

Nine ecosystem repos were verified. **Three are not Hotwire at all** and were dropped immediately:

| Repo | Verdict |
|---|---|
| `lobsters/lobsters` | ❌ **Not Hotwire.** No `turbo-rails`/`stimulus-rails`/`@hotwired/*`, no `package.json`. Sprockets + jQuery |
| `postalserver/postal` | ❌ **Not Hotwire.** `gem "turbolinks", "~> 5"` — the *pre*-Hotwire predecessor. jQuery/Sprockets |
| `decidim/decidim` | ❌ **Not Hotwire.** React (`@decidim/core`) + jQuery/Foundation. Zero Stimulus controllers |

The rest:

#### `AlchemyCMS/alchemy_cms` — Turbo, but deliberately **no Stimulus**

Ships `turbo-rails` and pins `@hotwired/turbo-rails`, but has **no `stimulus-rails` gem, no `@hotwired/stimulus`, and zero Stimulus controllers.** Its entire admin UI is built on **native Web Components** (`@ungap/custom-elements` polyfill plus `alchemy_admin/components/*`: `page_select`, `attachment_select`, `tags_autocomplete`, …). Heavy ViewComponent use on the Ruby side (49 files reference `ViewComponent::Base`).

**This independently corroborates the Lexxy finding.** Two unrelated teams — 37signals building an editor, Alchemy building a CMS admin — both concluded that a rich component layer wants custom elements rather than Stimulus, while keeping Turbo. That is now a pattern, not an anecdote.

#### `solidusio/solidus` (admin engine) — the cleanest pairing helper found anywhere

Hotwire lives in the engines, not the root: `admin/solidus_admin.gemspec` and `promotions/solidus_promotions.gemspec` depend on `stimulus-rails ~> 1.2` and `turbo-rails`.

Only **6 controllers, 122 lines total**, and **all 6 are generic primitives**: `sortable` (40), `confirm` (21), `alert_animation` (20), `readonly_when_submitting` (17), `details_click_outside` (12), `custom_validity` (12). Zero domain logic in JS for an entire e-commerce admin.

And `admin/app/helpers/solidus_admin/stimulus_helper.rb` — the most elegant expression of the pairing pattern found in the whole research, included into every ViewComponent via `BaseComponent`:

```ruby
# solidusio/solidus — BSD-3-Clause
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

`stimulus_id` is auto-derived per ViewComponent, so a component never names its own controller. The helper's own comment says it exists to avoid "clumsy interpolations". Where 37signals writes one bespoke helper *per controller*, Solidus writes one *generic* helper that works for every controller — a genuinely different and arguably better factoring, and one crosswire should consider offering alongside the 37signals style.

`solidus_promotions` adds 3 more (2 domain-specific: `product_option_values`, `calculator_tiers`).

#### `avo-hq/avo` — the largest Stimulus codebase surveyed, and the least generic

**71 controllers, 6,159 lines** — `turbo-rails >= 2.0`, `@hotwired/stimulus ^3.2.2`, `@hotwired/turbo-rails ^8.0.23`. ViewComponent throughout (~150 components).

Split: **~28 generic / ~43 one-off (39% generic)** — by far the lowest ratio measured. The one-offs are overwhelmingly `fields/*` controllers, one per Avo field type (`key_value`, `date_field`, `trix_field`, `tiptap_field`, …). That is defensible for a *framework* whose product literally is a catalogue of field types, but it is the opposite of the primitive style. Largest files: `appearance` (352), `sidebar_resize` (347), `index_row_navigator` (268).

Avo's pairing helper generates controller strings from **view context** rather than per-component:

```ruby
# avo-hq/avo — lib/avo/concerns/has_resource_stimulus_controllers.rb (abridged)
def get_stimulus_controllers
  controllers = []
  case @view.to_sym
  when :show       then controllers << "resource-show"
  when :new, :edit then controllers << "resource-edit"
  when :index      then controllers << "resource-index record-selector"
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
```

Note it auto-derives a `-view-value` for every controller in the stack, and produces stacked controllers (`"resource-index record-selector"`) as a matter of course.

**Avo also confirms the Writebook custom-stream-action idiom is not unique** — it does the same `Turbo::Streams::TagBuilder.prepend(Avo::TurboStreamActionsHelper)` monkeypatch in `lib/avo.rb`, defining `avo_download`, `avo_flash_alerts`, `avo_close_modal`, `avo_turbo_reload`, `avo_update_belongs_to`, with matching JS in `app/javascript/js/custom-stream-actions.js`. It additionally depends on the `turbo_power` gem for a broader stream-action library.

#### `thoughtbot/administrate` — 3 controllers, all generic

`select` (37, selectize wrapper), `tooltip` (24, wraps the **native Popover API** — `showPopover()`/`hidePopover()`, zero dependencies), `table` (23, click-row-to-navigate). Plain ERB partials, no custom stream actions. The pairing appears as **Field objects rather than helpers**: `lib/administrate/field/select.rb` and `belongs_to.rb` implement `html_options` returning `data: { controller: html_controller }`. Functionally identical job — a Ruby object deciding which Stimulus controller renders — through a different seam.

#### `rails/mission_control-jobs` — the minimalism benchmark

An entire job-monitoring dashboard on **one 21-line Stimulus controller** (`form_controller.js`, debounced auto-submit) plus Turbo. Worth citing whenever someone claims a data-dense admin UI needs a JS framework.

#### `hotwired/turbo-rails` `test/dummy`

**Zero Stimulus controllers and no `stimulus-rails` dependency** — a deliberately Turbo-only app for testing turbo-rails in isolation. Not a source of Stimulus idioms.

---

## Controller census

Counts exclude `application.js` and `index.js`. "Generic" = the controller contains no reference to the host app's domain nouns and could be dropped into an unrelated app; "one-off" = it names or assumes app-specific concepts.

| Codebase | # controllers | # generic | # one-off | % generic | Notable |
|---|---:|---:|---:|---:|---|
| **basecamp/fizzy** | 69 | 53 | 16 | **77%** | 8 in a `bridge/` namespace for Hotwire Native; `dispatch_event`, `morph_guard`, `related_element` are pure glue primitives |
| **basecamp/once-campfire** | 35 | 22 | 13 | **63%** | 59% of app JS lives *outside* controllers, in `models/`+`lib/` |
| **basecamp/writebook** | 22 | 17 | 5 | **77%** | `arrangement` is 403 lines (42% of total) yet fully domain-free |
| **basecamp/lexxy** (`src/`) | **0** | — | — | n/a | 12,316 lines of Web Components + OO classes. No Stimulus at all |
| *lexxy `test/dummy/`* | 6 | 0 | 6 | 0% | demo glue only, not library code |
| **37signals subtotal** | **126** | **92** | **34** | **73%** | |
| | | | | | |
| **avo-hq/avo** | 71 | 28 | 43 | **39%** | Lowest ratio measured; 43 one-offs are mostly `fields/*`, one per field type |
| **solidusio/solidus** (admin) | 6 | 6 | 0 | **100%** | A whole e-commerce admin, 122 lines of JS, zero domain logic |
| **solidusio/solidus** (promotions) | 3 | 1 | 2 | 33% | `calculator_tiers`, `product_option_values` are domain |
| **thoughtbot/administrate** | 3 | 3 | 0 | **100%** | `tooltip` wraps the native Popover API — no library |
| **rails/mission_control-jobs** | 1 | 1 | 0 | 100% | A whole dashboard on 21 lines of JS |
| **AlchemyCMS/alchemy_cms** | **0** | — | — | n/a | Turbo, but **deliberately no Stimulus** — native Web Components |
| **hotwired/turbo-rails** `test/dummy` | 0 | — | — | n/a | No stimulus-rails dependency; Turbo-only by design |
| **Ecosystem subtotal** | **84** | **39** | **45** | **46%** | Skewed almost entirely by Avo's 43 field controllers |
| | | | | | |
| **TOTAL (excl. non-Hotwire)** | **210** | **131** | **79** | **62%** | |

Not Hotwire, excluded: `lobsters/lobsters` (jQuery/Sprockets), `postalserver/postal` (Turbolinks 5), `decidim/decidim` (React).

Cross-app duplication (evidence of an unmaintained shared library):

| Primitive | Campfire | Writebook | Fizzy |
|---|:-:|:-:|:-:|
| `auto_submit` | ✅ | ✅ *(identical)* | ✅ |
| `copy_to_clipboard` | ✅ | ✅ *(identical)* | ✅ |
| `form` | ✅ | ✅ *(identical)* | ✅ |
| `web_share` | ✅ | ✅ *(2-line diff)* | — |
| `lightbox` | ✅ | ✅ | ✅ |
| `upload_preview` | ✅ | ✅ | ✅ |
| `toggle_class` | ✅ | — | ✅ |
| `element_removal` | ✅ | ✅ *(as `autoremove`)* | ✅ |
| `soft_keyboard` | ✅ | — | ✅ |
| `hotkey` | — | ✅ | ✅ |
| `filter` | ✅ | — | ✅ |
| `local_time` | ✅ | — | ✅ |
| `dialog` / `popover` / `popup` | ✅ | ✅ | ✅ |
| `touch` (swipe) | — | ✅ | ✅ *(`touch_placeholder`)* |
| `FormsHelper#auto_submit_form_with` (Ruby) | ✅ | ✅ *(identical)* | ✅ |
| `helpers/timing_helpers.js` | ✅ | ✅ | ✅ |

**Fourteen primitives copy-pasted across three apps, three of them byte-identical.** 37signals has a de facto standard library and no distribution mechanism for it.

---

## Generic controllers found in the wild

Deduplicated. **MIT-licensed entries (Campfire/Writebook/Lexxy) may be adapted into crosswire with a copyright notice. Fizzy entries are marked and must be re-implemented, not vendored.**

### `auto_submit` — MIT (Campfire + Writebook, identical)

The whole thing. Submits its form on connect; combined with Turbo Streams this is a complete "live filter" mechanism.

```js
// © 37signals LLC — MIT. Campfire & Writebook, byte-identical.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.requestSubmit()
  }
}
```

Paired Ruby helper (also identical across all three apps):

```ruby
# © 37signals LLC — MIT
module FormsHelper
  def auto_submit_form_with(**attributes, &)
    data = attributes.delete(:data) || {}
    data[:controller] = "auto-submit #{data[:controller]}".strip

    form_with **attributes, data: data, &
  end
end
```

Note `"auto-submit #{data[:controller]}".strip` — the helper *prepends* itself to any controller list the caller passed, so it composes instead of clobbering. This one line is the whole composability trick.

### `copy_to_clipboard` — MIT (Campfire + Writebook, identical)

```js
// © 37signals LLC — MIT
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { content: String }
  static classes = [ "success" ]

  async copy(event) {
    event.preventDefault()
    this.reset()

    try {
      await navigator.clipboard.writeText(this.contentValue)
      this.element.classList.add(this.successClass)
    } catch {}
  }

  reset() {
    this.element.classList.remove(this.successClass)
    this.#forceReflow()
  }

  #forceReflow() {
    this.element.offsetWidth
  }
}
```

`#forceReflow()` — reading `offsetWidth` purely for its side effect — is the trick that lets the CSS success animation replay on a second click. Nothing in a tutorial teaches this.

Paired helper (`app/helpers/clipboard_helper.rb`, Campfire — Fizzy's adds `tooltip` to the controller list):

```ruby
# © 37signals LLC — MIT
module ClipboardHelper
  def button_to_copy_to_clipboard(url, &)
    tag.button class: "btn", data: {
      controller: "copy-to-clipboard", action: "copy-to-clipboard#copy",
      copy_to_clipboard_success_class: "btn--success", copy_to_clipboard_content_value: url
    }, &
  end
end
```

### `form` — MIT (Campfire + Writebook, identical)

Three methods, used everywhere. The generic "make this form controllable from elsewhere" primitive.

```js
// © 37signals LLC — MIT
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "cancel" ]

  submit() {
    this.element.requestSubmit()
  }

  cancel() {
    this.cancelTarget?.click()
  }

  preventAttachment(event) {
    event.preventDefault()
  }
}
```

### `element_removal` — MIT (Campfire)

Two lines, and it is how Campfire's flash messages disappear — `animationend->element-removal#remove`. CSS owns the animation; JS owns only the removal.

```js
// © 37signals LLC — MIT
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  remove() {
    this.element.remove()
  }
}
```

### `toggle_class` — MIT (Campfire)

Nine lines, and it is the entire sidebar open/close mechanism in Campfire's layout.

```js
// © 37signals LLC — MIT
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static classes = [ "toggle" ]

  toggle() {
    this.element.classList.toggle(this.toggleClass)
  }
}
```

Used as: `<aside id="sidebar" data-controller="toggle-class" data-toggle-class-toggle-class="open">`.

### `hotkey` — MIT (Writebook)

Turns any element into a keyboard-activatable one *without* the controller knowing what the element does — it just clicks it. Composition by delegation to the DOM.

```js
// © 37signals LLC — MIT (Writebook)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  click(event) {
    if (this.#isClickable && !this.#shouldIgnore(event)) {
      this.element.click()
    }
  }

  #shouldIgnore(event) {
    return event.defaultPrevented || event.target.closest("input, textarea")
  }

  get #isClickable() {
    return getComputedStyle(this.element).pointerEvents !== "none"
  }
}
```

The `getComputedStyle(...).pointerEvents !== "none"` check is the clever bit: a hotkey automatically stops working when CSS has visually disabled its target. **CSS becomes the source of truth for whether a keyboard shortcut is live.** Fizzy's version adds a `focus()` action and extends the ignore selector to `lexxy-editor`.

### `drop_target` — MIT (Campfire)

The canonical `this.dispatch` primitive: it knows nothing about uploads, it just normalizes HTML5 drag events into one custom event.

```js
// © 37signals LLC — MIT
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dragenter(event) {
    event.preventDefault()
  }

  dragover(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "copy"
  }

  drop(event) {
    event.preventDefault()
    this.dispatch("drop", { detail: { files: event.dataTransfer.files }})
  }
}
```

Its paired helper is a bare action string — the minimal form of the pairing pattern:

```ruby
# © 37signals LLC — MIT
module DropTargetHelper
  def drop_target_actions
    "dragenter->drop-target#dragenter dragover->drop-target#dragover drop->drop-target#drop"
  end
end
```

…consumed in `RoomsHelper#composer_data_actions` as `drop-target:drop@window->composer#dropFiles`. The producer and consumer are two independent controllers on two different elements, coupled only by an event name.

### `local_time` — MIT (Campfire)

Server renders UTC in `<time datetime>`; client rewrites to the viewer's locale. Notice it uses **three target callbacks as a dispatch table** rather than a `switch`.

```js
// © 37signals LLC — MIT
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "time", "date", "datetime" ]

  initialize() {
    this.timeFormatter = new Intl.DateTimeFormat(undefined, { timeStyle: "short" })
    this.dateFormatter = new Intl.DateTimeFormat(undefined, { dateStyle: "long" })
    this.dateTimeFormatter = new Intl.DateTimeFormat(undefined, { timeStyle: "short", dateStyle: "short" })
  }

  timeTargetConnected(target)     { this.#formatTime(this.timeFormatter, target) }
  dateTargetConnected(target)     { this.#formatTime(this.dateFormatter, target) }
  datetimeTargetConnected(target) { this.#formatTime(this.dateTimeFormatter, target) }

  #formatTime(formatter, target) {
    const dt = new Date(target.getAttribute("datetime"))
    target.textContent = formatter.format(dt)
    target.title = this.dateTimeFormatter.format(dt)
  }
}
```

Paired helper — and note the helper's whole job is to pick which target name to use:

```ruby
# © 37signals LLC — MIT
module TimeHelper
  def local_datetime_tag(datetime, style: :time, **attributes)
    tag.time **attributes, datetime: datetime.iso8601, data: { local_time_target: style }
  end
end
```

Because this is target-callback driven, it works automatically on Turbo Stream-appended content with no re-initialization. That is the reason to prefer `xTargetConnected` over `connect()` + `querySelectorAll`.

### `web_share` — MIT (Campfire / Writebook, 2-line diff)

Progressive enhancement done right: hides itself when unsupported, in `connect()`.

```js
// © 37signals LLC — MIT
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { title: String, text: String, url: String, files: String }

  connect() {
    this.element.hidden = !navigator.canShare
  }

  async share() {
    await navigator.share(await this.#getShareData())
  }

  async #getShareData() {
    const data = { title: this.titleValue, text: this.textValue }
    if (this.urlValue)   data.url = this.urlValue
    if (this.filesValue) data.files = [ await this.#getFileObject() ]
    return data
  }

  async #getFileObject() {
    const response = await fetch(this.filesValue)
    const blob = await response.blob()
    const randomPrefix = `Campfire_${Math.random().toString(36).slice(2)}`
    const fileName = `${randomPrefix}.${blob.type.split('/').pop()}`
    return new File([ blob ], fileName, { type: blob.type })
  }
}
```

### `sound` — MIT (Campfire)

Ten lines. Interesting because it is triggered by *another controller's dispatch*, not a DOM event: `data-action="messages:play->sound#play"`.

```js
// © 37signals LLC — MIT
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { "url": String }

  play() {
    const sound = new Audio(this.urlValue)
    sound.play()
  }
}
```

### `dialog` — MIT (Writebook)

Thirteen lines wrapping the native `<dialog>` element. No modal library, no focus-trap dependency.

```js
// © 37signals LLC — MIT (Writebook)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dialog" ]

  open()  { this.dialogTarget.showModal() }
  close() { this.dialogTarget.close() }
}
```

### `autosave` — MIT (Writebook)

The best "small controller, real feature" example found. Debounce-free (it uses the timer's own existence as the dirty flag) and it flushes on `disconnect()` so navigating away never loses work.

```js
// © 37signals LLC — MIT (Writebook)
import { Controller } from "@hotwired/stimulus"
import { submitForm } from "helpers/form_helpers"

const AUTOSAVE_INTERVAL = 3000

export default class extends Controller {
  static classes = [ "clean", "dirty", "saving" ]

  #timer

  disconnect() {
    this.submit()
  }

  async submit() {
    if (this.#dirty) {
      await this.#save()
    }
  }

  change(event) {
    if (event.target.form === this.element && !this.#dirty) {
      this.#scheduleSave()
      this.#updateAppearance()
    }
  }

  async #save() {
    this.#updateAppearance(true)
    this.#resetTimer()
    await submitForm(this.element)
    this.#updateAppearance()
  }

  #updateAppearance(saving = false) {
    this.element.classList.toggle(this.cleanClass,  !this.#dirty)
    this.element.classList.toggle(this.dirtyClass,   this.#dirty)
    this.element.classList.toggle(this.savingClass,  saving)
  }

  #scheduleSave() { this.#timer = setTimeout(() => this.#save(), AUTOSAVE_INTERVAL) }
  #resetTimer()   { clearTimeout(this.#timer); this.#timer = null }

  get #dirty() { return !!this.#timer }
}
```

`get #dirty() { return !!this.#timer }` — the pending-timer *is* the dirty state. One field, no bookkeeping. And the three-class `clean`/`dirty`/`saving` CSS Classes API means the entire save indicator UI is CSS.

### `popover` — MIT (Writebook) / `popup` — MIT (Campfire)

Self-orienting menu that flips up near the viewport bottom and publishes its own max-width as a CSS custom property. Notable for **JS measuring, CSS rendering** — the controller never sets `left`/`top`.

```js
// © 37signals LLC — MIT (Writebook)
import { Controller } from "@hotwired/stimulus"

const BOTTOM_THRESHOLD = 0

export default class extends Controller {
  static targets = [ "menu" ]
  static classes = [ "orientationTop" ]

  close()  { this.menuTarget.close(); this.#orient() }
  open()   { this.menuTarget.show();  this.#orient() }
  toggle() { this.menuTarget.open ? this.close() : this.open() }

  closeOnClickOutside({ target }) {
    if (!this.element.contains(target)) this.close()
  }

  #orient() {
    this.element.classList.toggle(this.orientationTopClass, this.#distanceToBottom < BOTTOM_THRESHOLD)
    this.menuTarget.style.setProperty("--max-width", this.#maxWidth + "px")
  }

  get #distanceToBottom() { return window.innerHeight - this.#boundingClientRect.bottom }
  get #maxWidth()         { return window.innerWidth - this.#boundingClientRect.left }
  get #boundingClientRect() { return this.menuTarget.getBoundingClientRect() }
}
```

### `dependent_checkbox` — MIT (Writebook)

Fifteen lines that solve the "child implies parent" checkbox problem generically, with two targets and no config.

```js
// © 37signals LLC — MIT (Writebook)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dependant", "dependee" ]

  input({target}) {
    if (target === this.dependantTarget && target.checked) {
      this.dependeeTarget.checked = true
    }

    if (target === this.dependeeTarget && !target.checked) {
      this.dependantTarget.checked = false
    }
  }
}
```

### `touch` — MIT (Writebook)

Swipe detection that emits nothing but two custom events. Note `#isSelection` — it refuses to fire a swipe if the user was selecting text, the kind of correctness detail tutorials omit.

```js
// © 37signals LLC — MIT (Writebook). Abridged: see repo for full body.
const SWIPE_DURATION = 1000
const SWIPE_THRESHOLD = 30

// ...
#swipedLeft()  { this.dispatch("swipe-left") }
#swipedRight() { this.dispatch("swipe-right") }

get #isSelection() {
  const selection = window.getSelection()
  return selection.toString().length > 0 && !selection.isCollapsed
}
```

### `maintain_scroll` — MIT (Campfire)

The most sophisticated *small* controller found — it intercepts Turbo's stream render to preserve scroll position, by **replacing `event.detail.render` with a wrapped version**. 32 lines.

```js
// © 37signals LLC — MIT
import { Controller } from "@hotwired/stimulus"
import ScrollManager from "models/scroll_manager"

export default class extends Controller {
  #scrollManager

  connect() {
    this.#scrollManager = new ScrollManager(this.element)
  }

  beforeStreamRender(event) {
    const shouldKeepScroll = event.detail.newStream.hasAttribute("maintain_scroll")
    const render = event.detail.render
    const target = event.detail.newStream.getAttribute("target")
    const targetElement = document.getElementById(target)

    if (this.element.contains(targetElement) && shouldKeepScroll) {
      const top = this.#isAboveFold(targetElement)
      event.detail.render = async (streamElement) => {
        this.#scrollManager.keepScroll(top, () => render(streamElement))
      }
    }
  }

  #isAboveFold(element) {
    return element.getBoundingClientRect().top < this.element.clientHeight
  }
}
```

The server opts a specific broadcast into this behavior with a custom attribute on the stream element:

```ruby
# app/controllers/messages_controller.rb — © 37signals LLC, MIT
@message.broadcast_replace_to @room, :messages,
  target: [ @message, :presentation ],
  partial: "messages/presentation",
  attributes: { maintain_scroll: true }
```

**`attributes:` on a broadcast helper is an almost-undocumented turbo-rails feature.** It lets the server annotate a `<turbo-stream>` element with arbitrary attributes that client code can branch on. This is the clean way to do "this update should behave differently" without inventing a custom stream action.

### From Fizzy — study only, do not vendor

**`dispatch_event`** `[FIZZY — O'Saasy]` — nine lines; the universal "turn any DOM event into a named document-level event" adapter. `prefix: false` means the event name is exactly `nameValue`, not `dispatch-event:foo`.

```js
// [FIZZY — O'Saasy License. Re-implement, do not copy.]
export default class extends Controller {
  static values = { name: String }

  fire() {
    this.dispatch(this.nameValue, { target: document, prefix: false })
  }
}
```

**`morph_guard`** `[FIZZY — O'Saasy]` — 16 lines that solve a real Turbo 8 morphing problem, with an excellent comment explaining *why* the attribute isn't just in the markup:

```js
// [FIZZY — O'Saasy License]
// Marks the enclosing turbo-frame permanent while connected, so that a
// broadcasted page refresh can't morph away an edit in progress. The attribute
// is never in the server-rendered markup, so display mode stays morphable and
// page replacements never transplant the frame.
export default class extends Controller {
  connect() {
    this.frame = this.element.closest("turbo-frame")
    this.frame?.setAttribute("data-turbo-permanent", "")
  }

  disconnect() {
    this.frame?.removeAttribute("data-turbo-permanent")
  }
}
```

**Also worth studying in Fizzy:** `related_element` (cross-highlighting by shared group value), `fetch_on_visible` (IntersectionObserver → `get(url, {responseKind: "turbo-stream"})`, i.e. lazy-load without a frame), `frame_reloader` (staleness-gated `element.reload()`), `outlet_auto_save` (a controller whose *entire body* is outlet forwarding), `clicker`, `auto_click`, `beacon`, `css_variable_counter` (writes `element.style.setProperty(name, count)` so CSS can react to list length), `toggle_enable`, `retarget_links`, `details`, `dialog_manager` (an "only one open at a time" coordinator that queries `[data-controller~="dialog"]`).

---

## Composition techniques observed

### 1. Cross-controller events via `this.dispatch` + `@window` action routing

The dominant composition mechanism. A producer controller dispatches; consumers subscribe from ERB using Stimulus's global-event syntax.

Producer — `drop_target_controller.js` (Campfire): `this.dispatch("drop", { detail: { files } })`
Consumer — `RoomsHelper#composer_data_actions`: `drop-target:drop@window->composer#dropFiles`

Campfire's full event bus, all discovered by grepping `dispatch(`:

| Event | Producer | Consumer |
|---|---|---|
| `drop-target:drop@window` | `drop_target` | `composer#dropFiles` |
| `refresh-room:online@window` | `refresh_room` | `composer#online` |
| `refresh-room:offline@window` | `refresh_room` | `composer#offline` |
| `read-rooms:read` | `read_rooms` | `rooms-list#read` |
| `rooms-list:read` / `:unread` | `rooms_list` | `sorted-list#updateItem`, `badge-dot#update` |
| `messages:play` | `messages` (targeted at a specific node) | `sound#play` |
| `presence:present` | `presence` | (room presence) |

Note `this.dispatch("play", { target: soundTarget })` in `messages_controller.js` — dispatching **at a specific element** rather than the controller's own, so only that one sound plays. That is `dispatch`'s `target` option doing real work.

### 2. Stacked controllers on one element

Used, but sparingly and always from a helper. Real examples:

- `data-controller="composer drop-target"` (Campfire, `RoomsHelper#composer_data_options`)
- `data-controller="messages presence drop-target"` (Campfire, `MessagesHelper#message_area_tag`)
- `data-controller="maintain-scroll refresh-room"` (Campfire, `MessagesHelper#messages_tag`)
- `data-controller="local-time lightbox"` (Campfire, `<body>`)
- `data-controller="arrangement reading-progress"` (Writebook, `ArrangementHelper#arrangement_tag`)
- `data-controller="navigable-list css-variable-counter"` (Fizzy, `ColumnsHelper#column_tag`)
- `data-controller="copy-to-clipboard tooltip"` (Fizzy, `ClipboardHelper`)

The pattern is always *one behavioral controller + one or more orthogonal cross-cutting ones* (scroll, presence, drop, tooltip, counter). Never two controllers competing for the same concern.

### 3. Outlets — used, but rarely, and only for imperative cross-component calls

Only **four outlet declarations** across 126 controllers:

| Controller | Outlet | Purpose | File |
|---|---|---|---|
| `composer` | `messages` | `this.messagesOutlet.insertPendingMessage(...)` | `once-campfire/app/javascript/controllers/composer_controller.js:10` |
| `reply` | `composer` | `this.composerOutlet.replaceMessageContent(content)` | `once-campfire/app/javascript/controllers/reply_controller.js:6` |
| `edit_mode` | `autosave` | `for (const a of this.autosaveOutlets) await a.submit()` | `writebook/app/javascript/controllers/edit_mode_controller.js:7` |
| `outlet_auto_save` | `auto-save` | pure forwarding | `fizzy/app/javascript/controllers/outlet_auto_save_controller.js:4` |

The rule they follow: **events for notification (fan-out, fire-and-forget); outlets only when you need a return value or must `await` the other controller.** `edit_mode` is the clearest case — it must await every autosave form flushing before it navigates. An event could not express that.

Outlet *selectors* are set from helpers, not templates: `composer_messages_outlet: "#message-area"` (`rooms_helper.rb:68`), `reply_composer_outlet: "#composer"` (`messages_helper.rb:40`).

### 4. CSS Classes API — heavily used, and it is what keeps controllers generic

This is the technique that most directly enables the primitive style. `static classes` means a controller can toggle appearance without knowing any class names.

`MessagesHelper#message_area_tag` (Campfire) passes five at once:
```ruby
messages_first_of_day_class: "message--first-of-day",
messages_formatted_class:    "message--formatted",
messages_me_class:           "message--me",
messages_mentioned_class:    "message--mentioned",
messages_threaded_class:     "message--threaded"
```

…and `messages_controller.js` then hands them straight to a plain object: `new MessageFormatter(Current.user.id, { firstOfDay: this.firstOfDayClass, ... })`. **The CSS class names travel from ERB → Stimulus → plain JS class**, so the formatting logic is testable and app-agnostic.

Counts of `static classes` usage: Campfire 10 controllers, Writebook 6, Fizzy ~15.

### 5. Values-as-API

Consistently used for anything the server knows: URLs (`refresh_room_url_value`, `arrangement_url_value`, `messages_page_url_value`), IDs (`composer_room_id_value`, `reading_tracker_book_id_value`), and timestamps (`refresh_room_loaded_at_value`). Typed defaults appear in Fizzy: `reloadInterval: { type: Number, default: 10 * 60 }`.

**No controller in any of the four apps constructs a URL from a string template.** Every URL comes from a Rails route helper through a value. This is a hard rule worth stating in crosswire.

### 6. JS writes CSS custom properties; CSS does the rendering

A recurring division of labor:

- `popup_controller`: `this.menuTarget.style.setProperty("--max-width", this.#maxWidth + "px")`
- `knob_controller` (Fizzy): `this.fieldTarget.style.setProperty("--knob-index", index)`
- `css_variable_counter_controller` (Fizzy): `this.counterTarget.style.setProperty(this.propertyNameValue, count)`
- `composer_controller`: `style="--percentage: ${percent}%"` for upload progress
- `cards_helper.rb` (Fizzy): `style: "--card-color: #{card.color}"`

The controller computes one number; the stylesheet owns every visual consequence.

---

## The helper↔controller pairing (our differentiator)

**Finding: `hotwire_combobox` is not the only one doing this. It is 37signals' default way of writing Hotwire, it has been independently reinvented by at least three ecosystem projects, and it is documented nowhere.**

Five independent implementations of "Ruby decides the Stimulus wiring" were found:

| Project | Mechanism | Shape |
|---|---|---|
| 37signals (Campfire/Writebook/Fizzy) | one bespoke helper **per controller** | `button_to_copy_to_clipboard`, `message_area_tag`, `column_frame_tag` |
| `solidusio/solidus` admin | one **generic** helper module keyed on `stimulus_id` | `stimulus_controller`, `stimulus_action(on:)`, `stimulus_target`, `stimulus_value` |
| `avo-hq/avo` | a **concern** deriving the controller list from view context | `get_stimulus_controllers`, `stimulus_data_attributes` |
| `thoughtbot/administrate` | **Field objects** returning `html_options` | `Field::Select#html_options → data: { controller: "select" }` |
| `josefarias/hotwire_combobox` | a **gem** with a form-builder method | `f.combobox` |

Nobody has named this pattern. Five teams arrived at it separately because it is what makes generic controllers usable. The 37signals and Solidus variants are the two worth teaching: **one helper per controller** (maximum ergonomics, more code) versus **one generic helper for all controllers** (minimum code, callers still name the controller). They compose — a project can use the generic helper as the substrate and add bespoke helpers for its most-used primitives.

Across Campfire, Writebook, and Fizzy there are **20+ ERB helper methods whose sole purpose is to emit the wiring for a specific Stimulus controller.** The evidence is strongest in Campfire: its main chat screen (`app/views/rooms/show.html.erb`) contains zero `data-controller` attributes because all four are supplied by helpers.

### The taxonomy of pairings observed

**(a) Full element helper** — helper renders the tag and all wiring.

```ruby
# once-campfire/app/helpers/messages_helper.rb — © 37signals LLC, MIT
def message_area_tag(room, &)
  tag.div id: "message-area", class: "message-area", contents: true, data: {
    controller: "messages presence drop-target",
    action: [ messages_actions, drop_target_actions, presence_actions ].join(" "),
    messages_first_of_day_class: "message--first-of-day",
    messages_formatted_class: "message--formatted",
    messages_me_class: "message--me",
    messages_mentioned_class: "message--mentioned",
    messages_threaded_class: "message--threaded",
    messages_page_url_value: room_messages_url(room)
  }, &
end
```

Others: `messages_tag`, `message_tag`, `button_to_jump_to_newest_message`, `button_to_copy_to_clipboard`, `link_to_zoom_qr_code`, `local_datetime_tag` (Campfire); `arrangement_tag`, `leaf_item_tag`, `leaf_nav_tag`, `leafable_edit_form` (Writebook); `column_tag`, `column_frame_tag`, `pagination_list`, `pagination_link`, `bridged_share_url_button`, `back_link_to` (Fizzy).

**(b) Form-builder wrapper** — decorates an existing Rails form helper, composing rather than replacing.

```ruby
# Identical in Campfire, Writebook, and Fizzy — © 37signals LLC, MIT
def auto_submit_form_with(**attributes, &)
  data = attributes.delete(:data) || {}
  data[:controller] = "auto-submit #{data[:controller]}".strip
  form_with **attributes, data: data, &
end
```

Fizzy's `bridged_form_with` extends the idea to actions as well:
```ruby
# [FIZZY — O'Saasy License]
controllers = [ data[:controller], "bridge--form" ].compact.join(" ").strip
actions = [ data[:action],
  "turbo:submit-start->bridge--form#submitStart",
  "turbo:submit-end->bridge--form#submitEnd" ].compact.join(" ").strip
```

**(c) Bare action-string helper** — the minimal unit; returns a `data-action` fragment for composition.

```ruby
# once-campfire/app/helpers/drop_target_helper.rb — © 37signals LLC, MIT
def drop_target_actions
  "dragenter->drop-target#dragenter dragover->drop-target#dragover drop->drop-target#drop"
end
```

Campfire has five of these (`drop_target_actions`, `messages_actions`, `maintain_scroll_actions`, `refresh_room_actions`, `presence_actions`, `rich_text_data_actions`) and composes them with `[...].join(" ")`. Fizzy composes them with `token_list(...)` instead, which additionally handles `nil`s and dedupes.

**(d) Frame/stream helper** — pairs with Turbo rather than Stimulus.
`column_frame_tag`, `pagination_frame_tag`, `day_timeline_pagination_frame_tag` (Fizzy); `sidebar_turbo_frame_tag` (Campfire).

**(e) Custom-element tag helper** — the post-Stimulus form of the pairing. Lexxy's `lexxy_rich_textarea_tag` / `f.lexxy_rich_textarea`.

**(f) Custom stream action + TagBuilder method** — Writebook's `turbo_stream.scroll_into_view`.

### Naming conventions actually used

- `<thing>_tag` — renders an element with wiring (`message_area_tag`, `column_tag`, `arrangement_tag`, `local_datetime_tag`)
- `<thing>_actions` — returns a `data-action` string fragment (`drop_target_actions`, `presence_actions`)
- `button_to_<verb>` / `link_to_<verb>` — a wired control (`button_to_copy_to_clipboard`, `link_to_zoom_qr_code`, `button_to_jump_to_newest_message`)
- `<adjective>_form_with` — decorated form builder (`auto_submit_form_with`, `bridged_form_with`)
- `<thing>_frame_tag` — wired Turbo frame (`column_frame_tag`, `pagination_frame_tag`)
- Helper file name matches controller file name: `drop_target_helper.rb` ↔ `drop_target_controller.js`, `clipboard_helper.rb` ↔ `copy_to_clipboard_controller.js`, `arrangement_helper.rb` ↔ `arrangement_controller.js`.

**This is the design language crosswire should formalize.** Nobody has written it down.

---

## Turbo usage patterns

### Broadcasts are called from controllers, not model callbacks

This is a direct contradiction of every Hotwire tutorial, which teaches `after_create_commit -> { broadcast_append_to ... }` in the model.

Campfire defines broadcast *methods* on the model in a concern but **never registers a callback**:

```ruby
# once-campfire/app/models/message/broadcasts.rb — © 37signals LLC, MIT
module Message::Broadcasts
  def broadcast_create
    broadcast_append_to room, :messages, target: [ room, :messages ]
    broadcast_unread_room
  end

  def broadcast_remove
    broadcast_remove_to room, :messages
  end

  private
    # Fanned out to the room's members rather than published on one global stream, so
    # that the timing of activity in a room only reaches people who are in it.
    def broadcast_unread_room
      room.memberships.pluck(:user_id).each do |user_id|
        ActionCable.server.broadcast UnreadRoomsChannel.stream_name_for(user_id), { roomId: room.id }
      end
    end
end
```

…and the *controller* decides when to fire it:

```ruby
# app/controllers/messages_controller.rb
@message.broadcast_create        # create
@message.broadcast_remove        # destroy
```

Some broadcasts live entirely in the controller (`rooms/opens_controller.rb`, `rooms/closeds_controller.rb`, `messages/boosts_controller.rb`). The benefit: no surprise broadcasts from seeds, imports, console work, or `update_column`; the HTTP request that caused the change owns the broadcast. **This is the single most important Turbo idiom the tutorials get wrong.**

### Partial granularity and the `dom_id` convention

The `dom_id(record, prefix)` two-argument form is used as a namespacing device throughout:

- `dom_id(@message.room, :messages)` — the container that messages append into
- `[ @message, :presentation ]` — a sub-region of a message that can be replaced independently of its wrapper
- `[ @room, :list ]` — the room's row in the sidebar, distinct from the room itself
- `dom_id(leaf, :being_edited)` — a presence indicator region (Writebook)
- `dom_id(card, :article)` / `[ @card, :card_container ]` (Fizzy)

Note that broadcast targets accept the array form directly: `broadcast_replace_to @room, :messages, target: [ @message, :presentation ]`. The pattern is: **one record renders as several independently-addressable regions**, each with a prefixed `dom_id`, so a broadcast can update the reaction bar without re-rendering the message body.

### `turbo_stream` templates are rare and short

Campfire has **4** `.turbo_stream.erb` files in the whole app. Two of them are one-liners:

```erb
<%# app/views/messages/create.turbo_stream.erb %>
<%= turbo_stream.append dom_id(@message.room, :messages), @message %>
```
```erb
<%# app/views/messages/destroy.turbo_stream.erb %>
<%= turbo_stream.remove @message %>
```

The multi-action ones do exactly one job — batched pagination:

```erb
<%# app/views/rooms/refreshes/show.turbo_stream.erb %>
<%= turbo_stream.append dom_id(@room, :messages) do %>
  <%= render partial: "messages/message", collection: @new_messages, cached: true %>
<% end if @new_messages.any? %>

<% @updated_messages.each do |message| %>
  <%= turbo_stream.replace dom_id(message), partial: "messages/message", locals: { message: message } %>
<% end %>
```

Fizzy has 38, including a **`.turbo_stream.erb` partial** — `app/views/columns/_refresh_adjacent_columns.turbo_stream.erb` — rendered from multiple stream templates. That is a nice way to DRY up repeated stream fragments.

Also note `render partial: ..., collection: ..., cached: true` inside a stream — collection caching works across the wire.

### Morph vs targeted streams: a clear generational split

| App | turbo-rails | Morphing? |
|---|---|---|
| Writebook | 2.0.11 | **None.** Zero `turbo_refreshes_with` |
| Campfire | 2.0.16 (git) | **None.** Zero `turbo_refreshes_with` |
| Fizzy | current | **Yes — but never page-level refresh** |

Fizzy's usage is exclusively **morph as a rendering method on a targeted operation**:

```erb
<%# app/views/boards/columns/update.turbo_stream.erb — [FIZZY] %>
<%= turbo_stream.replace(dom_id(@column), partial: "boards/show/column", method: :morph, locals: { column: @column }) %>
```
```erb
<%# app/views/boards/columns/create.turbo_stream.erb — [FIZZY] %>
<%= turbo_stream.before("closed-cards", partial: "boards/show/column", method: :morph, locals: { column: @column }) %>
```
```ruby
# app/controllers/concerns/card_scoped.rb — [FIZZY]
render turbo_stream: turbo_stream.replace([ @card, :card_container ],
  partial: "cards/container", method: :morph, locals: { card: @card.reload })
```

…plus frame-level morph refresh: `turbo_frame_tag "notifications", src: ..., refresh: "morph"`, and `column_frame_tag`'s `options[:refresh] = :morph if src.present?`.

**Nobody in these codebases uses `turbo_refreshes_with method: :morph` for whole-page broadcast refreshes.** The blogosphere's "just broadcast a refresh and let morphing sort it out" is not what 37signals ships. They target precisely and use morph only to make *that* replacement non-destructive to focus/scroll/selection.

Supporting evidence: Fizzy needs `morph_guard_controller` and `frame_controller#morphRender`/`#morphReload` and `turbo:before-morph-attribute->collapsible-columns#preventToggle` — i.e., morphing brings its own class of bugs, and they wrote three separate controllers to contain them.

### Frames are for lazy panels, not for everything

18 `turbo_frame_tag` call sites across Campfire + Writebook combined. They are used for: the sidebar (`src:` lazy-loaded), search results, settings dialogs, pagination containers, and edit-in-place regions. The main content stream is Turbo Drive + Streams, not frames.

---

## Idioms the tutorials miss

1. **`ignoringBriefDisconnects`** (`once-campfire/app/javascript/helpers/dom_helpers.js`) — Turbo (and morphing) transiently disconnects and reconnects elements. Naively unsubscribing an ActionCable channel in `disconnect()` causes a subscription thrash on every navigation. Campfire's fix:

   ```js
   // © 37signals LLC — MIT
   export function ignoringBriefDisconnects(element, fn) {
     requestAnimationFrame(() => {
       if (!element.isConnected) fn()
     })
   }
   ```
   Used as `disconnect() { ignoringBriefDisconnects(this.element, () => { this.channel?.unsubscribe(); this.channel = null }) }` in `rooms_list_controller` and `read_rooms_controller`. **One frame of patience eliminates an entire class of Turbo bug.** Nothing teaches this.

2. **`pageIsTurboPreview()` guards** — Turbo Drive renders a cached preview before the fresh response arrives. Controllers that open WebSockets or start timers must not run during it:

   ```js
   // © 37signals LLC — MIT — helpers/turbo_helpers.js
   export function pageIsTurboPreview() {
     return document.documentElement.hasAttribute("data-turbo-preview")
   }
   ```
   Guarded in `refresh_room_controller` and `typing_notifications_controller`: `async connect() { if (!pageIsTurboPreview()) { ... } }`.

3. **`attributes:` on broadcast helpers** — server-side annotation of a `<turbo-stream>` element that client code branches on (`maintain_scroll: true`). Barely documented in turbo-rails. Avoids inventing a custom stream action for a one-off behavior tweak.

4. **Replacing `event.detail.render`** in `turbo:before-stream-render` to wrap the render in scroll preservation, rather than trying to fix scroll after the fact. Both `messages_controller` and `maintain_scroll_controller` do this. Turbo hands you the render function; you may decorate it.

5. **A global promise chain to serialize DOM mutations.** `ScrollManager` (Campfire) uses a *static* field so that every instance shares one queue:
   ```js
   static #pendingOperations = Promise.resolve()

   #appendOperation(operation) {
     ScrollManager.#pendingOperations = ScrollManager.#pendingOperations.then(operation)
     return ScrollManager.#pendingOperations
   }
   ```
   Racing stream renders can't interleave their scroll math.

6. **`static get shouldLoad()`** — Stimulus lets a controller decline to register at all. Campfire's `soft_keyboard_controller`:
   ```js
   static get shouldLoad() { return isTouchDevice() }
   ```
   Almost nobody knows this hook exists.

7. **CSS `pointer-events` as the source of truth for keyboard shortcuts** — `hotkey_controller`'s `getComputedStyle(this.element).pointerEvents !== "none"`. Disable a button in CSS and its hotkey dies automatically.

8. **Target-connected callbacks instead of `connect()` + query.** `timeTargetConnected`, `messageTargetConnected`, `itemTargetConnected`, `bodyTargetConnected`. This is what makes formatting survive Turbo Stream appends with no re-init logic. Campfire's `sorted_list_controller` re-sorts on `itemTargetConnected` — meaning a broadcast append lands in the right sort position automatically.

9. **Building `data-action` strings in Ruby from a hash or `token_list`.** `ArrangementHelper#arrangement_actions` (16 keyboard bindings from a hash); `ColumnsHelper` (`token_list(default, default, data.delete(:action))`).

10. **Namespacing Hotwire Native controllers in a `bridge/` subdirectory**, referenced as `bridge--form`, and pairing with `bridged_form_with` — instead of platform conditionals sprinkled through app controllers.

11. **The dirty-flag-is-the-timer trick** — `get #dirty() { return !!this.#timer }` in Writebook's `autosave`.

12. **Fake-input focus to summon the mobile soft keyboard** before async content loads (`soft_keyboard_controller`), with a linked gist explaining the browser quirk. Pure production scar tissue.

13. **`turbo_page_requires_reload`** on login/signup pages in both Campfire and Writebook — the only Turbo escape hatch either app uses.

14. **Custom events as a public component API.** Lexxy exposes 18 `lexxy:*` events; Writebook's markdown editor exposes `house-md:change`, consumed as `house-md:change->autosave#change`. A component's contract is its event names, not its methods.

---

## What production code avoids

Ranked by how loudly the blogosphere recommends them.

1. **Page-level morph refreshes (`turbo_refreshes_with method: :morph`) — zero uses across all four apps.** Campfire and Writebook contain no morphing at all; Fizzy uses `method: :morph` only on *targeted* stream operations and frames. The "broadcast a refresh, let morphing figure it out" advice is not shipped by the people who built morphing.

2. **Model callbacks for broadcasting — zero uses.** No `after_create_commit :broadcast_append_to` anywhere. Broadcasts are explicit controller-level calls.

3. **ViewComponent and Phlex — zero uses *at 37signals*.** All four 37signals apps are plain ERB partials plus helper methods; `app/components/` does not exist in any of them. **But this does not generalize** — Avo, solidus_admin, and Alchemy are all heavily ViewComponent-based. The honest reading is that *engines and frameworks* (which must offer a stable, overridable API to host apps) reach for ViewComponent, while *applications* stay with partials + helpers. Solidus's `StimulusHelper` shows the two approaches compose fine.

4. **`stimulus-use` and third-party Stimulus libraries — zero dependencies *at 37signals*.** No `stimulus-use`, no `tailwindcss-stimulus-components`, no `stimulus-components` in any of the four. Behaviors like debounce, throttle, intersection observation, and click-outside are 3–10 lines written inline (`helpers/timing_helpers.js` is 39 lines and covers `throttle`, `debounce`, `nextFrame`, `nextEventNamed`, `delay`, `nextEventLoopTick`). **The ecosystem disagrees:** Avo's `toggle_controller` and solidus_admin's `details_click_outside_controller` both use `stimulus-use`'s `useClickOutside`. So this is a 37signals house preference, not a universal production norm — though it is notable that the inline versions are short enough that the dependency buys very little.

5. **npm / bundlers — zero.** All four use importmap with vendored files (`vendor/javascript/*.min.js`). No build step. Even Lexxy, which *does* have a rollup build, ships the built artifact for Rails consumers.

6. **Lazy controller loading — avoided.** Both Campfire and Writebook use `eagerLoadControllersFrom("controllers", application)`; Writebook's `index.js` keeps the `lazyLoadControllersFrom` line commented out with a warning. Given 69 small controllers in Fizzy, eager loading is evidently fine.

7. **Reactivity gems — zero.** No cable_ready, no StimulusReflex, no turbo_boost. Consistent with that category being dormant post-Turbo 8.

8. **Deep target hierarchies and mega-controllers.** The largest controller in 126 is 403 lines and it is a generic component. Median is under 30 lines.

9. **`connect()` + `querySelectorAll` re-initialization.** Replaced by `xTargetConnected` callbacks almost everywhere.

10. **Constructing URLs in JavaScript.** Every URL arrives as a value from a Rails route helper. Zero string-templated paths.

11. **`data-action` strings written by hand in templates.** In Campfire and Fizzy they are assembled in Ruby. Long inline action strings in ERB are essentially absent.

12. **Defensive `?.` chains.** Lexxy's `STYLE.md` explicitly forbids this: *"The smell is… reaching for `?.` or a fallback to paper over a value that our own logic guarantees is present."* Fail fast instead.

13. **Comments explaining *what*.** Lexxy's `STYLE.md`: *"Avoid adding comments… Comments are usually a sign that the code is below our standards."* The comments that do survive in Campfire/Fizzy all explain non-obvious *why* (the `morph_guard` comment, the `broadcast_unread_room` fan-out rationale, the soft-keyboard gist link).

---

## Verdict: does the composable-primitive philosophy hold up?

**Yes — decisively, and with better evidence than the thesis originally claimed. But with two important refinements.**

### The evidence

**73% of 37signals' 126 production Stimulus controllers are generic, domain-free primitives** (92 generic / 34 one-off). In their newest codebase the figure is 77%. The median controller is under 30 lines. Fourteen distinct primitives appear in two or three separate apps, three of them byte-for-byte identical — they are literally copy-pasting a standard library between projects because no distribution mechanism exists.

Across all 210 controllers surveyed (10 Hotwire codebases) the figure is **62% generic**. That number is dragged down almost entirely by one outlier: **Avo alone contributes 43 of the 79 one-off controllers**, because its product *is* a catalogue of field types and it ships one controller per field. Remove Avo and the remaining 139 controllers are **103 generic / 36 one-off — 74%**, matching 37signals almost exactly. Two ecosystem admins — solidus_admin (6/6) and administrate (3/3) — are **100% generic**, running entire e-commerce and CRUD admin interfaces on 122 and 84 lines of JavaScript respectively.

The honest caveat: **the classification is my judgment, not a mechanical measure.** "Generic" here means the file contains no reference to the host app's domain nouns and its configuration arrives through values/classes/targets. Borderline calls (Campfire's `presence` and `notifications`, Fizzy's `theme` and `collapsible_columns`, Solidus's `flash`) were counted as one-off, so the numbers are conservative rather than flattering.

The one-off controllers are not counter-evidence either. Campfire's 13 app-specific controllers are almost all *integration* controllers — `composer`, `messages`, `presence`, `refresh_room`, `typing_notifications` — that coordinate cable subscriptions and plain-JS objects. They are the seams of the application, and there is no plausible generic version of "the Campfire message composer". The primitives handle everything else.

### Refinement 1: "small" and "generic" are different axes, and generic is the one that matters

The thesis as stated bundles two claims: controllers should be *small* and controllers should be *generic*. Production code supports the second far more strongly than the first.

`arrangement_controller.js` is 403 lines — 42% of Writebook's entire controller codebase in one file — and it is completely domain-free (grep for `book|leaf|chapter` returns only two drag-and-drop MIME-type constants). Fizzy's `navigable_list` (282), `collapsible_columns` (198), `local_time` (172), `drag_and_drop` (150) and `multi_selection_combobox` (133) are the same: large, and reusable.

So the honest formulation is: **controllers should be generic; size follows from the complexity of the behavior, not from a line budget.** A 400-line generic list-arrangement primitive is good architecture. A 60-line `checkout_step_three_controller` is not. Crosswire should say this explicitly, because a naive "keep controllers under 50 lines" rule would push people toward splitting `arrangement` into five coupled controllers, which would be worse.

### Refinement 2: there is a ceiling, and above it Stimulus is the wrong tool

Lexxy is the falsification test the thesis needed. 12,316 lines of editor, **zero Stimulus controllers**, built as custom elements driving plain OO classes, with 18 namespaced custom events as its public API and a 281-line Ruby gem whose only job is to render one tag with the right data attributes.

The same instinct shows up in Campfire at smaller scale: 59% of its JavaScript lives outside `controllers/`, in `models/` and `lib/`. `ScrollManager`, `MessageFormatter`, `MessagePaginator`, `TypingTracker` are plain classes; the Stimulus controllers construct them and forward DOM events.

So the real principle is a three-tier architecture that nobody has written down:

| Tier | Technology | Example |
|---|---|---|
| **Glue** | Stimulus controller, generic, 5–50 lines | `toggle_class`, `auto_submit`, `hotkey`, `drop_target` |
| **Logic** | Plain ES class in `models/` or `lib/`, no DOM lifecycle | `ScrollManager`, `MessageFormatter`, `TypingTracker` |
| **Component** | Custom element + namespaced custom events | `<lexxy-editor>`, `house-md` |

**Stimulus is the wiring tier, not the component tier.** Controllers that grow logic should extract a plain class, not grow. Components that need real internal state and a public API should become custom elements. The ERB-helper pairing spans all three tiers unchanged — which is why the pairing, not Stimulus, is the durable idea.

### Refinement 3 (the biggest one): the pairing is the real thesis

The research set out to check whether anyone besides `hotwire_combobox` pairs a Stimulus controller with an ERB helper. The answer is that **37signals does it universally, and it is the load-bearing reason their controllers can stay generic.**

The causal chain is worth stating plainly: a controller can only be generic if all its app-specific knowledge — CSS class names, URLs, IDs, event bindings, outlet selectors — is injected from outside. Injecting that by hand in ERB is verbose and error-prone, so in practice people give up and write app-specific controllers instead. The helper is what makes genericity *ergonomic*. `button_to_copy_to_clipboard(url)` is shorter than a hand-written `<button data-controller data-action data-*-class data-*-value>`, and it is what allows `copy_to_clipboard_controller.js` to be identical in three different applications.

**So: generic controllers are not achievable at scale without the helper layer.** That is the insight crosswire is built on, it is empirically true in the best Hotwire code that exists, and — remarkably — it is not documented anywhere. `hotwire_combobox` is not an outlier; it is the only *gem* that noticed what 37signals does in every app.

---

## Appendix: repos checked and their status

| Repo | Status |
|---|---|
| `basecamp/once-campfire` | ✅ Read in depth. **MIT** (not source-available as assumed) |
| `basecamp/writebook` | ✅ Read in depth. **MIT** |
| `basecamp/lexxy` | ✅ Read in depth. MIT. **No Stimulus** — Web Components |
| `basecamp/fizzy` | ✅ Read in depth. **Not previously known; highest-value repo found.** O'Saasy License |
| `rails/mission_control-jobs` | ✅ Checked. 1 controller (`form`, 21 lines) |
| `hotwired/turbo-rails` | ✅ Checked (test/dummy) |
| `maybe-finance/maybe` | ⚠️ Archived. 39 controllers. **AGPL-3.0 — do not copy** |
| `blackcandy-org/blackcandy` | ⚪ 21 controllers, surveyed only |
| `avo-hq/avo` | ✅ Hotwire. 71 controllers. License "Other" — check before copying |
| `solidusio/solidus` | ✅ Hotwire **in the admin/promotions engines only**. BSD-ish "Other" |
| `thoughtbot/administrate` | ✅ Hotwire. 3 controllers. MIT |
| `AlchemyCMS/alchemy_cms` | ✅ Turbo, **no Stimulus** (Web Components). BSD-3-Clause |
| `lobsters/lobsters` | ❌ **Not Hotwire** — Sprockets + jQuery |
| `postalserver/postal` | ❌ **Not Hotwire** — Turbolinks 5, jQuery |
| `decidim/decidim` | ❌ **Not Hotwire** — React + Foundation |
| `hotwired/hotwire-native-demo` | ⚪ Exists; not read (Fizzy's `bridge/` covers the same ground better) |

### Repos worth a follow-up pass

- **`basecamp/fizzy`** — only partially mined. `navigable_list` (282 lines), `collapsible_columns` (198), `drag_and_drop` (150), `pagination` (123) and `multi_selection_combobox` (133) were not read in full; each is likely a strong primitive. Its 38 turbo_stream templates and `app/helpers/filters_helper.rb` / `notifications_helper.rb` also went unread.
- **`basecamp/lexxy`'s `STYLE.md`** (327 lines) — a complete house style guide for exactly the kind of code crosswire teaches. Worth reproducing key rules with attribution.
- **`solidusio/solidus`'s `StimulusHelper`** — the generic-helper variant of the pairing deserves its own recipe.
