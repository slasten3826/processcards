# Trump Runtime Stub Law

Статус:

```text
canonical runtime table law
current minimal trump pipeline
```

Этот документ фиксирует
самую базовую runtime-механику козырей
до ввода полного per-trump effect layer.

## 1. Core pipeline

Minimal trump runtime сейчас читается так:

```text
revealed trump
-> trump flow
-> pending trump event
-> manual confirm
-> stub resolution
-> trump zone
```

## 2. Reveal trigger

Козырь входит в `trump flow`
не потому что он просто существует,
а потому что он:

```text
becomes revealed
```

Если он попал в concealed zone как `not-revealed`,
ничего ещё не происходит.

## 3. Open vs concealed deck entry

### Open deck entry

Если карта идёт из `deck`
в открытую логику,
машина обязана сначала:

```text
reveal topdeck
```

и только потом resolve-ить revealed result.

### Concealed deck entry

Если карта идёт из `deck`
в скрытую зону,
она:

- не reveal-ится заранее
- входит туда сразу как `not-revealed`

Это может быть и `minor`, и `trump`.

## 4. Trump diversion

Если revealed topdeck оказался trump,
то:

1. он не закрывает open structural obligation
2. он уходит в `trump flow`
3. эта конкретная open draw/open-entry attempt сгорает на нём

Но если machine всё ещё должна закрыть open slot,
reveal продолжается,
пока structural closure не будет достигнут.

## 5. Pending event law

Когда козырь вошёл в `trump flow`,
его event не должен автоматически проматываться.

Сначала возникает:

```text
pending trump event
```

И runtime должен ждать
явного player confirm.

## 6. Manual confirm

До full event-layer
достаточно простого explicit confirm:

- `OK`
- `△`
- или другой later canonical confirm control

Но принцип уже фиксирован:

```text
trump resolution is acknowledged, not auto-skipped
```

## 7. Stub resolution

На текущем минимальном слое
stub resolution может ничего не менять в мире
кроме прохождения through the pipe.

Runtime обязан:

- показать trump в `trump flow`
- позволить confirm
- потом убрать его из `trump flow`
- затем отправить в `trump zone`

## 8. Board closure gate

Даже если козырь уже в `trump flow`,
он не может начать stub resolution,
пока board не закрыт.

См.:

- [BOARD_CLOSURE_LAW.md](./BOARD_CLOSURE_LAW.md)

## 9. Target override

Revealed trump в `targets`
не идёт в `trump flow`.

Он:

- остаётся в `targets`
- живёт как compiler trump

## 10. Short formula

```text
Only a revealed trump enters trump flow.
Trump flow waits for board closure and player confirm.
Then stub resolution sends the trump to trump zone.
Targets override normal flow entry.
```
