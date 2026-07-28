# FLOW

```text
STATUS: LEGACY as of 2026-07-28
superseded by ../FLOW_RING_LAW.md
причина: дека и латент объединены в одно кольцо, направление одно, known стал анкером
```


Symbol:

```text
▽
```

Статус:

```text
canonical operator law
current turn-law branch
```

## 1. Core identity

`▽ FLOW` снова читается как оператор движения скрытого будущего.

Current playtest candidate:

```text
▽ = shift not-revealed cards by 1 step
```

Коротко:

```text
flow advances concealed structure
```

## 2. What it is not

`▽` is not:

- draw by default
- reveal
- removal
- choose
- runtime install

## 3. Current playtest law

If `▽` is the chosen operator effect,
the player shifts a legal not-revealed structure
by exactly `1` step.

Legal spaces:

```text
targets
latent
deck
```

Direction:

```text
left or right
```

For `deck`, the same law means:

```text
topdeck <-> bottom access through one-step rotation
```

So yes:

```text
FLOW may bring bottom-deck card to topdeck
```

as part of repeated lawful motion.

## 4. Not-revealed law

`▽` works on:

- `hidden`
- `known`

But not on:

- `revealed`

Коротко:

```text
flow moves not-revealed cards only
revealed cards stay fixed
```

## 5. Hand-economy role

`▽` is no longer the hand-refill operator.

Its role is:

```text
hidden-world manipulation
```

That means hand economy should be carried elsewhere,
not by `FLOW`.

## 6. Native order by space

### `targets`

One flow step means:

- rotate target structure by one slot
- only not-revealed target cards participate in motion

### `latent`

One flow step means:

- rotate latent row by one slot
- only not-revealed latent cards participate in motion
- revealed latent cards remain fixed

### `deck`

One flow step means:

- rotate deck by one card
- top card may move to bottom
- bottom card may move to top

Direction decides which way the deck rotates.

If topdeck is already `revealed`,
that card becomes a fixed anchor.

Then `FLOW(deck)` rotates only the still not-revealed remainder of the deck.

## 7. Revealed anchors

If a structure contains revealed cards,
those cards are anchors and do not move.

Flow continues only through the not-revealed part
of that structure.

This is especially important for:

- revealed cards in `targets`
- revealed cards in `latent`
- revealed topdeck

## 8. Legacy relation

The temporary `draw 2` idea for `▽`
should now be treated as superseded playtest thinking.

The new preferred branch is hidden-structure motion.

## 9. Open questions

- exact physical law when a structure has mixed revealed and not-revealed cards
- whether deck flow is better read as circular rotation or explicit top/bottom step
- whether `▽▽` should amplify step count or scope

## 10. Short formula

```text
▽ FLOW = shift not-revealed cards by 1 step in targets, latent, or deck
```
