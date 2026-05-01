# LOVE Client Rebuild 2026-05-01

## Purpose

This document records the reading of the current `main.lua`
after the headless interaction branch became real.

The goal is to define:

- what the old LOVE layer still does well
- what can be reused
- what must not survive into the new client

## Current diagnosis

The current `main.lua` is not only a visual client.

It is a mixed shell containing:

1. rendering
2. animation playback
3. input mapping
4. local interaction interpretation
5. legacy DEV manipulation tools
6. compatibility glue for old gameplay flow

That mixture was tolerable while interaction truth still lived partly in LOVE.

After the headless migration, this file is now structurally wrong as a client root.

The problem is not that the file is ugly.
The problem is that it still knows too much.

## What the file currently contains

The current `main.lua` contains these classes of code:

### 1. Visual canon and colors

This is still useful:

- `COLORS`
- `OP_COLORS`
- glyph color choices
- card frame language
- panel tone language

These are manifestation assets, not game-law logic.

They may be reused.

### 2. Layout and geometry

Also reusable:

- `make_layout()`
- zone rect layout
- slot rect generation
- hand layout
- grave viewer geometry
- top/header/footer placement ideas

This is presentation structure.
It belongs in the new LOVE client.

### 3. Card rendering

Mostly reusable:

- `draw_card(...)`
- segmented frame drawing
- breath halo
- card back / face rendering
- glyph rendering hookups
- known/revealed visual treatment

This is manifestation code.
It should be lifted out, not deleted.

### 4. Playback / animation helpers

Potentially reusable:

- move animations
- flip animations
- predicted rect helpers
- event-driven playback helpers

But only if they are fed by core events.

If a playback helper assumes local gameplay truth,
it must be rewritten or dropped.

### 5. Core sync and shadow state

This is where the current file becomes dangerous.

Examples:

- `sync_from_core(...)`
- copied `pending_*` state
- copied `armed_*` state
- copied `legal_hints`
- copied `committed`

This layer is already too thick.

The new client should not clone interaction truth into ad hoc local mirrors
except where needed for transient animation playback.

## What must not survive

The following logic should not survive into the new client shell:

### Local phase interpretation

Examples:

- deciding what phase the player is in
- deciding what `Space` means
- deciding whether an operator should open a target phase
- deciding whether target selection is active

This now belongs to `core.interaction(state)`.

### Local legality derivation

Examples:

- deriving legal targets from copied pending fields
- deriving grave legality locally
- deriving hand legality locally
- deriving operator legality from visual state

This now belongs to `interaction(state).legal`.

### Local armed truth

Examples:

- `state.ui.armed_target`
- fallbacks for armed operator inference
- phase-specific local guesses about what is selected

This now belongs to `interaction(state).armed`.

### Local confirm routing

Examples:

- `if pending_public_choice then confirm_public ...`
- `if pending_manifest_choice then confirm_manifest ...`
- `if pending_operator_choice then confirm_operator ...`

This routing should collapse toward:

```text
Space -> apply_action({kind="advance"})
```

The client should not reinterpret `△`.

## What should be reused

The new LOVE client should reuse only these classes of code:

### Keep

- visual constants
- glyph presentation
- card rendering
- frame rendering
- panel rendering
- layout math
- grave viewer rendering/layout ideas
- animation primitives
- event playback primitives

### Do not keep as controller truth

- copied gameplay pending state
- manual phase routing
- manual target legality
- manual `Space` branching
- old DEV interaction shell

## Required shape of the new LOVE client

The new client should be split by responsibility.

Suggested file split:

- `src/manifest/app.lua`
  - boot
  - owns core game object
  - fetches `interaction`
  - sends `apply_action`

- `src/manifest/layout.lua`
  - geometry
  - zone rects
  - overlay rects

- `src/manifest/render.lua`
  - panels
  - cards
  - operator cards
  - grave viewer

- `src/manifest/input.lua`
  - maps clicks/keys to protocol actions
  - no gameplay inference beyond hit-testing

- `src/manifest/playback.lua`
  - event queue
  - move / flip playback
  - temporary ghost state only

This split matters because it prevents the old controller soup from reforming.

## New client law

The new LOVE client must follow this rule:

```text
render snapshot
render interaction
map user gesture to action
apply action
play emitted events
repeat
```

Not:

```text
guess phase
guess legality
guess confirm route
then maybe tell core
```

## Grave implication

The current grave viewer can be reused conceptually:

- overlay shape
- newest-first ordering
- click-outside close

But its gameplay meaning must come from the protocol:

- browse-mode
- target-mode

The client should not invent when grave is relevant.

## DEV mode implication

The old `DEV` manipulation shell does not belong in the new runtime client root.

It may later return as:

- separate debug overlay
- separate tool mode
- separate developer manifestation

But it should not remain fused into the gameplay controller.

## Conclusion

The current `main.lua` is valuable as:

- visual reference
- rendering source
- animation source
- layout source

It is not a good base for continued gameplay-controller patching.

Therefore the correct next step is:

```text
keep visual assets
discard old controller shell
build a new LOVE client on top of headless interaction protocol
```

## Short formula

```text
old LOVE is now an asset mine
not the future runtime shell
```
