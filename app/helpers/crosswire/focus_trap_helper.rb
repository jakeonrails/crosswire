# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::FocusTrapHelper
  #   end
  #
  # `focus-trap` is a behaviour, not a widget — it decorates an element you already
  # have, so it ships no batteries-included render form and no partial, only the
  # `_for` attribute builder.
  #
  # Rule 0 lives on the presenter: skip this entirely for a native `<dialog>` opened
  # with `showModal()`; reach for it only for drawers, non-modal panels and toolbars.
  module FocusTrapHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_focus_trap_for active: @drawer_open, initial: "#drawer-heading" do |t| %>
    #     <div <%= cw_attrs(t.root_attrs) %>>
    #       <h2 id="drawer-heading" tabindex="-1">Filters</h2>
    #       …
    #     </div>
    #   <% end %>
    def crosswire_focus_trap_for(**options)
      yield Crosswire::Presenters::FocusTrap.new(**options)
    end
  end
end
