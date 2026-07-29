# Win Module Slice

Статус:

```text
crystall contract
источник: ../table/WIN_MODULE_LAW.md
```

## 1. Несущее решение: судья без рук

Модуль не имеет доступа к мутаторам. Он не вызывает `state_lib` изменяющих функций, не вызывает `draw`, `repair`, `turn`, `trump`. Единственное, что он пишет, — `state.outcome`.

```text
доска    только чтение
исход    единственная запись
```

Это проверяется механически: в модуле не должно встречаться ни одного вызова из списка §11.3. Проверка дешёвая и она же и есть гарантия закона `§3`.

## 2. Модуль

```lua
-- src/core/win.lua
local M = {}

M.predicates            -- таблица предикатов по имени
M.check(state, name)    -- один предикат по имени. НЕ пишет
M.check_unsigned(state) -- все безподписные, первый сработавший. НЕ пишет
M.request(state, req)   -- ЕДИНСТВЕННЫЙ вход. Проверяет и, если сошлось, пишет
M.is_over(state)        -- state.outcome ~= nil

return M
```

**Один вход, два просителя.**

```lua
win.request(state, {signature = "TURN"})
win.request(state, {signature = "ENOUGH", basis = {revealed = 6, hand = 6}})
```

Шаг 9 минорной машины спрашивает «есть победа?». `ENOUGH` заявляет «я считаю, что победа». Форма обращения одна, отличается подпись.

Из единственности входа следует то, что иначе держалось бы на дисциплине:

```text
проверка is_over живёт в ОДНОМ месте
переписать уже записанный исход физически нечем
```

`check` отделён от `request` затем, чтобы предикат можно было прогнать в тесте, ничего не записывая.

Модуль **не эмитит события шага 9**: они принадлежат ходу, а не судье.

## 3. Поле исхода

```lua
state.outcome = {
    kind = "victory",
    by = "pattern" | "<подпись заявителя>",
    reading = "upper" | "lower" | nil,
    seq = <номер транзакции, в которой записан>,
}
```

Имя `outcome` — по соглашению остальных полей состояния (`committed`, `armed_hand`, `pending_trump`): нижний регистр, прямо на `state`, инициализируется в `state_lib.new_game` как `nil`.

## 4. Точка вызова, и почему её надо схлопнуть

Шаг 9 сейчас эмитится **в двух местах**:

```text
turn.lua:746    внутри close_turn
game.lua:449    внутри resolve_pending_trump
```

Оба места — одинаковый блок из двух событий. Это ровно та форма дублирования, которая сегодня уже дала дефект: `play_to_grave` эмитился в одиннадцати местах, `pending_operator_choice = nil` в двенадцати, и один путь оказался неинструментирован.

Поэтому оба места заменяются одним вызовом **turn-функции**, а не win-функции: шаг принадлежит ходу.

Сама функция специфицирована в `STEP_CHECK_SLICE_2026-07-29 §1`, чтобы не жить в двух кристаллах сразу. Модуль про шаги не знает.

Следствие, которое получается без отдельного правила: `ENOUGH §9` требует, чтобы победа обрывала остаток цепи. Очередь козырей сливается повторными действиями игрока через `apply_action`, а `apply_action` при записанном исходе отказывает (§7). Значит очередь останавливается сама.

`turn_closed` остаётся у вызывающего: он про ход, а не про проверку.

## 5. Предикат шаблона

`WIN_MODULE_LAW §5`.

```lua
-- трио -> шесть глифов
local function compiled_sequence(state)
    local seq = {}
    for slot = 1, 3 do
        local id = state.zones.targets.cards[slot]
        local card = id and state.cards[id]
        -- скрытая карта не компилирует: неизвестно, что она козырь.
        -- is_known истинно для known и для revealed, и target zone —
        -- единственная зона, где козырь может быть known: везде ещё
        -- раскрытый козырь уходит в trump flow.
        if not card
            or card.class ~= "trump"
            or not state_lib.is_known(state, id) then
            return nil
        end
        seq[#seq + 1] = card.op_a
        seq[#seq + 1] = card.op_b
    end
    return seq
end
```

```lua
-- ряд целиком: "op_a" или "op_b", смешивать нельзя
local function matches_row(state, seq, row)
    for slot = 1, 6 do
        local id = state.zones.manifest.cards[slot]
        local card = id and state.cards[id]
        if not card or card[row] ~= seq[slot] then
            return false
        end
    end
    return true
end
```

Предикат:

```text
seq = compiled_sequence(state)
если seq нет            -> не победа
matches_row(seq,"op_a") -> победа, reading = "upper"
matches_row(seq,"op_b") -> победа, reading = "lower"
иначе                   -> не победа
```

Верхнее проверяется первым; при совпадении обоих записывается `upper`. Совпадение обоих возможно и не является ошибкой.

## 6. Заявки

`WIN_MODULE_LAW §6`.

```lua
request = {
    signature = "ENOUGH",
    basis = {revealed = 6, hand = 6},
}
```

```lua
function M.request(state, req)
    if M.is_over(state) then
        return nil, "already_over"        -- победа наступает один раз
    end

    local outcome
    if req.signature == "TURN" then
        -- машина не заявляет, она спрашивает: прогнать ВСЕ безподписные.
        -- WIN_MODULE_LAW §4: список открыт, значит перебор, а не одно имя
        outcome = M.check_unsigned(state)
    else
        local predicate = M.predicates[req.signature]
        if not predicate then
            return nil, "unknown_claimant"
        end
        outcome = predicate(state)
        if not outcome then
            -- ДЕФЕКТ заявителя, а не отказ: он утверждал то, чего нет
            transition.emit(state, "win_claim_rejected", {
                signature = req.signature,
                basis = req.basis,
            })
            return nil, "claim_not_verified"
        end
    end

    if not outcome then
        return nil
    end
    -- безподписный предикат называет себя сам; заявитель — своей подписью
    outcome.by = outcome.by or req.signature
    state.outcome = outcome
    transition.emit(state, "game_won", {by = outcome.by, reading = outcome.reading})
    return outcome
end
```

**Форма у модуля, основание у козыря** реализуется так: `signature` выбирает предикат, а сам предикат живёт в `M.predicates`. Заявитель называет себя; считает модуль.

`basis` в заявке — не вход, а **самоописание заявителя**. Модуль его не использует для решения, только кладёт в событие расхождения, если предикат не подтвердился. Иначе заявитель мог бы задать себе ответ.

```lua
M.predicates.ENOUGH = function(state)
    -- ENOUGH: открытых на manifest+latent столько же, сколько карт в руке
    ...
    return equal and {kind = "victory", reading = nil} or nil
end
```

Повторяемость получается сама: `request` — обычный вызов, ограничение одно, `already_over`.

## 7. Терминальность

Одна вставка в начало `interaction.read`, сразу после `empty_interaction()`:

```lua
if state.outcome then
    ix.phase = "over"
    ix.prompt = "Game over: " .. state.outcome.by
    return ix
end
```

Дальше **ничего делать не надо**: `enumerate_legal_actions` разбирает `ix.phase` через цепочку сравнений, ни одно не совпадёт, а `empty_interaction()` ставит все `clears` в `false` и `advance.enabled` в `false`. Пустой список получается сам.

И одна вставка в `game.apply_action`:

```lua
if state.outcome then
    transition.begin(state, "apply_action", {kind = tostring(action and action.kind)})
    return transition.finish(state, {error = "game_over"})
end
```

Без неё вызывающий, не смотрящий на фазу, продолжит толкать действия.

## 8. Совместимость с ядром

```text
форма модуля     local M = {} ... return M, requires сверху
события          transition.emit(state, "snake_case", payload)
транзакции       модуль НЕ вызывает transition.begin/finish:
                 проверка не действие, она идёт внутри чужой транзакции.
                 Исключение — отказ в apply_action, там граница API
поле состояния   на state, нижний регистр, инициализация в new_game
ошибки           на границе API возвращать ТРАНЗАКЦИЮ, а не голую пару
                 nil, err. Сегодня turn.arm_operator вернул голую пару,
                 и вызывающий прочитал отказ как успех. Не повторять
зависимости      state, transition, constants. НЕ turn, НЕ trump,
                 НЕ draw, НЕ repair, НЕ view, НЕ interaction
                 state_lib — только читающие: is_known, is_revealed.
                 Мутаторы из него в чёрном списке §11.3
```

Последняя строка важна: `interaction` знает про `win` (терминальная фаза), а `win` про `interaction` не знает. Зависимость односторонняя.

## 9. Чего этот срез не делает

```text
GRANT             грантовые колонки и перебор шесть-из-N не реализуются.
                  GRANT отсутствует в constants.TRUMP_NAMES, то есть
                  такой карты в игре нет. Код под недостижимый случай
                  сегодня уже дважды оказывался мусором
поражение         вне модуля, WIN_MODULE_LAW §8
показ игроку      модуль пишет исход, показывает кто угодно снаружи
```

Когда GRANT появится, предикат шаблона получит второй режим, а `matches_row` — перебор подмножеств. Точка расширения одна и она известна.

## 10. Вырожденные случаи

```text
целевой слот пуст                  шаблона нет, не победа
в целевом слоте минор              шаблона нет, не победа
в целевом слоте СКРЫТЫЙ козырь     шаблона нет, не победа
в манифесте дыра                   не победа (card == nil -> false)
совпали оба ряда                   записывается upper, не ошибка
исход уже записан                  request возвращает already_over
                                   независимо от подписи
```

Третья строка была открытым пунктом и закрыта решением автора:

```text
скрытая карта козырем не считается
known — состояние, доступное козырю ТОЛЬКО в целевой зоне
```

Отсюда следует момент срабатывания, ради которого проверка и стоит на шаге 9: шаблон в манифесте может быть собран **раньше**, чем компилятор достроен. Два козыря открыты, третий ещё скрыт, победная комбинация уже стоит — и победа наступает в тот ход, когда третий становится открытым. Побеждает не последний ход, а последнее **раскрытие**.

## 11. Проверки среза

```text
1.  шаблон собран, верхний ряд совпал  -> victory, by=pattern, reading=upper
2.  шаблон собран, нижний ряд совпал   -> victory, reading=lower
3.  пять слотов из шести совпали       -> не победа
4.  смешанное чтение (три верхних,
    три нижних)                        -> НЕ победа
5.  в целевой зоне два козыря и минор  -> не победа
6.  ENOUGH заявляет при равенстве      -> victory, by=ENOUGH
7.  ENOUGH заявляет при неравенстве    -> claim_not_verified,
                                          исход НЕ записан
8.  повторная заявка после победы      -> already_over
8a. ENOUGH победил на шаге 8, шаг 9
    находит собранный шаблон           -> подпись остаётся ENOUGH
9.  после записи исхода
    enumerate_legal_actions            -> пустой список
10. после записи исхода apply_action   -> error = game_over
11. в модуле нет ни одного вызова
    из чёрного списка §11.3            -> read-only держится
12. шаг 9 эмитится ровно из ОДНОГО
    места в коде
13. в целевой зоне СКРЫТЫЙ козырь
    и собранный манифест            -> не победа
14. тот же слот раскрыт             -> победа В ТОТ ЖЕ ход
```

Пункт 4 — контрольный: он отличает реализованный закон от «шести совпадений где угодно».

Пункты 13 и 14 — вторая контрольная пара, на момент срабатывания. Тринадцатый без четырнадцатого означал бы, что проверка вообще не видит компилятор; четырнадцатый без тринадцатого — что она не смотрит на информационное состояние.

Чёрный список для пункта 11:

```text
state_lib.place_card, state_lib.remove_from_current_zone,
state_lib.set_info_state, state_lib.hide_card, state_lib.know_card,
state_lib.reveal_card, draw.*, repair.*, turn.*, trump.*
```

## 12. Порядок

```text
1. state.outcome в new_game, is_over
2. предикат шаблона (§5) и его проверки 1-5
3. request с подписью TURN, turn.step_check и схлопывание
   двух точек вызова в одну (§2, §4)
4. терминальная фаза и отказ apply_action (§7), проверки 9-10
5. предикат ENOUGH и заявка с подписью (§6), проверки 6-8
6. проверки 11-12
```

Шаги 1-3 дают работающее условие победы по шаблону. Шаг 5 добавляет второй способ и протокол под него.

---

Автор закона: slasten, 2026-07-29.
Контракт: Opus 5 (claude-opus-5).

---

machines only. not for humans.
