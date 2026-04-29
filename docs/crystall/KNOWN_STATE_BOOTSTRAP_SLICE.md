# Known State Bootstrap Slice

Status:

```text
current implementation slice
core-first information-state migration
```

## Scope

This slice introduces `known` into the shared game core
without requiring a separate visible LOVE presentation yet.

The goal is:

- make `known` real in machine truth
- avoid delaying core migration on unfinished UI language
- keep LOVE and CLI on the same information-state model

## Current decision

The runtime now supports:

```text
hidden
known
revealed
```

This is already true in the shared core.

## Current rendering stance

This slice originally allowed `known`
to remain internal-only for migration speed.

That bootstrap step is now being closed.

Current direction is:

```text
known should become visibly distinct in LOVE
while still remaining face-down in geometry
```

So the new visible target becomes:

```text
hidden   -> face-down
known    -> face-down + ghost identity
revealed -> face-up
```

## Why this is correct for now

Because the immediate requirement is not visual polish.

The immediate requirement is:

- stop collapsing machine truth to binary `face_up`
- prepare honest support for:
  - `OBSERVE`
  - `ORACLE`
  - `UNVEIL`
  - known topdeck behavior
  - later information-sensitive trump / operator rules

## Current implementation consequence

`face_up` is now treated as a rendering derivative,
not as the source of truth.

Short form:

```text
revealed => face_up
hidden/known => not face_up
```

## What this slice still does not do yet

This slice still does not define:

- final exact ghost overlay art
- special topdeck visual for `known`
- final player-facing UX language for all known-bearing zones

Those are now pushed into the next presentation slice,
not left undefined forever.

## Short formula

```text
known already exists in machine truth,
but not yet as a distinct visible LOVE state.
```
