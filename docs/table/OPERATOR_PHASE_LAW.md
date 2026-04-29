# Operator Phase Law

Status:

```text
canonical table law
current played-operator execution branch
```

## 1. Core claim

`Operator phase` is now a real machine phase.

It is not just flavor text attached to the played card.

Short formula:

```text
operator phase = the played hand-card resolves one chosen operator while it remains in play
```

## 2. Why this is now a phase

Current machine already requires all of the following:

1. the hand-card reaches `play`
2. the world finishes first repair
3. one of the two operators is explicitly chosen
4. that operator resolves before the played card is spent
5. trump flow waits until this closes

So operator execution is no longer optional narration.

It is phase structure.

## 3. Entry condition

Operator phase begins only after:

1. commit has happened
2. the committed manifest card has left the world
3. first repair has closed the opened board obligation

Then:

```text
the played hand-card remains in play
and the machine enters operator phase
```

## 4. Current operator-phase structure

Current canonical shell is:

```text
hand -> play
repair phase
operator phase
play -> grave
trump flow continuation
```

Inside operator phase:

1. the player chooses exactly one of the played card's two operators
2. that chosen operator resolves from `play`
3. if the operator reopens the board,
   repair phase runs again
4. only after operator closure may the played card leave `play`

## 5. Relationship to repair

Operator phase does not replace repair.

It sits between repair and discharge.

Current reading is:

```text
repair first
operator second
repair again if reopened
```

This is especially important for operators like `CHOOSE`,
which can create a second manifest obligation.

## 6. Relationship to trump flow

Trump flow may receive cards during earlier steps of the turn
or during the operator itself.

But trump flow may not continue while operator phase is still open.

So current priority is:

```text
board closure
operator phase closure
trump flow continuation
```

## 7. Current scope

At the current stage,
operator phase already governs:

- pending operator choice
- `CONNECT`
- `CHOOSE`
- future operator payloads

It should also govern later operators
unless a future law explicitly overrides this shell.

## 8. LOVE / runtime consequence

The played hand-card must remain visibly in `play`
while operator phase is active.

The player must be able to see:

- which card is currently resolving
- which operator is being chosen
- whether the operator opened a second repair phase

Operator phase should therefore be legible in presentation,
not hidden behind instant discharge.

## 9. Short formula

```text
after first repair,
the machine enters operator phase.
one operator resolves from play.
only after operator closure may the played card leave play,
and only after that may trump flow continue.
```
