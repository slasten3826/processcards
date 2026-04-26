# Draw Procedure Law

Статус:

```text
canonical prototype table law
```

Этот документ фиксирует,
что именно значит `draw`
в текущем prototype scope.

## 1. Core claim

`Draw` — это не “просто добавь карту в руку”.

`Draw` всегда читается как отдельная процедура:

```text
reveal topdeck
resolve what was revealed
then end that one draw procedure
```

## 2. Minor result

Если revealed topdeck = minor-card,
то:

1. карта становится `known`
2. карта входит в `hand`
3. конкретная draw procedure успешно даёт карту

## 3. Trump result

Если revealed topdeck = trump,
то:

1. карта становится `known`
2. запускается обычный `TRUMP event` path
3. карта **не** входит в `hand`
4. именно эта конкретная draw procedure считается потраченной

Коротко:

```text
trump burns that draw procedure
```

## 4. Multi-draw consequence

Если эффект даёт не одну, а несколько draw procedures,
то каждая из них считается отдельно.

Пример:

```text
draw 2
```

значит:

1. perform draw procedure #1
2. perform draw procedure #2

Если в первой вскрылся trump,
сгорает только первая.

Вторая всё равно выполняется.

## 5. Why this law exists

Этот закон нужен, чтобы:

- trump не превращался в обычную карту руки
- один trump не отменял весь multi-draw effect целиком
- draw оставался частью общей future-machine,
  а не отдельной бухгалтерией

## 6. Relationship to trump law

Этот документ нужно читать вместе с:

- [TRUMP_EVENT_MINIMAL_LAW.md](./TRUMP_EVENT_MINIMAL_LAW.md)
- [CARD_INFORMATION_STATE_LAW.md](./CARD_INFORMATION_STATE_LAW.md)

Разделение такое:

- `DRAW_PROCEDURE_LAW` = что значит один draw step
- `TRUMP_EVENT_MINIMAL_LAW` = что происходит, если draw вскрыл trump
- `CARD_INFORMATION_STATE_LAW` = hidden / known / revealed model

## 7. Short formula

```text
each draw is one separate procedure
minor enters hand
trump triggers event and burns that one draw procedure
remaining draw procedures still continue
```
