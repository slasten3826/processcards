# Halt Law

```text
STATUS: LEGACY as of 2026-07-28
superseded by HALT_MODE_LAW.md
причина: HALT задаёт ёмкость очереди вместо флагов цепи
```


Статус:

```text
canonical table law
adopted individual trump event
```

Core edge:

```text
△ -> ☱
MANIFEST -> RUNTIME
```

## 1. Core identity

`HALT` is not a value trump.

It is a trump-flow boundary event.

It does not cancel what has already begun.
It prevents further trump entry
after the current resolving item finishes.

Short formula:

```text
finish current resolution
deny further trump entry
```

## 2. Reading

`△` here is not reveal for information.

It is the moment
the stop-law becomes active.

`☱` here is not ordinary installation.

It means a temporary active condition
of the current trump flow:

```text
after HALT appears,
the current flow may complete,
but no further trump may enter it
```

So this trump reads as:

```text
revealed stop-law becomes active flow boundary
```

## 3. Core law

If `HALT` becomes known during an ongoing trump flow:

1. the current resolving item completes normally
2. no further trump resolution may begin during that same flow
3. any trump revealed later in that same flow becomes a `halted trump`
4. halted trumps do not resolve
5. when the halted flow closes, halted unresolved trumps are shuffled into deck
6. `HALT` itself then follows ordinary trump ecology
7. the already-living current resolver follows its own trump law

If `HALT` becomes known
and no further trump entry would occur,
it has no additional flow effect.

Short formula:

```text
HALT resolves
current item finishes
later trumps become halted trumps
halted unresolved trumps -> deck
HALT itself -> ordinary trump ecology
current resolver -> its own ordinary/special ecology
```

## 4. Halted trumps

`halted trump` is a rules term.

It means:

```text
trump revealed after HALT
in the same halted flow,
but not allowed to begin resolution
```

Important:

- `HALT` itself is not a halted trump
- a halted trump is revealed, but unresolved
- halted trumps do not enter `trump zone`
- halted trumps do not go to `grave`
- halted trumps are flushed directly back into `deck` when the halted flow closes

Important extension:

The already-living resolver is not automatically erased by `HALT`.

If a trump was already resolving when `HALT` appeared,
that trump may finish its own living procedure.

This matters for burst trumps such as `RUSH`.

For `RUSH`:

- `HALT` does not cut the six-card burst in half
- later trumps exposed after `HALT` become halted trumps
- `RUSH` itself follows the ecology allowed by its own law

Canonical compression:

```text
HALT preserves current resolver
HALT denies later trump entry
halted unresolved trumps return to deck
HALT itself follows ordinary ecology
```

## 5. What HALT does not do

`HALT` does not:

- cancel the current resolving item mid-instruction
- undo the board
- revert already-completed steps
- stop ordinary non-trump substeps inside the current instruction body

It means only:

```text
let the current resolving item finish
block later trump starts in that same flow
```

## 6. Solo behavior

If `HALT` appears alone,
with no later trump entry to suppress,
it has no additional boundary effect
beyond its own ordinary resolution.

This is intentional.

`HALT` is context-sensitive by design.

## 7. Relation to trump ecology

`HALT` does not invent separate ecology.

It is the explicit special-case boundary
already recognized by:

- [TRUMP_FLOW_LAW.md](./TRUMP_FLOW_LAW.md)
- [TRUMP_RESOLUTION_ORDER_LAW.md](./TRUMP_RESOLUTION_ORDER_LAW.md)
- [TRUMP_ZONE_LAW.md](./TRUMP_ZONE_LAW.md)

Its specificity is not in leaving the machine.

Its specificity is in changing
how the current trump flow is allowed to close.

## 8. Design character

`HALT` should feel:

- anti-cascade
- anti-overgrowth
- anti-runaway resolution
- context-dependent
- precise rather than explosive
- more like a machine law than a spectacle event

This is a trump of:

```text
boundary
```

## 9. Minimal canonical text

```text
If HALT appears during an ongoing trump flow,
the current resolving item may finish.
No further trump resolutions may begin in that flow.
Any trumps revealed later in that flow become halted trumps.
When the halted flow closes,
halted unresolved trumps are shuffled into deck.
HALT itself follows ordinary trump ecology.
The current resolver follows its own trump law.
```
