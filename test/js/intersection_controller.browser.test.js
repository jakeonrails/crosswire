import { describe, expect, test } from "vitest"
import IntersectionController from "../../app/assets/javascripts/crosswire/controllers/intersection_controller.js"
import { mount } from "./setup.js"

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
// Run with `npm run test:browser` after `npx playwright install chromium` — wired up
// in vitest.browser.config.js. The assertions below are written against real browser
// APIs (a real IntersectionObserver, real scrolling, a real viewport).
//
// Uses the shared `mount()` helper from setup.js rather than a hand-rolled
// Application.start()/register(), so this file gets the same load-bearing afterEach
// teardown order as every other suite (DOM cleared and a tick awaited BEFORE
// Application#stop(), letting disconnect() actually run and the IntersectionObserver
// actually get torn down between tests — see setup.js and the gotchas table in
// docs/COMPONENT_CONTRACT.md).

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
    await mount(markup(), { "cw--intersection": IntersectionController })

    const entered = []
    document.addEventListener("cw--intersection:entered", (e) => entered.push(e))

    await scrollSentinelIntoView()

    expect(entered).toHaveLength(1)
    expect(entered[0].detail.entry.isIntersecting).toBe(true)
    expect(typeof entered[0].detail.entry.intersectionRatio).toBe("number")
  })

  test("once unobserves after the first entry — scrolling away and back fires nothing more", async () => {
    await mount(markup({ once: true }), { "cw--intersection": IntersectionController })

    const entered = []
    document.addEventListener("cw--intersection:entered", (e) => entered.push(e))

    await scrollSentinelIntoView()
    expect(entered).toHaveLength(1)

    window.scrollTo(0, 0)
    await scrollSentinelIntoView()

    expect(entered).toHaveLength(1)
  })

  test("dispatches left when scrolled back out of view", async () => {
    await mount(markup(), { "cw--intersection": IntersectionController })

    const left = []
    document.addEventListener("cw--intersection:left", (e) => left.push(e))

    await scrollSentinelIntoView()
    window.scrollTo(0, 0)
    await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))

    expect(left).toHaveLength(1)
  })
})
