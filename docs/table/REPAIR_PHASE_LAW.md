# Repair Phase Law

Status:

```text
canonical table law
current runtime repair branch
```

## 1. Core claim

`Repair` is no longer a hidden implementation tail.

It is now an explicit machine phase.

Short formula:

```text
repair = the machine closes an opened structural slot
```

## 2. Why repair is now a real phase

Current machine already requires repair in multiple places:

1. after the committed world-node leaves `manifest`
2. after an operator effect if that operator reopens the board
3. before trump-flow continuation
4. as part of board-closure truth

So `repair` must now be read as phase law,
not as invisible housekeeping.

## 3. When repair begins

Repair begins whenever a structural obligation appears.

Current examples:

- a `manifest` slot becomes empty after commit consumption
- a revealed `manifest` card is extracted by an operator
- a later effect may reopen another structural board slot

## 4. Current canonical repair object

At the current stage,
the primary repair object is:

```text
an opened manifest slot
```

Repair then means:

1. try to promote `latent[i] -> manifest[i]`
2. if the promoted latent card is a trump,
   that trump enters `trump flow`
3. closure of `manifest[i]` still continues through open deck-entry law
4. then `latent[i]` is refilled from deck as concealed card

Short form:

```text
manifest repair = close manifest
then refill latent
```

## 5. Concealed vs open consequence

Repair obeys the already existing split:

### Open closure

If the machine owes an open visible slot:

```text
reveal topdeck first
```

If revealed result is:

- `minor` -> it may close the slot
- `trump` -> it enters `trump flow`, and closure continues

### Concealed refill

If the machine owes a concealed refill:

```text
move topdeck directly as not-revealed
```

Trump status does not matter until later reveal.

## 6. Repair priority

Repair precedes trump-flow continuation.

That means:

- trumps may enter `trump flow` during repair
- but trump flow may not continue
  until repair has fully finished

This is one of the main reasons
repair must now be a named phase.

## 7. Secondary repair

An operator effect may itself reopen the board
after the first repair already finished.

If that happens:

1. the normal first repair still remains valid
2. the operator resolves
3. the operator reopens a structural slot
4. the machine enters repair again

So current machine already allows:

```text
repair
operator
repair again
```

## 8. CHOOSE consequence

This law is especially important for `CHOOSE`.

If `CHOOSE` removes one revealed manifest card into hand:

1. the first normal repair has already happened
2. `CHOOSE` reopens a manifest slot
3. the machine must enter a second repair phase
4. only after that may the played card fully discharge
5. only after that may trump flow continue

## 9. Short formula

```text
repair is an explicit machine phase.
whenever a structural slot is opened,
the machine owes closure before later continuation.
```
