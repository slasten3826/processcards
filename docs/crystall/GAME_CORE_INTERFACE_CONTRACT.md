# Game Core Interface Contract

Статус:

```text
canonical crystall core contract
```

Этот документ фиксирует,
какой интерфейс должен стать
общим источником истины
для CLI и LOVE2D.

## 1. Core rule

Оба runtime consumer-а:

- CLI
- LOVE2D

должны говорить
с одним и тем же game core.

## 2. Required core surface

Минимально game core должен давать:

1. `new`
2. `start_game`
3. `snapshot`
4. `last_transition`
5. `drain_events`

## 3. Transition law

Логика не должна существовать
только как “сразу мутированный state”.

Core должен также уметь сообщать:

```text
what happened during the last transition
```

То есть:

- transition kind
- transition payload
- event stream
- final summary

## 4. Why events matter

CLI использует это для:

- test scenarios
- assertions
- bug inspection

LOVE2D использует это для:

- animation plans
- event stepping
- zone updates
- readable manifestation

## 5. Short formula

```text
The core must return both state and transition meaning.
CLI inspects it.
LOVE animates it.
```
