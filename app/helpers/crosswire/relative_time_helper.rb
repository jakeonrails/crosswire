# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::RelativeTimeHelper
  #   end
  #
  # `relative_time` is a behaviour, not a widget — it decorates an element you
  # already have (typically a `<time>`), so it ships no batteries-included
  # render form and no partial, only the two standard forms. Supply the
  # element's own text content yourself (Rails' `time_ago_in_words` is the
  # obvious choice) so there is a sensible fallback before JS runs.
  #
  # Read `Crosswire::Presenters::RelativeTime`'s docstring first — Rule 0
  # applies strongly here: prefer `<relative-time>` from
  # `@github/relative-time-element` over this controller where you can take the
  # dependency.
  module RelativeTimeHelper
    # Yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_relative_time_for datetime: comment.created_at.utc.iso8601 do |rt| %>
    #     <time <%= cw_attrs(rt.root_attrs) %>><%= time_ago_in_words(comment.created_at) %> ago</time>
    #   <% end %>
    def crosswire_relative_time_for(**options, &block)
      capture(Crosswire::Presenters::RelativeTime.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for
    # `cw_attrs` or `tag.time(**...)`. Renders and escapes nothing itself; that
    # is `cw_attrs`' job. `datetime:` is required and passed straight through to
    # the presenter.
    #
    #   <time <%= cw_attrs(crosswire_relative_time_attrs(datetime: comment.created_at.utc.iso8601)) %>>
    #     <%= time_ago_in_words(comment.created_at) %> ago
    #   </time>
    def crosswire_relative_time_attrs(**options)
      Crosswire::Presenters::RelativeTime.new(**options).root_attrs
    end
  end
end
