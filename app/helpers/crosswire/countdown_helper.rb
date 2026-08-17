# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.countdown_for`,
  # `cw.countdown_attrs` (and `cw.countdown` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `countdown` is a behaviour, not a widget — it decorates a container you
  # already have, so it ships no batteries-included render form and no partial.
  # It does own a second element (the `output` target that receives the ticking
  # text), which is why `cw.countdown_for` is the form to reach for when
  # you want that target wired too.
  module CountdownHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= cw.countdown_for deadline: @auction.ends_at.utc.iso8601 do |c| %>
    #     <div <%= cw_attrs(c.root_attrs) %> data-action="cw--countdown:elapsed->form#disable">
    #       <time <%= cw_attrs(c.output_attrs) %>>
    #         <%= distance_of_time_in_words_to_now(@auction.ends_at) %>
    #       </time>
    #     </div>
    #   <% end %>
    def countdown_for(**options, &block)
      capture(Crosswire::Presenters::Countdown.new(**options), &block)
    end

    # Returns the merged ROOT attribute hash — a plain Hash, ready for
    # `cw_attrs` or `tag.div(**...)`. Renders and escapes nothing itself; that
    # is `cw_attrs`' job. `deadline:` is required and passed straight through to
    # the presenter. This form does not wire the `output` target — reach for
    # `cw.countdown_for` when you need that too.
    #
    #   <div <%= cw_attrs(cw.countdown_attrs(deadline: @auction.ends_at.utc.iso8601)) %>>
    #     …
    #   </div>
    def countdown_attrs(**options)
      Crosswire::Presenters::Countdown.new(**options).root_attrs
    end
  end
end
