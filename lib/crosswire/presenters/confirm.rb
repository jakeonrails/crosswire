# frozen_string_literal: true

require "crosswire/presenter"

module Crosswire
  module Presenters
    # WAI-ARIA APG: Alert and Message Dialogs (a confirmation is the canonical
    # alertdialog) — https://www.w3.org/WAI/ARIA/apg/patterns/alertdialog/
    #
    # A promise-returning replacement for `window.confirm`, built on the native
    # `<dialog>` element. Several of the requirements below correct widely-circulated
    # wrong advice, so read the whole docstring before wiring this up.
    #
    # Install as `Turbo.config.forms.confirm`:
    #
    #   Turbo.config.forms.confirm = (message, element, submitter) => {
    #     const controller = application.getControllerForElementAndIdentifier(
    #       document.getElementById("confirm"), "cw--confirm")
    #     return controller.open({ body: message })
    #   }
    #
    # NEVER `Turbo.setConfirmMethod()` — that API is deprecated, and its presence in a
    # tutorial is a reliable sign it predates Turbo 8.
    #
    # `data-turbo-confirm` is SILENTLY IGNORED on a plain `<a href>`. Turbo only reads
    # it on forms, and on links that also carry `data-turbo-method` (only those go
    # through Turbo's FormSubmission path). A plain link with `data-turbo-confirm`
    # alone does nothing at all — no error, no dialog, just a normal navigation. This
    # is the single most common silent failure reported for this attribute: if a
    # confirm isn't firing on a link, check for `data-turbo-method` first.
    #
    # `open()` returns a `Promise<boolean>` because that is the exact contract
    # `Turbo.config.forms.confirm` requires.
    #
    # TODO(compose): delegate to cw--dialog once both have landed. This presenter and
    # its controller currently implement their own minimal `<dialog>` plumbing —
    # open/close, focus save-and-restore — rather than composing with cw--dialog,
    # because cw--dialog is being built in parallel and may not exist yet. Light
    # dismiss is intentionally NOT offered either way: a confirmation should never be
    # dismissible by an accidental backdrop click.
    #
    # Unlike cw--dialog, open/closed is not modeled as a Stimulus value here: a
    # confirmation is always triggered dynamically after the page has already loaded,
    # never meaningfully part of the initial server-rendered HTML, so there is no
    # morph-survival requirement (R4) to satisfy the way there is for a dialog that can
    # legitimately start open on first paint.
    class Confirm < Presenter
      attr_reader :id, :title, :body, :confirm_label, :cancel_label, :destructive

      # @param id [String] base id; title, body and both buttons derive theirs from it
      # @param title [String] dialog heading — the default text. `open({ title })` can
      #   override it per call.
      # @param body [String] dialog body text — the default text. `open({ body })` can
      #   override it per call; this is what a `Turbo.config.forms.confirm(message)`
      #   integration passes through as `message`.
      # @param confirm_label [String] label of the affirmative button
      # @param cancel_label [String] label of the negative button
      # @param destructive [Boolean] the confirmed action is destructive. Per APG
      #   guidance to focus the least surprising, least destructive control, the
      #   controller focuses Cancel (not Confirm) when true. Also exposed through the
      #   CSS Classes API via `destructive_class` so the confirm button can be styled
      #   differently without the controller carrying a design-system opinion.
      # @param destructive_class [String, nil] class applied to the root while
      #   `destructive` is true
      # @param overrides [Hash] merged into the `<dialog>` element, last
      def initialize(id: "cw-confirm", title: "Are you sure?", body: "", confirm_label: "Confirm",
                     cancel_label: "Cancel", destructive: false, destructive_class: nil, **overrides)
        @id = id
        @title = title
        @body = body
        @confirm_label = confirm_label
        @cancel_label = cancel_label
        @destructive = !!destructive
        @destructive_class = destructive_class
        super(**overrides)
      end

      def title_id = "#{id}-title"
      def body_id  = "#{id}-body"

      def dialog_attrs(**extra)
        merge(
          controller_attrs,
          target(:dialog),
          values(
            title: title,
            body: body,
            confirm_label: confirm_label,
            cancel_label: cancel_label,
            destructive: destructive
          ),
          classes(destructive: @destructive_class),
          # `close` fires for every dialog close regardless of cause (our own
          # confirm()/cancel(), or the browser's default action after the native
          # `cancel` event on Escape) — the single path that resolves the promise. The
          # `cancel` event itself is only wired so Escape can be told apart from a
          # normal close in that one shared handler.
          action("cancel->cancel", "close->closed"),
          {
            "id" => id,
            "role" => "alertdialog",
            "aria-labelledby" => title_id,
            "aria-describedby" => body_id
          },
          overrides,
          extra
        )
      end

      def title_attrs(**extra)
        merge(target(:title), { "id" => title_id }, extra)
      end

      def body_attrs(**extra)
        merge(target(:body), { "id" => body_id }, extra)
      end

      def confirm_attrs(**extra)
        merge(
          target(:confirmButton),
          action("click->confirm"),
          { "type" => "button" },
          extra
        )
      end

      def cancel_attrs(**extra)
        merge(
          target(:cancelButton),
          action("click->cancel"),
          { "type" => "button" },
          extra
        )
      end
    end
  end
end
