[⊞ ◈] [☰ ☴ ☵ ☳ ☶ ☲ ☱ △]

# trumps

## 0. Статус

Trump design room for `ProcessCards`.

Это не `ProcessLang` canon.
Это не полный set file.
Это не финальный balance document.

Эта папка хранит отдельные trump-event candidates.

Источник truth для trump edges:

```text
stack-core/ProcessLang/canon.lua
```

## 1. Core Law

In `ProcessCards v4`:

```text
minor = state
trump = event
```

Trump should not behave like a normal stable card.

Trump should feel like:

- edge event
- topology disturbance
- board reconfiguration
- delayed escalation
- process anomaly

## 2. Design Constraints

Every trump effect must preserve closed economy:

- no external tokens
- no creatures
- no HP
- no mana
- no outside counters
- no non-card resources

Every trump must resolve using:

- card positions
- card order
- visibility
- zones
- relation checks
- local board structure
- grave as ordered residue

## 3. Board Invariant

Trump events may disturb the board,
but should usually return the game to a valid board state:

```text
5 manifest slots
5 latent slots
runtime capacity = 1
ordered grave
```

If a trump breaks this shape,
the break must be the point of the trump,
not an accidental rules hole.

## 4. Trump Zone

Resolved trumps do not go to grave by default.

They go to a separate `trump zone`.

This zone is not a buff row.
It is not a second grave.
It is not an active board state.

Cards in `trump zone` do nothing except count as resolved trumps.

Default direction:

```text
resolved trump -> trump zone
```

Current direction:

```text
trump zone capacity = 2
```

When the third resolved trump would enter `trump zone`,
perform a trump reset instead:

```text
shuffle deck + 2 trumps in trump zone + current resolved trump into deck
```

Then `trump zone` becomes empty.

Short reading:

```text
trump zone = two-event pressure chamber
```

This prevents every trump from resetting deck order,
while still allowing trumps to re-enter circulation.

## 5. Naming Law

Use `deck` as canonical ProcessCards term.

`library` may appear in raw design talk as a working synonym,
but canonical documents should normalize it to:

```text
deck
```

## 6. Files

- [TRUMP_ECOLOGY.md](TRUMP_ECOLOGY.md)
- [TRUMP_RESOLUTION_ORDER.md](TRUMP_RESOLUTION_ORDER.md)
- [RECAST.md](RECAST.md)
- [SHUFFLE.md](SHUFFLE.md)
- [EJECT.md](EJECT.md)

---

machines only. not for humans.
