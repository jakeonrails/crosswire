# frozen_string_literal: true

# **What it is.** A checkbox group with select-all, `indeterminate` state, a live count,
# and toolbar enable/disable — a table of rows, a list of cards. A *behaviour* — no
# markup, no partial.
#
# **What it composes from.** `Crosswire::Presenters::Selection` owns four elements'
# attributes — `all_attrs` (the header checkbox), `item_attrs` (one per row),
# `count_attrs` (a live-announced output) and `action_attrs` (toolbar controls, disabled
# by default since a fresh page load has nothing selected — R4). Turbo Stream rows are
# handled for free: the controller wires `itemTargetConnected`/`itemTargetDisconnected`
# to recompute everything as targets come and go, no re-init required.
#
# **The detail everyone gets wrong.** `indeterminate` is a DOM *property*, not an HTML
# attribute — `<input indeterminate>` does nothing, and because it is never serialised
# into markup it does **not** survive a Turbo morph or a bfcache restore. There is no
# server-rendered fallback for it the way `open` or `selected` have elsewhere in this
# library. The scenario below starts two of three rows `checked` — a real attribute, so
# that much is correct before any JS runs — and lets the controller derive
# `indeterminate` itself on `connect()`. Reload the preview: the select-all box renders
# plain-checked from the server-side markup for an instant, then flips to the
# dashed/indeterminate look the moment `cw--selection` connects, because two of three
# rows being checked is a state the server literally cannot express through the
# select-all checkbox's own markup.
#
# **Rule 0.** `indeterminate` itself is native; a native "select-all checkbox group"
# element is not. The coordination between one header checkbox, N row checkboxes, a live
# count and a toolbar is exactly what this primitive supplies.
class SelectionPreview < Lookbook::Preview
  def default
    render_with_template(template: "selection_preview/default")
  end
end
