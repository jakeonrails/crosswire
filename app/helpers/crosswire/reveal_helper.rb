# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::RevealHelper
  #   end
  #
  # `reveal` is a behaviour, not a widget — it decorates an input and a trigger you
  # already have, so it ships no partial, only the two standard forms.
  module RevealHelper
    # Build the attributes for the element `cw--reveal` should decorate (the
    # container wrapping both the input and its trigger).
    #
    #   <div <%= cw_attrs(crosswire_reveal_attrs) %>>
    #     <%= f.password_field :password %>
    #     <button type="button">Show</button>
    #   </div>
    #
    # This bare form does not wire the `input`/`trigger` targets — use
    # `crosswire_reveal_for` when you want those attributes built for you too.
    def crosswire_reveal_attrs(**options)
      Crosswire::Presenters::Reveal.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_reveal_for do |r| %>
    #     <div <%= cw_attrs(r.root_attrs) %>>
    #       <%= f.password_field :password, **r.input_attrs, autocomplete: "new-password" %>
    #       <button <%= cw_attrs(r.trigger_attrs) %>>Show password</button>
    #     </div>
    #   <% end %>
    def crosswire_reveal_for(**options, &block)
      capture(Crosswire::Presenters::Reveal.new(**options), &block)
    end
  end
end
