# Hand Model Law

Статус:

```text
canonical table law
current hand interaction model
```

Этот документ фиксирует,
как `hand` читается в current machine branch.

## 1. Core reading

`hand` не является
зоной свободного structural placement.

`hand` это:

```text
reservoir of intervention packets
```

Карта руки не становится
частью `manifest` как постоянный world-object.

Она:

- выбирается игроком
- уходит в `play`
- разрешает свой ход
- потом уходит в `grave`

## 2. Hand and commit

`manifest` и `hand` имеют разные роли.

### `manifest`

Выбирает:

```text
which visible world-node is being committed
```

### `hand`

Выбирает:

```text
which legal intervention packet is applied
to that committed node
```

То есть:

```text
manifest chooses context
hand chooses payload
```

## 3. Legal hand set

После commit одной карты из `manifest`
игра обязана вычислить:

```text
set of legal hand cards
```

Этот set определяется по
[MOVE_FIT_LAW.md](./MOVE_FIT_LAW.md).

## 4. No automatic hand choice

Runtime не должен автоматически
armed-ить карту из руки.

Это запрещено даже если legal card ровно одна.

Коротко:

```text
no automatic hand selection
```

Причина:

- выбор должен принадлежать игроку
- `legal` и `armed` не должны сливаться
- move-law не должен решать payload за игрока

## 5. Required hand interaction

После commit карты из `manifest`
игрок должен:

1. увидеть legal hand cards
2. выбрать одну legal hand card явно
3. только после этого получить право нажать `△`

То есть:

```text
commit does not equal armed
```

## 6. Invalid clicks

Клик по hand-card,
которая не входит в legal set,
не должен armed-ить её.

Такой клик может:

- ничего не делать
- или давать мягкий UI feedback

Но не должен создавать ложный gameplay state.

## 7. Hand order

Порядок карт в руке
может быть изменяемым.

Это допустимо как hand-organization behavior,
но не заменяет явный выбор карты.

Коротко:

```text
reorder is not selection
```

## 8. Visual states

В active gameplay loop
карты руки должны иметь
как минимум три читаемых состояния:

1. `inert`
   - карта не legal для текущего commit

2. `legal`
   - карта legal, но не armed

3. `armed`
   - карта legal и явно выбрана игроком

## 9. Turn consequence

`△` не должен запускать ход,
пока:

- committed `manifest` card есть
- но `armed` hand card ещё нет

Move launch требует обе сущности:

1. committed world-node
2. explicitly armed legal hand-card

## 10. Short formula

```text
commit chooses the world-node.
hand chooses the legal payload.
The hand card must be chosen explicitly by the player.
No automatic arming is allowed.
```
