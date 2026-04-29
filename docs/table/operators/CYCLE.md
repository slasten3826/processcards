# CYCLE

Symbol:

```text
☲
```

Статус:

```text
canonical operator law
current hand-filter operator
aligned with play-zone execution shell
```

## 1. Core identity

В текущей новой ветке `☲`
читается как основной оператор hand turnover,
а не как draw-growth operator.

Short formula:

```text
☲ = perform 1 draw procedure, then discard 1 from hand
```

## 2. Execution position

`☲` now resolves through the same real machine shell
as the other active operators.

Current runtime shell is:

```text
hand -> play
pending operator choice
choose ☲
resolve ☲ while the card remains in play
then play -> grave
```

So `☲` is a true `play-zone` payload,
not abstract text detached from the played card.

## 3. Current runtime law

If `☲` is the chosen operator effect,
player performs:

1. `1` draw procedure
2. then discards `1` card from hand

Read the draw through:

- [../DRAW_PROCEDURE_LAW.md](../DRAW_PROCEDURE_LAW.md)

So current `☲` is:

```text
draw first
discard second
```

not:

```text
discard first
draw later
```

## 4. Why draw first

`☲` should feel like turnover and filtering,
not like punishment with late compensation.

This order gives:

- real post-draw choice
- hand smoothing
- no pure hand growth

So `☲` stays distinct from `☰`.

Current role split is:

```text
☰ grows hand
☲ refreshes hand
☳ reclaims board material into hand
```

## 5. Trump consequence

Because `☲` still uses real draw procedure,
it also carries real trump risk.

That means:

- `☲` does not guarantee one extra card
- it guarantees one draw procedure
- if that draw reveals a trump,
  the draw burns into `trump flow`
- discard still happens afterwards

So current order remains:

1. draw procedure resolves
2. any revealed trump enters `trump flow`
3. `☲` still completes its discard
4. only later may `△` continue `trump flow`

This follows:

- [../OPERATOR_PHASE_LAW.md](../OPERATOR_PHASE_LAW.md)
- [../TRUMP_FLOW_LAW.md](../TRUMP_FLOW_LAW.md)

## 6. Physical / runtime execution law

`☲` must remain physically legible.

That means:

- the draw really comes from `deck`
- revealed trump really diverts into `trump flow`
- one real card is then discarded from `hand`
- the played card remains in `play` until `☲` fully closes

No hidden replacement or silent reshuffle
should stand in for the cycle.

## 7. Restrictions

- `☲` should not become free tutor
- `☲` should not secretly skip discard
- discard destination must stay explicit
- `☲` is refresh/filter, not pure refill

## 8. Pair law directions

- `☲☳` — reclaim after turnover
- `☲☴` — know before release
- `☲☵` — cycle through encoded ordering
- `☲☶` — cycle while loosening one internal constraint
- `☲☱` — runtime-form churn

These are still branch directions,
not current runtime payload laws.

## 9. Open questions

- whether weak `☲` should stay exactly `draw 1 then discard 1`
- whether later pair-laws should constrain discard target class
- whether discard should later allow grave/board interaction modifiers

## 10. Short formula

```text
☲ CYCLE = while the played card remains in play,
perform 1 draw procedure,
then discard 1 from hand;
then let the played card leave play
```
