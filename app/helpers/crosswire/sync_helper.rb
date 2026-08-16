# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::SyncHelper
  #   end
  #
  # `sync` is a behaviour, not a widget — it decorates an element you already
  # have, so it ships no batteries-included render form and no partial, only the
  # `_for` attribute builder.
  module SyncHelper
    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_sync_for target: "#char-count", attribute: "textContent", transform: "length" do |s| %>
    #     <textarea maxlength="280" <%= cw_attrs(s.root_attrs) %>></textarea>
    #   <% end %>
    #   <span id="char-count">0</span>
    def crosswire_sync_for(**options)
      yield Crosswire::Presenters::Sync.new(**options)
    end
  end
end
