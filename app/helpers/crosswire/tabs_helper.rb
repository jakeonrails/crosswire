# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.tabs_for`,
  # `cw.tabs_attrs` (and `cw.tabs` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  module TabsHelper
    # Batteries-included form — renders the shipped partial.
    #
    #   <%= cw.tabs id: "settings", selected: "profile",
    #         tabs: [{ id: "profile", label: "Profile" }, { id: "billing", label: "Billing" }] do |tab_id| %>
    #     <% if tab_id == "profile" %>
    #       <p>Profile fields…</p>
    #     <% else %>
    #       <p>Billing fields…</p>
    #     <% end %>
    #   <% end %>
    #
    # `tabs:` is an ordered array of `{ id:, label: }` hashes. The block is called
    # once per tab (via `capture`) with that tab's id, and its return value becomes
    # that tab's panel content — this is what lets one helper call render every
    # panel without a separate method per tab.
    #
    # The partial is overridable by creating app/views/crosswire/_tabs.html.erb, or
    # ejectable with `rails g crosswire:eject tabs`. Accessibility comes from the
    # presenter, so a restyled copy stays correct.
    def tabs(id:, selected:, tabs:, **options, &panel_content)
      presenter = Crosswire::Presenters::Tabs.new(id: id, selected: selected, **options)

      panels = tabs.map do |tab|
        tab_id = tab.fetch(:id).to_s
        { id: tab_id, label: tab.fetch(:label), body: capture(tab_id, &panel_content) }
      end

      render("crosswire/tabs", tabs: presenter, panels: panels)
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.tabs_for id: "settings", selected: @tab do |t| %>
    #     <div <%= cw_attrs(t.root_attrs) %>>
    #       <div <%= cw_attrs(t.tablist_attrs) %>>
    #         <button <%= cw_attrs(t.tab_attrs(tab_id: "profile")) %>>Profile</button>
    #         <button <%= cw_attrs(t.tab_attrs(tab_id: "billing")) %>>Billing</button>
    #       </div>
    #       <div <%= cw_attrs(t.panel_attrs(tab_id: "profile")) %>>…</div>
    #       <div <%= cw_attrs(t.panel_attrs(tab_id: "billing")) %>>…</div>
    #     </div>
    #   <% end %>
    #
    # The root element must wrap the tablist AND every panel — see
    # Crosswire::Presenters::Tabs#root_attrs.
    def tabs_for(**options, &block)
      capture(Crosswire::Presenters::Tabs.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    # The root element must wrap the tablist AND every panel — see
    # Crosswire::Presenters::Tabs#root_attrs.
    #
    #   <div <%= cw_attrs(cw.tabs_attrs(id: "settings", selected: @tab)) %>>
    #     …
    #   </div>
    def tabs_attrs(**options)
      Crosswire::Presenters::Tabs.new(**options).root_attrs
    end
  end
end
