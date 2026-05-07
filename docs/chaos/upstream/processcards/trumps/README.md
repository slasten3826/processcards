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

Flavor text may exist as a separate card-identity layer.

It should not replace:

- core reading
- mechanical law
- canonical resolution text

It should compress the event into one short memorable line.

## 3. Board Invariant

Trump events may disturb the board,
but should usually return the game to a valid board state:

```text
6 manifest slots
6 latent slots
runtime capacity = 1
ordered grave
```

If a trump breaks this shape,
the break must be the point of the trump,
not an accidental rules hole.

## 4. Trump Zone

Resolved trumps do not go to grave by default.

They close through the trump engine:

- ordinary chains park into `trump zone`
- halted chains flush non-`HALT` trumps back into `deck`
- `HALT` itself still parks into `trump zone`

This zone is not a buff row.
It is not a second grave.
It is not an active board state.

Cards in `trump zone` do nothing except count as resolved trumps.

Current direction:

```text
trumps remain in-flight until chain close
ordinary close -> trump zone
halted close -> deck flush + HALT to trump zone
```

Trump zone capacity:

```text
2
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
- [FOOL.md](FOOL.md)
- [EJECT.md](EJECT.md)
- [RECAST.md](RECAST.md)
- [SHUFFLE.md](SHUFFLE.md)
- [RESET.md](RESET.md)
- [UNVEIL.md](UNVEIL.md)
- [ORACLE.md](ORACLE.md)
- [HALT.md](HALT.md)
- [SWAP.md](SWAP.md)
- [WARRANT.md](WARRANT.md)
- [REPEAT.md](REPEAT.md)
- [UNBOUND.md](UNBOUND.md)
- [TIGEL.md](TIGEL.md)
- [RUSH.md](RUSH.md)
- [ENOUGH.md](ENOUGH.md)
- [GRANT.md](GRANT.md)
- [GATE.md](GATE.md)
- [PURGE.md](PURGE.md)
- [CANON.md](CANON.md)
- [MAXIMIZE.md](MAXIMIZE.md)
- [ERROR.md](ERROR.md)
- [REQUIEM.md](REQUIEM.md)

---

machines only. not for humans.
