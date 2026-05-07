[⊞ ◈] [☳ ☶]

# RECAST

## 0. Status

Clarified trump-event draft.

This is not final balance text.
This is not locked card wording.
This is a mechanical clarification draft.

Legacy breadcrumb:

```text
XII The Hanged Man
```

Edge:

```text
☳ -> ☶
CHOOSE -> LOGIC
```

Primary short name:

```text
RECAST
```

Flavor text:

```text
System rewritten. Context inverted.
```

## 1. Core Reading

`☳ CHOOSE` does not resolve as free choice.

It is suspended,
then forced through `☶ LOGIC`
as structural reinterpretation.

Short reading:

```text
choice suspended into structural reinterpretation
```

This event does not grant value.
It rewrites the relation between:

- current visible board
- current hidden underside
- current hand as intervention surface

## 2. Terms

`manifest chain` is the full `2×6` table:

- 6 face-up cards = manifest row
- 6 face-down cards = latent row

For this event,
only the face-up row is first removed directly.

The latent row is then promoted into the new visible row.

Temporary zone used by this event:

```text
proto-hand
```

`proto-hand` is not normal hand.
It is a temporary holding zone for the old visible row.

## 3. Trigger

When this trump becomes known,
resolve it immediately as an event.

Possible known-states include:

- drawn into hand
- observed in latent row
- revealed from target compiler
- manifested from hidden state
- otherwise exposed by card effect

## 4. Clarified Effect

On reveal / become known:

1. Move all six cards from the current face-up manifest row into `proto-hand`.
2. Reveal all six cards in the current latent row.
3. Those six revealed latent cards become the new face-up manifest row.
4. Shuffle the player's current hand.
5. Deal six cards from that shuffled hand face-down into the latent row.
6. If the shuffled hand contains fewer than six cards,
   fill the remaining latent slots from deck face-down.
7. Reveal all remaining cards from the shuffled hand one by one.
8. Put those revealed cards into grave in reveal order.
9. Move all cards in `proto-hand` into the player's hand.
10. After this event fully resolves,
    move this trump to `trump zone`.
11. If `trump zone` already contains two trumps,
    shuffle deck, those two trumps,
    and this trump into deck instead.

## 5. Resulting State

After resolution:

- manifest row = former latent row
- latent row = 6 cards from old hand, with deck refill if needed
- grave = old hand overflow in reveal order
- hand = former visible manifest row
- trump = `trump zone`, unless it triggers trump reset

Short zone formula:

```text
manifest -> proto-hand -> hand
latent -> manifest
old hand -> latent
old hand overflow -> grave
trump -> trump zone
third trump -> deck reset
```

## 6. Why This Works

This event preserves the board invariant:

```text
6 manifest slots
6 latent slots
runtime capacity = 1
ordered grave
```

It does not require:

- tokens
- counters
- external markers
- extra non-card resources

It uses only existing ProcessCards materials:

- visibility
- zone transfer
- order
- grave residue
- latent / manifest inversion
- trump zone as two-event pressure chamber

## 7. Hand Reading

`RECAST` should not be used as proof that hand must be globally capped.

This event already normalizes itself.
It does not need a universal hand limit to complete.

What matters is not hand cap,
but valid post-resolve structure.

This event succeeds because it always returns the game to a closed state:

- visible row restored
- hidden row restored
- old visible row inherited as new hand
- surplus written into grave

So the hand here behaves not as “cards you keep safe”,
but as:

```text
intervention surface
```

`RECAST` temporarily recodes that intervention surface
into hidden future structure,
then inherits the old visible world back as the new hand.

## 8. Grave Residue

The grave step is load-bearing.

The event does not simply discard excess.
It writes the history of inversion into ordered grave:

```text
surplus becomes residue in reveal order
```

This makes grave meaningful as:

- loss archive
- memory trace
- inversion residue
- ordered aftermath

## 9. Boundaries

`RECAST` affects:

- manifest row
- latent row
- hand
- deck
- grave
- trump zone

`RECAST` does not affect by default:

- target compiler
- runtime lane

This keeps the event local to the manifest-chain machine,
with only the standard trump-zone after-resolve handling.

## 10. Legacy Breadcrumb

Early design notes referred to this event through the tarot-like image:

```text
XII Повешенный
```

This is legacy breadcrumb only.

Canonical ProcessCards name:

```text
RECAST
```

## 11. Short Formula

```text
RECAST = old visible world becomes hand, hidden world becomes visible, old hand becomes new hidden underside, surplus is written into grave, trump becomes event residue
```

Even shorter:

```text
visible is suspended
hidden becomes manifest
intervention becomes latent fate
surplus becomes residue
trump becomes event count
```

---

machines only. not for humans.
