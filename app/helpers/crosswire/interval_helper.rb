# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.interval_for`,
  # `cw.interval_attrs` (and `cw.interval` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `interval` is a behaviour, not a widget — it decorates an element you already
  # have, so it ships no batteries-included render form and no partial, only the
  # two standard forms.
  module IntervalHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= cw.interval_for ms: 5000 do |i| %>
    #     <turbo-frame id="job_status" src="<%= job_status_path %>">
    #       <div <%= cw_attrs(i.root_attrs) %>
    #            data-action="cw--interval:tick->job_status#reload"></div>
    #     </turbo-frame>
    #   <% end %>
    def interval_for(**options, &block)
      capture(Crosswire::Presenters::Interval.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs`
    # or `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`'
    # job. `ms:` is required and passed straight through to the presenter.
    #
    #   <div <%= cw_attrs(cw.interval_attrs(ms: 5000),
    #             data: { action: "cw--interval:tick->job_status#reload" }) %>>
    #   </div>
    def interval_attrs(**options)
      Crosswire::Presenters::Interval.new(**options).root_attrs
    end
  end
end
