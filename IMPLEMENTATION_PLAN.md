# Implementation plan

This is a suggested path, not a frozen commandment.
If code reveals a better small step, take it and explain why.

## Phase 0: Minimal skeleton

Create plain Lua modules such as:

```text
src/processcards.lua
src/canon_adapter.lua
src/cards.lua
src/state.lua
src/relations.lua
src/setup.lua
src/trumps.lua
tests/run.lua
```

If fewer files are better at first, use fewer.
Keep it table-first.

## Phase 1: Canon adapter

Load:

```text
/home/slasten/Документы/stack/stack-core/ProcessLang/canon.lua
```

Expose a small interface:

```lua
is_adjacent(left, right)
resolve(value)
inventory_order
operators
```

## Phase 2: Card representation

Use simple Lua tables.

Minor example:

```lua
{ kind = "minor", number = "▽", suit = "☶", id = "1☶" }
```

Trump example:

```lua
{ kind = "trump", edge = { "☳", "☶" }, name = "RECAST" }
```

These formats can change if implementation pressure shows a better table shape.

## Phase 3: Setup prototype

Build a prototype deck:

- 100 minors = all ordered number/suit pairs
- enough trump placeholders to test trump handling
- named `RECAST` for edge `☳ -> ☶`

Prototype setup should create:

```text
3 targets face-down
5 manifest cards face-up
5 latent cards face-down
hand cards
grave empty
runtime nil
trump_zone empty
```

If exact initial hand size is uncertain, start with 5 and make it configurable.

## Phase 4: Relation checks

Implement:

```lua
is_weak(a, b)
is_strong(a, b)
is_mirror(a, b)
```

Weak relation:

```text
number_A == number_B
suit_A == suit_B
number_A == suit_B
suit_A == number_B
```

Strong relation:

```text
canon.is_adjacent(suit_A, number_B)
or canon.is_adjacent(suit_B, number_A)
```

Mirror relation:

```text
number_A == suit_B and suit_A == number_B
```

## Phase 5: RECAST

Implement current RECAST behavior from source docs.

Expected behavior:

```text
old manifest -> new hand
old latent -> new manifest
old hand -> new latent
if old hand has fewer than 5, refill latent from deck face-down
old hand overflow -> grave in reveal order
resolved trump -> trump_zone
if trump_zone already has 2 trumps, third trump resets chamber into deck
```

## Phase 6: Tests as design pressure

Write tests for invariants and edge cases that matter now:

- deck construction count
- setup board shape
- weak/strong/mirror examples
- RECAST with old hand size 0
- RECAST with old hand size 5
- RECAST with old hand size > 5
- grave order after overflow
- third trump reset

Run with:

```bash
lua tests/run.lua
```

## Non-goals now

Do not build UI yet.
Do not implement all card texts.
Do not implement full target compiler yet.
Do not create a balancing simulator yet.
Do not rewrite the design into another philosophy document.

machines only. not for humans.
