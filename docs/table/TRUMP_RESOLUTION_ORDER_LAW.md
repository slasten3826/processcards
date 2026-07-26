# Trump Resolution Order Law

Статус:

```text
canonical table law
current trump ecology order
```

Этот документ фиксирует
как упорядочиваются trump-caused effects.

Он не определяет payload каждого отдельного козыря.

## 1. Core claim

`ProcessCards` не использует Magic-like stack.

Trump-caused events не резолвятся по `last in, first out`.

Они резолвятся:

```text
in the order they are produced
```

Коротко:

```text
ordered resolution, not stack resolution
```

## 2. Board integrity first

Если trump effect создаёт пустоту на доске,
машина должна сначала вернуть structural integrity,
если текущие законы поверхности это разрешают.

That means:

- refill the emptied latent slot
- or promote hidden to visible
- or restore the required local board shape

before the newly exposed trump-event begins resolving.

Коротко:

```text
repair board first
resolve anomaly second
```

## 3. Holy place law

Working phrase:

```text
holy place does not stay empty
```

Machine reading:

```text
vacated board slots refill before trump resolution
```

Это особенно относится к:

- `latent` slots
- `manifest` positions
- `target` slots with explicit refill law

## 4. Resolution queue

Если trump effect causes another trump to become active,
that newly activated trump enters a resolution queue.

Queue resolves in:

```text
arrival order
```

Not:

```text
last in, first out
```

But:

```text
first caused, first resolved
```

Queue ownership belongs to the active trump-flow runner.

Individual trump effects may produce trumps,
but they do not independently decide when the whole chain closes.

## 5. In-flight trumps

Пока trump flow ещё резолвится,
resolved trumps не паркуются в `trump zone`.

Они остаются:

```text
in-flight
```

Это нужно потому что:

- `trump zone` should not release mid-chain
- chain exceptions such as `HALT` need access to the full active anomaly contour
- ecology handling belongs to chain close, not mid-chain

Коротко:

```text
resolve now
park later
```

Operational reading:

```text
queue -> current -> in_flight -> chain close -> trump zone
```

No individual trump payload may call the trump-zone parking procedure directly
while its parent chain is still active.

## 6. Ordinary chain close

When an ordinary trump flow closes:

1. all resolved `in_flight` trumps are transferred into `trump zone` in resolution order
2. if this produces a third parked trump, resolve the ordinary chamber release
3. chamber release happens only during this close procedure, not mid-chain

Коротко:

```text
ordinary close -> trump zone
third parked trump -> chamber release
```

## 7. Halted chain close

`HALT` creates a special chain ending.

If a chain becomes a:

```text
halted chain
```

then ordinary trump-zone transfer is bypassed.

In a halted chain:

- the current resolving item may finish
- no further trump resolution may begin
- trumps revealed after the HALT boundary become halted trumps
- halted trumps are shuffled into deck
- `HALT` itself enters ordinary trump ecology after the halted chain closes
- the already-living current resolver follows its own trump law

Canonical compression:

```text
HALT preserves current resolver
HALT denies later trump entry
halted unresolved trumps return to deck
HALT itself follows ordinary ecology
```

## 8. Why this matters

This keeps `ProcessCards` readable.

The game should not become counterspell jurisprudence.

It should behave like a process machine:

1. a structural disturbance happens
2. the local board shape is restored
3. newly active anomalies enter the queue
4. the queue resolves in order
5. the closed chain enters ecology handling

Коротко:

```text
board repair -> event queue -> ordered resolution -> chain close handling
```

## 9. Relationship to other trump laws

Read together with:

- [TRUMP_FLOW_LAW.md](./TRUMP_FLOW_LAW.md)
- [TRUMP_ZONE_LAW.md](./TRUMP_ZONE_LAW.md)
- [TRUMP_EVENT_MINIMAL_LAW.md](./TRUMP_EVENT_MINIMAL_LAW.md)

Division:

- `TRUMP_EVENT_MINIMAL_LAW` = when trump event starts
- `TRUMP_FLOW_LAW` = where active trumps live
- `TRUMP_RESOLUTION_ORDER_LAW` = in what order active trumps resolve and close
- `TRUMP_ZONE_LAW` = where ordinary closed-chain residue parks

## 10. Short formula

```text
ProcessCards uses ordered trump resolution, not stack resolution.
If a trump effect creates a board vacancy, restore the slot first.
If a trump effect activates another trump, enqueue it.
Resolve trumps in the order they were caused.
Resolved trumps remain in-flight until chain close.
Ordinary closed chains enter trump zone.
Halted chains preserve the current resolver, deny later trump entry, and flush halted unresolved trumps into deck.
HALT itself follows ordinary ecology.
Trump-zone overflow is a chain-close event, never a mid-chain event.
```
