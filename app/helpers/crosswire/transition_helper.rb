# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::TransitionHelper
  #   end
  #
  # `transition` is a behaviour, not a widget — it decorates an element you already
  # own, so it ships no partial, only the two standard forms.
  module TransitionHelper
    # Build the attributes for an element `cw--transition` should decorate.
    #
    #   <div <%= cw_attrs(crosswire_transition_attrs(
    #             leave: "transition duration-150",
    #             leave_from: "opacity-100",
    #             leave_to: "opacity-0"),
    #           crosswire_dismiss_attrs) %>>
    #     …
    #   </div>
    #
    # Pair with `crosswire_transition_attrs(...).merge` — or, more idiomatically,
    # `cw_attrs` — to combine with another component's attrs on the same element, most
    # commonly `cw--dismiss` (see `Crosswire::Presenters::Transition#leave_on`).
    def crosswire_transition_attrs(**options)
      Crosswire::Presenters::Transition.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= crosswire_transition_for leave: "transition duration-150",
    #         leave_from: "opacity-100", leave_to: "opacity-0" do |t| %>
    #     <div <%= cw_attrs(t.root_attrs, t.leave_on, crosswire_dismiss_attrs) %>>
    #       …
    #     </div>
    #   <% end %>
    def crosswire_transition_for(**options)
      yield Crosswire::Presenters::Transition.new(**options)
    end
  end
end
