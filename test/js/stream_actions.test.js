import { afterEach, beforeEach, describe, expect, test, vi } from "vitest"
import { registerCrosswireStreamActions, versionedReplace } from "../../app/assets/javascripts/crosswire/stream_actions.js"
import { captureEvents } from "./setup.js"

// jsdom tier — the FULL versionedReplace decision table, bound to a fake
// StreamElement ({ templateContent, targetElements, getAttribute }) with a spied
// window.Turbo.StreamActions.replace, and WITHOUT ever importing @hotwired/turbo.
// Honest here specifically because these three properties/methods are the entire
// surface Turbo itself calls versionedReplace through (see stream_actions.js's
// docstring on `this` and `scopedToTargets`) — nothing here needs a real morph, real
// custom elements, or a real Turbo.renderStreamMessage to verify the decision table.
// The REQUIRED, authoritative end-to-end coverage — real @hotwired/turbo, real
// Turbo.renderStreamMessage, the method="morph" passthrough actually morphing — lives
// in stream_actions.browser.test.js.

function fakePayload(version) {
  const root = document.createElement("div")
  root.id = "payload-root"
  if (version !== undefined) root.dataset.cwVersion = String(version)
  const frag = document.createDocumentFragment()
  frag.append(root)
  return frag
}

function fakeTarget(version) {
  const el = document.createElement("div")
  if (version !== undefined) el.dataset.cwVersion = String(version)
  document.body.append(el)
  return el
}

function fakeStream({ payloadVersion, targets, method = null }) {
  return {
    getAttribute: (name) => (name === "method" ? method : null),
    templateContent: fakePayload(payloadVersion),
    targetElements: targets
  }
}

let replaceSpy

beforeEach(() => {
  replaceSpy = vi.fn()
  window.Turbo = { StreamActions: { replace: replaceSpy } }
})

afterEach(() => {
  delete window.Turbo
})

describe("versionedReplace — the decision table", () => {
  test("payloadVersion > pageVersion applies", () => {
    const target = fakeTarget(1)
    versionedReplace.call(fakeStream({ payloadVersion: 2, targets: [target] }))

    expect(replaceSpy).toHaveBeenCalledTimes(1)
    expect(replaceSpy.mock.contexts[0].targetElements).toEqual([target])
  })

  test("payloadVersion === pageVersion skips — a redelivery, not an update", () => {
    const target = fakeTarget(2)
    versionedReplace.call(fakeStream({ payloadVersion: 2, targets: [target] }))

    expect(replaceSpy).not.toHaveBeenCalled()
  })

  test("payloadVersion < pageVersion skips", () => {
    const target = fakeTarget(5)
    versionedReplace.call(fakeStream({ payloadVersion: 2, targets: [target] }))

    expect(replaceSpy).not.toHaveBeenCalled()
  })

  test("pageVersion NaN (no data-cw-version yet) applies unconditionally — fail open toward freshness", () => {
    const target = fakeTarget(undefined)
    versionedReplace.call(fakeStream({ payloadVersion: 2, targets: [target] }))

    expect(replaceSpy).toHaveBeenCalledTimes(1)
    expect(replaceSpy.mock.contexts[0].targetElements).toEqual([target])
  })

  test("payloadVersion NaN applies (degrades to a plain replace) and warns exactly once", () => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {})
    const target = fakeTarget(3)

    versionedReplace.call(fakeStream({ payloadVersion: undefined, targets: [target] }))

    expect(replaceSpy).toHaveBeenCalledTimes(1)
    expect(warn).toHaveBeenCalledTimes(1)
    expect(warn.mock.calls[0][0]).toMatch(/data-cw-version/)

    warn.mockRestore()
  })

  test("a SECOND payloadVersion-NaN delivery still applies but does not warn again — logged once per page load", () => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {})
    const target = fakeTarget(3)

    versionedReplace.call(fakeStream({ payloadVersion: undefined, targets: [target] }))

    expect(replaceSpy).toHaveBeenCalledTimes(1)
    expect(warn).not.toHaveBeenCalled()

    warn.mockRestore()
  })

  test("method=\"morph\" is forwarded through to the scoped `this` passed to Turbo.StreamActions.replace", () => {
    const target = fakeTarget(1)
    versionedReplace.call(fakeStream({ payloadVersion: 2, targets: [target], method: "morph" }))

    expect(replaceSpy).toHaveBeenCalledTimes(1)
    expect(replaceSpy.mock.contexts[0].getAttribute("method")).toBe("morph")
  })
})

describe("versionedReplace — multiple targets diverge independently", () => {
  test("one target applies while a sibling target in the same message skips", () => {
    const fresh = fakeTarget(1) // payload (2) > pageVersion (1) -> applies
    const stale = fakeTarget(9) // payload (2) < pageVersion (9) -> skips
    const seen = captureEvents("cw--stream:skipped")

    versionedReplace.call(fakeStream({ payloadVersion: 2, targets: [fresh, stale] }))

    expect(replaceSpy).toHaveBeenCalledTimes(1)
    expect(replaceSpy.mock.contexts[0].targetElements).toEqual([fresh])
    expect(seen).toHaveLength(1)
    expect(seen[0].target).toBe(stale)
  })

  test("every target skipping means replace is never called at all", () => {
    const a = fakeTarget(9)
    const b = fakeTarget(10)

    versionedReplace.call(fakeStream({ payloadVersion: 2, targets: [a, b] }))

    expect(replaceSpy).not.toHaveBeenCalled()
  })
})

describe("versionedReplace — cw--stream:skipped event", () => {
  test("bubbles, and carries {action, payloadVersion, pageVersion} in detail", () => {
    const target = fakeTarget(5)
    const seen = captureEvents("cw--stream:skipped")

    versionedReplace.call(fakeStream({ payloadVersion: 2, targets: [target] }))

    expect(seen).toHaveLength(1)
    const event = seen[0]
    expect(event.bubbles).toBe(true)
    expect(event.target).toBe(target)
    expect(event.detail).toEqual({ action: "versioned_replace", payloadVersion: 2, pageVersion: 5 })
  })

  test("is not dispatched for a target that applies", () => {
    const target = fakeTarget(1)
    const seen = captureEvents("cw--stream:skipped")

    versionedReplace.call(fakeStream({ payloadVersion: 2, targets: [target] }))

    expect(seen).toHaveLength(0)
  })
})

describe("registerCrosswireStreamActions", () => {
  test("installs versionedReplace onto Turbo.StreamActions.versioned_replace", () => {
    const fakeTurbo = { StreamActions: {} }
    registerCrosswireStreamActions(fakeTurbo)

    expect(fakeTurbo.StreamActions.versioned_replace).toBe(versionedReplace)
  })

  test("defaults to window.Turbo when called with no argument", () => {
    window.Turbo = { StreamActions: {} }
    registerCrosswireStreamActions()

    expect(window.Turbo.StreamActions.versioned_replace).toBe(versionedReplace)
  })

  test("raises a clear error when there is no Turbo to register into", () => {
    delete window.Turbo
    expect(() => registerCrosswireStreamActions()).toThrow(/StreamActions/)
  })
})
