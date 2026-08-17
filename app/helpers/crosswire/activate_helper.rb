# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.activate_for`,
  # `cw.activate_attrs` (and `cw.activate` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `activate` is a behaviour, not a widget — it decorates whatever element(s)
  # it is stacked onto or scoped near, so it ships no batteries-included render
  # form and no partial, only the two standard forms.
  module ActivateHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= cw.activate_for target: "#load_more" do |a| %>
    #     <div <%= cw_attrs(cw.intersection_attrs, a.root_attrs) %>
    #          data-action="cw--intersection:entered->cw--activate#activate">
    #       <%= link_to "Load more", next_page_path, id: "load_more" %>
    #     </div>
    #   <% end %>
    def activate_for(**options, &block)
      capture(Crosswire::Presenters::Activate.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for
    # `cw_attrs` or `tag.div(**...)`. Renders and escapes nothing itself; that
    # is `cw_attrs`' job.
    #
    #   <div <%= cw_attrs(cw.activate_attrs(target: "#load_more"),
    #             data: { action: "cw--intersection:entered->cw--activate#activate" }) %>>
    #   </div>
    def activate_attrs(**options)
      Crosswire::Presenters::Activate.new(**options).root_attrs
    end
  end
end
