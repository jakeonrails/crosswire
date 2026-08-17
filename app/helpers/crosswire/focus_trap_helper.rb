# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.focus_trap_for`,
  # `cw.focus_trap_attrs` (and `cw.focus_trap` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `focus-trap` is a behaviour, not a widget — it decorates an element you already
  # have, so it ships no batteries-included render form and no partial, only the two
  # standard forms.
  #
  # Rule 0 lives on the presenter: skip this entirely for a native `<dialog>` opened
  # with `showModal()`; reach for it only for drawers, non-modal panels and toolbars.
  module FocusTrapHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= cw.focus_trap_for active: @drawer_open, initial: "#drawer-heading" do |t| %>
    #     <div <%= cw_attrs(t.root_attrs) %>>
    #       <h2 id="drawer-heading" tabindex="-1">Filters</h2>
    #       …
    #     </div>
    #   <% end %>
    def focus_trap_for(**options, &block)
      capture(Crosswire::Presenters::FocusTrap.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <div <%= cw_attrs(cw.focus_trap_attrs(active: @drawer_open, initial: "#drawer-heading")) %>>
    #     …
    #   </div>
    def focus_trap_attrs(**options)
      Crosswire::Presenters::FocusTrap.new(**options).root_attrs
    end
  end
end
