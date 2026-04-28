# Move Fit Law

Статус:

```text
canonical table law
current move-fit law
aligned with compiler/victory machine
```

Этот документ фиксирует текущий канон legality:

```text
ход формируется через committed manifest-card
и full-fit карты из руки
```

## 1. Core claim

Новый ход в этой ветке начинается не с placement карты из руки.

Он начинается с:

```text
commit one open manifest card
```

После этого карта из руки проверяется
не как самостоятельный “режим weak/strong”,
а как topology-fit к committed карте мира.

## 2. Committed manifest card

Пусть committed manifest-card имеет операторную пару:

```text
A B
```

А hand-card имеет пару:

```text
C D
```

## 3. Full pair fit

Ход легален только если hand-card
может полностью закрыться against committed manifest-card.

Это значит:

```text
(A ~ C and B ~ D)
or
(A ~ D and B ~ C)
```

Где:

```text
X ~ Y
```

означает:

```text
canonical topology allows X and Y to connect
```

## 4. No orphan operator law

Недостаточно, чтобы с committed manifest-card
сцепился только один оператор hand-card.

Если второй оператор hand-card остаётся без легального pair-match,
ход не собирается.

Коротко:

```text
no orphan operator allowed
```

## 5. Two-direction check

Fit проверяется в обеих перестановках.

То есть hand-card не обязана совпасть
только в одной фиксированной ориентации.

Разрешены оба варианта:

```text
A->C and B->D
```

и

```text
A->D and B->C
```

Это нужно,
чтобы topology-fit не становился искусственно слишком жёстким.

## 6. Self-link law

Для текущей ветки fit-law допускается,
что оператор топологически соединяется с самим собой.

То есть:

```text
X ~ X
```

разрешено.

Это особенно важно для карт с дублями,
например:

- `△△`
- `☱☱`
- `☶☶`

## 7. Duplicate special case

Если committed manifest-card имеет вид:

```text
X X
```

то fit-law сужается до:

```text
C ~ X
and
D ~ X
```

То есть оба оператора hand-card
обязаны лежать в соседстве `X`.

Следствие:

дубль в `manifest`
образует узкий committed gate.

Коротко:

```text
XX on manifest demands double compatibility against X
```

## 8. Hand duplicate consequence

Если сама hand-card является дублем:

```text
Y Y
```

то она легальна только если один и тот же оператор `Y`
может законно пристыковаться к обоим портам committed manifest-card.

То есть hand-duplicate тоже работает
как жёсткий topology filter.

## 9. Why this matters

Этот закон нужен,
чтобы topology была не декоративной,
а реально определяла,
собирается ход или нет.

Коротко:

```text
the move is topology-first
not button-mode-first
```

## 10. Manifest sentence consequence

Committed card живёт внутри
не просто open row,
а внутри:

```text
6-slot visible directed sentence surface
```

Это значит:

- fit проверяет local legality of the move
- но сам move later переписывает один слот
  будущего visible victory sentence

Коротко:

```text
fit is local
sentence consequence is global
```

## 11. Relationship to current victory branch

Этот документ не делает win check.

Но он должен быть совместим с тем,
что later победа проверяется
against one full directed 6-slot reading of `manifest`.

См.:

- [TURN_LAW_V2.md](./TURN_LAW_V2.md)
- [WIN_CHECK_LAW.md](./WIN_CHECK_LAW.md)

## 12. Relationship to old weak/strong model

Этот документ естественно конфликтует
со старой интуицией:

- weak move
- strong move

как двух отдельных режимов hand-card.

В этой ветке move legality
растёт прежде всего из:

```text
committed manifest pattern + hand-card fit
```

А не из заранее выбранного режима.

## 13. What this law does not decide yet

Этот документ пока не решает:

- что игрок делает, если fit не собрался
- даёт ли legal fit сразу draw reward
- exact final strong law
- full compiler derivation grammar

Он решает только:

```text
what counts as a topology-legal move candidate
```

## 14. Short formula

```text
a move is legal only if the hand card fully closes
against the committed manifest card
no orphan operator allowed
duplicates narrow the gate even harder
the committed slot belongs to a 6-slot visible sentence surface
```
