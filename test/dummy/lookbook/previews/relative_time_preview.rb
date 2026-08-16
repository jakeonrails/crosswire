# frozen_string_literal: true

# **What it is.** Render and self-update a relative timestamp ("3 minutes ago"). A
# *behaviour* — no markup, no partial — that decorates an element you already have
# (typically a `<time>`); you supply its initial text content yourself (Rails'
# `time_ago_in_words` is the obvious choice) so there is a sensible fallback before JS
# runs and for crawlers/no-JS clients.
#
# **Reach for [`<relative-time>`](https://github.com/github/relative-time-element)
# first.** It is a mature, actively maintained custom element that does this properly —
# `Intl.RelativeTimeFormat` localisation, a `title` with the absolute time, per-instance
# self-adjusting scheduling, and zero lifecycle code because a custom element's lifecycle
# is owned by the browser rather than by Stimulus/Turbo connect discipline. If your app
# can take one more small dependency, ship that instead. **This** controller exists only
# for the case where you do not want another JS dependency and only need coarse-grained
# English relative phrasing, not the web component's full locale/precision/duration
# surface.
#
# **What it composes from.** `Crosswire::Presenters::RelativeTime` emits `datetime`
# (required — an absolute instant, never a duration), `format`, `threshold`, and always
# renders both a literal `datetime` attribute and a `title` carrying the same absolute
# instant formatted for humans — the accessible escape hatch for "when exactly?".
#
# **Deliberately no `aria-live`.** A page of self-updating timestamps announcing
# themselves on every change is a screen-reader denial-of-service, not a convenience.
# `title`/`datetime` is the correct accessible answer here — not a live region — and this
# component does not "fix" that by adding one.
#
# **Rule 0.** See above — `<relative-time>` is the strong Rule 0 case (R9) for this
# entire component.
class RelativeTimePreview < Lookbook::Preview
  # @param seconds_ago number "How long ago the timestamp is, computed at render time"
  # @param threshold number "Seconds of age after which it switches to an absolute date and stops updating"
  def default(seconds_ago: 45, threshold: 86_400)
    datetime = (Time.now.utc - seconds_ago).iso8601

    render_with_template(
      template: "relative_time_preview/default",
      locals: {datetime: datetime, threshold: threshold}
    )
  end
end
