# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::DialogHelper
  #   end
  module DialogHelper
    # Batteries-included form — renders the shipped partial.
    #
    #   <%= crosswire_dialog "Delete this project?", id: "confirm-delete", trigger_label: "Delete…" do %>
    #     <p>This cannot be undone.</p>
    #   <% end %>
    #
    # `title` becomes the dialog's accessible name (`aria-labelledby`) and its visible
    # heading. `trigger_label`, if given, renders a button — fully wired via
    # `dialog.trigger_attrs` — that opens the dialog; omit it to supply your own
    # trigger anywhere on the page with `crosswire_dialog_for`.
    #
    # The partial is overridable by creating app/views/crosswire/_dialog.html.erb, or
    # ejectable with `rails g crosswire:eject dialog`. Accessibility comes from the
    # presenter, so a restyled copy stays correct.
    def crosswire_dialog(title = nil, trigger_label: nil, **options, &body)
      presenter = Crosswire::Presenters::Dialog.new(title: title, **options)

      # The block is genuinely optional — a dialog can be title-only, or have its body
      # streamed in later. `capture(&nil)` yields with no block and raises
      # LocalJumpError, so guard rather than assume.
      render("crosswire/dialog",
             dialog: presenter,
             title: title,
             trigger_label: trigger_label,
             body: (capture(&body) if body))
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_dialog_for id: "confirm-delete" do |d| %>
    #     <div <%= cw_attrs(d.root_attrs) %>>
    #       <button <%= cw_attrs(d.trigger_attrs) %>>Delete…</button>
    #       <dialog <%= cw_attrs(d.panel_attrs) %>>
    #         <h2 <%= cw_attrs(d.title_attrs) %>>Delete this project?</h2>
    #         <button <%= cw_attrs(d.close_attrs) %>>Close</button>
    #       </dialog>
    #     </div>
    #   <% end %>
    def crosswire_dialog_for(**options)
      yield Crosswire::Presenters::Dialog.new(**options)
    end
  end
end
