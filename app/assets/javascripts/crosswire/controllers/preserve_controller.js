import { Controller } from "@hotwired/stimulus"
import { createMorphGuard } from "crosswire/morph"

/**
 * cw--preserve — protect specific attributes (or a whole subtree) of an element from
 * Turbo 8 morphing, for elements whose behaviour comes from a controller you do NOT
 * own — a third-party Stimulus controller, a web component, a JS library that writes
 * its own attributes at runtime.
 *
 * Landscape this exists in (research/notes/14-morphing-dossier.md has the full
 * source-verified account): Turbo 8's morph overwrites every attribute on the live
 * element that is absent from, or different from, the server's HTML, and it never
 * re-runs `connect()`/`connectedCallback()` for an element that survives — the single
 * most common way a mounted widget (TomSelect, a map, a rich text editor) goes dead
 * after any morphed page render. If you own the controller, prefer `usePreserve` from
 * `crosswire/morph` (`static preservedValues` / `static preservedAttributes`) — it is
 * declarative in the controller class and needs nothing from the view author. This
 * controller is the markup-driven escape hatch for the case that leaves: code you
 * cannot add a static property to.
 *
 * Values   attributes (String, space-separated attribute names to protect),
 *          element (Boolean, default false — full-subtree opt-out, see below)
 *
 * Stack it on the element whose attributes need protecting, alongside whatever
 * controller actually owns them:
 *
 *   <div data-controller="tom-select cw--preserve"
 *        data-cw--preserve-attributes-value="data-selected">
 *
 * `attributesValue` is read fresh on every check, so changing it at runtime (a server
 * re-render, another controller writing it) takes effect on the very next morph — it
 * is never cached at connect() time.
 *
 * `elementValue: true` exempts the WHOLE subtree, attributes and children alike — the
 * equivalent of `data-turbo-permanent`, but scoped to morph passes only (it does not
 * also leak into an ordinary Drive navigation to a different page the way
 * `data-turbo-permanent` does):
 *
 *   <div data-controller="leaflet-map cw--preserve" data-cw--preserve-element-value="true">
 *
 * Same divergence check as the controller-owned form (B2 in the dossier's design
 * brief): an attribute is only protected once ITS current DOM value has actually
 * diverged from what was recorded the last time this guard synced. This is the fix
 * over the prior art it is modelled on — Evil Martians' `data-turbo-morph-permanent-
 * attrs` (2025-06-24) protects unconditionally, so the server can never update that
 * attribute again, for the lifetime of the page. Naming it once here rather than
 * scattering it once per attribute is deliberate: cheap to add, easy to forget to
 * remove, and the tell that it has outlived its purpose is the same either way — the
 * page state it is protecting could instead be rendered by the server (Radan Skorić's
 * "family 3": persist the state, and the problem evaporates along with a maintenance
 * liability).
 */
export default class PreserveController extends Controller {
  static values = {
    attributes: String,
    element: Boolean
  }

  connect() {
    this.#guard = createMorphGuard(this.element, {
      attributeNames: () => this.#attributeNames(),
      preserveElement: () => this.elementValue
    })
  }

  disconnect() {
    this.#guard?.teardown()
    this.#guard = null
  }

  #guard = null

  #attributeNames() {
    if (!this.hasAttributesValue) return []

    return this.attributesValue.trim().split(/\s+/).filter(Boolean)
  }
}
