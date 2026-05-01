# INTERACTION PROTOCOL CONTRACT

## Purpose

This document defines the interaction surface that the headless game core must expose to clients.

The goal is:

```text
one machine
many manifestations
```

That requires a shared interaction truth, not only shared game rules.

The protocol defined here is the truth surface for:

- CLI manifestation
- LOVE2D manifestation
- future manifestations

## What this protocol must answer

At any moment, a client must be able to ask:

1. what phase the machine is in
2. what is currently armed
3. what is currently legal to select
4. whether `△` may advance now
5. what `△` would advance

This must be answerable without GUI-side inference.

## Minimal surface

The core must converge toward this surface:

- `snapshot(state)`
- `interaction(state)`
- `advance(state)`
- `apply_action(state, action)` later
- `drain_events(state)`

During migration, existing direct functions may remain:

- `commit_manifest(...)`
- `arm_hand(...)`
- `arm_operator(...)`
- `arm_target(...)`

But the target state is a single action protocol.

## `interaction(state)`

`interaction(state)` must return a machine-readable structure of this class:

```text
{
  phase = ...,
  prompt = ...,
  advance = ...,
  armed = ...,
  legal = ...,
  overlays = ...,
}
```

The exact field order is not important.
The presence of these meanings is important.

## Phase

The protocol should use a compact phase model.

Current preferred shape:

```text
await_commit
await_hand
await_operator
await_target
await_trump
idle
terminal
```

The machine may keep more detailed internal pending structures.
Clients should read the compact phase.

### Meaning

- `await_commit`
  - choose one manifest slot to commit

- `await_hand`
  - choose one hand card under current commit

- `await_operator`
  - choose operator or choose none

- `await_target`
  - choose target for the currently armed operator

- `await_trump`
  - advance pending trump event

- `idle`
  - no current player-facing selection required

- `terminal`
  - win/loss or otherwise no further play

## Prompt

The machine must expose one canonical prompt string or prompt label.

Example:

```text
Choose one revealed manifest card.
```

This prevents each manifestation from inventing its own phase wording.

## Armed state

The machine must expose armed state explicitly.

Preferred shape:

```text
armed = {
  hand_card_id = ... or nil,
  operator = ... or nil,
  target = ... or nil,
}
```

Where `target` is of this class:

```text
{
  kind = "card" | "slot" | "zone",
  zone = ...,
  card_id = ... or nil,
  slot = ... or nil,
}
```

This is the shared truth for:

- CLI selection display
- LOVE highlight state
- advance legality

## Legal selectable surfaces

The machine must expose what is legal to select in the current phase.

It should not expose vague pending data and force the client to derive meaning.

Preferred structure:

```text
legal = {
  commit_slots = {...},
  hand_cards = {...},
  operators = {...},
  targets = {
    kind = ...,
    cards = {...},
    slots = {...},
    zones = {...},
  },
}
```

Not every field needs to be populated every phase.

### Required meaning

- `commit_slots`
  - legal manifest slots to commit now

- `hand_cards`
  - legal hand cards for current step

- `operators`
  - legal operator identities for the played card

- `targets`
  - legal target surface for current operator target step

## Target kinds

Target selection must be typed.

Current target-kind family should be of this class:

```text
manifest_slot
hidden_card
unrevealed_card
public_minor_card
hand_card
zone_entry
```

This lets clients render different surfaces without inventing meaning.

### Notes

- `grave` may appear as:
  - `zone_entry` for opening viewer
  - and/or cards within a `public_minor_card` surface

- `topdeck` is not a full deck surface
  - it is a single legal card within the `deck` zone

## Advance

`△` must become a shared machine concept, not a client guess.

The protocol must expose:

```text
advance = {
  enabled = true | false,
  reason = ...,
  label = ...,
}
```

### Meaning

- `enabled`
  - whether the machine may currently advance

- `reason`
  - what kind of advance this is

- `label`
  - optional human-facing description

Current advance reasons should be of this class:

```text
confirm_turn
confirm_operator
confirm_target
resolve_trump
discharge
```

The exact names may change.
The semantic distinction must remain explicit.

## Overlays

The machine must expose overlay truth separately from geometry.

Preferred shape:

```text
overlays = {
  grave_open = true | false,
  grave_select_mode = true | false,
}
```

This is enough for clients to know:

- whether an overlay is open
- whether it is browse-mode or gameplay selection mode

Layout and rendering stay manifestation-local.

## Events

The interaction protocol does not replace event emission.

`drain_events(state)` remains necessary because manifestations need:

- movement events
- reveal events
- target events
- trump entry events
- phase transition events

`interaction(state)` tells the client what is true now.
`events` tell the client what just changed.

Both are necessary.

## Migration posture

This protocol should be introduced iteratively.

### Step 1

Add `interaction(state)` over current internal pending structures.

### Step 2

Add `advance(state)` as one shared machine function.

### Step 3

Make CLI consume `interaction(state)` directly.

### Step 4

Introduce unified `apply_action(state, action)`.

### Step 5

Make LOVE consume the same protocol and remove local interaction-law guessing.

## Success condition

This contract is successful when:

1. CLI can play the machine using protocol truth
2. LOVE can render selection/advance truth without local inference
3. new operators do not require inventing new local control laws in `main.lua`

## Non-goal

This protocol is not a UI layout contract.

It does not define:

- button positions
- overlay geometry
- animation speed
- color treatment
- train styling

Those remain manifestation concerns.

It defines only interaction truth.
