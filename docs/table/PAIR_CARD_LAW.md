# PAIR CARD LAW

## Purpose

This law defines the selection model
for any gameplay step
that is resolved through a **pair of cards**.

The primary object here is not the operator.
The primary object is the pair itself.

The goal is to avoid false asymmetry
when the machine is really asking the player
to form a valid pair of cards.

## Core principle

If the machine is asking for two linked cards,
the player should not always be forced
to start from a single predetermined side.

Instead:

```text
choose first anchor
then see legal counterparts
then choose counterpart
then confirm with △
```

## What this law is for

This law applies to card-selection situations of this class:

- swap relations
- pair formation
- two-surface exchange
- any two-card step that is not inherently one-way

## What this law is not for

This law does **not** apply to ordinary single-card targeting.

Examples that stay single-card:

- `OBSERVE`
- `MANIFEST`
- `CHOOSE`

These still use:

```text
arm operator
-> arm target
-> △ confirm
```

## Pair-card selection rhythm

The canonical pair-card rhythm is:

```text
arm operator
-> choose first card
-> machine reveals legal counterpart cards
-> choose second card
-> △ confirm the pair
```

Important:

- first card is not yet execution
- second card is not yet execution
- the pair remains in pre-manifest state
  until `△` confirms it

So the law stays consistent with:

- [ARMED_LAW.md](./ARMED_LAW.md)
- [ADVANCE_BUTTON_LAW.md](./ADVANCE_BUTTON_LAW.md)

## First anchor

The first chosen card is the **anchor**.

It defines which legal counterparts may be shown next.

That means:

- before first anchor:
  - the machine may expose multiple legal surfaces
- after first anchor:
  - the machine narrows legality to cards
    that form a valid pair with that anchor

## Symmetry

If the pair relation is truly symmetric,
the player may begin from either side of the pair.

Meaning:

```text
board first -> hand second
```

or:

```text
hand first -> board second
```

Both are legal if the pair-card canon
allows both sides equally.

This law exists to support that symmetry.

## Manifestation consequence

The client should show:

### before first anchor

- all legal first-card surfaces

### after first anchor

- the armed anchor card
- only legal counterpart cards

The armed anchor and the legal counterpart field
must not be drawn with the same visual language.

Recommended split:

- armed anchor = glow / fixed selected state
- legal counterparts = train / legality frame

## Machine consequence

The core should be able to represent:

- no pair card armed
- first anchor armed
- full pair armed

This is different from single-target selection.

The machine should not fake this
as a one-way source-then-target step
if the card-pair relation is genuinely symmetric.

## Short formula

```text
pair-card selection chooses an anchor first,
not a mandatory source side
```
