# frozen_string_literal: true

# **What it is.** A trigger that shows and hides a panel — the APG Disclosure pattern.
# The one primitive almost every other "show/hide" feature turns out to be.
#
# **What it composes from.** `Crosswire::Presenters::Disclosure` (all ARIA: `aria-expanded`,
# `aria-controls`, the id relationships, `type="button"`, the optional landmark `region`)
# plus `cw--disclosure`, which owns only the open/closed value.
#
# **Rule 0.** If you need no server-rendered state, no animation and no external control,
# `<details>`/`<summary>` does this with no JavaScript. Reach for `cw--disclosure` when the
# open state must be rendered by the server, survive a Turbo morph, or be driven from
# elsewhere on the page.
class DisclosurePreview < Lookbook::Preview
  # The shipped partial, via `crosswire_disclosure`.
  #
  # @param summary text "Trigger label"
  # @param open toggle "Server-rendered initial state — correct before JS loads"
  # @param region toggle "Label the panel as a landmark region (APG: only when substantial)"
  # @param open_class text "Class applied to the root while open"
  def default(summary: "Shipping details", open: false, region: false, open_class: "is-open")
    render_with_template(
      template: "disclosure_preview/default",
      locals: {summary: summary, open: open, region: region, open_class: open_class.presence}
    )
  end

  # `crosswire_disclosure_for` yields the presenter and renders none of our markup — here
  # driving a native `<details>`/`<summary>`, an element structure the shipped partial
  # never produces. The controller still works: it only ever knew targets and values.
  def compose_your_own
    render_with_template(template: "disclosure_preview/compose_your_own")
  end

  # Caller `class`, `data-controller` and `data-action` are merged, not clobbered —
  # `Crosswire::Attributes.merge` unions exactly those three keys.
  def caller_overrides
    render_with_template(template: "disclosure_preview/caller_overrides")
  end
end
