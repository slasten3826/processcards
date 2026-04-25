# Platform Requirements

Статус:

```text
canonical crystall constraint
```

Этот документ фиксирует требования к первой целевой платформе и interaction baseline.

## 1. Baseline resolution

Первый обязательный target resolution:

```text
1280x720
```

Это baseline,
а не optional mode.

Если стол не собирается в `720p`,
значит UI ещё не готов.

## 2. Primary platforms

Current primary targets:

- `PC`
- `hacked Switch`

Это и есть основная целевая связка первого runtime surface.

## 3. Secondary / optional targets

Optional later targets:

- browser build
- higher desktop resolutions like `1080p+`

Важно:

```text
browser is desirable
but not primary
```

## 4. Input requirements

Игра должна быть playable через:

- buttons
- mouse
- touch

Это жёсткое требование.

Нельзя строить core loop как mouse-only interaction.

## 5. Interaction baseline

Базовая модель взаимодействия:

```text
selection-first
```

То есть игрок должен уметь:

- выбрать карту
- выбрать цель / зону / слот
- подтвердить действие

без необходимости точного desktop drag-only UX.

## 6. Drag and drop

Drag/drop допустим,
но только как:

```text
enhancement layer
```

not as:

```text
the only playable interaction model
```

Это особенно важно для:

- buttons
- Switch
- touch

## 7. Layout constraint

Board must stay readable and playable in `720p`.

Это означает:

- stable zone hierarchy
- no critical overflow
- no tiny unreadable slots
- no dependence on ultra-wide desktop space

## 8. Resolution scaling

`1080p+` и выше считаются:

```text
optional upscale targets
```

То есть:

- baseline собирается под `720p`
- higher resolutions only expand or refine it
- they must not define the original layout law

## 9. Architecture consequence

These requirements imply:

- portable-friendly UI
- input abstraction layer
- no hover-only critical actions
- no desktop-only assumptions in board engine

## 10. Current rule

When a UI/system choice is made,
it should be checked against:

```text
does this still work in 720p
on Switch-like input
without mouse precision
```

## 11. Short formula

```text
first build targets 720p, PC, hacked Switch,
with buttons/mouse/touch all treated as real inputs
```
