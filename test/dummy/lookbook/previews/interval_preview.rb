# frozen_string_literal: true

# **What it is.** Dispatch a `cw--interval:tick` event every N milliseconds while the
# document is visible. A *behaviour* — no markup, no partial, no trigger of its own; wire
# whatever should run on each tick onto `cw--interval:tick`.
#
# **What it composes from.** `Crosswire::Presenters::Interval` emits `ms` (required —
# there is no sensible default polling cadence) and `immediate`. Sits beside `timeout`,
# not on top of it: `timeout` fires **once** and never re-arms itself; this re-arms on
# every tick and keeps going until the controller disconnects. A "resend code in 30s"
# cooldown or a toast's auto-dismiss wants `timeout`; a polling `<turbo-frame>`, a
# progress bar for a background job, or a live "who's online" dashboard wants `interval`.
#
# **It pauses while the tab is hidden.** Switch to another tab and back — the tick count
# below stops advancing while this tab is hidden, and resumes with a **fresh** interval
# on return rather than bursting out every tick it "missed." A naive `setInterval` either
# burns cycles in the background or dumps a pile of stale ticks on refocus; this does
# neither.
#
# **Rule 0.** None beyond wrapping `setInterval` — the value this component adds over a
# bare one is entirely the visibility pause/resume and Turbo-aware teardown above. For
# polling a server specifically, the composition is a lazy `<turbo-frame>` reloaded on
# every tick, not a bespoke "poll" controller:
#
#   <turbo-frame id="job_status" src="...">
#     <div data-controller="cw--interval" data-cw--interval-ms-value="2000"
#          data-action="cw--interval:tick->job_status#reload"></div>
#   </turbo-frame>
class IntervalPreview < Lookbook::Preview
  # @param ms number "Milliseconds between ticks — required, there is no sensible default"
  # @param immediate toggle "Dispatch one extra tick immediately on connect"
  def default(ms: 1000, immediate: false)
    render_with_template(
      template: "interval_preview/default",
      locals: {ms: ms, immediate: immediate}
    )
  end
end
