# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.preserve_for`,
  # `cw.preserve_attrs` (and `cw.preserve` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `preserve` is a behaviour, not a widget — it decorates an element you already have
  # (typically one already carrying a DIFFERENT controller you do not own), so it ships
  # no partial, only the two standard forms.
  module PreserveHelper
    # Build the attributes for the element `cw--preserve` should decorate. Stack it
    # alongside the controller that actually owns the element:
    #
    #   <div <%= cw_attrs({data: {controller: "tom-select"}},
    #             cw.preserve_attrs(attributes: "data-selected")) %>>
    #
    # Or exempt the whole subtree from morphing (B6 — like `data-turbo-permanent`, but
    # scoped to morph passes only):
    #
    #   <div <%= cw_attrs({data: {controller: "leaflet-map"}},
    #             cw.preserve_attrs(element: true)) %>>
    def preserve_attrs(**options)
      Crosswire::Presenters::Preserve.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.preserve_for attributes: "data-selected" do |p| %>
    #     <div <%= cw_attrs({data: {controller: "tom-select"}}, p.root_attrs) %>>
    #       …
    #     </div>
    #   <% end %>
    def preserve_for(**options, &block)
      capture(Crosswire::Presenters::Preserve.new(**options), &block)
    end
  end
end
