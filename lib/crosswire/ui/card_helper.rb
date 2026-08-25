# frozen_string_literal: true

module Crosswire
  module UI
    # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into
    # views directly — reach these through `cw.card`/`cw.card_for`/`cw.card_attrs`
    # (or the canonical `crosswire.` in place of `cw.`).
    module CardHelper
      # Batteries-included form — renders the shipped partial. The block yields a
      # `Crosswire::UI::Slots` builder (header/body/footer); naming no slot at all
      # (the "arity-0 shorthand") makes the whole block the body — see
      # `Crosswire::UI::Slots`' own docstring for the single code path this relies on.
      #
      #   <%= cw.card variant: :raised do |c| %>
      #     <% c.header { "Plan" } %>
      #     <% c.body { "Everything in Free, plus…" } %>
      #     <% c.footer { cw.button "Upgrade", variant: :primary } %>
      #   <% end %>
      #
      #   <%= cw.card { "No header or footer needed." } %>
      def card(**options, &block)
        presenter = Crosswire::UI::Card.new(**options)
        slots = Crosswire::UI::Slots.new(view_context: self)

        # `capture(&nil)` raises — the block is optional (an empty card is legal, if
        # unusual), so guard rather than assume, same as every other UI helper's
        # block. `block.call(slots)` (not `capture(&block)` directly) is what lets a
        # zero-arg block still work: Ruby procs silently ignore an argument they never
        # declared a parameter for, so `do ... end` and `do |c| ... end` both work
        # through the exact same call.
        whole = capture { block.call(slots) } if block
        body = slots[:body] || (slots.any? ? nil : whole)

        render("crosswire/ui/card",
               card: presenter,
               header: slots[:header],
               body: body,
               footer: slots[:footer])
      end

      # Compose-it-yourself form — yields the presenter, renders no markup of ours.
      #
      #   <%= cw.card_for variant: :outlined do |c| %>
      #     <div <%= cw_attrs(c.root_attrs) %>>
      #       <div <%= cw_attrs(c.body_attrs) %>>Hand-rolled body.</div>
      #     </div>
      #   <% end %>
      def card_for(**options, &block)
        capture(Crosswire::UI::Card.new(**options), &block)
      end

      # Returns the merged ROOT attribute hash — a plain Hash, ready for `cw_attrs` or
      # a tag call of your own. Slots have no `_attrs` equivalent of their own (there
      # is no single element to hand back for "the header") — reach for `card_for`
      # instead when you need that level of control.
      def card_attrs(**options)
        Crosswire::UI::Card.new(**options).root_attrs
      end
    end
  end
end
