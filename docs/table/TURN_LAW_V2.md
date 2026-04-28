# Turn Law V2

Статус:

```text
canonical table law
current turn-law branch
aligned with compiler/victory machine
```

Этот документ фиксирует текущую каноническую модель хода.

Старый закон хода остаётся в:

- [../legacy/table/HAND_AND_PLAY_LAW.md](../legacy/table/HAND_AND_PLAY_LAW.md)

как предыдущая replacement-model ветка.

## 1. Core shift

Старая модель:

```text
hand card replaces manifest card
```

Новая модель:

```text
hand card is cast at manifest
hand card does not remain in manifest
```

То есть:

- `manifest / latent` = active world strip
- `hand` = action reservoir

Рука даёт не board-objects,
а operation packets.

## 2. Manifest as sentence surface

В текущей ветке `manifest chain`
надо мыслить не просто как open row,
а как:

```text
visible directed sentence surface
```

Это важно потому, что:

- ход всегда consume-ит один visible node
- victory later checks the whole visible sentence

См.:

- [CHAIN_SURFACE_LAW.md](./CHAIN_SURFACE_LAW.md)
- [WIN_CHECK_LAW.md](./WIN_CHECK_LAW.md)

## 3. Current structural sizes

Current machine branch assumes:

```text
manifest = 6 visible cards
hand = 6 cards
```

Это больше не incidental sizing,
а часть общей victory/compiler машины.

## 4. Move reading

Текущий ход в этой ветке читается так:

```text
commit one visible world-node
fit one hand card into it
let the world update
resolve one chosen operator effect
spend the played card
```

Подробная sequence-форма вынесена в:

- [TURN_SEQUENCE_LAW_V2.md](./TURN_SEQUENCE_LAW_V2.md)

## 5. Directed consequence

Так как `manifest` теперь одновременно:

- active world strip
- future victory sentence

каждый ход работает не только как local action,
но и как possible rewrite of directed visible order.

Коротко:

```text
a move changes both local world state
and future sentence possibility
```

## 6. Grave consequence

Так как:

- committed manifest-card уходит в `grave`
- played hand-card уходит в `grave`

grave в этой модели остаётся:

```text
history of opened and spent layers
```

См.:

- [GRAVE_LAW.md](./GRAVE_LAW.md)

## 7. Chain consequence

`manifest / latent` остаются самостоятельной машиной.

`hand` не подпирает `manifest`.

`manifest` восстанавливается только через:

```text
latent -> manifest
deck -> latent
```

См.:

- [CHAIN_SURFACE_LAW.md](./CHAIN_SURFACE_LAW.md)

## 8. Compiler consequence

Victory больше не живёт отдельно от хода.

Ход не обязан сам по себе проверять победу на промежуточном шаге.

Но turn-law должен быть совместим с тем, что:

```text
victory is checked after full turn closure
against the fully visible 6-slot manifest sentence
compiled by 3 target trumps
```

См.:

- [TARGET_ZONE_LAW.md](./TARGET_ZONE_LAW.md)
- [WIN_CHECK_LAW.md](./WIN_CHECK_LAW.md)

## 9. Operator consequence

Эта ветка уже опирается на новый operator layer,
а не на old weak/strong chassis.

Current read order:

- [OPERATORS_INDEX.md](./OPERATORS_INDEX.md)
- `operators/*.md`

## 10. Development consequence

С этого места проект живёт по циклу:

```text
thought
-> table
-> crystall
-> code
```

А новые rewrite-ветки теперь должны проверяться
не только against move feel,
но и against compiler/victory coherence.

## 11. What is still unresolved

Этот current branch пока не решает:

- exact final strong move law
- full derivation grammar for every compiler trio
- whether some future operator families may branch turn timing further

Но он уже фиксирует:

```text
the turn is part of one larger machine
not a free-floating local card action
```

## 12. Short formula

```text
hand cards are cast at the world
not installed into the world
manifest is a 6-slot visible sentence surface
and each turn rewrites that surface before victory is checked
```
