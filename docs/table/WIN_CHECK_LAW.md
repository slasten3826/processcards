# Win Check Law

Статус:

```text
canonical table law
current victory/compiler branch
```

Этот документ фиксирует,
как сейчас собирается и проверяется победа
через `target zone` и directed `manifest chain`.

## 1. Core claim

Victory is not a separate score track.

Victory is compiled from:

- `target zone`
- directed `manifest chain`

Short formula:

```text
target trumps compile the required pattern
manifest chain must become that pattern
```

## 2. Core structural sizes

Current branch assumes:

- `manifest chain` = `6` cards
- `hand` = `6` cards

This is required because:

```text
3 target trumps
x 2 directed readings each
= 6-slot victory structure
```

So the chain must have six visible positions
for the compiled pattern to fully manifest.

## 3. Compiler zone

`target zone` is the victory compiler.

When it contains `3` trumps,
those trumps define the current win condition.

Before `target zone` is fully compiled,
victory is not checked.

Short formula:

```text
3 trumps in target zone -> victory pattern exists
fewer than 3 trumps -> no victory check
```

## 4. What the trumps compile

Each trump in `target zone`
contributes one path-glyph edge.

Example target trio:

```text
▽☴
☵☳
△☶
```

Because each minor-card has
a directed upper pair and a directed lower pair,
and cards are not reversible,

```text
☵☳ != ☳☵
```

this trio compiles not `3` cards,
but one directed:

```text
6-card visible chain requirement
```

## 5. Two full readings only

The compiled win pattern may be read in exactly two ways:

- full upper reading
- full lower reading

Mixed reading is illegal.

That means:

- all six checks use upper path-glyph positions
- or all six checks use lower path-glyph positions
- zig-zag reading is forbidden

Short formula:

```text
upper-only or lower-only
never mixed
```

## 6. Directed order law

Victory pattern is directional.

It is not enough that the right cards exist somewhere in chain.

They must appear:

- in the correct order
- in the correct slot sequence
- in one full legal reading orientation

So `manifest chain` is checked
as a directed sentence,
not as an unordered bag of matches.

Short formula:

```text
victory requires ordered manifestation
not unordered presence
```

## 7. Example reading

If `target zone` contains:

```text
▽☴
☵☳
△☶
```

then the game compiles two possible directed six-slot readings:

### Upper reading candidate

```text
▽☰
☴☶
☵☳
☳☱
△☰
☳△
```

### Lower reading candidate

```text
☱▽
△☴
☶☵
☰☳
☱△
☲☶
```

Victory occurs when the full six-card `manifest chain`
matches one complete legal compiled reading
in directed order.

This file fixes the structure of the law,
not the full derivation grammar for every possible trio.

## 8. Manifest surface law

Victory is not achieved in deck,
not in hand,
and not in hidden future alone.

Victory occurs only when the compiled target-law
becomes fully visible on the six-card `manifest chain`.

So:

```text
target zone writes destiny
manifest chain must embody it
```

This keeps victory fully inside the card machine.

## 9. Timing law

Victory is checked only after:

- `target zone` is fully compiled with `3` trumps
- world update for the turn is complete
- the played hand-card effect has resolved
- the played hand-card has been spent to `grave`

Victory is checked:

```text
once per turn
after full turn closure
```

This prevents false wins during intermediate sequence states.

Short formula:

```text
no mid-resolution victory
check only after full turn effect closure
```

## 10. Why this is not a puzzle

This victory system should not be read
as a static puzzle template only.

The target pattern is fixed enough to be readable,
but the player still reaches it through
a moving, interfering, living machine:

- world-strip keeps shifting
- hand effects keep rewriting access
- trumps disturb stability
- compiler pressure changes the meaning of the chain

So the win condition is not merely solved.

It is enacted through the machine.

Short formula:

```text
not a puzzle
a directed machine-state closure
```

## 11. Design consequence

This law makes victory:

- physical
- readable
- card-native
- topology-native
- compiler-based
- fully internal to ProcessCards materials

It requires no extra score track,
no token layer,
and no external win meter.

It uses only:

- target trumps
- minor directionality
- chain order
- turn timing
- table state

## 12. Current unresolved edge

This current branch still does not fully lock:

- the exact derivation grammar from every possible target trio
- whether some trumps may later modify victory checking
- whether alternative special win-laws may exist for rare trump states

But it does lock the current core:

```text
3 target trumps compile
1 six-slot directed pattern pair exists
manifest must match one whole reading
victory is checked after full turn closure
```

## 13. Final short formula

```text
3 trumps in target zone compile a directed 6-slot victory pattern.
Manifest chain must match one full upper or one full lower reading in order.
Victory is checked once per turn after full turn closure.
```
