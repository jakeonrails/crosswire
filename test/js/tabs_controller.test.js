import { describe, expect, test, vi } from "vitest"
import TabsController from "../../app/assets/javascripts/crosswire/controllers/tabs_controller.js"
import RovingFocusController from "../../app/assets/javascripts/crosswire/controllers/roving_focus_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

const CONTROLLERS = {
  "cw--tabs": TabsController,
  "cw--roving-focus": RovingFocusController
}

// Both controllers are registered and stacked on the same tablist element, exactly
// as the presenter builds it — this test file exercises the real composition, not a
// mock of roving-focus, so a regression in either controller's contract shows up
// here too.
function markup({ selected = "profile", activation = null, param = null, ids = ["profile", "billing"] } = {}) {
  const tabs = ids
    .map((id) => {
      const current = id === selected
      return `<button id="settings-tab-${id}"
                       data-cw--roving-focus-target="item"
                       data-cw--tabs-target="tab"
                       data-cw--tabs-id-param="${id}"
                       tabindex="${current ? "0" : "-1"}"
                       data-action="click->cw--tabs#select keydown.enter->cw--tabs#select keydown.space->cw--tabs#select"
                       role="tab"
                       aria-selected="${current}"
                       aria-controls="settings-panel-${id}">${id}</button>`
    })
    .join("")

  const panels = ids
    .map((id) => {
      const current = id === selected
      return `<div id="settings-panel-${id}"
                    data-cw--tabs-target="panel"
                    role="tabpanel"
                    aria-labelledby="settings-tab-${id}"
                    tabindex="0"
                    ${current ? "" : "hidden"}>${id} content</div>`
    })
    .join("")

  return `
    <div data-controller="cw--roving-focus cw--tabs"
         data-cw--roving-focus-orientation-value="horizontal"
         data-cw--tabs-selected-value="${selected}"
         ${activation ? `data-cw--tabs-activation-value="${activation}"` : ""}
         ${param ? `data-cw--tabs-param-value="${param}"` : ""}
         data-action="cw--roving-focus:moved->cw--tabs#selectFromMove">
      <div data-action="keydown->cw--roving-focus#navigate" role="tablist">
        ${tabs}
      </div>
      ${panels}
    </div>`
}

function key(k) {
  return new KeyboardEvent("keydown", { key: k, bubbles: true, cancelable: true })
}

describe("cw--tabs", () => {
  test("renders the server-selected tab/panel state on connect", async () => {
    const root = await mount(markup({ selected: "billing" }), CONTROLLERS)

    expect(root.querySelector("#settings-tab-billing").getAttribute("aria-selected")).toBe("true")
    expect(root.querySelector("#settings-tab-profile").getAttribute("aria-selected")).toBe("false")
    expect(document.getElementById("settings-panel-billing").hidden).toBe(false)
    expect(document.getElementById("settings-panel-profile").hidden).toBe(true)
  })

  test("clicking a tab selects it and shows its panel", async () => {
    const root = await mount(markup(), CONTROLLERS)

    root.querySelector("#settings-tab-billing").click()
    await nextFrame()

    expect(root.querySelector("#settings-tab-billing").getAttribute("aria-selected")).toBe("true")
    expect(root.querySelector("#settings-tab-profile").getAttribute("aria-selected")).toBe("false")
    expect(document.getElementById("settings-panel-billing").hidden).toBe(false)
    expect(document.getElementById("settings-panel-profile").hidden).toBe(true)
  })

  test("dispatches changed with the new selection", async () => {
    const changed = captureEvents("cw--tabs:changed")
    const root = await mount(markup(), CONTROLLERS)

    root.querySelector("#settings-tab-billing").click()
    await nextFrame()

    expect(changed).toHaveLength(1)
    expect(changed[0].detail.selected).toBe("billing")
  })

  test("does not announce changed on initial connect", async () => {
    const changed = captureEvents("cw--tabs:changed")
    await mount(markup({ selected: "billing" }), CONTROLLERS)

    expect(changed).toHaveLength(0)
  })

  test("clicking the already-selected tab is a no-op (no duplicate event)", async () => {
    const changed = captureEvents("cw--tabs:changed")
    const root = await mount(markup({ selected: "profile" }), CONTROLLERS)

    root.querySelector("#settings-tab-profile").click()
    await nextFrame()

    expect(changed).toHaveLength(0)
  })

  // --- composition with roving-focus (automatic activation, the default) -----------

  test("automatic activation: arrow-key movement selects the tab it lands on", async () => {
    const root = await mount(markup({ selected: "profile" }), CONTROLLERS)
    const profile = root.querySelector("#settings-tab-profile")

    profile.focus()
    profile.dispatchEvent(key("ArrowRight"))
    await nextFrame()

    // roving-focus moved DOM focus AND tabindex...
    expect(document.activeElement.id).toBe("settings-tab-billing")
    expect(root.querySelector("#settings-tab-billing").getAttribute("tabindex")).toBe("0")
    // ...and cw--tabs reacted to the moved event by selecting it too.
    expect(root.querySelector("#settings-tab-billing").getAttribute("aria-selected")).toBe("true")
    expect(document.getElementById("settings-panel-billing").hidden).toBe(false)
  })

  // --- composition with roving-focus (manual activation) ---------------------------

  test("manual activation: arrow-key movement moves focus without selecting", async () => {
    const root = await mount(markup({ selected: "profile", activation: "manual" }), CONTROLLERS)
    const profile = root.querySelector("#settings-tab-profile")

    profile.focus()
    profile.dispatchEvent(key("ArrowRight"))
    await nextFrame()

    // Focus (and the roving stop) moved...
    expect(document.activeElement.id).toBe("settings-tab-billing")
    expect(root.querySelector("#settings-tab-billing").getAttribute("tabindex")).toBe("0")
    // ...but selection did NOT follow.
    expect(root.querySelector("#settings-tab-billing").getAttribute("aria-selected")).toBe("false")
    expect(root.querySelector("#settings-tab-profile").getAttribute("aria-selected")).toBe("true")
    expect(document.getElementById("settings-panel-profile").hidden).toBe(false)
  })

  test("manual activation: Enter on the focused tab selects it", async () => {
    const root = await mount(markup({ selected: "profile", activation: "manual" }), CONTROLLERS)
    const profile = root.querySelector("#settings-tab-profile")

    profile.focus()
    profile.dispatchEvent(key("ArrowRight"))
    await nextFrame()

    document.activeElement.dispatchEvent(key("Enter"))
    await nextFrame()

    expect(root.querySelector("#settings-tab-billing").getAttribute("aria-selected")).toBe("true")
    expect(document.getElementById("settings-panel-billing").hidden).toBe(false)
  })

  test("manual activation: Space on the focused tab selects it", async () => {
    const root = await mount(markup({ selected: "profile", activation: "manual" }), CONTROLLERS)
    const profile = root.querySelector("#settings-tab-profile")

    profile.focus()
    profile.dispatchEvent(key("ArrowRight"))
    await nextFrame()

    document.activeElement.dispatchEvent(key(" "))
    await nextFrame()

    expect(root.querySelector("#settings-tab-billing").getAttribute("aria-selected")).toBe("true")
  })

  // --- URL sync ----------------------------------------------------------------------

  test("param sync updates the URL via history.replaceState on selection", async () => {
    const original = window.location.href
    const replaceSpy = vi.spyOn(window.history, "replaceState")

    const root = await mount(markup({ selected: "profile", param: "tab" }), CONTROLLERS)
    root.querySelector("#settings-tab-billing").click()
    await nextFrame()

    expect(replaceSpy).toHaveBeenCalled()
    const [, , url] = replaceSpy.mock.calls[0]
    expect(String(url)).toContain("tab=billing")

    replaceSpy.mockRestore()
    window.history.replaceState(null, "", original)
  })

  test("without param, selecting a tab never touches history", async () => {
    const replaceSpy = vi.spyOn(window.history, "replaceState")

    const root = await mount(markup({ selected: "profile" }), CONTROLLERS)
    root.querySelector("#settings-tab-billing").click()
    await nextFrame()

    expect(replaceSpy).not.toHaveBeenCalled()
    replaceSpy.mockRestore()
  })

  // --- R3-flavoured guard: no matching panel does not throw -------------------------

  test("selecting a tab with no matching panel in the DOM does not throw", async () => {
    const html = `
      <div data-controller="cw--roving-focus cw--tabs"
           data-cw--tabs-selected-value="profile"
           data-action="keydown->cw--roving-focus#navigate cw--roving-focus:moved->cw--tabs#selectFromMove"
           role="tablist">
        <button data-cw--roving-focus-target="item" data-cw--tabs-target="tab"
                data-cw--tabs-id-param="profile" tabindex="0"
                data-action="click->cw--tabs#select" role="tab"
                aria-selected="true" id="settings-tab-profile">profile</button>
      </div>`

    await mount(html, CONTROLLERS)

    expect(() => document.getElementById("settings-tab-profile").click()).not.toThrow()
  })
})
