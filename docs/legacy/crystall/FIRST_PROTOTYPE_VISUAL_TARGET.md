# First Prototype Visual Target

Статус:

```text
canonical crystall target
```

Этот документ фиксирует,
что именно мы хотим увидеть от первого прототипа
как от визуальной и пространственной поверхности.

Это не полный rulesheet
и не implementation plan.

Это документ про:

- layout
- визуальную иерархию
- плотность информации
- что должно быть на столе в первом слое

Если нужен уже более жёсткий spatial baseline,
читать также:

- [LAYER1_LAYOUT_SPEC.md](./LAYER1_LAYOUT_SPEC.md)

## 1. Main idea

Первый прототип должен выглядеть как:

```text
реальный карточный стол с живыми зонами
```

а не как:

- debug dashboard
- текстовая форма с картинками
- перегруженный rules UI

## 2. What must already be visible

На первом прототипе уже должны быть видны:

- `deck`
- `targets`
- `trump zone`
- `runtime`
- `manifest row`
- `latent row`
- `hand`
- `grave`
- `log`

Все эти зоны должны уже существовать как board reality.

## 3. Central focus

Центром экрана должен быть:

```text
manifest row + latent row
```

Это главное поле игры.

Именно они должны восприниматься как центр стола,
а не боковые панели.

## 4. Manifest / latent layout

Manifest и latent должны быть построены как:

```text
5 columns x 2 layers
```

Важно:

- latent находится прямо под manifest
- столбцы читаются как связанные пары
- визуальная связь колонок очевидна

## 5. Left / center / right structure

Предпочтительная композиция первого прототипа:

### Left column

- `deck`
- `runtime`
- `trump zone`

### Center

- `targets`
- `manifest`
- `latent`
- `hand`

### Right column

- небольшой `system status` block сверху
- `log` вертикальной колонкой на остальную высоту

## 6. Log placement

`log` лучше делать:

```text
right-side vertical column
```

а не нижней широкой полосой.

Почему:

- не съедает вертикальное пространство центра
- поддерживает процессуальную природу игры
- лучше ложится в `720p`

## 7. Density rule

Первый слой не должен быть слишком gameplay-loaded.

Это значит:

- без лишних counters
- без чужой экономики типа `health / shield / energy`
- без плотных текстовых описаний на картах
- без premature `legal / illegal` semantics на зонах,
  где gameplay ещё не включён

## 8. Card presentation in layer 1

На первом слое карты могут быть:

- blank
- placeholder
- simple dummy face
- id-card

Это допустимо.

На первом слое важнее:

- карта как сущность
- карта как face-up / face-down object
- карта как movable thing

а не её полный gameplay text.

## 9. What to avoid in layer 1

Не нужно тащить в первый visual layer:

- full action HUD with final semantics
- fake final counters
- target legality coloring as if target gameplay already exists
- длинные card texts
- лишнюю UI-декорацию

## 10. Readability target

Стол должен читаться сразу.

Игрок должен видеть:

- где колода
- где рука
- где manifest
- где latent
- где grave
- где runtime
- где targets
- где trump zone
- где история действий

без необходимости читать объясняющий текст.

## 11. Platform fit

Visual target must already respect:

- `1280x720` baseline
- desktop
- hacked Switch trajectory

Это значит:

- центральное поле не должно ломаться в `720p`
- лог не должен съедать manifest/latent
- стол не должен зависеть от огромного desktop canvas

## 12. Short formula

```text
first prototype should look like a clean living card table,
with manifest and latent as the center,
and log as a right-side history column
```

## 13. Current accepted baseline

На текущем этапе первый runtime уже принят как:

```text
good enough layer-1 visual baseline
```

Это не final polish.

Это значит:

- spatial hierarchy уже рабочая
- board surface уже читается как стол
- layout больше не блокирует следующий слой разработки
