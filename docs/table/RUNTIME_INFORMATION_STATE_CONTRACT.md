# Runtime Information State Contract

Статус:

```text
working table contract
runtime-facing state requirement
```

Этот документ не заменяет
[CARD_INFORMATION_STATE_LAW.md](./CARD_INFORMATION_STATE_LAW.md).

Он фиксирует,
как текущий runtime должен представлять
эту truth-model в коде.

## 1. Core decision

Runtime больше не должен опираться
только на:

```text
face_up = true / false
```

Этого недостаточно для current machine canon.

Нужен явный machine state:

```text
hidden
known
revealed
```

## 2. Required card state

Каждая карта в runtime должна уметь хранить:

```text
info_state = "hidden" | "known" | "revealed"
```

Минимально это можно вводить
либо как одно поле,
либо как эквивалентную нормализованную структуру.

Но runtime должен уметь различать
эти три truth-state без догадки.

## 3. Why `face_up` is not enough

Бинарного `face_up` уже недостаточно для честной поддержки:

- `OBSERVE`
- `ORACLE`
- `UNVEIL`
- `known topdeck`
- refill preserving known/revealed state
- trump trigger on `known`

То есть:

```text
known but not revealed
must exist in runtime
```

## 4. Required semantic mapping

Runtime must support at least this reading:

### `hidden`

- card is not publicly surfaced
- card is not yet known by default

### `known`

- card identity is known
- card is not necessarily publicly revealed
- card may still render as face-down object

### `revealed`

- card is public face-up machine state
- revealed always implies known

## 5. Required transitions

Runtime must support at least:

- `hidden -> known`
- `hidden -> revealed`
- `known -> revealed`

And by default must not silently do:

- `known -> hidden`
- `revealed -> hidden`

unless a later explicit law says otherwise.

## 6. Rendering consequence

Runtime rendering should eventually be able to express:

- `hidden` = ordinary card back
- `known` = card back + ghost identity overlay
- `revealed` = full face-up card

Exact art may evolve,
but this middle layer must be representable.

## 7. Gameplay consequence

Current gameplay work that depends on this contract:

- `OBSERVE`
- `ORACLE`
- `UNVEIL`
- topdeck persistence
- latent refill preserving information state
- trump triggers on `known`

## 8. Migration consequence

Runtime migration should treat this
as a real state-model change,
not as a cosmetic render tweak.

Коротко:

```text
this is machine truth
not UI polish
```

## 9. Short formula

```text
runtime must represent three card states:
hidden, known, revealed.
Binary face-up is no longer enough for current canon.
```
