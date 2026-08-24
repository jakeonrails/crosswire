# frozen_string_literal: true

# **What it is.** WAI-ARIA APG Menu Button/Menu — a list of *commands* (Duplicate,
# Archive, Delete), not links to other pages. See the "Navigation is not a menu"
# scenario below for the distinction and why it matters.
#
# **What it composes from.** `cw--menu` is a thin (under 90 lines) controller stacked
# on top of two already-shipped primitives: `cw--popover` supplies open/close, the
# top layer, light-dismiss, Escape-to-close, focus-return-to-invoker and placement —
# all from the native Popover API, zero JavaScript of its own; `cw--roving-focus`
# supplies Up/Down/Home/End, wrapping, and typeahead. `cw--menu` itself only moves
# focus into the panel on open, closes on activation for the right item roles, wires
# Tab/Shift+Tab to close rather than move between items, and rescues focus (R8) if
# the focused item is removed while open. The "compose your own" scenario below
# renders the resulting `data-controller="cw--popover cw--roving-focus"` stack on the
# panel explicitly — there is no wrapper hiding it.
#
# **Rule 0 note.** A list of navigation links is not a menu — `role="menu"` obligates
# you to remove every item from the Tab sequence and hand-implement everything a menu
# needs. If your items are links to other pages, reach for `cw.popover` with plain
# `<a>` elements and no `role="menu"` instead — see the "Navigation is not a menu"
# scenario, and `Crosswire::Presenters::Menu`'s own Rule 0 docstring.
class MenuPreview < Lookbook::Preview
  # The shipped partial, via `cw.menu`. `items:` is an ordered array of
  # `{ label:, href: nil, value: nil, role: "menuitem", checked: nil, disabled: false }`.
  #
  # @param placement select "~ [bottom-start, bottom-end, top-start, top-end]"
  def default(placement: "bottom-start")
    render_with_template(
      template: "menu_preview/default",
      locals: {placement: placement}
    )
  end

  # `cw.menu_for` yields the presenter and renders none of our markup. The panel
  # below carries `data-controller="cw--popover cw--roving-focus"` — both stacked on
  # one element, exactly what `Crosswire::Presenters::Menu#menu_attrs` builds — with
  # `cw--menu` itself on the wrapper, visible here with nothing hidden. Includes one
  # `button_to`-shaped destructive item, which `cw.menu`'s items: array deliberately
  # cannot express.
  def compose_your_own
    render_with_template(template: "menu_preview/compose_your_own")
  end

  # `menuitemcheckbox`/`menuitemradio` items toggle `aria-checked` on activation and
  # the menu stays OPEN — only a plain `menuitem` closes it. A `menuitemradio` group
  # (view density) plus a standalone `menuitemcheckbox` (show hidden files).
  def checkable_items
    render_with_template(template: "menu_preview/checkable_items")
  end

  # THE most valuable scenario here: the same visual dropdown button, built two ways.
  # Left is a list of links — `cw.popover` with plain `<a>` elements, no
  # `role="menu"` anywhere, and no `cw--menu` controller at all. Right is a list of
  # commands — `cw.menu`. Inspect both: the left one is not missing anything: APG's
  # own Disclosure Navigation pattern says the `menu` role is the WRONG choice for a
  # link list, because it doesn't give assistive technology the complex behaviour
  # that role promises. Most "accessible dropdown" tutorials on the web get this
  # backwards.
  def navigation_is_not_a_menu
    render_with_template(template: "menu_preview/navigation_is_not_a_menu")
  end
end
