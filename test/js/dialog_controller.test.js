import { Application } from "@hotwired/stimulus"
import { afterEach, describe, expect, test, vi } from "vitest"
import DialogController from "../../app/assets/javascripts/crosswire/controllers/dialog_controller.js"
import { captureEvents, nextFrame } from "./setup.js"

// jsdom tier (docs/COMPONENT_CONTRACT.md R8). jsdom (as of the version pinned in
// package.json) implements HTMLDialogElement's `.open` attribute reflection but NOT
// showModal()/show()/close() at all, and has no top layer, no inertness, and no
// backdrop. Here we polyfill minimal, spec-shaped versions of those three methods so
// the *controller's* logic — value wiring, event sequencing, the SSR-upgrade path,
// morph/cache defence, scroll-lock bookkeeping, teardown — is exercised against real
// code paths rather than mocks of the controller itself. The polyfill is installed
// BEFORE Stimulus connects (see `mountDialog` below), matching what a real browser
// gives the controller from the start.
//
// What this file does NOT and cannot honestly test: real modality (the rest of the
// page is not actually inert), real focus containment, a real backdrop click landing
// on the dialog's padding box, and genuine `:modal` matching (jsdom's nwsapi throws on
// that pseudo-class rather than just not matching it — our polyfill below tracks it by
// hand purely so the controller's own idempotency check has *something* honest to ask).
// Those all live in dialog_controller.browser.test.js instead, run against a real
// browser via `npm run test:browser`.
function polyfillDialog(panel) {
  // Tracks real-browser `:modal` matching (true only between a successful showModal()
  // and the dialog actually closing) so the controller's own `#isModal` check — which
  // is how it decides the SSR-upgrade reopen is idempotent — gets an honest answer.
  // jsdom's nwsapi throws on the `:modal` pseudo-class rather than just not matching
  // it, so this is *our* stub's job, not something jsdom provides.
  let modal = false

  panel.showModal = vi.fn(function showModal() {
    if (this.open) throw new DOMException("already open", "InvalidStateError")
    this.setAttribute("open", "")
    modal = true
  })
  panel.show = vi.fn(function show() {
    this.setAttribute("open", "")
    modal = false
  })
  panel.close = vi.fn(function close() {
    if (!this.open) return
    this.removeAttribute("open")
    modal = false
    this.dispatchEvent(new Event("close"))
  })
  const nativeMatches = typeof panel.matches === "function" ? panel.matches.bind(panel) : null
  panel.matches = (selector) => {
    if (selector === ":modal") return modal
    if (!nativeMatches) return false
    try {
      return nativeMatches(selector)
    } catch {
      return false
    }
  }
  return panel
}

function markup({ open = false, modal = null, dismissable = null } = {}) {
  return `
    <div data-controller="cw--dialog"
         data-cw--dialog-open-value="${open}"
         ${modal !== null ? `data-cw--dialog-modal-value="${modal}"` : ""}
         ${dismissable !== null ? `data-cw--dialog-dismissable-value="${dismissable}"` : ""}>
      <button data-cw--dialog-target="trigger"
              data-action="click->cw--dialog#open"
              aria-haspopup="dialog" aria-controls="d1">Open</button>
      <dialog id="d1"
              data-cw--dialog-target="panel"
              data-action="close->cw--dialog#syncClosed cancel->cw--dialog#cancel click->cw--dialog#backdropClick turbo:before-morph-element->cw--dialog#beforeMorph turbo:before-cache->cw--dialog#reset"
              ${open ? "open" : ""}>
        <h2 id="d1-title">Title</h2>
        <button data-action="click->cw--dialog#close" aria-label="Close">&times;</button>
      </dialog>
    </div>`
}

// A local, hand-rolled variant of setup.js's `mount()` — needed because the dialog
// polyfill above MUST be installed before Stimulus's first connect() runs (a real
// browser already has these methods at that point). setup.js's shared `mount()`
// starts the Application immediately after setting innerHTML, leaving no window to
// polyfill first.
let app

function mountDialog(opts = {}) {
  document.body.innerHTML = markup(opts)
  const el = document.body.firstElementChild
  const panel = el.querySelector("dialog")
  polyfillDialog(panel)

  app = Application.start()
  app.register("cw--dialog", DialogController)

  return nextFrame().then(() => ({
    el,
    panel,
    trigger: el.querySelector("[data-cw--dialog-target='trigger']")
  }))
}

afterEach(async () => {
  // Application#stop() does NOT call disconnect() on still-connected controllers —
  // it only stops observing for *future* mutations — so a test that leaves a dialog
  // open (never called close()) would otherwise skip R7 teardown (releasing the
  // scroll lock) entirely: setup.js's global afterEach clears document.body.innerHTML
  // AFTER this hook runs, by which point stop() has already torn down the observer
  // that would have detected the removal. Clear the DOM ourselves first and await a
  // tick so Stimulus's MutationObserver fires the real disconnect() naturally — the
  // same thing a Turbo navigation does to a connected page — before stopping.
  document.body.innerHTML = ""
  await nextFrame()
  app?.stop()
  app = undefined
})

describe("cw--dialog", () => {
  test("renders closed on connect", async () => {
    const { panel } = await mountDialog()
    expect(panel.open).toBe(false)
    expect(panel.showModal).not.toHaveBeenCalled()
  })

  test("clicking the trigger opens the dialog via showModal", async () => {
    const { panel, trigger } = await mountDialog()
    trigger.click()
    await nextFrame()

    expect(panel.showModal).toHaveBeenCalledTimes(1)
    expect(panel.open).toBe(true)
  })

  test("modal:false uses show() instead of showModal()", async () => {
    const { panel, trigger } = await mountDialog({ modal: "false" })
    trigger.click()
    await nextFrame()

    expect(panel.show).toHaveBeenCalledTimes(1)
    expect(panel.showModal).not.toHaveBeenCalled()
  })

  test("server-rendered open state is upgraded to a real modal on connect", async () => {
    // SSR can only ever emit the plain `open` attribute — a `<dialog open>` is visible
    // but NOT modal (no top layer, no inertness). showModal() also throws
    // InvalidStateError on an already-open dialog, so the controller must close() the
    // SSR state first and reopen it properly. This is the R4a "DOM work always runs in
    // the value callback" guarantee doing real work, not just avoiding a phantom event.
    const { panel } = await mountDialog({ open: true })

    expect(panel.close).toHaveBeenCalledTimes(1)
    expect(panel.showModal).toHaveBeenCalledTimes(1)
    expect(panel.open).toBe(true)
  })

  test("does not announce opened on initial connect even when open", async () => {
    const opened = captureEvents("cw--dialog:opened")
    await mountDialog({ open: true })
    expect(opened).toHaveLength(0)
  })

  test("close button closes the dialog", async () => {
    const { panel, el } = await mountDialog({ open: true })
    el.querySelector("[aria-label='Close']").click()
    await nextFrame()

    expect(panel.open).toBe(false)
  })

  test("dispatches opening/opened and closing/closed", async () => {
    const opening = captureEvents("cw--dialog:opening")
    const opened = captureEvents("cw--dialog:opened")
    const closing = captureEvents("cw--dialog:closing")
    const closed = captureEvents("cw--dialog:closed")
    const { trigger, el } = await mountDialog()

    trigger.click()
    await nextFrame()
    expect(opening).toHaveLength(1)
    expect(opened).toHaveLength(1)

    el.querySelector("[aria-label='Close']").click()
    await nextFrame()
    expect(closing).toHaveLength(1)
    expect(closed).toHaveLength(1)
  })

  test("opening is cancelable and aborts the open", async () => {
    const preventOpening = (event) => event.preventDefault()
    document.addEventListener("cw--dialog:opening", preventOpening)

    try {
      const { panel, trigger } = await mountDialog()
      trigger.click()
      await nextFrame()

      expect(panel.showModal).not.toHaveBeenCalled()
      expect(panel.open).toBe(false)
    } finally {
      document.removeEventListener("cw--dialog:opening", preventOpening)
    }
  })

  test("closing is cancelable and aborts the close", async () => {
    const preventClosing = (event) => event.preventDefault()
    document.addEventListener("cw--dialog:closing", preventClosing)

    try {
      const { panel, el } = await mountDialog({ open: true })
      el.querySelector("[aria-label='Close']").click()
      await nextFrame()

      expect(panel.close).toHaveBeenCalledTimes(1) // the SSR-upgrade close() from connect
      expect(panel.open).toBe(true) // still open — the second close() (from the button) never ran
    } finally {
      document.removeEventListener("cw--dialog:closing", preventClosing)
    }
  })

  test("backdrop click closes when dismissable", async () => {
    const { panel } = await mountDialog({ open: true })

    // A backdrop click's event.target IS the <dialog> element itself; a click on
    // rendered content lands on a descendant instead.
    const event = new MouseEvent("click", { bubbles: true })
    Object.defineProperty(event, "target", { value: panel })
    panel.dispatchEvent(event)
    await nextFrame()

    expect(panel.open).toBe(false)
  })

  test("backdrop click is a no-op when dismissable is false", async () => {
    const { panel } = await mountDialog({ open: true, dismissable: "false" })
    const event = new MouseEvent("click", { bubbles: true })
    Object.defineProperty(event, "target", { value: panel })
    panel.dispatchEvent(event)
    await nextFrame()

    expect(panel.open).toBe(true)
  })

  test("click on descendant content is not treated as a backdrop click", async () => {
    const { panel, el } = await mountDialog({ open: true })
    const heading = el.querySelector("h2")
    const event = new MouseEvent("click", { bubbles: true })
    Object.defineProperty(event, "target", { value: heading })
    panel.dispatchEvent(event)
    await nextFrame()

    expect(panel.open).toBe(true)
  })

  test("native close event (e.g. Escape) syncs the value even though this controller did not initiate it", async () => {
    const closed = captureEvents("cw--dialog:closed")
    const { panel, el } = await mountDialog({ open: true })

    // Simulate what the browser does on Escape: it closes the dialog itself, then
    // fires `close`. No action method of ours runs first.
    panel.removeAttribute("open")
    panel.dispatchEvent(new Event("close"))
    await nextFrame()

    expect(closed).toHaveLength(1)
    expect(el.getAttribute("data-cw--dialog-open-value")).toBe("false")
  })

  test("turbo:before-morph-element is cancelled while open, so Idiomorph never strips `open`", async () => {
    const { panel } = await mountDialog({ open: true })
    const event = new Event("turbo:before-morph-element", { cancelable: true })
    panel.dispatchEvent(event)

    expect(event.defaultPrevented).toBe(true)
  })

  test("turbo:before-morph-element is allowed through while closed", async () => {
    const { panel } = await mountDialog({ open: false })
    const event = new Event("turbo:before-morph-element", { cancelable: true })
    panel.dispatchEvent(event)

    expect(event.defaultPrevented).toBe(false)
  })

  test("turbo:before-cache closes an open dialog before it is snapshotted", async () => {
    const { panel } = await mountDialog({ open: true })
    panel.dispatchEvent(new Event("turbo:before-cache"))
    await nextFrame()

    expect(panel.open).toBe(false)
  })

  test("focus is restored to the trigger after close", async () => {
    const { panel, trigger, el } = await mountDialog()
    trigger.focus()
    trigger.click()
    await nextFrame()

    el.querySelector("[aria-label='Close']").click()
    await nextFrame()

    expect(document.activeElement).toBe(trigger)
  })

  test("locks scroll while open and releases it on close", async () => {
    const { trigger, el } = await mountDialog()
    trigger.click()
    await nextFrame()

    expect(document.documentElement.style.overflow).toBe("hidden")
    expect(document.documentElement.style.scrollbarGutter).toBe("stable")

    el.querySelector("[aria-label='Close']").click()
    await nextFrame()

    expect(document.documentElement.style.overflow).not.toBe("hidden")
  })

  test("disconnect releases the scroll lock even without a close", async () => {
    const { trigger, el } = await mountDialog()
    trigger.click()
    await nextFrame()
    expect(document.documentElement.style.overflow).toBe("hidden")

    el.remove()
    await nextFrame()

    expect(document.documentElement.style.overflow).not.toBe("hidden")
  })

  // R3-adjacent: dialog has no Classes API, but its Boolean values have defaults —
  // confirm hand-authored markup that omits modal/dismissable value attributes
  // entirely does not throw.
  test("does not throw when modal/dismissable value attributes are absent", async () => {
    document.body.innerHTML = `
      <div data-controller="cw--dialog" data-cw--dialog-open-value="false">
        <dialog data-cw--dialog-target="panel"
                data-action="close->cw--dialog#syncClosed cancel->cw--dialog#cancel click->cw--dialog#backdropClick"></dialog>
      </div>`
    const el = document.body.firstElementChild
    const panel = el.querySelector("dialog")
    polyfillDialog(panel)

    app = Application.start()
    app.register("cw--dialog", DialogController)
    await nextFrame()

    expect(() => panel.dispatchEvent(new Event("close"))).not.toThrow()
  })
})
