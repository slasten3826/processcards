# Card Field Darkening (final)

Статус:

```text
canonical tuning document
```

Связанные документы:

- [CARD_FACE_COLOR_DIRECTION.md](./CARD_FACE_COLOR_DIRECTION.md) — общая концепция
- [glyphs/RUNTIME_SPECIAL.md](./glyphs/RUNTIME_SPECIAL.md)
- [STYLE_CANON.md](./STYLE_CANON.md)

Этот документ не заменяет `CARD_FACE_COLOR_DIRECTION.md` целиком.

Он делает только одно:

```text
locks the current darkening coefficient for the active face-color canon
```

## 1. Результат

Поле карты затемнено с коэффициентом `0.90`:

```lua
dark_a = lerp_color(op_color, COLORS.bg, 0.90)
```

10% цвета оператора, 90% фона.

Это компромисс между глубиной затемнения (чтобы глифы цвета оператора ярко читались)
и сохранением читаемости split-композиции (диагональ minor / вертикаль trump).

## 2. Пробы

| lerp | Эффект |
|------|--------|
| 0.55 | исходное — поля яркие, глифы теряются |
| 0.30 | слишком ярко для глифов |
| 0.75 | приемлемо, но split читается |
| 0.85 | хорошо, split ещё виден |
| 0.95 | слишком тёмно — split-композиция исчезает |
| **0.90** | **финал: тёмный фон, split читается, глифы яркие** |

## 3. Спец-случай RUNTIME

RUNTIME-поле больше не держится на почти чёрном графите.
Current runtime color is shifted toward steel-slate:

```text
{0.40, 0.46, 0.52}
```

Это позволяет сохранить:

- тёмную системную идентичность
- line-mode glyph
- but no forced white inversion

См. [glyphs/RUNTIME_SPECIAL.md](./glyphs/RUNTIME_SPECIAL.md).

## 4. Почему не вариант с разделителем

Рассматривался вариант с диагональной линией-разделителем вместо осветления фона.
Отложен в пользу текущего решения — проще, меньше кода, визуально чище.
