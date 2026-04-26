# RUNTIME

Symbol:

```text
☱
```

Статус:

```text
canonical operator law
current turn-law branch
```

## 1. Core identity

`☱` now reads as install-choice operator.

It does not add a passive aura by itself.
It expands the future choice menu of later plays
through the `runtime` zone.

Short formula:

```text
☱ = install one extra reusable operator choice
```

## 2. What it is not

`☱` is not:

- automatic free extra effect on every play
- passive aura math
- draw
- reveal
- generic “make this card permanent” without runtime law

## 3. Current playtest law

If a card with `☱` is chosen for its runtime effect,
it may be installed into `runtime`
instead of using its ordinary partner operator as a one-shot effect.

Then:

1. the card goes to `runtime`
2. its partner operator `X` becomes an extra reusable option
3. on future plays, each played card may choose:
   - operator A of the played card
   - operator B of the played card
   - runtime operator `X`

Player still chooses exactly **one** effect.

Runtime does not create additive multi-cast by default.

## 4. Runtime access law

By default:

- only cards containing `☱` may enter `runtime`
- installed card stays in the one runtime slot
- its partner operator is the granted runtime choice

## 5. Meaning of runtime choice

The runtime-granted operator is not tied
to the card being played from hand.

It is a machine-level available choice.

Example:

- if `☱☰` is installed in runtime,
  every future played card may choose `☰`
  as a third effect option

## 6. Special self-pair law: `☱☱`

`☱☱` is special.

It does not immediately grant two runtime operators.

Instead:

```text
☱☱ opens runtime for any card
```

While `☱☱` remains in runtime:

- player may later install any minor card into runtime
- that chosen card replaces `☱☱`
- `☱☱` goes to `grave`
- the newly installed card then grants both of its operators
  as extra future choices

So `☱☱` is a runtime-opener,
not the final payload itself.

## 7. Physical execution law

Runtime must stay cardboard-readable.

That means:

- runtime is a real table zone
- installed card visibly occupies it
- players can see which extra operator choice(s) the machine currently grants

## 8. Restrictions

- runtime slot count remains `1`
- runtime grants extra choice, not free additional cast
- a played card still resolves exactly one chosen effect
- trumps do not become runtime cards through this default law

## 9. Open questions

- whether some future pair laws may alter how often runtime choice can be used
- whether runtime-installed card should always enter revealed
- exact replacement timing if runtime slot is already occupied by a non-opener card

## 10. Short formula

```text
☱ RUNTIME = install one extra reusable operator choice
☱☱ = open runtime for any later minor card
```
