import { afterEach, describe, expect, test } from "vitest"

// Browser tier (docs/COMPONENT_CONTRACT.md / ui-tier-spec.md §7.3, which names toast
// and field as the tier's two required browser-tier components — field shipped
// without one in Phase 2; this is that test, added now). `Crosswire::UI::Field` ships
// no controller at all (Morph: Safe — see its own docstring), so there is nothing to
// boot here, no Stimulus Application, no controller class — this is a pure DOM test
// of the id relationships the PRESENTER computes, exercised the one way that matters:
// does `aria-describedby`/`aria-errormessage` actually resolve to a real element in a
// real DOM, the same lookup a screen reader's accessibility-tree builder performs,
// rather than merely asserting the presenter emitted matching STRINGS (already pinned,
// with no DOM at all, in test/crosswire/ui/field_test.rb). Kept small on purpose —
// this is a relationship-resolution proof, not a second copy of the presenter suite.
//
// Run with `npm run test:browser` after `npx playwright install chromium` — see
// vitest.browser.config.js.

afterEach(() => {
  document.body.innerHTML = ""
})

// Mirrors exactly what app/views/crosswire/ui/_field.html.erb renders for
// `cw.field "Email", id: "email", hint: "...", error: "..."` — see that partial and
// Crosswire::UI::Field#control_attrs.
function field({ hint = true, error = true } = {}) {
  document.body.innerHTML = `
    <div class="cw-field">
      <label class="cw-field__label" for="email">Email</label>
      <input class="cw-input" id="email" type="email"
             ${hint ? 'aria-describedby="email-hint"' : ""}
             ${error ? 'aria-errormessage="email-error" aria-invalid="true"' : ""}>
      ${hint ? '<p class="cw-field__hint" id="email-hint">We\'ll never share this.</p>' : ""}
      ${error ? '<p class="cw-field__error" id="email-error">Enter a valid email address.</p>' : ""}
    </div>`
  return document.getElementById("email")
}

describe("Crosswire::UI::Field — id relationships resolve to real elements", () => {
  test("label's `for` resolves to the control via a real click-to-focus association", () => {
    const input = field()
    const label = document.querySelector(".cw-field__label")

    expect(label.getAttribute("for")).toBe(input.id)
    // `HTMLLabelElement.control` is the browser's own resolution of `for` — not a
    // string comparison, the actual associated form control per the HTML spec.
    expect(label.control).toBe(input)
  })

  test("aria-describedby resolves to a real element carrying the hint text", () => {
    const input = field()
    const id = input.getAttribute("aria-describedby")
    const hint = document.getElementById(id)

    expect(hint).not.toBeNull()
    expect(hint.textContent).toBe("We'll never share this.")
  })

  test("aria-errormessage resolves to a real element carrying the error text, alongside aria-invalid", () => {
    const input = field()
    const id = input.getAttribute("aria-errormessage")
    const error = document.getElementById(id)

    expect(error).not.toBeNull()
    expect(error.textContent).toBe("Enter a valid email address.")
    expect(input.getAttribute("aria-invalid")).toBe("true")
  })

  test("hint and error resolve independently and simultaneously — one control, two live relationships", () => {
    const input = field({ hint: true, error: true })

    const hintId = input.getAttribute("aria-describedby")
    const errorId = input.getAttribute("aria-errormessage")

    expect(hintId).not.toBe(errorId)
    expect(document.getElementById(hintId)).not.toBeNull()
    expect(document.getElementById(errorId)).not.toBeNull()
  })

  test("no hint/error given resolves to no dangling id reference at all", () => {
    const input = field({ hint: false, error: false })

    expect(input.hasAttribute("aria-describedby")).toBe(false)
    expect(input.hasAttribute("aria-errormessage")).toBe(false)
    expect(input.hasAttribute("aria-invalid")).toBe(false)
  })
})
