# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::SelectionHelper
  #   end
  #
  # `selection` is a behaviour, not a widget — it decorates checkboxes and a
  # toolbar you already have (a table of rows, a list of cards), so it ships no
  # batteries-included render form and no partial, only the two standard forms.
  module SelectionHelper
    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_selection_for do |s| %>
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
    def crosswire_selection_for(**options)
      yield Crosswire::Presenters::Selection.new(**options)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <div <%= cw_attrs(crosswire_selection_attrs) %>>
    #     …
    #   </div>
    def crosswire_selection_attrs(**options)
      Crosswire::Presenters::Selection.new(**options).root_attrs
    end
  end
end
