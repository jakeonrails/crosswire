# frozen_string_literal: true

# **What it is.** Track unsaved changes in a form and guard against losing them —
# dirty-form warnings, multi-step wizards, form state across a Turbo cache preview.
# A *behaviour* — no markup, no partial; it decorates a `<form>` you already have.
#
# **What it composes from.** `Crosswire::Presenters::DirtyForm` emits `guard`, wires
# `input`/`change` on the root to `#check`, and the controller owns three separate
# guards — `beforeunload`, `turbo:before-visit`, `turbo:before-frame-render` —
# because `beforeunload` alone **does not fire on a Turbo Drive visit**, the single
# most common bug in hand-rolled versions of this.
#
# **The free CSS hook.** `data-dirty="true"/"false"` is always set on the form,
# independent of `dirty_class` — try it in this preview and watch the status text
# below the fields change as you type.
#
# **`guard: false`** still tracks dirtiness (`data-dirty`, the `changed`/`reset`
# events) without ever blocking navigation — useful for driving a "Save" button's
# disabled state with no prompt at all.
#
# **Rule 0.** None for the whole feature — there is no platform primitive for "warn
# before leaving a form with unsaved changes" that survives Turbo Drive navigation.
class DirtyFormPreview < Lookbook::Preview
  # @param guard toggle "Block navigation while dirty — false just tracks, never prompts"
  def default(guard: true)
    render_with_template(
      template: "dirty_form_preview/default",
      locals: {guard: guard}
    )
  end
end
