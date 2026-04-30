# LOGIC

Symbol:

```text
☶
```

Статус:

```text
canonical operator law
aligned with operator-phase shell
current turn-law branch
```

## 1. Core identity

`☶` now reads as the machine's public/grave exchange operator
for revealed minor-cards.

Short formula:

```text
☶ = swap one revealed minor-card with one card from hand
```

## 2. What it is not

`☶` is not:

- draw
- reveal
- trump manipulation
- hidden-card manipulation by default

## 3. Current playtest law

If `☶` is the chosen operator effect:

1. choose one revealed minor-card in a legal public zone
2. choose one card from hand
3. swap them

This means:

- chosen revealed minor goes to `hand`
- chosen hand-card takes that card's exact place
- inserted hand-card enters that place as `revealed`

The inserted card does not separately resolve its own effect.

Current runtime shell is:

```text
hand -> play
repair phase
choose ☶
choose public/grave target
choose hand target
swap
play -> grave
then later trump flow may continue
```

## 4. Legal target class

`☶` may target only:

- `revealed` cards
- `minor` cards

Default legal public zones:

- `manifest`
- revealed `latent`
- `grave`
- revealed `topdeck`

It does **not** target:

- hidden cards
- known-but-not-revealed cards
- trumps
- `targets`
- `trump zone`

## 5. Why these zones are coherent

`☶` is allowed to work with:

- active public world surface (`manifest`)
- surfaced hidden underlayer (`revealed latent`)
- surfaced future card (`revealed topdeck`)
- spent public residue (`grave`)

This gives `☶` a distinct role:

```text
LOGIC is the only current operator
that naturally works with grave material
```

It is therefore not just a generic swap effect.

It is the machine's recovery / exchange operator
for already surfaced minor cards.

## 6. Why the trump exclusion is clean

In current machine reality,
revealed trumps live only in:

- `targets`
- `trump zone`

And those zones do not contain revealed minor-cards.

So `☶` can stay simple:

```text
logic works only with revealed minor-cards
```

without needing a second trump exception table.

## 7. Physical execution law

Logic must still be cardboard-playable.

That means:

- both swapped cards are physically visible and trackable
- chosen public slot is explicit
- the extracted revealed card really enters hand
- the inserted hand-card really takes that exact public place

If the target came from `grave`,
the chosen hand-card enters `grave` as revealed residue.

If the target came from a board slot,
the chosen hand-card takes that exact board slot as revealed.

## 8. Repair consequence

Default `☶` swap does not create an empty slot.

So unlike `CHOOSE`,
it does not normally create a second repair phase.

Short formula:

```text
LOGIC exchanges material
without reopening the board by default
```

## 9. Restrictions

- `☶` does not ignore all rules
- `☶` does not touch trumps by default
- `☶` does not touch hidden cards by default
- swap does not trigger a second play on the inserted hand-card
- swap does not trigger chain repair if the slot never stays empty

## 10. Open questions

- exact targeting shape inside `grave`
- whether `grave` targeting should later be whole-zone or top-item only
- whether `☶☶` should amplify swap scope or stay simple

## 11. Short formula

```text
☶ LOGIC = swap one revealed minor-card
from board or grave
with one card from hand
```
