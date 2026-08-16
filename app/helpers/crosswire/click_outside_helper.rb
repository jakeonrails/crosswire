# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::ClickOutsideHelper
  #   end
  #
  # `click-outside` is a behaviour, not a widget — it decorates an element you already
  # have, so it ships no batteries-included render form and no partial, only the two
  # standard forms.
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

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <div <%= cw_attrs(crosswire_click_outside_attrs(enabled: @menu_open),
    #             data: { action: "cw--click-outside:clicked->cw--dismiss#dismiss" }) %>>
    #     …
    #   </div>
    def crosswire_click_outside_attrs(**options)
      Crosswire::Presenters::ClickOutside.new(**options).root_attrs
    end
  end
end
