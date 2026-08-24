# frozen_string_literal: true

module Crosswire
  module UI
    # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into
    # views directly — reach these through `cw.badge`/`cw.badge_for`/`cw.badge_attrs`
    # (or the canonical `crosswire.` in place of `cw.`).
    module BadgeHelper
      # Batteries-included form — renders the shipped partial.
      #
      #   <%= cw.badge "Active", variant: :success, dot: true %>
      #   <%= cw.badge variant: :accent do %><svg>…</svg> New<% end %>
      def badge(label = nil, **options, &block)
        presenter = Crosswire::UI::Badge.new(**options)

        # Optional block, same capture-guard reasoning as `Crosswire::UI::ButtonHelper#button`
        # and `Crosswire::DisclosureHelper#disclosure` — `capture(&nil)` raises.
        render("crosswire/ui/badge",
               badge: presenter,
               label: label,
               content: (capture(&block) if block))
      end

      # Compose-it-yourself form — yields the presenter, renders no markup of ours.
      #
      #   <%= cw.badge_for variant: :danger do |b| %>
      #     <span <%= cw_attrs(b.attrs) %>>Overdue</span>
      #   <% end %>
      def badge_for(**options, &block)
        capture(Crosswire::UI::Badge.new(**options), &block)
      end

      # Returns the merged attribute hash — a plain Hash, ready for `cw_attrs` or a
      # tag call of your own.
      #
      #   <span <%= cw_attrs(cw.badge_attrs(variant: :warning)) %>>Pending</span>
      def badge_attrs(**options)
        Crosswire::UI::Badge.new(**options).attrs
      end
    end
  end
end
