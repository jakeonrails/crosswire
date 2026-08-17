# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.timeout_for`,
  # `cw.timeout_attrs` (and `cw.timeout` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `timeout` is a behaviour, not a widget — it decorates an element you already have,
  # so it ships no batteries-included render form and no partial, only the two
  # standard forms.
  module TimeoutHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= cw.timeout_for delay: 8000 do |t| %>
    #     <div <%= cw_attrs(t.root_attrs) %>
    #          data-action="cw--timeout:elapsed->cw--dismiss#dismiss
    #                       mouseenter->cw--timeout#cancel
    #                       mouseleave->cw--timeout#restart">
    #       …
    #     </div>
    #   <% end %>
    def timeout_for(**options, &block)
      capture(Crosswire::Presenters::Timeout.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    # `delay:` is required and passed straight through to the presenter.
    #
    #   <div <%= cw_attrs(cw.timeout_attrs(delay: 8000),
    #             data: { action: "cw--timeout:elapsed->cw--dismiss#dismiss" }) %>>
    #     …
    #   </div>
    def timeout_attrs(**options)
      Crosswire::Presenters::Timeout.new(**options).root_attrs
    end
  end
end
