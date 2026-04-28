# Next Gameplay Slice V2

Статус:

```text
canonical crystall contract
current turn-law branch
pending sync with compiler/victory implementation layer
```

Этот документ фиксирует,
что именно мы теперь кодим
после смены базовой move-модели.

Старый документ:

- [../legacy/crystall/NEXT_GAMEPLAY_SLICE.md](../legacy/crystall/NEXT_GAMEPLAY_SLICE.md)

остаётся полезным как предыдущий crystall-slice
для replacement-модели.

Новый slice опирается уже на:

- [../table/TURN_LAW_V2.md](../table/TURN_LAW_V2.md)
- [../table/MOVE_FIT_LAW.md](../table/MOVE_FIT_LAW.md)
- [../table/TURN_SEQUENCE_LAW_V2.md](../table/TURN_SEQUENCE_LAW_V2.md)

## 1. Core purpose

Следующий кодовый слой —
это первый playable slice
для новой move-модели:

```text
commit manifest card
check full-fit from hand
resolve cast against world strip
```

Коротко:

```text
topology-first move prototype
```

Но теперь этот slice уже существует
внутри larger machine,
где:

- `manifest` = 6 visible slots
- `targets` = compiler zone
- victory is checked after full turn closure

## 2. What this slice must do

Этот slice должен дать:

1. выбор 1 открытой карты в `manifest[1..6]`
2. её временный `commit / tap` как source of move
3. подсветку / определение legal hand-cards по `MOVE_FIT_LAW`
4. выбор 1 legal hand-card
5. подтверждение хода через control `△`
6. committed manifest-card уходит в `grave`
7. `latent[i] -> manifest[i]`
8. `deck -> latent[i]`
9. hand-card effect resolves after world update by default
10. played hand-card уходит в `grave` after effect
11. refill preserves current known / revealed state of topdeck
12. post-resolution victory check may be called against compiled target state

## 3. Included rules

В этот slice входят:

- [../table/MOVE_FIT_LAW.md](../table/MOVE_FIT_LAW.md)
- [../table/TURN_LAW_V2.md](../table/TURN_LAW_V2.md)
- [../table/CHAIN_SURFACE_LAW.md](../table/CHAIN_SURFACE_LAW.md)
- [../table/RESOLUTION_ORDER_LAW.md](../table/RESOLUTION_ORDER_LAW.md)
- [../table/GRAVE_LAW.md](../table/GRAVE_LAW.md)
- [../table/CARD_INFORMATION_STATE_LAW.md](../table/CARD_INFORMATION_STATE_LAW.md)
- [../table/TURN_SEQUENCE_LAW_V2.md](../table/TURN_SEQUENCE_LAW_V2.md)
- [../table/WIN_CHECK_LAW.md](../table/WIN_CHECK_LAW.md)

То есть:

- committed manifest-card = источник topology gate
- hand-card must fully close against it
- no orphan operator allowed
- chain repair remains structural truth
- world update precedes played-card effect by default
- refill does not re-hide known/revealed topdeck
- victory is checked only after full turn closure

## 4. First implementation simplification

Для первого coding pass здесь допустимо упростить:

```text
legal fit first
full operator payload later
```

То есть сначала можно честно собрать:

1. commit manifest
2. show legal / illegal hand cards
3. allow only legal hand-card cast
4. animate world-strip consumption and repair

А уже после этого наслаивать
реальные operator effects.

Но больше нельзя игнорировать,
что `manifest` lives inside a 6-slot victory sentence surface.

## 5. Included animation obligations

См.:

- [GAMEPLAY_ANIMATION_LAYER.md](./GAMEPLAY_ANIMATION_LAYER.md)

Для этой ветки обязательны:

1. manifest commit/tap visual mark
2. committed manifest card -> grave
3. latent lift
4. latent refill
5. hand-card discharge to grave
6. later optional known-state ghost overlay on latent refill
7. confirm control is expressed as glyph `△`, not text button
8. if victory check exists in this slice,
   it must happen only after played-card discharge

Критично:

```text
the move must read as world consumption
not as card teleport bookkeeping
```

## 6. Explicitly not included

В этот slice пока не входят:

- полный новый weak/strong law
- fallback action if no fit exists
- full trump event engine
- runtime granted effect draft
- final operator reinterpretation
- final card text rewrite

At this stage compiler grammar may still stay simplified,
but the slice must not contradict the existence of compiler-driven victory.

## 7. Lua architecture split

Этот slice желательно резать так:

### A. Commit state

- which manifest slot is committed
- whether move is awaiting hand-card choice

### B. Fit check

- function that tests full pair fit
- legal hand-card query for one committed manifest-card

### C. Move resolution

- consume committed manifest card
- repair column
- resolve hand-card payload
- discharge hand-card
- if compiler complete, run win check after discharge

### D. Animation

- commit highlight
- grave move
- lift
- refill
- hand-card discharge

## 8. Definition of done

Slice считается собранным,
если:

1. игрок может commit-ить 1 manifest-card
2. игра может определить,
   какие hand-cards legal against this commit
3. illegal hand-cards не разыгрываются
4. legal hand-card может быть сыграна
5. committed world-node visibly consumed
6. column visibly repaired
7. hand-card effect resolves after repair by default
8. hand-card visibly discharged
9. no mid-resolution victory check occurs

## 9. Short formula

```text
next we code the first topology-first move:
commit one manifest card
fit one hand card into it
consume the world node
repair the column
discharge the played card
then optionally check compiled victory
```
