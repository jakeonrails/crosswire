# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.disclosure_for`,
  # `cw.disclosure_attrs` (and `cw.disclosure` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  module DisclosureHelper
    # Batteries-included form — renders the shipped partial.
    #
    #   <%= cw.disclosure "Shipping details", id: "shipping" do %>
    #     <p>Arrives in 3–5 days.</p>
    #   <% end %>
    #
    # The partial is overridable by creating app/views/crosswire/_disclosure.html.erb,
    # or ejectable with `rails g crosswire:eject disclosure`. Accessibility comes from
    # the presenter, so a restyled copy stays correct.
    def disclosure(summary = nil, **options, &panel)
      presenter = Crosswire::Presenters::Disclosure.new(**options)

      # The block is genuinely optional (a disclosure whose panel content is rendered
      # elsewhere, or is empty until a Turbo Frame fills it). `capture(&nil)` yields
      # with no block and raises LocalJumpError, so guard rather than assume.
      render("crosswire/disclosure",
             disclosure: presenter,
             summary: summary,
             panel: (capture(&panel) if panel))
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.disclosure_for id: "faq-1" do |d| %>
    #     <div <%= cw_attrs(d.root_attrs) %>>
    #       <%= tag.button "Details", **d.trigger_attrs %>
    #       <%= tag.div(**d.panel_attrs) { "…" } %>
    #     </div>
    #   <% end %>
    def disclosure_for(**options, &block)
      capture(Crosswire::Presenters::Disclosure.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <div <%= cw_attrs(cw.disclosure_attrs(id: "faq-1"), class: "faq") %>>
    #     …
    #   </div>
    def disclosure_attrs(**options)
      Crosswire::Presenters::Disclosure.new(**options).root_attrs
    end
  end
end
