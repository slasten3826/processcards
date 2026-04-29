# Board Closure Law

Статус:

```text
canonical table law
current board-priority branch
```

Этот документ фиксирует,
что в current machine branch
закрытие board первично
по отношению к резолву козырей.

## 1. Core claim

Козырь может войти в `trump flow`
до закрытия стола.

Но он не может начать resolution,
пока board не закрыт полностью.

Коротко:

```text
board closure precedes trump resolution
```

## 2. What counts as full board closure

Current board считается закрытым,
только если заняты:

- все `manifest[1..6]`
- все `latent[1..6]`
- все `targets[1..3]`

То есть:

```text
12 chain cards + 3 target cards
```

должны одновременно присутствовать на столе.

## 3. Trump flow consequence

Если revealed trump уже вошёл в `trump flow`
до полного closure board,
то он:

- может быть видим в `trump flow`
- может накапливаться в очереди
- но не должен резолвиться

Пока board не закрыт:

```text
trump flow may accumulate
but may not resolve
```

## 4. Structural priority

Если машина обязана закрыть
open structural slot,
то это обязательство первично.

Пока оно не исполнено,
trump resolution не стартует.

Это относится прежде всего к:

- `manifest` closure
- `latent` closure
- `targets` closure

## 5. Open deck entry consequence

Если карта из `deck`
идёт в открытую structural logic,
то:

1. topdeck reveal-ится
2. если это `minor`, он может закрыть нужный slot
3. если это `trump`, он уходит в `trump flow`
4. но structural closure всё ещё считается незавершённым
5. reveal продолжается, пока нужный open slot не будет реально закрыт

Коротко:

```text
trump diverts into flow
but does not satisfy open structural closure
```

## 6. Concealed deck entry consequence

Если карта из `deck`
идёт в скрытую зону,
то:

- она не reveal-ится предварительно
- она входит туда сразу как `not-revealed`
- это может быть и `minor`, и `trump`

Коротко:

```text
concealed entry does not trigger trump flow by itself
```

## 7. Trigger law

Сам по себе класс карты `trump`
не достаточен для входа в `trump flow`.

Нужен именно факт:

```text
the trump becomes revealed
```

До этого скрытый trump
может спокойно лежать в concealed zone.

## 8. Target override

Если козырь revealed в `targets`,
он не уходит в `trump flow`.

Он:

- остаётся в `targets`
- живёт как compiler trump

## 9. Short formula

```text
Trumps may enter trump flow before the board is closed.
They may not resolve until manifest, latent, and targets are all fully occupied.
Board closure is primary.
```
