# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::HotkeyHelper
  #   end
  #
  # `hotkey` is a behaviour, not a widget — it decorates an element you already have,
  # so it ships no batteries-included render form and no partial, only the `_for`
  # attribute builder.
  module HotkeyHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_hotkey_for key: "cmd+k" do |h| %>
    #     <button <%= cw_attrs(h.root_attrs) %> data-action="click->dialog#open">
    #       Search
    #     </button>
    #   <% end %>
    def crosswire_hotkey_for(**options)
      yield Crosswire::Presenters::Hotkey.new(**options)
    end
  end
end
