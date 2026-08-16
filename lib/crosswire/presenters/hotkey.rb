# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # Hotkey — bind a declarative keybinding that fires an action or a click.
    #
    # Rule 0: the platform has `accesskey`, and it is not a real alternative. It has no
    # discoverability (nothing on screen tells a user it exists), it collides with
    # browser and OS chrome (Alt+<letter> is a menu accelerator in most browsers, and
    # Ctrl+<letter>/Cmd+<letter> ranges are reserved by the OS), and its trigger
    # modifier is different per browser and platform by design — there is no way to
    # document a single keystroke for it. That combination is why every serious
    # command-palette or shortcut implementation (GitHub, Linear, Superhuman, Slack)
    # hand-rolls keybindings instead of using `accesskey`, which is what this component
    # exists to make declarative and consistent instead of ad hoc.
    #
    # A behaviour, not a widget — it decorates whatever element it is placed on
    # (typically the same button or link the shortcut should activate) and ships no
    # partial (docs/COMPONENT_CONTRACT.md).
    class Hotkey < Presenter
      attr_reader :key, :scope, :prevent_default

      # @param key [String] a key spec such as `"cmd+k"`, `"/"`, or `"shift+?"`.
      #   Modifiers are `cmd`/`command`/`meta`, `ctrl`/`control`, `alt`/`option`, and
      #   `shift`, joined to the key with `+`. Parsed entirely in the controller — see
      #   its docstring for why Stimulus's own key filters cannot express this.
      # @param scope [String] `"window"` (default) listens document-wide regardless of
      #   focus; `"element"` listens only while focus is inside the controller's own
      #   element.
      # @param prevent_default [Boolean] call `event.preventDefault()` on a match.
      #   Defaults to true because most bindings (`cmd+k`, `/`) would otherwise also
      #   trigger a browser default (quick-find, address-bar focus).
      # @param overrides [Hash] merged into the root element, last
      def initialize(key:, scope: "window", prevent_default: true, **overrides)
        @key = key
        @scope = scope
        @prevent_default = !!prevent_default
        super(**overrides)
      end

      def root_attrs
        merge(
          controller_attrs,
          values(key: key, scope: scope, prevent_default: prevent_default),
          overrides
        )
      end
    end
  end
end
