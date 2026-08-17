# frozen_string_literal: true

# **Rule 0, read this first.** The native Popover API (`popovertarget` on the trigger +
# `popover="auto"` on the panel) already gives you light-dismiss, Escape-to-close, and
# top-layer stacking — so the panel is never clipped by an `overflow: hidden` ancestor
# — with ZERO JavaScript. `Crosswire::Presenters::Popover` emits those attributes
# UNCONDITIONALLY, and CSS anchor positioning (`anchor-name`/`position-anchor`) handles
# placement with equally zero JavaScript on engines that support it, also emitted
# unconditionally. For a large share of popovers — tooltips, simple dropdowns, "About
# this user" cards — that native pair is the *entire* component; `cw--popover` adds
# nothing for them.
#
# **What `cw--popover` actually adds.** Only two things the platform doesn't yet give
# you everywhere: (1) placement FALLBACK — a small hand-written placement table, not a
# general-purpose positioning engine — on an engine without CSS anchor positioning, and
# (2) programmatic `show()`/`hide()`/`toggle()` control from other Stimulus code. If you
# need neither, you can eject this partial and delete the `data-controller` entirely;
# the `popovertarget`/`popover` attributes alone keep working.
#
# **Caution.** `popover` itself is "newly available" (MDN, 2026-08), not yet "widely
# available," and there is a live, unresolved Safari iOS bug where a popover cannot be
# dismissed by a touch outside it — verify light-dismiss there before shipping if you
# support iOS Safari.
class PopoverPreview < Lookbook::Preview
  # The shipped partial, via `cw.popover`. Trigger and panel are siblings, not
  # nested — `popovertarget`/`popover` is an attribute-level relationship the browser
  # resolves by id, so no shared wrapper is needed.
  #
  # @param placement select "~ [bottom-start, bottom-end, top-start, top-end, left-start, right-start]"
  # @param strategy select "~ [anchor, js]" "anchor: prefer native CSS anchor positioning, falling back automatically. js: always use the fallback positioner."
  def default(placement: "bottom-start", strategy: "anchor")
    render_with_template(
      template: "popover_preview/default",
      locals: {placement: placement, strategy: strategy}
    )
  end

  # `cw.popover_for` yields the presenter. Note there is no `root_attrs` at all
  # — unlike `dialog`/`tabs`, nothing here needs a common ancestor.
  def compose_your_own
    render_with_template(template: "popover_preview/compose_your_own")
  end
end
