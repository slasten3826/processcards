# LOVE Pair-Card Debug Bible

## Scope

This document records the exact state of the ProcessCards runtime after the first successful headless migration and during the first failed `LOVE2D` pair-card client migration.

It exists for one purpose:

- let another machine continue immediately;
- avoid repeating the same blind debugging loops;
- separate **what is already true in core/CLI** from **what is still broken in LOVE manifestation**.

This is not a general design note.
This is a migration/debug contract.

---

## 1. Strategic State

The project has already crossed the great migration threshold:

- `table` is the machine law;
- `crystall` is the headless runtime;
- `manifest` is only a client and must not invent runtime truth.

This branch is already true in code, not only in docs.

### Current truth

Core already exposes:

- `interaction(state)`
- `advance(state)`
- `apply_action(state, action)`

CLI already consumes this truth as a headless client:

- `lua cli.lua interaction`
- `lua cli.lua advance`
- `lua cli.lua autoplay [seed] [steps]`
- `lua cli.lua headless [seed] [steps]`
- `lua cli.lua play [seed]`

This means:

- core/runtime protocol is real;
- `LOVE` is now the lagging client;
- current bugs are overwhelmingly in manifestation/input/render, not in law.

---

## 2. What Was Successfully Migrated

### 2.1 Headless interaction protocol

Implemented and working:

- `src/core/interaction.lua`
- `src/core/game.lua`
- `src/sim/runner.lua`
- `cli.lua`

The engine can already answer:

1. what phase it is in;
2. what is armed;
3. what is legal;
4. whether `△/advance` is available;
5. what happened after action application.

### 2.2 New LOVE client shell

Old `main.lua` was replaced by a thin entrypoint.

New shell:

- `src/manifest/app.lua`
- `src/manifest/layout.lua`
- `src/manifest/render.lua`
- `src/manifest/input.lua`
- `src/manifest/playback.lua`
- `src/manifest/theme.lua`

The new client already does:

- start/reset/draw;
- commit manifest;
- arm hand;
- advance;
- arm operator;
- arm target;
- grave viewer open/close;
- grave target click path;
- logs to `love_trace.log`;
- reads `core.interaction(game)`;
- sends `core.apply_action(game, action)`.

This matters:

- the old controller shell is no longer the source of truth;
- the new shell is the right place to continue.

---

## 3. Pair-Card Law: What Was Implemented

### 3.1 The conceptual law

The project moved from fixed-order target selection to pair-card selection:

```text
arm operator
-> choose first anchor
-> see legal counterparts
-> choose second card
-> confirm pair with △
```

This is documented in:

- `docs/table/PAIR_CARD_LAW.md`

### 3.2 What was changed in core

New state:

- `state.pending_pair_card_choice`

Added in:

- `src/core/state.lua`

New pair-card runtime logic in:

- `src/core/turn.lua`

Implemented:

- `arm_pair_card_target(state, card_id)`
- `confirm_pair_card_target(state)`
- `choose_pair_card_target(state, card_id)`

### 3.3 LOGIC was moved onto pair-card flow

`LOGIC` no longer uses:

- `pending_public_choice -> pending_hand_choice`

Instead it now opens:

- `pending_pair_card_choice`

with:

- `legal_public_card_ids`
- `legal_hand_card_ids`
- `armed_public_card_id`
- `armed_hand_card_id`

Important:

- first anchor may be public;
- first anchor may be hand;
- second side is then chosen;
- pair is confirmed with `advance`.

### 3.4 Core interaction surface now understands pair-card

In `src/core/interaction.lua`:

- `await_target` now supports `target_kind = "pair_card"`
- `interaction.armed.targets` exists and may contain more than one armed target
- prompts change depending on pair state:
  - no anchor: `Choose the first card of the pair.`
  - public armed: `Choose one hand card.`
  - hand armed: `Choose one revealed minor card.`
  - both armed: `Confirm the selected pair.`

### 3.5 Core game dispatcher understands pair-card

In `src/core/game.lua`:

- `advance(state)` checks `pending_pair_card_choice`
- `apply_action(... kind="arm_target" ...)` dispatches to `arm_pair_card_target`

### 3.6 Inspect output was updated

In `src/core/inspect.lua`:

- snapshot now reports:
  - `pending_pair=yes/no`
  - `armed_pair_public`
  - `armed_pair_hand`

---

## 4. What Was Verified Headlessly

The pair-card migration is not speculative.
It is already verified in headless runtime.

### Scenarios that passed

- `lua cli.lua scenario public_target_arm_toggle 7`
- `lua cli.lua scenario hand_target_arm_toggle 7`
- `lua cli.lua scenario logic_manifest_swap 7`
- `lua cli.lua scenario logic_grave_swap 7`

### Benches that passed

- `lua cli.lua bench smoke 80 1`
- `lua cli.lua bench logic_manifest_swap 80 1`
- `lua cli.lua bench logic_latent_swap 80 1`
- `lua cli.lua bench logic_grave_swap 80 1`
- `lua cli.lua bench logic_topdeck_swap 80 1`
- `lua cli.lua bench autoplay 40 1`

### Strong conclusion

As of this document:

```text
pair-card core logic is considered working
headless protocol is considered working
the current breakage is in LOVE client behavior
```

---

## 5. What Was Changed in LOVE for Pair-Card

### 5.1 App trace was strengthened

In `src/manifest/app.lua`:

`love_trace.log` now includes:

- phase
- prompt
- advance enabled/reason
- armed hand
- armed operator
- primary target
- full armed target list
- target kind
- target card count
- target slot count
- current play card

This is already much better than old logging.

### 5.2 Input now understands pair-card as a legal click mode

In `src/manifest/input.lua`:

- `pair_card` clicks no longer rely only on `interaction.legal.targets.cards`
- instead they use the underlying pending pair state from core:
  - `legal_public_card_ids`
  - `legal_hand_card_ids`
  - currently armed pair cards

This was done because the narrow legal-target list is not enough for symmetric pair selection.

### 5.3 Render now understands multiple armed targets

In `src/manifest/render.lua`:

- card flags were updated to read `ix.armed.targets`
- not only `ix.armed.target`

This matters for pair-card:

- one public card may be armed;
- one hand card may be armed;
- both may need glow at once.

---

## 6. What Was Also Fixed Around LOVE

These are not the final bug, but they are real fixes already made.

### 6.1 Grave viewer lifecycle

`grave` viewer is closed automatically when the interaction is no longer in grave-select target mode.

### 6.2 Await-hand recommit support

During `await_hand`, player may recommit by clicking another manifest slot.

This is already supported:

- in core interaction legality
- in LOVE input

### 6.3 Commit/recommit by manifest card

Manifest selection was extended so clicking the actual manifest card can commit/recommit, not only the abstract slot rect.

### 6.4 No-op messaging

Current client now emits more explicit user feedback instead of silent no-op:

- `Choose a manifest card first.`
- `Choose a legal hand card or recommit manifest.`
- `Choose a legal target.`

### 6.5 No-op trace categories

Input now logs:

- `operator_click_noop`
- `commit_click_noop`
- `manifest_target_click_noop`
- `hand_click_noop`
- `target_click_noop`
- `grave_target_noop`
- `grave_viewer_noop`
- `click_no_card`
- `click_noop`
- `await_commit_hand_block`
- `await_commit_zone_block`

This is useful and should stay.

---

## 7. What Is Still Broken

### 7.1 User-facing symptom

The user’s complaint is:

```text
clicking a hand card should work as the first anchor
then legal manifest/public targets should light up by train
but this is not reading correctly in LOVE
```

Important:

- user is not talking specifically about `LOGIC` in words;
- user is talking about the general card-pair selection feeling;
- however, the only implemented pair-card consumer right now is `LOGIC`.

So practically:

- the current failure still appears through `LOGIC`,
- but the conceptual issue is broader than one operator.

### 7.2 Why this still feels broken

Even after the pair-card core migration, the LOVE manifestation is still not yet clean enough in one of these three places:

1. **Input acceptance**
   - does the click on hand card in `pair_card` phase really go through?
2. **Interaction refresh**
   - after arming hand first, does `interaction(state)` refresh into the expected counterpart-only legal set?
3. **Render semantics**
   - does the train redraw only on public counterparts after hand is armed?

Current evidence says:

- core knows how to do this;
- CLI knows how to do this;
- LOVE still fails at the “I clicked hand first, now show me public counterparts” reading.

---

## 8. What The Latest Logs Actually Showed

### 8.1 Some logs were not pair-card logs at all

Several traces never reached pair-card phase.

They stayed in:

- `await_commit`

and the clicks were:

- `zone=hand`

So those logs did **not** prove a pair-card bug.
They only proved:

- user clicked hand while the machine still wanted a manifest commit.

That was real, but not the target bug.

### 8.2 Some logs were MANIFEST logs, not LOGIC logs

At least one trace clearly showed:

- operator `MANIFEST`
- latent target selection
- `confirm_unrevealed_target`

So again:

- that trace did not localize the pair-card bug.

### 8.3 The real unresolved bug remains under-observed

The actual needed trace is still:

```text
await_operator
-> operator_click LOGIC
-> await_target target_kind=pair_card
-> click hand card
-> interaction refresh
-> counterpart train on public/manifest side
```

Without that exact trace, one can only infer, not finish.

---

## 9. Most Likely Current Failure Point

Given the state of code and the fact that headless passes, the most likely remaining problem is:

### not core law

It is probably not:

- swap legality
- pair confirmation
- pair state transitions

### but manifestation semantics

It is likely one of:

1. `pair_card` first-anchor clicks are accepted in input,
   but render still reads legal targets too broadly or too narrowly;
2. `pair_card` legal target list after first anchor is correct in core,
   but `render.lua` still visually mixes:
   - armed anchor
   - all legal pair surfaces
   - counterpart-only surfaces
3. `input.lua` and `render.lua` are not using exactly the same truth source for pair-card phase.

The current code is close, but not yet visibly canonical.

---

## 10. What The Next Machine Should Do

### Step 1

Do not touch core first.

Core is currently the least suspicious layer because:

- scenarios pass;
- benches pass;
- headless play passes.

### Step 2

Reproduce one exact pair-card flow in `LOVE`:

1. commit
2. arm hand
3. advance
4. arm `LOGIC`
5. verify `target_kind=pair_card`
6. click one hand card
7. inspect refreshed interaction
8. verify only public counterparts remain legal

### Step 3

Instrument `render.lua` directly if needed.

If ambiguity remains, add temporary on-screen debugging for:

- `target_kind`
- `armed.targets`
- `legal.targets.cards`
- each clicked card’s zone

### Step 4

If render is wrong:

- fix only render

If click is not accepted:

- fix only input

If `interaction(state)` itself is wrong after first hand anchor:

- then and only then re-open core.

### Step 5

Once hand-first pair-card reads correctly in LOVE:

- only then proceed to broader pair-card UX polish.

Do not broaden scope before that.

---

## 11. Hard Conclusions

### True

- Great Migration succeeded in core/CLI.
- Pair-card law exists in core.
- `LOGIC` already uses pair-card law in headless runtime.
- New LOVE shell is the correct shell to continue.

### False

- It is false that the old `main.lua` should be revived.
- It is false that the current problem proves pair-card law is bad.
- It is false that the current problem is definitely in core.

### Current bottleneck

The bottleneck is:

```text
LOVE pair-card manifestation fidelity
```

not:

```text
game law
```

---

## 12. Files Most Relevant For Continuation

### Core

- `src/core/state.lua`
- `src/core/turn.lua`
- `src/core/interaction.lua`
- `src/core/game.lua`
- `src/core/inspect.lua`

### CLI / headless verification

- `src/sim/scenarios.lua`
- `src/sim/runner.lua`
- `cli.lua`

### LOVE client

- `src/manifest/app.lua`
- `src/manifest/input.lua`
- `src/manifest/render.lua`
- `src/manifest/playback.lua`
- `love_trace.log`

---

## 13. Minimal Summary

If another machine has to continue in minimal context, the summary is this:

```text
core and CLI are already migrated and green
LOGIC now uses pair-card law in headless runtime
LOVE was rebuilt as a new client, not patched old main.lua
current unresolved bug is in LOVE pair-card interaction/render semantics
not in core law
```

And the next debugging target is:

```text
hand-first pair-card anchor
-> show only legal public/manifest counterparts by train
-> confirm pair with △
```
