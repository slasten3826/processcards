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
-> ../legacy/table/OPERATOR_MODEL.md as legacy semantic layer
-> ../legacy/table/CONNECT_LAW.md as legacy semantic layer
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

- `▽ FLOW` — superseded by [FLOW_RING_LAW.md](./FLOW_RING_LAW.md)
- `☰ CONNECT` — canonical family
- `☷ DISSOLVE` — canonical family
- `☵ ENCODE` — superseded by [ENCODE_SWAP_LAW.md](./ENCODE_SWAP_LAW.md)
- `☳ CHOOSE` — canonical family
- `☴ OBSERVE` — canonical family
- `☲ CYCLE` — superseded by [CYCLE_ADVANCE_LAW.md](./CYCLE_ADVANCE_LAW.md)
- `☶ LOGIC` — superseded by [LOGIC_JOKER_LAW.md](./LOGIC_JOKER_LAW.md)
- `☱ RUNTIME` — canonical family
- `△ MANIFEST` — canonical family

## Shared table laws

These laws apply across the operator layer:

1. Minor physical deck remains `100 ordered cards`.
2. Effect-family reading may ignore internal operator order.
3. Current move branch tends toward choosing `1` operator effect from the played card.
4. Old weak/strong operator chassis is no longer current canon.
5. If cardboard cannot do it, prototype cannot rely on it.
6. Draw now means one explicit draw procedure, not silent hand gain.

## Legacy relation

If a legacy draft conflicts with an operator family file in `./operators/`,
the family file wins.

But if an older semantic draft conflicts with a family file in `./operators/`,
the family file wins.
