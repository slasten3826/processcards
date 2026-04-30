# Grave Viewer UI Slice

Status:

```text
current LOVE-only interaction slice
neutral grave viewer before LOGIC integration
```

## Scope

This slice does **not** implement `LOGIC` yet.

It only defines the neutral user interface
for opening and reading the full `grave` zone in LOVE.

`LOGIC` is a later consumer of this viewer,
not the reason to design it backwards.

## Core requirement

The game now needs a real grave viewer.

Reason:

- `grave` order matters
- `grave` is now an actual gameplay-relevant zone
- compact stack rendering in the side panel is not enough anymore

## Required behavior

### 1. Open by click

Clicking the `grave` panel opens the full grave viewer.

This should work even outside any active operator effect.

Short formula:

```text
grave is always browsable by click
```

### 2. Full grave, not a subset

The viewer must expose the whole grave.

Not:

- top card only
- top few cards only
- collapsed history preview

But:

```text
full ordered grave
```

## Order law

Grave order is important.

The viewer must preserve and show that order clearly.

That means:

- the player must be able to read which card is newest
- which card is older
- and how the stack/history is arranged

The viewer is not a bag of cards.

It is an ordered discard history.

## Closing law

The viewer closes by clicking outside the grave field.

Current first-pass close behavior:

```text
click outside -> close grave viewer
```

No extra close button is required for the first slice.

## Presentation direction

The viewer may be rendered as a new opaque field
on top of the board.

Current preferred direction:

- full non-transparent overlay field
- rendered above the board
- grave cards arranged inside it
- click outside closes it

This means the grave viewer is not a tooltip
and not a tiny expanded stack.

It is a temporary focus surface.

## Layout constraint

The first implementation must already respect:

```text
720p baseline layout
```

So the viewer must be designed
for the current LOVE screen and board density,
not only for wide desktop assumptions.

## Implementation order

The correct order is:

1. build neutral grave viewer UI
2. make it open by click
3. make it close by outside click
4. make grave order legible
5. only later let `LOGIC` use this viewer as a target picker

This order is important.

The grave viewer should not be born
as a one-off `LOGIC` hack.

## What this slice explicitly does not define yet

Not yet decided here:

- exact card grid vs row vs staggered layout
- exact hover enlargement behavior
- exact newest/oldest direction visuals
- `LOGIC`-specific target highlighting

Those belong to the next layer.

## Short formula

```text
grave must become a real clickable viewer in LOVE.
it shows the full ordered grave on an opaque overlay field.
clicking outside closes it.
LOGIC comes later on top of this.
```
