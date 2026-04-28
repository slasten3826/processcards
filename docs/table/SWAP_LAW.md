# Swap Law

Статус:

```text
canonical table law
adopted individual trump event
```

Legacy breadcrumb:

```text
VIII Justice / XI Justice
```

Core edge:

```text
☴ -> ☳
OBSERVE -> CHOOSE
```

## 1. Core identity

`SWAP` is a public trump rearrangement event.

It does not create new trump-state.
It does not reveal hidden trump-state.
It acts only on trumps that are already shown on the table.

Short formula:

```text
swap 2 trumps
```

## 2. Reading

`☴ OBSERVE` here is not private inspection.

It means the trump works only on what is already shown.
The machine can only rearrange what is legally visible.

`☳ CHOOSE` here is not free creation of new fate.

It means the shown trump-state may be reassigned by swap.
Choice is bounded by what already exists in the open field.

So this trump reads as:

```text
shown trump positions are not fixed
```

This is not:

```text
creation
```

And not:

```text
hidden intervention
```

It is:

```text
public redistribution of already-visible fate
```

## 3. Core law

When `SWAP` becomes known:

- if there are fewer than `2` shown table-trumps, `SWAP` has no effect
- if there are exactly `2` shown table-trumps, they are swapped automatically
- if there are `3` or more shown table-trumps, player chooses `2` of them, then swaps them

Short formula:

```text
0-1 trumps = no effect
2 trumps = forced swap
3+ trumps = choose 2, then swap
```

## 4. What counts as a legal trump for SWAP

For the purposes of this trump,
the game only looks at actual shown table-trumps.

In current machine reality,
this means trumps that may appear in:

- `targets`
- `trump zone`

This trump does not need extra reveal wording.
If a trump is a legal table-trump for `SWAP`,
it is already shown.

Short formula:

```text
SWAP acts on table-trumps
not on hidden trump potential
```

## 5. Zone consequence

When two trumps are swapped:

- each card moves into the other's exact position
- each destination zone's own law continues to apply after the swap
- `SWAP` itself does not add extra reveal, trigger, or replacement text

Examples:

- a trump moved into `targets` now exists there under [TARGET_ZONE_LAW.md](./TARGET_ZONE_LAW.md)
- a trump moved into `trump zone` now exists there under [TRUMP_ZONE_LAW.md](./TRUMP_ZONE_LAW.md)

## 6. Why this works

`SWAP` does not create new fate.

It rearranges already shown fate.

That makes it:

- public
- readable
- highly contextual
- stronger when multiple trumps are already active on the table
- scales with trump saturation

It also keeps the text short
while letting table-state determine
whether the move is forced or chosen.

## 7. Relation to trump ecology

`SWAP` does not invent a separate ecology.

It uses:

- ordinary table-trump visibility rules
- ordinary zone-law inheritance after movement
- ordinary trump-zone law for any trump parked there
- ordinary target-zone law for any trump installed there

Its specificity is not in ecology.
Its specificity is in redistributing positions
without triggering new resolution.

## 8. Restrictions

`SWAP` does not:

- touch hidden cards
- touch known-but-not-shown cards
- create new trump entries by itself
- affect minors
- rewrite multiple zones beyond the one-for-one swap
- trigger additional resolution on swapped trumps

## 9. Design character

`SWAP` should feel:

- mechanical
- blunt
- public
- law-like
- less mystical than `FOOL`
- less surgical than `EJECT`
- less destructive than `RESET`
- more like a machine instruction than a ceremony
- more like redistribution than creation

This is intentional.

## 10. Minimal canonical text

```text
Swap 2 trumps.
If only 2 trumps are on the table, swap them automatically.
If 3 or more trumps are on the table, choose 2, then swap them.
```
