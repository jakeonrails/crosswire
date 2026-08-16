# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::AutosubmitHelper
  #   end
  #
  # `autosubmit` is a behaviour, not a widget — it decorates a field you already have,
  # so it ships no batteries-included render form and no partial, only the two
  # standard forms.
  module AutosubmitHelper
    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.input(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <input <%= cw_attrs(crosswire_autosubmit_attrs(delay: 300), type: "search", name: "q") %>>
    def crosswire_autosubmit_attrs(**options)
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
