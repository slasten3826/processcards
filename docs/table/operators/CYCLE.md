# CYCLE

Symbol:

```text
☲
```

Статус:

```text
canonical operator law
current hand-filter operator
```

## 1. Core identity

`☲` now reads as the main hand-filter operator.

Short formula:

```text
draw first, then discard
```

## 2. What it is not

`☲` is not:

- pure draw
- pure discard
- reveal
- removal from field by default

## 3. Current playtest law

If `☲` is the chosen operator effect,
player:

1. performs `1` draw procedure
2. then discards `1` card from hand

Read the draw through:

- [../DRAW_PROCEDURE_LAW.md](../DRAW_PROCEDURE_LAW.md)

This means:

- if a minor is drawn, hand briefly expands before discard choice
- if a trump is drawn, that draw procedure burns into trump-event,
  and discard still happens afterwards

## 4. Why draw first

`☲` should feel like turnover and filtering,
not like punishment with late compensation.

So:

```text
draw first
discard second
```

gives:

- real choice
- hand smoothing
- no pure hand growth

This keeps `☲` distinct from `☰`.

## 5. Pair law directions

- `☲☳` — choose what to keep or what to release
- `☲☴` — observe before cycle choice
- `☲☵` — cycle through encoded ordering
- `☲☶` — cycle while ignoring one native cycle restriction
- `☲☱` — install cycle as runtime-form churn

## 6. Physical execution law

Cycle must be executable with physical cards.

That means:

- actual draw from deck
- actual discard to grave
- no hidden engine-side replacement without visible card movement

## 7. Restrictions

- cycle should not become free tutor
- discard destination must stay explicit
- cycle must preserve bounded information access

## 8. Open questions

- whether weak `☲` is always exactly `draw 1 then discard 1`
- whether later some pair may modify the discard class
- exact runtime-form cadence for `☱☲`

## 9. Short formula

```text
☲ CYCLE = perform 1 draw procedure, then discard 1 from hand
```
