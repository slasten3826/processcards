# Next Gameplay Slice

Статус:

```text
canonical crystall contract
```

Этот документ фиксирует,
что именно мы кодим следующим слоем
в текущем `Lua + LÖVE` runtime.

## 1. Core purpose

Следующий кодовый слой —
это не “весь gameplay”.

Это:

```text
animated core replacement loop
```

То есть первый настоящий playable gesture,
собранный на уже зафиксированных zone laws.

## 2. What this slice must do

Этот слой должен дать:

1. выбор карты из `hand`
2. выбор target-slot в `manifest`
3. базовый replace-step
4. chain repair по законам `manifest/latent`
5. visible move / flip / reveal / lift / refill

Коротко:

```text
hand -> manifest replacement
plus visible chain repair
```

## 3. Included rules

В этот slice входят только следующие rule-parts:

### 3.1. Hand play skeleton

См.:

- [../table/HAND_AND_PLAY_LAW.md](../table/HAND_AND_PLAY_LAW.md)

Игрок:

1. берёт карту из `hand`
2. целит `manifest[i]`
3. target manifest card уходит в `grave`
4. card from hand занимает target slot

### 3.2. Grave reveal on entry

См.:

- [../table/GRAVE_LAW.md](../table/GRAVE_LAW.md)

Если карта уходит в `grave`,
она не должна оставаться скрытой.

### 3.3. Chain surface repair

См.:

- [../table/CHAIN_SURFACE_LAW.md](../table/CHAIN_SURFACE_LAW.md)
- [../table/RESOLUTION_ORDER_LAW.md](../table/RESOLUTION_ORDER_LAW.md)

После primary effect:

- `latent[i] -> manifest[i]`
- reveal on ascent
- `deck -> latent[i]` face-down

если для этой колонки образовалась соответствующая пустота.

### 3.4. Start Game compatibility

См.:

- [../table/DECK_AND_SETUP_LAW.md](../table/DECK_AND_SETUP_LAW.md)
- [START_GAME_FLOW.md](./START_GAME_FLOW.md)

Новый slice не заменяет `Start Game`,
а продолжается поверх уже собранной стартовой доски.

## 4. Included animation obligations

См.:

- [GAMEPLAY_ANIMATION_LAYER.md](./GAMEPLAY_ANIMATION_LAYER.md)

Для этого slice обязательны:

1. `move`
2. `flip`
3. `reveal`
4. `lift`
5. `refill`

То есть:

- `manifest -> grave` не телепортируется
- `hand -> manifest` не телепортируется
- `latent -> manifest` visibly lifts
- `deck -> latent` visibly refills

## 5. Explicitly not included

В этот slice **не входят**:

- weak legality
- strong legality
- operator payloads
- strong combined readings
- duplicate law
- target reveal gameplay
- runtime-card granted effects
- trump event resolution
- connect special mechanics
- logic special mechanics
- full turn economy

Если для реализации чего-то из этого понадобится выдумка,
значит этот кусок нужно отложить.

## 6. Lua architecture split

Следующий слой должен строиться в такой раскладке:

### A. State

Чистая игровая правда:

- cards
- zones
- face states
- deck order
- selected card / selected slot

### B. Rules

Чистые операции:

- start_game
- send_to_grave
- play_from_hand_to_manifest
- repair_chain_column
- reveal_card

### C. Animation

Presentation events:

- move
- flip
- reveal
- lift
- refill

### D. UI / input

- choose card from hand
- choose manifest slot
- trigger action

### E. Render

- draw board
- draw cards
- draw animated transitions

## 7. Why Lua matters here

Этот slice должен резаться так,
чтобы `Lua + LÖVE` оставались простыми:

- no giant engine rewrite
- no unnecessary framework layer
- no premature module explosion

Но при этом:

- rules не должны быть размазаны по draw/input
- animation не должна жить как blind teleport patch

Коротко:

```text
small modules
clear responsibilities
no mixed truth/render law
```

## 8. Definition of done

Slice считается собранным,
если:

1. после `Start Game` можно выбрать карту из `hand`
2. можно выбрать target-slot в `manifest`
3. target visibly moves to `grave`
4. played card visibly takes the manifest slot
5. chain repair visibly resolves according to law
6. no critical transition reads as teleport
7. runtime still works in current prototype shell

## 9. Short formula

```text
next we build the first real gameplay gesture:
hand card replaces manifest card
grave, lift and refill all animate visibly
everything else stays out of scope
```
