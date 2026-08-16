# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::PopoverHelper
  #   end
  module PopoverHelper
    # Batteries-included form — renders the shipped partial.
    #
    #   <%= crosswire_popover "About this user", id: "user_card_42" do %>
    #     <p>Member since 2024.</p>
    #   <% end %>
    #
    # The partial is overridable by creating app/views/crosswire/_popover.html.erb,
    # or ejectable with `rails g crosswire:eject popover`. Remember Rule 0 (see
    # Crosswire::Presenters::Popover): for most popovers the native
    # `popovertarget`/`popover` attributes this renders are the ENTIRE mechanism —
    # `cw--popover` only adds placement fallback and programmatic control.
    def crosswire_popover(trigger_label, **options, &body)
      presenter = Crosswire::Presenters::Popover.new(**options)

      render("crosswire/popover",
             popover: presenter,
             trigger_label: trigger_label,
             body: capture(&body))
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_popover_for id: "user_card_42" do |p| %>
    #     <button <%= cw_attrs(p.trigger_attrs) %>>About</button>
    #     <div <%= cw_attrs(p.panel_attrs) %>>…</div>
    #   <% end %>
    def crosswire_popover_for(**options)
      yield Crosswire::Presenters::Popover.new(**options)
    end
  end
end
