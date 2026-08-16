# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::TimeoutHelper
  #   end
  #
  # `timeout` is a behaviour, not a widget — it decorates an element you already have,
  # so it ships no batteries-included render form and no partial, only the `_for`
  # attribute builder.
  module TimeoutHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_timeout_for delay: 8000 do |t| %>
    #     <div <%= cw_attrs(t.root_attrs) %>
    #          data-action="cw--timeout:elapsed->cw--dismiss#dismiss
    #                       mouseenter->cw--timeout#cancel
    #                       mouseleave->cw--timeout#restart">
    #       …
    #     </div>
    #   <% end %>
    def crosswire_timeout_for(**options)
      yield Crosswire::Presenters::Timeout.new(**options)
    end
  end
end
