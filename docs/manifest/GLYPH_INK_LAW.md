# Glyph Ink Law

Статус:

```text
legacy manifest branch
```

Этот документ фиксирует отдельный закон цвета glyph layer.

Он не описывает:

- геометрию glyph forms
- placement glyphs on card faces
- operator field colors

Он описывает только:

```text
how glyphs receive visible ink on top of colored card fields
```

Связанные документы:

- [GLYPH_SYSTEM_V1.md](./GLYPH_SYSTEM_V1.md)
- [STYLE_CANON.md](./STYLE_CANON.md)
- [CARD_FRAME_DIRECTION.md](./CARD_FRAME_DIRECTION.md)
- [CARD_FACE_COLOR_DIRECTION.md](./CARD_FACE_COLOR_DIRECTION.md)

## 0. Status note

Этот документ сохраняется в репозитории как история альтернативной ветки.

Он больше не является current visual canon.

Current runtime-facing branch:

- [CARD_FACE_COLOR_DIRECTION.md](./CARD_FACE_COLOR_DIRECTION.md)
- [CARD_FIELD_DARKENING.md](./CARD_FIELD_DARKENING.md)

## 1. Core Claim

Нельзя считать, что цвет оператора автоматически определяет цвет glyph ink.

То есть:

```text
operator field color != glyph ink color
```

Причина простая:

- `☳ CHOOSE` живёт на красном поле,
  но красный glyph на красном поле даст плохую читаемость
- `☴ OBSERVE` живёт на почти белом поле
- `☱ RUNTIME` живёт на тёмном steel-slate поле

Один фиксированный universal glyph color тоже не подходит.

## 2. Mask-first law

Glyph layer должен мыслиться так:

1. glyph is a procedural form
2. that form first exists as a neutral mask
3. visible ink is chosen after the field colors are known

Короткая формула:

```text
glyph form first
glyph ink second
```

То есть glyph не должен быть заранее зашит как:

- всегда белый
- всегда чёрный
- всегда operator-colored

## 3. Separation of layers

Card face нужно держать как три разных слоя:

### A. Field color layer

Это split-composition карты:

- minor diagonal split
- trump vertical split

Этот слой несёт operator color identity.

### B. Glyph mask layer

Это чистая форма символа.

Этот слой несёт operator form identity.

### C. Glyph ink layer

Это уже видимый цвет glyph overprint.

Этот слой несёт:

- contrast
- readability
- visual emphasis

## 4. Anti-law

Нельзя делать:

```text
glyph color = operator hue by default
```

Нельзя делать:

```text
one global glyph color for all cards
```

Нельзя делать:

```text
glyph color chosen ad hoc by eye per card with no system
```

## 5. Ink classes

На текущем каноническом уровне достаточно держать три ink classes:

### `light ink`

- warm white
- pale bone
- soft luminous off-white

Используется там,
где нужен светлый знак на среднем или тёмном поле.

### `dark ink`

- graphite
- deep charcoal
- near-black metal ink

Используется там,
где нужен тёмный знак на светлом поле.

### `accent ink`

- reserved third contrast class
- используется только там,
  где `light` и `dark` не дают достаточно чистой читаемости

`accent ink` не должен быть default path.

## 6. Contrast law

Glyph ink выбирается не по названию оператора,
а по читаемости на конкретном face field.

Правило:

```text
ink is chosen by contrast against the rendered field
not by loyalty to the operator hue
```

Приоритет:

1. clean readability
2. stable card identity
3. harmony with frame and field
4. only then subtle style preference

## 7. Minor and trump consequence

Этот закон одинаково действует и на minors, и на trumps.

Но practical result может различаться:

- minor glyphs живут внутри diagonal field composition
- trump glyphs живут внутри vertical event composition

Значит выбор ink может различаться даже при одной и той же operator pair family.

## 8. Text reduction consequence

Если glyph layer становится главным face signal,
то шумный текст на карте должен уходить назад.

Следствие:

- большие operator names на card face убираются
- glyph + field + frame становятся primary identity
- text допустим только как debug residue или secondary support

## 9. Runtime implementation law

Когда этот слой идёт в код,
runtime не должен хранить glyph color как фиксированную часть operator identity.

Правильная модель:

```text
operator defines glyph form
render context chooses glyph ink
```

То есть:

- `operator -> glyph shape`
- `card face state -> ink class`

А не:

- `operator -> one eternal glyph color`

## 10. What this document does not decide yet

Этот документ пока не фиксирует:

- exact RGB values for `light ink`
- exact RGB values for `dark ink`
- exact trigger thresholds for contrast switching
- whether dual-glyph cards ever need mixed-ink treatment

Это следующий rendering sublayer.

Но главный закон уже зафиксирован:

```text
glyphs are rendered as masks first
ink comes later through contrast law
```

## 11. Short formula

```text
field color names the operator surface
glyph form names the operator shape
glyph ink is chosen for contrast, not for hue loyalty
```
