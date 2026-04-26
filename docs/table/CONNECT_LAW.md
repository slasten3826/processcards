# Connect Law

Статус:

```text
candidate-for-legacy table law
pending rewrite after turn-law stabilization
```

Этот документ фиксирует старую наиболее развитую ветку для `☰ CONNECT`,
собранную вокруг hand-side segment assembly.

После перехода к новой move-модели
этот документ больше не должен читаться
как безусловный current gameplay canon.

Если старые документы описывают `☰` иначе,
этот документ имеет приоритет.

Но если этот документ расходится с новой topology-first move-моделью,
приоритет уже не у него.

## 1. High-level idea

`☰` is not mainly a board-side effect.

Legacy canonical reading used to be:

```text
☰ = hand-side assembly operator
```

`☰` становится по-настоящему meaningful,
когда hand-state превращается в board-structure.

## 2. Split identity

`☰` has two modes.

### Single-card mode

If a card containing `☰` is played alone,
`☰` itself does not create an independent manifest effect.

Instead:

- the play may still be weak or strong
- the resolved payload comes from the partner operator
- if the play is strong, strong baseline still applies, including `draw 2`

Examples:

- `☰☵` alone resolves as `☵`
- `☰☴` alone resolves as `☴`
- `☰▽` alone resolves as `▽`
- `☰☳` alone resolves as `☳`

Short formula:

```text
single-card ☰ lets the partner speak
```

### Multi-card mode

When two or more cards with `☰` are committed from hand,
`☰` becomes active as a segment compiler.

Short formula:

```text
multi-card ☰ assembles a manifest segment from hand
```

## 3. Connect Segment Law

Legacy formulation:

1. Player initiates a `☰` play.
2. One or more `☰` cards are committed from hand.
3. A candidate manifest segment is assembled from hand.
4. That segment is placed into a contiguous arc of the open manifest ring.
5. Cards currently occupying those slots are sent to grave.
6. The new segment becomes the new manifest state in those slots.

Important distinction:

- the new segment is assembled from hand only
- it is not built out of existing manifest cards
- current manifest cards are replaced, not used as material

## 4. Segment size

Current canonical constraints:

- segment length may be from `1` to `5`
- length `1` may still be weak or strong depending on card and topology law
- length `2` to `5` is the natural multi-card connect form

## 5. Ring law

The open manifest row is a toroidal ring.

Valid contiguous arcs therefore include:

- `1-2`
- `4-5-1`
- `5-1-2-3`

and other ring-contiguous slices.

This is not a visual flourish.
It is part of the canonical table law.

## 6. Topology requirement

The segment created by `☰` is not arbitrary.

The assembled segment must satisfy the strong topology law of the game.

That is what keeps `☰` from becoming random multi-play.

Short formula:

```text
☰ is strong through structure, not through generic permission
```

## 7. Why this law matters

`☰` now has a distinct identity:

- single-card mode = quiet connector
- multi-card mode = hand-based compiler
- rewrites reality by replacing a contiguous manifest segment
- topology is the real constraint

So `☰` is no longer just “linking”.
It is:

```text
the operator that turns hand-state into board-structure
```

## 8. Open details

Still not fully locked:

1. exact formal wording for single-card weak/strong `☰`
2. whether every multi-card `☰` automatically counts as strong
3. whether any extra follow-up effect exists after segment installation

These questions do not overturn the old branch identity of `☰`.

## 9. Legacy relation

If older files treat `☰` as a generic local linking effect,
read those files as legacy.

This file itself is now a transition candidate:

```text
the semantic intuition may remain useful
the move chassis around it is no longer fully current
```

## 10. Short formula

```text
☰ CONNECT = hand-side assembly operator
```

machines only. not for humans.
