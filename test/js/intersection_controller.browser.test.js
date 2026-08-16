import { describe, expect, test } from "vitest"
import { Application } from "@hotwired/stimulus"
import IntersectionController from "../../app/assets/javascripts/crosswire/controllers/intersection_controller.js"

// Browser tier (docs/COMPONENT_CONTRACT.md: "Browser mode for anything touching
// focus, <dialog>, IntersectionObserver, or positioning — jsdom cannot test those
// honestly"). jsdom has no real IntersectionObserver at all (verified directly
// against the jsdom version this project pins), so intersection_controller.test.js
// only proves the controller's *wiring* against an explicit fake: the options it
// passes, that it observes/disconnects the right element, that value changes
// reconfigure without leaking. None of that is "does this actually fire when the
// element scrolls into view" — that claim can only be honestly tested against a real
// browser IntersectionObserver, which is what this file does.
//
// Run with `npm run test:browser` after `npx playwright install chromium`. As of
// this writing vitest.config.js does not yet define the `browser` project the
// package.json script points at — wiring that up is tracked separately from this
// primitive's implementation, same as every other crosswire controller's browser
// tier. The assertions below are written against real browser APIs (a real
// IntersectionObserver, real scrolling, a real viewport) so they are correct the
// day that project exists, not aspirational pseudocode.

function markup({ threshold = 0, once = false, rootMargin = "0px" } = {}) {
  return `
    <div style="height: 3000px;">
      <div id="sentinel"
           data-controller="cw--intersection"
           data-cw--intersection-threshold-value="${threshold}"
           data-cw--intersection-once-value="${once}"
           data-cw--intersection-root-margin-value="${rootMargin}"
           style="margin-top: 2800px; height: 20px;">Sentinel</div>
    </div>`
}

async function scrollSentinelIntoView() {
  document.getElementById("sentinel").scrollIntoView()
  // Real IntersectionObserver callbacks land on a microtask queued by the browser's
  // rendering pipeline, not synchronously with the scroll — give it a couple of
  // animation frames.
  await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
}

describe("cw--intersection (real browser IntersectionObserver)", () => {
  test("dispatches entered with a real IntersectionObserverEntry when scrolled into view", async () => {
    document.body.innerHTML = markup()
    const application = Application.start()
    application.register("cw--intersection", IntersectionController)

    const entered = []
    document.addEventListener("cw--intersection:entered", (e) => entered.push(e))

    await scrollSentinelIntoView()

    expect(entered).toHaveLength(1)
    expect(entered[0].detail.entry.isIntersecting).toBe(true)
    expect(typeof entered[0].detail.entry.intersectionRatio).toBe("number")

    application.stop()
    document.body.innerHTML = ""
  })

  test("once unobserves after the first entry — scrolling away and back fires nothing more", async () => {
    document.body.innerHTML = markup({ once: true })
    const application = Application.start()
    application.register("cw--intersection", IntersectionController)

    const entered = []
    document.addEventListener("cw--intersection:entered", (e) => entered.push(e))

    await scrollSentinelIntoView()
    expect(entered).toHaveLength(1)

    window.scrollTo(0, 0)
    await scrollSentinelIntoView()

    expect(entered).toHaveLength(1)

    application.stop()
    document.body.innerHTML = ""
  })

  test("dispatches left when scrolled back out of view", async () => {
    document.body.innerHTML = markup()
    const application = Application.start()
    application.register("cw--intersection", IntersectionController)

    const left = []
    document.addEventListener("cw--intersection:left", (e) => left.push(e))

    await scrollSentinelIntoView()
    window.scrollTo(0, 0)
    await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))

    expect(left).toHaveLength(1)

    application.stop()
    document.body.innerHTML = ""
  })
})
