# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::PersistHelper
  #   end
  #
  # `persist` is a behaviour, not a widget — it decorates an element you already own, so
  # it ships no partial. This helper exposes only an attribute builder, in the spirit of
  # `Crosswire::DisclosureHelper#crosswire_disclosure_for`.
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
  end
end
