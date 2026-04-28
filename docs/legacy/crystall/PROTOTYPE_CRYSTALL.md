# Prototype Crystall

Это документ о первом кодовом crystall-срезе.

Он отвечает не на вопрос “что такое игра вообще”,
а на вопрос:

```text
что именно мы кодируем первым
и в каком порядке
```

## 1. Core law

Код начинается только после table.

То есть:

```text
table names the surface
crystall fixes the surface
```

Если в коде появляется новое крупное правило,
которого нет в table-документах,
это считается design debt и должно быть либо задокументировано,
либо удалено.

И ещё:

```text
crystall may assist the player
but may not fake impossible cardboard actions
```

## 2. First crystall target

Первый crystall-срез должен собрать:

- state model;
- deck construction;
- setup;
- relation checks;
- action resolution;
- log of action tail;
- minimal clickable GUI in `Love2D`.

Это crystall только для minor-only machine.

Он должен моделировать физически исполнимую игру,
а не цифровой режим, который потом невозможно перенести на реальные карты.

Current strong source:

- `docs/table/STRONG_COMBINED_LAW.md`
- `docs/table/STRONG_PAIR_TABLE.md`

Deprecated reading:

```text
strong = draw 2 + 1-2 effects
```

This older wording is no longer live canon.

## 3. Proposed module split

Первое разумное разбиение:

```text
src/processcards/init.lua
src/processcards/canon_adapter.lua
src/processcards/cards.lua
src/processcards/state.lua
src/processcards/setup.lua
src/processcards/relations.lua
src/processcards/actions.lua
src/processcards/ui_geometry.lua
main.lua
tests/run.lua
```

Если меньше файлов окажется лучше,
можно собрать плотнее.

## 4. First data responsibilities

### `cards.lua`

- построение 100 minors;
- card ids;
- card labels;
- card metadata useful for UI.

### `state.lua`

- all zones;
- selected hand card;
- selected column;
- current action mode;
- log;
- turn counter.

Здесь нельзя держать скрытые игровые истины,
которые не имеют физического выражения на столе.

### `setup.lua`

- create shuffled deck;
- fill targets;
- fill manifest;
- fill latent;
- fill hand;
- initialize empty grave/runtime/log.

### `relations.lua`

- `is_weak`
- `is_strong`
- `is_mirror`

### `actions.lua`

- `play`
- `discard`
- `pass`
- bounded resolution tail

### `ui_geometry.lua`

- board rectangles;
- card hitboxes;
- layout constants;
- no gameplay rules here.

UI может подсвечивать:

- выбранную карту;
- weak / strong legality on manifest targets;
- текущую action mode;
- order in grave.

Но UI не должен:

- знать за игрока скрытые latent cards, если они не были physically observed;
- исполнять скрытые автоматические zone rewrites, которые не выражаются картами;
- делать invisible bookkeeping, от которого зависит rules truth.

## 5. Love2D scope

Первый LÖVE GUI должен уметь:

- отрисовать стол;
- отрисовать manifest / latent / hand / deck / grave / target;
- подсвечивать selected card;
- подсвечивать valid / invalid columns;
- принимать mouse input;
- выполнять action;
- показывать короткий log;
- не смешивать render code с gameplay rules сильнее, чем это нужно на первом срезе.

И должен соблюдать physical-card law:

- всё важное должно быть выражено картами и их положением;
- hidden state должен оставаться bounded и physically legible;
- действия должны быть воспроизводимы руками на столе без цифровой магии.

## 6. First visual goal

Visual goal:

```text
functional dark table
light cards
clear zone separation
clickable columns
```

Это не финальный арт.
Это operational board.

## 7. Test target before polish

До любого visual polish должны проходить tests, которые доказывают:

- setup shape valid;
- weak relation examples work;
- strong relation examples work;
- weak move preserves board shape;
- strong move preserves board shape;
- discard preserves ordered grave.

И отдельная проверка смыслом:

- никакой core action первого прототипа не требует purely digital convenience.

Если GUI уже красивый, а эти вещи не доказаны,
значит crystall идёт впереди table и впереди machine truth.

## 8. What to defer

Во второй очереди:

- unresolved strong pair branches beyond documented clear pairs;
- target compiler semantics;
- runtime depth beyond capacity 1;
- hidden trump emergence;
- SHUFFLE;
- EJECT;
- animations;
- sound;
- card text rendering depth.

Также откладываем всё, что пока не проходит physical-card law,
даже если в коде это легко сделать.

## 9. Short formula

```text
first crystall = minor rules machine first, clickable board second, polish later
```

machines only. not for humans.
