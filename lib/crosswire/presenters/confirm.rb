# frozen_string_literal: true

require "crosswire/presenter"
require "crosswire/presenters/dialog"

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
    # COMPOSES WITH cw--dialog rather than reimplementing `<dialog>` plumbing:
    # `dialog_attrs` stacks both controllers on the single `<dialog>` element
    # (`data-controller="cw--dialog cw--confirm"`) by merging in a
    # `Crosswire::Presenters::Dialog` instance's `root_attrs` + `panel_attrs` — so the
    # native open/close, scroll lock, focus restore and `turbo:before-morph-element`
    # guard all come from cw--dialog, not from us. `dismissable` is fixed `false`: a
    # confirmation should never be dismissible by an accidental backdrop click. Confirm
    # owns only the promise, the buttons and the alertdialog semantics on top of that —
    # see the controller docstring for exactly how the two controllers talk to each
    # other (stacked-element values for the open request, `cw--dialog:opened` /
    # `cw--dialog:closed` events for the rest — never an outlet, per R5).
    #
    # Unlike cw--dialog, open/closed is not modeled as a Stimulus *value on cw--confirm
    # itself* here: a confirmation is always triggered dynamically after the page has
    # already loaded, never meaningfully part of the initial server-rendered HTML, so
    # there is no morph-survival requirement (R4) to satisfy the way there is for a
    # dialog that can legitimately start open on first paint. (cw--dialog's own `open`
    # value, which this delegates to, is always initialised `false` for the same
    # reason.)
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

      # The single `<dialog>` element carries BOTH controllers. `dialog.root_attrs`
      # supplies `cw--dialog`'s own `data-controller` + open/modal/dismissable values;
      # `dialog.panel_attrs` supplies its `panel` target, native `cancel`/`close`
      # wiring and the Turbo morph/cache guards. `controller_attrs` unions `cw--confirm`
      # into the same `data-controller`, so the result is
      # `data-controller="cw--dialog cw--confirm"` — stacked controllers on one
      # element, exactly per R5. `dismissable` is fixed `false`; `open` is always
      # initialised `false` (see class docstring).
      def dialog_attrs(**extra)
        dialog = Presenters::Dialog.new(id: id, open: false, modal: true, dismissable: false)

        merge(
          dialog.root_attrs,
          dialog.panel_attrs,
          controller_attrs,
          values(
            title: title,
            body: body,
            confirm_label: confirm_label,
            cancel_label: cancel_label,
            destructive: destructive
          ),
          classes(destructive: @destructive_class),
          # Inbound half of the composition: react to cw--dialog's own lifecycle
          # events rather than to the dialog's native cancel/close (those already
          # belong to cw--dialog, wired in via `panel_attrs` above). See the
          # controller docstring for the outbound half (how confirm asks cw--dialog
          # to open/close).
          action("cw--dialog:opened->opened", "cw--dialog:closed->closed"),
          {
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

      # Each button fires cw--confirm's own action first (recording the intended
      # result), then `cw--dialog#close` — the real close, with cw--dialog's own
      # cancelable `closing` pre-check, triggered by the same click. This is the
      # `action()` pass-through documented on `Presenter#action`: a spec containing
      # `#` wires a different controller by name rather than being auto-prefixed.
      def confirm_attrs(**extra)
        merge(
          target(:confirmButton),
          action("click->confirm", "click->cw--dialog#close"),
          { "type" => "button" },
          extra
        )
      end

      def cancel_attrs(**extra)
        merge(
          target(:cancelButton),
          action("click->cancel", "click->cw--dialog#close"),
          { "type" => "button" },
          extra
        )
      end
    end
  end
end
