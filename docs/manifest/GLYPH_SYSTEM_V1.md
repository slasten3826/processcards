# Glyph System V1

Статус:

```text
working manifest canon
```

Этот документ фиксирует следующий шаг card presentation:

```text
operator glyphs are rendered procedurally
not loaded as bitmap assets
```

Current color-law branch for this glyph system:

- [CARD_FACE_COLOR_DIRECTION.md](./CARD_FACE_COLOR_DIRECTION.md)
- [CARD_FIELD_DARKENING.md](./CARD_FIELD_DARKENING.md)

Legacy alternative branch:

- [GLYPH_INK_LAW.md](./GLYPH_INK_LAW.md)

## 1. Core decision

Для `ProcessCards` glyph layer должен строиться не через:

- unicode fallback
- bitmap icon pack
- sprite sheet

А через:

```text
procedural / code-rendered glyph system
```

То есть глифы должны быть:

- определены как собственные shape-laws
- отрисовываться кодом
- быть масштабируемыми
- жить как часть реального visual system,
  а не как внешний temporary asset pack

## 2. Why this path is chosen

Этот путь выбран потому что проект делается всерьёз,
а не как временный mockup.

Нужный результат:

- glyph system принадлежит самой игре
- glyph system можно точно контролировать
- glyph system не зависит от случайного шрифта
- glyph system later проще переносить между runtime layers

Коротко:

```text
glyphs are part of the canon
not borrowed decoration
```

## 3. What procedural means here

`Procedural` в этом документе не значит:

- случайная генерация
- шумовые формы
- каждый раз новый символ

Это значит:

- у каждого оператора есть фиксированная геометрия
- эта геометрия задаётся кодом
- runtime рисует её из primitive strokes / shapes

То есть:

```text
stable code-defined glyphs
```

## 4. Operator set

Нужно процедурно определить все `10` glyph families:

- `▽ FLOW`
- `☰ CONNECT`
- `☷ DISSOLVE`
- `☵ ENCODE`
- `☳ CHOOSE`
- `☴ OBSERVE`
- `☲ CYCLE`
- `☶ LOGIC`
- `☱ RUNTIME`
- `△ MANIFEST`

## 5. Placement law

Glyph placement для разных card classes должен различаться.

### Minor cards

У minor-карт glyphs должны:

- поддерживать diagonal operator composition
- быть компактными
- не ломать split-geometry карты
- работать как grammar marks

### Trump cards

У trump-карт glyphs должны:

- жить по другому placement law
- ощущаться более ceremonial / event-like
- не читаться как просто уменьшенная minor-layout схема

Коротко:

```text
same glyph canon
different placement law by card class
```

## 6. Temporary text reduction

На ближайшем шаге с карт нужно убрать шумные временные названия.

То есть:

- card titles in runtime should be reduced or removed
- glyphs should become the primary face identity signal

Это делается потому что сейчас:

- текст забивает face
- visual grammar карты читается хуже

## 7. What may remain temporarily

На переходном этапе допустимо оставить:

- debug id
- small class marker
- minimal operator labels during development

Но это не должно снова превращать карту в текстовую плитку.

## 8. Relationship to color law

Glyph system не заменяет color canon.

Нужная связка такая:

```text
color = operator field identity
glyph = operator form identity
```

То есть:

- цвет и форма должны работать вместе
- glyph не должен отменять split-composition
- split-composition не должен убивать glyph readability

Current branch for that relationship:

```text
dark field + pure operator-color glyph
```

То есть этот документ сейчас нужно читать
не вместе с `GLYPH_INK_LAW.md` как равным каноном,
а вместе с:

- [CARD_FACE_COLOR_DIRECTION.md](./CARD_FACE_COLOR_DIRECTION.md)
- [CARD_FIELD_DARKENING.md](./CARD_FIELD_DARKENING.md)

## 9. Implementation law

Когда этот слой дойдёт до кода,
нужно делать:

- один canonical glyph renderer
- таблицу `operator -> draw function`
- class-specific placement maps for:
  - minor
  - trump

Не делать:

- вручную рисовать каждый glyph по месту как ad hoc patch
- смешивать glyph logic с unrelated gameplay code

## 10. What this document does not decide yet

Этот документ пока не фиксирует:

- точные stroke coordinates каждого glyph
- exact line thickness
- final anti-aliasing style
- final placement metrics in pixels

Это следующий подслой.

Но главный путь уже зафиксирован:

```text
procedural glyph system
```

## 11. Short formula

```text
glyphs are code-defined canonical forms
titles step back
operator identity moves from text toward color + symbol
```
