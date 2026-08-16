# frozen_string_literal: true

require "time"
require "crosswire/presenter"

module Crosswire
  module Presenters
    # RelativeTime — render and self-update a relative timestamp ("3 minutes
    # ago").
    #
    # Rule 0, and it is a strong one here (R9): reach for
    # [`<relative-time>`](https://github.com/github/relative-time-element) from
    # `@github/relative-time-element` first. It is a mature, actively maintained
    # custom element that does this properly — `Intl.RelativeTimeFormat`
    # localisation, a `title` with the absolute time, per-instance self-adjusting
    # `setTimeout` scheduling, zero lifecycle code because a custom element's
    # lifecycle is owned by the browser rather than by Stimulus/Turbo connect
    # discipline. It works after a Turbo Stream append, a frame swap, a morph, or
    # a cache restore with nothing from you. If your app can take one more small
    # dependency, ship that instead of this controller.
    #
    # THIS controller exists for the one case where `<relative-time>` is not the
    # answer: you do not want another JS dependency, and you only need
    # coarse-grained English relative phrasing (seconds/minutes/hours/days), not
    # the web component's full locale/precision/duration/micro-format surface. It
    # is a deliberately small fallback, not a competing implementation — it uses
    # `Intl.RelativeTimeFormat` itself rather than hand-rolling "3 minutes ago"
    # string concatenation, so at least the actual formatting is correct and
    # localised, only the surrounding feature set is smaller.
    #
    # A behaviour, not a widget — it decorates an element you already have (a
    # `<time>`, typically) and ships no partial. The consumer supplies the
    # element's initial text content themselves (e.g. Rails' own
    # `time_ago_in_words`) so there is a sensible fallback before JS runs and for
    # crawlers/no-JS clients; this presenter only computes the attributes, never
    # the visible text.
    #
    # Accessibility (R2): the visible text is coarse and relative, so the
    # instant it actually refers to must still be recoverable. `root_attrs` always
    # emits BOTH a literal `datetime` attribute (what `<time>` semantics and
    # assistive tech expect) and a `title` (what a mouse hover or many screen
    # readers surface) carrying the same absolute instant, formatted for humans.
    # Deliberately no `aria-live` — a page of self-updating timestamps announcing
    # themselves on every change is a screen-reader denial-of-service, and the
    # `title`/`datetime` pair is the correct accessible escape hatch for "when
    # exactly?", not a live announcement.
    class RelativeTime < Presenter
      attr_reader :datetime, :format, :threshold

      # Matches the final tier of the controller's own update back-off (every
      # hour under a day, then stop) — see the controller docstring. Configure a
      # smaller threshold to switch to an absolute date sooner, e.g. an hour for
      # a chat where "yesterday" is more useful than a stale "18 hours ago".
      DEFAULT_THRESHOLD = 86_400

      # @param datetime [String] ISO 8601 instant, e.g. `Time#utc#iso8601`.
      #   Required — there is no meaningful default "when" for a relative time.
      # @param format [String] "relative" (default) — self-updating relative
      #   phrasing — or "datetime" — a static formatted absolute date/time,
      #   never updated or scheduled. Passed straight through to the controller.
      # @param threshold [Numeric] seconds after which the element stops
      #   updating and switches to an absolute date, regardless of `format`.
      #   Default #{DEFAULT_THRESHOLD} (one day).
      # @param overrides [Hash] merged into the root element, last
      def initialize(datetime:, format: "relative", threshold: DEFAULT_THRESHOLD, **overrides)
        @datetime = datetime
        @format = format
        @threshold = threshold
        super(**overrides)
      end

      def root_attrs
        instant = Time.iso8601(datetime)

        merge(
          controller_attrs,
          values(datetime: datetime, format: format, threshold: threshold),
          {
            "datetime" => datetime,
            "title" => absolute_title(instant)
          },
          overrides
        )
      end

      private

      # A plain, unambiguous absolute rendering — not locale-aware, deliberately:
      # the presenter runs with no view context and no request, so it has no
      # user locale to format for. This is the accessible fallback shown in a
      # tooltip/to a screen reader, not the primary display, so clarity beats
      # localisation here. `Intl.DateTimeFormat` in the controller is where any
      # locale-aware absolute rendering (`format: "datetime"`) belongs instead.
      def absolute_title(instant)
        instant.utc.strftime("%B %-d, %Y, %-I:%M %p UTC")
      end
    end
  end
end
