# frozen_string_literal: true

# **What it is.** Treat an arbitrary event as a click on some element. A *behaviour* — no
# markup, no partial — that exists to keep OBSERVERS pure: `intersection` reports
# visibility and knows nothing about navigation, `hotkey` reports a keypress and knows
# nothing about what it should do, and neither should grow a navigation opinion just to
# serve the one feature that needs it. `activate` is that opinion, factored out.
#
# **What it composes from.** `Crosswire::Presenters::Activate` emits `target` (a CSS
# selector, `nil` meaning "my own element") and `on_connect`. Worked composition:
# **infinite scroll is `intersection` + `activate` + a lazy `<turbo-frame>`** — a
# sentinel dispatches `cw--intersection:entered`, `activate` turns that into a real click
# on the "load more" link, and the frame does the actual loading. Not a bespoke
# infinite-scroll controller.
#
# **The synthetic click is not a real one.** `target.click()` dispatches a genuine click
# event, but `event.isTrusted` is `false` and `event.detail` is `0` (a real click's
# `detail` is the click count — 1, 2 for a dblclick). The status line below reads both
# straight off the event. Anything that depends on real browser trust — an `<a
# download>` in some browsers, a file picker — will not fire through this path; that is
# a platform restriction on synthetic clicks generally, not something this controller
# can route around.
#
# **The recursion trap.** Binding `click->cw--activate#activate` on the *same* element
# `activate` targets loops forever: the controller clicks the element, which re-fires
# the `click` listener, which clicks it again. Always trigger `activate` from a
# *different* event than the one it produces — `cw--intersection:entered` in the first
# scenario below, `mouseenter` in the second. Never `click` on the target itself.
#
# **Rule 0.** None — there is no platform primitive for "treat this other event as a
# click on that element."
class ActivatePreview < Lookbook::Preview
  # `intersection` + `activate` + a real link, the infinite-scroll recipe. Scroll the
  # box below; once the sentinel enters view, `activate` performs a real (but
  # synthetic) click on the nested "Load more" link.
  def default
    render_with_template(template: "activate_preview/default")
  end

  # `activate` triggered by `mouseenter` rather than a click on its own element —
  # deliberately a *different* event than the one it produces, per the recursion note
  # above. `target: nil` here means "click my own element," which only works because
  # the triggering event (`mouseenter`) is not `click`.
  def hover_trigger
    render_with_template(template: "activate_preview/hover_trigger")
  end
end
