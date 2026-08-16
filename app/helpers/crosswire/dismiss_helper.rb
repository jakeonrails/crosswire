# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::DismissHelper
  #   end
  #
  # `dismiss` is a behaviour, not a widget — it decorates a container you already have
  # (a flash message, a banner, a modal), so it ships no partial. It does own a second
  # element though, the trigger, which is why there is a `_for` form as well as the
  # bare attribute builder.
  module DismissHelper
    # Build the attributes for the container `cw--dismiss` should decorate.
    #
    #   <div <%= cw_attrs(crosswire_dismiss_attrs(escape: true), class: "flash") %>>
    #     Saved.
    #   </div>
    #
    # Composes with `transition` on the same element — the cancelable-dismissal seam
    # is the reference example of R6:
    #
    #   <div <%= cw_attrs(
    #             crosswire_transition_attrs(leave: "fade", leave_from: "opacity-100", leave_to: "opacity-0"),
    #             crosswire_dismiss_attrs) %>>
    def crosswire_dismiss_attrs(**options)
      Crosswire::Presenters::Dismiss.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    # Use this when you want the trigger wired too.
    #
    #   <%= crosswire_dismiss_for label: "Dismiss notice" do |d| %>
    #     <div <%= cw_attrs(d.root_attrs, class: "flash") %>>
    #       Saved.
    #       <button <%= cw_attrs(d.trigger_attrs) %>>&times;</button>
    #     </div>
    #   <% end %>
    def crosswire_dismiss_for(**options, &block)
      capture(Crosswire::Presenters::Dismiss.new(**options), &block)
    end
  end
end
