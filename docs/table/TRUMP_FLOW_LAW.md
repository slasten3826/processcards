# Trump Flow Law

Статус:

```text
canonical table law
current active trump-flow branch
```

Этот документ фиксирует поведение зоны:

```text
trump flow
```

## 1. Core identity

`trump flow` — это не residue-zone
и не storage-zone.

Это:

```text
active event runner for the current trump chain
```

Коротко:

```text
trump flow owns the active chain
trump zone holds trumps that already resolved
```

## 2. Why this zone exists

Без отдельного `trump flow`
одна и та же зона вынуждена была бы значить сразу две вещи:

- active trump now being processed
- already resolved trump residue

Это запрещено.

Current machine must distinguish:

1. active trump event sequence
2. current resolving trump
3. resolved but not yet parked in-flight trumps
4. halted unresolved trumps
5. resolved trump history / pressure residue

## 3. Card class restriction

В `trump flow` могут находиться только козыри.

Minor cards не могут:

- входить в `trump flow`
- оставаться в `trump flow`

## 4. Face state

Карты в `trump flow` всегда считаются открытой информацией.

То есть:

```text
all cards in trump flow are face-up
```

## 5. Entry law

Если козырь становится `revealed`
вне zone override,
то он не должен сразу считаться residue в `trump zone`.

Сначала он входит в:

```text
trump flow
```

То есть:

1. trump becomes `revealed`
2. trump enters `trump flow`
3. trump waits there until board closure allows resolution
4. only then resolved trump may enter `trump zone`

## 6. Machine terms

The active trump chain has five machine terms:

```text
queue
current
in_flight
halted
close
```

Definitions:

```text
queue = revealed trumps waiting to begin resolution
current = the one trump whose effect is resolving now
in_flight = trumps already resolved in this chain, not yet parked
halted = trumps revealed after HALT denied entry, unresolved
close = the only procedure that may touch trump zone
```

`trump flow` is the visible/public representation of this active chain.

Implementation may store these terms however it wants,
but runtime behavior must preserve these distinctions.

Short rule:

```text
resolve_trump_card does not park into trump zone
chain close parks into trump zone
```

## 7. Queue reading

`trump flow` читается как ordered active sequence.

Current queue discipline is:

```text
first caused, first resolved
```

This is a queue, not a stack.

Коротко:

```text
ordered queue, not LIFO stack
```

Этот документ therefore жёстко фиксирует:

```text
multiple active trumps must be representable
as an explicit visible chain
```

То есть `trump flow` должен уметь выражать:

- один active trump
- несколько active trumps
- interruptible trump order

## 8. Current resolver law

Only one trump is `current` at a time.

When a trump begins resolution:

1. it leaves the waiting queue
2. it becomes `current`
3. its payload fully resolves unless a specific trump law says otherwise
4. after its payload ends, it becomes `in_flight`
5. it does not enter `trump zone` yet

If its payload reveals or produces more trumps,
those trumps enter the queue or halted set according to current flow state.

Short formula:

```text
queue -> current -> in_flight -> close
```

## 9. Relationship to trump zone

Разделение такое:

- [TRUMP_FLOW_LAW.md](./TRUMP_FLOW_LAW.md) = active trump flow
- [TRUMP_ZONE_LAW.md](./TRUMP_ZONE_LAW.md) = resolved trump residue

Коротко:

```text
chain = now
zone = after
```

The only lawful bridge from `trump flow` to `trump zone` is:

```text
chain close
```

No individual trump payload may park itself into `trump zone`
while the chain is still active.

## 10. Target override

`targets` по-прежнему переопределяют общий вход в `trump flow`.

Если козырь становится `revealed` в `targets`,
то:

- он не входит в `trump flow`
- он остаётся в `targets`
- он продолжает жить как compiler trump

См.:

- [TARGET_ZONE_LAW.md](./TARGET_ZONE_LAW.md)

## 11. Board closure gate

Даже если trump уже вошёл в `trump flow`,
он не должен начинать resolution,
пока board не закрыт полностью.

См.:

- [BOARD_CLOSURE_LAW.md](./BOARD_CLOSURE_LAW.md)

If a board-opening effect reveals more trumps during repair,
the machine must finish required repair before beginning the next queued trump.

Short formula:

```text
repair before next trump start
```

## 12. Chain close consequence

While chain is still active:

- current trump is resolving
- resolved trumps remain `in_flight`
- they are not yet parked into `trump zone`
- halted trumps are known but unresolved

When chain closes:

- ordinary close parks them into `trump zone`
- halted close applies HALT boundary law
- no later active chain cards remain in `trump flow`

## 13. Legal and broken states

Legal intermediate state:

```text
board_closed = true
trump_flow has queued cards
pending target/operator choice still owns the current action
```

This may happen while a non-trump interaction phase is still waiting for user
confirmation.

Broken state:

```text
board_closed = false
trump_flow has queued cards
no current repair/target/operator continuation owns the action
pending_trump = nil
```

This means the engine lost the continuation.

Guarded runtime should stop with diagnostic error rather than looping:

```text
trump_flow_runaway
```

## 14. What this law does not decide yet

Этот документ пока не решает:

- exact presentation law for active trump animation
- final UI representation of queue/current/in_flight/halted

Он решает только:

```text
active trump chains need one authoritative runner
separate from resolved trump residue
```

## 15. Short formula

```text
trump flow = visible active runner for one trump chain
revealed trump enters trump flow
trump resolution waits for full board closure
queue resolves first-caused first-resolved
current resolves fully, then becomes in_flight
resolved trumps remain in_flight until chain close
individual trump payloads do not park themselves into trump zone
ordinary close parks them into trump zone
halted close follows HALT boundary law
trump zone = visible residue of already resolved trumps
targets override normal chain entry
```
