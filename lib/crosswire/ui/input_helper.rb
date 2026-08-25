# frozen_string_literal: true

module Crosswire
  module UI
    # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into
    # views directly — reach these through `cw.input`/`cw.input_for`/`cw.input_attrs`
    # (or the canonical `crosswire.` in place of `cw.`).
    module InputHelper
      # Batteries-included form — renders the shipped partial.
      #
      #   <%= cw.input name: "email", type: "email", placeholder: "you@example.com" %>
      #   <%= cw.input name: "bio", multiline: true, value: @user.bio %>
      def input(value: nil, **options)
        presenter = Crosswire::UI::Input.new(value: value, **options)

        render("crosswire/ui/input", input: presenter)
      end

      # Compose-it-yourself form — yields the presenter, renders no markup of ours.
      #
      #   <%= cw.input_for size: :lg do |i| %>
      #     <%= content_tag(i.tag_name, i.attrs) %>
      #   <% end %>
      def input_for(**options, &block)
        capture(Crosswire::UI::Input.new(**options), &block)
      end

      # Returns the merged attribute hash — a plain Hash, ready for `cw_attrs` or a
      # tag call of your own.
      def input_attrs(**options)
        Crosswire::UI::Input.new(**options).attrs
      end
    end
  end
end
