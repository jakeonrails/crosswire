# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.dirty_form_for`,
  # `cw.dirty_form_attrs` (and `cw.dirty_form` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `dirty-form` is a behaviour, not a widget — it decorates a `<form>` you already
  # have, so it ships no partial, only the two standard forms.
  module DirtyFormHelper
    # Build the attributes for the `<form>` `cw--dirty-form` should decorate.
    #
    #   <%= form_with model: @post, **cw_attrs(cw.dirty_form_attrs) do |f| %>
    #     …
    #   <% end %>
    def dirty_form_attrs(**options)
      Crosswire::Presenters::DirtyForm.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.dirty_form_for guard: true do |d| %>
    #     <%= form_with model: @post, **d.root_attrs do |f| %>
    #       …
    #     <% end %>
    #   <% end %>
    def dirty_form_for(**options, &block)
      capture(Crosswire::Presenters::DirtyForm.new(**options), &block)
    end
  end
end
