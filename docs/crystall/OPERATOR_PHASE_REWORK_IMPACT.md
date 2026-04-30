# OPERATOR PHASE REWORK IMPACT

## Status

Current crystall note. This is a design and implementation review note,
not yet a completed migration.

## Why this matters

The current operator interaction shell is too technical for a central mechanic.

Right now the player is forced into immediate small-button choice,
with no clean no-operator route and with weak phase readability.

The proposed rework changes that.

## New intended interaction

The played card enters `play`.

Then:

- two operator cards appear as selectable action surfaces
- one may be armed
- the other may be armed
- or none may be armed

`△` confirms the current armed state.

## What this changes in the machine

### Logical layer

This is a moderate core change, not a total rewrite.

The machine already has:

- operator phase
- pending operator work
- pending target work

What changes is:

- operator selection becomes toggleable armed state
- no-operator discharge becomes a first-class legal route
- confirmation happens through `△`

### LOVE layer

This is a larger LOVE change.

The current manifestation is built around immediate operator buttons.

It will need to become:

- armed operator cards
- operator-specific target reveal only while armed
- `△` as visible continuation law
- clearer separation between selection state and execution state

## Why this is worth doing

This is not polish.

This is a structural improvement to the main interaction loop.

It makes:

- operator use optional in a clean way
- skip/no-operator natural
- target highlighting less noisy
- the whole machine easier to read

## Current recommendation

Do not patch this piecemeal in LOVE first.

Read these together:

- [../table/OPERATOR_PHASE_LAW.md](../table/OPERATOR_PHASE_LAW.md)
- [../table/ADVANCE_BUTTON_LAW.md](../table/ADVANCE_BUTTON_LAW.md)
- [../table/OPERATOR_CONFIRMATION_LAW.md](../table/OPERATOR_CONFIRMATION_LAW.md)

Then compare them against:

- `src/core/*`
- `main.lua`

and only then start the migration.
