# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.reveal_for`,
  # `cw.reveal_attrs` (and `cw.reveal` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `reveal` is a behaviour, not a widget — it decorates an input and a trigger you
  # already have, so it ships no partial, only the two standard forms.
  module RevealHelper
    # Build the attributes for the element `cw--reveal` should decorate (the
    # container wrapping both the input and its trigger).
    #
    #   <div <%= cw_attrs(cw.reveal_attrs) %>>
    #     <%= f.password_field :password %>
    #     <button type="button">Show</button>
    #   </div>
    #
    # This bare form does not wire the `input`/`trigger` targets — use
    # `cw.reveal_for` when you want those attributes built for you too.
    def reveal_attrs(**options)
      Crosswire::Presenters::Reveal.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.reveal_for do |r| %>
    #     <div <%= cw_attrs(r.root_attrs) %>>
    #       <%= f.password_field :password, **r.input_attrs, autocomplete: "new-password" %>
    #       <button <%= cw_attrs(r.trigger_attrs) %>>Show password</button>
    #     </div>
    #   <% end %>
    def reveal_for(**options, &block)
      capture(Crosswire::Presenters::Reveal.new(**options), &block)
    end
  end
end
