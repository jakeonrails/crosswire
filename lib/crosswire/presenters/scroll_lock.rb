# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # ScrollLock — lock document scroll while active.
    #
    # Rule 0: there isn't one. `<dialog>.showModal()` does not lock document scroll —
    # verified against whatwg/html#7732, open since 2022 — so the page behind an open
    # modal or drawer keeps scrolling unless something here does the locking. This is
    # the rare crosswire primitive with no platform feature to defer to.
    #
    # A behaviour, not a widget — it decorates whatever element owns the "am I open"
    # state (typically the same element as `cw--dialog` or a drawer's own controller)
    # and ships no partial (docs/COMPONENT_CONTRACT.md). The lock itself always applies
    # to `document.documentElement`/`document.body`, never to the controller's own
    # element — there is nothing element-scoped about "the page can't scroll."
    #
    # The controller reference-counts at module scope rather than per instance, because
    # two stacked lockers (a dialog opened from inside an already-locked drawer) must
    # not have the inner one's release re-enable page scroll while the outer is still
    # active — see the controller docstring for why that makes this a shared primitive
    # rather than inline code duplicated in `dialog` and every other overlay that needs
    # it.
    class ScrollLock < Presenter
      attr_reader :active

      # @param active [Boolean] whether the lock is currently engaged. State lives
      #   here, not in a method call — the owning controller (a dialog, a drawer) flips
      #   this value and `activeValueChanged` does the work, per R4.
      # @param overrides [Hash] merged into the root element, last
      def initialize(active: false, **overrides)
        @active = !!active
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(active: active),
          overrides
        )
      end
    end
  end
end
