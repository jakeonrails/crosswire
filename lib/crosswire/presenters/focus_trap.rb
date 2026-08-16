# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # FocusTrap — constrain Tab cycling within an element and restore focus on release.
    #
    # Rule 0, and read it before wiring this up: inside a modal `<dialog>` you do NOT
    # need this. `showModal()` already makes the rest of the document `inert`, which
    # removes it from both the tab order and the accessibility tree for free — hand-
    # rolling a trap on top of that is redundant at best and can actively fight the
    # browser's own focus handling at worst. See `cw--dialog`, which drives native
    # `<dialog>` and says as much in its own docstring.
    #
    # This component exists for everything `<dialog>` cannot cover: drawers, non-modal
    # side panels, toolbars, and any other overlay or region that intentionally leaves
    # the rest of the page interactive but still needs Tab to stay inside it while
    # active.
    #
    # A behaviour, not a widget — it decorates whatever element it is placed on and
    # ships no partial (docs/COMPONENT_CONTRACT.md).
    #
    # The controller re-queries focusable descendants on every Tab press rather than
    # caching a list at activation. Content under Turbo changes constantly — frames
    # render, streams append, buttons toggle `disabled` — and a cached list goes stale
    # and can trap focus on a node that is no longer there. See the controller
    # docstring for the exact mechanics of wrapping, the no-focusable-children
    # fallback, and escaped-focus recapture.
    class FocusTrap < Presenter
      attr_reader :active, :initial

      # @param active [Boolean] whether the trap is currently engaged. State lives
      #   here, not in a method call — a parent controller (a drawer, a panel) flips
      #   this value and the controller's `activeValueChanged` does the work, per R4.
      # @param initial [String, nil] CSS selector, resolved inside the trapped element,
      #   for the element to focus when the trap activates. Falls back to the first
      #   focusable descendant, then to the container itself.
      # @param active_class [String, nil] class applied to the root element while the
      #   trap is engaged. Optional — omit it and the controller's `hasActiveClass`
      #   guard (R3) skips it entirely rather than throwing.
      # @param overrides [Hash] merged into the root element, last
      def initialize(active: true, initial: nil, active_class: nil, **overrides)
        @active = !!active
        @initial = initial
        @active_class = active_class
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(active: active, initial: initial),
          # Per R3a, the class attribute is emitted on the root (controller) element
          # even though visually there is nothing else it could apply to here — this
          # component has no targets, only the root.
          classes(active: @active_class),
          # Stimulus's key-filter modifiers are exact-match: a bare `.tab` filter
          # requires shiftKey to be false, so Shift+Tab needs its own descriptor
          # (`.shift+tab`) rather than being caught by the plain one. Both route to
          # the same #cycle, which reads event.shiftKey itself to pick a direction.
          action("keydown.tab->cycle", "keydown.shift+tab->cycle"),
          overrides
        )
      end
    end
  end
end
