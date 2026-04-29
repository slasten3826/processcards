# CLI-First Runtime Architecture

Статус:

```text
canonical crystall architecture decision
```

Этот документ фиксирует
новую архитектурную границу проекта:

```text
game logic lives in CLI-first runtime
LOVE2D renders and animates that logic
```

## 1. Core decision

`LOVE2D` больше не должен быть
источником истины для игровой логики.

Источником истины должен стать:

```text
headless CLI game core
```

А `LOVE2D` должен:

- читать состояние этого core
- запускать transitions
- рисовать
- анимировать
- принимать input

Но не изобретать логику заново внутри UI-layer.

## 2. Why this is now required

Текущий runtime уже дошёл до уровня,
где логика начинает ломаться
из-за смешивания:

- machine state mutation
- animation queue
- render timing
- UI interaction

Это делает сложным:

- поиск дыр в `manifest`
- тестирование trump routing
- проверку `board closure`
- повторяемые сценарии

## 3. New separation

### CLI core

CLI core должен отвечать за:

- zones
- cards
- info states
- move legality
- turn sequence
- board closure
- draw/open/concealed entry
- trump flow / trump zone
- win checks
- deterministic state transitions

### LOVE2D shell

LOVE2D shell должен отвечать за:

- layout
- visual zones
- animation
- input mapping
- timing of presentation
- card motion polish
- readable event stepping

Коротко:

```text
CLI decides what happens
LOVE shows how it happens
```

## 4. Testing consequence

После этого любая машина должна уметь:

- запускать game logic без GUI
- воспроизводить сценарии
- дампить zones
- проверять invariants
- писать deterministic tests

Примеры:

- latent trump ascent scenario
- draw reveals trump scenario
- board closure blocks trump resolution
- no holes in manifest after closure

## 5. Required CLI capabilities

Минимальный CLI core должен уметь:

1. создать game state
2. выполнить setup
3. выполнить action
4. выполнить resolve step
5. вывести state snapshot
6. вернуть machine-readable result

То есть:

```text
setup
act
resolve
dump
assert
```

## 6. Required LOVE2D behavior after split

LOVE2D не должен сам решать:

- куда карта уходит логически
- закрыт ли board
- что делает trump
- как заполняется `manifest`
- как работает draw law

Вместо этого он должен получать
уже вычисленный transition plan
или state diff
из CLI core.

## 7. Migration strategy

Переход должен идти не через
полную перепись UI,
а через вынос логики из `main.lua`
в reusable core modules.

Порядок:

1. setup/state core
2. turn core
3. trump core
4. draw/closure core
5. test scenarios
6. LOVE2D adapter over the same core

## 8. First implementation goal

Первый practically useful результат:

```text
a CLI scenario runner
that can reproduce and inspect logic bugs
without LOVE2D
```

Это важнее,
чем сразу делать идеальный engine split.

## 9. Short formula

```text
Game truth moves to a headless CLI core.
LOVE2D becomes the presentation and animation shell.
Logic must be testable without graphics.
```
