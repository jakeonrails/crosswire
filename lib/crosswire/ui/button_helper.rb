# frozen_string_literal: true

module Crosswire
  module UI
    # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into
    # views directly — reach these through `cw.button`/`cw.button_for`/`cw.button_attrs`
    # (or the canonical `crosswire.` in place of `cw.`), exactly like the primitive
    # tier's per-component helpers (app/helpers/crosswire/disclosure_helper.rb).
    module ButtonHelper
      # Batteries-included form — renders the shipped partial.
      #
      #   <%= cw.button "Save", variant: :primary %>
      #   <%= cw.button variant: :danger do %><svg>…</svg> Delete<% end %>
      #
      # RULE 0: this is markup and styling only. A button that submits a form or
      # navigates needs no JavaScript — pair it with `button_to`/`f.submit`/`link_to`,
      # or with `button_attrs` below for full control over the tag.
      def button(label = nil, **options, &block)
        presenter = Crosswire::UI::Button.new(**options)

        # The block is optional (most buttons are plain text) — `capture(&nil)` yields
        # with no block and raises LocalJumpError, so guard rather than assume, same
        # as `Crosswire::DisclosureHelper#disclosure`.
        render("crosswire/ui/button",
               button: presenter,
               label: label,
               content: (capture(&block) if block))
      end

      # Compose-it-yourself form — yields the presenter, renders no markup of ours.
      #
      #   <%= cw.button_for variant: :primary do |b| %>
      #     <%= content_tag(b.tag_name, b.attrs) { "Save" } %>
      #   <% end %>
      #
      # NOTE for the tag call above: `b.attrs` has STRING keys (`Crosswire::Attributes`
      # always produces flat, dashed string keys — "aria-disabled", not `:aria_disabled`)
      # so it must be passed as a plain Hash positional, never double-splatted into
      # `tag.a(**b.attrs)` — Ruby keyword-splat requires Symbol keys and raises
      # `TypeError: wrong argument type String (expected Symbol)` on a String-keyed
      # Hash. `content_tag(name, options_hash, &block)` (and `tag.attributes(hash)`,
      # what `cw_attrs` itself calls) both take that hash as an ordinary argument
      # instead, which is exactly why the shipped partial uses `content_tag` too.
      def button_for(**options, &block)
        capture(Crosswire::UI::Button.new(**options), &block)
      end

      # Returns the merged attribute hash — a plain Hash, ready for `cw_attrs` or
      # your own tag call. This is the `button_to`/`f.submit`/`link_to` integration
      # story (ui-tier-spec.md §2): no `cw.button_to` exists because Rails already
      # ships the real thing — just pass this as its `html_options` Hash (a plain
      # positional argument, same string-keys caveat as `button_for` above).
      #
      #   <%= link_to "Save", edit_path, cw.button_attrs(variant: :primary) %>
      #   <%= f.submit "Save", cw.button_attrs(variant: :primary).except("type") %>
      #   <!-- ("type" dropped since f.submit sets its own submit type) -->
      def button_attrs(**options)
        Crosswire::UI::Button.new(**options).attrs
      end
    end
  end
end
