# Hand-First Step 1: Interaction Surface 2026-05-07

## Goal

Сделать `interaction(state)` полностью достаточным
для hand-first minor machine.

После этого:

- клиент не должен гадать;
- prompt не должен врать;
- legal surfaces должны быть machine-readable.

Status:

- completed

---

## What must be true

### `await_start`

Должен отдавать:

- `legal.commit_slots`
- `legal.hand_cards`
- exact prompt
- `advance.enabled = false`

Если рука может быть первой поверхностью выбора,
это должно быть выражено не только текстом, но и данными.

### `await_complete`

Должен отдавать:

- current `armed.hand_card_id` if any
- current committed slot if any
- legal remaining complementary surfaces
- clear legality if current model permits it

Нужно честно различать хотя бы такие под-состояния:

1. armed hand only
2. committed manifest only
3. both selected but not yet promoted to ready

Если `await_complete` фактически скрывает несколько семантически разных состояний,
это должно быть видно через `legal` и `armed`, а не оставаться на стороне клиента.

### `await_ready`

Должен означать одно:

```text
selection complete
advance casts
```

Не должно быть ambiguity.

---

## Deliverable

После Step 1 должно быть возможно написать headless client,
который использует только:

- `interaction(state)`
- `apply_action(state, action)`
- `advance(state)`

и не знает про внутренние костыли hand-first ветки.

Implemented in:

- [src/core/interaction.lua](/home/slasten/dev/processcards/src/core/interaction.lua)

Verified by:

- `lua cli.lua scenario interaction_start_surface 7`
- `lua cli.lua scenario interaction_complete_from_commit 7`
- `lua cli.lua scenario interaction_complete_from_hand 7`
- `lua cli.lua scenario interaction_ready_surface 7`
- `lua cli.lua bench interaction_start_surface 40 1`
- `lua cli.lua bench interaction_complete_from_commit 40 1`
- `lua cli.lua bench interaction_complete_from_hand 40 1`
- `lua cli.lua bench interaction_ready_surface 40 1`

---

## Exit criteria

1. `await_start` публикует и `commit_slots`, и `hand_cards`
2. `await_complete` не требует UI guesses
3. `await_ready` однозначен
4. prompts совпадают с legal data

Current result:

- all four conditions are satisfied in the current core branch
