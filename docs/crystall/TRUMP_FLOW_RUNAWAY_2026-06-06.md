[⊞ ◈] [⚠ trump flow runaway]

# Trump Flow Runaway

## 0. Status

Observed engineering defect in the headless trump resolution layer.

Date:

```text
2026-06-06
```

This is:

- not a balance note
- not a new law
- not a finished fix report

This is a crystall debt note. It records a dangerous runtime shape that must stay visible until the root cause is fully closed.

---

## 1. Symptom

During long headless/autoplay checks, the game can enter an abnormal trump-chain state where:

```text
deck approaches 0
trump_flow remains non-empty
board repair cannot finish
bench runtime grows sharply
Lua memory/stack usage can spike
```

The most visible bad state was:

```text
board_closed = false
deck = 0
grave = 0
hand ~= full minor population
trump_flow ~= empty
pending_trump = nil
```

That state is not a normal deck-exhaustion event.

It means the ecology pipeline has lost closure:

```text
trump_flow still contains work
but the public pending trump phase is not armed
and the board is already open
```

---

## 2. Confirmed Risk

A first repair attempt changed `trump_flow` resolution from shallow pending-trump stepping to deeper internal draining.

That exposed a second defect:

```text
resolve_trump_card
-> resolve_all_pending_trumps
-> resolve_trump_card
-> resolve_all_pending_trumps
-> ...
```

The stack overflow trace passed through:

```text
src/core/trump.lua
resolve_trump_card
resolve_all_pending_trumps
resolve_trump_zone_entry
```

So the dangerous class is now known:

```text
re-entrant trump_flow draining
```

Lua did not "randomly" eat memory. The engine allowed a recursive resolution shape that could keep allocating stack frames, transition events, logs, and zone mutations.

---

## 3. Current Partial Fix

`src/core/trump.lua` now has a re-entry guard:

```text
state.trump_flow_draining
```

And `UNVEIL` / `PURGE` no longer start a full nested `resolve_all_pending_trumps` from inside their own `resolve_trump_card` body.

This removes the direct recursion shape.

This is not yet treated as a complete fix, because long bench runs can still become expensive after parties stop dying early.

Update:

```text
2026-06-06
```

Additional guardrails now exist:

```text
max_trump_chain_steps
max_repair_attempts
max_transition_events_per_action
```

If `max_trump_chain_steps` or `max_repair_attempts` trips, the transition summary returns:

```text
error = trump_flow_runaway
```

If the transition event cap trips, the transition summary returns:

```text
error = transition_event_limit
```

The diagnostic payload is stored in:

```text
summary.trump_runaway
state.trump_runaway
summary.transition_event_overflow
```

There is a focused scenario:

```text
trump_flow_runaway_guard
```

The scenario forces `max_trump_chain_steps = 0` and verifies that the flow head and `pending_trump` are preserved when the guard trips.

---

## 4. Suspected Root Area

The root area is the boundary between:

```text
trump_flow
pending_trump
trump_zone
board repair
```

The suspicious rule conflict:

```text
refresh_pending_trump / resolve_pending_trump are board_closed-gated
```

But several trump effects can open board holes and enqueue more trumps before closure has been restored.

If the engine reaches:

```text
board_closed = false
trump_flow > 0
pending_trump = nil
```

then public interaction can no longer naturally continue the trump chain, while invariants also reject the board.

That is the core smell.

---

## 5. Working Hypothesis

Trump resolution needs one authoritative chain runner.

That runner must own:

1. taking cards from `trump_flow`
2. resolving each trump exactly once
3. allowing local board repair after each effect
4. flushing `trump_zone` overflow
5. stopping runaway chains with a hard diagnostic limit

Individual trump effects should enqueue or reveal trumps, but should not recursively decide to drain the entire global flow unless they are explicitly defined as special chain runners.

At the moment, the implementation still has too many local places that can:

```text
enter_trump_flow
refresh_pending_trump
resolve_pending_trump
repair board
```

This makes resolution order hard to reason about.

Additional observation from short guarded probes:

```text
trump_flow > 0
pending_trump = nil
phase = await_target
board_closed = true
```

This can occur while an operator target choice is still in progress.

That shape is not immediately treated as illegal, because the target phase may legitimately be controlling the current action. But it means the scheduler law is still under-specified:

```text
when operator target resolution and queued trump flow both exist,
which layer owns the next continuation?
```

This should be answered by the chain runner refactor, not by scattered local `refresh_pending_trump` calls.

---

## 6. Required Guardrails

Before any large autoplay/bench run, runtime guardrails must be active:

```text
max_trump_chain_steps
max_transition_events_per_action
max_repair_attempts_per_action
```

If a guard trips, the engine should return a controlled error:

```text
trump_flow_runaway
```

The error must include:

```text
seed
step
last action
deck / hand / grave sizes
trump_flow contents
trump_zone contents
pending_trump
board_closed
recent transition events
```

No future test run should be allowed to freeze the machine just to prove the chain is broken.

Implementation status:

```text
DONE: max_trump_chain_steps
DONE: max_repair_attempts
DONE: max_transition_events_per_action
DONE: controlled transition summary error
TODO: richer recent-transition tail in runner failure output
TODO: single authoritative chain runner
TODO: formal law for target-phase vs trump-flow continuation
```

---

## 7. Safe Test Policy

Until this debt is closed:

```text
no large bench without timeout
no 1000-step multi-seed survival bench without internal guards
prefer single-seed 50-200 step probes
prefer named scenarios over broad autoplay
```

Example safe shell shape:

```text
timeout 10 lua cli.lua survival <seed> 200
timeout 10 lua cli.lua headless <seed> 200
timeout 10 lua cli.lua bench smoke 120 1
```

---

## 8. Closure Criteria

This debt is closed only when:

1. `trump_flow` has a single authoritative resolution path.
2. No trump effect can recursively re-enter global flow draining by accident.
3. `board_closed=false + trump_flow>0 + pending_trump=nil` is either impossible or explicitly legal with a continuation.
4. Runaway guardrails exist and return diagnostic state instead of freezing.
5. Focused scenarios cover `UNVEIL`, `PURGE`, `ERROR`, `SHUFFLE`, `RECAST`, `REPEAT`, `HALT` chain interactions.
6. A bounded multi-seed survival run completes under a fixed timeout.

---

## 9. Current Reading

The game ecology is doing what it should conceptually do:

```text
trumps can cause ecological cascades
deck / grave / hand can be massively rearranged
trump_zone overflow should recycle pressure back into deck
```

But the implementation currently mixes:

```text
game law
chain scheduling
board repair
public interaction phase control
```

That is the technical debt.

The next engineering step is not another trump. The next step is to harden the trump-chain runner.
