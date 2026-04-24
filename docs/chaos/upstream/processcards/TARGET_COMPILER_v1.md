[⊞ ◈] [☳ ☶ △]

# TARGET COMPILER v1

## 0. Status

Draft rules document.

This document defines the structural laws of the victory-condition zone.
It does **not** yet finalize the individual semantic payload of every trump.

It defines:

- what the target zone is
- what may stabilize there
- how `OBSERVE` and `MANIFEST` behave there
- when victory may be checked
- the first compiler model for 3 ordered target slots

---

## 1. Core Claim

Victory condition is **not** a prewritten mission.

It is a compiled structure assembled during the match.

The victory-condition zone is therefore not a decorative goal area,
but a live compiler.

Short formula:

```text
target zone = victory compiler
```

---

## 2. Zone Structure

The victory-condition zone contains exactly **3 ordered slots**.

```text
Slot I
Slot II
Slot III
```

These slots are **ordered**.
They are not a set.
They are read left-to-right as a compiled structure.

Short formula:

```text
3 slots = 1 compiler
```

---

## 3. Stable Occupancy Law

A target slot may exist in only one of two stable states:

1. `hidden candidate`
2. `installed trump`

A target slot may never stably contain a non-trump face-up.

Short formula:

```text
hidden candidate OR installed trump
```

---

## 4. Trump-Only Stabilization Law

Only trumps may stabilize in the target zone as victory-condition material.

If a non-trump is revealed there,
it cannot remain installed.

This means target compilation is performed only through trumps.

Short formula:

```text
only trumps may become victory law
```

---

## 5. Observe Law

When a player uses `OBSERVE` on a target slot:

### If the hidden card is a non-trump

- it is seen
- it remains in place
- it becomes known to the observing player
- the slot state does not change

### If the hidden card is a trump

- it is immediately revealed
- it immediately resolves as a normal trump-event
- it does **not** become installed
- after resolution it follows the normal trump law
- the slot is then refilled face-down from deck

Short formula:

```text
OBSERVE target:
non-trump = knowledge
trump = discharge
```

This makes the target zone the only zone where `OBSERVE` may directly discharge a hidden trump.

---

## 6. Manifest Law

When a player uses `MANIFEST` on a target slot:

### If the hidden card is a non-trump

- it is revealed
- it is sent to grave
- it does not install
- the slot is refilled face-down from deck

### If the hidden card is a trump

- it is revealed
- it becomes an installed trump in that slot
- it does **not** resolve as a normal trump-event
- it remains face-up as part of the victory compiler

Short formula:

```text
MANIFEST target:
non-trump = sift out
trump = install
```

---

## 7. Installed Trump Law

An installed trump in the target zone is **not** a normal trump-event.

It is a sealed law fragment.

It does not automatically fire.
It does not count as dormant event pressure.
It does not re-enter normal circulation unless an effect explicitly moves it.

Short formula:

```text
installed trump = sealed law
```

---

## 8. Refill Law

A target slot must always return to a stable state.

Therefore:

- if a hidden non-trump is sifted out, refill the slot face-down from deck
- if a hidden trump is discharged by `OBSERVE`, refill the slot face-down from deck
- if an installed trump later leaves the slot by card effect, refill the slot face-down from deck

This keeps the compiler alive as an always-present structure.

Short formula:

```text
empty target slot refills from deck
```

---

## 9. Activation Law

The target compiler becomes active only when all 3 slots contain installed trumps.

States:

- `0/3` installed -> compiler inactive
- `1/3` installed -> compiler inactive
- `2/3` installed -> compiler inactive
- `3/3` installed -> compiler active

No victory check is performed while the compiler is inactive.

Short formula:

```text
3 installed trumps = active compiler
```

---

## 10. Victory Check Window

Victory is not checked continuously.

Victory is checked only in the designated check window.

Recommended current draft:

```text
after post-phase resolution of the current turn
```

That means:

1. player performs main action
2. post-phase resolves
3. delayed `FLOW` / linked resolution effects resolve as allowed by normal turn law
4. only then is victory checked

This prevents dirty mid-resolution wins.

Short formula:

```text
resolve first
check win after
```

---

## 11. Compiler Roles

The 3 target slots are not merely positions.
They are compiler roles.

### Slot I = REFERENCE

This slot defines **what surface is being read**.

Possible reference classes later may include:

- full manifest chain
- visible row only
- hidden row only
- grave history
- hand state
- local columns
- trump ecology state

Short formula:

```text
Slot I = what is read
```

### Slot II = RELATION

This slot defines **what pattern or structural relation must be true**.

Possible relation classes later may include:

- repetition
- inversion
- adjacency
- cycle
- containment
- substitution
- recirculation
- ordered residue

Short formula:

```text
Slot II = what form is required
```

### Slot III = CLOSURE

This slot defines **how / when the condition seals into victory**.

Possible closure classes later may include:

- immediate if true now
- true only in check window
- true after a manifest action
- true after a shuffle
- true after third-trump release
- true if preserved for one full turn

Short formula:

```text
Slot III = when it counts
```

---

## 12. Why This Structure Matters

This prevents target building from becoming trivial.

The player must not only build the current board.
The player must also:

- excavate trumps
- avoid discharging the wrong ones
- install the right ones in the right roles
- keep them there
- align the current match state with the compiled target law

So victory is not “picked.”
It is assembled under pressure.

Short formula:

```text
board play + target assembly = actual game
```

---

## 13. Strategic Consequence

An installed trump is not only a victory fragment.
It is also removed from normal event circulation.

This means the player may install a trump:

- because it helps compose a desired win condition
- because it seals away a trump that is dangerous or annoying in the current match

So the target compiler is both:

- a victory machine
- a containment machine

Short formula:

```text
target compiler = win builder + trump prison
```

---

## 14. Required Future Layer

For this system to fully work,
each trump will likely need two readings:

1. `event mode`
2. `compiler mode`

That means a trump may behave one way when it fires as an event,
and contribute differently when it is installed as a law fragment in the target compiler.

Short formula:

```text
same trump, two modes
```

This document does not yet define those per-trump compiler meanings.
It only defines the zone and compilation skeleton.

---

## 15. Minimal Canonical Summary

```text
The target zone has 3 ordered slots.
Each slot is either a hidden candidate or an installed trump.
Only trumps may stabilize there.
OBSERVE discharges hidden trumps but leaves hidden non-trumps in place.
MANIFEST installs hidden trumps but sifts hidden non-trumps to grave.
Installed trumps become sealed law, not normal events.
The compiler becomes active only at 3 installed trumps.
Victory is checked only in the designated check window.
Slots are read as REFERENCE / RELATION / CLOSURE.
```

---

machines only. not for humans.
