# frozen_string_literal: true

module Crosswire
  module UI
    # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into
    # views directly — reach these through `cw.toast`/`cw.toast_for`/`cw.toast_attrs`
    # (or the canonical `crosswire.` in place of `cw.`).
    #
    # Also carries `toast_viewport`/`toast_viewport_attrs` — the live-region CONTAINER
    # (`Crosswire::UI::ToastViewport`) toasts render or append into. It rides along on
    # this same module rather than a second registered component (spec §2's anatomy
    # rule: a UI-tier "component" is a caller-facing name with its own variants/CSS
    # knobs; the viewport has neither — see that class's own docstring) — the helper
    # TRIPLE the contract audit requires (`toast`/`toast_for`/`toast_attrs`) is exactly
    # the three methods below the viewport pair; nothing about carrying two extra
    # methods on the same module violates it.
    module ToastHelper
      # Batteries-included form — renders the shipped partial. See
      # `Crosswire::UI::Toast`'s own docstring for both rendering paths (inside
      # `cw.toast_viewport`'s block on first paint, or Turbo-Stream-appended later).
      #
      #   <%= cw.toast "Draft saved.", severity: :success %>
      #   <%= cw.toast "Upload failed.", severity: :danger, timeout: nil %>
      def toast(message = nil, **options, &block)
        presenter = Crosswire::UI::Toast.new(**options)

        render("crosswire/ui/toast",
               toast: presenter,
               message: message,
               content: (capture(&block) if block))
      end

      # Compose-it-yourself form — yields the presenter, renders no markup of ours.
      def toast_for(**options, &block)
        capture(Crosswire::UI::Toast.new(**options), &block)
      end

      # Returns the merged ROOT attribute hash — a plain Hash, ready for `cw_attrs` or
      # a tag call of your own.
      def toast_attrs(**options)
        Crosswire::UI::Toast.new(**options).root_attrs
      end

      # The live-region container — render ONCE per politeness level, before any toast
      # exists (`Crosswire::UI::ToastViewport`'s own docstring: "the aria-live rule
      # from the corpus"). Batteries-included: renders the shipped container partial,
      # `data-turbo-permanent` and all.
      #
      #   <%# app/views/layouts/application.html.erb, inside <body>, outside any frame %>
      #   <%= cw.toast_viewport %>
      #
      #   <%# server-rendered flash toasts on first paint — path 1, see Toast's docstring %>
      #   <%= cw.toast_viewport do %>
      #     <% flash.each { |type, message| cw.toast message, severity: severity_for(type) } %>
      #   <% end %>
      def toast_viewport(**options, &block)
        presenter = Crosswire::UI::ToastViewport.new(**options)

        render("crosswire/ui/toast_viewport",
               viewport: presenter,
               content: (capture(&block) if block))
      end

      # Returns the merged attribute hash for the container element — a plain Hash,
      # ready for `cw_attrs` or a tag call of your own.
      def toast_viewport_attrs(**options)
        Crosswire::UI::ToastViewport.new(**options).root_attrs
      end
    end
  end
end
