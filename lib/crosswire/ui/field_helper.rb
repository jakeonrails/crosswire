# frozen_string_literal: true

module Crosswire
  module UI
    # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into
    # views directly — reach these through `cw.field`/`cw.field_for`/`cw.field_attrs`
    # (or the canonical `crosswire.` in place of `cw.`).
    module FieldHelper
      # Batteries-included form — renders the shipped partial, composing `cw.input`
      # as the control by default. Pass `control:` to forward extra options straight
      # to that `cw.input` call (e.g. `type:`, `placeholder:`) — anything crosswire's
      # own wiring (`id`, `aria-describedby`, `aria-errormessage`, `aria-invalid`)
      # already set is NOT among them, so there is nothing for `control:` to clobber.
      #
      #   <%= cw.field "Email", id: "email", hint: "We'll never share this",
      #                control: { type: "email" } %>
      #   <%= cw.field "Password", id: "pw", error: @user.errors[:password].first,
      #                control: { type: "password" } %>
      #
      # For anything other than a plain `cw.input` — a `cw.select`, a `<textarea>`, a
      # hand-rolled radio group — pass a block instead; see `field_for` below, which
      # this delegates to.
      def field(label = nil, hint: nil, error: nil, control: {}, **options, &block)
        presenter = Crosswire::UI::Field.new(hint: hint, error: error, **options)

        control_html = if block
          capture(presenter, &block)
        else
          input(**presenter.control_attrs.merge(control))
        end

        render("crosswire/ui/field",
               field: presenter,
               label: label,
               control: control_html)
      end

      # Compose-it-yourself form — yields the presenter, renders no control of ours.
      # `f.control_attrs` is safe to double-splat into ANY `cw.<control>` helper
      # (see `Crosswire::UI::Field#control_attrs`'s own docstring for why it stays
      # Symbol-keyed).
      #
      #   <%= cw.field_for id: "country", error: @user.errors[:country].first do |f| %>
      #     <%= cw.select(**f.control_attrs) do %>
      #       <option value="us">United States</option>
      #     <% end %>
      #   <% end %>
      def field_for(hint: nil, error: nil, **options, &block)
        capture(Crosswire::UI::Field.new(hint: hint, error: error, **options), &block)
      end

      # Returns the merged ROOT (wrapper) attribute hash — a plain Hash, ready for
      # `cw_attrs` or a tag call of your own. Reach for `field_for` when you need the
      # label/hint/error attribute hashes too.
      def field_attrs(hint: nil, error: nil, **options)
        Crosswire::UI::Field.new(hint: hint, error: error, **options).root_attrs
      end
    end
  end
end
