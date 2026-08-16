# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Selection — a checkbox group with select-all, indeterminate state, a live
    # count, and toolbar enable/disable.
    #
    # A behaviour, not a widget — it decorates checkboxes and a toolbar you already
    # have (a table of rows, a list of cards), so it ships no partial
    # (docs/COMPONENT_CONTRACT.md "Files per component").
    #
    # Rule 0: none applies. `indeterminate` itself is native to `<input
    # type="checkbox">`, but there is no native "select-all checkbox group" element —
    # the coordination between the header checkbox, N row checkboxes, a live count and
    # a toolbar is exactly what this primitive supplies.
    #
    # THE DETAIL EVERYONE GETS WRONG: `indeterminate` is a DOM *property*, not an HTML
    # *attribute*. It cannot be set in markup (`<input indeterminate>` does nothing)
    # and it does NOT survive a Turbo morph or a bfcache restore — the browser simply
    # never serialises it. So the controller re-derives it imperatively, both on
    # `connect()` and after every change; there is no server-rendered equivalent to
    # fall back on the way `open` or `selected` can for other primitives. See the
    # controller docstring for exactly where.
    #
    # Turbo Streams append rows without a full re-init, so the controller wires
    # `itemTargetConnected`/`itemTargetDisconnected` (and the `all` equivalents) to
    # recompute the count and select-all state as targets come and go — the ordinary
    # Hotwire idiom for a group whose membership changes under it (see `roving-focus`
    # for the same idiom applied to tabindex bookkeeping).
    class Selection < Presenter
      def root_attrs
        merge(controller_attrs, overrides)
      end

      # The header/"select all" checkbox. Toggling it checks or unchecks every `item`.
      def all_attrs(**extra)
        merge(target(:all), action("change->toggleAll"), extra)
      end

      # One call per row checkbox. `change` recomputes the count, the select-all
      # state (including `indeterminate`) and the toolbar's enabled state — see the
      # controller's `itemTargetConnected` for why membership changes (a Turbo Stream
      # appending a row) recompute the same way without needing this action to fire.
      def item_attrs(**extra)
        merge(target(:item), action("change->refresh"), extra)
      end

      # The live count output. `aria-live="polite"` is set here, not by the
      # controller, because the region must PRE-EXIST for assistive tech to announce
      # into it — an element that gains `aria-live` only after JS has already written
      # its text is not guaranteed to announce that first write.
      def count_attrs(**extra)
        merge(
          target(:count),
          { "aria-live" => "polite", "aria-atomic" => "true" },
          extra
        )
      end

      # One call per toolbar control (a button, or a submit input). Disabled by
      # default because the ordinary case is a fresh page load with nothing selected
      # (R4: state rendered server-side, so the disabled toolbar is correct before
      # JavaScript loads). Pass `disabled: false` when the caller pre-selects rows
      # server-side.
      #
      # Both `disabled` and `aria-disabled` are set: the native `disabled` attribute
      # is right for a real `<button>`/`<input>`, but it also removes the element from
      # the tab order — wrong for a control (an `<a>` styled as a button, say) that
      # must stay focusable while inert. `aria-disabled` works on anything and costs
      # nothing to set alongside the native attribute.
      def action_attrs(disabled: true, **extra)
        merge(
          target(:action),
          { "disabled" => disabled, "aria-disabled" => disabled.to_s },
          extra
        )
      end
    end
  end
end
