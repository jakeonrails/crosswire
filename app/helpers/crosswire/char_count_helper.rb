# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::CharCountHelper
  #   end
  #
  # `char-count` is a behaviour, not a widget — it decorates an input and an output
  # element you already have, so it ships no partial, only the two standard forms.
  module CharCountHelper
    # Build the attributes for the element `cw--char-count` should decorate (the
    # container wrapping both the input and its output).
    #
    #   <div <%= cw_attrs(crosswire_char_count_attrs(max: 280)) %>>
    #     <%= f.text_area :bio, maxlength: 280 %>
    #     <output>280 characters remaining</output>
    #   </div>
    #
    # This bare form does not wire the `input`/`output` targets — use
    # `crosswire_char_count_for` when you want those attributes built for you too.
    def crosswire_char_count_attrs(**options)
      Crosswire::Presenters::CharCount.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_char_count_for max: 280 do |c| %>
    #     <div <%= cw_attrs(c.root_attrs) %>>
    #       <%= f.text_area :bio, **c.input_attrs, maxlength: 280 %>
    #       <%= tag.output(**c.output_attrs) %>
    #     </div>
    #   <% end %>
    def crosswire_char_count_for(**options, &block)
      capture(Crosswire::Presenters::CharCount.new(**options), &block)
    end
  end
end
