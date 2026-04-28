# Eject Law

Статус:

```text
canonical table law
adopted individual trump event
```

Legacy breadcrumb:

```text
I Magician
```

Core edge:

```text
▽ -> ☷
FLOW -> DISSOLVE
```

## 1. Core identity

`EJECT` is a universal extractor trump.

It is not ordinary local removal.
It selects one card from its current mode of existence
and forces it into the machine's next lawful state.

Short formula:

```text
select
reveal if needed
if trump -> trump flow
else -> top of grave
```

## 2. Reading

`▽` here is not gentle motion.

It means forced extraction out of the current place.

`☷` here is not ordinary revealed-board dissolve.

It means forced discharge by class:

- trump -> live event
- non-trump -> residue

So this trump reads as:

```text
what cannot remain is extracted into its next law
```

This is not:

```text
draw
```

And not:

```text
ordinary board removal
```

It is:

```text
precision extraction with class-based discharge
```

## 3. Legal scope

`EJECT` may choose:

- any card on board
- any card in hand
- the top card of deck

It does not reach:

- deep deck beyond topdeck

Board is defined by:

- [BOARD_SCOPE_LAW.md](./BOARD_SCOPE_LAW.md)

Short formula:

```text
board + hand + topdeck only
not deep deck
```

## 4. Core law

When `EJECT` becomes known:

1. choose one legal target card
2. if that card is not revealed, reveal it
3. remove it from its current zone
4. if it is a trump, it enters ordinary trump event flow
5. if it is not a trump, place it on top of grave
6. after `EJECT` fully resolves, `EJECT` itself follows ordinary trump ecology

Short formula:

```text
choose
reveal if needed
if trump -> ordinary trump event flow
else -> top of grave
EJECT -> ordinary trump ecology
```

## 5. Information consequence

`EJECT` does not bypass the information model silently.

If it chooses a hidden or known-but-not-revealed card,
that card becomes revealed as part of extraction.

Then class routing applies:

- trump -> ordinary trump flow
- non-trump -> top of grave

This keeps `EJECT` inside:

- [CARD_INFORMATION_STATE_LAW.md](./CARD_INFORMATION_STATE_LAW.md)
- [TRUMP_EVENT_MINIMAL_LAW.md](./TRUMP_EVENT_MINIMAL_LAW.md)
- [GRAVE_LAW.md](./GRAVE_LAW.md)

## 6. Zone consequences

### Board

If `EJECT` takes a card from board:

- non-trump -> top of grave
- trump -> ordinary trump event flow

The vacated zone then follows
its own structural law:

- target slot refill
- ordinary board integrity handling
- no special `EJECT`-only repair rule

### Hand

If `EJECT` takes a card from hand:

- non-trump -> top of grave
- trump -> ordinary trump event flow

This is forced extraction from intervention reservoir,
not discard by player choice.

### Topdeck

If `EJECT` takes the top card of deck:

- reveal it if needed
- non-trump -> top of grave
- trump -> ordinary trump event flow

## 7. Relation to compiler and trump residue

`EJECT` may act on:

- installed trumps in `targets`
- stored trumps in `trump zone`
- active trumps in `trump flow`

Consequences:

- target seals are breakable
- stored trump residue may be forced back into live event space
- active trump flow remains contestable

This is why `EJECT` is a world-key trump,
not just strong removal.

## 8. Relation to trump ecology

`EJECT` does not invent separate ecology.

It uses:

- ordinary class routing
- ordinary trump flow if a trump is extracted
- ordinary ordered resolution
- ordinary chain-close handling
- ordinary trump-zone law after its own resolution

Its specificity is not in special cascade grammar.

Its specificity is in choosing
what object gets forced into native machine law next.

## 9. Restrictions

`EJECT` does not:

- access deep deck beyond topdeck
- ignore zone structure after extraction
- suppress immediate trump resolution of an extracted trump
- invent bespoke refill rules for vacated slots

The trump chooses the card.
The machine chooses the aftermath.

## 10. Design character

`EJECT` should feel:

- exact
- surgical
- authoritative
- high-agency
- slightly dangerous
- globally reaching without being omnipotent

The player chooses the target.
The player does not fully choose the cascade.

## 11. Minimal canonical text

```text
Choose one card on board, in hand, or the top card of deck.
Reveal it if needed.
If it is a trump, it enters ordinary trump event flow.
If it is not a trump, place it on top of grave.
After EJECT fully resolves, it follows ordinary trump ecology.
```
