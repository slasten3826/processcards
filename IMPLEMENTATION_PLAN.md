# План реализации

Это suggested path, не замороженная заповедь.
Если код показывает лучший маленький шаг, надо брать его и объяснять почему.

## Phase 0: Minimal skeleton

Создать простые Lua-модули:

```text
src/processcards.lua
src/canon_adapter.lua
src/cards.lua
src/state.lua
src/relations.lua
src/setup.lua
src/trumps.lua
tests/run.lua
```

Если на старте лучше меньше файлов - использовать меньше.
Главное: table-first, без тяжёлых abstractions.

## Phase 1: Canon adapter

Загрузить:

```text
/home/slasten/Документы/stack/stack-core/ProcessLang/canon.lua
```

Дать маленький interface:

```lua
is_adjacent(left, right)
resolve(value)
inventory_order
operators
```

## Phase 2: Card representation

Использовать простые Lua tables.

Minor example:

```lua
{ kind = "minor", number = "▽", suit = "☶", id = "1☶" }
```

Trump example:

```lua
{ kind = "trump", edge = { "☳", "☶" }, name = "RECAST" }
```

Форматы могут поменяться, если implementation pressure покажет более удобную форму.

## Phase 3: Setup prototype

Собрать prototype deck:

- 100 minors = все ordered number/suit pairs;
- enough trump placeholders для проверки trump handling;
- named `RECAST` для edge `☳ -> ☶`.

Prototype setup должен создавать:

```text
3 targets face-down
5 manifest cards face-up
5 latent cards face-down
hand cards
grave empty
runtime nil
trump_zone empty
log empty
```

Если exact initial hand size неизвестен, стартовать с 5 и сделать configurable.

## Phase 4: Relation checks

Реализовать:

```lua
is_weak(a, b)
is_strong(a, b)
is_mirror(a, b)
```

Weak relation:

```text
number_A == number_B
suit_A == suit_B
number_A == suit_B
suit_A == number_B
```

Strong relation:

```text
canon.is_adjacent(suit_A, number_B)
or canon.is_adjacent(suit_B, number_A)
```

Mirror relation:

```text
number_A == suit_B and suit_A == number_B
```

## Phase 5: RECAST

Реализовать текущий `RECAST` из source docs.

Expected behavior:

```text
old manifest -> new hand
old latent -> new manifest
old hand -> new latent
if old hand has fewer than 5, refill latent from deck face-down
old hand overflow -> grave in reveal order
resolved trump -> trump_zone
if trump_zone already has 2 trumps, third trump resets chamber into deck
```

## Phase 6: Tests as design pressure

Написать tests для инвариантов и edge cases:

- deck construction count;
- setup board shape;
- weak/strong/mirror examples;
- RECAST with old hand size 0;
- RECAST with old hand size 5;
- RECAST with old hand size > 5;
- grave order after overflow;
- third trump reset.

Запуск:

```bash
lua tests/run.lua
```

## Phase 6.5: Target compiler shell

После базовой устойчивости board-state добавить минимальную версию target compiler:

- 3 ordered target slots;
- stable state slot = hidden candidate or installed trump;
- `OBSERVE` target:
  - non-trump -> becomes known, stays hidden;
  - trump -> discharges as normal event, slot refills;
- `MANIFEST` target:
  - non-trump -> goes to grave, slot refills;
  - trump -> installs as sealed law in that slot;
- victory check only after post-phase resolution;
- no full semantic payload for all target roles yet.

Здесь задача не сделать финальную систему победы,
а доказать, что target zone уже ведёт себя как compiler, а не как декорация.

## Phase 7: Playable CLI

После rules tests сделать первый playable loop:

```bash
lua src/cli.lua
```

Минимальный CLI должен уметь:

- показать zones;
- показать manifest row;
- показать hand;
- выбрать action;
- выбрать карты/слоты по индексам;
- выполнить weak / strong / discard / pass;
- показать log текущего хода;
- сохранить bounded resolution tail.

CLI не обязан быть красивым.
Он должен быть честным test harness, в который можно играть.

## Phase 8: Functional GUI

GUI делать только поверх уже работающего rules engine.

Цель GUI:

```text
кликабельный карточный стол
```

Желаемый feel:

- карты можно выбирать мышкой;
- зоны читаются визуально;
- latent/manifest slots видны как 5 columns x 2 layers;
- hand и grave доступны без лишнего текста;
- trump zone виден как two-event pressure chamber;
- интерфейс помогает играть, а не объясняет игру.

Стиль может быть простым.
Важнее функциональность и скорость правок.

Возможные направления:

- Love2D, если хочется нативный Lua GUI;
- web UI поверх Lua rules bridge, если это окажется быстрее;
- terminal UI как промежуточный слой, если GUI рано.

Решение не фиксировать до появления playable CLI.

## Phase 9: Staged trump expansion

После playable CLI расширять trump-layer поэтапно:

1. `RECAST` как обязательный rewrite trump;
2. `SHUFFLE` как circulation trump;
3. `EJECT` как precision trump;
4. только потом расширять набор дальше.

Порядок важен:

- `RECAST` проверяет board rewrite;
- `SHUFFLE` проверяет residue/deck ecology без переписывания сцены;
- `EJECT` проверяет cross-zone pressure и может слишком рано расшатать всё, если дать его раньше.

## Non-goals now

Сейчас не делать:

- полный polished GUI;
- все card texts;
- full target compiler;
- balancing simulator;
- переписывание дизайна в новый философский трактат;
- внешние зависимости без явной необходимости.

machines only. not for humans.
