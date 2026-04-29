# Turn Effect Priority Slice

Status:

```text
current runtime priority note
not a standalone table law
```

## Scope

This note fixes the current execution priority
between:

- world repair
- played hand-card operator resolution
- trump-flow entry
- trump-flow continuation

## Current priority order

The current runtime order is:

```text
commit world-node
repair the world
allow trumps to enter trump flow if revealed
finish the currently played hand-card operator
move the played hand-card from play to grave
only then allow trump flow to continue
```

## Core claim

Trump entry and trump resolution are not the same thing.

Current machine allows:

```text
revealed trump -> enter trump flow
```

but still delays:

```text
trump flow continuation
```

until the currently played card has finished its own operator phase.

## Why this is correct

Because the played hand-card is now a real temporary effect-bearing object in `play`.

So once it reaches `play`:

- the machine still owes its operator choice
- the machine still owes that chosen operator's resolution
- only after that does the card discharge to `grave`

It would be incoherent to let trump-flow resolution interrupt this unfinished play-phase.

## Interaction with board closure

This note does not replace board-closure priority.

Current reading is:

1. the board must still close first
2. revealed trumps may enter `trump flow` during that closure
3. but even after closure, `trump flow` still waits
   if the played card has not finished its operator phase yet

So the two gates are:

```text
board closure first
played operator completion second
trump flow continuation third
```

## CONNECT example

If a latent trump is revealed during repair:

1. it enters `trump flow`
2. the played card still remains in `play`
3. player chooses an operator
4. if that operator is `CONNECT`,
   two draw procedures happen
5. if those draws reveal more trumps,
   they also enter `trump flow`
6. only after `CONNECT` fully resolves
   and the played card leaves `play`
   may `△` continue the trump flow

## Short formula

```text
trumps may enter flow early
but they do not outrank the currently played hand-card.
The played operator resolves first.
```
