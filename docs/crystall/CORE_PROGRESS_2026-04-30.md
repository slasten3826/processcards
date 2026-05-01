# Core Progress 2026-04-30

Status:

```text
current implementation slice
shared core + CLI operator-confirmation branch
```

## What changed in this slice

The shared core no longer treats immediate operator execution
as its primary branch.

Instead, current core / CLI truth now supports:

- armed operator state
- explicit operator confirmation
- explicit no-operator discharge

## Current operator-phase shape in core

Current shape is now:

```text
resolve turn
-> pending operator choice
-> arm operator A / B / none
-> confirm operator phase
-> start operator payload or discharge
```

This means operator phase is now structurally closer
to the intended `△`-driven law.

## New core API surface

The shared core now exposes:

- `arm_operator(state, op_name)`
- `confirm_operator_phase(state)`

Legacy:

- `choose_operator(state, op_name)`

still exists as a compatibility wrapper,
but it is no longer the intended long-term interaction model.

## Optional operator use

Optional operator use is now real in the shared core branch.

That means:

```text
armed = none
+ confirm
= played card discharges with no operator payload
```

This is already verified in CLI scenarios.

## CLI coverage added

New scenario coverage now includes:

- operator arm toggle behavior
- no-operator discharge behavior

Existing `LOGIC` scenarios were also migrated
to the new arm + confirm branch.

## Verified status

The following were verified during this slice:

- `operator_arm_toggle`
- `operator_skip_discharge`
- `logic_manifest_swap`
- `logic_latent_swap`
- `logic_grave_swap`
- `logic_topdeck_swap`
- smoke bench

No logical failures were found in these runs.

## What is still not migrated

This slice does **not** yet migrate LOVE.

So the remaining heavy work is:

- operator-card UI in `main.lua`
- armed-state manifestation
- `△` as visible operator confirm in LOVE
- target reveal only for the armed operator

## Short formula

```text
table/crystall have moved first.
manifest still has to catch up.
```
