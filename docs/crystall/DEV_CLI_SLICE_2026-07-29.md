# Dev CLI Slice

Статус:

```text
crystall contract
источник: ../table/DEV_CLI_LAW.md
```

## 1. Несущее решение: форма проверки

`DEV_CLI_LAW §2` объявляет единицей работы кристалл, доведённый до `▲`, и оставляет открытым, что это значит. Здесь это закрывается.

```text
проверка — модуль, который ЦИТИРУЕТ раздел закона
           и отвечает за него одним из трёх исходов
```

Без цитаты покрытие невычислимо, и «довести до `▲`» остаётся словами.

## 2. Три исхода, а не два

```text
OK    закон соблюдается в проверенных позициях
FAIL  найдено нарушение
SKIP  проверка отказалась: предмет недостижим в текущей сборке
```

`SKIP` несущий. Он отличает **отложенный** закон от **непокрытого**:

```text
непокрытый   ни одна проверка его не цитирует
отложенный   проверка есть, она отработала и отказалась
```

Этим же закрывается `DEV_CLI_LAW §10.2`. Закон, который нельзя проверить до готовности козырной машины, получает проверку, возвращающую `SKIP` с причиной, а не отсутствие проверки.

## 3. Результат проверки

```lua
{
    cites   = "TURN_STEP_LAW §8",
    status  = "OK" | "FAIL" | "SKIP",
    reached = "played" | "planted",
    effects = "all" | "none" | "<список>",
    detail  = "строка, обязательна для FAIL и SKIP",
}
```

`reached` — требование `DEV_CLI_LAW §7`. Позиция, полученная расстановкой, валидна и не обязана быть достижимой, поэтому исход обязан это нести.

`effects` — потому что `OK` при `effects=none` и `OK` при `effects=all` разные утверждения.

## 4. Модуль проверки

```lua
-- src/check/<name>.lua
return {
    cites = {"TURN_STEP_LAW §8", "TURN_STEP_LAW §9"},
    run = function(opts) return {results = {...}} end,
}
```

```text
cites   разделы, за которые модуль отвечает
run     возвращает список результатов раздела 3
opts    seeds, steps, effects
```

Существующие проверки переносятся в эту форму: `logic_joker_check`, `step_invariant`, `observation_audit`, `session_check`.

## 5. Реестр и покрытие

```lua
src/check/init.lua
    M.modules()   -- перечисление модулей
    M.run(opts)   -- прогон всех, сбор результатов
    M.coverage()  -- цитируемые разделы против существующих
```

`coverage` читает `docs/table/`, извлекает из каждого файла заголовок и разделы вида `## N.`, и сопоставляет с цитатами.

```text
lua cli.lua check          прогон всех, сводка по исходам
lua cli.lua check <name>   один модуль
lua cli.lua coverage       покрытие законов
```

Вывод `coverage`:

```text
законов   94
разделов  <n>
цитируется <m>
непокрыто  <n-m>

TURN_STEP_LAW           8/9
WIN_CHECK_LAW           0/13
...
```

Цитата на несуществующий раздел — `FAIL` реестра, не молчание.

## 6. Ось эффектов

`DEV_CLI_LAW §4`, `§5`.

```lua
-- setup.start_game
state.setup_options.enabled_effects = normalize_effects(opts.enabled_effects)
-- nil = все, {} = ни одного, {SHUFFLE = true} = только названные
```

```lua
-- trump.lua, resolve_trump_card, между двумя событиями
transition.emit(state, "trump_effect_begin", {card_id = card_id, trump = name})

if effect_enabled(state, name) then
    ... существующее тело без изменений ...
else
    transition.emit(state, "trump_effect_stubbed", {card_id = card_id, trump = name})
end

transition.emit(state, "trump_effect_end", {card_id = card_id, trump = name})
```

Единственная точка вмешательства. Всё до `trump_effect_begin` и всё после `trump_effect_end`, включая `resolve_trump_zone_entry`, не трогается.

`normalize_effects` повторяет форму `normalize_enabled_trumps`: принимает имена, `TRUMP-<n>` и числа.

## 7. Заголовок журнала

`DEV_CLI_LAW §6`.

```text
# seed=7 trumps=full effects=none
```

```text
поле       значения
seed       число
trumps     full | none | список
effects    all | none | список
```

Отсутствие `effects` читается как `all`: журналы, записанные до введения оси, остаются валидными.

Разбор и запись — `session.read` и `session.write`.

## 8. Тумблер

`DEV_CLI_LAW §3`.

```text
умолчание          полная поверхность
--honest           честная
```

Флаг не пишется в журнал и не влияет на переигрывание.

```text
session show            inspect.snapshot + interaction
session show --honest    view.format(view.observe)
```

Отладочные команды продолжают печатать баннер по `MACHINE_CLI_LAW §1`, эта часть закона не заменена.

## 9. Пометка расстановки

`DEV_CLI_LAW §7`.

```lua
session.rebuild(log) -- дополнительно возвращает planted = true,
                     -- если журнал содержит хотя бы одну запись plant
```

Проверка, строящая позицию через `session.plant` или прогоняющая журнал с `planted`, обязана вернуть `reached = "planted"`.

Сводка прогона печатает число результатов, полученных через расстановку, отдельной строкой.

## 10. Вырожденные случаи

```text
модуль без cites              ошибка реестра
цитата на исчезнувший раздел  FAIL реестра
FAIL или SKIP без detail      ошибка реестра
effects со списком, где имя
  не из TRUMP_CANON           ошибка разбора при старте
пустой список effects         эквивалент none
```

## 11. Проверки среза

```text
1. effects=none: в трассе нет ни одного эффекта козыря,
   но есть trump_flow_entry, step_trump_begin, step_trump_end
   и вход в козырную зону
2. effects=none и effects=all: состав деки после setup совпадает
   покарточно
3. effects=SHUFFLE: срабатывает только SHUFFLE, остальные дают
   trump_effect_stubbed
4. заголовок с effects переживает запись и чтение
5. заголовок без effects читается как all
6. цитата на несуществующий раздел даёт FAIL реестра
7. проверка, прошедшая через plant, возвращает reached=planted
8. coverage: сумма цитируемых и непокрытых равна числу разделов
```

Пункт 2 — контрольный: он отличает ось эффектов от оси присутствия. Расхождение означало бы, что заглушка меняет игру, а не только эффект.

## 12. Порядок

```text
1. форма результата и модуль проверки (разделы 3, 4)
2. реестр и coverage (раздел 5)
3. перенос четырёх существующих проверок в форму
4. ось эффектов (раздел 6)
5. поле effects в заголовке (раздел 7)
6. тумблер (раздел 8)
7. пометка расстановки (раздел 9)
8. проверки раздела 11
```

Шаги 1–3 не меняют поведения игры и дают число покрытия. Шаг 4 первый, который трогает ядро.

---

Автор закона: slasten, 2026-07-29.
Контракт: Opus 5 (claude-opus-5).

---

machines only. not for humans.
