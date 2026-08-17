# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.sortable_for`,
  # `cw.sortable_attrs` (and `cw.sortable` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `sortable` is a behaviour, not a widget — it decorates a list you already have,
  # so it ships no batteries-included render form and no partial, only the two
  # standard forms. SortableJS itself is an optional peer, never a dependency of
  # this gem — see `Crosswire::Presenters::Sortable` and the controller docstring.
  module SortableHelper
    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.sortable_for url: reorder_items_path(@list) do |s| %>
    #     <ul <%= cw_attrs(s.root_attrs) %>>
    #       <% @list.items.each do |item| %>
    #         <li <%= cw_attrs(s.item_attrs(id: dom_id(item))) %>>
    #           <%= item.name %>
    #           <button <%= cw_attrs(s.move_up_attrs(disabled: item == @list.items.first)) %>>&uarr;</button>
    #           <button <%= cw_attrs(s.move_down_attrs(disabled: item == @list.items.last)) %>>&darr;</button>
    #         </li>
    #       <% end %>
    #     </ul>
    #   <% end %>
    def sortable_for(**options, &block)
      capture(Crosswire::Presenters::Sortable.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <ul <%= cw_attrs(cw.sortable_attrs(url: reorder_items_path(@list))) %>>
    #     …
    #   </ul>
    def sortable_attrs(**options)
      Crosswire::Presenters::Sortable.new(**options).root_attrs
    end
  end
end
