# frozen_string_literal: true

require "crosswire/ui"

module Crosswire
  # The single entry point for crosswire's helper surface — modeled on
  # `Turbo::Streams::TagBuilder` (turbo-rails) and Rails' own `tag.`/`translate`-`t`
  # idiom, rather than mixing ~90 flat `crosswire_<name>[_for|_attrs]` methods into
  # every view. See docs/DECISIONS.md D8 for the full rationale.
  #
  #   <%= cw.disclosure "Shipping details", id: "shipping" do %>...<% end %>
  #   <%= cw.disclosure_for id: "faq-1" do |d| %>...<% end %>
  #   <%= tag.div **cw.disclosure_attrs(id: "x") %>
  #   <%= cw.stream_from @board, channel: BoardChannel %>
  #
  # Reached from a view through the `crosswire` / `cw` facade helper
  # (app/helpers/crosswire/facade_helper.rb) — never instantiated directly by a
  # consumer. One instance per view render, memoized there, exactly the way
  # `ActionView::Helpers::TagHelper#tag` and Turbo's own `turbo_stream` are.
  #
  # Deliberately a plain Ruby class with no Rails requires of its own — this file is
  # never on `lib/crosswire.rb`'s eager Rails-free require list (unlike the presenters),
  # and is loaded exactly once, lazily, the first time `app/helpers/crosswire/
  # facade_helper.rb` is loaded (which only happens inside a booted Rails app, well
  # after Zeitwerk is active — see that file's own comment for why the timing matters).
  #
  # Every per-component helper module (app/helpers/crosswire/<name>_helper.rb) is
  # included HERE, not into views — the modules themselves are unmodified Ruby, still
  # calling `render`, `capture`, `tag`, `turbo_stream`, etc. as though `self` were the
  # view context. That still works, unchanged, because `#method_missing` below forwards
  # anything Builder itself doesn't define to the real view context — the same
  # delegate-what-you-don't-recognize shape `Turbo::Streams::TagBuilder` uses for
  # `render`/`capture` inside `render_template`.
  class Builder
    # A dependency-free `"focus_trap".camelize => "FocusTrap"` — deliberately NOT
    # `ActiveSupport::Inflector#camelize`. This class body runs the `include` loop
    # below at load time, and `test/crosswire/contract_audit_test.rb` (docs/DECISIONS.md
    # D5's plain-Ruby, no-Rails suite) loads this very file to assert every component
    # helper is included here — ActiveSupport is not on its load path, so leaning on
    # `String#camelize` would make this file quietly Rails-only despite the docstring
    # above promising otherwise. Mirrors the identical local `camelize` in
    # contract_audit_test.rb itself, for the same reason.
    def self.camelize(name)
      name.to_s.split("_").map { |part| part[0].upcase + part[1..] }.join
    end
    private_class_method :camelize

    Crosswire.component_names.each do |name|
      include Crosswire.const_get(:"#{camelize(name)}Helper")
    end
    include Crosswire::StreamsHelper

    # The UI tier's equivalent of the loop above — included from `Crosswire::UI`,
    # not `Crosswire`, and from a module living under `Crosswire::UI::<Name>Helper`
    # (lib/crosswire/ui/<name>_helper.rb), not `app/helpers/`, per the UI-tier spec §2.
    # `Crosswire::UI::COMPONENTS` is empty through Phase 0 (spec §10), so this is a
    # true no-op today — zero iterations, nothing included — but it is real, exercised
    # code: `test/crosswire/ui_contract_audit_test.rb` walks
    # `Crosswire::UI.component_names` and asserts each one's helper module actually
    # landed in `Crosswire::Builder.ancestors`, so the very first UI component to add
    # a name here is checked by the same mechanism the primitive tier already trusts,
    # not by a promise that this loop would have worked.
    Crosswire::UI.component_names.each do |name|
      include Crosswire::UI.const_get(:"#{camelize(name)}Helper")
    end

    # Names a consumer might reasonably reach for that crosswire deliberately does NOT
    # ship as one primitive (docs/COMPONENT_CONTRACT.md "Banned as primitive names" —
    # `modal`, `dropdown`, `tooltip`, … describe a feature, not a behaviour). Rather than
    # a bare NoMethodError, `method_missing` below teaches the composition.
    COMPOSITE_HINTS = {
      modal: "a modal is dialog + focus-trap + scroll-lock + dismiss + transition, " \
             "composed on one element — see cw.dialog for the batteries-included form, " \
             "or cw.dialog_for to compose the pieces yourself.",
      dropdown: "\"dropdown\" is two different widgets depending on what's inside: " \
                "navigation links to other pages are cw.popover with plain <a> " \
                "elements and NO role=\"menu\" (APG's Disclosure Navigation example " \
                "says the menu role is wrong for a link list); a list of commands " \
                "(Duplicate, Archive, Delete) is cw.menu, which composes popover + " \
                "roving-focus + the role=\"menu\" semantics for you. See " \
                "Crosswire::Presenters::Menu's Rule 0 before reaching for either.",
      tooltip: "crosswire ships no tooltip primitive (see docs/COMPONENT_CONTRACT.md " \
               "R9, Rule 0) — the native `title` attribute or a CSS-only " \
               "`popover`/anchor-positioning pattern covers most cases with no JS at all."
    }.freeze

    def initialize(view_context)
      @view_context = view_context
    end

    def inspect = "#<Crosswire::Builder view_context=#{@view_context.class}>"

    private

    attr_reader :view_context

    def method_missing(name, ...)
      return view_context.public_send(name, ...) if view_context.respond_to?(name)

      raise NoMethodError, unknown_method_message(name)
    end

    def respond_to_missing?(name, include_private = false)
      view_context.respond_to?(name, include_private) || super
    end

    def unknown_method_message(name)
      base = name.to_s.sub(/_(?:for|attrs)\z/, "").to_sym
      hint = COMPOSITE_HINTS[base]

      return "Crosswire::Builder has no `#{name}` — no primitive `#{base}`; #{hint}" if hint

      "undefined method `#{name}' for #{inspect} — known crosswire primitives: " \
        "#{Crosswire.component_names.join(", ")} (each as <name>_for/<name>_attrs, " \
        "plus the bare <name> render form for components that ship a partial), and " \
        "stream_from/version_attrs/versioned_replace. #{view_context.class} does not " \
        "define `#{name}` either."
    end
  end
end
