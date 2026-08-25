# frozen_string_literal: true

module Crosswire
  module UI
    # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into
    # views directly — reach these through `cw.select`/`cw.select_for`/
    # `cw.select_attrs` (or the canonical `crosswire.` in place of `cw.`).
    #
    # `cw.select` deliberately SHADOWS `ActionView::Helpers::FormOptionsHelper#select`
    # inside `Crosswire::Builder` — see `Crosswire::UI::Select`'s own docstring for
    # the full explanation and why it is safe (scoped to `Builder`, does not affect a
    # bare `select(...)` call from a view or `FormBuilder`).
    module SelectHelper
      # Batteries-included form — renders the shipped partial. The `<option>`
      # elements are whatever the block writes; crosswire generates none of its own
      # (Rule 0 — see the class docstring).
      #
      #   <%= cw.select name: "country" do %>
      #     <option value="us">United States</option>
      #     <option value="ca" selected>Canada</option>
      #   <% end %>
      def select(**options, &block)
        presenter = Crosswire::UI::Select.new(**options)

        # The block is genuinely optional (an empty select, filled by a Turbo Frame,
        # is legal) — `capture(&nil)` raises, so guard rather than assume, same as
        # every other UI helper's block.
        render("crosswire/ui/select",
               select: presenter,
               content: (capture(&block) if block))
      end

      # Compose-it-yourself form — yields the presenter, renders no markup of ours.
      #
      #   <%= cw.select_for name: "country" do |s| %>
      #     <%= content_tag(:select, s.attrs) { "<option>...</option>".html_safe } %>
      #   <% end %>
      def select_for(**options, &block)
        capture(Crosswire::UI::Select.new(**options), &block)
      end

      # Returns the merged attribute hash — a plain Hash, ready for `cw_attrs` or a
      # tag call of your own.
      def select_attrs(**options)
        Crosswire::UI::Select.new(**options).attrs
      end
    end
  end
end
