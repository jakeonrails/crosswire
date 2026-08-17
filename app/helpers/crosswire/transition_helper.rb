# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.transition_for`,
  # `cw.transition_attrs` (and `cw.transition` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `transition` is a behaviour, not a widget — it decorates an element you already
  # own, so it ships no partial, only the two standard forms.
  module TransitionHelper
    # Build the attributes for an element `cw--transition` should decorate.
    #
    #   <div <%= cw_attrs(cw.transition_attrs(
    #             leave: "transition duration-150",
    #             leave_from: "opacity-100",
    #             leave_to: "opacity-0"),
    #           cw.dismiss_attrs) %>>
    #     …
    #   </div>
    #
    # Pair with `cw.transition_attrs(...).merge` — or, more idiomatically,
    # `cw_attrs` — to combine with another component's attrs on the same element, most
    # commonly `cw--dismiss` (see `Crosswire::Presenters::Transition#leave_on`).
    def transition_attrs(**options)
      Crosswire::Presenters::Transition.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.transition_for leave: "transition duration-150",
    #         leave_from: "opacity-100", leave_to: "opacity-0" do |t| %>
    #     <div <%= cw_attrs(t.root_attrs, t.leave_on, cw.dismiss_attrs) %>>
    #       …
    #     </div>
    #   <% end %>
    def transition_for(**options, &block)
      capture(Crosswire::Presenters::Transition.new(**options), &block)
    end
  end
end
