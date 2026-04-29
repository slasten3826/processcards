# Fast Simulation Core Target

Статус:

```text
canonical crystall target
```

Этот документ фиксирует,
каким должен стать
headless game core в ближайшей перспективе.

## 1. Core goal

CLI/core нужен не просто
для разовых debug snapshots.

Он должен стать:

```text
a fast simulation machine
for large-scale logic playtesting
```

То есть core должен быть способен
прокручивать:

- тысячи сценариев
- тысячи партий
- массовые invariant checks
- машинный плейтест

без GUI и без animation overhead.

## 2. Why this matters

Пока логика живёт в LOVE2D runtime,
каждый серьёзный баг приходится ловить:

- глазами
- через анимации
- через смешение state и presentation

Это слишком медленно и слишком грязно.

Нужен core,
который может быть проверен
как машина:

- быстро
- воспроизводимо
- детерминированно

## 3. Required end-state

Game core должен уметь:

1. создать новую игру
2. выполнить setup
3. вычислить legal actions
4. применить action
5. выполнить resolve path
6. вернуть новый state
7. вернуть transition/events
8. сказать terminal / non-terminal status

Коротко:

```text
state
action
transition
result
```

## 4. Simulation capability

Core должен быть пригоден
для массового прогона:

```text
play N games
collect stats
assert invariants
```

Примеры полезных массовых проверок:

- average game length
- trump-flow frequency
- closure failure frequency
- invariant violation frequency
- win-pattern distribution
- dead-state frequency

## 5. Separation from LOVE2D

LOVE2D не должен быть местом,
где живёт sim logic.

LOVE2D должен стать:

- визуальной манифестацией
- animation shell
- input shell

А core должен быть тем,
что могут использовать:

- CLI
- test runner
- simulation batch runner
- later AI agents
- LOVE2D renderer

## 6. Required machine qualities

Fast simulation core должен быть:

- headless
- deterministic under seed
- serializable enough for snapshots
- assertable
- scriptable
- reusable from multiple frontends

## 7. Minimal progression

Переход к этому состоянию должен идти так:

1. setup core
2. one full turn core
3. trump-flow core
4. win-check core
5. legal-action query
6. simple autoplay policy
7. batch simulation runner

## 8. Human interface is not the goal

Эта ветка не обязана
делать красивый терминальный интерфейс для человека.

Главное:

```text
machines must be able to run and inspect the game
at scale
```

Если человеку нужен обзор,
его уже можно давать:

- через краткий snapshot
- через LOVE2D manifestation
- через словесный отчёт

## 9. Short formula

```text
The headless core must become a fast simulation machine.
Its job is not to look nice.
Its job is to let machines play, test, and break the game at scale.
LOVE2D will later manifest the same truth visually.
```
