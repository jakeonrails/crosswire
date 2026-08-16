# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::AutogrowHelper
  #   end
  #
  # `autogrow` is a behaviour, not a widget — it decorates a `<textarea>` you already
  # have, so it ships no partial, only the two standard forms. Read the presenter's
  # Rule 0 docstring before reaching for it: `field-sizing: content` replaces this
  # entirely on current-generation browsers.
  module AutogrowHelper
    # Build the attributes for the `<textarea>` `cw--autogrow` should decorate.
    #
    #   <%= f.text_area :body, **cw_attrs(crosswire_autogrow_attrs(max_rows: 12)) %>
    def crosswire_autogrow_attrs(**options)
      Crosswire::Presenters::Autogrow.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_autogrow_for max_rows: 12 do |a| %>
    #     <%= f.text_area :body, **a.root_attrs %>
    #   <% end %>
    def crosswire_autogrow_for(**options)
      yield Crosswire::Presenters::Autogrow.new(**options)
    end
  end
end
