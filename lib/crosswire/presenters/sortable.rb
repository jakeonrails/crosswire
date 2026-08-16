# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Sortable — drag-and-drop reordering that PATCHes the new position to the
    # server, wrapping SortableJS (https://github.com/SortableJS/Sortable).
    #
    # A behaviour, not a widget — it decorates a list of `item`s you already have,
    # so it ships no partial (docs/COMPONENT_CONTRACT.md "Files per component").
    #
    # Rule 0: native `draggable="true"` + the HTML5 Drag and Drop API exist, but they
    # are a poor fit here on their own merits (no built-in ghost/animation/scroll
    # handling, inconsistent touch support) — a wrapped library earns its place. What
    # Rule 0 actually buys you is the keyboard fallback below: reordering itself has
    # no zero-JS answer, but the ACCESSIBLE path (`move_up_attrs`/`move_down_attrs`)
    # is plain buttons and needs no library at all.
    #
    # SORTABLEJS IS NOT A DEPENDENCY OF THIS GEM — neither a gem nor an npm package.
    # A component library that hard-depends on a drag-and-drop library for one
    # component out of dozens is a bad trade (research/notes/05-ecosystem-survey.md).
    # It is an OPTIONAL PEER: the controller looks for `window.Sortable` (what an
    # importmap-rails pin of "sortablejs" — or a plain `<script>` tag — exposes) and,
    # failing that, calls a loader hook a bundler consumer can override with their own
    # dynamic import. See the controller docstring for the exact mechanism and the
    # install line. If neither is present, the controller logs one console warning
    # naming what to install and no-ops — drag-and-drop is unavailable, but the
    # `move_up_attrs`/`move_down_attrs` keyboard controls (which depend on nothing but
    # `fetch`) keep working regardless.
    #
    # ACCESSIBILITY, STATED HONESTLY: native HTML5 drag-and-drop is not operable by
    # keyboard or screen-reader users, and SortableJS — a pointer/touch-event library
    # — does not change that. There is no ARIA that fixes this; APG has no pattern for
    # drag-and-drop reordering because pointer dragging isn't the accessible mechanism
    # in the first place. The REQUIRED fallback is a pair of "move up"/"move down"
    # buttons per item, provided as first-class presenter methods
    # (`move_up_attrs`/`move_down_attrs`) rather than left for a consumer to
    # improvise — they drive the exact same reorder-and-persist code path as a real
    # drag, so a keyboard user's reorder is never a second-class citizen of the
    # feature.
    class Sortable < Presenter
      # @param url [String] where to PATCH the new order.
      # @param group [String, nil] shared group name; set on multiple containers to
      #   allow dragging items between them.
      # @param handle [String, nil] CSS selector restricting the draggable grip to a
      #   descendant of each item (e.g. ".drag-handle") rather than the whole item.
      # @param param_name [String] the form-field name the new order is PATCHed
      #   under, sent as `<param_name>[]=id1&<param_name>[]=id2…` in the new DOM
      #   order — the server infers each item's position from array order, never from
      #   a client-computed integer. Defaults to "position" (the common Rails column
      #   name for what the field ultimately controls), even though the field itself
      #   carries ids, not indices — rename it if your endpoint expects a different
      #   key (e.g. "ids").
      def initialize(url:, group: nil, handle: nil, param_name: "position", **overrides)
        @url = url
        @group = group
        @handle = handle
        @param_name = param_name
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(url: @url, group: @group, handle: @handle, param_name: @param_name),
          overrides
        )
      end

      # One call per draggable row. `id` is the item's stable server-side identifier
      # — rendered as the plain HTML `id` attribute (the ordinary `dom_id(record)`
      # idiom), which is what the controller reads to build the PATCHed order. Do not
      # confuse this with a Stimulus value: it is per-item data, not controller state.
      def item_attrs(id:, **extra)
        merge(target(:item), { "id" => id.to_s }, extra)
      end

      # THE ACCESSIBLE PATH — see the class docstring. A plain `type="button"` that
      # dispatches the controller's `moveUp` action, which moves the item one slot
      # earlier in the DOM and PATCHes the result through the identical persistence
      # path a drag uses. Pass `disabled: true` for the first item (there is nowhere
      # further up to move it) — the presenter cannot know this on its own; the
      # caller knows the item's position.
      def move_up_attrs(disabled: false, label: "Move up", **extra)
        merge(
          action("click->moveUp"),
          { "type" => "button", "aria-label" => label, "disabled" => disabled },
          extra
        )
      end

      # The mirror of `move_up_attrs`: moves the item one slot later. Pass
      # `disabled: true` for the last item.
      def move_down_attrs(disabled: false, label: "Move down", **extra)
        merge(
          action("click->moveDown"),
          { "type" => "button", "aria-label" => label, "disabled" => disabled },
          extra
        )
      end
    end
  end
end
