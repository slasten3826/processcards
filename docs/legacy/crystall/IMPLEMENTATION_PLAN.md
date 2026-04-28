# План реализации

Статус:

```text
current crystall path
```

Это текущая траектория после sync с новым table canon.

## Phase 0: Table stabilization

До любой новой реализации:

- собрать operator-family docs
- собрать strong-law docs
- развести `prototype-legal now` и `future canon`
- не кодить unresolved rules

Опорные документы:

- `docs/table/OPERATORS_INDEX.md`
- `docs/table/operators/*.md`
- `docs/table/CONNECT_LAW.md`
- `docs/table/STRONG_COMBINED_LAW.md`
- `docs/table/STRONG_PAIR_TABLE.md`
- `docs/table/MINOR_MACHINE.md`

## Phase 1: Crystall sync

Прежде чем двигать runtime,
нужно держать handoff-слой синхронным с table.

Задача:

- один текущий runtime target
- один текущий first-prototype scope
- zero contradictions about strong law

## Phase 2: Minimal LOVE machine

Первый runnable target:

```text
Lua + LÖVE
```

Минимальный executable scope:

- board setup
- full 122-card temporary deck ids
- Start Game setup
- deck
- hand
- manifest row
- latent row
- targets shell
- runtime shell
- grave
- log

## Phase 3: Relation layer

Реализовать только актуальный relation layer:

### Weak

```text
same number
or
same suit
```

No cross-position weak matching.

### Strong

```text
canon adjacency decides strong legality
```

using:

```text
/home/slasten/Документы/stack/stack-core/ProcessLang/canon.lua
```

### Mirror

Mirror remains diagnostic structure,
not mandatory payoff source.

## Phase 4: Action surface

Первый playable action surface:

- `play`
- `discard`
- `pass`

Where:

- `play` auto-detects weak vs strong from legality
- ordinary play targets only open manifest row
- strong payload follows combined-pair law

## Phase 5: Prototype-safe operator layer

В первом runnable build реализуются только те operator branches,
которые уже достаточно собраны документами.

Allowed:

- placeholder for unresolved pair branches
- deferred logging for not-yet-implemented pair readings

Not allowed:

- fake sequential weak decomposition of strong
- invented payload for unresolved pair

## Phase 6: UI contract

LÖVE table must:

- fit one normal desktop screen
- keep manifest row as center
- show hand, grave, targets, runtime, deck
- show legal/illegal manifest targets
- preserve hidden/public distinction

## Phase 7: Verification

Before any polish:

- prototype launches
- setup is stable
- weak legality works
- strong legality works
- discard works
- pass works
- board shape survives several turns
- grave remains ordered

## Deferred

Explicitly deferred from first playable build:

- victory conditions
- trumps
- trump zone
- duplicate law
- full connect multi-card assembly
- full runtime install behavior
- full pair matrix coverage

## Short formula

```text
stabilize docs
then build one honest LOVE minor-machine
```
