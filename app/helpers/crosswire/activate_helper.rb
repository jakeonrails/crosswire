# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::ActivateHelper
  #   end
  #
  # `activate` is a behaviour, not a widget — it decorates whatever element(s)
  # it is stacked onto or scoped near, so it ships no batteries-included render
  # form and no partial, only the two standard forms.
  module ActivateHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_activate_for target: "#load_more" do |a| %>
    #     <div <%= cw_attrs(crosswire_intersection_attrs, a.root_attrs) %>
    #          data-action="cw--intersection:entered->cw--activate#activate">
    #       <%= link_to "Load more", next_page_path, id: "load_more" %>
    #     </div>
    #   <% end %>
    def crosswire_activate_for(**options)
      yield Crosswire::Presenters::Activate.new(**options)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for
    # `cw_attrs` or `tag.div(**...)`. Renders and escapes nothing itself; that
    # is `cw_attrs`' job.
    #
    #   <div <%= cw_attrs(crosswire_activate_attrs(target: "#load_more"),
    #             data: { action: "cw--intersection:entered->cw--activate#activate" }) %>>
    #   </div>
    def crosswire_activate_attrs(**options)
      Crosswire::Presenters::Activate.new(**options).root_attrs
    end
  end
end
