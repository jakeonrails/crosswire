# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::SyncHelper
  #   end
  #
  # `sync` is a behaviour, not a widget — it decorates an element you already
  # have, so it ships no batteries-included render form and no partial, only the two
  # standard forms.
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

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.textarea(**...)`. Renders and escapes nothing itself; that is `cw_attrs`'
    # job. `target:` is required and passed straight through to the presenter.
    #
    #   <textarea maxlength="280" <%= cw_attrs(crosswire_sync_attrs(target: "#char-count", attribute: "textContent", transform: "length")) %>></textarea>
    #   <span id="char-count">0</span>
    def crosswire_sync_attrs(**options)
      Crosswire::Presenters::Sync.new(**options).root_attrs
    end
  end
end
