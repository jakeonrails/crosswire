# frozen_string_literal: true

# **What it is.** Lock document scroll while active. A *behaviour* — no markup, no
# partial — that always applies to `document.documentElement`/`document.body`, never
# to its own element; there is nothing element-scoped about "the page can't scroll."
#
# **What it composes from.** `Crosswire::Presenters::ScrollLock` emits a single
# `active` value; the controller reference-counts its lock at MODULE scope (not per
# instance) so two stacked lockers — a dialog opened from inside an already-locked
# drawer — don't have the inner one's release re-enable page scroll while the outer is
# still active. Typically stacked on the same element as `cw--dialog` or a drawer's own
# controller, with `active` driven by whichever of them owns the open/closed state —
# `cw--dialog` already does this internally, so this preview shows the primitive on its
# own, driven by a plain toggle button instead.
#
# **Rule 0.** There isn't one. `<dialog>.showModal()` does not lock document scroll
# (whatwg/html#7732, open since 2022) — this is the rare crosswire primitive with no
# platform feature to defer to.
class ScrollLockPreview < Lookbook::Preview
  # Toggle the lock and try scrolling the page behind this frame.
  def default
    render_with_template(template: "scroll_lock_preview/default")
  end
end
