# First LOVE Prototype TZ

Статус:

```text
canonical crystall contract
```

Этот документ фиксирует первый реально собираемый прототип после отказа от browser-v0.

## 1. Build target

Первый собираемый runtime теперь:

```text
Lua + LÖVE
```

Browser-v0 больше не является текущим build target.

## 2. Goal

Собрать кликабельную minor-machine,
в которую уже можно играть на одном экране,
без victory conditions,
но с живым core gameplay loop.

## 3. Required loop

Прототип обязан поддерживать:

- setup
- `play`
- `discard`
- `pass`
- hand selection
- manifest targeting
- basic operator resolution
- ordered grave
- visible latent / targets / runtime surfaces

Important:

- `play` may auto-detect weak vs strong from legality
- strong payload must follow combined-pair law,
  not deprecated `1-2 effects` wording

## 4. Scope

Входит:

- `100` minor cards
- `deck`
- `hand`
- `manifest row`
- `latent row`
- `targets`
- `runtime`
- `grave`
- `log`

Не входит как обязательное:

- victory conditions
- trumps
- trump zone
- duplicate law
- full connect multi-card assembly
- full runtime install behavior

## 5. Rules source priority

Primary sources:

- `docs/table/OPERATORS_INDEX.md`
- `docs/table/operators/*.md`
- `docs/table/CONNECT_LAW.md`
- `docs/table/STRONG_COMBINED_LAW.md`
- `docs/table/STRONG_PAIR_TABLE.md`
- `docs/table/MINOR_MACHINE.md`

## 6. UI law

UI must fit as one readable card table on a normal desktop screen,
including `1440p`.

Manifest row remains the center.
Main loop must be usable by mouse only.

## 7. Technical shape

Minimum file set:

```text
main.lua
conf.lua
```

Additional Lua modules are allowed if needed,
but first build should stay tight.

## 8. Definition of done

This prototype is done when:

1. `love .` launches
2. board is readable on one screen
3. weak / strong / discard / pass work
4. legal / illegal targets are visually distinct
5. several turns can be played without state corruption
6. no core action depends on digital-only convenience

## 9. Short formula

```text
first LOVE prototype = one-screen clickable minor-machine
```
