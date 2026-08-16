# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::DirtyFormHelper
  #   end
  #
  # `dirty-form` is a behaviour, not a widget — it decorates a `<form>` you already
  # have, so it ships no partial, only the two standard forms.
  module DirtyFormHelper
    # Build the attributes for the `<form>` `cw--dirty-form` should decorate.
    #
    #   <%= form_with model: @post, **cw_attrs(crosswire_dirty_form_attrs) do |f| %>
    #     …
    #   <% end %>
    def crosswire_dirty_form_attrs(**options)
      Crosswire::Presenters::DirtyForm.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_dirty_form_for guard: true do |d| %>
    #     <%= form_with model: @post, **d.root_attrs do |f| %>
    #       …
    #     <% end %>
    #   <% end %>
    def crosswire_dirty_form_for(**options, &block)
      capture(Crosswire::Presenters::DirtyForm.new(**options), &block)
    end
  end
end
