# Trump Flow Module Slice

Статус:

```text
crystall contract
источник: ../table/TRUMP_FLOW_MODULE_LAW.md
          ../table/TRUMP_FLOW_LAW.md
          ../table/TRUMP_ZONE_LAW.md
          ../table/HALT_MODE_LAW.md
давление: ../chaos/WHO_MAY_ENQUEUE_A_TRUMP_2026-08-02.md

OWNER: slasten
DATE: 2026-08-05
REVISION: 1
REPLACES: NONE
```

Четвёртый модуль новой архитектуры, уровень 2: просит только деку, не просит ни одну из двух машин.

## 1. Поверхность

```lua
-- src/core/trump_flow.lua
local M = {}

M.accept(state, card_id, request)  -- ПРИНЯТЬ, §3
M.hand_out(state)                  -- ВЫДАТЬ голову очереди, §4
M.take_back(state, card_id)        -- отработавший -> in_flight, §5
M.close(state)                     -- ЗАКРЫТЬ цепь, §6
M.is_empty(state)                  -- очередь пуста. НЕ пишет

return M
```

```text
зависимости: state, transition, deck
запрещены:   minor_machine, trump_machine
```

Вторая строка — несущая, и она же проверка 12. Модуль, потребовавший машину, замыкает тот самый цикл, ради разрыва которого он и выделен.

## 2. Пять состояний как данные

`TRUMP_FLOW_LAW §6` называет пять машинных терминов. Они кладутся в состояние явно, а не выводятся из порядка в одном списке:

```lua
state.trump_flow = {
    queue     = { <card_id>, ... },  -- ждут начала, FIFO
    current   = <card_id> | nil,     -- разрешается сейчас, РОВНО один
    in_flight = { <card_id>, ... },  -- отработали, не припаркованы
    halted    = { <card_id>, ... },  -- пришли после запрета HALT
}
state.trump_zone = { <card_id>, ... }  -- камера
```

```text
реализация вольна хранить как угодно, но различия обязана сохранить
```

`TRUMP_FLOW_LAW §6`. Сегодня прототип держит одну плоскую зону `trump_flow`, и различить в ней `queue` от `in_flight` нельзя — отсюда невозможность отличить «цепь ещё идёт» от «цепь закрылась и не припарковала».

## 3. ПРИНЯТЬ

```lua
M.accept(state, card_id, request) -> ok | nil, reason
-- request = {asker = "minor" | "trump" | "draw", reason = "<строка>"}
```

```text
ASK       проситель назван, §5 закона
GUARD     карта из ЦЕЛЕЙ не принимается никогда
STATE     reveal_card. В потоке нет закрытых, TRUMP_FLOW_LAW §4
CAPACITY  режим HALT: сверх ёмкости -> в halted, §3.1
PLACE     в хвост queue
```

Вход — **операция, а не укладка**: внутри решение по ёмкости. Основание — `TRUMP_FLOW_MODULE_LAW §3`.

### 3.1. Ёмкость

`HALT_MODE_LAW §2` и `§2.1`.

```text
HALT в потоке      ёмкость 2 = разрешающийся + сам HALT
в коде             занятых мест в queue не больше 1
сверх ёмкости      карта уходит в halted, НЕ в queue
```

Расхождение закона и кода на единицу — намеренное и записано в `HALT_MODE_LAW §2.1`. Контракт его повторяет, чтобы никто не «починил».

```text
halted разбирается только при ЗАКРЫТИИ, §6
```

Редакция 1 закона вытесняла в деку немедленно. Настоящий срез переносит слив в закрытие: пока цепь жива, `halted` — состояние, а не действие. Снаружи результат тот же, момент другой.

## 4. ВЫДАТЬ

```lua
M.hand_out(state) -> card_id | nil
```

```text
queue пуста          nil. Не ошибка
доска не закрыта     nil, "board_not_closed". BOARD_CLOSURE_LAW §1
иначе                голова queue -> current, возвращается card_id
```

```text
current ровно один. Второй ВЫДАТЬ при занятом current -> nil, "current_busy"
```

Порядок — `first caused, first resolved`, `TRUMP_RESOLUTION_ORDER_LAW §4`. Очередь, не стек.

## 5. ПРИНЯТЬ НАЗАД

```lua
M.take_back(state, card_id)
```

```text
current -> in_flight. current становится nil
```

```text
парковка в камеру здесь НЕ происходит
```

`TRUMP_RESOLUTION_ORDER_LAW §5`: `resolve now, park later`. Отработавший козырь остаётся в цепи, потому что `HALT` должен видеть весь её контур.

## 6. ЗАКРЫТЬ

```lua
M.close(state)
```

```text
обычное закрытие   in_flight -> камера, в порядке разрешения
                   каждый предлагается по одному, §6.1
halted             ВСЕ, кроме самого HALT, -> deck.give_back
                   с обязательным перемешиванием
HALT сам           уходит в камеру по обычному правилу
```

`TRUMP_RESOLUTION_ORDER_LAW §7`, `TRUMP_ECOLOGY §5`.

### 6.1. Камера и разряд

`TRUMP_ZONE_LAW §5`, `§6`.

```text
ёмкость          2, если не изменена. TIGEL удваивает текущую
предложение      козыри предлагаются ПО ОДНОМУ, в порядке разрешения
место есть       занимает слот
места нет        РАЗРЯД: этот козырь + всё содержимое камеры ->
                 deck.give_back с перемешиванием, камера пуста
после разряда    следующие продолжают предлагаться в пустую камеру
```

```text
разряд — событие ЗАКРЫТИЯ. Внутри цепи не бывает
```

`TIGEL` анкерится и обычным разрядом не вымывается: `TIGEL §3`. Он занимает слот внутри удвоенной ёмкости.

## 7. Отношение к деке

Единственная исходящая стрелка:

```lua
deck.give_back(state, card_ids, {shuffle = true, reason = "<строка>"})
```

Два вызова: слив `halted` и разряд камеры. Оба с обязательным перемешиванием — `HALT_MODE_LAW §4`, `TRUMP_ZONE_LAW §6`.

```text
модуль потока -> модуль деки. ВНИЗ. Цикла нет
```

## 8. События

```text
trump_flow_accepted    card_id, asker, reason
trump_flow_refused     card_id, reason     цели, ёмкость
trump_flow_handed_out  card_id
trump_flow_taken_back  card_id
trump_flow_closed      parked, flushed
trump_zone_released    cards
```

Существующие имена (`trump_flow_entry`, `trump_flow_displaced`, `halt_mode_begin`) сохраняются на время переезда: эталоны трасс стоят на них.

## 9. Вырожденные случаи

```text
accept козыря из целей       nil, "target_zone_trump". TARGET_ZONE_LAW §7
accept минора                nil, "not_a_trump". TRUMP_FLOW_LAW §3
hand_out при пустой queue    nil, не ошибка
hand_out при занятом current nil, "current_busy"
take_back не того козыря     nil, "not_current"
close при пустой цепи        ничего не паркует, событие не эмитится
close при halted без HALT    невозможно: halted заводится только режимом
разряд при ёмкости 0         вырожден: TIGEL снят, камера пуста -> прямо в деку
```

## 10. Проверки среза

```text
1.  accept кладёт в хвост        порядок queue сохраняется
2.  accept козыря из целей       отказ, "target_zone_trump"
3.  accept минора                отказ, "not_a_trump"
4.  accept раскрывает            в потоке нет не-revealed
5.  hand_out при незакрытой доске отказ. BOARD_CLOSURE_LAW §1
6.  hand_out даёт ГОЛОВУ         first caused, first resolved
7.  второй hand_out              отказ, "current_busy"
8.  take_back                    current пуст, козырь в in_flight,
                                 в камере ЕЩЁ НЕТ
9.  close паркует in_flight      в порядке разрешения
10. третий припаркованный        РАЗРЯД: камера пуста, карты в деке
11. HALT: сверх ёмкости          в halted, НЕ в queue
12. HALT: закрытие               halted в деку, сам HALT в камеру
13. TIGEL анкерится              обычный разряд его не вымывает
14. СТРУКТУРНАЯ: trump_flow.lua  ноль require на minor/trump машины
15. СТРУКТУРНАЯ: place_card
    в "trump_flow" вне модуля    ноль вхождений
16. СТРУКТУРНАЯ: place_card
    в "trump" вне модуля         ноль вхождений
```

Что ловит каждая:

```text
2       переопределение целевой зоны. Тихое нарушение: козырь-буква
        спецификации ушёл бы играть глаголом
6, 7    очередь против стека, и единственность current
8       resolve now, park later. Ловит преждевременную парковку,
        из-за которой HALT перестаёт видеть контур цепи
10      разряд как событие ЗАКРЫТИЯ, а не середины цепи
11, 12  режим HALT целиком. Двенадцатая — что сам HALT НЕ сливается
14-16   уровни. Пятнадцатая и шестнадцатая — то самое
        «ни один модуль не вызывает козырную машину, чтобы отдать
        ей козыря»: если кто-то кладёт в зону напрямую, вход обойдён
```

Проверки 1-13 поведенческие, расстановкой. 14-16 структурные и до конца миграции красные — это означает «переезд не завершён», а не дефект.

## 11. Ожидаемое расхождение эталона

```text
ожидается
```

Пять состояний вместо одной плоской зоны меняют то, что видно снаружи в момент цепи. Эталоны перезаписываются **после** приёмки, одной операцией вместе с декой и минорной машиной: `DECK_MODULE_SLICE §11`.

## 12. Порядок

```text
1. src/core/trump_flow.lua: пять состояний, accept, hand_out, take_back
2. close, камера, разряд, TIGEL
3. проверки §10, поведенческие
4. перевод козырной машины: enter_trump_flow -> accept
5. перевод минорной машины и добора на accept
6. УДАЛЕНИЕ enter_trump_flow и прямых place_card в trump_flow/trump
7. структурные 14-16 зеленеют здесь
```

Пункты 1-3 не трогают существующий код.

## 13. Open

```text
1. Признак runaway: бюджеты у козырной машины, а исчерпание
   обнаруживается при ВЫДАТЬ. TRUMP_FLOW_MODULE_LAW §10.1
2. Общий ли интерфейс у двух ёмкостей — HALT на очереди,
   TIGEL на камере. §10.3 закона
```

---

Автор закона: slasten, 2026-08-05.
Контракт: Opus 5 (claude-opus-5), 2026-08-05.

---

machines only. not for humans.
