# frozen_string_literal: true

# **What it is.** WAI-ARIA APG Combobox (editable, list autocomplete) — a text input
# with an attached, filterable listbox and a hidden field carrying the submitted
# value. See the "Native controls first" scenario below before reaching for this at
# all — a plain `<select>` or a `<datalist>` covers most "pick one" cases with zero
# JavaScript.
#
# **What it composes from.** `cw--combobox` maintains the active option purely
# through `aria-activedescendant` — an ANTI-composition with `cw--roving-focus`
# (see `Crosswire::Presenters::Combobox`'s docstring for why "combobox =
# roving-focus + listbox" is the wrong guess): DOM focus never leaves the input, no
# option ever carries a `tabindex`. The one real composition is `cw--click-outside`,
# stacked on the same root and armed only while the listbox is expanded (R5a
# mechanism 2) — visible explicitly in the "compose your own" scenario below.
#
# **Rule 0 note.** See the "Native controls first" scenario, and
# `Crosswire::Presenters::Combobox`'s own Rule 0 docstring — reach for this
# presenter only when the submitted value differs from the displayed text, the list
# is long enough that filtering is the point, and the result has to land in a form
# field rather than navigate.
class ComboboxPreview < Lookbook::Preview
  STATES = [
    {value: "AL", display: "Alabama"}, {value: "AK", display: "Alaska"},
    {value: "AZ", display: "Arizona"}, {value: "AR", display: "Arkansas"},
    {value: "CA", display: "California"}, {value: "CO", display: "Colorado"},
    {value: "CT", display: "Connecticut"}, {value: "DE", display: "Delaware"},
    {value: "FL", display: "Florida"}, {value: "GA", display: "Georgia"},
    {value: "HI", display: "Hawaii"}, {value: "ID", display: "Idaho"},
    {value: "IL", display: "Illinois"}, {value: "IN", display: "Indiana"},
    {value: "IA", display: "Iowa"}, {value: "KS", display: "Kansas"},
    {value: "KY", display: "Kentucky"}, {value: "LA", display: "Louisiana"},
    {value: "ME", display: "Maine"}, {value: "MD", display: "Maryland"},
    {value: "MA", display: "Massachusetts"}, {value: "MI", display: "Michigan"},
    {value: "MN", display: "Minnesota"}, {value: "MS", display: "Mississippi"},
    {value: "MO", display: "Missouri"}, {value: "MT", display: "Montana"},
    {value: "NE", display: "Nebraska"}, {value: "NV", display: "Nevada"},
    {value: "NH", display: "New Hampshire"}, {value: "NJ", display: "New Jersey"}
  ].freeze

  # The shipped partial, `filter: "client"` (the default) — all 30 options rendered
  # up front, the controller only ever toggles `hidden`.
  #
  # @param autocomplete select "~ [none, list, both]"
  # @param min_length number "Remote/typed filter minimum query length (client mode ignores this — it only matters once you switch to remote)"
  def default(autocomplete: "list", min_length: 0)
    render_with_template(
      template: "combobox_preview/default",
      locals: {autocomplete: autocomplete, min_length: min_length, states: STATES}
    )
  end

  # `autocomplete: "both"` — typing completes to the first case-insensitive prefix
  # match, selecting the completed portion so the next keystroke overwrites it
  # (never after Backspace/Delete — see the controller docstring).
  def inline_autocomplete
    render_with_template(template: "combobox_preview/inline_autocomplete", locals: {states: STATES})
  end

  # `filter: "remote"` against `/combobox_demo`, a real route on this dummy app (see
  # `test/dummy/config/routes.rb`) — the same "a live backend beats a simulated one"
  # rationale `sortable`'s own preview documents. No options are rendered here at
  # all; they arrive entirely from the server as the query debounces.
  def remote
    render_with_template(template: "combobox_preview/remote")
  end

  # `value:`/`display:` rendered server-side (R4) — the exact regression `tabs` hit
  # (BUILD-LOG §3): a controller reading its initial state from only ONE of several
  # places is one refactor away from reading `""` on connect and clobbering a
  # correct page. Inspect the rendered HTML before any JavaScript runs: the hidden
  # field already carries the value, the input already shows the display text, and
  # the matching option already carries `aria-selected="true"`.
  def preselected
    render_with_template(template: "combobox_preview/preselected", locals: {states: STATES})
  end

  # `cw.combobox_for` — different markup than the shipped partial, the hidden field
  # written by hand, and `data-controller="cw--combobox cw--click-outside"` visible
  # on the root with nothing hidden inside a partial.
  def compose_your_own
    render_with_template(template: "combobox_preview/compose_your_own", locals: {states: STATES.first(6)})
  end

  # Rule 0, made concrete: the same "pick a state" job, three ways, side by side. A
  # plain `<select>` (zero JS, real constraint validation, a native mobile picker).
  # A text input plus `<datalist>` (zero JS, but the SUBMITTED value is whatever was
  # typed — free text, not a code). `cw.combobox` (the only one of the three where
  # the displayed text and the submitted value can legitimately differ). Reach for
  # the combobox only when you are actually in that third case.
  def native_first
    render_with_template(template: "combobox_preview/native_first", locals: {states: STATES.first(10)})
  end
end
