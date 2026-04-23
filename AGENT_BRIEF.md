# Agent brief

You are joining an active design/implementation process.

You are not here to merely execute a finished specification.
You are here to help turn the current ProcessCards design into a small runnable Lua simulator and surface what breaks.

## Working attitude

Prefer:

- small executable steps
- clear state tables
- simple tests
- explicit uncertainty
- reporting design gaps
- asking for decision only when the code cannot proceed safely

Avoid:

- redesigning the whole game alone
- treating every document sentence as final law
- importing the whole slastack into this repo
- philosophical expansion unrelated to implementation
- Python
- external dependencies
- UI work before the rules engine exists

## What to build first

Start with a Lua table-machine that can represent current game state:

```text
deck
hand
targets
manifest
latent
runtime
grave
trump_zone
log
```

Then implement enough mechanics to test the current design:

- construct a deck
- initialize board state
- check weak / strong / mirror relations
- preserve 5 manifest + 5 latent slots
- resolve `RECAST`
- model trump zone capacity 2
- write tests around invariants

## What is allowed to be provisional

The following are still design surfaces, not finished law:

- exact setup procedure
- target compiler details
- all card texts
- full trump set
- balance numbers
- final CLI format

If a provisional choice is needed, make the smallest local assumption and write it down.

## Canonical topology

Use ProcessLang topology from:

```text
/home/slasten/Документы/stack/stack-core/ProcessLang/canon.lua
```

Topology is not provisional.

## First useful milestone

A good first milestone is:

```text
lua tests/run.lua
```

passing tests that prove:

- setup creates valid zones
- relation checks work
- RECAST preserves board shape
- old manifest becomes new hand
- old latent becomes manifest
- old hand becomes latent / overflow grave
- third resolved trump resets trump zone into deck

machines only. not for humans.

## Optional skill

When working with ProcessLang traces, use the local ProcessLang skill:

```text
/home/slasten/Документы/stack/protocols/skills/processlang/SKILL.md
```

Use it for glyph reading, trace validation, and ProcessLang state-packet interpretation.
Do not use it as a replacement for ProcessCards rules documents.
