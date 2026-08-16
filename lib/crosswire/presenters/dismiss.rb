# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Dismiss — remove or hide a container on click, Escape, or a timeout.
    #
    # No APG pattern governs this; the accessibility requirements come from context:
    # a dismissible alert needs its trigger labelled, and removing a focused element
    # must not strand focus. Both are handled here and in the controller.
    #
    # Composes with `transition` (exit animation) and `timeout` (auto-dismiss) rather
    # than absorbing either. That separation is why the same controller serves a flash
    # message, a modal close button, and a dismissible banner.
    class Dismiss < Presenter
      # @param remove [Boolean] remove the node (true) or just hide it (false).
      #   Hiding is the right default inside a Turbo Frame that may re-render.
      # @param selector [String, nil] CSS selector for the container to dismiss.
      #   Defaults to the controller element itself.
      # @param label [String] accessible name for the trigger
      # @param escape [Boolean] also dismiss on Escape
      def initialize(remove: true, selector: nil, label: "Dismiss", escape: false, **overrides)
        @remove = !!remove
        @selector = selector
        @label = label
        @escape = !!escape
        super(**overrides)
      end

      def root_attrs
        actions = []
        actions << "keydown.esc->dismiss" if @escape

        merge(
          controller_attrs,
          values(remove: @remove, selector: @selector),
          actions.any? ? action(*actions) : {},
          # Escape has to reach the container even when focus is inside it.
          @escape ? { "tabindex" => "-1" } : {},
          overrides
        )
      end

      def trigger_attrs(**extra)
        merge(
          action("click->dismiss"),
          { "type" => "button", "aria-label" => @label },
          extra
        )
      end
    end
  end
end
