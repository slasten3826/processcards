# Strong Combined Law

Статус:

```text
canonical table draft
```

Этот документ фиксирует базовый закон сильного хода у minor-карт.

Он не даёт ещё полную таблицу всех `100` карт.
Он задаёт правильную поверхность:

```text
strong is a combined reading of the pair
not two weak effects in sequence
```

## 0. Source of truth

Read this document as:

```text
how strong pairs are interpreted in principle
```

Read [STRONG_PAIR_TABLE.md](./STRONG_PAIR_TABLE.md) as:

```text
which pair families are currently documented with what maturity
```

## 0.5 Precedence

When strong-reading sources collide, use this order:

```text
1. explicit pair entry in STRONG_PAIR_TABLE.md
2. LOGIC override for pairs containing ☶
3. CONNECT override for pairs containing ☰
4. ordinary strong interpretation from STRONG_COMBINED_LAW.md
```

This order exists to prevent invented hybrid readings.

## 1. Core law

Сильный ход не читает карту как:

```text
operator A
then operator B
```

Сильный ход читает карту как:

```text
combined meaning of operator pair AB
```

То есть:

- `weak` = one operator reading
- `strong` = pair reading

## 2. What strong is not

Strong is not:

- two weak abilities one after another
- free double-cast
- arbitrary pick-any-two
- “draw 2 and then do whatever both symbols do separately”

`draw 2` остаётся baseline strong bonus,
но сам payload strong задаётся именно pair-reading.

## 3. Default prototype strong chassis

Current default prototype chassis for manifest-played minor cards:

```text
strong move
= replace target manifest card
+ draw 2
+ resolve one combined effect of the played pair
```

This is not a universal law for every future strong-capable surface.

It is the default chassis for:

```text
ordinary minor card played from hand into manifest chain
```

## 4. Pair classes

Не все пары одного типа.

Для strong их надо читать по классам.

### 4.1 Modifier pairs

These are pairs where one operator modifies the other.

Current clear modifier families:

- `☳ + X`
- `☶ + X`

#### `☳ + X`

`☳` does not contribute a standalone payload here.
It gives selection / scope / explicit choice to `X`.

Strong reading:

```text
choose how / where / what X resolves on
```

Examples:

- `☳☴` = choose which hidden card to observe
- `☳▽` = choose which hidden structure to flow
- `☳△` = choose what to manifest
- `☳☷` = choose what to dissolve

#### `☶ + X`

`☶` is a rule-exception operator.
It lets `X` resolve while breaking one native restriction of `X`.

Strong reading:

```text
X resolves in exception mode
```

Examples:

- `☶☴` = observe while ignoring one normal observe restriction
- `☶△` = manifest while ignoring one normal manifest restriction
- `☶☷` = dissolve while ignoring one normal dissolve restriction

### 4.2 Quiet-partner pairs

Current clear family:

- `☰ + X`

Bridge rule:

```text
whenever a pair contains ☰,
CONNECT_LAW has priority over ordinary strong-pair interpretation
```

Special note:

```text
☶☰ / ☰☶ is not plain CONNECT
it is CONNECT read under logic override
```

So:

- connect identity remains primary as family
- but the concrete reading is not ordinary pure connect
- it must be treated as logic-modified connect-family behavior

In single-card mode:

`☰` does not speak as a separate local payload.
The pair is read through the partner,
under the special law of a quiet connector card.

Short formula:

```text
single-card ☰X strong = partner-led reading, not X plus connect separately
```

In multi-card mode:

`☰` leaves ordinary strong reading entirely
and enters connect assembly law.

So multi-card `☰` should be treated as:

```text
special structural strong mode
```

not as ordinary pair resolution.

### 4.3 Symmetric fusion pairs

These are pairs where neither operator is merely a modifier,
and the strong reading should become one fused action.

Examples likely belong here:

- `☴☵`
- `☷△`
- `▽☴`
- `☵△`
- `☲☵`

Current law:

```text
these pairs must be written pair-by-pair
they must not be auto-expanded into two weak effects
```

This class is real,
but its internal table is not yet complete.

### 4.4 Self-pairs

Self-pairs are a separate class:

```text
AA
```

They should not be read as:

```text
A then A
```

They should be read as:

```text
special combined form of operator A with itself
```

Exact self-pair law stays outside this document for now.

Routing note:

For operational self-pair behavior also read:

- [DUPLICATE_LAW.md](./DUPLICATE_LAW.md)

## 5. Order law

For minor effect reading,
internal order is not the primary semantic carrier.

So by default:

```text
AB and BA may share one strong combined reading
```

unless a later explicit table-law says otherwise.

This is a major simplification law for minors.

## 6. Relation to weak

Weak and strong must not collapse into each other.

Weak asks:

```text
which one operator of this card is being read
```

Strong asks:

```text
what does this pair mean together
```

That distinction is structural,
not merely numerical.

## 7. Coding prohibition

Until a pair has a documented strong combined reading,
it must not be implemented as:

```text
first weak-like effect A
then weak-like effect B
```

That implementation is false.

If the pair is not yet known,
the honest state is:

```text
document first
defer code second
```

## 8. Current stable conclusions

Stable enough to keep:

- strong = combined pair reading
- not two weak abilities in sequence
- `☳ + X` is modifier-combination
- `☶ + X` is exception-combination
- `☰ + X` in single-card mode is quiet-partner combination
- multi-card `☰` is special structural mode
- self-pairs are their own class
- unresolved symmetric pairs must be documented pair-by-pair

## 9. Next table step

This document is the law of the layer.

The next document should be the table of actual pair families,
for example:

```text
docs/table/STRONG_PAIR_TABLE.md
```

That file should list:

- clear pairs
- rough pairs
- unresolved pairs

without pretending the whole matrix is already solved.

## 10. Short formula

```text
strong = one combined reading of the pair
not two weak reads chained together
```
