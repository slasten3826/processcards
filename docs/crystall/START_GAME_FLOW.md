# Start Game Flow

Статус:

```text
canonical crystall contract
```

Этот документ фиксирует,
что должна делать кнопка:

```text
Start Game
```

Table source of truth:

- [../table/DECK_AND_SETUP_LAW.md](../table/DECK_AND_SETUP_LAW.md)

## 1. Purpose

`Start Game` должен:

- очистить текущую доску
- собрать полную колоду
- перемешать её
- выполнить стартовую раскладку

Это уже не просто technical reset dev-table.
Это переход от пустого skeleton к реальному game setup.

## 2. Source deck

При `Start Game` runtime создаёт:

```text
122 cards
```

С временными id:

- `MINOR-1 .. MINOR-100`
- `TRUMP-1 .. TRUMP-22`

## 3. Runtime sequence

При нажатии `Start Game`:

1. clear current board state
2. rebuild `100` minor cards
3. shuffle minor deck
4. deal minor-only opening
5. merge in `22` trump cards
6. shuffle merged deck
7. deal hidden opening layers

Strict order:

### Phase A

1. `manifest[1..5]` face-up from minor deck
2. `hand` gets 5 cards from minor deck

### Phase B

3. add `22` trump cards to remaining minor deck
4. shuffle merged deck
5. `targets[1]` face-down
6. `targets[2]` face-down
7. `targets[3]` face-down
8. `latent[1..5]` face-down

## 4. Resulting runtime state

После успешного `Start Game` runtime должен показать:

- `targets` full with 3 hidden cards
- `manifest` full with 5 visible minor cards
- `latent` full with 5 hidden cards
- `hand` with 5 minor cards
- `deck` with `104` remaining cards
- empty `runtime`
- empty `grave`
- empty `trump zone`

## 5. Relation to dev mode

На ближайшем слое `Start Game` не отменяет `dev mode`.

То есть после setup
игрок всё ещё может вручную двигать карты,
если runtime остаётся в:

```text
dev mode
```

Это допустимо,
пока normal mode ещё не введён.

## 6. UI contract

В runtime должен быть явный control:

```text
Start Game
```

Он может:

- жить как отдельная кнопка
- жить рядом с `Reset`
- later заменить `Reset`, если семантика будет разделена иначе

Но пока difference must stay clear:

- `Reset` = technical rebuild / clear surface
- `Start Game` = build shuffled opening board from full deck

## 7. What this contract does not require yet

Этот документ пока не требует:

- normal mode
- weak/strong legality after setup
- target victory logic
- trump gameplay

## 8. Short formula

```text
Start Game = clear board
build 100-minor opening
shuffle
deal 5 open manifest
deal 5 hand
add 22 trumps
shuffle again
deal 3 hidden targets
deal 5 hidden latent
leave 104 in deck
```
