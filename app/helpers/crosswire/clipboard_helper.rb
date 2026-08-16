# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::ClipboardHelper
  #   end
  #
  # `clipboard` is a behaviour, not a widget — it ships no partial, only the `_for`
  # attribute builder. Note that `status_attrs` must be rendered as part of your normal
  # markup (never injected client-side later) — see the presenter and controller
  # docstrings for why.
  module ClipboardHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_clipboard_for success_class: "is-copied" do |c| %>
    #     <div <%= cw_attrs(c.root_attrs) %>>
    #       <input <%= cw_attrs(c.source_attrs) %> value="<%= invite_url %>" readonly>
    #       <button <%= cw_attrs(c.button_attrs) %>>Copy link</button>
    #       <span class="sr-only" <%= cw_attrs(c.status_attrs) %>></span>
    #     </div>
    #   <% end %>
    def crosswire_clipboard_for(**options)
      yield Crosswire::Presenters::Clipboard.new(**options)
    end
  end
end
