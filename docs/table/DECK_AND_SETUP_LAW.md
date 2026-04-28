# Deck And Setup Law

Статус:

```text
canonical table law
aligned with current victory/compiler branch
```

Этот документ фиксирует:

- полный размер колоды
- временную naming-схему карт
- стартовую раскладку партии
- стартовые размеры `manifest` и `hand`

## 1. Full deck size

Полная колода `ProcessCards` состоит из:

```text
122 cards
```

Разделение:

- `100` minor cards
- `22` trump cards

## 2. Temporary naming law

Пока финальные имена карт ещё не собраны,
временная маркировка допустима такая:

### Trumps

```text
TRUMP-1
TRUMP-2
...
TRUMP-22
```

### Minors

```text
MINOR-1
MINOR-2
...
MINOR-100
```

## 3. Core structural sizes

Current machine branch assumes:

```text
manifest chain = 6
hand = 6
target zone = 3 slots
```

Это согласовано с:

- [TURN_LAW_V2.md](./TURN_LAW_V2.md)
- [WIN_CHECK_LAW.md](./WIN_CHECK_LAW.md)

Short formula:

```text
3 target trumps compile a 6-slot victory sentence
so manifest must expose 6 visible positions
```

## 4. Start game setup

При старте новой партии:

1. собрать отдельную `minor deck` из `100` minor cards
2. выполнить `shuffle` minor deck
3. выполнить minor-only opening
4. затем вмешать `22` trump cards
5. выполнить второй `shuffle`
6. только после этого достроить hidden opening

## 5. Two-phase setup

### Phase A: minor-only bootstrap

Используется только `100` minor cards.

Порядок:

#### Manifest

- `manifest[1..6]` <- 6 cards face-up

#### Hand

- `hand` <- 6 cards

После этой фазы:

- `manifest` гарантированно minor-only
- `hand` гарантированно minor-only
- в minor deck остаётся `88` cards

### Phase B: full deck completion

После Phase A:

1. взять оставшиеся `88` minor cards
2. добавить к ним `22` trump cards
3. выполнить `shuffle`
4. из полученной колоды разложить hidden layers

#### Targets

- `targets[1]` <- 1 card face-down
- `targets[2]` <- 1 card face-down
- `targets[3]` <- 1 card face-down

#### Latent

- `latent[1..6]` <- 6 cards face-down

## 6. Why this law exists

Этот setup-law нужен, чтобы:

- `manifest` стартовал как `6-slot visible sentence surface`
- `hand` стартовала как `minor-only intervention surface`
- trump cards не прорывались в открытый стартовый chain
- hidden layers уже могли нести trump potential
- `targets` уже существовали как hidden compiler shell

Коротко:

```text
open opening = minors only
hidden opening = full deck allowed
compiler shell exists from the start
```

## 7. Deck remainder after setup

Во время setup из колоды выходят:

- `6` cards to manifest
- `6` cards to hand
- `3` cards to targets
- `6` cards to latent

Итого:

```text
21 cards leave the deck during setup
```

Математика по фазам:

### After Phase A

- `100 minor`
- `12` removed to manifest + hand
- `88 minor remain`

### After Phase B merge

- `88 minor + 22 trump = 110`

### After hidden dealing

- `9` removed to targets + latent

Остаётся в финальной deck:

```text
101 cards in deck
```

## 8. Zone state after setup

После `Start Game`:

- `targets` = 3 hidden cards from full merged deck
- `manifest` = 6 visible minor cards
- `latent` = 6 hidden cards from full merged deck
- `hand` = 6 minor cards
- `runtime` = empty
- `grave` = empty
- `trump zone` = empty
- `deck` = 101 cards

## 9. Compiler consequence

На старте партии `targets` ещё не обязаны содержать 3 trumps.

Значит:

- compiler shell already exists
- full victory pattern may still not exist yet
- victory check starts only after target compilation becomes complete

См.:

- [TARGET_ZONE_LAW.md](./TARGET_ZONE_LAW.md)
- [WIN_CHECK_LAW.md](./WIN_CHECK_LAW.md)

## 10. What this law does not decide

Этот документ пока не решает:

- mulligan
- redraw
- exact probability shaping of target compilation
- trump behavior after setup
- full win-grammar derivation

Он решает только:

```text
what a new game physically looks like right after Start Game
```

## 11. Short formula

```text
100 minors shuffle
6 open manifest
6 hand
then add 22 trumps
shuffle again
3 hidden targets
6 hidden latent
101 remain in deck
```
