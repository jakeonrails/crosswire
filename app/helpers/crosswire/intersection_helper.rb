# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::IntersectionHelper
  #   end
  #
  # `intersection` is a behaviour, not a widget — it decorates an element you already
  # have, so it ships no batteries-included render form and no partial, only the two
  # standard forms.
  module IntersectionHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_intersection_for once: true, root_margin: "200px" do |i| %>
    #     <div <%= cw_attrs(i.root_attrs) %> data-action="cw--intersection:entered->gallery#loadMore">
    #       Loading more…
    #     </div>
    #   <% end %>
    def crosswire_intersection_for(**options, &block)
      capture(Crosswire::Presenters::Intersection.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <div <%= cw_attrs(crosswire_intersection_attrs(once: true, root_margin: "200px"),
    #             data: { action: "cw--intersection:entered->gallery#loadMore" }) %>>
    #     Loading more…
    #   </div>
    def crosswire_intersection_attrs(**options)
      Crosswire::Presenters::Intersection.new(**options).root_attrs
    end
  end
end
