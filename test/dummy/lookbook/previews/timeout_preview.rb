# frozen_string_literal: true

# **What it is.** Dispatch an action once, N ms after connect or after a trigger. A
# *behaviour* — no markup, no partial, and no trigger of its own; wire `start`/
# `cancel`/`restart` onto whatever elements or events should control it.
#
# **What it composes from.** `Crosswire::Presenters::Timeout` emits `delay` and
# `start_on_connect`. Sits beside `interval`, not on top of it: `interval` re-arms
# itself and keeps ticking, `timeout` fires once and never re-arms on its own. Its
# canonical pairing — shown below — is with `cw--dismiss` for a toast that
# auto-dismisses, with `restart`/`cancel` wired to `mouseenter`/`mouseleave` so hovering
# pauses the countdown, exactly the recipe from `Crosswire::TimeoutHelper`'s own doc
# example.
#
# **Rule 0.** None. There is no platform primitive for "run this once, later" beyond a
# bare `setTimeout`, which is exactly what this wraps — plus Turbo-aware teardown and
# pausing while the tab is hidden.
class TimeoutPreview < Lookbook::Preview
  # Hover the toast to pause the countdown (`restart` on `mouseleave` pushes the
  # deadline back out, `cancel` on `mouseenter` stops it) — the same shape as
  # hover-to-pause on a real toast stack, without needing `interval`'s repetition.
  #
  # @param delay number "Milliseconds before cw--timeout:elapsed fires"
  def default(delay: 4000)
    render_with_template(template: "timeout_preview/default", locals: {delay: delay})
  end
end
