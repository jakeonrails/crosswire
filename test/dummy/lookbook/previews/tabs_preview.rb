# frozen_string_literal: true

# **What it is.** Full tablist/tab/tabpanel roles — WAI-ARIA APG Tabs — for panels that
# are all pre-rendered and must switch instantly with no round trip.
#
# **What it composes from.** This is the reference example of R5a: `cw--tabs` STACKS on
# top of `cw--roving-focus` on a shared root element
# (`data-controller="cw--roving-focus cw--tabs"`) rather than reimplementing arrow-key
# navigation — every `tab` is ALSO a roving-focus `item`, so Left/Right/Home/End and
# the roving `tabindex` bookkeeping come from `cw--roving-focus` entirely for free.
# `cw--tabs` itself owns only `aria-selected`, panel visibility, and the optional URL
# sync. The "compose your own" scenario below renders that stacking explicitly — there
# is no wrapper hiding it.
#
# **Rule 0 note.** This is NOT the zero-JS answer the way `disclosure`/`dialog`/
# `popover` are — there is no native tabs element. If panels are cheap, server-rendered
# HTML swapped over the network on each click, prefer `cw--roving-focus` alone with a
# real `<a href>` per tab and a `<turbo-frame>` supplying `aria-selected` server-side on
# every navigation instead (research/notes/08, tier (b)). Reach for this presenter —
# tier (c) — only when panels are small, already on the page, and must switch with zero
# latency, which is also why its default `activation` is "automatic".
class TabsPreview < Lookbook::Preview
  # The shipped partial, via `crosswire_tabs`. `tabs:` is an ordered array of
  # `{ id:, label: }`; the block is called once per tab (via `capture`) to render that
  # tab's panel content.
  #
  # @param selected select "~ [profile, billing, danger]"
  # @param activation select "~ [automatic, manual]" "Automatic: arrow keys select immediately. Manual: arrow keys move focus only, Enter/Space selects."
  def default(selected: "profile", activation: "automatic")
    render_with_template(
      template: "tabs_preview/default",
      locals: {selected: selected, activation: activation}
    )
  end

  # `crosswire_tabs_for` yields the presenter and renders none of our markup. The root
  # `<div>` below carries `data-controller="cw--roving-focus cw--tabs"` — both
  # controllers stacked on one element, exactly what `Crosswire::Presenters::Tabs#root_attrs`
  # builds, visible here with nothing hidden inside a partial.
  def compose_your_own
    render_with_template(template: "tabs_preview/compose_your_own")
  end
end
