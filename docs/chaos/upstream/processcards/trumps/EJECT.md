[⊞ ◈] [▽ ☷]

# EJECT

## 0. Status

Working design document.

Final rules text may still tighten.

Legacy breadcrumb:

```text
I. Маг
```

Core edge:

```text
▽ -> ☷
FLOW -> DISSOLVE
```

This trump is not a normal local removal.
It is a universal extractor.

---

## 1. Core Reading

This trump selects a card from its current mode of existence
and forces it into resolution.

It does not care much **where** the card is.
It cares what the card becomes **next**.

Short formula:

```text
select -> reveal if needed -> dissolve OR discharge
```

If the selected card is a non-trump,
it is forced into grave.

If the selected card is a trump,
it is forced into immediate trump resolution.

---

## 2. Identity

This is one of the rare precision trumps.

Most trumps act as:

- fate
- ecology pressure
- system-wide event
- circulation shift
- law rewrite

This trump instead acts as:

```text
explicit choice of target
```

That makes it a high-agency trump.
Not because it guarantees outcome,
but because it allows the player to point at a specific card.

Short formula:

```text
precision without total certainty
```

---

## 3. Target Law

This trump does **not** use a closed whitelist of zones.

It may target **any one card from any place**,
as long as the current rules of that place make the card legally addressable.

There is therefore no fixed list of “allowed zones”
and no special list of “forbidden zones.”

The only default structural restriction is:

```text
deck is addressable only at top-card level
```

That means:

- on table: any addressed card
- in hand: any chosen card
- in grave: any chosen card
- in target zone: any installed trump or any hidden candidate that current access rules expose
- in hidden / face-down state: any card the current rules allow to be chosen
- in trump zone: any stored trump
- in deck: only the top card by default

Short formula:

```text
any card, anywhere, if that place can legally point at it
```

---

## 4. Universal Resolution Law

Resolve this trump as follows:

1. Choose a legal target card.
2. If the card is hidden / unknown, reveal it.
3. Remove it from its current zone.
4. If it is a trump, resolve it immediately as a normal trump-event.
5. If it is not a trump, place it on top of grave.

Short formula:

```text
choose
reveal if needed
if trump -> play now
else -> top of grave
```

This single law should replace per-zone special casing whenever possible.

---

## 5. Zone-by-Zone Consequences

### Table / visible row

- non-trump -> removed to top of grave
- trump -> immediate resolution

### Hidden / face-down row

- reveal first
- non-trump -> top of grave
- trump -> immediate resolution

### Hand

- chosen card is pulled out of hand
- non-trump -> top of grave
- trump -> immediate resolution

### Grave

- chosen grave card leaves grave
- non-trump -> top of grave
- trump -> immediate resolution

### Top of deck

- reveal top card
- non-trump -> top of grave
- trump -> immediate resolution

### Installed trump in target zone

- the seal is broken
- the installed trump leaves the target slot
- it resolves immediately as a normal trump-event
- target slot then follows normal refill law

### Trump zone

- stored trump pressure is pulled back into live event space
- chosen trump resolves immediately as a normal trump-event
- trump zone loses that stored card

---

## 6. Why This Trump Matters

This trump can touch almost every ontological layer of the game:

- board state
- hidden state
- hand state
- deck future
- target law
- trump ecology

So this is not merely “good removal.”

This is a world-key trump.

Short formula:

```text
local target, global reach
```

---

## 7. Relation to Target Compiler

This trump is especially important because it can interact with installed victory-condition trumps.

That means target zone is not a perfect safe vault.
An installed trump may be forcibly unsealed.

Result:

- victory compiler remains contestable
- sealed annoying trumps may be re-discharged into the match
- target law remains politically unstable

Short formula:

```text
EJECT breaks seals
```

---

## 8. Relation to Ordered Grave

Because non-trumps go to **top of grave**,
this trump also interacts with ordered-grave logic.

It does not merely discard.
It can influence what becomes the newest residue.

This matters for any future mechanic that reads grave order,
grave top,
or grave recirculation.

Short formula:

```text
removal also writes residue
```

---

## 9. Chain Law

`EJECT` does not create bespoke cascade rules.

It selects a card and forces that card back into its own native law.

That means chains may happen,
but those chains are produced by the existing machine:

- target refill
- trump resolution
- trump-zone pressure release
- latent trump emergence

`EJECT` follows the general rule defined in:

- [TRUMP_RESOLUTION_ORDER.md](TRUMP_RESOLUTION_ORDER.md)

That means:

- restore vacated board structure first
- then enqueue newly activated trump-events
- then resolve them in arrival order

Short formula:

```text
EJECT chooses the card.
The machine chooses the aftermath.
```

---

## 10. Design Character

This trump should feel like:

- exact
- surgical
- authoritative
- slightly dangerous
- not fully predictable if a hidden or stored trump is selected

The player chooses the target,
but does not always fully choose the resulting cascade.

That is the correct feel.

---

## 11. Minimal Canonical Text

Draft rules text:

```text
Choose any legally addressable card.
If it is in deck, choose only the top card by default.
Reveal it if needed.
If it is a trump, it resolves immediately as a normal trump-event.
If it is not a trump, place it on top of grave.
```

Optional rules note:

```text
If an installed target trump is chosen, break its seal, resolve it immediately, then refill that target slot face-down from deck.
```

---

machines only. not for humans.
