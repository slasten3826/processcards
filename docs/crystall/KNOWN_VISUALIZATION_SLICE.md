# Known Visualization Slice

Status:

```text
current presentation slice
first visible known-state branch
```

## Scope

This slice defines how `known` should first appear in LOVE,
especially for `OBSERVE`.

The goal is:

- make `known` visibly distinct from `hidden`
- keep `known` clearly distinct from `revealed`
- avoid reading `known` as disabled-state or broken transparency

## Core decision

`Known` should not manifest
as a fully face-up card
and should not manifest
as a whole-card alpha fade.

That would read as:

- disabled
- ghost object
- drag state
- unavailable object

which is not the meaning of `known`.

## Current visual law

`Known` should read as:

```text
face-down card
with leaked identity
```

So the card stays concealed in geometry,
but no longer stays opaque in meaning.

## Required visible difference

Current intended mapping:

- `hidden` = ordinary card back
- `known` = card back + ghost identity overlay
- `revealed` = full face-up card

## Preferred first implementation

The first `known` layer should use:

1. the normal back-face remains
2. a soft ghost overlay of the two operator glyphs appears over that back
3. the overlay should stay subtle, not fully readable as a normal face
4. the frame may gain a slight additional clarity,
   but frame change must remain secondary

So the strongest signal is:

```text
identity leaks through the back
```

not:

```text
the card turns into a faded full face
```

## OBSERVE consequence

This slice exists mainly because `OBSERVE` now means:

```text
choose one hidden card on board
make it known
```

So the player must be able to tell:

- this card is still concealed on board
- but it is no longer unknown

## Current restrictions

The first `known` presentation should avoid:

- full face rendering
- full-card alpha fade
- noisy glow
- exact copy of revealed face with only reduced opacity

## ID cleanup note

Current prototype may still show internal card ids,
but that is not part of the intended long-term `known` language.

Card ids should later disappear as primary visible information.

So `known` must stand on its own
through card-language,
not through debug labels.

## Short formula

```text
known = back-face remains,
identity softly leaks through
without becoming fully revealed
```
