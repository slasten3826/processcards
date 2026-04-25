# Layer 1 Board Skeleton Spec

Статус:

```text
canonical crystall contract
```

Этот документ фиксирует самый первый слой разработки.

Это слой:

```text
table surface before gameplay law
```

То есть:

- зоны уже существуют
- карты уже существуют как сущности
- картами уже можно манипулировать
- но игровые правила ещё не включены

## 1. Goal

Собрать первый рабочий скелет стола,
в котором уже есть:

- карточные сущности
- все главные зоны
- ручные базовые операции
- визуально читаемый стол

Но ещё нет:

- weak/strong legality
- operator payloads
- victory logic
- active trump gameplay

## 2. What this layer is

This layer is:

- board skeleton
- zone skeleton
- card entity skeleton
- movement skeleton

This layer is not:

- gameplay-complete prototype
- rules engine
- operator engine
- strong-pair engine

## 3. Required zones

На первом слое уже должны существовать:

- `deck`
- `hand`
- `grave`
- `runtime`
- `targets`
- `manifest row`
- `latent row`
- `trump zone`

Все эти зоны нужны сразу как board reality,
даже если их gameplay law ещё не активирован.

## 4. Card entities

Карты на этом слое считаются уже реальными сущностями.

Минимально карта должна иметь:

- `id`
- `face state` (`face-up` / `face-down`)
- `current zone`
- `slot/index` if zone is ordered

На этом этапе карта может быть:

- blank
- dummy
- placeholder
- without final gameplay text

Это допустимо.

## 5. Core manual operations

Первый слой обязан поддерживать именно эти базовые операции:

### `draw`

```text
take one card from deck
move it into hand
```

### `discard`

```text
take one card
move it into grave
```

### `play`

На этом слое `play` означает не “сыграть по правилам weak/strong”,
а просто:

```text
place/move a card onto the table surface
```

То есть карта может быть вручную помещена:

- в `manifest`
- в `latent`
- в `runtime`
- в `targets`
- в `trump zone`

если конкретная debug/manual operation это разрешает.

Важно:

```text
layer 1 play = board placement
not gameplay legality
```

## 5.5. Runtime modes

На первом слое надо сразу различать два режима runtime:

### `dev mode`

Это основной и единственный обязательный режим текущего слоя.

В нём:

- карты можно вручную переставлять между зонами
- можно вручную класть карту в `manifest`
- можно вручную класть карту в `latent`
- можно вручную класть карту в `targets`
- можно вручную класть карту в `runtime`
- можно вручную класть карту в `trump zone`
- `draw`, `discard`, `flip`, `move` работают как debug/manual operations

Ограничения здесь только structural:

- карта не может быть в двух зонах сразу
- ordered zones должны сохранять порядок
- invalid structural placement может вернуть карту назад

### `normal mode`

Этот режим существует как future slot,
но не является обязательным для текущего слоя.

Он потом будет нужен для:

- реальной gameplay legality
- weak/strong play law
- operator payloads
- controlled action surface

Текущий закон:

```text
layer 1 implements dev mode first
normal mode is deferred
```

## 6. Visibility operations

Скелет обязан уметь:

- turn card face-up
- turn card face-down
- reveal card
- hide card

Потому что hidden/public state — часть самой поверхности игры.

## 7. Ordered-zone behavior

Первый слой должен уже понимать ordered zones.

Это обязательно для:

- `grave`
- `manifest row`
- `latent row`
- `targets`
- `trump zone` if represented as ordered chamber

Значит движок уже должен поддерживать:

- slot placement
- insertion position
- top/bottom semantics where needed

## 8. Manual law vs gameplay law

Нужно очень жёстко разделить два режима:

### Manual board operations

Это операции первого слоя:

- draw
- discard
- place card
- move card
- flip card

Они проверяют только structural validity,
а не gameplay legality.

Именно этот режим сейчас и является:

```text
dev mode
```

### Gameplay operations

Это более поздний слой:

- weak
- strong
- operator payloads
- strong combined readings
- duplicate law
- trumps

Их на первом слое ещё нет.

## 9. Minimum validity rules

Хотя gameplay law ещё не включён,
первый слой не должен быть хаосом.

Поэтому already needed:

- card cannot exist in two zones at once
- moving card updates zone ownership correctly
- ordered zones preserve order
- hidden/public state stays explicit
- invalid structural placement may snap back

## 10. Interaction requirement

На этом слое уже должны работать:

- selection
- placement
- optional drag/drop
- snap-back on invalid placement

Но interaction ещё не обязан знать реальные игровые правила.

## 11. Trump zone on layer 1

`trump zone` должен быть уже видимым и рабочим как zone shell.

Но:

- trumps не обязаны участвовать в gameplay
- trump resolution не включён
- zone exists only as board structure

## 12. Definition of done

Первый слой считается собранным,
если одновременно верно:

1. все ключевые зоны уже существуют
2. карты уже являются отдельными сущностями
3. draw работает
4. discard работает
5. manual play/place работает
6. face-up / face-down state работает
7. grave visibly grows
8. deck visibly decreases
9. карты можно переносить по столу без поломки zone ownership
10. `dev mode` already allows free manual board manipulation
11. `normal mode` is not required yet

## 13. Short formula

```text
layer 1 = living board skeleton with real card entities,
before gameplay law enters the machine
```
