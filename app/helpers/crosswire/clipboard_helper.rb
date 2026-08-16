# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::ClipboardHelper
  #   end
  #
  # `clipboard` is a behaviour, not a widget — it ships no partial, only the two
  # standard forms. Note that `status_attrs` must be rendered as part of your normal
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

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.button(**...)`. Renders and escapes nothing itself; that is `cw_attrs`'
    # job. Covers the controller/values/classes attrs only — per
    # `Presenters::Clipboard#button_attrs`, the root element can carry the click
    # action itself for a single-element copy button, so add it explicitly:
    #
    #   <button <%= cw_attrs(crosswire_clipboard_attrs(text: invite_url),
    #             data: { action: "click->cw--clipboard#copy" }, type: "button") %>>
    #     Copy link
    #   </button>
    #
    # Reach for `crosswire_clipboard_for` when you need separate source/button/status
    # elements wired too.
    def crosswire_clipboard_attrs(**options)
      Crosswire::Presenters::Clipboard.new(**options).root_attrs
    end
  end
end
