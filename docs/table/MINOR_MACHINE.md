# Minor Machine

Это table-документ о первой рабочей машине на 100 minor-карт.

Статус:

```text
legacy core-loop draft
```

Он фиксирует именно core gameplay первого playable слоя.

Не весь `ProcessCards`.
Не полный rulesheet.
А первую честную minor-only machine.

Важно:

- этот документ остаётся полезным как loop draft;
- но если он расходится с newer canonical operator docs,
  приоритет у:
  - [OPERATOR_MODEL.md](./OPERATOR_MODEL.md)
  - [CONNECT_LAW.md](./CONNECT_LAW.md)
  - [STRONG_COMBINED_LAW.md](./STRONG_COMBINED_LAW.md)
  - [STRONG_PAIR_TABLE.md](./STRONG_PAIR_TABLE.md)

## 1. Core claim

Первый playable слой игры работает через:

```text
open manifest chain
```

Игрок делает ходы только в открытый `manifest row`.

Это и есть текущий core gameplay.

## 2. Board model

На столе есть:

- `deck`
- `hand`
- `manifest row`
- `latent row`
- `targets`
- `runtime lane`
- `grave`
- `log`

Ядро board:

```text
5 columns x 2 layers
```

Но в первом playable loop активной поверхностью хода является только:

```text
manifest row
```

## 3. Manifest chain

`Manifest chain` = 5 открытых карт в ряд.

Игрок всегда целит одну из этих открытых карт.

Это важно:

- weak target = manifest only;
- strong target = manifest only;
- discard target = hand only;
- pass target = no target.

Нельзя делать обычный ход в latent,
потому что latent hidden by default.

## 4. Latent row in first prototype

Latent row уже существует как часть board model,
но пока не участвует напрямую в core loop.

Текущее правило:

- latent физически лежит на столе;
- latent скрыт;
- latent нельзя целить обычным weak/strong move;
- weak/strong не поднимают latent автоматически;
- replacement в manifest не триггерит latent promotion.

Это важно считать временным ограничением первого playable слоя,
а не финальной истиной всей игры.

## 5. Weak topology

Слабая топология работает как `UNO`-подобное совпадение.

Weak legal, если между картой из руки и целевой картой в manifest есть:

```text
same number
OR
same suit
```

Здесь:

- `number` = позиция 1-10;
- `suit` = glyph-operator на карте.

В первом playable прототипе weak topology не использует cross-position matching.

То есть:

```text
number_A == number_B
or
suit_A == suit_B
```

и только это.

Важно:

это topology закона хода,
а не полная модель effect reading карты.

## 6. Strong topology

Сильная топология берётся из:

```text
/home/slasten/Документы/stack/stack-core/ProcessLang/canon.lua
```

Strong legal, если переход между картой из руки и целевой картой в manifest topology-valid по canon.

Рабочая формула первого прототипа:

```text
canon adjacency decides strong legality
```

Точная helper-function фиксируется уже в crystall.

## 7. Weak move procedure

Weak move работает так:

1. Игрок выбирает карту из `hand`.
2. Игрок выбирает одну открытую карту в `manifest row`.
3. Проверяется weak legality.
4. Если weak legal:
   - targeted manifest card goes to `grave`;
   - chosen hand card goes into the freed manifest slot;
   - player resolves 1 effect of the played card;
   - draw 0.

Short formula:

```text
weak = replace targeted manifest card + 1 card effect
```

## 8. Strong move procedure

Strong move работает так:

1. Игрок выбирает карту из `hand`.
2. Игрок выбирает одну открытую карту в `manifest row`.
3. Проверяется strong legality.
4. Если strong legal:
   - targeted manifest card goes to `grave`;
   - chosen hand card goes into the freed manifest slot;
   - player draws 2;
   - player resolves one strong combined reading of the played pair.

Short formula:

```text
strong = replace targeted manifest card + draw 2 + combined pair reading
```

Deprecated wording:

```text
strong = draw 2 + 1-2 effects
```

This older formula should now be read only as a legacy draft,
not as current canon.

## 9. Discard

Discard работает так:

1. Игрок выбирает карту из `hand`.
2. Карта уходит в `grave`.
3. Draw 0.

Discard не должен становиться бесплатным фильтром.

## 10. Pass

Pass legal,
но tempo-negative.

Если pass становится частым,
значит minor machine не создаёт достаточного давления.

## 11. Grave

`Grave` в первой машине:

- open;
- ordered;
- public;
- пополняется сверху новыми картами.

Целевая карта из manifest при weak/strong уходит именно туда.

## 12. Runtime lane

`Runtime lane` существует на столе,
но в первом playable loop может оставаться пассивным surface.

Если он ещё не включён в ходовую механику,
это нормально.
Но capacity = 1 нужно удерживать как structural law.

## 13. Target zone

`Targets` существуют как surface и будущий compiler.

Но в первой minor machine:

- они не являются surface обычного хода;
- не должны мешать собрать core manifest gameplay;
- могут быть пока просто скрытым блоком из 3 ordered slots.

## 14. Physical-card reading

Все действия minor machine должны быть физически исполнимы на реальных картах.

Это значит:

- игрок видит только открытый manifest;
- игрок не знает latent автоматически;
- игрок может вручную заменить открытую карту другой картой из руки;
- игрок может положить старую карту в grave;
- игрок может добрать карты из deck.

Прототип может подсветить legal target,
но не должен подменять собой физическую процедуру игры.

## 15. Card effect reading

Minor-карта в первом prototype имеет два operator layers.

Но важно различать:

- physical card identity;
- effect reading of the card.

Физически:

```text
☵☳ and ☳☵ are different cards in deck
```

Effect-wise:

```text
weak reads one operator
strong reads the pair as one combined meaning
```

Important layer note:

- the first playable machine still targets only open manifest for ordinary moves;
- some strong pair meanings already documented in `STRONG_PAIR_TABLE.md`
  may reach beyond first-playable scope;
- that future canon does not automatically become prototype-legal now.

Но по effect family:

```text
☵☳ and ☳☵ can read as the same operator family
```

То есть для first prototype:

```text
physical order may remain
effect order does not need to matter
```

Подробнее это фиксируется в:

```text
docs/table/CARD_EFFECT_MODEL.md
```
## 16. Example weak move

Example:

```text
manifest: 10▽ 7▽ 7☶ 9☶ 8☷
hand:     2☰ 8☰ 1☷ 10☰ 8☳
```

Игрок выбирает `1☷` из руки и целит `8☷`.

Совпадение по suit `☷` делает ход weak-legal.

Результат:

- `8☷` -> grave
- `1☷` -> target manifest slot

## 17. Example strong move

Example:

```text
manifest: 10▽ 7▽ 7☶ 9☶ 8☷
hand:     2☰ 8☰ 1☷ 10☰ 8☳
```

Игрок выбирает `8☰` из руки и целит `7▽`.

Если canon topology подтверждает strong legality,
то результат такой:

- `7▽` -> grave
- `8☰` -> target manifest slot
- draw 2
- resolve 1-2 effects of `8☰`

## 18. Short formula

```text
minor machine = choose hand card, target open manifest card, replace it, then resolve weak or strong card reading
```

machines only. not for humans.
