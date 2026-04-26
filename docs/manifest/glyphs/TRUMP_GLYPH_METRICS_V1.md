# Trump Glyph Metrics V1

Статус:

```text
current glyph refinement pass
```

Этот документ фиксирует важное ограничение текущего слоя:

```text
strict glyph-metrics refinement is applied to trumps first
minor glyph metrics remain provisional for now
```

Связанные документы:

- [GLYPH_METRICS_LAW.md](./GLYPH_METRICS_LAW.md)
- [GLYPH_PLACEMENT_LAW.md](./GLYPH_PLACEMENT_LAW.md)
- [RUNTIME_SPECIAL.md](./RUNTIME_SPECIAL.md)
- [../GLYPH_SYSTEM_V1.md](../GLYPH_SYSTEM_V1.md)
- [../../table/TRUMP_IDENTITY_LAW.md](../../table/TRUMP_IDENTITY_LAW.md)

## 1. Why trumps first

На текущем runtime layer именно trump cards сильнее всего показывают проблемы метрики:

- они крупнее читаются как отдельный класс
- у них более жёсткая симметрия левой и правой половины
- любая ошибка по высоте или ширине сразу видна
- special case `RUNTIME` сильнее бросается в глаза

Поэтому refinement pass начинается не с общего пересмотра всех glyph faces,
а с trump faces.

## 2. Scope of this pass

Этот документ касается только:

- glyph centering on trump cards
- visual equality of left and right trump glyph positions
- alignment of trigram and triangle families inside trump halves
- special runtime readability on trump faces

Этот документ пока не требует:

- немедленного полного переноса тех же метрик на minor cards
- полной замены minor glyph placement
- полного global glyph rewrite

## 3. Current split

Текущая дисциплина должна читаться так:

### Trumps

```text
strict metrics pass
```

Trump glyphs обязаны:

- obey one optical-center law
- obey one local-box discipline
- visually align inside the two event halves

### Minors

```text
provisional metrics pass
```

Minor glyphs пока могут оставаться на текущей рабочей системе,
если:

- карты уже читаются
- diagonal pair identity не разваливается
- refinement там пока не критичен

## 4. Trump-specific expectation

На trump face нельзя допускать:

- левый глиф визуально выше правого
- один glyph family уже другой без закона
- trigram block просажен вниз относительно triangle
- `RUNTIME` живёт в другой оптической системе, а не просто в другом draw mode

То есть trump face должен читаться как:

```text
two halves
two glyph boxes
one metric discipline
```

## 5. Relation to general glyph law

`GLYPH_METRICS_LAW.md` остаётся общим законом.

Но practical implementation priority сейчас такая:

1. fix trump metrics first
2. validate trump class readability
3. only then decide whether minor metrics need the same strict pass

То есть:

```text
general law exists
strict enforcement starts on trump cards
```

## 6. Relation to placement law

`GLYPH_PLACEMENT_LAW.md` продолжает описывать,
где на card face glyph pair размещается.

Но для trump cards placement сам по себе не считается достаточным.

Сначала glyph family должна obey:

- [GLYPH_METRICS_LAW.md](./GLYPH_METRICS_LAW.md)

Потом уже trump placement считается валидным.

## 7. What this does not decide yet

Этот документ пока не фиксирует:

- точные pixel offsets для trump glyphs
- whether minor glyphs will later inherit the same exact metric box
- whether trump glyphs need class-specific scale different from minors

Он фиксирует только рабочий приоритет:

```text
trumps first
minors later if needed
```

## 8. Short formula

```text
current strict glyph-metrics work belongs to trump faces
minor glyphs remain provisional until a later refinement pass
```
