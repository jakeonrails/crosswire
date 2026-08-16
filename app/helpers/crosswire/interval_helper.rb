# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::IntervalHelper
  #   end
  #
  # `interval` is a behaviour, not a widget — it decorates an element you already
  # have, so it ships no batteries-included render form and no partial, only the
  # two standard forms.
  module IntervalHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_interval_for ms: 5000 do |i| %>
    #     <turbo-frame id="job_status" src="<%= job_status_path %>">
    #       <div <%= cw_attrs(i.root_attrs) %>
    #            data-action="cw--interval:tick->job_status#reload"></div>
    #     </turbo-frame>
    #   <% end %>
    def crosswire_interval_for(**options)
      yield Crosswire::Presenters::Interval.new(**options)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs`
    # or `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`'
    # job. `ms:` is required and passed straight through to the presenter.
    #
    #   <div <%= cw_attrs(crosswire_interval_attrs(ms: 5000),
    #             data: { action: "cw--interval:tick->job_status#reload" }) %>>
    #   </div>
    def crosswire_interval_attrs(**options)
      Crosswire::Presenters::Interval.new(**options).root_attrs
    end
  end
end
