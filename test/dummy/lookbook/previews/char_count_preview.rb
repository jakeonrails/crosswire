# frozen_string_literal: true

# **What it is.** A live character count for an input or textarea, counting down
# against `max` with warn/over states — character counters, client-side validation,
# textarea autogrow. A *behaviour* — no markup, no partial.
#
# **What it composes from.** `Crosswire::Presenters::CharCount` emits `max`
# (required) and `warnAt`; the controller counts **grapheme clusters** via
# `Intl.Segmenter`, not `.length` (an emoji is one character to a person, several
# UTF-16 code units to JavaScript).
#
# **The aria-live detail that is easy to skip.** Announcing on every keystroke reads
# "279… 278… 277…" to a screen reader for as long as the user types — worse than no
# live region at all. Rather than a second announcer element, the controller
# **debounces its writes** to the one `output` target: the DOM only updates once the
# user pauses, so the live region only speaks then too. The very first render (on
# connect) is immediate, so a pre-filled value is correct before anyone has typed.
#
# **Rule 0.** `<output for>` covers one narrow case (a calculation tied to specific
# input ids) and does nothing for a live length readout, so this earns its JS.
class CharCountPreview < Lookbook::Preview
  # @param max number "Character limit — required, there is no sensible default"
  # @param warn_at number "Fraction of max (0–1) at which the warning state turns on"
  def default(max: 120, warn_at: 0.9)
    render_with_template(
      template: "char_count_preview/default",
      locals: {max: max, warn_at: warn_at}
    )
  end
end
