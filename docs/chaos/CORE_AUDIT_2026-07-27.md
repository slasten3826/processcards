# Аудит ядра и предложение модульной системы

Статус:

```text
слой: chaos
дата: 2026-07-27
объём: только src/core и src/sim, LOVE-клиент не трогался
вид: аудит по чтению всего ядра + предложение структуры
авторитет: не контракт
код изменён: нет
базис: тег playable-2026-07-26
```

Объём ядра:

```text
turn.lua        1739
trump.lua       1135
game.lua         601
interaction.lua  472
view.lua         354   (добавлен вчера)
state.lua        223
setup.lua        133
operators.lua     89
inspect.lua       82
draw.lua          81
transition.lua    75
cards.lua         70
repair.lua        65
rules.lua         61
constants.lua     61
api.lua            1
итого           5242
```

Сначала то, что хорошо, потому что это определяет стратегию починки.

## 0. Что в ядре здорово

**Граф зависимостей ацикличен.**

```text
constants  state  transition          листья
cards -> constants
rules -> constants
trump -> constants state transition
draw  -> state transition trump
repair-> state draw trump transition
turn  -> state rules draw repair trump transition operators
game  -> state setup inspect interaction transition turn draw trump rules
```

Ни одного цикла. Состояние — инертные данные, функции над ним чистые по форме,
`transition` даёт поток событий, `sim/rng` даёт детерминизм от сида. Это
означает, что ядро **можно рефакторить механически и проверять сравнением
трасс**, а не молиться. Ниже это и предлагается.

---

## S1. Две разошедшиеся реализации `repair_manifest_slot`

Самая тяжёлая находка.

```text
src/core/repair.lua:8    M.repair_manifest_slot
src/core/trump.lua:142   local repair_manifest_slot
```

Это одна и та же операция доски, и они **ведут себя по-разному**:

```text
                        repair.lua              trump.lua
проверка runaway        нет                     есть, выходит молча
refill                  draw.concealed_refill   локальный, с guard_repair
козырь из латента       trump.enter_trump_flow  handle_revealed_trump(..,"queue")
reason в событии        "latent ascent"         "eject_repair"
закрытие манифеста      draw.open_manifest_closure  локальный цикл
```

То есть **результат починки колонки зависит от того, каким путём в неё пришли** —
обычным ходом или через козырь. Подозреваю, что твои же `ANOMALY_75_2026-05-22`
и `TRUMP_FLOW_RUNAWAY_2026-06-06` — симптомы отсюда.

Причина структурная, и она важна: `draw -> trump`, поэтому `trump` не может
потребовать `draw` и `repair` без цикла. **Ацикличность графа куплена
копипастой.** Дублируются три вещи: `pop_topdeck`, `concealed_refill`,
`repair_manifest_slot`.

## S2. Десять козырей из двадцати двух — молчаливые пустышки

Диспетчер в `trump.lua:926` — цепь `if name == ... elseif ...` без `else`.

Незакодированные индексы: `4 5 6 7 9 10 11 12 13 18` — это `CANON`, `GATE`,
`GRANT`, `MAXIMIZE`, `REQUIEM`, `SWAP`, `TIGEL`, `UNBOUND`, `WARRANT` и второе
ребро `LOGIC–RUNTIME`.

У них `trump_name` = nil, ни одна ветка не совпадает, карта эмитит
`trump_effect_begin` / `trump_effect_end` и уезжает в trump-зону, **не сделав
ничего и не сообщив об этом**. При этом `cards.append_trump_deck` по умолчанию
раздаёт все 22.

Это не «ещё не сделано». Это «сделано как тишина», что хуже: ни ошибки, ни
диагностики, и на замерах такой козырь выглядит как рабочий.

## S3. `REPEAT` содержит вторую копию диспетчера

Внутри ветки `REPEAT` лежит ещё одна цепь по `parent_name`. И тела `FOOL` и
`RUSH` там **скопированы посимвольно**, а не вызваны. Остальные ветки зовут
общие функции.

Следствия: правку в `FOOL` нужно вносить дважды; `HALT` как родитель молча
игнорируется; расхождение двух копий — вопрос времени.

## S4. Восемь целевых фаз — восемь копий одной машины

```text
различных pending_*_choice:  9
ссылок на них:               306 в 7 файлах
  turn 135  scenarios 81  interaction 32  inspect 29  game 17  state 10  runner 2

семейство arm_/confirm_/choose_ в turn.lua: 1110 строк из 1739  (64%)
```

`arm_hidden_target` и `arm_public_target` совпадают дословно, кроме слова
`hidden` / `public`. То же для `flow`, `encode`, `unrevealed`, `manifest`,
`hand`, `pair_card`.

Цена: добавление девятой фазы требует правки минимум в пяти местах —
`state.lua`, `turn.lua`, две ветки в `game.lua`, `interaction.lua`,
`inspect.lua`. Именно это делает новую механику дорогой, а не сама механика.

## S5. `operators.lua` не реализует операторы

```lua
function M.resolve(state, op_name)
    if op_name == "CONNECT" then resolve_connect(state) return end
    transition.emit(state, "operator_effect_stub", {operator = op_name})
end
```

Реализован только `CONNECT`; всё остальное — заглушка. Настоящая логика девяти
операторов живёт в `turn.lua`. Плюс семь почти одинаковых однострочников
`finish_cycle / finish_observe / finish_dissolve / finish_encode / finish_flow /
finish_logic / finish_runtime`.

Модуль с таким именем должен быть местом, где операторы определены. Сейчас имя
врёт, а это в твоём стеке дороже, чем плохой код.

## S6. Четыре копии «есть ли значение в списке»

```text
game.lua:13   list_contains
turn.lua:122  operator_choice_is_legal
turn.lua:131  choices_include        -- чистый алиас предыдущей, мёртвый код
turn.lua:135  card_choice_is_legal
turn.lua:144  slot_choice_is_legal
```

## S7. `count_hidden_trumps` продублирован

`game.lua:38` и `sim/runner.lua:183`. Обе копии читают `info_state == "hidden"`
и обе кормят скоринг — это та утечка, которая закрыта вчера в `view.lua`, но в
самом ядре ещё живёт.

## S8. Три разных соглашения об ошибке

```text
turn.lua    return nil, "illegal_hand_card"      строка
game.lua    transition.finish{error = "..."}     в сводке транзакции
draw.lua    return nil, nil                      успех, выраженный как отсутствие
```

Таксономии ошибок нет: нельзя отличить «ход нелегален» от «состояние сломано».

---

## Предложение: модульная система

Не ООП. Реестры и один общий слой эффектов — по образцу
`runtime/operator_registry.lua` из proc-17.

```text
src/core/
  kernel/       state, zones, cards, info-state, transition
                (никаких правил игры)
  rules/        fit, легальность
  effects/      ОДНА реализация каждой операции доски:
                draw, concealed_refill, repair_slot, move_to_grave,
                open_manifest_closure
  operators/    registry.lua + по файлу на оператор
  trumps/       registry.lua + по файлу на козырь
  phases/       ОДНА общая машина целевых фаз + 8 дескрипторов
  api.lua       фасад
```

**Что чинится структурно:**

`effects/` зависит только от `kernel/`, а `operators/`, `trumps/` и `phases/`
зависят от `effects/`. Цикл `draw ↔ trump` исчезает не обходом, а тем, что обе
стороны зовут одну реализацию. **S1 растворяется**, а не заклеивается.

**Реестр козырей** — по дескриптору на карту:

```lua
trumps.FOOL = {
    index = 1,
    edge = {"FLOW", "CONNECT"},
    arcana = "0 Fool",
    flavor = "The road begins before the reason.",
    status = "implemented",
    resolve = function(state, ctx) ... end,
}

trumps.TIGEL = {
    index = 9, edge = {"DISSOLVE", "OBSERVE"}, arcana = "IX Hermit",
    flavor = "What is empty is doubled.",
    status = "declared",
    resolve = nil,
}
```

- **S2**: `status = "declared"` плюс типизированное событие
  `trump_not_implemented` вместо тишины. Незакодированный козырь становится
  видимым фактом, а не пустотой.
- **S3**: `REPEAT` превращается в `registry[parent].resolve(state, ctx)` — одна
  строка вместо второй копии диспетчера.
- Дескриптор заодно становится единственным местом, где живут ребро, аркан и
  флавор — сейчас они только в документах.

**Общая машина фаз** — по дескриптору на фазу:

```lua
phases.hidden = {
    field = "pending_hidden_choice",
    legal = function(state) ... end,
    on_confirm = function(state, card_id) ... end,
    event_prefix = "hidden",
}
```

Общие `arm(state, phase, ref)`, `confirm(state, phase)`, `clear_all(state)`.
Восемь дескрипторов вместо 24 функций и ~1110 строк. `interaction.lua`,
`game.lua` и `inspect.lua` начинают перебирать реестр вместо восьми жёстких
веток — **S4 закрывается во всех пяти местах сразу**.

**Реестр операторов** закрывает S5 и становится посадочным местом для пяти
ревизий из `../table/OPERATOR_REVISION_PROPOSAL_2026-07-26.md`.

---

## Как рефакторить без тестового пакета

Тестов у проекта нет, но есть детерминизм и поток событий. Значит есть
эквивалентностная проверка:

```text
1. до рефактора: записать трассу событий на N сидах
   (headless + autoplay + survival, фиксированные сиды)
2. после каждого шага рефактора: проиграть те же сиды
3. требование: поток событий идентичен
4. исключения объявлять явно — их должно быть ровно столько,
   сколько намеренных изменений поведения
```

Плюс уже существующие сторожа: `sim/invariants.lua` после каждого шага и
`sim/observation_audit.lua` на утечки.

Порядок, от безопасного к рискованному:

```text
1. effects/ и снятие дубля repair_manifest_slot   лечит S1, поведение фиксируем трассой
2. реестр козырей, 12 существующих без изменений   лечит S2 S3
3. общая машина фаз                                лечит S4
4. реестр операторов                               лечит S5
5. мелочи: S6 S7 S8
6. только после этого — пять ревизий и 10 козырей
```

Шаг 1 обязан идти первым: пока `repair_manifest_slot` существует в двух
версиях, любая трасса-эталон записана поверх неопределённости.

---

## Открытые вопросы

```text
1. Расхождение двух repair — это баг или намеренная разная политика
   для козырного пути? От ответа зависит, какую версию делать канонической.
2. Что должен делать незакодированный козырь до реализации:
   уходить в trump-зону как сейчас, или не попадать в колоду вообще.
3. Нужна ли таксономия ошибок сейчас или после ревизий.
4. Переносить ли ребро/аркан/флавор в дескриптор, или оставить
   единственным источником документы table/trumps/*.md.
```

---

## Авторство

```text
Opus 5 (claude-opus-5), 2026-07-27
    полное чтение src/core, находки S1-S8, предложение структуры,
    протокол эквивалентностной проверки
```

---

machines only. not for humans.
