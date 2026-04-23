# Local sources

These files are the design handoff from `slastack`.

Read enough to implement the current prototype.
Do not bulk-import the whole stack.

## Primary sources

```text
/home/slasten/Документы/stack/projects/processcards/YELLOWPRINT_v4.md
/home/slasten/Документы/stack/projects/processcards/trumps/README.md
/home/slasten/Документы/stack/projects/processcards/trumps/TRUMP_ECOLOGY.md
/home/slasten/Документы/stack/projects/processcards/trumps/RECAST.md
/home/slasten/Документы/stack/stack-core/ProcessLang/canon.lua
```

## Context sources

```text
/home/slasten/Документы/stack/projects/processcards/GAMEPLAY_LINEAGE.md
/home/slasten/Документы/stack/projects/processcards/YELLOWPRINT_v3_5.md
/home/slasten/Документы/stack/projects/processcards/YELLOWPRINT.md
```

Use context sources to understand how the design formed.
Do not treat old yellowprints as current rules when they conflict with v4.

## Priority if sources conflict

```text
canon.lua                      -> ProcessLang topology
YELLOWPRINT_v4.md              -> current board model
trumps/TRUMP_ECOLOGY.md        -> current trump ecology direction
trumps/RECAST.md               -> current RECAST behavior
this dev directory             -> local implementation notes
older yellowprints             -> history
```

## Vocabulary

The user may say `library` in conversation.
In code and docs use canonical term:

```text
deck
```

machines only. not for humans.

## Optional ProcessLang skill

Use this skill when reading, validating, or writing ProcessLang glyph traces:

```text
/home/slasten/Документы/stack/protocols/skills/processlang/SKILL.md
```

The skill helps with:

- PL glyph meanings
- adjacency validation
- state-packet reading
- PLANGOS-style structured headers when requested

The skill does not replace ProcessCards source documents.
It only helps interpret ProcessLang traces and process-state notation.
