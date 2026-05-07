# Hand-First Step 3: Phase Safety 2026-05-07

## Goal

Закрыть runtime hole вокруг `arm_hand`
и любых других cross-phase selection mutations.

Status:

- completed

---

## Core problem

Сейчас possible:

- hand selection mutates outside semantically correct phase;
- client can silently drift from current phase truth;
- operator/target phases may carry stale or illegal hand state.

---

## Target rule

Нужно добиться такого закона:

```text
armed state may mutate only in phases
where interaction explicitly marks that surface legal
```

То есть:

- не client intuition;
- не “ну вроде harmless”;
- а строгая phase legality.

---

## Preferred variant

Предпочтительный вариант:

### Strict interaction gate

Core/action layer запрещает illegal hand-arm
в неподходящих фазах.

Это лучше, чем:

### Core-permissive, client-strict

потому что клиент не должен быть последней линией обороны
против логически нелегальной мутации state.

---

## Exit criteria

1. `armed_hand` не мутирует в `await_operator` и аналогичных фазах
2. phase truth и armed truth не расходятся
3. CLI/TUI and future LOVE can trust core legality

Current result:

- all three conditions are satisfied for the current repair scope

Verified by:

- `lua cli.lua scenario arm_hand_blocked_in_operator_phase 7`
- `lua cli.lua scenario clear_actions_blocked_in_start 7`
- `lua cli.lua bench arm_hand_blocked_in_operator_phase 40 1`
- `lua cli.lua bench clear_actions_blocked_in_start 40 1`
