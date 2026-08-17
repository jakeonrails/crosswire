# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.click_outside_for`,
  # `cw.click_outside_attrs` (and `cw.click_outside` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `click-outside` is a behaviour, not a widget — it decorates an element you already
  # have, so it ships no batteries-included render form and no partial, only the two
  # standard forms.
  module ClickOutsideHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= cw.click_outside_for enabled: @menu_open do |c| %>
    #     <div <%= cw_attrs(c.root_attrs) %> data-action="cw--click-outside:clicked->cw--dismiss#dismiss">
    #       …
    #     </div>
    #   <% end %>
    def click_outside_for(**options, &block)
      capture(Crosswire::Presenters::ClickOutside.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <div <%= cw_attrs(cw.click_outside_attrs(enabled: @menu_open),
    #             data: { action: "cw--click-outside:clicked->cw--dismiss#dismiss" }) %>>
    #     …
    #   </div>
    def click_outside_attrs(**options)
      Crosswire::Presenters::ClickOutside.new(**options).root_attrs
    end
  end
end
