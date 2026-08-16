# frozen_string_literal: true

# **What it is.** Protect specific attributes — or a whole subtree — from Turbo 8
# morphing. A *behaviour*: no markup of its own, stacked onto an element you already
# have. See `crosswire/morph`'s `usePreserve` for the controller-owned surface this
# one complements (that surface is for controllers you own; this one — `cw--preserve`
# — is the markup-driven escape hatch for controllers you don't).
#
# **What it composes from.** `Crosswire::Presenters::Preserve` emits `attributes`
# (space-separated attribute names) and/or `element` (Boolean, full-subtree opt-out) as
# Stimulus values. The controller records each watched attribute's value the moment it
# connects, and on every subsequent morph cancels only the ones that have actually
# diverged since — an attribute nothing ever wrote stays the server's to update.
#
# **The seam worth studying** is `default`: it drives a REAL morph via
# `@hotwired/turbo`'s exported `morphElements(current, stale)`, not a simulated one —
# see morph.js's docstring for why crosswire itself never imports Turbo at runtime, and
# note this Lookbook preview is a dev/test-only exception, wired through the dummy
# app's own importmap.
#
# **Rule 0.** Prefer persisting the state server-side first (Radan Skorić's "family
# 3") — this exists for state the server genuinely does not know, or for attributes a
# controller you do not own writes at runtime.
class PreservePreview < Lookbook::Preview
  # Two identical boxes, started from the same server-rendered markup. Toggle either
  # one (simulating a controller — yours, or a third party's — writing its own
  # runtime state), then "simulate morph" against markup identical to what each box
  # was rendered with originally. The left box has no protection and reverts to the
  # stale `aria-expanded="false"`; the right box has `cw--preserve` watching
  # `aria-expanded` and keeps whatever it was last set to.
  def default
    render_with_template(template: "preserve_preview/default")
  end
end
