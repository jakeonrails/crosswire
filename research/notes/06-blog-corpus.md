# The Hotwire blog corpus

*Research notes for **crosswire** — a definitive collection of Hotwire skills, components and recipes for building rich UI "The Rails Way."*

**Compiled:** 2026-08-15. **Method:** every article below was fetched and read in full (not summarized from titles), with code transcribed verbatim where it was worth stealing. Sources mined: Evil Martians Chronicles, hotrails.dev, colby.so, dev.37signals.com + world.hey.com/dhh, marcoroth.dev + hotwire.io, radan.dev (formerly radanskoric.com), thoughtbot, Boring Rails, Fly.io, Honeybadger, AppSignal, Speedshop, GoRails, Rails Designer, masilotti.com, hotwire_combobox, and Ruby conference talks 2023–2026.

**How this document is organized.** The ranked reading list comes first — start there. Below it, the full annotated bibliography is grouped **by theme**, not by author, so that everything the corpus has to say about (say) morphing sits in one place regardless of who wrote it. Each entry carries title, author, date, URL, a technique summary, transcribed code, and the author's strong opinions. `★` marks entries whose code is worth lifting more or less wholesale; `★★` marks the ones that should shape the repo's structure.

---

## Reading list — the 25 essential articles, ranked

Ranked by *what a Hotwire practitioner should read first*, weighting canonical status, depth, and how much reusable code each one carries.

| # | Article | Author | Why it earns the slot |
|---|---|---|---|
| 1 | [A happier happy path in Turbo with morphing](https://dev.37signals.com/a-happier-happy-path-in-turbo-with-morphing/) | Jorge Manrubia, 37signals | The design document for Turbo 8. Establishes the progressive ladder (full-page → Frames → Streams), why partial updates tax you, and why morphing is deliberately an *implementation detail* rather than a new tool. Everything else in this corpus argues with or builds on it. |
| 2 | [Thinking in Hotwire: Progressive Enhancement](https://boringrails.com/articles/thinking-in-hotwire-progressive-enhancement/) | Matt Swanson, Boring Rails | The conceptual map: the whole stack presented as one progressive-enhancement ladder, with the rule for when to climb a rung. The best thing to read *second*, and the framing the repo's structure should borrow. |
| 3 | [Hotwire: Reactive Rails with no JavaScript?](https://evilmartians.com/chronicles/hotwire-reactive-rails-with-no-javascript) | Evil Martians | The best end-to-end walkthrough of Drive + Frames + Streams + Stimulus, ~20 code blocks, including the 303-See-Other redirect rule and broadcasting via `Turbo::StreamsChannel`. |
| 4 | [Dynamic forms with Turbo](https://thoughtbot.com/blog/dynamic-forms-with-turbo) | Sean Doyle, Turbo maintainer | The clearest statement of the Hotwire *method*: the list of questions to ask instead of the React ones, then a dependent-select built with zero JavaScript before any enhancement is added. |
| 5 | [Turbo Rails Tutorial](https://www.hotrails.dev/turbo-rails) (12 chapters, free) | Alexandre Ruban | The reference curriculum. Chapters 4–6 (Frames, Streams, and Streams **security**) and 10–11 (nested frames) are the load-bearing ones. |
| 6 | [Turbo 8 morphing deep dive — how does it work?](https://radan.dev/articles/turbo-morphing-deep-dive) | Radan Skorić | The Rails-side plumbing: what `broadcasts_refreshes` expands to, signed stream names, the `X-Turbo-Request-Id` echo that suppresses self-refreshes, and the 0.5s `Turbo::Debouncer`. |
| 7 | [Turbo 8 morphing deep dive — how idiomorph works?](https://radan.dev/articles/turbo-morphing-deep-dive-idiomorph) | Radan Skorić | The algorithm, with an interactive playground. Yields the two rules that govern morph quality: ids must be unique, and ids must be everywhere (`dom_id`). |
| 8 | [How to avoid problems with Turbo morphing](https://radan.dev/articles/how-to-avoid-problem-with-turbo-morphing) | Radan Skorić | The troubleshooting taxonomy — including the correction that Turbo **Frames do not morph** on their own refresh, despite `refresh="morph"`. |
| 9 | [Writing better StimulusJS controllers](https://boringrails.com/articles/better-stimulus-controllers/) | Matt Swanson | The Stimulus design doctrine: stop writing one controller per component (the React instinct); write small generic primitives configured by `data-` attributes and compose several on one element. |
| 10 | [Exploring server-side diffing in Turbo](https://dev.37signals.com/exploring-server-side-diffing-in-turbo/) | Jorge Manrubia | The road not taken, and the sharpest statement of Turbo's design philosophy: statelessness, portability, "the client already has a copy of the current page." |
| 11 | [A vanilla Rails stack is plenty](https://dev.37signals.com/a-vanilla-rails-stack-is-plenty/) | Jorge Manrubia | The most quotable "why no React" piece, plus a concrete inventory of what 37signals actually runs in production. |
| 12 | [Should you use Hotwire or a Frontend framework on your next Rails project?](https://radan.dev/articles/hotwire-or-frontend-framework) | Radan Skorić | The honest decision framework: shared-state complexity → Hotwire; visual-interaction complexity → a frontend framework; the hybrid is legitimate. |
| 13 | [How to refresh the full page when submitting a form inside a Turbo Frame?](https://radan.dev/articles/update-full-page-on-form-in-frame-submit) | Radan Skorić | Five techniques with explicit "use when" rules for Turbo's single most-asked question (hotwired/turbo#257). |
| 14 | [Versatile feature of Turbo: stream actions inside regular HTML](https://radan.dev/articles/stream-actions-inside-regular-html) | Radan Skorić | `<turbo-stream>` executes anywhere it lands in the DOM — the escape hatch for multi-region updates on GET requests and for killing inline `<script>` in legacy apps. He wrote the Turbo test and the docs PR that made it official. |
| 15 | [Turbo Drive, Frames, Streams, Morph? What to use?!](https://railsdesigner.com/turbo-drive-frame-stream-morph/) | Rails Designer | One feature walked up the whole ladder, with the *concrete symptom* that forces each escalation. The best teaching sequence in the corpus. |
| 16 | [thoughtbot/hotwire-example-template](https://github.com/thoughtbot/hotwire-example-template) | Sean Doyle / thoughtbot | Not an article — one Rails app with a branch per technique (modal, kanban, pagination, inline-edit, typeahead, nested attributes ×2, upload processing…), each readable commit-by-commit. A pattern library in disguise. |
| 17 | [Hotwire: Typeahead searching](https://thoughtbot.com/blog/hotwire-typeahead-searching) | Sean Doyle | Search-as-you-type with keyboard nav that degrades to a plain GET form, plus the reusable `?turbo_frame=` trick for rendering one template into any frame. |
| 18 | [Turbo 8 in 8 minutes](https://fly.io/ruby-dispatch/turbo-8-in-8-minutes/) + [8 Turbo 8 "Gotchas"](https://fly.io/ruby-dispatch/8-turbo-8-gotchas/) | Brad Gessler, Fly.io | The fastest correct mental model of morphing, then the field-tested list of what breaks when you turn it on. Radan points newcomers here rather than at his own deep dives. |
| 19 | [When broadcasting a Turbo refresh is not enough: versioned immediate updates](https://radan.dev/articles/turbo-versioned-updates) | Radan Skorić | The most advanced real-time recipe here: why `broadcasts_refreshes` is the right default, its three costs, and how to buy latency back without reintroducing stale renders. |
| 20 | [Building Basecamp project stacks with Hotwire](https://dev.37signals.com/building-basecamp-project-stacks-with-hotwire/) | Nicklas Ramhöj Holtryd, 37signals | Production Frames + Streams + Stimulus together — drag-and-drop, modal frames, inline edit — as progressive enhancement over legacy JS. |
| 21 | [Turbo 7.2: A guide to Custom Turbo Stream Actions](https://marcoroth.dev/posts/guide-to-custom-turbo-stream-actions) | Marco Roth | Both halves of a custom action: the JS, and a first-class `turbo_stream.toast(...)` Ruby helper via `Turbo::Streams::TagBuilder.prepend`. |
| 22 | [Supercharge your Stimulus controllers with Custom APIs](https://marcoroth.dev/posts/supercharge-your-stimulus-controllers-with-custom-apis) | Marco Roth, Stimulus maintainer | Stimulus's `static blessings` extension point, and the framing that Stimulus's value *is* its small set of declarative conventions. |
| 23 | [Write Reliable, Asynchronous Integration Tests With Capybara](https://thoughtbot.com/blog/write-reliable-asynchronous-integration-tests-with-capybara) | Joe Ferris, thoughtbot | Predates Hotwire and matters more because of it: every Turbo UI is asynchronous, and this is the discipline that stops the test suite from going flaky. |
| 24 | [The Hotwire-Rails summit, or interactive multi-step forms at peak UX](https://evilmartians.com/chronicles/hotwire-rails-summit-interactive-multi-step-forms-peak-ux) | Evil Martians | A complete multi-step wizard built from morphing + View Transitions and nothing else. |
| 25 | [Hotwire Native hub](https://masilotti.com/hotwire-native/) + [*Hotwire Native for Rails Developers*](https://pragprog.com/titles/jmnative/hotwire-native-for-rails-developers/) | Joe Masilotti | The mobile story from the person who helped build the iOS library — including an unusually honest account of when Hotwire Native is the wrong choice. |

**Near misses worth knowing about:** [ViewComponent in the Wild II: Supercharging Your Components](https://evilmartians.com/chronicles/viewcomponent-in-the-wild-supercharging-your-components) (sidecar Stimulus controllers, done properly) · [Hotwire and HTMX — Same Principles, Different Approaches](https://radan.dev/articles/hotwire-and-htmx) · [Turbo morphing woes](https://thoughtbot.com/blog/turbo-morphing-woes) (three concrete morph failure modes and their fixes) · [Announcing Hotwire Spark](https://dev.37signals.com/announcing-hotwire-spark-live-reloading-for-rails/) (HMR for Stimulus with no build tool) · David Colby's Turbo 8 trilogy — [refreshes](https://colby.so/posts/turbo-8-morphing-refreshes-on-rails), [sortable tables](https://colby.so/posts/turbo-8-refresh-sorting), [search & filter](https://colby.so/posts/turbo-8-search-and-filter) · [Turbo Frames on Rails](https://www.colby.so/posts/turbo-frames-on-rails) + [Turbo Streams on Rails](https://www.colby.so/posts/turbo-streams-on-rails) (the best plain reference pair) · [Use native dialog with Turbo, no JavaScript](https://railsdesigner.com/dialog-turboframe/) · [How to debug issues with Turbo Morphing](https://radan.dev/articles/how-to-debug-issues-with-turbo-morphing) · [The most underrated Rails helper: dom_id](https://boringrails.com/articles/rails-dom-id-the-most-underrated-helper/) · [Modern CSS patterns in Campfire](https://dev.37signals.com/modern-css-patterns-and-techniques-in-campfire/) · [The Art of Turbo Mount](https://evilmartians.com/chronicles/the-art-of-turbo-mount-hotwire-meets-modern-js-frameworks) (React/Vue islands inside Hotwire) · [AnyCable v1.4](https://evilmartians.com/chronicles/enter-anycable-v1-4-reliable-real-time-features-for-apps-of-any-size) (when Action Cable stops being enough) · [Making Accessible Web Apps with Rails and Hotwire](https://rubyevents.org/talks/making-accessible-web-apps-with-rails-and-hotwire) (Bruno Prieto, Rails World 2024) · [Radan's printable Turbo 8 cheat-sheet PDF](https://radan.dev/cheatsheet/).

---
## Source-set notes

**Evil Martians**

Source: evilmartians.com/chronicles (highest-priority source). Compiled by reading full article text (via the `.md` source variant of each URL, e.g. `evilmartians.com/chronicles/<slug>.md`) and transcribing code verbatim, plus WebSearch sweeps (`site:evilmartians.com/chronicles` + turbo/stimulus/hotwire/turbo streams/turbo frames/view component/anycable keywords) to catch articles not linked from the index page directly, plus direct review of Hotwire-adjacent Evil Martians open-source repos.

Articles are grouped by theme below. Some articles legitimately span multiple themes and are cross-referenced with a short pointer rather than duplicated in full.

**Inaccessible / out of scope notes:**
- All targeted articles were reachable — Evil Martians' Cloudflare protection did not block WebFetch when using the `.md` source-URL variant of each article; no curl-impersonate fallback was needed in practice.
- "Keep up with the Tines: Rails frontend revamp" (2020) was read in full and found to be pre-Hotwire (Webpacker + React + MobX + GraphQL) with zero mention of Hotwire/Turbo/Stimulus/ViewComponent — included below only as a documented "checked, ruled out" entry, not fabricated as relevant.
- "The Art of Turbo Mount" article's FortuneSheet-specific integration code snippets were not fully captured verbatim in this pass (summarized instead) — the canonical Turbo Mount install/usage code is captured in full under Open-source projects below and is representative of the same API.

---

**37signals dev blog + DHH**

Source index: https://dev.37signals.com/ (61 posts, June 2022 → April 2026, no pagination — all on one page).
Jorge Manrubia author archive: https://dev.37signals.com/author/jorge/ (19 posts).

---

**Marco Roth / hotwire.io + Radan Skorić**

**Important:** radanskoric.com has **moved to radan.dev**. Old URLs still resolve/redirect; canonical links now use `radan.dev`. Article index: https://radan.dev/archives/ (note `/articles` 404s — the index is `/archives/`).
Marco Roth's blog index is https://marcoroth.dev/blog (not `/posts` — that 404s; individual posts live at `/posts/<slug>`).

Radan sells **"Master Hotwire"** (https://masterhotwire.com) — an e-book for experienced Rails devs covering Hotwire + Hotwire Native. Several of his articles are extracted from it. He also gives away a **printable A4 Turbo 8 cheat-sheet PDF**: https://radan.dev/cheatsheet/ → https://radan.dev/assets/Turbo8cheatsheet.pdf (two pages, quick reference — worth mirroring in this repo's references).

Marco Roth also runs the **Hotwire Weekly** newsletter (https://hotwire.io/newsletter) and is a Stimulus maintainer + Turbo contributor.

---

**thoughtbot, Boring Rails, Fly.io, Honeybadger, AppSignal, Speedshop**

Sources: thoughtbot.com/blog, boringrails.com (Matt Swanson), fly.io/ruby-dispatch (Brad Gessler, Sam Ruby), honeybadger.io/blog, blog.appsignal.com, speedshop.co (Nate Berkopec). 58 articles read in full and transcribed, grouped by theme.

---

**GoRails, Rails Designer, hotwire_combobox**

---

**Sean Doyle, Joe Masilotti, Julian Rubisch, conference talks**

---


---

## Philosophy — why HTML over the wire (and why not React)


### The Long Game: Why Rails Survived the Hype Cycle and What It Means for Your Startup
- **Author:** Irina Nazarova | **Date:** August 18, 2025 | **URL:** https://evilmartians.com/chronicles/the-long-game-why-rails-survived-the-hype-cycle-and-what-it-means-for-your-startup
- **Summary:** A "Rails is not dead" retrospective mapped onto the Gartner Hype Cycle (Technology Trigger → Peak of Inflated Expectations → Trough of Disillusionment → Slope of Enlightenment → Plateau of Productivity). Argues Rails' 2016-2020 "trough" (Twitter's 2009 migration being the first "Rails is dead" moment) was exactly when serious infra investment happened: Shopify's YJIT, Stripe's Sorbet, Gusto/Stripe's Packwerk, Evil Martians' own AnyCable, and StimulusReflex (Hotwire's predecessor). Frames Rails' "big tent" architecture — adapters behind clear interfaces for DB, jobs, testing, and frontend (Hotwire vs. Inertia, both first-class) — as the reason the framework can absorb new tooling without a rewrite.
- **Code worth stealing:** None — this is a pure opinion/industry-history piece, no code blocks in the source.
- **Opinion / hot take:** "Ruby on Rails today is a developer productivity-focused framework that's never been better for startups." Also: "By separating interface from implementation, the 'big tent' keeps Rails productive, adaptable, and a place where developer happiness thrives." Frontend take: "Frontend approaches including Hotwire for native Rails reactivity or Inertia for modern JavaScript preferences remain interchangeable" — i.e. the author explicitly refuses to declare one frontend approach the winner.

### Keeping Rails cool: the modern frontend toolkit
- **Authors:** Irina Nazarova, Travis Turner | **Date:** December 10, 2024 | **URL:** https://evilmartians.com/chronicles/keeping-rails-cool-the-modern-frontend-toolkit
- **Summary:** Lays out Evil Martians' "silver toolbox" strategy for Rails frontend: don't pick one framework, pick the right tool per screen. Four tools: (1) Hotwire/Turbo for CRUD/admin pages where server-side state is sufficient, (2) Turbo Mount as the escape hatch to drop a modern JS component into a Hotwire page without abandoning the architecture, (3) Inertia for full SPA-grade experiences that still want Rails controllers/routing, (4) Vite Ruby as the shared build-tool foundation underpinning all three. Uses the "Turbo Music Drive" demo app as a worked example of progressively upgrading the same feature from Hotwire → Turbo Mount → Inertia as interactivity requirements grow.
- **Code worth stealing:** No code blocks captured in this fetch (article is largely narrative/strategy); see the Turbo Mount and Inertia articles for the actual code.
- **Opinion / hot take:** Tagline: "Cooling down Hot Wires with Inertia" — i.e. Hotwire's rough edges (heavy client interactivity) are best "cooled" by escalating to Inertia rather than forcing everything through Turbo/Stimulus. Frontend productivity is a property of *strategic combination* of tools, not a single dogmatic choice.


### ViewComponent in the Wild I: Building Modern Rails Frontends
- **Authors:** Alexander Baygeldin, Travis Turner | **Date:** October 12, 2022 | **URL:** https://evilmartians.com/chronicles/viewcomponent-in-the-wild-building-modern-rails-frontends
- **Summary:** Argues for classic server-driven MVC + ViewComponent as a first-class alternative to SPA architecture, not a legacy fallback. Core definition: "a view component is just a Ruby object with an associated template" — instantiate it and pass to Rails' `#render`. Frames the real payoff as parity between backend/frontend teams (both now "think in components") and fast, isolated unit tests instead of slow/brittle request or system specs. Lays out five best practices: test the actual template behavior (not private helper methods) via `render_inline`, use implicit context (e.g. `dry-effects`) for global/popular data like `current_user` instead of prop-drilling, pass components-as-slots rather than drilling data when a child's data needs diverge from its parent, extract general-purpose/presentational components separately from app-specific/container components, and never issue DB queries inside a component (fetch in controllers, preload eagerly).
- **Code worth stealing:**
```html
<!-- app/views/components/menu/component.html.erb -->
<% if current_user %>
  Hello, <%= current_user.name %>!
  <%= button_to t(".sign_out"), users_sessions_path, method: :delete %>
<% else %>
  <%= button_to t(".sign_in"), users_sessions_path %>
<% end %>
```
```ruby
# spec/views/components/menu_spec.rb
describe Menu::Component do
  subject { page }
  let(:component) { described_class.new }

  before do
    with_current_user(user) { render_inline(component) }
  end

  context "when current_user is present" do
    let(:user) { build(:user, name: "Handsome") }
    it("renders sign out button") { is_expected.to have_link "Sign out" }
    it("has greeting text") { is_expected.to have_content "Hello, Handsome!" }
  end

  context "when current_user is absent" do
    let(:user) { nil }
    it("renders sign in button") { is_expected.to have_link "Sign in" }
  end
end
```
```ruby
# spec/system/components/my_component_spec.rb — testing JS-driven component behavior via its preview page
it "does some dynamic stuff" do
  visit("/rails/view_components/my_component/default")
  click_on("JavaScript-infused button")
  expect(page).to have_content("dynamic stuff")
end
```
```ruby
# Slots pattern to avoid "argument drilling" when a child's needs diverge from its parent's
# app/views/components/feed/component.rb
class Feed::Component < ApplicationViewComponent
  renders_one :pinned
  renders_many :posts
end
```
```erb
<!-- app/views/components/feed/component.html.erb -->
<%= pinned %>
<% posts.each do |post| %>
  <%= post %>
<% end %>
```
```erb
<%= render(Feed::Component.new) do |c| %>
  <% c.with_pinned do %>
    <%= render(Post::Component.new(@pinned_post)) %>
  <% end %>
  <% @posts.each do |post| %>
    <% c.with_post do %>
      <%= render(Post::Component.new(post)) %>
    <% end %>
  <% end %>
<% end %>
```
- **Opinion / hot take:** "The classic, server-driven MVC approach... why shouldn't we use it?" — cites GitHub's own multi-page ERB-rendered Rails app as evidence at scale. "ViewComponent unit tests are over 100x faster than similar controller tests" (cited from the GitHub codebase). "Views are for rendering data, not fetching it" — a hard rule against DB queries in components.


### Inertia.js in Rails: a new era of effortless integration
- **Authors:** Svyatoslav Kryukov, Travis Turner | **Date:** December 31, 2025 | **URL:** https://evilmartians.com/chronicles/inertiajs-in-rails-a-new-era-of-effortless-integration
- **Summary:** Announces expanded official Evil Martians support/maintenance for `inertia_rails`, and explicitly draws the line between Hotwire and Inertia as *complementary, not competing* tools: "Hotwire provides server-side rendering of HTML and partial updates of the page using Turbo Streams and Turbo Frames," recommended when a team wants minimal JS and only needs 1-2 interactive components (pointing to Turbo Mount for that narrow case); Inertia is recommended when a team is already frontend-framework-fluent and wants full React/Vue/Svelte view layers while keeping Rails controllers/routing and *without* standing up a separate JSON API or client-side router. Ships three official starter kits (React/Vue/Svelte) and confirms Rails' Inertia adapter has reached feature parity with Laravel's (Inertia 2.0 `once`/`scroll`/`merge` props, flash data, new `render` syntax).
- **Code worth stealing:**
```bash
rails new inertia_rails_example --skip-js
cd inertia_rails_example
bundle add inertia_rails
bin/rails generate inertia:install
```
```ruby
class InertiaExampleController < InertiaController
  def index
    render inertia: {
      rails_version: Rails.version,
      ruby_version: RUBY_DESCRIPTION,
      rack_version: Rack.release,
      inertia_rails_version: InertiaRails::VERSION,
    }
  end
end
```
```ruby
# Base controller pattern for globally shared props (analogous to Turbo's current_user meta-tag trick)
class InertiaController < ApplicationController
  # Share data with all Inertia responses
  # see https://inertia-rails.dev/guide/shared-data
  inertia_share user: -> { Current.user&.as_json(only: [:id, :name, :email]) }
end
```
```ruby
class PostsController < InertiaController
  before_action :set_post, only: %i[ show edit update destroy ]

  def edit
    render inertia: {
      post: serialize_post(@post)
    }
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post was successfully updated."
    else
      redirect_to edit_post_url(@post), inertia: { errors: @post.errors }
    end
  end
end
```
- **Opinion / hot take:** Deliberately non-competitive framing: Hotwire for "minimal JS, enhance server-rendered pages"; Inertia for "teams already proficient in frontend frameworks... without abandoning Rails conventions." Turbo Mount is explicitly the recommended bridge for the narrow one-or-two-components case rather than reaching for either Hotwire's full Stimulus toolkit or full Inertia.

### Simplicity, vanished?! Solving the mystery with Inertia.js + Rails
- **Authors:** Svyatoslav Kryukov, Travis Turner | **Date:** July 29, 2025 | **URL:** https://evilmartians.com/chronicles/simplicity-vanished-solving-the-mystery-with-inertia-js-and-rails
- **Summary:** Argues API+SPA architecture is usually unjustified complexity, citing a stat that "only 31% of Rails developers use Stimulus" as evidence most Rails shops have already defaulted to full client-side frameworks rather than Hotwire — and that Inertia lets those teams keep that framework choice while dropping the API-layer/client-router tax. Explicitly concedes Hotwire's territory: **"if you don't need heavy client-side interactivity, Hotwire is genuinely simpler and probably the right choice."** Contrasts navigation models: "Unlike Hotwire's magic, Inertia uses explicit links" (i.e. Inertia's `<Link>` is a plain, traceable AJAX call vs. Turbo Drive's automatic link/form interception). Shows Inertia's answer to real-time updates: keep using ActionCable/Turbo-Streams-style broadcasting, but on receipt just call Inertia's `router.reload({ only: [...] })` to re-fetch specific named props instead of hand-patching the DOM — conceptually the Inertia analogue of a Turbo Stream partial update.
- **Code worth stealing:**
```jsx
import { Link } from "@inertiajs/react"

export const PostPreview = ({ post }) => (
  <div>
    <h2>{post.title}</h2>
    <Link href={`/posts/${post.id}`}>Show this post</Link>
  </div>
)
```
```ruby
# Partial/lazy props — the Inertia analogue of only sending what a Turbo Frame needs
class PostsController < ApplicationController
  def show
    render inertia: {
      post: serialize_post(@post),
      comments: InertiaRails.optional do
        serialize_comments(@post.comments.includes(:user))
      end
    }
  end
end
```
```ruby
class ApplicationController < ActionController::Base
  inertia_share flash: -> { flash.to_hash },
                current_user: -> { current_user&.as_json(...) },
                feature_flags: -> { FeatureFlags.all.as_json(...) }
end
```
```jsx
import { useForm } from '@inertiajs/react'

export const CreateUserForm = ({ user }) => {
  const { data, setData, post, errors } = useForm({email: ""})

  return (
    <form onSubmit={e => { e.preventDefault(); post("/passwords") }}>
      <input type="text" value={data.email}
        onChange={(e) => setData("email", e.target.value)}
      />
      {errors.email && <span>{errors.email}</span>}
      <button type="submit">Reset Password</button>
    </form>
  )
}
```
```js
// Keeping ActionCable for the transport, but resolving into an Inertia partial reload
// instead of hand-writing DOM patch logic (contrast with Turbo Streams' broadcast_append_to)
const chatChannel = consumer.subscriptions.create(
  { channel: "ChatChannel", room_id: roomId },
  {
    received(data) {
      switch(data.type) {
        case "message_created":
          router.reload({ only: ["messages"] })
          break
      }
    }
  }
)
```
```typescript
// typelizer-generated TS types kept in sync with Rails serializers
export interface Post {
  id: number;
  title: string;
  body: string;
  published_at: string | null;
  category: "news" | "article" | "blog" | null;
  author: Author;
}
```
- **Opinion / hot take:** Core thesis: "question complexity" — full SPA/API architecture is often cargo-culted rather than chosen deliberately. But notably even this pro-Inertia piece explicitly hands Hotwire the win for low-interactivity apps rather than claiming universal superiority.


### Turbo Rails tutorial introduction (see chapter table above)
Covered above — includes the author's core "boring but effective" philosophy.

### Filter, search, and sort tables with Rails and Turbo Frames
- **Author:** David Colby | **URL:** https://www.colby.so/posts/filtering-tables-with-rails-and-hotwire
- **Summary:** See Turbo Frames section below for code. Philosophically representative of Colby's default stance: keep filter/sort state in the Rails `session` object (merged across requests) rather than pushing it into client JS state, so multiple filters compose for free server-side.
- **Opinion / hot take:** "The client side code stays light and maintainable, while our server looks and feels familiar to any level of Rails developer."

### Sort tables (almost) instantly with Ruby on Rails and Turbo Frames
- **Author:** David Colby | **URL:** https://www.colby.so/posts/sortable-table-with-rails-and-turbo-frames
- **Summary:** See Turbo Frames section. Philosophical point: presents Turbo Frames and StimulusReflex as equally valid competing approaches, refusing to declare one universally better.
- **Opinion / hot take:** "The right choice for you and your team is almost certain to be the option that your team feels most comfortable with and most productive in." Also: "Rails developers [have] the ability to quickly build fast, modern user experiences without adding the weight and complexity that can come with JavaScript frameworks."

### Handling modal forms with Rails, Tailwind CSS, and Hotwire
- **Author:** David Colby | **URL:** https://www.colby.so/posts/handling-modal-forms-with-rails-and-hotwire
- **Summary:** See Forms section. Philosophically argues for using community component libraries (`tailwindcss-stimulus-components`) rather than hand-rolling UI primitives.
- **Opinion / hot take:** "One of the joys of Ruby on Rails development is the incredibly robust ecosystem of community-built libraries" — avoid reinventing the wheel.

### Using Hotwire and Rails to build a live commenting system
- **Author:** David Colby | **URL:** https://www.colby.so/posts/using-hotwire-and-rails-to-build-a-commenting-system
- **Summary:** See Real-time section.
- **Opinion / hot take:** "Sending HTML instead of JSON" removes JS complexity: "if you're a small team building standard SaaS applications... spend time learning about Hotwire-powered applications to keep your team productive." Prioritizes developer velocity over frontend framework sophistication.

### Publishing on Gumroad: lessons learned
- **Author:** David Colby | **URL:** https://colby.so/posts/publishing-on-gumroad-lessons-learned
- **Summary:** Reflects on self-publishing the "Hotwiring Rails" ebook: built a custom web-app delivery format instead of a PDF (clickable code, embedded GIFs); found that sales plateau fast once the launch discount ends without active promotion; regrets not collecting reviews early given the $70 price point needs more social proof; credits existing blog/Twitter audience as essential to launch success.
- **Code worth stealing:** N/A (meta/business post, no code).
- **Opinion / hot take:** "The price tag is pretty high at $70, which is a big investment to make without more social proof." Free content builds the audience that makes paid content sellable.

---


### Hotwire: HTML Over The Wire (the manifesto)
- **Author:** 37signals | **Date:** Dec 2020, continuously updated | **URL:** https://hotwired.dev/
- **Summary:** The canonical framing. "An alternative approach to building modern web applications without using much JavaScript by sending HTML instead of JSON over the wire." Three parts: **Turbo** ("a set of complementary techniques for speeding up page changes and form submissions, dividing complex pages into components, and stream partial page updates over WebSocket" — all without writing JavaScript), **Stimulus** for the residual ~20% of custom behavior using "a HTML-centric approach to state and wiring", **Hotwire Native** as "a web-first framework for building native mobile apps."
- **Opinion / hot take:** The whole pitch is that you get SPA-grade responsiveness while keeping server-side templates and one rendering path.

### The time is right for Hotwire
- **Author:** DHH | **Date:** 2021 | **URL:** https://world.hey.com/dhh/the-time-is-right-for-hotwire-ecdb9b33
- **Summary:** The cultural argument, not the technical one. DHH claims the mid-2010s SPA/React/GraphQL enthusiasm peaked and enough developers "gave this approach an earnest shot and concluded 'this just isn't for me'". He deliberately does NOT argue SPAs are inherently flawed — only that they're a poor fit for many problem domains, and that industry cycles between enthusiasm and realism. Rails 7 shipping Hotwire as the default frontend is timing meeting readiness.
- **Opinion / hot take:** Framing to steal: "pragmatic plurality" rather than "SPAs are bad." Useful for a repo that wants to be persuasive rather than tribal.

### You can't get faster than No Build
- **Author:** DHH | **Date:** 2023 (post-Rails World) | **URL:** https://world.hey.com/dhh/you-can-t-get-faster-than-no-build-7a44131c
- **Summary:** Argues the frontier moved from "better bundlers" to "no bundler." Stack: vanilla ES6 + **import maps** (no transpiling, no bundling), vanilla CSS with native nesting and custom properties, **Propshaft** as the asset pipeline, HTTP/2 multiplexing making many small files cheap. He concedes esbuild/bun are legitimate (Rails 7.1 ships native bun support) but positions no-build as the emerging default for anyone not already committed to React/Vue.
- **Opinion / hot take:** > "the state of the art is no longer finding more sophisticated ways to build JavaScript or CSS. It's not to build at all." And, on build speed: "It's also fast. Really fast. Infinitely fast."

### A vanilla Rails stack is plenty
- **Author:** Jorge Manrubia | **Date:** December 12, 2024 | **URL:** https://dev.37signals.com/a-vanilla-rails-stack-is-plenty/
- **Summary:** The single most quotable "why no React" post from 37signals. Enumerates the actual stack they run in production: Hotwire, Hotwire Native for mobile, ERB templates + view helpers, import maps, Propshaft, Minitest, PWA, and the Solid trilogy (solid_cache, solid_queue, solid_cable) to remove Redis. Explicitly rejects: React-class frameworks, a JSON API layer to feed them, Redis, and complex build processes.
- **Opinion / hot take:**
  > "Minimal dependencies, maximum productivity. Staying vanilla pays long term dividends."
  > "You don't need React or any other front-end frameworks, nor a JSON API to feed those."
  > "Embrace and celebrate rendering things on the server. It has become cool again."
  > "Vanilla means your app stays nimble. Fewer dependencies mean fewer future headaches."

### Vanilla Rails is plenty
- **Author:** Jorge Manrubia | **Date:** November 8, 2022 | **URL:** https://dev.37signals.com/vanilla-rails-is-plenty/
- **Summary:** Backend counterpart (service objects vs rich domain models) but load-bearing for a Hotwire repo because the whole HTML-over-the-wire model assumes fat models + thin controllers rendering full pages. Their two tactics instead of service objects: **concerns** to organize complex model code, and **object composition / POROs** to delegate implementation while keeping a clean model-level public API (a "facade"). Controllers call domain methods directly — `@contact.designate_to(@box)` — rather than instantiating services.
- **Opinion / hot take:**
  > "The more common mistake is to give up too easily on fitting the behavior into an appropriate object, gradually slipping towards procedural programming."
  Criticizes the Rails community for presenting architecture patterns "as a tradeoff-free answer to a very complex problem." Proof point cited: Basecamp 4, a ~9-year-old codebase with 400 controllers and 500 models.

### The gift of constraints
- **Author:** Jorge Manrubia | **Date:** September 9, 2024 | **URL:** https://dev.37signals.com/the-gift-of-constraints/
- **Summary:** Not Hotwire-specific — process philosophy. Fixed time / variable scope, timeboxing, small teams as forcing functions. Included because the Hotwire design decisions at 37signals repeatedly cite "we had a 2-week appetite" as the reason a simpler solution won.
- **Opinion / hot take:** > "Fixed time, variable scope is probably the single most powerful concept I have ever learned about shipping." / "constraints are not to be avoided or resisted but rather embraced and even induced."

---


### Should you use Hotwire or a Frontend framework on your next Rails project? ★
- **Author:** Radan Skorić | **Date:** Jan 16, 2024 (updated Jul 11, 2026) | **URL:** https://radan.dev/articles/hotwire-or-frontend-framework
- **Summary:** The single best decision framework I found in the whole corpus, and it refuses to be tribal. Once the table-stakes factors (team expertise, existing company stack, available libraries) are neutral, he argues one question dominates: **"How is the complexity of the project distributed between shared state management and visual interactions?"** If complexity lives in shared state, the database is the source of truth and the layer closest to the DB (the backend) is where complexity is cheapest to manage — Hotwire wins. If complexity lives in visual interaction and rendering, the frontend framework is "metaphorically in bed with the browser" — React/Vue/Svelte win. He explicitly names the hybrid as viable and often safest: **"A mostly Hotwire app with small self contained single page applications embedded in the pages."**
- **Opinion / hot take:**
  > "Answering a technical choice by first looking at the tools themselves is usually a bad way to find the answer. It's always a tradeoff and your specific tradeoff comes from the project, not the tools. Understand where is the complexity and **only then find the best tool for the job.**"
  He also crisply restates the standard pro-Hotwire argument and its real content: "With FE frameworks you are managing 2 applications" — not just two codebases but two *running* applications, hence distributed state, which is worst precisely when shared-state complexity dominates.

### Hotwire and HTMX — Same Principles, Different Approaches ★
- **Author:** Radan Skorić | **Date:** Oct 29, 2024 (updated Nov 10, 2024) | **URL:** https://radan.dev/articles/hotwire-and-htmx
- **Summary:** A genuinely balanced comparison — he bought and read *Hypermedia Systems* (the HTMX authors' book) to avoid a straw man. Shared premises: (1) HTML+CSS is a rich interface for interactive experiences; (2) the SPA thick-client pattern adds *incidental* complexity; (3) treat HTML as the **engine of application state** (HATEOAS) and render it on the server. Shared approach: business logic on the server, HTML as the state store, enhance HTML, JS only for what enhanced HTML can't do. The differences are in **ratio of implicit vs explicit enhancement** and **how far to push before you're expected to write custom JavaScript**. Hotwire is implicit/conventional (Turbo Drive silently takes over all navigation; Frames are a "page within a page"); HTMX is explicit/compositional (a large set of orthogonal `hx-*` attributes you combine per element).
- **Code worth stealing:** The HTMX contrast example — every element can issue any HTTP verb on any event and swap any part of the page:
```html
<ul hx-post="/generate" hx-trigger="click[ctrlKey]" hx-swap="beforeend">
  <li> Click while holding Ctrl to generate new items </li>
</ul>
```
- **Opinion / hot take:** His one-line summaries are the best short definitions in the corpus:
  - Turbo Drive: "intercepts regular browser navigation and instead performs an AJAX request and handles the response itself… It also adds missing HTML functionality, like an ability to make links perform a non-GET request."
  - Turbo Frames: "decompose the page into independent contexts. They implement the mental model of a page within a page."
  - Stimulus: "think of Stimulus as a modern replacement for jQuery… Doesn't take over HTML but instead treats HTML as the source of application state."
  Verdict: "I think both are great, for different reasons."

---


### 4 Tips When Getting Started with Hotwire
- **Author:** Joël Quenneville | **Date:** November 4, 2024 | **URL:** https://thoughtbot.com/blog/4-tips-when-getting-started-with-hotwire
- **Summary:** Four heuristics for Hotwire beginners: (1) "Pretend Hotwire doesn't exist" — build plain Rails pages/links/redirects first, then layer turbo-frames on afterward (inline-edit example needed only 4 extra lines); (2) "Think RESTfully" — Hotwire works best with RESTful resources since `dom_id`/URL helpers/form helpers depend on it, and any independently-interactive page fragment deserves its own resource; (3) use `dom_id` everywhere (frame ids, stream targets, collection rendering) to avoid ID-mismatch bugs, and define `to_key` on non-AR objects to make `dom_id` work; (4) visualize nested frames (screenshot + draw boxes, or the hotwire-dev-tools browser extension) since nesting/targeting gets confusing fast.
- **Code worth stealing:**
```erb
<!-- app/views/abilities/_ability.html.erb -->
<%= turbo_frame_tag dom_id(ability) do %>
  <dt><%= ability.name.to_s.titleize %></dt>
  <dd>
    <span><%= ability.value %></span>
    <span>(<%= sprintf "%+d", ability.modifier %>)</span>
    <%= link_to "Edit", [:edit, @character, ability] %>
  </dd>
<% end %>
```
```erb
<!-- app/views/abilities/edit.html.erb -->
<%= turbo_frame_tag dom_id(@ability) do %>
  <%= form_with model: [@character, @ability] do |f| %>
    <%= f.label :value, @ability.name.to_s.titleize %>
    <%= f.number_field :value, min: 1, max: 20 %>
    <%= f.submit %>
  <% end %>
<% end %>
```
- **Opinion / hot take:** "Hotwire works best when composing RESTful resources" — pushes back on the instinct to model Hotwire fragments around DB tables; model them around whatever needs independent interactivity instead.

### Writing better StimulusJS controllers
- **Author:** Matt Swanson | **Date:** Jun 1, 2020 | **URL:** https://boringrails.com/articles/better-stimulus-controllers/
- **Summary:** The foundational "Stimulus mindset" article. Core thesis: don't build one-to-one page/component controllers (the React instinct); build small, generic, composable "primitive" controllers that take configuration via `data-` attributes (URLs, target class names) so the same controller works across unrelated features. Walks through evolving a naive `toggle` controller (hardcoded target/class) into a generic one driven by `data-toggle-class`, then a `filters` controller that goes from field-specific getters to a generic `filterTargets` array keyed off input `name` attributes, then a `checkbox_list` controller using optional targets (`hasCountTarget`) for a "select all / count selected" widget. Finishes by composing all three controllers (`toggle`, `checkbox-list`, `filters`) together via multiple `data-controller` values on one element to build a multi-select filter UI — the payoff of the whole composability argument.
- **Code worth stealing:**
```js
// toggle_controller.js — generic version, configurable class
import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["content"];

  toggle() {
    this.contentTargets.forEach((t) => t.classList.toggle(data.get("class")));
  }
}
```
```html
<div data-controller="toggle" data-toggle-class="hidden">
  <button data-action="toggle#toggle">Toggle</button>
  <div data-target="toggle.content">Some special content</div>
</div>
```
```js
// filters_controller.js — generic version using input `name` attrs
import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["filter"];

  filter() {
    const url = `${window.location.pathname}?${this.params}`;

    Turbolinks.clearCache();
    Turbolinks.visit(url);
  }

  get params() {
    return this.filterTargets.map((t) => `${t.name}=${t.value}`).join("&");
  }
}
```
```js
// checkbox_list_controller.js — optional target pattern via has[Name]Target
import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["count"];

  connect() {
    this.setCount();
  }

  checkAll() {
    this.setAllCheckboxes(true);
    this.setCount();
  }

  checkNone() {
    this.setAllCheckboxes(false);
    this.setCount();
  }

  onChecked() {
    this.setCount();
  }

  setAllCheckboxes(checked) {
    this.checkboxes.forEach((el) => {
      const checkbox = el;
      if (!checkbox.disabled) {
        checkbox.checked = checked;
      }
    });
  }

  setCount() {
    if (this.hasCountTarget) {
      const count = this.selectedCheckboxes.length;
      this.countTarget.innerHTML = `${count} selected`;
    }
  }

  get selectedCheckboxes() {
    return this.checkboxes.filter((c) => c.checked);
  }

  get checkboxes() {
    return new Array(...this.element.querySelectorAll("input[type=checkbox]"));
  }
}
```
```erb
<!-- Composed example: toggle + checkbox-list + filters controllers stacked on one element -->
<div class="filter-section">
  <div class="filters" data-controller="filters">
    <div>
      <div class="filter-label">Brand</div>
      <%= select_tag :brand,
            options_from_collection_for_select(
              Shoe.brands, :to_s, :to_s, params[:brand]
            ),
            include_blank: "All Brands",
            class: "form-select",
            data: { action: "filters#filter", target: "filters.filter" } %>
    </div>
    <div>
      <div class="filter-label">Colorway</div>
      <div class="relative"
        data-controller="toggle checkbox-list"
      >
        <button class="form-select text-left"
          data-action="toggle#toggle"
          data-target="checkbox-list.count"
        >
          All
        </button>

        <div class="hidden select-popup" data-target="toggle.content">
          <div class="flex flex-col">
            <div class="select-popup-header">
              <div class="select-label">Select colorways...</div>
              <button class="clear-filters"
                data-action="checkbox-list#checkNone filters#filter"
              >
                Clear filter
              </button>
            </div>
            <div class="select-popup-list space-y-2">
              <% Shoe.colors.each do |c| %>
                <%= label_tag nil, class: "leading-none flex items-center" do %>
                  <%= check_box_tag 'colors[]', c, params.fetch(:colors, []).include?(c),
                    class: "form-checkbox text-indigo-500 mr-2",
                    data: { target: "filters.filter"} %>
                  <%= c %>
                <% end %>
              <% end %>
            </div>
            <div class="select-popup-action-footer">
              <button class="p-2 w-full select-none" data-action="filters#filter">Apply</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
```
- **Opinion / hot take:** "Stimulus is not React. React is not Stimulus... There is no virtual DOM or reactive updating or passing 'data down, actions up'. Those patterns are not wrong, just *different* and trying to shoehorn them into a Turbolinks/Stimulus setup will not work." Level one Stimulus usage is "an opinionated, more modern version of jQuery `on('click')` functions"; level two is a set of reusable "behaviors."

### Building GitHub-style Hovercards with StimulusJS and HTML-over-the-wire
- **Author:** Matt Swanson | **Date:** Jun 22, 2020 | **URL:** https://boringrails.com/articles/hovercards-stimulus/
- **Summary:** Full worked example of GitHub/Twitter/Wikipedia-style hovercards using ~30 lines of vanilla Stimulus + `fetch`, no client framework. Controller fetches an HTML fragment from a Rails endpoint on `mouseenter`, injects it via `document.createRange().createContextualFragment()`, caches the injected DOM node as a Stimulus target so subsequent hovers skip the network call, and removes it on `disconnect`. Backend is a plain Rails member route rendered with `layout: false`. Demonstrates reusing the identical `hovercard_controller` for two unrelated model types (Shoe, User) just by swapping the ERB partial — zero new JS. Also gives a short history lesson tracing HTML-over-the-wire back through Turbolinks/pjax to a 2006-era "AHAH" microformat that DHH contributed to.
- **Code worth stealing:**
```erb
<!-- app/views/shoes/feed.html.erb -->
<div
  class="inline-block"
  data-controller="hovercard"
  data-hovercard-url-value="<%= hovercard_shoe_path(shoe) %>"
  data-action="mouseenter->hovercard#show mouseleave->hovercard#hide"
>
  <%= link_to shoe.name, shoe, class: "branded-link" %>
</div>
```
```js
// app/javascript/controllers/hovercard_controller.js
import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["card"];
  static values = { url: String };

  show() {
    if (this.hasCardTarget) {
      this.cardTarget.classList.remove("hidden");
    } else {
      fetch(this.urlValue)
        .then((r) => r.text())
        .then((html) => {
          const fragment = document
            .createRange()
            .createContextualFragment(html);

          this.element.appendChild(fragment);
        });
    }
  }

  hide() {
    if (this.hasCardTarget) {
      this.cardTarget.classList.add("hidden");
    }
  }

  disconnect() {
    if (this.hasCardTarget) {
      this.cardTarget.remove();
    }
  }
}
```
```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :shoes do
    member do
      get :hovercard
    end
  end
end
```
```ruby
# app/controllers/shoes_controller.rb
class ShoesController < ApplicationController
  def hovercard
    @shoe = Shoe.find(params[:id])
    render layout: false
  end
end
```
```erb
<!-- app/views/shoes/hovercard.html.erb -->
<div class="relative" data-hovercard-target="card">
  <div data-tooltip-arrow class="absolute bottom-8 left-0 z-50 bg-white shadow-lg rounded-lg p-2 min-w-max-content">
    <div class="flex space-x-3 items-center w-64">
      <%= image_tag @shoe.image_url, class: "flex-shrink-0 h-24 w-24 object-cover border border-gray-200 bg-gray-100 rounded", alt: @shoe.name %>
      <div class="flex flex-col">
        <span class="text-sm leading-5 font-medium text-indigo-600"><%= @shoe.brand %></span>
        <span class="text-lg leading-0 font-semibold text-gray-900"><%= @shoe.name %></span>
        <span class="flex text-sm text-gray-500">
          <%= @shoe.colorway %>
          <span class="mx-1">&middot;</span>
          <%= number_to_currency(@shoe.price.to_f / 100) %>
        </span>
      </div>
    </div>
  </div>
</div>
```
```css
/* app/javascript/stylesheets/application.css — CSS-only tooltip arrow, no Popper needed */
[data-tooltip-arrow]::after {
  content: " ";
  position: absolute;
  top: 100%;
  left: 1rem;
  border-width: 2rem;
  border-color: white transparent transparent transparent;
}
```
- **Opinion / hot take:** "Somewhere along the way toward our current JavaScript hellscape, programmers decided that HTML was over... But HTML? Yuck!" And: "This stack is a love letter to the web. Use links and forms. Render HTML. Keep your state on the server and in the database... For many it feels like a step backward, but in my opinion it's going back to the way things should be."

### Thinking in Hotwire: Progressive Enhancement
- **Author:** Matt Swanson | **Date:** Aug 16, 2022 | **URL:** https://boringrails.com/articles/thinking-in-hotwire-progressive-enhancement/
- **Summary:** THE conceptual map of the whole Hotwire toolkit, framed as a progressive-enhancement ladder from "no Hotwire at all" up through the full stack, using one running example (adding a comment to a post) at every rung: (1) plain Rails scaffold CRUD, full page loads; (2) add Turbo Drive — same code, AJAX body-swap navigation, mostly invisible, on by default in modern Rails; (3) add Turbo Frames for partial-page updates — "iFrames but they work how you would want them to," canonical use case is inline-edit-in-place by wrapping each list item in a frame with a matching ID; (4) add Turbo Streams for granular add/remove/replace ops — explicitly framed as the spiritual successor to Rails' old Server-Generated JavaScript Responses (SJR/`js.erb`), solving SJR's CSP problems with a CRUD-like abstraction; (5) add Turbo Streams over Action Cable for real-time multi-user updates — explicitly clarifies Streams don't *require* websockets, that's a separate broadcast layer; (6) add Stimulus for client-side sprinkles — explicit warning that Stimulus has no template/JSX system, "if you find yourself generating a lot of HTML in your Stimulus controllers, you should take a step back and re-assess"; (7) add full custom JS components (React/Vue/Web Components) only when truly needed, citing Trix editor as the canonical example shipped inside Rails itself; (8) Turbo Native — reuses Rails views inside real Swift/Kotlin apps via webview, HEY's inbox as the example of a fully-native screen alongside mostly-Rails-view screens; (9) Strada (then unreleased) for native↔web JS bridging.
- **Code worth stealing:** This is a conceptual/architecture article — no code blocks, all diagrams (images not transcribable). The value is entirely the mental model and the "which tool for which job" decision ladder.
- **Opinion / hot take:** "So how should you know when to reach for each tool? I think the best approach comes from the earliest days of web development: progressive enhancement... You should use the least amount of the tooling as possible to achieve your desired outcome. As you move 'down the stack' of what Hotwire offers, you trade off more power for more complexity." On Stimulus: "Stimulus controllers are often general-purpose and under 50 lines of code" and even calls out that a native `<details>` element often beats writing a Stimulus collapse controller at all.

### How To Use Turbolinks to Make Fast Rails Apps
- **Author:** Nate Berkopec | **Date:** 2015-05-27 | **URL:** https://www.speedshop.co/2015/05/27/100-ms-to-glass-with-rails-and-turbolinks.html
- **Summary:** His earliest and most direct "why server-rendered is fast" piece, framed around whether Rails can hit "sub-0.1-second interaction" (the classic Nielsen/NN-group HCI thresholds: 0.1s = instantaneous, 1.0s = flow stays uninterrupted, 10s = attention limit). Argues Turbolinks/pjax invented a third path he calls "view-over-the-wire": instead of SPA-style JSON-over-the-wire, you send fully rendered HTML views, keeping app logic and state on the server. Because the JS VM and CSSOM are never torn down between navigations, you skip 200–700ms of relayout/re-tokenize/re-execute work per page. Built a Rails 5 + Turbolinks 3 TodoMVC as a benchmark: interactions landed at 100–250ms glass-to-glass, versus 25–40ms for a reference Backbone TodoMVC (though the Backbone version never round-trips to a server — LocalStorage only). Cites Shopify (150k+ customers, ~100ms avg response across 300M+ monthly pageviews on Rails), DHH's claim of Basecamp's 27ms avg server response, and GitHub's ~60ms avg as evidence Rails backends aren't the bottleneck — full-page navigation cost is.
- **Code worth stealing:** None with file paths, but describes the pattern: use non-RESTful responses (re-render index directly) instead of `redirect_to` after a `create`, because a redirect doubles round-trips and blows the 100ms budget:
```ruby
def create
  thing = Thing.new(params[:thing])
  if thing.save
    redirect_to #...
```
He argues instead to "just re-render the (updated) index view" rather than redirect.
- **Opinion / hot take:** "Is Rails dead? Can the old Ruby web framework no longer keep up in this age of 'native-like' performance?" ... "instead of sending _data_ over the wire, Turbolinks sent _fully rendered views_. Application logic was reclaimed from the client and kept on the server again. Which meant we got to write more Ruby!" ... "I wouldn't recommend using Turbolinks on existing projects, and using it for greenfield only" (because it removes `load`/`DOMContentLoaded` and breaks jQuery plugins that assume full page loads). Also: "'View-over-the-wire' is better than it got credit for."

### Why Your Rails App is Slow: Lessons Learned from 3000+ Hours of Teaching
- **Author:** Nate Berkopec | **Date:** 2019-06-17 | **URL:** https://www.speedshop.co/blog/what-i-learned-teaching-rails-performance/
- **Summary:** Doesn't name Turbo/Hotwire/Stimulus (pre-dates Hotwire's 2020 release), but it's his clearest general statement of the "server response time barely matters, SPA weight is the real problem" argument that underlies all his later Turbo advocacy — worth keeping for the philosophy angle even though it's framework-agnostic. Core claim: once p90 latency is under 500ms and median is under 100ms, the backend stops being the user-perceived bottleneck at all — because average page load is ~5 seconds and "some JavaScript single-page-applications can take 12 seconds or more on initial render." Uses this to argue language/framework choice (Ruby, Rails) is essentially irrelevant to perceived speed once you're past baseline hygiene; the SPA client-side weight problem dwarfs anything a fast backend can fix.
- **Code worth stealing:** None — no code blocks relevant to Hotwire/Turbo.
- **Opinion / hot take:** "It's 2017 [sic] and web applications don't return flat HTML files anymore... Websites are gargantuan, with JavaScript bundles stretching into the size of megabytes... So how much of a difference does a web application which responds in 1 millisecond or less make in this environment? Vanishingly little." ... "Some JavaScript single-page-applications can take 12 seconds or more on initial render." ... "If Ruby on Rails, frequently maligned 'as too slow' or 'can't scale', can run several of the top 1000 websites in the world by traffic, including that little fly-by-night outfit called GitHub, then it's a fine choice for whatever your application is."

---


### Dynamic forms with Turbo ★★ CORNERSTONE (the best statement of the Hotwire method)
- **Author:** Sean Doyle (Turbo maintainer, thoughtbot) | **Date:** February 2, 2022 | **URL:** https://thoughtbot.com/blog/dynamic-forms-with-turbo
- **Source code:** https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-turbo-dynamic-forms (best read [commit-by-commit](https://github.com/thoughtbot/hotwire-example-template/commits/hotwire-example-turbo-dynamic-forms) or as a unified diff; includes a test suite)
- **Summary:** The framing paragraph is the single most useful thing in the whole corpus for a "how to think in Hotwire" chapter. Doyle contrasts the *questions* a React team asks ("What goes in our JSON schema? How do components render fetched data? Where do we store application state?") with the questions a Hotwire team should ask instead — and the point is to invert the direction of inquiry, not to swap libraries. The worked feature: a shipping-address form where the list of state `<option>`s must stay in sync with the selected country (~3,391 state options across all countries, so rendering them all client-side is out). He builds it **with zero JavaScript first**, using only a second `<button>` carrying `[formmethod="get"]` and `[formaction]` to re-submit the same form as a `GET /addresses/new`, which URL-encodes the current fields as params; the `new` action feeds those params straight into `Address.new` and re-renders with the right state list. *Then* he progressively enhances it. Note the small but load-bearing Rails detail: `params.fetch(:address, {}).permit(...)` instead of `params.require`, so a bare visit to `/addresses/new` still works.
- **Code worth stealing:**
```
"How long could we wait before we introduce our first Stimulus Controller?
 What would it take to build this without a Turbo Stream?
 Could we defer to the server for this?
 Would a full-page navigation work?
 Could these fetch requests be replaced with form submissions?
 What would it take to get started on this feature without Stimulus, Turbo,
 or any JavaScript at all?"
```
```erb
<%# app/views/addresses/new.html.erb — the starting point, no JS at all %>
<section class="w-full max-w-lg">
  <h1>New address</h1>

  <%= render partial: "addresses/address", object: @address %>

  <%= form_with model: @address, class: "flex flex-col gap-2" do |form| %>
    <fieldset class="contents">
      <%= form.label :country %>
      <%= form.select :country, @address.countries.invert %>

      <%# The whole trick: re-submit THIS form as a GET to the same page. %>
      <button formmethod="get" formaction="<%= new_address_path %>">Select country</button>
    </fieldset>

    <%= form.label :line_1 %>
    <%= form.text_field :line_1 %>
    <%= form.label :line_2 %>
    <%= form.text_field :line_2 %>
    <%= form.label :city %>
    <%= form.text_field :city %>
    <%= form.label :state %>
    <%= form.select :state, @address.states.invert %>
    <%= form.label :postal_code %>
    <%= form.text_field :postal_code %>

    <%= form.button %>
  <% end %>
</section>
```
```ruby
# app/controllers/addresses_controller.rb
class AddressesController < ApplicationController
  def new
    @address = Address.new address_params   # was: Address.new
  end

  def create
    @address = Address.new address_params

    if @address.save
      redirect_to address_url(@address)
    else
      render :new, status: :unprocessable_entity   # 422 is REQUIRED for Turbo to render the form again
    end
  end

  def show
    @address = Address.find params[:id]
  end

  private

  def address_params
    # fetch, not require — /addresses/new with no params must still work
    params.fetch(:address, {}).permit(
      :country, :line_1, :line_2, :city, :state, :postal_code,
    )
  end
end
```
```ruby
# app/models/address.rb — validation driven by the same data that renders the options
class Address < ApplicationRecord
  with_options presence: true do
    validates :line_1
    validates :city
    validates :postal_code
  end

  validates :state, inclusion: { in: -> record { record.states.keys }, allow_blank: true },
                    presence: { if: -> record { record.states.present? } }

  def countries = CS.countries.with_indifferent_access
  def country_name = countries[country]
  def states = CS.states(country).with_indifferent_access
  def state_name = states[state]
end
```
- **Opinion / hot take:**
  > "Each line of application code is as much of a liability as it is an asset. Teams have a finite 'innovation token' budget to spend on a project. They should reserve the majority of that budget for differentiating their product from the competition, and minimize the cost of inventing (or re-inventing) Web technologies."
  He is explicit that starting Hotwire work by asking "how should my Stimulus controller make fetch requests?" is importing the SPA mindset into a stack that doesn't need it.
- **Companion post:** **Dynamic forms with Stimulus** — https://thoughtbot.com/blog/dynamic-forms-with-stimulus — the client-side-rendering alternative (render all pairings into the document and filter with Stimulus). He links to it specifically to argue *against* it at this data scale. Reading the two together is the best available "when do I reach for Stimulus" lesson.

### Hotwire: Typeahead searching ★★
- **Author:** Sean Doyle | **Date:** September 17, 2021 | **URL:** https://thoughtbot.com/blog/hotwire-typeahead-searching
- **Source code:** https://github.com/thoughtbot/hotwire-example-template/commits/hotwire-example-typeahead-search
- **Summary:** Builds a collapsible search-as-you-type box with in-line results, keyboard navigation and selection, that only hits the server when there's a term — starting from a plain `<form method="get">` and a `<turbo-frame>`, degrading gracefully with JS off. Sequence: (1) plain GET form to `searches#index`, results rendered as links with `highlight` wrapping matches in `<mark>`; (2) wrap the results template in `<turbo-frame id="search_results">` and point the form at it with `data-turbo-frame="search_results"`; (3) because Turbo requires the response to contain a frame whose `[id]` matches the requesting frame, he encodes the frame id in the URL as `?turbo_frame=` and reads it back with `params.fetch(:turbo_frame, "search_results")` — a reusable trick for making a template renderable into *any* frame; (4) make result links escape the frame via `target="_top"` **on the frame** rather than `data-turbo-frame="_top"` on every `<a>`.
- **Code worth stealing:**
```erb
<%# app/views/layouts/application.html.erb %>
<header>
  <form action="<%= searches_path(turbo_frame: "search_results") %>" data-turbo-frame="search_results">
    <label for="search_query">Query</label>
    <input id="search_query" name="query" type="search">

    <button>Search</button>
  </form>

  <turbo-frame id="search_results" target="_top"></turbo-frame>
</header>

<main><%= yield %></main>
```
```erb
<%# app/views/searches/index.html.erb — frame id echoed from the param, with a default %>
<turbo-frame id="<%= params.fetch(:turbo_frame, "search_results") %>">
  <h1>Results</h1>
  <ul>
    <% @messages.each do |message| %>
      <li>
        <%= link_to highlight(message.body, params[:query]), message_path(message) %>
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
  scope :containing, -> (query) { where <<~SQL, "%" + query + "%" }
    body ILIKE :query
  SQL
end
```
- **Opinion / hot take:** On why he annotates the frame rather than the links: "let's annotate the custom `<turbo-frame>` element with the custom `[target]` attribute instead of annotating the standards-based `<a>` element with a `data`-prefixed custom attribute." A tidy design rule — keep custom attributes on custom elements, leave standard HTML standard.
- Also notes a detail people miss: a `<form>` with no `[method]` defaults to GET, which is correct for a query because searching is idempotent and safe.

### thoughtbot's `hotwire-example-template` repo ★★ (highest-value single link in this batch)
- **Author:** Sean Doyle / thoughtbot | **URL:** https://github.com/thoughtbot/hotwire-example-template
- **Summary:** One Rails app, **one branch per Hotwire technique**, each readable commit-by-commit, most with tests. This is effectively a pattern library and should be mined branch-by-branch when building recipes. Current branches:
  `hotwire-example-action-text-mentions`, `hotwire-example-ag-grid`, `hotwire-example-attachment-album`, `hotwire-example-button-alert-template`, `hotwire-example-chat`, `hotwire-example-dynamic-form-fields`, `hotwire-example-grid`, `hotwire-example-inline-edit`, `hotwire-example-kanban`, `hotwire-example-kanban-preserve-focus`, `hotwire-example-live-preview`, `hotwire-example-map`, `hotwire-example-modal`, `hotwire-example-multi-form-search`, `hotwire-example-pagination`, `hotwire-example-process-network-request`, `hotwire-example-restore-page-state`, `hotwire-example-stimulus-dynamic-forms`, `hotwire-example-template-powered-nested-attributes`, `hotwire-example-tooltip-fetch`, `hotwire-example-turbo-dynamic-forms`, `hotwire-example-turbo-frame-powered-nested-attributes`, `hotwire-example-typeahead-search`, `hotwire-example-upload-processing`, `drawer`.
  Note the paired branches — `stimulus-dynamic-forms` vs `turbo-dynamic-forms`, and `template-powered-nested-attributes` vs `turbo-frame-powered-nested-attributes` — which are deliberate A/B comparisons of two ways to solve the same problem. `kanban` vs `kanban-preserve-focus` is another.
- **Sean Doyle's other Hotwire posts:** https://thoughtbot.com/blog/hotwire-server-rendered-live-previews (Sept 14, 2021 — live preview of form input, server-rendered), https://thoughtbot.com/blog/full-text-search-with-postgres-and-action-text (Nov 3, 2021), https://thoughtbot.com/blog/dynamic-forms-with-stimulus (Feb 1, 2022), https://thoughtbot.com/blog/integration-testing-with-capybara (older, but his testing perspective).

---

---

## Turbo Drive & navigation


### Hotwire: Reactive Rails with no JavaScript?
- **Author:** Vladimir Dementyev | **Date:** April 12, 2021 | **URL:** https://evilmartians.com/chronicles/hotwire-reactive-rails-with-no-javascript
- **Summary:** The foundational Evil Martians Hotwire article (companion to a RailsConf 2021 talk), walking through hotwire-ifying an existing Turbolinks-era Rails app step by step: Turbolinks → Turbo Drive, then Turbo Frames for scoped item updates, then Turbo Streams for cross-frame updates (flash messages + real-time broadcast), and finally Stimulus + custom elements for the cases HTML-over-the-wire genuinely can't cover (DOM-position hacks via MutationObserver, per-user message styling via Custom Elements). Explicitly documents the discovery that Turbo Frames are scoped to their own frame and can't update siblings — which is why Turbo Streams exist.
- **Code worth stealing:**
```javascript
// Before (Turbolinks)
import Turbolinks from 'turbolinks';
Turbolinks.start();
// After (Turbo Drive)
import "@hotwired/turbo"
```
```ruby
# Redirects must use 303 See Other so Turbo's fetch "redirect: follow" auto-GETs
redirect_to workspace, status: :see_other
```
```erb
<!-- _item.html.erb : turbo frame per list item -->
<%= turbo_frame_tag dom_id(item) do %>
  <div class="item">
    <%= form_for item do |f| %>
      <%= f.check_box :completed, onchange: "this.form.requestSubmit();" %>
      <%= f.text_field :desc %>
    <% end %>
    <%= button_to item_path(item), method: :delete %>
      Delete
    <% end %>
  </div>
<% end %>
```
```ruby
class ItemsController < ApplicationController
  def update
    item.update!(item_params)
    render partial: "item", locals: { item }
  end

  def destroy
    item.destroy!
    render partial: "item", locals: { item }
  end
end
```
```erb
<!-- Respond with an EMPTY frame to remove the node on delete -->
<%= turbo_frame_tag dom_id(item) do %>
  <% unless item.destroyed? %>
    <div class="item"><!-- ... --></div>
  <% end %>
<% end %>
```
```html
<!-- Raw turbo-stream element shape -->
<turbo-stream action="replace" target="flash-alerts">
  <template>
    <div id="flash-alerts" class="alerts"><!--  --></div>
  </template>
</turbo-stream>
```
```javascript
// Old JS-template era
// destroy.js.erb
$("#<%= dom_id(item) %>").remove();
```
```erb
<!-- Turbo Streams equivalent -->
<!-- destroy.html.erb -->
<%= turbo_stream.remove dom_id(item) %>
```
```erb
<!-- Combining frame + stream update: only works if you go all-streams -->
<!-- _item_update.html.erb -->
<%= turbo_stream.replace dom_id(item) do %>
  <%= render item %>
<% end %>
<%= turbo_stream.replace "flash-alerts" do %>
  <%= render "shared/alerts" %>
<% end %>
```
```erb
<!-- Cleaner: put shared flash-replace logic in the turbo_stream layout -->
<!-- layouts/application.turbo_stream.erb -->
<%= turbo_stream.replace "flash-alerts" do %>
  <%= render "shared/alerts" %>
<% end %>
<%= yield %>
```
```ruby
def update
  item.update!(item_params)
  flash.now[:notice] = "Item has been updated"
  # no explicit render — implicit render + turbo_stream layout does the flash
end
```
```erb
<!-- update.turbo_stream.erb -->
<%= turbo_stream.replace dom_id(item) do %>
  <%= render item %>
<% end %>
```
```erb
<!-- Subscribing to a broadcast stream from HTML -->
<!-- workspaces/show.html.erb -->
<main>
  <%= turbo_stream_from workspace %>
</main>
```
```ruby
# Broadcasting via Turbo::StreamsChannel instead of a hand-rolled ActionCable channel
def broadcast_changes
  return if item.errors.any?
  if item.destroyed?
    Turbo::StreamsChannel.broadcast_remove_to workspace, target: item
  else
    Turbo::StreamsChannel.broadcast_replace_to workspace, target: item, partial: "items/item", locals: { item }
  end
end
```
```ruby
# Custom RSpec matcher for turbo stream broadcasts (turbo-rails had none at the time)
module Turbo::HaveBroadcastedToTurboMatcher
  include Turbo::Streams::StreamName

  def have_broadcasted_turbo_stream_to(*streamables, action:, target:)
    target = target.respond_to?(:to_key) ? ActionView::RecordIdentifier.dom_id(target) : target
    have_broadcasted_to(stream_name_from(streamables))
      .with(a_string_matching(%(turbo-stream action="#{action}" target="#{target}")))
  end
end

RSpec.configure do |config|
  config.include Turbo::HaveBroadcastedToTurboMatcher
end
```
```ruby
# usage
it "broadcasts a deleted message" do
  expect { subject }.to have_broadcasted_turbo_stream_to(
    workspace, action: :remove, target: item
  )
end
```
```javascript
// Stimulus + stimulus-use's useMutation to fix DOM-position after a stream append
import { Controller } from "stimulus";
import { useMutation } from "stimulus-use";

export default class extends Controller {
  static targets = ["lists", "newForm"];

  connect() {
    [this.observeLists, this.unobserveLists] = useMutation(this, {
      element: this.listsTarget,
      childList: true,
    });
  }

  mutate(entries) {
    const entry = entries[0];
    if (!entry.addedNodes.length) return;
    this.unobserveLists();
    this.listsTarget.append(this.newFormTarget);
    this.observeLists();
  }
}
```
```erb
<!-- Passing current user identity to JS via meta tags, tracked for Turbo cache invalidation -->
<head>
  <% if logged_in? %>
    <meta name="current-user-name" content="<%= current_user.name %>" data-turbo-track="reload">
    <meta name="current-user-id" content="<%= current_user.id %>" data-turbo-track="reload">
  <% end %>
</head>
```
```javascript
let user;
export const currentUser = () => {
  if (user) return user;
  const id = getMeta("id");
  const name = getMeta("name");
  user = { id, name };
  return user;
};
function getMeta(name) {
  const element = document.head.querySelector(`meta[name='current-user-${name}']`);
  if (element) return element.getAttribute("content");
}
```
```ruby
def create
  Turbo::StreamsChannel.broadcast_append_to(
    workspace,
    target: ActionView::RecordIdentifier.dom_id(workspace, :chat_messages),
    partial: "chats/message",
    locals: { message: params[:message], name: current_user.name, user_id: current_user.id }
  )
end
```
```html
<!-- Using a Custom Element instead of Stimulus for per-user message styling -->
<any-chat-message class="chat--msg" data-author-id="<%= user_id %>">
  <%= message %>
  <div data-role="author"><%= name %></div>
</any-chat-message>
```
```javascript
import { currentUser } from "../utils/current_user";

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
- **Opinion / hot take:** "The classic HTML-first Rails way was my way (or the highway)... I still don't understand why we need to stuff every web app with reacts and webpacks." Also concludes candidly: "does Reactive Rails With Zero JavaScript exist after all? Not really. We removed a lot of JS code but eventually had to replace it with something new... more utilitarian... requires good knowledge of both JavaScript and the latest browser APIs" — a rare admission from a Hotwire advocate that it isn't zero-JS in practice.


### Turbo Drive (hotrails.dev)
See full entry in the Turbo Rails Tutorial section (Chapter 3) above — covers link/form interception, `data-turbo="false"`, `data-turbo-track="reload"`, and progress-bar styling.

---


### Better navigation in HEY
- **Author:** Jason Zimdars | **Date:** December 1, 2022 | **URL:** https://dev.37signals.com/better-navigation-in-hey/
- **Summary:** A useful negative result. They wanted an in-app Back button and explicitly *rejected* replicating browser history — no `history.back()`, no Turbo `restorationData`. Instead: a **hierarchical** back that always returns you up the app's own structure (Imbox → Paper Trail always goes back to Imbox, regardless of history), plus referrer validation so Back can never take you off the app to another site, plus conditional rendering of Back vs a Home/Imbox button depending on context. Sections gained a consistent subnavigation index so you can navigate up to a top-level screen.
- **Opinion / hot take:** Constraint-driven — a 2-week appetite produced "a simpler solution" with less code than a faithful history implementation. Good ammunition against reflexively reaching for Turbo's history APIs.

---


### Migrating From Turbolinks To Turbo
- **Author:** Julio Sampaio | **Date:** January 10, 2022 | **URL:** https://www.honeybadger.io/blog/hb-turbolinks-to-turbo/
- **Summary:** Step-by-step migration of an existing Rails app from `turbolinks` gem to `@hotwired/turbo-rails`. Covers swapping the JS import, updating `data-turbolinks-*` → `data-turbo-*` attributes in the layout, opting individual links/forms out of Turbo, adding model validations + `unprocessable_entity` status codes so Turbo Drive's error-handling kicks in correctly on failed form submits, wrapping a form in `turbo_frame_tag`, and customizing/speeding up the built-in progress bar.
- **Code worth stealing:**
```javascript
// app/javascript/packs/application.js
import "@hotwired/turbo-rails";
```
```erb
<%# app/views/layouts/application.html.erb %>
<%= stylesheet_link_tag 'application', media: 'all', 'data-turbo-track': 'reload' %>
<%= javascript_pack_tag 'application', 'data-turbo-track': 'reload' %>
```
```ruby
# def create / def update in posts_controller.rb — Turbo needs 422 to render the form with errors
format.html { render :new, status: :unprocessable_entity }
format.html { render :edit, status: :unprocessable_entity }
```
```erb
<%= turbo_frame_tag post do %>
    ...
<% end %>
```
```css
.turbo-progress-bar {
  height: 15px;
  background-color: gold;
}
```
```javascript
window.Turbo.setProgressBarDelay(1); // ms; default threshold is 500ms
```
- **Opinion / hot take:** States plainly that Turbolinks "is no longer under active development" and has been superseded by Turbo under the Hotwire umbrella — a migration-now recommendation, not hedged.

### A pragmatic guide for adding React to an existing Rails application (and still use Hotwire)
- **Author:** Steve Polito | **Date:** June 28, 2024 | **URL:** https://thoughtbot.com/blog/add-react-to-an-existing-rails-app
- **Summary:** Not a Hotwire tutorial per se, but documents the concrete interop problem of mixing React into a Turbo Drive app: since Turbo Drive replaces `<body>` on navigation, a client-rendered React root left mounted becomes orphaned/leaked. Fix is to mount on `turbo:load` and explicitly `root.unmount()` on `turbo:before-visit`, using React 18's `createRoot`. Migrates the app off `importmap-rails` onto `jsbundling-rails`/esbuild first (needed for JSX), then reinstalls Turbo/Stimulus under the new bundler.
- **Code worth stealing:**
```javascript
document.addEventListener("turbo:load", () => {
  const app = document.getElementById("app");
  if (app) {
    const root = createRoot(app);
    root.render(<App />);
    document.addEventListener("turbo:before-visit", () => {
      root.unmount();
    });
  }
});
```
- **Opinion / hot take:** Frames this explicitly as "sprinkling" React into specific components rather than a rewrite — Hotwire and React are not framed as mutually exclusive, just requiring an explicit lifecycle bridge at Turbo Drive's navigation boundary.

### Beautiful Rails confirmation dialogs (with zero JavaScript)
- **Author:** Matt Swanson (guest collab with Stephen Margheim of High Leverage Rails) | **Date:** Dec 15, 2025 | **URL:** https://boringrails.com/articles/data-turbo-confirm-beautiful-dialog/
- **Summary:** Replaces the ugly native `confirm()` popup that Turbo's `data-turbo-confirm` triggers with a fully styled, animated native `<dialog>` element — using zero JavaScript for the dialog mechanics themselves, only ~15 lines to wire it into Turbo's confirm hook. Leans on very recent browser APIs: the Invoker Commands API (`command="show-modal"` / `command="close"` + `commandfor="id"` declarative button-to-dialog wiring, shipped Chrome 131/Safari 18.4), `closedby="any"` for backdrop-click light-dismiss, and `@starting-style` + `transition-behavior: allow-discrete` to animate a normally-unanimatable `display: none ↔ block` transition. Shows the full integration recipe: a single `<dialog>` template dropped once into the app layout, `Turbo.config.forms.confirm` reassigned to a function that populates the dialog's message/button text and returns a Promise resolved by listening for the dialog's native `close` event and checking `returnValue === "confirm"` (set automatically by a `<form method="dialog">` submit button's `value` attribute — no manual event wiring needed). Includes per-trigger button text customization via `data-turbo-confirm-button`, and a one-line `body:has(dialog:modal) { overflow: hidden }` trick for background-scroll locking.
- **Code worth stealing:**
```erb
<button type="button" commandfor="delete-item-dialog" command="show-modal">
  Delete this item
</button>

<dialog id="delete-item-dialog" closedby="any" role="alertdialog"
        aria-labelledby="dialog-title" aria-describedby="dialog-desc">
  <header>
    <hgroup>
      <h3 id="dialog-title">Delete this item?</h3>
      <p id="dialog-desc">Are you sure you want to permanently delete this item?</p>
    </hgroup>
  </header>

  <footer>
    <button type="button" commandfor="delete-item-dialog" command="close">
      Cancel
    </button>
    <%= button_to item_path(item), method: :delete do %>
      Delete item
    <% end %>
  </footer>
</dialog>
```
```css
dialog {
  opacity: 1;
  scale: 1;

  transition:
    opacity 0.2s ease-out,
    scale 0.2s ease-out,
    overlay 0.2s ease-out allow-discrete,
    display 0.2s ease-out allow-discrete;

  @starting-style {
    opacity: 0;
    scale: 0.95;
  }
}

dialog:not([open]) {
  opacity: 0;
  scale: 0.95;
}

dialog::backdrop {
  background-color: rgb(0 0 0 / 0.5);
  transition:
    background-color 0.2s ease-out,
    overlay 0.2s ease-out allow-discrete,
    display 0.2s ease-out allow-discrete;

  @starting-style {
    background-color: rgb(0 0 0 / 0);
  }
}

dialog:not([open])::backdrop {
  background-color: rgb(0 0 0 / 0);
}
```
```erb
<%# app/views/layouts/application.html.erb %>
<dialog id="turbo-confirm-dialog" closedby="any"
        aria-labelledby="turbo-confirm-title" aria-describedby="turbo-confirm-message">
  <header>
    <hgroup>
      <h3 id="turbo-confirm-title">Confirm</h3>
      <p id="turbo-confirm-message"></p>
    </hgroup>
  </header>

  <footer>
    <button type="button" commandfor="turbo-confirm-dialog" command="close">
      Cancel
    </button>
    <form method="dialog">
      <button type="submit" value="confirm">
        Confirm
      </button>
    </form>
  </footer>
</dialog>
```
```js
const dialog = document.getElementById("turbo-confirm-dialog")
const messageElement = document.getElementById("turbo-confirm-message")
const confirmButton = dialog?.querySelector("button[value='confirm']")

Turbo.config.forms.confirm = (message, element, submitter) => {
  // Fall back to native confirm if dialog isn't in the DOM
  if (!dialog) return Promise.resolve(confirm(message))

  messageElement.textContent = message

  // Allow custom button text via data-turbo-confirm-button
  const buttonText = submitter?.dataset.turboConfirmButton || "Confirm"
  confirmButton.textContent = buttonText

  dialog.showModal()

  return new Promise((resolve) => {
    dialog.addEventListener("close", () => {
      resolve(dialog.returnValue === "confirm")
    }, { once: true })
  })
}
```
```erb
<%= button_to item_path(item),
              method: :delete,
              data: {
                turbo_confirm: "Are you sure you want to delete this item?",
                turbo_confirm_button: "Delete item"
              } do %>
  Delete
<% end %>
```
```css
/* Prevent background scroll while a native <dialog> modal is open */
body:has(dialog:modal) {
  overflow: hidden;
}
```
- **Opinion / hot take:** "So much functionality with nothing but declarative HTML! I love it." The whole article is implicitly a hot take against "traditional" community advice (cites GoRails and Flagrant Development posts by name) that says you need a Stimulus controller + manual event coordination for custom confirm dialogs — his point is that as of late 2025 the platform now does all of that natively.

### Ludicrously Fast Page Loads - A Guide for Full-Stack Devs
- **Author:** Nate Berkopec | **Date:** 2015-10-07 | **URL:** https://www.speedshop.co/2015/10/07/frontend-performance-chrome-timeline.html
- **Summary:** A Chrome DevTools Timeline/flamegraph tutorial that uses his own Turbolinks TodoMVC demo as the live worked example throughout, so it doubles as a concrete profiling walkthrough of a Turbolinks page load. He records a hard refresh of the Turbolinks app and gets "254 ms from refresh to done." Walks through Receive Response → Receive Data → Parse HTML → script evaluation, and specifically calls out marking the app's JS bundle `async` plus `data-turbolinks-track="true"` so the browser doesn't block-and-wait on script download/eval before rendering. Includes geographic network latency numbers (NYC→Oregon ~100ms ping, NYC→Indonesia ~364ms RTT) as a reminder that TTFB dominates small perf deltas.
- **Code worth stealing:**
```html
<script src="/assets/application-....js" async="async" data-turbolinks-track="true"></script>
```
- **Opinion / hot take:** "End-users don't care how fast your super-turbocharged bare-metal Node.js server is - they care about the page being completely loaded as fast as possible." "An idle browser is the devil's workshop."

---

---

## Turbo Frames patterns


### Turbo Frames on Rails
- **Author:** David Colby | **Date:** (undated, evergreen reference post) | **URL:** https://www.colby.so/posts/turbo-frames-on-rails
- **Summary:** A from-scratch reference on Turbo Frames: basic tag construction, frame-with-`src` (lazy/eager loading), matching-id replacement across multiple frames on one page, `turbo_frame_request?` for conditional rendering, breaking out with `data-turbo-frame="_top"`, tabbed navigation via a shared target frame, `loading: "lazy"`, and the request-variant pattern (`request.variant = :turbo_frame`).
- **Code worth stealing:**
```erb
<%= turbo_frame_tag "some_id" do %>
  <div>Some framed content</div>
<% end %>
```
```erb
<%= turbo_frame_tag "comments", src: comments_path do %>
  <div>Placeholder content</div>
<% end %>
```
```ruby
if turbo_frame_request?
  render partial: "some_turbo_frame_partial"
else
  render partial: "some_other_partial"
end
```
```erb
<ul>
  <li><a href="user/1/profile" data-turbo-frame="main">Profile</a></li>
  <li><a href="user/1/favorites" data-turbo-frame="main">Favorites</a></li>
</ul>
<turbo-frame id="main"></turbo-frame>
```
```erb
<%= turbo_frame_tag "lazy_frame", src: comments_path, loading: "lazy" do %>
  <div>I'm a loading spinner</div>
<% end %>
```
```ruby
class ApplicationController < ActionController::Base
  before_action :turbo_frame_request_variant
  private
  def turbo_frame_request_variant
    request.variant = :turbo_frame if turbo_frame_request?
  end
end
```
```erb
<%= form_with url: customers_path, method: :get, data: { turbo_frame: "customers", turbo_action: "advance" } do |form| %>
```
- **Opinion / hot take:** "The `turbo_frame_request?` [check] is the only support Rails maintainers endorse... If you're branching all your responses for frames vs not, something isn't right" — frames should work naturally for both contexts, not be riddled with conditionals.

### Filter, search, and sort tables with Rails and Turbo Frames
- **Author:** David Colby | **URL:** https://www.colby.so/posts/filtering-tables-with-rails-and-hotwire
- **Summary:** A reusable `Filterable` controller concern persists filter params in `session["#{resource}_filters"]`, merges new params on each request, and a model-level `.filter(filters)` class method chains `by_name`/`by_team`/`order` scopes. A debounced Stimulus controller auto-submits the form on `input`/`change`, targeting a `turbo_frame`.
- **Code worth stealing:**
```ruby
# app/controllers/concerns/filterable.rb
module Filterable
  def filter!(resource)
    store_filters(resource)
    apply_filters(resource)
  end
  private
  def store_filters(resource)
    session["#{resource.to_s.underscore}_filters"] ||= {}
    session["#{resource.to_s.underscore}_filters"].merge!(filter_params_for(resource))
  end
  def filter_params_for(resource)
    params.permit(resource::FILTER_PARAMS)
  end
  def apply_filters(resource)
    resource.filter(session["#{resource.to_s.underscore}_filters"])
  end
end
```
```ruby
# app/models/player.rb
FILTER_PARAMS = %i[name team_id column direction].freeze
scope :by_name, ->(query) { where('players.name ilike ?', "%#{query}%") }
scope :by_team, ->(team_id) { where(team_id: team_id) if team_id.present? }
def self.filter(filters)
  Player.includes(:team).by_name(filters['name']).by_team(filters['team_id'])
        .order("#{filters['column']} #{filters['direction']}")
end
```
```javascript
// app/javascript/controllers/search_form_controller.js
export default class extends Controller {
  static targets = [ "form" ]
  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => { this.formTarget.requestSubmit() }, 200)
  }
}
```
- **Opinion / hot take:** Session-based filter persistence lets multiple independent filters compose without any client-side state management.

### Sort tables (almost) instantly with Ruby on Rails and Turbo Frames
- **Author:** David Colby | **URL:** https://www.colby.so/posts/sortable-table-with-rails-and-turbo-frames
- **Summary:** Wraps a table in `turbo_frame_tag "players"`; a `collection get 'list'` route renders just the partial; sort-header links regenerate with toggled `direction` via a `sort_link`/`next_direction` helper pair; a small `sort`/`sort-asc`/`sort-desc` CSS triangle indicates current sort.
- **Code worth stealing:**
```erb
<%= turbo_frame_tag "players", class: "..." do %>
  <th><%= sort_indicator if params[:column] == "name" %><%= sort_link(column: "name", label: "Name") %></th>
<% end %>
```
```ruby
# config/routes.rb
resources :players do
  collection { get 'list' }
end
```
```ruby
module PlayersHelper
  def sort_link(column:, label:)
    if column == params[:column]
      link_to(label, list_players_path(column: column, direction: next_direction))
    else
      link_to(label, list_players_path(column: column, direction: 'asc'))
    end
  end
  def next_direction
    params[:direction] == 'asc' ? 'desc' : 'asc'
  end
end
```
```css
.sort { position: absolute; top: 1rem; left: 0.5rem; width: 0; height: 0; border-left: 6px solid transparent; border-right: 6px solid transparent; }
.sort-desc { border-top: 8px solid #fff; }
.sort-asc { border-bottom: 8px solid #fff; }
```

### Pagination and infinite scrolling with Rails and the Hotwire stack
- **Author:** David Colby | **URL:** https://www.colby.so/posts/pagination-and-infinite-scrolling-with-hotwire
- **Summary:** Three escalating techniques using Pagy: (1) plain prev/next links; (2) Turbo Frame with `autoscroll: "true"` + `data-turbo-action: "advance"` for history-preserving pagination; (3) an empty `page_handler` frame targeted by pagination links that returns a `+turbo_frame` view variant containing `turbo_stream_action_tag("append"...)`/`("replace"...)` to append results and swap the pager, avoiding full frame replacement; (4) automatic infinite scroll via a Stimulus controller using `stimulus-use`'s `useIntersection`.
- **Code worth stealing:**
```ruby
def index
  @pagy, @widgets = pagy(Widget.all, items: 10)
end
```
```erb
<%= turbo_frame_tag "widgets", class: "min-w-full", autoscroll: "true" do %>
  <%= render @widgets %>
  <%= render "pager", pagy: @pagy %>
<% end %>
```
```erb
<%# app/views/widgets/index.html+turbo_frame.erb %>
<%= turbo_frame_tag "page_handler" do %>
  <%= turbo_stream_action_tag("append", target: "widgets", template: %(#{render @widgets})) %>
  <%= turbo_stream_action_tag("replace", target: "pager", template: %(#{render "pager", pagy: @pagy})) %>
<% end %>
```
```javascript
// app/javascript/controllers/autoclick_controller.js
import { useIntersection } from 'stimulus-use'
export default class extends Controller {
  options = { threshold: 1 }
  connect() { useIntersection(this, this.options) }
  appear(entry) { this.element.click() }
}
```
- **Opinion / hot take:** The empty-frame + view-variant Turbo Stream technique is "not-obvious but built-in Turbo behavior" that sidesteps manually managing headers, and is preferred over the simpler frame-replace approach for true infinite append.

### Everyone GET in here! Infinite scroll with Rails, Turbo Streams, and Stimulus
- **Author:** David Colby | **URL:** https://colby.so/posts/infinite-scroll-with-turbo-streams-and-stimulus
- **Summary:** Post-Turbo-7.2 rewrite of the above, now using native GET Turbo Stream responses (`data-turbo-stream: ""`) instead of the "empty frame hack." A `_pager.html.erb` link carries `data: { turbo_stream: "", controller: "autoclick" }`; the controller's `index.turbo_stream.erb` uses `turbo_stream_action_tag` to append cards and replace the pager.
- **Code worth stealing:**
```erb
<%# app/views/cards/_pager.html.erb %>
<%= link_to("Load more cards", cards_path(page: pagy.next),
    data: { turbo_stream: "", controller: "autoclick" }) %>
```
```erb
<%# app/views/cards/index.turbo_stream.erb %>
<%= turbo_stream_action_tag("append", target: "cards", template: %(#{render @cards})) %>
<%= turbo_stream_action_tag("replace", target: "pager", template: %(#{render "pager", pagy: @pagy})) %>
```
- **Opinion / hot take:** "Rendering an empty Turbo Frame so it could be used to insert Turbo Stream actions into the page was odd... it always felt uncomfortable" — GET-request Turbo Streams (Turbo 7.2+) are a major DX improvement.

### Remotely loading tabbed content with Ruby on Rails and Hotwire
- **Author:** David Colby | **URL:** https://www.colby.so/posts/remotely-loading-tab-content-with-rails-and-hotwire
- **Summary:** Tabs implemented as ordinary links pointing at nested resource routes (`person_awards_path`, `person_credits_path`); each nested controller's `index` renders a partial containing a `turbo_frame_tag "details_tab"` with the same id, so clicking a tab link swaps only that frame's contents — no JS at all.
- **Code worth stealing:**
```ruby
resources :people do
  resources :awards, only: %i[index]
  resources :credits, only: %i[index]
end
```
```erb
<%# app/views/awards/_list.html.erb %>
<%= turbo_frame_tag "details_tab" do %>
  <%= render partial: "shared/tabs" %>
  <h3>Awards won by <%= person.name %></h3>
  ...
<% end %>
```
- **Opinion / hot take:** "Small teams and solo developers can use Rails + Hotwire to provide modern, highly-performant web applications quickly" without a JS framework.

### Toggling view layouts with Kredis, Turbo Frames, and Rails
- **Author:** David Colby | **URL:** https://colby.so/posts/toggling-view-layouts-with-kredis-and-rails
- **Summary:** Persists a user's list/card view preference in Redis via `kredis_hash :preferences` on the User model instead of a URL param (which resets on any link without it). Wraps the toggle-able region in a `turbo_frame_tag "players"` so switching views doesn't show cached/flashing content, and list-item "View" links carry `data-turbo-frame: "_top"` to break out.
- **Code worth stealing:**
```ruby
# Gemfile
gem "kredis"
```
```ruby
# app/models/user.rb
kredis_hash :preferences
```
```ruby
def index
  @players = Player.all
  current_user.preferences.update(view: params[:view]) if params[:view].present?
end
```
```erb
<%= turbo_frame_tag "players", class: "min-w-full mt-8" do %>
  <% if current_user.preferences[:view] == "card" %>
    <%= render @players, partial: "players/card", as: :player %>
  <% else %>
    <%= render @players %>
  <% end %>
<% end %>
```
- **Opinion / hot take:** URL params are insufficient for persistent UI preferences — "the layout will always fall back to the default list view when visiting `/players` without any URL parameters." Kredis + Turbo Frames avoids both stale state and flash-of-cached-content.

### Building a modal form with Turbo Stream GET requests and custom stream actions
- **Author:** David Colby | **URL:** https://colby.so/posts/building-modal-forms-with-turbo-streams
- **Summary:** See Forms section for full code. Demonstrates `data-turbo-stream=""` on a GET link to receive a Turbo Stream response directly (Turbo 7.2+), replacing the "empty frame" workaround, plus authoring a **custom Turbo Stream action** (`dispatch_event`) registered via `StreamActions.dispatch_event`.
- **Code worth stealing:**
```javascript
// app/javascript/custom_actions/dispatch_event.js
import { StreamActions } from '@hotwired/turbo'
StreamActions.dispatch_event = function() {
  const name = this.getAttribute('name')
  const event = new Event(name)
  window.dispatchEvent(event)
}
```
```ruby
# app/helpers/dispatch_event_helper.rb
module DispatchEventHelper
  def dispatch_event(name)
    turbo_stream_action_tag :dispatch_event, name: name
  end
end
Turbo::Streams::TagBuilder.prepend(DispatchEventHelper)
```
```erb
<%# app/views/cards/create.turbo_stream.erb %>
<%= turbo_stream.prepend "card-list", @card %>
<%= turbo_stream.dispatch_event "modalClose" %>
```
- **Opinion / hot take:** Custom stream actions enable "highly targeted DOM manipulation initiated from the server" — powerful but the author frames this specific example as more of a demo than a necessity (a native Turbo event would have sufficed).

---


### Building Basecamp project stacks with Hotwire ★
- **Author:** Nicklas Ramhöj Holtryd | **Date:** November 7, 2023 | **URL:** https://dev.37signals.com/building-basecamp-project-stacks-with-hotwire/
- **Summary:** The best 37signals worked example of Frames + Streams + Stimulus together, and of *progressively enhancing legacy JavaScript* rather than rewriting it. A modal driven by a Turbo Frame; the frame's contents are a collection partial; drag-and-drop handled by a small Stimulus controller that POSTs a position update and optimistically removes the element; the server responds with a Turbo Stream that replaces either the stack partial or the parent bucket partial depending on whether the drop formed a new stack. Inline editing of the stack name is a nested `turbo_frame_tag dom_id(record, :header)` containing a `form_with` plus a "Never mind" cancel link that just re-GETs the frame.
- **Code worth stealing:**
```erb
<!-- buckets/pins/positions/create.turbo_stream.erb -->
<%= turbo_stream.replace dom_id(@parent.bucket), partial: "stacks/stack",
      locals: { bucket: @stack.bucket } if should_form_new_stack? %>

<%= turbo_stream.replace dom_id(@stack), partial: "stacks/stack",
      locals: { bucket: @stack.bucket } if @stack %>
```
```javascript
// stack_controller.js
import { Controller } from "@hotwired/stimulus"
import { request } from "../helpers/request_helpers"

export default class extends Controller {
  static targets = [ "project" ]

  setupDraggedElement(event) {
    event.dataTransfer.setData("text/plain", event.target.id)
  }

  acceptDrop(event) {
    if (this.element === event.target) {
      const element = this.#getDraggedElement(event)
      this.#unstackProject(element)
    }
  }

  #getDraggedElement(event) {
    const draggedElementId = event.dataTransfer.getData("text/plain")
    return this.projectTargets.find(target => target.id === draggedElementId)
  }

  #unstackProject(element) {
    this.#postUpdate(element.dataset.url)
    element.remove()
  }

  #postUpdate(url) {
    const body = new FormData()
    body.append("parent_id", "root")
    body.append("position", "bottom")
    request.post(url, { body })
  }
}
```
```erb
<!-- stacks/show.html.erb — note the custom element wrapper + action on the container -->
<bc-modal id="stack_modal" data-controller="stack"
          data-action="drop->stack#acceptDrop">
  <%= render partial: "stacks/project", collection: @stack.buckets %>
</bc-modal>

<!-- stacks/_project.html.erb -->
<article data-stack-target="project"
         data-action="dragstart->stack#setupDraggedElement">
</article>

<!-- projects/index.html.erb — empty frame acts as a modal slot -->
<%= turbo_frame_tag :stack_modal %>

<!-- stacks/_stack.html.erb — link targets the modal frame -->
<%= link_to stack_path(bucket), data: { turbo_frame: :stack_modal } %>

<!-- stacks/edit.html.erb — inline edit inside a nested frame -->
<%= turbo_frame_tag dom_id(@bucket.stack, :header) do %>
  <%= form_with model: @bucket.stack, url: stack_path(@bucket) do |form| %>
    <%= form.text_field :name, required: true, maxlength: 100 %>
    <%= form.submit "Save" %>
    <%= link_to "Never mind", stack_path(@bucket) %>
  <% end %>
<% end %>
```
- **Opinion / hot take:** The pattern name to steal is "progressive enhancement of legacy systems" — Turbo Streams intercept the response and surgically update the DOM while Stimulus handles new interactions, with zero modification to the pre-existing JS.

---


### How to reuse the same page in different Turbo Frame flows ★
- **Author:** Radan Skorić | **Date:** May 28, 2024 (updated Jun 10, 2024) | **URL:** https://radan.dev/articles/reuse-same-page-in-multiple-frames
- **Summary:** Solves "the same page must load into two differently-named frames." Frame ids must be unique on a page, and Turbo demands the response contain a frame with the matching `id` or you get **Content missing** — so a hardcoded `turbo_frame_tag :popup_modal` blocks reuse. Two motivating cases: a login/registration/forgot-password flow that lives in a modal *and* as standalone pages; and a product-details flow that must work inside a left and a right comparison pane simultaneously. The bad fix is a query param (`?popup=true`, `?side=left`) you must thread through every link. The good fix: Turbo sends the requested frame id in the **`Turbo-Frame` request header**, exposed by turbo-rails as `turbo_frame_request_id` — so the template can echo it back.
- **Code worth stealing:**
```erb
<%# Not great: query parameter plumbing %>
<%= turbo_frame_tag (params[:popup] ? :popup_modal : :full_page) %>
<%= turbo_frame_tag (params[:side] || @product) %>

<%# Great: echo the requested frame id, fall back to the standalone id %>
<%= turbo_frame_tag (turbo_frame_request_id || :full_page) %>
<%= turbo_frame_tag (turbo_frame_request_id || @product) %>

<%# If you render MULTIPLE frames in one response and let Turbo pick, don't blindly
    echo — you'd emit duplicate ids. Validate against an allowlist instead: %>
<%= turbo_frame_tag (turbo_frame_request_id.in?(%w[left right]) ? turbo_frame_request_id : @product) %>
```
- **Gotcha:** `turbo_frame_request_id` returns a **String**, not a Symbol. Without Rails, read the `Turbo-Frame` header directly.

### How to refresh the full page when submitting a form inside a Turbo Frame? ★★
- **Author:** Radan Skorić | **Date:** Jun 11, 2024 (updated Oct 7, 2024) | **URL:** https://radan.dev/articles/update-full-page-on-form-in-frame-submit
- **Summary:** The definitive answer to Turbo's most-asked question (hotwired/turbo#257). He frames it as an audit of what "just slap a Turbo Frame on it" actually covers: full-page navigation ✅, tabs ✅, self-contained widgets like an image gallery ✅, inline editing in a list ✅ — **but "submitting a form shows errors OR modifies the full page" ❌**, because *which* of the two happens is decided dynamically on the server, and Turbo's targeting mechanisms are static markup. He read the entire issue thread and distilled five techniques with explicit "use when" rules.
- **Code worth stealing:**
```erb
<%# 1. target="_top" — simplest, but ALWAYS navigates the full page, so errors break.
       USE WHEN you know every submit will succeed. %>
<%= turbo_frame_tag :target_top, target: "_top" %>
```
```ruby
# 2. Emit a refresh stream action on success. The error path stays plain-HTML simple.
#    USE WHEN you need to show errors and the happy path returns to the same page.
def create
  @record = Record.create(record_params)
  if @record.valid?
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.refresh(request_id: nil) }
      format.html { redirect_to :index }
    end
  else
    render :new # Rely on the form rendering showing errors
  end
end
```
> **Why `request_id: nil`?** Turbo ignores refreshes originating from the current page's own request (to avoid a double refresh when your change also broadcasts over ActionCable). Here that's exactly what you *do* want, so you must clear the request id.

```javascript
// 3. A custom full-page redirect stream action.
//    USE WHEN you need errors AND the happy path goes to a DIFFERENT page.
Turbo.StreamActions.full_page_redirect = function() {
  document.location = this.getAttribute("target")
}
```
```ruby
respond_to do |format|
  format.turbo_stream do
    render turbo_stream: turbo_stream.action(:full_page_redirect, redirect_path)
  end
  format.html { redirect_to redirect_path }
end
```
```erb
<%# 4. turbo-visit-control meta tag on the DESTINATION page.
       Turbo fetches the page, sees the meta tag, abandons the frame update and
       does a full reload of the same URL — i.e. the page loads TWICE.
       USE WHEN the target page must always be a full page load (classic: login). %>
<% turbo_page_requires_reload %>
```
```erb
<%# 5. Don't use a Turbo Frame at all. Wrap the form in a plain div with an id;
       redirect normally on success, and use a replace stream to simulate a frame
       update only on error. Makes the HAPPY path identical to plain HTML. %>
<div id="<%= dom_id(record, "form") %>">
  <%= form_for record do |f| %>
    ...
  <% end %>
</div>
```
```ruby
if @record.valid?
  redirect_to :index
else
  respond_to do |format|
    format.turbo_stream do
      # replace the dom_id(record, "form") div with the re-rendered form + errors
    end
  end
end
```
- **Opinion / hot take:** The meta-observation is the useful part: techniques 1–4 keep the *sad* path (errors in the form) trivially simple and put the added complexity on the happy path. Technique 5 inverts that. Choose based on which path you'd rather keep boring.

### How to elegantly update other UI when a Turbo Frame is updated ★★
- **Author:** Radan Skorić | **Date:** Oct 1, 2025 | **URL:** https://radan.dev/articles/turbo-extraframe-updates
- **Summary:** Coins **"extraframe content"** — content physically outside a Turbo Frame but logically belonging to it (a counter, a title, a highlighted sidebar item). The technique keeps the logic 100% on the backend with no Stimulus controller, by combining two things: (a) render the sidebar *inside* the frame on frame requests, and (b) exploit the fact that **stream actions execute when rendered into ordinary HTML**. A single view helper switches between `content_for` (full page load) and `turbo_stream.replace(..., method: :morph)` (frame request). Using `method: :morph` is what keeps the sidebar's scroll position stable across clicks. Real example: the chapter sidebar on the web version of his *Master Hotwire* book.
- **Code worth stealing:**
```erb
<%# layout — a slot for the extraframe content %>
<body>
  <aside>
    <%= yield :sidebar %>
  </aside>
  <main>
    <%= yield %>
  </main>
</body>
```
```erb
<%# the page view — NOTE: the sidebar renders INSIDE the frame. This is critical:
    on a frame request only in-frame content enters the document, and the embedded
    stream action needs to land in the DOM to execute. %>
<%= turbo_frame_tag :chapter_content do %>
  <%= render 'sidebar', chapters: @chapters, chapter: @chapter %>

  <article>
    <h1><%= @chapter.full_title %></h1>
    <%= render_chapter(@chapter.content) %>
  </article>
<% end %>
```
```erb
<%# _sidebar.html.erb %>
<%= turbo_aware_content_for :sidebar do %>
  <nav id="sidebar">
    <ul>
      <% chapters.each do |chap| %>
        <li>
          <%= link_to chap.full_title,
                      chapter_path(chap),
                      class: "link #{'highlight' if chap == chapter}",
                      data_turbo_frame: :chapter_content
                      %>
        </li>
      <% end %>
    </ul>
  </nav>
<% end %>
```
```ruby
# the whole trick, in seven lines
def turbo_aware_content_for(name, &block)
  if turbo_frame_request?
    turbo_stream.replace(name, method: :morph, &block)
  else
    content_for(name, &block)
  end
end
```
- **Gotcha he flags:** the helper implicitly requires an element whose `id` matches the slot name (here `<nav id="sidebar">`). Better: have the helper generate the wrapper element itself, "By having the helper generate the wrapper, it's impossible to use it incorrectly."
- **Opinion / hot take:** The payoff argument is maintainability, not cleverness: when he later wanted the sidebar to also render the current chapter's subtitle list, the backend approach needed only a partial change, while "if we used the pure frontend solution, we'd now face some *not so trivial* changes."

### How to load a lazy loaded turbo frame a bit before it scrolls into view ★
- **Author:** Radan Skorić | **Date:** Sep 2, 2024 | **URL:** https://radan.dev/articles/load-lazy-loaded-frame-before-it-scrolls-in-view
- **Summary:** Turbo's `loading="lazy"` frames only start loading once visible, so there's always a visible delay. Turbo implements this with `AppearanceObserver` wrapping a plain `IntersectionObserver` constructed with **no options**. You can't patch Turbo, but you can attach your own `IntersectionObserver` with a `rootMargin` and then flip the frame's `loading` attribute to `eager` — Turbo's `FrameController` has a `loadingStyleChanged` handler that reacts to the attribute change and loads the frame. He also debunks the intuitive-but-wrong `rootMargin`: it grows the **root (the viewport)**, not the target, so to fire 1000px *before* a frame below you enters view, the value is `0px 0px 1000px 0px`, not `1000px 0px 0px 0px`.
- **Code worth stealing:**
```javascript
// app/javascript/controllers/prefetch_lazy_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.element.getAttribute("loading") == "lazy") {
      this.observer = new IntersectionObserver(this.intersect, {rootMargin: "0px 0px 1000px 0px"})
      this.observer.observe(this.element)
    }
  }

  disconnect() {
    // We want to be good citizens and clean up after ourselves.
    this.observer?.disconnect()
  }

  intersect = (entries) => {
    const lastEntry = entries.slice(-1)[0]
    if (lastEntry?.isIntersecting) {
      this.observer.unobserve(this.element) // We only need to do this once
      this.element.setAttribute("loading", "eager")
    }
  }
}
```
```erb
<%= turbo_frame_tag :awesome, src: url, loading: :lazy, data: {controller: "prefetch-lazy"} %>
```
- **Opinion / hot take:** The best articulation of Hotwire's core idea I found:
  > "I really like this as an example of how useful Hotwire's philosophy of treating HTML as the **state of the UI** and not just as *the rendering of the state*. We don't have to wade through some arcane Turbo calls but instead we can just modify the HTML and Turbo will adapt. Turbo does the hard work to allow us to have *a simpler mental model*."
  Naming note: he calls it `prefetch-lazy` as a nod to Turbo's hover link prefetching — same purpose, "making the user wait less." Pairs with infinite scrolling (see the Pagy guest article below).

---


### Build a (progressively enhanced) drawer component with Hotwire
- **Author:** Steve Polito | **Date:** January 28, 2025 | **URL:** https://thoughtbot.com/blog/hotwire-drawer
- **Summary:** Builds an animated slide-over drawer in three progressive-enhancement stages: (1) a server-rendered "faux drawer" using Rails **variants** (`edit.html+drawer.erb`) so the same controller action can render either a full page or a drawer fragment; (2) native **View Transitions API** (single `<meta name="view-transition" content="same-origin">` tag + `::view-transition-old/new` CSS) animates cross-page navigation; (3) a `turbo-frame` wraps the drawer so it can be inserted/removed without navigation, and a Stimulus controller using the `el-transition` library intercepts `turbo:before-frame-render` to animate the frame's enter/leave (since native view-transitions don't fire on Turbo Frame/Stream DOM mutations).
- **Code worth stealing:**
```ruby
# app/controllers/products_controller.rb
before_action :set_variant, only: %i[ new edit update create ]

def new
  request.variant = @variant
  @product = Product.new
end

def create
  @product = Product.new(product_params)
  if @product.save
    redirect_to products_path, notice: "Product was successfully created."
  else
    render :new, variants: @variant, status: :unprocessable_entity
  end
end

private

def set_variant
  @variant ||= :drawer if params[:variant] == "drawer"
end
```
```erb
<%# app/views/products/edit.html+drawer.erb %>
<%= render "drawer", title: "Edit product" do %>
  <%= render "form", product: @product %>
<% end %>
```
```css
::view-transition-old(backdrop) { animation: 0.4s ease-in both fade-out; }
::view-transition-new(backdrop) { animation: 0.4s ease-in both fade-in; }
::view-transition-old(panel) { animation: 0.4s ease-in both slide-out; }
::view-transition-new(panel) { animation: 0.4s ease-in both slide-in; }
#panel { view-transition-name: panel; }
#backdrop { view-transition-name: backdrop; }
```
```erb
<%# app/views/products/create.turbo_stream.erb %>
<turbo-stream action="refresh"></turbo-stream>
```
```javascript
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
    const { detail: { newFrame } } = event;
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
```erb
<%= turbo_frame_tag :drawer, data: {controller: "drawer", action: "turbo:before-frame-render->drawer#animate"} %>
```
- **Opinion / hot take:** Treats "pretend the drawer is a full page first, animate it later" as the correct order of operations — progressive enhancement isn't just a JS-off nicety, it's the actual build sequence.

### Conditionally render a Turbo Frame shared between multiple views
- **Author:** Steve Polito | **Date:** August 13, 2024 | **URL:** https://thoughtbot.com/blog/conditionally-render-turbo-frame
- **Summary:** Solves a real Turbo Frame footgun: a `_post` partial shared by `index` and `show` both wraps the same `turbo_frame_tag dom_id(post)`, so editing from the index accidentally re-renders the full show-style content into the index's frame after submit (because the frame ID must match on request and response, but the content differs by context). Two fixes given: the simple one is `redirect_back_or_to` so the response frame always matches whichever page issued the request. The more powerful one for genuinely different post-edit behavior per context: pass `variant: :inline` as a param, add `request.variant = @variant` in the controller, and create `edit.html+inline.erb`/`show.html+inline.erb` variant templates that each carry their own `turbo_frame_tag`, threading the variant through as a hidden field on the form so it survives the round trip.
- **Code worth stealing:**
```ruby
# app/controllers/posts_controller.rb
def update
  if @post.update(post_params)
    redirect_back_or_to post_url(@post), notice: "Post was successfully updated."
  else
    render :edit, status: :unprocessable_entity
  end
end
```
```erb
<!-- app/views/posts/_post.html.erb -->
<%= link_to "Edit", edit_post_path(post, variant: :inline) %>
```
```erb
# app/views/posts/edit.html+inline.erb
<% content_for :title, "Editing post" %>
<h1>Editing post</h1>
<%= turbo_frame_tag dom_id(@post) do %>
  <%= render "form", post: @post %>
  <%= link_to "Cancel", :back %>
<% end %>
```
```erb
<!-- app/views/posts/_form.html.erb -->
<% if params[:variant] == "inline" %>
  <%= hidden_field_tag :variant, "inline", readonly: true %>
<% end %>
```
```ruby
# app/controllers/posts_controller.rb
before_action :set_variant, only: %i[ show edit update ]

def show
  request.variant = @variant
end

def edit
  request.variant = @variant
end

def update
  if @post.update(post_params)
    redirect_to post_url(@post, variant: @variant), notice: "Post was successfully updated."
  else
    render :edit, status: :unprocessable_entity
  end
end

private

def set_variant
  @variant ||= :inline if params[:variant] == "inline"
end
```
- **Opinion / hot take:** Frames the constraint plainly: "a request made from within a turbo-frame must receive a response containing a corresponding turbo-frame of the same id" — most conditional-frame bugs trace back to violating this.

### Hotwire: Asynchronously loaded tooltips
- **Author:** Steve Polito | **Date:** January 26, 2022 | **URL:** https://thoughtbot.com/blog/hotwire-asynchronously-loaded-tooltips
- **Summary:** Builds hover tooltips that lazy-load via a nested `turbo-frame` with `loading="lazy"` (Intersection-Observer-backed, so the request only fires once the frame scrolls into view / is revealed), `target="_top"` so any link clicked inside the tooltip navigates the whole page rather than getting trapped in the tiny frame, and CSS `:hover`/`:focus` peer-selectors (`peer-hover:block`) to reveal the frame's `hidden` class — no JS at all for the show/hide interaction. ARIA (`aria-describedby`, `role="tooltip"`) wires it for accessibility.
- **Code worth stealing:**
```ruby
# config/routes.rb
resources :users do
  resource :tooltip, only: :show
end
```
```erb
<!-- app/views/tooltips/show.html.erb -->
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
<!-- app/views/users/_user.html.erb -->
<p class="relative">
  <%= link_to "Show this user", user, class: "peer", aria: { describedby: dom_id(user, :tooltip) } %>
  <turbo-frame id="<%= dom_id user, :tooltip %>" target="_top" role="tooltip"
               src="<%= user_tooltip_path(user, turbo_frame: dom_id(user, :tooltip)) %>"
               class="hidden absolute translate-y-[-150%] z-10
                      peer-hover:block peer-focus:block hover:block focus-within:block"
               loading="lazy"
  ></turbo-frame>
</p>
```
- **Opinion / hot take:** "There's a cost to each network request" — argues for defaulting to `loading="lazy"` on non-critical frames, and calls CSS peer/sibling selectors "an incredibly powerful yet under-utilized feature of CSS" for interactions people reach for JS to do.

### Hotwire: Typeahead searching
- **Author:** Sean Doyle | **Date:** September 17, 2021 | **URL:** https://thoughtbot.com/blog/hotwire-typeahead-searching
- **Summary:** Deep, incremental build of a full search-as-you-type combobox: starts from a plain GET search form/results page, wraps results in a `turbo-frame` targeted from the form (`data-turbo-frame`/`turbo_frame:` query param) for partial updates, uses HTML5 constraint validation (`pattern`, `required`) plus a Stimulus controller that intercepts the `invalid` event (captured) to suppress the native validation bubble and instead hide results via CSS. Adds full keyboard navigation via GitHub's `@github/combobox-nav` library wrapped in a `ComboboxController` (targets `input`/`list`, `start()`/`stop()` lifecycle tied to `focus`/`focusout`, `listTargetConnected()` restarts on Turbo Frame re-render). Finishes with search-as-you-type by wiring the form's `input` event to auto-click a hidden submit button, debounced 200ms via lodash's `debounce` loaded from Skypack.
- **Code worth stealing:**
```ruby
scope :containing, -> (query) { where <<~SQL, "%" + query + "%" }
  body ILIKE :query
SQL
```
```ruby
class SearchesController < ApplicationController
  def index
    @messages = Message.containing(params[:query])
  end
end
```
```erb
<form action="<%= searches_path(turbo_frame: "search_results") %>" data-turbo-frame="search_results" class="peer"
  data-controller="form" data-action="invalid->form#hideValidationMessage:capture input->form#submit">
  <label for="search_query">Query</label>
  <input id="search_query" name="query" type="search" pattern=".*\w+.*" required autocomplete="off"
    data-combobox-target="input" data-action="focus->combobox#start focusout->combobox#stop">
  <button data-form-target="submit">Search</button>
</form>
```
```javascript
// app/javascript/controllers/form_controller.js
import { Controller } from "@hotwired/stimulus"
import debounce from "https://cdn.skypack.dev/lodash.debounce"

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
// app/javascript/controllers/combobox_controller.js
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
```erb
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
```css
.empty\:hidden:empty                                { display: none; }
.peer:invalid ~ .peer-invalid\:hidden               { display: none; }
.aria-selected\:outline-black[aria-selected="true"] { outline: 2px dotted black; }
```
- **Opinion / hot take:** Explicitly avoids "JSON encoding or direct XMLHttpRequest/fetch calls," insisting the whole combobox be built from "semantically meaningful elements like form, input type='search', and mark" — a purist HTML-over-fetch stance.

### Tip: Lazy-loading content with Turbo Frames and skeleton loader
- **Author:** Matt Swanson | **Date:** Mar 30, 2021 | **URL:** https://boringrails.com/tips/turboframe-lazy-load-skeleton
- **Summary:** Short, focused tip on the core lazy-loading Turbo Frame mechanics: a `<turbo-frame src="...">` auto-fetches on page load and swaps its content for the matching frame in the response; `loading: :lazy` (vs `:eager`) additionally delays the fetch until the frame scrolls into view. Recommends replacing the default "Loading..." text with a Tailwind `animate-pulse` skeleton-screen placeholder to reduce layout jank. Critical gotcha called out explicitly: the frame's *response* view must NOT re-specify `src`/`loading` attributes on its own `turbo_frame_tag`, or you create an infinite fetch loop.
- **Code worth stealing:**
```erb
<%= turbo_frame_tag :feed, src: activity_feed_path, loading: :lazy do %>
  <div class="flex flex-col space-y-6">
    <% 10.times do %>
      <div class="animate-pulse flex space-x-4">
        <div class="rounded-full bg-gray-400 h-12 w-12"></div>
        <div class="flex-1 space-y-4 py-1">
          <div class="h-4 bg-gray-400 rounded w-3/4"></div>
          <div class="space-y-2">
            <div class="h-4 bg-gray-400 rounded"></div>
            <div class="h-4 bg-gray-400 rounded w-5/6"></div>
          </div>
        </div>
      </div>
    <% end %>
  </div>
<% end %>
```
```ruby
class ActivityFeedController < ApplicationControler
  def show
    @events = Current.user.activity.last(20)
  end
end
```
```erb
<!-- app/views/activity_feed/show.html.erb — no src/loading here, or infinite loop! -->
<%= turbo_frame_tag :feed do %>
  <%= render partial: "feed_item", collection: @events %>
<% end %>
```
- **Opinion / hot take:** "The Turbo Frame is a super-charged iFrame that doesn't make you cringe when you use it."

### The most underrated Rails helper: dom_id
- **Author:** Matt Swanson | **Date:** Jun 28, 2022 | **URL:** https://boringrails.com/articles/rails-dom-id-the-most-underrated-helper/
- **Summary:** Argues `dom_id` is quietly foundational to Hotwire because it establishes one canonical, collision-resistant convention for element IDs instead of ad-hoc string interpolation. Covers four concrete use cases: (1) clean `tag.div id: dom_id(@post, :comments)` builders; (2) deep-linking anchor tags/redirects via `anchor: dom_id(@comment)`, paired with CSS `:target` and `scroll-margin-top`; (3) `turbo_frame_tag` uses `dom_id` under the hood, so passing a record directly (`turbo_frame_tag @post`) or record+prefix keeps frame IDs collision-free, and `data: { turbo_frame: @comment }` targets a frame by record; (4) scoping Turbo Stream responses so `turbo_stream.erb` template IDs always match view IDs without manual string sync, and `turbo_stream.remove @comment` calls `dom_id(@comment)` internally.
- **Code worth stealing:**
```ruby
dom_id(Post.find(45))       # => "post_45"
dom_id(Post.new)            # => "new_post"
dom_id(Post.find(45), :edit) # => "edit_post_45"
dom_id(Post.new, :custom)    # => "custom_post"
```
```erb
<%= tag.div id: dom_id(@post, :comments), class: "flex flex-col divide-y" do %>
  <%= render @post.comments %>
<% end %>
```
```ruby
# app/controllers/comments_controller.rb — redirect + scroll to newly created record
class CommentsController < ApplicationController
  def create
    @post.comments.create!(comment_params)
    redirect_to posts_path(@post, anchor: dom_id(@comment))
  end
end
```
```ruby
turbo_frame_tag @post # => <turbo-frame id="post_123"></turbo-frame>
turbo_frame_tag dom_id(@post, :comments) # => <turbo-frame id="comments_post_123"></turbo-frame>
```
```erb
<%= turbo_frame_tag @comment, src: comment_path(@comment) %>

<!-- Elsewhere... -->
<%= link_to "Edit", edit_comment_path(@comment), data: { turbo_frame: @comment } %>
```
```erb
<!-- app/views/plans/quick_edit/update.turbo_stream.erb -->
<%= turbo_stream.replace dom_id(@plan, :title), partial: "plans/title" %>
<%= turbo_stream.replace dom_id(@plan, :notes), partial: "plans/notes" %>
<%= turbo_stream.replace dom_id(@plan, :assigned), partial: "plans/assigned" %>
```
```erb
<!-- app/views/comments/destroy.turbo_stream.erb -->
<!-- Calls `dom_id(@comment)` under the hood -->
<%= turbo_stream.remove @comment %>
```
- **Opinion / hot take:** "Who would have thought that a simple helper... would be such a useful concept that, more than a decade after first being introduced, it continues to prove helpful even on the newest and shiniest parts of Rails."

### Get Started with Hotwire in Your Ruby on Rails App
- **Site:** blog.appsignal.com | **Author:** Sapan Diwakar | **Date:** July 6, 2022 | **URL:** https://blog.appsignal.com/2022/07/06/get-started-with-hotwire-in-your-ruby-on-rails-app.html
- **Summary:** Despite the generic title, this has real recipes: infinite/endless scroll via a self-referencing lazy-loaded `turbo_frame_tag`; a "dynamic form" pattern where changing one select re-renders a dependent select by PUTting the whole form and getting back a `turbo_stream.replace`; and appending new comments live via `broadcast_prepend_later_to` with a `highlight: true` local that triggers a Stimulus controller to flash-and-fade the new element.
- **Code worth stealing:**
```erb
<%= turbo_frame_tag "posts_#{@posts.current_page}" do %>
  <%= render @posts %>
  <% unless @posts.last_page? %>
    <%= turbo_frame_tag "posts_#{@posts.next_page}", :src => path_to_next_page(@posts), :loading => "lazy" do %>
      <%= render "loading" %>
    <% end  %>
  <% end  %>
<% end %>
```
```javascript
// app/javascript/controllers/refresh_form_controller.js — dependent-select pattern
import { Controller } from "stimulus";
import { put } from "@rails/request.js";

export default class extends Controller {
  static targets = ["form"];
  refreshForm() {
    put(this.data.get("url"), {
      body: new FormData(this.formTarget),
      responseKind: "turbo-stream",
    });
  }
}
```
```ruby
# app/models/coment.rb
after_create_commit :stream
private
def stream
  broadcast_prepend_later_to(post, :comments, target: :comments, locals: { highlight: true })
end
```
```javascript
// highlight controller — flashes newly-broadcast elements
export default class extends Controller {
  connect() {
    this.element.classList.add("highlight");
    this.timeout = setTimeout(() => this.element.classList.remove("highlight"), 3000);
  }
  disconnect() {
    clearTimeout(this.timeout);
  }
}
```
- **Uniqueness note:** The dependent-select-refreshes-via-PUT-and-turbo-stream-replace pattern and the "pass a `highlight` local into a broadcast partial to flash new items" trick are both genuinely useful and not spelled out this cleanly elsewhere in the corpus.

### Build a Table Editor with Trix and Turbo Frames in Rails
- **Site:** blog.appsignal.com | **Author:** Julian Rubisch | **Date:** October 26, 2022 | **URL:** https://blog.appsignal.com/2022/10/26/build-a-table-editor-with-trix-and-turbo-frames-in-rails.html
- **Summary:** Builds an editable table as a custom ActionText attachment. A `Table` model implements `ActionText::Attachable` and `to_trix_content_attachment_partial_path`; a Stimulus controller inserts a `Trix.Attachment` into the editor by POSTing to create the record, then the attachment renders as a `turbo_frame_tag` whose cells are `contenteditable` divs PATCHing individual row/column/cell operations back to the server. Server-rendered HTML avoids ever serializing table state to JSON on the client.
- **Code worth stealing:**
```ruby
# app/models/action_text/table.rb
class ActionText::Table < ApplicationRecord
  include ActionText::Attachable
  attribute :content_type, :string, default: "text/html"

  def to_trix_content_attachment_partial_path
    "tables/editor"
  end
  def to_partial_path
    "tables/table"
  end
  def add_row(index = rows - 1)
    content << Array.new(columns, "")
  end
end
```
```erb
<%# app/views/tables/_editor.html.erb %>
<%= turbo_frame_tag "table_#{table.attachable_sgid}",
   data: {controller: "table-editor", table_editor_url_value: table_path(id: table.attachable_sgid)} do %>
  <table>
    <% table.content.each_with_index do |row, row_index| %>
      <tr>
        <% row.each_with_index do |column, column_index| %>
          <td>
            <div contenteditable
               data-action="input->table-editor#updateCell"
               data-row-index="<%= row_index %>"
               data-column-index="<%= column_index %>">
              <%= column %>
            </div>
          </td>
        <% end %>
      </tr>
    <% end %>
  </table>
<% end %>
```
```javascript
// app/javascript/controllers/trix_table_controller.js
import { Controller } from "@hotwired/stimulus";
import Trix from "trix";
import { post } from "@rails/request.js";

export default class extends Controller {
  static values = { url: String };
  async attachTable(event) {
    const response = await post(this.urlValue);
    if (response.ok) {
      const tableAttachment = await response.json;
      this.insertTable(tableAttachment);
    }
  }
  insertTable(tableAttachment) {
    this.attachment = new Trix.Attachment(tableAttachment);
    this.element.querySelector("trix-editor").editor.insertAttachment(this.attachment);
    this.element.focus();
  }
}
```
```javascript
// workaround: force-reload the Turbo Frame after Trix re-syncs its doc on submit,
// otherwise cell edits can get reverted
connect() {
  this.element.addEventListener("turbo:submit-end", (e) => {
    this.element.closest("turbo-frame").reload();
  });
}
```
- **Opinion / hot take:** Calls out a real Trix limitation: "Until Trix gains a Turbo-compatible interface, there's no way around" the re-sync-reverts-edits issue.
- **Uniqueness note:** Highly unique — nobody else covers building a custom ActionText attachment type as an editable Turbo Frame, including the specific Trix/Turbo Frame reload workaround.

### Hotwire Modals in Ruby on Rails with Stimulus and Turbo Frames
- **Site:** blog.appsignal.com | **Author:** Ayush Newatia | **Date:** February 21, 2024 | **URL:** https://blog.appsignal.com/2024/02/21/hotwire-modals-in-ruby-on-rails-with-stimulus-and-turbo-frames.html
- **Summary:** Part 1 of a 2-part accessible-modals series. Uses the native `<dialog>` element (`showModal()`/`close()`, `::backdrop` styling, `<form method="dialog">` for the close button) for free focus-trapping and Esc-to-dismiss. First shows a purely-client Stimulus `modal` controller that calls `showModal()` on a `data-modal-dialog-param` target; then a server-driven version where a global `turbo_frame_tag :remote_modal` sits in the layout, a link with `data: { turbo_frame: :remote_modal }` fetches a `<dialog data-controller="remote-modal">` partial, and a second tiny Stimulus controller calls `showModal()` on `connect()`.
- **Code worth stealing:**
```javascript
// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus";
export default class extends Controller {
  connect() {
    this.element.dataset.action = "modal#show";
  }
  show(event) {
    const dialog = document.getElementById(event.params.dialog);
    dialog.showModal();
  }
}
```
```erb
<button
  data-controller="modal"
  data-modal-dialog-param="contact_details_modal">
  Show contact details
</button>
<dialog id="contact_details_modal" aria-labelledby="modal_title"> ... </dialog>
```
```erb
<%# app/views/layouts/application.html.erb — global remote-modal mount point %>
<body>
  <%= yield %>
  <%= turbo_frame_tag :remote_modal %>
</body>
```
```erb
<%= link_to new_support_ticket_path, data: { turbo_frame: :remote_modal } do %>
  Show contact form
<% end %>
```
```javascript
// app/javascript/controllers/remote_modal_controller.js
import { Controller } from "@hotwired/stimulus";
export default class extends Controller {
  connect() {
    this.element.showModal();
  }
}
```
```scss
dialog {
  width: 80vw;
  margin: auto;
  &::backdrop {
    background: red;
    opacity: 0.2;
  }
}
```
- **Opinion / hot take:** Argues the `<dialog>` element "gives us most of [accessibility] for free" and is "ideal in most cases" given ~94% global browser support.
- **Uniqueness note:** This exact pattern (global `turbo_frame_tag` in the layout + `data-turbo-frame` link for remote modals) isn't spelled out elsewhere in the corpus.

### Full-Text Search for Ruby on Rails with Litesearch
- **Site:** blog.appsignal.com | **Author:** Julian Rubisch | **Date:** February 14, 2024 | **URL:** https://blog.appsignal.com/2024/02/14/full-text-search-for-ruby-on-rails-with-litesearch.html
- **Summary:** Turbo is a supporting player here (article is primarily about the Litesearch gem), but the live-search wiring is a clean, minimal pattern: a `turbo_frame_tag` wraps the results grid, a plain `keyup` listener rewrites the frame's `src` attribute to trigger Turbo's native frame-reload-on-`src`-change behavior (no Stimulus needed), and a `turbo:before-frame-render` listener post-processes the incoming frame to wrap matched terms in `<em>`.
- **Code worth stealing:**
```erb
<%# app/views/prompts/index.html.erb %>
<%= turbo_frame_tag :prompts, class: "grid" do %>
  <% @prompts.each do |prompt| %>
    <%= link_to prompt do %>
      <%= render "index", prompt: prompt %>
    <% end %>
  <% end %>
<% end %>
```
```javascript
// app/javascript/application.js — live search by rewriting the frame's src
document
  .querySelector("sl-input[name=search]")
  .addEventListener("keyup", (event) => {
    document.querySelector("#prompts").src =
      `/prompts?query=${encodeURIComponent(event.target.value)}`;
  });
```
```javascript
// highlight matched terms before the frame renders
document
  .querySelector("turbo-frame#prompts")
  .addEventListener("turbo:before-frame-render", (event) => {
    // wrap search terms in <em> tags before display
  });
```
- **Uniqueness note:** The `turbo:before-frame-render` event for intercepting/mutating frame content before it's painted is a genuinely underused technique not called out elsewhere in this corpus.

### Using TurboStream with the Fetch API
- **Author:** Sam Ruby | **Date:** Sep 8, 2022 | **URL:** https://fly.io/ruby-dispatch/turbostream-fetch/
- **Summary:** Real production pattern (from Ruby's "Showcase" ballroom-competition scheduling app) for dynamic dependent-select forms: a Stimulus controller intercepts a `<select>` change, does its own `fetch()` POST (not a form submit) carrying the CSRF token by hand, and pipes the raw response text into `Turbo.renderStreamMessage()` — letting you drive Turbo Stream updates from arbitrary JS-triggered events (drag/drop, autocomplete, etc.), not just form submits or ActionCable pushes. The server side is a normal `turbo_stream.replace` responder rendering a shared partial.
- **Code worth stealing:**
```erb
<%# app/views/people/_form.html.erb %>
<%= form_with(model: person, data: { controller: "person", id: person.id }) do |form| %>
  <div>
    <%= form.label :type %>
    <%= form.select :type, @types, {},
      'data-person-target' => 'type',
      'data-action' => 'person#setType',
      'data-url' => type_people_path %>
  </div>
  <%= render partial: 'package', locals: { person: person } %>
<% end %>
```
```erb
<%# app/views/people/_package.html.erb %>
<%= turbo_frame_tag('package-select') do %>
  <% unless @packages.empty? %>
    <%= label_tag :person_package_id, 'Package' %>
    <%= select_tag 'person[package_id]',
       options_for_select(@packages, @person.package_id || '') %>
  <% end %>
<% end %>
```
```javascript
// app/javascript/controllers/person_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="person"
export default class extends Controller {
  static targets = ['studio'];

  connect() {
    this.id = JSON.parse(this.element.dataset.id);
    this.token = document.querySelector('meta[name="csrf-token"]').content;
  }

  setType(event) {
    fetch(event.target.getAttribute('data-url'), {
      method: 'POST',
      headers: {
        'X-CSRF-Token': this.token,
        'Content-Type': 'application/json'
      },
      credentials: 'same-origin',
      body: JSON.stringify({
       id: this.id,
       type: event.target.value,
       studio_id: this.studioTarget.value
      })
    }).then(response => response.text())
    .then(html => Turbo.renderStreamMessage(html));
  }
}
```
```ruby
# app/controllers/people_controller.rb
def post_type
  @person = Person.find_by_id(params[:id]) || Person.new
  @person.studio = Studio.find(params[:studio_id])
  @person.type = params[:type]

  selections

  respond_to do |format|
    format.turbo_stream {
      render turbo_stream: turbo_stream.replace('package-select',
        render_to_string(partial: 'package'))
    }
    format.html { redirect_to people_url }
  end
end
```
- **Opinion / hot take:** Documents two "obscure" API corners explicitly: extracting the CSRF token manually for non-form `fetch` calls, and `Turbo.renderStreamMessage(streamActionHTML)` as the sanctioned way to apply a stream response that didn't arrive via SSE/WebSocket/form-submit MIME handling.

---

---

## Turbo Streams patterns


*(see also "Hotwire: Reactive Rails with no JavaScript?" above, and "The Hotwire-Rails summit" below)*

### The future of full-stack Rails II: Turbo View Transitions
- **Authors:** Vladimir Dementyev, Travis Turner | **Date:** October 23, 2023 | **URL:** https://evilmartians.com/chronicles/the-future-of-full-stack-rails-turbo-view-transitions
- **Summary:** Applies the browser View Transitions API to Turbo Drive navigations and Turbo Stream updates. Key insight: View Transitions animate *screenshots* of old/new page states, not DOM elements directly, which is why it works across full-page Turbo Drive swaps (Chrome-only multi-page support, must be manually enabled). Introduces the `turbo-view-transitions` library and its `data-turbo-transition` attribute to auto-assign unique `view-transition-name` values only to elements present in both old and new DOM (avoiding transition errors), plus a parallel `data-turbo-stream-transition` attribute + `turbo:before-stream-render` hook for animating individual Turbo Stream updates.
- **Code worth stealing:**
```js
document.addEventListener("turbo:before-render", (event) => {
  if (document.startViewTransition) {
    event.detail.render = (prevEl, newEl) => {
      morphRender(prevEl, newEl);
    };
    event.preventDefault();
    document.startViewTransition(() => {
      event.detail.resume();
    });
  }
});
```
```css
::view-transition-new(cover) {
  animation: 300ms ease-in 0ms both shake;
}
```
- **Opinion / hot take:** "Hotwire's flexibility allows developers to implement emerging web technologies before official framework support arrives" — positions Hotwire's event-hook architecture (not just its defaults) as the actual long-term value proposition.

### The Hotwire-Rails summit, or interactive multi-step forms at peak UX
- **Authors:** Vladimir Dementyev, Travis Turner | **Date:** June 24, 2025 | **URL:** https://evilmartians.com/chronicles/hotwire-rails-summit-interactive-multi-step-forms-peak-ux
- **Summary:** Case study building a multi-step wizard form (SumIt's custom-report builder) entirely in Hotwire instead of reaching for React. Key techniques: a single form object encapsulating all wizard steps/state (kept swappable/decoupled from the controller interface); switching from full-partial replacement to DOM morphing (`method: "morph"` on `turbo_stream.replace`) because replace felt "laggish"; a custom `data-turbo-morph-permanent-attrs` attribute + `turbo:before-morph-attribute` listener to protect specific attributes (not whole nodes) from being clobbered by morph, fixing incompatibilities with third-party Stimulus controllers that mutate their own attributes; faking nested forms (illegal in HTML) via `button_tag name:` on the submit button read server-side to know which sub-form was submitted; directional page-transition animations driven by the View Transitions API where the *server* (form object) decides the transition direction/name based on which wizard action was taken.
- **Code worth stealing:**
```ruby
def update
  @report_form = CustomReportForm.with(report:).from(params.require(:report))

  if @report_form.save
    redirect_to custom_report_path(report)
  else
    render :new, status: (@report_form.errors.none? ? :created : :unprocessable_entity)
  end
end
```
```erb
<%= turbo_stream.replace :reporting_custom_wizard, method: "morph" do %>
  <%= render "form", report_form: @report_form %>
<% end %>
```
```js
// Protect specific attributes (not whole elements) from being overwritten during morph
addEventListener("turbo:before-morph-attribute", (event) => {
  if (!event.target.dataset.turboMorphPermanentAttrs) return;

  const { attributeName } = event.detail;

  const regex = event.target._permanentAttrsRegex ||=
    new RegExp(`\\b(${event.target.dataset.turboMorphPermanentAttrs.split(/\s+/).join('|')})\\b`);
  if (regex.test(attributeName)) {
    event.preventDefault();
  }
});
```
```erb
<!-- Faking a "nested form" via button name/value read server-side -->
<%= form.fields_for :new_previous_interval, allow_method_names_outside_object: true do |f| %>
  <%= f.number_field :count, required: true, value: 1, min: 1 %>
  <%= f.select :period, available_periods, {include_blank: false} %>
  <%= button_tag name: "#{form.object_name}[new_interval_type]", value: "previous" do %>
    <%= render_svg("icons/plus") %>
    Add
  <% end %>
<% end %>
```
```js
// Stimulus controller choosing the view-transition name based on which wizard button was pressed
handleSubmit(event: SubmitEvent) {
  const button = event.submitter as HTMLButtonElement;
  if (!this.hasTransitionTarget) return;

  const el = this.transitionTarget;

  if (button.value === "back") {
    el.dataset.turboStreamTransition = "wizard-back";
  } else if (button.value === "autosubmit") {
    delete el.dataset.turboStreamTransition;
  } else {
    el.dataset.turboStreamTransition = "wizard";
  }
}
```
```ruby
class CustomReportForm < ApplicationForm
  attribute :name
  attribute :description
  attribute :new_period_interval
  attribute :new_previous_interval
  attribute :new_fixed_interval
  attribute :new_interval_type

  def build_new_interval
    case new_interval_type
    when "period"
      intervals << CustomReport::Interval::Period.build(year: new_period_interval[:year], period: new_period_interval[:period], breakdown: new_period_interval[:breakdown]).to_params
    when "previous"
      intervals << CustomReport::Interval::Previous.build(count: new_previous_interval[:count].to_i, period: new_previous_interval[:period]).to_params
    when "fixed"
      intervals << CustomReport::Interval::Fixed.build(start_date: new_fixed_interval[:start_date], end_date: new_fixed_interval[:end_date], name: new_fixed_interval[:name]).to_params
    end
  end
end
```
```ruby
def view_transition_name
  case report_form.wizard_action
  when "autosubmit" then "none"
  when "back" then "wizard-back"
  else "wizard"
  end
end
```
- **Opinion / hot take:** "Aligning with a project's practices and tools should play a decisive role in choosing the right tool for the job" — explicit pushback against reflexively reaching for React for anything interactive; also notes the architecture keeps the door open to switching to Inertia later without touching the backend.


### Simple Declarative Presence for Hotwire apps with AnyCable
- **Authors:** Irina Nazarova, Vladimir Dementyev, Travis Turner | **Date:** March 18, 2025 | **URL:** https://evilmartians.com/chronicles/simple-declarative-presence-for-hotwire-apps-with-anycable
- **Summary:** Zero-imperative-JS presence tracking (Slack-style online dots, Google-Docs-style "who's viewing") via a single custom element, `<turbo-cable-presence-source>`, shipped by `@anycable/turbo-stream`. It auto-subscribes to a signed AnyCable stream and appends/removes a Turbo Stream template for each joining/leaving user; a `presence-id` attribute identifies the current session, an optional `ignore-self` attribute excludes the current user from their own list, and `data-presence-counter`-style elements can be live-updated with a count. Requires AnyCable server v1.6+, the `@anycable/web` JS client (in place of stock Action Cable), and `@anycable/turbo-stream`.
- **Code worth stealing:**
```erb
<% # locals: (post:, user: current_user) %>
<turbo-cable-presence-source
  signed-stream-name="<%= signed_stream_name([post, :presence]) %>"
  presence-id="<%= dom_id(user, :presence) %>"
>
  <h3>Online Users</h3>
  <!-- Users will be appended here -->

  <!-- Template for how each user should be rendered -->
  <template>
    <%= turbo_stream.append dom_id(post, :presence) do %>
      👤 @<%= user.username %>
    <% end %>
  </template>
</turbo-cable-presence-source>
```
```erb
<!-- ignore-self: exclude the current user from their own presence list -->
<turbo-cable-presence-source
  signed-stream-name="<%= signed_stream_name([post, :presence]) %>"
  presence-id="<%= dom_id(user, :presence) %>"
  ignore-self
>
  <!-- same contents -->
</turbo-cable-presence-source>
```
```js
// Client setup — swap stock ActionCable consumer for the AnyCable web client + presence plugin
import "@hotwired/turbo"

import { start } from "@anycable/turbo-stream"
import { createCable } from "@anycable/web"

const cable = createCable({ protocol: 'actioncable-v1-ext-json' })

start(cable, { presence: true })
```
- **Opinion / hot take:** "Implementing this feature becomes as straightforward as dropping a `<turbo-cable-presence-source>` tag on the page" — presented as proof that real-time UI features don't require hand-rolled Stimulus + ActionCable channel code once AnyCable + Turbo Streams are combined declaratively.

### AnyCable, Rails, and the pitfalls of LLM-streaming
- **Authors:** Vladimir Dementyev, Travis Turner | **Date:** December 18, 2025 | **URL:** https://evilmartians.com/chronicles/anycable-rails-and-the-pitfalls-of-llm-streaming
- **Summary:** Documents concrete failure modes of streaming LLM output over Turbo Streams via stock Action Cable, using a demo app "Proposer" (Rails 8.1 + Hotwire + RubyLLM). Problem 1: **message ordering** — Action Cable's default thread-pool broadcaster (4 threads) delivers chunks out of order under load, causing visible "UI hallucinations" (text arriving scrambled); mitigations discussed: switch `broadcast_append_to`→`broadcast_update_to` (wasteful), throttle/batch broadcasts (~100ms, still breaks under load), use faster pub/sub (Redis vs. Solid Cable, still not guaranteed), or Action Cable Next / Async Cable's "fastlane" broadcast mode. Problem 2: **network reliability** — Action Cable is only "at-most-once" delivery and doesn't replay missed messages on reconnect, so chunks sent while a client is briefly disconnected are silently lost. **Fix: AnyCable** natively gives both ordering and "at-least-once" delivery (messages are stored as position-stamped logs — in-memory for single install, Redis Streams for AnyCable Pro clusters — and the client library auto-catches-up from last-seen position on reconnect, or can request historical messages on initial subscribe). Also flags the emerging "Durable Streams" HTTP protocol (from ElectricSQL) as a future direction AnyCable is adopting for its read side.
- **Code worth stealing:**
```erb
<%= turbo_stream_from "chat_42" %>
Thinking...
```
```ruby
RubyLLM.chat.ask("What are the pitfalls of real-time HTTP transports?") do |chunk|
  Turbo::StreamsChannel.broadcast_append_to("chat_42", target: "chat", html: chunk.content)
end
```
```ruby
# Proposer demo — streaming one field of an AI-generated proposal via Turbo Streams
def generate_field(id, prompt)
  response = chat.ask(prompt) do |chunk|
    next if chunk.content.blank?

    Turbo::StreamsChannel.broadcast_append_to(
      [proposal, field],
      target: dom_id(proposal, field),
      html: chunk.content
    )
  end

  proposal.update!(id => response.content)
end
```
```sh
# Fixing ordering/delivery guarantees: swap in AnyCable, app code is unchanged
bundle add anycable-rails
bin/rails g anycable:setup
```
- **Opinion / hot take:** "Action Cable uses thread pools to distribute broadcast work... when you broadcast, say, 100 messages to the same client in a row, 4 Ruby threads pick them up and are being transmitted to the client concurrently" — a direct, blunt explanation of *why* naive Turbo Stream + LLM streaming breaks, not just that it does. Demo repo: https://github.com/palkan/proposer


### Turbo Streams on Rails
- **Author:** David Colby | **URL:** https://www.colby.so/posts/turbo-streams-on-rails
- **Summary:** Reference post walking from raw `<turbo-stream>` markup through `format.turbo_stream` conventions, inline `render turbo_stream:` (single and array-of-streams), model broadcasting (`broadcast_append_to`, custom `target:`/`partial:`), `_later` background-job variants, and the "magic" `broadcasts`/`broadcasts_to` shorthand — which the author is skeptical of.
- **Code worth stealing:**
```erb
<turbo-stream action="action_to_take" target="element_to_update">
  <template><div id="element_to_update">...</div></template>
</turbo-stream>
```
```ruby
format.turbo_stream do
  render turbo_stream: [
    turbo_stream.replace('players_form', partial: 'new_player'),
    turbo_stream.append('players', partial: 'player', locals: { player: @player })
  ]
end
```
```ruby
# app/models/player.rb
after_create_commit { broadcast_append_later_to('players') }
```
```ruby
# "magic" shorthand — author is skeptical of these
broadcasts_to ->(_) { 'players' }
broadcasts
```
```ruby
belongs_to :team
after_create_commit { broadcast_append_later_to(team) }
after_destroy_commit { broadcast_remove_to(team) }
```
- **Opinion / hot take:** Prefer `_later` variants: "Since we want everything to be fast, not slow, we'll use `broadcast_action_later_to`." Skeptical of magic methods like `broadcasts`/`broadcasts_to`: they "often do not add much value since they rely so much on magical naming convention" — prefers explicit forms. Always scope channels (e.g. to a `team`) to avoid cross-tenant leaks. Debugging is hard because a stream silently no-ops when the target element doesn't exist on the page.

### Turbo Rails 101: Building a todo app with Turbo
- **Author:** David Colby | **URL:** https://colby.so/posts/turbo-rails-101-todo-list
- **Summary:** End-to-end todo app combining Turbo Streams (create/update/destroy via `dom_id`-keyed containers) with Turbo Frames (inline edit-in-place), a status enum, a dedicated `change_status` member route/action, and view-based filtering via `params[:status]` inside a tabbed `turbo_frame_tag "todos-container"`.
- **Code worth stealing:**
```ruby
# app/models/todo.rb
validates_presence_of :name
enum status: { incomplete: 0, complete: 1 }
```
```erb
<%# app/views/todos/_todo.html.erb %>
<li id="<%= "#{dom_id(todo)}_container" %>">
  <%= turbo_frame_tag dom_id(todo) do %>
    <%= link_to todo.name, edit_todo_path(todo) %>
  <% end %>
</li>
```
```erb
<%# app/views/todos/create.turbo_stream.erb %>
<%= turbo_stream.prepend "todos" do %><%= render "todo", todo: @todo %><% end %>
<%= turbo_stream.replace "#{dom_id(Todo.new)}_form" do %><%= render "form", todo: Todo.new %><% end %>
```
```ruby
# config/routes.rb
resources :todos do
  patch :change_status, on: :member
end
```
```ruby
def change_status
  @todo.update(status: todo_params[:status])
  respond_to do |format|
    format.turbo_stream { render turbo_stream: turbo_stream.remove("#{helpers.dom_id(@todo)}_container") }
    format.html { redirect_to todos_path, notice: "Updated todo status." }
  end
end
```
- **Opinion / hot take:** "Turbo Streams target elements in the DOM by id... any element with an id can be targeted by a Turbo Stream, not just Turbo Frame elements" — challenges the common misconception that Streams require Frames.

### Building a modal form with Turbo Stream GET requests and custom stream actions
(See Turbo Frames section above for full entry and code — cross-referenced here as a core Streams technique: GET-triggered Turbo Streams via `data-turbo-stream=""`.)

### Conditional rendering with Turbo Stream broadcasts
- **Author:** David Colby | **URL:** https://colby.so/posts/conditional-rendering-with-turbo-stream-broadcasts
- **Summary:** Solves the problem that model-level `broadcast_*` callbacks have no request context, so `current_user`/session data is unavailable inside the broadcast partial. Workaround: broadcast a lightweight placeholder frame with a `src:` pointing back to a real controller action (which does have session access), forcing a secondary HTTP round-trip per client to render the truly personalized content.
- **Code worth stealing:**
```ruby
# app/models/spy.rb
after_create_commit { broadcast_append_to('spies', target: 'spies', partial: 'spies/spy_frame', locals: { agent: self }) }
```
```erb
<%# app/views/spies/_spy_frame.html.erb %>
<%= turbo_frame_tag spy, src: spy_path(spy, frame: true) %>
```
```ruby
def show
  if request.headers["turbo-frame"]
    render partial: 'spy', locals: { spy: @spy }
  else
    render 'show'
  end
end
```
```erb
<%# app/views/spies/_spy.html.erb %>
<%= turbo_frame_tag spy do %>
  <div><%= spy.name %> | Current mission: <%= secret_clearance ? spy.mission : "Classified" %></div>
<% end %>
```
- **Opinion / hot take:** "Without that request context, variables like `current_user` will always be undefined." Explicit tradeoff warning: "We're gaining a lot of flexibility in return for additional load on our server... not every problem related to session variables and broadcasts is a nail" — consider simpler alternatives first.

### User notifications with Rails, Noticed, and Hotwire
- **Author:** David Colby | **URL:** https://colby.so/posts/user-notifications-with-rails-noticed-and-hotwire
- **Summary:** Combines the `noticed` gem with Turbo Streams: a `Notification` model (via `Noticed::Model`) broadcasts itself (`broadcast_append_later_to(recipient, :notifications, target: 'notifications-list', partial: ...)`) polymorphically to whichever `recipient` it belongs to, subscribed to per-user via `turbo_stream_from current_user, :notifications`.
- **Code worth stealing:**
```ruby
# app/notifications/message_notification.rb
class MessageNotification < Noticed::Base
  deliver_by :database
  param :message
  def message; params[:message].content; end
end
```
```ruby
# app/models/message.rb
after_create_commit :notify_user
def notify_user
  MessageNotification.with(message: self).deliver_later(user)
end
```
```ruby
# app/models/notification.rb
include Noticed::Model
belongs_to :recipient, polymorphic: true
after_create_commit :broadcast_to_recipient
def broadcast_to_recipient
  broadcast_append_later_to(recipient, :notifications, target: 'notifications-list',
    partial: 'notifications/notification', locals: { notification: self })
end
```
```erb
<%= turbo_stream_from current_user, :notifications %>
<%= turbo_frame_tag "notifications", src: notifications_path %>
```

### Rendering view components with Turbo Stream broadcasts
- **Author:** David Colby | **URL:** https://colby.so/posts/rendering-view-components-with-turbo-stream-broadcasts
- **Summary:** Shows rendering a `ViewComponent` (not a partial) inside a model broadcast callback via `ApplicationController.render(SpyComponent.new(spy: self))` passed to the `html:` option added to turbo-rails broadcast methods.
- **Code worth stealing:**
```ruby
# app/models/spy.rb
def append_new_record
  broadcast_append_to('spies', html: ApplicationController.render(SpyComponent.new(spy: self)))
end
```
```ruby
class SpyComponent < ViewComponent::Base
  def initialize(spy:); @spy = spy; end
end
```
- **Opinion / hot take:** "Using `ApplicationController.render` to render a view_component isn't officially sanctioned" — flagged as a workaround pending official ViewComponent/Turbo integration.

### Turbo Streams and security / Real-time updates (hotrails.dev)
See Turbo Rails Tutorial Chapters 5 & 6 above for the canonical `broadcasts_to`/scoped-channel treatment.

---


### Versatile feature of Turbo: stream actions inside regular HTML ★★
- **Author:** Radan Skorić | **Date:** May 14, 2024 (updated Jan 8, 2025) | **URL:** https://radan.dev/articles/stream-actions-inside-regular-html
- **Summary:** A `<turbo-stream>` element executes **anywhere it lands in the DOM** — not just in a `text/vnd.turbo-stream.html` form response or a WebSocket message. Radan discovered the behavior was real but undocumented, then wrote the test PR (hotwired/turbo#1263) and the docs PR (hotwired/turbo-site#192); both merged, so it is now official: https://turbo.hotwired.dev/reference/streams#stream-elements-inside-html
  **Why it works:** `<turbo-stream>` is a custom element (`customElements.define("turbo-stream", StreamElement)`). `StreamElement#connectedCallback` interprets and executes the action instead of rendering, then removes the tag from the DOM. So *anything* that attaches the element to the document triggers it — including the initial page HTML. When the docs say Turbo "attaches" stream elements, all that means is Turbo inserts them into the DOM and lets the browser fire `connectedCallback`.
  **Where it works:** anywhere in the initial page HTML; inside a Turbo Frame response **as long as it is inside the frame tag** (content outside the frame never enters the document); anywhere JS injects one; and even nested inside content rendered by another stream action. It works with Turbo Drive disabled.
- **Code worth stealing:**
```html
<!-- Minimal proof, no Rails involved -->
<html>
  <head>
    <script src="https://unpkg.com/@hotwired/turbo"></script>
  </head>
  <body>
    <turbo-stream action="append" target="list">
      <template>
        <li>list element</li>
      </template>
    </turbo-stream>
    This list has an element added via the stream action:
    <ul id="list">
    </ul>
  </body>
</html>
```
```javascript
// If you invoke a CUSTOM action from initial page load, you MUST define it on
// StreamActions directly. The turbo:before-stream-render approach in the docs
// will NOT work, because the tag can be rendered before the listener attaches.
import { StreamActions } from "@hotwired/turbo"

// <turbo-stream action="log" message="Hello, world"></turbo-stream>
StreamActions.log = function () {
  console.log(this.getAttribute("message"))
}
```
- **Use cases he names:** side effects alongside a Turbo Frame response (update a counter outside the frame) without refactoring the whole flow to streams; **updating multiple parts of the page after a GET link** — Turbo will not process a stream *response* to a GET, but you can embed stream elements in the ordinary HTML response and achieve the same thing; and **eliminating inline `<script>` tags in legacy apps** — replace "run this JS on load" with a custom stream action, which is cleaner and unlocks a `script-src` CSP without `unsafe-inline`.
- **Opinion / hot take:** "Think of it as *a backup tool* to reach for when more direct Turbo approaches don't work or become convoluted." And: "Ruby and Rails are all about sharp tools given to you to use wisely. This is another one."

### When broadcasting a Turbo refresh is not enough: faster UX with versioned immediate updates ★★
- **Author:** Radan Skorić | **Date:** Jul 15, 2026 | **URL:** https://radan.dev/articles/turbo-versioned-updates
- **Real-world source:** his multiplayer game https://github.com/radanskoric/minesvshumanity/
- **Summary:** The most advanced real-time recipe in the corpus. Starts by fairly stating why `broadcasts_refreshes` + `turbo_stream_from` is the right default — 3 benefits: trivial to implement; **each user gets the page rendered in their own session, so user-specific content just works**; and it is race-condition-proof because the last refresh always re-fetches current state, so **"It's impossible to render a stale state."** Then the 3 downsides that bite on low-latency collaborative UIs: an extra round trip per client (the refresh action carries no data); **every connected client fires an HTTP request simultaneously** (thundering herd); and turbo-rails debounces broadcasts by 0.5s.
  Fix in two halves. **Half 1 — broadcast the HTML directly** with `broadcast_replace_to` (kills round trip + herd), then bypass the debouncer by scheduling `Turbo::Streams::BroadcastStreamJob` yourself from the controller (kills the 0.5s delay). **Half 2 —** you've now reintroduced the race condition (job order isn't guaranteed across workers, so a client can receive a newer update before an older one and end up stale), so add a **version number** to the payload and a custom `versioned_replace` stream action that applies the replace only if the incoming version is greater than what's rendered. For the version, use a natural counter, or add `lock_version` via **Active Record optimistic locking** — "Even if you don't actually need optimistic locking, it's perfectly OK to introduce it just to get a robust version number" — and use `touch:` on associations so child changes bump the parent's version.
- **Code worth stealing:**
```ruby
# Step 1: send HTML instead of a bare refresh — no extra round trip, no request herd
after_update_commit -> { broadcast_replace_to self, partial: "games/game", locals: { game: game } }
```
```ruby
# Step 2: bypass turbo-rails' 0.5s debouncer by scheduling the job yourself.
# Best placed in the controller.
action = turbo_stream.replace game, partial: "games/game", locals: { game: game }
Turbo::Streams::BroadcastStreamJob.perform_later game, content: action
```
```javascript
// Step 3: a custom stream action that rejects stale payloads.
// Requires data-version on both the payload's root element and the target element.
Turbo.StreamActions.versioned_replace = function () {
  let payloadVersion = parseInt(this.templateContent.children[0].dataset.version)
  let pageVersion = parseInt(this.targetElements[0].dataset.version)

  if (payloadVersion > pageVersion) {
    Turbo.StreamActions.replace.bind(this)()
  }
}
```
- **When to reach for it:** live dashboards with shared state, collaborative editors, multiplayer games, collaborative kanban, "any application with a critical, time-sensitive UI that requires minimal latency."

### Turbo 7.2: A guide to Custom Turbo Stream Actions ★
- **Author:** Marco Roth | **Date:** Oct 5, 2022 | **URL:** https://marcoroth.dev/posts/guide-to-custom-turbo-stream-actions
- **Summary:** The canonical end-to-end tutorial for custom stream actions, covering **both** halves — the JS action and a first-class Ruby helper so you can write `turbo_stream.toast(...)` anywhere `turbo_stream` works. Turbo ships 7 built-in actions (`after`, `append`, `before`, `prepend`, `remove`, `replace`, `update`); custom actions cover everything else. Requires Turbo ≥ 7.2 / turbo-rails ≥ 1.3.0. Two gotchas he calls out: you **must** use `function() {}` not an arrow function, because arrows bind `this` lexically; and inside the action `this` is the `StreamElement` instance (the actual `<turbo-stream>` element), so `this.getAttribute(...)` reads your custom attributes. Worked example wraps `toastify-js`.
- **Code worth stealing:**
```javascript
// app/javascript/application.js — the minimal custom action
import { StreamActions } from "@hotwired/turbo"

StreamActions.console_log = function() {
  const message = this.getAttribute("message")
  console.log(message)
}
```
```html
<turbo-stream action="console_log" message="Hello World"></turbo-stream>
```
```ruby
# app/helpers/turbo_stream_actions_helper.rb
# generated with: rails generate helper TurboStreamActions
module TurboStreamActionsHelper
  def toast(text)
    turbo_stream_action_tag :toast, text: text
  end
end

# Prepending is what makes turbo_stream.toast(...) available everywhere
Turbo::Streams::TagBuilder.prepend(TurboStreamActionsHelper)
```
```ruby
# Usable from a controller…
class ToastController < ApplicationController
  def index
    render turbo_stream: turbo_stream.toast("Hello world from Toastify!")
  end
end
```
```erb
<%# …or any view/partial %>
<%= turbo_stream.toast("Hello world from Toastify!") %>
```
```javascript
// The JS side of the toast action
import { StreamActions } from "@hotwired/turbo"
import Toastify from "toastify-js"

StreamActions.toast = function() {
  const text = this.getAttribute("text")

  const toast = Toastify({
    text,
    duration: 3000,
    gravity: "top",
    position: "right",
    close: true
  })

  toast.showToast()
}
```
```bash
# adding the dependency, both ways
yarn add toastify-js          # esbuild / webpacker
bin/importmap pin toastify-js # import maps
```
- **Good-fit use cases he lists:** HTML-diffing libraries for efficient updates, toast alerts, showing/hiding modals, updating dropdown contents, typeahead results, playing a sound. "You can basically wrap every JavaScript snippet or any npm package you could think of in an action."

### TurboPower — the stream-action power pack ★
- **Author:** Marco Roth | **URL:** https://github.com/marcoroth/turbo_power (+ https://github.com/marcoroth/turbo_power-rails, Django port: `django-turbo-helper`) | **Docs:** https://hotwire.io/documentation/turbo-power
- **Summary:** Adds ~50 ready-made custom stream actions to Turbo (requires Turbo 7.2+), plus the `morph` action from `turbo-morph`. This is the "don't write your own custom action for the twentieth time" library, and the action list doubles as a catalogue of *what people actually need beyond the built-in seven*.
- **Install:**
```bash
yarn add turbo_power
```
```javascript
// application.js
import * as Turbo from '@hotwired/turbo'

import TurboPower from 'turbo_power'
TurboPower.initialize(Turbo.StreamActions)
```
```bash
# TypeScript users (Turbo 8 ships types via the community package)
yarn add --dev @types/hotwired__turbo
```
- **The full action list (verbatim):**
  - **DOM:** `graft(target, parent, **attributes)`, `morph(target, html = nil, **attributes, &block)`, `inner_html(target, html = nil, **attributes, &block)`, `insert_adjacent_html(target, html = nil, position: 'beforeend', **attributes, &block)`, `insert_adjacent_text(target, text, position: 'beforebegin', **attributes)`, `outer_html(target, html = nil, **attributes, &block)`, `text_content(target, text, **attributes)`, `set_meta(name, content)`
  - **Attribute:** `add_css_class`, `remove_attribute`, `remove_css_class`, `set_attribute(target, attribute, value)`, `set_dataset_attribute`, `set_property`, `set_style(target, name, value)`, `set_styles`, `set_value`, `toggle_attribute(target, attribute, force)`, `toggle_css_class`, `replace_css_class(target, from, to)`
  - **Event:** `dispatch_event(target, name, detail: {})`
  - **Form:** `reset_form(target)`
  - **Storage:** `clear_storage(type)`, `clear_local_storage`, `clear_session_storage`, `remove_storage_item(key, type)`, `remove_local_storage_item`, `remove_session_storage_item`, `set_storage_item(key, value, type)`, `set_local_storage_item`, `set_session_storage_item`
  - **Browser:** `reload`, `scroll_into_view` (also `(targets)`, `(targets, align_to_top)`, `(targets, behavior:, block:, inline:)`), `set_focus(target)`, `set_title(title)`
  - **Document:** `set_cookie(cookie)`, `set_cookie_item(key, value)`
  - **History:** `history_back`, `history_forward`, `history_go(delta)`, `push_state(url, title, state)`, `replace_state(url, title, state)`
  - **Debug:** `console_log(message, level = :log)`, `console_table(data, columns)`
  - **Notification:** `notification(title, **options)`
  - **Turbo:** `redirect_to(url, turbo_action, turbo_frame)`, `turbo_clear_cache`
  - **Progress bar:** `turbo_progress_bar_show`, `turbo_progress_bar_hide`

---


### Process slow network requests with Turbo and Active Model
- **Author:** Steve Polito | **Date:** November 20, 2024 | **URL:** https://thoughtbot.com/blog/process-network-requests-with-turbo
- **Summary:** Shows how to run a slow external call in a background job and stream the result back with `Turbo::Broadcastable` — using a **plain ActiveModel object, not ActiveRecord**. Progression: naive synchronous controller → background job using low-level `Turbo::StreamsChannel.broadcast_replace_to` with `ApplicationController.render(partial:, locals:)` → cleaner version by including `Turbo::Broadcastable` directly on the ActiveModel class so the model gets `.broadcast_replace`. Because ActiveJob needs to serialize the plain object, it registers a custom `ActiveJob::Serializers::ObjectSerializer`. Finishes with a user-scoped variant (`turbo_stream_from order_search.user, order_search`) so only the requesting user's stream receives the update.
- **Code worth stealing:**
```ruby
# app/models/order_search.rb
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
# app/jobs/get_order_job.rb
class GetOrderJob < ActiveJob::Base
  def perform(order_search)
    sleep 1
    order_search.result = Order.new(id: order_search.order_id, product: "Some Widget", quantity: 1)
    order_search.broadcast_replace
  end
end
```
```ruby
# app/serializers/order_search_serializer.rb
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
# config/application.rb
config.autoload_once_paths << "#{root}/app/serializers"
```
```ruby
# config/initializers/custom_serializers.rb
Rails.application.config.active_job.custom_serializers << OrderSearchSerializer
```
```erb
<% # app/views/order_searches/_order_search.html.erb %>
<div id="<%= dom_id(order_search) %>">
  <% if order_search.processing? %>
    <%= turbo_stream_from order_search %>
    <p>Searching...</p>
  <% elsif order_search.processed? %>
    <%= render order_search.result %>
  <% end %>
</div>
```
```ruby
# user-scoped variant
order_search.broadcast_replace_to order_search.user, order_search
```
- **Opinion / hot take:** Establishes `Turbo::Broadcastable` works on any `ActiveModel::Model`, not just `ActiveRecord` — useful pattern reminder for non-persisted "form object"/search-object style classes.

### Hotwire: Turbo-Streaming ViewComponents
- **Author:** Connor McQuillan | **Date:** February 8, 2022 | **URL:** https://thoughtbot.com/blog/hotwire-turbo-streaming-viewcomponents
- **Summary:** Builds a live message board where messages render via `ViewComponent` instead of partials, both for the initial `turbo_stream.append` response and for real-time broadcast to other users. Key move: a small `Broadcast::Message` PORO wraps `Turbo::StreamsChannel.broadcast_append_later_to`, rendering the ViewComponent to HTML via `ApplicationController.render(component, layout: false)` since `turbo_stream.append` helpers don't natively accept components.
- **Code worth stealing:**
```ruby
# app/components/message_component.rb
class MessageComponent < ViewComponent::Base
  include ActionView::RecordIdentifier

  def initialize(message:)
    @message = message
  end

  private

  attr_reader :message
  delegate :body, :created_at, to: :message, prefix: true

  def recent_message?
    message_created_at > 1.hour.ago
  end

  def timestamp
    message_created_at.strftime("%Y-%m-%d at %H:%M")
  end
end
```
```erb
# app/views/messages/create.turbo_stream.erb
<%= turbo_stream.replace "new_message_form", partial: "form" %>
<%= turbo_stream.append "messages" do %>
  <%= render MessageComponent.new(message: @message) %>
<% end %>
```
```ruby
# app/models/broadcast/message.rb
module Broadcast
  class Message
    def self.append(message:)
      new(message).append
    end

    def initialize(message)
      @message = message
    end

    def append
      Turbo::StreamsChannel.broadcast_append_later_to(
        :messages,
        target: "messages",
        html: rendered_component
      )
    end

    private

    attr_reader :message

    def rendered_component
      ApplicationController.render(
        MessageComponent.new(message: message),
        layout: false
      )
    end
  end
end
```
```ruby
# app/controllers/messages_controller.rb
def create
  @message = Message.new(body: params[:body])

  if @message.save
    Broadcast::Message.append(message: @message)
  end

  respond_to do |format|
    format.html { redirect_to messages_path }
    format.turbo_stream
  end
end
```
- **Opinion / hot take:** Positions ViewComponent + Turbo Streams as strictly better than partials + Turbo Streams for "reusability, testability, and performance," treating partials as the legacy default rather than the preferred one.

### Hotwire: Server-rendered live previews
- **Author:** Sean Doyle | **Date:** September 14, 2021 | **URL:** https://thoughtbot.com/blog/hotwire-server-rendered-live-previews
- **Summary:** Builds a live article-preview pane in three stages: (1) plain HTML — a second submit button (`formaction: previews_path`) posts the draft and redirects back to `new_article_url` with the content round-tripped as query params, rendered server-side with `simple_format`; (2) Turbo Streams — controller `respond_to`s with `format.turbo_stream`, template does `turbo_stream.update params[:render_into]` so the target id is parameterized rather than hardcoded; (3) Stimulus — a `FormController` with a hidden `preview` submit-button target gets auto-clicked on the form's `input` event, debounced 300ms via lodash from Skypack, so the preview updates live as you type with zero manual "Preview" clicks.
- **Code worth stealing:**
```ruby
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
```erb
<%= turbo_stream.update params[:render_into] do %>
  <%= render partial: "articles/article", object: @preview, as: :article %>
<% end %>
```
```erb
<%= form.button "Preview Article", formaction: previews_path(render_into: "article_preview"),
      name: "_method", value: "post",
      data: { form_target: "preview" } %>
```
```javascript
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
```erb
<%= form_with(model: article, data: { controller: "form", action: "input->form#preview" }) do |form| %>
```
- **Opinion / hot take:** Frames Hotwire's core value as treating "form elements as declarative HTML alternatives to imperative AJAX calls" — no JSON serialization of records, ever, in this pattern.

### content_for -- What is it good_for?
- **Author:** Louis Antonopoulos | **Date:** March 24, 2025 | **URL:** https://thoughtbot.com/blog/content-for-what-is-it-good-for
- **Summary:** General `content_for` tutorial with a directly Hotwire-relevant payoff: placing a `<turbo-cable-stream-source>` (from `turbo_stream_from`) inside a `<ul>` violates HTML/accessibility rules, so `content_for :body` is used inside a `_post.html.erb` partial to hoist the `turbo_stream_from post` call out of the list and into the layout body. Also documents opting individual views into Turbo morphing without a global default, via `content_for :head` wrapping `turbo_refresh_method_tag`/`turbo_refresh_scroll_tag`, simplified by the `turbo_refreshes_with(method:, scroll:)` helper.
- **Code worth stealing:**
```erb
<!-- app/views/posts/_post.html.erb -->
<% content_for :body do %>
  <%= turbo_stream_from post %>
<% end %>

<li id="<%= dom_id(post) %>">
  <%= link_to post.title, post_path(post) %>
</li>
```
```erb
<!-- app/views/layouts/application.html.erb -->
<body>
   <%= content_for :body %> <!-- or yield :body -->
   <% yield %>
</body>
```
```erb
<!-- app/views/posts/index.html.erb -->
<% content_for :head do %>
  <%= turbo_refresh_method_tag :morph %>
  <%= turbo_refresh_scroll_tag :preserve %>
<% end %>
```
```erb
<!-- cleaner equivalent -->
<%= turbo_refreshes_with method: :morph, scroll: :preserve %>
```
- **Opinion / hot take:** Calls `content_for` "the decluttering friend that solves HTML problems with elegance and simplicity."

### Self-destructing StimulusJS controllers
- **Author:** Matt Swanson | **Date:** Jun 13, 2022 | **URL:** https://boringrails.com/articles/self-destructing-stimulus-controllers/
- **Summary:** Pattern for one-shot JS effects: a Stimulus controller that runs its logic in `connect()` and immediately calls `this.element.remove()`. Recommends wrapping these in `<template>` tags. Combines especially well with Turbo Stream `append` responses — you can append a task to a list *and* a self-destructing `scroll-to` template in the same stream response, letting the controller's own lifecycle trigger the scroll. Gives four concrete production examples: scroll-to, highlighter (adds temporary highlight classes via the `classes` API), grab-focus (moves focus to a newly-added form input), and an "analytics beacon" (PATCHes a view-tracking endpoint via `@rails/request.js` then vanishes) — the beacon pattern is credited as borrowed from HEY.
- **Code worth stealing:**
```js
// app/javascript/controllers/scroll_to_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { location: String };

  connect() {
    this.targetElement.scrollIntoView();
    this.element.remove();
  }

  get targetElement() {
    return document.getElementById(this.locationValue);
  }
}
```
```erb
<%= turbo_stream.append :tasks, @task %>

<%= turbo_stream.append :tasks do %>
  <template
    data-controller="scroll-to"
    data-scroll-to-location-value="<% dom_id(@task) %>"></template>
<% end %>
```
```js
// app/javascript/controllers/highlighter_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { marker: String };
  static classes = ["highlight"];

  connect() {
    this.markedElement.classList.add(...this.highlightClasses);
    this.element.remove();
  }

  get markedElement() {
    return document.getElementById(this.markerValue);
  }
}
```
```js
// app/javascript/controllers/beacon_controller.js — HEY-inspired analytics beacon
import { Controller } from "@hotwired/stimulus";
import { patch } from "@rails/request.js";

export default class extends Controller {
  static values = { url: String };

  connect() {
    patch(this.urlValue);
    this.element.remove();
  }
}
```
```ruby
module AnalyticsHelper
  def tracking_beacon(url:)
    tag.template data: { controller: "beacon", beacon_url_value: url }
  end
end
```
- **Opinion / hot take:** "Piggybacking on the existing lifecycle of Stimulus controllers ensures that things work as expected when changing content via Turbo Streams and navigating between pages with Turbo Drive" — avoids the classic `turbo:load` re-registration bugs that manual script tags suffer from.

### Hotwire components that refresh themselves
- **Author:** Matt Swanson (guest collab with Jesper Christiansen) | **Date:** Jul 7, 2025 | **URL:** https://boringrails.com/articles/self-updating-components/
- **Summary:** Advanced production pattern for real-time/background-job-driven UI: encapsulate `dom_id`/broadcast-channel string literals as methods on a ViewComponent (or Phlex) object itself, so the component "knows how to refresh itself." The component defines `id` (wraps `dom_id`), `broadcast_channel` (an array tuple passed to `turbo_stream_from`), and `broadcast_refresh!` (calls `Turbo::StreamsChannel.broadcast_replace_to` using `renderable: self` instead of `partial:`/`locals:`). Extends the pattern with a `sending_email?`-style transient state flag so the component only opens its `turbo_stream_from` subscription while actively in an in-progress state.
- **Code worth stealing:**
```ruby
# Before: scattered magic strings, hard to refactor
Turbo::StreamsChannel.broadcast_replace_to(
  "my-unique-identifier",
  target: id,
  partial: "user/card"
  locals: { user: @user }
)
```
```ruby
# UI::UserCard — component encapsulates its own identity + broadcast plumbing
class UI::UserCard < ApplicationComponent
  def initialize(user:, sending_email: false)
    @user = user
    @sending_email = sending_email
  end

  def id
    dom_id(@user, :user_card)
  end

  def broadcast_channel
    [@user, :user_card_refresh]
  end

  def sending_email?
    @sending_email
  end

  def introduction_email_sent?
    @user.introduction_email_sent_at.present?
  end

  def broadcast_refresh!
    Turbo::StreamsChannel.broadcast_replace_to(
      broadcast_channel,
      target: id,
      renderable: self,
      layout: false
    )
  end
end
```
```erb
<% tag.div id: id do %>
    <div class="text-lg font-bold"><%= @user.name %></div>
    <div class="text-sm text-slate-500"><%= @user.email %></div>

    <% if sending_email? %>
      <%= helpers.turbo_stream_from broadcast_channel %>
      <%= render UI::Spinner.new(size: :sm, message: "Sending introduction email") %>
    <% elsif !introduction_email_sent? %>
      <%= helpers.button_to "Send introduction email", user_emails_introduction_path(@user) %>
    <% end %>
<% end %>
```
```ruby
def create
  @user = Current.account.users.find(params[:id])
  @user.send_introduction_email_later!

  user_card = UI::UserCard.new(user: @user, sending_email: true)
  render turbo_stream: turbo_stream.replace(user_card.id, user_card)
end
```
```ruby
class SendUserIntroductionEmailJob < ApplicationJob
  queue_as :default

  def perform(user)
    user.send_introduction_email_later!
    UI::UserCard.new(user: user, sending_email: false).broadcast_refresh!
  end
end
```
- **Opinion / hot take:** "Are we mixing responsibilities and breaking the sacred Single Responsibility Principle? Probably, but I find that I much prefer working in systems that value locality of behavior these days."

### Galaxy brain CSS tricks with Hotwire and Rails
- **Author:** Matt Swanson | **Date:** Jul 26, 2022 | **URL:** https://boringrails.com/articles/css-tips-and-tricks-hotwire/
- **Summary:** Four CSS techniques specifically motivated by Hotwire's server-rendered-fragment model. (1) Empty-state handling for Turbo-Stream-mutated lists: always render the empty-state element and use the CSS `:only-child` pseudo-selector (Tailwind: `only:block hidden`) so it auto-shows/hides based on sibling count as Turbo Streams append/remove items — no re-render of the whole list needed. (2) Tailwind variants keyed off `data-` attributes on `<body>` via a custom `addVariant` Tailwind plugin, explicitly flagged as *not* a security boundary, just a view-cleanliness trick. (3) Dynamic `<style>` tags rendered from ERB for per-user/per-account theming via CSS custom properties, traced back to an old Basecamp fragment-caching trick. (4) Stop string-interpolating class names — use `tag.li class: [...]` array/hash syntax (Rails 6.1's `class_names` helper, auto-invoked by `tag`).
- **Code worth stealing:**
```erb
<div id="my_list" class="flex flex-col divide-y">
  <p class="only:block hidden">Whoops! you have no items!</p>
  <%= render partial: "list_item", collection: @list %>
</div>
```
```js
// tailwind.config.js — custom data-attribute variant
plugins: [
  function({addVariant}) {
    addVariant('admin', 'body[data-admin] &')
  }
],
```
```erb
<body <%= 'data-admin' if Current.user.admin? %>>
  ...
</body>

<div class="admin:block hidden">
  <%= button_to "Delete", @comment, method: :delete %>
</div>
```
```erb
<!-- per-account CSS-variable theming, fragment-cache friendly -->
<style>
  :root {
    --color-brand: <%= @account.brand_color %>;
    --color-brand-contrast: <%= ColorHelper.contrast(@account.brand_color) %>;
    --color-brand-tint: <%= ColorHelper.tint(@account.brand_color) %>;
  }
</style>
```
```ruby
# ViewComponent conditional class array (Rails 6.1 class_names under the hood)
class MyWidget < ViewComponent::Base
  def container_classes
    [
      "flex items-center justify-center space-x-2 rounded-full",
      "disabled:pointer-events-none disabled:select-none",
      "font-medium tracking-wide",
      {"text-white bg-black hover:bg-neutral-900": variant == :primary},
      {"text-neutral-600 border hover:bg-neutral-50 hover:text-neutral-900": variant == :secondary},
      {"w-full": full_width?}
    ]
  end
end
```
- **Opinion / hot take:** On the data-attribute-authorization trick: "isn't this super risky because someone could just fiddle with the HTML and delete a comment? Well, yes, they could – but you need to be checking authorization on the server-side anyways. It's a trade-off."

### Turbo Streaming Modals in Ruby on Rails
- **Site:** blog.appsignal.com | **Author:** Ayush Newatia | **Date:** March 13, 2024 | **URL:** https://blog.appsignal.com/2024/03/13/turbo-streaming-modals-in-ruby-on-rails.html
- **Summary:** Part 2 of the modals series. Replaces the previous post's `remote-modal` Stimulus controller with a **custom Turbo Stream action** (`Turbo.StreamActions.show_remote_modal`) registered under `app/javascript/stream_actions/`, exposed to Ruby views via a Rails helper that's `prepend`ed onto `Turbo::Streams::TagBuilder`. The custom element `<remote-modal-container>` receives the stream's `templateContent` and calls `showModal()` directly — eliminating the Stimulus controller entirely for this use case. Also shows enabling Turbo Streams on a plain `GET` link via `data: { turbo_stream: true }`.
- **Code worth stealing:**
```javascript
// app/javascript/stream_actions/show_remote_modal.js
Turbo.StreamActions.show_remote_modal = function () {
  const container = document.querySelector("remote-modal-container");
  container.replaceChildren(this.templateContent);
  container.querySelector("dialog").showModal();
};
```
```ruby
# app/helpers/turbo_stream_actions.rb
module TurboStreamActionsHelper
  def show_remote_modal(&block)
    turbo_stream_action_tag(
      :show_remote_modal,
      template: @view_context.capture(&block)
     )
  end
end
Turbo::Streams::TagBuilder.prepend(TurboStreamActionsHelper)
```
```erb
<%# app/views/support/tickets/new.turbo_stream.erb %>
<%= turbo_stream.show_remote_modal do %>
  <dialog id="contact_form_modal" aria-labelledby="modal_title"> ... </dialog>
<% end %>
```
```erb
<%= link_to new_support_ticket_path, data: { turbo_stream: true } do %>
  Show contact form
<% end %>
```
- **Uniqueness note:** The most technically distinctive post in the honeybadger/appsignal set — registering a genuinely custom `Turbo.StreamActions.*` action and exposing it as a first-class `turbo_stream.*` helper via monkey-patching `Turbo::Streams::TagBuilder`. Not covered by any other post found.

### How to Scale Ruby on Rails Applications
- **Site:** blog.appsignal.com | **Author:** Sapan Diwakar | **Date:** November 9, 2022 | **URL:** https://blog.appsignal.com/2022/11/09/how-to-scale-ruby-on-rails-applications.html
- **Summary:** In a "Background Workers" section, shows the pattern of kicking off a slow job synchronously-triggered-async, showing a loading partial immediately, then having the job itself broadcast the finished result back into the page via `Turbo::StreamsChannel.broadcast_replace_to` against a per-user notification stream — decoupling "queue the work" from "deliver the result" cleanly through Turbo Streams rather than polling.
- **Code worth stealing:**
```erb
<%= turbo_stream_from user, :huge_datasets %>
<%= render "filters" %>
<div id="data-container">
  <% if defined? data %>
    <%= render partial: "item", collection: data  %>
  <% else %>
    <%= render "loading" %>
  <% end %>
</div>
```
```ruby
def notify_completed(user, data)
  Turbo::StreamsChannel.broadcast_replace_to(
    [user, :huge_datasets],
    target: "data-container",
    partial: "huge_datasets/index",
    locals: { user: user, data: data }
  )
end
```
- **Uniqueness note:** A clean, minimal statement of the "background job finishes → broadcasts result via Turbo Streams to a scoped-array stream" pattern; the scoped stream `[user, :huge_datasets]` array-key idiom is a small but handy detail.

---

---

## Morphing & page refreshes


### The future of full-stack Rails: Turbo Morph Drive
- **Authors:** Vladimir Dementyev, Travis Turner | **Date:** October 16, 2023 | **URL:** https://evilmartians.com/chronicles/the-future-of-full-stack-rails-turbo-morph-drive
- **Summary:** Pre-Turbo-8 exploration of DOM morphing (rather than full `<body>` replacement) for Turbo Drive navigations, using the Idiomorph library ("it's what we'll end up with in Turbo 8"). Covers hooking `turbo:before-render` to swap in morphing, preserving scroll position across query-param-only navigations, handling `data-turbo-permanent` equivalents for morphing via a custom `data-morph-permanent` attribute + `beforeNodeMorphed` callback, applying the same technique to Turbo Frames via `turbo:before-frame-render`, making Stimulus controllers "morphing-aware" (reactive to attribute changes instead of expecting reconnect), and a custom `refresh` Turbo Stream action for model-change-triggered full-page refresh broadcasts (the ancestor of Turbo 8's built-in `refresh` action / `broadcasts_refreshes`).
- **Code worth stealing:**
```js
document.addEventListener("turbo:before-render", (event) => {
  event.detail.render = async (prevEl, newEl) => {
    await new Promise((resolve) => setTimeout(() => resolve(), 0));
    Idiomorph.morph(prevEl, newEl);
  };
});
```
```js
// Preserve scroll position across same-path navigations (e.g. query param changes)
let prevPath = window.location.pathname;

document.addEventListener("turbo:before-render", (event) => {
  Turbo.navigator.currentVisit.scrolled = prevPath === window.location.pathname;
  prevPath = window.location.pathname;
   event.detail.render = async (prevEl, newEl) => {
    await new Promise((resolve) => setTimeout(() => resolve(), 0));
    Idiomorph.morph(prevEl, newEl);
  };
});
```
```js
// data-morph-permanent: skip morphing nodes both old and new mark permanent
event.detail.render = async (prevEl, newEl) => {
  await new Promise((resolve) => setTimeout(() => resolve(), 0));
  Idiomorph.morph(prevEl, newEl, {
    callbacks: {
      beforeNodeMorphed: (fromEl, toEl) => {
        if (typeof fromEl !== "object" || !fromEl.hasAttribute) return true;
        if (fromEl.isEqualNode(toEl)) return false;
        if (
          fromEl.hasAttribute("data-morph-permanent") &&
          toEl.hasAttribute("data-morph-permanent")
        ) {
          return false;
        }
        return true;
      },
    },
  });
});
```
```js
// Morphing for Turbo Frames
document.addEventListener("turbo:before-frame-render", (event) => {
  event.detail.render = (prevEl, newEl) => {
    Idiomorph.morph(prevEl, newEl.children, { morphStyle: "innerHTML" });
  };
});
```
```js
// Stimulus controller reacting to attribute-value changes instead of expecting reconnect
import AnimatedNumber from "stimulus-animated-number";

export default class extends AnimatedNumber {
  endValueChanged(_newValue, oldValue) {
    this.startValue = oldValue;
    this.animate();
  }
}
```
```js
// Custom "refresh" turbo stream action, session-scoped so the triggering tab doesn't refresh itself
import { StreamActions } from "@hotwired/turbo";

const sessionID = Math.random().toString(36).slice(4);

StreamActions.refresh = function () {
  if (this.getAttribute("session-id") !== sessionID) {
    window.Turbo.cache.exemptPageFromPreview();
    window.Turbo.visit(window.location.href, { action: "replace" });
  }
};

document.addEventListener("turbo:before-fetch-request", (event) => {
  event.detail.fetchOptions.headers["X-Turbo-Session-ID"] = sessionID;
});
```
```ruby
# application_controller.rb — tag every request with a per-tab session id
class ApplicationController < ActionController::Base
  around_action :set_turbo_session_id

  private

  def set_turbo_session_id(&block)
    Current.set(turbo_session_id: request.headers["X-Turbo-Session-ID"], &block)
  end
end

# application_record.rb — model concern to broadcast a refresh on any commit
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  class << self
    def broadcasts_refreshes
      after_commit do
        Turbo::StreamsChannel.broadcast_stream_to(
          self,
          content: Turbo::StreamsChannel.turbo_stream_action_tag(
            :refresh,
            :"session-id" => Current.turbo_session_id
          )
        )
      end
    end
  end
end

# in some model
class Artist < ApplicationRecord
  broadcasts_refreshes
end
```
- **Opinion / hot take:** Full `<body>` replacement loses "local state" (scroll position, animation states, form focus) — morphing is framed as a strict UX upgrade Rails developers should adopt broadly, not just for the narrow "refresh" use case Turbo 8 eventually shipped. Demo app: "Turbo Music Drive" — https://github.com/palkan/turbo-music-drive, live at turbo-music-drive.fly.dev.


### Turbo 8 morphing refreshes on Rails
- **Author:** David Colby | **Date:** 2024-03-17 | **URL:** https://colby.so/posts/turbo-8-morphing-refreshes-on-rails
- **Summary:** Introduces Turbo 8's `turbo_refreshes_with(method: :morph, scroll: :preserve)` layout tag and `broadcasts_refreshes_to :blog` model declaration, which broadcast a "go refetch yourself" signal rather than HTML — each client re-fetches its own personalized page and idiomorph diffs it in, side-stepping the "session context problem" broadcast callbacks otherwise have.
- **Code worth stealing:**
```erb
<%# app/views/layouts/application.html.erb %>
<%= turbo_refreshes_with(method: :morph, scroll: :preserve) %>
```
```ruby
# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :blog
  broadcasts_refreshes_to :blog
end
```
```ruby
def create
  @post = Post.new(post_params)
  @post.blog = @blog
  if @post.save
    redirect_to @blog
  else
    render 'blogs/show', status: :unprocessable_entity
  end
end
```
```erb
<%= turbo_stream_from @blog %>
```
- **Opinion / hot take:** Advantages: "simpler happy paths" (no DOM ids, no stream templates, no controller branching); broadcasting avoids the session-context problem since each client fetches with its own permissions. Disadvantages: form state handling is "tricky" (needs `data-turbo-permanent`), full-page rendering is "more resource heavy" than targeted streams, and there's a network round-trip per broadcast. Conclusion: morphing refreshes suit *new* features more than retrofits — "think about your use case."

### Building a sortable table with Turbo 8's page refreshes
- **Author:** David Colby | **Date:** 2024-03-21 | **URL:** https://colby.so/posts/turbo-8-refresh-sorting
- **Summary:** Builds column-header sorting purely with morphing page refreshes and `data-turbo-action: 'replace'` — no frames or streams. Same-URL "replace" navigation triggers a re-render that idiomorph diffs into the existing DOM.
- **Code worth stealing:**
```erb
<%= turbo_refreshes_with method: :morph, scroll: :preserve %>
```
```ruby
module PlayersHelper
  def sort_link(column:, label:)
    direction = column == params[:column] ? next_direction : 'asc'
    link_to(label, players_path(column: column, direction: direction), data: { turbo_action: 'replace' })
  end
  def next_direction
    params[:direction] == 'asc' ? 'desc' : 'asc'
  end
end
```
```ruby
@players = Player.includes(:team).order("#{params[:column]} #{params[:direction]}")
```
- **Opinion / hot take:** "Page refreshes blend into the background" with vanilla Rails patterns. Tradeoff: `replace` doesn't advance browser history, so users can't step back through individual sort changes — "a deliberate simplification favoring developer ergonomics."

### Searching and filtering with Turbo 8
- **Author:** David Colby | **Date:** 2024-03-27 | **URL:** https://colby.so/posts/turbo-8-search-and-filter
- **Summary:** Layers debounced search/filter on top of the sortable-table post: filters persist in `session['filters']`, merged and applied via Ruby's `then` chaining; the form uses `data-turbo-permanent` so the input keeps focus/value across morphs; a Stimulus `autosubmit` controller debounces input.
- **Code worth stealing:**
```erb
<%= form_with url: players_path, method: :get, data: { turbo_action: "replace", controller: "autosubmit", turbo_permanent: "" } do |form| %>
```
```javascript
// app/javascript/controllers/autosubmit_controller.js
export default class extends Controller {
  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => { this.element.requestSubmit() }, 250)
  }
}
```
```ruby
def index
  session['filters'] ||= {}
  session['filters'].merge!(filter_params)
  @players = Player.includes(:team)
                    .then { search_by_name _1 }
                    .then { filter_by_team _1 }
                    .then { apply_order _1 }
end
```
- **Opinion / hot take:** "Turbo 8 plus Rails gives us the tools to write simple, Rails-y code without sacrificing user experience" — "page refreshes are vanilla Rails with a dash of magic on top."

---


### A happier happy path in Turbo with morphing ★ CORNERSTONE
- **Author:** Jorge Manrubia | **Date:** October 9, 2023 | **URL:** https://dev.37signals.com/a-happier-happy-path-in-turbo-with-morphing/
- **Video version:** Rails World 2023 talk — https://www.youtube.com/watch?v=m97UsXa6HFg
- **Summary:** The design document for Turbo 8 morphing. Core mental model: Turbo is a *progressive* ladder trading developer happiness against responsiveness — full-page `<body>` replacement (happiest) → Turbo Frames → Turbo Stream actions (most responsive, least happy). Partial updates impose "a reduced-productivity tax": once you add them you must reason about screen regions, the elements inside them, and how every interaction affects them. HEY Calendar broke this: partial updates were complex because rendering a calendar is hard, and they had an explosion of them. They tried `morphdom` (used by Phoenix LiveView) and found the win was NOT rendering speed but **preserved client-side state — scroll, focus, selected text, CSS transition states**. They switched to `idiomorph` because morphdom required sprinkling `id`s everywhere to help node matching, which broke the seamlessness. The result: a **page refresh** concept (re-rendering the current page, e.g. form submit → redirect back), auto-detected by Turbo, configured declaratively via page-level meta directives. Broadcasting collapses from per-model DOM operations to a single `refresh` action, auto-debounced so a burst of broadcasts yields one refresh.
- **Code worth stealing:**
```html
<meta name="turbo-refresh-method" content="morph">
<meta name="turbo-refresh-scroll" content="preserve">
```
```ruby
# The controller does NOT change — a plain redirect is what triggers the page refresh
class Kanban::ColumnsController < ApplicationController
  #...

  def create
    @column = @bucket.record Kanban::Column.new(column_params), parent: @board
    redirect_to @board
  end
end
```
```ruby
# Model — replaced +100 lines of per-event broadcast code in the Card Table
class Board < ApplicationRecord
  broadcasts_refreshes
end
```
```erb
<%= turbo_stream_from @board %>
```
```html
<!-- Exclude a region from morphing (e.g. an open popover menu) -->
<div data-turbo-permanent>
</div>
```
  Child models (`Card`, `Column`) `touch: true` up to `Board`, so a single `Board` refresh signal replaces the old fan-out (`prepend` on card create, `remove` on card remove, `replace` on assignee change, `append`/`remove`/`replace` on columns).
- **Opinion / hot take:**
  > "DOM tree morphing is a fantastic innovation, but we don't want to make it a new tool in your Turbo box, we want to make it an implementation detail."
  > "Morphing is an implementation detail that Turbo will hide away in Turbo Drive, just like it does with `history.pushState`."
  > "The traditional server-side full-page programming model that Rails nailed twenty years ago is incredibly productive… Old-fashioned and boring, this programming model delivers peak programming happiness."
  Also a sharp observation about incentives inverting: under manual broadcasts you only broadcast a few key changes because each costs work; under `broadcasts_refreshes` the work is *excluding* changes from triggering a refresh.
  Explicitly: page refreshes do **not** deprecate Turbo Streams — streams still give higher fidelity — "but it should make them rarer."

### Demo of page refreshes with morphing
- **Author:** Jorge Manrubia | **Date:** November 27, 2023 | **URL:** https://dev.37signals.com/page-refreshes-with-morphing-demo/
- **Summary:** Companion to the above: a demo repo showing the *same* app in three versions — (1) vanilla Rails, (2) enhanced with Turbo Stream actions, (3) all interactions done with page refreshes. Written explicitly as a code comparison because "Comparing code helps a lot in software discussions." Published alongside the Turbo 8 first beta.
- **Opinion / hot take:** > "page refreshes don't deprecate stream actions — [they] remain Turbo's most responsive mechanism, but they should reduce the need to use those. And this is a good thing because stream actions are costly."

### Exploring server-side diffing in Turbo ★ (the road not taken)
- **Author:** Jorge Manrubia | **Date:** October 24, 2023 | **URL:** https://dev.37signals.com/exploring-server-side-diffing-in-turbo/
- **Summary:** They prototyped the Phoenix-LiveView-ish alternative and rejected it. The prototype: a Rails middleware intercepting requests with a custom MIME type `text/vnd.turbo-diff.json`, a server-side diff engine holding a per-session cache of the last page sent, and a client applying a JSON diff. The diff format used **positional selectors** (e.g. `"0/1"`) instead of DOM ids, so it didn't need element identifiers. Result: payloads shrank but "there were some marginal gains due to the smaller payload, but they weren't noticeable in the scenarios we tested."
- **Opinion / hot take:** Three reasons they killed it, and they're the best available articulation of Turbo's design philosophy:
  > "Tracking the per-client state on the server is pushing against the grain of HTTP, where stateless is core" — and "The client already has a copy of the current page, on screen and in memory." (Jeffrey Hardy)
  > "While we can create an excellent DOM diffing library for the server that covers edge cases, do we want to?"
  Plus portability: server-side diffing requires a backend implementation per language, violating Turbo's "drop it into your app, and it just works" promise. HTML is more portable than a diffing protocol.

### Turbo 8 released
- **Author:** Alberto Fernández-Capel | **Date:** February 7, 2024 | **URL:** https://dev.37signals.com/turbo-8-released/
- **Summary:** Ships four headline features. (1) **Morphing page refreshes** — already in production in Basecamp's Card Table and the HEY Calendar. (2) **View Transitions API** support for animated page transitions (Chrome-only at the time), in use in Campfire. (3) **InstantClick** — preloads links on hover/before click; cited example goes from ~1.4s to ~380ms on a slow connection; in production in Basecamp and Campfire. (4) **TypeScript removed** — Turbo migrated back to plain JavaScript, which they credit with "a stable and ever growing community of contributors." Release volume: 125 PRs merged, 102 issues closed.
- **Opinion / hot take:** The TS-removal decision is a real hot take worth citing in any "Hotwire's philosophy" section: they traded static types for contributor throughput.

---


### Turbo 8 morphing deep dive — how does it work? (Part 1) ★★ CORNERSTONE
- **Author:** Radan Skorić | **Date:** Dec 12, 2023 (updated Jul 11, 2026) | **URL:** https://radan.dev/articles/turbo-morphing-deep-dive
- **Summary:** The definitive teardown of the Rails-side plumbing. Traces the full path: form submit → model commit callbacks → debounced background job → ActionCable broadcast → `<turbo-cable-stream-source>` → `refresh` stream action → idiomorph. Key mechanics documented nowhere else this clearly:
  - `broadcasts_refreshes` unrolls into three callbacks (below).
  - Stream names are built from `record.to_gid_param` (globalid), concatenated for multiple records, then **signed** with `Turbo.signed_stream_verifier` (an `ActiveSupport::MessageVerifier`) to prevent tampering.
  - Fallback: absent `to_gid_param` it calls `to_param`, which `String` implements — **so you can broadcast to an arbitrary string name with no AR record involved.**
  - The `request-id` on a refresh tag is generated on the frontend, sent up as the `X-Turbo-Request-Id` header, echoed back by the server; the client keeps a list and **ignores refreshes whose request id it originated**, so you don't double-refresh from your own action (you already got the HTML in the HTTP response).
  - Broadcasts run through `Turbo::Debouncer` (thread-scoped, built on `Concurrent::ScheduledTask`), **default delay 0.5s**, cancel-and-reschedule semantics — so the broadcast typically fires half a second after your last DB write.
  - Turbo's idiomorph options: don't add an element that has an `id` + `data-turbo-permanent` and already exists; don't morph/remove an element if it's `data-turbo-permanent`, or the frame being updated isn't a morphing remote frame, or the node being replaced *is* a morphing remote frame (those reload separately after morphing finishes).
- **Code worth stealing:**
```ruby
# What broadcasts_refreshes actually expands to (turbo-rails Turbo::Broadcastable)
stream = model_name.plural
after_create_commit  -> { broadcast_refresh_later_to(stream) }
after_update_commit  -> { broadcast_refresh_later }
after_destroy_commit -> { broadcast_refresh }
```
```ruby
# Broadcasting to an arbitrary stream name — no Active Record record needed
# In the model
after_update_commit -> { broadcast_refresh_later_to("Beeblebrox") }
```
```erb
<%# In the view %>
<%= turbo_stream_from "Beeblebrox" %>
```
```html
<!-- What actually goes over the wire for a refresh -->
<turbo-stream
  request-id="ca519ab9-1138-4625-abc2-6049317321a9"
  action="refresh">
</turbo-stream>

<!-- What subscribes the page to the stream -->
<turbo-cable-stream-source
  channel="Turbo::StreamsChannel"
  signed-stream-name="SIGNED_NAME">
</turbo-cable-stream-source>
```
- **Opinion / hot take:** His stated method is worth adopting wholesale: "as with every _Rails magic_ feature I'm part excited… and anxious for all of the time I will waste figuring out why it stopped working. My favourite way to battle it is to pull the curtain on the magic. I'm not scared once I've seen the wizard behind the curtain pulling the ropes."
  Practical takeaways he lands on: don't worry about spawning too many broadcasts on one stream (the debouncer handles it) — **but refreshes from different models are not aggregated**, so think about whether each model really needs to broadcast; and the initiating user morphs against *your* response, so make sure that response matches what other users will fetch.

### Turbo 8 morphing deep dive — how idiomorph works? (Part 2, with interactive playground) ★★
- **Author:** Radan Skorić | **Date:** Dec 19, 2023 (updated Jul 11, 2026) | **URL:** https://radan.dev/articles/turbo-morphing-deep-dive-idiomorph
- **Summary:** The algorithm itself, with an embedded playground where you paste before/after HTML and watch what idiomorph does. Five steps: build an ID map → morph `<head>` specially → find the best match in new content for the old top-level element → recursively morph → re-insert content that sat around the best match. The **ID map** maps every node to the `Set` of ids contained anywhere beneath it, built by `node.querySelectorAll('[id]')` and walking each match's parent chain. Node matching is scored: **+0.5 for a matching node type, +1 for each shared id**; a type mismatch scores 0 outright and ids are ignored.
  `<head>` uses idiomorph's **merge** algorithm (Turbo's default): keep elements present in both, remove ones only in old, add ones only in new. Three consequences: order is not preserved; elements are compared by full `outerHTML` (any difference = not equal); and the head morph is **async — it waits for newly added elements' `load` events** so new CSS/JS is in place before the body morphs.
- **Code worth stealing:**
```html
<!-- How the ID map is built: each node maps to the set of ids beneath it -->
<div> <!-- ids=["left", "A", "B", "more", "right"] -->
  <div id="left"> <!-- ids=["left", "A", "B", "more"] -->
    <div> <!-- ids=["A", "B"] -->
      <p id="A">This is some A content</p>
      <p id="B">This is just B content.</p>
    </div>
    <div id="more">More content</div>
  </div>
  <div id="right">Right text</div>
</div>
```
```html
<!-- Best-match scoring. Old content: -->
<div><p id="A">aa</p><p id="B">bb</p><p id="C">cc</p></div>

<!-- Candidates in new content, with their scores: -->
<p id="A">abcd</p>                              <!-- 0   (no node type match) -->
<div><p>aaa</p></div>                           <!-- 0.5 (just type match) -->
<div><p id="Z">zzz</p></div>                    <!-- 0.5 (just type match) -->
<div><p id="A">aaa</p></div>                    <!-- 1.5 (type match + 1 id) -->
<div><p id="B">bbb</p><p id="C">ccc</p></div>   <!-- 2.5 (type match + 2 ids) -->
```
- **Opinion / hot take:** Two rules that should be repo doctrine:
  1. **ids must genuinely be unique.** "HTML and CSS are reasonably forgiving of repeated ids. However, it could cause big issues with this algorithm."
  2. **Put ids on all real content**, globally unique and model-derived — `id="project-123"` — i.e. use `dom_id`. Morph quality is a direct function of id coverage.
  Also a counter-intuitive perf note: **there is no cost for head tags that stay the same**, so "front loading of all assets can be a reasonable strategy" — but beware adding very large new assets in morphed content, because the body stays un-morphed until they load.

### How to avoid problems with Turbo morphing ★★
- **Author:** Radan Skorić | **Date:** Feb 5, 2025 (updated Apr 18, 2026) | **URL:** https://radan.dev/articles/how-to-avoid-problem-with-turbo-morphing
- **Demo:** https://demo.radan.dev/morphing — source at https://github.com/radanskoric/demo/tree/main/demos/morphing
- **Summary:** The best troubleshooting taxonomy available. Root cause of every morphing complaint stated in one line: **"Part of the new state is in the browser and morphing causes problems by forcing it to match server state."** Symptoms: non-Turbo-aware JS libraries lose their initialized DOM elements; user-modified UI state (open sidebars, accordions) resets; server-loaded forms disappear. Three families of fix:
  1. **Tell Turbo to leave it alone** — `data-turbo-permanent`, or `preventDefault()` in the morph callbacks.
  2. **Limit the update scope** — `replace`/`update` stream actions with `method="morph"`, or Turbo Frames.
  3. **Make server state match browser state** — persist the UI state (user preferences model, or session), or encode it in the URL, so you morph *toward* the desired state and the problem evaporates.
  He documents exactly how `data-turbo-permanent` works: Turbo (a) saves permanent elements from the current page keyed **by id** — hence **every permanent element must have a unique id**; (b) replaces matching permanent elements in the incoming content with placeholders keeping the id; (c) performs the refresh; (d) swaps the saved nodes back in by id — so they remain *the same JavaScript objects*, which is why attached listeners and library state survive. This mechanism predates and is independent of morphing (it works with plain body replacement too).
  **Critical correction to the docs:** Turbo Frames **do not support morphing** for their own updates. The `refresh="morph"` attribute means "frame that will get reloaded with morphing **during page refreshes**" — the morph runs only when the frame is refreshed as part of a full page refresh, not when the frame itself is refreshed. (Exception he notes: a frame with `refresh="morph"` *will* morph if explicitly reloaded from JS via `.reload()`; there's an unmerged turbo-site docs PR clarifying this.)
- **Code worth stealing:**
```javascript
// The two morph-specific escape hatches — call preventDefault() to veto a morph
// turbo:before-morph-element    — fires before an element is morphed
// turbo:before-morph-attribute  — fires before an attribute is morphed
```
```html
<!-- Every permanent element MUST have a unique id — Turbo stores/restores them by id -->
<div id="rich-text-editor" data-turbo-permanent>…</div>
```
- **Opinion / hot take:** The "store UI state on the server or in the URL" fix is the one most people miss, and he notes the tell for when it's right: **"This best usage of this approach is when it also has a UX benefit beyond fixing morphing"** — e.g. the state now persists across sessions, or the URL becomes shareable with the UI state intact. Opens with a haiku: *"A beautiful UI / Morphed into existence / Suddenly broken."*

### How to debug issues with Turbo Morphing ★
- **Author:** Radan Skorić | **Date:** Feb 26, 2024 (updated Oct 10, 2025) | **URL:** https://radan.dev/articles/how-to-debug-issues-with-turbo-morphing
- **Summary:** A repeatable debugging procedure, written after he chased a reported Turbo issue and found a real corner-case bug (https://github.com/hotwired/turbo/issues/1158#issuecomment-1938477505) in about an hour. Steps: get accurate mental models first (his two deep dives); make it reproducible but **don't** over-invest in a minimal example (morphing debugs fine with noise around it); **swap Turbo to the unminified build**; use the browser's "Break on…" DOM breakpoints; and set breakpoints at three known-good spots in Turbo's source. Key insight that makes morphing unusually debuggable: **there is no intermediate state stored in JavaScript between two morphing updates — morphing is fully determined by the incoming HTML plus the current DOM.**
- **Code worth stealing:**
```ruby
# config/importmap.rb — use the unminified Turbo so you can set breakpoints in it
pin "@hotwired/turbo-rails", to: "turbo.min.js"   # default
pin "@hotwired/turbo-rails", to: "turbo.js"       # change to this while debugging
```
  DOM "Break on" options, and when each is useful:
  - **subtree modifications** — best general choice; idiomorph descends recursively, morphing each node with its children before moving to siblings, so you can step through changes cleanly.
  - **attribute modifications** — best for Turbo Frames inside morphed content (remote frames have a more complex lifecycle); pair with breakpoints in `FrameController`.
  - **node removal** — least useful; if a node is removed unexpectedly it's almost always missing from the new HTML response, and anything else is a morphing-library bug.

  Search strings for breakpoints inside Turbo's source (Sources tab → assets → turbo), given as snippets rather than line links so they survive version bumps (written against v8.0.18):
  1. `"turbo:morph"` → lands in `renderElements`, where the actual morphing happens (morphing has *finished* when the event dispatches — break at the **start** of the method).
  2. `shouldMorphPage =` → inside `PageView#renderPage`, which handles rendering the server response. Fires every time; use this if the morph breakpoint never hits.
  3. `linkClicked =` → the callback Turbo attaches to links; use this if the request never reaches the server.
  Workflow: run to the Turbo breakpoint first, *then* set the "Break on" DOM breakpoints while execution is paused, then resume.

---


### Hotwire and That Syncing Feeling
- **Author:** Louis Antonopoulos | **Date:** March 13, 2025 (updated March 20, 2025) | **URL:** https://thoughtbot.com/blog/hotwire-and-that-syncing-feeling
- **Summary:** Builds a multi-screen presentation system (group view, individual view, presenter view, ~30 concurrent clients) kept in sync purely with `broadcasts_refreshes` + `turbo_stream_from` + Turbo morphing — no custom Action Cable channel or JS. Key gotcha: `increment!`/`decrement!` skip ActiveRecord callbacks so they never trigger a broadcast — must use `update!`. Shows two ways to make system tests wait for the async broadcast job (async Active Job adapter + `perform_enqueued_jobs`, or forcing the inline test adapter). Notes Heroku needs a second dyno (`bundle exec bin/jobs`) for job processing.
- **Code worth stealing:**
```ruby
# app/models/presentation.rb
class Presentation < ApplicationRecord
  broadcasts_refreshes
end
```
```erb
<!-- app/views/presentations/group/show.html.erb -->
<%= turbo_stream_from @presentation %>
  <div id="<%= dom_id(@presentation) %>">
    <div>Group View: Slide <%= @presentation.current_slide %></div>
```
```erb
<!-- app/views/layouts/application.html.erb -->
<!DOCTYPE html>
<html lang="en">
  <head>
    ...
    <%= csp_meta_tag %>
    <%= turbo_refreshes_with method: :morph, scroll: :preserve %>
```
```ruby
# test/system/presentation_test.rb
test "/presentations/:id/group dynamically updates its content" do
  presentation = create :presentation, current_slide: 1
  visit presentation_group_path(presentation)
  assert_text "Slide 1"
  presentation.update!(current_slide: 2)
  assert_text "Slide 2"
end
```
```ruby
# config/environments/test.rb
config.active_storage.service = :async
```
```ruby
# test/system/presentation_test.rb
include ActiveJob::TestHelper

test "/presentations/:id/group dynamically updates its content" do
  presentation = create :presentation, current_slide: 1
  visit presentation_group_path(presentation)
  assert_text "Slide 1"
  perform_enqueued_jobs do
    presentation.update!(current_slide: 2)
  end
  assert_text "Slide 2"
end
```
```ruby
# config/environments/test.rb  (alternate: inline adapter)
config.active_storage.service = :inline
```
```ruby
# test/test_helper.rb
module ActiveJob
  module TestHelper
    def queue_adapter_for_test
      ActiveJob::QueueAdapters::TestAdapter.new
    end
  end
end
```
- **Opinion / hot take:** Warns that "submitting a form with Turbo morphing on can create some unexpected woes, such as the form not clearing itself on a POST" — points readers to the companion "Turbo morphing woes" article.

### Turbo morphing woes
- **Author:** Matheus Richard | **Date:** December 11, 2024 (updated Dec 13, 2024) | **URL:** https://thoughtbot.com/blog/turbo-morphing-woes
- **Summary:** Walks through three concrete failure modes of Turbo 8 page-refresh morphing and their fixes: (1) morphing destroys/recreates a Trix rich-text editor's DOM, killing its JS state — fixed with `data-turbo-permanent` on the *wrapping div* (not the textarea itself, because `<trix-toolbar>` also needs preserving); (2) forms don't clear after a morphed POST — fixed with a tiny Stimulus controller that calls `this.element.reset()` on `turbo:submit-end`; (3) `broadcasts_refreshes` + morph reopens a `<details>` element for every viewer whenever anyone edits a comment — fixed by listening to `turbo:before-morph-attribute` and calling `event.preventDefault()` when `attributeName === "open"`.
- **Code worth stealing:**
```erb
<!-- app/views/comments/_form.html.erb -->
<div data-turbo-permanent>
  <%= form.label :content %>
  <%= form.rich_text_area :content %>
</div>
```
```javascript
// app/javascript/controllers/form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  reset() {
    this.element.reset()
  }
}
```
```erb
<!-- app/views/comments/_form.html.erb -->
<%= form_with(model: comment, data: {controller: "form", action: "turbo:submit-end->form#reset"}) do |form| %>
  <%# ... %>
<% end %>
```
```ruby
# app/models/comment.rb
class Comment < ApplicationRecord
  broadcasts_refreshes
end
```
```javascript
// app/javascript/controllers/details_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  preventToggle(event) {
    const { attributeName } = event.detail;
    if (attributeName === "open") event.preventDefault()
  }
}
```
```erb
<!-- app/views/comments/_comment.html.erb -->
<%= turbo_stream_from comment %>
<details open data-controller="details" data-action="turbo:before-morph-attribute->details#preventToggle">
```
- **Opinion / hot take:** "Morphing isn't as simple as it might seem, so enabling it by default can be dangerous... Turbo morphs are sharp knives that should be wielded with care in specific scenarios, but not something ready yet to be enabled globally."

### Turbo 8 in 8 minutes
- **Author:** Brad Gessler | **Date:** Nov 29, 2023 | **URL:** https://fly.io/ruby-dispatch/turbo-8-in-8-minutes/
- **Summary:** Introduces Turbo 8's `morph` refresh mode as "a really smart page reloader": Rails models call `broadcasts_refreshes`, pages subscribe via `turbo_stream_from`, and on any change Turbo fetches the *entire* HTML page over HTTP, diffs it against the current DOM, and patches only the differences — no more hand-written `turbo_stream.replace` blocks or turbo_frame wiring for many CRUD cases. Also covers touch-propagation for updating collections (index pages) when child records change, and notes Postgres/SQLite NOTIFY-based ActionCable adapters remove the old 8000-byte payload ceiling since only a change signal (not HTML) crosses the wire.
- **Code worth stealing:**
```ruby
# Gemfile
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails", "~> 2.0.0.pre.beta"
```
```erb
<%# app/views/layouts/application.html.erb %>
<%= turbo_refreshes_with method: :morph, scroll: :preserve %>
<%= content_for :head %>
```
```erb
<%# app/views/post/show.html.erb %>
<%= turbo_stream_from @post %>
<h1><%= @post.title %></h1>
```
```ruby
# app/models/post.rb
class Post < ApplicationRecord
  # When the model instance is changed, a message will sent over
  # ActionCable that notifies the page to reload.
  broadcasts_refreshes
end
```
```erb
<%# app/views/blog/posts/index.html.erb — updating a collection %>
<%= turbo_stream_from @blog %>
<%= render @blog.posts %>
```
```ruby
class Post
  # Touch will update the timestamp on the blog when
  # a post is created, updated, or destroyed.
  belongs_to :blog, touch: true

  broadcasts_refreshes
end

class Blog
  has_many :posts
  broadcasts_refreshes
end
```
```ruby
# Three-level chain: Post -> Blog -> User, all "touch" up to trigger a refresh
class Blog < ApplicationRecord
  belongs_to :user, touch: true
end

class User < ApplicationRecord
  has_many :blogs
  broadcasts_refreshes
end
```
```erb
<%# dashboard page %>
<%= turbo_stream_from current_user %>
<%= render @current_user.blogs %>
```
- **Opinion / hot take:** "Forget everything you know about older versions of Turbo" — don't compare Turbo 7 vs 8, just learn morph fresh. Also: "If you're heavily invested in Turbo Frames in versions prior to Turbo 8, the hardest part of moving over will probably be removing all the `format.turbo_stream` blocks in your controller code and `turbo_frame` tags from your views."

### 8 Turbo 8 "Gotchas"
- **Author:** Brad Gessler | **Date:** Jan 2, 2024 | **URL:** https://fly.io/ruby-dispatch/8-turbo-8-gotchas/
- **Summary:** Field-tested list of gotchas upgrading to Turbo 8 morph. Covers `scroll: preserve` vs `reset` semantics per-page-type, `autofocus` fighting with idiomorph diffing and forcing unwanted scroll jumps, `data-turbo-permanent` to protect in-progress form edits from being clobbered by a morph, why caching matters more now that morph re-fetches full HTML pages, a `content_for :head`/`_tag` helper-suffix gotcha for where Turbo meta tags actually render, a "simulate slowness" dev concern for seeing loading states, `turbo-cable-stream-source` breaking CSS grid/flex layouts, and a reminder that `turbo_frame` still has a place for lazy-loaded/paginated/autocomplete content even after morph.
- **Code worth stealing:**
```ruby
# ./app/models/concerns/simulated_slowness.rb
module SimulatedSlowness
  # Simulates a delay in a development environment so we don't get spoiled
  # by everything being super fast all the time.
  def simulate_delay(seconds = 5)
    if Rails.env.development?
      Rails.logger.debug "Sleeping for #{seconds} seconds 🥱"
      seconds.times.each do |n|
        sleep 1
        Rails.logger.debug "Sleeping for #{n} seconds 😴"
      end
      Rails.logger.debug "Awake after #{seconds} seconds 😀"
    end
  end
end
```
```ruby
class ApplicationModel < ActiveRecord::Base
  include SimulatedSlowness
end

# usage inside a job/model method
def perform
  simulate_delay 4.seconds
end
```
```html
<!-- keep the cable stream tag out of grid/flex layout flow -->
<turbo-cable-stream-source channel="Turbo::StreamsChannel"
  signed-stream-name="..." class="hidden" style="display: none;" connected="">
</turbo-cable-stream-source>
<div id="post_1" class="grid grid-columns-2">
  <!-- ... -->
</div>
```
- **Opinion / hot take:** "Turbo 8 page morphing seems like a sledge hammer approach to building low latency UI... but when you consider how caching is built into browsers, proxies, and frameworks — it's really an elegant and balanced way to solve the problem." Also flags the client-side DX gap honestly: "there's a lot of room for improvement for the developer experience including better client-side debugging tools, a client-side API to handle conflict resolution for DOM merging elements like form inputs."

---

---

## Stimulus design & patterns


### ViewComponent in the Wild II: Supercharging Your Components
- **Authors:** Alexander Baygeldin, Travis Turner | **Date:** October 18, 2022 | **URL:** https://evilmartians.com/chronicles/viewcomponent-in-the-wild-supercharging-your-components
- **Summary:** The heavily-code-driven production playbook for `view_component-contrib`: folder conventions (`app/views/components/<name>/component.rb` + `component.html.erb` + `preview.rb` + sidecar assets, namespaced with `append_view_path` so controller/mailer views don't collide), a `component(name, *args, **kwargs)` helper to avoid typing `.new` + full class name everywhere, base classes wired to `dry-initializer` for declarative constructors, `dry-effects` for implicit context propagation (e.g. `current_user`) into both components and their RSpec/preview environments, relative component nesting (`.my-nested-component` syntax), namespaced I18n, CSS Modules-style class scoping via a `postcss-modules` `generateScopedName` function plus a `class_for` helper, **and the canonical sidecar Stimulus controller pattern**: one `controller.js` per component folder, glob-registered via `import.meta.globEager("./../../app/views/components/**/controller.js")`, with the Stimulus controller *identifier* auto-derived from the folder path so `data-controller`/`data-*-target`/`data-action` attributes never have to be hand-typed (a `controller_name` helper mirrors the CSS `identifier` naming). Also covers wiring up Lookbook (a Storybook-alike for ViewComponent) including previews for ActionMailer emails and for React components living in the same hybrid app, plus a runtime linter that raises if a component fires a SQL query during render (via `ActiveSupport::Notifications` on `sql.active_record` / `!render.view_component`).
- **Code worth stealing:**
```ruby
# ApplicationController — namespace controller views under app/views/controllers
append_view_path Rails.root.join("app", "views", "controllers")
```
```ruby
# ApplicationHelper — shorthand render helper
def component(name, *args, **kwargs, &block)
  component = name.to_s.camelize.constantize::Component
  render(component.new(*args, **kwargs), &block)
end
```
```ruby
# app/views/components/application_view_component.rb
class ApplicationViewComponent < ViewComponentContrib::Base
  extend Dry::Initializer
  include ApplicationHelper
end
```
```ruby
# Implicit context via dry-effects — ApplicationController
include Dry::Effects::Handler.Reader(:current_user)
around_action :set_current_user
private
def set_current_user
  with_current_user(current_user) { yield }
end
```
```ruby
# ApplicationViewComponent
include Dry::Effects.Reader(:current_user, default: nil)
```
```js
// app/views/components/hello/controller.js — sidecar Stimulus controller per component
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name"]

  greet() {
    const element = this.nameTarget
    const name = element.value
    console.log(`Hello, ${name}!`)
  }
}
```
```erb
<!-- app/views/components/hello/component.html.erb -->
<div data-controller="hello">
  <input data-hello-target="name" type="text">
  <button data-action="click->hello#greet">Greet</button>
</div>
```
```js
// app/assets/javascripts/application.js — Vite-based glob auto-registration of sidecar controllers
import { Application } from '@hotwired/stimulus'

const application = Application.start()
window.Stimulus = application

const controllers = import.meta.globEager(
  "./../../app/views/components/**/controller.js"
)

for (let path in controllers) {
  let module = controllers[path]
  let name = path
    .match(/app\/views\/components\/(.+)\/controller\.js$/)[1]
    .replaceAll("_", "-")
    .replaceAll("/", "--")

  application.register(name, module.default)
}
```
```ruby
# ApplicationViewComponent — mirror the same naming to avoid hand-typed data-controller strings
def controller_name
  self.class.identifier
end
```
```erb
<!-- Now data-controller is never hand-typed / can't drift out of sync -->
<div data-controller="<%= controller_name %>">
  <input data-<%= controller_name %>-target="name" type="text">
  <button data-action="click-><%= controller_name %>#greet">Greet</button>
</div>
```
```js
// postcss.config.js — CSS Modules scoping keyed to the component folder path
module.exports = {
  plugins: {
    'postcss-modules': {
      generateScopedName: (name, filename, _css) => {
        const matches = filename.match(/\/app\/views\/components\/?(.*)\/index.css$/)
        if (!matches) return name
        const identifier = matches[1].replaceAll('_', '-').replaceAll('/', '--')
        return `c--${identifier}--${name}`
      },
      getJSON: () => {}
    }
  }
}
```
```ruby
# Runtime linter: raise if a component queries the DB during render
# config/application.rb
config.view_component.instrumentation_enabled = true
# development.rb / test.rb
config.view_component.raise_on_db_queries = true
```
```ruby
# config/initializers/view_component.rb
if Rails.application.config.view_component.raise_on_db_queries
  ActiveSupport::Notifications.subscribe "sql.active_record" do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    Thread.current[:last_sql_query] = event
  end

  ActiveSupport::Notifications.subscribe("!render.view_component") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    last_sql_query = Thread.current[:last_sql_query]
    next unless last_sql_query

    if (event.time..event.end).cover?(last_sql_query.time)
      component = event.payload[:name].constantize
      next if component.allow_db_queries?

      raise <<~ERROR.squish
        `#{component.component_name}` component is not allowed to make database queries.
        Attempting to make the following query: #{last_sql_query.payload[:sql]}.
      ERROR
    end
  end
end
```
- **Opinion / hot take:** "The majority of techniques presented in this article can be considered 'off-label' to ViewComponent... this is how we cook view components at Evil Martians." Frontend/backend hybrid apps (some ViewComponent, some React) are treated as normal, not a failure state — the goal is one unified Lookbook storybook regardless of rendering technology.


### Build modals with Hotwire in Rails (Turbo Frames + Stimulus)
- **Author:** Alexandre Ruban | **URL:** https://www.hotrails.dev/articles/rails-modals-with-hotwire
- **Summary:** Reusable Bootstrap-based modal pattern: a single `turbo_frame_tag "modal"` lives once in the app layout; any "New X" link targets it (`data-turbo-frame: "modal"`); a `modal` Stimulus controller listens for `turbo:frame-load` (open) and `turbo:submit-end` (close on success) — no explicit JS calls needed to open/close, Turbo's own lifecycle events drive it.
- **Code worth stealing:**
```erb
<%# app/views/layouts/application.html.erb %>
<div class="modal" tabindex="-1" data-controller="modal"
     data-action="turbo:frame-load->modal#open turbo:submit-end->modal#close">
  <div class="modal-dialog"><div class="modal-content">
    <%= turbo_frame_tag "modal" %>
  </div></div>
</div>
```
```javascript
// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"
export default class extends Controller {
  connect() { this.modal = new bootstrap.Modal(this.element) }
  open() { if (!this.modal.isOpened) { this.modal.show() } }
  close(event) { if (event.detail.success) { this.modal.hide() } }
}
```
```erb
<%= link_to "New item", new_item_path, class: "btn btn-primary", data: { turbo_frame: "modal" } %>
```
- **Opinion / hot take:** Put the modal container once in the layout, not per-page, "so our modal pattern will work on every page" — reusability over duplication.

### Handling modal forms with Rails, Tailwind CSS, and Hotwire
- **Author:** David Colby | **URL:** https://www.colby.so/posts/handling-modal-forms-with-rails-and-hotwire
- **Summary:** A second modal approach built on the `tailwindcss-stimulus-components` `Modal` controller, extended via subclassing (`ExtendedModal extends Modal`) to add form-reset and error-clearing behavior on `turbo:submit-end`.
- **Code worth stealing:**
```javascript
// app/javascript/controllers/extended_modal_controller.js
import { Modal } from "tailwindcss-stimulus-components"
export default class ExtendedModal extends Modal {
  static targets = ["form", "errors"]
  connect() { super.connect() }
  handleSuccess({ detail: { success } }) {
    if (success) { super.close(); this.clearErrors(); this.formTarget.reset() }
  }
  clearErrors() { if (this.hasErrorsTarget) { this.errorsTarget.remove() } }
}
```
```erb
<div data-extended-modal-target="container" data-action="turbo:submit-end->extended-modal#handleSuccess" class="hidden ...">
```
- **Opinion / hot take:** Extend/subclass community Stimulus controllers instead of writing modal logic from scratch.

### Building a custom Stimulus generator for Rails
- **Author:** David Colby | **URL:** https://colby.so/posts/building-a-custom-stimulus-generator-for-rails
- **Summary:** A `rails g stimulus Thing` custom generator (Thor-based `Rails::Generators::NamedBase`) that stamps out a boilerplate controller file, tested with `Rails::Generators::TestCase`.
- **Code worth stealing:**
```ruby
# lib/generators/stimulus/stimulus_generator.rb
class StimulusGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)
  def create_controller
    template('controller.js', File.join("app/javascript/controllers/#{file_name}_controller.js"))
  end
end
```
```ruby
# lib/generators/stimulus/stimulus_generator_test.rb
class StimulusGeneratorTest < Rails::Generators::TestCase
  tests StimulusGenerator
  destination Rails.root.join('tmp/generators')
  setup :prepare_destination
  test 'It generates a controller in the app/javascript/controllers directory' do
    run_generator ["Hello"]
    assert_file "app/javascript/controllers/hello_controller.js"
  end
end
```
- **Opinion / hot take:** "Without a generator, every new Stimulus controller requires manual work" worth automating.

### Building a collapsible sidebar with Stimulus and Tailwind CSS
- **Author:** David Colby | **URL:** https://colby.so/posts/building-a-collapsible-sidebar-with-stimulus-and-tailwind
- **Summary:** Vanilla (non-Rails, CDN-loaded Stimulus) demo of `targets`-driven collapse/expand: a `data-expanded` attribute on the container tracks state, `linkTargets` get `sr-only` toggled for accessible hiding of labels, and the toggle icon's inner SVG is swapped via `innerHTML`.
- **Code worth stealing:**
```javascript
application.register("sidebar", class extends Stimulus.Controller {
  static get targets() { return [ "sidebarContainer", "icon", "link" ] }
  toggle() {
    this.sidebarContainerTarget.dataset.expanded === "1" ? this.collapse() : this.expand()
  }
  collapse() {
    this.sidebarContainerTarget.classList.remove("sm:w-1/5")
    this.sidebarContainerTarget.dataset.expanded = "0"
    this.linkTargets.forEach(link => link.classList.add("sr-only"))
  }
  expand() {
    this.sidebarContainerTarget.classList.add("sm:w-1/5")
    this.sidebarContainerTarget.dataset.expanded = "1"
    this.linkTargets.forEach(link => link.classList.remove("sr-only"))
  }
})
```
- **Opinion / hot take:** "A future developer revisiting code written with Stimulus and Tailwind can quickly [understand it]" — declarative `data-*` targets over brittle class/id selectors improve long-term maintainability.

### Building a horizontal slider with Stimulus and Tailwind CSS
- **Author:** David Colby | **URL:** https://colby.so/posts/building-a-horizontal-slider-with-stimulus-and-tailwind
- **Summary:** A CSS-scroll-snap carousel where a Stimulus controller's `IntersectionObserver` (rooted at the scroll container, `threshold: 0.5`) toggles the active-dot indicator class as slides scroll into view, and `scrollTo()` on indicator click calculates `getBoundingClientRect()` offsets to smooth-scroll to a given slide.
- **Code worth stealing:**
```javascript
initialize() {
  this.observer = new IntersectionObserver(this.onIntersectionObserved.bind(this), {
    root: this.scrollContainerTarget, threshold: 0.5
  })
  this.imageTargets.forEach(image => this.observer.observe(image))
}
onIntersectionObserved(entries) {
  entries.forEach(entry => {
    const i = this.imageTargets.indexOf(entry.target)
    entry.intersectionRatio > 0.5
      ? this.indicatorTargets[i].classList.add("bg-blue-900")
      : this.indicatorTargets[i].classList.remove("bg-blue-900")
  })
}
scrollTo() {
  const imageId = event.target.dataset.imageId
  const imageCoordinates = document.getElementById(imageId).getBoundingClientRect()
  this.scrollContainerTarget.scrollTo({ left: this.scrollContainerTarget.scrollLeft + imageCoordinates.left, top: false, behavior: "smooth" })
}
```
```css
.gallery-item { scroll-snap-align: start; }
.gallery { -webkit-overflow-scrolling: touch; scroll-snap-type: x mandatory; }
```
- **Opinion / hot take:** Explicitly drops IE11 support in favor of `IntersectionObserver`/`scrollTo` — "intentional trade-offs favoring developer experience and user experience for contemporary deployments."

### Building a simple commenting form with Stimulus.js and Rails 6
- **Author:** David Colby | **URL:** https://colby.so/posts/building-a-simple-commenting-form-with-stimulus-js-and-rails-6
- **Summary:** Pre-Turbo (rails-ujs era) pattern: form submits via `ajax:success`, a Stimulus controller listens for that event, builds a DOM node from `xhr.response`, prepends it, clears the input, and applies a CSS fade-in animation with a `setTimeout` cleanup.
- **Code worth stealing:**
```javascript
// app/javascript/controllers/comments_controller.js
export default class extends Controller {
  static targets = ["commentList", "commentBody"]
  createSuccess(event) {
    const [data, status, xhr] = event.detail
    const newComment = document.createElement("div")
    newComment.classList.add("fade-in-left")
    newComment.innerHTML = xhr.response
    this.commentListTarget.prepend(newComment)
    this.commentBodyTarget.value = ''
    setTimeout(() => newComment.classList.remove("fade-in-left"), 600)
  }
}
```
- **Opinion / hot take:** "Instead of reaching for the monster JavaScript frameworks that have become very popular in recent years, Stimulus gives you the tools to add just enough interactivity while relying on plain-old Rails and HTML as often as possible." (Historical note: this predates Turbo Streams — superseded by the Turbo-native commenting post below.)

---


### Supercharge your Stimulus controllers with Custom APIs ★★
- **Author:** Marco Roth | **Date:** Jul 27, 2023 | **URL:** https://marcoroth.dev/posts/supercharge-your-stimulus-controllers-with-custom-apis
- **Summary:** Written by a Stimulus maintainer, this is the deepest available look at Stimulus's extension mechanism. History first: Stimulus's releases are essentially defined by their APIs — 1.0 **Targets**, 2.0 **Values** + **CSS Classes**, 3.2 **Outlets** — and the syntax has been stable enough that a 1.0.0 controller still runs on 3.2.1. He then builds a brand-new **Elements API** (`static elements = { backdrop: "#backdrop", … }` → `this.backdropElement` / `this.itemElements`) to formalize the widespread ad-hoc pattern of hand-writing `get fooElement() { return document.querySelector(...) }` getters. The mechanism: Stimulus's `Controller` class has a `static blessings` array (`ClassPropertiesBlessing`, `TargetPropertiesBlessing`, `ValuePropertiesBlessing`, `OutletPropertiesBlessing`); a *blessing* is a function taking the constructor and returning property descriptors to mix in. Add your own to the array and you've extended Stimulus itself.
  **When to use Elements over Targets/Outlets** (his rules): you can't control the elements you want to reference and/or can't mark them as targets; they're outside the controller's scope but don't warrant full outlets; or the controller is deliberately meant to drive one specific page-level element independent of its own element and children.
- **Code worth stealing:**
```javascript
// The ad-hoc pattern this replaces
import { Controller } from "@hotwired/stimulus"
import tippy from "tippy.js"

export default class extends Controller {
  connect() {
    this.backdropElement.classList.remove("hidden")
    this.itemElements.forEach(element => ...)
    this.tippyElements.forEach(element => tippy(element))
  }

  get backdropElement() {
    return document.querySelector("#backdrop")
  }

  get itemElements() {
    return document.querySelectorAll(".item")
  }

  get tippyElements() {
    return document.querySelectorAll("[data-tippy]")
  }
}
```
```javascript
// The proposed API — declarative, mirrors targets/values/outlets
export default class extends Controller {
  static elements = {
    backdrop: "#backdrop",
    item: ".item",
    tippy: "[data-tippy]"
  }

  connect() {
    this.backdropElement.classList.remove("hidden")   // querySelector
    this.itemElements.forEach(element => ...)          // querySelectorAll
    this.tippyElements.forEach(element => tippy(element))
  }
}
```
```javascript
// Stimulus internals — the extension point
// @hotwired/stimulus - src/core/controller.ts
export class Controller {
  static blessings = [
    ClassPropertiesBlessing,
    TargetPropertiesBlessing,
    ValuePropertiesBlessing,
    OutletPropertiesBlessing,
  ]
  // ...
}
```
```javascript
// app/javascript/element_properties.js — your own blessing
export function ElementPropertiesBlessing(constructor) {
  const properties = {}
  // …populate with [name]Element / [name]Elements getters derived from
  //   constructor.elements, then:
  return properties
}
```
- **Opinion / hot take:** "it's the Stimulus APIs that truly make Stimulus and the releases special" — i.e. the framework's value is its small set of declarative conventions, and the right way to extend it is to add a convention, not to bolt on imperative code.

---


### Taking the Most Out of Stimulus.js
- **Author:** Matheus Richard | **Date:** July 26, 2022 | **URL:** https://thoughtbot.com/blog/taking-the-most-out-of-stimulus
- **Summary:** A patterns catalogue for writing Stimulus controllers well: (1) write general-purpose behavior controllers (`ClipboardController`) instead of one-off per-page controllers; (2) compose controllers via `this.dispatch(...)` custom events instead of coupling them directly; (3) wrap third-party libraries (Tippy) inside a controller's `connect`/`disconnect` so swapping libraries later doesn't ripple through templates; (4) use the **Values API** to make controllers configurable from data attributes instead of hardcoding; (5) use **Actions** instead of manual `addEventListener`/`removeEventListener` pairs to eliminate memory-leak bookkeeping; (6) use the **Classes API** instead of hardcoding CSS class strings in JS, especially valuable with Tailwind's multi-class idioms; (7) prefer vanilla JS over jQuery.
- **Code worth stealing:**
```javascript
class ClipboardController extends Controller {
  static targets = ['source'];

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value);
    this.dispatch('copy', {detail: {content: this.sourceTarget.value}});
  }
}
```
```html
<div data-controller="clipboard flash" data-action="clipboard:copy->flash#show" data-flash-message-param="Copied!">
  <label>
    PIN:
    <input type="text" name="pin" data-clipboard-target="source" readonly />
  </label>
  <button data-action="clipboard#copy">Copy to clipboard</button>
</div>
```
```javascript
class TooltipController extends Controller {
  static values = {message: String};

  connect() {
    this.tippyInstance = tippy(this.element, this.messageValue);
  }

  disconnect() {
    this.tippyInstance.destroy();
  }
}
```
```javascript
// Values API with defaults
export default class extends Controller {
  static values = {
    config: {type: Object, default: {input: {wait: 250}}},
  };

  initialize() {
    debounced.initialize(this.configValue);
  }
}
```
```javascript
// Actions instead of manual listeners
export default class extends Controller {
  trapFocus(event) {
    // ...
  }
}
```
```html
<details data-controller="menu" data-action="toggle->menu#trapFocus">
  <summary>Open the menu</summary>
</details>
```
```javascript
// Classes API
export default class extends Controller {
  static targets = ['element'];
  static classes = ['hidden'];

  show() {
    this.elementTarget.classList.remove(...this.hiddenClasses);
  }

  hide() {
    this.elementTarget.classList.add(...this.hiddenClasses);
  }
}
```
```html
<div data-controller="toggler" data-toggler-hidden-class="some-component--hidden">
  <span class="some-component" data-toggler-target="element">This toggles!</span>
  <button data-action="toggler#show">Show</button>
  <button data-action="toggler#hide">Hide</button>
</div>
```
- **Opinion / hot take:** "Turbo remains the primary approach for building reactive Rails applications. Stimulus handles approximately the last 10-20% of the way" — explicitly frames Stimulus as a minority-share tool. Also: "It's just sprinkles."

### Magic Responsive Tables with Stimulus and IntersectionObserver
- **Author:** Matt Swanson (guest collab with Pascal Laliberté) | **Date:** Jan 13, 2021 | **URL:** https://boringrails.com/articles/responsive-tables-stimulus-intersection-observer/
- **Summary:** Recreates Shopify Polaris's side-scrolling responsive-table nav widget (scroll-left/right buttons + column-visibility dots) in vanilla Stimulus, deliberately avoiding `window.resize`/`window.scroll` listeners in favor of the `IntersectionObserver` API. Pattern: each `<th>` is bound as a `column` target; an `IntersectionObserver` scoped to the scrollable area (`root: this.scrollAreaTarget`, `threshold: 0.99`) writes `data-is-visible` onto each column header on every intersection change; separate methods then read that dataset to toggle nav-bar visibility, indicator-dot classes, and button disabled states — all via the Stimulus `classes` API.
- **Code worth stealing:**
```js
// controllers/table_scroll_controller.js — feature-detected IntersectionObserver setup
import { Controller } from "stimulus";

function supportsIntersectionObserver() {
  return (
    "IntersectionObserver" in window ||
    "IntersectionObserverEntry" in window ||
    "intersectionRatio" in window.IntersectionObserverEntry.prototype
  );
}

export default class extends Controller {
  static targets = [
    "navBar", "scrollArea", "column", "leftButton", "rightButton", "columnVisibilityIndicator",
  ];
  static classes = ["navShown", "navHidden", "buttonDisabled", "indicatorVisible"];

  connect() {
    this.startObservingColumnVisibility();
  }

  startObservingColumnVisibility() {
    if (!supportsIntersectionObserver()) {
      console.warn(`This browser doesn't support IntersectionObserver`);
      return;
    }

    this.intersectionObserver = new IntersectionObserver(
      this.updateScrollNavigation.bind(this),
      {
        root: this.scrollAreaTarget,
        threshold: 0.99, // otherwise, the right-most column sometimes won't be considered visible in some browsers, rounding errors, etc.
      }
    );

    this.columnTargets.forEach((headingEl) => {
      this.intersectionObserver.observe(headingEl);
    });
  }

  updateScrollNavigation(observerRecords) {
    observerRecords.forEach((record) => {
      record.target.dataset.isVisible = record.isIntersecting;
    });

    this.toggleScrollNavigationVisibility();
    this.updateColumnVisibilityIndicators();
    this.updateLeftRightButtonAffordance();
  }

  disconnect() {
    this.stopObservingColumnVisibility();
  }

  stopObservingColumnVisibility() {
    if (this.intersectionObserver) {
      this.intersectionObserver.disconnect();
    }
  }
}
```
```js
scrollLeft() {
  // scroll to make visible the first non-fully-visible column to the left of the scroll area
  let columnToScrollTo = null;
  for (let i = 0; i < this.columnTargets.length; i++) {
    const column = this.columnTargets[i];
    if (columnToScrollTo !== null && column.dataset.isVisible === "true") {
      break;
    }
    if (column.dataset.isVisible === "false") {
      columnToScrollTo = column;
    }
  }

  this.scrollAreaTarget.scroll(columnToScrollTo.offsetLeft, 0);
}
```
Markup skeleton:
```html
<div data-controller="table-scroll" data-table-scroll-nav-shown-class="flex" data-table-scroll-nav-hidden-class="hidden" data-table-scroll-button-disabled-class="text-gray-200" data-table-scroll-indicator-visible-class="text-blue-600">
  <div data-table-scroll-target="navBar">
    <button data-table-scroll-target="leftButton" data-action="table-scroll#scrollLeft"><svg></svg></button>
    <% 5.times do %>
      <span class="text-gray-200" data-table-scroll-target="columnVisibilityIndicator"><svg></svg></span>
    <% end %>
    <button data-table-scroll-target="rightButton" data-action="table-scroll#scrollRight"><svg></svg></button>
  </div>
  <div class="flex flex-col mx-auto">
    <div class="overflow-x-auto" data-table-scroll-target="scrollArea">
      <table class="min-w-full">
        <thead><tr>
          <th data-table-scroll-target="column">Product</th>
          <th data-table-scroll-target="column">Price</th>
        </tr></thead>
      </table>
    </div>
  </div>
</div>
```
Full gist: https://gist.github.com/swanson/722f890c7fb495443af3f699f25e30e5 · Codepen: https://codepen.io/pascallaliberte/pen/MWjvGaj?editors=1011
- **Opinion / hot take:** "Before you completely change your application architecture to use a fancy client-side framework, see if you can get by with your existing HTML markup and a bit of Stimulus."

### Tailwind style CSS transitions with StimulusJS
- **Author:** Matt Swanson | **Date:** Jun 1, 2022 | **URL:** https://boringrails.com/articles/tailwind-style-css-transitions-with-stimulusjs/
- **Summary:** Solves the classic "you can't transition `display: none`" CSS problem using the Vue/Alpine/TailwindUI six-stage transition convention (enter/enter-from/enter-to, leave/leave-from/leave-to) expressed as Stimulus `data-transition-*` attributes. Surveys three library options — `stimulus-transitions`, `stimulus-use`'s `useTransition` mixin, and `el-transition` (framework-agnostic, ~60-line vendor-able file, `enter()`/`leave()` return Promises) — and recommends `el-transition` for its Promise-based API, letting `Promise.all()` coordinate multiple simultaneously-animating elements before finally toggling the container's `hidden` class.
- **Code worth stealing:**
```html
<!-- Tailwind transition data attributes, applied per-element -->
<div
  data-slide-over-target="backdrop"
  class="fixed inset-0 transition-opacity bg-gray-500 bg-opacity-75"
  data-transition-enter="ease-in-out duration-500"
  data-transition-enter-start="opacity-0"
  data-transition-enter-end="opacity-100"
  data-transition-leave="ease-in-out duration-500"
  data-transition-leave-start="opacity-100"
  data-transition-leave-end="opacity-0"
></div>
```
```js
import { Controller } from "@hotwired/stimulus";
import { enter, leave } from "el-transition";

export default class extends Controller {
  static targets = ["container", "backdrop", "panel", "closeButton"];

  show() {
    this.containerTarget.classList.remove("hidden");
    enter(this.backdropTarget);
    enter(this.closeButtonTarget);
    enter(this.panelTarget);
  }

  hide() {
    Promise.all([
      leave(this.backdropTarget),
      leave(this.closeButtonTarget),
      leave(this.panelTarget),
    ]).then(() => {
      this.containerTarget.classList.add("hidden");
    });
  }
}
```
- **Opinion / hot take:** el-transition wins because "it was super simple and not tied to the framework... I didn't have to rely on an external library to update for newer Stimulus releases if there are breaking changes."

### Adding keyboard shortcuts and hotkeys to StimulusJS
- **Author:** Matt Swanson | **Date:** Jul 11, 2022 | **URL:** https://boringrails.com/articles/stimulus-hotkeys-keyboard-shortcuts/
- **Summary:** Practical library survey comparing four ways to add hotkeys to a Stimulus app: `stimulus-hotkeys` (JSON bindings map as an HTML data attribute, zero controller code, but fragile); `stimulus-use`'s `useHotkeys` (React-hooks-style API, auto-unbinds on disconnect, but inflexible if you need a controller present-but-inactive); raw `hotkeys-js` used directly (full manual control over bind/unbind timing — this is what he shipped); and `github/hotkey` (`data-hotkey` attribute, battle-tested across github.com, triggers native element behavior rather than calling arbitrary JS). Notes Stimulus 3.2 later shipped built-in keyboard-event action filters, reducing the need for any of this for simple cases.
- **Code worth stealing:**
```html
<!-- stimulus-hotkeys -->
<div data-controller="hotkeys" data-hotkeys-bindings-value='{"ctrl+z, command+z": "#foo->editor#undo"}'></div>
<div id="foo" data-controller="editor"></div>
```
```js
// stimulus-use/useHotkeys
import { Controller } from "@hotwired/stimulus";
import { useHotkeys } from "stimulus-use";

export default class extends Controller {
  connect() {
    useHotkeys(this, {
      "cmd+t": [this.openPalette],
      ".": [this.editFile],
    });
  }
}
```
```js
// HotKeys.JS directly — chosen approach for fine-grained bind/unbind control
import { Controller } from "@hotwired/stimulus";
import hotkeys from "hotkeys-js";

export default class extends Controller {
  connect() {
    hotkeys("esc", () => this.doSomething());
  }

  disconnect() {
    hotkeys.unbind("esc");
  }
}
```
```html
<!-- github/hotkey -->
<button data-hotkey="Shift+?">Show help dialog</button>
<a href="/page/2" data-hotkey="j">Next</a>
<a href="/help" data-hotkey="Control+h">Help</a>
<a href="/rails/rails" data-hotkey="g c">Code</a>
<a href="/search" data-hotkey="s,/">Search</a>
```
- **Opinion / hot take:** "It really depends on what your specific hotkey needs are" — he explicitly picked the "least abstracted" option (raw HotKeys.JS) despite two Stimulus-native wrappers existing, because he needed control the wrappers didn't expose.

### Tip: Building lightweight components with Rails Helpers and Stimulus
- **Author:** Matt Swanson | **Date:** Apr 12, 2021 | **URL:** https://boringrails.com/tips/lightweight-components-with-helpers-stimulus
- **Summary:** Uses the hovercard controller from the earlier Hovercards article to show how a plain Ruby `app/helpers` module can wrap repetitive Stimulus `data-controller`/`data-action` attribute boilerplate into a named helper method taking a block — effectively hand-rolled "components" without any component library, with per-model convenience wrappers built on a shared base helper.
- **Code worth stealing:**
```ruby
# app/helpers/hovercard_helper.rb
module HovercardHelper
  # Use a helper to avoid repeating Stimulus controller attributes
  def hovercard(url, &block)
    content_tag(:div,
      "data-controller": "hovercard",
      "data-hovercard-url-value": url,
      "data-action": "mouseenter->hovercard#show mouseleave->hovercard#hide",
      &block)
  end

  # Build your own light-weight "components"
  def repo_hovercard(repo, &block)
    hovercard hovercard_repository_path(repo), &block
  end

  def user_hovercard(user, &block)
    hovercard hovercard_user_path(user), &block
  end
end
```
```erb
<%= user_hovercard(@user) do %>
  <%= link_to @user.username, @user %>
<% end %>

<%= repo_hovercard(repository) do %>
  <div class="flex items-center space-x-2">
    <svg></svg> <!-- Some icon -->
    <%= link_to repository.name, repository %>
  </div>
<% end %>
```
- **Opinion / hot take:** "if we want to change our Stimulus controller, it's all in one spot, instead of spread out across many views in the app."

### Tip: Accessing Rails environment variables from a StimulusJS Controller
- **Author:** Matt Swanson | **Date:** Jan 20, 2022 | **URL:** https://boringrails.com/tips/rails-environment-variables-stimulus-js
- **Summary:** For app-wide config values (not per-instance data suited to the Stimulus `values` API), render a `<meta name="..." content="...">` tag once in the layout `<head>` and read it via `document.head.querySelector('meta[name=...]').content` inside any controller — avoids re-passing the same value as a `data-*-value` attribute on every controller instantiation. Concrete example: exposing `Rails.env` to gate test-only behavior. Notes this is the same mechanism `@rails/request.js` uses internally to read the CSRF token meta tag.
- **Code worth stealing:**
```erb
<%= tag :meta, name: :rails_env, content: Rails.env %>
```
```js
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect() {
    if (this.isTestEnvironment) {
      // Do something for testing
    } else {
      // Do something for dev/prod
    }
  }

  get isTestEnvironment() {
    return document.head.querySelector("meta[name=rails_env]").content === "test"
  }
}
```
```js
// The same pattern request.js uses internally for the CSRF token
function metaContent (name) {
  const element = document.head.querySelector(`meta[name="${name}"]`)
  return element && element.content
}
```
- **Opinion / hot take:** Security caveat: "Remember that this data is visible in your page source!... Make sure you are only exposing data that is safe to be public."

### Connecting React.js and StimulusJS with JavaScript Events
- **Site:** blog.appsignal.com | **Authors:** Connor James and Robert Beekman | **Date:** December 18, 2023 | **URL:** https://blog.appsignal.com/2023/12/18/connecting-react-and-stimulusjs-with-javascript-events.html
- **Summary:** Short but concrete case study from AppSignal's own app: a React-rendered "Getting started" page and a Rails-rendered Stimulus settings toggle need to stay in sync without polling. Solved with plain `CustomEvent`s dispatched on `document`, listened to by both a Stimulus controller (`connect`/`disconnect` add/remove the listener) and a React `useEffect`.
- **Code worth stealing:**
```javascript
// StimulusJS side
export default class extends Controller {
  connect() {
    this.boundToggleSwitchState = this.toggleSwitchState.bind(this);
    document.addEventListener("hide_getting_started", this.boundToggleSwitchState);
  }
  disconnect() {
    document.removeEventListener("hide_getting_started", this.boundToggleSwitchState);
  }
  toggleSwitchState(event) {
    if (this.currentValue != event.detail) {
      this.currentValue = event.detail;
    }
    // ... toggle classList based on this.currentValue
  }
}
```
```javascript
// React side
useEffect(() => {
  const toggleHideGettingStarted = (event) => { /* handle state here */ };
  document.addEventListener("hide_getting_started", toggleHideGettingStarted);
  return () => document.removeEventListener("hide_getting_started", toggleHideGettingStarted);
});
```
```javascript
// Either side, to broadcast a change
const event = new CustomEvent("hide_getting_started", { detail: newValue });
document.dispatchEvent(event);
```
- **Uniqueness note:** The only post addressing Stimulus/React interop in a mixed-framework app via a `document`-level event bus, drawn from a real production incident at AppSignal itself.

### Storing Ephemeral UI State with Kredis for Rails
- **Site:** blog.appsignal.com | **Author:** Julian Rubisch | **Date:** February 22, 2023 | **URL:** https://blog.appsignal.com/2023/02/22/storing-ephemeral-ui-state-with-kredis-for-rails.html
- **Summary:** Persists collapsed/expanded state of nested `<details>` elements per-user across sessions/devices using Kredis (`kredis_set :open_department_ids` on `User`) instead of ActiveRecord columns or session storage. A Stimulus controller PATCHes the department id + open/closed boolean to a tiny `UiStateController#update` on the `toggle` event; the view rehydrates by conditionally emitting the `open` attribute from `current_user.open_department_ids.include?(dep.id)` on render.
- **Code worth stealing:**
```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  kredis_set :open_department_ids
end
```
```ruby
# app/controllers/ui_state_controller.rb
class UiStateController < ApplicationController
  def update
    if ui_state_params[:open] == "true"
      current_user.open_department_ids << params[:department_id]
    else
      current_user.open_department_ids.remove(params[:department_id])
    end
    head :ok
  end
  private
  def ui_state_params
    params.permit(:department_id, :open)
  end
end
```
```javascript
// app/javascript/controllers/ui_state_controller.js
import { Controller } from "@hotwired/stimulus";
import { patch } from "@rails/request.js";

export default class extends Controller {
  static values = { departmentId: Number };
  async toggle() {
    const body = new FormData();
    body.append("open", this.element.open);
    body.append("department_id", this.departmentIdValue);
    await patch("/ui_state/update", { body });
  }
}
```
```erb
<details
  data-controller="ui-state"
  data-action="toggle->ui-state#toggle"
  data-ui-state-department-id-value="<%= dep.id %>"
  <%= "open" if current_user.open_department_ids.include?(dep.id) %>
>
```
- **Uniqueness note:** The only post covering server-persisted (Redis-backed) UI state driven from a Stimulus controller listening to the native `<details>` `toggle` event, with server-side rehydration of the `open` attribute.

### Introducing Live Elements
- **Author:** Sam Ruby | **Date:** Mar 28, 2023 | **URL:** https://fly.io/ruby-dispatch/introducing-live-elements/
- **Summary:** Presents `stimulus-live-elements`, a generic Stimulus controller (installed via importmap) that scans the DOM for `data-action` attributes and routes arbitrary DOM events straight to server routes via `fetch`, rendering the turbo_stream response — giving Phoenix-LiveView-style "no custom JavaScript" interactivity built entirely on Turbo Streams + Stimulus primitives already in Rails. No WebSockets, no long polling. Includes a technical-appendix comparison against HTMX, StimulusReflex, CableReady, and Turbo Boost Streams.
- **Code worth stealing:**
```erb
<div>
   <%= render partial: 'header', locals: {color: "yellow"} %>
   <%= form_with data: {controller: "live-elements"} do |form| %>
     <%= form.button "blue", name: 'color',
       data: {action: {click: demo_click_path}},
       class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" %>
     <%= form.button "red", name: 'color',
       data: {action: {click: demo_click_path}},
       class: "bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded" %>
   <% end %>
</div>
```
```erb
<%# _header.html.erb %>
<%= turbo_frame_tag "header", class: "block bg-#{color}-400 mb-4" do %>
  <h1 class="font-bold text-4xl">Live button demo</h1>
<% end %>
<!-- bg-yellow-400 bg-blue-400 bg-red-400 (comment forces Tailwind to keep these classes) -->
```
```ruby
class DemoController < ApplicationController
  def button
  end

  def click
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace('header',
          render_to_string(partial: 'header', locals: {color: params[:color]}))
      }
    end
  end
end
```
```bash
bin/importmap pin @flydotio/stimulus-live-elements@0.1.0
echo 'export { default } from  "@flydotio/stimulus-live-elements"' > \
  app/javascript/controllers/live_elements_controller.js
```
```ruby
Rails.application.routes.draw do
  root "demo#button"
  post "demo/click"
end
```
```ruby
# Turbo Boost Streams — invoking arbitrary JS from a turbo_stream response
stream << turbo_stream.invoke("console.log", args: ["Hello World!"])
```
- **Opinion / hot take:** Sharp, opinionated framework comparison: StimulusReflex is "much more ambitious... think of Live Elements as training wheels and build a plan to converge over time to just StimulusReflex" if you outgrow it. Implementation detail: uses `MutationObserver` to detect new `data-action` elements and `requestIdleCallback` (falling back to `setTimeout(50)` on Safari) to sequence stream actions correctly.

### Accommodating Safari Users
- **Author:** Sam Ruby | **Date:** Oct 23, 2023 | **URL:** https://fly.io/ruby-dispatch/accommodating-safari/
- **Summary:** Practical warning that Stimulus's `static targets = [...]` (static class fields) silently fails on Safari < 14.1 — and Safari isn't evergreen, so real users are stuck on old versions for years. Rails' default import-map pipeline has no documented/sanctioned transpilation path, so the author builds a custom `assets:precompile`-enhancing Rake task that runs `esbuild` over compiled Stimulus controller JS post-precompile to transpile+minify+sourcemap down to es2020 for older Safari compatibility.
- **Code worth stealing:**
```ruby
# lib/tasks/esbuild.rake
# minify js controllers and target older browsers
Rake::Task['assets:precompile'].enhance do
  Dir.chdir 'public/assets/controllers' do
    files = Dir['*.js'] -
            Dir['*.js.map'].map {|file| File.basename(file, '.map')}

    unless files.empty?
      sh "esbuild", *files, *%w(
        --outdir=.
        --allow-overwrite
        --minify
        --target=es2020
        --sourcemap
      )
    end
  end
end
```
```dockerfile
# Install esbuild
RUN chdir /usr/local/bin && \
    curl -fsSL https://esbuild.github.io/dl/latest | sh
```
- **Opinion / hot take:** Calls out Rails' asset-pipeline choices as a deliberate obstacle: "Despite not being written in JavaScript, Rails makes you buy into the whole Node.js ecosystem if you want to use esbuild... import maps explicitly limits inputs to files that don't require transpilation... it was explicitly rejected [by the Rails team]." Frames his Rake-task workaround as "the least hacky solution I have come up with to date."

---

---

## Forms & validation


### Building a modal form with Turbo Stream GET requests and custom stream actions
- **Author:** David Colby | **URL:** https://colby.so/posts/building-modal-forms-with-turbo-streams
- **Summary:** Full custom-modal implementation independent of any component library: a body-level `data-controller="modal"` with `open`/`close`/`_backgroundHTML()` methods; "New" links carry `data: { action: "click->modal#open", turbo_stream: "" }`; `new.turbo_stream.erb` populates the modal title/body via `turbo_stream.update`; error re-renders return `status: :unprocessable_entity` with a stream replacing the form.
- **Code worth stealing:**
```javascript
// app/javascript/controllers/modal_controller.js
export default class extends Controller {
  static targets = ['container'];
  connect() {
    this.toggleClass = 'hidden'; this.backgroundId = 'modal-background';
    this.backgroundHtml = this._backgroundHTML();
  }
  open() {
    document.body.classList.add('fixed', 'inset-x-0', 'overflow-hidden');
    this.containerTarget.classList.remove(this.toggleClass);
    document.body.insertAdjacentHTML('beforeend', this.backgroundHtml);
    this.background = document.querySelector(`#${this.backgroundId}`);
  }
  close() {
    if (typeof event !== 'undefined') event.preventDefault();
    this.containerTarget.classList.add(this.toggleClass);
    if (this.background) this.background.remove();
  }
}
```
```erb
<%# app/views/cards/new.turbo_stream.erb %>
<%= turbo_stream.update "modal-title", "Add a card" %>
<%= turbo_stream.update "modal-body", partial: "form", locals: { card: @card } %>
```
```ruby
def create
  @card = Card.new(card_params)
  respond_to do |format|
    if @card.save
      format.turbo_stream
    else
      format.turbo_stream { render turbo_stream: turbo_stream.replace('card-form', partial: 'form'), status: :unprocessable_entity }
    end
  end
end
```

### Handling modal forms with Rails, Tailwind CSS, and Hotwire
(Full entry with error-target code is under Stimulus design & patterns above — cross-referenced here for its form-validation flow: errors surface in a `data-extended-modal-target="errors"` div, cleared on successful resubmit.)

### Flash messages with Hotwire (hotrails.dev)
See Turbo Rails Tutorial Chapter 7 above.

---


### Dynamic forms with Turbo
- **Author:** Sean Doyle | **Date:** February 2, 2022 | **URL:** https://thoughtbot.com/blog/dynamic-forms-with-turbo
- **Summary:** Builds a shipping-address form whose state/province options depend on the selected country, entirely through progressive enhancement stages: (1) plain HTML `<select>` reload via `<noscript><button formmethod="get" formaction="...">` (works with JS off); (2) a one-line Stimulus controller (`ElementController#click`) that auto-clicks the hidden reload button on `change`, so the round trip happens without a visible click; (3) wraps the state `<select>` in a `turbo-frame` targeted via `form.field_id(:state, :turbo_frame)`, and a `SearchParamsController` rewrites a hidden anchor's `search` (query string) with `URLSearchParams` before the Stimulus `click` controller fires it — replacing full-page reload with a frame-scoped fetch.
- **Code worth stealing:**
```ruby
# app/models/address.rb
class Address < ApplicationRecord
  with_options presence: true do
    validates :line_1
    validates :city
    validates :postal_code
  end

  validates :state, inclusion: { in: -> record { record.states.keys }, allow_blank: true },
                    presence: { if: -> record { record.states.present? } }

  def countries
    CS.countries.with_indifferent_access
  end

  def states
    CS.states(country).with_indifferent_access
  end
end
```
```erb
<fieldset class="contents" data-controller="element">
  <%= form.label :country %>
  <%= form.select :country, @address.countries.invert, {}, autocomplete: "off",
                  data: { action: "change->element#click" } %>
  <noscript>
    <button formmethod="get" formaction="<%= new_address_path %>">Select country</button>
  </noscript>
  <button formmethod="get" formaction="<%= new_address_path %>" hidden
          data-element-target="click"></button>
</fieldset>
```
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
<fieldset class="contents" data-controller="element search-params">
  <%= form.label :country %>
  <%= form.select :country, @address.countries.invert, {}, autocomplete: "off",
                  data: { action: "change->search-params#encode change->element#click" } %>
  <noscript>
    <button formmethod="get" formaction="<%= new_address_path %>">Select country</button>
  </noscript>
  <a href="<%= new_address_path %>" hidden
     data-search-params-target="anchor"
     data-element-target="click" data-turbo-frame="<%= form.field_id(:state, :turbo_frame) %>"></a>
</fieldset>

<turbo-frame id="<%= form.field_id(:state, :turbo_frame) %>" class="contents">
  <% if @address.states.any? %>
    <%= form.label :state %>
    <%= form.select :state, @address.states.invert %>
  <% end %>
  <%= turbo_stream.replace dom_id(@address), partial: "addresses/address", object: @address %>
</turbo-frame>
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
- **Opinion / hot take:** "When brainstorming a new feature, start by asking: 'How far can we get with full-page transitions, server-rendered HTML, and form submissions?' then make incremental improvements from there." — a concrete methodology, not just a slogan.

### Dynamic forms with Stimulus
- **Author:** Sean Doyle | **Date:** February 1, 2022 | **URL:** https://thoughtbot.com/blog/dynamic-forms-with-stimulus
- **Summary:** Companion piece to "Dynamic forms with Turbo," focused purely on client-side (no round trip) conditional field display: a document access-level radio group toggles which `<fieldset>` is `disabled` (the HTML disabled attribute already excludes fields from form submission, so no manual "remove this field's value" JS is needed). Builds the no-JS baseline first, then layers a `FieldsController` that listens for `input` on radio buttons and toggles fieldset `disabled` via `aria-controls` (used as the wiring mechanism instead of arbitrary data attributes — the ARIA attribute also documents the relationship for a11y tools). Extends to support `<select>` too.
- **Code worth stealing:**
```erb
<%= field_set_tag "Passcode protect", disabled: !@document.passcode_protect?, class: "disabled:hidden",
                                id: form.field_id(:access, :passcode_protected, :fieldset),
                                name: form.field_name(:access) do %>
  <%= form.label :passcode %>
  <%= form.text_field :passcode %>
<% end %>
```
```erb
<%= builder.radio_button autocomplete: "off",
                         aria: { controls: form.field_id(:access, builder.value, :fieldset) },
                         data: { action: "input->fields#enable" } %>
```
```javascript
// app/javascript/controllers/fields_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  enable({ target }) {
    const elements = Array.from(this.element.elements)
    const selectedElements = [ target ]

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
```erb
<%# select-based variant %>
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
- **Opinion / hot take:** Reiterates that the Stimulus controller "never renders" anything and "never translates changes made to the passcode field into an in-memory data store" — DOM state stays canonical, JS just flips existing HTML attributes.

### Multi-Factor Authentication for Rails With WebAuthn and Devise
- **Author:** Petr Hlavicka | **Date:** September 27, 2021 | **URL:** https://www.honeybadger.io/blog/multi-factor-2fa-authentication-rails-webauthn-devise/
- **Summary:** Implements WebAuthn passkey registration/login as three Stimulus controllers that call the browser's WebAuthn API, then POST the signed credential back to Rails via `@rails/request.js` — using `responseKind: "turbo-stream"` for registration and `window.Turbo.visit()` for the post-auth redirect on login. A separate toggle controller flips a login form between password and passwordless mode by rewriting its `data-turbo`/`data-remote`/`action` attributes at runtime.
- **Code worth stealing:**
```javascript
// app/frontend/controllers/webauthn/register_controller.js
import { Controller } from "stimulus"
import * as WebAuthnJSON from "@github/webauthn-json"
import { FetchRequest } from "@rails/request.js"

export default class extends Controller {
  static targets = ["nickname"]
  static values = { callback: String }

  create(event) {
    const [data, status, xhr] = event.detail;
    const _this = this
    WebAuthnJSON.create({ "publicKey": data }).then(async function(credential) {
      const request = new FetchRequest("post", _this.callbackValue + `?nickname=${_this.nicknameTarget.value}`, { body: JSON.stringify(credential), responseKind: "turbo-stream" })
      await request.perform()
    }).catch(function(error) {
      console.log("something is wrong", error);
    });
  }
}
```
```javascript
// app/frontend/controllers/webauthn/auth_controller.js
auth(event) {
  const [data, status, xhr] = event.detail;
  const _this = this
  WebAuthnJSON.get({ "publicKey": data }).then(async function(credential) {
    const request = new FetchRequest("post", _this.callbackValue, { body: JSON.stringify(credential) })
    const response = await request.perform()
    if (response.ok) {
      const data = await response.json
      window.Turbo.visit(data.redirect, {action: 'replace'})
    }
  })
}
```
```javascript
// app/frontend/controllers/webauthn/login_controller.js — toggles a form between password/passwordless
toggle(event) {
  event.preventDefault()
  this.passwordTarget.classList.toggle("hidden")
  this.defaultTarget.classList.toggle("hidden")
  this.webauthnTarget.classList.toggle("hidden")
  if(this.webauthn) {
    this.element.setAttribute("data-remote", true)
    this.element.setAttribute("data-turbo", false)
    this.element.setAttribute("action", this.webauthnValue)
  } else {
    this.element.setAttribute("data-remote", false)
    this.element.setAttribute("data-turbo", true)
    this.element.setAttribute("action", this.defaultActionUrl)
  }
  this.webauthn = !this.webauthn
}
```
- **Uniqueness note:** Genuinely unique — driving the native WebAuthn browser API from a Stimulus controller, then bridging back into Turbo via `responseKind: "turbo-stream"` on a raw `FetchRequest` and `window.Turbo.visit()` for a JS-initiated redirect.

### Create a Markdown Editor in Ruby on Rails
- **Site:** blog.appsignal.com | **Author:** Hans-Jörg Schnedlitz | **Date:** December 10, 2025 | **URL:** https://blog.appsignal.com/2025/12/10/create-a-markdown-editor-in-ruby-on-rails.html
- **Summary:** Builds a GitHub-style write/preview Markdown editor. A Stimulus controller POSTs the raw textarea content to a `preview` collection action with `responseKind: "turbo-stream"`, and the controller renders `turbo_stream.update("preview", @markdown)` using the Commonmarker gem. Later extends the same controller to toggle write/preview panes and to handle clipboard image paste via `@rails/activestorage`'s `DirectUpload`, inserting a Markdown image link at the cursor position with `setRangeText`.
- **Code worth stealing:**
```ruby
# app/controllers/posts_controller.rb
def preview
  require "commonmarker"
  @markdown = Commonmarker.to_html(params[:body])
  render turbo_stream: turbo_stream.update("preview", @markdown)
end
```
```javascript
// app/javascript/controllers/preview_controller.js
import { Controller } from "@hotwired/stimulus";
import { post } from "@rails/request.js";

export default class extends Controller {
  static targets = ["editorContent"];
  static values = { url: String };
  show() {
    post(this.urlValue, {
      body: { body: this.editorContentTarget.value },
      responseKind: "turbo-stream",
    });
  }
}
```
```javascript
// clipboard image upload -> insert Markdown link at cursor
import { DirectUpload } from "@rails/activestorage";

export default class extends Controller {
  static values = { url: String, uploadUrl: String };
  upload(event) {
    if (!event.clipboardData.files.length) return;
    event.preventDefault();
    Array.from(event.clipboardData.files).forEach((file) => this.#uploadFile(file));
  }
  #uploadFile(file) {
    const upload = new DirectUpload(file, this.uploadUrlValue);
    upload.create((_error, blob) => {
      const url = `/rails/active_storage/blobs/redirect/${blob.signed_id}/${encodeURIComponent(blob.filename)}`;
      const link = `![${blob.filename}](${url})\n`;
      const start = this.editorContentTarget.selectionStart;
      const end = this.editorContentTarget.selectionEnd;
      this.editorContentTarget.setRangeText(link, start, end);
    });
  }
}
```
```erb
<%= form.textarea :body,
              data: { preview_target: "editorContent", action: "paste->preview#upload" },
              %>
```
- **Uniqueness note:** Clipboard-paste-to-DirectUpload-to-inserted-Markdown-link is a specific, fully-worked technique not found in any other post in this corpus; references Rails 8.1's new Markdown content type.

---

---

## UI components


- **Author:** Jose Farias | **Repo:** https://github.com/josefarias/hotwire_combobox | **Docs + live demo:** https://hotwirecombobox.com (docs source: https://github.com/josefarias/hotwire_combobox_docs) | npm: `@josefarias/hotwire_combobox`
- **Summary:** "Easy and Accessible Autocomplete for Ruby on Rails" — a gem + Stimulus controller pair implementing a real, accessible combobox/autocomplete on top of Turbo and Stimulus. Requires turbo-rails and stimulus-rails already working. Ships customizable default styles. Supports pagination of options and multiselect. Self-described as early-stage/nearing beta with a possibly-changing API. **The important part for this repo is the accessibility posture** — it implements the [W3C APG combobox pattern](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/) and then documents its three *deliberate deviations*, which is exactly the level of rigor a component recipe should aspire to.
- **Install / config (verbatim):**
```ruby
# Gemfile
gem "hotwire_combobox"
```
```js
// Importmaps: usually zero config, since eager/lazyLoadControllersFrom picks it up.
// app/javascript/controllers/index.js should already contain one of:
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// …or lazyLoadControllersFrom("controllers", application)
```
```js
// Explicit registration alternative — app/javascript/controllers/application.js
import { Application } from "@hotwired/stimulus"
const application = Application.start()

import HwComboboxController from "controllers/hw_combobox_controller"
application.register("hw-combobox", HwComboboxController)

export { application }
```
```bash
# JS bundling (esbuild, rollup, …) — install the npm half too
yarn add @josefarias/hotwire_combobox
# or: npm install @josefarias/hotwire_combobox
```
```js
// …and register it from the package
import { Application } from "@hotwired/stimulus"
const application = Application.start()

import HwComboboxController from "@josefarias/hotwire_combobox"
application.register("hw-combobox", HwComboboxController)

export { application }
```
```erb
<%# CSS: drop the stylesheet in <head>. Accepts any stylesheet_link_tag option. %>
<%= combobox_style_tag %>
```
```
/* Sprockets alternative — app/assets/stylesheets/application.css */
*= require hotwire_combobox
```
- **Gotcha:** with JS bundling you must keep the **gem and the npm package on the same version number** — "You should always run the same version number on both sides."
- **Accessibility notes worth quoting (verbatim from the README):** it follows the APG combobox pattern "with some exceptions we feel increase the usefulness of the component without much detriment to the overall accessible experience":
  1. **Wrap-around selection** in the listbox — `Up Arrow` on the first option selects the last, `Down Arrow` on the last selects the first. In paginated comboboxes "the first and last options refer to the currently available options. More options may be loaded after navigating to the last currently available option."
  2. **An unlabeled combobox is possible**, because labeling is delegated to the implementing developer.
  3. **Multiselect has no APG guidelines** ([open W3C issue](https://github.com/w3c/aria-practices/issues/1512)); they announce multi-selections via an ARIA **live region** and explicitly solicit feedback until official guidance exists.

---

---

## Real-time, broadcasting & WebSockets


### AnyCable: Action Cable on steroids
- **Author:** Vladimir Dementyev | **Date:** 2016-12-20 | **URL:** https://evilmartians.com/chronicles/anycable-actioncable-on-steroids
- **Summary:** The original AnyCable introduction. Action Cable's broadcasting is slow and memory-hungry because it's Ruby/Rails doing low-level WebSocket connection management. AnyCable splits the architecture: a logic-less WebSocket proxy server (originally Erlang, later Go) handles sockets/subscriptions/broadcasting, while a gRPC-based RPC server (your Rails app) handles only business logic (auth, channel actions). The WS server calls three RPC methods (`Connect`, `Command`, `Disconnect`) into Rails via a `rpc.proto` gRPC service. No app objects (connections) are kept in memory on the Ruby side — everything is disposable per-request.
- **Code worth stealing:**

The gRPC service definition (`rpc.proto`):
```protobuf
service RPC {
  rpc Connect (ConnectionRequest) returns (ConnectionResponse) {}
  rpc Command (CommandMessage) returns (CommandResponse) {}
  rpc Disconnect (DisconnectRequest) returns (DisconnectResponse) {}
}
```

Standard Action Cable connection/auth code (compatible with AnyCable):
```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connected
      self.current_user = User.find_by(id: cookies[:user_id])
      reject_unauthorized_connection unless current_user
    end
  end
end
```

Chat channel (subscribe + stream):
```ruby
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:id]}"
  end
end
```

Client-side subscription (JS):
```javascript
App.cable.subscriptions.create({channel: 'ChatChannel', id: 1}, ...)
```

Broadcasting to a stream from a channel action:
```ruby
class ChatChannel < ApplicationCable::Channel
  def speak(data)
    ActionCable.server.broadcast(
      "chat_#{params[:id]}",
      text: data['text'], user_id: current_user.id
    )
  end
end
```

Naive (slow) Action Cable broadcast internals, illustrating the bottleneck:
```ruby
subscribers_map[stream_id].each do |channel|
  channel.transmit message
end
```

Setup:
```ruby
gem "anycable-rails"
```
```shell
rails g anycable:setup
```

Procfile for Overmind/Hivemind:
```yaml
web: bundle exec rails s
rpc: bundle exec anycable
go:  anycable-go --port=8080
```
- **Opinion / hot take:** "In my opinion, besides bugs, the only problem [with Action Cable] is Ruby itself — the language I'm fond of, but not considering it a technology fit for writing scalable concurrent applications." Benchmarks cited: Action Cable took ~1 second broadcast RTT for 1,000 clients and 10+ seconds for 10,000 clients — "Doesn't look real-time, does it?" AnyCable, by contrast, showed near-identical resource usage to raw Erlang/Go servers.

---

### AnyCable 1.0: Four years of real-time web with Ruby and Go
- **Author:** Vladimir Dementyev | **Date:** 2020-07-01 | **URL:** https://evilmartians.com/chronicles/anycable-1-0-four-years-of-real-time-web-with-ruby-and-go
- **Summary:** The 1.0 retrospective/release post. Major theme: making migration from Action Cable "as smooth as possible" — an interactive `rails g anycable:setup` generator, Rack middleware support (so Warden/Devise auth just works via `env["warden"]`), and a new `state_attr_accessor` API to replace instance-variable channel state (since AnyCable channels are stateless/disposable between actions, unlike Action Cable's in-memory channel objects). Also covers the AnyCable-Go rewrite from a tangled single-package Go app to a properly layered architecture, and the philosophy of building a conformance-test suite (AnyT) to keep multiple server implementations in sync with Action Cable's protocol.
- **Code worth stealing:**

Channel state persisted across actions via `state_attr_accessor` (AnyCable's one API addition to Action Cable):
```ruby
class RoomChannel < ApplicationCable::Channel
  # AnyCable API similar to attr_accessor
  state_attr_accessor :room

  def subscribed
    self.room = Room.find(params["room_id"])
    stream_for room
  end

  def speak(data)
    broadcast_to room, message: data["message"]
  end
end
```

Pre-1.0 Devise/Warden auth workaround (manual session/cookie decryption):
```ruby
# AnyCable <1.0
def connect
  self.user = find_verified_user || reject_unauthorized_connection
end

def find_verified_user
  app_cookies_key = Rails.application.config.session_options[:key] ||
                    raise("No session cookies key in config")

  env["rack.session"] = cookies.encrypted[app_cookies_key]
  Warden::SessionSerializer.new(env).fetch(:user)
end
```

Post-1.0 with Rack middleware support — now identical to a normal Action Cable app:
```ruby
# AnyCable >=1.0
def connect
  self.user = env["warden"].user(:user) || reject_unauthorized_connection
end
```

Theoretical/planned AnyCable 2.0 JS client API (design sketch, not shipped as-is at time of writing):
```js
// channels/chat.js
import { Channel } from 'anycable'

export default class extends Channel {
  static identifier = 'chat';

  fetchHistory = () => this.perform('fetchHistory')
}

// index.js
import ChatChannel from 'channels/chat'

const roomId = 42
// JS camelCased keys are automatically transformed to Ruby snake_case
// at the server side
const channel = new ChatChannel({roomId})

// All async calls are Promise-based,
// so you can use await (of course, from within an async function)
await channel.connect()

// An alternative events API
channel.on('connect', () => console.log('Connected'))

// Here is where message acks are used
const messages = await channel.fetchHistory()

// Subscribing to incoming messages
channel.on('message', message => console.log(message))
```
- **Opinion / hot take:** "Open source for the sake of open source is not fun" — the author nearly abandoned the project for a year+ due to zero production feedback. "Writing complex reliable software cannot be easy" — on why the naive/easy Go rewrite led to an unmaintainable mess, and why he had to study other real Go projects' architecture (Faktory, Centrifugo, Telegraf) to fix it. Also: "Investing in development tools pays off in the long term" re: building the AnyT conformance-test tool before building new server implementations.

---

### AnyCable Goes Pro: Fast WebSockets for Ruby, at scale
- **Author:** Vladimir Dementyev | **Date:** 2021-06-16 | **URL:** https://evilmartians.com/chronicles/anycable-goes-pro-fast-websockets-for-ruby-at-scale
- **Summary:** Announces AnyCable Pro's commercial tier on top of the OSS core. Three headline features: (1) a "goroutines pool plus epoll/kqueue" connection-handling rewrite (vs. "two goroutines per connection") cutting idle-connection memory further, especially useful on Heroku/Kubernetes-style small-instance deployments; (2) binary protocol support (Msgpack, Protocol Buffers) instead of JSON to cut bandwidth; (3) an Apollo GraphQL-compatible endpoint (`<anycable-pro-go>/graphql`) that translates Apollo subscription messages into Action Cable actions server-side, so GraphQL clients don't need to know Action Cable exists.
- **Code worth stealing:** No Ruby/JS code blocks in this article — it's feature-announcement prose plus benchmark charts. Key config/usage fact: connect a GraphQL WS transport to the `/graphql` endpoint on the AnyCable Pro Go server; no Apollo Link customization needed.
- **Opinion / hot take:** "We'll be adding Pro-only, commercial features on top of the existing codebase to help customers handle extra high load" — explicit statement of AnyCable's open-core business model, contrasted with GitHub Sponsors which "never meant to be fuel for the project development; it's just to show gratitude."

---

### Introducing JavaScript and TypeScript client for AnyCable
- **Author:** Vladimir Dementyev | **Date:** 2021-07-28 | **URL:** https://evilmartians.com/chronicles/introducing-anycable-javascript-and-typescript-client
- **Summary:** Introduces `@anycable/web` (the `anycable-client` JS/TS SDK), built to replace dependency on the stale `@rails/actioncable` package. Architecture separates Channel (pure logic) from Transport (bytes), Encoder (serialization), and Protocol (message schema) so any layer can be swapped independently — enabling binary encoders, long-polling transport, cross-tab socket sharing, etc. Also covers reconnection strategy: comparing Rails 5 (deterministic/simultaneous reconnect → "thundering herd"/"connection avalanche"), Rails 7 (exponential backoff, fixed in rails/rails#40229), Logux, and AWS's "Full Jitter" backoff — landing on a configurable `jitterWeight` formula.
- **Code worth stealing:**

Typed channel definition with typed incoming messages:
```ts
import { Channel } from "@anycable/web";

type Params = {
  roomId: string | number;
};

type TypingMessage = {
  type: "typing";
  username: string;
};

type ChatMessage = {
  type: "message";
  username: string;
  userId: string;
};

type Message = TypingMessage | ChatMessage;

export class ChatChannel extends Channel {
  static identifier = "ChatChannel";
}

// Without parameters, it would raise a type error and won't compile
let channel = new ChatChannel({ roomId: "2021" });

channel.on("message", (msg) => {
  // Here compiler knows the type of the msg
  if (msg.type === "typing") {
    // Now, compiler knows that msg is a TypingMessage and not ChatMessage
  }
});
```

Drop-in replacement for `@rails/actioncable` (Action Cable compatibility mode) — literally a one-line import swap:
```diff
- import { createConsumer } from "@rails/actioncable";
+ import { createConsumer } from "@anycable/web";

 // createConsumer accepts all the options available to createCable
 export default createConsumer();
```

Using AnyCable Pro binary encoders (Msgpack):
```js
// cable.js
import { createCable } from "@anycable/web";
import { MsgpackEncoder } from "@anycable/msgpack-encoder";

export default createCable({
  protocol: "actioncable-v1-msgpack",
  encoder: new MsgpackEncoder(),
});
```

Reconnect backoff formula (Mathematica, for reference/derivation — not runnable JS, but documents the algorithm AnyCable's JS client backoff is based on):
```mathematica
anyBackoff[attempt_, minDelay_, backoffRate_, jitterWeight_, maxDelay_] := Module[
  {fun},
  fun = Function[
    {a, md, br, jw, mx},
    left := 2 * md * (br^a);
    right := 2 * md * (br^(a + 1));
    t := Min[mx, left + (right - left) * Random[Real, 1.0]];
    dv := 2 *(Random[Real, 1.0] - 0.5) * jw;
    d := t * (1 + dv);
    If[a === 0, d, fun[a -1, md, br, jw, mx] + d]
  ];
  fun[attempt, minDelay, backoffRate, jitterWeight, maxDelay]
]
```
- **Opinion / hot take:** On the stock `@rails/actioncable` package: "[it] fully satisfies [Basecamp's] project's needs (I guess). And it lacks extensibility. How can I use a different transport? How can I change the reconnection strategy? ... the only answer was monkey-patching." On the "thundering herd"/connection-avalanche problem (all clients reconnecting simultaneously after a deploy) as a real production hazard for naive Action Cable clients pre-Rails-7.

---

### Enter AnyCable v1.4: reliable real-time features for apps of any size
- **Author:** Irina Nazarova, Vladimir Dementyev, Travis Turner | **Date:** 2023-07-14 | **URL:** https://evilmartians.com/chronicles/enter-anycable-v1-4-reliable-real-time-features-for-apps-of-any-size
- **Summary:** Major reliability release. Headline feature: "Reliable Streams" + "Resumable Sessions" — Action Cable only offers at-most-once delivery (a disconnected client silently misses broadcasts sent during the outage). AnyCable extends the Action Cable protocol with message IDs/acks so a reconnecting client can request and replay missed messages, with **zero application code changes required** if you're using the AnyCable JS client — this directly benefits Turbo Streams reliability under Hotwire. Also introduces "RPC over HTTP" mode (replacing the gRPC/HTTP2 requirement) so AnyCable's RPC server can be embedded directly inside a normal Rails/Heroku dyno with no separate service/port — dramatically simplifying Heroku and serverless deployment. Plus: long-polling fallback (Pro, for firewalled/corporate-proxy environments that block WebSockets), non-Rails Hotwire support, and OCPP (EV charger protocol) support as a case study of AnyCable's protocol-agnosticism.
- **Code worth stealing:** This is a features-announcement post; no Ruby/JS code blocks are given (mostly prose, benchmark images, and a Twitter embed). Key config facts: single-node reliability/resumability ships in the OSS version; cluster-mode reliability requires Pro. Demo reference: [anycable/anycasts_demo](https://github.com/anycable/anycasts_demo) shows "consistent Turbo Streams" using reliable streams.
- **Opinion / hot take:** "AnyCable is no longer only a performance boost for Action Cable, but an independent project providing unique and valuable features. That's why we say this is a new era for AnyCable... AnyCable has become a superset of Action Cable, expanding its capabilities." Also frames reliable delivery as now "non-negotiable" for real-time apps, positioning plain Action Cable/Pusher as inadequate by comparison. Interesting business-model aside: two v1.4 features were explicitly funded by customer pre-payment against the backlog — "this doesn't mean our entire product strategy is customer-funded... [but] this strategy can be a nice way to deal with backlog prioritization."

---

### AnyCable off Rails: connecting Twilio streams with Hanami
- **Author:** Pasha Kalashnikov, Vladimir Dementyev, Travis Turner | **Date:** 2023-03-21 | **URL:** https://evilmartians.com/chronicles/anycable-goes-off-rails-connecting-twilio-streams-with-hanami
- **Summary:** Demonstrates using AnyCable-Go as a **Go library** (not just a standalone binary) to build custom WebSocket protocol bridges — here, consuming Twilio Media Streams (phone-call audio over WebSocket) and piping them to a Vosk speech-recognition server, with all business logic delegated back to a Ruby app via AnyCable RPC. Also a full non-Rails integration case study: building the Ruby side on Hanami 2.0 + Phlex (views) + Vite Ruby (assets) + Lite Cable (Action-Cable-compatible channels without Rails) + Cable Ready (HTML-over-the-wire broadcasts, reimplemented sans ActiveSupport) + embedded NATS (pub/sub without Redis). Key architectural pattern: define a custom `Encoder` (translates wire protocol ↔ AnyCable's internal `common.Message`) and `Executor` (intercepts non-Action-Cable commands and turns them into RPC calls) to adapt any WebSocket protocol onto the AnyCable framework.
- **Code worth stealing:**

AnyCable-Go scaffold main package:
```go
func main() {
  conf := config.NewConfig()

  anyconf, err, ok := acli.NewConfigFromCLI(
    os.Args,
    acli.WithCLIName("mycable"),
    acli.WithCLIUsageHeader("MyCable, the custom AnyCable-Go build"),
    acli.WithCLIVersion(version.Version()),
    acli.WithCLICustomOptions(cli.CustomOptions(conf)),
  )

  // error handling

  if err := cli.Run(conf, anyconf); err != nil {
    fmt.Fprintf(os.Stderr, "%v", err)
    os.Exit(1)
  }
}
```

Custom WebSocket endpoint registration with custom encoder/executor:
```go
func initAnyCableRunner(appConf *config.Config, anyConf *aconfig.Config) (*acli.Runner, error) {
  opts := []acli.Option{
    acli.WithDefaultSubscriber(),
    acli.WithWebSocketEndpoint("/ws", myWebsocketHandler(appConf)),
  }

  if appConf.FakeRPC {
    opts = append(opts, acli.WithController(func(m *metrics.Metrics, c *aconfig.Config, lg *slog.Logger) (node.Controller, error) {
      return fake_rpc.NewController(lg), nil
    }))
  } else {
    opts = append(opts, acli.WithDefaultRPCController())
  }

  return acli.NewRunner(anyConf, opts)
}
```

```go
func myWebsocketHandler(config *config.Config) func(n *node.Node, c *aconfig.Config. lg *slog.Logger) (http.Handler, error) {
  return func(n *node.Node, c *aconfig.Config, lg *slog.Logger) (http.Handler, error) {
    extractor := ws.DefaultHeadersExtractor{Headers: c.RPC.ProxyHeaders, Cookies: c.RPC.ProxyCookies}

    executor := custom.NewExecutor(n)

    return ws.WebsocketHandler([]string{}, &extractor, &c.WS, lg, func(wsc *websocket.Conn, info *ws.RequestInfo, callback func()) error {
      wrappedConn := ws.NewConnection(wsc)
      session := node.NewSession(
        n, wrappedConn, info.URL, info.Headers, info.UID,
        node.WithEncoder(custom.Encoder{}), node.WithExecutor(executor),
      )

      // Invokes Authenticate RPC method
      _, err := n.Authenticate(session)

      if err != nil {
        return err
      }

      return session.Serve(callback)
    }), nil
  }
}
```

Twilio message decode struct and custom Encoder:
```go
type DecodeMessage struct {
  Event     string `json:"event"`
  StreamSID string `json:"streamSid"`

  Start StartPayload `json:"start,omitempty"`
  Media MediaPayload `json:"media,omitempty"`
  Stop  StopPayload  `json:"stop,omitempty"`
  Mark  MarkPayload  `json:"mark,omitempty"`
}
```
```go
func (Encoder) Decode(raw []byte) (*common.Message, error) {
  twMsg := &DecodeMessage{}

  if err := json.Unmarshal(raw, &twMsg); err != nil {
    return nil, err
  }

  var data interface{}

  switch twMsg.Event {
  case StartEvent:
    data = twMsg.Start
  case MediaEvent:
    data = twMsg.Media
  case MarkEvent:
    data = twMsg.Mark
  case StopEvent:
    data = twMsg.Stop
  }

  msg := common.Message{Command: twMsg.Event, Identifier: twMsg.StreamSID, Data: data}

  return &msg, nil
}
```

Executor skeleton translating Twilio events into commands:
```go
// Handling Twilio events and transforming them into Action Cable commands
type Executor struct {
  node node.AppNode
  conf *config.Config
}

// HandleCommand is reponsible for handling incoming messages; here msg has been decoded
// with the Twilio encoder
func (ex *Executor) HandleCommand(s *node.Session, msg *common.Message) error {
  // ...
  if msg.Command == StartEvent {
    // ...
  }

  if msg.Command == MediaEvent {
    // ...
  }

  // Ignore everything else
  return nil
}
```

Vosk gRPC streaming client (`KickOff`):
```go
func (s *Streamer) KickOff(ctx context.Context) error {
  // ...
  conn, _ := grpc.NewClient(s.config.VoskRPC, dialOptions...)
  s.client = vosk.NewSttServiceClient(conn)

  stream, _ := s.client.StreamingRecognize(cancelCtx)

  stream.Send(&vosk.StreamingRecognitionRequest{
    StreamingRequest: &vosk.StreamingRecognitionRequest_Config{
      Config: &vosk.RecognitionConfig{
        Specification: &vosk.RecognitionSpec{
          SampleRateHertz: 8000,
          PartialResults:  s.config.PartialRecognize,
        },
      },
    },
  })

  s.stream = stream

  go s.readFromStream()

  return nil
}
```

Reading recognition results back:
```go
func (s *Streamer) readFromStream() {
  for {
    resp, err := s.stream.Recv()

    if err == nil {
      chunk := resp.GetChunks()[0]
      alt := chunk.Alternatives[0]

      if alt.Text == "" && chunk.Final {
        s.log.Debug("recognition completed")
        break
      }

      if alt.Text != "" {
        s.sendResultFunction(&Response{Message: alt.Text, Final: chunk.Final, Event: "transcript"})
      }
    } else {
      // error handling
      break
    }
  }

  s.conn.Close()
}
```

Buffering audio before pushing to Vosk:
```go
func (s *Streamer) Push(msg *Packet) error {
  s.buf.Write(msg.Audio)

  if s.buf.Len() > bytesPerFlush {
    s.stream.Send(&vosk.StreamingRecognitionRequest{
      StreamingRequest: &vosk.StreamingRecognitionRequest_AudioContent{
        AudioContent: s.buf.Bytes(),
      },
    }

    s.buf.Reset()
  }

  return nil
}
```

Handling the "media" event, decoding base64 mulaw audio:
```go
if msg.Command == MediaEvent {
  twilioMsg := msg.Data.(MediaPayload)

  var t *streamer.Streamer

  if rawStreamer, ok := s.ReadInternalState("streamer"); ok {
    t = rawStreamer.(*streamer.Streamer)
  }

  audioBytes, _ := base64.StdEncoding.DecodeString(twilioMsg.Payload)

  err = t.Push(&streamer.Packet{Audio: g711.DecodeUlaw(audioBytes)})

  return err
}
```

Authentication via RPC + header injection on the session, plus channel subscribe:
```go
if msg.Command == StartEvent {
  start, _ok := msg.Data.(StartPayload)

  // We add account SID as a header to the sesssion.
  // So, we can access it via request.headers['x-twilio-account'] in Ruby.
  s.GetEnv().SetHeader("x-twilio-account", start.AccountSID)
  res, err := ex.node.Authenticate(s)

  if err != nil {
    return err
  }

  // We need to perform an additional RPC call to initialize the channel subscription
  // and notify about the call start.
  ex.node.Subscribe(s, &common.Message{Identifier: channelId(start.CallSID), Command: "subscribe"})

  ex.initStreamer(s, start.CallSID)

  return nil
}
```

Streamer init with RPC callback (`node.Perform`):
```go
func (ex *Executor) initStreamer(s *node.Session, sid string) error {
  identifier := channelId(sid)

  st := streamer.NewStreamer(ex.conf, s.Log)

  st.OnResponse(func(response *streamer.Response) {
    _, performError := ex.node.Perform(s, &common.Message{
      Identifier: identifier,
      Command:    "message",
      Data: string(
        utils.ToJSON(map[string]interface{}{
          "action": "handle_message",
          "result": response,
        })),
    })
  })

  st.KickOff(context.Background())

  s.WriteInternalState("streamer", st)

  return nil
}
```

Testing via `wsdirector` (WebSocket scenario fixture player, avoids needing real Twilio calls):
```sh
wsirector -f etc/fixtures/wsdirector/ruby.yml -u ws://localhost:8080/streams
```

Hanami app bootstrap:
```sh
$ hanami new kaisen
```

Phlex view class (Ruby-as-HTML, includes `stream_from` custom helper):
```ruby
class Show < View
  option :call_sid, optional: true
  option :phone, optional: true

  def template
    div(class: "min-w-full flex flex-row") do
      div(class: "w-1/3 border-r border-red-100 mr-4") do
        a(href: path_for(:calls)) { h2(class: "font-bold text-2xl mb-5") { "Calls" } }

        render Form.new(phone:)

        hr(class: "border-red-100 mt-2")

        div(id: "calls", class: "pr-2") do
          stream_from("calls")
        end
      end

      render Events.new(call_sid:)
    end
  end
end
```

Base Phlex view class with Hanami route helper:
```ruby
module Kaisen
  class View < Phlex::HTML
    extend Dry::Initializer

    private

    def path_for(...) = ::Hanami.app["routes"].path(...)
  end
end
```

Action class rendering a Phlex view:
```ruby
module Calls
  class Show < Kaisen::Action
    def handle(request, response)
      call_sid = request.params[:id]
      response.body = phlex(locals: {call_sid:})
    end
  end
end
```

Vite helpers built on Phlex (`vite_client`, `vite_javascript`):
```ruby
def vite_client
  return unless src = vite_manifest.vite_client_src

  script(src: src, type: "module")
end

def vite_javascript(name, **options)
  entries = vite_manifest.resolve_entries(*name, type: :javascript)
  return unless entries

  entries.first.last.each do |src|
    script(src:, **options)
  end
end
```

Hanami CSP config to allow Vite dev server assets:
```ruby
environment :development do
  # Allow @vite/client to hot reload changes in development
  config.actions.content_security_policy[:script_src] += " 'unsafe-eval' 'unsafe-inline'"
  config.actions.content_security_policy[:connect_src] += " ws://#{ ViteRuby.config.host_with_port }"
  config.actions.content_security_policy[:style_src] += " 'unsafe-eval'"
end
```

Rack middleware for Vite dev proxy / static assets:
```ruby
environment :development do
  config.middleware.use(ViteRuby::DevServerProxy) if ViteRuby.run_proxy?
  config.middleware.use Rack::Static, { urls: ["/vite-dev/"], root: "public" }
end
```

Client-side Cable Ready + AnyCable client wiring (framework-agnostic, no Rails needed):
```js
import CableReady from 'cable_ready';
import { createConsumer } from "@anycable/web";

const consumer = createConsumer();
CableReady.initialize({ consumer });
```

Re-implementing Cable Ready's signed-stream verifier without ActiveSupport (Base64 + raw OpenSSL HMAC):
```ruby
class StreamName
  def signed(name)
    data = ::Base64.strict_encode64(name.to_json)
    digest = generate_digest(data)
    "#{data}--#{generate_digest(data)}"
  end

  private

  def generate_digest(data)
    require "openssl" unless defined?(OpenSSL)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, ::Hanami.app["settings"][:cable_ready_sign_key], data)
  end
end
```

Hanami provider registering Cable Ready broadcaster + stream-name signer as app dependencies:
```ruby
Hanami.app.register_provider(:cable_ready) do
  prepare do
    require "cable_ready/hanami"
  end

  start do
    broadcaster = Kaisen::CableReady::Hanami::Broadcaster.new
    stream_name = Kaisen::CableReady::Hanami::StreamName.new

    register "cable_ready", broadcaster
    register "cable_ready_stream_name", stream_name
  end
end
```

Consuming the broadcaster as an injected dependency (Hanami `Deps`):
```ruby
class MyClass
  include Deps["cable_ready"]

  def broadcast_something = cable_ready.action(...).broadcast_to("test")
end
```

Registering `<cable-ready-stream-from>` as a Phlex custom element + `stream_from` helper (equivalent of Turbo's `turbo_stream_from`):
```ruby
class View < Phlex::HTML
  register_element :cable_ready_stream_from

  private

  def stream_from(name)
    cable_ready_stream_from(identifier: ::Hanami.app["cable_ready_stream_name"].signed(name))
  end
end
```

Embedded NATS as pub/sub backend (no Redis needed), via env vars:
```sh
# .env
ANYCABLE_EMBED_NATS=true
ANYCABLE_BROADCAST_ADAPTER=nats
```

Hanami settings config wiring the broadcast adapter:
```ruby
# config/settings.rb
module Kaisen
  class Settings < Hanami::Settings
    # ...
    setting :anycable_broadcast_adapter, default: "nats", constructor: Types::String
  end
end
```

Lite Cable connection class (Action-Cable-compatible, but Rails-free) authenticating via a custom header:
```ruby
class Connection < LiteCable::Connection::Base
  def connect
    sid = request.env["HTTP_X_TWILIO_ACCOUNT"]
    return unless sid

    twilio_account_sid = Hanami.app["settings"].twilio_account_sid
    reject_unauthorized_connection unless sid == twilio_account_sid
  end
end
```

Lite Cable channel broadcasting Cable Ready DOM operations in response to RPC-driven events:
```ruby
class Twilio < Channel
  def subscribed
    cable_ready.append(
      selector: "#calls",
      html: render_call(call_sid:)
    ).broadcast_to("calls")

    cable_ready.append(
      selector: "#events",
      html: render_event(text: "Call started", event_type: "start")
    ).broadcast_to("call_#{call_sid}")
  end

  def unsubscribed
    # ...
  end

  def handle_message(data)
    data.fetch("result").values_at("id", "text", "event") => id, text, event_type

    cable_ready.append_or_replace(
      selector: "#events",
      target: "#event_#{id}",
      html: render_event(id:, text:, event_type:)
    ).broadcast_to("call_#{call_sid}")
  end

  private

  def call_sid = params["sid"]

  def render_event(**)
    Views::Calls::Show::Event.new(**).call
  end

  def render_call(**)
    Views::Calls::Show::Call.new(**).call
  end
end
```
- **Opinion / hot take:** "Using AnyCable as a framework for building a real-time service simplifies the integration of this service with the existing Ruby/Rails application and helps keep business-logic in one place" — i.e., keep the Go layer as dumb/thin as possible, push everything into Ruby via RPC. Also frames AnyCable's core motto as "connect everyone with anything" and explicitly treats WebSockets between two servers ("WebSocketHooks") as a category as legitimate as webhooks.

---

### Hey, AnyCable speaking! Needing help with a Twilio-OpenAI connection?
- **Author:** Vladimir Dementyev, Travis Turner | **Date:** 2024-11-12 | **URL:** https://evilmartians.com/chronicles/anycable-speaking-needing-help-with-a-twilio-openai-connection
- **Summary:** Follow-up to the Hanami/Twilio post, now building a **bidirectional** voice AI assistant: Rails app + AnyCable-Go bridging Twilio Media Streams to OpenAI's Realtime API (WebSocket-based, direct audio-to-LLM, no separate STT step). Covers: sending Twilio-formatted TTS audio from a Rails channel via `#transmit`; handling DTMF (keypad) events via AnyCable's `Perform` RPC interface; initializing and managing an OpenAI Realtime WebSocket session from a Go `agent` package (session config, audio format conversion to g711_ulaw, transcription via whisper-1); wiring OpenAI function-calling ("tools") back to Ruby methods via RPC `reply_with`; and a neat Ruby metaprogramming closer that auto-generates OpenAI tool JSON schemas from `tool def` annotated methods with RBS type signatures.
- **Code worth stealing:**

Directory layout showing where cable/Rails logic each live:
```sh
app/
  channels/twilio/ # <- where all the call management logic lives
    application_connection.rb
    media_stream_channel.rb
  controllers/
    twilio/
      status_controller.rb        # <- handles Twilio webhooks
    phone_calls_controller.rb     # <- call monitoring dashboard
    # ...
  models/
  # ...
cable/             # <- where our AnyCable application lives
  cmd/
  internal/
  pkg/
    cli/
    twilio/
      encoder.go   # <- converts Twilio protocol to AnyCable protocol
      executor.go  # <- controls media streams
      twilio.go    # <- Twilio message format structs
# ...
```

Action Cable channel modeling call lifecycle:
```ruby
module Twilio
  class MediaStreamChannel < ApplicationChannel
    # Called whenever a media stream has started
    # (i.e., a call has started)
    def subscribed
      broadcast_call_status "active"
      broadcast_log "Media stream has started"
    end

    # Called whenever a media stream has disconnected
    # (i.e., a call has finished)
    def unsubscribed
      broadcast_log "Media stream has stopped"
      broadcast_call_status "completed"
    end
  end
end
```

Go executor handling the "start" event: authenticate, subscribe to channel:
```go
func (ex *Executor) HandleCommand(s *node.Session, msg *common.Message) error {
	// ...

	// This message is sent to indicate the start of the media stream
	if msg.Command == StartEvent {
		start := msg.Data.(StartPayload)

		// Mark as authenticated and store the identifiers
		callSid := start.CallSID
		streamSid := start.StreamSID
		identifiers := string(utils.ToJSON(map[string]string{"call_sid": callSid, "stream_sid": streamSid}))

		// Make call ID and stream ID available to the Rails app
		// as connection identifiers
		ex.node.Authenticated(s, identifiers)

		// Subscribe the stream session to the MediaStreamChannel.
		// That would trigger the #subscribed callback.
		identifier := `{"channel":"Twilio::MediaStreamChannel"}`
		ex.node.Subscribe(s, &common.Message{Identifier: identifier, Command: "subscribe"})

		return nil
	}

	// This message carries the actual audio data.
	// We'll talk about it later.
	if msg.Command == MediaEvent {
		// ...
	}

	// ...

	return fmt.Errorf("unknown command: %s", msg.Command)
}
```

Twilio status webhook controller returning TwiML to start a media stream:
```ruby
module Twilio
  class StatusController < ApplicationController
    def create
      def create
        status = params[:CallStatus]

        broadcast_call_status status

        if status == "ringing"
          return render plain: setup_stream_response, content_type: "text/xml"
        end

        head :ok
      end

      private

      def setup_stream_response
        Twilio::TwiML::VoiceResponse.new do |r|
          r.connect do
            _1.stream(url: TwilioConfig.stream_callback)
          end
          r.say(message: "I'm sorry, I cannot connect you at this time.")
        end.to_s
      end
    end
  end
end
```

Sending audio to a Twilio stream via plain `#transmit` (works transparently over WebSocket):
```ruby
class Twilio::MediaStreamChannel < ApplicationChannel
  GREETING = "Hi, let's see what's on your plate..."

  def subscribed
    # ...
    payload = generate_twilio_audio(GREETING)

    transmit({
      event: "media",
      streamSid: stream_sid, # provided via connection identifiers
      media: {
        payload:
      }
    })
  end
end
```

OpenAI TTS request (ruby-openai gem):
```ruby
audio = client.audio.speech(
  parameters: {
    model: "tts-1-hd",
    input: phrase,
    voice: "echo",
    response_format: "pcm"
  }
)
```

Full audio pipeline: TTS → resample → mu-law encode → base64:
```ruby
def generate_twilio_audio(input, voice: "alloy")
  client.audio.speech(
    parameters: {
      model: "tts-1-hd",
      input:,
      voice:,
      response_format: "pcm"
    }
  ).then { resample_audio(_1) }
    .then { G711.encode_ulaw(_1).pack("C*") }
    .then { Base64.strict_encode64(_1) }
end

def resample_audio(payload)
  samples = payload.unpack("C*")
  new_samples = []
  # The simplest resampling algorithm: just drop samples.
  # The quality turned out to be good enough for phone calls.
  (0..(samples.size - 1)).step(3) do |i|
    new_samples << samples[i]
  end
  new_samples
end
```

DTMF handling — Go side turns keypad digit into an RPC "perform" call:
```go
func (ex *Executor) HandleCommand(s *node.Session, msg *common.Message) error {
  // ...

	if msg.Command == DTMFEvent {
		dtfm := msg.Data.(DTMFPayload)
		ex.performRPC(s, "handle_dtmf", map[string]string{"digit": dtfm.Digit})

		return nil
	}

	// ...
}

func (ex *Executor) performRPC(s *node.Session, action string, data map[string]string) (error) {
	data["action"] = action
	payload := utils.ToJSON(data)
	identifier := channelId(s)

	_, err := ex.node.Perform(s, &common.Message{
		Identifier: identifier,
		Command:    "message",
		Data:       string(payload),
	})

	return err
}
```

Ruby side handling the DTMF-driven `handle_dtmf` action:
```ruby
class Twilio::MediaStreamChannel < ApplicationChannel
  def handle_dtmf(data)
    digit = data["digit"].to_i
    broadcast_log "< Pressed ##{digit}"

    todos, period =
      case digit
      when 1 then [Todo.for_today, "today"]
      when 2 then [Todo.for_tomorrow, "tomorrow"]
      when 3 then [Todo.for_week, "this week"]
      end

    return unless todos

    phrase = if todos.any?
      "Here is what you have for #{period}:\n#{todos.map(&:description).join(",")}"
    else
      "You don't have any tasks for #{period}"
    end

    transmit_message(phrase)
  end
end
```

Kicking off an OpenAI Realtime agent right after channel subscription:
```go
func (ex *Executor) HandleCommand(s *node.Session, msg *common.Message) error {
	// ...

	if msg.Command == StartEvent {
		// Channel subscription logic

		// If subscribed successfully, initialize an AI agent
		ex.initAgent(s)

		return nil
	}

	// ...
}

func (ex *Executor) initAgent(s *node.Session) error {
	// Retrieve AI configuration from the main app
	res, err := ex.performRPC(s, "configure_openai", nil)

	// We send configuration as a JSON string
	var data OpenAIConfigData
	json.Unmarshal(res.Data, &data)

	conf := agent.NewConfig(data.APIKey)

	agent := agent.NewAgent(conf, s.Log)
	// KickOff establishes an OpenAI WebSocket connection
	agent.KickOff(context.Background())
	// Keep the agent struct in the session state for future uses
	// (i.e., to send audio or to terminate the agent)
	s.WriteInternalState("agent", agent)

	return nil
}
```

Ruby channel action supplying OpenAI config via `reply_with` (sends data back to the Go app, not to the client):
```ruby
class Twilio::MediaStreamChannel < ApplicationChannel
  def configure_openai
    config = OpenAIConfig

    reply_with("openai.configuration", {api_key: config.api_key})
  end
end
```

Full Go `Agent` struct managing the OpenAI Realtime WebSocket connection:
```go
package agent

type Agent struct {
	conn   *websocket.Conn
	sendCh chan []byte
	log *slog.Logger
}

func NewAgent(c *Config, l *slog.Logger) *Agent {
	return &Agent{
		// ...
	}
}

func (a *Agent) KickOff(ctx context.Context) error {
	// Prepare connection parameters
	url := a.conf.URL + "?model=" + a.conf.Model
	header := http.Header{
		"Authorization": []string{"Bearer " + a.conf.Key},
		"OpenAI-Beta":   []string{"realtime=v1"},
	}

	// Establish a WebSocket connection
	conn, _, err := websocket.DefaultDialer.Dial(url, header)
	a.conn = conn

	// Send session.update message to configure the session
	sessionConfig := map[string]interface{}{
		"type": "session.update",
		"session": map[string]interface{}{
			"input_audio_format":  "g711_ulaw",
			"output_audio_format": "g711_ulaw",
			"input_audio_transcription": map[string]string{
				"model": "whisper-1",
			},
		},
	}

	configMessage := utils.ToJSON(sessionConfig)
	a.sendMsg(configMessage)

	// Set up reading and writing go routines
	go a.readMessages()
	go a.writeMessages()

	return nil
}

type Event struct {
	Type string `json:"type"`
}

func (a *Agent) readMessages() {
	for {
		_, msg, err := a.conn.ReadMessage()
		typedMessage := Event{}
		json.Unmarshal(msg, &typedMessage)

		switch typedMessage.Type {
		case "session.created":
		// many other event types
		case "response.done":
		case "error":
			a.log.Error("server error", "err", string(msg))
		}
	}
}

func (a *Agent) writeMessages() {
	for {
		select {
		case msg := <-a.sendCh:
			if err := a.conn.WriteMessage(websocket.TextMessage, msg); err != nil {
				return
			}
		}
	}
}

func (a *Agent) sendMsg(msg []byte) {
	a.sendCh <- msg
}
```

Propagating Twilio "media" audio into the agent:
```go
func (ex *Executor) HandleCommand(s *node.Session, msg *common.Message) error {
	// ...
	if msg.Command == MediaEvent {
		twilioMsg := msg.Data.(MediaPayload)

		// Ignore robot streams
		if twilioMsg.Track == "outbound" {
			return nil
		}

		audioBytes := base64.StdEncoding.DecodeString(twilioMsg.Payload)

		ai := ex.getAI(s)
		ai.EnqueueAudio(audioBytes)

		return nil
	}
}
```

Agent-side audio buffering before sending to OpenAI:
```go
func (a *Agent) EnqueueAudio(audio []byte) {
	a.buf.Write(audio)

	if a.buf.Len() > bytesPerFlush {
		a.sendAudio(a.buf.Bytes())
		a.buf.Reset()
	}
}

func (a *Agent) sendAudio(audio []byte) {
	encoded := base64.StdEncoding.EncodeToString(audio)

	msg := []byte(`{"type":"input_audio_buffer.append","audio": "` + encoded + `"}`)
	a.sendMsg(msg)
}
```

Reading OpenAI Realtime response events (audio deltas, transcripts):
```go
func (a *Agent) readMessages() {
	for {
		// ...
		switch typedMessage.Type {
		case "response.audio.delta":
			var event *AudioDeltaEvent
			json.Unmarshal(msg, &event)

			a.audioHandler(event.Delta, event.ItemId)
		case "conversation.item.input_audio_transcription.completed":
			var event *InputAudioTranscriptionCompletedEvent
			_ = json.Unmarshal(msg, &event)

			a.transcriptHandler("user", event.Transcript, event.ItemId)
		case "response.audio_transcript.delta":
			var event *AudioTranscriptDeltaEvent
			json.Unmarshal(msg, &event)

			a.transcriptHandler("assistant", event.Delta, event.ItemId)
		case "response.audio_transcript.done":
			var event *AudioTranscriptDoneEvent
			json.Unmarshal(msg, &event)

			a.transcriptHandler("assistant", event.Transcript, event.ItemId)
		}
	}
}
```

Wiring transcript/audio handlers, sending audio straight to the media stream socket:
```go
func (ex *Executor) initAgent(s *node.Session) error {
	// ...

	agent := agent.NewAgent(conf, s.Log)

	agent.HandleTranscript(func(role string, text string, id string) {
		ex.performRPC(s, "handle_transcript", map[string]string{"role": role, "text": text, "id": id})
	})

	agent.HandleAudio(func(encodedAudio string, id string) {
		val := s.ReadInternalState("streamSid")
		streamSid := val.(string)

		s.Send(&common.Reply{Type: MediaEvent, Message: MediaPayload{Payload: encodedAudio}, Identifier: streamSid})
	})

	// ...

	return nil
}
```

Populating session `instructions` (system prompt) from Ruby config:
```ruby
def configure_openai
  config = OpenAIConfig

  reply_with("openai.configuration", {api_key: config.api_key, prompt: config.prompt})
end
```
```diff
 sessionConfig := map[string]interface{}{
			 "type": "session.update",
			 "session": map[string]interface{}{
+			 "instructions": a.conf.Prompt,
				 "input_audio_format":  "g711_ulaw",
				 "output_audio_format": "g711_ulaw",
				 "input_audio_transcription": map[string]string{
					 "model": "whisper-1",
				 },
			 },
		 }
```

Example guardrail system prompt for a task-scoped voice assistant:
```txt
You are a voice assistant focused solely on weekly planning and task management.
Your only purpose is to help users manage their todos within the app.

Core functions:
- Browse tasks (today, tomorrow, this week)
- Add new tasks
- Mark tasks complete

Response rules:
- Keep responses under 2 sentences
- Always use function calls for actions
- Confirm actions with brief acknowledgments
- Stay strictly within app features

Do not:
- Suggest features not in the app
- Discuss topics unrelated to tasks/planning
- Give advice beyond task management
- Engage in general conversation
- Make promises about future features
- Explain your limitations or nature

Example responses:
- "You have no tasks today. Congrats!"
- "Added 'Dentist appointment' to Thursday. Need anything else?"
- "Task marked complete. You have 4 remaining today."
```

Manually-defined OpenAI function-calling tool schemas sent via `session.update`:
```ruby
def configure_openai
  config = OpenAIConfig

  tools = [
    {
      type: "function",
      name: "get_tasks",
      description: "Fetch user's tasks for a given period of time",
      parameters: {
        type: "object",
        properties: {
          period: {
            type: "string",
            enum: ["today", "tomorrow", "week"]
          }
        },
        required: ["period"]
      }
    },
    {
      type: "function",
      name: "create_task",
      description: "Create a new task for a specified date",
      parameters: {
        # ...
      }
    },
    {
      type: "function",
      name: "complete_task",
      description: "Mark a task as completed",
      parameters: {
        # ...
      }
    }
  ].to_json

  reply_with("openai.configuration", {api_key: config.api_key, prompt: config.prompt, tools:})
end
```

Go side handling `function_call` output items and relaying results back into the conversation:
```go
// pgk/agent/agent.go
func (a *Agent) readMessages() {
	for {
		// ...
		switch typedMessage.Type {
		case "response.output_item.done":
			var event *OutputItemDoneEvent
			json.Unmarshal(msg, &event)
			item := event.Item

			if item.Type == "function_call" {
  			a.functionHandler(item.Name, item.Arguments, item.CallID)
			}
		}
	}
}

func (a *Agent) HandleFunctionCallResult(callID string, data string) {
	item := &Item{Type: "function_call_output", CallID: callID, Output: data}
	msg := struct {
		Type string `json:"type"`
		Item *Item  `json:"item"`
	}{"conversation.item.create", item}

	encoded := utils.ToJSON(msg)
	a.sendMsg(encoded)
	// Send `response.create` message right away to trigger model inference
	a.sendMsg([]byte(`{"type":"response.create"}`))
}

// pgk/twilio/executor.go
agent.HandleFunctionCall(func(name string, args string, id string) {
	res, err := ex.performRPC(s, "handle_function_call", map[string]string{"name": name, "arguments": args})

	if res != nil && res.Event == "openai.function_call_result" {
		agent.HandleFunctionCallResult(id, string(res.Data))
	}
})
```

Ruby handling of OpenAI tool calls via pattern matching:
```ruby
def handle_function_call(data)
  name = data["name"]
  args = JSON.parse(data["arguments"], symbolize_names: true)

  case [name, args]
  in "get_tasks", {period: "today" | "tomorrow" | "week" => period}
    range = case period
    when "today"
      Date.current.all_day
    when "tomorrow"
      Date.tomorrow.all_day
    when "week"
      Date.current.all_week
    end

    todos = Todo.incomplete.where(deadline: range).as_json(only: [:id, :deadline, :description])

    reply_with("openai.function_call_result", {todos:})
  in "create_task", {date: String => deadline, description: String => description}
    todo = Todo.new(deadline:, description:)
    if todo.save
      reply_with("openai.function_call_result", {status: :created, todo: todo.as_json(only: [:id, :deadline, :description])})
    else
      reply_with("openai.function_call_result", {status: :failed, message: todo.errors.full_messages.join(", ")})
    end
  in "complete_task", {id: Integer => id}
    todo = Todo.find_by(id:)
    if todo
      todo.update!(completed: true)
      reply_with("openai.function_call_result", {status: :completed})
    else
      reply_with("openai.function_call_result", {status: :failed, message: "Task not found"})
    end
  end
end
```

Bonus: metaprogramming-based `tool def` DSL to auto-derive OpenAI function schemas from RBS-annotated Ruby methods (avoids hand-written JSON schema duplication):
```ruby
def configure_openai
  # ...
  tools = self.class.openai_tools_schema.to_json

  reply_with("openai.configuration", {api_key:, voice:, prompt:, tools:})
end

def handle_function_call(data)
  name = data["name"].to_sym
  return unless self.class.openai_tools.include?(name)

  args = JSON.parse(data["arguments"], symbolize_names: true)

  result = public_send(name, **args)
  reply_with("openai.function_call_result", result)
end

# Fetch user's tasks for a given period of time.
# @rbs (period: (:today | :tomorrow | :week)) -> Array[Todo]
tool def get_tasks(period:)
  range = case period
  when "today"
    Date.current.all_day
  when "tomorrow"
    Date.tomorrow.all_day
  when "week"
    Date.current.all_week
  end

  {todos: Todo.incomplete.where(deadline: range).as_json(only: [:id, :deadline, :description])}
end

# Create a new task for a specified date
# @rbs (deadline: Date, description: String) -> {status: (:created | :failed), ?todo: Todo}
tool def create_task(deadline:, description:)
  todo = Todo.new(deadline:, description:)
  if todo.save
    {status: :created, todo: todo.as_json(only: [:id, :deadline, :description])}
  else
    {status: :failed, message: todo.errors.full_messages.join(", ")}
  end
end

# Mark a task as completed
# @rbs (id: Integer) -> {status: (:completed | :failed), ?message: String}
tool def complete_task(id:)
  todo = Todo.find_by(id: id)
  if todo
    todo.update!(completed: true)
    {status: :completed}
  else
    {status: :failed, message: "Task not found"}
  end
end
```
- **Opinion / hot take:** "When building applications with AnyCable, we try to delegate as much logic as possible to the main app... we keep the realtime server as 'dumb' as possible, meaning we can launch it once and forget it." On hand-written OpenAI tool schema boilerplate: "it makes me sad. The amount of boilerplate is far beyond what I expected... If I wanted to write like this, I'd have chosen Go (oh, wait...)." Guardrails framed as a hard requirement for production voice AI, not optional: "we must be very cautious about what is being said... true story" (re: an AI asking a customer their pet's name).

---

### AnyCable for Laravel: reliable WebSocket infrastructure
- **Author:** Vladimir Dementyev, Irina Nazarova | **Date:** 2025-07-29 | **URL:** https://evilmartians.com/chronicles/anycable-for-laravel
- **Summary:** AnyCable expands beyond Ruby to PHP/Laravel (as a "return the favor" to Inertia.js, which came from the Laravel world into Rails). Ships `anycable-laravel` (server-side broadcaster package) and `@anycable/echo` (a Laravel Echo-compatible JS broadcaster driver), so migration is purely config-level — no app code changes. Benchmarked head-to-head against Laravel Reverb on connection-avalanche resilience and broadcast latency using a demo chat app called Larachat (React + Inertia.js + Laravel + SQLite). Same reliable-streams/resumable-sessions pitch as the Rails v1.4 article, now for Laravel.
- **Code worth stealing:**

Wiring Laravel Echo to use AnyCable as the broadcaster, in place of Reverb/Pusher:
```js
import Echo from "laravel-echo";
import { EchoCable } from "@anycable/echo";

window.Echo = new Echo({
  broadcaster: EchoCable,
  cableOptions: {
    url: url: import.meta.env.VITE_WEBSOCKET_URL || 'ws://localhost:8080/cable',
  },
  // other configuration options such as auth, etc
});
```

(Article states the server-side change is just setting `BROADCAST_CONNECTION=anycable`, backed by the `anycable-laravel` package — no code sample given for that part.)

Benchmark data tables worth keeping for comparison purposes:

Connection-avalanche resilience (thundering herd on mass reconnect):

| Scenario | Laravel Reverb | AnyCable |
| --- | --- | --- |
| 1,000 simultaneous connections | 100% success | 100% success |
| 2,500 simultaneous connections | 79.27% success | 100% success |
| 3,000 simultaneous connections | Server crashes | 100% success |
| 15,000 simultaneous connections | Server crashes | 99.73% success |

Broadcast latency (~10k virtual users, ~100-150 broadcasts/sec):

| Metric | Laravel Reverb | AnyCable |
| --- | --- | --- |
| Average broadcast latency | 221 ms | 185 ms |
| 95th percentile latency | 923 ms | 792 ms |
| Peak memory usage | 95 MB | 80 MB |

Feature comparison table (Reverb vs Pusher vs AnyCable):

| Feature | Laravel Reverb | Pusher | AnyCable |
| --- | --- | --- | --- |
| Reliable message delivery | Best effort | Best effort | At-least-once guarantee |
| Connection recovery | Manual reconnect | Manual reconnect | Automatic with state restoration |
| Offline message queuing | ❌ | ❌ | ✅ |
| Fallback transports | WebSockets only | WebSockets + polling | WebSockets + SSE + polling |
| Message size limit | PHP memory limit (~8MB) | 10KB per message | Configurable (no hard limit) |
| Custom authentication | Laravel guards | Webhooks | Laravel guards + JWT |
| Built-in monitoring | Basic logs | Dashboard + metrics | Prometheus metrics |
| Message history/replay | ❌ | Limited (24h) | ✅ Configurable retention |
| License | MIT | Commercial | MIT |
- **Opinion / hot take:** "We were genuinely surprised by the performance characteristics of Laravel Reverb. Very solid! Great work" — notable, unusually generous acknowledgment of a direct competitor's quality before pivoting to AnyCable's reliability differentiators. Core positioning line: "Focus on your product, not your tech stack." Also frames connection avalanches ("thundering herd" at mass restart/redeploy) as *the* underestimated scaling risk for realtime infra, not raw steady-state throughput.


### Connection Avalanche Safety Tips and Prepping for Real-Time Applications
- **Authors:** Vladimir Dementyev, Travis Turner | **Date:** July 9, 2024 | **URL:** https://evilmartians.com/chronicles/connection-avalanche-safety-tips-and-prepping-for-realtime-applications
- **Summary:** A "thundering herd" playbook specifically for WebSocket/real-time apps (relevant to any Turbo Streams app broadcasting to many connected clients). Identifies two avalanche triggers: **recovery avalanches** (a server restart/downtime causes mass simultaneous reconnects) and **celebrity avalanches** (a traffic spike, e.g. Hacker News front page, causes mass simultaneous new connections). Prescribes fixes across four layers: Ops (avoid deploys at peak traffic, roll out slowly, prefer least-connections over round-robin load balancing), Client (exponential backoff + jitter on reconnect, and *linearize* — i.e. stagger — multiple channel subscriptions instead of firing them all at once), Protocol (send an explicit disconnect notice before intentional restarts so clients don't all panic-reconnect instantly, support session resumability so reconnecting doesn't require full re-auth, use pre-authorized/signed subscription tokens to skip authorization round-trips on reconnect), and Server (slow-drain connections during shutdown instead of hard-dropping everyone at once, and run the real-time layer as a separate proxy service like AnyCable so connection-storm handling doesn't compete with app/business-logic resources).
- **Code worth stealing:** None captured — this article is architecture/ops guidance rather than code samples.
- **Opinion / hot take:** "Real-time client initialization is a *resource-intensive operation*" requiring auth, authorization, and multiple subscriptions simultaneously — the core justification for treating reconnect storms as a first-class capacity-planning concern, not an edge case.

### Real-time stress: AnyCable, k6, WebSockets, and Yabeda
- **Authors:** Vladimir Dementyev, Svyatoslav Kryukov, Andrey Novikov | **Date:** September 7, 2021 | **URL:** https://evilmartians.com/chronicles/real-time-stress-anycable-k6-websockets-and-yabeda
- **Summary:** Load-testing playbook for WebSocket/ActionCable/AnyCable servers using k6, culminating in the `xk6-cable` k6 extension (Go-based) that turns verbose raw-WebSocket k6 scripts into a few lines of `channel.perform` / `channel.receive`. Demonstrates ApacheBench → k6 HTTP → raw k6 WebSocket (`k6/ws`, painfully manual JSON protocol handling) → `xk6-cable` (clean channel abstraction) progression, plus a full ramping-VU chat load test measuring round-trip time via a `Trend` metric. Benchmarked results: Action Cable has materially worse latency/connection-init time than AnyCable; at 5,000 concurrent VUs, AnyCable Pro survives while both stock Action Cable and AnyCable OSS have significant issues.
- **Code worth stealing:**
```js
// k6 WebSocket test BEFORE xk6-cable — raw protocol handling
import ws from "k6/ws";
import { check } from "k6";

const WS_URL = __ENV.WS_URL || "wss://ws.demo.anycable.io/cable";
const WS_COOKIE = __ENV.WS_COOKIE;

export default function () {
  const response = ws.connect(
    WS_URL,
    { headers: { Cookie: WS_COOKIE } },
    (socket) => {
      socket.on("open", () => {
        let ws_cmd = {
          command: "subscribe",
          identifier: '{"channel":"ChatChannel","id":"demo"}',
        };
        socket.send(JSON.stringify(ws_cmd));

        socket.setTimeout(function () {
          let ws_cmd = {
            command: "message",
            identifier: '{"channel":"ChatChannel","id":"demo"}',
            data: '{"action":"speak","message":"Hello"}',
          };
          socket.send(JSON.stringify(ws_cmd));
        }, 500);
      });

      socket.on("message", (data) => {
        let parsed_data = JSON.parse(data);
        if (parsed_data.type === "confirm_subscription") {
          check(parsed_data, {
            subscribed: (d) => d.identifier === '{"channel":"ChatChannel","id":"demo"}',
          });
        } else if (parsed_data.message && parsed_data.message.action) {
          check(parsed_data, {
            "message recieved": (d) => d.message.action === "newMessage",
          });
        }
      });

      socket.setTimeout(function () {
        socket.close();
      }, 3000);
    }
  );
  check(response, { "status is 101": (r) => r && r.status === 101 });
}
```
```shell
xk6 build --with github.com/anycable/xk6-cable
```
```js
// k6 WebSocket test AFTER xk6-cable — clean channel abstraction
import { check, sleep } from "k6";
import cable from "k6/x/cable";

const WS_URL = __ENV.WS_URL || "wss://ws.demo.anycable.io/cable";
const WS_COOKIE = __ENV.WS_COOKIE;

export default function () {
  const client = cable.connect(WS_URL, { cookies: WS_COOKIE });
  const channel = client.subscribe("ChatChannel", { id: "demo" });
  channel.perform("speak", { message: "Hello" });
  const res = channel.receive();
  check(res, { "received res": (obj) => obj.action === "newMessage" });
  sleep(1);
  client.disconnect();
}
```
```js
// Full ramping-VU chat load test with RTT metric
import { check, sleep, fail } from "k6";
import cable from "k6/x/cable";
import { randomIntBetween } from "https://jslib.k6.io/k6-utils/1.1.0/index.js";
import { Trend } from "k6/metrics";

let rttTrend = new Trend("rtt", true);

let userId = `100${__VU}`;
let userName = `Kay${userId}`;

const URL = __ENV.CABLE_URL || "ws://localhost:8080/cable";
const WORKSPACE = __ENV.WORKSPACE || "demo";
const MESSAGES_NUM = parseInt(__ENV.NUM || "5");
const MAX = parseInt(__ENV.MAX || "20");
const TIME = parseInt(__ENV.TIME || "120");

export let options = {
  thresholds: { checks: ["rate>0.9"] },
  scenarios: {
    chat: {
      executor: "ramping-vus",
      startVUs: (MAX / 10 || 1) | 0,
      stages: [
        { duration: `${TIME / 3}s`, target: (MAX / 4) | 0 },
        { duration: `${(7 * TIME) / 12}s`, target: MAX },
        { duration: `${TIME / 12}s`, target: 0 },
      ],
    },
  },
};

export default function () {
  let client = cable.connect(URL, {
    cookies: `uid=${userName}/${userId}`,
    receiveTimeoutMS: 10000,
  });
  if (!check(client, { "successful connection": (obj) => obj })) fail("connection failed");

  let channel = client.subscribe("ChatChannel", { id: WORKSPACE });
  if (!check(channel, { "successful subscription": (obj) => obj })) fail("failed to subscribe");

  for (let i = 0; i < MESSAGES_NUM; i++) {
    let startMessage = Date.now();
    channel.perform("speak", { message: `hello from ${userName}` });
    let message = channel.receive({ author_id: userId });
    if (!check(message, { "received its own message": (obj) => obj })) {
      fail("expected message hasn't been received");
    }
    let endMessage = Date.now();
    rttTrend.add(endMessage - startMessage);
    sleep(randomIntBetween(5, 10) / 10);
  }

  client.disconnect();
}
```
- **Opinion / hot take:** "If we had written this post a few years ago, I would say—use jMeter" — explicit acknowledgment that tool recommendations decay and JS/Go-based k6 is the current best fit for WebSocket load testing.

### Real-time magic, no elixirs: optimizing Sera with AnyCable
- **Authors:** Kirill Kuznetsov, Olga Rusakova | **Date:** March 1, 2023 | **URL:** https://evilmartians.com/chronicles/real-time-magic-no-elixirs-optimizing-sera-with-anycable
- **Summary:** Case study migrating a GPS-tracking real-time system off Elixir/Phoenix onto Rails + AnyCable, so the whole stack could live in one language/runtime. Used `anycable-client` specifically for its automatic token-renewal handling (avoiding the token-expiration-mid-connection problem) and its flexible reconnection tuning for battery-constrained mobile clients. Used Action Cable's command callbacks to implement multi-tenancy scoping across AnyCable + Rails. Infra: AnyCable-Go talking gRPC to AnyCable-RPC, Prometheus/Grafana/CloudWatch monitoring, OpenSearch log tuning. Testing: TestProf + Fixturama + Dip (Evil Martians' own OSS) for fast, reliable specs against a system where visual/map data is constantly changing (so literal screenshot diffing didn't work — required adaptive test assertions instead). CI/CD: migrating to self-hosted GitLab runners cut deploy-test time from 50→22 min and MR-test time from 30→7 min.
- **Code worth stealing:** None captured verbatim in this fetch — narrative case study, no code blocks surfaced.
- **Opinion / hot take:** Positions AnyCable as a genuine substitute for reaching outside Ruby/Rails (e.g. to Elixir/Phoenix) purely to get real-time performance — "you don't need another language's runtime just for WebSockets."

### WebSocket Director: Scenario-Based Integration Tests for Real-time Apps
- **Authors:** Vladimir Dementyev, Travis Turner | **Date:** September 20, 2022 | **URL:** https://evilmartians.com/chronicles/websocket-director-scenario-based-integration-tests-for-real-time-apps
- **Summary:** The origin story and full usage guide for `wsdirector` (see also the OSS-projects section of this file). Beyond the basic YAML scenario format, shows two advanced real-world uses directly relevant to Turbo Streams/AnyCable testing: (1) capturing real Twilio Voice WebSocket traffic by patching `ApplicationCable::Connection` to snapshot every inbound frame into a wsdirector scenario file automatically, turning manual "run server + tunnel + call Twilio" debugging loops into replayable fixtures; (2) driving a **Capybara system test** for a non-browser actor (a mobile app sending GPS pings over Phoenix Channels) by firing a wsdirector scenario from inside the test itself via `run_websocket_scenario`, then asserting the resulting Turbo/DOM update in the browser side — a pattern for testing "real-time push into a page under test" end-to-end without needing a second real client.
- **Code worth stealing:**
```yaml
- subscribe:
    channel: "EchoChannel"
- perform:
    channel: "EchoChannel"
    data:
      text: "Hey!"
- receive:
    channel: "EchoChannel"
    data:
      response: "Hey!"
```
```yaml
# Multi-user scenario with a scale multiplier (like pgbench)
- client:
    multiplier: ":scale"
    name: publishers
    actions:
      - subscribe:
          channel: ChatChannel
          params:
            room_id: "42"
      - wait_all
      - perform:
          channel: ChatChannel
          params:
            room_id: "42"
          action: "speak"
          data:
            message: "test"
- client:
    multiplier: ":scale * 2"
    name: listeners
    actions:
      - subscribe:
          channel: ChatChannel
          params:
            room_id: "42"
      - wait_all
      - receive:
          multiplier: ":scale"
          channel: ChatChannel
          params:
            room_id: "42"
          data:
            message: "test"
```
```bash
$ wsdirector chat.yml localhost:8080/cable -s 10
Group publishers: 10 clients, 0 failures
Group listeners: 20 clients, 0 failures
```
```ruby
# Auto-capturing real WebSocket traffic (e.g. Twilio Voice) into a replayable wsdirector scenario
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    def handle_open
      @snapshot = WSDirector::Snapshot.new
      message_buffer.process!
    end

    def dispatch_websocket_message(data)
      @snapshot << decode(data)
    end

    def handle_close
      File.write("tmp/call.yml", @snapshot.to_yml)
    end
  end
end
```
```yaml
# Generated Twilio scenario excerpt
---
- send:
    data:
      event: connected
      protocol: Call
      version: 0.2.0
- sleep:
    time: 0.022
- send:
    data:
      event: start
      sequenceNumber: '1'
      start:
        accountSid: AC41149b360
        streamSid: MZ50f966ef8a
```
```yaml
# Emulating a mobile app sending GPS pings over Phoenix Channels, with ERB interpolation
---
- send:
    data:
      topic: tenant:<%= ENV.fetch('TENANT', 'rspec') %>
      event: phx_join
      payload: {}
      ref: '1'
- receive:
    data:
      topic: tenant:<%= ENV.fetch('TENANT', 'rspec') %>
      ref: '1'
      payload:
        status: ok
        response: {}
      event: phx_reply
- send:
    data:
      topic: tenant:<%= ENV.fetch('TENANT', 'rspec') %>
      event: update_location
      payload:
        position:
          latitude: <%= ENV.fetch('LAT', 32.84019785216758).to_f %>
          longitude: <%= ENV.fetch('LON', -97.06401083105213).to_f %>
        technicianId: <%= ENV['ID'] %>
      ref: '2'
```
```ruby
# Capybara system test driving a WS scenario as "the other client" while asserting DOM updates
it "sees location updates in real-time" do
  within "#tech-#{tech.id} .location" do
    expect(page).to have_text "Bronx, NY"
  end

  run_websocket_scenario(
    "tracker/update_location.yml",
    token: jwt_token,
    env: {
      "ID" => tech.id,
      "LAT" => 32.9846003797191,
      "LON" => -97.0647746830336
    }
  )

  within "#tech-#{tech.id} .location" do
    expect(page).to have_text "Dallas, TX"
  end
end
```
```ruby
# wsdirector 1.0 — clean Ruby-native invocation helper
def run_websocket_scenario(path, token:, url: Rails.configuration.tracker_url, **options)
  url = "#{url}?token=#{token}"
  scenario = Rails.root.join "spec" / "fixtures" / "wsdirector" / path

  WSDirector.run(scenario, url:, **options)
end
```
```bash
wsdirector -r ./my_protocol.rb -u localhost:3030/ws -i '[{"client":{"protocol":"MyProtocol"}}]'
```
- **Opinion / hot take:** "Humans are the bottleneck" — the tool exists specifically to remove humans from repetitive manual real-time QA loops (e.g. manually placing Twilio test calls over and over).

### How Doximity brought real-time Go power to their Rails app
- **Authors:** Victoria Melnikova, Travis Turner | **Date:** February 25, 2025 | **URL:** https://evilmartians.com/chronicles/growing-pains-and-a-dose-of-go-real-time-features-for-this-rails-app
- **Summary:** Case study: Doximity (80%+ of US physicians as users) added a "Hold for Me" phone feature (an automated assistant waits on a phone hold queue and alerts the physician when a human answers) by bolting AnyCable's Go real-time server onto their existing Rails app via a 2-week Evil Martians engagement (training + pairing), rather than rewriting anything. Notable: Doximity funded (open-sourced) a long-polling fallback for AnyCable Pro specifically to handle corporate networks that block WebSocket traffic outright.
- **Code worth stealing:** None captured — pure case-study narrative, no code blocks in the source.
- **Opinion / hot take:** "You don't need to abandon your Rails app to achieve high-performance real-time features" — the explicit thesis, aimed at both startups and large enterprises second-guessing Rails' ability to do real-time at scale.


### Using Hotwire and Rails to build a live commenting system
- **Author:** David Colby | **URL:** https://www.colby.so/posts/using-hotwire-and-rails-to-build-a-commenting-system
- **Summary:** Canonical Turbo-Streams-over-ActionCable commenting pattern: `turbo_stream_from @project, :comments` subscribes the show page; `Comment#after_create_commit` calls `broadcast_prepend_to [project, :comments], target: "#{dom_id(project)}_comments"`; the comment form itself lives in a `turbo_frame_tag "comment_form"` so it can be independently replaced on validation error.
- **Code worth stealing:**
```ruby
# app/models/comment.rb
include ActionView::RecordIdentifier
after_create_commit { broadcast_prepend_to [project, :comments], target: "#{dom_id(project)}_comments" }
```
```erb
<%= turbo_stream_from @project, :comments %>
<div id="<%= "#{dom_id(@project)}_comments" %>">
  <%= render @project.comments.order(created_at: :desc) %>
</div>
```
```ruby
def create
  @comment = @project.comments.new(comment_params)
  respond_to do |format|
    if @comment.save
      format.turbo_stream { render turbo_stream: turbo_stream.replace('comment_form', partial: 'comments/form', locals: { comment: Comment.new }) }
    else
      format.turbo_stream { render turbo_stream: turbo_stream.replace('comment_form', partial: 'comments/form', locals: { comment: @comment }) }
    end
  end
end
```

### Real-time updates with Turbo Streams / Turbo Streams and security (hotrails.dev)
See Turbo Rails Tutorial Chapters 5 & 6 above — the most rigorous treatment of scoped multi-tenant broadcasting found in this research.

### User notifications with Rails, Noticed, and Hotwire
See Turbo Streams patterns section above.

### Older-generation real-time posts (StimulusReflex / CableReady era — not transcribed in depth)
David Colby wrote a series of pre-Turbo-Streams real-time posts using **StimulusReflex** and **CableReady**, later superseded by native Turbo Streams (several of the above posts are direct Turbo-native rewrites of these same demos):
- "Interactive charts with Ruby on Rails, StimulusReflex, and ApexCharts" — https://colby.so/posts/interactive-charts-with-rails-and-stimulusreflex
- "Real-time previews with Rails and StimulusReflex" — https://colby.so/posts/real-time-previews-with-stimulus-reflex
- "Sort tables (almost) instantly with Ruby on Rails and StimulusReflex" — https://colby.so/posts/a-sortable-table-with-rails-and-stimulusreflex
- "Server-rendered modal forms on Rails with CableReady, Mrujs, Stimulus, and Tailwind" — https://colby.so/posts/modal-forms-with-cableready-and-mrujs
- "Doing the Impossible — Building a Persistent Audio Player in Ruby on Rails" — https://colby.so/posts/doing-the-impossible-persistent-audio-player-in-rails
- "Building a Live Search Experience with StimulusReflex and Ruby on Rails" — https://colby.so/posts/live-search-with-rails-and-stimulusreflex
- "Building a Real Time Scoreboard with Ruby on Rails and CableReady" — https://colby.so/posts/building-a-real-time-scoreboard-with-rails-and-cableready

---


*(See `broadcasts_refreshes` under Morphing — at 37signals the morphing page-refresh broadcast has largely replaced hand-written stream broadcasts. Also see Turbo 8 release notes.)*

---


### Building a Real-Time Chat App in Rails Using ActionCable and Turbo
- **Author:** Abiodun Olowode | **Date:** September 20, 2021 | **URL:** https://www.honeybadger.io/blog/chat-app-rails-actioncable-turbo/
- **Summary:** Full-build tutorial for a public/private-room chat app on Rails 6 combining ActionCable (Redis adapter) with Turbo Streams' `broadcast_append_to`. Models broadcast themselves on `after_create_commit`; private rooms are access-controlled via a `Participant` join model checked in a `before_create` callback that `throw :abort`s unauthorized messages even from console. A small Stimulus controller resets the message/room forms after each Turbo Stream submission since there's no full-page reload to naturally clear them.
- **Code worth stealing:**
```ruby
# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :user
  belongs_to :room
  before_create :confirm_participant
  after_create_commit { broadcast_append_to self.room }

  def confirm_participant
    if self.room.is_private
      is_participant = Participant.where(user_id: self.user.id,
                                        room_id: self.room.id).first
      throw :abort unless is_participant
    end
  end
end
```
```erb
<%# app/views/rooms/index.html.erb %>
<%= turbo_stream_from "users" %>
<div id="users"><%= render @users %></div>
...
<%= turbo_stream_from @single_room %>
<div id="messages"><%= render @messages %></div>
```
```erb
<%# app/views/layouts/_new_message_form.html.erb %>
<%= form_with(model: [@single_room ,@message], remote: true, class: "d-flex",
     data: { controller: "reset-form", action: "turbo:submit-end->reset-form#reset" }) do |f| %>
  <%= f.text_field :content, id: 'chat-text', class: "form-control msg-content", autocomplete: 'off' %>
  <%= f.submit data: { disable_with: false }, class: "btn btn-primary" %>
<% end %>
```
```javascript
// app/javascript/controllers/reset_form_controller.js
import { Controller } from "stimulus"

export default class extends Controller {
  reset() {
    this.element.reset()
  }
}
```
```bash
bundle add turbo-rails
rails turbo:install
sudo apt install redis-server
rails turbo:install:redis
```
- **Opinion / hot take:** Flags a real production caveat: "for applications that depend on WebSocket updates for certain features, on poor connections, or if there are server issues, your WebSocket may get disconnected" — don't treat Turbo Streams broadcasts as guaranteed delivery.

### Using Hotwire with Rails
- **Author:** Renata Marques | **Date:** August 30, 2021 | **URL:** https://www.honeybadger.io/blog/hotwire-rails/
- **Summary:** General-purpose intro (`hotwire-rails` gem install, Redis + ActionCable config, a likable-posts scaffold with `broadcast_prepend_to`) plus a deployment/security section covering Heroku Redis pub-sub across multiple dynos and a warning to run WSS and sanitize input.
- **Code worth stealing:**
```ruby
# app/models/post.rb
class Post < ApplicationRecord
  validates_presence_of :body
  after_create_commit { broadcast_prepend_to :posts }
end
```
```ruby
# posts_controller.rb#create
format.turbo_stream { render turbo_stream: turbo_stream.replace(@post, partial: 'posts/form', locals: { post: @post }) }
```
```yaml
# config/cable.yml
development:
  adapter: redis
  redis://localhost:6379/1
```
- **Opinion / hot take:** Warns that a Hotwire app "is exposed and vulnerable to many attacks" if WSS and input sanitization aren't handled. Also notes that without Redis on Heroku with >1 dyno, broadcasts silently won't reach everyone.

### Action Cable - Friend or Foe?
- **Author:** Nate Berkopec | **Date:** 2015-09-30 | **URL:** https://www.speedshop.co/blog/action-cable/
- **Summary:** Pre-Hotwire (Rails 5 era) analysis of Action Cable. Not about Turbo directly (Turbo/Turbo Streams didn't exist yet), but genuinely prescient: he evaluates Action Cable against three use cases (bidirectional game-style traffic, "live" data updates like live comments, and binary streaming) and concludes Action Cable is overkill for the "live data" case specifically because it hands developers a raw transport layer instead of an opinionated "live view" abstraction. He explicitly wishes Rails had extended the Turbolinks "view-over-the-wire" philosophy to WebSockets — describing something functionally identical to what Turbo Streams became years later.
- **Code worth stealing:** None (explicitly a "why" piece, not a how-to).
- **Opinion / hot take:** "I would have liked to see DHH and team double down on the 'view-over-the-wire' strategy espoused by Turbolinks and make Action Cable something more like 'live Rails partials over WebSockets'." ... "Providing Rails developers access to WebSockets is a little bit like showing up at a restaurant and, when you order a sandwich, being told to go make it yourself in the back." ... on "realtime" as a buzzword: "'Realtime' implies constant, nano-second resolution updating. The reality is that the comments section on your website probably doesn't change every nano-second... I prefer the term 'Live'."

### Audience of One
- **Author:** Sam Ruby | **Date:** Oct 26, 2023 | **URL:** https://fly.io/ruby-dispatch/audience-of-one/
- **Summary:** Builds a per-client (not broadcast) live log-streaming console using Action Cable + Stimulus: rather than one shared channel broadcasting to all subscribers, a random per-request token is registered server-side and used to `stream_from` a unique substream, so each browser tab only sees the output of the command *it* launched. Streams `flyctl logs` output (or any long-running subprocess) line-by-line to the browser using `Open3.popen3` + `IO.select` for non-blocking multiplexed stdout/stderr reads, converting ANSI color codes to HTML en route.
- **Code worth stealing:**
```bash
rails new console --css=tailwind
cd console
bin/rails generate channel output
bin/rails generate stimulus submit
bin/rails generate controller demo cmd
bundle add ansi-to-html
```
```erb
<%# app/views/demo/command.html.erb %>
<div class="w-full" data-controller="submit">
<h1 class="text-4xl font-extrabold text-center">Command demo</h1>
<input data-submit-target="input" name="app" placeholder="appname" class="...">
<button data-submit-target="submit" class="...">submit</button>
<div class="border-2 border-black rounded-xl p-2 hidden">
<div data-submit-target="output" data-stream="" class="...">
</div>
</div>
</div>
```
```javascript
// app/javascript/controllers/submit_controller.js
import { Controller } from "@hotwired/stimulus"
import consumer from '../channels/consumer'

export default class extends Controller {
  static targets = [ "input", "submit", "output" ]

  connect() {
    this.buttonTarget.addEventListener('click', event => {
      event.preventDefault()
      const { outputTarget } = this
      const params = {}
      for (const input of this.inputTargets) {
        params[input.name] = input.value
      }

      consumer.subscriptions.create({
        channel: "OutputChannel",
        stream: outputTarget.dataset.stream
      }, {
        connected() {
          this.perform("command", params)
          outputTarget.parentNode.classList.remove("hidden")
        },
        received(data) {
          let div = document.createElement("div")
          div.setAttribute("class", "pb-2 break-all overflow-x-hidden")
          div.innerHTML = data
          let bottom = outputTarget.scrollHeight - outputTarget.scrollTop - outputTarget.clientHeight
          outputTarget.appendChild(div)
          if (bottom == 0) div.scrollIntoView()
        }
      })
    })
  }
}
```
```ruby
# app/controllers/demo_controller.rb
class DemoController < ApplicationController
  def cmd
    @stream = OutputChannel.register do |params|
      ["flyctl", "logs", "--app", params["app"]]
    end
  end
end
```
```ruby
# app/channels/output_channel.rb
require 'open3'

class OutputChannel < ApplicationCable::Channel
  def subscribed
    @stream = params[:stream]
    @pid = nil
    stream_from @stream if @@registry[@stream]
  end

  def command(data)
    block = @@registry[@stream]
    run(block.call(data)) if block
  end

  def unsubscribed
    Process.kill("KILL", @pid) if @pid
  end

private
  @@registry = {}
  BLOCK_SIZE = 4096

  def self.register(&block)
    token = SecureRandom.base64(15)
    @@registry[token] = block
    token
  end

  def logger
    @logger ||= Logger.new(nil)
  end

  def html(string)
    Ansi::To::Html.new(string).to_html
  end

  def run(command)
    Open3.popen3(*command) do |stdin, stdout, stderr, wait_thr|
      @pid = wait_thr.pid
      files = [stdout, stderr]
      stdin.close_write
      part = { stdout => "", stderr => "" }

      until files.all? {|file| file.eof} do
        ready = IO.select(files)
        next unless ready
        ready[0].each do |f|
          lines = f.read_nonblock(BLOCK_SIZE).split("\n", -1)
          next if lines.empty?
          lines[0] = part[f] + lines[0] unless part[f].empty?
          part[f] = lines.pop()
          lines.each {|line| transmit html(line)}
          rescue EOFError => e
        end
      end
      part.values.each { |part| transmit html(part) unless part.empty? }
      files.each {|file| file.close}
      @pid = nil
    rescue Interrupt
    rescue => e
      puts e.to_s
    ensure
      files.each {|file| file.close}
      @pid = nil
    end
  end
end
```
- **Opinion / hot take:** "Action Cable does the heavy lifting in this scenario. As documented it may appear daunting and unapproachable... but in practice it can be very easy to use." Security note baked into the design: commands are never client-supplied strings — only server-registered blocks keyed by a random token, and the final command is always an argv array (never shell-interpolated) to block shell injection.

### Push to Subscribe
- **Author:** Sam Ruby | **Date:** Jul 10, 2023 | **URL:** https://fly.io/ruby-dispatch/push-to-subscribe/
- **Summary:** Full walkthrough of adding Web Push notifications to a Rails 7 app using the `web-push` gem, a service worker, and a Stimulus controller that drives the whole permission → subscribe → POST-to-server flow. Not Turbo-specific — it's the Push API, not Hotwire's own real-time story — but included because the entire client wiring is a Stimulus controller and it's a genuinely useful "real-time engagement" companion pattern to ActionCable/Turbo Streams for Rails+Hotwire apps.
- **Code worth stealing:**
```javascript
// app/views/service_worker/service_worker.js.erb
self.addEventListener("push", event => {
  const { title, ...options } = event.data.json();
  self.registration.showNotification(title, options);
})

self.addEventListener("pushsubscriptionchange", event => {
  const newSubscription = event.newSubscription?.toJSON()
  event.waitUntil(
    fetch(<%= change_notifications_path.inspect.html_safe %>, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        old_endpoint: event.oldSubscription?.endpoint,
        new_endpoint: event.newSubscription?.endpoint,
        new_p256dh: newSubscription?.keys?.p256dh,
        new_auth: newSubscription?.keys?.auth
      })
    })
  )
})
```
```javascript
// app/javascript/controllers/subscribe_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    for (const field of this.element.querySelectorAll('.my-5')) {
      field.style.display = 'none'
    }
    this.element.style.display = 'inline-block'
    const submit = this.element.querySelector('input[type=submit]')

    if (!navigator.serviceWorker || !window.PushManager) {
      this.disable(submit)
    } else if (Notification.permission !== "default") {
      this.disable(submit)
    } else {
      submit.addEventListener("click", event => {
        event.stopPropagation()
        event.preventDefault()
        this.disable(submit)

        const key = Uint8Array.from(atob(this.element.dataset.key), m => m.codePointAt(0))
        const path = this.element.dataset.path

        Notification.requestPermission().then(permission => {
          if (Notification.permission === "granted") {
            navigator.serviceWorker.register('/service-worker.js')
            .then(registration => registration.pushManager.subscribe({
              userVisibleOnly: true,
              applicationServerKey: key
            }))
            .then(subscription => {
              subscription = subscription.toJSON()
              let formData = new FormData(this.element.querySelector('form'))
              formData.set('subscription[endpoint]', subscription.endpoint)
              formData.set('subscription[auth_key]', subscription.keys.auth)
              formData.set('subscription[p256dh_key]', subscription.keys.p256dh)

              return fetch(path, {
                method: 'POST',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: new URLSearchParams(formData).toString()
              })
            })
            .catch(error => console.error(`Web Push subscription failed: ${error}`))
          }
        })
      })
    }
  }

  disable(submit) {
    submit.removeAttribute('href')
    submit.style.cursor = 'not-allowed'
    submit.style.opacity = '30%'
  }
}
```
```erb
<%# app/views/users/_user.html.erb %>
<span data-controller="subscribe" class="hidden"
  data-path=<%= subscriptions_path %> data-key="<%=
    Rails.application.credentials.webpush.public_key.tr("_-", "/+")
  %>">
  <%= render partial: 'subscriptions/form', locals: {
     subscription: Subscription.new(user: user)
   } %>
</span>
```
```ruby
# app/models/user.rb
def push(notification)
  creds = Rails.application.credentials
  subscriptions.each do |subscription|
    begin
      response = WebPush.payload_send(
        message: notification.to_json,
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh_key,
        auth: subscription.auth_key,
        vapid: {
          private_key: creds.webpush.private_key,
          public_key: creds.webpush.public_key
        }
      )
      logger.info "WebPush: #{response.inspect}"
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      logger.warn "WebPush: #{response.inspect}"
    rescue WebPush::ResponseError => response
      logger.error "WebPush: #{response.inspect}"
    end
  end
end
```
- **Opinion / hot take:** None strong — practical/reference-style post. Notes the ecosystem is a mess: webpush protocol/docs/gem all "provide too many choices, are incomplete, may even suggest things that no longer work."

---

---

## Web Components + Hotwire


### The Art of Turbo Mount: Hotwire Meets Modern JS Frameworks
- **Authors:** Svyatoslav Kryukov, Travis Turner | **Date:** June 11, 2024 | **URL:** https://evilmartians.com/chronicles/the-art-of-turbo-mount-hotwire-meets-modern-js-frameworks
- **Summary:** Worked example ("Excel-lent Palettes") mounting a React spreadsheet component (`@fortune-sheet/react`) inside a Hotwire page. Shows the progression from (1) hand-rolled Stimulus controller that mounts/unmounts React on `connect()`/`disconnect()` with props passed via Stimulus Values API, to (2) Turbo Mount's `turbo_mount` helper which eliminates that boilerplate, to (3) extending a Turbo-Mount-registered component with a custom controller for two-way prop updates, to (4) building fully custom components with Vite + auto-loading registration. Positions Turbo Mount as filling the gap "Hotwire alone lacks complex interactive components."
- **Code worth stealing:** Full code wasn't captured verbatim in this fetch — the OSS-projects section of this file already has the canonical turbo-mount install/usage snippets (Gemfile, importmap pins, `registerComponent`, `turbo_mount()` helper, custom `TurboMountController` subclass). Re-fetch this specific article's `.md` source directly if the FortuneSheet-specific integration code is needed.
- **Opinion / hot take:** Turbo Mount's value proposition per the authors: simplicity, Vite compatibility, and framework-agnosticism (React/Vue/Svelte) via "convention over configuration" — a deliberate rejection of hand-rolled Stimulus-mounts-React boilerplate as the default pattern.

---

## Performance


No dedicated performance-focused articles were found on either site beyond the tradeoffs already noted in the Morphing section (full-page morph refresh vs. targeted Turbo Stream cost) and the Real-time section (`_later` async broadcasting to avoid blocking the request cycle). See:
- "Turbo 8 morphing refreshes on Rails" (Morphing section) — "more resource heavy" full-page renders vs. targeted streams.
- "Turbo Streams on Rails" (Streams section) — preference for `broadcast_*_later_to` over synchronous broadcasting.

---


### Async Ruby on Rails
- **Author:** Matheus Richard | **Date:** June 7, 2024 (edited Jan 31, 2025) | **URL:** https://thoughtbot.com/blog/async-ruby-on-rails
- **Summary:** Broad async-Rails roundup (background jobs, the `async` gem for concurrent HTTP, ActiveRecord `load_async`, parallel testing) with a Turbo Frames section relevant here: multiple independent `<turbo-frame src="..." loading="lazy">` elements on one page fetch and render in parallel, each hitting its own controller action — explicitly framed as a way to parallelize page-section loading without JS, though the author warns against overusing it because too many concurrent frame requests degrade UX.
- **Code worth stealing:**
```html
<turbo-frame
  id="best_sellers"
  src="books/best_sellers"
  loading="lazy"
></turbo-frame>
```
```ruby
class BooksController
  def best_sellers
    @books = Book.best_sellers
  end
end
```
```erb
<turbo-frame id="best_sellers">
  <h1>Best Sellers</h1>
  <%= render @best_sellers %>
</turbo-frame>
```
```ruby
# ActiveRecord load_async, used alongside frames for the same goal (parallelism)
class ReportsController
  def create
    @new_authors = Author.recent.load_async
    @new_books = Book.recent.load_async
    @new_reviews = BookReview.recent.load_async
  end
end
```
- **Opinion / hot take:** "Async can make your app faster, but it also can make the code more complex" — argues fixing N+1s/indexing/caching should come before reaching for async/parallel-frame tricks, not after.

### Organization for Transformative Works Performance Audit
- **Author:** Nate Berkopec | **Date:** 2026-05-29 | **URL:** https://www.speedshop.co/blog/performance-lessons-from-ao3/
- **Summary:** A real, paid performance-retainer audit report for Archive of Our Own (AO3, a 16+ year old Rails app), published in full. Most of it is generic Rails perf, but one recommendation is explicitly about Turbo: "Use Turbo Drive or Turbo Frames," rated Cost 4 / Benefit 5 — the highest benefit score of any recommendation in the whole audit. He frames full-page-nav elimination as the single highest-leverage performance change available, bigger than any backend optimization in the report. For AO3 specifically he recommends Turbo Frames over Turbo Drive as the lower-effort migration path (can be layered onto specific UI sections without an inventory of every jQuery plugin's page-load assumptions), while Turbo Drive would require auditing "_all_ your JavaScript" since "pretty much every jQuery plugin's assumption about how pageloads work will break."
- **Code worth stealing:** Not Turbo-specific code, but the audit's read-replica routing pattern (relevant to any Turbo-Frame-heavy app doing partial GETs) is worth keeping:
```ruby
def use_replica_if_read_only
  if read_only_queue?
    begin
      ActiveRecord::Base.connected_to(role: :reading) { yield }
    rescue ActiveRecord::ReadOnlyError
      self.class.set(queue: writable_queue_name).perform_later(*arguments)
    end
  else
    yield
  end
end

def read_only_queue?
  queue_name.include?("read-only")
end

def writable_queue_name
  queue_name.gsub(/[-_]?read-only[-_]?/, "")
end
```
- **Opinion / hot take:** "I harp on this one on social media a lot but it's true. **The biggest performance impact you can have on a web app user is to turn a full page navigation into an SPA-style route change**. For 'golden path' Rails apps like AO3, that means using Turbo." ... "The reason why these kinds of requests are so much faster is because the CSSOM and Javascript VM are re-used. You don't need to completely relayout everything, recalculate the CSSOM and re-execute all your JS. You can just move on! It's truly the only thing that [can] remove **seconds** from a user waiting on the page to do something, rather than milliseconds." ... "It's a lot of work, but there's really nothing that makes pageloads faster. If you can turn a full-page-nav into something else, people really feel it."

---

---

## Testing


### ViewComponent in the Wild III: TailwindCSS classes & HTML attributes
- **Authors:** Vladimir Dementyev, Travis Turner | **Date:** January 23, 2024 | **URL:** https://evilmartians.com/chronicles/viewcomponent-in-the-wild-embracing-tailwindcss-classes-and-html-attributes
- **Summary:** Solves the "dozens of Tailwind classes scattered through component templates" and "conflicting conditional classes" problems with **Style Variants** — a `view_component-contrib` DSL directly modeled on Tailwind Variants/CVA, including a `compound(...)` directive for classes that only apply for a specific *combination* of variants (e.g. `variant: :outline, disabled: true`), and a `tailwind_merge` gem integration so conflicting utility classes resolve deterministically instead of silently double-defining `bg-*`. Second half covers HTML attribute propagation: instead of enumerating every possible input option, expose a "bag of attributes" (`html_attrs`, `input_attrs`) rendered via Rails 7's built-in `tag.attributes(**hash)` helper, with a sugar `html_option` DSL and `dots(...)` alias (a JS spread-operator pun). Also introduces inline-template browser testing via a `visit_template` helper (from `rails-intest-views`) so system specs for interactive components don't require wiring up a full component preview.
- **Code worth stealing:**
```ruby
class UIKit::Button::Component < ApplicationComponent
  option :type, default: proc { "button" }
  option :variant, default: proc { :default }
  option :disabled, default: proc { false }

  style do
    base {
      %w[
        items-center justify-center px-4 py-2
        text-sm font-medium
        border border-slate-300 shadow-sm rounded-md
        focus:outline-none focus:ring-offset-2
      ]
    }
    variants {
      variant {
        primary {
          %w[
            text-white bg-blue-600 ring-blue-700
            hover:bg-blue-700
            focus:ring-offset-blue-50
            dark:border-slate-950 dark:bg-blue-700 dark:text-blue-50 dark:ring-blue-950
            dark:hover:bg-blue-800
            dark:focus:ring-offset-blue-700
          ]
        }
        outline {
          %w[
            bg-slate-50
            hover:bg-slate-100
            focus:ring-slate-600 focus:ring-offset-blue-50
            dark:border-slate-950 dark:bg-slate-700 dark:ring-slate-950
            dark:hover:bg-slate-800
            dark:focus:ring-offset-slate-700
          ]
        }
      }
      disabled {
        yes { %w[opacity-50 pointer-events-none] }
      }
    }
    defaults { {variant: :primary, disabled: false} }
    # compound: extra classes ONLY when this exact combination of variants is used
    compound(variant: :outline, disabled: true) { %w[opacity-75 bg-slate-300] }
  end

  erb_template <<~ERB
    <button type="<%= type %>" class="<%= style(variant:, disabled:) %>"<%= " disabled" if disabled %>>
      <%= content %>
    </button>
  ERB
end
```
```ruby
# Resolve conflicting Tailwind utility classes deterministically
class ApplicationComponent < ViewComponentContrib::Base
  include ViewComponentContrib::StyleVariants

  style_config.postprocess_with do |classes|
    TailwindMerge::Merger.new.merge(classes.join(" "))
  end
end
```
```ruby
# HTML attribute "bag" instead of enumerating every possible option
class UIKit::Input::Component < ApplicationComponent
  option :name
  option :html_attrs, default: proc { {} }
  option :input_attrs, default: proc { {} }, type: -> { {autocomplete: "off", required: false}.merge(_1) }

  erb_template <<~ERB
    <input <%= tag.attributes(**input_attrs) %>>
  ERB

  def before_render
    input_attrs.merge({name:})
  end
end
```
```erb
<%= render UIKit::Input::Component.new(
  name: "name",
  input_attrs: {placeholder: "Enter your name", autocomplete: "on", autofocus: true}) %>
```
```ruby
# Sugared DSL
class UIKit::Input::Component < ApplicationComponent
  option :name
  html_option :html_attrs
  html_option :input_attrs, default: {autocomplete: "off", required: false}

  erb_template <<~ERB
    <input <%= dots(input_attrs) %>>
  ERB
end
```
```ruby
# Inline-template system test — no preview page required
it "does some dynamic stuff" do
  visit_template <<~ERB
    <form id="myForm" onsubmit="event.preventDefault(); this.innerHTML = '';">
      <h2>Self-destructing form</h2>
      <%= render Button::Component.new(type: :submit, kind: :info) do %>
        Destroy me!
      <% end %>
    </form>
  ERB

  expect(page).to have_text "Self-destructing form"
  click_on("Destroy me!")
  expect(page).to have_no_text "Self-destructing form"
end
```
- **Opinion / hot take:** "TailwindCSS has conquered the world of UI development. Why bother with CSS rules, nesting, and naming (BEM, SMACSS...) when you can define all your styling with HTML classes?" Also flags real UI kit prior art for Rails: PhlexUI, RailsUI, ZestUI.


### Turbo Rails Tutorial — system tests (hotrails.dev)
Every CRUD chapter of the hotrails.dev tutorial (Chapters 1, 4, 9, 10) ships a Capybara system test exercising the exact Turbo behavior just added. Representative example from Chapter 9:
```ruby
# test/system/line_item_dates_test.rb
test "Creating a new line item date" do
  assert_selector "h1", text: "First quote"
  click_on "New date"
  fill_in "Date", with: Date.current + 1.day
  click_on "Create date"
  assert_text I18n.l(Date.current + 1.day, format: :long)
end
```
- **Opinion / hot take (Chapter 1):** "Testing is a fundamental part of software development" — Rails system tests + fixtures are the author's default, applied consistently through the whole 12-chapter series.

### Building a custom Stimulus generator for Rails
See Stimulus section above — `Rails::Generators::TestCase` pattern for testing a custom generator.

No standalone "testing Stimulus controllers" or "testing Turbo Streams" articles were found on colby.so; testing content is embedded within feature posts (e.g. the generator test above) rather than treated as its own topic.

---


### Write Reliable, Asynchronous Integration Tests With Capybara
- **Author:** Joe Ferris | **Date:** September 10, 2014 (updated March 23, 2019) | **URL:** https://thoughtbot.com/blog/write-reliable-asynchronous-integration-tests-with-capybara
- **Summary:** Pre-dates Hotwire but is the canonical thoughtbot explanation of *why* Capybara+JS-driver system specs flake, and is directly applicable to Turbo/Stimulus specs since Turbo Drive/Frame/Stream requests are exactly the kind of async DOM mutation this describes: with a JS driver, the app runs in a background thread and makes real HTTP round trips while the test process keeps running, creating races between assertions and DOM updates. Capybara's finder/matcher methods (`find`, `have_css`, `have_field`) have built-in waiting/retrying; direct Ruby-side checks (`first`, `all`, `execute_script` without a preceding `find`, reading `.value`/`.text` immediately) do not, and are the actual source of most "flaky Hotwire test" reports.
- **Code worth stealing:**
```ruby
# Bad — first() returns nil if element hasn't appeared yet
first(".active").click

# Good
find(".active").click                    # exactly one expected
find(".active", match: :first).click     # first of several, less safe long-term
```
```ruby
# Bad — all() can return [] before elements render
all(".active").each(&:click)

# Good — force a wait first
find(".active", match: :first)
all(".active").each(&:click)
```
```ruby
# Bad — JS runs before the element may exist
execute_script("$('.active').focus()")

# Good
find(".active")
execute_script("$('.active').focus()")
```
```ruby
# Bad — reads value immediately, no wait for a pending update
expect(find_field("Username").value).to eq("Joe")

# Good — matcher waits/retries until value matches
expect(page).to have_field("Username", with: "Joe")
```
```ruby
# Bad
expect(find(".user")["data-name"]).to eq("Joe")

# Good
expect(page).to have_css(".user[data-name='Joe']")
```
```ruby
# Bad — has_css? returns true immediately but waits ~2s only when false
it "doesn't have an active class name" do
  expect(has_active_class).to be_false
end

def has_active_class
  has_css?(".active")
end

# Good — matcher form waits properly in both directions
it "doesn't have an active class name" do
  expect(page).not_to have_active_class
end

def have_active_class
  have_css(".active")
end
```
- **Opinion / hot take:** "Use action methods, like click_on, instead of finder methods, like find, when interacting with the page... Use RSpec matchers, like have_css, instead of node methods, like text, when verifying elements exist" — a blanket API-choice rule, not just situational advice.

### AI's "overnight" solution for our flaky tests took two weeks to adopt
- **Author:** Fritz Meissner | **Date:** June 22, 2026 | **URL:** https://thoughtbot.com/blog/what-it-took-to-use-this-overnight-ai-solution
- **Summary:** Case study (no code blocks) of using Claude to fix a years-old backlog of flaky system specs on "interactive pages using Stimulus or Hotwire," where 60% of CI runs were failing on this quarantined `:flaky` test group. Claude ran the flaky group hundreds of times at increasing batch sizes (5 → 50 → 100 runs) to find fixes empirically, but the author still spent two weeks manually filtering the AI's output — stripping out cargo-cult fixes like inserted `sleep` calls that happened to "work" without addressing the real race condition.
- **Code worth stealing:** None provided — the article is narrative/process, not code.
- **Opinion / hot take:** "Eventually 'tidy first, then do the work' ends up being faster than 'just do the work'" — applied here to AI-generated test fixes: don't ship the AI's flaky-test patches without a cleanup pass, because AI reliably reaches for `sleep`-style band-aids over Capybara's proper waiting APIs.

### Don't Steal a Penguin -- A Guide to Rails Flashes
- **Author:** Louis Antonopoulos | **Date:** April 25, 2025 | **URL:** https://thoughtbot.com/blog/rails-flashes-guide
- **Summary:** Comprehensive flash-message guide; the Hotwire-relevant portion is a dismissible-flash Stimulus controller (`hide-on-click`, one-liner `this.element.remove()`) wired via `data-action="hide-on-click#hide"`, plus a full custom Minitest/Capybara assertion helper (`assert_flashes`, `assert_no_flash`, `assert_no_flashes`) built on `capybara_accessible_selectors` and thoughtbot's own `action_dispatch-testing-integration-capybara` gem, asserting both the `flash` hash contents and the rendered `div#flash` DOM structure in one call. Also shows using `content_for?(:hide_flashes)` to suppress the default flash partial on pages that render flashes in a custom location.
- **Code worth stealing:**
```javascript
// app/javascript/controllers/hide_on_click_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  hide() {
    this.element.remove();
  }
}
```
```erb
<!-- app/views/application/_flash.html.erb -->
<div role="alert" data-controller="hide-on-click">
  <span><%= message %></span>
  <button data-action="hide-on-click#hide">X</button>
</div>
```
```ruby
# Gemfile
group :test do
  gem "capybara_accessible_selectors", github: "citizensadvice/capybara_accessible_selectors", tag: "v0.12.0"

  gem "action_dispatch-testing-integration-capybara",
    github: "thoughtbot/action_dispatch-testing-integration-capybara",
    require: "action_dispatch/testing/integration/capybara/minitest"
end
```
```ruby
# test/test_helper.rb
module ActiveSupport
  class TestCase
    def assert_flashes(messages, type:)
      messages = Array(messages)
      assert_equal messages, Array(flash[type])
      assert_element "div", id: "flash", count: 1 do |parent|
        messages.each_with_index do |text, index|
          parent.assert_selector :alert, text:, id: "flash-#{type}-#{index}", normalize_ws: true, exact_text: true
        end
      end
    end

    def assert_no_flash(type:)
      assert_nil flash[type]
      assert_element "div", id: "flash-#{type}-0", count: 0
    end

    def assert_no_flashes
      assert_empty flash
      assert_element "div", id: "flash", count: 0
      assert_no_flash(type: :alert)
      assert_no_flash(type: :notice)
    end
  end
end
```
```ruby
# usage
assert_flashes "You need to sign in or sign up before continuing.", type: :alert
assert_flashes "Signed in successfully.", type: :notice
assert_flashes ["Penguins are majestic", "Peguins are also cuddly"], type: :penguin
```
```erb
<!-- app/views/layouts/application.html.erb -->
<body>
  <% unless content_for?(:hide_flashes) %>
    <%= render "application/flashes" %>
  <% end %>
  <%= yield %>
</body>
```
- **Opinion / hot take:** Insists Rails deliberately leaves flash *rendering* unimplemented — "your users will never see them" without you building the partial — treating this as a routinely-missed gap in tutorials.

---

---

## Tooling & debugging


### Gemfile of dreams: the libraries we use to build Rails apps
- **Authors:** Vladimir Dementyev, Travis Turner | **Date:** April 10, 2026 (regularly updated) | **URL:** https://evilmartians.com/chronicles/gemfile-of-dreams-libraries-we-use-to-build-rails-apps
- **Summary:** Evil Martians' curated, continuously-updated "ideal Gemfile" across every Rails subsystem. Frontend-relevant section explicitly names the current HTML-over-the-wire stack (`view_component`, `view_component-contrib`, `lookbook`, `reactionview`, `turbo-rails`) as the default, with Inertia + React (`inertia_rails`, `alba`, `alba-inertia`, `typelizer`, `js-routes`) now used in "about half of all greenfield projects." Asset pipeline default has moved to `vite_rails` + `bundlebun` (packages a Bun runtime into a gem so no separate Node install is needed) instead of Propshaft/importmap or jsbundling-rails. Also flags `anycable-rails` under "Everything Else" as the answer to "want to build some reliable real-time features?"
- **Code worth stealing:**
```ruby
# HTML-over-the-wire stack
gem 'view_component'
gem 'view_component-contrib'
gem 'lookbook', require: false
gem 'reactionview'
gem 'turbo-rails'
```
```ruby
# Inertia stack (~50% of new greenfield projects per the authors)
gem "inertia_rails", "~> 3.0"
gem "alba"
gem "alba-inertia"
gem "typelizer"
gem "js-routes"
```
```ruby
# Asset management
gem 'vite_rails'
gem "bundlebun"   # bundles a Bun runtime into the gem — no separate Node.js install needed
```
```ruby
# Real-time
gem 'anycable-rails'
```
```ruby
# Example of active_record-associated_object + active_job-performs cutting boilerplate
class Cable < ApplicationRecord
  has_object :deployer

  performs def provision
    return unless created?

    case deployer.deploy_application(provider_id, configuration)
    in Success[true]
      Rails.logger.info "Successfully deployed cable #{id}"
    in Failure[error]
      Rails.error.report(error, handled: true)
    end
  end
end

cable = Cable.create!(cable_params)
cable.provision_later
```
- **Opinion / hot take:** "Hotwire makes our HTML-based applications interactive and reactive, while view components help us organize the templates and their logic" — stated as one line, treating Hotwire+ViewComponent as a settled default rather than a debate. Frontend stack choice is explicitly framed as per-project (Hotwire vs. Inertia), not dogmatic.

### Vite-lizing Rails: get live reload and hot replacement with Vite Ruby
- **Author:** Vladimir Dementyev | **Date:** June 28, 2022 (updated May 21, 2024 for Vite 5) | **URL:** https://evilmartians.com/chronicles/vite-lizing-rails-get-live-reload-and-hot-replacement-with-vite-ruby
- **Summary:** Migrating a Rails 7 app from Webpacker to `vite_rails`/Vite Ruby, focused on restoring HMR. Central Stimulus-specific point: Stimulus controllers can get real HMR (reconnect on edit without a full page reload, preserving app state) via the `vite-plugin-stimulus-hmr` plugin layered on top of controller auto-registration via `import.meta.glob`. Also covers running Vite inside vs. alongside Docker (a `bin/vite` wrapper with its own `gemfiles/frontend.gemfile` so frontend deps don't bloat the main bundle, and `"host": "0.0.0.0"` in `config/vite.json` so the dev server is reachable from other containers).
- **Code worth stealing:**
```js
// Stimulus controller auto-loading, Vite < 5
const controllers = import.meta.globEager("./**/*_controller.js");
for (let path in controllers) {
  let module = controllers[path];
  let name = path.match(/\.\/(.+)_controller\.js$/)[1].replaceAll("/", "--");
  application.register(name, module.default);
}
```
```js
// Simplified with stimulus-vite-helpers
import { registerControllers } from "stimulus-vite-helpers";
const controllers = import.meta.glob("./**/*_controller.js", { eager: true });
registerControllers(application, controllers);
```
```js
// vite.config.js — Stimulus HMR + full reload on ERB template edits
import { defineConfig } from "vite";
import RubyPlugin from "vite-plugin-ruby";
import StimulusHMR from "vite-plugin-stimulus-hmr";
import FullReload from "vite-plugin-full-reload";

export default defineConfig({
  plugins: [
    RubyPlugin(),
    StimulusHMR(),
    FullReload(["app/views/**/*.erb"])
  ],
});
```
```yaml
# docker-compose.yml — dedicated vite service sharing volumes with backend
x-backend: &backend
  volumes:
    - vite_dev:/app/public/vite-dev
    - vite_test:/app/public/vite-test

vite:
  <<: *backend
  command: ./bin/vite dev
  volumes:
    - ..:/app:cached
    - bundle:/usr/local/bundle
    - node_modules:/app/node_modules
    - vite_dev:/app/public/vite-dev
    - vite_test:/app/public/vite-test
  ports:
    - "3036:3036"
```
```bash
#!/bin/bash
# bin/vite — isolates frontend deps into their own Gemfile
cd $(dirname $0)/..
export BUNDLE_GEMFILE=./gemfiles/frontend.gemfile
bundle check > /dev/null || bundle install
bundle exec vite $@
```
- **Opinion / hot take:** "Hot module replacement...makes it possible to refresh the current state of a browser's JavaScript environment without reloading the entire page" — presented as a strict developer-experience upgrade over Webpacker's typical full-reload workflow, worth the migration effort.

### Now you see it: Vite on Rails without the proxy
- **Authors:** Svyatoslav Kryukov, Travis Turner | **Date:** April 14, 2026 | **URL:** https://evilmartians.com/chronicles/now-you-see-it-vite-on-rails-without-the-proxy
- **Summary:** Introduces `rails_vite`, a new lighter-weight alternative to `vite_rails` inspired by how Laravel wires up Vite (a plugin writes the dev-server URL to a file; a server helper reads it — no Rack proxy). Two modes: "jsbundling mode" plants a tiny JS stub file in `app/assets/builds/` that Propshaft happily fingerprints/serves as if it were real, but which actually just `import`s the live Vite dev server URLs (rewritten at boot once Vite picks a port) — including a clever CSS-via-JS-import trick so CSS HMR works through the same stub without touching `stylesheet_link_tag`. In production, a "double" file re-exports the real content-hashed Vite bundle so Propshaft's fingerprinted path and Vite's manifest path both resolve to the same module (avoiding duplicate-module-identity bugs). "Gem mode" is more explicit: writes dev-server info to `tmp/rails-vite.json`, and a Ruby helper (`vite_tags`) emits `<script src="http://localhost:5173/...">` tags directly, plus gives you `vite_image_tag`/`vite_asset_path`/CSP nonce support that jsbundling-mode's stub trick can't provide. Confirms Stimulus HMR again via `vite-plugin-stimulus-hmr` + `stimulus-vite-helpers`. States this exact approach (Stimulus + Turbo + Tailwind + AnyCable) is running in the "AnyCable Rails Demo," migrated from esbuild to Vite as the reference example.
- **Code worth stealing:**
```javascript
// rails-vite dev stub – DO NOT EDIT (planted in app/assets/builds/, Propshaft-visible)
import "http://localhost:5173/@vite/client";
import "http://localhost:5173/app/javascript/application.css";
import "http://localhost:5173/app/javascript/application.js";
```
```bash
npm install -D rails-vite-plugin vite
```
```typescript
// vite.config.ts — jsbundling mode
import { defineConfig } from "vite";
import jsbundling from "rails-vite-plugin/jsbundling";

export default defineConfig({
  plugins: [
    jsbundling(),
  ],
});
```
```diff
  web: bin/rails server -p 3000
- js: yarn build --watch
+ vite: npx vite
```
```typescript
// Tailwind v4 via its official Vite plugin, dropping cssbundling-rails entirely
import { defineConfig } from "vite";
import jsbundling from "rails-vite-plugin/jsbundling";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [
    jsbundling(),
    tailwindcss(),
  ],
});
```
```json
{ "build": "vite build" }
```
```bash
# Gem mode install
bundle add rails_vite
bin/rails generate rails_vite:install
```
```erb
<%= vite_tags "application.js" %>
```
```html
<!-- Gem mode dev output -->
<script src="http://localhost:5173/@vite/client" type="module"></script>
<script src="http://localhost:5173/app/javascript/application.js" type="module"></script>
```
```html
<!-- Gem mode production output, reading the Vite manifest directly -->
<link rel="modulepreload" href="/vite/assets/vendor-b3c4d5e6.js" />
<script src="/vite/assets/application-a1b2c3d4.js" type="module"></script>
<link rel="stylesheet" href="/vite/assets/application-x9y8z7w6.css" />
```
- **Opinion / hot take:** "The trick was making Vite invisible to Rails. Both systems got what they wanted, and neither had to compromise." Explicitly non-dogmatic about which mode/gem to use: "vite_ruby works fine for thousands of apps. If you're happy with it, there's no reason to switch."

### The Tale of Sprockets and Webpacker Duality
- **Authors:** Vladimir Dementyev, Artem Shibakov | **Date:** September 13, 2021 | **URL:** https://evilmartians.com/chronicles/the-tale-of-sprockets-and-webpacker-duality
- **Summary:** Zero-downtime, gradual migration strategy from Sprockets to Webpacker on a large legacy app: compile both bundles from the same source in parallel, gate which one a given user gets via a feature flag, and roll forward/back per-user instead of an atomic cutover. JS source files carry both Sprockets `//= require` directives and ES module `import` statements marked `// webpack-only`; a custom Sprockets preprocessor strips the webpack-only lines so Sprockets only sees its own directives. Not Hotwire-specific, but directly useful as a template for any "run two asset pipelines side by side during a slow migration" project (e.g. migrating onto Vite/esbuild without a hard cutover).
- **Code worth stealing:**
```js
// app/assets/javascripts/admin.js — dual entrypoint, readable by both Sprockets and Webpack
//= require services/s3_service
//= require components/uploaders/input_uploader
//= require admin/index.js

import './services/s3_service'; // webpack-only
import './components/uploaders/input_uploader'; // webpack-only
import './admin/index'; // webpack-only
```
```ruby
# Custom Sprockets preprocessor that strips webpack-only lines/blocks
module Sprockets::WebpackOnlyProcessor
  class << self
    def call(input)
      data = input[:data].gsub(%r{^.*// webpack-only\s*$}, "")
      data.gsub!(%r{^\s*// webpack-only-begin.*^\s*// webpack-only-end\s*$}m, "")
      { data: data }
    end
  end
end

Rails.application.config.assets.configure do |env|
  env.register_preprocessor "application/javascript", Sprockets::WebpackOnlyProcessor
end
```
```ruby
# Per-user feature-flagged asset pipeline selection
def javascript_pack_tag(*args)
  if Rails.configuration.x.webpack_enabled ||
     (defined?(user_features) && user_features.enabled?("webpacker"))
    return super
  end

  javascript_include_tag(*args)
end
```
```js
// webpack alias config to resolve Bootstrap Sass imports identically to Sprockets
const config = {
  resolve: {
    alias: {
      'bootstrap/functions': resolve(__dirname, '..', '..', 'node_modules/bootstrap/scss/_functions.scss'),
      'bootstrap/variables': resolve(__dirname, '..', '..', 'node_modules/bootstrap/scss/_variables.scss'),
      'bootstrap/mixins': resolve(__dirname, '..', '..', 'node_modules/bootstrap/scss/_mixins.scss')
    }
  }
};
```
- **Opinion / hot take:** Pragmatic, not ideological: "this method will prove useful if you need a safer upgrade option" — explicitly frames the last 10% of a migration as harder than the first 90%, worth planning for.

### Keep up with the Tines: Rails frontend revamp
- **Authors:** Rita Klubochkina, Andy Barnov | **Date:** June 3, 2020 | **URL:** https://evilmartians.com/chronicles/keep-up-with-the-tines-a-rails-frontend-revamp
- **Summary:** Out of scope for this Hotwire/Turbo/Stimulus repo — confirmed by full read. This is a pre-Hotwire (2020) case study modernizing Tines' frontend from Rails Asset Pipeline views to Webpacker + React + TypeScript + MobX + GraphQL + Tailwind/CSS-Modules. No mention of Hotwire, Turbo, Stimulus, or ViewComponent anywhere in the article.
- **Code worth stealing:** Not transcribed — not relevant to this repo's scope. (One incidental technique if useful elsewhere: bridging React components into legacy CoffeeScript via `document.dispatchEvent(new CustomEvent("diagramDeleteAgent"))`.)
- **Opinion / hot take:** N/A — included here only to document that it was checked and ruled out, not fabricated as relevant.


### Rebuilding Turbo Rails (course) — hotrails.dev
See "Books / courses found" at top. Positioned explicitly as a debugging/internals-literacy tool: "Do you wish you could read the source code of a gem instead of relying on documentation?" Teaches Rails engine anatomy (`rails plugin new`, `test/dummy`), and turbo-rails' own security implementation, framed as transferable skill for reading any Rails engine (ActionText, ActiveStorage, etc).
- **Opinion / hot take:** "According to DHH, the secret to becoming a better Ruby on Rails developer is simple: you need to read a lot of software." Author's own admission of struggling to onboard into the Factory Bot gem's source motivated the course.

### Writing effective coding tutorials
- **Author:** David Colby | **URL:** https://colby.so/posts/writing-effective-coding-tutorials
- **Note:** Found via the full post index/atom feed but not fetched in depth for this pass (meta/writing-craft content, not a Hotwire technique post). Flagging its existence for completeness since it's adjacent to how Colby structures his tutorial-style Hotwire posts.

---


### Announcing Hotwire Spark: live reloading for Rails applications ★
- **Author:** Jorge Manrubia | **Date:** December 18, 2024 | **URL:** https://dev.37signals.com/announcing-hotwire-spark-live-reloading-for-rails/
- **Summary:** Live reloading designed for the no-build stack — it works *because* there's no bundler. Three change types handled differently: **HTML** → it morphs the `<body>` into the new `<body>`, disconnecting and reconnecting Stimulus controllers so state survives; **CSS** → reloads only the changed stylesheet, not the page; **Stimulus controllers** → fetches the changed controller, replaces its module in the Stimulus application, and reconnects all controllers. Net effect is HMR for Stimulus without any frontend build tool.
- **Code worth stealing:**
```ruby
# Gemfile
group :development do
  gem "hotwire-spark"
end
```
- **Opinion / hot take:** "Hot Module Replacement for Stimulus controllers without any frontend building tool" — the reload story is a direct *benefit* of no-build, not a cost. Design goal stated as: smooth enough that you perceive only the changes you intended.

### Lexxy: A new rich text editor for Rails
- **Author:** Jorge Manrubia | **Date:** September 4, 2025 | **URL:** https://dev.37signals.com/announcing-lexxy-a-new-rich-text-editor-for-rails/
- **Summary:** Trix's replacement, built on Meta's Lexical. Pitched as "a better Action Text": proper HTML semantics (real `<p>` tags rather than Trix's div soup), markdown shortcuts and auto-formatting, code syntax highlighting, URL→link conversion, configurable prompts for @-mentions, attachment previews for PDFs and video. Stated motivation: "Trix was falling short of expectations in certain areas, and we encountered technical barriers when attempting to offer the experience we wanted." Roadmap: Action Text gains pluggable editor configuration (like Active Record's database config) so alternative editors slot in and still work with Active Storage.
- **Note:** The announcement post itself has no implementation code — for the custom-element/Hotwire integration details, read the `basecamp/lexxy` repo directly. Worth a follow-up in this repo, since a Lexical-based custom element inside a Turbo page is a first-class example of "web component + Hotwire."

---


### hotwire.io — the community Hotwire hub ★
- **Curator:** Marco Roth | **URL:** https://hotwire.io/ | **Source:** https://github.com/marcoroth/hotwire.io
- **Summary:** Community-driven, explicitly **not** affiliated with the official Hotwire project. Positions Hotwire as "The JavaScript Ecosystem for Server-rendered Web-Applications" — i.e. framework-agnostic, not a Rails-only thing. Structure worth mining as a taxonomy for this repo:
  - **Ecosystem** — /ecosystem/core (core libraries), /ecosystem/extensions (extending core), /ecosystem/new-concepts, /ecosystem/helpers, /ecosystem/tooling
  - **Documentation** — /documentation/turbo, /stimulus, /hotwire-native, /turbo-power, /turbo-morph, /formulus
  - **Framework integrations** — /frameworks/{rails, laravel, symfony, django, wagtail, hanami, roda, bridgetown, camping, phoenix, spring, express, nestjs, node, flask, aspdotnet, amber, lucky, marten, coldfusion, micronaut}
  - **Community** — /community/education, /community/articles, /community/videos, /community/blogs
  - **Newsletter** — /newsletter → **Hotwire Weekly**
  - Featured plugins: turbo-power, turbo-morph, formulus, turbo-boost, stimulus-use
- **Opinion / hot take:** Framing to steal: "Hotwire is the catalyst that transforms your backend framework into a complete full-stack powerhouse" and "Turn your framework into a full-stack framework." The framework-integration list is the strongest evidence that HTML-over-the-wire is not a Rails idiosyncrasy.

### Marco Roth's open-source portfolio (the Hotwire tooling layer)
- **URL:** https://marcoroth.dev/open-source
- Roles: **maintainer of hotwired/stimulus**, maintainer of stimulus-use, contributor to hotwired/turbo + turbo-rails, core team on StimulusReflex and CableReady.
- Projects that matter for this repo:
  - **turbo_power** / **turbo_power-rails** — ~50 extra Turbo Stream actions (see above).
  - **turbo-morph** — standalone `morph` stream action.
  - **stimulus-lsp** — Language Server for Stimulus: autocomplete + diagnostics for controllers, targets, values, actions in your HTML/ERB. The highest-leverage DX tool for Stimulus.
  - **stimulus-parser** — static analysis of Stimulus controllers (powers the LSP).
  - **stimulus-lint** — Stimulus linting (now inside the Herb monorepo).
  - **turbo-lsp** — Language Server for Turbo.
  - **Herb** ecosystem — an HTML-aware ERB **parser** (C/C++/Ruby/WASM) plus **language server**, **linter**, and **formatter** for `.html.erb`. Introduced at RubyKaigi 2025; linter+formatter launched at RailsConf 2025.
  - **ReActionView** — an ActionView-compatible ERB engine and an initiative for the future of the Rails view layer; announced at Rails World 2025.
  - **current.js**, **phlexing**, **RubyEvents.org** (merged RubyConferences.org + RubyVideo.dev — a searchable archive of Ruby conference talks, useful for finding Hotwire talk videos).
- **Relevant posts:** https://marcoroth.dev/posts/introducing-herb (Apr 16, 2025), https://marcoroth.dev/posts/herb-language-server (Jun 20, 2025), https://marcoroth.dev/posts/railsconf-2025-recap (Jul 17, 2025 — Herb linter/formatter + a vision for Rails views), https://marcoroth.dev/posts/rails-world-2025-recap (Sep 11, 2025 — ReActionView, 24 min read).

### Turbo 8 Cheat-sheet (printable PDF)
- **Author:** Radan Skorić | **URL:** https://radan.dev/cheatsheet/ → PDF at https://radan.dev/assets/Turbo8cheatsheet.pdf
- Two-page printable A4 quick reference for Turbo 8. Free. Directly relevant as a model for a reference card in this repo.

---


Cross-referenced here (full entries live in their primary sections above): **8 Turbo 8 "Gotchas"** (fly.io, under Morphing) covers a `SimulatedSlowness` dev-only delay concern for surfacing loading states, and a `turbo-cable-stream-source`-breaks-CSS-grid layout gotcha. **Accommodating Safari Users** (fly.io, under Stimulus) covers an `esbuild`-via-Rake-task workaround for Stimulus static-class-field breakage on old Safari. **Ludicrously Fast Page Loads** (speedshop, under Turbo Drive & navigation) is a full Chrome DevTools Timeline/flamegraph profiling walkthrough using a Turbolinks page load as the worked example. **AI's "overnight" solution for our flaky tests** (thoughtbot, under Testing) is a case study in using an AI coding agent to debug flaky Stimulus/Hotwire system specs at scale.

No standalone tooling/debugging-only articles (browser extensions, LSPs, dev consoles) were found on any of the six sites searched.

---

---

## Native / mobile


### Announcing Hotwire Native
- **Author:** Jay Ohms | **Date:** September 25, 2024 | **URL:** https://dev.37signals.com/announcing-hotwire-native/
- **Summary:** Turbo Native + Strada merged and rebranded; the Hotwire umbrella becomes Turbo / Stimulus / Native. Key changes: a new navigation layer handling complex stack situations (Joe Masilotti's `TurboNavigator` library was absorbed into the iOS implementation); **path configuration** rules unified and made consistent across iOS and Android; **Bridge Components** (formerly Strada) now work out of the box with no extra integration; native screens can replace web screens and be routed to by URL. Setup reduced to a few lines of code.
- **Opinion / hot take:** The framing is progressive enhancement applied to mobile: ship the web app in a shell, then selectively promote individual screens to native rather than converting wholesale.

### Announcing Strada
- **Author:** Jay Ohms | **Date:** September 20, 2023 | **URL:** https://dev.37signals.com/announcing-strada/
- **Summary:** The original bridge-component announcement (superseded by Hotwire Native above). Historical value: it explains the web↔native message-passing model that Bridge Components still use.

### Speeding up mobile development with Turbo
- **Author:** Fernando Olivares | **Date:** February 22, 2024 | **URL:** https://dev.37signals.com/speeding-up-mobile-development-with-turbo/
- **Summary:** The economic case for hybrid. Techniques: hybrid architecture mixing native chrome (popover menus, push navigation) with web content; path-based view selection where Turbo-iOS intercepts navigation and decides per-route whether to open a new native view controller or update the webview in place; Turbo 8's page caching giving near-native perceived speed without building a mobile API; a dedicated web designer maintaining small-screen CSS so web content reads as native; full native reserved for high-traffic screens needing custom multi-touch gestures. Headline number: replacing a native table-view report screen with a Turbo-powered web view **deleted 10 files and 1,436 lines of code** at feature parity.
- **Opinion / hot take:** "Selective native implementation" — most screens Turbo, a few screens native, decided per-route in path configuration.

### Bringing Card Table to the small screen
- **Author:** Jirka Hutárek | **Date:** February 15, 2023 | **URL:** https://dev.37signals.com/bringing-card-table-to-the-small-screen/
- **Summary:** Hybrid-app design study. Explains that 37signals' apps "wrap every page of the Basecamp web app inside a native shell" via Turbo, letting the mobile team override individual pages natively. Card Table's bidirectional-scroll drag-and-drop was judged too demanding for a webview, so it went native in Jetpack Compose. The interesting part is the *interaction* redesign for small screens (collapsible Triage, one continuous scrollable space, context-sensitive column expansion) rather than responsive CSS.
- **Code worth stealing:** (Kotlin/Compose, included only as the native-override example)
```kotlin
@Composable
fun TriageHeader(
    triage: TriageColumn,
    expanded: Boolean,
    onAddCardToTriage: (columnId: Long) -> Unit,
    onTriageMenuClick: (columnId: Long) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier.fillMaxWidth()
    ) {
        ColumnHeaderButton(
            title = triage.title,
            cardsCount = triage.cards.size,
            expanded = expanded,
            modifier = Modifier.weight(1f)
        )
        AnimatedVisibility(visible = expanded) {
            Row {
                SmallFilledButton(
                    text = stringResource(R.string.add_card),
                    icon = Icons.Add,
                    onClick = { onAddCardToTriage(triage.id) }
                )
                IconButton(
                    icon = Icons.Menu,
                    contentDescription = stringResource(R.string.column_menu, triage.title),
                    onClick = { onTriageMenuClick(triage.id) }
                )
            }
        }
    }
}
```
- **Opinion / hot take:** "Judo" problem-solving — work within platform limits instead of fighting them. Concretely: when a webview can't deliver the interaction, promote that one screen, don't abandon the hybrid model.

---


### Turbo adapter: Hotwire Native's backdoor entrance ★★
- **Author:** Radan Skorić | **Date:** Jul 25, 2025 (updated Oct 1, 2025) | **URL:** https://radan.dev/articles/turbo-adapter-hotwire-native-backdoor-entrance
- **Summary:** Extracted from *Master Hotwire*. Explains exactly how Hotwire Native hooks into your web app — the single most useful thing to know when debugging web/native integration or deciding whether Hotwire Native fits. TL;DR: **Hotwire Native injects JavaScript that registers itself as Turbo's *adapter*, replacing the default `BrowserAdapter`.** A Hotwire Native app is a native shell around a webview (iOS `WKWebView`, Android `WebView`) running your mobile website; **only the web app talks to the server, which is why you generally don't need a separate mobile API.** Navigation can't be detected the naive way because Turbo Drive hijacks navigation, so Native plugs into Turbo's own visit pipeline: `Session#visit` → `Navigator#proposeVisit` (checks e.g. same-domain) → back to `Session` → `adapter.visitProposedToLocation(location, options)`. That last call is the hinge: the Native adapter uses it to ask the native code whether to let Turbo proceed or to stop and let native load the URL, then uses **path configuration** to decide how to present the screen.
- **Code worth stealing:**
```javascript
// The two calls that define the pipeline (Turbo source)
this.navigator.proposeVisit(expandURL(location), options)   // Session -> Navigator
this.adapter.visitProposedToLocation(location, options)     // Session -> Adapter

// Swap in your own adapter — this is exactly what Hotwire Native does
Turbo.registerAdapter(/* TurboNative instance */)
```
  The injected sources are worth reading directly:
  - iOS: https://github.com/hotwired/hotwire-native-ios/blob/main/Source/Turbo/WebView/turbo.js
  - Android: https://github.com/hotwired/hotwire-native-android/blob/main/core/src/main/assets/js/turbo.js
- **Opinion / hot take:** "If you're having trouble with web/native integration, [`visitProposedToLocation`] is a great place to start your investigation." Also opens with a haiku: *"A native embrace, / The blossom of the web, / Joined by an adapter."*

---


No standalone Turbo Native or Hotwire Native tutorial was found on any of the six sites searched (thoughtbot, boringrails, fly.io, honeybadger, appsignal, speedshop). The topic appears only conceptually:

- **Thinking in Hotwire: Progressive Enhancement** (boringrails, full entry under Philosophy / why-no-React) places Turbo Native and Strada at the top rungs of its progressive-enhancement ladder — reusing Rails views inside real Swift/Kotlin apps via webview, with HEY's inbox cited as an example of a fully-native screen alongside mostly-Rails-view screens.
- A thoughtbot CTO-interview piece ("Why CTOs are choosing Hotwire and Ruby on Rails," excluded elsewhere as promotional/no-code) mentions Turbo Native only in passing as a cross-platform cost-saving argument.

---


### Hotwire Native hub + "Hotwire Native for Rails Developers" ★
- **Author:** Joe Masilotti | **URL:** https://masilotti.com/hotwire-native/ | **Book:** https://pragprog.com/titles/jmnative/hotwire-native-for-rails-developers/ (Pragmatic Programmers)
- **Summary:** Masilotti is the authority here — he helped 37signals build the iOS library (his `TurboNavigator` was absorbed into Hotwire Native) and has shipped 25+ apps. The mental model he teaches: **two pieces do the work — a native navigation stack and a web view running Turbo.** The native side owns tab bars, navigation bars, transitions, gestures, push notifications, in-app purchases; the web side renders content; Turbo makes screen-to-screen movement feel instant. When a screen needs to be native or touch hardware (camera, biometrics, push), you drop to native via a **bridge component**, which "connects a Stimulus controller in your HTML to Swift or Kotlin, so you add native behavior without leaving the Rails mental model" — write the native code once, reuse it on every screen.
- **Where it does NOT fit (his words, worth quoting because it's rare honesty in this space):** apps that must work **fully offline today** ("Not today… though offline support is being explored"), and apps where **every screen needs heavy custom animation** — "you'll work against the framework more than with it."
- **Key evergreen pages:** https://masilotti.com/bridge-components/ (bridge components without writing Swift/Kotlin), https://masilotti.com/turbo-native-app-roadmap/ (what to build first, which store to launch to), https://masilotti.com/rails-developers-guide-to-mobile-app-frameworks/ (Feb 12, 2026 — decision guide comparing native / React Native / PWA / Hotwire Native).
- **Opinion / hot take:** "your Rails views *are* the mobile app… one codebase powers three places: the web, iOS, and Android. When you ship a feature or fix a bug in Rails, every platform gets it at the same time, with no app store review standing in the way." The counter-positioning is explicit: "This is the opposite of the React Native or fully native path, where every screen and feature gets built two or three more times."
- **Note on his archive:** most of his 2025–2026 writing has moved to Substack (https://newsletter.masilotti.com) — individual deep dives there include "Hotwire Native deep dive: In-app purchases on iOS" (Jan 22, 2026), "Getting your Hotwire Native app into the App Store" (Feb 26, 2026), "How to build a Rails app that's ready for the app stores" (Apr 28, 2026), "What I've learned from shipping 25+ mobile apps" (Feb 19, 2026). He has also launched **Ruby Native** (https://newsletter.masilotti.com/p/ruby-native-is-here, May 2026) — ship a Rails app to the App Store from a single YAML file without opening Xcode — and **PurchaseKit** (https://purchasekit.dev) for in-app purchases with native payment sheets and server-rendered paywalls.
- The full archive index is https://masilotti.com/archive/ (also served at `/articles/`).

---

---

## CSS & no-build styling


### Modern CSS patterns in Campfire ★
- **Author:** Jason Zimdars | **Date:** April 4, 2024 | **URL:** https://dev.37signals.com/modern-css-patterns-and-techniques-in-campfire/
- **Summary:** How to build a real product's CSS with zero preprocessor — the styling half of the no-build story. Techniques used: native CSS nesting; `:has()` for parent/ancestor queries; `:is()` / `:where()` (the latter for zero-specificity); `oklch()` wide-gamut colors composed from LCH custom properties; the View Transitions API; custom properties with fallbacks as the component-variant mechanism; character-based (`ch`) responsive units; and `any-hover` / `pointer` / `prefers-color-scheme` media queries to branch on input device rather than screen size.
- **Code worth stealing:**
```css
/* Color tokens as LCH triplets, composed into oklch() */
:root {
  --lch-gray: 96% 0.005 96;
  --lch-gray-dark: 92% 0.005 96;
  --lch-gray-darker: 75% 0.005 96;
}

--color-border: oklch(var(--lch-gray));
--color-link-50: oklch(var(--lch-blue) / 0.5);
```
```css
/* Component variants via custom-property fallbacks — no BEM modifier explosion */
.btn {
  align-items: center;
  background-color: var(--btn-background, var(--color-text-reversed));
  border-radius: var(--btn-border-radius);
  color: var(--btn-color, var(--color-text));
  padding: var(--btn-padding, 0.5em 1.1em);
}

.btn--reversed {
  --btn-background: var(--color-text);
}

.btn--negative {
  --btn-background: var(--color-negative);
}
```
```css
/* :has() to make a component adapt to its own content */
.btn img {
  -webkit-touch-callout: none;
  user-select: none;
}

&:where(:has(img):not(.avatar)) {
  img {
    filter: invert(0);
    inline-size: 1.3em;
  }
}

/* icon-only button: detect a screen-reader-only label + an image */
&:where(:has(.for-screen-reader):has(img)) {
  --btn-border-radius: 50%;
  --btn-padding: 0;
  aspect-ratio: 1;
  block-size: var(--btn-size);
  display: grid;
  place-items: center;
}
```
```css
/* Unread dot only when the sidebar is closed AND contains an unread item */
#sidebar:where(:not([open]):has(.unread)) & {
  &::after {
    --size: 1em;
    aspect-ratio: 1;
    background-color: var(--color-negative);
    border-radius: calc(var(--size) * 2);
    content: "";
  }
}

.membership-item:has(.btn.invisible) {
  opacity: 0.5;
}
```
```css
/* Avatar stack that restyles itself based on how many children it has */
.avatar__group {
  --avatar-size: 2.5ch;
  display: grid;
  grid-template-columns: 1fr 1fr;

  &:where(:has(> :last-child:nth-child(2))) {
    --avatar-size: 3.5ch;
  }

  &:where(:has(> :last-child:nth-child(3))) {
    > :last-child {
      margin-inline: 1.25ch -1.25ch;
    }
  }
}
```
```css
/* Breakpoint in ch, not px */
@media (max-width: 100ch) { /* … */ }

/* Branch on input capability, not viewport */
@media (any-hover: hover) {
  &:where(:not(:active):hover) { /* hover effect */ }
}

@media (any-hover: hover) and (pointer: fine) {
  /* reveal affordance only on hover */
}

@media (any-hover: none) and (pointer: coarse) {
  /* always show it on touch */
}
```
- **Opinion / hot take:** Campfire was built "#nobuild" — no compiler, no preprocessor. The `:has()`-driven components are the strongest practical argument that you no longer need a component framework to get content-adaptive UI.

---

---

## Conference talks


Best index: **https://rubyevents.org** (Marco Roth + Adrien Poly) — browsable by topic, e.g. `/topics/hotwire`, `/topics/turbo`, `/topics/hotwire-native`. Most entries link the video and many have transcripts. Note the topic tagging is imperfect: several tagged talks only mention Hotwire in passing.

| Talk | Speaker | Event / Year | Link | Key takeaway |
|---|---|---|---|---|
| **Turbo 8 morphing (the morphing reveal)** | Jorge Manrubia | Rails World 2023 | https://www.youtube.com/watch?v=m97UsXa6HFg | The talk version of "A happier happy path in Turbo with morphing" — the progressive ladder (full page → frames → streams), idiomorph, `broadcasts_refreshes`. The single most important Hotwire talk. |
| **Strada: Bridging The Web and Native Worlds** | Jay Ohms | Rails World 2023 | https://rubyevents.org/talks/strada-bridging-the-web-and-native-worlds | The bridge-component model (later folded into Hotwire Native). |
| **Building an Offline Experience with a Rails-powered PWA** | Alicia Rojas | Rails World 2023 | https://rubyevents.org/talks/building-an-offline-experience-with-a-rails-powered-pwa | Service workers + Rails; the offline story Hotwire itself lacks. |
| **Making Accessible Web Apps with Rails and Hotwire** | Bruno Prieto | Rails World 2024 | https://rubyevents.org/talks/making-accessible-web-apps-with-rails-and-hotwire | The a11y talk for Hotwire — focus management and announcements across Turbo navigations/streams. High priority for this repo. |
| **Revisiting the Hotwire Landscape after Turbo 8** | Marco Roth | RailsConf 2024 (also Brighton Ruby 2024, Helvetic Ruby 2024) | https://rubyevents.org/talks/revisiting-the-hotwire-landscape-after-turbo-8 | Ecosystem survey post-Turbo-8: what morphing changed, what the extension libraries are for now. |
| **Leveling Up Developer Tooling For The Modern Rails & Hotwire Era** | Marco Roth | Rocky Mountain Ruby 2024, EuRuKo 2024, Ruby Türkiye 2024 | https://rubyevents.org/talks/leveling-up-developer-tooling-for-the-modern-rails-hotwire-era | Stimulus LSP, stimulus-parser, Herb — why ERB/Stimulus needed real static analysis. |
| **Rails 8 Frontend: 10 commandments and 7 deadly sins in 2025** | Yaroslav Shmarov | EuRuKo 2024 | https://rubyevents.org/talks/rails-8-frontend-10-commandments-and-7-deadly-sins-in-2025 | Opinionated do/don't list for the modern Rails frontend. |
| **Lightning Talk: Turbo Morphing — Making the Jump** | Ron Shinall | Rocky Mountain Ruby 2024 | https://rubyevents.org/talks/lightning-talk-turbo-morphing-making-the-jump | Field report on migrating an existing app to morphing. |
| **Showing Progress of Background Jobs with Hotwire Turbo** | Michał Łęcicki | Ruby Unconf 2024 / Ruby Warsaw 2024 | https://rubyevents.org/talks/showing-progress-of-background-jobs-with-hotwire-turbo | Broadcasting job progress — a classic Turbo Streams use case. |
| **Building ChatGPT in Rails: Live Coding with Stimulus, Morphing, and Turbo Native** | Keith Schacht | SF Bay Area Ruby, Aug 2024 | https://rubyevents.org/talks/building-chatgpt-in-rails-live-coding-with-stimulus-morphing-and-turbo-native | Streaming LLM output into a Hotwire UI — live coded. |
| **Lightning Talk: Hotwire Native — Turn any Rails App into a Mobile App** | Yaroslav Shmarov | Rails World 2024 | https://rubyevents.org/talks/lightning-talk-hotwire-native-turn-any-rails-app-into-a-mobile-ios-android-app | Fastest possible on-ramp to Hotwire Native. |
| **Keynote: Hotwire Native — A Rails Developer's Secret Tool for Building Mobile Apps** | Joe Masilotti | Rails World 2025 | https://rubyevents.org/talks/keynote-hotwire-native-a-rails-developer-s-secret-tool-for-building-mobile-apps | The canonical Hotwire Native talk, keynote slot. |
| **Workshop: Hotwire Native** | Joe Masilotti | RailsConf 2025 | https://rubyevents.org/talks/workshop-hotwire-native-a-rails-developer-s-secret-tool-to-building-mobile-apps | Longer hands-on version of the keynote. |
| **Lessons from Migrating a Legacy Frontend to Hotwire** | Radan Skorić | Rails World 2025 | https://rubyevents.org/talks/lessons-from-migrating-a-legacy-frontend-to-hotwire | Incremental migration strategy — pairs with his "scope morphing to small sections first in legacy apps" advice. |
| **Coming Soon: Offline Mode to Hotwire with Service Workers** | Rosa Gutiérrez | Rails World 2025 | https://rubyevents.org/talks/coming-soon-offline-mode-to-hotwire-with-service-workers | 37signals working on the biggest acknowledged Hotwire gap. Watch this one. |
| **Introducing ReActionView: A new ActionView-Compatible ERB Engine** | Marco Roth | Rails World 2025 / EuRuKo 2025 / Kaigi on Rails 2025 | https://rubyevents.org/talks/introducing-reactionview-a-new-actionview-compatible-erb-engine | Where the Rails view layer is heading. |
| **The Modern View Layer Rails Deserves: A Vision for 2025 and Beyond** | Marco Roth | RailsConf 2025 | https://rubyevents.org/talks/the-modern-view-layer-rails-deserves-a-vision-for-2025-and-beyond | Herb + ReActionView vision talk. |
| **Rails Frontend Evolution: It Was a Setup All Along** | Svyatoslav Kryukov | RailsConf 2025 | https://rubyevents.org/talks/rails-frontend-evolution-it-was-a-setup-all-along | History of Rails frontend decisions; from the Evil Martians side. |
| **Defying Front-End Inertia: Inertia.js on Rails** | Svyatoslav Kryukov | Tropical on Rails 2025 | https://rubyevents.org/talks/defying-front-end-inertia-inertia-js-on-rails | The main *alternative* to Hotwire in the Rails world — worth covering to be credible. |
| **The Front-end is Omakase** | Cameron Dutro | RailsConf 2025 | https://rubyevents.org/talks/the-front-end-is-omakase | Direct riff on DHH's "Rails is omakase" applied to frontend choices. |
| **Keynote: Hotwire Demystified** | Chris Oliver | Tropical on Rails 2025 | https://rubyevents.org/talks/keynote-hotwire-demystified | GoRails' Chris Oliver explaining the whole model end to end. |
| **From React to Hotwire, the right path** | Jackson Pires | Tropical on Rails 2025 | https://rubyevents.org/talks/from-react-to-hotwire-the-right-path | Migration path talk. |
| **From React to Hotwire: The Adventures of a Frontend Migration** | Weldys Santos | Tropical.rb 2024 | https://rubyevents.org/talks/from-react-to-hotwire-the-adventures-of-a-frontend-migration | Same genre, different war story. |
| **Overreacting – from React to Hotwire** | Igor Aleksandrov | XO Ruby Atlanta 2025 | https://rubyevents.org/talks/overreacting-from-react-to-hotwire | Ditto. |
| **Lightning Talk: Ruby UI — From React to Hotwire** | Cirdes Henrique | RailsConf 2025 | https://rubyevents.org/talks/lightning-talk-ruby-ui-from-react-to-hotwire | Component-library angle (RubyUI). |
| **Bridging React and Rails with Superglue** | Johny Ho, Sally Hall | thoughtbot Open Summit 2025 | https://rubyevents.org/talks/bridging-react-and-rails-with-superglue | The "keep React but make it Rails-shaped" option. |
| **Hotwire meets The Platform™: a new way to build PWAs relying on native HTML APIs** | Edy Silva | Tropical on Rails 2025 | https://rubyevents.org/talks/hotwire-meets-the-platform-a-new-way-to-build-pwas-relying-on-native-html-apis | Native HTML APIs (dialog, popover, etc.) + Hotwire. |
| **The Great Mobile Hack: Hotwire Native** | Daniel Medina | Tropical on Rails 2025 | https://rubyevents.org/talks/the-great-mobile-hack-hotwire-native | Native field report. |
| **Ruby on Rails is a Game Engine** | Jonathan Woodard | Rocky Mountain Ruby 2025 | https://rubyevents.org/talks/ruby-on-rails-is-a-game-engine | Pushing Turbo Streams to real-time-game latency. |
| **TikTok on Rails** | Cecy Correa | XO Ruby Austin 2025 | https://rubyevents.org/talks/tiktok-on-rails | Building a feed UI with Hotwire. |
| **Ran out of eggs? Fix it with Hotwire Native** | Agustin Peluffo, Facundo Busto | Ruby Montevideo, Oct 2024 | https://rubyevents.org/talks/ran-out-of-eggs-fix-it-with-hotwire-native | Small-team Hotwire Native case study. |
| **Hotwire Turbo in Rails: Drive, Frames and Streams** | Helmer Davila | Montreal.rb, May 2024 | https://rubyevents.org/talks/hotwire-turbo-in-rails-drive-frames-and-streams | Straightforward intro to the three Turbo pieces. |
| **Retinas on Rails! — Eye spy with my little eye Macuject** | Bianca Power, Bradley Beddoes | RubyConf AU 2024 | https://rubyevents.org/talks/retinas-on-rails-eye-spy-with-my-little-eye-macuject | Medical imaging UI on Rails/Hotwire — unusually demanding UI case study. |
| **Evolution of real-time, AnyCable Pro and… me** | Irina Nazarova | Rocky Mountain Ruby 2024 / EuRuKo 2024 | https://rubyevents.org/talks/evolution-of-real-time-anycable-pro-and-me | The AnyCable (Evil Martians) angle on scaling Turbo Streams. |
| **Rails World opening keynotes** | DHH | Rails World 2023 / 2024 / 2025 | https://rubyevents.org/events/rails-world-2025 | Each keynote carries the current official frontend position (no-build, Propshaft, importmaps, Solid trilogy, Hotwire Native). |

---

---

## Open-source projects & libraries


### AnyCable
- **Repo:** https://github.com/anycable/anycable (core Go server) + https://github.com/anycable/anycable-rails (Ruby/Rails adapter gem)
- **Pattern demonstrated:** Drop-in replacement/accelerator for ActionCable — swaps the low-level WebSocket connection handling from the Ruby process to a separate Go-based server (anycable-go), while business logic (channels, broadcasting) stays in Ruby. Fully compatible with `turbo_stream_from` / `Turbo::StreamsChannel.broadcast_*_to` — for Hotwire-only apps, integration is "swap the adapter and everything works." Solves ActionCable's memory/CPU-per-connection cost and reconnection reliability at scale (used to broadcast Turbo Streams to thousands of concurrent connections). Also offers "at-least-once" delivery guarantees relevant to streaming LLM responses over Turbo Streams without dropping chunks.
- **Also relevant:** `<turbo-cable-presence-source>` custom element (from the "Simple Declarative Presence" article) — a single HTML tag gives automatic WebSocket subscription + live user counter + Turbo Stream DOM updates, no imperative JS.

### wsdirector (palkan/wsdirector)
- **Repo:** https://github.com/palkan/wsdirector
- **Pattern demonstrated:** Scenario-based integration testing for WebSocket servers (ActionCable, AnyCable, Phoenix Channels, GraphQL-WS) via YAML scripts describing `send`/`receive`/`subscribe`/`perform` sequences, including multi-client/group scenarios with a `multiplier` for load-style fan-out testing. Directly useful for testing Turbo Streams broadcast behavior end-to-end without a browser.
- **Code:**
```yaml
# Basic scenario
- receive: "Welcome"
- send:
    data: "send message"
- receive:
    data: "receive message"
```
```yaml
# Action Cable protocol example
- client:
    protocol: "action_cable"
    actions:
      - subscribe:
          channel: "ChatChannel"
      - perform:
          channel: "ChatChannel"
          action: "broadcast"
          data:
            text: "hello"
```
```yaml
# Multi-client group scenario with scale multiplier
- client:
    name: "publisher"
    multiplier: ":scale"
    actions:
      - receive:
          data: "Welcome"
      - wait_all
      - send:
          data: "test message"
- client:
    name: "listeners"
    multiplier: ":scale * 2"
    actions:
      - receive:
          data: "Welcome"
      - wait_all
      - receive:
          multiplier: ":scale"
          data: "test message"
```
```ruby
# Library usage
scenario = [
  { send: { data: "ping" } },
  { receive: { data: "pong" } }
]
result = WSDirector.run(scenario, url: "ws://my.ws.server:4949/live")
result.success? #=> true or false
```

### turbo-mount (skryukov/turbo-mount, an Evil Martians–originated project now community-maintained)
- **Repo:** https://github.com/skryukov/turbo-mount
- **Pattern demonstrated:** Bridges server-rendered Hotwire views with "islands" of React/Vue/Svelte components — mount a JS component into a Rails ERB view via a helper, pass server-side props as JSON, and (optionally) drive prop updates imperatively from a custom Stimulus-style controller. Positioned as the lightweight alternative to going full-SPA when only a couple of interactive widgets are needed.
- **Code worth stealing:**
```ruby
# Gemfile
gem "turbo-mount"
```
```bash
bin/rails generate turbo_mount:install
```
```ruby
# config/importmap.rb
pin "turbo-mount", to: "turbo-mount.min.js"
pin "turbo-mount/react", to: "turbo-mount/react.min.js"
```
```javascript
// app/javascript/turbo-mount.js
import { TurboMount } from "turbo-mount";
import { registerComponent } from "turbo-mount/react";
import { HexColorPicker } from 'react-colorful';

const turboMount = new TurboMount();
registerComponent(turboMount, "HexColorPicker", HexColorPicker);
```
```erb
<%= turbo_mount("HexColorPicker", props: {color: "#034"}, class: "mb-5") %>
```
```javascript
// Custom controller for imperative prop updates
export default class extends TurboMountController {
  get componentProps() {
    return {
      ...this.propsValue,
      onChange: this.onChange.bind(this),
    };
  }
  onChange = (color) => {
    this.setComponentProps({ ...this.propsValue, color });
  };
}
```

### view_component-contrib (palkan/view_component-contrib)
- **Repo:** https://github.com/palkan/view_component-contrib
- **Pattern demonstrated:** Meta-gem of ViewComponent extensions accumulated from real Evil Martians projects, not yet (or never) upstreamed. Most notable is **Style Variants** (a Ruby DSL clone of Tailwind Variants / CVA) for managing conditional Tailwind class combinations per component, sidecar reorganization (drop the `_component` suffix, colocate `component.rb`/`component.html`/`index.js`/`index.css`/`preview.rb` in one folder), sidecar Stimulus controllers (`controller.js` per component), CSS Modules scoping via PostCSS, namespaced I18n, and "wrapped" components (only render wrapper markup if the inner component actually renders something).
- **Code worth stealing:**
```ruby
class ButtonComponent < ViewComponent::Base
  include ViewComponentContrib::StyleVariants

  style do
    base {
      %w[font-medium bg-blue-500 text-white rounded-full]
    }
    variants {
      color {
        primary { %w[bg-blue-500 text-white] }
        secondary { %w[bg-purple-500 text-white] }
      }
      size {
        sm { "text-sm" }
        md { "text-base" }
        lg { "px-4 py-3 text-lg" }
      }
    }
    defaults { {size: :md, color: :primary} }
  end

  def initialize(size: nil, color: nil)
    @size = size
    @color = color
  end
end
```
```erb
<button class="<%= style(size:, color:) %>">Click me</button>
<%# with size: :lg, color: :secondary renders: %>
<%# <button class="font-medium bg-purple-500 text-white rounded-full px-4 py-3 text-lg"> %>
```
```
components/
  example/
    component.html
    component.rb
    preview.rb
    index.css
    index.js
    controller.js
```
```javascript
// controller.js — sidecar Stimulus controller per component
import { Controller as BaseController } from "@hotwired/stimulus";

export class Controller extends BaseController {
  connect() {
    // controller logic
  }
}
```
```erb
<%# Wrapped components: only render wrapper if inner component renders %>
<%= render Example::Component.new.wrapped do |wrapper| %>
  <div class="col-md-auto mb-4">
    <%= wrapper.component %>
  </div>
<% end %>
```
```yaml
# Namespaced I18n
en:
  view_components:
    login_form:
      submit: "Log in"
```
```erb
<button type="submit"><%= t(".submit") %></button>
```
- **Install:** `rails app:template LOCATION="https://railsbytes.com/script/zJosO5"`

### nanotags (psd-coder/nanotags — built by an Evil Martians engineer, featured on the blog)
- **Repo:** https://github.com/psd-coder/nanotags | docs: https://psd-coder.github.io/nanotags/
- **Pattern demonstrated:** A ~2.5KB typed, reactive wrapper around native Custom Elements (Web Components), powered by Nano Stores atoms for reactive props. No Shadow DOM (markup stays in the light/regular DOM, so it plays nicely with Turbo's DOM diffing/morphing and with global CSS). No virtual DOM, no template engine — deliberately minimal: reactive props, typed refs/events, automatic listener/subscription cleanup on disconnect. Used in production to migrate an Astro site off React + Ark UI onto native Web Components, saving ~100KB of JS with no functional loss — directly relevant as a "Web Components + Hotwire" building block since it avoids Shadow DOM's incompatibility with Turbo Stream/Frame replacement.
- **Related article:** "From React to native web with nanotags: a migration that saved 100 KB" — https://evilmartians.com/chronicles/from-react-to-native-web-with-nanotags-a-migration-that-saved-100kb

### Lite Cable (evilmartians/lite_cable)
- **Repo:** https://github.com/evilmartians/lite_cable
- **Pattern demonstrated:** Lightweight, dependency-light ActionCable-alike implementation for plain Ruby (non-Rails) apps needing WebSocket channel semantics.

### GraphQL-AnyCable, Kuby-AnyCable, xk6-cable, ACLI (evilmartians/anycable ecosystem)
- **Repos:** github.com/anycable/graphql-anycable, github.com/anycable/kuby-anycable, github.com/anycable/xk6-cable, github.com/anycable/acli
- **Pattern demonstrated:** Ecosystem tooling around AnyCable — GraphQL subscriptions transport, Kubernetes deployment plugin (Kuby), k6 load-testing extension for WebSocket load tests, and a minimal mruby CLI client for ActionCable-protocol servers. Useful for anyone standing up AnyCable in production alongside Turbo Streams broadcasting and needing to load-test or deploy it.

---

## Courses, books & full-catalogue indexes


- **"Hotwiring Rails" — David Colby**, ebook on Gumroad (`https://davidcolby.gumroad.com/`), ~$70. An 11-chapter, line-by-line walkthrough of building a Rails app (an Applicant Tracking System, code at `github.com/DavidColby/hotwired_ats_code`) using Stimulus, Turbo, CableReady, and StimulusReflex on Rails 7. Delivered as a custom web app rather than a PDF (clickable copy-paste code blocks, embedded GIFs). Colby's companion post `https://colby.so/posts/publishing-on-gumroad-lessons-learned` covers his self-publishing lessons (see Philosophy section).
- **"Rebuilding Turbo Rails" — Alexandre Ruban**, paid video course (`https://www.hotrails.dev/rebuilding-turbo-rails`), YouTube-hosted with a separate chapter index. Not a written tutorial — teaches rebuilding the `turbo-rails` gem from scratch as a Rails engine (using `rails plugin new`, `test/dummy`, ActionView/ActionCable/ActiveJob internals, turbo-rails' security model, rake install tasks, and gem-level testing) to teach how to read Rails engine source code. No code was transcribed since it's video content behind a paywall.

---


Free, ordered tutorial building a "quote editor" (later multi-tenant quoting) app. Site nav: `hotrails.dev` → Turbo Rails tutorial.

| # | Title | URL | Technique taught |
|---|-------|-----|-------------------|
| 0 | Turbo Rails tutorial introduction | `/turbo-rails/turbo-rails-tutorial-introduction` | Project setup (`rails new --css=sass --javascript=esbuild`), why Turbo replaces React/Redux for this author |
| 1 | A simple CRUD controller with Rails | `/turbo-rails/crud-controller-ruby-on-rails` | Plain Rails CRUD baseline (simple_form, `status: :unprocessable_entity`, system tests) before adding Turbo |
| 2 | Organizing CSS files in Ruby on Rails | `/turbo-rails/css-ruby-on-rails` | BEM + Sass partial architecture (mixins/config/components/layouts), CSS custom properties design tokens |
| 3 | Turbo Drive | `/turbo-rails/turbo-drive` | How Drive intercepts links/forms, `data-turbo="false"`, `data-turbo-track="reload"`, progress bar styling |
| 4 | Turbo Frames and Turbo Stream templates | `/turbo-rails/turbo-frames-and-turbo-streams` | Frame-per-record CRUD, `*.turbo_stream.erb` templates, `respond_to` + `format.turbo_stream` |
| 5 | Real-time updates with Turbo Streams | `/turbo-rails/turbo-streams` | Action Cable broadcasting from the model (`broadcasts_to`, `after_create_commit`), `turbo_stream_from` |
| 6 | Turbo Streams and security | `/turbo-rails/turbo-streams-security` | Scoping broadcasts per-tenant via lambda `broadcasts_to ->(quote) { [quote.company, "quotes"] }`, signed stream names |
| 7 | Flash messages with Hotwire | `/turbo-rails/flash-messages-hotwire` | `flash.now` + Turbo Stream partial injection, Stimulus-driven auto-dismiss via `animationend` |
| 8 | Two ways to handle empty states with Hotwire | `/turbo-rails/empty-states` | Server-rendered empty-state stream update vs. pure-CSS `:only-child` selector approach |
| 9 | Another CRUD controller with Turbo Rails | `/turbo-rails/turbo-rails-crud` | Nested resource (dates) with ordered insertion via `turbo_stream.after`/`.prepend` based on a `previous_date` model method |
| 10 | Nested Turbo Frames | `/turbo-rails/nested-turbo-frames` | Deeply nested frames (quote → date → line item) with a `nested_dom_id` helper to keep frame ids unique |
| 11 | Adding a quote total with Turbo Frames | `/turbo-rails/quote-totals-turbo-frames` | Cross-cutting computed total kept in sync via `turbo_stream.update` targeting a `dom_id(@quote, :total)` frame |

### Chapter 0: Turbo Rails tutorial introduction
- **Author:** Alexandre Ruban | **URL:** https://www.hotrails.dev/turbo-rails/turbo-rails-tutorial-introduction
- **Summary:** Sets up the tutorial's app (a quote editor: create/update/delete quotes, each with dates). Establishes prerequisites (CRUD, design systems, auth already known) and states the tutorial's promise: full understanding of Turbo's three parts (Drive, Frames, Streams) without custom JS.
- **Code worth stealing:**
```bash
rails new quote-editor --css=sass --javascript=esbuild --database=postgresql
```
```ruby
# Gemfile
gem "turbo-rails", "~> 1.0"
```
```
# Procfile.dev
web: bin/rails server -p 3000
js: yarn build --watch
css: yarn build:css --watch
```
- **Opinion / hot take:** "I was blown away by how easy it was to work with. And the best part? No more React, no more Redux, no more Formik! ... Boring? Yes, but I could get the benefits from React with a tenth of the effort."

### Chapter 1: A simple CRUD controller with Rails
- **Author:** Alexandre Ruban | **URL:** https://www.hotrails.dev/turbo-rails/crud-controller-ruby-on-rails
- **Summary:** Builds the baseline Quote CRUD (model, migration, routes, controller, simple_form views) with zero Turbo yet, deliberately, so later chapters layer Turbo cleanly on top of working Rails conventions. Emphasizes `status: :unprocessable_entity` on failed form re-renders (required later for Turbo Drive to behave).
- **Code worth stealing:**
```ruby
# app/models/quote.rb
class Quote < ApplicationRecord
  validates :name, presence: true
end
```
```ruby
class CreateQuotes < ActiveRecord::Migration[7.0]
  def change
    create_table :quotes do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
```
```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :quotes
end
```
- **Opinion / hot take:** "Testing is a fundamental part of software development" — author commits to Rails system tests + fixtures throughout the series, and stresses following Rails conventions so Turbo can be layered in with minimal JS later.

### Chapter 2: Organizing CSS files in Ruby on Rails
- **Author:** Alexandre Ruban | **URL:** https://www.hotrails.dev/turbo-rails/css-ruby-on-rails
- **Summary:** A BEM-based Sass file structure (`mixins/`, `config/`, `components/`, `layouts/`) with CSS custom properties for the whole design system (fonts, spacing scale, colors, shadows). Used throughout the rest of the tutorial's UI.
- **Code worth stealing:**
```
app/assets/stylesheets/
├── application.sass.scss
├── mixins/_media.scss
├── config/_variables.scss
├── config/_reset.scss
├── components/_btn.scss
├── components/_quote.scss
├── components/_form.scss
├── components/_visually_hidden.scss
├── components/_error_message.scss
└── layouts/_container.scss, _header.scss
```
```scss
// app/assets/stylesheets/config/_variables.scss
:root {
  --font-size-m: 1rem;
  --space-m: 1rem;
  --color-primary: hsl(350, 67%, 50%);
  --border-radius: 0.375rem;
  --border: solid 2px var(--color-light);
}
```
```scss
// app/assets/stylesheets/mixins/_media.scss
@mixin media($query) {
  @if $query == tabletAndUp {
    @media (min-width: 50rem) { @content; }
  }
}
```
```scss
// app/assets/stylesheets/application.sass.scss
@import "mixins/media";
@import "config/variables";
@import "config/reset";
@import "components/btn";
@import "components/error_message";
@import "components/form";
@import "components/visually_hidden";
@import "components/quote";
@import "layouts/container";
@import "layouts/header";
```
- **Opinion / hot take:** Components ideally shouldn't set external margins (author admits violating this pragmatically); define a fixed breakpoint list and use CSS custom properties instead of magic numbers for team consistency.

### Chapter 3: Turbo Drive
- **Author:** Alexandre Ruban | **URL:** https://www.hotrails.dev/turbo-rails/turbo-drive
- **Summary:** Explains Turbo Drive as an AJAX-ifier of every link click/form submit, replacing only `<body>`. Covers opting individual links/forms out with `data-turbo="false"`, disabling app-wide, `data-turbo-track="reload"` for asset-fingerprint-based reloads, and styling the progress bar.
- **Code worth stealing:**
```javascript
// app/javascript/application.js
import "@hotwired/turbo-rails"
import "./controllers"
```
```erb
<%= link_to "New quote", new_quote_path, class: "btn btn--primary", data: { turbo: false } %>
```
```javascript
// app/javascript/application.js — disable Drive app-wide
import { Turbo } from "@hotwired/turbo-rails"
Turbo.session.drive = false
```
```erb
<%# app/views/layouts/application.html.erb %>
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
<%= javascript_include_tag "application", "data-turbo-track": "reload", defer: true %>
```
```scss
// app/assets/stylesheets/components/_turbo_progress_bar.scss
.turbo-progress-bar {
  background: linear-gradient(to right, var(--color-primary), var(--color-primary-rotate));
}
```
```ruby
# app/controllers/application_controller.rb — temporary debug aid
before_action -> { sleep 3 }
```
- **Opinion / hot take:** Turbo Drive gives "substantial performance benefits for free without writing a single line of custom code." Rails 7 requires a 422 status on failed form re-renders for Drive to display errors correctly.

### Chapter 4: Turbo Frames and Turbo Stream templates
- **Author:** Alexandre Ruban | **URL:** https://www.hotrails.dev/turbo-rails/turbo-frames-and-turbo-streams
- **Summary:** Introduces `turbo_frame_tag`, the three frame-matching rules, and `respond_to`/`*.turbo_stream.erb` for create/destroy. Uses `dom_id()` extensively for frame naming and `data-turbo-frame: "_top"` to break out of a frame.
- **Code worth stealing:**
```erb
<%# app/views/quotes/index.html.erb %>
<%= turbo_frame_tag Quote.new %>
<%= turbo_frame_tag "quotes" do %>
  <%= render @quotes %>
<% end %>
```
```erb
<%# app/views/quotes/_quote.html.erb %>
<%= turbo_frame_tag quote do %>
  <div class="quote">
    <%= link_to quote.name, quote_path(quote), data: { turbo_frame: "_top" } %>
    ...
  </div>
<% end %>
```
```erb
<%# app/views/quotes/create.turbo_stream.erb %>
<%= turbo_stream.prepend "quotes", @quote %>
<%= turbo_stream.update Quote.new, "" %>
```
```erb
<%# app/views/quotes/destroy.turbo_stream.erb %>
<%= turbo_stream.remove @quote %>
```
```ruby
def create
  @quote = Quote.new(quote_params)
  if @quote.save
    respond_to do |format|
      format.html { redirect_to quotes_path, notice: "Quote was successfully created." }
      format.turbo_stream
    end
  else
    render :new, status: :unprocessable_entity
  end
end
```
```ruby
# test/system/quotes_test.rb
test "Creating a new quote" do
  visit quotes_path
  click_on "New quote"
  fill_in "Name", with: "Capybara quote"
  click_on "Create quote"
  assert_text "Capybara quote"
end
```
- **Opinion / hot take:** Turbo Frames excel at replacing discrete sections; Turbo Streams shine for multi-action responses and preserving page state.

### Chapter 5: Real-time updates with Turbo Streams
- **Author:** Alexandre Ruban | **URL:** https://www.hotrails.dev/turbo-rails/turbo-streams
- **Summary:** Progressive refinement of model-level broadcasting: raw `broadcast_prepend_to` → convention-based shorthand → full CRUD callbacks → async `_later` variants → final `broadcasts_to` one-liner.
- **Code worth stealing:**
```ruby
# app/models/quote.rb — final form
class Quote < ApplicationRecord
  broadcasts_to ->(quote) { "quotes" }, inserts_by: :prepend
end
```
```ruby
# intermediate steps shown along the way
after_create_commit -> { broadcast_prepend_to "quotes" }
after_update_commit -> { broadcast_replace_to "quotes" }
after_destroy_commit -> { broadcast_remove_to "quotes" }
# then async:
after_create_commit -> { broadcast_prepend_later_to "quotes" }
```
```erb
<%= turbo_stream_from "quotes" %>
```
```yaml
# config/cable.yml
development:
  adapter: redis
  url: redis://localhost:6379/1
```
- **Opinion / hot take:** "Broadcasting Turbo Streams asynchronously is the preferred method for performance reasons."

### Chapter 6: Turbo Streams and security
- **Author:** Alexandre Ruban | **URL:** https://www.hotrails.dev/turbo-rails/turbo-streams-security
- **Summary:** Multi-tenant security model: scope broadcasts to `[quote.company, "quotes"]` so only same-company users share a channel, scope controller queries through `current_company`, and rely on Turbo's signed stream names to prevent tampering. Includes fixtures demonstrating a would-be "eavesdropper" in a different company.
- **Code worth stealing:**
```ruby
# app/models/quote.rb
broadcasts_to ->(quote) { [quote.company, "quotes"] }, inserts_by: :prepend
```
```ruby
# app/controllers/application_controller.rb
def current_company
  @current_company ||= current_user.company if user_signed_in?
end
helper_method :current_company
```
```ruby
def index
  @quotes = current_company.quotes.ordered
end
```
```erb
<%= turbo_stream_from current_company, "quotes" %>
```
```yaml
# test/fixtures/users.yml
eavesdropper:
  company: pwc
  email: eavesdropper@pwc.com
  encrypted_password: <%= Devise::Encryptor.digest(User, 'password') %>
```
- **Opinion / hot take:** "Users who share broadcastings should have the lambda return an array with the same values. Users who shouldn't share broadcastings should have the lambda return an array with different values." Security isn't optional middleware — it's built into the broadcast architecture itself.

### Chapter 7: Flash messages with Hotwire
- **Author:** Alexandre Ruban | **URL:** https://www.hotrails.dev/turbo-rails/flash-messages-hotwire
- **Summary:** `flash.now` inside `format.turbo_stream` blocks + a `render_turbo_stream_flash_messages` helper prepended to every CRUD turbo_stream view; a Stimulus `removals` controller deletes the flash element from the DOM on `animationend` after a CSS fade animation.
- **Code worth stealing:**
```erb
<%# app/views/layouts/_flash.html.erb %>
<% flash.each do |flash_type, message| %>
  <div class="flash__message" data-controller="removals" data-action="animationend->removals#remove">
    <%= message %>
  </div>
<% end %>
```
```javascript
// app/javascript/controllers/removals_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  remove() { this.element.remove() }
}
```
```ruby
def create
  ...
  respond_to do |format|
    format.html { redirect_to quotes_path, notice: "Quote was successfully created." }
    format.turbo_stream { flash.now[:notice] = "Quote was successfully created." }
  end
end
```
```ruby
# app/helpers/application_helper.rb
def render_turbo_stream_flash_messages
  turbo_stream.prepend "flash", partial: "layouts/flash"
end
```
```scss
@keyframes appear-then-fade {
  0%, 100% { opacity: 0 }
  5%, 60%  { opacity: 1 }
}
.flash__message {
  animation: appear-then-fade 4s both;
}
```
- **Opinion / hot take:** Flash messages should physically leave the DOM after fading, not just become invisible, to avoid stray hover/focus bugs.

### Chapter 8: Two ways to handle empty states with Hotwire
- **Author:** Alexandre Ruban | **URL:** https://www.hotrails.dev/turbo-rails/empty-states
- **Summary:** Compares two techniques: (1) explicit server-side stream update rendering an empty-state partial after the last record is destroyed, vs. (2) a pure-CSS `.empty-state--only-child { display: none; &:only-child { display: revert } }` that requires no destroy-time branching at all, which the author prefers for collaborative/broadcast scenarios.
- **Code worth stealing:**
```erb
<%# app/views/quotes/destroy.turbo_stream.erb — method 1 %>
<%= turbo_stream.remove @quote %>
<% unless current_company.quotes.exists? %>
  <%= turbo_stream.update Quote.new do %>
    <%= render "quotes/empty_state" %>
  <% end %>
<% end %>
```
```scss
.empty-state--only-child {
  display: none;
  &:only-child { display: revert; }
}
```
```erb
<%# method 2 — always render the empty state, let CSS hide it %>
<%= turbo_frame_tag "quotes" do %>
  <%= render "quotes/empty_state" %>
  <%= render @quotes %>
<% end %>
```
- **Opinion / hot take:** The CSS `:only-child` approach is more elegant for collaborative environments where broadcasts arrive unpredictably from other users.

### Chapter 9: Another CRUD controller with Turbo Rails
- **Author:** Alexandre Ruban | **URL:** https://www.hotrails.dev/turbo-rails/turbo-rails-crud
- **Summary:** Adds a nested `LineItemDate` resource, and solves ordered insertion: a `previous_date` model method finds the date immediately before the new/updated one, and the turbo_stream view uses `turbo_stream.after previous_date` (or `.prepend` if none) to insert the new row in the correct position instead of re-rendering the whole list.
- **Code worth stealing:**
```ruby
# app/models/line_item_date.rb
class LineItemDate < ApplicationRecord
  belongs_to :quote
  validates :date, presence: true, uniqueness: { scope: :quote_id }
  scope :ordered, -> { order(date: :asc) }

  def previous_date
    quote.line_item_dates.ordered.where("date < ?", date).last
  end
end
```
```erb
<%# app/views/line_item_dates/create.turbo_stream.erb %>
<%= turbo_stream.update LineItemDate.new, "" %>
<% if previous_date = @line_item_date.previous_date %>
  <%= turbo_stream.after previous_date do %>
    <%= render @line_item_date, quote: @quote %>
  <% end %>
<% else %>
  <%= turbo_stream.prepend "line_item_dates" do %>
    <%= render @line_item_date, quote: @quote %>
  <% end %>
<% end %>
<%= render_turbo_stream_flash_messages %>
```
```ruby
# db/migrate — uniqueness at the DB level too
add_index :line_item_dates, [:date, :quote_id], unique: true
```
```ruby
# test/models/line_item_date_test.rb
test "#previous_date returns the quote's previous date when it exists" do
  assert_equal line_item_dates(:today), line_item_dates(:next_week).previous_date
end
```
- **Opinion / hot take:** "We will always start this way as we need our controllers to work properly before making any improvement" — build plain CRUD first, then layer Turbo on top, every time.

### Chapter 10: Nested Turbo Frames
- **Author:** Alexandre Ruban | **URL:** https://www.hotrails.dev/turbo-rails/nested-turbo-frames
- **Summary:** Introduces a `nested_dom_id` helper (`args.map { dom_id or literal }.join("_")`) to keep frame ids collision-free when frames nest three levels deep (quote → date → line item). Wraps collections, individual records, and "new" placeholders each in their own frame.
- **Code worth stealing:**
```ruby
# app/helpers/application_helper.rb
def nested_dom_id(*args)
  args.map { |arg| arg.respond_to?(:to_key) ? dom_id(arg) : arg }.join("_")
end
```
```erb
<%= turbo_frame_tag nested_dom_id(line_item_date, "line_items") do %>
  <%= render line_item_date.line_items, quote: quote, line_item_date: line_item_date %>
<% end %>
<%= turbo_frame_tag nested_dom_id(line_item_date, LineItem.new) %>
```
```erb
<%# app/views/line_items/create.turbo_stream.erb %>
<%= turbo_stream.update nested_dom_id(@line_item_date, LineItem.new), "" %>
<%= turbo_stream.append nested_dom_id(@line_item_date, "line_items") do %>
  <%= render @line_item, quote: @quote, line_item_date: @line_item_date %>
<% end %>
```
- **Opinion / hot take:** "Turbo Frames must have unique ids on the page to work properly" — generic ids like `line_items` collide across multiple parents. Acknowledged limitation: reordering the parent list loses open child form state rather than implementing a JS workaround; build CRUD without frames first, then add frames/streams incrementally to avoid debugging confusion.

### Chapter 11: Adding a quote total with Turbo Frames
- **Author:** Alexandre Ruban | **URL:** https://www.hotrails.dev/turbo-rails/quote-totals-turbo-frames
- **Summary:** A cross-cutting computed total (sum across nested line items) kept live by wrapping it in its own frame keyed off `dom_id(@quote, :total)`, updated from every line-item create/update/destroy turbo_stream view.
- **Code worth stealing:**
```erb
<%= turbo_frame_tag dom_id(@quote, :total) do %>
  <%= render "quotes/total", quote: @quote %>
<% end %>
```
```ruby
# app/models/quote.rb
def total_price
  line_items.sum(&:total_price)
end
```
```erb
<%# app/views/line_items/create.turbo_stream.erb %>
<%= turbo_stream.update dom_id(@quote, :total) do %>
  <%= render "quotes/total", quote: @quote %>
<% end %>
```
- **Opinion / hot take:** "My *personal preference* here is always to use Turbo Frame tags as it makes it obvious that the id is used somewhere in a Turbo Stream view," even when a plain div with an id would technically work.

---


Tag pages: https://gorails.com/episodes/tagged/Hotwire , /tagged/Turbo , /tagged/Frontend . (`/tagged/stimulus` lowercase returns nothing — the tag is capitalized; Stimulus content is spread across the Hotwire/Javascript/Frontend tags.)
Chris Oliver also sells a dedicated course: **Learn Hotwire** — https://learnhotwire.com. GoRails' OSS is at https://github.com/gorails-screencasts and https://gorails.com/open-source.

**Free** = no "Pro" badge on the listing.

| Title | URL | Date | Technique taught | Free? |
|---|---|---|---|---|
| Realtime Domain Updates with Turbo Refreshes & Morph | /episodes/realtime-domain-updates-with-turbo-morph | Dec 12, 2025 | Background jobs pushing UI updates via `refresh` stream action + morphing instead of hand-written stream targets | Pro |
| Adding Turbo Frame Test Helpers | /episodes/adding-turbo-frame-test-helpers | Jun 16, 2025 | Writing your own test assertions for `<turbo-frame>` tags in responses, extending turbo-rails | Pro |
| Live Reloading with Hotwire Spark | /episodes/hotwire-spark | Dec 23, 2024 | Installing/using Hotwire Spark; morphing-based live reload | Free |
| CloudFlare Turnstile Captchas in Rails | /episodes/cloudflare-turnstile-captchas-in-rails | Sep 23, 2024 | Third-party JS widget inside a Turbo-driven form (the "non-Turbo-aware library" problem) | Pro |
| Responsive Navigation with Turbo | /episodes/responsive-navigation-with-turbo | Aug 14, 2023 | Serving genuinely different mobile vs desktop widgets (a `<select>` for mobile nav) rather than CSS-hiding both | Free |
| Dynamic Nested Forms With Turbo Part 2 | /episodes/dynamic-nested-forms-with-turbo-part-2 | Jul 17, 2023 | Removing/deleting nested fields from a dynamic nested form | Pro |
| Refactoring Turbo Streams into Turbo Frames | /episodes/refactoring-turbo-streams-into-turbo-frames | Jul 10, 2023 | When a stream `replace` is really just a frame — simplify by deleting the stream | Free |
| Liking Posts in Rails with Hotwire | /episodes/liking-posts-in-rails-with-hotwire | Jun 26, 2023 | Rebuild of their most popular episode with **zero custom JavaScript** | Pro |
| Custom Turbo Stream Actions | /episodes/custom-turbo-stream-actions | Apr 03, 2023 | Building custom stream actions (browser notifications, console logging) + reading Turbo's own implementation | Pro |
| Auto-submitting Forms & Custom Turbo Stream Actions | /episodes/custom-turbo-stream-actions-and-auto-submitting-forms | Mar 27, 2023 | Auto-submit a form on input change; update the page with a custom stream action | Free |
| Turbo Confirm Modals with Confirmation Text | /episodes/turbo-confirm-modals-with-confirmation-text-in-rails | Feb 06, 2023 | "Type the name to confirm" destructive-action modal via a custom `Turbo.setConfirmMethod` | Pro |
| Dynamic Nested Forms with Turbo | /episodes/dynamic-nested-forms-with-turbo | Nov 28, 2022 | Refactoring a Stimulus-based nested-attributes form to use Turbo GET requests instead (46 hearts — their most-loved Hotwire episode) | Pro |
| Custom Turbo Confirm Modals with Hotwire | /episodes/custom-hotwire-turbo-confirm-modals | Jun 13, 2022 | Overriding `Turbo.setConfirmMethod` with a promise so Turbo awaits your own modal | Free |
| Inline Editing with Turbo Frames | /episodes/inline-editing-turbo-frames | Feb 01, 2022 | Reusable inline editing for *any* field on *any* model via frames | Free |
| Realtime Charts with Stimulus Target Callbacks | /episodes/realtime-charts-with-stimulus-target-callbacks | Jan 17, 2022 | `xTargetConnected` / `xTargetDisconnected` callbacks to drive live chart updates | Pro |
| Migrating from Rails UJS to Hotwire: Data Method, Confirm, Disable With | /episodes/turbo-data-confirm-method-and-disable | Dec 29, 2021 | The Turbo equivalents of UJS `data-method` / `data-confirm` / `data-disable-with` | Free |
| Setting up Customer Support models with Hotwire | /episodes/rails-hotwire-actionmailbox-part-1 | Apr 28, 2021 | App setup wiring Hotwire + ActionMailbox | Free |
| Flash Messages and Toasts with Hotwire & Turbo.js | /episodes/hotwire-flash-messages | Mar 15, 2021 | Delivering flash/toast notifications when updates arrive over streams (flashes don't "just work" with partial updates) | Pro |
| Realtime Nested Comments: Part 3 | /episodes/realtime-nested-comments-part-3 | Feb 15, 2021 | Custom stream targets for nested comment rendering, form reset, appends | Pro |
| Realtime Nested Comments: Part 2 | /episodes/realtime-nested-comments-part-2 | Feb 08, 2021 | Broadcasting nested comment changes | Free |
| Realtime Nested Comments: Part 1 | /episodes/realtime-nested-comments-part-1 | Feb 02, 2021 | Nested comments foundation | Free |
| Hotwire Modal Forms | /episodes/hotwire-modal-forms | Jan 12, 2021 | Modal forms that render validation errors in place and redirect on success — the canonical hard case | Pro |
| How to upgrade from Turbolinks to Hotwire & Turbo | /episodes/upgrade-from-turbolinks-to-hotwire-and-turbo | Jan 05, 2021 | Migration path; Turbo's error-response handling is what makes it simple | Free |
| How to use Devise with Hotwire & Turbo.js | /episodes/devise-hotwire-turbo | Jan 01, 2021 | The Devise + Turbo form-interception fix (422 responses, `turbo_stream` format) — still one of the most-hit problems | Free |
| How to use Hotwire in Rails | /episodes/hotwire-rails | Dec 23, 2020 | The original launch-day episode: a Twitter clone in Hotwire | Free |
| How to use CodeMirror with ImportMaps | /episodes/how-to-use-codemirror-with-importmaps | Apr 07, 2025 | Pinning a complex third-party editor under importmaps (no-build) | Free |
| Rails Request.js Query Option | /episodes/rails-requestjs-query-option | Aug 09, 2021 | `@rails/request.js` — the sanctioned way to make fetch requests from Stimulus | Pro |

**Notes:** Episode video/code is paywalled ("Pro"), but every listing page carries a usable one-line technique description, and the free episodes are watchable. The 2020–2021 cluster is essentially a historical record of Hotwire's first six months; the 2022–2025 cluster (custom stream actions, dynamic nested forms, inline editing, frame test helpers, morphing) is the currently useful material.

---


**Correct index:** https://railsdesigner.com/articles/ (note: `/blog/` 404s). Filtered category: https://railsdesigner.com/articles/hotwire/ — **~75 Hotwire/Stimulus articles**, plus `/articles/javascript/`, `/articles/css/`, `/articles/viewcomponent/`. Feeds: `/feed.xml`, `/feed/notes.xml`, `/feed/changelog.xml`.

Products/OSS worth knowing: **Rails Designer UI Components** (200+ components, paid, https://railsdesigner.com/components/), **Attractive.js** (a "JavaScript-free JavaScript library" — declarative `data-action` behaviors with no controller of your own, https://attractivejs.railsdesigner.com , source https://github.com/rails-designer/attractivejs), **Rails Icons**, **Perron** (Rails-based static site generator), **Turbo Transition**, **Rails Vault**, **Courrier**, **Fuik**, and the book **JavaScript for Rails Developers**. Demo repos live under https://github.com/rails-designer-repos.

### Turbo Drive, Frames, Streams, Morph? What to use?! ★★ (the decision guide)
- **Author:** Rails Designer | **Date:** May 2025 | **URL:** https://railsdesigner.com/turbo-drive-frame-stream-morph/ | **Free**
- **Demo repo:** https://github.com/rails-designer-repos/turbo-when ([start commit](https://github.com/rails-designer-repos/turbo-when/commit/28dff0bae604dcd0ab61a7de80151c1ee61bf51f), [end commit](https://github.com/rails-designer-repos/turbo-when/commit/69e58d8477df2b1faaea817ed3f6913547694bee))
- **Summary:** Walks a single "like a post" feature up the Turbo ladder and shows exactly where each rung breaks. Stated reach-for order: **1. Turbo Drive → 2. Turbo Frame → 3. Turbo Stream (incl. broadcasts) → 4. Turbo Morph.** Drive alone works (the button label and the `<h1>` count both update, since only the body is injected) but the page scrolls to top; `<meta name="turbo-refresh-scroll" content="preserve">` fixes body scroll **but not scroll inside a nested scrolling element** — that's the concrete trigger to move to a Frame. A Frame fixes scroll and the button, but now the `<h1>` like-count outside the frame goes stale — that's the concrete trigger to move to Streams. He extracts the title into its own partial with an `id` and replaces both regions.
- **Code worth stealing:**
```erb
<%# app/views/layouts/application.html.erb %>
<meta name="turbo-refresh-scroll" content="preserve">
```
```erb
<%# Step 2: wrap the region in a frame %>
<turbo-frame id="likes">
  <% if user.likes.exists?(post: post) %>
    <%= button_to post_like_path(post, user.likes.find_by(post: post)), method: :delete do %>
      Unlike
    <% end %>
  <% else %>
    <%= button_to post_likes_path(post), method: :post do %>
      Like
    <% end %>
  <% end %>
</turbo-frame>
```
```erb
<%# app/views/posts/_title.html.erb — extracted so a stream can target it %>
<h1 id="title">
  <%= post.title %>
  (<%= pluralize(post.likes.count, "like") %>)
</h1>
```
```erb
<%# app/views/likes/create.turbo_stream.erb (destroy.turbo_stream.erb is identical) %>
<%= turbo_stream.replace "likes" do %>
  <%= render partial: "likes/like", locals: { user: Current.user, post: @post } %>
<% end %>

<%= turbo_stream.replace "title" do %>
  <%= render partial: "posts/title", locals: { post: @post } %>
<% end %>
```
- **Opinion / hot take:**
  > "You can try to use Stimulus on a per-component basis, but you get way more bang for your buck if you write general-purpose controllers instead."
  > "You get the most value out of Hotwire if you follow progressive enhancement."
  On the identical create/destroy stream templates: "I prefer my actions to be RESTful and down the road requirements between what needs to happen between the actions might change. So I'd rather have some duplication then making my code too smart." — a deliberate, quotable anti-DRY stance for Turbo Stream templates.

### Use native dialog with Turbo (and no extra JavaScript) ★★
- **Author:** Rails Designer | **Date:** 8 January 2026 | **URL:** https://railsdesigner.com/dialog-turboframe/ | **Free** | **Code:** https://github.com/rails-designer-repos/turbo-dialog
- **Summary:** Modals *and* slide-over panels with **zero custom JavaScript**: one `<dialog id="overlay" closedby="any">` in the layout containing one empty `<turbo-frame id="modal">`; links carry `data-turbo-frame="modal"` to load content into it, plus an Attractive.js `dialog#openModal` action to open the dialog. `closedby="any"` gives click-outside and Escape-to-close for free. The modal-vs-slider variant is chosen by setting a `type` attribute on the dialog *before* opening (`addAttribute#type=modal dialog#openModal` — **order matters**, or styles from the other type leak), and all presentation differences are pure CSS attribute selectors. Enter/exit animation uses `@starting-style` (`starting:` in Tailwind), and mobile modals slide up from the bottom while sliders keep sliding in from the right.
- **Code worth stealing:**
```erb
<%# app/views/layouts/application.html.erb — ONE dialog serves every modal and slider %>
<dialog
  id="overlay"
  closedby="any"
  class="
    px-3 py-4 max-w-md w-full
    opacity-100 scale-100 translate-x-0 translate-y-0
    shadow-2xl
    starting:opacity-0
    transition-all duration-300

    /* Modal-specific */
    [&[type=modal]]:m-auto
    [&[type=modal]]:rounded-lg
    [&[type=modal]]:starting:scale-95
    [&[type=modal]]:backdrop:bg-black/50 [&[type=modal]]:backdrop:backdrop-blur-sm
    [&[type=modal]]:max-sm:mb-0 [&[type=modal]]:max-sm:rounded-b-none
    [&[type=modal]]:max-sm:starting:translate-y-full
    [&[type=modal]]:max-sm:starting:scale-100
    [&[type=modal]]:sm:my-auto

    /* Slider-specific */
    [&[type=slider]]:m-0 [&[type=slider]]:ml-auto
    [&[type=slider]]:h-screen [&[type=slider]]:max-h-none [&[type=slider]]:max-w-sm
    [&[type=slider]]:rounded-l-lg
    [&[type=slider]]:starting:translate-x-full
  "
>
  <%= tag.turbo_frame id: :modal %>
</dialog>
```
```javascript
// app/javascript/application.js
import "@hotwired/turbo-rails"
import "controllers"

import attractivejs from "https://esm.sh/attractivejs";
```
```erb
<%# Links — type is set BEFORE the dialog opens %>
<%= link_to "Show modal", modal_path,
      data: {action: "addAttribute#type=modal dialog#openModal", target: "#overlay", turbo_frame: :modal} %>

<%= link_to "Show slider", slider_path,
      data: {action: "addAttribute#type=slider dialog#openModal", target: "#overlay", turbo_frame: :modal} %>
```
```ruby
# Endpoints just return a matching frame — no template needed for trivial content
def slider
  render html: helpers.tag.turbo_frame("Slider content", id: :modal)
end
```
- **Opinion / hot take:** "Browsers get more and more powerful features, like `dialog`. Using these keeps your code simple and easier to maintain. The native dialog element provides accessibility features like focus trapping and escape key handling." He also flags the **Invoker Commands API** as the next step that would remove even the Attractive.js layer — though "setting the Turbo Frame `src` attribute would still be needed."

### Rails Designer — the rest of the Hotwire catalogue (grouped, all at railsdesigner.com/<slug>/)

**Turbo Frames patterns**
- Visual loading states for Turbo Frames with **CSS only** — `/visual-loading-turbo-frames/` (Oct 2025) — uses the `[busy]`/`aria-busy` attribute Turbo sets on a loading frame; no JS.
- Conditionally Style Turbo Frame Content — `/turbo-frame-conditional-styles/`
- Easy Peasy Form Validation Errors with Rails Turbo Frames (modals) — `/turbo-frame-form-validations/`
- Launch a Turbo Modal with URL Params Using Stimulus — `/rails-turbo-frame-on-load/`
- How to create Modals with Rails and Hotwire (and Tailwind CSS) — `/modal-with-rails-hotwire/`
- How to add a skeleton UI to Rails with Turbo — `/rails-skeleton-ui/`

**Turbo Streams patterns**
- How do Turbo Streams Work (behind the scenes) — `/turbo-streams-behind-the-scenes/`
- Broadcast Turbo Streams **without Redis** — `/turbo-stream-without-redis/` (solid_cable era)
- User-Specific Content in Turbo Stream Partials — `/user-content-turbo-streams/` (Aug 2025) — the classic broadcast problem: a broadcast partial has no `current_user`.
- Update favicon with badge using custom turbo streams — `/update-favicon-badge-turbo-stream/`
- Update page title counter with custom turbo streams — `/update-page-title-turbo/`
- Update a Progress Bar using Turbo Streams (Custom Actions) — `/progress-bar-turbo/`
- Smooth Transitions with Turbo Streams — `/turbo-stream-transitions/` (and the gem: Introducing Turbo Transition — `/introducing-turbo-transition/`)
- ViewComponent over Turbo Stream Broadcasts — `/viewcomponents-in-turbo-streams/`
- Add a "X is writing…" indicator with Rails and Turbo — `/ux-is-typing/`
- Use cases for Turbo's Custom Events — `/turbo-custom-events/`

**Turbo Drive / navigation / UX**
- Customize the Turbo Progress Bar — `/turbo-progress-bar/`
- How to Add Disabled State to Buttons with Turbo & Tailwind — `/disable-submit-turbo-tailwind/`
- Custom Confirm Dialog For Turbo and Rails — `/custom-confirm-dialog/`
- Replace Turbo confirm with native dialog — `/turboless-confirm/` (Feb 2026)
- Building optimistic UI in Rails powered by Turbo — `/turbo-powered-optimistic-ui/` (Jan 2026)
- Building optimistic UI in Rails (and learn custom elements) — `/custom-elements/` (Dec 2025) — **when to use a custom element instead of a Stimulus controller**; one of their most-read.
- Inline editing with custom elements in Rails — `/custom-element-inline-edit/`
- Creating a link-icon custom element — `/link-icon-custom-elements/`

**Forms**
- Nested Forms With Turbo (without dependencies) — `/rails-nested-forms-with-turbo/`
- Building Nested Forms in Rails with Stimulus — `/rails-nested-form-with-stimulus/`
- Adding edit, delete and reposition for nested forms with Stimulus — `/extending-nested-forms-stimulus/`
- Nested forms without `accepts_nested_attributes_for` — `/nested-forms-without-accepts-nested-attributes/`
- Add a multi-step form/wizard to your Rails app — `/multistep-forms/`
- Inline Save and Add Another with Rails and Hotwire — `/inline-save-and-another/`
- Basic Autocomplete Without JavaScript using Datalist — `/basic-autocomplate-without-js/`
- Reusable drag-and-drop image preview — `/image-upload-element/`; Preview an Image Before Upload — `/preview-images-with-hotwire/`; Drag & Drop Images with Preview using Stimulus **Outlets** — `/drag-drop-image-preview-stimulus/`; ActiveStorage Direct Upload with Stimulus — `/direct-upload-stimulus/`
- Catch JavaScript errors with user-friendly error feedback — `/js-errors-feedback/`

**Stimulus design & patterns** (the strongest sub-corpus anywhere on Stimulus craft)
- How to Properly Structure Stimulus Controller — `/proper-stimulus-controllers/`
- Stimulus basics: what is a Stimulus controller? — `/stimulus-basics/`
- Stimulus Features You (Didn't) Know — `/lesser-known-stimulus-features/`
- Inheritance with Stimulus Controllers — `/inheritance-with-stimulus/`
- Communicating between Stimulus Controllers using the Outlets API — `/communication-between-stimulus-controllers/`
- Refactor Stimulus.js Controllers to Use Change Callbacks — `/refactor-stimulus-change-callbacks/`
- Connected and Disconnected **Target** Callbacks — `/connect-disconnect-targets/`
- Why Disconnect in Stimulus Controllers — `/disconnect-stimulus-controllers/`
- Smarter Use of Stimulus' Action Parameters — `/smarter-action-parameters/`
- Advanced Stimulus: Custom Action Options — `/stimulus-custom-action-options/`
- Enhanced debugging for Stimulus — `/stimulus-enhanced-debugging/`
- How to Send Requests from Stimulus Controllers — `/request-from-stimulus-controller/`
- Store UI State in localStorage with Stimulus — `/localstorage-stimulus/`
- Translations in Stimulus Controllers — `/translations-in-stimulus/` and Beyond translations: dates, time, currency — `/beyond-translations-in-stimulus/`
- Using the Keyboard with Stimulus — `/keyboard-events-with-stimulus/`; Hotkeys — `/rails-hotkeys/`; Konami Codes — `/konami-stimulus/`
- Touch Events (swipe) using Stimulus — `/stimulus-touch-events/`
- Shift+Click Selection for Bulk Actions — `/shift-selection/`
- Toggle class controllers — `/stimulus-toggle-class/`, `/multiple-classes-stimulus/`, `/conditional-css-classes-in-stimulus/`
- Changing CSS as You Scroll — `/change-css-scroll-stimulus/`; Resizable Navigation — `/resize-with-stimulus/`; Animated Counter — `/counter-with-stimulus/`; macOS-inspired stack UI — `/stimulus-stack-ui/`; before/after image slider — `/before-after-images-stimulus/`
- **Recreating Stimulus** series (2026) — `/recreating-stimulus-controllers/` (ES6 classes, Map, MutationObserver, WeakMap) and `/recreating-stimulus-targets-actions-values/` (Object.defineProperty, event delegation, static class fields, type coercion). The best available explanation of *how Stimulus works internally*.
- Hotwire and Stimulus Tools You Need to Know — `/best-hotwire-stimulus-tools/`

**Bigger builds / case studies**
- Create a Kanban board with Rails and Hotwire — `/kanban-rails-hotwire/` (Oct 2025) and Extending the Kanban board — `/extending-kanban-rails-hotwire/`
- Build a Notion-like editor with Rails — `/rails-block-editor/` + part 2 `/rails-block-editor-part-2/`
- Create a Markdown-Powered Textarea with Stimulus — `/markdown-textarea/`
- Recurring Calendar Events in Rails — `/calendar-recurring-events/` + Natural Language Parser for recurring events — `/natural-language-parsing/`
- Building a quiz with Stimulus — `/quiz-stimulus/`; custom emojis — `/custom-emoji-stimulus/`; video hover preview — `/video-hover-preview-stimulus/`; record video — `/recording-video-stimulus/`
- Components in Rails **without gems** — `/vanilla-components/` (Sep 2025)

**CSS / tooling adjacent**
- Understanding importmap-rails — `/importmap-rails/`; Modern CSS organization (in Rails) — `/modern-css-organization/`; 10 Modern CSS Features You Want to Use — `/modern-css-overview/`; CSS Counters — `/css-counters/`; cubic-bezier transitions — `/transitions-with-cubic-bezier/`; Choosing colors (OKLCH) — `/color-for-rails-developers/`; Rails' Partial Features You (Didn't) Know — `/rails-partial-features/`; Rails `dom_id` without exposing the primary id — `/dom-id-without-primary-id/`.

---

---

## Appendix — coverage notes, gaps & inaccessible sources


**hotrails.dev — fully covered:**
- Homepage nav confirmed only 4 top-level items: Turbo Rails tutorial, Rebuilding Turbo Rails (paid course), Articles, Quote editor (a live demo app, not an article).
- `/articles` currently lists exactly **one** written article ("Build modals with Hotwire") — confirmed via both WebFetch and raw `curl` + link-grep of the page, so nothing was missed there.
- All 12 Turbo Rails Tutorial chapters fetched and transcribed.
- `WebSearch site:hotrails.dev` returned nothing beyond what was already found (mostly false-positive Wikipedia "Hot-" results).
- Nothing on hotrails.dev was inaccessible; no curl fallback was needed.

**colby.so — broadly covered:**
- Full post inventory recovered via `colby.so/atom.xml` (48 posts total) and the `/writing` + `/writing/page2/` index pages — this is the authoritative complete list, more complete than the homepage alone (which listed no posts) or `/posts` (404s — the correct path is `/writing`).
- 24 Hotwire/Turbo/Stimulus-relevant posts fully transcribed in depth above.
- 7 older StimulusReflex/CableReady-era real-time posts identified but not transcribed in code-level depth (listed by title/URL in the Real-time section) — these predate native Turbo Streams and are largely superseded by Turbo-native rewrites of the same demos that *were* transcribed.
- Non-Hotwire posts on the site (product-management essays like "Do less," "Shape Up reflections," "Quit Doing Stupid Shit," monthly "Hotwiring Rails Newsletter" roundups, a video-converter/FFmpeg post) were excluded as out of scope.
- "Writing effective coding tutorials" was found but not read in depth (noted above, low priority — craft/meta content).
- Nothing on colby.so was inaccessible; no curl-impersonate fallback was needed (plain `curl` with a standard user-agent worked fine for both the writing index and atom feed).

`faster-paging-in-hey` (pure MySQL composite-index optimization, no frontend content — despite the promising title), `the-radiating-programmer`, `good-concerns`, `fractal-journeys`, `active-record-nice-and-blended`, `domain-driven-boldness`, `leaning-imperative`, `pending-tests`, plus all infra posts (Kamal, Thruster, Solid Queue/Cache, datacenter, YJIT, ONCE app server, Upright, multi-tenancy, S3 migration).

- `introducing-action-push-native` (Aug 2025, Jacopo Beschi) — web push for Hotwire Native apps.
- `announcing-hotwire-native-v1-2` (Apr 2025, Jay Ohms).
- `fizzy-infrastructure` (Feb 2026) — infra-focused, but Fizzy is a new 37signals Hotwire app worth checking for frontend posts.

- **Using Turbo Frames and Streams without Rails** (Nov 28, 2023) — https://radan.dev/experiments/using-turbo-frame-streams-without-rails — rebuilds a to-do app with Turbo and no Rails; the best proof that Turbo is backend-agnostic, and the reference app used in several of his other articles.
- **Exercise: Multiplayer Minesweeper with Rails and Hotwire** (Jul 29, 2024) — https://radan.dev/experiments/multiplayer-minesweeper-with-rails-and-hotwire — the collaborative-game case study behind the versioned-updates article.
- **Pagy Out, Turbo In: Transforming Pagination with Infinite Scrolling and Turbo** (guest post by Miha, Jan 9, 2024) — https://radan.dev/guest-articles/pagy-out-turbo-in — infinite scroll with lazy frames; pairs with the prefetch-lazy controller.
- **Rails 8 Assets series** (4 parts, Mar–Apr 2025) — the no-build asset story in depth: `rails-assets-propshaft-importmaps` (how Propshaft and importmap-rails work together), `rails-assets-deep-dive-propshaft`, `rails-assets-combine-importmaps`, `rails-assets-bundled-with-vanilla` (adding one bundled package alongside a vanilla setup — the pragmatic escape hatch).
- **Practical CSS: simplifying UI code with pseudo-classes** (Apr 8, 2026) — https://radan.dev/articles/css-pseudo-classes-practical-examples — pairs with 37signals' Campfire CSS post.
- **Rails is better low code than low code** (Nov 26, 2024).


- **thoughtbot:** 19 articles read in full. Nothing was 403'd or bot-blocked. Excluded as out of scope: the Superglue series (thoughtbot's competing React-on-Rails framework, not Hotwire), a pure announcement post, and a promotional CTO interview.
- **boringrails.com:** Site has only 19 long-form articles total (verified via sitemap.xml + Wayback Machine CDX cross-check) plus ~30 short "Tiny Tips." 11 long-form + 3 tips included here (14 total); the rest were non-Hotwire (migrations, CI, mailers, etc.). No "Digging into Turbo" internals series or dedicated single-file-component article exists on this domain despite that reputation.
- **fly.io:** Rails/Hotwire content lives entirely under `fly.io/ruby-dispatch/` (Brad Gessler, Sam Ruby); the main `/blog/` has essentially none, and `/blog/topic/hotwire/` 404s. 7 of ~35 Ruby Dispatch posts were substantively about Turbo/Stimulus.
- **honeybadger.io/blog + blog.appsignal.com:** 13 articles included (4 honeybadger, 9 appsignal) after filtering out shallow SEO fluff (8 posts excluded, listed in `site-honeybadger-appsignal.md`).
- **speedshop.co:** Full 27-post sitemap checked. Only 5 posts engage with Turbo/Turbolinks/Hotwire at all — Nate Berkopec writes performance philosophy/audits, not Hotwire tutorials. No dedicated post-2020 Hotwire benchmark exists; the 2026 AO3 audit is the only Hotwire-era post.
- Nothing across any of the six sites required the `curl-impersonate` fallback — all WebFetch/curl requests succeeded directly.


- **itsameandrea.com (Andrea Fomera)** — the site is **gone**. `https://itsameandrea.com/`, `/blog`, and `/articles` all return a bare `Hello World!` placeholder (HTTP 200, so it isn't a block — the site has been taken down or replaced). Her Hotwire posts would need to be recovered from the Wayback Machine if wanted.
- **railsdesigner.com/blog/** returns 404 — the real index is `/articles/`. Noted so nobody re-chases it.
- **GoRails episode bodies/videos** are paywalled ("Pro" badge). Titles, dates, and one-line technique descriptions are public and captured above; free episodes are fully watchable.
- **WebSearch was unavailable** for this batch (session-wide search budget exhausted), so discovery was done by direct navigation and link enumeration. GoRails episodes tagged only under `Javascript`/`Forms`/`Notifications` etc. may be missing from the table.


- **Sean Doyle's Stack Overflow answers** — `stackoverflow.com` returned "Enable JavaScript and cookies to continue" even through curl-impersonate (Chrome 145 TLS fingerprint). His SO answers are frequently cited as the deepest Turbo Q&A anywhere and remain **unmined**. Would need a real browser session. His GitHub PR/issue write-ups in `hotwired/turbo` and `hotwired/turbo-rails` are reachable and are the best substitute — worth a dedicated pass.
- **Sean Doyle has no personal blog** that I could find; `dev.to/seanpdoyle` is a 404. His writing lives on the thoughtbot blog (10 posts, ~5 Hotwire-relevant, all listed above) plus the `hotwire-example-template` repo, which is arguably the real body of work.
- **Julian Rubisch** — `julianrubisch.at` **no longer has any Rails content**. The domain is now an art/music site ("programmverdichter", concrete poetry and Subtractive Lutherie); his Rails/StimulusReflex writing appears to be gone. His StimulusReflex/CableReady material survives only via the project docs (`docs.stimulusreflex.com`, `cableready.stimulusreflex.com`) and his book *Building Reactive Rails Applications*. **Treat StimulusReflex/CableReady as a historical branch**: Marco Roth is still core team on both, but Turbo 8 morphing + `broadcasts_refreshes` absorbed most of their use cases.
- **Joe Masilotti's recent deep dives are on Substack** (newsletter.masilotti.com) rather than his own site; individually fetchable but each is a separate page — not exhaustively mined here.
- **WebSearch budget was exhausted session-wide** partway through this batch, so discovery relied on direct navigation (rubyevents.org topic pages, author archive pages, the GitHub API). Some talks tagged under other topics may be missing from the table.
