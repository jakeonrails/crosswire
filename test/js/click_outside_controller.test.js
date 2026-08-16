import { describe, expect, test } from "vitest"
import ClickOutsideController from "../../app/assets/javascripts/crosswire/controllers/click_outside_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--click-outside": ClickOutsideController }

// jsdom performs no layout at all, so `document.documentElement.clientWidth`/
// `clientHeight` are always 0 there (verified directly against the jsdom version this
// project pins). The controller's scrollbar-click heuristic guards against exactly
// that — it returns false rather than misreading it as "0-width viewport, everything
// is a scrollbar click" — so this suite can honestly assert the guard is INERT under
// jsdom (never suppresses a legitimate outside click). It cannot assert the guard's
// true-positive behaviour (a real click actually landing on a real scrollbar), which
// needs real layout and, per the class docstring, is only a best-effort heuristic even
// in a real browser (overlay scrollbars can't be detected this way at all). That claim
// is not tested in any tier here — it is documented as an accepted limitation instead
// of soft-pedaled into a jsdom assertion that would not honestly back it up.

function markup({ enabled = null } = {}) {
  return `
    <div id="outer">
      <div data-controller="cw--click-outside"
           ${enabled !== null ? `data-cw--click-outside-enabled-value="${enabled}"` : ""}>
        <button id="inside">Inside</button>
      </div>
      <button id="outside">Outside</button>
    </div>`
}

function pointerdown(target, overrides = {}) {
  const event = new MouseEvent("pointerdown", {
    bubbles: true,
    composed: true,
    cancelable: true,
    button: 0,
    ...overrides
  })
  target.dispatchEvent(event)
  return event
}

describe("cw--click-outside", () => {
  test("dispatches clicked when a pointerdown lands outside the element", async () => {
    const clicked = captureEvents("cw--click-outside:clicked")
    await mount(markup(), CONTROLLERS)

    pointerdown(document.getElementById("outside"))

    expect(clicked).toHaveLength(1)
  })

  test("does not dispatch when the pointerdown lands inside the element", async () => {
    const clicked = captureEvents("cw--click-outside:clicked")
    await mount(markup(), CONTROLLERS)

    pointerdown(document.getElementById("inside"))

    expect(clicked).toHaveLength(0)
  })

  test("does not dispatch when disabled", async () => {
    const clicked = captureEvents("cw--click-outside:clicked")
    await mount(markup({ enabled: false }), CONTROLLERS)

    pointerdown(document.getElementById("outside"))

    expect(clicked).toHaveLength(0)
  })

  test("ignores right-clicks", async () => {
    const clicked = captureEvents("cw--click-outside:clicked")
    await mount(markup(), CONTROLLERS)

    pointerdown(document.getElementById("outside"), { button: 2 })

    expect(clicked).toHaveLength(0)
  })

  test("ignores middle-clicks", async () => {
    const clicked = captureEvents("cw--click-outside:clicked")
    await mount(markup(), CONTROLLERS)

    pointerdown(document.getElementById("outside"), { button: 1 })

    expect(clicked).toHaveLength(0)
  })

  // The reason this listens on pointerdown rather than click: a click event only
  // fires when mouseup targets the same element mousedown did, so a selection/drag
  // that starts inside and ends outside never produces a click at all. Asserting that
  // a bare `click` dispatched outside (with no matching pointerdown) does NOT trigger
  // anything on its own would be trivially true and prove nothing; the meaningful
  // assertion is the inverse — that pointerdown alone, with no click ever following it,
  // is sufficient.
  test("fires from pointerdown alone, with no click event required", async () => {
    const clicked = captureEvents("cw--click-outside:clicked")
    await mount(markup(), CONTROLLERS)

    const outside = document.getElementById("outside")
    pointerdown(outside)
    // Deliberately no accompanying "click" dispatch.

    expect(clicked).toHaveLength(1)
  })

  // R-composed-path: a plain `contains()` check reads a click inside an open shadow
  // root as "outside" once the event crosses back out through the shadow boundary,
  // because `event.target` is retargeted to the shadow host from outside the root.
  // composedPath() does not have that blind spot.
  test("composed-path aware: a pointerdown on a node INSIDE an open shadow root nested in the element does not count as outside", async () => {
    const clicked = captureEvents("cw--click-outside:clicked")
    const el = await mount(markup(), CONTROLLERS)
    const controllerRoot = el.querySelector("[data-controller='cw--click-outside']")

    const shadowHost = document.createElement("div")
    controllerRoot.appendChild(shadowHost)
    const shadow = shadowHost.attachShadow({ mode: "open" })
    const shadowButton = document.createElement("button")
    shadow.appendChild(shadowButton)

    pointerdown(shadowButton)

    expect(clicked).toHaveLength(0)
  })

  test("composed-path aware: a pointerdown on a node inside a shadow root OUTSIDE the element does count as outside", async () => {
    const clicked = captureEvents("cw--click-outside:clicked")
    await mount(markup(), CONTROLLERS)

    const shadowHost = document.createElement("div")
    document.getElementById("outside").appendChild(shadowHost)
    const shadow = shadowHost.attachShadow({ mode: "open" })
    const shadowButton = document.createElement("button")
    shadow.appendChild(shadowButton)

    pointerdown(shadowButton)

    expect(clicked).toHaveLength(1)
  })

  test("the scrollbar-click guard is inert under jsdom (0-size viewport never suppresses a real outside click)", async () => {
    const clicked = captureEvents("cw--click-outside:clicked")
    await mount(markup(), CONTROLLERS)

    // Under real layout this would be read as a scrollbar click if it exceeded a
    // nonzero clientWidth/clientHeight; under jsdom clientWidth/clientHeight are both
    // 0, so the guard must not fire and swallow this legitimate outside click.
    pointerdown(document.getElementById("outside"), { clientX: 9999, clientY: 9999 })

    expect(clicked).toHaveLength(1)
  })

  test("event.detail carries the original pointerdown event", async () => {
    const clicked = captureEvents("cw--click-outside:clicked")
    await mount(markup(), CONTROLLERS)

    const event = pointerdown(document.getElementById("outside"))

    expect(clicked).toHaveLength(1)
    expect(clicked[0].detail.originalEvent).toBe(event)
  })

  // R7 — exhaustive teardown.
  test("removes the document listener on disconnect", async () => {
    const clicked = captureEvents("cw--click-outside:clicked")
    await mount(markup(), CONTROLLERS)

    document.body.innerHTML = ""
    await nextFrame()

    pointerdown(document.body)

    expect(clicked).toHaveLength(0)
  })
})
