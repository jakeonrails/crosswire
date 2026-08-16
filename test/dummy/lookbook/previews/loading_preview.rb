# frozen_string_literal: true

# **What it is.** Mark an in-flight Turbo request with a bare `data-loading`
# attribute. A *behaviour* — no markup, no partial — scoped to whatever wraps the
# form/frame(s) it should watch.
#
# **What it composes from.** `Crosswire::Presenters::Loading` emits `delay` (the
# anti-flicker threshold) and `loading_class`, and wires `turbo:submit-start`/
# `turbo:before-fetch-request` to `start`, `turbo:submit-end`/`turbo:frame-render`/
# `turbo:fetch-request-error` to `stop`. Both scenarios below hit the SAME real,
# slow (`/survivability_demo/slow`, a route added to this dummy app for this
# preview — see `demo_controller.rb`) endpoint, so `data-loading` appears and clears
# against genuine Turbo events, not a simulated fetch.
#
# **Rule 0.** Turbo already sets `aria-busy="true"` on the form/frame it is
# submitting/loading, and `data-turbo-submits-with="Saving…"` swaps a submit
# button's own label for the duration — both for free, with no controller at all.
# `cw--loading` earns its keep for the SUBMITTER being marked separately from the
# form/frame, the anti-flicker delay, and the bare, Livewire-compatible attribute
# name Tailwind v4's `data-loading:` variants already understand.
class LoadingPreview < Lookbook::Preview
  # A `<turbo-frame>` reload and a `<form>` submission, scoped by ONE `cw--loading`
  # wrapping both — every Turbo fetch/submit event bubbles, so placement is entirely
  # the caller's call. Watch `data-loading` appear on the `<turbo-frame>` after the
  # 100ms anti-flicker delay while its 1.5s round trip is in flight, and on the
  # submit button (the SUBMITTER, separately from the form) when the form is
  # submitted.
  #
  # @param delay number "Anti-flicker threshold in ms before data-loading appears"
  def default(delay: 100)
    render_with_template(template: "loading_preview/default", locals: {delay: delay})
  end
end
