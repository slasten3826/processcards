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

Козыри как design layer уже существуют в документах,
но первый настоящий playable prototype теперь намеренно ограничен:

```text
рабочая машина на 100 minor-карт
```

То есть trump-layer не входит в первый playable scope.
Сначала minor-loop должен стать реальной игрой сам по себе.

## Стол

Ядро стола:

```text
5 columns x 2 layers

manifest row = 5 открытых карт
latent row   = 5 закрытых карт
```

Другие зоны первого playable слоя:

```text
deck
hand
targets
runtime lane
grave
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
- `target zone = victory compiler`.

Но в первом playable machinery layer активны только minor-карты.
Trump ecology пока не кристаллизуется в коде.

## Что мы делаем сейчас

Пишем Lua table-based simulator, потому что natural-language design начал расползаться.

Симулятор - не просто техника.
Это thinking tool: он должен показывать противоречия, мёртвые механики, неявные дыры и места, где игра ещё не стала игрой.

Перед кодом действует рабочий закон:

```text
table first
crystall second
```

Смысл:

- `table` = документы, где явно названы зоны, переходы, ходы, trigger order и локальные prototype допущения;
- `crystall` = кодовая фиксация уже названной структуры.

Это не значит, что документы должны быть “идеальными”.
Это значит, что код не должен становиться местом, где внезапно рождается скрытый rulesheet.

Текущий рабочий приоритет:

1. описать первый prototype table;
2. сделать приятный и честный minor game loop;
3. собрать рабочую машину на 100 minor-карт;
4. подключить простой working target/compiler shell без active trump payloads;
5. только потом возвращаться к trump-layer.

Если реализация вскрывает design problem, нужно назвать его явно.
Не надо молча изобретать большое правило, если без него можно сохранить маленький прототип.

machines only. not for humans.
