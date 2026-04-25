# Card Color Render V1

Статус:

```text
canonical crystall rendering contract
```

Этот документ фиксирует ближайший шаг presentation-layer:

```text
color-first card rendering
without operator glyph rendering yet
```

## 1. Purpose

Следующий визуальный шаг прототипа:

- перестать держать карты полностью blank
- начать показывать operator identity через цвет
- не тащить пока пиксельную отрисовку глифов

## 2. Why glyphs are deferred

На текущем этапе glyph rendering откладывается,
потому что:

- готового шрифтового решения нет
- unicode-глифы ненадёжны как final solution
- ручная отрисовка глифов потребует отдельного visual pass

Текущий закон:

```text
first color
later glyph
```

## 3. Current visual source of truth

Этот rendering-step опирается на:

- [../manifest/STYLE_CANON.md](../manifest/STYLE_CANON.md)
- [../manifest/CARD_FRAME_DIRECTION.md](../manifest/CARD_FRAME_DIRECTION.md)
- [PRESENTATION_DIRECTION_V1.md](./PRESENTATION_DIRECTION_V1.md)

## 4. Card classes in this render pass

### Minor cards

Minor cards должны рисоваться как:

```text
diagonal split of two operator colors
```

Это соответствует style canon:

```text
minor = grammar
minor = diagonal operator composition
```

### Trump cards

Trump cards должны рисоваться как:

```text
vertical split of two operator colors
```

Это соответствует style canon:

```text
trump = law
trump = vertical event seam
```

## 5. Hidden cards

Cards that are face-down must not reveal operator colors.

Face-down render should remain:

- dark
- neutral
- readable as hidden state
- distinct from revealed card face

## 6. Runtime data implication

Чтобы красить карты по style canon,
runtime должен хранить у карты не только `id`,
но и:

- card class (`minor` / `trump`)
- operator identity for the face

На ближайшем шаге это может быть:

- temporary operator-pair data
- even before full text/glyph realization

## 7. What this step does not require yet

Этот шаг пока не требует:

- final glyph rendering
- full card typography
- final art
- full card-frame polish
- animation polish

Он требует только:

```text
operator identity begins to appear through color
```

## 8. Short formula

```text
minors = diagonal color split
trumps = vertical color split
hidden cards stay dark
glyphs later
```
