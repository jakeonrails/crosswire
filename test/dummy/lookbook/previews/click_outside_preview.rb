# frozen_string_literal: true

# **What it is.** Dispatch a `cw--click-outside:clicked` event when a pointer event
# lands outside the element. A *behaviour* — no markup, no partial.
#
# **What it composes from.** `Crosswire::Presenters::ClickOutside` emits only the
# `enabled` value. On its own the controller does nothing visible — it only fires an
# event — so every real use pairs it with something that reacts to that event. The
# reference pairing, shown below, is `cw--dismiss`: `data-action=
# "cw--click-outside:clicked->cw--dismiss#dismiss"` wires the two together with no
# outlet and no cross-controller method call (R5), exactly per
# `Crosswire::ClickOutsideHelper`'s own doc example.
#
# **Rule 0.** The native Popover API (`popover="auto"`) and `<dialog>`'s
# `closedby="any"` already give light-dismiss for their own cases with zero JavaScript
# — reach for this controller for everything else: a custom-styled menu, a non-modal
# panel, an inline editor that should commit when focus/pointer activity leaves it.
class ClickOutsidePreview < Lookbook::Preview
  # `enabled: false` leaves the very click that opens something from being misread as
  # an outside click on itself — flip it on once the thing is actually open (R5a #2:
  # writing the value attribute directly). Here it starts enabled so the panel is
  # already showing.
  #
  # @param enabled toggle "Whether the listener is currently armed"
  def default(enabled: true)
    render_with_template(template: "click_outside_preview/default", locals: {enabled: enabled})
  end
end
