# frozen_string_literal: true

# **What it is.** Drag-and-drop reordering that PATCHes the new order to the server,
# wrapping SortableJS. A *behaviour* — no markup, no partial.
#
# **What it composes from.** `Crosswire::Presenters::Sortable` emits `url` (required),
# `group`, `handle`, `param_name`, plus `item_attrs` (one per row — needs a real `id`)
# and the accessible fallback: `move_up_attrs`/`move_down_attrs`.
#
# **SortableJS is an OPTIONAL peer, not a dependency of this gem — and this dummy app
# does not have it pinned.** Open dev tools on this preview and you will see the
# controller's own console warning that `window.Sortable` was not found; drag-and-drop
# is disabled here as a direct, honest consequence. What this preview demonstrates
# instead is the part that is **first-class, not a degraded fallback**: the keyboard
# "Move up"/"Move down" buttons below need nothing but `fetch`, work with zero
# SortableJS present, and drive the *identical* reorder-and-persist code path a real drag
# would.
#
# **Native drag-and-drop is not keyboard- or screen-reader-operable, and wrapping it in
# SortableJS does not change that.** There is no ARIA that fixes it — the WAI-ARIA APG
# has no drag-and-drop-reordering pattern, because pointer dragging is not the accessible
# mechanism to begin with. That is why `move_up_attrs`/`move_down_attrs` are required
# presenter methods, not something left for a consumer to improvise.
#
# The PATCH target below (`/sortable_demo`, a route added to this dummy app for this
# preview) actually responds, so moving an item persists and stays — a Lookbook preview
# with no live backend at all would instead show the honest failure/revert path (see the
# controller's `#persist`/`#revert`), which is correct behaviour but a worse first look
# at the component.
#
# **Rule 0.** Native `draggable="true"` + HTML5 DnD exist but are a poor fit on their own
# merits (no ghost/animation/scroll handling, inconsistent touch support) — a wrapped
# library earns its place for the pointer path. What Rule 0 actually buys here is the
# keyboard fallback: reordering itself has no zero-JS answer, but the accessible path is
# plain buttons and needs no library at all.
class SortablePreview < Lookbook::Preview
  # @param param_name text "Form-field name the new order is PATCHed under"
  def default(param_name: "position")
    render_with_template(
      template: "sortable_preview/default",
      locals: {param_name: param_name}
    )
  end
end
