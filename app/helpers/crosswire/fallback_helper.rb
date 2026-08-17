# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.fallback_for`,
  # `cw.fallback_attrs` (and `cw.fallback` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `fallback` is a behaviour, not a widget — it decorates a scope you already have
  # (typically wrapping a `<turbo-frame>`), so it ships no partial.
  module FallbackHelper
    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    # This is the form worth reaching for: `loading_attrs`/`failed_attrs`/
    # `source_attrs` all read the presenter's own `state`, so building the retry
    # button and both regions from ONE presenter instance keeps them in sync.
    #
    # A lazy `<turbo-frame>` wrapped end to end (`turbo_frame_tag` is a Rails/
    # turbo-rails helper used here only as an example — crosswire has no dependency
    # on it, see Rule 0 in the controller docstring):
    #
    #   <%= cw.fallback_for(state: @report_ready ? "ok" : "loading") do |f| %>
    #     <div <%= cw_attrs(f.root_attrs) %>>
    #       <p <%= cw_attrs(f.loading_attrs) %>>Loading report…</p>
    #       <div <%= cw_attrs(f.failed_attrs) %>>
    #         Could not load the report.
    #         <button type="button" data-action="click->cw--fallback#retry">Retry</button>
    #       </div>
    #       <%= turbo_frame_tag "report", src: report_path, loading: :lazy do %>
    #         …
    #       <% end %>
    #     </div>
    #   <% end %>
    def fallback_for(**options, &block)
      capture(Crosswire::Presenters::Fallback.new(**options), &block)
    end

    # Returns the merged ROOT attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. The common single-scope case; reach for `cw.fallback_for`
    # when you also need `loading_attrs`/`failed_attrs`/`source_attrs` from the SAME
    # presenter instance (state stays in sync across all four) rather than
    # constructing several independent presenters by hand.
    def fallback_attrs(**options)
      Crosswire::Presenters::Fallback.new(**options).root_attrs
    end
  end
end
