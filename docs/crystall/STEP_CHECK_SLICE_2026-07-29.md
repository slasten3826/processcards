# Step Check Slice

Статус:

```text
crystall contract
источник: ../table/STEP_CHECK_LAW.md
```

## 1. Функция

```lua
-- turn.lua
local function step_check(state)
    transition.emit(state, "step_check_begin", {})
    local outcome = win.request(state, {signature = "TURN"})
    transition.emit(state, "step_check_end", {
        outcome = outcome and outcome.by or nil,
    })
end
```

Локальная в `turn.lua`, потому что это шаг хода. Экспортируется как `M.step_check`, чтобы её мог вызвать `game.lua`.

## 2. Две точки вызова схлопываются

```text
было
  turn.lua   close_turn:            emit begin; emit end
  game.lua   resolve_pending_trump: emit begin; emit end

стало
  turn.lua   close_turn:            step_check(state)
  game.lua   resolve_pending_trump: turn.step_check(state)
```

`turn_closed` остаётся у вызывающего: он про ход, а не про проверку.

## 3. Зависимость

```text
turn -> win
```

Односторонняя. `win` про `turn` не знает и знать не должен: у него в чёрном списке зависимостей `turn` стоит явно (`WIN_MODULE_SLICE §8`).

## 4. Что не меняется

```text
порядок событий           begin, затем end — как было
имена событий             step_check_begin / step_check_end
момент вызова             там же, где эмитились границы
turn_closed               остаётся у вызывающего
```

Единственное изменение в потоке событий — появление `game_won` между границами, и только когда победа наступила.

## 5. Вырожденные случаи

```text
победы нет            outcome = nil, end несёт outcome = nil,
                      поток событий как раньше
исход уже записан     win.request вернёт already_over, шаг отработает
                      вхолостую. Достижимо, если победа записана
                      заявкой на шаге 8
```

## 6. Проверки среза

```text
1. step_check_begin эмитится ровно из одного места в коде
2. при отсутствии победы поток событий совпадает с эталоном
3. при победе между границами появляется game_won
4. победа, записанная заявкой на шаге 8, не переписывается
   девятым шагом
```

Пункт 2 — контрольный: он ловит случай, когда шаг начал менять поток там, где ничего не произошло.

## 7. Ожидаемое расхождение эталона

```text
не ожидается
```

Пока победа недостижима в прогонах, поток событий не меняется. Если эталоны разойдутся — значит шаг делает что-то помимо обращения, и это дефект, а не ожидаемое следствие.

## 8. Порядок

```text
1. step_check в turn.lua, экспорт
2. замена двух блоков на вызовы
3. проверки раздела 6
```

---

Автор закона: slasten, 2026-07-29.
Контракт: Opus 5 (claude-opus-5).

---

machines only. not for humans.
