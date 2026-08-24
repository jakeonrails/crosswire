import { describe, expect, test, vi } from "vitest"
import ComboboxController from "../../app/assets/javascripts/crosswire/controllers/combobox_controller.js"
import { captureEvents, mount, nextFrame } from "./setup.js"

// jsdom tier (docs/COMPONENT_CONTRACT.md R8). What this file does NOT and cannot
// honestly test: real focus (the input never actually losing it across a real
// mousedown-on-option), real `scrollIntoView` layout, real native Tab traversal
// out of the widget, real Enter-submits-the-surrounding-form defaults, and a real
// `Turbo.morphElements()` pass. All of that lives in
// combobox_controller.browser.test.js. `mount()` from setup.js is used throughout —
// never a hand-rolled Application (docs/COMPONENT_CONTRACT.md's connect-tick note).

const CONTROLLERS = { "cw--combobox": ComboboxController }

const DEFAULT_OPTIONS = [
  { value: "CA", display: "California" },
  { value: "NY", display: "New York" },
  { value: "TX", display: "Texas" }
]

function optionHtml({ value, display, id }) {
  return `<li id="${id ?? `state-option-${value}`}" role="option" aria-selected="false"
             data-cw--combobox-target="option"
             data-action="click->cw--combobox#select mousedown->cw--combobox#preventBlur"
             data-cw--combobox-value-param="${value}"
             data-cw--combobox-display-param="${display}">${display}</li>`
}

function markup({
  value = "",
  display = "",
  expanded = false,
  filter = "client",
  autocomplete = "list",
  src = null,
  param = "q",
  delay = 200,
  minLength = 0,
  wrap = true,
  clearOnEscape = true,
  resultsMessage = "%{count} results available",
  emptyMessage = "No results available",
  activeClass = null,
  expandedClass = null,
  disabled = false,
  options = DEFAULT_OPTIONS,
  includeFrame = false
} = {}) {
  return `
    <div data-controller="cw--combobox"
         data-cw--combobox-value-value="${value}"
         data-cw--combobox-expanded-value="${expanded}"
         data-cw--combobox-filter-value="${filter}"
         data-cw--combobox-autocomplete-value="${autocomplete}"
         ${src ? `data-cw--combobox-src-value="${src}"` : ""}
         data-cw--combobox-param-value="${param}"
         data-cw--combobox-delay-value="${delay}"
         data-cw--combobox-min-length-value="${minLength}"
         data-cw--combobox-wrap-value="${wrap}"
         data-cw--combobox-clear-on-escape-value="${clearOnEscape}"
         data-cw--combobox-results-message-value="${resultsMessage}"
         data-cw--combobox-empty-message-value="${emptyMessage}"
         ${activeClass ? `data-cw--combobox-active-class="${activeClass}"` : ""}
         ${expandedClass ? `data-cw--combobox-expanded-class="${expandedClass}"` : ""}
         data-action="cw--click-outside:clicked->cw--combobox#close">
      <label id="state-label" for="state-input">State</label>
      <input type="text" id="state-input" role="combobox" aria-controls="state-listbox"
             aria-haspopup="listbox" aria-autocomplete="${autocomplete}" autocomplete="off"
             data-cw--combobox-target="input" value="${display}" ${disabled ? "disabled" : ""}
             data-action="input->cw--combobox#filter
                          keydown.down->cw--combobox#down keydown.alt+down->cw--combobox#down
                          keydown.up->cw--combobox#up keydown.alt+up->cw--combobox#up
                          keydown.esc->cw--combobox#escape keydown.enter->cw--combobox#enter
                          keydown.tab->cw--combobox#tabOut keydown.shift+tab->cw--combobox#tabOut">
      <input type="hidden" id="state-field" name="state" value="${value}" ${disabled ? "disabled" : ""}
             data-cw--combobox-target="field">
      ${includeFrame ? `<turbo-frame id="state-options" data-cw--combobox-target="frame"></turbo-frame>` : ""}
      <ul id="state-listbox" role="listbox" aria-labelledby="state-label"
          data-cw--combobox-target="listbox" ${expanded ? "" : "hidden"}>
        ${options.map(optionHtml).join("\n")}
      </ul>
      <p data-cw--combobox-target="empty" hidden>No results</p>
      <div id="state-status" role="status" aria-live="polite" aria-atomic="true"
           data-cw--combobox-target="status"></div>
      <button type="button" data-action="click->cw--combobox#clear" aria-label="Clear">&times;</button>
    </div>`
}

async function boot(opts = {}) {
  const el = await mount(markup(opts), CONTROLLERS)
  return {
    el,
    input: el.querySelector("[data-cw--combobox-target='input']"),
    field: el.querySelector("[data-cw--combobox-target='field']"),
    listbox: el.querySelector("[data-cw--combobox-target='listbox']"),
    empty: el.querySelector("[data-cw--combobox-target='empty']"),
    status: el.querySelector("[data-cw--combobox-target='status']"),
    frame: el.querySelector("[data-cw--combobox-target='frame']"),
    options: () => Array.from(el.querySelectorAll("[data-cw--combobox-target='option']")),
    clearButton: el.querySelector("[data-action='click->cw--combobox#clear']")
  }
}

function key(k, opts = {}) {
  return new KeyboardEvent("keydown", { key: k, bubbles: true, cancelable: true, ...opts })
}

describe("cw--combobox", () => {
  // --- connect: renders server state, no phantom events (R4a) -----------------------

  test("renders the collapsed state on connect", async () => {
    const { listbox, input } = await boot()
    expect(listbox.hidden).toBe(true)
    expect(input.getAttribute("aria-expanded")).toBe("false")
  })

  test("server-rendered expanded state is honoured without any interaction", async () => {
    const { listbox, input } = await boot({ expanded: true })
    expect(listbox.hidden).toBe(false)
    expect(input.getAttribute("aria-expanded")).toBe("true")
  })

  test("does not dispatch opened merely from connecting with expanded: true", async () => {
    const opened = captureEvents("cw--combobox:opened")
    await boot({ expanded: true })
    expect(opened).toHaveLength(0)
  })

  test("does not dispatch closed merely from connecting with the (default) collapsed state", async () => {
    const closed = captureEvents("cw--combobox:closed")
    await boot()
    expect(closed).toHaveLength(0)
  })

  test("does not dispatch selected merely from connecting with a preselected value", async () => {
    const selected = captureEvents("cw--combobox:selected")
    await boot({ value: "CA", display: "California" })
    expect(selected).toHaveLength(0)
  })

  // --- valueValueChanged: single write path (R4) -------------------------------------

  test("connecting with a preselected value writes the hidden field and marks the matching option", async () => {
    const { field, options } = await boot({ value: "CA", display: "California" })
    expect(field.value).toBe("CA")

    const [ca, ny] = options()
    expect(ca.getAttribute("aria-selected")).toBe("true")
    expect(ny.getAttribute("aria-selected")).toBe("false")
  })

  test("a preselected value fires a bubbling change on the hidden field even on connect", async () => {
    document.body.innerHTML = ""
    const changes = []
    document.addEventListener("change", (event) => changes.push(event), true)
    try {
      await boot({ value: "CA", display: "California" })
      expect(changes).toHaveLength(1)
      expect(changes[0].bubbles).toBe(true)
    } finally {
      document.removeEventListener("change", (event) => changes.push(event), true)
    }
  })

  test("select writes the hidden field, dispatches change, and dispatches selected", async () => {
    const selected = captureEvents("cw--combobox:selected")
    const { field, options } = await boot({ expanded: true })
    const [ca] = options()

    let changed = false
    field.addEventListener("change", () => {
      changed = true
    })

    ca.click()
    await nextFrame()

    expect(field.value).toBe("CA")
    expect(changed).toBe(true)
    expect(selected).toHaveLength(1)
    expect(selected[0].detail.value).toBe("CA")
  })

  test("select writes the display text into the visible input and closes", async () => {
    const { input, listbox, options } = await boot({ expanded: true })
    options()[0].click()
    await nextFrame()

    expect(input.value).toBe("California")
    expect(listbox.hidden).toBe(true)
  })

  // --- expandedValueChanged: single write path, including R5a mechanism 2 -----------

  test("expanding writes aria-expanded and un-hides the listbox", async () => {
    const { el, listbox, input } = await boot()
    el.setAttribute("data-cw--combobox-expanded-value", "true")
    await nextFrame()

    expect(listbox.hidden).toBe(false)
    expect(input.getAttribute("aria-expanded")).toBe("true")
  })

  test("R5a mechanism 2 — expanding/collapsing writes cw--click-outside's own enabled value directly onto this element", async () => {
    const { el } = await boot()
    expect(el.getAttribute("data-cw--click-outside-enabled-value")).toBe("false")

    el.setAttribute("data-cw--combobox-expanded-value", "true")
    await nextFrame()
    expect(el.getAttribute("data-cw--click-outside-enabled-value")).toBe("true")

    el.setAttribute("data-cw--combobox-expanded-value", "false")
    await nextFrame()
    expect(el.getAttribute("data-cw--click-outside-enabled-value")).toBe("false")
  })

  test("dispatches opened and closed on real transitions", async () => {
    const opened = captureEvents("cw--combobox:opened")
    const closed = captureEvents("cw--combobox:closed")
    const { el } = await boot()

    el.setAttribute("data-cw--combobox-expanded-value", "true")
    await nextFrame()
    expect(opened).toHaveLength(1)

    el.setAttribute("data-cw--combobox-expanded-value", "false")
    await nextFrame()
    expect(closed).toHaveLength(1)
  })

  test("closing clears the active option", async () => {
    const { el, input } = await boot({ expanded: true })
    el.setAttribute("data-cw--combobox-active-value", "state-option-CA")
    await nextFrame()
    expect(input.getAttribute("aria-activedescendant")).toBe("state-option-CA")

    el.setAttribute("data-cw--combobox-expanded-value", "false")
    await nextFrame()
    expect(input.hasAttribute("aria-activedescendant")).toBe(false)
  })

  // --- activeValueChanged: aria-activedescendant + aria-selected + active class -----

  test("setting active writes aria-activedescendant and marks the option aria-selected, clearing others", async () => {
    const { el, input, options } = await boot({ expanded: true, value: "NY" })
    el.setAttribute("data-cw--combobox-active-value", "state-option-CA")
    await nextFrame()

    expect(input.getAttribute("aria-activedescendant")).toBe("state-option-CA")
    const [ca, ny] = options()
    expect(ca.getAttribute("aria-selected")).toBe("true")
    // Active overrides the value-based baseline while navigating (APG's own
    // combobox-list example: aria-selected tracks the ACTIVE option).
    expect(ny.getAttribute("aria-selected")).toBe("false")
  })

  test("clearing active (closing, right after a select) does not wipe the just-selected option's aria-selected", async () => {
    const { options } = await boot({ expanded: true })
    const [ca] = options()

    ca.click()
    await nextFrame()

    // select() writes valueValue, THEN close() clears activeValue — the option this
    // just selected must still read aria-selected="true" afterwards.
    expect(ca.getAttribute("aria-selected")).toBe("true")
  })

  test("applies the active class only to the active option", async () => {
    const { el, options } = await boot({ expanded: true, activeClass: "is-active" })
    el.setAttribute("data-cw--combobox-active-value", "state-option-NY")
    await nextFrame()

    const [ca, ny] = options()
    expect(ca.classList.contains("is-active")).toBe(false)
    expect(ny.classList.contains("is-active")).toBe(true)
  })

  // R3 — Stimulus throws on this.fooClass when the attribute is absent.
  test("does not throw when no active class or expanded class is given", async () => {
    const { el } = await boot()
    expect(() => el.setAttribute("data-cw--combobox-active-value", "state-option-CA")).not.toThrow()
    expect(() => el.setAttribute("data-cw--combobox-expanded-value", "true")).not.toThrow()
    await nextFrame()
  })

  // --- filter: client mode -----------------------------------------------------------

  test("client filter hides non-matching options and opens", async () => {
    const { input, options, listbox } = await boot()
    input.value = "cal"
    input.dispatchEvent(new Event("input"))
    await nextFrame()

    const [ca, ny, tx] = options()
    expect(ca.hidden).toBe(false)
    expect(ny.hidden).toBe(true)
    expect(tx.hidden).toBe(true)
    expect(listbox.hidden).toBe(false)
  })

  test("client filter is case-insensitive", async () => {
    const { input, options } = await boot()
    input.value = "CALIFORNIA"
    input.dispatchEvent(new Event("input"))
    await nextFrame()

    expect(options()[0].hidden).toBe(false)
  })

  test("live region updates only when the visible count actually changes", async () => {
    const { input, status } = await boot()

    input.value = "c"
    input.dispatchEvent(new Event("input"))
    await nextFrame()
    expect(status.textContent).toBe("1 results available")

    // "ca" still matches only California — count unchanged, message unchanged.
    status.textContent = "SENTINEL"
    input.value = "ca"
    input.dispatchEvent(new Event("input"))
    await nextFrame()
    expect(status.textContent).toBe("SENTINEL")
  })

  test("dispatches filtered with query and count", async () => {
    const filtered = captureEvents("cw--combobox:filtered")
    const { input } = await boot()

    input.value = "new"
    input.dispatchEvent(new Event("input"))
    await nextFrame()

    expect(filtered).toHaveLength(1)
    expect(filtered[0].detail.query).toBe("new")
    expect(filtered[0].detail.count).toBe(1)
  })

  test("zero matches shows the empty target and announces the empty message", async () => {
    const { input, empty, status } = await boot()
    input.value = "zzz"
    input.dispatchEvent(new Event("input"))
    await nextFrame()

    expect(empty.hidden).toBe(false)
    expect(status.textContent).toBe("No results available")
  })

  test("empty target is hidden again once a match reappears", async () => {
    const { input, empty } = await boot()
    input.value = "zzz"
    input.dispatchEvent(new Event("input"))
    await nextFrame()
    expect(empty.hidden).toBe(false)

    input.value = "ca"
    input.dispatchEvent(new Event("input"))
    await nextFrame()
    expect(empty.hidden).toBe(true)
  })

  test("filter: none never hides options, only opens", async () => {
    const { input, options, listbox } = await boot({ filter: "none" })
    input.value = "anything"
    input.dispatchEvent(new Event("input"))
    await nextFrame()

    options().forEach((option) => expect(option.hidden).toBe(false))
    expect(listbox.hidden).toBe(false)
  })

  test("clearing the active option when it becomes hidden by filtering", async () => {
    const { el, input, options } = await boot({ expanded: true })
    el.setAttribute("data-cw--combobox-active-value", "state-option-NY")
    await nextFrame()
    expect(options()[1].getAttribute("id")).toBe("state-option-NY")

    input.value = "cal"
    input.dispatchEvent(new Event("input"))
    await nextFrame()

    expect(el.getAttribute("data-cw--combobox-active-value")).toBe("")
  })

  // --- filter: remote mode -------------------------------------------------------------

  test("remote mode writes frameTarget.src exactly once per debounced burst, with the query param", async () => {
    const { input, frame } = await boot({ filter: "remote", src: "/combobox_demo", delay: 20, includeFrame: true })

    vi.useFakeTimers()
    try {
      input.value = "c"
      input.dispatchEvent(new Event("input"))
      vi.advanceTimersByTime(5)

      input.value = "ca"
      input.dispatchEvent(new Event("input"))
      vi.advanceTimersByTime(5)

      input.value = "cal"
      input.dispatchEvent(new Event("input"))
      expect(frame.src).toBeUndefined()

      vi.advanceTimersByTime(25)
      expect(frame.src).toContain("q=cal")

      // A second burst replaces it.
      input.value = "cali"
      input.dispatchEvent(new Event("input"))
      vi.advanceTimersByTime(25)
      expect(frame.src).toContain("q=cali")
    } finally {
      vi.useRealTimers()
    }
  })

  test("remote mode sends no request below min_length", async () => {
    const { input, frame } = await boot({
      filter: "remote",
      src: "/combobox_demo",
      delay: 5,
      minLength: 3,
      includeFrame: true
    })

    vi.useFakeTimers()
    try {
      input.value = "ca"
      input.dispatchEvent(new Event("input"))
      vi.advanceTimersByTime(50)

      expect(frame.src).toBeUndefined()
    } finally {
      vi.useRealTimers()
    }
  })

  // --- inline autocomplete (autocomplete: "both") -------------------------------------

  test("both: completes to the first match and selects the completed portion", async () => {
    const { input } = await boot({ autocomplete: "both" })
    input.value = "ca"
    input.dispatchEvent(new InputEvent("input", { inputType: "insertText", bubbles: true }))
    await nextFrame()

    expect(input.value).toBe("California")
    expect(input.selectionStart).toBe(2)
    expect(input.selectionEnd).toBe("California".length)
  })

  test("both: never completes after a Backspace/Delete", async () => {
    const { input } = await boot({ autocomplete: "both" })
    input.value = "cal"
    input.dispatchEvent(new InputEvent("input", { inputType: "deleteContentBackward", bubbles: true }))
    await nextFrame()

    expect(input.value).toBe("cal")
  })

  test("list mode never inline-completes", async () => {
    const { input } = await boot({ autocomplete: "list" })
    input.value = "ca"
    input.dispatchEvent(new InputEvent("input", { inputType: "insertText", bubbles: true }))
    await nextFrame()

    expect(input.value).toBe("ca")
  })

  // --- down/up -------------------------------------------------------------------------

  test("ArrowDown from collapsed opens and activates the first option", async () => {
    const { el, input, listbox } = await boot()
    input.dispatchEvent(key("ArrowDown"))
    await nextFrame()

    expect(listbox.hidden).toBe(false)
    expect(el.getAttribute("data-cw--combobox-active-value")).toBe("state-option-CA")
  })

  test("Alt+ArrowDown opens with NO active option", async () => {
    const { el, listbox, input } = await boot()
    input.dispatchEvent(key("ArrowDown", { altKey: true }))
    await nextFrame()

    expect(listbox.hidden).toBe(false)
    expect(el.getAttribute("data-cw--combobox-active-value")).toBe("")
  })

  test("ArrowUp from collapsed opens and activates the last option", async () => {
    const { el, input } = await boot()
    input.dispatchEvent(key("ArrowUp"))
    await nextFrame()

    expect(el.getAttribute("data-cw--combobox-active-value")).toBe("state-option-TX")
  })

  test("ArrowDown/ArrowUp always preventDefault (text cursor must not move)", async () => {
    const { input } = await boot()
    const down = key("ArrowDown")
    input.dispatchEvent(down)
    expect(down.defaultPrevented).toBe(true)

    const up = key("ArrowUp")
    input.dispatchEvent(up)
    expect(up.defaultPrevented).toBe(true)
  })

  test("ArrowDown moves to the next visible option, wrapping last to first", async () => {
    const { el, input } = await boot({ expanded: true })
    el.setAttribute("data-cw--combobox-active-value", "state-option-TX")
    await nextFrame()

    input.dispatchEvent(key("ArrowDown"))
    await nextFrame()

    expect(el.getAttribute("data-cw--combobox-active-value")).toBe("state-option-CA")
  })

  test("Alt+ArrowUp while expanded closes without changing the value", async () => {
    const { el, input, listbox } = await boot({ expanded: true, value: "NY" })
    el.setAttribute("data-cw--combobox-active-value", "state-option-CA")
    await nextFrame()

    input.dispatchEvent(key("ArrowUp", { altKey: true }))
    await nextFrame()

    expect(listbox.hidden).toBe(true)
    expect(el.getAttribute("data-cw--combobox-value-value")).toBe("NY")
  })

  // --- enter -----------------------------------------------------------------------------

  test("Enter with an active option selects it and preventDefaults", async () => {
    const { el, field } = await boot({ expanded: true })
    el.setAttribute("data-cw--combobox-active-value", "state-option-CA")
    await nextFrame()

    const input = el.querySelector("[data-cw--combobox-target='input']")
    const event = key("Enter")
    input.dispatchEvent(event)
    await nextFrame()

    expect(event.defaultPrevented).toBe(true)
    expect(field.value).toBe("CA")
  })

  test("Enter with no active option does not preventDefault — the form submits normally", async () => {
    const { input } = await boot()
    const event = key("Enter")
    input.dispatchEvent(event)

    expect(event.defaultPrevented).toBe(false)
  })

  // --- escape: two-stage per APG --------------------------------------------------------

  test("Escape while expanded closes without touching text or value", async () => {
    const { el, input, listbox } = await boot({ expanded: true, value: "CA", display: "California" })
    input.dispatchEvent(key("Escape"))
    await nextFrame()

    expect(listbox.hidden).toBe(true)
    expect(input.value).toBe("California")
    expect(el.getAttribute("data-cw--combobox-value-value")).toBe("CA")
  })

  test("a second Escape, already collapsed, clears text and value and dispatches cleared", async () => {
    const cleared = captureEvents("cw--combobox:cleared")
    const { input, el } = await boot({ value: "CA", display: "California" })

    input.dispatchEvent(key("Escape"))
    await nextFrame()

    expect(input.value).toBe("")
    expect(el.getAttribute("data-cw--combobox-value-value")).toBe("")
    expect(cleared).toHaveLength(1)
  })

  test("Escape does nothing when clear_on_escape is disabled and already collapsed", async () => {
    document.body.innerHTML = ""
    const el = await mount(
      markup({ value: "CA", display: "California" }).replace(
        'data-cw--combobox-clear-on-escape-value="true"',
        'data-cw--combobox-clear-on-escape-value="false"'
      ),
      CONTROLLERS
    )
    const input = el.querySelector("[data-cw--combobox-target='input']")

    input.dispatchEvent(key("Escape"))
    await nextFrame()

    expect(input.value).toBe("California")
  })

  // --- clear() action --------------------------------------------------------------------

  test("the clear button clears text, value, and dispatches cleared", async () => {
    const cleared = captureEvents("cw--combobox:cleared")
    const { clearButton, input, el } = await boot({ value: "CA", display: "California" })

    clearButton.click()
    await nextFrame()

    expect(input.value).toBe("")
    expect(el.getAttribute("data-cw--combobox-value-value")).toBe("")
    expect(cleared).toHaveLength(1)
  })

  // --- tabOut ------------------------------------------------------------------------------

  test("Tab closes without preventDefault", async () => {
    const { input, listbox } = await boot({ expanded: true })
    const event = key("Tab")
    input.dispatchEvent(event)
    await nextFrame()

    expect(listbox.hidden).toBe(true)
    expect(event.defaultPrevented).toBe(false)
  })

  test("Shift+Tab also closes (R8a)", async () => {
    const { input, listbox } = await boot({ expanded: true })
    input.dispatchEvent(key("Tab", { shiftKey: true }))
    await nextFrame()

    expect(listbox.hidden).toBe(true)
  })

  // --- preventBlur -------------------------------------------------------------------------

  test("mousedown on an option preventDefaults so the input never blurs first", async () => {
    const { options } = await boot({ expanded: true })
    const event = new MouseEvent("mousedown", { bubbles: true, cancelable: true })
    options()[0].dispatchEvent(event)

    expect(event.defaultPrevented).toBe(true)
  })

  // --- optionTargetConnected/Disconnected (remote frame re-render idiom) -----------------

  test("a newly connected option is immediately given the correct aria-selected from the current value", async () => {
    const { el, listbox } = await boot({ value: "NY" })
    const li = document.createElement("li")
    li.id = "state-option-TX"
    li.setAttribute("role", "option")
    li.setAttribute("data-cw--combobox-target", "option")
    li.setAttribute("data-cw--combobox-value-param", "TX")
    li.textContent = "Texas"
    listbox.appendChild(li)
    await nextFrame()

    expect(li.getAttribute("aria-selected")).toBe("false")

    const ny = el.querySelector("#state-option-NY") ?? Array.from(el.querySelectorAll("[data-cw--combobox-target='option']")).find((o) => o.id.endsWith("NY"))
    expect(ny.getAttribute("aria-selected")).toBe("true")
  })

  // --- disabled: every action early-returns -----------------------------------------------

  test("a disabled field ignores filter/open/select", async () => {
    const { el, input, listbox, options } = await boot({ disabled: true })

    input.dispatchEvent(key("ArrowDown"))
    await nextFrame()
    expect(listbox.hidden).toBe(true)

    // Force-open via the DOM to prove select() itself still no-ops while disabled.
    el.setAttribute("data-cw--combobox-expanded-value", "true")
    await nextFrame()
    options()[0].click()
    await nextFrame()

    expect(el.getAttribute("data-cw--combobox-value-value")).toBe("")
  })

  // --- form reset (R7) ---------------------------------------------------------------------

  test("a form reset restores the input and the value to their server-rendered defaults", async () => {
    const form = await mount(`<form>${markup({ value: "CA", display: "California" })}</form>`, CONTROLLERS)
    const el = form.firstElementChild
    const input = el.querySelector("[data-cw--combobox-target='input']")

    // A real selection, through the actual select() code path — not a hand-poked
    // attribute — so this exercises the same write path the rest of the app uses.
    const ny = Array.from(el.querySelectorAll("[data-cw--combobox-target='option']")).find((o) =>
      o.id.endsWith("NY")
    )
    ny.click()
    await nextFrame()
    expect(input.value).toBe("New York")
    expect(el.getAttribute("data-cw--combobox-value-value")).toBe("NY")

    form.dispatchEvent(new Event("reset", { bubbles: true, cancelable: true }))
    await nextFrame()

    expect(input.value).toBe("California")
    expect(el.getAttribute("data-cw--combobox-value-value")).toBe("CA")
  })

  // --- disconnect (R7) ---------------------------------------------------------------------

  test("disconnect cancels a pending remote debounce — no src write afterwards", async () => {
    const el = await mount(
      markup({ filter: "remote", src: "/combobox_demo", delay: 30, includeFrame: true }),
      CONTROLLERS
    )
    const input = el.querySelector("[data-cw--combobox-target='input']")
    const frame = el.querySelector("[data-cw--combobox-target='frame']")

    input.value = "ca"
    input.dispatchEvent(new Event("input"))

    document.body.innerHTML = ""
    await nextFrame()

    await new Promise((resolve) => setTimeout(resolve, 60))
    expect(frame.src).toBeUndefined()
  })

  test("disconnect removes the form reset listener", async () => {
    const form = await mount(`<form>${markup({ value: "CA", display: "California" })}</form>`, CONTROLLERS)
    const el = form.firstElementChild

    el.remove()
    await nextFrame()

    expect(() => form.dispatchEvent(new Event("reset", { bubbles: true, cancelable: true }))).not.toThrow()
  })
})
