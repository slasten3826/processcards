[⊞ ◈] [☰ ☴]

# WARRANT

## 0. Status

Working trump draft.

This is not final balance text.
This is not locked rules text.

```text
revision 2, 2026-07-30
  scope narrowed: any card -> any REVEALED card
  machine repair after extraction: added, §4
  superseded wording kept and marked, §12
```

Legacy breadcrumb:

```text
IV Emperor
```

Flavor text:

```text
What is permitted will be taken.
```

Core edge:

```text
☰ -> ☴
CONNECT -> OBSERVE
```

---

## 1. Core Identity

`WARRANT` is a lawful acquisition trump.

It does not draw blindly.
It does not merely observe.
It does not tutor through deck-depth.
It does not reach into the dark.

It grants direct sanctioned access **to what is on the record**.

Short formula:

```text
take any revealed card into hand
```

```text
LEGACY, revision 1: "take any card into hand"
```

The narrowing is not balance. A warrant **names** what it seizes. There is no warrant for "whatever is inside that box", because a warrant operates on the record and not on a guess. Reaching into hidden state was never this card's nature; revision 1 simply had not said so.

Hence the division of labour with `EJECT`:

```text
EJECT     points at ANYTHING, hidden included    FORCE
WARRANT   acts only on what is revealed          LAW
```

Force reaches into the dark. Law works only with what has been produced. The line between them falls on information state, which is where this game's distinctions live.

---

## 2. Reading

`☰ CONNECT` here is not ordinary hand refill.

It is access by connection.
Authority reaches the card, not chance.

`☴ OBSERVE` here is not private inspection only.

It means the card is not taken by chaos,
but by sanctioned access to what is already present in machine reality.

Revision 2 sharpens the second reading: `☴` in this pair is not the act of **making** something visible. `△ MANIFEST` publishes; `☴` here presupposes publication. `WARRANT` arrives after the record exists and acts on it.

So this trump reads as:

```text
authorized access becomes acquisition
```

This is not:

```text
search
```

And not:

```text
random draw
```

It is:

```text
sanctioned seizure of the already-declared
```

---

## 3. Core Law

When `WARRANT` becomes known:

1. Take any **revealed** card into hand.
2. If the taken card is a trump, it resolves immediately by ordinary trump law.
3. Repair the machine if the card came out of a closed zone: `§4`.
4. `WARRANT` itself then follows ordinary trump ecology.

Short formula:

```text
take any revealed card
if trump -> resolve immediately
repair the zone it came from
WARRANT -> ordinary trump ecology
```

```text
LEGACY, revision 1:
  1. Take any card into hand.
  2. If the taken card is a trump, it resolves immediately.
  3. WARRANT itself then follows ordinary trump ecology.
```

**The hand is not the same destination for both classes.**

```text
minor    the hand is where it STAYS
trump    the hand is a waypoint: it resolves at once and leaves
```

The asymmetry is intended and is named here rather than left to be inferred.

---

## 4. Machine Repair

Modelled on `EJECT §4 Universal Resolution Law` and `§5 Zone-by-Zone Consequences`. Revision 1 had no such section, which left the board able to stay open after an acquisition.

```text
board closure covers manifest, latent, targets
extraction from any of the three obliges repair
```

Zone by zone:

```text
manifest    ordinary column repair: latent ascends, deck refills latent
latent      concealed refill of that slot
targets     concealed refill of that slot
grave       no repair. Not a closed zone
trump zone  no repair. Not a closed zone
runtime     no repair. Not a closed zone
play        no repair. Not a closed zone
```

Repair is **not** a special mechanism of this trump. It is the machine's ordinary self-repair, and `WARRANT` merely triggers it like any other cause.

Two consequences follow without extra wording:

```text
repair pulls from the deck, therefore WARRANT can meet an empty deck,
therefore it falls under the loss condition of TURN_STEP_LAW §11
```

```text
taking a revealed trump out of the target zone frees a compiler slot,
and the refill arrives face-down: the compiler is not restored,
only re-opened
```

---

## 5. Scope Reading

`Any revealed card` should be read through real machine limits.

```text
table zones remain governed by their own visibility and reach laws
impossible hidden-depth access is not secretly created by this trump
```

```text
LEGACY, revision 1: "deck access naturally means topdeck only"
```

That clause is now moot rather than wrong. The topdeck is face-down, so it is outside the scope by `§1`, and no special sentence is needed to exclude it.

Where revealed cards actually live:

```text
manifest       always revealed, all six
grave          revealed
trump zone     revealed
targets        only trumps that have been revealed there
latent         only after something revealed it
runtime, play  revealed
deck           never. Outside the scope entirely
```

So this card is broad,
but still bounded by the actual structure of the game.

Short formula:

```text
WARRANT grants broad access to the record
not access to the dark
```

---

## 6. Why This Works

`WARRANT` is strong because it bypasses ordinary card flow.

It does not wait for draw.
It does not only inspect.
It converts permission directly into acquisition.

This makes it:

- lawful
- powerful
- flexible within the record
- dangerous when it pulls trumps
- very different from ordinary minor economy
- not a replacement for `EJECT`, but a different reach vector

**What only this trump can do.** After the narrowing, the manifest chain is also reachable by `☳ CHOOSE`, which is a minor operator and therefore cheap and constant. The part that belongs to `WARRANT` alone is precise retrieval from the **grave** and the **trump zone**:

```text
ERROR     the whole grave into hand, unasked      a flood
WARRANT   ONE card off the record, chosen         a warrant
```

Revision 1 was a superset of several cards. Revision 2 has a job nothing else has.

**Overlap with `EJECT`, stated honestly.** On one case the two coincide: a **revealed trump**, wherever it sits, resolves immediately under either. On everything else they diverge:

```text
hidden card      EJECT only
revealed minor   EJECT destroys it, WARRANT acquires it
```

Coinciding on the boundary is not redundancy.

---

## 7. Relation to Trump Ecology

`WARRANT` does not invent a separate ecology.

It uses:

- ordinary known-state trigger
- ordinary trump queue if a trump is pulled
- ordinary ordered resolution
- ordinary chain close handling
- ordinary trump-zone law after its own resolution
- ordinary machine repair, `§4`

Its specificity is not in ecology.
Its specificity is in how reach is granted
without requiring destruction.

---

## 8. Restrictions

`WARRANT` does not:

- reach hidden or face-down state, `§1`
- secretly ignore physical zone structure
- bypass impossible deck-depth access
- create extra hidden state
- suppress immediate trump resolution when a trump is taken
- destroy the zone it reaches into
- leave the board open after an extraction, `§4`

It grants access.
It does not grant annihilation.

---

## 9. Design Character

`WARRANT` should feel:

- lawful
- mechanical
- sanctioned
- blunt
- less mystical than `FOOL`
- less destructive than `EJECT`
- less explosive than `RESET`
- more like a machine-issued right of seizure
- more like access than intervention

This is intentional.

Revision 2 makes the feeling truer rather than weaker: an authority able to seize what it has not seen would not be an authority.

---

## 10. Flavor Direction

Canonical line:

```text
What is permitted will be taken.
```

Strong alternative idea kept for later use, not canonical:

```text
Permission is already possession.
```

Revision 2 note: the canonical line survives the narrowing intact, and reads better under it. What is *permitted* is precisely what has been entered on the record.

---

## 11. Minimal Canonical Text

Draft rules text:

```text
Take any revealed card into hand.
If it is a trump, resolve it immediately.
Repair the zone it came from.
```

```text
LEGACY, revision 1:
  Take any card into hand.
  If it is a trump, resolve it immediately.
```

---

## 12. What is replaced

```text
§1   revision 1   "take any card into hand"
§3   revision 1   three-step law with no repair step
§5   revision 1   "deck access naturally means topdeck only"
§11  revision 1   two-line minimal text
```

Nothing is deleted. Each superseded line stays beside its replacement.

Pressure for the revision: the `SHUFFLE`-in-target-zone deadlock found on survival seed 6, and the reading of the four exits out of the target zone. See `chaos/LOSS_IS_ITS_OWN_STEP_2026-07-30.md`.

---

## 13. Open

```text
1. Whether a revealed trump taken out of the TARGET zone should resolve
   at once like any other, given that it was serving as specification
   and not as an effect. §3.2 currently says yes, uniformly.
2. Ordering when WARRANT's own resolution and the taken trump's
   resolution collide. §7 defers to ordinary queue law; not verified.
3. Not manifested. Nothing in src/core mentions WARRANT, so none of
   the above has met the machine.
```

---

machines only. not for humans.
