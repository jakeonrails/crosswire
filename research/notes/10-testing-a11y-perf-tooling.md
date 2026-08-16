# Testing, Accessibility, Performance & Tooling — the Four Cross-Cutting Concerns

> Research note for **crosswire**. Compiled 2026-08-15.
> These are the four concerns that decide whether a component library is *usable by other people* rather
> than just *demoable*. Every one of them is a decision we have to make once, early, and then live with.
>
> Code marked `[SOURCE]` was read directly from a clone of the named repository, not from prose docs.
> Version facts were verified against npm/rubygems on 2026-08-15.

**Version baseline for this document**

| Thing | Version | Note |
|---|---|---|
| `@hotwired/turbo` | **8.0.23** | There is no Turbo 9 |
| `turbo-rails` | **2.0.23** | `Turbo::VERSION` read from source |
| `@hotwired/stimulus` | 3.2.2 | API-frozen since 3.2.0 |
| `idiomorph` | 0.7.4 | Turbo inlines it at build time |
| `capybara` | 3.40.0 | |
| `cuprite` | 0.17 | |
| `vitest` | 4.1.10 | browser mode is mature |
| `@web/test-runner` | **1.0.0** | hit 1.0 on 2026-07-07 |
| `playwright` | 1.62.1 | |
| `axe-core` / `@axe-core/playwright` | 4.13.0 | |
| `axe-core-rspec` / `axe-core-capybara` (gems) | 4.13.0 | |
| `lookbook` | 2.3.14 | |
| `hotwire-spark` | 0.1.13 | **not** a Rails 8 default |
| `@herb-tools/linter` / `stimulus-lint` | 0.10.3 / 0.4.3 | |

Rack 3.1 renamed HTTP 422 to **Unprocessable Content**; `:unprocessable_entity` is a deprecated alias.
Prefer `:unprocessable_content`.

---

## Table of Contents

1. [Testing](#1-testing)
   - 1.1 [What the ecosystem actually does — test-suite archaeology](#11-archaeology)
   - 1.2 [Unit-testing Stimulus controllers](#12-unit-testing)
   - 1.3 [Rails-side: request/integration tests for Turbo](#13-rails-integration)
   - 1.4 [Rails-side: broadcasts](#14-broadcasts)
   - 1.5 [System tests and the flakiness problem](#15-system-tests)
   - 1.6 [Preview pages and visual testing](#16-previews)
2. [Accessibility](#2-accessibility)
   - 2.1 [What Turbo breaks by default](#21-what-turbo-breaks)
   - 2.2 [The official position — issue archaeology](#22-official-position)
   - 2.3 [The route announcer and focus patterns](#23-announcer)
   - 2.4 [APG pattern specs for the widgets we're building](#24-apg)
   - 2.5 [How the existing libraries do — named and shamed](#25-audit)
   - 2.6 [Automated a11y testing](#26-a11y-testing)
3. [Performance](#3-performance)
4. [Debugging & Dev Tooling](#4-debugging)
5. [**Testing recipe**](#testing-recipe)
6. [**A11y checklist**](#a11y-checklist)
7. [**Performance checklist**](#performance-checklist)
8. [**Debugging playbook**](#debugging-playbook)
9. [**Recommendations for crosswire**](#recommendations)

---

<a name="1-testing"></a>
## 1. Testing

<a name="11-archaeology"></a>
### 1.1 What the ecosystem actually does — test-suite archaeology

Rather than reason about what *should* be used, we cloned every relevant library and read its
`package.json`, CI workflow, and actual test files. This is the decision-relevant evidence.

| Repo | Runner | Real browser or jsdom? | Coverage | Ships |
|---|---|---|---|---|
| **hotwired/stimulus** | Karma + QUnit | Real: Chrome **+ Firefox** headless | 47 test files, comprehensive | ESM + UMD + types (Rollup) |
| **stimulus-components** (monorepo) | **Vitest** | **jsdom** | 22 tested / 32 components | ESM + UMD + types + `./src` (Vite lib mode, per package) |
| **tailwindcss-stimulus-components** | `@web/test-runner` | Real: headless Chromium via Puppeteer | 8 / 10 controllers | ESM + CJS (esbuild) |
| **stimulus-use** | **Vitest browser mode** (Playwright provider) | Real: Chromium | 29 specs, comprehensive | ESM + UMD + types + `./hotkeys` subpath (Rollup) |
| **hotwired/turbo** | `@web/test-runner` **and** `@playwright/test` | Real: unit on Chromium/FF/WebKit; functional on Chrome + FF | 5 unit + 27 functional | ESM + UMD, ES2017 (Rollup) |
| **hotwired/turbo-rails** | **none for JS** | Ruby Minitest + Capybara/Cuprite | **0 JS test files** | raw ESM source dir |
| stimulus_reflex | Mocha | jsdom | 10 | raw ESM, no build |

Five findings that should shape our decision:

**(a) The closest peer to crosswire uses Vitest + jsdom, deliberately.** `stimulus-components` is the only
library at our scale (32 first-party controllers, small team). Its `vitest.config.mts` carries a
maintainer comment making clear the jsdom choice is considered, not accidental:

> *"Every spec drives a Stimulus Application against a real DOM… This only applies when Vitest resolves
> this config… each spec also carries its own `@vitest-environment jsdom` docblock. Both are needed;
> neither is redundant."*

**(b) It's normal to leave the hard ones untested.** 10 of 32 stimulus-components controllers have **zero**
tests — and they are precisely the third-party wrappers (Swiper, Chart.js, Sortable.js, Howler, Google
Places, GLightbox). Effort is concentrated on first-party logic. That is a defensible policy, not neglect.

**(c) Real browsers earn their keep for exactly one thing: focus.** The most a11y-serious test file in the
entire survey is `tailwindcss-stimulus-components/test/dropdown_test.js`, which asserts real
`document.activeElement` transitions after Escape and after outside-click — **and that library runs on a
real browser**. jsdom's focus model is not trustworthy enough for focus-trap and roving-tabindex
assertions. Turbo itself splits the same way: `@web/test-runner` for pure unit logic, Playwright against a
real Express server for anything navigational.

**(d) Nobody in this ecosystem uses axe-core.** Not one of the seven repos surveyed runs any automated
accessibility tool. Every a11y assertion anywhere is a hand-written `aria-*` / `activeElement` check.
Adopting axe would be a **deliberate departure from every peer** — which is exactly why it's an
opportunity (see §2.5).

**(e) Distribution consensus is ESM + one legacy format, Stimulus always a peer dependency.**
Three of five actively-built packages ship UMD alongside ESM; one ships CJS; `@hotwired/stimulus` is
externalised as a `peerDependency` in every single case and bundled in none. `stimulus-use` additionally
ships a `./hotkeys` **subpath export** to keep an optional dependency (`hotkeys-js`) out of the main
bundle — direct precedent for a "core + optional extras" packaging strategy.

<a name="12-unit-testing"></a>
### 1.2 Unit-testing Stimulus controllers

**Yes, it is actually done** — by every library except turbo-rails. But there is **no official test helper**
and no maintained community one:

- `@symfony/stimulus-testing` — jsdom + mutationobserver shim. Superseded. Don't adopt.
- `stimulus-jest` — unmaintained hobby project.
- The framework's own harness (`ControllerTestCase`) is internal, not published.

So everyone rolls a ~30-line `mount()` helper. Here is the one we should use, incorporating the four ideas
worth stealing from Stimulus's internal harness (see `03-stimulus-deep-dive.md` §15.1) plus the
`TestLogger` idea from stimulus-use:

```js
// test/support/stimulus.js
import { Application } from "@hotwired/stimulus"

export const nextFrame = () => new Promise(requestAnimationFrame)

/**
 * Mount a fixture with one or more controllers registered.
 * Returns { application, root, teardown }.
 */
export async function mount(html, controllers) {
  document.body.innerHTML = `<div id="fixture">${html}</div>`
  const root = document.getElementById("fixture")

  // CRITICAL: Stimulus swallows controller errors by default, which makes broken
  // controllers pass their tests. Re-throwing is the single most important test tip.
  const application = new (class extends Application {
    handleError(error) { throw error }
  })(root)                                   // scope to the fixture, NOT document.documentElement

  Object.entries(controllers).forEach(([id, klass]) => application.register(id, klass))
  application.start()
  await nextFrame()                          // Stimulus connects async, via MutationObserver

  return {
    application,
    root,
    element: root.firstElementChild,
    teardown() { application.stop(); document.body.innerHTML = "" }
  }
}

/** Record every event a controller dispatches — the stimulus-use TestLogger pattern. */
export function recordEvents(element, ...names) {
  const log = []
  names.forEach(name => element.addEventListener(name, e => log.push({ name, detail: e.detail })))
  return log
}
```

Four rules baked into that helper, each with a reason:

1. **Override `handleError` to throw.** Stimulus's `Application#handleError` logs and forwards to
   `window.onerror` (`[SOURCE]` `src/core/application.ts:87–91`). In a test runner nothing is listening,
   so a controller that throws in `connect()` produces a *passing* test.
2. **Scope the Application to the fixture element.** `application.stop()` then really cleans up, and
   tests can't leak into each other.
3. **`await nextFrame()` after every DOM mutation.** Stimulus connects on a microtask after a
   MutationObserver callback; a `requestAnimationFrame` await is the reliable barrier.
4. **Drive controllers through their declared contract** — set `data-*-value` attributes and dispatch real
   events, don't call methods on the instance. The attributes *are* the public API; that's what the server
   will write.

**The jsdom gap list.** jsdom lacks or fakes: `IntersectionObserver`, `ResizeObserver`, `matchMedia`,
`navigator.clipboard`, `HTMLDialogElement.showModal()`, `requestSubmit()`, `inert`, the Popover API,
`getBoundingClientRect` (returns all zeros), and — most importantly — a trustworthy **focus model**.
`requestAnimationFrame` is a `setTimeout` shim and is a known source of intermittent failures.

That list maps almost exactly onto crosswire's hardest components. Hence the two-tier recommendation in
§5.

<a name="13-rails-integration"></a>
### 1.3 Rails-side: request/integration tests for Turbo

turbo-rails ships **official assertion helpers that almost nobody knows about**. `[SOURCE]`
`lib/turbo/test_assertions.rb` and `lib/turbo/test_assertions/integration_test_assertions.rb`
(turbo-rails 2.0.23).

The base module gives four assertions:

```ruby
assert_turbo_stream(action:, target: nil, targets: nil, count: 1, &block)
assert_no_turbo_stream(action:, target: nil, targets: nil)
assert_turbo_frame(*ids, loading: nil, src: nil, target: nil, count: 1, &block)
assert_no_turbo_frame(*ids, **options, &block)
```

`:target` is smart: *"If the value responds to `#to_key`, the value will be transformed by calling
`dom_id`"* — so you pass the record, not a string. Same for `assert_turbo_frame`'s ids.

The **integration-test** flavour is the one you actually want, because it additionally asserts the status
and the media type before delegating:

```ruby
# [SOURCE] lib/turbo/test_assertions/integration_test_assertions.rb — verbatim
def assert_turbo_stream(status: :ok, **attributes, &block)
  assert_response status
  assert_equal Mime[:turbo_stream], response.media_type
  super(**attributes, &block)
end
```

Meaning a single `assert_turbo_stream` call checks three things at once: the response code, that the
server really replied `text/vnd.turbo-stream.html` (`[SOURCE]` `lib/turbo/engine.rb:77`), and that the
expected `<turbo-stream>` element is present.

```ruby
# test/integration/messages_test.rb
require "test_helper"

class MessagesTest < ActionDispatch::IntegrationTest
  include Turbo::TestAssertions::IntegrationTestAssertions

  test "creating a message appends it to the list" do
    message = messages(:one)

    post messages_path, params: { message: { content: "Hello" } }, as: :turbo_stream

    assert_turbo_stream action: "append", target: "messages" do
      assert_select "template .message", text: "Hello"
    end
  end

  test "an invalid message re-renders the form with 422" do
    post messages_path, params: { message: { content: "" } }, as: :turbo_stream

    # Rack 3.1: prefer :unprocessable_content. :unprocessable_entity is a deprecated alias.
    assert_turbo_stream status: :unprocessable_content, action: "replace", target: "new_message_form"
  end

  test "does not broadcast a removal for a draft" do
    post messages_path, params: { message: { content: "x", draft: true } }, as: :turbo_stream

    assert_no_turbo_stream action: "remove", target: messages(:one)   # record → dom_id
  end
end
```

`as: :turbo_stream` works because turbo-rails registers a custom `ActionDispatch::RequestEncoder`
(`[SOURCE]` `lib/turbo/engine.rb:121–128`) that sends `Accept: text/vnd.turbo-stream.html, text/html`.
Without it you'd hand-roll the header.

**`rails-controller-testing`** (gem 1.0.5, last released 2020-06-23) is effectively unmaintained.
`assert_template`/`assigns` are not the right tool for Turbo work — `assert_turbo_stream` + `assert_select`
cover it. Don't add it.

**RSpec**: `turbo_rspec` (gem, v1.6.2, eclectic-coding/turbo_rspec) exists and provides
`have_turbo_stream` / `have_turbo_frame` / `have_broadcasted_turbo_stream_to` matchers. Verified real, but
low adoption; the Minitest helpers above are first-party and better maintained.

<a name="14-broadcasts"></a>
### 1.4 Rails-side: broadcasts

`[SOURCE]` `lib/turbo/broadcastable/test_helper.rb` — `Turbo::Broadcastable::TestHelper` includes
`ActionCable::TestHelper` and adds three methods:

```ruby
assert_turbo_stream_broadcasts(stream_name_or_object, count: nil, &block)
assert_no_turbo_stream_broadcasts(stream_name_or_object, &block)
capture_turbo_stream_broadcasts(stream_name_or_object, &block)  # → [Nokogiri::XML::Element]
```

`capture_` is the good one. It JSON-decodes each Action Cable payload, parses it with
`Nokogiri::HTML5`, and hands you real `<turbo-stream>` elements you can assert against:

```ruby
class MessageTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "saving broadcasts an append then a replace" do
    message = Message.new(content: "Hi", room: rooms(:one))

    append, replace = capture_turbo_stream_broadcasts rooms(:one) do
      message.save!
      message.update!(content: "Hi there")
    end

    assert_equal "append",  append["action"]
    assert_equal "replace", replace["action"]
    assert_equal ActionView::RecordIdentifier.dom_id(message), replace["target"]
  end

  test "drafts do not broadcast" do
    assert_no_turbo_stream_broadcasts rooms(:one) do
      Message.create!(content: "draft", room: rooms(:one), draft: true)
    end
  end
end
```

The stream name accepts a String, a record, or an Array — the same polymorphism as `broadcast_*_to`.

**`broadcast_*_later` needs `perform_enqueued_jobs`.** The `_later` variants enqueue an Active Job that
does the rendering; without draining the queue nothing is ever broadcast and
`assert_no_turbo_stream_broadcasts` will pass for the wrong reason:

```ruby
include ActiveJob::TestHelper

test "broadcast_later renders in the job" do
  perform_enqueued_jobs do
    assert_turbo_stream_broadcasts rooms(:one), count: 1 do
      messages(:one).broadcast_append_later_to rooms(:one)
    end
  end
end
```

<a name="15-system-tests"></a>
### 1.5 System tests and the flakiness problem

#### The driver

turbo-rails' own setup is minimal and is the right starting point. `[SOURCE]`
`test/application_system_test_case.rb` — verbatim:

```ruby
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, using: :chrome, screen_size: [1400, 1400], options: { js_errors: true }
end

Capybara.configure do |config|
  config.server = :puma, { Silent: true }
end
```

`js_errors: true` is the load-bearing option: **a JS exception fails the test** instead of producing a
mystery timeout. Selenium cannot do this cleanly. That alone is the argument for Cuprite (gem 0.17,
CDP/Ferrum-based) over Selenium for a Hotwire app.

A fuller version for crosswire's dummy app:

```ruby
# test/application_system_test_case.rb
require "test_helper"

Capybara.configure do |config|
  config.server                = :puma, { Silent: true }
  config.default_max_wait_time = 5           # generous; Turbo requests are real HTTP
  config.disable_animation     = true        # kill CSS transitions — the #1 flake source
  config.save_path             = Rails.root.join("tmp/capybara")
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite,
    using: :chrome,
    screen_size: [1400, 1400],
    options: {
      js_errors: true,                        # fail the test on any uncaught JS error
      headless: ENV["HEADLESS"] != "false",   # HEADLESS=false to watch it run
      process_timeout: Integer(ENV.fetch("FERRUM_PROCESS_TIMEOUT", 15)),
      timeout:         Integer(ENV.fetch("FERRUM_DEFAULT_TIMEOUT", 10)),
      browser_options: { "no-sandbox": nil }  # required in most CI containers
    }
end
```

turbo-rails' own CI raises `FERRUM_PROCESS_TIMEOUT=25` and `FERRUM_DEFAULT_TIMEOUT=15` — CI runners are
slow to boot Chrome, and the default timeouts cause spurious failures. Rails 8's
`ActionDispatch::SystemTestCase` **already screenshots on failure**; no extra gem needed.

`Capybara.disable_animation = true` injects CSS that zeroes out transitions and animations. For a
component library full of dropdowns and modals with enter/leave transitions, this is not optional.

#### Capybara's waiting semantics — get this exactly right

This is the whole flakiness story in four rules:

| Expression | Waits? | Use it? |
|---|---|---|
| `assert_selector ".foo"` | Yes — polls until found or `default_max_wait_time` | ✅ |
| `assert_no_selector ".foo"` | Yes — polls until **absent** | ✅ |
| `page.has_css?(".foo")` | Yes — polls until found | ✅ |
| `page.has_no_css?(".foo")` | Yes — polls until absent | ✅ |
| **`!page.has_css?(".foo")`** | **Waits the full timeout, then negates a false** | ❌ **the classic trap** |
| `find(".foo")` | Yes | ✅ |
| `all(".foo")` | **No** — returns immediately | ⚠️ pass `count:`/`minimum:` to make it wait |
| `page.evaluate_script(...)` | No | ⚠️ |

`!page.has_css?` is the trap because it is *both* slow (always burns the full wait) and wrong (it can pass
before the element that's about to appear appears). Always use the positive `has_no_css?` /
`assert_no_selector` form.

**The DB-assertion race.** This is flaky:

```ruby
click_button "Save"
assert_equal "Hello", message.reload.content   # ❌ nothing polls a raw DB read
```

Capybara only auto-waits on *Capybara* expectations. `reload` runs the instant the click returns, which is
before the Turbo request has completed. The fix is always the same shape — **assert a DOM change that can
only happen after the response landed, then assert the DB**:

```ruby
click_button "Save"
assert_selector "#messages .message", text: "Hello"   # ✅ this waits
assert_equal "Hello", message.reload.content          # now safe
```

#### The broadcast race, and turbo-rails' official fix

There is a second, Turbo-specific race that nobody expects: `<turbo-cable-stream-source>` connects to
Action Cable **asynchronously**. If your test visits a page and immediately triggers a server-side
broadcast, the subscription may not exist yet and the broadcast vanishes.

turbo-rails ships `Turbo::SystemTestHelper` for exactly this. `[SOURCE]` `lib/turbo/system_test_helper.rb`:

```ruby
# Delay until every `<turbo-cable-stream-source>` element present in the page
# is ready to receive broadcasts
def connect_turbo_cable_stream_sources(**options, &block)
  all(:turbo_cable_stream_source, **options, connected: false, wait: 0).each do |element|
    element.assert_matches_selector(:turbo_cable_stream_source, **options, connected: true, &block)
  end
end
```

It also registers a Capybara selector and two assertions:

```ruby
assert_turbo_cable_stream_source(locator = nil, connected:, channel:, signed_stream_name:)
assert_no_turbo_cable_stream_source(...)
```

**Crucially, it is only auto-invoked after `visit`.** `[SOURCE]` `lib/turbo/engine.rb:8`:

```ruby
config.turbo.test_connect_after_actions = %i[ visit ]
```

So if your test navigates by clicking a link — which is the normal case in a Turbo app — you get **no**
automatic wait and the race is live. Fix it in the test env:

```ruby
# config/environments/test.rb
config.turbo.test_connect_after_actions << :click_link
config.turbo.test_connect_after_actions << :click_button
# or disable entirely and call connect_turbo_cable_stream_sources manually:
# config.turbo.test_connect_after_actions = []
```

This is the single most valuable, least-known Turbo testing fact in this document.

The generic alternative is **`capybara-lockstep`** (gem, v2.3.1, makandra), which patches Capybara to wait
for network idle before every interaction. It fixes a whole class of races at the cost of some speed. Worth
adopting if flakes persist after the above.

**Another coverage gap to know about:** the test-environment Action Cable adapter is `:test`, even in
Rails 8 apps that use `solid_cable` in production. Broadcast tests therefore never exercise the real
adapter.

#### Testing Turbo Frame navigation

The thing worth asserting is that the frame was replaced *and the page was not*. Scope with `within` and
pin something outside the frame:

```ruby
test "editing inside a frame does not navigate the page" do
  visit message_path(messages(:one))
  outside = find("h1").text

  within "turbo-frame#message_1" do
    click_link "Edit"
    assert_selector "form"                       # waits for the frame to load
    fill_in "Content", with: "Updated"
    click_button "Save"
    assert_selector ".message", text: "Updated"
  end

  assert_equal outside, find("h1").text          # page never navigated
  assert_current_path message_path(messages(:one))
end
```

For lazy frames, assert the placeholder first, then the loaded content — that proves laziness rather than
accidentally passing on an eager load:

```ruby
assert_selector "turbo-frame#stats .skeleton"
assert_selector "turbo-frame#stats .chart"
```

#### Testing morph / page refresh

Only the *instructions* are assertable from Ruby; the DOM diff itself is client-side:

```ruby
# integration test — the opt-in meta tag is present
assert_select "meta[name=turbo-refresh-method][content=morph]", count: 1
assert_select "meta[name=turbo-refresh-scroll][content=preserve]", count: 1

# a morph-flavoured stream
assert_turbo_stream action: "refresh"
```

In a system test you assert the *observable consequence* of a morph rather than the morph: that
non-morphed state survived. E.g. focus an input, type into it, trigger a refresh, assert the value and
`document.activeElement` are unchanged. That is the real regression you care about.

<a name="16-previews"></a>
### 1.6 Preview pages and visual testing

**Lookbook** (gem 2.3.14) is the right home for crosswire's demo pages. Confirmed: it supports
**"ViewComponent, Phlex, ActionView partials and more"** — you do **not** need ViewComponent to use it.
Since crosswire ships partials + Stimulus controllers rather than ViewComponents, this matters a lot.

Previews are plain Ruby classes rendering whatever you like:

```ruby
# test/components/previews/dropdown_preview.rb
class DropdownPreview < Lookbook::Preview
  # @param items number
  # @param align select [start, end]
  def default(items: 5, align: "start")
    render "crosswire/dropdown", items: items, align: align
  end

  # @label Keyboard navigation
  def with_typeahead
    render "crosswire/dropdown", items: 26, typeahead: true
  end
end
```

Lookbook previews double as the **system-test fixtures**: point Capybara at
`/lookbook/preview/dropdown/default` and you have a hermetic page containing exactly one component, with
no app chrome to interfere. That kills a whole category of "the test broke because the layout changed"
flakes and gives every component a stable, addressable URL.

**Visual regression options**, in order of practicality:

1. **`capybara-screenshot-diff`** (gem 1.12.0, now also published as `snap_diff-capybara`; actively
   maintained, last release 2026-04-13). Self-hosted, commits baseline PNGs to the repo, no SaaS.
   `screenshot "dropdown_open"` in a system test; fails the build on pixel drift beyond a threshold.
2. **Playwright screenshots** (`toHaveScreenshot()`) — if we already run Playwright for controller tests,
   this is free and has better cross-browser support and a built-in diff UI.
3. **Percy / Happo** — SaaS, best diff review UX, costs money. Overkill for an OSS library.

Recommendation: (1) or (2), pointed at Lookbook preview URLs, gated to a nightly job rather than every PR —
pixel diffs are noisy and shouldn't block merges.

---

<a name="2-accessibility"></a>
## 2. Accessibility

<a name="21-what-turbo-breaks"></a>
### 2.1 What Turbo breaks by default

Verified against a clone of `hotwired/turbo@8.0.23`. The summary: **Turbo ships mechanical primitives
(`aria-busy`, `[autofocus]` handling, permanent-element focus preservation) and deliberately ships no
announcement or focus-management policy at all.**

#### Drive visits: no announcement, no focus reset

`[SOURCE]` `src/core/drive/page_renderer.js`:

```js
finishRendering() {
  super.finishRendering()
  if (!this.isPreview) {
    this.focusFirstAutofocusableElement()
  }
}
```

`[SOURCE]` `src/core/renderer.js`:

```js
get shouldAutofocus() { return true }

focusFirstAutofocusableElement() {
  if (this.shouldAutofocus) {
    const element = this.connectedSnapshot.firstAutofocusableElement
    if (element) element.focus()
  }
}
```

**That is the entirety of Turbo's focus management on a Drive visit.** Only `[autofocus]` elements get
focus. There is no fallback to `<body>`, `<main>`, or the first heading. Grepping all of `src/` for
`aria-live`, `announce`, or `role="status"` returns **zero hits outside test fixtures** — no announcement
mechanism exists.

Compare to a real browser navigation, where the browser resets focus to `<body>` and every screen reader
announces the new `<title>`. **A Turbo app is, by default, silent on navigation and leaves focus wherever
the user left it — often on a link that no longer exists.** For a screen reader or keyboard user this is
the single biggest regression Hotwire introduces. Tracked as
[hotwired/turbo#774](https://github.com/hotwired/turbo/issues/774) — **still open**.

#### Frames: `aria-busy` yes, focus no

`[SOURCE]` `src/util.js`:

```js
export function markAsBusy(...elements) {
  for (const element of elements) {
    if (element.localName == "turbo-frame") element.setAttribute("busy", "")
    element.setAttribute("aria-busy", "true")
  }
}

export function clearBusyState(...elements) {
  for (const element of elements) {
    if (element.localName == "turbo-frame") element.removeAttribute("busy")
    element.removeAttribute("aria-busy")
  }
}
```

Called from `frame_controller.js` on `requestStarted`/`requestFinished` and
`formSubmissionStarted`/`formSubmissionFinished`. The docs confirm the form gets it too: *"When navigating
the `<turbo-frame>` through a `<form>` submission, Turbo will toggle the Form's `[aria-busy="true"]`
attribute in tandem with the Frame's."*

The scoping — frame-local, never bubbled to `<html>` — was a deliberate decision in
[hotwired/turbo#442](https://github.com/hotwired/turbo/pull/442):

> **dhh**: *"I think if we can't use aria-busy in a uniform way, we should use data-turbo-busy, and then
> leave it as an exercise for the app…"*
> **seanpdoyle**: *"This change aims to contain `<turbo-frame>`-initiated toggling to the frame itself and
> the `<form>` that initiated the navigation."*

**Open bug worth knowing:**
[hotwired/turbo-rails#667](https://github.com/hotwired/turbo-rails/issues/667) — *"aria-busy state cleared
too early from turbo frame, leads to accessibility issues"*: `busy`/`aria-busy` are removed **before**
`turbo:before-frame-render` fires, so assistive tech can be told "done" while the DOM is still old.
Multiple independent reporters; still open.

**Also open:** [hotwired/turbo#1248](https://github.com/hotwired/turbo/issues/1248) — a *blurred* input
gets refocused (or worse, the first input on the page gets focused) after a frame replaces it. Root cause
traced to `focusFirstAutofocusableElement()`. Deflected as user error (missing unique DOM ids); never
fixed at framework level. If crosswire renders forms inside frames, this will bite consumers.

#### Streams: nothing is announced, ever

`[SOURCE]` `src/core/streams/stream_message_renderer.js` — the render path does two things:
`withPreservedFocus` (keeps focus if the focused element survives the stream) and
`withAutofocusFromFragment` (which only fires if **nothing** currently has focus). There is no `aria-live`
logic anywhere in the file.

So: **a Turbo Stream can append a message, remove a row, or replace a form and a screen-reader user will
not be told anything happened.** Announcing stream insertions is 100% the application's (or component
library's) job.

#### Morph: focus is preserved, but by a different mechanism

`[SOURCE]` `src/core/drive/morphing_page_renderer.js`:

```js
export class MorphingPageRenderer extends PageRenderer {
  async preservingPermanentElements(callback) { return await callback() }   // Bardo skipped
  get shouldAutofocus() { return false }                                    // morph never re-autofocuses
}
```

`shouldAutofocus = false` is a genuine a11y fix (from #1267, *"Don't lose focus due to autofocus when
morphing pages"*): morph runs on **every** page refresh, and re-firing `[autofocus]` each time would yank
focus out from under the user constantly.

Bardo (the detach/reattach mechanism that preserves `data-turbo-permanent` elements during a full replace)
is bypassed for morph because idiomorph is told never to touch permanent subtrees at all.
`[SOURCE]` `src/core/morphing.js`:

```js
beforeNodeAdded = (node) => {
  return !(node.id && node.hasAttribute("data-turbo-permanent") && document.getElementById(node.id))
}
```

Anything focused inside a permanent element is therefore simply never disturbed.

**Open bug:** [hotwired/turbo#1538](https://github.com/hotwired/turbo/issues/1538) —
`TypeError: activeElement.setSelectionRange is not a function` during morph. Fixed upstream in
[idiomorph#150](https://github.com/bigskysoftware/idiomorph); Turbo is waiting on a release. Focus and
selection preservation during morph is **not** bulletproof.

Scroll preservation across a refresh is separate and **opt-in**:
`<meta name="turbo-refresh-scroll" content="preserve">`.

#### The progress bar: invisible to AT, ignores reduced-motion

`[SOURCE]` `src/core/drive/progress_bar.js` — the element is a bare `<div class="turbo-progress-bar">`.
**No `role`, no `aria-*`.** It is decorative-by-accident rather than by declaration, which is arguably
fine, but it also means loading state is never communicated to a screen reader on a Drive visit.

`grep -rn "reduced-motion" src/` returns exactly **one** hit, and it gates View Transitions, not the
progress bar (`[SOURCE]` `src/core/drive/page_snapshot.js`):

```js
get prefersViewTransitions() {
  const viewTransitionEnabled = /* ... */
  return viewTransitionEnabled && !window.matchMedia("(prefers-reduced-motion: reduce)").matches
}
```

So the progress bar animates unconditionally. Manual opt-out only:

```css
@media (prefers-reduced-motion: reduce) {
  .turbo-progress-bar { transition: none; }
}
```

#### The submit-button trap — a real, fixable default

`[SOURCE]` `src/core/config/forms.js` — Turbo disables the submitter during submission, and the **default
strategy removes it from the accessibility tree**:

```js
const submitter = {
  "aria-disabled": {
    beforeSubmit: submitter => {
      submitter.setAttribute("aria-disabled", "true")
      submitter.addEventListener("click", cancelEvent)
    },
    afterSubmit: submitter => {
      submitter.removeAttribute("aria-disabled")
      submitter.removeEventListener("click", cancelEvent)
    }
  },
  "disabled": {
    beforeSubmit: submitter => submitter.disabled = true,
    afterSubmit:  submitter => submitter.disabled = false
  }
}

export const forms = new Config({
  mode: "on",
  submitter: "disabled"          // ← the default
})
```

Setting `disabled = true` on the focused submit button **blows away focus** (a disabled element cannot be
focused) and silently drops it from the a11y tree mid-interaction. The `aria-disabled` strategy keeps the
button focusable and announced, and blocks the click via `cancelEvent` instead. **One line fixes it
app-wide:**

```js
// app/javascript/application.js
Turbo.config.forms.submitter = "aria-disabled"
```

crosswire should ship this in its install generator and document it loudly. It is the highest
value-per-character a11y change available in a Hotwire app.

#### `data-turbo-confirm`

`[SOURCE]` `src/core/drive/form_submission.js`:

```js
static confirmMethod(message) { return Promise.resolve(confirm(message)) }
```

The default is native `window.confirm()` — which is **fully accessible** (OS-level modal, keyboard
operable, focus trapped, announced everywhere). The moment anyone replaces it with a pretty custom dialog
via `Turbo.config.forms.confirm`, they inherit the entire APG dialog spec. Turbo gives zero guidance on
this. **A correct, drop-in accessible confirm dialog is one of the most valuable things crosswire can
ship.**

<a name="22-official-position"></a>
### 2.2 The official position — issue archaeology

There is **no accessibility chapter on turbo.hotwired.dev**. All handbook and reference pages were crawled
and grepped for `aria`/`accessib`/`screen reader`/`a11y`/`focus`/`announce`. Total substantive content: the
`aria-busy` paragraphs quoted above, and one line recommending real forms/buttons over `data-turbo-method`
links. No announcer pattern, no focus-management guidance, no WCAG statement.

The position is nonetheless *considered*, not merely absent. The evidence:

**[hotwired/turbo-rails#355](https://github.com/hotwired/turbo-rails/pull/355)** proposed a default
`aria-live="polite"` on every `turbo_frame_tag`. Closed, not merged. **dhh:**

> *"I think this is too far into app-specific territory on how you want to deal with accessibility. I could
> well imagine a bunch of turbo frames you're just using for the purpose on initial lazy loading, but that
> you don't want calling out all at once when they load together with the first content (and they're not
> individually interactive)."*

**[hotwired/turbo#774](https://github.com/hotwired/turbo/issues/774)** — "Accessibility issues with Turbo
navigation", **open**, the substantive thread. brunoprietog (a blind screen-reader user, later a
turbo-rails collaborator):

> *"I think a good starting point would be for Turbo to announce by default the change of a page title
> when browsing."*

manuelpuyol (maintainer):

> *"we are going to try some of your suggestions, like announcing during before-visit… if Turbo provided
> the tools for it, it'd make the navigation more standard for users."*

seanpdoyle proposed a concrete `aria-live="assertive"` sr-only span and asked *"Would that be a good
pattern to codify into Turbo or Turbo Rails?"*

**None of it shipped.** No announcer element, helper, or config exists in 8.0.23. The issue is still open.

**Synthesis of the official position:** announcement and focus-target semantics are considered too
application-specific to default. Turbo standardises only the "safe" mechanical primitives and leaves the
rest as an app-level integration point via `turbo:before-visit` / `turbo:load` / `turbo:before-render`.

**This is crosswire's single clearest opportunity.** The framework has explicitly declined to fill this
gap, the gap is real and well-documented, and a *component library* is precisely the right layer to fill
it — narrower than the framework, wider than one app.

**Third-party solutions: there are none.** Searches across GitHub found no maintained Turbo route-announcer
package. Real apps hand-roll it: `basecamp/fizzy` (Basecamp's own open-source Hotwire app) wires
`turbo:before-stream-render@document` to bespoke Stimulus controllers; `opf/openproject` maintains its own
`frontend/src/turbo/turbo-event-listeners.ts` layer. "Roll your own" is the ecosystem norm.

<a name="23-announcer"></a>
### 2.3 The route announcer and focus patterns

The standard SPA remedy, adapted to Turbo. This is table stakes and crosswire should ship it as a
first-class component.

```erb
<%# app/views/layouts/application.html.erb %>
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>

  <%# ONE announcer for the whole page. It must exist in the DOM BEFORE any content changes. %>
  <div id="route-announcer"
       class="sr-only"
       role="status"
       aria-live="polite"
       aria-atomic="true"></div>

  <main id="main-content" tabindex="-1">
    <h1><%= yield :page_title %></h1>
    <%= yield %>
  </main>
</body>
```

```js
// app/javascript/controllers/route_announcer_controller.js  (or a plain listener)
document.addEventListener("turbo:load", () => {
  const announcer = document.getElementById("route-announcer")
  if (!announcer) return

  // Clear first: screen readers only announce a CHANGE. Re-setting the same
  // text is a no-op, and setting text in the same frame as clearing can be missed.
  announcer.textContent = ""
  requestAnimationFrame(() => { announcer.textContent = document.title })

  // Move focus to the top of the new content, matching real navigation.
  document.getElementById("main-content")?.focus()
})
```

Five rules that make or break this, all of which are commonly got wrong:

1. **The live region must already be in the DOM before the change.** Injecting an element that *already
   has* `aria-live` set announces nothing — the region has to be observed first, then mutated. This is
   why the announcer lives in the layout, not in the streamed content.
2. **`polite` for routine, `assertive`/`role="alert"` only for urgent.** An assertive region interrupts
   whatever the user is currently listening to.
3. **Only mutate text, never wrap a subtree.** Putting `aria-live` on a container that receives a large
   Turbo Stream insertion queues the *entire subtree* for announcement and overwhelms the user.
4. **One announcer per page**, not one per frame — this is exactly dhh's objection in #355, and he's right.
5. **Hide it with the `.sr-only` clip pattern**, never `display:none` or `visibility:hidden` — those
   suppress AT announcement too.

```css
.sr-only {
  position: absolute;
  width: 1px; height: 1px;
  padding: 0; margin: -1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
  clip-path: inset(50%);
  white-space: nowrap;
  border: 0;
}
```

Use `turbo:load` — it fires after a full Drive render and **only** on Drive visits, not on every frame
load. That's the correct granularity per dhh's objection.

**For Turbo Stream insertions**, the same announcer is reused with an explicit, human-authored message
rather than raw content — because raw inserted markup makes terrible speech:

```erb
<%# app/views/messages/create.turbo_stream.erb %>
<%= turbo_stream.append :messages, @message %>
<%= turbo_stream.update :route_announcer do %>
  New message from <%= @message.author.name %>
<% end %>
```

That is the crosswire pattern: **the server decides what gets announced.** It is idiomatic Hotwire (the
server owns the semantics), it is testable in an integration test with `assert_turbo_stream`, and it
avoids every over-announcement failure mode.


---

<a name="24-apg"></a>
### 2.4 APG pattern specs for the widgets we're building

Fetched live from the W3C APG on 2026-08-15. Each widget crosswire ships must satisfy the row below.

#### Dialog (modal) — <https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/>

| Key | Action |
|---|---|
| `Tab` | Move to next focusable **inside** the dialog; **wraps** to first |
| `Shift+Tab` | Previous focusable inside; wraps to last |
| `Escape` | Close the dialog |

**ARIA:** `role="dialog"`, `aria-modal="true"`, and `aria-labelledby` (or `aria-label`). APG advises
against `aria-describedby` when the body is structured content — it gets read as one flat blob.
**Focus:** fully trapped. Initial focus is context-dependent: the first focusable element normally; a
static heading (`tabindex="-1"`) for large/structured dialogs; the **least destructive** action for
confirmations. On close, return focus to the invoker — *unless* the invoker is gone, in which case a
logically adjacent element (e.g. the row just created).

#### Disclosure — <https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/>

| Key | Action |
|---|---|
| `Enter` / `Space` | Toggle the disclosed content |

**ARIA:** `role="button"` (use a real `<button>`), `aria-expanded`, optionally `aria-controls`.
**Focus:** none — no trap, no forced movement. The simplest correct widget; there is no excuse for
getting it wrong.

#### Accordion — <https://www.w3.org/WAI/ARIA/apg/patterns/accordion/>

Note: the accordion has its **own pattern page**, it is not merely a disclosure example.

| Key | Action |
|---|---|
| `Enter` / `Space` | Toggle the focused header's panel |
| `Tab` / `Shift+Tab` | Normal page flow — **no roving tabindex** |

**ARIA:** header is a `<button>` inside an element with `role="heading"` + `aria-level`; `aria-expanded`,
`aria-controls`; `aria-disabled` on a header whose panel cannot be collapsed. The panel may take
`role="region"` + `aria-labelledby`, but **APG warns against this past ~6 panels** (landmark
proliferation makes the landmark list useless).

#### Tabs — <https://www.w3.org/WAI/ARIA/apg/patterns/tabs/>

| Key | Action |
|---|---|
| `Tab` | Into the tablist → lands on the **active** tab; again → into the tabpanel |
| `Left` / `Right` | Move focus among tabs, **wrapping** (horizontal) |
| `Up` / `Down` | Same, when `aria-orientation="vertical"` |
| `Space` / `Enter` | Activate the focused tab (only if **not** auto-activating) |
| `Home` / `End` | First / last tab (optional but expected) |
| `Delete` | Close the tab, where closeable (optional) |
| `Shift+F10` | Open the tab's context menu, if any |

**ARIA:** `role="tablist"` → `role="tab"` (`aria-selected`, `aria-controls`) → `role="tabpanel"`
(`aria-labelledby`); `aria-orientation` when vertical.
**Focus:** **roving tabindex only.** APG does not mention `aria-activedescendant` for tabs at all. Support
both *automatic* activation (selection follows focus — good for cheap panels) and *manual* activation
(arrow to move, Enter to select — required when panels are expensive or lazily loaded).

#### Combobox — <https://www.w3.org/WAI/ARIA/apg/patterns/combobox/>

| Key (on the input) | Action |
|---|---|
| `Down` | Open the popup and move into it |
| `Escape` | Dismiss the popup |
| `Enter` | Accept the current value |
| Printable chars | Type / filter |

| Key (in the listbox popup) | Action |
|---|---|
| `Enter` | Accept and close |
| `Escape` | Close, return to the input |
| `Up` / `Down` | Move the active option |
| `Left` / `Right` | (editable combobox) return to the input |
| Printable chars | Type into the input, or typeahead-jump |

**ARIA:** `role="combobox"` on the input, plus `aria-expanded`, `aria-controls`, `aria-haspopup`,
`aria-autocomplete`.
**Focus:** **`aria-activedescendant` — mandatory, not optional.** APG, verbatim: *"DOM Focus is maintained
on the combobox and the assistive technology focus is moved within the listbox using
aria-activedescendant."* This is the one widget where roving tabindex is wrong, because DOM focus must
stay on the text input so typing keeps working. The exception is a *dialog*-type popup, which reverts to
real DOM focus and the dialog pattern's trap/return rules.

#### Menu / Menubar / Menu button — <https://www.w3.org/WAI/ARIA/apg/patterns/menubar/> and <https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/>

| Key (on the button) | Action |
|---|---|
| `Enter` / `Space` | Open the menu, focus the **first** item |
| `Down` / `Up` | Open and focus first / last item (optional) |

| Key (in an open menu) | Action |
|---|---|
| `Tab` / `Shift+Tab` | **Exit and close the entire menu**, move on in page order |
| `Enter` / `Space` | Activate the item, or open its submenu |
| `Down` / `Up` | Next / previous item, wrapping |
| `Right` | Open submenu (or, in a menubar, next top-level menu) |
| `Left` | Close submenu and return to parent (or previous top-level menu) |
| `Home` / `End` | First / last item |
| `Escape` | Close the current level, return focus to the invoker/parent item |
| Printable chars | Typeahead (optional but expected) |

**ARIA:** `role="menu"` / `role="menubar"`; items are `role="menuitem"`, `menuitemcheckbox`, or
`menuitemradio`; parent items carry `aria-haspopup` + `aria-expanded`; `aria-checked` where applicable;
`aria-disabled` items **stay focusable**.
**Focus:** APG deliberately leaves the model open — either `aria-activedescendant` on the container or
roving tabindex per item (in a menubar the first item gets `tabindex="0"`). Note the critical difference
from a dialog: **Tab does not cycle within a menu, it closes it.**

#### Listbox — <https://www.w3.org/WAI/ARIA/apg/patterns/listbox/>

| Key | Action |
|---|---|
| `Up` / `Down` | Move focus; in single-select, **selection follows focus** |
| `Home` / `End` | First / last option (recommended above 5 options) |
| Printable chars | Typeahead (recommended above 7 options) |
| `Space` | (multi-select) toggle the focused option |
| `Shift+Up/Down` | (multi-select) extend the selection |
| `Ctrl+Shift+Home/End` | (multi-select) select to start / end |
| `Ctrl+A` | (multi-select) select all / none |

**ARIA:** `role="listbox"` → `role="option"`; `aria-multiselectable`; use `aria-selected` for single-select
or `aria-checked` for multi-select — **not both**.
**Focus:** roving tabindex is the baseline (real DOM focus on the option); `aria-activedescendant` is
documented as "an alternative." No trap.

#### Tooltip — <https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/>

⚠️ **APG flags this pattern as unsettled**: *"This design pattern is work in progress; it does not yet have
task force consensus"* (w3c/aria-practices #127, #128).

| Key | Action |
|---|---|
| `Escape` | Dismiss the tooltip |

That is the entire keyboard section. **ARIA:** `role="tooltip"` on the bubble; the trigger gets
`aria-describedby`.
**Focus:** the tooltip **never** receives focus; focus stays on the trigger. If the bubble needs focusable
content, it is not a tooltip — it's a non-modal dialog, and a different pattern applies. Also apply WCAG
1.4.13 (Content on Hover or Focus): dismissible, hoverable, persistent.

#### Alert — <https://www.w3.org/WAI/ARIA/apg/patterns/alert/>

| Key | Action |
|---|---|
| — | **"Not applicable"** (verbatim — the whole keyboard section) |

**ARIA:** `role="alert"` and nothing else; it implies assertive live-region semantics.
**Focus:** must **not** move focus — that is precisely what separates an Alert from an Alert Dialog.
Two rules people break constantly: it must **not auto-dismiss on a timer** (WCAG 2.2.3 No Timing), and it
must be **populated after page load** — an alert already present with content when the page loads is never
announced.

#### Switch — <https://www.w3.org/WAI/ARIA/apg/patterns/switch/>

| Key | Action |
|---|---|
| `Space` | Toggle |
| `Enter` | Toggle (optional) |

**ARIA:** `role="switch"` + `aria-checked`. No arrow navigation.
**The rule everyone gets wrong**, quoted from APG: *"it is critical the label on a switch does not change
when its state changes."* State is conveyed by `aria-checked` alone — never by swapping the label between
"On" and "Off".

#### Toast / status region — no APG pattern exists

Confirmed against the APG practices index: there is **no toast pattern**. Compose it:
`role="status"` (implies `aria-live="polite"` + `aria-atomic="true"`) for routine toasts; reserve
`role="alert"` for urgent ones. Auto-dismiss timers conflict with WCAG 2.2.1 (Timing Adjustable) unless
the user can pause/extend — so pause on hover **and on focus**, and never auto-dismiss anything the user
must act on.

#### Cross-cutting platform primitives

**`<dialog>` + `showModal()`** — Baseline *Widely available* since March 2022. What you get **free**:
top-layer rendering with `::backdrop`; the rest of the page automatically `inert`; implicit
`aria-modal="true"`; **Escape closes**; initial focus lands on the first focusable element.

What you do **not** get and must build:
- **Scroll lock** — the background still scrolls. Not documented as automatic anywhere.
- **Focus restoration to the invoker on close** — not stated as automatic; implement it explicitly.
- **Click-outside to dismiss** — the new `closedby` attribute defaults to `closerequest` behaviour;
  light dismiss requires `closedby="any"`.

**`inert`** — Baseline *Widely available* since April 2023. Blocks focus, clicks, find-in-page, selection
and editing, and removes the subtree from the accessibility tree. A modal `<dialog>` is the one element
type that escapes an inert ancestor. No visual styling by default — you must dim it yourself.

**Popover API** — Baseline ***newly available* (2025)**, meaningfully less proven than `<dialog>`/`inert`.
Plain popovers are **always non-modal**; for modal+popover semantics use `<dialog popover>`. States are
`auto` / `hint` / `manual`; `auto` uses the same light-dismiss mechanism as `closedby="any"`. MDN names
toast notifications as a canonical use case. **Recommendation: use it, but behind a capability check**,
given its age relative to our support window.

**`aria-live`** — `off` / `polite` / `assertive`; `role="alert"` implies assertive, `role="status"` implies
polite + atomic. The **pre-existing-container rule** is the one that breaks implementations: the live
region must be in the DOM *before* the content changes. Creating-and-populating a node in one step
announces nothing.

<a name="25-audit"></a>
### 2.5 How the existing libraries do — named and shamed

Read from cloned source, not READMEs. Every claim below was independently re-verified with grep.

#### excid3/tailwindcss-stimulus-components (6.1.4)

- **`modal.js` and `slideover.js`: no focus trap, no Escape handler, no focus restore, no scroll lock, no
  `inert`.** Verified: `modal.js` is **56 lines** and contains **zero** occurrences of `focus`, `Escape`,
  `inert`, or `overflow`. All accessibility is borrowed from native `<dialog>.showModal()` — and the code
  never checks that `dialogTarget` actually *is* a `<dialog>`. Point it at a `<div>` and you get a
  completely inaccessible modal with no warning.
- **`popover.js` and `toggle.js`: zero ARIA attributes at all.** No Escape, no focus handling.
  `popover.js`'s `dismissAfter` timer auto-hides with no pause and no extend — a WCAG 2.2.1 failure.
- **`tabs.js`: sets `aria-selected` but never manages `tabindex`.** No roving tabindex, so arrow-key
  navigation is not wired and every tab is in the tab order. Also sets no `role` from JS.
- **`dropdown.js` is the best implementation in the entire survey** — it sets `role`, `aria-haspopup`,
  `aria-controls`, `aria-labelledby`, `aria-expanded`; focuses the first item on open; conditionally
  restores focus. But it has **no Tab trap**, and Escape/arrow handling exists only as *methods the
  consumer must hand-wire* via `data-action="keydown->..."`. Miss that line in your ERB and the keyboard
  support silently isn't there.

#### stimulus-components monorepo (32 components)

The headline finding, verified by grep across every component's `src/`:

```
$ grep -rhoE '"aria-[a-z]+"' components/*/src/ | sort | uniq -c
   6 "aria-expanded"
```

**`aria-expanded` is the only ARIA attribute set anywhere in the entire library**, in only two files
(`dropdown`, `reveal-controller`). No `role`, no `aria-controls`, no `aria-selected`, no `aria-haspopup`,
nothing.

- **`dropdown` is a regression versus excid3's** — no `role`, no Escape, no arrow navigation; the word
  "focus" does not appear in the file.
- **`notification`** has no `role="alert"` and no `aria-live`, and auto-dismisses at 3000ms with no
  pause-on-hover. A screen-reader user is never told a notification appeared, and a slow reader cannot
  finish reading it.
- **`popover`** injects HTML via `createContextualFragment` with no live-region announcement and zero ARIA.
- **`carousel`** wraps Swiper with `defaultOptions = {}` — it ships no accessibility opinion whatsoever.
- **`dialog`** uses the same native-`<dialog>`-only approach as excid3, with the same gaps.

#### stimulus-use (0.53.0)

**There is no focus-trap mixin.** Verified: `grep -ril "trap" src/` returns nothing; no such directory
exists. `useClickOutside` listens only on `click` and `touchend` — **pointer-only, with no keyboard
equivalent**, so a dropdown built on it cannot be dismissed from the keyboard unless the consumer adds
Escape handling themselves.

#### Is there a maintained a11y-first Stimulus/Hotwire component library?

No. `gh search repos hotwire aria` → **zero results**. `gh search repos stimulus accessibility` → the top
hit is a 98-star single-widget datepicker; everything else is 0–4 stars. **This is an open lane.**

#### Where the bar actually is: Primer ViewComponents

Worth studying precisely because it is *not* Stimulus — verified: zero matches for `stimulus` or
`data-controller` across `app/components/**/*.rb`. GitHub built it on `@github/catalyst`,
`@primer/behaviors`, and native custom elements. Its `modal_dialog.ts` does everything the Stimulus
libraries skip:

- imports a real `focusTrap()` from `@primer/behaviors`
- **menu-aware focus restore** via `getFocusableChild`
- body scroll lock **with scrollbar-width compensation**
  (`document.body.style.paddingRight = window.innerWidth - document.documentElement.clientWidth`) — so the
  page doesn't visibly jump when the modal opens
- explicit `case "Escape"` handling
- an **`overlayStack`** so nested dialogs close in the right order

`action_menu_element.ts` wires real `menuitem` / `menuitemcheckbox` / `menuitemradio` roles and registers
**one `keydown` listener in `connect()`** rather than requiring per-consumer markup wiring — the exact fix
for tailwindcss-stimulus-components' "you must hand-wire Escape yourself" flaw.

These are directly portable design targets.

#### What non-Hotwire libraries treat as table stakes

Headless UI, Radix UI, and React Aria all ship, by default: focus trap; portal rendering; complete
automatic ARIA wiring; typeahead; RTL support; and **collision-aware floating positioning**.

**None of the audited Stimulus libraries' popovers do collision detection at all** — they will happily
render a dropdown off the bottom of the viewport.

#### The gap, stated plainly

| Capability | twsc | stimulus-components | Primer | crosswire target |
|---|---|---|---|---|
| Focus trap | ❌ (native only) | ❌ (native only) | ✅ | ✅ |
| Focus restore on close | ⚠️ partial | ❌ | ✅ menu-aware | ✅ |
| Escape handling | ⚠️ opt-in wiring | ❌ | ✅ | ✅ built in |
| Arrow-key navigation | ⚠️ opt-in wiring | ❌ | ✅ | ✅ built in |
| Roving tabindex | ❌ | ❌ | ✅ | ✅ |
| Full ARIA wiring | ⚠️ dropdown only | ❌ `aria-expanded` only | ✅ | ✅ |
| Scroll lock | ❌ | ❌ | ✅ + scrollbar compensation | ✅ |
| Live-region announcement | ❌ | ❌ | ✅ | ✅ |
| Collision-aware positioning | ❌ | ❌ | ✅ | ✅ |
| Typeahead | ❌ | ❌ | ✅ | ✅ |

**That table is the product thesis.** Accessibility is not a nice-to-have differentiator for crosswire —
it is the *only* substantive differentiator available, because the incumbents have essentially none.

<a name="26-a11y-testing"></a>
### 2.6 Automated a11y testing

Recall from §1.1: **no library in the Hotwire ecosystem runs any automated a11y tool.** Adopting one is a
deliberate departure — and a cheap one.

**Ruby side — `axe-core-rspec` / `axe-core-capybara` 4.13.0** (both real, both current):

```ruby
# Gemfile
group :test do
  gem "axe-core-rspec"        # RSpec matchers
  gem "axe-core-capybara"     # the Capybara driver injection
end
```

```ruby
# Minitest
require "axe/matchers/be_axe_clean"

class DropdownA11yTest < ApplicationSystemTestCase
  include Axe::Matchers

  test "dropdown is axe-clean, closed and open" do
    visit "/lookbook/preview/dropdown/default"
    assert_axe_clean page, according_to: [:wcag2a, :wcag2aa, :wcag21aa], within: "#component"

    find("[data-crosswire--dropdown-target=trigger]").click
    assert_selector "[role=menu]"
    assert_axe_clean page, according_to: [:wcag2a, :wcag2aa, :wcag21aa], within: "#component"
  end
end
```

```ruby
# RSpec flavour
expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa).within("#component")
```

**JS side — `@axe-core/playwright` 4.13.0:**

```js
import AxeBuilder from "@axe-core/playwright"

test("dialog has no axe violations while open", async ({ page }) => {
  await page.goto("/lookbook/preview/dialog/default")
  await page.getByRole("button", { name: "Open" }).click()
  await expect(page.getByRole("dialog")).toBeVisible()

  const results = await new AxeBuilder({ page })
    .include("#component")
    .withTags(["wcag2a", "wcag2aa", "wcag21aa"])
    .analyze()

  expect(results.violations).toEqual([])
})
```

**`jest-axe` 11.0.0** works but runs in jsdom with no real layout, so it cannot see contrast, focus order,
or anything geometric. Weaker signal than Playwright + axe; not worth a separate dependency for us.

**The honest limitation:** axe-core's own documentation puts automated coverage at roughly **30–40% of
WCAG issues**. Everything crosswire actually differentiates on — focus order, focus restoration,
live-region timing, keyboard-only operability — is in the 60% axe cannot see. So:

- **axe is the floor**, run on every preview in every state, as a regression net for the easy stuff.
- **Hand-written keyboard + `document.activeElement` assertions are the real test** (real-browser tier).
- **A manual NVDA/VoiceOver pass per component, once, at release** — recorded in the component's doc page
  as "verified with X on Y". Nothing automated substitutes for it.

**Two axe-specific gotchas** for a component library: scope with `.include()`/`within:` so you test *the
component*, not Lookbook's own chrome; and test **every state** — a dialog that's axe-clean while closed
tells you nothing.

---

<a name="3-performance"></a>
## 3. Performance

### 3.1 Full-page morph vs targeted Turbo Streams

`[SOURCE]` `src/core/drive/morphing_page_renderer.js` — a morph calls `morphElements()` on the **entire
`<body>`**. There is no scoping mechanism; `page_view.js` only swaps the renderer class based on the
`refresh-method`, never the scope.

So the cost model is:

| | Full-page morph (page refresh) | Targeted Turbo Stream |
|---|---|---|
| Server render | The **whole page** — nav, sidebar, chrome, everything | One partial |
| Bytes over the wire | Full HTML document | One fragment |
| Client work | idiomorph diff over the whole body tree | Direct DOM operation on one target |
| Author cost | **Zero** — reuse the page template you already have | A `.turbo_stream.erb` per change type |
| Correctness | Always consistent with the canonical page | Can drift from the page render |

**When each wins:**

- **Morph wins** when the change is diffuse (many parts of the page change together), when authoring
  bespoke streams would mean maintaining a parallel rendering path, or when correctness-by-construction
  matters more than bytes. It is also the only sane option for "something changed, re-sync everything".
- **Streams win** for high-frequency, small, well-localised updates — a chat message, a counter, a row
  status. At 10 messages/second, morphing the whole page 10 times is absurd.

**The honest framing, from Turbo's own author.** Jorge Manrubia,
["A happier happy path in Turbo with morphing"](https://dev.37signals.com/a-happier-happy-path-in-turbo-with-morphing/):
morphing's benefit is **not** rendering speed — it is **client-state preservation** (scroll, focus, open
menus, unsent form input). Choose morph for correctness and authoring simplicity, not for throughput.

Relatedly, ["Exploring server-side diffing in Turbo"](https://dev.37signals.com/exploring-server-side-diffing-in-turbo/)
reports that a prototype that shrank payloads by diffing on the server produced **"marginal gains… not
noticeable"** and was abandoned. **Payload size is not usually the bottleneck in a Hotwire app.** Worth
internalising before we optimise the wrong thing.

### 3.2 The cost of morphing large DOMs (idiomorph 0.7.4)

`[SOURCE]` `idiomorph/src/idiomorph.js`. The algorithm builds id-sets via a bottom-up
`querySelectorAll("[id]")` plus an ancestor walk — near-linear. But `findBestMatch` does a **linear sibling
scan per new node**, which degrades toward **O(n²)** on large lists of siblings **without ids** — a big
`<ul>` or `<table>` being reordered is exactly the pathological case.

idiomorph's own README is refreshingly blunt:

> *"Idiomorph is not designed to be as fast as morphdom or nanomorph… approximately 10% slower than
> morphdom for large DOM morphs."*

Open/closed issues worth tracking:

- **[idiomorph#134](https://github.com/bigskysoftware/idiomorph/issues/134)** — *closed, fix shipped.*
  Profiling found ~90% of morph time in a `document.activeElement` containment check. The precomputed
  `activeElementAndParents` set is present in 0.7.4.
- **[idiomorph#144](https://github.com/bigskysoftware/idiomorph/issues/144)** — **open, not shipped.**
  Skipping the morph of byte-identical subtrees gives the author's own measured **10× speedup on normal
  morphs and up to 100× on pathological ones**. Verified absent from 0.7.4.
- **[idiomorph#143](https://github.com/bigskysoftware/idiomorph/issues/143)** — open, investigating the
  id-less sibling-list O(n²) pathology.

**The practical lever for crosswire: give every repeated element a stable `id`.** `dom_id(record)` on every
row, item, and card. This is what turns idiomorph's matching from a linear scan into a hash lookup, and it
is free — we already use `dom_id` for stream targeting.

Also relevant: **[hotwired/turbo#1538](https://github.com/hotwired/turbo/issues/1538)** —
`activeElement.setSelectionRange is not a function` during morph. Fixed upstream in idiomorph#150; Turbo
awaits a release.

### 3.3 Broadcast cost — the good news and the real traps

**The good news, verified from source** (`app/models/concerns/turbo/broadcastable.rb`,
`lib/turbo/streams/broadcasts.rb`): rendering happens **exactly once**. `render_broadcast_action` produces
one `content` string, then `ActionCable.server.broadcast(stream_name, content)` publishes it once. There is
**no per-subscriber re-render** — fan-out is the adapter's problem, not Rails'. A broadcast to 5,000
subscribers costs one render.

**The real traps:**

1. **`broadcast_*_later` renders inside an Active Job worker with no request context.** URL helpers need
   `default_url_options` configured for the job environment, and `Current` attributes are unset. Views
   that call `current_user` or a bare `_url` helper will blow up — or worse, render wrong. This is the
   number-one broadcast bug.
2. **Rendering in the job vs the request.** `_later` moves the render off the request thread (good for
   response latency) but means the job can render a version of the record newer than the one that
   triggered the broadcast. `_later` is right for expensive partials; the synchronous form is right when
   you need render-time consistency.
3. **Loops enqueue N jobs.** `records.each { it.broadcast_replace_later_to(room) }` is a real N+1 — N
   renders, N publishes. Batch it into one broadcast of a re-rendered collection instead.
4. **Debouncing exists, but only for refreshes.** `broadcasts_refreshes` / `broadcast_refresh_later_to`
   debounce through `Turbo::ThreadDebouncer` (0.5s default, `Concurrent::ScheduledTask`). **Targeted
   append/replace/prepend broadcasts are NOT debounced.** High-frequency targeted broadcasts need your own
   throttle.
5. **`suppressing_turbo_broadcasts`** is the escape hatch for bulk imports and migrations. Use it.
6. Broadcast from `after_commit`, never `after_save` — otherwise you can publish a payload rendered from
   a transaction that then rolls back.

### 3.4 Stream security — what signing does and does not do

`[SOURCE]` `app/channels/turbo/streams_channel.rb` and `Turbo::Streams::StreamName`.

`turbo_stream_from(*streamables)` embeds a **`MessageVerifier`-signed** stream name in the
`<turbo-cable-stream-source signed-stream-name="...">` attribute. On subscribe, the channel re-verifies it
and rejects if verification fails:

```ruby
def subscribed
  if stream_name = verified_stream_name_from_params
    stream_from stream_name
  else
    reject
  end
end
```

**This authenticates that the name was not tampered with client-side. It does NOT authorise the viewer.**
Anyone who obtains a signed name — from a shared screenshot, a leaked HTML dump, a cached page — can
subscribe to that stream forever; the signature has no expiry and no user binding.

Two consequences for crosswire's docs, both non-obvious and both important:

- **Never render `turbo_stream_from` for a resource the current user isn't authorised to see.** The
  authorisation decision happens when you emit the tag, not when the subscription arrives.
- **For anything sensitive, use a custom channel** with a `subscription_allowed?` check. turbo-rails
  documents the pattern in the `Turbo::StreamsChannel` source comments:

```ruby
class CustomChannel < ActionCable::Channel::Base
  extend  Turbo::Streams::Broadcasts, Turbo::Streams::StreamName
  include Turbo::Streams::StreamName::ClassMethods

  def subscribed
    if (stream_name = verified_stream_name_from_params).present? && subscription_allowed?
      stream_from stream_name
    else
      reject
    end
  end

  def subscription_allowed?
    current_user.can_read?(...)          # ← the actual authorisation
  end
end
```
```erb
<%= turbo_stream_from @room, channel: CustomChannel %>
```

### 3.5 Turbo Drive caching and prefetch — exact numbers from source

**Two separate caches. Do not conflate them.**

| Cache | Size | Purpose | Source |
|---|---|---|---|
| Snapshot cache | **10** entries | Back/forward previews | `page_view.js:10` — `new SnapshotCache(10)` |
| Prefetch cache | **1** entry | Hover prefetch | `prefetch_cache.js:50` — `new PrefetchCache()`, `constructor(size = 1, …)` |

**Prefetch-on-hover**, `[SOURCE]` `src/core/drive/prefetch_cache.js`:

```js
const PREFETCH_DELAY = 100                       // ms of hover before the request fires

class PrefetchCache extends LRUCache {
  constructor(size = 1, prefetchDelay = PREFETCH_DELAY) { super(size, toCacheKey); … }
  putLater(url, request, ttl) {
    this.#prefetchTimeout = setTimeout(() => { request.perform(); this.put(url, request, ttl) }, this.prefetchDelay)
  }
}

export const cacheTtl = 10 * 1000                // prefetched responses are good for 10 seconds
```

Both of the numbers in circulation are correct: **100ms hover delay, LRU of size 1.** Size 1 means hovering
across a list of links leaves only the last one cached — prefetch helps a deliberate hover-then-click, not
a scan.

`[SOURCE]` `src/observers/link_prefetch_observer.js`: prefetch is skipped for non-GET links, links with a
confirm, and cross-origin links. Requests carry `X-Sec-Purpose: prefetch` so the server can cheapen or
skip work. There is **no `saveData` / Data Saver check** — confirmed absent.

Controls:

```html
<meta name="turbo-prefetch" content="false">              <!-- disable globally -->
<meta name="turbo-prefetch-cache-time" content="30000">   <!-- override the 10s TTL -->
<a href="/expensive" data-turbo-prefetch="false">…</a>    <!-- per link, or on any ancestor -->
```

**Cost/benefit:** every hover that doesn't convert is a wasted full server render. On a dense index page
with expensive rows, prefetch can meaningfully raise server load for little benefit. Turn it off per
container on such pages.

**⚠️ Stale-tutorial correction.** `data-turbo-cache="false"` as a per-element attribute **does not exist in
Turbo 8.0.23** — grepping the whole of `src/` for `turbo-cache` returns exactly one hit, in `cache.js`, and
it is the page-level meta tag:

```js
#setCacheControl(value) { setMetaContent("turbo-cache-control", value) }
```

The real mechanisms are `<meta name="turbo-cache-control" content="no-cache">` (never cache this page) and
`content="no-preview"` (cache, but don't show a preview), or the JS equivalents
`Turbo.cache.exemptPageFromCache()` / `exemptPageFromPreview()`. Plenty of blog posts get this wrong.

`data-turbo-track="reload"` on assets triggers a full reload when the digest changes
(`[SOURCE]` `head_snapshot.js:86`) — how a deploy forces clients onto new JS/CSS. Cheap; keep it.

### 3.6 Lazy frames as a performance tool

`[SOURCE]` `src/observers/appearance_observer.js` — 31 lines:

```js
this.intersectionObserver = new IntersectionObserver(this.intersect)
```

**No options**, so the default `threshold: 0` — the frame loads at the **first visible pixel**, with no
root margin, so there is no preloading before it scrolls into view. One observer instance per lazy frame,
torn down after the first load.

Consequences:

- **No request coalescing.** A fast scroll past ten lazy frames fires ten simultaneous requests. Browsers
  cap ~6 concurrent connections per origin on HTTP/1.1; on HTTP/2 they all go at once and hit your server
  together. **A page with many lazy frames can be worse than one eager render.**
- **No built-in skeleton.** Whatever static HTML sits inside the `<turbo-frame>` *is* the placeholder.
  Ship a skeleton — an empty frame causes layout shift (a Core Web Vitals CLS hit).
- **Threshold 0 means late.** The user sees the skeleton, then a flash of content. There is no way to tune
  a root margin from markup.

Strategy: **eager for above-the-fold, lazy for below, and never more than a handful of lazy frames per
page.** Where a page needs many independent regions, prefer one render with all the data over ten lazy
frames.

```erb
<%# above the fold: render inline, no frame round-trip %>
<%= render "dashboard/summary", stats: @stats %>

<%# below the fold: lazy, with a real skeleton that reserves the right height %>
<%= turbo_frame_tag "activity", src: activity_path, loading: :lazy do %>
  <div class="skeleton" style="min-height: 20rem" aria-busy="true">…</div>
<% end %>
```

### 3.7 Import maps vs bundling, and what crosswire should ship

**The mechanics of lazy registration**, `[SOURCE]` `stimulus-rails/app/assets/javascripts/stimulus-loading.js`:

```js
export function eagerLoadControllersFrom(under, application) {
  const paths = Object.keys(parseImportmapJson()).filter(path => path.match(new RegExp(`^${under}/.*_controller$`)))
  paths.forEach(path => registerControllerFromPath(path, under, application))
}

export function lazyLoadControllersFrom(under, application, element = document) {
  lazyLoadExistingControllers(under, application, element)
  lazyLoadNewControllers(under, application, element)     // MutationObserver on [data-controller]
}

function controllerFilename(name, under) {
  return `${under}/${name.replace(/--/g, "/").replace(/-/g, "_")}_controller`
}
```

The lazy path watches `data-controller` with a `MutationObserver`
(`{ attributeFilter: ["data-controller"], subtree: true, childList: true }`) and dynamically imports
`${under}/${name}_controller` only when a matching element appears — including elements inserted later by
a Turbo Stream.

**This is the decisive fact for our distribution decision: lazy registration requires one module per
controller at a predictable path. A single bundled file cannot be lazy-loaded.** For a library of ~30
controllers of which a typical page uses three, that is exactly the property we want.

**How the ecosystem actually ships** (read from source):

| Library | Shape | Importmap-consumable? | Lazy-loadable? |
|---|---|---|---|
| turbo-rails / stimulus-rails | **Rails engine gem** vendoring one pre-bundled file in `app/assets/javascripts/` (`turbo.min.js`, ~105KB) + install generator writing the `pin` | ✅ zero build step | n/a (single entry) |
| tailwindcss-stimulus-components | npm only, esbuild → one ESM file | ✅ via CDN pin or `bin/importmap pin --download` | ❌ one bundle |
| stimulus-components | npm monorepo, per-package Vite build, **TypeScript source** | ⚠️ needs compilation | ❌ per package |
| stimulus_reflex | raw ESM source, no build | ✅ | ✅ |

**Notably, neither tailwindcss-stimulus-components nor stimulus-components ships a Ruby gem at all**
(verified: no such gems on rubygems.org). Every Rails consumer has to reach through npm/CDN. For a library
whose entire premise is "The Rails Way", that is a gap we can close.

**The HTTP/2 waterfall reality.** The old "import maps mean N round trips" objection is mostly obsolete:
HTTP/2 multiplexes, importmap-rails emits `<link rel="modulepreload">` for pinned modules, and each file
gets a content digest so caching is per-file — a one-controller change doesn't invalidate the bundle. The
genuine remaining costs are (a) a deeper dependency graph costs latency on high-RTT connections, and (b)
no tree-shaking or minification across modules. For ~30 small controllers, neither is material.

### 3.8 Stimulus runtime cost on a page

MutationObserver cost is **not flat** — verified against the Stimulus source:

- **one** global document-wide observer (the Router),
- **plus one per controller instance that declares Values** (scoped to that controller's element),
- **plus one per distinct outlet name** (scoped to `document.body` — the most expensive shape).

So heavy **Outlets** usage is the highest-overhead pattern on a many-controller page: each outlet name adds
a body-wide observer. For a library, that argues for preferring events over outlets for loose coupling,
and reserving outlets for genuine cross-controller wiring.

Memory leaks: Stimulus tears down its own observers and Action-API listeners correctly on `disconnect()`.
Leaks come from **developer code** that calls `addEventListener` manually — especially on `window` or
`document` — without removing it. Under morphing this compounds, because a surviving element keeps its
controller instance while the page re-renders around it.

### 3.9 Action Cable scaling for Turbo Streams

**solid_cable** is the Rails 8 default. `[SOURCE]` `configuration.rb:22-25` — `polling_interval` defaults
to **`0.1.seconds`**. It polls a DB table; one query per interval fetches all subscribed channels at once,
and fan-out to local sockets happens in-process. **Autotrim runs synchronously inline on every broadcast**
by default — the README itself flags this as a cost.

solid_cable's **own published k6 benchmarks** (README; Hetzner CCX13, single machine, vendor's own numbers —
treat accordingly): at the default 0.1s polling, median RTT is roughly **2× Redis or Postgres NOTIFY**
(≈146ms vs ≈69–73ms average at 250 VUs). Dropping to 0.01s polling brings it to ≈84ms — "comparable to
Redis" — at **10× the poll queries**.

| Adapter | When it's right |
|---|---|
| **solid_cable** | Default. No extra infrastructure. Fine when ~150ms extra latency is invisible (notifications, activity feeds, dashboards). |
| **Redis** | Lower latency, mature, one more service to run. The right call for chat/presence/typing indicators. |
| **AnyCable** | Holds WebSocket connections in a **separate Go process**, so connection count is decoupled from Puma threads/workers. The answer at tens of thousands of concurrent connections. Supports turbo-rails signed streams. |

The Puma interaction is the thing people miss: with in-process Action Cable, **every open WebSocket
occupies a Puma thread**. A default `max_threads: 5` server supports a handful of concurrent subscribers.
Either raise the thread count substantially, run a dedicated cable process, or move to AnyCable.

### 3.10 Published benchmarks — be skeptical

**No credible third-party "Hotwire vs SPA" benchmark exists.** The searchable material is marketing posts
and blog anecdotes with unspecified methodology.

The two genuinely useful primary sources are both from Turbo's own author, both linked above, and both
*deflate* the performance framing: morphing is about **state preservation, not speed**, and server-side
diffing produced **"marginal gains… not noticeable."**

**Recommendation: crosswire's docs must not claim a performance number over React.** We have no data that
would survive scrutiny, and the framework's own authors decline to make the claim. The honest and stronger
pitch is architectural — less code, one language, no client/server state duplication, and no build step.

---

<a name="4-debugging"></a>
## 4. Debugging & Dev Tooling

### 4.1 hotwire-spark — live reload

`hotwire-spark` (gem, **0.1.13**, [hotwired/spark](https://github.com/hotwired/spark)) is 37signals' live-reloading
system. **It is NOT in the Rails 8 default Gemfile** — you add it yourself. Last release 2025-01-25, last
push 2025-04-29: stable but not actively developed. 592k downloads.

```ruby
# Gemfile
group :development do
  gem "hotwire-spark"
end
```

That is the whole install. `[SOURCE] README.md`

**What it reloads, and how it differs by bundler** — this distinction is the thing people miss:

| Change | Import maps | JS bundling (esbuild/vite/rollup) |
|---|---|---|
| HTML (views, controllers, helpers, models, locales, images) | fetches new document body, **morphs** it with idiomorph, then reloads all Stimulus controllers on the page | full-page Turbo visit |
| CSS | fetches and reloads **only the stylesheet that changed** | same |
| Stimulus controller | fetches the changed controller module and **hot-reloads all controllers on the page** | full-page Turbo visit |

So: **import maps get true hot module reload for Stimulus controllers; bundled setups do not.** For a
controller library's demo app, that is a real argument for running the demo app on import maps.

```ruby
# config/environments/development.rb
config.hotwire.spark.html_reload_method = :morph      # :morph (default) | :replace
config.hotwire.spark.logging            = true        # log reloads to the browser console
config.hotwire.spark.html_paths        += %w[ lib ]   # default: app/controllers app/helpers
                                                      #          app/assets/images app/models
                                                      #          app/views config/locales
config.hotwire.spark.stimulus_paths    += %w[ app/components ]  # default: app/javascript/controllers
config.hotwire.spark.css_paths         += %w[ app/components ]  # default: app/assets/stylesheets
                                                      #          (or app/assets/builds if it exists)
```

Default monitored extensions: HTML `rb erb png jpg jpeg webp svg yaml yml`; CSS `css`; Stimulus `js`.
Note `stimulus_extensions` defaults to `js` only — **if crosswire's controllers are `.ts`, Spark will not
see them** without adding the extension.

Enabled in `development` only by default.

### 4.2 Turbo debugging

#### The complete `turbo:*` event list in 8.0.23

`[SOURCE]` grepped from `hotwired/turbo@8.0.23` `src/` — 24 events, all `dispatch("...")` call sites:

```
turbo:click                  turbo:before-visit             turbo:visit
turbo:before-cache           turbo:before-render            turbo:render
turbo:load                   turbo:reload
turbo:before-fetch-request   turbo:before-fetch-response    turbo:fetch-request-error
turbo:before-prefetch
turbo:submit-start           turbo:submit-end
turbo:before-stream-render
turbo:before-frame-render    turbo:frame-render             turbo:frame-load
turbo:frame-missing
turbo:morph                  turbo:before-frame-morph
turbo:before-morph-element   turbo:morph-element            turbo:before-morph-attribute
```

The five morph events (`turbo:morph`, `turbo:before-frame-morph`, `turbo:before-morph-element`,
`turbo:morph-element`, `turbo:before-morph-attribute`) are **Turbo 8 only**. Any tutorial that lists
events without them is pre-2024.

#### Copy-pasteable event logger

Drop this in a `<script>` in development, or paste into the console:

```js
// Log every Turbo event with its most useful detail field.
;(() => {
  const EVENTS = [
    "turbo:click", "turbo:before-visit", "turbo:visit",
    "turbo:before-cache", "turbo:before-render", "turbo:render",
    "turbo:load", "turbo:reload",
    "turbo:before-fetch-request", "turbo:before-fetch-response", "turbo:fetch-request-error",
    "turbo:before-prefetch",
    "turbo:submit-start", "turbo:submit-end",
    "turbo:before-stream-render",
    "turbo:before-frame-render", "turbo:frame-render", "turbo:frame-load", "turbo:frame-missing",
    "turbo:morph", "turbo:before-frame-morph",
    "turbo:before-morph-element", "turbo:morph-element", "turbo:before-morph-attribute"
  ]

  const label = (e) => {
    const t = e.target
    const id = t?.id ? `#${t.id}` : ""
    const tag = t?.tagName?.toLowerCase() ?? "document"
    return `${tag}${id}`
  }

  EVENTS.forEach((name) => {
    document.addEventListener(name, (event) => {
      console.groupCollapsed(
        `%c${name}%c ${label(event)}`,
        "color:#8250df;font-weight:bold", "color:inherit"
      )
      console.log("target:", event.target)
      console.log("detail:", event.detail)
      if (event.detail?.fetchOptions) console.log("method:", event.detail.fetchOptions.method)
      if (event.detail?.url)           console.log("url:", event.detail.url)
      if (event.detail?.fetchResponse) console.log("status:", event.detail.fetchResponse.statusCode)
      if (event.cancelable)            console.log("cancelable: yes (preventDefault() to block)")
      console.groupEnd()
    })
  })
  console.info(`[turbo-debug] logging ${EVENTS.length} turbo events`)
})()
```

#### Console incantations

`[SOURCE]` `src/core/index.js` — what is actually exported from the `Turbo` global:

```js
Turbo.session          // the Session object — the root of everything
Turbo.navigator        // exported as `navigator` (renamed from session.navigator to avoid shadowing)
Turbo.cache            // the Cache object
Turbo.config           // { drive: {...}, forms: {...} }
Turbo.visit(url, { action: "advance" | "replace" | "restore" })
Turbo.renderStreamMessage(html)   // hand-feed a <turbo-stream> for testing
Turbo.connectStreamSource(source) / Turbo.disconnectStreamSource(source)
Turbo.registerAdapter(adapter)
Turbo.start()
Turbo.morphElements(a, b) / Turbo.morphChildren(a, b)
Turbo.PageRenderer / Turbo.PageSnapshot / Turbo.FrameRenderer / Turbo.fetch
```

**Config, the Turbo 8 way** (`[SOURCE]` `src/core/config/`):

```js
Turbo.config.drive.enabled            // true
Turbo.config.drive.progressBarDelay   // 500 (ms)
Turbo.config.drive.unvisitableExtensions  // Set of ~55 extensions Turbo won't Drive-visit
Turbo.config.forms.mode               // "on" | "off" | "optin"
Turbo.config.forms.submitter          // "disabled" (default) | "aria-disabled" | custom object
Turbo.config.forms.confirm            // custom confirm function
```

**STALE-TUTORIAL DETECTOR.** These top-level functions still exist in 8.0.23 but `console.warn` on every
call — if a tutorial uses them it predates Turbo 8:

```js
// src/core/index.js — verbatim
Turbo.setProgressBarDelay(d)  // → warns; use Turbo.config.drive.progressBarDelay = d
Turbo.setConfirmMethod(fn)    // → warns; use Turbo.config.forms.confirm = fn
Turbo.setFormMode(mode)       // → warns; use Turbo.config.forms.mode = mode
```

And `Turbo.clearCache()` **is gone entirely**. The API is now (`[SOURCE]` `src/core/cache.js`):

```js
Turbo.cache.clear()
Turbo.cache.resetCacheControl()
Turbo.cache.exemptPageFromCache()     // sets <meta name="turbo-cache-control" content="no-cache">
Turbo.cache.exemptPageFromPreview()   // sets ... content="no-preview"
```

**Frame introspection:**

```js
const frame = document.querySelector("turbo-frame#messages")
frame.src           // the URL it will/did load
frame.loaded        // a Promise that resolves when the current load finishes
frame.complete      // boolean — has it loaded?
frame.loading       // "eager" | "lazy"
frame.disabled
frame.reload()      // re-fetch src
frame.getAttribute("busy")     // present while fetching
frame.getAttribute("aria-busy")

// list every frame and its state
console.table([...document.querySelectorAll("turbo-frame")].map(f => ({
  id: f.id, src: f.src, loading: f.loading, complete: f.complete, busy: f.hasAttribute("busy")
})))
```

### 4.3 Stimulus debugging

`[SOURCE]` `@hotwired/stimulus@3.2.2` `src/core/application.ts`, `src/core/context.ts`, `src/core/binding.ts`.

```js
// In app/javascript/controllers/index.js, or just from the console:
window.Stimulus.debug = true
```

`debug` is a plain public field (`application.ts:17 — debug = false`). Turning it on makes
`logDebugActivity` emit a `console.groupCollapsed` for:

- `application #starting` / `#start` / `#stopping` / `#stop` (`application.ts:35–45`)
- **every controller** `initialize`, `connect`, `disconnect` (`context.ts:34, 48, 61`)
- **every action invocation** — with `{ event, target, currentTarget, action }` (`binding.ts:78`)

That last one is the killer feature: if an action is not firing, `debug = true` tells you instantly whether
Stimulus saw the event at all.

**Introspection:**

```js
Stimulus.controllers
// → Controller[] — every connected controller instance on the page  (application.ts:76)

Stimulus.getControllerForElementAndIdentifier(el, "dropdown")
// → the instance, or null                                          (application.ts:80)

Stimulus.router.modules.map(m => m.identifier).sort()
// → every REGISTERED identifier (router.ts:38) — compare against what's in the DOM:

const inDom = new Set([...document.querySelectorAll("[data-controller]")]
  .flatMap(el => el.dataset.controller.split(/\s+/)))
const registered = new Set(Stimulus.router.modules.map(m => m.identifier))
console.log("in DOM but NOT registered:", [...inDom].filter(id => !registered.has(id)))
console.log("registered but unused:", [...registered].filter(id => !inDom.has(id)))
```

That last snippet is the single fastest diagnosis for "my controller isn't connecting".

**Error swallowing.** `Application#handleError` logs and re-raises to `window.onerror`
(`application.ts:87–91`). In *tests* this is a trap — see the testing section — but in the browser it means
a thrown error inside `connect()` shows up as a console error, **not** as a broken-looking page. Always
check the console before believing "nothing happened".

### 4.4 Browser extension: hotwire-dev-tools

**[leonvogt/hotwire-dev-tools](https://github.com/leonvogt/hotwire-dev-tools)** — 342★, actively developed
(last push 2026-07-15). By Leon Vogt, *not* Marco Roth (a commonly repeated mix-up). Available for all
three browsers:

- Chrome: <https://chromewebstore.google.com/detail/hotwire-dev-tools/phdobjkbablgffmmgnjbmfbbofnbkajc>
- Firefox: <https://addons.mozilla.org/en-US/firefox/addon/hotwire-dev-tools/>
- Safari: <https://apps.apple.com/ch/app/hotwire-dev-tools/id6503706225>

`[SOURCE] README.md` — what it actually does:

**Turbo:** highlights Turbo Frames on the page; monitors incoming Turbo Streams live; shows Turbo context
(Drive enabled? morphing enabled?); logs all Turbo events; highlights frame changes as they happen.
**Stimulus:** highlights controllers; lists all controllers on the page.

Its **warning engine** is the interesting part — `[SOURCE] src/lib/constants.js`, `WARNING_TYPES`:

```js
DUPLICATE_TURBO_FRAME                  // two frames with the same id — a top cause of "wrong frame updated"
UNREGISTERED_STIMULUS_CONTROLLER       // data-controller with no matching registration
STIMULUS_TARGET_OUTSIDE_CONTROLLER     // data-*-target not nested inside its controller
TURBO_PERMANENT_ELEMENT_MISSING_ID     // data-turbo-permanent with no id (silently does nothing)
TURBO_PERMANENT_ELEMENT_DUPLICATE_ID   // data-turbo-permanent with a non-unique id
```

Those five are, empirically, the five bugs everyone hits. Alt+Shift+S opens the options popup.

**Recommendation for crosswire:** make this a documented prerequisite in the contributing guide. The
"unregistered controller" and "target outside controller" warnings alone will save every consumer of a
30-controller library hours.

### 4.5 Editor & static tooling

| Tool | Package | Version | What it is |
|---|---|---|---|
| **Herb** | gem `herb` / npm `@herb-tools/*` | **0.10.3** | HTML-aware ERB parser in C + linter + formatter + LSP. 1284★, pushed today. |
| Herb linter | npm `@herb-tools/linter` (bin `herb-lint`) | 0.10.3 | ~135 rules incl. 10 `a11y-*`, 40+ `html-*`, Turbo & UJS rules |
| **stimulus-lint** | npm `stimulus-lint` | **0.4.3** | Herb-based Stimulus rules — the closest thing to an "eslint-plugin-stimulus" |
| Stimulus LSP | [marcoroth/stimulus-lsp](https://github.com/marcoroth/stimulus-lsp) | 1.1.2 | VS Code / Neovim / Zed intelligence for Stimulus. 303★ |
| stimulus-parser | [marcoroth/stimulus-parser](https://github.com/marcoroth/stimulus-parser) | 0.3.2 | Static analysis of controllers — the engine under the LSP |
| erb_lint | gem `erb_lint` | 0.9.0 (2025-01) | Shopify's ERB linter. Maintained but slow; Herb is its successor |
| erblint-github | gem `erblint-github` | 1.0.1 | **GitHub's 16 accessibility rules for erb_lint** |

**There is no `eslint-plugin-stimulus` on npm** (verified: the package does not exist). `stimulus-lint` is
the answer to that question, and it lints the *templates* — which is where Stimulus bugs actually live,
since the wiring is in HTML attributes.

`[SOURCE]` `javascript/packages/stimulus-lint/src/rules/` — the five rules:

```
stimulus-attribute-format      stimulus-data-action-valid    stimulus-data-controller-valid
stimulus-data-target-valid     stimulus-data-value-valid
```

i.e. it cross-references your `data-controller` / `data-action` / `data-*-target` / `data-*-value`
attributes against the controllers actually defined in your project. For a library shipping 30 controllers
with a large declarative API surface, this is the highest-leverage lint available.

**Herb's accessibility rules** (`[SOURCE]` `javascript/packages/linter/src/rules/`):

```
a11y-avoid-generic-link-text          a11y-disabled-attribute
a11y-nested-interactive-elements      a11y-no-accesskey-attribute
a11y-no-aria-label-misuse             a11y-no-aria-unsupported-elements
a11y-no-autofocus-attribute           a11y-no-redundant-image-alt
a11y-no-visually-hidden-interactive-elements   a11y-svg-has-accessible-text
```

plus a large set of `html-*` rules that are a11y in all but name:

```
html-aria-attribute-must-be-valid     html-aria-role-must-be-valid
html-aria-level-must-be-valid         html-aria-role-heading-requires-level
html-no-aria-hidden-on-focusable      html-no-aria-hidden-on-body
html-no-abstract-roles                html-no-positive-tab-index
html-avoid-both-disabled-and-aria-disabled
html-img-require-alt                  html-anchor-require-href
html-iframe-has-title                 html-navigation-has-label
html-no-empty-headings                html-no-nested-links
html-no-nested-forms                  html-no-duplicate-ids
html-input-require-autocomplete       html-details-has-summary
html-no-title-attribute               html-no-event-handler-attributes
```

These are direct ports of GitHub's erblint-github rules (Herb's README credits it as prior art). Two ways
to get them:

```yaml
# .erb-lint.yml — the erb_lint route (older, Ruby, works today)
inherit_gem:
  erblint-github:
    - config/accessibility.yml
```
```ruby
# .erb-linters/erblint-github.rb
require "erblint-github/linters"
```

```sh
# the Herb route (newer, HTML-aware, faster) — no Ruby config file needed
npx @herb-tools/linter
npx stimulus-lint
```

**Turbo-specific lint rules in Herb** — worth calling out because nothing else has them:

```
turbo-permanent-require-id            turbo-permanent-no-misleading-value
ujs-no-remote-attribute               ujs-prefer-turbo-confirm
ujs-prefer-turbo-method               ujs-prefer-turbo-submits-with
```

The `ujs-*` rules are a migration aid: they flag `data-remote`, `data-confirm`, `data-method`, and
`data-disable-with` (Rails-UJS) and tell you to use the Turbo equivalents. Useful for crosswire's docs,
because a lot of copy-pasted Rails HTML in the wild is still UJS.

---

<a name="testing-recipe"></a>
## Testing recipe

The concrete stack, in the order you'd set it up.

### Tier 0 — static, runs in milliseconds

```sh
npx stimulus-lint                 # data-controller / data-action / target / value cross-referencing
npx @herb-tools/linter            # HTML+ERB correctness, incl. 10 a11y-* rules and turbo-permanent rules
bundle exec rubocop
```

### Tier 1 — controller unit tests: **Vitest, jsdom by default**

```
crosswire/
  app/javascript/crosswire/          # the controllers we ship
  test/js/
    support/stimulus.js              # the mount() helper from §1.2
    controllers/*.test.js            # jsdom by default
    browser/*.browser.test.js        # opted into a real browser
  vitest.config.js
  vitest.browser.config.js
```

```js
// vitest.config.js — the fast default tier
import { defineConfig } from "vitest/config"

export default defineConfig({
  test: {
    environment: "jsdom",
    globals: true,
    include: ["test/js/controllers/**/*.test.js"],
    setupFiles: ["test/js/support/setup.js"]
  }
})
```

```js
// vitest.browser.config.js — the real-browser tier for focus/observer/dialog work
import { defineConfig } from "vitest/config"

export default defineConfig({
  test: {
    include: ["test/js/browser/**/*.browser.test.js"],
    browser: {
      enabled: true,
      provider: "playwright",
      headless: true,
      instances: [{ browser: "chromium" }, { browser: "firefox" }, { browser: "webkit" }]
    }
  }
})
```

```json
{
  "scripts": {
    "test":         "vitest run && vitest run --config vitest.browser.config.js",
    "test:unit":    "vitest run",
    "test:browser": "vitest run --config vitest.browser.config.js",
    "test:watch":   "vitest"
  }
}
```

**The routing rule — which tier does a controller belong in?**
A controller goes in the **browser** tier if it touches any of:

- `document.activeElement`, focus trapping, roving tabindex, `inert`
- `IntersectionObserver`, `ResizeObserver`, `matchMedia`
- `<dialog>.showModal()`, the Popover API
- `getBoundingClientRect()` / positioning / collision detection
- `navigator.clipboard`, `requestSubmit()`
- real CSS transitions (`transitionend`)

Everything else — state machines, value/target plumbing, event dispatch, string munging, form
serialisation — goes in the fast jsdom tier. In practice that's roughly a 1/3 : 2/3 split for a widget
library, and the fast tier stays under a second.

### Tier 2 — Rails integration tests (fast, no browser)

```ruby
# test/test_helper.rb
class ActionDispatch::IntegrationTest
  include Turbo::TestAssertions::IntegrationTestAssertions
end

class ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper
  include ActiveJob::TestHelper
end
```

Assert `assert_turbo_stream` / `assert_turbo_frame` / `assert_no_turbo_stream` on every controller action
that speaks `turbo_stream`, and `assert_turbo_stream status: :unprocessable_content` on every validation
failure path. These are cheap and catch the two most common server-side Turbo bugs (wrong MIME type,
wrong status).

### Tier 3 — system tests against Lookbook previews

```ruby
# test/system/dropdown_test.rb
class DropdownTest < ApplicationSystemTestCase
  test "keyboard navigation follows the APG menu pattern" do
    visit "/lookbook/preview/dropdown/default"

    find("[data-crosswire--dropdown-target='trigger']").send_keys(:enter)
    assert_selector "[role=menu]"
    assert_equal "Item 1", evaluate_script("document.activeElement.textContent").strip

    page.driver.browser.keyboard.type(:down)  if page.driver.respond_to?(:browser)
    assert_equal "Item 2", evaluate_script("document.activeElement.textContent").strip

    find("[role=menu]").send_keys(:escape)
    assert_no_selector "[role=menu]"
    assert_equal "trigger", evaluate_script("document.activeElement.dataset.crosswireDropdownTarget")
  end
end
```

Point every system test at a **Lookbook preview URL**, not an app page — hermetic, addressable, no app
chrome to break.

### Tier 4 — automated a11y scan (see §2.6)

axe-core over every Lookbook preview, in both closed and open states.

### CI configuration

```yaml
# .github/workflows/ci.yml
jobs:
  lint:
    steps:
      - run: npx stimulus-lint && npx @herb-tools/linter && bundle exec rubocop

  js:
    steps:
      - run: npm ci
      - run: npx playwright install --with-deps chromium firefox webkit
      - run: npm run test:unit
      - run: npm run test:browser

  ruby:
    env:
      FERRUM_PROCESS_TIMEOUT: 25     # CI runners are slow to boot Chrome
      FERRUM_DEFAULT_TIMEOUT: 15
    steps:
      - run: bin/rails test              # integration + unit
      - run: bin/rails test:system       # Cuprite
      - uses: actions/upload-artifact@v4
        if: failure()
        with: { name: capybara-screenshots, path: tmp/capybara }
```

### CI stability rules

- `Capybara.disable_animation = true` — mandatory for a library full of transitions.
- `js_errors: true` in the Cuprite driver — turns silent JS failures into loud test failures.
- Never `!page.has_css?`; always `assert_no_selector` / `has_no_css?`.
- Never assert DB state straight after a click — assert a DOM change first.
- `config.turbo.test_connect_after_actions << :click_link` if any system test relies on broadcasts.
- Raise `FERRUM_*` timeouts in CI only, not locally (slow locally hides real bugs).
- Rails 8 auto-screenshots on failure; upload `tmp/capybara` as an artifact.
- Gate visual-regression snapshots to a nightly job, not PRs.

---

<a name="a11y-checklist"></a>
## A11y checklist

**Every crosswire component must satisfy every applicable line below before it ships.** This is a gate,
not an aspiration — see §2.5 for why it's also our entire competitive position.

### A. Semantics and ARIA

- [ ] Built on the **correct native element** first — `<button>`, `<a href>`, `<dialog>`, `<details>`,
      `<input type="checkbox">`. A `<div>` with `data-action` is an automatic fail.
- [ ] Interactive elements are reachable by `Tab` **without** any author-supplied positive `tabindex`.
- [ ] The applicable APG roles are set **by the controller**, not left to the consumer's markup. If the
      consumer must remember to add `role="menu"`, we have shipped a bug.
- [ ] State attributes are updated on **every** state change: `aria-expanded`, `aria-selected`,
      `aria-checked`, `aria-current`, `aria-pressed`, `aria-disabled`.
- [ ] Relationship attributes are wired with **generated ids** if none are supplied: `aria-controls`,
      `aria-labelledby`, `aria-describedby`, `aria-haspopup`, `aria-activedescendant`.
- [ ] Every component has an accessible name. If it cannot derive one, it **warns in development**.
- [ ] `aria-selected` **or** `aria-checked` — never both on the same element.
- [ ] Disabled items use `aria-disabled` and **stay focusable** (menu/listbox items especially); reserve
      the `disabled` attribute for form controls that must not submit.
- [ ] No `aria-hidden` on anything focusable. No positive `tabindex`. No redundant `role` on a native
      element that already has it.

### B. Keyboard

- [ ] The full APG key table from §2.4 is implemented for this widget, in the controller — not delegated
      to consumer `data-action` wiring.
- [ ] `Escape` dismisses every dismissible thing (dialog, menu, popover, tooltip, combobox popup).
- [ ] Arrow keys navigate every composite widget (tabs, menu, listbox, combobox, accordion headers where
      applicable) and **wrap**.
- [ ] `Home` / `End` jump to first / last in any collection.
- [ ] **Typeahead** in listbox and menu once there are more than ~7 options.
- [ ] The right focus model per widget: **roving tabindex** for tabs and listbox; **`aria-activedescendant`
      for combobox** (mandatory — DOM focus must stay on the input); either model for menu.
- [ ] `Tab` behaves per pattern: it **cycles** inside a modal dialog, and it **closes** a menu.
- [ ] Every mouse interaction has a keyboard equivalent. `useClickOutside` alone is a fail.
- [ ] Nothing is operable by hover alone (WCAG 1.4.13: dismissible, hoverable, persistent).

### C. Focus management

- [ ] Modal dialogs **trap focus**, wrapping in both directions.
- [ ] Initial focus is deliberate: first focusable; or a `tabindex="-1"` heading for large content; or the
      **least destructive** action in a confirmation.
- [ ] Focus **returns to the invoker** on close — and to a sensible neighbour if the invoker is gone.
- [ ] Background content is made `inert` while a modal is open (free with `<dialog>.showModal()`; explicit
      otherwise).
- [ ] **Scroll lock** while a modal is open, with **scrollbar-width compensation** so the page doesn't
      jump (Primer's technique, §2.5).
- [ ] Nested overlays close in reverse order — maintain an overlay stack.
- [ ] Focus is never lost to `document.body` after a component removes the focused element; move it
      somewhere sensible first.
- [ ] Focus visible: never `outline: none` without an equally visible replacement; honour
      `:focus-visible`.

### D. Turbo interaction — the traps nobody else handles

- [ ] The app sets **`Turbo.config.forms.submitter = "aria-disabled"`** — crosswire's install generator
      writes this. The default (`disabled`) destroys focus and drops the button from the a11y tree
      mid-submission (§2.1).
- [ ] Exactly **one** route announcer per page, in the layout, populated on `turbo:load` with
      `document.title`, and focus moved to `#main-content` (§2.3).
- [ ] Turbo Stream insertions that matter are announced via a **server-authored message** into the
      pre-existing announcer — never by wrapping the inserted subtree in `aria-live`.
- [ ] Live regions **exist in the DOM before** their content changes. A streamed-in element that already
      carries `aria-live` announces nothing.
- [ ] Components survive **morphing**: no listeners re-bound on reconnect, no assumption that `connect()`
      means fresh DOM, no reliance on `[autofocus]` (morph sets `shouldAutofocus = false`).
- [ ] Anything that must keep focus/state across a page refresh is `data-turbo-permanent` **with a unique
      id** (a permanent element without an id silently does nothing).
- [ ] Components inside lazy frames don't announce on initial load — that's dhh's #355 objection, and he
      was right.
- [ ] `data-turbo-confirm` replacements meet the **full dialog spec**; native `confirm()` was already
      accessible, so a custom one that isn't is a regression (§2.1).
- [ ] Frames used as loading regions carry a visible **and** announced busy state; do not rely on Turbo's
      `aria-busy` alone given turbo-rails#667 (cleared too early).

### E. Visual and motion

- [ ] Text contrast ≥ 4.5:1, large text and UI components ≥ 3:1 (WCAG 1.4.3 / 1.4.11).
- [ ] Nothing is conveyed by colour alone (WCAG 1.4.1).
- [ ] Every animation respects `prefers-reduced-motion: reduce`, **including** an opt-out for Turbo's
      progress bar — Turbo does not do this for you (§2.1).
- [ ] Works at 200% zoom and 320px width without loss of function (WCAG 1.4.10).
- [ ] Works in forced-colors / Windows High Contrast mode.
- [ ] Touch targets ≥ 24×24 CSS px (WCAG 2.5.8).

### F. Timing and content

- [ ] No auto-dismiss on anything the user must act on (WCAG 2.2.1). Toasts pause on **hover and focus**.
- [ ] `role="alert"` is populated **after** load, never present-with-content at load — and never
      auto-dismissed on a timer (WCAG 2.2.3).
- [ ] `role="status"` (polite) for routine toasts; `role="alert"` (assertive) reserved for urgent.
- [ ] A switch's **label never changes** with its state (APG, verbatim).
- [ ] Error messages are programmatically associated with their field (`aria-describedby`,
      `aria-invalid`) and announced.

### G. Verification — every component, every release

- [ ] axe-clean (`wcag2a`, `wcag2aa`, `wcag21aa`) in **every state**, scoped to the component.
- [ ] A real-browser test asserting `document.activeElement` at each step of the keyboard flow.
- [ ] A keyboard-only walkthrough with the mouse physically unplugged.
- [ ] One manual screen-reader pass (NVDA/Firefox or VoiceOver/Safari), recorded on the component's doc
      page as "verified with X on Y, date".
- [ ] The component's documentation page states its APG pattern, links it, and lists its key bindings —
      so consumers can verify our claims.

---

<a name="performance-checklist"></a>
## Performance checklist

### Choosing an update mechanism

- [ ] Default to a **targeted Turbo Stream** for a localised change; use a **page refresh / morph** when
      the change is diffuse or when maintaining a parallel stream template would drift.
- [ ] Never morph on a high-frequency event stream (chat, presence, typing). Morph is for correctness,
      streams are for throughput.
- [ ] Understand that a morph transmits and re-renders the **entire page** — there is no scoping.

### Morph efficiency

- [ ] **Every repeated element has a stable `id`** (`dom_id(record)`). This is the single biggest morph
      performance lever — it converts idiomorph's linear sibling scan into id-set matching.
- [ ] Long id-less sibling lists (big `<ul>`, `<table>`) are the known O(n²) pathology — never ship one.
- [ ] Elements that must survive a morph carry `data-turbo-permanent` **and a unique id** (no id = silently
      no-op).
- [ ] Budget: measure morph time on the largest realistic page. Idiomorph is ~10% slower than morphdom by
      its own README; the byte-identical-subtree optimisation (idiomorph#144, 10–100×) has **not** shipped.

### Broadcasts

- [ ] Broadcast from `after_commit`, never `after_save`.
- [ ] Never call `broadcast_*_later_to` inside a loop over records — batch into one broadcast.
- [ ] `_later` jobs have **no request context**: configure `default_url_options` for the job environment,
      and never reference `Current`/`current_user` in a broadcast partial.
- [ ] Remember that only **refresh** broadcasts are debounced (`Turbo::ThreadDebouncer`, 0.5s). Throttle
      high-frequency targeted broadcasts yourself.
- [ ] Wrap bulk imports/migrations in `suppressing_turbo_broadcasts`.
- [ ] Rendering happens once per broadcast regardless of subscriber count — so optimise the **partial**,
      not the fan-out.

### Stream security (a performance-adjacent correctness gate)

- [ ] `turbo_stream_from` is only rendered when the current user is authorised — the signature
      authenticates the *name*, it does not authorise the *viewer*, and it never expires.
- [ ] Anything sensitive uses a custom channel with a `subscription_allowed?` check.

### Caching and prefetch

- [ ] Know the two caches: snapshot cache = **10** entries; prefetch cache = **1** entry, **100ms** hover
      delay, **10s** TTL.
- [ ] Disable prefetch (`data-turbo-prefetch="false"`) on containers of expensive links — every
      non-converting hover is a wasted full render.
- [ ] Use `X-Sec-Purpose: prefetch` server-side to cheapen prefetch responses.
- [ ] Use `<meta name="turbo-cache-control" content="no-cache">` for pages that must not be cached.
      **`data-turbo-cache="false"` is not a thing in Turbo 8** — don't copy it from a blog post.
- [ ] `data-turbo-track="reload"` on assets so deploys pick up new JS/CSS.

### Lazy frames

- [ ] Above-the-fold content renders **inline**; only below-the-fold gets `loading="lazy"`.
- [ ] Keep lazy frames to a handful per page — there is **no request coalescing**, and threshold is 0
      (loads at the first visible pixel).
- [ ] Every lazy frame ships a skeleton that reserves the correct height (CLS).
- [ ] Where a page would need many lazy frames, render once with all the data instead.

### JavaScript delivery

- [ ] Ship **one module per controller** so `stimulus-loading`'s lazy path can work — a single bundle
      cannot be lazy-registered.
- [ ] Use `lazyLoadControllersFrom` rather than `eagerLoadControllersFrom` for a 30-controller library.
- [ ] Keep controllers free of heavy dependencies; if one needs a big third-party library, put it behind a
      **subpath export** (the stimulus-use `./hotkeys` precedent) or dynamic `import()`.
- [ ] `@hotwired/stimulus` is a **peerDependency**, never bundled.
- [ ] Verify `<link rel="modulepreload">` is emitted for pinned controllers.

### Stimulus runtime

- [ ] Prefer **events** over **outlets** for loose coupling — each distinct outlet name adds a
      `document.body`-wide MutationObserver.
- [ ] Every manual `addEventListener` in `connect()` has a matching removal in `disconnect()`, ideally via
      one `AbortController`.
- [ ] Controllers behave correctly when `connect()` runs more than once and when the element **survives** a
      morph.
- [ ] Verify no listener growth: check `getEventListeners(window)` across several Turbo visits.

### Action Cable

- [ ] Know that with in-process Action Cable, **every WebSocket holds a Puma thread**. Raise
      `max_threads`, run a dedicated cable process, or move off it.
- [ ] solid_cable default polling is **0.1s** and costs roughly **2× the RTT of Redis**; tune
      `polling_interval` or switch to Redis if latency is user-visible.
- [ ] solid_cable's inline autotrim runs on every broadcast — consider moving it out of band at volume.
- [ ] AnyCable when connection counts outgrow the app server.

### Claims

- [ ] **Never publish a "faster than React" number.** No credible benchmark exists, and Turbo's own
      author reports payload-diffing gains were "not noticeable." Pitch architecture, not throughput.

---

<a name="debugging-playbook"></a>
## Debugging playbook

Setup once, then the seven diagnoses.

```js
// Paste in the console, or ship behind a dev flag.
window.Stimulus.debug = true                     // logs connect/disconnect/every action
Turbo.session.drive                              // is Drive even on?
Turbo.config                                     // full config object
```

Install **hotwire-dev-tools** (Chrome/Firefox/Safari) — its five built-in warnings are the five bugs below.

### 1. "Content missing" appears inside a frame

`[SOURCE]` `src/core/frames/frame_view.js:6`:

```js
this.element.innerHTML = `<strong class="turbo-frame-error">Content missing</strong>`
```

The response was fetched successfully but **contained no `<turbo-frame>` with a matching `id`**.

Diagnose in order:
1. `document.querySelector("turbo-frame#x").src` — is it the URL you expect?
2. Open that URL directly in a tab, View Source, search for `id="x"`. Not there → server-side bug.
3. Did the server **redirect** somewhere that lacks the frame? Turbo follows redirects; the *final*
   response must contain the frame.
4. Duplicate frame ids on the page? hotwire-dev-tools flags `DUPLICATE_TURBO_FRAME`. Turbo matches the
   *first*, which may not be yours.
5. Listen for the real event and inspect: `document.addEventListener("turbo:frame-missing", e => { console.log(e.detail.response, e.detail.visit); })`.

Fixes: render the frame in the response (including on the error/redirect path); or `target="_top"` on the
link if it should break out of the frame; or handle `turbo:frame-missing` with `event.preventDefault()`
and do something app-specific.

### 2. A Turbo Stream response arrives but nothing happens

Check, in this order:
1. **Content-Type must be `text/vnd.turbo-stream.html`.** Network tab → Response Headers. If it says
   `text/html`, Turbo ignores it entirely. Rails sets it automatically for `format.turbo_stream` and for
   `render turbo_stream:`; a hand-rolled `render plain:` will not.
2. **The `target` id must exist right now.** `document.getElementById("<target>")` in the console. Streams
   are fire-and-forget: a missing target is a **silent** no-op, no error.
3. **The content must be inside a `<template>`.** `<turbo-stream action="append" target="x">` requires a
   `<template>` child for every action except `remove`. The `turbo_stream.*` helpers do this for you;
   hand-written markup often doesn't.
4. Log it: `document.addEventListener("turbo:before-stream-render", e => console.log(e.target.action, e.target.target, e.target))`.
5. Hand-feed a known-good stream to isolate client vs server:
   `Turbo.renderStreamMessage('<turbo-stream action="append" target="messages"><template><p>test</p></template></turbo-stream>')`.
   Works → server problem. Doesn't → target/DOM problem.
6. For **broadcast** streams, also check the `<turbo-cable-stream-source>` element is present and has the
   `connected` attribute, and that Action Cable is actually running.

### 3. A Stimulus controller isn't connecting

```js
const inDom = new Set([...document.querySelectorAll("[data-controller]")]
  .flatMap(el => el.dataset.controller.split(/\s+/)))
const registered = new Set(Stimulus.router.modules.map(m => m.identifier))
console.log("in DOM but NOT registered:", [...inDom].filter(id => !registered.has(id)))
```

If it's in the "not registered" list:
- **Filename ↔ identifier mismatch.** `[SOURCE]` `stimulus-loading.js`: the path is derived as
  `${under}/${name.replace(/--/g, "/").replace(/-/g, "_")}_controller`. So `data-controller="date-picker"`
  → `controllers/date_picker_controller.js`, and `data-controller="admin--user-row"` →
  `controllers/admin/user_row_controller.js`. Underscores in the file, hyphens in the HTML, `--` for
  namespaces.
- **Import map pin missing.** `bin/importmap json | grep controller`, and check `pin_all_from` covers the
  directory.
- **A JS error during import.** Check the console — `lazyLoadControllersFrom` logs
  `Failed to autoload controller: <name>`.
- **Bundled setup, controller not imported** in `controllers/index.js`.

If it IS registered but still not connecting, the element was probably added by a Turbo Stream into a
subtree the Application isn't observing, or the `Application` was scoped to an element that doesn't contain
it.

### 4. An action isn't firing

1. `Stimulus.debug = true` and interact. If **no log line appears**, Stimulus never bound the action.
2. Check the descriptor syntax: `data-action="click->dropdown#toggle"`. Common errors: a space around
   `->`, a typo'd identifier, a method that doesn't exist on the controller (Stimulus warns), or the
   attribute on an element **outside** the controller's scope.
3. Check the **default event** for the element type. Stimulus infers: `click` for most, `submit` for
   `<form>`, `input` for `<input>`/`<textarea>`/`<select>`, `change` for `<select>`. If you're on a `<div>`
   expecting `submit`, name the event explicitly.
4. Non-bubbling events (`focus`, `blur`, `mouseenter`, `mouseleave`) don't delegate. Use the
   `@window`/`@document` suffix or their bubbling counterparts (`focusin`, `focusout`).
5. `data-action` on a `<div>` gives no keyboard access even when it works — that's an a11y bug, not just a
   wiring one. Use a `<button>`.

### 5. Double submits / double-bound handlers

Symptoms: two records created, an event handler firing twice, a listener count that grows on every visit.

- **Listeners added in `connect()` on `window`/`document` must be removed in `disconnect()`.** Turbo Drive
  restores a cached page and then re-renders it, so `connect()` runs more than once per "page view".
- **Under morphing this is worse**: `connect()`/`disconnect()` no longer bracket every server render, and
  an element that survives a morph keeps its controller instance alive. Never assume `connect()` implies
  "fresh DOM".
- Prefer `data-action` over manual `addEventListener` — Stimulus handles teardown for you.
- Guard idempotently: `if (this.abortController) return`; use `AbortController` and
  `{ signal: this.abortController.signal }` so `disconnect()` can drop every listener in one call.
- Verify: `getEventListeners(window)` in Chrome DevTools, before and after a few Turbo visits.

### 6. Form validation errors don't render — the 422 requirement

Turbo requires a **non-2xx status** to render a form-submission response in place. `[SOURCE]`
`src/core/drive/form_submission.js`:

```js
requestSucceededWithResponse(request, response) {
  if (response.clientError || response.serverError) {
    this.delegate.formSubmissionFailedWithResponse(this, response)
    return
  }
  // ...
  if (this.requestMustRedirect(request) && responseSucceededWithoutRedirect(response)) {
    const error = new Error("Form responses must redirect to another location")
    this.delegate.formSubmissionErrored(this, error)
  }
```

So a `200 OK` re-render of the form produces the console error **"Form responses must redirect to another
location"** and nothing appears. The fix:

```ruby
def create
  @message = Message.new(message_params)
  if @message.save
    redirect_to @message                                  # success → redirect (303 for non-GET if needed)
  else
    render :new, status: :unprocessable_content           # ← failure → 4xx. Non-negotiable.
  end
end
```

`:unprocessable_content` (422) is the Rack 3.1 name; `:unprocessable_entity` still works but is a
deprecated alias. Use `status: :see_other` (303) on redirects after `DELETE`/`PATCH`.

### 7. Turbo isn't intercepting a link or form at all

A full page load happens instead of a Drive visit. Check:
- `data-turbo="false"` on the element or any ancestor.
- `target="_blank"` or any `target` other than `_top`.
- Cross-origin `href` — Turbo only drives same-origin URLs.
- The URL ends in one of the ~55 extensions in `Turbo.config.drive.unvisitableExtensions`
  (`.pdf`, `.csv`, `.zip`, `.json`, …). Check with
  `Turbo.config.drive.unvisitableExtensions.has(".csv")`.
- `Turbo.config.drive.enabled === false`, or `Turbo.config.forms.mode === "off"` / `"optin"` for forms.
- `<meta name="turbo-visit-control" content="reload">` on the *destination* page forces a full load.
- For frames: `data-turbo-frame` pointing at a frame id that doesn't exist.

### Bonus: watching everything at once

```js
// The 24-event logger from §4.2, plus stream + frame state
Stimulus.debug = true
console.table([...document.querySelectorAll("turbo-frame")].map(f => ({
  id: f.id, src: f.src, loading: f.loading, complete: f.complete
})))
```

---

<a name="recommendations"></a>
## Recommendations for crosswire

Three explicit calls, plus what follows from them.

---

### CALL 1 — Testing stack: **Vitest two-tier + Minitest/Cuprite against Lookbook**

**Adopt:**

| Layer | Tool | Scope |
|---|---|---|
| Static | `stimulus-lint` + `@herb-tools/linter` + rubocop | every commit |
| Controller units (fast tier) | **Vitest + jsdom** | ~2/3 of controllers: state, values, targets, events |
| Controller units (real tier) | **Vitest browser mode, Playwright provider** | ~1/3: focus, observers, `<dialog>`, positioning, clipboard |
| Server | **Minitest** + `Turbo::TestAssertions::IntegrationTestAssertions` + `Turbo::Broadcastable::TestHelper` | every turbo_stream action, every broadcast |
| Integration | **Minitest system tests + Cuprite** against **Lookbook preview URLs** | one per component recipe |
| A11y | **axe-core** (`axe-core-capybara`) over every preview, in every state | gate |
| Visual | `capybara-screenshot-diff` or Playwright screenshots, **nightly** | non-blocking |

**Why Vitest and not `@web/test-runner`.** `@web/test-runner` is what Turbo and
tailwindcss-stimulus-components use and it's excellent — it just hit 1.0.0. But **Vitest browser mode gets
us both tiers from one tool, one config language, one assertion API, and one watch mode.** For a small
team maintaining ~30 controllers, one tool that does both beats two tools that each do one well. Vitest 4
makes browser mode a first-class, non-experimental path, and `stimulus-use` is proof it works in
production for exactly our kind of library.

**Why two tiers and not just jsdom.** Our closest peer (`stimulus-components`) is jsdom-only, and it is
also the library whose a11y is worst — `aria-expanded` is the *only* ARIA attribute in the entire codebase
and the word "focus" doesn't appear in its dropdown. That is not a coincidence: **you don't write focus
tests when your test environment can't run them.** Since focus management *is* our differentiator, the
tests that prove it must run in a real browser. The routing rule in §5 is the contract.

**Why not just system tests.** We are *packaging* controllers, so the contract (values, targets, classes,
events) is the product. Every controller gets a unit test against its declared contract. That inverts the
usual application-code advice, deliberately.

**Do not adopt:** `@symfony/stimulus-testing` (superseded), `stimulus-jest` (unmaintained),
`rails-controller-testing` (unmaintained, wrong tool), `jest-axe` (jsdom, no layout — weaker than
Playwright+axe for no benefit).

**Non-negotiables inside the stack:** override `Application#handleError` to **throw** in tests; scope the
Application to the fixture; `js_errors: true` in Cuprite; `Capybara.disable_animation = true`; never
`!page.has_css?`; and `config.turbo.test_connect_after_actions << :click_link` if any system test depends
on a broadcast.

---

### CALL 2 — Distribution: **a Rails engine gem, shipping unbundled per-controller ESM, plus a bundled fallback. npm later, if ever.**

```
crosswire/                                   # the gem
  lib/crosswire/engine.rb
  lib/generators/crosswire/install/           # writes the pin + the config into the host app
  app/javascript/crosswire/controllers/       # ← ONE FILE PER CONTROLLER, plain ESM, no build
      dialog_controller.js
      dropdown_controller.js
      tabs_controller.js
      …
  app/javascript/crosswire/index.js           # convenience: register everything
  app/assets/javascripts/crosswire.min.js     # ← bundled fallback for jsbundling apps
  app/views/crosswire/                        # the ERB partials/helpers
  app/helpers/crosswire/
```

Host app, import maps (the primary path):

```ruby
# config/importmap.rb — written by the install generator
pin_all_from Crosswire::Engine.root.join("app/javascript/crosswire/controllers"),
             under: "crosswire/controllers", to: "crosswire/controllers"
```
```js
// app/javascript/controllers/index.js
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
lazyLoadControllersFrom("crosswire/controllers", application)   // ← lazy, per-controller
lazyLoadControllersFrom("controllers", application)
```

**Why unbundled per-controller ESM is the primary artefact.** Verified from `stimulus-loading.js`: lazy
registration works by dynamically importing `${under}/${name}_controller` when a matching `data-controller`
appears in the DOM — including elements inserted by a Turbo Stream. **A single bundle cannot be
lazy-registered.** For 30 controllers of which a page uses three, shipping unbundled means a page downloads
three small modules instead of a 30-controller bundle. HTTP/2 multiplexing plus `modulepreload` plus
per-file digests makes the old waterfall objection largely moot.

**Why a gem, and why that's the differentiator.** Neither `tailwindcss-stimulus-components` nor
`stimulus-components` ships a Ruby gem — verified, neither exists on rubygems.org. Every Rails consumer
reaches through npm or a CDN. Meanwhile `turbo-rails` and `stimulus-rails` prove the engine-gem-vendoring
pattern works perfectly: JS inside the gem, an install generator that writes the pin, **zero build step for
the consumer**. For a library whose thesis is "rich UI The Rails Way", `bundle add crosswire && bin/rails
crosswire:install` is the product. Shipping npm-only would contradict the premise.

The gem also lets us ship the **ERB partials and view helpers alongside the controllers**, which is the
whole point — crosswire is not a JS library, it's a Hotwire component library. A dialog is a partial *and*
a controller *and* a helper. npm cannot express that.

**Why also a bundled `crosswire.min.js`.** jsbundling-rails/esbuild shops exist and shouldn't be locked
out. It costs one rollup config. Mirrors exactly what turbo-rails does (`app/assets/javascripts/turbo.min.js`).

**Rules that follow:**
- `@hotwired/stimulus` is a **peer** dependency — never bundled. Universal across every library surveyed.
- **Plain JavaScript, not TypeScript, for the shipped controllers.** TS source must be compiled, which
  breaks `pin_all_from` on raw files and forces a build step on us and a compiled artefact on consumers.
  `stimulus-components` chose TS and consequently is *not* raw-importmap-consumable. We can still ship
  hand-written `.d.ts` files if we want editor support; we should not ship a compiler dependency.
- **Zero runtime dependencies in the core.** Anything heavy (a date library, a positioning engine) goes
  behind a subpath / separate controller file, per the `stimulus-use` `./hotkeys` precedent.
- **No CSS dependency.** Style hooks via Stimulus **CSS Classes** so the library is design-system-agnostic
  — that's the escape hatch tailwindcss-stimulus-components didn't take, and it's why its name has a CSS
  framework in it.
- npm publication is a **later, additive** decision, justified only by real non-Rails demand. It is a
  second build target, not a prerequisite.

---

### CALL 3 — The a11y bar: **APG-complete, keyboard-first, verified per component. This is the product, not a feature.**

**The bar:** every crosswire widget implements its **full APG keyboard and ARIA specification in the
controller** — not as opt-in wiring the consumer must remember — and passes the §6 checklist before it
ships. Concretely, `WCAG 2.1 AA` as the floor, APG conformance as the actual target.

**Why this bar and not a lower one.** The audit in §2.5 is unambiguous, and every claim in it was verified
by grep against real source:

- `tailwindcss-stimulus-components/src/modal.js` is **56 lines with zero occurrences of `focus`,
  `Escape`, `inert`, or `overflow`** — no trap, no restore, no scroll lock, and it doesn't even check that
  the target is a real `<dialog>`.
- Across the **entire** `stimulus-components` monorepo, `grep -rhoE '"aria-[a-z]+"' components/*/src/`
  returns **`6 "aria-expanded"`** and nothing else. One attribute, two files, 32 components.
- `stimulus-use` has **no focus-trap mixin** and `useClickOutside` is pointer-only.
- `gh search repos hotwire aria` → **zero results.** There is no a11y-first Hotwire component library.

Meanwhile Headless UI, Radix, and React Aria treat focus trapping, complete ARIA wiring, typeahead, RTL,
and collision-aware positioning as *table stakes*. **The Hotwire ecosystem is roughly a decade behind the
React ecosystem on accessibility, and nobody is fixing it.** That gap is the most defensible thing
crosswire can own — far more so than "another dropdown."

**Three specific commitments that make the bar concrete and visible:**

1. **Everything is wired in the controller, nothing in consumer markup.** The single most common failure in
   the audited libraries is "the Escape handler exists, but you have to add `data-action="keydown->..."`
   yourself." Register the listener in `connect()` — copy Primer's `action_menu_element.ts`. If a consumer
   *can* forget it, they will, and our a11y claim becomes false in their app.
2. **Fix Turbo's defaults for the consumer.** The install generator writes
   `Turbo.config.forms.submitter = "aria-disabled"` (the default `disabled` destroys focus and drops the
   button from the a11y tree mid-submit), installs the **route announcer** (one per page, `turbo:load`,
   focus to `#main-content`), and adds the `prefers-reduced-motion` opt-out for the progress bar. Turbo has
   explicitly declined to do these (dhh on turbo-rails#355; turbo#774 open since forever) — which makes
   the component-library layer the right place, and makes it a genuine reason to install crosswire.
3. **Publish the evidence.** Every component's doc page names its APG pattern, links it, lists its key
   bindings, and records the screen reader + browser + date of its last manual pass. Claims that can be
   checked are worth far more than a badge.

**What we explicitly accept as the cost:** axe covers only ~30–40% of WCAG issues, so the remainder is
hand-written focus assertions in a real browser plus one manual NVDA/VoiceOver pass per component at
release. That is real, recurring work. It is also the moat.

**Where we deliberately don't gold-plate:** RTL and collision-aware positioning are table stakes in React
land but are a second-phase concern for us; ship the keyboard and ARIA correctness first, since that's what
actually locks people out.

---

### Follow-on decisions implied by the three calls

- **Demo app runs on import maps**, not a bundler — because `hotwire-spark` only hot-reloads Stimulus
  controllers under import maps (§4.1), and because it dogfoods our primary distribution path.
- **Lookbook is the demo/preview surface** and doubles as the system-test and axe-scan fixture — verified
  to support plain ActionView partials, not just ViewComponent.
- **`hotwire-dev-tools` is a documented prerequisite** in CONTRIBUTING — its five built-in warnings are
  exactly the five bugs consumers of a 30-controller library will hit.
- **Controllers are plain JS with hand-written `.d.ts`**, per Call 2.
- **Set `stimulus_extensions` in hotwire-spark config** if we ever move to `.ts` — it defaults to `js` only.

### Open questions

- Does Vitest browser mode's WebKit provider work reliably enough in CI to keep in the matrix, or do we run
  Chromium + Firefox only (as Turbo does for its functional tests)?
- Do we vendor a positioning engine for collision-aware popovers, or ship without and accept the gap in v1?
- Popover API is Baseline *newly available* (2025) — do we adopt it behind a capability check now, or wait?
- Is a `crosswire-a11y` axe rule pack (custom rules encoding the APG specs axe can't see) worth building
  as a separate artefact? It would be a genuine ecosystem contribution.
