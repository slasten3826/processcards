# ADVANCE BUTTON LAW

## Status

Law candidate. Not yet implemented in full.

## Core statement

`△` is the machine's universal advance / confirm button.

It is not only a turn button and not only a trump button.

It is the visible permission for the machine to continue.

## General rule

No major visible chain should continue by itself if the player is expected to read and acknowledge it.

Instead:

```text
machine presents the next meaningful state
player presses △
machine advances
```

## Current intended scope

`△` should eventually cover:

- normal turn launch
- operator confirmation
- no-operator discharge confirmation
- trump-flow continuation
- other future visible chain continuations

## Operator-phase implication

During operator phase:

- the player may arm operator A
- the player may arm operator B
- the player may arm no operator

`△` confirms the currently armed state.

## Trump implication

Trump flow remains queued and visible.

It should not auto-continue through meaningful visible events.

`△` advances the next pending trump event when the machine is ready for trump continuation.

## Design goal

The machine should feel deliberate:

```text
nothing important slips past the player
the player always knows when the machine is waiting
and always knows how to let it continue
```
