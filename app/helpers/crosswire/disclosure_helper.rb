# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::DisclosureHelper
  #   end
  module DisclosureHelper
    # Batteries-included form — renders the shipped partial.
    #
    #   <%= crosswire_disclosure "Shipping details", id: "shipping" do %>
    #     <p>Arrives in 3–5 days.</p>
    #   <% end %>
    #
    # The partial is overridable by creating app/views/crosswire/_disclosure.html.erb,
    # or ejectable with `rails g crosswire:eject disclosure`. Accessibility comes from
    # the presenter, so a restyled copy stays correct.
    def crosswire_disclosure(summary = nil, **options, &panel)
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
    #   <%= crosswire_disclosure_for id: "faq-1" do |d| %>
    #     <div <%= cw_attrs(d.root_attrs) %>>
    #       <%= tag.button "Details", **d.trigger_attrs %>
    #       <%= tag.div(**d.panel_attrs) { "…" } %>
    #     </div>
    #   <% end %>
    def crosswire_disclosure_for(**options)
      yield Crosswire::Presenters::Disclosure.new(**options)
    end
  end
end
