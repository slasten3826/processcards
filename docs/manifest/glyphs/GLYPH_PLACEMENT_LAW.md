# Glyph Placement Law

Статус:

```text
manifest glyph canon
```

Этот документ фиксирует общие правила размещения глифов,
применимые ко всем 10 операторам.

Связанные документы:

- [GLYPH_SYSTEM_V1.md](../GLYPH_SYSTEM_V1.md)
- [STYLE_CANON.md](../STYLE_CANON.md)
- [GLYPH_METRICS_LAW.md](./GLYPH_METRICS_LAW.md)
- [TRUMP_GLYPH_METRICS_V1.md](./TRUMP_GLYPH_METRICS_V1.md)
- [../CARD_FACE_COLOR_DIRECTION.md](../CARD_FACE_COLOR_DIRECTION.md)

## 1. Placement by card class

### Minor cards

Глифы размещаются в углах карты, по одному на оператор:

- `op_a` — верхний левый угол (30% ширины, 30% высоты от левого верхнего края)
- `op_b` — нижний правый угол (70% ширины, 70% высоты)

Поддерживает diagonal operator composition (STYLE_CANON §4).

### Trump cards

Глифы размещаются симметрично по горизонтальному центру карты:

- `op_a` — левая половина (25% ширины, 44% высоты)
- `op_b` — правая половина (75% ширины, 44% высоты)

Поддерживает vertical event seam (STYLE_CANON §5).

## 2. Scale

Базовый размер глифа: `gs = 15 * layout.scale`.

При карте 82×118 px (на базовом разрешении 1280×720) глиф занимает примерно 18% ширины карты.

Размер параметризован — может быть изменён централизованно для всех глифов.

## 3. Current branch note

Этот документ описывает только placement на card face.

Он не решает:

- current glyph color law
- current darkening law
- strict metrics refinement priority

Current branch:

- [../CARD_FACE_COLOR_DIRECTION.md](../CARD_FACE_COLOR_DIRECTION.md)

Current strict metrics priority:

- [TRUMP_GLYPH_METRICS_V1.md](./TRUMP_GLYPH_METRICS_V1.md)

## 4. Ink

Ink не зашит в геометрию глифа. Цвет передаётся параметром при отрисовке.

Current runtime branch сейчас использует:

```text
pure operator-color glyphs
```

Но сам placement law от этого не меняется:

- position stays a placement concern
- color stays a face-render concern

## 5. Procedural definition

Все глифы отрисовываются через примитивы LÖVE:

- линии, полигоны, круги, прямоугольники
- режимы `"line"` (контур) или `"fill"` (заливка)
- никаких внешних ассетов, шрифтов, спрайтов

Каждый глиф — отдельная функция с сигнатурой:
```text
draw_glyph_X(center_x, center_y, size, ink_color)
```
