# frozen_string_literal: true

# **What it is.** A declarative keybinding that fires an action or a click. A
# *behaviour* — no markup, no partial.
#
# **What it composes from.** `Crosswire::Presenters::Hotkey` emits `key`, `scope` and
# `prevent_default` as values; `cw--hotkey` parses the spec by hand (Stimulus's own key
# filters are exact-match per descriptor, which cannot express an arbitrary
# runtime-supplied chord — R8a) and, on a match, dispatches `cw--hotkey:fired` and then
# performs a synthetic `this.element.click()`. That second part is the whole model: a
# hotkey activates the element it decorates, it does not carry its own behaviour. Bind
# it to a link and it navigates; bind it to a button that already has its own
# `data-action="click->…"` and the two compose for free, no extra wiring needed.
#
# **Rule 0.** The platform has `accesskey`, and it is not a real alternative — no
# discoverability, it collides with browser/OS chrome, and its trigger modifier differs
# per browser and platform by design. That combination is why every serious
# command-palette implementation hand-rolls keybindings instead.
class HotkeyPreview < Lookbook::Preview
  # Press the key anywhere on this page (unless it lands in a text field and the spec
  # has no modifier — see "suppressed while typing" in the controller docstring). The
  # button's own click count increments because the hotkey performs a real click on it,
  # not because the hotkey carries any click-handling logic of its own.
  #
  # @param key text "A spec such as cmd+k, /, or shift+?"
  # @param scope select "~ [window, element]"
  # @param prevent_default toggle "preventDefault() on a match — usually wanted so cmd+k doesn't also open a browser UI"
  def default(key: "cmd+k", scope: "window", prevent_default: true)
    render_with_template(
      template: "hotkey_preview/default",
      locals: {key: key, scope: scope, prevent_default: prevent_default}
    )
  end
end
