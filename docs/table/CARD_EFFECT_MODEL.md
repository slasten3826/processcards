# Card Effect Model

Это table-документ о том,
как сейчас читается effect layer minor-карт.

Часть его содержимого теперь superseded более новыми canonical docs.

Current priority:

- [OPERATOR_MODEL.md](./OPERATOR_MODEL.md)
- [CONNECT_LAW.md](./CONNECT_LAW.md)
- [STRONG_COMBINED_LAW.md](./STRONG_COMBINED_LAW.md)
- [STRONG_PAIR_TABLE.md](./STRONG_PAIR_TABLE.md)
- this file as older effect-model draft

То есть этот документ теперь:

```text
legacy-supporting table draft
```

## 1. Physical card vs effect reading

Minor deck физически остаётся такой:

```text
100 cards = 10 x 10 ordered pairs
```

То есть:

- `☵☳` и `☳☵` — две разные физические карты в колоде;
- `▽▽` и `▽▽` — две разные физические копии одной и той же self-pair card.

Но effect reading minor-карты сейчас читается так:

```text
operator order does not matter
```

То есть:

```text
☵☳ and ☳☵ belong to the same effect family
☴☳ and ☳☴ belong to the same effect family
```

Short formula:

```text
physical identity = ordered pair
effect identity = unordered pair
```

## 2. Two operator layers

У каждой minor-карты есть два operator layers:

- number/operator layer
- suit/operator layer

Но для prototype-level чтения их удобнее понимать просто как:

```text
two operators on one card
```

Не как “главный” и “вторичный”,
а как два potential effects одной карты.

## 3. Weak effect model

Weak move даёт:

```text
replace targeted manifest card
use 1 effect of the played card
draw 0
```

То есть игрок:

1. делает weak-legal replacement в manifest chain;
2. выбирает один effect этой карты;
3. разыгрывает только его.

## 4. Strong effect model

This section is now partially deprecated.

Live canonical reading of strong should be taken from:

- [STRONG_COMBINED_LAW.md](./STRONG_COMBINED_LAW.md)
- [STRONG_PAIR_TABLE.md](./STRONG_PAIR_TABLE.md)

Legacy wording used to say:

```text
replace targeted manifest card
draw 2
use 1-2 effects of the played card
```

That wording should now be treated as deprecated draft.

Current corrected reading is:

```text
replace targeted manifest card
draw 2
resolve one combined pair reading
```

То есть strong больше не читается как “два weak-like эффекта подряд”.

## 5. Not every operator must work alone

Ключевой текущий закон:

```text
not every operator must be self-sufficient on weak
```

Это особенно важно для `☳ CHOOSE`.

Если оператор сам по себе не даёт meaningful standalone weak effect,
он всё ещё может быть useful как часть combined strong reading.

## 6. Rough operator status

Текущий rough status по тем операторам, которые уже обсуждены:

### `☴ OBSERVE`

Current reading:

```text
look at one hidden card
```

Полезное локальное ограничение:

```text
standalone ☴ can read hidden card of the same column
```

### `☳ CHOOSE`

Current reading:

```text
choose / target
```

Но сам по себе `☳` сейчас не выглядит self-sufficient weak effect.

Поэтому честное текущее состояние такое:

```text
☳ is weak-fragile alone
☳ becomes meaningful in combination
```

### `☴ + ☳`

Current strong reading candidate:

```text
choose which hidden card to observe
```

Отсюда:

- standalone `☴` может быть локальным observe;
- `☳ + ☴` together can widen choice.

### `☷ DISSOLVE`

Current rough reading:

```text
send one field card to grave
```

### `☵ ENCODE`

Current rough reading:

```text
reorder hidden cards / manipulate deck order / scry-like structure work
```

### `☲ CYCLE`

Current rough reading:

```text
draw a card, discard a card
```

### `☱ RUNTIME`

Current rough reading:

```text
place or move card into runtime lane
```

### `△ MANIFEST`

Current rough reading:

```text
reveal hidden card
```

### Legacy unclear block

- `▽ FLOW`
- `☰ CONNECT`  # superseded by CONNECT_LAW.md
- `☶ LOGIC`

Их не надо фальшиво финализировать раньше времени.

## 7. Example

Card:

```text
☴☳
```

Weak:

- legal replacement in manifest;
- use one effect only;
- likely `☴` as standalone local observe;
- `☳` by itself may remain weak-fragile.

Strong:

- legal replacement in manifest;
- draw 2;
- use combined reading;
- current candidate reading:

```text
choose which hidden card to observe
```

## 8. Short formula

```text
weak = one effect
strong = draw 2 + one combined pair reading
```

machines only. not for humans.
