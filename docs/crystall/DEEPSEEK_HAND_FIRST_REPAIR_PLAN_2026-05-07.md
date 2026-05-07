# DeepSeek Hand-First Repair Plan

## Scope

This document records the repair plan for the recent hand-first flow changes.

It is not a blame document.
It is not a rollback note.
It is a continuation contract.

Reason:

- the machine was changed under active development;
- limits ended mid-stream;
- work had to continue;
- the current branch contains both strong ideas and real protocol regressions.

Short reading:

```text
the hand-first direction is worth preserving
the current implementation is not yet protocol-complete
```

---

## 1. What Changed

The new branch introduced:

1. a hand-first interaction model;
2. a new phase sequence:
   - `await_start`
   - `await_complete`
   - `await_ready`
3. explicit clear actions:
   - `clear_selection`
   - `clear_committed`
   - `clear_armed`
4. a real CLI/TUI manifestation:
   - `src/cli/glyphs.lua`
   - `src/cli/input.lua`
   - `src/cli/render.lua`
   - `src/cli/main.lua`

This means the branch is not a trivial patch.
It is a partial machine rewrite plus a new manifestation.

---

## 2. What Is Good And Should Be Preserved

These are not mistakes.
They are good direction.

### 2.1 Hand-first selection

Allowing the player to begin from hand is strong.

It better matches:

- armed law
- pre-manifest thinking
- pair-card direction
- future richer target selection

### 2.2 Clear separation of intermediate states

The new phases:

- `await_start`
- `await_complete`
- `await_ready`

are conceptually stronger than the old binary `await_commit / await_hand`.

They acknowledge:

- first selection
- incomplete pairing
- ready-to-cast confirmation

That is good design pressure.

### 2.3 Dedicated CLI manifestation

The ANSI/TUI client is a real gain.

It pushes `crystall` in the right direction:

- headless truth
- visible text manifestation
- less dependence on `LOVE` for interactive debugging

This should absolutely stay.

---

## 3. What Is Broken Right Now

These are the concrete regressions that currently matter.

## 3.1 Protocol clients do not understand the new phases

The headless protocol runners still expect the old phase vocabulary.

Examples:

- `src/sim/runner.lua`
- `cli.lua` autoplay/headless helpers

Current consequence:

```text
headless/autoplay stop at await_start
```

Observed symptom:

```text
unknown_phase_await_start
```

This is a real `crystall` regression.

The machine changed,
but protocol consumers were not fully migrated with it.

---

## 3.2 `interaction(state)` does not fully describe the new hand-first truth

In `await_start`,
the prompt says:

```text
Choose a manifest slot or a hand card.
```

But interaction currently exports only:

- `legal.commit_slots`

and does **not** export:

- legal first-pick hand surfaces

This is a direct violation of the new architecture.

Because:

```text
if a client must guess, migration is incomplete
```

So at the moment:

- text suggests hand-first selection is legal,
- protocol truth does not fully expose it.

That gap must be closed.

---

## 3.3 `arm_hand` is currently too phase-loose

Current behavior allows `arm_hand` to mutate state even when:

- no commit exists,
- or the machine is already in later phases.

This creates a runtime hole.

It is not merely UI awkwardness.

It means the engine can enter states like:

```text
await_operator
with newly changed armed_hand
```

That should not be allowed unless explicitly canonized.

Current judgment:

```text
arm_hand is under-gated
```

This must be repaired either:

- in core,
- or in the action layer,
- but preferably in core-truth itself.

---

## 3.4 The new CLI input is ahead of the protocol contract

The TUI input already behaves as if hand-first is canon.

That is fine in spirit,
but right now it outruns the interaction protocol.

Meaning:

- the CLI UI can perform useful actions,
- but the exported protocol is not yet equally explicit.

This creates asymmetry between:

- what the CLI does,
- what other clients are formally told they may do.

That asymmetry must be removed.

---

## 4. What Is Not The Problem

This is important.

The problem is **not**:

- that hand-first is a bad idea;
- that the machine must be rolled back immediately;
- that the CLI client was a mistake;
- that the old `LOVE` path was better.

The problem is:

```text
the new machine idea was introduced faster
than the protocol and client surfaces were normalized
```

So the repair is not:

```text
undo everything
```

It is:

```text
finish the migration properly
```

---

## 5. Repair Goal

The branch is repaired when all of the following are true:

1. the new phases are recognized by all headless clients;
2. `interaction(state)` fully describes legal hand-first entry;
3. `arm_hand` cannot corrupt later phases;
4. CLI and `LOVE` can both consume the same truth without guessing;
5. `smoke`, `autoplay`, `headless`, and manual CLI play all stay green.

Short formula:

```text
hand-first must become protocol truth
not just local UI behavior
```

---

## 6. Exact Repair Order

This order matters.

### Step 1 — Normalize `interaction(state)`

Do this first.

The interaction contract must describe the new machine honestly.

Specifically:

- `await_start` must expose all legal first surfaces;
- `await_complete` must expose what is still missing;
- `await_ready` must expose ready-to-cast confirmation state;
- prompts and legal sets must agree.

This is the root contract.

Without this, every client will keep improvising.

---

### Step 2 — Repair protocol consumers

Then update:

- `src/sim/runner.lua`
- `cli.lua`
- any helper autoplay/headless loops

They must understand:

- `await_start`
- `await_complete`
- `await_ready`

and act on them as first-class phases.

No old-phase fallback should remain silently relied on.

---

### Step 3 — Tighten `arm_hand`

Then decide explicitly:

When is `arm_hand` allowed?

The answer must be machine-law clear.

Likely allowed:

- `await_start`
- `await_complete`

Likely forbidden:

- `await_operator`
- `await_target`
- `await_trump`

If hand mutation outside these phases is still desirable,
that must be a separate canon decision,
not an accidental side effect.

---

### Step 4 — Validate CLI manifestation against protocol

The new ANSI/TUI client should then be reviewed not as a toy,
but as a first-class `crystall` client.

Check:

- does it only do what protocol allows?
- does every visible selection have protocol support?
- does clear/deselect behavior align with machine truth?

The CLI client should become:

```text
the first trusted interactive manifestation
```

before more `LOVE` work continues.

---

### Step 5 — Only then re-evaluate LOVE

`LOVE` should not be the place where hand-first is discovered.

`LOVE` should inherit it from the repaired core + crystall branch.

Meaning:

- first repair protocol truth,
- then verify CLI,
- then reconnect `LOVE`.

---

## 7. Recommended Core Questions To Resolve Explicitly

Before coding, these questions should be answered concretely.

### 7.1 In `await_start`, can the player legally begin from either side?

If yes, protocol must expose:

- legal hand picks
- legal manifest picks

not only one of them.

### 7.2 What exactly is `await_complete`?

It appears to mean:

```text
one side is chosen
the other side is still missing
```

That must be formalized and kept consistent across:

- prompts
- legal sets
- advance behavior

### 7.3 What exactly is `await_ready`?

It appears to mean:

```text
both necessary selections exist
cast is now confirmable through △
```

That is good.
It just needs to become uniformly consumed.

### 7.4 What does deselection mean?

Because clear actions now exist,
we need clean semantics for:

- clear everything
- clear only committed side
- clear only armed side

Without that, clients will implement inconsistent local escape behavior.

---

## 8. Test Requirements For The Repair

The repair is not complete unless these are green.

### Headless / batch

- `lua cli.lua bench smoke 80 1`
- `lua cli.lua autoplay 7 24`
- `lua cli.lua headless 7 24`

### Manual CLI

From the TUI:

- start from manifest first
- start from hand first
- clear and reselect
- reach `await_ready`
- confirm cast with empty input / advance

### Invariant

No phase should allow side-selection mutation that the interaction protocol does not advertise.

This is the most important regression guard.

---

## 9. Recommended Implementation Attitude

Do not patch this as UI glue.

Do not “just make the client work”.

The only repair worth doing is:

```text
make hand-first truth explicit in the interaction protocol
then let clients consume it
```

That is the whole point of the earlier great migration.

If this branch is repaired locally only in clients,
the architecture regresses.

---

## 10. Final Reading

This branch should be read as:

```text
strong design move
incomplete protocol migration
worth repairing
not worth rolling back blindly
```

The right next move is not to abandon hand-first.

The right next move is to finish making it machine-truth.
