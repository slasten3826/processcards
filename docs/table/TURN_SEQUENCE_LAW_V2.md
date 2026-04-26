# Turn Sequence Law V2

Статус:

```text
canonical table law
current turn sequence
```

Этот документ фиксирует уже не общую интуицию новой move-модели,
а конкретную последовательность хода
для topology-first ветки.

Он читается вместе с:

- [TURN_LAW_V2.md](./TURN_LAW_V2.md)
- [MOVE_FIT_LAW.md](./MOVE_FIT_LAW.md)
- [CARD_INFORMATION_STATE_LAW.md](./CARD_INFORMATION_STATE_LAW.md)
- [CHAIN_SURFACE_LAW.md](./CHAIN_SURFACE_LAW.md)
- [RESOLUTION_ORDER_LAW.md](./RESOLUTION_ORDER_LAW.md)

## 1. Core claim

Ход в этой ветке собирается не через placement,
а через commit world-node и cast из руки.

Коротко:

```text
commit one manifest card
fit one hand card into it
consume the world node
update the world
resolve the played card
spend the played card
```

## 2. Move preparation

Перед запуском хода игрок:

1. выбирает 1 открытую карту в `manifest`
2. игра считает legal hand-cards по [MOVE_FIT_LAW.md](./MOVE_FIT_LAW.md)
3. игрок выбирает 1 legal hand-card
4. игрок подтверждает ход

Критично:

- commit всегда идёт по одной manifest-card
- выбор hand-card тоже всегда один

## 3. Launch law

После подтверждения ход запускается как sequence.

Базовый sequence такой:

1. committed `manifest[i]` уходит в `grave`
2. `latent[i]` становится `revealed`, если была только `hidden` или `known`
3. `latent[i] -> manifest[i]`
4. `deck top -> latent[i]`
5. played hand-card effect resolves
6. played hand-card уходит в `grave`

## 4. World update before effect

По умолчанию effect hand-card играет
уже **после** world update.

То есть:

```text
world updates first
card effect resolves second
```

Это default law.

Later отдельные operator families
могут явно переопределить этот timing.

## 5. Hand-card spend timing

Сыгранная карта из руки не уходит в `grave` сразу в момент выбора.

Правильный порядок такой:

1. карта выбрана
2. мир обновился
3. effect карты сыграл
4. только после этого played hand-card уходит в `grave`

Коротко:

```text
the played card acts first
then it is spent
```

## 6. Column repair consequence

Так как commit consume-ит ровно одну manifest-card,
repair в этой модели локален по одной колонке:

```text
manifest[i] consumed
latent[i] promoted
deck refills latent[i]
```

Это делает ход:

- локальным
- читаемым
- хорошо анимируемым

## 7. Refill information law

Когда `deck top` входит в `latent[i]`,
карта не должна терять уже имеющийся information state.

То есть:

- если topdeck был `hidden`, он входит в `latent` hidden
- если topdeck уже был `known`, он входит в `latent` known
- если topdeck уже был `revealed`, он входит в `latent` revealed

Коротко:

```text
refill preserves the current information state of the drawn topdeck
```

## 8. No re-hide consequence

Из этого следует:

```text
revealed cards do not re-hide just because they entered latent
known cards do not become unknown just because they entered latent
```

Это особенно важно для later trump / unveil cases.

## 9. Relationship to observe / know

Этот документ не заменяет [OBSERVE_VS_REVEAL_LAW.md](./OBSERVE_VS_REVEAL_LAW.md)
и [CARD_INFORMATION_STATE_LAW.md](./CARD_INFORMATION_STATE_LAW.md).

Но он использует их следствия:

- `observe` по умолчанию создаёт `known`
- `reveal` создаёт `revealed`
- refill не имеет права заново делать `known/revealed` карту полной `hidden`

## 10. What this law does not decide yet

Этот draft пока не решает:

- fallback action when no fit exists
- full strong-move law
- exact operator payloads
- exact trump-effect insertion into this sequence
- whether later some operators may act before world update

## 11. Short formula

```text
commit one manifest card
fit one hand card
send committed world-node to grave
promote latent and refill the column
resolve played card effect
then send the played card to grave
```
