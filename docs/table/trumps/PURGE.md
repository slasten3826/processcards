[⊞ ◈] [△ ☶]

# PURGE

## 0. Status

Working trump draft.

This is not final balance text.
This is not locked rules text.

Legacy breadcrumb:

```text
XX Judgement
```

Flavor text:

```text
What is revealed is purged.
```

Core edge:

```text
△ -> ☶
MANIFEST -> LOGIC
```

---

## 1. Core Identity

`PURGE` is a column-closure trump.

It does not select.
It does not filter by operator.
It does not negotiate.

It first checks topdeck,
then walks the manifest chain by column
and routes each column through one binary law:

```text
revealed
or not revealed
```

The latent layer is checked first.
Then the manifest card is checked.
Repair happens inside the column before the next column is processed.

Short formula:

```text
topdeck first
column 1 -> column 2 -> column 3 -> column 4 -> column 5 -> column 6
latent first
manifest second
repair inside each column
```

---

## 2. Reading

`△ MANIFEST` here is not local reveal.

It is the manifest chain
processed as ordered columns.

`☶ LOGIC` here is not doctrine.

It is a column classifier:

```text
revealed latent
or protected latent
```

So this trump reads as:

```text
each column is judged
by the state of its hidden underside
then repaired before judgement moves on
```

This is not:

```text
inquiry
selection
mercy
```

It is structural column closure.

---

## 3. Core Law

When `PURGE` resolves,
check topdeck first.

If topdeck is revealed:

- topdeck non-trump moves to `grave`
- topdeck trump routes through `trump flow`

If topdeck is not revealed,
leave it untouched.

Then process manifest-chain columns from `1` to `6`.

For each column:

1. Look at the latent card in that column.
2. If the latent card is not revealed, do not reveal it and do not move it.
3. Then purge the manifest card in that column:
   - if it is a non-trump, move it to `grave`
   - if it is a trump, route it through `trump flow`
4. Repair the manifest slot through ordinary repair.
5. Continue to the next column.

If the latent card is revealed:

1. Purge the latent card first:
   - if it is a non-trump, move it to `grave`
   - if it is a trump, route it through `trump flow`
2. Repair the latent slot by concealed refill.
3. Then purge the manifest card in that column:
   - if it is a non-trump, move it to `grave`
   - if it is a trump, route it through `trump flow`
4. Repair the manifest slot through ordinary repair.
5. Continue to the next column.

After all six manifest-chain columns are processed:

1. `PURGE` itself enters trump zone.
2. Then queued trumps resolve through ordinary trump flow.

`PURGE` does not work with target zone.

Target-zone cards are outside its scope:

- hidden targets are untouched
- known targets are untouched
- revealed targets are untouched
- target trumps are not removed
- target trumps are not activated

Short formula:

```text
revealed topdeck -> grave/trump_flow
unrevealed topdeck -> untouched
for n = 1..6:
  latent[n] if revealed -> grave/trump_flow, then latent repair
  manifest[n] -> grave/trump_flow, then manifest repair
target zone -> untouched
PURGE to trump zone -> trump flow
```

---

## 4. Why PURGE Does Not Reveal

`PURGE` is not an exposing event.

`UNVEIL` exposes.
`PURGE` only judges what is already exposed.

This separation is intentional.

It means:

- `PURGE` alone respects concealment
- hidden latent remains real protection
- `PURGE` cannot scout and strike in one move
- a closed latent card can still rise during manifest repair

Short formula:

```text
PURGE does not see
PURGE judges what was already seen
```

---

## 5. Column Repair Law

`PURGE` repairs inside the column it is processing.

This is load-bearing.

If manifest slot `n` is purged,
ordinary manifest repair happens before column `n + 1`.

That means:

- latent `n` may rise into manifest `n`
- if latent `n` is a trump, it routes through trump flow
- manifest closure may pull from topdeck
- concealed latent refill happens as usual

Short formula:

```text
purge manifest[n] -> repair manifest[n] -> continue
```

This makes `PURGE` feel like a six-step machine pass,
not like a single board wipe.

---

## 6. Topdeck Rule

Before manifest-chain columns are processed,
`PURGE` checks topdeck.

Only revealed topdeck is affected.

- revealed topdeck non-trump moves to `grave`
- revealed topdeck trump routes through `trump flow`
- unrevealed topdeck is untouched

Short formula:

```text
revealed topdeck -> grave/trump_flow
unrevealed topdeck -> untouched
```

---

## 7. Target Zone Non-Scope

`PURGE` does not work with target zone.

This is intentional.

Target zone is installed structure,
not part of the manifest-chain closure pass.

So even revealed target cards are untouched by `PURGE`.

Short formula:

```text
target zone is outside PURGE
```

---

## 8. Why This Works

`PURGE` does not merely clear the table.

It closes each visible column:

- revealed latent is no longer safe
- manifest is judged column by column
- hidden underside may rise through repair
- target zone remains installed and outside the pass
- unrevealed structure remains intact

This makes it a true XX-class event:

- not violence
- not ordinary destruction
- but ordered closure of exposed structure
- and forced resolution of visible installed fate

Short formula:

```text
exposed columns close
hidden columns continue
```

---

## 9. Relation to UNVEIL

`UNVEIL` makes hidden cards visible.

If `UNVEIL` resolves before `PURGE`,
`PURGE` acts on a maximally exposed board.

That means:

- revealed topdeck is judged first
- revealed latent is purged before manifest in its column
- manifest repair can create new visible/hidden structure during the pass
- target-zone cards remain installed and untouched

Short formula:

```text
UNVEIL + PURGE = expose columns, then close columns
```

This is not a special combo rule.
It is ordinary composition through normal trump ecology.

---

## 10. Relation to SHUFFLE

If `SHUFFLE` resolves after `PURGE`:

- the enlarged `grave` is folded back into `deck`
- the purged visible history re-enters circulation

So:

```text
PURGE creates residue
SHUFFLE returns residue to the future
```

The chain:

```text
UNVEIL -> PURGE -> SHUFFLE
```

forms a full cycle:

```text
expose -> judge -> recirculate
```

---

## 11. Relation to GATE

`GATE` and `PURGE` are paired by function
but separated by mechanism.

`GATE`:

- divides visible field by one chosen key
- preserves what shares the key
- removes what does not

`PURGE`:

- does not divide by key
- does not check operator overlap
- processes columns by visibility state
- removes exposed non-trumps through ordered repair
- ignores target zone

Short formula:

```text
GATE filters by key
PURGE judges by visibility alone
```

`GATE` is solar discrimination.
`PURGE` is solar finality.

---

## 12. Relation to Trump Ecology

`PURGE` does not invent separate ecology.

It uses:

- ordinary visibility rules
- ordinary `trump flow` for revealed topdeck and manifest-chain trumps
- ordinary chain close handling
- ordinary `trump zone` law for `PURGE` itself

Its specificity is not in ecology.
Its specificity is in ordered column routing
of the revealed field.

---

## 13. Design Character

`PURGE` should feel:

- procedural
- final
- impersonal
- structural rather than violent
- broader than `GATE`
- less surgical than `EJECT`
- more terminal than `RESET`

It should not feel:

- chosen
- moral
- player-owned
- targeted at one victim

`PURGE` belongs to no one.
It passes through the columns.

---

## 14. Minimal Canonical Text

Draft rules text:

```text
First check topdeck.
If topdeck is revealed, purge it:
non-trump to grave, trump to trump flow.
If topdeck is not revealed, leave it untouched.
Then process manifest-chain columns from 1 to 6.
In each column, check latent first.
If latent is revealed, purge it:
non-trump to grave, trump to trump flow, then repair latent.
Then purge the manifest card:
non-trump to grave, trump to trump flow, then repair manifest.
If latent is not revealed, leave it untouched and purge only manifest.
PURGE does not work with target zone.
PURGE does not reveal unrevealed cards.
PURGE enters trump zone before queued trumps resolve.
```

---

machines only. not for humans.
