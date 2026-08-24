import { afterEach, beforeEach, describe, expect, test, vi } from "vitest"
import { Application } from "@hotwired/stimulus"
import ScrollLockController from "../../app/assets/javascripts/crosswire/controllers/scroll_lock_controller.js"
import { captureEvents, nextFrame } from "./setup.js"

// jsdom performs no layout at all (verified directly against the jsdom version this
// project pins: `document.documentElement.clientWidth` is unconditionally 0, `CSS` is
// not even defined as a global). So this suite proves the controller's WIRING
// honestly — the `overflow`/`scrollbarGutter` style writes, the module-level
// reference-counted lock/unlock, the iOS position:fixed branch (pure style-property
// logic, verifiable by stubbing `navigator` — no real layout needed for that part),
// event dispatch, and R7 teardown. It does NOT and cannot honestly assert "the page
// visually does not shift" or "scrolling the mouse wheel is actually blocked" — those
// claims require a real layout engine and belong exclusively in
// scroll_lock_controller.browser.test.js.
//
// This file constructs multiple root elements directly via Stimulus's Application
// rather than the shared single-element `mount()` helper, because several tests need
// two independent controller instances live in the DOM at once (the reference-count
// stacking guarantee).

const html = document.documentElement
const body = document.body

function markup(id, active) {
  return `<div id="${id}" data-controller="cw--scroll-lock" data-cw--scroll-lock-active-value="${active}"></div>`
}

let application

async function mountAll(htmlString) {
  document.body.innerHTML = htmlString
  application = Application.start()
  application.register("cw--scroll-lock", ScrollLockController)
  await nextFrame()
}

describe("cw--scroll-lock", () => {
  afterEach(async () => {
    // Extra safety on top of the shared afterEach in setup.js: this file starts its
    // own Application instances directly rather than through mount(), so make sure
    // every lock this file acquired is actually released before the next test, or the
    // module-level reference count leaks across tests.
    document.body.innerHTML = ""
    await new Promise((resolve) => setTimeout(resolve, 0))
    application?.stop()
    application = undefined
    html.style.overflow = ""
    html.style.paddingRight = ""
    body.style.cssText = ""
  })

  // --- basic lock/unlock -------------------------------------------------------------

  test("locks document.documentElement overflow when active on connect", async () => {
    await mountAll(markup("a", true))
    expect(html.style.overflow).toBe("hidden")
  })

  test("does not lock when active is false", async () => {
    await mountAll(markup("a", false))
    expect(html.style.overflow).toBe("")
  })

  test("unlocks when active transitions to false", async () => {
    await mountAll(markup("a", true))
    expect(html.style.overflow).toBe("hidden")

    document.getElementById("a").setAttribute("data-cw--scroll-lock-active-value", "false")
    await nextFrame()

    expect(html.style.overflow).toBe("")
  })

  // --- events -------------------------------------------------------------------------

  test("dispatches locked and unlocked on real transitions, not on initial hydration", async () => {
    const locked = captureEvents("cw--scroll-lock:locked")
    const unlocked = captureEvents("cw--scroll-lock:unlocked")

    await mountAll(markup("a", true))
    expect(locked).toHaveLength(0) // R4a: initial hydration is not a transition

    document.getElementById("a").setAttribute("data-cw--scroll-lock-active-value", "false")
    await nextFrame()
    expect(unlocked).toHaveLength(1)

    document.getElementById("a").setAttribute("data-cw--scroll-lock-active-value", "true")
    await nextFrame()
    expect(locked).toHaveLength(1)
  })

  // --- R5/reference counting: the whole reason this is a shared primitive -----------

  test("a stacked instance releasing does not unlock the page while another instance is still active", async () => {
    await mountAll(`${markup("outer", true)}${markup("inner", true)}`)
    expect(html.style.overflow).toBe("hidden")

    document.getElementById("inner").setAttribute("data-cw--scroll-lock-active-value", "false")
    await nextFrame()

    // The outer instance is still active — the page must remain locked.
    expect(html.style.overflow).toBe("hidden")

    document.getElementById("outer").setAttribute("data-cw--scroll-lock-active-value", "false")
    await nextFrame()

    // Now that the last holder has released, the page unlocks.
    expect(html.style.overflow).toBe("")
  })

  test("order of release does not matter — the page stays locked until every holder releases", async () => {
    await mountAll(`${markup("outer", true)}${markup("inner", true)}`)

    document.getElementById("outer").setAttribute("data-cw--scroll-lock-active-value", "false")
    await nextFrame()
    expect(html.style.overflow).toBe("hidden")

    document.getElementById("inner").setAttribute("data-cw--scroll-lock-active-value", "false")
    await nextFrame()
    expect(html.style.overflow).toBe("")
  })

  // --- R7: exhaustive teardown --------------------------------------------------------

  test("disconnect releases the lock even without ever setting active back to false", async () => {
    await mountAll(markup("a", true))
    expect(html.style.overflow).toBe("hidden")

    document.body.innerHTML = ""
    await nextFrame()

    expect(html.style.overflow).toBe("")
  })

  test("disconnect of one stacked instance mid-open still leaves the other holding the lock", async () => {
    document.body.innerHTML = `<div id="wrapper">${markup("outer", true)}${markup("inner", true)}</div>`
    application = Application.start()
    application.register("cw--scroll-lock", ScrollLockController)
    await nextFrame()

    expect(html.style.overflow).toBe("hidden")

    document.getElementById("inner").remove()
    await nextFrame()

    expect(html.style.overflow).toBe("hidden") // outer instance is still connected and active

    document.getElementById("outer").remove()
    await nextFrame()

    expect(html.style.overflow).toBe("")
  })

  // --- iOS Safari position:fixed branch -----------------------------------------------
  // Pure style-property logic — no real layout required, so this is honestly
  // testable under jsdom by stubbing `navigator` to look like iOS. What is NOT
  // honestly testable here is whether that CSS actually holds scroll position in a
  // real WebKit engine; that's an accepted limit of every JS test tier, browser
  // included, since Playwright's Chromium project can't emulate WebKit's iOS quirks
  // either — the only thing being verified is "does the controller apply and later
  // restore the expected inline styles."

  // --- scrollbar-gutter compensation gating --------------------------------------------
  //
  // jsdom does no layout, so `document.documentElement.clientWidth` is unconditionally 0
  // and `CSS` isn't even defined as a global here (see the file-level comment) — real
  // cross-platform layout behavior belongs in scroll_lock_controller.browser.test.js.
  // But that's exactly what makes jsdom the one place `applyLock()`'s gating logic can be
  // pinned down deterministically: `clientWidth`, `innerWidth`, and `CSS.supports` can
  // all be mocked directly, independent of what scrollbar (if any) the host OS/browser
  // actually renders. This is the regression test for the bug fixed here: the
  // `scrollbar-gutter: stable` branch used to apply unconditionally, which reserves
  // gutter space even when nothing overflowed before locking (per the CSS Overflow spec,
  // `stable` reserves space "even if the box doesn't currently overflow") — introducing
  // exactly the shift the compensation was supposed to prevent, on any platform with a
  // space-taking scrollbar. It only ever surfaced as the real, reproducible CI failure
  // this fix responds to.
  describe("scrollbar-gutter compensation gating", () => {
    let originalCSS

    beforeEach(() => {
      originalCSS = global.CSS
      global.CSS = { supports: () => true } // pretend scrollbar-gutter is supported
    })

    afterEach(() => {
      global.CSS = originalCSS
      html.style.scrollbarGutter = ""
    })

    test("does not reserve scrollbar-gutter space when nothing overflowed before locking", async () => {
      Object.defineProperty(html, "clientWidth", { value: 1024, configurable: true }) // no gap
      Object.defineProperty(window, "innerWidth", { value: 1024, configurable: true })

      await mountAll(markup("a", true))

      expect(html.style.scrollbarGutter).toBe("")

      delete html.clientWidth
    })

    test("reserves scrollbar-gutter space when a real scrollbar was taking space before locking", async () => {
      Object.defineProperty(html, "clientWidth", { value: 1009, configurable: true }) // 15px gap
      Object.defineProperty(window, "innerWidth", { value: 1024, configurable: true })

      await mountAll(markup("a", true))

      expect(html.style.scrollbarGutter).toBe("stable")

      delete html.clientWidth
    })
  })

  describe("iOS", () => {
    // `platform`/`maxTouchPoints` are inherited getters on Navigator.prototype, not
    // own properties of the `navigator` instance — `getOwnPropertyDescriptor` returns
    // undefined for both (verified directly), so there is no descriptor to save and
    // restore. `defineProperty` shadows the prototype getter with an own property;
    // `delete` removes that own property and lets the original prototype getter show
    // through again, which is the correct way to undo this rather than restoring a
    // descriptor that never existed.
    beforeEach(() => {
      Object.defineProperty(navigator, "platform", { value: "iPhone", configurable: true })
      Object.defineProperty(navigator, "maxTouchPoints", { value: 5, configurable: true })
    })

    afterEach(() => {
      delete navigator.platform
      delete navigator.maxTouchPoints
    })

    test("pins body to position:fixed while locked", async () => {
      await mountAll(markup("a", true))

      expect(body.style.position).toBe("fixed")
      expect(body.style.left).toBe("0px")
      expect(body.style.width).toBe("100%")
    })

    test("restores body position and scroll offset on unlock", async () => {
      const scrollToSpy = vi.spyOn(window, "scrollTo").mockImplementation(() => {})
      Object.defineProperty(window, "scrollY", { value: 240, configurable: true })

      await mountAll(markup("a", true))
      expect(body.style.position).toBe("fixed")
      expect(body.style.top).toBe("-240px")

      document.getElementById("a").setAttribute("data-cw--scroll-lock-active-value", "false")
      await nextFrame()

      expect(body.style.position).toBe("")
      expect(scrollToSpy).toHaveBeenCalledWith(0, 240)

      scrollToSpy.mockRestore()
      Object.defineProperty(window, "scrollY", { value: 0, configurable: true })
    })
  })
})
