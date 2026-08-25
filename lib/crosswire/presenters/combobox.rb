# frozen_string_literal: true

require "crosswire/presenter"
require "crosswire/presenters/click_outside"

module Crosswire
  module Presenters
    # WAI-ARIA APG: Combobox (with listbox popup, single autocomplete selection)
    # https://www.w3.org/WAI/ARIA/apg/patterns/combobox/
    #
    # RULE 0, read this first: three native controls beat this one, in order. (1) A
    # native `<select>` — for a short, fixed list where the user picks one of a
    # handful of known values. It ships keyboard navigation, typeahead, a native
    # mobile picker, real constraint validation and full form participation, for zero
    # JavaScript and zero markup of ours. Do not replace a `<select>` merely to
    # restyle it. (2) A `<datalist>` on a text input — for free text with
    # suggestions, where the *typed text itself* is the value being submitted. Also
    # zero JavaScript. (3) A plain search input plus a Turbo Frame rendering results
    # as ordinary links — for search, where the outcome is navigation rather than
    # filling in a field. That is not a combobox and must not carry
    # `role="combobox"`; a `role="status"` result count is the whole accessibility
    # story. Reach for this presenter only when all three of these are true: the
    # submitted value differs from the displayed text (records, not strings), the
    # list is long enough that filtering is the point, and the result must land in a
    # form field rather than navigate. If you want the batteries-included version of
    # exactly that, `hotwire_combobox` is excellent and well-maintained; this
    # presenter exists so the same pattern composes with the rest of crosswire and
    # can be ejected.
    #
    # ANTI-COMPOSITION, NOT AN OMISSION: this presenter deliberately does NOT compose
    # `cw--roving-focus`, even though "combobox = roving-focus + listbox" is the
    # obvious wrong guess — it is not merely unhelpful here, it is the wrong pattern
    # entirely. DOM focus never leaves the input; no option ever carries a
    # `tabindex`. APG's combobox pattern maintains the "active" option purely via
    # `aria-activedescendant` on the input, because the input has to keep receiving
    # every keystroke — a roving `tabindex` would move real DOM focus onto an option
    # and the input would stop receiving input. seanpdoyle/stimulus_aria_widgets
    # (research/notes/19) got the activedescendant bookkeeping itself right but
    # MISSED `aria-autocomplete` entirely — fixed here by making `autocomplete:` a
    # first-class option that is ALWAYS emitted, never conditional.
    #
    # `aria-controls` is emitted; `aria-owns` is not — APG prefers `aria-controls` for
    # this pattern, and `aria-owns` is an ARIA 1.0 relationship that dangles across a
    # remote frame reload swapping the listbox's children out from under it.
    # `aria-haspopup="listbox"` is emitted even though `role="combobox"` implies it —
    # the notes/19 lesson is about attributes that go MISSING, not about redundancy.
    #
    # `aria-activedescendant` is NEVER rendered server-side — it names transient
    # client-only navigation state (the same position `Crosswire::Presenters::Selection`
    # takes on `indeterminate`), set and removed entirely by the controller.
    #
    # FORM INTEGRATION: the visible `input` carries NO `name` — it holds DISPLAY text
    # ("California"), not the submitted VALUE (5), so it cannot be the field the form
    # submits (hotwire_combobox makes the same choice). A sibling `<input
    # type="hidden">` (the `field` target) carries the real value under `name:`, and
    # is the single thing this component ever submits. The Stimulus `value` value is
    # the one source of truth; the hidden input is a RENDERING of it, written by
    # exactly one path (`valueValueChanged`, R4) that a click, a keypress, a morph or
    # a server render all converge on. `disabled: true` disables BOTH inputs, and the
    # controller no-ops on every action while `field.matches(":disabled")` reads
    # true — which covers an ancestor `<fieldset disabled>` for free. Deliberately
    # not `field.disabled`: that IDL property reflects only the element's OWN
    # `disabled` attribute, per spec, and does NOT fold in an ancestor fieldset's
    # cascade — verified directly against both jsdom and a real browser, not
    # assumed. `:disabled` is the actual computed "is this control disabled"
    # concept the HTML spec defines for form participation.
    #
    # NATIVE CONSTRAINT VALIDATION IS NOT SUPPORTED IN v1 — hidden inputs are
    # explicitly excluded from the constraint validation API by the HTML spec, so
    # `required:` cannot mean what it means on a native `<select>` here; it only
    # emits `aria-required` for assistive technology. Validate server-side and
    # surface failures through `invalid:`/`described_by:` (`aria-invalid` /
    # `aria-describedby`). The escalation path, if you need real constraint
    # validation, is a form-associated custom element WRAPPING this same presenter's
    # attributes — the three-tier rule's own answer (crosswire-authoring §1) — not a
    # bigger controller.
    #
    # PRESELECTED VALUE (R4): `value:`/`display:` render all THREE representations
    # server-side — `data-cw--combobox-value-value` on the root, `value=` on the
    # hidden field, `value=` on the visible input (the display text), and
    # `aria-selected="true"` on the option whose value matches. This guards the exact
    # regression `tabs` hit (BUILD-LOG §3): a controller that only reads its
    # server-rendered value from ONE of several places is one refactor away from
    # reading `""` on connect and clobbering a correct page. `value:` is not a
    # required keyword, so `contract_audit_test.rb`'s rendered-values check cannot
    # catch a regression here on its own — browser test 19 is the guard.
    #
    # FILTERING — one `filter:` option, two real modes plus none. `"client"`
    # (default): options are server-rendered up front; the controller only hides
    # non-matching ones. `"remote"`: the controller debounces (`delay:`, default
    # 200ms — catalog's 250-350ms sweet spot, "below 150ms you're DoS-ing your own
    # database"; hotwire_combobox defaults 150) and writes `frameTarget.src`,
    # nothing else — there is NO fetch path in this controller. That is deliberate:
    # Turbo already cancels the previous frame request the instant a new `src` is
    # set, which is exactly the request-race problem a hand-rolled `fetch` would have
    # to solve itself; a frame request's `Accept` header asks for HTML, so the classic
    # Rails 406-on-JSON pitfall never arises; and — per D2 — the consumer owns the
    # endpoint, so parsing a response and handling CSRF has no business living in a
    # reusable controller (crosswire-authoring §1 routes exactly that shape to a
    # plain ES class, not a Stimulus controller). You cannot nest a second `<form>`
    # inside the record form this combobox usually lives in either, which rules out
    # the "search form targets a frame" idiom for anything living inside a real form —
    # writing `frame.src` directly is the only mechanism that works there. `"none"`:
    # no filtering at all, a select-shaped combobox over a short static list.
    #
    # R8a — FOUR ALT+ARROW DESCRIPTORS, NOT TWO: Stimulus key filters are
    # EXACT-MATCH on modifier state (docs/COMPONENT_CONTRACT.md R8a), so a bare
    # `keydown.down->down` would silently swallow Alt+ArrowDown rather than
    # delivering it — there is no filter that means "ArrowDown, with or without
    # Alt." `input_attrs` therefore wires all four: `keydown.down`, `keydown.alt+down`,
    # `keydown.up`, `keydown.alt+up`, each routed to the SAME `down`/`up` action,
    # which branches on `event.altKey` itself to tell "open, no active option" apart
    # from "open, active = first/last" and, when already open, "Alt+Up closes without
    # changing anything" apart from ordinary Up/Down movement.
    #
    # HOME/END DELIBERATELY NOT WIRED — a genuine divergence from this repo's own
    # catalog (research/notes/08-ui-pattern-catalog.md line 3526 says "Home/End
    # jump"), resolved in APG's favour as the source of truth over the catalog: APG
    # assigns Home/End to the TEXT CURSOR for an editable combobox, exactly like any
    # other text input, not to jumping the active option to the first/last visible
    # one. Wiring them here would silently break "move the caret to the start of
    # what I typed." Presenter test asserts their absence; `docs/recipes/corrections.md`
    # carries the correction.
    #
    # MORPH SAFETY (0.7) — `usePreserve` runs in `connect()`, guarding
    # `preservedValues = ["value", "expanded"]`, never `"active"` (transient
    # navigation state with no server-rendered counterpart at all — morph
    # legitimately invalidates it, same as `aria-activedescendant` itself).
    # `value` is preserved so a background stream render cannot silently revert a
    # choice the user already made (B2's divergence check: the SERVER still wins if
    # this controller has not actually written the value since the last sync — this
    # only stops morph from clobbering a write THIS controller made).
    # `expanded` is preserved so an unrelated stream landing elsewhere on the page
    # cannot collapse the listbox out from under someone mid-typing. KNOWN RESIDUAL,
    # documented rather than papered over: the characters the user has typed live in
    # the visible `input` element's `value` PROPERTY, and that element is a
    # DESCENDANT of the root this presenter's `usePreserve` guards —
    # `createMorphGuard`'s B1 per-element scoping (`event.target !== element`) means
    # a guard on the root cannot reach a descendant's property at all, by design, no
    # matter what values are listed. The correct fix is `crosswire/morph`'s own Rule
    # 0: narrow the SERVER-SIDE update's scope with
    # `turbo_stream.replace(target, method: :morph)` so the combobox subtree is never
    # the thing being morphed into in the first place. Controller browser tests 20/21
    # record what idiomorph is OBSERVED to do here, without the docstring or the test
    # claiming a guarantee the code does not make.
    #
    # RESERVED, NOT SHIPPED, NOT STUBBED (0.6): `multiple:` (a chip-based multiselect
    # combobox) and `name_when_new:` (hotwire_combobox's "create a new record from
    # free text" option) are both intentionally absent from this presenter's keyword
    # list — no dead kwarg sits here pretending to be wired up. Multiselect has no
    # APG pattern to build against at all (w3c/aria-practices#1512) and is a widget's
    # worth of surface (chip markup, chip removal keyboard model) on its own; free
    # text/"create new" needs two competing hidden fields plus association-creation
    # logic that D2 routes to the consuming application, not this gem. A caller who
    # needs chips today can build them over `cw.combobox_for` — `name:` is already
    # the submitted field name.
    #
    # Morph: Preserved
    #   DOM-only state: the selected `value` and whether the listbox is `expanded`.
    #     Unlike `Crosswire::Presenters::Popover`/`Menu`, this controller DOES declare
    #     ordinary Stimulus values for both (`value`/`expanded`, per `root_attrs`
    #     above), so there is a real attribute a morph could patch out from under a
    #     choice the user already made client-side.
    #   On morph: `static preservedValues = ["value", "expanded"]`, guarded by
    #     `usePreserve(this)` (called in `connect()`, AFTER the controller has
    #     re-rendered from its own values and flipped internal readiness — see the
    #     controller's own comment on that ordering) — the same `crosswire/morph`
    #     mechanism `cw--disclosure`/`cw--dialog`'s sibling primitives use. A
    #     divergence check (B2) means the SERVER still wins whenever this controller
    #     has not itself written a value since the last sync — the guard only stops a
    #     background morph from silently reverting a write THIS controller actually
    #     made. KNOWN RESIDUAL, documented rather than papered over: the characters the
    #     user has typed live in the visible `input` element's `value` PROPERTY, a
    #     DESCENDANT of the element `usePreserve` guards — `createMorphGuard`'s B1
    #     per-element scoping means a guard on the root cannot reach a descendant's
    #     property, by design, no matter what `preservedValues` lists.
    #     `aria-activedescendant`/the active option are correctly NOT preserved: they
    #     are transient client-only navigation state with no server-rendered
    #     counterpart, and morph legitimately invalidates them. Proven, not merely
    #     asserted, against real `@hotwired/turbo` in
    #     `test/js/combobox_controller.browser.test.js` (tests 20/21) — the docstring
    #     claims exactly what the code is observed to do, no more.
    #   The app must: narrow the SERVER-SIDE update's scope with
    #     `turbo_stream.replace(target, method: :morph)` so this combobox's own subtree
    #     is never the thing being morphed INTO — that is `crosswire/morph`'s own Rule
    #     0, and it is the only way to close the descendant-`value`-property residual
    #     above; `usePreserve` alone cannot reach it.
    class Combobox < Presenter
      FILTERS = %w[client remote none].freeze
      AUTOCOMPLETES = %w[none list both].freeze

      attr_reader :id, :name, :value, :display, :label, :expanded, :filter, :autocomplete,
                  :src, :param, :delay, :min_length, :wrap, :clear_on_escape, :open_on_focus,
                  :disabled, :invalid, :described_by, :required, :active_class, :expanded_class,
                  :results_message, :empty_message

      # @param id [String] required — base id every other element's id is derived from
      # @param name [String] required — the submitted field name, rendered on the
      #   HIDDEN input (`field_attrs`), never on the visible one (see class docstring)
      # @param value [String, nil] the preselected option's value — rendered THREE
      #   ways server-side (R4; see class docstring)
      # @param display [String, nil] the preselected option's display text
      # @param label [String, nil] rendered by the partial; `label_attrs` wires
      #   `for`/`id` regardless of whether the caller uses the partial
      # @param expanded [Boolean] server-rendered open state
      # @param filter [String] "client" (default) | "remote" | "none"
      # @param autocomplete [String] "none" | "list" (default) | "both" — ALWAYS
      #   emitted as `aria-autocomplete` (see class docstring)
      # @param src [String, nil] required when `filter: "remote"` — the Turbo Frame's
      #   source URL, sans the filter query param (added at request time)
      # @param param [String] query-param name written onto `src` when filtering remotely
      # @param delay [Numeric] remote-filter debounce, in milliseconds
      # @param min_length [Integer] remote filter fires no request below this query length
      # @param wrap [Boolean] arrow-key wrapping — a documented APG deviation
      # @param clear_on_escape [Boolean] second-stage Escape (closed + has text) clears
      #   the input and the value
      # @param open_on_focus [Boolean] adds `focus->open` to the input's actions
      # @param disabled [Boolean] disables BOTH the visible and hidden inputs
      # @param invalid [Boolean] emits `aria-invalid` on the input
      # @param described_by [String, nil] emits `aria-describedby` on the input
      # @param required [Boolean] emits `aria-required` — NOT native constraint
      #   validation (see class docstring)
      # @param active_class [String, nil] CSS Classes API — emitted on the ROOT even
      #   though applied to the active OPTION (R3a; see `root_attrs`)
      # @param expanded_class [String, nil] CSS Classes API, on the root
      # @param results_message [String] `%{count}`-interpolated live-region message
      #   after a client-side filter changes the match count
      # @param empty_message [String] live-region message when a filter matches nothing
      # @param overrides [Hash] merged into the root element, last
      # @raise [ArgumentError] `filter:`/`autocomplete:` outside their enumerated
      #   sets; `filter: "remote"` with no `src:`; `filter: "remote"` combined with
      #   `autocomplete: "both"` (inline completion against options that have not
      #   arrived yet — use `autocomplete: "list"` instead)
      def initialize(
        id:,
        name:,
        value: nil,
        display: nil,
        label: nil,
        expanded: false,
        filter: "client",
        autocomplete: "list",
        src: nil,
        param: "q",
        delay: 200,
        min_length: 0,
        wrap: true,
        clear_on_escape: true,
        open_on_focus: false,
        disabled: false,
        invalid: false,
        described_by: nil,
        required: false,
        active_class: nil,
        expanded_class: nil,
        results_message: "%{count} results available",
        empty_message: "No results available",
        **overrides
      )
        unless FILTERS.include?(filter)
          raise ArgumentError,
                "Crosswire::Presenters::Combobox#filter must be one of " \
                "#{FILTERS.join(", ")}, got #{filter.inspect}"
        end
        unless AUTOCOMPLETES.include?(autocomplete)
          raise ArgumentError,
                "Crosswire::Presenters::Combobox#autocomplete must be one of " \
                "#{AUTOCOMPLETES.join(", ")}, got #{autocomplete.inspect}"
        end
        if filter == "remote" && src.nil?
          raise ArgumentError,
                "Crosswire::Presenters::Combobox: a remote combobox needs somewhere " \
                "to fetch from — pass src:"
        end
        if filter == "remote" && autocomplete == "both"
          raise ArgumentError,
                "Crosswire::Presenters::Combobox: filter: \"remote\" with " \
                "autocomplete: \"both\" would inline-complete against options that " \
                "have not arrived yet — use autocomplete: \"list\" instead"
        end

        @id = id
        @name = name
        @value = value
        @display = display
        @label = label
        @expanded = !!expanded
        @filter = filter
        @autocomplete = autocomplete
        @src = src
        @param = param
        @delay = delay
        @min_length = min_length
        @wrap = !!wrap
        @clear_on_escape = !!clear_on_escape
        @open_on_focus = !!open_on_focus
        @disabled = !!disabled
        @invalid = !!invalid
        @described_by = described_by
        @required = !!required
        @active_class = active_class
        @expanded_class = expanded_class
        @results_message = results_message
        @empty_message = empty_message
        super(**overrides)
      end

      def input_id = "#{id}-input"
      def listbox_id = "#{id}-listbox"
      def label_id = "#{id}-label"
      def status_id = "#{id}-status"
      def frame_id = "#{id}-options"
      def option_id(value) = "#{id}-option-#{value}"

      # The wrapper — carries `cw--combobox` STACKED with `cw--click-outside` (R5a
      # mechanism 2: `expanded:` drives `click_outside`'s own `enabled:` at render
      # time; the controller keeps them in sync at runtime by writing
      # `data-cw--click-outside-enabled-value` directly from `expandedValueChanged`,
      # the exact external-write path R4 already guarantees works). `action(...)`
      # below reacts to click-outside's own already-namespaced event (R5a case 3) —
      # nothing here reimplements outside-dismissal.
      def root_attrs(**extra)
        merge(
          controller_attrs,
          values(
            value: value,
            expanded: expanded,
            filter: filter,
            autocomplete: autocomplete,
            src: src,
            param: param,
            delay: delay,
            min_length: min_length,
            wrap: wrap,
            clear_on_escape: clear_on_escape,
            results_message: results_message,
            empty_message: empty_message
          ),
          # R3a: `active_class` is APPLIED to an option target, but the Stimulus
          # Classes API always resolves `data-*-class` against the CONTROLLER's own
          # element, never a target — so it is emitted here, on the root, not from
          # `option_attrs`.
          classes(active: active_class, expanded: expanded_class),
          click_outside(expanded).root_attrs,
          action("cw--click-outside:clicked->close"),
          overrides,
          extra
        )
      end

      def label_attrs(**extra)
        merge(
          { "id" => label_id, "for" => input_id },
          extra
        )
      end

      def input_attrs(**extra)
        merge(
          target(:input),
          action(*input_actions),
          {
            "id" => input_id,
            "role" => "combobox",
            "aria-expanded" => expanded.to_s,
            "aria-controls" => listbox_id,
            "aria-haspopup" => "listbox",
            "aria-autocomplete" => autocomplete,
            # Native browser autocomplete/spellcheck/autocorrect UI would compete
            # with — and visually collide with — this component's own listbox.
            "autocomplete" => "off",
            "spellcheck" => "false",
            "autocapitalize" => "none",
            "autocorrect" => "off",
            "value" => display,
            "aria-invalid" => (invalid ? "true" : nil),
            "aria-required" => (required ? "true" : nil),
            "aria-describedby" => described_by,
            "disabled" => (disabled || nil)
          },
          extra
        )
      end

      # The submitted field (R4 — see class docstring's FORM INTEGRATION section).
      # The visible `input_attrs` above carries no `name` at all; this is the only
      # element this component ever submits.
      def field_attrs(**extra)
        merge(
          target(:field),
          {
            "type" => "hidden",
            "name" => name,
            "value" => value,
            "disabled" => (disabled || nil)
          },
          extra
        )
      end

      def listbox_attrs(**extra)
        merge(
          target(:listbox),
          {
            "id" => listbox_id,
            "role" => "listbox",
            "hidden" => !expanded,
            "aria-labelledby" => label_id
          },
          extra
        )
      end

      # @param value [String] required — read back by the controller's `select`
      #   action via `data-cw--combobox-value-param`
      # @param display [String, nil] the option's display text, read back the same way
      # @param selected [Boolean] whether this is the preselected option (matches
      #   this presenter's own `value:` — the partial computes this; a caller using
      #   `option_attrs` directly is free to pass it explicitly)
      # @param disabled [Boolean] emits `aria-disabled`
      #
      # Deliberately NO `tabindex` anywhere in this method, ever — see the class
      # docstring's ANTI-COMPOSITION note. DOM focus never leaves the input.
      def option_attrs(value:, display: nil, selected: false, disabled: false, **extra)
        merge(
          target(:option),
          action("click->select", "mousedown->preventBlur"),
          {
            "id" => option_id(value),
            "role" => "option",
            "aria-selected" => selected.to_s,
            "aria-disabled" => (disabled ? "true" : nil),
            "data-#{identifier}-value-param" => value,
            "data-#{identifier}-display-param" => display
          },
          extra
        )
      end

      # A live region, rendered server-side and present from FIRST PAINT — an
      # element that only gains `aria-live` after JavaScript writes to it is not
      # guaranteed by any spec to announce that very first write (the same lesson
      # `Crosswire::Presenters::Selection`'s docstring draws for `indeterminate`).
      def status_attrs(**extra)
        merge(
          target(:status),
          {
            "id" => status_id,
            "role" => "status",
            "aria-live" => "polite",
            "aria-atomic" => "true"
          },
          extra
        )
      end

      def empty_attrs(**extra)
        merge(
          target(:empty),
          { "hidden" => true },
          extra
        )
      end

      # Remote mode only — the Turbo Frame the controller writes `src` onto. No
      # `src` is emitted here; the frame starts empty and the controller supplies
      # one only once the user has actually typed something (see `min_length:`).
      def frame_attrs(**extra)
        merge(
          target(:frame),
          { "id" => frame_id },
          extra
        )
      end

      def clear_attrs(**extra)
        merge(
          action("click->clear"),
          { "type" => "button", "aria-label" => "Clear" },
          extra
        )
      end

      private

      def input_actions
        actions = [
          "input->filter",
          "keydown.down->down",
          "keydown.alt+down->down",
          "keydown.up->up",
          "keydown.alt+up->up",
          "keydown.esc->escape",
          "keydown.enter->enter",
          "keydown.tab->tabOut",
          "keydown.shift+tab->tabOut"
        ]
        actions << "focus->open" if open_on_focus
        actions
      end

      # A fresh, stateless `ClickOutside` per call — mirrors `Presenters::Menu`'s
      # identical `popover`/`roving_focus` private helpers.
      def click_outside(enabled)
        Presenters::ClickOutside.new(enabled: enabled)
      end
    end
  end
end
