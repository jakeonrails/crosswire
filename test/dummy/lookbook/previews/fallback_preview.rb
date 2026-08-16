# frozen_string_literal: true

# **What it is.** A tri-state (`"ok"` | `"loading"` | `"failed"`) indicator for the
# failure Turbo has no answer to: a lazy `<turbo-frame>` whose endpoint 500s just sits
# there showing its placeholder forever. A *behaviour* — no markup, no partial.
#
# **What it composes from.** `Crosswire::Presenters::Fallback` emits `state`
# (rendered server-side, R4) and `failed_class`, plus `loading_attrs`/`failed_attrs`/
# `source_attrs` for the three regions. The frame below is lazy-loaded against
# `/survivability_demo/fail` — a route added to this dummy app for this preview that
# ALWAYS returns a genuine 500 — so the failed state below comes from a real Turbo
# `turbo:before-fetch-response` with `fetchResponse.succeeded == false`, not a
# simulated one.
#
# **Rule 0.** For "is this request taking a while," prefer `cw--loading` (or Turbo's
# own `aria-busy`/`data-turbo-submits-with`) — see that preview. This one exists
# specifically for the genuinely absent failure state.
class FallbackPreview < Lookbook::Preview
  # Starts `state: "loading"` (rendered server-side, correct before JavaScript ever
  # boots — this is what a lazy frame's wrapper should render) and moves to
  # `"failed"` once the real 500 comes back. Click Retry to watch it fail again
  # against the same broken endpoint, or the link below to point the frame at a
  # working one instead and watch `cw--fallback:recovered` fire.
  def default
    render_with_template(template: "fallback_preview/default")
  end
end
