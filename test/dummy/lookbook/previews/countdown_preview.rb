# frozen_string_literal: true

# **What it is.** Tick down to a deadline and dispatch `cw--countdown:elapsed` at zero. A
# *behaviour* — no markup, no partial — that does own a second element: the `output`
# target that receives the ticking text.
#
# **What it composes from.** `Crosswire::Presenters::Countdown` emits `deadline`
# (required — an absolute instant, never a duration, so a page restored from Turbo's
# cache recomputes the correct remaining time rather than drifting) and `format`.
# Composes with `timeout` for "do something at zero" with no ticking display, and with
# `transition` for a flash effect in the final seconds.
#
# **`output_attrs` rests at `role="timer"` and `aria-live="off"`, and this preview does
# not change that.** A live region re-announcing every second is a screen-reader
# denial-of-service, not a countdown. The controller flips `aria-live` to `"assertive"`
# for the **final 30 seconds only**, then reverts to `"off"`. The default deadline below
# is 40 seconds out specifically so that, if you leave this preview open, you can watch
# — or inspect in dev tools — that transition happen for real at the 30-second mark,
# rather than taking it on faith.
#
# **Rule 0.** None — there is no platform primitive for "count down to an absolute
# instant and tell me when it arrives." (A countdown that must fire while the app is
# backgrounded is a native local notification, out of scope for this controller.)
class CountdownPreview < Lookbook::Preview
  # @param seconds_from_now number "Deadline, computed at render time — leave this open past 30s left to see aria-live flip to assertive"
  # @param format select "~ [clock, words]"
  def default(seconds_from_now: 40, format: "clock")
    deadline = (Time.now.utc + seconds_from_now).iso8601

    render_with_template(
      template: "countdown_preview/default",
      locals: {deadline: deadline, format: format}
    )
  end
end
