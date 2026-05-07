# DeepSeek Hand-First Repair 2026-05-07

## Status

Этот документ фиксирует текущее состояние после внеплановой hand-first ветки и CLI/TUI ветки, которые были внесены в проект во время лимитного разрыва.

Корневой program document теперь:

- [MINOR_HEADLESS_CORE_PROGRAM_2026-05-07.md](./MINOR_HEADLESS_CORE_PROGRAM_2026-05-07.md)

Речь не про откат.

Current repair status:

- Step 1 completed
- Step 2 completed
- Step 3 completed

Речь про:

1. сохранить сильные части новой ветки;
2. локализовать реальные поломки;
3. вернуть `table -> crystall -> manifest` в честное состояние;
4. не позволить `LOVE` снова лечить дырки ядра локальной магией.

---

## Что реально было изменено

### 1. Entry flow игры был пересобран

Старый hand/commit shell больше не основной.

Вместо старой формы:

```text
await_commit
-> await_hand
-> advance
```

в ядре появилась новая:

```text
await_start
-> await_complete
-> await_ready
```

Смысл новой формы:

- игрок может начинать не только с `manifest` slot;
- рука стала реальной первой поверхностью выбора;
- `advance()` теперь подтверждает не old hand-phase, а состояние полной готовности пары:
  - committed manifest
  - armed hand

Файлы:

- [src/core/interaction.lua](/home/slasten/dev/processcards/src/core/interaction.lua)
- [src/core/game.lua](/home/slasten/dev/processcards/src/core/game.lua)
- [src/core/turn.lua](/home/slasten/dev/processcards/src/core/turn.lua)

### 2. В core добавлены explicit clear-actions

Теперь в action surface существуют:

- `clear_selection`
- `clear_committed`
- `clear_armed`

Это уже не случайный UI reset, а часть machine surface.

Файл:

- [src/core/game.lua](/home/slasten/dev/processcards/src/core/game.lua)

### 3. Появился отдельный CLI/TUI клиент

Это большое и в целом правильное изменение.

Теперь кроме bench/headless harness есть ещё и карточная ANSI-манифестация:

- [src/cli/main.lua](/home/slasten/dev/processcards/src/cli/main.lua)
- [src/cli/render.lua](/home/slasten/dev/processcards/src/cli/render.lua)
- [src/cli/input.lua](/home/slasten/dev/processcards/src/cli/input.lua)
- [src/cli/glyphs.lua](/home/slasten/dev/processcards/src/cli/glyphs.lua)

Это важный шаг, потому что `crystall` должен быть не только simulation shell, но и playable non-GUI manifestation.

### 4. Локально сверху лежит маленький bootstrap-fix

Незакоммиченная правка на текущий момент:

- [src/cli/main.lua](/home/slasten/dev/processcards/src/cli/main.lua)

Смысл:

- вычислить `project_root`;
- добавить нужные пути в `package.path`;
- сделать CLI запуск более устойчивым к cwd.

Это хорошая маленькая правка и не источник текущей боли.

---

## Что в новой ветке правильно и должно остаться

### Hand-first direction

Это не шум и не случайное усложнение.

Новая идея сама по себе сильная:

- рука перестаёт быть только хвостом после manifest commit;
- выбор становится ближе к живому игровому чтению;
- позже это может лучше лечь и на pair-card laws.

### Clear actions

Это правильно, потому что:

- reset/clear перестают быть локальной UI-магией;
- их можно тестировать в CLI;
- их можно переносить между клиентами честно.

### CLI/TUI как отдельная манифестация

Это тоже правильный ход.

Нам и так нужен был:

```text
core
|- protocol/headless client
|- human CLI manifestation
|- LOVE manifestation
```

Так что сам факт появления `src/cli/*` — это не поломка, а шаг в верную сторону.

---

## Что сейчас поломано

Ниже не вкусовщина, а реальные структурные дефекты.

### 1. Protocol clients не мигрированы на новые фазы

Это главный дефект ветки.

`interaction(state)` уже живёт в hand-first фазах:

- `await_start`
- `await_complete`
- `await_ready`

Но protocol-driven consumers всё ещё думают старой моделью:

- `await_commit`
- `await_hand`

Файлы:

- [src/sim/runner.lua](/home/slasten/dev/processcards/src/sim/runner.lua)
- [cli.lua](/home/slasten/dev/processcards/cli.lua)

Последствие:

```bash
lua cli.lua headless 7 24
```

останавливается на:

```text
unknown_phase_await_start
```

То есть:

- новый core уже один;
- старый protocol-client уже другой;
- `crystall` потерял единый interaction truth.

Это high-severity regression.

### 2. `interaction(state)` врёт по неполноте

В `await_start` prompt говорит:

```text
Choose a manifest slot or a hand card.
```

Но наружу interaction surface отдаёт только:

- `legal.commit_slots`

И не отдаёт:

- `legal.hand_cards`

Файл:

- [src/core/interaction.lua](/home/slasten/dev/processcards/src/core/interaction.lua)

Это критично, потому что:

- клиент, который честно читает только protocol surface,
  не может узнать legal hand-first choices;
- значит клиент неизбежно начнёт гадать;
- а это уже прямое нарушение всей великой миграции.

Коротко:

```text
text says hand-first exists
interaction surface does not fully expose it
```

### 3. `arm_hand` стал фазово слишком свободным

Сейчас `turn.arm_hand()` разрешает arming hand-card даже когда:

- `state.committed == nil`

Это само по себе ещё можно считать новым canonical behavior,
если оно честно выражено через interaction protocol.

Но проблема глубже:

- эта свобода не ограничена фазой достаточно жёстко;
- её легко вызвать в фазах, где рука уже не должна мутировать selection-state.

Файл:

- [src/core/turn.lua](/home/slasten/dev/processcards/src/core/turn.lua)

Конкретная проблема:

- можно менять `armed_hand` уже в `await_operator`;
- это создаёт скрытую cross-phase мутацию;
- машина получает состояние, которое interaction shell может не ожидать.

Это уже не просто UI-шероховатость. Это runtime hole.

### 4. CLI/TUI input уже живёт по новой интуиции, но без достаточного phase-gating

Файл:

- [src/cli/input.lua](/home/slasten/dev/processcards/src/cli/input.lua)

Сейчас:

- клавиши `a..f` почти всегда ведут к `arm_hand`;
- slot digits в `await_start/await_complete/await_ready` ведут к `commit_manifest`;
- но сам клиент не проверяет interaction contract достаточно жёстко.

Иными словами:

```text
new TUI already assumes hand-first truth
but protocol surface is not yet strict enough to support it honestly
```

Поэтому TUI начинает жить “примерно правильно”, а не строго правильно.

### 5. `smoke` больше не достаточный индикатор здоровья

Это важно отдельно зафиксировать.

Сейчас возможно одновременно:

- `smoke` зелёный;
- `headless` сломан;
- `autoplay` сломан.

Значит:

- старый smoke coverage больше не покрывает новый protocol branch;
- branch health надо оценивать уже по:
  - `headless`
  - `autoplay`
  - protocol interaction legality

---

## Почему это произошло

Причина не в том, что hand-first идея плохая.

Причина в другом:

### Core moved faster than protocol clients

То есть:

1. ядро уже стало новым;
2. `interaction` стало наполовину новым;
3. protocol-driven consumers остались старыми;
4. TUI уже начал жить в новой интуиции;
5. formal contract ещё не дотянут до конца.

Из этого рождается плохое состояние:

```text
new truth
old protocol clients
partially updated interaction
partially intuitive TUI
```

Это именно transition debt.

Не провал идеи, а недоведённая миграция.

---

## Что надо чинить и в каком порядке

Порядок здесь важен. Нельзя лечить это хаотично.

### Step 1. Дочинить `interaction(state)` как единственный formal truth surface

Step doc:

- [HAND_FIRST_STEP_1_INTERACTION_SURFACE_2026-05-07.md](./HAND_FIRST_STEP_1_INTERACTION_SURFACE_2026-05-07.md)

Сначала надо сделать так, чтобы `interaction.read(state)` **полностью и честно** описывал hand-first flow.

Минимум:

#### `await_start`

Должен machine-readable образом отдавать:

- legal `commit_slots`
- legal `hand_cards`
- correct prompt
- correct advance state

Если hand-first легален, это обязано быть видно не только в prompt, но и в `legal`.

#### `await_complete`

Должен честно говорить:

- что уже armed;
- чего именно не хватает до cast-ready;
- какие surfaces сейчас ещё legal:
  - recommit manifest?
  - another hand choice?
  - clear/reset?

#### `await_ready`

Должен быть финальным, однозначным:

- пара выбрана;
- `advance` cast’ит;
- client не должен гадать, что именно подтверждает `△`.

Цель Step 1:

```text
interaction protocol fully describes hand-first machine
without UI guesses
```

Status:

- done
- verified by:
  - `interaction_start_surface`
  - `interaction_complete_from_commit`
  - `interaction_complete_from_hand`
  - `interaction_ready_surface`

### Step 2. Перевести protocol clients на новые фазы

Step doc:

- [HAND_FIRST_STEP_2_PROTOCOL_CLIENTS_2026-05-07.md](./HAND_FIRST_STEP_2_PROTOCOL_CLIENTS_2026-05-07.md)

После Step 1 надо починить:

- [src/sim/runner.lua](/home/slasten/dev/processcards/src/sim/runner.lua)
- [cli.lua](/home/slasten/dev/processcards/cli.lua)

Смысл:

- `headless`
- `autoplay`
- any protocol harness

должны понимать:

- `await_start`
- `await_complete`
- `await_ready`

без legacy fallback на old phase names.

Цель Step 2:

```text
headless client again becomes first-class manifestation
```

Проверка после Step 2:

```bash
lua cli.lua headless 7 24
lua cli.lua autoplay 7 16
```

не должны умирать на `unknown_phase_await_start`.

Status:

- done
- verified by:
  - `lua cli.lua autoplay 7 16`
  - `lua cli.lua headless 7 24`
  - `lua cli.lua bench autoplay 40 1`
  - `lua cli.lua bench headless 40 1`

### Step 3. Закрыть phase-hole вокруг `arm_hand`

Step doc:

- [HAND_FIRST_STEP_3_PHASE_SAFETY_2026-05-07.md](./HAND_FIRST_STEP_3_PHASE_SAFETY_2026-05-07.md)

После того как `interaction` и clients уже согласованы, надо решить,
какой именно hand-first canon мы реально хотим.

Есть 2 допустимых варианта:

#### Variant A. Strict interaction gate

`arm_hand` можно вызывать только тогда, когда interaction phase это разрешает.

Тогда:

- core/action layer валидирует phase;
- illegal hand-arm в `await_operator` и подобных фазах запрещается.

#### Variant B. Core-permissive, client-strict

Core оставляет некоторую permissive гибкость,
но `apply_action` или clients режут illegal phase usage.

Это слабее.

Для текущей архитектуры правильнее выглядит **Variant A**.

Иначе снова получим hidden state drift между client и machine.

Цель Step 3:

```text
armed_hand cannot mutate in semantically wrong phases
```

Status:

- done
- verified by:
  - `arm_hand_blocked_in_operator_phase`
  - `clear_actions_blocked_in_start`

### Step 4. Только после этого чинить LOVE/TUI manifestation details

Пока первые три шага не сделаны, лечить визуальные симптомы — пустая трата времени.

Сначала:

- one protocol truth;
- protocol clients healthy;
- no cross-phase hand hole.

Потом уже:

- TUI UX polish;
- LOVE manifestation hookup;
- train/highlight semantics;
- prompts and clears.

Status:

- not started in this repair pass
- intentionally postponed

---

## Что не надо делать

### Не откатывать hand-first branch целиком

Ветка несёт полезную мысль.

Откат сейчас сотрёт:

- новую форму выбора;
- TUI manifestation work;
- clear-actions surface.

Это нерационально.

### Не чинить сначала LOVE

Это снова поставит `manifest` впереди `crystall`.

Сейчас проблема живёт в:

- protocol truth
- phase model
- consumer migration

А не в том, как именно рисуется клиент.

### Не маскировать проблему prompt’ами

Если prompt пишет правильный текст, а legal surface его не выражает,
это не fix.

Это cosmetic lie.

### Не держать старые и новые phase names вперемешку как long-term решение

На короткий bridge это допустимо,
но как постоянный канон — нет.

Иначе:

- `interaction` будет одно;
- clients другое;
- docs третье.

---

## Exit criteria

Ветка считается починенной только если выполнены все условия ниже.

### Protocol health

- `headless` больше не падает на `await_start`
- `autoplay` больше не падает на `await_start`
- старый `smoke` не единственный зелёный тест

Current result:

- all three conditions satisfied

### Interaction truth

- `await_start` честно отдаёт both sides:
  - `commit_slots`
  - `hand_cards`
- `await_complete` и `await_ready` не требуют клиентских догадок

Current result:

- satisfied

### Phase safety

- `armed_hand` не мутирует в неподходящих фазах
- нельзя случайно испортить operator/target phase hand-arm вызовом

Current result:

- satisfied

### Manifest readiness

- и CLI/TUI, и LOVE могут быть thin clients
- ни одному клиенту не нужно самому придумывать:
  - что сейчас legal
  - что сейчас armed
  - что делает `△`

Current reading:

- `crystall` side is now in a state where thin clients are realistic
- `manifest` side still needs its own rebuild/hookup pass

---

## Short conclusion

Текущее состояние — это не “DeepSeek всё сломал”.

Точнее:

- он сдвинул машину в содержательно интересную сторону;
- но не довёл миграцию до честного protocol finish;
- из-за этого сейчас живёт transition debt между core, protocol clients и manifestations.

Поэтому правильное чтение ситуации такое:

```text
hand-first branch should be repaired, not reverted
protocol must catch up with the new core truth
only then manifestations may follow
```

Это и есть задача следующего repair pass.
