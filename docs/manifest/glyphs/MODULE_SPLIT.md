# Glyph Module Split

Статус:

```text
proposed — до реализации не канон
```

Связанные документы:

- [GLYPH_SYSTEM_V1.md](../GLYPH_SYSTEM_V1.md)
- [GLYPH_INK_LAW.md](../GLYPH_INK_LAW.md)
- [GLYPH_PLACEMENT_LAW.md](./GLYPH_PLACEMENT_LAW.md)
- [../../crystall/PROTOTYPE_CRYSTALL.md](../../crystall/PROTOTYPE_CRYSTALL.md)

## 1. Зачем

Сейчас весь код лежит в `main.lua` (~1100 строк, монолит).

Глифы — отдельная система, которая не должна быть вмонтирована в остальную логику.
Если всё смешано:

- смена цвета глифа требует поиска по всему файлу
- смена формы глифа требует правки рендера карт
- невозможно протестировать глифы отдельно

Цель: сделать glyph layer модульным, чтобы форма, цвет и размещение менялись независимо.

## 2. Что будет

Три новых файла в `src/`:

```
src/
├── glyphs.lua        — геометрия глифов (формы)
├── glyph_ink.lua     — палитра ink, выбор по контрасту
└── glyph_layout.lua  — координаты глифов на карте
```

## 3. Ответственность каждого модуля

### `glyphs.lua` — чистая геометрия

Что делает:
- Экспортирует функции для отрисовки каждого из 10 глифов
- Функция получает: `(center_x, center_y, size, ink_color)`
- Функция рисует: примитивами LÖVE (`rectangle`, `line`, `polygon`, `circle`)

Что НЕ делает:
- Не знает, какая карта и где
- Не выбирает цвет — цвет передан параметром
- Не содержит игровых правил
- Не зависит от `state`, `layout`, `COLORS`

Публичный интерфейс (пример):
```lua
-- треугольники
glyphs.draw_MANIFEST(x, y, gs, ink)
glyphs.draw_FLOW(x, y, gs, ink)

-- триграммы — одна общая функция + 8 обёрток
glyphs.draw_CONNECT(x, y, gs, ink)
glyphs.draw_DISSOLVE(x, y, gs, ink)
...
```

Или таблица:
```lua
glyphs.draw["MANIFEST"](x, y, gs, ink)
```

### `glyph_ink.lua` — выбор цвета

Что делает:
- Определяет палитру (light ink, dark ink)
- Содержит функцию `ink_for_field(r, g, b)` — возвращает light или dark по luminance поля

Что НЕ делает:
- Не знает названий операторов
- Не знает где на карте глиф
- Не содержит геометрии

Публичный интерфейс:
```lua
glyph_ink.light   -- {0.94, 0.93, 0.89}
glyph_ink.dark    -- {0.08, 0.10, 0.14}
glyph_ink.for_field(r, g, b) -> light | dark
```

### `glyph_layout.lua` — где рисовать

Что делает:
- Содержит позиции глифов относительно карты: координаты для minor и trump
- Получает `rect` карты и возвращает `{x, y}` для op_a и op_b

Что НЕ делает:
- Не содержит геометрии
- Не выбирает цвет
- Не знает игровых правил

Публичный интерфейс:
```lua
glyph_layout.minor_pos(rect) -> {ax, ay, bx, by}
glyph_layout.trump_pos(rect) -> {ax, ay, bx, by}
```

## 4. Как модули соединяются

`main.lua` подключает все три и собирает вызов:

```lua
-- внутри draw_card(), когда карта face_up:
local gs = 15 * layout.scale

if card.class == "trump" then
    local pos = glyph_layout.trump_pos(rect)
    local ink_a = glyph_ink.for_field(dark_a)
    local ink_b = glyph_ink.for_field(dark_b)
    glyphs.draw[card.op_a](pos.ax, pos.ay, gs, ink_a)
    glyphs.draw[card.op_b](pos.bx, pos.by, gs, ink_b)
else
    local pos = glyph_layout.minor_pos(rect)
    local ink_a = glyph_ink.for_field(dark_a)
    local ink_b = glyph_ink.for_field(dark_b)
    glyphs.draw[card.op_a](pos.ax, pos.ay, gs, ink_a)
    glyphs.draw[card.op_b](pos.bx, pos.by, gs, ink_b)
end
```

## 5. Что меняется в main.lua

- Добавляются 3 `require` в начале файла
- В функции `draw_card()`:
  - убирается отрисовка текстовых имён операторов
  - добавляется отрисовка глифов (3-5 строк на ветку minor/trump)
- Всё остальное — без изменений

## 6. Правило разделения

```text
glyphs.lua       — форма (как выглядит)
glyph_ink.lua    — цвет (каким цветом)
glyph_layout.lua — место (где на карте)
```

Ни один модуль не знает про другие. Цепочка собирается в `main.lua`.

## 7. Что это даёт

- Поменять цвет всех глифов → одна строка в `glyph_ink.lua`
- Сдвинуть глифы на карте → два числа в `glyph_layout.lua`
- Переделать форму конкретного глифа → одна функция в `glyphs.lua`
- Протестировать глифы можно отдельно, без запуска всей игры
- Позже добавить анимацию глифов → новый модуль, старые не трогаем
