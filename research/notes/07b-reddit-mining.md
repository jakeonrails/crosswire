# 07b — Reddit Mining: Hotwire problems, answers, and sentiment

**Compiled 2026-08-15.** Companion to [`07-problem-mining.md`](./07-problem-mining.md), which covered Stack Overflow, discuss.hotwired.dev, GitHub and HN but could not reach Reddit. This document fills that gap. Versions treated as current throughout: **Turbo 8.0.x, turbo-rails 2.0.x, Stimulus 3.2.x, Rails 8.1.x.**

Nothing here duplicates the sibling document's 60 questions, 18 pain points, or 195 recipe candidates unless explicitly flagged as a *confirmation* of one.

---

## Method & coverage

Reddit itself (`reddit.com`, `old.reddit.com`) remained hard-blocked from this network, as it was for the sibling agent. Everything below was retrieved through **third-party Reddit archive APIs**, not from Reddit.

| Archive | Endpoint | What it gave me | Where it failed |
|---|---|---|---|
| **PullPush** (`api.pullpush.io`) | `/reddit/search/submission/` | ~960 r/rails submission rows across 24 query terms, ranked by score | Archive tail is **2025-05-18** (`_meta.retrieved_2nd_on = 1747603799`; newest submission returned: 2025-05-17). After ~40 requests it began returning `429`, then a hard block: *"Rate limit exceeded. This website does not provide free scraping resources for agents."* Comment search was never successfully reached before the block. |
| **Arctic Shift** (`arctic-shift.photon-reddit.com`) | `/api/posts/search`, `/api/posts/ids`, `/api/comments/search?link_id=` | **The workhorse.** Full coverage through **2026-08-15 (today)** — I retrieved r/rails posts from the morning of the compile date. Per-thread comment fetch by `link_id` is fast and reliable. | `comments/search` with a `body=` term (with or without `subreddit=`) **always** returned `Timeout. Maybe slow down a bit`. Broad `posts/search` with `sort=` also timed out. So there is **no full-text comment search in this corpus** — only whole-thread reads. |

**Queries actually run.** Submission searches for: `hotwire`, `turbo`, `turbo frames`, `turbo streams`, `stimulus`, `turbo morph`, `morphing`, `hotwire vs react`, `hotwire vs inertia`, `inertia`, `nested form`, `modal`, `infinite scroll`, `autocomplete`, `file upload`, `drag drop`, `hotwire native`, `importmap`, `view_component`, `phlex`, `turbo 8`, `turbo drive`, `stimulus controller`, `htmx`, `liveview` — against **r/rails, r/ruby, r/rubyonrails, r/webdev, r/experienceddevs**, plus unscoped searches. Then title-scoped sweeps of r/rails/r/ruby/r/rubyonrails/r/webdev/r/experienceddevs and a dedicated `after=2025-06-01` sweep of r/rails to cover the window PullPush cannot reach.

**Threads read in full: 94**, comprising **~1,090 comments** with score > 0, from posts spanning **2020-11-12 → 2026-08-11**. Every quote below carries its thread's permalink and the comment's score.

### Archive-completeness caveats — read these before trusting any number here

- **Scores and comment counts are archive snapshots, not live values.** PullPush and Arctic Shift disagree by 5–25% on the same post (e.g. `1ew4uo8` is 95/114 in PullPush and 75/106 in Arctic Shift). I report Arctic Shift's values because its ingest is more recent. Treat all scores as ±20%.
- **Comment coverage thins for very recent threads.** For the r/webdev thread from 2026-08-06 I could only retrieve low-score comments, and no top-level scores above 6 — the archive had not yet re-crawled for updated scores.
- **Deleted/removed comments are missing**, and heavily-downvoted comments (score ≤ 0) were filtered out of my corpus by design. This biases the sample *toward* consensus and *against* the most contrarian takes.
- **No full-text comment search means I could not measure how often bad advice is repeated on Reddit.** I can only report what appears in the 94 threads I read. See "Corrections" below — I state plainly what I could and could not verify.
- r/experienceddevs produced **essentially nothing**: every "stimulus" hit was about US government stimulus checks, and Hotwire is not discussed there under any of my query terms. r/webdev discusses Turbo only as an outsider curiosity. **The real corpus is r/rails, with r/ruby and r/rubyonrails as thin satellites.**

---

## New recipe candidates

Cross-checked against all 195 items in `07-problem-mining.md`. These are the ones Reddit surfaced that are **not** on that list.

### High confidence — real recurring pain, concrete recipe

1. **★ Browser page-translation (Google Translate, Chrome's built-in translate) breaks Turbo Drive and morphing.**
   Reported as reproducing across *all* of one dev's Rails apps, not one bug: after translating, Turbo navigation stops behaving. The only workaround the thread found was `data-turbo="false"` on links, which the reporter refused to ship. thoughtbot's *Turbo morphing woes* is the closest published treatment. This is a whole class of problem — **third-party DOM mutators that Idiomorph then fights** — that no Hotwire doc addresses.
   [r/rails 1lb5h5x](https://www.reddit.com/r/rails/comments/1lb5h5x/) (6/7, 2025-06-14)

2. **★ Beat the 0.5-second broadcast debounce: versioned immediate updates.**
   `broadcast_refresh_later_to` routes through `Turbo::ThreadDebouncer`, whose `DEFAULT_DELAY` is **0.5 seconds** — and *only* refreshes are debounced, not other stream actions. For latency-sensitive shared UIs (live dashboards, collaboratively-edited forms, games) that half second is the whole complaint. The recipe: carry a monotonically increasing version on the record, broadcast an immediate `replace` alongside the debounced refresh, and have the client drop out-of-order frames. Author is Radan Skorić (turbo-rails book author), verified against turbo-rails source in-thread.
   [r/rails 1ux509m](https://www.reddit.com/r/rails/comments/1ux509m/) (23/13, 2026-07-15)

3. **★ Modal forms under Turbo 8 morphing + `broadcasts_refreshes`, with *no* `.turbo_stream.erb` per action.**
   This is the sibling doc's canonical Q4 problem *restated for the morphing era*, and Reddit's answer is different from the frames-plus-streams answer. The asker explicitly rejects `data-turbo-frame="_top"` (it kills the modal on validation failure) and rejects per-action stream templates. The accepted answer is a scoped `turbo:frame-missing` handler that visits the response URL on success and paints an inline error otherwise. Worth its own recipe because "Turbo 8 morphing + modal + redirect" is now the default new-app shape.
   ```js
   document.addEventListener("turbo:frame-missing", (event) => {
     if (event.target.id !== "modal") return
     const { response } = event.detail
     event.preventDefault()
     if (response.ok && response.status < 400) {
       event.detail.visit(response.url, { action: "replace" })
     } else {
       event.target.innerHTML = `<div class="error">Couldn't load this. Try again.</div>`
     }
   })
   ```
   [r/rails 1mxxyyh](https://www.reddit.com/r/rails/comments/1mxxyyh/) (20/10, 2025-08-23) — 14-score answer by `enki-42`, confirmed working by the asker.

4. **★ Turbo Frame error boundaries.** The general form of #3: a frame that fails should degrade to a visible error *inside the frame*, never to a broken whole page and never to a silent empty box. `enki-42`'s reason for adding the error branch is the recipe's whole justification: *"without it, a frame breaking resulted in the whole page breaking and it can make smaller bugs much more severe."* (Adjacent to list items #36/#38, but neither frames it as a reusable boundary component.)
   Also: [r/rails 1sxtq7h](https://www.reddit.com/r/rails/comments/1sxtq7h/) "Turbo Frames — Error Boundaries" (2026-04-28).

5. **★ Nested HTML forms: a Delete button inside an Edit form.** UJS solved this with `data-method`; Turbo does not, and HTML forbids nesting `<form>`. The answer is the HTML5 `form=` attribute plus `formaction`/`formmethod` on the button — no JS. Author wrote it up as "my notes about nested HTML forms" precisely because the UJS→Turbo migration surfaces it.
   [r/rails 1ps8nfo](https://www.reddit.com/r/rails/comments/1ps8nfo/) (22/1, 2025-12-21)

6. **★ Direct-upload an image and get a usable URL *before* the record is saved.** Active Storage direct upload → `signed_id` → render/preview → attach on create. Distinct from list items #158–162, which all assume a persisted record.
   [r/rails 10ldca6](https://www.reddit.com/r/rails/comments/10ldca6/) (2023-01-25)

7. **★ A `data-turbo-track="reload"` script whose URL contains a changing timestamp makes every navigation a full page reload — and silently eats your flash.**
   The best root-cause find in the whole corpus, and it took the reporter days. Symptom: after a form submit, the log shows the show action processed **twice** — once as `TURBO_STREAM`, once as `HTML` — and the second request wipes the flash. Every wrong theory was tried first (Devise `navigational_formats`, `status: :see_other`, `target: "_top"`, giving up and disabling Turbo on all forms). Actual cause:
   > *"In my header, I had a JS library via a CDN link which I copy pasted without paying much attention… The link contains a `data-turbo-track="reload"` with a changing timestamp; just removing the turbo-tracking solves the issue."* — `rafamunez`
   Turbo compares tracked asset URLs between snapshots; a cache-busting timestamp in the URL means they never match, so Turbo forces a full reload on every visit. Generalises to any CDN snippet pasted into `<head>`. Adjacent to sibling pain point P14 but a distinct mechanism, and the diagnostic signature (*two GETs in the log, flash gone*) is worth memorising.
   [r/rails 102qh6d](https://www.reddit.com/r/rails/comments/102qh6d/) (2023-01-04)

8. **★ One controller per *page interaction*, not per model — the answer to "my Turbo components aren't self-contained."**
   The clearest architectural guidance in the corpus, and it directly addresses the componentization complaint below:
   > *"the controller's responsibility is not 'update the comment' but 'drive the page interaction where the comment gets updated'. If I have two separate page interactions with different needs that both happen to update the same kind of record, it's still two separate page interactions, which means I probably need two separate controllers or at least two separate actions. I'd much rather do it this way than try to weave conditionals and magic parameters and other stuff in there."* — `GreenCalligrapher571` **(16)**
   With the anti-pattern named explicitly — **"magic params"** (a hidden field or query param that makes one action behave two ways): *"in the desire to reuse code, you end up with more complex code. It's not that bad if there's just one param, but what if there are 7?"* And a warning about the tempting shortcut: **view variants were designed for platform-specific templates, not for this** (`pinzonjulian`). Controllers are cheap; make more of them.
   [r/rails 14g9dgc](https://www.reddit.com/r/rails/comments/14g9dgc/) (2023-06-22)

9. **Background-job progress: a status row + Turbo Stream, not polling.** A `Job`/`Export` model row that the worker updates, broadcasting progress to a stream. The list has "stream LLM responses token-by-token" (#94) but no generic long-job progress recipe, and this is the more common need (exports, imports, reports).
   [r/rails 1ac7lli](https://www.reddit.com/r/rails/comments/1ac7lli/) (2024-01-27)
   **And its companion**: broadcasting progress from a plain loop with **no model at all**, using `Turbo::StreamsChannel` directly — a class Reddit found *"absolutely nowhere"* in the docs:
   ```ruby
   Turbo::StreamsChannel.broadcast_replace_to "match-count",
     target: "match-count", partial: "partials/match_count", locals: { count: }
   ```
   with `<%= turbo_stream_from "match-count" %>` on the page. The asker's framing is the recipe's reason for existing: *"Why do I need to go through the database to send an update to the client?"* Throttling advice from the thread: broadcast every N iterations, not every one, or the UI flickers and you flood the client.
   [r/rails 12eqzu0](https://www.reddit.com/r/rails/comments/12eqzu0/) (2023-04-07)

10. **Server-driven live form preview: re-render the whole form on every change without losing the cursor.** The technique named repeatedly for on-blur/on-keystroke validation: wrap the form in a frame, `requestSubmit()` on `change`, send a `preview=1` param so the action **does not call `save`** and only renders validation state — then rely on Turbo 8 morphing to preserve caret position and untouched input values. Pre-morph this needed morphdom or `optimism`. Distinct from list #13 (submit-time errors) and #29 (dual validation).
   [r/rails s19z3j](https://www.reddit.com/r/rails/comments/s19z3j/) — `palkan` (10) and `gorliggs` (25); [r/rails x9k9h9](https://www.reddit.com/r/rails/comments/x9k9h9/)

11. **Mount a React/Svelte island in a Hotwire page — and make it survive the Turbo snapshot cache.** The list has "vendor an ESM library into an importmap" but no island recipe, and this is the single most-recommended escape hatch on Reddit. The trap named in-thread: **`turbo-mount` does not automatically handle Turbo cache compatibility, so browser back/forward can break your mounted component** unless you handle it. Tools named: `turbo-mount`, `islandjs-rails`, `superglue`, `react-rails`.
   [r/rails 1oppg76](https://www.reddit.com/r/rails/comments/1oppg76/), [r/rails 1e6sg28](https://www.reddit.com/r/rails/comments/1e6sg28/)

### Hotwire Native — an entire cluster the 195-item list does not touch

The sibling list rates "mobile app parity" as **PARTIAL** but contains **zero Hotwire Native recipes**. Reddit's Hotwire Native discussion is large, positive, and specific, and the maintainer (`joemasilotti`) answers in-thread.

12. **★ Wrap an existing Rails app in Hotwire Native — path configuration, native stacks vs modals.** [r/rails 1otcn0o](https://www.reddit.com/r/rails/comments/1otcn0o/) (29/19)
13. **★ Bridge Components: replace an HTML element with a native control** (bottom nav, top-bar overflow menu, native buttons, toasts, haptics on drag, camera/sensor access). [r/rails 1otcn0o](https://www.reddit.com/r/rails/comments/1otcn0o/), [1sjj19f](https://www.reddit.com/r/rails/comments/1sjj19f/)
14. **OAuth inside a Hotwire Native app via a bridge component.** [r/rails 1qr5658](https://www.reddit.com/r/rails/comments/1qr5658/) (2026-01-30)
15. **Push notifications in Hotwire Native.** [r/rails 1p2e3jq](https://www.reddit.com/r/rails/comments/1p2e3jq/) (37 score, 2025-11-20)
16. **★ A *single* offline flow in Hotwire Native — and the honest boundary.** The best answer in the corpus on offline, and it contradicts a flat "no good answer": precache routes in a service worker, hold task state in IndexedDB, intercept `POST`/`PUT` in the SW and queue them, replay on reconnect. Then the boundary: *"If techs need to browse and edit a queue of 20+ tasks while offline for hours… you end up writing Stimulus controllers that read from IndexedDB and patch the DOM, which is reinventing a client-side framework inside Hotwire."* The maintainer's own triage is a three-way fork (build that one flow fully native / cache-and-render-native on connection loss / don't use Hotwire Native).
   [r/rails 1tghfkz](https://www.reddit.com/r/rails/comments/1tghfkz/) (27/8, 2026-05-18)
17. **The sequencing rule for Hotwire Native projects: build the web app first, add Native second.** From a consultant who lived the failure mode of doing them in lockstep. [r/rails 1otcn0o](https://www.reddit.com/r/rails/comments/1otcn0o/) — `winebiddle` (2).

### Organizational / architectural recipes

18. **★ A custom Turbo Stream action registry.** One `app/javascript/turbo_stream_actions/index.js` that registers every custom action in one place — including actions that call into Stimulus controllers (`open_modal`, `close_modal`, `redirect`, `update_url`). List item #65 covers *writing* one action; this covers surviving twenty of them.
19. **★ "Responder" objects: keep stream-building out of controllers.** Controller collects models and calls `responder.create_success(...)`; the responder owns which panels get replaced and where to redirect. *"I don't like back-end code being responsible for knowing which panels need to be updated… The upside is that testing is spectacularly easy."*
   Both from `ikariusrb`, [r/rails 1tcdhwo](https://www.reddit.com/r/rails/comments/1tcdhwo/) (2–3 each) and [r/ruby 1ow04bf](https://www.reddit.com/r/ruby/comments/1ow04bf/).
20. **Where to put lazy-frame endpoints** — routes, controllers, and view files for frames whose only job is to be `src`'d. Asked directly as "Organizing lazy turbo_frame files"; no canonical answer exists. [r/rails 10ky1p4](https://www.reddit.com/r/rails/comments/10ky1p4/)
21. **Skip `respond_to` when you only ever answer `turbo_stream`.** A 22-score correction to a popular post: `render turbo_stream: [...]` needs no `respond_to` block unless a second format genuinely differs. Reddit's stated preference is to put multi-action responses in a `*.turbo_stream.erb` template rather than inline. [r/ruby 1ow04bf](https://www.reddit.com/r/ruby/comments/1ow04bf/) (45/12)
22. **Diagnose a Turbo Streams/Action Cable app that "stalls" under load.** Real report at ~100 concurrent users where **polling outperformed Action Cable**, plus the diagnostic path Reddit recommends: instrument backend p99s first, then *watch real sessions* (`spectator_sport`, PostHog, Sentry replay) rather than guessing. Also: Safari drops WebSocket connections. Distinct from list #90 (cost) and #187 (dev vs prod).
   [r/rails 1vl7fnw](https://www.reddit.com/r/rails/comments/1vl7fnw/) (2026-08-11 — four days before compile)
23. **Get an IDE that understands Stimulus.** The single most-repeated *ergonomic* complaint is losing go-to-definition and autocomplete when logic moves from JS classes into `data-` attributes. The answer named in-thread is **`stimulus-lsp`** (plus, newly, a Hotwire/Stimulus Chrome DevTools extension). A DX recipe worth its own page.
   [r/rails 1azndng](https://www.reddit.com/r/rails/comments/1azndng/) (15/6), [r/rails 1stqrkh](https://www.reddit.com/r/rails/comments/1stqrkh/) (25/5, 2026-04-23)
24. **Kredis as a server-side store for UI state that doesn't belong in a table.** Reddit's answer to "Stimulus has no state management": *"you can use kredis to create a state management similar to react context."* Half-joking, but it is a real pattern for wizard/filter/panel state. [r/rubyonrails 14mdm7i](https://www.reddit.com/r/rubyonrails/comments/14mdm7i/)

### Lower confidence — real but narrow

25. Reset **all** frames on a page when one filter changes ([r/rails 11950j0](https://www.reddit.com/r/rails/comments/11950j0/)).
26. Turbo + desktop shells (`Turbo Desktop`, [r/ruby 1s0odtu](https://www.reddit.com/r/ruby/comments/1s0odtu/); [r/rails 1oi3yz4](https://www.reddit.com/r/rails/comments/1oi3yz4/)).
27. View Transitions as the answer to "make Hotwire feel less like a page load" — a 63-score 2026 writeup pairing Turbo + Stimulus + view transitions ([r/rails 1ripe5w](https://www.reddit.com/r/rails/comments/1ripe5w/)).

---

## Questions & answers

Reddit's question corpus is much smaller and much *softer* than Stack Overflow's — most r/rails Hotwire threads are "how should I think about this," not "here is my broken code." The genuinely reusable Q&A:

### Q. "My modal form should redirect the whole page on success but keep errors in the modal — under Turbo 8 morphing, without writing a `.turbo_stream.erb` for every action."
Scoped `turbo:frame-missing` handler (code in New Recipe #3). Two alternatives were offered and each has a stated limit:
- `data-turbo-frame="_top"` on the form — *rejected by the asker*: it forces a full page load on validation failure too, destroying the modal.
- `turbo_stream.refresh` on success (Radan Skorić's writeup) — *rejected*: doesn't carry flash messages or redirect to the created object.
- `turbo_stream.redirect_to` from the **`turbo_power`** gem — offered, untested in-thread.
[1mxxyyh](https://www.reddit.com/r/rails/comments/1mxxyyh/) · **Not outdated.** Note this thread is 2025-08 and post-dates most blog content on modals.

### Q. "Turbo isn't intercepting my link clicks in Rails 8 — I see a browser spinner, not the progress bar."
Two separate confusions collapsed into one. The correct answer, from `t27duck` (7):
> *"the requests when you click on the links are going through the fetch API which is what turbo uses under the hood… This is not a bug."*

Turbo Drive **is** handling the link; the expectation of a Rails progress bar on a fast response is wrong (add `sleep 5` to the action to see it). Separately, a `GET` link does **not** request a Turbo Stream unless you add `data-turbo-stream`. `t27duck` initially wrote `data-turbo="true"` and corrected himself to **`data-turbo-stream="true"`** — worth noting, because the uncorrected form is the kind of thing that gets copied.
Another answer in the same thread — *"replaced `link_to` with `button_to` and it worked, haven't had the time to figure out why"* (4) — is the accidental-fix pattern: `button_to` issues a POST, and non-GET submissions request streams automatically.
[1mq54ia](https://www.reddit.com/r/rails/comments/1mq54ia/) (2025-08-14). Confirms sibling Q10/Q11.

### Q. "Explain morphing in simple terms."
> *"Rather than swapping out the block of HTML the morph library will check for differences between the 2 HTML trees and cleverly swap out the differences. This means you don't have to blow away everything and things that might have been applied since the first render (such as classes, or entire partials) can be retained."* — `matsuri2057` (12)

[170mohr](https://www.reddit.com/r/rails/comments/170mohr/) (2023-10-05). The canonical long-form reference Reddit points at for morphing is **jonsully.net/blog/turbo-8-page-refreshes-morphing-explained-at-length** ([1ocakn4](https://www.reddit.com/r/rails/comments/1ocakn4/), 8). For morphing gone wrong: **thoughtbot's "Turbo morphing woes"** ([1lb5h5x](https://www.reddit.com/r/rails/comments/1lb5h5x/), 3).

### Q. "Do I need `respond_to` for a Turbo Stream response?"
No, unless a second format genuinely does something different.
> *"You don't need `respond_to` unless you're actively expecting more than one format AND need that other format to do something different. A good example is an index page where the HTML version presents a paginated copy, while a CSV version exports all records as a CSV file."* — `dougc84` (22)

And the community's stated preference: put the stream actions in a `*.turbo_stream.erb` template, not in the controller (`the_maddogx`, 22; `zenzen_wakarimasen`, 7). This matches dhh's documented position in the sibling doc's Q28.
[r/ruby 1ow04bf](https://www.reddit.com/r/ruby/comments/1ow04bf/) (2025-11-13)

### Q. "How do I get instant feedback? Every Turbo Stream action has a visible lag."
Three answers, in ascending order of usefulness:
1. *"If your UI waits for a round trip to your server to update, it's always gonna have a delay, regardless of the technology… What you need to do is to build a UI that does optimistic updates."* — `ProstetnicSth` (8)
2. Make sure you are answering the **originating HTTP request** with the stream, not only broadcasting over Action Cable. Broadcast-only means the acting client waits for a websocket round trip it didn't need. — `twistedjoe` (3)
3. Render a partial inside a `<template>` tag in the ERB, and have the Stimulus controller clone it for the optimistic insert — so the same markup serves the server and the client. — `matsuri2057` (10)

[1izsbqa](https://www.reddit.com/r/rails/comments/1izsbqa/) (2025-02-27). Point 2 is a genuinely underdocumented gotcha and belongs in list item #178.

### Q. "My flash message disappears after a form redirect."
Confirms sibling Q3/Q11 territory but with a **new root cause and a memorable diagnostic signature**. The log shows the redirect target processed twice:
```
GET Processing by JobsController#show as TURBO_STREAM
GET Processing by JobsController#show as HTML
```
…and the second, full-page GET wipes the flash. The thread's wrong turns are instructive because they are the standard advice: `target: :_top`, `status: :see_other`, hooking `turbo:submit-end` + `Turbo.visit()`, changing Devise's `navigational_formats`. None of them were it. Actual cause: a CDN `<script>` in `<head>` carrying `data-turbo-track="reload"` with a **cache-busting timestamp in the URL**, so Turbo saw the tracked assets change on every response and forced a full reload. Removing the tracking attribute fixed it.
Note the intermediate state of the thread, which is its own data point: *"The docs are really not clear on the topic, super frustrating. A lot of people are having this problem from what I can see... I already spent too much time on this, I capitulate. I will just disable turbo on all my forms."*
[102qh6d](https://www.reddit.com/r/rails/comments/102qh6d/) (2023-01-04)

### Q. "My Stimulus action fires twice on every click."
Confirms list item #141 with the exact misconfiguration: in `config/importmap.rb`, `pin "application"` **and** `pin_all_from "app/javascript/controllers"` while `application.js` also imports the controllers — so each controller is registered twice. (`ryzhao`, 6/1). The generic debugging advice in the same thread is worth stealing verbatim for a "how this fails" block: turn on `application.debug = true`, and `console.log` *outside* the class definition to see whether the module itself is evaluated twice.
[1cfpxnw](https://www.reddit.com/r/rails/comments/1cfpxnw/) (2024-04-29)

### Q. "How do I make a broadcast reach the browser from `rails console` / an ActiveJob?"
The `async` Action Cable adapter only works within one process, so console and worker broadcasts never arrive. Confirms sibling Q14 item 3, and it is still catching people in **2025-09**. (`caiohsramos`, 9 — asker: *"That was exactly the issue… I can see all the warnings in the guide and cable.yml that would have answered my question."*)
[1nh46zh](https://www.reddit.com/r/rails/comments/1nh46zh/) (2025-09-14)

### Q. "Which of these three ways of targeting a frame is right?"
Reddit converges on the Turbo reference's own "frame with overwritten navigation targets" form — `turbo_frame_tag ... target: "_top"` on the frame, with per-link `data: { turbo_frame: ... }` overrides — over the alternatives. Useful because it is one of the few threads where someone posted three working options and asked which is idiomatic.
[13wqpup](https://www.reddit.com/r/rails/comments/13wqpup/) (2023-05-31)

### A security/correctness note that appears nowhere in the sibling doc
> *"All that matters is that the surrounding frame tag dom ids match (**though please note, they are ideally scoped to the current user so streams can't get crossed for certain views**)."* — `tumes` (4), [1h4j5vx](https://www.reddit.com/r/rails/comments/1h4j5vx/)

`dom_id(record)` is global, so a broadcast keyed on it reaches every subscriber whose page happens to contain that id. Any recipe involving `turbo_stream_from` + `dom_id` should say how to scope the stream name (and, where it matters, the target id) per tenant/user.

### Q. "Where do I actually learn this?"
The overwhelmingly most-recommended resource across five separate threads, spanning 2023–2026, is **hotrails.dev** — recommended in [1ejzdet](https://www.reddit.com/r/rails/comments/1ejzdet/) (11), [1ew4uo8](https://www.reddit.com/r/rails/comments/1ew4uo8/) (11, 9), [1lvrpag](https://www.reddit.com/r/rails/comments/1lvrpag/) (15, 2). Caveat stated in-thread: *"it's only Rails 7."* Also named: colby.so, Joe Masilotti's newsletter and Hotwire Native book (Pragmatic Bookshelf), the Pragmatic Studio Hotwire course, Superails (YouTube), `asyraffff/Hotwire-in-action`.
**Reference apps Reddit points to for reading real Hotwire code:** 37signals' **Writebook** (source available under the ONCE licence), **maybe-finance/maybe**, **rubyevents/rubyevents**, **OpenProject**, **palkan/turbo-music-drive**.

---

## Lived experience — what shipping devs say

Quotes are verbatim; `(score)` is the archived comment score.

### People who shipped and are glad

> *"I am rewriting tens of thousands of lines of react and graphql with a few hundred lines of erb and stimulus. I am convinced people using react are completely out of their minds."* — `normal_man_of_mars` **(27)**, [r/rails 1ip5468](https://www.reddit.com/r/rails/comments/1ip5468/)

> *"I migrated away from React and productivity has been through the roof. Delivering exact to similar experiences."* — `gorliggs` **(53)**, [r/rails 1avm4es](https://www.reddit.com/r/rails/comments/1avm4es/). Same person elsewhere: *"I've been working with Rails since 2007 and picked up on the SPA train starting in 2012 with Ember and moved to React in 2015. I can say definitively that Turbo/Hotwire can tackle any user experience that React or any frontend library is promising you today."* (42)

> *"Within the same company I moved from a big team that was slowly moving towards React (from jQuery) to a small team using Hotwire. The team using Hotwire is developing **a lot** faster. One of the reasons is no extra communication layer between frontend and backend."* — `lafeber` **(6)**, [r/rubyonrails 14mdm7i](https://www.reddit.com/r/rubyonrails/comments/14mdm7i/)

> *"We develop a very niche industry based ERP software with Rails, Hotwire/Stimulus and Tailwind CSS. The app has very complex forms, modals, dynamically created form fields/sections etc… I can't imagine spending time to achieve this using React/Rails combo."* — `kazdal` **(7)**, [r/rails x9k9h9](https://www.reddit.com/r/rails/comments/x9k9h9/)

> *"No performance issues running on Heroku with ~200k monthly users. To be honest I used Turbo to address performance problems. Had a complex query driving out the main user interaction… We were able to triage it quickly by chopping the most expensive part and stuffing it in its controller with a separate query that was then rendered into a turbo frame."* — `numberwitch` **(10)**, [r/rails 15vmd1u](https://www.reddit.com/r/rails/comments/15vmd1u/). **A Turbo frame used as a performance tool, not a UX tool** — this framing appears nowhere in the official docs and is a genuinely good recipe seed.

> *"I work on an app that has more active users than what you specified, and there isn't a difference in terms of resource usage between a pure API approach and using Hotwire… our dedicated ActionCable server rarely goes over 9% CPU usage and about a gig of memory. Though, CPU usage can spike heavily when a lot of users (around 10k+) connect at the same time, like during a deploy."* — `monorkin` **(5)**, same thread. The deploy-thundering-herd detail is the most concrete production ops fact in the whole corpus.

Hotwire Native draws the most uniformly positive sentiment of anything in this corpus:

> *"the first time you get your rails app loading through the mobile app feels like that Rails magic all over again! Most things just work."* — `rsmithlal` **(24)**, [r/rails 1otcn0o](https://www.reddit.com/r/rails/comments/1otcn0o/)

> *"I've been using it for more than 5 years with 2 clients… I have a bridge component that manages a SIP call to a device through twilio (native SDK) — all the UI is from a web page."* — `InsideStorm9` **(3)**, same thread.

### People who shipped and struggled

The single most-upvoted diagnosis of Hotwire's problem is not about capability at all:

> *"Mostly due to lackluster documentation IMO"* — `clearlynotmee` **(48)**, [r/rails 1ejzdet](https://www.reddit.com/r/rails/comments/1ejzdet/) — top comment on a thread titled *"Turbo is a great idea but one of the worst things to get started with that I have ever seen."*

> *"This is the dhh pattern. Release a lib that simplifies something drastically. Write a super basic 'handbook' and give very little in the way of documentation or tutorials. Complain no one uses this better way forward"* — `pjo336` **(37)**, same thread.

> *"They've essentially introduced an entire front end framework with documentation that leaves you more confused than informed. There's no 'OH I SEE' moments… Honestly, it's one of the main reasons why I've never implemented it in any app successfully and just went back on server rendered pages."* — `dougc84` **(10)**, same thread.

> *"The docs are a special kind of bad for Hotwire & Rails. Go to the Hotwire website and search for 'Rails'. You won't find it. I think there's 1-2 mentions. On the Rails website look for Hotwire. Not much."* — `bradgessler` **(7)**, [r/rails 1ny8ldn](https://www.reddit.com/r/rails/comments/1ny8ldn/). Same author, who built a Hotwire course: *"For me one of the most confusing parts was Turbo frames and streams… It's a complete mess. What's frustrating is the Good Parts, Turbo Pagemorphs, barely gets any mention."* (2)

The second-most-cited complaint is **tooling ergonomics**, and it is specific:

> *"With react, I can 'control + click' my code and find all references. With hotwire I have to manually search for everything. If I change something on a stimulus controller, if I have a typo, nothing will accuse an error… I lose all autocomplete and intellisense too. And even copilot doesn't work as good because of this."* — `alphmz` **(14)**, [r/rails 1azndng](https://www.reddit.com/r/rails/comments/1azndng/) — **written by someone who voted *for* migrating his project from React to Hotwire.** The reply, `stimulus-lsp` (11), is the fix nobody knows about.

> *"It's the fucking data- attributes everywhere in the app. I feel like I'm going to break something all the time."* — `wiznaibus` **(11)** (10 years Rails, 5 years React, 3 months Stimulus), [r/rails 1ew4uo8](https://www.reddit.com/r/rails/comments/1ew4uo8/)

Third: **componentization**. This is the most intellectually serious criticism in the corpus and it recurs almost verbatim across four years.

> *"I believe it stems from the need to have Rails controllers with specific responses for every turbo frame, etc. It breaks componentization. Where in Vue, you have a component that GETs via a store and is therefore self contained and can be dropped wherever, reusable components in Hotwire/turbo/stimulus aren't as contained bc your controller has to support it. So you drop a partial and then you have to get hairy w your controllers and maybe even your models having callbacks to broadcast. It's too coupled."* — `Adventurous-Ad-3637` **(3)**, [r/rails 1ew4uo8](https://www.reddit.com/r/rails/comments/1ew4uo8/)

> *"Not a fan when I have to split logic between stimulus, turbo_frame replace/append etc. The code is at so many places it is hard to understand what is going on."* — `kw2006` **(8)**, [r/rails x9k9h9](https://www.reddit.com/r/rails/comments/x9k9h9/)

> *"This highlights one of my biggest gripes with Turbo streams — inappropriately tight coupling your model to your view layer."* — `latortuga` **(3)**, [r/rails 1srrqxc](https://www.reddit.com/r/rails/comments/1srrqxc/) (2026-04), on `broadcasts_refreshes`/`broadcast_*` in model callbacks. This is the sibling doc's list item #80 ("move broadcasting out of model callbacks") stated as a principled objection rather than a technique.

> *"you still can't get around the madness that comes in large projects when your primitive is html and your pointers are html/css classes or ids. For tiny projects this is fine, but large projects I don't want my first question on a bug to be 'where in the hell is this even coming from', let alone when you end up with collisions."* — `Reardon-0101` **(3)**, [r/rails 1avm4es](https://www.reddit.com/r/rails/comments/1avm4es/)

And the recurring rejoinder, also from experienced people, is that this is almost always a **mindset** failure rather than a capability one:

> *"I have seen a few people complain about turbo here, and the case is they are ALWAYS overcomplicating it, always… there is a pattern change, partials are BIG, because you need to wrap things in turbo frames that get swapped out… Also if your list data is a table, then you need to tell that each row is a turboframe rather than wrap it. **Imo don't use a table to learn turbo.**"* — `LordThunderDumper` **(11)**, [r/rails 1ejzdet](https://www.reddit.com/r/rails/comments/1ejzdet/)

> *"the first mistake I made was to try the things I'm doing with a React mental model. You'd have to understand where your interactivity should be and only work around that — forget about states, as the only state you probably need is the actual state of the DOM. You can hack your way around it and that's where it gets ugly."* — `candidpose` **(3)**, [r/rails 1ew4uo8](https://www.reddit.com/r/rails/comments/1ew4uo8/)

The best single piece of triage advice in the corpus, worth putting near the top of the repo:

> *"What percent of your user interactions depend on Stimulus and Turbo Stream? Ideally, most user interactions don't require Hotwire. When you do use Hotwire, you want to mostly be using Turbo Frames. Turbo Streams and Stimulus are when things start to get complex. **If you ever find yourself wanting to generate HTML or make a network request in a Stimulus controller, you want to re-think that** and see if you can use Turbo Frames. If you are using Turbo Streams but only modifying the part of the page that triggered the change, you want to re-think and try to use Turbo Frames."* — `kcdragon` **(4)**, [r/rails 1ew4uo8](https://www.reddit.com/r/rails/comments/1ew4uo8/)

### The hiring/ecosystem anxiety — a distinct, non-technical objection

This is the most-repeated *business* argument against Hotwire on Reddit and it barely appears in the SO/GitHub corpus at all.

> *"Try finding a Rails frontend dev... New devs look at our setup like I'm speaking alien."* — OP of [1ew4uo8](https://www.reddit.com/r/rails/comments/1ew4uo8/) (75/106)

> *"I tried to use Hotwire but I found that documentation was very limited and it also felt like Hotwire skill was Rails-only and not that transferable to other tech stacks."* — `blackfoks` **(19)**, [r/rails 1tcdhwo](https://www.reddit.com/r/rails/comments/1tcdhwo/) (2026-05). Reply, `Redditface_Killah` **(9)**: *"Good point about Hotwire being a niche skill."*

> *"Many use Rails + React because Hotwire didn't exist when they started the company. It's just inertia and it's hard to justify switching in most real world business contexts… Also react talent pool is much larger."* — `DanTheProgrammingMan` **(15)**, [r/rubyonrails 14u7pqa](https://www.reddit.com/r/rubyonrails/comments/14u7pqa/)

> *"No interest in Hotwire. I like React… And the likelihood of it being abandoned in 5 years is MUCH less than Hotwire."* — `jryan727` **(2)**, same thread.

---

## The framework debates

### vs React — where the argument has actually landed

The 2021–2022 threads are religious. The 2024–2026 threads are not: the modal position on r/rails today is **hybrid, decided per screen**, and both camps say it.

The strongest pro-Hotwire arguments, from people who have used both:
- **One source of truth, one validation implementation.** *"hotwire keeps all your business logic on the backend (where it belongs, IMO)… write business logic once… reduces surface area for bugs… exposes less information to attackers… less technologies to support (surface area of hotwire is much smaller than react)."* — `BattleBrisket` **(25)**, [1qez1ls](https://www.reddit.com/r/rails/comments/1qez1ls/)
- **Perceived-speed parity is an engineering choice, not a framework property.** *"React often feels snappier because most sites render a skeleton or loading layout while they wait for the JSON payload… You can add a skeleton layout or a loading state to turbo too, and then the difference is gone."* — `monorkin` **(5)**, [15vmd1u](https://www.reddit.com/r/rails/comments/15vmd1u/)
- **The measured productivity anecdote.** Same personal project rebuilt: *"the original version took me three weeks, the Rails one took me just four days."* — `tommasonegri` **(8)**, [s19z3j](https://www.reddit.com/r/rails/comments/s19z3j/)

The strongest anti-Hotwire arguments, from people who have used both:
- **The HTTP boundary is a maintenance feature, not a cost.** *"having a strict border (HTTP) between your backend and frontend makes for easier maintenance over projects lifetime. Business requirements invariably lead to mess somewhere, and if you can push that mess into frontend, the system will work better."* — `slvrsmth` **(7)**, [1avm4es](https://www.reddit.com/r/rails/comments/1avm4es/). Same comment: *"Hotwire is great to churn out appearance of interactivity super fast… The moment you want to do a lot of work in frontend, React pulls ahead, and FAST."*
- **Data arriving from multiple sources.** *"when your data comes from various sources (example: initial load from cache, then live updates via websockets), it's often much more efficient to have one bit of JS that knows how to render that data 'shape', and not care how it got there."* — `slvrsmth`, same.
- **Mobile forces the API anyway.** *"because we have android and iOS applications, we must have API anyway; it's not effective to maintain an API and use it only for mobile applications and develop something else for the rest."* — `Late-Act-9823` **(2)**, [14u7pqa](https://www.reddit.com/r/rubyonrails/comments/14u7pqa/). (Note this is directly contested by the Hotwire Native threads — see below.)
- **Cross-team split.** Two full-time jobs, two skill pools, and Rails devs are scarce enough that companies want every good one on the backend. — `Beep-Boop-Bloop` **(11)**, same thread.

The honest middle, which is also the most-upvoted long comment in the corpus on this question:
> *"Hotwire diehards will tell you you'll get the same UX as a React app. But rarely is any decision as clear cut as that, right? If you're comfortable letting the technology (React) influence the UI to an extent, then Hotwire is a fine choice. There are interactions and features that will be complex to implement with Hotwire. Maybe you decide to not do them, or sprinkle in a React component. **There's a fidelity tradeoff with Hotwire, too.**"* — `jryan727` **(18)**, [1avm4es](https://www.reddit.com/r/rails/comments/1avm4es/)

### vs Inertia.js — the live 2026 debate

This is the argument Reddit is actually having *now*. [r/rails 1tcdhwo](https://www.reddit.com/r/rails/comments/1tcdhwo/) (2026-05-13, 24/36) is the canonical thread, and it splits roughly evenly.

Pro-Inertia:
- **The component library is the whole argument.** *"The key benefit of Inertia is being able to use great ready-made ui libraries like shadcn."* — `inonconstant` (2). Echoed by `RagingBearFish` (10): *"let rails do what rails does best (the backend) and let the JS frameworks handle what they do best (frontend). Inertia gives you the best of both worlds."*
- *"InertiaJS + Svelte feels more The Rails Way than Hotwire. Or maybe a more modern Rails way? More batteries-included… It honestly feels like having .svelte files (HTML-first templates) instead of .erb."* — `RevolutionaryMeal464` **(9)**, [1c0utvr](https://www.reddit.com/r/rails/comments/1c0utvr/)
- Transferable skill, larger hiring pool (see above).

Anti-Inertia, from people who tried it:
- **It's more boilerplate, and the advantage evaporates at complexity.** *"Inertia felt like a good compromise for using UI libraries like shadcn with Rails but I still found it much more boilerplate heavy than Hotwire. Now that AI has helped spawn some erb and view component based options I am back to Hotwire… I don't find Inertia much easier to use when you do more complex things anyway so it was feeling just like a verbose template to me."* — `grainmademan` **(2)**, [1tcdhwo](https://www.reddit.com/r/rails/comments/1tcdhwo/)
- **Setup is rough.** A week to get Inertia Rails + SSR working, with the author noting `INERTIA_SSR_URL` is undocumented and had to be found by reading the gem's tests ([1koozuz](https://www.reddit.com/r/rails/comments/1koozuz/), 54/24). A separate report of the getting-started tutorial not producing a working app and generators writing files to paths the template engine doesn't look in ([1rytd47](https://www.reddit.com/r/rails/comments/1rytd47/), `planetaska`, 2).
- **A concrete correctness report**, unverified but specific: *"Inertia has a bug that leaks state over different threads. Several users have reported it… If you're writing current user and their API key, it's an issue when that appears on the reset password page from another request."* — `BlueEyesWhiteSliver` **(6)**, [1c0utvr](https://www.reddit.com/r/rails/comments/1c0utvr/). **Flagged as unverified** — nobody in-thread produced the GitHub issue when asked.

### vs HTMX / Alpine / Unpoly / Datastar

Small but consistent. HTMX wins on documentation and loses on server-push:
> *"I felt the same way when I started looking into Turbo and chose htmx instead because it was simpler and the documentation was better."* — `GentAndScholar87` (3), [1ejzdet](https://www.reddit.com/r/rails/comments/1ejzdet/)

> *"If you only want to perform some operations without full page reload, then yes. But tooling like hotwire gives you an extra bonus of events triggered by a server side. Htmx won't help much with this."* — `katafrakt` (4), [s19z3j](https://www.reddit.com/r/rails/comments/s19z3j/)

The one person in the corpus who used all three in production came down for Hotwire:
> *"I used HTMX, Alpine, and Hotwire in separate real-world apps over the last year. My conclusion is that Hotwire is the complete package and best choice to use with Rails. The others are good too, but Turbo and Stimulus are just so well integrated with the Rails workflow. It didn't click with me either at first, but after building fully functional apps you understand the design choices more clearly."* — `AceLumberman` **(13)**, [r/rails zc08zb](https://www.reddit.com/r/rails/comments/zc08zb/)

**Unpoly** and **Datastar** appear as 2026 alternatives ([1rytd47](https://www.reddit.com/r/rails/comments/1rytd47/), [1m8e7ki](https://www.reddit.com/r/webdev/comments/1m8e7ki/)) — new names since the sibling doc was compiled.

### vs Phoenix LiveView — the most technically substantive comparison in the corpus

`GreenCalligrapher571` **(16)**, [r/rails 1ka0tve](https://www.reddit.com/r/rails/comments/1ka0tve/), having used both:

> *"LiveViews can hold their own state in-memory; in that way, the LiveView process (on the server) acts as a caching layer — you can look up the record once, and then hold it in state, mutate it as needed, etc. **In HotWire, there's a socket connection, but doing any sort of operations generally requires that you go fetch all the relevant records each time a new client-to-server message comes in. This can get really expensive.**"*
> *"In both cases, the story of integrating third-party JS with either HotWire or LiveView is kinda clunky and I didn't enjoy it."*
> *"The state model for HotWire didn't feel great to me… as soon as the operations performed by the user began getting complex, it became harder and harder to reason about state within HotWire. By contrast, I've found it much easier to reason about state with LiveView or even relatively plain React."*

This is the sharpest articulation of Hotwire's structural gap anywhere in the corpus: **there is no per-connection server-side state, so every message re-derives everything from the database.** It is also the correct rebuttal to "Hotwire is Rails' LiveView."

Useful counterweight from the same thread: *"Hotwire doesn't require websockets to function. Almost all of the interactions with the server are done over regular HTTP requests… things like turbo streams work just fine over HTTP. It's a common misconception."* — `matsuri2057` (9).

### Where Hotwire was the wrong tool — specific screens named by the people who built them

These are the highest-value items in this document.

1. **A map-centred control surface with bidirectional component coupling.**
   > *"we had this app inside the main Rails app that was a single screen around a map, with a lot of HTML components allowing to change things on the map, but also the opposite (map changing HTML components around), with keyboard shortcuts and all, graphs updating in real time depending on what you were doing elsewhere on the interface… We tried Hotwire but it wasn't working for this specific page. For all the other pages of the app, it was plain Rails with a little bit of Hotwire."* — `Vindve` **(10)**, [r/rails 15vml4r](https://www.reddit.com/r/rails/comments/15vml4r/)

2. **A terminal emulator — keypress-level input handling.** The clearest statement in the corpus of the *latency floor* argument, and notable because the author had already taken the "put the state on the server" advice and it still didn't help:
   > *"Fair point on server-owned state — I do have a session model backing it. The blocker was keypress-level input handling: cursor positioning, history traversal, tab completion all need to feel instant, and server round-trips introduced lag that felt broken on a terminal. **So you still end up writing a client-side input layer regardless of where state lives.**"* — `ultrathink-art` (2), [r/rails 1rr5p2n](https://www.reddit.com/r/rails/comments/1rr5p2n/) (2026-03-11)

3. **Anything stateful-but-not-persisted — the calculator test.** The best one-line heuristic anyone offered:
   > *"Turbo is best suited for STATELESS interactions… On the other [hand] STATEFUL interactions are something that turbo/hotwire does very poorly. **Easiest example to demonstrate that challenge is try building a calculator with only turbo.** There are plenty of example javascript programs where you build a calculator. You aren't saving any of the fields/values in the database, the results of each button click on a calculator are predicated on the previous action. Also hotwire/turbo/stimulus does an inferior job when handling animation."* — `606anonymous` (3), [r/rails 15vml4r](https://www.reddit.com/r/rails/comments/15vml4r/)
   Independently confirmed two and a half years later: *"Or a calculator - that needs to update 120ish things across a long page, plus conditional display based on the calculation. I really wish Stimulus had reactivity."* — `planetaska` (2), [1tcdhwo](https://www.reddit.com/r/rails/comments/1tcdhwo/) (2026-05)

4. **A complex model editor with a live side-by-side preview.**
   > *"I introduced Hotwire into a legacy app last year, and it worked great for JS interaction with Stimulus, and Turbo to update the DOM seamlessly. **It got very difficult when I built an interactive interface that gave the user the ability to maintain this very complex model with a preview on the side. At that point I wish I had React just for that interface.** But overall you can get very far with Hotwire."* — `sneaky-pizza` (2), [r/rails 1ny8ldn](https://www.reddit.com/r/rails/comments/1ny8ldn/)

5. **Real-time multi-user + multi-language, where it worked and then didn't scale.**
   > *"I've just recently built a fairly complex frontend feature that required real-time multi user updates in different languages at work using Hotwire/StimulusJS and I have to say that while initially I was super happy with how quick and easy I could get this to work, **it's now also causing quite some pain in terms of raw performance.**"* — `CallMeXed` (6), [r/rails s19z3j](https://www.reddit.com/r/rails/comments/s19z3j/)

6. **Offline-first field work** — see New Recipe #16. The boundary is crisp and stated by the maintainer himself.

7. **Web Audio / getUserMedia / `data-turbo-permanent` territory.**
   > *"I've had headaches with web audio, user media, or turbo permanent stuff where it is just more difficult to use stimulus/turbo than the alternative."* — `xero01` (3), [1ny8ldn](https://www.reddit.com/r/rails/comments/1ny8ldn/)

**The rebuttal that keeps this honest**, and which the repo should carry alongside the list above:
> *"Why is it fundamentally client-sided and stateless? You could imagine a terminal session as a database-backed model… **Yes Hotwire is a bad fit for client-side apps because that's not what it is. But that's often an architectural decision that's being made which in turn makes Hotwire the wrong solution, not an inherent limitation of Hotwire itself.**"* — `jryan727` **(9)**, [1rr5p2n](https://www.reddit.com/r/rails/comments/1rr5p2n/)

---

## Corrections to popular Reddit advice

### What I could verify

- **`redirect_to path, turbo_frame: "_top"` — did NOT appear anywhere in the 63 threads I read.** I could not run a full-text comment search (Arctic Shift timed out on every `body=` query and PullPush blocked me), so I cannot say it is absent from Reddit; I can only report that **zero of ~1,000 comments read contained it**, and that the closest thing — the [1mxxyyh](https://www.reddit.com/r/rails/comments/1mxxyyh/) thread, which is exactly the problem it purports to solve — reached for `turbo:frame-missing` instead. Same for `Turbo.clearCache()`, `setConfirmMethod`, `data-turbo-cache`, `DOMNodeInserted`, and `format: :turbo_stream` in a path helper: **zero occurrences in the corpus.** Reddit's Hotwire discussion is not, in this sample, a vector for the specific bad snippets that pollute blog posts and Stack Overflow.

- **`data-turbo="true"` to make a GET link request a Turbo Stream — WRONG, and corrected in-thread.** `t27duck` posted it, then self-corrected to **`data-turbo-stream="true"`** two comments later ([1mq54ia](https://www.reddit.com/r/rails/comments/1mq54ia/)). The uncorrected first version has 4 upvotes and sits above the correction. Anyone skimming gets the wrong attribute.

- **"Replace `link_to` with `button_to` and it worked, haven't had the time to figure out why" (4 upvotes, same thread) is a coincidental fix.** It works because `button_to` emits a POST, and Turbo automatically negotiates `text/vnd.turbo-stream.html` for non-GET. Copying it as *the* fix will surprise you the moment you need an idempotent GET.

- **"Polling should honestly be considered an anti-pattern in programming" (`VampireHugs`, 3, [1ew4uo8](https://www.reddit.com/r/rails/comments/1ew4uo8/)) is too strong**, and the corpus contradicts it: a 2026 production report found polling *more reliable* than Action Cable at ~100 concurrent users ([1vl7fnw](https://www.reddit.com/r/rails/comments/1vl7fnw/)). Polling a lazy frame with `frame.reload()` is a legitimate, low-ops choice.

- **The standard flash-disappears advice is a dead end more often than Reddit admits.** In [102qh6d](https://www.reddit.com/r/rails/comments/102qh6d/) the top-voted suggestions — `target: :_top`, `status: :see_other`, hooking `turbo:submit-end` and calling `Turbo.visit()`, changing Devise's `navigational_formats` — were all wrong for the actual bug (`data-turbo-track="reload"` on a timestamped CDN URL). Anyone writing a "flash messages with Hotwire" recipe should lead with the diagnostic (**count the GETs in the log**) rather than the fix list.

- **"Turbo requires WebSockets" — a misconception that recurs and is corrected.** Turbo Streams work over plain HTTP responses; Action Cable is only needed for server-initiated push. (`matsuri2057`, 9, [1ka0tve](https://www.reddit.com/r/rails/comments/1ka0tve/)).

- **"Strada" is dead as a name.** Threads from 2024 and earlier reference it; it was folded into **Hotwire Native** as "Native Components" in Sept 2024. Any Reddit answer mentioning Strada as a current, separate thing is out of date. (`joemasilotti`, 6, [1fps6h9](https://www.reddit.com/r/rails/comments/1fps6h9/))

- **`turbo-mount` and Turbo's snapshot cache.** The `islandjs-rails` author claims, self-flagged as unverified (*"I need to verify"*), that turbo-mount does not ship back/forward-cache handling. **Treat as unverified**; it is a claim by a competing library's author. It is, however, a real hazard worth testing for in any island recipe.

### Advice that is *dated* rather than wrong

- **"`stimulus-loading` eager-loads every controller on every page, and Stimulus offers no code splitting"** ([r/webdev 1vgwaxl](https://www.reddit.com/r/webdev/comments/1vgwaxl/), 2026-08). The critique of the *default* is fair, but `lazyLoadControllersFrom` has existed in `@hotwired/stimulus-loading` since 2021 and is the documented escape hatch. Anyone repeating this should be pointed there.
- **StimulusReflex** is recommended in threads through ~2022 as the answer to complex interactions ([mlnyof](https://www.reddit.com/r/rubyonrails/comments/mlnyof/), [x9k9h9](https://www.reddit.com/r/rails/comments/x9k9h9/)). Turbo 8 morphing covers most of what it was reached for; treat pre-2023 StimulusReflex advice as superseded.
- **`format.js` / `.js.erb`** is still being recommended as recently as 2023 ([15o9mi4](https://www.reddit.com/r/rails/comments/15o9mi4/), `armahillo`, 3). It is dead in Rails 8 (rails-ujs removed).
- **hotrails.dev**, the community's near-universal recommendation, is **Rails 7 content**, as one recommender flags. Its Turbo/Stimulus material is still accurate; its scaffold/status-code details (`:unprocessable_entity`, 302 redirects) are not, per the sibling doc's version-facts section.

---

## Sentiment summary — how Rails devs feel about Hotwire in 2025–2026

**The honest read: Hotwire has won the argument about *capability* and lost the argument about *onboarding*.**

Five things are true at once, and the proportions matter:

**1. Nobody credible still claims Hotwire can't build a real app.** The 2021–2022 threads are full of "can it replace React?"; by 2025–2026 that question isn't asked. What replaced it is *"can you get by with Hotwire alone, or do you often need to bring in React?"* ([1ny8ldn](https://www.reddit.com/r/rails/comments/1ny8ldn/), 2025-10) — and the consensus answer is a confident **"yes, 90% of the time, and mount an island for the rest."** Reports of migrating *from* React *to* Hotwire (with productivity claims) outnumber the reverse in this corpus by roughly 4:1. That ratio is real but should be discounted for the obvious selection effect: this is r/rails.

**2. The dominant criticism is documentation, and it is not close.** The single highest-scoring comment on the biggest anti-Turbo thread is four words about docs (48). The people making this criticism are frequently Hotwire *advocates* — the course author, the person who voted to migrate his company to it. This is the most actionable finding for the crosswire repo: **the gap the community is loudly asking someone to fill is exactly this repo's premise.** hotrails.dev is doing the job by default, is universally recommended, and is stuck on Rails 7.

**3. The second criticism is tooling ergonomics, and it is under-recognised.** "I lose ctrl-click, autocomplete, and Copilot quality when logic moves into `data-` attributes" is a real, specific, fixable complaint (`stimulus-lsp`, Hotwire DevTools extension) that almost nobody in the threads knows the fix for. A repo page on this would land.

**4. The third criticism — componentization — is legitimate and unresolved.** "A frame needs a controller action to support it, so components aren't self-contained" recurs from 2022 to 2026 in near-identical words from different people. ViewComponent/Phlex are the community's partial answer, and the shadcn-alikes (Rails Blocks, PhlexUI/RBUI, ZestUI, Protos) are 2024–2026 attempts to close the ecosystem gap that Redditors name as React's real advantage. This is the honest structural cost of the model and the repo should say so rather than argue it away.

**5. Two things swing sentiment *toward* Hotwire in this window, and one swings against.**
   - **Hotwire Native is the strongest positive.** It is the least-contested, most-enthusiastic topic in the entire corpus — "feels like Rails magic all over again," 20+ apps in the App Store from one maintainer, five-year production users, native bridge components doing real work (SIP calls, haptics, push). It also directly rebuts the "you'll need an API for mobile anyway" argument that was React's best structural card. Offline is its one hard, acknowledged wall.
   - **Turbo 8 morphing** turned "Hotwire can't do live-updating" into a two-line feature, and multiple 2024–2026 threads see someone arrive at a hard problem and get pointed at morphing as the answer. Its own docs problem is that, per one course author, "the Good Parts, Turbo Pagemorphs, barely gets any mention."
   - **Inertia.js is the real competitor now, not React.** The 2026 threads that used to be "Hotwire vs React" are "Hotwire or Inertia" — and Inertia is winning on exactly one axis, repeated over and over: **you get shadcn and the ready-made component ecosystem.** Not performance, not architecture. Component libraries.

**On AI/agentic coding — genuinely split, and new.** [1qez1ls](https://www.reddit.com/r/rails/comments/1qez1ls/) (2026-01) asks whether agentic coding changes the calculus. The top answer is a flat "yes, still Hotwire, because at some point you're going to have to read the code" (64). But the counter-argument is serious and comes from a working team: *"if moving to a JavaScript framework could mean that 80-90% of our UIs could be built via AI, then that changes the equation quite a bit."* A 20-year Rails veteran in the same thread argues the "Ruby tax disappears thanks to AI" and that a new coder "will invariably be force-fed a JS framework, mainly because that's what the LLM will naturally use." This is a **new** category of argument that did not exist when the sibling document's HN corpus was written, and it cuts against Hotwire's long-term mindshare rather than its merits.

**The mood, in one sentence:** Rails developers in 2026 are settled and largely happy with Hotwire for the app they have, defensive but no longer evangelical about it, unanimously frustrated by the documentation, quietly anxious about hiring, genuinely excited about Hotwire Native, and — for the first time — meaningfully tempted away by Inertia not because it is better engineering but because it comes with components.

---

## Tooling and libraries Redditors actually endorse

Usage signal from real threads, distinct from GitHub-stars signal.

| Thing | Signal | Where |
|---|---|---|
| **hotrails.dev** | The learning resource, recommended in 5+ separate threads 2023–2026, always unprompted. Caveat: Rails 7. | [1ejzdet](https://www.reddit.com/r/rails/comments/1ejzdet/), [1ew4uo8](https://www.reddit.com/r/rails/comments/1ew4uo8/), [1lvrpag](https://www.reddit.com/r/rails/comments/1lvrpag/) |
| **Joe Masilotti's Hotwire Native book + newsletter** | The Hotwire Native resource; maintainer answers on Reddit directly. | [1otcn0o](https://www.reddit.com/r/rails/comments/1otcn0o/), [1sjj19f](https://www.reddit.com/r/rails/comments/1sjj19f/) |
| **`stimulus-lsp`** | The fix for the #2 complaint; almost nobody knows it exists. | [1azndng](https://www.reddit.com/r/rails/comments/1azndng/) |
| **Hotwire/Stimulus Chrome DevTools extension** | New (2026-04), free, open source. | [1stqrkh](https://www.reddit.com/r/rails/comments/1stqrkh/) |
| **`tailwindcss-stimulus-components`** (excid3) | *"I rarely need to go beyond"* it. | [1tcdhwo](https://www.reddit.com/r/rails/comments/1tcdhwo/) |
| **Rails Blocks** (railsblocks.com) | 2025–2026 shadcn-alike, 44 component sets, built for Hotwire + Tailwind; author active on r/rails. Named as *"the best shadcn like experience for Rails."* | [1ny8ldn](https://www.reddit.com/r/rails/comments/1ny8ldn/), [1tcdhwo](https://www.reddit.com/r/rails/comments/1tcdhwo/) |
| **PhlexUI / RBUI, ZestUI, PhlexyUI, Protos, shadcn.rails-components.com, Flowbite** | The Phlex-side component ecosystem. Honest caveat in-thread: shadcn-for-Rails ports are *"still a little rough… you will have to do some work to get various components to work (e.g. figuring out what 3rd party JS packages you need)."* | [1fqzmqm](https://www.reddit.com/r/rails/comments/1fqzmqm/) |
| **Ultimate Turbo Modal** (`cmer`) | Long-lived, v3 in 2026, *"I use this all the time."* | [128afnn](https://www.reddit.com/r/rails/comments/128afnn/), [1rzxuu0](https://www.reddit.com/r/rails/comments/1rzxuu0/) |
| **`turbo_power`** | Named for `turbo_stream.redirect_to` and other extra stream actions. | [1mxxyyh](https://www.reddit.com/r/rails/comments/1mxxyyh/) |
| **`turbo-mount`** (skryukov) | The default answer for mounting React/Svelte/Vue islands. | [1e6sg28](https://www.reddit.com/r/rails/comments/1e6sg28/), [1oppg76](https://www.reddit.com/r/rails/comments/1oppg76/) |
| **`islandjs-rails`** | 2025–2026 alternative to turbo-mount; UMD-globals approach, no npm/Stimulus dependency. Author active. | [1oppg76](https://www.reddit.com/r/rails/comments/1oppg76/) |
| **Superglue** | React + Rails via Turbo Streams; 2.0 alpha Sept 2025. | [1njdfbt](https://www.reddit.com/r/rails/comments/1njdfbt/) |
| **ViewComponent** | The consistent answer to "how do I get components"; several teams pair it with a small set of Stimulus behaviours (`openable`) to build dropdowns/accordions. Performance caveat named: **very small partial-based components got slow in production for one team**, and they went back to duplicated markup. | [x9k9h9](https://www.reddit.com/r/rails/comments/x9k9h9/), [1tcdhwo](https://www.reddit.com/r/rails/comments/1tcdhwo/), [1fqzmqm](https://www.reddit.com/r/rails/comments/1fqzmqm/) |
| **`spectator_sport`** | Self-hosted session replay for diagnosing "the app feels slow" reports. | [1vl7fnw](https://www.reddit.com/r/rails/comments/1vl7fnw/) |
| **`rack-mini-profiler`** | Reddit's first answer to "how do I make my Turbo frames load faster" — measure the server before blaming Turbo. | [y9pefa](https://www.reddit.com/r/rails/comments/y9pefa/) |
| **`<details>`/`<summary>`** | Repeatedly the answer to "how do I do a disclosure/dropdown" before anyone reaches for Stimulus; GitHub's own nav is cited as proof of how far it goes, with a linked accessibility caveat. Confirms list item #179. | [yng08k](https://www.reddit.com/r/rails/comments/yng08k/) |
| **`inertia_rails`** | Real production usage (Vue and React), plus repeated reports of a rough getting-started experience. | [1tcdhwo](https://www.reddit.com/r/rails/comments/1tcdhwo/), [1koozuz](https://www.reddit.com/r/rails/comments/1koozuz/), [1rytd47](https://www.reddit.com/r/rails/comments/1rytd47/) |
| **Reference apps to read** | 37signals **Writebook** (source available), **maybe-finance/maybe**, **rubyevents/rubyevents**, **OpenProject**, **palkan/turbo-music-drive**, **lafeber/fullcalendar-hotwire**. | [1lvrpag](https://www.reddit.com/r/rails/comments/1lvrpag/), [1e0h3wb](https://www.reddit.com/r/rails/comments/1e0h3wb/), [1ji9znt](https://www.reddit.com/r/rubyonrails/comments/1ji9znt/) |
| **Drag & drop** | Reddit's practical answers are `Shopify/draggable`, `interact.js`, and Dragula wrapped in a Stimulus controller — not a Hotwire-specific library. | [1avm4es](https://www.reddit.com/r/rails/comments/1avm4es/) |

**Notably absent from Reddit's recommendations**, despite GitHub prominence: `stimulus-components` / `@stimulus-components/*` is barely named; `turbo_boost`/CableReady/Mrujs appear once each and defensively; `hotwire_combobox` never came up. Treat GitHub-stars ranking and Reddit-mention ranking as measuring different things.
