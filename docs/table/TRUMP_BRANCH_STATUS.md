# Trump Branch Status

Статус:

```text
canonical table routing note
```

Этот документ фиксирует,
как сейчас читать trump-layer в репозитории.

## 1. Current split

В проекте сейчас существуют два разных trump-слоя:

### A. Live prototype trump canon

Это то,
что уже реально участвует в текущем prototype scope.

Сюда сейчас входят:

- [TRUMP_IDENTITY_LAW.md](./TRUMP_IDENTITY_LAW.md)
- [TRUMP_FLOW_LAW.md](./TRUMP_FLOW_LAW.md)
- [TRUMP_RESOLUTION_ORDER_LAW.md](./TRUMP_RESOLUTION_ORDER_LAW.md)
- [TRUMP_ZONE_LAW.md](./TRUMP_ZONE_LAW.md)
- [TRUMP_EVENT_MINIMAL_LAW.md](./TRUMP_EVENT_MINIMAL_LAW.md)
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

А также связанные зоны:

- [TARGET_ZONE_LAW.md](./TARGET_ZONE_LAW.md)
- [OBSERVE_VS_REVEAL_LAW.md](./OBSERVE_VS_REVEAL_LAW.md)

Это и есть текущий live law,
на который может опираться runtime.

### B. Full table trump branch

Полный trump-канон теперь лежит прямо в:

- [trumps/README.md](./trumps/README.md)
- [trumps/TRUMP_ECOLOGY.md](./trumps/TRUMP_ECOLOGY.md)
- [trumps/TRUMP_RESOLUTION_ORDER.md](./trumps/TRUMP_RESOLUTION_ORDER.md)
- [trumps/FOOL.md](./trumps/FOOL.md)
- [trumps/EJECT.md](./trumps/EJECT.md)
- [trumps/SHUFFLE.md](./trumps/SHUFFLE.md)
- [trumps/RECAST.md](./trumps/RECAST.md)
- [trumps/RESET.md](./trumps/RESET.md)
- [trumps/UNVEIL.md](./trumps/UNVEIL.md)
- [trumps/HALT.md](./trumps/HALT.md)
- [trumps/ORACLE.md](./trumps/ORACLE.md)
- [trumps/SWAP.md](./trumps/SWAP.md)
- [trumps/WARRANT.md](./trumps/WARRANT.md)
- [trumps/REPEAT.md](./trumps/REPEAT.md)
- [trumps/UNBOUND.md](./trumps/UNBOUND.md)
- [trumps/TIGEL.md](./trumps/TIGEL.md)
- [trumps/RUSH.md](./trumps/RUSH.md)
- [trumps/ENOUGH.md](./trumps/ENOUGH.md)
- [trumps/GRANT.md](./trumps/GRANT.md)
- [trumps/GATE.md](./trumps/GATE.md)
- [trumps/PURGE.md](./trumps/PURGE.md)
- [trumps/CANON.md](./trumps/CANON.md)
- [trumps/MAXIMIZE.md](./trumps/MAXIMIZE.md)
- [trumps/ERROR.md](./trumps/ERROR.md)
- [trumps/REQUIEM.md](./trumps/REQUIEM.md)

Эти документы уже находятся в `table`,
но это не значит, что весь trump-layer уже автоматически обязан runtime.
Надо всё ещё различать:

- short live prototype laws in `docs/table/*.md`
- full trump branch in `docs/table/trumps/`

Already adopted individual trump law:

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

## 2. How to read them

Правильный порядок чтения сейчас такой:

1. сначала читать live prototype laws в `docs/table/`
2. потом читать full trump branch в `docs/table/trumps/`
3. поднимать отдельные pieces из full trump branch в `docs/table/`
   только после явного решения

Коротко:

```text
table/*.md short laws = active prototype law
table/trumps/* = full trump canon branch
```

## 3. Why this split exists

Этот split нужен,
потому что trump-доки уже собраны как table-branch,
но текущий prototype scope всё ещё intentionally проще.

То есть:

- full trump knowledge уже живёт в table
- но нельзя делать вид,
  будто весь trump event engine уже обязателен в текущем runtime

## 4. Upgrade rule

Если какой-то trump law из `table/trumps/`
становится частью живого прототипа,
его надо:

1. явно зафиксировать в `docs/table/`
2. связать с существующими zone / ecology laws
3. только после этого тащить в runtime

Неправильно:

```text
read a chaos trump draft
implement it directly
```

Правильно:

```text
table/trumps draft -> explicit short-law adoption -> code
```

## 5. Short formula

```text
full trump branch now lives in table/trumps
only adopted short laws become active runtime-facing table law
```
