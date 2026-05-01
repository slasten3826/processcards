# GREAT MIGRATION

## What this migration is

This is the migration where ProcessCards stops being:

```text
shared rules + partially shared interaction + local LOVE guessing
```

and becomes:

```text
one game machine
multiple manifestations
```

This is the branch where the project stops treating `LOVE2D` as the practical center of runtime truth.

After this migration, the center must be:

```text
headless game core
```

Everything else becomes a client.

## Final architecture

The target architecture is:

```text
game core
|- CLI manifestation
|- LOVE2D manifestation
```

Important:

This is **not**:

```text
core -> cli -> love
```

CLI is not a proxy.
CLI and LOVE are sibling clients of the same machine.

## Three layers

### 1. Core

The core is the machine itself.

It owns:

- rules
- zones
- phases
- legal actions
- armed state
- state transitions
- emitted events
- terminal state

It must be complete enough that no client needs to invent game truth locally.

### 2. CLI manifestation

CLI is the first headless client of the machine.

It is not only a test helper.
It must become a real playable manifestation for machines.

CLI must be able to:

- read full state
- read current interaction phase
- read legal actions
- apply actions
- advance the machine
- play full games without GUI
- run thousands of games
- collect statistics

This is the machine manifestation for:

- testing
- simulation
- balancing
- fuzzing
- bot play

### 3. LOVE2D manifestation

LOVE is the visual playable client for humans.

It must:

- read state from core
- read interaction truth from core
- read events from core
- render selection surfaces
- render armed states
- render target legality
- animate emitted events

It must not:

- invent legality
- invent phase order
- invent armed truth
- invent target truth
- reinterpret what `△` means

## Why this migration is necessary

We already extracted a lot of shared logic.

That solved:

- setup law drift
- repair law drift
- trump flow drift
- operator payload drift

But it did **not** fully solve:

- interaction truth
- phase truth
- confirm truth
- target truth

That is why `main.lua` still becomes a battlefield whenever operators get deeper.

Minor operators already exposed this.
Trump runtime will expose it much harder.

## What the core must provide

The core must provide enough truth for:

### CLI

So that machines can play:

- 1000 games in a row
- scenario benches
- policy testing
- invariant testing

### LOVE

So that a visual client can:

- show current legal surfaces
- know what is armed
- know what `△` would do
- animate what just happened

## Minimum contract

The core must be able to answer three questions:

### 1. What is true right now?

This is the machine snapshot:

- cards
- zones
- info states
- pending states
- trump states
- terminal states

### 2. What can be done right now?

This is the interaction surface:

- current phase
- legal actions
- legal targets
- armed entities
- whether `△` can advance

### 3. What just changed?

This is the event surface:

- transitions
- emitted events
- animation material for manifestations

## Target protocol shape

The exact API may still change,
but the machine needs a surface of this class:

- `snapshot(state)`
- `interaction(state)`
- `apply_action(state, action)`
- `drain_events(state)`

Meaning:

- `snapshot` = full machine truth
- `interaction` = playable current phase truth
- `apply_action` = one canonical mutation entry point
- `drain_events` = manifestation playback material

This is the strategic direction.

## Current progress

This migration is no longer only a future branch.

As of `2026-05-01`, the project already has:

- explicit `interaction(state)` in core
- shared `advance(state)` semantics
- first-pass `apply_action(state, action)`
- protocol-driven `smoke`
- protocol-driven `autoplay`
- `headless` full-run CLI command
- `play` REPL CLI command

That means the migration has already crossed into working code.

See also:

- [INTERACTION_PROTOCOL_CONTRACT.md](./INTERACTION_PROTOCOL_CONTRACT.md)
- [GREAT_MIGRATION_PROGRESS_2026-05-01.md](./GREAT_MIGRATION_PROGRESS_2026-05-01.md)

## What changes after this migration

### Before

`LOVE` still interprets pending states and decides too much locally.

### After

`LOVE` only reads and manifests.

### Before

CLI is partly a test harness around the machine.

### After

CLI is a real machine client and also a test harness.

## Point of no return

This is a serious migration because once it lands,
we should stop adding new gameplay branches directly to `main.lua`.

New mechanics should enter:

```text
table -> crystall -> manifestations
```

not:

```text
manifest first
```

That is why this is a point-of-no-return branch.

## What this unlocks

If this migration lands correctly,
ProcessCards logic becomes portable.

That means the same machine can drive:

- CLI
- LOVE2D
- 3D manifestation
- VR manifestation
- future platforms

without rewriting game logic each time.

The logic becomes platform-independent.
The manifestations become replaceable.

This is the real prize of the migration.

## What still stays local to manifestations

Manifestations may still own:

- layout
- camera
- visual emphasis
- overlays
- animation timing
- presentation wording

They do **not** own:

- rules
- phase progression
- legality
- what `△` advances
- armed truth

## Immediate next step

The next document should be the practical one:

```text
interaction protocol contract
```

That document must define what the core actually exposes to clients.

Without that, this migration remains intention.
With that, it becomes implementable.
