# frozen_string_literal: true

# **What it is.** Enter/leave transitions driven entirely by CSS classes you supply. A
# *behaviour* — no markup, no partial.
#
# **What it composes from.** `Crosswire::Presenters::Transition` emits nothing but
# Stimulus Classes API attributes (`data-cw--transition-leave-class`, …), which is why
# the controller carries no design-system opinion and works identically under Tailwind,
# plain CSS or anything else. Every class is optional and the controller guards each one
# with `hasFooClass` — reading `this.fooClass` when the attribute is absent **throws**
# (R3), and that is the single most likely way a component breaks for a consumer.
#
# **Rule 0.** For pure enter animations, `@starting-style` plus `transition-behavior:
# allow-discrete` now does this natively. What CSS still cannot do is *leave*: removal is
# synchronous, so something has to hold the node open while it animates. That is what
# `leave_on` is for.
class TransitionPreview < Lookbook::Preview
  # @param leave text "Class applied for the whole leave transition"
  # @param leave_from text "Class applied at the start of leave"
  # @param leave_to text "Class applied for the settled leave state"
  def default(leave: "fade", leave_from: "opacity-100", leave_to: "opacity-0")
    render_with_template(
      template: "transition_preview/default",
      locals: {leave: leave, leave_from: leave_from, leave_to: leave_to}
    )
  end

  # `leave_on` is the composition helper: it wires `cw--transition#leave` as the handler
  # for another controller's cancelable removal event, `cw--dismiss:dismissing` by default.
  def leave_on_dismiss
    render_with_template(template: "transition_preview/leave_on_dismiss")
  end
end
