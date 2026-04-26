# CONNECT

Symbol:

```text
☰
```

Статус:

```text
canonical operator law
current hand-refill operator
```

## 1. Core identity

В текущей новой ветке `☰`
рассматривается уже не как segment compiler,
а как основной оператор подпитки руки.

Short formula:

```text
☰ = perform 2 draw procedures
```

## 2. Current playtest law

If `☰` is the chosen operator effect,
player performs:

```text
2 draw procedures
```

Read those procedures through:

- [../DRAW_PROCEDURE_LAW.md](../DRAW_PROCEDURE_LAW.md)

## 3. Why this fits

`☰` now becomes the dedicated operator
for hand continuation.

This is useful because:

- every played card already costs `hand -1`
- not every operator should restore hand
- draw should live on a specific operator,
  not as a background rule of every move

## 4. Trump consequence

Because draw already reveals first,
`☰` naturally carries trump risk.

That means:

- `☰` does not guarantee 2 cards in hand
- it guarantees 2 draw procedures
- any of those may be consumed by trump-event

## 5. Restrictions

- `☰` should not secretly bypass draw law
- `☰` does not mean “take 2 cards ignoring trump”
- `☰` is hand refill, not generic topology override

## 6. Legacy relation

Older assembly / segment-compiler readings of `☰`
should now be treated as legacy branch material
unless later the game explicitly returns to that idea.

## 7. Open questions

- whether `☰☰` should stay exactly `draw 2`
  or later become stronger
- whether some pair-laws should modify one of the two draw procedures
- whether later hand-cap pressure needs extra constraint on repeated `☰`

## 8. Short formula

```text
☰ CONNECT = perform 2 draw procedures
```
