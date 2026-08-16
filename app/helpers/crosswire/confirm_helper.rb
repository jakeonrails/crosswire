# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::ConfirmHelper
  #   end
  module ConfirmHelper
    # Batteries-included form — renders the shipped partial.
    #
    # Mount this ONCE, e.g. in the application layout — one dialog is reused for every
    # confirmation in the page via its `open()` method. See
    # Crosswire::Presenters::Confirm for the `Turbo.config.forms.confirm` wiring.
    #
    #   <%= crosswire_confirm id: "confirm" %>
    def crosswire_confirm(**options)
      presenter = Crosswire::Presenters::Confirm.new(**options)

      render("crosswire/confirm", confirm: presenter)
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_confirm_for id: "confirm" do |c| %>
    #     <dialog <%= cw_attrs(c.dialog_attrs) %>>
    #       <h2 <%= cw_attrs(c.title_attrs) %>><%= c.title %></h2>
    #       <p <%= cw_attrs(c.body_attrs) %>><%= c.body %></p>
    #       <button <%= cw_attrs(c.cancel_attrs) %>><%= c.cancel_label %></button>
    #       <button <%= cw_attrs(c.confirm_attrs) %>><%= c.confirm_label %></button>
    #     </dialog>
    #   <% end %>
    def crosswire_confirm_for(**options, &block)
      capture(Crosswire::Presenters::Confirm.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.dialog(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    # `confirm` has a single root element (the `<dialog>` itself, stacking both
    # `cw--dialog` and `cw--confirm`), so this is `Presenters::Confirm#dialog_attrs`
    # rather than a `root_attrs` — see the presenter docstring.
    #
    #   <dialog <%= cw_attrs(crosswire_confirm_attrs(id: "confirm"), class: "cw-confirm") %>>
    #     …
    #   </dialog>
    def crosswire_confirm_attrs(**options)
      Crosswire::Presenters::Confirm.new(**options).dialog_attrs
    end
  end
end
