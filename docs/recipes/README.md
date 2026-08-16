# Recipes

Documentation is the biggest complaint about Hotwire, by a wide margin — not a niche gap, the top
complaint, including from people who love the framework and built a course on it. This directory exists
because most of the answer was already sitting inside `research/`, verified against source, and just
needed extracting and sharpening. These pages are not a consolation prize alongside the gem; they are the
highest-leverage thing crosswire ships.

## What's here

**[`corrections.md`](./corrections.md) — Advice that is now wrong.** Claims people repeat online — in
blog posts, in accepted Stack Overflow answers, in tutorials that were correct when written — checked
against current source (Turbo 8.0.23 / turbo-rails 2.0.23 / Stimulus 3.2.2 / Rails 8.1) and corrected.
Ordered by how likely you are to hit each one. Read this before you copy a snippet from a search result.

**[`diagnosis.md`](./diagnosis.md) — Why isn't this working?** A triage guide organized by symptom, not
by mechanism — because a symptom is what you actually have when something's broken. Each entry gives you
the cheapest check first, then the root cause, then the fix. Covers the "I clicked and nothing happened"
family (the single largest category of Hotwire problem report anywhere it's been measured), Content
Missing, Stimulus controllers that won't connect, forms that submit but don't update, unwanted full
reloads, JS libraries dying after morphs, frozen dialogs, and state that resets for every viewer when one
person edits.

### The recipes

**[`frames-vs-streams.md`](./frames-vs-streams.md) — Which tool for this update?** The escalation ladder:
plain link/redirect → Turbo Frame → Turbo Stream → `turbo_stream.replace(target, method: :morph)` → morph
page refresh → drop to Stimulus. Organised around the only question that actually decides it — **who owns
this region's state?** — rather than a feature comparison. Includes the fourth option most people miss
(targeted render *with* morph semantics — the only form of morphing that appears in 37signals' own shipped
code), when one frame is enough and when it genuinely isn't, the evidence for that default graded honestly
rather than oversold, and a decision table you can scan in fifteen seconds. **Start here if
you're new to the collection**; it's the root cause of the most-repeated "Hotwire is convoluted"
complaint.

**[`form-response-contract.md`](./form-response-contract.md) — My form submits but nothing happens.** The
303/422 contract, derived from Turbo's `form_submission.js`: why a `200` with HTML on a non-GET is
discarded, why only `303` works for redirect-after-POST, why the 422 body must be a complete document,
`:unprocessable_content` vs the deprecated `:unprocessable_entity`, rendering errors via Turbo Stream, and
the morphing interaction — **422 responses do morph**, which is what kills Stimulus-wrapped JS libraries
on the most ordinary flow in Rails.

**[`nested-forms.md`](./nested-forms.md) — The cocoon replacement.** Sean Doyle's frame-powered nested
attributes, shipping **zero custom Stimulus controllers**: `form.fields(index:)` plus add/remove buttons
that *are* form fields, so there's no client-side counter to desync and validation state survives for
free. Includes the implicit-submission hazard those `[formaction]` buttons create (with the one-line fix
and a keyboard-only system test), and the `<template>` fallback for the two cases a GET round-trip can't
serve.

**[`frame-breakout.md`](./frame-breakout.md) — Redirect the whole page from inside a frame.**
`redirect_to path, turbo_frame: "_top"` **does not exist** — and here's why it can't, in the maintainer's
own words, plus the ~25-line `Turbo::FrameRedirectable` concern that does work, why its flash hop is
necessary rather than a hack, and when `target="_top"` on the frame is the right answer instead (and when
it breaks multi-step flows).

Every page cites the `research/notes/*.md` file it was extracted from, so you can follow a claim back to
its primary source — a GitHub thread, a maintainer quote, a specific line of Turbo or Idiomorph source —
rather than trusting the summary. Where something couldn't be verified, the page says so instead of
smoothing it over.

## What's not here yet

**The rest of the pattern recipes.** Four of the 195 recipe candidates catalogued in
`research/notes/07-problem-mining.md` are written (above); the remainder — autosubmit, modals, infinite
scroll, broadcasting, and so on — are not. Don't assume a `docs/recipes/patterns/` directory exists just
because this README describes the shape of the collection. When they land, most will point at a crosswire
primitive rather than showing you the raw Turbo/Stimulus each time; where a primitive doesn't exist yet,
they'll show you the underlying pattern directly, because most of what's true here is true for any Hotwire
app, not just crosswire's.

## House rules for this collection

Set by `docs/COMPONENT_CONTRACT.md` and `docs/DECISIONS.md`, and worth restating here:

- **State limitations rather than working around them.** Where a maintainer has explicitly declined to
  fix something (turbo#1210, the morph/Stimulus-values conflict, is the canonical example — open 2.5
  years, "this is by design"), the recipe says so and quotes the maintainer, rather than pretending a
  workaround is a fix.
- **Where crosswire solves a problem documented here, say so in one line** — not more. Most of what's in
  `corrections.md` and `diagnosis.md` applies to any Hotwire app, with or without this gem.
- **No pre-2024 material trusted by default.** Turbo 8 changed enough (morphing, hover prefetch, the
  `unprocessable_content` rename, Devise 4.9's native Turbo support) that a large fraction of the
  historical blog corpus teaches a stack that no longer exists as described.
