import { describe, expect, test, vi } from "vitest"
import { userEvent } from "vitest/browser"
import { morphElements } from "@hotwired/turbo"
import ComboboxController from "../../app/assets/javascripts/crosswire/controllers/combobox_controller.js"
import ClickOutsideController from "../../app/assets/javascripts/crosswire/controllers/click_outside_controller.js"
import { mount } from "./setup.js"

// Browser tier (docs/COMPONENT_CONTRACT.md: "Browser mode for anything touching
// focus … jsdom cannot test those honestly"). This IS the accessibility claim for
// `cw--combobox`: jsdom has no `scrollIntoView`, and — per
// combobox_controller.test.js's own header — dispatched (untrusted) key/pointer
// events never trigger a browser's native default actions (native Tab traversal,
// Enter-submits-a-form, Home/End moving a text caret, mousedown-blurs-the-input).
// The twenty-five tests below are the only place the FULL real stack — real focus,
// real layout, real native key/pointer defaults — is exercised together, exactly as
// WAI-ARIA APG's Combobox pattern requires it to work.
//
// Register cw--combobox AND cw--click-outside — the one real composition this
// widget has (0.4/R5a mechanism 2); see Crosswire::Presenters::Combobox's
// docstring for why cw--roving-focus is deliberately NOT part of this stack at all
// (0.3 — an anti-composition, not an omission).
//
// Uses the shared `mount()` helper from setup.js, never a hand-rolled
// Application.start()/register() — the connect-tick bug documented in
// docs/COMPONENT_CONTRACT.md's gotchas table, and independently in
// menu_controller.browser.test.js.
//
// Synthetic vs real input, deliberately split, the same justification
// menu_controller.browser.test.js gives for the identical choice: ArrowUp/Down,
// Alt+Arrow and Escape (tests 1-6, 9-11, 14) are dispatched as plain
// `KeyboardEvent`s because this controller reads `event.key`/`event.altKey` itself
// and moves an explicit `active` value — there is no browser-native default action
// being relied on. Tests 7 (Home/End caret movement), 12 and 13 (Enter's native
// "submit the form" default), 15 (native Tab traversal) and 16 (native
// mousedown-blurs-focus) all depend on genuine trusted input, so those five use
// `userEvent` (the Playwright provider) — a `dispatchEvent`-created KeyboardEvent
// has `isTrusted: false` and never triggers a UA default action at all.
//
// Tests 12 and 13 (activation/submission) follow the exact technique
// menu_controller.browser.test.js documents for its own Enter/Space tests: a real
// same-page form submission inside Vitest's browser-mode iframe reliably corrupts
// its own RPC state for every test that runs afterward in the same worker. So the
// surrounding `<form>`'s `submit` listener calls `event.preventDefault()` ITSELF,
// in the test, never in the controller — and the claim under test ("did the form
// actually get asked to submit") is proven by that listener's own call count, not
// by letting a real navigation complete.

const CONTROLLERS = {
  "cw--combobox": ComboboxController,
  "cw--click-outside": ClickOutsideController
}

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

function comboboxHtml({
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
  openOnFocus = false,
  disabled = false,
  options = DEFAULT_OPTIONS,
  includeFrame = false,
  tall = false
} = {}) {
  const focusAction = openOnFocus ? "focus->cw--combobox#open " : ""

  return `
    <div id="state-combobox" data-controller="cw--combobox cw--click-outside"
         data-cw--click-outside-enabled-value="${expanded}"
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
         data-action="cw--click-outside:clicked->cw--combobox#close">
      <label id="state-label" for="state-input">State</label>
      <input type="text" id="state-input" role="combobox" aria-controls="state-listbox"
             aria-haspopup="listbox" aria-autocomplete="${autocomplete}" autocomplete="off"
             data-cw--combobox-target="input" value="${display}" ${disabled ? "disabled" : ""}
             data-action="${focusAction}input->cw--combobox#filter
                          keydown.down->cw--combobox#down keydown.alt+down->cw--combobox#down
                          keydown.up->cw--combobox#up keydown.alt+up->cw--combobox#up
                          keydown.esc->cw--combobox#escape keydown.enter->cw--combobox#enter
                          keydown.tab->cw--combobox#tabOut keydown.shift+tab->cw--combobox#tabOut">
      <input type="hidden" id="state-field" name="state" value="${value}" ${disabled ? "disabled" : ""}
             data-cw--combobox-target="field">
      ${includeFrame ? `<turbo-frame id="state-options" data-cw--combobox-target="frame"></turbo-frame>` : ""}
      <ul id="state-listbox" role="listbox" aria-labelledby="state-label"
          data-cw--combobox-target="listbox" ${expanded ? "" : "hidden"}
          ${tall ? `style="max-height: 60px; overflow: auto; display: block;"` : ""}>
        ${options.map(optionHtml).join("\n")}
      </ul>
      <p data-cw--combobox-target="empty" hidden>No results</p>
      <div id="state-status" role="status" aria-live="polite" aria-atomic="true"
           data-cw--combobox-target="status"></div>
    </div>`
}

function markup(opts = {}, { wrapInForm = false, before = false, after = false } = {}) {
  const combobox = comboboxHtml(opts)
  const withBefore = before ? `<button id="before">Before</button>${combobox}` : combobox
  const withAfter = after ? `${withBefore}<button id="after">After</button>` : withBefore

  return wrapInForm ? `<form id="the-form">${withAfter}</form>` : withAfter
}

async function boot(opts = {}, mountOpts = {}) {
  const el = await mount(markup(opts, mountOpts), CONTROLLERS)
  const root = mountOpts.wrapInForm || mountOpts.before ? document.getElementById("state-combobox") : el
  return {
    el: root,
    input: document.getElementById("state-input"),
    field: document.getElementById("state-field"),
    listbox: document.getElementById("state-listbox"),
    empty: root.querySelector("[data-cw--combobox-target='empty']"),
    status: document.getElementById("state-status"),
    options: () => Array.from(root.querySelectorAll("[data-cw--combobox-target='option']"))
  }
}

function key(k, opts = {}) {
  return new KeyboardEvent("keydown", { key: k, bubbles: true, cancelable: true, ...opts })
}

async function settle() {
  await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
}

describe("cw--combobox (real browser, full composed stack)", () => {
  test("1. ArrowDown from closed opens and sets aria-activedescendant to the first option; activeElement stays the input", async () => {
    const { input } = await boot()
    input.focus()
    input.dispatchEvent(key("ArrowDown"))
    await settle()

    expect(input.getAttribute("aria-activedescendant")).toBe("state-option-CA")
    expect(document.activeElement).toBe(input)
  })

  test("2. Alt+ArrowDown opens with NO aria-activedescendant (proves the four-descriptor R8a wiring)", async () => {
    const { input } = await boot()
    input.focus()
    input.dispatchEvent(key("ArrowDown", { altKey: true }))
    await settle()

    expect(input.hasAttribute("aria-activedescendant")).toBe(false)
    expect(document.getElementById("state-listbox").hidden).toBe(false)
  })

  test("3. ArrowUp from closed activates the LAST option", async () => {
    const { input } = await boot()
    input.focus()
    input.dispatchEvent(key("ArrowUp"))
    await settle()

    expect(input.getAttribute("aria-activedescendant")).toBe("state-option-TX")
  })

  test("4. ArrowDown at the last option wraps to the first", async () => {
    const { input } = await boot({ expanded: true })
    input.focus()
    input.dispatchEvent(key("ArrowUp")) // -> TX (last)
    await settle()
    input.dispatchEvent(key("ArrowDown"))
    await settle()

    expect(input.getAttribute("aria-activedescendant")).toBe("state-option-CA")
  })

  test("5. Exactly one option carries aria-selected=true and the active class at a time", async () => {
    const { input, options } = await boot({ expanded: true, activeClass: "is-active" })
    input.focus()
    input.dispatchEvent(key("ArrowDown"))
    await settle()
    input.dispatchEvent(key("ArrowDown"))
    await settle()

    const selected = options().filter((o) => o.getAttribute("aria-selected") === "true")
    const active = options().filter((o) => o.classList.contains("is-active"))
    expect(selected).toHaveLength(1)
    expect(active).toHaveLength(1)
    expect(selected[0]).toBe(active[0])
    expect(selected[0].id).toBe("state-option-NY")
  })

  test("6. Arrowing to an off-screen option scrolls it into view in a fixed-height listbox (real layout)", async () => {
    const manyOptions = Array.from({ length: 15 }, (_, i) => ({ value: `v${i}`, display: `Option ${i}` }))
    const { input, listbox } = await boot({ expanded: true, options: manyOptions, tall: true })
    input.focus()

    for (let i = 0; i < 12; i++) {
      input.dispatchEvent(key("ArrowDown"))
      await settle()
    }

    expect(listbox.scrollTop).toBeGreaterThan(0)
  })

  test("7. Home/End move the text caret and leave aria-activedescendant untouched (native default, not intercepted)", async () => {
    const { input } = await boot({ expanded: true, display: "California" })
    input.focus()
    input.dispatchEvent(key("ArrowDown"))
    await settle()
    const activeBefore = input.getAttribute("aria-activedescendant")

    await userEvent.keyboard("{End}")
    expect(input.selectionStart).toBe("California".length)

    await userEvent.keyboard("{Home}")
    expect(input.selectionStart).toBe(0)

    expect(input.getAttribute("aria-activedescendant")).toBe(activeBefore)
  })

  test("8. Typing filters, hides non-matching options, and the live region reads the results message", async () => {
    const { input, options, status } = await boot()
    input.focus()
    await userEvent.type(input, "cal")
    await settle()

    const [ca, ny, tx] = options()
    expect(ca.hidden).toBe(false)
    expect(ny.hidden).toBe(true)
    expect(tx.hidden).toBe(true)
    expect(status.textContent).toBe("1 results available")
  })

  test("9. Zero matches shows the empty target, announces the empty message, and removes aria-activedescendant", async () => {
    const { input, empty, status } = await boot({ expanded: true })
    input.focus()
    input.dispatchEvent(key("ArrowDown"))
    await settle()
    expect(input.hasAttribute("aria-activedescendant")).toBe(true)

    await userEvent.type(input, "zzz")
    await settle()

    expect(empty.hidden).toBe(false)
    expect(status.textContent).toBe("No results available")
    expect(input.hasAttribute("aria-activedescendant")).toBe(false)
  })

  test("10. autocomplete: both completes to the first match and selects the completed portion", async () => {
    const { input } = await boot({ autocomplete: "both" })
    input.focus()
    await userEvent.type(input, "ca")
    await settle()

    expect(input.value).toBe("California")
    expect(input.selectionStart).toBe(2)
    expect(input.selectionEnd).toBe("California".length)
  })

  test("11. Backspace never re-triggers inline completion", async () => {
    const { input } = await boot({ autocomplete: "both" })
    input.focus()
    await userEvent.type(input, "cal")
    await settle()
    expect(input.value).toBe("California")
    // "cal" + auto-completed "ifornia" left SELECTED (selectionStart 3, per test
    // 10) — a real Backspace here deletes that selection outright, the ordinary
    // text-editing behaviour for Backspace over a non-collapsed selection. That is
    // exactly what proves completion did NOT re-fire: if it had, the result would
    // be "California" again (or another completed word), not the bare typed
    // prefix with the selection removed.
    expect(input.selectionStart).toBe(3)

    await userEvent.keyboard("{Backspace}")
    await settle()

    // "California" (the completed value) with its [3,10] selection removed — the
    // completed display text's own casing survives on the un-selected prefix.
    expect(input.value).toBe("Cal")
  })

  test("12. Enter with an active option selects it, closes, dispatches selected, and does NOT submit the surrounding form", async () => {
    const { input, field, listbox } = await boot({ expanded: true }, { wrapInForm: true })
    const form = document.getElementById("the-form")

    let submitCount = 0
    form.addEventListener("submit", (event) => {
      event.preventDefault() // see the file header — never in the controller, always in the test
      submitCount++
    })

    const selected = []
    document.addEventListener("cw--combobox:selected", (event) => selected.push(event))

    input.focus()
    input.dispatchEvent(key("ArrowDown")) // activate California
    await settle()

    await userEvent.keyboard("{Enter}")
    await settle()

    expect(field.value).toBe("CA")
    expect(input.value).toBe("California")
    expect(listbox.hidden).toBe(true)
    expect(selected).toHaveLength(1)
    expect(submitCount).toBe(0)
  })

  test("13. Enter with no active option submits the surrounding form", async () => {
    const { input } = await boot({}, { wrapInForm: true })
    const form = document.getElementById("the-form")

    let submitCount = 0
    form.addEventListener("submit", (event) => {
      event.preventDefault()
      submitCount++
    })

    input.focus()
    await userEvent.keyboard("{Enter}")
    await settle()

    expect(submitCount).toBe(1)
  })

  test("14. Escape once closes keeping the text; a second Escape clears text and value and dispatches cleared", async () => {
    const cleared = []
    document.addEventListener("cw--combobox:cleared", (event) => cleared.push(event))

    const { input, listbox, field } = await boot({ expanded: true, value: "CA", display: "California" })
    input.focus()

    await userEvent.keyboard("{Escape}")
    await settle()
    expect(listbox.hidden).toBe(true)
    expect(input.value).toBe("California")

    await userEvent.keyboard("{Escape}")
    await settle()
    expect(input.value).toBe("")
    expect(field.value).toBe("")
    expect(cleared).toHaveLength(1)
  })

  test("15. Tab closes the listbox and moves focus out of the widget entirely (native Tab traversal)", async () => {
    const { input, listbox } = await boot({ expanded: true }, { after: true })
    input.focus()

    await userEvent.tab()
    await settle()

    expect(listbox.hidden).toBe(true)
    expect(document.activeElement).toBe(document.getElementById("after"))
  })

  test("16. A real pointer click on an option selects it, and activeElement stays the input throughout (mousedown preventDefault)", async () => {
    const { input, field, options } = await boot({ expanded: true })
    input.focus()

    const [ca] = options()
    let activeElementAtMousedown = null
    ca.addEventListener("mousedown", () => {
      activeElementAtMousedown = document.activeElement
    })

    await userEvent.click(ca)
    await settle()

    expect(activeElementAtMousedown).toBe(input)
    expect(document.activeElement).toBe(input)
    expect(field.value).toBe("CA")
  })

  test("17. pointerdown outside closes it; while closed, click-outside's own enabled value is false", async () => {
    const { el, input, listbox } = await boot({}, { after: true })
    const outside = document.getElementById("after")

    expect(el.getAttribute("data-cw--click-outside-enabled-value")).toBe("false")

    input.focus()
    input.dispatchEvent(key("ArrowDown"))
    await settle()
    expect(listbox.hidden).toBe(false)
    expect(el.getAttribute("data-cw--click-outside-enabled-value")).toBe("true")

    // click-outside itself doesn't rely on any native default action — only on
    // receiving a real `pointerdown` DOM event — so a synthetic dispatch is
    // honest here, the same idiom click_outside_controller.test.js's own suite
    // uses throughout.
    outside.dispatchEvent(new MouseEvent("pointerdown", { bubbles: true, composed: true, cancelable: true, button: 0 }))
    await settle()

    expect(listbox.hidden).toBe(true)
  })

  test("17b. open_on_focus: focusing the input itself never gets misread as an outside click and immediately re-closed", async () => {
    const { input, listbox } = await boot({ openOnFocus: true })

    input.focus()
    await settle()

    expect(listbox.hidden).toBe(false)
  })

  test("18. aria-expanded tracks state and aria-controls keeps pointing at the listbox id, including after options are replaced (simulated remote render)", async () => {
    const { input, listbox } = await boot()
    expect(input.getAttribute("aria-controls")).toBe("state-listbox")
    expect(input.getAttribute("aria-expanded")).toBe("false")

    input.dispatchEvent(key("ArrowDown"))
    await settle()
    expect(input.getAttribute("aria-expanded")).toBe("true")

    // Simulates a remote frame render swapping the listbox's children with no
    // connect() of its own — optionTargetConnected is what picks these up.
    listbox.innerHTML = optionHtml({ value: "WA", display: "Washington" })
    await settle()

    expect(input.getAttribute("aria-controls")).toBe("state-listbox")
    const washington = listbox.querySelector("[data-cw--combobox-target='option']")
    expect(washington.getAttribute("aria-selected")).toBe("false")
  })

  test("19. Server-rendered value:/display: are correct BEFORE connect and unchanged AFTER (the tabs regression)", async () => {
    document.body.innerHTML = markup({ value: "CA", display: "California" })

    // Before any JS runs at all — raw server-rendered markup.
    const field = document.getElementById("state-field")
    const input = document.getElementById("state-input")
    const ca = document.getElementById("state-option-CA")
    expect(field.getAttribute("value")).toBe("CA")
    expect(input.getAttribute("value")).toBe("California")
    expect(ca.getAttribute("aria-selected")).toBe("false") // presenter deliberately renders this via option_attrs(selected:) by the caller — this hand-written fixture didn't set it, matching 0.3's "activedescendant/selection are client concerns" boundary for a bare option element

    const { Application } = await import("@hotwired/stimulus")
    const application = Application.start()
    application.register("cw--combobox", ComboboxController)
    await settle()

    expect(field.value).toBe("CA")
    expect(input.value).toBe("California")
    application.stop()
  })

  // --- 20. morph + preserved value (B2) -------------------------------------------------

  test("20a. morph with a DIFFERENT server value AFTER the user picked one keeps the user's choice", async () => {
    const { el, options, field } = await boot()
    options()[1].click() // New York
    await settle()
    expect(field.value).toBe("NY")

    const incoming = document.createElement("div")
    incoming.id = "state-combobox"
    incoming.innerHTML = el.innerHTML
    incoming.setAttribute("data-controller", "cw--combobox")
    incoming.setAttribute("data-cw--combobox-value-value", "TX") // the server's stale idea
    incoming.setAttribute("data-cw--combobox-expanded-value", "false")
    incoming.setAttribute("data-cw--combobox-filter-value", "client")
    incoming.setAttribute("data-cw--combobox-autocomplete-value", "list")

    morphElements(el, incoming)
    await settle()

    expect(el.getAttribute("data-cw--combobox-value-value")).toBe("NY")
    expect(field.value).toBe("NY")
  })

  test("20b. morph with a new server value the user never touched wins (server still drives untouched state)", async () => {
    const { el, field } = await boot()

    const incoming = document.createElement("div")
    incoming.id = "state-combobox"
    incoming.innerHTML = el.innerHTML
    incoming.setAttribute("data-controller", "cw--combobox")
    incoming.setAttribute("data-cw--combobox-value-value", "TX")
    incoming.setAttribute("data-cw--combobox-expanded-value", "false")
    incoming.setAttribute("data-cw--combobox-filter-value", "client")
    incoming.setAttribute("data-cw--combobox-autocomplete-value", "list")

    morphElements(el, incoming)
    await settle()

    expect(el.getAttribute("data-cw--combobox-value-value")).toBe("TX")
    expect(field.value).toBe("TX")
  })

  // --- 21. morph while expanded -----------------------------------------------------------

  test("21. morph over the root while expanded leaves the listbox open; typed text is OBSERVED, not guaranteed (see crosswire/morph's Rule 0)", async () => {
    const { el, input, listbox } = await boot({ expanded: true })
    input.focus()
    input.value = "cali"
    input.dispatchEvent(new InputEvent("input", { bubbles: true, inputType: "insertText" }))
    await settle()

    const incoming = document.createElement("div")
    incoming.id = "state-combobox"
    incoming.innerHTML = el.innerHTML
    incoming.setAttribute("data-controller", "cw--combobox")
    incoming.setAttribute("data-cw--combobox-value-value", "")
    incoming.setAttribute("data-cw--combobox-expanded-value", "true")
    incoming.setAttribute("data-cw--combobox-filter-value", "client")
    incoming.setAttribute("data-cw--combobox-autocomplete-value", "list")
    // The incoming input element itself carries the SERVER's idea of the value
    // attribute (unchanged from the original render, "" — no display text).
    incoming.querySelector("#state-input").setAttribute("value", "")

    morphElements(el, incoming)
    await settle()

    // The guaranteed part (0.7 — expanded IS preserved): the listbox survives open.
    expect(listbox.hidden).toBe(false)

    // OBSERVED, not asserted as a guarantee, and recorded here exactly as it
    // actually behaves (verified directly against a real Chromium via Playwright,
    // not assumed): idiomorph does NOT preserve the input's live `value` property
    // across this morph — it overwrites it from the incoming element's `value`
    // ATTRIBUTE, the same as any other attribute, clobbering the typed "cali" back
    // to "". This is the residual the class docstring names: usePreserve's guard
    // (B1, per-element scoping — `event.target !== element` in
    // `crosswire/morph.js`) runs on the ROOT this controller owns, and an
    // `<input>` several levels down is a DESCENDANT, entirely outside what that
    // guard can see or protect, no matter what `preservedValues` lists. The
    // documented, supported fix for a page that actually needs typed text to
    // survive a background render here is crosswire/morph's own Rule 0: scope the
    // SERVER-SIDE update with `turbo_stream.replace(target, method: :morph)` so
    // this subtree is never the thing morphed into in the first place.
    expect(input.value).toBe("")
  })

  // --- 22/23. remote debounce ---------------------------------------------------------------

  test("22. Remote mode writes frameTarget.src once per debounced burst, and a second burst replaces it", async () => {
    const { input } = await boot({ filter: "remote", src: "/combobox_demo", delay: 20, includeFrame: true })
    const frame = document.getElementById("state-options")

    vi.useFakeTimers()
    try {
      input.value = "c"
      input.dispatchEvent(new Event("input", { bubbles: true }))
      vi.advanceTimersByTime(5)
      input.value = "ca"
      input.dispatchEvent(new Event("input", { bubbles: true }))
      expect(frame.src).toBeNull()

      vi.advanceTimersByTime(30)
      expect(frame.src).toContain("q=ca")

      input.value = "cal"
      input.dispatchEvent(new Event("input", { bubbles: true }))
      vi.advanceTimersByTime(30)
      expect(frame.src).toContain("q=cal")
    } finally {
      vi.useRealTimers()
    }
  })

  test("23. Removing the element mid-debounce means no src write ever lands", async () => {
    const { el, input } = await boot({ filter: "remote", src: "/combobox_demo", delay: 30, includeFrame: true })
    const frame = document.getElementById("state-options")

    input.value = "ca"
    input.dispatchEvent(new Event("input", { bubbles: true }))

    el.remove()
    await settle()

    await new Promise((resolve) => setTimeout(resolve, 60))
    expect(frame.src).toBeNull()
  })

  // --- 24. R3 missing-class guard ------------------------------------------------------------

  test("24. No active_class given — activating an option never throws", async () => {
    const { input } = await boot()
    input.focus()
    expect(() => input.dispatchEvent(key("ArrowDown"))).not.toThrow()
    await settle()
  })

  // --- 25. fieldset disabled -------------------------------------------------------------------

  test("25. Inside a disabled fieldset, the input is disabled and no keystroke changes state", async () => {
    await mount(`<fieldset disabled>${markup()}</fieldset>`, CONTROLLERS)

    const input = document.getElementById("state-input")
    const listbox = document.getElementById("state-listbox")

    // NOT input.disabled — that IDL property reflects only the element's OWN
    // attribute and does not fold in the fieldset's cascade (see the controller's
    // own #disabled getter and its docstring for the same, directly-verified
    // finding). :disabled is the actual computed concept.
    expect(input.matches(":disabled")).toBe(true)

    input.dispatchEvent(key("ArrowDown"))
    await settle()

    expect(listbox.hidden).toBe(true)
    expect(input.hasAttribute("aria-activedescendant")).toBe(false)
  })
})
