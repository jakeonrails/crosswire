import { Controller } from "@hotwired/stimulus"

// In-memory fallback store, shared by every instance in this JS context. Storage reads
// and writes can throw (Safari private browsing, a full quota, disabled cookies), and a
// component library must degrade silently rather than break the page — this is what it
// degrades TO. It is intentionally page-lifetime only: a real fallback would just be
// localStorage, which is exactly what is unavailable.
const memoryStore = new Map()

// Elements already warned about refusing to persist a password field, so a Turbo
// reconnect doesn't spam the console every time.
const warnedPasswordElements = new WeakSet()
const warnedMissingKeyElements = new WeakSet()

/**
 * cw--persist — mirror one piece of element state to localStorage/sessionStorage and
 * reapply it on connect.
 *
 * Values   key (String, required), attribute (String, default "value"),
 *          storage (String, default "local" — or "session"), debounce (Number ms, default 0)
 * Events   cw--persist:restored, cw--persist:saved
 *
 * Reads and writes one of three shapes depending on `attribute`:
 *   "value"    element.value              (String)  — input/change events
 *   "checked"  element.checked            (Boolean)  — change events
 *   "open"     element.open               (Boolean)  — toggle events (<details>)
 *   anything else  a generic HTML attribute via get/set/removeAttribute — since a
 *     plain attribute is not reflected by input/change/toggle, this path is driven by
 *     a MutationObserver instead, which is also what lets this cover state set by
 *     another controller (an accordion's data-state, a sidebar's data-collapsed, …).
 *
 * Survives a Turbo morph: morphing overwrites `data-*-value` attributes and skips
 * connect() entirely (turbo#1210, closed won't-fix), so state re-applies on
 * `turbo:morph-element` too. Deliberately element-scoped (`this.element.addEventListener`,
 * not `turbo:morph@window`) — the window-scoped event fires page-wide and has hung
 * browsers with many controllers mounted. Because `turbo:morph-element` bubbles once per
 * morphed descendant, the handler checks `event.target === this.element` so it only
 * reacts to morphs of the element it actually owns.
 *
 * Every storage read/write is wrapped; failures degrade silently to an in-memory
 * fallback rather than breaking the page.
 *
 * Refuses to run against `type="password"` fields. Storing credentials in Web Storage
 * is a security bug; the controller detects this at connect and warns once instead of
 * persisting anything.
 */
export default class PersistController extends Controller {
  static values = {
    key: String,
    attribute: { type: String, default: "value" },
    storage: { type: String, default: "local" },
    debounce: { type: Number, default: 0 }
  }

  #timer = null
  #observer = null

  connect() {
    if (this.#isPasswordField()) {
      this.#warnOnce(warnedPasswordElements, "cw--persist: refusing to persist a %s field — " +
        "storing credentials in Web Storage is a security risk.", "password")
      return
    }

    if (!this.hasKeyValue || this.keyValue === "") {
      this.#warnOnce(warnedMissingKeyElements,
        "cw--persist: no key value given; refusing to persist %o to avoid " +
        "clobbering unrelated elements under a shared empty key.", this.element)
      return
    }

    this.#restore()
    this.#bind()
    this.element.addEventListener("turbo:morph-element", this.#handleMorph)
  }

  disconnect() {
    this.#unbind()
    this.element.removeEventListener("turbo:morph-element", this.#handleMorph)

    if (this.#timer) {
      clearTimeout(this.#timer)
      this.#timer = null
    }
  }

  #bind() {
    const events = this.#nativeEvents()

    if (events) {
      for (const type of events) this.element.addEventListener(type, this.#handleChange)
    } else {
      this.#observer = new MutationObserver(this.#handleChange)
      this.#observer.observe(this.element, { attributes: true, attributeFilter: [this.attributeValue] })
    }
  }

  #unbind() {
    const events = this.#nativeEvents()

    if (events) {
      for (const type of events) this.element.removeEventListener(type, this.#handleChange)
    }

    this.#observer?.disconnect()
    this.#observer = null
  }

  // input/change/toggle for the three well-known DOM properties; null for a generic
  // attribute, since typing into a value or toggling a checkbox fires DOM events but an
  // arbitrary attribute change (typically made by another controller) does not.
  #nativeEvents() {
    switch (this.attributeValue) {
      case "value": return ["input", "change"]
      case "checked": return ["change"]
      case "open": return ["toggle"]
      default: return null
    }
  }

  #handleChange = () => {
    if (this.debounceValue > 0) {
      clearTimeout(this.#timer)
      this.#timer = setTimeout(() => this.#save(), this.debounceValue)
    } else {
      this.#save()
    }
  }

  #handleMorph = (event) => {
    if (event.target !== this.element) return

    this.#restore()
  }

  #restore() {
    const stored = this.#readStorage()

    if (stored !== undefined) this.#write(stored)

    this.dispatch("restored", { detail: { value: this.#read(), found: stored !== undefined } })
  }

  #save() {
    const value = this.#read()
    this.#writeStorage(value)
    this.dispatch("saved", { detail: { value } })
  }

  #read() {
    const element = this.element

    switch (this.attributeValue) {
      case "value": return element.value
      case "checked": return element.checked
      case "open": return element.open
      default: return element.hasAttribute(this.attributeValue)
        ? element.getAttribute(this.attributeValue)
        : null
    }
  }

  #write(value) {
    const element = this.element

    switch (this.attributeValue) {
      case "value":
        element.value = value ?? ""
        break
      case "checked":
        element.checked = value === true || value === "true"
        break
      case "open":
        element.open = value === true || value === "true"
        break
      default:
        if (value === null || value === undefined) {
          element.removeAttribute(this.attributeValue)
        } else {
          element.setAttribute(this.attributeValue, value)
        }
    }
  }

  #storageKey() {
    return `cw--persist:${this.keyValue}`
  }

  #storageArea() {
    try {
      return this.storageValue === "session" ? window.sessionStorage : window.localStorage
    } catch {
      return null
    }
  }

  #readStorage() {
    const key = this.#storageKey()
    const area = this.#storageArea()

    if (area) {
      try {
        const raw = area.getItem(key)
        if (raw !== null) return JSON.parse(raw)
        return undefined
      } catch {
        // Fall through to the in-memory store — quota exceeded, disabled storage,
        // corrupt JSON, or a browser that throws just for touching the API.
      }
    }

    return memoryStore.has(key) ? memoryStore.get(key) : undefined
  }

  #writeStorage(value) {
    const key = this.#storageKey()
    const area = this.#storageArea()

    if (area) {
      try {
        area.setItem(key, JSON.stringify(value))
        memoryStore.delete(key)
        return
      } catch {
        // Quota exceeded or storage disabled — degrade silently to memory below.
      }
    }

    memoryStore.set(key, value)
  }

  #isPasswordField() {
    return this.element.type === "password"
  }

  #warnOnce(set, message, ...args) {
    if (set.has(this.element)) return

    set.add(this.element)
    console.warn(message, ...args)
  }
}
