# Operator Model

Статус:

```text
candidate-for-legacy table law
pending rewrite after turn-law stabilization
```

Этот документ фиксирует старую каноническую модель операторов minor-карт
до стабилизации нового topology-first turn-law.

Он всё ещё полезен как semantic source,
но больше не должен читаться как полностью живой source of truth
для current gameplay branch.

Current move transition branch:

- [TURN_LAW_V2.md](./TURN_LAW_V2.md)
- [TURN_SEQUENCE_LAW_V2.md](./TURN_SEQUENCE_LAW_V2.md)
- [MOVE_FIT_LAW.md](./MOVE_FIT_LAW.md)

Он не финализирует каждый оператор до последней формулы,
но задаёт текущий канон operator layer.

Если старые operator drafts расходятся с этим документом,
приоритет пока остаётся у этого файла.

Но если этот файл расходится с новой move-моделью,
приоритет уже у:

- [TURN_LAW_V2.md](./TURN_LAW_V2.md)
- [TURN_SEQUENCE_LAW_V2.md](./TURN_SEQUENCE_LAW_V2.md)
- newer operator rewrites once they are written

## 1. Current gameplay frame

Текущий gameplay frame:

- manifest table = 10 карт total
- arranged as `5 columns x 2 rows`
- `5` open cards in visible row
- `5` hidden cards in latent row beneath them

Главное уточнение:

```text
open manifest row is a toroidal ring
```

То есть:

- slot 1 adjacent to slot 2 and slot 5
- slot 5 adjacent to slot 4 and slot 1

Это canonical law.

## 2. Weak and strong play

Weak / strong distinction remains core.

### Weak play

- lower commitment
- usually local or narrow effect
- no baseline draw bonus
- resolves through a smaller card reading

### Strong play

- higher commitment
- stronger structure or stronger resolution
- baseline rule = `draw 2`
- for mixed cards, strong play opens the broader card reading

## 3. Card effect law

Minor-card effect law now reads:

```text
weak = resolve 1 effect of the card
strong = draw 2 + resolve 1-2 effects of the card
```

Important:

- physical card identity may remain ordered
- effect family reading may ignore internal order

So:

```text
☵☳ and ☳☵ are different physical cards
but may share one effect family
```

## 4. Operator draft state

Not every operator is equally finalized,
but the following model is current canon.

### `▽ FLOW`

Still under design.

Main direction:

- not simple draw
- not generic value gain
- flow / shift / continuation / forced movement
- likely interacts with hidden zones, deck order, target zone, or latent structures
- should feel mandatory rather than optional

### `☰ CONNECT`

This operator now has a canonical identity.

Core idea:

```text
☰ is primarily a hand-side assembly operator
```

It does not primarily produce a local board-side effect by itself.

It has split identity:

- single-card mode: `☰` itself is quiet, partner operator resolves
- multi-card mode: `☰` becomes a hand-based segment compiler

Detailed law is recorded in:

- [CONNECT_LAW.md](./CONNECT_LAW.md)

### `☷ DISSOLVE`

Current canonical direction:

- removal
- severance
- breakage
- send one field card to grave

Still open for refinement,
but this family is stable enough to keep.

### `☵ ENCODE`

Current canonical direction:

- manipulation of hidden information
- reordering hidden cards
- deck arrangement
- concealed restructuring
- latent-space control

### `☳ CHOOSE`

Current canonical direction:

- weak resolution may intentionally be null
- this is not treated as a bug
- cards with `☳` may have a safe mode in weak play
- `☳` becomes grammatically powerful in combination

Short formula:

```text
☳ is weak-fragile alone
☳ becomes meaningful in combination
```

### `☴ OBSERVE`

Current canonical direction:

- look at a hidden card
- inspect without necessarily changing state
- knowledge without forced manifestation

### `☲ CYCLE`

Current canonical direction:

- draw/discard style exchange
- replace one thing with another
- rotation
- churn
- turnover

### `☶ LOGIC`

Still under design.

Current direction:

- exception handling
- rule-bending
- structural reinterpretation
- changing what counts as valid resolution

### `☱ RUNTIME`

Current canonical direction:

- cards that leave normal operator flow
- enter runtime field / persistent field
- should feel installed rather than simply resolved

### `△ MANIFEST`

Current canonical direction:

- reveal hidden card
- turn latent into explicit state
- keep it on table as known information

## 5. Strong combined readings

Current canonical allowance:

- not every operator must be self-sufficient on weak
- strong may open broader combined readings

Example:

```text
☴☳ or ☳☴
```

Current canonical reading candidate:

```text
choose which hidden card to observe
```

This means:

- standalone `☴` can still be local observe
- `☳ + ☴` together can widen scope/choice

## 6. Legacy relation

If older files disagree with this operator model,
treat those older readings as legacy.

Canonical priority:

```text
OPERATOR_MODEL.md
-> CONNECT_LAW.md
-> older table drafts
```

## 7. Short formula

```text
operators are no longer just flavor labels
they are the active grammar of weak and strong card resolution
```

Короткий вывод статуса:

```text
operator identity notes remain useful
but the gameplay chassis in this file is no longer fully current
```
