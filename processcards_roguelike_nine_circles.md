# ProcessCards — Roguelike Nine Circles

## Status

Working crystall draft.

This is not final balance text.
This is not locked implementation law.
This document records the current design shape for the roguelike hell-run structure.

The core idea:

```text
Run starts at Circle 9 and descends to Circle 1.
```

That is important.

The player does **not** begin at Circle 1 and go down to Circle 9.
The player begins at the outer frozen runtime layer, Circle 9, and must descend toward Circle 1, where the most primitive operator, `▽ FLOW`, becomes the final floor challenge.

`△ MANIFEST` is not a floor.
It remains the player's exit / victory condition / manifestation layer.

---

## Operator Ladder

```text
1  ▽ FLOW
2  ☰ CONNECT
3  ☷ DISSOLVE
4  ☵ ENCODE
5  ☳ CHOOSE
6  ☴ OBSERVE
7  ☲ CYCLE
8  ☶ LOGIC
9  ☱ RUNTIME
10 △ MANIFEST
```

Roguelike descent order:

```text
9 → 8 → 7 → 6 → 5 → 4 → 3 → 2 → 1
```

Playable floor order:

```text
☱ → ☶ → ☲ → ☴ → ☳ → ☵ → ☷ → ☰ → ▽
```

`△ MANIFEST` stays outside the floor list.

---

## Global Roguelike Principle

Each floor corrupts one operator.

The operator is not simply banned or weakened.
Each floor makes its dominant operator express the corresponding hell-crystal.

```text
floor = circle pathology × operator law
```

The floor should change the *gesture* of the operator, not merely add a numeric debuff.

---

# Floor 9 — ☱ RUNTIME

## Circle Theme

Treachery / frozen relation / ice palace.

This is the first floor of the roguelike run.
It must be readable and playable as an introduction to hell-mode.

The idea is not that runtime becomes locked forever.
Runtime still installs and replaces normally.

The corruption is:

```text
runtime no longer asks.
runtime ticks automatically.
```

## Normal Game

In the normal game, runtime grants an extra optional operator choice.

Example:

```text
played card operators: A / B
runtime grants: X
choices: A / B / X / none
```

## Circle 9 Law — Automatic Runtime

If runtime is occupied, its granted operator resolves automatically every turn before the player's chosen operator.

Runtime install / replacement rules remain normal.

Draft law:

```text
FLOOR 9 — AUTOMATIC RUNTIME

- Runtime install and replacement work normally.
- Runtime no longer grants an optional choice.
- If runtime is occupied, its granted operator auto-resolves each turn.
- Auto-runtime resolves before the player's chosen operator.
- A runtime installed during the current turn begins ticking on the next turn.
```

Example:

```text
Runtime: ☱☶
Played card: ☰☰
Player chooses: ☰

Resolution:
1. ☶ resolves from runtime automatically.
2. ☰ resolves from the played card.
```

Short formula:

```text
☱ / Circle 9 = installed relation becomes mandatory continuation
```

---

# Floor 8 — ☶ LOGIC

## Circle Theme

Fraud / laundering / logic as public falsification.

The key move:

```text
logic loses the hand.
grave replaces manifest.
```

## Normal Game

Normal `☶ LOGIC` works with hand and public material.
It can exchange hand material with revealed public/grave material.

## Circle 8 Law — Logic Laundering

On Circle 8, `☶ LOGIC` no longer uses hand.
Instead, it swaps a revealed manifest-chain card with a card from grave.

Draft law:

```text
FLOOR 8 — LOGIC LAUNDERING

When resolving ☶:

1. Disable normal hand-based LOGIC.
2. Choose one revealed card in manifest chain.
3. Swap it with a card from grave.
4. The manifest card goes to grave.
5. The grave card enters that manifest slot revealed.
```

Current default candidate:

```text
use top grave card
```

Balance variant:

```text
allow choosing any grave card
```

Core law is not the top/any distinction.
Core law is:

```text
no hand;
grave ↔ manifest
```

Short formula:

```text
☶ / Circle 8 = grave becomes public reality
```

---

# Floor 7 — ☲ CYCLE

## Circle Theme

Violence / repeated force / stored blow fired again.

This floor makes `☲ CYCLE` behave like a trump-effect trigger without making it a trump card.

## Normal Game

Normal `☲ CYCLE` refreshes hand:

```text
draw 1 procedure
then discard 1 from hand
```

## Circle 7 Law — Trump Cycle

On Circle 7, `☲` does not perform normal hand-cycle.
It repeats the latest trump currently stored in Trump Zone.

Also, only on this floor:

```text
Trump Zone capacity becomes 3.
```

This matches the increased violence/turbulence of the floor and gives the floor a deeper stored-force chamber.

Draft law:

```text
FLOOR 7 — TRUMP CYCLE

- Trump Zone capacity is 3 instead of normal capacity.
- ☲ does not perform normal draw/discard cycle.
- When resolving ☲, check Trump Zone.
- If Trump Zone is empty, ☲ has no effect.
- If Trump Zone contains trumps, resolve the latest / top / most recent trump effect again.
- ☲ itself is not a trump.
- ☲ does not enter Trump Zone.
- Any trumps exposed by the repeated trump effect enter normal trump flow.
```

Short formula:

```text
☲ / Circle 7 = stored force fires again
```

---

# Floor 6 — ☴ OBSERVE

## Circle Theme

Heresy / doctrine-check / myth refuses to update.

Core idea:

```text
myth does not change under reality;
reality is changed under myth.
```

`OBSERVE` becomes an act of judgment.

## Normal Game

Normal `☴ OBSERVE`:

```text
choose one hidden card on board
make it known
```

## Circle 6 Law — Heresy Observe

When resolving `☴`, the currently played observing card defines doctrine.
Doctrine is the pair of operators on the played card.

A hidden observed minor card is heresy if it shares no operator with the observing card.

Example:

```text
Played observing card: ☴☳
Doctrine: {☴, ☳}

Observed card ☴☰ → not heresy
Observed card ☳☵ → not heresy
Observed card ☲☱ → heresy
```

Draft law:

```text
FLOOR 6 — HERESY OBSERVE

When resolving ☴:

1. Choose one legal hidden card in latent / topdeck.
2. Look at it.
3. Define doctrine as both operators on the currently played OBSERVE-card.
4. If the observed card shares at least one operator with doctrine:
      it is not heresy;
      it becomes known normally.
5. If the observed card shares no operator with doctrine:
      it is heresy;
      observed card → grave;
      choose any card from hand;
      place that hand card into the observed slot as hidden-known.
6. If the observed card is a trump:
      it cannot be heresy;
      send it to trump flow by normal trump law.
```

Target zone is not affected by this effect during the hell-run.
Targets are locked by floor configuration.

Short formula:

```text
☴ / Circle 6 = observe → judge → replace
```

---

# Floor 5 — ☳ CHOOSE

## Circle Theme

Wrath / Styx / choice becomes replacement.

The important mechanical inversion:

```text
normal CHOOSE pulls manifest into hand;
Circle 5 CHOOSE pushes play into manifest.
```

This floor should break the player's mechanical memory.
In most of the game, the player cannot directly place hand material into manifest.
On this floor, this is exactly what happens.

## Normal Game

Normal `☳ CHOOSE`:

```text
choose one revealed manifest card
take it into hand
repair that column
played card later goes to grave
```

## Circle 5 Law — Styx Choose

On Circle 5, `☳ CHOOSE` becomes replacement.

Draft law:

```text
FLOOR 5 — STYX CHOOSE

When resolving ☳:

1. Choose one revealed card in manifest chain.
2. Move chosen manifest card to grave.
3. Move the currently played ☳ card from play zone into that manifest slot as revealed.
4. The played ☳ card does not go to grave, because it has become manifest.
5. Do not perform ordinary column repair for that slot, because the slot is filled by the played card.
```

No flip.
No new token.
No wrath/sullen fork in the first version.

Open variant for playtest:

```text
On Circle 5, any played card may use this replacement behavior,
not only cards resolving ☳.
```

This variant may be too strong and requires testing.

Short formula:

```text
☳ / Circle 5 = choice becomes direct manifest replacement
```

---

# Floor 4 — ☵ ENCODE

## Circle Theme

Avarice / prodigality / burden exchange / visible cargo shoving.

The key inversion:

```text
normal ENCODE writes hidden future;
Circle 4 ENCODE only shoves visible burden.
```

This is the only floor where flip exists.

## Normal Game

Normal `☵ ENCODE` works with not-revealed cards.
It swaps hidden/known cards and shapes future structure.

## Circle 4 Law — Burden Encode

On Circle 4, `☵` no longer works with hidden cards.
It works only on revealed manifest-chain cards.

It swaps two revealed manifest cards and flips both internally.

Draft law:

```text
FLOOR 4 — BURDEN ENCODE

When resolving ☵:

1. Ignore normal hidden-swap ENCODE.
2. Choose two revealed cards in manifest chain.
3. Swap their positions.
4. Flip both cards internally.
```

Flip means:

```text
AB becomes BA
```

Example:

```text
Before:
slot 2 = ☵☳
slot 5 = △☱

After:
slot 2 = ☱△
slot 5 = ☳☵
```

There are no trumps in manifest chain under current rules.

Timing remains simple:

```text
normal column change / repair first;
then Circle 4 ENCODE shoves visible manifest cards.
```

Short formula:

```text
☵ / Circle 4 = hidden future-writing collapses into visible burden-swapping
```

---

# Floor 3 — ☷ DISSOLVE

## Circle Theme

Gluttony / Cerberus / latent future eaten into grave.

The floor makes `DISSOLVE` consume the whole latent manifest chain.

## Normal Game Candidate

Normal `☷ DISSOLVE` candidate:

```text
choose one card in latent manifest chain
send it to grave
```

Normal turn repair already works as:

```text
revealed manifest card → grave
latent card in same column → revealed manifest
deck card → hidden latent
```

## Circle 3 Law — Cerberus Dissolve

On Circle 3, `☷ DISSOLVE` does not consume one latent card.
It consumes the entire latent row left-to-right.

Draft law:

```text
FLOOR 3 — CERBERUS DISSOLVE

When resolving ☷:

1. Normal column repair has already happened.
2. Scan latent manifest chain left-to-right.
3. For each latent slot:
   - if minor:
       move card to grave;
       mark slot empty.
   - if trump:
       move card to trump_flow_queue;
       mark slot empty.
   - if empty:
       continue.
4. After all 6 slots were scanned:
      refill all emptied latent slots from deck as hidden latent cards.
5. After the circle effect finishes:
      resolve queued trumps in collected order by normal trump law / priority.
```

Circle effect outranks trump effects during the scan.
Trumps do not interrupt Cerberus.
They queue and resolve after the whole latent row has been consumed and repaired.

Typical grave math:

```text
normal turn: grave +1
normal dissolve turn: grave +2
Circle 3 dissolve turn: grave +7
```

Short formula:

```text
☷ / Circle 3 = Cerberus eats the latent row
```

---

# Floor 2 — ☰ CONNECT

## Circle Theme

Lust / loop of old connection / grave-fed desire.

This is not about storm as a mechanic.
The core is:

```text
connect no longer opens future;
connect recycles residue.
```

## Normal Game

Normal `☰ CONNECT` performs draw procedures from deck.

## Circle 2 Law — Grave Connect

On Circle 2, `☰ CONNECT` draws only from top grave.

Draft law:

```text
FLOOR 2 — GRAVE CONNECT

When resolving ☰:

1. Do not perform normal deck draw procedures.
2. For each draw procedure ☰ would perform:
   - if grave has at least one eligible card:
       move top grave card to hand.
   - if grave is empty:
       that draw procedure fizzles.
3. The currently played ☰ card cannot draw itself,
   because it remains in play until ☰ finishes.
4. After ☰ closes, the played card goes to grave normally.
```

Short formula:

```text
☰ / Circle 2 = draw from what already burned
```

---

# Floor 1 — ▽ FLOW

## Circle Theme

Closed knowledge / unstable hidden substrate.

This is the final floor of the run.
The player reaches it only after descending through 9 → 2.

The floor should be difficult because the most primitive operator becomes hostile.

## Normal Game

Normal `▽ FLOW` moves not-revealed cards only.
It works on hidden / known cards, not revealed cards.
Legal spaces include:

```text
targets
latent
deck
```

It does not move revealed cards.
Revealed cards act as anchors.

## Circle 1 Candidate Law — Forced Hidden Flow

On Circle 1, `▽ FLOW` becomes an automatic hidden-layer disturbance.

Draft law:

```text
FLOOR 1 — FORCED FLOW

At the end of each player turn,
after victory / crystal check:

1. If victory was not achieved,
   the floor performs forced FLOW.
2. Forced FLOW shifts one legal not-revealed structure by 1 step.
3. Legal structures: latent / deck / possibly locked target structure if floor rules allow.
4. Revealed cards do not move.
5. Known cards count as not-revealed unless another law says otherwise.
```

Important:

```text
victory check should happen before forced FLOW
```

The player may manifest a win in the moment.
If they do not, the hidden substrate flows again.

Short formula:

```text
▽ / Circle 1 = concealed substrate refuses to stabilize
```

---

# Current Floor Summary

```text
9 ☱ RUNTIME  — automatic runtime tick before chosen operator
8 ☶ LOGIC    — grave ↔ manifest laundering, no hand
7 ☲ CYCLE    — repeat latest Trump Zone effect; Trump Zone capacity 3
6 ☴ OBSERVE  — doctrine-check; mismatch becomes heresy and replacement
5 ☳ CHOOSE   — played card replaces chosen manifest card
4 ☵ ENCODE   — swap + flip two revealed manifest cards
3 ☷ DISSOLVE — Cerberus consumes latent row left-to-right
2 ☰ CONNECT  — draw from top grave only; cannot draw itself
1 ▽ FLOW     — forced hidden-layer motion after failed win check
```

Run direction:

```text
START: 9 ☱ RUNTIME
↓
8 ☶ LOGIC
↓
7 ☲ CYCLE
↓
6 ☴ OBSERVE
↓
5 ☳ CHOOSE
↓
4 ☵ ENCODE
↓
3 ☷ DISSOLVE
↓
2 ☰ CONNECT
↓
FINAL: 1 ▽ FLOW
↓
EXIT: △ MANIFEST
```

---

# Design Notes

## Target Zone

During hell-run floors, target zone is not freely manipulated by the player.
Each floor has predetermined victory conditions / target configuration.

The target zone may be generated by floor-specific rules, but once the floor starts, player effects do not rewrite it unless a later explicit floor law says otherwise.

## Trumps

Trump handling remains normal unless a floor says otherwise.

Special cases currently noted:

- Circle 7 increases Trump Zone capacity to 3.
- Circle 7 `☲` repeats latest trump in Trump Zone but is not itself a trump.
- Circle 6 heresy cannot apply to trumps; observed trumps go to trump flow.
- Circle 3 Cerberus queues latent trumps and resolves them after the whole latent row is consumed and refilled.

## Balance Handles

The following are known tuning points:

- Circle 8: top grave vs any grave.
- Circle 6: doctrine check by one shared operator vs stricter matching.
- Circle 5: only `☳` uses replacement vs all cards on the floor use replacement.
- Circle 1: which hidden structure forced FLOW targets and whether player chooses direction.
- Circle 9: whether floor starts with empty runtime or predefined runtime.

---

# Core Crystall Formula

```text
ProcessCards hell-run =
9 operator-corruptions,
played in reverse descent,
where each circle teaches one pathology
by changing how its operator behaves in hand, field, grave, latent, trump, or runtime.
```

Short formula:

```text
Start in frozen runtime.
Descend through fraud, violence, heresy, wrath, burden, gluttony, old connection.
End at unstable hidden flow.
Exit only through manifest.
```

machines only. not for humans.

