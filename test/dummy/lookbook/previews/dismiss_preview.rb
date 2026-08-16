# frozen_string_literal: true

# **What it is.** Remove or hide a container — a flash message, a banner, a notice — on
# click, on Escape, or on a timeout. A *behaviour*: it decorates markup you already own
# and ships no partial of its own.
#
# **What it composes from.** `Crosswire::Presenters::Dismiss` (the trigger's accessible
# name, the `tabindex="-1"` that lets Escape reach the container when focus is inside it)
# plus `cw--dismiss`, which owns removal, focus rescue (R8) and the cancelable
# `cw--dismiss:dismissing` event (R6).
#
# **The seam worth studying** is the `with_transition` scenario. `Node.remove()` is
# synchronous — once it runs there is nothing left to animate — so `dismiss` dispatches a
# *cancelable* `cw--dismiss:dismissing` first, carrying a `complete()` callback in
# `detail`. `transition` listens for exactly that event. Neither controller knows about
# the other; they meet at an event name.
class DismissPreview < Lookbook::Preview
  # Bare attribute builder on a container you already have.
  #
  # @param remove toggle "Remove the node, or just hide it (safer inside a Turbo Frame)"
  # @param escape toggle "Also dismiss on Escape"
  # @param label text "Accessible name for the trigger"
  def default(remove: true, escape: true, label: "Dismiss notice")
    render_with_template(
      template: "dismiss_preview/default",
      locals: {remove: remove, escape: escape, label: label}
    )
  end

  # `dismiss` + `transition` stacked on one element: the reference example of R6.
  def with_transition
    render_with_template(template: "dismiss_preview/with_transition")
  end
end
