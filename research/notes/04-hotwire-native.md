# 04 — Hotwire Native (iOS + Android)

> Research notes for **crosswire**. Compiled 2026-08-15.
> Everything below is checked against the *current* Hotwire Native era. Advice written for
> **Turbo Native** (pre-Sept 2024) or **Strada** (Sept 2023 – Sept 2024) is flagged
> `⚠️ OUTDATED` inline wherever it survives in the wild.

## Version snapshot (2026-08-15)

| Piece | Current | Notes |
|---|---|---|
| `hotwired/hotwire-native-ios` | **1.3.1** (2026-08-14) | Swift Package. `import HotwireNative` |
| `hotwired/hotwire-native-android` | **1.3.1** (2026-07-27) | Maven `dev.hotwire:*` |
| `@hotwired/hotwire-native-bridge` (npm) | **1.2.2** (2025-08-21) | peer dep `@hotwired/stimulus ^3.2.2` |
| `turbo-rails` | **2.0.23** (2026-01-29) | ships `Turbo::Native::Navigation`. Requires Ruby ≥ 3.1, Rails ≥ 7.1 |
| `hotwire_native_rails` (gem, community) | **0.4.4** (2025-03-11) | by Yaro Shmarov. A generator, not a runtime dep. No `turbo_native_rails` gem exists. |
| *Hotwire Native for Rails Developers* | **P1.0**, Sept 2025 | Joe Masilotti, Pragmatic Bookshelf, 270pp |
| Docs | <https://native.hotwired.dev> | source: `hotwired/hotwire-native-site` |
| Canonical Rails demo | <https://github.com/hotwired/hotwire-native-demo> → <https://hotwire-native-demo.dev> | Rails 8, importmap, propshaft |

Naming history (important when reading old blog posts):

- **Turbolinks iOS/Android** → **Turbo Native** → **Hotwire Native** (announced Rails World 2024, 2024-09-25).
- **Strada** (announced 2023-09-20) → folded in as **Bridge Components**, no separate dependency.
  The JS package was `@hotwired/strada`; it is now `@hotwired/hotwire-native-bridge`.
  (`window.Strada` and `window.webBridge` are still aliased for legacy clients — see `src/index.js`.)
- `turbo_native_app?` → `hotwire_native_app?` (the old name is still an `alias_method`, not removed).

---

## Table of contents

1. [Architecture: what "native shell + web views" actually means](#1-architecture)
2. [Path configuration](#2-path-configuration)
3. [Bridge components](#3-bridge-components)
4. [Rails-side concerns](#4-rails-side-concerns)
5. [Authentication, cookies, sessions](#5-authentication-cookies-sessions)
6. [Navigation semantics](#6-navigation-semantics)
7. [Native screens and native tabs](#7-native-screens-and-native-tabs)
8. [Bridge Component Catalog](#bridge-component-catalog)
9. [Gotchas](#gotchas)
10. [Outdated-advice map](#outdated-advice-map)
11. [The book: *Hotwire Native for Rails Developers*](#the-book-hotwire-native-for-rails-developers)
12. [Implications for our library](#implications-for-our-library)
13. [Open Questions](#open-questions)
14. [Sources](#sources)

---

## 1. Architecture

### 1.1 The one-sentence version

A Hotwire Native app is a **native navigation shell** (UIKit `UINavigationController` /
AndroidX Navigation) wrapped around **a very small number of long-lived web views**, where
*tapping a link* is intercepted and turned into a *native push/present*, and the destination's
HTML is then rendered inside the web view.

From <https://native.hotwired.dev/overview/how-it-works>: the adapter, on a link tap,

1. captures a screenshot of the current page,
2. pushes or presents a new screen using native animations,
3. requests the web content for the new screen,
4. renders that content via the web view.

> "If the user navigates 'back' to a previous screen Hotwire Native will use cached
> screenshots, and because we are using native navigation controls, interactive pop
> gestures work exactly as expected."

### 1.2 The critical structural fact: there is not one web view per screen

This is the single most load-bearing implementation detail, and the docs bury it. From
`hotwire-native-ios/Source/Turbo/Navigator/Navigator.swift`:

```swift
public private(set) var session: Session
public private(set) var modalSession: Session
// ...
let session = Session(webView: Hotwire.config.makeWebView())
session.pathConfiguration = Hotwire.config.pathConfiguration

let modalSession = Session(webView: Hotwire.config.makeWebView())
modalSession.pathConfiguration = Hotwire.config.pathConfiguration
```

And `Source/Turbo/Session/Session.swift`:

```swift
public let webView: WKWebView
private lazy var bridge = WebViewBridge(webView: webView)
// ...
private func activateVisitable(_ visitable: Visitable) {
    deactivateActivatedVisitable()
    visitable.activateVisitableWebView(webView)
}

private func deactivateActivatedVisitable() {
    deactivateVisitable(visitable, showScreenshot: true)
}
```

So per `Navigator`:

- **exactly two `Session`s** — `session` (main stack) and `modalSession` (modal stack),
- **exactly two `WKWebView`s**,
- only **one screen per stack is live** at a time. Everything else on the stack is a
  `UIView` snapshot (`webView.snapshotView(afterScreenUpdates: false)`, in
  `Source/Turbo/Visitable/VisitableView.swift`) with the web view hidden behind it.

Consequences that ripple all the way back into how you write Rails views:

- **Background screens are frozen images.** They have no JS running, no Turbo Stream
  subscription that can repaint them, no timers. A screen five deep in the stack is a JPEG.
- **A modal is a *different JS realm* from the screen behind it.** Different `WKWebView`,
  different `document`, different `Turbo` instance, different Action Cable connection.
  A Turbo Stream broadcast rendered into the modal *cannot* touch the parent screen's DOM.
  This is why the "refresh the previous screen after submitting a modal form" problem
  exists at all, and why it has to be solved with a *navigation* primitive
  (`refresh_or_redirect_to`) rather than a *DOM* primitive (`turbo_stream.replace`).
- **Native tabs multiply this.** `HotwireTabBarController` gives each tab its own
  `Navigator`, hence its own pair of web views. A 4-tab app has up to 8 `WKWebView`s
  (mitigated by `lazyLoadTabs: true`). Every one of them cold-boots your JS bundle.

### 1.3 The session/adapter model

The layering, bottom-up:

```
WKWebView / android.webkit.WebView
  └── Turbo (turbo.js) running in the page
        └── window.turboNative adapter  ── JS ⇄ native message channel
              └── Session (Swift/Kotlin) — owns the web view, drives visits
                    └── Navigator — owns the UINavigationController(s), applies path config
                          └── Router / RouteDecisionHandler chain — decides in-app vs external
```

- **Turbo, in the page**, sees a `turboNative` adapter is present and hands visit proposals
  to it instead of performing them itself.
- **`Session`** translates a proposal into a `VisitProposal` carrying the URL, the
  `VisitOptions` (`action: advance|replace|restore`), and the **path-configuration
  properties** matched for that URL.
- **`Navigator`** consults the routing table (§6) and pushes/presents/pops/replaces.
- **`Router`** decides *whether the app handles the URL at all* — see
  `AppNavigationRouteDecisionHandler`, `SafariViewControllerRouteDecisionHandler` (iOS),
  `BrowserTabRouteDecisionHandler` (Android), `SystemNavigationRouteDecisionHandler`.
  Off-domain `http(s)` URLs go to SFSafariViewController / Custom Tabs; `mailto:`/`sms:`
  go to the system. This is registered, and overridable, in order:

```swift
Hotwire.registerRouteDecisionHandlers([
    AppNavigationRouteDecisionHandler(),
    MyCustomExternalRouteDecisionHandler()
])
```

There is a **second, parallel channel**: the **Bridge**. `WebViewBridge` injects the bridge
JS shim, and `window.HotwireNative.web` (the `Bridge` class in the npm package) exchanges
`{id, component, event, data}` messages with registered native `BridgeComponent`s. Bridge
messages are *out-of-band with respect to navigation* — a bridge component can put a button
in the native nav bar for the currently-visible screen without any visit happening.

### 1.4 Minimal shells

**iOS** (`SceneDelegate.swift`, from the getting-started guide) — this is the whole app:

```swift
import HotwireNative
import UIKit

let rootURL = URL(string: "https://hotwire-native-demo.dev")!

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private let navigator = Navigator(configuration: .init(
        name: "main",
        startLocation: rootURL
    ))

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        window?.rootViewController = navigator.rootViewController
        navigator.start()
    }
}
```

**Android** (`MainActivity.kt`):

```kotlin
class MainActivity : HotwireActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        findViewById<View>(R.id.main_nav_host).applyDefaultImeWindowInsets()
    }

    override fun navigatorConfigurations() = listOf(
        NavigatorConfiguration(
            name = "main",
            startLocation = "https://hotwire-native-demo.dev",
            navigatorHostId = R.id.main_nav_host
        )
    )
}
```

Android additionally needs a `NavigatorHost` `FragmentContainerView` in the layout:

```xml
<androidx.fragment.app.FragmentContainerView
    android:id="@+id/main_nav_host"
    android:name="dev.hotwire.navigation.navigator.NavigatorHost"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    app:defaultNavHost="false" />
```

### 1.5 When should a screen be native vs. web?

The framework's own framing (`/overview/native-screens`) is a three-tier ladder:

| Tier | Cost | Use when |
|---|---|---|
| **Web screen** | ~zero; you already wrote it | Default. Lists, forms, detail pages, settings, anything text/CRUD-shaped. |
| **Web screen + bridge component(s)** | one Stimulus controller + one Swift/Kotlin class, *per component, reused everywhere* | The screen is fine but a *control* on it should be native: submit button in the nav bar, action sheet, share, camera, haptics. |
| **Fully native screen** | a real iOS/Android engineer, per platform, per app-store cycle | Continuous-gesture UI (maps, drawing, video scrubbing, camera viewfinder), 60fps lists over huge datasets, deep SDK integration, or the screen that *is* the product. |

Their own warnings on the native tier:

- "It's strongly encouraged that each native screen has a corresponding URL, so it's easier
  to integrate into Hotwire Native's built-in navigation."
- "You'll need to write a version for every platform and go through the app store review
  process for any future changes."

And the counter-lever that makes the ladder safe: **progressive rollout**. Because native
screens are routed *through path configuration*, deleting the `view_controller` / `uri`
property from the remote path config instantly demotes a broken native screen back to its
web equivalent — no app store review. That is worth designing for deliberately: **every
native screen should have a working web page at the same URL.**

---

## 2. Path Configuration

Path configuration is a JSON document, loaded by the native app, that maps **URL path
regexes → presentation properties**. It is the primary lever the Rails side has over native
behaviour, and it is *remotely updatable*, which makes it the closest thing to
"deploy-to-native-without-review".

### 2.1 Schema

Two required top-level keys:

```json
{
  "settings": {},
  "rules": []
}
```

**`settings`** — free-form app-level config, read once when the path configuration loads.
Feature flags, remote script URLs, whatever. The framework does not interpret it.

```json
{
  "settings": {
    "use_local_db": true,
    "cable": {
      "script_url": "https://hotwire-native-demo.dev/configurations/action_cable.js"
    },
    "feature_flags": [
      { "name": "new_onboarding_flow", "enabled": true }
    ]
  },
  "rules": []
}
```

**`rules`** — an ordered array of `{ patterns: [regex...], properties: {...} }`.

### 2.2 The matching algorithm (get this right or everything is confusing)

From `/reference/path-configuration`:

> Entries in `rules` are read **sequentially** and are applied to the caught URL as they are
> read. This means that rules **earlier in the array can be overwritten by rules further
> down** the array.

So it is **last-match-wins, cumulative merge** — *not* first-match-wins, and *not*
most-specific-wins. Every matching rule's properties are merged in order.

The idiomatic shape is therefore: **rule 0 is the catch-all default**, everything after it
is an override.

```json
{
  "settings": {},
  "rules": [
    {
      "patterns": [".*"],
      "properties": {
        "context": "default",
        "pull_to_refresh_enabled": true
      }
    },
    {
      "patterns": ["/new$"],
      "properties": {
        "context": "modal",
        "pull_to_refresh_enabled": false
      }
    }
  ]
}
```

Pattern matching is `NSRegularExpression` (iOS — see `PathRule.swift`) against the URL's
**path *and* query string** by default:

```swift
public func match(path: String) -> Bool {
    for pattern in patterns {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
        let range = NSRange(path.startIndex ..< path.endIndex, in: path)
        if regex.numberOfMatches(in: path, range: range) > 0 { return true }
    }
    return false
}
```

Note it uses `numberOfMatches`, i.e. **unanchored substring match**. `"/new"` matches
`/newsletters/5`. Anchor with `$` and `^` deliberately.

Query-string matching (iOS): patterns match path + query. Because param order is not
guaranteed, wrap in wildcards:

```json
{ "patterns": [".*\\?.*foo=bar.*"], "properties": { "foo": "bar" } }
```

Disable entirely with `Hotwire.config.pathConfiguration.matchQueryStrings = false`.

### 2.3 Properties reference

**Cross-platform:**

| Property | Values | Default | Meaning |
|---|---|---|---|
| `context` | `default`, `modal` | `default` | Which stack the screen belongs to. |
| `presentation` | `default`, `push`, `pop`, `replace`, `replace_root`, `clear_all`, `refresh`, `none` | `default` | What navigation action to perform. |
| `pull_to_refresh_enabled` | `true`, `false` | **`true` on iOS, `false` on Android** | Note the platform asymmetry. |
| `animated` | `true`, `false` | `true` | Animate the push/pop/present. |

**iOS-only:**

| Property | Values | Meaning |
|---|---|---|
| `view_controller` | string | Matches `PathConfigurationIdentifiable.pathConfigurationIdentifier` on a native `UIViewController`. |
| `modal_style` | `large` (default), `medium`, `full`, `page_sheet`, `form_sheet` | `medium` = half-sheet with detents. Requires `context: "modal"`. |
| `modal_dismiss_gesture_enabled` | `true`/`false` (default `true`) | Swipe-down-to-dismiss. |
| `queryStringPresentation` | e.g. `"replace"` | iOS **1.2.1+** (not in the reference table yet). Replace rather than push when only the query string changes — matches long-standing Android behaviour. Essential for filter/sort/pagination links, which otherwise stack up a dozen screens. |

Related, not a path-config property but the natural companion to `context: "modal"`:

```swift
Hotwire.config.showDoneButtonOnModals = true   // adds a system Done button to modal screens
```

**Android-only:**

| Property | Values | Meaning |
|---|---|---|
| `uri` | **required** | Destination URI, e.g. `hotwire://fragment/web`. Must match a `@HotwireDestinationDeepLink(uri = ...)` fragment. |
| `fallback_uri` | | Used when no destination matches `uri` — the compatibility escape hatch for older app builds. |
| `title` | string | Toolbar title. Mostly for native destinations; web destinations use the page `<title>`. |

> **Android requires `uri` on every rule.** This is the biggest structural difference
> between the two files, and the reason you serve **two different JSON documents**, not one.
> An Android catch-all rule *must* include `"uri": "hotwire://fragment/web"`.

You may add arbitrary extra properties; the framework ignores what it doesn't know and hands
the whole `PathProperties` dictionary to your `NavigatorDelegate` / fragment. The demo app
uses a `"comment"` key purely for humans.

### 2.4 Sources, caching, and load order

Configuration comes from an ordered list of sources. **Always ship a bundled copy**, even
when loading remotely, so the app works offline and on first launch.

iOS (`AppDelegate.swift` — must run before the first `Navigator` is created):

```swift
let localPathConfigURL = Bundle.main.url(forResource: "path-configuration", withExtension: "json")!
let remotePathConfigURL = URL(string: "https://example.com/configurations/ios_v1.json")!

Hotwire.loadPathConfiguration(from: [
    .file(localPathConfigURL),
    .server(remotePathConfigURL)
])
```

Android (in an `Application` subclass):

```kotlin
Hotwire.loadPathConfiguration(
    context = this,
    location = PathConfiguration.Location(
        assetFilePath = "json/configuration.json",
        remoteFileUrl = "https://example.com/configurations/android_v1.json"
    )
)
```

Load order is asynchronous and layered:

1. the bundled local file,
2. a **locally cached copy of a previous successful server download**,
3. a freshly downloaded server copy (which then becomes #2 next launch).

Practical implication: **a remote path-config change takes effect on the *next* app launch
for most users**, not immediately. Don't treat it as a live kill-switch with sub-second
semantics; treat it as a same-day rollback lever.

### 2.5 Versioning

Docs recommendation, and it's a real constraint:

- `/configurations/ios_v1.json`
- `/configurations/android_v1.json`

Bump to `_v2.json` for breaking changes, **point the new app build at the new URL, and keep
`_v1.json` serving forever** — older installs will keep hitting it. Path configuration is a
public API with a long tail of clients you cannot force-upgrade. Treat it exactly like you'd
treat a versioned JSON API.

### 2.6 Serving it from Rails

The canonical demo does the dumbest possible thing, and it is the right thing — a plain
controller rendering a Ruby hash as JSON, so it lives in version control, gets reviewed, and
can use route helpers (`hotwire-native-demo/app/controllers/configurations_controller.rb`):

```ruby
class ConfigurationsController < ApplicationController
  def ios_v1
    render json: {
      settings: { enable_feature_x: true },
      rules: [
        {
          patterns: ["/new$", "/edit$", "/modal"],
          properties: { context: "modal", pull_to_refresh_enabled: false },
          comment: "Present forms and custom modal path as modals."
        },
        {
          patterns: ["/numbers$"],
          properties: { view_controller: "numbers" },
          comment: "Intercept with a native view."
        },
        {
          patterns: ["^/$"],
          properties: { presentation: "clear_all" },
          comment: "Reset navigation stacks when visiting root page."
        }
      ]
    }
  end

  def android_v1
    render json: {
      settings: {},
      rules: [
        {
          patterns: [".*"],
          properties: {
            context: "default",
            uri: "hotwire://fragment/web",
            fallback_uri: "hotwire://fragment/web",
            pull_to_refresh_enabled: true
          }
        },
        {
          patterns: ["^$", "^/$"],
          properties: { presentation: "clear_all" }
        },
        {
          patterns: ["/new$", "/edit$", "/modal"],
          properties: { context: "modal", pull_to_refresh_enabled: false }
        },
        {
          patterns: ["/numbers$"],
          properties: { uri: "hotwire://fragment/numbers", title: "Numbers" }
        },
        {
          patterns: ["/numbers/[0-9]+$"],
          properties: {
            context: "modal",
            uri: "hotwire://fragment/web/modal/sheet",
            pull_to_refresh_enabled: false
          }
        },
        {
          patterns: [".+\\.(?:bmp|gif|heic|jpg|jpeg|png|svg|webp)"],
          properties: { context: "modal", uri: "hotwire://fragment/image_viewer" }
        }
      ]
    }
  end
end
```

Routes:

```ruby
resources :configurations, only: [] do
  get "ios_v1", on: :collection
  get "android_v1", on: :collection
end
```

Serving from Rails (rather than a static file in `public/`) buys you: route helpers instead
of hand-written regexes, a test suite over the config, per-user/per-flag variation if you
really need it, and normal code review. Cost: you must cache it hard at the edge and it must
never 500 — a failed fetch silently falls back to the bundled copy, which is fine, but a
*successful* fetch of garbage JSON is not.

### 2.7 Common recipes

```jsonc
// Forms and edit screens open as modals; disable pull-to-refresh so the
// refresh gesture doesn't fight the dismiss gesture or blow away typed input.
{ "patterns": ["/new$", "/edit$"],
  "properties": { "context": "modal", "pull_to_refresh_enabled": false } }

// Root resets the whole app — use for "Home" tab / post-login landing.
{ "patterns": ["^/$"], "properties": { "presentation": "clear_all" } }

// Post-login: blow away the auth stack so Back can't return to the login form.
{ "patterns": ["^/dashboard$"], "properties": { "presentation": "replace_root" } }

// Half-sheet picker (iOS).
{ "patterns": ["/filters$"],
  "properties": { "context": "modal", "modal_style": "medium" } }

// Images open in a native viewer (Android).
{ "patterns": [".+\\.(?:bmp|gif|heic|jpg|jpeg|png|svg|webp)"],
  "properties": { "context": "modal", "uri": "hotwire://fragment/image_viewer" } }

// Native screen with a web fallback — delete `view_controller` remotely to roll back.
{ "patterns": ["/map$"], "properties": { "view_controller": "map" } }

// A URL the app should ignore entirely (e.g. a print view).
{ "patterns": ["/print$"], "properties": { "presentation": "none" } }
```

---

## 3. Bridge Components

### 3.1 What a bridge component is

Three parts, always:

1. **HTML markup** on the server, carrying `data-controller` + `data-bridge-*` attributes.
2. A **`BridgeComponent`** — a Stimulus `Controller` subclass, from
   `@hotwired/hotwire-native-bridge`.
3. A **native counterpart** — a Swift `BridgeComponent` subclass or a Kotlin
   `BridgeComponent<HotwireDestination>` subclass, registered at app launch.

The web and native sides are matched **by name string**: `static component = "form"` on the
JS side, `override class var name: String { "form" }` on Swift, and
`BridgeComponentFactory("form", ::FormComponent)` on Kotlin.

### 3.2 Installation (Rails)

Bridge components require Stimulus. With importmap-rails:

```bash
./bin/importmap pin @hotwired/stimulus @hotwired/hotwire-native-bridge
```

which yields (demo app's `config/importmap.rb`):

```ruby
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@hotwired/hotwire-native-bridge", to: "@hotwired--hotwire-native-bridge.js" # @1.2.2
pin_all_from "app/javascript/controllers", under: "controllers"
```

Merely importing the package has a side effect — from `src/index.js`:

```js
if (!window.HotwireNative) {
  const webBridge = new Bridge()
  window.HotwireNative = { web: webBridge }
  addLegacyClientSupport(webBridge)   // aliases window.Strada and window.webBridge
  webBridge.start()                   // dispatches "web-bridge:ready" on document
}
```

So `import "@hotwired/hotwire-native-bridge"` anywhere in your bundle is enough to install
the bridge; `import { BridgeComponent, BridgeElement }` is what you actually use.

**Version history of the JS package** — small, but two entries change behaviour materially:

| Version | Date | Change |
|---|---|---|
| 1.0.0 | 2024-09-25 | Initial release (as `@hotwired/hotwire-native-bridge`, superseding `@hotwired/strada`). |
| **1.1.0** | 2025-03-12 | **Behaviour change:** `BridgeComponent` controllers now load *only* when the client's UA advertises support for **that specific component**. Previously they loaded on any Hotwire Native client. This is the `shouldLoad` gate described below. |
| 1.2.0 | 2025-04-01 | Uses `window.HotwireNative` instead of `window.Strada` / `window.webBridge`. |
| 1.2.1 | 2025-04-04 | Better legacy support for alpha Strada clients. |
| **1.2.2** | 2025-08-21 | Listens for the `native:restore` event and re-invokes `connect()`. |

⚠️ **If you read a post written before March 2025**, its claims about when a bridge component
runs are wrong: pre-1.1.0, the controller connected on *every* native client and you had to
guard with `this.enabled` yourself. Post-1.1.0 the gate is automatic — but `this.enabled` is
still the right guard for *per-instance* opt-outs (`data-controller-optout-ios`).

**Convention:** put bridge components in `app/javascript/controllers/bridge/`, which
Stimulus's `pin_all_from` auto-registers under the identifier `bridge--form`,
`bridge--menu`, etc. The docs explicitly recommend this: *"It's recommended to place your
bridge components in a `/bridge` subdirectory where your Stimulus controllers live."* The
`bridge--` prefix is a naming convention, **not** the component name — `static component`
is separate and unprefixed.

### 3.3 Full lifecycle

Reading `src/bridge_component.js` and `src/bridge.js` end to end, the real lifecycle is:

**Boot**

1. Native app builds a user-agent string containing the names of every registered bridge
   component. From `hotwire-native-ios/Source/Bridge/UserAgent.swift`:

   ```swift
   let components = componentTypes.map { $0.name }.joined(separator: " ")
   let componentsSubstring = "bridge-components: [\(components)]"

   return [
       applicationPrefix,
       "Hotwire Native iOS;",
       "Turbo Native iOS;",
       componentsSubstring
   ].compactMap { $0 }.joined(separator: " ")
   ```

   → e.g. `... Hotwire Native iOS; Turbo Native iOS; bridge-components: [form menu overflow-menu]`

2. **Stimulus refuses to even load an unsupported component.** This is the cleverest part
   of the design and it happens *before* any DOM work:

   ```js
   export class BridgeComponent extends Controller {
     static component = ""

     static get shouldLoad() {
       return appSupportsBridgeComponent(this.component)
     }
   ```

   with

   ```js
   export function appSupportsBridgeComponent(component) {
     const supportedComponents = userAgent.match(/bridge-components: \[(.*?)\]/)
     if (supportedComponents) {
       return supportedComponents[1].split(" ").includes(component)
     } else {
       return false
     }
   }
   ```

   In a normal browser there is no such UA substring → `shouldLoad` is `false` → the
   controller is never registered → `connect()` never fires → **zero runtime cost on the
   web**. This is the single most important fact for library design (§10).

3. The native adapter attaches and `Bridge#setAdapter` stamps the `<html>` element:

   ```js
   document.documentElement.dataset.bridgePlatform = this.#adapter.platform          // "ios" | "android"
   document.documentElement.dataset.bridgeComponents = this.#adapter.supportedComponents.join(" ")
   ```

   → `<html data-bridge-platform="ios" data-bridge-components="form menu overflow-menu">`
   which is what the CSS hooks in §3.6 key off.

4. Any messages sent before the adapter attached are queued and flushed
   (`#pendingMessages` / `#sendPendingMessages`).

**Connect / send / reply**

5. `connect()` runs. **You must call `super.connect()`** — the base class installs the
   `native:restore` listener there. Then you typically `this.send(...)`.

   ```js
   send(event, data = {}, callback) {
     data.metadata = { url: window.location.href }   // so native can route the reply correctly
     const message = { component: this.component, event, data, callback }
     const messageId = this.bridge.send(message)
     if (callback) this.pendingMessageCallbacks.push(messageId)
   }
   ```

6. Native `onReceive(message:)` fires, does native work, and later calls
   `reply(to: "connect")` (optionally with a payload). That resolves the JS `callback`.
   **`reply` can be called many times** — the callback is not one-shot; it stays registered
   until disconnect. This is how a native button keeps working across repeated taps.

**Restore**

7. When a screen comes back from the screenshot state (or the native destination is
   recreated), the native side dispatches `native:restore` on `document`:

   ```js
   restore() {
     // Manually call connect() so the native bridge component has
     // a chance to restore its view state if it needs to be recreated.
     this.connect()
   }
   ```

   → **your `connect()` must be idempotent.** It will be called more than once for the same
   element. Don't append; set.

**Disconnect**

8. ```js
   disconnect() {
     this.removePendingCallbacks()
     this.removePendingMessages()
     this.removeRestoreEventListener()
   }
   ```
   If you override `disconnect()`, call `super.disconnect()` or you leak callbacks.

### 3.4 The `BridgeComponent` API surface

| Member | Type | What it does |
|---|---|---|
| `static component` | string | Name matched against the native component. Required. |
| `static get shouldLoad` | — | Overridden by the base class; gates on UA. Don't override. |
| `this.send(event, data = {}, callback)` | method | Sends a message; `callback(message)` runs on each native `reply`. Automatically merges `data.metadata.url`. |
| `this.enabled` | bool | `!platformOptingOut && bridge.supportsComponent(component)`. **Use this to guard behaviour**, not `shouldLoad`. |
| `this.platformOptingOut` | bool | True when `data-controller-optout-ios`/`-android` names this controller. |
| `this.bridgeElement` | `BridgeElement` | `this.element` wrapped. |
| `this.bridge` | `Bridge` | `window.HotwireNative.web`. |

`BridgeElement` (`src/bridge_element.js`):

| Member | Behaviour |
|---|---|
| `title` | `data-bridge-title` → `aria-label` → `textContent` → `value`, trimmed. **Accessibility pays off directly here.** |
| `disabled` / `enabled` | reads `data-bridge-disabled`; true if `"true"` **or** equal to the current platform (`"ios"` / `"android"`). |
| `enableForComponent(component)` | removes `data-bridge-disabled` if the component is enabled. |
| `hasClass(name)`, `attribute(name)` | plain DOM reads. |
| `bridgeAttribute(name)` | reads `data-bridge-<name>`. |
| `setBridgeAttribute(name, value)` / `removeBridgeAttribute(name)` | writes/removes. |
| `click()` | clicks the element — and on Android **removes `target` first**, working around a WebView bug where `target="_blank"` breaks JS-initiated clicks. |
| `platform` | `document.documentElement.dataset.bridgePlatform`. |

Data attributes:

- `data-bridge-title="…"` — explicit title for the native control.
- `data-bridge-disabled="true|false|ios|android"` — per-platform disable of a *bridge element*.
- `data-bridge-*` — arbitrary, readable via `bridgeAttribute("*")`.
- `data-controller-optout-ios` / `data-controller-optout-android` — per-platform disable of
  a *component instance*, even when the native app supports it. Value is the controller
  identifier, e.g. `data-controller-optout-ios="bridge--menu"`.

### 3.5 A complete component, all three sides

The canonical "native submit button" (`form`), from the demo app.

**ERB** (`hotwire-native-demo/app/views/components/new.html.erb`):

```erb
<%= form_with url: components_path,
      data: {
        controller: "bridge--form",
        action: "turbo:submit-start->bridge--form#submitStart turbo:submit-end->bridge--form#submitEnd"
      } do |form| %>
  <%= form.label :first_name %>
  <%= form.text_field :first_name %>

  <%= form.submit "Submit form",
        data: { bridge__form_target: "submit", bridge_title: "Submit" } %>
<% end %>
```

Note the two Rails-isms: `bridge__form_target:` (double underscore → `bridge--form-target`)
and `bridge_title:` → `data-bridge-title`.

**Stimulus** (`app/javascript/controllers/bridge/form_controller.js`):

```js
import { BridgeComponent, BridgeElement } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "form"
  static targets = ["submit"]

  connect() {
    super.connect()
    this.notifyBridgeOfConnect()
  }

  notifyBridgeOfConnect() {
    const submitButton = new BridgeElement(this.submitTarget)
    const submitTitle = submitButton.title

    this.send("connect", { submitTitle }, () => {
      this.submitTarget.click()
    })
  }

  submitStart(event) {
    this.submitTarget.disabled = true
    this.send("submitDisabled")
  }

  submitEnd(event) {
    this.submitTarget.disabled = false
    this.send("submitEnabled")
  }
}
```

**Swift** (`hotwire-native-ios/Demo/Bridge/FormComponent.swift`):

```swift
final class FormComponent: BridgeComponent {
    override class var name: String { "form" }

    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .connect:        handleConnectEvent(message: message)
        case .submitEnabled:  submitBarButtonItem?.isEnabled = true
        case .submitDisabled: submitBarButtonItem?.isEnabled = false
        }
    }

    private weak var submitBarButtonItem: UIBarButtonItem?
    private var viewController: UIViewController? { delegate?.destination as? UIViewController }

    private func handleConnectEvent(message: Message) {
        guard let data: MessageData = message.data() else { return }
        configureBarButton(with: data.submitTitle)
    }

    private func configureBarButton(with title: String) {
        guard let viewController else { return }
        let action = UIAction { [unowned self] _ in reply(to: Event.connect.rawValue) }
        let item = UIBarButtonItem(title: title, primaryAction: action)
        viewController.navigationItem.rightBarButtonItem = item
        submitBarButtonItem = item
    }
}

private extension FormComponent {
    enum Event: String { case connect, submitEnabled, submitDisabled }
    struct MessageData: Decodable { let submitTitle: String }
}
```

**Kotlin** (shape, from the docs):

```kotlin
class ButtonComponent(
    name: String,
    private val delegate: BridgeDelegate<HotwireDestination>
) : BridgeComponent<HotwireDestination>(name, delegate) {

    override fun onReceive(message: Message) {
        when (message.event) {
            "connect" -> handleConnectEvent(message)
            else -> Log.w("ButtonComponent", "Unknown event for message: $message")
        }
    }

    private fun handleConnectEvent(message: Message) {
        val data = message.data<MessageData>() ?: return
        // render a native toolbar button using data.title
    }

    private fun performButtonClick(): Boolean = replyTo("connect")

    @Serializable
    data class MessageData(@SerialName("title") val title: String)
}
```

**Registration:**

```swift
// iOS — AppDelegate.application(_:didFinishLaunchingWithOptions:)
Hotwire.registerBridgeComponents([
    FormComponent.self,
    MenuComponent.self,
    OverflowMenuComponent.self
])
```

```kotlin
// Android — Application subclass
Hotwire.registerBridgeComponents(
    BridgeComponentFactory("form", ::FormComponent),
    BridgeComponentFactory("menu", ::MenuComponent)
)
```

### 3.6 Hiding the web control when the native one exists

Because `<html>` carries `data-bridge-components`, pure CSS is enough — no JS branch, no
server-side conditional. From the demo's `native.css`:

```css
/* Hide elements in Hotwire Native apps. */
.hide\@native { display: none !important; }

/* Hide the submit button when the "form" component is registered. */
[data-bridge-components~="form"]
[data-controller~="bridge--form"]
[type="submit"] {
  display: none;
}

/* Hide the overflow button when the "overflow-menu" component is registered. */
[data-bridge-components~="overflow-menu"]
[data-controller~="bridge--overflow-menu"] {
  display: none;
}
```

The `~=` (whitespace-separated list contains) operator is doing the work in both selectors.
This is **version-aware for free**: an old app build whose UA lists only `[form]` will hide
the form's submit button and keep showing the web menu, correctly, with no server change.

The layout only loads this stylesheet for native clients:

```erb
<%= stylesheet_link_tag "native", "data-turbo-track": "reload" if hotwire_native_app? %>
```

### 3.7 The "stacked controllers" degradation pattern

The demo's menu is the most instructive markup in the whole ecosystem, because it shows how
one piece of HTML serves *both* a web `<dialog>` and a native action sheet:

```erb
<div data-controller="menu bridge--menu">
  <button class="button"
          data-action="click->bridge--menu#show click->menu#show">Open Menu</button>

  <dialog data-menu-target="dialog">
    <p data-bridge--menu-target="title">Select an option</p>
    <button data-menu-target="item"
            data-bridge--menu-target="item"
            data-action="click->menu#itemSelected">Option One</button>
    <!-- ... -->
  </dialog>
</div>
```

Two controllers on one element; two actions on one click, **ordered bridge-first**. The
bridge controller cancels the web one when native is available:

```js
export default class extends BridgeComponent {
  static component = "menu"
  static targets = ["title", "item"]

  show(event) {
    if (this.enabled) {
      event.stopImmediatePropagation()      // ← kills the queued click->menu#show
      this.notifyBridgeToDisplayMenu(event)
    }
  }

  notifyBridgeToDisplayMenu(event) {
    const title = new BridgeElement(this.titleTarget).title
    const items = this.makeMenuItems(this.itemTargets)
    const { x, y, width, height } = event.target.getBoundingClientRect()

    this.send("display", { title, items, source: { x, y, width, height } }, message => {
      const selectedItem = new BridgeElement(this.itemTargets[message.data.selectedIndex])
      selectedItem.click()                  // ← replay the selection into the web DOM
    })
  }

  makeMenuItems(elements) {
    return elements.map((el, index) => this.menuItem(el, index)).filter(Boolean)
  }

  menuItem(element, index) {
    const bridgeElement = new BridgeElement(element)
    if (bridgeElement.disabled) return null
    return { title: bridgeElement.title, index }
  }
}
```

Three things to steal wholesale:

1. **`event.stopImmediatePropagation()` guarded by `this.enabled`** is the cancellation
   primitive. Order matters in `data-action` — bridge controller first.
2. **The native side never navigates.** It replies with an *index*, and the web side does
   `selectedItem.click()`. All the real behaviour (the href, the `data-turbo-method`, the
   form submit) stays in the HTML. The native layer is a *renderer for a choice*, nothing more.
3. **`source: { x, y, width, height }`** from `getBoundingClientRect()` lets the native side
   anchor a popover to the web element. The Swift side has to add
   `webView.scrollView.adjustedContentInset.top` to `y` to account for the nav bar.

---

## 4. Rails-side concerns

### 4.1 `hotwire_native_app?`

`turbo-rails` ships `Turbo::Native::Navigation`, auto-included into `ActionController::Base`
via the engine (`lib/turbo/engine.rb`). Verbatim
(`turbo-rails/app/controllers/turbo/native/navigation.rb`):

```ruby
module Turbo::Native::Navigation
  extend ActiveSupport::Concern

  included do
    helper_method :hotwire_native_app?, :turbo_native_app?
  end

  # Hotwire Native applications are identified by having the string "Hotwire Native" as part of their user agent.
  # Legacy Turbo Native applications use the "Turbo Native" string.
  def hotwire_native_app?
    request.user_agent.to_s.match?(/(Turbo|Hotwire) Native/)
  end

  alias_method :turbo_native_app?, :hotwire_native_app?
  # ...
end
```

Facts worth internalising:

- It is **pure user-agent sniffing**. Nothing more. Which means it is trivially spoofable and
  must never gate authorization — only presentation.
- It is available as a **controller method and a view helper**.
- `turbo_native_app?` is an alias, not deprecated-with-warning. ⚠️ Old posts using it are
  still correct, just old-fashioned.
- The iOS library *always* emits both `"Hotwire Native iOS;"` and `"Turbo Native iOS;"` for
  exactly this backwards compatibility.

Detecting **which** platform requires your own regex, because turbo-rails doesn't provide it:

```ruby
def hotwire_native_ios?     = request.user_agent.to_s.include?("Hotwire Native iOS")
def hotwire_native_android? = request.user_agent.to_s.include?("Hotwire Native Android")
```

And the supported-components list is in the UA too, if you ever need server-side
feature-detection rather than the CSS approach:

```ruby
def native_bridge_components
  request.user_agent.to_s[/bridge-components: \[(.*?)\]/, 1].to_s.split(" ")
end
```

### 4.2 The native request variant

> **Correction to a widely-repeated claim:** there is **no built-in `:hotwire_native`
> request variant.** Verified against turbo-rails 2.0.23 — the gem never touches
> `request.variant`, and the official docs never mention a variant. `variant: :hotwire_native`
> is a convention people write themselves. (The one gem that ships the pattern,
> `hotwire_native_rails`, names it **`:native`**, not `:hotwire_native`.)

You opt in yourself:

```ruby
class ApplicationController < ActionController::Base
  before_action :set_native_variant

  private

  def set_native_variant
    request.variant = :hotwire_native if hotwire_native_app?
  end
end
```

Then `app/views/messages/index.html+hotwire_native.erb` wins over
`index.html.erb` for native clients, and `layouts/application.html+hotwire_native.erb`
overrides the layout. **Pick one name and be consistent** — `:native` (the
`hotwire_native_rails` convention, shorter) or `:hotwire_native` (more explicit). We should
pick `:hotwire_native` for crosswire and say so, because `:native` is generic enough to
collide with an app's own variants.

`hotwire_native_rails` ships it as a concern:

```ruby
# app/controllers/concerns/device_format.rb  (generated by hotwire_native_rails)
module DeviceFormat
  extend ActiveSupport::Concern

  included do
    before_action :set_variant
  end

  private

  def set_variant
    request.variant = :native if turbo_native_app?
  end
end
```

Alternatively, and often better, keep one template and switch only the layout:

```ruby
layout -> { hotwire_native_app? ? "hotwire_native" : "application" }
```

**Guidance: prefer the layout switch + CSS over the variant.** A `+hotwire_native` template
is a second copy of a view that will drift. Reach for the variant only when the native
screen is genuinely a *different* screen, not the same screen with less chrome.

### 4.3 Hiding web chrome

The demo takes the cheapest possible route — a utility class plus a conditional stylesheet:

```erb
<header class="header hide@native">
  <!-- brand + top nav -->
</header>
```

```erb
<%= stylesheet_link_tag "native", "data-turbo-track": "reload" if hotwire_native_app? %>
```

```css
.hide\@native { display: none !important; }
```

Why this beats `<% unless hotwire_native_app? %>`:

- one HTML output for both clients → **the HTTP cache and the CDN see one document**, and
  fragment caches don't need a `hotwire_native` cache-key dimension;
- the decision is expressed in the same place as the rest of your styling;
- it composes with the `[data-bridge-components~=...]` selectors, which *cannot* be done
  server-side (the server doesn't know which components this app build supports... except
  via UA parsing, which is fragile).

Reserve server-side `if hotwire_native_app?` for cases where the *payload* should differ
(don't ship a 200KB chart library to a screen the native app replaces) or where a route
must behave differently.

**Masilotti makes the caching argument explicitly** (book ch. 2, and
`/hotwire-native-by-example/hide-content-tailwind-css/`): branching in Ruby means the HTML
varies by user agent, which **doubles your cache footprint** — every fragment cache, every
CDN object, every `Vary: User-Agent` response, twice. His preferred technique, which is
strictly better than the demo app's conditional stylesheet, is a **single stamped attribute
plus a CSS variant**:

```erb
<html>
  <body <%= "data-hotwire-native" if hotwire_native_app? %>>
```

Tailwind v4:

```css
@import "tailwindcss";

@custom-variant hotwire-native {
  body[data-hotwire-native] & { @slot; }
}
@custom-variant not-hotwire-native {
  body:not([data-hotwire-native]) & { @slot; }
}
```

Tailwind v3:

```js
plugins: [
  ({ addVariant }) => {
    addVariant("hotwire-native", "body[data-hotwire-native] &"),
    addVariant("not-hotwire-native", "body:not([data-hotwire-native]) &")
  }
]
```

Usage:

```erb
<h1 class="hotwire-native:hidden">Hikes</h1>
```

(`hotwire_native_rails` ships the same idea, stamping `data-hotwire-native` on `<html>` via a
`platform_identifier` helper and registering `hotwire-native:` / `non-hotwire-native:`
variants.)

⚠️ Don't confuse the three attributes:

| Attribute | Set by | Element | Meaning |
|---|---|---|---|
| `data-hotwire-native` | **you**, server-side ERB | `<html>` or `<body>` | "this response was rendered for a native client" |
| `data-bridge-platform` | the bridge JS, at runtime | `<html>` | `"ios"` or `"android"` |
| `data-bridge-components` | the bridge JS, at runtime | `<html>` | space-separated component names this app build supports |

Only the first is available at render time; the other two are only available to CSS/JS after
the native adapter attaches.

**Dynamic native titles need nothing at all.** Both platforms read the nav bar / action bar
title from the page's `<title>`, so ordinary `content_for` works:

```erb
<%# layout %>
<title><%= content_for(:title) || "Default Title" %></title>

<%# app/views/dashboards/show.html.erb %>
<% content_for :title, "Dashboard" %>
```

(Android can override this per-destination with the path-config `title` property, which is
mostly for native fragments that have no `<title>`.)

### 4.4 `data-turbo-*` differences in native

Mostly the same, with these deltas:

- **`data-turbo-action="replace"`** is honoured, and it maps onto the native
  `presentation: replace` behaviour (replace the top screen instead of pushing). This is
  the per-link escape hatch when a path-config rule would be overkill.
- **`data-turbo="false"`** disables Turbo, which in native means the link does a full page
  load *inside the current web view* — no native push, no back button entry. Almost always
  wrong in native. Prefer path configuration.
- **`data-turbo-frame`** works normally *within one screen*. It cannot target a frame on a
  different screen in the stack (different web view / frozen screenshot).
- **`target="_blank"`** is a known Android WebView hazard; `BridgeElement#click()`
  strips it before clicking for exactly this reason.
- **`data-turbo-permanent`** is per-web-view. Since a modal is a separate web view, a
  permanent element does not survive main-stack → modal.
- **`turbo-refresh-method` / `turbo-refresh-scroll` morphing meta tags** work fine and the
  demo app sets both:
  ```html
  <meta name="turbo-refresh-method" content="morph">
  <meta name="turbo-refresh-scroll" content="preserve">
  ```
  Morphing is *especially* valuable in native because `presentation: refresh` re-requests
  the page; morphing keeps scroll position and form state from jumping.

### 4.5 Native-specific routes and deep links

Two distinct things called "deep links":

1. **turbo-rails historical-location routes** (mounted automatically by the engine —
   `turbo-rails/config/routes.rb`):

   ```ruby
   get "recede_historical_location",  to: "turbo/native/navigation#recede",  as: :turbo_recede_historical_location
   get "resume_historical_location",  to: "turbo/native/navigation#resume",  as: :turbo_resume_historical_location
   get "refresh_historical_location", to: "turbo/native/navigation#refresh", as: :turbo_refresh_historical_location
   ```

   Their controller is deliberately trivial:

   ```ruby
   class Turbo::Native::NavigationController < ActionController::Base
     def recede  = render html: "Going back…"
     def refresh = render html: "Refreshing…"
     def resume  = render html: "Staying put…"
   end
   ```

   These are **commands encoded as URLs**. Since **Hotwire Native 1.2.0** the native
   libraries recognise them with **no path-configuration entry required**
   (`hotwire-native-ios/Source/Turbo/Path Configuration/PathRule+ServerRoutes.swift`):

   ```swift
   static let recedeHistoricalLocation = PathRule(
       patterns: ["/recede_historical_location"],
       properties: ["presentation": "pop", "context": "default", "historical_location": true]
   )
   static let resumeHistoricalLocation = PathRule(
       patterns: ["/resume_historical_location"],
       properties: ["presentation": "none", "context": "default", "historical_location": true]
   )
   static let refreshHistoricalLocation = PathRule(
       patterns: ["/refresh_historical_location"],
       properties: ["presentation": "refresh", "context": "default", "historical_location": true]
   )
   ```

   ⚠️ **OUTDATED:** pre-1.2 guides tell you to hand-add these three rules to your path
   configuration. On 1.2+ that's redundant (harmless, but noise).

2. **OS deep links / universal links** (`myapp://…`, `https://example.com/…` opened from
   Mail). These are handled entirely on the native side by resolving the URL and calling
   `navigator.route(url)`. The Rails-side requirement is just that **every screen has a real
   URL** and that you serve `/.well-known/apple-app-site-association` and
   `/.well-known/assetlinks.json`. Those must be served with `Content-Type: application/json`
   and no redirect — a common Rails misconfiguration is having them 301 to a canonical host.

### 4.6 Rails-side gems and generators

**`turbo-rails` is the only thing you strictly need.** Everything else is scaffolding.

#### `hotwire_native_rails` — by **Yaro Shmarov (yshmarov)**, not Masilotti

- <https://github.com/yshmarov/hotwire_native_rails> · <https://rubygems.org/gems/hotwire_native_rails>
- **v0.4.4** (2025-03-11), 13 releases, ~8.8k downloads.
- **There is no `turbo_native_rails` gem.** That name doesn't exist on RubyGems.

It is a **one-shot generator**, not a runtime library — `rails g hotwire_native` copies files
into your app and then the gem does nothing. There is no API surface to depend on
(`HotwireNativeRails::VERSION` is literally all it exposes at runtime). What it generates:

- `app/helpers/hotwire_native_helper.rb` — `page_title`, `viewport_meta_tag`,
  `platform_identifier`, `replace_if_native`, a `link_to` override, and a
  `bridge_form_with` + `BridgeFormBuilder` pair;
- `config/routes/hotwire_native.rb` + two path-configuration controllers under
  `hotwire_native/v1/{ios,android}/path_configurations#show`, plus a `TabsController`;
- `app/controllers/concerns/device_format.rb` (the `:native` variant, §4.2);
- six bridge Stimulus controllers under `app/javascript/controllers/bridge/`:
  `button`, `menu`, `form`, `overflow_menu`, `nav` (UIMenu), `review_prompt`;
- Tailwind v3/v4 `hotwire-native:` / `non-hotwire-native:` variants (§4.3);
- `bin/importmap pin` / `yarn add` for `@hotwired/stimulus` + `@hotwired/hotwire-native-bridge`;
- `bundle add browser`.

The most reusable idea in it is the form builder, which removes the boilerplate from §3.5:

```ruby
class BridgeFormBuilder < ActionView::Helpers::FormBuilder
  def submit(value = nil, options = {})
    options[:data] ||= {}
    options['data-bridge--form-target'] = 'submit'
    options[:class] = [options[:class], 'hotwire-native:hidden'].compact
    super
  end
end

def bridge_form_with(*, **options, &)
  options[:html] ||= {}
  options[:html][:data] ||= {}
  options[:html][:data] = options[:html][:data].merge(
    controller: 'bridge--form',
    action: 'turbo:submit-start->bridge--form#submitStart turbo:submit-end->bridge--form#submitEnd'
  )
  options[:builder] = BridgeFormBuilder
  form_with(*, **options, &)
end
```

`bridge_form_with` is exactly the shape crosswire should adopt (see I7/I8) — **a helper that
makes the bridge wiring invisible to the author.** Note the gem still uses `turbo_native_app?`
internally throughout; harmless, just old-fashioned.

#### `joemasilotti/bridge-components`

Not a gem — a **copy-paste library** of Swift + Kotlin + Stimulus files. See the
[Bridge Component Catalog](#bridge-component-catalog).

#### Other reference material

- `hotwired/hotwire-native-demo` — the canonical Rails app (used throughout these notes).
- `joemasilotti/hotwire-native-blog-demo` — small Rails blog wired for native.
- `jumpstart-pro/example-hotwire-native-rails-backend` — SaaS-shaped reference backend.
- blog.corsego.com / superails.com (Shmarov) — de facto cookbook for individual bridge
  components; the generator's JS templates cite these directly.

Nothing exists for **generating path configuration from Rails routes** — see I7.

---

## 5. Authentication, cookies, sessions

### 5.1 The default: it just works, because it's cookies in a web view

The web view is a real browser. Rails' `Set-Cookie` session works unmodified. There is no
token exchange, no OAuth dance, no `Authorization` header. **This is the biggest practical
advantage of Hotwire Native over a REST-API-plus-native-client architecture** and it should
be preserved deliberately: don't invent a JSON API for the mobile app.

Cookie persistence on iOS is `WKWebsiteDataStore.default()` — persistent across launches.
`Navigator` additionally copies web-view cookies into the shared `HTTPCookieStorage` after
each request, so native code (e.g. an `URLSession` download, or a native screen fetching
JSON) shares the session (`Navigator.swift`):

```swift
public func sessionDidFinishRequest(_ session: Session) {
    guard let url = session.activeVisitable?.initialVisitableURL else { return }

    Task { @MainActor in
        let cookies = await WKWebsiteDataStore.default().httpCookieStore.allCookies()
        HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: url)
        delegate?.requestDidFinish(at: url)
    }
}
```

Requirements on the Rails side:

- **Session cookie must not be `SameSite=Strict`** if any auth flow bounces off a third-party
  IdP. `Lax` is fine.
- **Cookie must not be host-locked to `www.`** if the app's `rootURL` omits it, and vice versa.
  Mismatched hosts is the #1 cause of "logged in on web, logged out in app".
- `config.force_ssl` + HSTS are fine and recommended.
- **Don't tie the session to `request.remote_ip`** — mobile IPs change constantly.
- Session lifetime should be *long*. A native app that logs you out weekly reads as broken.
  Use `cookies.encrypted.permanent` / a long-lived remember-me token, as the demo does:
  ```ruby
  cookies.encrypted.permanent[:authenticated] = true
  ```

### 5.2 The 401 → login flow

The idiomatic pattern (restored to the library in iOS 1.3.0, "Bring back the authentication
flow", PR #168) is: **the server returns `401 Unauthorized`, and the native app reacts.**

`hotwire-native-ios/Demo/SceneController.swift`:

```swift
func visitableDidFailRequest(_ visitable: any Visitable, error: HotwireNativeError, retryHandler: RetryBlock?) {
    switch error {
    case .http(.client(.unauthorized)):
        promptForAuthentication()
    default:
        // present the error view / retry
    }
}

private func promptForAuthentication() {
    // Clean up empty screen from 401 response.
    tabBarController.activeNavigator.pop(animated: false)

    let authURL = rootURL.appendingPathComponent("/session/new")
    tabBarController.activeNavigator.route(authURL)
}
```

Rails side (`hotwire-native-demo/app/controllers/sessions_controller.rb`):

```ruby
def protected
  unless cookies.encrypted[:authenticated]
    head :unauthorized
  end
end
```

**This is the important Rails-side rule and it is not obvious:** for native clients,
authentication failures should be **`head :unauthorized`**, not `redirect_to new_session_url`.

- A redirect produces a *pushed screen showing a login page*, so Back goes to a page the
  user can't see, and after logging in you're two screens deep in the wrong place.
- A 401 lets the native app decide — pop the empty screen, then present login *modally*, and
  after success `presentation: replace_root` or `clear_all` back to the intended destination.

So:

```ruby
def require_authentication
  return if authenticated?

  if hotwire_native_app?
    head :unauthorized
  else
    redirect_to new_session_path
  end
end
```

### 5.3 Post-login navigation

After a successful login you want the login screen *gone*, not on the back stack. Path config:

```json
{ "patterns": ["/session/new$"], "properties": { "context": "modal" } },
{ "patterns": ["^/$"],           "properties": { "presentation": "clear_all" } }
```

or from the controller, `refresh_or_redirect_to root_path` (dismisses the modal, refreshes
what's underneath).

### 5.4 Third-party / OAuth logins

The hard case. `SafariViewControllerRouteDecisionHandler` sends off-domain URLs to
SFSafariViewController — **which does not share cookies with `WKWebView`**. An OAuth round
trip that leaves your domain and comes back will therefore complete in Safari and leave the
web view still logged out.

Mitigations, in order of preference:

1. Keep the whole flow on your domain (server-side OAuth: your Rails app is the OAuth
   client; the browser only ever talks to you). Works with zero native code.
2. Register a custom `RouteDecisionHandler` that keeps the IdP host in the web view rather
   than punting to Safari:
   ```swift
   class IdentityProviderRouteDecisionHandler: RouteDecisionHandler {
       let name = "identity-provider"
       func matches(proposal: VisitProposal, configuration: Navigator.Configuration) -> Bool {
           proposal.url.host == "login.example.com"
       }
       func handle(proposal: VisitProposal, configuration: Navigator.Configuration, navigator: Navigating) -> Router.Decision {
           navigator.route(proposal.url)   // stay in-app
           return .cancel
       }
   }
   ```
3. Native `ASWebAuthenticationSession` + a bridge component. Most work, best UX, and
   Sign in with Apple effectively requires native anyway (see §Gotchas / guideline 4.8).

### 5.5 Biometrics / app lock

There is no built-in support. The pattern is a bridge component: on `connect`, native runs
`LAContext.evaluatePolicy`, and `reply`s with success, at which point the web side reveals
content or submits a form. Note that **the gate is cosmetic unless the server also
re-authenticates** — biometrics protects the device, not the session.

---

## 6. Navigation semantics

### 6.1 Defaults

- Every link tap **pushes** a new screen, with a loading spinner, then the content renders.
- Navigating to the **current** URL **replaces** the screen instead of pushing.
- Navigating to the URL of the **previous** screen **pops** then visits.
- Back uses the cached screenshot; iOS interactive edge-swipe works.
- **Off-domain links leave the app** (SFSafariViewController / Custom Tabs).

### 6.2 The full routing table

From `/reference/navigation`. *State* = what the app is currently showing; *Context* and
*Presentation* come from the matched path-configuration rule (or `data-turbo-action`).

| State | Context | Presentation | Behavior |
|---|---|---|---|
| `default` | `default` | `default` | Push on main stack — *or* replace if visiting the same page — *or* pop then visit if the previous screen is the same URL |
| `default` | `default` | `replace` | Replace screen on main stack |
| `default` | `modal` | `default` | Present a modal with only this screen |
| `default` | `modal` | `replace` | Present a modal with only this screen |
| `modal` | `default` | `default` | **Dismiss** then push on main stack |
| `modal` | `default` | `replace` | **Dismiss** then replace on main stack |
| `modal` | `modal` | `default` | Push on the modal stack |
| `modal` | `modal` | `replace` | Replace screen on modal stack |
| `default` | any | `pop` | Pop screen off main stack |
| `default` | any | `refresh` | Pop on main stack, then refresh |
| `modal` | any | `pop` | Pop off modal stack — or dismiss if it's the only modal screen |
| `modal` | any | `refresh` | Pop off modal stack then refresh last modal screen — or dismiss, then refresh the last screen on the **main** stack |
| any | any | `clear_all` | Dismiss modal, pop to root, refresh root |
| any | any | `replace_root` | Dismiss modal, pop to root, replace root |
| any | any | `none` | Nothing |

Read the `modal` rows carefully: **a `context: default` link tapped from inside a modal
dismisses the modal first.** That is the mechanism behind "submit the form, modal closes,
you land on the new record".

### 6.3 `data-turbo-action` vs path configuration

`data-turbo-action="replace"` sets the Turbo visit action, which the native side maps to
`presentation: replace`. It's per-link and lives in your ERB.

Use `data-turbo-action` when the *link* is semantically a replacement (a tab strip within a
page, a "next step" in a wizard). Use **path configuration** for everything that's a property
of the *destination* (all `/new` pages are modals). Rule of thumb: **if you'd have to write
the same attribute on more than two links, it belongs in path configuration.**

### 6.4 The "dismiss modal + refresh what's underneath" problem

This is *the* recurring Hotwire Native question, and it exists because of §1.2: the modal
and the screen behind it are **separate web views**, so no Turbo Stream can bridge them.

`turbo-rails` solves it with three server-driven commands (`Turbo::Native::Navigation`):

```ruby
# Pops any modal, then pops the visible screen off the stack.
recede_or_redirect_to(url, **options)

# Pops any modal, then reloads the visible screen (new request, cache invalidated).
refresh_or_redirect_to(url, **options)

# Pops any modal. Nothing else.
resume_or_redirect_to(url, **options)

# ...and _back_or_to variants that use redirect_back for the web fallback:
recede_or_redirect_back_or_to(url, **options)
refresh_or_redirect_back_or_to(url, **options)
resume_or_redirect_back_or_to(url, **options)
```

Implementation (verbatim):

```ruby
def turbo_native_action_or_redirect(url, action, redirect_type, options = {})
  native_params = options.delete(:native_params) || {}

  if turbo_native_app?
    redirect_to send("turbo_#{action}_historical_location_url", notice: options[:notice], **native_params)
  elsif redirect_type == :back
    redirect_back fallback_location: url, **options
  else
    redirect_to url, options
  end
end
```

Note what this actually does: for native clients it **redirects to a magic URL** which the
native app intercepts as a command. Everything stays inside normal Turbo redirect semantics.

**Decision table for a `create`/`update` action:**

| You want | Use |
|---|---|
| Close the modal, refresh the list behind it | `refresh_or_redirect_to items_path` |
| Close the modal, go *forward* to the new record | plain `redirect_to item_path(@item)` — the modal-state/`default`-context row dismisses the modal and pushes |
| Close the modal, go back one screen (e.g. a delete) | `recede_or_redirect_to items_path` |
| Close the modal, change nothing (e.g. a "dismiss" action, or an async job kicked off) | `resume_or_redirect_to items_path` |
| Reset the app after login/logout | path config `presentation: clear_all` or `replace_root` on the destination |

Typical controller:

```ruby
class ItemsController < ApplicationController
  def create
    @item = Item.new(item_params)

    if @item.save
      refresh_or_redirect_to items_path, notice: "Item created"
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

On the web this is `redirect_to items_path`; in native it dismisses the modal and re-requests
`items` — which, if you have `turbo-refresh-method: morph` set, morphs rather than repaints.

`native_params:` lets you pass extra params through to the historical-location URL, which the
native side can read from the `VisitProposal`:

```ruby
refresh_or_redirect_to items_path, native_params: { toast: "Saved!" }
```

⚠️ **OUTDATED:** Older write-ups (and some still-current third-party framework docs) tell you
to add `/recede_historical_location` etc. to path configuration by hand. Unnecessary since 1.2.

### 6.5 Error / failed-visit handling

`Hotwire.config.makeCustomErrorView` (iOS 1.3.0+) lets you replace the default error screen:

```swift
Hotwire.config.makeCustomErrorView = { error, handler in
    MyErrorView(error: error, handler: handler)
}
```

Rails side: return real HTTP status codes. `422` for validation failures (Turbo requires it),
`401` for auth (§5.2), `404`/`500` render the native error view with a Retry button. Don't
return `200` with an error page — the native app can't distinguish it from success.

---

## 7. Native screens and native tabs

### 7.1 Native screens, iOS

Conform to `PathConfigurationIdentifiable`:

```swift
class NumbersViewController: UITableViewController, PathConfigurationIdentifiable {
    static var pathConfigurationIdentifier: String { "numbers" }

    init(url: URL) { self.url = url }
}
```

Match it in path config with `"view_controller": "numbers"`, then intercept in
`NavigatorDelegate`:

```swift
extension SceneDelegate: NavigatorDelegate {
    func handle(proposal: VisitProposal, from navigator: Navigator) -> ProposalResult {
        switch proposal.viewController {
        case NumbersViewController.pathConfigurationIdentifier:
            return .acceptCustom(NumbersViewController(url: proposal.url))
        default:
            return .accept
        }
    }
}
```

### 7.2 Native screens, Android

```kotlin
@HotwireDestinationDeepLink(uri = "hotwire://fragment/numbers")
class NumbersFragment : HotwireFragment() { /* ... */ }
```

```kotlin
Hotwire.registerFragmentDestinations(
    HotwireWebFragment::class,   // don't forget this for ordinary web destinations
    NumbersFragment::class
)
```

### 7.3 Progressive rollout (the killer feature)

Because a native screen is *addressed by URL* and *selected by path configuration*, removing
the `view_controller` / `uri` property from the remote config demotes it to the web page at
the same URL:

```json
{ "patterns": ["/numbers$"], "properties": { } }
```

> "you could easily update your remote Path Configuration and either point to your web
> content so users don't lose functionality, or immediately disable the screen altogether –
> no app store review required."

**Design rule this creates for us: never build a native screen whose URL has no working web
page.** The web page is the rollback.

### 7.4 Native tabs

Introduced in Hotwire Native 1.2 (`HotwireTabBarController` on iOS,
`HotwireBottomNavigationController` on Android). This is also the cheapest single thing you
can do to pass App Store guideline 4.2 (§Gotchas).

```swift
private let tabBarController = HotwireTabBarController()

func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
    window?.rootViewController = tabBarController
    tabBarController.load(tabs)
}

let tabs = [
    HotwireTab(title: "Navigation",
               image: .init(systemName: "arrow.left.arrow.right")!,
               url: rootURL),
    HotwireTab(title: "Bridge Components",
               image: .init(systemName: "square.grid.2x2")!,
               url: rootURL.appendingPathComponent("components"))
]
```

- **Each tab gets its own `Navigator`** → its own main + modal web views.
- `HotwireTabBarController(lazyLoadTabs: true)` — don't cold-boot every tab's URL at launch.
- `HotwireTab(..., isSearchTab: true)` — `UISearchTab` on iOS 18+, dedicated search
  appearance on iOS 26.
- `Hotwire.config.hideTabBarWhenPushed = true` — tab bar only on each tab's root.
- Tapping the active tab pops that stack to root, for free.

**Rails-side consequence:** each tab's start URL is now a *native entry point*. Those pages
must (a) be fast, (b) not assume you arrived from somewhere, (c) hide the web nav, and
(d) usually be marked `presentation: clear_all` so tapping the tab genuinely resets.

---

## Bridge Component Catalog

Components that exist in the official demos are marked ✅ **canonical** (source available).
The rest are patterns that recur across the community; treat the sketches as shape, not
copy-paste.

### Shipped in the official demo apps

| Component | `component` name | What it does | Web↔native contract |
|---|---|---|---|
| ✅ **Native submit button** | `form` | Moves a form's submit button into the native nav bar. Never hidden by the keyboard, always visible while scrolling. | web→`connect {submitTitle}`; native→`reply(connect)` → `submitTarget.click()`. Plus `submitDisabled`/`submitEnabled` driven by `turbo:submit-start` / `turbo:submit-end`. |
| ✅ **Native menu / action sheet** | `menu` | Replaces a web `<dialog>` menu with `UIAlertController(.actionSheet)` / a bottom sheet. | web→`display {title, items:[{title,index}], source:{x,y,width,height}}`; native→`reply(display, {selectedIndex})` → `items[selectedIndex].click()`. |
| ✅ **Overflow (⋯) nav-bar button** | `overflow-menu` | Puts a 3-dot button in the nav bar which, when tapped, clicks the web element that opens the `menu` component. Composes with `menu`. | web→`connect {label}`; native→`reply(connect)` → `bridgeElement.click()`. |
| ✅ **Generic nav-bar button** | `button` | Docs' teaching example: any link becomes a `UIBarButtonItem`. | web→`connect {title}`; native→`reply(connect)` → `element.click()`. |

Source: `hotwire-native-ios/Demo/Bridge/{FormComponent,MenuComponent,OverflowMenuComponent}.swift`,
`hotwire-native-android/demo/src/main/kotlin/dev/hotwire/demo/bridge/*.kt`,
`hotwire-native-demo/app/javascript/controllers/bridge/*.js`.

### Masilotti's `bridge-components` library — the de facto standard catalog

<https://github.com/joemasilotti/bridge-components> · <https://masilotti.com/bridge-components/>

Distribution model worth noting: **it is not a package.** You copy the Swift/Kotlin/JS files
into your app, then drive behaviour entirely from HTML `data-bridge-*` attributes — which
means behaviour changes ship as a Rails deploy, not an app store submission. Requires
Hotwire Native 1.2+, Stimulus 3+, iOS 16+, Android 9+. The repo includes example iOS,
Android, and Rails apps.

**Free tier:**

| Component | What it does |
|---|---|
| **Alert** | Native confirm-action alert. The right replacement for `data-turbo-confirm`. |
| **Button** | Native button (text or image) in the top nav bar. |
| **Form** | Native submit button; auto-disables during submit; keyboard-aware. |
| **Haptic** | Device vibration via the haptic engine. |
| **Menu** | `UIMenu` (iOS) / `DropdownMenu` (Android). |
| **Review Prompt** | App Store / Play Store review prompt. |
| **Search** | Native search field that passes queries back to JS. |
| **Share** | Native share sheet. |
| **Theme** | Toggles device dark/light appearance and styles native chrome to match. |
| **Toast** | Floating auto-dismissing message. |

**PRO tier** ($299 individual / $979 team, one-time):

| Component | What it does |
|---|---|
| **Barcode Scanner** | Camera-based barcode / QR scan. |
| **Biometrics Lock** | Locks the app when backgrounded until biometric auth. |
| **Document Scanner** | Auto-detect / perspective-correct document capture. |
| **Location** | Single-dialog precise-location prompt. |
| **NFC** | Read text / URLs from NFC tags. |
| **Notification Token** | Permission prompt + push token retrieval. |
| **Permissions** | Query status of location / notifications / etc. |

The `Menu` component's markup is the best illustration of the "attributes-as-API" style —
note how the *icon* is specified per-platform in HTML, so a Rails deploy can change a native
menu's icons:

```html
<div data-controller="bridge--menu">
  <a href="/one"
     data-bridge--menu-target="item"
     data-bridge-title="One"
     data-bridge-ios-image="1.circle"
     data-bridge-android-image="counter_1">
    One
  </a>
  <!-- more items -->
</div>
```

This is the pattern crosswire should copy for its own native hints (see I4): **the component
contract is a set of `data-bridge-*` attributes**, not a JS API.

### Other components commonly built in real apps

| Component | Typical name | Native API | Notes / contract sketch |
|---|---|---|---|
| **Share sheet** | `share` | `UIActivityViewController` / `Intent.ACTION_SEND` | `send("share", { url, title, text })`. No reply needed. Cheap, high perceived value, and directly answers guideline 4.2. |
| **Toast / flash** | `toast`, `flash` | native banner / `Snackbar` | Connect-time `send("display", { message, type })` from your flash partial. Native toasts survive a screen transition; a web flash doesn't. |
| **Haptics** | `haptic` | `UIImpactFeedbackGenerator` / `VibrationEffect` | Fire-and-forget `send("impact", { style: "medium" })` on `data-action="click->bridge--haptic#tap"`. |
| **Nav-bar title / subtitle** | `title`, `nav-bar` | `navigationItem.titleView` | Lets a page set a two-line or badged title. Otherwise the native title comes from `<title>`. |
| **Camera / photo picker** | `camera` | `UIImagePickerController` / `PHPicker` | Often unnecessary — `<input type="file" accept="image/*" capture>` works in the web view — but **requires `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` in `Info.plist` or the app crashes** (§Gotchas). |
| **Biometrics / app lock** | `biometrics` | `LAContext` / `BiometricPrompt` | `send("authenticate")` → reply on success → reveal or submit. Must be paired with a real server-side check. |
| **App Store review prompt** | `review` | `SKStoreReviewController` / Play In-App Review | Server decides *when* (Nth successful action), native performs the ask. Nice division of labour: the eligibility logic lives in Ruby. |
| **Push notification permission** | `push`, `notifications` | `UNUserNotificationCenter` | `send("requestPermission")`, reply with granted/denied + token; POST the token back with a normal Turbo form so it lands in your DB. |
| **Native date/time picker** | `date-picker` | `UIDatePicker` sheet | Replaces `<input type="date">` where the web control is weak. Reply with an ISO string, write it into the input, dispatch `input`. |
| **Native search bar** | `search` | `UISearchController` | Puts search in the nav bar; replies with the query, which the web side writes into a form and submits (works nicely with a Turbo Frame result list). |
| **Location** | `location` | `CLLocationManager` | Reply with lat/lng into hidden fields, then submit. |
| **Refresh control / progress** | `progress` | `UIProgressView` | For long uploads where the web progress bar is invisible behind the keyboard. |
| **Contacts / calendar** | `contacts`, `calendar` | `CNContactPicker`, `EKEventStore` | Same shape: native picks, replies with data, web fills a form. |

### The shape they all share

Notice every entry above follows the same contract, and it's worth stating as a rule:

> **The native side renders and collects. The web side decides and acts.**
> Native replies with a *value* (an index, a string, a boolean, a token). The web side then
> performs an ordinary DOM action — `click()`, set an input, submit a form — so that the
> resulting behaviour is identical to the pure-web path.

Components that break this rule (native code that navigates, or that mutates server state
directly) are the ones that rot, because they duplicate logic that already exists in HTML.

---

## Gotchas

### G1. App Store guideline 4.2 "Minimum Functionality" — the real risk

> "Your app should include features, content, and UI that **elevate it beyond a repackaged
> website**… If your app is not particularly useful, unique, or 'app-like,' it doesn't
> belong on the App Store." — [App Store Review Guidelines §4.2](https://developer.apple.com/app-store/review/guidelines/#4.2)

Masilotti, who has shipped 25+ of these:

> "4.2 is by far the most important guideline to consider when building a Hotwire Native app.
> You will most likely *not* get accepted if you repackage your Rails app in some native
> chrome. It needs something more to warrant an app."
> — <https://masilotti.com/hotwire-native-app-store-tips/>

Cheapest things that reliably help, roughly in order of effort:

1. **Native tab bar** (`HotwireTabBarController`) — hours, and it's the single strongest signal.
2. **Push notifications.**
3. **Native menu** replacing a web hamburger (`UIMenu` / `menu` bridge component).
4. **Share sheet**, **haptics**, **biometric lock**, **offline handling**.
5. **At least one genuinely native screen.**

Also: hide *all* web chrome. A visible web header/footer in the screenshot you upload to App
Store Connect is a giveaway.

### G2. Other App Store guidelines that bite Hotwire Native apps specifically

- **2.1 App Completeness — the file-input crash.** A `<input type="file">` in the web view
  will **crash** the app unless `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`
  are set in `Info.plist`. Two lines; extremely common rejection.
- **5.1.1(v) Account Deletion.** If the app supports account creation it must offer account
  deletion *in the app*. Handle it like sign-out: a `DELETE` to `/users` instead of
  `/sessions`, all server-side. Easy to forget; automatic rejection.
- **3.1.1 / 3.1.3(b) In-App Purchase.** If a user can self-serve pay you for the service,
  Apple generally wants IAP. This is the guideline most likely to make a Hotwire Native app
  *not worth building*. Read all of §3.1 before committing. RevenueCat + webhooks to your
  Rails app is the common escape from coordinating entitlements client-side.
- **2.3.2** — App Store metadata must disclose that featured items require purchase.
- **4.8 Sign in with Apple** — if you offer third-party social login, you generally must also
  offer Sign in with Apple, which effectively requires native code.

Google Play is materially more permissive about web-view apps but still enforces its own
Spam/Minimum Functionality policy, data-safety declarations, and (for digital goods) Play
Billing.

### G3. JS bundle differences and cold-start cost

Every screen transition in native *may* be a fresh page load, and every tab is a fresh web
view. Your JS/CSS bundle is parsed and executed more often than on the web, on slower CPUs.

- Prefer **importmap + HTTP caching** over a giant bundle; the web view honours normal cache
  headers, and unchanged files are not re-fetched.
- `data-turbo-track: "reload"` on stylesheets is correct and important — it's how a deploy
  propagates into a long-lived app session.
- **Do not ship heavy JS to screens the native app replaces.** This is one of the few places
  a server-side `if hotwire_native_app?` genuinely earns its keep.
- Beware anything measuring "time to interactive" per screen: in native that clock restarts
  on every push.

### G4. Offline

There is **no built-in offline story.** No service worker (Hotwire Native does not register
one for you), no request queue, no local cache of pages.

What you get:
- The **path configuration** works offline via the bundled file.
- Back navigation shows **screenshots**, so the app doesn't look dead — but the screenshot is
  not interactive, and tapping anything on it triggers a failed visit.
- A failed visit renders the error view (customisable via `makeCustomErrorView`) with retry.

If offline matters, that is an argument for a **native screen** backed by a local store, not
for heroics in the web view.

### G5. Screenshots and caching

- Screens on the stack are `UIView` snapshots taken *at the moment you navigate away*. If
  data changed since, the user sees stale content on Back until something refreshes it.
- `presentation: refresh` / `refresh_or_redirect_to` is the deliberate cure.
- Turbo's own page cache is *also* in play inside each web view, so a Back can show
  Turbo's cached HTML preview before the fresh page arrives.
- **The screenshot is also what iOS shows in the app switcher.** If your app shows sensitive
  data, that's a security consideration requiring native code to blur it.

### G6. Modal ↔ parent isolation

Restating §1.2 because it's the source of half of all confusion:

- A modal is a **different `WKWebView`**. Different `document`, different Stimulus
  application instance, different Action Cable connection.
- `turbo_stream.replace "some_id"` rendered in the modal's response affects **only the
  modal's DOM**.
- `data-turbo-permanent` doesn't carry across.
- Anything you want reflected behind the modal must go through a navigation command
  (§6.4), not the DOM.

### G7. Path configuration foot-guns

- **Unanchored regexes.** `"/new"` matches `/newsletters`. Always `^`/`$`.
- **Last match wins.** A permissive rule *after* a specific one silently undoes it.
- **Android needs `uri` on every rule**; iOS ignores `uri` and Android ignores
  `view_controller`/`modal_style`. Two files, not one.
- **Query strings are part of the match by default on iOS.** `/items$` will not match
  `/items?page=2`. Either anchor before the `?` (`^/items(\\?|$)`) or disable
  `matchQueryStrings`.
- **Remote config lands on next launch**, not immediately (§2.4).
- **`pull_to_refresh_enabled` defaults differ per platform** (`true` iOS / `false` Android).
  Always set it explicitly in the catch-all rule.

### G8. `connect()` runs more than once

Because of `native:restore`, a bridge component's `connect()` is re-invoked when a screen
returns to the foreground. Non-idempotent `connect()` (appending a DOM node, incrementing a
counter, `send`ing a "create" event) will misbehave. Also: **always call `super.connect()`**,
or `native:restore` is never wired and your native controls vanish after a Back.

### G9. `hotwire_native_app?` is UA sniffing

Spoofable. Fine for presentation, never for authorization or billing decisions. And it will
return `true` for legacy Turbo Native clients (`/(Turbo|Hotwire) Native/`), which is usually
what you want but is worth knowing.

### G10. Android WebView `target="_blank"`

A JS-initiated `.click()` on an anchor with `target="_blank"` fails to yield a URL in Android
WebView. `BridgeElement#click()` strips the attribute first. If you write your own click
plumbing, replicate that.

### G11. Version skew is permanent

Users don't update apps. At any moment you are serving:
- app builds that support component set A, and others that support set B,
- app builds pinned to `ios_v1.json` and others to `ios_v2.json`,
- and *all of them* get today's HTML.

The `[data-bridge-components~="x"]` CSS pattern handles component skew elegantly. Path-config
versioning handles config skew. **Nothing handles HTML/JS skew except discipline:** never
remove a URL or change a form's parameter names without a deprecation window.

### G12. Debugging is easier than the old posts say

⚠️ **OUTDATED:** pre-Oct-2024 posts tell you to set `webView.isInspectable = true` manually
before handing the web view to a `Session`. **Hotwire Native now configures a debuggable web
view automatically** (`WKWebView.debugInspectable(configuration:)` is the default
`makeCustomWebView`). Just: Safari → Settings → Advanced → *Show features for web developers*
→ Develop menu → your simulator → the web view. Requires a **Debug** build.

Also on by default in the current libraries:

```swift
Hotwire.config.debugLoggingEnabled = true
Hotwire.config.log = MyAppLogger()   // forward Hotwire logs to your own framework
```

which logs visits *and* bridge component connect/disconnect/send/receive — the fastest way to
diagnose "my bridge component isn't firing" (usually: the component name isn't in the UA, or
`super.connect()` wasn't called).

### G13. Performance

- Web-view scrolling is good; long lists with heavy per-row JS are not. Prefer server-rendered
  pagination over infinite scroll with client-side templating.
- Avoid `position: fixed` bars — they interact badly with the keyboard and safe areas. This is
  precisely what nav-bar bridge components are for.
- Set `viewport-fit=cover` and use `env(safe-area-inset-*)` if you keep any fixed chrome.
- Turbo morphing (`turbo-refresh-method: morph`) matters more in native than on the web,
  because `refresh` presentations are common.

---

## Outdated-advice map

Half the Hotwire Native content on the internet predates October 2024. This table is the
decoder ring. **The reliable signal is the URL slug and publish date, not the title** — Joe
Masilotti edits old post *bodies* in place to say "Hotwire Native" while leaving
`/turbo-native-*/` slugs intact.

Two flag styles appear on masilotti.com. A banner:

> ### This post was written for Turbo Native
> It may still be useful, but parts of it are outdated.

…and precise inline notes ("Update October 15, 2024: …"), which are the more useful ones.

| ⚠️ Outdated approach | Current approach | Notes |
|---|---|---|
| `@hotwired/strada`, `strada-ios`, `strada-android`; "Strada components" | `@hotwired/hotwire-native-bridge`; "Bridge components", built into Hotwire Native | Renamed 2024-10-15. `window.Strada` / `window.webBridge` still aliased. `strada-web` is frozen. |
| `hotwired/turbo-ios`, `hotwired/turbo-android` | `hotwired/hotwire-native-ios`, `hotwired/hotwire-native-android` | Same rename. |
| `joemasilotti/TurboNavigator` as a separate dependency | Built in as `Navigator` | Upstreamed; it *is* the iOS navigation layer now. |
| Docs at `turbo.hotwired.dev/handbook/native` and `strada.hotwired.dev` | `native.hotwired.dev` | |
| Demo at `turbo-native-demo.glitch.me` / `hotwired/turbo-native-demo` | `hotwire-native-demo.dev` / `hotwired/hotwire-native-demo` (a real Rails 8 app) | Rebuilt for v1.2, April 2025. |
| `TurboNavigator(pathConfiguration:)` — per-`Navigator` path config | `Hotwire.loadPathConfiguration(from:)` — **global**, in `AppDelegate`, before any `Navigator` exists | **Breaking change in 1.1.** The old per-instance API caused the classic "why isn't my config applying" bug. |
| `Hotwire.config.userAgent = "..."` (assign the whole string) | `Hotwire.config.applicationUserAgentPrefix = "My App;"` | **Breaking change in 1.1.** The framework now appends `Hotwire Native iOS; Turbo Native iOS; bridge-components: [...]` itself — don't hand-write those. |
| Hand-rolled `WKScriptMessageHandler` + `evaluateJavaScript(...)` string interpolation to call Swift from Stimulus | `BridgeComponent` + `this.send()` / `onReceive(message:)` / `reply(to:)` | Typed, correlated request/reply with `Decodable` payloads. |
| Manually subclassing `UITabBarController` in a Storyboard for native tabs | `HotwireTabBarController` + `HotwireTab` (iOS 1.2+), `HotwireBottomNavigationController` (Android) | |
| Hand-adding `/recede_historical_location` etc. to path configuration | Built in since **Hotwire Native 1.2.0** | See `PathRule+ServerRoutes.swift`. Harmless if you leave them, just noise. |
| `webView.isInspectable = true` for Safari debugging | Automatic | See G12. |
| Manual `Bridge.initialize(webView)` + a custom `BridgeDestination` / `BridgeDelegate` subclass to wire Strada into a Turbo Native app (six manual steps) | `Hotwire.registerBridgeComponents([...])` — one call | |
| `turbo_native_app?` | `hotwire_native_app?` | Live `alias_method`, **no deprecation warning**. Old code keeps working; the UA regex `/(Turbo\|Hotwire) Native/` matches both eras deliberately. |
| JS `alert()`/`confirm()` needing a custom handler | Handled automatically | Since 2024-10-15. |
| Bridge components load on any native client; guard with `this.enabled` | Gated automatically by `shouldLoad` against the UA component list | Behaviour change in bridge JS **1.1.0** (2025-03-12). |

**Posts that look old but are current:** `/hotwire-native-app-store-tips/`,
`/when-to-upgrade-turbo-native-screens/`,
`/progressively-enhanced-turbo-native-apps-in-the-app-store/`, `/turbo-native-app-roadmap/` —
Turbo-Native-era slugs and dates, but bodies were edited in place and carry no banner. Their
*advice* is current; some of their *outbound links* point at posts whose code samples are not.

---

## The book: *Hotwire Native for Rails Developers*

Joe Masilotti, Pragmatic Bookshelf ("Facets of Ruby" series), foreword by DHH.
270pp, ISBN 9798888651513, **published September 2025** (P1.0, 2025-09-10), $30.95.
<https://pragprog.com/titles/jmnative/hotwire-native-for-rails-developers/>
Code: `media.pragprog.com/titles/jmnative/code/jmnative-code.zip`. Errata on DevTalk.

**Prerequisites:** basic Rails CRUD + Stimulus familiarity. **No Swift/Kotlin experience
required.** Needs macOS, Ruby 3.4.2, SQLite, Xcode 16, Android Studio Meerkat+.

**Premise:** builds a hiking-tracker Rails app, then progressively grows iOS *and* Android
apps around it, driving as much as possible from Rails.

### Table of contents

| Ch. | Title | Covers |
|---|---|---|
| — | **Preface** *(free excerpt)* | The problem with native apps; the hybrid solution; prerequisites; structure. |
| 1 | **Build Your First Hotwire Native Apps** *(excerpt)* | iOS app; Android app; crash course in Swift + Kotlin syntax. |
| 2 | **Control Your Apps with Rails** *(excerpt)* | Native title via `<title>`/`content_for`; hide nav bar with Ruby; hide it with CSS (and the caching argument); keep users signed in between launches; camera & photo access on both platforms. |
| 3 | **Navigate Gracefully with Path Configuration** | Routing modals; iOS + Android path config; wiring both clients. |
| 4 | **Add a Native Tab Bar** | Directory/package cleanup; tabs on iOS and Android; **not overloading the server at app start** (each tab is its own web view). |
| 5 | **Render Native Screens with SwiftUI** *(excerpt)* | *When to go native*; SwiftUI map screen; `UIViewController` bridge; route via path config; JSON endpoint + model/view-model. |
| 6 | **Render Native Screens with Jetpack Compose** | Compose integration; route via path config; Google Maps key; JSON model/view-model. |
| 7 | **Build iOS Bridge Components with Swift** | Install the bridge; HTML markup; Stimulus controller; native component; customisation. |
| 8 | **Build Android Bridge Components with Kotlin** | Native component; respond to taps; remove duplicate buttons; dynamic text; dynamic image. |
| 9 | **Deploy to Physical Devices with TestFlight and Play Testing** | App Store Connect; archive & upload; TestFlight; Play Console; signed app bundle; distributing to testers. |
| 10 | **Send Push Notifications with APNs and FCM** | Sending from Rails; configuring iOS; configuring Android. |

**Notable framing from the free Preface**, which is the best one-paragraph case for the whole
architecture:

> "After an initial upfront cost, it's possible to not touch the native code again for years.
> I had the same version of a Hotwire Native app in the App Store for almost five years, all
> while receiving weekly feature updates and bug fixes via changes to the Rails codebase."

Structurally the book is *exactly* the ladder from §1.5 — chapters 2–4 are "do it all from
Rails", 5–6 are native screens, 7–8 are bridge components, 9–10 are the operational tail.
It confirms that the ecosystem's own pedagogy puts **"control your apps with Rails" before
any native code at all**, which is the posture crosswire should adopt.

---

## Implications for our library

This is the strategic section. The constraint set above is unusually *legible*, and it points
at a small number of concrete design rules for crosswire.

### I1. Make "degrades to native" a first-class variant of every interactive component

The stacked-controller pattern from the demo menu (§3.7) should be the **house pattern**, not
a special case. For each interactive component we ship (menu, dialog, sheet, picker, toast,
confirm, share, file-attach), ship *two* controllers:

- `foo_controller.js` — the pure web implementation. Works in every browser. No knowledge of native.
- `bridge/foo_controller.js` — a `BridgeComponent` that, **when and only when `this.enabled`**,
  calls `event.stopImmediatePropagation()` and delegates to native, then replays the result
  into the same DOM the web controller would have manipulated.

The markup that consumes them is *identical* on web and native:

```erb
<div data-controller="menu bridge--menu">
  <button data-action="click->bridge--menu#show click->menu#show">…</button>
```

This works because `BridgeComponent.shouldLoad` is false in browsers — the bridge controller
is **never even registered** outside a native app, so there is genuinely zero cost. We should
document that fact loudly, because it's the thing that makes the pattern free.

**Ordering rule to encode in our helpers:** the bridge action must be listed *first* in
`data-action`. Our view helpers should emit the attribute so authors can't get it wrong.

### I2. Every component's public contract must be expressible as `{value} → DOM action`

We should require, for any component we bless as "native-ready", that its native path
reduces to: native collects a value → replies → **web performs an ordinary DOM action**
(`click()`, set input + dispatch `input`, `requestSubmit()`).

Practical consequence: **behaviour must live in HTML, not in JS.** A menu item must be a real
`<a href>` or a real `<button>` inside a real `<form>` — not a JS handler that calls
`fetch()`. If the behaviour is only reachable through JS, the native replay can't reproduce
it, and we'd be forced to duplicate logic natively. This is a *good* constraint that pushes
us toward progressive enhancement anyway.

Test we can actually run: **for every component, the native path must be simulable by
`element.click()` in a browser test.** If it isn't, the design is wrong.

### I3. Ship the accessibility attributes the bridge already reads

`BridgeElement#title` falls back `data-bridge-title` → `aria-label` → `textContent` → `value`.
So a component that already sets a good `aria-label` gets a correct native button title for
free. Our helpers should:

- always emit `aria-label` on icon-only controls (we should anyway),
- expose a `bridge_title:` option that emits `data-bridge-title` when the native label should
  differ (native controls want *shorter* labels — "Save", not "Save changes to this record"),
- never rely on `textContent` alone for anything that could become a native control.

### I4. Adopt the `data-bridge-*` namespace as our native-hint channel

Rather than inventing our own attributes, put native hints in `data-bridge-*`, because they're
readable via `bridgeAttribute()` with no extra plumbing and they're inert on the web. Candidates:

- `data-bridge-title` — native label
- `data-bridge-disabled="ios"` — hide this option on one platform
- `data-bridge-icon="square.and.arrow.up"` — SF Symbol / Material icon hint
- `data-bridge-style="destructive"` — maps to `UIAlertAction.Style.destructive`

And use `data-controller-optout-ios` / `-android` (already supported) for per-instance escape
hatches instead of inventing our own.

### I5. Two-tier CSS: `@native` utilities + component-scoped bridge selectors

Adopt both patterns from the demo:

```css
/* Tier 1: coarse. Loaded only for native clients. */
.hide\@native  { display: none !important; }
.only\@native  { display: none; }            /* revealed by the native stylesheet */

/* Tier 2: fine-grained and version-aware. Safe to ship to everyone. */
[data-bridge-components~="menu"] [data-controller~="bridge--menu"] .c-menu__web-trigger {
  display: none;
}
```

Tier 2 selectors should ship in the **main** stylesheet, not the native one, because they're
inert without `data-bridge-components` and they must be *component-version-aware* — an old app
build that lacks the `menu` component keeps its web menu automatically. Each component we
ship with a native counterpart should include its own tier-2 rule in its own CSS file, so the
rule and the component version together.

### I6. Design the DOM so a screen is self-contained

Because background screens are frozen screenshots and modals are separate web views (§1.2, §G6):

- **No component may depend on updating an element on another screen.** Broadcast-driven UI
  ("live" counters, presence indicators) works *within* the visible screen only.
- **Any component that opens in a modal must define its "what happens to the parent" story**
  as a *navigation* outcome, and our Rails helpers should make that easy:

  ```ruby
  # proposed helper for our library
  respond_to_form_submission(
    on_success: :refresh,      # → refresh_or_redirect_to
    fallback:   items_path
  )
  ```

  i.e. a thin, opinionated wrapper over `refresh_or_redirect_to` / `recede_or_redirect_to` /
  `resume_or_redirect_to` so component authors pick a *semantic* outcome and we translate.
- **Every modal-capable component must document its dismissal contract**, and our generated
  path-configuration should keep pace (see I7).

### I7. Generate the path configuration from the same place we define routes

Path configuration is a second routing table that will drift from `config/routes.rb`.
We should offer a Ruby DSL that produces both JSON documents, so authors write one thing:

```ruby
# config/hotwire_native.rb  (sketch)
HotwireNative.configure do
  default pull_to_refresh: true

  modal   %r{/new$}, %r{/edit$}, pull_to_refresh: false
  modal   filters_path, style: :medium
  reset   root_path                       # presentation: clear_all
  replace dashboard_path                  # presentation: replace_root
  native  map_path, ios: "map", android: "hotwire://fragment/map"
end
```

…which renders `ios_v1.json` and `android_v1.json`, automatically injecting Android's required
`uri: "hotwire://fragment/web"` catch-all and anchoring regexes. Value delivered:

- one file instead of two, no duplicated regexes;
- **anchoring by default** (§G7 foot-gun eliminated);
- route helpers instead of hand-written paths;
- a test we can ship: assert that every `native` declaration has a working web route (the
  progressive-rollback guarantee from §7.3);
- versioning built in (`HotwireNative.version = 2` → serve `_v2` and keep `_v1`).

This is probably the highest-leverage Rails-side artifact crosswire could produce, because
nothing in the ecosystem does it today.

### I8. Bake the native-aware response idioms into our controller concern

A small concern that makes the right thing the default:

```ruby
module Crosswire::NativeAware
  extend ActiveSupport::Concern

  included do
    before_action { request.variant = :hotwire_native if hotwire_native_app? }
    helper_method :hotwire_native_ios?, :hotwire_native_android?, :native_bridge_components
  end

  # 401 for native, redirect for web — see §5.2
  def require_authentication!
    return if authenticated?
    hotwire_native_app? ? head(:unauthorized) : redirect_to(new_session_path)
  end
end
```

…plus a documented rule that **auth failures are `head :unauthorized` for native clients**,
because that single decision is the difference between a sane and an insane login experience,
and almost nobody gets it right first time.

### I9. Prefer CSS/UA-attribute branching over template branching

House rule: **`hotwire_native_app?` in a *view* is a smell; `hide@native` is the answer.**
Reserve server-side branching for:

- the layout (`layout -> { hotwire_native_app? ? "native" : "application" }`),
- asset payload decisions (don't ship the heavy chart JS),
- HTTP status/redirect semantics (§5.2, §6.4).

This keeps one HTML document, one cache key, and one code path to test.

### I10. Every component needs a documented "native fidelity" tier

We should label each component in our catalog:

| Tier | Meaning |
|---|---|
| **Web-only** | Fine in a web view as-is. No native counterpart. (Most components.) |
| **Bridge-ready** | Ships a `BridgeComponent` + a documented message contract + the tier-2 CSS + a reference Swift/Kotlin implementation in our docs. |
| **Native-required** | Genuinely doesn't work in a web view; we document the native screen and *require* a web fallback page at the same URL. |

And for every **Bridge-ready** component, publish the message contract as a small table
(events, payload shape, reply shape) so that Swift/Kotlin developers — who may not read our
JS — can implement against a spec. **The message contract is our real API surface for
native**, and it deserves to be versioned and documented like one.

### I11. Compose with `bridge-components`, don't compete with it

Masilotti's library already covers the obvious catalog (alert, button, form, haptic, menu,
review, search, share, theme, toast — free; hardware components — paid), it's widely used, and
it's maintained by the iOS library's co-maintainer. Building a rival catalog is a bad use of
our time.

The high-value move is **interoperability**: make crosswire's web components emit the
`data-bridge-*` attributes his components already read, so that a team using both gets native
enhancement for free. Concretely:

- our menu component's items should already carry `data-bridge-title` and accept
  `data-bridge-ios-image` / `data-bridge-android-image` passthrough;
- our confirm/`data-turbo-confirm` wrapper should be shaped so his **Alert** component can
  intercept it;
- our toast/flash partial should be markup his **Toast** component can attach to;
- our form helper should emit the `bridge--form` wiring (§4.6) behind an opt-in flag.

Then document, per component: *"native-enhanced by `bridge-components` X — add the Swift/Kotlin
file, no markup changes needed."* That is a much stronger story than "here is our ninth
implementation of a share sheet."

### I12. Don't fight the frame; give people the ladder

The strategic posture: crosswire's job is to make the **web tier so good that the bridge tier
is rarely needed, and the native tier almost never**. Concretely, the components most worth
building well are the ones that native shells otherwise force you to escape from:

- **nav-bar-anchored actions** (because `position: fixed` + keyboard is the classic failure),
- **sheets/menus** (because the web versions feel wrong on touch),
- **forms with long content and a distant submit** (the `form` bridge component exists for
  exactly this reason),
- **toasts/flashes** (because a web flash dies on navigation).

Every one of these has a known bridge component. Building the *web* version well, with the
bridge hook pre-wired, is the highest-value thing we can ship.

---

## Open Questions

1. **Do we depend on `hotwire_native_rails` (yshmarov, v0.4.4) or supersede it?**
   *Resolved enough to decide:* it's a one-shot generator at 0.x with a single maintainer and
   no runtime API. Recommendation — **don't depend on it; borrow its two good ideas**
   (`bridge_form_with` + `BridgeFormBuilder`, and the Tailwind variant) and build I7 ourselves.
2. **~~Is there an official Rails-side path-configuration generator?~~** *Answered: no.*
   Nothing in turbo-rails, the demo app, or `hotwire_native_rails` (which just hard-codes a
   hash in a controller). **I7 is a genuine, unfilled gap.**
3. **`@hotwired/hotwire-native-bridge` has been at 1.2.2 since 2025-08-21** while the native
   libraries moved 1.2 → 1.3.1. Is the JS package effectively feature-complete, or is it
   lagging? Affects whether we should vendor a shim for anything.
4. **Do we ship a bridge-component library at all, given Masilotti's already exists?**
   His free tier covers alert/button/form/haptic/menu/review/search/share/theme/toast, and the
   paid tier covers hardware. Building a competing catalog is probably wasted effort; the
   better play is to make our *web* components emit the `data-bridge-*` attributes **his**
   components already consume, so crosswire + bridge-components compose. Needs a read of his
   attribute contracts to confirm they're stable enough to target.
5. **How does the bridge behave inside a Turbo Frame that lazy-loads after `native:restore`?**
   `shouldLoad` is evaluated at controller-registration time, but `connect()` fires per
   element — need to verify a component inside a `<turbo-frame loading="lazy">` gets its
   native counterpart correctly on a restored screen.
6. **Can a bridge component reliably target a *modal's* native chrome while the main stack's
   component is also connected?** iOS 1.3.1 shipped "Keep bridge destinations active while
   attached" (PR #253), which suggests this was buggy. Worth testing before we depend on it.
7. **Action Cable in native:** each web view opens its own WebSocket. A 4-tab app with modals
   could hold 8. Is there a recommended pattern for suppressing subscriptions on
   non-visible screens? (The demo's `settings.cable.script_url` hints at *something*, but
   it's undocumented.)
8. **Do we want to ship reference Swift/Kotlin implementations** for our bridge-ready
   components, or only the message contracts? Shipping code means maintaining two more
   toolchains; shipping contracts risks nobody implementing them.
9. **What's the story for `presentation: refresh` + morphing when the parent screen has
   unsaved form state?** Morphing preserves more than a reload, but not everything. Needs a
   documented recommendation.
10. **iPadOS / multi-window:** `HotwireTabBarController` and the two-session model in a
   multi-scene app — untested territory for us.
11. **Testing:** is there any established way to system-test the native path (e.g. spoofing
    the UA + `data-bridge-components` in Capybara) so our bridge components have CI coverage
    without a simulator? This seems tractable and valuable.

---

## Sources

### Official documentation (all read in full, 2026-08-15)

- Overview: [How it Works](https://native.hotwired.dev/overview/how-it-works) ·
  [Basic Navigation](https://native.hotwired.dev/overview/basic-navigation) ·
  [Path Configuration](https://native.hotwired.dev/overview/path-configuration) ·
  [Bridge Components](https://native.hotwired.dev/overview/bridge-components) ·
  [Native Screens](https://native.hotwired.dev/overview/native-screens)
- iOS: [Getting Started](https://native.hotwired.dev/ios/getting-started) ·
  [Tabs](https://native.hotwired.dev/ios/tabs) ·
  [Path Configuration](https://native.hotwired.dev/ios/path-configuration) ·
  [Bridge Components](https://native.hotwired.dev/ios/bridge-components) ·
  [Native Screens](https://native.hotwired.dev/ios/native-screens) ·
  [Configuration](https://native.hotwired.dev/ios/configuration) ·
  [Reference](https://native.hotwired.dev/ios/reference)
- Android: [Getting Started](https://native.hotwired.dev/android/getting-started) ·
  [Tabs](https://native.hotwired.dev/android/tabs) ·
  [Path Configuration](https://native.hotwired.dev/android/path-configuration) ·
  [Bridge Components](https://native.hotwired.dev/android/bridge-components) ·
  [Native Screens](https://native.hotwired.dev/android/native-screens) ·
  [Configuration](https://native.hotwired.dev/android/configuration) ·
  [Reference](https://native.hotwired.dev/android/reference)
- Reference: [Navigation](https://native.hotwired.dev/reference/navigation) ·
  [Path Configuration](https://native.hotwired.dev/reference/path-configuration) ·
  [Bridge Installation](https://native.hotwired.dev/reference/bridge-installation) ·
  [Bridge Components](https://native.hotwired.dev/reference/bridge-components)

### Source code read directly

- <https://github.com/hotwired/hotwire-native-bridge> @ 1.2.2 — `src/bridge_component.js`,
  `src/bridge.js`, `src/bridge_element.js`, `src/index.js`, `src/helpers/user_agent.js`
- <https://github.com/hotwired/hotwire-native-ios> @ 1.3.1 — `Source/HotwireConfig.swift`,
  `Source/Bridge/UserAgent.swift`, `Source/Turbo/Navigator/Navigator.swift`,
  `Source/Turbo/Session/Session.swift`, `Source/Turbo/Visitable/VisitableView.swift`,
  `Source/Turbo/Path Configuration/PathRule.swift`, `.../PathRule+ServerRoutes.swift`,
  `Demo/Bridge/{FormComponent,MenuComponent,OverflowMenuComponent}.swift`,
  `Demo/SceneController.swift`
- <https://github.com/hotwired/hotwire-native-android> @ 1.3.1 —
  `demo/src/main/kotlin/dev/hotwire/demo/bridge/*.kt`, `core/.../config/HotwireConfig.kt`
- <https://github.com/hotwired/hotwire-native-demo> (the Rails app behind hotwire-native-demo.dev) —
  `app/controllers/configurations_controller.rb`, `app/controllers/sessions_controller.rb`,
  `app/views/layouts/application.html.erb`, `app/views/shared/_nav.html.erb`,
  `app/views/components/{new,menu,overflow}.html.erb`,
  `app/javascript/controllers/bridge/*.js`, `app/assets/stylesheets/native.css`,
  `config/importmap.rb`, `config/routes.rb`
- <https://github.com/hotwired/turbo-rails> @ 2.0.23 —
  `app/controllers/turbo/native/navigation.rb`,
  `app/controllers/turbo/native/navigation_controller.rb`, `config/routes.rb`,
  `lib/turbo/engine.rb`

### 37signals

- [Announcing Hotwire Native](https://dev.37signals.com/announcing-hotwire-native/) —
  Jay Ohms, 2024-09-25. The Turbo Native + Strada consolidation; credits Joe Masilotti's
  TurboNavigator as the foundation of the new iOS navigation layer.
- [Announcing Hotwire Native 1.2](https://dev.37signals.com/announcing-hotwire-native-v1-2/) —
  Jay Ohms, 2025-04-23. Route decision handlers, built-in historical-location support,
  `HotwireTabBarController` / `HotwireBottomNavigationController`, new demo apps.
- [Announcing Strada](https://dev.37signals.com/announcing-strada/) — Jay Ohms, 2023-09-20.
  "We've been using Strada to build the HEY mobile apps for the past 3 years."
  ⚠️ Historical only — Strada no longer exists as a separate library.
- The docs site footer lists Basecamp, HEY, **Fizzy** (fizzy.do), and ONCE as the products
  behind Hotwire.

### Joe Masilotti (masilotti.com) — co-maintainer of hotwire-native-ios, author of the book

**Current era — safe to follow:**

- [Hotwire Native hub](https://masilotti.com/hotwire-native/) — the pillar page.
- [Hotwire Native by Example](https://masilotti.com/hotwire-native-by-example/) — focused tutorials:
  [native screen titles](https://masilotti.com/hotwire-native-by-example/native-screen-titles/) ·
  [hide content with Tailwind](https://masilotti.com/hotwire-native-by-example/hide-content-tailwind-css/) ·
  [modal forms](https://masilotti.com/hotwire-native-by-example/modal-forms/) ·
  [tabs](https://masilotti.com/hotwire-native-by-example/tabs/) ·
  [opaque native bars](https://masilotti.com/hotwire-native-by-example/opaque-native-bars/)
- [10 tips from 10 years of Hotwire Native](https://masilotti.com/10-hotwire-native-tips/) (2024-12-12)
  — includes the `refresh_historical_location` + `refresh_or_redirect_to` recipe.
- [App Store submission tips for Hotwire Native](https://masilotti.com/hotwire-native-app-store-tips/)
  — guidelines 4.2, 2.1 (the file-input crash), 5.1.1(v) account deletion, 3.1.3(b) IAP, 2.3.2.
- [Bridge Components library](https://masilotti.com/bridge-components/) ·
  [launch post](https://masilotti.com/bridge-component-library/) (2025-03-27) ·
  [github.com/joemasilotti/bridge-components](https://github.com/joemasilotti/bridge-components)
- Release notes: [1.1](https://masilotti.com/hotwire-native-1.1/) ·
  [1.2 (video)](https://masilotti.com/hotwire-native-1.2-video/) ·
  [1.2.x](https://masilotti.com/hotwire-native-v1.2.x/)
- [Turbo Native is dead, long live Hotwire Native](https://masilotti.com/turbo-native-is-dead-long-live-hotwire-native/) (2024-10-11)
- [A Rails developer's guide to mobile app frameworks](https://masilotti.com/rails-developers-guide-to-mobile-app-frameworks/)
- [Book chapter walkthrough](https://masilotti.com/hotwire-native-book-chapters/)

**⚠️ Turbo Native era — read only with the [outdated-advice map](#outdated-advice-map) in hand.**
Most carry Joe's own "This post was written for Turbo Native" banner: the `/turbo-ios/` 6-part
series, `/turbo-native-tabs/`, `/turbo-native-path-configuration/`, `/turbo-native-pull-to-refresh/`,
`/uimenu-turbo-native/`, `/call-swift-from-stimulus-turbo-native/`,
`/interacting-with-stimulus-from-turbo-native/`, `/javascript-alerts-in-turbo-native/`,
`/hide-web-rendered-content-on-turbo-native-apps/`, `/debug-turbo-native-apps-with-safari/`,
`/turbo-native-apps-in-15-minutes/`, `/strada-launch/`, `/strada-and-turbo-navigator/`,
`/turbo-navigator-upstream/`.

### The book

- [Hotwire Native for Rails Developers](https://pragprog.com/titles/jmnative/hotwire-native-for-rails-developers/)
  — Pragmatic Bookshelf, Sept 2025, 270pp, ISBN 9798888651513. Foreword by DHH.
  Free Preface excerpt + sample chapters 1, 2, 5 (`media.pragprog.com/titles/jmnative/*.pdf`).
  Linked directly from the official demo app's routes file:
  `direct(:book) { "https://pragprog.com/titles/jmnative/hotwire-native-for-rails-developers/" }`.

### Rails-side ecosystem

- [yshmarov/hotwire_native_rails](https://github.com/yshmarov/hotwire_native_rails) ·
  [rubygems](https://rubygems.org/gems/hotwire_native_rails) — v0.4.4 (2025-03-11).
  Generator, not a runtime library. **Note: `turbo_native_rails` does not exist.**
- [@hotwired/hotwire-native-bridge on npm](https://www.npmjs.com/package/@hotwired/hotwire-native-bridge) — v1.2.2.
  ⚠️ Its predecessor `@hotwired/strada` is frozen; migrate.
- [joemasilotti/hotwire-native-blog-demo](https://github.com/joemasilotti/hotwire-native-blog-demo)
- [jumpstart-pro/example-hotwire-native-rails-backend](https://github.com/jumpstart-pro/example-hotwire-native-rails-backend)
- blog.corsego.com / superails.com (Yaro Shmarov) — per-component cookbook, cited by the generator's own templates.

### Apple / Google

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) —
  especially [4.2](https://developer.apple.com/app-store/review/guidelines/#4.2),
  [2.1](https://developer.apple.com/app-store/review/guidelines/#2.1),
  [5.1.1(v)](https://developer.apple.com/app-store/review/guidelines/#5.1.1v),
  [3.1.3(b)](https://developer.apple.com/app-store/review/guidelines/#3.1.3b)
- [Offering account deletion in your app](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
