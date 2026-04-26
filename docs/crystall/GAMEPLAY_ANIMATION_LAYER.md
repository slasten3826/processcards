# Gameplay Animation Layer

Статус:

```text
canonical crystall contract
```

Этот документ фиксирует обязательный animation layer
для перехода от board skeleton к настоящему gameplay runtime.

## 1. Core claim

Gameplay changes не должны выглядеть как телепорты.

Коротко:

```text
game truth may update in steps
visual state must visibly travel through those steps
```

То есть игрок должен видеть не только итог,
но и сам путь карты через машину.

## 2. Why this matters

Для `ProcessCards` это не cosmetic luxury.

Это важно потому что:

- игра читается как процесс
- порядок резолва имеет значение
- surface laws должны быть видны глазами
- игрок должен понимать,
  что именно куда ушло и что именно откуда поднялось

## 3. Truth state vs presentation state

Runtime должен разделять как минимум два слоя:

### A. Truth state

Это реальное состояние игры:

- где карта на самом деле находится
- какие зоны чем заполнены
- какой effect уже отработал

### B. Presentation state

Это видимая последовательность:

- как карта двигается
- как карта переворачивается
- как latent поднимается в manifest
- как refill приходит из deck

Короткая формула:

```text
logic owns truth
animation owns travel
```

## 4. Mandatory animation types

Для первого gameplay-capable слоя обязательны как минимум:

### 4.1. Move

Карта должна visibly перемещаться между зонами.

Примеры:

- `manifest -> grave`
- `hand -> manifest`
- `latent -> manifest`
- `deck -> latent`
- `deck -> hand`
- `trump resolve -> trump zone`

### 4.2. Flip

Переворот карты должен быть отдельной анимацией,
а не мгновенной сменой face.

Это касается:

- ручного flip в dev mode
- reveal on ascent
- reveal in target zone
- any future reveal effects

### 4.3. Reveal

Reveal может совпадать с flip,
но в системе он должен читаться как отдельный шаг изменения информации.

### 4.4. Lift

Подъём карты из `latent` в `manifest`
должен читаться как особый move-step,
а не как простой swap/teleport.

## 5. First gameplay sequence example

Для базового хода:

1. selected hand card targets `manifest[i]`
2. target manifest card moves to `grave`
3. played hand card moves into `manifest[i]`
4. если после этого chain law создаёт пустоту ниже,
   `latent[i]` visibly lifts into `manifest[i]`
5. `deck` visibly refills `latent[i]` face-down

То есть резолв должен читаться как sequence,
а не как мгновенная перестановка итоговых состояний.

## 6. Structural repair must also animate

Особенно важно:

```text
chain repair is not silent
chain repair must also be visible
```

Это касается:

- `latent -> manifest`
- `deck -> latent`
- `deck -> targets`

Если repair есть по table-law,
он должен быть виден в runtime.

## 7. Flip law

Flip уже сейчас нужно считать first-class animation event.

То есть:

- не просто `face_up = not face_up`
- а:
  - begin flip
  - midpoint face swap
  - settle

Точный easing later может меняться,
но сам animation event должен существовать с самого начала.

## 8. What this document does not require yet

Этот документ пока не требует:

- particle effects
- expensive shaders
- final Balatro-level juice
- final sound sync
- animated Start Game sequence in the immediate next slice

Он требует только:

```text
no critical gameplay change should read as a blind teleport
```

## 9. Deferred start-game sequence

Анимированная стартовая раскладка считается желательным будущим слоем,
но не обязательным для ближайшей реализации gameplay gesture.

То есть:

```text
animated Start Game is intended
but deferred until later polishing
```

Когда этот слой будет делаться,
он должен читать `Start Game` как sequence,
а не как blind board pop-in.

## 10. Platform consequence

Этот animation layer должен строиться так,
чтобы later оставаться совместимым с:

- PC
- Switch homebrew target

То есть:

- lightweight transforms
- simple timelines
- no platform-specific rendering tricks as a dependency

## 11. Implementation direction

На ближайшем кодовом слое желательно иметь:

- animation event queue
- card presentation objects
- separation of:
- requested move
- committed truth
- displayed interpolation

Это ещё не требует full engine,
но требует правильной архитектурной развилки.

## 12. Short formula

```text
cards do not teleport
move, flip, reveal, lift and refill are visible events
```
