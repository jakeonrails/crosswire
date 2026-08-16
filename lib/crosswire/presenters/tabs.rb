# frozen_string_literal: true

require "crosswire/presenter"
require "crosswire/presenters/roving_focus"

module Crosswire
  module Presenters
    # WAI-ARIA APG: Tabs
    # https://www.w3.org/WAI/ARIA/apg/patterns/tabs/
    #
    # Full tablist/tab/tabpanel roles, `aria-selected`, `aria-controls`,
    # `aria-labelledby`, and the roving tabindex that keeps arrow-key navigation
    # correct — every ARIA relationship a screen reader needs lives here, not in the
    # partial (R2), so an ejected or restyled copy keeps them all.
    #
    # COMPOSES WITH cw--roving-focus by STACKING controllers on a shared root
    # element (`data-controller="cw--roving-focus cw--tabs"`, built in `root_attrs`
    # below — see that method's docstring for why the root has to wrap the tablist
    # AND every panel, not just the tablist) rather than reimplementing arrow-key
    # navigation (R5a) — this is the entire reason `roving-focus` was built first.
    # Every `tab` is ALSO a roving-focus `item` (see `tab_attrs`), so
    # Left/Right/Home/End all come from `cw--roving-focus` for free; this
    # presenter/controller pair owns only selection state, panel visibility, and
    # the optional URL sync. See the controller docstring for exactly how the two
    # talk to each other: `cw--roving-focus:moved` in (via the presenter's
    # `action()` pass-through) to implement "automatic" activation, nothing at all
    # out (a plain click or Enter/Space on a tab is a real DOM event, so it needs
    # no cross-controller plumbing per R5a case 1).
    #
    # A caller using `root_attrs`/`tablist_attrs`/`tab_attrs`/`panel_attrs`
    # directly (the `_for` helper form) must render `root_attrs` on an element that
    # is an ANCESTOR of both the tablist and every panel — see `_tabs.html.erb` for
    # the shipped shape.
    #
    # RULE 0 NOTE: there is no native tabs element, so this presenter is not "the
    # zero-JS answer" the way `disclosure`/`dialog`/`popover` are. If your panels
    # are cheap, server-rendered HTML swapped over the network on each click,
    # prefer the Turbo-Frame "tier (b)" recipe in research/notes/08-ui-pattern-
    # catalog.md instead: `roving-focus` alone, no `tabs` controller at all — a real
    # `<a href>` per tab, the frame supplies `aria-selected` server-side on every
    # navigation, and the URL is simply the link's own href, no client-side sync
    # needed. Reach for THIS presenter for tier (c): small panels, all pre-rendered,
    # that must switch instantly with no round trip — which is also exactly why its
    # default `activation` is "automatic" (see below): APG recommends automatic
    # activation specifically when panel content has no perceptible latency.
    class Tabs < Presenter
      attr_reader :id, :selected, :activation, :param

      # @param id [String] base id namespacing every tab/panel pair this instance
      #   generates ids from
      # @param selected [String, Symbol, Integer] the currently selected tab's
      #   identifier — compared to each `tab_attrs(tab_id:)` / `panel_attrs(tab_id:)`
      #   call's own `tab_id` via `#to_s`, so String, Symbol or Integer identifiers
      #   all work interchangeably. Rendered server-side (R4), so the right tab and
      #   panel are correct before JavaScript loads and survive a Turbo morph.
      # @param activation [String] "automatic" (default) — moving focus with arrow
      #   keys selects the tab immediately, per APG's guidance for panels that
      #   switch with no perceptible latency (see Rule 0 note above). "manual" —
      #   arrow keys move focus only, Enter/Space selects. Prefer "manual" if
      #   selecting a tab is ever expensive.
      # @param param [String, nil] query-param name to keep in sync with the
      #   selected tab via `history.replaceState` — see the controller docstring
      #   for why not Turbo Frame history. Omit for no URL sync.
      # @param overrides [Hash] merged into the root element (see `root_attrs`), last
      def initialize(id:, selected:, activation: "automatic", param: nil, **overrides)
        @id = id
        @selected = selected.to_s
        @activation = activation
        @param = param
        super(**overrides)
      end

      def tab_id(tab_id) = "#{id}-tab-#{tab_id}"
      def panel_id(tab_id) = "#{id}-panel-#{tab_id}"

      # Wraps the tablist AND every panel — unlike `disclosure`/`dialog`, whose
      # panel sits INSIDE the same element as the trigger, tabs are Stimulus
      # targets shared between two stacked controllers (`tab`/`panel` for
      # `cw--tabs`, `item` for `cw--roving-focus`), and Stimulus scopes a
      # controller's targets to descendants of the element carrying its own
      # `data-controller` — so both controllers must sit on a common ancestor of
      # every tab AND every panel, not merely of the tablist.
      #
      # `keydown->cw--roving-focus#navigate` deliberately does NOT live here — see
      # `tablist_attrs` — because Stimulus binds an action listener to the exact
      # element carrying it, not to the whole controller subtree. Scoping it to the
      # tablist specifically (rather than this wider root) means arrow keys typed
      # inside a panel's own form fields are never mistaken for tab navigation.
      def root_attrs(**extra)
        merge(
          roving_focus.state_attrs,
          controller_attrs,
          values(activation: activation, param: param),
          # Inbound half of the composition (R5a case 3): react to roving-focus's
          # own `moved` event to implement "automatic" activation. There is no
          # outbound half — see the class docstring.
          action("cw--roving-focus:moved->selectFromMove"),
          overrides,
          extra
        )
      end

      def tablist_attrs(**extra)
        merge(
          roving_focus.action_attrs,
          { "role" => "tablist" },
          extra
        )
      end

      def tab_attrs(tab_id:, **extra)
        tab_id = tab_id.to_s
        current = tab_id == selected

        merge(
          # Every tab IS a roving-focus item — this is what "stacking" means at the
          # element level, not just the controller level: one <button> carries both
          # `data-cw--roving-focus-target="item"` (tabindex bookkeeping, owned
          # entirely by roving-focus from here on) and `data-cw--tabs-target="tab"`
          # below (aria-selected, owned by this controller). Neither controller
          # touches the attribute the other owns.
          roving_focus.item_attrs(current: current),
          target(:tab),
          # Click always selects a tab, in either activation mode — the
          # "automatic"/"manual" distinction only concerns ARROW-KEY-driven focus
          # movement, never a direct activation gesture. keydown.space is required
          # in addition to click for role="tab" on an `<a href>`, which only
          # responds to Enter natively (research/notes/08 "Pitfalls").
          action("click->select", "keydown.enter->select", "keydown.space->select"),
          {
            "id" => self.tab_id(tab_id),
            "role" => "tab",
            "aria-selected" => current.to_s,
            "aria-controls" => panel_id(tab_id),
            "data-cw--tabs-id-param" => tab_id
          },
          extra
        )
      end

      def panel_attrs(tab_id:, **extra)
        tab_id = tab_id.to_s
        current = tab_id == selected

        merge(
          target(:panel),
          {
            "id" => panel_id(tab_id),
            "role" => "tabpanel",
            "aria-labelledby" => self.tab_id(tab_id),
            # Always focusable: APG requires a tabpanel to be reachable via Tab
            # after leaving the tablist even when its content holds nothing
            # inherently focusable of its own.
            "tabindex" => "0",
            "hidden" => !current
          },
          extra
        )
      end

      private

      # A fresh, stateless RovingFocus instance per call is cheap and keeps this
      # presenter from duplicating roving-focus's own attribute logic. Horizontal
      # orientation is fixed rather than exposed as an option: every APG tabs
      # example is Left/Right, and a caller who genuinely needs vertical tabs can
      # compose `cw--roving-focus` directly instead of through this presenter.
      def roving_focus
        Presenters::RovingFocus.new(orientation: "horizontal")
      end
    end
  end
end
