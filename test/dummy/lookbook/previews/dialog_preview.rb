# frozen_string_literal: true

# **What it is.** A modal or non-modal dialog built on the native `<dialog>` element.
#
# **What it composes from.** `Crosswire::Presenters::Dialog` (accessible name via
# `aria-labelledby`, `aria-haspopup="dialog"` + `aria-controls` on the trigger,
# `type="button"`, the server-rendered `open` state) plus `cw--dialog`, which owns
# `showModal()`/`close()`, the native `cancel`/`close` events, backdrop clicks, and the
# two Turbo defences (`turbo:before-morph-element`, `turbo:before-cache`).
#
# **Rule 0.** Use the platform. `<dialog>` + `showModal()` already gives you the top
# layer, the backdrop, focus containment and Escape-to-close for free — this controller
# exists for the parts the platform does *not* do: server-rendered open state that
# survives a Turbo morph, and the cache/morph reset.
class DialogPreview < Lookbook::Preview
  # The shipped partial, via `cw.dialog`.
  #
  # @param title text "Becomes the accessible name AND the visible heading"
  # @param trigger_label text "Omit to place your own trigger anywhere on the page"
  # @param open toggle "Rendered open by the server"
  # @param modal toggle "showModal() (top layer + backdrop) vs show()"
  # @param dismissable toggle "Escape and backdrop clicks close it"
  def default(title: "Delete this project?", trigger_label: "Delete…", open: false,
              modal: true, dismissable: true)
    render_with_template(
      template: "dialog_preview/default",
      locals: {title: title, trigger_label: trigger_label, open: open,
               modal: modal, dismissable: dismissable}
    )
  end

  # Non-dismissable and non-modal: `show()` instead of `showModal()`, Escape and backdrop
  # clicks ignored. Use sparingly — a dialog a keyboard user cannot escape needs a very
  # good reason and an obvious close control.
  def non_modal
    render_with_template(template: "dialog_preview/non_modal")
  end

  # `cw.dialog_for` yields the presenter. The trigger does not have to live inside
  # the dialog's own root — `trigger_attrs` carries `aria-controls`, so it can sit
  # anywhere on the page.
  def compose_your_own
    render_with_template(template: "dialog_preview/compose_your_own")
  end
end
