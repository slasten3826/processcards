# HEADLESS INTERACTION MIGRATION

## Purpose

This is the migration from:

```text
core decides rules
LOVE still decides too much interaction truth
```

to:

```text
core decides rules and interaction truth
CLI consumes that truth headlessly
LOVE manifests that same truth visually
```

This is the point-of-no-return branch for ProcessCards interaction.

The goal is not a prettier CLI.
The goal is a complete headless machine that can drive:

- CLI play
- CLI testing
- LOVE2D
- future 3D / VR / other manifestations

without re-inventing turn flow in each client.

## Why this migration is necessary

We already have shared game logic.

But `main.lua` still decides too much:

- what phase the player is currently in
- what `△` should confirm
- which targets are legal
- what is armed
- when a target phase begins
- how grave interaction enters gameplay

This worked while the machine was small.

It does not scale to:

- armed operator flow
- armed target flow
- grave as real gameplay surface
- trump class runtime
- future trump payloads

Minor operators already exposed the problem.
Trump operators will magnify it.

## Point Of No Return

After this migration, `LOVE` is no longer allowed to be an interaction-law coauthor.

It may:

- render state
- render legal actions
- render armed state
- send chosen actions back into core
- animate emitted transitions

It may not:

- infer hidden phase logic
- invent fallback confirm laws
- maintain its own source of truth for legal targets
- maintain its own source of truth for armed targets

If `LOVE` needs to guess, the migration is incomplete.

## New source of truth

The source of truth must move from:

```text
pending_* fields + LOVE-side interpretation
```

to:

```text
explicit headless interaction protocol
```

The protocol lives in `table` law and is executed by `crystall`.

## Canonical interaction model

### Core principle

`armed` is pre-manifest state.

`△` is act of manifestation / machine advance.

That canon stays.

### Required interaction truth

The headless machine must expose:

- current phase
- currently legal actions
- currently armed entities
- whether `△` can advance now
- what target class is currently expected

This must be machine-readable without GUI assumptions.

## Interaction phases

The exact names may change, but the machine needs explicit phases of this class:

- `await_commit`
- `await_hand_arm`
- `await_move_advance`
- `await_operator_arm_or_discharge`
- `await_target_arm`
- `await_target_advance`
- `await_trump_advance`
- `terminal`

Important:

`await_target_arm` and `await_target_advance` are not GUI ideas.
They are runtime truths.

## Canonical actions

The machine must converge toward a unified action protocol of this class:

- `commit_manifest(slot)`
- `arm_hand(card_id)`
- `arm_operator(op_name_or_nil)`
- `arm_target(target_ref)`
- `advance()`
- `open_grave()`
- `close_overlay()`

Not every client must expose every action the same way.
But every client must use the same underlying action truth.

## Legal action export

The headless runtime must eventually expose not only raw pending fields, but an explicit legal-action surface.

Example shape:

```text
phase = await_target_arm
armed_operator = CHOOSE
legal_targets = [...]
armed_target = ...
can_advance = false
```

Or an equivalent structured API.

The exact format is implementation detail.
The existence of this surface is not optional.

## CLI target state

CLI must stop being only a scenario bench.

It must become a real headless client of the machine:

- show state
- show current phase
- show legal actions
- apply chosen action
- play a full game without GUI

The scenario bench stays.
But it becomes a consumer of the same interaction protocol, not a parallel interface.

## LOVE target state

After the migration:

- `LOVE` reads phase from core
- `LOVE` reads armed state from core
- `LOVE` reads legal targets from core
- `LOVE` maps `Space` to `advance()`
- `LOVE` maps clicks to explicit arm/open actions

`LOVE` should never need to decide whether a click means:

- arm
- confirm
- skip
- advance

That must already be decided by the machine protocol.

## Grave implication

`LOGIC` already proved that `grave` is not a decorative stack.

Therefore the protocol must support:

- neutral grave viewing
- grave as legal target zone when the machine says so

This is not a `LOGIC`-only visual exception.
It is proof that machine-space interaction must be generalized.

## Migration order

This branch must proceed in this order:

1. `table`
   - finalize headless interaction canon

2. `crystall`
   - implement explicit interaction protocol in core
   - update CLI and scenario bench to consume it
   - test until green

3. `manifest`
   - reconnect LOVE to that protocol
   - remove local interaction-law guessing

Not the reverse.

## Immediate implementation priorities

### First

Introduce an explicit interaction/phase surface in core.

This can be:

- `src/core/interaction.lua`
- or `src/core/phase.lua`
- or equivalent

But it must centralize phase truth.

### Second

Make CLI consume that surface directly.

### Third

Rewire `main.lua` to that surface and delete local interpretation layers.

## What must remain local to LOVE

These things may stay client-side:

- animations
- panel layout
- button placement
- grave viewer geometry
- glow / train / framing decisions

These things must not stay client-side:

- legality
- phase progression
- armed truth
- target truth
- meaning of `△`

## Success condition

This migration is successful when:

1. core can describe current interaction truth without GUI help
2. CLI can play the machine through that truth
3. LOVE only manifests and animates that truth
4. adding a new operator or trump effect does not require inventing a new local UI law in `main.lua`

## Strategic value

If this migration lands cleanly, game logic becomes portable.

That means the same ProcessCards machine can drive:

- CLI
- 2D
- 3D
- VR
- other future manifestations

without re-authoring the game each time.

That is why this is heavy work.
And that is why this branch is worth doing correctly.
