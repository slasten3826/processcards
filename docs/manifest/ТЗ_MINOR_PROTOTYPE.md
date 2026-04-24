# ТЗ: Minor Prototype

Это техническое задание на первый настоящий прототип `ProcessCards`.

Это не полный rulesheet.
Это не implementation plan.
Это рабочий контракт на первую собираемую машину.

## 1. Цель

Собрать первый играбельный прототип,
в который можно играть руками и мышкой,
и который честно моделирует физически исполнимую карточную машину.

Ключевой scope:

```text
100 minor-карт
без active trump-layer
```

## 2. Формат прототипа

Первый настоящий runtime:

```text
Lua + LÖVE
```

Прототип должен быть:

- кликабельным;
- визуально читаемым;
- пригодным для playtest;
- faithful к картонной версии игры.

## 3. Базовое ограничение

Главный закон:

```text
if cardboard cannot do it, prototype cannot rely on it
```

Следствия:

- нельзя строить механику на скрытой цифровой памяти;
- нельзя делать core action, который физически невозможен на реальных картах;
- нельзя держать rules truth в невидимом состоянии без карточного выражения;
- нельзя компенсировать неясные правила цифровыми удобствами.

Прототип может:

- подсвечивать валидные действия;
- считать relation checks;
- вести лог;
- помогать видеть порядок grave.

Прототип не может:

- знать за игрока скрытые карты без легального наблюдения;
- делать магические rewrites без карточного аналога;
- превращать физически сложную процедуру в “просто кнопку”, если сама процедура несёт игровой смысл.

## 4. Игровой scope

В первом прототипе обязаны существовать:

- `deck`
- `hand`
- `manifest row`
- `latent row`
- `grave`
- `targets`
- `runtime lane`
- `log`

В первом прототипе не обязаны играть:

- trumps;
- trump zone;
- active target compiler semantics;
- full operator-specific card texts.

## 5. Board model

Ядро стола:

```text
5 columns x 2 layers
```

Каждая колонка содержит:

- 1 manifest slot
- 1 latent slot

Инварианты:

- manifest row всегда 5 slots;
- latent row всегда 5 slots;
- runtime capacity = 1;
- grave ordered;
- targets = 3 ordered slots.

## 6. Action set

Первый playable action surface:

- `place weak`
- `place strong`
- `discard`
- `pass`

Никаких других player actions в первый сборочный слой не добавлять.

## 7. Rule minimum

Прототип обязан реализовать:

- deck из 100 ordered minor pairs;
- initial setup;
- weak relation;
- strong relation;
- mirror relation как диагностическую структуру;
- weak card effect resolution;
- strong card effect resolution;
- bounded action tail;
- board-shape preservation;
- grave order preservation.

## 8. Prototype assumptions

Для первого playable среза разрешены такие локальные допущения:

### Weak

```text
target manifest card -> grave
played hand card -> target manifest slot
resolve 1 card effect
draw 0
```

### Strong

```text
target manifest card -> grave
played hand card -> target manifest slot
draw 2
resolve 1-2 card effects
```

### Discard

```text
hand -> grave
draw 0
```

### Pass

```text
legal but tempo-negative
```

Все эти допущения считаются provisional
и должны быть явно названы в документации и коде.

Дополнительный закон:

```text
physical card identity may remain ordered
effect reading may be order-insensitive
```

## 9. UI requirements

Интерфейс должен позволять:

- увидеть весь стол сразу;
- выбрать action;
- выбрать карту из hand;
- выбрать колонку;
- увидеть, валиден ход или нет;
- увидеть, как обновились зоны после действия;
- прочитать краткий log.

UI не должен:

- прятать критическую rules truth;
- жить отдельно от физической логики стола;
- быть “красивым раньше, чем понятным”.

## 10. Definition of done

Первый minor prototype считается собранным,
если одновременно выполняются условия:

1. игра запускается в `LÖVE`;
2. setup создаёт валидный стол;
3. игрок может делать `weak/strong/discard/pass`;
4. relation checks работают;
5. board shape не ломается;
6. grave остаётся ordered;
7. прототип не опирается на purely digital convenience;
8. в него уже можно сыграть серию ходов как в настоящую physical-card machine.

## 11. Что не входит в это ТЗ

Не входит:

- trumps;
- RECAST/SHUFFLE/EJECT;
- target compiler semantics beyond shell;
- polished art;
- full balancing;
- production UX polish.

## 12. Short formula

```text
first build = playable physical-card-faithful minor machine in Lua + LÖVE
```
