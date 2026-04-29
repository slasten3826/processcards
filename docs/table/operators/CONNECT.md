# CONNECT

Symbol:

```text
☰
```

Статус:

```text
canonical operator law
current hand-refill operator
aligned with play-zone execution shell
```

## 1. Core identity

В текущей новой ветке `☰`
рассматривается уже не как segment compiler,
а как основной оператор подпитки руки.

Short formula:

```text
☰ = perform 2 draw procedures
```

## 2. Execution position

`☰` no longer resolves as abstract text detached from the played card.

Current runtime shell is:

```text
hand -> play
pending operator choice
choose ☰
resolve ☰ while the card remains in play
then play -> grave
```

So `☰` is now a real `play-zone` payload,
not a pre-play or post-grave effect.

## 3. Current runtime law

If `☰` is the chosen operator effect,
player performs:

```text
2 draw procedures
```

Read those procedures through:

- [../DRAW_PROCEDURE_LAW.md](../DRAW_PROCEDURE_LAW.md)

Each draw procedure is still separate.

That means:

1. draw procedure #1 resolves fully
2. draw procedure #2 resolves fully

`☰` does not collapse them into one big hand gain.

## 4. Why this fits

`☰` now becomes the dedicated operator
for hand continuation.

This is useful because:

- every played card already costs `hand -1`
- not every operator should restore hand
- draw should live on a specific operator,
  not as a background rule of every move

## 5. Trump consequence

Because draw already reveals first,
`☰` naturally carries trump risk.

That means:

- `☰` does not guarantee 2 cards in hand
- it guarantees 2 draw procedures
- any of those may be consumed by trump-event

If a draw under `☰` reveals a trump:

- that trump enters `trump flow`
- that one draw procedure burns
- the remaining draw procedure, if any, still continues

But trump-flow continuation does **not** outrank the current played card.

So:

- trumps may enter flow during `☰`
- `☰` still finishes first
- the played card still leaves `play` first
- only then may `△` continue the trump flow

This follows:

- [../../crystall/TURN_EFFECT_PRIORITY_SLICE.md](../../crystall/TURN_EFFECT_PRIORITY_SLICE.md)
- [../../crystall/PENDING_OPERATOR_CHOICE_SLICE.md](../../crystall/PENDING_OPERATOR_CHOICE_SLICE.md)

## 6. Physical / runtime execution law

`☰` must remain visible as actual machine action.

That means:

- draw cards really come from `deck`
- revealed trump really enters `trump flow`
- hand size changes are physically observable
- the played card remains in `play` until `☰` fully finishes

## 7. Restrictions

- `☰` should not secretly bypass draw law
- `☰` does not mean “take 2 cards ignoring trump”
- `☰` is hand refill, not generic topology override
- `☰` does not auto-resolve trump flow mid-effect

## 8. Legacy relation

Older assembly / segment-compiler readings of `☰`
should now be treated as legacy branch material
unless later the game explicitly returns to that idea.

## 9. Open questions

- whether `☰☰` should stay exactly `draw 2`
  or later become stronger
- whether some pair-laws should modify one of the two draw procedures
- whether later hand-cap pressure needs extra constraint on repeated `☰`

## 10. Short formula

```text
☰ CONNECT = while the played card remains in play,
perform 2 draw procedures;
then let the played card leave play
```
