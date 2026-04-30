# OPERATOR REWORK MIGRATION CHECKLIST

## Status

Current crystall migration checklist.

This document compares the new operator-confirmation branch
against the current codebase.

## Goal

Move from:

```text
click operator -> effect begins immediately
```

to:

```text
arm operator or arm none
press △
effect begins only after confirmation
```

## What already matches

These parts already exist and should be preserved:

- shared core as source of truth
- `play` as real operator-phase zone
- first repair before operator work
- second repair when an operator reopens structure
- trump flow waiting until operator phase closes
- per-operator target branches:
  - hidden targets
  - unrevealed targets
  - manifest targets
  - hand targets
  - public targets

So this is not a fresh redesign of the whole machine.

It is a migration of the operator entry and confirmation shell.

## Core changes required

### 1. Replace immediate operator choice with armed state

Current core:

- `pending_operator_choice`
- `choose_operator(state, op_name)`

Target form:

- `pending_operator_choice` stores:
  - `card_id`
  - `choices`
  - `armed_operator`
- add an `arm_operator(state, op_name_or_nil)` path

Meaning:

- click does not begin effect
- click only changes armed state

### 2. Add no-operator route

Current core has no real `none` resolution branch.

Need:

```text
armed = nil
+ △
= play -> grave
```

without operator payload.

### 3. Add confirm path for operator phase

Need a core-level action like:

- `confirm_operator_phase(state)`

This function should:

- read current `pending_operator_choice`
- inspect `armed_operator`
- if `armed_operator == nil`, discharge played card
- if `armed_operator` is set, start that operator's effect path

### 4. Keep existing target pipelines

These branches should remain,
but they should start from confirmation instead of from raw operator click:

- `CHOOSE -> pending_manifest_choice`
- `OBSERVE -> pending_hidden_choice`
- `LOGIC -> pending_public_choice`
- `MANIFEST -> pending_unrevealed_choice`
- `CYCLE -> draw then pending_hand_choice`

### 5. Keep target resolution APIs

These already fit the future model and should remain:

- `choose_manifest_target(...)`
- `choose_hidden_target(...)`
- `choose_public_target(...)`
- `choose_unrevealed_target(...)`
- `choose_hand_target(...)`

They do not need conceptual redesign.

## LOVE changes required

### 1. Replace immediate operator buttons with armed operator cards

Current LOVE behavior:

- click glyph button
- effect starts immediately or target phase begins immediately

Target behavior:

- click left operator card -> left armed
- click right operator card -> right armed
- click armed card again -> none armed

Only one operator may be armed at a time.

### 2. Move confirmation to `△`

Current LOVE:

- `△` launches turn
- `△` resolves pending trump
- operator click itself begins operator execution

Target LOVE:

- `△` launches turn
- `△` confirms current operator armed state
- `△` continues trump flow

### 3. Show targets only for armed operator

Current LOVE shows targets only after the operator branch has already begun.

Target LOVE:

- armed `OBSERVE` reveals hidden target language
- armed `CHOOSE` reveals manifest targets
- armed `MANIFEST` reveals unrevealed targets
- armed `LOGIC` reveals public targets and grave-zone entry
- armed `CYCLE` does not reveal targets until after confirm and draw

### 4. Keep later target-picking as click-driven

This migration does not require `△` to replace every later click.

Current first-pass target pick model may remain:

- arm operator
- `△` confirms operator
- if that operator needs targets,
  choose target by click

This is enough for the migration branch.

### 5. Rework operator-phase UI messaging

Current messaging is still built around:

- choose operator now

Need messages that read like:

- arm operator or arm none
- press `△` to continue
- choose target

## Grave / LOGIC implication

The grave viewer may remain structurally separate from this migration.

What changes later is only:

- when `LOGIC` is armed,
  grave becomes a visible legal zone entry
- after confirm,
  grave viewer may act as picker

The neutral grave viewer does not need redesign for this branch.

## What should not be rewritten

Do not rewrite these unless a concrete blocker appears:

- repair law
- trump flow class runtime
- info-state model `hidden / known / revealed`
- existing target-choice core APIs
- grave viewer baseline UI

## Migration order

Recommended order:

1. patch core armed-state model
2. patch CLI / scenario runner around new confirm path
3. run smoke and operator scenarios
4. patch LOVE operator UI
5. patch LOVE target-visibility rules
6. only then tune animations / polish

## Short formula

```text
keep the machine
replace the operator entry shell
move confirmation into △
let LOVE catch up after core and CLI hold
```
