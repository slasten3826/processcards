# LOGIC

Symbol:

```text
☶
```

Статус:

```text
canonical operator law
current turn-law branch
```

## 1. Core identity

`☶` now reads not as abstract exception text,
but as a direct swap operator for revealed minor-cards.

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

## 4. Legal target class

`☶` may target only:

- `revealed` cards
- `minor` cards

Default legal public zones:

- `manifest`
- `revealed latent`
- `grave`
- revealed `topdeck`

It does **not** target:

- hidden cards
- known-but-not-revealed cards
- trumps
- `targets`
- `trump zone`

## 5. Why the trump exclusion is clean

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

## 6. Physical execution law

Logic must still be cardboard-playable.

That means:

- both swapped cards are physically visible and trackable
- chosen public slot is explicit
- the extracted revealed card really enters hand
- the inserted hand-card really takes that exact public place

## 7. Restrictions

- `☶` does not ignore all rules
- `☶` does not touch trumps by default
- `☶` does not touch hidden cards by default
- swap does not trigger a second play on the inserted hand-card
- swap does not trigger chain repair if the slot never stays empty

## 8. Open questions

- whether revealed `topdeck` should be treated exactly like a public slot
- whether `☶☶` should amplify swap scope or stay simple
- whether later some mixed pairs should extend legal public zones

## 9. Short formula

```text
☶ LOGIC = swap one revealed minor-card with one card from hand
```
