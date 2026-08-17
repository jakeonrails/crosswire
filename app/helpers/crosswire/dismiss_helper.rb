# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.dismiss_for`,
  # `cw.dismiss_attrs` (and `cw.dismiss` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `dismiss` is a behaviour, not a widget — it decorates a container you already have
  # (a flash message, a banner, a modal), so it ships no partial. It does own a second
  # element though, the trigger, which is why there is a `_for` form as well as the
  # bare attribute builder.
  module DismissHelper
    # Build the attributes for the container `cw--dismiss` should decorate.
    #
    #   <div <%= cw_attrs(cw.dismiss_attrs(escape: true), class: "flash") %>>
    #     Saved.
    #   </div>
    #
    # Composes with `transition` on the same element — the cancelable-dismissal seam
    # is the reference example of R6:
    #
    #   <div <%= cw_attrs(
    #             cw.transition_attrs(leave: "fade", leave_from: "opacity-100", leave_to: "opacity-0"),
    #             cw.dismiss_attrs) %>>
    def dismiss_attrs(**options)
      Crosswire::Presenters::Dismiss.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    # Use this when you want the trigger wired too.
    #
    #   <%= cw.dismiss_for label: "Dismiss notice" do |d| %>
    #     <div <%= cw_attrs(d.root_attrs, class: "flash") %>>
    #       Saved.
    #       <button <%= cw_attrs(d.trigger_attrs) %>>&times;</button>
    #     </div>
    #   <% end %>
    def dismiss_for(**options, &block)
      capture(Crosswire::Presenters::Dismiss.new(**options), &block)
    end
  end
end
