# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.clipboard_for`,
  # `cw.clipboard_attrs` (and `cw.clipboard` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `clipboard` is a behaviour, not a widget — it ships no partial, only the two
  # standard forms. Note that `status_attrs` must be rendered as part of your normal
  # markup (never injected client-side later) — see the presenter and controller
  # docstrings for why.
  module ClipboardHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= cw.clipboard_for success_class: "is-copied" do |c| %>
    #     <div <%= cw_attrs(c.root_attrs) %>>
    #       <input <%= cw_attrs(c.source_attrs) %> value="<%= invite_url %>" readonly>
    #       <button <%= cw_attrs(c.button_attrs) %>>Copy link</button>
    #       <span class="sr-only" <%= cw_attrs(c.status_attrs) %>></span>
    #     </div>
    #   <% end %>
    def clipboard_for(**options, &block)
      capture(Crosswire::Presenters::Clipboard.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.button(**...)`. Renders and escapes nothing itself; that is `cw_attrs`'
    # job. Covers the controller/values/classes attrs only — per
    # `Presenters::Clipboard#button_attrs`, the root element can carry the click
    # action itself for a single-element copy button, so add it explicitly:
    #
    #   <button <%= cw_attrs(cw.clipboard_attrs(text: invite_url),
    #             data: { action: "click->cw--clipboard#copy" }, type: "button") %>>
    #     Copy link
    #   </button>
    #
    # Reach for `cw.clipboard_for` when you need separate source/button/status
    # elements wired too.
    def clipboard_attrs(**options)
      Crosswire::Presenters::Clipboard.new(**options).root_attrs
    end
  end
end
