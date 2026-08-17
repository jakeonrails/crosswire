# frozen_string_literal: true

# **What it is.** One reusable confirmation dialog for the whole page — the replacement
# for `window.confirm` and for Turbo's `data-turbo-confirm`.
#
# **What it composes from.** This is the reference example of R5a: `cw--confirm` **stacks
# on the same element** as `cw--dialog` (`data-controller="cw--dialog cw--confirm"`) rather
# than wrapping it. `Crosswire::Presenters::Confirm` builds a `Dialog` presenter internally
# and merges its `root_attrs` + `panel_attrs`, then adds `role="alertdialog"`,
# `aria-labelledby`/`aria-describedby`, and its own title/body/label values.
#
# The two halves of the composition:
#
# * **outbound** — `confirm` opens the dialog by writing `cw--dialog`'s own value
#   attribute (`data-cw--dialog-open-value`), which is the same external-write path a
#   Turbo morph takes.
# * **inbound** — it listens for `cw--dialog:opened` / `cw--dialog:closed` via the
#   presenter's `action()` pass-through. Never a cross-controller method call.
#
# **Mount it once**, in the application layout. `Turbo.config.forms.confirm` then routes
# every `data-turbo-confirm` through it — see the presenter docstring for that wiring.
class ConfirmPreview < Lookbook::Preview
  # The shipped partial, via `cw.confirm`.
  #
  # @param title text
  # @param body text
  # @param confirm_label text
  # @param cancel_label text
  # @param destructive toggle "Focuses Cancel rather than Confirm, per APG"
  def default(title: "Delete this project?", body: "This cannot be undone.",
              confirm_label: "Delete", cancel_label: "Cancel", destructive: true)
    render_with_template(
      template: "confirm_preview/default",
      locals: {title: title, body: body, confirm_label: confirm_label,
               cancel_label: cancel_label, destructive: destructive}
    )
  end

  # `cw.confirm_for` yields the presenter. Note that a single `<dialog>` element
  # carries both controllers — there is no wrapper div anywhere in this markup.
  def compose_your_own
    render_with_template(template: "confirm_preview/compose_your_own")
  end
end
