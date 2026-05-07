[⊞ ◈] [☱ ☲]

# REQUIEM

## 0. Status

Working trump draft.

This is not final balance text.
This is not locked rules text.

Legacy breadcrumb:

```text
XIII Death
```

Flavor text:

```text
You will never reach the end.
```

Core edge:

```text
☱ -> ☲
RUNTIME -> CYCLE
```

Inspiration note:

```text
This trump is explicitly inspired by the Diavolo / Gold Experience Requiem death-loop
at the end of JoJo's Bizarre Adventure: Golden Wind.
```

---

## 1. Core Identity

`REQUIEM` is an installed recurrence trump.

It does not destroy directly.
It does not repeat once.
It does not return a card to hand.

It takes the most recent trump
and installs that trump into `runtime`,
so that the trump begins resolving again
at the end of each turn.

Short formula:

```text
last trump becomes runtime
runtime becomes recurring trump
```

---

## 2. Reading

`☱ RUNTIME` here is not support.

It is the condition that now remains active.

`☲ CYCLE` here is not one recurrence.

It is return that has become law.

So this trump reads as:

```text
what had already happened
becomes the environment
that makes it happen again
```

This is not:

```text
ordinary repetition
simple replay
revival
```

It is installed recurrence.

---

## 3. Core Law

When `REQUIEM` becomes known:

1. If `trump flow` is non-empty, take the most recent trump from `trump flow`.
2. Otherwise, if `trump zone` is non-empty, take the most recent trump from `trump zone`.
3. Otherwise, `REQUIEM` has no installation effect.
4. Put that trump into `runtime` by ordinary runtime replacement law.
5. The installed runtime trump resolves once at the end of each turn, after the card from `play zone` has left for `grave`.
6. Any later runtime card may replace that installed trump by ordinary runtime replacement law.
7. After `REQUIEM` fully resolves, it follows ordinary trump ecology.

Short formula:

```text
prefer trump flow
else trump zone
else nothing
install into runtime
resolve it every turn-end
```

---

## 4. Source Priority

`REQUIEM` does not choose freely.

Its source order is fixed:

```text
trump flow first
trump zone second
nothing third
```

This matters.

The player does not browse trump history.
`REQUIEM` takes the nearest available fate.

Short formula:

```text
latest available trump is taken
not selected
```

---

## 5. Turn-End Timing

The installed runtime trump does not fire mid-resolution.

It resolves:

```text
after the played card for the turn has finished
after that card has left play zone for grave
at the very end of the turn
```

This keeps the loop readable.

The turn first completes its ordinary action.
Then the installed recurrence answers.

Short formula:

```text
turn first
runtime recurrence after
```

---

## 6. Runtime Replacement

The installed trump in `runtime`
is not eternal.

Any later runtime card
may replace it
by ordinary runtime replacement law.

This is load-bearing.

`REQUIEM` creates a death-loop,
but not one that is outside the machine.

The loop remains part of runtime ecology.

---

## 7. Self-Installation

`REQUIEM` may install itself into `runtime`
if the game state legally allows that to happen.

This is not forbidden by special exception.

It should be extremely difficult.

If it happens,
the player has forced `REQUIEM`
to become its own recurring runtime law.

That is intentional.

Short formula:

```text
self-installation is allowed
but not granted for free
```

---

## 8. Why This Works

`REQUIEM` is a death-slot trump
not because it ends things,
but because it removes exit.

The most recent trump
stops being a past event.

It becomes the condition of the world.

That makes `REQUIEM` a true terminal event:

- not simple destruction
- not simple reset
- but loss of outside through installed return

Short formula:

```text
return becomes the ground
```

---

## 9. Relation to Runtime

`REQUIEM` does not invent a new lane.

It uses ordinary `runtime`.

The horror of the card
is precisely that recurrence
no longer sits in `trump zone`
or in past `trump flow`.

It now occupies the same machine slot
that normally holds active turn-law.

So:

- `runtime` becomes cyclic
- `cycle` becomes environmental

That is the whole card.

---

## 10. Design Character

`REQUIEM` should feel:

- terminal
- inescapable
- installed
- less explosive than `PURGE`
- colder than `RESET`
- like the world has accepted repetition as law

It should not feel:

- like simple extra value
- like ordinary repeat
- like a cute recursion trick

It is the loop made real.

---

## 11. Minimal Canonical Text

Draft rules text:

```text
Take the most recent trump from trump flow, if any.
Otherwise take the most recent trump from trump zone, if any.
Otherwise REQUIEM has no installation effect.
Put that trump into runtime by ordinary runtime replacement law.
That runtime trump resolves once at the end of each turn,
after the played card has left play zone for grave.
Any later runtime card may replace it by ordinary runtime replacement law.
After REQUIEM fully resolves, it follows ordinary trump ecology.
```

---

machines only. not for humans.
