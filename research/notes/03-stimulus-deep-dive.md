# Stimulus — Deep Technical Reference

> Research note for **crosswire**. Compiled 2026-08-15.
> Bias of this document: **generic, reusable, composable controllers**. Every section is written
> to answer "how does this feature help one controller serve many features?"
>
> Primary sources are linked inline. Code marked `[SOURCE]` was read directly from the
> Stimulus/stimulus-use/stimulus-rails repositories rather than from prose docs.

---

## Table of Contents

1. [Orientation: versions, currency, and what "current" means in 2026](#1-orientation)
2. [Anatomy: identifiers, filenames, registration, loading](#2-anatomy)
3. [Lifecycle: exact firing order and the subtle rules](#3-lifecycle)
4. [Targets](#4-targets)
5. [Values](#5-values)
6. [CSS Classes](#6-css-classes)
7. [Actions](#7-actions)
8. [Outlets](#8-outlets)
9. [**Composition Patterns Catalog**](#9-composition-patterns-catalog) ← the star
10. [stimulus-use: the mixin masterclass](#10-stimulus-use)
11. [Prior art: controller libraries and opinionated writing](#11-prior-art)
12. [Real-world evidence: 37signals Writebook & Campfire](#12-real-world-37signals)
13. [**Generic Controller Vocabulary — candidates for our library**](#13-generic-controller-vocabulary)
14. [Stimulus + Turbo: frames, streams, caching, morphing](#14-stimulus--turbo)
15. [Testing Stimulus controllers](#15-testing)
16. [TypeScript](#16-typescript)
17. [**Anti-patterns**](#17-anti-patterns)
18. [**Gotchas**](#18-gotchas)
19. [**Open Questions**](#19-open-questions)
20. [Source index](#20-source-index)

---

<a name="1-orientation"></a>
## 1. Orientation: versions, currency, and what "current" means in 2026

| Package | Latest | Released | Note |
|---|---|---|---|
| `@hotwired/stimulus` | **3.2.2** | **2023-08-07** | No release in 3 years. Stable/frozen, not abandoned — `main` still gets dependency bumps (last commit 2026-07-25). |
| `stimulus-rails` (gem) | 1.3.4 | 2024-08 | |
| `stimulus-use` | **0.53.0** | **2026-06-30** | Actively maintained. |
| `@hotwired/turbo` / `turbo-rails` | 8.0.23 | 2026-01-29 | Morphing era. |
| `tailwindcss-stimulus-components` | 6.1.4 | 2026-06-03 | Maintained. |
| `@hotwired/stimulus-webpack-helpers` | 1.0.1 | 2021-09 | **Legacy.** Webpacker is dead; the handbook still gives it a whole section. |
| `el-transition` | 0.0.7 | 2020-09 | Effectively unmaintained. |

**Practical read:** the *API surface* of Stimulus has been stable since Outlets landed in **3.2.0 (Nov 2022)**. That is
good news for a library of reusable controllers — nothing you build against 3.2 is going to be churned.
The *ecosystem* around it (Turbo morphing especially) has moved a lot, and most blog advice you'll find
predates it. Two hard staleness lines to apply when reading anything:

- **Pre-2022-11 (Stimulus 3.2)** → predates **Outlets**. Any "how do controllers talk to each other"
  post from before this is proposing workarounds for a solved problem.
- **Pre-2024-02 (Turbo 8)** → predates **morphing**. Any advice about `turbo:before-cache` teardown, or
  that assumes `connect()`/`disconnect()` bracket every server render, is now only half true.

### The philosophy, in the authors' words

From [The Origin of Stimulus](https://stimulus.hotwired.dev/handbook/origin) (DHH):

> "We write a lot of JavaScript at Basecamp, but we don't use it to create 'JavaScript applications' in
> the contemporary sense. All our applications have server-side rendered HTML at their core, then add
> **sprinkles of JavaScript to make them sparkle**."

The reuse motivation is stated explicitly as the *founding* problem:

> "While it was easy to add new code like this, it wasn't a comprehensive solution, and we had too many
> in-house styles and patterns coexisting. **That made it hard to reuse code, and it made it hard for new
> developers to learn a consistent approach.**"

The state-in-the-DOM argument, which is what makes controllers reusable and source-agnostic:

> "Most frameworks have ways of maintaining state within JavaScript objects, and then render HTML based on
> that state. **Stimulus is the exact opposite. State is stored in the HTML, so that controllers can be
> discarded between page changes, but still reinitialize as they were when the cached HTML appears again.**"

And from [Introduction](https://stimulus.hotwired.dev/handbook/introduction) — the thesis of this whole document:

> "Stimulus's conventions naturally encourage you to group related code by name. In turn, **Stimulus helps
> you build small, reusable controllers**, giving you just enough structure to keep your code from
> devolving into 'JavaScript soup.'"

Note the handbook says "three main concepts" (origin, pre-3.0) then "four" (introduction). The real 2026
API surface is **six**: controllers, actions, targets, values, classes, outlets.

---

<a name="2-anatomy"></a>
## 2. Anatomy: identifiers, filenames, registration, loading

### 2.1 A controller

```js
// app/javascript/controllers/hello_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets  = [ "name" ]
  static values   = { greeting: { type: String, default: "Hello" } }
  static classes  = [ "active" ]
  static outlets  = [ "other-controller" ]

  initialize() {}   // once per instance
  connect()    {}   // every time the element enters the document
  disconnect() {}   // every time it leaves
}
```

Documented instance properties: `this.application`, `this.element`, `this.identifier`.
Undocumented but real and used in the wild: `this.scope`, `this.data`, `this.targets`, `this.classes`, `this.outlets`.
Documented method: `this.dispatch(name, options)`.

Generic type parameter for the element (TS): `class extends Controller<HTMLFormElement>`.

### 2.2 Filename → identifier

Official table ([reference/controllers](https://stimulus.hotwired.dev/reference/controllers)):

| File | Identifier |
|---|---|
| `clipboard_controller.js` | `clipboard` |
| `date_picker_controller.js` | `date-picker` |
| `local-time-controller.js` | `local-time` |
| `users/list_item_controller.js` | `users--list-item` |
| `admin/users/list_item_controller.js` | `admin--users--list-item` |

Rules: **`/` → `--`**, **`_` → `-`**, trailing `_controller.ext` stripped. Dashes and underscores are
treated identically in filenames.

`[SOURCE]` The two real implementations differ slightly but agree on results.

```js
// stimulus-rails: app/assets/javascripts/stimulus-loading.js — path → identifier
const name = path
  .replace(new RegExp(`^${under}/`), "")
  .replace("_controller", "")     // NOTE: non-global replace, strips the FIRST occurrence
  .replace(/\//g, "--")
  .replace(/_/g, "-")

// …and the inverse, used by the lazy loader
function controllerFilename(name, under) {
  return `${under}/${name.replace(/--/g, "/").replace(/-/g, "_")}_controller`
}
```

```ts
// @hotwired/stimulus-webpack-helpers
export function identifierForContextKey(key: string): string | undefined {
  const logicalName = (key.match(/^(?:\.\/)?(.+)(?:[/_-]controller\..+?)$/) || [])[1]
  if (logicalName) return logicalName.replace(/_/g, "-").replace(/\//g, "--")
}
```

**Footguns in the transform:**
- `.replace("_controller", "")` is non-global. `my_controller_thing_controller.js` → `my-thing-controller`. Don't do that.
- The round trip is lossy: both `-` and `_` in a filename become `-` in the identifier, and the lazy loader
  always resolves back to the *underscore* form. Pick one convention (snake_case) and stick to it.
- **Never put a `.` in a controller filename.** The dot survives into the identifier, and dots are the
  key-filter separator in action descriptors, so the identifier becomes unusable.

### 2.3 The `--` namespace, end to end

For a namespaced controller `users--list-item`:

```html
<div data-controller="users--list-item"
     data-users--list-item-target="…"                    <!-- targets on descendants -->
     data-users--list-item-label-value="Hi"
     data-users--list-item-active-class="is-active"
     data-users--list-item-other-outlet=".selector">
  <button data-action="users--list-item#activate">Go</button>
</div>
```

But in **JS property names the namespace delimiters collapse**:

```js
static outlets = [ "admin--user-status" ]

this.admin__UserStatusOutlets   // undefined — WRONG
this.adminUserStatusOutlets     // correct
```

`[SOURCE]` `src/core/string_helpers.ts`:

```ts
export function camelize(value: string) {
  return value.replace(/(?:[_-])([a-z0-9])/g, (_, char) => char.toUpperCase())
}
export function namespaceCamelize(value: string) {
  return camelize(value.replace(/--/g, "-").replace(/__/g, "_"))
}
```

So identifier `admin--user-status` yields `adminUserStatusOutlet`, `adminUserStatusOutlets`,
`adminUserStatusOutletElement(s)`, `hasAdminUserStatusOutlet`, and callbacks
`adminUserStatusOutletConnected` / `…Disconnected`.

### 2.4 Registration

```js
// explicit
import ReferenceController from "./controllers/reference_controller"
application.register("reference", ReferenceController)

// inline, for genuinely tiny one-offs
application.register("reference", class extends Controller { /* … */ })

// conditional — skip registration entirely
class UnloadableController extends Controller {
  static get shouldLoad() { return false }
}

// side effect on registration, even with zero controlled elements in the DOM
class SpinnerButton extends Controller {
  static afterLoad(identifier, application) {
    const { controllerAttribute } = application.schema
    document.querySelectorAll(".legacy-spinner-button")
      .forEach(el => el.setAttribute(controllerAttribute, identifier))
  }
}
```

> The official docs' `afterLoad` sample uses `document.querySelector(...).forEach(...)` — a real bug in the
> docs; `querySelector` returns one element. Use `querySelectorAll`.

`afterLoad` is the retrofit hook: it lets a **generic** controller adopt **legacy markup** it doesn't control,
without touching the templates. Genuinely useful for a shared library.

### 2.5 importmap vs jsbundling

**importmap (Rails default).** `bin/rails stimulus:install` writes:

```ruby
# config/importmap.rb
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
```

```js
// app/javascript/controllers/index.js
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
```

```js
// app/javascript/controllers/application.js
import { Application } from "@hotwired/stimulus"
const application = Application.start()
application.debug = false
window.Stimulus   = application
export { application }
```

**jsbundling / esbuild / bun.** `index.js` is a *generated manifest*:

```js
// This file is auto-generated by ./bin/rails stimulus:manifest:update
import { application } from "./application"

import HelloController from "./hello_controller"
application.register("hello", HelloController)

import Namespace__NamespacedController from "./namespace/namespaced_controller"
application.register("namespace--namespaced", Namespace__NamespacedController)
```

`[SOURCE]` `lib/stimulus/manifest.rb` — the exact naming rules the generator uses:

```ruby
controller_class_name = module_path.underscore.camelize.gsub(/::/, "__")
tag_name = module_path.remove(/_controller/).gsub(/_/, "-").gsub(/\//, "--")
```

**`stimulus:manifest:update` is only for the bundler path.** The rake tasks:

```
bin/rails stimulus:install               # detects importmap / node / bun
bin/rails stimulus:manifest:display      # print the manifest
bin/rails stimulus:manifest:update       # OVERWRITE controllers/index.js
bin/rails generate stimulus NAME         # scaffold + update the manifest
```

`[SOURCE]` the generator skips the manifest rewrite when `config/importmap.rb` exists:

```ruby
def update_manifest_index?
  !(Rails.root.join("config/importmap.rb").exist? || options[:skip_manifest])
end
```

So: **importmap apps never need `stimulus:manifest:update`.** Bundler apps must run it (or use the
generator) whenever a controller is added or renamed. This is the single most common "my controller
doesn't work" cause in esbuild apps.

The generator template — note the comment convention, which is worth adopting as a documentation habit
for a shared library:

```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="my-name"
export default class extends Controller {
  connect() {
  }
}
```

### 2.6 `eagerLoadControllersFrom` vs `lazyLoadControllersFrom`

`[SOURCE]` `stimulus-rails/app/assets/javascripts/stimulus-loading.js`, in full:

```js
import "@hotwired/stimulus"   // FIXME: es-module-shim won't shim the dynamic import without this

const controllerAttribute = "data-controller"

export function eagerLoadControllersFrom(under, application) {
  const paths = Object.keys(parseImportmapJson())
    .filter(path => path.match(new RegExp(`^${under}/.*_controller$`)))
  paths.forEach(path => registerControllerFromPath(path, under, application))
}

function parseImportmapJson() {
  return JSON.parse(document.querySelector("script[type=importmap]").text).imports
}

export function lazyLoadControllersFrom(under, application, element = document) {
  lazyLoadExistingControllers(under, application, element)
  lazyLoadNewControllers(under, application, element)
}

function lazyLoadNewControllers(under, application, element) {
  new MutationObserver((mutationsList) => {
    for (const { attributeName, target, type } of mutationsList) {
      switch (type) {
        case "attributes": {
          if (attributeName == controllerAttribute && target.getAttribute(controllerAttribute)) {
            extractControllerNamesFrom(target).forEach(n => loadController(n, under, application))
          }
        }
        case "childList": {
          lazyLoadExistingControllers(under, application, target)
        }
      }
    }
  }).observe(element, { attributeFilter: [controllerAttribute], subtree: true, childList: true })
}

function canRegisterController(name, application){
  return !application.router.modulesByIdentifier.has(name)
}
```

Three things a definitive reference should say about this:

1. **Eager loading requires an *inline* `<script type="importmap">`.** `parseImportmapJson()` reads
   `.text`. If a strict CSP or an external importmap file is used, this throws and *nothing* registers.
2. It reaches into `application.router.modulesByIdentifier` — **a private internal**. It works, but it's
   not a supported API and it's why `stimulus-loading` is versioned with the gem.
3. There is **no `break`** after `case "attributes"` — deliberate-looking fallthrough, harmless because
   `canRegisterController` makes re-scanning idempotent.

**Should you lazy load?** stimulus-rails' own guidance: eager is the default and is right "when you have a
modest number of controllers"; lazy is for "a lot of controllers." Writebook's generated `index.js`
carries the switch commented out with a warning:

```js
// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("controllers", application)
```

For **crosswire** — a library of ~30 tiny controllers — eager loading is almost certainly correct: the
controllers are small, HTTP/2-multiplexed, and lazy loading introduces a frame of latency before behavior
attaches (visible as flicker on toggle/transition controllers). Revisit only if the bundle measurably hurts.

### 2.7 No build step / CDN

```html
<script type="module">
  import { Application, Controller } from "https://unpkg.com/@hotwired/stimulus/dist/stimulus.js"
  window.Stimulus = Application.start()
  Stimulus.register("hello", class extends Controller { static targets = ["name"] })
</script>
```

The handbook's unpinned `unpkg` URL is a supply-chain and reproducibility hazard — pin the version and
prefer `jsdelivr`/`esm.sh` in 2026.

### 2.8 Overriding the schema

```js
import { Application, defaultSchema } from "@hotwired/stimulus"

const customSchema = { ...defaultSchema, actionAttribute: "data-stimulus-action" }
window.Stimulus = Application.start(document.documentElement, customSchema)
```

`[SOURCE]` the full schema:

```ts
export const defaultSchema: Schema = {
  controllerAttribute: "data-controller",
  actionAttribute: "data-action",
  targetAttribute: "data-target",                                   // legacy, Stimulus 1
  targetAttributeForScope: (identifier) => `data-${identifier}-target`,
  outletAttributeForScope: (identifier, outlet) => `data-${identifier}-${outlet}-outlet`,
  keyMappings: { /* see §7 */ },
}
```

### 2.9 Error handling

Every call into your code is wrapped in `try/catch`. Compose, don't replace:

```js
const defaultErrorHandler = application.handleError.bind(application)
application.handleError = (error, message, detail = {}) => {
  defaultErrorHandler(error, message, detail)
  Sentry.captureException(error, { message, ...detail })
}
```

`[SOURCE]` the default also forwards to `window.onerror`, so most error trackers pick it up for free:

```ts
handleError(error: Error, message: string, detail: object) {
  this.logger.error(`%s\n\n%o\n\n%o`, message, error, detail)
  window.onerror?.(message, "", 0, 0, error)
}
```

---

<a name="3-lifecycle"></a>
## 3. Lifecycle: exact firing order and the subtle rules

### 3.1 The canonical order

The docs say "target callbacks fire before `connect()`" and stop there. `[SOURCE]` `src/core/context.ts`
gives the complete picture:

```ts
constructor(module, scope) {
  this.controller = new module.controllerConstructor(this)   // 1
  this.bindingObserver = new BindingObserver(this, this.dispatcher)
  this.valueObserver   = new ValueObserver(this, this.controller)
  this.targetObserver  = new TargetObserver(this, this)
  this.outletObserver  = new OutletObserver(this, this)
  this.controller.initialize()                               // 2
}

connect() {
  this.bindingObserver.start()   // 3  actions bound
  this.valueObserver.start()     // 4  [name]ValueChanged ×N
  this.targetObserver.start()    // 5  [name]TargetConnected ×N
  this.outletObserver.start()    // 6  [name]OutletConnected ×N
  this.controller.connect()      // 7
}

disconnect() {
  this.controller.disconnect()   // 1
  this.outletObserver.stop()     // 2  [name]OutletDisconnected ×N
  this.targetObserver.stop()     // 3  [name]TargetDisconnected ×N
  this.valueObserver.stop()      // 4
  this.bindingObserver.stop()    // 5  actions unbound
}
```

**Connect:**
```
constructor → initialize() → [bind actions] → xValueChanged(v, undefined) ×N
  → xTargetConnected(el) ×N → xOutletConnected(ctrl, el) ×N → connect()
```

**Disconnect (exact mirror):**
```
disconnect() → xOutletDisconnected(ctrl, el) ×N → xTargetDisconnected(el) ×N → [unbind actions]
```

Consequences you must internalise:

- **`initialize()` runs exactly once per controller instance.** Not once per connect.
- **`connect()` can run many times** for the same instance — Stimulus reuses the instance when the same
  element is detached and re-attached.
- **`[name]ValueChanged` fires before `connect()` on *every* connect**, for every declared value, with
  `previousValue === undefined` on the first call. Don't duplicate initialisation work in both places.
- Inside `initialize()`, value *getters* work (they read the attribute directly) but **no callbacks have
  fired and no targets have been announced**.

### 3.2 When does a controller connect / disconnect?

Connected when *both*: the element is in the document, **and** the identifier is in `data-controller`.

Disconnected when either becomes false ([reference/lifecycle-callbacks](https://stimulus.hotwired.dev/reference/lifecycle-callbacks)):

- `removeChild()` / `remove()` on the element
- a parent is removed
- a parent's contents are replaced via `innerHTML =`
- the element's `data-controller` attribute is removed or modified
- the document installs a new `<body>` — i.e. **a Turbo Drive page change**

### 3.3 Reconnection, and the DOM-move trap

> "A disconnected controller may become connected again at a later time. When this happens, such as after
> removing the controller's element from the document and then re-attaching it, **Stimulus will reuse the
> element's previous controller instance**, calling its `connect()` method multiple times."

`[SOURCE]` confirmed by the framework's own test — `initializeCount` stays 1 across a
remove/append cycle while `connectCount` goes to 2:

```ts
async "test Controller#connect"() {
  this.assert.equal(this.controller.connectCount, 1)
  await this.reconnectControllerElement()      // removeChild + appendChild
  this.assert.equal(this.controller.connectCount, 2)
}
```

`appendChild` on an already-attached node is a **move**, and a move is `disconnect()` + `connect()`.
Any drag-and-drop, sortable list, or "move this row to the top" code will churn every controller inside
the moved subtree. Three defences:

1. Make `connect()` idempotent and `disconnect()` unconditional.
2. Keep expensive resources out of `connect()` — build them in `initialize()`.
3. Use the 37signals idiom for "was that a real removal or just a move?" — `[SOURCE]` Campfire
   `app/javascript/helpers/dom_helpers.js`:

```js
export function ignoringBriefDisconnects(element, fn) {
  requestAnimationFrame(() => {
    if (!element.isConnected) fn()
  })
}
```

```js
// campfire rooms_list_controller.js
disconnect() {
  ignoringBriefDisconnects(this.element, () => {
    this.channel?.unsubscribe()
    this.channel = null
  })
}
```

That is: **defer teardown one frame; if the element came back, skip it.** Steal this.

### 3.4 Timing: microtasks, not synchronous

> "Stimulus watches the page for changes asynchronously using the DOM `MutationObserver` API… Stimulus
> calls your controller's lifecycle methods asynchronously after changes are made to the document, in the
> next **microtask** following each change."

So after `container.innerHTML = html`, the controller is *not* connected on the next line. In tests, await
a frame or a microtask. Ordering is still guaranteed: two `connect()`s are always separated by a `disconnect()`.

### 3.5 The MutationObserver pause

> "During the execution of `[name]TargetConnected` and `[name]TargetDisconnected` callbacks, the
> `MutationObserver` instances behind the scenes are **paused**. This means that if a callback adds or
> removes a target with a matching name, the corresponding callback _will not_ be invoked again."

This is what makes the canonical "re-sort my list whenever an item connects" pattern safe from infinite
recursion. `[SOURCE]` `target_observer.ts` — `this.tokenListObserver?.pause(() => this.delegate.targetConnected(...))`.

### 3.6 Async work in `connect()`

Because callbacks are deferred, an `await` inside `connect()` can resume after the element has been
detached. Guard it:

```js
async connect() {
  const data = await fetch(this.urlValue).then(r => r.json())
  if (!this.element.isConnected) return   // detached while we awaited
  this.render(data)
}
```

`this.element.isConnected` is plain DOM (`Node.isConnected`), not a Stimulus API.

### 3.7 Turbo cache previews

Not covered anywhere in the official Stimulus reference. Practical model: on a Turbo Drive restoration
visit, the **cached snapshot body is installed first** (controllers connect against stale HTML, with
`<html data-turbo-preview>` set), then the fresh body replaces it (those controllers disconnect, new ones
connect). Net effect: **`connect()` can fire twice per navigation**, once against stale markup.

```js
get isPreview() {
  return document.documentElement.hasAttribute("data-turbo-preview")
}

connect() {
  if (this.isPreview) return       // don't start timers/sockets against a stale snapshot
  this.start()
}
```

See §14 for the full Turbo story including morphing.

---

<a name="4-targets"></a>
## 4. Targets

```html
<div data-controller="search">
  <input type="text" data-search-target="query">
  <div data-search-target="errorMessage"></div>
  <div data-search-target="results"></div>
</div>
```

```js
static targets = [ "query", "errorMessage", "results" ]
```

| Kind | Property | Value |
|---|---|---|
| Singular | `this.queryTarget` | first match in scope — **throws** if none |
| Plural | `this.queryTargets` | array of all matches |
| Existential | `this.hasQueryTarget` | boolean |

Error text: `Missing target element "results" for "search" controller`.

### 4.1 Scoping rules

A target belongs to the **nearest ancestor controller with the matching identifier**.

```html
<ul id="parent" data-controller="list">
  <li data-list-target="item">One</li>
  <li data-list-target="item">Two</li>
  <li>
    <ul id="child" data-controller="list">
      <li data-list-target="item">I am</li>
      <li data-list-target="item">a nested list</li>
    </ul>
  </li>
</ul>
```

`#parent.itemTargets` → `[One, Two]`. `#child.itemTargets` → the inner two.

`[SOURCE]` the mechanism is one line in `scope.ts`:

```ts
containsElement = (element: Element): boolean => {
  return element.closest(this.controllerSelector) === this.element
}
```

**Nesting only shields against the *same* identifier.** A nested `data-controller="other"` does not stop an
outer `list` controller from claiming `data-list-target` elements inside it. This is precisely why
recursive components (tree views, nested comment threads) work with a single controller, and it is a
load-bearing property for reusable controllers.

### 4.2 Shared targets

One element can be a target of several controllers:

```html
<form data-controller="search checkbox">
  <input type="checkbox" data-search-target="projects" data-checkbox-target="input">
  <input type="checkbox" data-search-target="messages" data-checkbox-target="input">
</form>
```

`search` sees `this.projectsTarget` / `this.messagesTarget`; `checkbox` sees `this.inputTargets` (both).
This is a real composition lever: a generic `checkbox` controller can operate on the same elements a
feature-specific controller names differently.

### 4.3 Target callbacks as a reactive primitive

```js
export default class extends Controller {
  static targets = [ "item" ]

  itemTargetConnected(element)    { this.sort() }
  itemTargetDisconnected(element) { this.sort() }
}
```

`itemTargetConnected` fires when the element is added, **or** when `data-…-target` is added to an existing
element, **or** when the name is appended to an existing target attribute's space-separated list.

This is the primitive that makes controllers robust under Turbo Streams: content arrives over the wire,
and the controller reacts without any explicit "re-init" step. It is the single most underused feature in
the API.

Production example — `[SOURCE]` Campfire `sorted_list_controller.js`:

```js
import { Controller } from "@hotwired/stimulus"
import { throttle } from "helpers/timing_helpers"

export default class extends Controller {
  static targets = [ "item" ]

  itemTargetConnected(target) { this.#throttledSort() }

  updateItem({ detail: { targetId }}) {
    const item = this.itemTargets.find(t => t.id == targetId)
    if (item) {
      if (item.dataset.sortedListNumber) item.dataset.sortedListNumber = new Date().getTime()
      this.sort()
    }
  }

  sort() {
    this.itemTargets
      .sort((a, b) => /* … */)
      .forEach(item => this.element.appendChild(item))
  }

  #throttledSort = throttle(this.sort.bind(this))
}
```

Note: `appendChild` in `sort()` moves the items, which disconnects and reconnects any controllers inside
them (see §3.3). Acceptable here because the items are inert; be careful when the items themselves carry
stateful controllers.

---

<a name="5-values"></a>
## 5. Values

```html
<div data-controller="loader"
     data-loader-url-value="/messages"
     data-loader-content-type-value="application/json"
     data-loader-interval-value="5"
     data-loader-refresh-value="true"
     data-loader-ids-value="[1,2,3]"
     data-loader-params-value='{"page":1}'>
</div>
```

```js
static values = {
  url:         String,
  contentType: { type: String, default: "text/html" },
  interval:    { type: Number, default: 5 },
  refresh:     Boolean,
  ids:         Array,
  params:      Object
}
```

Attribute shape: `data-[identifier]-[kebab-name]-value`, **on the same element as `data-controller`**.

### 5.1 Types, encoding, defaults

| Type | Encoded | Decoded | Absent default |
|---|---|---|---|
| Array | `JSON.stringify` | `JSON.parse` (throws if not an array) | `[]` |
| Boolean | `String(bool)` | `!(v == "0" \|\| v.toLowerCase() == "false")` | `false` |
| Number | `String(n)` | `Number(v.replace(/_/g, ""))` | `0` |
| Object | `JSON.stringify` | `JSON.parse` (throws if array/null/non-object) | `{}` |
| String | itself | itself | `""` |

`[SOURCE]` `src/core/value_properties.ts` — two decoders that surprise people:

```ts
boolean(value: string): boolean {
  return !(value == "0" || String(value).toLowerCase() == "false")
},
number(value: string): number {
  return Number(value.replace(/_/g, ""))
},
```

- **Boolean is not `JSON.parse`.** Every string except `"0"` and `"false"` is `true` — including `""`,
  `"no"`, `"off"`, `"null"`. `data-x-open-value=""` is `true`. Render booleans explicitly.
- **Number strips underscores**: `data-x-limit-value="1_000_000"` → `1000000`. Non-numeric → `NaN`, silently.
- Declaring `{ type: Number, default: "5" }` **throws at load time** — type and default must agree.

### 5.2 Properties

| Kind | Property | Effect |
|---|---|---|
| Getter | `this.urlValue` | reads the attribute, falls back to default |
| Setter | `this.urlValue = x` | **writes the attribute**; `= undefined` removes it |
| Existential | `this.hasUrlValue` | see caveat below |

**Values never throw for absence** — unlike targets, classes and outlets. That asymmetry is worth memorising.

`[SOURCE]` the existential property is **not** what the docs say:

```ts
[`has${capitalize(name)}`]: {
  get(this: Controller): boolean {
    return this.data.has(key) || definition.hasCustomDefaultValue
  },
},
```

**`hasXValue` returns `true` whenever the value was declared with an explicit `default:`, even if the
attribute is absent.** This is a genuine doc/behaviour divergence and it breaks the
"optional feature detection" idiom (§5.4) if you also give the value a default.

### 5.3 `valueChanged` as reactive state

```js
export default class extends Controller {
  static targets = [ "slide" ]
  static values  = { index: Number }

  next()     { this.indexValue++ }
  previous() { this.indexValue-- }

  indexValueChanged(current, previous) { this.showCurrentSlide() }

  showCurrentSlide() {
    this.slideTargets.forEach((el, i) => { el.hidden = i !== this.indexValue })
  }
}
```

From the handbook:

> "Stimulus calls the `indexValueChanged()` method at initialization and in response to any change to the
> `data-slideshow-index-value` attribute. **You can even fiddle with the attribute in the web inspector and
> the controller will change slides in response.**"

That last sentence is the whole point: **the attribute is a public, externally-writable API**. The server
can drive it via a Turbo Stream. Devtools can drive it. Another controller can drive it. A test can drive
it. A controller whose behaviour is a pure function of its values is the most reusable thing you can build.

Firing rules:
- Fires on every connect, before `connect()`, for every value (present or defaulted).
- Fires on attribute change from *any* source, including your own setter.
- Fires when the attribute is **removed**, with the type default as the new value.
- `previousValue` is `undefined` on the initial call. Guard with `if (previous === undefined) return` when
  you want "changes only."

**In-place mutation does not fire the callback.** `this.itemsValue.push(x)` neither writes the DOM nor
triggers `itemsValueChanged`. Always reassign: `this.itemsValue = [...this.itemsValue, x]`.
(betterstimulus.com's State Management article gets this wrong in its "Good" example.)

### 5.4 Values as the public API of a reusable controller

This is the central technique for the crosswire library. Every axis of variation becomes a value:

```js
// A single "poll" controller that serves: load-once, poll, poll-while-visible, and stop-after-N.
export default class extends Controller {
  static values = {
    url:      String,
    interval: Number,                                 // absent ⇒ no polling
    max:      { type: Number, default: Infinity },
    method:   { type: String, default: "GET" }
  }

  connect() {
    this.load()
    if (this.hasIntervalValue) this.start()   // optional feature, selected by markup
  }
}
```

The `has…Value` check is the **optional-feature switch**: presence of an attribute turns a capability on.
(Caveat: only works for values *without* a declared `default:` — see §5.2.)

The handbook's own example of this is `content-loader`, where `hasRefreshIntervalValue` decides between
"load once" and "poll."

### 5.5 Object values as configuration blobs

```html
<div data-controller="chart"
     data-chart-options-value='{"type":"bar","stacked":true,"legend":{"position":"bottom"}}'>
</div>
```

```js
static values = { options: Object }
connect() { this.chart = new Chart(this.element, { ...this.defaults, ...this.optionsValue }) }
```

Good for third-party library config. Bad as a substitute for named values — you lose type safety, the
`valueChanged` granularity, and the self-documenting quality of the markup. Rule of thumb: **named values
for things your controller reasons about; one Object value for things it passes straight through.**

---

<a name="6-css-classes"></a>
## 6. CSS Classes — the design-system-agnostic escape hatch

```html
<form data-controller="search"
      data-search-loading-class="search--busy"
      data-search-no-results-class="search--empty">
```

```js
static classes = [ "loading", "noResults" ]

loadResults() {
  this.element.classList.add(...this.loadingClasses)
}
```

| Kind | Property | Value |
|---|---|---|
| Singular | `this.loadingClass` | **the first class in the list** |
| Plural | `this.loadingClasses` | array split on whitespace |
| Existential | `this.hasLoadingClass` | boolean |

**Both singular and plural throw when the attribute is absent** (`Missing attribute "data-search-loading-class"`).
That is Target-like behaviour, not Value-like. Guard with `hasLoadingClass`.

### Why this API exists

From [reference/css-classes](https://stimulus.hotwired.dev/reference/css-classes):

> "**As an alternative to hard-coding classes with JavaScript strings**, Stimulus lets you refer to CSS
> classes by _logical name_…"

And the handbook, on the clipboard controller:

> "**This will let us control the specific CSS class in the HTML, so our controller becomes even more
> easily adaptable to different CSS approaches.**"

That's the reusability argument stated by the authors: **a controller that hardcodes `"hidden"` is coupled
to one stylesheet; a controller that reads `this.hiddenClass` works with Tailwind, Bootstrap, BEM, or a
design-system token without a code change.** For crosswire this is non-negotiable: **no controller in the
library may ever contain a literal CSS class name.**

### The multi-class trap

```html
data-search-loading-class="bg-gray-500 animate-spin cursor-wait"
```

```js
this.element.classList.add(this.loadingClass)      // adds ONLY "bg-gray-500" — silent bug
this.element.classList.add(...this.loadingClasses) // correct
```

With Tailwind, multi-class values are the norm. **Always use the plural + spread form** in library code.
A useful house rule: only use the singular when the value is semantically a single token.

### Toggle idiom

```js
this.element.classList.toggle(this.activeClass, condition)          // single
this.activeClasses.forEach(c => this.element.classList.toggle(c, condition))  // multi
```

There is no built-in multi-class `toggle`; `classList.toggle` takes one token. Worth a tiny shared helper
in the library:

```js
// helpers/css.js
export const toggleClasses = (el, classes, force) =>
  classes.forEach(c => el.classList.toggle(c, force))
```

---

<a name="7-actions"></a>
## 7. Actions

### 7.1 The full grammar

`[SOURCE]` `src/core/action_descriptor.ts`:

```ts
const descriptorPattern =
  /^(?:(?:([^.]+?)\+)?(.+?)(?:\.(.+?))?(?:@(window|document))?->)?(.+?)(?:#([^:]+?))(?::(.+))?$/
```

```
[[<modifiers>+]<event>[.<keyFilter>][@window|@document]->]<identifier>#<method>[:<opt>[:<opt>…]]
```

Everything before `->` is optional. `@` accepts **only** `window` or `document` — nothing else parses.

`[SOURCE]` a crucial branch: the `.filter` suffix is only a *key filter* for keyboard events; for anything
else the dot folds back into the literal event name.

```ts
if (keyFilter && !["keydown", "keyup", "keypress"].includes(eventName)) {
  eventName += `.${keyFilter}`
  keyFilter = ""
}
```

That's why `data-action="my.custom.event->x#y"` works for a dotted custom event name.

### 7.2 Default events

`[SOURCE]` `src/core/action.ts`:

```ts
const defaultEventNames = {
  a:        () => "click",
  button:   () => "click",
  form:     () => "submit",
  details:  () => "toggle",
  input:    (e) => (e.getAttribute("type") == "submit" ? "click" : "input"),
  select:   () => "change",
  textarea: () => "input",
}
```

Omitting the event on anything else throws `missing event name`. Note `details → toggle` — the basis of the
`registerActionOption("open")` example below.

### 7.3 Event options

| Option | Effect |
|---|---|
| `:capture` | `{ capture: true }` |
| `:once` | `{ once: true }` |
| `:passive` | `{ passive: true }` |
| `:!passive` | `{ passive: false }` |
| `:stop` | `event.stopPropagation()` before invoking |
| `:prevent` | `event.preventDefault()` before invoking |
| `:self` | only if `event.target === element` |

**`:!default` does not exist.** `[SOURCE]` the parser turns any `!`-prefixed token into `{ token: false }`;
`default` matches no registered filter and is then handed to `addEventListener` as a meaningless key —
a silent no-op. Use `:prevent`.

```ts
function parseEventOptions(eventOptions: string): AddEventListenerOptions {
  return eventOptions.split(":").reduce(
    (options, token) => Object.assign(options, { [token.replace(/^!/, "")]: !/^!/.test(token) }), {})
}
```

Options chain: `data-action="submit->form#save:prevent:once"`, `click->modal#close:self:stop`.

### 7.4 Keyboard filters

Complete `keyMappings` — `[SOURCE]` `src/core/schema.ts`:

| Filter | Key |
|---|---|
| `enter` | `Enter` |
| `tab` | `Tab` |
| `esc` | `Escape` |
| `space` | `" "` |
| `up` `down` `left` `right` | `Arrow*` |
| `home` `end` | `Home` `End` |
| `page_up` `page_down` | `PageUp` `PageDown` |
| `a`–`z` | themselves |
| `0`–`9` | themselves |

Modifiers: `alt` (option), `ctrl`, `meta` (⌘), `shift`.

```html
<div data-action="keydown.esc->modal#close" tabindex="0"></div>
<div data-action="keydown.ctrl+k@document->palette#open"></div>
<div data-action="keydown.meta+shift+p@window->palette#open"></div>
```

Extend via a custom schema:

```js
const customSchema = { ...defaultSchema, keyMappings: { ...defaultSchema.keyMappings, at: "@", slash: "/" } }
```

**Two undocumented behaviours** — `[SOURCE]` `src/core/action.ts`:

```ts
private keyFilterDissatisfied(event, filters): boolean {
  const [meta, ctrl, alt, shift] = allModifiers.map(m => filters.includes(m))
  return event.metaKey !== meta || event.ctrlKey !== ctrl || event.altKey !== alt || event.shiftKey !== shift
}
```

1. **Modifier matching is exact and exhaustive, not "at least".** `keydown.esc` does **not** fire when
   Shift is held. `keydown.ctrl+k` does **not** fire for Ctrl+Shift+K. There is no wildcard.
2. **Modifier filters also apply to `MouseEvent`s** via `shouldIgnoreMouseEvent`. So
   `click.shift->list#extendSelection` and `click.meta->link#openInNewTab` work. (Only the modifier part
   is meaningful for mouse events.)
3. Key comparison is case-insensitive both sides — a filter cannot distinguish `a` from `A`; use `shift`.
4. An unknown filter name throws **at dispatch time**, not at parse time: `contains unknown key filter: …`.

Practical warning for a `hotkey` controller: because the match is exhaustive, a global shortcut like
`keydown.meta+k` will silently not fire on a keyboard layout where the user also holds Shift. If you want
lenient matching, write your own controller and inspect `event` yourself — or use `useHotkeys` (§10).

### 7.5 Action params

`data-[identifier]-[name]-param="…"`, **on the same element as the `data-action`**.

```html
<div data-controller="item spinner">
  <button data-action="item#upvote spinner#start"
    data-item-id-param="12345"
    data-item-url-param="/votes"
    data-item-payload-param='{"value":"1234567"}'
    data-item-active-param="true">…</button>
</div>
```

```js
upvote({ params: { id, url } }) { /* id === 12345 (Number), url === "/votes" */ }
```

`spinner#start` receives `{}` — **params are namespaced by controller identifier**, so two controllers on
the same button don't see each other's params.

`[SOURCE]` typecasting is `JSON.parse` with a string fallback, and the attribute regex is **case-insensitive**:

```ts
get params() {
  const params = {}
  const pattern = new RegExp(`^data-${this.identifier}-(.+)-param$`, "i")
  for (const { name, value } of Array.from(this.element.attributes)) {
    const key = (name.match(pattern) || [])[1]
    if (key) params[camelize(key)] = typecast(value)
  }
  return params
}
function typecast(value) { try { return JSON.parse(value) } catch { return value } }
```

Gotchas: `data-item-zip-param="01234"` is invalid JSON → stays the **string** `"01234"`. Same for `"007"`.

**Values vs params — the distinction that matters for reuse:**

| | Values | Action params |
|---|---|---|
| Scope | per controller *instance* | per *invocation* |
| Lives on | the `data-controller` element | the element carrying `data-action` |
| Reactive | yes (`valueChanged`) | no |
| Use for | configuration of the behaviour | arguments to one call |

The handbook's own illustration — one `content-loader` instance serving many URLs:

```html
<div data-controller="content-loader">
  <a href="#" data-content-loader-url-param="/messages.html" data-action="content-loader#load">Messages</a>
  <a href="#" data-content-loader-url-param="/comments.html" data-action="content-loader#load">Comments</a>
</div>
```

```js
load({ params: { url } }) {
  fetch(url).then(r => r.text()).then(html => this.element.innerHTML = html)
}
```

### 7.6 Custom action options

```js
application.registerActionOption("open", ({ event, value }) => {
  if (event.type == "toggle") return event.target.open == value
  return true
})
```

```html
<details data-action="toggle->menu#opened:open toggle->menu#closed:!open">
```

Return `false` to suppress the call. Callback receives `{ name, value, event, element, controller }`.
This is a legitimate extension point for a shared library — e.g. a `:visible` option that only fires when
the element is on screen, or a `:mobile` option gated on `matchMedia`.

### 7.7 Multiple actions and ordering

```html
<input data-action="focus->field#highlight input->search#update">
```

Left to right, in descriptor order. `event.stopImmediatePropagation()` inside an action halts the rest of
the chain.

### 7.8 Naming

> "Avoid action names that simply repeat the event's name, such as `click`, `onClick`, or `handleClick`…
> Instead, name your action methods based on what will happen when they're called."

```html
<button data-action="click->profile#click">Don't</button>
<button data-action="click->profile#showDialog">Do</button>
```

For a **reusable** controller this rule has extra force: the method name is the public verb of your
component. `toggle#toggle`, `dialog#open`, `clipboard#copy` read as pseudocode in the template — which is
exactly what DHH claimed as Stimulus's advantage.

---

<a name="8-outlets"></a>
## 8. Outlets — the cross-page composition primitive

```html
<div class="online-user" data-controller="user-status">…</div>
<div class="online-user" data-controller="user-status">…</div>

<div data-controller="chat" data-chat-user-status-outlet=".online-user"></div>
```

```js
export default class extends Controller {
  static outlets = [ "user-status" ]

  connect() {
    this.userStatusOutlets.forEach(status => status.markAsSelected())
  }

  userStatusOutletConnected(outlet, element)    { /* Controller first, Element second */ }
  userStatusOutletDisconnected(outlet, element) { }
}
```

Attribute: `data-[host-identifier]-[outlet-identifier]-outlet="[css selector]"`, on the host's
`data-controller` element. The **outlet name must equal the target controller's identifier**.

### 8.1 The five generated properties

| Property | Returns | Missing |
|---|---|---|
| `hasUserStatusOutlet` | Boolean | — |
| `userStatusOutlet` | `Controller` | **throws** |
| `userStatusOutlets` | `Controller[]` | `[]` |
| `userStatusOutletElement` | `Element` | **throws** |
| `userStatusOutletElements` | `Element[]` | `[]` |

The `…OutletElement(s)` pair is under-documented and genuinely useful — it gives you the DOM node without
requiring the other controller to be connected yet.

### 8.2 Things the docs don't tell you

**(a) Outlets are queried from `document.documentElement`, not from the host's scope.** `[SOURCE]` `scope.ts`:

```ts
this.outlets = new OutletSet(this.documentScope, element)
// …
private get documentScope(): Scope {
  return this.isDocumentScope ? this
    : new Scope(this.schema, document.documentElement, this.identifier, this.guide.logger)
}
```

and `outlet_observer.ts` sets up `new SelectorObserver(document.body, selector, …)`. **An outlet selector
is global.** `data-chat-user-status-outlet=".online-user"` matches `.online-user` anywhere on the page,
including inside unrelated components. For a reusable controller this is a footgun: scope your selectors
(`#sidebar .online-user`) or accept that a second instance of your component elsewhere will be captured.

**(b) The outlet element must also carry `data-controller` for that identifier.** `[SOURCE]`:

```ts
private matchesElement(element, selector, outletName): boolean {
  const controllerAttribute = element.getAttribute(this.scope.schema.controllerAttribute) || ""
  return element.matches(selector) && controllerAttribute.split(" ").includes(outletName)
}
```

Otherwise: `Missing "data-controller=user-status" attribute on outlet element for "chat" controller`.

**(c) Accessing outlets in `connect()` force-connects them, nesting their lifecycles inside yours.**
`[SOURCE]` `outlet_properties.ts` calls
`controller.application.router.proposeToConnectScopeForElementAndIdentifier(element, outletName)`.
The framework's own test proves the interleaving:

```
alpha-alpha1-start
  beta-beta-1-start / beta-beta-1-end
  beta-beta-2-start / beta-beta-2-end
  beta-beta-3-start / beta-beta-3-end
alpha-alpha1-end
```

That is: reading `this.betaOutlets` inside `alpha#connect()` runs all three `beta#connect()` bodies
*before* `alpha#connect()` returns. If a beta controller's `connect()` reads back into alpha, you get
re-entrancy. Prefer `userStatusOutletConnected()` over touching outlets in `connect()`.

**(d) Selecting by the controller attribute itself.** Writebook does this, and it's a neat idiom for
"every instance of X on the page":

```erb
data: { edit_mode_autosave_outlet: "[data-controller='autosave']" }
```

### 8.3 Outlets vs events — the real trade-off

The docs frame outlets as "an alternative to dispatching custom events." betterstimulus.com is blunter:

> "Tracking outlets via their selectors in the HTML can be tedious. The markup can become bloated and
> confusing. So I'd advise to **use it sparingly, and look into custom events as an alternative**."

| | Custom events (`dispatch`) | Outlets |
|---|---|---|
| Coupling | emitter knows nothing about receivers | host knows the other controller's *identifier and API* |
| Direction | one → many, fire and forget | host → outlets, imperative, can read return values |
| Wiring lives in | `data-action` on the receiver | `data-…-outlet` selector on the host |
| Timing | fire and forget; late listeners miss it | host can enumerate at any time; gets connect/disconnect callbacks |
| Reach | needs `@window` to cross the DOM tree | global by default |
| Reuse cost | **low** — emitter is fully generic | **medium** — host is coupled to a specific identifier |
| Testability | assert on dispatched events | need both controllers mounted |

**The decisive empirical finding:** across `stimulus-components` (32 packages),
`tailwindcss-stimulus-components` (10 controllers) and `stimulus-use` (19 mixins) — **not one uses
Outlets.** Every published Stimulus component library composes with mixins, `dispatch()`, and class
inheritance instead. That is not an accident: **outlets hardcode another controller's identifier, which a
distributable component cannot know.**

**Rule for crosswire:** a controller in the library **emits events and never declares outlets**. Outlets
belong in *app-level* coordinator controllers that compose library controllers. That keeps the library
acyclic: library controllers know nothing about each other, and it matches what every other library in the
ecosystem independently concluded.

The Gnar Company makes a sharper version of this argument
([Two Tips for Reusable UI with Stimulus](https://www.thegnar.com/blog/two-tips-for-reusable-ui-with-stimulus),
Erik Cameron, 2025-08-20, updated 2026-02-05): outlets identify controllers *by class*, so with several
instances of the same component on a page you can't address one of them. Their fix is targets + a
configurable event "channel":

```html
<div data-controller="select"
     data-contact-form-target="statesAndProvinces"
     data-select-channel-value="country">
```

```js
// in SelectController
this.dispatch("select", { prefix: this.channelValue, detail: { … } })
```

```html
<!-- the parent listens on the channel, not on the component's class name -->
data-action="country:select->contact-form#updateStatesAndProvinces"
```

This is the best idea I found in the recent literature: **`prefix:` turns `dispatch` from a
class-scoped event into a configurable channel**, which decouples the emitter from its own identity.
See Pattern C3 in §9.

---

<a name="9-composition-patterns-catalog"></a>
## 9. Composition Patterns Catalog

The organising claim: **every axis of variation should be pushed out of JavaScript and into an attribute.**
A maximally reusable Stimulus controller has zero hardcoded selectors, zero hardcoded class names, zero
hardcoded URLs, and zero hardcoded knowledge of any other controller.

Sources for this section: the Stimulus reference, betterstimulus.com, stimulus-use, the Gnar Company,
Pete Hawkins, and the production code in Writebook and Campfire (§12).

---

### A. Composition **within** the markup

#### A1 — Stack controllers on one element ("controllers are mixins")

```html
<div data-controller="clipboard effects"
     data-action="clipboard:copy->effects#flash">
  <input data-clipboard-target="source" value="1234" readonly>
  <button data-action="clipboard#copy">Copy</button>
</div>
```

betterstimulus.com states the principle:

> "Stimulus controllers are meant to be used as mixins themselves (i.e. applying multiple controllers to
> one DOM element, thus mixing in behavior)."

This is the primary composition primitive. Behaviours compose by attribute concatenation the way Tailwind
utilities compose by class concatenation. Each controller gets its own instance, its own scope, its own
values namespace. They cannot collide: `data-clipboard-*` and `data-effects-*` are disjoint.

**When they need to share state**, they don't — one of them owns the state as a value, and the other
reads it via an event or an outlet. Two controllers on one element are *not* automatically aware of each
other.

#### A2 — Instance multiplicity: reuse = duplicate the markup

> "**Our controller is reusable: any time we want to provide a way to copy a bit of text to the clipboard,
> all we need is markup on the page with the right annotations.**" — Handbook, Ch. 3

No registration, no instantiation, no keys. This is the cheapest form of reuse and the one people forget
is available.

#### A3 — Wrapper elements as composition scope

Because a controller's scope is its element's subtree, you compose by **nesting elements**, not by nesting
JS objects:

```html
<div data-controller="disclosure" data-disclosure-open-value="false">
  <button data-action="disclosure#toggle" data-disclosure-target="trigger">Details</button>

  <div data-disclosure-target="panel" hidden
       data-controller="transition"
       data-transition-enter-class="fade-in"
       data-transition-leave-class="fade-out"
       data-action="disclosure:opened->transition#enter disclosure:closed->transition#leave">
    …
  </div>
</div>
```

`disclosure` knows nothing about animation. `transition` knows nothing about disclosure. The **wrapper
element plus a `data-action` is the wiring**. This is the pattern to lean on hardest for crosswire.

#### A4 — Duck-typed targets

> "our `source` target need not be an `<input type="text">`. The controller only expects it to have a
> `value` property. That means we can use a `<textarea>` instead."

A reusable controller should assume the **smallest possible interface** on its targets. Prefer
`element.value`, `element.textContent`, `element.hidden`, `classList` over anything type-specific.

#### A5 — The Rails helper *is* the controller's markup API

Matt Swanson, [Building lightweight components with Rails helpers and Stimulus](https://boringrails.com/tips/lightweight-components-with-helpers-stimulus).
This is the missing half of the reusable-controller story that nobody else writes about:

> "Custom Rails `helpers` modules are often overlooked, but they can be a great option for building
> lightweight components and **reducing boilerplate in your Stimulus controllers**."

A generic controller needs a generic *markup* API too, or every call site retypes six data attributes and
they drift. Pattern: one base helper wrapping the wiring, then thin specialised helpers on top.

```ruby
# app/helpers/hovercard_helper.rb
module HovercardHelper
  def hovercard(url:, delay: 300, &block)
    tag.span(
      data: {
        controller: "hovercard",
        hovercard_url_value: url,
        hovercard_delay_value: delay,
        action: "mouseenter->hovercard#show mouseleave->hovercard#hide"
      },
      &block
    )
  end

  def user_hovercard(user, &block) = hovercard(url: hovercard_user_path(user), &block)
  def repo_hovercard(repo, &block) = hovercard(url: hovercard_repo_path(repo), &block)
end
```

**This is how you get a *vocabulary* rather than a *library*: the controller is the verb, the helper is
the phrasebook entry.** It also means an attribute rename is a one-file change instead of a grep.

Strong recommendation for crosswire: ship helpers (or Phlex/ViewComponent wrappers) alongside the
controllers, and treat the helper signature as the *real* public API.

---

### B. Composition **via events** (the loose-coupling bus)

#### B1 — `this.dispatch()` + `data-action`

```js
class ClipboardController extends Controller {
  static targets = [ "source" ]
  copy() {
    this.dispatch("copy", { detail: { content: this.sourceTarget.value } })
    navigator.clipboard.writeText(this.sourceTarget.value)
  }
}
```

```html
<div data-controller="clipboard effects" data-action="clipboard:copy->effects#flash">
```

`[SOURCE]` `dispatch` in full — it is 6 lines and worth knowing exactly:

```ts
dispatch(eventName, { target = this.element, detail = {}, prefix = this.identifier,
                      bubbles = true, cancelable = true } = {}) {
  const type = prefix ? `${prefix}:${eventName}` : eventName
  const event = new CustomEvent(type, { detail, bubbles, cancelable })
  target.dispatchEvent(event)
  return event
}
```

Placement rules:
- Same element or an ancestor of the emitter → plain `data-action="clipboard:copy->effects#flash"` (events bubble).
- Anywhere else on the page → `@window`: `data-action="clipboard:copy@window->effects#flash"`.

#### B2 — Cancellable events: veto points in a generic controller

```js
copy() {
  const event = this.dispatch("copy", { cancelable: true })
  if (event.defaultPrevented) return
  navigator.clipboard.writeText(this.sourceTarget.value)
}
```

```js
class EffectsController extends Controller {
  flash(event) { event.preventDefault() }   // vetoes the copy
}
```

This lets a **generic** controller expose extension points that **specific** controllers can hook, without
the generic controller knowing they exist. Every non-trivial library controller should dispatch a
`cancelable` `before…` event.

#### B3 — Configurable event channels (`prefix:`)

The Gnar Company's technique. Default `prefix` is the controller's identifier, which couples the event
name to the class. Override it with a value:

```js
export default class extends Controller {
  static values = { channel: String }

  select(item) {
    this.dispatch("select", {
      prefix: this.hasChannelValue ? this.channelValue : this.identifier,
      detail: { item }
    })
  }
}
```

```html
<div data-controller="select" data-select-channel-value="country">…</div>
<div data-controller="select" data-select-channel-value="state">…</div>

<form data-controller="contact-form"
      data-action="country:select->contact-form#loadStates
                   state:select->contact-form#loadCities">
```

Now **two instances of the same generic controller are individually addressable**, which outlets cannot
do. Strong candidate for a house convention: every crosswire controller accepts an optional
`channel` value.

#### B4 — Prefer native events where they already exist

betterstimulus.com's "Targetless Controllers" article splits a controller in two and couples the halves
with the browser's own `submit` event — no custom event, no API at all:

```html
<form data-controller="form form-indicator" data-action="submit->form-indicator#display">
  <span data-form-indicator-target="indicator"></span>
  <input type="number" data-action="change->form#submit">
</form>
```

```js
// form_controller.js — targetless: only acts on this.element
export default class extends Controller {
  submit() { this.element.requestSubmit() }   // fires the native submit event
}
// form_indicator_controller.js — only acts on targets
export default class extends Controller {
  static targets = ["indicator"]
  display() { this.indicatorTarget.textContent = "Saving…" }
}
```

Zero coupling. Free composability. **Always check whether a native event already carries the signal**
(`submit`, `input`, `change`, `toggle`, `animationend`, `transitionend`, `visibilitychange`, `focusin`,
`popstate`) before inventing a custom one.

#### B5 — The window bus for page-wide coordination

Campfire's sidebar, a real production example — one element listening to **two different controllers'**
events plus a Turbo event:

```erb
data-action="rooms-list:unread@window->badge-dot#update
             rooms-list:read@window->badge-dot#update
             turbo:submit-start->turbo-frame#unpermanize"
```

and another element consuming the same event stream for a different purpose:

```erb
<div id="direct_rooms" data-controller="sorted-list"
     data-action="rooms-list:unread@window->sorted-list#updateItem">
```

`rooms-list` broadcasts; `badge-dot` and `sorted-list` — two entirely generic controllers — subscribe.
**Neither subscriber imports or references the publisher.** This is the pattern at its best.

#### B6 — The Relay Controller: a *scoped* event bus in six lines

Justin Searls,
[A decoupled approach to relaying events between Stimulus controllers](https://justin.searls.co/posts/a-decoupled-approach-to-relaying-events-between-stimulus-controllers/)
(2024-08-18). His indictment of the built-in options:

> "Each major version of Stimulus has improved this story, adding features like Outlets and a convenience
> method for dispatching namespaced events" — but these approaches "sometimes introduce pressure to
> **unnecessarily couple controllers that wouldn't otherwise need to know anything about each other**."
> Outlets are "more explicit coupling between controllers, **but coupling all the same**."

He coins **"tightly decoupled"**: no explicit references between controllers, but an implicit contract via
DOM position — a shared ancestor.

```js
import { Controller } from '@hotwired/stimulus'

export default class RelayController extends Controller {
  forward (e) {
    const subscribers = this.element.
      querySelectorAll(`[data-relay-events*='${e.type}']`)

    subscribers.forEach(el => {
      el.dispatchEvent(new CustomEvent(e.type, {
        detail: e.detail,
        params: e.params
      }))
    })
  }
}
```

```html
<div data-controller="relay">
  <div data-controller="list-appender"
       data-action="list-appender:listWasAppended->relay#forward">
    …
  </div>

  <div data-controller="commentator"
       data-action="list-appender:listWasAppended->commentator#comment"
       data-relay-events="list-appender:listWasAppended">
  </div>
</div>
```

Two subscription mechanisms on purpose: `data-action` says *what to do*, `data-relay-events` says
*I opt in to receiving relayed events*. Because the relay only queries within `this.element`, it is
**not** a global bus — the subtree is the channel.

This solves the case `@window` handles badly: sibling controllers that aren't in each other's bubbling
path, where `@window` would leak the event to every instance of the component on the page.

On not shipping it as a package:

> "Because it's like six lines long, man."

That's worth taking seriously — some of crosswire's value may be as **documented snippets** rather than
as installed dependencies.

#### B7 — Self-destructing controllers (fire once, remove yourself)

Matt Swanson, [Self-destructing StimulusJS controllers](https://boringrails.com/articles/self-destructing-stimulus-controllers/)
(2022-06-13). A genuinely distinct controller *genre*: do one thing on connect, then `this.element.remove()`.
It replaces inline `<script>` tags, and:

> "all of the lifecycle events are taken care of" — you never write a `turbo:load` listener again.

```html
<template data-controller="scroll-to" data-scroll-to-selector-value="#comment_42"></template>
```

```js
export default class extends Controller {
  static values = { selector: String }

  connect() {
    document.querySelector(this.selectorValue)?.scrollIntoView({ behavior: "smooth" })
    this.element.remove()
  }
}
```

Use a `<template>` rather than an empty `<div>`: it signals intent and never renders. The genre covers
`scroll-to`, `highlight`, `grab-focus`, and analytics `beacon`. It pairs perfectly with Turbo Streams —
one response can append content *and* trigger its behaviour.

⚠️ Re-test these under morphing: a `<template>` that is never re-rendered behaves differently when the
page morphs rather than replaces.

---

### C. Composition **via direct references**

#### C1 — Outlets

See §8. Use for: a coordinator that must *call methods on* or *read state from* a known set of controller
instances. Writebook's real usage:

```js
export default class extends Controller {
  static outlets = [ "autosave" ]

  async #submitAutosaveControllers() {
    for (const autosave of this.autosaveOutlets) await autosave.submit()
  }
}
```

Note the `await` — this is the case events genuinely cannot serve: you need to know when the other
controller *finished*.

#### C2 — `getControllerForElementAndIdentifier`

```js
const other = this.application.getControllerForElementAndIdentifier(this.otherTarget, "other")
other.otherMethod()
```

The docs' own verdict:

> "**This should only be used if you have a unique problem that cannot be solved through the more general
> way of using events.**"

Reasons it's worse than an outlet: no connect/disconnect callbacks, returns `null` silently, and the
element must be the exact `data-controller` element. Use it only when you already have the element in hand
and outlets would be overkill.

#### C3 — `this.application.controllers`

`[SOURCE]` `get controllers()` maps over `this.router.contexts`. Undocumented and fragile. It appears in
betterstimulus.com's "Global Teardown" recipe:

```js
document.addEventListener("turbo:before-cache", () => {
  application.controllers.forEach(c => { if (typeof c.teardown === "function") c.teardown() })
})
```

That is a real, useful pattern (an opt-in extra lifecycle hook), but it relies on a private API. If you
adopt it, wrap it in one place so a Stimulus upgrade breaks one file.

---

### D. Composition **in JavaScript**

#### D1 — Mixin functions (`useX(this)`) — the stimulus-use style

betterstimulus.com's canonical form:

```js
// mixins/useOverlay.js
export const useOverlay = controller => {
  Object.assign(controller, {
    showOverlay(e) { /* … */ },
    hideOverlay(e) { /* … */ }
  })
}
```

```js
export default class extends Controller {
  connect() { useOverlay(this) }
}
```

Their heuristic, which is the best decision rule I found anywhere:

> - does my controller have an ***is a*** relation to the target ⟹ **use inheritance**
> - does my controller have an ***acts as a*** relation to the target ⟹ **use mixins**
> - is what you're modelling a **collaborator** (*has a*) ⟹ **use composition** — a plain JS module/class

**Two limitations the article doesn't mention, and they matter:**

1. Raw `Object.assign` **cannot add `static targets/values/classes`.** Those are read off the constructor
   and blessed onto the prototype at registration time; assigning to an instance in `connect()` is far too
   late. A mixin can only add methods and instance state.
2. Raw `Object.assign` **clobbers** same-named methods and does not compose lifecycle hooks. A mixin that
   adds listeners must also chain `disconnect`. That's exactly what stimulus-use does properly — see §10.

#### D2 — The lifecycle-patching mixin (the correct form)

`[SOURCE]` stimulus-use's `StimulusUse` base class captures the originals in its constructor:

```ts
// make copies of lifecycle functions
this.controllerInitialize = controller.initialize.bind(controller)
this.controllerConnect    = controller.connect.bind(controller)
this.controllerDisconnect = controller.disconnect.bind(controller)
```

and its `method` helper returns a no-op when the controller hasn't implemented the hook, so a mixin can
call optional callbacks unconditionally:

```ts
export const method = (controller: Controller, methodName: string): Function => {
  const method = (controller as any)[methodName]
  return typeof method == "function" ? method : (...args: any[]) => {}
}
```

The reusable recipe for writing your own:

```js
export function useSomething(controller, options = {}) {
  const originalConnect    = controller.connect.bind(controller)
  const originalDisconnect = controller.disconnect.bind(controller)

  let cleanup = () => {}

  Object.assign(controller, {
    connect() {
      cleanup = install(controller, options)   // your setup, returns a teardown fn
      originalConnect()
    },
    disconnect() {
      originalDisconnect()
      cleanup()
    }
  })

  // if the controller is already connected when the mixin is applied, install now
  if (controller.element.isConnected) cleanup = install(controller, options)
}
```

Call it in `initialize()` (so the patch is in place before the first `connect()`), or in `connect()` with
the "already connected" branch above.

#### D3 — Class mixins (higher-order classes) — the modern alternative

Not mentioned anywhere in the literature I read, but it's strictly better than `Object.assign` when you
need statics, because **Stimulus merges `static targets/values/classes/outlets` up the whole prototype
chain**. `[SOURCE]` `inheritable_statics.ts`:

```ts
function getAncestorsForConstructor<T>(constructor: Constructor<T>) {
  const ancestors = []
  while (constructor) { ancestors.push(constructor); constructor = Object.getPrototypeOf(constructor) }
  return ancestors.reverse()
}
```

So this works, and the values/classes merge:

```js
// mixins/dismissable.js
export const Dismissable = Base => class extends Base {
  static values  = { dismissDelay: Number }     // no manual spreading needed
  static classes = [ "dismissing" ]

  dismiss() {
    this.element.classList.add(...this.dismissingClasses)
    setTimeout(() => this.element.remove(), this.dismissDelayValue)
  }
}
```

```js
export default class extends Dismissable(Controller) {
  static values = { url: String }     // Stimulus merges: { dismissDelay, url }
}
```

**No manual spreading is required.** `getAncestorsForConstructor` walks `Object.getPrototypeOf(constructor)`
to the root and reverses, so pairs are collected base-first and the descriptor map is built by reducing in
order — more-derived definitions win on duplicate keys, everything else merges. The same applies to
`static targets/classes/outlets` via `readInheritableStaticArrayValues`, which unions into a `Set`.

One subtlety: `getOwnStaticObjectPairs` reads `constructor[propertyName]` — an *inherited* lookup, not
`Object.getOwnPropertyDescriptor`. So a subclass that declares **no** `static values` will report its
parent's values again. Harmless (the reduce dedupes by key), but it means you cannot detect "did this
class declare its own values?" that way.

This is the decisive advantage of higher-order class mixins over `Object.assign` mixins:
**HOC mixins can contribute values, targets, classes and outlets; `useX(this)` mixins cannot.**

#### D4 — Base-class inheritance (`ApplicationController`)

```js
// application_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  get isPreview() { return document.documentElement.hasAttribute("data-turbo-preview") }
  get csrfToken() { return document.querySelector("meta[name=csrf-token]")?.content }
}
```

Legitimate for genuinely universal concerns (error reporting, preview detection, a `teardown` hook). The
warning from betterstimulus.com is the important half:

> "Before bloating your `ApplicationController`, ask yourself if what you're implementing isn't a
> specialization but a **role** (*acts as a* — use mixins) or an attribute (*has a* — use composition)."

For crosswire specifically: **a shared base class is a coupling tax on every consumer.** Prefer mixins and
plain helper modules; keep any base class to near-zero.

Note the site contradicts itself: the Mixins article uses `overlay → dropdown/flyout` inheritance as its
*bad* example, while the Open-Closed article recommends `WidgetController → ToggleController` inheritance.
The reconciliation is the *is a* / *acts as a* test, which they never spell out.

#### D5 — Plain collaborator objects (*has a*)

The most under-used option, and the one 37signals actually reaches for. Campfire and Writebook both keep a
`app/javascript/helpers/` and `app/javascript/models/` directory of framework-free modules:

```
helpers/  timing_helpers.js  dom_helpers.js  cookie_helpers.js  form_helpers.js  turbo_helpers.js
models/   scroll_manager.js  message_paginator.js  typing_tracker.js  file_uploader.js
```

```js
// campfire maintain_scroll_controller.js
import ScrollManager from "models/scroll_manager"

export default class extends Controller {
  #scrollManager
  connect() { this.#scrollManager = new ScrollManager(this.element) }
}
```

**Anything that can be a pure function or a plain class should be**, because it's trivially unit-testable
with no DOM and no Stimulus application. This is also the answer to "how do I test my controller?" —
mostly, you don't; you test the collaborator.

#### D6 — Configuration injection (Dependency Inversion)

Because Stimulus instantiates controllers itself, you cannot pass constructor arguments. **All injection
happens through data attributes.**

```js
export default class extends Controller {
  static values = { adapter: String }

  async adapterValueChanged(name) {
    const { default: Adapter } = await import(`./adapters/${name}_adapter`)
    this.adapter = new Adapter(this.element)
  }
}
```

(betterstimulus.com's version of this has a bug — `await import()` returns the *module namespace*, not the
class. Destructure `default`.) Under importmaps, dynamic imports need a pinned, statically-analysable
specifier, so a registry map is safer than a template literal:

```js
const ADAPTERS = {
  google:  () => import("./adapters/google_adapter"),
  algolia: () => import("./adapters/algolia_adapter"),
}
```

#### D7 — Blessings: add your own `static` API to every controller

Marco Roth, [Supercharge your Stimulus controllers with Custom APIs](https://marcoroth.dev/posts/supercharge-your-stimulus-controllers-with-custom-apis)
(2023-07-27). The most architecturally ambitious idea in the literature, and it exploits something we
already saw in §2: **every public Stimulus API is itself a "Blessing."**

```js
export class Controller {
  static blessings = [
    ClassPropertiesBlessing,
    TargetPropertiesBlessing,
    ValuePropertiesBlessing,
    OutletPropertiesBlessing,
  ]
}
```

`Controller.blessings` is a public-ish array you can push onto. His example adds a `static elements` API
for referencing elements *outside* the controller's scope by CSS selector — the thing targets can't do
and outlets only do for controller elements:

```js
export default class extends Controller {
  static elements = { backdrop: "#backdrop", item: ".item" }

  connect() {
    this.backdropElement.classList.remove("hidden")
    this.itemElements.forEach(el => …)
  }
}
```

```js
import { readInheritableStaticObjectPairs } from "@hotwired/stimulus/dist/core/inheritable_statics"
import { namespaceCamelize } from "@hotwired/stimulus/dist/core/string_helpers"

export function ElementPropertiesBlessing(constructor) {
  const properties = {}
  readInheritableStaticObjectPairs(constructor, "elements").forEach(([name, selector]) => {
    const camelizedName = namespaceCamelize(name)
    Object.assign(properties, {
      [`${camelizedName}Element`]:  { get() { return document.querySelector(selector) } },
      [`${camelizedName}Elements`]: { get() { return document.querySelectorAll(selector) } }
    })
  })
  return properties
}
```

```js
Controller.blessings.push(ElementPropertiesBlessing)
```

His thesis:

> "**Not every new API needs to ship with Stimulus itself to be useful in applications.** Shipping custom
> APIs as application-specific code allows us build APIs to our specific needs without polluting the
> upstream framework."

⚠️ **Deep-import warning.** It imports from `@hotwired/stimulus/dist/core/*` — unpublished internals with
no stability guarantee. Fine as an experiment; risky as a foundation, and a hard dependency for a library
we'd ask other people to install. Note also that blessed properties are computed **once at registration**,
so a Blessing cannot react to DOM changes the way targets/outlets do.

**For crosswire:** interesting, probably out of scope for v1. If we ever want a `static elements` or
`static params` API across the whole vocabulary, this is how — but it makes crosswire a framework
extension rather than a controller library, which is a much bigger commitment.

---

### E. Composition **you shouldn't write at all**

#### E1 — When NOT to write a controller

Pete Hawkins, [Hotwire best practices for Stimulus](https://dev.to/phawk/hotwire-best-practices-for-stimulus-40e):

> "Try to rely on Turbo frames or streams to do the heavy lifting… **you should really be avoiding writing
> stimulus controllers unless absolutely necessary.**"

Travis Gaff (Lab Zero),
[Hotwire Decisions](https://labzero.com/blog/hotwire-decisions-when-to-use-turbo-frames-turbo-streams-and-stimulus)
(2023-03-02) formalises this as a **five-rung escalation ladder — Stimulus is the last rung, not the first**:

```
1. HTML + CSS          ← try here first, always
2. Turbo Drive         ← full-page navigation, free
3. Turbo Frames        ← swap a region, no JS
4. Turbo Streams       ← server pushes targeted updates
5. Stimulus            ← only what the first four cannot do
```

And his smell test, which is the best one-liner on scope creep:

> "if your controller starts to morph into a **whole-page hall-monitor** you might want to reconsider."

Checklist before writing anything:

| Instead of a controller… | use |
|---|---|
| show/hide a panel on click | `<details>` / `<summary>`, or the **Popover API** (`popover` + `popovertarget`) |
| modal dialog | `<dialog>` + `showModal()` — a 13-line controller at most (see Writebook §12) |
| tooltip / dropdown positioning | CSS **anchor positioning**, or the Popover API |
| conditional UI based on a checkbox | CSS `:has()` / `:checked` sibling selectors |
| "load more" / pagination | Turbo Frame with `loading="lazy"` |
| live-updating list | Turbo Streams over ActionCable |
| submit form and swap a region | Turbo Frame — no JS at all |
| animate on state change | CSS transitions + a class toggled by a *generic* controller |
| format a timestamp | `<time>` + a **single** generic `local-time` controller, not per-feature code |
| copy to clipboard | a controller — genuinely no HTML element for this |

The handbook's own framing: Stimulus is for "the behavior that shows and hides elements, copies content to
a clipboard… **the focus is on manipulating, not creating elements**." If your controller is building DOM
from JSON, you are in the wrong tool — either render it on the server or reach for something heavier.

DHH again:

> "**Furthermore, you don't even have to choose.** Stimulus and Turbo work great in conjunction with other,
> heavier approaches… Our calendars tend to use client-side rendering. Our text editor is Trix."

#### E2 — The Single Responsibility test

betterstimulus.com's sharpest heuristic, from "Targetless Controllers":

> "there are two types of controllers: those that act on the element the controller is attached on itself,
> and those that act on one or several `target`s. **You should avoid mixing the two.**"
>
> "If you're unsure, ask 'What would be reasons for this controller to change?' If you come up with one for
> the `target`s and one for `this.element`, that's an instance of divergent change, and you should decouple
> it into two or more controllers, and use outlets or events to communicate between them."

Practical corollary for a library: **most library controllers should be targetless.** `toggle-class`,
`auto-submit`, `element-removal`, `autoselect`, `scroll-into-view`, `web-share`, `hotkey` — all act only on
`this.element`, which is why they compose freely with anything.

---

<a name="10-stimulus-use"></a>
## 10. stimulus-use: the mixin masterclass

`github.com/stimulus-use/stimulus-use` · **0.53.0**, released **2026-06-30** · docs at `stimulus-use.dev`.
Maintained but bursty: 18 months of silence (Dec 2024 → Jun 2026), then a real batch of work in one day.
Effectively single-maintainer (Marco Roth is now the de-facto maintainer; Adrien Poly wrote it).
Still `0.x` after six years. Direction of travel is **deprecation toward Stimulus core**
(`useDispatch` → `this.dispatch()`, `useTargetMutation`'s add/remove → native target callbacks,
`stimulusUseDebug` → `application.debug`).

**Scope correction:** several names in circulation are *not* stimulus-use APIs. There is no
`useCollectionEventListener`, `useTimeout`, `useNowPlaying`, `useHead`, `useHeadTag`, or `useScrollTo`.
There *is* a `useWindowFocus` that rarely gets mentioned. `getControllerForElementAndIdentifier` belongs
to Stimulus itself, not to `ApplicationController`.

### 10.1 The four primitives — `src/support/index.ts`

The entire composition model rests on four small functions. This is the part to steal.

```ts
export const method = (controller: Controller, methodName: string): Function => {
  const method = (controller as any)[methodName]
  if (typeof method == 'function') {
    return method
  } else {
    return (...args: any[]) => {}     // no-op, so call sites need no guard
  }
}

export const composeEventName = (name: string, controller: Controller, eventPrefix: boolean | string) => {
  let composedName = name
  if (eventPrefix === true) {
    composedName = `${controller.identifier}:${name}`
  } else if (typeof eventPrefix === 'string') {
    composedName = `${eventPrefix}:${name}`
  }
  return composedName
}

export const extendedEvent = (type: string, event: Event | null, detail: object): CustomEvent => {
  const { bubbles, cancelable, composed } = event || { bubbles: true, cancelable: true, composed: true }
  if (event) Object.assign(detail, { originalEvent: event })
  return new CustomEvent(type, { bubbles, cancelable, composed, detail })
}

export function isElementInViewport(el: Element) { /* getBoundingClientRect vs innerHeight/Width */ }
export function camelize(value: string) {
  return value.replace(/(?:[_-])([a-z0-9])/g, (_, char) => char.toUpperCase())
}
```

Why each matters:

- **`method()`** is the *optional callback* primitive. Call sites become unconditional:
  `method(controller, 'appear').call(controller, entry, observer)`. Note `.call(controller, …)` so
  `this` inside the user's `appear()` is the controller. This one line is copied everywhere in the library.
- **`composeEventName()`** is one namespacing policy for every mixin: `true` → `card:appear`,
  `"foo"` → `foo:appear`, `false` → `appear`. Same three-way boolean/string contract everywhere, so
  `eventPrefix` is documented once and inherited by all. **This is the `prefix:` idea from Pattern B3,
  generalised.**
- **`extendedEvent()`** builds a `CustomEvent` that **inherits `bubbles`/`cancelable`/`composed` from the
  originating DOM event** and stashes the original at `detail.originalEvent`. A synthetic
  `card:click:outside` therefore propagates exactly like the real click that caused it.

### 10.2 The core mechanic — chaining `disconnect`

**Every observer mixin uses the same five lines.** This is the technique.

```ts
// keep a copy of the current disconnect() function of the controller
// to support composing several behaviors
const controllerDisconnect = controller.disconnect.bind(controller)

Object.assign(controller, {
  disconnect() {
    unobserve()
    controllerDisconnect()
  }
})

observe()                                 // start immediately
return [observe, unobserve] as const      // hand manual control back to the caller
```

`Object.assign(controller, …)` writes an **own property on the instance**, shadowing the prototype method:

```
controller.disconnect                         (prototype: the user's disconnect)
  ↓ useIntersection(this)
= () => { unobserveIntersection(); prototypeDisconnect() }
  ↓ useResize(this)
= () => { unobserveResize(); intersectionPatchedDisconnect() }
```

Each mixin captures whatever `disconnect` was **at the moment it ran** and calls it last. Cleanups run
**LIFO**, and the user's own `disconnect()` always runs at the tail. No mixin knows about any other.
That is the whole composition contract, and it is why `useX(this)` mixins stack cleanly.

**The gotcha you must document.** The patch lives on the *instance*, and Stimulus reuses the instance
across disconnect/reconnect. Because mixins are conventionally applied in `connect()`, a second connect
wraps the already-wrapped disconnect:

```js
connect() { useIntersection(this) }   // connect #1: 1 wrapper, 1 IntersectionObserver
                                      // connect #2: 2 wrappers, 2 observers
```

Cleanup still works (each layer unobserves its own observer) but the chain grows unboundedly and
allocates a fresh observer per cycle. `useIntersection` also pushes into `controller.intersectionElements`
**without deduping**, so `allVisible()` counts drift. **Mitigation: apply mixins in `initialize()`**
(runs once per instance) rather than `connect()`, or guard with a flag.

### 10.3 The `StimulusUse` base class

Half the mixins are plain closures; the other half extend `StimulusUse` to get logging, `dispatch`,
`call`, and the lifecycle copies.

```ts
constructor(controller: Controller, options: StimulusUseOptions = {}) {
  // …
  this.targetElement = options?.element || controller.element
  const { dispatchEvent, eventPrefix } = Object.assign({}, defaultOptions, options)
  Object.assign(this, { dispatchEvent, eventPrefix })

  // make copies of lifecycle functions
  this.controllerInitialize = controller.initialize.bind(controller)
  this.controllerConnect    = controller.connect.bind(controller)
  this.controllerDisconnect = controller.disconnect.bind(controller)
}

dispatch = (eventName: string, details: any = {}) => {
  if (this.dispatchEvent) {
    const { event, ...eventDetails } = details            // `event` is pulled OUT of the detail
    const customEvent = this.extendedEvent(eventName, event || null, eventDetails)
    this.targetElement.dispatchEvent(customEvent)
  }
}

call = (methodName: string, args: any = {}) => {
  const method = (this.controller as any)[methodName]
  if (typeof method == 'function') return method.call(this.controller, args)
}
```

Defaults: `{ debug: false, logger: console, dispatchEvent: true, eventPrefix: true }`.
`debug` cascades: per-call option → `application.debug` → legacy `application.stimulusUseDebug`
(deprecated in 0.53.0, warns once) → `false`.

Note: `dispatch()` destructures `event` out of the detail and re-attaches it as `detail.originalEvent`.
**The docs are wrong about this for several mixins** — see the detail-shape table in §10.6.

### 10.4 Three API shapes

| Shape | Used by | Returns |
|---|---|---|
| **Closure** (private state in closure vars) | `useIntersection`, `useLazyLoad`, `useClickOutside`, `useIdle`, `useResize`, `useWindowResize`, `useTransition`, `useMemo`, `useMeta`, `useDebounce`, `useThrottle`, `useApplication` | `[observe, unobserve]`, or `[enter, leave, toggleTransition]`, or nothing |
| **Class extending `StimulusUse`** | `UseHover`, `UseVisibility`, `UseWindowFocus`, `UseMutation`, `UseTargetMutation`, `UseMatchMedia`, `UseDispatch`, `UseHotkeys` | thin `useX()` wrapper returns the tuple or the instance |
| **`*Controller` base class** (inherit instead of compose) | one per observer mixin | — |

The third shape is worth studying for one trick — the constructor defers via `requestAnimationFrame` so
that **subclass class-fields have been initialised** before the mixin reads `this.options`:

```ts
export class IntersectionController extends IntersectionComposableController {
  options?: IntersectionOptions

  constructor(context: Context) {
    super(context)
    requestAnimationFrame(() => {
      const [observe, unobserve] = useIntersection(this, this.options)
      Object.assign(this, { observe, unobserve })
    })
  }
}
```

Without the rAF, `this.options` is still `undefined`. (`ApplicationController` gets this **wrong** — it
calls `useApplication(this, this.options)` directly in the constructor, so a subclass `options = {…}`
field is never seen.)

The `…ComposableController` half of each pair is **types only** (`declare`), emitting no runtime code —
a clean way to publish optional-callback signatures to TypeScript users.

### 10.5 The mixin catalog

#### `useIntersection(controller, options)` → `[observe, unobserve]`
Defaults `{ dispatchEvent: true, eventPrefix: true, visibleAttribute: 'isVisible' }`, plus native
`root`/`rootMargin`/`threshold` passed straight through to `IntersectionObserver`.
Callbacks `appear(entry, observer)`, `disappear(entry, observer)`.
Adds `isVisible()`, `allVisible()`, `noneVisible()`, `oneVisible()`, `atLeastOneVisible()`,
`intersectionElements`. Events `appear` / `disappear`, detail `{ controller, entry, observer }`.

Note `isVisible` here is **a function** (`const isVisible = allVisible`), whereas `useVisibility`'s
`isVisible` is a **boolean property** — a silent collision if you compose both.

The guard that avoids a spurious initial `disappear`:

```ts
const callback = (entries) => {
  const [entry] = entries
  if (entry.isIntersecting) {
    dispatchAppear(entry)
  } else if (targetElement.hasAttribute(visibleAttribute)) {
    dispatchDisappear(entry)
  }
}
```

```js
// infinite scroll sentinel
connect() {
  const [observe, unobserve] = useIntersection(this, {
    element: this.sentinelTarget, rootMargin: '200px'
  })
  Object.assign(this, { observe, unobserve })
}

async appear(entry, observer) {
  observer.unobserve(entry.target)                       // guard re-entry while fetching
  const html = await (await fetch(`${this.urlValue}?page=${++this.pageValue}`)).text()
  this.listTarget.insertAdjacentHTML('beforeend', html)
  observer.observe(entry.target)
}
```

#### `useLazyLoad(controller, options?)` → `[observe, unobserve]`
Options are a bare `IntersectionObserverInit`. **No events.** Callbacks `loading(src)`, `loaded(src)`;
adds `isLoading` / `isLoaded`. Contract: the element must be an `<img>` and the URL comes from
`controller.data.get('src')`, i.e. `data-[identifier]-src`. `LazyLoadController` defaults to
`{ rootMargin: '10%' }`.

#### `useResize(controller, options)` → `[observe, unobserve]`
Options `element`, `box` (`'content-box' | 'border-box' | 'device-pixel-content-box'`, **new in 0.53.0**),
`dispatchEvent`, `eventPrefix`. Callback `resize(contentRect)` — a `DOMRectReadOnly`, so
`resize({ width, height })` destructures. Event `resize`, detail `{ controller, entry }`.

0.53.0 coalesces callbacks into a `requestAnimationFrame` to kill the
"ResizeObserver loop completed with undelivered notifications" warning, and `unobserve()` cancels the
pending frame:

```ts
let frame = null
const callback = (entries) => {
  if (frame !== null) cancelAnimationFrame(frame)
  frame = requestAnimationFrame(() => { frame = null; /* … */ })
}
const unobserve = () => {
  if (frame !== null) { cancelAnimationFrame(frame); frame = null }
  observer.unobserve(targetElement)
}
```

Copy that pattern into any rAF-batched mixin.

#### `useWindowResize(controller)` → `[observe, unobserve]`
**No options at all.** Callback `windowResize({ height, width, event })`. No events. **Not debounced.**
`observe()` fires the callback once immediately (with `event === undefined`) so the controller gets an
initial size — a pattern shared with `useVisibility` and `useWindowFocus`.

#### `useHover(controller, options)` → `[observe, unobserve]`
Listens on `mouseenter`/`mouseleave` (non-bubbling). Callbacks `mouseEnter()`, `mouseLeave()`.
Events `mouseEnter`, `mouseLeave`.
**Bug:** `onEnter` dispatches `{ hover: false }` — should be `true`. Use the event *name*, not the detail.

#### `useClickOutside(controller, options)` → `[observe, unobserve]`
Defaults `{ events: ['click','touchend'], onlyVisible: true, dispatchEvent: true, eventPrefix: true }`.
Callback `clickOutside(event)`. Event `click:outside` (→ `card:click:outside`), detail
`{ controller, originalEvent }`.

Three details worth knowing:

```ts
const observe   = () => events.forEach(e => window.addEventListener(e, onEvent, true))
const unobserve = () => events.forEach(e => window.removeEventListener(e, onEvent, true))
```

- Listeners go on `window` **in the capture phase**. That is why a click that opens dropdown B closes
  dropdown A *before* B's toggle action runs — capture beats bubble. N independent dropdowns become
  mutually exclusive for free.
- `targetElement` is re-resolved **inside** `onEvent`, so a target re-rendered by Turbo is picked up.
- `onlyVisible: true` suppresses the callback when the element isn't in the viewport.
- The docs warn: **never call `event.preventDefault()` inside `clickOutside`** — that's a real click on
  some other element, and cancelling it breaks links, submits and checkboxes.

#### `useIdle(controller, options)` → `[observe, unobserve]`
Defaults `{ ms: 60000, initialState: false, events: ['mousemove','mousedown','resize','keydown','touchstart','wheel'] }`.
Callbacks `away(event)`, `back(event)`; adds `isIdle`. Events `away` / `back`.
Also listens to `visibilitychange` and treats "tab became visible" as activity. `unobserve()` clears the
pending timeout.

#### `useVisibility(controller, options)` → `[observe, unobserve]`
Page Visibility API. Callbacks `visible()`, `invisible()`; adds `isVisible` (**boolean**).
Events `visible` / `invisible`. **No de-duplication** — every `visibilitychange` fires, and `observe()`
always fires an initial callback.

#### `useWindowFocus(controller, options)` → `[observe, unobserve]`
Options `interval` (default **200 ms**). Callbacks `focus()`, `unfocus()`; adds `hasFocus`.
Implemented by **polling `document.hasFocus()`** on a `setInterval`, because window focus (unlike page
visibility) has no reliable cross-iframe event. Fires only on **transitions** (it compares against
`controller.hasFocus`), so this one *is* de-duplicated.

`useVisibility` = "is the tab in the foreground". `useWindowFocus` = "is the browser window itself
focused" — clicking into devtools or another app unfocuses without changing visibility.

#### `useMatchMedia(controller, { mediaQueries })` → `[observe, unobserve]`
Generates three callbacks per query via `camelize`: `is[Name](payload)`, `not[Name](payload)`,
`[name]Changed(payload)`, payload `{ name, media, matches, event }`. Events `is:[name]`, `not:[name]`,
`[name]:changed`.

```js
connect() {
  useMatchMedia(this, {
    mediaQueries: { mobile: '(max-width: 767px)', motion: '(prefers-reduced-motion: no-preference)' }
  })
}
isMobile()  { this.element.dataset.nav = 'drawer' }
notMobile() { this.element.dataset.nav = 'bar' }
```

Caveats: it reverse-looks-up the name by comparing `event.media` to your configured string, so **the
query must round-trip exactly** through `MediaQueryList.media` (wrap the whole query in parentheses).
It uses the deprecated `addListener`/`removeListener`. And if `window.matchMedia` is missing it bails out
with `console.error` and **never patches `disconnect`**.

#### `useMutation(controller, options)` → `[observe, unobserve]`
Options are a `MutationObserverInit` (`childList`, `attributes`, `subtree`, `attributeFilter`, …) plus
`element`. Callback `mutate(entries)`; event `mutate`, detail `{ entries }`. Invalid configs are routed
into `controller.application.handleError` instead of throwing.

```js
// "show the empty state when the list is empty" — no custom Turbo Stream needed
connect() { useMutation(this, { childList: true, subtree: true }) }
mutate() { this.emptyTarget.classList.toggle('hidden', this.listTarget.children.length > 0) }
```

#### `useTargetMutation(controller, { targets })` → `[observe, unobserve]`
**⚠️ Deprecated as of 0.52.3.** `targetAdded`/`targetRemoved` warn on every fire, pointing at native
`[name]TargetConnected` / `[name]TargetDisconnected`. **`[name]TargetChanged(node)` has no Stimulus
equivalent** and is the only remaining reason to use it — it fires when a target's *contents* change
(characterData or childList inside the target), which native callbacks do not cover.

#### `useDebounce(controller, options)` → `void`
Declared with `static debounces = ['method']` or `[{ name, wait, leading, trailing }]`.
Defaults `{ wait: 200, leading: false, trailing: true }` (leading/trailing **new in 0.53.0**).

Different mechanic: instead of patching `disconnect`, it **replaces named methods with wrapped versions
as own instance properties** — the prototype stays pristine, each instance gets its own timer, and there
is no teardown needed.

The Stimulus-specific bit inside `debounce` is worth reproducing, because you must reimplement it if you
roll your own:

```ts
const params         = args.map(arg => (arg instanceof Event ? arg.params : undefined))
const currentTargets = args.map(arg => (arg instanceof Event ? arg.currentTarget : undefined))

const callback = () => {
  args.forEach((arg, index) => {
    if (arg instanceof Event) {
      arg.params = params[index]
      Object.defineProperty(arg, 'currentTarget', { configurable: true, value: currentTargets[index] })
    }
  })
  return fn.apply(context, args)
}
```

The browser **nulls `event.currentTarget` once dispatch finishes**, and Stimulus grafts action params
onto the event per-listener. A debounced handler runs *after* dispatch completes, so both would be gone.
`debounce` snapshots them and re-installs them (via `defineProperty`, since `currentTarget` is a read-only
accessor) before invoking. **Any debouncing you write for Stimulus needs this.**

#### `useThrottle(controller, options)` → `void`
`static throttles = [...]`, `wait` default 200. Leading-edge only, no trailing call, no params
preservation (unnecessary — it fires synchronously). Note `constructor.throttles?.forEach` is
optional-chained while debounce's is not, so `useDebounce` with no `static debounces` **throws**.

#### `useMemo(controller)` → `void`
`static memos = ['getterName']`. **Rewritten in 0.53.0 to be lazy.** Two techniques worth teaching:

```ts
const findDescriptor = (controller, name) => {          // walks the prototype chain
  let prototype = Object.getPrototypeOf(controller)
  while (prototype && prototype !== Object.prototype) {
    const descriptor = Object.getOwnPropertyDescriptor(prototype, name)
    if (descriptor) return descriptor
    prototype = Object.getPrototypeOf(prototype)
  }
}

Object.defineProperty(controller, name, {
  configurable: true,
  get(this: Controller) {
    const value = getter.call(this)
    Object.defineProperty(this, name, { value, configurable: true })   // self-replace with a data property
    return value
  }
})
```

Prototype-chain walking matters because Stimulus apps commonly have
`ApplicationController → BaseController → MyController`. The self-overwriting descriptor means zero
overhead after the first read. Only `get` accessors are memoized; plain methods are silently skipped.

#### `useMeta(controller, { suffix = true })` → `void`
`static metaNames = ['user-id', 'feature_flags']` → `this.userIdMeta`, `this.featureFlagsMeta`, plus a
`this.metas` object. Values are typecast via `JSON.parse`-with-fallback, so `"42"` → Number,
`"true"` → Boolean, `'{"a":1}'` → Object, `"joe@doe.com"` → String. Getters are **live** (they re-query
`document.head` on every access), so a meta tag swapped by Turbo is picked up immediately.

#### `useTransition(controller, options)` → `[enter, leave, toggleTransition]`
Marked **Beta**. Defaults
`{ transitioned: false, hiddenClass: 'hidden', preserveOriginalClass: true, removeToClasses: true }`,
plus `enterActive`/`enterFrom`/`enterTo`, `leaveActive`/`leaveFrom`/`leaveTo`, `leaveAfter`.

Different mechanic again — it **wraps your methods rather than `disconnect`**:

```ts
const controllerEnter = controller.enter?.bind(controller)

async function enter(event?: Event) {
  if (controller.transitioned) return       // idempotent
  controller.transitioned = true
  controllerEnter && controllerEnter(event) // your hook runs FIRST
  // … class choreography …
}

Object.assign(controller, { enter, leave, toggleTransition })
```

So after the mixin runs, `this.enter()` *is* the transition, and your own `enter()` became a pre-hook.

The choreography is the Vue/Alpine algorithm, written out — this is the piece to study if we build our
own headless `transition` controller (vocabulary item #10):

```ts
addClasses(element, initialClasses)       // from-state
removeClasses(element, stashedClasses)    // drop overlapping originals
addClasses(element, activeClasses)        // duration/easing, held for the whole phase
await nextAnimationFrame()                // let the browser PAINT the from-state
removeClasses(element, initialClasses)
addClasses(element, endClasses)           // to-state → the transition actually runs here
await afterTransition(element)            // wait computed transitionDuration
removeClasses(element, activeClasses)
if (removeEndClasses) removeClasses(element, endClasses)
addClasses(element, stashedClasses)       // restore originals
```

```ts
async function nextAnimationFrame() {
  return new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)))
}

async function afterTransition(element: Element): Promise<number> {
  return new Promise(resolve => {
    const duration =
      Number(getComputedStyle(element).transitionDuration.split(',')[0].replace('s', '')) * 1000
    setTimeout(() => resolve(duration), duration)
  })
}
```

Two techniques: the **double `requestAnimationFrame`** (one frame is not enough — the browser must
commit the from-state styles before the to-state can animate), and **duration read from computed style**
so the CSS remains the single source of truth. Class names can come from JS options,
`data-transition-enter-from`, or Alpine-style `data-transition-enter-class`, in that precedence order.

#### `useDispatch(controller, options)` → instance ⚠️ **deprecated**
Superseded by Stimulus 3's native `this.dispatch()`. Migration:

```diff
- this.dispatch('add', { quantity: 1 })
+ this.dispatch('add', { detail: { quantity: 1 } })
```

The one thing lost is the automatic `detail.controller` (sender identity). Event names are compatible —
both produce `item:add`.

#### `useApplication(controller, { overwriteDispatch = true })` / `ApplicationController`
Adds `isPreview` (checks `data-turbo-preview` **and** `data-turbolinks-preview`), `isConnected`,
`csrfToken`, and `metaValue(name)`.

```ts
Object.defineProperty(controller, 'isPreview', {
  get(): boolean {
    return document.documentElement.hasAttribute('data-turbolinks-preview') ||
           document.documentElement.hasAttribute('data-turbo-preview')
  }
})

Object.defineProperty(controller, 'isConnected', {
  get(): boolean {
    return !!Array.from(this.context.module.connectedContexts).find(c => c === this.context)
  }
})
```

`isConnected` reaches into Stimulus internals (`context.module.connectedContexts`) — private API.
Pass `overwriteDispatch: false` to keep Stimulus' native `dispatch`.

#### `useHotkeys(controller, options)` — from `'stimulus-use/hotkeys'`
**Not** exported from the main entrypoint; the main `useHotkeys` is a deliberately **throwing stub**
that tells you to import from `stimulus-use/hotkeys`, so `hotkeys-js` stays out of the tree-shakeable
main bundle. Nice packaging technique in itself.

Accepts two option shapes, normalised by a `!options.hotkeys` sniff ("shape-coercing options"):

```js
this.hotkeys = useHotkeys(this, {
  hotkeys: {
    '/':     { handler: this.focusSearch },
    'cmd+k': { handler: this.focusSearch },
    esc:     { handler: this.blurSearch, options: { keyup: true, keydown: false } }
  },
  filter: e => !['INPUT', 'TEXTAREA'].includes(e.target.tagName) || e.key === 'Escape'
})
```

Handlers are `.bind(this.controller)`, so `this` is the controller. It keeps a `registrations` array of
exact `{hotkey, scope, callback}` triples so `hotkeys.unbind` removes **only this controller's** handler —
critical when several controllers register the same key. Caveat: `hotkeys.filter` is a **global** on the
hotkeys-js singleton, so the last controller to set it wins.

**vs. Stimulus's built-in key filters:** stimulus-use/hotkeys gives you lenient matching, scopes, a
global input filter, and runtime bind/unbind. Stimulus's `keydown.ctrl+k` is exact-match, has no scope
concept, and cannot be suspended. For a command palette, use the mixin; for a local `esc` on a dialog,
use the built-in.

### 10.6 Reference tables

| Mixin | Returns | Callbacks | Adds | Events |
|---|---|---|---|---|
| `useIntersection` | `[observe, unobserve]` | `appear`, `disappear` | `isVisible()`, `allVisible()`, `noneVisible()`, `oneVisible()`, `atLeastOneVisible()`, `intersectionElements` | `appear`, `disappear` |
| `useLazyLoad` | `[observe, unobserve]` | `loading(src)`, `loaded(src)` | `isLoading`, `isLoaded` | — |
| `useResize` | `[observe, unobserve]` | `resize(rect)` | — | `resize` |
| `useWindowResize` | `[observe, unobserve]` | `windowResize({w,h,event})` | — | — |
| `useHover` | `[observe, unobserve]` | `mouseEnter`, `mouseLeave` | — | `mouseEnter`, `mouseLeave` |
| `useClickOutside` | `[observe, unobserve]` | `clickOutside(event)` | — | `click:outside` |
| `useIdle` | `[observe, unobserve]` | `away`, `back` | `isIdle` | `away`, `back` |
| `useVisibility` | `[observe, unobserve]` | `visible`, `invisible` | `isVisible` (bool) | `visible`, `invisible` |
| `useWindowFocus` | `[observe, unobserve]` | `focus`, `unfocus` | `hasFocus` | `focus`, `unfocus` |
| `useMatchMedia` | `[observe, unobserve]` | `is[N]`, `not[N]`, `[n]Changed` | — | `is:[n]`, `not:[n]`, `[n]:changed` |
| `useMutation` | `[observe, unobserve]` | `mutate(entries)` | — | `mutate` |
| `useTargetMutation` ⚠️ | `[observe, unobserve]` | `[t]TargetAdded/Removed/Changed` | — | — |
| `useDebounce` | `void` | wraps `static debounces` | — | — |
| `useThrottle` | `void` | wraps `static throttles` | — | — |
| `useMemo` | `void` | wraps `static memos` getters | — | — |
| `useMeta` | `void` | reads `static metaNames` | `[n]Meta` getters, `metas` | — |
| `useTransition` | `[enter, leave, toggleTransition]` | `enter`, `leave`, `toggleTransition` (pre-hooks) | `enter()`, `leave()`, `toggleTransition()`, `transitioned` | — |
| `useDispatch` ⚠️ | instance | — | `dispatch(name, detail)` | — |
| `useApplication` | `void` | — | `isPreview`, `isConnected`, `csrfToken`, `metaValue()` | — |
| `useHotkeys` | instance | your handlers | — | — |

**Event detail shapes — verified against source, docs are wrong in four places:**

| Event | Actual `event.detail` | Docs |
|---|---|---|
| `appear` / `disappear` | `{ controller, entry, observer }` | ✅ |
| `click:outside` | `{ controller, originalEvent }` | ✅ |
| `away` / `back` | `{ controller }` (+ `originalEvent`) | ✅ |
| `resize` | `{ controller, entry }` | ✅ |
| `mutate` | `{ entries }` | ✅ |
| `mouseEnter` / `mouseLeave` | `{ hover: false }` **in both cases** | ❌ |
| `visible` / `invisible` | `{ isVisible, originalEvent? }` | ❌ docs say `{ event, isVisible }` |
| `focus` / `unfocus` | `{ hasFocus }` | ❌ docs say `{ event, hasFocus }` |
| `is:[n]` / `not:[n]` / `[n]:changed` | `{ name, media, matches, originalEvent? }` | ❌ docs say `event` |

**Which mixins patch `disconnect`:** `useIntersection`, `useLazyLoad`, `useResize`, `useWindowResize`,
`useHover`, `useClickOutside`, `useIdle`, `useVisibility`, `useWindowFocus`, `useMatchMedia` (only if
`window.matchMedia` exists), `useMutation`, `useTargetMutation`, `useHotkeys`.
**Which don't** (nothing to tear down): `useDebounce`, `useThrottle`, `useMemo`, `useMeta`,
`useTransition`, `useDispatch`, `useApplication`.

**Composition order rules:**
1. Observer mixins are order-independent for cleanup; the one applied **last** tears down **first**.
2. Apply `useDebounce`/`useThrottle` before mixins that will invoke the wrapped methods.
   (`useTransition` captures `controller.enter?.bind(controller)` **eagerly**, so order genuinely matters there.)
3. **Name collisions are real and silent.** `useIntersection` installs `isVisible` as a *function*;
   `useVisibility` and `useLazyLoad` install it as a *boolean*. Composing any two corrupts one.
4. Prefer `initialize()` over `connect()` to avoid stacking `disconnect` wrappers across Turbo cache cycles.

### 10.7 Write your own mixin — the template

```js
// mixins/use_scroll_direction.js
const defaultOptions = { threshold: 5, dispatchEvent: true, eventPrefix: true }

export const useScrollDirection = (controller, options = {}) => {
  const { threshold, dispatchEvent, eventPrefix } = Object.assign({}, defaultOptions, options)
  const targetElement = options.element || controller.element

  let lastY = window.scrollY
  let direction = null

  const onScroll = event => {
    const y = window.scrollY
    if (Math.abs(y - lastY) < threshold) return
    const next = y > lastY ? "down" : "up"
    lastY = y
    if (next === direction) return
    direction = next

    controller.scrollDirection = direction                                    // 1. state
    method(controller, "scrollDirectionChanged").call(controller, direction)  // 2. optional callback
    if (dispatchEvent) {                                                      // 3. namespaced event
      const name = composeEventName("scroll:direction", controller, eventPrefix)
      targetElement.dispatchEvent(extendedEvent(name, event, { controller, direction }))
    }
  }

  const observe   = () => window.addEventListener("scroll", onScroll, { passive: true })
  const unobserve = () => window.removeEventListener("scroll", onScroll)

  const controllerDisconnect = controller.disconnect.bind(controller)         // 4. THE MECHANIC
  Object.assign(controller, {
    scrollDirection: null,
    disconnect() { unobserve(); controllerDisconnect() }
  })

  observe()                                                                   // 5. start eagerly
  return [observe, unobserve]
}
```

**The five obligations of a well-behaved Stimulus mixin:**

1. Merge options over a module-level `defaultOptions` with `Object.assign({}, defaultOptions, options)` —
   never mutate the caller's object.
2. Resolve `targetElement` as `options.element || controller.element`.
3. Call optional controller callbacks through a no-op-returning `method()` helper, always with
   `.call(controller, …)`.
4. Dispatch a `composeEventName`-namespaced `extendedEvent` from `targetElement`, gated on `dispatchEvent`.
5. Capture `controller.disconnect.bind(controller)` **before** overwriting it, run your teardown first,
   then delegate. Start observing eagerly, return `[observe, unobserve]`.

### 10.8 What this means for crosswire

Every mixin here is **also expressible as a headless controller** (§13). `useClickOutside` ↔ a
`click-outside` controller that dispatches `click-outside:clicked`. `useIntersection` ↔ an `intersection`
controller. The trade-off:

| | Mixin (`useX(this)`) | Headless controller |
|---|---|---|
| Composed in | JavaScript | **HTML** |
| Visible in the template | no | **yes** |
| Requires editing the consumer's JS | **yes** | no |
| Can add targets/values/classes | **no** (with `Object.assign`) | yes |
| Multiple independent configs on one element | awkward | natural |

Given crosswire's stated bias — behaviour visible in the markup, "almost like pseudocode" — **headless
controllers should be the default and mixins the exception.** Reserve mixins for cross-cutting concerns
that every controller needs (`usePreventMorph`, `useDebounce`) rather than for user-facing behaviour.

---

<a name="11-prior-art"></a>
## 11. Prior art: controller libraries and opinionated writing

### 11.1 Stimulus Components — `stimulus-components.com`

The closest existing thing to what crosswire wants to be, and the best evidence for what a
"controller vocabulary" looks like in practice. Maintained by Guillaume Briday and contributors;
site copyright reads 2026. **Distribution model: one npm package per component**
(`@stimulus-components/clipboard`, `@stimulus-components/dropdown`, …), each independently versioned.
Most of the packages last published around **March 2024** during the scoped-package migration — actively
curated, but individually quiet.

The full catalog (32 components), grouped by the crosswire taxonomy:

| Category | Components |
|---|---|
| **Headless behaviours** | Auto Submit · Clipboard · Hotkey · Prefetch · Reveal · Sound · Scroll To · Textarea Autogrow · Content Loader · Remote Rails |
| **Disclosure / overlay** | Dialog (native `<dialog>`) · Dropdown · Popover · Lightbox · Notification · Read More · Confirmation |
| **Form** | Character Counter · Checkbox Select All · Password Visibility · Rails Nested Form · Color Picker · Places Autocomplete · Speech Recognition |
| **Scroll / viewport** | Scroll Progress · Scroll Reveal |
| **Display / formatting** | Animated Number · Timeago · Glow |
| **List** | Sortable · Carousel |
| **Third-party wrapper** | Chartjs |

**What to learn from it:**
- The overlap with my §13 list is high and independently arrived at — Auto Submit, Clipboard, Hotkey,
  Reveal, Dialog, Popover, Character Counter, Checkbox Select All, Content Loader, Scroll To, Sound,
  Timeago, Scroll Reveal. That convergence is a good signal the vocabulary is real.
- **Per-component packages** is a real design decision worth copying or explicitly rejecting. Pro: consumers
  install only what they use, and each component versions independently. Con: 32 packages to maintain, and
  cross-component composition (Dropdown + Click Outside) becomes a dependency graph.
- Several entries are **third-party wrappers** (Chartjs, Places Autocomplete, Color Picker, Speech
  Recognition) rather than primitives. Those are the ones that age badly and that morphing breaks. I'd
  keep them out of a v1.
- The only cross-library composition anywhere in the 32 packages is `dropdown` and `notification`
  importing **`useTransition` from stimulus-use**. No outlets, no shared base class, no internal events
  between components. Each package is an island.

**Three naming traps, all of which will bite:**
1. Packages were renamed from unscoped (`stimulus-carousel`) to scoped **`@stimulus-components/*`** between
   Feb and Mar 2024. **Three were never migrated** and remain unscoped: `stimulus-glow`,
   `stimulus-places-autocomplete`, `stimulus-textarea-autogrow`.
2. **The npm package literally named `stimulus-components` is dead** — v3.0.0, last published 2020-10-14,
   depends on the pre-Hotwired `stimulus@^1.1.1`. Do not install it.
3. **The RubyGem `stimulus-components` (v1.0.0, Apr 2026) is an unrelated third-party gem** by a different
   author with ~266 total downloads, despite claiming to package "over 25 Stimulus controllers." Name
   collision only. Don't let it into a Gemfile.

Registration is per-component; ESM + UMD builds; documented for bundlers, importmaps
(`bin/importmap pin @stimulus-components/x`), Sprockets and CDN:

```js
import CharacterCounter from "@stimulus-components/character-counter"
application.register("character-counter", CharacterCounter)
```

Representative APIs, for calibration on how much configuration a shipped controller carries:
- `sortable`: `static values = { resourceName: String, paramName: { default: "position" },
  responseKind: { default: "html" }, animation: Number, handle: String, method: { default: "patch" } }`
- `checkbox-select-all`: `static targets = ["checkboxAll", "checkbox"]`,
  `static values = { disableIndeterminate: Boolean, ignoreDisabled: Boolean }`, and it uses
  `checkboxTargetConnected/Disconnected` — the reactive-target pattern from §4.3.
- `dropdown`: `static targets = ["menu", "button"]`, no values, `useTransition(this, { element: this.menuTarget })`,
  syncs `aria-expanded`.

### 11.2 tailwindcss-stimulus-components — `excid3/tailwindcss-stimulus-components`

**v6.1.4, published 2026-06-03 — the most recently updated controller library in the ecosystem.**
Chris Oliver / GoRails. Ten controllers, 780 lines total:

```
 29  alert.js          52  autosave.js       44  color_preview.js
157  dropdown.js       56  modal.js          73  popover.js
 55  slideover.js     123  tabs.js           36  toggle.js
145  transition.js  ← not a controller
```

The most instructive thing in the whole ecosystem is that **`transition.js` is a plain exported module,
not a controller and not a mixin**:

```js
export { default as Alert }    from './alert.js'
// …
export { transition } from "./transition.js"     // ← a function, sitting among the controllers
```

```js
// toggle.js — 36 lines, composes the transition module
import { transition } from "./transition.js"

export default class extends Controller {
  static targets = ['toggleable']
  static values  = { open: { type: Boolean, default: false } }

  toggle()  { this.openValue = !this.openValue; this.animate() }
  hide()    { this.openValue = false;           this.animate() }
  show()    { this.openValue = true;            this.animate() }

  // Sets open to value of checkbox or radio
  toggleInput(event) { this.openValue = event.target.checked; this.animate() }

  animate() {
    this.toggleableTargets.forEach(target => transition(target, this.openValue))
  }
}
```

That is Pattern D5 (plain collaborator) applied to the hardest shared concern in the whole vocabulary.
`alert`, `modal`, `dropdown`, `popover`, `slideover` and `toggle` all import it. **Five controllers share
one animation engine with no inheritance, no mixin, and no coupling** — the module is a pure function of
`(element, state)`.

Its transition class names come from `data-transition-*` attributes on the element rather than from
`static classes`, which is a deliberate trade: the module can't use the Classes API (it isn't a
controller), so it reads the dataset directly.

```html
data-transition-enter="transition-all ease-in-out duration-300"
data-transition-enter-from="bg-opacity-0"
data-transition-enter-to="bg-opacity-80"
data-transition-leave="transition-all ease-in-out duration-300"
data-transition-leave-from="bg-opacity-80"
data-transition-leave-to="bg-opacity-0"
```

Note the divergence from stimulus-use's `useTransition`, which reads `data-transition-enter-from` **and**
Alpine's `data-transition-enter-class`. Three libraries, three near-identical attribute schemes.
**If crosswire ships a transition controller it should pick one of these two conventions rather than
inventing a third.**

`alert.js` is also a clean model for vocabulary item #9 (`dismiss`):

```js
static values = { dismissAfter: Number, showDelay: { type: Number, default: 0 } }

connect() {
  setTimeout(() => enter(this.element), this.showDelayValue)
  if (this.hasDismissAfterValue) {                       // optional feature via has…Value
    setTimeout(() => this.close(), this.dismissAfterValue)
  }
}

close() { leave(this.element).then(() => this.element.remove()) }
```

…though note it leaks: neither timer is cleared in `disconnect()`.

### 11.3 The opinionated writing, annotated

**[Writing better StimulusJS controllers](https://boringrails.com/articles/better-stimulus-controllers/)**
— Matt Swanson, Boring Rails, **2020-06-01**. ⚠️ Pre-Outlets, pre-mature-Values, pre-morphing, uses
Turbolinks — **and still the foundational text.** Everything written since is elaboration.

> "Stimulus is not React. React is not Stimulus. Stimulus works best when we let the server do the
> rendering."

Controllers should be **"small, generic, and composable."** He names the failure mode (one controller per
page or per section) and its three causes: over-specificity, misapplied React component-thinking, and
jQuery refugees who never adopted ES6 idioms.

His **two-level model** is worth stealing wholesale:

> "Level one is an opinionated, more modern version of jQuery… **Level two is a set of behaviors you can
> use to quickly build interactive sprinkles.**"

Most teams never reach level two, and that is the entire problem crosswire exists to solve. His payoff
demo recombines three trivial controllers (`toggle`, `filters`, `checkbox-list`) into a new feature:

> "Each individual controller is simple and easy to implement but they can be combined to create more
> complicated behaviors." … **"New feature, but no new JavaScript! The dream!"**

The concrete refactor shown is `classList.toggle("hidden")` → `classList.toggle(data.get("class"))`.
In 2026 you'd write that as `static classes = ["toggle"]`; **the idea is intact, the API in the post is
obsolete.** Also uses `data-target="toggle.content"` (Stimulus 1/2) and `Turbolinks.clearCache()`.

**[Taking the most out of Stimulus.js](https://thoughtbot.com/blog/taking-the-most-out-of-stimulus)**
— Matheus Richard, thoughtbot, **2022-07-26**. The best modern restatement; seven named practices each
with a refactor. It converts a page-bound `PinsController` into a domain-free `ClipboardController`, and
frames the whole discipline as a question:

> "think in terms of **behaviors** in our apps. Which kinds of behaviors do we want them to have?"

On events (our Pattern B1):

> "we not only avoided violating the single-responsibility principle, but we were able to **compose
> behaviors without writing new code**."

Its seven: general-purpose controllers · event-based composition via `dispatch` · the third-party
**wrapper pattern** (wrap Tippy.js so you can swap it for Floating UI without touching a template) ·
Values for parameterisation · actions over `addEventListener` · Classes API to decouple JS from CSS
(*especially* valuable under Tailwind) · prefer vanilla JS over dependencies. Explicitly frames the design
as **Unix philosophy — small, focused, composable tools**, with Stimulus as "the last 10–20%" and Turbo as
the reactivity engine. Note it landed four months *before* Outlets shipped and is silent on them.

**[A decoupled approach to relaying events between Stimulus controllers](https://justin.searls.co/posts/a-decoupled-approach-to-relaying-events-between-stimulus-controllers/)**
— Justin Searls, **2024-08-18**. The best 2024 idea; see Pattern B6. Coins "tightly decoupled" and argues
that Outlets are still coupling.

**[Two Tips for Reusable UI with Stimulus](https://www.thegnar.com/blog/two-tips-for-reusable-ui-with-stimulus)**
— Erik Cameron, The Gnar Company, 2025-08-20 (updated 2026-02-05). See §11.3 below and Pattern B3.

**[Building Basecamp project stacks with Hotwire](https://dev.37signals.com/building-basecamp-project-stacks-with-hotwire/)**
— Nicklas Ramhöj Holtryd, 37signals, **2023-11-07**. The only 37signals *prose* about controller design,
and it's thin — but the code confirms everything in §12: ~37 lines, one interaction, `#private` methods vs
public actions, endpoint URLs in data attributes not JS.

⚠️ **Caveat on 37signals sourcing:** there is no canonical DHH/37signals essay on Stimulus controller
design. Their public position is expressed through the handbook, scattered code in posts like this, and
the general "vanilla Rails is plenty" stance. Anyone quoting "the 37signals Stimulus style guide" is
quoting a third-party reconstruction. (The `marckohlbrugge/37signals-skills` repo that surfaces in searches
is explicitly **unofficial**.) **The Writebook and Campfire source in §12 is the real primary evidence.**

**Rails Designer** — the mechanical style-guide complement to the design essays:
- [How to Properly Structure Stimulus Controller](https://railsdesigner.com/proper-stimulus-controllers/)
  (2024-03-21, upd. 2025-12-29): **public methods only for actions** — *"Only add the functions for the
  actions that you create (ie. those that are fired based on event listeners)"*; true privacy via
  `#`-prefixed methods, not underscores; getters for value transformation; and a **fixed member order**
  — lifecycle → public actions → value-change callbacks → private helpers → getters. 37signals' production
  code independently uses the same `#private` convention; this has consensus.
- [Smarter Use of Stimulus' Action Parameters](https://railsdesigner.com/smarter-action-parameters/)
  (2025-07): collapses N near-identical methods into one parameterised method — see Pattern in §7.5.
  ```js
  updateSetting({ params: { key }, currentTarget }) {
    this[`${key}Value`] = valueFrom(currentTarget)
  }
  ```
- [Stimulus Features You (Didn't) Know](https://railsdesigner.com/lesser-known-stimulus-features/)
  (2024-11-28): inventory of under-used API surface — existential properties across all four APIs
  (*the* mechanism for optional features), target connect/disconnect callbacks, action modifiers,
  multi-class spread, nested scope isolation, `shouldLoad`, `afterLoad`.
- [Communicating Between Stimulus Controllers Using Outlets API](https://railsdesigner.com/communication-between-stimulus-controllers/)
  (2024-05-23): the gotcha it hammers — *"Outlet names must be the same as the controller name"* — people
  have "lost hours" on this.

**[Dynamic forms with Stimulus](https://thoughtbot.com/blog/dynamic-forms-with-stimulus)** — Sean Doyle,
thoughtbot, 2022-02-01. Doyle authored the Turbo morph-events PR. His principles: treat the document as
the single source of truth; semantic HTML first (`<fieldset>`, radio, `<select>`); *"route browser-based
events and infer application state from the document"*; and **ARIA as the wiring** — `aria-controls`
establishes the control↔dependent relationship and doubles as the controller's addressing mechanism.
Read alongside its companion [Dynamic forms with Turbo](https://thoughtbot.com/blog/dynamic-forms-with-turbo)
(the same feature with *zero* Stimulus) as the "do you even need a controller" counterpoint.

⚠️ On the premise that "thoughtbot has a strong accessible/reusable Stimulus series": **that series is
thinner than its reputation.** It's Doyle 2021–22 + Richard 2022 + the morphing post (2024). thoughtbot's
Stimulus tag today is dominated by Superglue (React+Rails) posts. Nothing new since 2024.

**[Composable Stimulus Controllers?](https://dev.to/adrienpoly/composable-stimulus-controllers-2i9h)**
and [Introducing Stimulus-use](https://dev.to/adrienpoly/introducing-stimulus-use-composable-behaviors-for-your-controllers-mlc)
— Adrien Poly, May 2020. The diagnosis that launched the mixin ecosystem:

> "**the missing ability to compose multiple simple behavior within a controller has been a major obstacle
> of adoption.**"

Explicitly modelled on React hooks / react-use, adapted to a class-based world. Ships two composition
modes deliberately (mixin + base class) because single-behavior cases want inheritance and multi-behavior
cases want mixins.

**[Hotwire or a frontend framework?](https://radan.dev/articles/hotwire-or-frontend-framework)** —
Radan Skorić (2024-01-16, upd. 2026-07-11). The scoping question that should precede any controller
design: *"Understand where is the complexity and only then find the best tool for the job."* Shared-state
complexity → Hotwire. Rich visual-interaction complexity → a frontend framework. His endorsed middle
ground: *"A mostly Hotwire app with small self contained single page applications embedded in the pages."*
Don't force a generic Stimulus controller to do a job that wants React.

**[betterstimulus.com](https://betterstimulus.com/)** — Julian Rubisch (StimulusReflex core), with
contributions from leastbad, Adrien Poly, Chris Oliver, geetfun. Content source at
`github.com/julianrubisch/better-stimulus`. **18 knowledge-base articles in 9 categories + 5 cookbook
recipes.** Covered throughout §9 and §17. Last substantive content commit **Feb 2025**; only 3 of 23
pages touched in 2025. It has no Naming, Directory-structure, Testing, Anti-patterns or Cheatsheet
section, despite what its reputation suggests.

Its five best ideas, in order:
1. The ***is a* / *acts as a* / *has a*** decision heuristic for inheritance vs mixin vs composition.
2. **Configurable Controllers** — inject CSS classes/selectors/IDs so the controller is reusable.
3. **Targetless Controllers** — don't mix "acts on `this.element`" with "acts on targets"; that's
   divergent change. Its newest article (Feb 2025) and its sharpest.
4. **State in values, not instance fields** — more correct in 2026 than when written, because morphing
   rewards DOM-resident state.
5. The **Dark Mode + Radio Dropdown** recipe pair: two generic controllers that emit `dark-mode:change`
   and `radio-dropdown:change` and are wired to each other purely through `data-action`. Neither imports
   the other. If you model one thing from the site, model this pair.

**Caveats — five "Good" examples on the live site are broken as published:**
- *State Management*: `this.markersValue.push(…)` does not fire `markersValueChanged` (in-place mutation).
- *Targetless Controllers*: `this.indicatorTarget = "Saving..."` (missing `.textContent`).
- *Open-Closed*: three `export default`s in one file; `super.setup()` with no base implementation.
- *Dependency Inversion*: `await import()` returns a module namespace, not a class instance.
- *Global Error Handler*: `export default class extends ApplicationController` inside
  `application_controller.js`; undefined `metaValue`.

**And five pages are outdated:**
- `/interaction/callbacks` — a **jQuery** message bus, pre-Outlets. Fully superseded. Biggest liability.
- `/error_handling/global-error-handler` — Webpacker `packs/` + `require.context`; badged "Updated for Stimulus 2".
- `/integrating-libraries/lifecycle` — **Stimulus 1** target syntax (`data-target="easymde.field"`).
- `/turbo/teardown` — relies on private `application.controllers`; pre-morphing worldview.
- `/dom_manipulation/template` — SemanticUI/Bootstrap framing; `<dialog>` is the answer now.

**[Two Tips for Reusable UI with Stimulus](https://www.thegnar.com/blog/two-tips-for-reusable-ui-with-stimulus)**
— Erik Cameron, The Gnar Company, 2025-08-20 (updated 2026-02-05). **The most current and most useful
piece I found.** Two arguments:
1. Outlets identify controllers *by class*, so with several instances of the same component on a page you
   cannot address one of them. Use targets + custom events instead.
2. Replace the class-derived event prefix with a configurable **channel** value (`prefix: this.channelValue`),
   so `country:select` and `state:select` come from two instances of the same generic `select` controller.
   See Pattern B3 — this is the single best idea in the recent literature.

**[Hotwire best practices for Stimulus](https://dev.to/phawk/hotwire-best-practices-for-stimulus-40e)**
— Pete Hawkins, 2021-10-15. Old (pre-Outlets, pre-morph) but the *philosophy* is exactly ours:
> "keep things generic" rather than creating application-specific controllers.

His worked controllers are `ToggleController` (with `useClickOutside`), `AutoSubmitController`,
`DisplayEmptyController` (using `useMutation` to show/hide an empty state when a Turbo Stream changes a
list — a genuinely clever trick), `FlashController`, `HovercardController`. And the closing line:
> "Try to rely on Turbo frames or streams to do the heavy lifting… you should really be avoiding writing
> stimulus controllers unless absolutely necessary."

⚠️ Uses `Rails.fire()` (UJS-era) — replace with `requestSubmit()`.

**[Turbo morphing woes](https://thoughtbot.com/blog/turbo-morphing-woes)** — Matheus Richard, thoughtbot,
2024-12-11. The canonical writeup of what morphing breaks and the two escape hatches
(`data-turbo-permanent`, `turbo:before-morph-attribute` + `preventDefault()`). Covered in §14.3.
Its conclusion — morphing needs careful, scenario-specific adoption rather than a global switch — is
the right posture.

**[How I test Stimulus controllers](https://dimiterpetrov.com/blog/how-i-test-stimulus-controllers/)**
— Dimiter Petrov, 2024-07-02. Argues *against* jsdom fixture tests for application code: extract logic
into plain classes, unit-test those, and cover the rest with 1–2 Capybara system tests. Correct for apps;
**inverted for us**, since our controllers *are* the product (§15.4).

**Where the literature is thin.** Across everything I read, nobody has written seriously about:
composition *catalogues* (named patterns with trade-offs), morph-safe controller design, testing a
controller *library* as opposed to an app, or the "controller vocabulary" idea as an explicit design goal.
The Gnar post is the closest, and it's two tips long. **That gap is crosswire's opportunity.**

### 11.4 Ecosystem health check (2026-08)

| Project | Latest | Verdict |
|---|---|---|
| `stimulus-use` | 0.53.0 (2026-06-30) | Healthy but bursty; single maintainer; deprecating toward core |
| `tailwindcss-stimulus-components` | 6.1.4 (2026-06-03) | **Healthiest**; small, focused, current |
| `@stimulus-components/*` | mostly 2024-03 | Curated, broad, individually quiet |
| `betterstimulus.com` | content frozen Feb 2025 | Still the best writing; verify code before copying |
| `el-transition` | 0.0.7 (2020-09) | **Dead.** Do not depend on it |
| `@hotwired/stimulus-webpack-helpers` | 1.0.1 (2021-09) | **Legacy.** Webpacker era |
| `@hotwired/stimulus` | 3.2.2 (2023-08) | Frozen API. Good for us; watch for a successor |
| `@stimulus-components/*` monorepo | pushed 2026-08-15 | Repo itself is very much alive even where packages are quiet |
| `@symfony/stimulus-testing` | archived 2025-07-05 | **Dead.** Copy its two helpers locally |
| `mrujs` | **zero published releases** | Dormant; its problem space is absorbed by Turbo Drive |
| `stimulus-lsp` / `stimulus-parser` | active | Marco Roth; the highest-leverage tooling in the ecosystem |

### 11.5 Sources that are actively wrong — do not copy

| Item | Why |
|---|---|
| npm `stimulus-components` v3.0.0 | 2020, depends on pre-Hotwired `stimulus@^1.1.1` |
| RubyGem `stimulus-components` v1.0.0 | Unrelated third-party name collision |
| `@symfony/stimulus-testing` | Archived 2025-07-05 |
| betterstimulus `/interaction/callbacks` | Entirely jQuery, pre-Outlets |
| `stimulus` npm package (unscoped) | Replaced by `@hotwired/stimulus` in 3.0 (Sept 2021); stimulus-lsp flags it |
| stimulus-use `useDispatch` | Deprecated for native `this.dispatch()`; signature changed |
| PascalCase controller identifiers ([dev.to/gambala, 2020](https://dev.to/gambala/semantic-naming-in-stimulus-js-23ac)) | Contradicts official kebab-case; breaks stimulus-lsp and every generator |
| `data-turbo-morph` | **Does not exist.** The opt-outs are `data-turbo-permanent` and cancelling `turbo:before-morph-element` |
| Karma (as used by Stimulus itself) | Deprecated by its maintainers in 2023 |

Link hygiene: **radanskoric.com now 301s to radan.dev**, and **Hotwire Weekly archive URLs return HTTP 410**
for older issues — don't cite them as durable sources.

---

<a name="12-real-world-37signals"></a>
## 12. Real-world evidence: 37signals Writebook & Campfire

Both ONCE apps are public:
`github.com/basecamp/writebook` and `github.com/basecamp/once-campfire`.
This is the most valuable prior art available — it's how the people who invented Stimulus actually write it.

### 12.1 Shape of the codebases

**Writebook**, 24 controllers, 960 lines total. Median controller: **17 lines.**

```
  7  auto_submit          7  autoremove          9  scroll_to_highlight
 13  autoselect          13  dialog             15  dependent_checkbox
 17  form                17  hotkey             18  lightbox
 19  fullscreen          20  reading_progress   20  upload_preview
 23  sidebar             23  toc_view           25  copy_to_clipboard
 32  edit_mode           36  web_share          43  popover
 54  touch               59  autosave           67  reading_tracker
403  arrangement   ← the one big app-specific controller
```

**Campfire**, 35 controllers. Same shape: a long tail of 7–35 line generic controllers plus a handful of
large domain controllers (`messages`, `composer`, `notifications`).

**Observations:**
- Overwhelmingly **small and targetless**. The 7-line controllers are the majority pattern, not the exception.
- **No `ApplicationController` base class.** Both apps' `application.js` is the stock generated file.
- **No mixins, no stimulus-use.** Shared behaviour lives in plain modules under `helpers/` and `models/`.
- **Very light outlet usage** — exactly one outlet across Writebook's 24 controllers.
- **Heavy `dispatch` + `@window` action usage** for cross-controller coordination (Campfire: 12 dispatch sites).
- **Private fields and private methods everywhere** (`#timer`, `#save()`, `get #dirty()`), a strong
  public/private boundary that doubles as documentation of the controller's API.
- `static classes` used for *every* CSS class. I found no hardcoded class strings.

### 12.2 The canonical tiny controllers

```js
// campfire toggle_class_controller.js — the single most reusable controller in either codebase
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static classes = [ "toggle" ]

  toggle() {
    this.element.classList.toggle(this.toggleClass)
  }
}
```

```html
<aside id="sidebar" data-controller="toggle-class" data-toggle-class-toggle-class="open">
  <button class="btn sidebar__toggle" data-action="toggle-class#toggle">…</button>
</aside>
```

```js
// element_removal_controller.js (campfire) / autoremove_controller.js (writebook)
export default class extends Controller {
  remove() { this.element.remove() }
}
```

```erb
<%# composed with a native CSS-animation event — no timer, no custom event %>
<div class="flash" data-controller="element-removal" data-action="animationend->element-removal#remove">
```

```js
// auto_submit_controller.js — identical in both apps
export default class extends Controller {
  connect() { this.element.requestSubmit() }
}
```

```js
// autoselect_controller.js (writebook) — feature-detects off a native attribute
export default class extends Controller {
  connect() { if (this.autoselect) this.element.select() }
  get autoselect() { return this.element.autofocus }
}
```

```js
// dialog_controller.js (writebook) — the whole modal implementation
export default class extends Controller {
  static targets = [ "dialog" ]
  open()  { this.dialogTarget.showModal() }
  close() { this.dialogTarget.close() }
}
```

```erb
data-action="keydown.ctrl+space@document->dialog#open keydown.esc->dialog#close"
```

```js
// drop_target_controller.js (campfire) — headless behaviour, output is an event
export default class extends Controller {
  dragenter(event) { event.preventDefault() }
  dragover(event)  { event.preventDefault(); event.dataTransfer.dropEffect = "copy" }
  drop(event)      { event.preventDefault(); this.dispatch("drop", { detail: { files: event.dataTransfer.files } }) }
}
```

```js
// touch_controller.js (writebook) — gesture recogniser; emits, never acts
export default class extends Controller {
  #swipedLeft()  { this.dispatch("swipe-left") }
  #swipedRight() { this.dispatch("swipe-right") }
}
```

`drop-target` and `touch` are the purest examples of the **headless behavioural controller**: they detect
something and dispatch. All policy lives in the markup that listens.

### 12.3 Classes-as-state-machine

```js
// writebook autosave_controller.js (abridged)
export default class extends Controller {
  static classes = [ "clean", "dirty", "saving" ]
  #timer

  disconnect() { this.submit() }              // flush on the way out

  async submit() { if (this.#dirty) await this.#save() }

  change(event) {
    if (event.target.form === this.element && !this.#dirty) {
      this.#scheduleSave()
      this.#updateAppearance()
    }
  }

  #updateAppearance(saving = false) {
    this.element.classList.toggle(this.cleanClass,  !this.#dirty)
    this.element.classList.toggle(this.dirtyClass,   this.#dirty)
    this.element.classList.toggle(this.savingClass,  saving)
  }

  get #dirty() { return !!this.#timer }
}
```

Three logical class names, all injected. The controller is completely design-system agnostic, and
`get #dirty()` derives state from the timer rather than storing a duplicate flag.

### 12.4 The one outlet

```js
// writebook edit_mode_controller.js
export default class extends Controller {
  static values  = { targetUrl: String }
  static classes = [ "editing" ]
  static outlets = [ "autosave" ]

  async change({ target: { checked } }) {
    if (!checked) await this.#submitAutosaveControllers()
    setCookie("edit_mode", checked)
    Turbo.visit(this.targetUrlValue)
  }

  async #submitAutosaveControllers() {
    for (const autosave of this.autosaveOutlets) await autosave.submit()
  }
}
```

```erb
data: { edit_mode_autosave_outlet: "[data-controller='autosave']" }
```

The outlet earns its place because the coordinator must **await** each autosave before navigating —
something a fire-and-forget event cannot express.

### 12.5 The window event bus in production

```erb
<%# campfire app/views/users/sidebars/show.html.erb %>
data-action="rooms-list:unread@window->badge-dot#update
             rooms-list:read@window->badge-dot#update
             turbo:submit-start->turbo-frame#unpermanize"
```

```erb
<div id="direct_rooms" data-controller="sorted-list"
     data-action="rooms-list:unread@window->sorted-list#updateItem">
```

One publisher (`rooms-list`), two unrelated generic subscribers (`badge-dot`, `sorted-list`), wired
entirely in ERB. Neither subscriber knows the publisher exists.

### 12.6 Shared helper modules

```js
// writebook + campfire: app/javascript/helpers/timing_helpers.js
export function throttle(fn, delay = 1000) { /* … */ }
export function debounce(fn, delay = 1000) { /* … */ }
export function nextFrame()            { return new Promise(requestAnimationFrame) }
export function nextEventLoopTick()    { return delay(0) }
export function onNextEventLoopTick(cb){ setTimeout(cb, 0) }
export function nextEventNamed(name, el = window) {
  return new Promise(resolve => el.addEventListener(name, resolve, { once: true }))
}
export function delay(ms) { return new Promise(resolve => setTimeout(resolve, ms)) }
```

```js
// campfire: helpers/dom_helpers.js — the DOM-move guard
export function ignoringBriefDisconnects(element, fn) {
  requestAnimationFrame(() => { if (!element.isConnected) fn() })
}
```

crosswire should ship an equivalent `helpers/` module. `nextFrame`, `debounce`, `throttle` and
`ignoringBriefDisconnects` are load-bearing across the whole library.

Both apps expose these directories through the importmap alongside controllers, which is what makes
`import { throttle } from "helpers/timing_helpers"` work inside a controller:

```ruby
# campfire config/importmap.rb
pin "@hotwired/stimulus",         to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/initializers", under: "initializers"
pin_all_from "app/javascript/lib",          under: "lib"
pin_all_from "app/javascript/channels",     under: "channels"
pin_all_from "app/javascript/controllers",  under: "controllers"
pin_all_from "app/javascript/helpers",      under: "helpers"
pin_all_from "app/javascript/models",       under: "models"
```

Both apps **eager load** (`eagerLoadControllersFrom`) despite having 24–35 controllers.

Even the outlier — Writebook's 403-line `arrangement_controller.js`, a full drag-and-drop reorder
implementation — keeps the discipline: `static classes = [ "cursor", "selected", "placeholder",
"addingMode", "moveMode" ]`, `static values = { url: String }`, and eight `#private` fields. Not one
hardcoded class name or URL, even in the app-specific code.

### 12.7 Turbo Stream custom actions live alongside controllers

```js
// writebook app/javascript/actions/scroll_into_view.js
import { Turbo } from "@hotwired/turbo-rails"

Turbo.StreamActions.scroll_into_view = function() {
  const animation = this.getAttribute("animation")
  const element = this.targetElements[0]
  element.scrollIntoView({ behavior: "smooth", block: "center" })
  if (animation) {
    element.addEventListener("animationend", () => element.classList.remove(animation), { once: true })
    element.classList.add(animation)
  }
}
```

A reminder that **not every behaviour needs to be a controller.** A custom Turbo Stream action is often the
right unit when the server is the one deciding something should happen.

---

<a name="13-generic-controller-vocabulary"></a>
## 13. Generic Controller Vocabulary — candidates for our library

Design contract for every entry:

- **Targetless if possible.** Acts on `this.element` unless it genuinely coordinates children.
- **No literal CSS class strings.** Every class comes from `static classes`.
- **No literal selectors, URLs, or durations.** Everything from `static values` / action params.
- **Emits before/after events**, `cancelable` where a veto makes sense.
- **Accepts an optional `channel` value** to override the dispatch prefix (Pattern B3).
- **Cleans up in `disconnect()`**, guarded by `ignoringBriefDisconnects` where teardown is expensive.

| # | Identifier | Contract |
|---|---|---|
| 1 | `toggle-class` | classes `toggle`; actions `toggle/add/remove`; params `class`. Toggles injected classes on `this.element`. |
| 2 | `toggle` | values `open:Boolean`; targets `panel[]`, `trigger[]`; classes `open`,`closed`; emits `toggle:opened`/`closed`. Reactive via `openValueChanged`. |
| 3 | `disclosure` | as `toggle` + ARIA (`aria-expanded`, `aria-controls`); values `open`. Prefer `<details>` when no animation is needed. |
| 4 | `dialog` | targets `dialog`; actions `open/close/toggle`; emits `dialog:opened`/`closed`. Thin wrapper over `<dialog>.showModal()`. |
| 5 | `popover` | targets `menu`; classes `orientationTop`; actions `open/close/toggle/closeOnClickOutside`. Flip-on-overflow positioning. |
| 6 | `clipboard` | values `content:String`; targets `source`; classes `success`; values `resetAfter:Number`; emits `clipboard:copied`, cancelable `clipboard:copy`. |
| 7 | `auto-submit` | values `delay:Number`(0); actions `submit`; submits `this.element` (a form) via `requestSubmit()`, debounced. |
| 8 | `element-removal` | actions `remove`; values `delay:Number`; classes `leaving`. Removes `this.element`, optionally after a leave class + `animationend`. |
| 9 | `dismiss` | targets `dismissable`; classes `leaving`; values `after:Number`; emits `dismiss:dismissed`. Auto-dismiss flashes/toasts. |
| 10 | `transition` | classes `enter`,`enterFrom`,`enterTo`,`leave`,`leaveFrom`,`leaveTo`; actions `enter/leave/toggle`; values `duration:Number`. Headless enter/leave engine. |
| 11 | `hotkey` | values `key:String`; actions bound via `keydown.*@document`; clicks/focuses `this.element` when the chord fires; skips when focus is in an input. |
| 12 | `debounce` / `throttle` | values `wait:Number`; action `call`; re-dispatches `debounce:fired` after the interval. A rate-limiter you compose in front of anything. |
| 13 | `autosave` | classes `clean`,`dirty`,`saving`; values `interval:Number`; flushes in `disconnect()`; emits `autosave:saved`. |
| 14 | `autoselect` | no config; `select()`s `this.element` on connect when `autofocus` is present. |
| 15 | `autofocus` | values `delay:Number`, `preventScroll:Boolean`; focuses on connect, preview-aware. |
| 16 | `scroll-into-view` | values `behavior:String`(smooth), `block:String`(center), `selector:String`; scrolls on connect after `nextFrame()`. |
| 17 | `maintain-scroll` | anchors scroll position across Turbo Stream renders; action `beforeStreamRender`. |
| 18 | `sorted-list` | targets `item[]`; values `key:String`, `direction:String`; re-sorts on `itemTargetConnected` (throttled). |
| 19 | `filter` | targets `list`,`input`; classes `active`,`selected`; values `attribute:String`, `delay:Number`. Client-side filtering by data attribute. |
| 20 | `poll` | values `url:String`, `interval:Number`, `visibleOnly:Boolean`; refreshes `this.element` (frame or innerHTML); pauses when hidden. |
| 21 | `content-loader` | values `url:String`, `lazy:Boolean`; params `url`; loads HTML into `this.element`. Params make one instance serve many sources. |
| 22 | `intersection` | values `threshold:Number`, `rootMargin:String`, `once:Boolean`; classes `visible`; emits `intersection:appear`/`disappear`. |
| 23 | `visibility` | emits `visibility:visible`/`hidden` from the Page Visibility API; action-only, no DOM effect. |
| 24 | `media-query` | values `query:String`; classes `match`; emits `media-query:matched`/`unmatched`. |
| 25 | `click-outside` | emits `click-outside:clicked`; values `dismissOn:String`. Composes with `popover`/`dialog` rather than duplicating the logic. |
| 26 | `character-count` | targets `input`,`counter`; values `max:Number`; classes `nearLimit`,`overLimit`. |
| 27 | `dependent-fields` | targets `controller`,`dependent[]`; values `showWhen:String`; toggles `hidden`/`disabled` on dependents. |
| 28 | `checkbox-select-all` | targets `all`,`item[]`; values `count:Number`(out); emits `checkbox-select-all:changed`. |
| 29 | `drop-target` | actions `dragenter/dragover/drop`; classes `dragging`; emits `drop-target:drop` with `{ files }`. Headless. |
| 30 | `upload-preview` | targets `input`,`preview[]`,`template`; renders object URLs; revokes them in `disconnect()`. |
| 31 | `local-time` | values `format:String`, `datetime:String`; rewrites `<time>` to the viewer's locale/timezone on connect. |
| 32 | `web-share` | values `title`,`text`,`url`; hides `this.element` when `navigator.canShare` is absent. |
| 33 | `fullscreen` | targets `button`; removes the button when unsupported; action `toggle`. |
| 34 | `sound` | values `src:String`, `volume:Number`; action `play`; a tiny audio trigger. |
| 35 | `form-status` | classes `submitting`,`success`,`error`; listens to `turbo:submit-start`/`turbo:submit-end` on `this.element`. |
| 36 | `turbo-frame` | actions `reload`,`load`(param `url`),`unpermanize`; imperative control of an enclosing frame. |
| 37 | `confirm` | values `message:String`; action `check:prevent`; cancelable `confirm:confirmed`. Replaces `data-turbo-confirm` when you need custom UI. |
| 38 | `reveal-on-scroll` | classes `revealed`; values `threshold:Number`, `once:Boolean`. Thin sugar over `intersection`. |
| 39 | `relay` | action `forward`; forwards a caught event to `[data-relay-events*="..."]` within its subtree. Scoped event bus (Pattern B6). |
| 40 | `preserve` | values `attributes:String`(glob), `element:Boolean`; cancels `turbo:before-morph-element` / `-attribute`. **The morph-safety primitive.** |
| 41 | `beacon` | values `url:String`, `payload:Object`; POSTs once on connect then `this.element.remove()`. Self-destructing genre (B7). |
| 42 | `grab-focus` | values `selector:String`, `preventScroll:Boolean`; focuses once then removes itself. |

That's ~42 — trim to the ~30 that earn their keep. My cut list for a v1: **1–17, 20–25, 27–30, 32, 35, 37,
39, 40.** `transition` (10), `toggle` (2), `intersection` (22) and `preserve` (40) are the four that most
need careful design because everything else composes on top of them.

**`preserve` (40) deserves special attention.** It is the one primitive the framework, every ecosystem
library, and the entire literature have left unbuilt (§14.3): stimulus#801 proposed it and was closed;
Evil Martians hand-rolled `data-turbo-morph-permanent-attrs`; thoughtbot documents the raw event listeners.
Shipping a clean, documented version would be crosswire's most differentiated contribution.

Note the "self-destructing" genre (41, 42, plus `scroll-into-view` when used as a one-shot) has a different
contract from the rest: **no `disconnect()`, no reuse, `<template>` markup.** Worth calling out as its own
category in the docs so people don't try to compose them.

**Naming convention proposal:** verb-or-noun, kebab-case, no app prefix, no `-controller` suffix in the
identifier. Namespace only when a controller is genuinely a variant family (`form--autosubmit`), and prefer
flat names otherwise — `--` identifiers are verbose in markup and collapse confusingly in JS property names.

---

<a name="14-stimulus--turbo"></a>
## 14. Stimulus + Turbo: frames, streams, caching, morphing

### 14.1 The three render paths

| Path | What happens to controllers |
|---|---|
| **Turbo Drive visit** | `<body>` is replaced → every controller disconnects, new instances connect. |
| **Turbo Frame navigation** | the frame's children are replaced → controllers inside the frame disconnect; controllers *on* or *outside* the frame survive. |
| **Turbo Stream render** | only the targeted element's subtree changes → surgical disconnect/connect. |
| **Turbo 8 morph refresh** | idiomorph patches in place → **controllers whose element survives are NOT disconnected/reconnected.** |

That last row is the one that breaks assumptions.

### 14.2 Cache previews

Turbo caches a snapshot before navigating away and shows it as a preview on a restoration visit. So a
single navigation can run `connect()` **twice**: once against the stale snapshot, once against the fresh body.

```js
get isPreview() {
  return document.documentElement.hasAttribute("data-turbo-preview")
}

connect() {
  if (this.isPreview) return
  this.startExpensiveThing()
}
```

And to keep transient state out of the cache:

```js
document.addEventListener("turbo:before-cache", () => {
  // reset anything that would look wrong when replayed from cache
})
```

betterstimulus.com's "Global Teardown" recipe generalises this into an opt-in `teardown()` hook —
see Pattern C3, and note it relies on the private `application.controllers`.

#### The idempotency discipline (and the "dead DOM" trap)

The sharpest statement of this anywhere is, oddly, in the
[Contao developer docs](https://docs.contao.org/5.x/dev/internals/_stimulus-backend/). Four rules:

1. **Idempotent transformations** — "applying the code multiple times does not do any harm." Cache entries
   are created *before* DOM removal, so `disconnect()` cleanup cannot affect cached content. Guard with a
   `data-initialized` attribute, or restore/remove before caching.
2. **Cleanup before caching** — a `beforeCache()` hook, or mark ephemera `data-turbo-temporary`.
3. **Restore external resources in `disconnect()`** — parent CSS classes, sibling elements, listeners bound
   outside your own element. "always assume that this can happen at any time."
4. **Prefer `data-action` over `addEventListener`.** Window bindings persist across Turbo Drive navigation.

Rule 1 has a corollary that is **the most under-appreciated sentence in this whole subject**, and it is a
full day's debugging if you don't know it:

> when you detect an already-transformed state and skip the transform, "**the DOM you are looking at is
> basically dead. It was restored from cache, so there are no event listeners or live objects.**"

So an idempotency guard must skip the **DOM work** but still **reattach the listeners**:

```js
connect() {
  if (!this.element.dataset.initialized) {
    this.buildDOM()                       // expensive, skip on a cache restore
    this.element.dataset.initialized = "true"
  }
  this.attachListeners()                  // ALWAYS — the restored nodes are inert
}
```

⚠️ Contao's own examples use an underscore-prefix private-method convention; use `#private` fields instead
(§12 — 37signals and Rails Designer both do).

### 14.3 Morphing (Turbo 8+)

```html
<meta name="turbo-refresh-method" content="morph">
<meta name="turbo-refresh-scroll"  content="preserve">
```

```html
<turbo-stream action="refresh" method="morph" scroll="preserve"></turbo-stream>
<turbo-frame id="my-frame" refresh="morph" src="/my_frame"></turbo-frame>
```

#### Why some controllers survive a morph and others don't — the ID-set algorithm

This is the single most important mechanical fact about Stimulus under Turbo 8, and it is documented
nowhere official. Radan Skorić reverse-engineered it in
[Turbo 8 morphing deep dive: the idiomorph algorithm](https://radan.dev/articles/turbo-morphing-deep-dive-idiomorph)
(2023-12-19, updated 2026-07-11).

Idiomorph preprocesses both DOM trees and builds a map from each parent to the set of `id`s beneath it:

> "For each element with the `id` property it walks its parent chain until it reaches the top level node
> and along the way adds its id value to the Set of ids."

Matching then prefers "an element that overlaps in at least one id from the ID map."

**The operational consequence:**

| | Element **has** a stable unique `id` | Element has **no** `id` |
|---|---|---|
| Idiomorph | matches it and patches **in place** | far more likely to remove + re-insert |
| DOM node | survives | replaced |
| Stimulus | `disconnect()`/`connect()` **never fire** | full disconnect + connect cycle |
| Controller instance | **survives with all in-memory state** | destroyed, fresh instance |

So: **whether your controller keeps its instance state across a morph is decided by whether you put an
`id` on the element.** Skorić's practical advice — put `id`s on all real content, use Rails' `dom_id`.

The corollary for a controller library is uncomfortable: **the same controller behaves differently
depending on markup you don't control.** A `chart` controller holding a Chart.js instance works fine on an
element with `dom_id(@report)` and silently leaks/reinitialises on one without. This is the strongest
argument for the crosswire rule "state lives in values, not instance fields" — it makes the distinction
stop mattering.

Radan Skorić's root-cause framing, from
[How to avoid problems with Turbo morphing](https://radan.dev/articles/how-to-avoid-problem-with-turbo-morphing)
(2025-02-05, updated 2026-04-18) — the cleanest statement of the problem anywhere:

> "**Part of the new state is in the browser and morphing causes problems by forcing it to match server
> state.**"

His three solution families, in escalating order of correctness:
1. **Tell Turbo to leave it alone** — `data-turbo-permanent` (needs a unique `id`), or cancel
   `turbo:before-morph-element` / `turbo:before-morph-attribute`.
2. **Limit the scope** — targeted Turbo Streams with `method="morph"`, or `refresh="morph"` frames.
3. **Align server state with browser state** — persist UI state to the DB/session, or encode it in URL
   params (bonus: shareable links that preserve UI config).

Only (3) actually makes controllers *more* reusable, because it removes hidden instance state entirely.

And Jorge Manrubia (37signals) on the design intent,
[A happier happy path in Turbo with morphing](https://dev.37signals.com/a-happier-happy-path-in-turbo-with-morphing/)
(2023-10-09):

> "the improvement came from **keeping client-side state**: scroll, focus, selected text, CSS transition
> states, etc."

Idiomorph was chosen specifically because it **avoids requiring IDs throughout the DOM** — which is exactly
the property that makes Stimulus lifecycle behaviour unpredictable. The convenience and the footgun are
the same design decision.

**What survives a morph:**
- The element identity (so `initialize()` doesn't re-run, and `connect()`/`disconnect()` do **not** fire).
- Any instance state on the controller (`this.chart`, `this.#timer`, closures).

**What gets clobbered:**
- **Attributes are morphed to match the server's HTML** — which means `data-…-value` attributes are
  overwritten with whatever the server rendered. Client-side value changes are lost, and `valueChanged`
  fires with the server's value. See [hotwired/turbo#1210](https://github.com/hotwired/turbo/issues/1210)
  ("Turbo morph not preserving stimulus values").
- Any DOM a third-party library mutated in place (see
  [hotwired/turbo#1083](https://github.com/hotwired/turbo/issues/1083)).

**The nasty case:** a JS library mutated the DOM, the morph reverts it, but because the element was never
removed and re-added, `disconnect()`/`connect()` never fire — so the controller has no idea it needs to
re-initialise. This is the core of
[thoughtbot: Turbo morphing woes](https://thoughtbot.com/blog/turbo-morphing-woes) (Matheus Richard, 2024-12-11).

**Morph lifecycle events** (from [hotwired/turbo#1097](https://github.com/hotwired/turbo/pull/1097), seanpdoyle):

| Event | Cancelable | Use |
|---|---|---|
| `turbo:before-morph-element` | yes | `preventDefault()` to leave this element untouched |
| `turbo:before-morph-attribute` | yes | `event.detail.attributeName` — veto a single attribute |
| `turbo:morph-element` | no | fired for every morphed node; re-initialise here |
| `turbo:morph` | no | fired once per morph, on `document` |

**Pattern: protect an attribute from being morphed** (thoughtbot's `<details>` example):

```js
export default class extends Controller {
  preventToggle(event) {
    const { attributeName } = event.detail
    if (attributeName === "open") event.preventDefault()
  }
}
```

```html
<details data-controller="details"
         data-action="turbo:before-morph-attribute->details#preventToggle">
```

**Pattern: protect the whole controller element**
(from [hotwired/stimulus#801](https://github.com/hotwired/stimulus/issues/801), closed without a built-in API):

```js
export default class extends Controller {
  connect() {
    this.element.addEventListener("turbo:before-morph-element", this.#preventMorph)
  }
  disconnect() {
    this.element.removeEventListener("turbo:before-morph-element", this.#preventMorph)
  }
  #preventMorph = (event) => { if (event.target === this.element) event.preventDefault() }
}
```

Better as a **mixin** (`usePreventMorph(this)`), which is exactly what the issue asked Stimulus to ship and
it declined. Strong candidate for crosswire: a `preserve` controller / `usePreventMorph` mixin.

The API that *should* exist, per the closed issue: `preventElementMorph()`,
`preventElementMorph({ target: 'button' })`,
`preventAttributeMorph({ classContains: 'is-active' })`,
`preventAttributeMorph({ target: 'button', classContains: 'is-loading' })`.

**Pattern: stop a morph from wiping your values** — the community workaround for the still-open
[turbo#1210](https://github.com/hotwired/turbo/issues/1210):

```js
preserveValues(event) {
  const { attributeName } = event.detail
  if (attributeName.startsWith("data-") && attributeName.endsWith("-value")) {
    event.preventDefault()
  }
}
```

```html
<div data-controller="wizard preserve-values"
     data-action="turbo:before-morph-attribute->preserve-values#preserveValues">
```

Evil Martians hit the same wall on a production fintech wizard and **invented their own
`data-turbo-morph-permanent-attrs` attribute** to generalise it
([The Hotwire-Rails summit](https://evilmartians.com/chronicles/hotwire-rails-summit-interactive-multi-step-forms-peak-ux),
2025-06-24). Their other finding is directly relevant to us: **many third-party Stimulus controllers were
not morphing-ready** and had to be patched.

> **This is the sharpest unresolved tension in the whole field.** Every best-practice source says "keep
> state in the DOM via the Values API." Morphing can wipe exactly those attributes and skip `connect()`.
> The framework-level fix was proposed (stimulus#801) and closed without a maintainer response. **A
> standardised morph-safety primitive is probably the single highest-value thing crosswire could ship** —
> it is the one gap the framework, every ecosystem library, and the entire literature have all left open.

**Pattern: re-initialise a third-party widget after a morph:**

```html
<div data-controller="tom-select" data-action="turbo:morph@window->tom-select#reconnect"></div>
```

**Rule of thumb for morph-safety:** a controller whose entire state lives in **values** is morph-safe by
construction (the server re-asserts the truth). A controller holding state in instance fields is not.
This makes betterstimulus.com's "state belongs in values" advice *more* correct in 2026 than when written.

Known open issue worth tracking:
[hotwired/turbo#1224](https://github.com/hotwired/turbo/issues/1224) — Stimulus does not consistently
disconnect/reconnect across repeated form submissions on a morphing page (reported 2024-03-17, closed
without a fix; reporter's workaround was to disable morphing on those pages).

### 14.4 `data-turbo-permanent`

Marks an element to be carried across renders untouched. The controller inside is **not** disconnected on a
Drive visit, which is the point — but it also means:

- `connect()` will not re-run, so anything you keyed to `connect()` is stale.
- Under morphing, `data-turbo-permanent` opts the subtree out of the morph entirely.
- Campfire has a controller action specifically to *remove* the attribute at the right moment:

```js
// campfire turbo_frame_controller.js
unpermanize() { delete this.element.dataset.turboPermanent }
```

```erb
data-action="turbo:submit-start->turbo-frame#unpermanize"
```

### 14.5 Memory-leak checklist for `disconnect()`

Anything created in `connect()` must be destroyed in `disconnect()`, because `connect()` re-runs on every
DOM move and every Turbo render:

- [ ] `window` / `document` listeners → **prefer `@window` / `@document` actions**, which Stimulus unbinds for you
- [ ] `setTimeout` / `setInterval` → `clearTimeout` / `clearInterval`
- [ ] `IntersectionObserver` / `ResizeObserver` / `MutationObserver` → `.disconnect()`
- [ ] ActionCable subscriptions → `.unsubscribe()` (wrapped in `ignoringBriefDisconnects`)
- [ ] `AbortController` for `fetch` → `.abort()`
- [ ] Object URLs from `URL.createObjectURL` → `URL.revokeObjectURL`
- [ ] Third-party instances (charts, maps, editors, selects) → their `.destroy()` / `.toTextArea()`
- [ ] `requestAnimationFrame` loops → `cancelAnimationFrame`

The **`AbortController` signal pattern** collapses all listener cleanup into one line:

```js
connect() {
  this.abortController = new AbortController()
  const { signal } = this.abortController
  window.addEventListener("scroll", this.onScroll, { signal })
  document.addEventListener("keydown", this.onKey, { signal })
}

disconnect() {
  this.abortController.abort()
}
```

This also sidesteps the classic `.bind()` bug that betterstimulus.com warns about:

```js
// BROKEN — .bind() returns a NEW function each call, so removal silently fails
connect()    { document.addEventListener("click", this.findFoo.bind(this)) }
disconnect() { document.removeEventListener("click", this.findFoo.bind(this)) }
```

The modern alternatives, in order of preference:
1. a `@window`/`@document` **action** in the markup (Stimulus manages it),
2. `AbortController` + `{ signal }`,
3. a class-property arrow function: `onScroll = () => { … }`,
4. a stored bound reference: `this.boundFindFoo = this.findFoo.bind(this)`.

### 14.6 `turbo:load` vs `DOMContentLoaded`

Never wire Stimulus behaviour to either. `DOMContentLoaded` fires once per full page load and not on Turbo
visits; `turbo:load` fires on visits but not on Stream renders or morphs. `connect()` is the only hook that
fires for *all* of them. Chris Oliver's betterstimulus article makes exactly this point about third-party
library setup:

> "Using Stimulus lifecycle events allows you to make most Javascript libraries compatible with Turbo
> without additional effort… Stimulus creates separate instances automatically which also saves you from
> maintaining an array of active instances that need to be torn down later."

---

<a name="15-testing"></a>
## 15. Testing Stimulus controllers

### 15.1 The framework's own harness — the pattern worth copying

`[SOURCE]` `src/tests/cases/`. Stimulus tests its own controllers with a small hierarchy:
`TestCase → DOMTestCase → ApplicationTestCase → ControllerTestCase`.

```ts
// dom_test_case.ts — the essentials
export class DOMTestCase extends TestCase {
  fixtureSelector = "#qunit-fixture"
  fixtureHTML = ""

  async renderFixture(fixtureHTML = this.fixtureHTML) {
    this.fixtureElement.innerHTML = fixtureHTML
    return this.nextFrame
  }

  get nextFrame(): Promise<any> {
    return new Promise((resolve) => requestAnimationFrame(resolve))
  }

  async triggerEvent(selectorOrTarget, type, options = {}) { /* dispatch + await nextFrame */ }
  async setAttribute(selectorOrElement, name, value)       { /* set + await nextFrame */ }
  async appendChild(selectorOrElement, child)              { /* append + await nextFrame */ }
  async remove(selectorOrElement)                          { /* remove + await nextFrame */ }
}
```

```ts
// application_test_case.ts — errors THROW instead of being swallowed
export class TestApplication extends Application {
  handleError(error: Error, _message: string, _detail: object) { throw error }
}

export class ApplicationTestCase extends DOMTestCase {
  async runTest(testName: string) {
    try {
      this.application = new TestApplication(this.fixtureElement, this.schema)
      this.setupApplication()
      this.application.start()
      await super.runTest(testName)
    } finally {
      this.application.stop()
    }
  }
  setupApplication() {}   // override to register controllers
}
```

```ts
// controller_test_case.ts
export class ControllerTests<T extends Controller> extends ApplicationTestCase {
  identifier: string | string[] = "test"
  controllerConstructor!: ControllerConstructor
  fixtureHTML = `<div data-controller="${this.identifiers.join(" ")}">`

  setupApplication() {
    this.identifiers.forEach(id => this.application.register(id, this.controllerConstructor))
  }
  get controller(): T { return this.controllers[0] }
  get controllers(): T[] { return this.application.controllers as any }
}
```

**The four ideas to steal:**
1. **Override `handleError` to throw.** Otherwise Stimulus swallows every error in your controller and your
   test passes while the controller is broken. This is the single most important testing tip.
2. **Scope the `Application` to the fixture element**, not `document.documentElement`, so tests are isolated
   and `application.stop()` really cleans up.
3. **`await nextFrame()` after every DOM mutation.** Stimulus connects on a microtask after a
   MutationObserver callback; a `requestAnimationFrame` await is the reliable barrier.
4. Register the *same* controller class under multiple identifiers to test multi-instance / outlet scenarios.

### 15.2 A modern vitest + jsdom setup

```js
// vitest.config.js
export default { test: { environment: "jsdom", globals: true } }
```

```js
// test/support/stimulus.js
import { Application } from "@hotwired/stimulus"

export const nextFrame = () => new Promise(requestAnimationFrame)

export async function mount(html, controllers) {
  document.body.innerHTML = `<div id="fixture">${html}</div>`
  const root = document.getElementById("fixture")

  const application = new (class extends Application {
    handleError(error) { throw error }        // fail loudly
  })(root)

  Object.entries(controllers).forEach(([id, klass]) => application.register(id, klass))
  application.start()
  await nextFrame()

  return { application, root, teardown: () => { application.stop(); document.body.innerHTML = "" } }
}
```

```js
// test/controllers/toggle_class_controller.test.js
import ToggleClassController from "controllers/toggle_class_controller"
import { mount, nextFrame } from "../support/stimulus"

test("toggles the injected class", async () => {
  const { root, teardown } = await mount(`
    <div data-controller="toggle-class" data-toggle-class-toggle-class="open">
      <button data-action="toggle-class#toggle">x</button>
    </div>`, { "toggle-class": ToggleClassController })

  const el = root.querySelector("[data-controller]")
  root.querySelector("button").click()
  await nextFrame()
  expect(el.classList.contains("open")).toBe(true)

  teardown()
})
```

**Testing dispatched events** — the natural unit test for a headless controller:

```js
test("dispatches drop-target:drop with the files", async () => {
  const { root, teardown } = await mount(
    `<div data-controller="drop-target" data-action="drop->drop-target#drop"></div>`,
    { "drop-target": DropTargetController })

  const el = root.querySelector("[data-controller]")
  const spy = vi.fn()
  el.addEventListener("drop-target:drop", spy)

  const files = [new File(["x"], "x.txt")]
  el.dispatchEvent(Object.assign(new Event("drop"), { dataTransfer: { files } }))
  await nextFrame()

  expect(spy).toHaveBeenCalled()
  expect(spy.mock.calls[0][0].detail.files).toBe(files)
  teardown()
})
```

**Testing values as the public API** — drive the controller by writing the attribute, which is exactly how
the server would:

```js
el.setAttribute("data-slideshow-index-value", "2")
await nextFrame()
expect(/* … */)
```

**jsdom caveats:** `requestAnimationFrame` in jsdom is a `setTimeout` shim and can be flaky under vitest;
if you see intermittent failures, use `await new Promise(r => setTimeout(r, 0))` twice, or move the test to
a real browser runner. jsdom also lacks `IntersectionObserver`, `ResizeObserver`, `matchMedia`,
`navigator.clipboard`, `showModal()`, and `requestSubmit()` — you will need shims for a meaningful
fraction of the vocabulary in §13. **This is the strongest argument for running crosswire's controller
tests in a real browser** (`@web/test-runner`, Playwright component testing, or vitest's browser mode)
rather than jsdom.

### 15.3 What the framework itself does: real browsers

`[SOURCE]` `hotwired/stimulus` `package.json`:

```json
"test": "yarn build:test && karma start karma.conf.cjs"
```
```json
"karma": "^6.4.4",
"karma-chrome-launcher": "^3.2.0",
"karma-firefox-launcher": "^2.1.3",
"karma-qunit": "^4.2.1",
"qunit": "^2.20.0"
```

**Real Chrome and Firefox, not jsdom.** That is a quiet but strong endorsement: the framework's own
authors do not trust a DOM emulator to exercise MutationObserver-driven lifecycle.

⚠️ Karma itself was deprecated by its maintainers in 2023 and Stimulus hasn't migrated. Copy the
*conclusion* (real browser), not the tool — use `@web/test-runner`, Vitest browser mode, or Playwright CT.
(stimulus-use already runs Vitest 3 in browser mode via Playwright.)

### 15.4 Library status

- `@symfony/stimulus-testing` — **repo archived 2025-07-05, read-only.** Its deprecation rationale is
  itself a useful opinion: forcing Jest and "~270 sub-dependencies including Babel" was unacceptable, and
  "many test runners exist" that are "more modern and much faster." Migration path: install
  `@testing-library/jest-dom` + `@testing-library/dom` and **copy the two helpers into a local file.**
- `stimulus-jest` — unmaintained hobby project.
- [hotwire.io's "Testing Stimulus Controllers" guide](https://hotwire.io/documentation/stimulus/guides/testing-stimulus-controllers)
  **is an empty stub** — *"Apologies, but this page hasn't been created yet"* — and has been for ~3 years.
  Worth citing precisely because it's empty: **there is no community consensus document on testing
  Stimulus.** Laurence Hughes' 2020 line is still true in 2026: *"Stimulus JS is great but doesn't provide
  any documentation for testing controllers."*
- There is **no maintained official testing helper**. Roll the ~30-line `mount()` above.

The most-copied helper in circulation is
[bholtbholt's gist](https://gist.github.com/bholtbholt/c8351665a861aee62e915d8b32e2c759)
(last updated 2025-02-04):

```javascript
export function startStimulus(name, controller) {
  const application = Application.start();
  application.register(name, controller);
}

export async function setHTML(content = '') {
  document.body.innerHTML = content.trim();
  return document.body.innerHTML;
}
```

**The reason `setHTML` is `async` and returns a value is the entire trick** — *"Stimulus isn't mounted
before the test runs, so these helpers wrap the calls in async functions to fix race conditions."*
Awaiting it yields a microtask turn, letting Stimulus's MutationObserver fire `connect()` before your
assertions run. This is the single most common cause of flaky Stimulus tests.

### 15.5 Static analysis as a partial substitute for tests

Marco Roth's [stimulus-lsp](https://github.com/marcoroth/stimulus-lsp) (built on `stimulus-parser`)
catches exactly the class of bug that unit tests of reusable controllers usually catch — **wiring
errors** — but across the whole codebase, **including ERB**. Shipped diagnostics:

*In HTML:* missing controller (`stimulus.controller.invalid`), missing action
(`stimulus.action.invalid`), missing target (`stimulus.controller.target.missing`), missing value
(`stimulus.controller.value.missing`), invalid action descriptor, data-attribute format mismatch
(`stimulus.attribute.mismatch`), value type mismatch (`stimulus.controller.value.type_mismatch`).
*In JS:* value-definition default-value type mismatch, unknown value type, controller parse errors,
**imports from deprecated packages** (`stimulus.package.deprecated.import` — catches `from "stimulus"`).
Plus completions for identifiers/actions/targets/values/classes and quick-fixes that generate a missing
controller or implement a missing action.

**The argument to make explicitly:** for a *generic* controller with a documented markup contract, an LSP
that validates **every call site** is higher-leverage than a unit test that validates one. crosswire
should make sure its controllers are statically analysable — which mostly means: declare everything in
`static` blocks, never build attribute names dynamically.

### 15.6 System tests: what belongs where

Dimiter Petrov's position ([How I test Stimulus controllers](https://dimiterpetrov.com/blog/how-i-test-stimulus-controllers/),
2024-07-02) is the pragmatic one for *application* code:

> "I'm not packaging a stimulus controller. I'm using it directly in my application… mistakes typically
> occur during integration with the page itself."

His split: extract logic into plain classes and unit-test those; write 1–2 Capybara system tests for the
whole flow; treat controllers as implementation details.

**For crosswire that advice inverts.** We *are* packaging controllers. The contract (values, targets,
classes, events) is the product, so:

- **Unit test every library controller** against its declared contract, in a real browser.
- **System test the recipes** (the compositions of several controllers) in a Rails dummy app with
  Capybara + Cuprite, because that's where Turbo interaction bugs live.
- **Extract anything non-DOM into `helpers/`** and unit test it with no DOM at all.

---

<a name="16-typescript"></a>
## 16. TypeScript

Types ship inside `@hotwired/stimulus`. **There is no `@types/stimulus` to install** — don't.

```ts
import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLFormElement> {   // types this.element
  static targets = [ "input" ]
  static values  = { code: String }

  declare readonly hasInputTarget: boolean
  declare readonly inputTarget: HTMLInputElement
  declare readonly inputTargets: HTMLInputElement[]

  declare codeValue: string                    // NOT readonly — it has a setter
  declare readonly hasCodeValue: boolean

  submit() { new FormData(this.element) }
}
```

`declare` is essential: it types the property **without emitting a class field**, which would shadow the
getter/setter Stimulus installs on the prototype. For the same reason, **`useDefineForClassFields: true`
plus a non-`declare` field will silently break values and targets.**

The docs cover targets and values only. Extrapolated (correct, but not quoted from the docs) for outlets
and classes:

```ts
declare readonly hasUserStatusOutlet: boolean
declare readonly userStatusOutlet: UserStatusController
declare readonly userStatusOutlets: UserStatusController[]
declare readonly userStatusOutletElement: HTMLElement
declare readonly userStatusOutletElements: HTMLElement[]

declare readonly hasLoadingClass: boolean
declare readonly loadingClass: string
declare readonly loadingClasses: string[]
```

**Is it worth it for crosswire?** The `declare` boilerplate roughly doubles the length of a 7-line
controller, which fights the whole aesthetic. My read: ship **plain JS with JSDoc contracts** in the
controllers, and provide `.d.ts` files (or JSDoc `@typedef`s) documenting each controller's values/targets/
classes/events for consumers. Revisit if the library grows past ~40 controllers.

---

<a name="17-anti-patterns"></a>
## 17. Anti-patterns

**A1 — The page controller.** One controller per page/screen with a grab-bag of targets and methods.
betterstimulus.com:

> "it is tempting to write your controllers in a **page controller** style, resulting in a disjointed
> accumulation of unrelated functionality. Resist that temptation — try to write reusable controllers."

Tell: the identifier is a noun from your domain (`checkout`, `dashboard`, `settings`) rather than a
behaviour.

**A2 — Hardcoded CSS classes.** `this.element.classList.add("hidden")`. Instantly couples the controller to
one stylesheet. Use `static classes`.

**A3 — Hardcoded selectors, URLs, durations, keys.** Anything a second consumer would want to change must be
a value or a param.

**A4 — Mixing targetless and target-ful responsibilities.** If a controller acts on both `this.element`
*and* on targets, it probably has two reasons to change. Split it and wire the halves with an event.

**A5 — State in instance fields instead of values.** Breaks Turbo caching, breaks morphing, breaks devtools
inspection, breaks server-driven updates. Use values unless the state is non-serialisable
(a Chart.js instance) or sensitive.

**A6 — Mutating a value in place.** `this.itemsValue.push(x)` does nothing observable. Reassign.

**A7 — `connect()` as a constructor.** betterstimulus.com's "Don't Overuse connect":

> `connect` is **not** the right place for: setting up controller state (→ use values); hooking up
> additional event listeners (→ "just use the regular Stimulus DOM notation instead, as they will
> automatically clean up after themselves").

Remember `connect()` re-runs on every DOM move.

**A8 — `addEventListener` + `.bind()` in `connect`/`disconnect`.** The bound functions differ, so removal
silently fails and you register a new listener on every reconnect. Use a `@window` action, an
`AbortController`, or a stable reference.

**A9 — Reaching into another controller's internals.** `getControllerForElementAndIdentifier(...).someMethod()`
as a default. The docs call this a last resort. Prefer events; then outlets.

**A10 — Outlets in a reusable controller.** An outlet hardcodes another controller's *identifier*, which
makes the library controller un-reusable outside a context where that identifier exists. Coordinators may
use outlets; library primitives may not.

**A11 — Building DOM from JSON in a controller.** You've left Stimulus's design centre. Render on the server
(Turbo Frame/Stream) or use a real view library for that one screen.

**A12 — Reinventing `<details>`, `<dialog>`, Popover API, or CSS `:has()`.** See §9-E1.

**A13 — A `useX` mixin that doesn't chain `disconnect`.** Adds listeners that are never removed. Every mixin
must patch teardown, not just setup.

**A14 — Duplicating `valueChanged` work in `connect()`.** `valueChanged` already ran before `connect()`.
You will do the work twice.

**A15 — Assuming `hasXValue === "attribute present"` when the value has a `default:`.** It doesn't.

**A16 — Global `data-action` names that repeat the event.** `click->x#click`. Name the *outcome*.

**A17 — Depending on `application.controllers` or `application.router` in app code.** Private APIs. Isolate
in one adapter file if you must.

**A18 — Lazy-loading a controller that affects first paint.** The dynamic import lands a frame or more
later, so toggles/transitions flash. Eager-load anything that runs on connect.

**A19 — Public methods that aren't actions.** Rails Designer's rule: *"Only add the functions for the
actions that you create."* Everything else is `#private`. For a library controller the public surface **is**
the documented API — every stray public method is an accidental promise.

**A20 — An idempotency guard that also skips listener setup.** On a Turbo cache restore the DOM is inert:
"there are no event listeners or live objects." Skip the DOM work, always reattach. (§14.2)

**A21 — Relying on the element having an `id`.** Whether a controller instance survives a morph is decided
by idiomorph's ID-set matching (§14.3). A controller that only works when the consumer remembered
`dom_id(@thing)` is not a reusable controller.

**A22 — Bare `@window` for component-to-component events.** With several instances of the same component
on a page, `@window` broadcasts to all of them. Use a `channel` prefix (B3) or a `relay` (B6).

**A23 — Naming a controller after a component.** The origin doc is explicit: Stimulus "attaches itself to
an existing HTML document" — it isn't a component framework. `card`, `modal-wrapper`, `user-row` are smells;
`toggle`, `dismiss`, `clipboard` are behaviours.

---

<a name="18-gotchas"></a>
## 18. Gotchas

**Lifecycle**
1. `initialize()` once, `connect()` many. `appendChild` on an attached node is a **move** → disconnect+connect.
2. `valueChanged` fires **before** `connect()`, on **every** connect, for **every** value including defaults.
3. `outletConnected` fires after `targetConnected`, before `connect()`. `outletDisconnected` fires **after** `disconnect()`.
4. Callbacks are **microtask-deferred**. Nothing is connected on the line after you mutate the DOM.
5. MutationObservers are **paused** inside `targetConnected`/`targetDisconnected`, so adding a target from
   within the callback will not re-fire it.
6. Reading `this.xOutlets` inside `connect()` **force-connects** those controllers, nesting their entire
   `connect()` inside yours. Use `xOutletConnected` instead.

**Values**
7. Boolean decoding is `!(v == "0" || v == "false")`. `""` is **`true`**.
8. Number decoding strips `_`. Non-numeric → `NaN`, silently.
9. `hasXValue` is `true` whenever the value declares a `default:`, attribute or not.
10. Setting `undefined` removes the attribute; setting anything else writes it.
11. Declaring a `default` whose type disagrees with `type` **throws at load**.
12. In-place mutation of Array/Object values is invisible to Stimulus.

**Classes**
13. `this.xClass` returns **only the first** class. With Tailwind you almost always want `...this.xClasses`.
14. Accessing a missing class **throws** (unlike values).
15. `classList.toggle` takes one token — no built-in multi-class toggle.

**Actions**
16. `:!default` is **not a thing**. Use `:prevent`.
17. Modifier key filters are **exact** — `keydown.esc` won't fire with Shift held; `keydown.ctrl+k` won't
    fire for Ctrl+Shift+K.
18. Modifier filters also apply to **mouse** events (`click.shift`, `click.meta`).
19. `.filter` after a non-keyboard event name folds into the **event name**, not a filter.
20. `@` accepts only `window` and `document`. `@body` silently binds to the element.
21. Action params must be on the **same element** as the `data-action`, and are **namespaced by identifier**.
22. Param typecasting is `JSON.parse` with a string fallback — `"007"` and `"01234"` stay strings.
23. An unknown key filter throws at **dispatch** time, not parse time.
24. Referencing a non-existent method throws at dispatch time:
    `Action "…" references undefined method "…"`.

**Targets / scope**
25. Nesting only shields against the **same identifier**; a nested different controller provides no isolation.
26. `containsElement` uses `element.closest(controllerSelector) === this.element` — the *nearest* controller wins.
27. Singular target access **throws** when absent. `hasXTarget` first.

**Outlets**
28. Outlet selectors are matched against **`document.body`** — they are global, not scoped to the host.
29. The outlet element must **also** carry `data-controller` for that identifier.
30. Outlet property names **collapse `--`**: `admin--user-status` → `adminUserStatusOutlets`.
31. Singular outlet access throws; plural returns `[]`.

**Loading / Rails**
32. `eagerLoadControllersFrom` requires an **inline** `<script type="importmap">`. External importmap or a
    CSP that blocks inline JSON → nothing registers, silently.
33. Bundler apps must re-run `stimulus:manifest:update` (or use the generator) after adding a controller.
34. `.replace("_controller", "")` is non-global — avoid `_controller` earlier in a filename.
35. Never put a `.` in a controller filename.
36. `stimulus-loading` depends on the private `application.router.modulesByIdentifier`.

**Turbo**
37. Cache previews mean `connect()` can run **twice** per navigation, once against stale HTML.
    Detect with `document.documentElement.hasAttribute("data-turbo-preview")`.
38. **Morphing does not fire `connect`/`disconnect`** when the element survives — but it *does* overwrite
    your `data-…-value` attributes with the server's version.
39. Third-party DOM mutations are reverted by a morph with no lifecycle callback to tell you.
    Listen for `turbo:morph-element` / `turbo:morph@window`.
40. `data-turbo-permanent` prevents disconnect on Drive visits — so `connect()`-time setup goes stale.
41. `turbo:load` and `DOMContentLoaded` do not fire for Stream renders or morphs. Use `connect()`.

**Misc**
42. `handleError` swallows exceptions and merely logs them — **your tests will pass while your controller is
    broken** unless you override it.
43. `application.start()` awaits `DOMContentLoaded`; nothing connects before that.
44. `disconnect()` is *not* called on page unload, so it is not a reliable "save on exit" hook
    (Writebook's autosave calls `submit()` from `disconnect()` anyway, plus relies on Turbo).
45. **Controllers do not initialise until `DOMContentLoaded`** — `Application#start()` awaits it
    ([stimulus#815](https://github.com/hotwired/stimulus/discussions/815)). A controller near the top of a
    long page is unresponsive during initial render. Matters for anything that must work before paint
    (theme toggles, FOUC guards) — use a blocking inline script for those, not a controller.
46. Whether a controller survives a morph depends on idiomorph's **ID-set matching** — i.e. on whether the
    element has a stable `id`. Same controller, different lifecycle, depending on markup you don't control.
47. On a Turbo cache restore the restored nodes are **inert** — no listeners, no live objects — even though
    they look fully formed. An idempotency guard must still reattach listeners.
48. `stimulus-lsp` flags `import { Controller } from "stimulus"` (the unscoped package) as deprecated.
    It's `@hotwired/stimulus` since 3.0 (Sept 2021).

---

<a name="19-open-questions"></a>
## 19. Open Questions

1. **Morph-safety as a library-wide contract.** Should every crosswire controller be required to keep 100%
   of its state in values so it survives a morph? That rules out controllers wrapping stateful third-party
   widgets. Do we instead ship a `preserve` controller / `usePreventMorph` mixin and document which
   controllers need it? (Stimulus declined to build this — issue #801.)

2. **Events vs outlets as the house style.** I've proposed "library controllers emit events and never
   declare outlets." Is that too strict? The `await autosave.submit()` case in Writebook is real —
   some coordination genuinely needs a return value.

3. **The `channel` value convention.** Should *every* controller accept an optional `channel` value to
   override the dispatch prefix (Gnar's pattern)? It's uniform and solves multi-instance addressing, but
   it's a per-controller tax and an extra concept to teach.

4. **Mixins: `Object.assign` or higher-order classes?** stimulus-use and betterstimulus both use
   `Object.assign`, which cannot contribute `static targets/values/classes`. Higher-order classes can
   (confirmed from source, §9-D3 — statics merge up the prototype chain with no manual spreading).
   Do we standardise on HOCs (better, but novel) or on `useX(this)` (familiar, ecosystem-compatible)?
   Related: §10.8 argues most of what stimulus-use does as a mixin, we should do as a headless
   controller — is there *any* mixin we actually need beyond `usePreventMorph` and `useDebounce`?

5. **Do we depend on `stimulus-use` or vendor the ideas?** It's maintained (0.53.0, 2026-06) and excellent,
   but it's an extra dependency and its mixins patch lifecycle methods in a way that can surprise.
   Alternative: document the technique and ship 4–5 of our own mixins.

6. **jsdom or real browser for the test suite?** A large fraction of the §13 vocabulary needs
   `IntersectionObserver`, `matchMedia`, `<dialog>.showModal`, `requestSubmit`, `navigator.clipboard` —
   all missing or stubbed in jsdom. Real-browser testing is slower but tests the thing we ship.

7. **TypeScript?** The `declare` boilerplate is heavier than the controllers themselves. Ship JS + `.d.ts`,
   or bite the bullet?

8. **Flat vs namespaced identifiers.** 37signals keeps everything flat. Namespacing (`form--autosubmit`)
   reads better in a large library but produces verbose markup and confusing JS property names. Which?

9. **Lazy loading.** Almost certainly no for a small-controller library — but at what count does that flip?
   Is there a measurable threshold, or is it always "eager + HTTP/2"?

10. **How opinionated should the transition/animation controller be?** `el-transition` is dead (2020),
    `tailwindcss-stimulus-components` has a maintained one, stimulus-use ships `useTransition`. Do we build
    a headless enter/leave engine, or wrap CSS `@starting-style` / View Transitions, which are now widely
    supported and would let us delete most of it?

11. **Stimulus 3.2.2 has not shipped in 3 years.** Is the project effectively frozen? Is there a "Stimulus 4"?
    Worth checking Rails World 2026 talks / Marco Roth's work (stimulus-parser, hotwire.io) before we bet a
    library on an unchanging API. (Frozen API is *good* for us — but a hard fork or successor would not be.)

12. **Accessibility as a library concern.** The example `tabs` controller in the Stimulus repo manages
    `tabIndex` and focus; `@stimulus-components/dropdown` syncs `aria-expanded`; Sean Doyle uses
    `aria-controls` as the *addressing mechanism*. Should every crosswire controller own its ARIA state
    and focus trapping, or is that the consumer's job? Owning it makes the controllers much more valuable
    and much less generic.

13. **Do we ship Rails helpers alongside the controllers?** Pattern A5 argues the helper signature is the
    real public API and that a library without one forces every call site to retype six data attributes.
    But it doubles the surface area, forces a Ruby dependency on a JS library, and we'd owe ERB *and*
    Phlex *and* ViewComponent variants. Big call; probably the highest-impact one on this list.

14. **Package granularity.** stimulus-components ships 32 separate npm packages; tailwindcss-stimulus-components
    ships one with 10 exports. One package, one package per controller, or a few themed bundles?
    (Related: does crosswire ship as npm, as a Rails engine with `pin_all_from`, or both?)

15. **Is some of this a snippet library rather than a dependency?** Searls' "because it's like six lines
    long, man" is a real argument. `relay`, `element-removal`, `auto-submit` and `toggle-class` are each
    under ten lines. Would a documented, copy-pasteable cookbook serve people better than an install?
    Perhaps both: install the complex ones, copy the trivial ones.

16. **Does the library take a position on morphing?** Options: (a) assume morph-off and document the risks;
    (b) assume morph-on and make every controller morph-safe by construction; (c) ship `preserve` and let
    consumers opt in. (b) is the most valuable and the most work, and it constrains every controller to
    values-only state.

17. **Should crosswire controllers be statically analysable by design?** stimulus-lsp validates every call
    site, which is higher-leverage than unit tests for a library with a markup contract (§15.5). That
    implies a hard rule: declare everything in `static` blocks, never construct attribute names
    dynamically. Cheap to adopt now, expensive to retrofit.

---

<a name="20-source-index"></a>
## 20. Source index

**Primary — official**
- Handbook: [origin](https://stimulus.hotwired.dev/handbook/origin) · [introduction](https://stimulus.hotwired.dev/handbook/introduction) · [hello-stimulus](https://stimulus.hotwired.dev/handbook/hello-stimulus) · [building-something-real](https://stimulus.hotwired.dev/handbook/building-something-real) · [designing-for-resilience](https://stimulus.hotwired.dev/handbook/designing-for-resilience) · [managing-state](https://stimulus.hotwired.dev/handbook/managing-state) · [working-with-external-resources](https://stimulus.hotwired.dev/handbook/working-with-external-resources) · [installing](https://stimulus.hotwired.dev/handbook/installing)
- Reference: [controllers](https://stimulus.hotwired.dev/reference/controllers) · [lifecycle-callbacks](https://stimulus.hotwired.dev/reference/lifecycle-callbacks) · [actions](https://stimulus.hotwired.dev/reference/actions) · [targets](https://stimulus.hotwired.dev/reference/targets) · [outlets](https://stimulus.hotwired.dev/reference/outlets) · [values](https://stimulus.hotwired.dev/reference/values) · [css-classes](https://stimulus.hotwired.dev/reference/css-classes) · [using-typescript](https://stimulus.hotwired.dev/reference/using-typescript)
- Turbo: [page refreshes / morphing](https://turbo.hotwired.dev/handbook/page_refreshes)

**Source code read**
- `github.com/hotwired/stimulus` — `src/core/*.ts`, `src/tests/cases/*.ts`, `examples/`
- `github.com/hotwired/stimulus-rails` — `app/assets/javascripts/stimulus-loading.js`, `lib/stimulus/manifest.rb`, `lib/tasks/stimulus_tasks.rake`, `lib/generators/`
- `github.com/stimulus-use/stimulus-use` — `src/`
- `github.com/basecamp/writebook` — `app/javascript/`
- `github.com/basecamp/once-campfire` — `app/javascript/`
- `github.com/julianrubisch/better-stimulus` — content source for betterstimulus.com

**Opinionated writing — controller design**
- [Writing better StimulusJS controllers](https://boringrails.com/articles/better-stimulus-controllers/) — Matt Swanson, Boring Rails, 2020-06-01 ⭐ *foundational*
- [Self-destructing StimulusJS controllers](https://boringrails.com/articles/self-destructing-stimulus-controllers/) — Matt Swanson, 2022-06-13
- [Lightweight components with Rails helpers and Stimulus](https://boringrails.com/tips/lightweight-components-with-helpers-stimulus) — Matt Swanson
- [Taking the most out of Stimulus.js](https://thoughtbot.com/blog/taking-the-most-out-of-stimulus) — Matheus Richard, thoughtbot, 2022-07-26 ⭐
- [Two Tips for Reusable UI with Stimulus](https://www.thegnar.com/blog/two-tips-for-reusable-ui-with-stimulus) — Erik Cameron, The Gnar Company, 2025-08-20 / upd. 2026-02-05 ⭐ *most current*
- [A decoupled approach to relaying events between Stimulus controllers](https://justin.searls.co/posts/a-decoupled-approach-to-relaying-events-between-stimulus-controllers/) — Justin Searls, 2024-08-18 ⭐
- [betterstimulus.com](https://betterstimulus.com/) — Julian Rubisch et al. (18 articles + 5 recipes; content frozen Feb 2025)
- [Hotwire best practices for Stimulus](https://dev.to/phawk/hotwire-best-practices-for-stimulus-40e) — Pete Hawkins, 2021-10-15
- [Hotwire Decisions: Frames, Streams, Stimulus](https://labzero.com/blog/hotwire-decisions-when-to-use-turbo-frames-turbo-streams-and-stimulus) — Travis Gaff, Lab Zero, 2023-03-02
- [Supercharge your Stimulus controllers with Custom APIs](https://marcoroth.dev/posts/supercharge-your-stimulus-controllers-with-custom-apis) — Marco Roth, 2023-07-27
- [Composable Stimulus Controllers?](https://dev.to/adrienpoly/composable-stimulus-controllers-2i9h) / [Introducing Stimulus-use](https://dev.to/adrienpoly/introducing-stimulus-use-composable-behaviors-for-your-controllers-mlc) — Adrien Poly, May 2020
- Rails Designer: [structure](https://railsdesigner.com/proper-stimulus-controllers/) · [action params](https://railsdesigner.com/smarter-action-parameters/) · [lesser-known features](https://railsdesigner.com/lesser-known-stimulus-features/) · [outlets](https://railsdesigner.com/communication-between-stimulus-controllers/)
- [Dynamic forms with Stimulus](https://thoughtbot.com/blog/dynamic-forms-with-stimulus) / [with Turbo](https://thoughtbot.com/blog/dynamic-forms-with-turbo) — Sean Doyle, thoughtbot, Feb 2022
- [Building Basecamp project stacks with Hotwire](https://dev.37signals.com/building-basecamp-project-stacks-with-hotwire/) — 37signals, 2023-11-07
- [Turbo-compatible Stimulus controllers](https://docs.contao.org/5.x/dev/internals/_stimulus-backend/) — Contao docs (idempotency rules; pre-morphing framing)

**Morphing**
- [Turbo Handbook — Page Refreshes](https://turbo.hotwired.dev/handbook/page_refreshes) (says nothing about Stimulus)
- [Turbo morphing deep dive](https://radan.dev/articles/turbo-morphing-deep-dive) / [the idiomorph algorithm](https://radan.dev/articles/turbo-morphing-deep-dive-idiomorph) — Radan Skorić, upd. 2026-07-11 ⭐
- [How to avoid problems with Turbo morphing](https://radan.dev/articles/how-to-avoid-problem-with-turbo-morphing) — Radan Skorić, upd. 2026-04-18 ⭐
- [Turbo morphing woes](https://thoughtbot.com/blog/turbo-morphing-woes) — Matheus Richard, thoughtbot, 2024-12-11
- [A happier happy path in Turbo with morphing](https://dev.37signals.com/a-happier-happy-path-in-turbo-with-morphing/) — Jorge Manrubia, 2023-10-09
- [Interactive multi-step forms at peak UX](https://evilmartians.com/chronicles/hotwire-rails-summit-interactive-multi-step-forms-peak-ux) — Evil Martians, 2025-06-24

**Testing**
- [How I test Stimulus controllers](https://dimiterpetrov.com/blog/how-i-test-stimulus-controllers/) — Dimiter Petrov, 2024-07-02
- [bholtbholt's Jest helper gist](https://gist.github.com/bholtbholt/c8351665a861aee62e915d8b32e2c759) — upd. 2025-02-04
- [stimulus-lsp](https://github.com/marcoroth/stimulus-lsp) / [stimulus-parser](https://github.com/marcoroth/stimulus-parser) — Marco Roth

**Issues worth tracking**
- [stimulus#801](https://github.com/hotwired/stimulus/issues/801) — morph-inhibition helpers (**closed**, no API shipped)
- [turbo#1210](https://github.com/hotwired/turbo/issues/1210) — morph does not preserve Stimulus values (**still OPEN**) 🔴
- [turbo#1224](https://github.com/hotwired/turbo/issues/1224) — inconsistent disconnect/reconnect under morph (closed)
- [turbo#1083](https://github.com/hotwired/turbo/issues/1083) — JS-lib DOM mutations lost on morph
- [turbo#1351](https://github.com/hotwired/turbo/issues/1351) — `connect()` out of order with `data-turbo-permanent`
- [turbo#1097](https://github.com/hotwired/turbo/pull/1097) — introduces the `turbo:*morph*` events (Sean Doyle)
- [stimulus#815](https://github.com/hotwired/stimulus/discussions/815) — controllers don't initialise until `DOMContentLoaded`
