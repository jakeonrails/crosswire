# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.loading_for`,
  # `cw.loading_attrs` (and `cw.loading` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `loading` is a behaviour, not a widget — it decorates a scope you already have (a
  # form, a `<turbo-frame>`, a table row, `<body>`), so it ships no partial and there
  # is nothing to build a `_for` form's block around beyond the presenter itself.
  module LoadingHelper
    # Build the attributes for the scope `cw--loading` should watch. Returns a plain
    # Hash, ready for `cw_attrs` or `tag.form(**...)`; renders and escapes nothing
    # itself.
    #
    #   <%= form_with model: @order, **cw_attrs(cw.loading_attrs) do |f| %>
    #     <%= f.submit "Place order" %>
    #   <% end %>
    #
    #   <%# style off the bare, Livewire-compatible attribute — ships no CSS: %>
    #   <style>[data-loading] { opacity: 0.6; }</style>
    def loading_attrs(**options)
      Crosswire::Presenters::Loading.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.loading_for(delay: 200) do |l| %>
    #     <turbo-frame id="results" src="<%= results_path %>" <%= cw_attrs(l.root_attrs) %>>
    #     </turbo-frame>
    #   <% end %>
    def loading_for(**options, &block)
      capture(Crosswire::Presenters::Loading.new(**options), &block)
    end
  end
end
