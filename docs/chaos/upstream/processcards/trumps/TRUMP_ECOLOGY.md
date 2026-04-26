[⊞ ◈] [☴ ☵ ☲ ☶]

# Trump ecology

## 0. Статус

Design note for `ProcessCards` trumps.

Это не финальный rulesheet.
Это не set file.
Это не balance-locked document.

Этот документ фиксирует текущую ecology козырей после обсуждения.

## 1. Core Law

In `ProcessCards`:

```text
minor = state
trump = event
```

Козырь не должен вести себя как обычная стабильная карта.

Он должен ощущаться как:

- event
- disturbance
- topology pulse
- delayed escalation
- process anomaly

Козырь не должен становиться:

- creature
- buff
- permanent
- passive hidden resource
- обычной spent card в grave

## 2. Trump Zone

Resolved trumps do not enter `trump zone` immediately while a chain is still resolving.

During active chain resolution,
resolved trumps remain:

```text
in-flight
```

Only after an ordinary chain closes,
its in-flight trumps are transferred into `trump zone`.

Short formula:

```text
in-flight first
trump zone on ordinary chain close
```

This zone is not:

- grave
- battlefield
- buff row
- active state
- resource pool

Cards in `trump zone` do nothing except count as resolved trumps.

Short reading:

```text
trump zone = event pressure chamber
```

## 3. Capacity

Current direction:

```text
trump zone capacity = 2
```

First resolved trump:

```text
disturbance
```

Second resolved trump:

```text
warning
```

Third resolved trump:

```text
release / reset
```

## 4. Ordinary Chain Close And Third Trump Reset

Ordinary direction:

```text
ordinary chain closes
-> in-flight trumps enter trump zone in resolution order
```

But if `trump zone` already contains two trumps,
the newly resolved trump does not stay there.

Instead:

```text
shuffle deck + 2 trumps in trump zone + current resolved trump into deck
empty trump zone
```

Short formula:

```text
third trump releases the chamber
```

## 5. Halted Chain Exception

`HALT` creates a special chain ending.

If a chain becomes a:

```text
halted chain
```

then ordinary trump-zone transfer is bypassed.

In a halted chain:

- the current resolving item may finish
- no further trump resolution may begin
- all non-`HALT` trumps from that halted chain are shuffled into deck
- `HALT` itself enters ordinary trump ecology after the halted chain closes

Short formula:

```text
ordinary chain -> trump zone
halted chain -> deck flush
HALT itself -> trump zone
```

Canonical compression:

```text
HALTed chain parks nothing except HALT itself
```

## 6. Why Two, Not Three

Three parked trumps is too slow.

Two parked trumps creates a clearer pressure state:

```text
1st = something happened
2nd = chamber loaded
3rd = reset pulse
```

This is more readable than waiting for a fourth event.

It also keeps trump circulation alive
without letting every single trump destroy deck order.

The in-flight rule protects that pressure geometry
from being distorted mid-chain.

## 7. Relation To ENCODE

If every trump immediately shuffled back into deck,
`☵ ENCODE` would lose too much value.

Deck-order play needs room to exist.

So trump reset must be periodic,
not automatic.

The two-trump chamber protects both:

- trump escalation
- deck-order planning

## 8. Visual Requirement

Trump zone should be visually clear.

It can be represented as:

```text
two visible trump slots
```

The third trump should feel like it releases pressure,
not like it simply enters a third slot.

## 9. Short Formula

```text
trump zone = two-event pressure chamber
```

```text
third trump resets the chamber into deck
```

```text
trumps remain in-flight until chain close
```

```text
HALT converts chain close into deck flush, except for HALT itself
```

---

machines only. not for humans.
