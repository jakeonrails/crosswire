# 16 — The Three-Tier Architecture: Stimulus Controllers, Plain ES Classes, and Custom Elements

*Research date: 2026-08-15. Primary sources: `basecamp/lexxy` @ 8c64aa4, `basecamp/trix`, `hotwired/turbo`, `basecamp/once-campfire`, `AlchemyCMS/alchemy_cms` — all shallow-cloned and read. Web sources are marked and dated separately.*

This note picks up where [11 — Production Codebases](11-production-codebases.md) left off. That note censused 210 Stimulus controllers and noticed something the Hotwire literature never says out loud: **above a certain complexity, expert Rails teams stop writing Stimulus controllers.** They don't switch to React. They drop to two other tiers that have always been there — plain ES classes and custom elements — and they keep Turbo.

This note establishes that the three tiers are real, documents how each is written in production, and lands a decision rule sharp enough that crosswire never has to re-litigate "should this be a controller?" again.

**Two corrections to note 11, up front:**

- **AlchemyCMS did not "deliberately drop Stimulus."** There is no evidence it ever used Stimulus — no dependency, no issues, no PRs. It migrated jQuery/CoffeeScript straight to Web Components over several years. This makes it *stronger* evidence, not weaker: an independent arrival, not a reaction.
- **The Evil Martians article "Hotwire and Web Components" does not exist.** The real article is Vladimir Dementyev's *"Hotwire: Reactive Rails with no JavaScript?"* (2021), which does make the argument. See [the debate section](#the-debate-stimulus-vs-web-components).

---

## Table of contents

- [The three tiers, defined](#the-three-tiers-defined)
- [Evidence from production](#evidence-from-production)
  - [Lexxy — 12,316 lines, zero Stimulus](#lexxy--12316-lines-zero-stimulus)
  - [Campfire — all three tiers in one feature](#campfire--all-three-tiers-in-one-feature)
  - [Trix — the first draft of the pattern](#trix--the-first-draft-of-the-pattern)
  - [Turbo itself — the canonical house style](#turbo-itself--the-canonical-house-style)
  - [AlchemyCMS — the independent replication](#alchemycms--the-independent-replication)
  - [What the four codebases agree on](#what-the-four-codebases-agree-on)
- [The debate: Stimulus vs Web Components](#the-debate-stimulus-vs-web-components)
  - [First finding: there almost isn't one](#first-finding-there-almost-isnt-one)
  - [The one real thread: hotwired/stimulus#581](#the-one-real-thread-hotwiredstimulus581)
  - [Evil Martians, 2021](#evil-martians-2021--the-earliest-rails-statement-of-the-pattern)
  - [The tradeoffs, honestly stated](#the-tradeoffs-honestly-stated)
  - [Browser support, precisely](#browser-support-precisely)
- [Decision rule: controller vs class vs custom element](#decision-rule-controller-vs-class-vs-custom-element)
- [Form-associated custom elements](#form-associated-custom-elements)
- [Interop patterns](#interop-patterns)
- [Turbo interactions & gotchas](#turbo-interactions--gotchas)
- [Testing each tier](#testing-each-tier)
- [Recommendation for crosswire](#recommendation-for-crosswire)
- [Open questions](#open-questions)

---

## The three tiers, defined

| | Tier 1 — Stimulus controller | Tier 2 — Plain ES class | Tier 3 — Custom element |
|---|---|---|---|
| **Lives in** | `app/javascript/controllers/` | `app/javascript/models/`, `lib/`, `helpers/` | `app/javascript/elements/` (or `lib/**/custom_elements/`) |
| **Identified by** | `data-controller` attribute | an `import` | its tag name in HTML |
| **Owns** | DOM wiring, lifecycle, event forwarding | logic, state machines, algorithms, network | a *thing on the page* with a public API |
| **Public API** | none (private to the element it's on) | its constructor + methods | attributes, properties, methods, **namespaced events** |
| **Lifecycle** | `connect()` / `disconnect()` — Stimulus-managed | none — you own it | `connectedCallback` / `disconnectedCallback` / `attributeChangedCallback` — browser-managed |
| **Can it be in a form?** | no (it's an attribute on something) | no | **yes** — `static formAssociated = true` |
| **Server can render it?** | yes (an attribute) | no | yes (a tag) |
| **Reusable across apps?** | needs the controller registered | yes (import it) | yes (registers itself globally) |
| **Typical size** | 10–60 lines | 40–400 lines | 40–900 lines |

The one-sentence version of each:

- **Tier 1 is an *adapter*.** It translates between the DOM (clicks, targets, values) and something else. It should contain almost no logic. When it grows logic, that logic wants to be Tier 2.
- **Tier 2 is *the program*.** It doesn't know about `data-` attributes, doesn't have a lifecycle, and is testable in a bare `jsdom` with `new`. This is where the actual work lives, and it is where most JavaScript in a serious Hotwire app lives.
- **Tier 3 is a *component*.** It is a noun. It has a tag. The server renders it. It owns its subtree, publishes events as its interface, and — critically — it can be a form control.

The tiers are **not** a ladder you climb as code gets bigger. They are three different *kinds* of thing. A 500-line Stimulus controller is a mistake, but so is a custom element that exists only to add a click handler.

Stimulus's own docs describe Tier 1 accurately. What's missing from the literature is any acknowledgement that Tiers 2 and 3 exist at all — which is why so many Rails apps end up with a `controllers/` directory full of 300-line controllers with private methods, `#state` fields, and hand-rolled pub/sub.

---

## Evidence from production

### Lexxy — 12,316 lines, zero Stimulus

`basecamp/lexxy` is 37signals' Lexical-based replacement for Trix, shipping as the Action Text editor in Rails 8.1+. It is the strongest single data point available, because it is *new* (2025–26), *by the people who invented Stimulus*, and it contains **no Stimulus at all**.

Measured at commit `8c64aa4`:

```
src/**/*.js          12,316 lines across 91 files
lib/**/*.rb             281 lines            ← the entire Ruby gem
Stimulus controllers      0
```

The internal split is the three-tier thesis in one table:

| Directory | Lines | Tier | What's in it |
|---|---:|---|---|
| `src/elements/` | 3,577 | **3** | 11 custom elements |
| `src/editor/` | 4,381 | **2** | `Contents`, `Selection`, `Clipboard`, `CommandDispatcher`, `Configuration`, prompt sources, node inserters |
| `src/nodes/` | 1,425 | 2 | Lexical node subclasses |
| `src/extensions/` | 1,400 | 2 | feature modules |
| `src/helpers/` | 1,261 | 2 | pure functions |
| `src/config/` | 249 | 2 | global config, sanitizer setup |

**71% of Lexxy is Tier 2.** The custom elements are the thin, DOM-facing shell; the plain classes are the program. Compare Campfire's 59% — the same shape at a quarter of the size.

#### Lexxy's own STYLE.md says it in as many words

```
[LEXXY — MIT, © 37signals LLC]  STYLE.md

Lexxy's JavaScript is a set of plain ES modules. The editor is a custom element
(`<lexxy-editor>`) that builds a handful of object-oriented controllers
(`Contents`, `Selection`, `Clipboard`) around a Lexical editor, plus a set of
extensions for optional behavior. Lexical is *a component we drive*, not the
pattern we organize around.
```

And on the Tier-2 boundary:

```
[LEXXY — MIT, © 37signals LLC]  STYLE.md — "OO controllers wrap Lexical"

Our controllers exist to give the editor a clear, intention-revealing API and to
keep Lexical's lower-level abstractions from leaking out. A controller method
should read like a sentence about the editor, not like a Lexical incantation.

Keep UI concerns out of the controllers, and keep raw Lexical objects
(`RangeSelection`, `LexicalNode`, commands) from appearing in their public
signatures. Callers should talk to the controller in the editor's own vocabulary.
```

Note that 37signals calls its Tier-2 classes "controllers". Naming collision with Stimulus — but the intent is clear and it is **not** Stimulus.

#### The element is a shell that composes Tier-2 objects

```js
// [LEXXY — MIT, © 37signals LLC]  src/elements/editor.js (abridged)
export class LexicalEditorElement extends HTMLElement {
  static formAssociated = true
  static observedAttributes = [ "autocapitalize", "connected", "required" ]

  #listeners = new ListenerBin()
  #disposables = []

  constructor() {
    super()
    this.internals = this.attachInternals()
    this.internals.role = "presentation"
  }

  connectedCallback() {
    this.id ||= generateDomId("lexxy-editor")
    this.config      = new Configuration(this)
    this.extensions  = new Extensions(this)
    this.editor      = this.#createEditor()
    this.contents    = new Contents(this)
    this.selection   = new Selection(this)
    this.clipboard   = new Clipboard(this)
    this.adapter     = new BrowserAdapter()

    this.#disposables.push(this.extensions, this.editor, this.#listeners,
                           this.contents, this.selection, this.clipboard)

    this.#initialize()
    this.toggleAttribute("connected", true)

    requestAnimationFrame(() => {
      this.#mountRoot()
      this.#handleAutofocus()
      this.#dispatchInitialize()
    })
  }

  disconnectedCallback() {
    this.valueBeforeDisconnect = this.value
    this.#clearCachedValues()
    this.#reset()   // Prevent hangs with Safari when morphing
  }
}
```

Read `connectedCallback` as a constructor for a graph of Tier-2 objects, and `disconnectedCallback` as its destructor. That's the whole shape.

#### The event API is the public interface

Lexxy exposes **18 namespaced `lexxy:*` events** and essentially nothing else. Every one is dispatched with `bubbles: true`, from one three-line helper:

```js
// [LEXXY — MIT, © 37signals LLC]  src/helpers/html_helper.js
export function dispatch(element, eventName, detail = null, cancelable = false) {
  return element.dispatchEvent(new CustomEvent(eventName, { bubbles: true, detail, cancelable }))
}
```

The catalogue, from `home/docs/events.md`:

| Event | Cancelable | `detail` |
|---|---|---|
| `lexxy:initialize` | — | — |
| `lexxy:editor-initialized` | — | `{ highlightColors, headingFormats }` |
| `lexxy:focus` / `lexxy:blur` | — | — |
| `lexxy:change` | — | — |
| `lexxy:attributes-change` | — | `{ attributes, linkHref, highlight, headingTag }` |
| `lexxy:file-accept` | **yes** | `{ file }` |
| `lexxy:upload-start` / `-progress` / `-end` | — | `{ file, progress?, error? }` |
| `lexxy:insert-link` | — | `{ url, replaceLinkWith(), insertBelowLink() }` |
| `lexxy:insert-markdown` | — | `{ markdown, document, addBlockSpacing() }` |
| `lexxy:code-language-picker-open` | **yes** | picker state |

Three conventions worth stealing verbatim:

1. **`namespace:kebab-case`.** Every event is prefixed with the component's name. This is exactly Turbo's `turbo:*` and Trix's `trix-*` convention (Trix used a hyphen; Lexxy switched to a colon, matching Turbo — treat the colon as current house style).
2. **Cancelable events are a *filter hook*.** `lexxy:file-accept` is dispatched with `cancelable: true` and its return value is the decision. Lexxy itself is just another listener on its own event:
   ```js
   // [LEXXY — MIT, © 37signals LLC]  src/elements/editor.js
   acceptsFile(file) {
     return dispatch(this, "lexxy:file-accept", { file }, true)
   }

   #registerFileAcceptFilter() {
     this.#listeners.track(
       registerEventListener(this, "lexxy:file-accept", (event) => {
         if (!this.permitsAttachmentContentType(event.detail.file.type)) {
           event.preventDefault()
         }
       })
     )
   }
   ```
   The component eats its own dogfood: its built-in policy is implemented through the same public hook it offers you. If the hook can't express the built-in behaviour, the hook is wrong.
3. **`detail` can carry callbacks.** `lexxy:insert-link` hands the listener `replaceLinkWith(html, options)` and `insertBelowLink(html, options)`. This turns a one-way notification into a negotiation without exposing internals. It is the custom-element equivalent of a block parameter.

#### The Ruby side is 281 lines of tag rendering

```rb
# [LEXXY — MIT, © 37signals LLC]  lib/lexxy/rich_text_area_tag.rb (abridged)
def lexxy_rich_textarea_tag(name, value = nil, options = {}, &block)
  options = options.symbolize_keys
  value = render_custom_attachments_in(value)
  value = value.to_str if value.respond_to? :to_str

  options[:name]  ||= name
  options[:value] ||= value
  options[:class] ||= "lexxy-content"
  options[:data]  ||= {}
  options[:data][:direct_upload_url]  ||= main_app.rails_direct_uploads_url
  options[:data][:blob_url_template]  ||= main_app.rails_service_blob_url(":signed_id", ":filename")

  content_tag("lexxy-editor", "", options, &block)
end
```

That is the entire server-side integration: render one tag, with a `name`, a `value`, and two data attributes. The Rails 8.1 path is even thinner — Lexxy registers itself as an Action Text editor and `form.rich_text_area :content` just works:

```rb
# [LEXXY — MIT, © 37signals LLC]  lib/lexxy/engine.rb (abridged)
initializer "lexxy.action_text_editor", before: "action_text.editors" do |app|
  app.config.action_text.editors[:lexxy] = {}
  app.config.action_text.editor = :lexxy
end
```

**The helper↔component pairing survives the move from Tier 1 to Tier 3 unchanged.** In Tier 1 the helper emits `data-controller="foo"`; in Tier 3 it emits `<foo-thing>`. Same idea, same ergonomics, better encapsulation. This matters for crosswire: the pairing, not Stimulus, is the durable idea.

#### And the docs teach Stimulus *interop*, not Stimulus *implementation*

Lexxy's own docs show a Stimulus controller — but as the **host app's** listener, not as part of the component:

```js
// [LEXXY — MIT, © 37signals LLC]  home/docs/events.md
// app/javascript/controllers/link_unfurl_controller.js
import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

export default class extends Controller {
  static values = { url: String }

  unfurl(event) {
    this.#unfurlLink(event.detail.url, event.detail)
  }
  // …fetches metadata, then callbacks.replaceLinkWith(html)
}
```

wired up in ERB:

```erb
<%# [LEXXY — MIT, © 37signals LLC]  test/dummy/app/views/posts/_form.html.erb (abridged) %>
<%= form_with model: post, data: {
      controller: "events-logger file-acceptance unfurl-link",
      action: "lexxy:focus->events-logger#log " \
              "lexxy:change->events-logger#log " \
              "lexxy:insert-link->unfurl-link#unfurl " \
              "lexxy:file-accept->file-acceptance#acceptFile " \
              "lexxy:upload-progress->events-logger#log" } do |form| %>
  <%= form.rich_text_area :body, placeholder: "Write something…", required: true %>
<% end %>
```

This is the canonical Tier-3 ↔ Tier-1 interop pattern, straight from the source. The custom element publishes; Stimulus subscribes, on an *ancestor*, because the events bubble.

---

### Campfire — all three tiers in one feature

`basecamp/once-campfire` (MIT, © 37signals LLC) has the clearest single example, because its autocomplete feature uses **all three tiers at once**:

```
app/javascript/controllers/autocomplete_controller.js      46 lines   Tier 1
app/javascript/lib/autocomplete/*.js                    1,231 lines   Tier 2
app/javascript/lib/autocomplete/custom_elements/*.js       103 lines  Tier 3
```

**Tier 1 — the adapter (46 lines).** It has targets, it has a value, it constructs the Tier-2 object and tears it down. It contains no autocomplete logic whatsoever:

```js
// [CAMPFIRE — MIT, © 37signals LLC]  app/javascript/controllers/autocomplete_controller.js
import { Controller } from "@hotwired/stimulus"
import AutocompleteHandler from "lib/autocomplete/autocomplete_handler"
import { debounce } from "helpers/timing_helpers"

export default class extends Controller {
  static targets = [ "select", "input" ]
  static values  = { url: String }

  #handler

  initialize() { this.search = debounce(this.search.bind(this), 300) }

  connect()    { this.#installHandler(); this.inputTarget.focus() }
  disconnect() { this.#uninstallHandler() }

  search(event)      { this.#handler.search(event.target.value) }
  didPressKey(event) {
    if (event.key == "Backspace" && this.inputTarget.value == "") {
      this.#handler.removeLastSelection()
    }
  }

  #installHandler() {
    this.#uninstallHandler()
    this.#handler = new AutocompleteHandler(this.inputTarget, this.selectTarget, this.urlValue)
  }

  #uninstallHandler() {
    this.#handler?.disconnect()
    this.#handler?.destroy()
  }
}
```

**Tier 3 — pure DOM state (44 lines).** `<suggestion-select>` is *not* a widget; it's a typed accessor over a subtree. Every getter reads the DOM; every setter writes an attribute. There is no internal state at all:

```js
// [CAMPFIRE — MIT, © 37signals LLC]  app/javascript/lib/autocomplete/custom_elements/suggestion_select.js
export default class extends HTMLElement {
  connectedCallback() {
    if (!this.hasAttribute("role")) this.setAttribute("role", "listbox")
  }

  get optionElements() { return this.querySelectorAll("suggestion-option") }

  get selectedIndex() {
    return this.querySelector("suggestion-option[selected]")?.index
  }

  set selectedIndex(value) {
    const optionElements = this.optionElements
    if (!optionElements.length) return
    Array.from(optionElements).forEach(option => { option.selected = false })
    if (value === null || typeof value === "undefined") return
    const index = Math.max(0, Math.min(optionElements.length - 1, parseInt(value, 10)))
    optionElements[index].selected = true
  }

  get selectedOption() { return this.optionElements[this.selectedIndex] }
  get value()          { return this.selectedOption?.value }
}
```

```js
// [CAMPFIRE — MIT, © 37signals LLC]  .../custom_elements/suggestion_option.js (abridged)
export default class extends HTMLElement {
  connectedCallback() { this.id ||= `option-${generateUUID()}` }

  get selectElement() { return this.closest("suggestion-select") }   // ← child→parent discovery

  get index() {
    return this.selectElement
      ? Array.from(this.selectElement.optionElements).indexOf(this)
      : null
  }

  get selected()      { return this.hasAttribute("selected") }
  set selected(value) { value ? this.setAttribute("selected", "") : this.removeAttribute("selected") }
  get value()         { return this.getAttribute("value") }
}
```

Two idioms here that recur everywhere:

- **Attribute-reflecting property pairs.** `get selected()` reads the attribute; `set selected(v)` writes it. State lives in the DOM, so the server can render it, CSS can style it (`suggestion-option[selected]`), morphing preserves it, and there is no separate source of truth to desync. This is *the* custom-element idiom.
- **`this.closest("parent-tag")` for composition.** A child element finds its parent by tag, not by a passed reference. It works regardless of nesting depth and survives the server re-rendering either half.

Registration is separated from definition, in an initializer:

```js
// [CAMPFIRE — MIT, © 37signals LLC]  app/javascript/initializers/autocomplete.js
import SuggestionSelectElement from "lib/autocomplete/custom_elements/suggestion_select"
import SuggestionOptionElement from "lib/autocomplete/custom_elements/suggestion_option"

customElements.define("suggestion-select", SuggestionSelectElement)
customElements.define("suggestion-option", SuggestionOptionElement)
```

Exporting the class and calling `define()` elsewhere is deliberate: the class stays importable and testable without registering a global tag name, and there is exactly one place that owns the registry.

**Tier 2 elsewhere in Campfire** looks like this — no DOM, no lifecycle, a callback out:

```js
// [CAMPFIRE — MIT, © 37signals LLC]  app/javascript/models/typing_tracker.js (abridged)
export default class TypingTracker {
  constructor(callback) {
    this.callback = callback
    this.currentlyTyping = {}
    this.timer = setInterval(this.#refresh.bind(this), REFRESH_INTERVAL)
  }
  close()          { clearInterval(this.timer) }
  add(name)        { this.currentlyTyping[name] = Date.now(); this.#refresh() }
  remove(name)     { delete this.currentlyTyping[name]; this.#refresh() }
  #refresh()       { /* …purge, sort, callback(names) */ }
}
```

and its Tier-1 adapter is a textbook two-liner in `connect`/`disconnect`:

```js
// [CAMPFIRE — MIT, © 37signals LLC]  app/javascript/controllers/typing_notifications_controller.js (abridged)
async connect() {
  if (!pageIsTurboPreview()) {
    this.tracker = new TypingTracker(this.#update.bind(this))
    this.channel = await cable.subscribeTo({ channel: "TypingNotificationsChannel", room_id: Current.room.id },
                                           { received: this.#received.bind(this) })
  }
}

disconnect() {
  this.tracker?.close()
  this.channel?.unsubscribe()
}

#update(message) {
  this.authorTarget.textContent = message
  this.indicatorTarget.classList.toggle(this.activeClass, !!message)
}
```

Note `pageIsTurboPreview()` — a one-line Tier-2 helper (`document.documentElement.hasAttribute("data-turbo-preview")`) used to skip expensive setup while a cached preview is on screen. See [Turbo interactions](#turbo-interactions--gotchas).

---

### Trix — the first draft of the pattern

`basecamp/trix` (MIT) predates Stimulus and shows the pattern in its rawest form. Its `src/trix/` tree is a full MVC in plain ES classes with **two custom elements** and zero Stimulus:

```
src/trix/models/        composition, document, editor, attachment, selection_manager, …  ← Tier 2
src/trix/views/         document_view, block_view, piece_view, attachment_view, …        ← Tier 2
src/trix/controllers/   editor_controller, input_controller, toolbar_controller, …       ← Tier 2 (not Stimulus)
src/trix/observers/     mutation_observer, selection_change_observer                     ← Tier 2
src/trix/operations/    file_verification_operation, image_preload_operation             ← Tier 2
src/trix/elements/      trix_editor_element.js, trix_toolbar_element.js                  ← Tier 3
```

**What changed between Trix and Lexxy:**

| | Trix (2014–) | Lexxy (2025–) | Verdict |
|---|---|---|---|
| Event names | `trix-initialize`, `trix-change` (hyphen) | `lexxy:initialize`, `lexxy:change` (colon) | Use the colon — matches `turbo:*` |
| Events built via | `triggerEvent(name, { onElement, attributes })` helper | `dispatch(el, name, detail, cancelable)` helper | Same idea; Lexxy's is 2 lines |
| Form participation | runtime-switched: `ElementInternals` **or** a shadow `<input type=hidden>` | `static formAssociated = true`, unconditional | Baseline is here — drop the fallback |
| Editable surface | the custom element **is** `contenteditable` | element hosts a `<div contenteditable>` child | Lexxy's is better (see below) |
| Value caching | none | `cachedValue ??=`, invalidated on update | Lexxy's; sanitizing on every read is costly |
| Cleanup | ad-hoc `destroy()` methods | `ListenerBin` + a `#disposables` array | Lexxy's, decisively |
| Toolbar coupling | element creates and inserts a sibling `<trix-toolbar>` | toolbar is a child, discovered or created, wired via `setEditor()` + a promise | Lexxy's — no DOM outside your own subtree |
| Default CSS | `installDefaultCSSForTagName()` injects a `<style>` at import | plain stylesheet shipped by the engine | Lexxy's — injected CSS fights the host app |

The single biggest lesson: **Trix made the custom element itself the `contenteditable` region and it caused a decade of pain.** Lexxy creates an inner `<div class="lexxy-editor__content" contenteditable role="textbox">` and forwards the relevant attributes into it:

```js
// [LEXXY — MIT, © 37signals LLC]  src/elements/editor.js (abridged)
#createEditorContentElement() {
  const editorContentElement = createElement("div", {
    id: `${this.id}-content`,
    classList: "lexxy-editor__content",
    contenteditable: true,
    role: "textbox",
    "aria-multiline": true,
    "aria-label": this.#labelText,
    placeholder: this.getAttribute("placeholder")
  })

  this.#ariaAttributes.forEach(a => editorContentElement.setAttribute(a.name, a.value))
  this.#transferAttributeToContentEditable(editorContentElement, "autocapitalize")
  this.#transferAttributeToContentEditable(editorContentElement, "tabindex", { defaultValue: 0, removeSource: true })

  return editorContentElement
}

get #labelText() {
  return Array.from(this.internals.labels).map(label => label.textContent).join(" ")
}
```

**Generalized rule: the custom element is a *container*, not the interactive surface.** Put the `contenteditable` / `<input>` / `<canvas>` / focusable thing *inside* it and forward attributes in. Then the outer element can be styled, morphed, and re-rendered without destroying the interactive state, and the accessible role of the wrapper (`presentation`) doesn't fight the role of the control (`textbox`).

Trix's other lasting contribution is the `connected` attribute morph trick, which Lexxy inherited verbatim — see [Turbo gotchas](#turbo-interactions--gotchas).

---

### Turbo itself — the canonical house style

`hotwired/turbo` ships three custom elements and nothing else. They *are* the house style, and they're worth copying character for character.

**Registration is guarded.** This is the fix for double-registration, and it's what Turbo does:

```js
// [TURBO — MIT, © 37signals LLC]  src/elements/index.js
if (customElements.get("turbo-frame") === undefined) {
  customElements.define("turbo-frame", FrameElement)
}
if (customElements.get("turbo-stream") === undefined) {
  customElements.define("turbo-stream", StreamElement)
}
if (customElements.get("turbo-stream-source") === undefined) {
  customElements.define("turbo-stream-source", StreamSourceElement)
}
```

**The element is a thin façade over a delegate.** `FrameElement` has *no logic*. It is attribute plumbing plus four lifecycle forwards to a Tier-2 `FrameController`:

```js
// [TURBO — MIT, © 37signals LLC]  src/elements/frame_element.js (abridged)
export class FrameElement extends HTMLElement {
  static delegateConstructor = undefined
  loaded = Promise.resolve()

  static get observedAttributes() { return ["disabled", "loading", "src"] }

  constructor() {
    super()
    this.delegate = new FrameElement.delegateConstructor(this)
  }

  connectedCallback()    { this.delegate.connect() }
  disconnectedCallback() { this.delegate.disconnect() }

  attributeChangedCallback(name) {
    if (name == "loading")       this.delegate.loadingStyleChanged()
    else if (name == "src")      this.delegate.sourceURLChanged()
    else if (name == "disabled") this.delegate.disabledChanged()
  }

  get src()      { return this.getAttribute("src") }
  set src(value) { value ? this.setAttribute("src", value) : this.removeAttribute("src") }

  get disabled()      { return this.hasAttribute("disabled") }
  set disabled(value) { value ? this.setAttribute("disabled", "") : this.removeAttribute("disabled") }

  get complete() { return !this.delegate.isLoading }
}
```

Note `static delegateConstructor = undefined`, wired at the composition root:

```js
// [TURBO — MIT, © 37signals LLC]  src/elements/index.js
FrameElement.delegateConstructor = FrameController
```

That's dependency injection into a custom element — a class you can't pass constructor arguments to, because the browser calls `new` for you. Wiring the delegate as a static breaks the import cycle (`element → controller → element`) and keeps the element file free of the whole framework.

**Attribute-reflecting property pairs, every time.** `src`, `refresh`, `loading`, `disabled`, `autoscroll` all follow the same three-line shape. Booleans use presence (`hasAttribute` / `setAttribute(name, "")`); strings use value; a missing value *removes* the attribute rather than setting `"null"`.

**`<turbo-stream>` shows a second archetype: the element as an *action*.** It renders in `connectedCallback` and then deletes itself:

```js
// [TURBO — MIT, © 37signals LLC]  src/elements/stream_element.js (abridged)
export class StreamElement extends HTMLElement {
  static async renderElement(newElement) { await newElement.performAction() }

  async connectedCallback() {
    try { await this.render() }
    catch (error) { console.error(error) }
    finally { this.disconnect() }
  }

  async render() {
    return (this.renderPromise ??= (async () => {
      const event = this.beforeRenderEvent
      if (this.dispatchEvent(event)) {          // ← cancelable: the app can veto
        await nextRepaint()
        await event.detail.render(this)
      }
    })())
  }

  disconnect() { try { this.remove() } catch {} }

  get beforeRenderEvent() {
    return new CustomEvent("turbo:before-stream-render", {
      bubbles: true, cancelable: true,
      detail: { newStream: this, render: StreamElement.renderElement }
    })
  }
}
```

Two more stealable ideas: **`renderPromise ??=` idempotence** (connect can fire more than once), and **handing the default implementation to the listener in `detail.render`** so an app can wrap rather than replace it.

**`<turbo-stream-source>` is the "element as a subscription" archetype** — a resource whose entire lifetime is the element's lifetime:

```js
// [TURBO — MIT, © 37signals LLC]  src/elements/stream_source_element.js
export class StreamSourceElement extends HTMLElement {
  streamSource = null

  connectedCallback() {
    this.streamSource = this.src.match(/^ws{1,2}:/) ? new WebSocket(this.src) : new EventSource(this.src)
    connectStreamSource(this.streamSource)
  }

  disconnectedCallback() {
    if (this.streamSource) {
      this.streamSource.close()
      disconnectStreamSource(this.streamSource)
    }
  }

  get src() { return this.getAttribute("src") || "" }
}
```

A Stimulus controller could do this, and `turbo-rails` could have shipped it as one. It didn't — because a *tag* is renderable from the server, has a name that appears in the HTML, and can't be accidentally detached from its element by a class change. That's the Tier-3 argument in miniature.

---

### AlchemyCMS — the independent replication

**Correction to the framing in note 11 first.** Alchemy did *not* "drop Stimulus". A search of the repo's issues and PRs for `stimulus` returns **zero results**, and `package.json` has never listed a Stimulus dependency. What actually happened is a multi-year migration from **jQuery/CoffeeScript directly to native Web Components**, visible as a long PR trail: #2554 (datepicker), #2555 (TinyMCE), #2574 (spinner), #2578/#2575 (Safari fixes), #2606 (select), #2611 (menubar), #2615 (node select), #2621 (button), #2623 (jQuery upload → web component), continuing through #4044 and #4128 in 2025–26.

That makes it *better* evidence, not worse: a team modernizing a large Rails admin in the Hotwire era looked at the same problem 37signals looked at and **never reached for Stimulus at all**. It is an independent arrival at Tier 3, not a reaction against Tier 1.

One PR body (#2606, "Add Select Web Component") gives the honest tradeoff in the team's own words:

> Replace default Select2 initializer with a custom component to have an easier initialization. This web component does not work on Safari, but it will gracefully fallback to the default select behavior.

Its own AGENTS.md states the position:

```
[ALCHEMY — BSD-3-Clause]  AGENTS.md

AlchemyCMS is an open source Rails CMS engine … and a modern admin interface
built with Rails + Web Components.
```

It ships **Turbo, ~54 custom elements, and no Stimulus.** (Note the phrase "built with Rails + Web Components" is the project's own self-description, written for coding agents — this is a deliberate architectural stance, not an accident of history.) The entry point is a plain module:

```js
// [ALCHEMY — BSD-3-Clause]  app/javascript/alchemy_admin.js (abridged)
import "@ungap/custom-elements"
import { Turbo } from "@hotwired/turbo-rails"
import "alchemy_admin/turbo_stream_actions"
import "alchemy_admin/components"          // ← every element, imported for side effect

Turbo.config.forms.confirm = openConfirmDialog
document.addEventListener("turbo:load", Initializer)

// Public API for extensions
export { RemoteSelect }   from "alchemy_admin/components/remote_select"
export { PageSelect }     from "alchemy_admin/components/page_select"
export { on }             from "alchemy_admin/utils/events"
```

`components/index.js` is a flat list of 45 side-effect imports; each component file ends with its own `customElements.define(...)`. This is the opposite of Campfire's centralized-registry approach — pick one, don't mix. (Alchemy's is simpler; Campfire's is more testable. See [Testing](#testing-each-tier).)

Alchemy's components span the whole size range, which is what makes it useful. The small end shows how little a custom element can be and still earn its tag:

```js
// [ALCHEMY — BSD-3-Clause]  app/javascript/alchemy_admin/components/auto_submit.js
// Dispatch a submit event on change of input or select elements
// contained in a form, so that Turbo can submit the form.
class AutoSubmit extends HTMLElement {
  connectedCallback()    { this.addEventListener("change", this.#onChange) }
  disconnectedCallback() { this.removeEventListener("change", this.#onChange) }

  #onChange = (event) => {
    const submitEvent = new Event("submit", { bubbles: true, cancelable: true })
    event.target.form.dispatchEvent(submitEvent)
    return false
  }
}

customElements.define("alchemy-auto-submit", AutoSubmit)
```

That is byte-for-byte the job of Campfire's and Writebook's `auto_submit_controller.js` — the same behaviour, chosen into a different tier. **This is the honest counter-evidence: for behaviours this small, the tier choice is a house-style decision, not a technical one.** Alchemy wraps (`<alchemy-auto-submit><form>…</form></alchemy-auto-submit>`); Stimulus decorates (`<form data-controller="auto-submit">`). Decorating is less markup and doesn't add a node; wrapping is self-registering and needs no controller-loading infrastructure.

The `handleEvent` idiom appears repeatedly in Alchemy and is worth stealing — pass `this` as the listener and implement `handleEvent`, and `removeEventListener` works without storing bound functions:

```js
// [ALCHEMY — BSD-3-Clause]  app/javascript/alchemy_admin/components/char_counter.js (abridged)
class CharCounter extends HTMLElement {
  connectedCallback() {
    this.formField = this.getFormField()
    if (this.formField) {
      this.createDisplayElement()
      this.countCharacters()
      this.formField.addEventListener("keyup", this)     // ← `this` is the listener
    }
  }

  disconnectedCallback() { this.formField?.removeEventListener("keyup", this) }

  handleEvent(event) { if (event.type === "keyup") this.countCharacters() }

  get maxChars() { return this.getAttribute("max-chars") ?? 60 }
}

customElements.define("alchemy-char-counter", CharCounter)
```

Alchemy also namespaces its events (`alchemy:element-update-title`, `alchemy:link`, `alchemy:unlink`, `alchemy:page-dirty`) via a shared helper, and — the one thing not to copy — carries a legacy `Alchemy.upload.*` / `Alchemy.Change` dotted convention alongside. Pick one namespace separator and never deviate.

**One Alchemy choice crosswire should *not* copy: customized built-in elements.**

```js
// [ALCHEMY — BSD-3-Clause]
customElements.define("alchemy-select",      Select,     { extends: "select" })
customElements.define("alchemy-button",      Button,     { extends: "button" })
customElements.define("alchemy-dialog-link", DialogLink, { extends: "a" })
```

used as `<select is="alchemy-select">`. WebKit has refused to implement customized built-ins for a decade, so Alchemy ships the `@ungap/custom-elements` polyfill as a hard dependency and imports it first in the bundle. That's a real tax (an extra dependency, an ordering constraint, and a class of bugs that only appear in Safari) in exchange for inheriting `<select>` semantics. See [the decision rule](#decision-rule-controller-vs-class-vs-custom-element) for what to do instead.

Finally, Alchemy's `turbo_stream_actions.js` is a good demonstration that **Turbo Stream custom actions are a fourth integration seam** — a way for the server to call into the client without any controller or element at all:

```js
// [ALCHEMY — BSD-3-Clause]  app/javascript/alchemy_admin/turbo_stream_actions.js (abridged)
Turbo.StreamActions.dialog_visit = function () {
  const url = this.getAttribute("url")
  if (!closeCurrentDialog(() => Turbo.visit(url))) Turbo.visit(url)
}

// The editors observe their form field for mutations, so it must not be replaced.
Turbo.StreamActions.assign_picture = function () {
  const [formField] = this.targetElements
  if (!formField) return
  formField.value = this.getAttribute("picture-id")
  closeCurrentDialog(() => formField.closest("alchemy-element-editor")?.setDirty())
}
```

Note that comment: *"the editors observe their form field for mutations, so it must not be replaced."* A custom action exists precisely because a normal `replace` stream would destroy a live component. That's a Tier-3 constraint leaking into stream design, and it will bite crosswire too.

---

### What the four codebases agree on

Independently arrived at, in all of Lexxy, Trix, Turbo, Campfire and Alchemy:

1. **The custom element is a shell.** Logic lives in plain classes it constructs. Turbo names the pattern outright (`delegateConstructor`); Lexxy calls them "OO controllers"; Trix calls them models/views/controllers.
2. **State lives in attributes, exposed as reflecting property pairs.** No shadow state object.
3. **Events are the public API, namespaced `component:verb-phrase`, always `bubbles: true`.**
4. **Cancelable events are the extension mechanism.** `preventDefault()` = veto. The component implements its own defaults through the same hook.
5. **`this.closest("parent-tag")` for child→parent wiring.**
6. **Explicit disposal.** `disconnectedCallback` tears down *everything* — every listener, timer, observer, and subscription. Lexxy formalizes it with `ListenerBin` + a `#disposables` array; Turbo with `delegate.disconnect()`.
7. **Nobody uses Shadow DOM.** Not one element in Lexxy, Trix, Turbo, Campfire or Alchemy attaches a shadow root for encapsulation. (`shadow_root_node_inserter.js` in Lexxy is about Lexical's internal node model, not Shadow DOM.) Every component is light-DOM, so the server renders its children and the app's stylesheet styles them.
8. **Zero framework dependencies at Tier 3.** No Lit, no Stencil, no decorators. `extends HTMLElement`, hand-written.

---

## The debate: Stimulus vs Web Components

### First finding: there almost isn't one

This is worth stating plainly, because it shapes crosswire's opportunity. A deliberate search of the places this debate *should* live came up nearly empty:

| Source | Result |
|---|---|
| **betterstimulus.com** | Sections on Architecture, DOM Manipulation, Events, Lifecycle, SOLID, "With Turbo". **No page on web components, custom elements, or when not to use Stimulus.** Confirmed by fetching the index and the two likeliest pages. |
| **hotwire.io** | No article or page on custom elements. |
| **Evil Martians** | No article titled "Hotwire and Web Components", "Reactive UI with Hotwire", or "Rails, Hotwire, and Web Components" exists. Note 11's premise was wrong; see below for what *does* exist. |
| **DHH / 37signals** | **No statement found** explaining why Lexxy has no Stimulus. Searched `basecamp/lexxy` issues and discussions and the visible slice of world.hey.com/dhh. |
| **AlchemyCMS** | No blog post, ADR, CONTRIBUTING, or AGENTS text explaining the choice. The PR trail is the only evidence. |
| **`hotwired/stimulus` issues/discussions** | **Exactly one substantive thread** (#581) in the project's history. |

**The three-tier architecture is undocumented not because it's controversial but because nobody has bothered.** The practitioners doing it are shipping, not writing. That is exactly the gap crosswire exists to fill — and it also means we should be honest that we are synthesizing a pattern from code, not summarizing a settled consensus.

### The one real thread: `hotwired/stimulus#581`

[hotwired/stimulus#581, "Feature Idea — Component-API"](https://github.com/hotwired/stimulus/issues/581) (2023, closed) is the only place the question is argued properly. The core exchange, verbatim:

**Jared White**, arguing the widget/mixin distinction — this is the sharpest statement of the tier boundary anyone has made in public:

> A conversation around "component APIs" which doesn't start with custom elements (aka web components) in ~2023 is missing the forest for the trees. I would love to see Stimulus fully embrace web components. Right now they can certainly co-exist but there are rough edges and if you introduce shadow DOM stuff falls apart.
>
> I also think as "modest" as Stimulus is in terms of project goals, it's already veering into the territory I believe is now better served by web components. In other words, every Stimulus controller should ask itself if it should actually be a custom element IMHO. **I see Stimulus as a useful way to introduce generic behavior "mixins" to existing server-rendered HTML, but when it wades into "this is a widget" territory I question why one would write `<div data-controller="my-widget">` instead of `<my-widget>`.**

**KonoMaxi** (the issue's author), replying with the counter-position — and note that he uses *both*, splitting them by scope, not by size:

> Indeed I also use Web Components for some functionality I previously tackled with stimulusControllers — Google's LitElement is quite handy for this stuff and plays nice with import-maps. **For me a stimulus-controller is a piece of "life-cycled" javascript that overarches sometimes huge sections of my HTML-pages… Something I really don't want to do with web-components, as I tend to use them for small reusable components that I "sprinkle" all over the place.**
>
> […] I understand this is also possible with web-components, but they sadly have a lot of restrictions — maybe that's why frameworks like svelte have gained popularity this quickly in recent years.

**Marco Roth** (Stimulus core team), on why a component API won't land in Stimulus itself:

> I also think that most of the Stimulus users are not going to need that kind of depth for writing Stimulus controllers, also because **it kinda speaks against the general ideology behind Stimulus**. That's why I think we should start with option 1, before thinking about putting this or part of it into upstream Stimulus.

Three things to take from this thread:

1. **The "mixin vs widget" line is the same line this note draws** from reading code, arrived at independently three years earlier. That's a useful convergence.
2. **The two practitioners disagree about which tier owns *scope*.** Jared White splits by *encapsulation* (is it a self-contained thing?); KonoMaxi splits by *span* (does it wire together a large region of unrelated markup?). Both are defensible. Our decision rule follows White's — but KonoMaxi's "a controller can overarch huge sections of page" is a real Tier-1 use case our rule should not forbid: a controller coordinating five unrelated regions of a page is legitimate glue, however long it is.
3. **Stimulus core has no ambition here.** Stimulus is frozen at 3.2.2 (Aug 2023) and its maintainers consider "component" territory out of scope by design. Nothing is coming to close the gap. Whatever Tier 3 looks like in Rails, it is going to be hand-written custom elements.

For completeness, DHH addressed the "is Stimulus dead" question in [hotwired/stimulus#803](https://github.com/hotwired/stimulus/issues/803#issuecomment-2629405803) (2 Feb 2025):

> Absolutely not. But not every package of software needs a constant churn of releases to be alive. Stimulus is used by every new Rails app by default, and it powers Basecamp, HEY, and a bunch of other web apps.

Read alongside Lexxy: Stimulus is finished, not dead — and 37signals reaches past it for components without announcing that they have.

### Evil Martians, 2021 — the earliest Rails statement of the pattern

The article that actually exists is **["Hotwire: Reactive Rails with no JavaScript?"](https://evilmartians.com/chronicles/hotwire-reactive-rails-with-no-javascript)** by **Vladimir Dementyev**, 12 April 2021. Building a chat, he uses Stimulus (with a mutation observer) for the cross-cutting behaviour and then reaches for a custom element for the per-message behaviour:

```html
<!-- [Evil Martians, 2021 — quoted for study] -->
<any-chat-message class="chat--msg" data-author-id="<%= user_id %>">
  <%= message %>
  <%= name %>
</any-chat-message>
```

```js
import { currentUser } from "../utils/current_user";

// This is how you create custom HTML elements with a modern API
export class ChatMessageElement extends HTMLElement {
  connectedCallback() {
    const mine = currentUser().id == this.dataset.authorId;

    this.classList.add(mine ? "mine" : "theirs");

    const authorElement = this.querySelector('[data-role="author"]');

    if (authorElement && mine) authorElement.innerText = "You";
  }
}

customElements.define("any-chat-message", ChatMessageElement);
```

> That's it! Now when a new `<any-chat-message>` element is added on a page, it automatically updates itself if the message came from the current user. **And we don't even need Stimulus for that!**

And the honest conclusion:

> So, does Reactive Rails With Zero JavaScript exist after all? Not really. We removed a lot of JS code but eventually had to replace it with something new. This new code is different from what we had before: it's more, I'd say, *utilitarian*. It's also more advanced and **requires a good knowledge of both JavaScript and the latest browser APIs, which is definitely a trade-off to consider.**

That last sentence is the honest cost of Tier 3 and belongs in crosswire's docs: custom elements demand more platform knowledge than Stimulus does. Stimulus's real value proposition was never technical superiority — it was that a Rails developer could learn it in an afternoon.

(Evil Martians' 2026 piece ["From React to native web with nanotags"](https://evilmartians.com/chronicles/from-react-to-native-web-with-nanotags-a-migration-that-saved-100kb) argues for custom elements generally — *"Web Components are part of the platform. The Custom Elements API has been stable in every modern browser since 2018"*, 100 KB saved — but it's an Astro project with no Rails or Stimulus content. Cite it only for the platform-stability point, and note that its whole premise is that raw custom elements have too much boilerplate, which is why they built a 2.5 KB wrapper. That is a genuine argument against hand-rolled Tier 3 at scale.)

### The tradeoffs, honestly stated

**For custom elements over Stimulus controllers:**

1. **A widget deserves a tag.** (`#581`) `<my-widget>` names the thing; `<div data-controller="my-widget">` decorates an anonymous div. The tag is self-documenting in view source, in the server template, and in a test.
2. **Form participation.** Decisive and not close: `ElementInternals` is the only way a custom control gets into `params`, validation, reset, and `:disabled`. Stimulus has no answer.
3. **Encapsulation without a framework.** The element owns its subtree; the world talks to it through attributes, properties, and events. A controller's "API" is a set of `data-` attributes anyone can typo.
4. **Self-registering and portable.** `customElements.define` is global. There is no controller-loading infrastructure, no importmap pin per component, no `application.register`. This is why component *libraries* (Trix, Lexxy, `<turbo-frame>`) are always elements.
5. **Platform durability.** Custom Elements v1 has been stable in every modern browser since 2018. Stimulus has been frozen since 2023 and has no roadmap into this territory.
6. **Not forgeable from stored content.** A sanitizer must explicitly allow-list a custom element's tag; `data-controller` is just an attribute that slips through any sanitizer that permits `data-*`. See [gotcha 6](#6-data-controller-and-data-action-are-a-stored-content-attack-surface).

**Against — real costs, not FUD:**

1. **Boilerplate.** `observedAttributes`, reflecting property pairs, idempotent connect, complete disconnect, `attachInternals` plumbing. A 15-line controller becomes a 60-line element. This is why nanotags and Lit exist.
2. **Platform knowledge required.** Dementyev's point. The lifecycle has genuine sharp edges (constructor restrictions, upgrade timing, connect firing repeatedly) that Stimulus papers over.
3. **Shadow DOM breaks things.** (`#581`: *"if you introduce shadow DOM stuff falls apart"*.) Stimulus doesn't traverse shadow boundaries; neither does Turbo's morphing, nor `form.elements`, nor most CSS. **This is why every codebase we read uses light DOM.** It's not that Shadow DOM is unavailable — it's that in a server-rendered Rails app it costs everything and buys style isolation you don't need.
4. **Double registration is an operational hazard** with no Stimulus equivalent — `application.register` is idempotent, `customElements.define` throws. See [gotcha 1](#1-double-registration--notsupportederror-on-navigation) and [hotwired/turbo#104](https://github.com/hotwired/turbo/issues/104).
5. **You can't decorate.** A custom element must *be* a node. To add behaviour to a `<form>` the server already renders, Stimulus adds an attribute; a custom element has to wrap it, adding a node to the tree and a layout box you must neutralize with `display: contents` (which itself has a11y bugs). **For decorating behaviours, Stimulus is genuinely the better tool.**
6. **Real browser gaps remain** — see the compatibility table below.
7. **Nothing is composable across tiers by attribute.** Two Stimulus controllers stack on one element trivially (`data-controller="a b"`). Two custom elements require nesting.

### Browser support, precisely

Pulled from `mdn/browser-compat-data` (`api/ElementInternals.json`, `api/HTMLElement.json`) rather than the rendered MDN page:

| Feature | Chrome | Firefox | Safari |
|---|---:|---:|---:|
| `ElementInternals`, `attachInternals()` | 77 | 93 | **16.4** |
| `setFormValue`, `setValidity`, `checkValidity`, `reportValidity`, `validity`, `validationMessage`, `willValidate`, `form`, `labels` | 77 | 98 | 16.4 |
| `internals.role` | 103 | 119 | 16.4 |
| Common `aria*` reflection (`ariaLabel`, `ariaExpanded`, `ariaInvalid`, `ariaRequired`, …) | 81 | 119 | 16.4 |
| `internals.states` (`CustomStateSet` → CSS `:state()`) | 90 | 126 | **17.4** |
| Element-reference ARIA (`ariaLabelledByElements`, `ariaControlsElements`, …) | 135 | 136 | 16.4 |
| `ariaDescription` | 83 | 119 | **not supported** |
| `ariaColIndexText` / `ariaRowIndexText` | 128 | 119 | **not supported** |
| `ariaOwnsElements` | **not supported** | 136 | 16.4 |

**Baseline for crosswire: Safari 16.4 (March 2023).** Form-associated custom elements are safe. `:state()` requires Safari 17.4 (March 2024) — still fine, but a year newer, which is why the [open questions](#open-questions) flag it. Do not rely on `ariaDescription` or the row/col index-text properties.

Two caveats from web.dev's *More capable form controls* that are easy to be surprised by:

- **Chrome does not display the native validation message bubble for form-associated custom elements.** `setValidity` still blocks submission and `reportValidity()` still returns `false` and fires `invalid` — but the user may see nothing. **Render your own error text**; don't rely on the browser's bubble as the only feedback. (This alone justifies the Rails habit of server-rendered inline errors.)
- **Chrome does not handle autofill for form-associated custom elements.** Anything that should autofill (address, name, payment) must be a real `<input>`.
- **There are no polyfills** for `formAssociated` or the `formdata` event, and web.dev says they're "likely difficult or impossible to polyfill". Support is a floor, not a gradient.

---

## Decision rule: controller vs class vs custom element

Apply in order. The first rule that fires wins.

### Rule 0 — Can the server do it?

If the behaviour can be expressed as a Turbo Frame, a Turbo Stream, `data-turbo-permanent`, a `<details>`, a `<dialog>`, `popover`, an anchor, or CSS — **do that and write no JavaScript.** This rule kills more candidate components than the other three combined.

### Rule 1 — Does it need to be a form control?

**If the thing has a `name` and a value that must submit with `form_with` → Tier 3, form-associated.**

There is no other way to do this. A Stimulus controller cannot participate in form submission, validation, reset, or `:disabled` propagation. A hidden-input mirror is the workaround, and it desynchronizes, doesn't validate, doesn't reset, and doesn't respond to `<fieldset disabled>`.

- ✅ Tier 3: rich text editor, tag/token input, star rating, color picker, date-range picker, signature pad, sortable list that submits an order, file dropzone with a value, combobox over a remote source.
- ❌ Not this rule: a "copy to clipboard" button in a form. It has no value.

### Rule 2 — Does it own a *subtree* and have consumers?

The short form is Jared White's, from [stimulus#581](https://github.com/hotwired/stimulus/issues/581): **is it a behaviour mixin on markup the server already rendered, or is it a widget?** Mixin → Tier 1. Widget → Tier 3. Three questions make that concrete.

**If the answer to all three is yes → Tier 3.**

1. Is it a **noun** you'd name in a design review ("the composer", "the sitemap", "the cropper")?
2. Does it **own DOM it created**, not just DOM it decorates?
3. Will **someone outside it** need to observe or command it — another component, a Stimulus controller, a test, a Turbo Stream action?

If (3) is no, you don't need a public API, and you probably don't need a tag.

- ✅ Tier 3: `<lexxy-editor>`, `<alchemy-image-cropper>`, `<suggestion-select>`, `<turbo-stream-source>`, a `<chart-canvas>`, a virtualized `<data-grid>`.
- ❌ Tier 1: `data-controller="clipboard"`, `data-controller="auto-submit"`, `data-controller="toggle-class"` — these *decorate* an element that already exists and nobody needs to talk to them.

### Rule 3 — Is it logic without a DOM lifecycle?

**If it can be tested with `new Thing()` in a bare Node process → Tier 2, always.**

Algorithms, state machines, formatters, parsers, network clients, schedulers, caches, trackers. If a method takes an `HTMLElement` argument, that's fine; if it reads `data-` attributes off `this.element`, it's drifted into Tier 1's job.

- ✅ Tier 2: `MessageFormatter`, `TypingTracker`, `ScrollManager`, `AutocompleteHandler`, `Selection`, `Clipboard`, a debounce helper, a `request.js` wrapper.
- ❌ Tier 1: anything whose whole body is `this.element.classList.toggle(...)`.

### Rule 4 — Everything else is Tier 1.

Glue, wiring, forwarding, small imperative behaviours attached to server-rendered markup. **A Stimulus controller should be under ~60 lines and mostly `connect`, `disconnect`, and action methods.**

### The escalation triggers

Rewrite a Tier-1 controller into another tier the moment any of these is true:

| Symptom | Move to |
|---|---|
| It has private fields holding non-DOM state that survives across actions | **Tier 2** (extract the state machine) |
| It has private methods that don't touch `this.element` or targets | **Tier 2** |
| It's past ~80 lines | **Tier 2** (the logic) — controller stays |
| Two controllers coordinate via a shared `window.` global or dispatched events on `document` | **Tier 2** (a shared module) or **Tier 3** (make the thing a component) |
| It creates and manages DOM it invented, with its own internal structure | **Tier 3** |
| It needs a value in `form_with` | **Tier 3** |
| It needs to survive being re-rendered by a Turbo Stream, holding state | **Tier 3** (`data-turbo-permanent` + a real element) |
| You want to hand it to another team/app | **Tier 3** |

And the reverse — signs a Tier 3 element should have been a Tier 1 controller:

| Symptom | Move to |
|---|---|
| It never creates DOM; it only adds one listener to a child | **Tier 1** |
| It has no attributes, no properties, no events | **Tier 1** |
| Its only reason to exist is "I needed a lifecycle hook" | **Tier 1** — Stimulus is a lifecycle hook |
| It wraps an existing element only to intercept its events | **Tier 1** (decorate, don't wrap) |

### Worked examples on both sides of each line

**"Copy to clipboard button": Tier 1.**
Rule 1 no (no value). Rule 2: it decorates a `<button>` the server already rendered; nobody needs to command it. Rule 3 no. → `data-controller="clipboard"`. *Alchemy makes it `<alchemy-clipboard-button>` and pays for it with a wrapper node and a hand-built inner icon; we prefer decorating.*

**"Tag input that submits `post[tag_ids][]`": Tier 3.**
Rule 1 fires immediately. It must appear in `params`, must reset with the form, must respect `required`, must go grey inside `<fieldset disabled>`. → `<tag-input name="post[tag_ids][]" formAssociated>` with a Tier-2 `TagCollection` doing the set arithmetic.

**"Autocomplete over `/users`": Tier 1 + Tier 2 + Tier 3.**
The search/debounce/fetch/keyboard state machine is Tier 2 (`AutocompleteHandler`). The list-with-a-selected-option DOM is Tier 3 (`<suggestion-select>` / `<suggestion-option>`) because two independent pieces of code — the handler and the keyboard nav — both need to read/write the selection through a stable API. The `data-controller="autocomplete"` that constructs the handler and tears it down is Tier 1. This is Campfire, exactly.

**"Auto-submit a filter form on change": Tier 1.**
Rule 2 question 3 fails: nobody talks to it. Twelve lines of `data-controller="auto-submit"`. *Alchemy chose Tier 3 for this and it's fine — but it costs a wrapper element, and once you have `<alchemy-auto-submit>` in your markup you can never make it not-a-node.*

**"Countdown timer showing `2:31`": Tier 1 + Tier 2.**
The clock arithmetic and interval are Tier 2 (`Countdown`, testable with fake timers). The controller writes `textContent`. No tag needed — nobody commands a countdown. *If you later need `<x-countdown>.pause()` from a Turbo Stream action, promote it to Tier 3.*

**"Sortable list of sections that persists order": Tier 3.**
Rule 1 fires if the order submits with the form; Rule 2 fires regardless (it owns drag state, has drop events others care about). Sortable.js instance is Tier 2, held by the element.

**"Modal dialog": Tier 0.**
Native `<dialog>` + `showModal()`. If you need it opened from a link, that's a five-line Tier-1 controller. Do not build `<x-modal>`.

**"Chart rendered from a JSON payload": Tier 3, marginal.**
Rule 2: it owns a `<canvas>` it created, and Turbo Streams will want to push new data into it without destroying it. `<line-chart data-series="…">` with an `update(series)` method beats `data-controller="chart"` because the stream action can call `document.getElementById("x").update(...)` against a stable interface. But if it's a static chart that never updates, Tier 1 + Tier 2 is less machinery.

**"Character counter under a textarea": Tier 1.**
Decorates an existing field, no consumers, ~15 lines. *Alchemy's `<alchemy-char-counter>` has to `querySelector` its way to the field it's wrapping; a controller just uses a target.*

---

## Form-associated custom elements

This is the capability that makes Tier 3 possible in Rails at all. Without it, a custom element cannot appear in `params` and the whole idea collapses back to hidden-input mirroring.

### The full API surface

Opt in with a static field; the browser then treats your element like a built-in control:

```js
class MyControl extends HTMLElement {
  static formAssociated = true      // ← the switch

  #internals

  constructor() {
    super()
    this.#internals = this.attachInternals()   // throws if called twice
  }
}
```

`attachInternals()` returns an `ElementInternals` giving you:

| Member | Purpose |
|---|---|
| `internals.form` | the owning `<form>`, honouring the `form="id"` attribute — read-only |
| `internals.labels` | `NodeList` of `<label>`s pointing at this element |
| `internals.setFormValue(value, state?)` | the value that submits. `string \| File \| FormData \| null` |
| `internals.setValidity(flags, message?, anchor?)` | mark invalid/valid; `anchor` is the element the browser scrolls to and points the bubble at |
| `internals.validity` | the resulting `ValidityState` |
| `internals.validationMessage` | current message |
| `internals.willValidate` | whether it participates in validation right now |
| `internals.checkValidity()` / `reportValidity()` | as on a native control |
| `internals.states` | a `CustomStateSet` — `internals.states.add("loading")` → matches `:state(loading)` in CSS |
| `internals.role`, `internals.ariaLabel`, `internals.ariaExpanded`, … | default ARIA semantics, overridable by real attributes |

And four lifecycle callbacks the browser calls on you:

| Callback | When |
|---|---|
| `formAssociatedCallback(form)` | associated with (or disassociated from, `null`) a form |
| `formDisabledCallback(disabled)` | element or an ancestor `<fieldset>` became `[disabled]` |
| `formResetCallback()` | the form was reset |
| `formStateRestoreCallback(state, mode)` | `"restore"` on bfcache/session restore, `"autocomplete"` for autofill — receives the second argument you passed to `setFormValue` |

Free consequences of `formAssociated = true`: the `:disabled`, `:enabled`, `:valid`, `:invalid`, `:required`, `:optional` CSS pseudo-classes apply to your tag; `<fieldset disabled>` cascades to it; `form.elements` contains it; `form.reset()` reaches it.

### The Rails recipe, end to end

**1. The element.** A single-value control that submits under `name`, validates `required`, and resets:

```js
// app/javascript/elements/rating_element.js
export default class RatingElement extends HTMLElement {
  static formAssociated = true
  static observedAttributes = [ "value", "required", "max" ]

  #internals
  #defaultValue = null

  constructor() {
    super()
    this.#internals = this.attachInternals()
    this.#internals.role = "radiogroup"
  }

  // --- form control surface -------------------------------------------------

  get form()              { return this.#internals.form }
  get name()              { return this.getAttribute("name") }
  get type()              { return this.localName }
  get validity()          { return this.#internals.validity }
  get validationMessage() { return this.#internals.validationMessage }
  get willValidate()      { return this.#internals.willValidate }
  checkValidity()         { return this.#internals.checkValidity() }
  reportValidity()        { return this.#internals.reportValidity() }

  get value()      { return this.getAttribute("value") }
  set value(next)  { next == null ? this.removeAttribute("value") : this.setAttribute("value", next) }

  get required()   { return this.hasAttribute("required") }
  get max()        { return Number(this.getAttribute("max") ?? 5) }

  // --- lifecycle ------------------------------------------------------------

  connectedCallback() {
    this.#defaultValue = this.getAttribute("value")
    this.#render()
    this.addEventListener("click", this)
    this.addEventListener("keydown", this)
    this.#sync()
  }

  disconnectedCallback() {
    this.removeEventListener("click", this)
    this.removeEventListener("keydown", this)
  }

  attributeChangedCallback(name) {
    if (!this.isConnected) return
    if (name === "value") { this.#render(); this.#sync() }
    if (name === "required") this.#validate()
  }

  formResetCallback() {
    this.value = this.#defaultValue
  }

  formDisabledCallback(disabled) {
    this.toggleAttribute("inert", disabled)
    this.#validate()
  }

  formStateRestoreCallback(state) {
    this.value = state
  }

  // --- internals ------------------------------------------------------------

  handleEvent(event) {
    if (event.type === "click")   this.#choose(event.target.closest("[data-star]")?.dataset.star)
    if (event.type === "keydown") this.#handleKey(event)
  }

  #choose(star) {
    if (!star) return
    this.value = star
    this.dispatchEvent(new CustomEvent("rating:change", { bubbles: true, detail: { value: this.value } }))
  }

  #sync() {
    // Submits as `name=value`. Pass null to submit nothing at all.
    this.#internals.setFormValue(this.value, this.value)
    this.#validate()
  }

  #validate() {
    if (this.required && !this.value) {
      this.#internals.setValidity(
        { valueMissing: true },
        "Please choose a rating.",
        this.querySelector("[data-star]") ?? this          // ← anchor: what the bubble points at
      )
    } else {
      this.#internals.setValidity({})
    }
  }

  #render() { /* paint stars from this.value / this.max */ }
}
```

Register it once, guarded:

```js
// app/javascript/elements/index.js
import RatingElement from "elements/rating_element"

if (!customElements.get("x-rating")) customElements.define("x-rating", RatingElement)
```

**2. The ERB helper** — the Tier-3 half of the helper↔component pairing:

```rb
# app/helpers/rating_helper.rb
module RatingHelper
  def rating_field_tag(name, value = nil, max: 5, required: false, **options)
    tag.x_rating(name: name, value: value, max: max, required: required, **options)
  end
end
```

`tag.x_rating` emits `<x-rating>` — Rails' `tag` builder converts underscores to hyphens, so no `content_tag("x-rating", ...)` needed. With a form builder:

```rb
# app/helpers/form_builders/rating.rb  (mixed into your builder)
def rating_field(method, **options)
  @template.rating_field_tag(
    field_name(method),
    object&.public_send(method),
    id: field_id(method),
    **options
  )
end
```

```erb
<%= form_with model: @review do |form| %>
  <%= form.label :stars %>
  <%= form.rating_field :stars, max: 5, required: true %>
  <%= form.submit %>
<% end %>
```

Submits `review[stars]=4`. Fails browser validation with the native bubble when empty. Resets with `<button type="reset">`. Greys out inside `<fieldset disabled>`. `form.errors` styling via `:invalid` works. No hidden input anywhere.

### Multi-value fields (`name[]`)

`setFormValue` takes a `FormData` when one control needs to submit several entries — this is how a token/tag input submits `post[tag_ids][]`:

```js
#sync() {
  const data = new FormData()
  for (const id of this.#selectedIds) data.append(this.name, id)
  this.#internals.setFormValue(data)          // `name` on each entry, not the element's name
}
```

Rails' `post[tag_ids][]` convention works as long as `this.name` already ends in `[]`, i.e. the helper emits `name="post[tag_ids][]"`. Note that when you pass a `FormData`, the element's own `name` attribute is ignored — the keys inside the `FormData` are used verbatim.

To submit **nothing** (the "unchecked checkbox" case) pass `null`. Trix does exactly this for disabled editors:

```js
// [TRIX — MIT, © 37signals LLC]  src/trix/elements/trix_editor_element.js
setFormValue(value) {
  this.value = value
  this.#validate()
  this.#internals.setFormValue(this.element.disabled ? undefined : this.value)
}
```

For Rails' "always send something so the param key exists" pattern, emit a real `<input type="hidden" name="…" value="">` *before* the element in the helper, exactly as `check_box` does — don't try to make `setFormValue` do two things.

### Validation, the Trix way

Trix's `#validate` is the cleanest trick in the corpus: **build a throwaway native input and steal its localized validation message**, so you never hardcode English:

```js
// [TRIX — MIT, © 37signals LLC]  src/trix/elements/trix_editor_element.js (abridged)
#validate(customValidationMessage = "") {
  const { required, value } = this.element
  const valueMissing = required && !value
  const customError = !!customValidationMessage
  const input = makeElement("input", { required })
  const validationMessage = customValidationMessage || input.validationMessage

  this.#internals.setValidity({ valueMissing, customError }, validationMessage)
}
```

Lexxy scales the same trick to *multiple* validity sources — a `Map` of contributors keyed by object, merged into one `ValidityState`, so an extension can add a constraint without the editor knowing about it:

```js
// [LEXXY — MIT, © 37signals LLC]  src/elements/editor.js (abridged)
#validity = new Map()
#validationTextArea = document.createElement("textarea")

setElementValidity(key, flags, message) {
  this.#validity.set(key, { flags, message })
  this.#requestValidityRefresh()
}

async #requestValidityRefresh() {
  await nextFrame()
  if (this.isConnected) this.#refreshValidity()
}

#refreshValidity() {
  this.#refreshInternalValidity()
  const { validity, message } = this.#calculateValidity()
  this.internals.setValidity(validity, message, this.editorContentElement)
}

#refreshInternalValidity() {
  this.#validationTextArea.required = this.required && this.isBlank
  this.#validity.set(this, {
    flags: this.#validationTextArea.validity,
    message: this.#validationTextArea.validationMessage
  })
}

#calculateValidity() {
  const validity = {}
  const messages = []
  for (const { flags, message } of this.#validity.values()) {
    if (flags.valid === true) continue                  // a valid ValidityState contributes nothing
    for (const flag in flags) {
      if (flags[flag]) { validity[flag] = true; messages.push(message) }
    }
  }
  return { validity, message: messages.join("\n") }
}
```

Three things to copy: the **reusable hidden native control** as a message oracle; the **`await nextFrame()` debounce** so validity is recomputed once per frame instead of once per keystroke; and the **third argument to `setValidity`** — the *anchor* — pointing at the actual visible control so the browser's error bubble lands in the right place rather than on an invisible wrapper.

### Focus, labels and a11y

A form-associated custom element is **not automatically focusable**. Three options:

1. **Host a real control inside** (Lexxy's `<div contenteditable role="textbox">`, or a visually-hidden `<input>`). Best for anything text-like.
2. **`tabindex="0"` on the element** plus your own key handling. Fine for composite widgets, but you must implement roving tabindex yourself. Lexxy ships `handleRollingTabIndex` in `helpers/accessibility_helper.js` for exactly this.
3. **`attachShadow({ delegatesFocus: true })`** — works, but drags in Shadow DOM, which we're avoiding.

Labels work through `internals.labels`. Lexxy composes the accessible name from them:

```js
// [LEXXY — MIT, © 37signals LLC]  src/elements/editor.js
get #labelText() {
  return Array.from(this.internals.labels).map(label => label.textContent).join(" ")
}
```

and sets the wrapper's role to `presentation` so the wrapper doesn't shadow the inner control's `textbox` role:

```js
constructor() {
  super()
  this.internals = this.attachInternals()
  this.internals.role = "presentation"
}
```

**Clicking a `<label for>` does not automatically focus a form-associated custom element.** Trix's non-`ElementInternals` fallback had to hand-roll this with a document-level click listener; with `ElementInternals` the label association exists but focus delegation still requires either an inner focusable control or a `click` handler that calls `this.focus()`. Test it.

Also forward `aria-*` attributes from the outer tag to whatever inner element actually carries the role, or authors will set `aria-describedby` on the tag and it will do nothing:

```js
// [LEXXY — MIT, © 37signals LLC]  src/elements/editor.js
get #ariaAttributes() {
  return Array.from(this.attributes).filter(a => a.name.startsWith("aria-"))
}
```

### Three things that will surprise you

1. **Chrome does not show the native validation bubble for form-associated custom elements.** `setValidity` still blocks submission, `reportValidity()` still returns `false`, and the `invalid` event still fires — but the user may see nothing at all. **Render your own error text.** In Rails this means the usual `form.object.errors` inline rendering plus a client-side message near the control; do not treat the browser bubble as your only feedback path.
2. **Chrome does not autofill form-associated custom elements.** Anything that should participate in browser autofill (name, address, payment, one-time codes) must be a real `<input>`. Wrap one; don't replace it.
3. **There are no polyfills**, for `formAssociated` or for the `formdata` event, and the platform docs say they are "likely difficult or impossible to polyfill." Support is a floor, not a gradient.

### Browser support

`ElementInternals` and `formAssociated` are Baseline: Chrome 77, Firefox 98, **Safari 16.4 (March 2023)**. See [the full compatibility table](#browser-support-precisely) for the ARIA-reflection and `:state()` gaps.

Lexxy's `package.json` declares `"browserslist": ["baseline 2023", "not dead"]` and uses `static formAssociated = true` **unconditionally**. Trix, being older and shipping into more contexts, still runtime-switches:

```js
// [TRIX — MIT, © 37signals LLC]
static formAssociated = "ElementInternals" in window
```

with a whole `LegacyDelegate` class behind it that warns on every property and mirrors the value into a sibling `<input type="hidden">`. **Crosswire should follow Lexxy, not Trix: declare `formAssociated = true` unconditionally and document the 2023 baseline.** The dual-delegate design doubles the surface area of every component for browsers we don't support.

(If you ever *do* need a fallback, copy Trix's shape: one interface, two implementations, chosen once in the constructor — not `if` statements sprinkled through the element.)

---

## Interop patterns

### 1. Custom element publishes, Stimulus subscribes

The default. Events bubble, so the `data-action` can sit on any ancestor — usually the `<form>` or a wrapper — which means the controller doesn't need to be on the element itself and survives the element being re-rendered.

```erb
<div data-controller="composer"
     data-action="lexxy:change->composer#enableSubmit
                  lexxy:upload-start->composer#disableSubmit
                  lexxy:upload-end->composer#enableSubmit">
  <%= form.rich_text_area :body %>
  <%= form.submit %>
</div>
```

```js
export default class extends Controller {
  static targets = [ "submit" ]
  enableSubmit()  { this.submitTarget.disabled = false }
  disableSubmit() { this.submitTarget.disabled = true }
}
```

**Rule: a Tier-3 component never imports Stimulus and never knows a controller exists.**

### 2. Stimulus drives the element via properties and methods

The other direction. The controller holds a reference and calls methods — this is why Tier 3 needs a deliberate public API.

```js
export default class extends Controller {
  static targets = [ "editor" ]

  insertSignature() {
    this.editorTarget.value += "<p>— Jake</p>"   // property, not attribute
  }

  clear() {
    this.editorTarget.value = ""
    this.editorTarget.focus()
  }
}
```

Lexxy's own dummy app does exactly this (`lexxy_output_controller.js` reads `this.editorTarget.value` and `this.editorTarget.toString()`).

**Gotcha: a `data-*-target` may resolve before the element upgrades.** Stimulus's `connect()` can run before `customElements.define()` has been called (importmap load order) or before the browser has upgraded the node. If `this.editorTarget.value` is `undefined`, you're talking to an un-upgraded `HTMLElement`. Two fixes:

```js
// (a) wait for the definition
async connect() {
  await customElements.whenDefined("lexxy-editor")
  this.editorTarget.focus()
}

// (b) wait for the component's own ready event — preferred, because
//     "defined" ≠ "initialized"
// data-action="lexxy:initialize->composer#ready"
```

Lexxy publishes `lexxy:initialize` for precisely this reason, and Alchemy's toolbar solves the same ordering problem internally with a promise:

```js
// [LEXXY — MIT, © 37signals LLC]  src/elements/toolbar.js (abridged)
async #createEditorPromise() {
  this.editorPromise = new Promise((resolve) => { this.resolveEditorPromise = resolve })
  this.editorElement = await this.editorPromise
}

async getEditorElement() { return this.editorElement || await this.editorPromise }

setEditor(editorElement) {
  this.editorElement = editorElement
  /* …wire… */
  this.resolveEditorPromise(editorElement)
}
```

**Pattern worth stealing: a `ready` promise on every non-trivial element**, resolved at the end of initialization, so consumers can `await el.ready` regardless of when they arrive.

### 3. Attributes in, properties out

The rule that keeps server-rendering and morphing sane:

| Direction | Mechanism | Why |
|---|---|---|
| **Server → element** | **attributes** (`<x-rating value="4" max="5">`) | Only attributes exist in HTML. `observedAttributes` + `attributeChangedCallback` gives you a reactive channel. Morphing updates attributes. |
| **JS → element** | **properties** (`el.value = 4`) for anything not stringy or not worth reflecting; **attributes** for anything that should be visible/styleable/morphable | Properties can hold objects, Files, Maps |
| **Element → world** | **events** + **reflected attributes** | Never a callback property (`el.onchange = …` is unsubscribable and gets clobbered) |

Reflect a property to an attribute when: CSS should be able to select on it, the server should be able to render the same state, or a test/morph should be able to see it. Don't reflect when it's a large object, a File, or high-frequency (a per-keystroke value).

**Large payloads:** put JSON in a `data-` attribute, or better, in a `<script type="application/json">` child that the element reads and removes. A `<template>` child is the idiomatic way to hand an element markup (that's exactly what `<turbo-stream>` does).

**Never pass data via a global.** `window.Alchemy` exists in Alchemy for legacy reasons and their own code routes around it.

### 4. Element ↔ element composition

Parent finds children by tag; children find parent with `closest`. Both sides tolerate the other appearing later:

```js
// parent
get options() { return this.querySelectorAll("suggestion-option") }

// child
get selectElement() { return this.closest("suggestion-select") }
```

**Registration order matters when elements create each other.** Lexxy's registry carries the constraint as a comment:

```js
// [LEXXY — MIT, © 37signals LLC]  src/elements/index.js
const elements = {
  // Toolbar must be registered BEFORE Editor
  "lexxy-toolbar": Toolbar,
  …
  "lexxy-editor": Editor,
  // Prompt must be registered AFTER Editor
  "lexxy-prompt": Prompt,
  …
}
Object.entries(elements).forEach(([ name, element ]) => customElements.define(name, element))
```

Because the editor's `connectedCallback` *creates* a `<lexxy-toolbar>`, that tag must already be defined or it upgrades a beat late. If you find yourself needing this, prefer having the parent wait (`customElements.whenDefined`) over encoding an ordering rule — but know the rule exists.

### 5. Deferred definition so configuration can land first

Both Lexxy and Trix defer registration by a macrotask so that a `<script type="module">` in the page can configure globals before any element upgrades:

```js
// [LEXXY — MIT, © 37signals LLC]  src/index.js
// Pushing elements definition to after the current call stack to allow global
// configuration to take place first
setTimeout(defineElements, 0)
```

```js
// [TRIX — MIT, © 37signals LLC]  src/trix/trix.js
function start() {
  if (!customElements.get("trix-toolbar")) customElements.define("trix-toolbar", elements.TrixToolbarElement)
  if (!customElements.get("trix-editor"))  customElements.define("trix-editor",  elements.TrixEditorElement)
}
window.Trix = Trix
setTimeout(start, 0)
```

enabling:

```erb
<script type="module">
  import * as Lexxy from "lexxy"
  Lexxy.configure({ global: { attachmentTagName: "bc-attachment" } })
</script>
```

This is a genuinely load-bearing trick for a distributable component library, and it's invisible until you need it. Adopt it for any crosswire element that has global configuration.

### 6. The server-side seam: Turbo Stream custom actions

For "the server needs to command a live component", a custom Stream action beats a `replace`:

```js
Turbo.StreamActions.rating_set = function () {
  const [element] = this.targetElements
  element?.setAttribute("value", this.getAttribute("value"))
}
```

```rb
turbo_stream.action(:rating_set, dom_id(@review), value: @review.stars)
```

Alchemy uses this pattern precisely to avoid replacing DOM that a component is observing. See the verbatim comment in [the Alchemy section](#alchemycms--the-independent-replication).

---

## Turbo interactions & gotchas

Ordered by how likely they are to bite.

### 1. Double registration — `NotSupportedError` on navigation

`customElements.define()` throws if the name is taken. This happens when a script is evaluated twice: a `<script>` inside a page body that Turbo Drive re-renders, an importmap module re-imported through a different specifier, or two copies of a package in the bundle. The error kills the rest of the script, so the symptom is usually "everything after this stopped working after clicking one link".

**Always guard.** Turbo's own form:

```js
if (customElements.get("turbo-frame") === undefined) {
  customElements.define("turbo-frame", FrameElement)
}
```

`turbo-rails` does the same for its own element:

```js
// [TURBO-RAILS — MIT, © 37signals LLC]  app/javascript/turbo/cable_stream_source_element.js
if (customElements.get("turbo-cable-stream-source") === undefined) {
  customElements.define("turbo-cable-stream-source", TurboCableStreamSourceElement)
}
```

Trix's:

```js
if (!customElements.get("trix-editor")) customElements.define("trix-editor", TrixEditorElement)
```

**This guard exists because it happened to Turbo.** [hotwired/turbo#104 — *"the name 'turbo-frame' has already been used with this registry"*](https://github.com/hotwired/turbo/issues/104) is the canonical bug report; DHH's diagnosis in the thread:

> This happens when Turbo is being loaded twice. Are you sure you didn't also include the `turbo_include_tags` call? That call is not to be used if you're using webpack.

Duplicate gems, duplicate pack tags, and two importmap pins to one file are all the same failure. Note that **Lexxy does *not* guard** — its `defineElements()` loops over the registry and calls `define` unconditionally — which is a genuine inconsistency in the ecosystem's "best practice", and a reason for crosswire to guard rather than copy Lexxy here.

Second defence: **put registration in a module imported from `application.js`, never in a page-level `<script>`.** ES modules are evaluated once per specifier; page scripts are not. Third defence: for importmap apps, make sure only one specifier maps to the file — `pin "elements/rating", to: "elements/rating_element.js"` plus a relative import of the same file elsewhere counts as two modules.

### 2. Upgrade timing — a parsed element is not yet your class

The single most important line in Turbo's source on this subject:

```js
// [TURBO — MIT, © 37signals LLC]  src/core/morphing.js
function areFramesCompatibleForRefreshing(currentFrame, newFrame) {
  // newFrame cannot yet be an instance of FrameElement because custom
  // elements don't get initialized until they're attached to the DOM, so
  // test its Element#nodeName instead
  return newFrame instanceof Element && newFrame.nodeName === "TURBO-FRAME" && …
}
```

Consequences:

- Elements inside a `DocumentFragment`, a `<template>`'s content, a `DOMParser` document, or a Turbo *snapshot* are **not upgraded**. `instanceof MyElement` is `false`; your getters don't exist. Test `nodeName` / `localName` / `matches("x-rating")` instead.
- Anything a Turbo Stream inserts upgrades on insertion, not before. `beforeNodeAdded` callbacks see raw elements.
- Because upgrade happens on attach, **`connectedCallback` runs before the element's children are necessarily parsed** if the element is being parsed from HTML by the streaming parser. If you must read your own children at connect, defer one frame (`requestAnimationFrame`) — which is exactly what Lexxy does:
  ```js
  requestAnimationFrame(() => { this.#mountRoot(); this.#handleAutofocus(); this.#dispatchInitialize() })
  ```

### 3. `connectedCallback` fires more than once, and out of order

Moving an element in the DOM fires `disconnectedCallback` then `connectedCallback`. Turbo Drive rendering, Frame updates, morphing, and `<dialog>` reparenting all move nodes. So:

- **`connectedCallback` must be idempotent.** Guard creation: `this.editorContentElement ||= this.#createEditorContentElement()`, `this.id ||= generateDomId(…)`, `renderPromise ??=`.
- **`disconnectedCallback` must be complete.** Every listener, timer, `ResizeObserver`, `MutationObserver`, `EventSource`, and third-party instance must go. A leaked listener on `document` is a memory leak *and* a ghost that fires for the next instance.

Lexxy formalizes this with two structures worth lifting wholesale:

```js
// [LEXXY — MIT, © 37signals LLC]  src/helpers/listener_helper.js
// Register an event listener with a return function to deregister the listener. Both the element and
// the listener are WeakRefs so neither is pinned in memory by the deregister function.
export function registerEventListener(element, type, listener, options) {
  element.addEventListener(type, listener, options)
  const elementRef  = new WeakRef(element)
  const listenerRef = new WeakRef(listener)

  return function deregisterListener() {
    const listener = listenerRef.deref()
    if (listener) elementRef.deref()?.removeEventListener(type, listener, options)
  }
}

export class ListenerBin {
  #listeners = []
  track(...listeners) { this.#listeners.push(...listeners) }
  dispose() {
    while (this.#listeners.length) this.#listeners.pop()()
  }
}
```

plus a `#disposables` array of anything with a `dispose()`:

```js
// [LEXXY — MIT, © 37signals LLC]  src/elements/editor.js
#dispose() {
  while (this.#disposables.length) this.#disposables.pop().dispose()
}
```

`WeakRef` in the deregistration closure is the subtle part: without it, the teardown function itself keeps the element alive if the bin outlives the element.

### 4. Turbo Drive page caching — snapshot the *clean* state

Before Turbo caches a page it clones the current DOM. Anything your element created — an editor surface, a popover appended to your subtree, a third-party widget's DOM — gets serialized into the cache and restored as **dead markup** on back/forward, on top of which your `connectedCallback` will then build a second copy.

Both fixes are in Lexxy:

```js
// [LEXXY — MIT, © 37signals LLC]  src/elements/editor.js
#resetBeforeTurboCaches() {
  this.#listeners.track(
    registerEventListener(document, "turbo:before-cache", this.#handleTurboBeforeCache)
  )
}

#handleTurboBeforeCache = (event) => {
  if (!this.closest("[data-turbo-permanent]")) this.#reset()
}
```

```js
// [LEXXY — MIT, © 37signals LLC]  src/elements/prompt.js
// The popover is appended to the <lexxy-editor> subtree, so Turbo serializes it
// into the page cache. Removing it before caching prevents an orphaned, unmanaged
// popover from being restored on history back/forward.
#removePopoverBeforeTurboCaches() {
  this.#globalListeners.track(
    registerEventListener(document, "turbo:before-cache", () => this.#removePopover())
  )
}
```

**Rule: every Tier-3 element that generates DOM listens for `turbo:before-cache` and tears itself back down to its server-rendered shape.** And it checks `data-turbo-permanent` first, because a permanent element is exempted from the cache dance and must not be reset.

**Also skip expensive work while a preview is on screen.** Turbo sets `data-turbo-preview` on `<html>` while showing a cached snapshot. Campfire's one-liner:

```js
// [CAMPFIRE — MIT, © 37signals LLC]  app/javascript/helpers/turbo_helpers.js
export function pageIsTurboPreview() {
  return document.documentElement.hasAttribute("data-turbo-preview")
}
```

Turbo's own `FrameElement` does the same via `get isPreview()`.

### 5. Morphing — the `connected` attribute trick

Morphing (page refreshes, `<turbo-frame refresh="morph">`) **does not** re-run `connectedCallback`, because the element node is preserved. Idiomorph updates its attributes and morphs its children — including children *your element created*, which the server's HTML doesn't contain, so they get deleted out from under you while the element believes it's still initialized.

Trix invented, and Lexxy copied, an elegant fix that costs three lines: **set a boolean attribute at the end of `connectedCallback`, observe it, and reconnect if it disappears.** The server never renders `connected`, so any morph strips it — which is exactly the signal that the DOM was rewritten.

```js
// [TRIX — MIT, © 37signals LLC]  src/trix/elements/trix_editor_element.js
static observedAttributes = [ "connected" ]

attributeChangedCallback(name, oldValue, newValue) {
  if (name === "connected" && this.isConnected && oldValue != null && oldValue !== newValue) {
    requestAnimationFrame(() => this.reconnect())
  }
}

connectedCallback() {
  /* …build… */
  this.toggleAttribute("connected", true)
}

disconnectedCallback() {
  /* …tear down… */
  this.toggleAttribute("connected", false)
}

reconnect() {
  this.removeInternalToolbar()
  this.disconnectedCallback()
  this.connectedCallback()
}
```

Lexxy's is identical in shape, with the value preserved across the cycle:

```js
// [LEXXY — MIT, © 37signals LLC]  src/elements/editor.js
disconnectedCallback() {
  this.#previousInternalFormValue = null
  this.valueBeforeDisconnect = this.value       // ← carry the value over the rebuild
  this.#clearCachedValues()
  this.#reset()                                 // Prevent hangs with Safari when morphing
}

connectedChangedCallback(oldValue, newValue) {
  if (this.isConnected && oldValue != null && oldValue !== newValue) {
    requestAnimationFrame(() => this.#reconnect())
  }
}

#reconnect() {
  this.disconnectedCallback()
  this.valueBeforeDisconnect = null
  this.connectedCallback()
}

#reset() {
  this.#dispose()
  this.#resetValidity()
  this.#uploadRequests?.clear()
  this.editorContentElement?.remove()
  this.editorContentElement = null

  // Prevents issues with turbo morphing receiving an empty <lexxy-editor> which wipes
  // out the DOM for the tools, and the old toolbar reference will cause issues
  this.toolbar = null
}
```

Note the `requestAnimationFrame` — reconnecting synchronously inside `attributeChangedCallback` re-enters while the morph is still running.

Lexxy also uses a small dispatch table so each observed attribute gets its own handler instead of an `if` ladder:

```js
// [LEXXY — MIT, © 37signals LLC]  src/elements/editor.js
attributeChangedCallback(name, oldValue, newValue) {
  if (typeof this[`${name}ChangedCallback`] === "function") {
    this[`${name}ChangedCallback`](oldValue, newValue)
  }
}
```

**The alternative, when reconnecting is too expensive: opt out of the morph.**

```js
document.addEventListener("turbo:before-morph-element", (event) => {
  if (event.target.localName === "x-rating") event.preventDefault()
})
```

Turbo honours `preventDefault()` on `turbo:before-morph-element` and skips the subtree entirely, and it unconditionally skips anything with `data-turbo-permanent`:

```js
// [TURBO — MIT, © 37signals LLC]  src/core/morphing.js
beforeNodeMorphed = (currentElement, newElement) => {
  if (currentElement instanceof Element) {
    if (!currentElement.hasAttribute("data-turbo-permanent") && this.#beforeNodeMorphed(currentElement, newElement)) {
      const event = dispatch("turbo:before-morph-element", {
        cancelable: true, target: currentElement, detail: { currentElement, newElement }
      })
      return !event.defaultPrevented
    } else {
      return false
    }
  }
}
```

Choose per component: **reconnect** if rebuilding is cheap and the server's HTML is authoritative; **opt out** if the element holds unsaved user state (a half-typed message, a scroll position, an open dropdown).

### 6. `data-controller` and `data-action` are a stored-content attack surface

The strongest security argument in the corpus, and it's Stimulus-specific. Lexxy's sanitizer forbids Stimulus attributes **unconditionally**, in both the DOMPurify config and a hook, because user-authored rich text can otherwise wire arbitrary controllers into a *viewer's* session:

```js
// [LEXXY — MIT, © 37signals LLC]  src/config/dom_purify.js
const FORBIDDEN_STIMULUS_ATTRIBUTES = [ "data-controller", "data-action" ]

// Stimulus behavior attributes must never survive sanitization, whatever an
// extension's allowedElements declares. FORBID_ATTR alone isn't enough: in
// DOMPurify 3.x the functional ADD_ATTR — which Lexxy builds from the public
// allowedElements API — is evaluated ahead of FORBID_ATTR, so an extension that
// listed one of these on a tag would otherwise reinstate it.
function stimulusAttributeFilterHook(_currentNode, hookEvent) {
  if (FORBIDDEN_STIMULUS_ATTRIBUTES.includes(hookEvent.attrName)) hookEvent.keepAttr = false
}
DOMPurify.addHook("uponSanitizeAttribute", stimulusAttributeFilterHook)
```

```rb
# [LEXXY — MIT, © 37signals LLC]  test/system/stimulus_sanitization_test.rb (comment)
# an attachment's content= can smuggle Stimulus behavior attributes
# (data-controller/data-action). On hydration Lexxy renders that stored HTML
# into the live editor DOM … so the sanitizer must strip those attributes there —
# otherwise stored content wires up arbitrary controllers/actions in the viewer's
# editing session.
```

**Generalize: any allow-list sanitizer in a Rails app that renders user HTML must forbid `data-controller`, `data-action`, `data-*-target`, and `data-*-value`.** Note that a registered custom element *tag* is the equivalent hazard for Tier 3 — if you allow-list `<x-rating>` in Action Text, stored content can instantiate one. Tier 3's exposure is narrower (you allow-list tags explicitly, and there's no way to bind arbitrary behaviour to an existing tag), but it is not zero.

### 7. Importmap vs bundling

| | Importmap | Bundled (`jsbundling` / propshaft + esbuild/rollup) |
|---|---|---|
| Custom elements work? | yes | yes |
| Registration timing | modules load in parallel; a page can render before `customElements.define` runs → elements upgrade late, flash unstyled | one bundle, one evaluation, deterministic order |
| Double-registration risk | **higher** — two pins to the same file are two modules | low |
| npm deps (Lexical, Sortable, Tom Select) | painful; needs `pin` per transitive dep or a CDN | trivial |
| Distributing a component library | consumers must add pins | consumers `import` |

**Practical consequence:** upgrade lateness is real on importmap. Mitigate with `<link rel="modulepreload">` (which `importmap-rails` emits for preloaded pins), and with CSS that hides an un-upgraded element — the `:defined` pseudo-class is the intended tool:

```css
x-rating:not(:defined) { visibility: hidden; }
x-rating:not(:defined)::after { content: ""; display: block; block-size: 2rem; }  /* reserve space */
```

Note that `:defined` means "the tag name is registered", **not** "this instance has initialized". For the latter, style on your own `[connected]` attribute — a second, better reason to have it.

Any Tier-3 component with real npm dependencies wants bundling. Lexxy, Trix and Alchemy all use Rollup and ship a built artifact; Lexxy ships *both* a gem (with `app/assets/javascript/lexxy.js` prebuilt) and an npm package.

### 8. ViewComponent / Phlex — does it change the calculus?

No, and that's the point. All three server-side rendering strategies emit the same HTML:

```rb
# helper
def rating_field_tag(name, value: nil, **) = tag.x_rating(name:, value:, **)

# ViewComponent template
<x-rating name="<%= @name %>" value="<%= @value %>"><%= content %></x-rating>

# Phlex
def view_template = x_rating(name: @name, value: @value) { yield }
```

The component *is* the tag; the server-side object is just a nicer way to write it. Two real differences worth noting:

- **ViewComponent/Phlex give the Tier-3 component a natural home for its slots and defaults**, which a bare helper does awkwardly. `<lexxy-editor>` taking a block of `<lexxy-prompt>` children is exactly a ViewComponent slot in disguise.
- **A ViewComponent's own `*_controller.js` sidecar convention biases you toward Tier 1.** Don't let file-layout convenience make the tier decision. A ViewComponent whose sidecar is 400 lines should be a ViewComponent that renders a custom element.

Crosswire's helper↔component pairing works identically with all three; document the plain-helper form as canonical and show the ViewComponent/Phlex equivalents.

### 9. Miscellaneous sharp edges

- **`disconnectedCallback` is not guaranteed** when the page unloads or the tab closes. Don't put "save my draft" there alone.
- **`attributeChangedCallback` fires before `connectedCallback`** for attributes present in the parsed HTML. Guard with `if (!this.isConnected) return` or make handlers safe to run early. Lexxy guards: `requiredChangedCallback() { if (this.isConnected) this.#requestValidityRefresh() }`.
- **The constructor may not touch attributes or children.** Spec rule; it throws in the "upgrade an existing element" path. Everything DOM-touching goes in `connectedCallback`. `attachInternals()` in the constructor is fine (and must happen there — it throws on the second call).
- **Safari + morphing + `contenteditable` hangs.** Lexxy's `disconnectedCallback` calls `#reset()` with the comment *"Prevent hangs with Safari when morphing"*. If you host a `contenteditable`, remove it on disconnect.
- **Don't create DOM outside your own subtree.** Trix inserts its toolbar and hidden input as *siblings*; Lexxy makes the toolbar a *child*. Siblings get orphaned by morphing and confuse `data-turbo-permanent`.
- **Custom elements in `<table>`, `<select>`, `<ul>` contexts** get hoisted by the HTML parser. `<my-row>` inside `<tbody>` is legal but `<tbody><my-thing>` may be relocated. Wrap-inside, not wrap-around, in table markup.

---

## Testing each tier

Each tier has a different natural test, and getting this right is most of the value of the split.

### Tier 2 — unit tests, no browser

Plain classes are testable with `new`. This is the single largest argument for extracting them.

```js
// vitest / jsdom
import TypingTracker from "models/typing_tracker"

test("purges typists after the timeout", () => {
  vi.useFakeTimers()
  const seen = []
  const tracker = new TypingTracker(names => seen.push(names))
  tracker.add("Ann")
  vi.advanceTimersByTime(6000)
  expect(seen.at(-1)).toBeNull()
  tracker.close()
})
```

Lexxy: `yarn test` → Vitest over `test/`, described as *"fast JS unit tests for helpers and pure logic"*. Alchemy: `pnpm run test` → Vitest, jsdom, with a `spec/javascript/**` root and path aliases mirroring the app's importmap:

```js
// [ALCHEMY — BSD-3-Clause]  vitest.config.js (abridged)
export default defineConfig({
  test: { environment: "jsdom", globals: true, root: "spec/javascript/alchemy_admin/", setupFiles: ["setup.js"] },
  resolve: {
    alias: {
      alchemy_admin: path.resolve(__dirname, "app/javascript/alchemy_admin"),
      "@hotwired/turbo-rails": path.resolve(__dirname, "spec/javascript/alchemy_admin/turbo_rails_stub.js")
    }
  }
})
```

Note the **Turbo stub alias** — Tier-2 code that imports Turbo gets a fake in unit tests rather than the real thing.

### Tier 3 — jsdom for structure, real browser for behaviour

jsdom supports `customElements` well enough for the structural half: define, set attributes, assert on the rendered subtree and on properties. Alchemy tests all 30-odd of its components this way with a three-line helper:

```js
// [ALCHEMY — BSD-3-Clause]  spec/javascript/alchemy_admin/components/component.helper.js
export const renderComponent = (name, html) => {
  document.body.innerHTML = html
  return document.querySelector(`${name}, [is="${name}"]`)
}
```

```js
// [ALCHEMY — BSD-3-Clause]  spec/javascript/alchemy_admin/components/char_counter.spec.js (abridged)
import "alchemy_admin/components/char_counter"
import { renderComponent } from "./component.helper"

describe("alchemy-char-counter", () => {
  let component

  beforeEach(() => {
    component = renderComponent("alchemy-char-counter", `
      <alchemy-char-counter><input type="text"></alchemy-char-counter>
    `)
  })

  it("creates the typed-character indicator", () => {
    expect(component.querySelector("small").textContent).toEqual("0 of 60 chars")
  })

  it("defaults to 60 max chars", () => {
    expect(component.maxChars).toEqual(60)
  })
})
```

Setting `document.body.innerHTML` triggers upgrade synchronously in jsdom, so the element is live on the next line. Two caveats: **jsdom does not implement `ElementInternals` form association** (no `setFormValue`, no `formResetCallback` wiring, no `internals.labels`) — form-associated behaviour must be tested in a real browser; and it has no layout, so anything geometric is untestable there.

For behaviour, Lexxy uses **Playwright against real Chromium/Firefox/WebKit**, driving the element through its public API and asserting on dispatched events. This is the model to copy:

```js
// [LEXXY — MIT, © 37signals LLC]  test/browser/tests/events.test.js (abridged)
test("dispatch lexxy:focus and lexxy:blur on focus gain and loss", async ({ page, editor }) => {
  await page.goto("/")
  await editor.waitForConnected()

  await editor.focus()
  await expect(page.locator("[data-event='lexxy:focus']")).toBeVisible()

  await page.locator("input[name='post[title]']").click()
  await expect(page.locator("[data-event='lexxy:blur']")).toBeVisible()
})

test("no lexxy:change event on initial load", async ({ page, editor }) => {
  await page.goto("/")
  await editor.waitForConnected()
  await expect(page.locator("[data-event='lexxy:change']")).toHaveCount(0)
})
```

Three techniques here:

1. **A page-object fixture per element** (`EditorHandle`), injected via `test.extend`, with `waitForConnected()`, `focus()`, `flush()`. Assertions read like the component's API, not like CSS selectors.
2. **`waitForConnected()`** — waits on the `[connected]` attribute. This is a *third* use for that attribute (morph detection, `:defined` styling, test synchronization) and on its own justifies adding it to every element.
3. **Events are asserted by having the page log them into the DOM.** The fixture page carries a Stimulus controller that appends `<div data-event="lexxy:change">` per event, and the test asserts on locators. No `page.evaluate` bridge, no serialization problem, and negative assertions (`toHaveCount(0)`) work naturally.

### Tier 1 — don't unit test it; system test it

A Stimulus controller under the decision rule is 20 lines of forwarding. Testing it in isolation means mounting a Stimulus application in jsdom to assert that a click called a method — high ceremony, near-zero yield. Test it through the feature, in a Capybara system test.

None of the five codebases surveyed unit-tests its Stimulus controllers.

### The round-trip test only Rails can do

Lexxy's third suite is Capybara system tests, reserved for *"anything that has to survive the editor → save → render → re-edit round-trip"*:

```rb
# [LEXXY — MIT, © 37signals LLC]  test/system/form_test.rb (abridged)
test "resets editor to initial state when empty" do
  visit posts_path
  click_on "New post"

  find_editor.send "This"
  click_on "Reset"                    # ← exercises formResetCallback
  find_editor.send "That"

  click_on "Create Post"
  click_on "Edit this post"
  wait_for_editor

  assert_editor_html "<p>That</p>"
end
```

and their AGENTS.md makes it a rule:

```
[LEXXY — MIT, © 37signals LLC]  AGENTS.md

When changing how Lexxy formats or serializes content …, always verify the new
format survives the full Action Text round-trip: editor → save → render →
re-edit. The editor's HTML passes through DOMPurify (client), Loofah (server),
and highlightCode() (rendered view) — any of these can strip markup that the
editor preserved.
```

**For crosswire: every form-associated element needs one system test that submits it, reloads, and asserts the value round-tripped** — plus `<button type="reset">`, plus a `required` submit that's blocked. Those four assertions catch essentially every `ElementInternals` mistake.

### Test matrix

| | Tier 1 | Tier 2 | Tier 3 |
|---|---|---|---|
| Vitest + jsdom | ✗ | **✓ primary** | ✓ structure/attrs/properties |
| Playwright | ✗ | rarely | **✓ primary** for behaviour, focus, keyboard, events |
| Capybara system | **✓ primary** (via the feature) | ✗ | ✓ form round-trip, Turbo nav/morph/cache |

---

## Recommendation for crosswire

### The stance

**Crosswire teaches three tiers and says so on the first page.** The dominant framing in the Hotwire literature — "Turbo for pages, Stimulus for sprinkles" — is a two-tier model that every serious production codebase we read has outgrown. Publishing the missing third tier, with the decision rule, is the single most differentiated thing this repo can do. Nobody else has written it down.

Positioning line: *Stimulus is the wiring tier, not the component tier.*

The same line was drawn independently in [hotwired/stimulus#581](https://github.com/hotwired/stimulus/issues/581) in 2023 — *"Stimulus is a useful way to introduce generic behavior 'mixins' to existing server-rendered HTML, but when it wades into 'this is a widget' territory…"* — and then nobody followed through. Crosswire should credit it and finish the job.

**And be honest about the cost.** Tier 3 is more work than Tier 1: `observedAttributes`, reflecting property pairs, idempotent connect, complete teardown, `ElementInternals` plumbing. Vladimir Dementyev's 2021 verdict still holds — *"requires a good knowledge of both JavaScript and the latest browser APIs, which is definitely a trade-off to consider."* Stimulus's real advantage was never technical; it was that a Rails developer could learn it in an afternoon. **Crosswire's job is to make Tier 3 as learnable as Tier 1 by shipping the scaffold, the checklist, and the gotchas — not to shame people out of controllers.** If the docs make a reader feel their 30-line controller was a mistake, they're wrong.

### The default

For a new piece of behaviour, in order: **server → Stimulus controller → extract a plain class → promote to a custom element.** Most things stop at step 1 or 2. The two triggers that jump straight to Tier 3 are (a) it needs a `name` in a form, (b) something outside it needs to command or observe it.

### Which crosswire components live where

**Tier 1 — Stimulus controllers.** Ship these as copy-pasteable recipes with an ERB helper each. This is the bulk of the library by count.

> `clipboard`, `auto_submit`, `toggle_class`, `element_removal`, `hotkey`, `local_time`, `web_share`, `sound`, `dependent_checkbox`, `touch`, `maintain_scroll`, `drop_target` (the wiring half), `dialog` (opening a native `<dialog>`), `popover` (positioning a native `popover`), `autosave` (the trigger), `form` (submit state), scroll/intersection observers, focus traps, "confirm before leaving", "submit on cmd+enter".

**Tier 2 — plain ES classes.** Ship a `models/` and `helpers/` convention plus a handful of primitives, and — more importantly — teach the extraction. Every Tier-1 recipe above ~40 lines gets an "extract the class" variant.

> `debounce` / `throttle` / `nextFrame` timing helpers, a `ListenerBin`, a `request.js`-style fetch wrapper, `Countdown`, `Autosaver`, `Paginator`, `ScrollManager`, `Uploader` (Active Storage direct upload wrapper), `Poller`, a small state machine helper, `LocalTimeFormatter`.

**Tier 3 — custom elements.** A small, deliberate set. Every one is form-associated or has real consumers. Each ships as: the element, its ERB helper, its stylesheet, its event catalogue, and a system test proving the form round-trip.

> **Form-associated:** `<x-tags>` (token input → `name[]`), `<x-rating>`, `<x-combobox>` (remote-source select), `<x-daterange>`, `<x-money>` (masked currency), `<x-sortable-list>` (submits an order), `<x-dropzone>` (files + progress → signed IDs), `<x-richtext>` (thin wrapper over Lexxy/Trix, or a documented "use Lexxy" pointer).
>
> **Non-form, but owns a subtree with consumers:** `<x-autocomplete>` + `<x-option>` (the Campfire shape), `<x-chart>`, `<x-map>`, `<x-clock>` (live-updating, morph-safe), `<x-stream-source>`-style subscriptions, `<x-lightbox>`.

Anything not on those lists is Tier 1 until proven otherwise.

### House rules for crosswire's Tier-3 elements

Non-negotiable, so every component in the library looks the same:

1. **Tag prefix.** Pick one and never deviate. Recommend `<cw-…>` for library-owned elements, and teach app authors to use their own app prefix. Never a generic name that might collide (`<tabs>`, `<modal>`).
2. **Light DOM only.** No `attachShadow` for encapsulation. The server renders the children; the app's stylesheet styles them; morphing works. (Revisit only if a component ships to third-party pages.)
3. **Attributes in, properties out, events as the contract.** Reflecting property pairs for everything the server can render. `bubbles: true` always. Namespace `cw-rating:change` style — colon separator, matching `turbo:*` and `lexxy:*`.
4. **`static formAssociated = true` unconditionally** for anything with a value. Declare "Baseline 2023" support and don't write fallbacks.
5. **Guarded registration**, in one `elements/index.js`, imported once from `application.js`.
6. **A `connected` attribute** set at the end of `connectedCallback`, in `observedAttributes`, with the reconnect-on-removal handler. Gives us morph-resilience, `:defined`-independent CSS, and a test synchronization point, for three lines.
7. **A `ListenerBin` + `#disposables`**, and a `disconnectedCallback` that empties both.
8. **A `turbo:before-cache` listener** that returns generated DOM to its server-rendered shape — unless inside `[data-turbo-permanent]`.
9. **The element is a container.** Focusable/editable surfaces go *inside*, with `aria-*` and `tabindex` forwarded in and `internals.role = "presentation"` on the wrapper.
10. **A `ready` promise** on any element with async initialization, plus a `component:initialize` event.
11. **Cancelable events for every policy decision**, with the component implementing its own default through the same hook.
12. **No Tier-3 element imports Stimulus. Ever.**
13. **Render your own validation message.** Chrome shows no bubble for form-associated custom elements. Every crosswire form control ships with an error-display recipe (server-rendered inline errors plus a client-side message slot), never "the browser will tell them".
14. **Wrap a real `<input>` for anything autofillable.** Name, address, payment, OTP. Chrome won't autofill a custom element.

### What crosswire should ship as documents

- `docs/three-tiers.md` — this note's decision rule, condensed to one page with the escalation table.
- `docs/custom-elements.md` — the house rules above, as a checklist, plus the form-associated recipe verbatim.
- `docs/turbo-and-components.md` — the gotchas section: registration, upgrade timing, caching, morphing, the `connected` attribute.
- `docs/security.md` — sanitizers must forbid `data-controller` / `data-action` in user content. This is a genuinely under-published finding.
- A `templates/element.js` scaffold implementing rules 4–10 so a new Tier-3 component starts correct.

---

## Open questions

1. **Where exactly is the Tier-1 → Tier-3 line for *small* behaviours?** Alchemy makes `auto_submit` a custom element; 37signals makes it a Stimulus controller. Both ship. Our decision rule says Tier 1 (decorate, don't wrap), which matches Jared White's "mixin vs widget" split — but KonoMaxi in the same thread splits by *span* instead ("a controller can overarch huge sections of my pages"), and that's also defensible. State ours as a preference with the reasoning, not as a law.

1b. **Nobody has written this down, which is either an opportunity or a warning.** No Evil Martians article, no betterstimulus page, no hotwire.io article, no DHH post, no Alchemy ADR — exactly one GitHub thread in Stimulus's entire history. Crosswire would be publishing a synthesis from code, not summarizing a consensus. That's the differentiator, but it also means we should ship the decision rule with its evidence attached and an explicit "here's where practitioners disagree" section, rather than asserting it as received wisdom.

2. **Should crosswire ship its Tier-3 elements as an npm package, a gem with prebuilt assets, or copy-paste recipes?** Lexxy does the first two; crosswire's stated identity is the third. Copy-paste is the honest answer for a recipe repo, but a form-associated element with 200 lines of `ElementInternals` boilerplate is a poor copy-paste. Possibly: recipes for Tier 1/2, a real package for Tier 3.

3. **Does anything justify Shadow DOM in a Rails app?** Zero of five codebases use it, and the one public thread on the subject agrees (*"if you introduce shadow DOM stuff falls apart"* — stimulus#581). The theoretical case (a component embedded in a page whose CSS you don't control) doesn't arise in a first-party Rails app. Crosswire should say "no, light DOM" in one paragraph. **Resolved enough to act on; leaving open only in case a crosswire component ever ships to third-party pages.**

4. **Declarative Shadow DOM + streaming.** If crosswire ever wants server-rendered encapsulated components, DSD is the mechanism and it interacts badly with Idiomorph. Not researched here.

5. **`CustomStateSet` / `:state()` for styling.** `internals.states.add("loading")` → `x-thing:state(loading)` can't collide with app CSS and can't be clobbered by a morph — strictly better than toggling classes on paper. Support is Chrome 90 / Firefox 126 / **Safari 17.4**, a year newer than the `formAssociated` baseline. None of the five codebases use it; they all toggle attributes or classes. Is that conservatism, the newer baseline, or a real problem? Untested. Note the tension with house rule 6: state in `internals.states` is *invisible to the server and to morphing*, which is a feature for transient UI state and a bug for anything the server should render.

6. **Element upgrade + Turbo Drive: is there a measurable FOUC?** The `:defined` mitigation is theory here. Needs a real measurement on an importmap app before we recommend the CSS.

7. **`formStateRestoreCallback` and Turbo's history restore.** The bfcache path is documented; whether it fires on a Turbo Drive restoration visit (which is a fresh DOM, not a bfcache restore) is not — probably not, meaning `valueBeforeDisconnect`-style manual preservation is required. Lexxy implements the manual path, which is suggestive.

8. **Hotwire Native.** Lexxy ships a `NativeAdapter` alongside its `BrowserAdapter` precisely so a native shell can drive the editor's toolbar. That adapter seam — an element with a swappable presentation adapter — may be a fourth pattern crosswire should document. Not investigated here.

9. **Does the `connected`-attribute reconnect trick have a failure mode under `<turbo-frame refresh="morph">`?** Both Trix and Lexxy defer with `requestAnimationFrame`, which suggests they hit re-entrancy. Worth stress-testing before we recommend it as a house rule.
