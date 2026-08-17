# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.autogrow_for`,
  # `cw.autogrow_attrs` (and `cw.autogrow` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `autogrow` is a behaviour, not a widget — it decorates a `<textarea>` you already
  # have, so it ships no partial, only the two standard forms. Read the presenter's
  # Rule 0 docstring before reaching for it: `field-sizing: content` replaces this
  # entirely on current-generation browsers.
  module AutogrowHelper
    # Build the attributes for the `<textarea>` `cw--autogrow` should decorate.
    #
    #   <%= f.text_area :body, **cw_attrs(cw.autogrow_attrs(max_rows: 12)) %>
    def autogrow_attrs(**options)
      Crosswire::Presenters::Autogrow.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.autogrow_for max_rows: 12 do |a| %>
    #     <%= f.text_area :body, **a.root_attrs %>
    #   <% end %>
    def autogrow_for(**options, &block)
      capture(Crosswire::Presenters::Autogrow.new(**options), &block)
    end
  end
end
