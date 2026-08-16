# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::PersistHelper
  #   end
  #
  # `persist` is a behaviour, not a widget — it decorates an element you already own, so
  # it ships no partial, only the two standard forms.
  module PersistHelper
    # Build the attributes for an element `cw--persist` should decorate.
    #
    #   <input <%= cw_attrs(crosswire_persist_attrs(key: "search-filter")) %> type="text">
    #
    #   <details <%= cw_attrs(crosswire_persist_attrs(key: "faq-1-open", attribute: "open")) %>>
    #     …
    #   </details>
    def crosswire_persist_attrs(**options)
      Crosswire::Presenters::Persist.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    # `key:` is required and passed straight through to the presenter (which raises
    # if it's blank) — there is no sane default for the identity of a persisted value.
    #
    #   <%= crosswire_persist_for key: "faq-1-open", attribute: "open" do |p| %>
    #     <details <%= cw_attrs(p.root_attrs) %>>
    #       …
    #     </details>
    #   <% end %>
    def crosswire_persist_for(**options)
      yield Crosswire::Presenters::Persist.new(**options)
    end
  end
end
