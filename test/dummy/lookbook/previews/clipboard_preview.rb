# frozen_string_literal: true

# **What it is.** Copy a value to the clipboard and announce that it worked. A
# *behaviour* — no markup, no partial.
#
# **What it composes from.** `Crosswire::Presenters::Clipboard` owns three elements'
# attributes — `source`, `button`, and the `status` live region — plus the success class.
#
# Two details in here are load-bearing and easy to get wrong:
#
# * **The live region must be in the initial markup.** A live region injected into the
#   DOM at announcement time is not announced by most screen readers; only changes to an
#   *already-present* region are. `status_attrs` exists so you render it up front, empty.
# * **`success_class` goes on the ROOT, not on the button** — even though the controller
#   applies it to the button. Stimulus's Classes API resolves `data-<identifier>-<name>-class`
#   against the controller's own element, never a target's; put it on the target and
#   `this.successClass` throws `Missing attribute` at runtime (R3a).
class ClipboardPreview < Lookbook::Preview
  # Copies the value of the `source` element.
  #
  # @param success_class text "Applied on copy — omit and the controller skips it (R3)"
  # @param success_duration number "How long the success state is held, in ms"
  def default(success_class: "is-copied", success_duration: 2000)
    render_with_template(
      template: "clipboard_preview/default",
      locals: {success_class: success_class, success_duration: success_duration}
    )
  end

  # With `text:` set there is no source element at all.
  def static_text
    render_with_template(template: "clipboard_preview/static_text")
  end
end
