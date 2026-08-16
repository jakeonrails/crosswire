import { Controller } from "@hotwired/stimulus"

// Modifier tokens accepted on either side of a key spec, mapped to the boolean
// KeyboardEvent property that must be true for a match.
const MODIFIER_ALIASES = {
  cmd: "metaKey",
  command: "metaKey",
  meta: "metaKey",
  ctrl: "ctrlKey",
  control: "ctrlKey",
  alt: "altKey",
  option: "altKey",
  shift: "shiftKey"
}

// Aliases for keys whose `KeyboardEvent.key` value isn't the literal spec token.
const KEY_ALIASES = {
  esc: "escape",
  return: "enter",
  space: " ",
  up: "arrowup",
  down: "arrowdown",
  left: "arrowleft",
  right: "arrowright",
  // "+" can't appear as a literal token (it's the modifier separator), so this is the
  // only way to bind the plus key itself.
  plus: "+"
}

// Parses a spec like "cmd+k", "/", or "shift+?" into the primary key plus which of the
// four modifiers must be held. Every unrecognised, non-modifier token is treated as the
// key itself (lowercased) — so `"?"`, `"/"`, and `"k"` all fall through unchanged.
function parseKeySpec(raw) {
  const tokens = (raw || "").split("+").map((token) => token.trim()).filter(Boolean)
  const modifiers = { metaKey: false, ctrlKey: false, altKey: false, shiftKey: false }
  let key = null

  for (const token of tokens) {
    const lower = token.toLowerCase()
    const modifier = MODIFIER_ALIASES[lower]

    if (modifier) {
      modifiers[modifier] = true
    } else {
      key = KEY_ALIASES[lower] || lower
    }
  }

  return { key, modifiers, hasModifier: Object.values(modifiers).some(Boolean) }
}

function eventMatchesSpec(event, spec) {
  if (!spec.key) return false
  if (event.key.toLowerCase() !== spec.key) return false

  // Exact-match on every modifier, not just the ones the spec cares about — the same
  // "cmd+k must not also fire on cmd+shift+k" guarantee a real keybinding needs, and
  // exactly what Stimulus's own key filters already do for a SINGLE descriptor. The
  // reason this whole controller exists rather than leaning on those filters is R8a:
  // Stimulus's key-filter modifiers are exact-match *per descriptor*, so expressing
  // "any of these modifier combinations" (which is this component's entire job — chord
  // bindings like `cmd+k` alongside plain ones like `/`) would need a combinatorial
  // explosion of `data-action` descriptors, one per modifier combination, computed by
  // hand and re-derived by hand every time a binding changes. Parsing the spec
  // ourselves and comparing directly against the four KeyboardEvent modifier booleans
  // is the same exact-match rule, applied once, generically, from a single string value
  // instead.
  return event.metaKey === spec.modifiers.metaKey &&
    event.ctrlKey === spec.modifiers.ctrlKey &&
    event.altKey === spec.modifiers.altKey &&
    event.shiftKey === spec.modifiers.shiftKey
}

// True when `event.target` is somewhere a keystroke is ordinarily meant as text, not a
// command — an <input>, <textarea>, <select>, or anything contenteditable (including a
// contenteditable descendant, e.g. a toolbar button inside a rich-text editor).
function isTypingContext(target) {
  if (!target || typeof target.closest !== "function") return false
  if (target.tagName === "INPUT" || target.tagName === "TEXTAREA" || target.tagName === "SELECT") return true

  return !!target.closest("[contenteditable]:not([contenteditable='false'])")
}

/**
 * cw--hotkey — bind a declarative keybinding that fires an action or a click.
 *
 * Values   key (String, e.g. "cmd+k", "/", "shift+?"),
 *          scope (String, default "window" — or "element"),
 *          preventDefault (Boolean, default true)
 * Events   cw--hotkey:fired — detail carries `{ key }`
 *
 * Rule 0 lives on the presenter: `accesskey` exists and is not a real alternative
 * (no discoverability, browser/OS collisions, no way to express a chord).
 *
 * THE KEY PARSING IS HAND-ROLLED ON PURPOSE (R8a). Stimulus's built-in key filters
 * (`data-action="keydown.cmd+k->…"`) are exact-match on modifier state per descriptor,
 * which is fine for a single fixed chord but wrong for a generic component whose whole
 * job is arbitrary modifier combinations supplied at runtime through a value — there is
 * no `data-action` descriptor to bind ahead of time for a key spec that only exists as
 * a string once the presenter renders it. So `parseKeySpec`/`eventMatchesSpec` above
 * apply the identical exact-match rule by hand, once, generically, against a plain
 * `keydown` listener instead of Stimulus's action-filter syntax.
 *
 * Suppressed while typing: a keystroke that lands in an <input>, <textarea>, <select>,
 * or a contenteditable region is ignored UNLESS the spec includes a modifier — a bare
 * `/` must not steal a search box's own `/` character, but `cmd+k` should still work
 * from inside a text field. `event.isComposing` (mid-IME-composition) and
 * `event.repeat` (key auto-repeat) are both ignored outright, regardless of modifiers —
 * neither represents a deliberate, discrete keypress.
 *
 * On a match: dispatches `cw--hotkey:fired`, then performs a synthetic
 * `this.element.click()`. That second part is "just click me" — the same model
 * @github/hotkey uses (a hotkey activates an element, it doesn't carry its own
 * behaviour) — so a hotkey bound to a link navigates, one bound to a submit button
 * submits, and one bound to an element that already carries its own
 * `data-action="click->…"` composes with that for free. Consumers who want to react to
 * the keystroke itself rather than a click on this exact element can instead listen for
 * `cw--hotkey:fired` from anywhere via `data-action`.
 *
 * Exhaustive teardown (R7): the `keydown` listener (on `window` or `this.element`,
 * per `scope`) is added with a stable bound reference and removed on `disconnect()`.
 */
export default class HotkeyController extends Controller {
  static values = {
    key: String,
    scope: { type: String, default: "window" },
    preventDefault: { type: Boolean, default: true }
  }

  #spec = null
  #listenTarget = null

  connect() {
    this.#spec = parseKeySpec(this.keyValue)
    this.#attach()
  }

  disconnect() {
    this.#detach()
  }

  keyValueChanged() {
    this.#spec = parseKeySpec(this.keyValue)
  }

  // Only reconnects the listener once one already exists — mirrors
  // cw--intersection's #reconfigure guard, so the initial value hydration (which runs
  // before connect()) never tries to detach a listener that was never attached.
  scopeValueChanged() {
    if (this.#listenTarget) {
      this.#detach()
      this.#attach()
    }
  }

  #attach() {
    this.#listenTarget = this.scopeValue === "element" ? this.element : window
    this.#listenTarget.addEventListener("keydown", this.#onKeydown)
  }

  #detach() {
    this.#listenTarget?.removeEventListener("keydown", this.#onKeydown)
    this.#listenTarget = null
  }

  #onKeydown = (event) => {
    if (!this.#spec || event.isComposing || event.repeat) return
    if (!eventMatchesSpec(event, this.#spec)) return
    if (isTypingContext(event.target) && !this.#spec.hasModifier) return

    if (this.preventDefaultValue) event.preventDefault()

    this.dispatch("fired", { detail: { key: this.keyValue } })
    this.element.click()
  }
}
