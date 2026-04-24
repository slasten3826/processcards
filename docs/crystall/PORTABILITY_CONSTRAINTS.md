# Portability Constraints

Статус:

```text
canonical crystall constraint
```

Этот документ фиксирует ограничения portability,
чтобы движок стола не собрался как desktop-only dead end.

## 1. Core idea

Current runtime target is:

```text
Lua + LÖVE
```

But the project should stay capable of moving toward smaller devices,
including possible PSP-style constraints later.

This does not mean:

```text
build PSP version now
```

It means:

```text
do not build the skeleton in a way that makes PSP-like targets impossible
```

## 2. Design constraint

From now on the board engine should be:

```text
portable-friendly
```

not:

```text
desktop-mouse-only
```

## 3. Screen constraint

The interface must not rely on infinite desktop space.

Requirements:

- one-screen readability matters
- core surface must survive lower resolutions
- zones must keep stable positions
- important actions must remain accessible without huge horizontal spread

## 4. Input constraint

Core interaction must not depend only on:

- hover
- ultra-precise drag
- tiny hit targets
- desktop cursor assumptions

The engine should be built so that later it can support:

- mouse
- keyboard
- controller-like navigation
- PSP-style buttons / directional input

## 5. Interaction model

Preferred baseline:

```text
selection-first interaction
optional drag/drop enhancement
```

That means:

- selecting source and destination should always be possible
- drag/drop may exist,
  but core interaction must not collapse without it

## 6. Hit area law

Cards, buttons, and zone slots must keep:

- large enough click/selection areas
- stable geometry
- visually clear focus states

Tiny precision-only UI is forbidden as core interaction.

## 7. Layout law

Layout must prefer:

- strong zone hierarchy
- consistent slot grid
- predictable anchor regions
- minimal decorative waste

The board should behave like a constrained card table,
not like a desktop dashboard that only works on wide monitors.

## 8. Performance law

Do not assume:

- heavy animations
- large texture budgets
- desktop-only visual effects

Board engine skeleton should remain light enough
that later portability is not blocked by the rendering model itself.

## 9. Text law

Critical gameplay should not require dense text blocks.

Reason:

- smaller displays punish text-heavy layout
- card identity and zone structure should stay readable even when text is reduced

## 10. Architecture law

To preserve portability:

- rules must stay separate from rendering
- input mapping must not be hardwired to mouse-only logic
- UI state must be adaptable to multiple input schemes

## 11. Current working rule

For the near-term build:

- desktop LÖVE is the active runtime target
- portability is a design constraint, not a separate branch

So each UI/system decision should be checked against:

```text
would this become impossible or ugly on a small-screen / non-mouse target
```

## 12. Short formula

```text
build for desktop now
but do not paint the engine into a desktop-only corner
```
