[⊞ ◈] [☴ ☱ △]

# TRUMP RESOLUTION ORDER

## 0. Status

Working systemic rules document.

This file defines **how trump-caused effects are ordered**.
It does not define individual trump payloads.

---

## 1. Core Claim

`ProcessCards` does **not** use a Magic-like stack.

It does not resolve last-in first-out.

It resolves caused events in the order they are produced.

Short formula:

```text
ordered resolution, not stack resolution
```

---

## 2. Board Integrity First

If a trump effect vacates a board slot,
the machine should restore the structural slot first whenever the current rules allow it.

That means:

- refill the emptied latent slot
- or promote hidden to visible
- or restore the required local board shape

before the newly exposed trump-event begins resolving.

Short formula:

```text
repair board first
resolve anomaly second
```

---

## 3. Holy Place Law

Working phrase:

```text
holy place does not stay empty
```

Machine reading:

```text
vacated board slots refill before trump resolution
```

This applies especially to:

- latent slots
- manifest row positions
- target slots with explicit refill law

This keeps the machine structurally whole before event escalation continues.

---

## 4. Resolution Queue

If a trump effect causes another trump to become active,
that newly activated trump enters a resolution queue.

The queue resolves in **arrival order**.

Not:

```text
last in, first out
```

But:

```text
first caused, first resolved
```

Short formula:

```text
queue, not stack
```

---

## 5. In-Flight Trumps

While a trump chain is still resolving,
resolved trumps are not yet parked in `trump zone`.

They remain:

```text
in-flight
```

This matters because:

- `trump zone` should not release mid-chain
- chain exceptions such as `HALT` need access to the full active anomaly contour
- ecology handling belongs to chain close, not mid-chain

Short formula:

```text
resolve now
park later
```

---

## 6. Chain Close Handling

When an ordinary trump chain closes:

1. resolved in-flight trumps are transferred into `trump zone` in resolution order
2. if this produces a third parked trump, resolve the ordinary chamber release

When a halted chain closes:

1. all non-`HALT` trumps from that halted chain are shuffled into deck
2. `HALT` itself enters ordinary trump ecology

Short formula:

```text
ordinary close -> trump zone
halted close -> deck flush + HALT to trump zone
```

Canonical compression:

```text
HALTed chain parks nothing except HALT itself
```

---

## 7. Why This Matters

This keeps `ProcessCards` readable.

The game should not become counterspell jurisprudence.

It should behave like a process machine:

1. a structural disturbance happens
2. the local board shape is restored
3. newly active anomalies enter the queue
4. the queue resolves in order
5. the closed chain enters ecology handling

Short formula:

```text
board repair -> event queue -> ordered resolution -> chain close handling
```

---

## 8. Example Reading

`EJECT` targets a manifest card whose hidden counterpart causes exposure of a trump.

Correct order:

1. `EJECT` vacates or shifts the slot
2. hidden/latent structure is restored as required
3. the exposed trump becomes active
4. that trump resolves after the local board is whole

If that trump causes another trump,
the second trump enters the queue after the first.

If `HALT` is later activated in that same chain,
the current resolving item may finish,
but the chain closes through halted-chain handling instead of ordinary parking.

---

## 9. Minimal Canonical Summary

```text
ProcessCards uses ordered trump resolution, not stack resolution.
If a trump effect creates a board vacancy, restore the slot first.
If a trump effect activates another trump, enqueue it.
Resolve trumps in the order they were caused.
Resolved trumps remain in-flight until chain close.
Ordinary closed chains enter trump zone.
Halted chains flush non-HALT trumps into deck, while HALT itself follows ordinary ecology.
HALTed chain parks nothing except HALT itself.
```

---

machines only. not for humans.
