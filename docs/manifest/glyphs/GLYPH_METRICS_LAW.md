# Glyph Metrics Law

Статус:

```text
manifest glyph canon
```

Этот документ фиксирует не placement глифа на карте,
а его внутреннюю метрику.

То есть он отвечает не на вопрос:

```text
where does the glyph go on the card
```

а на вопрос:

```text
what x,y means for every glyph family
and what local box every glyph must obey
```

Связанные документы:

- [GLYPH_PLACEMENT_LAW.md](./GLYPH_PLACEMENT_LAW.md)
- [TRIGRAMS.md](./TRIGRAMS.md)
- [FLOW.md](./FLOW.md)
- [MANIFEST.md](./MANIFEST.md)
- [RUNTIME_SPECIAL.md](./RUNTIME_SPECIAL.md)
- [../GLYPH_SYSTEM_V1.md](../GLYPH_SYSTEM_V1.md)

## 1. Core problem

Сейчас разные glyph families могут читать переданную точку `(x, y)` по-разному:

- triangles как геометрический центр формы
- trigrams как набор полос,
  собранных от своей внутренней базовой линии
- special runtime variant как ещё один отдельный случай

Практический результат:

- одни глифы визуально уезжают вверх или вниз
- у других плывёт optical center
- часть триграмм кажется шире или уже соседних glyph families

Это запрещено.

## 2. Canonical interpretation of `(x, y)`

Для всех glyph families:

```text
(x, y) = optical center of the glyph box
```

Не:

- baseline
- top anchor
- bottom anchor
- center of the first stroke

А именно:

```text
visual / optical center of the full glyph footprint
```

## 3. Canonical local box

Каждый glyph должен существовать внутри одной и той же локальной рамки.

Базовый закон:

```text
glyph local box = square centered at (x, y)
```

Для текущего слоя достаточно считать,
что рабочая зона глифа укладывается в:

- width: `~1.2 × gs`
- height: `~1.2 × gs`

Точная доля может чуть плавать,
но optical center и общий footprint должны совпадать.

## 4. Family equality law

Разные glyph families не обязаны иметь одну и ту же геометрию,
но обязаны иметь сопоставимую метрику.

Это значит:

- `▽ FLOW` и `△ MANIFEST` не должны казаться меньше триграмм
- trigram families не должны визуально висеть ниже triangles
- `☱ RUNTIME` не должен менять центр только потому,
  что он рисуется `line`, а не `fill`

Коротко:

```text
different forms
same metric discipline
```

## 5. Triangle law

Для triangle glyph families:

- форма строится вокруг центра box
- apex и base должны быть уравновешены относительно `(x, y)`
- треугольник не должен оптически заваливаться вверх или вниз

Следствие:

- `FLOW`
- `MANIFEST`

должны использовать одну и ту же metric model,
только с разной вертикальной ориентацией.

## 6. Trigram law

Для trigram glyph families:

- вся трёхлинейная конструкция должна быть центрирована как единый блок
- `(x, y)` не может означать центр одной из линий
- нижняя, средняя и верхняя линии должны балансироваться вокруг общей midline

То есть:

```text
the trigram is one centered object
not three lines growing upward from a base
```

Это особенно важно для:

- `CONNECT`
- `DISSOLVE`
- `ENCODE`
- `CHOOSE`
- `OBSERVE`
- `CYCLE`
- `LOGIC`
- `RUNTIME`

## 7. Runtime special law

`RUNTIME` остаётся special-case только по draw mode:

- `line`
instead of
- `fill`

Но не по метрике.

То есть:

```text
RUNTIME may differ in stroke mode
RUNTIME may not differ in box center law
```

## 8. Width and left-right balance

Glyph считается плохим,
если при одинаковом `(x, y)` он:

- визуально тянет влево
- визуально тянет вправо
- кажется уже или шире соседних glyph families без намеренного закона

Следствие:

- left/right extents должны быть симметричны вокруг центра
- контурные glyphs не должны “съедать” пол-ширины по сравнению с filled glyphs

## 9. Height and up-down balance

Glyph считается плохим,
если при одинаковом `(x, y)` он:

- кажется висящим слишком высоко
- проседает вниз
- имеет другой perceived center, чем соседняя family

Следствие:

- top/bottom extents тоже должны балансироваться вокруг центра
- особенно внимательно надо проверять триграммы и triangles рядом друг с другом

## 10. Placement consequence

`GLYPH_PLACEMENT_LAW.md` должен работать только после нормализации метрики.

То есть:

1. сначала glyph family obeys `GLYPH_METRICS_LAW`
2. потом placement law раскладывает glyphs по card class

Не наоборот.

Иначе placement на карте будет правиться бесконечно,
а проблема останется внутри самих glyph functions.

## 11. Debug interpretation

При визуальной проверке вопрос должен быть не:

```text
this card needs a slightly different anchor
```

А сначала:

```text
does this glyph obey the same local box and optical center law as the others
```

То есть first suspect:

- glyph metrics

а не:

- card placement

## 12. Implementation consequence

Когда пойдём в код,
нужно будет сделать одно из двух:

1. либо ввести нормализованный local coordinate system для каждой glyph family
2. либо пересобрать helper functions так,
   чтобы они действительно рисовали от общего центра

Но в любом случае правка должна идти не ad hoc по каждой карте,
а через общий metric law.

## 13. Short formula

```text
every glyph family may differ in shape
but all glyph families must share one optical-center law
and one normalized local box discipline
```
