# Core Progress 2026-04-29

Status:

```text
current implementation slice
shared core + LOVE manifestation branch
```

## What now lives in shared core

The game no longer treats LOVE as the source of truth
for the current playable turn branch.

Current truth now lives in:

- `src/core/*`
- `cli.lua`
- `src/sim/*`

LOVE is already consuming this logic for the active gameplay path.

## Core machine layers already working

Current shared core now includes:

- setup
- draw procedure
- concealed refill
- manifest repair
- board closure gate
- trump flow entry
- pending trump
- operator phase
- known / hidden / revealed information state

## Current operator coverage

The following operators are no longer stubs:

- `CONNECT`
- `CYCLE`
- `CHOOSE`
- `OBSERVE`

Current meanings:

- `CONNECT` = perform 2 draw procedures
- `CYCLE` = draw 1, then discard 1
- `CHOOSE` = take one revealed manifest card into hand, then repair
- `OBSERVE` = choose one hidden card on board and advance its information state

## Current OBSERVE runtime branch

`OBSERVE` is now split correctly by board context:

- hidden minor on board -> `known`
- hidden trump in `latent` -> leaves `latent`, enters `trump flow`, `latent` refills
- hidden trump in `targets` -> revealed in place, stays in `targets`

So `OBSERVE` no longer leaves latent or target trumps in an incoherent face-down state.

## Current LOVE manifestation branch

LOVE now visibly manifests:

- pending operator choice
- pending hidden target choice
- pending hand target choice
- pending manifest target choice
- known cards as concealed geometry with ghost identity leak
- separate trump flow zone

This means the current playable path is already:

```text
core decides
LOVE manifests
CLI tests
```

## Machine bench status

The CLI bench is already usable as a machine test stand.

It now supports:

- scenario runs
- smoke runs
- batch bench runs
- invariant checks for the current gameplay branch

This bench already helped catch:

- bad phase-B setup law
- stale manifest-hole manifestation bug
- trump-zone flush bug back into deck

## What is still not done

Still missing from the live core branch:

- `MANIFEST`
- `LOGIC`
- `ENCODE`
- `FLOW`
- `DISSOLVE`
- `RUNTIME`
- individual trump payloads
- full terminal loss / win closure

## Short formula

```text
the machine is no longer only a LOVE prototype.
it is now a shared playable core with CLI verification and LOVE manifestation.
```
