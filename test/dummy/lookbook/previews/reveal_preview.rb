# frozen_string_literal: true

# **What it is.** Toggle an input between `password` and `text`, or unmask masked
# text — password show/hide, click-to-reveal. A *behaviour* — no markup, no partial.
#
# **What it composes from.** `Crosswire::Presenters::Reveal` emits `revealed`
# (rendered server-side, R4) and the trigger's `aria-pressed`. The controller never
# clears or replaces the input's `value` when flipping `type` — that would lose what
# the user typed and break password managers watching the field.
#
# **The cache-leak guard.** A password left revealed inside Turbo's snapshot cache
# is a real information leak the next time that page is restored from cache. Two
# separate hooks close it: `disconnect()` (ordinary teardown) and `turbo:before-cache`
# (fired before Turbo clones the live DOM into its cache — earlier than
# `disconnect()` ever runs).
#
# **Rule 0.** None — there is no platform primitive for flipping an input's own
# `type` from a click.
class RevealPreview < Lookbook::Preview
  # @param revealed toggle "Server-rendered initial state — correct before JS loads"
  def default(revealed: false)
    render_with_template(
      template: "reveal_preview/default",
      locals: {revealed: revealed}
    )
  end
end
