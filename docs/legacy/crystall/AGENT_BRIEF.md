# Бриф для агента

Статус:

```text
current crystall handoff
```

Ты подключаешься к активному design process по `ProcessCards`.

Сейчас главное:

```text
if the rule is not known, do not code it
```

## 1. Рабочий закон

Текущий порядок проекта:

```text
thought
-> table
-> crystall
-> code
```

Новый код не пишется,
если rule-surface ещё не собрана документами.

## 2. Текущий scope

Первый ближайший runtime layer сейчас:

```text
board engine skeleton
```

То есть:

- все ключевые зоны уже присутствуют
- карты уже существуют как сущности
- gameplay legality ещё не включена
- `trump zone` уже есть как shell
- active trump gameplay по-прежнему не включён
- `Start Game` setup may already exist before normal mode

## 3. Текущий runtime target

Первый runtime target сейчас:

```text
Lua + LÖVE
```

Browser-v0 больше не является текущим build target.
CLI-first больше не является первичной траекторией.

## 4. Главные источники истины

### Table canon

- `docs/table/OPERATORS_INDEX.md`
- `docs/table/operators/*.md`
- `docs/table/CONNECT_LAW.md`
- `docs/table/STRONG_COMBINED_LAW.md`
- `docs/table/STRONG_PAIR_TABLE.md`
- `docs/table/MINOR_MACHINE.md`

### Crystall canon

- `docs/legacy/crystall/FIRST_LOVE_PROTOTYPE_TZ.md`
- `docs/crystall/PROTOTYPE_CRYSTALL.md`

## 5. Strong law

`strong` больше нельзя читать как:

```text
draw 2 + 1-2 weak-like effects
```

Текущий закон:

```text
draw 2 + one combined reading of the pair
```

Если pair-reading ещё не собран документом,
его нельзя кодить.

## 6. CONNECT law

`☰ CONNECT` — это отдельная механика,
а не обычная строка общей strong-таблицы.

Читать:

- `docs/table/CONNECT_LAW.md`

## 7. Что реально строится первым

Когда проект доходит до кода,
первый runnable слой должен дать:

- setup
- hand
- manifest row
- latent row
- targets shell
- runtime shell
- trump zone shell
- grave
- log
- `dev mode`
- `draw / discard / manual place / flip`
- `Start Game` from full 122-card deck
- shuffled opening setup with targets / manifest / latent / hand

Нормальный gameplay mode на этом слое ещё не обязателен.

## 8. Чего не делать

Сейчас нельзя:

- возвращать trump-first scope
- строить active trump gameplay в first build
- кодить unresolved strong pairs
- держать в handoff два несовместимых runtime target
- вводить hidden digital truth без cardboard analogue

## 9. Short formula

```text
first assemble the game in thought
then document it
only then implement
```
