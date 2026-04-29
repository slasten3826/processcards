# Glyph: ☱ RUNTIME — Special Case

Статус:

```text
current canon
```

Связанные документы:

- [TRIGRAMS.md](./TRIGRAMS.md)
- [GLYPH_PLACEMENT_LAW.md](./GLYPH_PLACEMENT_LAW.md)
- [../CARD_FACE_COLOR_DIRECTION.md](../CARD_FACE_COLOR_DIRECTION.md)
- [../../table/operators/RUNTIME.md](../../table/operators/RUNTIME.md)

## 1. Previous problem

Earlier RUNTIME used near-black graphite: `{0.18, 0.20, 0.24}`.
That forced the glyph into white inversion and made it drift toward OBSERVE.

Current canonical color is now:

```text
{0.40, 0.46, 0.52}
```

This keeps RUNTIME dark,
but no longer collapses it into unreadable black-on-black.

## 2. Current solution

RUNTIME is no longer a white inversion case.

It now uses:

- its own steel-slate operator color
- line-mode trigram
- no special white ink override

Два отличия от остальных глифов:

### 2.1. Режим: line вместо fill

Триграмма рисуется линиями (`"line"`), а не залитыми прямоугольниками (`"fill"`).

Это НЕ отдельная система рисования. `draw_trigram()` — одна функция,
параметр `mode` переключает используемый примитив:

```
"fill" → love.graphics.rectangle("fill", ...)
"line" → love.graphics.line(...)
```

Геометрия (позиции, размеры, паттерн черт) — общая для всех триграмм.

### 2.2. Цвет: канонический RUNTIME вместо белого

В `draw_card()` для RUNTIME цвет глифа снова берётся
из `OP_COLORS["RUNTIME"]`.

Визуальный эффект:
- контурный знак
- но уже без белой оптической путаницы с OBSERVE

## 3. Метафора

Остальные глифы — залитые фигуры цвета оператора.
RUNTIME — контур, пустая форма.

Это соответствует идентичности RUNTIME: среда исполнения, инфраструктура,
не контент а вместилище.

## 4. Техническая реализация

В `glyphs.lua`:
- `draw_trigram` принимает третий параметр `mode`: `"fill"` или `"line"`
- Все триграммы вызывают `draw_trigram(..., "fill")`
- RUNTIME вызывает `draw_trigram(..., "line")`

В `draw_card()` (main.lua):
- Для RUNTIME: `set_color(OP_COLORS["RUNTIME"])` перед отрисовкой глифа
- Для остальных: `set_color(OP_COLORS[op])`

## 5. Влияние на другие системы

- `glyph_layout.lua` — без изменений
- `OP_COLORS["RUNTIME"]` — changed to steel-slate current canon
- Остальные 9 глифов — без изменений
