# Optional Operator Review

Status:

```text
review promoted into shared core / CLI branch
LOVE migration still pending
```

## Current question

Should operator effect resolution be mandatory?

Old runtime assumed:

```text
choose operator A or operator B
```

But the current operator family already reads differently.

## Current reading of live operators

The currently implemented operators are:

- `CONNECT`
- `CYCLE`
- `CHOOSE`
- `OBSERVE`
- `MANIFEST`

All of them read as:

```text
tactical features
```

not:

```text
mandatory taxes
```

Some are used often:

- `CONNECT`

Some are situational:

- `CHOOSE`
- `OBSERVE`
- `MANIFEST`
- future `LOGIC`

That means the operator shell may be too strict
if it always forces one payload to fire.

## Candidate law change

The reviewed candidate is:

```text
operator phase may resolve:
operator A
operator B
or no operator
```

So the played card would still:

- enter `play`
- survive first repair
- enter operator phase

but the player may choose:

- first operator
- second operator
- or no operator at all

Then the played card still leaves `play`
and the turn continues normally.

## Why this now looks coherent

Because current operator docs already present effects
as useful optional tactical opportunities.

They are not framed as compulsory costs
for the right to play the card.

So optional use would not invert their identity.

It would align runtime behavior
with their existing design reading.

## What this would improve

- less forced awkward payload usage
- cleaner distinction between "card was played"
  and "operator opportunity was used"
- better support for situational operators
- less false pressure on future complex operators

## What is not decided yet

This review does **not** yet decide:

- exact UI for skipping operator use
- whether skip should be a third button
- whether some future laws may force operator use

It now records two things:

1. optional operator use was coherent with the live operator family
2. that reading has now been promoted into the shared core / CLI branch

So:

```text
optional operator use now reads as coherent with the live operator family
```

## Short formula

```text
current implemented operators already read as features,
not taxes.
therefore optional operator use is now a coherent next law candidate.
```

Current update:

```text
that candidate has now become the active shared core / CLI branch
through armed operator state and confirmable no-operator discharge
```
