# Turn Sequence Law V2

Статус:

```text
canonical table law
current turn sequence
aligned with compiler/victory machine
```

Этот документ фиксирует конкретную последовательность хода
для topology-first ветки.

Он читается вместе с:

- [TURN_LAW_V2.md](./TURN_LAW_V2.md)
- [MOVE_FIT_LAW.md](./MOVE_FIT_LAW.md)
- [CARD_INFORMATION_STATE_LAW.md](./CARD_INFORMATION_STATE_LAW.md)
- [CHAIN_SURFACE_LAW.md](./CHAIN_SURFACE_LAW.md)
- [REPAIR_PHASE_LAW.md](./REPAIR_PHASE_LAW.md)
- [OPERATOR_PHASE_LAW.md](./OPERATOR_PHASE_LAW.md)
- [RESOLUTION_ORDER_LAW.md](./RESOLUTION_ORDER_LAW.md)
- [WIN_CHECK_LAW.md](./WIN_CHECK_LAW.md)

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
check victory after full closure
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
- `manifest` here means one slot of the current 6-card visible sentence

## 3. Launch law

После подтверждения ход запускается как sequence.

Базовый sequence такой:

1. committed `manifest[i]` уходит в `grave`
2. `latent[i]` становится `revealed`, если была только `hidden` или `known`
3. `latent[i] -> manifest[i]`
4. `deck top -> latent[i]` as concealed refill
5. machine enters operator phase
6. chosen operator resolves
7. if needed, repair runs again
8. played hand-card уходит в `grave`
9. victory check may occur

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

## 5. Operator phase

После первого repair machine now enters
an explicit operator phase.

That means:

1. played hand-card remains in `play`
2. player chooses exactly one operator
3. chosen operator resolves from `play`
4. if that operator reopens the board,
   repair phase runs again

Short form:

```text
world repair first
operator phase second
```

## 6. Hand-card spend timing

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

## 7. Column repair consequence

Так как commit consume-ит ровно одну manifest-card,
repair в этой модели локален по одной колонке:

```text
manifest[i] consumed
latent[i] promoted
deck refills latent[i]
```

Это делает ход:

- локальным по исполнению
- читаемым по анимации
- глобальным по влиянию на directed sentence

## 8. Refill information law

Когда `deck top` входит в `latent[i]`,
это concealed refill.

Значит карта:

- не reveal-ится предварительно
- входит в `latent` сразу как `not-revealed`
- может быть как `minor`, так и `trump`

Коротко:

```text
concealed refill enters as not-revealed
```

## 9. No re-hide consequence

Из этого следует:

Сам по себе такой concealed refill
не запускает `trump flow`,
даже если карта оказалась trump.

## 10. Relationship to observe / know

Этот документ не заменяет [OBSERVE_VS_REVEAL_LAW.md](./OBSERVE_VS_REVEAL_LAW.md)
и [CARD_INFORMATION_STATE_LAW.md](./CARD_INFORMATION_STATE_LAW.md).

Но он использует их следствия:

- `observe` по умолчанию создаёт `known`
- `reveal` создаёт `revealed`
- open deck entry reveal-ит first
- concealed deck entry кладёт directly as `not-revealed`

## 11. Victory check timing

Victory не проверяется на промежуточных состояниях sequence.

Проверка допустима только после того, как:

1. world update завершён
2. played effect разрешился
3. played hand-card уже ушла в `grave`
4. `targets` already hold a complete 3-trump compiler

Коротко:

```text
no mid-resolution victory
check only after full turn closure
```

## 12. Manifest sentence consequence

Так как `manifest` теперь является
6-slot visible sentence surface,
каждый turn sequence делает сразу две вещи:

1. local world consumption
2. rewrite of the current visible victory sentence candidate

То есть:

```text
the turn updates the world
and only then the sentence may be checked
```

## 13. What this law does not decide yet

Этот current branch пока не решает:

- full strong-move law
- exact derivation grammar for every target trio
- whether later some operators may act before world update
- whether rare trumps may alter the timing of win check

## 14. Short formula

```text
commit one manifest card
fit one hand card
send committed world-node to grave
promote latent and refill the column
enter operator phase and resolve one chosen operator
send the played card to grave
then check victory against the compiled 6-slot manifest sentence
```
