# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::TimeoutHelper
  #   end
  #
  # `timeout` is a behaviour, not a widget — it decorates an element you already have,
  # so it ships no batteries-included render form and no partial, only the two
  # standard forms.
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
    def crosswire_timeout_for(**options, &block)
      capture(Crosswire::Presenters::Timeout.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    # `delay:` is required and passed straight through to the presenter.
    #
    #   <div <%= cw_attrs(crosswire_timeout_attrs(delay: 8000),
    #             data: { action: "cw--timeout:elapsed->cw--dismiss#dismiss" }) %>>
    #     …
    #   </div>
    def crosswire_timeout_attrs(**options)
      Crosswire::Presenters::Timeout.new(**options).root_attrs
    end
  end
end
