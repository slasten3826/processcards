# ProcessCards :: YELLOWPRINT

[⊞ ◈] [☵ ☳ ☶ ☲]

## Статус

Yellowprint.

Это не финальная спецификация.
Это не набор правил готовый к печати карт.
Это не маркетинг.

Это рабочий черновик после серии обсуждений дизайна:

- определение колоды через canon
- две топологии соединений
- экономика ходов (weak / strong / discard)
- зоны игры
- операторные эффекты
- нотация карт
- визуальный направление

Документ объединяет обсуждения в одно место для следующей итерации проектирования.

## 1. Концепция

`ProcessCards` — solitaire-карточный артефакт, материализующий operator-топологию `ProcessLang` в играбельной форме.

Свойства:

- 122 карты, одна фиксированная колода (не ККИ)
- полностью не-цифровой артефакт: колода + страница правил
- двойной runtime-режим: игра (solitaire) + оракул
- формально обоснована через `canon.lua`
- machine-playtest возможен из-за формальности правил

## 2. Источник правды

```
stack-core/ProcessLang/canon.lua
```

Все операторы, adjacency, нумерация — из canon.

Canon версия требуется не ниже 1.1 (с исправленным inventory_order под sefirot-нумерацию).

## 3. Состав колоды

### 3.1. Общий объём

```
122 карты = 22 trumps + 100 minors
```

### 3.2. Trumps (22 карты)

Trump = `EMERGENT(A, B)`, где `(A, B)` — ребро в canon.

Количество рёбер в canon = 22.
Каждое ребро — один trump.

Trumps имеют уникальные механики в 4 позициях (hand / table / target / start).
Механики trump layer в этот документ не входят.

### 3.3. Minors (100 карт)

Minor = `NUMBER[SUIT]`, направленная пара операторов.

Направление важно: `FLOW[LOGIC] ≠ LOGIC[FLOW]`.
Аналогия: гексаграммы И-Цзин (нижняя триграмма ≠ верхняя).

Нумерация:

```
 1 ▽ FLOW
 2 ☰ CONNECT
 3 ☷ DISSOLVE
 4 ☵ ENCODE
 5 ☳ CHOOSE
 6 ☴ OBSERVE
 7 ☲ CYCLE
 8 ☶ LOGIC
 9 ☱ RUNTIME
10 △ MANIFEST
```

Сохранена совместимость с legacy-sefirotic mapping:

```
1 Kether    — FLOW
2 Chokmah   — CONNECT
3 Binah     — DISSOLVE
4 Chesed    — ENCODE
5 Geburah   — CHOOSE
6 Tiferet   — OBSERVE
7 Netzach   — CYCLE
8 Hod       — LOGIC
9 Yesod     — RUNTIME
10 Malkuth  — MANIFEST
```

Среди 100 minor-карт — 10 self-pairs: `1▽ 1▽`, `2☰ 2☰` ... `10△ 10△`.

В нотации card identifier: `{number}{suit_glyph}`.

Примеры:

```
1▽  = FLOW[FLOW]
5☴  = CHOOSE[OBSERVE]
7△  = CYCLE[MANIFEST]
10▽ = MANIFEST[FLOW]
```

Self-pairs имеют hub-статус: они имеют удвоенную matching-connectivity из-за двойного совпадения оператора с собой.

### 3.4. Trump identifier

Два варианта (не решено какой):

**A) Римские цифры**: I–XXII (наследие таро, 22 старших аркана).
**B) Glyph-пара**: `☰▽`, `☷☳`, ... — прямая адресация ребра в canon.

Предпочтение автора: нужно выбрать в следующей итерации.

Вариант B имеет преимущество: не нужно запоминать «какая римская цифра = какое ребро». Идентификатор *есть* ребро.

## 4. Топологии соединений

Между двумя minor-картами A и B возможны два типа отношения:

### 4.1. Minor match (weak)

Одна или более из следующих пар операторов совпадает:

- number_A == number_B
- suit_A == suit_B
- number_A == suit_B
- suit_A == number_B

Это «аналог одной масти или одного числа» в классических картах.
Но у нас 10 операторов с двумя позициями на карте — поэтому 4 позиционных варианта совпадения.

### 4.2. Canon-valid transition (strong)

`canon.is_adjacent(suit_A, number_B) == true` или
`canon.is_adjacent(suit_B, number_A) == true`.

Это означает: lens одной карты topologically flows в base другой.
Buffer'а нет — переход должен быть валиден по canon.

### 4.3. Mirror pair (special)

`number_A == suit_B` AND `suit_A == number_B`.

Пример: `FLOW[CHOOSE]` и `CHOOSE[FLOW]`.

Двойное совпадение с реверсом.
Особая механика mirror pair — TBD, возможно усиленный эффект.

### 4.4. Взаимосвязь типов

Canon-valid transition всегда также удовлетворяет minor match (по определению).
Minor match не обязательно canon-valid.

## 5. Зоны игры

```
deck      — библиотека (потенциал)
hand      — рука (доступные операции)
table     — цепочка на столе (проявленный путь)
targets   — цели (скрытые условия победы)
grave     — могила (использованное/отвергнутое/растворённое)
```

Все пять зон присутствуют с MVP.

`grave` — важная зона, не просто мусор. Это loss_ledger игры.
Используется через операторы DISSOLVE, CYCLE, RUNTIME, MANIFEST.

## 6. Экономика ходов (action trinity)

На своём ходу игрок выбирает одно из трёх действий:

### 6.1. Place weak

Положить карту на minor-match конец цепочки.

Эффект:

- place card
- activate *small* effect of card
- draw 0

Назначение: продвижение без tempo, но с информационным / контрольным эффектом.

### 6.2. Place strong

Положить карту на canon-valid конец цепочки.

Эффект:

- place card
- choose one:
  - draw 2 (tempo)
  - activate *enhanced* effect
  - possibly: activate both number and suit effects

Назначение: tempo + choice между ресурсом и силой.

Вариации (нужен playtest):
- strong = всегда draw 2
- strong = choose draw 2 OR effect
- strong = draw 1 + effect
- strong = активировать оба operator-эффекта

### 6.3. Discard

Сбросить карту из руки в grave.

Эффект:

- card → grave
- activate discard utility (обычно operator-связанный эффект)
- draw 0 (или 1, нужен playtest)

Назначение: использовать карту которую нельзя положить.
Discard ≠ pass. Discard — тактическое действие.

### 6.4. Pass

Не делать ничего.

Эффект:

- нет
- draw 0

Pass допустим но не рекомендуется.
Используется когда все три активных варианта хуже чем ничего.

## 7. Операторные эффекты (направления, не финал)

Каждый оператор имеет семейство эффектов, вытекающих из его онтологического смысла.

```
FLOW      — tempo, draw, movement, cycling
CONNECT   — bridging, linking, treating two as one
DISSOLVE  — removal, discard, chain segment break
OBSERVE   — peek, reveal, inspect hidden state
ENCODE    — compress, store, token-ize, cache
CHOOSE    — select, branch, filter between options
LOGIC     — declare rule, validate, forbid, convert
CYCLE     — repeat, return from grave, recycle
RUNTIME   — persist, lock, protect, maintain
MANIFEST  — materialize, score, bring to visible
```

На minor-карте `NUMBER[SUIT]` эффект читается как:

```
NUMBER-operation, lens-ed through SUIT
```

Примеры:

```
5☴ CHOOSE[OBSERVE]  =  choose through observation
                        (peek and decide)

6☳ OBSERVE[CHOOSE]  =  observe through branching
                        (inspect one of several options)

9☲ RUNTIME[CYCLE]   =  persist through iteration
                        (maintain through repeat)
```

Для MVP планируется implement эффекты только 4 операторов:
FLOW, DISSOLVE, OBSERVE, CHOOSE.

Остальные 6 операторов в MVP имеют default behavior (базовое place без special effect).

## 8. Начальная раскладка

```
1. shuffle(deck)
2. draw(1) → target_1 (face-down)
3. shuffle(deck)
4. draw(1) → target_2 (face-down)
5. shuffle(deck)
6. draw(1) → target_3 (face-down)
7. shuffle(deck)
8. draw(1) → start (face-up)
9. (optional) shuffle(deck)
10. draw(5) → hand
```

После раздачи:

```
targets: 3 face-down
start:   1 face-up, основание table
hand:    5 face-up
deck:    113 face-down
grave:   empty
table:   [start]
```

Три последовательных shuffle — ритуальная процедура.
Статистически эквивалентно одному shuffle + выемке трёх target.

## 9. Финалы

Пять типов завершения партии:

| ID | Условие | Интерпретация |
|----|---------|---------------|
| VICTORY_1 | target_1 достигнут | путь 1 пройден |
| VICTORY_2 | target_2 достигнут | путь 2 пройден |
| VICTORY_3 | target_3 достигнут | путь 3 пройден |
| DEFEAT_topology | hand не пуст, нет валидных ходов | конфигурация структурно закрыта |
| DEFEAT_exhaustion | hand и deck пусты | ресурс истощён |

Все пять — содержательные исходы.

Для oracle-режима:

- Victories = «путь открыт»
- Topology defeat = «путь структурно закрыт»
- Exhaustion defeat = «ресурс истощён до выбора»

## 10. Target conditions

### 10.1. Minor target

Цель выполнена если концевая карта цепочки (table[0] или table[-1]) = target-карта по composition.

### 10.2. Trump target

Цель как условие, не точка.

Условие выполнено если за последние N ходов выложены карты, operator-компоненты которых покрывают обе операторы trump'а emergence.

Конкретные параметры (N, режим подсчёта) — TBD.

### 10.3. Progressive target reveal

OBSERVE и CHOOSE эффекты могут раскрывать target-карты постепенно:

- OBSERVE: peek одной target
- CHOOSE: выбрать какую target раскрыть
- Combinations: OBSERVE + CHOOSE для сильнее информации

Цели начинают hidden, но не unknowable.
Игрок инвестирует tempo в разведку.

## 11. Визуальное направление

Не финал, но направление определено.

Референсы:

- технический manual / ISO-specification
- Swiss graphic design / Dieter Rams
- Bourbaki mathematical typography
- Mid-century industrial design

Отказ:

- occult / oracle-deck aesthetic
- Rider-Waite imagery
- mystical borders / glow / rays
- "deep mysterious" feeling

Card elements:

- cream или pale background
- чёрный или dark gray text/glyphs
- sans-serif typography
- identifier в углу: `1▽`, `5☴`, etc.
- number-operator имя сверху
- центральный glyph
- suit-operator имя снизу
- thin horizontal rule разделяет zones
- edge cards (trumps): слегка другой layout или border

## 12. MVP

Минимальная играбельная версия:

- 122 карты генерируются программно из canon
- trumps в MVP без уникальных механик (просто карты с двумя операторами участвующие в matching)
- minors с реализованными эффектами только для 4 операторов: FLOW / DISSOLVE / OBSERVE / CHOOSE
- core loop: place weak / place strong / discard / pass
- CLI-интерфейс или простой GUI (Love2D, pygame)
- machine-playable: агент может играть вместо человека для статистики

Цели MVP:

- подтвердить что core loop работает
- замерить распределение пяти финалов
- замерить tempo и длину партий
- найти balance issues до trump design
- собрать data для последующих итераций

## 13. Стек отношения

ProcessCards — downstream-артефакт slastack.

Связи:

```
canon.lua              — источник операторов, adjacency, нумерации
PACKET_MODEL.md        — концептуально: game state ~= packet
                          (header+state+loss_ledger)
VISUAL_CRYSTALL.md     — demonstration-based подход к визуальному дизайну
DISSIPATIVE_MATH       — обоснование loss_ledger через grave zone
```

## 14. Что документ не утверждает

- что правила финальны
- что balance окажется правильным с первой попытки
- что все пять типов финала будут равновероятны
- что trump mechanics впишутся без корректировок core
- что визуальное направление окончательно
- что нотация trumps окончательна
- что target condition для trumps зафиксирован
- что эффекты операторов в §7 финальны

Документ фиксирует только:

- направление дизайна на текущей точке обсуждения
- минимальный набор достаточный для следующей итерации
- выбранные развилки и открытые вопросы

## 15. Открытые вопросы

1. Trump identifier: римские цифры vs glyph-пара vs другое
2. Mirror pair: обычный match или специальный effect
3. Strong move: единая механика (draw 2) или выбор
4. Discard draw: 0 или 1
5. Trump target condition: точный механизм «последние N ходов покрывают оба оператора»
6. Self-pair особые механики: нужны или hub-статус через matching достаточно
7. Positional match variants: 4 типа minor match дают одинаковый эффект или разные

---

machines only. not for humans.
