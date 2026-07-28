# Cycle Advance Slice

Статус:

```text
crystall contract
источник: ../table/CYCLE_ADVANCE_LAW.md
код на момент написания: не изменён
```

## 1. Объём

`CYCLE` перестаёт быть оператором руки и становится вторым продвижением колонки. Механизм продвижения **уже существует** и переиспользуется целиком.

```text
добавляется   вызов существующего perform_ordinary_world_update
удаляется     ветка CYCLE в arm_operator, открывающая фазу сброса
              resolve_cycle_draw и finish_cycle в operators.lua
```

## 2. Что есть сейчас

```text
turn.lua  start_operator_effect, ветка op_name == "CYCLE"
          -> operators.resolve_cycle_draw(state)      тянет одну карту
          -> открывает pending_hand_choice            выбор сброса
          -> ход завершается в confirm_hand_target

operators.lua  resolve_cycle_draw, finish_cycle
```

## 3. Что должно стать

```lua
-- turn.lua, start_operator_effect
if op_name == "CYCLE" then
    -- CYCLE_ADVANCE_LAW: та же колонка продвигается второй раз,
    -- по своему НОВОМУ состоянию после обычного UPDATE шага 5.
    local slot = pending.turn_context and pending.turn_context.slot
    local current_manifest_id = slot and state.zones.manifest.cards[slot]
    transition.emit(state, "operator_effect_begin", {operator = op_name})
    if slot and current_manifest_id then
        transition.emit(state, "cycle_second_advance", {slot = slot})
        perform_ordinary_world_update(state, slot, current_manifest_id)
    else
        transition.emit(state, "cycle_advance_skipped", {
            slot = slot,
            reason = current_manifest_id and "no_slot" or "empty_manifest_slot",
        })
    end
    transition.emit(state, "operator_effect_end", {operator = op_name})
else
    ...
end
```

Ключевое: `current_manifest_id` читается **из текущего состояния**, а не из `turn_context.manifest_card_id`. В контексте лежит карта, которая ушла в могилу при первом продвижении.

## 4. Что удаляется

```text
turn.lua       ветка elseif op_name == "CYCLE" в arm_operator,
               создающая pending_hand_choice
operators.lua  resolve_cycle_draw
operators.lua  finish_cycle
```

Фаза `pending_hand_choice` **сама по себе не удаляется**: её использует ещё и `CHOOSE`. Проверить перед удалением ветки, что других потребителей у неё нет; если есть — удалять только ветку `CYCLE`.

## 5. Что не трогается

```text
perform_ordinary_world_update    переиспользуется как есть
repair.repair_manifest_slot      восхождение и закрытие слота
open_manifest_closure            встреча козыря при закрытии
привязка CYCLE к шагу EFFECT     не меняется
```

## 6. Вырожденные случаи

```text
слот пуст после первого продвижения   не должно случаться: закрытие
                                      заполняет его; на всякий случай
                                      эмитим cycle_advance_skipped
латент пуст                           repair_manifest_slot уже эмитит
                                      repair_skipped, отдельного
                                      обращения не нужно
дека пуста                            пополнение возвращает nil,
                                      слот остаётся пустым — то же
                                      поведение, что при обычном
                                      исчерпании
грантовая колонка                     латентный этаж доедается,
                                      колонка исчезает за один ход;
                                      закон это допускает
```

## 7. Проверки

```text
1. после CYCLE карта, стоявшая в манифесте ПОСЛЕ первого подъёма,
   находится в grave
2. в манифестном слоте стоит карта, поднявшаяся из латента вторым подъёмом
3. латентный слот пополнен и закрыт
4. дека уменьшилась на два пополнения (плюс закрытия, если были козыри)
5. рука изменилась ровно на -1, то есть только на каст
6. целевая фаза не открывается: в трассе нет hand_choice_pending
7. доска замкнута
8. латентный козырь при втором подъёме уходит в trump flow,
   а не разрешается на месте (инвариант шагов держится)
```

Пункт 5 — контрольный: он отличает новый `CYCLE` от старого, где рука уходила в −1 ещё и через сброс.

## 8. Ожидаемое расхождение эталона

```text
minor_* и full_*   ожидается расхождение
```

Исчезают `draw_to_hand` и `hand_to_grave` от `CYCLE`, появляются `cycle_second_advance` и вторая серия `manifest_to_grave` / `latent_to_manifest` / `concealed_refill`.

Отсутствие расхождения означало бы, что матрица не доходит до `CYCLE` — ложная зелень, а не успех.

## 9. Порядок

```text
1. заменить ветку CYCLE в start_operator_effect
2. убрать ветку CYCLE из arm_operator
3. убрать resolve_cycle_draw и finish_cycle
4. проверки раздела 7
5. полный набор: check_logic, check_steps, audit_view, headless, playtest
6. перезапись эталона с объявлением расхождения
```

---

Автор закона: slasten, 2026-07-28.
Контракт: Opus 5 (claude-opus-5).

---

machines only. not for humans.
