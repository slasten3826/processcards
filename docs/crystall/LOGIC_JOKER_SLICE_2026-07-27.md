# Logic Joker Slice

Статус:

```text
crystall contract
источник: ../table/LOGIC_JOKER_LAW.md
scope: минорная машина, trump-free
код на момент написания: не изменён
```

Этот документ переводит `LOGIC_JOKER_LAW` в исполнимую форму: где именно в ходе стоит крючок, что меняется в состоянии, какие события эмитятся и что обязано остаться нетронутым.

## 1. Точка вмешательства

Джокер живёт в **проверке легальности**, а не в разрешении оператора.

Текущие места, где считается легальность:

```text
src/core/rules.lua  full_pair_fit(manifest_card, hand_card)
src/core/rules.lua  legal_hand_ids(state, manifest_card_id)
src/core/rules.lua  legal_manifest_slots_for_hand(state, hand_card_id)
```

`full_pair_fit` остаётся **чистой топологической функцией** и не меняется. Джокер добавляется слоем выше, потому что он зависит от состояния игры (`runtime`), а не только от пары карт.

## 2. Доступность

```text
logic_available(state, hand_card_id) =
    hand_card несёт ☶
    OR
    ☶ входит в runtime_granted_operators(state)
```

`runtime_granted_operators` уже существует в `turn.lua` и возвращает операторы, выданные установленной runtime-картой.

## 3. Легальность хода

```text
move_legal(state, manifest_card, hand_card) =
    full_pair_fit(manifest_card, hand_card)
    OR
    logic_available(state, hand_card)
```

Следствия для двух функций легальности:

```text
legal_hand_ids                 при logic_available для карты — карта легальна
                               к ЛЮБОЙ committed manifest-карте
legal_manifest_slots_for_hand  при logic_available — легальны ВСЕ занятые слоты
```

## 4. Различение обычного и джокерного хода

Ключевая величина, вычисляемая в момент фиксации:

```text
joker_move = NOT full_pair_fit(manifest_card, hand_card)
```

То есть джокерным считается ход, который **не прошёл бы** обычную проверку. Если топология сошлась сама, ход обычный, даже если карта несёт `☶`.

Это значение сохраняется в `turn_context` рядом с существующим `defer_world_update`:

```text
state.pending_operator_choice.turn_context.joker_move = true | false
```

## 5. Ограничение выбора оператора

```text
если turn_context.joker_move истинно:
    operator_choices_for_card возвращает ровно {"LOGIC"}
иначе:
    прежнее поведение без изменений
```

Правило самоисполняющееся: платить джокером заставляет не отдельная проверка, а отсутствие альтернатив.

Отсюда же следует, что `runtime`-выданный `☶` не создаёт лазейки: если fit не сошёлся, единственный доступный оператор всё равно `☶`, значит эффект хода потерян.

## 6. Разрешение ☶

```text
☶ LOGIC не производит эффекта.

start_operator_effect(state, "LOGIC"):
    emit operator_effect_begin  {operator = "LOGIC", joker = joker_move}
    emit logic_joker_pass       {card_id, manifest_card_id}   если joker_move
    emit operator_effect_end    {operator = "LOGIC"}
    далее обычный путь: play -> grave, очистка выбора, refresh trump
```

`☶` не открывает целевую фазу. `operator_opens_target_phase` теряет `"LOGIC"`.

Выбор `☶` при обычном ходе (fit сошёлся сам) остаётся легальным и не производит ничего. Бесполезный ход не запрещается — стимул отбирает сам, как и у слепого `☵`.

## 7. Что обязано остаться нетронутым

```text
full_pair_fit                топология не меняется
DISSOLVE defer_world_update  единственное исключение по времени сохраняется
порядок хода                 мировое обновление по-прежнему до фазы оператора
grave                        LOGIC его больше не целит, но закон могилы не меняется
trump flow                   поведение не меняется
```

Отдельно: `☶` **теряет grave**. Прежний обмен мог целить `grave` как публичную зону; джокер не целит ничего. Соответствующие ветки `arm_public_target` / `confirm_public_target` для LOGIC становятся недостижимыми и удаляются вместе с общей машиной фаз, а не сейчас.

## 8. Ожидаемое расхождение эталона

```text
исчезают     pair_card_choice_pending, pair_card_target_armed,
             и события обмена LOGIC
появляются   logic_joker_pass на ходах, которые раньше были нелегальны
меняется     число доступных ходов: при карте с ☶ в руке
             легальны все занятые манифест-слоты
```

Расхождение будет большим и это ожидаемо: закон меняет множество легальных ходов, а не только один эффект.

## 9. Проверки среза

```text
1. карта с ☶, fit не сходится   -> ход легален, оператор ровно один: LOGIC
2. карта с ☶, fit сходится      -> оператор на выбор, LOGIC даёт пустой ход
3. карта без ☶, fit не сходится -> ход нелегален, как раньше
4. ☶☶ в руке                     -> легальна к любому слоту, выбора нет
5. ☶ в runtime, карта без ☶     -> ход легален к любому слоту,
                                    оператор ровно один: LOGIC
6. после джокерного хода         -> committed в grave, латент поднялся,
                                    слот пополнен, сыгранная карта в grave
7. инварианты                    -> board closed после каждого хода
```

## 10. Известные взаимодействия

**`MAXIMIZE`** кастует из руки в манифест подряд, пока топология разрешает **и пока игрок хочет**. Обе остановки — по условию, поэтому козырь можно не играть вовсе, а желаннее всего он при полной руке.

Под джокером первое условие перестаёт останавливать: с `☶` в `runtime` топология разрешает всегда. Тогда `MAXIMIZE` ограничен только волей игрока и размером руки. Это не блокер минорного среза — `MAXIMIZE` не закодирован, — но при его реализации ограничение придётся задать явно.

**Круг 8 Nine Circle Run** был искажением прежнего обмена LOGIC. Искажать больше нечего, круг помечается как legacy до переписывания.

## 10.1. ТЗ по функциям

Ниже — точные изменения. Всё, что не перечислено, не трогается.

### `src/core/rules.lua`

```lua
-- НОВОЕ. Зависит от состояния, поэтому живёт отдельно от full_pair_fit.
function M.logic_available(state, hand_card_id)
    -- true, если карта руки несёт "LOGIC"
    -- ИЛИ "LOGIC" входит в операторы, выданные runtime-картой
    -- источник runtime-операторов: turn.runtime_granted_operators(state)
end

-- НОВОЕ. Единственная точка, где решается легальность хода.
function M.move_legal(state, manifest_card, hand_card, hand_card_id)
    return M.full_pair_fit(manifest_card, hand_card)
        or M.logic_available(state, hand_card_id)
end

-- БЕЗ ИЗМЕНЕНИЙ
function M.full_pair_fit(manifest_card, hand_card)

-- ИЗМЕНЯЮТСЯ: обе используют move_legal вместо full_pair_fit
function M.legal_hand_ids(state, manifest_card_id)
function M.legal_manifest_slots_for_hand(state, hand_card_id)
```

Циклическая зависимость: `rules` не должен требовать `turn`. Функция
`runtime_granted_operators` переносится из `turn.lua` в `rules.lua`
либо дублируется там как локальная. Перенос предпочтительнее.

### `src/core/turn.lua`

```lua
-- M.arm_operator, в месте формирования pending_operator_choice:
--   вычислить и сохранить
turn_context.joker_move = not rules.full_pair_fit(manifest_card, hand_card)

-- operator_choices_for_card(state, card_id)
--   получает третий аргумент joker_move
--   если joker_move истинно -> вернуть ровно {"LOGIC"}
--   иначе -> прежнее поведение, включая дедупликацию дубля
--            и операторы, выданные runtime

-- operator_opens_target_phase(op_name)
--   убрать "LOGIC" из списка

-- start_operator_effect(state, op_name)
--   ветка op_name == "LOGIC":
--     emit operator_effect_begin {operator="LOGIC", joker=joker_move}
--     если joker_move: emit logic_joker_pass {card_id, manifest_card_id}
--     emit operator_effect_end {operator="LOGIC"}
--     дальше общий путь: move_to_grave, play_to_grave,
--     clear_gameplay_selection, refresh_pending_trump
--   НЕ вызывать operators.resolve для LOGIC
```

### Не трогается

```lua
full_pair_fit                    топология
defer_world_update и DISSOLVE    единственное исключение по времени
порядок хода                     мировое обновление до фазы оператора
state.lua, interaction.lua       структура фаз
trump.lua                        целиком
arm_public_target / confirm_public_target
                                 становятся недостижимы для LOGIC,
                                 но удаляются вместе с машиной фаз
```

### Замер, выполняемый заодно

```text
доля ходов, где при непустой руке нет ни одной легальной пары
(считается по full_pair_fit, без учёта джокера)
```

Это число определяет, несёт ли `☶` реальную нагрузку. Считать до и
после изменения — оно не должно измениться, потому что джокер не меняет
топологию.

## 11. Порядок реализации

```text
1. logic_available + move_legal в rules.lua, обе функции легальности
2. joker_move в turn_context при фиксации
3. сужение operator_choices_for_card при joker_move
4. пустое разрешение LOGIC, снятие LOGIC из operator_opens_target_phase
5. проверки раздела 9
6. перезапись эталона с явным объявлением расхождения
7. плейтест trump-free
```

---

Автор закона: slasten, 2026-07-27.
Контракт: Opus 5 (claude-opus-5).

---

machines only. not for humans.
