# frozen_string_literal: true

# **What it is.** Mirror this element's value or state onto another element on every
# change. A *behaviour* — no markup, no partial — and the generic primitive dependent
# selects, character counters, range/slider readouts and dark-mode toggle mirrors all
# compose from.
#
# **What it composes from.** `Crosswire::Presenters::Sync` emits `target` (a CSS
# selector, not a Stimulus target — the mirrored element is almost never a descendant),
# `attribute` (what gets WRITTEN on the target; default `"value"`) and `transform`
# (`"none"`, `"length"`, `"uppercase"`, `"lowercase"`, applied before writing). Reading
# THIS element is not configurable — checkboxes/radios read `.checked`, anything with a
# `.value` reads that, everything else reads `.textContent` — deliberately, so the
# common case (an `<input>` source, a `<span>` readout target) needs only `attribute` to
# name the write side.
#
# **Rule 0.** None generally — mirroring one element's state onto an unrelated one is
# not something any single native element/attribute does. (`<output for>` covers exactly
# one narrow case — a calculation tied to specific `<input>` ids — and does nothing for
# the cases below.)
class SyncPreview < Lookbook::Preview
  # A character counter: `transform: "length"` writes the typed text's length, not the
  # text itself, into the counter's `textContent`.
  #
  # @param max number "maxlength on the textarea"
  # @param transform select "~ [length, none, uppercase, lowercase]"
  def default(max: 280, transform: "length")
    render_with_template(template: "sync_preview/default", locals: {max: max, transform: transform})
  end

  # A range slider mirrored into a live readout — `attribute: "textContent"` on an
  # `<output>` that is not a descendant of the slider.
  def range_readout
    render_with_template(template: "sync_preview/range_readout")
  end
end
