# Prototype Table

Это table-документ первого играбельного прототипа.

Он фиксирует не код,
а поверхность будущей сборки:

- какие зоны существуют;
- какие переходы уже разрешены;
- какие ходы уже считаются частью первой игры;
- какие допущения мы принимаем сознательно;
- что пока не кодируем.

Это не финальный rulesheet.
Это рабочая table перед crystall.

## 0. Physical-card law

Этот прототип обязан быть честно исполнимым на реальных картах.

Базовый закон:

```text
if cardboard cannot do it, prototype cannot rely on it
```

Отсюда следуют запреты:

- нельзя опираться на скрытую цифровую память, которой у игрока нет;
- нельзя делать автоматические reveal/checks, которые игрок физически не может выполнить;
- нельзя использовать невидимые очереди, маркеры или состояния без карточного выражения;
- нельзя требовать действий, которые невозможны руками на столе;
- нельзя подменять сложный физический процесс “бесплатной кнопкой”, если сама игра потом должна жить на картоне.

Прототип может помогать считать и подсвечивать,
но не имеет права строиться на действиях, которых физическая версия не может выполнить.

## 1. Цель первого прототипа

Первый прототип должен дать честный playable loop:

- игрок видит стол;
- игрок видит hand;
- игрок выбирает action;
- игрок выбирает карту;
- игрок выбирает колонку;
- игра валидирует weak / strong relation;
- игра обновляет manifest / latent / grave / deck / hand;
- игра оставляет log хода;
- игра сохраняет board shape.

Критерий успеха:

```text
в это уже можно играть руками
и уже можно заметить, где игра врёт
```

Материал первого playable слоя:

```text
100 minor-карт
```

Физический состав minor deck:

```text
100 ordered cards remain physically distinct
```

Но effect reading minor-карты может игнорировать внутренний порядок пары.

## 2. Формат первого настоящего runtime

Первый настоящий runtime идёт в:

```text
Lua + LÖVE
```

Причина:

- игра и так проектируется под Lua;
- `Love2D` уже установлен;
- нужен кликабельный карточный стол;
- board пространственный, а не только текстовый;
- GUI должен быть нативным слоем над rules machine.

Browser sketch может жить как visual reference,
но не как основной runtime проекта.

LÖVE-прототип здесь нужен не для цифрового convenience fantasy,
а для честного проигрывания картонной машины.

## 3. Board surface

Ядро стола:

```text
5 columns x 2 layers
```

В каждой колонке:

- 1 manifest slot
- 1 latent slot

Другие зоны первого прототипа:

```text
deck
hand
targets
runtime lane
grave
log
```

## 4. Stable board laws

Для первого прототипа держим инварианты:

- manifest row всегда содержит 5 slots;
- latent row всегда содержит 5 slots;
- runtime lane capacity = 1;
- grave остаётся ordered;
- target zone содержит 3 ordered slots.

И ещё один инвариант:

- каждое состояние прототипа должно иметь физический аналог на столе.

## 5. First playable action set

На первом playable слое игрок может выбрать одно из действий:

- `place weak`
- `place strong`
- `discard`
- `pass`

Это и есть первый настоящий action surface.

Все эти действия в первом playable слое целят только:

```text
open manifest chain
```

Не latent.
Не targets.
Не runtime.
Core gameplay первого слоя = работа по открытому manifest row.

## 6. Weak law for prototype

Для первого прототипа фиксируем локальное допущение:

```text
choose hand card
target one open manifest card
target manifest -> grave
hand card -> target manifest slot
resolve 1 effect of the played card
draw 0
```

Почему так:

- weak должен быть staging;
- weak должен усиливать latent growth;
- weak должен создавать pressure без бесплатного tempo;
- weak должен использовать локальность колонки.

Это prototype law, не вечный закон.

И оно допустимо физически:

- игрок может выбрать карту из руки;
- игрок может указать открытую карту в main chain;
- целевая карта может уйти в grave;
- карта из руки может занять её место.

## 7. Strong law for prototype

Для первого прототипа фиксируем:

```text
choose hand card
target one open manifest card
target manifest -> grave
hand card -> target manifest slot
draw 2
resolve one strong combined reading of the played pair
```

И это тоже должно оставаться физически исполнимым:

- положить карту в manifest;
- убрать старую карту в grave;
- добрать 2 карты из deck.

Current canonical source for strong payload:

- [STRONG_COMBINED_LAW.md](./STRONG_COMBINED_LAW.md)
- [STRONG_PAIR_TABLE.md](./STRONG_PAIR_TABLE.md)

## 8. Discard law

Для первого прототипа:

```text
discard = hand -> grave
draw 0
```

Discard не должен становиться бесплатным фильтром.

## 9. Pass law

Для первого прототипа:

```text
pass = legal but tempo-negative
```

Если pass начинает становиться частым,
это сигнал, что hand economy или relation pressure собраны плохо.

## 10. Relation law

Move legality:

- weak требует `weak relation`;
- strong требует `strong relation`;
- mirror пока считается special structure without dedicated payoff.

Текущее уточнение weak topology:

```text
weak = same number OR same suit
```

Без cross-position match в первом playable prototype.

Текущее уточнение strong topology:

```text
strong = canon-valid transition from ProcessLang topology
```

Это topology layer хода.
Отдельно от этого у карты есть effect layer.

Для него сейчас фиксируем:

```text
weak uses 1 effect
strong uses one combined pair reading
```

Deprecated legacy draft:

```text
strong = 1-2 effects of the card
```

That older wording should no longer be treated as live canon.

Important prototype distinction:

- not every documented strong pair is already prototype-legal now;
- some strong pair readings belong to future canon but are not yet ready for first playable build;
- unresolved pairs must not be faked in code.

Важно:

relation legality может быть подсвечена прототипом,
но не должна зависеть от скрытой цифровой информации.
Игрок должен уметь вручную проверить её по открытым картам.

## 11. Minor-only law

Первый playable prototype намеренно не включает active trumps.

```text
minor-only machine first
```

Причина:

- нам пока нужна не “игра с одним козырем”;
- нам нужна рабочая машина на 100 minor-карт;
- trump-layer сейчас только усложнит diagnosis;
- сначала minor-loop должен стать настоящей игрой.

## 12. Latent discipline

Latent row уже существует на столе в первом prototype,
но пока не участвует напрямую в core weak/strong move loop.

Текущее состояние:

- latent visible as zone structure? no;
- latent physically present as hidden cards? yes;
- weak/strong target latent? no;
- manifest replacement auto-promotes latent? no.

То есть latent сейчас есть как board layer,
но ещё не включён в основную механику замещения.

## 13. Target compiler shell

В первом playable прототипе target zone должен существовать как поверхность уже сейчас.

Но его semantic payload может быть отложен.

Минимум, который нужно удержать:

- 3 ordered slots;
- hidden candidate surface;
- refill law, если это потребуется для первого loop;
- no continuous win-check;
- check window only after resolution tail.

Если target surface в первом срезе ещё не обслуживается физически чисто,
лучше оставить её как видимую, но пассивную часть стола,
чем притворяться, что она уже играет по rules, которых нельзя честно выполнить руками.

## 14. Card effect model

Для первого prototype scope дополнительно фиксируем:

- каждая minor-карта несёт два operator layers;
- не каждый оператор обязан быть self-sufficient on weak;
- `☳ CHOOSE` сейчас meaningful прежде всего в комбинации;
- `☴ OBSERVE` уже выглядит usable standalone;
- strong может раскрывать combined reading карты;
- `AB` и `BA` могут быть разными physical cards, но одной effect family.

## 15. Что пока сознательно не фиксируем

Пока не фиксируем окончательно:

- operator-specific minor effects;
- full target compiler semantics;
- full hidden trump procedure;
- any active trump payloads;
- balance numbers;
- final card wording.

## 16. Short formula

```text
first prototype = honest minor loop on a 5x2 board
```

machines only. not for humans.
