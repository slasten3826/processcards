# Logic Joker Law

Статус:

```text
canonical table law
current LOGIC branch
supersedes the operator effect in operators/LOGIC.md
amends MOVE_FIT_LAW
```

## 1. Availability

```text
logic_available =
    карта руки несёт ☶
    OR
    ☶ входит в операторы, выданные установленной runtime-картой
```

`RUNTIME` добавляет выданный оператор к набору выбора и не заменяет операторы карты.

## 2. Legality

```text
ход легален, если
    full_pair_fit(committed manifest card, hand card)
    OR
    logic_available
```

`full_pair_fit` не меняется. `MOVE_FIT_LAW §3-4` действует в полном объёме для всех случаев, где `logic_available` ложно.

## 3. Joker move

```text
joker_move = NOT full_pair_fit(committed manifest card, hand card)
```

Величина вычисляется в момент фиксации хода.

## 4. Operator constraint

```text
joker_move истинно  -> набор операторов хода равен ровно {☶}
joker_move ложно    -> набор операторов не меняется,
                       включая ☶, если карта его несёт
```

## 5. Effect

```text
☶ не производит эффекта
☶ не открывает целевую фазу
☶ не целит grave
```

Ход разрешается обычным мировым обновлением:

```text
committed manifest -> grave
latent -> manifest
deck -> latent, закрыто
сыгранная карта -> grave
```

## 6. Placement in the turn

`☶` не разрешается ни до мирового обновления, как `☷ DISSOLVE`, ни после, как остальные восемь операторов. Он применяется в проверке легальности.

Это вынужденно: оператор выбирается после того, как ход собран, поэтому при несошедшемся fit фаза выбора оператора недостижима. Оператор, легализующий ход, не может быть эффектом этого хода.

## 7. Duplicates

`MOVE_FIT_LAW §8` сужает ворота для дубля руки: оба порта обязаны состыковаться.

Для `☶☶` пункт 2 настоящего закона делает карту легальной к любой занятой манифест-карте. Набор операторов при `joker_move` равен `{☶}`, при обычном fit — тоже `{☶}` после дедупликации.

`☶` присутствует на 19 картах из 100.

## 8. Runtime

Пока карта с `☶` установлена в `runtime`, `logic_available` истинно для любой карты руки. Пункт 4 продолжает действовать: при несошедшемся fit оператором хода будет `☶`, то есть эффекта не будет.

## 9. Superseded

```text
operators/LOGIC.md §1  ☶ = swap one revealed minor-card with one card from hand
operators/LOGIC.md §3  процедура обмена
operators/LOGIC.md §4  legal target class
```

Файл подлежит пометке `superseded by LOGIC_JOKER_LAW.md` при следующем проходе по operator-слою.

## 10. Rejected

```text
правило «оператор, сделавший ход легальным, не обязывает играть его эффект»
```

Отклонено: `MOVE_FIT_LAW §3-4` требует закрытия обоих операторов, поэтому отдельного «оператора легальности» не существует. Введение такого правила потребовало бы отмены no-orphan law. No-orphan law остаётся в силе.

## 11. Open

```text
1. Круг 8 Nine Circle Run искажал прежний обмен ☶. Помечен legacy,
   требует переписывания.
2. Частотная ручка для ☶ (раз в ход / раз за партию) не задана.
3. MAXIMIZE кастует «пока топология разрешает и пока хочет игрок».
   При logic_available первое условие не ограничивает.
   Граница задаётся при реализации MAXIMIZE.
```

---

Автор изменения: slasten, 2026-07-27.

---

machines only. not for humans.
