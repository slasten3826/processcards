# ARMED TARGET LAW

## Status

Current table law candidate.

This is not yet fully migrated into runtime or LOVE.

## Core statement

The machine needs a third armed concept:

```text
armed hand
armed operator
armed target
```

`armed target` is a real machine state.

It is not the same as:

- a legal target field
- a revealed target
- a hand card armed for turn launch
- an operator armed for confirmation

## Why this is needed

Current operator effects already produce target phases:

- `CHOOSE`
- `OBSERVE`
- `MANIFEST`
- `LOGIC`
- later more operators

Right now these phases often jump directly from:

```text
legal targets shown
-> click
-> effect resolves
```

or into inconsistent half-states.

That is too weak for a core interaction loop.

The machine needs:

```text
legal targets shown
-> one target becomes armed
-> △ confirms that armed target
```

## Definition

An `armed target` is:

```text
the currently selected effect target
which has not yet been confirmed
```

It is the next object the machine is prepared to consume
if the player presses `△`.

## General target-phase law

Once an operator has been confirmed
and has entered a target phase:

1. all legal targets may be shown by the target-language
2. clicking one legal target arms it
3. clicking the same armed target again may clear it
4. only after `△` does the effect actually consume that target

So target phase becomes:

```text
legal set
-> armed target
-> confirm
```

## Relationship to operator confirmation

This does not replace operator confirmation.

It comes after it.

Short formula:

```text
arm operator
-> confirm operator
-> arm target
-> confirm target
```

## Relationship to legal target trains

The legal target train is not the same thing as armed target.

It only says:

```text
these are possible
```

The armed target says:

```text
this exact one is currently selected
```

So once a target becomes armed:

- its train should usually disappear
- it should receive a different armed-state manifestation

## Scope

This law should eventually govern:

- `CHOOSE`
- `OBSERVE`
- `MANIFEST`
- `LOGIC`
- future target-bearing operators

It may also later govern certain trump-target phases
if the trump branch introduces them.

## Design consequence

Without `armed target`,
the machine remains ambiguous during target phases.

With `armed target`,
the machine can read clearly as:

```text
I have chosen the effect
I am now choosing the exact object
I have not yet confirmed it
```

## Short formula

```text
armed target is a first-class machine state.
it sits after legal target visibility
and before target resolution.
```
