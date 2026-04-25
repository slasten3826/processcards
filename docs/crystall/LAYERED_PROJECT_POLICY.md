# Layered Project Policy

Статус:

```text
canonical crystall policy
```

Этот документ фиксирует главный рабочий закон проекта:

```text
мы собираем ProcessCards по слоям
```

Не всё сразу.
Не gameplay, runtime и card design вперемешку.
Не desktop-first прототип, который потом больно переносить.

Сначала разделяем слои.
Потом строим каждый слой отдельно.

## 1. Why this exists

`ProcessCards` должен потом проще переноситься:

- между рантаймами
- между платформами
- между input-моделями
- между visual shells

Чтобы это было реально,
надо в самом начале не смешивать:

- механику игры
- реализацию рантайма
- конкретный вид карт

Именно поэтому проект делится на слои документации и слои разработки.

Этот policy согласован с тем принципом,
который уже используется в `packet3`:

- логика не должна быть сцеплена с presentation
- platform/runtime слой не должен владеть truth игры
- визуальная манифестация должна опираться на уже названную машину,
  а не подменять её собой

## 2. Core layered formula

```text
table -> crystall -> manifest
```

Где:

- `table` = игровая машина
- `crystall` = runtime и implementation shell
- `manifest` = конкретный вид, карта, визуальный язык, card-face design

`chaos` остаётся upstream/history/source слоем,
но не считается рабочим implementation layer.

## 3. Table layer

`docs/table/` владеет:

- механикой игры
- законами зон
- weak/strong laws
- operator laws
- duplicate law
- target and runtime laws как игровые законы
- тем, что вообще разрешено игре как машине

`table` не владеет:

- LÖVE-циклами
- layout-метриками движка
- input plumbing
- animation implementation
- конкретным графическим видом карт

Коротко:

```text
table defines game truth
```

## 4. Crystall layer

`docs/crystall/` владеет:

- выбором runtime
- platform constraints
- input model
- zone engine skeleton
- update/render architecture
- portability policy
- implementation phases
- тем, как table truth получает исполнимую форму

Сейчас это означает:

- `Lua + LÖVE` как текущий runtime path
- `PC + hacked Switch` как primary targets
- `720p` как baseline
- selection-first interaction
- drag/drop только как enhancement

`crystall` не владеет:

- изобретением новых правил игры
- подменой unresolved table-law удобной реализацией
- конкретным финальным card art

Коротко:

```text
crystall defines how game truth becomes runnable
```

## 5. Manifest layer

`docs/manifest/` владеет:

- видимой картой проекта
- навигацией по документации
- later card-face design direction
- later visual identity of cards
- later readable presentation of concrete card content

Для `ProcessCards` это особенно важно:

`manifest` не должен раньше времени диктовать,
как будто игра уже собрана.

Сначала:

- зона
- состояние
- правило

Потом:

- face design
- layout polish
- final visible card language

Коротко:

```text
manifest defines visible design
```

## 6. Practical development order

Проект собирается так:

1. `table`
2. `crystall`
3. code
4. `manifest` detail/polish

То есть:

1. сначала понимаем механику
2. потом фиксируем исполнимый runtime-layer
3. потом пишем код
4. потом дожимаем видимую форму и конкретный дизайн карт

## 7. Portability law

Это разделение нужно не ради красивой схемы.

Оно нужно, чтобы потом было проще:

- переносить игру с PC на Switch-class hardware
- менять visual shell
- делать browser-preview отдельно от main runtime
- держать button/mouse/touch input без полного переписывания игры

Если слойность ломается,
портируемость ломается сразу.

## 7.5. Documentation preservation law

Старые документы проекта не надо удалять,
если они перестали быть current canon.

Правильное поведение такое:

```text
keep the old document
mark it as legacy / superseded / historical draft
write the new truth separately
```

Это нужно потому что для `ProcessCards`
ценность есть не только у текущего закона,
но и у пути, которым игра к нему пришла.

Неправильно:

- тихо переписывать старый документ так,
  будто прошлой версии не было
- удалять старые drafts,
  если они ещё помогают читать эволюцию проекта

Правильно:

- сохранять lineage
- явно маркировать current truth
- явно маркировать legacy truth

## 8. Immediate implication for current work

Текущая ближайшая задача:

```text
board engine skeleton
```

Она уже относится к `crystall`,
а не к `table`.

Но:

- сами зоны и их игровая роль всё ещё идут из `table`
- внешний вид пустых карт и surface layout пока ещё не являются final `manifest`

## 9. Short formula

```text
table names the game
crystall makes it runnable
manifest makes it visible
```
