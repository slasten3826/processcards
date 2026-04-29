# Hand Frame Visual Contract

Статус:

```text
canonical crystall visual contract
```

Этот документ фиксирует,
как должна читаться рамка карты руки
в current gameplay loop.

## 1. Core decision

У hand-card не должно быть
нескольких наложенных gameplay-рамок.

Нужна:

```text
one frame
three behavior modes
```

То есть состояние карты руки
меняет не количество рамок,
а поведение одной основной рамки.

## 2. The three hand states

### `inert`

Карта:

- не legal для текущего commit
- не armed

Вид:

- рамка статична
- обычное operator-colored base reading

### `legal`

Карта:

- legal для текущего commit
- ещё не armed

Вид:

- та же самая рамка
- начинает мягко дышать
- дыхание идёт между двумя operator colors карты

Коротко:

```text
legal = breathing frame
```

### `armed`

Карта:

- legal
- явно выбрана игроком

Вид:

- та же самая рамка
- больше не дышит плавно
- дышит в operator colors
- вокруг карты есть мягкий световой halo
- halo не должен читаться как набор дополнительных line-рамок
- это back-glow, а не geometry stack

Коротко:

```text
armed = breathing frame + soft halo
```

## 3. Color law

Gameplay frame не должен
вводить новый внешний UI color language.

Он должен использовать:

```text
the two operator colors of the card itself
```

То есть:

- `legal` живёт внутри той же операторной палитры
- `armed` тоже живёт внутри той же операторной палитры

## 4. Motion difference

Главное различие между `legal` и `armed`
должно читаться не как
"больше рамок" или "другой случайный цвет",
а как разница в типе движения.

### `legal`

- дискретное
- медленное
- running / clockwise

### `armed`

- плавное
- заметное
- breathing with glow

## 5. What must not happen

Не нужно делать:

- затемнение inert-карт
- отдельную вторую gameplay-рамку поверх основной
- внешний gold UI border как основной язык armed-state
- pulsing of the whole card face
- halo как набор жёстких прямоугольных ступеней

Коротко:

```text
the card face stays readable
the frame carries the state
```

## 6. Commit relation

Committed `manifest` card
не должна использовать ту же hand-frame grammar.

Её состояние должно читаться
другим способом:

- через slot emphasis
- или through external highlight

Но не через hand-frame mode system.

## 7. Implementation reading

Runtime implementation может читать это так:

- `inert` = static base frame
- `legal` = animated segmented two-color flow over the same frame
- `armed` = animated color-breath over the same frame plus soft back-glow

## 8. Card surface shape

Лицо карты не должно рисоваться
как прямоугольный color block
под скруглённой рамкой.

Face fill должен быть:

```text
clipped to the same rounded card shape
```

То есть:

- rounded border
- rounded face fill
- glyphs and text поверх уже clipped card surface

Это часть каноничного current render reading,
а не случайная техническая деталь.

## 9. Short formula

```text
One hand-card frame.
Inert is static.
Legal runs slowly in segmented operator colors clockwise.
Armed breathes in operator colors and emits a soft halo.
Card face fill is clipped to the rounded card shape.
```
