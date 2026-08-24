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
