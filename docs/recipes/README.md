<%# crosswire:contract v1 %>
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

Both pages cite the `research/notes/*.md` file they were extracted from, so you can follow a claim back
to its primary source — a GitHub thread, a maintainer quote, a specific line of Turbo or Idiomorph
source — rather than trusting the summary.

## What's not here yet

**Pattern recipes are not written.** The 195 recipe candidates catalogued in
`research/notes/07-problem-mining.md` (autosubmit, modals, infinite scroll, nested forms, broadcasting,
and so on) are the next layer of this directory, and they don't exist yet — don't assume a
`docs/recipes/patterns/` or similar exists just because this README describes the shape of the
collection. When they land, most will point at a crosswire primitive rather than showing you the raw
Turbo/Stimulus each time; where a primitive doesn't exist yet, they'll show you the underlying pattern
directly, because most of what's true here is true for any Hotwire app, not just crosswire's.

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
