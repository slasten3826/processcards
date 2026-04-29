# CLI Bench Findings 2026-04-29

Status:

```text
working machine-bench note
not a table law
```

## Scope

This note records the first meaningful results from the shared headless core.

Its purpose is:

- verify that the extracted game core already behaves coherently
- separate real logic failures from expected machine behavior
- define the next statistical questions

## Bench commands used

```text
lua cli.lua bench smoke 1000 1
lua cli.lua bench latent_trump_closure 1000 1
```

Additional direct distribution probes were also run against the core.

## Result 1: smoke bench

```text
mode=smoke total=1000 passed=1000 skipped=0 failed=0
```

Current reading:

- setup holds
- draw holds
- turn resolution holds
- manifest closure holds
- latent refill holds
- pending trump / trump-zone stub holds
- no invariant failure was observed in 1000 machine runs

This is the first strong sign that the extracted core is already more trustworthy
than the old animation-driven LOVE logic.

## Result 2: latent_trump_closure bench

```text
mode=latent_trump_closure total=1000 passed=707 skipped=260 failed=33
```

Raw reading:

- `260 skipped`:
  - no trump existed in `latent` at setup
- `707 passed`:
  - a latent trump existed
  - and a legal hand-card existed for that committed column
- `33 failed`:
  - a latent trump existed
  - but no legal hand-card existed for that specific committed column

## Important interpretation

The `33 failed` cases are **not currently treated as machine bugs**.

They do **not** mean:

- no legal move exists at game start
- the game is dead
- setup is broken

They mean only:

```text
a latent trump may exist
without being immediately reachable
through the current legal hand for that exact column
```

This is currently treated as a normal property of the machine,
not as an error.

## Setup distribution observed

### Latent trump count at setup

Across 1000 seeded starts:

```text
0 trumps -> 260
1 trump  -> 383
2 trumps -> 266
3 trumps -> 81
4 trumps -> 10
```

Current reading:

- `latent` is now genuinely mixed
- trump presence in `latent` is common
- but `latent` is no longer trump-only

### Target trump count at setup

Across 1000 seeded starts:

```text
0 trumps -> 525
1 trump  -> 389
2 trumps -> 78
3 trumps -> 8
```

Current reading:

- `targets` are also mixed under the current phase-B setup
- `targets` are often minor-heavy
- whether this is desirable is still a design question

## First draw distribution

Across 1000 seeded starts:

```text
topdeck minor -> 800
topdeck trump -> 200
```

Current reading:

- first draw burns into `trump flow` in about `20%` of starts

## Current conclusion

The machine bench already tells us three important things:

1. the shared core is structurally stable enough to trust for further work
2. the old LOVE hole-in-manifest bug was not a core truth bug
3. not every surprising statistical case is a failure

## Next useful questions

The next batch layer should measure:

- frequency of `no legal turn`
- turns until first pending trump
- turns until first trump resolution
- typical trump-flow length
- target-zone composition over larger sample sizes

