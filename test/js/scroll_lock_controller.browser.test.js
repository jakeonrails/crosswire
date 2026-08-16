import { describe, expect, test } from "vitest"
import { userEvent } from "vitest/browser"
import ScrollLockController from "../../app/assets/javascripts/crosswire/controllers/scroll_lock_controller.js"
import { mount } from "./setup.js"

// Browser tier (docs/COMPONENT_CONTRACT.md: "Browser mode for anything touching
// focus, <dialog>, IntersectionObserver, or positioning — jsdom cannot test those
// honestly"). jsdom performs NO layout at all — not "imperfect" layout, none — so
// every claim this component actually makes about scrolling (does the page stop
// scrolling, does the scrollbar's disappearance actually avoid a visible layout
// shift) can only be honestly verified against a real layout engine and a real,
// visible scrollbar. scroll_lock_controller.test.js sticks to what jsdom CAN honestly
// prove (the reference-counted lock/unlock wiring, event dispatch, R7 teardown, and
// the iOS position:fixed style-property logic); this file proves the rest.
//
// Run with `npm run test:browser` after `npx playwright install chromium` — wired up
// in vitest.browser.config.js.
//
// Two real bugs in this file as first written, neither in the controller:
//
// 1. `window.scrollTo()` does not test scroll locking. CSS `overflow: hidden` blocks
//    USER-driven scroll (wheel, touch, keyboard, dragging the scrollbar) but
//    explicitly still permits programmatic `scrollTo`/`scrollBy`/`scrollTop =` per the
//    CSS Overflow spec. So `window.scrollTo(0, 500)` while "locked" was always going to
//    move the page regardless of whether the lock worked at all — the assertion could
//    never honestly prove the claim in its name. Fixed by driving a real trusted wheel
//    gesture via `userEvent.wheel`, which is exactly the kind of input `overflow:
//    hidden` is documented to block. (Same fix already shipped in
//    dialog_controller.browser.test.js for the same reason — see its comment for the
//    full writeup.)
//
// 2. Hand-rolled `Application.start()`/`register()` with `application.stop()` called
//    BEFORE clearing the DOM at the end of each test. `Application#stop()` does not
//    call `disconnect()` on still-connected controllers — so every lock instance
//    left active at teardown never runs `disconnect()`, never calls the module-level
//    `release()`, and leaks a held reference into the NEXT test via the shared
//    `lockCount` counter (see the controller's own docstring on why that counter is
//    module-scoped). That leak was largely invisible here because bug #1 already made
//    the "stays locked" assertions pass or fail for the wrong reason regardless of
//    real lock state — but it's exactly the kind of latent cross-test contamination
//    the contract's gotchas table warns about. Fixed by using the shared `mount()`
//    helper from setup.js, which clears the DOM and awaits a tick BEFORE stopping the
//    application, letting Stimulus's own MutationObserver fire `disconnect()` (and
//    thus `release()`) naturally for every test, every time.

function tallPageMarkup(active = false) {
  return `
    <div style="height: 4000px;">
      <div id="lock" data-controller="cw--scroll-lock" data-cw--scroll-lock-active-value="${active}"></div>
    </div>`
}

async function settle() {
  await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
}

describe("cw--scroll-lock (real browser layout)", () => {
  test("prevents the document from scrolling while active", async () => {
    await mount(tallPageMarkup(), { "cw--scroll-lock": ScrollLockController })

    window.scrollTo(0, 0)
    document.getElementById("lock").setAttribute("data-cw--scroll-lock-active-value", "true")
    await settle()

    await userEvent.wheel(document.body, { delta: { y: 500 } })
    await settle()

    expect(window.scrollY).toBe(0)
  })

  test("releasing the lock allows scrolling again", async () => {
    await mount(tallPageMarkup(), { "cw--scroll-lock": ScrollLockController })

    window.scrollTo(0, 0)
    document.getElementById("lock").setAttribute("data-cw--scroll-lock-active-value", "true")
    await settle()
    document.getElementById("lock").setAttribute("data-cw--scroll-lock-active-value", "false")
    await settle()

    await userEvent.wheel(document.body, { delta: { y: 500 } })
    await settle()

    expect(window.scrollY).toBeGreaterThan(0)
  })

  // The detail everyone gets wrong, per the presenter's docstring: without scrollbar
  // compensation, engaging the lock removes the scrollbar and the whole page's content
  // shifts sideways by the scrollbar's width. Asserting a real browser's client width
  // is unchanged (or compensated by padding) across the lock transition is the only
  // honest way to verify that claim — jsdom cannot report a real scrollbar width at
  // all.
  test("does not shift page content width when the scrollbar disappears", async () => {
    await mount(tallPageMarkup(), { "cw--scroll-lock": ScrollLockController })

    const widthBefore = document.documentElement.clientWidth

    document.getElementById("lock").setAttribute("data-cw--scroll-lock-active-value", "true")
    await settle()

    const widthDuring = document.documentElement.clientWidth

    expect(widthDuring).toBe(widthBefore)
  })

  test("two stacked instances: releasing the inner one leaves the page locked until the outer releases too", async () => {
    await mount(
      `<div style="height: 4000px;">
        <div id="outer" data-controller="cw--scroll-lock" data-cw--scroll-lock-active-value="true"></div>
        <div id="inner" data-controller="cw--scroll-lock" data-cw--scroll-lock-active-value="true"></div>
      </div>`,
      { "cw--scroll-lock": ScrollLockController }
    )

    window.scrollTo(0, 0)
    document.getElementById("inner").setAttribute("data-cw--scroll-lock-active-value", "false")
    await settle()

    await userEvent.wheel(document.body, { delta: { y: 500 } })
    await settle()
    expect(window.scrollY).toBe(0) // outer still holds the lock

    document.getElementById("outer").setAttribute("data-cw--scroll-lock-active-value", "false")
    await settle()

    await userEvent.wheel(document.body, { delta: { y: 500 } })
    await settle()
    expect(window.scrollY).toBeGreaterThan(0)
  })
})
