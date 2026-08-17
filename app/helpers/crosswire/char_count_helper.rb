# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.char_count_for`,
  # `cw.char_count_attrs` (and `cw.char_count` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `char-count` is a behaviour, not a widget — it decorates an input and an output
  # element you already have, so it ships no partial, only the two standard forms.
  module CharCountHelper
    # Build the attributes for the element `cw--char-count` should decorate (the
    # container wrapping both the input and its output).
    #
    #   <div <%= cw_attrs(cw.char_count_attrs(max: 280)) %>>
    #     <%= f.text_area :bio, maxlength: 280 %>
    #     <output>280 characters remaining</output>
    #   </div>
    #
    # This bare form does not wire the `input`/`output` targets — use
    # `cw.char_count_for` when you want those attributes built for you too.
    def char_count_attrs(**options)
      Crosswire::Presenters::CharCount.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.char_count_for max: 280 do |c| %>
    #     <div <%= cw_attrs(c.root_attrs) %>>
    #       <%= f.text_area :bio, **c.input_attrs, maxlength: 280 %>
    #       <%= tag.output(**c.output_attrs) %>
    #     </div>
    #   <% end %>
    def char_count_for(**options, &block)
      capture(Crosswire::Presenters::CharCount.new(**options), &block)
    end
  end
end
