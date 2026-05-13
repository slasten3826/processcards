# ProcessCards Game Overview

Статус:

```text
human-readable current table overview
shareable summary of the game
not a replacement for detailed table laws
```

Этот документ нужен для двух задач:

1. быстро объяснить, что такое `ProcessCards`
2. дать один плотный вход в игру без чтения десятков law-файлов

Если нужен полный канон, после этого документа читать:

- [CURRENT_CANON_SUMMARY.md](./CURRENT_CANON_SUMMARY.md)
- [TURN_LAW_V2.md](./TURN_LAW_V2.md)
- [TURN_SEQUENCE_LAW_V2.md](./TURN_SEQUENCE_LAW_V2.md)
- [OPERATORS_INDEX.md](./OPERATORS_INDEX.md)
- [WIN_CHECK_LAW.md](./WIN_CHECK_LAW.md)

## 1. Что такое ProcessCards

`ProcessCards` — это не игра про строительство своего поля и не обычный card battler.

Её базовое чтение такое:

```text
you do not build the world
you intervene in an already moving machine
```

В игре уже существует дышащая поверхность мира:

- `manifest` — открытый слой
- `latent` — скрытый поддерживающий слой

Игрок не ставит карту из руки на стол как новый постоянный объект.
Игрок посылает из руки **пакет вмешательства** в уже движущуюся структуру.

Коротко:

```text
hand = intervention reservoir
manifest / latent = world surface
turn = intervention into a moving strip
```

## 2. Почему 100 миноров и 22 козыря

### 100 миноров

Миноры — это полная упорядоченная сетка операторных пар:

```text
10 operators x 10 operators = 100 minor cards
```

Порядок в минорах имеет значение:

```text
AB != BA
```

То есть `☵☳` и `☳☵` — это разные minor-карты.

### 22 козыря

Козыри строятся иначе.

Они не берут всю ordered-grid логику миноров.
Они собираются как все уникальные adjacency-пары канонической топологии:

```text
trumps = all unique topology adjacencies
AB = BA
no self-pairs
```

Поэтому их не `100`, а `22`.

Коротко:

```text
minors = ordered operator grid
trumps = unordered topology adjacencies
```

## 3. Чем миноры отличаются от козырей

Это одно из главных различий игры.

### Миноры

Миноры — это обычная рабочая материя игры.
Они:

- лежат в `manifest`
- лежат в `latent`
- входят в руку
- выбираются для обычного хода
- несут два оператора

Миноры читаются как:

```text
state matter
```

### Козыри

Козыри — это не просто “сильные карты”.
Они читаются как:

```text
events
```

Козырь обычно не становится обычной частью minor-состояния.
Он врывается в игру как нарушение, сдвиг, замена, раскрытие, сброс, расширение или перестройка текущей машины.

Коротко:

```text
minor = state
trump = event
```

## 4. Зоны стола

Текущая машина использует такие основные зоны:

### `deck`

Главная колода.
Глубокая внутренняя часть колоды не считается board.
Но `topdeck` может становиться видимой и значимой поверхностью.

### `hand`

Рука игрока.
Это не board и не слой будущих world-objects.
Это резервуар пакетов вмешательства.

### `manifest`

Открытая 6-карточная цепь.
Это:

- видимая поверхность мира
- активная полоска хода
- будущая поверхность победной строки

### `latent`

Скрытая 6-карточная подпорка под `manifest`.
Когда `manifest`-карта consumed, именно `latent` поднимается вверх и занимает её место.

### `targets`

3 скрытых слота-компилятора победы.
Когда там собираются 3 козыря, они компилируют победный шаблон.

### `grave`

История открытых и потраченных слоёв.
Сюда уходят:

- committed карта из `manifest`
- сыгранная карта из руки
- многие раскрытые non-trump cards
- часть эффектных сбросов и растворений

### `runtime`

Специальная зона установленного runtime-состояния.
Она не тождественна обычному board-object placement.
Это отдельная машинная зона.

### `trump flow`

Очередь козырей “в полёте”, которые ещё не закрыли свою цепь разрешения.

### `trump zone`

Хранилище отработавших козырей.
Это не grave.
Это отдельная камера козырной экологии.

### `topdeck`

Верхняя карта колоды, если она стала видимой или известной.
`topdeck` считается частью board.

Коротко:

```text
board = targets + manifest + latent + runtime + grave + trump flow + trump zone + topdeck
hand is not board
deep deck is not board
```

## 5. Старт партии

Полная колода состоит из:

```text
100 minor cards
22 trump cards
122 total
```

Старт делается в две фазы.

### Фаза A — minor-only bootstrap

Сначала используются только `100` minor cards:

- `manifest[1..6]` — 6 карт face-up
- `hand` — 6 карт

После этого открытый старт гарантированно minor-only.

### Фаза B — full deck completion

Потом:

1. оставшиеся `88` minor cards смешиваются с `22` trumps
2. колода снова перемешивается
3. из неё раскладываются:
   - `targets[1..3]` face-down
   - `latent[1..6]` face-down

После setup:

- `manifest` = 6 открытых миноров
- `hand` = 6 миноров
- `targets` = 3 скрытые карты
- `latent` = 6 скрытых карт
- `grave` = empty
- `runtime` = empty
- `trump zone` = empty

## 6. Как вообще устроен ход

Ход в `ProcessCards` читается не как “положи карту на стол”.

Текущая формула хода такая:

```text
commit one visible manifest card
fit one legal hand card into it
let the world update
resolve one chosen operator
spend the played card
then check victory
```

### По шагам

1. игрок выбирает одну открытую карту в `manifest`
2. игра считает, какие карты руки к ней подходят по topology-fit law
3. игрок выбирает одну legal hand-card
4. игрок подтверждает запуск хода
5. committed карта из `manifest` уходит в `grave`
6. соответствующая карта из `latent` поднимается в `manifest`
7. `deck top` заполняет пустой `latent`-слот скрыто
8. сыгранная карта из руки входит в `play`
9. игрок выбирает один оператор этой карты
10. эффект оператора разрешается
11. сыгранная карта уходит в `grave`
12. только после полного закрытия хода может проверяться победа

Важно:

```text
the hand card is cast at the world
it does not remain in manifest as a permanent object
```

## 7. Как вообще ходить легально

Не любая карта руки подходит к любой карте `manifest`.

Текущая ветка использует `MOVE_FIT_LAW`:

```text
a hand card is legal only if both of its operators
fully close against the committed manifest card
```

Смысл:

- glyph/topology в игре не декоративны
- карта руки должна реально “сойтись” с committed world-node
- orphan operator запрещён

Поэтому каждый ход — это не просто выбор сильного эффекта,
а ещё и геометрически легальное вмешательство в поверхность мира.

## 8. Условия поражения

В текущей ветке зафиксировано одно базовое условие поражения:

```text
if you must take a normal turn and your hand is empty, you lose
```

То есть:

- если игра требует от тебя обычного minor turn
- а в `hand` нет карт
- партия проиграна

Другие loss-условия могут появиться позже,
но current branch пока фиксирует именно это как базовый проигрыш.

## 9. Как устроена победа

Победа не живёт в отдельном score track.

Она собирается из двух вещей:

1. `target zone`
2. `manifest chain`

### `targets` как компилятор

Когда в `targets` лежат 3 козыря,
они компилируют победный шаблон.

Пока там меньше 3 козырей:

```text
no full victory pattern exists yet
```

### `manifest` как видимая строка

Скомпилированный шаблон должен не “где-то совпасть”,
а полностью воплотиться в видимой 6-карточной цепи `manifest`.

Коротко:

```text
targets write destiny
manifest must embody it
```

### Важные ограничения

- победа directional
- победа ordered
- victory check не делается посреди резолва
- проверка идёт только после полного закрытия хода

## 10. Операторы

Формально в текущем каноне их `10`.

Если хочется разделять их по форме,
можно читать это так:

- `9` триграммных операторов
- `1` особый оператор `△ MANIFEST`

Полный текущий список:

1. `▽ FLOW`
2. `☰ CONNECT`
3. `☷ DISSOLVE`
4. `☵ ENCODE`
5. `☳ CHOOSE`
6. `☴ OBSERVE`
7. `☶ LOGIC`
8. `☲ CYCLE`
9. `☱ RUNTIME`
10. `△ MANIFEST`

### Кратко по каждому

#### `▽ FLOW`

Работа со скрытым движением и перераспределением concealed структуры.

#### `☰ CONNECT`

Обычный приток материи в руку через draw procedures.

#### `☷ DISSOLVE`

Прожигание скрытой подпорки committed-столбца до его обычного подъёма.

#### `☵ ENCODE`

Работа со скрытой / not-revealed структурой и её перестановкой.

#### `☳ CHOOSE`

Извлечение видимой полевой карты обратно в руку.

#### `☴ OBSERVE`

Получение знания о скрытой карте без обязательного публичного reveal.

#### `☶ LOGIC`

Перекомпоновка уже surfaced материи через pair-card swap.

#### `☲ CYCLE`

Обновление hand-state через draw + controlled discard.

#### `☱ RUNTIME`

Установка или предоставление дополнительного operator-layer pressure.

#### `△ MANIFEST`

Выведение скрытой карты в публично раскрытое состояние.

## 11. Что делают 22 козыря

Ниже — короткие однострочные чтения, не заменяющие полные trump docs.

### `CANON`

Reveal верх колоды; если там подходящая связка, втягивает её в руку и продолжает чтение.

### `EJECT`

Берёт одну карту, раскрывает если нужно, затем выбрасывает её из текущей зоны или discharge’ит.

### `ENOUGH`

Проверяет равенство между увиденным внешним и удерживаемым внутренним; при совпадении даёт alternate victory.

### `ERROR`

Открывает grave и возвращает всё накопленное residue обратно в машину без права отказаться.

### `FOOL`

Сверлит колоду draw-процедурами до контакта с козырем.

### `GATE`

Оставляет на столе только то видимое, что разделяет оператор с выбранным gatekeeper; остальное уходит в `grave`.

### `GRANT`

Временно добавляет новую wildcard-колонку и разрешает два каста через расширенную поверхность.

### `HALT`

Даёт текущей trump-цепи нормально закрыться, но не пускает новые козыри в неё войти.

### `MAXIMIZE`

Позволяет подряд кастовать карты из руки прямо в `manifest`, пока topology это разрешает.

### `ORACLE`

Смотрит верхние 6 карт колоды, берёт одну в руку, остальные возвращает наверх в выбранном порядке.

### `PURGE`

Сметает revealed non-trump материю; target-trumps при этом активируются как compiler matter.

### `RECAST`

Переформировывает hand-state через временную proto-hand конструкцию и новую раскладку.

### `REPEAT`

Повторяет родительский козырь или делает ничего.

### `REQUIEM`

Берёт одну скрытую карту поля, ставит её в `runtime` и заставляет этот runtime снова править игрой.

### `RESET`

Сбрасывает текущее hand-состояние и заставляет собрать его заново.

### `RUSH`

Даёт быстрый burst hand-state через серию draw procedures.

### `SHUFFLE`

Перемешивает соответствующую материю и ломает текущую фиксированную предсказуемость.

### `SWAP`

Меняет местами два козыря на столе.

### `TIGEL`

Якорит себя в `trump zone` и расширяет ёмкость козырной камеры.

### `UNBOUND`

Растворяет одну target-card и занимает её слот самим собой.

### `UNVEIL`

Переводит hidden state в visible state.

### `WARRANT`

Забирает любую разрешённую карту в руку.

## 12. Nine Circle Run

Отдельно от основной партии у `ProcessCards` есть branch:

```text
Roguelike Nine Circles
```

Это не просто “ещё один режим”, а descent-структура,
где каждый круг искажает один из операторов.

Ключевой порядок такой:

```text
Circle 9 -> Circle 8 -> Circle 7 -> Circle 6 -> Circle 5 -> Circle 4 -> Circle 3 -> Circle 2 -> Circle 1
```

То есть run идёт:

```text
☱ -> ☶ -> ☲ -> ☴ -> ☳ -> ☵ -> ☷ -> ☰ -> ▽
```

`△ MANIFEST` не является кругом.
Она остаётся внешним слоем выхода / воплощения / победного закрытия.

### Базовый принцип Nine Circle Run

Каждый круг не просто штрафует игрока числом.
Он искажает сам жест одного оператора.

Коротко:

```text
floor = circle pathology x operator law
```

### Текущая shape of the run

- **Circle 9 / ☱ RUNTIME**: runtime начинает тикать автоматически
- **Circle 8 / ☶ LOGIC**: grave становится публичной реальностью
- **Circle 7 / ☲ CYCLE**: cycle превращается в повтор stored trump-force
- **Circle 6 / ☴ OBSERVE**: знание становится ересью и заменой
- **Circle 5 / ☳ CHOOSE**: выбор превращается в прямую manifest-replacement логику
- **Circle 4 / ☵ ENCODE**: hidden encode схлопывается в visible burden swap
- **Circle 3 / ☷ DISSOLVE**: Cerberus ест весь latent row
- **Circle 2 / ☰ CONNECT**: draw идёт из grave
- **Circle 1 / ▽ FLOW**: скрытая подложка отказывается стабилизироваться

Важно:

```text
Nine Circle Run is a current design branch
not yet the same thing as locked base-game runtime law
```

## 13. Короткая формула всей игры

Если совсем сжать `ProcessCards`, получится так:

```text
100 ordered minor packets
22 trump events
6 visible manifest cards
6 hidden latent supports
3 hidden target compiler slots

turn = commit world-node
+ fit legal hand packet
+ let the world update
+ resolve one operator

victory = compiled target-trump pattern
made real on the visible manifest chain
```
