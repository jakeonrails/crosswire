# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::AutosubmitHelper
  #   end
  module AutosubmitHelper
    # Batteries-included form — this behaviour owns no markup (see
    # docs/COMPONENT_CONTRACT.md), so there is nothing to render. Instead this returns
    # the attrs hash for `crosswire_autosubmit`'s presenter, ready to pass straight
    # into `cw_attrs` on whatever field element you already have.
    #
    #   <input <%= cw_attrs(crosswire_autosubmit(delay: 300), type: "search", name: "q") %>>
    def crosswire_autosubmit(**options)
      Crosswire::Presenters::Autosubmit.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <% crosswire_autosubmit_for(delay: 300, event: "change") do |a| %>
    #     <select <%= cw_attrs(a.root_attrs, name: "status") %>>
    #       ...
    #     </select>
    #   <% end %>
    def crosswire_autosubmit_for(**options)
      yield Crosswire::Presenters::Autosubmit.new(**options)
    end
  end
end
