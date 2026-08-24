# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.menu_for`,
  # `cw.menu_attrs` (and `cw.menu` for components that ship a partial) — or the
  # canonical `crosswire.` in place of `cw.`.
  module MenuHelper
    # Batteries-included form — renders the shipped partial.
    #
    #   <%= cw.menu "Actions", id: "row-42-menu", items: [
    #         { label: "Duplicate", value: "duplicate" },
    #         { label: "Archive", value: "archive" },
    #         { label: "View history", href: history_path(42) },
    #         { label: "Delete", value: "delete" }
    #       ] %>
    #
    # `items:` is an ordered array of `{ label:, href: nil, value: nil,
    # role: "menuitem", checked: nil, disabled: false }`. An item with `href:` renders
    # as `<a role="menuitem">`; without it, as `<button type="button" role="menuitem">`.
    # For a `button_to`-shaped item (a DELETE with CSRF), use `cw.menu_for` instead —
    # this partial deliberately doesn't try to express every activation shape.
    #
    # The partial is overridable by creating app/views/crosswire/_menu.html.erb, or
    # ejectable with `rails g crosswire:eject menu`. Accessibility comes from the
    # presenter, so a restyled copy stays correct. See
    # `Crosswire::Presenters::Menu`'s Rule 0 before reaching for this at all — if the
    # items are links to other pages, `cw.popover` with plain `<a>` and no `role="menu"`
    # is very likely what you actually want.
    def menu(button_label, id:, items:, **options)
      presenter = Crosswire::Presenters::Menu.new(id: id, **options)

      render("crosswire/menu", menu: presenter, button_label: button_label, items: items)
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.menu_for id: "row-42-menu" do |m| %>
    #     <div <%= cw_attrs(m.root_attrs) %>>
    #       <button <%= cw_attrs(m.button_attrs) %>>Actions</button>
    #       <div <%= cw_attrs(m.menu_attrs) %>>
    #         <button <%= cw_attrs(m.item_attrs(value: "duplicate")) %>>Duplicate</button>
    #         <%= button_to "Delete", row_path(42), method: :delete,
    #               **m.item_attrs(value: "delete") %>
    #       </div>
    #     </div>
    #   <% end %>
    def menu_for(**options, &block)
      capture(Crosswire::Presenters::Menu.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <div <%= cw_attrs(cw.menu_attrs(id: "row-42-menu")) %>>…</div>
    def menu_attrs(**options)
      Crosswire::Presenters::Menu.new(**options).root_attrs
    end
  end
end
