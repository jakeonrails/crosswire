## button

```
Morph: Safe
  A button carries no DOM-only state of its own (no open/expanded/selected —
  just the variant classes and a11y attributes, all of which are re-rendered
  identically by any morph because they are pure functions of the presenter's
  constructor arguments). Nothing for a Turbo 8 morph to clobber or need to
  preserve.
```

## badge

```
Morph: Safe
  A badge carries no DOM-only state — its class list is a pure function of the
  presenter's constructor arguments, so any morph re-renders it identically.
```

## card

```
Morph: Safe
  A card carries no DOM-only state of its own (no open/expanded/selected) — its
  class list and slot contents are a pure function of the presenter's
  constructor arguments and the caller's block, so any morph re-renders it
  identically. (The real `<a>` inside an interactive card is an ordinary link;
  it has nothing for a morph to clobber either.)
```

## input

```
Morph: Safe
  An input's OWN classes/attributes are a pure function of the presenter's
  constructor arguments, so any morph re-renders those identically. The thing a
  morph could clobber — text the user is actively typing — is native browser
  state Turbo 8 already protects on its own: idiomorph does not overwrite the
  `value` of a focused form field during a page-level morph. Nothing here needs
  to add anything on top of that (contrast `Crosswire::UI::Select`, whose
  Server-owned verdict is about a DIFFERENT DOM/attribute-sync gap idiomorph
  does NOT cover for `<option selected>`).
```

## field

```
Morph: Safe
  A field's own wrapper/label/hint/error markup is a pure function of the
  presenter's constructor arguments, so any morph re-renders it identically.
  The control it wraps carries its own Morph verdict independently (`cw.input`
  is Safe; a `cw.select` composed in via `field_for` is Server-owned on its own
  terms — this presenter neither changes nor needs to know that).
```

## select

```
Morph: Server-owned
  DOM-only state: which `<option>` the browser currently shows as selected.
    Once a user (or script) has changed a `<select>`'s value, the browser does
    not keep re-deriving `.selectedIndex`/`.value` from each `<option>`'s
    `selected` HTML ATTRIBUTE — the attribute and the live IDL property can
    legitimately disagree from that point on. A DOM diff that patches the
    `selected` ATTRIBUTE onto the right `<option>` element is therefore not
    guaranteed to make the SELECT actually show that option as chosen.
  On morph: the server-rendered `<option selected>` in the new HTML is what
    must win. Turbo/idiomorph's own morph (`morphElements`) patches attributes
    correctly; the risk this verdict names is specifically whether the LIVE
    `.value` visibly follows that patched attribute for a `<select>` whose
    value has already diverged client-side — the same class of gap
    `Crosswire::UI::Select`'s sibling primitive `cw--preserve` exists to close
    for CONTROLLER-owned values, except here there is no controller to run
    `usePreserve` at all (select ships none — Rule 0). See
    `test/js/select.browser.test.js` for the proof against real
    `@hotwired/turbo`, not jsdom.
  The app must: always render the CURRENTLY correct `selected` option
    server-side on every response that could be followed by a morph (a
    redirect-after-submit, a Turbo Stream update) — never rely on the client
    to remember a selection across one. The value named here is exactly one
    thing: which `<option>` carries the `selected` attribute in the HTML the
    server sends.
```

## alert

```
Morph: Server-owned
  DOM-only state: whether the alert has been dismissed. Dismissal here is a DOM
    REMOVAL driven by a Stimulus action (`cw--dismiss`), not a Stimulus VALUE —
    there is no server-rendered `dismissed="true"` attribute a morph could ever
    see and decide to honour, the way `Crosswire::UI::Select`'s Server-owned
    verdict has a `selected` attribute to patch. That absence IS the hazard.
  On morph: this is the flash-message trap. If the SAME alert keeps being
    server-rendered on the next response that could be followed by a morph (the
    session still holds the flash, a background `broadcasts_refreshes`, a page
    that simply re-renders the same instance variable), idiomorph has no way to
    know the node the user just dismissed ever existed — the incoming HTML
    carries an element idiomorph has never been told to treat as gone, so it adds
    it right back, identical to the one the user removed. A morph does not
    "clobber" a dismissed alert; it resurrects it, because dismissal was never
    expressed anywhere the server could see. Proven, not merely asserted, against
    real `@hotwired/turbo` in `test/js/alert.browser.test.js` — that file
    DEMONSTRATES the trap (a morph brings the alert back), it does not claim to
    fix it, because nothing at this layer can: the fix is server-side.
  The app must: stop rendering a dismissed alert on the very next response that
    could be followed by a morph — consume the flash after it is read once,
    track acknowledgement server-side and stop emitting the alert once
    acknowledged, or equivalent. Client-side dismissal alone never survives a
    morph if the server does not also agree, server-side, that the alert is gone.
```

## toast

```
Morph: Excluded
  DOM-only state: which toasts currently exist in the viewport, and each one's
    live `cw--timeout` timer (paused/remaining, armed by hover) and any in-flight
    `cw--transition` leave animation. None of that has a server-side
    representation at all — a toast is never re-derived from a page's own
    instance variables the way, say, a flash `<div>` embedded in the page body
    is; it is either rendered once at the moment it was pushed (path 1 above) or
    appended once via a Turbo Stream (path 2) and never again.
  On morph: `Crosswire::UI::ToastViewport`'s shipped partial carries
    `data-turbo-permanent`, which — proven in `test/js/toast.browser.test.js`
    against real `@hotwired/turbo`, not merely asserted — a bare `morphElements()`
    call already honours on its own: `data-turbo-permanent` is checked inside
    `DefaultIdiomorphCallbacks`, the callback object `morphElements()` itself
    constructs internally, not something layered on only by Turbo's page-level
    renderer. A permanent node is skipped by the morph entirely — idiomorph never
    compares its children against the incoming HTML at all — so every toast
    inside it, and every live timer/transition driving one, survives a page-level
    morph completely untouched. See docs/BUILD-LOG.md for the full finding.
  The app must: give the viewport a STABLE id across responses (the whole reason
    `data-turbo-permanent` id-matches at all) and never rely on server-rendered
    HTML to describe which toasts are currently showing — the container's
    CONTENTS are the only source of truth once the page has loaded, exactly like
    `data-turbo-permanent`'s other shipped use (`cw--autosubmit`'s search box).
```

## dialog

```
Morph: Server-owned
  DOM-only state: the `<dialog>` element's OWN modal state — its `open`
    attribute vs. whether `showModal()`/`close()` has actually been called on it.
    `open:` is rendered server-side (R4), and the controller's `#render` calls
    `showModal()`/`close()` from that value on connect — the two are meant to
    agree, but per the HTML spec they CAN diverge: removing the `open` attribute
    does NOT call `close()`.
  On morph: this is exactly the divergence a background morph can cause. Turbo
    8's Idiomorph gives `open` no special handling, so a morph that strips it
    from a currently-open `<dialog>` would leave the document `inert` (from the
    earlier `showModal()`) with no visible, reachable modal and `close()` reduced
    to a silent no-op — the page goes dead. The controller does not rely on a
    `usePreserve` guard for this: it cancels `turbo:before-morph-element` on the
    panel outright while open (so Idiomorph never touches it mid-modal at all)
    and closes the dialog itself on `turbo:before-cache`, so a page snapshot
    never depicts a live modal as dead markup. A second, narrower guard
    (`turbo:before-morph-attribute`, the seanpdoyle turbo#1239 fix) cancels only
    the `open` attribute's own removal as defence-in-depth. Proven against real
    `@hotwired/turbo`, not merely asserted, in `test/js/dialog_controller.browser.test.js`.
  The app must: always render the CURRENTLY correct `open:` server-side on every
    response that could be followed by a morph — the controller's own defence
    stops a BACKGROUND morph from killing an already-open dialog, but a page-level
    navigation/redirect still trusts whatever `open:` the next response sends.
```

## popover

```
Morph: Preserved
  DOM-only state: whether the panel is currently open. Unlike `dialog`, this
    controller declares no `open` Stimulus value at all — the native popover
    API's own top-layer membership IS the single source of truth (`cw--popover`'s
    own docstring: "STATE LIVES IN THE BROWSER, NOT A STIMULUS VALUE"), queried
    only via `matches(":popover-open")` when needed, never written by this
    controller (`toggled()` only ever reacts to the browser's own `toggle`
    event).
  On morph: because open/closed is not expressed as any DOM attribute, there is
    nothing for Idiomorph to patch and therefore nothing for it to get wrong —
    an attribute-patching morph over the SAME panel element (Idiomorph matches
    nodes and patches in place; it does not replace the element outright) simply
    never touches the browser's native top-layer state, so an open popover stays
    open through it with no controller intervention required. This is "preserved"
    by construction rather than by an active `usePreserve` guard — there is
    nothing here for that mechanism to name. `placement`/`offset`/`strategy` ARE
    ordinary Stimulus values, but they are pure, deterministic functions of the
    presenter's own constructor arguments, so a morph re-rendering them is a
    no-op, not a hazard.
  The app must: nothing beyond the ordinary rule for a Stimulus value — if the
    SAME panel element is ever replaced outright (not patched) by a morph, its
    native popover state is lost along with the node, same as any other
    browser-owned element state (scroll position, `:hover`) would be.
```

## menu

```
Morph: Preserved
  DOM-only state: whether the menu is open, and which item currently holds
    `tabindex="0"` (assigned by the composed `cw--roving-focus`, never by this
    controller — see the class docstring's composition map). Same shape as
    `Crosswire::Presenters::Popover`'s own verdict: `cw--menu` renders NO
    Stimulus values at all (the class docstring: "STATE LIVES IN THE BROWSER,
    NOT A STIMULUS VALUE... nothing here for Turbo 8 morphing to clobber or to
    register with usePreserve"), because open/closed is the same native
    popover top-layer state `cw--popover` already leans on underneath it.
  On morph: with nothing expressed as a DOM attribute, an in-place morph over
    the wrapper has nothing to patch that would change open/closed — proven, not
    merely asserted, against real `@hotwired/turbo` (browser test 18: "an open
    menu survives `Turbo.morphElements()` over its wrapper, still open, with
    focus unmoved"). The one REAL residual hazard is different in kind: a
    background stream replacing `item` elements while the menu is open, which
    `itemTargetDisconnected` (R8) plus `cw--roving-focus`'s own stop-handoff
    cover directly — not a "state was clobbered" bug, but "the items themselves
    changed out from under an open menu," which no preserve mechanism could fix
    either.
  The app must: nothing beyond the ordinary rule for a Stimulus controller with
    no server-rendered state to keep correct — there is no `open:` kwarg here for
    a response to get wrong the way `Crosswire::Presenters::Dialog#open` can.
```

## combobox

```
Morph: Preserved
  DOM-only state: the selected `value` and whether the listbox is `expanded`.
    Unlike `Crosswire::Presenters::Popover`/`Menu`, this controller DOES declare
    ordinary Stimulus values for both (`value`/`expanded`, per `root_attrs`
    above), so there is a real attribute a morph could patch out from under a
    choice the user already made client-side.
  On morph: `static preservedValues = ["value", "expanded"]`, guarded by
    `usePreserve(this)` (called in `connect()`, AFTER the controller has
    re-rendered from its own values and flipped internal readiness — see the
    controller's own comment on that ordering) — the same `crosswire/morph`
    mechanism `cw--disclosure`/`cw--dialog`'s sibling primitives use. A
    divergence check (B2) means the SERVER still wins whenever this controller
    has not itself written a value since the last sync — the guard only stops a
    background morph from silently reverting a write THIS controller actually
    made. KNOWN RESIDUAL, documented rather than papered over: the characters the
    user has typed live in the visible `input` element's `value` PROPERTY, a
    DESCENDANT of the element `usePreserve` guards — `createMorphGuard`'s B1
    per-element scoping means a guard on the root cannot reach a descendant's
    property, by design, no matter what `preservedValues` lists.
    `aria-activedescendant`/the active option are correctly NOT preserved: they
    are transient client-only navigation state with no server-rendered
    counterpart, and morph legitimately invalidates them. Proven, not merely
    asserted, against real `@hotwired/turbo` in
    `test/js/combobox_controller.browser.test.js` (tests 20/21) — the docstring
    claims exactly what the code is observed to do, no more.
  The app must: narrow the SERVER-SIDE update's scope with
    `turbo_stream.replace(target, method: :morph)` so this combobox's own subtree
    is never the thing being morphed INTO — that is `crosswire/morph`'s own Rule
    0, and it is the only way to close the descendant-`value`-property residual
    above; `usePreserve` alone cannot reach it.
```
