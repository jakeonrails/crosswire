# frozen_string_literal: true

module Crosswire
  module UI
    # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into
    # views directly — reach these through `cw.alert`/`cw.alert_for`/`cw.alert_attrs`
    # (or the canonical `crosswire.` in place of `cw.`).
    module AlertHelper
      # Batteries-included form — renders the shipped partial.
      #
      #   <%= cw.alert "Draft saved.", severity: :success %>
      #   <%= cw.alert "Payment failed.", severity: :danger, dismissible: true %>
      #   <%= cw.alert severity: :info do %>Renews on <%= @plan.renews_on %>.<% end %>
      def alert(message = nil, **options, &block)
        presenter = Crosswire::UI::Alert.new(**options)

        # Optional block, same capture-guard reasoning as every other UI helper's
        # block (`capture(&nil)` raises) — `message` covers the common plain-text case.
        render("crosswire/ui/alert",
               alert: presenter,
               message: message,
               content: (capture(&block) if block))
      end

      # Compose-it-yourself form — yields the presenter, renders no markup of ours.
      #
      #   <%= cw.alert_for severity: :danger, dismissible: true do |a| %>
      #     <div <%= cw_attrs(a.root_attrs) %>>
      #       <div class="cw-alert__body">Payment failed.</div>
      #       <button <%= cw_attrs(a.dismiss_trigger_attrs) %>>&times;</button>
      #     </div>
      #   <% end %>
      def alert_for(**options, &block)
        capture(Crosswire::UI::Alert.new(**options), &block)
      end

      # Returns the merged ROOT attribute hash — a plain Hash, ready for `cw_attrs` or
      # a tag call of your own.
      def alert_attrs(**options)
        Crosswire::UI::Alert.new(**options).root_attrs
      end
    end
  end
end
