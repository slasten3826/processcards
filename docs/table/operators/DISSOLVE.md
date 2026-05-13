# DISSOLVE

Symbol:

```text
☷
```

Статус:

```text
canonical operator law
current column-burn branch
```

## 1. Core identity

`☷` больше не читается как generic visible removal.

Его current identity такая:

```text
burn the latent support of the committed column
before ordinary column ascent
```

Коротко:

```text
☷ dissolves the hidden support layer
of the column being played
```

## 2. What it is not

`☷` now is not:

- broad field removal
- “choose any revealed card and send it to grave”
- generic destruction of arbitrary board matter
- hand interaction
- grave interaction

Это важно.

Если `☷` снова станет просто removal,
он потеряет собственную identity inside ProcessCards.

## 3. Core law

If `☷` is the chosen operator effect,
it acts only in the **committed column**.

That means:

1. look at `latent[i]` under the committed `manifest[i]`
2. force that latent card into contact
3. if it is a `minor`, send it to `grave`
4. if it is a `trump`, send it to `trump flow`
5. refill `latent[i]` from `deck`
6. only after that continue the ordinary column sequence

Short formula:

```text
☷ burns latent[i] first
then the normal column sequence continues
```

## 4. Exact sequence

Let the committed column be `i`.

Normal turn sequence in that column is:

1. `manifest[i] -> grave`
2. `latent[i] -> manifest[i]`
3. `deck top -> latent[i]`

With `☷`, the sequence changes to:

1. inspect `latent[i]`
2. reveal that latent card into contact
3. if `minor` -> `grave`
4. if `trump` -> `trump flow`
5. `deck top -> latent[i]`
6. now perform the ordinary column consume:
   - `manifest[i] -> grave`
   - `latent[i] -> manifest[i]`
   - `deck top -> latent[i]`

So yes:

```text
the same column is pushed one layer deeper
in a single turn
```

## 5. Why this is the right branch

This keeps `☷` specific to the ProcessCards machine.

It does not merely remove a public object.

It does something more native:

```text
it dissolves the hidden support
of the world-node you are already committing
```

That makes `☷`:

- local
- structural
- column-bound
- readable on cardboard

## 6. Trump consequence

If the dissolved `latent[i]` card is a trump,
it does not go to grave.

It enters:

```text
trump flow
```

This means `☷` can force earlier contact
with hidden trump matter in the committed column.

That is part of its power.

## 7. Minor consequence

If the dissolved `latent[i]` card is a minor,
it simply goes to:

```text
grave
```

So `☷` can also be read as:

```text
skip one hidden support layer
and let a deeper future rise sooner
```

## 8. No extra target law

`☷` should not open a separate free target-selection surface.

Its target is already defined by the move:

```text
the committed column itself
```

This is one of the main advantages of this branch.

It means:

- no extra board-wide target UI
- no ambiguity
- no fake “choose any field card” reading

## 9. Pair-law consequence

This law gives `☷` a clean family identity:

- `☷☳` may later choose how the column-burn branches
- `☷☴` may later inspect the support before burning it
- `☷☵` may later rewrite concealed support around the burn
- `☷☱` may later install column-burn pressure into runtime

But the native core remains:

```text
column-local latent dissolve
```

## 10. Physical execution law

`☷` must stay executable with cardboard.

That means:

- the committed column is obvious
- the latent card under it is obvious
- the burn result is visible
- the refill is visible
- the ordinary ascent after that is visible

No hidden engine-only interpretation is allowed here.

## 11. Short formula

```text
☷ DISSOLVE = in the committed column,
burn latent support before ordinary ascent.
Minor -> grave.
Trump -> trump flow.
Refill latent.
Then continue the ordinary column sequence.
```
