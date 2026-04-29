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
active flow of in-flight trump events
```

Коротко:

```text
trump flow holds trumps that are currently resolving
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
2. resolved trump history / pressure residue

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

## 6. Queue reading

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

## 7. Relationship to trump zone

Разделение такое:

- [TRUMP_FLOW_LAW.md](./TRUMP_FLOW_LAW.md) = active trump flow
- [TRUMP_ZONE_LAW.md](./TRUMP_ZONE_LAW.md) = resolved trump residue

Коротко:

```text
chain = now
zone = after
```

## 8. Target override

`targets` по-прежнему переопределяют общий вход в `trump flow`.

Если козырь становится `revealed` в `targets`,
то:

- он не входит в `trump flow`
- он остаётся в `targets`
- он продолжает жить как compiler trump

См.:

- [TARGET_ZONE_LAW.md](./TARGET_ZONE_LAW.md)

## 9. Board closure gate

Даже если trump уже вошёл в `trump flow`,
он не должен начинать resolution,
пока board не закрыт полностью.

См.:

- [BOARD_CLOSURE_LAW.md](./BOARD_CLOSURE_LAW.md)

## 10. Chain close consequence

While chain is still active:

- resolved trumps remain in-flight in `trump flow`
- they are not yet parked into `trump zone`

When chain closes:

- ordinary close parks them into `trump zone`
- halted close flushes all non-`HALT` trumps into deck
- only `HALT` itself may then enter ordinary ecology

## 11. What this law does not decide yet

Этот документ пока не решает:

- whether later some trumps may inject new trumps into the active chain mid-resolution
- exact presentation law for active trump animation

Он решает только:

```text
active trumps need their own visible flow zone
separate from resolved trump residue
```

## 12. Short formula

```text
trump flow = visible active flow of resolving trumps
revealed trump enters trump flow
trump resolution waits for full board closure
resolved trumps remain in-flight until chain close
ordinary close parks them into trump zone
halted close parks nothing except HALT itself
trump zone = visible residue of already resolved trumps
targets override normal chain entry
```
