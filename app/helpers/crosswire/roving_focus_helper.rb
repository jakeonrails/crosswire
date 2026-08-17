# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.roving_focus_for`,
  # `cw.roving_focus_attrs` (and `cw.roving_focus` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `roving-focus` is a behaviour, not a widget — it decorates a set of `item`
  # targets you already have, so it ships no batteries-included render form and no
  # partial, only the two standard forms.
  module RovingFocusHelper
    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.roving_focus_for orientation: "horizontal" do |r| %>
    #     <div <%= cw_attrs(r.root_attrs) %>>
    #       <% items.each_with_index do |item, i| %>
    #         <button <%= cw_attrs(r.item_attrs(current: i.zero?)) %>><%= item %></button>
    #       <% end %>
    #     </div>
    #   <% end %>
    def roving_focus_for(**options, &block)
      capture(Crosswire::Presenters::RovingFocus.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <div <%= cw_attrs(cw.roving_focus_attrs(orientation: "horizontal")) %>>
    #     …
    #   </div>
    def roving_focus_attrs(**options)
      Crosswire::Presenters::RovingFocus.new(**options).root_attrs
    end
  end
end
