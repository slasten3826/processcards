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

### B. Imported trump design branch

Полные draft-доки по козырям теперь лежат в:

- [../chaos/upstream/processcards/trumps/README.md](../chaos/upstream/processcards/trumps/README.md)
- [../chaos/upstream/processcards/trumps/TRUMP_ECOLOGY.md](../chaos/upstream/processcards/trumps/TRUMP_ECOLOGY.md)
- [../chaos/upstream/processcards/trumps/TRUMP_RESOLUTION_ORDER.md](../chaos/upstream/processcards/trumps/TRUMP_RESOLUTION_ORDER.md)
- [../chaos/upstream/processcards/trumps/FOOL.md](../chaos/upstream/processcards/trumps/FOOL.md)
- [../chaos/upstream/processcards/trumps/EJECT.md](../chaos/upstream/processcards/trumps/EJECT.md)
- [../chaos/upstream/processcards/trumps/SHUFFLE.md](../chaos/upstream/processcards/trumps/SHUFFLE.md)
- [../chaos/upstream/processcards/trumps/RECAST.md](../chaos/upstream/processcards/trumps/RECAST.md)
- [../chaos/upstream/processcards/trumps/RESET.md](../chaos/upstream/processcards/trumps/RESET.md)
- [../chaos/upstream/processcards/trumps/UNVEIL.md](../chaos/upstream/processcards/trumps/UNVEIL.md)
- [../chaos/upstream/processcards/trumps/HALT.md](../chaos/upstream/processcards/trumps/HALT.md)

Эти документы уже ценны,
но пока не считаются автоматически live prototype canon.

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
2. потом читать imported trump branch в `docs/chaos/.../trumps/`
3. поднимать отдельные pieces из imported branch в `docs/table/`
   только после явного решения

Коротко:

```text
chaos trumps = imported branch
table trumps = active prototype law
```

## 3. Why this split exists

Этот split нужен,
потому что trump-доки уже достаточно сильные как design branch,
но текущий prototype scope пока intentionally проще.

То есть:

- trump knowledge уже надо хранить в репо
- но нельзя делать вид,
  будто весь trump event engine уже обязателен в текущем runtime

## 4. Upgrade rule

Если какой-то trump law из imported branch
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
chaos draft -> explicit table adoption -> code
```

## 5. Short formula

```text
full trump branch now lives in chaos
only adopted pieces become active table law
```
