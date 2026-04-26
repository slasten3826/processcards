# Glyph: Trigrams (☰ ☷ ☵ ☳ ☴ ☲ ☶ ☱)

Статус:

```text
manifest glyph canon
```

Связанные документы:

- [GLYPH_PLACEMENT_LAW.md](./GLYPH_PLACEMENT_LAW.md)
- [GLYPH_METRICS_LAW.md](./GLYPH_METRICS_LAW.md)
- [TRUMP_GLYPH_METRICS_V1.md](./TRUMP_GLYPH_METRICS_V1.md)
- [../GLYPH_SYSTEM_V1.md](../GLYPH_SYSTEM_V1.md)
- [../CARD_FACE_COLOR_DIRECTION.md](../CARD_FACE_COLOR_DIRECTION.md)
- [../STYLE_CANON.md](../STYLE_CANON.md)
- [../../table/OPERATORS_INDEX.md](../../table/OPERATORS_INDEX.md)

## 1. Form

Триграмма — три горизонтальные черты, каждая либо сплошная (⚊), либо прерванная (⚋).

Чтение снизу вверх: нижняя черта первая, верхняя третья.

### Геометрия черты

Длина и масштаб триграммы должны совпадать по занимаемой площади с глифами-треугольниками (▽△).

| Параметр | Значение |
|----------|----------|
| Длина черты | `1.2 × gs` |
| Толщина черты | `0.15 × gs` |
| Зазор между чертами | `0.35 × gs` |
| Общая высота триграммы | `3 × 0.15 + 2 × 0.35 = 1.15 × gs` |
| Ширина триграммы | `1.2 × gs` |

Для сравнения: треугольник ~`1.2 × gs` ширина, ~`1.1 × gs` высота.

### Прерванная черта (⚋)

Делится на: левая половина, зазор, правая половина.

- Каждая половина: `0.5 × gs`
- Зазор: `0.2 × gs`

### Сплошная черта (⚊)

Один прямоугольник на всю длину: `1.2 × gs`.

### Прорисовка

Залитые прямоугольники (`"fill"`).

## 2. Operator patterns

Рисунок черт (снизу вверх: нижняя → средняя → верхняя):

| Оператор | Символ | Нижняя | Средняя | Верхняя |
|----------|--------|--------|---------|---------|
| CONNECT  | ☰ | ⚊ | ⚊ | ⚊ |
| DISSOLVE | ☷ | ⚋ | ⚋ | ⚋ |
| ENCODE   | ☵ | ⚋ | ⚊ | ⚋ |
| CHOOSE   | ☳ | ⚊ | ⚋ | ⚋ |
| OBSERVE  | ☴ | ⚋ | ⚊ | ⚊ |
| CYCLE    | ☲ | ⚊ | ⚋ | ⚊ |
| LOGIC    | ☶ | ⚋ | ⚋ | ⚊ |
| RUNTIME  | ☱ | ⚊ | ⚊ | ⚋ |

## 3. Current branch note

Этот документ фиксирует trigram geometry,
а не competing visual branches.

Current runtime-facing branch:

- [../CARD_FACE_COLOR_DIRECTION.md](../CARD_FACE_COLOR_DIRECTION.md)

Current strict metrics refinement priority:

- [TRUMP_GLYPH_METRICS_V1.md](./TRUMP_GLYPH_METRICS_V1.md)

## 4. Ink

Ink не зашит в геометрию. Цвет передаётся параметром при отрисовке.

Current runtime branch использует operator-color glyph rendering,
но trigram geometry от этого не зависит.
