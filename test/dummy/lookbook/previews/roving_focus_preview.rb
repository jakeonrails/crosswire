# frozen_string_literal: true

# **What it is.** Move focus across a set of `item` targets with arrow keys using the
# roving tabindex model — WAI-ARIA APG Keyboard Interface Practices. A *behaviour* — no
# markup, no partial, no opinion about what the items are (buttons, links, list items).
#
# **What it composes from.** `Crosswire::Presenters::RovingFocus` renders exactly one
# item's `tabindex="0"` server-side (every other item gets `"-1"`) so Tab moves in and
# out of the whole group in a single stop, correct before JavaScript loads. Home/End
# jump to the first/last item; typeahead, when enabled, matches an item's leading text
# per APG's suggested ~500ms buffering — a genuine APG requirement that (per
# research/notes/03) no other Stimulus library in the ecosystem implements.
#
# `tabs` builds directly on top of this by STACKING controllers on the tablist element
# (`data-controller="cw--roving-focus cw--tabs"`) rather than reimplementing arrow-key
# navigation — see the `tabs` preview for that composition; this preview shows the
# primitive standalone, the way a toolbar or a plain listbox would use it.
#
# **Rule 0.** None applies — there is no native element that gives arrow-key
# navigation across a set of custom widgets for free.
class RovingFocusPreview < Lookbook::Preview
  # A toolbar: horizontal orientation, click or arrow keys move focus.
  #
  # @param orientation select "~ [horizontal, vertical, both]"
  # @param wrap toggle "Wrap from the last item back to the first"
  def default(orientation: "horizontal", wrap: true)
    render_with_template(template: "roving_focus_preview/default", locals: {orientation: orientation, wrap: wrap})
  end

  # A listbox with typeahead enabled: type a fruit's first letter (repeatedly, to cycle
  # through matches) to jump to it, per APG's composite-widget typeahead requirement.
  def typeahead_listbox
    render_with_template(template: "roving_focus_preview/typeahead_listbox")
  end
end
