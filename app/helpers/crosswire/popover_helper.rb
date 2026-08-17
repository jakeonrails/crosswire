# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.popover_for`,
  # `cw.popover_attrs` (and `cw.popover` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  module PopoverHelper
    # Batteries-included form — renders the shipped partial.
    #
    #   <%= cw.popover "About this user", id: "user_card_42" do %>
    #     <p>Member since 2024.</p>
    #   <% end %>
    #
    # The partial is overridable by creating app/views/crosswire/_popover.html.erb,
    # or ejectable with `rails g crosswire:eject popover`. Remember Rule 0 (see
    # Crosswire::Presenters::Popover): for most popovers the native
    # `popovertarget`/`popover` attributes this renders are the ENTIRE mechanism —
    # `cw--popover` only adds placement fallback and programmatic control.
    def popover(trigger_label, **options, &body)
      presenter = Crosswire::Presenters::Popover.new(**options)

      render("crosswire/popover",
             popover: presenter,
             trigger_label: trigger_label,
             body: capture(&body))
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.popover_for id: "user_card_42" do |p| %>
    #     <button <%= cw_attrs(p.trigger_attrs) %>>About</button>
    #     <div <%= cw_attrs(p.panel_attrs) %>>…</div>
    #   <% end %>
    def popover_for(**options, &block)
      capture(Crosswire::Presenters::Popover.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    # `popover` has no single element wrapping trigger+panel (see the presenter
    # docstring: `popovertarget`/`popover` link the two by id, with no shared
    # ancestor required) and the controller lives entirely on the panel, so this is
    # `Presenters::Popover#panel_attrs` rather than a `root_attrs`. You still need
    # to render the trigger yourself with `cw.popover_for`'s `trigger_attrs`.
    #
    #   <div <%= cw_attrs(cw.popover_attrs(id: "user_card_42")) %>>…</div>
    def popover_attrs(**options)
      Crosswire::Presenters::Popover.new(**options).panel_attrs
    end
  end
end
