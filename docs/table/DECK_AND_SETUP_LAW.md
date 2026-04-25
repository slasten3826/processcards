# Deck And Setup Law

Статус:

```text
canonical table law
```

Этот документ фиксирует:

- полный размер колоды
- временную naming-схему карт
- стартовую раскладку партии

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

## 3. Start game setup

При старте новой партии:

1. собрать отдельную `minor deck` из `100` minor cards
2. выполнить `shuffle` minor deck
3. выполнить minor-only opening
4. затем вмешать `22` trump cards
5. выполнить второй `shuffle`
6. только после этого достроить hidden opening

## 4. Two-phase setup

### Phase A: minor-only bootstrap

Используется только `100` minor cards.

Порядок:

#### Manifest

- `manifest[1..5]` <- 5 cards face-up

#### Hand

- `hand` <- 5 cards

После этой фазы:

- `manifest` гарантированно minor-only
- `hand` гарантированно minor-only
- в minor deck остаётся `90` cards

### Phase B: full deck completion

После Phase A:

1. взять оставшиеся `90` minor cards
2. добавить к ним `22` trump cards
3. выполнить `shuffle`
4. из полученной колоды разложить hidden layers

#### Targets

- `targets[1]` <- 1 card face-down
- `targets[2]` <- 1 card face-down
- `targets[3]` <- 1 card face-down

#### Latent

- `latent[1..5]` <- 5 cards face-down

## 5. Why this law exists

Этот setup-law нужен, чтобы:

- `manifest` стартовал как `state surface`
- `hand` стартовала как `minor-only intervention surface`
- trump cards не прорывались в открытый стартовый chain
- hidden layers уже могли нести trump potential

Коротко:

```text
open opening = minors only
hidden opening = full deck allowed
```

## 6. Deck remainder after setup

Во время setup из колоды выходят:

- `5` cards to manifest
- `5` cards to hand
- `3` cards to targets
- `5` cards to latent

Итого:

```text
18 cards leave the deck during setup
```

Математика по фазам:

### After Phase A

- `100 minor`
- `10` removed to manifest + hand
- `90 minor remain`

### After Phase B merge

- `90 minor + 22 trump = 112`

### After hidden dealing

- `8` removed to targets + latent

Остаётся в финальной deck:

```text
104 cards in deck
```

## 7. Zone state after setup

После `Start Game`:

- `targets` = 3 hidden cards from full merged deck
- `manifest` = 5 visible minor cards
- `latent` = 5 hidden cards from full merged deck
- `hand` = 5 minor cards
- `runtime` = empty
- `grave` = empty
- `trump zone` = empty
- `deck` = 104 cards

## 8. What this law does not decide

Этот документ пока не решает:

- mulligan
- redraw
- trump behavior after setup
- target semantics
- weak/strong legality after setup
- whether hidden targets/latent should later filter trumps further

Он решает только:

```text
what a new game physically looks like right after Start Game
```

## 9. Short formula

```text
100 minors shuffle
5 open manifest
5 hand
then add 22 trumps
shuffle again
3 hidden targets
5 hidden latent
104 remain in deck
```
