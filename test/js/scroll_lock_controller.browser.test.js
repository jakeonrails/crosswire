import { describe, expect, test } from "vitest"
import { Application } from "@hotwired/stimulus"
import ScrollLockController from "../../app/assets/javascripts/crosswire/controllers/scroll_lock_controller.js"

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
// Run with `npm run test:browser` after `npx playwright install chromium`. As of this
// writing vitest.config.js does not yet define the `browser` project the
// package.json script points at — wiring that up is tracked separately from this
// primitive's implementation, same as every other crosswire controller's browser
// tier (see intersection_controller.browser.test.js). The assertions below are
// written against real browser scroll behaviour so they are correct the day that
// project exists, not aspirational pseudocode.

function tallPageMarkup() {
  return `
    <div style="height: 4000px;">
      <div id="lock" data-controller="cw--scroll-lock" data-cw--scroll-lock-active-value="false"></div>
    </div>`
}

describe("cw--scroll-lock (real browser layout)", () => {
  test("prevents the document from scrolling while active", async () => {
    document.body.innerHTML = tallPageMarkup()
    const application = Application.start()
    application.register("cw--scroll-lock", ScrollLockController)

    window.scrollTo(0, 0)
    document.getElementById("lock").setAttribute("data-cw--scroll-lock-active-value", "true")
    await new Promise((resolve) => requestAnimationFrame(resolve))

    window.scrollTo(0, 500)
    await new Promise((resolve) => requestAnimationFrame(resolve))

    expect(window.scrollY).toBe(0)

    application.stop()
    document.body.innerHTML = ""
  })

  test("releasing the lock allows scrolling again", async () => {
    document.body.innerHTML = tallPageMarkup()
    const application = Application.start()
    application.register("cw--scroll-lock", ScrollLockController)

    document.getElementById("lock").setAttribute("data-cw--scroll-lock-active-value", "true")
    await new Promise((resolve) => requestAnimationFrame(resolve))
    document.getElementById("lock").setAttribute("data-cw--scroll-lock-active-value", "false")
    await new Promise((resolve) => requestAnimationFrame(resolve))

    window.scrollTo(0, 500)
    await new Promise((resolve) => requestAnimationFrame(resolve))

    expect(window.scrollY).toBe(500)

    application.stop()
    document.body.innerHTML = ""
    window.scrollTo(0, 0)
  })

  // The detail everyone gets wrong, per the presenter's docstring: without scrollbar
  // compensation, engaging the lock removes the scrollbar and the whole page's content
  // shifts sideways by the scrollbar's width. Asserting a real browser's client width
  // is unchanged (or compensated by padding) across the lock transition is the only
  // honest way to verify that claim — jsdom cannot report a real scrollbar width at
  // all.
  test("does not shift page content width when the scrollbar disappears", async () => {
    document.body.innerHTML = tallPageMarkup()
    const application = Application.start()
    application.register("cw--scroll-lock", ScrollLockController)
    await new Promise((resolve) => requestAnimationFrame(resolve))

    const widthBefore = document.documentElement.clientWidth

    document.getElementById("lock").setAttribute("data-cw--scroll-lock-active-value", "true")
    await new Promise((resolve) => requestAnimationFrame(resolve))

    const widthDuring = document.documentElement.clientWidth

    expect(widthDuring).toBe(widthBefore)

    application.stop()
    document.body.innerHTML = ""
  })

  test("two stacked instances: releasing the inner one leaves the page locked until the outer releases too", async () => {
    document.body.innerHTML = `
      <div style="height: 4000px;">
        <div id="outer" data-controller="cw--scroll-lock" data-cw--scroll-lock-active-value="true"></div>
        <div id="inner" data-controller="cw--scroll-lock" data-cw--scroll-lock-active-value="true"></div>
      </div>`
    const application = Application.start()
    application.register("cw--scroll-lock", ScrollLockController)
    await new Promise((resolve) => requestAnimationFrame(resolve))

    window.scrollTo(0, 0)
    document.getElementById("inner").setAttribute("data-cw--scroll-lock-active-value", "false")
    await new Promise((resolve) => requestAnimationFrame(resolve))

    window.scrollTo(0, 500)
    await new Promise((resolve) => requestAnimationFrame(resolve))
    expect(window.scrollY).toBe(0) // outer still holds the lock

    document.getElementById("outer").setAttribute("data-cw--scroll-lock-active-value", "false")
    await new Promise((resolve) => requestAnimationFrame(resolve))

    window.scrollTo(0, 500)
    await new Promise((resolve) => requestAnimationFrame(resolve))
    expect(window.scrollY).toBe(500)

    application.stop()
    document.body.innerHTML = ""
    window.scrollTo(0, 0)
  })
})
