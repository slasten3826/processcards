# Turn Step Slice

Статус:

```text
crystall contract
источник: ../table/TURN_STEP_LAW.md, ../table/HALT_MODE_LAW.md
код на момент написания: не изменён
```

## 0. Что этот срез делает и чего НЕ делает

**Делает:** реализует закон о шагах на существующем протоколе взаимодействия.

**Не делает:** не переписывает управление ходом в настоящую пошаговую машину.

Порядок шагов в коде уже правильный — он задан последовательностью протокола `commit → arm → advance → operator → advance`. Не хватает трёх вещей: привязки оператора к шагу, отсрочки козырей и наблюдаемых границ шагов.

Настоящая пошаговая машина — отдельная миграция после того, как эта окажется зелёной. Смешивать их нельзя: тогда расхождение эталона станет нечитаемым и мы не поймём, что именно сломалось.

## 1. Дескриптор оператора

`src/core/operators.lua` сейчас почти пуст: реализован только `CONNECT`, остальное `operator_effect_stub`, плюс семь однострочников `finish_*`. Он становится реестром.

```lua
-- src/core/operators.lua
M.descriptors = {
    FLOW     = {step = "EFFECT"},
    CONNECT  = {step = "EFFECT"},
    DISSOLVE = {step = "BURN"},
    ENCODE   = {step = "EFFECT"},
    CHOOSE   = {step = "EFFECT"},
    OBSERVE  = {step = "EFFECT"},
    LOGIC    = {step = "LEGALITY"},
    CYCLE    = {step = "EFFECT"},
    RUNTIME  = {step = "EFFECT"},
    MANIFEST = {step = "EFFECT"},
}

function M.step_of(op_name)
    local d = M.descriptors[op_name]
    return d and d.step or "EFFECT"   -- закон: без объявления — EFFECT
end
```

Поле `step` — единственное, что добавляется на этом срезе. Реестр эффектов (`resolve`) переносится **позже**, отдельной миграцией.

## 2. Снятие defer_world_update

```text
turn.lua:625   local defer_world_update = choices_include(choices, "DISSOLVE")
turn.lua:675   if ... defer_world_update and op_name ~= "DISSOLVE" then
```

Заменяется на вопрос к реестру:

```lua
-- при фиксации: откладывать мир, если хоть один доступный оператор
-- связан с BURN
local defer_world_update = false
for _, op_name in ipairs(choices) do
    if operators.step_of(op_name) == "BURN" then
        defer_world_update = true
    end
end

-- при выборе оператора: если выбранный НЕ на BURN, догнать мир
if pending.turn_context.defer_world_update
   and op_name ~= nil
   and operators.step_of(op_name) ~= "BURN" then
    perform_ordinary_world_update(...)
end
```

Поведение не меняется, пока `DISSOLVE` — единственный оператор на `BURN`. Имя `defer_world_update` сохраняется: переименование пойдёт вместе с настоящей пошаговой машиной.

## 3. Отсрочка козырей

### 3.1. Единственный немедленный разряд

```text
src/core/draw.lua:33-45   resolve_revealed_draw
```

Сейчас после раскрытия козыря вызывает `refresh_pending_trump` и **сразу** `resolve_pending_trump`. Убирается: остаётся только вход в поток.

```lua
if state.cards[card_id].class == "trump" then
    trump.enter_trump_flow(state, card_id, reason)
    return nil, nil          -- очередь ждёт шага TRUMP
end
```

Это и есть главная правка среза. Она делает `CONNECT` атомарным: три тяга проходят целиком, и первый вскрытый козырь больше не ворошит деку до второго.

### 3.2. refresh_pending_trump

Двенадцать вызовов в `turn.lua` не разряжают очередь, они выставляют `state.pending_trump` для интерфейса. Под шагами `pending_trump` должен появляться только на шаге 8.

Все вызовы в `turn.lua` удаляются. Остаётся один — в момент перехода к шагу `TRUMP` (см. 4).

### 3.3. Вызовы внутри trump.lua

```text
trump.lua:368    внутри resolve_eject_effect
trump.lua:1127   внутри M.resolve_pending_trump
```

Оба уже находятся внутри разрядки шага 8. Не трогаются. Защита от рекурсии — существующий флаг `trump_flow_draining`.

## 4. Шаг TRUMP на существующем протоколе

Шаг 8 наступает после `SPEND`, то есть после `play_to_grave` в `start_operator_effect`.

```lua
-- в конце start_operator_effect, после play_to_grave:
transition.emit(state, "step_spend_end", {})
trump.refresh_pending_trump(state)
transition.emit(state, "step_trump_begin", {})
```

`await_trump` **сохраняется как фаза темпа**, а не выбора. Игрок продвигает разрядку по одному козырю, но ничего не выбирает. Автоматическая разрядка целого шторма нечитаема, а лишать игрока такта — терять наблюдаемость.

Когда очередь пуста:

```lua
transition.emit(state, "step_trump_end", {})
transition.emit(state, "step_check_begin", {})
-- терминальные условия не реализованы; шаг существует как граница
transition.emit(state, "step_check_end", {})
transition.emit(state, "turn_closed", {})
```

## 5. События границ

Без них проверить закон нечем.

```text
step_spend_end     после ухода сыгранной карты в grave
step_trump_begin   перед разрядкой очереди
step_trump_end     очередь пуста
step_check_begin   граница проверки
step_check_end
turn_closed        ход закрыт
```

Минимальный набор: границы нужны только там, где закон делает проверяемое утверждение. Размечать все девять шагов сейчас не нужно.

## 6. Что не трогается

```text
full_pair_fit, move_legal, logic_available      LOGIC_JOKER_LAW
joker_move и сужение набора операторов          LOGIC_JOKER_LAW
flow_ring_rotate                                FLOW-кольцо
порядок протокола commit/arm/advance            интерфейс
state.lua, interaction.lua                      структура фаз
trump.lua внутренняя механика                   кроме 3.3
HALT                                            отдельный срез
восемь целевых фаз                              отдельная миграция
```

`HALT_MODE_LAW` в этот срез **не входит**. Ёмкость очереди меняется после того, как отсрочка окажется зелёной.

## 7. Проверка

Новая, из закона:

```text
INVARIANT: в потоке событий одного хода ни одно козырное событие
           не стоит раньше step_spend_end
```

Реализуется как проход по трассе: найти индекс `step_spend_end`, убедиться, что все события с префиксом `trump_`, `pending_trump`, `trump_effect_` идут после него.

Существующие, все обязаны остаться зелёными:

```text
lua cli.lua check_logic       15 проверок, сиды 1..60
lua cli.lua audit_view        утечки 0, контроль течёт
lua cli.lua headless          не падает
lua cli.lua playtest          инвариантов 0
lua cli.lua baseline check    расхождение ожидается, см. 8
```

## 8. Ожидаемое расхождение эталона

Крупное и только в `full_*` прогонах. `minor_*` не должны измениться вообще — козырей там нет.

```text
minor_headless, minor_survival    ожидается ИДЕНТИЧНО
full_headless, full_survival      ожидается расхождение
```

Если `minor_*` разошлись — правка задела минорную машину, чего быть не должно. Это стоп-сигнал, а не повод перезаписать эталон.

Характер расхождения в `full_*`: козырные события уезжают из середины хода в хвост.

## 9. Риски

**Р1. Доска между UPDATE и TRUMP.** Козырь, вскрытый при подъёме латента, уходит в поток, а слот закрывается из деки прямо в `UPDATE` через `open_manifest_closure`. Доска остаётся замкнутой. Проверяется существующим счётчиком незамкнутости в плейтесте — должен остаться нулём.

**Р2. Клиенты интерфейса.** `await_trump` теперь появляется только после `SPEND`. `src/cli` и `src/manifest` этого не знают. LÖVE-клиент в этот срез не входит, но CLI обязан пережить `lua cli.lua play`.

**Р3. Более длинные цепи.** Всё копится и разряжается залпом, значит внутри одной разрядки вероятнее reset pulse и срабатывание guard-лимитов. `max_trump_chain_steps` может начать срабатывать там, где раньше не срабатывал. Если сработает — это находка, а не поломка: сообщать, а не поднимать лимит.

**Р4. Порядок внутри залпа.** Очередь FIFO, но раньше часть козырей разрешалась немедленно и потому вне очереди. После правки порядок разрешения изменится даже там, где состав тот же. Ожидаемо.

## 10. Порядок реализации

```text
1. operators.descriptors и step_of
2. defer_world_update через реестр            поведение не меняется
   -> baseline check: ожидается 20/20
3. draw.lua: убрать немедленный разряд
4. turn.lua: убрать 12 refresh_pending_trump
5. границы шагов и один refresh на шаге 8
   -> baseline check: minor_* идентично, full_* разошлось
6. инвариант «козыри после SPEND» в src/sim
7. полный набор проверок
8. перезапись эталона с объявлением расхождения
```

Шаг 2 отдельным коммитом и с зелёным эталоном: если он что-то меняет, значит реестр расходится с прежним условием, и это надо увидеть до отсрочки.

---

Автор закона: slasten, 2026-07-28.
Контракт: Opus 5 (claude-opus-5).

---

machines only. not for humans.
