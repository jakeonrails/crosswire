# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.sync_for`,
  # `cw.sync_attrs` (and `cw.sync` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `sync` is a behaviour, not a widget — it decorates an element you already
  # have, so it ships no batteries-included render form and no partial, only the two
  # standard forms.
  module SyncHelper
    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.sync_for target: "#char-count", attribute: "textContent", transform: "length" do |s| %>
    #     <textarea maxlength="280" <%= cw_attrs(s.root_attrs) %>></textarea>
    #   <% end %>
    #   <span id="char-count">0</span>
    def sync_for(**options, &block)
      capture(Crosswire::Presenters::Sync.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.textarea(**...)`. Renders and escapes nothing itself; that is `cw_attrs`'
    # job. `target:` is required and passed straight through to the presenter.
    #
    #   <textarea maxlength="280" <%= cw_attrs(cw.sync_attrs(target: "#char-count", attribute: "textContent", transform: "length")) %>></textarea>
    #   <span id="char-count">0</span>
    def sync_attrs(**options)
      Crosswire::Presenters::Sync.new(**options).root_attrs
    end
  end
end
