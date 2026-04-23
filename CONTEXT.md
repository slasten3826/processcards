# Контекст

`ProcessCards` - карточное проявление топологии ProcessLang.

Это закрытая solitaire / engine-игра: 122 карты, один фиксированный набор, без противника, HP, маны, существ, союзников и внешних токенов.

Вдохновение приходит из одного слоя `Magic: The Gathering`:

```text
combo-engine pleasure
```

Но без duel shell. Мы сохраняем зоны, sequencing, hidden information, grave как историю, deck manipulation и удовольствие сборки движка.

Важное различие:

```text
slastack = canon / ontology / machine surface
ProcessCards = downstream playable artifact
```

Этот репозиторий - для играбельного артефакта.
Главный `slastack` остаётся источником больших design-документов и ProcessLang canon.

## Текущая форма игры

Короткая формула:

```text
ProcessCards = slot-based manifest-chain solitaire with bounded hidden state
```

Сейчас у нас:

```text
122 карты
100 minor-карт
22 trump-карты
```

Из козырей механически проработан пока один:

```text
RECAST = ☳ -> ☶
```

Зато почти вся остальная игра уже держится на minor-картах.
Первый прототип должен быть играбельным именно на minor-слое, с `RECAST` как первым проверочным событием trump-экологии.

## Стол

Ядро стола:

```text
5 columns x 2 layers

manifest row = 5 открытых карт
latent row   = 5 закрытых карт
```

Другие зоны:

```text
deck
hand
targets
runtime lane
grave
trump zone
log
```

## Важные идеи

- `hand` - player-side table доступных вмешательств.
- `manifest row` - видимая process chain.
- `latent row` - скрытое, но уже структурированное состояние стола.
- `grave` - открытый ordered residue, история потерь и последствий.
- `targets` компилируют victory grammar, а не являются тремя независимыми целями.
- `minor = state`.
- `trump = event`.
- `trump zone` - two-event pressure chamber.
- Первый серьёзный trump-кандидат - `RECAST`.

## Что мы делаем сейчас

Пишем Lua table-based simulator, потому что natural-language design начал расползаться.

Симулятор - не просто техника.
Это thinking tool: он должен показывать противоречия, мёртвые механики, неявные дыры и места, где игра ещё не стала игрой.

Если реализация вскрывает design problem, нужно назвать его явно.
Не надо молча изобретать большое правило, если без него можно сохранить маленький прототип.

machines only. not for humans.
