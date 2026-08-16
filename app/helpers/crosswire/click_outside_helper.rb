# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::ClickOutsideHelper
  #   end
  #
  # `click-outside` is a behaviour, not a widget — it decorates an element you already
  # have, so it ships no batteries-included render form and no partial, only the `_for`
  # attribute builder.
  module ClickOutsideHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_click_outside_for enabled: @menu_open do |c| %>
    #     <div <%= cw_attrs(c.root_attrs) %> data-action="cw--click-outside:clicked->cw--dismiss#dismiss">
    #       …
    #     </div>
    #   <% end %>
    def crosswire_click_outside_for(**options)
      yield Crosswire::Presenters::ClickOutside.new(**options)
    end
  end
end
