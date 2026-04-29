# Trump Flow Presentation Contract

Статус:

```text
canonical crystall presentation contract
```

Этот документ фиксирует,
как `trump flow` должен читаться
в current runtime branch.

## 1. Core decision

`trump flow` не должен быть
overlay поверх already occupied table band.

Он должен быть:

```text
its own explicit top-level zone
```

отдельной от:

- `targets`
- `trump zone`

## 2. Zone order

Current top reading должен быть таким:

1. `trump flow`
2. `targets`
3. `trump zone`

Коротко:

```text
active anomaly
-> compiler
-> resolved residue
```

## 3. Geometry

`trump flow` должен иметь:

- фиксированную ширину
- `3` видимых слота
- зона не должна расширяться вместе с очередью

Если later active trumps станет больше трёх,
карты должны:

- наезжать друг на друга
- но не раздувать саму зону

## 4. Control law

`△` в `trump flow` читается не как обычная кнопка,
а как:

```text
allow the chain to proceed
```

То есть:

- если pending trump event есть,
  `△` разрешает следующий шаг chain
- trump flow не должен auto-run
- игрок должен явно видеть и подтверждать
  каждый отдельный trump step

## 5. Why explicit stepping matters

Это критично потому что игрок должен:

- видеть, что именно сейчас pending
- понимать порядок событий
- читать каждую карту в цепочке

Коротко:

```text
the player must see each trump event
not a blurred automatic chain
```

## 6. Visual language

`trump flow` должен выделяться
не чужим UI color,
а внутренним языком игры.

Current canonical reading:

- zone outline uses train motion
- train uses colors of cards currently in the flow
- colors concatenate by queue content

## 7. Color accumulation law

Если в `trump flow` лежит:

### 1 trump

train uses:

- `2` operator colors

### 2 trumps

train uses:

- `4` operator colors

### 3 trumps

train uses:

- `6` operator colors

То есть zone train выражает
не только сам факт flow,
но и текущую плотность аномальной очереди.

## 8. Speed law

Train у `trump flow`
должен работать заметно быстрее,
чем current train у:

- legal hand cards
- committed manifest card

Current intended reading:

```text
about 2x faster than hand/manifest train
```

## 9. Zone-state law

Если `trump flow` пуст,
зона может оставаться на столе,
но должна читаться тихо.

Если `trump flow` не пуст,
она становится visibly active.

То есть:

```text
quiet when empty
dominant when active
```

## 10. Card vs zone reading

Важно:

- train описывает состояние всей зоны `trump flow`
- позиции карт внутри зоны описывают queue order
- `△` продвигает очередь дальше

Коротко:

```text
zone train = flow exists
card order = queue order
triangle glyph = advance queue
```

## 11. Short formula

```text
Trump flow is its own fixed top-level zone.
It shows up to three visible slots.
Its outline runs as a fast color-train built from all trumps currently in the flow.
The triangle glyph advances the chain one event at a time.
```
