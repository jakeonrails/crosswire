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

afterEach(() => {
  application?.stop()
  application = undefined
  for (const [type, handler] of listeners) document.removeEventListener(type, handler)
  listeners = []
  document.body.innerHTML = ""
})
