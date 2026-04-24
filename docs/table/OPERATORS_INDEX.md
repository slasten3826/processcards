# Operators Index

Статус:

```text
canonical table index
```

Этот файл — вход в операторный слой minor-машины.

Старые общие документы не удаляются,
но для семейства операторов читать сначала нужно этот индекс
и затем отдельные family docs в `./operators/`.

## Canon priority

Current read order:

```text
OPERATORS_INDEX.md
-> operators/*.md
-> OPERATOR_MODEL.md
-> CONNECT_LAW.md
-> older legacy drafts
```

## Operator families

- [FLOW.md](./operators/FLOW.md) — `▽`
- [CONNECT.md](./operators/CONNECT.md) — `☰`
- [DISSOLVE.md](./operators/DISSOLVE.md) — `☷`
- [ENCODE.md](./operators/ENCODE.md) — `☵`
- [CHOOSE.md](./operators/CHOOSE.md) — `☳`
- [OBSERVE.md](./operators/OBSERVE.md) — `☴`
- [CYCLE.md](./operators/CYCLE.md) — `☲`
- [LOGIC.md](./operators/LOGIC.md) — `☶`
- [RUNTIME.md](./operators/RUNTIME.md) — `☱`
- [MANIFEST.md](./operators/MANIFEST.md) — `△`

## Current status map

- `▽ FLOW` — canonical family
- `☰ CONNECT` — canonical family
- `☷ DISSOLVE` — canonical direction, pair details open
- `☵ ENCODE` — canonical direction, pair details open
- `☳ CHOOSE` — weak-fragile family, still delicate
- `☴ OBSERVE` — canonical direction
- `☲ CYCLE` — canonical direction
- `☶ LOGIC` — canonical family
- `☱ RUNTIME` — canonical family
- `△ MANIFEST` — canonical direction

## Shared table laws

These laws apply across the operator layer:

1. Minor physical deck remains `100 ordered cards`.
2. Effect-family reading may ignore internal operator order.
3. Weak play resolves `1` card effect.
4. Strong play resolves broader card reading and baseline `draw 2`.
5. If cardboard cannot do it, prototype cannot rely on it.

## Legacy relation

If a legacy draft conflicts with an operator family file in `./operators/`,
the family file wins.
