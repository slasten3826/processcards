# Presentation Direction V1

Статус:

```text
future-facing crystall direction
```

Этот документ фиксирует
не текущий layer-1 skeleton,
а следующий визуальный горизонт проекта.

Source vision asset:

- [processcards_future_vision_v1.png](../manifest/vision_assets/processcards_future_vision_v1.png)

## 1. Purpose

Текущий runtime уже собран как:

```text
layer-1 board skeleton
```

Но проекту нужен следующий слой:

```text
functional presentation shell
```

Этот слой должен быть:

- красивее
- плотнее
- богаче визуально
- ближе к законченной игре

без потери читаемости.

## 2. What this document is

Это документ про:

- visual direction
- runtime presentation shell
- information styling
- panel language
- atmosphere and polish target

Это не документ про:

- weak/strong rules
- operator truth
- trump legality
- final card database

## 3. Main target feeling

Желаемое ощущение:

```text
ritual techno table
```

Не минималистичный wireframe.
Не casual mobile UI.
Не fantasy parchment.

А:

- dark ritual board
- restrained neon / ember highlights
- instrument-panel precision
- collectible-card weight

## 4. What must be preserved from layer 1

Даже при усилении presentation
нужно сохранить spatial truth,
которая уже собрана:

- `deck` слева
- `runtime` слева снизу
- `targets` сверху ближе к центру
- `trump zone` справа от targets
- `manifest / latent` как главное поле
- `hand` внизу
- `system / log / grave` справа

То есть presentation shell
не должен ломать board hierarchy.

## 5. Visual priorities

### Primary visual priority

```text
manifest / latent
```

Главное поле должно выглядеть самым значимым.

### Secondary visual priority

- `targets`
- `trump zone`
- `hand`

### Tertiary visual priority

- `system`
- `log`
- `grave`
- `runtime`
- `deck`

Это не значит,
что инфраструктурные зоны надо прятать.
Это значит,
что они не должны спорить с сердцем стола.

## 6. Panel language

Нужный тип панелей:

- тёмные глубокие поверхности
- тонкие светящиеся рамки
- лёгкие внутренние фаски
- технологические уголки и насечки
- умеренный glow, не кислотный

Панели не должны выглядеть как:

- голые debug boxes
- flat web cards
- случайный game HUD

## 7. Card-object language

Карты должны ощущаться как:

- физические ритуальные объекты
- плотные, дорогие, читаемые артефакты
- не просто white placeholder rectangles

Нужные свойства:

- выраженная рамка
- глубина
- поверхность
- центральная композиция
- operator identity

Подробный card-language выносится в отдельный manifest-doc.

## 8. Information density

Этот direction допускает более высокую плотность,
чем layer 1,
но не хаос.

Хорошая плотность:

- короткие counters
- компактные labels
- хорошо организованный log
- card-face с несколькими слоями информации

Плохая плотность:

- текстовая каша
- HUD-спам
- одинаковый вес у всего
- слабая иерархия

## 9. Color law

Базовая палитра:

- почти чёрный / тёмно-синий фон
- тёплые медно-золотые акценты
- бирюзово-циановые технологические свечения
- цветовые отличия между зонами и card families

Важно:

- не уходить в дешёвый sci-fi neon overload
- не делать всё одним оттенком
- не убивать читабельность тёмной кашей

## 10. Animation direction

Желаемое направление:

```text
Balatro-like card juice
```

То есть:

- чёткие перемещения
- лёгкие zoom / lift / snap
- уверенный hover/focus response
- ощущение веса карты
- небольшие pulse/highlight эффекты

Но:

- animation не должна маскировать неясный layout
- presentation не должна ломать portability

## 11. What to take from the vision asset

Из [processcards_future_vision_v1.png](../manifest/vision_assets/processcards_future_vision_v1.png)
мы хотим взять:

- общее настроение стола
- panel detailing language
- card-object richness
- правую service-column логику
- верхнюю service line
- visual weight of manifest/latent field

## 12. What not to take blindly

Не надо слепо тащить из vision asset:

- точные card texts
- fake integrity/chain counters как уже решённую механику
- все декоративные линии один-в-один
- любую визуальную деталь,
  если она мешает `720p` readability

Vision asset — это direction,
а не literal contract every pixel.

## 13. Relationship to current layer

Current layer:

- proves board truth
- proves zone structure
- proves dev-mode manipulation

Next presentation layer should:

- keep that truth
- enrich the shell
- make the game feel closer to its final objecthood

## 14. Short formula

```text
layer 1 proves the table
presentation v1 should make that table feel ritual, dense, and alive
```
