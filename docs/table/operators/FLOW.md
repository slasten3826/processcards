# FLOW

Symbol:

```text
▽
```

Статус:

```text
canonical operator family
```

## 1. Core identity

`▽ FLOW` is not draw.

It is not primarily value gain.
It is not generic cycling.

Canonical reading:

```text
▽ = forced continuation / movement of a concealed sequence
```

Short formula:

```text
advance hidden structure by one lawful step
```

## 2. What it is not

`▽` is not:

- draw
- generic card advantage
- hand cycling
- grave recursion
- random reshuffle
- encode / structural editing

Useful contrast:

```text
☵ rearranges structure
▽ pushes structure forward
```

## 3. Mandatory law

If a flow effect is the selected branch of the card,
it must resolve.

Player does not get to decline it
just because the continuation is inconvenient.

Short formula:

```text
selected flow must happen
```

## 4. Hidden-only law

Flow may target only hidden structures.

Current legal flow spaces:

1. hidden layer of the `ManifestChain`
2. hidden target / victory structure
3. `deck`

Flow does not target:

- hand
- grave
- open manifest cards
- runtime zone
- arbitrary open zones

## 5. Default meaning of flow

A flow action means:

```text
shift the target hidden structure forward by one step
according to that structure's native order
```

Flow is therefore lawful motion inside a hidden structure.

## 6. Native order by space

### Hidden layer of ManifestChain

The hidden layer is ordered toroidally across `5` columns.

That means:

- column 1 adjacent to 2 and 5
- column 5 adjacent to 4 and 1

Current working convention:

- one flow step = one step left around the toroidal order

### Hidden target structure

The target structure has `3` slots.

One flow step there means:

- advance hidden target state by one slot in that zone's cyclic order

### Deck

One flow step on the deck means:

```text
top card -> bottom of deck
```

This keeps deck-flow as motion, not draw.

## 7. Revealed cards are anchors

If a hidden structure contains cards that are already revealed and fixed,
those cards do not move when flow resolves.

They act as anchors.

Flow continues only through the still-hidden part of the structure.

This applies at least to:

- hidden cards in the `ManifestChain` that became revealed and fixed
- target structure slots that became revealed and fixed

## 8. Null-result legality

Some legal flow resolutions may produce little or no visible change.

This is still legal.

A mandatory flow effect does not become optional
just because the current visible result is null.

## 9. Locality and targeting

Without `☳ CHOOSE`,
flow is not a free global selector.

Default rule:

- if the card does not explicitly provide selection,
- flow resolves through its default or local binding

For weak-local behavior,
that means flow should bind to the hidden structure naturally associated
with where the card is played,
not freely choose any legal hidden flow space.

## 10. Interaction with CHOOSE

`☳` can turn local flow into explicitly targeted flow.

Working principle:

```text
☳▽ / ▽☳ strong
-> choose which legal hidden structure to flow
```

Legal chosen spaces remain only:

- hidden manifest layer
- hidden target structure
- deck

## 11. Safe-mode interaction

`☳` currently has no strong standalone payload in weak mode.

Because of that,
mixed `☳▽ / ▽☳` cards create a canonical safe-mode interaction:

- if the card is played weak,
- player may choose the `☳` side,
- which effectively means "no flow"

This is not treated as a bug.
It is part of the current character of `☳`.

## 12. Physical execution law

Flow stays cardboard-playable because:

- it acts only on real hidden structures
- those structures have visible native order
- revealed anchors visibly stay fixed
- deck flow is physical top-to-bottom motion

No invisible engine-only momentum state is required.

## 13. Open questions

- final wording for weak-local flow on every pair
- whether hidden-layer flow should always be defined as leftward or abstract forward
- whether later cards may amplify flow by more than one step
- final law for duplicate `▽▽`

## 14. Short formula

```text
▽ FLOW = mandatory hidden continuation by one lawful step
```
