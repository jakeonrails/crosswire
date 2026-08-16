import { Application } from "@hotwired/stimulus"
import { afterEach, beforeEach } from "vitest"

let application

/**
 * Mount markup with one or more controllers registered, and wait for Stimulus to
 * connect. Returns the root element.
 *
 *   const el = await mount(`<div data-controller="cw--disclosure">…</div>`,
 *                          { "cw--disclosure": DisclosureController })
 */
export async function mount(html, controllers = {}) {
  document.body.innerHTML = html
  application = Application.start()
  for (const [identifier, controller] of Object.entries(controllers)) {
    application.register(identifier, controller)
  }
  await nextFrame()
  return document.body.firstElementChild
}

/** Let Stimulus's MutationObserver flush. */
export function nextFrame() {
  return new Promise((resolve) => setTimeout(resolve, 0))
}

let listeners = []

/** Collect events of a given type dispatched anywhere in the document. */
export function captureEvents(type) {
  const seen = []
  const handler = (event) => seen.push(event)
  document.addEventListener(type, handler)
  // Tracked so afterEach can remove it. Document-level listeners survive
  // `document.body.innerHTML = ""`, so without this they accumulate across the whole
  // run — exactly the leak R7 exists to prevent, and it would be embarrassing to have
  // it in the harness that tests for it.
  listeners.push([type, handler])
  return seen
}

beforeEach(() => {
  document.body.innerHTML = ""
})

afterEach(async () => {
  // Order matters, and getting it wrong silently voids every R7 teardown assertion in
  // the suite.
  //
  // `Application#stop()` does NOT call `disconnect()` on still-connected controllers —
  // it only stops observing future mutations. So stopping first and clearing the DOM
  // afterwards means `disconnect()` never runs for any test that left its element in
  // place, and every "releases the listener / observer / lock on disconnect" test
  // passes without exercising the code it names. (Found while fixing `dialog`, whose
  // scroll lock leaked across tests through a deliberately shared counter.)
  //
  // Clearing the DOM first and awaiting a tick lets Stimulus's own MutationObserver
  // fire `disconnect()` naturally — the same path a real Turbo navigation takes.
  document.body.innerHTML = ""
  await new Promise((resolve) => setTimeout(resolve, 0))

  application?.stop()
  application = undefined

  for (const [type, handler] of listeners) document.removeEventListener(type, handler)
  listeners = []
})
