# frozen_string_literal: true

# **What it is.** Submit the owning form automatically on input or change — search-as-you-
# type, filter dropdowns, auto-saving forms. A *behaviour* — no markup, no partial.
#
# **What it composes from.** `Crosswire::Presenters::Autosubmit` emits `delay`, `event` and
# an optional `scope`; `cw--autosubmit` owns the debounce and the double-submit guard.
#
# Two things this controller enforces that hand-rolled versions get wrong:
#
# * **Always `form.requestSubmit()`, never `form.submit()`.** `submit()` skips HTML5
#   validation *and* bypasses Turbo entirely, turning what should be a Turbo visit into a
#   full page load. There is no option here that reaches `form.submit()`.
# * **Focus and caret preservation is markup, not behaviour.** Give the field a stable
#   `id` and `data-turbo-permanent` and Turbo keeps the live element across the round
#   trip. Under Turbo 8 morphing an element with no `id` is always replaced rather than
#   patched, so the `id` is doing real work either way.
#
# **Rule 0.** For the simplest case — no debounce, no guard, no events —
# `onchange="this.form.requestSubmit()"` is the whole feature with none of our JavaScript.
class AutosubmitPreview < Lookbook::Preview
  # @param delay number "Debounce in ms — 0 submits on every keystroke"
  # @param event select "~ [input, change]"
  def default(delay: 300, event: "input")
    render_with_template(
      template: "autosubmit_preview/default",
      locals: {delay: delay, event: event}
    )
  end

  # `scope:` points a field at a form it is not nested inside.
  def select_and_scope
    render_with_template(template: "autosubmit_preview/select_and_scope")
  end
end
