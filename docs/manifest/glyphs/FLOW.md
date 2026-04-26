# Glyph: ▽ FLOW

Статус:

```text
manifest glyph canon
```

Связанные документы:

- [GLYPH_PLACEMENT_LAW.md](./GLYPH_PLACEMENT_LAW.md)
- [../GLYPH_SYSTEM_V1.md](../GLYPH_SYSTEM_V1.md)
- [../GLYPH_INK_LAW.md](../GLYPH_INK_LAW.md)
- [../STYLE_CANON.md](../STYLE_CANON.md)
- [../../table/operators/FLOW.md](../../table/operators/FLOW.md)

## 1. Form

Равносторонний треугольник, вершина вниз.

```text
▽
```

- Только контур (stroke), без заливки.
- Без внутренних деталей.
- Толщина линии: пропорционально размеру глифа.

Геометрически — MANIFEST-треугольник, развёрнутый на 180°.

## 2. Ink

Ink не зашит в геометрию. Цвет передаётся параметром при отрисовке.

FLOW-поле — бирюзовое (`{0.22, 0.82, 0.82}`).

Конкретный ink-класс (light / dark) определяется по контрасту с полем в момент рендера, согласно `GLYPH_INK_LAW.md`.

Minor и trump карты используют один и тот же ink для этого глифа.
