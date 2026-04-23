# Context

`ProcessCards` is a card-game manifestation of ProcessLang topology.

It is being designed as a closed-system solitaire / engine game.
It is inspired by the combo-engine pleasure of Magic: The Gathering, but without the duel shell.

Important distinction:

```text
slastack = canon / ontology / machine surface
ProcessCards = downstream playable artifact
```

This directory is for the playable artifact.
The main slastack repository remains the source of design documents and ProcessLang canon.

## Current design shape

The current design direction is roughly:

```text
ProcessCards = slot-based manifest-chain solitaire with bounded hidden state
```

Core board image:

```text
5 columns × 2 layers

manifest row = 5 face-up cards
latent row   = 5 face-down cards
```

Other zones:

```text
deck
hand
targets
runtime lane
grave
trump zone
```

## Current important ideas

- `hand` is a player-side table of available interventions.
- `manifest row` is the visible process chain.
- `latent row` is hidden but already structured board-state.
- `grave` is open ordered residue.
- `targets` compile a victory grammar, not three unrelated goals.
- `minor = state`.
- `trump = event`.
- `trump zone` is a two-event pressure chamber.
- The first serious trump candidate is `RECAST`.

## What we are doing now

We want to write a Lua table-based simulator because natural-language design is starting to sprawl.

The simulator is a thinking tool.
It should reveal contradictions, missing rules, and dead mechanics.

If implementation exposes a design problem, report it clearly.
Do not silently invent a big rule unless it is necessary to keep the prototype running.

machines only. not for humans.
