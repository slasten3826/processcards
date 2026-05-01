# Great Migration Progress 2026-05-01

Status:

```text
headless interaction branch is now real
CLI is no longer only a bench harness
```

## What already landed

The migration is no longer only document intent.

The shared core now exposes a real first-pass interaction surface:

- `snapshot(state)`
- `interaction(state)`
- `advance(state)`
- `apply_action(state, action)`
- `drain_events(state)`

This is not the final protocol shape,
but it is already enough to drive a headless client.

## What `interaction(state)` already tells clients

Current interaction export already includes:

- compact phase
- prompt
- advance truth
- armed hand / operator / target
- legal commit surfaces
- legal hand cards
- legal operators
- legal targets
- grave select-mode truth

This means the machine can now answer:

```text
what is true
what is selectable
what is armed
what △ would do
```

without LOVE-side guessing.

## What `apply_action(state, action)` already supports

Current action protocol already supports:

- `commit_manifest`
- `arm_hand`
- `arm_operator`
- `arm_target`
- `advance`
- `draw`
- `resolve_pending_trump`

This is enough for a playable headless loop.

## CLI is now a real client branch

CLI is no longer only:

- snapshots
- scenarios
- benches

It now also has:

- `autoplay`
- `headless`
- `play`

### `autoplay`

Protocol-driven turn sequence with transcript.

### `headless`

Full headless run with:

- transcript
- final snapshot
- final interaction state
- explicit stop reason

### `play`

A simple interactive REPL manifestation:

- commit
- arm hand
- arm operator
- arm target
- advance
- inspect interaction

This is already a machine-facing playable shell.

## What was verified

The following are green on the current branch:

- `smoke`
- protocol scenarios
- operator arm/disarm
- target arm/disarm
- `LOGIC` protocol paths
- `autoplay`
- `headless`
- CLI REPL basic flow

This means the migration already crossed the line from:

```text
idea
```

to:

```text
working headless runtime surface
```

## Important correction made during this slice

One real interaction-truth bug was caught while using CLI:

- after `resolve_turn`
- `armed_hand` incorrectly survived into `await_operator`

That has been fixed in core.

This is important because it proves the new CLI branch
is already useful not only for benches,
but for finding runtime-truth bugs before LOVE.

## What is still missing

The migration is not done.

The following still remain:

- fuller stop-reason semantics
- terminal/loss integration
- richer action protocol around overlays
- more complete CLI game loop ergonomics
- LOVE reconnection

## What this means for LOVE

This branch now strongly argues against continuing to patch old `main.lua`.

The more correct next step is:

```text
new LOVE client
old visuals reused where useful
interaction logic not reused
```

Meaning:

- keep card rendering
- keep field layout
- keep reusable animation code
- discard old local interaction-law shell

## Short formula

```text
the great migration has started to pay rent
```

Core already speaks enough truth
for CLI to act like a real client.

That is the threshold we needed before rebuilding LOVE.
