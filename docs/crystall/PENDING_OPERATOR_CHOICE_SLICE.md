# Pending Operator Choice Slice

Status:

```text
current implementation slice
core-first play-zone staging
```

## Scope

This slice formalizes the new middle phase
between `hand -> play` and `play -> grave`.

The card in `play` does not discharge immediately anymore.

It now pauses for explicit operator choice.

## Core decision

Current runtime turn structure is:

```text
hand -> play
commit world-node -> grave
repair world
pending operator choice
choose one operator
play -> grave
then later trump flow may continue
```

## Why this is necessary

Because the played hand-card is not only a discharge object.

It is also the current packet of possible effects.

So the machine must now support:

```text
play zone as temporary effect-bearing state
```

not just:

```text
play zone as transit to grave
```

## Current operator behavior

At this stage:

- no actual operator effects are resolved yet
- the machine only requires that one of the two operators be chosen
- after the choice is made, the played card is allowed to leave `play`

So current operator choice is structural, not yet effectful.

## Runtime law

When a hand-card reaches `play`:

1. the world repair still completes first
2. the played card remains in `play`
3. runtime creates:

```text
pending_operator_choice
```

4. the player must choose exactly one of the card's two operators
5. only after that choice does the played card move to `grave`

## Trump interaction

`trump flow` does not advance through `△`
while there is still a pending operator choice.

So current priority is:

```text
finish the played card's operator choice first
then allow further trump-flow continuation
```

## LOVE manifestation

Current LOVE presentation uses:

- `play` as visible staging zone
- two clickable operator buttons
- each button uses the already drawn glyph shape
- no unicode glyph fallback

So the presentation already matches the machine law:

```text
the card is visibly waiting in play
until one operator is chosen
```

## CLI / machine consequence

The headless core must also preserve this phase.

That means:

- a turn may end with the card still in `play`
- a following machine step must choose one operator
- only then is the card discharged to `grave`

This is required for future operator-effect testing.

## Short formula

```text
played cards do not leave play immediately anymore.
they pause in play until one operator is explicitly chosen.
```
