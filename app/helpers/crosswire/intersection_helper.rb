# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.intersection_for`,
  # `cw.intersection_attrs` (and `cw.intersection` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `intersection` is a behaviour, not a widget — it decorates an element you already
  # have, so it ships no batteries-included render form and no partial, only the two
  # standard forms.
  module IntersectionHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= cw.intersection_for once: true, root_margin: "200px" do |i| %>
    #     <div <%= cw_attrs(i.root_attrs) %> data-action="cw--intersection:entered->gallery#loadMore">
    #       Loading more…
    #     </div>
    #   <% end %>
    def intersection_for(**options, &block)
      capture(Crosswire::Presenters::Intersection.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <div <%= cw_attrs(cw.intersection_attrs(once: true, root_margin: "200px"),
    #             data: { action: "cw--intersection:entered->gallery#loadMore" }) %>>
    #     Loading more…
    #   </div>
    def intersection_attrs(**options)
      Crosswire::Presenters::Intersection.new(**options).root_attrs
    end
  end
end
