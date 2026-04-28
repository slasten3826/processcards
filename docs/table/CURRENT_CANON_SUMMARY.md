# Current Canon Summary

Статус:

```text
canonical table overview
entry point for current machine branch
```

Этот документ не заменяет table laws.

Он нужен как короткая карта текущей машины:

- что уже считается current canon
- что уже собрано в одну систему
- где сейчас проходит граница следующей миграции

## 1. Identity

ProcessCards currently reads as:

```text
intervention into a breathing machine
not direct board control
```

Primary identity note:

- [../manifest/PROCESSCARDS_IDENTITY.md](../manifest/PROCESSCARDS_IDENTITY.md)

## 2. Core machine

Current machine branch is built around:

1. `manifest / latent` as world surface
2. `hand` as intervention reservoir
3. one committed manifest-node per move
4. topology-fit legality from hand
5. world update before played effect
6. played card goes to grave after its effect

Core laws:

- [TURN_LAW_V2.md](./TURN_LAW_V2.md)
- [TURN_SEQUENCE_LAW_V2.md](./TURN_SEQUENCE_LAW_V2.md)
- [MOVE_FIT_LAW.md](./MOVE_FIT_LAW.md)

## 3. Information model

Current canon uses three information states:

- `hidden`
- `known`
- `revealed`

Core laws:

- [CARD_INFORMATION_STATE_LAW.md](./CARD_INFORMATION_STATE_LAW.md)
- [OBSERVE_VS_REVEAL_LAW.md](./OBSERVE_VS_REVEAL_LAW.md)

Short formula:

```text
known is not yet revealed
revealed is always known
```

## 4. Draw and trump entry

Draw is no longer vague card gain.

It is a sequence of explicit draw procedures.

Core laws:

- [DRAW_PROCEDURE_LAW.md](./DRAW_PROCEDURE_LAW.md)
- [TRUMP_EVENT_MINIMAL_LAW.md](./TRUMP_EVENT_MINIMAL_LAW.md)
- [TRUMP_RESOLUTION_ORDER_LAW.md](./TRUMP_RESOLUTION_ORDER_LAW.md)
- [FOOL_LAW.md](./FOOL_LAW.md)
- [SHUFFLE_LAW.md](./SHUFFLE_LAW.md)
- [UNVEIL_LAW.md](./UNVEIL_LAW.md)
- [RESET_LAW.md](./RESET_LAW.md)
- [SWAP_LAW.md](./SWAP_LAW.md)
- [WARRANT_LAW.md](./WARRANT_LAW.md)
- [REPEAT_LAW.md](./REPEAT_LAW.md)
- [UNBOUND_LAW.md](./UNBOUND_LAW.md)
- [HALT_LAW.md](./HALT_LAW.md)
- [EJECT_LAW.md](./EJECT_LAW.md)
- [ORACLE_LAW.md](./ORACLE_LAW.md)
- [RECAST_LAW.md](./RECAST_LAW.md)

Short formula:

```text
each draw procedure may yield a minor
or burn into a trump event
```

## 5. Zone reading

Current live zones:

- `deck`
- `hand`
- `manifest`
- `latent`
- `targets`
- `runtime`
- `trump flow`
- `grave`
- `trump zone`

Core laws:

- [BOARD_SCOPE_LAW.md](./BOARD_SCOPE_LAW.md)
- [CHAIN_SURFACE_LAW.md](./CHAIN_SURFACE_LAW.md)
- [TARGET_ZONE_LAW.md](./TARGET_ZONE_LAW.md)
- [GRAVE_LAW.md](./GRAVE_LAW.md)
- [RUNTIME_ZONE_LAW.md](./RUNTIME_ZONE_LAW.md)
- [TRUMP_FLOW_LAW.md](./TRUMP_FLOW_LAW.md)
- [TRUMP_RESOLUTION_ORDER_LAW.md](./TRUMP_RESOLUTION_ORDER_LAW.md)
- [TRUMP_ZONE_LAW.md](./TRUMP_ZONE_LAW.md)

## 6. Operator layer

Current operator canon is indexed here:

- [OPERATORS_INDEX.md](./OPERATORS_INDEX.md)

Live family docs:

- [operators/FLOW.md](./operators/FLOW.md)
- [operators/CONNECT.md](./operators/CONNECT.md)
- [operators/DISSOLVE.md](./operators/DISSOLVE.md)
- [operators/ENCODE.md](./operators/ENCODE.md)
- [operators/CHOOSE.md](./operators/CHOOSE.md)
- [operators/OBSERVE.md](./operators/OBSERVE.md)
- [operators/CYCLE.md](./operators/CYCLE.md)
- [operators/LOGIC.md](./operators/LOGIC.md)
- [operators/RUNTIME.md](./operators/RUNTIME.md)
- [operators/MANIFEST.md](./operators/MANIFEST.md)

## 7. Victory branch

Current victory thinking is no longer external score tracking.

It is being rebuilt as:

```text
target zone compiler
-> directed manifest sentence
-> post-resolution win check
```

Current branch:

- [WIN_CHECK_LAW.md](./WIN_CHECK_LAW.md)

This branch is high-impact
and forces migration of several older current docs.

## 8. Current fracture line

The project now has one coherent machine,
but not every canonical doc has been rewritten to fit it.

Current fracture line is:

```text
turn-law and operator canon already exist
victory/compiler branch now forces structural rewrite
```

Migration map:

- [WIN_CHECK_MIGRATION_STATUS.md](./WIN_CHECK_MIGRATION_STATUS.md)

## 9. Legacy rule

Older generations of the project now live in:

- [../legacy/README.md](../legacy/README.md)

They remain useful as archive,
but not as current execution canon.

## 10. Short formula

```text
current ProcessCards canon =
topology-first move
+ hidden/known/revealed information model
+ operator-choice play
+ target-compiled directed victory branch
```
