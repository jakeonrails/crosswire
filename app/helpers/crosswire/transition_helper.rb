# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::TransitionHelper
  #   end
  #
  # `transition` is a behaviour, not a widget — it decorates an element you already
  # own, so it ships no partial. This helper exposes only an attribute builder, in the
  # spirit of `Crosswire::DisclosureHelper#crosswire_disclosure_for`.
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
  end
end
