# Card Face: Color Direction

Статус:

```text
canonical manifest law
```

Связанные документы:

- [STYLE_CANON.md](./STYLE_CANON.md)
- [GLYPH_SYSTEM_V1.md](./GLYPH_SYSTEM_V1.md)
- [CARD_COLOR_RENDER_V1.md](../crystall/CARD_COLOR_RENDER_V1.md)
- [CARD_FIELD_DARKENING.md](./CARD_FIELD_DARKENING.md)
- [glyphs/TRIGRAMS.md](./glyphs/TRIGRAMS.md)
- [glyphs/FLOW.md](./glyphs/FLOW.md)
- [glyphs/MANIFEST.md](./glyphs/MANIFEST.md)
- [CARD_FIELD_BRIGHTENING.md](./CARD_FIELD_BRIGHTENING.md) — superseded
- [GLYPH_INK_LAW.md](./GLYPH_INK_LAW.md) — legacy branch, not current canon

## 0. Source of truth

Этот документ фиксирует текущий живой card-face canon,
который уже принят в runtime.

Коротко:

```text
dark field + pure operator-color glyph
```

`CARD_FIELD_DARKENING.md` не спорит с этим документом,
а только фиксирует финальный darkening coefficient
для той же самой линии.

## 1. Core idea

```text
dark field + pure operator-color glyph
```

Поле карты — очень тёмное, но сохраняет оттенок цвета оператора.
Глиф — рисуется каноническим цветом оператора (OP_COLORS), без ink-прослойки.

Визуальный эффект: карта почти чёрная, еле заметный цветной отлив поля,
и поверх — яркий чистый глиф цвета оператора.

## 2. Split-композиция сохраняется

Поле по-прежнему разделено:

- Minor — диагональный split (верхний левый / нижний правый)
- Trump — вертикальный split (левая / правая половина)

Но затемнение поля усиливается: `lerp(op_color, bg, 0.75)`.

25% цвета оператора, 75% фона. Почти чёрный, с еле читаемым оттенком.

Сейчас было: `lerp(op_color, bg, 0.30)` — 70% цвета, яркое поле.
Новое: `lerp(op_color, bg, 0.75)` — 25% цвета, глубоко тёмное поле.

Сравнение на примере FLOW (бирюзовый `{0.22, 0.82, 0.82}`, фон `{0.05, 0.08, 0.10}`):

| Коэффициент | Цвет поля |
|------------|-----------|
| Было (0.30 bg) | `{0.17, 0.60, 0.60}` — яркий бирюзовый |
| Станет (0.75 bg) | `{0.09, 0.27, 0.28}` — почти чёрный с бирюзовым отливом |

## 3. Glyph color

Глиф рисуется чистым каноническим цветом оператора из таблицы OP_COLORS.

Никакого ink-слоя, никакого выбора light/dark по контрасту.
Цвет глифа = цвет оператора. Всегда.

Система `glyph_ink.lua` и `GLYPH_INK_LAW.md`
не являются текущим каноном для этого подхода.

## 4. RUNTIME — особый случай

RUNTIME-поле больше не должно быть почти чёрным.
Слишком тёмный графит сдвигал RUNTIME
в вынужденную белую инверсию,
и он начинал визуально спорить с OBSERVE.

Current canonical color:

```text
steel slate / machine blue-gray
{0.40, 0.46, 0.52}
```

Решение: триграмма RUNTIME (☱) по-прежнему рисуется контуром (`"line"`),
но уже своим каноническим цветом, без белой инверсии.

Остальные триграммы — заливка, как и было.

## 5. OBSERVE — особый случай

OBSERVE — почти белый (`{0.86, 0.86, 0.84}`).
На тёмном поле его глиф будет ярко выделяться — это нормально, так и задумано.

## 6. Что меняется в коде

### main.lua
- `lerp_color(ca, COLORS.bg, 0.30)` → `lerp_color(ca, COLORS.bg, 0.75)`

### draw_card()
- Убрать вызовы `glyph_ink.for_field()`
- Глифам передавать напрямую цвет оператора: `OP_COLORS[card.op_a]`

### src/glyphs.lua
- RUNTIME — использовать `draw_trigram(..., "line")`
- без отдельной белой ink-инверсии

### Убирается
- `src/glyph_ink.lua` больше не требуется
- `require("src.glyph_ink")` из main.lua

## 7. Relationship to darkening law

Этот документ задаёт общую visual direction.

Точный current field-darkening coefficient
фиксируется отдельно в:

- [CARD_FIELD_DARKENING.md](./CARD_FIELD_DARKENING.md)

Если между примером в этом документе и final tuning doc есть разница,
current truth принадлежит `CARD_FIELD_DARKENING.md`.

## 8. What remains

- `src/glyphs.lua` — геометрия глифов (с поправкой RUNTIME)
- `src/glyph_layout.lua` — позиции на карте
- Split-композиция (диагональ для minor, вертикаль для trump)
- Вертикальный разделитель на trump-картах
- Debug id и trump-имена
