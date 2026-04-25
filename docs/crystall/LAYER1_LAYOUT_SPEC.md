# Layer 1 Layout Spec

Статус:

```text
canonical crystall layout spec
```

Этот документ фиксирует
не общий visual direction,
а уже конкретную layout-геометрию первого слоя.

Он относится к:

```text
board engine skeleton / dev mode surface
```

Не к gameplay.
Не к финальному card design.
Не к позднему polished UI.

## 1. Scope

Этот документ отвечает на вопрос:

```text
как именно должен быть собран стол в layer 1
```

Он опирается на:

- [LAYER1_BOARD_SKELETON_SPEC.md](./LAYER1_BOARD_SKELETON_SPEC.md)
- [BOARD_ENGINE_SKELETON_TZ.md](./BOARD_ENGINE_SKELETON_TZ.md)
- [PLATFORM_REQUIREMENTS.md](./PLATFORM_REQUIREMENTS.md)
- [FIRST_PROTOTYPE_VISUAL_TARGET.md](./FIRST_PROTOTYPE_VISUAL_TARGET.md)

Он теперь фиксирует не только target-form,
но и текущий accepted baseline после реального runtime pass.

## 2. Baseline resolution

Все значения ниже задаются для baseline:

```text
1280x720
```

На других разрешениях
layout может масштабироваться,
но исходный закон формы берётся отсюда.

## 3. Main composition

Стол должен быть разбит так:

### Left block

- `deck`
- `runtime`

### Top center block

- `targets`
- `trump zone`

### Main center block

- `manifest + latent` как одно большое поле

### Bottom center block

- `hand`

### Right block

- `system`
- `log`
- `grave`

Это и есть текущая принятая схема первого слоя.

## 4. Layout corrections from current prototype

По итогам первого визуального прогона
должны быть зафиксированы такие правки:

1. `deck` надо сделать заметно больше  
   и дать ему более сильный левый anchor weight.

2. `runtime` надо держать отдельно в левом нижнем углу,
   а не рядом с `hand`.

3. Верхний блок `targets + trump zone`
   надо сдвинуть правее,
   чтобы он сидел ближе к центру экрана.

4. `manifest / latent` надо сделать шире,
   потому что это главное поле игры.

5. Между картами в `manifest / latent`
   допустимо дать больше воздуха,
   чем в текущем runtime.

6. `manifest` и `latent` допустимо объединить
   в одно внешнее поле,
   но с явным внутренним разделителем между слоями.

7. `system` должен остаться сверху справа,
   но с меньшим шрифтом и меньшим визуальным шумом.

8. `grave` и `log` должны быть разделены
   как два отдельных правых блока.

Статус:

```text
accepted in current runtime
```

## 5. Card metrics

Базовый card footprint для layer 1:

```text
82 x 118 px
```

Это не финальный закон карточного дизайна.
Это runtime-layout metric для первого слоя.

Допускается небольшой later adjustment,
но текущий baseline надо держать близко к этому размеру.

## 6. Horizontal law

### Targets

`targets` должны читаться как:

```text
3 card slots
```

и должны быть размещены
не у левого края центрального пространства,
а ближе к оптическому центру экрана.

Практически это значит:

- блок `targets` короткий
- блок `trump zone` стоит рядом
- вся верхняя связка сдвинута правее

Текущий accepted state:

- `targets` сидит отдельно ближе к центру
- `trump zone` сидит отдельно правее
- они больше не читаются как одна слитая общая капсула

### Trump zone

`trump zone` остаётся в одной верхней полосе с `targets`.

Практически:

- справа от `targets`
- короткий самостоятельный блок
- визуально читаетcя как сосед targets
- не опускается в левую колонку

Текущий runtime уже использует именно это чтение.

### Manifest + latent

Центральный блок больше не нужно чрезмерно ужимать.

Он должен быть:

```text
шире текущего runtime
```

потому что это главное поле игры.

Важно:

- поле должно занимать больше горизонтального веса
- допускается больший gap между карточными слотами
- блок должен ощущаться главным столом,
  а не просто компактной матрицей

Текущий accepted state:

- внешний panel уже шире ранних версий
- главное поле уже визуально доминирует над верхними служебными зонами
- внутренние gaps увеличены

## 7. Vertical law

Вертикальный порядок:

1. верхняя линия:
   - `deck`
   - `targets`
   - `trump zone`
   - `system`

2. центральная линия:
   - объединённое поле `manifest / latent`
   - справа `log`

3. нижняя линия:
   - `runtime` слева
   - `hand` внизу по центру
   - `grave` справа

Это важный сдвиг:

```text
runtime returns to the lower-left corner
grave keeps its own lower-right block
```

## 8. Combined manifest-latent field

Для layer 1 допустима следующая форма:

- один внешний panel frame
- верхняя часть = `manifest`
- нижняя часть = `latent`
- между ними явный divider

Важно:

- divider должен быть визуально простым
- `manifest` и `latent` всё ещё должны быть отдельно подписаны
- колонка `1..5` должна читаться сквозным образом

## 9. Right column law

Правая колонка больше не должна быть одной длинной служебной трубой.

Она должна быть разделена так:

### Top

- `system`

### Middle

- `log`

### Bottom

- `grave`

Логика:

- `system` остаётся маленьким status block
- `log` получает основную высоту
- `grave` получает самостоятельный визуальный вес

Это уже реализовано и принято как baseline layer-1 shape.

## 10. System block law

`system` в layer 1 не должен доминировать.

Поэтому:

- шрифт меньше текущего
- короткие строки
- только нужные structural counters

Текущий runtime это уже соблюдает.

Никакой fake economy туда не возвращать.

## 11. Runtime block law

`runtime` должен находиться:

```text
в левом нижнем углу
```

а не рядом с `hand`.

Причина:

- так он не спорит с центральной нижней рабочей зоной
- `hand` получает больше чистого центрального пространства
- левая сторона остаётся пространством инфраструктурных зон:
  ```text
  deck above
  runtime below
  ```

Текущий runtime это уже использует.

## 12. Deck block law

`deck` должен быть:

- выше
- заметнее
- крупнее по визуальному весу

чем в текущем runtime.

Задача:

- сделать колоду заметнее
- сохранить её как главный левый anchor
- не превращать левую сторону в перегруженную dashboard-колонку

## 12.5. Main table law

`manifest / latent` — это главное поле игры.

Поэтому:

- именно оно получает основную ширину
- именно оно может иметь больший gap между слотами
- именно оно должно визуально доминировать над `targets` и `trump zone`

Это не побочный центральный блок.
Это сердце стола.

## 13. Pixel-oriented baseline

Для baseline `1280x720`
надо держать такую практическую интуицию:

- outer margin: около `16 px`
- major gap: около `12-16 px`
- card gap inside ordered rows: около `12-14 px`
- section padding: около `12-16 px`

Это не final art grid,
но это уже рабочая crystall-геометрия.

## 14. What this document does not decide

Этот документ не решает:

- gameplay legality
- weak/strong UI
- operator icons
- final typography style
- final animation language
- final card-face contents

Он решает только:

```text
how the first layer board should be spatially assembled
```

## 15. Short formula

```text
deck gets bigger
runtime returns to lower-left
targets and trump move toward the center
manifest / latent becomes wider and more dominant
grave stays separate from log
system becomes quieter
```
