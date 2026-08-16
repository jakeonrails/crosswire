import { Application } from "@hotwired/stimulus"
import { afterEach, describe, expect, test, vi } from "vitest"
import ConfirmController from "../../app/assets/javascripts/crosswire/controllers/confirm_controller.js"
import DialogController from "../../app/assets/javascripts/crosswire/controllers/dialog_controller.js"
import { captureEvents, nextFrame } from "./setup.js"

// TIER: jsdom. Everything here exercises cw--confirm's OWN logic — the promise, the
// buttons, alertdialog semantics, and (per this file's very purpose) that it delegates
// rather than reimplements. It deliberately does NOT re-prove cw--dialog's own
// showModal()/top-layer/inertness behaviour — that belongs to dialog_controller.test.js
// and dialog_controller.browser.test.js, owned by a sibling agent. What's proven here
// instead is that cw--confirm never touches `<dialog>` itself: every open/close is
// routed through the polyfilled panel methods below, which only cw--dialog calls.
//
// jsdom implements HTMLDialogElement's `.open` reflection but not
// showModal()/show()/close() at all (see dialog_controller.test.js's own note), so the
// same minimal, spec-shaped polyfill is installed here, before Stimulus's first
// connect() — matching what a real browser already provides at that point.
function polyfillDialog(panel) {
  panel.showModal = vi.fn(function showModal() {
    if (this.open) throw new DOMException("already open", "InvalidStateError")
    this.setAttribute("open", "")
  })
  panel.show = vi.fn(function show() {
    this.setAttribute("open", "")
  })
  panel.close = vi.fn(function close() {
    if (!this.open) return
    this.removeAttribute("open")
    this.dispatchEvent(new Event("close"))
  })
  panel.matches = panel.matches || (() => false)
  return panel
}

// Mirrors what Crosswire::Presenters::Confirm#dialog_attrs (composed with
// Crosswire::Presenters::Dialog) renders: ONE <dialog> element stacking both
// controllers, per docs/COMPONENT_CONTRACT.md R5 — never a Stimulus outlet.
function markup({ destructive = null } = {}) {
  return `
    <dialog id="cw-confirm"
            role="alertdialog"
            aria-labelledby="cw-confirm-title"
            aria-describedby="cw-confirm-body"
            data-controller="cw--dialog cw--confirm"
            data-cw--dialog-target="panel"
            data-cw--dialog-open-value="false"
            data-cw--dialog-modal-value="true"
            data-cw--dialog-dismissable-value="false"
            data-cw--confirm-title-value="Are you sure?"
            data-cw--confirm-body-value="This cannot be undone."
            data-cw--confirm-confirm-label-value="Confirm"
            data-cw--confirm-cancel-label-value="Cancel"
            ${destructive !== null ? `data-cw--confirm-destructive-value="${destructive}"` : ""}
            data-action="close->cw--dialog#syncClosed cancel->cw--dialog#cancel click->cw--dialog#backdropClick turbo:before-morph-element->cw--dialog#beforeMorph turbo:before-cache->cw--dialog#reset cw--dialog:opened->cw--confirm#opened cw--dialog:closed->cw--confirm#closed">
      <h2 data-cw--confirm-target="title" id="cw-confirm-title">Are you sure?</h2>
      <p data-cw--confirm-target="body" id="cw-confirm-body">This cannot be undone.</p>
      <div class="cw-confirm__actions">
        <button data-cw--confirm-target="cancelButton"
                data-action="click->cw--confirm#cancel click->cw--dialog#close"
                type="button">Cancel</button>
        <button data-cw--confirm-target="confirmButton"
                data-action="click->cw--confirm#confirm click->cw--dialog#close"
                type="button">Confirm</button>
      </div>
    </dialog>`
}

// A local, hand-rolled mount — needed for the same reason as dialog_controller.test.js's
// `mountDialog`: the polyfill above MUST be installed before Stimulus's first connect().
let app

function mountConfirm(opts = {}) {
  document.body.innerHTML = markup(opts)
  const el = document.body.firstElementChild
  polyfillDialog(el)

  app = Application.start()
  app.register("cw--dialog", DialogController)
  app.register("cw--confirm", ConfirmController)

  return nextFrame().then(() => ({
    el,
    confirmButton: el.querySelector("[data-cw--confirm-target='confirmButton']"),
    cancelButton: el.querySelector("[data-cw--confirm-target='cancelButton']")
  }))
}

afterEach(() => {
  app?.stop()
  app = undefined
})

describe("cw--confirm", () => {
  // --- the promise ------------------------------------------------------------------

  test("resolves true when Confirm is clicked", async () => {
    const { el, confirmButton } = await mountConfirm()
    const confirmController = app.getControllerForElementAndIdentifier(el, "cw--confirm")
    const pending = confirmController.open()
    await nextFrame()

    confirmButton.click()
    await nextFrame()

    await expect(pending).resolves.toBe(true)
  })

  test("resolves false when Cancel is clicked", async () => {
    const { el, cancelButton } = await mountConfirm()
    const confirmController = app.getControllerForElementAndIdentifier(el, "cw--confirm")
    const pending = confirmController.open()
    await nextFrame()

    cancelButton.click()
    await nextFrame()

    await expect(pending).resolves.toBe(false)
  })

  // Escape is handled entirely by cw--dialog (native `cancel` then `close`); cw--confirm
  // never sees a native event at all, only `cw--dialog:closed`. Simulated the same way
  // dialog_controller.test.js simulates it: the browser closes the dialog itself, then
  // fires `close` — no action method of cw--dialog's own runs first.
  test("resolves false on Escape", async () => {
    const { el } = await mountConfirm()
    const confirmController = app.getControllerForElementAndIdentifier(el, "cw--confirm")
    const pending = confirmController.open()
    await nextFrame()

    el.removeAttribute("open")
    el.dispatchEvent(new Event("close"))
    await nextFrame()

    await expect(pending).resolves.toBe(false)
  })

  // --- events -------------------------------------------------------------------------

  test("dispatches cw--confirm:opened once cw--dialog has actually opened", async () => {
    const opened = captureEvents("cw--confirm:opened")
    const { el } = await mountConfirm()
    const confirmController = app.getControllerForElementAndIdentifier(el, "cw--confirm")

    confirmController.open()
    await nextFrame()

    expect(opened).toHaveLength(1)
  })

  test("dispatches cw--confirm:resolved with detail.confirmed on confirm", async () => {
    const resolved = captureEvents("cw--confirm:resolved")
    const { el, confirmButton } = await mountConfirm()
    const confirmController = app.getControllerForElementAndIdentifier(el, "cw--confirm")

    confirmController.open()
    await nextFrame()
    confirmButton.click()
    await nextFrame()

    expect(resolved).toHaveLength(1)
    expect(resolved[0].detail.confirmed).toBe(true)
  })

  test("dispatches cw--confirm:resolved with detail.confirmed false on cancel", async () => {
    const resolved = captureEvents("cw--confirm:resolved")
    const { el, cancelButton } = await mountConfirm()
    const confirmController = app.getControllerForElementAndIdentifier(el, "cw--confirm")

    confirmController.open()
    await nextFrame()
    cancelButton.click()
    await nextFrame()

    expect(resolved).toHaveLength(1)
    expect(resolved[0].detail.confirmed).toBe(false)
  })

  // --- delegates to cw--dialog, does not reimplement it -------------------------------

  test("opening calls cw--dialog's showModal, not a direct call of its own", async () => {
    const { el } = await mountConfirm()
    const confirmController = app.getControllerForElementAndIdentifier(el, "cw--confirm")

    expect(el.showModal).not.toHaveBeenCalled()
    confirmController.open()
    await nextFrame()

    // The only showModal on this element is the one cw--dialog's own #render calls;
    // cw--confirm has no dialog target and no showModal()/close() call of its own —
    // it only ever writes cw--dialog's `open` value and reacts to its events.
    expect(el.showModal).toHaveBeenCalledTimes(1)
    expect(el.open).toBe(true)
  })

  test("confirming closes via cw--dialog's close(), not a direct native close", async () => {
    const { el, confirmButton } = await mountConfirm()
    const confirmController = app.getControllerForElementAndIdentifier(el, "cw--confirm")

    confirmController.open()
    await nextFrame()
    confirmButton.click()
    await nextFrame()

    // cw--confirm's `confirm()` action only records the result; the actual close is
    // the second `click->cw--dialog#close` binding on the same button.
    expect(el.close).toHaveBeenCalledTimes(1)
    expect(el.open).toBe(false)
  })

  test("does not have a dialog target of its own — it IS cw--dialog's panel", async () => {
    const { el } = await mountConfirm()
    const confirmController = app.getControllerForElementAndIdentifier(el, "cw--confirm")

    expect(confirmController.constructor.targets).not.toContain("dialog")
  })

  // Deliberately no light dismiss — a confirmation should never close on an accidental
  // backdrop click. Proven here via cw--dialog's own dismissable value, which the
  // presenter fixes to false.
  test("backdrop click does not close or resolve (no light dismiss)", async () => {
    const { el } = await mountConfirm()
    const confirmController = app.getControllerForElementAndIdentifier(el, "cw--confirm")
    const pending = confirmController.open()
    await nextFrame()

    const event = new MouseEvent("click", { bubbles: true })
    Object.defineProperty(event, "target", { value: el })
    el.dispatchEvent(event)
    await nextFrame()

    expect(el.open).toBe(true)

    // Clean up the still-pending confirmation so it doesn't leak into the next test.
    el.remove()
    await expect(pending).resolves.toBe(false)
  })

  // --- focus placement (APG: least destructive control gets focus by default) --------

  test("focuses the confirm button by default once opened", async () => {
    const { el, confirmButton } = await mountConfirm()
    const confirmController = app.getControllerForElementAndIdentifier(el, "cw--confirm")

    confirmController.open()
    await nextFrame()

    expect(document.activeElement).toBe(confirmButton)
  })

  test("focuses the cancel button instead when destructive", async () => {
    const { el, cancelButton } = await mountConfirm({ destructive: true })
    const confirmController = app.getControllerForElementAndIdentifier(el, "cw--confirm")

    confirmController.open()
    await nextFrame()

    expect(document.activeElement).toBe(cancelButton)
  })

  // --- R7: exhaustive teardown ---------------------------------------------------------

  test("disconnect resolves a still-pending confirmation false", async () => {
    const { el } = await mountConfirm()
    const confirmController = app.getControllerForElementAndIdentifier(el, "cw--confirm")
    const pending = confirmController.open()
    await nextFrame()

    el.remove()
    await nextFrame()

    await expect(pending).resolves.toBe(false)
  })

  test("does not throw when torn down with no pending confirmation", async () => {
    const { el } = await mountConfirm()

    expect(() => el.remove()).not.toThrow()
  })
})
