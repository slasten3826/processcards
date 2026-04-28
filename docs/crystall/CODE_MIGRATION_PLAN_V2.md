# Code Migration Plan V2

Статус:

```text
canonical crystall migration plan
soft migration branch
```

Этот документ фиксирует
как переносить current machine canon в код,
не устраивая лишнюю революцию в runtime.

Главная мысль:

```text
migration can be soft
because the old runtime is still small
and the new canon is already coherent
```

## 1. Core strategy

Миграция должна идти не через полный rewrite,
а через последовательную замену узлов:

1. surface geometry
2. turn loop
3. information model
4. draw / trump entry
5. victory/compiler check
6. individual operator / trump payloads

Коротко:

```text
replace machine layers one by one
```

## 2. Why this is a soft migration

Текущий код ещё не настолько большой,
чтобы быть настоящим legacy engine.

Уже есть полезные куски,
которые можно не выбрасывать:

- базовый board state
- zone rendering
- animation scaffolding
- hand / manifest interaction shell
- hinting experiments

То есть задача не:

```text
delete everything
```

А:

```text
reuse the shell
replace the machine inside it
```

## 3. Migration order

### Phase 1. Surface geometry

Сначала привести runtime к current physical shape:

- `manifest = 6`
- `latent = 6`
- `targets = 3`
- `hand = 6`

Definition of done:

- layout and state model already know the new slot counts
- no active code path still assumes the old 5-slot shape

### Phase 2. Turn loop replacement

Убрать старый replacement-style play path.

Вместо него вшить current turn sequence:

1. commit one manifest card
2. choose one legal hand card
3. confirm move
4. `manifest[i] -> grave`
5. `latent[i] -> manifest[i]`
6. `deck top -> latent[i]`
7. played effect resolves
8. played card -> grave
9. post-closure victory check

Definition of done:

- no old hand-to-manifest placement remains as active move law

### Phase 3. Information model

В state model нужно ввести:

- `hidden`
- `known`
- `revealed`

Нельзя оставаться только на `face_up boolean`,
если хотим честно поддержать:

- `OBSERVE`
- `UNVEIL`
- `known but not revealed`
- topdeck state preservation

Definition of done:

- runtime can represent known without forced reveal

### Phase 4. Draw procedure

Draw нужно вынести
в один reusable runtime procedure:

1. reveal topdeck
2. if trump -> enter ordinary trump flow
3. else -> move to hand

Definition of done:

- `CONNECT`
- `CYCLE`
- `RESET`
- later `ORACLE` / `RECAST`

can all call the same draw machinery where applicable.

### Phase 5. Trump flow and ecology

Нужно ввести в runtime:

- `trump flow`
- `trump zone`
- ordered resolution
- ordinary close
- halted close

Это не значит сразу кодить все козыри.

Это значит:

```text
the runtime must have the ecology layer
before all individual trump payloads arrive
```

Definition of done:

- the engine has a real place
  for active in-flight trumps
- resolved trumps do not jump straight to `trump zone` mid-flow

### Phase 6. Compiler win check

После turn-closure runtime должен уметь:

1. detect whether `targets` hold 3 trumps
2. derive the directed 6-slot sentence candidate
3. compare it against current visible `manifest`
4. decide victory only after full closure

Definition of done:

- no mid-resolution victory
- no score-track substitute

### Phase 7. Operators and trumps

Только после предыдущих фаз
стоит полноценно наслаивать:

- operator payloads
- individual trump payloads

Порядок тут должен быть от простого к структурному.

Recommended operator order:

1. `OBSERVE`
2. `MANIFEST`
3. `DISSOLVE`
4. `CONNECT`
5. `CYCLE`
6. `CHOOSE`
7. `LOGIC`
8. `FLOW`
9. `ENCODE`
10. `RUNTIME`

Recommended trump order:

1. ecology already first
2. `FOOL`
3. `SHUFFLE`
4. `UNVEIL`
5. `RESET`
6. `SWAP`
7. `WARRANT`
8. `REPEAT`
9. `UNBOUND`
10. `HALT`
11. `EJECT`
12. `ORACLE`
13. `RECAST`

## 4. First coding target

Первый реальный coding target
должен быть narrower than the full machine.

Лучший первый target сейчас:

```text
6-slot board
new commit/cast turn loop
known/revealed state model
post-closure victory hook
```

То есть сначала:

- не все эффекты
- не все козыри
- а новый core loop

## 5. What should not be rewritten first

Не надо первым делом пытаться:

- переписать все operator docs в code
- кодить все trumps подряд
- строить final UI polish
- строить final animation polish

Это замедлит миграцию
и увеличит поверхность ошибок.

Коротко:

```text
first make the machine true
then make the card content rich
```

## 6. Recommended runtime split

Кодовую миграцию полезно резать так:

### A. State model

- zone arrays
- card information state
- compiler state
- trump flow state

### B. Rules layer

- fit check
- draw procedure
- manifest repair
- target refill
- trump flow close
- victory check

### C. Action layer

- commit manifest
- choose hand card
- confirm move
- resolve turn
- resolve trump event

### D. Presentation layer

- highlights
- movement animations
- reveal/ghost visuals
- trump flow rendering
- victory signal

## 7. Definition of migration success

Migration should be considered successful
when the runtime can truthfully execute:

1. current 6-slot board geometry
2. topology-first turn loop
3. hidden / known / revealed truth model
4. draw procedure
5. trump flow ecology
6. target-compiled post-closure win check

Only after that
does it make sense to ask
whether every card effect is already present.

## 8. Relationship to other docs

Read together with:

- [NEXT_GAMEPLAY_SLICE_V2.md](./NEXT_GAMEPLAY_SLICE_V2.md)
- [../table/CURRENT_CANON_SUMMARY.md](../table/CURRENT_CANON_SUMMARY.md)
- [../table/MACHINE_PRIMITIVES_LAW.md](../table/MACHINE_PRIMITIVES_LAW.md)

Division:

- `CURRENT_CANON_SUMMARY` = what the machine is
- `MACHINE_PRIMITIVES_LAW` = what language the machine should speak
- `NEXT_GAMEPLAY_SLICE_V2` = immediate playable slice
- `CODE_MIGRATION_PLAN_V2` = order of bringing that machine into runtime

## 9. Short formula

```text
soft migration:
first fix the machine skeleton,
then move the turn law,
then move information and trump ecology,
then attach individual card payloads.
```
