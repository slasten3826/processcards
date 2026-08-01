[⊞ ◈] [▽ ☴]

# ORACLE

## 0. Status

```text
revision 2, 2026-07-31
  proto hand instead of holding six cards nowhere
  all six return; number 6 becomes the topdeck
  ends with an ordinary draw
  superseded wording kept and marked in §3, §4, §7, §10
```

Working trump draft.

Legacy breadcrumb:

```text
II High Priestess
```

Flavor text:

```text
What is chosen will shape what follows.
```

Core edge:

```text
▽ -> ☴
FLOW -> OBSERVE
```

---

## 1. Core Identity

`ORACLE` is a controlled near-future reading trump.

It is not ordinary draw.
It is not ordinary observe.
It is not full tutor from deck-depth.

It looks into the near incoming stream,
chooses one card,
and rewrites the immediate future order.

Short formula:

```text
look at top 6
take 1 into hand
return the rest on top in any order
```

---

## 2. Reading

`▽ FLOW` here is not blind movement.

It means the card operates directly on the incoming stream of future.

`☴ OBSERVE` here is not truth-state conversion.

It does not create `known`.
It does not create `revealed`.
It does not trigger trump-law just by looking.

So this trump reads as:

```text
select one path from the immediate future
without rewriting truth-state
```

This is not:

```text
search
```

And not:

```text
full tutor access
```

It is:

```text
near-future shaping by selective sight
```

---

## 3. Core Law

When `ORACLE` becomes known:

1. Take the top `6` cards of the deck into the **proto hand**.
2. Each card there carries a number, `1` to `6`.
3. The player rearranges the numbers freely.
4. All six return to the deck by number. Number `6` becomes the topdeck.
5. Draw one card by the ordinary method.
6. After `ORACLE` fully resolves, it follows ordinary trump ecology.

Short formula:

```text
top 6 -> proto hand, numbered
player reorders
all 6 -> back to deck by number, 6 = topdeck
ordinary draw
ORACLE -> ordinary trump ecology
```

The proto hand is a **transient zone**: `TRANSIENT_ZONE_LAW`. It is occupied only while `ORACLE` resolves and is empty at rest.

```text
consequence, not extra wording
```

Cards `1`-`5` return to the **body** of the deck and enter it hidden by `DECK_LAW §2`: their identity is lost with their position. Card `6` returns to the **topdeck**, where `known` is lawful by `DECK_LAW §3`.

So the player looks at six and **remembers exactly one**. The choice is not only what to take but what to keep knowing.

```text
STATUS: LEGACY
CANONICAL: NO
SUPERSEDED_BY: this section, revision 2
REVISION: 1

1. Look at the top 6 cards of the deck.
2. Choose 1 of those cards and put it into hand.
3. Put the remaining 5 cards back on top of the deck in any order.
4. After ORACLE fully resolves, it follows ordinary trump ecology.
```

Revision 1 had the six cards nowhere: taken from the deck, not in any zone, held in view. Revision 2 puts them in a zone, because a card is always somewhere.

---

## 4. Looking Leaves No Lasting State

Revision 2 keeps the intent of revision 1 and reaches it differently.

The player does see the six cards: they are in the proto hand. But the state does not survive:

```text
cards 1-5 -> deck body -> hidden by DECK_LAW §2
card 6    -> topdeck   -> known is lawful there, DECK_LAW §3
```

```text
looking costs nothing PERMANENT
```

A trump among the six does not resolve on being seen. It resolves only if it becomes the drawn card, under ordinary trump draw law.

```text
STATUS: LEGACY
CANONICAL: NO
SUPERSEDED_BY: this section, revision 2
REVISION: 1

Look here means: private inspection for selection, no state upgrade,
no hidden -> known, no known -> revealed, no automatic trump trigger
just because a trump was seen.

Short formula: look does not change machine truth-state
```

Revision 1 forbade the state change outright. Revision 2 allows it and **undoes it on return**, which reaches the same place without an exception to `CARD_INFORMATION_STATE_LAW §7`: nothing is re-hidden by special rule, the deck body simply is closed information.

---

## 5. Why This Works

`ORACLE` is strong because it gives:

- near-future access
- one-card selection
- immediate stream ordering

But it does not give:

- full deck tutor
- deep deck access
- truth-state conversion
- automatic trump ignition from sight alone

This keeps the card powerful
without turning it into total future sterilization.

---

## 6. Why The Six Return To The Top

All six return to the top of the deck in the chosen order, and number `6` becomes the topdeck, which the ordinary draw then takes.

This is intentional.

The card should shape the immediate future,
not erase that future entirely.

Allowing cards to be sent to the bottom
would make the event too strong,
because it would become:

- selection
- reordering
- and deep removal of unwanted future pressure

That is not the intended role of this trump.

Short formula:

```text
ordering yes
bottoming no
```

---

## 7. Restrictions

`ORACLE` does not:

- send viewed cards to the bottom of deck
- auto-resolve trumps seen among the six
- access arbitrary deck-depth beyond the top six
- count as ordinary `OBSERVE`
- leave the proto hand occupied, `TRANSIENT_ZONE_LAW §3`

```text
STATUS: LEGACY
CANONICAL: NO
SUPERSEDED_BY: §3 and §4, revision 2
REVISION: 1

- create `known` by looking
```

Revision 1 forbade `known` outright. Under revision 2 the player does see the six, and card `6` may stay `known` on the topdeck by `DECK_LAW §3`. Cards `1`-`5` lose it on entering the deck body by `DECK_LAW §2`. The restriction is replaced by the mechanism, not by permission.

---

## 8. Relation to Trump Ecology

`ORACLE` does not invent a separate ecology.

It uses:

- ordinary known-state trigger
- ordinary ordered resolution
- ordinary trump queue
- ordinary chain close handling
- ordinary trump-zone law after its own resolution

Its specificity is not in ecology.
Its specificity is in shaping the near future
without rewriting truth-state.

---

## 9. Design Character

`ORACLE` should feel:

- precise
- foresighted
- selective
- controlling without becoming absolute
- more like guided sight than brute tutor access
- less reckless than `FOOL`
- less violent than `RESET`
- less explicit than `EJECT`

This is intentional.

---

## 10. Minimal Canonical Text

Draft rules text:

```text
Take the top 6 cards into the proto hand, numbered 1 to 6.
Rearrange the numbers as you like.
Return all six to the deck by number; number 6 becomes the topdeck.
Draw one card.
After ORACLE fully resolves, it follows ordinary trump ecology.
```

```text
STATUS: LEGACY
CANONICAL: NO
SUPERSEDED_BY: this section, revision 2
REVISION: 1

Look at the top 6 cards of the deck.
Choose 1 and put it into hand.
Put the rest back on top of the deck in any order.
After ORACLE fully resolves, it follows ordinary trump ecology.
```

---

machines only. not for humans.
