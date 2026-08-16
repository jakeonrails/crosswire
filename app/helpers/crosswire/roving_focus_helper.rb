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
  # partial, only the two standard forms.
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
    def crosswire_roving_focus_for(**options, &block)
      capture(Crosswire::Presenters::RovingFocus.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <div <%= cw_attrs(crosswire_roving_focus_attrs(orientation: "horizontal")) %>>
    #     …
    #   </div>
    def crosswire_roving_focus_attrs(**options)
      Crosswire::Presenters::RovingFocus.new(**options).root_attrs
    end
  end
end
