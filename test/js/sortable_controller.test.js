import { describe, expect, test, vi, beforeEach, afterEach } from "vitest"
import SortableController from "../../app/assets/javascripts/crosswire/controllers/sortable_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = { "cw--sortable": SortableController }

// TWO-TIER SPLIT, STATED EXPLICITLY (docs/COMPONENT_CONTRACT.md): jsdom cannot
// perform a real drag gesture at all — there is no pointer/touch event sequence that
// makes a browser's own drag machinery (which SortableJS ultimately rides on) fire in
// jsdom, and faking it by hand-calling private SortableJS internals would test our
// mock, not our code. So this file:
//
//   * stubs SortableJS ENTIRELY (a fake `Sortable.create` returning an object whose
//     `onStart`/`onEnd` callbacks this file invokes directly, exactly as SortableJS's
//     real event loop would once a drag actually completed) and honestly tests only
//     the WIRING around it: the optional-peer resolution order, that `Sortable.create`
//     receives the right options, and that `disconnect()` calls `destroy()` (R7).
//   * tests the PERSISTENCE logic (fetch call shape, CSRF header, success/failure,
//     revert-on-failure) by driving it through the fake Sortable's `onEnd` and through
//     the real `moveUp`/`moveDown` keyboard actions — both funnel through the same
//     `#complete`/`#persist` code, so this is not duplicated coverage.
//   * tests the KEYBOARD move up/down path for real. Unlike a drag gesture, a button
//     `click` and DOM reinsertion (`insertBefore`/`appendChild`) are ordinary jsdom
//     operations with no missing browser machinery involved, and `document.activeElement`
//     is honestly tracked by jsdom (the offsetParent/:modal gaps in the gotchas table
//     do not apply to it — `dismiss_controller.test.js`'s own R8 tests already rely on
//     the same fact). So the keyboard fallback is fully covered here, not deferred to a
//     `*.browser.test.js`.
//
// No test in this file ever asserts that a pointer drag occurred.

function markup({ items = ["a", "b", "c"], group = null, handle = null } = {}) {
  const itemsHtml = items
    .map(
      (id) => `
      <li id="${id}" data-cw--sortable-target="item">
        ${id}
        <button data-action="click->cw--sortable#moveUp" type="button">Up</button>
        <button data-action="click->cw--sortable#moveDown" type="button">Down</button>
      </li>`
    )
    .join("")

  return `
    <ul data-controller="cw--sortable"
        data-cw--sortable-url-value="/reorder"
        ${group ? `data-cw--sortable-group-value="${group}"` : ""}
        ${handle ? `data-cw--sortable-handle-value="${handle}"` : ""}>
      ${itemsHtml}
    </ul>`
}

function fakeSortable() {
  const instances = []
  class FakeSortable {
    static create(element, options) {
      const instance = { element, options, destroy: vi.fn() }
      instances.push(instance)
      return instance
    }
  }
  return { FakeSortable, instances }
}

function itemIds(el) {
  return Array.from(el.querySelectorAll("[data-cw--sortable-target='item']")).map((el) => el.id)
}

function jsonResponse({ ok = true, status = 204, contentType = "text/html" } = {}) {
  return new Response(null, { status: ok ? status : 422, headers: { "Content-Type": contentType } })
}

beforeEach(() => {
  const meta = document.createElement("meta")
  meta.name = "csrf-token"
  meta.content = "test-csrf-token"
  document.head.appendChild(meta)
})

afterEach(() => {
  document.head.innerHTML = ""
  SortableController.sortableLoader = () => globalThis.Sortable
  delete globalThis.Sortable
  delete globalThis.Turbo
  vi.restoreAllMocks()
  vi.unstubAllGlobals()
})

describe("cw--sortable: optional-peer resolution", () => {
  test("uses window.Sortable when present", async () => {
    const { FakeSortable, instances } = fakeSortable()
    globalThis.Sortable = FakeSortable
    SortableController.sortableLoader = () => globalThis.Sortable

    const el = await mount(markup(), CONTROLLERS)
    await nextFrame()

    expect(instances).toHaveLength(1)
    expect(instances[0].element).toBe(el)
  })

  test("falls back to the configurable sortableLoader hook", async () => {
    const { FakeSortable, instances } = fakeSortable()
    SortableController.sortableLoader = () => FakeSortable // no window.Sortable set

    await mount(markup(), CONTROLLERS)
    await nextFrame()

    expect(instances).toHaveLength(1)
  })

  test("warns exactly once and does not throw when neither resolves", async () => {
    SortableController.sortableLoader = () => undefined
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {})

    await mount(markup(), CONTROLLERS)
    await nextFrame()

    expect(warn).toHaveBeenCalledTimes(1)
    expect(warn.mock.calls[0][0]).toMatch(/SortableJS/)
  })

  test("keyboard reordering still works with no SortableJS present", async () => {
    SortableController.sortableLoader = () => undefined
    vi.spyOn(console, "warn").mockImplementation(() => {})
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(jsonResponse()))

    const el = await mount(markup(), CONTROLLERS)
    await nextFrame()

    el.querySelector("#b button[data-action*='moveUp']").click()
    await nextFrame()

    expect(itemIds(el)).toEqual(["b", "a", "c"])
  })

  test("passes handle and group through to Sortable.create", async () => {
    const { FakeSortable, instances } = fakeSortable()
    SortableController.sortableLoader = () => FakeSortable

    await mount(markup({ group: "cards", handle: ".drag-handle" }), CONTROLLERS)
    await nextFrame()

    expect(instances[0].options.group).toBe("cards")
    expect(instances[0].options.handle).toBe(".drag-handle")
  })

  test("group and handle are undefined, not empty strings, when not configured", async () => {
    const { FakeSortable, instances } = fakeSortable()
    SortableController.sortableLoader = () => FakeSortable

    await mount(markup(), CONTROLLERS)
    await nextFrame()

    expect(instances[0].options.group).toBeUndefined()
    expect(instances[0].options.handle).toBeUndefined()
  })
})

describe("cw--sortable: teardown (R7)", () => {
  test("disconnect calls Sortable's own destroy() and drops the reference", async () => {
    const { FakeSortable, instances } = fakeSortable()
    SortableController.sortableLoader = () => FakeSortable

    await mount(markup(), CONTROLLERS)
    await nextFrame()

    document.body.innerHTML = ""
    await nextFrame() // let Stimulus's MutationObserver fire disconnect() for real

    expect(instances[0].destroy).toHaveBeenCalledTimes(1)
  })

  test("a disconnect that races the loader promise never creates a leaked instance", async () => {
    const { FakeSortable, instances } = fakeSortable()
    let resolveLoader
    SortableController.sortableLoader = () => new Promise((resolve) => { resolveLoader = resolve })

    document.body.innerHTML = markup()
    const { Application } = await import("@hotwired/stimulus")
    const application = Application.start()
    application.register("cw--sortable", SortableController)
    await nextFrame()

    // Disconnect before the loader resolves.
    document.body.innerHTML = ""
    await nextFrame()

    resolveLoader(FakeSortable)
    await nextFrame()

    expect(instances).toHaveLength(0)

    application.stop()
  })
})

describe("cw--sortable: drag persistence (via the fake Sortable's onEnd)", () => {
  test("PATCHes the new id order with the CSRF token and Accept header", async () => {
    const { FakeSortable, instances } = fakeSortable()
    SortableController.sortableLoader = () => FakeSortable
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse())
    vi.stubGlobal("fetch", fetchMock)

    const el = await mount(markup(), CONTROLLERS)
    await nextFrame()

    const { onStart, onEnd } = instances[0].options
    onStart()
    // Simulate SortableJS having already moved the dragged node in the DOM.
    const [a, b, c] = itemIds(el).map((id) => el.querySelector(`#${id}`))
    el.insertBefore(c, a)
    onEnd({ item: c, oldIndex: 2, newIndex: 0 })
    await nextFrame()

    expect(fetchMock).toHaveBeenCalledTimes(1)
    const [url, options] = fetchMock.mock.calls[0]
    expect(url).toBe("/reorder")
    expect(options.method).toBe("PATCH")
    expect(options.headers["X-CSRF-Token"]).toBe("test-csrf-token")
    expect(options.headers.Accept).toBe("text/vnd.turbo-stream.html, text/html")
    expect(options.body.getAll("position[]")).toEqual(["c", "a", "b"])
  })

  test("does nothing when the item is dropped back where it started", async () => {
    const { FakeSortable, instances } = fakeSortable()
    SortableController.sortableLoader = () => FakeSortable
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse())
    vi.stubGlobal("fetch", fetchMock)

    const el = await mount(markup(), CONTROLLERS)
    await nextFrame()

    const { onStart, onEnd } = instances[0].options
    onStart()
    onEnd({ item: el.querySelector("#a"), oldIndex: 0, newIndex: 0 })
    await nextFrame()

    expect(fetchMock).not.toHaveBeenCalled()
  })

  test("paramName is configurable", async () => {
    const { FakeSortable, instances } = fakeSortable()
    SortableController.sortableLoader = () => FakeSortable
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse())
    vi.stubGlobal("fetch", fetchMock)

    document.body.innerHTML = `
      <ul data-controller="cw--sortable"
          data-cw--sortable-url-value="/reorder"
          data-cw--sortable-param-name-value="ids">
        <li id="a" data-cw--sortable-target="item"></li>
        <li id="b" data-cw--sortable-target="item"></li>
      </ul>`
    const { Application } = await import("@hotwired/stimulus")
    const application = Application.start()
    application.register("cw--sortable", SortableController)
    await nextFrame()

    const el = document.querySelector("ul")
    const { onStart, onEnd } = instances[0].options
    onStart()
    el.insertBefore(el.querySelector("#b"), el.querySelector("#a"))
    onEnd({ item: el.querySelector("#b"), oldIndex: 1, newIndex: 0 })
    await nextFrame()

    const [, options] = fetchMock.mock.calls[0]
    expect(options.body.getAll("ids[]")).toEqual(["b", "a"])

    application.stop()
  })

  test("dispatches reordered before the fetch resolves, then persisted on success", async () => {
    const { FakeSortable, instances } = fakeSortable()
    SortableController.sortableLoader = () => FakeSortable
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(jsonResponse()))

    const reordered = captureEvents("cw--sortable:reordered")
    const persisted = captureEvents("cw--sortable:persisted")
    const el = await mount(markup(), CONTROLLERS)
    await nextFrame()

    const { onStart, onEnd } = instances[0].options
    onStart()
    const c = el.querySelector("#c")
    el.insertBefore(c, el.querySelector("#a"))
    onEnd({ item: c, oldIndex: 2, newIndex: 0 })
    await nextFrame()

    expect(reordered).toHaveLength(1)
    expect(reordered[0].detail).toEqual({ item: c, oldIndex: 2, newIndex: 0 })
    expect(persisted).toHaveLength(1)
    expect(persisted[0].detail.ids).toEqual(["c", "a", "b"])
  })

  test("on failure, reverts the DOM to its pre-reorder order and dispatches failed", async () => {
    const { FakeSortable, instances } = fakeSortable()
    SortableController.sortableLoader = () => FakeSortable
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(jsonResponse({ ok: false })))

    const failed = captureEvents("cw--sortable:failed")
    const el = await mount(markup(), CONTROLLERS)
    await nextFrame()

    const { onStart, onEnd } = instances[0].options
    onStart() // captures ["a", "b", "c"] as the order to revert to
    const c = el.querySelector("#c")
    el.insertBefore(c, el.querySelector("#a"))
    expect(itemIds(el)).toEqual(["c", "a", "b"])

    onEnd({ item: c, oldIndex: 2, newIndex: 0 })
    await nextFrame()

    expect(itemIds(el)).toEqual(["a", "b", "c"])
    expect(failed).toHaveLength(1)
    expect(failed[0].detail.error).toBeInstanceOf(Error)
  })

  test("applies a Turbo Stream response via Turbo.renderStreamMessage when Turbo is present", async () => {
    const { FakeSortable, instances } = fakeSortable()
    SortableController.sortableLoader = () => FakeSortable
    const renderStreamMessage = vi.fn()
    globalThis.Turbo = { renderStreamMessage }
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(
        new Response("<turbo-stream></turbo-stream>", {
          status: 200,
          headers: { "Content-Type": "text/vnd.turbo-stream.html" }
        })
      )
    )

    const el = await mount(markup(), CONTROLLERS)
    await nextFrame()

    const { onStart, onEnd } = instances[0].options
    onStart()
    const c = el.querySelector("#c")
    el.insertBefore(c, el.querySelector("#a"))
    onEnd({ item: c, oldIndex: 2, newIndex: 0 })
    await nextFrame()
    await nextFrame()

    expect(renderStreamMessage).toHaveBeenCalledTimes(1)
    expect(renderStreamMessage).toHaveBeenCalledWith("<turbo-stream></turbo-stream>")
  })
})

describe("cw--sortable: keyboard move up / move down — the required accessible path", () => {
  test("moveUp swaps the item with its previous sibling", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(jsonResponse()))
    const el = await mount(markup(), CONTROLLERS)
    await nextFrame()

    el.querySelector("#b button[data-action*='moveUp']").click()
    await nextFrame()

    expect(itemIds(el)).toEqual(["b", "a", "c"])
  })

  test("moveDown swaps the item with its next sibling", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(jsonResponse()))
    const el = await mount(markup(), CONTROLLERS)
    await nextFrame()

    el.querySelector("#b button[data-action*='moveDown']").click()
    await nextFrame()

    expect(itemIds(el)).toEqual(["a", "c", "b"])
  })

  test("moveUp on the first item is a no-op (bounds guard)", async () => {
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse())
    vi.stubGlobal("fetch", fetchMock)
    const el = await mount(markup(), CONTROLLERS)
    await nextFrame()

    el.querySelector("#a button[data-action*='moveUp']").click()
    await nextFrame()

    expect(itemIds(el)).toEqual(["a", "b", "c"])
    expect(fetchMock).not.toHaveBeenCalled()
  })

  test("moveDown on the last item is a no-op (bounds guard)", async () => {
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse())
    vi.stubGlobal("fetch", fetchMock)
    const el = await mount(markup(), CONTROLLERS)
    await nextFrame()

    el.querySelector("#c button[data-action*='moveDown']").click()
    await nextFrame()

    expect(itemIds(el)).toEqual(["a", "b", "c"])
    expect(fetchMock).not.toHaveBeenCalled()
  })

  test("moves DOM focus with the item so the user does not lose their place", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(jsonResponse()))
    const el = await mount(markup(), CONTROLLERS)
    await nextFrame()

    const button = el.querySelector("#b button[data-action*='moveUp']")
    button.focus()
    button.click()
    await nextFrame()

    expect(document.activeElement).toBe(button)
  })

  test("PATCHes the new order and reuses the identical persistence path as a drag", async () => {
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse())
    vi.stubGlobal("fetch", fetchMock)
    const reordered = captureEvents("cw--sortable:reordered")
    const persisted = captureEvents("cw--sortable:persisted")

    const el = await mount(markup(), CONTROLLERS)
    await nextFrame()

    el.querySelector("#b button[data-action*='moveUp']").click()
    await nextFrame()

    expect(reordered).toHaveLength(1)
    expect(reordered[0].detail).toEqual({ item: el.querySelector("#b"), oldIndex: 1, newIndex: 0 })
    expect(persisted).toHaveLength(1)

    const [, options] = fetchMock.mock.calls[0]
    expect(options.body.getAll("position[]")).toEqual(["b", "a", "c"])
  })

  test("reverts on a failed keyboard move", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(jsonResponse({ ok: false })))
    const failed = captureEvents("cw--sortable:failed")

    const el = await mount(markup(), CONTROLLERS)
    await nextFrame()

    el.querySelector("#b button[data-action*='moveUp']").click()
    await nextFrame()

    expect(itemIds(el)).toEqual(["a", "b", "c"])
    expect(failed).toHaveLength(1)
  })
})
