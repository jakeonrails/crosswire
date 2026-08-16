# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::RovingFocusHelper
  #   end
  #
  # `roving-focus` is a behaviour, not a widget — it decorates a set of `item`
  # targets you already have, so it ships no batteries-included render form and no
  # partial, only the `_for` attribute builder.
  module RovingFocusHelper
    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_roving_focus_for orientation: "horizontal" do |r| %>
    #     <div <%= cw_attrs(r.root_attrs) %>>
    #       <% items.each_with_index do |item, i| %>
    #         <button <%= cw_attrs(r.item_attrs(current: i.zero?)) %>><%= item %></button>
    #       <% end %>
    #     </div>
    #   <% end %>
    def crosswire_roving_focus_for(**options)
      yield Crosswire::Presenters::RovingFocus.new(**options)
    end
  end
end
