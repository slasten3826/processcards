# Hand-First Step 2: Protocol Clients 2026-05-07

## Goal

Вернуть protocol-driven consumers в синхрон с новым hand-first core.

Status:

- completed

---

## Scope

Нужно починить:

- [src/sim/runner.lua](/home/slasten/dev/processcards/src/sim/runner.lua)
- [cli.lua](/home/slasten/dev/processcards/cli.lua)

Это включает:

- `headless`
- `autoplay`
- protocol auto loops

---

## What must change

Старые фазы:

- `await_commit`
- `await_hand`

должны быть заменены или честно мигрированы на:

- `await_start`
- `await_complete`
- `await_ready`

Без постоянного dual-law branch.

---

## Why this step exists

Пока protocol clients живут по старым фазам,
ветка не считается рабочей,
даже если core уже стал новым.

---

## Exit criteria

1. `lua cli.lua headless 7 24` не падает на `unknown_phase_await_start`
2. `lua cli.lua autoplay 7 16` не падает на `unknown_phase_await_start`
3. protocol client decisions читаются только из `interaction(state)`

Current result:

- all three conditions are satisfied

Verified by:

- `lua cli.lua autoplay 7 16`
- `lua cli.lua headless 7 24`
- `lua cli.lua bench autoplay 40 1`
- `lua cli.lua bench headless 40 1`
- `lua cli.lua bench smoke 80 1`
