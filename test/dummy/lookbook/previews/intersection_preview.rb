# frozen_string_literal: true

# **What it is.** A declarative wrapper over `IntersectionObserver` that dispatches
# `cw--intersection:entered` / `:left` when an element scrolls into or out of view. A
# *behaviour* — no markup, no partial.
#
# **What it composes from.** `Crosswire::Presenters::Intersection` emits nothing but the
# observer's own options as Stimulus values (`threshold`, `once`, `root_margin`, `root`),
# so the controller is a thin, correctly-torn-down (R7) adapter. Everything downstream —
# infinite scroll, lazy loading, scrollspy, reveal-on-scroll — is *your* listener on the
# event, not a feature of this component.
#
# **Rule 0.** `loading="lazy"` on `<img>`/`<iframe>` and `content-visibility: auto`
# already handle most lazy-loading. Reach for this when you need to *do* something on
# entry: fetch the next page, mark a section read, start a video.
class IntersectionPreview < Lookbook::Preview
  # @param once toggle "Stop observing after the first entry"
  # @param threshold number "Fraction of the element that must be visible (0–1)"
  # @param root_margin text "Grow or shrink the root box — '200px' fires 200px early"
  def default(once: true, threshold: 0, root_margin: "0px")
    render_with_template(
      template: "intersection_preview/default",
      locals: {once: once, threshold: threshold, root_margin: root_margin}
    )
  end
end
