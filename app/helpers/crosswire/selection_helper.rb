# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.selection_for`,
  # `cw.selection_attrs` (and `cw.selection` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `selection` is a behaviour, not a widget — it decorates checkboxes and a
  # toolbar you already have (a table of rows, a list of cards), so it ships no
  # batteries-included render form and no partial, only the two standard forms.
  module SelectionHelper
    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.selection_for do |s| %>
    #     <div <%= cw_attrs(s.root_attrs) %>>
    #       <table>
    #         <thead>
    #           <tr>
    #             <th><input type="checkbox" <%= cw_attrs(s.all_attrs, aria: { label: "Select all" }) %>></th>
    #           </tr>
    #         </thead>
    #         <tbody>
    #           <% posts.each do |post| %>
    #             <tr>
    #               <td><input type="checkbox" name="ids[]" value="<%= post.id %>"
    #                          <%= cw_attrs(s.item_attrs, aria: { label: "Select #{post.title}" }) %>></td>
    #             </tr>
    #           <% end %>
    #         </tbody>
    #       </table>
    #
    #       <output <%= cw_attrs(s.count_attrs) %>></output>
    #
    #       <button type="button" <%= cw_attrs(s.action_attrs) %>>Archive</button>
    #     </div>
    #   <% end %>
    def selection_for(**options, &block)
      capture(Crosswire::Presenters::Selection.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <div <%= cw_attrs(cw.selection_attrs) %>>
    #     …
    #   </div>
    def selection_attrs(**options)
      Crosswire::Presenters::Selection.new(**options).root_attrs
    end
  end
end
