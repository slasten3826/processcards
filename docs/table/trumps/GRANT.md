[⊞ ◈] [☰ ☷]

# GRANT

## 0. Status

Working trump draft.

This is not final balance text.
This is not locked rules text.

Legacy breadcrumb:

```text
III The Empress
```

Flavor text:

```text
What is granted is briefly held.
```

Core edge:

```text
☰ -> ☷
CONNECT -> DISSOLVE
```

---

## 1. Core Identity

`GRANT` is a foundation trump.

It does not attack.
It does not draw.
It does not rewrite current board contents.

It grants temporary world-space
with a built-in return clause.

Short formula:

```text
add a wildcard column
two casts
then vanish
```

---

## 2. Reading

`☰ CONNECT` here is not assembly of existing relations.

It is formal granting:

```text
authority connects to recipient
space is issued on condition
```

`☷ DISSOLVE` here is not destruction.

It is the dissolution of the grant itself after use.

So this trump reads as:

```text
space is granted
briefly held
then withdrawn back into absence
```

This is not:

```text
growth
permanent expansion
free multiplication
```

It is temporary possibility.

---

## 3. Core Law

When `GRANT` becomes known:

1. Add one new column to the board.
2. `deck -> manifest[n]` revealed.
3. `deck -> latent[n]` hidden.
4. The granted column follows ordinary column rules,
   except `latent[n]` does not refill from deck.
5. After `GRANT` fully resolves, it follows ordinary trump ecology.

Where `n` is the next available column index above the base six.

Short formula:

```text
new column granted
manifest from deck
latent from deck
two uses before disappearance
```

---

## 4. Column Lifecycle

The granted column behaves like a normal column:

- its manifest may be targeted, committed, and cast
- when manifest is cast, latent rises as revealed manifest
- the risen card may then be targeted and cast normally

The differences:

```text
granted latent does not refill
granted column vanishes after second cast
```

So the lifecycle is:

```text
manifest occupied, latent occupied
-> alive

first cast
-> latent rises
-> latent empty
-> dying

second cast
-> no latent to rise
-> column vanishes
```

---

## 5. Multiple Grants

Multiple `GRANT` columns stack additively.

Each `GRANT` adds one live granted column
at the next available index above the base six.

Example:

```text
first GRANT  -> column 7
second GRANT -> column 8
```

If a granted column has already died,
the next `GRANT` reuses the lowest available index above 6.

This keeps live granted space dense
instead of leaving dead gaps.

---

## 6. Victory Interaction

Granted columns participate in victory check
as wildcard positions.

While a granted column is alive:

- its revealed manifest may satisfy a required symbol
- it does not need to preserve the normal fixed manifest slot order

This is the key law.

Ordinary manifest slots remain:

```text
order-bound
```

Granted slots are:

```text
order-free wildcard positions
```

So `GRANT` does not merely add space.
It locally softens the rigidity of the victory compiler.

Short formula:

```text
ordinary slots preserve order
grant slots forgive order
```

---

## 7. Six-Of-N Victory Law

If granted columns are alive,
victory check no longer means:

```text
the visible six fixed manifest slots
must match directly
```

Instead:

```text
choose any six satisfiable positions
from the currently available manifest columns
```

with the following distinction:

- ordinary manifest columns keep their left-to-right order relation
- granted columns may satisfy missing required symbols without preserving global slot order

In the limit:

```text
the more live GRANT columns exist,
the less strict manifest order becomes
```

If enough granted columns exist,
order may cease to matter entirely for the winning subset.

This is intentional.

---

## 8. Auto-Check Recommendation

Because `GRANT` introduces wildcard geometry,
manual victory inspection becomes annoying quickly.

Recommended UX:

```text
before victory check,
engine tests all legal six-of-n winning subsets automatically
and surfaces a valid match if one exists
```

This keeps `GRANT` a structural gift,
not a combinatorial bookkeeping tax.

---

## 9. Circle Interaction

Granted columns are subject to ordinary circle corruption.

All floor laws that act on live manifest or latent columns
may affect granted columns too.

Important case:

```text
Circle 3 Cerberus consumes granted latent too
```

So a granted column may become single-use
if its latent is eaten before the first manifest cast.

This is good.

The grant is not sacred.
It survives only if the floor lets it survive.

---

## 10. Why This Works

`GRANT` does not create force.

It creates temporary possibility
and relaxes compiler rigidity for a short time.

That makes it:

- foundational
- quiet
- structural
- not immediately profitable
- dangerous when victory is close
- more topological than economic

It should feel like:

```text
a brief wildcard opening
```

Not like:

```text
free value
permanent growth
board domination
```

---

## 11. Relation to Trump Ecology

`GRANT` does not invent a separate ecology.

It uses:

- ordinary known-state trigger
- ordinary ordered resolution
- ordinary chain close handling
- ordinary trump-zone law after its own resolution

Its specificity is not in ecology.
Its specificity is in:

- temporary extra column geometry
- wildcard victory participation
- built-in disappearance

---

## 12. Minimal Canonical Text

Draft rules text:

```text
Add a new manifest/latent column to the board.
Deck one card into its manifest revealed.
Deck one card into its latent hidden.
The granted column follows ordinary rules, but its latent does not refill from deck.
After both granted cards are played, the column vanishes.
While a granted column is alive, victory check may use its revealed manifest as a wildcard position that does not preserve normal slot order.
After GRANT fully resolves, it follows ordinary trump ecology.
```

---

machines only. not for humans.
