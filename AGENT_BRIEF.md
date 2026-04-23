# Бриф для агента

Ты подключаешься к активному design/implementation процессу.

Ты не здесь, чтобы исполнять готовую спецификацию.
Ты здесь, чтобы помогать превращать текущий дизайн `ProcessCards` в маленький runnable Lua-прототип и показывать, что ломается.

## Язык документации

Документацию в этом репозитории ведём на русском.

Допустимы английские термины, если они являются:

- именами зон в коде: `deck`, `hand`, `grave`;
- canonical ProcessCards terms;
- ProcessLang / Lua identifiers;
- короткими формулами из исходных design-доков.

## Рабочее отношение

Предпочитать:

- маленькие исполняемые шаги;
- ясные state tables;
- простые тесты;
- явную неопределённость;
- отчёт о design gaps;
- вопросы к пользователю только когда код не может безопасно двигаться дальше.

Избегать:

- самостоятельного полного редизайна игры;
- отношения к каждому предложению markdown как к финальному закону;
- импорта всего `slastack` в этот репозиторий;
- философского расширения без связи с реализацией;
- Python;
- внешних зависимостей;
- UI раньше rules engine.

## Что строить первым

Начать с Lua table-machine, которая представляет состояние игры:

```text
deck
hand
targets
manifest
latent
runtime
grave
trump_zone
log
```

Затем реализовать достаточно механик, чтобы проверить текущий дизайн:

- собрать deck;
- инициализировать board state;
- проверить weak / strong / mirror relations;
- сохранять 5 manifest + 5 latent slots;
- resolve `RECAST`;
- смоделировать trump zone capacity 2;
- написать tests around invariants.

## Прототип, в который можно играть

Первый playable milestone должен дать человеку возможность пройти ходовой цикл, пусть даже в CLI.

CLI допустим как первый интерфейс, потому что он быстро проверяет rules engine.
GUI желателен как следующий слой: кликабельный карточный стол, выбор карт мышкой, понятные зоны, функциональность важнее красоты.

Архитектурно важно:

```text
rules engine не должен зависеть от CLI или GUI
```

Мы будем часто менять игру на логическом уровне.
Lua выбран именно потому, что такие правки должны быть быстрыми, локальными и прозрачными.

## Что можно считать provisional

Это ещё design surfaces, не окончательный закон:

- exact setup procedure;
- target compiler details;
- all card texts;
- full trump set;
- balance numbers;
- final CLI format;
- GUI framework / rendering layer.

Если нужен provisional choice, делай минимальное локальное предположение и записывай его.

## Canonical topology

Использовать ProcessLang topology из:

```text
/home/slasten/Документы/stack/stack-core/ProcessLang/canon.lua
```

Топология не provisional.

## Первый полезный milestone

Хороший первый milestone:

```text
lua tests/run.lua
```

passing tests должны доказывать:

- setup создаёт валидные зоны;
- relation checks работают;
- `RECAST` сохраняет board shape;
- old manifest становится new hand;
- old latent становится manifest;
- old hand становится latent / overflow grave;
- third resolved trump resets trump zone into deck.

После этого следующий milestone:

```text
lua src/cli.lua
```

минимально позволяет играть ходами и видеть зоны.

## Optional skill

При работе с ProcessLang traces можно использовать локальный ProcessLang skill:

```text
/home/slasten/Документы/stack/protocols/skills/processlang/SKILL.md
```

Он помогает читать glyphs, валидировать traces и интерпретировать ProcessLang state-packets.
Он не заменяет ProcessCards rules documents.

machines only. not for humans.
