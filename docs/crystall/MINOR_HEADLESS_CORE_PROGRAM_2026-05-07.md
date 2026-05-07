# Minor Headless Core Program 2026-05-07

## Status

Этот документ становится корневым для текущего repair branch.

Он отвечает не на вопрос:

```text
что сломано прямо сейчас
```

а на вопрос:

```text
какую машину мы вообще хотим получить
```

Документ [DEEPSEEK_HAND_FIRST_REPAIR_2026-05-07.md](./DEEPSEEK_HAND_FIRST_REPAIR_2026-05-07.md) остаётся документом диагноза.

Этот документ — документ программы.

---

## Цель

Текущая цель проекта не в том, чтобы сразу собрать всю игру целиком,
включая весь trump branch.

Текущая цель такая:

```text
собрать полноценное headless ядро
для минорной логики игры
с честным interaction protocol
и оставить рабочие stubs / hooks для козырей
```

Иначе говоря:

### Надо получить

1. один source of truth для minor game loop;
2. playable CLI manifestation;
3. protocol/headless client, который может гонять партии;
4. thin LOVE manifestation later;
5. trump branch не как “доделанную систему”, а как:
   - legal structural placeholders
   - pending hooks
   - runtime stubs

### Не надо пытаться получить прямо сейчас

1. всю игру целиком;
2. весь trump ecology;
3. все special-case UI flows;
4. полный polished manifestation.

---

## Почему именно так

Потому что minor branch — это общий фундамент.

Если его не сделать жёстко и честно,
то каждый следующий trump будет:

- не садиться в машину;
- требовать локальных патчей в клиентах;
- плодить новые interaction holes.

А если minor headless core собрать правильно,
то каждый следующий trump уже добавляется как отдельный controlled branch:

```text
law
-> core effect
-> CLI scenario
-> headless checks
-> manifestation hookup
```

То есть:

```text
minors = common machine
trumps = separate injections into an already stable machine
```

---

## Что именно считается "minor headless core"

Не абстрактно “игра без графики”.

А очень конкретно:

### 1. State truth

Ядро честно хранит:

- board state
- hand state
- information states
- operator states
- repair states
- grave state
- ready/cast states
- pending target states

### 2. Interaction truth

Ядро честно отдаёт:

- current phase
- legal surfaces
- armed surfaces
- meaning of `△`
- prompts
- clear/reset legality

### 3. Action truth

Ядро честно принимает:

- `commit_manifest`
- `arm_hand`
- `arm_operator`
- `arm_target`
- `advance`
- `clear_*`
- later trump-specific actions only if truly needed

### 4. Event truth

Ядро честно эмитит:

- what changed
- what moved
- what revealed
- what discharged
- what opened target phase
- what closed target phase

### 5. Headless consumer viability

CLI/headless client может:

- играть ходы;
- играть партии;
- падать только по законам машины, а не по дыркам interaction surface;
- быть первым тестовым consumer’ом minor gameplay.

---

## Что входит в current minor scope

### Operators

Current minor scope должен закрыть живыми:

- `CONNECT`
- `CYCLE`
- `CHOOSE`
- `OBSERVE`
- `MANIFEST`
- `LOGIC`

### Zones

Current minor scope должен честно держать:

- `manifest`
- `hand`
- `play`
- `runtime`
- `latent`
- `targets`
- `grave`
- `deck`

### Selection laws

Current minor scope должен честно выражать:

- armed hand
- armed operator
- armed target
- pair-card law where it truly applies
- hand-first start if it remains canon after repair

---

## Что входит в trump scope только как stub

Вот это важно зафиксировать жёстко.

Trump branch сейчас не надо “доделывать по дороге”.

Надо оставить:

### Structural truths

- `trump flow`
- `trump zone`
- pending trump state
- trump class distinction
- order of trump resolution

### Minimal runtime stubs

- place to enqueue pending trump
- place to resolve pending trump
- place to store trump branch state
- placeholder events / prompts where needed

### But not yet full content

Не надо сейчас требовать:

- full trump ecology
- all trump interactions
- full trump manifestation richness
- all edge-case chain explosions

Потому что каждый trump почти неизбежно:

- отдельный design object;
- отдельная implementation object;
- отдельный QA object.

---

## Program structure

Этот repair program идёт не одним документом, а несколькими controlled steps.

### Root

- [MINOR_HEADLESS_CORE_PROGRAM_2026-05-07.md](./MINOR_HEADLESS_CORE_PROGRAM_2026-05-07.md)

### Diagnosis

- [DEEPSEEK_HAND_FIRST_REPAIR_2026-05-07.md](./DEEPSEEK_HAND_FIRST_REPAIR_2026-05-07.md)

### Step docs

- [HAND_FIRST_STEP_1_INTERACTION_SURFACE_2026-05-07.md](./HAND_FIRST_STEP_1_INTERACTION_SURFACE_2026-05-07.md)
- [HAND_FIRST_STEP_2_PROTOCOL_CLIENTS_2026-05-07.md](./HAND_FIRST_STEP_2_PROTOCOL_CLIENTS_2026-05-07.md)
- [HAND_FIRST_STEP_3_PHASE_SAFETY_2026-05-07.md](./HAND_FIRST_STEP_3_PHASE_SAFETY_2026-05-07.md)

Current status:

- Step 1 completed and verified
- Step 2 completed and verified
- Step 3 completed and verified

---

## Practical order

### Step 1

Сначала добивается `interaction(state)` как complete machine-readable truth.

Без этого всё остальное будет гадать.

### Step 2

Потом protocol clients:

- `headless`
- `autoplay`
- CLI auto loop

должны снова стать честными consumers этой truth-surface.

### Step 3

Потом phase safety:

- никакой hidden mutation of `armed_hand`
- никакой phase drift
- никакой полумагии между start/complete/ready/operator/target

### Step 4

И только потом:

- TUI polish
- LOVE hookup
- target trains
- UI comfort

---

## Success condition

Repair branch считается успешным не тогда, когда “вроде поиграть можно”.

А когда выполняется формула:

```text
minor game loop is fully playable headless
protocol clients do not guess
CLI can act as first real manifestation
LOVE can become a thin manifestation later
trumps remain pluggable, not entangled
```

Current status relative to this condition:

- `interaction(state)` now expresses hand-first start/complete/ready truth
- protocol-driven `autoplay` and `headless` understand the new phases
- `arm_hand` and `clear_*` are gated through interaction legality
- interaction scenarios, protocol benches, `headless`, `autoplay`, and `smoke` are green

This does not mean the whole minor branch is content-complete.

It means the current hand-first repair program for the headless core is no longer structurally broken.

---

## Short conclusion

Текущая задача проекта:

```text
не чинить всё подряд
а собрать честный minor headless core
и оставить trump branch как controlled future work
```

Это и есть правильная база для следующих ходов.
