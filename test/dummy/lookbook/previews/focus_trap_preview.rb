# frozen_string_literal: true

# **What it is.** Keep Tab inside a container while it is active, and move focus to a
# sensible place when it engages. A *behaviour* — no markup, no partial.
#
# **What it composes from.** `Crosswire::Presenters::FocusTrap` emits the `active` and
# `initial` values, an optional `active_class`, and — the part worth reading — **two**
# key-filter action descriptors:
#
#     action("keydown.tab->cycle", "keydown.shift+tab->cycle")
#
# Stimulus key filters are exact-match on modifier state, so a bare `keydown.tab`
# requires `shiftKey === false` and **silently drops Shift+Tab**. Backwards tabbing
# simply would not work, with no error anywhere. Both descriptors route to the same
# `#cycle`, which reads `event.shiftKey` itself (R8a).
#
# **Rule 0.** Do not use this for a modal. `<dialog>` opened with `showModal()` traps
# focus natively, including in the browser's own UI in a way JavaScript cannot match.
# This is for drawers, non-modal panels and toolbars — the cases `showModal()` does not
# cover.
class FocusTrapPreview < Lookbook::Preview
  # @param active toggle "Engage the trap"
  def default(active: true)
    render_with_template(template: "focus_trap_preview/default", locals: {active: active})
  end
end
