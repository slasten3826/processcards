# Локальные источники

Эти файлы - design handoff из `slastack`.

Читать достаточно, чтобы реализовать текущий прототип.
Не импортировать весь stack в этот репозиторий.

## Primary sources

```text
/home/slasten/Документы/stack/projects/processcards/YELLOWPRINT_v4.md
/home/slasten/Документы/stack/projects/processcards/TARGET_COMPILER_v1.md
/home/slasten/Документы/stack/projects/processcards/trumps/README.md
/home/slasten/Документы/stack/projects/processcards/trumps/TRUMP_ECOLOGY.md
/home/slasten/Документы/stack/projects/processcards/trumps/TRUMP_RESOLUTION_ORDER.md
/home/slasten/Документы/stack/projects/processcards/trumps/RECAST.md
/home/slasten/Документы/stack/projects/processcards/trumps/SHUFFLE.md
/home/slasten/Документы/stack/projects/processcards/trumps/EJECT.md
/home/slasten/Документы/stack/stack-core/ProcessLang/canon.lua
```

## Context sources

```text
/home/slasten/Документы/stack/projects/processcards/README.md
/home/slasten/Документы/stack/projects/processcards/GAMEPLAY_LINEAGE.md
/home/slasten/Документы/stack/projects/processcards/YELLOWPRINT_v3_5.md
/home/slasten/Документы/stack/projects/processcards/YELLOWPRINT.md
```

Context sources нужны, чтобы понимать путь идеи.
Старые yellowprints не считать текущими rules, если они конфликтуют с v4.

## Priority if sources conflict

```text
canon.lua                      -> ProcessLang topology
YELLOWPRINT_v4.md              -> current board model
TARGET_COMPILER_v1.md          -> current target compiler law
trumps/TRUMP_ECOLOGY.md        -> current trump ecology direction
trumps/TRUMP_RESOLUTION_ORDER.md -> global trump ordering law
trumps/RECAST.md               -> current RECAST behavior
trumps/SHUFFLE.md              -> circulation trump draft
trumps/EJECT.md                -> precision extraction trump draft
this dev directory             -> local implementation notes
older yellowprints             -> history
```

## Upstream mirror inside repo

Чтобы не зависеть от внешней папки каждый раз при чтении,
мы держим локальную зеркальную копию актуальных upstream docs здесь:

```text
docs/chaos/upstream/processcards/
```

Это mirror design sources, а не независимая ветка правил.

Если upstream-док обновился, а mirror ещё нет, приоритет такой:

```text
оригинал в /home/slasten/Документы/... -> первичен
docs/chaos/upstream/processcards/      -> локальная зафиксированная копия
наши handoff docs                      -> рабочая интерпретация для реализации
```

## Vocabulary

Пользователь может говорить `library`.
В коде и документации использовать canonical term:

```text
deck
```

Документацию репозитория вести на русском.
Термины зон в коде оставлять стабильными: `deck`, `hand`, `grave`, `manifest`, `latent`, `targets`, `runtime`, `trump_zone`.

## Хроника

Историю идеи вести отдельно:

```text
docs/chaos/LEGEND.md
```

Это не rulesheet.
Это летопись/легенда/сказка о том, каким путём идея прошла.

Важно сохранять хронологию:

- что было раньше;
- что изменилось;
- почему старое решение перестало подходить;
- какой слой появился следующим;
- какие tension points привели к новому правилу.

Стиль может быть свободным.
Факт хронологии важнее строгой формы.

## Optional ProcessLang skill

Использовать этот skill при чтении, валидации или записи ProcessLang glyph traces:

```text
/home/slasten/Документы/stack/protocols/skills/processlang/SKILL.md
```

Skill помогает с:

- PL glyph meanings;
- adjacency validation;
- state-packet reading;
- PLANGOS-style structured headers when requested.

Skill не заменяет ProcessCards source documents.
Он только помогает интерпретировать ProcessLang traces и process-state notation.

machines only. not for humans.
