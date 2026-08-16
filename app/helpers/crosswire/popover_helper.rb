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

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    # `popover` has no single element wrapping trigger+panel (see the presenter
    # docstring: `popovertarget`/`popover` link the two by id, with no shared
    # ancestor required) and the controller lives entirely on the panel, so this is
    # `Presenters::Popover#panel_attrs` rather than a `root_attrs`. You still need
    # to render the trigger yourself with `crosswire_popover_for`'s `trigger_attrs`.
    #
    #   <div <%= cw_attrs(crosswire_popover_attrs(id: "user_card_42")) %>>…</div>
    def crosswire_popover_attrs(**options)
      Crosswire::Presenters::Popover.new(**options).panel_attrs
    end
  end
end
