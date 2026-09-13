# Deck Module Slice

Статус:

```text
crystall contract
источник: ../table/DECK_MODULE_LAW.md
          ../table/DECK_LAW.md
          ../table/FLOW_RING_LAW.md
          ../table/TARGET_ZONE_LAW.md §6.1
давление: ../chaos/DECK_MODULE_2026-07-31.md
          ../chaos/ARCHITECTURE_MIGRATION_2026-07-31.md

REVISION: 2, 2026-08-02
OWNER: slasten
REPLACES: §3, DISPATCH козыря; §10, проверка 3
REASON: источник изменён — DECK_MODULE_LAW §5.1a. Модуль козыря
        не отправляет; иначе стрелка deck -> trump замыкает цикл
        с trump -> deck и воспроизводит причину трёх копий
```

Первый модуль новой архитектуры. Пишется **рядом** со старым кодом; старые пути удаляются только после приёмки.

## 1. Файл и поверхность

```lua
-- src/core/deck.lua
local M = {}

M.can_serve(state)                     -- есть ли что выдать. НЕ пишет
M.take(state, request)                 -- ВЗЯТЬ, §3
M.give_back(state, card_ids, options)  -- ВЕРНУТЬ, §4
M.rotate_ring(state)                   -- ПЕРЕУПОРЯДОЧИТЬ, контракт FLOW, §5
M.place_ordered(state, card_ids)       -- ПЕРЕУПОРЯДОЧИТЬ, позиционная, §6

return M
```

Модуль не требует `turn`, `trump`, `repair`, `win`. Зависимости только вниз: `state`, `transition`.

Это **несущее** свойство, а не гигиена импортов: на нём стоит возможность козырной машины требовать модуль, а значит и смерть трёх копий. `DECK_MODULE_LAW §5.1a`.

```text
чтение зон снаружи НЕ запрещено. DECK_MODULE_LAW §2
```

## 2. Форма запроса

```lua
request = {
    asker       = "minor" | "player" | "trump",   -- DECK_MODULE_LAW §6
    zone        = "latent" | "targets" | "manifest" | "hand",
    slot        = <число или nil>,
    reveal      = <булево>,        -- решает шаг STATE
    destination = <"grave" | "hand" | nil>,  -- куда минор после DISPATCH
}
```

`asker` обязателен. `destination` обязателен, если `reveal = true` и карта может оказаться минором: `DECK_LAW §7` запрещает умолчание.

## 3. ВЗЯТЬ

Шаги `DECK_MODULE_LAW §5.1`.

```lua
function M.take(state, request)
```

```text
ASK       request.asker назван. Модуль НЕ проверяет право просить
AVAIL     нечем -> nil, "deck_exhausted". Вердикт не выносится
TAKE      снять с вершины
STATE     reveal=false -> hide_card;  reveal=true -> reveal_card
PLACE     положить в request.zone / slot
DISPATCH  только если STATE дал revealed
```

**Возврат:**

```text
успех, минор          card_id, nil, "minor"
успех, козырь         card_id, nil, "trump"
выдать нечем          nil, "deck_exhausted"
не назван asker       nil, "unsigned_request"
reveal без назначения nil, "destination_required"
```

Третье значение — **класс** — обязательная часть контракта, а не удобство: на нём стоит маршрутизация козыря у просителя. При `reveal = false` класс всё равно возвращается: он известен после `TAKE`, а прятать его значит заставить просителя лезть в `state.cards` самому.

Отказ громкий и **не** в виде голой пары на границе действия: вызывающий оборачивает его в переход, `TRANSITION_LAW §7`. Внутри модуля пара допустима — это не граница действия.

**DISPATCH по классу**, `DECK_LAW §6` и `DECK_MODULE_LAW §5.1a`:

```text
минор   -> request.destination. Кладёт МОДУЛЬ
козырь  -> модуль НЕ отправляет. Возвращает card_id и класс "trump";
           маршрутизирует ПРОСИТЕЛЬ одним вызовом
```

Поэтому `deck.lua` не требует `trump`: стрелка `deck -> trump` замкнула бы цикл с `trump -> deck`, а козырная машина обращается к модулю постоянно — `FOOL`, `ORACLE`, `RUSH` берут, `HALT` и разряд камеры возвращают. Тот же цикл `draw -> trump` уже породил три копии операций деки внутри `trump.lua`, `§9`.

```text
STATUS: LEGACY
CANONICAL: NO
SUPERSEDED_BY: настоящий раздел, редакция 2
REVISION: 1

успех   card_id

козырь  -> enter_trump_flow. Модуль вызывает козырную машину ОДНИМ вызовом
минор   -> request.destination
```

```text
порядок нерушим: PLACE никогда не раньше TAKE, STATE не позже PLACE
```

`DECK_MODULE_LAW §5.4`. Нарушение первого даёт карту в двух зонах и вечный цикл в потребителе.

## 4. ВЕРНУТЬ

```lua
function M.give_back(state, card_ids, options)
-- options = {shuffle = true|false, reason = "<строка>"}
```

```text
ASK
STATE   вход в ТЕЛО деки -> hide_card ВСЕГДА. DECK_LAW §2
PLACE
ORDER   options.shuffle -> перемешать через state.rng
```

```text
исключений нет: revealed и known входят СКРЫТЫМИ
```

Это снимает разошедшиеся копии прототипа: `shuffle_into_deck` и переполнение камеры делали разное, теперь одно.

`state.rng` обязателен. Падение на `math.random` запрещено: журнал переигрывается на машине без настроек.

## 5. ПЕРЕУПОРЯДОЧИТЬ: кольцо

```lua
function M.rotate_ring(state)
```

Привилегированный контракт `FLOW`, `DECK_MODULE_LAW §10`. Карту не выдаёт и не принимает.

```text
SELECT  подвижны позиции с НЕ-revealed картой. FLOW_RING_LAW §2
MOVE    каждая подвижная -> в следующую подвижную по кольцу
STATE   вошедшая в ТЕЛО деки -> hide_card. Вершина ИСКЛЮЧЕНА, DECK_LAW §3
```

```text
подвижных меньше двух -> ничего не происходит, событие о пропуске
```

Вершина определяется как последняя позиция деки. `known` там законен и сокрытием не затрагивается.

Второй режим при целиком раскрытом латенте — `FLOW_RING_LAW §8.1` — следствие `SELECT`, отдельной ветки не требует.

## 6. ПЕРЕУПОРЯДОЧИТЬ: позиционная укладка

```lua
function M.place_ordered(state, card_ids)
```

Для `ORACLE` ред. 2: карты возвращаются по номерам, **последняя становится вершиной**.

```text
STATE   все, кроме последней, -> hide_card
        последняя -> состояние не меняется. DECK_LAW §3
```

Интерфейс не заперт на одну карту: `DECK_MODULE_LAW §11`.

## 7. События

```text
deck_take              card_id, asker, zone, slot, revealed, class
deck_exhausted         asker, zone, slot
deck_give_back         cards, shuffled, reason
deck_ring_rotated      moved, anchors
deck_ring_skipped      movable, reason
deck_placed_ordered    cards
```

Имена с префиксом `deck_`: поток событий — приёмочная поверхность миграции (`TRANSITION_LAW`), и новый модуль обязан быть отличим от старых путей.

## 8. Вырожденные случаи

```text
дека пуста, asker=minor     nil, "deck_exhausted". Минорная машина
                            обращается к модулю исхода. Поражение
дека пуста, asker=player    nil, "deck_exhausted". Партия продолжается
дека пуста, asker=trump     nil, "deck_exhausted". DECK_MODULE_LAW §8,
                            третья строка — НЕ РЕШЕНО. Модуль отвечает
                            одинаково; решает вызывающий
give_back пустого списка    ничего, событие не эмитится
rotate_ring на пустой деке  подвижных меньше двух -> пропуск
place_ordered одной карты   она становится вершиной, состояние не меняется
take в зону вне закрытости  разрешено: hand не входит в закрытость
```

## 9. Утверждения единственности

```text
pop_topdeck существует в ОДНОМ месте: src/core/deck.lua
place_card(..., "deck") вызывается ТОЛЬКО из src/core/deck.lua
ring_set_card существует в ОДНОМ месте: src/core/deck.lua
```

Это ядро приёмки. Прототип держал два `pop_topdeck`, два `concealed_refill` и два `repair_manifest_slot`, и одна пара разошлась молча.

## 10. Проверки среза

```text
1.  take с reveal=false          карта скрыта, DISPATCH не выполнялся
2.  take с reveal=true, минор    ушёл в request.destination
3.  take с reveal=true, козырь   ВОЗВРАЩЁН с классом "trump", в поток
                                 НЕ вошёл, destination не нужен
4.  take без asker               nil, "unsigned_request"
5.  take с reveal без назначения nil, "destination_required"
6.  take при пустой деке         nil, "deck_exhausted" для ВСЕХ трёх asker
7.  КОНТРОЛЬ: asker=player при
    пустой деке                  партия НЕ кончается
8.  give_back revealed карты     она в теле деки СКРЫТА
9.  give_back known карты        то же
10. rotate_ring                  в теле деки нет revealed и нет known
11. КОНТРОЛЬ: known на ВЕРШИНЕ
    после rotate_ring            остался known
12. place_ordered                последняя карта на вершине,
                                 остальные скрыты
13. СТРУКТУРНАЯ: pop_topdeck
    вне deck.lua                 ноль вхождений
14. СТРУКТУРНАЯ: place_card
    в "deck" вне deck.lua        ноль вхождений
15. СТРУКТУРНАЯ: deck.lua не
    требует turn/trump/repair/win ноль require
16. СТРУКТУРНАЯ: math.random
    в deck.lua                   ноль вхождений
```

Что ловит каждая:

```text
1        вход в зону топдека по РАСКРЫТИЮ, а не по извлечению. DECK_LAW §5
3        то же, плюс односторонность DISPATCH: модуль козыря НЕ отправляет.
         Ловит возврат стрелки deck -> trump, то есть причину трёх копий
2, 5     умолчание назначения, запрещённое DECK_LAW §7
6, 7     политика по просителю. Седьмая — контроль: без неё правило
         «дека не может -> поражение» распространилось бы на игрока
8, 9     тело деки как закрытая информация. Тихий отказ:
         доска валидна, а в кольце появляются вечные анкеры
10, 11   сокрытие при вращении, и что оно НЕ накрыло вершину.
         Одиннадцатая ловит переусердствование
13-15    единственность. Свойство всего набора файлов, чтением не видно
16       воспроизводимость журнала на машине без настроек
```

Проверки 1-12 поведенческие, строятся расстановкой: `reached = "planted"`. Проверки 13-16 структурные.

## 11. Ожидаемое расхождение эталона

```text
ожидается
```

Имена событий новые (`§7`), значит трассы разойдутся на каждом пути, переведённом на модуль.

```text
эталоны перезаписываются ПОСЛЕ приёмки модуля, не до
```

Эталоны уже разошлись дважды и не перезаписаны: `STEP_CHECK_SLICE §7`, `DECK_LAW_SLICE §8`. Все три перезаписи делаются одной операцией.

## 12. Порядок

```text
1. src/core/deck.lua: can_serve, take, give_back
2. rotate_ring и place_ordered
3. проверки §10, включая структурные 13-16
4. перевод вызовов минорной машины на модуль
5. перевод вызовов козырной машины
6. УДАЛЕНИЕ старых путей: pop_topdeck x2, concealed_refill x2,
   repair_manifest_slot x2, ring_set_card, flow_ring_rotate
7. перезапись эталонов — ПОСЛЕДНЕЙ
```

Пункты 1-3 не трогают существующий код: модуль пишется рядом и принимается отдельно. Игра работает на каждом шаге.

Структурные проверки 13-15 станут зелёными только после пункта 6 и до тех пор возвращают `FAIL` — это ожидаемо и означает «миграция не завершена», а не дефект.

---

Автор закона: slasten, 2026-07-31 и 2026-08-01.
Контракт: Opus 5 (claude-opus-5).

---

machines only. not for humans.
