# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.persist_for`,
  # `cw.persist_attrs` (and `cw.persist` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `persist` is a behaviour, not a widget — it decorates an element you already own, so
  # it ships no partial, only the two standard forms.
  module PersistHelper
    # Build the attributes for an element `cw--persist` should decorate.
    #
    #   <input <%= cw_attrs(cw.persist_attrs(key: "search-filter")) %> type="text">
    #
    #   <details <%= cw_attrs(cw.persist_attrs(key: "faq-1-open", attribute: "open")) %>>
    #     …
    #   </details>
    def persist_attrs(**options)
      Crosswire::Presenters::Persist.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    # `key:` is required and passed straight through to the presenter (which raises
    # if it's blank) — there is no sane default for the identity of a persisted value.
    #
    #   <%= cw.persist_for key: "faq-1-open", attribute: "open" do |p| %>
    #     <details <%= cw_attrs(p.root_attrs) %>>
    #       …
    #     </details>
    #   <% end %>
    def persist_for(**options, &block)
      capture(Crosswire::Presenters::Persist.new(**options), &block)
    end
  end
end
