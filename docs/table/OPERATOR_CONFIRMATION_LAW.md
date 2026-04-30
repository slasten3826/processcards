# OPERATOR CONFIRMATION LAW

## Status

Law candidate. This document describes the intended replacement
for the current immediate operator-choice shell.

## Core statement

Operator selection is an armed state, not an immediate execution click.

## Operator phase

After:

```text
hand -> play
repair phase
```

the machine enters operator confirmation state.

In this state there are three legal armed states:

```text
armed = operator A
armed = operator B
armed = none
```

## Input model

Clicking an operator card toggles it:

- click operator A -> arm operator A
- click operator B -> arm operator B
- click armed operator A again -> arm none
- click armed operator B again -> arm none

Only one operator may be armed at a time.

## Confirmation

`△` confirms the currently armed state.

That means:

- if operator A is armed, operator A begins its effect path
- if operator B is armed, operator B begins its effect path
- if none is armed, the played card discharges with no operator effect

## Target visibility

Only the currently armed operator may expose its legal targets.

So:

- armed `OBSERVE` shows hidden targets
- armed `CHOOSE` shows manifest reclaim targets
- armed `MANIFEST` shows unrevealed targets
- armed `LOGIC` shows public revealed minor targets

If no operator is armed, no operator-specific target field should be shown.

## Skip model

No separate skip button is required.

```text
no operator armed
+ △
= discharge the played card without operator payload
```

## Design goal

Operator phase should read as:

```text
inspect the played card
arm one possible effect or arm none
confirm with △
then let the machine continue
```
