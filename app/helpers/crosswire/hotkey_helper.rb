# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::HotkeyHelper
  #   end
  #
  # `hotkey` is a behaviour, not a widget — it decorates an element you already have,
  # so it ships no batteries-included render form and no partial, only the two
  # standard forms.
  module HotkeyHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_hotkey_for key: "cmd+k" do |h| %>
    #     <button <%= cw_attrs(h.root_attrs) %> data-action="click->dialog#open">
    #       Search
    #     </button>
    #   <% end %>
    def crosswire_hotkey_for(**options, &block)
      capture(Crosswire::Presenters::Hotkey.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.button(**...)`. Renders and escapes nothing itself; that is `cw_attrs`'
    # job. `key:` is required and passed straight through to the presenter — a
    # hotkey with no key is meaningless, so there is no default to fall back on.
    #
    #   <button <%= cw_attrs(crosswire_hotkey_attrs(key: "cmd+k"), data: { action: "click->dialog#open" }) %>>
    #     Search
    #   </button>
    def crosswire_hotkey_attrs(**options)
      Crosswire::Presenters::Hotkey.new(**options).root_attrs
    end
  end
end
